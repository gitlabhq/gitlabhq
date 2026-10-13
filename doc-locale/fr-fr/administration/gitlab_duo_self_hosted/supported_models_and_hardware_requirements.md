---
stage: AI Platform
group: AI Model Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Modèles pris en charge et exigences matérielles.
title: Modèles et exigences matérielles
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated for Government

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/12972) dans GitLab 17.1 [avec le feature flag](../feature_flags/_index.md) `ai_custom_model`. Désactivé par défaut.
- [Activation sur GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/work_items/15176) dans GitLab 17.6.
- Module d’extension GitLab Duo rendu obligatoire à partir de GitLab 17.6.
- Suppression du feature flag `ai_custom_model` dans GitLab 17.8.
- Disponibilité générale dans GitLab 17.9.
- Disponibilité étendue à GitLab Premium dans GitLab 18.0.
- [Activation sur GitLab Dedicated for Government](https://gitlab.com/gitlab-org/gitlab/-/issues/569874) dans GitLab 18.5.

{{< /history >}}

Vous pouvez intégrer des modèles de pointe de Mistral, de Meta, d’Anthropic et d’OpenAI par l’intermédiaire de la plateforme de service de votre choix.

Vous pouvez utiliser :

- Des modèles pris en charge adaptés à vos besoins spécifiques en matière de performances et à vos cas d’utilisation.
- À partir de GitLab 18.3, votre propre modèle compatible pour tester des modèles qui ne figurent pas parmi les options officiellement prises en charge.
- Des modèles gérés par GitLab pour vous connecter à des modèles d’IA sans avoir à héberger votre propre infrastructure. Ces modèles sont entièrement gérés par GitLab.

## Modèles pris en charge {#supported-models}

Les modèles pris en charge par GitLab offrent différents niveaux de prise en charge des fonctionnalités GitLab Duo, selon la combinaison du modèle et de la fonctionnalité.

- {{< icon name="check-circle-filled" >}} Prise en charge complète : le modèle devrait pouvoir prendre en charge la fonctionnalité sans aucune perte de qualité.
- {{< icon name="check-circle-dashed" >}} Prise en charge partielle : le modèle prend en charge la fonctionnalité, mais cette prise en charge peut s’accompagner de compromis ou de limitations.
- {{< icon name="dash-circle" >}} Prise en charge limitée : le modèle n’est pas adapté à cette fonctionnalité et devrait entraîner une forte dégradation de la qualité ou des problèmes de performances. Les modèles qui ne prennent en charge une fonctionnalité que de manière limitée ne bénéficieront pas de l’assistance GitLab pour cette fonctionnalité en particulier.

<!-- vale gitlab_base.Spelling = NO -->

| Famille de modèles | Modèle | Complétion de code | Génération de code | GitLab Duo Non-Agentic Chat | GitLab Duo Agent Platform |
|--------------|-------|-----------------|-----------------|---------------------------|---------------------------|
| Claude 4 | [Claude 4 Sonnet](https://www.anthropic.com/news/claude-4) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète |
| Claude 4 | [Claude Haiku 4.5](https://www.anthropic.com/news/claude-haiku-4-5) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète |
| Claude 4 | [Claude Sonnet 4.6](https://www.anthropic.com/news/claude-sonnet-4-6) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète |
| Claude 4 | [Claude Opus 4.8](https://www.anthropic.com/news/claude-opus-4-8) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète |
| GPT | [GPT-4 Turbo](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-dashed" >}} Prise en charge partielle | {{< icon name="dash-circle" >}} Prise en charge limitée |
| GPT | [GPT-4o](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4o-and-gpt-4-turbo) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="dash-circle" >}} Prise en charge limitée |
| GPT | [GPT-4o-mini](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure#gpt-4o-and-gpt-4-turbo) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-dashed" >}} Prise en charge partielle | {{< icon name="dash-circle" >}} Prise en charge limitée |
| GPT | [GPT-5](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-5) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète |
| GPT | [GPT-5 Mini](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-5) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-dashed" >}} Prise en charge partielle |
| GPT | [GPT-5 Codex](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-5) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète |
| GPT | [GPT-5.1](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-51) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète |
| GPT | [GPT-5.2](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&pivots=azure-openai&tabs=global-standard-aoai%2Cglobal-standard#gpt-52) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète |
| GPT | [GPT-oss-120B](https://huggingface.co/openai/gpt-oss-120b) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="dash-circle" >}} Prise en charge limitée |
| Mistral Medium 3.5 | [Mistral Medium 3.5 128B](https://huggingface.co/mistralai/Mistral-Medium-3.5-128B) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète |
| Mistral Codestral | [Codestral 22B v0.1](https://huggingface.co/mistralai/Codestral-22B-v0.1) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-dashed" >}} Prise en charge partielle | {{< icon name="dash-circle" >}} Prise en charge limitée |
| Mistral | [Mistral Small 24B Instruct 2506](https://huggingface.co/mistralai/Mistral-Small-3.2-24B-Instruct-2506) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="dash-circle" >}} Prise en charge limitée |
| GLM | [GLM-5.1-FP8](https://huggingface.co/zai-org/GLM-5.1-FP8) | {{< icon name="dash-circle" >}} Prise en charge limitée | {{< icon name="dash-circle" >}} Prise en charge limitée | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète |
| Kimi | [Kimi-K2.5](https://huggingface.co/moonshotai/Kimi-K2.5) | {{< icon name="dash-circle" >}} Prise en charge limitée | {{< icon name="dash-circle" >}} Prise en charge limitée | {{< icon name="check-circle-dashed" >}} Prise en charge partielle | {{< icon name="check-circle-dashed" >}} Prise en charge partielle |
| Kimi | [Kimi-K2.6](https://huggingface.co/moonshotai/Kimi-K2.6) | {{< icon name="dash-circle" >}} Prise en charge limitée | {{< icon name="dash-circle" >}} Prise en charge limitée | {{< icon name="check-circle-dashed" >}} Prise en charge partielle | {{< icon name="check-circle-filled" >}} Prise en charge complète |
| MiniMax | [MiniMax-M2.7](https://huggingface.co/MiniMaxAI/MiniMax-M2.7) | {{< icon name="dash-circle" >}} Prise en charge limitée | {{< icon name="dash-circle" >}} Prise en charge limitée | {{< icon name="check-circle-dashed" >}} Prise en charge partielle | {{< icon name="check-circle-filled" >}} Prise en charge complète |
| Llama | [Llama 3 8B](https://huggingface.co/meta-llama/Meta-Llama-3-8B-Instruct) | {{< icon name="check-circle-dashed" >}} Prise en charge partielle | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="dash-circle" >}} Prise en charge limitée | {{< icon name="dash-circle" >}} Prise en charge limitée |
| Llama | [Llama 3.1 8B](https://huggingface.co/meta-llama/Llama-3.1-8B-Instruct) | {{< icon name="check-circle-dashed" >}} Prise en charge partielle | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-dashed" >}} Prise en charge partielle | {{< icon name="dash-circle" >}} Prise en charge limitée |
| Llama | [Llama 3 70B](https://huggingface.co/meta-llama/Meta-Llama-3-70B-Instruct) | {{< icon name="check-circle-dashed" >}} Prise en charge partielle | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="dash-circle" >}} Prise en charge limitée | {{< icon name="dash-circle" >}} Prise en charge limitée |
| Llama | [Llama 3.1 70B](https://huggingface.co/meta-llama/Llama-3.1-70B-Instruct) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="dash-circle" >}} Prise en charge limitée |
| Llama | [Llama 3.3 70B](https://huggingface.co/meta-llama/Llama-3.3-70B-Instruct) | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="check-circle-filled" >}} Prise en charge complète | {{< icon name="dash-circle" >}} Prise en charge limitée |

### Modèles compatibles {#compatible-models}

{{< details >}}

- Statut : version bêta

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/18556) dans GitLab 18.3 en tant que [version bêta](../../policy/development_stages_support.md#beta).

{{< /history >}}

Vous pouvez utiliser vos propres modèles compatibles ainsi que votre propre plateforme avec GitLab Duo Agent Platform et les fonctionnalités GitLab Duo. Pour les modèles compatibles qui ne figurent pas parmi les familles de modèles prises en charge, utilisez la famille de modèles générale. Cela comprend les modèles que vous hébergez vous-même, par exemple ceux que vous servez avec vLLM ou LiteLLM, à condition de les exposer par l’intermédiaire d’un point de terminaison `/v1` compatible avec l’API OpenAI.

Les modèles compatibles n’entrent pas dans la définition des modèles intégrés par les clients telle qu’elle figure dans les [conditions d'utilisation des fonctionnalités d'IA](https://handbook.gitlab.com/handbook/legal/ai-functionality-terms/). Les modèles et les plateformes compatibles doivent être conformes à la spécification de l’API OpenAI. Les modèles et les plateformes précédemment indiqués comme étant en version expérimentale ou en version bêta sont désormais considérés comme des modèles compatibles.

Cette fonctionnalité est en version bêta et est donc susceptible d’être modifiée à mesure que nous recueillons des commentaires et améliorons l’intégration :

- GitLab ne fournit aucune assistance technique pour les problèmes propres au modèle ou à la plateforme de votre choix.
- Le fonctionnement optimal de toutes les fonctionnalités de GitLab Duo Agent Platform ou de GitLab Duo n’est pas garanti avec chaque modèle compatible.
- La qualité des réponses, la vitesse et les performances globales peuvent varier considérablement selon le modèle choisi.

#### GitLab Duo {#gitlab-duo}

| Famille de modèles   | Modèle |
|----------------|-------|
| Générale        | Tout modèle compatible avec la [spécification de l'API OpenAI](https://platform.openai.com/docs/api-reference) |
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
| Générale        | Tout modèle compatible avec la [spécification de l'API OpenAI](https://platform.openai.com/docs/api-reference) |
| Gemini         | [Gemini 3.1 Pro](https://deepmind.google/models/gemini/pro/) |
| Gemini         | [Gemini 3.0 Flash](https://deepmind.google/models/gemini/flash/) |
| Gemma 4        | [Gemma-4-31B-IT](https://huggingface.co/google/gemma-4-31B-it) |
| Qwen 3.6       | [Qwen3.6-35B-A3B](https://huggingface.co/Qwen/Qwen3.6-35B-A3B) |

<!-- vale gitlab_base.Spelling = YES -->

## Modèles gérés par GitLab {#gitlab-managed-models}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/17192) dans GitLab 18.3 en tant que fonctionnalité [bêta](../../policy/development_stages_support.md#beta), avec un [feature flag](../feature_flags/_index.md) nommé `ai_self_hosted_vendored_features`. Désactivé par défaut.
- [Activation par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214030) dans GitLab 18.7
- [Suppression](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218595) du feature flag `ai_self_hosted_vendored_features` dans GitLab 18.9.

{{< /history >}}

Les modèles gérés par GitLab s’intègrent à l’infrastructure de la passerelle d’IA hébergée par GitLab pour donner accès à des modèles d’IA sélectionnés et mis à disposition par GitLab. Au lieu d’utiliser vos propres modèles auto-hébergés, vous pouvez choisir d’utiliser les modèles gérés par GitLab pour des fonctionnalités spécifiques de GitLab Duo.

Pour choisir les fonctionnalités pour lesquelles utiliser des modèles gérés par GitLab, consultez [sélectionner un modèle géré par GitLab pour une fonctionnalité](configure_duo_features.md#select-a-gitlab-managed-model-for-a-feature).

Lorsqu'un modèle est activé pour une fonctionnalité donnée :

- Tous les appels aux fonctionnalités configurées avec un modèle géré par GitLab passent par la passerelle d’IA hébergée par GitLab, et non par la passerelle d’IA auto-hébergée.
- Aucun journal détaillé n’est généré dans la passerelle d’IA hébergée par GitLab, même lorsque [les journaux d’IA sont activés.](logging.md#turn-on-data-collection-for-gitlab-duo). Cela évite les fuites involontaires d’informations sensibles.

## Exigences matérielles {#hardware-requirements}

Les spécifications matérielles suivantes constituent les exigences minimales pour exécuter GitLab Duo Self-Hosted sur site. Les exigences varient considérablement selon la taille du modèle et l’utilisation prévue :

### Configuration système requise {#base-system-requirements}

- **CPU** :
  - Minimum : 8 cœurs (16 threads)
  - Recommandé : plus de 16 cœurs pour les environnements de production
- **RAM** :
  - Minimum : 32 Go
  - Recommandé : 64 Go pour la plupart des modèles
- **Stockage** :
  - SSD avec un espace suffisant pour les poids du modèle et les données.

### Exigences GPU par taille de modèle {#gpu-requirements-by-model-size}

| Taille du modèle                                 | Configuration GPU minimale | VRAM minimale |
|--------------------------------------------|---------------------------|-----------------------|
| Modèles 7B<br>(par exemple, Mistral 7B)     | 1x NVIDIA A100 (40 Go)    | 35 Go                 |
| Modèles 22B<br>(par exemple, Codestral 22B) | 2x NVIDIA A100 (80 Go)    | 110 Go                |
| Mixtral 8x7B                               | 2x NVIDIA A100 (80 Go)    | 220 Go                |
| Mixtral 8x22B                              | 8x NVIDIA A100 (80 Go)    | 526 Go                |

Utilisez [l'utilitaire de gestion de la mémoire de Hugging Face](https://huggingface.co/spaces/hf-accelerate/model-memory-usage) pour vérifier la configuration mémoire requise.

### Temps de réponse par taille de modèle et GPU {#response-time-by-model-size-and-gpu}

#### Machine de faible puissance {#small-machine}

Avec un `a2-highgpu-2g` (2x NVIDIA A100 40 Go - 150 Go vRAM) ou équivalent :

| Nom du modèle               | Nombre de requêtes | Temps moyen par requête (s) | Nombre moyen de jetons dans la réponse | Nombre moyen de jetons par seconde et par requête | Temps total pour les requêtes | TPS total |
|--------------------------|--------------------|------------------------------|----------------------------|---------------------------------------|-------------------------|-----------|
| Mistral-7B-Instruct-v0.3 | 1                  | 7,09                         | 717,0                      | 101,19                                | 7,09                    | 101,17    |
| Mistral-7B-Instruct-v0.3 | 10                 | 8,41                         | 764,2                      | 90,35                                 | 13,70                   | 557,80    |
| Mistral-7B-Instruct-v0.3 | 100                | 13,97                        | 693,23                     | 49,17                                 | 20,81                   | 3331,59   |

#### Machine de moyenne puissance {#medium-machine}

Avec un `a2-ultragpu-4g` (4x NVIDIA A100 40 Go – 340 Go vRAM) sur GCP ou équivalent :

| Nom du modèle                 | Nombre de requêtes | Temps moyen par requête (s) | Nombre moyen de jetons dans la réponse | Nombre moyen de jetons par seconde et par requête | Temps total pour les requêtes | TPS total |
|----------------------------|--------------------|------------------------------|----------------------------|---------------------------------------|-------------------------|-----------|
| Mistral-7B-Instruct-v0.3   | 1                  | 3,80                         | 499,0                      | 131,25                                | 3,80                    | 131,23    |
| Mistral-7B-Instruct-v0.3   | 10                 | 6,00                         | 740,6                      | 122,85                                | 8,19                    | 904,22    |
| Mistral-7B-Instruct-v0.3   | 100                | 11,71                        | 695,71                     | 59,06                                 | 15,54                   | 4477,34   |
| Mixtral-8x7B-Instruct-v0.1 | 1                  | 6,50                         | 400,0                      | 61,55                                 | 6,50                    | 61,53     |
| Mixtral-8x7B-Instruct-v0.1 | 10                 | 16,58                        | 768,9                      | 40,33                                 | 32,56                   | 236,13    |
| Mixtral-8x7B-Instruct-v0.1 | 100                | 25,90                        | 767,38                     | 26,87                                 | 55,57                   | 1380,68   |

#### Machine de puissance élevée {#large-machine}

Avec un `a2-ultragpu-8g` (8 x NVIDIA A100 80 Go - 1360 Go vRAM) sur GCP ou équivalent :

| Nom du modèle                  | Nombre de requêtes | Temps moyen par requête (s) | Nombre moyen de jetons dans la réponse | Nombre moyen de jetons par seconde et par requête | Temps total pour les requêtes (s) | TPS total |
|-----------------------------|--------------------|------------------------------|----------------------------|---------------------------------------|-----------------------------|-----------|
| Mistral-7B-Instruct-v0.3    | 1                  | 3,23                         | 479,0                      | 148,41                                | 3,22                        | 148,36    |
| Mistral-7B-Instruct-v0.3    | 10                 | 4,95                         | 678,3                      | 135,98                                | 6,85                        | 989,11    |
| Mistral-7B-Instruct-v0.3    | 100                | 10,14                        | 713,27                     | 69,63                                 | 13,96                       | 5108,75   |
| Mixtral-8x7B-Instruct-v0.1  | 1                  | 6,08                         | 709,0                      | 116,69                                | 6,07                        | 116,64    |
| Mixtral-8x7B-Instruct-v0.1  | 10                 | 9,95                         | 645,0                      | 63,68                                 | 13,40                       | 481,06    |
| Mixtral-8x7B-Instruct-v0.1  | 100                | 13,83                        | 585,01                     | 41,80                                 | 20,38                       | 2869,12   |
| Mixtral-8x22B-Instruct-v0.1 | 1                  | 14,39                        | 828,0                      | 57,56                                 | 14,38                       | 57,55     |
| Mixtral-8x22B-Instruct-v0.1 | 10                 | 20,57                        | 629,7                      | 30,24                                 | 28,02                       | 224,71    |
| Mixtral-8x22B-Instruct-v0.1 | 100                | 27,58                        | 592,49                     | 21,34                                 | 36,80                       | 1609,85   |

### Exigences matérielles de la passerelle d'IA {#ai-gateway-hardware-requirements}

Pour obtenir des recommandations sur le matériel de la passerelle d'IA, consultez les [recommandations relatives à la mise à l'échelle de la passerelle d'IA](../../install/install_ai_gateway.md#scaling-recommendations).
