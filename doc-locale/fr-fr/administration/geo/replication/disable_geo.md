---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Désactivation de Geo
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Si vous souhaitez revenir à une installation normale via un package Linux après un test, ou si vous avez rencontré une situation de reprise après sinistre et que vous souhaitez désactiver Geo momentanément, vous pouvez utiliser ces instructions pour désactiver votre configuration Geo.

Il ne devrait y avoir aucune différence fonctionnelle entre la désactivation de Geo et une configuration Geo active sans sites Geo secondaires si vous les supprimez correctement.

Pour désactiver Geo, procédez comme suit :

1. [Supprimer tous les sites Geo secondaires](#remove-all-secondary-geo-sites).
1. [Supprimer le site principal de l'interface utilisateur](#remove-the-primary-site-from-the-ui).
1. [Supprimer les slots de réplication secondaires](#remove-secondary-replication-slots).
1. [Supprimer la configuration liée à Geo](#remove-geo-related-configuration).
1. [Facultatif. Rétablir les paramètres PostgreSQL pour utiliser un mot de passe et écouter sur une adresse IP](#optional-revert-postgresql-settings-to-use-a-password-and-listen-on-an-ip).

## Supprimer tous les sites Geo secondaires {#remove-all-secondary-geo-sites}

Pour désactiver Geo, vous devez d'abord supprimer tous vos sites Geo secondaires, ce qui signifie que la réplication n'a plus lieu sur ces sites. Vous pouvez consulter notre documentation pour [supprimer vos sites Geo secondaires](remove_geo_site.md).

Si le site actuel que vous souhaitez continuer à utiliser est un site secondaire, vous devez d'abord le promouvoir en site principal. Vous pouvez suivre nos étapes sur [la promotion d'un site secondaire](../disaster_recovery/_index.md#step-2-promoting-a-secondary-site) pour effectuer cette opération.

## Supprimer le site principal de l'interface utilisateur {#remove-the-primary-site-from-the-ui}

Pour supprimer le site **principal** :

1. [Supprimer tous les sites Geo secondaires](remove_geo_site.md)
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Nœuds**.
1. Sélectionnez **Supprimer** pour le nœud **principal**.
1. Confirmez en sélectionnant **Supprimer** lorsque l'invite s'affiche.

## Supprimer les slots de réplication secondaires {#remove-secondary-replication-slots}

Pour supprimer les slots de réplication secondaires, exécutez l'une des requêtes suivantes sur votre nœud Geo principal dans une console PostgreSQL (`sudo gitlab-psql`) :

- Si vous disposez déjà d'un cluster PostgreSQL, supprimez les slots de réplication individuels par leur nom pour éviter de supprimer vos bases de données secondaires du même cluster. Vous pouvez utiliser la commande suivante pour obtenir tous les noms, puis supprimer chaque slot individuellement :

  ```sql
  SELECT slot_name, slot_type, active FROM pg_replication_slots; -- view present replication slots
  SELECT pg_drop_replication_slot('slot_name'); -- where slot_name is the one expected from the previous command
  ```

- Pour supprimer tous les slots de réplication secondaires :

  ```sql
  SELECT pg_drop_replication_slot(slot_name) FROM pg_replication_slots;
  ```

## Supprimer la configuration liée à Geo {#remove-geo-related-configuration}

1. Pour chaque nœud de votre site Geo principal, connectez-vous en SSH au nœud et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et supprimez la configuration liée à Geo en supprimant toutes les lignes qui activaient `geo_primary_role` :

   ```ruby
   ## In pre-11.5 documentation, the role was enabled as follows. Remove this line.
   geo_primary_role['enable'] = true

   ## In 11.5+ documentation, the role was enabled as follows. Remove this line.
   roles ['geo_primary_role']
   ```

1. Après avoir effectué ces modifications, [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## (Facultatif) Rétablir les paramètres PostgreSQL pour utiliser un mot de passe et écouter sur une adresse IP {#optional-revert-postgresql-settings-to-use-a-password-and-listen-on-an-ip}

Si vous souhaitez supprimer les paramètres spécifiques à PostgreSQL et revenir aux valeurs par défaut (en utilisant un socket à la place), vous pouvez supprimer en toute sécurité les lignes suivantes du fichier `/etc/gitlab/gitlab.rb` :

```ruby
postgresql['sql_user_password'] = '...'
gitlab_rails['db_password'] = '...'
postgresql['listen_address'] = '...'
postgresql['md5_auth_cidr_addresses'] =  ['...', '...']
```
