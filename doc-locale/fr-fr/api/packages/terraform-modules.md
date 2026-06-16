---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API du registre de modules Terraform
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec le [CLI Terraform](../../user/packages/terraform_module_registry/_index.md).

> [!warning]
> Cette API est utilisée par le [CLI Terraform](https://www.terraform.io/) et n'est généralement pas destinée à une utilisation manuelle. Les méthodes d'authentification non documentées pourraient être supprimées à l'avenir.

## Répertorier les versions disponibles pour un module spécifique {#list-available-versions-for-a-specific-module}

Répertoriez toutes les versions disponibles pour un module spécifié.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/versions
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | oui | Le groupe principal (espace de nommage) auquel appartient le projet ou le sous-groupe du module Terraform.|
| `module_name` | string | oui | Le nom du module. |
| `module_system` | string | oui | Le nom du système de module ou du [fournisseur](https://www.terraform.io/registry/providers). |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/versions"
```

Exemple de réponse :

```json
{
  "modules": [
    {
      "versions": [
        {
          "version": "1.0.0",
          "submodules": [],
          "root": {
            "dependencies": [],
            "providers": [
              {
                "name": "local",
                "version":""
              }
            ]
          }
        },
        {
          "version": "0.9.3",
          "submodules": [],
          "root": {
            "dependencies": [],
            "providers": [
              {
                "name": "local",
                "version":""
              }
            ]
          }
        }
      ],
      "source": "https://gitlab.example.com/group/hello-world"
    }
  ]
}
```

## Récupérer la dernière version d'un module {#retrieve-latest-version-for-a-module}

Récupérez des informations sur la dernière version d'un module spécifié.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | oui | Le groupe auquel appartient le projet du module Terraform. |
| `module_name` | string | oui | Le nom du module. |
| `module_system` | string | oui | Le nom du système de module ou du [fournisseur](https://www.terraform.io/registry/providers). |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local"
```

Exemple de réponse :

```json
{
  "name": "hello-world/local",
  "provider": "local",
  "providers": [
    "local"
  ],
  "root": {
    "dependencies": []
  },
  "source": "https://gitlab.example.com/group/hello-world",
  "submodules": [],
  "version": "1.0.0",
  "versions": [
    "1.0.0"
  ]
}
```

## Récupérer une version spécifique d'un module {#retrieve-a-specific-version-for-a-module}

Récupérez des informations sur une version spécifique d'un module spécifié.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/1.0.0
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | oui | Le groupe auquel appartient le projet du module Terraform. |
| `module_name` | string | oui | Le nom du module. |
| `module_system` | string | oui | Le nom du système de module ou du [fournisseur](https://www.terraform.io/registry/providers). |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0"
```

Exemple de réponse :

```json
{
  "name": "hello-world/local",
  "provider": "local",
  "providers": [
    "local"
  ],
  "root": {
    "dependencies": []
  },
  "source": "https://gitlab.example.com/group/hello-world",
  "submodules": [],
  "version": "1.0.0",
  "versions": [
    "1.0.0"
  ]
}
```

## Récupérer l'URL de téléchargement pour la dernière version du module {#retrieve-download-url-for-latest-module-version}

Récupérez l'URL de téléchargement pour la dernière version du module dans l'en-tête `X-Terraform-Get`.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/download
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | oui | Le groupe auquel appartient le projet du module Terraform. |
| `module_name` | string | oui | Le nom du module. |
| `module_system` | string | oui | Le nom du système de module ou du [fournisseur](https://www.terraform.io/registry/providers). |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/download"
```

Exemple de réponse :

```plaintext
HTTP/1.1 204 No Content
Content-Length: 0
X-Terraform-Get: /api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file?token=&archive=tgz
```

En coulisses, ce point de terminaison d'API redirige vers `packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/download`

## Récupérer l'URL de téléchargement pour une version spécifique du module {#retrieve-download-url-for-a-specific-module-version}

Récupérez l'URL de téléchargement pour une version de module spécifiée dans l'en-tête `X-Terraform-Get`.

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/download
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | oui | Le groupe auquel appartient le projet du module Terraform. |
| `module_name` | string | oui | Le nom du module. |
| `module_system` | string | oui | Le nom du système de module ou du [fournisseur](https://www.terraform.io/registry/providers). |
| `module_version` | string | oui | Version spécifique du module à télécharger. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/download"
```

Exemple de réponse :

```plaintext
HTTP/1.1 204 No Content
Content-Length: 0
X-Terraform-Get: /api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file?token=&archive=tgz
```

## Télécharger un module {#download-module}

### Depuis un espace de nommage {#from-a-namespace}

```plaintext
GET packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/file
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `module_namespace` | string | oui | Le groupe auquel appartient le projet du module Terraform. |
| `module_name` | string | oui | Le nom du module. |
| `module_system` | string | oui | Le nom du système de module ou du [fournisseur](https://www.terraform.io/registry/providers). |
| `module_version` | string | oui | Version spécifique du module à télécharger. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file"
```

Pour écrire la sortie dans un fichier :

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/terraform/modules/v1/group/hello-world/local/1.0.0/file" \
  --output hello-world-local.tgz
```

### Depuis un projet {#from-a-project}

```plaintext
GET /projects/:id/packages/terraform/modules/:module_name/:module_system/:module_version
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le chemin encodé en URL du projet. |
| `module_name` | string | oui | Le nom du module. |
| `module_system` | string | oui | Le nom du système de module ou du [fournisseur](https://www.terraform.io/registry/providers). |
| `module_version` | string | non | Version spécifique du module à télécharger. Si omis, la dernière version est téléchargée. |

```shell
curl --user "<username>:<personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/terraform/modules/hello-world/local/1.0.0"
```

Pour écrire la sortie dans un fichier :

```shell
curl --user "<username>:<personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/terraform/modules/hello-world/local/1.0.0" \
  --output hello-world-local.tgz
```

## Charger un module {#upload-module}

Chargez un module pour un projet spécifié.

```plaintext
PUT /projects/:id/packages/terraform/modules/:module-name/:module-system/:module-version/file
```

| Attribut        | Type              | Obligatoire | Description |
|------------------|-------------------|----------|-------------|
| `id`             | entier ou chaîne | oui      | L'ID ou le chemin encodé en URL du projet. |
| `module-name`    | string            | oui      | Le nom du module. |
| `module-system`  | string            | oui      | Le nom du système de module ou du [fournisseur](https://www.terraform.io/registry/providers). |
| `module-version` | string            | oui      | Version spécifique du module à charger. |

```shell
curl --fail-with-body \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --upload-file path/to/file.tgz \
   --url  "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/terraform/modules/my-module/my-system/0.0.1/file"
```

Jetons pouvant être utilisés pour s'authentifier :

| En-tête          | Valeur |
|-----------------|-------|
| `PRIVATE-TOKEN` | Un [jeton d'accès personnel](../../user/profile/personal_access_tokens.md) avec la portée `api`. |
| `DEPLOY-TOKEN`  | Un [jeton de déploiement](../../user/project/deploy_tokens/_index.md) avec la portée `write_package_registry`. |
| `JOB-TOKEN`     | Un [job token](../../ci/jobs/ci_job_token.md). |

Exemple de réponse :

```json
{
  "message": "201 Created"
}
```
