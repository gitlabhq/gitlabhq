---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API de release de projet
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [releases](../../user/project/releases/_index.md) de projets.

> [!note]
> Pour interagir avec les releases d'un groupe, consultez l'[API de release de groupe](../group_releases.md).
>
> Pour interagir avec les liens en tant que ressource associée à une release, consultez l'[API de liens de release](links.md).

## Authentification {#authentication}

Pour l'authentification, l'API Releases accepte l'un ou l'autre des éléments suivants :

- Un [jeton d'accès personnel](../../user/profile/personal_access_tokens.md) en utilisant l'en-tête `PRIVATE-TOKEN`.
- Le [jeton de job CI/CD GitLab](../../ci/jobs/ci_job_token.md) `$CI_JOB_TOKEN` en utilisant l'en-tête `JOB-TOKEN`.

## Lister les releases {#list-releases}

Renvoie une liste paginée de releases, triées par `released_at`.

```plaintext
GET /projects/:id/releases
```

| Attribut     | Type           | Obligatoire | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](../rest/_index.md#namespaced-paths). |
| `order_by`    | string         | non       | Le champ à utiliser pour le tri. Soit `released_at` (par défaut) ou `created_at`. |
| `sort`        | string         | non       | Le sens du tri. Soit `desc` (par défaut) pour l'ordre décroissant ou `asc` pour l'ordre croissant. |
| `include_html_description` | boolean        | non       | Si `true`, la réponse inclut le Markdown rendu en HTML de la description de la release.   |

En cas de succès, renvoie [`200 OK`](../rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                             | Type   | Description                                      |
|:--------------------------------------|:-------|:-------------------------------------------------|
| `[]._links`                           | objet | Liens de la release.                            |
| `[]._links.closed_issues_url`         | string | URL HTTP des tickets fermés de la release.         |
| `[]._links.closed_merge_requests_url` | string | URL HTTP des merge requests fermées de la release. |
| `[]._links.edit_url`                  | string | URL HTTP de la page de modification de la release.             |
| `[]._links.merged_merge_requests_url` | string | URL HTTP des merge requests fusionnées de la release. |
| `[]._links.opened_issues_url`         | string | URL HTTP des tickets ouverts de la release.           |
| `[]._links.opened_merge_requests_url` | string | URL HTTP des merge requests ouvertes de la release.   |
| `[]._links.self`                      | string | URL HTTP de la release.                         |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases"
```

Exemple de réponse :

```json
[
   {
      "tag_name":"v0.2",
      "description":"## CHANGELOG\r\n\r\n- Escape label and milestone titles to prevent XSS in GLFM autocomplete. !2740\r\n- Prevent private snippets from being embeddable.\r\n- Add subresources removal to member destroy service.",
      "name":"Awesome app v0.2 beta",
      "created_at":"2019-01-03T01:56:19.539Z",
      "released_at":"2019-01-03T01:56:19.539Z",
      "author":{
         "id":1,
         "name":"Administrator",
         "username":"root",
         "state":"active",
         "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
         "web_url":"https://gitlab.example.com/root"
      },
      "commit":{
         "id":"079e90101242458910cccd35eab0e211dfc359c0",
         "short_id":"079e9010",
         "title":"Update README.md",
         "created_at":"2019-01-03T01:55:38.000Z",
         "parent_ids":[
            "f8d3d94cbd347e924aa7b715845e439d00e80ca4"
         ],
         "message":"Update README.md",
         "author_name":"Administrator",
         "author_email":"admin@example.com",
         "authored_date":"2019-01-03T01:55:38.000Z",
         "committer_name":"Administrator",
         "committer_email":"admin@example.com",
         "committed_date":"2019-01-03T01:55:38.000Z"
      },
      "milestones": [
         {
            "id":51,
            "iid":1,
            "project_id":24,
            "title":"v1.0-rc",
            "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
            "state":"closed",
            "created_at":"2019-07-12T19:45:44.256Z",
            "updated_at":"2019-07-12T19:45:44.256Z",
            "due_date":"2019-08-16",
            "start_date":"2019-07-30",
            "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/1",
            "issue_stats": {
               "total": 98,
               "closed": 76
            }
         },
         {
            "id":52,
            "iid":2,
            "project_id":24,
            "title":"v1.0",
            "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
            "state":"closed",
            "created_at":"2019-07-16T14:00:12.256Z",
            "updated_at":"2019-07-16T14:00:12.256Z",
            "due_date":"2019-08-16",
            "start_date":"2019-07-30",
            "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/2",
            "issue_stats": {
               "total": 24,
               "closed": 21
            }
         }
      ],
      "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
      "tag_path":"/root/awesome-app/-/tags/v0.11.1",
      "assets":{
         "count":6,
         "sources":[
            {
               "format":"zip",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.zip"
            },
            {
               "format":"tar.gz",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.tar.gz"
            },
            {
               "format":"tar.bz2",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.tar.bz2"
            },
            {
               "format":"tar",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.tar"
            }
         ],
         "links":[
            {
               "id":2,
               "name":"awesome-v0.2.msi",
               "url":"http://192.168.10.15:3000/msi",
               "link_type":"other"
            },
            {
               "id":1,
               "name":"awesome-v0.2.dmg",
               "url":"http://192.168.10.15:3000",
               "link_type":"other"
            }
         ],
         "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.2/evidence.json"
      },
      "evidences":[
        {
          "sha": "760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
          "filepath": "https://gitlab.example.com/root/awesome-app/-/releases/v0.2/evidence.json",
          "collected_at": "2019-01-03T01:56:19.539Z"
        }
     ]
   },
   {
      "tag_name":"v0.1",
      "description":"## CHANGELOG\r\n\r\n-Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
      "name":"Awesome app v0.1 alpha",
      "created_at":"2019-01-03T01:55:18.203Z",
      "released_at":"2019-01-03T01:55:18.203Z",
      "author":{
         "id":1,
         "name":"Administrator",
         "username":"root",
         "state":"active",
         "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
         "web_url":"https://gitlab.example.com/root"
      },
      "commit":{
         "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
         "short_id":"f8d3d94c",
         "title":"Initial commit",
         "created_at":"2019-01-03T01:53:28.000Z",
         "parent_ids":[

         ],
         "message":"Initial commit",
         "author_name":"Administrator",
         "author_email":"admin@example.com",
         "authored_date":"2019-01-03T01:53:28.000Z",
         "committer_name":"Administrator",
         "committer_email":"admin@example.com",
         "committed_date":"2019-01-03T01:53:28.000Z"
      },
      "assets":{
         "count":4,
         "sources":[
            {
               "format":"zip",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
            },
            {
               "format":"tar.gz",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
            },
            {
               "format":"tar.bz2",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
            },
            {
               "format":"tar",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
            }
         ],
         "links":[

         ],
         "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json"
      },
      "evidences":[
        {
          "sha": "c3ffedec13af470e760d6cdfb08790f71cf52c6cde4d",
          "filepath": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json",
          "collected_at": "2019-01-03T01:55:18.203Z"
        }
      ],
      "_links": {
         "closed_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=closed",
         "closed_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=closed",
         "edit_url": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/edit",
         "merged_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=merged",
         "opened_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=opened",
         "opened_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=opened",
         "self": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1"
      }
   }
]
```

## Obtenir une release par nom d'étiquette {#get-a-release-by-a-tag-name}

Récupère une release pour l'étiquette donnée.

```plaintext
GET /projects/:id/releases/:tag_name
```

| Attribut                  | Type           | Obligatoire | Description                                                                         |
|----------------------------| -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`                       | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](../rest/_index.md#namespaced-paths).  |
| `tag_name`                 | string         | oui      | L'étiquette Git à laquelle la release est associée.                                         |
| `include_html_description` | boolean        | non       | Si `true`, la réponse inclut le Markdown rendu en HTML de la description de la release.   |

En cas de succès, renvoie [`200 OK`](../rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                             | Type   | Description                                      |
|:--------------------------------------|:-------|:-------------------------------------------------|
| `[]._links`                           | objet | Liens de la release.                            |
| `[]._links.closed_issues_url`         | string | URL HTTP des tickets fermés de la release.         |
| `[]._links.closed_merge_requests_url` | string | URL HTTP des merge requests fermées de la release. |
| `[]._links.edit_url`                  | string | URL HTTP de la page de modification de la release.             |
| `[]._links.merged_merge_requests_url` | string | URL HTTP des merge requests fusionnées de la release. |
| `[]._links.opened_issues_url`         | string | URL HTTP des tickets ouverts de la release.           |
| `[]._links.opened_merge_requests_url` | string | URL HTTP des merge requests ouvertes de la release.   |
| `[]._links.self`                      | string | URL HTTP de la release.                         |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1"
```

Exemple de réponse :

```json
{
   "tag_name":"v0.1",
   "description":"## CHANGELOG\r\n\r\n- Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
   "name":"Awesome app v0.1 alpha",
   "created_at":"2019-01-03T01:55:18.203Z",
   "released_at":"2019-01-03T01:55:18.203Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
      "short_id":"f8d3d94c",
      "title":"Initial commit",
      "created_at":"2019-01-03T01:53:28.000Z",
      "parent_ids":[

      ],
      "message":"Initial commit",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:53:28.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:53:28.000Z"
   },
   "milestones": [
       {
         "id":51,
         "iid":1,
         "project_id":24,
         "title":"v1.0-rc",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-12T19:45:44.256Z",
         "updated_at":"2019-07-12T19:45:44.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/1",
         "issue_stats": {
            "total": 98,
            "closed": 76
         }
       },
       {
         "id":52,
         "iid":2,
         "project_id":24,
         "title":"v1.0",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-16T14:00:12.256Z",
         "updated_at":"2019-07-16T14:00:12.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/2",
         "issue_stats": {
            "total": 24,
            "closed": 21
         }
       }
   ],
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "assets":{
      "count":5,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
         }
      ],
      "links":[
         {
            "id":3,
            "name":"hoge",
            "url":"https://gitlab.example.com/root/awesome-app/-/tags/v0.11.1/binaries/linux-amd64",
            "link_type":"other"
         }
      ]
   },
   "evidences":[
     {
       "sha": "760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
       "filepath": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json",
       "collected_at": "2019-07-16T14:00:12.256Z"
     },
   "_links": {
      "closed_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=closed",
      "closed_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=closed",
      "edit_url": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/edit",
      "merged_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=merged",
      "opened_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=opened",
      "opened_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=opened",
      "self": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1"
    }
  ]
}
```

## Télécharger une ressource associée à une release {#download-a-release-asset}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/358188) dans GitLab 15.4.

{{< /history >}}

Téléchargez un fichier de ressource associée à une release en effectuant une requête avec le format suivant :

```plaintext
GET /projects/:id/releases/:tag_name/downloads/:direct_asset_path
```

| Attribut                  | Type           | Obligatoire | Description                                                                         |
|----------------------------| -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`                       | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](../rest/_index.md#namespaced-paths).  |
| `tag_name`                 | string         | oui      | L'étiquette Git à laquelle la release est associée.                                         |
| `direct_asset_path`        | string         | oui      | Chemin vers le fichier de ressource associée à une release tel que spécifié lors de sa [création](links.md#create-a-release-link) ou de sa [mise à jour](links.md#update-a-release-link). |

Exemple de requête :

```shell
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/downloads/bin/asset.exe"
```

### Obtenir la dernière release {#get-the-latest-release}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/358188) dans GitLab 15.4.

{{< /history >}}

Les informations sur la dernière release sont accessibles via une URL d'API permanente.

Le format de l'URL est :

```plaintext
GET /projects/:id/releases/permalink/latest
```

Pour appeler toute autre API GET nécessitant une étiquette de release, ajoutez un suffixe au chemin d'API `permalink/latest`.

Par exemple, pour obtenir la dernière [preuve de release](#collect-release-evidence), vous pouvez utiliser :

```plaintext
GET /projects/:id/releases/permalink/latest/evidence
```

Un autre exemple est le [téléchargement d'une ressource](#download-a-release-asset) de la dernière release, pour lequel vous pouvez utiliser :

```plaintext
GET /projects/:id/releases/permalink/latest/downloads/bin/asset.exe
```

#### Préférences de tri {#sorting-preferences}

Par défaut, GitLab récupère la release en utilisant l'heure `released_at`. L'utilisation du paramètre de requête `?order_by=released_at` est facultative, et la prise en charge de `?order_by=semver` est suivie [dans le ticket 352945](https://gitlab.com/gitlab-org/gitlab/-/issues/352945).

## Créer une release {#create-a-release}

Crée une release. Un accès de niveau Developer au projet est requis pour créer une release.

```plaintext
POST /projects/:id/releases
```

| Attribut          | Type            | Obligatoire                    | Description                                                                                                                      |
| -------------------| --------------- | --------                    | -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | entier ou chaîne  | oui                         | L'ID ou le [chemin encodé en URL du projet](../rest/_index.md#namespaced-paths).                                              |
| `name`             | string          | non                          | Le nom de la release.                                                                                                                |
| `tag_name`         | string          | oui                         | L'étiquette à partir de laquelle la release est créée.                                                                                  |
| `tag_message`      | string          | non                          | Message à utiliser lors de la création d'une nouvelle étiquette annotée.                                                                                  |
| `description`      | string          | non                          | La description de la release. Vous pouvez utiliser [Markdown](../../user/markdown.md).                                                  |
| `ref`              | string          | oui, si `tag_name` n'existe pas | Si une étiquette spécifiée dans `tag_name` n'existe pas, la release est créée à partir de `ref` et étiquetée avec `tag_name`. Il peut s'agir d'un SHA de commit, d'un autre nom d'étiquette ou d'un nom de branche. |
| `milestones`       | tableau de chaînes | non                          | Le titre de chaque jalon auquel la release est associée. Les clients [GitLab Premium](https://about.gitlab.com/pricing/) peuvent spécifier des jalons de groupe.                                                                      |
| `assets:links`     | tableau de hash   | non                          | Un tableau de liens vers des ressources.                                                                                                        |
| `assets:links:name`| string          | requis par : `assets:links` | Le nom du lien. Les noms de liens doivent être uniques au sein de la release.                                                              |
| `assets:links:url` | string          | requis par : `assets:links` | L'URL du lien. Les URL de liens doivent être uniques au sein de la release.                                                                |
| `assets:links:direct_asset_path` | string     | non | Chemin facultatif pour un [lien direct vers une ressource](../../user/project/releases/release_fields.md#permanent-links-to-release-assets). |
| `assets:links:link_type` | string     | non | Le type du lien : `other`, `runbook`, `image`, `package`. La valeur par défaut est `other`. |
| `released_at`      | datetime        | non                          | Date et heure de la release. La valeur par défaut est l'heure actuelle. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). Ne fournissez ce champ que lors de la création d'une release [à venir](../../user/project/releases/_index.md#upcoming-releases) ou [historique](../../user/project/releases/_index.md#historical-releases).  |

Exemple de requête :

```shell
curl --header 'Content-Type: application/json' --header "PRIVATE-TOKEN: <your_access_token>" \
     --data '{ "name": "New release", "tag_name": "v0.3", "description": "Super nice release", "milestones": ["v1.0", "v1.0-rc"], "assets": { "links": [{ "name": "hoge", "url": "https://google.com", "direct_asset_path": "/binaries/linux-amd64", "link_type":"other" }] } }' \
     --request POST "https://gitlab.example.com/api/v4/projects/24/releases"
```

Exemple de réponse :

```json
{
   "tag_name":"v0.3",
   "description":"Super nice release",
   "name":"New release",
   "created_at":"2019-01-03T02:22:45.118Z",
   "released_at":"2019-01-03T02:22:45.118Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"079e90101242458910cccd35eab0e211dfc359c0",
      "short_id":"079e9010",
      "title":"Update README.md",
      "created_at":"2019-01-03T01:55:38.000Z",
      "parent_ids":[
         "f8d3d94cbd347e924aa7b715845e439d00e80ca4"
      ],
      "message":"Update README.md",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:55:38.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:55:38.000Z"
   },
   "milestones": [
       {
         "id":51,
         "iid":1,
         "project_id":24,
         "title":"v1.0-rc",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-12T19:45:44.256Z",
         "updated_at":"2019-07-12T19:45:44.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/1",
         "issue_stats": {
            "total": 99,
            "closed": 76
         }
       },
       {
         "id":52,
         "iid":2,
         "project_id":24,
         "title":"v1.0",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-16T14:00:12.256Z",
         "updated_at":"2019-07-16T14:00:12.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/2",
         "issue_stats": {
            "total": 24,
            "closed": 21
         }
       }
   ],
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "evidence_sha":"760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
   "assets":{
      "count":5,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.tar"
         }
      ],
      "links":[
         {
            "id":3,
            "name":"hoge",
            "url":"https://gitlab.example.com/root/awesome-app/-/tags/v0.11.1/binaries/linux-amd64",
            "link_type":"other"
         }
      ],
      "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.3/evidence.json"
   }
}
```

### Jalons de groupe {#group-milestones}

{{< details >}}

- Édition :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les jalons de groupe associés au projet peuvent être spécifiés dans le tableau `milestones` pour les appels d'API [Créer une release](#create-a-release) et [Mettre à jour une release](#update-a-release). Seuls les jalons associés au groupe du projet peuvent être spécifiés ; l'ajout de jalons pour les groupes ancêtres génère une erreur.

## Collecter des preuves de release {#collect-release-evidence}

{{< details >}}

- Édition :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Crée une preuve de release pour une release existante.

```plaintext
POST /projects/:id/releases/:tag_name/evidence
```

| Attribut     | Type           | Obligatoire | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](../rest/_index.md#namespaced-paths). |
| `tag_name`    | string         | oui      | L'étiquette Git à laquelle la release est associée.                                         |

Exemple de requête :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/evidence"
```

Exemple de réponse :

```json
200
```

## Mettre à jour une release {#update-a-release}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72448) pour autoriser `JOB-TOKEN` dans GitLab 14.5.

{{< /history >}}

Met à jour une release. Un accès de niveau Developer au projet est requis pour mettre à jour une release.

```plaintext
PUT /projects/:id/releases/:tag_name
```

| Attribut     | Type            | Obligatoire | Description                                                                                                 |
| ------------- | --------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `id`          | entier ou chaîne  | oui      | L'ID ou le [chemin encodé en URL du projet](../rest/_index.md#namespaced-paths).                         |
| `tag_name`    | string          | oui      | L'étiquette Git à laquelle la release est associée.                                                                 |
| `name`        | string          | non       | Le nom de la release.                                                                                           |
| `description` | string          | non       | La description de la release. Vous pouvez utiliser [Markdown](../../user/markdown.md).                             |
| `milestones`  | tableau de chaînes | non       | Le titre de chaque jalon à associer à la release. Les clients [GitLab Premium](https://about.gitlab.com/pricing/) peuvent spécifier des jalons de groupe. Pour supprimer tous les jalons de la release, spécifiez `[]`. |
| `released_at` | datetime        | non       | La date à laquelle la release est/était prête. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`).          |

Exemple de requête :

```shell
curl --header 'Content-Type: application/json' --request PUT --data '{"name": "new name", "milestones": ["v1.2"]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1"
```

Exemple de réponse :

```json
{
   "tag_name":"v0.1",
   "description":"## CHANGELOG\r\n\r\n- Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
   "name":"new name",
   "created_at":"2019-01-03T01:55:18.203Z",
   "released_at":"2019-01-03T01:55:18.203Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
      "short_id":"f8d3d94c",
      "title":"Initial commit",
      "created_at":"2019-01-03T01:53:28.000Z",
      "parent_ids":[

      ],
      "message":"Initial commit",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:53:28.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:53:28.000Z"
   },
   "milestones": [
      {
         "id":53,
         "iid":3,
         "project_id":24,
         "title":"v1.2",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"active",
         "created_at":"2019-09-01T13:00:00.256Z",
         "updated_at":"2019-09-01T13:00:00.256Z",
         "due_date":"2019-09-20",
         "start_date":"2019-09-05",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/3",
         "issue_stats": {
            "opened": 11,
            "closed": 78
         }
      }
   ],
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "evidence_sha":"760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
   "assets":{
      "count":4,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
         }
      ],
      "links":[

      ],
      "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json"
   }
}
```

## Supprimer une release {#delete-a-release}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-foss/-/work_items/41766) dans GitLab 11.7.

{{< /history >}}

Supprime une release. La suppression d'une release ne supprime pas l'étiquette associée. Nécessite au minimum le rôle Developer pour le projet.

```plaintext
DELETE /projects/:id/releases/:tag_name
```

| Attribut     | Type           | Obligatoire | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](../rest/_index.md#namespaced-paths). |
| `tag_name`    | string         | oui      | L'étiquette Git à laquelle la release est associée.                                         |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1"
```

Exemple de réponse :

```json
{
   "tag_name":"v0.1",
   "description":"## CHANGELOG\r\n\r\n- Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
   "name":"new name",
   "created_at":"2019-01-03T01:55:18.203Z",
   "released_at":"2019-01-03T01:55:18.203Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
      "short_id":"f8d3d94c",
      "title":"Initial commit",
      "created_at":"2019-01-03T01:53:28.000Z",
      "parent_ids":[

      ],
      "message":"Initial commit",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:53:28.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:53:28.000Z"
   },
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "evidence_sha":"760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
   "assets":{
      "count":4,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
         }
      ],
      "links":[

      ],
      "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json"
   }
}
```

## Releases à venir {#upcoming-releases}

Une release dont l'attribut `released_at` est défini à une date future est étiquetée comme une **Release à venir** [dans l'interface utilisateur](../../user/project/releases/_index.md#upcoming-releases).

De plus, si une [release est demandée via l'API](#list-releases), pour chaque release dont l'attribut `release_at` est défini à une date future, un attribut supplémentaire `upcoming_release` (défini à true) est renvoyé dans la réponse.

## Releases antérieures {#historical-releases}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/199429) dans GitLab 15.2.

{{< /history >}}

Une release dont l'attribut `released_at` est défini à une date passée est étiquetée comme une **Release antérieure** [dans l'interface utilisateur](../../user/project/releases/_index.md#historical-releases).

De plus, si une [release est demandée via l'API](#list-releases), pour chaque release dont l'attribut `release_at` est défini à une date passée, un attribut supplémentaire `historical_release` (défini à true) est renvoyé dans la réponse.
