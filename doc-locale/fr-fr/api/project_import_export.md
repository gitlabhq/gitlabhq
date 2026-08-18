---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API d'import et d'export de projets"
description: "Importez et exportez des projets avec l'API REST."
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour [migrer un projet](../user/project/settings/import_export.md). Si vous migrez d'abord la structure du groupe parent avec l'[API d'import et d'export de groupes](group_import_export.md), vous pouvez préserver les relations au niveau du groupe, telles que les connexions entre les tickets du projet et les epics du groupe.

Après avoir utilisé cette API, vous pouvez utiliser l'[API des variables CI/CD au niveau du projet](project_level_variables.md) pour conserver les variables CI/CD du projet.

Vous devez toujours migrer votre [registre de conteneurs](../user/packages/container_registry/_index.md) via une série d'extractions et d'envois Docker. Réexécutez les pipelines CI/CD pour récupérer les artefacts de build.

Prérequis :

- Pour les exports de projets, consultez [exporter un projet et ses données](../user/project/settings/import_export.md#export-a-project-and-its-data).
- Pour les imports de projets, consultez [importer un projet et ses données](../user/project/settings/import_export.md#import-a-project-and-its-data).

## Exporter un projet {#export-a-project}

Exporte le projet spécifié.

Utilisez le paramètre de hachage `upload` pour téléverser le projet exporté vers un serveur web ou toute plateforme compatible S3. Pour les exports, GitLab :

- Prend uniquement en charge les téléversements de fichiers de données binaires vers le serveur final.
- Envoie l'en-tête `Content-Type: application/gzip` avec les demandes de téléversement. Assurez-vous que votre URL pré-signée inclut ceci dans le cadre de la signature.
- Peut prendre un certain temps pour terminer le processus d'export du projet. Assurez-vous que l'URL de téléversement n'a pas un délai d'expiration court et qu'elle est disponible tout au long du processus d'export.
- Les administrateurs peuvent modifier la taille maximale du fichier d'export. Par défaut, le maximum est illimité (`0`). Pour modifier cela, éditez `max_export_size` en utilisant l'une des méthodes suivantes :
  - [Interface utilisateur GitLab](../administration/settings/import_and_export_settings.md).
  - [API des paramètres d'application](settings.md#update-application-settings)
- A une limite fixe pour la taille maximale du fichier d'import sur GitLab.com. Pour plus d'informations, consultez [les paramètres de compte et de limites](../user/gitlab_com/_index.md#account-and-limit-settings).

Le paramètre `upload[url]` est obligatoire si le paramètre `upload` est présent.

Pour les téléversements vers Amazon S3, reportez-vous aux scripts de documentation [générant une URL pré-signée pour le téléversement d'objets](https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html) afin de générer `upload[url]`. En raison d'un [problème connu](https://gitlab.com/gitlab-org/gitlab/-/issues/430277), vous ne pouvez téléverser que des fichiers d'une taille maximale de 5 Go vers Amazon S3.

```plaintext
POST /projects/:id/export
```

| Attribut             | Type              | Obligatoire | Description |
|-----------------------|-------------------|----------|-------------|
| `id`                  | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `upload[url]`         | string            | Oui      | L'URL vers laquelle téléverser le projet. |
| `description`         | string            | Non       | Remplace la description du projet. |
| `upload`              | hash              | Non       | Hachage contenant les informations pour téléverser le projet exporté vers un serveur web. |
| `upload[http_method]` | string            | Non       | La méthode HTTP pour téléverser le projet exporté. Seules les méthodes `PUT` et `POST` sont autorisées. La valeur par défaut est `PUT`. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export" \
  --data "upload[http_method]=PUT" \
  --data-urlencode "upload[url]=https://example-bucket.s3.eu-west-3.amazonaws.com/backup?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=<your_access_token>%2F20180312%2Feu-west-3%2Fs3%2Faws4_request&X-Amz-Date=20180312T110328Z&X-Amz-Expires=900&X-Amz-SignedHeaders=host&X-Amz-Signature=8413facb20ff33a49a147a0b4abcff4c8487cc33ee1f7e450c46e8f695569dbd"
```

```json
{
  "message": "202 Accepted"
}
```

## Récupérer le statut d'un export de projet {#retrieve-the-status-of-a-project-export}

Récupère le statut de l'export le plus récent pour un projet spécifié.

```plaintext
GET /projects/:id/export
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export"
```

Le statut peut être l'un des suivants :

- `none` :  Aucun export en file d'attente, démarré, terminé ou en cours de régénération.
- `queued` :  La demande d'export est reçue et est en file d'attente pour être traitée.
- `started` :  Le processus d'export a démarré et est en cours. Il comprend :
  - Le processus d'exportation.
  - Les actions effectuées sur le fichier résultant, telles que l'envoi d'un e-mail notifiant l'utilisateur de télécharger le fichier, ou le téléversement du fichier exporté vers un serveur web.
- `finished` :  Une fois le processus d'export terminé et l'utilisateur notifié.
- `regeneration_in_progress` :  Un fichier d'export est disponible au téléchargement, et une demande de génération d'un nouvel export est en cours.

`_links` ne sont présents que lorsque l'export est terminé.

`created_at` est l'horodatage de création du projet, et non l'heure de début de l'export.

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "export_status": "finished",
  "_links": {
    "api_url": "https://gitlab.example.com/api/v4/projects/1/export/download",
    "web_url": "https://gitlab.example.com/gitlab-org/gitlab-test/download_export"
  }
}
```

## Télécharger un export de projet {#download-a-project-export}

Télécharge l'export le plus récent d'un projet spécifié.

```plaintext
GET /projects/:id/export/download
```

| Attribut | Type              | Obligatoire | Description                              |
| --------- | ----------------- | -------- | ---------------------------------------- |
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --remote-header-name \
  --remote-name \
  --url "https://gitlab.example.com/api/v4/projects/5/export/download"
```

```shell
ls *export.tar.gz
2017-12-05_22-11-148_namespace_project_export.tar.gz
```

## Importer un projet depuis une archive locale {#import-a-project-from-a-local-archive}

{{< history >}}

- Exigence du rôle Maintainer au lieu du rôle Developer introduite dans GitLab 16.0.
- Les attributs `namespace_id` et `namespace_path` [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/511053) dans GitLab 18.7.

{{< /history >}}

Importe un projet depuis une archive locale.

```plaintext
POST /projects/import
```

| Attribut         | Type              | Obligatoire | Description |
|-------------------|-------------------|----------|-------------|
| `file`            | string            | Oui      | Le fichier à téléverser. |
| `path`            | string            | Oui      | Nom et chemin du nouveau projet. |
| `name`            | string            | Non       | Le nom du projet à importer. Par défaut, correspond au chemin du projet s'il n'est pas fourni. |
| `namespace`       | entier ou chaîne | Non       | (Obsolète) L'ID ou le chemin de l'espace de nommage dans lequel importer le projet. Par défaut, correspond à l'espace de nommage de l'utilisateur actuel.<br/><br/> Nécessite le rôle Maintainer ou Owner sur le groupe de destination. Utilisez plutôt `namespace_id` ou `namespace_path`. |
| `namespace_id`    | entier           | Non       | L'ID de l'espace de nommage dans lequel importer le projet. Par défaut, correspond à l'espace de nommage de l'utilisateur actuel.<br/><br/> Nécessite le rôle Maintainer ou Owner sur le groupe de destination. |
| `namespace_path`  | string            | Non       | Le chemin de l'espace de nommage dans lequel importer le projet. Par défaut, correspond à l'espace de nommage de l'utilisateur actuel.<br/><br/> Nécessite le rôle Maintainer ou Owner sur le groupe de destination. |
| `override_params` | hash              | Non       | Prend en charge tous les champs définis dans l'[API de projet](projects.md). |
| `overwrite`       | boolean           | Non       | S'il existe un projet avec le même chemin, l'import l'écrase. Par défaut, la valeur est `false`. |

Les paramètres de remplacement passés ont la priorité sur toutes les valeurs définies dans le fichier d'export.

Pour téléverser un fichier depuis votre système de fichiers, utilisez l'argument `--form`. Cela conduit cURL à publier des données en utilisant l'en-tête `Content-Type: multipart/form-data`. Le paramètre `file=` doit pointer vers un fichier sur votre système de fichiers et être précédé de `@`. Par exemple :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "path=api-project" \
  --form "file=@/path/to/file" \
  --url "https://gitlab.example.com/api/v4/projects/import"
```

cURL ne prend pas en charge la publication d'un fichier depuis un serveur distant. Cet exemple importe un projet en utilisant la méthode `open` de Python :

```python
import requests

url =  'https://gitlab.example.com/api/v4/projects/import'
files = { "file": open("project_export.tar.gz", "rb") }
data = {
    "path": "example-project",
    "namespace_path": "example-group"
}
headers = {
    'Private-Token': "<your_access_token>"
}

requests.post(url, headers=headers, data=data, files=files)
```

```json
{
  "id": 1,
  "description": null,
  "name": "api-project",
  "name_with_namespace": "Administrator / api-project",
  "path": "api-project",
  "path_with_namespace": "root/api-project",
  "created_at": "2018-02-13T09:05:58.023Z",
  "import_status": "scheduled",
  "correlation_id": "mezklWso3Za",
  "failed_relations": []
}
```

> [!note]
> La taille maximale du fichier d'import peut être définie par l'administrateur. Sa valeur par défaut est `0` (illimitée). En tant qu'administrateur, vous pouvez modifier la taille maximale du fichier d'import. Pour ce faire, utilisez l'option `max_import_size` dans l'[API des paramètres d'application](settings.md#update-application-settings) ou la [zone **Admin**](../administration/settings/account_and_limit_settings.md).

## Importer un projet depuis une archive distante {#import-a-project-from-a-remote-archive}

{{< details >}}

- Statut : Bêta

{{< /details >}}

{{< history >}}

- Les attributs `namespace_id` et `namespace_path` [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/511053) dans GitLab 18.7.

{{< /history >}}

> [!flag]
> Sur GitLab Self-Managed, cette fonctionnalité est disponible par défaut. Pour masquer la fonctionnalité, un administrateur peut [désactiver le feature flag](../administration/feature_flags/_index.md) nommé `import_project_from_remote_file`. Sur GitLab.com et GitLab Dedicated, cette fonctionnalité est disponible.

Importe un projet depuis une archive distante.

```plaintext
POST /projects/remote-import
```

| Attribut         | Type              | Obligatoire | Description                              |
| ----------------- | ----------------- | -------- | ---------------------------------------- |
| `path`            | string            | Oui      | Nom et chemin du nouveau projet. |
| `url`             | string            | Oui      | URL du fichier à importer. |
| `name`            | string            | Non       | Le nom du projet à importer. S'il n'est pas fourni, correspond par défaut au chemin du projet. |
| `namespace`       | entier ou chaîne | Non       | (Obsolète) L'ID ou le chemin de l'espace de nommage dans lequel importer le projet. Par défaut, correspond à l'espace de nommage de l'utilisateur actuel.<br/><br/> Nécessite le rôle Maintainer ou Owner sur le groupe de destination. Utilisez plutôt `namespace_id` ou `namespace_path`. |
| `namespace_id`    | entier           | Non       | L'ID de l'espace de nommage dans lequel importer le projet. Par défaut, correspond à l'espace de nommage de l'utilisateur actuel.<br/><br/> Nécessite le rôle Maintainer ou Owner sur le groupe de destination. |
| `namespace_path`  | string            | Non       | Le chemin de l'espace de nommage dans lequel importer le projet. Par défaut, correspond à l'espace de nommage de l'utilisateur actuel.<br/><br/> Nécessite le rôle Maintainer ou Owner sur le groupe de destination. |
| `overwrite`       | boolean           | Non       | Si un projet avec le même chemin doit être écrasé lors de l'import. Par défaut, la valeur est `false`. |
| `override_params` | hash              | Non       | Prend en charge tous les champs définis dans l'[API de projet](projects.md). |

Les paramètres de remplacement passés ont la priorité sur toutes les valeurs définies dans le fichier d'export.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/remote-import" \
  --data '{"url":"https://remoteobject/file?token=123123","path":"remote-project"}'
```

```json
{
  "id": 1,
  "description": null,
  "name": "remote-project",
  "name_with_namespace": "Administrator / remote-project",
  "path": "remote-project",
  "path_with_namespace": "root/remote-project",
  "created_at": "2018-02-13T09:05:58.023Z",
  "import_status": "scheduled",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [],
  "import_error": null
}
```

L'en-tête `Content-Length` doit retourner un nombre valide. La taille maximale du fichier est de 10 Go. L'en-tête `Content-Type` doit être `application/gzip`.

## Importer un projet depuis un bucket AWS S3 {#import-a-project-from-an-aws-s3-bucket}

{{< history >}}

- Les attributs `namespace_id` et `namespace_path` [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/511053) dans GitLab 18.7.

{{< /history >}}

Importe un projet depuis une archive stockée dans un bucket AWS S3 spécifié.

```plaintext
POST /projects/remote-import-s3
```

| Attribut           | Type              | Obligatoire | Description |
| ------------------- | ----------------- | -------- | ----------- |
| `access_key_id`     | string            | Oui      | [ID de clé d'accès AWS S3](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html). |
| `bucket_name`       | string            | Oui      | [Nom du bucket AWS S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html) dans lequel le fichier est stocké. |
| `file_key`          | string            | Oui      | [Clé de fichier AWS S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingObjects.html) pour identifier le fichier. |
| `path`              | string            | Oui      | Le chemin complet du nouveau projet. |
| `region`            | string            | Oui      | [Nom de région AWS S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html#Regions) dans laquelle le fichier est stocké. |
| `secret_access_key` | string            | Oui      | [Clé d'accès secrète AWS S3](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html#access-keys-and-secret-access-keys). |
| `name`              | string            | Non       | Le nom du projet à importer. S'il n'est pas fourni, correspond par défaut au chemin du projet. |
| `namespace`         | entier ou chaîne | Non       | (Obsolète) L'ID ou le chemin de l'espace de nommage dans lequel importer le projet. Par défaut, correspond à l'espace de nommage de l'utilisateur actuel.<br/><br/> Nécessite le rôle Maintainer ou Owner sur le groupe de destination. Utilisez plutôt `namespace_id` ou `namespace_path`. |
| `namespace_id`      | entier           | Non       | L'ID de l'espace de nommage dans lequel importer le projet. Par défaut, correspond à l'espace de nommage de l'utilisateur actuel.<br/><br/> Nécessite le rôle Maintainer ou Owner sur le groupe de destination. |
| `namespace_path`    | string            | Non       | Le chemin de l'espace de nommage dans lequel importer le projet. Par défaut, correspond à l'espace de nommage de l'utilisateur actuel.<br/><br/> Nécessite le rôle Maintainer ou Owner sur le groupe de destination. |

Les paramètres de remplacement passés ont la priorité sur toutes les valeurs définies dans le fichier d'export.

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/projects/remote-import-s3" \
  --header "PRIVATE-TOKEN: <your gitlab access key>" \
  --header 'Content-Type: application/json' \
  --data '{
  "name": "Sample Project",
  "path": "sample-project",
  "region": "<Your S3 region name>",
  "bucket_name": "<Your S3 bucket name>",
  "file_key": "<Your S3 file key>",
  "access_key_id": "<Your AWS access key id>",
  "secret_access_key": "<Your AWS secret access key>"
}'
```

Cet exemple importe depuis un bucket Amazon S3, en utilisant un module qui se connecte à Amazon S3 :

```python
import requests
from io import BytesIO

s3_file = requests.get(presigned_url)

url =  'https://gitlab.example.com/api/v4/projects/import'
files = {'file': ('file.tar.gz', BytesIO(s3_file.content))}
data = {
    "path": "example-project",
    "namespace_path": "example-group"
}
headers = {
    'Private-Token': "<your_access_token>"
}

requests.post(url, headers=headers, data=data, files=files)
```

```json
{
  "id": 1,
  "description": null,
  "name": "Sample project",
  "name_with_namespace": "Administrator / sample-project",
  "path": "sample-project",
  "path_with_namespace": "root/sample-project",
  "created_at": "2018-02-13T09:05:58.023Z",
  "import_status": "scheduled",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [],
  "import_error": null
}
```

## Récupérer le statut d'un import de projet {#retrieve-the-status-of-a-project-import}

Récupère le statut de l'import le plus récent pour un projet spécifié.

```plaintext
GET /projects/:id/import
```

| Attribut | Type           | Obligatoire | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/import"
```

Le statut peut être l'un des suivants :

- `none`
- `scheduled`
- `failed`
- `started`
- `finished`

Si le statut est `failed`, il inclut le message d'erreur d'import sous `import_error`. Si le statut est `failed`, `started` ou `finished`, le tableau `failed_relations` peut être rempli avec toutes les occurrences de relations qui n'ont pas pu être importées en raison de :

- Erreurs irrécupérables.
- Les tentatives ont été épuisées. Un exemple typique : les délais d'attente de requête.

> [!note]
> Le champ `id` d'un élément dans `failed_relations` référence l'enregistrement d'échec, pas la relation. De plus, le tableau `failed_relations` est limité à 100 éléments.

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "import_status": "started",
  "import_type": "github",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [
    {
      "id": 42,
      "created_at": "2020-04-02T14:48:59.526Z",
      "exception_class": "RuntimeError",
      "exception_message": "A failure occurred",
      "source": "custom error context",
      "relation_name": "merge_requests",
      "line_number": 0
    }
  ]
}
```

Lors de l'import depuis GitHub, le champ `stats` liste le nombre d'objets déjà récupérés depuis GitHub et le nombre déjà importés :

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "import_status": "started",
  "import_type": "github",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [
    {
      "id": 42,
      "created_at": "2020-04-02T14:48:59.526Z",
      "exception_class": "RuntimeError",
      "exception_message": "A failure occurred",
      "source": "custom error context",
      "relation_name": "merge_requests",
      "line_number": 0
    }
  ],
  "stats": {
    "fetched": {
      "diff_note": 19,
      "issue": 3,
      "label": 1,
      "note": 3,
      "pull_request": 2,
      "pull_request_merged_by": 1,
      "pull_request_review": 16
    },
    "imported": {
      "diff_note": 19,
      "issue": 3,
      "label": 1,
      "note": 3,
      "pull_request": 2,
      "pull_request_merged_by": 1,
      "pull_request_review": 16
    }
  }
}
```

## Importer des ressources de projet {#import-project-resources}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/425798) en tant que [bêta](../policy/development_stages_support.md#beta) dans GitLab 16.11 [avec un flag](../administration/feature_flags/_index.md) nommé `single_relation_import`. Désactivé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/455889) dans GitLab 17.1. L'indicateur de fonctionnalité `single_relation_import` a été supprimé.

{{< /history >}}

Importe les [ressources de projet](../user/project/settings/import_export.md#project-items-that-are-exported) incluses dans une archive de projet. Le type d'élément à importer est contrôlé par l'attribut `relation`. Ignore les éléments précédemment importés.

Le fichier d'export de projet requis respecte la même structure et les mêmes exigences de taille décrites dans [importer un projet depuis une archive locale](#import-a-project-from-a-local-archive).

- Les fichiers extraits doivent respecter la structure d'un export de projet GitLab.
- L'archive ne doit pas dépasser la taille maximale du fichier d'import configurée par l'administrateur.

```plaintext
POST /projects/import-relation
```

| Attribut  | Type   | Obligatoire | Description                                                                                                    |
|------------|--------|----------|----------------------------------------------------------------------------------------------------------------|
| `file`     | string | Oui      | Le fichier à téléverser.                                                                                       |
| `path`     | string | Oui      | Nom et chemin du nouveau projet.                                                                                 |
| `relation` | string | Oui      | Le nom de la relation à importer. Doit être l'un des suivants : `issues`, `milestones`, `ci_pipelines` ou `merge_requests`. |

Pour téléverser un fichier depuis votre système de fichiers, utilisez l'option `--form`, qui conduit cURL à publier des données en utilisant l'en-tête `Content-Type: multipart/form-data`. Le paramètre `file=` doit pointer vers un fichier sur votre système de fichiers et être précédé de `@`. Par exemple :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "path=api-project" \
  --form "file=@/path/to/file" \
  --form "relation=issues" \
  --url "https://gitlab.example.com/api/v4/projects/import-relation"
```

```json
{
  "id": 9,
  "project_path": "namespace1/project1",
  "relation": "issues",
  "status": "finished"
}
```

## Récupérer le statut d'un import de ressources de projet {#retrieve-the-status-of-a-project-resource-import}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/425798) dans GitLab 16.11.

{{< /history >}}

Récupère le statut de l'import de relation le plus récent pour un projet spécifié. Étant donné qu'un seul import de relation peut être planifié à la fois, vous pouvez utiliser ce point de terminaison pour vérifier si l'import précédent s'est terminé avec succès.

```plaintext
GET /projects/:id/relation-imports
```

| Attribut | Type               | Obligatoire | Description                                                                          |
| --------- |--------------------| -------- |--------------------------------------------------------------------------------------|
| `id`      | entier ou chaîne  | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/18/relation-imports"
```

```json
[
  {
    "id": 1,
    "project_path": "namespace1/project1",
    "relation": "issues",
    "status": "created",
    "created_at": "2024-03-25T11:03:48.074Z",
    "updated_at": "2024-03-25T11:03:48.074Z"
  }
]
```

Le statut peut être l'un des suivants :

- `created` :  L'import a été planifié, mais n'a pas encore démarré.
- `started` :  L'import est en cours de traitement.
- `finished` :  L'import est terminé.
- `failed` :  L'import n'a pas pu être effectué.
