---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "API REST pour créer, récupérer, mettre à jour, supprimer et gérer les projets et les fonctionnalités des projets."
title: API Projects
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les projets GitLab et leurs paramètres associés. Un projet est un hub central de collaboration où vous stockez du code, suivez des tickets et organisez les activités de l'équipe. Pour plus d'informations, consultez [créer un projet](../user/project/_index.md).

L'API Projects contient des endpoints qui :

- Récupèrent les informations et les métadonnées du projet
- Créent, modifient et suppriment des projets
- Contrôlent la visibilité du projet, les permissions d'accès et les paramètres de sécurité
- Gèrent les fonctionnalités du projet telles que le suivi des tickets, les merge requests et le CI/CD
- Archivent et désarchivent des projets
- Transfèrent des projets entre des espaces de nommage
- Gèrent les paramètres de déploiement et du registre de conteneurs

## Prérequis {#prerequisites}

- N'importe quel [rôle par défaut](../user/permissions.md#roles) sur un projet pour lire les propriétés du projet.
- Le rôle Maintainer ou Owner sur un projet pour modifier les propriétés du projet.

## Niveau de visibilité du projet {#project-visibility-level}

Un projet dans GitLab peut avoir l'un des niveaux de visibilité suivants :

- Private
- Internal
- Public

Le niveau de visibilité est déterminé par le champ `visibility` dans le projet.

Pour plus d'informations, consultez [Visibilité du projet](../user/public_access.md).

Les champs renvoyés dans les réponses varient en fonction des [permissions](../user/permissions.md) de l'utilisateur authentifié.

## Niveau de visibilité des fonctionnalités du projet {#project-feature-visibility-level}

Vous pouvez contrôler la disponibilité des paramètres du projet lorsque vous créez ou modifiez un projet. Par exemple, pour désactiver `forking_access_level` pour un projet existant :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"forking_access_level": "disabled"}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>"
```

Chaque paramètre peut être défini indépendamment et accepte les valeurs suivantes :

- `disabled` : Désactiver la fonctionnalité.
- `private` : Activer et définir la fonctionnalité sur **Uniquement les membres du projet**.
- `enabled` : Activer et définir la fonctionnalité sur **Toute personne ayant accès**.
- `public` : Activer et définir la fonctionnalité sur **Tout le monde**. Disponible uniquement pour `pages_access_level`.

Pour plus d'informations, consultez [Modifier la visibilité des fonctionnalités individuelles d'un projet](../user/public_access.md#change-the-visibility-of-individual-features-in-a-project).

| Attribut                              | Type   | Obligatoire | Description |
|:---------------------------------------|:-------|:---------|:------------|
| `analytics_access_level`               | string | Non       | Définir la visibilité des [analyses](../user/analytics/_index.md). |
| `builds_access_level`                  | string | Non       | Définir la visibilité des [pipelines](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines). |
| `container_registry_access_level`      | string | Non       | Définir la visibilité du [registre de conteneurs](../user/packages/container_registry/_index.md#change-visibility-of-the-container-registry). |
| `environments_access_level`            | string | Non       | Définir la visibilité des [environnements](../ci/environments/_index.md). |
| `feature_flags_access_level`           | string | Non       | Définir la visibilité des [feature flags](../operations/feature_flags.md). |
| `forking_access_level`                 | string | Non       | Définir la visibilité des [duplications](../user/project/repository/forking_workflow.md). |
| `infrastructure_access_level`          | string | Non       | Définir la visibilité de la [gestion d'infrastructure](../user/infrastructure/_index.md). |
| `issues_access_level`                  | string | Non       | Définir la visibilité des [tickets](../user/project/issues/_index.md). |
| `merge_requests_access_level`          | string | Non       | Définir la visibilité des [merge requests](../user/project/merge_requests/_index.md). |
| `model_experiments_access_level`       | string | Non       | Définir la visibilité des [expériences de modèles de machine learning](../user/project/ml/experiment_tracking/_index.md). |
| `model_registry_access_level`          | string | Non       | Définir la visibilité du [registre de modèles de machine learning](../user/project/ml/model_registry/_index.md#access-the-model-registry). |
| `monitor_access_level`                 | string | Non       | Définir la visibilité de la [surveillance des performances des applications](../operations/_index.md). |
| `pages_access_level`                   | string | Non       | Définir la visibilité de [GitLab Pages](../user/project/pages/pages_access_control.md). |
| `releases_access_level`                | string | Non       | Définir la visibilité des [releases](../user/project/releases/_index.md). |
| `repository_access_level`              | string | Non       | Définir la visibilité du [dépôt](../user/project/repository/_index.md). |
| `requirements_access_level`            | string | Non       | Définir la visibilité de la [gestion des exigences](../user/project/requirements/_index.md). |
| `security_and_compliance_access_level` | string | Non       | Définir la visibilité de la [sécurité et conformité](../user/application_security/_index.md). |
| `snippets_access_level`                | string | Non       | Définir la visibilité des [extraits de code](../user/snippets.md#change-default-visibility-of-snippets). |
| `wiki_access_level`                    | string | Non       | Définir la visibilité du [wiki](../user/project/wiki/_index.md#enable-or-disable-a-project-wiki). |

## Attributs dépréciés {#deprecated-attributes}

Ces attributs sont dépréciés et pourraient être supprimés dans une future version de l'API REST. Utilisez plutôt les attributs alternatifs.

| Attribut déprécié     | Alternative |
|:-------------------------|:------------|
| `tag_list`               | Utilisez plutôt `topics`. |
| `marked_for_deletion_at` | Utilisez plutôt `marked_for_deletion_on`. Premium et Ultimate uniquement. |
| `approvals_before_merge` | [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/work_items/353097) dans GitLab 16.0. Utilisez plutôt l'[API Merge request approvals](merge_request_approvals.md). Premium et Ultimate uniquement. |
| `packages_enabled` | [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/work_items/454759) dans GitLab 17.10. Utilisez plutôt `package_registry_access_level`. |
| `container_registry_enabled` | Utilisez plutôt `container_registry_access_level`. |
| `public_builds` | Utilisez plutôt `public_jobs`. |
| `emails_disabled` | Utilisez plutôt `emails_enabled`. |
| `issues_enabled` | Utilisez plutôt `issues_access_level`. |
| `jobs_enabled` | Utilisez plutôt `builds_access_level`. |
| `merge_requests_enabled` | Utilisez plutôt `merge_request_access_level`. |
| `snippets_enabled` | Utilisez plutôt `snippets_access_level`. |
| `wiki_enabled` | Utilisez plutôt `wiki_access_level`. |
| `restrict_user_defined_variables` | [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154510) dans GitLab 17.7. Utilisez plutôt `ci_pipeline_variables_minimum_override_role`. |

## Récupérer un projet {#retrieve-a-project}

{{< history >}}

- `mr_default_title_template` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) dans GitLab 18.11 [avec un feature flag](../administration/feature_flags/_index.md) nommé `mr_default_title_template`. Désactivé par défaut.
- Le feature flag `mr_default_title_template` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642) dans GitLab 19.0.

{{< /history >}}

Récupère le projet spécifié. Cet endpoint est accessible sans authentification si le projet est accessible publiquement.

```plaintext
GET /projects/:id
```

Attributs pris en charge :

| Attribut                | Type              | Obligatoire | Description |
|:-------------------------|:------------------|:---------|:------------|
| `id`                     | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `license`                | boolean           | Non       | Inclure les données de licence du projet. |
| `statistics`             | boolean           | Non       | Inclure les statistiques du projet. Disponible uniquement pour les utilisateurs ayant le rôle Reporter, Developer, Maintainer ou Owner. |
| `with_custom_attributes` | boolean           | Non       | Inclure les [attributs personnalisés](custom_attributes.md) dans la réponse. Accès administrateur. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                | Type              | Description |
|:-------------------------|:------------------|:------------|
| `id` | integer | ID du projet. |
| `description` | string | Description du projet. |
| `description_html` | string | Description du projet au format HTML. |
| `name` | string | Nom du projet. |
| `name_with_namespace` | string | Nom du projet avec son espace de nommage. |
| `path` | string | Chemin du projet. |
| `path_with_namespace` | string | Chemin du projet avec son espace de nommage. |
| `created_at` | datetime | Horodatage de la création du projet. |
| `default_branch` | string | Branche par défaut du projet. |
| `tag_list` | tableau de chaînes de caractères | Déprécié. Utilisez plutôt `topics`. Liste des tags du projet. |
| `topics` | tableau de chaînes de caractères | Liste des topics du projet. |
| `ssh_url_to_repo` | string | URL SSH pour cloner le dépôt. |
| `http_url_to_repo` | string | URL HTTP pour cloner le dépôt. |
| `web_url` | string | URL pour accéder au projet dans un navigateur. |
| `readme_url` | string | URL vers le fichier README du projet. |
| `forks_count` | integer | Nombre de duplications du projet. |
| `avatar_url` | string | URL vers l'image d'avatar du projet. |
| `star_count` | integer | Nombre d'étoiles reçues par le projet. |
| `last_activity_at` | datetime | Horodatage de la dernière activité dans le projet. |
| `visibility` | string | Niveau de visibilité du projet. Valeurs possibles : `private`, `internal` ou `public`. |
| `namespace` | objet | Informations sur l'espace de nommage du projet. |
| `namespace.id` | integer | ID de l'espace de nommage. |
| `namespace.name` | string | Nom de l'espace de nommage. |
| `namespace.path` | string | Chemin de l'espace de nommage. |
| `namespace.kind` | string | Type d'espace de nommage. Valeurs possibles : `user` ou `group`. |
| `namespace.full_path` | string | Chemin complet de l'espace de nommage. |
| `namespace.parent_id` | integer | ID de l'espace de nommage parent, le cas échéant. |
| `namespace.avatar_url` | string | URL vers l'image d'avatar de l'espace de nommage. |
| `namespace.web_url` | string | URL pour accéder à l'espace de nommage dans un navigateur. |
| `container_registry_image_prefix` | string | Préfixe pour les images du registre de conteneurs. |
| `_links` | objet | Ensemble de liens d'endpoints d'API liés au projet. |
| `_links.self` | string | URL vers la ressource du projet. |
| `_links.issues` | string | URL vers les tickets du projet. |
| `_links.merge_requests` | string | URL vers les merge requests du projet. |
| `_links.repo_branches` | string | URL vers les branches du dépôt du projet. |
| `_links.labels` | string | URL vers les labels du projet. |
| `_links.events` | string | URL vers les événements du projet. |
| `_links.members` | string | URL vers les membres du projet. |
| `_links.cluster_agents` | string | URL vers les agents de cluster du projet. |
| `marked_for_deletion_at` | date | Déprécié. Utilisez plutôt `marked_for_deletion_on`. Date à laquelle le projet est programmé pour la suppression. |
| `marked_for_deletion_on` | date | Date à laquelle le projet est programmé pour la suppression. |
| `packages_enabled` | boolean | Indique si le registre de paquets est activé pour le projet. |
| `empty_repo` | boolean | Indique si le dépôt est vide. |
| `archived` | boolean | Indique si le projet est archivé. |
| `owner` | objet | Informations sur le propriétaire du projet. |
| `owner.id` | integer | ID du propriétaire (Owner) du projet. |
| `owner.username` | string | Nom d'utilisateur du propriétaire. |
| `owner.public_email` | string | Adresse e-mail publique du propriétaire. |
| `owner.name` | string | Nom du propriétaire (Owner) du projet. |
| `owner.state` | string | État actuel du compte du propriétaire. |
| `owner.locked` | boolean | Indique si le compte du propriétaire est verrouillé. |
| `owner.avatar_url` | string | URL vers l'image d'avatar du propriétaire. |
| `owner.web_url` | string | URL web du profil du propriétaire. |
| `owner.created_at` | datetime | Horodatage de la création du propriétaire (Owner). |
| `resolve_outdated_diff_discussions` | boolean | Indique si les discussions sur les diffs obsolètes sont automatiquement résolues. |
| `container_expiration_policy` | objet | Paramètres de la politique d'expiration des images de conteneur. |
| `container_expiration_policy.cadence` | string | Fréquence d'exécution de la politique d'expiration des conteneurs. |
| `container_expiration_policy.enabled` | boolean | Indique si la politique d'expiration des conteneurs est activée. |
| `container_expiration_policy.keep_n` | integer | Nombre d'images de conteneur à conserver. |
| `container_expiration_policy.older_than` | string | Supprimer les images de conteneur plus anciennes que cette valeur. |
| `container_expiration_policy.name_regex` | string | Déprécié. Utilisez plutôt `name_regex_delete`. Expression régulière pour correspondre aux noms des images de conteneur. |
| `container_expiration_policy.name_regex_delete` | string | Expression régulière pour correspondre aux noms des images de conteneur à supprimer. |
| `container_expiration_policy.name_regex_keep` | string | Expression régulière pour correspondre aux noms des images de conteneur à conserver. |
| `container_expiration_policy.next_run_at` | datetime | Horodatage de la prochaine exécution planifiée de la politique. |
| `repository_object_format` | string | Format d'objet utilisé par le dépôt. Valeurs possibles : `sha1` ou `sha256`. |
| `issues_enabled` | boolean | Indique si les tickets sont activés pour le projet. |
| `merge_requests_enabled` | boolean | Indique si les merge requests sont activées pour le projet. |
| `wiki_enabled` | boolean | Indique si le wiki est activé pour le projet. |
| `jobs_enabled` | boolean | Indique si les jobs sont activés pour le projet. |
| `snippets_enabled` | boolean | Indique si les extraits de code sont activés pour le projet. |
| `container_registry_enabled` | boolean | Déprécié. Utilisez plutôt `container_registry_access_level`. Indique si le registre de conteneurs est activé. |
| `service_desk_enabled` | boolean | Indique si Service Desk est activé pour le projet. |
| `service_desk_address` | string | Adresse e-mail pour Service Desk. |
| `can_create_merge_request_in` | boolean | Indique si l'utilisateur actuel peut créer des merge requests dans le projet. |
| `issues_access_level` | string | Niveau d'accès pour la fonctionnalité des tickets. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `repository_access_level` | string | Niveau d'accès pour la fonctionnalité du dépôt. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `merge_requests_access_level` | string | Niveau d'accès pour la fonctionnalité des merge requests. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `forking_access_level` | string | Niveau d'accès pour la duplication du projet. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `wiki_access_level` | string | Niveau d'accès pour la fonctionnalité wiki. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `builds_access_level` | string | Niveau d'accès pour la fonctionnalité de builds CI/CD. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `snippets_access_level` | string | Niveau d'accès pour la fonctionnalité des extraits de code. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `pages_access_level` | string | Niveau d'accès pour GitLab Pages. Valeurs possibles : `disabled`, `private`, `enabled` ou `public`. |
| `analytics_access_level` | string | Niveau d'accès pour les fonctionnalités d'analyse. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `container_registry_access_level` | string | Niveau d'accès pour le registre de conteneurs. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `security_and_compliance_access_level` | string | Niveau d'accès pour les fonctionnalités de sécurité et de conformité. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `releases_access_level` | string | Niveau d'accès pour la fonctionnalité des releases. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `environments_access_level` | string | Niveau d'accès pour la fonctionnalité des environnements. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `feature_flags_access_level` | string | Niveau d'accès pour la fonctionnalité des feature flags. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `infrastructure_access_level` | string | Niveau d'accès pour la fonctionnalité d'infrastructure. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `monitor_access_level` | string | Niveau d'accès pour la fonctionnalité de surveillance. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `model_experiments_access_level` | string | Niveau d'accès pour la fonctionnalité des expériences de modèles. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `model_registry_access_level` | string | Niveau d'accès pour la fonctionnalité du registre de modèles. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `package_registry_access_level` | string | Niveau d'accès pour la fonctionnalité du registre de paquets. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `emails_disabled` | boolean | Indique si les e-mails sont désactivés pour le projet. |
| `emails_enabled` | boolean | Indique si les e-mails sont activés pour le projet. |
| `show_diff_preview_in_email` | boolean | Indique si les aperçus de diff sont affichés dans les notifications par e-mail. |
| `shared_runners_enabled` | boolean | Indique si les runners partagés sont activés pour le projet. |
| `lfs_enabled` | boolean | Indique si Git LFS est activé pour le projet. |
| `creator_id` | integer | ID de l'utilisateur qui a créé le projet. |
| `import_url` | string | URL depuis laquelle le projet a été importé. |
| `import_type` | string | Type d'import utilisé pour le projet. |
| `import_status` | string | Statut de l'import du projet. |
| `import_error` | string | Message d'erreur si l'import a échoué. |
| `open_issues_count` | integer | Nombre de tickets ouverts. |
| `updated_at` | datetime | Horodatage de la dernière mise à jour du projet. |
| `ci_default_git_depth` | integer | Profondeur Git par défaut pour les pipelines CI/CD. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_delete_pipelines_in_seconds` | integer | Durée en secondes avant la suppression des anciens pipelines. |
| `ci_forward_deployment_enabled` | boolean | Indique si le déploiement en avant est activé. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_forward_deployment_rollback_allowed` | boolean | Indique si la restauration est autorisée pour les déploiements en avant. |
| `ci_job_token_scope_enabled` | boolean | Indique si la portée du token de job CI/CD est activée. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_separated_caches` | boolean | Indique si les caches CI/CD sont séparés par branche. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | boolean | Indique si les pipelines de fork peuvent s'exécuter dans le projet parent. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_id_token_sub_claim_components` | tableau de chaînes de caractères | Composants inclus dans le claim subject du token ID CI/CD. |
| `build_git_strategy` | string | Stratégie Git utilisée pour les builds CI/CD (fetch ou clone). Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `keep_latest_artifact` | boolean | Indique si le dernier artefact est conservé lors de la création d'un nouvel artefact. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `restrict_user_defined_variables` | boolean | Indique si les variables définies par l'utilisateur sont restreintes. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_pipeline_variables_minimum_override_role` | string | Rôle minimum requis pour remplacer les variables de pipeline. |
| `runner_token_expiration_interval` | integer | Intervalle d'expiration en secondes pour les tokens de runner. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `group_runners_enabled` | boolean | Indique si les runners de groupe sont activés pour le projet. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `resource_group_default_process_mode` | string | Mode de traitement par défaut pour les groupes de ressources. |
| `auto_cancel_pending_pipelines` | string | Paramètre pour l'annulation automatique des pipelines en attente. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `build_timeout` | integer | Délai d'attente en secondes pour les jobs CI/CD. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `auto_devops_enabled` | boolean | Indique si Auto DevOps est activé pour le projet. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `auto_devops_deploy_strategy` | string | Stratégie de déploiement pour Auto DevOps. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_push_repository_for_job_token_allowed` | boolean | Indique si le push vers le dépôt est autorisé à l'aide d'un token de job. |
| `runners_token` | string | Token pour enregistrer des runners auprès du projet. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_config_path` | string | Chemin vers le fichier de configuration CI/CD. |
| `public_jobs` | boolean | Indique si les job logs sont accessibles publiquement. |
| `shared_with_groups` | tableau d'objets | Liste des groupes avec lesquels le projet est partagé. |
| `shared_with_groups[].group_id` | integer | ID du groupe avec lequel le projet est partagé. |
| `shared_with_groups[].group_name` | string | Nom du groupe avec lequel le projet est partagé. |
| `shared_with_groups[].group_full_path` | string | Chemin complet du groupe avec lequel le projet est partagé. |
| `shared_with_groups[].group_access_level` | integer | Niveau d'accès accordé au groupe. |
| `only_allow_merge_if_pipeline_succeeds` | boolean | Indique si les fusions sont autorisées uniquement si le pipeline réussit. |
| `allow_merge_on_skipped_pipeline` | boolean | Indique si les fusions sont autorisées lorsque le pipeline est ignoré. |
| `request_access_enabled` | boolean | Indique si les utilisateurs peuvent demander l'accès au projet. |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | Indique si les fusions sont autorisées uniquement si toutes les discussions sont résolues. |
| `remove_source_branch_after_merge` | boolean | Indique si la branche source est automatiquement supprimée après la fusion. |
| `printing_merge_request_link_enabled` | boolean | Indique si les liens de merge request sont affichés après un push. |
| `printing_merge_requests_link_enabled` | boolean | Indique si le lien de merge request est affiché après un push. |
| `merge_method` | string | Méthode de fusion utilisée pour le projet. Valeurs possibles : `merge`, `rebase_merge` ou `ff`. |
| `merge_request_title_regex` | string | Modèle d'expression régulière pour la validation des titres de merge request. |
| `merge_request_title_regex_description` | string | Description de la validation du titre de merge request par expression régulière. |
| `squash_option` | string | Option de squash pour les merge requests. |
| `enforce_auth_checks_on_uploads` | boolean | Indique si les vérifications d'authentification sont appliquées lors des uploads. |
| `suggestion_commit_message` | string | Message de commit personnalisé pour les suggestions. |
| `merge_commit_template` | string | Modèle pour les messages de commit de fusion. |
| `mr_default_title_template` | string | Modèle pour les titres de merge request. |
| `squash_commit_template` | string | Modèle pour les messages de commit de squash. |
| `issue_branch_template` | string | Modèle pour les noms de branches créées à partir de tickets. |
| `warn_about_potentially_unwanted_characters` | boolean | Indique si un avertissement est émis pour les caractères potentiellement indésirables. |
| `autoclose_referenced_issues` | boolean | Indique si les tickets référencés sont automatiquement fermés. |
| `max_artifacts_size` | integer | Taille maximale en Mo pour les artefacts de job CI/CD. |
| `approvals_before_merge` | integer | Déprécié. Utilisez plutôt l'API Merge request approvals. Nombre d'approbations requises avant la fusion. |
| `mirror` | boolean | Indique si le projet est un miroir. |
| `external_authorization_classification_label` | string | Label de classification d'autorisation externe. |
| `requirements_enabled` | boolean | Indique si la gestion des exigences est activée. |
| `requirements_access_level` | string | Niveau d'accès pour la fonctionnalité des exigences. |
| `security_and_compliance_enabled` | boolean | Indique si les fonctionnalités de sécurité et de conformité sont activées. |
| `secret_push_protection_enabled` | boolean | Indique si la protection contre les pushs de secrets est activée. |
| `pre_receive_secret_detection_enabled` | boolean | Indique si la détection des secrets pré-réception est activée. |
| `compliance_frameworks` | tableau de chaînes de caractères | Cadres de conformité appliqués au projet. |
| `issues_template` | string | Description par défaut pour les tickets. La description est analysée avec GitLab Flavored Markdown. Premium et Ultimate uniquement. |
| `merge_requests_template` | string | Modèle pour les descriptions de merge request. Premium et Ultimate uniquement. |
| `ci_restrict_pipeline_cancellation_role` | string | Rôle minimum requis pour annuler des pipelines. |
| `merge_pipelines_enabled` | boolean | Indique si les pipelines de fusion sont activés. |
| `merge_trains_enabled` | boolean | Indique si les merge trains sont activés. |
| `merge_trains_skip_train_allowed` | boolean | Indique si l'omission du merge train est autorisée. |
| `max_pipelines_per_merge_train` | integer | Nombre maximum de pipelines parallèles par merge train. |
| `only_allow_merge_if_all_status_checks_passed` | boolean | Indique si les fusions sont autorisées uniquement si tous les contrôles de statut ont réussi. Ultimate uniquement. |
| `allow_pipeline_trigger_approve_deployment` | boolean | Indique si les déclencheurs de pipeline peuvent approuver des déploiements. |
| `prevent_merge_without_jira_issue` | boolean | Indique si les fusions nécessitent un ticket Jira associé. |
| `duo_remote_flows_enabled` | boolean | Indique si les flows distants GitLab Duo sont activés. |
| `duo_foundational_flows_enabled` | boolean | Indique si les flows par défaut GitLab Duo sont activés. |
| `duo_sast_fp_detection_enabled` | boolean | Indique si la détection des faux positifs SAST de GitLab Duo est activée. |
| `duo_sast_vr_workflow_enabled` | boolean | Indique si le workflow de résolution des vulnérabilités SAST de GitLab Duo est activé. |
| `web_based_commit_signing_enabled` | boolean | Indique si la signature de commit via le web est activée. |
| `spp_repository_pipeline_access` | boolean | Accès au pipeline du dépôt pour les politiques de sécurité. Visible uniquement si la fonctionnalité de politiques d'orchestration de sécurité est disponible. |
| `permissions` | objet | Permissions de l'utilisateur pour le projet. |
| `permissions.project_access` | objet | Permissions d'accès au niveau du projet pour l'utilisateur. |
| `permissions.project_access.access_level` | integer | Niveau d'accès pour le projet. |
| `permissions.project_access.notification_level` | integer | Niveau de notification pour le projet. |
| `permissions.group_access` | objet | Permissions d'accès au niveau du groupe pour l'utilisateur. |
| `permissions.group_access.access_level` | integer | Niveau d'accès pour le groupe. |
| `permissions.group_access.notification_level` | integer | Niveau de notification pour le groupe. |
| `license_url` | string | URL vers le fichier de licence du projet. |
| `license.key` | string | Identifiant clé de la licence. |
| `license.name` | string | Nom complet de la licence. |
| `license.nickname` | string | Surnom de la licence. |
| `license.html_url` | string | URL pour consulter les détails de la licence. |
| `license.source_url` | string | URL vers le texte source de la licence. |
| `repository_storage` | string | Emplacement de stockage du dépôt du projet. |
| `mirror_user_id` | integer | ID de l'utilisateur qui a configuré le miroir. |
| `mirror_trigger_builds` | boolean | Indique si les mises à jour du miroir déclenchent des builds. |
| `only_mirror_protected_branches` | boolean | Indique si seules les branches protégées sont mises en miroir. |
| `mirror_overwrites_diverged_branches` | boolean | Indique si le miroir écrase les branches divergentes. |
| `statistics.commit_count` | integer | Nombre de commits dans le projet. |
| `statistics.storage_size` | integer | Taille totale de stockage en octets. |
| `statistics.repository_size` | integer | Taille de stockage du dépôt en octets. |
| `statistics.wiki_size` | integer | Taille de stockage du wiki en octets. |
| `statistics.lfs_objects_size` | integer | Taille de stockage des objets LFS en octets. |
| `statistics.job_artifacts_size` | integer | Taille de stockage des artefacts de job en octets. |
| `statistics.pipeline_artifacts_size` | integer | Taille de stockage des artefacts de pipeline en octets. |
| `statistics.packages_size` | integer | Taille de stockage des paquets en octets. |
| `statistics.snippets_size` | integer | Taille de stockage des extraits de code en octets. |
| `statistics.uploads_size` | integer | Taille de stockage des uploads en octets. |
| `statistics.container_registry_size` | integer | Taille de stockage du registre de conteneurs en octets. <sup>1</sup> |
| `forked_from_project` | objet | Le projet en amont dont ce projet a été dupliqué. Si le projet en amont est privé, un token d'authentification est requis pour consulter ce champ. |
| `mr_default_target_self` | boolean | Indique si les merge requests ciblent ce projet par défaut. Si `false`, les merge requests ciblent le projet en amont. Apparaît uniquement si le projet est une duplication. |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>"
```

Exemple de réponse :

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "container_expiration_policy": {
    "cadence": "7d",
    "enabled": false,
    "keep_n": null,
    "older_than": null,
    "name_regex": null, // to be deprecated in GitLab 13.0 in favor of `name_regex_delete`
    "name_regex_delete": null,
    "name_regex_keep": null,
    "next_run_at": "2020-01-07T21:42:58.658Z"
  },
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora",
    "avatar_url": "http://localhost:3000/uploads/group/avatar/3/foo.jpg",
    "web_url": "http://localhost:3000/groups/diaspora"
  },
  "import_url": null,
  "import_type": null,
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": false,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "ci_display_pipeline_variables": false,
  "protect_merge_request_pipelines": true,
  "public_jobs": true,
  "shared_with_groups": [
    {
      "group_id": 4,
      "group_name": "Twitter",
      "group_full_path": "twitter",
      "group_access_level": 30
    },
    {
      "group_id": 3,
      "group_name": "Gitlab Org",
      "group_full_path": "gitlab-org",
      "group_access_level": 10
    }
  ],
  "repository_storage": "default",
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "allow_pipeline_trigger_approve_deployment": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "printing_merge_requests_link_enabled": true,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "auto_devops_enabled": true,
  "auto_devops_deploy_strategy": "continuous",
  "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
  "mirror": false,
  "mirror_user_id": 45,
  "mirror_trigger_builds": false,
  "only_mirror_protected_branches": false,
  "mirror_overwrites_diverged_branches": false,
  "external_authorization_classification_label": null,
  "packages_enabled": true,
  "empty_repo": false,
  "service_desk_enabled": false,
  "service_desk_address": null,
  "autoclose_referenced_issues": true,
  "suggestion_commit_message": null,
  "enforce_auth_checks_on_uploads": true,
  "merge_commit_template": null,
  "mr_default_title_template": null,
  "squash_commit_template": null,
  "issue_branch_template": "gitlab/%{id}-%{title}",
  "marked_for_deletion_at": "2020-04-03", // Deprecated in favor of marked_for_deletion_on. Planned for removal in a future version of the REST API.
  "marked_for_deletion_on": "2020-04-03",
  "compliance_frameworks": [ "sox" ],
  "warn_about_potentially_unwanted_characters": true,
  "secret_push_protection_enabled": false,
  "statistics": {
    "commit_count": 37,
    "storage_size": 1038090,
    "repository_size": 1038090,
    "wiki_size" : 0,
    "lfs_objects_size": 0,
    "job_artifacts_size": 0,
    "pipeline_artifacts_size": 0,
    "packages_size": 0,
    "snippets_size": 0,
    "uploads_size": 0,
    "container_registry_size": 0
  },
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  },
  "spp_repository_pipeline_access": false // Only visible if the security_orchestration_policies feature is available
}
```

## Lister les projets {#list-projects}

Lister les projets et les attributs des projets.

### Lister tous les projets {#list-all-projects}

{{< history >}}

- `web_based_commit_signing_enabled` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194650) dans GitLab 18.2 [avec un flag](../administration/feature_flags/_index.md) nommé `use_web_based_commit_signing_enabled`. Désactivé par défaut.
- `mr_default_title_template` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) dans GitLab 18.11 [avec un feature flag](../administration/feature_flags/_index.md) nommé `mr_default_title_template`. Désactivé par défaut.
- Le feature flag `mr_default_title_template` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642) dans GitLab 19.0.

{{< /history >}}

> [!flag]
> La disponibilité de l'attribut `web_based_commit_signing_enabled` est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

Liste tous les projets de l'instance accessibles à l'utilisateur authentifié. Les requêtes non authentifiées renvoient uniquement les projets publics avec un sous-ensemble limité d'attributs.

Vous pouvez filtrer les réponses par [attributs personnalisés](custom_attributes.md).

Cet endpoint prend en charge la pagination :

- Utilisez la pagination par décalage pour accéder à jusqu'à 50 000 projets.
- Utilisez la pagination par jeu de clés pour lister plus de 50 000 projets.

Pour plus d'informations, consultez [Pagination](rest/_index.md#pagination).

```plaintext
GET /projects
```

Attributs pris en charge :

| Attribut                     | Type     | Obligatoire | Description |
|:------------------------------|:---------|:---------|:------------|
| `archived`                    | boolean  | Non       | Filtrer par statut archivé. |
| `id_after`                    | integer  | Non       | Limiter les résultats aux projets dont les ID sont supérieurs à l'ID spécifié. |
| `id_before`                   | integer  | Non       | Limiter les résultats aux projets dont les ID sont inférieurs à l'ID spécifié. |
| `imported`                    | boolean  | Non       | Limiter les résultats aux projets importés depuis des systèmes externes par l'utilisateur actuel. |
| `include_hidden`              | boolean  | Non       | Inclure les projets cachés. _(administrateurs uniquement)_ Premium et Ultimate uniquement. |
| `include_pending_delete`      | boolean  | Non       | Inclure les projets en attente de suppression. _(administrateurs uniquement)_ |
| `last_activity_after`         | datetime | Non       | Limiter les résultats aux projets dont la dernière activité est postérieure à l'heure spécifiée. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |
| `last_activity_before`        | datetime | Non       | Limiter les résultats aux projets dont la dernière activité est antérieure à l'heure spécifiée. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |
| `membership`                  | boolean  | Non       | Filtrer par projets dont l'utilisateur actuel est membre. |
| `min_access_level`            | integer  | Non       | Limiter aux projets où l'utilisateur actuel dispose au moins du niveau d'accès spécifié. Valeurs possibles : `5` (Accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `order_by`                    | string   | Non       | Renvoyer les projets classés par les champs `id`, `name`, `path`, `created_at`, `updated_at`, `star_count`, `last_activity_at` ou `similarity`. Les champs `repository_size`, `storage_size`, `packages_size` ou `wiki_size` sont réservés aux administrateurs. `similarity` est disponible uniquement lors d'une recherche et est limité aux projets dont l'utilisateur actuel est membre. La valeur par défaut est `created_at`. |
| `owned`                       | boolean  | Non       | Filtrer par projets explicitement détenus par l'utilisateur actuel. |
| `repository_checksum_failed`  | boolean  | Non       | Limiter aux projets pour lesquels le calcul de la somme de contrôle du dépôt a échoué. Premium et Ultimate uniquement. |
| `repository_storage`          | string   | Non       | Limiter les résultats aux projets stockés sur `repository_storage`. _(administrateurs uniquement)_ |
| `search_namespaces`           | boolean  | Non       | Inclure les espaces de nommage ancêtres lors de la correspondance avec les critères de recherche. La valeur par défaut est `false`. |
| `search`                      | string   | Non       | Renvoyer la liste des projets dont le `path`, le `name` ou la `description` correspondent aux critères de recherche (insensible à la casse, correspondance de sous-chaîne). Plusieurs termes peuvent être fournis, séparés par un espace échappé, soit `+` soit `%20`, et seront combinés avec l'opérateur AND. Exemple : `one+two` correspondra aux sous-chaînes `one` et `two` (dans n'importe quel ordre). |
| `simple`                      | boolean  | Non       | Si `true`, renvoyer uniquement les champs limités pour chaque projet. Les requêtes non authentifiées renvoient uniquement les projets publics avec des champs limités, même si `simple` n'est pas défini. |
| `sort`                        | string   | Non       | Renvoyer les projets triés dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`. |
| `starred`                     | boolean  | Non       | Filtrer par projets mis en favori par l'utilisateur actuel. |
| `statistics`                  | boolean  | Non       | Inclure les statistiques du projet. Disponible uniquement pour les utilisateurs ayant le rôle Reporter, Developer, Maintainer ou Owner. |
| `topic_id`                    | integer  | Non       | Limiter les résultats aux projets avec le topic assigné correspondant à l'ID de topic donné. |
| `topic`                       | string   | Non       | Noms de topics séparés par des virgules. Limiter les résultats aux projets qui correspondent à tous les topics donnés. Voir l'attribut `topics`. |
| `updated_after`               | datetime | Non       | Limiter les résultats aux projets mis à jour après l'heure spécifiée. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) dans GitLab 15.10. Pour que ce filtre fonctionne, vous devez également fournir `updated_at` comme attribut `order_by`. |
| `updated_before`              | datetime | Non       | Limiter les résultats aux projets mis à jour avant l'heure spécifiée. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) dans GitLab 15.10. Pour que ce filtre fonctionne, vous devez également fournir `updated_at` comme attribut `order_by`. |
| `visibility`                  | string   | Non       | Filtrer par visibilité `public`, `internal` ou `private`. |
| `wiki_checksum_failed`        | boolean  | Non       | Limiter aux projets pour lesquels le calcul de la somme de contrôle du wiki a échoué. Premium et Ultimate uniquement. |
| `with_custom_attributes`      | boolean  | Non       | Inclure les [attributs personnalisés](custom_attributes.md) dans la réponse. _(administrateur uniquement)_ |
| `with_issues_enabled`         | boolean  | Non       | Filtrer par fonctionnalité de tickets activée. |
| `with_merge_requests_enabled` | boolean  | Non       | Filtrer par fonctionnalité de merge requests activée. |
| `with_programming_language`   | string   | Non       | Filtrer par projets utilisant le langage de programmation donné. |
| `marked_for_deletion_on`      | date     | Non       | Filtrer par date à laquelle le projet a été marqué pour suppression. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/463939) dans GitLab 17.1. Premium et Ultimate uniquement. |
| `active`                      | boolean  | Non       | Filtrer par projets qui ne sont pas archivés et non marqués pour suppression. |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type | Description |
|-----------|------|-------------|
| `id` | integer | ID du projet. |
| `description` | string | Description du projet. |
| `name` | string | Nom du projet. |
| `name_with_namespace` | string | Nom du projet avec son espace de nommage. |
| `path` | string | Chemin du projet. |
| `path_with_namespace` | string | Chemin du projet avec son espace de nommage. |
| `created_at` | datetime | Horodatage de la création du projet. |
| `default_branch` | string | Branche par défaut du projet. |
| `tag_list` | tableau de chaînes de caractères | Déprécié. Utilisez plutôt `topics`. Liste des tags du projet. |
| `topics` | tableau de chaînes de caractères | Liste des topics du projet. |
| `ssh_url_to_repo` | string | URL SSH pour cloner le dépôt. |
| `http_url_to_repo` | string | URL HTTP pour cloner le dépôt. |
| `web_url` | string | URL pour accéder au projet dans un navigateur. |
| `readme_url` | string | URL vers le fichier README du projet. |
| `forks_count` | integer | Nombre de duplications du projet. |
| `avatar_url` | string | URL vers l'image d'avatar du projet. |
| `star_count` | integer | Nombre d'étoiles reçues par le projet. |
| `last_activity_at` | datetime | Horodatage de la dernière activité dans le projet. |
| `visibility` | string | Niveau de visibilité du projet. Valeurs possibles : `private`, `internal` ou `public`. |
| `namespace` | objet | Informations sur l'espace de nommage du projet. |
| `namespace.id` | integer | ID de l'espace de nommage. |
| `namespace.name` | string | Nom de l'espace de nommage. |
| `namespace.path` | string | Chemin de l'espace de nommage. |
| `namespace.kind` | string | Type d'espace de nommage. Valeurs possibles : `user` ou `group`. |
| `namespace.full_path` | string | Chemin complet de l'espace de nommage. |
| `namespace.parent_id` | integer | ID de l'espace de nommage parent, le cas échéant. |
| `namespace.avatar_url` | string | URL vers l'image d'avatar de l'espace de nommage. |
| `namespace.web_url` | string | URL pour accéder à l'espace de nommage dans un navigateur. |
| `container_registry_image_prefix` | string | Préfixe pour les images du registre de conteneurs. |
| `_links` | objet | Ensemble de liens d'endpoints d'API liés au projet. |
| `_links.self` | string | URL vers la ressource du projet. |
| `_links.issues` | string | URL vers les tickets du projet. |
| `_links.merge_requests` | string | URL vers les merge requests du projet. |
| `_links.repo_branches` | string | URL vers les branches du dépôt du projet. |
| `_links.labels` | string | URL vers les labels du projet. |
| `_links.events` | string | URL vers les événements du projet. |
| `_links.members` | string | URL vers les membres du projet. |
| `_links.cluster_agents` | string | URL vers les agents de cluster du projet. |
| `marked_for_deletion_at` | date | Déprécié. Utilisez plutôt `marked_for_deletion_on`. Date à laquelle le projet est programmé pour la suppression. |
| `marked_for_deletion_on` | date | Date à laquelle le projet est programmé pour la suppression. |
| `packages_enabled` | boolean | Indique si le registre de paquets est activé pour le projet. |
| `empty_repo` | boolean | Indique si le dépôt est vide. |
| `archived` | boolean | Indique si le projet est archivé. |
| `resolve_outdated_diff_discussions` | boolean | Indique si les discussions sur les diffs obsolètes sont automatiquement résolues. |
| `container_expiration_policy` | objet | Paramètres de la politique d'expiration des images de conteneur. |
| `container_expiration_policy.cadence` | string | Fréquence d'exécution de la politique d'expiration des conteneurs. |
| `container_expiration_policy.enabled` | boolean | Indique si la politique d'expiration des conteneurs est activée. |
| `container_expiration_policy.keep_n` | integer | Nombre d'images de conteneur à conserver. |
| `container_expiration_policy.older_than` | string | Supprimer les images de conteneur plus anciennes que cette valeur. |
| `container_expiration_policy.name_regex` | string | Déprécié. Utilisez plutôt `name_regex_delete`. Expression régulière pour correspondre aux noms des images de conteneur. |
| `container_expiration_policy.name_regex_keep` | string | Expression régulière pour correspondre aux noms des images de conteneur à conserver. |
| `container_expiration_policy.next_run_at` | datetime | Horodatage de la prochaine exécution planifiée de la politique. |
| `repository_object_format` | string | Format d'objet utilisé par le dépôt (sha1 ou sha256). |
| `issues_enabled` | boolean | Indique si les tickets sont activés pour le projet. |
| `merge_requests_enabled` | boolean | Indique si les merge requests sont activées pour le projet. |
| `wiki_enabled` | boolean | Indique si le wiki est activé pour le projet. |
| `jobs_enabled` | boolean | Indique si les jobs sont activés pour le projet. |
| `snippets_enabled` | boolean | Indique si les extraits de code sont activés pour le projet. |
| `container_registry_enabled` | boolean | Déprécié. Utilisez plutôt `container_registry_access_level`. Indique si le registre de conteneurs est activé. |
| `service_desk_enabled` | boolean | Indique si Service Desk est activé pour le projet. |
| `can_create_merge_request_in` | boolean | Indique si l'utilisateur actuel peut créer des merge requests dans le projet. |
| `issues_access_level` | string | Niveau d'accès pour la fonctionnalité des tickets. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `repository_access_level` | string | Niveau d'accès pour la fonctionnalité du dépôt. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `merge_requests_access_level` | string | Niveau d'accès pour la fonctionnalité des merge requests. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `forking_access_level` | string | Niveau d'accès pour la duplication du projet. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `wiki_access_level` | string | Niveau d'accès pour la fonctionnalité wiki. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `builds_access_level` | string | Niveau d'accès pour la fonctionnalité de builds CI/CD. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `snippets_access_level` | string | Niveau d'accès pour la fonctionnalité des extraits de code. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `pages_access_level` | string | Niveau d'accès pour GitLab Pages. Valeurs possibles : `disabled`, `private`, `enabled` ou `public`. |
| `analytics_access_level` | string | Niveau d'accès pour les fonctionnalités d'analyse. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `container_registry_access_level` | string | Niveau d'accès pour le registre de conteneurs. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `security_and_compliance_access_level` | string | Niveau d'accès pour les fonctionnalités de sécurité et de conformité. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `releases_access_level` | string | Niveau d'accès pour la fonctionnalité des releases. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `environments_access_level` | string | Niveau d'accès pour la fonctionnalité des environnements. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `feature_flags_access_level` | string | Niveau d'accès pour la fonctionnalité des feature flags. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `infrastructure_access_level` | string | Niveau d'accès pour la fonctionnalité d'infrastructure. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `monitor_access_level` | string | Niveau d'accès pour la fonctionnalité de surveillance. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `model_experiments_access_level` | string | Niveau d'accès pour la fonctionnalité des expériences de modèles. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `model_registry_access_level` | string | Niveau d'accès pour la fonctionnalité du registre de modèles. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `package_registry_access_level` | string | Niveau d'accès pour la fonctionnalité du registre de paquets. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `emails_disabled` | boolean | Indique si les e-mails sont désactivés pour le projet. |
| `emails_enabled` | boolean | Indique si les e-mails sont activés pour le projet. |
| `show_diff_preview_in_email` | boolean | Indique si les aperçus de diff sont affichés dans les notifications par e-mail. |
| `shared_runners_enabled` | boolean | Indique si les runners partagés sont activés pour le projet. |
| `lfs_enabled` | boolean | Indique si Git LFS est activé pour le projet. |
| `creator_id` | integer | ID de l'utilisateur qui a créé le projet. |
| `import_status` | string | Statut de l'import du projet. |
| `open_issues_count` | integer | Nombre de tickets ouverts. |
| `description_html` | string | Description du projet au format HTML. |
| `updated_at` | datetime | Horodatage de la dernière mise à jour du projet. |
| `ci_config_path` | string | Chemin vers le fichier de configuration CI/CD. |
| `public_jobs` | boolean | Indique si les job logs sont accessibles publiquement. |
| `shared_with_groups` | tableau d'objets | Liste des groupes avec lesquels le projet est partagé. |
| `only_allow_merge_if_pipeline_succeeds` | boolean | Indique si les fusions sont autorisées uniquement si le pipeline réussit. |
| `allow_merge_on_skipped_pipeline` | boolean | Indique si les fusions sont autorisées lorsque le pipeline est ignoré. |
| `request_access_enabled` | boolean | Indique si les utilisateurs peuvent demander l'accès au projet. |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | Indique si les fusions sont autorisées uniquement si toutes les discussions sont résolues. |
| `remove_source_branch_after_merge` | boolean | Indique si la branche source est automatiquement supprimée après la fusion. |
| `printing_merge_request_link_enabled` | boolean | Indique si les liens de merge request sont affichés après un push. |
| `merge_method` | string | Méthode de fusion utilisée pour le projet. Valeurs possibles : `merge`, `rebase_merge` ou `ff`. |
| `merge_request_title_regex` | string | Modèle d'expression régulière pour la validation des titres de merge request. |
| `merge_request_title_regex_description` | string | Description de la validation du titre de merge request par expression régulière. |
| `squash_option` | string | Option de squash pour les merge requests. |
| `enforce_auth_checks_on_uploads` | boolean | Indique si les vérifications d'authentification sont appliquées lors des uploads. |
| `suggestion_commit_message` | string | Message de commit personnalisé pour les suggestions. |
| `merge_commit_template` | string | Modèle pour les messages de commit de fusion. |
| `mr_default_title_template` | string | Modèle pour les titres de merge request. |
| `squash_commit_template` | string | Modèle pour les messages de commit de squash. |
| `issue_branch_template` | string | Modèle pour les noms de branches créées à partir de tickets. |
| `warn_about_potentially_unwanted_characters` | boolean | Indique si un avertissement est émis pour les caractères potentiellement indésirables. |
| `autoclose_referenced_issues` | boolean | Indique si les tickets référencés sont automatiquement fermés. |
| `max_artifacts_size` | integer | Taille maximale en Mo pour les artefacts de job CI/CD. |
| `approvals_before_merge` | integer | Déprécié. Utilisez plutôt l'API Merge request approvals. Nombre d'approbations requises avant la fusion. |
| `mirror` | boolean | Indique si le projet est un miroir. |
| `external_authorization_classification_label` | string | Label de classification d'autorisation externe. |
| `requirements_enabled` | boolean | Indique si la gestion des exigences est activée. |
| `requirements_access_level` | string | Niveau d'accès pour la fonctionnalité des exigences. |
| `security_and_compliance_enabled` | boolean | Indique si les fonctionnalités de sécurité et de conformité sont activées. |
| `compliance_frameworks` | tableau de chaînes de caractères | Cadres de conformité appliqués au projet. |
| `issues_template` | string | Description par défaut pour les tickets. La description est analysée avec GitLab Flavored Markdown. Premium et Ultimate uniquement. |
| `merge_requests_template` | string | Modèle pour les descriptions de merge request. Premium et Ultimate uniquement. |
| `merge_pipelines_enabled` | boolean | Indique si les pipelines de fusion sont activés. |
| `merge_trains_enabled` | boolean | Indique si les merge trains sont activés. |
| `merge_trains_skip_train_allowed` | boolean | Indique si l'omission du merge train est autorisée. |
| `max_pipelines_per_merge_train` | integer | Nombre maximum de pipelines parallèles par merge train. |
| `only_allow_merge_if_all_status_checks_passed` | boolean | Indique si les fusions sont autorisées uniquement si tous les contrôles de statut ont réussi. Ultimate uniquement. |
| `allow_pipeline_trigger_approve_deployment` | boolean | Indique si les déclencheurs de pipeline peuvent approuver des déploiements. |
| `prevent_merge_without_jira_issue` | boolean | Indique si les fusions nécessitent un ticket Jira associé. |
| `duo_remote_flows_enabled` | boolean | Indique si les flows distants GitLab Duo sont activés. |
| `duo_foundational_flows_enabled` | boolean | Indique si les flows par défaut GitLab Duo sont activés. |
| `duo_sast_fp_detection_enabled` | boolean | Indique si la détection des faux positifs SAST de GitLab Duo est activée. |
| `duo_sast_vr_workflow_enabled` | boolean | Indique si le workflow de résolution des vulnérabilités SAST de GitLab Duo est activé. |
| `spp_repository_pipeline_access` | boolean | Accès au pipeline du dépôt pour les politiques de sécurité. Visible uniquement si la fonctionnalité de politiques d'orchestration de sécurité est disponible. |
| `permissions` | objet | Permissions de l'utilisateur pour le projet. |
| `permissions.project_access` | objet | Permissions d'accès au projet pour l'utilisateur. |
| `permissions.group_access` | objet | Permissions d'accès au groupe pour l'utilisateur. |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/projects"
```

Exemple de réponse :

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "default_branch": "main",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "ssh_url_to_repo": "git@gitlab.example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "https://gitlab.example.com/diaspora/diaspora-client.git",
    "web_url": "https://gitlab.example.com/diaspora/diaspora-client",
    "readme_url": "https://gitlab.example.com/diaspora/diaspora-client/blob/main/README.md",
    "avatar_url": "https://gitlab.example.com/uploads/project/avatar/4/uploads/avatar.png",
    "forks_count": 0,
    "star_count": 0,
    "last_activity_at": "2022-06-24T17:11:26.841Z",
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora",
      "parent_id": null,
      "avatar_url": "https://gitlab.example.com/uploads/project/avatar/6/uploads/avatar.png",
      "web_url": "https://gitlab.example.com/diaspora"
    },
    "container_registry_image_prefix": "registry.gitlab.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "https://gitlab.example.com/api/v4/projects/4",
      "issues": "https://gitlab.example.com/api/v4/projects/4/issues",
      "merge_requests": "https://gitlab.example.com/api/v4/projects/4/merge_requests",
      "repo_branches": "https://gitlab.example.com/api/v4/projects/4/repository/branches",
      "labels": "https://gitlab.example.com/api/v4/projects/4/labels",
      "events": "https://gitlab.example.com/api/v4/projects/4/events",
      "members": "https://gitlab.example.com/api/v4/projects/4/members",
      "cluster_agents": "https://gitlab.example.com/api/v4/projects/4/cluster_agents"
    },
    "packages_enabled": true, // deprecated, use package_registry_access_level instead
    "package_registry_access_level": "enabled",
    "empty_repo": false,
    "archived": false,
    "visibility": "public",
    "resolve_outdated_diff_discussions": false,
    "container_expiration_policy": {
      "cadence": "1month",
      "enabled": true,
      "keep_n": 1,
      "older_than": "14d",
      "name_regex": "",
      "name_regex_keep": ".*-main",
      "next_run_at": "2022-06-25T17:11:26.865Z"
    },
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": true,
    "jobs_enabled": true,
    "snippets_enabled": true,
    "container_registry_enabled": true,
    "service_desk_enabled": true,
    "can_create_merge_request_in": true,
    "issues_access_level": "enabled",
    "repository_access_level": "enabled",
    "merge_requests_access_level": "enabled",
    "forking_access_level": "enabled",
    "wiki_access_level": "enabled",
    "builds_access_level": "enabled",
    "snippets_access_level": "enabled",
    "pages_access_level": "enabled",
    "analytics_access_level": "enabled",
    "container_registry_access_level": "enabled",
    "security_and_compliance_access_level": "private",
    "emails_disabled": null,
    "emails_enabled": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "lfs_enabled": true,
    "creator_id": 1,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "open_issues_count": 0,
    "ci_default_git_depth": 20,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
    "ci_job_token_scope_enabled": false,
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "ci_display_pipeline_variables": false,
    "protect_merge_request_pipelines": true,
    "public_jobs": true,
    "build_timeout": 3600,
    "auto_cancel_pending_pipelines": "enabled",
    "ci_config_path": "",
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": null,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "request_access_enabled": true,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": true,
    "printing_merge_request_link_enabled": true,
    "merge_method": "merge",
    "squash_option": "default_off",
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "mr_default_title_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "auto_devops_enabled": false,
    "auto_devops_deploy_strategy": "continuous",
    "autoclose_referenced_issues": true,
    "keep_latest_artifact": true,
    "runner_token_expiration_interval": null,
    "external_authorization_classification_label": "",
    "requirements_enabled": false,
    "requirements_access_level": "enabled",
    "security_and_compliance_enabled": false,
    "secret_push_protection_enabled": false,
    "compliance_frameworks": [],
    "warn_about_potentially_unwanted_characters": true,
    "permissions": {
      "project_access": null,
      "group_access": null
    }
  },
  {
    ...
  }
]
```

> [!note]
> `last_activity_at` est mis à jour en fonction de l'[activité du projet](../user/project/working_with_projects.md#view-project-activity) et des [événements du projet](events.md). Pour optimiser les performances de la base de données, ce champ est mis à jour au maximum une fois par heure. Les événements survenant dans l'heure suivant la dernière mise à jour ne modifient pas l'horodatage. Par conséquent, `last_activity_at` peut être en retard d'une heure au maximum. `updated_at` est mis à jour chaque fois que l'enregistrement du projet est modifié dans la base de données.

### Lister tous les projets personnels d'un utilisateur {#list-all-personal-projects-for-a-user}

{{< history >}}

- `mr_default_title_template` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) dans GitLab 18.11 [avec un feature flag](../administration/feature_flags/_index.md) nommé `mr_default_title_template`. Désactivé par défaut.
- Le feature flag `mr_default_title_template` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642) dans GitLab 19.0.

{{< /history >}}

Liste tous les projets personnels d'un utilisateur spécifié. Les restrictions suivantes s'appliquent :

- Retourne uniquement les projets dans l'espace de nommage personnel de l'utilisateur, et non les projets de groupe ou de sous-groupe.
- Si le profil utilisateur est privé, retourne une liste vide.
- Les requêtes sans authentification retournent uniquement les projets publics.

Cet endpoint prend en charge la pagination :

- Utilisez la pagination par décalage pour accéder à jusqu'à 50 000 projets.
- Utilisez la pagination par jeu de clés pour lister plus de 50 000 projets.

Pour plus d'informations, consultez [Pagination](rest/_index.md#pagination).

```plaintext
GET /users/:user_id/projects
```

Attributs pris en charge :

| Attribut                     | Type     | Obligatoire | Description |
|:------------------------------|:---------|:---------|:------------|
| `user_id`                     | string   | Oui      | L'ID ou le nom d'utilisateur de l'utilisateur. |
| `archived`                    | boolean  | Non       | Filtrer par statut archivé. |
| `id_after`                    | integer  | Non       | Limiter les résultats aux projets dont les ID sont supérieurs à l'ID spécifié. |
| `id_before`                   | integer  | Non       | Limiter les résultats aux projets dont les ID sont inférieurs à l'ID spécifié. |
| `membership`                  | boolean  | Non       | Filtrer par projets dont l'utilisateur actuel est membre. |
| `min_access_level`            | integer  | Non       | Limiter aux projets où l'utilisateur actuel dispose au moins du niveau d'accès spécifié. Valeurs possibles : `5` (Accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `order_by`                    | string   | Non       | Retourner les projets triés par les champs `id`, `name`, `path`, `created_at`, `updated_at`, `star_count` ou `last_activity_at`. La valeur par défaut est `created_at`. |
| `owned`                       | boolean  | Non       | Filtrer par projets explicitement détenus par l'utilisateur actuel. |
| `search`                      | string   | Non       | Retourner la liste des projets correspondant aux critères de recherche. |
| `simple`                      | boolean  | Non       | Si `true`, renvoyer uniquement les champs limités pour chaque projet. Les requêtes non authentifiées renvoient uniquement les projets publics avec des champs limités, même si `simple` n'est pas défini. |
| `sort`                        | string   | Non       | Renvoyer les projets triés dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`. |
| `starred`                     | boolean  | Non       | Filtrer par projets mis en favori par l'utilisateur actuel. |
| `statistics`                  | boolean  | Non       | Inclure les statistiques du projet. Disponible uniquement pour les utilisateurs ayant le rôle Reporter, Developer, Maintainer ou Owner. |
| `updated_after`               | datetime | Non       | Limiter les résultats aux projets mis à jour après l'heure spécifiée. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `updated_before`              | datetime | Non       | Limiter les résultats aux projets mis à jour avant l'heure spécifiée. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `visibility`                  | string   | Non       | Filtrer par visibilité. Valeurs possibles : `public`, `internal` ou `private`. |
| `with_custom_attributes`      | boolean  | Non       | Inclure les [attributs personnalisés](custom_attributes.md) dans la réponse. Accès administrateur. |
| `with_issues_enabled`         | boolean  | Non       | Filtrer par fonctionnalité de tickets activée. |
| `with_merge_requests_enabled` | boolean  | Non       | Filtrer par fonctionnalité de merge requests activée. |
| `with_programming_language`   | string   | Non       | Filtrer par projets utilisant le langage de programmation donné. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type | Description |
|-----------|------|-------------|
| `id` | integer | ID du projet. |
| `description` | string | Description du projet. |
| `name` | string | Nom du projet. |
| `name_with_namespace` | string | Nom du projet avec son espace de nommage. |
| `path` | string | Chemin du projet. |
| `path_with_namespace` | string | Chemin du projet avec son espace de nommage. |
| `created_at` | datetime | Horodatage de la création du projet. |
| `default_branch` | string | Branche par défaut du projet. |
| `tag_list` | tableau de chaînes de caractères | Déprécié. Utilisez plutôt `topics`. Liste des tags du projet. |
| `topics` | tableau de chaînes de caractères | Liste des topics du projet. |
| `ssh_url_to_repo` | string | URL SSH pour cloner le dépôt. |
| `http_url_to_repo` | string | URL HTTP pour cloner le dépôt. |
| `web_url` | string | URL pour accéder au projet dans un navigateur. |
| `readme_url` | string | URL vers le fichier README du projet. |
| `forks_count` | integer | Nombre de duplications du projet. |
| `avatar_url` | string | URL vers l'image d'avatar du projet. |
| `star_count` | integer | Nombre d'étoiles reçues par le projet. |
| `last_activity_at` | datetime | Horodatage de la dernière activité dans le projet. |
| `visibility` | string | Niveau de visibilité du projet. Valeurs possibles : `private`, `internal` ou `public`. |
| `namespace` | objet | Informations sur l'espace de nommage du projet. |
| `namespace.id` | integer | ID de l'espace de nommage. |
| `namespace.name` | string | Nom de l'espace de nommage. |
| `namespace.path` | string | Chemin de l'espace de nommage. |
| `namespace.kind` | string | Type d'espace de nommage. Valeurs possibles : `user` ou `group`. |
| `namespace.full_path` | string | Chemin complet de l'espace de nommage. |
| `namespace.parent_id` | integer | ID de l'espace de nommage parent, le cas échéant. |
| `namespace.avatar_url` | string | URL vers l'image d'avatar de l'espace de nommage. |
| `namespace.web_url` | string | URL pour accéder à l'espace de nommage dans un navigateur. |
| `container_registry_image_prefix` | string | Préfixe pour les images du registre de conteneurs. |
| `_links` | objet | Ensemble de liens d'endpoints d'API liés au projet. |
| `_links.self` | string | URL vers la ressource du projet. |
| `_links.issues` | string | URL vers les tickets du projet. |
| `_links.merge_requests` | string | URL vers les merge requests du projet. |
| `_links.repo_branches` | string | URL vers les branches du dépôt du projet. |
| `_links.labels` | string | URL vers les labels du projet. |
| `_links.events` | string | URL vers les événements du projet. |
| `_links.members` | string | URL vers les membres du projet. |
| `_links.cluster_agents` | string | URL vers les agents de cluster du projet. |
| `marked_for_deletion_at` | date | Déprécié. Utilisez plutôt `marked_for_deletion_on`. Date à laquelle le projet est programmé pour la suppression. |
| `marked_for_deletion_on` | date | Date à laquelle le projet est programmé pour la suppression. |
| `packages_enabled` | boolean | Indique si le registre de paquets est activé pour le projet. |
| `empty_repo` | boolean | Indique si le dépôt est vide. |
| `archived` | boolean | Indique si le projet est archivé. |
| `resolve_outdated_diff_discussions` | boolean | Indique si les discussions sur les diffs obsolètes sont automatiquement résolues. |
| `container_expiration_policy` | objet | Paramètres de la politique d'expiration des images de conteneur. |
| `container_expiration_policy.cadence` | string | Fréquence d'exécution de la politique d'expiration des conteneurs. |
| `container_expiration_policy.enabled` | boolean | Indique si la politique d'expiration des conteneurs est activée. |
| `container_expiration_policy.keep_n` | integer | Nombre d'images de conteneur à conserver. |
| `container_expiration_policy.older_than` | string | Supprimer les images de conteneur plus anciennes que cette valeur. |
| `container_expiration_policy.name_regex` | string | Déprécié. Utilisez plutôt `name_regex_delete`. Expression régulière pour correspondre aux noms des images de conteneur. |
| `container_expiration_policy.name_regex_keep` | string | Expression régulière pour correspondre aux noms des images de conteneur à conserver. |
| `container_expiration_policy.next_run_at` | datetime | Horodatage de la prochaine exécution planifiée de la politique. |
| `repository_object_format` | string | Format d'objet utilisé par le dépôt (sha1 ou sha256). |
| `issues_enabled` | boolean | Indique si les tickets sont activés pour le projet. |
| `merge_requests_enabled` | boolean | Indique si les merge requests sont activées pour le projet. |
| `wiki_enabled` | boolean | Indique si le wiki est activé pour le projet. |
| `jobs_enabled` | boolean | Indique si les jobs sont activés pour le projet. |
| `snippets_enabled` | boolean | Indique si les extraits de code sont activés pour le projet. |
| `container_registry_enabled` | boolean | Déprécié. Utilisez plutôt `container_registry_access_level`. Indique si le registre de conteneurs est activé. |
| `service_desk_enabled` | boolean | Indique si Service Desk est activé pour le projet. |
| `can_create_merge_request_in` | boolean | Indique si l'utilisateur actuel peut créer des merge requests dans le projet. |
| `issues_access_level` | string | Niveau d'accès pour la fonctionnalité des tickets. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `repository_access_level` | string | Niveau d'accès pour la fonctionnalité du dépôt. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `merge_requests_access_level` | string | Niveau d'accès pour la fonctionnalité des merge requests. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `forking_access_level` | string | Niveau d'accès pour la duplication du projet. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `wiki_access_level` | string | Niveau d'accès pour la fonctionnalité wiki. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `builds_access_level` | string | Niveau d'accès pour la fonctionnalité de builds CI/CD. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `snippets_access_level` | string | Niveau d'accès pour la fonctionnalité des extraits de code. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `pages_access_level` | string | Niveau d'accès pour GitLab Pages. Valeurs possibles : `disabled`, `private`, `enabled` ou `public`. |
| `analytics_access_level` | string | Niveau d'accès pour les fonctionnalités d'analyse. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `container_registry_access_level` | string | Niveau d'accès pour le registre de conteneurs. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `security_and_compliance_access_level` | string | Niveau d'accès pour les fonctionnalités de sécurité et de conformité. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `releases_access_level` | string | Niveau d'accès pour la fonctionnalité des releases. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `environments_access_level` | string | Niveau d'accès pour la fonctionnalité des environnements. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `feature_flags_access_level` | string | Niveau d'accès pour la fonctionnalité des feature flags. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `infrastructure_access_level` | string | Niveau d'accès pour la fonctionnalité d'infrastructure. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `monitor_access_level` | string | Niveau d'accès pour la fonctionnalité de surveillance. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `model_experiments_access_level` | string | Niveau d'accès pour la fonctionnalité des expériences de modèles. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `model_registry_access_level` | string | Niveau d'accès pour la fonctionnalité du registre de modèles. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `package_registry_access_level` | string | Niveau d'accès pour la fonctionnalité du registre de paquets. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `emails_disabled` | boolean | Indique si les e-mails sont désactivés pour le projet. |
| `emails_enabled` | boolean | Indique si les e-mails sont activés pour le projet. |
| `show_diff_preview_in_email` | boolean | Indique si les aperçus de diff sont affichés dans les notifications par e-mail. |
| `shared_runners_enabled` | boolean | Indique si les runners partagés sont activés pour le projet. |
| `lfs_enabled` | boolean | Indique si Git LFS est activé pour le projet. |
| `creator_id` | integer | ID de l'utilisateur qui a créé le projet. |
| `import_status` | string | Statut de l'import du projet. |
| `open_issues_count` | integer | Nombre de tickets ouverts. |
| `description_html` | string | Description du projet au format HTML. |
| `updated_at` | datetime | Horodatage de la dernière mise à jour du projet. |
| `ci_default_git_depth` | integer | Profondeur Git par défaut pour les pipelines CI/CD. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_forward_deployment_enabled` | boolean | Indique si le déploiement en avant est activé. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_job_token_scope_enabled` | boolean | Indique si la portée du token de job CI/CD est activée. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_separated_caches` | boolean | Indique si les caches CI/CD sont séparés par branche. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | boolean | Indique si les pipelines de fork peuvent s'exécuter dans le projet parent. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `build_git_strategy` | string | Stratégie Git utilisée pour les builds CI/CD (fetch ou clone). Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `keep_latest_artifact` | boolean | Indique si le dernier artefact est conservé lors de la création d'un nouvel artefact. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `restrict_user_defined_variables` | boolean | Indique si les variables définies par l'utilisateur sont restreintes. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `runners_token` | string | Token pour enregistrer des runners auprès du projet. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `runner_token_expiration_interval` | integer | Intervalle d'expiration en secondes pour les tokens de runner. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `group_runners_enabled` | boolean | Indique si les runners de groupe sont activés pour le projet. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `auto_cancel_pending_pipelines` | string | Paramètre pour l'annulation automatique des pipelines en attente. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `build_timeout` | integer | Délai d'attente en secondes pour les jobs CI/CD. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `auto_devops_enabled` | boolean | Indique si Auto DevOps est activé pour le projet. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `auto_devops_deploy_strategy` | string | Stratégie de déploiement pour Auto DevOps. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_config_path` | string | Chemin vers le fichier de configuration CI/CD. |
| `public_jobs` | boolean | Indique si les job logs sont accessibles publiquement. |
| `shared_with_groups` | tableau d'objets | Liste des groupes avec lesquels le projet est partagé. |
| `only_allow_merge_if_pipeline_succeeds` | boolean | Indique si les fusions sont autorisées uniquement si le pipeline réussit. |
| `allow_merge_on_skipped_pipeline` | boolean | Indique si les fusions sont autorisées lorsque le pipeline est ignoré. |
| `request_access_enabled` | boolean | Indique si les utilisateurs peuvent demander l'accès au projet. |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | Indique si les fusions sont autorisées uniquement si toutes les discussions sont résolues. |
| `remove_source_branch_after_merge` | boolean | Indique si la branche source est automatiquement supprimée après la fusion. |
| `printing_merge_request_link_enabled` | boolean | Indique si les liens de merge request sont affichés après un push. |
| `merge_method` | string | Méthode de fusion utilisée pour le projet. Valeurs possibles : `merge`, `rebase_merge` ou `ff`. |
| `merge_request_title_regex` | string | Modèle d'expression régulière pour la validation des titres de merge request. |
| `merge_request_title_regex_description` | string | Description de la validation du titre de merge request par expression régulière. |
| `squash_option` | string | Option de squash pour les merge requests. |
| `enforce_auth_checks_on_uploads` | boolean | Indique si les vérifications d'authentification sont appliquées lors des uploads. |
| `suggestion_commit_message` | string | Message de commit personnalisé pour les suggestions. |
| `merge_commit_template` | string | Modèle pour les messages de commit de fusion. |
| `mr_default_title_template` | string | Modèle pour les titres de merge request. |
| `squash_commit_template` | string | Modèle pour les messages de commit de squash. |
| `issue_branch_template` | string | Modèle pour les noms de branches créées à partir de tickets. |
| `warn_about_potentially_unwanted_characters` | boolean | Indique si un avertissement est émis pour les caractères potentiellement indésirables. |
| `autoclose_referenced_issues` | boolean | Indique si les tickets référencés sont automatiquement fermés. |
| `max_artifacts_size` | integer | Taille maximale en Mo pour les artefacts de job CI/CD. |
| `approvals_before_merge` | integer | Déprécié. Utilisez plutôt l'API Merge request approvals. Nombre d'approbations requises avant la fusion. |
| `mirror` | boolean | Indique si le projet est un miroir. |
| `external_authorization_classification_label` | string | Label de classification d'autorisation externe. |
| `requirements_enabled` | boolean | Indique si la gestion des exigences est activée. |
| `requirements_access_level` | string | Niveau d'accès pour la fonctionnalité des exigences. |
| `security_and_compliance_enabled` | boolean | Indique si les fonctionnalités de sécurité et de conformité sont activées. |
| `compliance_frameworks` | tableau de chaînes de caractères | Cadres de conformité appliqués au projet. |
| `issues_template` | string | Description par défaut pour les tickets. La description est analysée avec GitLab Flavored Markdown. Premium et Ultimate uniquement. |
| `merge_requests_template` | string | Modèle pour les descriptions de merge request. Premium et Ultimate uniquement. |
| `merge_pipelines_enabled` | boolean | Indique si les pipelines de fusion sont activés. |
| `merge_trains_enabled` | boolean | Indique si les merge trains sont activés. |
| `merge_trains_skip_train_allowed` | boolean | Indique si l'omission du merge train est autorisée. |
| `max_pipelines_per_merge_train` | integer | Nombre maximum de pipelines parallèles par merge train. |
| `only_allow_merge_if_all_status_checks_passed` | boolean | Indique si les fusions sont autorisées uniquement si tous les contrôles de statut ont réussi. Ultimate uniquement. |
| `allow_pipeline_trigger_approve_deployment` | boolean | Indique si les déclencheurs de pipeline peuvent approuver des déploiements. |
| `prevent_merge_without_jira_issue` | boolean | Indique si les fusions nécessitent un ticket Jira associé. |
| `duo_remote_flows_enabled` | boolean | Indique si les flows distants GitLab Duo sont activés. |
| `duo_foundational_flows_enabled` | boolean | Indique si les flows par défaut GitLab Duo sont activés. |
| `duo_sast_fp_detection_enabled` | boolean | Indique si la détection des faux positifs SAST de GitLab Duo est activée. |
| `duo_sast_vr_workflow_enabled` | boolean | Indique si le workflow de résolution des vulnérabilités SAST de GitLab Duo est activé. |
| `spp_repository_pipeline_access` | boolean | Accès au pipeline du dépôt pour les politiques de sécurité. Visible uniquement si la fonctionnalité de politiques d'orchestration de sécurité est disponible. |
| `permissions` | objet | Permissions de l'utilisateur pour le projet. |
| `permissions.project_access` | objet | Permissions d'accès au projet pour l'utilisateur. |
| `permissions.group_access` | objet | Permissions d'accès au groupe pour l'utilisateur. |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/users/:user_id/projects
```

Exemple de réponse :

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 50,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "ci_display_pipeline_variables": false,
    "protect_merge_request_pipelines": true,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "mr_default_title_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "marked_for_deletion_at": "2020-04-03", // Deprecated in favor of marked_for_deletion_on. Planned for removal in a future version of the REST API.
    "marked_for_deletion_on": "2020-04-03",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  },
  {
    "id": 6,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "puppet"
    ],
    "topics": [
      "example",
      "puppet"
    ],
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "namespace": {
      "id": 4,
      "name": "Brightbox",
      "path": "brightbox",
      "kind": "group",
      "full_path": "brightbox"
    },
    "import_status": "none",
    "import_error": null,
    "permissions": {
      "project_access": {
        "access_level": 10,
        "notification_level": 3
      },
      "group_access": {
        "access_level": 50,
        "notification_level": 3
      }
    },
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 0,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "ci_display_pipeline_variables": false,
    "protect_merge_request_pipelines": true,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "auto_devops_enabled": true,
    "auto_devops_deploy_strategy": "continuous",
    "repository_storage": "default",
    "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
    "mirror": false,
    "mirror_user_id": 45,
    "mirror_trigger_builds": false,
    "only_mirror_protected_branches": false,
    "mirror_overwrites_diverged_branches": false,
    "external_authorization_classification_label": null,
    "packages_enabled": true, // deprecated, use package_registry_access_level instead
    "empty_repo": false,
    "package_registry_access_level": "enabled",
    "service_desk_enabled": false,
    "service_desk_address": null,
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "mr_default_title_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

### Lister toutes les contributions de projets pour un utilisateur {#list-all-projects-contributions-for-a-user}

{{< history >}}

- `mr_default_title_template` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) dans GitLab 18.11 [avec un feature flag](../administration/feature_flags/_index.md) nommé `mr_default_title_template`. Désactivé par défaut.
- Le feature flag `mr_default_title_template` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642) dans GitLab 19.0.

{{< /history >}}

Liste toutes les contributions aux projets visibles pour un utilisateur spécifié. Retourne uniquement les contributions de l'année écoulée. Pour plus d'informations sur ce qui est considéré comme une contribution, consultez [Voir les projets avec lesquels vous travaillez](../user/project/working_with_projects.md#view-projects-you-work-with).

```plaintext
GET /users/:user_id/contributed_projects
```

Attributs pris en charge :

| Attribut  | Type    | Obligatoire | Description |
|:-----------|:--------|:---------|:------------|
| `user_id`  | string  | Oui      | L'ID ou le nom d'utilisateur de l'utilisateur. |
| `order_by` | string  | Non       | Retourner les projets triés par les champs `id`, `name`, `path`, `created_at`, `updated_at`, `star_count` ou `last_activity_at`. La valeur par défaut est `created_at`. |
| `simple`   | boolean | Non       | Si `true`, renvoyer uniquement les champs limités pour chaque projet. Les requêtes non authentifiées renvoient uniquement les projets publics avec des champs limités, même si `simple` n'est pas défini. |
| `sort`     | string  | Non       | Renvoyer les projets triés dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type | Description |
|-----------|------|-------------|
| `id` | integer | ID du projet. |
| `description` | string | Description du projet. |
| `name` | string | Nom du projet. |
| `name_with_namespace` | string | Nom du projet avec son espace de nommage. |
| `path` | string | Chemin du projet. |
| `path_with_namespace` | string | Chemin du projet avec son espace de nommage. |
| `created_at` | datetime | Horodatage de la création du projet. |
| `default_branch` | string | Branche par défaut du projet. |
| `tag_list` | tableau de chaînes de caractères | Déprécié. Utilisez plutôt `topics`. Liste des tags du projet. |
| `topics` | tableau de chaînes de caractères | Liste des topics du projet. |
| `ssh_url_to_repo` | string | URL SSH pour cloner le dépôt. |
| `http_url_to_repo` | string | URL HTTP pour cloner le dépôt. |
| `web_url` | string | URL pour accéder au projet dans un navigateur. |
| `readme_url` | string | URL vers le fichier README du projet. |
| `forks_count` | integer | Nombre de duplications du projet. |
| `avatar_url` | string | URL vers l'image d'avatar du projet. |
| `star_count` | integer | Nombre d'étoiles reçues par le projet. |
| `last_activity_at` | datetime | Horodatage de la dernière activité dans le projet. |
| `visibility` | string | Niveau de visibilité du projet. Valeurs possibles : `private`, `internal` ou `public`. |
| `namespace` | objet | Informations sur l'espace de nommage du projet. |
| `namespace.id` | integer | ID de l'espace de nommage. |
| `namespace.name` | string | Nom de l'espace de nommage. |
| `namespace.path` | string | Chemin de l'espace de nommage. |
| `namespace.kind` | string | Type d'espace de nommage. Valeurs possibles : `user` ou `group`. |
| `namespace.full_path` | string | Chemin complet de l'espace de nommage. |
| `namespace.parent_id` | integer | ID de l'espace de nommage parent, le cas échéant. |
| `namespace.avatar_url` | string | URL vers l'image d'avatar de l'espace de nommage. |
| `namespace.web_url` | string | URL pour accéder à l'espace de nommage dans un navigateur. |
| `container_registry_image_prefix` | string | Préfixe pour les images du registre de conteneurs. |
| `_links` | objet | Ensemble de liens d'endpoints d'API liés au projet. |
| `_links.self` | string | URL vers la ressource du projet. |
| `_links.issues` | string | URL vers les tickets du projet. |
| `_links.merge_requests` | string | URL vers les merge requests du projet. |
| `_links.repo_branches` | string | URL vers les branches du dépôt du projet. |
| `_links.labels` | string | URL vers les labels du projet. |
| `_links.events` | string | URL vers les événements du projet. |
| `_links.members` | string | URL vers les membres du projet. |
| `_links.cluster_agents` | string | URL vers les agents de cluster du projet. |
| `marked_for_deletion_at` | date | Déprécié. Utilisez plutôt `marked_for_deletion_on`. Date à laquelle le projet est programmé pour la suppression. |
| `marked_for_deletion_on` | date | Date à laquelle le projet est programmé pour la suppression. |
| `packages_enabled` | boolean | Indique si le registre de paquets est activé pour le projet. |
| `empty_repo` | boolean | Indique si le dépôt est vide. |
| `archived` | boolean | Indique si le projet est archivé. |
| `resolve_outdated_diff_discussions` | boolean | Indique si les discussions sur les diffs obsolètes sont automatiquement résolues. |
| `container_expiration_policy` | objet | Paramètres de la politique d'expiration des images de conteneur. |
| `container_expiration_policy.cadence` | string | Fréquence d'exécution de la politique d'expiration des conteneurs. |
| `container_expiration_policy.enabled` | boolean | Indique si la politique d'expiration des conteneurs est activée. |
| `container_expiration_policy.keep_n` | integer | Nombre d'images de conteneur à conserver. |
| `container_expiration_policy.older_than` | string | Supprimer les images de conteneur plus anciennes que cette valeur. |
| `container_expiration_policy.name_regex` | string | Déprécié. Utilisez plutôt `name_regex_delete`. Expression régulière pour correspondre aux noms des images de conteneur. |
| `container_expiration_policy.name_regex_keep` | string | Expression régulière pour correspondre aux noms des images de conteneur à conserver. |
| `container_expiration_policy.next_run_at` | datetime | Horodatage de la prochaine exécution planifiée de la politique. |
| `repository_object_format` | string | Format d'objet utilisé par le dépôt (sha1 ou sha256). |
| `issues_enabled` | boolean | Indique si les tickets sont activés pour le projet. |
| `merge_requests_enabled` | boolean | Indique si les merge requests sont activées pour le projet. |
| `wiki_enabled` | boolean | Indique si le wiki est activé pour le projet. |
| `jobs_enabled` | boolean | Indique si les jobs sont activés pour le projet. |
| `snippets_enabled` | boolean | Indique si les extraits de code sont activés pour le projet. |
| `container_registry_enabled` | boolean | Déprécié. Utilisez plutôt `container_registry_access_level`. Indique si le registre de conteneurs est activé. |
| `service_desk_enabled` | boolean | Indique si Service Desk est activé pour le projet. |
| `can_create_merge_request_in` | boolean | Indique si l'utilisateur actuel peut créer des merge requests dans le projet. |
| `issues_access_level` | string | Niveau d'accès pour la fonctionnalité des tickets. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `repository_access_level` | string | Niveau d'accès pour la fonctionnalité du dépôt. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `merge_requests_access_level` | string | Niveau d'accès pour la fonctionnalité des merge requests. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `forking_access_level` | string | Niveau d'accès pour la duplication du projet. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `wiki_access_level` | string | Niveau d'accès pour la fonctionnalité wiki. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `builds_access_level` | string | Niveau d'accès pour la fonctionnalité de builds CI/CD. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `snippets_access_level` | string | Niveau d'accès pour la fonctionnalité des extraits de code. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `pages_access_level` | string | Niveau d'accès pour GitLab Pages. Valeurs possibles : `disabled`, `private`, `enabled` ou `public`. |
| `analytics_access_level` | string | Niveau d'accès pour les fonctionnalités d'analyse. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `container_registry_access_level` | string | Niveau d'accès pour le registre de conteneurs. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `security_and_compliance_access_level` | string | Niveau d'accès pour les fonctionnalités de sécurité et de conformité. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `releases_access_level` | string | Niveau d'accès pour la fonctionnalité des releases. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `environments_access_level` | string | Niveau d'accès pour la fonctionnalité des environnements. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `feature_flags_access_level` | string | Niveau d'accès pour la fonctionnalité des feature flags. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `infrastructure_access_level` | string | Niveau d'accès pour la fonctionnalité d'infrastructure. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `monitor_access_level` | string | Niveau d'accès pour la fonctionnalité de surveillance. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `model_experiments_access_level` | string | Niveau d'accès pour la fonctionnalité des expériences de modèles. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `model_registry_access_level` | string | Niveau d'accès pour la fonctionnalité du registre de modèles. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `package_registry_access_level` | string | Niveau d'accès pour la fonctionnalité du registre de paquets. Valeurs possibles : `disabled`, `private` ou `enabled`. |
| `emails_disabled` | boolean | Indique si les e-mails sont désactivés pour le projet. |
| `emails_enabled` | boolean | Indique si les e-mails sont activés pour le projet. |
| `show_diff_preview_in_email` | boolean | Indique si les aperçus de diff sont affichés dans les notifications par e-mail. |
| `shared_runners_enabled` | boolean | Indique si les runners partagés sont activés pour le projet. |
| `lfs_enabled` | boolean | Indique si Git LFS est activé pour le projet. |
| `creator_id` | integer | ID de l'utilisateur qui a créé le projet. |
| `import_status` | string | Statut de l'import du projet. |
| `open_issues_count` | integer | Nombre de tickets ouverts. |
| `description_html` | string | Description du projet au format HTML. |
| `updated_at` | datetime | Horodatage de la dernière mise à jour du projet. |
| `ci_default_git_depth` | integer | Profondeur Git par défaut pour les pipelines CI/CD. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_forward_deployment_enabled` | boolean | Indique si le déploiement en avant est activé. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_job_token_scope_enabled` | boolean | Indique si la portée du token de job CI/CD est activée. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_separated_caches` | boolean | Indique si les caches CI/CD sont séparés par branche. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | boolean | Indique si les pipelines de fork peuvent s'exécuter dans le projet parent. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `build_git_strategy` | string | Stratégie Git utilisée pour les builds CI/CD (fetch ou clone). Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `keep_latest_artifact` | boolean | Indique si le dernier artefact est conservé lors de la création d'un nouvel artefact. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `restrict_user_defined_variables` | boolean | Indique si les variables définies par l'utilisateur sont restreintes. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `runners_token` | string | Token pour enregistrer des runners auprès du projet. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `runner_token_expiration_interval` | integer | Intervalle d'expiration en secondes pour les tokens de runner. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `group_runners_enabled` | boolean | Indique si les runners de groupe sont activés pour le projet. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `auto_cancel_pending_pipelines` | string | Paramètre pour l'annulation automatique des pipelines en attente. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `build_timeout` | integer | Délai d'attente en secondes pour les jobs CI/CD. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `auto_devops_enabled` | boolean | Indique si Auto DevOps est activé pour le projet. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `auto_devops_deploy_strategy` | string | Stratégie de déploiement pour Auto DevOps. Visible uniquement si vous disposez d'un accès administrateur ou du rôle Owner pour le projet. |
| `ci_config_path` | string | Chemin vers le fichier de configuration CI/CD. |
| `public_jobs` | boolean | Indique si les job logs sont accessibles publiquement. |
| `shared_with_groups` | tableau d'objets | Liste des groupes avec lesquels le projet est partagé. |
| `only_allow_merge_if_pipeline_succeeds` | boolean | Indique si les fusions sont autorisées uniquement si le pipeline réussit. |
| `allow_merge_on_skipped_pipeline` | boolean | Indique si les fusions sont autorisées lorsque le pipeline est ignoré. |
| `request_access_enabled` | boolean | Indique si les utilisateurs peuvent demander l'accès au projet. |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | Indique si les fusions sont autorisées uniquement si toutes les discussions sont résolues. |
| `remove_source_branch_after_merge` | boolean | Indique si la branche source est automatiquement supprimée après la fusion. |
| `printing_merge_request_link_enabled` | boolean | Indique si les liens de merge request sont affichés après un push. |
| `merge_method` | string | Méthode de fusion utilisée pour le projet. Valeurs possibles : `merge`, `rebase_merge` ou `ff`. |
| `merge_request_title_regex` | string | Modèle d'expression régulière pour la validation des titres de merge request. |
| `merge_request_title_regex_description` | string | Description de la validation du titre de merge request par expression régulière. |
| `squash_option` | string | Option de squash pour les merge requests. |
| `enforce_auth_checks_on_uploads` | boolean | Indique si les vérifications d'authentification sont appliquées lors des uploads. |
| `suggestion_commit_message` | string | Message de commit personnalisé pour les suggestions. |
| `merge_commit_template` | string | Modèle pour les messages de commit de fusion. |
| `mr_default_title_template` | string | Modèle pour les titres de merge request. |
| `squash_commit_template` | string | Modèle pour les messages de commit de squash. |
| `issue_branch_template` | string | Modèle pour les noms de branches créées à partir de tickets. |
| `warn_about_potentially_unwanted_characters` | boolean | Indique si un avertissement est émis pour les caractères potentiellement indésirables. |
| `autoclose_referenced_issues` | boolean | Indique si les tickets référencés sont automatiquement fermés. |
| `max_artifacts_size` | integer | Taille maximale en Mo pour les artefacts de job CI/CD. |
| `approvals_before_merge` | integer | Déprécié. Utilisez plutôt l'API Merge request approvals. Nombre d'approbations requises avant la fusion. |
| `mirror` | boolean | Indique si le projet est un miroir. |
| `external_authorization_classification_label` | string | Label de classification d'autorisation externe. |
| `requirements_enabled` | boolean | Indique si la gestion des exigences est activée. |
| `requirements_access_level` | string | Niveau d'accès pour la fonctionnalité des exigences. |
| `security_and_compliance_enabled` | boolean | Indique si les fonctionnalités de sécurité et de conformité sont activées. |
| `compliance_frameworks` | tableau de chaînes de caractères | Cadres de conformité appliqués au projet. |
| `issues_template` | string | Description par défaut pour les tickets. La description est analysée avec GitLab Flavored Markdown. Premium et Ultimate uniquement. |
| `merge_requests_template` | string | Modèle pour les descriptions de merge request. Premium et Ultimate uniquement. |
| `merge_pipelines_enabled` | boolean | Indique si les pipelines de fusion sont activés. |
| `merge_trains_enabled` | boolean | Indique si les merge trains sont activés. |
| `merge_trains_skip_train_allowed` | boolean | Indique si l'omission du merge train est autorisée. |
| `max_pipelines_per_merge_train` | integer | Nombre maximum de pipelines parallèles par merge train. |
| `only_allow_merge_if_all_status_checks_passed` | boolean | Indique si les fusions sont autorisées uniquement si tous les contrôles de statut ont réussi. Ultimate uniquement. |
| `allow_pipeline_trigger_approve_deployment` | boolean | Indique si les déclencheurs de pipeline peuvent approuver des déploiements. |
| `prevent_merge_without_jira_issue` | boolean | Indique si les fusions nécessitent un ticket Jira associé. |
| `duo_remote_flows_enabled` | boolean | Indique si les flows distants GitLab Duo sont activés. |
| `duo_foundational_flows_enabled` | boolean | Indique si les flows par défaut GitLab Duo sont activés. |
| `duo_sast_fp_detection_enabled` | boolean | Indique si la détection des faux positifs SAST de GitLab Duo est activée. |
| `duo_sast_vr_workflow_enabled` | boolean | Indique si le workflow de résolution des vulnérabilités SAST de GitLab Duo est activé. |
| `spp_repository_pipeline_access` | boolean | Accès au pipeline du dépôt pour les politiques de sécurité. Visible uniquement si la fonctionnalité de politiques d'orchestration de sécurité est disponible. |
| `permissions` | objet | Permissions de l'utilisateur pour le projet. |
| `permissions.project_access` | objet | Permissions d'accès au projet pour l'utilisateur. |
| `permissions.group_access` | objet | Permissions d'accès au groupe pour l'utilisateur. |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/5/contributed_projects"
```

Exemple de réponse :

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "mr_default_title_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  },
  {
    "id": 6,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "puppet"
    ],
    "topics": [
      "example",
      "puppet"
    ],
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 4,
      "name": "Brightbox",
      "path": "brightbox",
      "kind": "group",
      "full_path": "brightbox"
    },
    "import_status": "none",
    "import_error": null,
    "permissions": {
      "project_access": {
        "access_level": 10,
        "notification_level": 3
      },
      "group_access": {
        "access_level": 50,
        "notification_level": 3
      }
    },
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "auto_devops_enabled": true,
    "auto_devops_deploy_strategy": "continuous",
    "repository_storage": "default",
    "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
    "mirror": false,
    "mirror_user_id": 45,
    "mirror_trigger_builds": false,
    "only_mirror_protected_branches": false,
    "mirror_overwrites_diverged_branches": false,
    "external_authorization_classification_label": null,
    "packages_enabled": true, // deprecated, use package_registry_access_level instead
    "empty_repo": false,
    "package_registry_access_level": "enabled",
    "service_desk_enabled": false,
    "service_desk_address": null,
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "mr_default_title_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

## Attributs de liste {#list-attributes}

Lister les attributs d'un projet.

### Lister tous les membres d'un projet {#list-all-members-of-a-project}

Liste tous les membres ayant accès à un projet spécifié.

```plaintext
GET /projects/:id/users
```

Attributs pris en charge :

| Attribut    | Type              | Obligatoire | Description |
|:-------------|:------------------|:---------|:------------|
| `id`         | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `search`     | string            | Non       | Rechercher un membre spécifique par son `username` ou son `name`. |
| `skip_users` | tableau d'entiers     | Non       | Exclure les membres avec les ID spécifiés. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type | Description |
|:----------|:-----|:------------|
| `id` | integer | ID de l'utilisateur. |
| `username` | string | Nom d'utilisateur de l'utilisateur. |
| `name` | string | Nom complet de l'utilisateur. |
| `state` | string | État du compte utilisateur. Valeurs possibles : `active` ou `blocked`. |
| `avatar_url` | string | URL de l'image d'avatar de l'utilisateur. |
| `web_url` | string | URL pour accéder au profil de l'utilisateur dans un navigateur. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<project_id>/users" \
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "name": "John Smith",
    "state": "active",
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://localhost:3000/john_smith"
  },
  {
    "id": 2,
    "username": "jack_smith",
    "name": "Jack Smith",
    "state": "blocked",
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "web_url": "http://localhost:3000/jack_smith"
  }
]
```

### Lister tous les groupes ancêtres {#list-all-ancestor-groups}

Liste tous les groupes ancêtres d'un projet spécifié.

```plaintext
GET /projects/:id/groups
```

Attributs pris en charge :

| Attribut                 | Type              | Obligatoire | Description |
|:--------------------------|:------------------|:---------|:------------|
| `id`                      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `search`                  | string            | Non       | Rechercher des groupes spécifiques par ID de groupe. |
| `shared_min_access_level` | integer           | Non       | Limiter aux groupes partagés avec au moins le niveau d'accès spécifié. Valeurs possibles : `5` (Accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `shared_visible_only`     | boolean           | Non       | Si `true`, retourne uniquement les groupes partagés auxquels l'utilisateur authentifié peut accéder. |
| `skip_groups`             | tableau d'entiers | Non       | Ignorer les ID de groupe passés. |
| `with_shared`             | boolean           | Non       | Inclure les projets partagés avec ce groupe. La valeur par défaut est `false`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type | Description |
|:----------|:-----|:------------|
| `id` | integer | ID du groupe. |
| `name` | string | Nom du groupe. |
| `avatar_url` | string | URL de l'image d'avatar du groupe. |
| `web_url` | string | URL pour accéder au groupe dans un navigateur. |
| `full_name` | string | Nom complet du groupe. |
| `full_path` | string | Chemin complet du groupe. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/groups"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "full_name": "Foobar Group",
    "full_path": "foo-bar"
  },
  {
    "id": 2,
    "name": "Shared Group",
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/bar.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar",
    "full_name": "Shared Group",
    "full_path": "foo/shared"
  }
]
```

### Lister tous les groupes disponibles à inviter dans un projet {#list-all-groups-available-to-invite-to-a-project}

Liste tous les groupes pouvant être invités dans un projet.

```plaintext
GET /projects/:id/share_locations
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `search`  | string            | Non       | Rechercher des groupes spécifiques par ID de groupe. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type | Description |
|:----------|:-----|:------------|
| `id` | integer | ID du groupe. |
| `web_url` | string | URL pour accéder au groupe dans un navigateur. |
| `name` | string | Nom du groupe. |
| `avatar_url` | string | URL de l'image d'avatar du groupe. |
| `full_name` | string | Nom complet du groupe. |
| `full_path` | string | Chemin complet du groupe. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/share_locations"
```

Exemple de réponse :

```json
[
  {
    "id": 22,
    "web_url": "http://127.0.0.1:3000/groups/gitlab-org",
    "name": "Gitlab Org",
    "avatar_url": null,
    "full_name": "Gitlab Org",
    "full_path": "gitlab-org"
  },
  {
    "id": 25,
    "web_url": "http://127.0.0.1:3000/groups/gnuwget",
    "name": "Gnuwget",
    "avatar_url": null,
    "full_name": "Gnuwget",
    "full_path": "gnuwget"
  }
]
```

### Lister tous les groupes invités dans un projet {#list-all-invited-groups-in-a-project}

Liste tous les groupes invités dans un projet. Lorsqu'il est consulté sans authentification, retourne uniquement les groupes invités publics. Ce point de terminaison est soumis à une limite de débit de 60 requêtes par minute par :

- Utilisateur pour les utilisateurs authentifiés
- Adresse IP pour les utilisateurs non authentifiés

Cet endpoint prend en charge la pagination :

- Utilisez la pagination par décalage pour accéder à jusqu'à 50 000 projets.
- Utilisez la pagination par jeu de clés pour lister plus de 50 000 projets.

Pour plus d'informations, consultez [Pagination](rest/_index.md#pagination).

```plaintext
GET /projects/:id/invited_groups
```

Attributs pris en charge :

| Attribut                | Type             | Obligatoire | Description |
|:-------------------------|:-----------------|:---------|:------------|
| `id`                     | entier ou chaîne de caractères   | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `search`                 | string           | non       | Retourne la liste des groupes autorisés correspondant aux critères de recherche. |
| `min_access_level`       | integer          | non       | Limiter aux groupes où l'utilisateur actuel dispose d'au moins le niveau d'accès spécifié. Valeurs possibles : `5` (Accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `relation`               | tableau de chaînes de caractères | non       | Filtrer les groupes par relation. Valeurs possibles : `direct` ou `inherited`. |
| `with_custom_attributes` | boolean          | non       | Si `true`, retourne les [attributs personnalisés](custom_attributes.md) dans la réponse. Nécessite un accès administrateur. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type | Description |
|:----------|:-----|:------------|
| `id` | integer | ID du groupe. |
| `web_url` | string | URL pour accéder au groupe dans un navigateur. |
| `name` | string | Nom du groupe. |
| `avatar_url` | string | URL de l'image d'avatar du groupe. |
| `full_name` | string | Nom complet du groupe. |
| `full_path` | string | Chemin complet du groupe. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/invited_groups"
```

Exemple de réponse :

```json
[
  {
    "id": 35,
    "web_url": "https://gitlab.example.com/groups/twitter",
    "name": "Twitter",
    "avatar_url": null,
    "full_name": "Twitter",
    "full_path": "twitter"
  }
]
```

### Récupérer les informations sur l'utilisation des langages de programmation {#retrieve-programming-language-usage-information}

Récupère des informations sur tous les langages de programmation utilisés dans un projet spécifié.

```plaintext
GET /projects/:id/languages
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et une liste des langages de programmation avec leurs pourcentages d'utilisation.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/languages"
```

Exemple de réponse :

```json
{
  "Ruby": 66.69,
  "JavaScript": 22.98,
  "HTML": 7.91,
  "CoffeeScript": 2.42
}
```

## Gérer les projets {#manage-projects}

Gérer un projet, notamment sa création, sa suppression et son archivage.

### Créer un projet {#create-a-project}

{{< history >}}

- `operations_access_level` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) dans GitLab 16.0.
- `model_registry_access_level` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/412734) dans GitLab 16.7.
- `packages_enabled` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) dans GitLab 17.10.
- `package_registry_access_level` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) dans GitLab 18.5.

{{< /history >}}

Crée un projet appartenant à l'utilisateur authentifié.

Si votre dépôt HTTP n'est pas accessible publiquement, ajoutez des informations d'authentification à l'URL `https://username:password@gitlab.company.com/group/project.git`, où `password` est une clé d'accès publique avec la portée `api` activée.

```plaintext
POST /projects
```

Attributs généraux du projet pris en charge :

| Attribut                                          | Type    | Obligatoire                       | Description |
|:---------------------------------------------------|:--------|:-------------------------------|:------------|
| `name`                                             | string  | Oui (si `path` n'est pas fourni) | Le nom du nouveau projet. Correspond au chemin si non fourni. |
| `path`                                             | string  | Oui (si `name` n'est pas fourni) | Nom du dépôt pour le nouveau projet. Généré à partir du nom si non fourni (généré en minuscules avec des tirets). Le chemin ne doit pas commencer ou se terminer par un caractère spécial et ne doit pas contenir de caractères spéciaux consécutifs. |
| `allow_merge_on_skipped_pipeline`                  | boolean | Non                             | Définir si les merge requests peuvent être fusionnées avec des jobs ignorés. |
| `approvals_before_merge`                           | integer | Non                             | Combien d'approbateurs devraient approuver les merge requests par défaut. Pour configurer les règles d'approbation, consultez [l'API d'approbation des merge requests](merge_request_approvals.md). [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) dans GitLab 16.0. Premium et Ultimate uniquement. |
| `auto_cancel_pending_pipelines`                    | string  | Non                             | Annuler automatiquement les pipelines en attente. Cette action bascule entre un état activé et un état désactivé ; ce n'est pas un booléen. |
| `auto_devops_deploy_strategy`                      | string  | Non                             | Stratégie de déploiement automatique (`continuous`, `manual` ou `timed_incremental`). |
| `auto_devops_enabled`                              | boolean | Non                             | Activer Auto DevOps pour ce projet. |
| `autoclose_referenced_issues`                      | boolean | Non                             | Définir si les tickets référencés sont automatiquement fermés sur la branche par défaut. |
| `avatar`                                           | mixte   | Non                             | Fichier image pour l'avatar du projet. |
| `build_git_strategy`                               | string  | Non                             | La stratégie Git. La valeur par défaut est `fetch`. |
| `build_timeout`                                    | integer | Non                             | Le temps maximum, en secondes, qu'un job peut s'exécuter. |
| `ci_config_path`                                   | string  | Non                             | Le chemin vers le fichier de configuration CI. |
| `container_expiration_policy_attributes`           | hash    | Non                             | Mettre à jour la politique de nettoyage des images pour ce projet. Accepte : `cadence` (chaîne), `keep_n` (entier), `older_than` (chaîne), `name_regex` (chaîne), `name_regex_delete` (chaîne), `name_regex_keep` (chaîne), `enabled` (booléen). Consultez la documentation du [registre de conteneurs](../user/packages/container_registry/reduce_container_registry_storage.md#use-the-cleanup-policy-api) pour plus d'informations sur les valeurs `cadence`, `keep_n` et `older_than`. |
| `container_registry_enabled`                       | boolean | Non                             | _(Obsolète)_ Activer le registre de conteneurs pour ce projet. Utilisez plutôt `container_registry_access_level`. |
| `default_branch`                                   | string  | Non                             | Le nom de la [branche par défaut](../user/project/repository/branches/default.md). Accepte un nom de branche (par exemple, `main`) ou une référence complète (par exemple, `refs/heads/main`). Si une référence complète est fournie, l'API supprime le préfixe `refs/heads/`. Requiert que `initialize_with_readme` soit `true`. |
| `description`                                      | string  | Non                             | Courte description du projet. |
| `emails_disabled`                                  | boolean | Non                             | _(Obsolète)_ Désactiver les notifications par e-mail. Utilisez `emails_enabled` à la place |
| `emails_enabled`                                   | boolean | Non                             | Activer les notifications par e-mail. |
| `external_authorization_classification_label`      | string  | Non                             | Le label de classification pour le projet. Premium et Ultimate uniquement. |
| `group_runners_enabled`                            | boolean | Non                             | Activer les runners de groupe pour ce projet. |
| `group_with_project_templates_id`                  | integer | Non                             | Pour les modèles personnalisés au niveau du groupe, spécifie l'ID du groupe à partir duquel tous les modèles de projets personnalisés sont issus. Laisser vide pour les modèles au niveau de l'instance. Requiert que `use_custom_template` soit vrai. Premium et Ultimate uniquement. |
| `import_url`                                       | string  | Non                             | URL pour importer le dépôt. Lorsque la valeur de l'URL n'est pas vide, vous ne devez pas définir `initialize_with_readme` sur `true`. Cela pourrait entraîner l'[erreur suivante](https://gitlab.com/gitlab-org/gitlab/-/issues/360266) : `not a git repository`. |
| `initialize_with_readme`                           | boolean | Non                             | Indique si un dépôt Git doit être créé avec uniquement un fichier `README.md`. La valeur par défaut est `false`. Lorsque ce booléen est vrai, vous ne devez pas passer `import_url` ni d'autres attributs de ce point de terminaison qui spécifient un contenu alternatif pour le dépôt. Cela pourrait entraîner l'[erreur suivante](https://gitlab.com/gitlab-org/gitlab/-/issues/360266) : `not a git repository`. |
| `issues_enabled`                                   | boolean | Non                             | _(Obsolète)_ Activer les tickets pour ce projet. Utilisez plutôt `issues_access_level`. |
| `jobs_enabled`                                     | boolean | Non                             | _(Obsolète)_ Activer les jobs pour ce projet. Utilisez plutôt `builds_access_level`. |
| `lfs_enabled`                                      | boolean | Non                             | Activer LFS. |
| `merge_method`                                     | string  | Non                             | Définir la [méthode de fusion](../user/project/merge_requests/methods/_index.md) du projet. Peut être `merge` (commit de fusion), `rebase_merge` (commit de fusion avec historique semi-linéaire) ou `ff` (fusion en avance rapide). |
| `merge_pipelines_enabled`                          | boolean | Non                             | Activer ou désactiver les pipelines de résultats fusionnés. |
| `merge_requests_enabled`                           | boolean | Non                             | _(Obsolète)_ Activer les merge requests pour ce projet. Utilisez plutôt `merge_requests_access_level`. |
| `merge_trains_enabled`                             | boolean | Non                             | Activer ou désactiver les merge trains. |
| `merge_trains_skip_train_allowed`                  | boolean | Non                             | Permet aux merge requests du merge train d'être fusionnées sans attendre la fin des pipelines. |
| `max_pipelines_per_merge_train`                    | integer | Non                             | Nombre maximum de pipelines parallèles par merge train. |
| `mirror_trigger_builds`                            | boolean | Non                             | La mise en miroir en extraction déclenche des builds. Premium et Ultimate uniquement. |
| `mirror`                                           | boolean | Non                             | Active la mise en miroir en extraction dans un projet. Premium et Ultimate uniquement. |
| `namespace_id`                                     | integer | Non                             | Espace de nommage pour le nouveau projet. Spécifiez un ID de groupe ou de sous-groupe. Si non fourni, utilise par défaut l'espace de nommage personnel de l'utilisateur actuel. |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | Non                             | Définir si les merge requests ne peuvent être fusionnées que lorsque toutes les discussions sont résolues. |
| `only_allow_merge_if_all_status_checks_passed`     | boolean | Non                             | Indique que les fusions de merge requests doivent être bloquées tant que toutes les vérifications de statut n'ont pas réussi. Par défaut : false. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/369859) dans GitLab 15.5 avec le feature flag `only_allow_merge_if_all_status_checks_passed` désactivé par défaut. Ultimate uniquement. |
| `only_allow_merge_if_pipeline_succeeds`            | boolean | Non                             | Définir si les merge requests ne peuvent être fusionnées qu'avec des pipelines réussis. Ce paramètre est nommé [**Les pipelines doivent réussir**](../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) dans les paramètres du projet. |
| `packages_enabled`                                 | boolean | Non                             | [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) dans GitLab 17.10. Activer ou désactiver la fonctionnalité de dépôt de paquets. Utilisez plutôt `package_registry_access_level`. |
| `package_registry_access_level`                    | string  | Non                             | Activer ou désactiver la fonctionnalité de dépôt de paquets. |
| `printing_merge_request_link_enabled`              | boolean | Non                             | Afficher le lien pour créer/voir une merge request lors d'un push depuis la ligne de commande. |
| `public_builds`                                    | boolean | Non                             | _(Obsolète)_ Si `true`, les jobs peuvent être consultés par des non-membres du projet. Utilisez plutôt `public_jobs`. |
| `public_jobs`                                      | boolean | Non                             | Si `true`, les jobs peuvent être consultés par des non-membres du projet. |
| `repository_object_format`                         | string  | Non                             | Format d'objet du dépôt. La valeur par défaut est `sha1`. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/419887) dans GitLab 16.9. |
| `remove_source_branch_after_merge`                 | boolean | Non                             | Activer l'option `Delete source branch` par défaut pour toutes les nouvelles merge requests. |
| `repository_storage`                               | string  | Non                             | Sur quelle partition de stockage se trouve le dépôt. _(administrateur uniquement)_ |
| `request_access_enabled`                           | boolean | Non                             | Permettre aux utilisateurs de demander l'accès en tant que membre. |
| `resolve_outdated_diff_discussions`                | boolean | Non                             | Résoudre automatiquement les discussions des diffs de merge request sur les lignes modifiées lors d'un push. |
| `shared_runners_enabled`                           | boolean | Non                             | Activer les runners d'instance pour ce projet. |
| `show_default_award_emojis`                        | boolean | Non                             | Afficher les réactions emoji par défaut. |
| `snippets_enabled`                                 | boolean | Non                             | _(Obsolète)_ Activer les extraits de code pour ce projet. Utilisez plutôt `snippets_access_level`. |
| `squash_option`                                    | string  | Non                             | L'une des valeurs suivantes : `never`, `always`, `default_on` ou `default_off`. |
| `tag_list`                                         | array   | Non                             | La liste des tags d'un projet ; indiquez un tableau de tags qui doivent être finalement attribués au projet. [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) dans GitLab 14.0. Utilisez plutôt `topics`. |
| `template_name`                                    | string  | Non                             | Lorsqu'utilisé sans `use_custom_template`, nom d'un [modèle de projet intégré](../user/project/_index.md#create-a-project-from-a-built-in-template). Lorsqu'utilisé avec `use_custom_template`, nom d'un modèle de projet personnalisé. |
| `template_project_id`                              | integer | Non                             | Lorsqu'utilisé avec `use_custom_template`, ID de projet d'un modèle de projet personnalisé. L'utilisation d'un ID de projet est préférable à l'utilisation de `template_name` car `template_name` peut être ambigu. Premium et Ultimate uniquement. |
| `topics`                                           | array   | Non                             | La liste des sujets d'un projet ; indiquez un tableau de sujets qui doivent être finalement attribués au projet. |
| `use_custom_template`                              | boolean | Non                             | Utiliser un modèle de projet personnalisé d'[instance](../administration/custom_project_templates.md) ou de [groupe](../user/group/custom_project_templates.md) (avec `group_with_project_templates_id`). Premium et Ultimate uniquement. |
| `visibility`                                       | string  | Non                             | Voir [le niveau de visibilité du projet](#project-visibility-level). |
| `warn_about_potentially_unwanted_characters`       | boolean | Non                             | Activer les avertissements concernant l'utilisation de caractères potentiellement indésirables dans ce projet. |
| `wiki_enabled`                                     | boolean | Non                             | _(Obsolète)_ Activer le wiki pour ce projet. Utilisez plutôt `wiki_access_level`. |

Exemple de requête :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your-token>" \
     --header "Content-Type: application/json" --data '{
        "name": "new_project", "description": "New Project", "path": "new_project",
        "namespace_id": "42", "initialize_with_readme": "true"}' \
     --url "https://gitlab.example.com/api/v4/projects/"
```

Pour définir le niveau de visibilité des fonctionnalités individuelles du projet, consultez [Niveau de visibilité des fonctionnalités du projet](#project-feature-visibility-level).

### Créer un projet pour un utilisateur {#create-a-project-for-a-user}

{{< history >}}

- `operations_access_level` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) dans GitLab 16.0.
- `model_registry_access_level` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/412734) dans GitLab 16.7.
- `packages_enabled` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) dans GitLab 17.10.
- `package_registry_access_level` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) dans GitLab 18.5.
- `mr_default_title_template` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) dans GitLab 18.11 [avec un feature flag](../administration/feature_flags/_index.md) nommé `mr_default_title_template`. Désactivé par défaut.
- Le feature flag `mr_default_title_template` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642) dans GitLab 19.0.

{{< /history >}}

Crée un projet pour un utilisateur.

Prérequis :

- Vous devez être un administrateur.

Si votre dépôt HTTP n'est pas accessible publiquement, ajoutez des informations d'authentification à l'URL. Par exemple, `https://username:password@gitlab.company.com/group/project.git` où `password` est une clé d'accès public avec la portée `api` activée.

```plaintext
POST /projects/user/:user_id
```

Attributs généraux du projet pris en charge :

| Attribut                                          | Type    | Obligatoire | Description |
|:---------------------------------------------------|:--------|:---------|:------------|
| `name`                                             | string  | Oui      | Le nom du nouveau projet. |
| `user_id`                                          | integer | Oui      | L'ID utilisateur du propriétaire du projet. |
| `allow_merge_on_skipped_pipeline`                  | boolean | Non       | Définir si les merge requests peuvent être fusionnées avec des jobs ignorés. |
| `approvals_before_merge`                           | integer | Non       | Combien d'approbateurs devraient approuver les merge requests par défaut. [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) dans GitLab 16.0. Pour configurer les règles d'approbation, consultez [l'API d'approbation des merge requests](merge_request_approvals.md). Premium et Ultimate uniquement. |
| `auto_cancel_pending_pipelines`                    | string  | Non       | Annuler automatiquement les pipelines en attente. Cette action bascule entre un état activé et un état désactivé ; ce n'est pas un booléen. |
| `auto_devops_deploy_strategy`                      | string  | Non       | Stratégie de déploiement automatique (`continuous`, `manual` ou `timed_incremental`). |
| `auto_devops_enabled`                              | boolean | Non       | Activer Auto DevOps pour ce projet. |
| `autoclose_referenced_issues`                      | boolean | Non       | Définir si les tickets référencés sont automatiquement fermés sur la branche par défaut. |
| `avatar`                                           | mixte   | Non       | Fichier image pour l'avatar du projet. |
| `build_git_strategy`                               | string  | Non       | La stratégie Git. La valeur par défaut est `fetch`. |
| `build_timeout`                                    | integer | Non       | Le temps maximum, en secondes, qu'un job peut s'exécuter. |
| `ci_config_path`                                   | string  | Non       | Le chemin vers le fichier de configuration CI. |
| `container_registry_enabled`                       | boolean | Non       | _(Obsolète)_ Activer le registre de conteneurs pour ce projet. Utilisez plutôt `container_registry_access_level`. |
| `default_branch`                                   | string  | Non       | Le nom de la [branche par défaut](../user/project/repository/branches/default.md). Requiert que `initialize_with_readme` soit `true`. |
| `description`                                      | string  | Non       | Courte description du projet. |
| `emails_disabled`                                  | boolean | Non       | _(Obsolète)_ Désactiver les notifications par e-mail. Utilisez `emails_enabled` à la place |
| `emails_enabled`                                   | boolean | Non       | Activer les notifications par e-mail. |
| `enforce_auth_checks_on_uploads`                   | boolean | Non       | Appliquer les [vérifications d'authentification](../security/user_file_uploads.md#enable-authorization-checks-for-all-media-files) sur les téléversements. |
| `external_authorization_classification_label`      | string  | Non       | Le label de classification pour le projet. Premium et Ultimate uniquement. |
| `group_runners_enabled`                            | boolean | Non       | Activer les runners de groupe pour ce projet. |
| `group_with_project_templates_id`                  | integer | Non       | Pour les modèles personnalisés au niveau du groupe, spécifie l'ID du groupe à partir duquel tous les modèles de projets personnalisés sont issus. Laisser vide pour les modèles au niveau de l'instance. Requiert que `use_custom_template` soit vrai. Premium et Ultimate uniquement. |
| `import_url`                                       | string  | Non       | URL pour importer le dépôt. |
| `initialize_with_readme`                           | boolean | Non       | `false` par défaut. |
| `issue_branch_template`                            | string  | Non       | Modèle utilisé pour suggérer des noms pour les [branches créées à partir de tickets](../user/project/merge_requests/creating_merge_requests.md#from-an-issue). _([Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/21243) dans GitLab 15.6.)_ |
| `issues_enabled`                                   | boolean | Non       | _(Obsolète)_ Activer les tickets pour ce projet. Utilisez plutôt `issues_access_level`. |
| `jobs_enabled`                                     | boolean | Non       | _(Obsolète)_ Activer les jobs pour ce projet. Utilisez plutôt `builds_access_level`. |
| `lfs_enabled`                                      | boolean | Non       | Activer LFS. |
| `merge_commit_template`                            | string  | Non       | [Modèle](../user/project/merge_requests/commit_templates.md) utilisé pour créer le message de commit de fusion dans les merge requests. |
| `merge_method`                                     | string  | Non       | Définir la [méthode de fusion](../user/project/merge_requests/methods/_index.md) du projet. Peut être `merge` (commit de fusion), `rebase_merge` (commit de fusion avec historique semi-linéaire) ou `ff` (fusion en avance rapide). |
| `merge_requests_enabled`                           | boolean | Non       | _(Obsolète)_ Activer les merge requests pour ce projet. Utilisez plutôt `merge_requests_access_level`. |
| `mr_default_title_template`                        | string  | Non       | [Modèle](../user/project/merge_requests/title_templates.md) utilisé pour définir le titre par défaut des merge requests. |
| `mirror_trigger_builds`                            | boolean | Non       | La mise en miroir en extraction déclenche des builds. Premium et Ultimate uniquement. |
| `mirror`                                           | boolean | Non       | Active la mise en miroir en extraction dans un projet. Premium et Ultimate uniquement. |
| `namespace_id`                                     | integer | Non       | Espace de nommage pour le nouveau projet (par défaut, l'espace de nommage de l'utilisateur actuel). |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | Non       | Définir si les merge requests ne peuvent être fusionnées que lorsque toutes les discussions sont résolues. |
| `only_allow_merge_if_all_status_checks_passed`     | boolean | Non       | Indique que les fusions de merge requests doivent être bloquées tant que toutes les vérifications de statut n'ont pas réussi. Par défaut : false. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/369859) dans GitLab 15.5 avec le feature flag `only_allow_merge_if_all_status_checks_passed` désactivé par défaut. Ultimate uniquement. |
| `only_allow_merge_if_pipeline_succeeds`            | boolean | Non       | Définir si les merge requests ne peuvent être fusionnées qu'avec des jobs réussis. |
| `packages_enabled`                                 | boolean | Non       | [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) dans GitLab 17.10. Activer ou désactiver la fonctionnalité de dépôt de paquets. Utilisez plutôt `package_registry_access_level`. |
| `package_registry_access_level`                    | string  | Non       | Activer ou désactiver la fonctionnalité de dépôt de paquets. |
| `path`                                             | string  | Non       | Nom de dépôt personnalisé pour le nouveau projet. Par défaut, généré à partir du nom. |
| `printing_merge_request_link_enabled`              | boolean | Non       | Afficher le lien pour créer/voir une merge request lors d'un push depuis la ligne de commande. |
| `public_builds`                                    | boolean | Non       | _(Obsolète)_ Si `true`, les jobs peuvent être consultés par des non-membres du projet. Utilisez plutôt `public_jobs`. |
| `public_jobs`                                      | boolean | Non       | Si `true`, les jobs peuvent être consultés par des non-membres du projet. |
| `repository_object_format`                         | string  | Non       | Format d'objet du dépôt. La valeur par défaut est `sha1`. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/419887) dans GitLab 16.9. |
| `remove_source_branch_after_merge`                 | boolean | Non       | Activer l'option `Delete source branch` par défaut pour toutes les nouvelles merge requests. |
| `repository_storage`                               | string  | Non       | Sur quel segment de stockage se trouve le dépôt. _(administrateurs uniquement)_ |
| `request_access_enabled`                           | boolean | Non       | Permettre aux utilisateurs de demander l'accès en tant que membre. |
| `resolve_outdated_diff_discussions`                | boolean | Non       | Résoudre automatiquement les discussions des diffs de merge request sur les lignes modifiées lors d'un push. |
| `shared_runners_enabled`                           | boolean | Non       | Activer les runners d'instance pour ce projet. |
| `show_default_award_emojis`                        | boolean | Non       | Afficher les réactions emoji par défaut. |
| `snippets_enabled`                                 | boolean | Non       | _(Obsolète)_ Activer les extraits de code pour ce projet. Utilisez plutôt `snippets_access_level`. |
| `squash_commit_template`                           | string  | Non       | [Modèle](../user/project/merge_requests/commit_templates.md) utilisé pour créer le message de commit squash dans les merge requests. |
| `squash_option`                                    | string  | Non       | L'une des valeurs suivantes : `never`, `always`, `default_on` ou `default_off`. |
| `suggestion_commit_message`                        | string  | Non       | Le message de commit utilisé pour appliquer les [suggestions](../user/project/merge_requests/reviews/suggestions.md) de merge requests. |
| `tag_list`                                         | array   | Non       | _([Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) dans GitLab 14.0)_ La liste des tags d'un projet ; saisissez le tableau des tags qui doivent être finalement assignés au projet. Utilisez plutôt `topics`. |
| `template_name`                                    | string  | Non       | Lorsqu'utilisé sans `use_custom_template`, nom d'un [modèle de projet intégré](../user/project/_index.md#create-a-project-from-a-built-in-template). Lorsqu'utilisé avec `use_custom_template`, nom d'un modèle de projet personnalisé. |
| `topics`                                           | array   | Non       | La liste des sujets du projet. |
| `use_custom_template`                              | boolean | Non       | Utiliser un modèle de projet personnalisé d'[instance](../administration/custom_project_templates.md) ou de [groupe](../user/group/custom_project_templates.md) (avec `group_with_project_templates_id`). Premium et Ultimate uniquement. |
| `visibility`                                       | string  | Non       | Voir [le niveau de visibilité du projet](#project-visibility-level). |
| `warn_about_potentially_unwanted_characters`       | boolean | Non       | Activer les avertissements concernant l'utilisation de caractères potentiellement indésirables dans ce projet. |
| `wiki_enabled`                                     | boolean | Non       | _(Obsolète)_ Activer le wiki pour ce projet. Utilisez plutôt `wiki_access_level`. |

Pour définir le niveau de visibilité des fonctionnalités individuelles du projet, consultez [Niveau de visibilité des fonctionnalités du projet](#project-feature-visibility-level).

### Mettre à jour un projet {#update-a-project}

{{< history >}}

- `operations_access_level` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) dans GitLab 16.0.
- `model_registry_access_level` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/412734) dans GitLab 16.7.
- `packages_enabled` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) dans GitLab 17.10.
- `package_registry_access_level` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) dans GitLab 18.5.
- `protect_merge_request_pipelines` et `ci_display_pipeline_variables` [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/584488) dans GitLab 18.10.
- `mr_default_title_template` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) dans GitLab 18.11 [avec un feature flag](../administration/feature_flags/_index.md) nommé `mr_default_title_template`. Désactivé par défaut.
- Le feature flag `mr_default_title_template` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642) dans GitLab 19.0.

{{< /history >}}

Met à jour un projet existant.

Si votre dépôt HTTP n'est pas accessible publiquement, ajoutez des informations d'authentification à l'URL `https://username:password@gitlab.company.com/group/project.git`, où `password` est une clé d'accès publique avec la portée `api` activée.

```plaintext
PUT /projects/:id
```

Attributs généraux du projet pris en charge :

| Attribut                                          | Type              | Obligatoire | Description |
|:---------------------------------------------------|:------------------|:---------|:------------|
| `id`                                               | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `allow_merge_on_skipped_pipeline`                  | boolean           | Non       | Définir si les merge requests peuvent être fusionnées avec des jobs ignorés. |
| `allow_pipeline_trigger_approve_deployment`        | boolean           | Non       | Définir si le déclencheur d'un pipeline est autorisé ou non à approuver des déploiements. Premium et Ultimate uniquement. |
| `only_allow_merge_if_all_status_checks_passed`     | boolean           | Non       | Indique que les fusions de merge requests doivent être bloquées tant que toutes les vérifications de statut n'ont pas réussi. Par défaut : false.<br/><br/>[Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/369859) dans GitLab 15.5 avec le feature flag `only_allow_merge_if_all_status_checks_passed` désactivé par défaut. Le feature flag a été activé par défaut dans GitLab 15.9. Ultimate uniquement. |
| `approvals_before_merge`                           | integer           | Non       | Combien d'approbateurs devraient approuver les merge requests par défaut. [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) dans GitLab 16.0. Pour configurer les règles d'approbation, consultez [l'API d'approbation des merge requests](merge_request_approvals.md). Premium et Ultimate uniquement. |
| `auto_cancel_pending_pipelines`                    | string            | Non       | Annuler automatiquement les pipelines en attente. Cette action bascule entre un état activé et un état désactivé ; ce n'est pas un booléen. |
| `auto_devops_deploy_strategy`                      | string            | Non       | Stratégie de déploiement automatique (`continuous`, `manual`, ou `timed_incremental`). |
| `auto_devops_enabled`                              | boolean           | Non       | Activer Auto DevOps pour ce projet. |
| `auto_duo_code_review_enabled`                     | boolean           | Non       | Activer les revues automatiques par GitLab Duo sur les merge requests. Voir [GitLab Duo dans les merge requests](../user/project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code). Ultimate uniquement. |
| `autoclose_referenced_issues`                      | boolean           | Non       | Définir si les tickets référencés sont automatiquement fermés sur la branche par défaut. |
| `avatar`                                           | mixte             | Non       | Fichier image pour l'avatar du projet. |
| `build_git_strategy`                               | string            | Non       | La stratégie Git. La valeur par défaut est `fetch`. |
| `build_timeout`                                    | integer           | Non       | Le temps maximum, en secondes, qu'un job peut s'exécuter. |
| `ci_config_path`                                   | string            | Non       | Le chemin vers le fichier de configuration CI. |
| `ci_default_git_depth`                             | integer           | Non       | Nombre de révisions par défaut pour le [clonage superficiel](../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone). |
| `ci_delete_pipelines_in_seconds`                   | integer           | Non       | Les pipelines plus anciens que la durée configurée sont supprimés. |
| `ci_display_pipeline_variables`                    | boolean           | Non       | Afficher toutes les variables définies manuellement dans la page de détails du pipeline après l'exécution manuelle d'un pipeline. |
| `ci_forward_deployment_enabled`                    | boolean           | Non       | Activer ou désactiver la fonctionnalité [Empêcher les jobs de déploiement obsolètes](../ci/pipelines/settings.md#prevent-outdated-deployment-jobs). |
| `ci_forward_deployment_rollback_allowed`           | boolean           | Non       | Activer ou désactiver la fonctionnalité [Autoriser les reprises de jobs pour les déploiements en rollback](../ci/pipelines/settings.md#prevent-outdated-deployment-jobs). |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | boolean           | Non       | Activer ou désactiver l'[exécution des pipelines dans le projet parent pour les merge requests issues de duplications](../ci/pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project). _([Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/325189) dans GitLab 15.3.)_ |
| `ci_id_token_sub_claim_components`                 | array             | Non       | Champs inclus dans le claim `sub` du [jeton d'identité](../ci/secrets/id_token_authentication.md). Accepte un tableau commençant par `project_path`. Le tableau peut également inclure `ref_type`, `ref`, `ref_protected`, `environment_protected`, et `deployment_tier`. La valeur par défaut est `["project_path", "ref_type", "ref"]`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/477260) dans GitLab 17.10. Prise en charge de `environment_protected` et `deployment_tier` introduite dans GitLab 18.7. |
| `ci_separated_caches`                              | boolean           | Non       | Définir si les caches doivent ou non être [séparés](../ci/caching/_index.md#cache-key-names) selon le statut de protection de la branche. |
| `ci_restrict_pipeline_cancellation_role`           | string            | Non       | Définir le [rôle requis pour annuler un pipeline ou un job](../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs). L'une des valeurs suivantes : `developer`, `maintainer`, ou `no_one`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/429921) dans GitLab 16.8. Premium et Ultimate uniquement. |
| `ci_pipeline_variables_minimum_override_role`      | string            | Non       | Vous pouvez spécifier quel rôle peut remplacer les variables. L'une des valeurs suivantes : `owner`, `maintainer`, `developer` ou `no_one_allowed`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/440338) dans GitLab 17.1. Dans GitLab 17.1 à 17.7, `restrict_user_defined_variables` doit être activé. |
| `ci_push_repository_for_job_token_allowed`         | boolean           | Non       | Activer ou désactiver la possibilité de pousser vers le dépôt du projet en utilisant un jeton de job. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/389060) dans GitLab 17.2. |
| `container_expiration_policy_attributes`           | hash              | Non       | Mettre à jour la politique de nettoyage des images pour ce projet. Accepte : `cadence` (chaîne), `keep_n` (entier), `older_than` (chaîne), `name_regex` (chaîne), `name_regex_delete` (chaîne), `name_regex_keep` (chaîne), `enabled` (booléen). |
| `container_registry_enabled`                       | boolean           | Non       | _(Obsolète)_ Activer le registre de conteneurs pour ce projet. Utilisez plutôt `container_registry_access_level`. |
| `default_branch`                                   | string            | Non       | Le nom de la [branche par défaut](../user/project/repository/branches/default.md). |
| `description`                                      | string            | Non       | Courte description du projet. |
| `duo_remote_flows_enabled`                         | boolean           | Non       | Déterminer si les [flows](../user/duo_agent_platform/flows/_index.md) peuvent s'exécuter dans votre projet. |
| `duo_sast_fp_detection_enabled` | boolean | Non | Activer ou désactiver la détection des faux positifs SAST. Voir [activer la détection des faux positifs SAST](../user/application_security/vulnerabilities/false_positive_detection.md#turn-on-for-a-project). |
| `duo_sast_vr_workflow_enabled` | boolean | Non | Activer ou désactiver le workflow de résolution des SAST vulnérabilités. Voir [activer le workflow de résolution des vulnérabilités SAST](../user/application_security/vulnerabilities/agentic_vulnerability_resolution.md#turn-on-for-a-project). |
| `emails_disabled`                                  | boolean           | Non       | _(Obsolète)_ Désactiver les notifications par e-mail. Utilisez `emails_enabled` à la place |
| `emails_enabled`                                   | boolean           | Non       | Activer les notifications par e-mail. |
| `enforce_auth_checks_on_uploads`                   | boolean           | Non       | Appliquer les [vérifications d'authentification](../security/user_file_uploads.md#enable-authorization-checks-for-all-media-files) sur les téléversements. |
| `external_authorization_classification_label`      | string            | Non       | Le label de classification pour le projet. Premium et Ultimate uniquement. |
| `group_runners_enabled`                            | boolean           | Non       | Activer les runners de groupe pour ce projet. |
| `import_url`                                       | string            | Non       | URL depuis laquelle le dépôt a été importé. |
| `issues_enabled`                                   | boolean           | Non       | _(Obsolète)_ Activer les tickets pour ce projet. Utilisez plutôt `issues_access_level`. |
| `issues_template` | string | Non | Description par défaut pour les nouveaux tickets. Formaté en GitLab Flavored Markdown. Premium et Ultimate uniquement. |
| `merge_requests_template` | string | Non | Description par défaut pour les nouvelles merge requests. Formaté en GitLab Flavored Markdown. Premium et Ultimate uniquement. |
| `jobs_enabled`                                     | boolean           | Non       | _(Obsolète)_ Activer les jobs pour ce projet. Utilisez plutôt `builds_access_level`. |
| `keep_latest_artifact`                             | boolean           | Non       | Désactiver ou activer la possibilité de conserver le dernier artefact de job pour ce projet. |
| `lfs_enabled`                                      | boolean           | Non       | Activer LFS. |
| `max_artifacts_size`                               | integer           | Non       | La taille maximale de fichier en mégaoctets pour les artefacts de job individuels. |
| `merge_commit_template`                            | string            | Non       | [Modèle](../user/project/merge_requests/commit_templates.md) utilisé pour créer le message de commit de fusion dans les merge requests. |
| `merge_method`                                     | string            | Non       | Définir la [méthode de fusion](../user/project/merge_requests/methods/_index.md) du projet. Peut être `merge` (commit de fusion), `rebase_merge` (commit de fusion avec historique semi-linéaire) ou `ff` (fusion en avance rapide). |
| `merge_pipelines_enabled`                          | boolean           | Non       | Activer ou désactiver les pipelines de résultats fusionnés. |
| `merge_requests_enabled`                           | boolean           | Non       | _(Obsolète)_ Activer les merge requests pour ce projet. Utilisez plutôt `merge_requests_access_level`. |
| `mr_default_title_template`                        | string            | Non       | [Modèle](../user/project/merge_requests/title_templates.md) utilisé pour définir le titre par défaut des merge requests. |
| `merge_trains_enabled`                             | boolean           | Non       | Activer ou désactiver les merge trains. |
| `merge_trains_skip_train_allowed`                  | boolean           | Non       | Permet aux merge requests du merge train d'être fusionnées sans attendre la fin des pipelines. |
| `max_pipelines_per_merge_train`                    | integer           | Non       | Nombre maximum de pipelines parallèles par merge train. |
| `mirror_overwrites_diverged_branches`              | boolean           | Non       | La mise en miroir en mode pull écrase les branches divergentes. Premium et Ultimate uniquement. |
| `mirror_trigger_builds`                            | boolean           | Non       | La mise en miroir en extraction déclenche des builds. Premium et Ultimate uniquement. |
| `mirror_user_id`                                   | integer           | Non       | Utilisateur responsable de toute l'activité liée à un événement de mise en miroir en mode pull. _(administrateurs uniquement)_ Premium et Ultimate uniquement. |
| `mirror`                                           | boolean           | Non       | Active la mise en miroir en extraction dans un projet. Premium et Ultimate uniquement. |
| `mr_default_target_self`                           | boolean           | Non       | Pour les projets dupliqués, cibler les merge requests vers ce projet. Si `false`, la cible est le projet amont. |
| `name`                                             | string            | Non       | Le nom du projet. |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean           | Non       | Définir si les merge requests ne peuvent être fusionnées que lorsque toutes les discussions sont résolues. |
| `only_allow_merge_if_pipeline_succeeds`            | boolean           | Non       | Définir si les merge requests ne peuvent être fusionnées qu'avec des jobs réussis. |
| `only_mirror_protected_branches`                   | boolean           | Non       | Ne mettre en miroir que les branches protégées. Premium et Ultimate uniquement. |
| `packages_enabled`                                 | boolean           | Non       | [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/454759) dans GitLab 17.10. Activer ou désactiver la fonctionnalité de dépôt de paquets. Utilisez plutôt `package_registry_access_level`. |
| `package_registry_access_level`                    | string  | Non                 | Activer ou désactiver la fonctionnalité de dépôt de paquets. |
| `path`                                             | string            | Non       | Nom de dépôt personnalisé pour le projet. Par défaut, généré à partir du nom. |
| `prevent_merge_without_jira_issue`                 | boolean           | Non       | Définir si les merge requests nécessitent un ticket associé dans Jira. Ultimate uniquement. |
| `printing_merge_request_link_enabled`              | boolean           | Non       | Afficher le lien pour créer/voir une merge request lors d'un push depuis la ligne de commande. |
| `protect_merge_request_pipelines`                  | boolean           | Non       | Activer ou désactiver le [contrôle d'accès aux variables protégées et aux runners](../ci/pipelines/merge_request_pipelines.md#control-access-to-protected-variables-and-runners). |
| `public_builds`                                    | boolean           | Non       | _(Obsolète)_ Si `true`, les jobs peuvent être consultés par des non-membres du projet. Utilisez plutôt `public_jobs`. |
| `public_jobs`                                      | boolean           | Non       | Si `true`, les jobs peuvent être consultés par des non-membres du projet. |
| `remove_source_branch_after_merge`                 | boolean           | Non       | Activer l'option `Delete source branch` par défaut pour toutes les nouvelles merge requests. |
| `repository_storage`                               | string            | Non       | Sur quel segment de stockage se trouve le dépôt. _(administrateurs uniquement)_ |
| `request_access_enabled`                           | boolean           | Non       | Permettre aux utilisateurs de demander l'accès en tant que membre. |
| `resolve_outdated_diff_discussions`                | boolean           | Non       | Résoudre automatiquement les discussions des diffs de merge request sur les lignes modifiées lors d'un push. |
| `restrict_user_defined_variables`                  | boolean           | Non       | _([Déprécié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154510) dans GitLab 17.7 en faveur de `ci_pipeline_variables_minimum_override_role`)_ N'autoriser que les utilisateurs ayant le rôle Maintainer à transmettre des variables définies par l'utilisateur lors du déclenchement d'un pipeline. Par exemple, lorsque le pipeline est déclenché depuis l'interface utilisateur, via l'API ou par un token de déclencheur. |
| `service_desk_enabled`                             | boolean           | Non       | Activer ou désactiver la fonctionnalité Service Desk. |
| `shared_runners_enabled`                           | boolean           | Non       | Activer les runners d'instance pour ce projet. |
| `show_default_award_emojis`                        | boolean           | Non       | Afficher les réactions emoji par défaut. |
| `snippets_enabled`                                 | boolean           | Non       | _(Obsolète)_ Activer les extraits de code pour ce projet. Utilisez plutôt `snippets_access_level`. |
| `issue_branch_template`                            | string            | Non       | Modèle utilisé pour suggérer des noms pour les [branches créées à partir de tickets](../user/project/merge_requests/creating_merge_requests.md#from-an-issue). _([Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/21243) dans GitLab 15.6.)_ |
| `spp_repository_pipeline_access`                   | boolean           | Non       | Autoriser les utilisateurs et les jetons à accéder en lecture seule aux configurations de politiques de sécurité depuis ce projet. Requis pour appliquer les politiques de sécurité dans les projets qui utilisent ce projet comme source de politique de sécurité. Ultimate uniquement. |
| `squash_commit_template`                           | string            | Non       | [Modèle](../user/project/merge_requests/commit_templates.md) utilisé pour créer le message de commit squash dans les merge requests. |
| `squash_option`                                    | string            | Non       | L'une des valeurs suivantes : `never`, `always`, `default_on` ou `default_off`. |
| `suggestion_commit_message`                        | string            | Non       | Le message de commit utilisé pour appliquer les suggestions de merge requests. |
| `tag_list`                                         | array             | Non       | _([Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) dans GitLab 14.0)_ La liste des tags d'un projet ; saisissez le tableau des tags qui doivent être finalement assignés au projet. Utilisez plutôt `topics`. |
| `topics`                                           | array             | Non       | La liste des sujets du projet. Cela remplace tous les sujets existants déjà ajoutés au projet. |
| `visibility`                                       | string            | Non       | Voir [le niveau de visibilité du projet](#project-visibility-level). |
| `warn_about_potentially_unwanted_characters`       | boolean           | Non       | Activer les avertissements concernant l'utilisation de caractères potentiellement indésirables dans ce projet. |
| `wiki_enabled`                                     | boolean           | Non       | _(Obsolète)_ Activer le wiki pour ce projet. Utilisez plutôt `wiki_access_level`. |
| `web_based_commit_signing_enabled`                 | boolean           | Non       | Active la signature des commits via le web pour les commits créés depuis l'interface GitLab. Disponible uniquement sur GitLab.com. |

Par exemple, pour basculer le paramètre pour les [runners d'instance sur un projet GitLab.com](../ci/runners/_index.md) :

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your-token>" \
     --url "https://gitlab.com/api/v4/projects/<your-project-ID>" \
     --data "shared_runners_enabled=true" # to turn off: "shared_runners_enabled=false"
```

Pour définir le niveau de visibilité des fonctionnalités individuelles du projet, consultez [Niveau de visibilité des fonctionnalités du projet](#project-feature-visibility-level).

### Importer des membres {#import-members}

Importe des membres depuis un autre projet.

Si le rôle du membre importateur pour le projet cible est :

- Maintainer, alors les membres ayant le rôle Owner dans le projet source sont importés avec le rôle Maintainer.
- Owner, alors les membres ayant le rôle Owner dans le projet source sont importés avec le rôle Owner.

```plaintext
POST /projects/:id/import_project_members/:project_id
```

Attributs pris en charge :

| Attribut    | Type              | Obligatoire | Description |
|:-------------|:------------------|:---------|:------------|
| `id`         | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet cible qui doit recevoir les membres. |
| `project_id` | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet source depuis lequel importer les membres. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/import_project_members/32"
```

Retourne :

- `200 OK` en cas de succès.
- `404 Project Not Found` si le projet cible ou source n'existe pas ou ne peut pas être consulté par le demandeur.
- `422 Unprocessable Entity` si l'importation des membres du projet ne s'est pas terminée avec succès.

Exemples de réponses :

- Lorsque tous les e-mails ont été envoyés avec succès (code de statut HTTP `200`) :

  ```json
  {  "status":  "success"  }
  ```

- Lorsqu'une erreur s'est produite lors de l'importation d'un ou plusieurs membres (code de statut HTTP `200`) :

  ```json
  {
    "status": "error",
    "message": {
                 "john_smith": "Some individual error message",
                 "jane_smith": "Some individual error message"
               },
    "total_members_count": 3
  }
  ```

- Lorsqu'une erreur système survient (codes de statut HTTP `404` et `422`) :

```json
{  "message":  "Import failed"  }
```

### Archiver un projet {#archive-a-project}

{{< history >}}

- `mr_default_title_template` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) dans GitLab 18.11 [avec un feature flag](../administration/feature_flags/_index.md) nommé `mr_default_title_template`. Désactivé par défaut.
- Le feature flag `mr_default_title_template` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642) dans GitLab 19.0.

{{< /history >}}

Archive le projet spécifié.

Prérequis :

- Vous devez être administrateur ou avoir le rôle Owner sur le projet.

Ce point de terminaison est idempotent. Archiver un projet déjà archivé ne modifie pas le projet.

```plaintext
POST /projects/:id/archive
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/archive"
```

Exemple de réponse :

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "repository_object_format": "sha1",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora"
  },
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": true,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "ci_display_pipeline_variables": false,
  "protect_merge_request_pipelines": true,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "allow_pipeline_trigger_approve_deployment": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "autoclose_referenced_issues": true,
  "enforce_auth_checks_on_uploads": true,
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "mr_default_title_template": null,
  "secret_push_protection_enabled": false,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

### Désarchiver un projet {#unarchive-a-project}

{{< history >}}

- `mr_default_title_template` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) dans GitLab 18.11 [avec un feature flag](../administration/feature_flags/_index.md) nommé `mr_default_title_template`. Désactivé par défaut.
- Le feature flag `mr_default_title_template` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642) dans GitLab 19.0.

{{< /history >}}

Désarchive le projet spécifié.

Prérequis :

- Vous devez être administrateur ou avoir le rôle Owner sur le projet.

Ce point de terminaison est idempotent. Désarchiver un projet qui n'est pas archivé ne modifie pas le projet.

```plaintext
POST /projects/:id/unarchive
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/unarchive"
```

Exemple de réponse :

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "repository_object_format": "sha1",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora"
  },
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": false,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "ci_display_pipeline_variables": false,
  "protect_merge_request_pipelines": true,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "allow_pipeline_trigger_approve_deployment": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "autoclose_referenced_issues": true,
  "enforce_auth_checks_on_uploads": true,
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "mr_default_title_template": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "secret_push_protection_enabled": false,
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

### Supprimer un projet {#delete-a-project}

{{< history >}}

- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) dans GitLab 16.0. Premium et Ultimate uniquement.
- [Déplacé](https://gitlab.com/groups/gitlab-org/-/epics/17208) de GitLab Premium vers GitLab Free dans GitLab 18.0.

{{< /history >}}

Prérequis :

- Vous devez être administrateur ou avoir le rôle Owner sur le projet.

Marque un projet pour suppression. Les projets sont supprimés à la fin de la période de rétention :

- Sur GitLab.com, les projets sont conservés pendant 30 jours.
- Sur GitLab Self-Managed, la période de rétention est contrôlée par les [paramètres de l'instance](../administration/settings/visibility_and_access_controls.md#deletion-protection).

Ce point de terminaison peut également supprimer immédiatement un projet précédemment marqué pour suppression.

> [!warning]
> Sur GitLab.com, après la suppression d'un projet, ses données sont conservées pendant 30 jours, et la suppression définitive n'est pas disponible. Si vous avez vraiment besoin de supprimer un projet immédiatement sur GitLab.com, vous pouvez ouvrir un [ticket de support](https://about.gitlab.com/support/).

```plaintext
DELETE /projects/:id
```

Attributs pris en charge :

| Attribut            | Type              | Obligatoire | Description |
|:---------------------|:------------------|:---------|:------------|
| `id`                 | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `full_path`          | string            | non       | Chemin complet du projet à utiliser avec `permanently_remove`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/396500) dans GitLab 15.11 pour Premium et Ultimate uniquement, puis déplacé vers GitLab Free dans la version 18.0. Pour trouver le chemin du projet, utilisez `path_with_namespace` depuis [obtenir un projet unique](projects.md#retrieve-a-project). |
| `permanently_remove` | booléen/chaîne    | non       | Supprime immédiatement un projet s'il est marqué pour suppression. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/396500) dans GitLab 15.11 pour Premium et Ultimate uniquement, puis déplacé vers GitLab Free dans la version 18.0. Désactivé sur GitLab.com et Dedicated. |

### Restaurer un projet marqué pour suppression {#restore-a-project-marked-for-deletion}

Restaure un projet spécifié qui a été marqué pour suppression.

```plaintext
POST /projects/:id/restore
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

### Transférer un projet vers un nouvel espace de nommage {#transfer-a-project-to-a-new-namespace}

{{< history >}}

- `mr_default_title_template` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) dans GitLab 18.11 [avec un feature flag](../administration/feature_flags/_index.md) nommé `mr_default_title_template`. Désactivé par défaut.
- Le feature flag `mr_default_title_template` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642) dans GitLab 19.0.

{{< /history >}}

Transfère un projet vers un nouvel espace de nommage.

Pour plus d'informations sur les prérequis pour transférer un projet, voir [Transférer un projet vers un autre espace de nommage](../user/project/working_with_projects.md#transfer-a-project).

```plaintext
PUT /projects/:id/transfer
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|:------------|:------------------|:---------|:------------|
| `id`        | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `namespace` | entier ou chaîne de caractères | Oui      | L'ID ou le chemin de l'espace de nommage vers lequel transférer le projet. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/transfer?namespace=14"
```

Exemple de réponse :

```json
  {
  "id": 7,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "name": "hello-world",
  "name_with_namespace": "cute-cats / hello-world",
  "path": "hello-world",
  "path_with_namespace": "cute-cats/hello-world",
  "created_at": "2020-10-15T16:25:22.415Z",
  "updated_at": "2020-10-15T16:25:22.415Z",
  "default_branch": "main",
  "tag_list": [], //deprecated, use `topics` instead
  "topics": [],
  "ssh_url_to_repo": "git@gitlab.example.com:cute-cats/hello-world.git",
  "http_url_to_repo": "https://gitlab.example.com/cute-cats/hello-world.git",
  "web_url": "https://gitlab.example.com/cute-cats/hello-world",
  "readme_url": "https://gitlab.example.com/cute-cats/hello-world/-/blob/main/README.md",
  "avatar_url": null,
  "forks_count": 0,
  "star_count": 0,
  "last_activity_at": "2020-10-15T16:25:22.415Z",
  "namespace": {
    "id": 18,
    "name": "cute-cats",
    "path": "cute-cats",
    "kind": "group",
    "full_path": "cute-cats",
    "parent_id": null,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/cute-cats"
  },
  "container_registry_image_prefix": "registry.example.com/cute-cats/hello-world",
  "_links": {
    "self": "https://gitlab.example.com/api/v4/projects/7",
    "issues": "https://gitlab.example.com/api/v4/projects/7/issues",
    "merge_requests": "https://gitlab.example.com/api/v4/projects/7/merge_requests",
    "repo_branches": "https://gitlab.example.com/api/v4/projects/7/repository/branches",
    "labels": "https://gitlab.example.com/api/v4/projects/7/labels",
    "events": "https://gitlab.example.com/api/v4/projects/7/events",
    "members": "https://gitlab.example.com/api/v4/projects/7/members"
  },
  "packages_enabled": true, // deprecated, use package_registry_access_level instead
  "package_registry_access_level": "enabled",
  "empty_repo": false,
  "archived": false,
  "visibility": "private",
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": true, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "enabled",
  "container_expiration_policy": {
    "cadence": "7d",
    "enabled": false,
    "keep_n": null,
    "older_than": null,
    "name_regex": null,
    "name_regex_keep": null,
    "next_run_at": "2020-10-22T16:25:22.746Z"
  },
  "issues_enabled": true,
  "merge_requests_enabled": true,
  "wiki_enabled": true,
  "jobs_enabled": true,
  "snippets_enabled": true,
  "service_desk_enabled": false,
  "service_desk_address": null,
  "can_create_merge_request_in": true,
  "issues_access_level": "enabled",
  "repository_access_level": "enabled",
  "merge_requests_access_level": "enabled",
  "forking_access_level": "enabled",
  "analytics_access_level": "enabled",
  "wiki_access_level": "enabled",
  "builds_access_level": "enabled",
  "snippets_access_level": "enabled",
  "pages_access_level": "enabled",
  "security_and_compliance_access_level": "enabled",
  "emails_disabled": null,
  "emails_enabled": null,
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "lfs_enabled": true,
  "creator_id": 2,
  "import_status": "none",
  "open_issues_count": 0,
  "ci_default_git_depth": 50,
  "public_jobs": true,
  "build_timeout": 3600,
  "auto_cancel_pending_pipelines": "enabled",
  "ci_config_path": null,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": null,
  "allow_pipeline_trigger_approve_deployment": false,
  "restrict_user_defined_variables": false,
  "request_access_enabled": true,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": true,
  "printing_merge_request_link_enabled": true,
  "merge_method": "merge",
  "squash_option": "default_on",
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "mr_default_title_template": null,
  "auto_devops_enabled": true,
  "auto_devops_deploy_strategy": "continuous",
  "autoclose_referenced_issues": true,
  "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
  "mirror": false,
  "compliance_frameworks": [],
  "warn_about_potentially_unwanted_characters": true,
  "secret_push_protection_enabled": false
}
```

#### Lister les groupes disponibles pour le transfert de projet {#list-groups-available-for-project-transfer}

Récupérer la liste des groupes vers lesquels l'utilisateur peut transférer un projet.

```plaintext
GET /projects/:id/transfer_locations
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `search`  | string            | Non       | Les noms de groupes à rechercher. |

Exemple de requête :

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/transfer_locations"
```

Exemple de réponse :

```json
[
  {
    "id": 27,
    "web_url": "https://gitlab.example.com/groups/gitlab",
    "name": "GitLab",
    "avatar_url": null,
    "full_name": "GitLab",
    "full_path": "GitLab"
  },
  {
    "id": 31,
    "web_url": "https://gitlab.example.com/groups/foobar",
    "name": "FooBar",
    "avatar_url": null,
    "full_name": "FooBar",
    "full_path": "FooBar"
  }
]
```

### Téléverser un avatar de projet {#upload-a-project-avatar}

Téléverse un avatar vers le projet spécifié.

```plaintext
PUT /projects/:id
```

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.
- Votre fichier doit faire 200 Ko ou moins. La taille d'image idéale est de 192 x 192 pixels.
- L'image doit être de l'un des types de fichiers suivants :
  - `.bmp`
  - `.gif`
  - `.ico`
  - `.jpeg`
  - `.png`
  - `.tiff`

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `avatar`  | string            | Oui      | Le fichier à téléverser. |
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Pour téléverser un avatar depuis votre système de fichiers, utilisez l'argument `--form`. Cela oblige cURL à envoyer des données en utilisant l'en-tête `Content-Type: multipart/form-data`. Le paramètre `avatar=` doit pointer vers un fichier image sur votre système de fichiers et être précédé de `@`.

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5" \
  --form "avatar=@dk.png"
```

Exemple de réponse :

```json
{
  "avatar_url": "https://gitlab.example.com/uploads/-/system/project/avatar/2/dk.png"
}
```

### Télécharger un avatar de projet {#download-a-project-avatar}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144039) dans GitLab 16.9.

{{< /history >}}

Télécharge un avatar de projet. Vous pouvez accéder à ce point de terminaison sans authentification si le projet est accessible publiquement.

```plaintext
GET /projects/:id/avatar
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/avatar"
```

### Supprimer un avatar de projet {#remove-a-project-avatar}

Pour supprimer un avatar de projet, utilisez une valeur vide pour l'attribut `avatar`.

Exemple de requête :

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "avatar=" "https://gitlab.example.com/api/v4/projects/5"
```

## Partager des projets {#share-projects}

Partager un projet avec un groupe.

Pour plus d'informations, voir [Inviter un groupe dans un projet](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project).

### Partager un projet avec un groupe {#share-a-project-with-a-group}

Partage un projet spécifié avec un groupe.

```plaintext
POST /projects/:id/share
```

Attributs pris en charge :

| Attribut      | Type              | Obligatoire | Description |
|:---------------|:------------------|:---------|:------------|
| `group_access` | integer           | Oui      | Le niveau d'accès à accorder au groupe. Valeurs possibles : `5` (Accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `group_id`     | integer           | Oui      | L'ID du groupe avec lequel partager. |
| `id`           | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `expires_at`   | string            | Non       | Date d'expiration du partage au format ISO 8601. Par exemple, `2016-09-26`. |

### Supprimer un lien de projet partagé dans un groupe {#delete-a-shared-project-link-in-a-group}

Annule le partage d'un projet avec un groupe spécifié. Retourne `204` et aucun contenu en cas de succès.

```plaintext
DELETE /projects/:id/share/:group_id
```

Attributs pris en charge :

| Attribut  | Type              | Obligatoire | Description |
|:-----------|:------------------|:---------|:------------|
| `group_id` | integer           | Oui      | L'ID du groupe. |
| `id`       | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/share/17"
```

## Démarrer la tâche de maintenance pour un projet {#start-the-housekeeping-task-for-a-project}

Démarre la [tâche de maintenance](../administration/housekeeping.md) pour un projet.

```plaintext
POST /projects/:id/housekeeping
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `task`    | string            | Non       | `prune` pour déclencher l'élagage manuel des objets inaccessibles ou `eager` pour déclencher une maintenance intensive. |

## Analyse de sécurité en temps réel {#real-time-security-scan}

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com
- Statut : Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/479210) dans GitLab 17.6. Cette fonctionnalité est une [expérimentation](../policy/development_stages_support.md).

{{< /history >}}

Retourne les résultats de l'analyse SAST pour un seul fichier en temps réel.

```plaintext
POST /projects/:id/security_scans/sast/scan
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
 --header "Content-Type: application/json" \
 --data '{
  "file_path":"src/main.c",
  "content":"#include<string.h>\nint main(int argc, char **argv) {\n  char buff[128];\n  strcpy(buff, argv[1]);\n  return 0;\n}\n"
 }' \
 --url "https://gitlab.example.com/api/v4/projects/:id/security_scans/sast/scan"
```

Exemple de réponse :

```json
{
  "vulnerabilities": [
    {
      "name": "Insecure string processing function (strcpy)",
      "description": "The `strcpy` family of functions do not provide the ability to limit or check buffer\nsizes before copying to a destination buffer. This can lead to buffer overflows. Consider\nusing more secure alternatives such as `strncpy` and provide the correct limit to the\ndestination buffer and ensure the string is null terminated.\n\nFor more information please see: https://linux.die.net/man/3/strncpy\n\nIf developing for C Runtime Library (CRT), more secure versions of these functions should be\nused, see:\nhttps://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/strncpy-s-strncpy-s-l-wcsncpy-s-wcsncpy-s-l-mbsncpy-s-mbsncpy-s-l?view=msvc-170\n",
      "severity": "High",
      "location": {
        "file": "src/main.c",
        "start_line": 5,
        "end_line": 5,
        "start_column": 3,
        "end_column": 23
      }
    }
  ]
}
```

## Télécharger un instantané d'un dépôt Git {#download-snapshot-of-a-git-repository}

Ce point de terminaison est uniquement accessible par un utilisateur administrateur.

Télécharge un instantané du dépôt Git du projet (ou du wiki, si demandé). Cet instantané est toujours au format [tar](https://en.wikipedia.org/wiki/Tar_(computing)) non compressé.

Si un dépôt est corrompu au point où `git clone` ne fonctionne plus, l'instantané peut permettre de récupérer une partie des données.

```plaintext
GET /projects/:id/snapshot
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `wiki`    | boolean           | Non       | Indique si le wiki doit être téléchargé plutôt que le dépôt du projet. |

## Récupérer le chemin vers le stockage du dépôt {#retrieve-the-path-to-repository-storage}

Récupère le chemin vers le stockage du dépôt pour le projet spécifié. Si vous utilisez Gitaly Cluster (Praefect), consultez plutôt les [chemins de réplique générés par Praefect](../administration/gitaly/praefect/_index.md#praefect-generated-replica-paths).

Disponible pour les administrateurs uniquement.

```plaintext
GET /projects/:id/storage
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

```json
[
  {
    "project_id": 1,
    "disk_path": "@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b",
    "created_at": "2012-10-12T17:04:47Z",
    "repository_storage": "default"
  }
]
```

## Statut de la protection push secrète {#secret-push-protection-status}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160960) dans GitLab 17.3.
- [Renommé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186602) depuis `setPreReceiveSecretDetection` dans GitLab 17.11.

{{< /history >}}

Si vous avez le rôle Responsable sécurité, Developer, Maintainer ou Owner, les requêtes suivantes peuvent également retourner la valeur `secret_push_protection_enabled`. Certaines de ces requêtes ont des exigences plus strictes concernant les rôles. Référez-vous aux points de terminaison mentionnés précédemment pour plus de précisions. Utilisez ces informations pour déterminer si la protection push secrète est activée pour un projet. Pour modifier la valeur `secret_push_protection_enabled`, utilisez l'[API des paramètres de sécurité du projet](project_security_settings.md).

- `GET /projects`
- `GET /projects/:id`
- `GET /users/:user_id/projects`
- `GET /users/:user_id/contributed_projects`
- `PUT /projects/:project_id/transfer?namespace=:namespace_id`
- `PUT /projects/:id`
- `POST /projects`
- `POST /projects/user/:user_id`
- `POST /projects/:id/archive`
- `POST /projects/:id/unarchive`

Exemple de réponse :

```json
{
  "id": 1,
  "project_id": 3,
  "secret_push_protection_enabled": true,
  ...
}
```

## Dépannage {#troubleshooting}

### Valeur `restrict_user_defined_variables` inattendue dans la réponse {#unexpected-restrict_user_defined_variables-value-in-response}

Si vous définissez des valeurs contradictoires pour `restrict_user_defined_variables` et `ci_pipeline_variables_minimum_override_role`, les valeurs de la réponse peuvent différer de ce que vous attendez car le paramètre `pipeline_variables_minimum_override_role` a la priorité la plus haute.

Par exemple, si vous :

- Définissez `restrict_user_defined_variables` à `true` et `ci_pipeline_variables_minimum_override_role` à `developer`, la réponse retourne `restrict_user_defined_variables: false`. Définir `ci_pipeline_variables_minimum_override_role` à `developer` a la priorité et les variables ne sont pas restreintes.
- Définissez `restrict_user_defined_variables` à `false` et `ci_pipeline_variables_minimum_override_role` à `maintainer`, la réponse retourne `restrict_user_defined_variables: true` car définir `ci_pipeline_variables_minimum_override_role` à `maintainer` a la priorité et les variables sont restreintes.
