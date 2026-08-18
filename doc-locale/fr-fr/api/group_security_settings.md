---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Mettre à jour les paramètres de sécurité de groupe dans GitLab. Configurez la protection push des secrets et d'autres politiques de sécurité pour tous les projets d'un groupe."
title: API des paramètres de sécurité de groupe
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/502827) dans GitLab 17.7.

{{< /history >}}

Chaque appel API aux paramètres de sécurité de groupe doit être [authentifié](rest/authentication.md).

Si un utilisateur n'est pas membre d'un groupe privé, les requêtes vers ce groupe privé renvoient un code de statut `404 Not Found`.

## Mettre à jour les paramètres de sécurité de groupe {#update-group-security-settings}

Met à jour les paramètres de sécurité de groupe pour un groupe spécifié.

Prérequis :

- Vous devez avoir le rôle Responsable sécurité, Maintainer ou Owner pour le groupe.

```plaintext
PUT /groups/:id/security_settings
```

| Attribut                        | Type              | Obligatoire | Description |
| -------------------------------- | ----------------- | -------- | ----------- |
| `id`                             | entier ou chaîne de caractères | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un groupe. |
| `secret_push_protection_enabled` | boolean           | Oui      | Active la protection push des secrets pour les projets du groupe. |
| `projects_to_exclude`            | tableau d'entiers | Non       | ID des projets à exclure de la protection push des secrets. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/7/security_settings?secret_push_protection_enabled=true&projects_to_exclude[]=1&projects_to_exclude[]=2"
```

Exemple de réponse :

```json
{
  "secret_push_protection_enabled": true,
  "errors": []
}
```
