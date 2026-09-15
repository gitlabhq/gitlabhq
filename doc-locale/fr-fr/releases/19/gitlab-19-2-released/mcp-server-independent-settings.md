---
title: "Activer le serveur MCP indépendamment de GitLab Duo Agent Platform"
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/590729
categories: [ AI Agents ]
level: secondary
weight: 50
---

Pour vous offrir un contrôle plus précis sur la façon dont les outils externes se connectent à votre instance ou groupe GitLab, vous pouvez désormais activer ou désactiver le serveur MCP GitLab indépendamment des paramètres de GitLab Duo Agent Platform.

Auparavant, le serveur MCP GitLab et GitLab Duo Agent Platform partageaient le même paramètre d'activation et de désactivation, ce qui ne vous permettait pas d'activer le serveur MCP sans activer également les fonctionnalités de GitLab Duo Agent Platform. Vous pouvez désormais autoriser d'autres outils à accéder à GitLab en tant que serveur MCP sans activer GitLab Duo Agent Platform, ou garder le serveur MCP GitLab désactivé tout en utilisant les fonctionnalités de GitLab Duo Agent Platform.
