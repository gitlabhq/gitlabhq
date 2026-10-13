---
title: Outils du serveur MCP GitLab issus de la communauté
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
co_create: true
documentation_link: "../../../user/model_context_protocol/mcp_server_tools/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248155
categories: [ Agent Tools ]
level: secondary
weight: 30
---

Des contributeurs de la communauté ont ajouté de nouveaux outils pour le serveur MCP GitLab. Les agents peuvent désormais utiliser `get_project` et `list_project_members` pour lire les métadonnées et les membres d'un projet, `list_branches` pour lister les branches d'un dépôt, et `list_merge_requests` pour lister les merge requests à l'échelle d'un groupe entier. `get_duo_session` récupère une session GitLab Duo afin que vous puissiez voir ce qu'une exécution précédente a effectué.

Ces outils sont fournis avec les autres nouveaux outils du serveur MCP GitLab dans la version 19.4 et fonctionnent sous la même gouvernance des outils, de sorte qu'un agent qui les utilise respecte les règles déjà définies par votre équipe.

Merci aux utilisateurs suivants pour ces contributions !

- [Dhairya Majmudar](https://gitlab.com/DhairyaMajmudar) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248155) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250316))
- [Giannis Kepas](https://gitlab.com/gkepas) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250430) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251379))
- [Mahaveer A](https://gitlab.com/Mahaveer1013) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252619))
