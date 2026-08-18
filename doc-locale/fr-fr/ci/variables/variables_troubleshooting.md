---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage des variables CI/CD
---

## Lister toutes les variables {#list-all-variables}

Vous pouvez lister toutes les variables disponibles pour un script avec la commande `export` dans Bash ou `dir env:` dans PowerShell. Cela expose les valeurs de **l'ensemble** des variables disponibles, ce qui peut constituer un [risque de sécurité](_index.md#cicd-variable-security). Les [variables masquées](_index.md#mask-a-cicd-variable) s'affichent sous la forme `[MASKED]`.

Par exemple, avec Bash :

```yaml
job_name:
  script:
    - export
```

Exemple de sortie de job log (tronquée) :

```shell
export CI_JOB_ID="50"
export CI_COMMIT_SHA="1ecfd275763eff1d6b4844ea3168962458c9f27a"
export CI_COMMIT_SHORT_SHA="1ecfd275"
export CI_COMMIT_REF_NAME="main"
export CI_REPOSITORY_URL="https://gitlab-ci-token:[MASKED]@example.com/gitlab-org/gitlab.git"
export CI_COMMIT_TAG="1.0.0"
export CI_JOB_NAME="spec:other"
export CI_JOB_STAGE="test"
export CI_JOB_MANUAL="true"
export CI_JOB_TRIGGERED="true"
export CI_JOB_TOKEN="[MASKED]"
export CI_PIPELINE_ID="1000"
export CI_PIPELINE_IID="10"
export CI_PAGES_DOMAIN="gitlab.io"
export CI_PAGES_URL="https://gitlab-org.gitlab.io/gitlab"
export CI_PROJECT_ID="34"
export CI_PROJECT_DIR="/builds/gitlab-org/gitlab"
export CI_PROJECT_NAME="gitlab"
export CI_PROJECT_TITLE="GitLab"
...
```

## Activer la journalisation de débogage {#enable-debug-logging}

> [!warning]
> La journalisation de débogage peut constituer un risque de sécurité sérieux. La sortie contient le contenu de toutes les variables disponibles pour le job. La sortie est téléversée sur le serveur GitLab et visible dans les job logs.

Vous pouvez utiliser la journalisation de débogage pour résoudre les problèmes liés à la configuration du pipeline ou aux scripts de job. La journalisation de débogage expose les détails d'exécution du job qui sont habituellement masqués par le runner et rend les job logs plus détaillés. Elle expose également toutes les variables et les secrets disponibles pour le job.

Avant d'activer la journalisation de débogage, assurez-vous que seuls les membres de l'équipe peuvent consulter les job logs. Vous devriez également [supprimer les job logs](../jobs/_index.md#view-jobs-in-a-pipeline) contenant une sortie de débogage avant de rendre les journaux à nouveau publics.

Pour activer la journalisation de débogage, définissez la variable CI/CD `CI_DEBUG_TRACE` sur `true` :

```yaml
job_name:
  variables:
    CI_DEBUG_TRACE: "true"
```

Exemple de sortie (tronquée) :

```plaintext
...
export CI_SERVER_TLS_CA_FILE="/builds/gitlab-examples/ci-debug-trace.tmp/CI_SERVER_TLS_CA_FILE"
if [[ -d "/builds/gitlab-examples/ci-debug-trace/.git" ]]; then
  echo $'\''\x1b[32;1mFetching changes...\x1b[0;m'\''
  $'\''cd'\'' "/builds/gitlab-examples/ci-debug-trace"
  $'\''git'\'' "config" "fetch.recurseSubmodules" "false"
  $'\''rm'\'' "-f" ".git/index.lock"
  $'\''git'\'' "clean" "-ffdx"
  $'\''git'\'' "reset" "--hard"
  $'\''git'\'' "remote" "set-url" "origin" "https://gitlab-ci-token:xxxxxxxxxxxxxxxxxxxx@example.com/gitlab-examples/ci-debug-trace.git"
  $'\''git'\'' "fetch" "origin" "--prune" "+refs/heads/*:refs/remotes/origin/*" "+refs/tags/*:refs/tags/lds"
++ CI_BUILDS_DIR=/builds
++ export CI_PROJECT_DIR=/builds/gitlab-examples/ci-debug-trace
++ CI_PROJECT_DIR=/builds/gitlab-examples/ci-debug-trace
++ export CI_CONCURRENT_ID=87
++ CI_CONCURRENT_ID=87
++ export CI_CONCURRENT_PROJECT_ID=0
++ CI_CONCURRENT_PROJECT_ID=0
++ export CI_SERVER=yes
++ CI_SERVER=yes
++ mkdir -p /builds/gitlab-examples/ci-debug-trace.tmp
++ echo -n '-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----'
++ export CI_SERVER_TLS_CA_FILE=/builds/gitlab-examples/ci-debug-trace.tmp/CI_SERVER_TLS_CA_FILE
++ CI_SERVER_TLS_CA_FILE=/builds/gitlab-examples/ci-debug-trace.tmp/CI_SERVER_TLS_CA_FILE
++ export CI_PIPELINE_ID=52666
++ CI_PIPELINE_ID=52666
++ export CI_PIPELINE_URL=https://gitlab.com/gitlab-examples/ci-debug-trace/pipelines/52666
++ CI_PIPELINE_URL=https://gitlab.com/gitlab-examples/ci-debug-trace/pipelines/52666
++ export CI_JOB_ID=7046507
++ CI_JOB_ID=7046507
++ export CI_JOB_URL=https://gitlab.com/gitlab-examples/ci-debug-trace/-/jobs/379424655
++ CI_JOB_URL=https://gitlab.com/gitlab-examples/ci-debug-trace/-/jobs/379424655
++ export CI_JOB_TOKEN=[MASKED]
++ CI_JOB_TOKEN=[MASKED]
++ export CI_REGISTRY_USER=gitlab-ci-token
++ CI_REGISTRY_USER=gitlab-ci-token
++ export CI_REGISTRY_PASSWORD=[MASKED]
++ CI_REGISTRY_PASSWORD=[MASKED]
++ export CI_REPOSITORY_URL=https://gitlab-ci-token:[MASKED]@gitlab.com/gitlab-examples/ci-debug-trace.git
++ CI_REPOSITORY_URL=https://gitlab-ci-token:[MASKED]@gitlab.com/gitlab-examples/ci-debug-trace.git
++ export CI_JOB_NAME=debug_trace
++ CI_JOB_NAME=debug_trace
++ export CI_JOB_STAGE=test
++ CI_JOB_STAGE=test
++ export CI_NODE_TOTAL=1
++ CI_NODE_TOTAL=1
++ export CI=true
++ CI=true
++ export GITLAB_CI=true
++ GITLAB_CI=true
++ export CI_SERVER_URL=https://gitlab.com:3000
++ CI_SERVER_URL=https://gitlab.com:3000
++ export CI_SERVER_HOST=gitlab.com
++ CI_SERVER_HOST=gitlab.com
++ export CI_SERVER_PORT=3000
++ CI_SERVER_PORT=3000
++ export CI_SERVER_SHELL_SSH_HOST=gitlab.com
++ CI_SERVER_SHELL_SSH_HOST=gitlab.com
++ export CI_SERVER_SHELL_SSH_PORT=22
++ CI_SERVER_SHELL_SSH_PORT=22
++ export CI_SERVER_PROTOCOL=https
++ CI_SERVER_PROTOCOL=https
++ export CI_SERVER_NAME=GitLab
++ CI_SERVER_NAME=GitLab
++ export GITLAB_FEATURES=audit_events,burndown_charts,code_owners,contribution_analytics,description_diffs,elastic_search,group_bulk_edit,group_burndown_charts,group_webhooks,issuable_default_templates,issue_weights,jenkins_integration,ldap_group_sync,member_lock,merge_request_approvers,multiple_issue_assignees,multiple_ldap_servers,multiple_merge_request_assignees,protected_refs_for_users,push_rules,related_issues,repository_mirrors,repository_size_limit,scoped_issue_board,usage_quotas,wip_limits,admin_audit_log,auditor_user,batch_comments,blocking_merge_requests,board_assignee_lists,board_milestone_lists,ci_cd_projects,cluster_deployments,code_analytics,code_owner_approval_required,commit_committer_check,cross_project_pipelines,custom_file_templates,custom_file_templates_for_namespace,custom_project_templates,custom_prometheus_metrics,cycle_analytics_for_groups,db_load_balancing,default_project_deletion_protection,dependency_proxy,deploy_board,design_management,email_additional_text,extended_audit_events,external_authorization_service_api_management,feature_flags,file_locks,geo,github_integration,group_allowed_email_domains,group_project_templates,group_saml,issues_analytics,jira_dev_panel_integration,ldap_group_sync_filter,merge_pipelines,merge_request_performance_metrics,merge_trains,metrics_reports,multiple_approval_rules,multiple_group_issue_boards,object_storage,operations_dashboard,packages,productivity_analytics,project_aliases,protected_environments,reject_unsigned_commits,required_ci_templates,scoped_labels,service_desk,smartcard_auth,group_timelogs,type_of_work_analytics,unprotection_restrictions,ci_project_subscriptions,container_scanning,dast,dependency_scanning,epics,group_ip_restriction,incident_management,insights,license_management,personal_access_token_expiration_policy,pod_logs,prometheus_alerts,report_approver_rules,sast,security_dashboard,tracing,web_ide_terminal
++ GITLAB_FEATURES=audit_events,burndown_charts,code_owners,contribution_analytics,description_diffs,elastic_search,group_bulk_edit,group_burndown_charts,group_webhooks,issuable_default_templates,issue_weights,jenkins_integration,ldap_group_sync,member_lock,merge_request_approvers,multiple_issue_assignees,multiple_ldap_servers,multiple_merge_request_assignees,protected_refs_for_users,push_rules,related_issues,repository_mirrors,repository_size_limit,scoped_issue_board,usage_quotas,wip_limits,admin_audit_log,auditor_user,batch_comments,blocking_merge_requests,board_assignee_lists,board_milestone_lists,ci_cd_projects,cluster_deployments,code_analytics,code_owner_approval_required,commit_committer_check,cross_project_pipelines,custom_file_templates,custom_file_templates_for_namespace,custom_project_templates,custom_prometheus_metrics,cycle_analytics_for_groups,db_load_balancing,default_project_deletion_protection,dependency_proxy,deploy_board,design_management,email_additional_text,extended_audit_events,external_authorization_service_api_management,feature_flags,file_locks,geo,github_integration,group_allowed_email_domains,group_project_templates,group_saml,issues_analytics,jira_dev_panel_integration,ldap_group_sync_filter,merge_pipelines,merge_request_performance_metrics,merge_trains,metrics_reports,multiple_approval_rules,multiple_group_issue_boards,object_storage,operations_dashboard,packages,productivity_analytics,project_aliases,protected_environments,reject_unsigned_commits,required_ci_templates,scoped_labels,service_desk,smartcard_auth,group_timelogs,type_of_work_analytics,unprotection_restrictions,ci_project_subscriptions,cluster_health,container_scanning,dast,dependency_scanning,epics,group_ip_restriction,incident_management,insights,license_management,personal_access_token_expiration_policy,pod_logs,prometheus_alerts,report_approver_rules,sast,security_dashboard,tracing,web_ide_terminal
++ export CI_PROJECT_ID=17893
++ CI_PROJECT_ID=17893
++ export CI_PROJECT_NAME=ci-debug-trace
++ CI_PROJECT_NAME=ci-debug-trace
...
```

### Accès à la journalisation de débogage {#access-to-debug-logging}

L'accès à la journalisation de débogage est limité aux [utilisateurs disposant du rôle Developer, Maintainer ou Owner](../../user/permissions.md#project-cicd). Les utilisateurs disposant d'un rôle inférieur ne peuvent pas consulter les journaux lorsque la journalisation de débogage est activée avec une variable dans :

- Le fichier [`.gitlab-ci.yml`](_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file).
- Les variables CI/CD définies dans l'interface utilisateur GitLab.

> [!warning]
> Si vous ajoutez `CI_DEBUG_TRACE` en tant que variable locale aux runners, des journaux de débogage sont générés et visibles par tous les utilisateurs ayant accès aux job logs. Les niveaux de permission ne sont pas vérifiés par le runner, c'est pourquoi vous ne devriez utiliser la variable que dans GitLab lui-même.

## Erreur `argument list too long` {#argument-list-too-long-error}

Ce problème survient lorsque la longueur combinée de toutes les variables CI/CD définies pour un job dépasse la limite imposée par le shell dans lequel le job s'exécute. Cela inclut les noms et les valeurs des variables prédéfinies et des variables définies par l'utilisateur. Cette limite est généralement désignée par `ARG_MAX` et dépend du shell et du système d'exploitation. Ce problème survient également lorsque le contenu d'une seule variable de [type fichier](_index.md#use-file-type-cicd-variables) dépasse `ARG_MAX`.

Pour plus d'informations, consultez le [ticket 392406](https://gitlab.com/gitlab-org/gitlab/-/issues/392406#note_1414219596).

Comme solution de contournement, vous pouvez :

- Utiliser des variables CI/CD de [type fichier](_index.md#use-file-type-cicd-variables) pour les grandes variables d'environnement lorsque cela est possible.
- Si une grande variable unique est plus grande que `ARG_MAX`, essayez d'utiliser les [Secure Files](../secure_files/_index.md), ou importez le fichier dans le job par un autre mécanisme.

## Erreur `Insufficient permissions to set pipeline variables` pour un pipeline downstream {#insufficient-permissions-to-set-pipeline-variables-error-for-a-downstream-pipeline}

Lors du déclenchement d'un pipeline downstream, vous pourriez obtenir cette erreur de façon inattendue :

```plaintext
Failed - (downstream pipeline can not be created, Insufficient permissions to set pipeline variables)
```

Cette erreur survient lorsqu'un projet downstream a des [variables de pipeline restreintes](_index.md#restrict-pipeline-variables) et que le job déclencheur :

- A des variables définies. Par exemple :

  ```yaml
  trigger-job:
    variables:
      VAR_FOR_DOWNSTREAM: "test"
    trigger: my-group/my-project
  ```

- Reçoit des variables provenant des [variables par défaut](../yaml/_index.md#default-variables) définies dans une section `variables` de niveau supérieur. Par exemple :

  ```yaml
  variables:
    DEFAULT_VAR: "test"

  trigger-job:
    trigger: my-group/my-project
  ```

Les variables transmises à un pipeline downstream dans un job déclencheur sont des [variables de pipeline](_index.md#use-pipeline-variables), la solution de contournement consiste donc à :

- Supprimer les `variables` définies dans le job déclencheur pour éviter de transmettre des variables.
- [Empêcher les variables par défaut d'être transmises au pipeline downstream](../pipelines/downstream_pipelines.md#prevent-default-variables-from-being-passed).

## La variable par défaut ne se développe pas dans une variable de job portant le même nom {#default-variable-doesnt-expand-in-job-variable-of-the-same-name}

Vous ne pouvez pas utiliser la valeur d'une variable par défaut dans une variable de job portant le même nom. Une variable par défaut n'est mise à disposition d'un job que lorsque celui-ci ne possède pas de variable définie avec le même nom. Si le job possède une variable portant le même nom, la variable du job est prioritaire et la variable par défaut n'est pas disponible dans le job.

Par exemple, ces deux exemples sont équivalents :

- Dans cet exemple, `$MY_VAR` n'a aucune valeur car elle n'est définie nulle part :

  ```yaml
  Job-with-variable:
    variables:
      MY_VAR: $MY_VAR
    script: echo "Value is '$MY_VAR'"
  ```

- Dans cet exemple, `$MY_VAR` n'a aucune valeur car la variable par défaut portant le même nom n'est pas disponible dans le job :

  ```yaml
  variables:
    MY_VAR: "Default value"

  Job-with-same-name-variable:
    variables:
      MY_VAR: $MY_VAR
    script: echo "Value is '$MY_VAR'"
  ```

Dans les deux cas, la commande echo produit la sortie `Value is '$MY_VAR'`.

En général, vous devriez utiliser directement la variable par défaut dans un job plutôt que de réassigner sa valeur à une nouvelle variable. Si vous devez le faire, utilisez plutôt des variables avec des noms différents. Par exemple :

```yaml
variables:
  MY_VAR1: "Default value1"
  MY_VAR2: "Default value2"

overwrite-same-name:
  variables:
    MY_VAR2_FROM_DEFAULTS: $MY_VAR2
  script: echo "Values are '$MY_VAR1' and '$MY_VAR2_FROM_DEFAULTS'"
```
