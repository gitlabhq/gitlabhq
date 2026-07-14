---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Plateformes de service LLM prises en charge.
title: Configurer les plateformes LLM
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

{{< /history >}}

L'AI Gateway prend en charge plusieurs fournisseurs LLM via [LiteLLM](https://docs.litellm.ai/docs/providers). Chaque plateforme possède des fonctionnalités et des avantages uniques qui peuvent répondre à différents besoins. La documentation suivante résume les fournisseurs que nous avons validés et testés. Si la plateforme que vous souhaitez utiliser ne figure pas dans cette documentation, donnez votre avis dans le [ticket de demande de plateforme (issue 526144)](https://gitlab.com/gitlab-org/gitlab/-/issues/526144).

## Utiliser plusieurs modèles et plateformes {#use-multiple-models-and-platforms}

Vous pouvez utiliser plusieurs modèles et plateformes dans la même instance GitLab.

Par exemple, vous pouvez configurer une fonctionnalité pour utiliser Azure OpenAI, et une autre pour utiliser AWS Bedrock, ou des modèles auto-hébergés servis avec vLLM.

Cette configuration vous offre la flexibilité de choisir le meilleur modèle et la meilleure plateforme pour chaque cas d'utilisation. Les modèles doivent être pris en charge et servis via une plateforme compatible.

## Déploiements de modèles auto-hébergés {#self-hosted-model-deployments}

### vLLM {#vllm}

[vLLM](https://docs.vllm.ai/en/latest/index.html) est un serveur d'inférence haute performance optimisé pour servir des LLM avec une efficacité mémoire élevée. Il prend en charge le parallélisme de modèles et s'intègre facilement aux flux de travail existants.

Pour installer vLLM, consultez le [Guide d'installation de vLLM](https://docs.vllm.ai/en/latest/getting_started/installation.html). Vous devez installer la [version v0.18.1](https://github.com/vllm-project/vllm/releases/tag/v0.18.1) ou ultérieure.

Pour un guide de configuration prescriptif pour servir GPT OSS 120B avec vLLM, consultez [Servir GPT OSS 120B avec vLLM](vllm_gpt_oss_120b.md).

#### Configuration de l'URL du point de terminaison {#configuring-the-endpoint-url}

Lors de la configuration de l'URL du point de terminaison pour toute plateforme compatible avec l'API OpenAI (comme vLLM) dans GitLab :

- L'URL doit être suffixée par `/v1`
- Si vous utilisez la configuration vLLM par défaut, l'URL du point de terminaison serait `https://<hostname>:8000/v1`
- Si votre serveur est configuré derrière un proxy ou un équilibreur de charge, vous n'aurez peut-être pas besoin de spécifier le port, auquel cas l'URL serait `https://<hostname>/v1`

#### Trouver le nom du modèle {#find-the-model-name}

Une fois le modèle déployé, pour obtenir le nom du modèle pour le champ d'identifiant de modèle dans GitLab, interrogez le point de terminaison `/v1/models` du serveur vLLM :

```shell
curl \
  --header "Authorization: Bearer API_KEY" \
  --header "Content-Type: application/json" \
  http://your-vllm-server:8000/v1/models
```

Le nom du modèle est la valeur du champ `data.id` dans la réponse.

Exemple de réponse :

```json
{
  "object": "list",
  "data": [
    {
      "id": "Mixtral-8x22B-Instruct-v0.1",
      "object": "model",
      "created": 1739421415,
      "owned_by": "vllm",
      "root": "mistralai/Mixtral-8x22B-Instruct-v0.1",
      // Additional fields removed for readability
    }
  ]
}
```

Dans cet exemple, si le `id` du modèle est `Mixtral-8x22B-Instruct-v0.1`, vous devez définir l'identifiant du modèle dans GitLab comme `custom_openai/Mixtral-8x22B-Instruct-v0.1`.

Pour plus d'informations, consultez la documentation suivante :

- Modèles pris en charge par vLLM, consultez la [documentation sur les modèles pris en charge par vLLM](https://docs.vllm.ai/en/latest/models/supported_models.html).
- Options disponibles lors de l'utilisation de vLLM pour exécuter un modèle, consultez la [documentation de vLLM sur les arguments du moteur](https://docs.vllm.ai/en/stable/configuration/engine_args.html).

#### Mistral-7B-Instruct-v0.2 {#mistral-7b-instruct-v02}

1. Téléchargez le modèle depuis HuggingFace :

   ```shell
   git clone https://<your-hugging-face-username>:<your-hugging-face-token>@huggingface.co/mistralai/Mistral-7B-Instruct-v0.3
   ```

1. Exécutez le serveur :

   ```shell
   vllm serve <path-to-model>/Mistral-7B-Instruct-v0.3 \
      --served_model_name <choose-a-name-for-the-model>  \
      --tokenizer_mode mistral \
      --tensor_parallel_size <number-of-gpus> \
      --load_format mistral \
      --config_format mistral \
      --tokenizer <path-to-model>/Mistral-7B-Instruct-v0.3
   ```

#### Mixtral-8x7B-Instruct-v0.1 {#mixtral-8x7b-instruct-v01}

1. Téléchargez le modèle depuis HuggingFace :

   ```shell
   git clone https://<your-hugging-face-username>:<your-hugging-face-token>@huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1
   ```

1. Renommez la configuration du token :

   ```shell
   cd <path-to-model>/Mixtral-8x7B-Instruct-v0.1
   cp tokenizer.model tokenizer.model.v3
   ```

1. Exécutez le modèle :

   ```shell
   vllm serve <path-to-model>/Mixtral-8x7B-Instruct-v0.1 \
     --tensor_parallel_size 4 \
     --served_model_name <choose-a-name-for-the-model> \
     --tokenizer_mode mistral \
     --load_format safetensors \
     --tokenizer <path-to-model>/Mixtral-8x7B-Instruct-v0.1
   ```

#### Désactiver la journalisation des requêtes pour réduire la latence {#disable-request-logging-to-reduce-latency}

Lors de l'exécution de vLLM en production, vous pouvez réduire considérablement la latence en utilisant l'indicateur `--disable-log-requests` pour désactiver la journalisation des requêtes.

> [!note]
> Utilisez cet indicateur uniquement lorsque vous n'avez pas besoin d'une journalisation détaillée des requêtes.

La désactivation de la journalisation des requêtes minimise la surcharge introduite par les journaux détaillés, en particulier sous charge élevée, et peut contribuer à améliorer les niveaux de performance.

```shell
vllm serve <path-to-model>/<model-version> \
--served_model_name <choose-a-name-for-the-model>  \
--disable-log-requests
```

Cette modification a été observée comme améliorant notablement les temps de réponse dans les benchmarks internes.

## Déploiements de modèles hébergés dans le cloud {#cloud-hosted-model-deployments}

GitLab a validé et testé les fournisseurs suivants. L'AI Gateway prend en charge les fournisseurs LLM compatibles avec [LiteLLM](https://docs.litellm.ai/docs/providers).

- [AWS Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)
- [Google Vertex AI](https://cloud.google.com/vertex-ai)
- [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure%2Cglobal-standard%2Cstandard-chat-completions)
- [Anthropic](https://platform.claude.com/docs/en/about-claude/models/overview)
- [OpenAI](https://developers.openai.com/api/docs/models)

### Configurer l'authentification avec AWS Bedrock {#configure-authentication-with-aws-bedrock}

Vous pouvez utiliser plusieurs méthodes pour authentifier AWS Bedrock avec votre AI Gateway.

Prérequis :

- Les modèles sont automatiquement activés dans Bedrock lors de leur première invocation. Pour plus d'informations, consultez [Accès aux modèles Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html).
- Disposez d'identifiants AWS configurés avec les autorisations IAM appropriées.

#### Amazon EKS avec Helm Chart (Recommandé) {#amazon-eks-with-helm-chart-recommended}

Utilisez IRSA (IAM Roles for Service Accounts) pour vos pods AI Gateway afin de vous authentifier auprès d'AWS Bedrock, sans stocker d'identifiants statiques.

Après avoir authentifié Amazon EKS avec IRSA, l'AI Gateway obtient automatiquement des identifiants temporaires à partir du rôle IRSA.

Pour utiliser IRSA afin d'authentifier Amazon EKS :

1. Créez une politique IAM qui accorde l'accès aux modèles Bedrock. Vous pouvez restreindre la portée à des modèles spécifiques si vous avez besoin d'une sécurité accrue :

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "bedrock:InvokeModel",
           "bedrock:InvokeModelWithResponseStream"
         ],
         "Resource": "arn:aws:bedrock:*::foundation-model/*"
       }
     ]
   }
   ```

   ```shell
   aws iam create-policy \
     --policy-name bedrock-ai-gateway-access \
     --policy-document file://bedrock-policy.json \
     --description "Bedrock access for AI Gateway"
   ```

1. Facultatif. Pour un contrôle d'accès plus strict, remplacez la ressource générique par le nom de ressource Amazon (ARN) spécifique du modèle. Cela garantit que seuls les modèles approuvés sont accessibles, même si la configuration GitLab change. Pour les ARN de modèles disponibles, consultez [les ID de modèles Amazon Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html).

   ```json
   "Resource": [
     "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0",
     "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
   ]
   ```

   > [!note]
   > Certains modèles peuvent utiliser des formats ARN différents. Par exemple, les modèles plus récents peuvent nécessiter des ARN de profil d'inférence en plus des ARN de modèle de fondation. Pour vérifier le format ARN de votre modèle spécifique, consultez les [ID de modèles Amazon Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html).

1. Créez un rôle IAM avec une politique de confiance pour votre compte de service Amazon EKS. Remplacez les valeurs suivantes :

   - `YOUR_ACCOUNT_ID` : Votre ID de compte AWS.
   - `REGION` : La région de votre cluster Amazon EKS (par exemple, `us-east-1`).
   - `YOUR_OIDC_ID` : L'ID du fournisseur OIDC de votre cluster Amazon EKS.
   - `NAMESPACE` : L'espace de nommage Kubernetes où l'AI Gateway est déployé.

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/oidc.eks.REGION.amazonaws.com/id/YOUR_OIDC_ID"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "oidc.eks.REGION.amazonaws.com/id/YOUR_OIDC_ID:sub": "system:serviceaccount:NAMESPACE:ai-gateway",
             "oidc.eks.REGION.amazonaws.com/id/YOUR_OIDC_ID:aud": "sts.amazonaws.com"
           }
         }
       }
     ]
   }
   ```

   ```shell
   # Create the role
   aws iam create-role \
     --role-name eks-ai-gateway-bedrock \
     --assume-role-policy-document file://trust-policy.json \
     --description "EKS IRSA role for AI Gateway to access Bedrock"
   ```

1. Attachez la politique IAM Bedrock à ce rôle.

   ```shell
   # Attach the role
   aws iam attach-role-policy \
     --role-name eks-ai-gateway-bedrock \
     --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/bedrock-ai-gateway-access
   ```

1. Pour configurer le chart Helm, installez l'AI Gateway avec l'annotation de rôle IAM :

   ```yaml
   serviceAccount:
     create: true
     name: ai-gateway
     annotations:
       eks.amazonaws.com/role-arn: arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_ROLE_NAME
   extraEnvironmentVariables:
     - name: AWS_REGION
       value: us-east-1
   ```

Pour plus d'informations, consultez [les rôles IAM pour les comptes de service](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).

#### Déploiements Docker {#docker-deployments}

Configurez les identifiants IAM via des variables d'environnement lors du démarrage du conteneur AI Gateway :

```shell
docker run -d \
  -e AWS_ACCESS_KEY_ID=your-access-key \
  -e AWS_SECRET_ACCESS_KEY=your-secret-key \
  -e AWS_REGION=us-east-1 \
  -p 5052:5052 \
  registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-vX.Y.Z-ee
```

L'utilisateur ou le rôle IAM doit disposer d'une politique similaire à celle que vous définiriez dans Amazon EKS avec Helm Chart.

#### Déploiements Kubernetes {#kubernetes-deployments}

Pour les clusters Kubernetes autres qu'Amazon EKS, vous pouvez utiliser des secrets Kubernetes pour stocker les identifiants AWS :

1. Créez un secret Kubernetes :

   ```shell
   kubectl create secret generic aws-credentials \
     --from-literal=access-key-id=YOUR_ACCESS_KEY_ID \
     --from-literal=secret-access-key=YOUR_SECRET_ACCESS_KEY \
     -n YOUR_NAMESPACE
   ```

1. Configurez le chart Helm pour référencer le secret :

   ```yaml
   extraEnvironmentVariables:
     - name: AWS_ACCESS_KEY_ID
       valueFrom:
         secretKeyRef:
           name: aws-credentials
           key: access-key-id
     - name: AWS_SECRET_ACCESS_KEY
       valueFrom:
         secretKeyRef:
           name: aws-credentials
           key: secret-access-key
     - name: AWS_REGION
       value: us-east-1
   ```

#### Clés API AWS Bedrock {#aws-bedrock-api-keys}

Pour utiliser les clés API AWS Bedrock comme alternative aux identifiants IAM :

1. [Créer une clé API Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/api-keys-generate.html)
1. Créez un secret Kubernetes avec la clé API :

   ```shell
   kubectl create secret generic bedrock-api-key \
     --from-literal=token=YOUR_BEDROCK_API_KEY \
     -n YOUR_NAMESPACE
   ```

1. Configurez l'AI Gateway (ajoutez à votre `values.yaml`) :

   ```yaml
   extraEnvironmentVariables:
     - name: AWS_BEARER_TOKEN_BEDROCK
       valueFrom:
         secretKeyRef:
           name: bedrock-api-key
           key: token
     - name: AWS_REGION
       value: us-east-1
   ```

#### Points de terminaison VPC privés {#private-vpc-endpoints}

Pour utiliser un point de terminaison Bedrock privé dans un VPC, définissez la variable d'environnement `AWS_BEDROCK_RUNTIME_ENDPOINT`.

Pour les déploiements Helm :

```yaml
extraEnvironmentVariables:
  - name: AWS_BEDROCK_RUNTIME_ENDPOINT
    value: https://bedrock-runtime.us-east-1.amazonaws.com
```

Pour les déploiements Docker :

```shell
docker run -d \
  -e AWS_BEDROCK_RUNTIME_ENDPOINT=https://bedrock-runtime.us-east-1.amazonaws.com \
  -e AWS_REGION=us-east-1 \
  # ... other configuration
```

Pour les points de terminaison VPC, utilisez le format : `https://vpce-{vpc-endpoint-id}-{service-name}.{region}.vpce.amazonaws.com`

#### Garde-fous Bedrock {#bedrock-guardrails}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/4715) dans GitLab 19.0.

{{< /history >}}

Vous pouvez utiliser Amazon Bedrock Guardrails pour fournir des contrôles de sécurité et de confidentialité pour vos requêtes de modèles Bedrock.

Pour appliquer ces garde-fous, définissez la valeur de la variable d'environnement `AIGW_BEDROCK_GUARDRAIL_CONFIG` sur un objet JSON avec les champs suivants :

| Champ                 | Description |
|-----------------------|-------------|
| `guardrailIdentifier` | L'ID du garde-fou dans votre compte AWS. Peut être un ID simple (`abc123`), ou un ARN complet (`arn:aws:bedrock:us-east-1:123456789012:guardrail/abc123`). |
| `guardrailVersion`    | La version du garde-fou à appliquer. Définir sur `1`. |
| `trace`               | Indique si les informations de trace doivent être incluses dans la réponse. Peut être défini sur `enabled` ou `disabled`. |

> [!note]
> Lorsqu'un garde-fou bloque une requête, le message renvoyé aux utilisateurs est le message de blocage personnalisé configuré dans votre garde-fou AWS Bedrock, et non un message fourni par GitLab. Configurez les messages de blocage de votre garde-fou dans la console AWS pour vous assurer que les utilisateurs reçoivent des conseils appropriés.

Pour un déploiement Helm, définissez la variable d'environnement comme suit :

```yaml
extraEnvironmentVariables:
  - name: AIGW_BEDROCK_GUARDRAIL_CONFIG
    value: '{"guardrailIdentifier": "<guardrail_id>", "guardrailVersion": "1", "trace": "disabled"}'
```

Pour un déploiement Docker :

```shell
docker run -d \
  -e AIGW_BEDROCK_GUARDRAIL_CONFIG='{"guardrailIdentifier": "<guardrail_id>", "guardrailVersion": "1", "trace": "disabled"}' \
  # ... other configuration
```

Pour plus d'informations, consultez [Amazon Bedrock Guardrails](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html).

### Configurer l'authentification avec Google Vertex AI {#configure-authentication-with-google-vertex-ai}

Pour utiliser des modèles de Google Vertex AI, vous devez authentifier votre instance AI Gateway. Vous pouvez utiliser l'un des mécanismes suivants :

- Exportez les variables d'environnement lors du démarrage du conteneur Docker. Pour ce faire, définissez les variables d'environnement suivantes lors de l'exécution du conteneur AI Gateway :

  ```shell
  GOOGLE_APPLICATION_CREDENTIALS=/path/to/application_default_credentials.json
  VERTEXAI_PROJECT=<gcp-project-id>
  VERTEXAI_LOCATION=global # or any specific location, e.g., "europe-west1"
  ```

- Exécutez le conteneur AI Gateway sur Google Cloud Run et utilisez le [compte de service Cloud Run](https://docs.litellm.ai/docs/providers/vertex#using-gcp-service-account) pour l'accès à Vertex AI.

## Sujets connexes {#related-topics}

- [Documentation sur les modèles pris en charge et les exigences matérielles](supported_models_and_hardware_requirements.md).
- [Modèles de fondation pris en charge par Amazon Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)
- [Bonnes pratiques AWS IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Sécurité Amazon Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/security.html)
- Pour les informations de configuration, consultez la documentation suivante :
  - [Présentation de l'API Anthropic](https://platform.claude.com/docs/en/api/overview)
  - [Présentation de l'API OpenAI](https://developers.openai.com/api/docs)
  - [Utilisation des modèles Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/working-with-models?tabs=powershell)
