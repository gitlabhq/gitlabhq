---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des miroirs distants de projet
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [miroirs distants](../user/project/repository/mirror/push.md). Vous pouvez interroger et modifier l'état de ces miroirs avec l'API de miroir distant.

Pour des raisons de sécurité, l'attribut `url` dans la réponse de l'API est toujours expurgé des informations de nom d'utilisateur et de mot de passe.

> [!note]
> [Les miroirs pull](../user/project/repository/mirror/pull.md) utilisent [un point de terminaison d'API différent](project_pull_mirroring.md#update-project-pull-mirroring-settings) pour les afficher et les mettre à jour.

## Lister tous les miroirs distants d'un projet {#list-all-remote-mirrors-for-a-project}

{{< history >}}

- Attribut `host_keys` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435) dans GitLab 18.4.

{{< /history >}}

Liste tous les miroirs distants d'un projet spécifié.

```plaintext
GET /projects/:id/remote_mirrors
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description                                                                      |
|-----------|-------------------|----------|----------------------------------------------------------------------------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths).       |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                   | Type    | Description |
|-----------------------------|---------|-------------|
| `auth_method`               | string  | Méthode d'authentification utilisée pour le miroir. |
| `enabled`                   | boolean | Si `true`, le miroir est activé. |
| `host_keys`                 | tableau   | Tableau des empreintes de clés d'hôte SSH pour le miroir distant. |
| `id`                        | entier | ID du miroir distant. |
| `keep_divergent_refs`       | boolean | Si `true`, les refs divergentes sont conservées lors de la mise en miroir. |
| `last_error`                | string  | Message d'erreur de la dernière tentative de miroir. `null` si réussie. |
| `last_successful_update_at` | string  | Horodatage de la dernière mise à jour réussie du miroir. Format ISO 8601. |
| `last_update_at`            | string  | Horodatage de la dernière tentative de miroir. Format ISO 8601. |
| `last_update_started_at`    | string  | Horodatage du début de la dernière tentative de miroir. Format ISO 8601. |
| `only_protected_branches`   | boolean | Si `true`, seules les branches protégées sont mises en miroir. |
| `update_status`             | string  | Statut de la mise à jour du miroir. Valeurs possibles : `none`, `scheduled`, `started`, `finished`, `failed`. |
| `url`                       | string  | URL du miroir avec les identifiants expurgés pour des raisons de sécurité. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors"
```

Exemple de réponse :

```json
[
  {
    "enabled": true,
    "id": 101486,
    "auth_method": "ssh_public_key",
    "last_error": null,
    "last_successful_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_started_at": "2020-01-06T17:31:55.864Z",
    "only_protected_branches": true,
    "keep_divergent_refs": true,
    "update_status": "finished",
    "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
    "host_keys": [
      {
        "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
      }
    ]
  }
]
```

## Récupérer un miroir distant pour un projet {#retrieve-a-remote-mirror-for-a-project}

{{< history >}}

- Attribut `host_keys` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435) dans GitLab 18.4.

{{< /history >}}

Récupère un miroir distant spécifié pour un projet.

```plaintext
GET /projects/:id/remote_mirrors/:mirror_id
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `id`        | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `mirror_id` | entier           | Oui      | ID du miroir distant. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                   | Type    | Description |
|-----------------------------|---------|-------------|
| `enabled`                   | boolean | Si `true`, le miroir est activé. |
| `id`                        | entier | ID du miroir distant. |
| `host_keys`                 | tableau   | Tableau des empreintes de clés d'hôte SSH pour le miroir distant. |
| `keep_divergent_refs`       | boolean | Si `true`, les refs divergentes sont conservées lors de la mise en miroir. |
| `last_error`                | string  | Message d'erreur de la dernière tentative de miroir. `null` si réussie. |
| `last_successful_update_at` | string  | Horodatage de la dernière mise à jour réussie du miroir. Format ISO 8601. |
| `last_update_at`            | string  | Horodatage de la dernière tentative de miroir. Format ISO 8601. |
| `last_update_started_at`    | string  | Horodatage du début de la dernière tentative de miroir. Format ISO 8601. |
| `only_protected_branches`   | boolean | Si `true`, seules les branches protégées sont mises en miroir. |
| `update_status`             | string  | Statut de la mise à jour du miroir. Valeurs possibles : `none`, `scheduled`, `started`, `finished`, `failed`. |
| `url`                       | string  | URL du miroir avec les identifiants expurgés pour des raisons de sécurité. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```

Exemple de réponse :

```json
{
  "enabled": true,
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "only_protected_branches": true,
  "keep_divergent_refs": true,
  "update_status": "finished",
  "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
  "host_keys": [
    {
      "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
    }
  ]
}
```

## Récupérer une clé publique pour un miroir distant {#retrieve-a-public-key-for-a-remote-mirror}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180291) dans GitLab 17.9.

{{< /history >}}

Récupère la clé publique d'un miroir distant spécifié qui utilise l'authentification SSH.

```plaintext
GET /projects/:id/remote_mirrors/:mirror_id/public_key
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `id`        | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `mirror_id` | entier           | Oui      | ID du miroir distant. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut   | Type   | Description                        |
|-------------|--------|------------------------------------|
| `public_key`| string | Clé publique du miroir distant.  |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486/public_key"
```

Exemple de réponse :

```json
{
  "public_key": "ssh-rsa AAAAB3NzaC1yc2EA..."
}
```

## Créer un miroir pull {#create-a-pull-mirror}

Apprenez à [configurer un miroir pull](project_pull_mirroring.md#update-project-pull-mirroring-settings) en utilisant l'API de mise en miroir pull de projet.

## Créer un miroir push {#create-a-push-mirror}

{{< history >}}

- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) dans GitLab 16.0.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/410354) dans GitLab 16.2. L'indicateur de fonctionnalité `mirror_only_branches_match_regex` a été supprimé.
- Champ `auth_method` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75155) dans GitLab 16.10.
- Attribut `host_keys` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435) dans GitLab 18.4.

{{< /history >}}

> [!note]
> Chaque projet peut avoir un maximum de 10 miroirs push activés. Pour plus d'informations, consultez [le nombre maximum de miroirs push de projet](../administration/instance_limits.md#maximum-number-of-project-push-mirrors).

Créez un miroir push pour un projet. La mise en miroir push est désactivée par défaut. Pour l'activer, incluez le paramètre facultatif `enabled` lors de la création du miroir.

```plaintext
POST /projects/:id/remote_mirrors
```

Attributs pris en charge :

| Attribut                 | Type              | Obligatoire | Description |
|---------------------------|-------------------|----------|-------------|
| `id`                      | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `url`                     | string            | Oui      | URL cible vers laquelle le dépôt est mis en miroir. |
| `auth_method`             | string            | Non       | Méthode d'authentification du miroir. Valeurs acceptées : `ssh_public_key`, `password`. |
| `enabled`                 | boolean           | Non       | Si `true`, le miroir est activé. |
| `host_keys`               | tableau de chaînes  | Non       | Clés d'hôte SSH au format simple (`ssh-ed25519 AAAA...`) ou au format complet `known_hosts` (`hostname ssh-ed25519 AAAA...`). Les clés simples utilisent le nom d'hôte de l'URL du miroir. |
| `keep_divergent_refs`     | boolean           | Non       | Si `true`, les refs divergentes sont conservées lors de la mise en miroir. |
| `mirror_branch_regex`     | string            | Non       | Expression régulière pour les noms de branches à mettre en miroir. Seules les branches dont les noms correspondent à l'expression régulière sont mises en miroir. Nécessite que `only_protected_branches` soit désactivé. Premium et Ultimate uniquement. |
| `only_protected_branches` | boolean           | Non       | Si `true`, seules les branches protégées sont mises en miroir. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                   | Type    | Description |
|-----------------------------|---------|-------------|
| `auth_method`               | string  | Méthode d'authentification utilisée pour le miroir. |
| `enabled`                   | boolean | Si `true`, le miroir est activé. |
| `host_keys`                 | tableau   | Tableau des empreintes de clés d'hôte SSH pour le miroir distant. |
| `id`                        | entier | ID du miroir distant. |
| `keep_divergent_refs`       | boolean | Si `true`, les refs divergentes sont conservées lors de la mise en miroir. |
| `last_error`                | string  | Message d'erreur de la dernière tentative de miroir. `null` si réussie. |
| `last_successful_update_at` | string  | Horodatage de la dernière mise à jour réussie du miroir. Format ISO 8601. |
| `last_update_at`            | string  | Horodatage de la dernière tentative de miroir. Format ISO 8601. |
| `last_update_started_at`    | string  | Horodatage du début de la dernière tentative de miroir. Format ISO 8601. |
| `only_protected_branches`   | boolean | Si `true`, seules les branches protégées sont mises en miroir. |
| `update_status`             | string  | Statut de la mise à jour du miroir. Valeurs possibles : `none`, `scheduled`, `started`, `finished`, `failed`. |
| `url`                       | string  | URL du miroir avec les identifiants expurgés pour des raisons de sécurité. |

Exemple de requête :

```shell
curl --request POST \
  --data "url=https://username:token@example.com/gitlab/example.git" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors"
```

Exemple de réponse :

```json
{
    "enabled": false,
    "id": 101486,
    "auth_method": "password",
    "last_error": null,
    "last_successful_update_at": null,
    "last_update_at": null,
    "last_update_started_at": null,
    "only_protected_branches": false,
    "keep_divergent_refs": false,
    "update_status": "none",
    "url": "https://*****:*****@example.com/gitlab/example.git",
    "host_keys": [
      {
        "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
      }
    ]
}
```

## Mettre à jour un miroir distant dans un projet {#update-a-remote-mirror-in-a-project}

{{< history >}}

- Champ `auth_method` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75155) dans GitLab 16.10.
- Attribut `host_keys` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435) dans GitLab 18.4.

{{< /history >}}

Met à jour la configuration ou le statut opérationnel d'un miroir distant spécifié.

```plaintext
PUT /projects/:id/remote_mirrors/:mirror_id
```

Attributs pris en charge :

| Attribut                 | Type              | Obligatoire | Description |
|---------------------------|-------------------|----------|-------------|
| `id`                      | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `mirror_id`               | entier           | Oui      | ID du miroir distant. |
| `auth_method`             | string            | Non       | Méthode d'authentification du miroir. Valeurs acceptées : `ssh_public_key`, `password`. |
| `enabled`                 | boolean           | Non       | Si `true`, le miroir est activé. |
| `host_keys`               | tableau de chaînes  | Non       | Clés d'hôte SSH au format simple (`ssh-ed25519 AAAA...`) ou au format complet `known_hosts` (`hostname ssh-ed25519 AAAA...`). Les clés simples utilisent le nom d'hôte de l'URL du miroir. |
| `keep_divergent_refs`     | boolean           | Non       | Si `true`, les refs divergentes sont conservées lors de la mise en miroir. |
| `mirror_branch_regex`     | string            | Non       | Expression régulière pour les noms de branches à mettre en miroir. Seules les branches dont les noms correspondent à l'expression régulière sont mises en miroir. Ne fonctionne pas avec `only_protected_branches` activé. Premium et Ultimate uniquement. |
| `only_protected_branches` | boolean           | Non       | Si `true`, seules les branches protégées sont mises en miroir. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                   | Type    | Description |
|-----------------------------|---------|-------------|
| `auth_method`               | string  | Méthode d'authentification utilisée pour le miroir. |
| `enabled`                   | boolean | Si `true`, le miroir est activé. |
| `host_keys`                 | tableau   | Tableau des empreintes de clés d'hôte SSH pour le miroir distant. |
| `id`                        | entier | ID du miroir distant. |
| `keep_divergent_refs`       | boolean | Si `true`, les refs divergentes sont conservées lors de la mise en miroir. |
| `last_error`                | string  | Message d'erreur de la dernière tentative de miroir. `null` si réussie. |
| `last_successful_update_at` | string  | Horodatage de la dernière mise à jour réussie du miroir. Format ISO 8601. |
| `last_update_at`            | string  | Horodatage de la dernière tentative de miroir. Format ISO 8601. |
| `last_update_started_at`    | string  | Horodatage du début de la dernière tentative de miroir. Format ISO 8601. |
| `only_protected_branches`   | boolean | Si `true`, seules les branches protégées sont mises en miroir. |
| `update_status`             | string  | Statut de la mise à jour du miroir. Valeurs possibles : `none`, `scheduled`, `started`, `finished`, `failed`. |
| `url`                       | string  | URL du miroir avec les identifiants expurgés pour des raisons de sécurité. |

Exemple de requête :

```shell
curl --request PUT \
  --data "enabled=false" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```

Exemple de réponse :

```json
{
    "enabled": false,
    "id": 101486,
    "auth_method": "password",
    "last_error": null,
    "last_successful_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_started_at": "2020-01-06T17:31:55.864Z",
    "only_protected_branches": true,
    "keep_divergent_refs": true,
    "update_status": "finished",
    "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
    "host_keys": [
      {
        "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
      }
    ]
}
```

## Forcer la mise à jour du miroir push {#force-push-mirror-update}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/388907) dans GitLab 16.11.

{{< /history >}}

[Forcer une mise à jour](../user/project/repository/mirror/_index.md#force-an-update) d'un miroir push.

```plaintext
POST /projects/:id/remote_mirrors/:mirror_id/sync
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `id`        | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `mirror_id` | entier           | Oui      | ID du miroir distant. |

En cas de succès, renvoie [`204 No Content`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486/sync"
```

## Supprimer un miroir distant d'un projet {#delete-a-remote-mirror-from-a-project}

Supprime un miroir distant spécifié d'un projet.

```plaintext
DELETE /projects/:id/remote_mirrors/:mirror_id
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `id`        | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `mirror_id` | entier           | Oui      | ID du miroir distant. |

En cas de succès, renvoie [`204 No Content`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```
