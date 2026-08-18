---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD 변수 문제 해결
---

## 모든 변수 나열 {#list-all-variables}

스크립트에서 사용 가능한 모든 변수를 `export` 명령으로 Bash에서 또는 `dir env:`로 PowerShell에서 나열할 수 있습니다. 이는 **전체** 사용 가능한 변수의 값을 노출하므로 [보안 위험](_index.md#cicd-variable-security)이 될 수 있습니다. [마스킹된 변수](_index.md#mask-a-cicd-variable)는 `[MASKED]`로 표시됩니다.

예를 들어 Bash를 사용하면:

```yaml
job_name:
  script:
    - export
```

예제 작업 로그 출력(잘린 부분):

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

## 디버그 로깅 활성화 {#enable-debug-logging}

> [!warning]
> 디버그 로깅은 심각한 보안 위험이 될 수 있습니다. 출력에는 작업에서 사용 가능한 모든 변수의 내용이 포함됩니다. 출력은 GitLab 서버에 업로드되고 작업 로그에서 볼 수 있습니다.

파이프라인 구성 또는 작업 스크립트의 문제를 해결하기 위해 디버그 로깅을 사용할 수 있습니다. 디버그 로깅은 일반적으로 러너에서 숨겨져 있는 작업 실행 세부 정보를 노출하고 작업 로그를 더 장황하게 만듭니다. 또한 작업에서 사용 가능한 모든 변수와 비밀을 노출합니다.

디버그 로깅을 활성화하기 전에 팀 멤버만 작업 로그를 볼 수 있는지 확인하세요. 작업 로그를 다시 공개하기 전에 디버그 출력이 있는 [작업 로그 삭제](../jobs/_index.md#view-jobs-in-a-pipeline)도 수행해야 합니다.

디버그 로깅을 활성화하려면 `CI_DEBUG_TRACE` 변수를 `true`로 설정하세요:

```yaml
job_name:
  variables:
    CI_DEBUG_TRACE: "true"
```

예제 출력(잘린 부분):

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

### 디버그 로깅에 대한 액세스 {#access-to-debug-logging}

디버그 로깅에 대한 액세스는 [Developer, Maintainer 또는 Owner 역할을 가진 사용자](../../user/permissions.md#project-cicd)로 제한됩니다. 하위 역할이 있는 사용자는 다음 위치에서 변수를 사용하여 디버그 로깅을 활성화할 때 로그를 볼 수 없습니다:

- [`.gitlab-ci.yml` 파일](_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file).
- GitLab UI에서 설정된 CI/CD 변수.

> [!warning]
> `CI_DEBUG_TRACE`을(를) 러너에 로컬 변수로 추가하면 디버그 로그가 생성되고 작업 로그에 액세스할 수 있는 모든 사용자에게 표시됩니다. 권한 수준은 러너에서 확인되지 않으므로 GitLab 자체에서만 변수를 사용해야 합니다.

## `argument list too long` 오류 {#argument-list-too-long-error}

이 이슈는 작업에 정의된 모든 변수의 결합된 길이가 작업이 실행되는 셸에서 부과하는 제한을 초과할 때 발생합니다. 여기에는 미리 정의된 변수와 사용자 정의 변수의 이름과 값이 포함됩니다. 이 제한은 일반적으로 `ARG_MAX`이라고 하며 셸 및 운영 체제에 따라 달라집니다. 이 이슈는 단일 [File-type](_index.md#use-file-type-cicd-variables) 변수의 내용이 `ARG_MAX`을(를) 초과할 때도 발생합니다.

자세한 내용은 [이슈 392406](https://gitlab.com/gitlab-org/gitlab/-/issues/392406#note_1414219596)을(를) 참조하세요.

해결 방법으로 다음 중 하나를 수행할 수 있습니다:

- 가능한 경우 큰 환경 변수에 [File-type](_index.md#use-file-type-cicd-variables) 변수를 사용하세요.
- 단일 대형 변수가 `ARG_MAX`보다 크면 [Secure Files](../secure_files/_index.md)를 사용하거나 다른 메커니즘을 통해 파일을 작업으로 가져오세요.

## `Insufficient permissions to set pipeline variables` 다운스트림 파이프라인 오류 {#insufficient-permissions-to-set-pipeline-variables-error-for-a-downstream-pipeline}

다운스트림 파이프라인을(를) 트리거할 때 예상치 못하게 이 오류가 발생할 수 있습니다:

```plaintext
Failed - (downstream pipeline can not be created, Insufficient permissions to set pipeline variables)
```

이 오류는 다운스트림 파이프라인 프로젝트에 [제한된 파이프라인 변수](_index.md#restrict-pipeline-variables)가 있고 트리거 작업이 다음 중 하나일 때 발생합니다:

- 정의된 변수가 있습니다. 예를 들어:

  ```yaml
  trigger-job:
    variables:
      VAR_FOR_DOWNSTREAM: "test"
    trigger: my-group/my-project
  ```

- 최상위 `variables` 섹션에서 정의된 [기본 변수](../yaml/_index.md#default-variables)로부터 변수를 수신합니다. 예를 들어:

  ```yaml
  variables:
    DEFAULT_VAR: "test"

  trigger-job:
    trigger: my-group/my-project
  ```

트리거 작업의 다운스트림 파이프라인에 전달되는 변수는 [파이프라인 변수](_index.md#use-pipeline-variables)이므로 해결 방법은 다음 중 하나입니다:

- 트리거 작업에서 정의된 `variables`을(를) 제거하여 변수 전달을 피하세요.
- [기본 변수가 다운스트림 파이프라인으로 전달되는 것 방지](../pipelines/downstream_pipelines.md#prevent-default-variables-from-being-passed).

## 기본 변수가 같은 이름의 작업 변수에서 확장되지 않음 {#default-variable-doesnt-expand-in-job-variable-of-the-same-name}

같은 이름의 작업 변수에서 기본 변수의 값을 사용할 수 없습니다. 기본 변수는 작업이 같은 이름으로 정의된 변수를 갖지 않을 때만 작업에서 사용 가능합니다. 작업이 같은 이름으로 변수를 갖는 경우, 작업의 변수가 우선적으로 적용되고 기본 변수는 작업에서 사용 가능하지 않습니다.

예를 들어 이 두 샘플은 동등합니다:

- 이 샘플에서 `$MY_VAR`은(는) 어디에도 정의되지 않았기 때문에 값이 없습니다:

  ```yaml
  Job-with-variable:
    variables:
      MY_VAR: $MY_VAR
    script: echo "Value is '$MY_VAR'"
  ```

- 이 샘플에서 `$MY_VAR`은(는) 같은 이름의 기본 변수를 작업에서 사용할 수 없기 때문에 값이 없습니다:

  ```yaml
  variables:
    MY_VAR: "Default value"

  Job-with-same-name-variable:
    variables:
      MY_VAR: $MY_VAR
    script: echo "Value is '$MY_VAR'"
  ```

두 경우 모두 echo 명령은 `Value is '$MY_VAR'`을(를) 출력합니다.

일반적으로 기본 변수를 새 변수에 다시 할당하지 말고 작업에서 직접 사용해야 합니다. 이를 수행해야 하는 경우 대신 다른 이름의 변수를 사용하세요. 예를 들어:

```yaml
variables:
  MY_VAR1: "Default value1"
  MY_VAR2: "Default value2"

overwrite-same-name:
  variables:
    MY_VAR2_FROM_DEFAULTS: $MY_VAR2
  script: echo "Values are '$MY_VAR1' and '$MY_VAR2_FROM_DEFAULTS'"
```
