---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation de l'API REST pour les commits Git dans GitLab."
title: API Commits
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [commits Git](../user/project/repository/commits/_index.md).

## Réponses {#responses}

Certains champs de date dans les réponses de cette API sont, ou peuvent sembler être, des informations dupliquées :

- Le champ `created_at` existe uniquement à des fins de cohérence avec les autres API GitLab. Il est toujours identique au champ `committed_date`.
- Les champs `committed_date` et `authored_date` sont générés à partir de sources différentes et peuvent ne pas être identiques.

### En-têtes de réponse de pagination {#pagination-response-headers}

Pour des raisons de performance, GitLab ne renvoie pas les en-têtes suivants dans les réponses de l'API Commits :

- `x-total`
- `x-total-pages`

Pour plus d'informations, consultez [le ticket 389582](https://gitlab.com/gitlab-org/gitlab/-/issues/389582).

## Lister les commits d'un dépôt {#list-repository-commits}

{{< history >}}

- `follow` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225733) dans GitLab 18.10.

{{< /history >}}

Récupère la liste des commits d'un dépôt dans un projet.

```plaintext
GET /projects/:id/repository/commits
```

| Attribut      | Type           | Obligatoire | Description |
|----------------|----------------|----------|-------------|
| `id`           | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `all`          | boolean        | Non       | Récupère tous les commits du dépôt. Si `true`, le paramètre `ref_name` est ignoré. |
| `author`       | string         | Non       | Recherche des commits par auteur de commit. |
| `first_parent` | boolean        | Non       | Si `true`, suit uniquement le premier commit parent lors de la détection d'un merge commit. |
| `follow`       | boolean        | Non       | Si `true`, suit les renommages de fichiers lors du filtrage des commits par `path`, et renvoie les commits pour le fichier même s'il a été renommé. Si `false`, renvoie uniquement les commits où le fichier existait à son chemin actuel. Utilisé uniquement lorsque `path` spécifie un seul fichier. La valeur par défaut est `true`. |
| `order`        | string         | Non       | Liste les commits dans l'ordre. Valeurs possibles : `default`, [`topo`](https://git-scm.com/docs/git-log#Documentation/git-log.txt---topo-order). La valeur par défaut est `default` ; les commits sont affichés dans l'ordre chronologique inverse. |
| `path`         | string         | Non       | Le chemin du fichier. |
| `ref_name`     | string         | Non       | Le nom d'une branche, d'un tag ou d'une plage de révisions du dépôt, ou, si non spécifié, la branche par défaut. |
| `since`        | string         | Non       | Seuls les commits postérieurs ou correspondant à cette date sont renvoyés au format ISO 8601 `YYYY-MM-DDTHH:MM:SSZ`. |
| `trailers`     | boolean        | Non       | Si `true`, analyse et inclut les [Git trailers](https://git-scm.com/docs/git-interpret-trailers) pour chaque commit. |
| `until`        | string         | Non       | Seuls les commits antérieurs ou correspondant à cette date sont renvoyés au format ISO 8601 `YYYY-MM-DDTHH:MM:SSZ`. |
| `with_stats`   | boolean        | Non       | Si `true`, récupère les statistiques de chaque commit. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type   | Description |
|---------------------|--------|-------------|
| `author_email`      | string | Adresse e-mail de l'auteur du commit. |
| `author_name`       | string | Nom de l'auteur du commit. |
| `authored_date`     | string | Date à laquelle le commit a été rédigé. |
| `committed_date`    | string | Date à laquelle le commit a été validé. |
| `committer_email`   | string | Adresse e-mail du committer du commit. |
| `committer_name`    | string | Nom du committer du commit. |
| `created_at`        | string | Date à laquelle le commit a été créé (identique à `committed_date`). |
| `extended_trailers` | objet | Git trailers étendus avec toutes les valeurs. |
| `id`                | string | SHA du commit. |
| `message`           | string | Message complet du commit. |
| `parent_ids`        | tableau  | Tableau des SHA des commits parents. |
| `short_id`          | string | SHA court du commit. |
| `title`             | string | Titre du message de commit. |
| `trailers`          | objet | Git trailers analysés depuis le message de commit. |
| `web_url`           | string | URL web du commit. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits"
```

Exemple de réponse :

```json
[
  {
    "id": "ed899a2f4b50b4370feeea94676502b42383c746",
    "short_id": "ed899a2f4b5",
    "title": "Replace sanitize with escape once",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2021-09-20T11:50:22.001+00:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2021-09-20T11:50:22.001+00:00",
    "created_at": "2021-09-20T11:50:22.001+00:00",
    "message": "Replace sanitize with escape once",
    "parent_ids": [
      "6104942438c14ec7bd21c6cd5bd995272b3faff6"
    ],
    "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/ed899a2f4b50b4370feeea94676502b42383c746",
    "trailers": {},
    "extended_trailers": {}
  },
  {
    "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
    "short_id": "6104942438c",
    "title": "Sanitize for network graph",
    "author_name": "randx",
    "author_email": "user@example.com",
    "committer_name": "ExampleName",
    "committer_email": "user@example.com",
    "created_at": "2021-09-20T09:06:12.201+00:00",
    "message": "Sanitize for network graph\nCc: John Doe <johndoe@gitlab.com>\nCc: Jane Doe <janedoe@gitlab.com>",
    "parent_ids": [
      "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
    ],
    "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/ed899a2f4b50b4370feeea94676502b42383c746",
    "trailers": {
      "Cc": "Jane Doe <janedoe@gitlab.com>"
    },
    "extended_trailers": {
      "Cc": [
        "John Doe <johndoe@gitlab.com>",
        "Jane Doe <janedoe@gitlab.com>"
      ]
    }
  }
]
```

## Créer un commit {#create-a-commit}

{{< history >}}

- `allow_empty` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211520) dans GitLab 18.8.
- Limites de taille des requêtes et limites de débit introduites dans GitLab 18.7.

{{< /history >}}

Crée un commit en publiant un contenu JSON

```plaintext
POST /projects/:id/repository/commits
```

> [!note]
> Cet endpoint est soumis aux [limites de taille des requêtes et aux limites de débit](../administration/instance_limits.md#commits-and-files-api-limits). Les requêtes dépassant une limite par défaut de 300 Mo sont rejetées. Les requêtes supérieures à 20 Mo sont soumises à une limite de débit de 3 requêtes toutes les 30 secondes.

| Attribut        | Type              | Obligatoire | Description |
|------------------|-------------------|----------|-------------|
| `branch`         | string            | Oui      | Nom de la branche dans laquelle effectuer le commit. Pour créer une nouvelle branche, fournissez également `start_branch` ou `start_sha`, et optionnellement `start_project`. |
| `commit_message` | string            | Oui      | Message de commit. |
| `id`             | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `actions[]`      | tableau             | Non       | Un tableau de hachages d'actions à valider en lot. Consultez le tableau suivant pour connaître les attributs qu'il peut prendre. |
| `allow_empty`    | boolean           | Non       | Lorsque `true`, crée un commit vide. La valeur par défaut est `false`. |
| `author_email`   | string            | Non       | Spécifie l'adresse e-mail de l'auteur du commit. |
| `author_name`    | string            | Non       | Spécifie le nom de l'auteur du commit. |
| `force`          | boolean           | Non       | Si `true`, écrase `branch` avec un nouveau commit basé sur `start_branch` ou `start_sha`, en remplaçant l'historique de commits existant de la branche. La valeur par défaut est `false`. <sup>1</sup> |
| `start_branch`   | string            | Non       | Nom de la branche à utiliser comme parent pour le nouveau commit. Si non fourni et que `start_sha` n'est pas non plus fourni, prend par défaut la valeur de `branch`. Mutuellement exclusif avec `start_sha`. <sup>1</sup> |
| `start_project`  | entier ou chaîne | Non       | L'ID du projet ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) à utiliser comme source pour `start_branch` ou `start_sha`. Prend par défaut la valeur de `id`. |
| `start_sha`      | string            | Non       | SHA du commit à utiliser comme parent pour le nouveau commit. Doit être un SHA complet de 40 caractères. Mutuellement exclusif avec `start_branch`. <sup>1</sup> |
| `stats`          | boolean           | Non       | Inclut les statistiques du commit. La valeur par défaut est `true`. |

**Remarques** :

1. Lorsque `force` est `true`, fournissez `start_branch` ou `start_sha` pour spécifier un commit parent différent. Si aucun n'est fourni, `start_branch` prend par défaut la valeur de `branch`, et le nouveau commit est basé sur le sommet de la branche courante. Dans ce cas, `force` n'a aucun effet car le résultat est identique à un commit ordinaire.

> [!note]
> Les requêtes volumineuses avec de nombreuses actions peuvent être soumises à des limites de taille. Pour plus d'informations, consultez [les limites de l'API commits](../administration/instance_limits.md#commits-and-files-api-limits).

| Attribut `actions[]` | Type    | Obligatoire | Description |
|-----------------------|---------|----------|-------------|
| `action`              | string  | Oui      | L'action à effectuer : `create`, `delete`, `move`, `update` ou `chmod`. |
| `file_path`           | string  | Oui      | Chemin complet vers le fichier. Par exemple : `lib/class.rb`. |
| `content`             | string  | Non       | Contenu du fichier, requis pour toutes les actions sauf `delete`, `chmod` et `move`. Les actions de déplacement qui ne spécifient pas `content` conservent le contenu existant du fichier, et toute autre valeur de `content` écrase le contenu du fichier. |
| `encoding`            | string  | Non       | `text` ou `base64`. `text` est la valeur par défaut. |
| `execute_filemode`    | boolean | Non       | Si `true`, active le drapeau d'exécution sur le fichier. Si `false`, le désactive. Pris en compte uniquement pour l'action `chmod`. |
| `last_commit_id`      | string  | Non       | Dernier ID de commit connu pour le fichier. Pris en compte uniquement pour les actions de mise à jour, de déplacement et de suppression. |
| `previous_path`       | string  | Non       | Chemin complet d'origine du fichier en cours de déplacement. Par exemple `lib/class1.rb`. Pris en compte uniquement pour l'action `move`. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut         | Type   | Description |
|-------------------|--------|-------------|
| `author_email`    | string | Adresse e-mail de l'auteur du commit. |
| `author_name`     | string | Nom de l'auteur du commit. |
| `authored_date`   | string | Date à laquelle le commit a été rédigé. |
| `committed_date`  | string | Date à laquelle le commit a été validé. |
| `committer_email` | string | Adresse e-mail du committer du commit. |
| `committer_name`  | string | Nom du committer du commit. |
| `created_at`      | string | Date à laquelle le commit a été créé. |
| `id`              | string | SHA du commit créé. |
| `message`         | string | Message complet du commit. |
| `parent_ids`      | tableau  | Tableau des SHA des commits parents. |
| `short_id`        | string | SHA court du commit créé. |
| `stats`           | objet | Statistiques sur le commit (ajouts, suppressions, total). |
| `status`          | string | Statut du commit. |
| `title`           | string | Titre du message de commit. |
| `web_url`         | string | URL web du commit. |

```shell
PAYLOAD=$(cat << 'JSON'
{
  "branch": "main",
  "commit_message": "some commit message",
  "actions": [
    {
      "action": "create",
      "file_path": "foo/bar",
      "content": "some content"
    },
    {
      "action": "delete",
      "file_path": "foo/bar2"
    },
    {
      "action": "move",
      "file_path": "foo/bar3",
      "previous_path": "foo/bar4",
      "content": "some content"
    },
    {
      "action": "update",
      "file_path": "foo/bar5",
      "content": "new content"
    },
    {
      "action": "chmod",
      "file_path": "foo/bar5",
      "execute_filemode": true
    }
  ]
}
JSON
)
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data "$PAYLOAD" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository/commits"
```

Exemple de réponse :

```json
{
  "id": "ed899a2f4b50b4370feeea94676502b42383c746",
  "short_id": "ed899a2f4b5",
  "title": "some commit message",
  "author_name": "Example User",
  "author_email": "user@example.com",
  "committer_name": "Example User",
  "committer_email": "user@example.com",
  "created_at": "2016-09-20T09:26:24.000-07:00",
  "message": "some commit message",
  "parent_ids": [
    "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
  ],
  "committed_date": "2016-09-20T09:26:24.000-07:00",
  "authored_date": "2016-09-20T09:26:24.000-07:00",
  "stats": {
    "additions": 2,
    "deletions": 2,
    "total": 4
  },
  "status": null,
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/ed899a2f4b50b4370feeea94676502b42383c746"
}
```

GitLab prend en charge [l'encodage de formulaire](rest/_index.md#array-and-hash-types). Voici un exemple d'utilisation de l'API Commit avec l'encodage de formulaire :

```shell
curl --request POST \
     --form "branch=main" \
     --form "commit_message=some commit message" \
     --form "start_branch=main" \
     --form "actions[][action]=create" \
     --form "actions[][file_path]=foo/bar" \
     --form "actions[][content]=</path/to/local.file" \
     --form "actions[][action]=delete" \
     --form "actions[][file_path]=foo/bar2" \
     --form "actions[][action]=move" \
     --form "actions[][file_path]=foo/bar3" \
     --form "actions[][previous_path]=foo/bar4" \
     --form "actions[][content]=</path/to/local1.file" \
     --form "actions[][action]=update" \
     --form "actions[][file_path]=foo/bar5" \
     --form "actions[][content]=</path/to/local2.file" \
     --form "actions[][action]=chmod" \
     --form "actions[][file_path]=foo/bar5" \
     --form "actions[][execute_filemode]=true" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/repository/commits"
```

## Récupérer un commit {#retrieve-a-commit}

Récupère un commit spécifié identifié par le hachage du commit ou le nom d'une branche ou d'un tag.

```plaintext
GET /projects/:id/repository/commits/:sha
```

Paramètres :

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `sha`     | string         | Oui      | Le hachage du commit ou le nom d'une branche ou d'un tag du dépôt. |
| `stats`   | boolean        | Non       | Inclut les statistiques du commit. La valeur par défaut est `true`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut         | Type   | Description |
|-------------------|--------|-------------|
| `author_email`    | string | Adresse e-mail de l'auteur du commit. |
| `author_name`     | string | Nom de l'auteur du commit. |
| `authored_date`   | string | Date à laquelle le commit a été rédigé. |
| `committed_date`  | string | Date à laquelle le commit a été validé. |
| `committer_email` | string | Adresse e-mail du committer du commit. |
| `committer_name`  | string | Nom du committer du commit. |
| `created_at`      | string | Date à laquelle le commit a été créé. |
| `id`              | string | SHA du commit. |
| `last_pipeline`   | objet | Informations sur le dernier pipeline pour ce commit. |
| `message`         | string | Message complet du commit. |
| `parent_ids`      | tableau  | Tableau des SHA des commits parents. |
| `short_id`        | string | SHA court du commit. |
| `stats`           | objet | Statistiques sur le commit (ajouts, suppressions, total). |
| `status`          | string | Statut du commit. |
| `title`           | string | Titre du message de commit. |
| `web_url`         | string | URL web du commit. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main"
```

Exemple de réponse :

```json
{
  "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
  "short_id": "6104942438c",
  "title": "Sanitize for network graph",
  "author_name": "randx",
  "author_email": "user@example.com",
  "committer_name": "Dmitriy",
  "committer_email": "user@example.com",
  "created_at": "2021-09-20T09:06:12.300+03:00",
  "message": "Sanitize for network graph",
  "committed_date": "2021-09-20T09:06:12.300+03:00",
  "authored_date": "2021-09-20T09:06:12.420+03:00",
  "parent_ids": [
    "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
  ],
  "last_pipeline": {
    "id": 8,
    "ref": "main",
    "sha": "2dc6aa325a317eda67812f05600bdf0fcdc70ab0",
    "status": "created"
  },
  "stats": {
    "additions": 15,
    "deletions": 10,
    "total": 25
  },
  "status": "running",
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/6104942438c14ec7bd21c6cd5bd995272b3faff6"
}
```

## Lister toutes les références vers lesquelles un commit est poussé {#list-all-references-a-commit-is-pushed-to}

Liste toutes les références (depuis des branches ou des tags) vers lesquelles un commit est poussé. Les paramètres de pagination `page` et `per_page` peuvent être utilisés pour restreindre la liste des références.

```plaintext
GET /projects/:id/repository/commits/:sha/refs
```

Paramètres :

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `sha`     | string         | Oui      | Le hachage du commit. |
| `type`    | string         | Non       | La portée des commits. Valeurs possibles `branch`, `tag`, `all`. La valeur par défaut est `all`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type   | Description |
|-----------|--------|-------------|
| `name`    | string | Nom de la branche ou du tag. |
| `type`    | string | Type de référence (`branch` ou `tag`). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/5937ac0a7beb003549fc5fd26fc247adbce4a52e/refs?type=all"
```

Exemple de réponse :

```json
[
  {
    "type": "branch",
    "name": "'test'"
  },
  {
    "type": "branch",
    "name": "add-balsamiq-file"
  },
  {
    "type": "branch",
    "name": "wip"
  },
  {
    "type": "tag",
    "name": "v1.1.0"
  }
]
```

## Obtenir la séquence de commits {#get-commit-sequence}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/438151) dans GitLab 16.9.

{{< /history >}}

Obtient le numéro de séquence d'un commit dans un projet en suivant les liens parents depuis le commit donné.

Cette API fournit essentiellement les mêmes fonctionnalités que la commande `git rev-list --count` pour un SHA de commit donné.

```plaintext
GET /projects/:id/repository/commits/:sha/sequence
```

Paramètres :

| Attribut      | Type           | Obligatoire | Description |
|----------------|----------------|----------|-------------|
| `id`           | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `sha`          | string         | Oui      | Le hachage du commit. |
| `first_parent` | boolean        | Non       | Si `true`, suit uniquement le premier commit parent lors de la détection d'un merge commit. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type | Description |
| --------- | ---- | ----------- |
| `count` | entier | Numéro de séquence du commit. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/5937ac0a7beb003549fc5fd26fc247adbce4a52e/sequence"
```

Exemple de réponse :

```json
{
  "count": 632
}
```

## Cherry-picker un commit {#cherry-pick-a-commit}

Effectue un cherry-pick d'un commit vers une branche donnée.

```plaintext
POST /projects/:id/repository/commits/:sha/cherry_pick
```

Paramètres :

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `branch`  | string         | Oui      | Le nom de la branche. |
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `sha`     | string         | Oui      | Le hachage du commit. |
| `dry_run` | boolean        | Non       | Si `true`, ne valide aucune modification. La valeur par défaut est `false`. |
| `message` | string         | Non       | Un message de commit personnalisé à utiliser pour le nouveau commit. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut         | Type   | Description |
|-------------------|--------|-------------|
| `author_email`    | string | Adresse e-mail de l'auteur du commit d'origine. |
| `author_name`     | string | Nom de l'auteur du commit d'origine. |
| `authored_date`   | string | Date à laquelle le commit d'origine a été rédigé. |
| `committed_date`  | string | Date à laquelle le commit cherry-pické a été validé. |
| `committer_email` | string | Adresse e-mail du committer du cherry-pick. |
| `committer_name`  | string | Nom du committer du cherry-pick. |
| `created_at`      | string | Date à laquelle le commit cherry-pické a été créé. |
| `id`              | string | SHA du commit cherry-pické. |
| `message`         | string | Message complet du commit. |
| `parent_ids`      | tableau  | Tableau des SHA des commits parents. |
| `short_id`        | string | SHA court du commit cherry-pické. |
| `title`           | string | Titre du message de commit. |
| `web_url`         | string | URL web du commit cherry-pické. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "branch=main" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main/cherry_pick"
```

Exemple de réponse :

```json
{
  "id": "8b090c1b79a14f2bd9e8a738f717824ff53aebad",
  "short_id": "8b090c1b",
  "author_name": "Example User",
  "author_email": "user@example.com",
  "authored_date": "2016-12-12T20:10:39.000+01:00",
  "created_at": "2016-12-12T20:10:39.000+01:00",
  "committer_name": "Administrator",
  "committer_email": "admin@example.com",
  "committed_date": "2016-12-12T20:10:39.000+01:00",
  "title": "Feature added",
  "message": "Feature added\n\nSigned-off-by: Example User <user@example.com>\n",
  "parent_ids": [
    "a738f717824ff53aebad8b090c1b79a14f2bd9e8"
  ],
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/8b090c1b79a14f2bd9e8a738f717824ff53aebad"
}
```

En cas d'échec du cherry-pick, la réponse fournit le contexte expliquant pourquoi :

```json
{
  "message": "Sorry, we cannot cherry-pick this commit automatically. This commit may already have been cherry-picked, or a more recent commit may have updated some of its content.",
  "error_code": "empty"
}
```

Dans ce cas, le cherry-pick a échoué car l'ensemble de modifications était vide, ce qui indique probablement que le commit existe déjà dans la branche cible. L'autre code d'erreur possible est `conflict`, ce qui indique qu'il y a eu un conflit de merge.

Lorsque `dry_run` est activé, le serveur tente d'appliquer le cherry-pick _mais sans valider les modifications résultantes_. Si le cherry-pick s'applique correctement, l'API répond avec `200 OK` :

```json
{
  "dry_run": "success"
}
```

En cas d'échec, une erreur s'affiche, identique à un échec sans dry run.

## Annuler un commit {#revert-a-commit}

Annule un commit dans une branche donnée.

```plaintext
POST /projects/:id/repository/commits/:sha/revert
```

Paramètres :

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `branch`  | string         | Oui      | Nom de la branche cible. |
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `sha`     | string         | Oui      | SHA du commit à annuler. |
| `dry_run` | boolean        | Non       | Si `true`, ne valide aucune modification. La valeur par défaut est `false`. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut         | Type   | Description |
|-------------------|--------|-------------|
| `author_email`    | string | Adresse e-mail de l'auteur du commit de retour arrière. |
| `author_name`     | string | Nom de l'auteur du commit de retour arrière. |
| `authored_date`   | string | Date à laquelle le commit de retour arrière a été rédigé. |
| `committed_date`  | string | Date à laquelle le commit de retour arrière a été validé. |
| `committer_email` | string | Adresse e-mail du committer du commit de retour arrière. |
| `committer_name`  | string | Nom du committer du commit de retour arrière. |
| `created_at`      | string | Date à laquelle le commit de retour arrière a été créé. |
| `id`              | string | SHA du commit de retour arrière. |
| `message`         | string | Message complet du commit de retour arrière. |
| `parent_ids`      | tableau  | Tableau des SHA des commits parents. |
| `short_id`        | string | SHA court du commit de retour arrière. |
| `title`           | string | Titre du message du commit de retour arrière. |
| `web_url`         | string | URL web du commit de retour arrière. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "branch=main" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/a738f717824ff53aebad8b090c1b79a14f2bd9e8/revert"
```

Exemple de réponse :

```json
{
  "id": "8b090c1b79a14f2bd9e8a738f717824ff53aebad",
  "short_id": "8b090c1b",
  "title": "Revert \"Feature added\"",
  "created_at": "2018-11-08T15:55:26.000Z",
  "parent_ids": [
    "a738f717824ff53aebad8b090c1b79a14f2bd9e8"
  ],
  "message": "Revert \"Feature added\"\n\nThis reverts commit a738f717824ff53aebad8b090c1b79a14f2bd9e8",
  "author_name": "Administrator",
  "author_email": "admin@example.com",
  "authored_date": "2018-11-08T15:55:26.000Z",
  "committer_name": "Administrator",
  "committer_email": "admin@example.com",
  "committed_date": "2018-11-08T15:55:26.000Z",
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/8b090c1b79a14f2bd9e8a738f717824ff53aebad"
}
```

En cas d'échec du retour arrière, la réponse fournit le contexte expliquant pourquoi :

```json
{
  "message": "Sorry, we cannot revert this commit automatically. This commit may already have been reverted, or a more recent commit may have updated some of its content.",
  "error_code": "conflict"
}
```

Dans ce cas, le retour arrière a échoué car la tentative de retour arrière a généré un conflit de merge. L'autre code d'erreur possible est `empty`, ce qui indique que l'ensemble de modifications était vide, probablement parce que la modification a déjà été annulée.

Lorsque `dry_run` est activé, le serveur tente d'appliquer le retour arrière _mais sans valider les modifications résultantes_. Si le retour arrière s'applique correctement, l'API répond avec `200 OK` :

```json
{
  "dry_run": "success"
}
```

En cas d'échec, une erreur s'affiche, identique à un échec sans dry run.

## Récupérer le diff d'un commit {#retrieve-commit-diff}

{{< history >}}

- Les attributs de réponse `collapsed` et `too_large` [introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199633) dans GitLab 18.4.

{{< /history >}}

Récupère le diff d'un commit dans un projet.

```plaintext
GET /projects/:id/repository/commits/:sha/diff
```

Paramètres :

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `sha`     | string         | Oui      | Le hachage du commit ou le nom d'une branche ou d'un tag du dépôt. |
| `unidiff` | boolean        | Non       | Si `true`, présente les diffs au format [diff unifié](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html). La valeur par défaut est `false`. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610) dans GitLab 16.5. |

> [!note]
> Cet endpoint est soumis aux [limites de diff](../administration/diff_limits.md). Lorsqu'un commit dépasse le nombre maximum de fichiers configuré, la pagination s'arrête et aucun fichier supplémentaire n'est renvoyé au-delà de la limite. Pour les limites spécifiques à GitLab.com, consultez [les limites d'affichage des diffs](../user/gitlab_com/_index.md#diff-display-limits).

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut      | Type    | Description |
|----------------|---------|-------------|
| `a_mode`       | string  | Ancien mode de fichier du fichier. |
| `b_mode`       | string  | Nouveau mode de fichier du fichier. |
| `collapsed`    | boolean | Les diffs du fichier sont exclus mais peuvent être récupérés sur demande. |
| `deleted_file` | boolean | Le fichier a été supprimé. |
| `diff`         | string  | Représentation diff des modifications apportées au fichier. |
| `new_file`     | boolean | Le fichier a été ajouté. |
| `new_path`     | string  | Nouveau chemin du fichier. |
| `old_path`     | string  | Ancien chemin du fichier. |
| `renamed_file` | boolean | Le fichier a été renommé. |
| `too_large`    | boolean | Les diffs du fichier sont exclus et ne peuvent pas être récupérés. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main/diff"
```

Exemple de réponse :

```json
[
  {
    "diff": "@@ -71,6 +71,8 @@\n sudo -u git -H bundle exec rake migrate_keys RAILS_ENV=production\n sudo -u git -H bundle exec rake migrate_inline_notes RAILS_ENV=production\n \n+sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production\n+\n ```\n \n ### 6. Update config files",
    "collapsed": false,
    "too_large": false,
    "new_path": "doc/update/5.4-to-6.0.md",
    "old_path": "doc/update/5.4-to-6.0.md",
    "a_mode": null,
    "b_mode": "100644",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
  }
]
```

## Lister tous les commentaires d'un commit {#list-all-commit-comments}

Liste tous les commentaires d'un commit dans un projet.

```plaintext
GET /projects/:id/repository/commits/:sha/comments
```

Paramètres :

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `sha`     | string         | Oui      | Le hachage du commit ou le nom d'une branche ou d'un tag du dépôt. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type   | Description |
|-----------|--------|-------------|
| `author`  | objet | Informations sur l'auteur du commentaire. |
| `note`    | string | Le texte du commentaire. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main/comments"
```

Exemple de réponse :

```json
[
  {
    "note": "this code is really nice",
    "author": {
      "id": 11,
      "username": "admin",
      "email": "admin@local.host",
      "name": "Administrator",
      "state": "active",
      "created_at": "2014-03-06T08:17:35.000Z"
    }
  }
]
```

## Publier un commentaire sur un commit {#post-comment-to-commit}

Crée un commentaire sur un commit.

Pour publier un commentaire sur une ligne particulière d'un fichier particulier, vous devez spécifier le SHA complet du commit, le `path`, le `line`, et `line_type` doit être `new`.

Le commentaire est ajouté à la fin du dernier commit si au moins l'un des cas suivants est valide :

- le `sha` est à la place une branche ou un tag et le `line` ou le `path` sont invalides
- le numéro `line` est invalide (n'existe pas)
- le `path` est invalide (n'existe pas)

Dans l'un ou l'autre des cas précédents, la réponse de `line`, `line_type` et `path` est définie sur `null`.

Pour d'autres approches permettant de commenter une merge request, consultez [créer une note de merge request](notes.md#create-a-merge-request-note) dans l'API des notes, et [créer un nouveau fil de discussion dans le diff de la merge request](discussions.md#create-a-new-thread-in-the-merge-request-diff) dans l'API des discussions.

```plaintext
POST /projects/:id/repository/commits/:sha/comments
```

| Attribut   | Type           | Obligatoire | Description |
|-------------|----------------|----------|-------------|
| `id`        | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `note`      | string         | Oui      | Le texte du commentaire. |
| `sha`       | string         | Oui      | Le SHA du commit ou le nom d'une branche ou d'un tag du dépôt. |
| `line`      | entier        | Non       | Le numéro de ligne où le commentaire doit être placé. |
| `line_type` | string         | Non       | Le type de ligne. Prend `new` ou `old` comme arguments. |
| `path`      | string         | Non       | Le chemin du fichier relatif au dépôt. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut    | Type    | Description |
|--------------|---------|-------------|
| `author`     | objet  | Informations sur l'auteur du commentaire. |
| `created_at` | string  | Date à laquelle le commentaire a été créé. |
| `line_type`  | string  | Type de ligne sur lequel se trouve le commentaire. |
| `line`       | entier | Numéro de ligne où le commentaire est placé. |
| `note`       | string  | Le texte du commentaire. |
| `path`       | string  | Chemin du fichier relatif au dépôt. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "note=Nice picture\!" \
  --form "path=README.md" \
  --form "line=11" \
  --form "line_type=new" \
  --url "https://gitlab.example.com/api/v4/projects/17/repository/commits/18f3e63d05582537db6d183d9d557be09e1f90c8/comments"
```

Exemple de réponse :

```json
{
  "author": {
    "web_url": "https://gitlab.example.com/janedoe",
    "avatar_url": "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
    "username": "janedoe",
    "state": "active",
    "name": "Jane Doe",
    "id": 28
  },
  "created_at": "2016-01-19T09:44:55.600Z",
  "line_type": "new",
  "path": "README.md",
  "line": 11,
  "note": "Nice picture!"
}
```

## Lister toutes les discussions d'un commit {#list-all-commit-discussions}

Liste toutes les discussions d'un commit dans un projet.

```plaintext
GET /projects/:id/repository/commits/:sha/discussions
```

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | Oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `sha`     | string | Oui | Le hachage du commit ou le nom d'une branche ou d'un tag du dépôt. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut         | Type    | Description |
|-------------------|---------|-------------|
| `id`              | string  | ID de la discussion. |
| `individual_note` | boolean | Si `true`, la discussion est une note individuelle. |
| `notes`           | tableau   | Tableau des notes dans la discussion. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/4604744a1c64de00ff62e1e8a6766919923d2b41/discussions"
```

Exemple de réponse :

```json
[
  {
    "id": "4604744a1c64de00ff62e1e8a6766919923d2b41",
    "individual_note": true,
    "notes": [
      {
        "id": 334686748,
        "type": null,
        "body": "Nice piece of code!",
        "attachment": null,
        "author": {
          "id": 28,
          "name": "Jane Doe",
          "username": "janedoe",
          "web_url": "https://gitlab.example.com/janedoe",
          "state": "active",
          "avatar_url": "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png"
        },
        "created_at": "2020-04-30T18:48:11.432Z",
        "updated_at": "2020-04-30T18:48:11.432Z",
        "system": false,
        "noteable_id": null,
        "noteable_type": "Commit",
        "resolvable": false,
        "confidential": null,
        "noteable_iid": null,
        "commands_changes": {}
      }
    ]
  }
]
```

## Statut du commit {#commit-status}

L'API de statut de commit pour une utilisation avec GitLab.

### Lister les statuts de commit {#list-commit-statuses}

{{< history >}}

- Les champs `pipeline_id`, `order_by` et `sort` [introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176142) dans GitLab 17.9.

{{< /history >}}

Liste les statuts d'un commit dans un projet. Les paramètres de pagination `page` et `per_page` peuvent être utilisés pour restreindre la liste des références.

```plaintext
GET /projects/:id/repository/commits/:sha/statuses
```

| Attribut     | Type              | Obligatoire | Description |
|---------------|-------------------|----------|-------------|
| `id`          | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `sha`         | string            | Oui      | Hachage du commit. |
| `all`         | boolean           | Non       | Si `true`, inclut tous les statuts au lieu du seul dernier. La valeur par défaut est `false`. |
| `name`        | string            | Non       | Filtre les statuts par [nom de job](../ci/yaml/_index.md#job-keywords). Par exemple, `bundler:audit`. |
| `order_by`    | string            | Non       | Valeurs pour le tri des statuts. Les valeurs valides sont `id` et `pipeline_id`. La valeur par défaut est `id`. |
| `pipeline_id` | entier           | Non       | Filtre les statuts par ID de pipeline. Par exemple, `1234`. |
| `ref`         | string            | Non       | Nom de la branche ou du tag. La valeur par défaut est la branche par défaut. |
| `sort`        | string            | Non       | Trie les statuts par ordre croissant ou décroissant. Les valeurs valides sont `asc` et `desc`. La valeur par défaut est `asc`. |
| `stage`       | string            | Non       | Filtre les statuts par [étape de build](../ci/yaml/_index.md#stages). Par exemple, `test`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut       | Type    | Description |
|-----------------|---------|-------------|
| `allow_failure` | boolean | Si `true`, le statut autorise l'échec. |
| `author`        | objet  | Informations sur l'auteur du statut. |
| `created_at`    | string  | Date à laquelle le statut a été créé. |
| `description`   | string  | Description du statut. |
| `finished_at`   | string  | Date à laquelle le statut s'est terminé. |
| `id`            | entier | ID du statut. |
| `name`          | string  | Nom du statut. |
| `ref`           | string  | Référence (branche ou tag) du commit. |
| `sha`           | string  | SHA du commit. |
| `started_at`    | string  | Date à laquelle le statut a démarré. |
| `status`        | string  | Statut du commit. |
| `target_url`    | string  | URL cible associée au statut. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/17/repository/commits/18f3e63d05582537db6d183d9d557be09e1f90c8/statuses"
```

Exemple de réponse :

```json
[
  ...
  {
    "status": "pending",
    "created_at": "2016-01-19T08:40:25.934Z",
    "started_at": null,
    "name": "bundler:audit",
    "allow_failure": true,
    "author": {
      "username": "janedoe",
      "state": "active",
      "web_url": "https://gitlab.example.com/janedoe",
      "avatar_url": "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
      "id": 28,
      "name": "Jane Doe"
    },
    "description": null,
    "sha": "18f3e63d05582537db6d183d9d557be09e1f90c8",
    "target_url": "https://gitlab.example.com/janedoe/gitlab-foss/builds/91",
    "finished_at": null,
    "id": 91,
    "ref": "main"
  },
  {
    "started_at": null,
    "name": "test",
    "allow_failure": false,
    "status": "pending",
    "created_at": "2016-01-19T08:40:25.832Z",
    "target_url": "https://gitlab.example.com/janedoe/gitlab-foss/builds/90",
    "id": 90,
    "finished_at": null,
    "ref": "main",
    "sha": "18f3e63d05582537db6d183d9d557be09e1f90c8",
    "author": {
      "id": 28,
      "name": "Jane Doe",
      "username": "janedoe",
      "web_url": "https://gitlab.example.com/janedoe",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png"
    },
    "description": null
  }
  ...
]
```

### Définir le statut du pipeline d'un commit {#set-commit-pipeline-status}

Ajoute ou met à jour le statut d'un commit représenté par un job dans une étape `external`. Si le commit est associé à une merge request, ciblez le commit dans la branche source de la merge request.

Lorsque vous définissez un statut de commit :

- Les pipelines existants sont d'abord recherchés pour y ajouter le job.
- Si aucun pipeline approprié n'existe, un nouveau pipeline est créé avec `CI_PIPELINE_SOURCE: external`.

Pour plus d'informations, consultez [les statuts de commit externes](../ci/ci_cd_for_external_repos/external_commit_statuses.md).

> [!note]
> Lorsque des pipelines en double existent pour le même commit, il peut être ambigu de savoir quel pipeline reçoit le statut externe. Configurez votre pipeline pour [éviter les doublons](../ci/jobs/job_rules.md#avoid-duplicate-pipelines).

Si un pipeline existe déjà et qu'il dépasse le [nombre maximum de jobs dans une limite de pipeline unique](../administration/cicd/limits.md#maximum-number-of-jobs-in-a-pipeline) :

- Si `pipeline_id` est spécifié, une erreur `422` est renvoyée : `The number of jobs has exceeded the limit`.
- Sinon, un nouveau pipeline est créé.

Si une mise à jour est déjà en cours pour une combinaison SHA/ref, une erreur `409` est renvoyée. Pour gérer cette erreur, relancez la requête.

```plaintext
POST /projects/:id/statuses/:sha
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `sha`               | string            | Oui      | Le SHA du commit. |
| `state`             | string            | Oui      | L'état du statut. Peut être l'une des valeurs suivantes : `pending`, `running`, `success`, `failed`, `canceled`, `skipped`. |
| `coverage`          | flottant             | Non       | La couverture totale du code. |
| `description`       | string            | Non       | La description courte du statut. Doit comporter 255 caractères ou moins. |
| `name` ou `context` | string            | Non       | Le label permettant de distinguer ce statut du statut des autres systèmes. La valeur par défaut est `default`. |
| `pipeline_id`       | entier           | Non       | L'ID du pipeline pour lequel définir le statut. À utiliser en cas de plusieurs pipelines sur le même SHA. |
| `ref`               | string            | Non       | Le `ref` (branche ou tag) auquel le statut fait référence. Doit comporter 255 caractères ou moins. |
| `target_url`        | string            | Non       | L'URL cible à associer à ce statut. Doit comporter 255 caractères ou moins. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut       | Type    | Description |
|-----------------|---------|-------------|
| `allow_failure` | boolean | Si `true`, le statut autorise l'échec. |
| `author`        | objet  | Informations sur l'auteur du statut. |
| `coverage`      | flottant   | Pourcentage de couverture du code. |
| `created_at`    | string  | Date à laquelle le statut a été créé. |
| `description`   | string  | Description du statut. |
| `finished_at`   | string  | Date à laquelle le statut s'est terminé. |
| `id`            | entier | ID du statut. |
| `name`          | string  | Nom du statut. |
| `ref`           | string  | Référence (branche ou tag) du commit. |
| `sha`           | string  | SHA du commit. |
| `started_at`    | string  | Date à laquelle le statut a démarré. |
| `status`        | string  | Statut du commit. |
| `target_url`    | string  | URL cible associée au statut. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/17/statuses/18f3e63d05582537db6d183d9d557be09e1f90c8?state=success"
```

Exemple de réponse :

```json
{
  "author": {
    "web_url": "https://gitlab.example.com/janedoe",
    "name": "Jane Doe",
    "avatar_url": "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
    "username": "janedoe",
    "state": "active",
    "id": 28
  },
  "name": "default",
  "sha": "18f3e63d05582537db6d183d9d557be09e1f90c8",
  "status": "success",
  "coverage": 100.0,
  "description": null,
  "id": 93,
  "target_url": null,
  "ref": null,
  "started_at": null,
  "created_at": "2016-01-19T09:05:50.355Z",
  "allow_failure": false,
  "finished_at": "2016-01-19T09:05:50.365Z"
}
```

## Lister les merge requests associées à un commit {#list-merge-requests-associated-with-a-commit}

{{< history >}}

- L'attribut `state` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191169) dans GitLab 18.2.

{{< /history >}}

Renvoie des informations sur la merge request qui a initialement introduit un commit spécifique.

```plaintext
GET /projects/:id/repository/commits/:sha/merge_requests
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `sha`     | string            | Oui      | Le SHA du commit. |
| `state`   | string            | Non       | Renvoie les merge requests avec l'état spécifié : `opened`, `closed`, `locked` ou `merged`. Omettez ce paramètre pour obtenir toutes les merge requests quel que soit leur état. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                      | Type    | Description |
|--------------------------------|---------|-------------|
| `assignee`                     | objet  | Informations sur le destinataire de la merge request. |
| `author`                       | objet  | Informations sur l'auteur de la merge request. |
| `created_at`                   | string  | Date à laquelle la merge request a été créée. |
| `description`                  | string  | Description de la merge request. |
| `discussion_locked`            | boolean | Si `true`, les discussions sont verrouillées. |
| `downvotes`                    | entier | Nombre de votes négatifs. |
| `draft`                        | boolean | Si `true`, la merge request est un brouillon. |
| `force_remove_source_branch`   | boolean | Si `true`, force la suppression de la branche source. |
| `id`                           | entier | ID de la merge request. |
| `iid`                          | entier | ID interne de la merge request. |
| `labels`                       | tableau   | Labels associés à la merge request. |
| `merge_commit_sha`             | string  | SHA du commit de fusion. |
| `merge_status`                 | string  | Statut de fusion de la merge request. |
| `merge_when_pipeline_succeeds` | boolean | Si `true`, fusionne lorsque le pipeline réussit. |
| `milestone`                    | objet  | Jalon associé à la merge request. |
| `project_id`                   | entier | ID du projet. |
| `sha`                          | string  | SHA de la merge request. |
| `should_remove_source_branch`  | boolean | Si `true`, supprime la branche source après la fusion. |
| `source_branch`                | string  | Branche source de la merge request. |
| `source_project_id`            | entier | ID du projet source. |
| `squash_commit_sha`            | string  | SHA du commit squash. |
| `state`                        | string  | État de la merge request. |
| `target_branch`                | string  | Branche cible de la merge request. |
| `target_project_id`            | entier | ID du projet cible. |
| `time_stats`                   | objet  | Statistiques de suivi du temps. |
| `title`                        | string  | Titre de la merge request. |
| `updated_at`                   | string  | Date à laquelle la merge request a été mise à jour pour la dernière fois. |
| `upvotes`                      | entier | Nombre de votes positifs. |
| `user_notes_count`             | entier | Nombre de notes utilisateur. |
| `web_url`                      | string  | URL web de la merge request. |
| `work_in_progress`             | boolean | Si `true`, la merge request est définie comme travail en cours. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/af5b13261899fb2c0db30abdd0af8b07cb44fdc5/merge_requests?state=opened"
```

Exemple de réponse :

```json
[
  {
    "id": 45,
    "iid": 1,
    "project_id": 35,
    "title": "Add new file",
    "description": "",
    "state": "opened",
    "created_at": "2018-03-26T17:26:30.916Z",
    "updated_at": "2018-03-26T17:26:30.916Z",
    "target_branch": "main",
    "source_branch": "test-branch",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "web_url": "https://gitlab.example.com/janedoe",
      "name": "Jane Doe",
      "avatar_url": "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
      "username": "janedoe",
      "state": "active",
      "id": 28
    },
    "assignee": null,
    "source_project_id": 35,
    "target_project_id": 35,
    "labels": [],
    "draft": false,
    "work_in_progress": false,
    "milestone": null,
    "merge_when_pipeline_succeeds": false,
    "merge_status": "can_be_merged",
    "sha": "af5b13261899fb2c0db30abdd0af8b07cb44fdc5",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 0,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": false,
    "web_url": "https://gitlab.example.com/root/test-project/merge_requests/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

## Récupérer la signature d'un commit {#retrieve-commit-signature}

Récupère la [signature d'un commit](../user/project/repository/signed_commits/_index.md), s'il est signé. Pour les commits non signés, cela entraîne une réponse 404.

```plaintext
GET /projects/:id/repository/commits/:sha/signature
```

Paramètres :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `sha`     | string            | Oui      | Le hachage du commit ou le nom d'une branche ou d'un tag du dépôt. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut               | Type    | Description |
|-------------------------|---------|-------------|
| `commit_source`         | string  | Source du commit. |
| `gpg_key_id`            | entier | ID de la clé GPG (pour les signatures PGP). |
| `gpg_key_primary_keyid` | string  | ID de clé primaire de la clé GPG. |
| `gpg_key_subkey_id`     | string  | ID de sous-clé de la clé GPG. |
| `gpg_key_user_email`    | string  | Adresse e-mail associée à la clé GPG. |
| `gpg_key_user_name`     | string  | Nom d'utilisateur associé à la clé GPG. |
| `key`                   | objet  | Informations sur la clé SSH (pour les signatures SSH). |
| `signature_type`        | string  | Type de signature (`PGP`, `SSH`, ou `X509`). |
| `verification_status`   | string  | Statut de vérification de la signature. |
| `x509_certificate`      | objet  | Informations sur le certificat X.509 (pour les signatures X.509). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository/commits/da738facbc19eb2fc2cef57c49be0e6038570352/signature"
```

Exemple de réponse si le commit est signé avec GPG :

```json
{
  "signature_type": "PGP",
  "verification_status": "verified",
  "gpg_key_id": 1,
  "gpg_key_primary_keyid": "8254AAB3FBD54AC9",
  "gpg_key_user_name": "John Doe",
  "gpg_key_user_email": "johndoe@example.com",
  "gpg_key_subkey_id": null,
  "commit_source": "gitaly"
}
```

Exemple de réponse si le commit est signé avec SSH :

```json
{
  "signature_type": "SSH",
  "verification_status": "verified",
  "key": {
    "id": 11,
    "title": "Key",
    "created_at": "2023-05-08T09:12:38.503Z",
    "expires_at": "2024-05-07T00:00:00.000Z",
    "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILZzYDq6DhLp3aX84DGIV3F6Vf+Ae4yCTTz7RnqMJOlR MyKey)",
    "usage_type": "auth_and_signing"
  },
  "commit_source": "gitaly"
}
```

Exemple de réponse si le commit est signé avec X.509 :

```json
{
  "signature_type": "X509",
  "verification_status": "unverified",
  "x509_certificate": {
    "id": 1,
    "subject": "CN=gitlab@example.org,OU=Example,O=World",
    "subject_key_identifier": "BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC",
    "email": "gitlab@example.org",
    "serial_number": 278969561018901340486471282831158785578,
    "certificate_status": "good",
    "x509_issuer": {
      "id": 1,
      "subject": "CN=PKI,OU=Example,O=World",
      "subject_key_identifier": "AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB",
      "crl_url": "http://example.com/pki.crl"
    }
  },
  "commit_source": "gitaly"
}
```

Exemple de réponse si le commit n'est pas signé :

```json
{
  "message": "404 GPG Signature Not Found"
}
```
