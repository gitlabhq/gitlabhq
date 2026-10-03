---
title: "Outils de projet et d'utilisateur du serveur MCP"
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

De nouveaux outils de projet et d'utilisateur donnent aux agents le contexte dont ils ont besoin pour cibler correctement les travaux via le serveur MCP GitLab :

- `list_projects` recherche et lit les détails du projet
- `get_user` recherche les détails de l'utilisateur pour les assignations et les mentions

Auparavant, les agents n'avaient aucun moyen de découvrir des informations sur les projets ou les utilisateurs via le serveur MCP GitLab.
