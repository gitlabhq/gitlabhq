---
title: "Les plafonds d'utilisation des GitLab Credits sont en disponibilité générale"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: fulfillment
documentation_link: "../../../subscriptions/gitlab_credits_dashboard/#usage-caps"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/607551
categories: [ Consumables Cost Management ]
level: secondary
---

L'utilisation à la demande peut générer des frais de dépassement imprévus. Les plafonds d'utilisation des GitLab Credits sont désormais en disponibilité générale : définissez un plafond au niveau de l'abonnement sur les crédits à la demande dans le portail clients, et définissez un plafond par défaut par utilisateur ou des remplacements par utilisateur avec l'API GraphQL. Lorsque la consommation atteint un plafond, les fonctionnalités qui consomment des GitLab Credits, comme GitLab Duo Agent Platform, sont suspendues jusqu'au début de la prochaine période de facturation ou jusqu'à ce qu'un administrateur ajuste le plafond. Les plafonds d'utilisation ont été introduits dans GitLab 18.11 via le feature flag `budget_caps_graphql_api`. Dans GitLab 19.3, le feature flag est supprimé.
