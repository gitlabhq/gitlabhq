---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Décrit le Model Context Protocol et son utilisation
title: Model Context Protocol
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version bêta

{{< /details >}}

Le Model Context Protocol (MCP) est un standard ouvert qui connecte les assistants IA aux outils et sources de données existants. Le MCP fonctionne comme un adaptateur universel. Au lieu de créer des connexions personnalisées distinctes pour chaque plateforme logicielle, vous pouvez utiliser un protocole standardisé unique pour la communication entre systèmes.

Par exemple, un assistant IA peut extraire des données clients de votre CRM, vérifier le statut d'un projet dans GitLab et consulter la documentation de votre wiki via le même protocole. Cette approche réduit la configuration nécessaire pour les équipes de développement et permet de créer des assistants IA plus puissants, dotés d'un accès au contexte dont ils ont besoin.

GitLab prend en charge le MCP de deux manières :

- [Clients MCP](mcp_clients.md) : connectez les fonctionnalités GitLab Duo, comme GitLab Duo Agentic Chat, à des serveurs MCP externes pour accéder aux données et aux outils d'autres systèmes et fournir une assistance plus complète.

- [Serveur MCP](../../model_context_protocol/mcp_server.md) : connectez des outils IA externes à votre instance GitLab. Les outils connectés disposent d'un accès sécurisé à vos projets, tickets, merge requests et autres données GitLab.

## Sujets connexes {#related-topics}

- [Premiers pas avec le MCP](https://modelcontextprotocol.io/docs/getting-started/intro)
