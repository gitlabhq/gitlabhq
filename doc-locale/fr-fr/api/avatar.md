---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Avatar
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les avatars des utilisateurs.

## Récupérer l'avatar d'un compte utilisateur {#retrieve-user-account-avatar}

Récupère l'URL de l'[avatar](../user/profile/_index.md#access-your-user-settings) d'un compte utilisateur associé à une adresse e-mail publique spécifiée. Ce point de terminaison ne nécessite pas d'authentification.

- En cas de succès, renvoie l'URL de l'avatar.
- Si aucun compte n'est associé à l'adresse e-mail donnée, renvoie les résultats des services d'avatar externes.
- Si la visibilité publique est restreinte et que la requête n'est pas authentifiée, renvoie `403 Forbidden`.

```plaintext
GET /avatar?email=admin@example.com
```

Paramètres :

| Attribut | Type    | Obligatoire | Description |
| --------- | ------- | -------- | ----------- |
| `email`   | string  | oui      | Adresse e-mail publique du compte. |
| `size`    | entier | non       | Dimension en pixel unique. Utilisé uniquement pour les recherches d'avatar sur `Gravatar` ou un serveur `Libravatar` configuré. |

Exemple de requête :

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/avatar?email=admin@example.com&size=32"
```

Exemple de réponse :

```json
{
  "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=64&d=identicon"
}
```

## Sujets connexes {#related-topics}

- [Téléverser un avatar pour vous-même](users.md#upload-an-avatar-for-yourself).
- [Téléverser un avatar de projet](projects.md#upload-a-project-avatar).
