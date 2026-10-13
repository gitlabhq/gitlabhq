---
title: Outils CI/CD du serveur MCP
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

De nouveaux outils CI/CD permettent aux agents de déclencher, d'inspecter et de contrôler les pipelines CI/CD depuis n'importe quel client MCP :

- `save_pipeline` exécute, relance ou annule un pipeline sans changer d'outil.
- `get_job` retourne les métadonnées du job ainsi que la trace du job, ce qui permet à un agent de lire le log d'un build échoué et de diagnostiquer le problème de manière autonome.

Auparavant, les agents n'avaient aucun moyen de déclencher ou d'inspecter des pipelines via MCP.
