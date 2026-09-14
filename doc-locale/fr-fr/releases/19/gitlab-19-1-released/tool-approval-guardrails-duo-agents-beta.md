---
title: "Garde-fous d'approbation des outils pour les agents d'IA GitLab Duo (version bêta)"
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../user/duo_agent_platform/agents/tool-governance/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22381
categories: [ AI Governance ]
level: primary
---

<!-- categories: AI Governance -->

Les administrateurs peuvent désormais configurer des politiques d'approbation au niveau des outils pour les agents d'IA GitLab Duo, soumettant les actions sensibles à une approbation humaine au moment de l'exécution.

Auparavant, une fois qu'un agent d'IA était approuvé pour un projet, il pouvait invoquer n'importe lequel de ses outils sans révision supplémentaire, y compris les opérations d'écriture et les opérations destructives. Désormais, vous pouvez définir des règles pour les groupes et les projets qui associent chaque outil à l'un des trois modes suivants :

- Allow (exécution silencieuse).
- Ask (nécessite une approbation humaine).
- Deny (blocage total).

Lorsqu'un agent d'IA appelle un outil en mode « ask », l'utilisateur est invité à confirmer via une carte d'approbation intégrée avant que l'exécution ne se poursuive.

Cette version bêta de la release inclut Agentic Chat, l'IDE et les flows, et émet des événements d'audit pour chaque décision d'approbation.
