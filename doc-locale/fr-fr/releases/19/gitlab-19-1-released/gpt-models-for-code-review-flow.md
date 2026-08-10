---
title: Modèles GPT pour le flow Code Review
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../../user/duo_agent_platform/model_selection/#supported-models"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/598322
categories: [ Duo Agent Platform, Duo Code Review ]
level: secondary
---

<!-- categories: Duo Agent Platform, Duo Code Review -->

Dans les versions précédentes de GitLab, le flow Code Review ne prenait en charge que les modèles Anthropic Claude. Les équipes ne pouvant pas utiliser les modèles Anthropic en raison de contraintes contractuelles, de politiques ou d'approvisionnement n'avaient aucun moyen d'exécuter le flow Code Review.

Vous pouvez désormais sélectionner GPT-5.2 ou GPT-5.3 Codex comme modèle pour le flow Code Review. Les propriétaires de groupe principal peuvent changer le modèle pour **Revue de code agentique** dans **Paramètres** > **GitLab Duo** > **Configurer les fonctionnalités**, sous **GitLab Duo Agent Platform**. Les modèles GPT sont hébergés via la passerelle d'IA GitLab, aucune configuration supplémentaire n'est donc requise.

Les deux modèles ont passé avec succès l'évaluation comparative réalisée sur le jeu de données de revue de code GitLab Duo, avec une qualité de revue comparable à celle du modèle par défaut Claude Sonnet 4.6 Vertex. Consultez l'[évaluation comparative de la revue de code](https://duo-review-bench-6f7260.gitlab.io/) pour connaître les résultats.
