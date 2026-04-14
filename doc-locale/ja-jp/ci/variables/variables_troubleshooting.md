---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: トラブルシューティングCI/CD変数
---

## すべての変数をリスト表示する {#list-all-variables}

Bashで`export`コマンド、PowerShellで`dir env:`を使用して、スクリプトで使用できるすべての変数をリスト表示できます。これにより、利用可能な**すべての**変数の値が公開されます。これは[セキュリティリスク](_index.md#cicd-variable-security)になる可能性があります。[マスクされた変数](_index.md#mask-a-cicd-variable)は、`[MASKED]`と表示されます。

たとえば、Bashの場合

```yaml
job_name:
  script:
    - export
```

ジョブログの出力例（省略）

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

## デバッグロギングを有効にする {#enable-debug-logging}

> [!warning]
> デバッグロギングは重大なセキュリティリスクとなる可能性があります。出力には、ジョブで使用できるすべての変数のコンテンツが含まれます。この出力はGitLabサーバーにアップロードされ、ジョブログに表示されます。

デバッグログを使用すると、パイプライン設定またはジョブスクリプトの問題のトラブルシューティングに役立ちます。デバッグログは、通常はRunnerによって非表示になっているジョブ実行の詳細を公開し、ジョブログをより詳細にします。また、ジョブで使用できるすべての変数とシークレットも公開します。

デバッグログを有効にする前に、チームメンバーのみがジョブログを閲覧できることを確認してください。また、ログを再び公開する前に、デバッグ出力を含む[ジョブログを削除](../jobs/_index.md#view-jobs-in-a-pipeline)する必要もあります。

デバッグログを有効にするには、`CI_DEBUG_TRACE`変数を`true`に設定します:

```yaml
job_name:
  variables:
    CI_DEBUG_TRACE: "true"
```

出力例（省略）:

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

### デバッグロギングへのアクセス {#access-to-debug-logging}

デバッグロギングへのアクセスは、[デベロッパー、メンテナー、またはオーナーロールのユーザー](../../user/permissions.md#project-cicd)に制限されています。以下の場所で変数を使用してデバッグログが有効になっている場合でも、より低いロールのユーザーはログを表示できません。

- [`.gitlab-ci.yml` ファイル](_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)。
- GitLab UIで設定されたCI/CD変数。

> [!warning]
> `CI_DEBUG_TRACE`をRunnerのローカル変数として追加した場合、デバッグジョブログが生成され、ジョブログにアクセスできるすべてのユーザーに表示されます。権限レベルはRunnerによってチェックされないため、GitLab自体でのみ変数を使用する必要があります。

## エラー: `argument list too long` {#argument-list-too-long-error}

この問題は、ジョブに定義されているすべてのCI/CD変数を組み合わせた長さが、ジョブが実行されるシェルによって課される制限を超えた場合に発生します。これには、定義済み変数とユーザー定義変数の名前と値が含まれます。この制限は通常、`ARG_MAX`と呼ばれ、シェルとオペレーティングシステムに依存します。この問題は、単一の[ファイルタイプ](_index.md#use-file-type-cicd-variables)変数のコンテンツが`ARG_MAX`を超える場合にも発生します。

詳細については、[イシュー392406](https://gitlab.com/gitlab-org/gitlab/-/issues/392406#note_1414219596)を参照してください。

回避策として、以下のいずれかを実行できます。

- 可能であれば、サイズの大きい環境変数には[ファイルタイプ](_index.md#use-file-type-cicd-variables)のCI/CD変数を使用する。
- 単一の大きな変数が`ARG_MAX`より大きい場合は、[セキュアファイル](../secure_files/_index.md)を使用するか、他のなんらかの仕組みでファイルをジョブに取り込む。

## `Insufficient permissions to set pipeline variables`エラー（ダウンストリームパイプラインの場合） {#insufficient-permissions-to-set-pipeline-variables-error-for-a-downstream-pipeline}

ダウンストリームパイプラインをトリガーすると、予期せずこのエラーが発生する場合があります:

```plaintext
Failed - (downstream pipeline can not be created, Insufficient permissions to set pipeline variables)
```

このエラーは、ダウンストリームプロジェクトに[制限されたパイプライン変数](_index.md#restrict-pipeline-variables)があり、トリガージョブが以下のいずれかの場合に発生します:

- 変数が定義されている場合。例: 

  ```yaml
  trigger-job:
    variables:
      VAR_FOR_DOWNSTREAM: "test"
    trigger: my-group/my-project
  ```

- トップレベルの`variables`セクションで定義されている[デフォルト変数](../yaml/_index.md#default-variables)から変数を受け取る場合。例: 

  ```yaml
  variables:
    DEFAULT_VAR: "test"

  trigger-job:
    trigger: my-group/my-project
  ```

トリガージョブでダウンストリームパイプラインに渡される変数は[パイプライン変数](_index.md#use-pipeline-variables)であるため、回避策は以下のいずれかです:

- 変数の受け渡しを避けるため、トリガージョブで定義されている`variables`を削除します。
- [デフォルト変数がダウンストリームパイプラインに渡されないようにする](../pipelines/downstream_pipelines.md#prevent-default-variables-from-being-passed)。

## 同名のジョブ変数でデフォルト変数が展開されない {#default-variable-doesnt-expand-in-job-variable-of-the-same-name}

同じ名前のジョブ変数でデフォルト変数の値を使用することはできません。デフォルト変数は、ジョブに同じ名前で定義された変数がない場合にのみ、ジョブで使用可能になります。ジョブに同じ名前の変数がある場合、ジョブの変数が優先され、デフォルト変数はジョブで使用できなくなります。

たとえば、次の2つのサンプルは同等です。

- このサンプルでは、`$MY_VAR`はどこにも定義されていないため、値がありません。

  ```yaml
  Job-with-variable:
    variables:
      MY_VAR: $MY_VAR
    script: echo "Value is '$MY_VAR'"
  ```

- このサンプルでは、同じ名前のデフォルト変数がジョブで使用できないため、`$MY_VAR`に値がありません。

  ```yaml
  variables:
    MY_VAR: "Default value"

  Job-with-same-name-variable:
    variables:
      MY_VAR: $MY_VAR
    script: echo "Value is '$MY_VAR'"
  ```

どちらの場合も、echoコマンドは`Value is '$MY_VAR'`を出力します。

一般に、新しい変数に値を再割り当てするのではなく、ジョブで直接デフォルト変数を使用する必要があります。これを行う必要がある場合は、代わりに異なる名前の変数を使用してください。例: 

```yaml
variables:
  MY_VAR1: "Default value1"
  MY_VAR2: "Default value2"

overwrite-same-name:
  variables:
    MY_VAR2_FROM_DEFAULTS: $MY_VAR2
  script: echo "Values are '$MY_VAR1' and '$MY_VAR2_FROM_DEFAULTS'"
```
