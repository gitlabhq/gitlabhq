---
title: Gouvernance des outils du serveur MCP GitLab
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
tier: [ Free, Premium, Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../user/ai-governance/tool-governance"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/628391
categories: [ AI Governance ]
level: primary
weight: 50
---

Auparavant, vous ne pouviez appliquer les règles de [gouvernance des outils des agents d'IA](../../../user/ai-governance/tool-governance.md) qu'aux outils internes de la plateforme GitLab Duo Agent Platform. Les outils disponibles à la fois pour la plateforme GitLab Duo Agent Platform et pour les agents tiers via le serveur MCP GitLab suivaient des règles fixes qui ne pouvaient pas être modifiées.

Vous pouvez désormais gérer les outils du serveur MCP GitLab depuis le même endroit que les outils internes de la plateforme GitLab Duo Agent Platform. Ils apparaissent aux côtés des outils internes dans les paramètres **GitLab Duo** de votre groupe et de votre projet, où vous pouvez définir un mode pour chaque outil :

- Les outils en lecture seule sont définis par défaut sur **Toujours autoriser**, afin que les consultations courantes s'exécutent sans interrompre votre équipe.
- Les outils d'écriture et de suppression sont définis par défaut sur **Toujours demander**, offrant aux relecteurs un point de contrôle avant qu'un agent d'IA n'effectue une modification.
