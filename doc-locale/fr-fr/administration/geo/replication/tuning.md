---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Réglage de Geo
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez limiter le nombre d'opérations simultanées que les sites peuvent exécuter en arrière-plan.

## Modification des valeurs de simultanéité de synchronisation/vérification {#changing-the-syncverification-concurrency-values}

Sur le site **principal** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Sélectionnez **Éditer** pour le site secondaire que vous souhaitez régler.
1. Sous **Paramètres de réglage**, plusieurs variables peuvent être ajustées pour améliorer les performances de Geo :

   - Limite de simultanéité de synchronisation des dépôts
   - Limite de simultanéité de synchronisation des fichiers
   - Limite de simultanéité de synchronisation des dépôts de conteneurs
   - Limite de simultanéité de vérification

L'augmentation des valeurs de simultanéité accroît le nombre de jobs planifiés. Cependant, cela peut ne pas entraîner davantage de téléchargements en parallèle, sauf si le nombre de fils de discussion Sidekiq disponibles est également augmenté. Par exemple, si la simultanéité de synchronisation des dépôts est augmentée de 25 à 50, vous souhaiterez peut-être également augmenter le nombre de fils de discussion Sidekiq de 25 à 50. Consultez la [documentation sur la simultanéité Sidekiq](../../sidekiq/extra_sidekiq_processes.md#concurrency) pour plus de détails.

## Réglage des paramètres par défaut faibles {#tuning-low-default-settings}

Pour éviter une charge excessive lors de la configuration de nouveaux sites Geo, à partir de GitLab 18.0, les paramètres de simultanéité de Geo sont définis sur des valeurs par défaut faibles pour la plupart des environnements. Pour augmenter ces paramètres :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Déterminez quels types de données progressent trop lentement.
1. Surveillez les métriques de charge des sites principal et secondaire.
1. Augmentez les limites de simultanéité de 10 pour rester prudent.
1. Surveillez les changements de progression et les métriques de charge pendant au moins 3 minutes.
1. Répétez l'augmentation des limites jusqu'à ce que les métriques de charge atteignent le maximum souhaité ou que la synchronisation et la vérification progressent aussi rapidement que souhaité.

## Re-vérification des dépôts {#repository-re-verification}

Consultez [Vérification automatique en arrière-plan](../disaster_recovery/background_verification.md).
