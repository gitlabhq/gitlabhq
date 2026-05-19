---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Explorez les agents et flux basés sur l'IA qui automatisent les tâches tout au long du cycle de vie du développement logiciel.
title: GitLab Duo Agent Platform
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- Available on [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduced as a [beta](../../policy/development_stages_support.md) in GitLab 18.2.
- For GitLab Duo Agent Platform on self-managed instances (both with [self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md) and cloud-connected GitLab models), [introduced](https://gitlab.com/groups/gitlab-org/-/epics/19213) in GitLab 18.4, as an [experiment](../../policy/development_stages_support.md#experiment) with a [feature flag](../../administration/feature_flags/_index.md) named `self_hosted_agent_platform`. Disabled by default.
- Feature flag `self_hosted_agent_platform` [enabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951) in GitLab 18.7.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.
- GitLab Duo Agent Platform and GitLab Credits supported on GitLab 18.8 and later.
- Feature flag `self_hosted_agent_platform` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218589) in GitLab 18.9.

{{< /history >}}

GitLab Duo Agent Platform est une solution native à l'IA qui intègre plusieurs
assistants intelligents (« agents »)
tout au long du cycle de vie du développement logiciel.

- Au lieu de suivre un workflow linéaire, collaborez de manière asynchrone avec des agents IA.
- Déléguez les tâches récurrentes — de la refactorisation du code et des analyses de sécurité à la recherche —
  à des agents IA spécialisés.

Pour commencer, consultez
[Premiers pas avec GitLab Duo Agent Platform](../get_started/get_started_agent_platform.md).

## Prérequis {#prerequisites}

Pour utiliser Agent Platform :

- Avoir [GitLab Duo activé](turn_on_off.md#turn-gitlab-duo-on-or-off).
- Si vous ne disposez pas de GitLab Duo Pro ou Enterprise,
  avoir [GitLab Duo Core activé](turn_on_off.md#turn-gitlab-duo-core-on-or-off) pour le groupe de niveau supérieur ou l'instance.
- Selon votre version de GitLab :
  - Dans GitLab 18.8 et versions ultérieures, avoir [Agent Platform activé](turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off).
  - Dans GitLab 18.7 et versions antérieures, avoir [les fonctionnalités bêta et expérimentales activées](turn_on_off.md#turn-on-beta-and-experimental-features).
- Pour GitLab Self-Managed, [configurer votre instance](../../administration/gitlab_duo/configure/gitlab_self_managed.md).
- Pour GitLab Duo Self-Hosted, [installer la passerelle d'IA](../../install/install_ai_gateway.md) avec le service Agent Platform.

Pour utiliser Agent Platform dans votre environnement local :

- Installez une extension d'éditeur et authentifiez-vous auprès de GitLab.
- Disposez d'un projet dans un [espace de noms de groupe](../namespace/_index.md).
- Disposez du rôle Développeur, Mainteneur ou Propriétaire.

## Fonctionnalités généralement disponibles {#generally-available-features}

Ces fonctionnalités sont généralement disponibles et consomment des [GitLab Credits](../../subscriptions/gitlab_credits.md) lors de leur utilisation.

Les fonctionnalités disponibles dans le niveau Free nécessitent l'achat de [GitLab Credits](../../subscriptions/gitlab_credits.md#for-the-free-tier).

| Fonctionnalité | Free | Premium | Ultimate |
|---------|---------|---------|---------|
| [GitLab Duo Chat (agentique)](../gitlab_duo_chat/agentic_chat.md) <br /> Répondez à des questions complexes et créez et modifiez des fichiers de manière autonome. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Code Suggestions](code_suggestions/_index.md) <br /> Obtenez des suggestions basées sur l'IA au fur et à mesure que vous écrivez du code. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Agents personnalisés](agents/custom.md) <br /> Créez des agents adaptés à votre équipe pour répondre à vos besoins de développement spécifiques. | {{< yes >}} |  {{< yes >}}  | {{< yes >}} |
| [Agents externes](agents/external.md) <br /> Connectez en toute sécurité des intégrations et outils tiers pour étendre les capacités d'Agent Platform. | {{< no >}} |  {{< yes >}}  | {{< yes >}} |
| [Planner Agent](agents/foundational_agents/planner.md) <br /> Planifiez, hiérarchisez et suivez le travail. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Data Analyst Agent](agents/foundational_agents/data_analyst.md) <br /> Analysez les données et générez des insights à partir de vos métriques de développement et données de projet. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Developer Flow](flows/foundational_flows/developer.md) <br /> Convertissez des tickets en merge requests. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Code Review Flow](flows/foundational_flows/code_review.md) <br /> Automatisez les tâches de revue de code et appliquez des normes de codage à l'ensemble de votre équipe. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Convert to GitLab CI/CD Flow](flows/foundational_flows/convert_to_gitlab_ci.md) <br /> Convertissez les pipelines CI/CD existants au format GitLab CI/CD. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Fix CI/CD Pipeline Flow](flows/foundational_flows/fix_pipeline.md) <br /> Diagnostiquez et corrigez automatiquement les pipelines CI/CD défaillants. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Software Development Flow](flows/foundational_flows/software_development.md) <br /> Créez un plan complet et multi-étapes avant de l'exécuter. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Clients MCP](../gitlab_duo/model_context_protocol/mcp_clients.md) <br /> Accédez aux ressources et outils GitLab depuis n'importe quel client IA ou extension d'IDE compatible MCP. <sup>1</sup> | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [SAST False Positive Detection Flow](flows/foundational_flows/sast_false_positive_detection.md) <br /> Identifiez et filtrez automatiquement les faux positifs dans les analyses de sécurité SAST. | {{< no >}} | {{< no >}}  | {{< yes >}} |
| [SAST Vulnerability Resolution Flow](flows/foundational_flows/agentic_sast_vulnerability_resolution.md) <br /> Générez automatiquement des correctifs et des étapes de remédiation pour les vulnérabilités SAST. | {{< no >}} | {{< no >}}  | {{< yes >}} |
| [Security Analyst Agent](agents/foundational_agents/security_analyst_agent.md) <br /> Automatisez les tâches de sécurité répétitives : triez les tickets, analysez les vulnérabilités et générez des correctifs. | {{< no >}} | {{< no >}}  | {{< yes >}} |

**Notes de bas de page** :

1. Les clients MCP ne consomment pas directement de crédits. Toutefois, toute utilisation d'Agent Platform, telle que les requêtes de modèle effectuées via un client MCP, peut consommer des crédits.

## Fonctionnalités bêta et expérimentales {#beta-and-experiment-features}

Ces fonctionnalités sont en version bêta ou expérimentale et ne consomment pas de GitLab Credits.

Pour les [utilisateurs sur le niveau Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), les fonctionnalités bêta et expérimentales ne consomment pas de crédits,
mais vous devez disposer de crédits dans votre pool d'engagement mensuel pour y accéder.

> [!warning]
> Lorsqu'une fonctionnalité devient généralement disponible, son utilisation commence à consommer des GitLab Credits sur toutes les versions de GitLab et sur toutes les offres.
> Les fonctionnalités bêta peuvent passer à la disponibilité générale avec facturation à l'usage à tout moment.

| Fonctionnalité | Free | Premium | Ultimate |
|---------|---|---|---|
| [Flows personnalisés](flows/custom.md) <br /> Combinez plusieurs agents pour résoudre vos problèmes métier. | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [Serveur MCP](../gitlab_duo/model_context_protocol/mcp_server.md) <br /> Connectez en toute sécurité des outils et applications IA à votre instance GitLab. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [CI Expert Agent](agents/foundational_agents/ci_expert_agent.md) <br /> Créez, déboguez et optimisez les pipelines GitLab CI/CD. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Serveurs MCP externes](../gitlab_duo/model_context_protocol/ai_catalog_mcp_servers.md) <br /> Connectez des agents personnalisés à des sources de données externes et à des services tiers via des serveurs MCP. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Knowledge Graph](../project/repository/knowledge_graph/_index.md) <br /> Créez des représentations structurées et interrogeables des dépôts de code pour alimenter les fonctionnalités IA. | {{< no >}} |{{< yes >}} | {{< yes >}} |
| [Résoudre les conflits de merge requests](../project/merge_requests/conflicts.md#resolve-conflicts-with-gitlab-duo) <br /> Analysez de manière autonome les conflits de merge requests, modifiez les fichiers en conflit et poussez un commit de résolution. | {{< no >}} | {{< yes >}} | {{< yes >}} |
