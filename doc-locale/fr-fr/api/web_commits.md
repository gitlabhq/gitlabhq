---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Web Commits
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/442533) dans GitLab 17.4.

{{< /history >}}

Utilisez cette API pour récupérer des informations sur les [commits web](../user/project/repository/web_editor.md).

## Récupérer la clé de signature publique {#retrieve-public-signing-key}

Récupère la clé publique GitLab pour la signature des commits web.

```plaintext
GET /web_commits/public_key
```

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut    | Type   | Description                                |
|--------------|--------|--------------------------------------------|
| `public_key` | string | Clé publique GitLab pour la signature des commits web. |

Exemple de requête :

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/web_commits/public_key"
```

Exemple de réponse :

```json
[
  {
    "public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="
  }
]
```
