---
title: Outils de merge request du serveur MCP
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

Les outils de merge request permettent aux agents d'exécuter la boucle complète de merge request via le serveur MCP de GitLab :

- `save_merge_request` ouvre et met à jour une merge request.
- `get_merge_request` inspecte une merge request en profondeur, avec les nouvelles facettes de diffs, de conflits et d'approbations.
- `save_merge_request_review` laisse des commentaires de revue au niveau des lignes, avec des commentaires de diff groupés et un résumé en un seul appel.
- `accept_merge_request` fusionne une merge request une fois les vérifications passées, et peut également l'approuver ou annuler son approbation.
