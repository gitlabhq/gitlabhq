---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Maven
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec le [client du gestionnaire de paquets Maven](../../user/packages/maven_repository/_index.md).

> [!warning]
> Cette API est utilisée par le [client du gestionnaire de paquets Maven](https://maven.apache.org/) et n'est généralement pas destinée à une utilisation manuelle.

Ces points de terminaison ne respectent pas les méthodes d'authentification standard de l'API. Consultez la [documentation du registre de paquets Maven](../../user/packages/maven_repository/_index.md) pour obtenir des informations sur les en-têtes et les types de jetons pris en charge. Les méthodes d'authentification non documentées pourraient être supprimées à l'avenir.

## Télécharger un fichier de paquet pour une instance {#download-a-package-file-for-an-instance}

Télécharge un fichier de paquet Maven spécifié pour l'instance.

```plaintext
GET packages/maven/*path/:file_name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `path`       | string | oui | Le chemin du paquet Maven, au format `<groupId>/<artifactId>/<version>`. Remplacez tout `.` dans le `groupId` par `/`. |
| `file_name`  | string | oui | Le nom du fichier de paquet Maven. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

Pour écrire la sortie dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

Cela écrit le fichier téléchargé dans `mypkg-1.0-SNAPSHOT.jar` dans le répertoire courant.

## Télécharger un fichier de paquet au niveau groupe {#download-a-package-file-for-a-group-level}

Télécharge un fichier de paquet Maven spécifié pour un groupe.

```plaintext
GET groups/:id/-/packages/maven/*path/:file_name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `path`       | string | oui | Le chemin du paquet Maven, au format `<groupId>/<artifactId>/<version>`. Remplacez tout `.` dans le `groupId` par `/`. |
| `file_name`  | string | oui | Le nom du fichier de paquet Maven. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

Pour écrire la sortie dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

Cela écrit le fichier téléchargé dans `mypkg-1.0-SNAPSHOT.jar` dans le répertoire courant.

## Télécharger un fichier de paquet pour un projet {#download-a-package-file-for-a-project}

Télécharge un fichier de paquet Maven spécifié pour un projet.

```plaintext
GET projects/:id/packages/maven/*path/:file_name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `path`       | string | oui | Le chemin du paquet Maven, au format `<groupId>/<artifactId>/<version>`. Remplacez tout `.` dans le `groupId` par `/`. |
| `file_name`  | string | oui | Le nom du fichier de paquet Maven. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar"
```

Pour écrire la sortie dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" >> mypkg-1.0-SNAPSHOT.jar
```

Cela écrit le fichier téléchargé dans `mypkg-1.0-SNAPSHOT.jar` dans le répertoire courant.

## Charger un fichier de paquet {#upload-a-package-file}

Charge un fichier de paquet Maven spécifié pour un projet.

```plaintext
PUT projects/:id/packages/maven/*path/:file_name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `path`       | string | oui | Le chemin du paquet Maven, au format `<groupId>/<artifactId>/<version>`. Remplacez tout `.` dans le `groupId` par `/`. |
| `file_name`  | string | oui | Le nom du fichier de paquet Maven. |

```shell
curl --request PUT \
     --upload-file path/to/mypkg-1.0-SNAPSHOT.pom \
     --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/maven/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.pom"
```
