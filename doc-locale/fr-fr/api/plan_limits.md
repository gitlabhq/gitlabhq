---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: API des limites de plan
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les limites de l'application pour votre plan d'abonnement existant.

Les plans existants dépendent de l'édition de GitLab. Dans la Community Edition, seul le plan `default` est disponible. Dans l'Enterprise Edition, des plans supplémentaires sont également disponibles.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

## Récupérer les limites actuelles du plan {#retrieve-current-plan-limits}

Récupère les limites actuelles d'un plan sur l'instance GitLab.

```plaintext
GET /application/plan_limits
```

| Attribut                         | Type    | Obligatoire | Description |
| --------------------------------- | ------- | -------- | ----------- |
| `plan_name`                       | string  | non       | Nom du plan dont on souhaite obtenir les limites. Par défaut : `default`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/plan_limits"
```

Exemple de réponse :

```json
{
  "ci_instance_level_variables": 25,
  "ci_pipeline_size": 0,
  "ci_active_jobs": 0,
  "ci_project_subscriptions": 2,
  "ci_pipeline_schedules": 10,
  "ci_needs_size_limit": 50,
  "ci_registered_group_runners": 1000,
  "ci_registered_project_runners": 1000,
  "dotenv_size": 5120,
  "dotenv_variables": 20,
  "conan_max_file_size": 3221225472,
  "enforcement_limit": 10000,
  "generic_packages_max_file_size": 5368709120,
  "helm_max_file_size": 5242880,
  "notification_limit": 10000,
  "maven_max_file_size": 3221225472,
  "npm_max_file_size": 524288000,
  "nuget_max_file_size": 524288000,
  "max_pipelines_per_merge_train": 20,
  "pipeline_hierarchy_size": 1000,
  "pypi_max_file_size": 3221225472,
  "terraform_module_max_file_size": 1073741824,
  "storage_size_limit": 15000
}
```

## Mettre à jour les limites du plan {#update-plan-limits}

Met à jour les limites d'un plan sur l'instance GitLab.

```plaintext
PUT /application/plan_limits
```

| Attribut                         | Type    | Obligatoire | Description |
| --------------------------------- | ------- | -------- | ----------- |
| `plan_name`                       | string  | oui      | Nom du plan à mettre à jour. |
| `ci_instance_level_variables`     | entier | non       | Nombre maximum de variables CI/CD de niveau instance pouvant être définies. |
| `ci_pipeline_size`                | entier | non       | Nombre maximum de jobs dans un seul pipeline. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) dans GitLab 15.0. |
| `ci_active_jobs`                  | entier | non       | Nombre total de jobs dans les pipelines actuellement actifs. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) dans GitLab 15.0. |
| `ci_project_subscriptions`        | entier | non       | Nombre maximum d'abonnements de pipeline vers et depuis un projet. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) dans GitLab 15.0. |
| `ci_pipeline_schedules`           | entier | non       | Nombre maximum de planifications de pipeline. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) dans GitLab 15.0. |
| `ci_needs_size_limit`             | entier | non       | Nombre maximum de dépendances [`needs`](../ci/yaml/needs.md) qu'un job peut avoir. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) dans GitLab 15.0. |
| `ci_registered_group_runners`     | entier | non       | Nombre maximum de runners créés ou actifs dans un groupe au cours des sept derniers jours. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) dans GitLab 15.0. |
| `ci_registered_project_runners`   | entier | non       | Nombre maximum de runners créés ou actifs dans un projet au cours des sept derniers jours. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) dans GitLab 15.0. |
| `dotenv_size`                     | entier | non       | Taille maximale d'un artefact dotenv en octets. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/432529) dans GitLab 17.1. |
| `dotenv_variables`                | entier | non       | Nombre maximum de variables dans un artefact dotenv. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/432529) dans GitLab 17.1. |
| `conan_max_file_size`             | entier | non       | Taille maximale du fichier de package Conan en octets. |
| `enforcement_limit`               | entier | non       | Taille de stockage maximale pour l'application des limites de l'espace de nommage racine en Mio. |
| `generic_packages_max_file_size`  | entier | non       | Taille maximale du fichier de package générique en octets. |
| `helm_max_file_size`              | entier | non       | Taille maximale du fichier de chart Helm en octets. |
| `maven_max_file_size`             | entier | non       | Taille maximale du fichier de package Maven en octets. |
| `notification_limit`              | entier | non       | Taille de stockage maximale pour les notifications de limite de l'espace de nommage racine en Mio. |
| `npm_max_file_size`               | entier | non       | Taille maximale du fichier de package NPM en octets. |
| `nuget_max_file_size`             | entier | non       | Taille maximale du fichier de package NuGet en octets. |
| `max_pipelines_per_merge_train`   | entier | non       | Nombre maximum de pipelines parallèles par merge train. Valeur par défaut : `20`. Valeur minimale : `1`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/374188) dans GitLab 19.0. |
| `pipeline_hierarchy_size`         | entier | non       | Nombre maximum de pipelines downstream dans l'arborescence hiérarchique d'un pipeline. Valeur par défaut : `1000`. Les valeurs supérieures à 1000 sont [déconseillées](../administration/cicd/limits.md#limit-pipeline-hierarchy-size). |
| `pypi_max_file_size`              | entier | non       | Taille maximale du fichier de package PyPI en octets. |
| `terraform_module_max_file_size`  | entier | non       | Taille maximale du fichier de package de module Terraform en octets. |
| `storage_size_limit`              | entier | non       | Taille de stockage maximale pour l'espace de nommage racine en Mio. |
| `web_hook_calls`                  | entier | non       | Nombre maximum de fois qu'un webhook peut être appelé par minute par espace de nommage de premier niveau. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/571738) dans GitLab 18.5. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/plan_limits?plan_name=default&conan_max_file_size=3221225472"
```

Exemple de réponse :

```json
{
  "ci_instance_level_variables": 25,
  "ci_pipeline_size": 0,
  "ci_active_jobs": 0,
  "ci_project_subscriptions": 2,
  "ci_pipeline_schedules": 10,
  "ci_needs_size_limit": 50,
  "ci_registered_group_runners": 1000,
  "ci_registered_project_runners": 1000,
  "conan_max_file_size": 3221225472,
  "dotenv_variables": 20,
  "dotenv_size": 5120,
  "generic_packages_max_file_size": 5368709120,
  "helm_max_file_size": 5242880,
  "maven_max_file_size": 3221225472,
  "npm_max_file_size": 524288000,
  "nuget_max_file_size": 524288000,
  "max_pipelines_per_merge_train": 20,
  "pipeline_hierarchy_size": 1000,
  "pypi_max_file_size": 3221225472,
  "terraform_module_max_file_size": 1073741824
}
```
