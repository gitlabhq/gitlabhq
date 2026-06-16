---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Vérification automatique en arrière-plan
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

La vérification automatique en arrière-plan garantit que les données transférées correspondent à une somme de contrôle calculée. Si la somme de contrôle des données sur le site **principal** correspond à la somme de contrôle des données sur le site **secondaire**, les données ont été transférées avec succès. Suite à un basculement planifié, toute donnée corrompue peut être **lost**, selon l'étendue de la corruption.

Si la vérification échoue sur le site **principal**, cela indique que Geo réplique un objet corrompu. Vous pouvez le restaurer à partir d'une sauvegarde ou le supprimer du site **principal** pour résoudre le problème.

Si la vérification réussit sur le site **principal** mais échoue sur le site **secondaire**, cela indique que l'objet a été corrompu pendant le processus de réplication. Geo tente activement de corriger les échecs de vérification en marquant le dépôt pour être resynchronisé avec une période de temporisation. Si vous souhaitez réinitialiser la vérification pour ces échecs, vous devez suivre [ces instructions](background_verification.md#reset-verification-for-projects-where-verification-has-failed).

Si la vérification prend un retard significatif par rapport à la réplication, envisagez d'accorder plus de temps au site avant de planifier un basculement.

## Vérification des dépôts {#repository-verification}

Prérequis :

- Accès administrateur.

Sur le site **principal** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Développez l'onglet **Informations de vérification** pour ce site afin de consulter l'état de la somme de contrôle automatique pour les dépôts et les wikis. Les succès sont affichés en vert, les travaux en attente en gris et les échecs en rouge.

   ![Onglet Informations de vérification avec une vue d'ensemble d'une instance Geo principale saine.](img/verification_status_primary_v14_0.png)

Sur le site **secondaire** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Développez l'onglet **Informations de vérification** pour ce site afin de consulter l'état de la somme de contrôle automatique pour les dépôts et les wikis. Les succès sont affichés en vert, les travaux en attente en gris et les échecs en rouge.

   ![Onglet Informations de vérification avec une vue d'ensemble d'une instance Geo secondaire saine.](img/verification_status_secondary_v14_0.png)

## Utilisation des sommes de contrôle pour comparer les sites Geo {#using-checksums-to-compare-geo-sites}

Pour vérifier l'état de santé des sites Geo **secondaire**, nous utilisons une somme de contrôle sur la liste des références Git et leurs valeurs. La somme de contrôle inclut `HEAD`, `heads`, `tags`, `notes`, ainsi que les références spécifiques à GitLab pour garantir une véritable cohérence. Si deux sites ont la même somme de contrôle, ils contiennent définitivement les mêmes références. Nous calculons la somme de contrôle pour chaque site après chaque mise à jour afin de nous assurer qu'ils sont tous synchronisés.

## Revérification des dépôts {#repository-re-verification}

En raison de bogues ou de défaillances d'infrastructure transitoires, il est possible que des dépôts Git changent de manière inattendue sans être marqués pour vérification. Geo vérifie constamment les dépôts pour garantir l'intégrité des données. L'intervalle de revérification par défaut et recommandé est de 7 jours, bien qu'un intervalle aussi court qu'1 jour puisse être défini. Des intervalles plus courts réduisent le risque mais augmentent la charge, et vice versa.

Sur le site **principal** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Sélectionnez **Éditer** pour le site **principal** afin de personnaliser l'intervalle de revérification minimum :

   ![Fenêtre avec les attributs de configuration d'un nœud Geo.](img/reverification-interval_v11_6.png)

## Réinitialiser la vérification pour les projets dont la vérification a échoué {#reset-verification-for-projects-where-verification-has-failed}

Geo tente activement de corriger les échecs de vérification en marquant le dépôt pour être resynchronisé avec une période de temporisation. Vous pouvez également [resynchroniser et revérifier manuellement des composants individuels via l'interface utilisateur ou la console Rails](../replication/troubleshooting/synchronization_verification.md#resync-and-reverify-individual-components).

## Réconcilier les différences avec les non-correspondances de sommes de contrôle {#reconcile-differences-with-checksum-mismatches}

{{< history >}}

- Les champs **Storage name** et **Relative path** ont été [renommés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128416) depuis **Gitaly storage name** et **Gitaly relative path** dans GitLab 16.3.

{{< /history >}}

Si les sites **principal** et **secondaire** ont une non-correspondance de vérification de somme de contrôle, la cause peut ne pas être évidente. Pour trouver la cause d'une non-correspondance de somme de contrôle :

1. Sur le site **principal** :
   1. Dans le coin supérieur droit, sélectionnez **Admin**.
   1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Projets**.
   1. Trouvez le projet dont vous souhaitez vérifier les différences de somme de contrôle et sélectionnez son nom.
   1. Sur la page d'administration du projet, obtenez les valeurs dans les champs **Storage name** et **Relative path**.

1. Sur un **Gitaly node on the primary** et un **Gitaly node on the secondary**, accédez au répertoire du dépôt du projet. Si vous utilisez le cluster Gitaly (Praefect), [vérifiez qu'il est dans un état sain](../../gitaly/praefect/troubleshooting.md#check-cluster-health) avant d'exécuter ces commandes.

   Le chemin par défaut est `/var/opt/gitlab/git-data/repositories`. Si les stockages de dépôts sont personnalisés, vérifiez la disposition des répertoires sur votre serveur pour en être sûr :

   ```shell
   cd /var/opt/gitlab/git-data/repositories
   ```

   1. Exécutez la commande suivante sur le site **principal**, en redirigeant la sortie vers un fichier :

      ```shell
      git show-ref --head | grep -E "HEAD|(refs/(heads|tags|keep-around|merge-requests|environments|notes)/)" > primary-site-refs
      ```

   1. Exécutez la commande suivante sur le site **secondaire**, en redirigeant la sortie vers un fichier :

      ```shell
      git show-ref --head | grep -E "HEAD|(refs/(heads|tags|keep-around|merge-requests|environments|notes)/)" > secondary-site-refs
      ```

   1. Copiez les fichiers des étapes précédentes sur le même système et effectuez un diff entre les contenus :

      ```shell
      diff primary-site-refs secondary-site-refs
      ```

## Limitations actuelles {#current-limitations}

Pour plus d'informations sur les méthodes de réplication et de vérification prises en charge, consultez les [types de données Geo pris en charge](../replication/datatypes.md).
