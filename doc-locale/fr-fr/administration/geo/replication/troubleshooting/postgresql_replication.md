---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage de la réplication PostgreSQL Geo
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les sections suivantes décrivent les étapes de dépannage pour corriger les messages d'erreur de réplication (indiqués par `Database replication working? ... no` dans la [sortie `geo:check`](common.md#health-check-rake-task). Les instructions présentées ici supposent principalement un déploiement de package Linux Geo à nœud unique, et pourraient nécessiter une adaptation à différents environnements.

## Suppression d'un slot de réplication inactif {#removing-an-inactive-replication-slot}

Les slots de réplication sont marqués comme « inactifs » lorsque le client de réplication (un site secondaire) connecté au slot se déconnecte. Les slots de réplication inactifs entraînent la conservation des fichiers WAL, car ils sont envoyés au client lorsqu'il se reconnecte et que le slot redevient actif. Si le site secondaire n'est pas en mesure de se reconnecter, procédez comme suit pour supprimer le slot de réplication inactif correspondant :

1. [Démarrez une session de console PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#connecting-to-the-postgresql-database) sur le nœud de base de données du site Geo principal :

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

   > [!note]
   > L'utilisation de `gitlab-rails dbconsole` ne fonctionne pas, car la gestion des slots de réplication nécessite des droits de superutilisateur.

1. Affichez les slots de réplication et supprimez-les s'ils sont inactifs :

   ```sql
   SELECT * FROM pg_replication_slots;
   ```

   Les slots pour lesquels `active` est `f` sont inactifs.

- Si ce slot devrait être actif, parce que vous avez un site **secondaire** configuré avec ce slot :
  - Consultez les [journaux PostgreSQL](../../../logs/_index.md#postgresql-logs) du site **secondaire** pour voir pourquoi la réplication ne s'exécute pas.
  - Si le site secondaire n'est plus en mesure de se reconnecter :

    1. Supprimez le slot à l'aide de la session de console PostgreSQL :

       ```sql
       SELECT pg_drop_replication_slot('<name_of_inactive_slot>');
       ```

    1. [Relancez le processus de réplication](../../setup/database.md#step-3-initiate-the-replication-process), ce qui recrée correctement le slot de réplication.

- Si vous n'utilisez plus le slot (par exemple, vous n'avez plus Geo activé), suivez les étapes [pour supprimer ce site Geo](../remove_geo_site.md).

## Message : `WARNING: oldest xmin is far in the past` et taille de `pg_wal` en augmentation {#message-warning-oldest-xmin-is-far-in-the-past-and-pg_wal-size-growing}

Si un slot de réplication est inactif, les journaux `pg_wal` correspondant au slot sont conservés indéfiniment (ou jusqu'à ce que le slot soit à nouveau actif). Cela entraîne une croissance continue de l'utilisation du disque et les messages suivants apparaissent de façon répétée dans les [journaux PostgreSQL](../../../logs/_index.md#postgresql-logs) :

```plaintext
WARNING: oldest xmin is far in the past
HINT: Close open transactions soon to avoid wraparound problems.
You might also need to commit or roll back old prepared transactions, or drop stale replication slots.
```

Pour résoudre ce problème, vous devez [supprimer le slot de réplication inactif](#removing-an-inactive-replication-slot) et relancer la réplication.

## Message : `ERROR:  replication slots can only be used if max_replication_slots > 0` ? {#message-error--replication-slots-can-only-be-used-if-max_replication_slots--0}

Cela signifie que la variable PostgreSQL `max_replication_slots` doit être définie sur la base de données **principal**. Ce paramètre est défini par défaut sur 1. Vous devrez peut-être augmenter cette valeur si vous avez davantage de sites **secondaire**.

Assurez-vous de redémarrer PostgreSQL pour que cette modification prenne effet. Consultez le guide de [configuration de la réplication PostgreSQL](../../setup/database.md#postgresql-replication) pour plus de détails.

## Message : `replication slot "geo_secondary_my_domain_com" does not exist` {#message-replication-slot-geo_secondary_my_domain_com-does-not-exist}

Cette erreur se produit lorsque PostgreSQL ne dispose pas d'un slot de réplication pour le site **secondaire** portant ce nom :

```plaintext
FATAL:  could not start WAL streaming: ERROR:  replication slot "geo_secondary_my_domain_com" does not exist
```

Vous pouvez réexécuter le [processus de réplication](../../setup/database.md) sur le site **secondaire**.

## Message : `Command exceeded allowed execution time` lors de la configuration de la réplication ? {#message-command-exceeded-allowed-execution-time-when-setting-up-replication}

Cela peut se produire lors de [l'initialisation du processus de réplication](../../setup/database.md#step-3-initiate-the-replication-process) sur le site **secondaire**, et indique que votre jeu de données initial est trop volumineux pour être répliqué dans le délai d'expiration par défaut (30 minutes).

Réexécutez `gitlab-ctl replicate-geo-database`, mais incluez une valeur plus grande pour `--backup-timeout` :

```shell
sudo gitlab-ctl \
   replicate-geo-database \
   --host=<primary_node_hostname> \
   --slot-name=<secondary_slot_name> \
   --backup-timeout=21600
```

Cela donne à la réplication initiale jusqu'à six heures pour se terminer, plutôt que les 30 minutes par défaut. Ajustez selon les besoins de votre installation.

## Message : `PANIC: could not write to file 'pg_xlog/xlogtemp.123': No space left on device` {#message-panic-could-not-write-to-file-pg_xlogxlogtemp123-no-space-left-on-device}

Déterminez si vous avez des slots de réplication inutilisés dans la base de données **principal**. Cela peut entraîner l'accumulation de grandes quantités de données de journaux dans `pg_xlog`.

[La suppression des slots inactifs](#removing-an-inactive-replication-slot) peut réduire la quantité d'espace utilisée dans `pg_xlog`.

## Message : `ERROR: canceling statement due to conflict with recovery` {#message-error-canceling-statement-due-to-conflict-with-recovery}

Ce message d'erreur se produit rarement dans le cadre d'une utilisation normale, et le système est suffisamment résilient pour se rétablir.

Cependant, dans certaines conditions, certaines requêtes de base de données sur les sites secondaires peuvent s'exécuter de façon excessive, ce qui augmente la fréquence de ce message d'erreur. Cela peut conduire à une situation où certaines requêtes ne se terminent jamais en raison de leur annulation à chaque réplication.

Ces requêtes à longue durée d'exécution sont [prévues pour être supprimées à l'avenir](https://gitlab.com/gitlab-org/gitlab/-/issues/34269), mais en guise de solution de contournement, nous recommandons d'activer [`hot_standby_feedback`](https://www.postgresql.org/docs/16/hot-standby.html#HOT-STANDBY-CONFLICT). Cela augmente la probabilité de gonflement sur le site **principal** car cela empêche `VACUUM` de supprimer les lignes récemment mortes. Cependant, il a été utilisé avec succès en production sur GitLab.com.

Pour activer `hot_standby_feedback`, ajoutez ce qui suit dans `/etc/gitlab/gitlab.rb` sur le site **secondaire** :

```ruby
postgresql['hot_standby_feedback'] = 'on'
```

Reconfigurez ensuite GitLab :

```shell
sudo gitlab-ctl reconfigure
```

Pour nous aider à résoudre ce problème, envisagez de commenter [le ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/4489).

## Message : `server certificate for "PostgreSQL" does not match host name` {#message-server-certificate-for-postgresql-does-not-match-host-name}

Si vous voyez cette erreur :

```plaintext
FATAL:  could not connect to the primary server: server certificate for "PostgreSQL" does not match host name
```

Cela se produit parce que le certificat PostgreSQL que le package Linux crée automatiquement contient le Common Name `PostgreSQL`, mais la réplication se connecte à un hôte différent et GitLab tente d'utiliser le mode SSL `verify-full` par défaut.

Pour résoudre ce problème, vous pouvez :

- Utiliser l'argument `--sslmode=verify-ca` avec la commande `replicate-geo-database`.
- Pour une base de données déjà répliquée, remplacez `sslmode=verify-full` par `sslmode=verify-ca` dans `/var/opt/gitlab/postgresql/data/gitlab-geo.conf` et exécutez `gitlab-ctl restart postgresql`.
- [Configurez SSL pour PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#configuring-ssl) avec un certificat personnalisé (incluant le nom d'hôte utilisé pour se connecter à la base de données dans le CN ou le SAN) au lieu d'utiliser le certificat généré automatiquement.

## Message : `LOG:  invalid CIDR mask in address` {#message-log--invalid-cidr-mask-in-address}

Cela se produit avec des adresses mal formatées dans `postgresql['md5_auth_cidr_addresses']`.

```plaintext
2020-03-20_23:59:57.60499 LOG:  invalid CIDR mask in address "***"
2020-03-20_23:59:57.60501 CONTEXT:  line 74 of configuration file "/var/opt/gitlab/postgresql/data/pg_hba.conf"
```

Pour résoudre ce problème, mettez à jour les adresses IP dans `/etc/gitlab/gitlab.rb` sous `postgresql['md5_auth_cidr_addresses']` pour respecter le format CIDR (par exemple, `10.0.0.1/32`).

## Message : `LOG:  invalid IP mask "md5": Name or service not known` {#message-log--invalid-ip-mask-md5-name-or-service-not-known}

Cela se produit lorsque vous avez ajouté des adresses IP sans masque de sous-réseau dans `postgresql['md5_auth_cidr_addresses']`.

```plaintext
2020-03-21_00:23:01.97353 LOG:  invalid IP mask "md5": Name or service not known
2020-03-21_00:23:01.97354 CONTEXT:  line 75 of configuration file "/var/opt/gitlab/postgresql/data/pg_hba.conf"
```

Pour résoudre ce problème, ajoutez le masque de sous-réseau dans `/etc/gitlab/gitlab.rb` sous `postgresql['md5_auth_cidr_addresses']` pour respecter le format CIDR (par exemple, `10.0.0.1/32`).

## Message : `Found data in the gitlabhq_production database` {#message-found-data-in-the-gitlabhq_production-database}

Si vous recevez l'erreur `Found data in the gitlabhq_production database!` lors de l'exécution de `gitlab-ctl replicate-geo-database`, des données ont été détectées dans la table `projects`. Lorsqu'un ou plusieurs projets sont détectés, l'opération est abandonnée pour éviter toute perte de données accidentelle. Pour contourner ce message, passez l'option `--force` à la commande.

## Message : `FATAL:  could not map anonymous shared memory: Cannot allocate memory` {#message-fatal--could-not-map-anonymous-shared-memory-cannot-allocate-memory}

Si vous voyez ce message, cela signifie que le PostgreSQL du site secondaire tente de demander plus de mémoire que la mémoire disponible. Il existe un [ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/381585) qui suit ce problème.

Exemple de message d'erreur dans les journaux Patroni (situés dans `/var/log/gitlab/patroni/current` pour les installations de packages Linux) :

```plaintext
2023-11-21_23:55:18.63727 FATAL:  could not map anonymous shared memory: Cannot allocate memory
2023-11-21_23:55:18.63729 HINT:  This error usually means that PostgreSQL's request for a shared memory segment exceeded available memory, swap space, or huge pages. To reduce the request size (currently 17035526144 bytes), reduce PostgreSQL's shared memory usage, perhaps by reducing shared_buffers or max_connections.
```

La solution de contournement consiste à augmenter la mémoire disponible pour les nœuds PostgreSQL du site secondaire afin de correspondre aux exigences en mémoire des nœuds PostgreSQL du site principal.

## Message : `could not open certificate file "/root/.postgresql/postgresql.crt"` {#message-could-not-open-certificate-file-rootpostgresqlpostgresqlcrt}

Si vous voyez cette erreur :

```plaintext
sql: error: connection to server at "x.x.x.x", port 5432 failed:
could not open certificate file "/root/.postgresql/postgresql.crt": Permission denied...
```

Cette erreur se produit parce que les clients PostgreSQL, tels que `psql` ou les applications utilisant `libpq`, recherchent les certificats SSL client dans des emplacements par défaut spécifiques comme `/root/.postgresql/postgresql.crt`. Cependant, ce message d'erreur peut être trompeur. Il apparaît souvent lorsque l'authentification échoue pour d'autres raisons, par exemple en utilisant un mot de passe incorrect pour l'utilisateur réplicateur GitLab. Avant de résoudre les problèmes de certificat SSL, confirmez d'abord que vos identifiants d'authentification sont corrects.

## Investiguer les causes du décalage de réplication de base de données {#investigate-causes-of-database-replication-lag}

Si la sortie de `sudo gitlab-rake gitlab:geo:status` indique que `Database replication lag` reste significativement élevé dans le temps, le nœud principal de la réplication de base de données peut être vérifié pour déterminer le statut du décalage pour les différentes parties du processus de réplication de base de données. Ces valeurs sont connues sous le nom de `write_lag`, `flush_lag` et `replay_lag`. Pour plus d'informations, consultez [la documentation officielle de PostgreSQL](https://www.postgresql.org/docs/16/monitoring-stats.html#MONITORING-PG-STAT-REPLICATION-VIEW).

Exécutez la commande suivante depuis la base de données du nœud Geo principal pour obtenir une sortie pertinente :

```shell
gitlab-psql -xc 'SELECT write_lag,flush_lag,replay_lag FROM pg_stat_replication;'

-[ RECORD 1 ]---------------
write_lag  | 00:00:00.072392
flush_lag  | 00:00:00.108168
replay_lag | 00:00:00.108283
```

Si une ou plusieurs de ces valeurs est significativement élevée, cela pourrait indiquer un problème et devrait être examiné plus en détail. Lors de la détermination de la cause, tenez compte des éléments suivants :

- `write_lag` indique le temps écoulé depuis que les octets WAL ont été envoyés par le principal, puis reçus par le secondaire, mais pas encore vidés ou appliqués.
- Une valeur élevée de `write_lag` peut indiquer des performances réseau dégradées ou une vitesse réseau insuffisante entre les nœuds principal et secondaire.
- Une valeur élevée de `flush_lag` peut indiquer des performances d'E/S disque dégradées ou sous-optimales avec le périphérique de stockage du nœud secondaire.
- Une valeur élevée de `replay_lag` peut indiquer des transactions de longue durée dans PostgreSQL, ou la saturation d'une ressource nécessaire comme le CPU.
- La différence de temps entre `write_lag` et `flush_lag` indique que des octets WAL ont été envoyés au système de stockage sous-jacent, mais celui-ci n'a pas signalé qu'ils avaient été vidés. Ces données ne sont très probablement pas entièrement écrites dans un stockage persistant, et sont susceptibles d'être conservées dans un type de cache d'écriture volatile.
- La différence entre `flush_lag` et `replay_lag` indique des octets WAL qui ont été correctement persistés dans le stockage, mais qui n'ont pas pu être rejoués par le système de base de données.

## Bloqué à `Message: pg_basebackup: initiating base backup, waiting for checkpoint to complete` {#stuck-at-message-pg_basebackup-initiating-base-backup-waiting-for-checkpoint-to-complete}

Si la réplication initiale est bloquée à `Message: pg_basebackup: initiating base backup, waiting for checkpoint to complete`, cela signifie que le site Geo principal n'est pas activement utilisé. Cela se produit principalement sur un serveur GitLab hors production ou sur une toute nouvelle installation GitLab.

La solution de contournement consiste à provoquer des écritures dans la base de données. Par exemple, vous pouvez vous connecter au site principal et créer quelques tickets et commentaires.

Une autre solution de contournement consiste à exécuter la requête SQL `CHECKPOINT;` sur la base de données du site principal :

```shell
sudo gitlab-psql -xc 'CHECKPOINT;'
```
