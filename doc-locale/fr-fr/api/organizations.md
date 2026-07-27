---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des organisations
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : Expérience

{{< /details >}}

Utilisez cette API pour interagir avec les organisations GitLab. Pour plus d'informations, consultez [organization](../user/organization/_index.md).

## Créer une organisation {#create-an-organization}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/470613) dans GitLab 17.5 avec un [feature flag](../administration/feature_flags/_index.md) nommé `allow_organization_creation`. Désactivé par défaut. Cette fonctionnalité est une [expérimentation](../policy/development_stages_support.md).
- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/549062) dans GitLab 18.4. Le feature flag `allow_organization_creation` a été consolidé et renommé en `organization_switching`.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Crée une organisation.

Ce point de terminaison est une [expérience](../policy/development_stages_support.md) et peut être modifié ou supprimé sans préavis.

```plaintext
POST /organizations
```

Paramètres :

| Attribut     | Type   | Obligatoire | Description                           |
|---------------|--------|----------|---------------------------------------|
| `name`        | string | oui      | Le nom de l'organisation          |
| `path`        | string | oui      | Le chemin de l'organisation          |
| `description` | string | non       | La description de l'organisation   |
| `avatar`      | file   | non       | L'image d'avatar de l'organisation |

Exemple de requête :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
--form "name=New Organization" \
--form "path=new-org" \
--form "description=A new organization" \
--form "avatar=@/path/to/avatar.png" \
"https://gitlab.example.com/api/v4/organizations"
```

Exemple de réponse :

```json
{
  "id": 42,
  "name": "New Organization",
  "path": "new-org",
  "description": "A new organization",
  "created_at": "2024-09-18T02:35:15.371Z",
  "updated_at": "2024-09-18T02:35:15.371Z",
  "web_url": "https://gitlab.example.com/o/new-org/-/overview",
  "avatar_url": "https://gitlab.example.com/uploads/-/system/organizations/organization_detail/avatar/42/avatar.png"
}
```
