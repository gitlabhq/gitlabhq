---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST des approbations de merge request dans GitLab."
title: API des approbations de merge request
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Le point de terminaison `/approvals` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) dans GitLab 16.0.

{{< /history >}}

Utilisez cette API pour gérer les [approbations de merge request](../user/project/merge_requests/approvals/_index.md).

Tous les points de terminaison nécessitent une authentification.

## Approuver une merge request {#approve-merge-request}

Approuve la merge request spécifiée. L'utilisateur actuellement authentifié doit être un [approbateur éligible](../user/project/merge_requests/approvals/rules.md#eligible-approvers).

Le paramètre `sha` garantit que vous approuvez la version actuelle de la merge request. S'il est défini, la valeur doit correspondre au SHA du commit HEAD de la merge request. Une incohérence renvoie une réponse `409 Conflict`. Cela correspond au comportement [d'acceptation d'une merge request](merge_requests.md#merge-a-merge-request).

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/approve
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |
| `approval_password` | string            | Non       | Mot de passe de l'utilisateur actuel. Requis si [**Require user re-authentication to approve**](../user/project/merge_requests/approvals/settings.md#require-user-re-authentication-to-approve) est activé dans les paramètres du projet. Échoue toujours si le groupe ou l'instance GitLab Self-Managed est configuré pour forcer l'authentification SAML. |
| `merge_request_iid` | entier           | Oui      | L'IID de la merge request. |
| `sha`               | string            | Non       | Le `HEAD` de la merge request. |

```json
{
  "id": 5,
  "iid": 5,
  "project_id": 1,
  "title": "Approvals API",
  "description": "Test",
  "state": "opened",
  "created_at": "2016-06-08T00:19:52.638Z",
  "updated_at": "2016-06-09T21:32:14.105Z",
  "merge_status": "can_be_merged",
  "approvals_required": 2,
  "approvals_left": 0,
  "approved_by": [
    {
      "user": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
        "web_url": "http://localhost:3000/root"
      },
      "approved_at": "2016-06-10T04:21:41.050Z"
    },
    {
      "user": {
        "name": "Nico Cartwright",
        "username": "ryley",
        "id": 2,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/cf7ad14b34162a76d593e3affca2adca?s=80\u0026d=identicon",
        "web_url": "http://localhost:3000/ryley"
      },
      "approved_at": "2016-06-10T09:17:13.520Z"
    }
  ]
}
```

### Empêcher la réinitialisation des approbations dans les merge requests automatisées {#prevent-approval-resets-in-automated-merge-requests}

Si vous utilisez l'API pour créer et approuver immédiatement une merge request, votre automatisation peut approuver la merge request avant que le commit soit entièrement traité. Par défaut, l'ajout d'un nouveau commit à une merge request [réinitialise toutes les approbations existantes](../user/project/merge_requests/approvals/settings.md#remove-all-approvals-when-commits-are-added-to-the-source-branch). Lorsque cela se produit, la zone **Activité** de la merge request affiche une séquence de messages comme ceci :

- `(botname)` a approuvé cette merge request il y a 5 minutes
- `(botname)` a ajouté 1 commit il y a 5 minutes
- `(botname)` a réinitialisé les approbations de `(botname)` en poussant vers la branche il y a 5 minutes

Pour vous assurer que les approbations automatisées ne sont pas appliquées avant que le traitement du commit soit terminé, votre automatisation doit ajouter une fonction d'attente (ou `sleep`) jusqu'à ce que :

- L'attribut `detailed_merge_status` n'est ni dans l'état `checking` ni dans l'état `approvals_syncing`.
- Le diff de la merge request contient un `patch_id_sha` qui n'est pas NULL.

## Désapprouver une merge request {#unapprove-a-merge-request}

Supprime l'approbation de l'utilisateur actuellement authentifié pour une merge request spécifiée.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/unapprove
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |
| `merge_request_iid` | entier           | Oui      | L'IID d'une merge request. |

## Réinitialiser les approbations d'une merge request {#reset-approvals-for-a-merge-request}

Réinitialise toutes les approbations d'une merge request spécifiée.

Disponible uniquement pour les [utilisateurs bot](../user/project/settings/project_access_tokens.md#bot-users-for-projects) disposant d'un jeton de projet ou de groupe valide. Les utilisateurs humains reçoivent une réponse `401 Unauthorized`.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/reset_approvals
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) du projet. |
| `merge_request_iid` | entier           | Oui      | L'ID interne de la merge request. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/reset_approvals"
```

## Règles d'approbation pour les projets {#approval-rules-for-projects}

Ces points de terminaison s'appliquent aux projets et à leurs règles d'approbation. Tous les points de terminaison nécessitent une authentification.

### Récupérer la configuration d'approbation d'un projet {#retrieve-approval-configuration-for-a-project}

Récupère la configuration d'approbation d'un projet.

```plaintext
GET /projects/:id/approvals
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |

```json
{
  "approvers": [], // Deprecated in GitLab 12.3, always returns empty
  "approver_groups": [], // Deprecated in GitLab 12.3, always returns empty
  "approvals_before_merge": 2, // Deprecated in GitLab 12.3, use Approval Rules instead
  "reset_approvals_on_push": true,
  "selective_code_owner_removals": false,
  "disable_overriding_approvers_per_merge_request": false,
  "merge_requests_author_approval": true,
  "merge_requests_disable_committers_approval": false,
  "require_password_to_approve": true, // Deprecated in 16.9, use require_reauthentication_to_approve instead
  "require_reauthentication_to_approve": true
}
```

### Mettre à jour la configuration d'approbation d'un projet {#update-approval-configuration-for-a-project}

Met à jour la configuration d'approbation d'un projet. L'utilisateur actuellement authentifié doit être un [approbateur éligible](../user/project/merge_requests/approvals/rules.md#eligible-approvers).

```plaintext
POST /projects/:id/approvals
```

Attributs pris en charge :

| Attribut                                        | Type              | Obligatoire | Description |
|--------------------------------------------------|-------------------|----------|-------------|
| `id`                                             | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |
| `approvals_before_merge` (déprécié)            | entier           | Non       | Le nombre d'approbations requises avant qu'une merge request puisse être fusionnée. [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/11132) dans GitLab 12.3. [Créez une règle d'approbation](#create-an-approval-rule-for-a-project) à la place.  |
| `disable_overriding_approvers_per_merge_request` | boolean           | Non       | Si `true`, empêche les modifications des approbateurs dans une merge request. |
| `merge_requests_author_approval`                 | boolean           | Non       | Si `true`, les auteurs peuvent s'auto-approuver leurs propres merge requests. |
| `merge_requests_disable_committers_approval`     | boolean           | Non       | Si `true`, les utilisateurs qui font des commits sur une merge request ne peuvent pas l'approuver. |
| `require_password_to_approve` (déprécié)       | boolean           | Non       | Si `true`, exige que les approbateurs s'authentifient avec un mot de passe avant d'ajouter l'approbation. [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/431346) dans GitLab 16.9. Utilisez `require_reauthentication_to_approve` à la place. |
| `require_reauthentication_to_approve`            | boolean           | Non       | Si `true`, exige que l'approbateur s'authentifie avant d'ajouter l'approbation. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/431346) dans GitLab 17.1. |
| `reset_approvals_on_push`                        | boolean           | Non       | Si `true`, les approbations sont réinitialisées lors d'un push. |
| `selective_code_owner_removals`                  | boolean           | Non       | Si `true`, réinitialise les approbations des propriétaires du code si leurs fichiers changent. Pour utiliser ce champ, `reset_approvals_on_push` doit être `false`. |

```json
{
  "approvals_before_merge": 2, // Use Approval Rules instead
  "reset_approvals_on_push": true,
  "selective_code_owner_removals": false,
  "disable_overriding_approvers_per_merge_request": false,
  "merge_requests_author_approval": false,
  "merge_requests_disable_committers_approval": false,
  "require_password_to_approve": true,
  "require_reauthentication_to_approve": true
}
```

### Lister toutes les règles d'approbation d'un projet {#list-all-approval-rules-for-a-project}

Répertorie toutes les règles d'approbation et tous les détails associés pour un projet spécifié.

```plaintext
GET /projects/:id/approval_rules
```

Pour restreindre la liste des règles d'approbation, utilisez les paramètres de [pagination](rest/_index.md#offset-based-pagination) `page` et `per_page`.

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "security",
    "rule_type": "regular",
    "report_type": null,
    "eligible_approvers": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      },
      {
        "id": 50,
        "name": "Group Member 1",
        "username": "group_member_1",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/group_member_1"
      }
    ],
    "approvals_required": 3,
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      }
    ],
    "groups": [
      {
        "id": 5,
        "name": "group1",
        "path": "group1",
        "description": "",
        "visibility": "public",
        "lfs_enabled": false,
        "avatar_url": null,
        "web_url": "http://localhost/groups/group1",
        "request_access_enabled": false,
        "full_name": "group1",
        "full_path": "group1",
        "parent_id": null,
        "ldap_cn": null,
        "ldap_access": null
      }
    ],
    "applies_to_all_protected_branches": false,
    "protected_branches": [
      {
        "id": 1,
        "name": "main",
        "push_access_levels": [
          {
            "access_level": 30,
            "access_level_description": "Developers + Maintainers"
          }
        ],
        "merge_access_levels": [
          {
            "access_level": 30,
            "access_level_description": "Developers + Maintainers"
          }
        ],
        "unprotect_access_levels": [
          {
            "access_level": 40,
            "access_level_description": "Maintainers"
          }
        ],
        "code_owner_approval_required": "false"
      }
    ],
    "contains_hidden_groups": false,
  },
  {
    "id": 2,
    "name": "Coverage-Check",
    "rule_type": "report_approver",
    "report_type": "code_coverage",
    "eligible_approvers": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      },
      {
        "id": 50,
        "name": "Group Member 1",
        "username": "group_member_1",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/group_member_1"
      }
    ],
    "approvals_required": 3,
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      }
    ],
    "groups": [
      {
        "id": 5,
        "name": "group1",
        "path": "group1",
        "description": "",
        "visibility": "public",
        "lfs_enabled": false,
        "avatar_url": null,
        "web_url": "http://localhost/groups/group1",
        "request_access_enabled": false,
        "full_name": "group1",
        "full_path": "group1",
        "parent_id": null,
        "ldap_cn": null,
        "ldap_access": null
      }
    ],
    "applies_to_all_protected_branches": false,
    "protected_branches": [
      {
        "id": 1,
        "name": "main",
        "push_access_levels": [
          {
            "access_level": 30,
            "access_level_description": "Developers + Maintainers"
          }
        ],
        "merge_access_levels": [
          {
            "access_level": 30,
            "access_level_description": "Developers + Maintainers"
          }
        ],
        "unprotect_access_levels": [
          {
            "access_level": 40,
            "access_level_description": "Maintainers"
          }
        ],
        "code_owner_approval_required": "false"
      }
    ],
    "contains_hidden_groups": false,
  }
]
```

Chaque objet de la réponse inclut un tableau `eligible_approvers`. Le tableau répertorie les utilisateurs qui peuvent approuver une merge request à laquelle la règle s'applique. Les approbateurs éligibles dépendent de la configuration de la règle et de l'appartenance au projet et au groupe. Pour plus d'informations, voir [les approbateurs éligibles](../user/project/merge_requests/approvals/rules.md#eligible-approvers).

### Récupérer une règle d'approbation d'un projet {#retrieve-an-approval-rule-for-a-project}

Récupère des informations sur une règle d'approbation spécifiée pour un projet.

```plaintext
GET /projects/:id/approval_rules/:approval_rule_id
```

Attributs pris en charge :

| Attribut          | Type              | Obligatoire | Description |
|--------------------|-------------------|----------|-------------|
| `id`               | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |
| `approval_rule_id` | entier           | Oui      | L'ID d'une règle d'approbation. |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "report_type": null,
  "eligible_approvers": [
    {
      "id": 5,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 3,
  "users": [
    {
      "id": 5,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "applies_to_all_protected_branches": false,
  "protected_branches": [
    {
      "id": 1,
      "name": "main",
      "push_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "merge_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "unprotect_access_levels": [
        {
          "access_level": 40,
          "access_level_description": "Maintainers"
        }
      ],
      "code_owner_approval_required": "false"
    }
  ],
  "contains_hidden_groups": false
}
```

### Créer une règle d'approbation pour un projet {#create-an-approval-rule-for-a-project}

Crée une règle d'approbation pour un projet.

Le champ `rule_type` prend en charge ces types de règles :

- `any_approver` : Une règle par défaut préconfigurée avec `approvals_required` défini sur `0`.
- `regular` : Utilisé pour les [règles d'approbation de merge request](../user/project/merge_requests/approvals/rules.md) standard.
- `report_approver` : Utilisé lorsque GitLab crée une règle d'approbation à partir de [politiques d'approbation de merge request](../user/application_security/policies/merge_request_approval_policies.md) configurées et activées. N'utilisez pas cette valeur lors de la création de règles d'approbation avec cette API.

```plaintext
POST /projects/:id/approval_rules
```

Attributs pris en charge :

| Attribut                           | Type              | Obligatoire | Description |
|-------------------------------------|-------------------|----------|-------------|
| `id`                                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |
| `approvals_required`                | entier           | Oui      | Le nombre d'approbations requises pour cette règle. |
| `name`                              | string            | Oui      | Le nom de la règle d'approbation. Limité à 1 024 caractères. |
| `applies_to_all_protected_branches` | boolean           | Non       | Si `true`, applique la règle à toutes les branches protégées et ignore l'attribut `protected_branch_ids`. |
| `group_ids`                         | Tableau             | Non       | Les ID des groupes en tant qu'approbateurs. |
| `protected_branch_ids`              | Tableau             | Non       | Les ID des branches protégées pour délimiter la règle. Pour identifier l'ID, utilisez l'API [Lister les branches protégées](protected_branches.md#list-protected-branches). |
| `report_type`                       | string            | Non       | Le type de rapport. Requis lorsque le type de règle est `report_approver`. Les types de rapports pris en charge sont `license_scanning` [(Déprécié dans GitLab 15.9)](../update/deprecations.md#license-check-and-the-policies-tab-on-the-license-compliance-page) et `code_coverage`.   |
| `rule_type`                         | string            | Non       | Le type de règle. Les valeurs prises en charge incluent `any_approver`, `regular` et `report_approver`. |
| `user_ids`                          | Tableau             | Non       | Les ID des utilisateurs en tant qu'approbateurs. Si utilisé avec `usernames`, ajoute les deux listes d'utilisateurs. |
| `usernames`                         | tableau de chaînes      | Non       | Les noms d'utilisateur des approbateurs. Si utilisé avec `user_ids`, ajoute les deux listes d'utilisateurs. |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "applies_to_all_protected_branches": false,
  "protected_branches": [
    {
      "id": 1,
      "name": "main",
      "push_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "merge_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "unprotect_access_levels": [
        {
          "access_level": 40,
          "access_level_description": "Maintainers"
        }
      ],
      "code_owner_approval_required": "false"
    }
  ],
  "contains_hidden_groups": false
}
```

Pour augmenter le nombre par défaut de 0 approbateurs requis :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"name": "Any name", "rule_type": "any_approver", "approvals_required": 2}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/approval_rules"
```

Un autre exemple est la création d'une règle spécifique à un utilisateur :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"name": "Name of your rule", "approvals_required": 3, "user_ids": [123, 456, 789]}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/approval_rules"
```

### Mettre à jour une règle d'approbation pour un projet {#update-an-approval-rule-for-a-project}

Met à jour une règle d'approbation spécifiée pour un projet. Ce point de terminaison supprime tous les approbateurs et groupes non définis dans les attributs `group_ids`, `user_ids` ou `usernames`.

Les groupes masqués (groupes privés que l'utilisateur n'est pas autorisé à consulter) qui ne figurent pas dans les paramètres `users` ou `groups` sont conservés par défaut. Pour les supprimer, définissez `remove_hidden_groups` sur `true`. Cela garantit que les groupes masqués ne sont pas supprimés involontairement lorsqu'un utilisateur met à jour une règle d'approbation.

```plaintext
PUT /projects/:id/approval_rules/:approval_rule_id
```

Attributs pris en charge :

| Attribut                           | Type              | Obligatoire | Description |
|-------------------------------------|-------------------|----------|-------------|
| `approval_rule_id`                  | entier           | Oui      | L'ID d'une règle d'approbation. |
| `id`                                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |
| `applies_to_all_protected_branches` | boolean           | Non       | Si `true`, applique la règle à toutes les branches protégées et ignore l'attribut `protected_branch_ids`. |
| `approvals_required`                | entier           | Non       | Le nombre d'approbations requises pour cette règle. |
| `group_ids`                         | Tableau             | Non       | Les ID des groupes en tant qu'approbateurs. |
| `name`                              | string            | Non       | Le nom de la règle d'approbation. Limité à 1 024 caractères. |
| `protected_branch_ids`              | Tableau             | Non       | Les ID des branches protégées pour délimiter la règle. Pour identifier l'ID, utilisez l'API [Lister les branches protégées](protected_branches.md#list-protected-branches). |
| `remove_hidden_groups`              | boolean           | Non       | Si `true`, supprime les groupes masqués de la règle d'approbation. |
| `user_ids`                          | Tableau             | Non       | Les ID des utilisateurs en tant qu'approbateurs. Si utilisé avec `usernames`, ajoute les deux listes d'utilisateurs. |
| `usernames`                         | tableau de chaînes      | Non       | Les noms d'utilisateur des approbateurs. Si utilisé avec `user_ids`, ajoute les deux listes d'utilisateurs. |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "applies_to_all_protected_branches": false,
  "protected_branches": [
    {
      "id": 1,
      "name": "main",
      "push_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "merge_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "unprotect_access_levels": [
        {
          "access_level": 40,
          "access_level_description": "Maintainers"
        }
      ],
      "code_owner_approval_required": "false"
    }
  ],
  "contains_hidden_groups": false
}
```

### Supprimer une règle d'approbation d'un projet {#delete-an-approval-rule-for-a-project}

Supprime une règle d'approbation pour un projet spécifié.

```plaintext
DELETE /projects/:id/approval_rules/:approval_rule_id
```

Attributs pris en charge :

| Attribut          | Type              | Obligatoire | Description |
|--------------------|-------------------|----------|-------------|
| `id`               | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |
| `approval_rule_id` | entier           | Oui      | L'ID d'une règle d'approbation. |

## Règles d'approbation pour une merge request {#approval-rules-for-a-merge-request}

Ces points de terminaison s'appliquent aux merge requests individuelles. Tous les points de terminaison nécessitent une authentification.

### Récupérer l'état d'approbation d'une merge request {#retrieve-approval-state-for-a-merge-request}

Récupère l'état d'approbation d'une merge request spécifiée.

Dans la réponse, `approved_by` contient des informations sur tous les approbateurs de la merge request, que ces approbations satisfassent ou non une règle d'approbation. Pour des informations plus détaillées sur les règles d'approbation d'une merge request et sur la question de savoir si les approbations reçues satisfont ces règles, consultez le [point de terminaison `/approval_state`](#retrieve-approval-details-for-a-merge-request).

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approvals
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |
| `merge_request_iid` | entier           | Oui      | L'IID de la merge request. |

```json
{
  "id": 5,
  "iid": 5,
  "project_id": 1,
  "title": "Approvals API",
  "description": "Test",
  "state": "opened",
  "created_at": "2016-06-08T00:19:52.638Z",
  "updated_at": "2016-06-08T21:20:42.470Z",
  "merge_status": "cannot_be_merged",
  "approvals_required": 2,
  "approvals_left": 1,
  "approved_by": [
    {
      "user": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
        "web_url": "http://localhost:3000/root"
      },
      "approved_at": "2016-06-09T01:45:21.720Z"
    }
  ]
}
```

### Récupérer les détails d'approbation d'une merge request {#retrieve-approval-details-for-a-merge-request}

Récupère les détails d'approbation d'une merge request spécifiée.

Si un utilisateur a modifié les règles d'approbation de la merge request, la réponse inclut :

- `approval_rules_overwritten` : Si `true`, indique que les règles d'approbation par défaut ont été modifiées.
- `approved` : Si `true`, indique que la règle d'approbation associée a été approuvée.
- `approved_by` : Si défini, indique les détails de l'utilisateur qui a approuvé la règle d'approbation associée. Les utilisateurs ne correspondant pas à une règle d'approbation ne sont pas renvoyés. Pour renvoyer tous les utilisateurs approbateurs, consultez le [point de terminaison `/approvals`](#retrieve-approval-state-for-a-merge-request).

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approval_state
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |
| `merge_request_iid` | entier           | Oui      | L'IID de la merge request. |

```json
{
  "approval_rules_overwritten": true,
  "rules": [
    {
      "id": 1,
      "name": "Ruby",
      "rule_type": "regular",
      "eligible_approvers": [
        {
          "id": 4,
          "name": "John Doe",
          "username": "jdoe",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "http://localhost/jdoe"
        }
      ],
      "approvals_required": 2,
      "users": [
        {
          "id": 4,
          "name": "John Doe",
          "username": "jdoe",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "http://localhost/jdoe"
        }
      ],
      "groups": [],
      "contains_hidden_groups": false,
      "approved_by": [
        {
          "id": 4,
          "name": "John Doe",
          "username": "jdoe",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "http://localhost/jdoe"
        }
      ],
      "source_rule": null,
      "approved": true,
      "overridden": false
    }
  ]
}
```

### Lister toutes les règles d'approbation d'une merge request {#list-all-approval-rules-for-a-merge-request}

Répertorie toutes les règles d'approbation et tous les détails associés pour une merge request spécifiée.

Utilisez les paramètres de [pagination](rest/_index.md#offset-based-pagination) `page` et `per_page` pour restreindre la liste des règles d'approbation.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approval_rules
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |
| `merge_request_iid` | entier           | Oui      | L'IID de la merge request. |

```json
[
  {
    "id": 1,
    "name": "security",
    "rule_type": "regular",
    "report_type": null,
    "eligible_approvers": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      },
      {
        "id": 50,
        "name": "Group Member 1",
        "username": "group_member_1",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/group_member_1"
      }
    ],
    "approvals_required": 3,
    "source_rule": null,
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      }
    ],
    "groups": [
      {
        "id": 5,
        "name": "group1",
        "path": "group1",
        "description": "",
        "visibility": "public",
        "lfs_enabled": false,
        "avatar_url": null,
        "web_url": "http://localhost/groups/group1",
        "request_access_enabled": false,
        "full_name": "group1",
        "full_path": "group1",
        "parent_id": null,
        "ldap_cn": null,
        "ldap_access": null
      }
    ],
    "contains_hidden_groups": false,
    "overridden": false
  },
  {
    "id": 2,
    "name": "Coverage-Check",
    "rule_type": "report_approver",
    "report_type": "code_coverage",
    "eligible_approvers": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      },
      {
        "id": 50,
        "name": "Group Member 1",
        "username": "group_member_1",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/group_member_1"
      }
    ],
    "approvals_required": 3,
    "source_rule": null,
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      }
    ],
    "groups": [
      {
        "id": 5,
        "name": "group1",
        "path": "group1",
        "description": "",
        "visibility": "public",
        "lfs_enabled": false,
        "avatar_url": null,
        "web_url": "http://localhost/groups/group1",
        "request_access_enabled": false,
        "full_name": "group1",
        "full_path": "group1",
        "parent_id": null,
        "ldap_cn": null,
        "ldap_access": null
      }
    ],
    "contains_hidden_groups": false,
    "overridden": false
  }
]
```

### Récupérer une règle d'approbation pour une merge request spécifique {#retrieve-an-approval-rule-for-a-specific-merge-request}

Récupère des informations sur une règle d'approbation pour une merge request spécifique.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |
| `approval_rule_id`  | entier           | Oui      | L'ID d'une règle d'approbation. |
| `merge_request_iid` | entier           | Oui      | L'IID d'une merge request. |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "report_type": null,
  "eligible_approvers": [
    {
      "id": 5,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 3,
  "source_rule": null,
  "users": [
    {
      "id": 5,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "contains_hidden_groups": false,
  "overridden": false
}
```

### Créer une règle d'approbation pour une merge request {#create-an-approval-rule-for-a-merge-request}

Crée une règle d'approbation pour une merge request spécifique. Si `approval_project_rule_id` est défini avec l'ID d'une règle d'approbation existante du projet, ce point de terminaison :

- Copie les valeurs de `name`, `users` et `groups` à partir de la règle du projet.
- Utilise la valeur de `approvals_required` que vous spécifiez.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/approval_rules
```

Attributs pris en charge :

| Attribut                  | Type              | Obligatoire               | Description                                                                  |
|----------------------------|-------------------|------------------------|------------------------------------------------------------------------------|
| `id`                       | entier ou chaîne | Oui | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |
| `approvals_required`       | entier           | Oui | Le nombre d'approbations requises pour cette règle.                              |
| `merge_request_iid`        | entier           | Oui | L'IID de la merge request.                                                |
| `name`                     | string            | Oui | Le nom de la règle d'approbation. Limité à 1 024 caractères.                                               |
| `approval_project_rule_id` | entier           | Non | L'ID de la règle d'approbation d'un projet.                                     |
| `group_ids`                | Tableau             | Non | Les ID des groupes en tant qu'approbateurs.                                              |
| `user_ids`                 | Tableau             | Non | Les ID des utilisateurs en tant qu'approbateurs. Si utilisé avec `usernames`, ajoute les deux listes d'utilisateurs. |
| `usernames`                | tableau de chaînes      | Non | Les noms d'utilisateur des approbateurs. Si utilisé avec `user_ids`, ajoute les deux listes d'utilisateurs. |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "source_rule": null,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "contains_hidden_groups": false,
  "overridden": false
}
```

### Mettre à jour une règle d'approbation pour une merge request {#update-an-approval-rule-for-a-merge-request}

Met à jour une règle d'approbation spécifiée pour une merge request. Ce point de terminaison supprime tous les approbateurs et groupes non inclus dans les attributs `group_ids`, `user_ids` ou `usernames`.

Les règles `report_approver` ou `code_owner` sont générées par le système et vous ne pouvez pas les modifier.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

Attributs pris en charge :

| Attribut              | Type              | Obligatoire | Description |
|------------------------|-------------------|----------|-------------|
| `id`                   | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |
| `approval_rule_id`     | entier           | Oui      | L'ID d'une règle d'approbation. |
| `merge_request_iid`    | entier           | Oui      | L'IID d'une merge request. |
| `approvals_required`   | entier           | Non       | Le nombre d'approbations requises pour cette règle. |
| `group_ids`            | Tableau             | Non       | Les ID des groupes en tant qu'approbateurs. |
| `name`                 | string            | Non       | Le nom de la règle d'approbation. Limité à 1 024 caractères. |
| `remove_hidden_groups` | boolean           | Non       | Si `true`, supprime les groupes masqués. |
| `user_ids`             | Tableau             | Non       | Les ID des utilisateurs en tant qu'approbateurs. Si utilisé avec `usernames`, ajoute les deux listes d'utilisateurs. |
| `usernames`            | tableau de chaînes      | Non       | Les noms d'utilisateur des approbateurs. Si utilisé avec `user_ids`, ajoute les deux listes d'utilisateurs. |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "source_rule": null,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "contains_hidden_groups": false,
  "overridden": false
}
```

### Supprimer une règle d'approbation pour une merge request {#delete-an-approval-rule-for-a-merge-request}

Supprime une règle d'approbation pour une merge request spécifiée.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

Les règles `report_approver` ou `code_owner` sont générées par le système et vous ne pouvez pas les modifier.

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |
| `approval_rule_id`  | entier           | Oui      | L'ID d'une règle d'approbation. |
| `merge_request_iid` | entier           | Oui      | L'IID de la merge request. |

## Règles d'approbation pour les groupes {#approval-rules-for-groups}

{{< details >}}

- Statut : Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/428051) dans GitLab 16.7 [avec un flag](../administration/feature_flags/_index.md) nommé `approval_group_rules`. Désactivé par défaut. Cette fonctionnalité est une [expérience](../policy/development_stages_support.md).

{{< /history >}}

> [!flag]
> Sur GitLab Self-Managed, cette fonctionnalité n'est pas disponible par défaut. Pour la rendre disponible, un administrateur peut [activer le feature flag](../administration/feature_flags/_index.md) nommé `approval_group_rules`. Sur GitLab.com et GitLab Dedicated, cette fonctionnalité n'est pas disponible. Cette fonctionnalité n'est pas prête pour une utilisation en production.

Les règles d'approbation de groupe s'appliquent à toutes les branches protégées des projets appartenant au groupe.

### Lister toutes les règles d'approbation d'un groupe {#list-all-approval-rules-for-a-group}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/440638) dans GitLab 16.10.

{{< /history >}}

Répertorie toutes les règles d'approbation et tous les détails associés pour un groupe spécifié. Réservé aux administrateurs de groupe.

Utilisez les paramètres de [pagination](rest/_index.md#offset-based-pagination) `page` et `per_page` pour restreindre la liste des règles d'approbation.

```plaintext
GET /groups/:id/approval_rules
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL](rest/_index.md#namespaced-paths) d'un projet. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/29/approval_rules"
```

Exemple de réponse :

```json
[
  {
    "id": 2,
    "name": "rule1",
    "rule_type": "any_approver",
    "report_type": null,
    "eligible_approvers": [],
    "approvals_required": 3,
    "users": [],
    "groups": [],
    "contains_hidden_groups": false,
    "protected_branches": [],
    "applies_to_all_protected_branches": true
  },
  {
    "id": 3,
    "name": "rule2",
    "rule_type": "code_owner",
    "report_type": null,
    "eligible_approvers": [],
    "approvals_required": 2,
    "users": [],
    "groups": [],
    "contains_hidden_groups": false,
    "protected_branches": [],
    "applies_to_all_protected_branches": true
  },
  {
    "id": 4,
    "name": "rule2",
    "rule_type": "report_approver",
    "report_type": "code_coverage",
    "eligible_approvers": [],
    "approvals_required": 2,
    "users": [],
    "groups": [],
    "contains_hidden_groups": false,
    "protected_branches": [],
    "applies_to_all_protected_branches": true
  }
]

```

### Créer une règle d'approbation pour un groupe {#create-an-approval-rule-for-a-group}

Crée une règle d'approbation pour un groupe. Réservé aux administrateurs de groupe.

N'utilisez pas le champ `rule_type` lors de la création de règles d'approbation depuis l'API. Le champ prend en charge ces types de règles :

- `any_approver` : Une règle par défaut préconfigurée avec `approvals_required` défini sur `0`.
- `regular` : Utilisé pour les [règles d'approbation de merge request](../user/project/merge_requests/approvals/rules.md) standard.
- `report_approver` : Utilisé lorsque GitLab crée une règle d'approbation à partir de [politiques d'approbation de merge request](../user/application_security/policies/merge_request_approval_policies.md) configurées et activées.

```plaintext
POST /groups/:id/approval_rules
```

Attributs pris en charge :

| Attribut            | Type              | Obligatoire | Description |
|----------------------|-------------------|----------|-------------|
| `id`                 | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL d'un groupe](rest/_index.md#namespaced-paths). |
| `approvals_required` | entier           | Oui      | Le nombre d'approbations requises pour cette règle. |
| `name`               | string            | Oui      | Le nom de la règle d'approbation. Limité à 1 024 caractères. |
| `group_ids`          | tableau             | Non       | Les ID des groupes en tant qu'approbateurs. |
| `rule_type`          | string            | Non       | Le type de règle. Les valeurs prises en charge incluent `any_approver`, `regular` et `report_approver`. |
| `user_ids`           | tableau             | Non       | Les ID des utilisateurs en tant qu'approbateurs. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/29/approval_rules?name=security&approvals_required=2"
```

Exemple de réponse :

```json
{
  "id": 5,
  "name": "security",
  "rule_type": "any_approver",
  "eligible_approvers": [],
  "approvals_required": 2,
  "users": [],
  "groups": [],
  "contains_hidden_groups": false,
  "protected_branches": [
    {
      "id": 5,
      "name": "master",
      "push_access_levels": [
        {
          "id": 5,
          "access_level": 40,
          "access_level_description": "Maintainers",
          "deploy_key_id": null,
          "user_id": null,
          "group_id": null
        }
      ],
      "merge_access_levels": [
        {
          "id": 5,
          "access_level": 40,
          "access_level_description": "Maintainers",
          "user_id": null,
          "group_id": null
        }
      ],
      "allow_force_push": false,
      "unprotect_access_levels": [],
      "code_owner_approval_required": false,
      "inherited": false
    }
  ],
  "applies_to_all_protected_branches": true
}
```

### Mettre à jour une règle d'approbation pour un groupe {#update-an-approval-rule-for-a-group}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/440639) dans GitLab 16.10.

{{< /history >}}

Met à jour une règle d'approbation pour un groupe. Réservé aux administrateurs de groupe.

N'utilisez pas le champ `rule_type` lors de la création de règles d'approbation depuis l'API. Le champ prend en charge ces types de règles :

- `any_approver` : Une règle par défaut préconfigurée avec `approvals_required` défini sur `0`.
- `regular` : Utilisé pour les [règles d'approbation de merge request](../user/project/merge_requests/approvals/rules.md) standard.
- `report_approver` : Utilisé lorsque GitLab crée une règle d'approbation à partir de [politiques d'approbation de merge request](../user/application_security/policies/merge_request_approval_policies.md) configurées et activées.

```shell
PUT /groups/:id/approval_rules/:approval_rule_id
```

Attributs pris en charge :

| Attribut            | Type              | Obligatoire | Description |
|----------------------|-------------------|----------|-------------|
| `approval_rule_id`   | entier           | Oui      | L'ID de la règle d'approbation. |
| `id`                 | entier ou chaîne | Oui      | L'ID ou le [chemin encodé par URL d'un groupe](rest/_index.md#namespaced-paths). |
| `approvals_required` | string            | Non       | Le nombre d'approbations requises pour cette règle. |
| `group_ids`          | entier           | Non       | Les ID des utilisateurs en tant qu'approbateurs. |
| `name`               | string            | Non       | Le nom de la règle d'approbation. Limité à 1 024 caractères. |
| `rule_type`          | tableau             | Non       | Le type de règle. Les valeurs prises en charge incluent `any_approver`, `regular` et `report_approver`. |
| `user_ids`           | tableau             | Non       | Les ID des groupes en tant qu'approbateurs. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/29/approval_rules/5?name=security2&approvals_required=1"
```

Exemple de réponse :

```json
{
  "id": 5,
  "name": "security2",
  "rule_type": "any_approver",
  "eligible_approvers": [],
  "approvals_required": 1,
  "users": [],
  "groups": [],
  "contains_hidden_groups": false,
  "protected_branches": [
    {
      "id": 5,
      "name": "master",
      "push_access_levels": [
        {
          "id": 5,
          "access_level": 40,
          "access_level_description": "Maintainers",
          "deploy_key_id": null,
          "user_id": null,
          "group_id": null
        }
      ],
      "merge_access_levels": [
        {
          "id": 5,
          "access_level": 40,
          "access_level_description": "Maintainers",
          "user_id": null,
          "group_id": null
        }
      ],
      "allow_force_push": false,
      "unprotect_access_levels": [],
      "code_owner_approval_required": false,
      "inherited": false
    }
  ],
  "applies_to_all_protected_branches": true
}
```
