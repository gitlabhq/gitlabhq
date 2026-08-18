---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des paramètres de sécurité de projet
description: "Points de terminaison d'API pour lister et mettre à jour les options de sécurité du projet, comme la protection push contre les secrets."
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Chaque appel d'API aux paramètres de sécurité du projet doit être [authentifié](rest/authentication.md).

Si un projet est privé et qu'un utilisateur n'est pas membre du projet auquel appartient le paramètre de sécurité, les requêtes adressées à ce projet renvoient un code de statut `404 Not Found`.

## Lister tous les paramètres de sécurité du projet {#list-all-project-security-settings}

Répertorie tous les paramètres de sécurité du projet.

Prérequis :

- Vous devez disposer du rôle Responsable sécurité, Developer, Maintainer ou Owner pour le projet.

```plaintext
GET /projects/:id/security_settings
```

| Attribut     | Type           | Obligatoire | Description                                                                                                                                                                 |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).                                                            |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/security_settings"
```

Exemple de réponse :

```json
{
    "project_id": 7,
    "created_at": "2024-08-27T15:30:33.075Z",
    "updated_at": "2024-10-16T05:09:22.233Z",
    "auto_fix_container_scanning": true,
    "auto_fix_dast": true,
    "auto_fix_dependency_scanning": true,
    "auto_fix_sast": true,
    "continuous_vulnerability_scans_enabled": true,
    "container_scanning_for_registry_enabled": false,
    "secret_push_protection_enabled": true
}
```

## Mettre à jour le paramètre `secret_push_protection_enabled` {#update-the-secret_push_protection_enabled-setting}

{{< history >}}

- [Renommé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185310) depuis `pre_receive_secret_detection_enabled` dans GitLab 17.11.

{{< /history >}}

Met à jour le paramètre `secret_push_protection_enabled` pour le projet spécifié.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

```plaintext
PUT /projects/:id/security_settings
```

| Attribut                        | Type              | Obligatoire | Description |
| -------------------------------- | ----------------- | -------- | ----------- |
| `id`                             | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un projet. |
| `secret_push_protection_enabled` | boolean           | Oui      | Active la protection push contre les secrets pour le projet. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "secret_push_protection_enabled=false" \
  --url "https://gitlab.example.com/api/v4/projects/7/security_settings"
```

Exemple de réponse :

```json
{
    "project_id": 7,
    "created_at": "2024-08-27T15:30:33.075Z",
    "updated_at": "2024-10-16T05:09:22.233Z",
    "auto_fix_container_scanning": true,
    "auto_fix_dast": true,
    "auto_fix_dependency_scanning": true,
    "auto_fix_sast": true,
    "continuous_vulnerability_scans_enabled": true,
    "container_scanning_for_registry_enabled": false,
    "secret_push_protection_enabled": false
}
```
