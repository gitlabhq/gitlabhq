---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Reprise après sinistre (Geo)
description: "Récupérer après un sinistre à l'aide d'une instance Geo."
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Geo réplique votre base de données, vos dépôts Git et autres ressources. Certains [problèmes connus](../_index.md#known-issues) existent.

> [!warning]
>
> - Les configurations multi-secondaires nécessitent la resynchronisation et la reconfiguration complètes de tous les sites secondaires non promus et entraînent des temps d'arrêt.
> - Une fois le site secondaire promu, le site principal est entièrement détaché. Si vous souhaitez restaurer le site principal, vous devez l'ajouter en tant que nouveau site secondaire.

## Sites secondaires avec synchronisation sélective activée {#secondary-sites-with-selective-synchronization-enabled}

La promotion d'un site **secondaire** avec la synchronisation sélective activée entraîne une **permanent data loss** pour toutes les données qui n'ont pas été répliquées sur ce site secondaire. Pour plus d'informations, voir [Promotion d'un site secondaire avec la synchronisation sélective activée](../replication/selective_synchronization.md#promoting-a-secondary-site-with-selective-synchronization-enabled).

## Le fichier `gitlab-cluster.json` {#the-gitlab-clusterjson-file}

Lorsque vous promouvez un site secondaire en site principal avec `gitlab-ctl geo promote`, la commande crée automatiquement un fichier `/etc/gitlab/gitlab-cluster.json` sur chaque nœud où elle s'exécute. Dans la plupart des cas, vous n'avez pas besoin de modifier manuellement ce fichier.

Le fichier `gitlab-cluster.json` permet à la commande de promotion d'automatiser les modifications de configuration sans modifier directement `/etc/gitlab/gitlab.rb`. La modification par programme de `gitlab.rb` est sujette aux erreurs, c'est pourquoi `gitlab-cluster.json` sert de couche de remplacement gérée par la machine.

Lorsque les deux fichiers existent, les valeurs de `gitlab-cluster.json` ont la priorité sur les valeurs correspondantes dans `gitlab.rb` lors de l'exécution de `gitlab-ctl reconfigure`. Lorsque vous exécutez cette commande, vous voyez un avertissement similaire à :

```plaintext
The 'geo_primary_role' is defined in /etc/gitlab/gitlab-cluster.json as 'true' and overrides the setting in the /etc/gitlab/gitlab.rb
The 'geo_secondary_role' is defined in /etc/gitlab/gitlab-cluster.json as 'false' and overrides the setting in the /etc/gitlab/gitlab.rb
```

Cet avertissement est attendu après la promotion.

### Structure du fichier {#file-structure}

Un fichier `gitlab-cluster.json` typique ressemble à :

```json
{
  "primary": true,
  "secondary": false,
  "geo_secondary": {
    "enable": false
  }
}
```

| Clé | Description |
|---|---|
| `primary` | Lorsque `true`, active `geo_primary_role`, qui configure le nœud en tant que principal Geo. |
| `secondary` | Lorsque `true`, active `geo_secondary_role`, qui configure le nœud en tant que secondaire Geo. |
| `geo_secondary` | Contient les paramètres liés à la configuration secondaire Geo, tels que la base de données de suivi. `"enable": false` désactive les services spécifiques aux secondaires. |

Les clés `primary` et `secondary` correspondent respectivement à `geo_primary_role` et `geo_secondary_role`. Ces rôles sont pratiques pour les configurations à nœud unique et ne doivent pas être utilisés dans les configurations multi-nœuds où les rôles de service individuels sont configurés explicitement dans `gitlab.rb`.

### Supprimer le fichier {#remove-the-file}

Après une promotion réussie, vous pouvez conserver `gitlab-cluster.json` en place. Cependant, vous devez le supprimer dans les situations suivantes :

- Si vous [ramenez un principal rétrogradé](bring_primary_back.md#configure-the-former-primary-site-to-be-a-secondary-site) en tant que nouveau site secondaire, vous devez supprimer `gitlab-cluster.json` de chaque nœud Sidekiq, PostgreSQL, Gitaly et Rails.
- Après avoir mis à jour `gitlab.rb` pour définir un rôle Geo (par exemple, `roles(['geo_primary_role'])`), et que vous souhaitez que `gitlab.rb` soit la seule source de configuration.
- Après avoir récupéré d'un basculement partiel.

  Voir [Récupération après un basculement partiel](failover_troubleshooting.md#recovering-from-a-partial-failover) pour plus de détails sur le moment où le fichier est créé manuellement lors de la récupération.

Pour supprimer le fichier :

- Exécutez ces commandes :

  ```shell
  sudo rm /etc/gitlab/gitlab-cluster.json
  sudo gitlab-ctl reconfigure
  ```

  Dans une configuration multi-nœuds, répétez ces commandes sur chaque nœud du site.

Pour des détails techniques sur la façon dont `gitlab-cluster.json` interagit avec le processus de reconfiguration, consultez la [documentation de reconfiguration Omnibus](https://docs.gitlab.com/omnibus/development/reconfigure_in_detail/#gitlab-clusterjson-file).

## Promotion d'un site Geo secondaire dans les configurations à secondaire unique {#promoting-a-secondary-geo-site-in-single-secondary-configurations}

Bien que vous ne puissiez pas promouvoir automatiquement un réplica Geo et effectuer un basculement, vous pouvez le faire manuellement si vous disposez d'un accès `root` à la machine.

Ce processus promeut un site Geo **secondaire** en site **principal**. Pour retrouver la redondance géographique aussi rapidement que possible, vous devez ajouter un nouveau site **secondaire** immédiatement après avoir suivi ces instructions.

### Permettre à la réplication de se terminer si possible {#allow-replication-to-finish-if-possible}

Si le site **secondaire** réplique toujours des données depuis le site **principal**, suivez [la documentation de basculement planifié](planned_failover.md) aussi fidèlement que possible afin d'éviter toute perte de données inutile.

### Étape 1. Désactiver définitivement le site **principal** {#step-1-permanently-disable-the-primary-site}

> [!warning]
> Si le site **principal** se déconnecte, des données enregistrées sur le site **principal** peuvent ne pas avoir été répliquées sur le site **secondaire**. Ces données doivent être considérées comme perdues si vous continuez.

En cas de panne du site **principal**, vous devez tout faire pour éviter une situation de split-brain où des écritures peuvent se produire dans deux instances GitLab différentes, ce qui complique les efforts de récupération. Pour préparer le basculement, nous devons donc désactiver le site **principal**.

- Si vous disposez d'un accès SSH :

  1. Connectez-vous en SSH au site **principal** pour arrêter et désactiver GitLab :

     ```shell
     sudo gitlab-ctl stop
     ```

  1. Empêchez GitLab de redémarrer si le serveur redémarre de façon inattendue :

     ```shell
     sudo systemctl disable gitlab-runsvdir
     ```

- Si vous n'avez pas d'accès SSH au site **principal**, mettez la machine hors ligne et empêchez-la de redémarrer par tous les moyens à votre disposition. Vous pourriez avoir besoin de :

  - Reconfigurer les équilibreurs de charge.
  - Modifier les enregistrements DNS (par exemple, pointer l'enregistrement DNS principal vers le site **secondaire** pour arrêter l'utilisation du site **principal**).
  - Arrêter les serveurs virtuels.
  - Bloquer le trafic via un pare-feu.
  - Révoquer les autorisations de stockage d'objets du site **principal**.
  - Déconnecter physiquement une machine.

  Si vous prévoyez de [mettre à jour l'enregistrement DNS du domaine principal](#optional-updating-the-primary-domain-dns-record), vous pouvez maintenir un TTL bas pour assurer une propagation rapide des modifications DNS.

  > [!note]
  > Le fichier `/etc/gitlab/gitlab.rb` du site principal n'est pas copié automatiquement sur les sites secondaires au cours de ce processus. Assurez-vous de sauvegarder le fichier `/etc/gitlab/gitlab.rb` du principal afin de pouvoir ultérieurement restaurer les valeurs nécessaires sur vos sites secondaires.

### Étape 2. Promotion d'un site **secondaire** {#step-2-promoting-a-secondary-site}

Notez ce qui suit lors de la promotion d'un secondaire :

- Si le site secondaire [a été mis en pause](../replication/pause_resume_replication.md), la promotion effectue une récupération à un point dans le temps vers le dernier état connu. Les données créées sur le principal pendant que le secondaire était en pause sont perdues.
- Si le site secondaire [a été mis en pause](../replication/pause_resume_replication.md) et que vous rencontrez un message d'erreur `ActiveRecord::StatementInvalid: PG::ReadOnlySqlTransaction: ERROR:  cannot execute DELETE in a read-only transaction` au cours de ce processus, consultez cet article de la base de connaissances :  [La promotion Geo échoue avec une erreur de transaction en lecture seule ou un délai d'attente après un arrêt inattendu du principal](https://support.gitlab.com/hc/en-us/articles/21019042667804-Geo-promotion-fails-with-read-only-transaction-error-or-timeout-after-unexpected-primary-shutdown).
- Un nouveau site **secondaire** ne doit pas être ajouté à ce stade. Si vous souhaitez ajouter un nouveau site **secondaire**, faites-le après avoir terminé l'ensemble du processus de promotion du **secondaire** vers le **principal**.
- Si vous rencontrez un message d'erreur `ActiveRecord::RecordInvalid: Validation failed: Name has already been taken` au cours de ce processus, pour plus d'informations, consultez ce [conseil de dépannage](failover_troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site).
- Si vous utilisez des URL distinctes, vous devez [pointer le DNS du domaine principal vers le site nouvellement promu](#optional-updating-the-primary-domain-dns-record). Sinon, les runners doivent être à nouveau enregistrés auprès du site nouvellement promu, et toutes les télécommandes Git, les signets et les intégrations externes doivent être mis à jour.
- Si vous utilisez le [DNS sensible à la localisation](../secondary_proxy/_index.md#configure-location-aware-dns), les runners doivent se connecter automatiquement au nouveau principal une fois l'ancien principal retiré de l'entrée DNS.
- Une fois le site principal hors ligne, exécutez `gitlab-ctl promotion-preflight-checks` sur le secondaire pour vérifier l'état de synchronisation Geo et effectuer les vérifications de validation finales.
- Si vous ne prévoyez pas que les runners connectés au principal précédent reviennent, vous devez les supprimer :
  - Via l'interface utilisateur :
    1. Dans le coin supérieur droit, sélectionnez **Admin**.
    1. Sélectionnez **CI/CD** > **Runners** et supprimez-les.
  - En utilisant l'[API Runners](../../../api/runners.md).

#### Promotion d'un site **secondaire** fonctionnant sur un nœud unique {#promoting-a-secondary-site-running-on-a-single-node}

1. Connectez-vous en SSH à votre site **secondaire** et exécutez :

   - Pour promouvoir le site secondaire en principal :

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - Pour promouvoir le site secondaire en principal **without any further confirmation** :

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Vérifiez que vous pouvez vous connecter au site **principal** nouvellement promu en utilisant l'URL précédemment utilisée pour le site **secondaire**.
1. En cas de succès, le site **secondaire** est maintenant promu en site **principal**.

Lorsque vous exécutez `gitlab-ctl geo promote`, un fichier [`gitlab-cluster.json`](#the-gitlab-clusterjson-file) est créé sur le nœud. Le fichier remplace les paramètres de rôle Geo dans `gitlab.rb` lorsque vous reconfigurez.

### Étape 3. Suppression de la base de données de suivi de l'ancien secondaire {#step-3-removing-the-former-secondarys-tracking-database}

Si des options de configuration `geo_secondary[]` sont activées dans votre fichier `/etc/gitlab/gitlab.rb`, commentez-les ou supprimez-les, puis [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

À ce stade, votre site promu est le nouveau site GitLab principal. Si vous le souhaitez, pour reconfigurer Geo avec un nouveau site secondaire, vous pouvez [ramener l'ancien site en tant que secondaire](bring_primary_back.md#configure-the-former-primary-site-to-be-a-secondary-site).

### Promotion d'un site **secondaire** avec plusieurs nœuds et un site **single-secondary** {#promoting-a-secondary-site-with-multiple-nodes-and-a-single-secondary-site}

1. Connectez-vous en SSH à chaque nœud Sidekiq, PostgreSQL et Gitaly du site **secondaire** et exécutez l'une des commandes suivantes :

   - Pour promouvoir le nœud du site secondaire en principal :

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - Pour promouvoir le site secondaire en principal **without any further confirmation** :

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Connectez-vous en SSH à chaque nœud Rails de votre site **secondaire** et exécutez l'une des commandes suivantes :

   - Pour promouvoir le site secondaire en principal :

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - Pour promouvoir le site secondaire en principal **without any further confirmation** :

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Vérifiez que vous pouvez vous connecter au site **principal** nouvellement promu en utilisant l'URL précédemment utilisée pour le site **secondaire**.
1. En cas de succès, le site **secondaire** est maintenant promu en site **principal**.

Lorsque vous exécutez `gitlab-ctl geo promote`, un fichier [`gitlab-cluster.json`](#the-gitlab-clusterjson-file) est créé sur le nœud. Le fichier remplace les paramètres de rôle Geo dans `gitlab.rb` lorsque vous reconfigurez.

#### Promotion d'un site **secondaire** avec un cluster de secours Patroni {#promoting-a-secondary-site-with-a-patroni-standby-cluster}

1. Connectez-vous en SSH à chaque nœud Sidekiq, PostgreSQL et Gitaly du site **secondaire** et exécutez l'une des commandes suivantes :

   - Pour promouvoir le site secondaire en principal :

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - Pour promouvoir le site secondaire en principal **without any further confirmation** :

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Connectez-vous en SSH à chaque nœud Rails de votre site **secondaire** et exécutez l'une des commandes suivantes :

   - Pour promouvoir le site secondaire en principal :

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - Pour promouvoir le site secondaire en principal **without any further confirmation** :

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Vérifiez que vous pouvez vous connecter au site **principal** nouvellement promu en utilisant l'URL précédemment utilisée pour le site **secondaire**.
1. En cas de succès, le site **secondaire** est maintenant promu en site **principal**.

#### Promotion d'un site **secondaire** avec une base de données PostgreSQL externe {#promoting-a-secondary-site-with-an-external-postgresql-database}

La commande `gitlab-ctl geo promote` peut être utilisée conjointement avec une base de données PostgreSQL externe. Dans ce cas, vous devez d'abord promouvoir manuellement la base de données réplica associée au site **secondaire** :

1. Promouvez la base de données réplica associée au site **secondaire**. Cela configure la base de données en lecture-écriture. Les instructions varient en fonction de l'endroit où votre base de données est hébergée :
   - [Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html#USER_ReadRepl.Promote)
   - [Azure PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-portal#stop-replication)
   - [Google Cloud SQL](https://cloud.google.com/sql/docs/mysql/replication/manage-replicas#promote-replica)
   - Pour les autres bases de données PostgreSQL externes, enregistrez le script suivant sur votre site secondaire, par exemple `/tmp/geo_promote.sh`, et modifiez les paramètres de connexion pour correspondre à votre environnement. Ensuite, exécutez-le pour promouvoir le réplica :

     ```shell
     #!/bin/bash

     PG_SUPERUSER=postgres

     # The path to your pg_ctl binary. You may need to adjust this path to match
     # your PostgreSQL installation
     PG_CTL_BINARY=/usr/lib/postgresql/16/bin/pg_ctl

     # The path to your PostgreSQL data directory. You may need to adjust this
     # path to match your PostgreSQL installation. You can also run
     # `SHOW data_directory;` from PostgreSQL to find your data directory
     PG_DATA_DIRECTORY=/etc/postgresql/16/main

     # Promote the PostgreSQL database and allow read/write operations
     sudo -u $PG_SUPERUSER $PG_CTL_BINARY -D $PG_DATA_DIRECTORY promote
     ```

1. Connectez-vous en SSH à chaque nœud Sidekiq, PostgreSQL et Gitaly du site **secondaire** et exécutez l'une des commandes suivantes :

   - Pour promouvoir le site secondaire en principal :

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - Pour promouvoir le site secondaire en principal **without any further confirmation** :

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Connectez-vous en SSH à chaque nœud Rails de votre site **secondaire** et exécutez l'une des commandes suivantes :

   - Pour promouvoir le site secondaire en principal :

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - Pour promouvoir le site secondaire en principal **without any further confirmation** :

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Vérifiez que vous pouvez vous connecter au site **principal** nouvellement promu en utilisant l'URL précédemment utilisée pour le site **secondaire**.
1. En cas de succès, le site **secondaire** est maintenant promu en site **principal**.

### (Facultatif) Mise à jour de l'enregistrement DNS du domaine principal {#optional-updating-the-primary-domain-dns-record}

Mettez à jour les enregistrements DNS du domaine principal pour qu'ils pointent vers le site **secondaire**. Cela évite d'avoir à mettre à jour toutes les références au domaine principal, par exemple les télécommandes Git et les URL d'API.

1. Connectez-vous en SSH au site **secondaire** et connectez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Mettez à jour l'enregistrement DNS du domaine principal. Après avoir mis à jour les enregistrements DNS du domaine principal pour qu'ils pointent vers le site **secondaire**, modifiez `/etc/gitlab/gitlab.rb` sur le site **secondaire** pour refléter la nouvelle URL :

   ```ruby
   # Change the existing external_url configuration
   external_url 'https://<new_external_url>'
   ```

   > [!note]
   > La modification de `external_url` n'empêche pas l'accès via l'ancienne URL secondaire, tant que les enregistrements DNS secondaires sont toujours intacts.

1. Mettez à jour le certificat SSL du site **secondaire** :

   - Si vous utilisez l'[intégration Let's Encrypt](https://docs.gitlab.com/omnibus/settings/ssl/#enable-the-lets-encrypt-integration), le certificat se met à jour automatiquement.
   - Si vous avez [configuré manuellement](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually) le certificat du site **secondaire**, copiez le certificat du site **principal** vers le site **secondaire**. Si vous n'avez pas accès au site **principal**, émettez un nouveau certificat et assurez-vous qu'il contient à la fois les URL du site **principal** et du site **secondaire** dans les noms alternatifs du sujet. Vous pouvez vérifier avec :

     ```shell
     /opt/gitlab/embedded/bin/openssl x509 -noout -dates -subject -issuer \
         -nameopt multiline -ext subjectAltName -in /etc/gitlab/ssl/new-gitlab.new-example.com.crt
     ```

1. Reconfigurez le site **secondaire** pour que la modification prenne effet :

   ```shell
   gitlab-ctl reconfigure
   ```

1. Exécutez la commande ci-dessous pour mettre à jour l'URL du site **principal** nouvellement promu :

   ```shell
   gitlab-rake gitlab:geo:update_primary_node_url
   ```

   Cette commande utilise la configuration `external_url` modifiée définie dans `/etc/gitlab/gitlab.rb`.

1. Vérifiez que vous pouvez vous connecter au site **principal** nouvellement promu via son URL. Si vous avez mis à jour les enregistrements DNS pour le domaine principal, ces modifications peuvent ne pas encore s'être propagées selon le TTL des enregistrements DNS précédents.

### (Facultatif) Ajouter un site Geo **secondaire** à un site **principal** promu {#optional-add-secondary-geo-site-to-a-promoted-primary-site}

Pour mettre en ligne un nouveau site **secondaire**, suivez les [instructions de configuration Geo](../setup/_index.md).

## Promotion d'un réplica Geo secondaire dans les configurations multi-secondaires {#promoting-secondary-geo-replica-in-multi-secondary-configurations}

Si vous avez plusieurs sites **secondaire** et que vous devez en promouvoir un, nous vous suggérons de suivre [Promotion d'un site Geo **secondaire** dans les configurations à secondaire unique](#promoting-a-secondary-geo-site-in-single-secondary-configurations), puis d'effectuer deux étapes supplémentaires.

### Étape 1. Préparer le nouveau site **principal** pour servir un ou plusieurs sites **secondaire** {#step-1-prepare-the-new-primary-site-to-serve-one-or-more-secondary-sites}

1. Connectez-vous en SSH au nouveau site **principal** et connectez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   ## Enable a Geo Primary role (if you haven't yet)
   roles ['geo_primary_role']

   ##
   # Allow PostgreSQL client authentication from the primary and secondary IPs. These IPs may be
   # public or VPC addresses in CIDR format, for example ['198.51.100.1/32', '198.51.100.2/32']
   ##
   postgresql['md5_auth_cidr_addresses'] = ['<primary_site_ip>/32', '<secondary_site_ip>/32']

   # Every secondary site needs to have its own slot so specify the number of secondary sites you're going to have
   # postgresql['max_replication_slots'] = 1 # Set this to be the number of Geo secondary nodes if you have more than one

   ##
   ## Disable automatic database migrations temporarily
   ## (until PostgreSQL is restarted and listening on the private address).
   ##
   gitlab_rails['auto_migrate'] = false
   ```

   (Pour plus de détails sur ces paramètres, vous pouvez lire [Configurer le serveur principal](../setup/database.md#step-1-configure-the-primary-site))

1. Enregistrez le fichier et reconfigurez GitLab pour que les modifications d'écoute de la base de données et les modifications des slots de réplication soient appliquées :

   ```shell
   gitlab-ctl reconfigure
   ```

   Redémarrez PostgreSQL pour que ses modifications prennent effet :

   ```shell
   gitlab-ctl restart postgresql
   ```

1. Réactivez les migrations maintenant que PostgreSQL est redémarré et en écoute sur l'adresse privée.

   Modifiez `/etc/gitlab/gitlab.rb` et **modification** la configuration en `true` :

   ```ruby
   gitlab_rails['auto_migrate'] = true
   ```

   Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   gitlab-ctl reconfigure
   ```

### Étape 2. Lancer le processus de réplication {#step-2-initiate-the-replication-process}

Nous devons maintenant faire en sorte que chaque site **secondaire** écoute les modifications sur le nouveau site **principal**. Pour ce faire, vous devez [lancer à nouveau le processus de réplication](../setup/database.md#step-3-initiate-the-replication-process), mais cette fois pour un autre site **principal**. Tous les anciens paramètres de réplication sont écrasés.

Les sites secondaires existants auront tous des bases de données renseignées, vous pourriez donc voir un message comme celui-ci :

```shell
Found data inside the gitlabhq_production database! If you are sure you are in the secondary server, override with --force
```

Après avoir confirmé que vous êtes sur le site secondaire approprié, lancez la réplication avec `--force`.

> [!warning]
> L'utilisation de `--force` entraîne **all existing data in the database on that secondary server to be deleted**.

## Promotion d'un cluster Geo secondaire dans le chart Helm GitLab {#promoting-a-secondary-geo-cluster-in-the-gitlab-helm-chart}

Lors de la mise à jour d'un déploiement Geo cloud-native, le processus de mise à jour de tout nœud externe au cluster Kubernetes secondaire ne diffère pas de l'approche non cloud-native. Par conséquent, vous pouvez toujours vous référer à [Promotion d'un site Geo secondaire dans les configurations à secondaire unique](#promoting-a-secondary-geo-site-in-single-secondary-configurations) pour plus d'informations.

Les sections suivantes supposent que vous utilisez l'espace de nommage `gitlab`. Si vous avez utilisé un espace de nommage différent lors de la configuration de votre cluster, vous devez également remplacer `--namespace gitlab` par votre espace de nommage.

### Étape 1. Désactiver définitivement le cluster **principal** {#step-1-permanently-disable-the-primary-cluster}

> [!warning]
> Si le site **principal** se déconnecte, des données enregistrées sur le site **principal** peuvent ne pas avoir été répliquées sur le site **secondaire**. Ces données doivent être considérées comme perdues si vous continuez.

En cas de panne du site **principal**, vous devez tout faire pour éviter une situation de split-brain où des écritures peuvent se produire dans deux instances GitLab différentes, ce qui complique les efforts de récupération. Pour préparer le basculement, vous devez donc désactiver le site **principal** :

- Si vous avez accès au cluster Kubernetes **principal**, connectez-vous-y et désactivez les pods GitLab `webservice` et `Sidekiq` :

  ```shell
  kubectl --namespace gitlab scale deploy gitlab-geo-webservice-default --replicas=0
  kubectl --namespace gitlab scale deploy gitlab-geo-sidekiq-all-in-1-v1 --replicas=0
  ```

- Si vous n'avez pas accès au cluster Kubernetes **principal**, mettez le cluster hors ligne et empêchez-le de se remettre en ligne par tous les moyens à votre disposition. Vous pourriez avoir besoin de :

  - Reconfigurer les équilibreurs de charge.
  - Modifier les enregistrements DNS (par exemple, pointer l'enregistrement DNS principal vers le site **secondaire** pour arrêter l'utilisation du site **principal**).
  - Arrêter les serveurs virtuels.
  - Bloquer le trafic via un pare-feu.
  - Révoquer les autorisations de stockage d'objets du site **principal**.
  - Déconnecter physiquement une machine.

### Étape 2. Promouvoir tous les nœuds du site **secondaire** externes au cluster {#step-2-promote-all-secondary-site-nodes-external-to-the-cluster}

> [!warning]
> Si le site secondaire [a été mis en pause](../_index.md#pausing-and-resuming-replication), cela effectue une récupération à un point dans le temps vers le dernier état connu. Les données créées sur le principal pendant que le secondaire était en pause sont perdues.

1. Pour chaque nœud (tel que PostgreSQL ou Gitaly) en dehors du cluster Kubernetes **secondaire** utilisant le package Linux, connectez-vous en SSH au nœud et exécutez l'une des commandes suivantes :

   - Pour promouvoir le nœud du site **secondaire** externe au cluster Kubernetes en principal :

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - Pour promouvoir le nœud du site **secondaire** externe au cluster Kubernetes en principal **without any further confirmation** :

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Trouvez le pod `toolbox` :

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. Promouvez le secondaire :

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake gitlab:geo:set_secondary_as_primary
   ```

   Des variables d'environnement peuvent être fournies pour modifier le comportement de la tâche. Les variables disponibles sont :

   | Nom | Valeur par défaut | Description |
   | ---- | ------------- | ------- |
   | `ENABLE_SILENT_MODE` | `false`  | Si `true`, active le [Mode silencieux](../../silent_mode/_index.md) avant la promotion (GitLab 16.4 et versions ultérieures) |

### Étape 3. Promouvoir le cluster **secondaire** {#step-3-promote-the-secondary-cluster}

1. Mettez à jour la configuration existante du cluster.

   Vous pouvez récupérer la configuration existante avec Helm :

   ```shell
   helm --namespace gitlab get values gitlab-geo > gitlab.yaml
   ```

   La configuration existante contient une section pour Geo qui devrait ressembler à :

   ```yaml
   geo:
      enabled: true
      role: secondary
      nodeName: secondary.example.com
      psql:
         host: geo-2.db.example.com
         port: 5431
         password:
            secret: geo
            key: geo-postgresql-password
   ```

   Pour promouvoir le cluster **secondaire** en cluster **principal**, mettez à jour `role: secondary` en `role: primary`.

   Si le cluster reste en tant que site principal, vous devez supprimer l'intégralité de la section `psql` sous `geo` ; elle fait référence à la base de données de suivi. Si elle est laissée en place, l'application identifie le nœud comme secondaire au démarrage, ce qui entraîne des problèmes d'enregistrement des routes qui brisent l'authentification lorsqu'un nouveau secondaire est ajouté avec une URL unifiée.

   Mettez à jour le cluster avec la nouvelle configuration :

   ```shell
   helm upgrade --install --version <current Chart version> gitlab-geo gitlab/gitlab --namespace gitlab -f gitlab.yaml
   ```

1. Vérifiez que vous pouvez vous connecter au principal nouvellement promu en utilisant l'URL précédemment utilisée pour le secondaire.
1. Succès ! Le secondaire a maintenant été promu en principal.

### Étape 4. (Facultatif) Promouvoir le cluster OpenBao HA {#step-4-optional-promote-the-openbao-ha-cluster}

Si GitLab Secrets Manager est activé, effectuez les étapes suivantes pour promouvoir le cluster OpenBao à haute disponibilité (HA) après avoir promu le cluster Kubernetes.

#### Redémarrer les pods OpenBao {#restart-openbao-pods}

Après la promotion du réplica PostgreSQL en principal, redémarrez les pods OpenBao pour qu'ils se reconnectent à la base de données maintenant qu'elle est accessible en écriture :

```shell
kubectl --namespace gitlab rollout restart deployment -l app=openbao
```

#### (Facultatif) Configurer l'authentification JWT {#optional-configure-jwt-authentication}

Ignorez cette étape si vous avez mis à jour les enregistrements DNS du domaine principal pour qu'ils pointent vers le site secondaire.

Pour reconfigurer l'authentification JWT, vous avez besoin d'un jeton racine. Utilisez la clé de récupération pour en générer un. Pour plus d'informations, voir [Générer un jeton racine à partir de la clé de récupération](../../secrets_manager/recovery_key.md#generate-a-root-token-from-the-recovery-key).

Une fois que vous disposez d'un jeton racine, reconfigurez le point de montage d'authentification JWT pour qu'il pointe vers le domaine secondaire. Pour les détails de configuration, voir [Configuration Geo](https://docs.gitlab.com/charts/charts/openbao/#geo-configuration).

#### Restaurer le secret de déverrouillage si nécessaire {#restore-the-unseal-secret-if-needed}

La clé de déverrouillage sur le cluster secondaire doit être identique à celle du cluster principal, sinon OpenBao ne pourra pas déverrouiller le coffre sur le secondaire.

En cas de discordance, restaurez le secret `gitlab-openbao-unseal` sur le cluster secondaire à partir de votre [sauvegarde des secrets](https://docs.gitlab.com/charts/backup-restore/backup/#back-up-the-secrets), puis redémarrez les pods OpenBao :

```shell
kubectl --namespace gitlab rollout restart deployment -l app=openbao
```

#### Vérifier qu'OpenBao est fonctionnel {#verify-openbao-is-functional}

1. Vérifiez que tous les pods OpenBao sont en cours d'exécution :

   ```shell
   kubectl --namespace gitlab get pods -l app=openbao
   ```

1. Testez l'intégration OpenBao en exécutant un pipeline CI qui utilise une [variable Secrets Manager](../../../ci/secrets/secrets_manager/_index.md).

## Dépannage {#troubleshooting}

Cette section a été déplacée vers [un autre emplacement](failover_troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site).
