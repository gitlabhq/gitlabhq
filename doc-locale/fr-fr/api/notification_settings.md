---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des paramètres de notification
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les paramètres de notification dans GitLab. Pour plus d'informations, voir [les e-mails de notification](../user/profile/notifications.md).

## Niveaux de notification {#notification-levels}

Les niveaux de notification sont définis dans l'énumération du modèle `NotificationSetting.level`. Les niveaux suivants sont reconnus :

- `disabled` :  Désactiver toutes les notifications
- `participating` :  Recevoir des notifications pour les fils de discussion auxquels vous avez participé
- `watch` :  Recevoir des notifications pour la plupart des activités
- `global` :  Utiliser vos paramètres de notification globaux
- `mention` :  Recevoir des notifications lorsque vous êtes mentionné(e) dans un commentaire
- `custom` :  Recevoir des notifications pour les événements sélectionnés

Si vous utilisez le niveau `custom`, vous pouvez contrôler des événements d'e-mail spécifiques. Les événements disponibles sont retournés par `NotificationSetting.email_events`. Les événements suivants sont reconnus :

| Événement                          | Description |
| ------------------------------ | ----------- |
| `approver`                     | Une merge request que vous êtes éligible à approuver est créée |
| `change_reviewer_merge_request`| Lorsque le relecteur d'une merge request est modifié |
| `close_issue`                  | Lorsqu'un ticket est fermé |
| `close_merge_request`          | Lorsqu'une merge request est fermée |
| `failed_pipeline`              | Lorsqu'un pipeline échoue |
| `fixed_pipeline`               | Lorsqu'un pipeline précédemment en échec est corrigé |
| `issue_due`                    | Lorsqu'un ticket arrive à échéance demain |
| `merge_merge_request`          | Lorsqu'une merge request est fusionnée |
| `merge_when_pipeline_succeeds` | Lorsqu'une merge request est configurée pour la fusion automatique |
| `moved_project`                | Lorsqu'un projet est déplacé |
| `new_epic`                     | Lorsqu'un nouvel epic est créé (dans les niveaux Premium et Ultimate) |
| `new_issue`                    | Lorsqu'un nouveau ticket est créé |
| `new_merge_request`            | Lorsqu'une nouvelle merge request est créée |
| `new_note`                     | Lorsque quelqu'un ajoute un commentaire |
| `new_release`                  | Lorsqu'une nouvelle release est publiée |
| `push_to_merge_request`        | Lorsque quelqu'un pousse vers une merge request |
| `reassign_issue`               | Lorsqu'un ticket est réassigné |
| `reassign_merge_request`       | Lorsqu'une merge request est réassignée |
| `reopen_issue`                 | Lorsqu'un ticket est rouvert |
| `reopen_merge_request`         | Lorsqu'une merge request est rouverte |
| `success_pipeline`             | Lorsqu'un pipeline se termine avec succès |

## Récupérer les paramètres de notification globaux {#retrieve-global-notification-settings}

Récupère le niveau de notification global et l'adresse e-mail.

```plaintext
GET /notification_settings
```

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/notification_settings"
```

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut            | Type   | Description |
| -------------------- | ------ | ----------- |
| `level`              | string | Niveau de notification global |
| `notification_email` | string | Adresse e-mail à laquelle les notifications sont envoyées |

Exemple de réponse :

```json
{
  "level": "participating",
  "notification_email": "admin@example.com"
}
```

## Mettre à jour les paramètres de notification globaux {#update-global-notification-settings}

Met à jour les paramètres de notification et l'adresse e-mail.

```plaintext
PUT /notification_settings
```

Exemple de requête :

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/notification_settings?level=watch"
```

Attributs pris en charge :

| Attribut                      | Type    | Obligatoire | Description |
| ------------------------------ | ------- | -------- | ----------- |
| `approver`                     | boolean | Non       | Activer les notifications lorsqu'une merge request que vous êtes éligible à approuver est créée |
| `change_reviewer_merge_request`| boolean | Non       | Activer les notifications lorsque le relecteur d'une merge request est modifié |
| `close_issue`                  | boolean | Non       | Activer les notifications lorsqu'un ticket est fermé |
| `close_merge_request`          | boolean | Non       | Activer les notifications lorsqu'une merge request est fermée |
| `failed_pipeline`              | boolean | Non       | Activer les notifications lorsqu'un pipeline échoue |
| `fixed_pipeline`               | boolean | Non       | Activer les notifications lorsqu'un pipeline précédemment en échec est corrigé |
| `issue_due`                    | boolean | Non       | Activer les notifications lorsqu'un ticket arrive à échéance demain |
| `level`                        | string  | Non       | Niveau de notification global |
| `merge_merge_request`          | boolean | Non       | Activer les notifications lorsqu'une merge request est fusionnée |
| `merge_when_pipeline_succeeds` | boolean | Non       | Activer les notifications lorsqu'une merge request est configurée pour la fusion automatique |
| `moved_project`                | boolean | Non       | Activer les notifications lorsqu'un projet est déplacé |
| `new_epic`                     | boolean | Non       | Activer les notifications lorsqu'un nouvel epic est créé (dans les niveaux Premium et Ultimate) |
| `new_issue`                    | boolean | Non       | Activer les notifications lorsqu'un nouveau ticket est créé |
| `new_merge_request`            | boolean | Non       | Activer les notifications lorsqu'une nouvelle merge request est créée |
| `new_note`                     | boolean | Non       | Activer les notifications lorsqu'un nouveau commentaire est ajouté |
| `new_release`                  | boolean | Non       | Activer les notifications lorsqu'une nouvelle release est publiée |
| `notification_email`           | string  | Non       | Adresse e-mail à laquelle les notifications sont envoyées |
| `push_to_merge_request`        | boolean | Non       | Activer les notifications lorsque quelqu'un pousse vers une merge request |
| `reassign_issue`               | boolean | Non       | Activer les notifications lorsqu'un ticket est réassigné |
| `reassign_merge_request`       | boolean | Non       | Activer les notifications lorsqu'une merge request est réassignée |
| `reopen_issue`                 | boolean | Non       | Activer les notifications lorsqu'un ticket est rouvert |
| `reopen_merge_request`         | boolean | Non       | Activer les notifications lorsqu'une merge request est rouverte |
| `success_pipeline`             | boolean | Non       | Activer les notifications lorsqu'un pipeline se termine avec succès |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut            | Type   | Description |
| -------------------- | ------ | ----------- |
| `level`              | string | Niveau de notification global |
| `notification_email` | string | Adresse e-mail à laquelle les notifications sont envoyées |

Exemple de réponse :

```json
{
  "level": "watch",
  "notification_email": "admin@example.com"
}
```

## Récupérer les paramètres de notification {#retrieve-notification-settings}

Récupère le niveau de notification pour un groupe ou un projet spécifié.

```plaintext
GET /groups/:id/notification_settings
GET /projects/:id/notification_settings
```

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/notification_settings"
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/8/notification_settings"
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe ou du projet |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type   | Description |
| --------- | ------ | ----------- |
| `level`   | string | Niveau de notification |

Exemple de réponse pour un niveau de notification standard :

```json
{
  "level": "global"
}
```

Exemple de réponse pour un groupe avec un niveau de notification personnalisé :

```json
{
  "level": "custom",
  "events": {
    "new_release": null,
    "new_note": null,
    "new_issue": null,
    "reopen_issue": null,
    "close_issue": null,
    "reassign_issue": null,
    "issue_due": null,
    "new_merge_request": null,
    "push_to_merge_request": null,
    "reopen_merge_request": null,
    "close_merge_request": null,
    "reassign_merge_request": null,
    "change_reviewer_merge_request": null,
    "merge_merge_request": null,
    "failed_pipeline": null,
    "fixed_pipeline": null,
    "success_pipeline": null,
    "moved_project": true,
    "merge_when_pipeline_succeeds": false,
    "new_epic": null
  }
}
```

Dans cette réponse :

- `true` indique que la notification est activée.
- `false` indique que la notification est désactivée.
- `null` indique que la notification utilise le paramètre par défaut.

> [!note]
> L'attribut `new_epic` est disponible uniquement dans les niveaux Premium et Ultimate.

## Mettre à jour les paramètres de notification d'un groupe ou d'un projet {#update-group-or-project-notification-settings}

Met à jour les paramètres de notification pour un groupe ou un projet.

```plaintext
PUT /groups/:id/notification_settings
PUT /projects/:id/notification_settings
```

Exemples de requêtes :

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/notification_settings?level=watch"
```

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/8/notification_settings?level=custom&new_note=true"
```

Attributs pris en charge :

| Attribut                      | Type              | Obligatoire | Description |
| ------------------------------ | ----------------- | -------- | ----------- |
| `approver`                     | boolean           | Non       | Activer les notifications lorsqu'une merge request que vous êtes éligible à approuver est créée |
| `change_reviewer_merge_request`| boolean           | Non       | Activer les notifications lorsque le relecteur d'une merge request change |
| `close_issue`                  | boolean           | Non       | Activer les notifications lorsqu'un ticket est fermé |
| `close_merge_request`          | boolean           | Non       | Activer les notifications lorsqu'une merge request est fermée |
| `failed_pipeline`              | boolean           | Non       | Activer les notifications lorsqu'un pipeline échoue |
| `fixed_pipeline`               | boolean           | Non       | Activer les notifications lorsqu'un pipeline précédemment en échec est corrigé |
| `id`                           | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe ou du projet |
| `issue_due`                    | boolean           | Non       | Activer les notifications lorsqu'un ticket arrive à échéance demain |
| `level`                        | string            | Non       | Niveau de notification pour ce groupe ou ce projet |
| `merge_merge_request`          | boolean           | Non       | Activer les notifications lorsqu'une merge request est fusionnée |
| `merge_when_pipeline_succeeds` | boolean           | Non       | Activer les notifications lorsqu'une merge request est configurée pour être fusionnée lorsque son pipeline réussit |
| `moved_project`                | boolean           | Non       | Activer les notifications lorsqu'un projet est déplacé |
| `new_epic`                     | boolean           | Non       | Activer les notifications lorsqu'un nouvel epic est créé (dans les niveaux Premium et Ultimate) |
| `new_issue`                    | boolean           | Non       | Activer les notifications lorsqu'un nouveau ticket est créé |
| `new_merge_request`            | boolean           | Non       | Activer les notifications lorsqu'une nouvelle merge request est créée |
| `new_note`                     | boolean           | Non       | Activer les notifications lorsqu'un nouveau commentaire est ajouté |
| `new_release`                  | boolean           | Non       | Activer les notifications lorsqu'une nouvelle release est publiée |
| `push_to_merge_request`        | boolean           | Non       | Activer les notifications lorsque quelqu'un pousse vers une merge request |
| `reassign_issue`               | boolean           | Non       | Activer les notifications lorsqu'un ticket est réassigné |
| `reassign_merge_request`       | boolean           | Non       | Activer les notifications lorsqu'une merge request est réassignée |
| `reopen_issue`                 | boolean           | Non       | Activer les notifications lorsqu'un ticket est rouvert |
| `reopen_merge_request`         | boolean           | Non       | Activer les notifications lorsqu'une merge request est rouverte |
| `success_pipeline`             | boolean           | Non       | Activer les notifications lorsqu'un pipeline se termine avec succès |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et l'un des formats de réponse suivants.

Pour un niveau de notification non personnalisé :

```json
{
  "level": "watch"
}
```

Pour un niveau de notification personnalisé, la réponse inclut un objet `events` indiquant l'état de chaque notification :

```json
{
  "level": "custom",
  "events": {
    "new_release": null,
    "new_note": true,
    "new_issue": false,
    "reopen_issue": null,
    "close_issue": null,
    "reassign_issue": null,
    "issue_due": null,
    "new_merge_request": null,
    "push_to_merge_request": null,
    "reopen_merge_request": null,
    "close_merge_request": null,
    "reassign_merge_request": null,
    "change_reviewer_merge_request": null,
    "merge_merge_request": null,
    "failed_pipeline": false,
    "fixed_pipeline": null,
    "success_pipeline": null,
    "moved_project": false,
    "merge_when_pipeline_succeeds": false,
    "new_epic": null
  }
}
```

Dans cette réponse :

- `true` indique que la notification est activée.
- `false` indique que la notification est désactivée.
- `null` indique que la notification utilise le paramètre par défaut.

> [!note]
> L'attribut `new_epic` est disponible uniquement dans les niveaux Premium et Ultimate.
