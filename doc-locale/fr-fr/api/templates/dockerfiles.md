---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Dockerfiles
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab fournit un point de terminaison d'API pour les modèles Dockerfile disponibles pour l'ensemble de l'instance. Les modèles par défaut sont définis dans [`vendor/Dockerfile`](https://gitlab.com/gitlab-org/gitlab-foss/-/tree/master/vendor/Dockerfile) dans le dépôt GitLab.

Les utilisateurs disposant du rôle Invité ne peuvent pas accéder aux modèles Dockerfiles. Pour plus d'informations, consultez [Visibilité des projets et des groupes](../../user/public_access.md).

## Remplacer les modèles de l'API Dockerfile {#override-dockerfile-api-templates}

{{< details >}}

- Édition :  GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Dans les niveaux [GitLab Premium et Ultimate](https://about.gitlab.com/pricing/) , les administrateurs d'instance GitLab peuvent remplacer les modèles dans la [zone **Admin**](../../administration/settings/instance_template_repository.md).

## Lister tous les modèles Dockerfile {#list-all-dockerfile-templates}

Liste tous les modèles Dockerfile.

```plaintext
GET /templates/dockerfiles
```

Exemple de requête :

```shell
curl "https://gitlab.example.com/api/v4/templates/dockerfiles"
```

Exemple de réponse :

```json
[
  {
    "key": "Binary",
    "name": "Binary"
  },
  {
    "key": "Binary-alpine",
    "name": "Binary-alpine"
  },
  {
    "key": "Binary-scratch",
    "name": "Binary-scratch"
  },
  {
    "key": "Golang",
    "name": "Golang"
  },
  {
    "key": "Golang-alpine",
    "name": "Golang-alpine"
  },
  {
    "key": "Golang-scratch",
    "name": "Golang-scratch"
  },
  {
    "key": "HTTPd",
    "name": "HTTPd"
  },
  {
    "key": "Node",
    "name": "Node"
  },
  {
    "key": "Node-alpine",
    "name": "Node-alpine"
  },
  {
    "key": "OpenJDK",
    "name": "OpenJDK"
  },
  {
    "key": "PHP",
    "name": "PHP"
  },
  {
    "key": "Python",
    "name": "Python"
  },
  {
    "key": "Python-alpine",
    "name": "Python-alpine"
  },
  {
    "key": "Python2",
    "name": "Python2"
  },
  {
    "key": "Ruby",
    "name": "Ruby"
  },
  {
    "key": "Ruby-alpine",
    "name": "Ruby-alpine"
  },
  {
    "key": "Rust",
    "name": "Rust"
  },
  {
    "key": "Swift",
    "name": "Swift"
  }
]
```

## Récupérer un seul modèle Dockerfile {#retrieve-a-single-dockerfile-template}

Récupère un seul modèle Dockerfile.

```plaintext
GET /templates/dockerfiles/:key
```

| Attribut | Type   | Obligatoire | Description |
|-----------|--------|----------|-------------|
| `key`     | string | oui      | La clé du modèle Dockerfile |

Exemple de requête :

```shell
curl "https://gitlab.example.com/api/v4/templates/dockerfiles/Binary"
```

Exemple de réponse :

```json
{
  "name": "Binary",
  "content": "# This file is a template, and might need editing before it works on your project.\n# This Dockerfile installs a compiled binary into a bare system.\n# You must either commit your compiled binary into source control (not recommended)\n# or build the binary first as part of a CI/CD pipeline.\n\nFROM buildpack-deps:buster\n\nWORKDIR /usr/local/bin\n\n# Change `app` to whatever your binary is called\nAdd app .\nCMD [\"./app\"]\n"
}
```
