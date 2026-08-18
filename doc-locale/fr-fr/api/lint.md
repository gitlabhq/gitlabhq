---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API CI Lint
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour [valider votre configuration GitLab CI/CD](../ci/yaml/lint.md).

Ces endpoints utilisent du contenu YAML encodé en JSON. Dans certains cas, il peut être utile d'utiliser des outils tiers comme [`jq`](https://jqlang.org/) pour formater correctement votre contenu YAML avant d'effectuer une requête. Cela peut être utile si vous souhaitez conserver le format de votre configuration CI/CD.

Par exemple, la commande suivante utilise JQ pour échapper correctement un fichier YAML donné, l'encoder en JSON et effectuer une requête vers l'API.

```shell
jq --null-input --arg yaml "$(<example-gitlab-ci.yml)" '.content=$yaml' \
| curl --url "https://gitlab.com/api/v4/projects/:id/ci/lint?include_merged_yaml=true" \
--header 'Content-Type: application/json' \
--data @-
```

1. Créez un fichier YAML nommé `example-gitlab-ci.yml` :

   ```yaml
   .api_test:
     rules:
       - if: $CI_PIPELINE_SOURCE=="merge_request_event"
         changes:
           - src/api/*
   deploy:
     extends:
       - .api_test
     rules:
       - when: manual
         allow_failure: true
     script:
       - echo "hello world"
   ```

1. Pour échapper et encoder un fichier YAML d'entrée (`example-gitlab-ci.yml`), puis l'envoyer via `POST` à l'API GitLab, créez une commande sur une seule ligne combinant `curl` et `jq` :

   ```shell
   jq --null-input --arg yaml "$(<example-gitlab-ci.yml)" '.content=$yaml' \
   | curl --url "https://gitlab.com/api/v4/projects/:id/ci/lint?include_merged_yaml=true" \
       --header 'Content-Type: application/json' \
       --data @-
   ```

## Analyser les réponses de cette API {#parse-responses-from-this-api}

Pour reformater les réponses de l'API CI Lint, vous pouvez :

- Diriger la réponse CI Lint directement vers `jq`.
- Stocker la réponse de l'API dans un fichier texte et la fournir à `jq` comme argument, comme ceci :

  ```shell
  jq --raw-output '.merged_yaml | fromjson' <your_input_here>
  ```

Par exemple, ce tableau JSON :

```json
{"valid":"true","errors":[],"merged_yaml":"---\n.api_test:\n  rules:\n  - if: $CI_PIPELINE_SOURCE==\"merge_request_event\"\n    changes:\n    - src/api/*\ndeploy:\n  rules:\n  - when: manual\n    allow_failure: true\n  extends:\n  - \".api_test\"\n  script:\n  - echo \"hello world\"\n"}
```

Une fois analysé et reformaté, le fichier YAML résultant contient :

```yaml
.api_test:
  rules:
  - if: $CI_PIPELINE_SOURCE=="merge_request_event"
    changes:
    - src/api/*
deploy:
  rules:
  - when: manual
    allow_failure: true
  extends:
  - ".api_test"
  script:
  - echo "hello world"
```

## Valider la configuration CI/CD {#validate-cicd-configuration}

Valide la configuration `.gitlab-ci.yml` pour un projet spécifié. Cet endpoint valide la configuration CI/CD dans le contexte du projet, notamment :

- L'utilisation des variables CI/CD du projet.
- La recherche des entrées `include:local` dans les fichiers du projet.

```plaintext
POST /projects/:id/ci/lint
```

| Attribut      | Type    | Obligatoire | Description |
|----------------|---------|----------|-------------|
| `content`      | string  | Oui      | Le contenu de la configuration CI/CD. |
| `dry_run`      | boolean | Non       | Exécuter une [simulation de création de pipeline](../ci/yaml/lint.md#simulate-a-pipeline), ou effectuer uniquement une vérification statique. Par défaut : `false`. |
| `include_jobs` | boolean | Non       | Indique si la liste des jobs qui existeraient dans une vérification statique ou une simulation de pipeline doit être incluse dans la réponse. Par défaut : `false`. |
| `ref`          | string  | Non       | Lorsque `dry_run` est `true`, définit le contexte de la branche ou du tag à utiliser pour valider la configuration YAML CI/CD. Par défaut, la branche par défaut du projet est utilisée si ce paramètre n'est pas défini. |

Exemple de requête :

```shell
curl --request POST \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/:id/ci/lint" \
  --data @- <<'EOF'
{
  "content": "{
    \"image\": \"ruby:2.6\",
    \"services\": [\"postgres\"],
    \"before_script\": [
      \"bundle install\",
      \"bundle exec rake db:create\"
    ],
    \"variables\": {
      \"DB_NAME\": \"postgres\"
    },
    \"stages\": [\"test\", \"deploy\", \"notify\"],
    \"rspec\": {
      \"script\": \"rake spec\",
      \"tags\": [\"ruby\", \"postgres\"],
      \"only\": [\"branches\"]
    }
  }"
}
EOF
```

Exemples de réponses :

- Configuration valide :

  ```json
  {
    "valid": true,
    "merged_yaml": "---\ntest_job:\n  script: echo 1\n",
    "errors": [],
    "warnings": [],
    "includes": []
  }
  ```

- Configuration invalide :

  ```json
  {
    "valid": false,
    "errors": [
      "jobs config should contain at least one visible job"
    ],
    "warnings": [],
    "merged_yaml": "---\n\".job\":\n  script:\n  - echo \"A hidden job\"\n",
    "includes": []
  }
  ```

## Valider la configuration CI/CD existante {#validate-existing-cicd-configuration}

{{< history >}}

- L'attribut `sha` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/369212) dans GitLab 16.5.
- `sha` et `ref` ont été [renommés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143098) en `content_ref` et `dry_run_ref` dans GitLab 16.10.

{{< /history >}}

Valide la configuration `.gitlab-ci.yml` existante pour un projet spécifié. Cet endpoint valide la configuration CI/CD dans le contexte du projet, notamment :

- L'utilisation des variables CI/CD du projet.
- La recherche des entrées `include:local` dans les fichiers du projet.

```plaintext
GET /projects/:id/ci/lint
```

| Attribut      | Type    | Obligatoire | Description |
|----------------|---------|----------|-------------|
| `content_ref`  | string  | Non       | Le contenu de la configuration CI/CD est extrait de ce SHA de commit, de cette branche ou de ce tag. Par défaut, le SHA de la tête de la branche par défaut du projet est utilisé si ce paramètre n'est pas défini. |
| `dry_run`      | boolean | Non       | Exécuter une simulation de création de pipeline, ou effectuer uniquement une vérification statique. |
| `dry_run_ref`  | string  | Non       | Si `dry_run` est `true`, définit le contexte de la branche ou du tag à utiliser pour valider la configuration YAML CI/CD. Par défaut, la branche par défaut du projet est utilisée si ce paramètre n'est pas défini. |
| `include_jobs` | boolean | Non       | Indique si la liste des jobs qui existeraient dans une vérification statique ou une simulation de pipeline doit être incluse dans la réponse. Par défaut : `false`. |
| `ref`          | string  | Non       | (Déprécié) Lorsque `dry_run` est `true`, définit le contexte de la branche ou du tag à utiliser pour valider la configuration YAML CI/CD. Par défaut, la branche par défaut du projet est utilisée si ce paramètre n'est pas défini. Utilisez plutôt `dry_run_ref`. |
| `sha`          | string  | Non       | (Déprécié) Le contenu de la configuration CI/CD est extrait de ce SHA de commit, de cette branche ou de ce tag. Par défaut, le SHA de la tête de la branche par défaut du projet est utilisé si ce paramètre n'est pas défini. Utilisez plutôt `content_ref`. |

Exemple de requête :

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects/:id/ci/lint"
```

Exemples de réponses :

- Configuration valide, avec `include.yml` comme [fichier inclus](../ci/yaml/_index.md#include) et `include_jobs` défini sur `true` :

  ```json
  {
    "valid": true,
    "errors": [],
    "warnings": [],
    "merged_yaml": "---\ninclude-job:\n  script:\n  - echo \"An included job\"\njob:\n  rules:\n  - if: \"$CI_COMMIT_BRANCH\"\n  script:\n  - echo \"A test job\"\n",
    "includes": [
      {
        "type": "local",
        "location": "include.yml",
        "blob": "https://gitlab.example.com/test-group/test-project/-/blob/ef5014c045873c5c4ffeb7a2f5be021a1d3ed703/include.yml",
        "raw": "https://gitlab.example.com/test-group/test-project/-/raw/ef5014c045873c5c4ffeb7a2f5be021a1d3ed703/include.yml",
        "extra": {},
        "context_project": "test-group/test-project",
        "context_sha": "ef5014c045873c5c4ffeb7a2f5be021a1d3ed703"
      }
    ],
    "jobs": [
      {
        "name": "include-job",
        "stage": "test",
        "before_script": [],
        "script": [
          "echo \"An included job\""
        ],
        "after_script": [],
        "tag_list": [],
        "only": {
          "refs": [
            "branches",
            "tags"
          ]
        },
        "except": null,
        "environment": null,
        "when": "on_success",
        "allow_failure": false,
        "needs": null
      },
      {
        "name": "job",
        "stage": "test",
        "before_script": [],
        "script": [
          "echo \"A test job\""
        ],
        "after_script": [],
        "tag_list": [],
        "only": null,
        "except": null,
        "environment": null,
        "when": "on_success",
        "allow_failure": false,
        "needs": null
      }
    ]
  }
  ```

- Configuration invalide :

  ```json
  {
    "valid": false,
    "errors": [
      "jobs config should contain at least one visible job"
    ],
    "warnings": [],
    "merged_yaml": "---\n\".job\":\n  script:\n  - echo \"A hidden job\"\n",
    "includes": []
  }
  ```
