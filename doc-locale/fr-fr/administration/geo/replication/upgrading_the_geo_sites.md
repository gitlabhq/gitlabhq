---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Mise à niveau des sites Geo
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!warning]
> Lisez attentivement ces sections avant de mettre à jour vos sites Geo. Ne pas suivre les étapes de mise à niveau spécifiques à la version peut entraîner des interruptions de service imprévues. Si vous avez des questions spécifiques, [contactez le support](https://about.gitlab.com/support/#contact-support). Une mise à niveau majeure de la version de base de données nécessite de [réinitialiser la réplication PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#upgrading-a-geo-instance) vers les sites Geo secondaires. Cela s'applique aux bases de données packagées sous Linux et aux bases de données gérées en externe. Cela peut entraîner une interruption de service plus longue que prévu.

La mise à niveau des sites Geo implique d'effectuer :

1. Les étapes de mise à niveau spécifiques à la version, selon la version vers laquelle ou depuis laquelle vous effectuez la mise à niveau :
   - [Notes de mise à niveau de GitLab 19](../../../update/versions/gitlab_19_changes.md)
   - [Notes de mise à niveau de GitLab 18](../../../update/versions/gitlab_18_changes.md)
   - [Notes de mise à niveau de GitLab 17](../../../update/versions/gitlab_17_changes.md)
   - [Notes de mise à niveau de GitLab 16](../../../update/versions/gitlab_16_changes.md)
   - [Notes de mise à niveau de GitLab 15](../../../update/versions/gitlab_15_changes.md)
1. [Étapes générales de mise à niveau](#general-upgrade-steps), pour toutes les mises à niveau.

## Étapes générales de mise à niveau {#general-upgrade-steps}

> [!note]
> Ces étapes générales de mise à niveau nécessitent une interruption de service dans une configuration multi-nœuds. Si vous souhaitez éviter les interruptions de service, envisagez d'utiliser les [mises à niveau sans interruption de service](../../../update/zero_downtime.md#upgrade-multi-node-geo-instances).

Pour mettre à niveau les sites Geo lors de la sortie d'une nouvelle version de GitLab, mettez à niveau le site **principal** et tous les sites **secondaire** :

1. Facultatif. [Suspendez la réplication sur chaque site **secondaire**](pause_resume_replication.md) pour protéger la capacité de reprise après sinistre (DR) des sites **secondaire**. Suspendez la réplication lorsque votre priorité est de préserver un point de contrôle DR propre lors d'une fenêtre de mise à niveau à risque élevé. Ne suspendez pas la réplication si votre priorité est de maintenir le site secondaire à jour et de servir le trafic en lecture normalement pendant la mise à niveau, en particulier dans une approche sans interruption de service.
1. Connectez-vous en SSH à chaque nœud du site **principal**.
1. [Mettez à niveau GitLab sur le site **principal**](../../../update/package/_index.md).
1. Effectuez des tests sur le site **principal**, en particulier si vous avez suspendu la réplication à l'étape 1 pour protéger la DR. Pour plus d'informations sur les tests post-mise à niveau, consultez [Exécuter les vérifications de l'état de la mise à niveau](../../../update/plan_your_upgrade.md#run-upgrade-health-checks).
1. Assurez-vous que les secrets du fichier `/etc/gitlab/gitlab-secrets.json` du site principal et du site secondaire sont identiques. Le fichier doit être identique sur tous les nœuds d'un site.
1. Connectez-vous en SSH à chaque nœud des sites **secondaire**.
1. [Mettez à niveau GitLab sur chaque site **secondaire**](../../../update/package/_index.md).
1. Si vous avez suspendu la réplication à l'étape 1, [reprenez la réplication sur chaque site **secondaire**](../_index.md#pausing-and-resuming-replication). Ensuite, redémarrez Puma et Sidekiq sur chaque site **secondaire**. Cela permet de s'assurer qu'ils sont initialisés par rapport au nouveau schéma de base de données qui est maintenant répliqué depuis le site **principal** précédemment mis à niveau.

   ```shell
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart puma
   ```

1. [Testez](#check-status-after-upgrading) les sites **principal** et **secondaire**, et vérifiez la version sur chacun d'eux.

### Vérifier l'état après la mise à niveau {#check-status-after-upgrading}

Maintenant que le processus de mise à niveau est terminé, vous pouvez vérifier que tout fonctionne correctement :

1. Exécutez la tâche Geo Rake sur un nœud d'application pour les sites principal et secondaire. Tout devrait être vert :

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

1. Vérifiez le tableau de bord Geo du site **principal** pour détecter d'éventuelles erreurs.
1. Testez la réplication des données en poussant du code vers le site **principal** et vérifiez s'il est reçu par les sites **secondaire**.

Si vous rencontrez des problèmes, consultez le [guide de dépannage Geo](troubleshooting/_index.md).
