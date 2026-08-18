---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation de l'API REST pour les dépôts Git dans GitLab."
title: API Dépôts
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [dépôts Git](../user/project/repository/_index.md).

## Répertorier toutes les arborescences du dépôt dans un projet {#list-all-repository-trees-in-a-project}

Répertorie tous les fichiers et répertoires du dépôt dans un projet spécifié. Cet endpoint est accessible sans authentification si le dépôt est accessible publiquement.

Cette commande fournit essentiellement les mêmes fonctionnalités que la commande `git ls-tree`. Pour plus d'informations, consultez les [objets d'arborescence](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects.html#_tree_objects) dans la documentation Git internals.

> [!warning]
> GitLab version 17.7 modifie le comportement de gestion des erreurs lorsqu'un chemin demandé est introuvable. L'endpoint retourne désormais un code de statut `404 Not Found`. Précédemment, le code de statut était `200 OK`.
>
> Si votre implémentation repose sur la réception d'un code de statut `200` avec un tableau vide pour les chemins manquants, vous devez mettre à jour votre gestion des erreurs pour traiter les nouvelles réponses `404`.

```plaintext
GET /projects/:id/repository/tree
```

Attributs pris en charge :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `id`         | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `page_token` | string            | Non       | ID d'enregistrement d'arborescence à partir duquel récupérer la page suivante. Utilisé uniquement avec la pagination par jeu de clés. |
| `pagination` | string            | Non       | Si `keyset`, utilise la [méthode de pagination par jeu de clés](rest/_index.md#keyset-based-pagination). |
| `path`       | string            | Non       | Chemin à l'intérieur du dépôt. Utilisé pour obtenir le contenu des sous-répertoires. |
| `per_page`   | entier           | Non       | Nombre de résultats à afficher par page. Si non spécifié, la valeur par défaut est `20`. Pour plus d'informations, consultez la [pagination](rest/_index.md#pagination). |
| `recursive`  | boolean           | Non       | Si `true`, obtient une arborescence récursive. La valeur par défaut est `false`. |
| `ref`        | string            | Non       | Nom d'une branche ou d'un tag du dépôt. Si non spécifié, utilise la branche par défaut. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et un tableau d'objets d'arborescence.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/tree"
```

Exemple de réponse :

```json
[
  {
    "id": "a1e8f8d745cc87e3a9248358d9352bb7f9a0aeba",
    "name": "html",
    "type": "tree",
    "path": "files/html",
    "mode": "040000"
  },
  {
    "id": "4535904260b1082e14f867f7a24fd8c21495bde3",
    "name": "images",
    "type": "tree",
    "path": "files/images",
    "mode": "040000"
  },
  {
    "id": "31405c5ddef582c5a9b7a85230413ff90e2fe720",
    "name": "js",
    "type": "tree",
    "path": "files/js",
    "mode": "040000"
  },
  {
    "id": "cc71111cfad871212dc99572599a568bfe1e7e00",
    "name": "lfs",
    "type": "tree",
    "path": "files/lfs",
    "mode": "040000"
  },
  {
    "id": "fd581c619bf59cfdfa9c8282377bb09c2f897520",
    "name": "markdown",
    "type": "tree",
    "path": "files/markdown",
    "mode": "040000"
  },
  {
    "id": "23ea4d11a4bdd960ee5320c5cb65b5b3fdbc60db",
    "name": "ruby",
    "type": "tree",
    "path": "files/ruby",
    "mode": "040000"
  },
  {
    "id": "7d70e02340bac451f281cecf0a980907974bd8be",
    "name": "whitespace",
    "type": "blob",
    "path": "files/whitespace",
    "mode": "100644"
  }
]
```

## Récupérer un blob depuis un dépôt {#retrieve-a-blob-from-a-repository}

Récupère des informations, telles que la taille et le contenu, sur les blobs d'un dépôt. Le contenu du blob est encodé en Base64. Cet endpoint est accessible sans authentification si le dépôt est accessible publiquement.

Pour les blobs de plus de 10 Mo, cet endpoint a une limite de débit de 5 requêtes par minute.

```plaintext
GET /projects/:id/repository/blobs/:sha
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `sha`     | string            | Oui      | SHA du blob.   |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut  | Type    | Description |
|------------|---------|-------------|
| `content`  | string  | Contenu du blob encodé en Base64. |
| `encoding` | string  | Encodage utilisé pour le contenu du blob. |
| `sha`      | string  | SHA du blob.   |
| `size`     | entier | Taille du blob en octets. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/blobs/79f7bbd25901e8334750839545a9bd021f0e4c83"
```

Exemple de réponse :

```json
{
  "size": 1476,
  "encoding": "base64",
  "content": "VGhpcyBpcyBhIGJpbmFyeSBmaWxl",
  "sha": "79f7bbd25901e8334750839545a9bd021f0e4c83"
}
```

## Récupérer le contenu brut d'un blob {#retrieve-raw-blob-content}

Récupère le contenu brut d'un fichier pour un blob, par SHA de blob. Cet endpoint est accessible sans authentification si le dépôt est accessible publiquement.

```plaintext
GET /projects/:id/repository/blobs/:sha/raw
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `sha`     | string            | Oui      | SHA du blob.   |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/blobs/79f7bbd25901e8334750839545a9bd021f0e4c83/raw"
```

## Récupérer l'archive de fichiers d'un dépôt {#retrieve-file-archive-from-a-repository}

Récupère l'archive de fichiers du dépôt spécifié. Cet endpoint est accessible sans authentification si le dépôt est accessible publiquement.

Pour les utilisateurs de GitLab.com, cet endpoint a un seuil de limite de débit de 5 requêtes par minute.

```plaintext
GET /projects/:id/repository/archive[.format]
```

`format` est un suffixe facultatif pour le format d'archive, et la valeur par défaut est `tar.gz`. Par exemple, spécifier `archive.zip` envoie une archive au format ZIP. Les options disponibles sont :

- `bz2`
- `tar`
- `tar.bz2`
- `tar.gz`
- `tb2`
- `tbz`
- `tbz2`
- `zip`

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `exclude_paths`     | string            | Non       | Liste de chemins séparés par des virgules à exclure de l'archive. |
| `include_lfs_blobs` | boolean           | Non       | Si `true`, les objets LFS sont inclus dans l'archive. Lorsque défini à `false`, les objets LFS sont exclus. La valeur par défaut est `true`. |
| `path`              | string            | Non       | Sous-chemin du dépôt à télécharger. Si la chaîne est vide, correspond à l'ensemble du dépôt par défaut. |
| `sha`               | string            | Non       | SHA du commit à télécharger. Accepte un tag, une référence de branche ou un SHA. Si non spécifié, correspond par défaut à la pointe de la branche par défaut. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.com/api/v4/projects/<project_id>/repository/archive?sha=<commit_sha>&path=<path>&exclude_paths=<path1,path2>"
```

## Comparer des branches, des tags ou des commits {#compare-branches-tags-or-commits}

{{< history >}}

- Les attributs de réponse `collapsed` et `too_large` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199633) dans GitLab 18.4.

{{< /history >}}

Récupère les différences entre deux branches, tags ou commits dans un projet spécifié. Cet endpoint est accessible sans authentification si le dépôt est accessible publiquement.

Lorsque `compare_timeout` est `true`, la comparaison a dépassé les limites de taille ou a expiré :

- Le tableau `commits` est toujours complet.
- Le tableau `diffs` peut être incomplet.
- Les objets diff individuels peuvent avoir des chaînes `diff` vides si leur contenu a dépassé les limites.

```plaintext
GET /projects/:id/repository/compare
```

Attributs pris en charge :

| Attribut         | Type              | Obligatoire | Description |
|-------------------|-------------------|----------|-------------|
| `from`            | string            | Oui      | SHA de commit ou nom de branche. |
| `id`              | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `to`              | string            | Oui      | SHA de commit ou nom de branche. |
| `from_project_id` | entier           | Non       | ID à partir duquel comparer. |
| `straight`        | boolean           | Non       | Si `true`, la méthode de comparaison est une comparaison directe entre `from` et `to` (`from`..`to`). Si `false`, compare en utilisant la base de fusion (`from`...`to`). La valeur par défaut est `false`. |
| `unidiff`         | boolean           | Non       | Si `true`, présente les diffs au format [diff unifié](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html). La valeur par défaut est `false`. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610) dans GitLab 16.5. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                | Type         | Description |
|--------------------------|--------------|-------------|
| `commit`                 | objet       | Détails du dernier commit dans la comparaison. |
| `commits`                | tableau d'objets | Commits entre les deux références. Toujours complet, même lorsque `compare_timeout` est `true`. |
| `commits[].author_email` | string       | Adresse e-mail de l'auteur du commit. |
| `commits[].author_name`  | string       | Nom de l'auteur du commit. |
| `commits[].created_at`   | datetime     | Horodatage de création du commit. |
| `commits[].id`           | string       | SHA complet du commit. |
| `commits[].short_id`     | string       | SHA abrégé du commit. |
| `commits[].title`        | string       | Titre du commit. |
| `compare_same_ref`       | boolean      | Si `true`, la comparaison utilise la même référence pour from et to. |
| `compare_timeout`        | boolean      | Si `true`, la comparaison a dépassé les limites de taille ou a expiré. Le tableau `diffs` peut être incomplet. |
| `diffs`                  | tableau d'objets | Liste des différences de fichiers. |
| `diffs[].a_mode`         | string       | Ancien mode de fichier. |
| `diffs[].b_mode`         | string       | Nouveau mode de fichier. |
| `diffs[].collapsed`      | boolean      | Si `true`, les diffs de fichier sont exclus mais peuvent être récupérés sur demande. |
| `diffs[].deleted_file`   | boolean      | Si `true`, le fichier a été supprimé. |
| `diffs[].diff`           | string       | Contenu du diff montrant les modifications apportées au fichier. |
| `diffs[].new_file`       | boolean      | Si `true`, le fichier a été ajouté. |
| `diffs[].new_path`       | string       | Nouveau chemin du fichier. |
| `diffs[].old_path`       | string       | Ancien chemin du fichier. |
| `diffs[].renamed_file`   | boolean      | Si `true`, le fichier a été renommé. |
| `diffs[].too_large`      | boolean      | Si `true`, les diffs de fichier sont exclus et ne peuvent pas être récupérés. |
| `web_url`                | string       | URL web pour afficher la comparaison. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/compare?from=main&to=feature"
```

Exemple de réponse :

```json
{
  "commit": {
    "id": "12d65c8dd2b2676fa3ac47d955accc085a37a9c1",
    "short_id": "12d65c8dd2b",
    "title": "JS fix",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "created_at": "2014-02-27T10:27:00+02:00"
  },
  "commits": [{
    "id": "12d65c8dd2b2676fa3ac47d955accc085a37a9c1",
    "short_id": "12d65c8dd2b",
    "title": "JS fix",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "created_at": "2014-02-27T10:27:00+02:00"
  }],
  "diffs": [{
    "old_path": "files/js/application.js",
    "new_path": "files/js/application.js",
    "a_mode": null,
    "b_mode": "100644",
    "diff": "@@ -24,8 +24,10 @@\n //= require g.raphael-min\n //= require g.bar-min\n //= require branch-graph\n-//= require highlightjs.min\n-//= require ace/ace\n //= require_tree .\n //= require d3\n //= require underscore\n+\n+function fix() { \n+  alert(\"Fixed\")\n+}",
    "collapsed": false,
    "too_large": false,
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
  }],
  "compare_timeout": false,
  "compare_same_ref": false,
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/compare/ae73cb07c9eeaf35924a10f713b364d32b2dd34f...0b4bc9a49b562e85de7cc9e834518ea6828729b9"
}
```

## Obtenir la liste des contributeurs {#get-contributor-list}

{{< history >}}

- `ref` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/156852) dans GitLab 17.4.

{{< /history >}}

Obtenir la liste des contributeurs du dépôt. Cet endpoint est accessible sans authentification si le dépôt est accessible publiquement.

Le nombre de commits retourné n'inclut pas les commits de fusion.

```plaintext
GET /projects/:id/repository/contributors
```

Attributs pris en charge :

| Attribut  | Type              | Obligatoire | Description |
|------------|-------------------|----------|-------------|
| `id`       | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `order_by` | string            | Non       | Trier les contributeurs par `name`, `email` ou `commits` (nombre de commits). Si non spécifié, les contributeurs sont triés par date de commit. |
| `ref`      | string            | Non       | Nom d'une branche ou d'un tag du dépôt. Si non spécifié, la branche par défaut. |
| `sort`     | string            | Non       | Retourner les contributeurs triés dans l'ordre `asc` ou `desc`. La valeur par défaut est `asc`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut   | Type    | Description |
|-------------|---------|-------------|
| `additions` | entier | Nombre d'ajouts de lignes par le contributeur. |
| `commits`   | entier | Nombre de commits par le contributeur. |
| `deletions` | entier | Nombre de suppressions de lignes par le contributeur. |
| `email`     | string  | Adresse e-mail du contributeur. |
| `name`      | string  | Nom du contributeur. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/repository/contributors"
```

Exemple de réponse :

```json
[{
  "name": "Example User",
  "email": "example@example.com",
  "commits": 117,
  "additions": 0,
  "deletions": 0
}, {
  "name": "Sample User",
  "email": "sample@example.com",
  "commits": 33,
  "additions": 0,
  "deletions": 0
}]
```

## Obtenir la base de fusion {#get-merge-base}

Obtenir l'ancêtre commun pour 2 refs ou plus, tels que des SHA de commits, des noms de branches ou des tags.

```plaintext
GET /projects/:id/repository/merge_base
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `refs`    | tableau             | Oui      | Refs pour lesquels trouver l'ancêtre commun. Accepte plusieurs refs. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type     | Description |
|---------------------|----------|-------------|
| `author_email`      | string   | Adresse e-mail de l'auteur. |
| `author_name`       | string   | Nom de l'auteur. |
| `authored_date`     | datetime | Date à laquelle le commit a été rédigé. |
| `committed_date`    | datetime | Date à laquelle le commit a été commis. |
| `committer_email`   | string   | Adresse e-mail du committer. |
| `committer_name`    | string   | Nom du committer. |
| `created_at`        | datetime | Horodatage de création du commit. |
| `extended_trailers` | objet   | Informations étendues sur les trailers Git. |
| `id`                | string   | SHA complet du commit. |
| `message`           | string   | Message de commit complet. |
| `parent_ids`        | tableau    | Liste des SHA des commits parents. |
| `short_id`          | string   | SHA abrégé du commit. |
| `title`             | string   | Titre du commit. |
| `trailers`          | objet   | Trailers Git analysés depuis le message de commit. |
| `web_url`           | string   | URL pour afficher le commit dans l'interface web de GitLab. |

Exemple de requête, avec les refs tronqués pour la lisibilité :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/merge_base?refs[]=304d257d&refs[]=0031876f"
```

Exemple de réponse :

```json
{
  "id": "1a0b36b3cdad1d2ee32457c102a8c0b7056fa863",
  "short_id": "1a0b36b3",
  "title": "Initial commit",
  "created_at": "2014-02-27T08:03:18.000Z",
  "parent_ids": [],
  "message": "Initial commit\n",
  "author_name": "Example User",
  "author_email": "user@example.com",
  "authored_date": "2014-02-27T08:03:18.000Z",
  "committer_name": "Example User",
  "committer_email": "user@example.com",
  "committed_date": "2014-02-27T08:03:18.000Z",
  "trailers": {},
  "extended_trailers": {},
  "web_url": "https://gitlab.example.com/example-group/example-project/-/commit/1a0b36b3cdad1d2ee32457c102a8c0b7056fa863"
}
```

## Générer des données de changelog {#generate-changelog-data}

{{< history >}}

- Authentification [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172842) via le [jeton de job CI/CD](../ci/jobs/ci_job_token.md) dans GitLab 17.7.
- L'attribut `config_file_ref` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/426108) dans GitLab 18.2.
- Le format texte brut (`.txt`) a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237585) dans GitLab 19.1.

{{< /history >}}

Génère des données de changelog basées sur les commits d'un dépôt, sans les committer dans un fichier de changelog.

Fonctionne exactement comme `POST /projects/:id/repository/changelog`, sauf que les données de changelog ne sont pas commitées dans un fichier de changelog.

```plaintext
GET /projects/:id/repository/changelog
```

Facultatif. Vous pouvez ajouter un suffixe `.txt` qui retourne le changelog en texte brut Markdown au lieu de JSON :

```plaintext
GET /projects/:id/repository/changelog.txt
```

Attributs pris en charge :

| Attribut         | Type     | Obligatoire | Description |
|-------------------|----------|----------|-------------|
| `version`         | string   | Oui      | Version pour laquelle générer le changelog. Le format doit suivre la [gestion sémantique de version](https://semver.org/). |
| `config_file`     | string   | Non       | Chemin du fichier de configuration du changelog dans le dépôt Git du projet. La valeur par défaut est `.gitlab/changelog_config.yml`. |
| `config_file_ref` | string   | Non       | Référence Git (par exemple, une branche) où le fichier de configuration du changelog est défini. La valeur par défaut est la branche par défaut du dépôt. |
| `date`            | datetime | Non       | Date et heure de la release. Utilise le format ISO 8601. Exemple : `2016-03-11T03:45:40Z`. La valeur par défaut est l'heure actuelle. |
| `from`            | string   | Non       | Début de la plage de commits (sous forme de SHA) à utiliser pour générer le changelog. Ce commit lui-même n'est pas inclus dans la liste. |
| `to`              | string   | Non       | Fin de la plage de commits (sous forme de SHA) à utiliser pour le changelog. Ce commit est inclus dans la liste. La valeur par défaut est le HEAD de la branche par défaut du projet. |
| `trailer`         | string   | Non       | Trailer Git à utiliser pour inclure les commits. La valeur par défaut est `Changelog`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type   | Description |
|-----------|--------|-------------|
| `notes`   | string | Données de changelog générées au format Markdown. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog?version=1.0.0"
```

Exemple de réponse, avec des sauts de ligne ajoutés pour la lisibilité :

```json
{
  "notes": "## 1.0.0 (2021-11-17)\n\n### feature (2 changes)\n\n-
    [Title 2](namespace13/project13@ad608eb642124f5b3944ac0ac772fecaf570a6bf)
    ([merge request](namespace13/project13!2))\n-
    [Title 1](namespace13/project13@3c6b80ff7034fa0d585314e1571cc780596ce3c8)
    ([merge request](namespace13/project13!1))\n"
}
```

Exemple de requête avec le format `.txt` :

```shell
curl --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog.txt?version=1.0.0"
```

Exemple de réponse :

```plaintext
## 1.0.0 (2021-11-17)

### feature (2 changes)

- [Title 2](namespace13/project13@ad608eb642124f5b3944ac0ac772fecaf570a6bf)
  ([merge request](namespace13/project13!2))
- [Title 1](namespace13/project13@3c6b80ff7034fa0d585314e1571cc780596ce3c8)
  ([merge request](namespace13/project13!1))
```

## Ajouter des données de changelog dans un fichier {#add-changelog-data-to-file}

{{< history >}}

- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/364101) dans GitLab 17.3. L'indicateur de fonctionnalité `changelog_commits_limitation` a été supprimé.
- `config_file_ref` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/426108) dans GitLab 18.2.

{{< /history >}}

Génère des données de changelog basées sur les commits d'un dépôt et les committe dans un fichier de changelog.

Étant donné une [version sémantique](https://semver.org/) et une plage de commits, GitLab génère un changelog pour tous les commits utilisant un [trailer Git](https://git-scm.com/docs/git-interpret-trailers) particulier. GitLab ajoute une nouvelle section formatée en Markdown dans un fichier de changelog du dépôt Git du projet. Le format de sortie peut être personnalisé.

Pour des raisons de performance et de sécurité, l'analyse de la configuration du changelog est limitée à 2 secondes. Cette limitation aide à prévenir les attaques DoS potentielles provenant de modèles de changelog malformés. Si la requête expire, envisagez de réduire la taille de votre fichier `changelog_config.yml`.

Pour la documentation destinée aux utilisateurs, consultez les [changelogs](../user/project/changelogs.md).

```plaintext
POST /projects/:id/repository/changelog
```

Les changelogs prennent en charge les attributs suivants :

| Attribut              | Type     | Obligatoire | Description |
|------------------------|----------|----------|-------------|
| `version` <sup>1</sup> | string   | Oui      | Version pour laquelle générer le changelog. Le format doit suivre la [gestion sémantique de version](https://semver.org/). |
| `branch`               | string   | Non       | Branche sur laquelle committer les modifications du changelog. La valeur par défaut est la branche par défaut du projet. |
| `config_file`          | string   | Non       | Chemin vers le fichier de configuration du changelog dans le dépôt Git du projet. La valeur par défaut est `.gitlab/changelog_config.yml`. |
| `config_file_ref`      | string   | Non       | Référence Git (par exemple, une branche) où le fichier de configuration du changelog est défini. La valeur par défaut est la branche par défaut du dépôt. |
| `date`                 | datetime | Non       | Date et heure de la release. La valeur par défaut est l'heure actuelle. |
| `file`                 | string   | Non       | Fichier dans lequel committer les modifications. La valeur par défaut est `CHANGELOG.md`. |
| `from` <sup>2</sup>    | string   | Non       | SHA du commit qui marque le début de la plage de commits à inclure dans le changelog. Ce commit n'est pas inclus dans le changelog. |
| `message`              | string   | Non       | Message de commit à utiliser lors du commit des modifications. La valeur par défaut est `Add changelog for version X`, où `X` est la valeur de l'argument `version`. |
| `to`                   | string   | Non       | SHA du commit qui marque la fin de la plage de commits à inclure dans le changelog. Ce commit est inclus dans le changelog. La valeur par défaut est la branche spécifiée dans l'attribut `branch`. Limité à 15 000 commits. |
| `trailer`              | string   | Non       | Trailer Git à utiliser pour inclure les commits. La valeur par défaut est `Changelog`. Sensible à la casse : `Example` ne correspond pas à `example` ni à `eXaMpLE`. |

**Remarques** :

1. L'attribut `version` peut inclure ou omettre le préfixe `v`. `1.0.0` et `v1.0.0` produisent des résultats identiques. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/437616) dans GitLab 17.0.

1. Lorsque `from` n'est pas spécifié, GitLab trouve automatiquement le dernier tag de version stable qui précède votre version spécifiée. GitLab reconnaît les tags au format `X.Y.Z` ou `vX.Y.Z`, en suivant la gestion sémantique de version.

   Par exemple, si `version` est `2.1.0`, GitLab utilise le tag `v2.0.0`. Lorsque `version` est `1.1.1` ou `1.2.0`, GitLab utilise le tag `v1.1.0`. Les tags de pré-release comme `v1.0.0-pre1` sont ignorés.

   Si aucun tag approprié n'est trouvé, l'API retourne une erreur et vous devez spécifier explicitement l'attribut `from`.

### Exemples {#examples}

Ces exemples utilisent [cURL](https://curl.se/) pour effectuer des requêtes HTTP. Les exemples de commandes utilisent ces valeurs :

- ID du projet : 42
- Emplacement : hébergé sur GitLab.com
- Exemple de jeton d'accès personnel de l'API : `token`

Cette commande génère un changelog pour la version `1.0.0`.

La plage de commits :

- Commence avec le tag de la dernière release.
- Se termine avec le dernier commit sur la branche cible. La branche cible par défaut est la branche par défaut du projet.

Si le dernier tag est `v0.9.0` et que la branche par défaut est `main`, la plage de commits incluse dans cet exemple est `v0.9.0..main` :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

Pour générer les données sur une branche différente, spécifiez le paramètre `branch`. Cette commande génère des données à partir de la branche `foo` :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&branch=foo" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

Pour utiliser un trailer différent, utilisez le paramètre `trailer` :

```shell
curl --request POST --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&trailer=Type" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

Pour stocker les résultats dans un fichier différent, utilisez le paramètre `file` :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&file=NEWS" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

Pour spécifier une branche comme paramètre, utilisez l'attribut `to` :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog?version=1.0.0&to=release/x.x.x"
```

## Migrer depuis des fichiers de changelog manuels {#migrate-from-manual-changelog-files}

Lorsque vous migrez d'un fichier de changelog géré manuellement vers un fichier utilisant des trailers Git, assurez-vous que le fichier de changelog correspond [au format attendu](../user/project/changelogs.md). Sinon, les nouvelles entrées de changelog ajoutées par l'API pourraient être insérées à une position inattendue. Par exemple, si les valeurs de version dans le fichier de changelog géré manuellement sont spécifiées comme `vX.Y.Z` au lieu de `X.Y.Z`, les nouvelles entrées de changelog ajoutées via des trailers Git sont ajoutées à la fin du fichier de changelog.

[L'issue 444183](https://gitlab.com/gitlab-org/gitlab/-/issues/444183) propose de personnaliser le format d'en-tête de version dans les fichiers de changelog. Cependant, jusqu'à ce que cette issue soit résolue, le format d'en-tête de version attendu dans les fichiers de changelog est `X.Y.Z`.

## Santé {#health}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182220) dans GitLab 17.10. Protégé par le [`project_repositories_health`](https://gitlab.com/gitlab-org/gitlab/-/issues/521115) feature flag.
- Nouveaux champs [ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191263) dans GitLab 18.1.

{{< /history >}}

Obtenir des statistiques relatives à la santé d'un dépôt de projet.

Cet endpoint est limité à 5 requêtes/heure par projet lorsque `generate` est `true`. L'endpoint est uniquement disponible pour les utilisateurs disposant d'un accès push au dépôt.

```plaintext
GET /projects/:id/repository/health
```

Attributs pris en charge :

| Attribut  | Type    | Obligatoire | Description                                                                            |
|------------|---------|----------|----------------------------------------------------------------------------------------|
| `generate` | boolean | Non       | Si `true`, un nouveau rapport de santé doit être généré. Définissez ceci si l'endpoint retourne `404`. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et des statistiques de santé du dépôt.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/health"
```

Exemple de réponse :

```json
{
  "size": 2619748827,
  "references": {
    "loose_count": 13,
    "packed_size": 333978,
    "reference_backend": "REFERENCE_BACKEND_FILES"
  },
  "objects": {
    "size": 2180475409,
    "recent_size": 2180453999,
    "stale_size": 21410,
    "keep_size": 0,
    "packfile_count": 1,
    "reverse_index_count": 1,
    "cruft_count": 0,
    "keep_count": 0,
    "loose_objects_count": 36,
    "stale_loose_objects_count": 36,
    "loose_objects_garbage_count": 0
  },
  "commit_graph": {
    "commit_graph_chain_length": 1,
    "has_bloom_filters": true,
    "has_generation_data": true,
    "has_generation_data_overflow": false
  },
  "bitmap": null,
  "multi_pack_index": {
    "packfile_count": 1,
    "version": 1
  },
  "multi_pack_index_bitmap": {
    "has_hash_cache": true,
    "has_lookup_table": true,
    "version": 1
  },
  "alternates": null,
  "is_object_pool": false,
  "last_full_repack": {
    "seconds": 1745892013,
    "nanos": 0
  },
  "updated_at": "2025-05-14T02:31:08.022Z"
}
```

Pour une description de chaque champ dans la réponse, consultez le message protobuf [`RepositoryInfoResponse`](https://gitlab.com/gitlab-org/gitaly/blob/fcb986a6482f82b088488db3ed7ca35adfa42fdc/proto/repository.proto#L444).

## Sujets connexes {#related-topics}

- Documentation utilisateur pour les [changelogs](../user/project/changelogs.md)
