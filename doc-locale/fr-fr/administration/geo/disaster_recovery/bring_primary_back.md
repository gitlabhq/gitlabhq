---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Réintroduire un site rétrogradé dans Geo
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Après un basculement, il est possible de réintroduire le site **principal** rétrogradé en tant que nouveau site **secondaire** ou de restaurer votre site **principal** d'origine. Ce processus comprend deux étapes :

1. Transformer l'ancien site **principal** en site **secondaire**.
1. Promouvoir un site **secondaire** en site **principal**.

> [!warning]
>
> - Si vous avez des doutes concernant la cohérence des données sur ce site, vous devriez le configurer depuis zéro.
> - Le site principal rétrogradé est considéré comme un serveur GitLab autonome qui n'est plus synchronisé avec Geo.
>
>   Assurez-vous que toute configuration résiduelle en tant qu'ancien site principal est supprimée avant de le rajouter en tant que nouveau site secondaire.

## Configurer l'ancien site **principal** en tant que site **secondaire** {#configure-the-former-primary-site-to-be-a-secondary-site}

Étant donné que l'ancien site **principal** n'est pas synchronisé avec le site **principal** actuel, la première étape consiste à mettre à jour l'ancien site **principal**. Notez que la suppression des données stockées sur disque telles que les dépôts et les téléversements n'est pas rejouée lors de la resynchronisation de l'ancien site **principal**, ce qui peut entraîner une augmentation de l'utilisation du disque. Vous pouvez également [configurer une nouvelle instance GitLab **secondaire**](../setup/_index.md) pour éviter cela.

Pour mettre à jour l'ancien site **principal** :

1. Connectez-vous via SSH à l'ancien site **principal** qui a pris du retard.
1. Supprimez `/etc/gitlab/gitlab-cluster.json` s'il existe. ([Qu'est-ce que le fichier `gitlab-cluster.json` ?](https://docs.gitlab.com/omnibus/development/reconfigure_in_detail/#gitlab-clusterjson-file))

   Si le site à rajouter en tant que site **secondaire** a été promu avec la commande `gitlab-ctl geo promote`, il peut contenir `/etc/gitlab/gitlab-cluster.json`. Par exemple, lors de l'exécution de `gitlab-ctl reconfigure`, vous pouvez remarquer une sortie du type :

   ```plaintext
   The 'geo_primary_role' is defined in /etc/gitlab/gitlab-cluster.json as 'true' and overrides the setting in the /etc/gitlab/gitlab.rb
   ```

   Dans ce cas, `/etc/gitlab/gitlab-cluster.json` doit être supprimé de chaque nœud Sidekiq, PostgreSQL, Gitaly et Rails du site (en cas de configuration multi-nœuds), afin de faire de `/etc/gitlab/gitlab.rb` l'unique source de vérité.

1. Assurez-vous que tous les services sont en cours d'exécution :

   ```shell
   sudo gitlab-ctl start
   ```

   > [!note]
   > - Si vous avez [désactivé le site **principal** de façon permanente](_index.md#step-1-permanently-disable-the-primary-site), vous devez annuler ces étapes maintenant. Pour les distributions avec systemd, telles que Debian/Ubuntu/CentOS7+, vous devez exécuter `sudo systemctl enable gitlab-runsvdir`. Pour les distributions sans systemd, telles que CentOS 6, vous devez installer l'instance GitLab depuis zéro et la configurer en tant que site **secondaire** en suivant les [instructions de configuration](../setup/_index.md). Dans ce cas, vous n'avez pas besoin de suivre l'étape suivante.
   > - Si vous avez [modifié les enregistrements DNS](_index.md#optional-updating-the-primary-domain-dns-record) pour ce site lors de la procédure de reprise après sinistre, vous devrez peut-être [bloquer toutes les écritures vers ce site](planned_failover.md#prevent-updates-to-the-primary-site) pendant cette procédure.

1. [Configurer Geo](../setup/_index.md). Dans ce cas, le site **secondaire** fait référence à l'ancien site **principal**.
   1. Si [PgBouncer](../../postgresql/pgbouncer.md) était activé sur le site **current secondary** (lorsqu'il était un site principal), désactivez-le en modifiant `/etc/gitlab/gitlab.rb` et en exécutant `sudo gitlab-ctl reconfigure`.
   1. Vous pouvez ensuite configurer la réplication de base de données sur le site **secondaire**.
   1. Initialisez le schéma de base de données de suivi Geo sur le site **secondaire** réintroduit.

      `gitlab-ctl replicate-geo-database` réplique uniquement la base de données principale `gitlabhq_production`. La base de données de suivi Geo (`gitlabhq_geo_production`) est locale au site **secondaire** et est normalement migrée par `sudo gitlab-ctl reconfigure` via `geo_secondary['auto_migrate']`. Si `auto_migrate` est désactivé, si la base de données de suivi est externe, ou si elle était vide lors de la dernière exécution de reconfigure, le curseur de journal Geo se bloque et tous les types de synchronisation restent à 0 %.

      Dans ces cas, sur un nœud Rails ou Sidekiq du site **secondaire** :
      
      1. [Exécutez les migrations de base de données de suivi manuellement](../setup/external_database.md#set-up-the-database-schema).
      1. Redémarrez le curseur de journal Geo afin qu'il prenne en compte le nouveau schéma :

         ```shell
         sudo gitlab-ctl restart geo-logcursor
         ```

      1. Vérifiez que la base de données de suivi est correctement configurée avant de continuer :

         ```shell
         # Confirm the tracking database has tables
         sudo gitlab-geo-psql -d gitlabhq_geo_production -c "\dt"

         # Confirm all tracking database migrations are applied
         sudo gitlab-rake db:migrate:status:geo | grep -w down

         # Run the full Geo check
         sudo gitlab-rake gitlab:geo:check
         ```

      La commande `db:migrate:status:geo` ne doit retourner aucune migration `down`, et `gitlab:geo:check` doit indiquer `GitLab Geo tracking database is correctly configured ... yes` dans sa sortie.

   1. Configurez l'audience JWT pour OpenBao. Si vous avez activé GitLab Secrets Manager et que les sites principal et secondaire ne partagent pas la même audience JWT, définissez `jwt_audience` sur l'URL OpenBao du nouveau site principal dans les valeurs Helm du site secondaire rajouté :

      ```yaml
      global:
        openbao:
          enabled: true
          url: https://openbao.old-primary.example.com:8200
          jwt_audience: https://openbao.promoted.example.com:8200
      ```

Si vous avez perdu votre site **principal** d'origine, suivez les [instructions de configuration](../setup/_index.md) pour configurer un nouveau site **secondaire**.

## Promouvoir le site **secondaire** en site **principal** {#promote-the-secondary-site-to-primary-site}

Lorsque la réplication initiale est terminée et que le site **principal** et le site **secondaire** sont étroitement synchronisés, vous pouvez effectuer un [basculement planifié](planned_failover.md).

## Restaurer le site **secondaire** {#restore-the-secondary-site}

Si votre objectif est d'avoir à nouveau deux sites, vous devez également remettre votre site **secondaire** en ligne en répétant la première étape ([configurer l'ancien site **principal** en tant que site **secondaire**](#configure-the-former-primary-site-to-be-a-secondary-site)) pour le site **secondaire**.

### Restauration de sites **secondaire** supplémentaires {#restoring-additional-secondary-sites}

S'il y a plus d'un site **secondaire**, les sites restants peuvent être remis en ligne maintenant. Pour chacun des sites restants, [lancez le processus de réplication](../setup/database.md#step-3-initiate-the-replication-process) avec le site **principal**.

## Ignorer le re-transfert de données sur un site **secondaire** {#skipping-re-transfer-of-data-on-a-secondary-site}

Lorsqu'un site secondaire est ajouté, s'il contient des données qui auraient autrement été synchronisées depuis le site principal, Geo évite de re-transférer ces données.

- Les dépôts Git sont transférés par `git fetch`, qui ne transfère que les références manquantes.
- Le code de synchronisation du registre de conteneurs de Geo compare des tuples de tags et de condensés, et ne récupère que ceux qui sont manquants.
- Les [blobs](#skipping-re-transfer-of-blobs) sont ignorés s'ils existent lors de la première synchronisation.

Cas d'utilisation :

- Vous effectuez un basculement planifié et rétrogradez l'ancien site principal en le rattachant en tant que site secondaire sans le reconstruire.
- Vous avez plusieurs sites Geo secondaires. Vous effectuez un basculement planifié et rattachez les autres sites Geo secondaires sans les reconstruire.
- Vous effectuez un test de basculement en promouvant et en rétrogradant un site secondaire, puis vous le rattachez sans le reconstruire.
- Vous restaurez une sauvegarde et rattachez le site en tant que site secondaire.
- Vous copiez manuellement des données vers un site secondaire pour contourner un problème de synchronisation.
- Vous supprimez ou tronquez des lignes de la table du registre dans la base de données de suivi Geo pour contourner un problème.
- Vous réinitialisez la base de données de suivi Geo pour contourner un problème.

### Ignorer le re-transfert des blobs {#skipping-re-transfer-of-blobs}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/352530) dans GitLab 16.8 [avec un indicateur](../../feature_flags/_index.md) nommé `geo_skip_download_if_exists`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/435788) dans GitLab 16.9. Indicateur de fonctionnalité `geo_skip_download_if_exists` supprimé.

{{< /history >}}

Lorsque vous ajoutez un site secondaire qui contient déjà des données de blobs, le site Geo secondaire évite de re-transférer ces données. Cela s'applique aux éléments suivants :

- Artefacts de job CI
- Artefacts de pipeline CI
- Fichiers sécurisés CI
- Objets LFS
- Diffs de merge request
- Fichiers de paquets
- Déploiements Pages
- Versions d'état Terraform
- Téléversements
- Manifestes du proxy de dépendances
- Blobs du proxy de dépendances

Si la copie du site secondaire est effectivement corrompue, la vérification en arrière-plan finira par échouer et le blob sera resynchronisé.

Les blobs ne seront ignorés de cette manière que s'ils n'ont pas d'enregistrement de registre correspondant dans la base de données de suivi Geo. Les conditions sont strictes car la resynchronisation est presque toujours intentionnelle, et nous ne pouvons pas risquer d'ignorer par erreur un transfert.
