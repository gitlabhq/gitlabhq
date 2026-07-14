---
stage: Data Access
group: Database Frameworks
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des migrations de base de données
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123408) dans GitLab 16.2.

{{< /history >}}

Utilisez cette API pour gérer les migrations de base de données GitLab.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

## Marquer une migration comme réussie {#mark-a-migration-as-successful}

Marque les migrations en attente comme exécutées avec succès pour les empêcher d'être exécutées par les tâches `db:migrate`. Utilisez cette API pour ignorer les migrations défaillantes après avoir déterminé qu'elles peuvent être ignorées en toute sécurité.

```plaintext
POST /api/v4/admin/migrations/:version/mark
```

| Attribut       | Type           | Obligatoire | Description                                                                                                                                                                                      |
|-----------------|----------------|----------|----------------------------------------------------------------------------------|
| `version`       | entier        | oui      | Horodatage de version de la migration à ignorer                                 |
| `database`      | string         | non       | Le nom de la base de données pour laquelle la migration est ignorée. La valeur par défaut est `main`.        |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/admin/migrations/:version/mark"
```

## Lister les migrations en attente {#list-pending-migrations}

Renvoie la liste de toutes les migrations en attente (pas encore exécutées) pour une base de données spécifiée.

```plaintext
GET /api/v4/admin/migrations/pending
```

| Attribut       | Type           | Obligatoire | Description                                                                      |
|-----------------|----------------|----------|-----------------------------------------------------------------------------------|
| `database`      | string         | non       | Le nom de la base de données à interroger. La valeur par défaut est `main`.                                  |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/admin/migrations/pending?database=main"
```

Exemple de réponse :

```json
{
  "pending_migrations": [
    {
      "version": 20240101120000,
      "name": "create_users_table",
      "filename": "20240101120000_create_users_table.rb",
      "status": "pending"
    },
    {
      "version": 20240102150000,
      "name": "add_email_to_users",
      "filename": "20240102150000_add_email_to_users.rb",
      "status": "pending"
    }
  ],
  "database": "main",
  "total_pending": 2
}
```
