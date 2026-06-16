---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
ignore_in_report: true
title: Runbooks de promotion pour la reprise après sinistre (Geo)
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed
- Statut :  Expérience

{{< /details >}}

Runbooks de promotion pour la reprise après sinistre (Geo).

> [!warning]
> Ce runbook est une [expérience](../../../../policy/development_stages_support.md#experiment). Pour une documentation complète et prête pour la production, consultez la [documentation sur la reprise après sinistre](../_index.md).

## Basculement planifié Geo pour une configuration multi-nœuds {#geo-planned-failover-for-a-multi-node-configuration}

| Composant   | Configuration                |
|:------------|:-----------------------------|
| PostgreSQL  | Géré par le package Linux |
| Site Geo    | Multi-nœuds                   |
| Secondaires | Un                          |

Ce runbook vous guide à travers un basculement planifié d'un site Geo multi-nœuds avec un secondaire. L'[architecture de référence suivante de 40 RPS / 2 000 utilisateurs](../../../reference_architectures/2k_users.md) est supposée :

Site principal (multi-nœuds) :

- Nœud Rails 1
- Nœud Rails 2
- Nœud PostgreSQL
- Nœud Gitaly
- Nœud Redis
- Nœud de surveillance

Site secondaire :

- Nœud Rails 1
- Nœud Rails 2
- Nœud PostgreSQL
- Nœud Gitaly
- Nœud Redis
- Nœud de surveillance

Ce guide aboutit aux résultats suivants :

1. Un site principal hors ligne.
1. Un site secondaire promu qui est désormais le nouveau site principal.

Ce qui n'est pas couvert :

1. Rajout de l'ancien site **principal** en tant que secondaire.
1. Ajout d'un nouveau site secondaire.

### Préparation {#preparation}

> [!note]
> Avant de suivre l'une de ces étapes, assurez-vous d'avoir l'accès `root` au site **secondaire** pour le promouvoir, car il n'existe pas de méthode automatisée pour promouvoir un réplica Geo et effectuer un basculement.

Sur le site **secondaire** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites** pour voir son statut. Les objets répliqués (affichés en vert) doivent être proches de 100 %, et il ne doit y avoir aucune défaillance (affichée en rouge). Si une grande proportion d'objets n'est pas répliquée (affichée en gris), envisagez d'accorder plus de temps au site pour terminer.

   ![Statut de réplication](img/geo_dashboard_v14_0.png)

Si des objets échouent à se répliquer, cela doit être examiné avant de planifier la fenêtre de maintenance. Après un basculement planifié, tout ce qui n'a pas pu être répliqué est **lost**.

Une cause fréquente des échecs de réplication est l'absence de données sur le site **principal** — vous pouvez résoudre ces échecs en restaurant les données à partir d'une sauvegarde ou en supprimant les références aux données manquantes.

La fenêtre de maintenance ne se termine pas tant que la réplication et la vérification Geo ne sont pas complètement terminées. Pour maintenir la fenêtre aussi courte que possible, vous devez vous assurer que ces processus sont aussi proches que possible de 100 % pendant une utilisation active.

Si le site **secondaire** est encore en train de répliquer des données depuis le site **principal**, suivez ces étapes pour éviter une perte de données inutile :

1. Activez le [mode maintenance](../../../maintenance_mode/_index.md) sur le site **principal**, et assurez-vous d'arrêter tous les [jobs en arrière-plan](../../../maintenance_mode/_index.md#background-jobs).
1. Terminez la réplication et la vérification de toutes les données :

   > [!warning]
   > Toutes les données ne sont pas automatiquement répliquées. En savoir plus sur [ce qui est exclu](../planned_failover.md#not-all-data-is-automatically-replicated).

   1. Si vous répliquez manuellement des [données non gérées par Geo](../../replication/datatypes.md#replicated-data-types), déclenchez maintenant le processus de réplication final.
   1. Sur le site **principal** :
      1. Dans le coin supérieur droit, sélectionnez **Admin**.
      1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Jobs en arrière-plan**.
      1. Sur le tableau de bord Sidekiq, sélectionnez **Queues**, et attendez que toutes les files d'attente, à l'exception de celles contenant `geo` dans le nom, tombent à 0. Ces files d'attente contiennent du travail soumis par vos utilisateurs ; effectuer un basculement avant qu'il soit terminé entraîne la perte de ce travail.
      1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites** et attendez que les conditions suivantes soient vraies pour le site **secondaire** vers lequel vous effectuez le basculement :

         - Tous les compteurs de réplication atteignent 100 % répliqué, 0 % d'échecs.
         - Tous les compteurs de vérification atteignent 100 % vérifié, 0 % d'échecs.
         - Le décalage de réplication de la base de données est de 0 ms.
         - Le curseur de log Geo est à jour (0 événement en retard).

   1. Sur le site **secondaire** :
      1. Dans le coin supérieur droit, sélectionnez **Admin**.
      1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Jobs en arrière-plan**.
      1. Sur le tableau de bord Sidekiq, sélectionnez **Queues**, et attendez que toutes les files d'attente `geo` tombent à 0 job en file d'attente et 0 job en cours d'exécution.
      1. [Exécutez une vérification d'intégrité](../../../raketasks/check.md) pour vérifier l'intégrité des artefacts CI, des objets LFS et des téléversements dans le stockage de fichiers.

   À ce stade, votre site **secondaire** contient une copie à jour de tout ce que possède le site **principal**, ce qui signifie que rien n'est perdu lors du basculement.

1. Dans cette dernière étape, vous devez désactiver définitivement le site **principal**.

   > [!warning]
   > Lorsque le site **principal** passe hors ligne, il peut y avoir des données enregistrées sur le site **principal** qui n'ont pas été répliquées vers le site **secondaire**. Ces données doivent être considérées comme perdues si vous continuez.

   Si vous prévoyez de [mettre à jour l'enregistrement DNS du domaine **principal**](../_index.md#optional-updating-the-primary-domain-dns-record), vous pouvez souhaiter réduire le TTL maintenant pour accélérer la propagation.

   Lors d'un basculement, nous voulons éviter une situation de split-brain où des écritures peuvent se produire dans deux instances GitLab différentes. Ainsi, pour préparer le basculement, vous devez désactiver le site **principal** :

   - Si vous avez un accès SSH au site **principal**, arrêtez et désactivez GitLab :

     ```shell
     sudo gitlab-ctl stop
     ```

     Empêchez GitLab de redémarrer si le serveur redémarre de manière inattendue :

     ```shell
     sudo systemctl disable gitlab-runsvdir
     ```

     > [!note]
     >
     > - Sous CentOS 6 ou version antérieure, il est difficile d'empêcher GitLab de démarrer si le redémarrage de la machine n'est pas disponible (voir [issue 3058](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3058)). Il peut être plus sûr de désinstaller complètement le package GitLab avec `sudo yum remove gitlab-ee`.
     > - Si vous utilisez une ancienne version d'Ubuntu comme 14.04 LTS ou toute autre distribution basée sur le système d'initialisation Upstart, vous pouvez empêcher GitLab de démarrer si la machine redémarre en tant que `root` avec `initctl stop gitlab-runsvvdir && echo 'manual' > /etc/init/gitlab-runsvdir.override && initctl reload-configuration`.

   - Si vous n'avez pas d'accès SSH au site **principal**, mettez la machine hors ligne et empêchez-la de redémarrer. Comme il existe de nombreuses façons d'y parvenir selon vos préférences, nous évitons de formuler une seule recommandation. Vous devrez peut-être :

     - Reconfigurer les équilibreurs de charge.
     - Modifier les enregistrements DNS (par exemple, pointer l'enregistrement DNS **principal** vers le site **secondaire** pour cesser d'utiliser le site **principal**).
     - Arrêter les serveurs virtuels.
     - Bloquer le trafic via un pare-feu.
     - Révoquer les permissions de stockage d'objets du site **principal**.
     - Déconnecter physiquement une machine.

### Promotion du site **secondaire** {#promoting-the-secondary-site}

1. Connectez-vous en SSH à chaque nœud Sidekiq, PostgreSQL et Gitaly du site **secondaire** et exécutez l'une des commandes suivantes :

   - Pour promouvoir le site secondaire en site principal :

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - Pour promouvoir le site secondaire en site principal sans aucune confirmation supplémentaire :

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Connectez-vous en SSH à chaque nœud Rails de votre site **secondaire** et exécutez l'une des commandes suivantes :

   - Pour promouvoir le site secondaire en site principal :

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - Pour promouvoir le site secondaire en site principal sans aucune confirmation supplémentaire :

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Vérifiez que vous pouvez vous connecter au site **principal** nouvellement promu en utilisant l'URL précédemment utilisée pour le site **secondaire**.

1. En cas de succès, le site **secondaire** est maintenant promu en site **principal**.

### Étapes suivantes {#next-steps}

Pour retrouver la redondance géographique aussi rapidement que possible, vous devriez [ajouter un nouveau site **secondaire**](../../setup/_index.md). Pour ce faire, vous pouvez rajouter l'ancien site **principal** en tant que nouveau secondaire et le remettre en ligne.
