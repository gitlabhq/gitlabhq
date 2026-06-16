---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Go Proxy
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec le [client du gestionnaire de paquets Go](../../user/packages/go_proxy/_index.md). Cette API est protégée par un feature flag désactivé par défaut. Les administrateurs GitLab ayant accès à la console GitLab Rails peuvent [activer](../../administration/feature_flags/_index.md) cette API pour votre instance GitLab.

> [!warning]
> Cette API est utilisée par la [commande `go`](https://go.dev/ref/mod#go-get) et n'est généralement pas destinée à une utilisation manuelle.

Ces endpoints ne respectent pas les méthodes d'authentification standard de l'API. Consultez la [documentation du paquet Go Proxy](../../user/packages/go_proxy/_index.md) pour obtenir des informations sur les en-têtes et les types de jetons pris en charge. Les méthodes d'authentification non documentées pourront être supprimées à l'avenir.

## Liste {#list}

Obtenir toutes les versions taguées pour un module Go donné :

```plaintext
GET projects/:id/packages/go/:module_name/@v/list
```

| Attribut      | Type   | Obligatoire | Description |
| -------------- | ------ | -------- | ----------- |
| `id`           | string | oui      | L'ID du projet ou le chemin complet d'un projet. |
| `module_name`  | string | oui      | Le nom du module Go. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/list"
```

Exemple de résultat :

```shell
"v1.0.0\nv1.0.1\nv1.3.8\n2.0.0\n2.1.0\n3.0.0"
```

## Métadonnées de version {#version-metadata}

Obtenir toutes les versions taguées pour un module Go donné :

```plaintext
GET projects/:id/packages/go/:module_name/@v/:module_version.info
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | oui      | L'ID du projet ou le chemin complet d'un projet. |
| `module_name`     | string | oui      | Le nom du module Go. |
| `module_version`  | string | oui      | La version du module Go. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.info"
```

Exemple de résultat :

```json
{
  "Version": "v1.0.0",
  "Time": "1617822312 -0600"
}
```

## Télécharger le fichier module {#download-module-file}

Récupérer le fichier module `.mod` :

```plaintext
GET projects/:id/packages/go/:module_name/@v/:module_version.mod
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | oui      | L'ID du projet ou le chemin complet d'un projet. |
| `module_name`     | string | oui      | Le nom du module Go. |
| `module_version`  | string | oui      | La version du module Go. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.mod"
```

Écrire dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.mod" >> foo.mod
```

Cela écrit dans `foo.mod` dans le répertoire courant.

## Télécharger la source du module {#download-module-source}

Récupérer le `.zip` de la source du module :

```plaintext
GET projects/:id/packages/go/:module_name/@v/:module_version.zip
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | oui      | L'ID du projet ou le chemin complet d'un projet. |
| `module_name`     | string | oui      | Le nom du module Go. |
| `module_version`  | string | oui      | La version du module Go. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.zip"
```

Écrire dans un fichier :

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.zip" >> foo.zip
```

Cela écrit dans `foo.zip` dans le répertoire courant.
