---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Hébergez votre propre AI Gateway et vos modèles de langage.
title: Modèles auto-hébergés
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/12972) dans GitLab 17.1 [avec un flag](../feature_flags/_index.md) nommé `ai_custom_model`. Désactivé par défaut.
- [Activé sur GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) dans GitLab 17.6.
- Modifié pour nécessiter le module complémentaire GitLab Duo dans GitLab 17.6 et versions ultérieures.
- Le feature flag `ai_custom_model` a été supprimé dans GitLab 17.8.
- Généralement disponible dans GitLab 17.9.
- Modifié pour inclure Premium dans GitLab 18.0.
- Modifié pour exiger le module complémentaire GitLab Duo Agent Platform Self-Hosted pour les licences hors ligne dans GitLab 18.8.
- Modifié pour utiliser la facturation à l'usage des fonctionnalités dans GitLab Duo Agent Platform pour les licences en ligne dans GitLab 18.9.

{{< /history >}}

Hébergez votre propre infrastructure d'IA pour utiliser les fonctionnalités de GitLab Duo avec les LLM de votre choix. Utilisez une AI Gateway auto-hébergée pour conserver toutes les données de requête et de réponse dans votre propre environnement, éviter les appels d'API externes et gérer le cycle de vie complet des requêtes vers vos backends LLM.

## Options de déploiement {#deployment-options}

Vous pouvez utiliser des modèles auto-hébergés avec différentes options de déploiement.

### GitLab Duo Agent Platform {#gitlab-duo-agent-platform}

Utilisez GitLab Duo Agent Platform Self-Hosted pour les modèles sur site ou les modèles hébergés dans un cloud privé dans GitLab Duo Agent Platform.

Pour les clients disposant d'une licence hors ligne, la facturation utilise un contrat de licence Enterprise pour GitLab Duo, et vous devez disposer du module complémentaire [GitLab Duo Agent Platform Self-Hosted](../../subscriptions/subscription-add-ons.md#gitlab-duo-agent-platform-self-hosted).

Pour les clients disposant d'une licence en ligne, la facturation est [basée sur l'usage](../../subscriptions/gitlab_credits.md). Vous pouvez également utiliser des modèles gérés par GitLab dans un déploiement hybride.

### GitLab Duo {#gitlab-duo}

GitLab Duo Self-Hosted s'adresse aux clients disposant de GitLab Duo Enterprise qui utilisent les fonctionnalités de GitLab Duo. Vous pouvez utiliser :

- Des modèles sur site ou des modèles hébergés dans un cloud privé
- Des modèles gérés par GitLab dans un déploiement hybride

Cette option utilise une tarification basée sur les sièges.

### Versions et statut des fonctionnalités {#feature-versions-and-status}

Le tableau suivant répertorie :

- La version de GitLab requise pour utiliser la fonctionnalité.
- Le statut de la fonctionnalité. Le statut d'une fonctionnalité dans le déploiement peut différer du statut indiqué dans la fonctionnalité.

Pour utiliser les fonctionnalités de GitLab Duo avec GitLab Duo Self-Hosted, vous devez disposer du module complémentaire GitLab Duo Enterprise. Cela s'applique même si vous pouvez utiliser ces fonctionnalités avec GitLab Duo Core ou GitLab Duo Pro lorsque GitLab héberge ces modèles et s'y connecte via l'[AI Gateway](../gitlab_duo/gateway.md) dans le cloud.

| Fonctionnalité                                                                                                                                | Version de GitLab          | Statut              |
|----------------------------------------------------------------------------------------------------------------------------------------|-------------------------|---------------------|
| [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md)                                                                   | GitLab 18.8 et versions ultérieures   | Généralement disponible |
| **GitLab Duo** | | |
| [Code Suggestions](../../user/project/repository/code_suggestions/_index.md)                                                 | GitLab 17.9 et versions ultérieures   | Généralement disponible |
| [GitLab Duo Non-Agentic Chat](../../user/gitlab_duo_chat/_index.md)                                                                      | GitLab 17.9 et versions ultérieures   | Généralement disponible |
| [Code Explanation](../../user/gitlab_duo_chat/examples.md#explain-selected-code)                                                       | GitLab 17.9 et versions ultérieures   | Généralement disponible |
| [Test Generation](../../user/gitlab_duo_chat/examples.md#write-tests-in-the-ide)                                                       | GitLab 17.9 et versions ultérieures   | Généralement disponible |
| [Refactor Code](../../user/gitlab_duo_chat/examples.md#refactor-code-in-the-ide)                                                       | GitLab 17.9 et versions ultérieures   | Généralement disponible |
| [Fix Code](../../user/gitlab_duo_chat/examples.md#fix-code-in-the-ide)                                                                 | GitLab 17.9 et versions ultérieures   | Généralement disponible |
| [Code Review](../../user/project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)                           | GitLab 18.3 et versions ultérieures   | Généralement disponible |
| [Root Cause Analysis](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)                   | GitLab 17.10 et versions ultérieures  | Bêta                |
| [Vulnerability Explanation](../../user/application_security/analyze/duo.md)                                                            | GitLab 18.1.2 et versions ultérieures | Bêta                |
| [Merge Commit Message Generation](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)          | GitLab 18.1.2 et versions ultérieures | Bêta                |
| [Merge Request Summary](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | GitLab 18.1.2 et versions ultérieures | Bêta                |
| [Discussion Summary](../../user/discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat)                                | GitLab 18.1.2 et versions ultérieures | Bêta                |
| [GitLab Duo for the CLI](https://docs.gitlab.com/cli/)                                                                                 | GitLab 18.1.2 et versions ultérieures | Bêta                |
| [Vulnerability Resolution](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution)                         | GitLab 18.1.2 et versions ultérieures | Bêta                |
| [GitLab Duo and SDLC trends Dashboard](../../user/analytics/duo_and_sdlc_trends.md)                                                    | GitLab 17.9 et versions ultérieures   | Bêta                |
| [Code Review Summary](../../user/project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review)                              | GitLab 18.1.2 et versions ultérieures | Expérimentation          |

## Transmission des données {#data-transmission}

Les métadonnées de facturation suivantes sont envoyées à GitLab pour la facturation à l'usage dans un objet JSON :

- ID d'instance
- ID d'utilisateur
- Nombre d'appels
- Horodatage

Par exemple :

```json
{
  "InstanceId": "ccbb3949-9836-471c-b2nb-32a38e8cca99",
  "GlobalUserId": "KWDTe17sGSADiAzEGJ6IuL1D7RAzsXqa2wun3aX1YuA=",
  "Quantity": 1,
  "Timestamp": "2026-05-04 18:04:30.969000000"
}
```

Les données d'inférence, y compris les entrées de code, les invites de modèle et les réponses des modèles, ne quittent pas le réseau du client.

GitLab ne collecte pas d'informations sur le modèle ou le fournisseur de modèle utilisé par le client.

## Configurations de l'AI Gateway {#ai-gateway-configurations}

Après avoir choisi une option de produit, configurez la façon dont votre AI Gateway se connecte aux LLM :

- **AI Gateway et LLM auto-hébergés** : Utilisez votre propre AI Gateway et vos propres modèles pour un contrôle total de votre infrastructure d'IA.
- **Hybrid AI Gateway and model configuration** : Pour chaque fonctionnalité, utilisez soit votre AI Gateway auto-hébergée avec des modèles auto-hébergés, soit l'AI Gateway de GitLab.com avec des modèles gérés par GitLab.
- **GitLab.com AI Gateway with default GitLab external vendor LLMs** : Utilisez l'infrastructure d'IA gérée par GitLab.

| Configuration               | AI Gateway auto-hébergée                                                                    | Configuration hybride d'AI Gateway et de modèles                                                                                                        | AI Gateway de GitLab.com                    |
|-----------------------------|-------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------|
| Exigences en matière d'infrastructure | Nécessite d'héberger votre propre AI Gateway et vos propres modèles                                           | Nécessite d'héberger votre propre AI Gateway et vos propres modèles                                                                                                  | Aucune infrastructure supplémentaire nécessaire      |
| Options de modèles               | Choisissez parmi les [modèles auto-hébergés pris en charge](supported_models_and_hardware_requirements.md) | Choisissez parmi les [modèles auto-hébergés pris en charge](supported_models_and_hardware_requirements.md) ou les modèles gérés par GitLab pour chaque fonctionnalité de GitLab Duo | Utilise les modèles gérés par GitLab par défaut |
| Exigences réseau        | Peut fonctionner dans des réseaux totalement isolés                                                    | Nécessite une connectivité Internet pour les fonctionnalités de GitLab Duo qui utilisent des modèles gérés par GitLab                                                          | Nécessite une connectivité Internet           |
| Responsabilités            | Vous configurez votre infrastructure et assurez votre propre maintenance                               | Vous configurez votre infrastructure, assurez votre propre maintenance et choisissez les fonctionnalités qui utilisent les modèles gérés par GitLab et l'AI Gateway                    | GitLab se charge de la configuration et de la maintenance   |

### AI Gateway auto-hébergée et LLM {#self-hosted-ai-gateway-and-llms}

Dans une configuration entièrement auto-hébergée, vous déployez votre propre AI Gateway et utilisez uniquement les [LLM pris en charge](supported_models_and_hardware_requirements.md) dans votre infrastructure, sans utiliser l'infrastructure GitLab ni les modèles de fournisseurs d'IA. Cela vous donne un contrôle total sur vos données et votre sécurité.

> [!note]
> Cette configuration inclut uniquement les modèles configurés via votre AI Gateway auto-hébergée. Si vous utilisez des [modèles gérés par GitLab](configure_duo_features.md#select-a-gitlab-managed-model-for-a-feature) pour certaines fonctionnalités, ces fonctionnalités se connectent à l'AI Gateway hébergée par GitLab plutôt qu'à votre gateway auto-hébergée, ce qui en fait une configuration hybride plutôt qu'entièrement auto-hébergée.

Pendant que vous déployez votre propre AI Gateway, vous pouvez toujours utiliser des services LLM dans le cloud comme [AWS Bedrock](https://aws.amazon.com/bedrock/) ou [Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service) comme backend de modèle, qui continueront à se connecter via votre AI Gateway auto-hébergée.

Si vous disposez d'un environnement hors ligne avec des barrières physiques ou des politiques de sécurité qui empêchent ou limitent l'accès à Internet, ainsi que des contrôles LLM complets, vous devez utiliser cette configuration entièrement auto-hébergée.

Pour plus d'informations, voir :

- Le [schéma de configuration de l'AI Gateway auto-hébergée](configuration_types.md#self-hosted-ai-gateway).

### Configuration hybride d'AI Gateway et de modèles {#hybrid-ai-gateway-and-model-configuration}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/17192) dans GitLab 18.3 en tant que [bêta](../../policy/development_stages_support.md#beta) avec un [feature flag](../feature_flags/_index.md) nommé `ai_self_hosted_vendored_features`. Désactivé par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214030) dans GitLab 18.7
- Généralement disponible dans GitLab 18.9. Le feature flag `ai_self_hosted_vendored_features` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218595).

{{< /history >}}

Dans cette configuration hybride, vous déployez votre propre AI Gateway et des modèles auto-hébergés pour la plupart des fonctionnalités, mais vous configurez des fonctionnalités spécifiques pour utiliser des modèles gérés par GitLab. Lorsqu'une fonctionnalité est configurée pour utiliser un modèle géré par GitLab, les requêtes correspondantes sont envoyées à l'AI Gateway hébergée par GitLab plutôt qu'à votre AI Gateway auto-hébergée.

Cette option offre de la flexibilité en vous permettant de :

- Utiliser vos propres modèles auto-hébergés pour les fonctionnalités où vous souhaitez un contrôle total.
- Utiliser des modèles de fournisseurs gérés par GitLab pour des fonctionnalités spécifiques où vous préférez les modèles sélectionnés par GitLab.

> [!note]
> Lorsque des fonctionnalités sont configurées pour utiliser des modèles gérés par GitLab :
>
> - Tous les appels à ces fonctionnalités utilisent l'AI Gateway hébergée par GitLab, et non l'AI Gateway auto-hébergée.
> - Une connectivité Internet est requise pour ces fonctionnalités.
> - Il ne s'agit pas d'une configuration entièrement auto-hébergée ou isolée.

#### Modèles gérés par GitLab {#gitlab-managed-models}

Utilisez les modèles gérés par GitLab pour vous connecter à des modèles d'IA sans avoir besoin d'auto-héberger une infrastructure. Ces modèles sont entièrement gérés par GitLab.

Vous pouvez sélectionner le modèle GitLab par défaut à utiliser avec une fonctionnalité native d'IA. Pour le modèle par défaut, GitLab utilise le meilleur modèle en fonction de la disponibilité, de la qualité et de la fiabilité. Le modèle utilisé pour une fonctionnalité peut changer sans préavis.

Lorsque vous sélectionnez un modèle géré par GitLab spécifique, toutes les requêtes pour cette fonctionnalité utilisent exclusivement ce modèle. Si le modèle devient indisponible, les requêtes vers l'AI Gateway échouent et les utilisateurs ne peuvent pas utiliser cette fonctionnalité jusqu'à ce qu'un autre modèle soit sélectionné.

> [!note]
> Lorsque vous configurez une fonctionnalité pour utiliser des modèles gérés par GitLab :
>
> - Les appels à ces fonctionnalités utilisent l'AI Gateway hébergée par GitLab, et non l'AI Gateway auto-hébergée.
> - Une connectivité Internet est requise pour ces fonctionnalités.
> - La configuration n'est pas entièrement auto-hébergée ou isolée.

### AI Gateway de GitLab.com avec les LLM de fournisseurs externes GitLab par défaut {#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms}

{{< details >}}

- Module complémentaire : GitLab Duo Core, Pro ou Enterprise

{{< /details >}}

Si vous ne remplissez pas les critères d'utilisation de GitLab Duo Self-Hosted, vous pouvez utiliser l'AI Gateway de GitLab.com avec les LLM de fournisseurs externes GitLab par défaut.

L'AI Gateway de GitLab.com est l'offre Enterprise par défaut et n'est pas auto-hébergée. Dans cette configuration, vous connectez votre instance à l'AI Gateway hébergée par GitLab, qui s'intègre avec des fournisseurs LLM externes, notamment :

- [Anthropic](https://www.anthropic.com/)
- [Fireworks AI](https://fireworks.ai/)
- [Google Vertex](https://cloud.google.com/vertex-ai/)

Ces LLM communiquent via le GitLab Cloud Connector, offrant une solution d'IA prête à l'emploi sans avoir besoin d'infrastructure sur site.

Pour plus d'informations, consultez le [schéma de configuration de l'AI Gateway de GitLab.com](configuration_types.md#gitlabcom-ai-gateway).

Pour configurer cette infrastructure, consultez [comment configurer GitLab Duo sur une instance GitLab Self-Managed](../gitlab_duo/configure/gitlab_self_managed.md).

## Configurer une infrastructure privée {#set-up-a-private-infrastructure}

Si vous disposez d'une licence hors ligne, vous pouvez configurer une infrastructure entièrement privée :

1. Installez une infrastructure de service de grands modèles de langage (LLM).

   - GitLab prend en charge diverses plateformes pour servir et héberger vos LLM, telles que vLLM, AWS Bedrock et Azure OpenAI. Pour plus d'informations sur chaque plateforme, consultez la [documentation sur les plateformes LLM prises en charge](supported_llm_serving_platforms.md).

   - GitLab fournit une matrice de modèles pris en charge avec leurs fonctionnalités spécifiques et leurs exigences matérielles. Pour plus d'informations, consultez la [documentation sur les modèles pris en charge et les exigences matérielles](supported_models_and_hardware_requirements.md).

1. [Installez l'AI Gateway](../../install/install_ai_gateway.md) pour accéder aux fonctionnalités de GitLab Duo.
1. [Configurez votre instance GitLab](configure_duo_features.md) pour que les fonctionnalités utilisent des modèles auto-hébergés.
1. [Activez la journalisation](logging.md) pour suivre et gérer les performances de votre système.

## Sujets connexes {#related-topics}

- [Dépannage](troubleshooting.md)
- [Installer l'AI Gateway GitLab](../../install/install_ai_gateway.md)
- [Modèles pris en charge](supported_models_and_hardware_requirements.md)
- [Plateformes prises en charge](supported_llm_serving_platforms.md)
- [Tutoriel : Guide de déploiement AWS Bedrock BYOM](../../solutions/integrations/aws_bedrock_byom.md)
