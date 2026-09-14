---
title: "Approbation d'outil basée sur des modèles pour Agentic Chat"
offering: [ gitlab_com, self_managed, gitlab_dedicated]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../../user/gitlab_duo_chat/agentic_chat/#approve-tools-in-your-local-environment"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21850
categories: [ 'Duo Agent Platform', 'Duo Chat', 'Editor Extensions' ]
weight: 50
---

<!-- categories: Duo Agent Platform, Duo Chat, Editor Extensions -->

Auparavant, lorsqu'Agentic Chat vous demandait d'approuver une invocation d'outil, vous pouviez l'approuver une fois ou approuver l'appel d'outil avec ces arguments pour le reste de la session. Des arguments différents nécessitaient une approbation supplémentaire.

Les workflows qui répétaient des commandes similaires, comme une série d'opérations `git`, vous forçaient à traiter un flux de messages pratiquement identiques.

Vous pouvez désormais choisir une troisième option d'approbation, **Approve all uses of this tool for session**. Cette option approuve les invocations de l'outil pour le reste de la session chaque fois que les arguments correspondent au modèle approuvé.

Les approbations basées sur des modèles sont disponibles pour Agentic Chat dans l'interface utilisateur GitLab, GitLab Duo CLI, GitLab for VS Code et le plugin GitLab Duo pour les IDE JetBrains.
