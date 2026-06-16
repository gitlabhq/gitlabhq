---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des règles push de projet
description: "Gérez les règles push de projet pour appliquer des normes de commit, valider les messages, empêcher les secrets et contrôler les opérations du dépôt."
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [règles push](../user/project/repository/push_rules.md) du projet.

> [!note]
> GitLab utilise la [syntaxe RE2](https://github.com/google/re2/wiki/Syntax) pour toutes les expressions régulières dans les règles push.

## Récupérer les règles push d'un projet {#retrieve-the-push-rules-of-a-project}

Récupère les règles push d'un projet spécifié.

```plaintext
GET /projects/:id/push_rule
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                       | Type    | Description |
|---------------------------------|---------|-------------|
| `author_email_regex`            | string  | Tous les e-mails des auteurs de commit doivent correspondre à cette expression régulière. |
| `branch_name_regex`             | string  | Tous les noms de branche doivent correspondre à cette expression régulière. |
| `commit_committer_check`        | boolean | Si `true`, les utilisateurs ne peuvent pousser des commits vers ce dépôt que si l'e-mail du committer est l'un de leurs e-mails vérifiés. |
| `commit_committer_name_check`   | boolean | Si `true`, les utilisateurs ne peuvent pousser des commits vers ce dépôt que si le nom de l'auteur du commit est cohérent avec leur nom de compte GitLab. |
| `commit_message_negative_regex` | string  | Aucun message de commit ne peut correspondre à cette expression régulière. |
| `commit_message_regex`          | string  | Tous les messages de commit doivent correspondre à cette expression régulière. |
| `created_at`                    | string  | Date et heure de création de la règle push. |
| `deny_delete_tag`               | boolean | Si `true`, interdit la suppression d'un tag. |
| `file_name_regex`               | string  | Tous les noms de fichiers committés ne doivent pas correspondre à cette expression régulière. |
| `id`                            | entier | ID de la règle push. |
| `max_file_size`                 | entier | Taille maximale du fichier (Mo). |
| `member_check`                  | boolean | Si `true`, restreint les commits par auteur (e-mail) aux utilisateurs GitLab existants. |
| `prevent_secrets`               | boolean | Si `true`, GitLab rejette tout fichier susceptible de contenir des secrets. |
| `project_id`                    | entier | ID du projet. |
| `reject_non_dco_commits`        | boolean | Si `true`, rejette les commits non certifiés DCO. |
| `reject_unsigned_commits`       | boolean | Si `true`, rejette les commits non signés. |

Si aucune règle push n'a jamais été configurée pour le projet, retourne HTTP `200 OK` avec la chaîne littérale `"null"` comme corps de réponse.

> [!note]
> Ceci diffère de l'[API des règles push de groupe](group_push_rules.md#retrieve-the-push-rules-of-a-group), qui retourne une erreur `404 Not Found`.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule"
```

Exemple de réponse lorsque les règles push sont configurées avec tous les paramètres désactivés :

```json
{
  "id": 1,
  "project_id": 3,
  "created_at": "2012-10-12T17:04:47Z",
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "ssh\\:\\/\\/",
  "branch_name_regex": "",
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 0,
  "commit_committer_check": null,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": null,
  "reject_non_dco_commits": null
}
```

Si les attributs suivants sont désactivés, ils retournent `null` au lieu de `false` :

- `commit_committer_check`
- `reject_unsigned_commits`
- `reject_non_dco_commits`

Exemple de réponse lorsque les règles push n'ont jamais été configurées pour le projet :

```plaintext
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 4

null
```

Ceci retourne la chaîne littérale `"null"` (4 caractères), et non une valeur JSON `null`.

## Ajouter des règles push à un projet {#add-push-rules-to-a-project}

Ajoute des règles push au projet spécifié.

```plaintext
POST /projects/:id/push_rule
```

Attributs pris en charge :

| Attribut                       | Type              | Obligatoire | Description |
|---------------------------------|-------------------|----------|-------------|
| `id`                            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `author_email_regex`            | string            | Non       | Tous les e-mails des auteurs de commit doivent correspondre à cette expression régulière. |
| `branch_name_regex`             | string            | Non       | Tous les noms de branche doivent correspondre à cette expression régulière. |
| `commit_committer_check`        | boolean           | Non       | Si `true`, les utilisateurs ne peuvent pousser des commits vers ce dépôt que si l'e-mail du committer est l'un de leurs e-mails vérifiés. |
| `commit_committer_name_check`   | boolean           | Non       | Si `true`, les utilisateurs ne peuvent pousser des commits vers ce dépôt que si le nom de l'auteur du commit est cohérent avec leur nom de compte GitLab. |
| `commit_message_negative_regex` | string            | Non       | Aucun message de commit ne peut correspondre à cette expression régulière. |
| `commit_message_regex`          | string            | Non       | Tous les messages de commit doivent correspondre à cette expression régulière. |
| `deny_delete_tag`               | boolean           | Non       | Si `true`, interdit la suppression d'un tag. |
| `file_name_regex`               | string            | Non       | Tous les noms de fichiers committés ne doivent pas correspondre à cette expression régulière. |
| `max_file_size`                 | entier           | Non       | Taille maximale du fichier (Mo). |
| `member_check`                  | boolean           | Non       | Si `true`, restreint les commits par auteur (e-mail) aux utilisateurs GitLab existants. |
| `prevent_secrets`               | boolean           | Non       | Si `true`, GitLab rejette tout fichier susceptible de contenir des secrets. |
| `reject_non_dco_commits`        | boolean           | Non       | Si `true`, rejette les commits non certifiés DCO. |
| `reject_unsigned_commits`       | boolean           | Non       | Si `true`, rejette les commits non signés. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                       | Type    | Description |
|---------------------------------|---------|-------------|
| `author_email_regex`            | string  | Tous les e-mails des auteurs de commit doivent correspondre à cette expression régulière. |
| `branch_name_regex`             | string  | Tous les noms de branche doivent correspondre à cette expression régulière. |
| `commit_committer_check`        | boolean | Si `true`, les utilisateurs ne peuvent pousser des commits vers ce dépôt que si l'e-mail du committer est l'un de leurs e-mails vérifiés. |
| `commit_committer_name_check`   | boolean | Si `true`, les utilisateurs ne peuvent pousser des commits vers ce dépôt que si le nom de l'auteur du commit est cohérent avec leur nom de compte GitLab. |
| `commit_message_negative_regex` | string  | Aucun message de commit ne peut correspondre à cette expression régulière. |
| `commit_message_regex`          | string  | Tous les messages de commit doivent correspondre à cette expression régulière. |
| `created_at`                    | string  | Date et heure de création de la règle push. |
| `deny_delete_tag`               | boolean | Si `true`, interdit la suppression d'un tag. |
| `file_name_regex`               | string  | Tous les noms de fichiers committés ne doivent pas correspondre à cette expression régulière. |
| `id`                            | entier | ID de la règle push. |
| `max_file_size`                 | entier | Taille maximale du fichier (Mo). |
| `member_check`                  | boolean | Si `true`, restreint les commits par auteur (e-mail) aux utilisateurs GitLab existants. |
| `prevent_secrets`               | boolean | Si `true`, GitLab rejette tout fichier susceptible de contenir des secrets. |
| `project_id`                    | entier | ID du projet. |
| `reject_non_dco_commits`        | boolean | Si `true`, rejette les commits non certifiés DCO. |
| `reject_unsigned_commits`       | boolean | Si `true`, rejette les commits non signés. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule" \
  --data "commit_message_regex=Fixes \\d+\\..*" \
  --data "deny_delete_tag=false"
```

Exemple de réponse :

```json
{
  "id": 1,
  "project_id": 3,
  "created_at": "2012-10-12T17:04:47Z",
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "",
  "branch_name_regex": "",
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 0,
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false
}
```

## Mettre à jour les règles push d'un projet {#update-push-rules-of-a-project}

Met à jour les règles push pour le projet spécifié.

```plaintext
PUT /projects/:id/push_rule
```

Attributs pris en charge :

| Attribut                       | Type              | Obligatoire | Description |
|---------------------------------|-------------------|----------|-------------|
| `id`                            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `author_email_regex`            | string            | Non       | Tous les e-mails des auteurs de commit doivent correspondre à cette expression régulière. |
| `branch_name_regex`             | string            | Non       | Tous les noms de branche doivent correspondre à cette expression régulière. |
| `commit_committer_check`        | boolean           | Non       | Si `true`, les utilisateurs ne peuvent pousser des commits vers ce dépôt que si l'e-mail du committer est l'un de leurs e-mails vérifiés. |
| `commit_committer_name_check`   | boolean           | Non       | Si `true`, les utilisateurs ne peuvent pousser des commits vers ce dépôt que si le nom de l'auteur du commit est cohérent avec leur nom de compte GitLab. |
| `commit_message_negative_regex` | string            | Non       | Aucun message de commit ne peut correspondre à cette expression régulière. |
| `commit_message_regex`          | string            | Non       | Tous les messages de commit doivent correspondre à cette expression régulière. |
| `deny_delete_tag`               | boolean           | Non       | Si `true`, interdit la suppression d'un tag. |
| `file_name_regex`               | string            | Non       | Tous les noms de fichiers committés ne doivent pas correspondre à cette expression régulière. |
| `max_file_size`                 | entier           | Non       | Taille maximale du fichier (Mo). |
| `member_check`                  | boolean           | Non       | Si `true`, restreint les commits par auteur (e-mail) aux utilisateurs GitLab existants. |
| `prevent_secrets`               | boolean           | Non       | Si `true`, GitLab rejette tout fichier susceptible de contenir des secrets. |
| `reject_non_dco_commits`        | boolean           | Non       | Si `true`, rejette les commits non certifiés DCO. |
| `reject_unsigned_commits`       | boolean           | Non       | Si `true`, rejette les commits non signés. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                       | Type    | Description |
|---------------------------------|---------|-------------|
| `author_email_regex`            | string  | Tous les e-mails des auteurs de commit doivent correspondre à cette expression régulière. |
| `branch_name_regex`             | string  | Tous les noms de branche doivent correspondre à cette expression régulière. |
| `commit_committer_check`        | boolean | Si `true`, les utilisateurs ne peuvent pousser des commits vers ce dépôt que si l'e-mail du committer est l'un de leurs e-mails vérifiés. |
| `commit_committer_name_check`   | boolean | Si `true`, les utilisateurs ne peuvent pousser des commits vers ce dépôt que si le nom de l'auteur du commit est cohérent avec leur nom de compte GitLab. |
| `commit_message_negative_regex` | string  | Aucun message de commit ne peut correspondre à cette expression régulière. |
| `commit_message_regex`          | string  | Tous les messages de commit doivent correspondre à cette expression régulière. |
| `created_at`                    | string  | Date et heure de création de la règle push. |
| `deny_delete_tag`               | boolean | Si `true`, interdit la suppression d'un tag. |
| `file_name_regex`               | string  | Tous les noms de fichiers committés ne doivent pas correspondre à cette expression régulière. |
| `id`                            | entier | ID de la règle push. |
| `max_file_size`                 | entier | Taille maximale du fichier (Mo). |
| `member_check`                  | boolean | Si `true`, restreint les commits par auteur (e-mail) aux utilisateurs GitLab existants. |
| `prevent_secrets`               | boolean | Si `true`, GitLab rejette tout fichier susceptible de contenir des secrets. |
| `project_id`                    | entier | ID du projet. |
| `reject_non_dco_commits`        | boolean | Si `true`, rejette les commits non certifiés DCO. |
| `reject_unsigned_commits`       | boolean | Si `true`, rejette les commits non signés. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule" \
  --data "commit_message_regex=Fixes \\d+\\..*" \
  --data "deny_delete_tag=true"
```

Exemple de réponse :

```json
{
  "id": 1,
  "project_id": 3,
  "created_at": "2012-10-12T17:04:47Z",
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "",
  "branch_name_regex": "",
  "deny_delete_tag": true,
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 0,
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false
}
```

## Supprimer les règles push d'un projet {#delete-the-push-rules-of-a-project}

Supprime toutes les règles push d'un projet spécifié.

```plaintext
DELETE /projects/:id/push_rule
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

En cas de succès, retourne [`204 No Content`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule"
```
