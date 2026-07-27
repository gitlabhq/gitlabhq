---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API de registre virtuel Maven
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : Bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161615) dans GitLab 17.4 [avec un flag](../administration/feature_flags/_index.md) nommé `virtual_registry_maven`. Désactivé par défaut.
- Le feature flag a été [modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) vers `maven_virtual_registry` dans GitLab 18.1. Désactivé par défaut. L'indicateur de fonctionnalité `virtual_registry_maven` a été supprimé.
- [Passage](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) de l'expérimentation à la version bêta dans GitLab 18.1.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) dans GitLab 18.2.

{{< /history >}}

> [!flag]
> La disponibilité de ces endpoints est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Utilisez cette API pour :

- Créer et gérer des registres virtuels Maven.
- Configurer des registres en amont.
- Gérer les entrées de cache.
- Gérer les téléchargements et les chargements de packages.

## Gérer les registres virtuels Maven {#manage-maven-virtual-registries}

Utilisez les endpoints suivants pour créer et gérer des registres virtuels Maven.

### Lister tous les registres virtuels {#list-all-virtual-registries}

{{< history >}}

- `downloads_count` et `downloaded_at` [introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201790) dans GitLab 18.4.

{{< /history >}}

Liste tous les registres virtuels Maven pour un groupe spécifié.

```plaintext
GET /groups/:id/-/virtual_registries/packages/maven/registries
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:-----|:---------|:------------|
| `id` | chaîne/entier | oui | L'ID du groupe ou le chemin complet du groupe. Doit être un groupe principal. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/registries"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "group_id": 5,
    "name": "my-virtual-registry",
    "description": "My virtual registry",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### Créer un registre virtuel {#create-a-virtual-registry}

Crée un registre virtuel Maven pour un groupe spécifié.

```plaintext
POST /groups/:id/-/virtual_registries/packages/maven/registries
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | chaîne/entier | oui | L'ID du groupe ou le chemin complet du groupe. Doit être un groupe principal. |
| `name` | string | oui | Le nom du registre virtuel. |
| `description` | string | non | La description du registre virtuel. |

Exemple de requête :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"name": "my-virtual-registry", "description": "My virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/registries"
```

Exemple de réponse :

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-virtual-registry",
  "description": "My virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### Récupérer un registre virtuel {#retrieve-a-virtual-registry}

Récupère un registre virtuel Maven spécifié.

```plaintext
GET /virtual_registries/packages/maven/registries/:id
```

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | oui | L'ID du registre virtuel Maven. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-virtual-registry",
  "description": "My virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### Mettre à jour un registre virtuel {#update-a-virtual-registry}

Met à jour un registre virtuel Maven spécifié.

```plaintext
PATCH /virtual_registries/packages/maven/registries/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | oui | L'ID du registre virtuel Maven. |
| `name` | string | oui | Le nom du registre virtuel. |
| `description` | string | non | La description du registre virtuel. |

Exemple de requête :

```shell
curl --request PATCH \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"name": "my-virtual-registry", "description": "My virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1"
```

En cas de succès, renvoie un code de statut [`200 OK`](rest/troubleshooting.md#status-codes).

### Supprimer un registre virtuel {#delete-a-virtual-registry}

> [!warning]
> La suppression d'un registre virtuel supprime également tous les registres en amont associés qui ne sont pas partagés avec d'autres registres virtuels, ainsi que leurs entrées de cache.

Supprime un registre virtuel Maven spécifié.

```plaintext
DELETE /virtual_registries/packages/maven/registries/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | oui | L'ID du registre virtuel Maven. |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1"
```

En cas de succès, renvoie un code de statut [`204 No Content`](rest/troubleshooting.md#status-codes).

### Supprimer les entrées de cache d'un registre virtuel {#delete-cache-entries-for-a-virtual-registry}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/538327) dans GitLab 18.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `maven_virtual_registry`. Activé par défaut.

{{< /history >}}

Planifie la suppression de toutes les entrées de cache dans tous les registres en amont exclusifs pour un registre virtuel Maven. La suppression des entrées de cache n'est pas planifiée pour les registres en amont associés à d'autres registres virtuels.

```plaintext
DELETE /virtual_registries/packages/maven/registries/:id/cache
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | oui | L'ID du registre virtuel Maven. |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1/cache"
```

En cas de succès, renvoie un code de statut [`204 No Content`](rest/troubleshooting.md#status-codes).

## Gérer les registres en amont {#manage-upstream-registries}

Utilisez les endpoints suivants pour configurer et gérer les registres Maven en amont.

### Lister tous les registres en amont {#list-all-upstream-registries}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/550728) dans GitLab 18.3 [avec un flag](../administration/feature_flags/_index.md) nommé `maven_virtual_registry`. Activé par défaut.
- `upstream_name` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/561675) dans GitLab 18.4.

{{< /history >}}

Liste tous les registres Maven en amont pour un groupe principal spécifié.

```plaintext
GET /groups/:id/-/virtual_registries/packages/maven/upstreams
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:-----|:---------|:------------|
| `id` | chaîne/entier | oui | L'ID du groupe ou le chemin complet du groupe. Doit être un groupe principal. |
| `page` | integer | non | Le numéro de page. La valeur par défaut est 1. |
| `per_page` | integer | non | Le nombre d'éléments par page. La valeur par défaut est 20. |
| `upstream_name` | string | non | Le nom du registre en amont pour le filtrage par recherche approximative par nom. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/upstreams"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://repo.maven.apache.org/maven2",
    "name": "Maven Central",
    "description": "Maven Central repository",
    "cache_validity_hours": 24,
    "metadata_cache_validity_hours": 24,
    "username": "user",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### Tester la connexion au registre en amont avant la création {#test-upstream-registry-connection-before-creation}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/535637) dans GitLab 18.3 [avec un flag](../administration/feature_flags/_index.md) nommé `maven_virtual_registry`. Activé par défaut.

{{< /history >}}

Teste la connexion à un registre Maven en amont qui n'a pas encore été ajouté au registre virtuel. Cet endpoint valide la connectivité et les identifiants avant de créer le registre en amont.

```plaintext
POST /groups/:id/-/virtual_registries/packages/maven/upstreams/test
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:-----|:---------|:------------|
| `id` | chaîne/entier | Oui | L'ID du groupe ou le chemin complet du groupe. Doit être un groupe principal. |
| `url` | string | Oui | L'URL du registre en amont. |
| `password` | string | Non | Le mot de passe du registre en amont. |
| `username` | string | Non | Le nom d'utilisateur du registre en amont. |

> [!note]
> Vous devez inclure à la fois `username` et `password` dans la requête, ou n'inclure ni l'un ni l'autre. Si non défini, une requête publique (anonyme) est utilisée pour tester la connexion.

#### Flux de test {#test-workflow}

L'endpoint `test` envoie une requête HEAD à l'URL en amont fournie en utilisant un chemin de test pour valider la connectivité et l'authentification. La réponse reçue de la requête HEAD est interprétée comme suit :

| Réponse en amont | Description | Résultat |
|:------------------|:--------|:-------|
| 2XX | Succès - en amont accessible | `{ "success": true }` |
| 404 | Succès - en amont accessible, mais l'artefact de test est introuvable | `{ "success": true }` |
| 401 | Échec de l'authentification | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | Accès interdit | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | Erreur du serveur en amont | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| Erreurs réseau | Problèmes de connexion ou d'expiration | `{ "success": false, "result": "Error: Connection timeout" }` |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/upstreams/test" \
     --data '{"url": "https://repo.maven.apache.org/maven2"}'
```

Exemple de réponse :

```json
{
  "success": true
}
```

### Lister tous les registres en amont pour un registre virtuel {#list-all-upstream-registries-for-a-virtual-registry}

Liste tous les registres Maven en amont pour un registre virtuel spécifié.

```plaintext
GET /virtual_registries/packages/maven/registries/:id/upstreams
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:-----|:---------|:------------|
| `id` | integer | oui | L'ID du registre virtuel Maven. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1/upstreams"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://repo.maven.apache.org/maven2",
    "name": "Maven Central",
    "description": "Maven Central repository",
    "cache_validity_hours": 24,
    "metadata_cache_validity_hours": 24,
    "username": "user",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z",
    "registry_upstream": {
      "id": 1,
      "registry_id": 1,
      "position": 1
    }
  }
]
```

### Créer un registre en amont {#create-an-upstream-registry}

{{< history >}}

- `metadata_cache_validity_hours` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/556138) dans GitLab 18.3.

{{< /history >}}

Crée un registre en amont pour un registre virtuel Maven spécifié.

```plaintext
POST /virtual_registries/packages/maven/registries/:id/upstreams
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | Oui | L'ID du registre virtuel Maven. |
| `url` | string | Oui | L'URL du registre en amont. |
| `cache_validity_hours` | integer | Non | La période de validité du cache. La valeur par défaut est 24 heures. |
| `description` | string | Non | La description du registre en amont. |
| `metadata_cache_validity_hours` | integer | Non | La période de validité du cache de métadonnées. La valeur par défaut est 24 heures. |
| `name` | string | Non | Le nom du registre en amont. |
| `password` | string | Non | Le mot de passe du registre en amont. |
| `username` | string | Non | Le nom d'utilisateur du registre en amont. |

> [!note]
> Vous devez inclure à la fois `username` et `password` dans la requête, ou ne pas les inclure du tout. Si non défini, une requête publique (anonyme) est utilisée pour accéder au registre en amont.
>
> Vous ne pouvez pas ajouter deux registres en amont avec la même URL et les mêmes identifiants (`username` et `password`) au même groupe principal. À la place, vous pouvez :
>
> - Définir des identifiants différents pour chaque registre en amont avec la même URL.
> - [Associer un registre en amont](#associate-an-upstream-registry-with-a-virtual-registry) à plusieurs registres virtuels.

Exemple de requête :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "https://repo.maven.apache.org/maven2", "name": "Maven Central", "description": "Maven Central repository", "username": <your_username>, "password": <your_password>, "cache_validity_hours": 48, "metadata_cache_validity_hours": 1}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1/upstreams"
```

Exemple de réponse :

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://repo.maven.apache.org/maven2",
  "name": "Maven Central",
  "description": "Maven Central repository",
  "cache_validity_hours": 48,
  "metadata_cache_validity_hours": 1,
  "username": "user",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z",
  "registry_upstream": {
    "id": 1,
    "registry_id": 1,
    "position": 1
  }
}
```

### Récupérer un registre en amont {#retrieve-an-upstream-registry}

Récupère un registre en amont spécifié.

```plaintext
GET /virtual_registries/packages/maven/upstreams/:id
```

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | oui | L'ID du registre en amont. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://repo.maven.apache.org/maven2",
  "name": "Maven Central",
  "description": "Maven Central repository",
  "cache_validity_hours": 24,
  "metadata_cache_validity_hours": 24,
  "username": "user",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z",
  "registry_upstreams": [
    {
      "id": 1,
      "registry_id": 1,
      "position": 1
    }
  ]
}
```

### Mettre à jour un registre en amont {#update-an-upstream-registry}

{{< history >}}

- `metadata_cache_validity_hours` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/556138) dans GitLab 18.3.

{{< /history >}}

Met à jour un registre en amont spécifié.

```plaintext
PATCH /virtual_registries/packages/maven/upstreams/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | Oui | L'ID du registre en amont. |
| `cache_validity_hours` | integer | Non | La période de validité du cache. La valeur par défaut est 24 heures. |
| `description` | string | Non | La description du registre en amont. |
| `metadata_cache_validity_hours` | integer | Non | La période de validité du cache de métadonnées. La valeur par défaut est 24 heures. |
| `name` | string | Non | Le nom du registre en amont. |
| `password` | string | Non | Le mot de passe du registre en amont. |
| `url` | string | Non | L'URL du registre en amont. |
| `username` | string | Non | Le nom d'utilisateur du registre en amont. |

> [!note]
> Vous devez fournir au moins un des paramètres optionnels dans votre requête.
>
> Les valeurs `username` et `password` doivent être fournies ensemble, ou ne pas être fournies du tout. Si non défini, une requête publique (anonyme) est utilisée pour accéder au registre en amont.

Exemple de requête :

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"cache_validity_hours": 72}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1"
```

En cas de succès, renvoie un code de statut [`200 OK`](rest/troubleshooting.md#status-codes).

### Mettre à jour la position d'un registre en amont {#update-an-upstream-registry-position}

Met à jour la position d'un registre en amont dans une liste ordonnée pour un registre virtuel Maven.

```plaintext
PATCH /virtual_registries/packages/maven/registry_upstreams/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | oui | L'ID du registre en amont. |
| `position` | integer | oui | La position du registre en amont. Entre 1 et 20. |

Exemple de requête :

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"position": 5}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registry_upstreams/1"
```

En cas de succès, renvoie un code de statut [`200 OK`](rest/troubleshooting.md#status-codes).

### Supprimer un registre en amont {#delete-an-upstream-registry}

Supprime un registre en amont spécifié.

```plaintext
DELETE /virtual_registries/packages/maven/upstreams/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | oui | L'ID du registre en amont. |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1"
```

En cas de succès, renvoie un code de statut [`204 No Content`](rest/troubleshooting.md#status-codes).

### Associer un registre en amont à un registre virtuel {#associate-an-upstream-registry-with-a-virtual-registry}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) dans GitLab 18.1 [avec un indicateur](../administration/feature_flags/_index.md) nommé `maven_virtual_registry`. Désactivé par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) dans GitLab 18.2.

{{< /history >}}

Associe un registre en amont existant à un registre virtuel Maven spécifié.

```plaintext
POST /virtual_registries/packages/maven/registry_upstreams
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `registry_id` | integer | oui | L'ID du registre virtuel Maven. |
| `upstream_id` | integer | oui | L'ID du registre Maven en amont. |

Exemple de requête :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"registry_id": 1, "upstream_id": 2}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registry_upstreams"
```

Exemple de réponse :

```json
{
  "id": 5,
  "registry_id": 1,
  "upstream_id": 2,
  "position": 2
}
```

### Dissocier un registre en amont d'un registre virtuel {#disassociate-an-upstream-registry-from-a-virtual-registry}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) dans GitLab 18.1 [avec un indicateur](../administration/feature_flags/_index.md) nommé `maven_virtual_registry`. Désactivé par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) dans GitLab 18.2.

{{< /history >}}

Dissocie un registre en amont d'un registre virtuel Maven spécifié.

```plaintext
DELETE /virtual_registries/packages/maven/registry_upstreams/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | oui | L'ID de l'association entre le registre et le registre en amont. |

Exemple de requête :

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registry_upstreams/1"
```

En cas de succès, renvoie un code de statut [`204 No Content`](rest/troubleshooting.md#status-codes).

### Supprimer les entrées de cache d'un registre en amont {#delete-cache-entries-for-an-upstream-registry}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/538327) dans GitLab 18.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `maven_virtual_registry`. Activé par défaut.

{{< /history >}}

Planifie la suppression de toutes les entrées de cache pour un registre en amont spécifié.

```plaintext
DELETE /virtual_registries/packages/maven/upstreams/:id/cache
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | oui | L'ID du registre en amont. |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/cache"
```

En cas de succès, renvoie un code de statut [`204 No Content`](rest/troubleshooting.md#status-codes).

### Tester la connexion au registre en amont {#test-upstream-registry-connection}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/535637) dans GitLab 18.3 [avec un flag](../administration/feature_flags/_index.md) nommé `maven_virtual_registry`. Activé par défaut.

{{< /history >}}

Teste la connexion à un registre Maven en amont spécifié.

```plaintext
GET /virtual_registries/packages/maven/upstreams/:id/test
```

#### Fonctionnement du test {#how-the-test-works}

L'endpoint effectue une requête HEAD vers l'URL en amont en utilisant le chemin de test pour valider la connectivité et l'authentification. Si le registre en amont possède un artefact en cache, son chemin relatif est utilisé pour le test. Sinon, un chemin factice est utilisé. La réponse reçue de la requête HEAD est interprétée comme suit :

| Réponse en amont | Signification | Résultat |
|:------------------|:--------|:-------|
| 2XX | Succès - en amont accessible | `{ "success": true }` |
| 404 | Succès - en amont accessible mais l'artefact de test est introuvable | `{ "success": true }` |
| 401 | Échec de l'authentification | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | Accès interdit | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | Erreur du serveur en amont | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| Erreurs réseau | Problèmes de connexion/d'expiration | `{ "success": false, "result": "Error: Connection timeout" }` |

> [!note]
> Les réponses `2XX` (trouvé) et `404` (non trouvé) indiquent toutes deux une connectivité et une authentification réussies auprès du registre en amont. Le test vérifie que GitLab peut atteindre et s'authentifier auprès du registre en amont, et non si un artefact spécifique existe.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

Exemple de réponse :

```json
{
  "success": true
}
```

### Tester la connexion au registre en amont avec des paramètres de substitution {#test-upstream-registry-connection-with-override-parameters}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/565897) dans GitLab 18.7 [avec un flag](../administration/feature_flags/_index.md) nommé `maven_virtual_registry`. Activé par défaut.

{{< /history >}}

Teste la connexion à un registre Maven en amont spécifié avec des substitutions de paramètres optionnelles.

Ainsi, vous pouvez tester les modifications apportées à l'URL, au nom d'utilisateur ou au mot de passe avant de mettre à jour la configuration du registre en amont.

```plaintext
POST /virtual_registries/packages/maven/upstreams/:id/test
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | Oui | L'ID du registre en amont. |
| `password` | string | Non | Le mot de passe de substitution pour les tests. |
| `url` | string | Non | L'URL de substitution pour les tests. Si fournie, teste la connexion à cette URL plutôt qu'à l'URL configurée du registre en amont. |
| `username` | string | Non | Le nom d'utilisateur de substitution pour les tests. |

#### Fonctionnement du test {#how-the-test-works-1}

L'endpoint effectue une requête HEAD vers l'URL en amont en utilisant le chemin de test pour valider la connectivité et l'authentification. Si le registre en amont possède un artefact en cache, le chemin relatif du registre en amont est utilisé pour le test. Sinon, un chemin de substitution est utilisé.

Le comportement du test dépend des paramètres fournis :

- Aucun paramètre : Teste le registre en amont avec sa configuration actuelle (URL, nom d'utilisateur et mot de passe existants)
- Substitution d'URL : Teste la connectivité vers la nouvelle URL ; le nom d'utilisateur et le mot de passe doivent être fournis ensemble ou pas du tout
- Substitution d'identifiants : Teste l'URL existante avec de nouveaux identifiants

La réponse reçue de la requête HEAD est interprétée comme suit :

| Réponse en amont | Signification | Résultat |
|:------------------|:--------|:-------|
| 2XX | Succès. En amont accessible | `{ "success": true }` |
| 404 | Succès. En amont accessible, mais l'artefact de test est introuvable | `{ "success": true }` |
| 401 | Échec de l'authentification | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | Accès interdit | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | Erreur du serveur en amont | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| Erreurs réseau | Problèmes de connexion ou d'expiration | `{ "success": false, "result": "Error: Connection timeout" }` |

> [!note]
> Les réponses `2XX` (trouvé) et `404` (non trouvé) indiquent toutes deux une connectivité et une authentification réussies auprès du registre en amont. Le test ne vérifie pas si un artefact spécifique existe.

Exemple de requête (test de la configuration existante) :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

Exemple de requête (test avec substitution d'URL et sans identifiants) :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "<https://new-repo.example.com/maven2>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

Exemple de requête (test avec substitution d'URL et d'identifiants) :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "<https://new-repo.example.com/maven2>", "username": "<newuser>", "password": "<newpass>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

Exemple de requête (test avec substitution d'identifiants) :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"username": "<newuser>", "password": "<newpass>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

Exemple de réponse :

```json
{
  "success": true
}
```

## Gérer les entrées de cache {#manage-cache-entries}

Utilisez les endpoints suivants pour gérer les entrées de cache d'un registre virtuel Maven.

### Lister toutes les entrées de cache du registre en amont {#list-all-upstream-registry-cache-entries}

Liste toutes les entrées de cache pour un registre Maven en amont spécifié.

```plaintext
GET /virtual_registries/packages/maven/upstreams/:id/cache_entries
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:-----|:---------|:------------|
| `id` | integer | Oui | L'ID du registre en amont. |
| `page` | integer | Non | Le numéro de page. La valeur par défaut est 1. |
| `per_page` | integer | Non | Le nombre d'éléments par page. La valeur par défaut est 20. |
| `search` | string | Non | La requête de recherche pour le chemin relatif du package (par exemple, `foo/bar/mypkg`). |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/cache_entries?search=foo/bar"
```

Exemple de réponse :

```json
[
  {
    "id": "MTUgZm9vL2Jhci9teXBrZy8xLjAtU05BUFNIT1QvbXlwa2ctMS4wLVNOQVBTSE9ULmphcg==",
    "group_id": 5,
    "upstream_id": 1,
    "upstream_checked_at": "2024-05-30T12:28:27.855Z",
    "file_md5": "44f21d5190b5a6df8089f54799628d7e",
    "file_sha1": "74d101856d26f2db17b39bd22d3204021eb0bf7d",
    "size": 2048,
    "relative_path": "foo/bar/package-1.0.0.pom",
    "content_type": "application/xml",
    "upstream_etag": "\"686897696a7c876b7e\"",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z",
    "downloads_count": 6,
    "downloaded_at": "2024-06-05T14:58:32.855Z"
  }
]
```

### Supprimer une entrée de cache du registre en amont {#delete-an-upstream-registry-cache-entry}

Supprime une entrée de cache spécifiée pour un registre Maven en amont.

```plaintext
DELETE /virtual_registries/packages/maven/cache_entries/*id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | string | Oui | L'ID en amont encodé en base64 et le chemin relatif de l'entrée de cache (par exemple, 'Zm9vL2Jhci9teXBrZy5wb20='). |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/cache_entries/Zm9vL2Jhci9teXBrZy5wb20="
```

En cas de succès, renvoie un code de statut [`204 No Content`](rest/troubleshooting.md#status-codes).

## Gérer les opérations sur les packages {#manage-package-operations}

Utilisez les endpoints suivants pour gérer les opérations sur les packages pour un registre virtuel Maven.

> [!warning]
> Ces endpoints sont destinés à un usage interne par GitLab et ne sont généralement pas conçus pour une utilisation manuelle.

Ces endpoints ne respectent pas les [méthodes d'authentification de l'API REST](rest/authentication.md). Pour plus d'informations sur les en-têtes et les types de jetons pris en charge, consultez [Registre virtuel Maven](../user/packages/virtual_registry/maven/_index.md). Les méthodes d'authentification non documentées pourraient être supprimées à l'avenir.

### Télécharger un package {#download-a-package}

Télécharge un package depuis un registre virtuel Maven spécifié. Pour accéder à cette ressource, vous devez [vous authentifier auprès du registre](../user/packages/package_registry/supported_functionality.md#authenticate-with-the-registry).

```plaintext
GET /virtual_registries/packages/maven/:id/*path
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:-----|:---------|:------------|
| `id` | integer | Oui | L'ID du registre virtuel Maven. |
| `path` | string | Oui | Le chemin complet du package (par exemple, `foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar`). |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/1/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" \
     --output mypkg-1.0-SNAPSHOT.jar
```

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les en-têtes de réponse suivants :

- `x-checksum-sha1` : Somme de contrôle SHA1 du fichier
- `x-checksum-md5` : Somme de contrôle MD5 du fichier
- `Content-Type` : Le type MIME du fichier
- `Content-Length` : La taille du fichier en octets

### Charger un package {#upload-a-package}

Charge un package vers un registre virtuel Maven spécifié. Cet endpoint est accessible uniquement par [GitLab Workhorse](../development/workhorse/_index.md).

```plaintext
POST /virtual_registries/packages/maven/:id/*path/upload
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | Oui | L'ID du registre virtuel Maven. |
| `file` | file | Oui | Le fichier en cours de chargement. |
| `path` | string | Oui | Le chemin complet du package (par exemple, `foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar`). |

En-têtes de requête :

- `Etag` : Balise d'entité pour le fichier
- `GitLab-Workhorse-Send-Dependency-Content-Type` : Type de contenu du fichier
- `Upstream-GID` : ID global de la cible en amont

En cas de succès, renvoie un code de statut [`200 OK`](rest/troubleshooting.md#status-codes).
