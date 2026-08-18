---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST de Code Suggestions."
title: API Code Suggestions
---

Utilisez cette API REST pour accéder à GitLab Duo Code Suggestions.

## Générer des complétions de code {#generate-code-completions}

{{< details >}}

- Statut : Expérience

{{< /details >}}

{{< history >}}

- Introduit dans GitLab 16.2 [avec un feature flag](../administration/feature_flags/_index.md) nommé `code_suggestions_completion_api`. Désactivé par défaut. Cette fonctionnalité est une expérimentation.
- L'obligation de générer un JWT avant d'appeler cet endpoint a été [supprimée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127863) dans GitLab 16.3.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/416371) dans GitLab 16.8. [Le feature flag `code_suggestions_completion_api`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138174) a été supprimé.
- Les attributs `context` et `user_instruction` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/462750) dans GitLab 17.1 [avec un feature flag](../administration/feature_flags/_index.md) nommé `code_suggestions_context`. Désactivé par défaut.
- Les attributs `context` et `user_instruction` sont [généralement disponibles](https://gitlab.com/gitlab-org/gitlab/-/issues/462750) dans GitLab 18.6. L'indicateur de fonctionnalité `code_suggestions_context` a été supprimé.

{{< /history >}}

```plaintext
POST /code_suggestions/completions
```

> [!note]
> Cet endpoint applique une limite de débit de 60 requêtes par fenêtre de 1 minute par utilisateur.

Utilisez la couche d'abstraction IA pour générer des complétions de code.

Les requêtes adressées à cet endpoint sont transmises par proxy à l'[AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/api.md).

Paramètres :

| Attribut          | Type    | Obligatoire | Description |
|--------------------|---------|----------|-------------|
| `current_file`     | hash    | oui      | Attributs du fichier pour lequel des suggestions sont générées. Consultez [Attributs de fichier](#file-attributes) pour obtenir la liste des chaînes acceptées par cet attribut. |
| `intent`           | string  | non       | L'intention de la requête de complétion. Cela peut être soit `completion`, soit `generation`. |
| `stream`           | boolean | non       | Indique si la réponse doit être diffusée en flux sous forme de petits morceaux dès qu'ils sont prêts (le cas échéant). Par défaut : `false`. |
| `project_path`     | string  | non       | Le chemin du projet. |
| `generation_type`  | string  | non       | Le type d'événement pour les requêtes de génération. Cela peut être `comment`, `empty_function` ou `small_file`. |
| `context`          | tableau   | non       | Contexte supplémentaire à utiliser pour Code Suggestions. Consultez [Attributs de contexte](#context-attributes) pour obtenir la liste des paramètres acceptés par cet attribut. |
| `user_instruction` | string  | non       | Les instructions d'un utilisateur pour Code Suggestions. |

### Attributs de fichier {#file-attributes}

L'attribut `current_file` accepte les chaînes suivantes :

- `file_name` - Le nom du fichier. Obligatoire.
- `content_above_cursor` - Le contenu du fichier au-dessus de la position actuelle du curseur. Obligatoire.
- `content_below_cursor` - Le contenu du fichier en dessous de la position actuelle du curseur. Facultatif.

### Attributs de contexte {#context-attributes}

L'attribut `context` accepte une liste d'éléments avec les attributs suivants :

- `type` - Le type de l'élément de contexte. Cela peut être soit `file`, soit `snippet`.
- `name` - Le nom de l'élément de contexte. Un nom de fichier ou un extrait de code.
- `content` - Le contenu de l'élément de contexte. Le corps du fichier ou une fonction.

Exemple de requête :

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --data '{
      "current_file": {
        "file_name": "car.py",
        "content_above_cursor": "class Car:\n    def __init__(self):\n        self.is_running = False\n        self.speed = 0\n    def increase_speed(self, increment):",
        "content_below_cursor": ""
      },
      "intent": "completion"
    }' \
  --url "https://gitlab.example.com/api/v4/code_suggestions/completions"
```

Exemple de réponse :

```json
{
  "id": "id",
  "model": {
    "engine": "vertex-ai",
    "name": "code-gecko"
  },
  "object": "text_completion",
  "created": 1688557841,
  "choices": [
    {
      "text": "\n        if self.is_running:\n            self.speed += increment\n            print(\"The car's speed is now",
      "index": 0,
      "finish_reason": "length"
    }
  ]
}
```

## Valider que Code Suggestions est activé {#validate-that-code-suggestions-is-enabled}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138814) dans GitLab 16.7.

{{< /history >}}

Utilisez cet endpoint pour valider si :

- Un projet a `code_suggestions` activé.
- Le groupe d'un projet a `code_suggestions` activé dans ses paramètres d'espace de nommage.

```plaintext
POST code_suggestions/enabled
```

Attributs pris en charge :

| Attribut         | Type    | Obligatoire | Description |
| ----------------- | ------- | -------- | ----------- |
| `project_path`    | string  | oui      | Le chemin du projet à valider. |

En cas de succès, retourne :

- [`200`](rest/troubleshooting.md#status-codes) si la fonctionnalité est activée.
- [`403`](rest/troubleshooting.md#status-codes) si la fonctionnalité est désactivée.

De plus, retourne un [`404`](rest/troubleshooting.md#status-codes) si le chemin est vide ou si le projet n'existe pas.

Exemple de requête :

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/code_suggestions/enabled" \
  --header "PRIVATE-TOKEN: <YOUR_ACCESS_TOKEN>" \
  --header "Content-Type: application/json" \
  --data '{
      "project_path": "group/project_name"
    }'
```

## Récupérer les détails de connexion directe pour l'AI Gateway {#fetch-direct-connection-details-for-the-ai-gateway}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/452044) dans GitLab 17.0 [avec un feature flag](../administration/feature_flags/_index.md) nommé `code_suggestions_direct_completions`. Désactivé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/456443) dans GitLab 17.2. L'indicateur de fonctionnalité `code_suggestions_direct_completions` a été supprimé.

{{< /history >}}

```plaintext
POST /code_suggestions/direct_access
```

> [!note]
> Cet endpoint applique une limite de débit de 10 requêtes par fenêtre de 5 minutes par utilisateur.

Retourne des détails de connexion spécifiques à l'utilisateur, utilisables par les IDE/clients pour envoyer des requêtes `completion` directement à l'AI Gateway, y compris les en-têtes devant être transmis par proxy à l'AI Gateway ainsi que le jeton d'authentification requis.

Exemple de requête :

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --url "https://gitlab.example.com/api/v4/code_suggestions/direct_access"
```

Exemple de réponse :

```json
{
  "base_url": "http://0.0.0.0:5052",
  "token": "a valid token",
  "expires_at": 1713343569,
  "headers": {
    "X-Gitlab-Instance-Id": "292c3c7c-c5d5-48ec-b4bf-f00b724ce560",
    "X-Gitlab-Realm": "saas",
    "X-Gitlab-Global-User-Id": "Df0Jhs9xlbetQR8YoZCKDZJflhxO0ZBI8uoRzmpnd1w=",
    "X-Gitlab-Host-Name": "gitlab.example.com"
  }
}
```

## Récupérer les détails de connexion {#fetch-connection-details}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/555060) dans GitLab 18.3.

{{< /history >}}

```plaintext
POST /code_suggestions/connection_details
```

> [!note]
> Cet endpoint applique une limite de débit de 10 requêtes par fenêtre de 1 minute par utilisateur.

Retourne des détails de connexion spécifiques à l'utilisateur, utilisables par les IDE/clients pour la télémétrie, y compris des métadonnées sur l'instance GitLab à laquelle l'utilisateur est connecté.

Exemple de requête :

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --url "https://gitlab.example.com/api/v4/code_suggestions/connection_details"
```

Exemple de réponse :

```json
{
  "instance_id": "292c3c7c-c5d5-48ec-b4bf-f00b724ce560",
  "instance_version": "18.2",
  "realm": "saas",
  "global_user_id": "Df0Jhs9xlbetQR8YoZCKDZJflhxO0ZBI8uoRzmpnd1w=",
  "host_name": "gitlab.example.com",
  "feature_enablement_type": "duo_pro",
  "saas_duo_pro_namespace_ids": "1000000"
}
```
