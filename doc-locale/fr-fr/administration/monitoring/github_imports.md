---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Surveillance des imports GitHub
description: "Utilisez les métriques Prometheus pour surveiller les imports GitHub dans votre instance GitLab Self-Managed."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

L'importateur GitHub expose diverses métriques Prometheus que vous pouvez utiliser pour surveiller l'état de santé et la progression de l'importateur.

## Durées d'import {#import-duration-times}

| Nom                                     | Type      |
|------------------------------------------|-----------|
| `github_importer_total_duration_seconds` | histogramme |

Cette métrique suit le temps total, en secondes, consacré à l'import d'un projet (depuis la création du projet jusqu'à la fin du processus d'import), pour chaque projet importé. Le nom du projet est stocké dans le label `project` au format `namespace/name` (par exemple `gitlab-org/gitlab`).

## Nombre de projets importés {#number-of-imported-projects}

| Nom                                | Type    |
|-------------------------------------|---------|
| `github_importer_imported_projects` | compteur |

Cette métrique suit le nombre total de projets importés au fil du temps. Cette métrique n'expose aucun label.

## Nombre d'appels à l'API GitHub {#number-of-github-api-calls}

| Nom                            | Type    |
|---------------------------------|---------|
| `github_importer_request_count` | compteur |

Cette métrique suit le nombre total d'appels à l'API GitHub effectués au fil du temps, pour tous les projets. Cette métrique n'expose aucun label.

## Erreurs de limite de débit {#rate-limit-errors}

| Nom                              | Type    |
|-----------------------------------|---------|
| `github_importer_rate_limit_hits` | compteur |

Cette métrique suit le nombre de fois où nous atteignons la limite de débit GitHub, pour tous les projets. Cette métrique n'expose aucun label.

## Nombre de tickets importés {#number-of-imported-issues}

| Nom                              | Type    |
|-----------------------------------|---------|
| `github_importer_imported_issues` | compteur |

Cette métrique suit le nombre de tickets importés dans tous les projets.

Le nom du projet est stocké dans le label `project` au format `namespace/name` (par exemple `gitlab-org/gitlab`).

## Nombre de pull requests importées {#number-of-imported-pull-requests}

| Nom                                     | Type    |
|------------------------------------------|---------|
| `github_importer_imported_pull_requests` | compteur |

Cette métrique suit le nombre de pull requests importées dans tous les projets.

Le nom du projet est stocké dans le label `project` au format `namespace/name` (par exemple `gitlab-org/gitlab`).

## Nombre de commentaires importés {#number-of-imported-comments}

| Nom                             | Type    |
|----------------------------------|---------|
| `github_importer_imported_notes` | compteur |

Cette métrique suit le nombre de commentaires importés dans tous les projets.

Le nom du projet est stocké dans le label `project` au format `namespace/name` (par exemple `gitlab-org/gitlab`).

## Nombre de commentaires de révision de pull request importés {#number-of-imported-pull-request-review-comments}

| Nom                                  | Type    |
|---------------------------------------|---------|
| `github_importer_imported_diff_notes` | compteur |

Cette métrique suit le nombre de commentaires importés dans tous les projets.

Le nom du projet est stocké dans le label `project` au format `namespace/name` (par exemple `gitlab-org/gitlab`).

## Nombre de dépôts importés {#number-of-imported-repositories}

| Nom                                    | Type    |
|-----------------------------------------|---------|
| `github_importer_imported_repositories` | compteur |

Cette métrique suit le nombre de dépôts importés dans tous les projets. Cette métrique n'expose aucun label.
