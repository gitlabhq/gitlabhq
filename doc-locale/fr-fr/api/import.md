---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API d'importation"
description: "Importez des dépôts depuis GitHub ou Bitbucket Server avec l'API REST."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- La réattribution des contributions au propriétaire d'un espace de nommage personnel lors de l'importation vers un espace de nommage personnel a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/525342) dans GitLab 18.3 [avec un flag](../administration/feature_flags/_index.md) nommé `user_mapping_to_personal_namespace_owner`. Désactivé par défaut.
- La réattribution des contributions au propriétaire d'un espace de nommage personnel lors de l'importation vers un espace de nommage personnel est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211626) dans GitLab 18.6. L'indicateur de fonctionnalité `user_mapping_to_personal_namespace_owner` a été supprimé.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Utilisez cette API pour [importer des dépôts depuis des sources externes](../user/import/_index.md).

> [!note]
> Le mappage des contributions des utilisateurs n'est pas pris en charge lorsque vous importez des projets vers un [espace de nommage personnel](../user/namespace/_index.md#types-of-namespaces). Lorsque vous importez vers un espace de nommage personnel, toutes les contributions sont attribuées au propriétaire de l'espace de nommage personnel et ne peuvent pas être réattribuées.

## Importer un dépôt depuis GitHub {#import-repository-from-github}

{{< history >}}

- Exigence du rôle Maintainer au lieu du rôle Developer introduite dans GitLab 16.0 et rétroportée dans GitLab 15.11.1 et GitLab 15.10.5.
- La clé `collaborators_import` dans `optional_stages` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/398154) dans GitLab 16.0.
- Le feature flag `github_import_extended_events` a été introduit dans GitLab 16.8. Désactivé par défaut. Ce flag améliore les performances des importations mais désactive l'étape facultative `single_endpoint_issue_events_import`.
- Le feature flag `github_import_extended_events` a été [activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/435089) dans GitLab 16.9.
- Les performances d'importation améliorées sont [généralement disponibles](https://gitlab.com/gitlab-org/gitlab/-/issues/435089) dans GitLab 16.11. L'indicateur de fonctionnalité `github_import_extended_events` a été supprimé.

{{< /history >}}

Importe un dépôt depuis GitHub vers GitLab.

Prérequis :

- [Prérequis pour l'importateur GitHub](../user/project/import/github.md#prerequisites).
- L'espace de nommage défini dans `target_namespace` doit exister.
- L'espace de nommage peut être votre espace de nommage utilisateur ou un groupe existant pour lequel vous avez le rôle Maintainer ou Owner.

```plaintext
POST /import/github
```

| Attribut               | Type    | Obligatoire | Description |
|-------------------------|---------|----------|-------------|
| `personal_access_token` | string  | Oui      | Jeton d'accès personnel GitHub. |
| `repo_id`               | integer | Oui      | ID de dépôt GitHub. |
| `target_namespace`      | string  | Oui      | Espace de nommage dans lequel importer le dépôt. Prend en charge les sous-groupes comme `/namespace/subgroup`. Ne doit pas être vide. |
| `github_hostname`       | string  | Non       | Nom d'hôte GitHub Enterprise personnalisé. Ne pas définir pour GitHub.com. De GitLab 16.5 à GitLab 17.1, vous devez inclure le chemin `/api/v3`. |
| `new_name`              | string  | Non       | Nom du nouveau projet. Également utilisé comme nouveau chemin, il ne doit donc pas commencer ou se terminer par un caractère spécial et ne doit pas contenir de caractères spéciaux consécutifs. |
| `optional_stages`       | objet  | Non       | [Éléments supplémentaires à importer](../user/project/import/github.md#select-additional-items-to-import). |
| `pagination_limit`      | integer | Non       | Nombre d'éléments récupérés par requête API REST vers GitHub. La valeur par défaut est 100 éléments par page. Pour les importations de projets à partir de grands dépôts, un nombre inférieur peut réduire le risque que les points de terminaison de l'API GitHub retournent des erreurs `500` ou `502`. Cependant, une taille de page plus petite augmente les temps de migration. |
| `timeout_strategy`      | string  | Non       | Stratégie de gestion des délais d'expiration d'importation. Les valeurs valides sont `optimistic` (continuer vers l'étape suivante de l'importation) ou `pessimistic` (échouer immédiatement). La valeur par défaut est `pessimistic`. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/422979) dans GitLab 16.5. |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/github" \
  --header "content-type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{
    "personal_access_token": "aBc123abC12aBc123abC12abC123+_A/c123",
    "repo_id": "12345",
    "target_namespace": "group/subgroup",
    "new_name": "NEW-NAME",
    "github_hostname": "https://github.example.com",
    "optional_stages": {
      "single_endpoint_notes_import": true,
      "attachments_import": true,
      "collaborators_import": true
    }
}'
```

Les clés suivantes sont disponibles pour `optional_stages` :

- `attachments_import`, pour l'importation des pièces jointes Markdown.
- `collaborators_import`, pour l'importation des collaborateurs directs du dépôt qui ne sont pas des collaborateurs externes.
- `single_endpoint_issue_events_import`, pour l'importation des événements de tickets et de pull requests. Cette étape facultative a été supprimée dans GitLab 16.9.
- `single_endpoint_notes_import`, pour une importation de commentaires alternative et plus complète.

Pour plus d'informations, voir [sélectionner des éléments supplémentaires à importer](../user/project/import/github.md#select-additional-items-to-import).

Exemple de réponse :

```json
{
    "id": 27,
    "name": "my-repo",
    "full_path": "/root/my-repo",
    "full_name": "Administrator / my-repo",
    "refs_url": "/root/my-repo/refs",
    "import_source": "my-github/repo",
    "import_status": "scheduled",
    "human_import_status_name": "scheduled",
    "provider_link": "/my-github/repo",
    "relation_type": null,
    "import_warning": null
}
```

### Importer un projet public via l'API à l'aide d'un jeton d'accès de groupe {#import-a-public-project-through-the-api-using-a-group-access-token}

Lorsque vous importez un projet de GitHub vers GitLab via l'API à l'aide d'un jeton d'accès de groupe :

- Le projet GitLab hérite des paramètres de visibilité du projet d'origine. Par conséquent, le projet est accessible publiquement si le projet d'origine est public.
- Si `path` ou `target_namespace` n'existe pas, l'importation du projet échoue.

### Annuler l'importation d'un projet GitHub {#cancel-github-project-import}

Annule une importation de projet GitHub en cours.

```plaintext
POST /import/github/cancel
```

| Attribut    | Type    | Obligatoire | Description |
|--------------|---------|----------|-------------|
| `project_id` | integer | Oui      | ID de projet GitLab. |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/github/cancel" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{
    "project_id": 12345
}'
```

Exemple de réponse :

```json
{
    "id": 160,
    "name": "my-repo",
    "full_path": "/root/my-repo",
    "full_name": "Administrator / my-repo",
    "import_source": "source/source-repo",
    "import_status": "canceled",
    "human_import_status_name": "canceled",
    "provider_link": "/source/source-repo"
}
```

Renvoie les codes d'état suivants :

- `200 OK` : l'importation du projet est en cours d'annulation.
- `400 Bad Request` : l'importation du projet ne peut pas être annulée.
- `404 Not Found` : le projet associé à `project_id` n'existe pas.

### Importer des gists GitHub dans des snippets GitLab {#import-github-gists-into-gitlab-snippets}

Importe des gists GitHub personnels dans des snippets GitLab. Vous pouvez importer des gists comportant jusqu'à 10 fichiers. Les gists GitHub comportant plus de 10 fichiers sont ignorés. Vous devez migrer manuellement ces gists GitHub.

Si des gists n'ont pas pu être importés, un e-mail est envoyé avec la liste des gists qui n'ont pas été importés.

```plaintext
POST /import/github/gists
```

| Attribut               | Type   | Obligatoire | Description |
|-------------------------|--------|----------|-------------|
| `personal_access_token` | string | Oui      | Jeton d'accès personnel GitHub. |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/github/gists" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_gitlab_access_token>" \
  --data '{
    "personal_access_token": "<your_github_personal_access_token>"
}'
```

Renvoie les codes d'état suivants :

- `202 Accepted` : l'importation des gists est en cours de démarrage.
- `401 Unauthorized` : le jeton d'accès personnel GitHub de l'utilisateur est invalide.
- `422 Unprocessable Entity` : l'importation des gists est déjà en cours.
- `429 Too Many Requests` : l'utilisateur a dépassé la limite de débit de GitHub.

## Importer un dépôt depuis Bitbucket Server {#import-repository-from-bitbucket-server}

{{< history >}}

- La validation de `bitbucket_server_project` et de `bitbucket_server_repo` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/work_items/429234) dans GitLab 19.1.

{{< /history >}}

Importe un dépôt depuis Bitbucket Server vers GitLab.

La clé de projet Bitbucket est uniquement utilisée pour trouver le dépôt dans Bitbucket. Vous devez spécifier un `target_namespace` si vous souhaitez importer le dépôt dans un groupe GitLab. Si vous ne spécifiez pas `target_namespace`, le projet est importé dans votre espace de nommage utilisateur personnel.

Prérequis :

- Pour plus d'informations, voir [prérequis pour l'importateur Bitbucket Server](../user/import/bitbucket_server.md).

```plaintext
POST /import/bitbucket_server
```

| Attribut                   | Type   | Obligatoire | Description |
|-----------------------------|--------|----------|-------------|
| `bitbucket_server_project`  | string | Oui      | Clé de projet Bitbucket. Doit contenir uniquement des lettres, des chiffres, des tirets, des traits de soulignement, des points ou des espaces blancs. Les clés de projet personnel commencent par `~`. |
| `bitbucket_server_repo`     | string | Oui      | Nom du dépôt Bitbucket. Doit contenir uniquement des lettres, des chiffres, des tirets, des traits de soulignement, des points ou des espaces blancs. |
| `bitbucket_server_url`      | string | Oui      | URL de Bitbucket Server. |
| `bitbucket_server_username` | string | Oui      | Nom d'utilisateur Bitbucket Server. |
| `personal_access_token`     | string | Oui      | Jeton d'accès personnel ou mot de passe Bitbucket Server. |
| `new_name`                  | string | Non       | Nom du nouveau projet. Également utilisé comme nouveau chemin, il ne doit donc pas commencer ou se terminer par un caractère spécial et ne doit pas contenir de caractères spéciaux consécutifs. Dans GitLab 16.9 et versions antérieures, le chemin du projet [était copié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88845) depuis Bitbucket à la place. Dans GitLab 16.10, le comportement a été [rétabli](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145793) au comportement d'origine. |
| `target_namespace`          | string | Non       | Espace de nommage dans lequel importer le dépôt. Prend en charge les sous-groupes comme `/namespace/subgroup`. |
| `timeout_strategy`          | string | Non       | Stratégie de gestion des délais d'expiration d'importation. Les valeurs valides sont `optimistic` (continuer vers l'étape suivante de l'importation) ou `pessimistic` (échouer immédiatement). La valeur par défaut est `pessimistic`. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/422979) dans GitLab 16.5. |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/bitbucket_server" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{
    "bitbucket_server_url": "http://bitbucket.example.com",
    "bitbucket_server_username": "root",
    "personal_access_token": "Nzk4MDcxODY4MDAyOiP8y410zF3tGAyLnHRv/E0+3xYs",
    "bitbucket_server_project": "NEW",
    "bitbucket_server_repo": "my-repo",
    "new_name": "NEW-NAME"
}'
```

## Importer un dépôt depuis Bitbucket Cloud {#import-repository-from-bitbucket-cloud}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/215036) dans GitLab 17.0.
- Prise en charge des jetons d'API Bitbucket Cloud [ajoutée](https://gitlab.com/gitlab-org/gitlab/-/work_items/575583) dans GitLab 18.9.
- Prise en charge des mots de passe d'application Bitbucket Cloud [supprimée](https://gitlab.com/gitlab-org/gitlab/-/work_items/588961) dans GitLab 19.0.

{{< /history >}}

Importe un dépôt depuis Bitbucket Cloud vers GitLab.

Prérequis :

- Les [prérequis pour l'importateur Bitbucket Cloud](../user/import/bitbucket_cloud.md).
- Un [jeton d'API Bitbucket Cloud](#bitbucket-cloud-api-token-scopes) avec les portées requises.

```plaintext
POST /import/bitbucket
```

| Attribut             | Type   | Obligatoire | Description |
|:----------------------|:-------|:---------|:------------|
| `bitbucket_api_token` | string | Oui      | Jeton d'API Bitbucket Cloud. |
| `bitbucket_email`     | string | Oui      | E-mail Bitbucket Cloud. |
| `repo_path`           | string | Oui      | Chemin vers le dépôt. |
| `target_namespace`    | string | Oui      | Espace de nommage dans lequel importer le dépôt. Prend en charge les sous-groupes comme `/namespace/subgroup`. |
| `new_name`            | string | Non       | Nom du nouveau projet. Également utilisé comme nouveau chemin, il ne doit donc pas commencer ou se terminer par un caractère spécial et ne doit pas contenir de caractères spéciaux consécutifs. |

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/import/bitbucket" \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data '{
    "bitbucket_email": "email@example.com",
    "bitbucket_api_token": "your_bitbucket_api_token",
    "repo_path": "username/my_project",
    "target_namespace": "my_group/my_subgroup",
    "new_name": "new_project_name"
}'
```

### Portées du jeton d'API Bitbucket Cloud {#bitbucket-cloud-api-token-scopes}

Si vous utilisez un jeton d'API Bitbucket Cloud pour l'authentification, le jeton doit disposer des portées suivantes :

- `read:repository:bitbucket`
- `read:pullrequest:bitbucket`
- `read:issue:bitbucket`
- `read:wiki:bitbucket`

## Sujets connexes {#related-topics}

- [API de migration de groupe par transfert direct](bulk_imports.md).
- [API d'importation et d'exportation de groupe](group_import_export.md).
- [API d'importation et d'exportation de projet](project_import_export.md).
