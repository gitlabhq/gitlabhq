---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez les agents d'IA et les flows alimentés par l'IA qui automatisent les tâches tout au long du cycle de vie du développement logiciel."
title: GitLab Duo Agent Platform
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- LLM :  Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduit en tant que [bêta](../../policy/development_stages_support.md) dans GitLab 18.2.
- Pour GitLab Duo Agent Platform sur les instances auto-gérées (aussi bien avec les [modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md) que les modèles GitLab connectés au cloud), [introduit](https://gitlab.com/groups/gitlab-org/-/epics/19213) dans GitLab 18.4, en tant qu'[expérience](../../policy/development_stages_support.md#experiment) avec un [feature flag](../../administration/feature_flags/_index.md) nommé `self_hosted_agent_platform`. Désactivé par défaut.
- Le feature flag `self_hosted_agent_platform` a été [activé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951) dans GitLab 18.7.
- [Disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) dans GitLab 18.8.
- GitLab Duo Agent Platform et GitLab Credits sont pris en charge sur GitLab 18.8 et versions ultérieures.
- Le feature flag `self_hosted_agent_platform` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218589) dans GitLab 18.9.

{{< /history >}}

GitLab Duo Agent Platform est une solution native d'IA qui intègre plusieurs assistants intelligents (« agents d'IA ») tout au long du cycle de vie du développement logiciel.

- Au lieu de suivre un flux de travail linéaire, collaborez de manière asynchrone avec des agents d'IA.
- Déléguez les tâches courantes, du refactoring de code et des analyses de sécurité à la recherche, à des agents d'IA spécialisés.

Pour commencer, consultez [Démarrer avec GitLab Duo Agent Platform](../get_started/get_started_agent_platform.md).

## Prérequis {#prerequisites}

Pour utiliser l'Agent Platform :

- Avoir [GitLab Duo activé](turn_on_off.md#turn-gitlab-duo-on-or-off).
- Si vous ne disposez pas de GitLab Duo Pro ou Enterprise, avoir [GitLab Duo Core activé](turn_on_off.md#turn-gitlab-duo-core-on-or-off) pour le groupe principal ou l'instance.
- En fonction de votre version de GitLab :
  - Dans GitLab 18.8 et versions ultérieures, avoir l'[Agent Platform activée](turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off).
  - Dans GitLab 18.7 et versions antérieures, avoir les [fonctionnalités bêta et expérimentales activées](turn_on_off.md#turn-on-beta-and-experimental-features).
- Pour GitLab Self-Managed, [configurer votre instance](../../administration/gitlab_duo/configure/gitlab_self_managed.md).
- Pour GitLab Duo Self-Hosted, [installer l'AI Gateway](../../install/install_ai_gateway.md) avec le service Agent Platform.

Pour utiliser l'Agent Platform dans votre environnement local :

- Installez une extension d'éditeur et authentifiez-vous avec GitLab.
- Disposer d'un projet dans un [espace de nommage de groupe](../namespace/_index.md).
- Avoir le rôle Developer, Maintainer ou Owner.

## Fonctionnalités en disponibilité générale {#generally-available-features}

Ces fonctionnalités sont en disponibilité générale et consomment des [GitLab Credits](../../subscriptions/gitlab_credits.md) lors de leur utilisation.

Les fonctionnalités disponibles sur le niveau Free pour les clients GitLab.com nécessitent l'achat de [GitLab Credits](../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom).

| Fonctionnalité | Free | Premium | Ultimate |
|---------|---------|---------|---------|
| [GitLab Duo Chat (agentique)](../gitlab_duo_chat/agentic_chat.md) <br /> Répondez à des questions complexes et créez et modifiez des fichiers de manière autonome. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Code Suggestions](code_suggestions/_index.md) <br /> Obtenez des suggestions alimentées par l'IA pendant que vous écrivez du code. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Agents personnalisés](agents/custom.md) <br /> Créez des agents d'IA spécifiques à votre équipe pour vos besoins de développement uniques. | {{< yes >}} |  {{< yes >}}  | {{< yes >}} |
| [Agents externes](agents/external.md) <br /> Connectez en toute sécurité des intégrations et des outils tiers pour étendre les capacités de l'Agent Platform. | {{< no >}} |  {{< yes >}}  | {{< yes >}} |
| [agent Planner](agents/foundational_agents/planner.md) <br /> Planifiez, priorisez et suivez le travail. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [agent Data Analyst](agents/foundational_agents/data_analyst.md) <br /> Analysez les données et générez des insights à partir de vos métriques de développement et des données de votre projet. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [flow Developer](flows/foundational_flows/developer.md) <br /> Convertissez des tickets en merge requests. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [flow Code Review](flows/foundational_flows/code_review.md) <br /> Automatisez les tâches de revue de code et appliquez les normes de codage au sein de votre équipe. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [flow Convert to GitLab CI/CD](flows/foundational_flows/convert_to_gitlab_ci.md) <br /> Convertissez les pipelines CI/CD existants au format GitLab CI/CD. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [flow Fix CI/CD Pipeline](flows/foundational_flows/fix_pipeline.md) <br /> Diagnostiquez et corrigez automatiquement les pipelines CI/CD en échec. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [flow Software Development](flows/foundational_flows/software_development.md) <br /> Créez un plan complet et multi-étapes avant de l'exécuter. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Clients MCP](../gitlab_duo/model_context_protocol/mcp_clients.md) <br /> Accédez aux ressources et aux outils GitLab depuis n'importe quel client IA ou extension IDE compatible MCP. <sup>1</sup> | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [flow SAST False Positive Detection](flows/foundational_flows/sast_false_positive_detection.md) <br /> Identifiez et filtrez automatiquement les faux positifs dans les analyses de sécurité SAST. | {{< no >}} | {{< no >}}  | {{< yes >}} |
| [flow SAST Vulnerability Resolution](flows/foundational_flows/agentic_sast_vulnerability_resolution.md) <br /> Générez automatiquement des corrections et des étapes de remédiation pour les vulnérabilités SAST. | {{< no >}} | {{< no >}}  | {{< yes >}} |
| [agent Security Analyst](agents/foundational_agents/security_analyst_agent.md) <br /> Automatisez les tâches de sécurité répétitives :  Triez les tickets, analysez les vulnérabilités et générez des corrections. | {{< no >}} | {{< no >}}  | {{< yes >}} |

**Footnotes** :

1. Les clients MCP ne consomment pas de crédits directement. Cependant, toute utilisation de l'Agent Platform, comme les requêtes de modèles effectuées via un client MCP, peut consommer des crédits.

## Fonctionnalités bêta et expérimentales {#beta-and-experiment-features}

Ces fonctionnalités sont soit en bêta, soit en expérimentation et ne consomment pas de GitLab Credits.

Pour les [utilisateurs GitLab.com sur le niveau Free](../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom), les fonctionnalités bêta et expérimentales ne consomment pas de crédits, mais vous avez besoin de crédits dans votre pool d'engagement mensuel pour y accéder.

> [!warning]
> Lorsqu'une fonctionnalité devient généralement disponible, son utilisation commence à consommer des GitLab Credits sur toutes les versions de GitLab et sur toutes les offres. Les fonctionnalités bêta peuvent passer en disponibilité générale avec facturation à l'utilisation à tout moment.

| Fonctionnalité | Free | Premium | Ultimate |
|---------|---|---|---|
| [Flows personnalisés](flows/custom.md) <br /> Combinez plusieurs agents d'IA pour résoudre vos problèmes métier. | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Serveur MCP](../gitlab_duo/model_context_protocol/mcp_server.md) <br /> Connectez en toute sécurité des outils et des applications d'IA à votre instance GitLab. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [agent CI Expert](agents/foundational_agents/ci_expert_agent.md) <br /> Créez, déboguez et optimisez les pipelines CI/CD GitLab. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Serveurs MCP externes](../gitlab_duo/model_context_protocol/ai_catalog_mcp_servers.md) <br /> Connectez des agents personnalisés à des sources de données externes et à des services tiers à l'aide de serveurs MCP. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Graphe de connaissances](../project/repository/knowledge_graph/_index.md) <br /> Créez des représentations structurées et interrogeables des dépôts de code pour alimenter les fonctionnalités d'IA. | {{< no >}} |{{< yes >}} | {{< yes >}} |
