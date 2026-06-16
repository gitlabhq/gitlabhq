---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez des règles push pour contrôler le contenu et le format des commits Git que votre dépôt accepte. Définissez des standards pour les messages de commit et bloquez les secrets ou les identifiants pour éviter qu'ils soient ajoutés accidentellement."
title: API des règles push de groupe
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [règles push de groupe](../user/project/repository/push_rules.md#group-push-rules) pour les projets nouvellement créés dans un groupe.

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe ou être administrateur de l'instance.

## Récupérer les règles push d'un groupe {#retrieve-the-push-rules-of-a-group}

Récupère les règles push d'un groupe spécifié.

```plaintext
GET /groups/:id/push_rule
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID du groupe ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                         | Type    | Description |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | string  | Autorise uniquement les e-mails d'auteur de commit correspondant à cette expression régulière. |
| `branch_name_regex`               | string  | Autorise uniquement les noms de branche correspondant à cette expression régulière. |
| `commit_committer_check`          | boolean | Si `true`, autorise les commits des utilisateurs uniquement si l'e-mail du committer est l'un de leurs e-mails vérifiés. |
| `commit_committer_name_check`     | boolean | Si `true`, autorise les commits des utilisateurs uniquement si le nom de l'auteur du commit est cohérent avec leur nom de compte GitLab. |
| `commit_message_negative_regex`   | string  | Rejette les messages de commit correspondant à cette expression régulière. |
| `commit_message_regex`            | string  | Autorise uniquement les messages de commit correspondant à cette expression régulière. |
| `created_at`                      | string  | Date et heure de création de la règle push. |
| `deny_delete_tag`                 | boolean | Si `true`, interdit la suppression d'un tag. |
| `file_name_regex`                 | string  | Rejette les noms de fichiers correspondant à cette expression régulière. |
| `id`                              | entier | L'ID de la règle push. |
| `max_file_size`                   | entier | Taille de fichier maximale (Mo) autorisée. |
| `member_check`                    | boolean | Si `true`, autorise uniquement les utilisateurs GitLab à être auteurs de commits. |
| `prevent_secrets`                 | boolean | Si `true`, rejette les fichiers susceptibles de contenir des secrets. |
| `reject_non_dco_commits`          | boolean | Si `true`, rejette un commit lorsqu'il n'est pas certifié DCO. |
| `reject_unsigned_commits`         | boolean | Si `true`, rejette un commit lorsqu'il n'est pas signé. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/2/push_rule"
```

Exemple de réponse lorsque les règles push sont configurées avec tous les paramètres désactivés :

```json
{
  "id": 1,
  "created_at": "2020-08-17T19:09:19.580Z",
  "commit_message_regex": "[a-zA-Z]",
  "commit_message_negative_regex": "[x+]",
  "branch_name_regex": "[a-z]",
  "author_email_regex": "^[A-Za-z0-9.]+@gitlab.com$",
  "file_name_regex": "(exe)$",
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": false,
  "max_file_size": 0,
  "commit_committer_check": null,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": null,
  "reject_non_dco_commits": null
}
```

Si des règles push n'ont jamais été configurées pour le groupe, renvoie [`404 Not Found`](rest/troubleshooting.md#status-codes) :

```json
{
  "message": "404 Not Found"
}
```

> [!note]
> Cela diffère de l'[API des règles push de projet](project_push_rules.md#retrieve-the-push-rules-of-a-project), qui renvoie HTTP `200 OK` avec la chaîne littérale `"null"` lorsqu'aucune règle push n'est configurée.

Lorsqu'ils sont désactivés, certains attributs booléens renvoient `null` au lieu de `false`. Par exemple :

- `commit_committer_check`
- `reject_unsigned_commits`
- `reject_non_dco_commits`

## Ajouter des règles push à un groupe {#add-push-rules-to-a-group}

Ajoute des règles push au groupe spécifié. À utiliser uniquement si vous n'avez pas encore défini de règles push.

```plaintext
POST /groups/:id/push_rule
```

Attributs pris en charge :

| Attribut                         | Type           | Obligatoire | Description |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | entier ou chaîne | Oui   | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `author_email_regex`              | string         | Non       | Autorise uniquement les e-mails d'auteur de commit correspondant à l'expression régulière fournie dans cet attribut, par exemple, `@my-company.com$`. |
| `branch_name_regex`               | string         | Non       | Autorise uniquement les noms de branche correspondant à l'expression régulière fournie dans cet attribut, par exemple, `(feature\|hotfix)\/.*`. |
| `commit_committer_check`          | boolean        | Non       | Si `true`, autorise les commits des utilisateurs uniquement si l'e-mail du committer est l'un de leurs e-mails vérifiés. |
| `commit_committer_name_check`     | boolean        | Non       | Si `true`, autorise les commits des utilisateurs uniquement si le nom de l'auteur du commit est cohérent avec leur nom de compte GitLab. |
| `commit_message_negative_regex`   | string         | Non       | Rejette les messages de commit correspondant à l'expression régulière fournie dans cet attribut, par exemple, `ssh\:\/\/`. |
| `commit_message_regex`            | string         | Non       | Si `true`, autorise uniquement les messages de commit correspondant à l'expression régulière fournie dans cet attribut, par exemple, `Fixed \d+\..*`. |
| `deny_delete_tag`                 | boolean        | Non       | Interdit la suppression d'un tag. |
| `file_name_regex`                 | string         | Non       | Rejette les noms de fichiers correspondant à l'expression régulière fournie dans cet attribut, par exemple, `(jar\|exe)$`. |
| `max_file_size`                   | entier        | Non       | Taille de fichier maximale (Mo) autorisée. |
| `member_check`                    | boolean        | Non       | Si `true`, autorise uniquement les utilisateurs GitLab à être auteurs de commits. |
| `prevent_secrets`                 | boolean        | Non       | Si `true`, rejette les fichiers susceptibles de [contenir des secrets](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml). |
| `reject_non_dco_commits`          | boolean        | Non       | Si `true`, rejette un commit lorsqu'il n'est pas certifié DCO. |
| `reject_unsigned_commits`         | boolean        | Non       | Si `true`, rejette un commit lorsqu'il n'est pas signé. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                         | Type    | Description |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | string  | Autorise uniquement les e-mails d'auteur de commit correspondant à cette expression régulière. |
| `branch_name_regex`               | string  | Autorise uniquement les noms de branche correspondant à cette expression régulière. |
| `commit_committer_check`          | boolean | Si `true`, autorise les commits des utilisateurs uniquement si l'e-mail du committer est l'un de leurs e-mails vérifiés. |
| `commit_committer_name_check`     | boolean | Si `true`, autorise les commits des utilisateurs uniquement si le nom de l'auteur du commit est cohérent avec leur nom de compte GitLab. |
| `commit_message_negative_regex`   | string  | Rejette les messages de commit correspondant à cette expression régulière. |
| `commit_message_regex`            | string  | Si `true`, autorise uniquement les messages de commit correspondant à cette expression régulière. |
| `created_at`                      | string  | Date et heure de création de la règle push. |
| `deny_delete_tag`                 | boolean | Si `true`, interdit la suppression d'un tag. |
| `file_name_regex`                 | string  | Rejette les noms de fichiers correspondant à cette expression régulière. |
| `id`                              | entier | L'ID de la règle push. |
| `max_file_size`                   | entier | Taille de fichier maximale (Mo) autorisée. |
| `member_check`                    | boolean | Si `true`, autorise uniquement les utilisateurs GitLab à être auteurs de commits. |
| `prevent_secrets`                 | boolean | Si `true`, rejette les fichiers susceptibles de contenir des secrets. |
| `reject_non_dco_commits`          | boolean | Si `true`, rejette un commit lorsqu'il n'est pas certifié DCO. |
| `reject_unsigned_commits`         | boolean | Si `true`, rejette un commit lorsqu'il n'est pas signé. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/19/push_rule?prevent_secrets=true"
```

Exemple de réponse :

```json
{
  "id": 1,
  "created_at": "2020-08-31T15:53:00.073Z",
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false,
  "commit_message_regex": "[a-zA-Z]",
  "commit_message_negative_regex": "[x+]",
  "branch_name_regex": null,
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": true,
  "author_email_regex": "^[A-Za-z0-9.]+@gitlab.com$",
  "file_name_regex": null,
  "max_file_size": 100
}
```

## Mettre à jour les règles push d'un groupe {#update-push-rules-of-a-group}

Met à jour les règles push pour le groupe spécifié.

```plaintext
PUT /groups/:id/push_rule
```

Attributs pris en charge :

| Attribut                         | Type           | Obligatoire | Description |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | entier ou chaîne | Oui   | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `author_email_regex`              | string         | Non       | Autorise uniquement les e-mails d'auteur de commit correspondant à l'expression régulière fournie dans cet attribut, par exemple, `@my-company.com$`. |
| `branch_name_regex`               | string         | Non       | Autorise uniquement les noms de branche correspondant à l'expression régulière fournie dans cet attribut, par exemple, `(feature\|hotfix)\/.*`. |
| `commit_committer_check`          | boolean        | Non       | Si `true`, autorise les commits des utilisateurs uniquement si l'e-mail du committer est l'un de leurs e-mails vérifiés. |
| `commit_committer_name_check`     | boolean        | Non       | Si `true`, autorise les commits des utilisateurs uniquement si le nom de l'auteur du commit est cohérent avec leur nom de compte GitLab. |
| `commit_message_negative_regex`   | string         | Non       | Rejette les messages de commit correspondant à l'expression régulière fournie dans cet attribut, par exemple, `ssh\:\/\/`. |
| `commit_message_regex`            | string         | Non       | Si `true`, autorise uniquement les messages de commit correspondant à l'expression régulière fournie dans cet attribut, par exemple, `Fixed \d+\..*`. |
| `deny_delete_tag`                 | boolean        | Non       | Si `true`, interdit la suppression d'un tag. |
| `file_name_regex`                 | string         | Non       | Rejette les noms de fichiers correspondant à l'expression régulière fournie dans cet attribut, par exemple, `(jar\|exe)$`. |
| `max_file_size`                   | entier        | Non       | Taille de fichier maximale (Mo) autorisée. |
| `member_check`                    | boolean        | Non       | Si `true`, autorise uniquement les utilisateurs GitLab à être auteurs de commits. |
| `prevent_secrets`                 | boolean        | Non       | Si `true`, rejette les fichiers susceptibles de [contenir des secrets](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml). |
| `reject_non_dco_commits`          | boolean        | Non       | Si `true`, rejette un commit lorsqu'il n'est pas certifié DCO. |
| `reject_unsigned_commits`         | boolean        | Non       | Si `true`, rejette un commit lorsqu'il n'est pas signé. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                         | Type    | Description |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | string  | Autorise uniquement les e-mails d'auteur de commit correspondant à cette expression régulière. |
| `branch_name_regex`               | string  | Autorise uniquement les noms de branche correspondant à cette expression régulière. |
| `commit_committer_check`          | boolean | Si `true`, autorise les commits des utilisateurs uniquement si l'e-mail du committer est l'un de leurs e-mails vérifiés. |
| `commit_committer_name_check`     | boolean | Si `true`, autorise les commits des utilisateurs uniquement si le nom de l'auteur du commit est cohérent avec leur nom de compte GitLab. |
| `commit_message_negative_regex`   | string  | Rejette les messages de commit correspondant à cette expression régulière. |
| `commit_message_regex`            | string  | Si `true`, autorise uniquement les messages de commit correspondant à cette expression régulière. |
| `created_at`                      | string  | Date et heure de création de la règle push. |
| `deny_delete_tag`                 | boolean | Si `true`, interdit la suppression d'un tag. |
| `file_name_regex`                 | string  | Rejette les noms de fichiers correspondant à cette expression régulière. |
| `id`                              | entier | L'ID de la règle push. |
| `max_file_size`                   | entier | Taille de fichier maximale (Mo) autorisée. |
| `member_check`                    | boolean | Si `true`, autorise uniquement les utilisateurs GitLab à être auteurs de commits. |
| `prevent_secrets`                 | boolean | Si `true`, rejette les fichiers susceptibles de contenir des secrets. |
| `reject_non_dco_commits`          | boolean | Si `true`, rejette un commit lorsqu'il n'est pas certifié DCO. |
| `reject_unsigned_commits`         | boolean | Si `true`, rejette un commit lorsqu'il n'est pas signé. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/19/push_rule?member_check=true"
```

Exemple de réponse :

```json
{
  "id": 19,
  "created_at": "2020-08-31T15:53:00.073Z",
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false,
  "commit_message_regex": "[a-zA-Z]",
  "commit_message_negative_regex": "[x+]",
  "branch_name_regex": null,
  "deny_delete_tag": false,
  "member_check": true,
  "prevent_secrets": false,
  "author_email_regex": "^[A-Za-z0-9.]+@staging.gitlab.com$",
  "file_name_regex": null,
  "max_file_size": 100
}
```

## Supprimer les règles push d'un groupe {#delete-the-push-rules-of-a-group}

Supprime toutes les règles push d'un groupe spécifié.

```plaintext
DELETE /groups/:id/push_rule
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

En cas de succès, renvoie [`204 No Content`](rest/troubleshooting.md#status-codes) sans corps de réponse.

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/19/push_rule"
```
