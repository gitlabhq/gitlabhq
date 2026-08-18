---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Topics
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : Bêta

{{< /details >}}

Utilisez cette API pour interagir avec les topics de projet. Pour plus d'informations, consultez [les topics de projet](../user/project/project_topics.md).

## Lister tous les topics {#list-all-topics}

Renvoie une liste des topics de projet dans l'instance GitLab, classés par nombre de projets associés.

```plaintext
GET /topics
```

Attributs pris en charge :

| Attribut          | Type    | Obligatoire               | Description |
| ------------------ | ------- | ---------------------- | ----------- |
| `page`             | integer | Non | Page à récupérer. La valeur par défaut est `1`.                      |
| `per_page`         | integer | Non | Nombre d'enregistrements à retourner par page. La valeur par défaut est `20`. |
| `search`           | string  | Non | Rechercher des topics par leur `name`.                     |
| `without_projects` | boolean | Non | Limiter les résultats aux topics sans projets assignés.      |

Exemple de requête :

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/topics?search=git"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "gitlab",
    "title": "GitLab",
    "description": "GitLab is an open source end-to-end software development platform with built-in version control, issue tracking, code review, CI/CD, and more.",
    "total_projects_count": 1000,
    "organization_id": 1,
    "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon"
  },
  {
    "id": 3,
    "name": "git",
    "title": "Git",
    "description": "Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.",
    "total_projects_count": 900,
    "organization_id": 1,
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
  },
  {
    "id": 2,
    "name": "git-lfs",
    "title": "Git LFS",
    "description": null,
    "total_projects_count": 300,
    "organization_id": 1,
    "avatar_url": null
  }
]
```

## Récupérer un topic {#retrieve-a-topic}

Récupère un topic de projet par ID.

```plaintext
GET /topics/:id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire               | Description         |
| --------- | ------- | ---------------------- | ------------------- |
| `id`      | integer | Oui | ID du topic de projet |

Exemple de requête :

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/topics/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "gitlab",
  "title": "GitLab",
  "description": "GitLab is an open source end-to-end software development platform with built-in version control, issue tracking, code review, CI/CD, and more.",
  "total_projects_count": 1000,
  "organization_id": 1,
  "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon"
}
```

## Lister tous les projets assignés à un topic {#list-all-projects-assigned-to-a-topic}

Utilise l'[API Projects](projects.md#list-all-projects) pour lister tous les projets assignés à un topic spécifique.

```plaintext
GET /projects?topic=<topic_name>
```

## Créer un topic de projet {#create-a-project-topic}

Crée un nouveau topic de projet. Disponible uniquement pour les administrateurs.

```plaintext
POST /topics
```

Attributs pris en charge :

| Attribut         | Type    | Obligatoire | Description                                                                                                                                                                                    |
|-------------------|---------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`            | string  | Oui      | Slug (nom)                                                                                                                                                                                    |
| `title`           | string  | Oui      | Titre                                                                                                                                                                                          |
| `avatar`          | file    | Non       | Avatar                                                                                                                                                                                         |
| `description`     | string  | Non       | Description                                                                                                                                                                                    |
| `organization_id` | integer | Non       | L'ID d'organisation pour le topic. Avertissement : cet attribut est expérimental et susceptible d'être modifié à l'avenir. Pour plus d'informations sur les organisations, consultez [l'API Organizations](organizations.md) |

Exemple de requête :

```shell
curl --request POST \
    --data "name=topic1&title=Topic 1" \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "topic1",
  "title": "Topic 1",
  "description": null,
  "total_projects_count": 0,
  "organization_id": 1,
  "avatar_url": null
}
```

## Mettre à jour un topic de projet {#update-a-project-topic}

Met à jour un topic de projet. Disponible uniquement pour les administrateurs.

```plaintext
PUT /topics/:id
```

Attributs pris en charge :

| Attribut     | Type    | Obligatoire | Description         |
|---------------|---------|----------|---------------------|
| `id`          | integer | Oui      | ID du topic de projet |
| `avatar`      | file    | Non       | Avatar              |
| `description` | string  | Non       | Description         |
| `name`        | string  | Non       | Slug (nom)         |
| `title`       | string  | Non       | Titre               |

Exemple de requête :

```shell
curl --request PUT \
    --data "name=topic1" \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "topic1",
  "title": "Topic 1",
  "description": null,
  "total_projects_count": 0,
  "organization_id": 1,
  "avatar_url": null
}
```

### Charger un avatar de topic {#upload-a-topic-avatar}

Pour charger un fichier avatar depuis votre système de fichiers, utilisez l'argument `--form`. Cet argument indique à cURL de publier des données en utilisant l'en-tête `Content-Type: multipart/form-data`. Le paramètre `file=` doit pointer vers un fichier sur votre système de fichiers et être précédé de `@`. Par exemple :

```shell
curl --request PUT \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1" \
    --form "avatar=@/tmp/example.png"
```

### Supprimer un avatar de topic {#remove-a-topic-avatar}

Pour supprimer un avatar de topic, utilisez une valeur vide pour l'attribut `avatar`.

Exemple de requête :

```shell
curl --request PUT \
    --data "avatar=" \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1"
```

## Supprimer un topic de projet {#delete-a-project-topic}

Vous devez être administrateur pour supprimer un topic de projet. Lorsque vous supprimez un topic de projet, vous supprimez également l'assignation du topic pour les projets.

```plaintext
DELETE /topics/:id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | Oui      | ID du topic de projet |

Exemple de requête :

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/1"
```

## Fusionner des topics {#merge-topics}

Vous devez être administrateur pour fusionner un topic source dans un topic cible. Lorsque vous fusionnez des topics, vous supprimez le topic source et déplacez tous les projets assignés vers le topic cible.

```plaintext
POST /topics/merge
```

Attributs pris en charge :

| Attribut         | Type    | Obligatoire | Description                |
|-------------------|---------|----------|----------------------------|
| `source_topic_id` | integer | Oui      | ID du topic de projet source |
| `target_topic_id` | integer | Oui      | ID du topic de projet cible |

> [!note]
> Les `source_topic_id` et `target_topic_id` doivent appartenir à la même organisation.

Exemple de requête :

```shell
curl --request POST \
    --data "source_topic_id=2&target_topic_id=1" \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/topics/merge"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "topic1",
  "title": "Topic 1",
  "description": null,
  "total_projects_count": 0,
  "organization_id": 1,
  "avatar_url": null
}
```
