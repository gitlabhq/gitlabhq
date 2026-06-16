---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des distributions de groupe Debian
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Déployé derrière un feature flag](../../administration/feature_flags/_index.md), désactivé par défaut.

{{< /history >}}

Utilisez cette API pour gérer les [distributions de groupe Debian](../../user/packages/debian_repository/_index.md). Cette API est protégée par un feature flag qui est désactivé par défaut. Pour utiliser cette API, vous devez [l'activer](#enable-the-debian-group-api).

> [!warning]
> Cette API est en cours de développement et n'est pas destinée à une utilisation en production.

## Activer l'API de groupe Debian {#enable-the-debian-group-api}

La prise en charge du dépôt de groupe Debian est encore en cours de développement. Elle est protégée par un feature flag qui est désactivé par défaut. [Les administrateurs GitLab ayant accès à la console GitLab Rails](../../administration/feature_flags/_index.md) peuvent choisir de l'activer. Pour l'activer, suivez les instructions dans [Activer l'API de groupe Debian](../../user/packages/debian_repository/_index.md#enable-the-debian-group-api).

## S'authentifier auprès des API de distributions Debian {#authenticate-to-the-debian-distributions-apis}

Voir [S'authentifier auprès des API de distributions Debian](../../user/packages/debian_repository/_index.md#authenticate-to-the-debian-distributions-apis).

## Lister toutes les distributions Debian dans un groupe {#list-all-debian-distributions-in-a-group}

Liste toutes les distributions Debian pour un groupe spécifié.

```plaintext
GET /groups/:id/-/debian_distributions
```

| Attribut  | Type            | Obligatoire | Description |
| ---------- | --------------- | -------- | ----------- |
| `id`       | entier ou chaîne  | oui      | L'ID ou le [chemin encodé en URL du groupe](../rest/_index.md#namespaced-paths). |
| `codename` | string          | non       | Filtrer avec un `codename` spécifique. |
| `suite`    | string          | non       | Filtrer avec un `suite` spécifique. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "codename": "sid",
    "suite": null,
    "origin": null,
    "label": null,
    "version": null,
    "description": null,
    "valid_time_duration_seconds": null,
    "components": [
      "main"
    ],
    "architectures": [
      "all",
      "amd64"
    ]
  }
]
```

## Récupérer une distribution de groupe Debian {#retrieve-a-debian-group-distribution}

Récupère une distribution de groupe Debian spécifiée pour un groupe.

```plaintext
GET /groups/:id/-/debian_distributions/:codename
```

| Attribut  | Type           | Obligatoire | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du groupe](../rest/_index.md#namespaced-paths). |
| `codename` | string         | oui      | Le `codename` d'une distribution. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions/unstable"
```

Exemple de réponse :

```json
{
  "id": 1,
  "codename": "sid",
  "suite": null,
  "origin": null,
  "label": null,
  "version": null,
  "description": null,
  "valid_time_duration_seconds": null,
  "components": [
    "main"
  ],
  "architectures": [
    "all",
    "amd64"
  ]
}
```

## Récupérer une clé de distribution de groupe Debian {#retrieve-a-debian-group-distribution-key}

Récupère une clé de distribution de groupe Debian spécifiée pour un groupe.

```plaintext
GET /groups/:id/-/debian_distributions/:codename/key.asc
```

| Attribut  | Type           | Obligatoire | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du groupe](../rest/_index.md#namespaced-paths). |
| `codename` | string         | oui      | Le `codename` d'une distribution. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions/unstable/key.asc"
```

Exemple de réponse :

```plaintext
-----BEGIN PGP PUBLIC KEY BLOCK-----
Comment: Alice's OpenPGP certificate
Comment: https://www.ietf.org/id/draft-bre-openpgp-samples-01.html

mDMEXEcE6RYJKwYBBAHaRw8BAQdArjWwk3FAqyiFbFBKT4TzXcVBqPTB3gmzlC/U
b7O1u120JkFsaWNlIExvdmVsYWNlIDxhbGljZUBvcGVucGdwLmV4YW1wbGU+iJAE
ExYIADgCGwMFCwkIBwIGFQoJCAsCBBYCAwECHgECF4AWIQTrhbtfozp14V6UTmPy
MVUMT0fjjgUCXaWfOgAKCRDyMVUMT0fjjukrAPoDnHBSogOmsHOsd9qGsiZpgRnO
dypvbm+QtXZqth9rvwD9HcDC0tC+PHAsO7OTh1S1TC9RiJsvawAfCPaQZoed8gK4
OARcRwTpEgorBgEEAZdVAQUBAQdAQv8GIa2rSTzgqbXCpDDYMiKRVitCsy203x3s
E9+eviIDAQgHiHgEGBYIACAWIQTrhbtfozp14V6UTmPyMVUMT0fjjgUCXEcE6QIb
DAAKCRDyMVUMT0fjjlnQAQDFHUs6TIcxrNTtEZFjUFm1M0PJ1Dng/cDW4xN80fsn
0QEA22Kr7VkCjeAEC08VSTeV+QFsmz55/lntWkwYWhmvOgE=
=iIGO
-----END PGP PUBLIC KEY BLOCK-----
```

## Créer une distribution de groupe Debian {#create-a-debian-group-distribution}

Crée une distribution de groupe Debian pour un groupe spécifié.

```plaintext
POST /groups/:id/-/debian_distributions
```

| Attribut                     | Type           | Obligatoire | Description |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du groupe](../rest/_index.md#namespaced-paths). |
| `codename`                    | string         | oui      | Le codename d'une distribution Debian. |
| `suite`                       | string         | non       | La suite de la nouvelle distribution Debian. |
| `origin`                      | string         | non       | L'origine de la nouvelle distribution Debian. |
| `label`                       | string         | non       | Le label de la nouvelle distribution Debian. |
| `version`                     | string         | non       | La version de la nouvelle distribution Debian. |
| `description`                 | string         | non       | La description de la nouvelle distribution Debian. |
| `valid_time_duration_seconds` | entier        | non       | La durée de validité (en secondes) de la nouvelle distribution Debian. |
| `components`                  | tableau de chaînes   | non       | La liste des composants de la nouvelle distribution Debian. |
| `architectures`               | tableau de chaînes   | non       | La liste des architectures de la nouvelle distribution Debian. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions?codename=sid"
```

Exemple de réponse :

```json
{
  "id": 1,
  "codename": "sid",
  "suite": null,
  "origin": null,
  "label": null,
  "version": null,
  "description": null,
  "valid_time_duration_seconds": null,
  "components": [
    "main"
  ],
  "architectures": [
    "all",
    "amd64"
  ]
}
```

## Mettre à jour une distribution de groupe Debian {#update-a-debian-group-distribution}

Met à jour une distribution de groupe Debian spécifiée pour un groupe.

```plaintext
PUT /groups/:id/-/debian_distributions/:codename
```

| Attribut                     | Type           | Obligatoire | Description |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du groupe](../rest/_index.md#namespaced-paths). |
| `codename`                    | string         | oui      | Le nouveau codename de la distribution Debian.  |
| `suite`                       | string         | non       | La nouvelle suite de la distribution Debian. |
| `origin`                      | string         | non       | La nouvelle origine de la distribution Debian. |
| `label`                       | string         | non       | Le nouveau label de la distribution Debian. |
| `version`                     | string         | non       | La nouvelle version de la distribution Debian. |
| `description`                 | string         | non       | La nouvelle description de la distribution Debian. |
| `valid_time_duration_seconds` | entier        | non       | La nouvelle durée de validité (en secondes) de la distribution Debian. |
| `components`                  | tableau de chaînes   | non       | La nouvelle liste des composants de la distribution Debian. |
| `architectures`               | tableau de chaînes   | non       | La nouvelle liste des architectures de la distribution Debian. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions/unstable?suite=new-suite&valid_time_duration_seconds=604800"
```

Exemple de réponse :

```json
{
  "id": 1,
  "codename": "sid",
  "suite": "new-suite",
  "origin": null,
  "label": null,
  "version": null,
  "description": null,
  "valid_time_duration_seconds": 604800,
  "components": [
    "main"
  ],
  "architectures": [
    "all",
    "amd64"
  ]
}
```

## Supprimer une distribution de groupe Debian {#delete-a-debian-group-distribution}

Supprime une distribution de groupe Debian spécifiée pour un groupe.

```plaintext
DELETE /groups/:id/-/debian_distributions/:codename
```

| Attribut  | Type           | Obligatoire | Description |
| ---------- | -------------- | -------- | ----------- |
| `id`       | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du groupe](../rest/_index.md#namespaced-paths). |
| `codename` | string         | oui      | Le codename de la distribution Debian. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/-/debian_distributions/unstable"
```
