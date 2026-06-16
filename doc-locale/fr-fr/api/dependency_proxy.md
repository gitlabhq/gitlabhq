---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API du proxy de dépendances
description: "Documentation de l'API REST pour le proxy de dépendances GitLab."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer le [proxy de dépendances](../user/packages/dependency_proxy/_index.md).

## Purger le proxy de dépendances pour un groupe {#purge-the-dependency-proxy-for-a-group}

Planifie la suppression des manifestes et des blobs mis en cache pour un groupe. Ce point de terminaison requiert le rôle Owner pour le groupe.

```plaintext
DELETE /groups/:id/dependency_proxy/cache
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

Exemple de requête :

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/groups/5/dependency_proxy/cache"
```
