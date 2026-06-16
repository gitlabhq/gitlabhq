---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des artefacts de job
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour télécharger, conserver et supprimer les [artefacts de job](../ci/jobs/job_artifacts.md).

## Télécharger les artefacts de job par ID de job {#download-job-artifacts-by-job-id}

Téléchargez l'archive des artefacts d'un job en utilisant un ID de job.

Si vous utilisez cURL pour télécharger des artefacts depuis GitLab.com, utilisez le paramètre `--location` car la requête peut être redirigée via un CDN.

```plaintext
GET /projects/:id/jobs/:job_id/artifacts
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
| ----------- | ----------------- | -------- | ----------- |
| `id`        | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `job_id`    | entier           | Oui      | ID d'un job. |
| `job_token` | string            | Non       | Jeton de job CI/CD pour les pipelines multi-projets. Premium et Ultimate uniquement. |

En cas de succès, retourne [`200`](rest/troubleshooting.md#status-codes) et sert le fichier d'artefacts.

Exemple de requête :

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts" \
  --output artifacts.zip
```

Exemple de requête utilisant un jeton de job CI/CD :

```yaml
# Uses the job_token parameter
artifact_download:
  stage: test
  script:
    - 'curl --request GET \
         --location \
         --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts?job_token=$CI_JOB_TOKEN" \
         --output artifacts.zip'
```

## Télécharger les artefacts de job par nom de référence {#download-job-artifacts-by-reference-name}

{{< history >}}

- L'attribut `search_recent_successful_pipelines` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/515864) dans GitLab 18.7 [avec un flag](../administration/feature_flags/_index.md) nommé `ci_search_recent_successful_pipelines`. Désactivé par défaut.
- Le feature flag `ci_search_recent_successful_pipelines` a été supprimé dans GitLab 18.10

{{< /history >}}

Téléchargez l'archive des artefacts d'un job depuis le dernier pipeline réussi en utilisant un nom de référence. Lorsque `search_recent_successful_pipelines=true`, la recherche inclut jusqu'à 100 pipelines réussis récents pour la référence spécifiée.

Le dernier pipeline réussi est déterminé en fonction de l'heure de création. L'heure de début ou de fin des jobs individuels n'a pas d'incidence sur le pipeline le plus récent.

Pour les [pipelines parent et enfant](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines), les artefacts sont recherchés dans un ordre hiérarchique du parent vers l'enfant. Si les pipelines parent et enfant ont tous les deux un job portant le même nom, l'artefact du pipeline parent est retourné.

Prérequis :

- Vous devez disposer d'un pipeline terminé avec un statut `success`.
- Si le pipeline inclut des jobs manuels, ceux-ci doivent soit :
  - Se terminer avec succès.
  - Avoir `allow_failure: true` défini.

Si vous utilisez cURL pour télécharger des artefacts depuis GitLab.com, utilisez le paramètre `--location` car la requête peut être redirigée via un CDN.

```plaintext
GET /projects/:id/jobs/artifacts/:ref_name/download?job=name
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
| ----------- | ----------------- | -------- | ----------- |
| `id`        | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `job`       | string            | Oui      | Le nom du job. |
| `ref_name`  | string            | Oui      | Nom de branche ou de tag dans le dépôt. Les références HEAD ou SHA ne sont pas prises en charge. Pour les pipelines de merge request, utilisez `refs/merge-requests/:iid/head` à la place du nom de branche. |
| `job_token` | string            | Non       | Jeton de job CI/CD pour les pipelines multi-projets. Premium et Ultimate uniquement. |
| `search_recent_successful_pipelines` | boolean | Non | Recherche parmi les pipelines réussis récents plutôt que parmi uniquement le dernier. La valeur par défaut est `false`. |

En cas de succès, retourne [`200`](rest/troubleshooting.md#status-codes) et sert le fichier d'artefacts.

Si le job ou les artefacts sont introuvables, retourne [`404`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test"
```

Exemple de requête utilisant un jeton de job CI/CD :

```yaml
# Uses the job_token parameter
artifact_download:
  stage: test
  script:
    - 'curl --request GET \
         --location \
         --url "https://gitlab.example.com/api/v4/projects/$CI_PROJECT_ID/jobs/artifacts/main/download?job=test&job_token=$CI_JOB_TOKEN" \
         --output artifacts.zip'
```

Exemple de requête avec recherche dans les pipelines récents :

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test&search_recent_successful_pipelines=true"
```

## Télécharger un seul fichier d'artefact par ID de job {#download-a-single-artifact-file-by-job-id}

Téléchargez un seul fichier depuis les artefacts d'un job en utilisant un ID de job. Le fichier est extrait de l'archive et transmis en flux au client.

Si vous utilisez cURL pour télécharger des artefacts depuis GitLab.com, utilisez le paramètre `--location` car la requête peut être redirigée via un CDN.

```plaintext
GET /projects/:id/jobs/:job_id/artifacts/*artifact_path
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
| --------------- | ----------------- | -------- | ----------- |
| `artifact_path` | string            | Oui      | Chemin vers un fichier à l'intérieur de l'archive d'artefacts. |
| `id`            | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `job_id`        | entier           | Oui      | L'identifiant unique du job. |
| `job_token`     | string            | Non       | Jeton de job CI/CD pour les pipelines multi-projets. Premium et Ultimate uniquement. |

En cas de succès, retourne [`200`](rest/troubleshooting.md#status-codes) et envoie un seul fichier d'artefact.

Exemple de requête :

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/5/artifacts/some/release/file.pdf"
```

## Lister tous les fichiers dans l'archive d'artefacts {#list-all-files-in-the-artifacts-archive}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/31448) dans GitLab 18.8.

{{< /history >}}

Listez tous les fichiers et répertoires dans l'archive d'artefacts d'un job spécifié. Cette opération lit les métadonnées de l'artefact sans extraire l'archive complète, ce qui la rend efficace pour parcourir de grandes archives.

```plaintext
GET /projects/:id/jobs/:job_id/artifacts/tree
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
| ----------- | ----------------- | -------- | ----------- |
| `id`        | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `job_id`    | entier           | Oui      | ID d'un job. |
| `path`      | string            | Non       | Chemin à parcourir dans l'archive d'artefacts. Par défaut, le répertoire racine. |
| `recursive` | boolean           | Non       | Si `true`, retourne toutes les entrées de manière récursive. Par défaut : `false`. |
| `job_token` | string            | Non       | Jeton de job CI/CD utilisé pour déclencher un pipeline multi-projets. Premium et Ultimate uniquement. |

Ce point de terminaison prend en charge la [pagination](rest/_index.md#pagination).

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type    | Description |
|-----------|---------|-------------|
| `name`    | string  | Nom du fichier ou du répertoire. |
| `path`    | string  | Chemin complet dans l'archive d'artefacts. Les répertoires incluent une barre oblique finale. |
| `type`    | string  | Type d'entrée. Valeurs possibles : `file`, `directory`. |
| `size`    | entier | Taille du fichier en octets. Présent uniquement pour les fichiers. |
| `mode`    | string  | Mode de fichier Unix au format octal. Par exemple, `100644` pour les fichiers ou `040755` pour les répertoires. |

Si le job, les artefacts, les métadonnées d'artefact ou le chemin spécifié sont introuvables, retourne [`404`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts/tree"
```

Exemple de réponse :

```json
[
  {
    "name": "ci_build_artifacts.zip",
    "path": "ci_build_artifacts.zip",
    "type": "file",
    "size": 1024,
    "mode": "100644"
  },
  {
    "name": "other_artifacts_0.1.2",
    "path": "other_artifacts_0.1.2/",
    "type": "directory",
    "mode": "040755"
  }
]
```

Exemple de requête pour parcourir un sous-répertoire :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts/tree?path=coverage/reports"
```

Exemple de requête pour un listage récursif :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts/tree?recursive=true"
```

Exemple de requête utilisant un jeton de job CI/CD :

```yaml
# Uses the job_token parameter
list_artifacts:
  stage: test
  script:
    - 'curl --request GET \
         --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts/tree?job_token=$CI_JOB_TOKEN"'
```

## Télécharger un seul fichier d'artefact par nom de référence {#download-a-single-artifact-file-by-reference-name}

{{< history >}}

- L'attribut `search_recent_successful_pipelines` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/515864) dans GitLab 18.9 [avec un flag](../administration/feature_flags/_index.md) nommé `ci_search_recent_successful_pipelines`. Désactivé par défaut.
- Le feature flag `ci_search_recent_successful_pipelines` a été supprimé dans GitLab 18.10

{{< /history >}}

Téléchargez un seul fichier depuis les artefacts d'un job dans le dernier pipeline réussi en utilisant le nom de référence. Le fichier est extrait de l'archive et transmis en flux au client avec le type de contenu `plain/text`. Lorsque `search_recent_successful_pipelines=true`, la recherche inclut jusqu'à 100 pipelines réussis récents pour la référence spécifiée.

Pour les [pipelines parent et enfant](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines), les artefacts sont recherchés dans un ordre hiérarchique du parent vers l'enfant. Si les pipelines parent et enfant ont tous les deux un job portant le même nom, l'artefact du pipeline parent est retourné.

Le fichier d'artefact fournit plus de détails que ce qui est disponible dans l'[export CSV](../user/application_security/vulnerability_report/_index.md#exporting).

Prérequis :

- Vous devez disposer d'un pipeline terminé avec un statut `success`.
- Si le pipeline inclut des jobs manuels, ceux-ci doivent soit :
  - Se terminer avec succès.
  - Avoir `allow_failure: true` défini.
- Pour effectuer une recherche dans les pipelines réussis récents, le feature flag `ci_search_recent_successful_pipelines` doit être activé pour le projet.

Si vous utilisez cURL pour télécharger des artefacts depuis GitLab.com, utilisez le paramètre `--location` car la requête peut être redirigée via un CDN.

```plaintext
GET /projects/:id/jobs/artifacts/:ref_name/raw/*artifact_path?job=name
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
| --------------- | ----------------- | -------- | ----------- |
| `artifact_path` | string            | Oui      | Chemin vers un fichier à l'intérieur de l'archive d'artefacts. |
| `id`            | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `job`           | string            | Oui      | Le nom du job. |
| `ref_name`      | string            | Oui      | Nom de branche ou de tag dans le dépôt. Les références `HEAD` ou `SHA` ne sont pas prises en charge. Pour les pipelines de merge request, utilisez `refs/merge-requests/:iid/head` à la place du nom de branche. |
| `job_token`     | string            | Non       | Jeton de job CI/CD pour les pipelines multi-projets. Premium et Ultimate uniquement. |
| `search_recent_successful_pipelines` | boolean | Non | Recherche parmi les pipelines réussis récents plutôt que parmi uniquement le dernier. La valeur par défaut est `false`. |

En cas de succès, retourne [`200`](rest/troubleshooting.md#status-codes) et envoie un seul fichier d'artefact.

Si le job ou le fichier d'artefact sont introuvables, retourne [`404`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/raw/some/release/file.pdf?job=pdf"
```

Exemple de requête avec recherche dans les pipelines récents :

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/raw/some/release/file.pdf?job=pdf&search_recent_successful_pipelines=true"
```

## Conserver les artefacts de job {#keep-job-artifacts}

Empêchez la suppression automatique des artefacts d'un job lorsqu'ils atteignent leur date d'expiration.

```plaintext
POST /projects/:id/jobs/:job_id/artifacts/keep
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `job_id`  | entier           | Oui      | ID d'un job. |

En cas de succès, retourne [`200`](rest/troubleshooting.md#status-codes) et les détails du job.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/artifacts/keep"
```

Exemple de réponse :

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "allow_failure": false,
  "download_url": null,
  "id": 42,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "stage": "test",
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:13:33.506Z",
  "finished_at": "2016-01-11T10:15:10.506Z",
  "duration": 97.0,
  "status": "failed",
  "failure_reason": "script_failure",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/42",
  "user": null
}
```

## Supprimer les artefacts de job {#delete-job-artifacts}

Supprimez tous les artefacts associés à un job spécifique. Les artefacts ne peuvent pas être récupérés après leur suppression.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

```plaintext
DELETE /projects/:id/jobs/:job_id/artifacts
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `job_id`  | entier           | Oui      | ID d'un job. |

En cas de succès, retourne [`204 No Content`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/artifacts"
```

## Supprimer tous les artefacts de job dans un projet {#delete-all-job-artifacts-in-a-project}

Supprimez tous les artefacts de job éligibles à la suppression dans un projet. Les artefacts ne peuvent pas être récupérés après leur suppression.

Par défaut, les artefacts du [pipeline réussi le plus récent de chaque ref](../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs) ne sont pas supprimés.

Les requêtes adressées à ce point de terminaison définissent l'expiration de tous les artefacts de job pouvant être supprimés à l'heure actuelle. Les fichiers sont ensuite supprimés du système dans le cadre du nettoyage régulier des artefacts de job expirés. Les job logs ne sont jamais supprimés.

Le nettoyage régulier s'effectue de manière asynchrone selon un calendrier, il peut donc y avoir un court délai avant la suppression des artefacts.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

```plaintext
DELETE /projects/:id/artifacts
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

En cas de succès, retourne [`202 Accepted`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/artifacts"
```

## Dépannage {#troubleshooting}

### Utilisation des noms de branche avec les pipelines de merge request {#using-branch-names-with-merge-request-pipelines}

Vous pouvez obtenir une erreur `404 Not Found` lorsque vous tentez de télécharger des artefacts de job en utilisant un nom de branche comme `ref_name`.

Ce problème se produit car les pipelines de merge request utilisent un format de référence différent de celui des pipelines de branche. Les pipelines de merge request s'exécutent sur `refs/merge-requests/:iid/head`, pas directement sur la branche source.

Pour télécharger les artefacts de job d'un pipeline de merge request, utilisez `refs/merge-requests/:iid/head` comme `ref_name` à la place du nom de branche, où `:iid` est l'ID du merge request. Dans les pipelines de merge request, l'ID est disponible depuis la variable `$CI_MERGE_REQUEST_IID` et le `ref_name` complet depuis la variable `$CI_MERGE_REQUEST_REF_PATH`.

Par exemple, pour le merge request `!123` :

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/refs/merge-requests/123/head/raw/file.txt?job=test"
```

### Téléchargement de fichiers `artifacts:reports` {#downloading-artifactsreports-files}

Vous pouvez obtenir une erreur `404 Not Found` lorsque vous tentez de télécharger des rapports via l'API des artefacts de job.

Ce problème se produit car les [rapports](../ci/yaml/_index.md#artifactsreports) ne sont pas téléchargeables par défaut.

Pour rendre les rapports téléchargeables, ajoutez leurs noms de fichiers ou `gl-*-report.json` à [`artifacts:paths`](../ci/yaml/_index.md#artifactspaths).
