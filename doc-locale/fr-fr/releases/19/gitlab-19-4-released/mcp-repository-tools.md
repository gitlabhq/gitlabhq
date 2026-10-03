---
title: Outils de dépôt du serveur MCP
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

Les nouveaux outils de dépôt permettent aux agents de parcourir la structure d'un projet, de consulter l'historique de ses commits et de proposer des modifications via le serveur MCP GitLab :

- `list_repository_tree` explore l'arborescence des fichiers.
- `list_tags` énumère les références.
- `list_releases` inspecte les releases publiées.
- `get_commit` récupère les métadonnées, le diff ou les notes d'un commit.
- `list_commits` parcourt l'historique d'une branche page par page.
- `add_commit` effectue un commit d'une ou plusieurs actions sur des fichiers en un seul appel, éventuellement vers une nouvelle branche à partir d'une référence de départ ou d'un projet source spécifique.
- `fork_repository` duplique un projet, permettant ainsi à un agent de passer de l'exploration d'un dépôt amont à la proposition de modifications sans quitter son client.
