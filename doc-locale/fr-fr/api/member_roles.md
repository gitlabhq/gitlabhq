---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des rôles de membre
description: "Utilisez l'API Member Roles pour gérer les rôles personnalisés pour les groupes GitLab.com ou les instances GitLab Self-Managed. Répertoriez, créez et supprimez des rôles de membre personnalisés par programmation."
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96996) dans GitLab 15.4. [Déployé derrière le `customizable_roles` flag](../administration/feature_flags/_index.md), désactivé par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110810) dans GitLab 15.9.
- [Read vulnerability ajouté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114734) dans GitLab 16.0.
- [Admin vulnerability ajouté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121534) dans GitLab 16.1.
- [Read dependency ajouté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126247) dans GitLab 16.3.
- [Champs Name et description ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126423) dans GitLab 16.3.
- [Admin merge request introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128302) dans GitLab 16.4 [avec un flag](../administration/feature_flags/_index.md) nommé `admin_merge_request`. Désactivé par défaut.
- [Feature flag `admin_merge_request` supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132578) dans GitLab 16.5.
- [Admin group members introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131914) dans GitLab 16.5 [avec un flag](../administration/feature_flags/_index.md) nommé `admin_group_member`. Désactivé par défaut. Le feature flag a été supprimé dans GitLab 16.6.
- [Manage project access tokens introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132342) dans GitLab 16.5 avec [un flag](../administration/feature_flags/_index.md) nommé `manage_project_access_tokens`. Désactivé par défaut.
- [Archive project introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134998) dans GitLab 16.7.
- [Delete project introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139696) dans GitLab 16.8.
- [Manage group access tokens introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140115) dans GitLab 16.8.
- [Admin terraform state introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140759) dans GitLab 16.8.
- Possibilité de créer et de supprimer un rôle personnalisé à l'échelle de l'instance sur GitLab Self-Managed [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141562) dans GitLab 16.9.

{{< /history >}}

Utilisez cette API pour interagir avec les rôles de membre de vos groupes GitLab.com ou de l'ensemble de votre instance GitLab Self-Managed.

## Gérer les rôles de membre d'instance {#manage-instance-member-roles}

{{< details >}}

- Édition : Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- [Authentifiez-vous](rest/authentication.md) en tant qu'administrateur.

### Obtenir tous les rôles de membre d'instance {#get-all-instance-member-roles}

Récupère tous les rôles de membre d'une instance.

```plaintext
GET /member_roles
```

Exemple de requête :

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/member_roles"
```

Exemple de réponse :

```json
[
  {
    "id": 2,
    "name": "Instance custom role",
    "description": "Custom guest that can read code",
    "group_id": null,
    "base_access_level": 10,
    "admin_cicd_variables": false,
    "admin_compliance_framework": false,
    "admin_group_member": false,
    "admin_merge_request": false,
    "admin_push_rules": false,
    "admin_terraform_state": false,
    "admin_vulnerability": false,
    "admin_web_hook": false,
    "archive_project": false,
    "manage_deploy_tokens": false,
    "manage_group_access_tokens": false,
    "manage_merge_request_settings": false,
    "manage_project_access_tokens": false,
    "manage_security_policy_link": false,
    "read_code": true,
    "read_runners": false,
    "read_dependency": false,
    "read_vulnerability": false,
    "remove_group": false,
    "remove_project": false
  }
]
```

### Créer un rôle de membre d'instance {#create-an-instance-member-role}

Crée un rôle de membre à l'échelle de l'instance.

```plaintext
POST /member_roles
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:--------|:---------|:-------------------------------------|
| `name`         | string         | oui      | Le nom du rôle de membre. |
| `description`  | string         | non       | La description du rôle de membre. |
| `base_access_level` | entier   | oui      | Niveau d'accès de base pour le rôle configuré. Les valeurs valides sont `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner).|
| `admin_cicd_variables` | boolean | non       | Autorisation de créer, lire, mettre à jour et supprimer des variables CI/CD. |
| `admin_compliance_framework` | boolean | non       | Autorisation d'administrer les frameworks de conformité. |
| `admin_group_member` | boolean | non       | Autorisation d'ajouter, de supprimer et d'assigner des membres dans un groupe. |
| `admin_merge_request` | boolean | non       | Autorisation d'approuver des merge requests. |
| `admin_push_rules` | boolean | non       | Autorisation de configurer les règles de push pour les dépôts au niveau du groupe ou du projet. |
| `admin_terraform_state` | boolean | non       | Autorisation d'administrer l'état terraform du projet. |
| `admin_vulnerability` | boolean | non       | Autorisation de modifier l'objet vulnérabilité, y compris le statut et la liaison avec un ticket. |
| `admin_web_hook` | boolean | non       | Autorisation d'administrer les webhooks. |
| `archive_project` | boolean | non       | Autorisation d'archiver des projets. |
| `manage_deploy_tokens` | boolean | non       | Autorisation de gérer les jetons de déploiement. |
| `manage_group_access_tokens` | boolean | non       | Autorisation de gérer les jetons d'accès de groupe. |
| `manage_merge_request_settings` | boolean | non       | Autorisation de configurer les paramètres des merge requests. |
| `manage_project_access_tokens` | boolean | non       | Autorisation de gérer les jetons d'accès au projet. |
| `manage_security_policy_link` | boolean | non       | Autorisation de lier des projets de politique de sécurité. |
| `read_code`           | boolean | non       | Autorisation de lire le code du projet. |
| `read_runners`     | boolean | non       | Autorisation de consulter les runners de projet. |
| `read_dependency`     | boolean | non       | Autorisation de lire les dépendances du projet. |
| `read_vulnerability`  | boolean | non       | Autorisation de lire les vulnérabilités du projet. |
| `remove_group` | boolean | non       | Autorisation de supprimer ou de restaurer un groupe. |
| `remove_project` | boolean | non       | Autorisation de supprimer un projet. |

Pour plus d'informations sur les autorisations disponibles, consultez [les autorisations personnalisées](../user/custom_roles/abilities.md).

Exemple de requête :

```shell
curl --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{"name" : "Custom guest (instance)", "base_access_level" : 10, "read_code" : true}' \
  --url "https://gitlab.example.com/api/v4/member_roles"
```

Exemple de réponse :

```json
{
  "id": 3,
  "name": "Custom guest (instance)",
  "group_id": null,
  "description": null,
  "base_access_level": 10,
  "admin_cicd_variables": false,
  "admin_compliance_framework": false,
  "admin_group_member": false,
  "admin_merge_request": false,
  "admin_push_rules": false,
  "admin_terraform_state": false,
  "admin_vulnerability": false,
  "admin_web_hook": false,
  "archive_project": false,
  "manage_deploy_tokens": false,
  "manage_group_access_tokens": false,
  "manage_merge_request_settings": false,
  "manage_project_access_tokens": false,
  "manage_security_policy_link": false,
  "read_code": true,
  "read_runners": false,
  "read_dependency": false,
  "read_vulnerability": false,
  "remove_group": false,
  "remove_project": false
}
```

### Supprimer un rôle de membre d'instance {#delete-an-instance-member-role}

Supprime un rôle de membre de l'instance.

```plaintext
DELETE /member_roles/:member_role_id
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:--------|:---------|:-------------------------------------|
| `member_role_id` | entier | oui   | L'ID du rôle de membre. |

En cas de succès, renvoie [`204`](rest/troubleshooting.md#status-codes) et une réponse vide.

Exemple de requête :

```shell
curl --request DELETE \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/member_roles/1"
```

## Gérer les rôles de membre de groupe {#manage-group-member-roles}

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com

{{< /details >}}

Prérequis :

- Vous devez avoir le rôle Owner pour le groupe.

### Obtenir tous les rôles de membre de groupe {#get-all-group-member-roles}

```plaintext
GET /groups/:id/member_roles
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |

Exemple de requête :

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/84/member_roles"
```

Exemple de réponse :

```json
[
  {
    "id": 2,
    "name": "Guest + read code",
    "description": "Custom guest that can read code",
    "group_id": 84,
    "base_access_level": 10,
    "admin_cicd_variables": false,
    "admin_compliance_framework": false,
    "admin_group_member": false,
    "admin_merge_request": false,
    "admin_push_rules": false,
    "admin_terraform_state": false,
    "admin_vulnerability": false,
    "admin_web_hook": false,
    "archive_project": false,
    "manage_deploy_tokens": false,
    "manage_group_access_tokens": false,
    "manage_merge_request_settings": false,
    "manage_project_access_tokens": false,
    "manage_security_policy_link": false,
    "read_code": true,
    "read_runners": false,
    "read_dependency": false,
    "read_vulnerability": false,
    "remove_group": false,
    "remove_project": false
  },
  {
    "id": 3,
    "name": "Guest + security",
    "description": "Custom guest that can read and administer security entities",
    "group_id": 84,
    "base_access_level": 10,
    "admin_cicd_variables": false,
    "admin_compliance_framework": false,
    "admin_group_member": false,
    "admin_merge_request": false,
    "admin_push_rules": false,
    "admin_terraform_state": false,
    "admin_vulnerability": true,
    "admin_web_hook": false,
    "archive_project": false,
    "manage_deploy_tokens": false,
    "manage_group_access_tokens": false,
    "manage_merge_request_settings": false,
    "manage_project_access_tokens": false,
    "manage_security_policy_link": false,
    "read_code": true,
    "read_runners": false,
    "read_dependency": true,
    "read_vulnerability": true,
    "remove_group": false,
    "remove_project": false
  }
]
```

### Ajouter un rôle de membre à un groupe {#add-a-member-role-to-a-group}

{{< history >}}

- Possibilité d'ajouter un nom et une description lors de la création d'un rôle personnalisé [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126423) dans GitLab 16.3.

{{< /history >}}

Ajoute un rôle de membre à un groupe. Vous pouvez uniquement ajouter des rôles de membre au niveau racine du groupe.

```plaintext
POST /groups/:id/member_roles
```

Paramètres :

| Attribut | Type                | Obligatoire | Description |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | entier ou chaîne      | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `admin_cicd_variables` | boolean | non       | Autorisation de créer, lire, mettre à jour et supprimer des variables CI/CD. |
| `admin_compliance_framework` | boolean | non       | Autorisation d'administrer les frameworks de conformité. |
| `admin_group_member` | boolean | non       | Autorisation d'ajouter, de supprimer et d'assigner des membres dans un groupe. |
| `admin_merge_request` | boolean | non       | Autorisation d'approuver des merge requests. |
| `admin_push_rules` | boolean | non       | Autorisation de configurer les règles de push pour les dépôts au niveau du groupe ou du projet. |
| `admin_terraform_state` | boolean | non       | Autorisation d'administrer l'état terraform du projet. |
| `admin_vulnerability` | boolean | non       | Autorisation d'administrer les vulnérabilités du projet. |
| `admin_web_hook` | boolean | non       | Autorisation d'administrer les webhooks. |
| `archive_project` | boolean | non       | Autorisation d'archiver des projets. |
| `manage_deploy_tokens` | boolean | non       | Autorisation de gérer les jetons de déploiement. |
| `manage_group_access_tokens` | boolean | non       | Autorisation de gérer les jetons d'accès de groupe. |
| `manage_merge_request_settings` | boolean | non       | Autorisation de configurer les paramètres des merge requests. |
| `manage_project_access_tokens` | boolean | non       | Autorisation de gérer les jetons d'accès au projet. |
| `manage_security_policy_link` | boolean | non       | Autorisation de lier des projets de politique de sécurité. |
| `read_code`           | boolean | non       | Autorisation de lire le code du projet. |
| `read_runners`     | boolean | non       | Autorisation de consulter les runners de projet. |
| `read_dependency`     | boolean | non       | Autorisation de lire les dépendances du projet. |
| `read_vulnerability`  | boolean | non       | Autorisation de lire les vulnérabilités du projet. |
| `remove_group` | boolean | non       | Autorisation de supprimer ou de restaurer un groupe. |
| `remove_project` | boolean | non       | Autorisation de supprimer un projet. |

Exemple de requête :

```shell
curl --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{"name" : "Custom guest", "base_access_level" : 10, "read_code" : true}' \
  --url "https://gitlab.example.com/api/v4/groups/84/member_roles"
```

Exemple de réponse :

```json
{
  "id": 3,
  "name": "Custom guest",
  "description": null,
  "group_id": 84,
  "base_access_level": 10,
  "admin_cicd_variables": false,
  "admin_compliance_framework": false,
  "admin_group_member": false,
  "admin_merge_request": false,
  "admin_push_rules": false,
  "admin_terraform_state": false,
  "admin_vulnerability": false,
  "admin_web_hook": false,
  "archive_project": false,
  "manage_deploy_tokens": false,
  "manage_group_access_tokens": false,
  "manage_merge_request_settings": false,
  "manage_project_access_tokens": false,
  "manage_security_policy_link": false,
  "read_code": true,
  "read_runners": false,
  "read_dependency": false,
  "read_vulnerability": false,
  "remove_group": false,
  "remove_project": false
}
```

Dans GitLab 16.3 et versions ultérieures, vous pouvez utiliser l'API pour :

- Ajouter un nom (obligatoire) et une description (facultative) lorsque vous [créez un nouveau rôle personnalisé](../user/custom_roles/_index.md#create-a-custom-member-role).
- Mettre à jour le nom et la description d'un rôle personnalisé existant.

### Supprimer le rôle de membre d'un groupe {#remove-member-role-of-a-group}

Supprime un rôle de membre d'un groupe.

```plaintext
DELETE /groups/:id/member_roles/:member_role_id
```

| Attribut | Type | Obligatoire | Description |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `member_role_id` | entier | oui   | L'ID du rôle de membre. |

En cas de succès, renvoie [`204`](rest/troubleshooting.md#status-codes) et une réponse vide.

Exemple de requête :

```shell
curl --request DELETE \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/84/member_roles/1"
```
