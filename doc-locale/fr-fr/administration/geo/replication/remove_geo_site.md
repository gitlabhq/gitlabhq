---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Suppression des sites Geo secondaires
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les sites **Secondaire** peuvent être supprimés du cluster Geo via la page d'administration Geo du site **principal**. Pour supprimer un site **secondaire** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Nœuds**.
1. Pour le site **secondaire** que vous souhaitez supprimer, sélectionnez **Supprimer**.
1. Confirmez en sélectionnant **Supprimer** lorsque l'invite s'affiche.

Une fois le site **secondaire** supprimé de la page d'administration Geo, vous devez arrêter et désinstaller ce site. Pour chaque nœud de votre site Geo secondaire :

1. Arrêtez GitLab :

   ```shell
   sudo gitlab-ctl stop
   ```

1. Désinstallez GitLab :

   > [!note]
   > Si les données GitLab doivent également être supprimées de l'instance, consultez comment [désinstaller le package Linux et toutes ses données](https://docs.gitlab.com/omnibus/installation/#uninstall-the-linux-package-omnibus).

   ```shell
   # Stop gitlab and remove its supervision process
   sudo gitlab-ctl uninstall

   # Debian/Ubuntu
   sudo dpkg --remove gitlab-ee

   # Redhat/Centos
   sudo rpm --erase gitlab-ee
   ```

Une fois GitLab désinstallé de chaque nœud du site **secondaire**, le slot de réplication doit être supprimé de la base de données du site **principal** comme suit :

1. Sur le nœud de base de données du site **principal**, démarrez une session console PostgreSQL :

   ```shell
   sudo gitlab-psql
   ```

   > [!note]
   > L'utilisation de `gitlab-rails dbconsole` ne fonctionne pas, car la gestion des slots de réplication nécessite des permissions de superutilisateur.

1. Trouvez le nom du slot de réplication concerné. Il s'agit du slot spécifié avec `--slot-name` lors de l'exécution de la commande de réplication : `gitlab-ctl replicate-geo-database`.

   ```sql
   SELECT * FROM pg_replication_slots;
   ```

1. Supprimez le slot de réplication pour le site **secondaire** :

   ```sql
   SELECT pg_drop_replication_slot('<name_of_slot>');
   ```
