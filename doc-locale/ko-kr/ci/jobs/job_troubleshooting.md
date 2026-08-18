---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 작업 문제 해결
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

작업을 사용할 때 다음과 같은 문제가 발생할 수 있습니다.

## `changes:`을 사용할 때 작업 또는 파이프라인이 예기치 않게 실행됨 {#jobs-or-pipelines-run-unexpectedly-when-using-changes}

[`rules: changes`](../yaml/_index.md#ruleschanges) 또는 [`only: changes`](../yaml/deprecated_keywords.md#onlychanges--exceptchanges)을 사용할 때 [머지 리퀘스트 파이프라인](../pipelines/merge_request_pipelines.md) 없이 작업 또는 파이프라인이 예기치 않게 실행될 수 있습니다.

머지 리퀘스트와 명시적으로 연결되지 않은 브랜치 또는 태그의 파이프라인은 이전 SHA를 사용하여 차이를 계산합니다. 이 계산은 `git diff HEAD~`과 동등하며 다음을 포함한 예기치 않은 동작을 야기할 수 있습니다:

- `changes` 규칙은 GitLab에 새 브랜치 또는 새 태그를 푸시할 때 항상 true로 평가됩니다.
- 새 커밋을 푸시할 때 변경된 파일은 이전 커밋을 기본 SHA로 사용하여 계산됩니다.

또한 `changes`이 포함된 규칙은 [예약된 파이프라인](../pipelines/schedules.md)에서 항상 true로 평가됩니다. 예약된 파이프라인이 실행될 때 모든 파일은 변경된 것으로 간주되므로, `changes`을 사용하는 예약된 파이프라인에 작업이 항상 추가될 수 있습니다.

## CI/CD 변수의 파일 경로 {#file-paths-in-cicd-variables}

CI/CD 변수에서 파일 경로를 사용할 때 주의하세요. 후행 슬래시는 변수 정의에서 올바르게 보일 수 있지만, `script:`, `changes:`, 또는 다른 키워드에서 확장될 때 무효화될 수 있습니다. 예를 들어:

```yaml
docker_build:
  variables:
    DOCKERFILES_DIR: 'path/to/files/'  # This variable should not have a trailing '/' character
  script: echo "A docker job"
  rules:
    - changes:
        - $DOCKERFILES_DIR/*
```

`DOCKERFILES_DIR` 변수가 `changes:` 섹션에서 확장될 때, 전체 경로는 `path/to/files//*`이 됩니다. 이중 슬래시는 사용된 키워드, 러너의 셸 및 OS 등의 요인에 따라 예기치 않은 동작을 야기할 수 있습니다.

## `You are not allowed to download code from this project.` 오류 메시지 {#you-are-not-allowed-to-download-code-from-this-project-error-message}

GitLab 관리자가 비공개 프로젝트에서 보호된 수동 작업을 실행할 때 파이프라인이 실패할 수 있습니다.

CI/CD 작업은 작업이 시작될 때 프로젝트를 복제하며, 이는 작업을 실행하는 사용자의 [권한](../../user/permissions.md#project-cicd)을 사용합니다. 비공개 프로젝트의 소스를 복제하려면 모든 사용자(관리자 포함)가 해당 프로젝트의 직접 구성원이어야 합니다. [이 동작을 변경하는 이슈가 있습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/23130).

보호된 수동 작업을 실행하려면:

- 관리자를 비공개 프로젝트의 직접 구성원으로 추가합니다(모든 역할)
- 프로젝트의 직접 구성원인 [사용자를 가장합니다](../../administration/admin_area.md#user-impersonation).

## 다시 실행할 때 CI/CD 작업이 새로운 구성을 사용하지 않음 {#a-cicd-job-does-not-use-newer-configuration-when-run-again}

파이프라인의 구성은 파이프라인이 생성될 때만 가져옵니다. 작업을 다시 실행할 때마다 동일한 구성을 사용합니다. [`include`](../yaml/_index.md#include)로 추가된 별도의 파일을 포함한 구성 파일을 업데이트하는 경우, 새로운 구성을 사용하려면 새 파이프라인을 시작해야 합니다.

## `Job may allow multiple pipelines to run for a single action` 경고 {#job-may-allow-multiple-pipelines-to-run-for-a-single-action-warning}

`if` 절 없이 `when` 절과 함께 [`rules`](../yaml/_index.md#rules)을 사용할 때, 여러 파이프라인이 실행될 수 있습니다. 일반적으로 이는 열린 머지 리퀘스트와 연결된 브랜치에 커밋을 푸시할 때 발생합니다.

[중복 파이프라인 방지](job_rules.md#avoid-duplicate-pipelines)하려면, [`workflow: rules`](../yaml/_index.md#workflow)를 사용하거나 실행할 수 있는 파이프라인을 제어하기 위해 규칙을 다시 작성하세요.

## `This GitLab CI configuration is invalid` 변수 표현식 {#this-gitlab-ci-configuration-is-invalid-for-variable-expressions}

[CI/CD 변수 표현식](job_rules.md#cicd-variable-expressions)으로 작업할 때 `This GitLab CI configuration is invalid` 오류 중 하나를 받을 수 있습니다. 이러한 구문 오류는 따옴표 문자의 잘못된 사용으로 인해 발생할 수 있습니다.

변수 표현식에서는 문자열에 따옴표를 붙여야 하고 변수에는 따옴표를 붙이면 안 됩니다. 예를 들어:

```yaml
variables:
  ENVIRONMENT: production

job:
  script: echo
  rules:
    - if: $ENVIRONMENT == "production"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

이 예시에서 `production` 문자열이 따옴표로 묶여 있고 CI/CD 변수는 따옴표 없이 있기 때문에 두 `if:` 절이 유효합니다.

반면에 이 `if:` 절은 모두 유효하지 않습니다:

```yaml
variables:
  ENVIRONMENT: production

job:
  script: echo
  rules:       # These rules all cause YAML syntax errors:
    - if: ${ENVIRONMENT} == "production"
    - if: "$ENVIRONMENT" == "production"
    - if: $ENVIRONMENT == production
    - if: "production" == "production"
```

이 예에서:

- `if: ${ENVIRONMENT} == "production"`은 유효하지 않습니다. `${ENVIRONMENT}`는 `if:`에서 CI/CD 변수에 대한 유효한 형식이 아니기 때문입니다.
- `if: "$ENVIRONMENT" == "production"`은 유효하지 않습니다. 변수가 따옴표로 묶여 있기 때문입니다.
- `if: $ENVIRONMENT == production`은 유효하지 않습니다. 문자열이 따옴표로 묶여 있지 않기 때문입니다.
- `if: "production" == "production"`은 유효하지 않습니다. 비교할 CI/CD 변수가 없기 때문입니다.

## `get_sources` 작업 섹션이 HTTP/2 문제로 인해 실패함 {#get_sources-job-section-fails-because-of-an-http2-problem}

때때로 작업이 다음 cURL 오류로 실패합니다:

```plaintext
++ git -c 'http.userAgent=gitlab-runner <version>' fetch origin +refs/pipelines/<id>:refs/pipelines/<id> ...
error: RPC failed; curl 16 HTTP/2 send again with decreased length
fatal: ...
```

Git과 `libcurl`을 구성하여 [HTTP/1.1을 사용](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpversion)함으로써 이 문제를 해결할 수 있습니다. 구성은 다음에 추가할 수 있습니다:

- 작업의 [`pre_get_sources_script`](../yaml/_index.md#hookspre_get_sources_script):

  ```yaml
  job_name:
    hooks:
      pre_get_sources_script:
        - git config --global http.version "HTTP/1.1"
  ```

- [러너의 `config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration/)와 [Git 구성 환경 변수](https://git-scm.com/docs/git-config#ENVIRONMENT):

  ```toml
  [[runners]]
  ...
  environment = [
    "GIT_CONFIG_COUNT=1",
    "GIT_CONFIG_KEY_0=http.version",
    "GIT_CONFIG_VALUE_0=HTTP/1.1"
  ]
  ```

## `resource_group`을 사용하는 작업이 정지됨 {#job-using-resource_group-gets-stuck}

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[`resource_group`](../yaml/_index.md#resource_group)을 사용하는 작업이 정지되면, GitLab 관리자는 [Rails 콘솔](../../administration/operations/rails_console.md#starting-a-rails-console-session)에서 다음 명령을 실행해 볼 수 있습니다:

```ruby
# find resource group by name
resource_group = Project.find_by_full_path('...').resource_groups.find_by(key: 'the-group-name')
busy_resources = resource_group.resources.where('build_id IS NOT NULL')

# identify which builds are occupying the resource
# (I think it should be 1 as of today)
busy_resources.pluck(:build_id)

# it's good to check why this build is holding the resource.
# Is it stuck? Has it been forcefully dropped by the system?
# free up busy resources
busy_resources.update_all(build_id: nil)
```

## 오류: `data integrity failure` {#error-data-integrity-failure}

작업 처리 중 `data integrity failure` 오류가 표시될 수 있습니다. [다운스트림 파이프라인](../pipelines/downstream_pipelines.md)에 대한 트리거 작업, 러너 할당을 기다리는 작업, 정리 중 정지된 작업을 포함한 모든 작업 유형에서 발생할 수 있습니다.

근본 원인을 찾기 위해 PostgreSQL 및 Sidekiq 로그를 확인하세요. GitLab Self-Managed 인스턴스의 일반적인 원인은 다음과 같습니다:

업그레이드 후 데이터베이스 시퀀스 손상 : PostgreSQL 로그에 `PG::UniqueViolation` 오류가 포함되어 있습니다. 관련 데이터베이스 트리거 함수가 올바른 시퀀스를 참조하는지 확인하세요.

업그레이드 후 오래된 Sidekiq 프로세스 : 오류가 간헐적이며 작업을 다시 시도하면 성공합니다. 모든 Sidekiq 노드가 예상 GitLab 버전을 실행 중인지 확인하고 그렇지 않은 노드를 다시 시작하세요.

스키마 변경으로 인한 모호하거나 유효하지 않은 SQL : PostgreSQL 로그에 작업 처리 중에 실행된 쿼리의 SQL 오류가 포함되어 있습니다. 최근 스키마 변경이 이 작업 유형에 대해 실행되는 쿼리에 영향을 미쳤는지 확인하세요.

오류가 지속되면, [Rails 콘솔](../../administration/operations/rails_console.md)에서 작업을 검사하여 `failure_reason`를 결정하고 다운스트림 파이프라인이 생성되었는지 확인하세요.

## `You are not authorized to run this manual job` 메시지 {#you-are-not-authorized-to-run-this-manual-job-message}

수동 작업을 실행하려고 할 때 이 메시지가 표시되고 비활성화된 **실행** 버튼이 있으면 다음과 같은 경우입니다:

- 대상 환경이 [보호 환경](../environments/protected_environments.md)이고 계정이 **배포 허용됨** 목록에 포함되지 않았습니다.
- [오래된 배포 작업 방지](../environments/deployment_safety.md#prevent-outdated-deployment-jobs) 설정이 활성화되어 있고 작업을 실행하면 최신 배포를 덮어쓰게 됩니다.
