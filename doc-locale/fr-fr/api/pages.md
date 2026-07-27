---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Pages
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour [administrer](../administration/pages/_index.md) et [utiliser](../user/project/pages/_index.md) GitLab Pages.

La fonctionnalité GitLab Pages doit être activée pour utiliser ces endpoints.

## Dépublier Pages {#unpublish-pages}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/498658) du rôle minimum requis, passant de l'accès administrateur au rôle Maintainer dans GitLab 17.9

{{< /history >}}

Dépublie et supprime Pages du projet spécifié.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

```plaintext
DELETE /projects/:id/pages
```

| Attribut | Type           | Obligatoire | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/2/pages"
```

## Récupérer les paramètres Pages pour un projet {#retrieve-pages-settings-for-a-project}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/436932) dans GitLab 16.8.

{{< /history >}}

Récupère les paramètres Pages pour un projet spécifié.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

```plaintext
GET /projects/:id/pages
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                                 | Type       | Description                                                                                                                  |
| ----------------------------------------- | ---------- | -----------------------                                                                                                      |
| `url`                                     | string     | URL pour accéder aux Pages de ce projet.                                                                                            |
| `is_unique_domain_enabled`                | boolean    | Si le [domaine unique](../user/project/pages/introduction.md) est activé.                                                        |
| `force_https`                             | boolean    | `true` si le projet est configuré pour forcer le HTTPS.                                                                                      |
| `deployments[]`                           | tableau      | Liste des déploiements actifs actuels.                                                                                          |
| `primary_domain`                          | string     | Domaine principal vers lequel rediriger toutes les requêtes Pages. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/481334) dans GitLab 17.8. |

| Attribut `deployments[]`                 | Type       | Description                                                                                                                   |
| ----------------------------------------- | ---------- |-------------------------------------------------------------------------------------------------------------------------------|
| `created_at`                              | date       | Date de création du déploiement.                                                                                                  |
| `url`                                     | string     | URL pour ce déploiement.                                                                                                      |
| `path_prefix`                             | string     | Préfixe de chemin de ce déploiement lors de l'utilisation des [déploiements parallèles](../user/project/pages/_index.md#parallel-deployments). |
| `root_directory`                          | string     | Répertoire racine.                                                                                                               |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/2/pages"
```

Exemple de réponse :

```json
{
  "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010",
  "is_unique_domain_enabled": true,
  "force_https": false,
  "deployments": [
    {
      "created_at": "2024-01-05T18:58:14.916Z",
      "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010/",
      "path_prefix": "",
      "root_directory": null
    },
    {
      "created_at": "2024-01-05T18:58:46.042Z",
      "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010/mr3",
      "path_prefix": "mr3",
      "root_directory": null
    }
  ],
  "primary_domain": null
}
```

## Mettre à jour les paramètres Pages pour un projet {#update-pages-settings-for-a-project}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147227) dans GitLab 17.0.
- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/498658) du rôle minimum requis, passant de l'accès administrateur au rôle Maintainer dans GitLab 17.9

{{< /history >}}

Met à jour les paramètres Pages pour le projet spécifié.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

```plaintext
PATCH /projects/:id/pages
```

Attributs pris en charge :

| Attribut                       | Type           | Obligatoire | Description                                                                                                         |
| --------------------------------| -------------- | -------- | --------------------------------------------------------------------------------------------------------------------|
| `id`                            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths)                                 |
| `pages_unique_domain_enabled`   | boolean        | Non       | Utiliser ou non le domaine unique                                                                                        |
| `pages_https_only`              | boolean        | Non       | Forcer ou non le HTTPS                                                                                              |
| `pages_primary_domain`          | string         | Non       | Définissez le domaine principal parmi les domaines assignés existants pour rediriger toutes les requêtes Pages vers celui-ci. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/481334) dans GitLab 17.8. |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                                 | Type       | Description                                                                                                                  |
| ----------------------------------------- | ---------- | -----------------------                                                                                                      |
| `url`                                     | string     | URL pour accéder aux Pages de ce projet.                                                                                            |
| `is_unique_domain_enabled`                | boolean    | Si le [domaine unique](../user/project/pages/introduction.md) est activé.                                                        |
| `force_https`                             | boolean    | `true` si le projet est configuré pour forcer le HTTPS.                                                                                      |
| `deployments[]`                           | tableau      | Liste des déploiements actifs actuels.                                                                                          |
| `primary_domain`                          | string     | Domaine principal vers lequel rediriger toutes les requêtes Pages. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/481334) dans GitLab 17.8. |

| Attribut `deployments[]`                 | Type       | Description                                                                                                                   |
| ----------------------------------------- | ---------- |-------------------------------------------------------------------------------------------------------------------------------|
| `created_at`                              | date       | Date de création du déploiement.                                                                                                  |
| `url`                                     | string     | URL pour ce déploiement.                                                                                                      |
| `path_prefix`                             | string     | Préfixe de chemin de ce déploiement lors de l'utilisation des [déploiements parallèles](../user/project/pages/_index.md#parallel-deployments). |
| `root_directory`                          | string     | Répertoire racine.                                                                                                               |

Exemple de requête :

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/pages" \
  --form 'pages_unique_domain_enabled=true' \
  --form 'pages_https_only=true' \
  --form 'pages_primary_domain=https://custom.example.com'
```

Exemple de réponse :

```json
{
  "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010",
  "is_unique_domain_enabled": true,
  "force_https": false,
  "deployments": [
    {
      "created_at": "2024-01-05T18:58:14.916Z",
      "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010/",
      "path_prefix": "",
      "root_directory": null
    },
    {
      "created_at": "2024-01-05T18:58:46.042Z",
      "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010/mr3",
      "path_prefix": "mr3",
      "root_directory": null
    }
  ],
  "primary_domain": null
}
```
