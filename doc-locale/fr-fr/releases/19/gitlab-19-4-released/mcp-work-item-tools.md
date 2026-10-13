---
title: "Outils d'éléments de travail du serveur MCP"
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

Le serveur MCP de GitLab expose désormais des outils d'éléments de travail, permettant aux agents et aux clients MCP de rechercher, lire, créer et mettre à jour des tickets, des epics, des tâches, des incidents, des objectifs et des résultats clés.

Utilisez `get_work_item` pour lire un élément individuel en détail, `list_work_items` pour effectuer une recherche dans un groupe ou un projet, et `save_work_item` pour créer ou mettre à jour n'importe quel type d'élément de travail.

Les tickets et les epics étant des types d'éléments de travail, `get_work_item` et `save_work_item` couvrent ce que font actuellement `get_issue` et `create_issue`.

`save_note` permet à un agent de commenter un élément de travail ou une merge request et de répondre dans un fil de discussion existant. L'introduction de cet outil renomme les outils existants `create_merge_request_note` et `create_workitem_note`.
