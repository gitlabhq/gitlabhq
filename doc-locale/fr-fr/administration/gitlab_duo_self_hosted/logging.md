---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Activer la journalisation pour les modèles auto-hébergés.
title: Journaux pour les modèles auto-hébergés
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
- Possibilité d'activer et de désactiver la journalisation via l'interface utilisateur ajoutée dans GitLab 17.9.
- Modifié pour inclure Premium dans GitLab 18.0.

{{< /history >}}

Surveillez les performances de votre modèle auto-hébergé et déboguez les problèmes plus efficacement grâce à une journalisation détaillée.

## Activer la collecte de données pour GitLab Duo {#turn-on-data-collection-for-gitlab-duo}

Prérequis :

- Vous devez être administrateur.

La collecte de données pour GitLab Duo diffère selon la configuration de l'AI Gateway.

### Sur GitLab Self-Managed avec un AI Gateway auto-hébergé {#on-gitlab-self-managed-with-a-self-hosted-ai-gateway}

Lorsque vous activez la collecte de données, les journaux AI verbeux (invites et réponses) sont stockés localement dans `llm.log` sur votre instance GitLab et dans l'AI Gateway. Les données ne sont pas partagées avec GitLab.

Pour activer la collecte de données :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Collecte de données**, sélectionnez **Collecter les données d'utilisation**.
1. Sélectionnez **Sauvegarder les modifications**.

### GitLab Self-Managed avec un AI Gateway géré par GitLab {#gitlab-self-managed-with-a-gitlab-managed-ai-gateway}

L'activation de **Collecter les données d'utilisation** partage les données d'utilisation avec GitLab. La journalisation étendue dans l'AI Gateway géré par GitLab n'est pas activée dans ce scénario, afin de protéger les données sensibles.

Pour activer la collecte de données :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Collecte de données**, sélectionnez **Collecter les données d'utilisation**.
1. Sélectionnez **Sauvegarder les modifications**.

## Journaux dans votre installation GitLab {#logs-in-your-gitlab-installation}

La configuration de la journalisation est conçue pour protéger les informations sensibles tout en maintenant la transparence des opérations système, et est composée des éléments suivants :

- Journaux qui capturent les requêtes adressées à l'instance GitLab.
- Contrôle de la journalisation.
- Le fichier `llm.log`.

### Journaux qui capturent les requêtes adressées à l'instance GitLab {#logs-that-capture-requests-to-the-gitlab-instance}

La journalisation dans les fichiers `application.json`, `production_json.log` et `production.log`, entre autres, capture les requêtes adressées à l'instance GitLab :

- **Filtered Requests** : Nous enregistrons les requêtes dans ces fichiers, mais nous veillons à ce que les données sensibles (telles que les paramètres d'entrée) soient **filtré**. Cela signifie que si les métadonnées de la requête sont capturées (par exemple, le type de requête, le point de terminaison et le statut de la réponse), les données d'entrée réelles (par exemple, les paramètres de requête, les variables et le contenu) ne sont pas enregistrées afin d'éviter l'exposition d'informations sensibles.
- **Example 1** : Dans le cas d'une requête de complétion de suggestions de code, les journaux capturent les détails de la requête tout en filtrant les informations sensibles :

  ```json
  {
    "method": "POST",
    "path": "/api/graphql",
    "controller": "GraphqlController",
    "action": "execute",
    "status": 500,
    "params": [
      {"key": "query", "value": "[FILTERED]"},
      {"key": "variables", "value": "[FILTERED]"},
      {"key": "operationName", "value": "chat"}
    ],
    "exception": {
      "class": "NoMethodError",
      "message": "undefined method `id` for {:skip=>true}:Hash"
    },
    "time": "2024-08-28T14:13:50.328Z"
  }
  ```

  Comme indiqué, si les informations d'erreur et la structure générale de la requête sont enregistrées, les paramètres d'entrée sensibles sont marqués comme `[FILTERED]`.

- **Example 2** : Dans le cas d'une requête de complétion de suggestions de code, les journaux capturent également les détails de la requête tout en filtrant les informations sensibles :

  ```json
  {
    "method": "POST",
    "path": "/api/v4/code_suggestions/completions",
    "status": 200,
    "params": [
      {"key": "prompt_version", "value": 1},
      {"key": "current_file", "value": {"file_name": "/test.rb", "language_identifier": "ruby", "content_above_cursor": "[FILTERED]", "content_below_cursor": "[FILTERED]"}},
      {"key": "telemetry", "value": []}
    ],
    "time": "2024-10-15T06:51:09.004Z"
  }
  ```

  Comme indiqué, si la structure générale de la requête est enregistrée, les paramètres d'entrée sensibles tels que `content_above_cursor` et `content_below_cursor` sont marqués comme `[FILTERED]`.

### Contrôle de la journalisation {#logging-control}

Pour contrôler un sous-ensemble de journaux, activez et désactivez la collecte de données via la page des paramètres de GitLab Duo. La désactivation de la collecte de données désactive la journalisation pour des opérations spécifiques.

### Fichier `llm.log` {#llmlog-file}

Dans une configuration d'AI Gateway auto-hébergé, lorsque la collecte de données est activée, les événements de génération de code et de GitLab Duo Chat qui se produisent via votre instance GitLab Self-Managed sont capturés dans le [fichier `llm.log`](../logs/_index.md#llmlog). Le fichier journal ne capture rien lorsqu'il n'est pas activé.

Les journaux de complétion de code sont capturés dans l'AI Gateway. Ces journaux ne sont pas transmis à GitLab. Ils sont visibles uniquement sur votre infrastructure GitLab Self-Managed.

- [Rotation, gestion, exportation et visualisation des journaux dans `llm.log`](../logs/_index.md).
- [Afficher l'emplacement du fichier journal (par exemple, pour pouvoir supprimer les journaux)](../logs/_index.md#llm-input-and-output-logging).

### Journaux dans votre conteneur AI Gateway {#logs-in-your-ai-gateway-container}

Pour spécifier l'emplacement des journaux générés par l'AI Gateway et la plateforme GitLab Duo Agent, exécutez :

```shell
docker run -e AIGW_GITLAB_URL=<your_gitlab_instance> \
 -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
 -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="your-signing-key" \
 -e AIGW_LOGGING__TO_FILE="aigateway.log" \
 -e DUO_WORKFLOW_LOGGING__TO_FILE="duo_agent_platform.log" \
 -v <your_aigateway_file_path>:aigateway.log \
 -v <your_duo_agent_platform_file_path>:duo_agent_platform.log \
 <image>
```

Par défaut, le niveau de journalisation est défini sur `INFO`. Pour modifier le niveau de journalisation en `DEBUG`, exécutez :

```shell
docker run -e AIGW_GITLAB_URL=<your_gitlab_instance> \
 -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
 -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="your-signing-key" \
 -e AIGW_LOGGING__TO_FILE="aigateway.log" \
 -e DUO_WORKFLOW_LOGGING__TO_FILE="duo_agent_platform.log" \
 -e AIGW_LOGGING__LEVEL="DEBUG" \
 -e DUO_WORKFLOW_LOGGING__LEVEL="DEBUG" \
 -v <your_aigateway_file_path>:aigateway.log \
 -v <your_duo_agent_platform_file_path>:duo_agent_platform.log \
 <image>
```

De plus, pour enregistrer toutes les instructions de débogage de `litellm`, ajoutez les variables d'environnement suivantes :

```shell
-e AIGW_LOGGING__ENABLE_LITELLM_LOGGING=true
```

Si vous ne spécifiez pas de nom de fichier, les journaux sont diffusés vers la sortie et peuvent également être gérés à l'aide des journaux Docker. Pour plus d'informations, consultez la [documentation Docker Logs](https://docs.docker.com/reference/cli/docker/container/logs/).

De plus, les sorties de l'exécution de l'AI Gateway peuvent aider au débogage des problèmes. Pour y accéder :

- Lors de l'utilisation de Docker :

  ```shell
  docker logs <container-id>
  ```

- Lors de l'utilisation de Kubernetes :

  ```shell
  kubectl logs <container-name>
  ```

Pour ingérer ces journaux dans la solution de journalisation, consultez la documentation de votre fournisseur de journalisation.

### Structure des journaux {#logs-structure}

Lorsqu'une requête POST est effectuée (par exemple, vers le point de terminaison `/chat/completions`), le serveur enregistre la requête :

- Payload
- En-têtes
- Métadonnées

#### 1\. Payload de la requête {#1-request-payload}

Le payload JSON inclut généralement les champs suivants :

- `messages` : Un tableau d'objets de message.
  - Chaque objet de message contient :
    - `content` : Une chaîne représentant la saisie ou la requête de l'utilisateur.
    - `role` : Indique le rôle de l'expéditeur du message (par exemple, `user`).
- `model` : Une chaîne spécifiant le modèle à utiliser (par exemple, `mistral`).
- `max_tokens` : Un entier spécifiant le nombre maximum de tokens à générer dans la réponse.
- `n` : Un entier indiquant le nombre de complétions à générer.
- `stop` : Un tableau de chaînes indiquant les séquences d'arrêt pour le texte généré.
- `stream` : Un booléen indiquant si la réponse doit être diffusée en continu.
- `temperature` : Un flottant contrôlant le caractère aléatoire de la sortie.

##### Exemple de requête {#example-request}

```json
{
    "messages": [
        {
            "content": "<s>[SUFFIX]None[PREFIX]# # build a hello world ruby method\n def say_goodbye\n    puts \"Goodbye, World!\"\n  end\n\ndef main\n  say_hello\n  say_goodbye\nend\n\nmain",
            "role": "user"
        }
    ],
    "model": "mistral",
    "max_tokens": 128,
    "n": 1,
    "stop": ["[INST]", "[/INST]", "[PREFIX]", "[MIDDLE]", "[SUFFIX]"],
    "stream": false,
    "temperature": 0.0
}
```

#### 2\. En-têtes de la requête {#2-request-headers}

Les en-têtes de la requête fournissent un contexte supplémentaire sur le client effectuant la requête. Les en-têtes clés peuvent inclure :

- `Authorization` : Contient le jeton Bearer pour l'accès à l'API.
- `Content-Type` : Indique le type de média de la ressource (par exemple, `JSON`).
- `User-Agent` : Informations sur le logiciel client effectuant la requête.
- En-têtes `X-Stainless-` : Divers en-têtes fournissant des métadonnées supplémentaires sur l'environnement client.

##### Exemple d'en-têtes de requête {#example-request-headers}

```json
{
    "host": "0.0.0.0:4000",
    "accept-encoding": "gzip, deflate",
    "connection": "keep-alive",
    "accept": "application/json",
    "content-type": "application/json",
    "user-agent": "AsyncOpenAI/Python 1.51.0",
    "authorization": "Bearer <TOKEN>",
    "content-length": "364"
}
```

#### 3\. Métadonnées de la requête {#3-request-metadata}

Les métadonnées incluent divers champs qui décrivent le contexte de la requête :

- `requester_metadata` : Métadonnées supplémentaires sur le demandeur.
- `user_api_key` : La clé API utilisée pour la requête (anonymisée).
- `api_version` : La version de l'API utilisée.
- `request_timeout` : La durée du délai d'attente pour la requête.
- `call_id` : Un identifiant unique pour l'appel.

##### Exemple de métadonnées {#example-metadata}

```json
{
    "user_api_key": "<ANONYMIZED_KEY>",
    "api_version": "1.48.18",
    "request_timeout": 600,
    "call_id": "e1aaa316-221c-498c-96ce-5bc1e7cb63af"
}
```

### Exemple de réponse {#example-response}

Le serveur répond avec une réponse de modèle structurée. Par exemple :

```python
Response: ModelResponse(
    id='chatcmpl-5d16ad41-c130-4e33-a71e-1c392741bcb9',
    choices=[
        Choices(
            finish_reason='stop',
            index=0,
            message=Message(
                content=' Here is the corrected Ruby code for your function:\n\n```ruby\ndef say_hello\n  puts "Hello, World!"\nend\n\ndef say_goodbye\n    puts "Goodbye, World!"\nend\n\ndef main\n  say_hello\n  say_goodbye\nend\n\nmain\n```\n\nIn your original code, the method names were misspelled as `say_hell` and `say_gobdye`. I corrected them to `say_hello` and `say_goodbye`. Also, there was no need for the prefix',
                role='assistant',
                tool_calls=None,
                function_call=None
            )
        )
    ],
    created=1728983827,
    model='mistral',
    object='chat.completion',
    system_fingerprint=None,
    usage=Usage(
        completion_tokens=128,
        prompt_tokens=69,
        total_tokens=197,
        completion_tokens_details=None,
        prompt_tokens_details=None
    )
)
```

### Journaux dans votre fournisseur de service d'inférence {#logs-in-your-inference-service-provider}

GitLab ne gère pas les journaux générés par votre fournisseur de service d'inférence. Consultez la documentation de votre fournisseur de service d'inférence pour savoir comment utiliser ses journaux.

## Comportement de journalisation dans les environnements GitLab et AI Gateway {#logging-behavior-in-gitlab-and-ai-gateway-environments}

GitLab fournit des fonctionnalités de journalisation pour les activités liées à l'IA via l'utilisation de `llm.log`, qui capture les entrées, les sorties et d'autres informations pertinentes. Cependant, le comportement de journalisation diffère selon que l'instance GitLab et l'AI Gateway sont **auto-hébergés** ou **connectés au cloud**.

Par défaut, le journal ne contient pas les entrées d'invites LLM et les sorties de réponse afin de prendre en charge les [politiques de conservation des données](../../user/gitlab_duo/data_usage.md#data-retention) des données de fonctionnalités IA.

## Scénarios de journalisation {#logging-scenarios}

### GitLab Self-Managed et AI Gateway auto-hébergé {#gitlab-self-managed-and-self-hosted-ai-gateway}

Dans cette configuration, GitLab et l'AI Gateway sont tous deux hébergés par le client.

- **Logging Behavior** : La journalisation complète est activée et toutes les invites, les entrées et les sorties sont enregistrées dans `llm.log` sur l'instance.
- Lorsque **Collecter les données d'utilisation** est activé, des informations de débogage supplémentaires sont enregistrées, notamment :
  - Invites prétraitées.
  - Invites finales.
  - Contexte supplémentaire.
- **Confidentialité** : Parce que GitLab et l'AI Gateway sont tous deux auto-hébergés :
  - Le client a un contrôle total sur la gestion des données.
  - La journalisation des informations sensibles peut être activée ou désactivée à la discrétion du client.

  > [!note]
  > Lorsqu'une fonctionnalité IA utilise un modèle géré par GitLab, même si la collecte de données est activée, des journaux détaillés ne sont pas générés dans l'AI Gateway géré par GitLab. Cela empêche les fuites non intentionnelles d'informations sensibles.

### GitLab Self-Managed et AI Gateway géré par GitLab (connecté au cloud) {#gitlab-self-managed-and-gitlab-managed-ai-gateway-cloud-connected}

Dans ce scénario, le client héberge GitLab mais s'appuie sur l'AI Gateway géré par GitLab pour le traitement IA.

- Comportement de journalisation : Pour obtenir des informations sur la façon dont GitLab gère les données d'invite et de réponse IA lors de l'utilisation de l'AI Gateway connecté au cloud, consultez [Utilisation des données GitLab Duo](../../user/gitlab_duo/data_usage.md#data-retention).
- Journalisation étendue : Même si **Collecter les données d'utilisation** est activé, aucun journal détaillé n'est généré dans l'AI Gateway géré par GitLab afin d'éviter des fuites non intentionnelles d'informations sensibles.
  - La journalisation reste minimale dans cette configuration, et les fonctionnalités de journalisation étendue sont désactivées par défaut.
- Confidentialité : Cette configuration est conçue pour garantir que les données sensibles ne sont pas enregistrées dans un environnement cloud.

## Journalisation dans les AI Gateways connectés au cloud {#logging-in-cloud-connected-ai-gateways}

Pour obtenir des informations sur la façon dont GitLab gère les données d'invite et de réponse IA lors de l'utilisation d'un AI Gateway connecté au cloud, consultez [Utilisation des données GitLab Duo](../../user/gitlab_duo/data_usage.md#data-retention).

## Références croisées des journaux entre l'AI Gateway et GitLab {#cross-referencing-logs-between-the-ai-gateway-and-gitlab}

La propriété `correlation_id` est assignée à chaque requête et est transmise à travers les différents composants qui répondent à une requête. Pour plus d'informations, consultez la [documentation sur la recherche de journaux avec un ID de corrélation](../logs/tracing_correlation_id.md).

L'ID de corrélation se trouve dans vos journaux AI Gateway et GitLab. Cependant, il n'est pas présent dans les journaux de votre fournisseur de modèle.

### Sujets connexes {#related-topics}

- [Analyse des journaux GitLab avec jq](../logs/log_parsing.md)
- [Recherche de l'ID de corrélation dans vos journaux](../logs/tracing_correlation_id.md#searching-your-logs-for-the-correlation-id)
