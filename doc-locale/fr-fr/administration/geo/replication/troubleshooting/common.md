---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Résolution des erreurs Geo courantes
description: "Diagnostiquer et résoudre les problèmes Geo courants, couvrant les vérifications de santé, les problèmes de réplication de base de données, la connectivité des sites et les procédures de résolution d'erreurs."
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

## Résolution de problèmes de base {#basic-troubleshooting}

Avant de tenter une résolution de problèmes plus avancée :

- Vérifiez [l'état de santé des sites Geo](#check-the-health-of-the-geo-sites).
- Vérifiez [si la réplication PostgreSQL fonctionne](#check-if-postgresql-replication-is-working).

### Traçage des requêtes entre les sites Geo {#tracing-requests-across-geo-sites}

Lors de la résolution de problèmes Geo, vous pourriez avoir besoin de tracer une requête du site secondaire vers le site principal, ou vice-versa. GitLab utilise des ID de corrélation pour relier les entrées de journal associées entre les services.

Par défaut, chaque site génère son propre ID de corrélation lors de la réception d'une requête. Pour tracer une seule requête entre les deux sites en utilisant le même ID de corrélation, vous devez configurer le Workhorse de chaque site récepteur pour accepter les ID de corrélation entrants provenant d'autres sites Geo.

Sur tous les sites Geo :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_workhorse['propagate_correlation_id'] = true
   gitlab_workhorse['trusted_cidrs_for_propagation'] = %w(<secondary-site-ip>/32)
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Mettez à jour vos valeurs Helm :

   ```yaml
   gitlab:
     webservice:
       workhorse:
         extraArgs: "-propagateCorrelationID"
         trustedCIDRsForPropagation: ["<secondary-site-ip>/32"]
   ```

1. Appliquez les modifications.

{{< /tab >}}

{{< /tabs >}}

Après avoir activé ce paramètre, les requêtes envoyées du site secondaire vers le site principal partagent le même ID de corrélation dans leurs journaux, ce qui vous permet de tracer les requêtes entre les deux sites.

### Vérifier l'état de santé des sites Geo {#check-the-health-of-the-geo-sites}

Sur le site **principal** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.

Nous effectuons les vérifications de santé suivantes sur chaque site **secondaire** pour aider à identifier si quelque chose ne va pas :

- Le site est-il en cours d'exécution ?
- La base de données du site secondaire est-elle configurée pour la réplication en continu ?
- La base de données de suivi du site secondaire est-elle configurée ?
- La base de données de suivi du site secondaire est-elle connectée ?
- La base de données de suivi du site secondaire est-elle à jour ?
- Le statut du site secondaire a-t-il moins d'1 heure ?

Un site s'affiche comme « En mauvaise santé » si le statut du site a plus d'1 heure. Dans ce cas, essayez d'exécuter la commande suivante dans la [console Rails](../../../operations/rails_console.md) sur le site secondaire concerné :

```ruby
Geo::MetricsUpdateWorker.new.perform
```

Si une erreur est soulevée, celle-ci empêche probablement aussi les jobs de se terminer. Si cela prend plus d'1 heure, le statut peut osciller ou persister comme « En mauvaise santé », même si le statut est occasionnellement mis à jour. Cela peut être dû à une croissance de l'utilisation, à une croissance des données au fil du temps, ou à des bugs de performance tels qu'un index de base de données manquant.

Vous pouvez surveiller la charge CPU du système avec un utilitaire comme `top` ou `htop`. Si PostgreSQL utilise une quantité significative de CPU, cela peut indiquer qu'il y a un problème, ou que le système est sous-provisionné. La mémoire système doit également être surveillée.

Si vous augmentez la mémoire, vous devez également vérifier les paramètres PostgreSQL liés à la mémoire dans votre configuration `/etc/gitlab/gitlab.rb`.

Si le statut est mis à jour avec succès, quelque chose peut être incorrect avec Sidekiq. Est-il en cours d'exécution ? Les journaux affichent-ils des erreurs ? Ce job est censé être mis en file d'attente chaque minute et pourrait ne pas s'exécuter si une clé d'[idempotence de déduplication de job](../../../sidekiq/sidekiq_troubleshooting.md#clearing-a-sidekiq-job-deduplication-idempotency-key) n'a pas été correctement effacée. Il prend un bail exclusif dans Redis pour s'assurer qu'un seul de ces jobs peut s'exécuter à la fois. Le site principal met à jour son statut directement dans la base de données PostgreSQL. Les sites secondaires envoient une requête HTTP Post au site principal avec leurs données de statut.

Un site s'affiche également comme « En mauvaise santé » si certaines vérifications de santé échouent. Vous pouvez révéler l'échec en exécutant la commande suivante dans la [console Rails](../../../operations/rails_console.md) sur le site secondaire concerné :

```ruby
Gitlab::Geo::HealthCheck.new.perform_checks
```

Si la valeur retournée est `""` (une chaîne vide) ou `"Healthy"`, les vérifications ont réussi. Si une autre valeur est retournée, le message devrait expliquer ce qui a échoué, ou afficher le message d'exception.

Pour des informations sur la manière de résoudre les messages d'erreur courants signalés depuis l'interface utilisateur, consultez [Correction des erreurs courantes](#fixing-common-errors).

Si l'interface utilisateur ne fonctionne pas, ou si vous n'êtes pas en mesure de vous connecter, vous pouvez exécuter la vérification de santé Geo manuellement pour obtenir ces informations et quelques détails supplémentaires.

#### Tâche Rake de vérification de santé {#health-check-rake-task}

{{< history >}}

- L'utilisation d'un serveur NTP personnalisé a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105514) dans GitLab 15.7.

{{< /history >}}

Cette tâche Rake peut être exécutée sur un nœud **Rails** dans les sites Geo **principal** ou **secondaire** :

```shell
sudo gitlab-rake gitlab:geo:check
```

Exemple de sortie :

```plaintext
Checking Geo ...

GitLab Geo is available ... yes
GitLab Geo is enabled ... yes
This machine's Geo node name matches a database record ... yes, found a secondary node named "Shanghai"
GitLab Geo tracking database is correctly configured ... yes
Database replication enabled? ... yes
Database replication working? ... yes
GitLab Geo HTTP(S) connectivity ...
* Can connect to the primary node ... yes
HTTP/HTTPS repository cloning is enabled ... yes
Machine clock is synchronized ... yes
Git user has default SSH configuration? ... yes
OpenSSH configured to use AuthorizedKeysCommand ... yes
GitLab configured to disable writing to authorized_keys file ... yes
GitLab configured to store new projects in hashed storage? ... yes
All projects are in hashed storage? ... yes
Container Registry replication enabled ... yes
Container Registry Geo events ... last event at 2024-01-15 10:30:00 UTC

Checking Geo ... Finished
```

Vous pouvez également spécifier un serveur NTP personnalisé en utilisant des variables d'environnement. Par exemple :

```shell
sudo gitlab-rake gitlab:geo:check NTP_HOST="ntp.ubuntu.com" NTP_TIMEOUT="30"
```

Les variables d'environnement suivantes sont prises en charge.

| Variable      | Description | Valeur par défaut |
| ------------- | ----------- | ------------- |
| `NTP_HOST`    | L'hôte NTP. | `pool.ntp.org` |
| `NTP_PORT`    | Le port NTP sur lequel l'hôte écoute. | `123` |
| `NTP_TIMEOUT` | Le délai d'expiration NTP en secondes. | La valeur définie dans la bibliothèque Ruby `net-ntp` ([60 secondes](https://github.com/zencoder/net-ntp/blob/3d0990214f439a5127782e0f50faeaf2c8ca7023/lib/net/ntp/ntp.rb#L6)). |

Si la tâche Rake ignore la vérification `OpenSSH configured to use AuthorizedKeysCommand`, la sortie suivante s'affiche :

```plaintext
OpenSSH configured to use AuthorizedKeysCommand ... skipped
  Reason:
  Cannot access OpenSSH configuration file
  Try fixing it:
  This is expected if you are using SELinux. You may want to check configuration manually
  For more information see:
  doc/administration/operations/fast_ssh_key_lookup.md
```

Ce problème peut survenir si :

- Vous utilisez [SELinux](../../../operations/fast_ssh_key_lookup.md#selinux-support).
- Vous n'utilisez pas SELinux, et l'utilisateur `git` ne peut pas accéder au fichier de configuration OpenSSH en raison de permissions de fichier restreintes.

Dans ce dernier cas, la sortie suivante montre que seul l'utilisateur `root` peut lire ce fichier :

```plaintext
sudo stat -c '%G:%U %A %a %n' /etc/ssh/sshd_config

root:root -rw------- 600 /etc/ssh/sshd_config
```

Pour permettre à l'utilisateur `git` de lire le fichier de configuration OpenSSH, sans changer le propriétaire ou les permissions du fichier, utilisez `acl` :

```plaintext
sudo setfacl -m u:git:r /etc/ssh/sshd_config
```

#### Tâche Rake de statut de synchronisation {#sync-status-rake-task}

Les informations de synchronisation actuelles peuvent être trouvées manuellement en exécutant cette tâche Rake sur n'importe quel nœud exécutant Rails (Puma, Sidekiq ou Geo Log Cursor) sur le site Geo **secondaire**.

GitLab ne vérifie **not** les objets stockés dans le stockage d'objets. Si vous utilisez le stockage d'objets, vous verrez toutes les vérifications « verified » afficher 0 succès. C'est attendu et ne constitue pas une source d'inquiétude.

```shell
sudo gitlab-rake gitlab:geo:status
```

La sortie comprend :

- un comptage des éléments « failed » si des échecs se sont produits
- le pourcentage des éléments « succeeded », par rapport au « total »

Exemple :

```plaintext
                        Geo Site Information
--------------------------------------------
                                      Name: example-us-east-2
                                       URL: https://gitlab.example.com
                                  Geo Role: Secondary
                             Health Status: Healthy
                This Node's GitLab Version: 17.7.0-ee

                     Replication Information
--------------------------------------------
                             Sync Settings: Full
                  Database replication lag: 0 seconds
           Last event ID seen from primary: 12345 (about 2 minutes ago)
                   Last event ID processed: 12345 (about 2 minutes ago)
                    Last status report was: 1 minute ago

                          Replication Status
--------------------------------------------
                    Lfs Objects replicated: succeeded 111 / total 111 (100%)
            Merge Request Diffs replicated: succeeded 28 / total 28 (100%)
                  Package Files replicated: succeeded 90 / total 90 (100%)
       Terraform State Versions replicated: succeeded 65 / total 65 (100%)
           Snippet Repositories replicated: succeeded 63 / total 63 (100%)
        Group Wiki Repositories replicated: succeeded 14 / total 14 (100%)
             Pipeline Artifacts replicated: succeeded 112 / total 112 (100%)
              Pages Deployments replicated: succeeded 55 / total 55 (100%)
                        Uploads replicated: succeeded 2 / total 2 (100%)
                  Job Artifacts replicated: succeeded 32 / total 32 (100%)
                Ci Secure Files replicated: succeeded 44 / total 44 (100%)
         Dependency Proxy Blobs replicated: succeeded 15 / total 15 (100%)
     Dependency Proxy Manifests replicated: succeeded 2 / total 2 (100%)
      Project Wiki Repositories replicated: succeeded 2 / total 2 (100%)
 Design Management Repositories replicated: succeeded 1 / total 1 (100%)
           Project Repositories replicated: succeeded 2 / total 2 (100%)

                         Verification Status
--------------------------------------------
                      Lfs Objects verified: succeeded 111 / total 111 (100%)
              Merge Request Diffs verified: succeeded 28 / total 28 (100%)
                    Package Files verified: succeeded 90 / total 90 (100%)
         Terraform State Versions verified: succeeded 65 / total 65 (100%)
             Snippet Repositories verified: succeeded 63 / total 63 (100%)
          Group Wiki Repositories verified: succeeded 14 / total 14 (100%)
               Pipeline Artifacts verified: succeeded 112 / total 112 (100%)
                Pages Deployments verified: succeeded 55 / total 55 (100%)
                          Uploads verified: succeeded 2 / total 2 (100%)
                    Job Artifacts verified: succeeded 32 / total 32 (100%)
                  Ci Secure Files verified: succeeded 44 / total 44 (100%)
           Dependency Proxy Blobs verified: succeeded 15 / total 15 (100%)
       Dependency Proxy Manifests verified: succeeded 2 / total 2 (100%)
        Project Wiki Repositories verified: succeeded 2 / total 2 (100%)
   Design Management Repositories verified: succeeded 1 / total 1 (100%)
             Project Repositories verified: succeeded 2 / total 2 (100%)

```

Tous les objets sont répliqués et vérifiés, tels que définis dans le [glossaire Geo](../../glossary.md). En savoir plus sur les méthodes que nous utilisons pour répliquer et vérifier chaque type de données dans [les types de données Geo pris en charge](../datatypes.md#data-types).

Pour trouver plus de détails sur les éléments ayant échoué, consultez [le fichier `gitlab-rails/geo.log`](../../../logs/log_parsing.md#find-most-common-geo-sync-errors)

Si vous constatez des échecs de réplication ou de vérification, vous pouvez essayer de [les résoudre](synchronization_verification.md).

##### Correction des erreurs trouvées lors de l'exécution de la tâche Rake de vérification Geo {#fixing-errors-found-when-running-the-geo-check-rake-task}

Lors de l'exécution de cette tâche Rake, vous pouvez voir des messages d'erreur si les nœuds ne sont pas correctement configurés :

```shell
sudo gitlab-rake gitlab:geo:check
```

- Rails n'a pas fourni de mot de passe lors de la connexion à la base de données.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... Exception: fe_sendauth: no password supplied
  GitLab Geo is enabled ... Exception: fe_sendauth: no password supplied
  ...
  Checking Geo ... Finished
  ```

  Assurez-vous d'avoir défini `gitlab_rails['db_password']` avec le mot de passe en texte brut utilisé lors de la création du hachage pour `postgresql['sql_user_password']`.

- Rails ne peut pas se connecter à la base de données.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... Exception: FATAL:  no pg_hba.conf entry for host "1.1.1.1",  user "gitlab", database "gitlabhq_production", SSL on
  FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL off
  GitLab Geo is enabled ... Exception: FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL on
  FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL off
  ...
  Checking Geo ... Finished
  ```

  Assurez-vous d'avoir inclus l'adresse IP du nœud rails dans `postgresql['md5_auth_cidr_addresses']`. Assurez-vous également d'avoir inclus le masque de sous-réseau sur l'adresse IP : `postgresql['md5_auth_cidr_addresses'] = ['1.1.1.1/32']`.

- Rails a fourni un mot de passe incorrect.

  ```plaintext
  Checking Geo ...
  GitLab Geo is available ... Exception: FATAL:  password authentication failed for user "gitlab"
  FATAL:  password authentication failed for user "gitlab"
  GitLab Geo is enabled ... Exception: FATAL:  password authentication failed for user "gitlab"
  FATAL:  password authentication failed for user "gitlab"
  ...
  Checking Geo ... Finished
  ```

  Vérifiez que le mot de passe correct est défini pour `gitlab_rails['db_password']` qui a été utilisé lors de la création du hachage dans `postgresql['sql_user_password']` en exécutant `gitlab-ctl pg-password-md5 gitlab` et en saisissant le mot de passe.

- La vérification retourne `not a secondary node`.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... yes
  GitLab Geo is enabled ... yes
  GitLab Geo tracking database is correctly configured ... not a secondary node
  Database replication enabled? ... not a secondary node
  ...
  Checking Geo ... Finished
  ```

  Assurez-vous d'avoir ajouté le site secondaire dans la zone **Admin** sous **Geo** > **Sites** sur l'interface web pour le site **principal**. Assurez-vous également d'avoir saisi `gitlab_rails['geo_node_name']` lors de l'ajout du site secondaire dans la zone **Admin** du site **principal**.

- La vérification retourne `Exception: PG::UndefinedTable: ERROR:  relation "geo_nodes" does not exist`.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... no
    Try fixing it:
    Add a new license that includes the GitLab Geo feature
    For more information see:
    https://about.gitlab.com/features/gitlab-geo/
  GitLab Geo is enabled ... Exception: PG::UndefinedTable: ERROR:  relation "geo_nodes" does not exist
  LINE 8:                WHERE a.attrelid = '"geo_nodes"'::regclass
                                             ^
  :               SELECT a.attname, format_type(a.atttypid, a.atttypmod),
                       pg_get_expr(d.adbin, d.adrelid), a.attnotnull, a.atttypid, a.atttypmod,
                       c.collname, col_description(a.attrelid, a.attnum) AS comment
                  FROM pg_attribute a
                  LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid AND a.attnum = d.adnum
                  LEFT JOIN pg_type t ON a.atttypid = t.oid
                  LEFT JOIN pg_collation c ON a.attcollation = c.oid AND a.attcollation <> t.typcollation
                 WHERE a.attrelid = '"geo_nodes"'::regclass
                   AND a.attnum > 0 AND NOT a.attisdropped
                 ORDER BY a.attnum
  ...
  Checking Geo ... Finished
  ```

  Lors d'une mise à jour de version majeure PostgreSQL (9 > 10), c'est attendu. Suivez [initiate-the-replication-process](../../setup/database.md#step-3-initiate-the-replication-process).

- Rails ne semble pas avoir la configuration nécessaire pour se connecter à la base de données de suivi Geo.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... yes
  GitLab Geo is enabled ... yes
  GitLab Geo tracking database is correctly configured ... no
  Try fixing it:
  Rails does not appear to have the configuration necessary to connect to the Geo tracking database. If the tracking database is running on a node other than this one, then you may need to add configuration.
  ...
  Checking Geo ... Finished
  ```

  - Si vous exécutez le site secondaire sur un nœud unique pour tous les services, suivez [Réplication de base de données Geo - Configurer le serveur secondaire](../../setup/database.md#step-2-configure-the-secondary-server).
  - Si vous exécutez la base de données de suivi du site secondaire sur son propre nœud, suivez [Geo pour plusieurs serveurs - Configurer la base de données de suivi Geo sur le site secondaire Geo](../multiple_servers.md#step-2-configure-the-geo-tracking-database-on-the-geo-secondary-site)
  - Si vous exécutez la base de données de suivi du site secondaire dans un cluster Patroni, suivez [Réplication de base de données Geo - Configuration du cluster Patroni pour la base de données PostgreSQL de suivi](../../setup/database.md#configuring-patroni-cluster-for-the-tracking-postgresql-database)
  - Si vous exécutez la base de données de suivi du site secondaire dans une base de données externe, suivez [Geo avec des instances PostgreSQL externes](../../setup/external_database.md#configure-the-tracking-database)
  - Si la tâche de vérification Geo a été exécutée sur un nœud qui n'exécute pas de service faisant fonctionner l'application GitLab Rails (Puma, Sidekiq ou Geo Log Cursor), cette erreur peut être ignorée. Le nœud n'a pas besoin que Rails soit configuré.

##### Message :  Container Registry Geo events ... none found {#message-container-registry-geo-events--none-found}

Si `Container Registry Geo events ... none found` s'affiche et que vous attendez la présence d'événements de réplication du registre de conteneurs, vérifiez que la configuration des notifications du registre sur le site **principal** est conforme au [guide de configuration de la réplication du registre de conteneurs](../container_registry.md#configure-primary-site).

##### Message :  Machine clock is synchronized ... Exception {#message-machine-clock-is-synchronized--exception}

La tâche Rake tente de vérifier que l'horloge du serveur est synchronisée avec NTP. Les horloges synchronisées sont requises pour que Geo fonctionne correctement. Par exemple, pour des raisons de sécurité, lorsque l'heure du serveur sur le site principal et le site secondaire diffèrent d'environ une minute ou plus, les requêtes entre les sites Geo échouent. Si cette tâche de vérification échoue pour une raison autre qu'une différence d'horaires, cela ne signifie pas nécessairement que Geo ne fonctionnera pas.

Le gem Ruby qui effectue la vérification est codé en dur avec `pool.ntp.org` comme source de référence temporelle.

- Message d'exception `Machine clock is synchronized ... Exception: Timeout::Error`

  Ce problème survient lorsque votre serveur ne peut pas accéder à l'hôte `pool.ntp.org`.

- Message d'exception `Machine clock is synchronized ... Exception: No route to host - recvfrom(2)`

  Ce problème survient lorsque le nom d'hôte `pool.ntp.org` se résout vers un serveur qui ne fournit pas de service de temps.

Dans ce cas, dans GitLab 15.7 et versions ultérieures, [spécifiez un serveur NTP personnalisé en utilisant des variables d'environnement](#health-check-rake-task).

Dans GitLab 15.6 et versions antérieures, utilisez l'une des solutions de contournement suivantes :

- Ajoutez des entrées dans `/etc/hosts` pour `pool.ntp.org` afin de diriger la requête vers des serveurs de temps locaux valides. Cela corrige le délai d'expiration prolongé et l'erreur de délai d'expiration.
- Dirigez la vérification vers n'importe quelle adresse IP valide. Cela résout le problème de délai d'expiration, mais la vérification échoue avec l'erreur `No route to host`, comme indiqué précédemment.

[Les déploiements GitLab natifs du cloud](https://docs.gitlab.com/charts/advanced/geo/#set-the-geo-primary-site) génèrent une erreur car les conteneurs dans Kubernetes n'ont pas accès à l'horloge de l'hôte :

```plaintext
Machine clock is synchronized ... Exception: getaddrinfo: Servname not supported for ai_socktype
```

##### Message : `cannot execute INSERT in a read-only transaction` {#message-cannot-execute-insert-in-a-read-only-transaction}

Lorsque cette erreur est rencontrée sur un site secondaire, elle affecte probablement toutes les utilisations de GitLab Rails telles que les commandes `gitlab-rails` ou `gitlab-rake`, ainsi que les services Puma, Sidekiq et Geo Log Cursor.

```plaintext
ActiveRecord::StatementInvalid: PG::ReadOnlySqlTransaction: ERROR:  cannot execute INSERT in a read-only transaction
/opt/gitlab/embedded/service/gitlab-rails/app/models/application_record.rb:86:in `block in safe_find_or_create_by'
/opt/gitlab/embedded/service/gitlab-rails/app/models/concerns/cross_database_modification.rb:92:in `block in transaction'
/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/database.rb:332:in `block in transaction'
/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/database.rb:331:in `transaction'
/opt/gitlab/embedded/service/gitlab-rails/app/models/concerns/cross_database_modification.rb:83:in `transaction'
/opt/gitlab/embedded/service/gitlab-rails/app/models/application_record.rb:86:in `safe_find_or_create_by'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:21:in `by_name'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:17:in `block in populate!'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:17:in `map'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:17:in `populate!'
/opt/gitlab/embedded/service/gitlab-rails/config/initializers/fill_shards.rb:9:in `<top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb:7:in `<top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
```

La base de données en lecture seule PostgreSQL produirait ces erreurs :

```plaintext
2023-01-17_17:44:54.64268 ERROR:  cannot execute INSERT in a read-only transaction
2023-01-17_17:44:54.64271 STATEMENT:  /*application:web,db_config_name:main*/ INSERT INTO "shards" ("name") VALUES ('storage1') RETURNING "id"
```

Cette situation peut survenir :

- Lors de la configuration initiale, lorsqu'un site secondaire n'est pas encore conscient qu'il est un site secondaire. Pour résoudre l'erreur, suivez [Étape 3. Ajouter le site secondaire](../configuration.md#step-3-add-the-secondary-site).
- Lors de la mise à jour d'un site Geo secondaire. Il est possible que `gitlab_rails['auto_migrate']` soit défini sur `true`, ce qui amène GitLab à tenter des migrations de base de données sur la base de données répliquée, ce qui n'est pas requis. Pour résoudre l'erreur :

  1. Connectez-vous en SSH en tant que root au nœud GitLab Rails du site secondaire.
  1. Modifiez `/etc/gitlab/gitlab.rb`, et commentez ce paramètre ou définissez-le sur false :

     ```ruby
     gitlab_rails['auto_migrate'] = false
     ```

  1. Reconfigurez GitLab :

     ```shell
     sudo gitlab-ctl reconfigure
     ```

### Vérifier si la réplication PostgreSQL fonctionne {#check-if-postgresql-replication-is-working}

Pour vérifier si la réplication PostgreSQL fonctionne, vérifiez si :

- [Les sites pointent vers le nœud de base de données correct](#are-sites-pointing-to-the-correct-database-node).
- [Geo peut détecter le site actuel correctement](#can-geo-detect-the-current-site-correctly).

Si vous rencontrez toujours des problèmes, consultez la [résolution des problèmes de réplication avancée](synchronization_verification.md).

#### Les sites pointent-ils vers le bon nœud de base de données ? {#are-sites-pointing-to-the-correct-database-node}

Vous devez vous assurer que votre **principal** Geo [site](../../glossary.md) pointe vers le nœud de base de données disposant des droits d'écriture.

Tous les sites **secondaire** ne doivent pointer que vers des nœuds de base de données en lecture seule.

#### Geo peut-il détecter le site actuel correctement ? {#can-geo-detect-the-current-site-correctly}

Geo trouve le nom du [site](../../glossary.md) Geo du nœud Puma ou Sidekiq actuel dans `/etc/gitlab/gitlab.rb` avec la logique suivante :

1. Obtenir le « Nom du nœud Geo » (il existe [un ticket pour renommer les paramètres en « Nom du site Geo »](https://gitlab.com/gitlab-org/gitlab/-/issues/335944)) :
   - Paquet Linux : obtenir le paramètre `gitlab_rails['geo_node_name']`.
   - Charts GitLab Helm : obtenir le paramètre `global.geo.nodeName` (voir [Charts avec GitLab Geo](https://docs.gitlab.com/charts/advanced/geo/)).
1. Si celui-ci n'est pas défini, obtenir le paramètre `external_url`.

Ce nom est utilisé pour rechercher le site Geo ayant le même **Nom** dans le tableau de bord **Sites Geo**.

Pour vérifier si la machine actuelle a un nom de site qui correspond à un site dans la base de données, exécutez la tâche de vérification :

```shell
sudo gitlab-rake gitlab:geo:check
```

Elle affiche le nom du site de la machine actuelle et indique si l'enregistrement de base de données correspondant est un site **principal** ou **secondaire**.

```plaintext
This machine's Geo node name matches a database record ... yes, found a secondary node named "Shanghai"
```

```plaintext
This machine's Geo node name matches a database record ... no
  Try fixing it:
  You could add or update a Geo node database record, setting the name to "https://example.com/".
  Or you could set this machine's Geo node name to match the name of an existing database record: "London", "Shanghai"
  For more information see:
  doc/administration/geo/replication/troubleshooting/_index.md#can-geo-detect-the-current-node-correctly
```

Pour plus d'informations sur les noms de sites recommandés dans la description du champ Nom, consultez [les paramètres communs de la zone **Admin** Geo](../../../geo_sites.md#common-settings).

### Vérifier la compatibilité des données de locale du système d'exploitation {#check-os-locale-data-compatibility}

Dans la mesure du possible, tous les nœuds Geo sur tous les sites doivent être déployés avec la même méthode et le même système d'exploitation, comme défini dans les [exigences pour l'exécution de Geo](../../_index.md#requirements-for-running-geo).

Si différents systèmes d'exploitation ou différentes versions de systèmes d'exploitation sont déployés sur les sites Geo, vous **must** effectuer une vérification de compatibilité des données de locale avant de configurer Geo. Vous devez également vérifier `glibc` lorsque vous utilisez un mélange de méthodes de déploiement GitLab. La locale peut différer entre une installation de paquet Linux, un conteneur GitLab Docker, un déploiement de chart Helm ou des services de base de données externes. Consultez la [documentation sur la mise à niveau des systèmes d'exploitation pour PostgreSQL](../../../postgresql/upgrading_os.md), y compris comment vérifier la compatibilité des versions de `glibc`.

Geo utilise PostgreSQL et la réplication en continu pour répliquer les données entre les sites Geo. PostgreSQL utilise les données de locale fournies par la bibliothèque C du système d'exploitation pour trier le texte. Si les données de locale dans la bibliothèque C sont incompatibles entre les sites Geo, cela provoque des résultats de requêtes erronés qui conduisent à un [comportement incorrect sur les sites secondaires](https://gitlab.com/gitlab-org/gitlab/-/issues/360723).

Par exemple, Ubuntu 18.04 (et antérieur) et RHEL/CentOS 7 (et antérieur) sont incompatibles avec leurs versions ultérieures. Consultez le [wiki PostgreSQL pour plus de détails](https://wiki.postgresql.org/wiki/Locale_data_changes).

## Correction des erreurs courantes {#fixing-common-errors}

Cette section documente les messages d'erreur courants signalés dans la zone **Admin** de l'interface web, et comment les corriger.

### Une base de données de suivi existante ne peut pas être réutilisée {#an-existing-tracking-database-cannot-be-reused}

Geo ne peut pas réutiliser une base de données de suivi existante.

Il est plus sûr d'utiliser un site secondaire vierge, ou de réinitialiser l'ensemble du site secondaire en suivant [Réinitialisation de la réplication du site secondaire Geo](synchronization_verification.md#resetting-geo-secondary-site-replication).

Il est risqué de réutiliser un site secondaire sans le réinitialiser car le site secondaire peut avoir manqué certains événements Geo. Par exemple, des événements de suppression manqués conduisent le site secondaire à conserver de façon permanente des données qui devraient être supprimées. De même, la perte d'un événement qui déplace physiquement l'emplacement des données conduit à des données définitivement orphelines dans un emplacement, et manquantes dans l'autre emplacement jusqu'à ce qu'elles soient re-vérifiées. C'est pourquoi GitLab est passé au stockage haché, ce qui rend inutile le déplacement des données. Il peut y avoir d'autres problèmes inconnus dus à des événements perdus.

Si ces types de risques ne s'appliquent pas, par exemple dans un environnement de test, ou si vous savez que la base de données Postgres principale contient encore tous les événements Geo depuis que le site Geo a été ajouté, vous pouvez contourner cette vérification de santé :

1. Obtenez l'heure du dernier événement traité. Dans la console Rails du site **secondaire**, exécutez :

   ```ruby
   Geo::EventLogState.last.created_at.utc
   ```

1. Copiez la sortie, par exemple `2024-02-21 23:50:50.676918 UTC`.
1. Mettez à jour l'heure de création du site secondaire pour le faire paraître plus ancien. Dans la console Rails du site **principal**, exécutez :

   ```ruby
   GeoNode.secondary_nodes.last.update_column(:created_at, DateTime.parse('2024-02-21 23:50:50.676918 UTC') - 1.second)
   ```

   Cette commande suppose que le site secondaire concerné est celui qui a été créé en dernier.

1. Mettez à jour le statut du site secondaire dans **Admin** > **Geo** > **Sites**. Dans la console Rails du site **secondaire**, exécutez :

   ```ruby
   Geo::MetricsUpdateWorker.new.perform
   ```

1. Le site secondaire devrait apparaître comme sain. Si ce n'est pas le cas, exécutez `gitlab-rake gitlab:geo:check` sur le site secondaire, ou essayez de redémarrer Rails si vous ne l'avez pas fait depuis que vous avez rajouté le site secondaire.
1. Pour resynchroniser les données manquantes ou obsolètes, accédez à **Admin** > **Geo** > **Sites**.
1. Sous le site secondaire, sélectionnez **Détails de Réplication**.
1. Sélectionnez **Tout revérifier** pour chaque type de données.

### Le site Geo a une base de données accessible en écriture {#geo-site-has-a-database-that-is-writable}

Ce message d'erreur fait référence à un problème avec le réplica de base de données sur un site **secondaire**, auquel Geo s'attend à avoir accès. Une base de données de site secondaire accessible en écriture indique que la base de données n'est pas configurée pour la réplication avec le site principal. Cela signifie généralement, soit :

- Une méthode de réplication non prise en charge a été utilisée (par exemple, la réplication logique).
- Les instructions pour configurer une [réplication de base de données Geo](../../setup/database.md) n'ont pas été suivies correctement.
- Les détails de connexion à votre base de données sont incorrects, c'est-à-dire que vous avez spécifié le mauvais utilisateur dans votre fichier `/etc/gitlab/gitlab.rb`.

Les sites Geo **secondaire** nécessitent deux instances PostgreSQL distinctes :

- Un réplica en lecture seule du site **principal**.
- Une instance normale accessible en écriture qui contient les métadonnées de réplication. C'est-à-dire la base de données de suivi Geo.

Ce message d'erreur indique que la base de données répliquée dans le site **secondaire** est mal configurée et que la réplication s'est arrêtée.

Pour restaurer la base de données et reprendre la réplication, vous pouvez effectuer l'une des actions suivantes :

- [Réinitialiser la réplication du site secondaire Geo](synchronization_verification.md#resetting-geo-secondary-site-replication).
- [Configurer un nouveau site Geo secondaire en utilisant le paquet Linux](../../setup/_index.md#using-linux-package-installations).

Si vous configurez un nouveau site secondaire depuis le début, vous devez également [supprimer l'ancien site du cluster Geo](../remove_geo_site.md).

### Le site Geo ne semble pas répliquer la base de données depuis le site principal {#geo-site-does-not-appear-to-be-replicating-the-database-from-the-primary-site}

Les problèmes les plus courants qui empêchent la base de données de se répliquer correctement sont :

- Les sites **Secondaire** ne peuvent pas atteindre le site **principal**. Vérifiez les identifiants et les [règles de pare-feu](../../_index.md#firewall-rules).
- Problèmes de certificat SSL. Assurez-vous d'avoir copié `/etc/gitlab/gitlab-secrets.json` depuis le site **principal**.
- Le disque de stockage de la base de données est plein.
- L'emplacement de réplication de la base de données est mal configuré.
- La base de données n'utilise pas d'emplacement de réplication ou une autre alternative et ne peut pas se mettre à jour car les fichiers WAL ont été purgés.

Assurez-vous de suivre les instructions de [réplication de base de données Geo](../../setup/database.md) pour la configuration prise en charge.

### La version de la base de données Geo (...) ne correspond pas à la dernière migration (...) {#geo-database-version--does-not-match-latest-migration-}

Si vous utilisez l'installation du paquet Linux, quelque chose a pu échouer lors de la mise à jour. Vous pouvez :

- Exécuter `sudo gitlab-ctl reconfigure`.
- Déclencher manuellement la migration de la base de données en exécutant : `sudo gitlab-rake db:migrate:geo` en tant que root sur le site **secondaire**.

### GitLab indique que plus de 100 % des dépôts ont été synchronisés {#gitlab-indicates-that-more-than-100-of-repositories-were-synced}

Cela peut être causé par des enregistrements orphelins dans le registre de projets. Ils sont nettoyés périodiquement à l'aide d'un worker de registre, laissez-lui donc un peu de temps pour se corriger automatiquement.

### Checksums échoués sur le site principal {#failed-checksums-on-primary-site}

Les checksums échoués identifiés par l'écran d'informations de vérification principale Geo peuvent être causés par des fichiers manquants ou des checksums non concordants. Vous pouvez trouver des messages d'erreur comme `"Repository cannot be checksummed because it does not exist"` ou `"File is not checksummable - file does not exist at: <path>"` dans le fichier `gitlab-rails/geo.log`. Le message d'erreur inclut le chemin du fichier pour aider à identifier le fichier manquant.

Pour des informations supplémentaires sur les éléments ayant échoué, exécutez les [tâches Rake de vérification d'intégrité](../../../raketasks/check.md#uploaded-files-integrity) :

```ruby
sudo gitlab-rake gitlab:artifacts:check
sudo gitlab-rake gitlab:ci_secure_files:check
sudo gitlab-rake gitlab:lfs:check
sudo gitlab-rake gitlab:uploads:check
```

Pour des informations détaillées sur les erreurs individuelles, utilisez la variable `VERBOSE=1`.

### Le site secondaire s'affiche comme **En mauvaise santé** dans l'interface utilisateur {#secondary-site-shows-unhealthy-in-ui}

Si vous avez mis à jour la valeur de `external_url` dans `/etc/gitlab/gitlab.rb` pour le site principal ou modifié le protocole de `http` à `https`, vous pouvez voir que les sites secondaires s'affichent comme **En mauvaise santé**. Vous pouvez également trouver l'erreur suivante dans `geo.log` :

```plaintext
"class": "Geo::NodeStatusRequestService",
...
"message": "Failed to Net::HTTP::Post to primary url: http://primary-site.gitlab.tld/api/v4/geo/status",
  "error": "Failed to open TCP connection to <PRIMARY_IP_ADDRESS>:80 (Connection refused - connect(2) for \"<PRIMARY_ID_ADDRESS>\" port 80)"
```

Dans ce cas, assurez-vous de mettre à jour l'URL modifiée sur tous vos sites :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Modifiez l'URL et enregistrez la modification.

### Message : `ERROR: canceling statement due to conflict with recovery` lors d'une sauvegarde {#message-error-canceling-statement-due-to-conflict-with-recovery-during-backup}

L'exécution d'une sauvegarde sur un site Geo **secondaire** [n'est pas prise en charge](https://gitlab.com/gitlab-org/gitlab/-/issues/211668).

Lors de l'exécution d'une sauvegarde sur un site **secondaire**, vous pourriez rencontrer le message d'erreur suivant :

```plaintext
Dumping PostgreSQL database gitlabhq_production ...
pg_dump: error: Dumping the contents of table "notes" failed: PQgetResult() failed.
pg_dump: error: Error message from server: ERROR:  canceling statement due to conflict with recovery
DETAIL:  User query might have needed to see row versions that must be removed.
pg_dump: error: The command was: COPY public.notes (id, note, [...], last_edited_at) TO stdout;
```

Pour éviter qu'une sauvegarde de base de données soit effectuée automatiquement lors des mises à jour de GitLab sur vos sites Geo **secondaries**, créez le fichier vide suivant :

```shell
sudo touch /etc/gitlab/skip-auto-backup
```

### Utilisation élevée du CPU sur le site principal lors de la vérification des objets {#high-cpu-usage-on-primary-during-object-verification}

De GitLab 16.11 à GitLab 17.2, un index PostgreSQL manquant provoque une utilisation élevée du CPU et une progression lente de la vérification des artefacts. De plus, les sites Geo secondaires peuvent se signaler comme non sains. Le [ticket 471727](https://gitlab.com/gitlab-org/gitlab/-/issues/471727) décrit le comportement en détail.

Pour déterminer si vous rencontrez ce problème, suivez les étapes pour [confirmer si vous êtes affecté](https://gitlab.com/gitlab-org/gitlab/-/issues/471727#to-confirm-if-you-are-affected).

Si vous êtes affecté, suivez les étapes de la [solution de contournement](https://gitlab.com/gitlab-org/gitlab/-/issues/471727#workaround) pour créer manuellement l'index. La création de l'index amène PostgreSQL à consommer légèrement plus de ressources jusqu'à ce qu'il se termine. Ensuite, l'utilisation du CPU peut rester élevée pendant que la vérification continue, mais les requêtes devraient se terminer beaucoup plus rapidement, et le statut du site secondaire devrait se mettre à jour correctement.

### Vérification échouée avec : `Verification timed out after (...)` {#verification-failed-with-verification-timed-out-after-}

Depuis GitLab 16.11, Geo peut créer des entrées `JobArtifactRegistry` dupliquées pour le même `artifact_id`, ce qui peut entraîner des échecs de synchronisation entre les sites principal et secondaires. Ce problème peut également impacter les entrées `UploadRegistry` et `PackageFileRegistry`.

Pour déterminer si vous rencontrez ce problème et supprimer les entrées dupliquées :

1. Ouvrez une [console Rails](../../../operations/rails_console.md) sur le site secondaire.
1. Obtenez le nombre d'ID d'enregistrements de modèle ayant des doublons :

   ```ruby
   artifact_ids = Geo::JobArtifactRegistry.group(:artifact_id).having('COUNT(*) > 1').pluck(:artifact_id); artifact_ids.size
   upload_ids = Geo::UploadRegistry.group(:file_id).having('COUNT(*) > 1').pluck(:file_id); upload_ids.size
   package_file_ids = Geo::PackageFileRegistry.group(:package_file_id).having('COUNT(*) > 1').pluck(:package_file_id); package_file_ids.size
   ```

1. Affichez les ID :

   ```ruby
   puts 'BEGIN Artifact IDs', artifact_ids, 'END Artifact IDs'
   puts 'BEGIN Upload IDs', upload_ids, 'END Upload IDs'
   puts 'BEGIN Package File IDs', package_file_ids, 'END Package File IDs'
   ```

   Si la sortie est vide, vous n'êtes pas affecté. Sinon, enregistrez la sortie du terminal dans un fichier texte au cas où vous perdriez la connexion ultérieurement.

1. Supprimez tous les doublons :

   ```ruby
   Geo::JobArtifactRegistry.where(artifact_id: artifact_ids).delete_all
   Geo::UploadRegistry.where(file_id: upload_ids).delete_all
   Geo::PackageFileRegistry.where(package_file_id: package_file_ids).delete_all
   ```

1. Attendez que les jobs en arrière-plan recréent les lignes du registre et resynchronisent.

Suivez le [ticket 479852](https://gitlab.com/gitlab-org/gitlab/-/issues/479852) pour obtenir des retours sur le correctif.

### Erreur `end of file reached` lors de l'exécution de la tâche Rake de vérification Geo sur le site secondaire {#error-end-of-file-reached-when-running-geo-rake-check-task-on-secondary}

Vous pouvez rencontrer l'erreur suivante lors de l'exécution de la [tâche Rake de vérification de santé](common.md#health-check-rake-task) sur le site secondaire :

```plaintext
Can connect to the primary node ... no
Reason:
end of file reached
```

Cela peut se produire si l'URL incorrecte du site principal a été spécifiée dans le paramètre. Pour résoudre le problème, exécutez les commandes suivantes dans [la console Rails](../../../operations/rails_console.md) :

```ruby
primary = Gitlab::Geo.primary_node
primary.internal_uri
Gitlab::HTTP.get(primary.internal_uri, allow_local_requests: true, limit: 10)
```

Assurez-vous que la valeur de `internal_uri` est correcte dans la sortie précédente. Si l'URL du site principal est incorrecte, vérifiez-la dans `/etc/gitlab/gitlab.rb`, et dans **Admin** > **Geo** > **Sites**.

### Charge excessive d'E/S de base de données due à la collecte des métriques Geo {#excessive-database-io-from-geo-metrics-collection}

Si vous rencontrez une charge élevée sur la base de données due à une collecte fréquente des métriques Geo, vous pouvez réduire la fréquence du job `geo_metrics_update_worker`. Cet ajustement peut aider à atténuer la charge sur la base de données dans les grandes instances GitLab où la collecte des métriques impacte significativement les performances de la base de données.

L'augmentation de l'intervalle signifie que vos métriques Geo sont mises à jour moins fréquemment. Cela entraîne des métriques obsolètes pour des périodes plus longues, ce qui peut affecter votre capacité à surveiller la réplication Geo en temps réel. Si les métriques sont obsolètes depuis plus de 10 minutes, le site est arbitrairement marqué comme « En mauvaise santé » dans la zone d'administration.

L'exemple suivant configure le job pour s'exécuter toutes les 30 minutes. Ajustez le calendrier cron selon vos besoins.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Ajoutez ou modifiez le paramètre suivant dans `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['geo_metrics_update_worker_cron'] = "*/30 * * * *"
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     ee_cron_jobs:
       geo_metrics_update_worker:
         cron: "*/30 * * * *"
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

#### Utiliser des résumés de vérification précalculés {#use-pre-calculated-verification-summaries}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/590853) dans GitLab 19.0 [avec un flag](../../../../administration/feature_flags/_index.md) nommé `geo_job_artifact_verification_summaries`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible pour les tests, mais n'est pas prête pour une utilisation en production.

Plutôt que de réduire la fréquence de collecte des métriques, vous pouvez activer les résumés de vérification précalculés pour les artefacts de job CI. Cela remplace les analyses de table complètes par des mises à jour incrémentielles, de sorte que seules les données modifiées sont recomptées.

Lorsqu'il est activé, un worker en arrière-plan maintient des comptages récapitulatifs dans une table dédiée. Un déclencheur de base de données marque les buckets affectés comme sales lorsque les états de vérification changent, et le worker recalcule uniquement ces buckets. Cela réduit la charge de base de données liée à la collecte des métriques de plusieurs ordres de grandeur sur les grandes instances.

Pour activer :

```shell
sudo gitlab-rails runner 'Feature.enable(:geo_job_artifact_verification_summaries)'
```

Pour désactiver :

```shell
sudo gitlab-rails runner 'Feature.disable(:geo_job_artifact_verification_summaries)'
```
