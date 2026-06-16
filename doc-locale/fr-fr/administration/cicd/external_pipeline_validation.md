---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Validation externe de pipeline
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez utiliser un service externe pour valider un pipeline avant sa création.

GitLab envoie une requête POST à l'URL du service externe avec les données du pipeline comme charge utile. Le code de réponse du service externe détermine si GitLab doit accepter ou rejeter le pipeline. Si la réponse est :

- `200`, le pipeline est accepté.
- `406`, le pipeline est rejeté.
- Autres codes : le pipeline est accepté et journalisé.

En cas d'erreur ou d'expiration de la requête, le pipeline est accepté.

Les pipelines rejetés par le service de validation externe ne sont pas créés et n'apparaissent pas dans les listes de pipelines dans l'interface utilisateur ou l'API GitLab. Si vous créez un pipeline dans l'interface utilisateur qui est rejeté, `Pipeline cannot be run. External validation failed` s'affiche.

## Configurer la validation externe de pipeline {#configure-external-pipeline-validation}

Pour configurer la validation externe de pipeline, ajoutez la [variable d'environnement `EXTERNAL_VALIDATION_SERVICE_URL`](../environment_variables.md) et définissez-la sur l'URL du service externe.

Par défaut, les requêtes vers le service externe expirent après cinq secondes. Pour remplacer la valeur par défaut, définissez la variable d'environnement `EXTERNAL_VALIDATION_SERVICE_TIMEOUT` sur le nombre de secondes requis.

## Schéma de charge utile {#payload-schema}

{{< history >}}

- `tag_list` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/335904) dans GitLab 16.11.

{{< /history >}}

```json
{
  "type": "object",
  "required" : [
    "project",
    "user",
    "credit_card",
    "pipeline",
    "builds",
    "total_builds_count",
    "namespace"
  ],
  "properties" : {
    "project": {
      "type": "object",
      "required": [
        "id",
        "path",
        "created_at",
        "shared_runners_enabled",
        "group_runners_enabled"
      ],
      "properties": {
        "id": { "type": "integer" },
        "path": { "type": "string" },
        "created_at": { "type": ["string", "null"], "format": "date-time" },
        "shared_runners_enabled": { "type": "boolean" },
        "group_runners_enabled": { "type": "boolean" }
      }
    },
    "user": {
      "type": "object",
      "required": [
        "id",
        "username",
        "email",
        "created_at"
      ],
      "properties": {
        "id": { "type": "integer" },
        "username": { "type": "string" },
        "email": { "type": "string" },
        "created_at": { "type": ["string", "null"], "format": "date-time" },
        "current_sign_in_ip": { "type": ["string", "null"] },
        "last_sign_in_ip": { "type": ["string", "null"] },
        "sign_in_count": { "type": "integer" }
      }
    },
    "credit_card": {
      "type": "object",
      "required": [
        "similar_cards_count",
        "similar_holder_names_count"
      ],
      "properties": {
        "similar_cards_count": { "type": "integer" },
        "similar_holder_names_count": { "type": "integer" }
      }
    },
    "pipeline": {
      "type": "object",
      "required": [
        "sha",
        "ref",
        "type"
      ],
      "properties": {
        "sha": { "type": "string" },
        "ref": { "type": "string" },
        "type": { "type": "string" }
      }
    },
    "builds": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "name",
          "stage",
          "image",
          "tag_list",
          "services",
          "script"
        ],
        "properties": {
          "name": { "type": "string" },
          "stage": { "type": "string" },
          "image": { "type": ["string", "null"] },
          "tag_list": { "type": ["array", "null"] },
          "services": {
            "type": ["array", "null"],
            "items": { "type": "string" }
          },
          "script": {
            "type": "array",
            "items": { "type": "string" }
          }
        }
      }
    },
    "total_builds_count": { "type": "integer" },
    "namespace": {
      "type": "object",
      "required": [
        "plan",
        "trial"
      ],
      "properties": {
        "plan": { "type": "string" },
        "trial": { "type": "boolean" }
      }
    },
    "provisioning_group": {
      "type": "object",
      "required": [
        "plan",
        "trial"
      ],
      "properties": {
        "plan": { "type": "string" },
        "trial": { "type": "boolean" }
      }
    }
  }
}
```

Le champ `namespace` est uniquement disponible dans [GitLab Premium et Ultimate](https://about.gitlab.com/pricing/).
