---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API PyPI
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec le [client gestionnaire de paquets PyPI](../../user/packages/pypi_repository/_index.md).

> [!warning]
> Cette API est utilisée par le [client gestionnaire de paquets PyPI](https://pypi.org/) et n'est généralement pas destinée à une utilisation manuelle.

Ces endpoints ne respectent pas les méthodes d'authentification standard de l'API. Consultez la [documentation du registre de paquets PyPI](../../user/packages/pypi_repository/_index.md) pour en savoir plus sur les en-têtes et les types de jetons pris en charge. Les méthodes d'authentification non documentées pourront être supprimées à l'avenir.

> [!note]
> [Twine 3.4.2](https://twine.readthedocs.io/en/stable/changelog.html?highlight=FIPS#id28) ou une version ultérieure est recommandé lorsque le mode FIPS est activé.

## Télécharger un fichier de paquet pour un groupe {#download-a-package-file-for-a-group}

Télécharge un fichier de paquet PyPI spécifié pour un groupe. L'[API simple](#retrieve-package-descriptor-for-a-group) fournit généralement cette URL.

```plaintext
GET groups/:id/-/packages/pypi/files/:sha256/:file_identifier
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | oui      | L'ID ou le chemin complet du groupe. |
| `sha256`          | string | oui      | La somme de contrôle sha256 du fichier de paquet PyPI. |
| `file_identifier` | string | oui      | Le nom du fichier de paquet PyPI. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz"
```

Pour écrire la sortie dans un fichier :

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz" >> my.pypi.package-0.0.1.tar.gz
```

Cela écrit le fichier téléchargé dans `my.pypi.package-0.0.1.tar.gz` dans le répertoire courant.

## Lister tous les paquets pour un groupe {#list-all-packages-for-a-group}

Liste tous les paquets pour le groupe spécifié dans un fichier HTML.

```plaintext
GET groups/:id/-/packages/pypi/simple
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | string | oui | L'ID ou le chemin complet du groupe. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple"
```

Exemple de réponse :

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for Group</title>
  </head>
  <body>
    <h1>Links for Group</h1>
    <a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/my-pypi-package" data-requires-python="">my.pypi.package</a><br><a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/package-2" data-requires-python="3.8">package_2</a><br>
  </body>
</html>
```

Pour écrire la sortie dans un fichier :

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple" >> simple_index.html
```

Cela écrit le fichier téléchargé dans `simple_index.html` dans le répertoire courant.

## Récupérer le descripteur de paquet pour un groupe {#retrieve-package-descriptor-for-a-group}

Récupère le descripteur de paquet sous forme de fichier HTML pour un paquet spécifié dans un groupe.

```plaintext
GET groups/:id/-/packages/pypi/simple/:package_name
```

| Attribut      | Type   | Obligatoire | Description |
| -------------- | ------ | -------- | ----------- |
| `id`           | string | oui      | L'ID ou le chemin complet du groupe. |
| `package_name` | string | oui      | Le nom du paquet. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/my.pypi.package"
```

Exemple de réponse :

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for my.pypi.package</title>
  </head>
  <body>
    <h1>Links for my.pypi.package</h1>
    <a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1-py3-none-any.whl#sha256=5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1-py3-none-any.whl</a><br><a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/9s9w01b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2/my.pypi.package-0.0.1.tar.gz#sha256=9s9w011b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1.tar.gz</a><br>
  </body>
</html>
```

Pour écrire la sortie dans un fichier :

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/my.pypi.package" >> simple.html
```

Cela écrit le fichier téléchargé dans `simple.html` dans le répertoire courant.

## Télécharger un fichier de paquet pour un projet {#download-a-package-file-for-a-project}

Télécharge un fichier de paquet PyPI spécifié pour un projet. L'[API simple](#retrieve-package-descriptor-for-a-project) fournit généralement cette URL.

```plaintext
GET projects/:id/packages/pypi/files/:sha256/:file_identifier
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`              | string | oui | L'ID ou le chemin complet du projet. |
| `sha256`          | string | oui | Somme de contrôle sha256 du fichier de paquet PyPI. |
| `file_identifier` | string | oui | Le nom du fichier de paquet PyPI. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz"
```

Pour écrire la sortie dans un fichier :

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz" >> my.pypi.package-0.0.1.tar.gz
```

Cela écrit le fichier téléchargé dans `my.pypi.package-0.0.1.tar.gz` dans le répertoire courant.

## Lister tous les paquets pour un projet {#list-all-packages-for-a-project}

Liste tous les paquets pour le projet spécifié dans un fichier HTML.

```plaintext
GET projects/:id/packages/pypi/simple
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | string | oui | L'ID ou le chemin complet du projet. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple"
```

Exemple de réponse :

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for Project</title>
  </head>
  <body>
    <h1>Links for Project</h1>
    <a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/my-pypi-package" data-requires-python="">my.pypi.package</a><br><a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/package-2" data-requires-python="3.8">package_2</a><br>
  </body>
</html>
```

Pour écrire la sortie dans un fichier :

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple" >> simple_index.html
```

Cela écrit le fichier téléchargé dans `simple_index.html` dans le répertoire courant.

## Récupérer le descripteur de paquet pour un projet {#retrieve-package-descriptor-for-a-project}

Récupère le descripteur de paquet sous forme de fichier HTML pour un paquet spécifié dans un projet.

```plaintext
GET projects/:id/packages/pypi/simple/:package_name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`           | string | oui | L'ID ou le chemin complet du projet. |
| `package_name` | string | oui | Le nom du paquet. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/my.pypi.package"
```

Exemple de réponse :

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for my.pypi.package</title>
  </head>
  <body>
    <h1>Links for my.pypi.package</h1>
    <a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1-py3-none-any.whl#sha256=5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1-py3-none-any.whl</a><br><a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/9s9w01b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2/my.pypi.package-0.0.1.tar.gz#sha256=9s9w011b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1.tar.gz</a><br>
  </body>
</html>
```

Pour écrire la sortie dans un fichier :

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/my.pypi.package" >> simple.html
```

Cela écrit le fichier téléchargé dans `simple.html` dans le répertoire courant.

## Téléverser un paquet {#upload-a-package}

Téléverse un paquet PyPI pour un projet spécifié.

```plaintext
POST projects/:id/packages/pypi
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | Oui | L'ID ou le chemin complet du projet. |
| `requires_python` | string | Non | La version PyPI requise. |
| `sha256_digest` | string | Non | La somme de contrôle SHA256 du fichier de paquet. Non requis pour les téléversements, mais sans cet attribut, `pip install` échoue car les URL d'index de paquets ne disposent pas des sommes de contrôle requises. |

```shell
curl --request POST \
     --form 'content=@path/to/my.pypi.package-0.0.1.tar.gz' \
     --form "sha256_digest=$(shasum -a 256 < path/to/my.pypi.package-0.0.1.tar.gz | cut -d' ' -f1)" \
     --form 'name=my.pypi.package' \
     --form 'version=1.3.7' \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi"
```
