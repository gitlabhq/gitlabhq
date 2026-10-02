---
title: "Définir des plafonds de crédit sans l'API GraphQL"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed ]
stage: fulfillment
documentation_link: "../../../subscriptions/gitlab_credits_dashboard/#manage-credit-caps"
work_item: https://gitlab.com/gitlab-org/gitlab/-/issues/628559
categories: [ Consumables Cost Management ]
level: secondary
---

Les plafonds de crédit limitent le nombre de GitLab Credits que chaque utilisateur peut consommer, mais jusqu'à présent, vous ne pouviez les configurer que via l'API GraphQL. Définir un plafond différent pour quelques utilisateurs nécessitait d'écrire des mutations manuellement.

La nouvelle page **Plafonds de crédit** vous permet de définir le plafond fixe qui s'applique à chaque utilisateur par défaut, et d'ajouter des remplacements par utilisateur pour des utilisateurs individuels via un sélecteur avec recherche. Cette page est disponible dans **Crédits Gitlab** pour les propriétaires de groupes sur GitLab.com et les administrateurs sur GitLab Self-Managed. Les mutations GraphQL fonctionnent toujours si vous préférez scripter les modifications de plafonds.
