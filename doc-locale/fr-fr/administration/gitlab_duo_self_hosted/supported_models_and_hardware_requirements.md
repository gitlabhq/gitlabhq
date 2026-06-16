---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Modèles pris en charge et exigences matérielles.
title: Modèles et exigences matérielles
---

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/12972) dans GitLab 17.1 [avec un flag](../feature_flags/_index.md) nommé `ai_custom_model`. Désactivé par défaut.
- [Activé sur GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) dans GitLab 17.6.
- Modifié pour exiger le module complémentaire GitLab Duo dans GitLab 17.6 et versions ultérieures.
- Le feature flag `ai_custom_model` a été supprimé dans GitLab 17.8.
- Généralement disponible dans GitLab 17.9.
- Modifié pour inclure Premium dans GitLab 18.0.

{{< /history >}}

Vous pouvez intégrer des modèles de pointe de Mistral, Meta, Anthropic et OpenAI via votre plateforme de service préférée.

Vous pouvez utiliser :

- Les modèles pris en charge pour répondre à vos besoins de performance et cas d'utilisation spécifiques.
- Dans GitLab 18.3 et versions ultérieures, votre propre modèle compatible pour expérimenter des modèles au-delà des options officiellement prises en charge.
- Les modèles gérés par GitLab pour vous connecter aux modèles d'IA sans avoir à héberger votre propre infrastructure. Ces modèles sont entièrement gérés par GitLab.

## Modèles pris en charge {#supported-models}

Les modèles pris en charge par GitLab offrent différents niveaux de fonctionnalité pour les fonctionnalités GitLab Duo, selon la combinaison spécifique de modèle et de fonctionnalité.

- {{< icon name="check-circle-filled" >}} Fonctionnalité complète : Le modèle peut probablement gérer la fonctionnalité sans aucune perte de qualité.
- {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle : Le modèle prend en charge la fonctionnalité, mais il peut y avoir des compromis ou des limitations.
- {{< icon name="dash-circle" >}} Fonctionnalité limitée : Le modèle ne convient pas à cette fonctionnalité, ce qui entraîne probablement une perte de qualité significative ou des problèmes de performance. Les modèles dont la fonctionnalité est limitée pour une fonctionnalité ne bénéficieront pas du support GitLab pour cette fonctionnalité spécifique.

<!-- vale gitlab_base.Spelling = NO -->

| Famille de modèles | Modèle | Complétion de code | Génération de code | GitLab Duo Non-Agentic Chat | GitLab Duo Agent Platform |
|--------------|-------|-----------------|-----------------|---------------------------|---------------------------|
| Claude 4 | [Claude 4 Sonnet](https://www.anthropic.com/news/claude-4) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète |
| Claude 4 | [Claude 4.5 Sonnet](https://www.anthropic.com/news/claude-sonnet-4-5) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète |
| Claude 4 | [Claude 4.5 Haiku](https://www.anthropic.com/news/claude-haiku-4-5) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète |
| Claude 4 | [Claude 4.5 Opus](https://www.anthropic.com/news/claude-opus-4-5) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète |
| GPT | [GPT-4 Turbo](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle | {{< icon name="dash-circle" >}} Fonctionnalité limitée |
| GPT | [GPT-4o](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4o-and-gpt-4-turbo) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="dash-circle" >}} Fonctionnalité limitée |
| GPT | [GPT-4o-mini](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4o-and-gpt-4-turbo) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle | {{< icon name="dash-circle" >}} Fonctionnalité limitée |
| GPT | [GPT-5](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-5) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète |
| GPT | [GPT-5 Mini](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-5) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle |
| GPT | [GPT-5 Codex](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-5) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète |
| GPT | [GPT-5.1](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-51) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète |
| GPT | [GPT-5.2](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-52) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète |
| GPT | [GPT-oss-120B](https://huggingface.co/openai/gpt-oss-120b) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="dash-circle" >}} Fonctionnalité limitée |
| Mistral Devstral | [Devstral 2 123B](https://huggingface.co/mistralai/Devstral-2-123B-Instruct-2512) | {{< icon name="dash-circle" >}} Fonctionnalité limitée | {{< icon name="dash-circle" >}} Fonctionnalité limitée | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète |
| Mistral Codestral | [Codestral 22B v0.1](https://huggingface.co/mistralai/Codestral-22B-v0.1) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle | {{< icon name="dash-circle" >}} Fonctionnalité limitée |
| Mistral | [Mistral Small 24B Instruct 2506](https://huggingface.co/mistralai/Mistral-Small-3.2-24B-Instruct-2506) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="dash-circle" >}} Fonctionnalité limitée |
| GLM | [GLM-5.1-FP8](https://huggingface.co/zai-org/GLM-5.1-FP8) | {{< icon name="dash-circle" >}} Fonctionnalité limitée | {{< icon name="dash-circle" >}} Fonctionnalité limitée | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète |
| Kimi | [Kimi-K2.5](https://huggingface.co/moonshotai/Kimi-K2.5) | {{< icon name="dash-circle" >}} Fonctionnalité limitée | {{< icon name="dash-circle" >}} Fonctionnalité limitée | {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle | {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle |
| Kimi | [Kimi-K2.6](https://huggingface.co/moonshotai/Kimi-K2.6) | {{< icon name="dash-circle" >}} Fonctionnalité limitée | {{< icon name="dash-circle" >}} Fonctionnalité limitée | {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle | {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle |
| MiniMax | [MiniMax-M2.7](https://huggingface.co/MiniMaxAI/MiniMax-M2.7) | {{< icon name="dash-circle" >}} Fonctionnalité limitée | {{< icon name="dash-circle" >}} Fonctionnalité limitée | {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle | {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle |
| Llama | [Llama 3 8B](https://huggingface.co/meta-llama/Meta-Llama-3-8B-Instruct) | {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="dash-circle" >}} Fonctionnalité limitée | {{< icon name="dash-circle" >}} Fonctionnalité limitée |
| Llama | [Llama 3.1 8B](https://huggingface.co/meta-llama/Llama-3.1-8B-Instruct) | {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle | {{< icon name="dash-circle" >}} Fonctionnalité limitée |
| Llama | [Llama 3 70B](https://huggingface.co/meta-llama/Meta-Llama-3-70B-Instruct) | {{< icon name="check-circle-dashed" >}} Fonctionnalité partielle | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="dash-circle" >}} Fonctionnalité limitée | {{< icon name="dash-circle" >}} Fonctionnalité limitée |
| Llama | [Llama 3.1 70B](https://huggingface.co/meta-llama/Llama-3.1-70B-Instruct) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="dash-circle" >}} Fonctionnalité limitée |
| Llama | [Llama 3.3 70B](https://huggingface.co/meta-llama/Llama-3.3-70B-Instruct) | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="check-circle-filled" >}} Fonctionnalité complète | {{< icon name="dash-circle" >}} Fonctionnalité limitée |

### Modèles compatibles {#compatible-models}

{{< details >}}

- Statut : Bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/18556) dans GitLab 18.3 en tant que [bêta](../../policy/development_stages_support.md#beta).

{{< /history >}}

Vous pouvez utiliser vos propres modèles et plateformes compatibles avec GitLab Duo Agent Platform et les fonctionnalités GitLab Duo. Pour les modèles compatibles non inclus dans les familles de modèles prises en charge, utilisez la famille de modèles générale. Cela inclut les modèles que vous hébergez vous-même (par exemple, via vLLM ou LiteLLM), à condition qu'ils soient exposés via un point de terminaison `/v1` compatible avec l'API OpenAI.

Les modèles compatibles sont exclus de la définition des modèles intégrés par les clients dans les [conditions d'utilisation des fonctionnalités d'IA](https://handbook.gitlab.com/handbook/legal/ai-functionality-terms/). Les modèles et plateformes compatibles doivent respecter la spécification de l'API OpenAI. Les modèles et plateformes précédemment marqués comme expérimentaux ou bêta sont désormais considérés comme des modèles compatibles.

Cette fonctionnalité est en bêta et est donc susceptible d'être modifiée au fur et à mesure que nous recueillons des retours et améliorons l'intégration :

- GitLab ne fournit pas de support technique pour les problèmes spécifiques au modèle ou à la plateforme que vous avez choisi.
- Il n'est pas garanti que toutes les fonctionnalités d'Agent Platform ou de GitLab Duo fonctionnent de manière optimale avec chaque modèle compatible.
- La qualité des réponses, la vitesse et les performances globales peuvent varier considérablement en fonction du modèle choisi.

#### GitLab Duo {#gitlab-duo}

| Famille de modèles   | Modèle |
|----------------|-------|
| Général        | Tout modèle compatible avec la [spécification de l'API OpenAI](https://platform.openai.com/docs/api-reference) |
| CodeGemma      | [CodeGemma 2b](https://huggingface.co/google/codegemma-2b) |
| CodeGemma      | [CodeGemma 7b-it](https://huggingface.co/google/codegemma-7b-it) |
| CodeGemma      | [CodeGemma 7b-code](https://huggingface.co/google/codegemma-7b) |
| Code Llama     | [Code-Llama 13b](https://huggingface.co/meta-llama/CodeLlama-13b-Instruct-hf) |
| DeepSeek Coder | [DeepSeek Coder 33b Instruct](https://huggingface.co/deepseek-ai/deepseek-coder-33b-instruct) |
| DeepSeek Coder | [DeepSeek Coder 33b Base](https://huggingface.co/deepseek-ai/deepseek-coder-33b-base) |

<!-- vale gitlab_base.Spelling = YES -->

#### GitLab Duo Agent Platform {#gitlab-duo-agent-platform}

| Famille de modèles   | Modèle |
|----------------|-------|
| Général        | Tout modèle compatible avec la [spécification de l'API OpenAI](https://platform.openai.com/docs/api-reference) |
| Gemini         | [Gemini 3.1 Pro](https://deepmind.google/models/gemini/pro/) |
| Gemini         | [Gemini 3.0 Flash](https://deepmind.google/models/gemini/flash/) |
| Gemma 4        | [Gemma-4-31B-IT](https://huggingface.co/google/gemma-4-31B-it) |
| Qwen 3.6       | [Qwen3.6-35B-A3B](https://huggingface.co/Qwen/Qwen3.6-35B-A3B) |

<!-- vale gitlab_base.Spelling = YES -->

## Modèles gérés par GitLab {#gitlab-managed-models}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/17192) dans GitLab 18.3 en tant que fonctionnalité [bêta](../../policy/development_stages_support.md#beta), avec un [feature flag](../feature_flags/_index.md) nommé `ai_self_hosted_vendored_features`. Désactivé par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214030) dans GitLab 18.7
- Le feature flag `ai_self_hosted_vendored_features` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218595) dans GitLab 18.9.

{{< /history >}}

Les modèles gérés par GitLab s'intègrent à l'infrastructure AI Gateway hébergée par GitLab pour fournir l'accès aux modèles d'IA sélectionnés et mis à disposition par GitLab. Au lieu d'utiliser vos propres modèles auto-hébergés, vous pouvez choisir d'utiliser les modèles gérés par GitLab pour des fonctionnalités spécifiques de GitLab Duo.

Pour choisir quelles fonctionnalités utilisent les modèles gérés par GitLab, consultez [sélectionner un modèle géré par GitLab pour une fonctionnalité](configure_duo_features.md#select-a-gitlab-managed-model-for-a-feature).

Lorsqu'elle est activée pour une fonctionnalité spécifique :

- Tous les appels vers ces fonctionnalités configurées avec un modèle géré par GitLab utilisent l'AI Gateway hébergé par GitLab, et non l'AI Gateway auto-hébergé.
- Aucun journal détaillé n'est généré dans l'AI Gateway hébergé par GitLab, même lorsque [les journaux d'IA sont activés](logging.md#turn-on-data-collection-for-gitlab-duo). Cela permet d'éviter les fuites involontaires d'informations sensibles.

## Exigences matérielles {#hardware-requirements}

Les spécifications matérielles suivantes représentent les exigences minimales pour exécuter GitLab Duo Self-Hosted sur site. Les exigences varient considérablement en fonction de la taille du modèle et de l'utilisation prévue :

### Exigences système de base {#base-system-requirements}

- **CPU** :
  - Minimum : 8 cœurs (16 fils d'exécution)
  - Recommandé : 16+ cœurs pour les environnements de production
- **RAM** :
  - Minimum : 32 Go
  - Recommandé : 64 Go pour la plupart des modèles
- **Stockage** :
  - SSD avec un espace suffisant pour les poids du modèle et les données.

### Exigences GPU par taille de modèle {#gpu-requirements-by-model-size}

| Taille du modèle                                 | Configuration GPU minimale | VRAM minimale requise |
|--------------------------------------------|---------------------------|-----------------------|
| Modèles 7B<br>(par exemple, Mistral 7B)     | 1x NVIDIA A100 (40 Go)    | 35 Go                 |
| Modèles 22B<br>(par exemple, Codestral 22B) | 2x NVIDIA A100 (80 Go)    | 110 Go                |
| Mixtral 8x7B                               | 2x NVIDIA A100 (80 Go)    | 220 Go                |
| Mixtral 8x22B                              | 8x NVIDIA A100 (80 Go)    | 526 Go                |

Utilisez [l'utilitaire de mémoire de Hugging Face](https://huggingface.co/spaces/hf-accelerate/model-memory-usage) pour vérifier les exigences en mémoire.

### Temps de réponse par taille de modèle et GPU {#response-time-by-model-size-and-gpu}

#### Machine de petite taille {#small-machine}

Avec un `a2-highgpu-2g` (2x NVIDIA A100 40 Go - 150 Go vRAM) ou équivalent :

| Nom du modèle               | Nombre de requêtes | Temps moyen par requête (s) | Nombre moyen de tokens dans la réponse | Nombre moyen de tokens par seconde par requête | Temps total pour les requêtes | TPS total |
|--------------------------|--------------------|------------------------------|----------------------------|---------------------------------------|-------------------------|-----------|
| Mistral-7B-Instruct-v0.3 | 1                  | 7.09                         | 717.0                      | 101.19                                | 7.09                    | 101.17    |
| Mistral-7B-Instruct-v0.3 | 10                 | 8.41                         | 764.2                      | 90.35                                 | 13.70                   | 557.80    |
| Mistral-7B-Instruct-v0.3 | 100                | 13.97                        | 693.23                     | 49.17                                 | 20.81                   | 3331.59   |

#### Machine de taille moyenne {#medium-machine}

Avec un `a2-ultragpu-4g` (4x NVIDIA A100 40 Go - 340 Go vRAM) sur GCP ou équivalent :

| Nom du modèle                 | Nombre de requêtes | Temps moyen par requête (s) | Nombre moyen de tokens dans la réponse | Nombre moyen de tokens par seconde par requête | Temps total pour les requêtes | TPS total |
|----------------------------|--------------------|------------------------------|----------------------------|---------------------------------------|-------------------------|-----------|
| Mistral-7B-Instruct-v0.3   | 1                  | 3.80                         | 499.0                      | 131.25                                | 3.80                    | 131.23    |
| Mistral-7B-Instruct-v0.3   | 10                 | 6.00                         | 740.6                      | 122.85                                | 8.19                    | 904.22    |
| Mistral-7B-Instruct-v0.3   | 100                | 11.71                        | 695.71                     | 59.06                                 | 15.54                   | 4477.34   |
| Mixtral-8x7B-Instruct-v0.1 | 1                  | 6.50                         | 400.0                      | 61.55                                 | 6.50                    | 61.53     |
| Mixtral-8x7B-Instruct-v0.1 | 10                 | 16.58                        | 768.9                      | 40.33                                 | 32.56                   | 236.13    |
| Mixtral-8x7B-Instruct-v0.1 | 100                | 25.90                        | 767.38                     | 26.87                                 | 55.57                   | 1380.68   |

#### Machine de grande taille {#large-machine}

Avec un `a2-ultragpu-8g` (8 x NVIDIA A100 80 Go - 1360 Go vRAM) sur GCP ou équivalent :

| Nom du modèle                  | Nombre de requêtes | Temps moyen par requête (s) | Nombre moyen de tokens dans la réponse | Nombre moyen de tokens par seconde par requête | Temps total pour les requêtes (s) | TPS total |
|-----------------------------|--------------------|------------------------------|----------------------------|---------------------------------------|-----------------------------|-----------|
| Mistral-7B-Instruct-v0.3    | 1                  | 3.23                         | 479.0                      | 148.41                                | 3.22                        | 148.36    |
| Mistral-7B-Instruct-v0.3    | 10                 | 4.95                         | 678.3                      | 135.98                                | 6.85                        | 989.11    |
| Mistral-7B-Instruct-v0.3    | 100                | 10.14                        | 713.27                     | 69.63                                 | 13.96                       | 5108.75   |
| Mixtral-8x7B-Instruct-v0.1  | 1                  | 6.08                         | 709.0                      | 116.69                                | 6.07                        | 116.64    |
| Mixtral-8x7B-Instruct-v0.1  | 10                 | 9.95                         | 645.0                      | 63.68                                 | 13.40                       | 481.06    |
| Mixtral-8x7B-Instruct-v0.1  | 100                | 13.83                        | 585.01                     | 41.80                                 | 20.38                       | 2869.12   |
| Mixtral-8x22B-Instruct-v0.1 | 1                  | 14.39                        | 828.0                      | 57.56                                 | 14.38                       | 57.55     |
| Mixtral-8x22B-Instruct-v0.1 | 10                 | 20.57                        | 629.7                      | 30.24                                 | 28.02                       | 224.71    |
| Mixtral-8x22B-Instruct-v0.1 | 100                | 27.58                        | 592.49                     | 21.34                                 | 36.80                       | 1609.85   |

### Exigences matérielles de l'AI Gateway {#ai-gateway-hardware-requirements}

Pour obtenir des recommandations sur le matériel de l'AI Gateway, consultez les [recommandations de mise à l'échelle de l'AI Gateway](../../install/install_ai_gateway.md#scaling-recommendations).
