---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des sous-modules de dépôt
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour mettre à jour les [sous-modules Git](https://git-scm.com/book/en/v2/Git-Tools-Submodules).

## Mettre à jour une référence de sous-module {#update-a-submodule-reference}

Met à jour la référence d'un sous-module. Utilisé pour certains workflows, notamment automatisés, afin de maintenir à jour d'autres projets qui l'utilisent.

```plaintext
PUT /projects/:id/repository/submodules/:submodule
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths) |
| `submodule` | string | oui | Chemin complet encodé dans l'URL vers le sous-module. Par exemple, `lib%2Fclass%2Erb` |
| `branch` | string | oui | Nom de la branche dans laquelle effectuer le commit |
| `commit_sha` | string | oui | SHA de commit complet vers lequel mettre à jour le sous-module |
| `commit_message` | string | non | Message de commit. Si aucun message n'est fourni, un message par défaut est défini |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/submodules/lib%2Fmodules%2Fexample" \
  --data "branch=main" \
  --data "commit_sha=3ddec28ea23acc5caa5d8331a6ecb2a65fc03e88" \
  --data "commit_message=Update submodule reference"
```

Exemple de réponse :

```json
{
  "id": "ed899a2f4b50b4370feeea94676502b42383c746",
  "short_id": "ed899a2f4b5",
  "title": "Updated submodule example_submodule with oid 3ddec28ea23acc5caa5d8331a6ecb2a65fc03e88",
  "author_name": "Dmitriy Zaporozhets",
  "author_email": "dzaporozhets@sphereconsultinginc.com",
  "committer_name": "Dmitriy Zaporozhets",
  "committer_email": "dzaporozhets@sphereconsultinginc.com",
  "created_at": "2018-09-20T09:26:24.000-07:00",
  "message": "Updated submodule example_submodule with oid 3ddec28ea23acc5caa5d8331a6ecb2a65fc03e88",
  "parent_ids": [
    "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
  ],
  "committed_date": "2018-09-20T09:26:24.000-07:00",
  "authored_date": "2018-09-20T09:26:24.000-07:00",
  "status": null
}
```
