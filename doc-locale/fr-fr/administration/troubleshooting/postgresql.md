---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PostgreSQL
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Cette page contient des informations sur PostgreSQL utilisées par l'équipe Support de GitLab lors du dépannage. GitLab rend ces informations publiques afin que tout le monde puisse bénéficier des connaissances collectées par l'équipe Support.

> [!warning]
> Certaines procédures documentées ici peuvent endommager votre instance GitLab. Utilisez-les à vos propres risques.

Si vous êtes sur un [niveau payant](https://about.gitlab.com/pricing/) et que vous ne savez pas comment utiliser ces commandes, [contactez le Support](https://about.gitlab.com/support/) pour obtenir de l'aide sur les problèmes que vous rencontrez.

## Démarrer une console de base de données {#start-a-database-console}

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Recommandé pour :

- Les instances à nœud unique.
- Les environnements à grande échelle ou hybrides, sur les nœuds Patroni, généralement le leader.
- Les environnements à grande échelle ou hybrides, sur le serveur exécutant le service PostgreSQL.

```shell
sudo gitlab-psql
```

Sur une instance à nœud unique, ou un nœud web ou Sidekiq, vous pouvez également utiliser la console de base de données Rails, mais son initialisation prend plus de temps :

```shell
sudo gitlab-rails dbconsole --database main
```

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
docker exec -it <container-id> gitlab-psql
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Utilisez la commande `psql` qui fait partie de [votre installation PostgreSQL](../../install/self_compiled/_index.md#7-database).

```shell
sudo -u git -H psql -d gitlabhq_production
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

- Si vous exécutez un environnement hybride et que PostgreSQL s'exécute sur une installation packagée Linux (Omnibus), l'approche recommandée consiste à utiliser la console de base de données localement sur ces serveurs. Reportez-vous aux détails du package Linux.
- Utilisez la console qui fait partie de votre service PostgreSQL tiers externe.
- Exécutez `gitlab-rails dbconsole` dans le pod toolbox.
  - Reportez-vous à notre [aide-mémoire Kubernetes](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet/#gitlab-specific-kubernetes-information) pour plus de détails.

> [!note]
> Pour les déploiements cloud natifs utilisant des services PostgreSQL gérés (tels qu'AWS RDS), vous ne pouvez pas modifier directement le fichier de configuration de la base de données. À la place, configurez les paramètres PostgreSQL via le groupe de paramètres ou l'interface de configuration de votre service cloud.

{{< /tab >}}

{{< /tabs >}}

Pour quitter la console, tapez : `quit`.

## Autre documentation GitLab sur PostgreSQL {#other-gitlab-postgresql-documentation}

Cette section contient des liens vers des informations disponibles ailleurs dans la documentation GitLab.

### Procédures {#procedures}

- [Procédures de base de données pour les installations du package Linux](https://docs.gitlab.com/omnibus/settings/database/), notamment :
  - SSL : activation, désactivation et vérification.
  - Activation de l'archivage Write Ahead Log (WAL).
  - Utilisation d'une installation PostgreSQL externe (non-Omnibus) et sauvegarde de celle-ci.
  - Écoute sur TCP/IP en plus ou à la place des sockets.
  - Stockage des données dans un autre emplacement.
  - Réensemencement destructif de la base de données GitLab.
  - Conseils sur la mise à jour de PostgreSQL packagé, notamment comment empêcher que cela se produise automatiquement.
- [Informations sur PostgreSQL externe](../postgresql/external.md).
- [Exécuter Geo avec PostgreSQL externe](../geo/setup/external_database.md).
- [Mises à niveau lors de l'exécution de PostgreSQL configuré pour la HA](https://docs.gitlab.com/omnibus/settings/database/#upgrading-a-gitlab-ha-cluster).
- Utilisation de PostgreSQL depuis [des runners CI](../../ci/services/postgres.md).
- Gestion des versions PostgreSQL sur les installations du package Linux à partir de la documentation de développement du package Linux.
- [Mise à l'échelle PostgreSQL](../postgresql/replication_and_failover.md)
  - Notamment le [dépannage](../postgresql/replication_and_failover_troubleshooting.md) de `gitlab-ctl patroni check-leader` et les erreurs PgBouncer.
- Documentation de base de données pour les développeurs, dont une partie n'est absolument pas destinée à un usage en production. Notamment :
  - Comprendre les plans EXPLAIN.

## Sujets du Support {#support-topics}

### Interblocages de base de données {#database-deadlocks}

Références :

- [Des interblocages peuvent se produire si une instance est inondée de push](https://gitlab.com/gitlab-org/gitlab/-/issues/33650). Fourni pour illustrer comment le code GitLab peut avoir ce type d'effet imprévu dans des situations inhabituelles.

```plaintext
ERROR: deadlock detected
```

Trois délais d'expiration applicables sont identifiés dans le ticket [\#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528) ; nos paramètres recommandés sont les suivants :

```ini
deadlock_timeout = 5s
statement_timeout = 15s
idle_in_transaction_session_timeout = 60s
```

Citation du ticket [\#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528) :

<!-- vale gitlab_base.FutureTense = NO -->

> « Si un interblocage se produit et que nous le résolvons en abandonnant la transaction après une courte période, les mécanismes de nouvelle tentative dont nous disposons déjà feront que le travail bloqué sera réessayé, et il est peu probable que nous subissions plusieurs interblocages consécutifs. »

<!-- vale gitlab_base.FutureTense = YES -->

> [!note]
> Au sein du Support, notre approche générale pour reconfigurer les délais d'expiration (s'applique également à la pile HTTP) est qu'il est acceptable de le faire temporairement comme solution de contournement. Si cela rend GitLab utilisable pour le client, cela permet de gagner du temps pour comprendre le problème plus complètement, implémenter un correctif rapide ou apporter un autre changement qui traite la cause première. En général, les délais d'expiration devraient être remis à des valeurs par défaut raisonnables une fois la cause première résolue.

Dans ce cas, les conseils que nous avions du développement étaient de supprimer `deadlock_timeout` ou `statement_timeout`, mais de laisser le troisième paramètre à 60 secondes. La définition de `idle_in_transaction` protège la base de données contre les sessions potentiellement bloquées pendant des jours. Vous trouverez plus de discussion dans [le ticket relatif à l'introduction de ce délai d'expiration sur GitLab.com](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1053).

Valeurs par défaut PostgreSQL :

- `statement_timeout = 0` (jamais)
- `idle_in_transaction_session_timeout = 0` (jamais)

Les commentaires du ticket [\#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528) indiquent que ces deux valeurs devraient être définies à au moins quelques minutes pour toutes les installations du package Linux (afin qu'elles ne restent pas bloquées indéfiniment). Cependant, 15 s pour `statement_timeout` est très court et n'est efficace que si l'infrastructure sous-jacente est très performante.

Consultez les paramètres actuels avec :

```shell
sudo gitlab-rails runner "c = ApplicationRecord.connection ; puts c.execute('SHOW statement_timeout').to_a ;
puts c.execute('SHOW deadlock_timeout').to_a ;
puts c.execute('SHOW idle_in_transaction_session_timeout').to_a ;"
```

La réponse peut prendre un peu de temps.

```ruby
{"statement_timeout"=>"1min"}
{"deadlock_timeout"=>"0"}
{"idle_in_transaction_session_timeout"=>"1min"}
```

Ces paramètres peuvent être mis à jour dans `/etc/gitlab/gitlab.rb` avec :

```ruby
postgresql['deadlock_timeout'] = '5s'
postgresql['statement_timeout'] = '15s'
postgresql['idle_in_transaction_session_timeout'] = '60s'
```

Une fois enregistré, [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

> [!note]
> Il s'agit de paramètres du package Linux. Si une base de données externe, telle qu'une installation PostgreSQL d'un client ou Amazon RDS, est utilisée, ces valeurs ne sont pas définies et devraient être configurées en externe.

### Modification temporaire du délai d'expiration des instructions {#temporarily-changing-the-statement-timeout}

> [!warning]
> Les conseils suivants ne s'appliquent pas si [PgBouncer](../postgresql/pgbouncer.md) est activé, car le délai d'expiration modifié pourrait affecter plus de transactions que prévu.

Dans certaines situations, il peut être souhaitable de définir un délai d'expiration des instructions différent sans avoir à [reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation), ce qui dans ce cas redémarrerait Puma et Sidekiq.

Par exemple, une sauvegarde peut échouer avec les erreurs suivantes dans la sortie de la [commande de sauvegarde](../backup_restore/_index.md#back-up-gitlab) car le délai d'expiration des instructions était trop court :

```plaintext
pg_dump: error: Error message from server: server closed the connection unexpectedly
```

Vous pouvez également voir des erreurs dans les [journaux PostgreSQL](../logs/_index.md#postgresql-logs) :

```plaintext
canceling statement due to statement timeout
```

#### Pour les installations du package Linux {#for-linux-package-installations}

Pour modifier temporairement le délai d'expiration des instructions :

1. Ouvrez `/var/opt/gitlab/gitlab-rails/etc/database.yml` dans un éditeur
1. Définissez la valeur de `statement_timeout` sur `0`, ce qui définit un délai d'expiration des instructions illimité.
1. [Confirmez dans une nouvelle session de console Rails](../operations/rails_console.md#using-the-rails-runner) que cette valeur est utilisée :

   ```shell
   sudo gitlab-rails runner "ActiveRecord::Base.connection_db_config[:variables]"
   ```

1. Effectuez l'action pour laquelle vous avez besoin d'un délai d'expiration différent (par exemple la sauvegarde ou la commande Rails).
1. Annulez la modification dans `/var/opt/gitlab/gitlab-rails/etc/database.yml`.

#### Pour les déploiements cloud natifs {#for-cloud-native-deployments}

Pour les déploiements cloud natifs utilisant des services PostgreSQL gérés (tels qu'AWS RDS, Azure Database pour PostgreSQL ou Google Cloud SQL), vous ne pouvez pas modifier directement le fichier de configuration de la base de données. À la place, configurez le paramètre `statement_timeout` via le groupe de paramètres ou l'interface de configuration de votre service cloud :

- **AWS RDS** : Modifiez le groupe de paramètres associé à votre instance de base de données et définissez `statement_timeout` sur `0` (illimité).
- **Azure Database for PostgreSQL** : Mettez à jour les paramètres du serveur dans le portail Azure et définissez `statement_timeout` sur `0`.
- **Google Cloud SQL** : Modifiez les indicateurs de base de données et définissez `statement_timeout` sur `0`.

Après avoir apporté des modifications au groupe de paramètres ou à la configuration, vous devrez peut-être redémarrer l'instance de base de données pour que les modifications prennent effet. Consultez la documentation de votre fournisseur cloud pour obtenir des instructions spécifiques.

### Observer le rapport de progression (RE)INDEX {#observe-reindex-progress-report}

Dans certaines situations, vous pouvez vouloir observer la progression d'une opération `CREATE INDEX` ou `REINDEX`. Par exemple, vous pouvez le faire pour confirmer si l'opération `CREATE INDEX` ou `REINDEX` est active, ou pour vérifier dans quelle phase se trouve l'opération.

Prérequis :

- Vous devez utiliser PostgreSQL version 12 ou ultérieure.

Pour observer une opération `CREATE INDEX` ou `REINDEX` :

- Utilisez la [vue `pg_stat_progress_create_index` intégrée](https://www.postgresql.org/docs/16/progress-reporting.html#CREATE-INDEX-PROGRESS-REPORTING).

Par exemple, depuis une session de console de base de données, exécutez la commande suivante :

```sql
SELECT * FROM  pg_stat_progress_create_index \watch 0.2
```

Pour en savoir plus sur la production d'une sortie conviviale et l'écriture de données dans des fichiers journaux, consultez [cet extrait](https://gitlab.com/-/snippets/3750940).

## Dépannage {#troubleshooting}

### Connexion à la base de données refusée {#database-connection-is-refused}

Si vous rencontrez les erreurs suivantes, vérifiez si `max_connections` est suffisamment élevé pour garantir des connexions stables.

```shell
connection to server at "xxx.xxx.xxx.xxx", port 5432 failed: Connection refused
      Is the server running on that host and accepting TCP/IP connections?
```

```shell
psql: error: connection to server on socket "/var/opt/gitlab/postgresql/.s.PGSQL.5432" failed:
FATAL:  sorry, too many clients already
```

Pour ajuster `max_connections`, consultez [la configuration de plusieurs connexions à la base de données](https://docs.gitlab.com/omnibus/settings/database/#configuring-multiple-database-connections).

### La base de données n'accepte pas les commandes pour éviter la perte de données par débordement de transaction {#database-is-not-accepting-commands-to-avoid-wraparound-data-loss}

Cette erreur signifie probablement que `autovacuum` ne parvient pas à terminer son exécution :

```plaintext
ERROR:  database is not accepting commands to avoid wraparound data loss in database "gitlabhq_production"
```

Ou

```plaintext
 ERROR:  failed to re-find parent key in index "XXX" for deletion target page XXX
```

Pour résoudre l'erreur, exécutez `VACUUM` manuellement :

1. Arrêtez GitLab avec la commande `gitlab-ctl stop`.
1. Placez la base de données en mode mono-utilisateur avec la commande :

   ```shell
   /opt/gitlab/embedded/bin/postgres --single -D /var/opt/gitlab/postgresql/data gitlabhq_production
   ```

1. Dans l'invite `backend>`, exécutez `VACUUM;`. Cette commande peut prendre plusieurs minutes.
1. Attendez la fin de la commande, puis appuyez sur <kbd>Contrôle</kbd> + <kbd>D</kbd> pour quitter.
1. Démarrez GitLab avec la commande `gitlab-ctl start`.

### Prérequis de base de données GitLab {#gitlab-database-requirements}

Consultez les [prérequis de base de données](../../install/requirements.md#postgresql) et examinez et installez la [liste des extensions requises](../../install/requirements.md#extensions).

### Erreurs de sérialisation dans le journal `production/sidekiq` {#serialization-errors-in-the-productionsidekiq-log}

Si vous recevez des erreurs comme cet exemple dans votre journal `production/sidekiq`, renseignez-vous sur la [définition de `default_transaction_isolation` sur read committed](https://docs.gitlab.com/omnibus/settings/database/#set-default_transaction_isolation-into-read-committed) pour résoudre le problème :

```plaintext
ActiveRecord::StatementInvalid PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update
```

### Erreurs de slot de réplication PostgreSQL {#postgresql-replication-slot-errors}

Si vous recevez des erreurs comme cet exemple, renseignez-vous sur la résolution des [erreurs de slot de réplication](https://docs.gitlab.com/omnibus/settings/database/#troubleshooting-upgrades-in-an-ha-cluster) PostgreSQL HA :

```plaintext
pg_basebackup: could not create temporary replication slot "pg_basebackup_12345": ERROR:  all replication slots are in use
HINT:  Free one or increase max_replication_slots.
```

### Erreurs de réplication Geo {#geo-replication-errors}

Si vous recevez des erreurs comme cet exemple, renseignez-vous sur la résolution des [erreurs de réplication Geo](../geo/replication/troubleshooting/postgresql_replication.md) :

```plaintext
ERROR: replication slots can only be used if max_replication_slots > 0

FATAL: could not start WAL streaming: ERROR: replication slot "geo_secondary_my_domain_com" does not exist

Command exceeded allowed execution time

PANIC: could not write to file 'pg_xlog/xlogtemp.123': No space left on device
```

### Examiner la configuration Geo et les erreurs courantes {#review-geo-configuration-and-common-errors}

Lors du dépannage de problèmes avec Geo, vous devriez :

- Examiner les [erreurs Geo courantes](../geo/replication/troubleshooting/common.md#fixing-common-errors).
- [Examiner votre configuration Geo](../geo/replication/troubleshooting/_index.md), notamment :
  - Reconfigurer les hôtes et les ports.
  - Examiner et corriger les mappages d'utilisateurs et de mots de passe.

### Incompatibilité des versions de `pg_dump` et `psql` {#mismatch-in-pg_dump-and-psql-versions}

Si vous recevez des erreurs comme cet exemple, renseignez-vous sur la façon de [sauvegarder et restaurer une base de données PostgreSQL non packagée](https://docs.gitlab.com/omnibus/settings/database/#backup-and-restore-a-non-packaged-postgresql-database) :

```plaintext
Dumping PostgreSQL database gitlabhq_production ... pg_dump: error: server version: 13.3; pg_dump version: 14.2
pg_dump: error: aborting because of server version mismatch
```

### L'extension `btree_gist` n'est pas dans la liste d'autorisation {#extension-btree_gist-is-not-allow-listed}

Le déploiement de PostgreSQL sur Azure Database pour PostgreSQL - Flexible Server peut entraîner cette erreur :

```plaintext
extension "btree_gist" is not allow-listed for "azure_pg_admin" users in Azure Database for PostgreSQL
```

Pour résoudre cette erreur, [ajoutez l'extension à la liste d'autorisation](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions#how-to-use-postgresql-extensions) avant l'installation.
