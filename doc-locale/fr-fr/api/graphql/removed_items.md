---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Éléments supprimés de l'API GraphQL"
description: "Liste des éléments dépréciés et supprimés dans l'API GraphQL de GitLab."
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GraphQL est une API sans version, contrairement à l'API REST. Parfois, des éléments doivent être mis à jour ou supprimés de l'API GraphQL. Conformément à notre [processus de suppression des éléments](_index.md#deprecation-and-removal-process), voici les éléments qui ont été supprimés.

Pour les dépréciations, consultez la [page des dépréciations par version](../../update/deprecations.md).

## GitLab 17.0 {#gitlab-170}

Champs supprimés dans GitLab 17.0.

### Champs GraphQL {#graphql-fields}

| Nom du champ         | Type GraphQL | Déprécié dans | Merge request de suppression                                                              | Utiliser à la place |
|--------------------|--------------|---------------|-------------------------------------------------------------------------|-------------|
| `architectureName` | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | Utilisez ce champ dans l'objet `manager` à la place. |
| `executorName`     | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | Utilisez ce champ dans l'objet `manager` à la place. |
| `ipAddress`        | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | Utilisez ce champ dans l'objet `manager` à la place. |
| `platformName`     | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | Utilisez ce champ dans l'objet `manager` à la place. |
| `revision`         | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | Utilisez ce champ dans l'objet `manager` à la place. |
| `version`          | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | Utilisez ce champ dans l'objet `manager` à la place. |

## GitLab 16.0 {#gitlab-160}

Champs supprimés dans GitLab 16.0.

### Champs GraphQL {#graphql-fields-1}

| Nom du champ   | Type GraphQL                    | Déprécié dans                                                       | Merge request de suppression                                                              | Utiliser à la place |
|--------------|---------------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------------|-------------|
| `name`       | `PipelineSecurityReportFinding` | [15.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89571) | [!119055](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119055) | `title`     |
| `external`   | `ReleaseAssetLink`              | 15.9                                                                | [!111750](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111750) | Aucune        |
| `confidence` | `PipelineSecurityReportFinding` | 15.4                                                                | [!118617](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118617) | Aucune        |
| `PAUSED`     | `CiRunnerStatus`                | 14.8                                                                | [!118635](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118635) | `CiRunner.paused: true` |
| `ACTIVE`     | `CiRunnerStatus`                | 14.8                                                                | [!118635](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118635) | `CiRunner.paused: false` |

### Mutations GraphQL {#graphql-mutations}

| Nom de l'argument | Mutation                          | Déprécié dans                                                       | Utiliser à la place |
|---------------|-----------------------------------|---------------------------------------------------------------------|-------------|
| -             | `vulnerabilityFindingDismiss`     | [15.5](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/99170) | `vulnerabilityDismiss` ou `securityFindingDismiss` |
| -             | `apiFuzzingCiConfigurationCreate` | [15.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87241) | `todos`     |
| -             | `CiCdSettingsUpdate`              | [15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/361801)        | `ProjectCiCdSettingsUpdate` |

## GitLab 15.0 {#gitlab-150}

Champs supprimés dans GitLab 15.0.

### Mutations GraphQL {#graphql-mutations-1}

[Supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85382) dans GitLab 15.0 :

| Nom de l'argument | Mutation                  | Déprécié dans | Utiliser à la place |
|---------------|---------------------------|---------------|-------------|
| -             | `clusterAgentTokenDelete` | 14.7          | `clusterAgentTokenRevoke` |

### Champs GraphQL {#graphql-fields-2}

[Supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/342882) dans GitLab 15.0 :

| Nom de l'argument | Nom du champ  | Déprécié dans | Utiliser à la place |
|---------------|-------------|---------------|-------------|
| -             | `pipelines` | 14.5          | Aucune        |

### Types GraphQL {#graphql-types}

| Nom du champ                                 | Type GraphQL             | Déprécié dans | Utiliser à la place |
|--------------------------------------------|--------------------------|---------------|-------------|
| `defaultMergeCommitMessageWithDescription` | `GraphQL::Types::String` | 14.5          | Aucun. Définissez un [modèle de commit de fusion](../../user/project/merge_requests/commit_templates.md) dans votre projet et utilisez `defaultMergeCommitMessage`. |
