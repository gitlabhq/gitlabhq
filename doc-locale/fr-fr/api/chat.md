---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST de GitLab Duo Chat."
title: API de complétion GitLab Duo Chat
---

Cette API REST est utilisée pour générer des réponses pour [GitLab Duo Chat](../user/gitlab_duo_chat/_index.md) :

- Sur GitLab.com, cette API REST est réservée à un usage interne uniquement.
- Sur GitLab Self-Managed, vous pouvez activer cette API REST [avec un feature flag](../administration/feature_flags/_index.md) nommé `access_rest_chat`.

Prérequis :

- Vous devez être un [membre de l'équipe GitLab](https://gitlab.com/groups/gitlab-com/-/group_members).

## Générer une réponse Chat {#generate-a-chat-response}

Génère une réponse à une question GitLab Duo Chat.

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133015) dans GitLab 16.7 [avec un indicateur](../administration/feature_flags/_index.md) nommé `access_rest_chat`. Désactivé par défaut. Cette fonctionnalité est réservée à un usage interne uniquement.
- Paramètre `additional_context` [ajouté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162650) dans GitLab 17.4 [avec un indicateur](../administration/feature_flags/_index.md) nommé `duo_additional_context`. Désactivé par défaut. Cette fonctionnalité est réservée à un usage interne uniquement.
- Paramètre `additional_context` [activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181305) dans GitLab 17.9.
- Paramètre `additional_context` [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/514559) dans GitLab 18.0. L'indicateur de fonctionnalité `duo_additional_context` a été supprimé.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

```plaintext
POST /chat/completions
```

> [!note]
> Les requêtes envoyées à ce point de terminaison sont transmises par proxy à la [passerelle IA](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/api.md).

Attributs pris en charge :

| Attribut                | Type            | Obligatoire | Description                                                             |
|--------------------------|-----------------|----------|-------------------------------------------------------------------------|
| `content`                | string          | Oui      | Question envoyée au Chat.                                                  |
| `resource_type`          | string          | Non       | Type de ressource envoyée avec la question Chat.                       |
| `resource_id`            | string, integer | Non       | ID de la ressource. Peut être un ID de ressource (entier) ou un hash de commit (chaîne). |
| `referer_url`            | string          | Non       | URL du référent.                                                            |
| `client_subscription_id` | string          | Non       | ID d'abonnement client.                                                 |
| `with_clean_history`     | boolean         | Non       | Indique si l'historique doit être réinitialisé avant et après la requête. |
| `project_id`             | integer         | Non       | ID du projet. Obligatoire si `resource_type` est un commit.                    |
| `additional_context`     | array           | Non       | Un tableau d'éléments de contexte supplémentaires pour cette requête de chat. Voir [Attributs de contexte](#context-attributes) pour la liste des paramètres acceptés par cet attribut. |

### Attributs de contexte {#context-attributes}

L'attribut `context` accepte une liste d'éléments avec les attributs suivants :

- `category` - La catégorie de l'élément de contexte. Les valeurs valides sont `file`, `merge_request`, `issue` ou `snippet`.
- `id` - L'ID de l'élément de contexte.
- `content` - Le contenu de l'élément de contexte. La valeur dépend de la catégorie de l'élément de contexte.
- `metadata` - Les métadonnées supplémentaires facultatives pour cet élément de contexte. La valeur dépend de la catégorie de l'élément de contexte.

Exemple de requête :

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --header "Content-Type: application/json" \
  --data '{
      "content": "how to define class in ruby",
      "additional_context": [
        {
          "category": "file",
          "id": "main.rb",
          "content": "class Foo\nend"
        }
      ]
    }' \
  --url "https://gitlab.example.com/api/v4/chat/completions"
```

Exemple de réponse :

```json
"To define class in ruby..."
```
