---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des attributs personnalisés
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les attributs personnalisés des utilisateurs, des groupes et des projets.

Prérequis :

- Vous devez être administrateur de l'instance.

## Lister tous les attributs personnalisés {#list-all-custom-attributes}

Liste tous les attributs personnalisés pour une ressource spécifiée.

```plaintext
GET /users/:id/custom_attributes
GET /groups/:id/custom_attributes
GET /projects/:id/custom_attributes
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | oui | L'identifiant d'une ressource |

```shell
curl --request GET \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes"
```

Exemple de réponse :

```json
[
   {
      "key": "location",
      "value": "Antarctica"
   },
   {
      "key": "role",
      "value": "Developer"
   }
]
```

## Récupérer un attribut personnalisé {#retrieve-a-custom-attribute}

Récupère un attribut personnalisé spécifié pour une ressource.

```plaintext
GET /users/:id/custom_attributes/:key
GET /groups/:id/custom_attributes/:key
GET /projects/:id/custom_attributes/:key
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | oui | L'identifiant d'une ressource |
| `key` | string | oui | La clé de l'attribut personnalisé |

```shell
curl --request GET \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```

Exemple de réponse :

```json
{
   "key": "location",
   "value": "Antarctica"
}
```

## Mettre à jour un attribut personnalisé {#update-a-custom-attribute}

Met à jour ou crée un attribut personnalisé pour une ressource spécifiée. L'attribut est mis à jour s'il existe déjà, ou nouvellement créé dans le cas contraire.

```plaintext
PUT /users/:id/custom_attributes/:key
PUT /groups/:id/custom_attributes/:key
PUT /projects/:id/custom_attributes/:key
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | oui | L'identifiant d'une ressource |
| `key` | string | oui | La clé de l'attribut personnalisé |
| `value` | string | oui | La valeur de l'attribut personnalisé |

```shell
curl --request PUT \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --data "value=Greenland" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```

Exemple de réponse :

```json
{
   "key": "location",
   "value": "Greenland"
}
```

## Supprimer un attribut personnalisé {#delete-custom-attribute}

Supprime un attribut personnalisé spécifié pour une ressource.

```plaintext
DELETE /users/:id/custom_attributes/:key
DELETE /groups/:id/custom_attributes/:key
DELETE /projects/:id/custom_attributes/:key
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | oui | L'identifiant d'une ressource |
| `key` | string | oui | La clé de l'attribut personnalisé |

```shell
curl --request DELETE \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```
