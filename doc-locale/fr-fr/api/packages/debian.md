---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Debian
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Déployée derrière un feature flag](../../administration/feature_flags/_index.md), désactivée par défaut.

{{< /history >}}

> [!warning]
> Cette API est utilisée par les clients de packages Debian tels que [dput](https://manpages.debian.org/stable/dput-ng/dput.1.en.html) et [apt-get](https://manpages.debian.org/stable/apt/apt-get.8.en.html), et n'est généralement pas destinée à une utilisation manuelle. Cette API est en cours de développement et n'est pas prête pour une utilisation en production en raison de fonctionnalités limitées.

Utilisez cette API pour interagir avec le [client du gestionnaire de packages Debian](../../user/packages/debian_repository/_index.md).

> [!note]
> Ces endpoints ne suivent pas les méthodes d'authentification API standard. Consultez la [documentation du registre Debian](../../user/packages/debian_repository/_index.md) pour obtenir des informations sur les en-têtes et les types de jetons pris en charge. Les méthodes d'authentification non documentées sont susceptibles d'être supprimées à l'avenir.

## Activer l'API Debian {#enable-the-debian-api}

L'API Debian est protégée par un feature flag qui est désactivé par défaut. [Les administrateurs GitLab ayant accès à la console GitLab Rails](../../administration/feature_flags/_index.md) peuvent choisir de l'activer. Pour l'activer, suivez les instructions dans [Activer l'API Debian](../../user/packages/debian_repository/_index.md#enable-the-debian-api).

## Activer l'API de groupe Debian {#enable-the-debian-group-api}

L'API de groupe Debian est protégée par un feature flag qui est désactivé par défaut. [Les administrateurs GitLab ayant accès à la console GitLab Rails](../../administration/feature_flags/_index.md) peuvent choisir de l'activer. Pour l'activer, suivez les instructions dans [Activer l'API de groupe Debian](../../user/packages/debian_repository/_index.md#enable-the-debian-group-api).

### S'authentifier auprès des dépôts de packages Debian {#authenticate-to-the-debian-package-repositories}

Consultez [S'authentifier auprès des dépôts de packages Debian](../../user/packages/debian_repository/_index.md#authenticate-to-the-debian-package-repositories).

## Uploader un fichier de package {#upload-a-package-file}

Uploade un fichier de package Debian pour un projet spécifié.

```plaintext
PUT projects/:id/packages/debian/:file_name
```

| Attribut      | Type   | Obligatoire | Description |
| -------------- | ------ | -------- | ----------- |
| `id`           | string | oui      | L'ID ou le chemin complet du projet.  |
| `file_name`    | string | oui      | Le nom du fichier de package Debian. |
| `distribution` | string | non       | Le nom de code ou la suite de la distribution. Utilisé avec `component` pour l'upload avec une distribution et un composant explicites. |
| `component`    | string | non       | Le composant du fichier de package. Utilisé avec `distribution` pour l'upload avec une distribution et un composant explicites. |

```shell
curl --request PUT \
     --user "<username>:<personal_access_token>" \
     --upload-file path/to/mypkg.deb \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/mypkg.deb"
```

Upload avec une distribution et un composant explicites :

```shell
curl --request PUT \
  --user "<username>:<personal_access_token>" \
  --upload-file  /path/to/myother.deb \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/myother.deb?distribution=sid&component=main"
```

## Télécharger un package {#download-a-package}

Télécharge un fichier de package spécifié pour un projet.

```plaintext
GET projects/:id/packages/debian/pool/:distribution/:letter/:package_name/:package_version/:file_name
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | oui      | Le nom de code ou la suite de la distribution Debian. |
| `letter`          | string | oui      | La classification Debian (première lettre ou lib-première lettre). |
| `package_name`    | string | oui      | Le nom du package source. |
| `package_version` | string | oui      | La version du package source. |
| `file_name`       | string | oui      | Le nom du fichier. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/pool/my-distro/a/my-pkg/1.0.0/example_1.0.0~alpha2_amd64.deb"
```

Écrire la sortie dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/pool/my-distro/a/my-pkg/1.0.0/example_1.0.0~alpha2_amd64.deb" \
     --remote-name
```

Cela écrit le fichier téléchargé en utilisant le nom de fichier distant dans le répertoire courant.

## Préfixe de route {#route-prefix}

Les endpoints restants décrits sont deux ensembles de routes identiques qui effectuent chacun des requêtes dans des portées différentes :

- Utilisez le préfixe de niveau projet pour effectuer des requêtes dans la portée d'un seul projet.
- Utilisez le préfixe de niveau groupe pour effectuer des requêtes dans la portée d'un seul groupe.

Les exemples de ce document utilisent tous le préfixe de niveau projet.

### Niveau projet {#project-level}

```plaintext
/projects/:id/packages/debian
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | oui | L'ID du projet ou le chemin complet du projet. |

### Niveau groupe {#group-level}

```plaintext
/groups/:id/-/packages/debian
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | oui | L'ID du projet ou le chemin complet du groupe. |

## Télécharger un fichier Release de distribution {#download-a-distribution-release-file}

Télécharge un fichier Release de distribution Debian spécifié.

```plaintext
GET <route-prefix>/dists/*distribution/Release
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | oui      | Le nom de code ou la suite de la distribution Debian. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release"
```

Écrire la sortie dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release" \
     --remote-name
```

Cela écrit le fichier téléchargé en utilisant le nom de fichier distant dans le répertoire courant.

## Télécharger un fichier Release de distribution signé {#download-a-signed-distribution-release-file}

Télécharge un fichier Release de distribution Debian signé spécifié.

```plaintext
GET <route-prefix>/dists/*distribution/InRelease
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | oui      | Le nom de code ou la suite de la distribution Debian. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/InRelease"
```

Écrire la sortie dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/InRelease" \
     --remote-name
```

Cela écrit le fichier téléchargé en utilisant le nom de fichier distant dans le répertoire courant.

## Télécharger la signature d'un fichier release {#download-a-release-file-signature}

Télécharge une signature de fichier release Debian spécifiée.

```plaintext
GET <route-prefix>/dists/*distribution/Release.gpg
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | oui      | Le nom de code ou la suite de la distribution Debian. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release.gpg"
```

Écrire la sortie dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release.gpg" \
     --remote-name
```

Cela écrit le fichier téléchargé en utilisant le nom de fichier distant dans le répertoire courant.

## Télécharger un index de packages {#download-a-packages-index}

Télécharge un index de packages spécifié.

```plaintext
GET <route-prefix>/dists/*distribution/:component/binary-:architecture/Packages
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | oui      | Le nom de code ou la suite de la distribution Debian. |
| `component`       | string | oui      | Le nom du composant de la distribution. |
| `architecture`    | string | oui      | Le type d'architecture de la distribution. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/Packages"
```

Écrire la sortie dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/Packages" \
     --remote-name
```

Cela écrit le fichier téléchargé en utilisant le nom de fichier distant dans le répertoire courant.

## Télécharger un index de packages par hachage {#download-a-packages-index-by-hash}

Télécharge un index de packages spécifié par hachage.

```plaintext
GET <route-prefix>/dists/*distribution/:component/binary-:architecture/by-hash/SHA256/:file_sha256

```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | oui      | Le nom de code ou la suite de la distribution Debian. |
| `component`       | string | oui      | Le nom du composant de la distribution. |
| `architecture`    | string | oui      | Le type d'architecture de la distribution. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

Écrire la sortie dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

Cela écrit le fichier téléchargé en utilisant le nom de fichier distant dans le répertoire courant.

## Télécharger un index de packages de l'installateur Debian {#download-a-debian-installer-packages-index}

Télécharge un index de packages de l'installateur Debian spécifié.

```plaintext
GET <route-prefix>/dists/*distribution/:component/debian-installer/binary-:architecture/Packages
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | oui      | Le nom de code ou la suite de la distribution Debian. |
| `component`       | string | oui      | Le nom du composant de la distribution. |
| `architecture`    | string | oui      | Le type d'architecture de la distribution. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/Packages"
```

Écrire la sortie dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/Packages" \
     --remote-name
```

Cela écrit le fichier téléchargé en utilisant le nom de fichier distant dans le répertoire courant.

## Télécharger un index de packages de l'installateur Debian par hachage {#download-a-debian-installer-packages-index-by-hash}

Télécharge un index de packages de l'installateur Debian spécifié par hachage.

```plaintext
GET <route-prefix>/dists/*distribution/:component/debian-installer/binary-:architecture/by-hash/SHA256/:file_sha256
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | oui      | Le nom de code ou la suite de la distribution Debian. |
| `component`       | string | oui      | Le nom du composant de la distribution. |
| `architecture`    | string | oui      | Le type d'architecture de la distribution. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

Écrire la sortie dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

Cela écrit le fichier téléchargé en utilisant le nom de fichier distant dans le répertoire courant.

## Télécharger un index de packages sources {#download-a-source-packages-index}

Télécharge un index de packages sources spécifié.

```plaintext
GET <route-prefix>/dists/*distribution/:component/source/Sources
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | oui      | Le nom de code ou la suite de la distribution Debian. |
| `component`       | string | oui      | Le nom du composant de la distribution. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/Sources"
```

Écrire la sortie dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/Sources" \
     --remote-name
```

Cela écrit le fichier téléchargé en utilisant le nom de fichier distant dans le répertoire courant.

## Télécharger un index de packages sources par hachage {#download-a-source-packages-index-by-hash}

Télécharge un index de packages sources spécifié par hachage.

```plaintext
GET <route-prefix>/dists/*distribution/:component/source/by-hash/SHA256/:file_sha256
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | string | oui      | Le nom de code ou la suite de la distribution Debian. |
| `component`       | string | oui      | Le nom du composant de la distribution. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

Écrire la sortie dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

Cela écrit le fichier téléchargé en utilisant le nom de fichier distant dans le répertoire courant.
