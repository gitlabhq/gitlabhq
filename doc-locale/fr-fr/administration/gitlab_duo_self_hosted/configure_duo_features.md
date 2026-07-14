---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Apprenez à intégrer vos modèles auto-hébergés à votre instance GitLab
title: Configurer GitLab pour utiliser des modèles auto-hébergés
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/12972) dans GitLab 17.1 [avec un flag](../feature_flags/_index.md) nommé `ai_custom_model`. Désactivé par défaut.
- [Activé sur GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) dans GitLab 17.6.
- Modifié pour nécessiter le module complémentaire GitLab Duo dans GitLab 17.6 et versions ultérieures.
- Le feature flag `ai_custom_model` a été supprimé dans GitLab 17.8
- Possibilité de définir l'URL de la passerelle d'IA via l'interface utilisateur [ajoutée](https://gitlab.com/gitlab-org/gitlab/-/issues/473143) dans GitLab 17.9.
- Généralement disponible dans GitLab 17.9.
- Modifié pour inclure Premium dans GitLab 18.0.

{{< /history >}}

Prérequis :

- [Mettez à niveau GitLab vers la version 17.9 ou ultérieure](../../update/_index.md).
- Vous devez être administrateur.

Pour configurer votre instance GitLab afin d'accéder aux modèles auto-hébergés dans votre infrastructure :

1. Configurez votre instance GitLab pour accéder à la passerelle d'IA.
1. Dans GitLab 18.4 et versions ultérieures, configurez votre instance GitLab pour accéder au service GitLab Duo Agent Platform.
1. Ajoutez des modèles auto-hébergés à votre instance GitLab.
1. Sélectionnez un modèle auto-hébergé pour une fonctionnalité.

## Configurer l'accès à la passerelle d'IA locale {#configure-access-to-the-local-ai-gateway}

Pour configurer l'accès entre votre instance GitLab et votre passerelle d'IA locale :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **URL de la passerelle d'IA locale**, saisissez l'URL de votre passerelle d'IA.
1. Sélectionnez **Sauvegarder les modifications**.

> [!note]
> Si l'URL de votre passerelle d'IA pointe vers un réseau local ou une adresse IP privée (par exemple, `172.31.x.x` ou des noms d'hôtes internes comme `ip-172-xx-xx-xx.region.compute.internal`), GitLab pourrait bloquer la requête pour des raisons de sécurité. Pour autoriser les requêtes vers cette adresse, [ajoutez l'adresse à la liste d'autorisation d'adresses IP](../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains).

### Configurer le délai d'attente de la passerelle d'IA {#configure-timeout-for-the-ai-gateway}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/567878) dans GitLab 18.7.

{{< /history >}}

Pour économiser des ressources et éviter les requêtes de longue durée, configurez le délai d'attente pour les requêtes GitLab vers la passerelle d'IA lors de l'attente des réponses du modèle. Utilisez des délais d'attente plus longs pour les modèles auto-hébergés avec de grandes fenêtres de contexte ou des requêtes complexes.

Vous pouvez configurer un délai d'attente compris entre 60 et 600 secondes (10 minutes). Si vous ne définissez pas le délai d'attente, GitLab utilise le délai d'attente par défaut de 60 secondes.

Pour configurer le délai d'attente de la passerelle d'IA :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Délai d'attente de la requête de la passerelle d'IA dépassé**, saisissez la valeur du délai d'attente en secondes (entre 60 et 600).
1. Sélectionnez **Sauvegarder les modifications**.

### Déterminer la valeur du délai d'attente {#determine-the-timeout-value}

La valeur du délai d'attente dépend de votre déploiement spécifique et de votre cas d'utilisation.

Pour déterminer la valeur du délai d'attente :

- Commencez avec le délai d'attente par défaut de 60 secondes et surveillez les erreurs de délai d'attente.
- Surveillez vos journaux pour les erreurs de délai d'attente `A1000` dans vos journaux. Si ces erreurs se produisent fréquemment, envisagez d'augmenter le délai d'attente.
- Tenez compte de votre cas d'utilisation. Les invites plus volumineuses, les tâches complexes de génération de code ou le traitement de documents de conception volumineux peuvent nécessiter des délais d'attente plus longs.
- Tenez compte de votre infrastructure. Les performances du modèle dépendent des ressources GPU disponibles, de la latence réseau entre la passerelle d'IA et le point de terminaison du modèle, et des capacités de traitement du modèle.
- Augmentez de manière incrémentielle. Si vous rencontrez des dépassements de délai, augmentez la valeur progressivement (par exemple, de 30 à 60 secondes) et surveillez les résultats.

Pour plus d'informations sur la résolution des erreurs de délai d'attente, consultez [Erreur A1000](troubleshooting.md#error-a1000).

## Configurer l'accès à GitLab Duo Agent Platform {#configure-access-to-the-gitlab-duo-agent-platform}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/19213) dans GitLab 18.4, en tant qu'[expérimentation](../../policy/development_stages_support.md#experiment) avec un [feature flag](../feature_flags/_index.md) nommé `self_hosted_agent_platform`. Désactivé par défaut.
- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/558083) de l'expérimentation à la bêta dans GitLab 18.5.
- [Activé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951) dans GitLab 18.7.
- [Disponible en version générale](https://gitlab.com/groups/gitlab-org/-/work_items/19125) dans GitLab 18.8.
- Le feature flag `self_hosted_agent_platform` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218589) dans GitLab 18.9.
- Sur GitLab 18.7 et 18.8, cette fonctionnalité est en bêta pour les clients disposant de licences en ligne. Pour utiliser cette fonctionnalité, vous devez [activer](#turn-on-self-hosted-beta-models-and-features) les modèles et fonctionnalités bêta auto-hébergés.

{{< /history >}}

Prérequis :

- Si votre instance dispose d'une licence hors ligne, vous devez disposer du module complémentaire [GitLab Duo Agent Platform Self-Hosted](../../subscriptions/subscription-add-ons.md).

Pour accéder au service Agent Platform depuis votre instance GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **URL locale du service GitLab Duo Agent Platform**, saisissez l'URL du service Agent Platform local.
   - L'URL est généralement la même que **URL de la passerelle d'IA locale** mais sur le port gRPC :50052.
   - N'incluez pas de préfixe d'URL tel que `http://` ou `https://`.
   - Si vous avez configuré SSL avec un [proxy inverse NGINX comme recommandé](../../install/install_ai_gateway.md#set-up-docker-with-nginx-and-ssl), ou utilisez le [chart Helm avec Ingress activé](../../install/install_ai_gateway.md#install-by-using-helm-chart), ne spécifiez pas de port. L'Ingress NGINX gère la redirection de port.
1. Facultatif. Si votre point de terminaison GitLab Duo Agent Platform local utilise TLS, sous **Sécurité**, cochez la case **Utiliser une connexion sécurisée (TLS) pour le service GitLab Duo Agent Platform**.
1. Sélectionnez **Sauvegarder les modifications**.

## Ajouter un modèle auto-hébergé {#add-a-self-hosted-model}

Vous devez ajouter un modèle auto-hébergé à votre instance GitLab pour l'utiliser avec les fonctionnalités GitLab Duo.

Pour ajouter un modèle auto-hébergé :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Configurer les modèles pour GitLab Duo**.
   - Si **Configurer les modèles pour GitLab Duo** n'est pas disponible, synchronisez votre abonnement après l'achat :
     1. Dans la barre latérale gauche, sélectionnez **Abonnement**.
     1. Dans **Détails de l'abonnement**, à droite de **Dernière synchronisation**, sélectionnez synchroniser l'abonnement ({{< icon name="retry" >}}).
1. Sélectionnez **Ajouter un modèle auto-hébergé**.
1. Remplissez les champs :
   - **Nom de déploiement** : Saisissez un nom pour identifier de manière unique le déploiement du modèle, par exemple, `Mixtral-8x7B-it-v0.1 on GCP`.
   - **Famille de modèles** : Sélectionnez la famille de modèles à laquelle appartient le déploiement. Vous pouvez sélectionner un modèle pris en charge ou compatible.
   - **Point de terminaison** : Saisissez l'URL où le modèle est hébergé.
   - **Clé de l'API** : Facultatif. Ajoutez une clé d'API si vous en avez besoin pour accéder au modèle.
   - **Identifiant du modèle** : Saisissez l'identifiant du modèle en fonction de votre méthode de déploiement. L'identifiant du modèle doit correspondre au format suivant :

     | Méthode de déploiement | Format | Exemple |
     |-------------|---------|---------|
     | [vLLM](supported_llm_serving_platforms.md#find-the-model-name)        | `custom_openai/<name of the model served through vLLM>` | `custom_openai/Mixtral-8x7B-Instruct-v0.1` |
     | [Amazon Bedrock](#set-the-model-identifier-for-amazon-bedrock-models) | `bedrock/<model ID of the model>`                       | `bedrock/mistral.mixtral-8x7b-instruct-v0:1` |
     | [Google Vertex AI](https://cloud.google.com/vertex-ai/generative-ai/docs/partner-models/use-claude) | `vertex_ai/<model ID of the model>` | `vertex_ai/claude-sonnet-4-6@default` |
     | [Anthropic](https://platform.claude.com/docs/en/about-claude/models/overview)                                                             | `anthropic/<model ID of the model>`                     | `anthropic/claude-opus-4-6` |
     | [OpenAI](https://developers.openai.com/api/docs/models)                                                                | `openai/<model ID of the model>`                        | `openai/gpt-5` |
     | Azure OpenAI                                                          | `azure/<model ID of the model>`                         | `azure/gpt-35-turbo` |

1. Sélectionnez **Ajouter un modèle auto-hébergé**.

### Définir l'identifiant de modèle pour les modèles Amazon Bedrock {#set-the-model-identifier-for-amazon-bedrock-models}

Pour définir un identifiant de modèle pour un modèle Amazon Bedrock :

1. Définissez votre `AWS_REGION`. Assurez-vous d'avoir accès aux modèles dans cette région dans votre configuration Docker de la passerelle d'IA.
1. Ajoutez le préfixe de région à l'ID de profil d'inférence du modèle pour l'inférence inter-régions.
1. Utilisez le préfixe de région `bedrock/` comme préfixe pour l'identifiant du modèle.

   Par exemple, pour le modèle Anthropic Claude 4.0 dans la région de Tokyo :

   - Le `AWS_REGION` est `ap-northeast-1`.
   - Le préfixe d'inférence inter-régions est `apac.`.
   - L'identifiant du modèle est `bedrock/apac.anthropic.claude-sonnet-4-20250514-v1:0`.

Certaines régions ne sont pas prises en charge par l'inférence inter-régions. Pour ces régions, ne spécifiez pas de préfixe de région dans l'identifiant du modèle. Par exemple :

- Le `AWS_REGION` est `eu-west-2`.
- L'identifiant du modèle est `anthropic.claude-sonnet-4-5-20250929-v1:0`.

## Activer les modèles et fonctionnalités bêta auto-hébergés {#turn-on-self-hosted-beta-models-and-features}

> [!note]
> L'activation des modèles et fonctionnalités bêta auto-hébergés implique également l'acceptation du [contrat de test GitLab](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

Pour activer les modèles et fonctionnalités bêta auto-hébergés :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Modèles et fonctionnalités bêta auto-hébergés**, cochez la case **Utiliser des modèles et fonctionnalités bêta dans les modèles GitLab Duo auto-hébergés**.
1. Sélectionnez **Sauvegarder les modifications**.

## Configurer les fonctionnalités GitLab Duo pour utiliser des modèles auto-hébergés {#configure-gitlab-duo-features-to-use-self-hosted-models}

### Afficher les fonctionnalités configurées {#view-configured-features}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Configurer les modèles pour GitLab Duo**.
   - Si **Configurer les modèles pour GitLab Duo** n'est pas disponible, synchronisez votre abonnement après l'achat :
     1. Dans la barre latérale gauche, sélectionnez **Abonnement**.
     1. Dans **Détails de l'abonnement**, à droite de **Dernière synchronisation**, sélectionnez synchroniser l'abonnement ({{< icon name="retry" >}}).
1. Sélectionnez l'onglet **Fonctionnalités d'IA natives**.

### Sélectionner un modèle auto-hébergé pour une fonctionnalité {#select-a-self-hosted-model-for-a-feature}

Pour sélectionner un modèle auto-hébergé :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Configurer les modèles pour GitLab Duo**.
1. Sélectionnez l'onglet **Fonctionnalités d'IA natives**.
1. Pour la fonctionnalité pour laquelle vous souhaitez sélectionner un modèle auto-hébergé, sélectionnez le modèle dans la liste déroulante.

> [!note]
> Si vous ne spécifiez pas de modèle pour une sous-fonctionnalité de GitLab Duo Chat, elle utilise automatiquement le modèle configuré pour **General Chat**. Cela garantit que toutes les fonctionnalités de Chat fonctionnent sans nécessiter une sélection individuelle de modèle pour chaque sous-fonctionnalité.

### Sélectionner un modèle géré par GitLab pour une fonctionnalité {#select-a-gitlab-managed-model-for-a-feature}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/17192) dans GitLab 18.3, en tant que [bêta](../../policy/development_stages_support.md#beta) avec un [feature flag](../feature_flags/_index.md) nommé `ai_self_hosted_vendored_features`. Désactivé par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214030) dans GitLab 18.7
- Généralement disponible dans GitLab 18.9. Le feature flag `ai_self_hosted_vendored_features` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218595).

{{< /history >}}

Vous pouvez sélectionner un modèle géré par GitLab pour une fonctionnalité, même si vous utilisez une passerelle d'IA auto-hébergée et des modèles auto-hébergés.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Configurer les modèles pour GitLab Duo**.
1. Sélectionnez l'onglet **Fonctionnalités d'IA natives**.
1. Pour la fonctionnalité et la sous-fonctionnalité que vous souhaitez configurer, dans la liste déroulante, sélectionnez **Modèle géré par GitLab**.

### Désactiver les fonctionnalités GitLab Duo {#turn-off-gitlab-duo-features}

Les fonctionnalités GitLab Duo restent activées même si vous n'avez pas choisi de modèle pour une fonctionnalité.

Pour désactiver une fonctionnalité GitLab Duo :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Configurer les modèles pour GitLab Duo**.
1. Sélectionnez l'onglet **Fonctionnalités d'IA natives**.
1. Pour la fonctionnalité que vous souhaitez désactiver, dans la liste déroulante, sélectionnez **Désactivé**.

### Auto-héberger la documentation GitLab {#self-host-the-gitlab-documentation}

Si votre configuration vous empêche d'accéder à la documentation GitLab sur `docs.gitlab.com`, vous pouvez auto-héberger la documentation. Pour plus d'informations, consultez [Héberger la documentation du produit GitLab](../docs_self_host.md).

## Sujets connexes {#related-topics}

- [Modèles pris en charge](supported_models_and_hardware_requirements.md#supported-models)
- [Modèles compatibles](supported_models_and_hardware_requirements.md#compatible-models)
- [Types de configuration de la passerelle d'IA](_index.md#ai-gateway-configurations)
