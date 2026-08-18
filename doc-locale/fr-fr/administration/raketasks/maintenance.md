---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tâches Rake de maintenance
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab fournit des tâches Rake pour la maintenance générale.

## Recueillir des informations sur GitLab et le système {#gather-gitlab-and-system-information}

Cette commande recueille des informations sur votre installation GitLab et le système sur lequel elle s'exécute. Ces informations peuvent être utiles lorsque vous demandez de l'aide ou signalez des problèmes. Dans un environnement multi-nœuds, exécutez cette commande sur les nœuds exécutant GitLab Rails afin d'éviter les erreurs de socket PostgreSQL.

- Installations avec le paquet Linux :

  ```shell
  sudo gitlab-rake gitlab:env:info
  ```

- Installations compilées manuellement :

  ```shell
  bundle exec rake gitlab:env:info RAILS_ENV=production
  ```

Exemple de sortie :

```plaintext
System information
System:         Ubuntu 20.04
Proxy:          no
Current User:   git
Using RVM:      no
Ruby Version:   2.7.6p219
Gem Version:    3.1.6
Bundler Version:2.3.15
Rake Version:   13.0.6
Redis Version:  6.2.7
Sidekiq Version:6.4.2
Go Version:     unknown

GitLab information
Version:        15.5.5-ee
Revision:       5f5109f142d
Directory:      /opt/gitlab/embedded/service/gitlab-rails
DB Adapter:     PostgreSQL
DB Version:     13.8
URL:            https://app.gitaly.gcp.gitlabsandbox.net
HTTP Clone URL: https://app.gitaly.gcp.gitlabsandbox.net/some-group/some-project.git
SSH Clone URL:  git@app.gitaly.gcp.gitlabsandbox.net:some-group/some-project.git
Elasticsearch:  no
Geo:            no
Using LDAP:     no
Using Omniauth: yes
Omniauth Providers:

GitLab Shell
Version:        14.12.0
Repository storage paths:
- default:      /var/opt/gitlab/git-data/repositories
- gitaly:       /var/opt/gitlab/git-data/repositories
GitLab Shell path:              /opt/gitlab/embedded/service/gitlab-shell


Gitaly
- default Address:      unix:/var/opt/gitlab/gitaly/gitaly.socket
- default Version:      15.5.5
- default Git Version:  2.37.1.gl1
- gitaly Address:       tcp://10.128.20.6:2305
- gitaly Version:       15.5.5
- gitaly Git Version:   2.37.1.gl1
```

## Afficher les informations de licence GitLab {#show-gitlab-license-information}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Cette commande affiche des informations sur votre [licence GitLab](../license.md) et le nombre de sièges utilisés. Elle est uniquement disponible sur les installations GitLab Enterprise : une licence ne peut pas être installée dans GitLab Community Edition.

Ces informations peuvent être utiles lorsque vous ouvrez des tickets auprès du support, ou pour vérifier vos paramètres de licence par programmation.

- Installations avec le paquet Linux :

  ```shell
  sudo gitlab-rake gitlab:license:info
  ```

- Installations compilées manuellement :

  ```shell
  bundle exec rake gitlab:license:info RAILS_ENV=production
  ```

Exemple de sortie :

```plaintext
Today's Date: 2020-02-29
Current User Count: 30
Max Historical Count: 30
Max Users in License: 40
License valid from: 2019-11-29 to 2020-11-28
Email associated with license: user@example.com
```

## Vérifier la configuration de GitLab {#check-gitlab-configuration}

La tâche Rake `gitlab:check` exécute les tâches Rake suivantes :

- `gitlab:gitlab_shell:check`
- `gitlab:gitaly:check`
- `gitlab:sidekiq:check`
- `gitlab:incoming_email:check`
- `gitlab:ldap:check`
- `gitlab:app:check`
- `gitlab:geo:check` (uniquement si vous exécutez [Geo](../geo/replication/troubleshooting/common.md#health-check-rake-task))

Elle vérifie que chaque composant a été configuré conformément au guide d'installation et suggère des correctifs pour les problèmes détectés. Cette commande doit être exécutée depuis votre serveur d'application et ne fonctionne pas correctement sur les serveurs de composants tels que [Gitaly](../gitaly/configure_gitaly.md#run-gitaly-on-its-own-server).

Vous pouvez également consulter nos guides de dépannage pour :

- [GitLab](../troubleshooting/_index.md).
- [Installations avec le paquet Linux](https://docs.gitlab.com/omnibus/#troubleshooting).

De plus, vous devriez également [vérifier que les valeurs de la base de données peuvent être déchiffrées à l'aide des secrets actuels](check.md#verify-database-values-can-be-decrypted-using-the-current-secrets).

Pour exécuter `gitlab:check`, lancez :

- Installations avec le paquet Linux :

  ```shell
  sudo gitlab-rake gitlab:check
  ```

- Installations compilées manuellement :

  ```shell
  bundle exec rake gitlab:check RAILS_ENV=production
  ```

- Installations Kubernetes :

  ```shell
  kubectl exec -it <toolbox-pod-name> -- sudo gitlab-rake gitlab:check
  ```

  > [!note]
  > En raison de l'architecture spécifique des installations GitLab basées sur Helm, la sortie peut contenir des faux négatifs pour la vérification de la connectivité à `gitlab-shell`, Sidekiq et aux fichiers liés à `systemd`. Ces échecs signalés sont attendus et n'indiquent pas de problèmes réels ; ignorez-les lors de l'examen des résultats de diagnostic.

Utilisez `SANITIZE=true` pour `gitlab:check` si vous souhaitez omettre les noms de projets de la sortie.

Exemple de sortie :

```plaintext
Checking Environment ...

Git configured for git user? ... yes
Has python2? ... yes
python2 is supported version? ... yes

Checking Environment ... Finished

Checking GitLab Shell ...

GitLab Shell version? ... OK (1.2.0)
Repo base directory exists? ... yes
Repo base directory is a symlink? ... no
Repo base owned by git:git? ... yes
Repo base access is drwxrws---? ... yes
post-receive hook up-to-date? ... yes
post-receive hooks in repos are links: ... yes

Checking GitLab Shell ... Finished

Checking Sidekiq ...

Running? ... yes

Checking Sidekiq ... Finished

Checking GitLab App...

Database config exists? ... yes
Database is SQLite ... no
All migrations up? ... yes
GitLab config exists? ... yes
GitLab config up to date? ... no
Cable config exists? ... yes
Resque config exists? ... yes
Log directory writable? ... yes
Tmp directory writable? ... yes
Init script exists? ... yes
Init script up-to-date? ... yes
Redis version >= 2.0.0? ... yes

Checking GitLab ... Finished
```

## Reconstruire le fichier `authorized_keys` {#rebuild-authorized_keys-file}

Dans certains cas, il est nécessaire de reconstruire le fichier `authorized_keys`, par exemple, si après une mise à niveau vous recevez `Permission denied (publickey)` lors d'un envoi [via SSH](../../user/ssh.md) et trouvez des erreurs `404 Key Not Found` dans [le fichier `gitlab-shell.log`](../logs/_index.md#gitlab-shelllog). Pour reconstruire `authorized_keys`, exécutez :

- Installations avec le paquet Linux :

  ```shell
  sudo gitlab-rake gitlab:shell:setup
  ```

- Installations compilées manuellement :

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake gitlab:shell:setup RAILS_ENV=production
  ```

Exemple de sortie :

```plaintext
This will rebuild an authorized_keys file.
You will lose any data stored in authorized_keys file.
Do you want to continue (yes/no)? yes
```

## Vider le cache Redis {#clear-redis-cache}

Si, pour une raison quelconque, le tableau de bord affiche des informations incorrectes, vous pouvez vider le cache de Redis. Pour ce faire, exécutez :

- Installations avec le paquet Linux :

  ```shell
  sudo gitlab-rake cache:clear
  ```

- Installations compilées manuellement :

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
  ```

## Précompiler les ressources {#precompile-the-assets}

Parfois, lors de mises à niveau de version, vous pouvez vous retrouver avec des CSS incorrects ou des icônes manquantes. Dans ce cas, essayez de précompiler à nouveau les ressources.

Cette tâche Rake s'applique uniquement aux installations compilées manuellement. [En savoir plus](../../update/package/package_troubleshooting.md#missing-asset-files) sur le dépannage de ce problème lors de l'utilisation du paquet Linux. Les instructions pour le paquet Linux peuvent être applicables aux déploiements Kubernetes et Docker de GitLab, bien qu'en général, les installations basées sur des conteneurs ne rencontrent pas de problèmes de ressources manquantes.

- Installations compilées manuellement :

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production
  ```

Pour les installations avec le paquet Linux, les ressources non optimisées (JavaScript, CSS) sont figées lors de la release de GitLab en amont. L'installation avec le paquet Linux inclut des versions optimisées de ces ressources. Sauf si vous modifiez le code JavaScript / CSS sur votre machine de production après l'installation du paquet, il ne devrait y avoir aucune raison de réexécuter `rake gitlab:assets:compile` sur la machine de production. Si vous pensez que les ressources ont été corrompues, vous devriez réinstaller le paquet Linux.

## Vérifier la connectivité TCP vers un site distant {#check-tcp-connectivity-to-a-remote-site}

Parfois, vous devez savoir si votre installation GitLab peut se connecter à un service TCP sur une autre machine (par exemple, un serveur PostgreSQL ou un serveur web) pour résoudre des problèmes de proxy. Une tâche Rake est incluse pour vous aider à cet égard.

- Installations avec le paquet Linux :

  ```shell
  sudo gitlab-rake gitlab:tcp_check[example.com,80]
  ```

- Installations compilées manuellement :

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake gitlab:tcp_check[example.com,80] RAILS_ENV=production
  ```

## Effacer le bail exclusif (DANGER) {#clear-exclusive-lease-danger}

GitLab utilise un mécanisme de verrou partagé : `ExclusiveLease` pour prévenir les opérations simultanées sur une ressource partagée. Par exemple, l'exécution périodique du ramasse-miettes sur les dépôts.

Dans des situations très spécifiques, une opération verrouillée par un bail exclusif peut échouer sans libérer le verrou. Si vous ne pouvez pas attendre son expiration, vous pouvez exécuter cette tâche pour l'effacer manuellement.

Pour effacer tous les baux exclusifs :

> [!warning]
> N'exécutez pas cette commande pendant que GitLab ou Sidekiq est en cours d'exécution

```shell
sudo gitlab-rake gitlab:exclusive_lease:clear
```

Pour spécifier un `type` de bail ou un `type + id` de bail, spécifiez une portée :

```shell
# to clear all leases for repository garbage collection:
sudo gitlab-rake gitlab:exclusive_lease:clear[project_housekeeping:*]

# to clear a lease for repository garbage collection in a specific project: (id=4)
sudo gitlab-rake gitlab:exclusive_lease:clear[project_housekeeping:4]
```

## Afficher le statut des migrations de base de données {#display-status-of-database-migrations}

Consultez la [documentation sur les migrations en arrière-plan](../../update/background_migrations.md) pour savoir comment vérifier que les migrations sont terminées lors de la mise à niveau de GitLab.

Pour vérifier le statut de migrations spécifiques, vous pouvez utiliser la tâche Rake suivante :

```shell
sudo gitlab-rake db:migrate:status
```

Pour vérifier la [base de données de suivi sur un site secondaire Geo](../geo/setup/external_database.md#configure-the-tracking-database), vous pouvez utiliser la tâche Rake suivante :

```shell
sudo gitlab-rake db:migrate:status:geo
```

Cela génère un tableau avec un `Status` de `up` ou `down` pour chaque migration. Exemple :

```shell
database: gitlabhq_production

 Status   Migration ID    Type     Milestone    Name
--------------------------------------------------
   up     20240701074848  regular  17.2         AddGroupIdToPackagesDebianGroupComponents
   up     20240701153843  regular  17.2         AddWorkItemsDatesSourcesSyncToIssuesTrigger
   up     20240702072515  regular  17.2         AddGroupIdToPackagesDebianGroupArchitectures
   up     20240702133021  regular  17.2         AddWorkspaceTerminationTimeoutsToRemoteDevelopmentAgentConfigs
   up     20240604064938  post     17.2         FinalizeBackfillPartitionIdCiPipelineMessage
   up     20240604111157  post     17.2         AddApprovalPolicyRulesFkOnApprovalGroupRules
```

À partir de GitLab 17.1, les migrations sont exécutées dans un ordre conforme à la cadence de release de GitLab.

## Exécuter les migrations de base de données incomplètes {#run-incomplete-database-migrations}

Les migrations de base de données peuvent rester bloquées dans un état incomplet, avec un statut `down` dans la sortie de la commande `sudo gitlab-rake db:migrate:status`.

1. Pour terminer ces migrations, utilisez la tâche Rake suivante :

   ```shell
   sudo gitlab-rake db:migrate
   ```

1. Une fois la commande terminée, exécutez `sudo gitlab-rake db:migrate:status` pour vérifier si toutes les migrations sont terminées (ont un statut `up`).
1. Rechargement à chaud des services `puma` et `sidekiq` :

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   ```

À partir de GitLab 17.1, les migrations sont exécutées dans un ordre conforme à la cadence de release de GitLab.

## Reconstruire les index de base de données {#rebuild-database-indexes}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/42705) dans GitLab 13.5 [avec un indicateur](../feature_flags/_index.md) nommé `database_reindexing`. Désactivé par défaut.
- [Activé sur GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/3989) dans GitLab 13.9.
- [Activé sur GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188548) dans GitLab 18.0.

{{< /history >}}

> [!warning]
> À utiliser avec précaution dans un environnement de production, et à exécuter pendant les heures creuses.

Les index de base de données peuvent être reconstruits régulièrement pour récupérer de l'espace et maintenir des niveaux de fragmentation d'index sains au fil du temps. La réindexation peut également être exécutée en tant que [tâche cron régulière](https://docs.gitlab.com/omnibus/settings/database/#automatic-database-reindexing). Un niveau de fragmentation « sain » dépend fortement de l'index spécifique, mais doit généralement être inférieur à 30 %.

La réindexation de la base de données effectue les tâches suivantes :

1. Réindexe les index PostgreSQL mis en file d'attente manuellement :  Un index peut être ajouté manuellement à une file d'attente pour la réindexation. La réindexation d'un index PostgreSQL réduit généralement la [fragmentation des index](https://wiki.postgresql.org/wiki/Index_Maintenance#Index_Bloat).
1. Réindexe automatiquement les index PostgreSQL à l'aide d'une heuristique de [fragmentation des index](https://wiki.postgresql.org/wiki/Index_Maintenance#Index_Bloat) :  PostgreSQL utilise une heuristique pour identifier les index les plus fragmentés. Le processus choisit au maximum 2 index lors de chaque exécution à réindexer.

Prérequis :

- Cette fonctionnalité requiert PostgreSQL 12 ou une version ultérieure.
- Ces types d'index ne sont **pas pris en charge** : les index d'expression et les index utilisés pour l'exclusion de contraintes.

### Exécuter la réindexation {#run-reindexing}

La tâche suivante ne reconstruit que les deux index de chaque base de données présentant la fragmentation la plus élevée. Pour reconstruire plus de deux index, réexécutez la tâche jusqu'à ce que tous les index souhaités aient été reconstruits.

1. Exécutez la tâche de réindexation :

   ```shell
   sudo gitlab-rake gitlab:db:reindex
   ```

1. Vérifiez [`application_json.log`](../logs/_index.md#application_jsonlog) pour confirmer l'exécution ou pour effectuer le dépannage.

Pour les installations Cloud Native de GitLab exécutant cette tâche à l'aide du [chart Toolbox](https://docs.gitlab.com/charts/charts/gitlab/toolbox/#configure-periodic-database-reindexing), les journaux se trouvent dans la sortie standard du pod.

### Personnaliser les paramètres de réindexation {#customize-reindexing-settings}

Pour les instances plus petites ou pour ajuster le comportement de réindexation, vous pouvez modifier ces paramètres à l'aide de la console Rails :

```shell
sudo gitlab-rails console
```

Personnalisez ensuite la configuration :

```ruby
# Lower minimum index size to 100 MB (default is 1 GB)
Gitlab::Database::Reindexing.minimum_index_size!(100.megabytes)

# Change minimum bloat threshold to 30% (default is 20%, there is no benefit from setting it lower)
Gitlab::Database::Reindexing.minimum_relative_bloat_size!(0.3)
```

### Réindexation automatisée {#automated-reindexing}

Pour les instances plus importantes avec une taille de base de données significative, automatisez la réindexation de la base de données en la planifiant pour qu'elle s'exécute pendant les périodes de faible activité.

#### Planifier avec crontab {#schedule-with-crontab}

Pour les installations GitLab empaquetées, utilisez crontab :

1. Modifiez le crontab :

   ```shell
   sudo crontab -e
   ```

1. Ajoutez une entrée selon votre planification préférée :

   1. Option 1 :  Exécuter quotidiennement pendant les périodes creuses

   ```shell
   # Run database reindexing every day at 21:12
   # The log will be rotated by the packaged logrotate daemon
   12 21 * * * /opt/gitlab/bin/gitlab-rake gitlab:db:reindex >> /var/log/gitlab/gitlab-rails/cron_reindex.log 2>&1
   ```

   1. Option 2 :  Exécuter uniquement les week-ends

   ```shell
   # Run database reindexing at 01:00 AM on weekends
   0 1 * * 0,6 /opt/gitlab/bin/gitlab-rake gitlab:db:reindex >> /var/log/gitlab/gitlab-rails/cron_reindex.log 2>&1
   ```

   1. Option 3 :  Exécuter fréquemment pendant les heures de faible trafic

   ```shell
   # Run database reindexing every 3 hours during night hours (22:00-07:00)
   0 22,1,4,7 * * * /opt/gitlab/bin/gitlab-rake gitlab:db:reindex >> /var/log/gitlab/gitlab-rails/cron_reindex.log 2>&1
   ```

Pour les déploiements Kubernetes, vous pouvez créer une planification similaire à l'aide de la ressource CronJob pour exécuter la tâche de réindexation.

### Notes {#notes}

- La reconstruction des index de base de données est une tâche gourmande en disque, c'est pourquoi vous devez l'effectuer pendant les heures creuses. L'exécution de la tâche pendant les heures de pointe peut entraîner une fragmentation accrue et peut également provoquer un ralentissement de certaines requêtes.
- La tâche nécessite de l'espace disque libre pour l'index en cours de restauration. Les index créés sont suffixés par `_ccnew`. Si la tâche de réindexation échoue, la réexécution de la tâche nettoie les index temporaires.
- Le temps nécessaire à la reconstruction des index de base de données dépend de la taille de la base de données cible. Cela peut prendre entre plusieurs heures et plusieurs jours.
- La tâche utilise des verrous Redis ; il est donc sûr de la planifier pour qu'elle s'exécute fréquemment. C'est une opération sans effet si une autre tâche de réindexation est déjà en cours d'exécution.

## Exporter le schéma de la base de données {#dump-the-database-schema}

Dans de rares circonstances, le schéma de la base de données peut différer de ce qu'attend le code de l'application, même si toutes les migrations de base de données sont terminées. Si cela se produit, cela peut entraîner des erreurs inattendues dans GitLab.

Pour exporter le schéma de la base de données :

```shell
SCHEMA=/tmp/structure.sql gitlab-rake db:schema:dump
```

La tâche Rake crée un fichier `/tmp/structure.sql` contenant l'export du schéma de la base de données.

Pour déterminer s'il existe des différences :

1. Accédez au fichier [`db/structure.sql`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/structure.sql) dans le projet [`gitlab`](https://gitlab.com/gitlab-org/gitlab). Sélectionnez la branche correspondant à votre version de GitLab. Par exemple, le fichier pour GitLab 16.2 : <https://gitlab.com/gitlab-org/gitlab/-/blob/16-2-stable-ee/db/structure.sql>.
1. Comparez `/tmp/structure.sql` avec le fichier `db/structure.sql` pour votre version.

## Vérifier la base de données pour détecter les incohérences de schéma {#check-the-database-for-schema-inconsistencies}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/390719) dans GitLab 15.11.

{{< /history >}}

Cette tâche Rake vérifie le schéma de la base de données pour détecter toute incohérence et les affiche dans le terminal. Cette tâche est un outil de diagnostic à utiliser sous la guidance du support GitLab. Vous ne devez pas utiliser cette tâche pour des vérifications de routine, car des incohérences de base de données peuvent être attendues.

```shell
gitlab-rake gitlab:db:schema_checker:run
```

## Collecter des informations et des statistiques sur la base de données {#collect-information-and-statistics-about-the-database}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-com/-/epics/2456) dans GitLab 17.11.

{{< /history >}}

La commande `gitlab:db:sos` recueille des données de configuration, de performance et de diagnostic sur votre base de données GitLab pour vous aider à résoudre les problèmes. L'endroit où vous exécutez cette commande dépend de votre configuration. Assurez-vous d'exécuter cette commande relativement à l'endroit où GitLab est installé `(/gitlab)`.

- **GitLab mis à l'échelle** : sur votre serveur Puma ou Sidekiq.
- **Installation cloud-native** : sur le pod toolbox.
- **Toutes les autres configurations** : sur votre serveur GitLab.

Modifiez la commande si nécessaire :

- **Chemin par défaut** \- Pour exécuter la commande avec le chemin de fichier par défaut (`/var/opt/gitlab/gitlab-rails/tmp/sos.zip`), exécutez `gitlab-rake gitlab:db:sos`.
- **Chemin personnalisé** \- Pour modifier le chemin du fichier, exécutez `gitlab-rake gitlab:db:sos["/absolute/custom/path/to/file.zip"]`.
- **Utilisateurs Zsh** \- Si vous n'avez pas modifié votre configuration Zsh, vous devez ajouter des guillemets autour de la commande entière, comme ceci : `gitlab-rake "gitlab:db:sos[/absolute/custom/path/to/file.zip]"`

La tâche Rake s'exécute pendant cinq minutes. Elle crée un dossier compressé dans le chemin que vous spécifiez. Le dossier compressé contient un grand nombre de fichiers.

### Activer les données statistiques de requêtes optionnelles {#enable-optional-query-statistics-data}

La tâche Rake `gitlab:db:sos` peut également recueillir des données pour le dépannage des requêtes lentes à l'aide de l'[extension `pg_stat_statements`](https://www.postgresql.org/docs/16/pgstatstatements.html).

L'activation de cette extension est facultative et nécessite le redémarrage de PostgreSQL et de GitLab. Ces données sont probablement nécessaires pour résoudre les problèmes de performance de GitLab causés par des requêtes de base de données lentes.

Prérequis :

- Vous devez être un utilisateur PostgreSQL disposant de privilèges superutilisateur pour activer ou désactiver une extension.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` pour ajouter la ligne suivante :

   ```ruby
   postgresql['shared_preload_libraries'] = 'pg_stat_statements'
   ```

1. Exécutez la reconfiguration :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. PostgreSQL doit redémarrer pour charger cette extension, ce qui nécessite également un redémarrage de GitLab :

   ```shell
   sudo gitlab-ctl restart postgresql
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart puma
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` pour ajouter la ligne suivante :

   ```ruby
   postgresql['shared_preload_libraries'] = 'pg_stat_statements'
   ```

1. Exécutez la reconfiguration :

   ```shell
   docker exec -it <container-id> gitlab-ctl reconfigure
   ```

1. PostgreSQL doit redémarrer pour charger cette extension, ce qui nécessite également un redémarrage de GitLab :

   ```shell
   docker exec -it <container-id> gitlab-ctl restart postgresql
   docker exec -it <container-id> gitlab-ctl restart sidekiq
   docker exec -it <container-id> gitlab-ctl restart puma
   ```

{{< /tab >}}

{{< tab title="Service PostgreSQL externe" >}}

1. Ajoutez ou décommentez les paramètres suivants dans votre fichier `postgresql.conf`

   ```shell
   shared_preload_libraries = 'pg_stat_statements'
   pg_stat_statements.track = all
   ```

1. Redémarrez PostgreSQL pour que les modifications prennent effet.
1. Redémarrez GitLab : les services web (Puma) et Sidekiq doivent être redémarrés.

{{< /tab >}}

{{< /tabs >}}

1. Sur la [console de base de données](../troubleshooting/postgresql.md), exécutez :

   ```SQL
   CREATE EXTENSION pg_stat_statements;
   ```

1. Vérifiez que l'extension fonctionne :

   ```SQL
   SELECT extname FROM pg_extension WHERE extname = 'pg_stat_statements';
   SELECT * FROM pg_stat_statements LIMIT 10;
   ```

## Vérifier la base de données pour détecter les tags CI/CD en double {#check-the-database-for-duplicate-cicd-tags}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/518698) dans GitLab 17.10.

{{< /history >}}

Cette tâche Rake vérifie la base de données `ci` pour détecter les tags en double dans la table `tags`. Ce problème peut affecter les instances ayant subi plusieurs mises à niveau majeures sur une période prolongée. Exécutez la commande suivante pour rechercher les tags en double, puis réécrire toutes les affectations de tags qui référencent des tags en double pour utiliser le tag original à la place.

```shell
sudo gitlab-rake gitlab:db:deduplicate_tags
```

Pour exécuter cette commande en mode simulation, définissez la variable d'environnement `DRY_RUN=true`.

## Détecter les incompatibilités de version de collation PostgreSQL {#detect-postgresql-collation-version-mismatches}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195450) dans GitLab 18.2.
- Vérification ponctuelle d'un ensemble prédéfini d'index pour détecter la corruption, [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198071) dans GitLab 18.3.
- Option de personnalisation de `MAX_TABLE_SIZE` et de contournement de PgBouncer, [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202736) dans GitLab 18.4.

{{< /history >}}

Le vérificateur de collation PostgreSQL :

- Détecte les incompatibilités de version de collation entre la base de données et le système d'exploitation pouvant provoquer une corruption des index. PostgreSQL utilise la bibliothèque `glibc` du système d'exploitation pour la collation des chaînes (règles de tri et de comparaison).
- Effectue des vérifications ponctuelles de corruption (détection de doublons) sur un ensemble prédéfini d'index. Ces index sont connus pour être sujets à des problèmes de corruption en raison d'incompatibilités de collation.

Exécutez cette tâche après les mises à niveau du système d'exploitation qui modifient la bibliothèque `glibc` sous-jacente.

Prérequis :

- PostgreSQL 13 ou version ultérieure.

Pour vérifier les incompatibilités de collation PostgreSQL et la corruption d'index associée dans toutes les bases de données :

```shell
sudo gitlab-rake gitlab:db:collation_checker
```

Pour vérifier une base de données spécifique :

```shell
# Check main database
sudo gitlab-rake gitlab:db:collation_checker:main

# Check CI database
sudo gitlab-rake gitlab:db:collation_checker:ci
```

### Ajuster les limites de taille des tables {#adjust-table-size-limits}

Par défaut, les tables de plus de 1 Go sont ignorées pour éviter les requêtes de longue durée susceptibles d'affecter les performances de la base de données. Vous pouvez ajuster le seuil de taille des tables en définissant la variable d'environnement `MAX_TABLE_SIZE`.

> [!warning]
> L'augmentation de la limite de taille des tables peut entraîner des requêtes de longue durée susceptibles d'affecter les performances de la base de données.

```shell
# Set custom table size limit (in bytes)
# to increase the max table size threshold to 10 GB
MAX_TABLE_SIZE=10737418240 sudo gitlab-rake gitlab:db:collation_checker:main
```

### Contourner PgBouncer pour les requêtes de longue durée {#bypass-pgbouncer-for-long-running-queries}

Consultez [résoudre les erreurs de délai d'expiration des instructions](#resolve-statement-timeout-errors) dans la section de dépannage.

### Exemple de sortie {#example-output}

Lorsqu'aucun problème n'est détecté :

```plaintext
Checking for PostgreSQL collation mismatches on main database...
No collation mismatches detected on main.
Found 8 indexes to corruption spot check.
No corrupted indexes detected.
```

Si des incompatibilités sont détectées, la tâche fournit des étapes de remédiation pour corriger les index affectés.

Exemple de sortie avec des incompatibilités :

```plaintext
Checking for PostgreSQL collation mismatches on main database...
⚠️ COLLATION MISMATCHES DETECTED on main database!
2 collation(s) have version mismatches:
  - en_US.utf8: stored=428.1, actual=513.1
  - es_ES.utf8: stored=428.1, actual=513.1

Found 8 indexes to corruption spot check.
Affected indexes that need to be rebuilt:
  - index_projects_on_name (btree) on table projects
    • Issues detected: duplicates
    • Affected columns: name
    • Type: UNIQUE
    • Needs deduplication: Yes

REMEDIATION STEPS:
1. Put GitLab into maintenance mode
2. Run the following SQL commands:

# Step 1: Check for duplicate entries in unique indexes
SELECT name, COUNT(*), ARRAY_AGG(id) FROM projects GROUP BY name HAVING COUNT(*) > 1 LIMIT 1;

# If duplicates exist, you may need to use gitlab:db:deduplicate_tags or similar tasks
# to fix duplicate entries before rebuilding unique indexes.

# Step 2: Rebuild affected indexes
# Option A: Rebuild individual indexes with minimal downtime:
REINDEX INDEX CONCURRENTLY index_projects_on_name;

# Option B: Alternatively, rebuild all indexes at once (requires downtime):
REINDEX DATABASE main;

# Step 3: Refresh collation versions
ALTER DATABASE main REFRESH COLLATION VERSION;

3. Take GitLab out of maintenance mode
```

Pour plus d'informations sur les problèmes de collation PostgreSQL et leur impact sur les index de base de données, consultez la [documentation sur la mise à niveau du système d'exploitation PostgreSQL](../postgresql/upgrading_os.md).

## Réparer les index de base de données corrompus {#repair-corrupted-database-indexes}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196677) dans GitLab 18.2.
- Option de contournement de PgBouncer, [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203843) dans GitLab 18.4.

{{< /history >}}

L'outil de réparation des index corrige les index de base de données corrompus ou manquants pouvant causer des problèmes d'intégrité des données. L'outil traite des index problématiques spécifiques affectés par des incompatibilités de collation ou d'autres problèmes de corruption. L'outil :

- Déduplique les données lorsque des index uniques sont corrompus.
- Met à jour les références pour maintenir l'intégrité des données.
- Reconstruit ou crée des index avec la configuration correcte.

Avant de réparer les index, exécutez l'outil en mode simulation pour analyser les modifications potentielles :

```shell
sudo DRY_RUN=true gitlab-rake gitlab:db:repair_index
```

L'exemple de sortie suivant montre les modifications :

```shell
INFO -- : DRY RUN: Analysis only, no changes will be made.
INFO -- : Running Index repair on database main...
INFO -- : Processing index 'index_merge_request_diff_commit_users_on_name_and_email'...
INFO -- : Index is unique. Checking for duplicate data...
INFO -- : No duplicates found in 'merge_request_diff_commit_users' for columns: name,email.
INFO -- : Index exists. Reindexing...
INFO -- : Index reindexed successfully.
```

Pour réparer tous les index problématiques connus dans toutes les bases de données :

```shell
sudo gitlab-rake gitlab:db:repair_index
```

La commande traite chaque base de données et répare les index. Par exemple :

```shell
INFO -- : Running Index repair on database main...
INFO -- : Processing index 'index_merge_request_diff_commit_users_on_name_and_email'...
INFO -- : Index is unique. Checking for duplicate data...
INFO -- : No duplicates found in 'merge_request_diff_commit_users' for columns: name,email.
INFO -- : Index does not exist. Creating new index...
INFO -- : Index created successfully.
INFO -- : Index repair completed for database main.
```

Pour réparer les index dans une base de données spécifique :

```shell
# Repair indexes in main database
sudo gitlab-rake gitlab:db:repair_index:main

# Repair indexes in CI database
sudo gitlab-rake gitlab:db:repair_index:ci
```

### Contourner PgBouncer pour les requêtes de longue durée {#bypass-pgbouncer-for-long-running-queries-1}

Consultez [résoudre les erreurs de délai d'expiration des instructions](#resolve-statement-timeout-errors) dans la section de dépannage.

## Dépannage {#troubleshooting}

### Informations sur la connexion de verrou advisory {#advisory-lock-connection-information}

Après avoir exécuté la tâche Rake `db:migrate`, vous pouvez voir une sortie similaire à ce qui suit :

```shell
main: == [advisory_lock_connection] object_id: 173580, pg_backend_pid: 5532
main: == [advisory_lock_connection] object_id: 173580, pg_backend_pid: 5532
```

Les messages renvoyés sont informatifs et peuvent être ignorés.

### Erreurs de socket PostgreSQL lors de l'exécution de la tâche Rake `gitlab:env:info` {#postgresql-socket-errors-when-executing-the-gitlabenvinfo-rake-task}

Après avoir exécuté `sudo gitlab-rake gitlab:env:info` sur Gitaly ou d'autres nœuds non-Rails, vous pouvez voir l'erreur suivante :

```plaintext
PG::ConnectionBad: could not connect to server: No such file or directory
Is the server running locally and accepting
connections on Unix domain socket "/var/opt/gitlab/postgresql/.s.PGSQL.5432"?
```

Cela est dû au fait que, dans un environnement multi-nœuds, la tâche Rake `gitlab:env:info` ne doit être exécutée que sur les nœuds exécutant **GitLab Rails**.

### Résoudre les erreurs de délai d'expiration des instructions {#resolve-statement-timeout-errors}

Si votre instance GitLab utilise PgBouncer et que vous rencontrez des délais d'expiration d'instructions lors des tâches de maintenance de la base de données (comme le vérificateur de collation ou la réparation d'index), contournez PgBouncer en utilisant des connexions PostgreSQL directes.

```shell
# Example with direct connection
GITLAB_BACKUP_PGUSER=postgres GITLAB_BACKUP_PGHOST=localhost sudo gitlab-rake gitlab:db:collation_checker

GITLAB_BACKUP_PGUSER=postgres GITLAB_BACKUP_PGHOST=localhost sudo gitlab-rake gitlab:db:repair_index
```

Variables d'environnement prises en charge :

- `GITLAB_BACKUP_PGHOST`
- `GITLAB_BACKUP_PGUSER`
- `GITLAB_BACKUP_PGPORT`
- `GITLAB_BACKUP_PGPASSWORD`

Pour plus d'informations sur le contournement de PgBouncer et une liste complète des variables d'environnement prises en charge, consultez la [procédure pour contourner PgBouncer](../postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer).
