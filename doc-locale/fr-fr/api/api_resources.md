---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Ressources de l'API REST"
description: "Ressources de l'API REST GitLab organisées par contexte (projet, groupe, autonome et modèles) avec les chemins d'accès aux endpoints."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

L'API REST GitLab vous donne un contrôle programmatique sur les ressources GitLab. Créez des intégrations avec vos outils existants, automatisez les tâches répétitives et extrayez des données pour des rapports personnalisés. Accédez aux projets, groupes, tickets et merge requests et manipulez-les sans utiliser l'interface web.

Utilisez l'API REST pour :

- Automatiser la création de projets et la gestion des utilisateurs.
- Déclencher des pipelines CI/CD depuis des systèmes externes.
- Extraire des données de tickets et de merge requests pour des tableaux de bord personnalisés.
- Intégrer GitLab avec des applications tierces.
- Mettre en œuvre des workflows personnalisés sur plusieurs dépôts.

Les ressources de l'API REST sont organisées en :

- [Ressources de projet](#project-resources)
- [Ressources de groupe](#group-resources)
- [Ressources autonomes](#standalone-resources)
- [Ressources de modèles](#template-resources)

## Ressources de projet {#project-resources}

Les ressources d'API suivantes sont disponibles dans le contexte de projet :

| Ressource                                                                       | Endpoints disponibles |
|--------------------------------------------------------------------------------|---------------------|
| [Demandes d'accès](access_requests.md)                                          | `/projects/:id/access_requests` (également disponible pour les groupes) |
| [Jetons d'accès](project_access_tokens.md)                                      | `/projects/:id/access_tokens` (également disponible pour les groupes) |
| [Agents](cluster_agents.md)                                                    | `/projects/:id/cluster_agents` |
| [Branches](branches.md)                                                        | `/projects/:id/repository/branches/`, `/projects/:id/repository/merged_branches` |
| [Commits](commits.md)                                                          | `/projects/:id/repository/commits`, `/projects/:id/statuses` |
| [Registre de conteneurs](container_registry.md)                                    | `/projects/:id/registry/repositories` |
| [Règles de protection du registre de conteneurs](container_repository_protection_rules.md)  | `/projects/:id/registry/protection/repository/rules` |
| [Règles de protection des tags du registre de conteneurs](container_registry_protection_tag_rules.md) | `/projects/:id/registry/protection/tag/rules` |
| [Attributs personnalisés](custom_attributes.md)                                      | `/projects/:id/custom_attributes` (également disponible pour les groupes et les utilisateurs) |
| [Distributions Composer](packages/composer.md)                                 | `/projects/:id/packages/composer` (également disponible pour les groupes) |
| [Distributions Conan v1](packages/conan_v1.md)                                       | `/projects/:id/packages/conan` (également disponible en autonome) |
| [Distributions Conan v2](packages/conan_v2.md)                                       | `/projects/:id/packages/conan` (également disponible en autonome) |
| [Distributions Debian](packages/debian_project_distributions.md)               | `/projects/:id/debian_distributions` (également disponible pour les groupes) |
| [Paquets Debian](packages/debian.md)                                          | `/projects/:id/packages/debian` (également disponible pour les groupes) |
| [Dépendances](dependencies.md)                                                | `/projects/:id/dependencies` |
| [Clés de déploiement](deploy_keys.md)                                                  | `/projects/:id/deploy_keys` (également disponible en autonome) |
| [Jetons de déploiement](deploy_tokens.md)                                              | `/projects/:id/deploy_tokens` (également disponible pour les groupes et en autonome) |
| [Déploiements](deployments.md)                                                  | `/projects/:id/deployments` |
| [Discussions](discussions.md) (commentaires en fil de discussion)                              | `/projects/:id/issues/.../discussions`, `/projects/:id/snippets/.../discussions`, `/projects/:id/merge_requests/.../discussions`, `/projects/:id/commits/.../discussions` (également disponible pour les groupes) |
| [Notes provisoires](draft_notes.md) (commentaires)                                       | `/projects/:id/merge_requests/.../draft_notes` |
| [Réactions emoji](emoji_reactions.md)                                          | `/projects/:id/issues/.../award_emoji`, `/projects/:id/merge_requests/.../award_emoji`, `/projects/:id/snippets/.../award_emoji` |
| [Environnements](environments.md)                                                | `/projects/:id/environments` |
| [Suivi des erreurs](error_tracking.md)                                            | `/projects/:id/error_tracking/settings` |
| [Événements](events.md)                                                            | `/projects/:id/events` (également disponible pour les utilisateurs et en autonome) |
| [Vérifications de statut externes](status_checks.md)                                     | `/projects/:id/external_status_checks` |
| [Listes d'utilisateurs de feature flag](feature_flag_user_lists.md)                          | `/projects/:id/feature_flags_user_lists` |
| [Feature flags](feature_flags.md)                                              | `/projects/:id/feature_flags` |
| [Périodes de gel](freeze_periods.md)                                            | `/projects/:id/freeze_periods` |
| [Proxy Go](packages/go_proxy.md)                                               | `/projects/:id/packages/go` |
| [Dépôt Helm](packages/helm.md)                                            | `/projects/:id/packages/helm_repository` |
| [Intégrations](project_integrations.md) (anciennement « services »)                          | `/projects/:id/integrations` |
| [Invitations](invitations.md)                                                  | `/projects/:id/invitations` (également disponible pour les groupes) |
| [Tableaux des tickets](boards.md)                                                      | `/projects/:id/boards` |
| [Liens de ticket](issue_links.md)                                                  | `/projects/:id/issues/.../links` |
| [Statistiques des tickets](issues_statistics.md)                                      | `/projects/:id/issues_statistics` (également disponible pour les groupes et en autonome) |
| [Tickets](issues.md)                                                            | `/projects/:id/issues` (également disponible pour les groupes et en autonome) |
| [Itérations](iterations.md)                                                    | `/projects/:id/iterations` (également disponible pour les groupes) |
| [Portée du jeton de job CI/CD du projet](project_job_token_scopes.md)                   | `/projects/:id/job_token_scope` |
| [Jobs](jobs.md)                                                                | `/projects/:id/jobs`, `/projects/:id/pipelines/.../jobs` |
| [Artefacts de job](job_artifacts.md)                                             | `/projects/:id/jobs/:job_id/artifacts` |
| [Labels](labels.md)                                                            | `/projects/:id/labels` |
| [Dépôt Maven](packages/maven.md)                                          | `/projects/:id/packages/maven` (également disponible pour les groupes et en autonome) |
| [Membres](project_members.md)                                                  | `/projects/:id/members` (également disponible pour les groupes) |
| [Approbations de merge request](merge_request_approvals.md)                          | `/projects/:id/approvals`, `/projects/:id/merge_requests/.../approvals` |
| [Merge requests](merge_requests.md)                                            | `/projects/:id/merge_requests` (également disponible pour les groupes et en autonome) |
| [Merge trains](merge_trains.md)                                                | `/projects/:id/merge_trains` |
| [Métadonnées](metadata.md)                                                        | `/metadata` |
| [Registre de modèles](model_registry.md)                                            | `/projects/:id/packages/ml_models/` |
| [Notes](notes.md) (commentaires)                                                   | `/projects/:id/issues/.../notes`, `/projects/:id/snippets/.../notes`, `/projects/:id/merge_requests/.../notes` (également disponible pour les groupes) |
| [Paramètres de notification](notification_settings.md)                              | `/projects/:id/notification_settings` (également disponible pour les groupes et en autonome) |
| [Dépôt NPM](packages/npm.md)                                              | `/projects/:id/packages/npm` |
| [Paquets NuGet](packages/nuget.md)                                            | `/projects/:id/packages/nuget` (également disponible pour les groupes) |
| [Paquets](packages.md)                                                        | `/projects/:id/packages` |
| [Domaines Pages](pages_domains.md)                                              | `/projects/:id/pages/domains` (également disponible en autonome) |
| [Paramètres Pages](pages.md)                                                     | `/projects/:id/pages` |
| [Planifications de pipeline](pipeline_schedules.md)                                    | `/projects/:id/pipeline_schedules` |
| [Déclencheurs de pipeline](pipeline_triggers.md)                                      | `/projects/:id/triggers` |
| [Pipelines](pipelines.md)                                                      | `/projects/:id/pipelines` |
| [Badges de projet](project_badges.md)                                            | `/projects/:id/badges` |
| [Clusters de projet](project_clusters.md)                                        | `/projects/:id/clusters` |
| [Import/export de projet](project_import_export.md)                              | `/projects/:id/export`, `/projects/import`, `/projects/:id/import` |
| [Jalons de projet](milestones.md)                                            | `/projects/:id/milestones` |
| [Extraits de code de projet](project_snippets.md)                                        | `/projects/:id/snippets` |
| [Modèles de projet](project_templates.md)                                      | `/projects/:id/templates` |
| [Vulnérabilités de projet](project_vulnerabilities.md).                         | `/projects/:id/vulnerabilities` |
| [Wikis de projet](wikis.md)                                                      | `/projects/:id/wikis` |
| [Variables au niveau du projet](project_level_variables.md)                          | `/projects/:id/variables` |
| [Projets](projects.md) incluant la configuration des webhooks                             | `/projects`, `/projects/:id/hooks` (également disponible pour les utilisateurs) |
| [Branches protégées](protected_branches.md)                                    | `/projects/:id/protected_branches` |
| [Registre de conteneurs protégé](container_repository_protection_rules.md)       | `/projects/:id/registry/protection/rules` |
| [Environnements protégés](protected_environments.md)                            | `/projects/:id/protected_environments` |
| [Paquets protégés](project_packages_protection_rules.md)                     | `/projects/:id/packages/protection/rules` |
| [Tags protégés](protected_tags.md)                                            | `/projects/:id/protected_tags` |
| [Paquets PyPI](packages/pypi.md)                                              | `/projects/:id/packages/pypi` (également disponible pour les groupes) |
| [Liens de release](releases/links.md)                                             | `/projects/:id/releases/.../assets/links` |
| [Releases](releases/_index.md)                                                 | `/projects/:id/releases` |
| [Miroirs distants](remote_mirrors.md)                                            | `/projects/:id/remote_mirrors` |
| [Dépôts](repositories.md)                                                | `/projects/:id/repository` |
| [Fichiers du dépôt](repository_files.md)                                        | `/projects/:id/repository/files` |
| [Sous-modules du dépôt](repository_submodules.md)                              | `/projects/:id/repository/submodules` |
| [Événements de label de ressource](resource_label_events.md)                              | `/projects/:id/issues/.../resource_label_events`, `/projects/:id/merge_requests/.../resource_label_events` (également disponible pour les groupes) |
| [Gems Ruby](packages/rubygems.md)                                              | `/projects/:id/packages/rubygems` |
| [Runners](runners.md)                                                          | `/projects/:id/runners` (également disponible en autonome) |
| [Recherche](search.md)                                                            | `/projects/:id/search` (également disponible pour les groupes et en autonome) |
| [Tags](tags.md)                                                                | `/projects/:id/repository/tags` |
| [Modules Terraform](packages/terraform-modules.md)                             | `/projects/:id/packages/terraform/modules` (également disponible en autonome) |
| [Valider le fichier `.gitlab-ci.yml`](lint.md)                                      | `/projects/:id/ci/lint` |
| [Vulnérabilités](vulnerabilities.md)                                          | `/vulnerabilities/:id` |
| [Exports de vulnérabilités](vulnerability_exports.md)                              | `/projects/:id/vulnerability_exports` |
| [Résultats de vulnérabilités](vulnerability_findings.md)                            | `/projects/:id/vulnerability_findings` |

## Ressources de groupe {#group-resources}

Les ressources d'API suivantes sont disponibles dans le contexte de groupe :

| Ressource                                                       | Endpoints disponibles |
|----------------------------------------------------------------|---------------------|
| [Demandes d'accès](access_requests.md)                          | `/groups/:id/access_requests/` (également disponible pour les projets) |
| [Jetons d'accès](group_access_tokens.md)                        | `/groups/:id/access_tokens` (également disponible pour les projets) |
| [Attributs personnalisés](custom_attributes.md)                      | `/groups/:id/custom_attributes` (également disponible pour les projets et les utilisateurs) |
| [Distributions Debian](packages/debian_group_distributions.md) | `/groups/:id/-/packages/debian` (également disponible pour les projets) |
| [Jetons de déploiement](deploy_tokens.md)                              | `/groups/:id/deploy_tokens` (également disponible pour les projets et en autonome) |
| [Discussions](discussions.md) (commentaires et fils de discussion)           | `/groups/:id/epics/.../discussions` (également disponible pour les projets) |
| [Tickets d'epic](epic_issues.md)                                  | `/groups/:id/epics/.../issues` |
| [Liens d'epic](epic_links.md)                                    | `/groups/:id/epics/.../epics` |
| [Epics](epics.md)                                              | `/groups/:id/epics` |
| [Groupes](groups.md)                                            | `/groups`, `/groups/.../subgroups` |
| [Badges de groupe](group_badges.md)                                | `/groups/:id/badges` |
| [Tableaux des tickets de groupe](group_boards.md)                          | `/groups/:id/boards` |
| [Itérations de groupe](group_iterations.md)                        | `/groups/:id/iterations` (également disponible pour les projets) |
| [Labels de groupe](group_labels.md)                                | `/groups/:id/labels` |
| [Variables au niveau du groupe](group_level_variables.md)              | `/groups/:id/variables` |
| [Jalons de groupe](group_milestones.md)                        | `/groups/:id/milestones` |
| [Releases de groupe](group_releases.md)                            | `/groups/:id/releases` |
| [Certificats SSH de groupe](group_ssh_certificates.md)            | `/groups/:id/ssh_certificates` |
| [Wikis de groupe](group_wikis.md)                                  | `/groups/:id/wikis` |
| [Invitations](invitations.md)                                  | `/groups/:id/invitations` (également disponible pour les projets) |
| [Tickets](issues.md)                                            | `/groups/:id/issues` (également disponible pour les projets et en autonome) |
| [Statistiques des tickets](issues_statistics.md)                      | `/groups/:id/issues_statistics` (également disponible pour les projets et en autonome) |
| [Epics liés](linked_epics.md)                                | `/groups/:id/epics/.../related_epics` |
| [Rôles de membre](member_roles.md)                                | `/groups/:id/member_roles` |
| [Membres](group_members.md)                                    | `/groups/:id/members` (également disponible pour les projets) |
| [Merge requests](merge_requests.md)                            | `/groups/:id/merge_requests` (également disponible pour les projets et en autonome) |
| [Notes](notes.md) (commentaires)                                   | `/groups/:id/epics/.../notes` (également disponible pour les projets) |
| [Paramètres de notification](notification_settings.md)              | `/groups/:id/notification_settings` (également disponible pour les projets et en autonome) |
| [Événements de label de ressource](resource_label_events.md)              | `/groups/:id/epics/.../resource_label_events` (également disponible pour les projets) |
| [Recherche](search.md)                                            | `/groups/:id/search` (également disponible pour les projets et en autonome) |

## Ressources autonomes {#standalone-resources}

Les ressources d'API suivantes sont disponibles en dehors des contextes de projet et de groupe (y compris `/users`) :

| Ressource                                                                                     | Endpoints disponibles |
|----------------------------------------------------------------------------------------------|---------------------|
| [Apparence](appearance.md)                                                                  | `/application/appearance` |
| [Applications](applications.md)                                                              | `/applications` |
| [Événements d'audit](audit_events.md)                                                              | `/audit_events` |
| [Avatar](avatar.md)                                                                          | `/avatar` |
| [Messages de diffusion](broadcast_messages.md)                                                  | `/broadcast_messages` |
| [Extraits de code](snippets.md)                                                                 | `/snippets` |
| [Code Suggestions](code_suggestions.md)                                                      | `/code_suggestions` |
| [Attributs personnalisés](custom_attributes.md)                                                    | `/users/:id/custom_attributes` (également disponible pour les groupes et les projets) |
| [Exports de liste de dépendances](dependency_list_export.md)                                         | `/pipelines/:id/dependency_list_exports`, `/projects/:id/dependency_list_exports`, `/groups/:id/dependency_list_exports`, `/security/dependency_list_exports/:id`, `/security/dependency_list_exports/:id/download` |
| [Clés de déploiement](deploy_keys.md)                                                                | `/deploy_keys` (également disponible pour les projets) |
| [Jetons de déploiement](deploy_tokens.md)                                                            | `/deploy_tokens` (également disponible pour les projets et les groupes) |
| [Flows de la plateforme d'agents GitLab Duo](duo_agent_platform_flows.md)                                      | `/ai/duo_workflows` |
| [Événements](events.md)                                                                          | `/events`, `/users/:id/events` (également disponible pour les projets) |
| [Feature flags](features.md)                                                                 | `/features` |
| [Nœuds Geo](geo_nodes.md)                                                                    | `/geo_nodes` |
| [GLQL](glql.md)                                                                              | `/glql` |
| [Analytique d'activité de groupe](group_activity_analytics.md)                                      | `/analytics/group_activity/{issues_count}` |
| [Déplacements de stockage du dépôt de groupe](group_repository_storage_moves.md)                          | `/group_repository_storage_moves` |
| [Importer un dépôt depuis GitHub](import.md#import-repository-from-github)                     | `/import/github` |
| [Importer un dépôt depuis Bitbucket Server](import.md#import-repository-from-bitbucket-server) | `/import/bitbucket_server` |
| [Clusters d'instance](instance_clusters.md)                                                    | `/admin/clusters` |
| [Variables CI/CD au niveau de l'instance](instance_level_ci_variables.md)                             | `/admin/ci/variables` |
| [Statistiques des tickets](issues_statistics.md)                                                    | `/issues_statistics` (également disponible pour les groupes et les projets) |
| [Tickets](issues.md)                                                                          | `/issues` (également disponible pour les groupes et les projets) |
| [Jobs](jobs.md)                                                                              | `/job` |
| [Clés](keys.md)                                                                              | `/keys` |
| [Licence](license.md)                                                                        | `/license` |
| [Markdown](markdown.md)                                                                      | `/markdown` |
| [Merge requests](merge_requests.md)                                                          | `/merge_requests` (également disponible pour les groupes et les projets) |
| [Espaces de nommage](namespaces.md)                                                                  | `/namespaces` |
| [Paramètres de notification](notification_settings.md)                                            | `/notification_settings` (également disponible pour les groupes et les projets) |
| [Paramètres de conformité et de politique](compliance_policy_settings.md)         | `/admin/security/compliance_policy_settings` |
| [Domaines Pages](pages_domains.md)                                                            | `/pages/domains` (également disponible pour les projets) |
| [Jetons d'accès personnels](personal_access_tokens.md)                                          | `/personal_access_tokens` |
| [Limites de plan](plan_limits.md)                                                                | `/application/plan_limits` |
| [Déplacements de stockage du dépôt de projet](project_repository_storage_moves.md)                      | `/project_repository_storage_moves` |
| [Projets](projects.md)                                                                      | `/users/:id/projects` (également disponible pour les projets) |
| [Runners](runners.md)                                                                        | `/runners` (également disponible pour les projets) |
| [Recherche](search.md)                                                                          | `/search` (également disponible pour les groupes et les projets) |
| [Données de service](usage_data.md)                                                                | `/usage_data` (réservé aux utilisateurs [Administrateur](../user/permissions.md) de l'instance GitLab) |
| [Paramètres](settings.md)                                                                      | `/application/settings` |
| [Métriques Sidekiq](sidekiq_metrics.md)                                                        | `/sidekiq` |
| [Administration des files d'attente Sidekiq](admin_sidekiq_queues.md)                                     | `/admin/sidekiq/queues/:queue_name` |
| [Déplacements de stockage du dépôt d'extrait de code](snippet_repository_storage_moves.md)                      | `/snippet_repository_storage_moves` |
| [Statistiques](statistics.md)                                                                  | `/application/statistics` |
| [Suggestions](suggestions.md)                                                                | `/suggestions` |
| [Hooks système](system_hooks.md)                                                              | `/hooks` |
| [Tâches](todos.md)                                                                           | `/todos` |
| [Informations sur les jetons](admin/token.md)                                                          | `/admin/token` |
| [Sujets](topics.md)                                                                          | `/topics` |
| [Applications utilisateur](user_applications.md)                                                    | `/user/applications` |
| [Utilisateurs](users.md)                                                                            | `/users` |
| [Commits web](web_commits.md)                                                                | `/web_commits/public_key` |

## Ressources de modèles {#template-resources}

Des endpoints sont disponibles pour :

- [Modèles Dockerfile](templates/dockerfiles.md)
- [Modèles `.gitignore`](templates/gitignores.md)
- [Modèles YAML GitLab CI/CD](templates/gitlab_ci_ymls.md)
- [Modèles de licences open source](templates/licenses.md)
