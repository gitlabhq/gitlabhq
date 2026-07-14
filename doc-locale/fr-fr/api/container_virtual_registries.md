---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API du registre virtuel de conteneurs
description: "Créez et gérez des registres virtuels pour le registre de conteneurs, et configurez les registres de conteneurs en amont."
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : Bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/548794) dans GitLab 18.5 [avec un flag](../administration/feature_flags/_index.md) nommé `container_virtual_registries`. Désactivé par défaut.
- [Passage](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631) d'expérimental à bêta dans GitLab 18.9.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224250) dans GitLab 18.10.

{{< /history >}}

> [!flag]
> La disponibilité de ces endpoints est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Utilisez cette API pour :

- Créer et gérer des registres virtuels pour le registre de conteneurs.
- Configurer les registres de conteneurs en amont.
- Gérer les images de conteneurs et les manifestes en cache.

Pour en savoir plus sur l'extraction d'images de conteneurs via un registre virtuel, consultez [Registre virtuel de conteneurs](../user/packages/virtual_registry/container/_index.md).

> [!note]
> Les registres de fournisseurs cloud ne sont pas pris en charge, mais le [ticket 20919](https://gitlab.com/groups/gitlab-org/-/work_items/20919) propose de modifier ce comportement.

## Gérer les registres virtuels {#manage-virtual-registries}

Utilisez les endpoints suivants pour créer et gérer des registres virtuels pour le registre de conteneurs.

### Lister tous les registres virtuels {#list-all-virtual-registries}

Liste tous les registres virtuels de conteneurs pour un groupe.

```plaintext
GET /groups/:id/-/virtual_registries/container/registries
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:-----|:---------|:------------|
| `id` | chaîne ou entier | Oui | L'ID du groupe ou le chemin complet du groupe. Doit être un groupe principal. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/registries"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "group_id": 5,
    "name": "my-container-virtual-registry",
    "description": "My container virtual registry",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### Créer un registre virtuel {#create-a-virtual-registry}

Crée un registre virtuel de conteneurs pour un groupe.

```plaintext
POST /groups/:id/-/virtual_registries/container/registries
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | chaîne ou entier | Oui | L'ID du groupe ou le chemin complet du groupe. Doit être un groupe principal. |
| `name` | string | Oui | Le nom du registre virtuel. |
| `description` | string | Non | La description du registre virtuel. |

> [!note]
> Vous pouvez créer un maximum de 5 registres virtuels par groupe.

Exemple de requête :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"name": "my-container-virtual-registry", "description": "My container virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/registries"
```

Exemple de réponse :

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-container-virtual-registry",
  "description": "My container virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### Récupérer un registre virtuel {#retrieve-a-virtual-registry}

Récupère un registre virtuel de conteneurs spécifié.

```plaintext
GET /virtual_registries/container/registries/:id
```

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | Oui | L'ID du registre virtuel de conteneurs. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-container-virtual-registry",
  "description": "My container virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z",
  "registry_upstreams": [
    {
      "id": 2,
      "position": 1,
      "upstream_id": 2
    }
  ]
}
```

### Mettre à jour un registre virtuel {#update-a-virtual-registry}

Met à jour un registre virtuel de conteneurs spécifié.

```plaintext
PATCH /virtual_registries/container/registries/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | Oui | L'ID du registre virtuel de conteneurs. |
| `description` | string | Non | La description du registre virtuel. |
| `name` | string | Non | Le nom du registre virtuel. |

> [!note]
> Vous devez fournir au moins l'un des paramètres facultatifs (`name` ou `description`) dans votre requête.

Exemple de requête :

```shell
curl --request PATCH \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"name": "my-container-virtual-registry", "description": "My container virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1"
```

En cas de succès, renvoie un code de statut [`200 OK`](rest/troubleshooting.md#status-codes).

### Supprimer un registre virtuel {#delete-a-virtual-registry}

> [!warning]
> Lorsque vous supprimez un registre virtuel, vous supprimez également tous les registres en amont associés qui ne sont pas partagés avec d'autres registres virtuels, ainsi que leurs images de conteneurs et manifestes en cache.

Supprime un registre virtuel de conteneurs spécifié.

```plaintext
DELETE /virtual_registries/container/registries/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | Oui | L'ID du registre virtuel de conteneurs. |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1"
```

En cas de succès, renvoie un code de statut [`204 No Content`](rest/troubleshooting.md#status-codes).

### Supprimer les entrées de cache d'un registre virtuel {#delete-cache-entries-for-a-virtual-registry}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/538327) dans GitLab 18.7 [avec un flag](../administration/feature_flags/_index.md) nommé `container_virtual_registries`. Désactivé par défaut.
- [Passage](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631) d'expérimental à bêta dans GitLab 18.9.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224250) dans GitLab 18.10.

{{< /history >}}

Planifie la suppression de toutes les entrées de cache dans tous les registres en amont exclusifs d'un registre virtuel de conteneurs. Les entrées de cache ne sont pas planifiées pour suppression pour les registres en amont associés à d'autres registres virtuels.

```plaintext
DELETE /virtual_registries/container/registries/:id/cache
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | Oui | L'ID du registre virtuel de conteneurs. |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1/cache"
```

En cas de succès, renvoie un code de statut [`204 No Content`](rest/troubleshooting.md#status-codes).

## Gérer les registres en amont {#manage-upstream-registries}

Utilisez les endpoints suivants pour configurer et gérer les registres de conteneurs en amont.

### Lister tous les registres en amont pour un groupe principal {#list-all-upstream-registries-for-a-top-level-group}

Liste tous les registres de conteneurs en amont pour un groupe principal.

```plaintext
GET /groups/:id/-/virtual_registries/container/upstreams
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:-----|:---------|:------------|
| `id` | chaîne ou entier | Oui | L'ID du groupe ou le chemin complet du groupe. Doit être un groupe principal. |
| `page` | entier | Non | Le numéro de page. Par défaut : 1. |
| `per_page` | entier | Non | Le nombre d'éléments par page. Par défaut : 20. |
| `upstream_name` | string | Non | Le nom du registre en amont pour le filtrage par recherche floue par nom. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/upstreams"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://registry-1.docker.io",
    "name": "Docker Hub",
    "description": "Docker Hub registry",
    "cache_validity_hours": 24,
    "username": "user",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### Tester la connexion avant de créer un registre en amont {#test-connection-before-creating-an-upstream-registry}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/578679) dans GitLab 18.9 [avec un flag](../administration/feature_flags/_index.md) nommé `container_virtual_registries`. Désactivé par défaut.
- [Passage](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631) d'expérimental à bêta dans GitLab 18.9.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224250) dans GitLab 18.10.

{{< /history >}}

Teste la connexion à un registre de conteneurs en amont qui n'a pas encore été ajouté au registre virtuel. Cet endpoint valide la connectivité et les informations d'identification avant de créer le registre en amont.

```plaintext
POST /groups/:id/-/virtual_registries/container/upstreams/test
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:-----|:---------|:------------|
| `id` | chaîne ou entier | Oui | L'ID du groupe ou le chemin complet du groupe. Doit être un groupe principal. |
| `url` | string | Oui | L'URL du registre en amont. |
| `password` | string | Non | Le mot de passe du registre en amont. |
| `username` | string | Non | Le nom d'utilisateur du registre en amont. |

> [!note]
> Vous devez inclure à la fois `username` et `password` dans la requête, ou ni l'un ni l'autre. Si non défini, une requête publique (anonyme) est utilisée pour accéder au registre en amont.

#### Workflow de test {#test-workflow}

L'endpoint `test` envoie une requête HEAD à l'URL en amont fournie en utilisant un chemin de test pour valider la connectivité et l'authentification. La réponse reçue de la requête HEAD est interprétée comme suit :

| Réponse en amont | Description | Résultat |
|:------------------|:--------|:-------|
| 2XX | Succès. Registre en amont accessible | `{ "success": true }` |
| 404 | Succès. Registre en amont accessible, mais artefact de test introuvable | `{ "success": true }` |
| 401 | Échec de l'authentification | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | Accès interdit | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | Erreur du serveur en amont | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| Erreurs réseau | Problèmes de connexion/délai d'expiration | `{ "success": false, "result": "Error: Connection timeout" }` |

Exemple de requête :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/upstreams/test"
     --data '{"url": "https://registry-1.docker.io", "username": "<your_username>", "password": "<your_password>"}' \
```

Exemple de réponse :

```json
{
  "success": true
}
```

> [!note]
> Les codes de statut HTTP `2XX` (trouvé) et `404 Not Found` provenant du registre en amont sont considérés comme des réponses réussies, car ils indiquent que le registre en amont est accessible et correctement configuré.

### Lister tous les registres en amont pour un registre virtuel {#list-all-upstream-registries-for-a-virtual-registry}

Liste tous les registres en amont pour un registre virtuel de conteneurs.

```plaintext
GET /virtual_registries/container/registries/:id/upstreams
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:-----|:---------|:------------|
| `id` | entier | Oui | L'ID du registre virtuel de conteneurs. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1/upstreams"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://registry-1.docker.io",
    "name": "Docker Hub",
    "description": "Docker Hub registry",
    "cache_validity_hours": 24,
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

Crée un registre de conteneurs en amont pour un registre virtuel de conteneurs spécifié.

```plaintext
POST /virtual_registries/container/registries/:id/upstreams
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | Oui | L'ID du registre virtuel de conteneurs. |
| `url` | string | Oui | L'URL du registre de conteneurs en amont. |
| `name` | string | Oui | Le nom du registre en amont. |
| `cache_validity_hours` | entier | Non | La période de validité du cache pour les images de conteneurs. Par défaut : 24 heures. |
| `description` | string | Non | La description du registre en amont. |
| `password` | string | Non | Le mot de passe du registre en amont. |
| `username` | string | Non | Le nom d'utilisateur du registre en amont. |

> [!note]
> Vous devez inclure à la fois `username` et `password` dans la requête, ou aucun des deux. Si non défini, une requête publique (anonyme) est utilisée pour accéder au registre en amont.

Vous ne pouvez pas ajouter deux registres en amont avec la même URL et les mêmes informations d'identification (`username` et `password`) au même groupe principal. À la place, vous pouvez :

- Définir des informations d'identification différentes pour chaque registre en amont avec la même URL.
- Associer un registre en amont à plusieurs registres virtuels.

> [!note]
> Vous pouvez ajouter un maximum de 5 registres en amont à chaque registre virtuel.

Exemple de requête :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "https://registry-1.docker.io", "name": "Docker Hub", "description": "Docker Hub registry", "username": "<your_username>", "password": "<your_password>", "cache_validity_hours": 48}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1/upstreams"
```

Exemple de réponse :

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://registry-1.docker.io",
  "name": "Docker Hub",
  "description": "Docker Hub registry",
  "cache_validity_hours": 48,
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

Récupère un registre de conteneurs en amont spécifié.

```plaintext
GET /virtual_registries/container/upstreams/:id
```

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | Oui | L'ID du registre en amont. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://registry-1.docker.io",
  "name": "Docker Hub",
  "description": "Docker Hub registry",
  "cache_validity_hours": 24,
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

Met à jour un registre de conteneurs en amont spécifié.

```plaintext
PATCH /virtual_registries/container/upstreams/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | Oui | L'ID du registre en amont. |
| `cache_validity_hours` | entier | Non | La période de validité du cache pour les images de conteneurs. Par défaut : 24 heures. |
| `description` | string | Non | La description du registre en amont. |
| `name` | string | Non | Le nom du registre en amont. |
| `password` | string | Non | Le mot de passe du registre en amont. |
| `url` | string | Non | L'URL du registre en amont. |
| `username` | string | Non | Le nom d'utilisateur du registre en amont. |

> [!note]
> Vous devez fournir au moins l'un des paramètres facultatifs dans votre requête.
>
> Les paramètres `username` et `password` doivent être fournis ensemble ou pas du tout. Si non défini, une requête publique (anonyme) est utilisée pour accéder au registre en amont.

Exemple de requête :

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"cache_validity_hours": 72}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1"
```

En cas de succès, renvoie un code de statut [`200 OK`](rest/troubleshooting.md#status-codes).

### Mettre à jour la position d'un registre en amont {#update-an-upstream-registry-position}

Met à jour la position d'un registre de conteneurs en amont dans une liste ordonnée pour un registre virtuel de conteneurs.

```plaintext
PATCH /virtual_registries/container/registry_upstreams/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | Oui | L'ID de l'association du registre en amont. |
| `position` | entier | Oui | La position du registre en amont. Entre 1 et 20. |

Exemple de requête :

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"position": 5}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registry_upstreams/1"
```

En cas de succès, renvoie un code de statut [`200 OK`](rest/troubleshooting.md#status-codes).

### Supprimer un registre en amont {#delete-an-upstream-registry}

Supprime un registre de conteneurs en amont spécifié.

```plaintext
DELETE /virtual_registries/container/upstreams/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | Oui | L'ID du registre en amont. |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1"
```

En cas de succès, renvoie un code de statut [`204 No Content`](rest/troubleshooting.md#status-codes).

### Associer un registre en amont à un registre virtuel {#associate-an-upstream-with-a-registry}

Associe un registre de conteneurs en amont spécifié à un registre virtuel de conteneurs spécifié.

```plaintext
POST /virtual_registries/container/registry_upstreams
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `registry_id` | entier | Oui | L'ID du registre virtuel de conteneurs. |
| `upstream_id` | entier | Oui | L'ID du registre de conteneurs en amont. |

> [!note]
> Vous pouvez associer un maximum de 5 registres en amont à chaque registre virtuel.

Exemple de requête :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"registry_id": 1, "upstream_id": 2}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registry_upstreams"
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

### Dissocier un registre en amont d'un registre virtuel {#disassociate-an-upstream-from-a-registry}

Supprime l'association entre un registre de conteneurs en amont spécifié et un registre virtuel de conteneurs spécifié.

```plaintext
DELETE /virtual_registries/container/registry_upstreams/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | Oui | L'ID de l'association du registre en amont. |

Exemple de requête :

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registry_upstreams/1"
```

En cas de succès, renvoie un code de statut [`204 No Content`](rest/troubleshooting.md#status-codes).

### Supprimer les entrées de cache d'un registre en amont {#delete-cache-entries-for-an-upstream-registry}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/538327) dans GitLab 18.7 [avec un flag](../administration/feature_flags/_index.md) nommé `container_virtual_registries`. Désactivé par défaut.
- [Passage](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631) d'expérimental à bêta dans GitLab 18.9.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224250) dans GitLab 18.10.

{{< /history >}}

Planifie la suppression de toutes les entrées de cache pour un registre en amont spécifié.

```plaintext
DELETE /virtual_registries/container/upstreams/:id/cache
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | Oui | L'ID du registre en amont. |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/cache"
```

En cas de succès, renvoie un code de statut [`204 No Content`](rest/troubleshooting.md#status-codes).

### Tester la connexion à un registre en amont avec des paramètres de remplacement {#test-connection-to-an-upstream-registry-with-override-parameters}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/578679) dans GitLab 18.9 [avec un flag](../administration/feature_flags/_index.md) nommé `container_virtual_registries`. Désactivé par défaut.
- [Passage](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631) d'expérimental à bêta dans GitLab 18.9.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224250) dans GitLab 18.10.

{{< /history >}}

Teste la connexion à un registre de conteneurs en amont existant avec des paramètres de remplacement facultatifs.

Ainsi, vous pouvez tester les modifications apportées à l'URL, au nom d'utilisateur ou au mot de passe avant de mettre à jour la configuration du registre en amont.

```plaintext
POST /virtual_registries/container/upstreams/:id/test
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | Oui | L'ID du registre en amont. |
| `password` | string | Non | Le mot de passe de remplacement pour les tests. |
| `url` | string | Non | L'URL de remplacement pour les tests. Si fournie, teste la connexion à cette URL plutôt qu'à l'URL configurée du registre en amont. |
| `username` | string | Non | Le nom d'utilisateur de remplacement pour les tests. |

#### Fonctionnement du test {#how-the-test-works}

L'endpoint effectue une requête HEAD vers l'URL en amont en utilisant un chemin de test pour valider la connectivité et l'authentification. Si le registre en amont dispose d'un artefact en cache, le chemin relatif du registre en amont est utilisé pour les tests. Sinon, un chemin d'espace réservé est utilisé.

Le comportement du test dépend des paramètres fournis :

- Aucun paramètre : Teste le registre en amont avec sa configuration actuelle (URL, nom d'utilisateur et mot de passe existants)
- Remplacement d'URL : Teste la connectivité à la nouvelle URL (le nom d'utilisateur et le mot de passe doivent être fournis ensemble ou pas du tout)
- Remplacement des informations d'identification : Teste l'URL existante avec les nouvelles informations d'identification

La réponse reçue de la requête HEAD est interprétée comme suit :

| Réponse en amont | Signification | Résultat |
|:------------------|:--------|:-------|
| 2XX | Succès. Registre en amont accessible | `{ "success": true }` |
| 404 | Succès. Registre en amont accessible, mais artefact de test introuvable | `{ "success": true }` |
| 401 | Échec de l'authentification | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | Accès interdit | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | Erreur du serveur en amont | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| Erreurs réseau | Problèmes de connexion ou de délai d'expiration | `{ "success": false, "result": "Error: Connection timeout" }` |

> [!note]
> Les réponses `2XX` (trouvé) et `404 Not Found` indiquent toutes deux une connectivité et une authentification réussies au registre en amont. Le test ne valide pas l'existence d'un artefact spécifique.

Exemple de requête (test de la configuration existante) :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/test"
```

Exemple de requête (test avec remplacement d'URL et sans informations d'identification) :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "https://registry-1.docker.io"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/test"
```

Exemple de requête (test avec remplacement d'URL et des informations d'identification) :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "https://registry-1.docker.io", "username": "<newuser>", "password": "<newpass>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/test"
```

Exemple de requête (test avec remplacement des informations d'identification) :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"username": "<newuser>", "password": "<newpass>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/test"
```

Exemple de réponse :

```json
{
  "success": true
}
```

## Gérer les entrées de cache {#manage-cache-entries}

Utilisez les endpoints suivants pour gérer les images de conteneurs et les manifestes en cache pour un registre virtuel de conteneurs.

### Lister les entrées de cache du registre en amont {#list-upstream-registry-cache-entries}

Liste les images de conteneurs et les manifestes en cache pour un registre de conteneurs en amont.

```plaintext
GET /virtual_registries/container/upstreams/:id/cache_entries
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:-----|:---------|:------------|
| `id` | entier | Oui | L'ID du registre en amont. |
| `page` | entier | Non | Le numéro de page. Par défaut : 1. |
| `per_page` | entier | Non | Le nombre d'éléments par page. Par défaut : 20. |
| `search` | string | Non | La requête de recherche pour le chemin relatif de l'image de conteneur (par exemple, `library/nginx`). |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/cache_entries?search=library/nginx"
```

Exemple de réponse :

```json
[
  {
    "id": "MTUgbGlicmFyeS9uZ2lueC9tYW5pZmVzdC9zaGEyNTY6YWJjZGVmZ2hpams=",
    "group_id": 5,
    "upstream_id": 1,
    "upstream_checked_at": "2024-05-30T12:28:27.855Z",
    "file_md5": "44f21d5190b5a6df8089f54799628d7e",
    "file_sha1": "74d101856d26f2db17b39bd22d3204021eb0bf7d",
    "size": 2048,
    "relative_path": "library/nginx/manifests/latest",
    "content_type": "application/vnd.docker.distribution.manifest.v2+json",
    "upstream_etag": "\"686897696a7c876b7e\"",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z",
    "downloads_count": 5,
    "downloaded_at": "2024-06-05T14:58:32.855Z"
  }
]
```

### Supprimer une entrée de cache du registre en amont {#delete-an-upstream-registry-cache-entry}

Supprime une image de conteneur ou un manifeste en cache spécifié pour un registre en amont.

```plaintext
DELETE /virtual_registries/container/cache_entries/*id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | string | Oui | L'ID de l'entrée de cache, qui est l'ID en amont encodé en base64 et le chemin relatif de l'entrée de cache (par exemple, 'bGlicmFyeS9uZ2lueC9tYW5pZmVzdHMvbGF0ZXN0'). |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/cache_entries/bGlicmFyeS9uZ2lueC9tYW5pZmVzdHMvbGF0ZXN0"
```

En cas de succès, renvoie un code de statut [`204 No Content`](rest/troubleshooting.md#status-codes).
