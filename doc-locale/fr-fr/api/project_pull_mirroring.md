---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API de mise en miroir pull
description: "Gérez la mise en miroir pull pour les projets. Affichez les détails du miroir, configurez les paramètres de mise en miroir et démarrez les mises à jour du miroir."
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer la [mise en miroir pull](../user/project/repository/mirror/pull.md) des projets.

## Récupérer les détails du miroir pull d'un projet {#retrieve-project-pull-mirror-details}

{{< history >}}

- [Réponse étendue](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168377) pour inclure les informations de configuration du miroir dans GitLab 17.5. Les paramètres de configuration suivants sont inclus : `enabled`, `mirror_trigger_builds`, `only_mirror_protected_branches`, `mirror_overwrites_diverged_branches` et `mirror_branch_regex`.

{{< /history >}}

Récupère les détails du miroir pull pour un projet spécifié.

```plaintext
GET /projects/:id/mirror/pull
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                             | Type            | Description |
|---------------------------------------|-----------------|-------------|
| `enabled`                             | boolean         | Si `true`, le miroir est actif. |
| `id`                                  | entier         | Identifiant unique de la configuration du miroir. |
| `last_error`                          | chaîne ou null  | Message d'erreur le plus récent, le cas échéant. `null` si aucune erreur ne s'est produite. |
| `last_successful_update_at`           | string          | Horodatage de la dernière mise à jour réussie du miroir. |
| `last_update_at`                      | string          | Horodatage de la tentative de mise à jour du miroir la plus récente. |
| `last_update_started_at`              | string          | Horodatage du démarrage du dernier processus de mise à jour du miroir. |
| `mirror_branch_regex`                 | chaîne ou null  | Modèle d'expression régulière pour filtrer les branches à mettre en miroir. `null` si non défini. |
| `mirror_overwrites_diverged_branches` | boolean         | Si `true`, écrase les branches divergentes lors de la mise en miroir. |
| `mirror_trigger_builds`               | boolean         | Si `true`, déclenche des builds pour les mises à jour du miroir. |
| `only_mirror_protected_branches`      | booléen ou null | Si `true`, seules les branches protégées sont mises en miroir. Si non défini, la valeur est `null`. |
| `update_status`                       | string          | Statut du processus de mise à jour du miroir. Valeurs possibles : `none`, `scheduled`, `started`, `finished`, `failed` ou `canceled`. |
| `url`                                 | string          | URL du dépôt mis en miroir. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

Exemple de réponse :

```json
{
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "update_status": "finished",
  "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
  "enabled": true,
  "mirror_trigger_builds": true,
  "only_mirror_protected_branches": null,
  "mirror_overwrites_diverged_branches": false,
  "mirror_branch_regex": null
}
```

## Mettre à jour les paramètres de mise en miroir pull du projet {#update-project-pull-mirroring-settings}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/494294) dans GitLab 17.6.

{{< /history >}}

Met à jour les paramètres de mise en miroir pull pour un projet.

```plaintext
PUT /projects/:id/mirror/pull
```

Attributs pris en charge :

| Attribut                             | Type              | Obligatoire | Description |
|:--------------------------------------|:------------------|:---------|:------------|
| `id`                                  | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `auth_password`                       | string            | Non       | Mot de passe utilisé pour l'authentification d'un projet auprès du miroir pull. |
| `auth_user`                           | string            | Non       | Nom d'utilisateur utilisé pour l'authentification d'un projet auprès du miroir pull. |
| `enabled`                             | boolean           | Non       | Si `true`, active la mise en miroir pull sur le projet lorsque défini sur `true`. |
| `mirror_branch_regex`                 | string            | Non       | Contient une expression régulière. Seules les branches dont le nom correspond à l'expression régulière sont mises en miroir. Nécessite que `only_mirror_protected_branches` soit désactivé. |
| `mirror_overwrites_diverged_branches` | boolean           | Non       | Si `true`, écrase les branches divergentes. |
| `mirror_trigger_builds`               | boolean           | Non       | Si `true`, déclenche des pipelines pour les mises à jour du miroir. |
| `only_mirror_protected_branches`      | boolean           | Non       | Si `true`, limite la mise en miroir aux seules branches protégées. |
| `url`                                 | string            | Non       | URL du dépôt distant mis en miroir. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et la configuration du miroir pull mise à jour.

Exemple de requête pour ajouter la mise en miroir pull :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "enabled": true,
    "url": "https://gitlab.example.com/group/project.git",
    "auth_user": "user",
    "auth_password": "password"
  }' \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

Exemple de requête pour supprimer la mise en miroir pull :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "enabled=false" \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

Exemple de réponse :

```json
{
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "update_status": "finished",
  "url": "https://gitlab.example.com/group/project.git",
  "enabled": true,
  "mirror_trigger_builds": false,
  "only_mirror_protected_branches": null,
  "mirror_overwrites_diverged_branches": false,
  "mirror_branch_regex": null
}
```

## Mettre à jour la mise en miroir pull pour un projet (déprécié) {#update-pull-mirroring-for-a-project-deprecated}

{{< history >}}

- Feature flag `mirror_only_branches_match_regex` [activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) dans GitLab 16.0.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/410354) dans GitLab 16.2. L'indicateur de fonctionnalité `mirror_only_branches_match_regex` a été supprimé.
- [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/494294) dans GitLab 17.6.

{{< /history >}}

> [!warning]
> Cette option de configuration a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/issues/494294) dans GitLab 17.6 et est prévue pour suppression dans la v5 de l'API. Utilisez plutôt la [nouvelle configuration et le nouvel endpoint](project_pull_mirroring.md#update-project-pull-mirroring-settings). Ce changement est un changement avec rupture de compatibilité.

Si le dépôt distant est accessible publiquement ou utilise l'authentification `username:token`, utilisez l'API pour configurer la mise en miroir pull lors de la [création](projects.md#create-a-project) ou de la [mise à jour](projects.md#update-a-project) d'un projet.

Si votre dépôt HTTP n'est pas accessible publiquement, vous pouvez ajouter les informations d'authentification à l'URL. Par exemple, `https://username:token@gitlab.company.com/group/project.git` où `token` est un [jeton d'accès personnel](../user/profile/personal_access_tokens.md) avec la portée `api` activée.

Attributs pris en charge :

| Attribut                        | Type    | Obligatoire | Description |
|:---------------------------------|:--------|:---------|:------------|
| `import_url`                     | string  | Oui      | URL du dépôt distant mis en miroir (avec `user:token` si nécessaire). |
| `mirror`                         | boolean | Oui      | Si `true`, active la mise en miroir pull. |
| `mirror_branch_regex`            | string  | Non       | Contient une expression régulière. Seules les branches dont le nom correspond à l'expression régulière sont mises en miroir. Nécessite que `only_mirror_protected_branches` soit désactivé. |
| `mirror_trigger_builds`          | boolean | Non       | Si `true`, déclenche des pipelines pour les mises à jour du miroir. |
| `only_mirror_protected_branches` | boolean | Non       | Si `true`, limite la mise en miroir aux seules branches protégées. |

Exemple de création d'un projet avec la mise en miroir pull :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "new_project",
    "namespace_id": "1",
    "mirror": true,
    "import_url": "https://username:token@gitlab.example.com/group/project.git"
  }' \
  --url "https://gitlab.example.com/api/v4/projects/"
```

Exemple d'ajout de la mise en miroir pull :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "mirror=true&import_url=https://username:token@gitlab.example.com/group/project.git" \
  --url "https://gitlab.example.com/api/v4/projects/:id"
```

Exemple de suppression de la mise en miroir pull :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "mirror=false" \
  --url "https://gitlab.example.com/api/v4/projects/:id"
```

## Démarrer le processus de mise en miroir pull pour un projet {#start-the-pull-mirroring-process-for-a-project}

Démarrez le processus de mise en miroir pull pour un projet.

```plaintext
POST /projects/:id/mirror/pull
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

En cas de succès, renvoie [`202 Accepted`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```
