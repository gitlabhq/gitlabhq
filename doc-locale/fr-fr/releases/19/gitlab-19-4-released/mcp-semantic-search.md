---
title: Outil de recherche sémantique du serveur MCP
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250372
categories: [ Agent Tools ]
level: secondary
weight: 50
---

`semantic_code_search` est désormais `semantic_search`. L'outil recherche du code par signification plutôt que par symbole exact ou nom de fichier, ce qui est inchangé par rapport aux releases précédentes. Le renommage ajoute un paramètre `scope` afin que des types de contenu indexés supplémentaires puissent être intégrés au même outil dans les futures releases. Actuellement, `scope` n'accepte que `code`.

Merci à [arun kumar](https://gitlab.com/arunsdev) pour cette contribution !
