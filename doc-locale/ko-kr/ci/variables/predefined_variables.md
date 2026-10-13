---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab 파이프라인에서 사용할 수 있는 사전 정의된 CI/CD 변수입니다.
title: 사전 정의된 CI/CD 변수 참조
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

사전에 정의된 [CI/CD 변수](_index.md)는 모든 GitLab CI/CD 파이프라인에서 사용할 수 있습니다.

[사전 정의된 변수 재정의](_index.md#use-pipeline-variables)를 피하세요. 파이프라인이 예기치 않게 작동할 수 있습니다.

## 가용성 {#variable-availability}

사전 정의된 변수는 파이프라인 실행의 세 가지 단계에서 사용할 수 있습니다.

- 파이프라인 전 단계: 파이프라인 전 변수는 파이프라인이 생성되기 전에 사용할 수 있습니다. 이 변수는 파이프라인 생성 시 사용할 설정 파일을 제어하기 위해 [`include:rules`](../yaml/_index.md#includerules)에만 사용할 수 있습니다.
- 파이프라인: 파이프라인 변수는 GitLab이 파이프라인을 생성할 때 사용할 수 있습니다. 파이프라인 전 변수와 함께, 파이프라인 변수는 작업에서 정의된 [`rules`](../yaml/_index.md#rules)를 설정하여 파이프라인에 추가할 작업을 결정하는 데 사용할 수 있습니다.
- 작업 전용: 이 변수는 러너가 작업을 선택하고 실행할 때만 각 작업에서 사용할 수 있으며,
  - 작업 스크립트에서 사용할 수 있습니다.
  - [트리거 작업](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file)과 함께 사용할 수 없습니다.
  - [`workflow`](../yaml/_index.md#workflow), [`include`](../yaml/_index.md#include), 또는 [`rules`](../yaml/_index.md#rules)와 함께 사용할 수 없습니다.

## 사전 정의된 변수 {#predefined-variables}

| 변수                                        | 가용성 | 설명 |
|-------------------------------------------------|--------------|-------------|
| `CHAT_CHANNEL`                                  | 파이프라인     | [ChatOps](../chatops/_index.md) 명령을 트리거한 소스 채팅 채널입니다. |
| `CHAT_INPUT`                                    | 파이프라인     | [ChatOps](../chatops/_index.md) 명령과 함께 전달된 추가 인수입니다. |
| `CHAT_USER_ID`                                  | 파이프라인     | [ChatOps](../chatops/_index.md) 명령을 트리거한 사용자의 채팅 서비스 사용자 ID입니다. |
| `CI`                                            | 파이프라인 전 | CI/CD에서 실행되는 모든 작업에서 사용할 수 있습니다. `true` 사용 가능합니다. |
| `CI_API_V4_URL`                                 | 파이프라인 전 | GitLab API v4 루트 URL입니다. |
| `CI_API_GRAPHQL_URL`                            | 파이프라인 전 | GitLab API GraphQL 루트 URL입니다. |
| `CI_BUILD_NETWORK_NAME`                         | 작업 전용     | 작업이 생성한 네트워크의 이름입니다. Docker 실행기에서만 사용 가능하며 [`FF_NETWORK_PER_BUILD`](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags)가 활성화되어 있을 때입니다. |
| `CI_BUILDS_DIR`                                 | 작업 전용     | 빌드가 실행되는 최상위 디렉터리입니다. |
| `CI_COMMIT_AUTHOR`                              | 파이프라인 전 | `Name <email>` 형식의 커밋 작성자입니다. |
| `CI_COMMIT_BEFORE_SHA`                          | 파이프라인 전 | 브랜치 또는 태그에 있는 이전의 최신 커밋입니다. 머지 리퀘스트 파이프라인, 예약된 파이프라인, 브랜치 또는 태그용 파이프라인의 첫 번째 커밋, 또는 파이프라인을 수동으로 실행하는 경우에는 항상 `0000000000000000000000000000000000000000`입니다. |
| `CI_COMMIT_BRANCH`                              | 파이프라인 전 | 커밋 브랜치 이름입니다. 브랜치 파이프라인(기본 브랜치의 파이프라인 포함)에서 사용 가능합니다. 머지 리퀘스트 파이프라인 또는 태그 파이프라인에서는 사용할 수 없습니다. |
| `CI_COMMIT_DEFAULT_BRANCH_BASE_SHA`             | 파이프라인 전 | `CI_COMMIT_SHA`와 기본 브랜치 사이의 병합 기본입니다. 기본이 아닌 브랜치 파이프라인에서만 사용 가능합니다. GitLab 19.1에서 도입되었습니다. |
| `CI_COMMIT_DESCRIPTION`                         | 파이프라인 전 | 커밋의 설명입니다. 제목이 100자 미만인 경우 설명은 첫 번째 줄을 제외한 메시지입니다. |
| `CI_COMMIT_MESSAGE`                             | 파이프라인 전 | 전체 커밋 메시지입니다. |
| `CI_COMMIT_MESSAGE_IS_TRUNCATED`                | 파이프라인 전 | 커밋 메시지가 너무 길어서 `CI_COMMIT_MESSAGE`가 `GITLAB_CI_MAX_COMMIT_MESSAGE_SIZE_IN_BYTES` 시스템 환경 변수(기본값 100KB)에 지정된 크기로 잘린 경우 `true`입니다. 그렇지 않으면 `false`입니다. GitLab 18.6에서 도입되었습니다. |
| `CI_COMMIT_REF_NAME`                            | 파이프라인 전 | 프로젝트가 빌드되는 브랜치 또는 태그 이름입니다. |
| `CI_COMMIT_REF_PROTECTED`                       | 파이프라인 전 | 작업이 보호된 참조에 대해 실행 중일 경우 `true`, 그렇지 않으면 `false`입니다. |
| `CI_COMMIT_REF_SLUG`                            | 파이프라인 전 | `CI_COMMIT_REF_NAME` (소문자로 변환, 63바이트로 단축, `0-9`와 `a-z` 외 모든 항목이 `-`로 교체). `-` 앞이나 뒤에 없음. URL, 호스트 이름 및 도메인 이름에 사용합니다. |
| `CI_COMMIT_SHA`                                 | 파이프라인 전 | 프로젝트가 빌드되는 커밋 리비전입니다. |
| `CI_COMMIT_SHORT_SHA`                           | 파이프라인 전 | `CI_COMMIT_SHA`의 처음 8자입니다. |
| `CI_COMMIT_TAG`                                 | 파이프라인 전 | 커밋 태그 이름입니다. 태그의 파이프라인에서만 사용 가능합니다. |
| `CI_COMMIT_TAG_MESSAGE`                         | 파이프라인 전 | 커밋 태그 메시지입니다. 태그의 파이프라인에서만 사용 가능합니다. |
| `CI_COMMIT_TIMESTAMP`                           | 파이프라인 전 | [ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A) 형식의 커밋 타임스탬프입니다. 예를 들어, `2022-01-31T16:47:55Z`입니다. [기본적으로 UTC](../../administration/timezone.md)입니다. |
| `CI_COMMIT_TITLE`                               | 파이프라인 전 | 커밋의 제목입니다. 메시지의 전체 첫 줄입니다. |
| `CI_COMMIT_USER_LOGIN`                          | 파이프라인 전 | 커밋 작성자의 프로필과 이메일이 공개되고 커밋 이메일과 일치할 경우 GitLab 사용자 이름, 그렇지 않으면 빈 문자열입니다. GitLab 18.10에서 도입되었습니다. |
| `CI_CONCURRENT_ID`                              | 작업 전용     | 단일 실행기에서의 빌드 실행의 고유 ID입니다. |
| `CI_CONCURRENT_PROJECT_ID`                      | 작업 전용     | 단일 실행기 및 프로젝트에서의 빌드 실행의 고유 ID입니다. |
| `CI_CONFIG_PATH`                                | 파이프라인 전 | CI/CD 설정 파일의 경로입니다. `.gitlab-ci.yml`로 기본값 지정합니다. |
| `CI_CONFIG_REF_URI`                             | 파이프라인     | 최상위 파이프라인 정의의 정규화된 참조 경로입니다. 예를 들어 `gitlab.example.com/my-group/my-project//.gitlab-ci.yml@refs/heads/main`입니다. 파이프라인 소스 참조를 결정할 수 없을 때는 사용할 수 없습니다. GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/593105)되었습니다. |
| `CI_DEBUG_TRACE`                                | 파이프라인     | [디버그 로깅(추적)](variables_troubleshooting.md#enable-debug-logging)이 활성화된 경우 `true`입니다. |
| `CI_DEBUG_SERVICES`                             | 파이프라인     | [서비스 컨테이너 로깅](../services/_index.md#capturing-service-container-logs)이 활성화된 경우 `true`입니다. |
| `CI_DEFAULT_BRANCH`                             | 파이프라인 전 | 프로젝트의 기본 브랜치 이름입니다. |
| `CI_DEFAULT_BRANCH_SLUG`                        | 파이프라인 전 | `CI_DEFAULT_BRANCH` (소문자로 변환, 63바이트로 단축, `0-9`와 `a-z` 외 모든 항목이 `-`로 교체). `-` 앞이나 뒤에 없음. URL, 호스트 이름 및 도메인 이름에 사용합니다. |
| `CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX` | 파이프라인 전 | 종속성 프록시를 통해 이미지를 가져오기 위한 직접 그룹 이미지 접두사입니다. |
| `CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX`        | 파이프라인 전 | 종속성 프록시를 통해 이미지를 가져오기 위한 최상위 그룹 이미지 접두사입니다. |
| `CI_DEPENDENCY_PROXY_PASSWORD`                  | 파이프라인     | 종속성 프록시를 통해 이미지를 가져오기 위한 암호입니다. |
| `CI_DEPENDENCY_PROXY_SERVER`                    | 파이프라인 전 | 종속성 프록시에 로그인하는 서버입니다. 이 변수는 `$CI_SERVER_HOST:$CI_SERVER_PORT`와 동일합니다. |
| `CI_DEPENDENCY_PROXY_USER`                      | 파이프라인     | 종속성 프록시를 통해 이미지를 가져오기 위한 사용자 이름입니다. |
| `CI_DEPLOY_FREEZE`                              | 파이프라인 전 | 파이프라인이 [배포 동결 기간](../../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze) 중에 실행될 경우에만 사용할 수 있습니다. `true` 사용 가능합니다. |
| `CI_DEPLOY_PASSWORD`                            | 작업 전용     | [GitLab 배포 토큰](../../user/project/deploy_tokens/_index.md#gitlab-deploy-token)의 인증 암호(프로젝트에 있는 경우)입니다. |
| `CI_DEPLOY_USER`                                | 작업 전용     | [GitLab 배포 토큰](../../user/project/deploy_tokens/_index.md#gitlab-deploy-token)의 인증 사용자 이름(프로젝트에 있는 경우)입니다. |
| `CI_DISPOSABLE_ENVIRONMENT`                     | 파이프라인     | 작업을 위해서만 생성되고 나중에 삭제되는 일회용 환경에서 작업이 실행되는 경우에만 사용 가능합니다. `shell`과 `ssh`을 제외한 모든 실행기가 지원합니다. `true` (사용 가능할 때). |
| `CI_ENVIRONMENT_ID`                             | 파이프라인     | 이 작업의 환경 ID입니다. [`environment:name`](../yaml/_index.md#environmentname)이 설정된 경우 사용 가능합니다. |
| `CI_ENVIRONMENT_NAME`                           | 파이프라인     | 이 작업의 환경 이름입니다. [`environment:name`](../yaml/_index.md#environmentname)이 설정된 경우 사용 가능합니다. |
| `CI_ENVIRONMENT_SLUG`                           | 파이프라인     | 환경 이름의 단순화된 버전으로, DNS, URL 및 Kubernetes 레이블에 포함하기에 적합합니다. [`environment:name`](../yaml/_index.md#environmentname)이 설정된 경우 사용 가능합니다. 슬러그는 [24자로 잘립니다](https://gitlab.com/gitlab-org/gitlab/-/issues/20941). [대문자 환경 이름](https://gitlab.com/gitlab-org/gitlab/-/issues/415526)에 임의 접미사가 자동으로 추가됩니다. |
| `CI_ENVIRONMENT_URL`                            | 파이프라인     | 이 작업의 환경 URL입니다. [`environment:url`](../yaml/_index.md#environmenturl)이 설정된 경우 사용 가능합니다. |
| `CI_ENVIRONMENT_ACTION`                         | 파이프라인     | 이 작업의 환경에 대해 지정된 작업 주석입니다. [`environment:action`](../yaml/_index.md#environmentaction)이 설정된 경우 사용 가능합니다. `start`, `prepare` 또는 `stop`이 될 수 있습니다. |
| `CI_ENVIRONMENT_TIER`                           | 파이프라인     | 이 작업의 [환경의 배포 계층](../environments/_index.md#deployment-tier-of-environments)입니다. |
| `CI_GITLAB_FIPS_MODE`                           | 파이프라인 전 | GitLab 인스턴스에서 [FIPS 모드](../../development/fips_gitlab.md)가 활성화된 경우에만 사용할 수 있습니다. `true` 사용 가능합니다. |
| `CI_HAS_OPEN_REQUIREMENTS`                      | 파이프라인     | 파이프라인의 프로젝트에 개설된 [요구사항](../../user/project/requirements/_index.md)이 있을 경우에만 사용할 수 있습니다. `true` 사용 가능합니다. |
| `CI_JOB_GROUP_NAME`                             | 파이프라인     | [`parallel`](../yaml/_index.md#parallel)을 사용하거나 [수동으로 그룹화된 작업](../jobs/_index.md#group-similar-jobs-together-in-pipeline-views)을 사용할 때 작업 그룹의 공유 이름입니다. 예를 들어 작업 이름이 `rspec:test: [ruby, ubuntu]`이면 `CI_JOB_GROUP_NAME`은 `rspec:test`입니다. 그렇지 않으면 `CI_JOB_NAME`과 동일합니다. GitLab 17.10에서 도입되었습니다. |
| `CI_JOB_ID`                                     | 작업 전용     | GitLab 인스턴스의 모든 작업 중에 고유한 작업의 내부 ID입니다. |
| `CI_JOB_IMAGE`                                  | 작업 전용     | 작업을 실행하는 Docker 이미지의 이름입니다. 작업이 명시적으로 Docker 이미지를 지정하는 경우에만 사용 가능합니다. |
| `CI_JOB_MANUAL`                                 | 파이프라인     | 작업이 수동으로 시작된 경우에만 사용할 수 있습니다. `true` 사용 가능합니다. |
| `CI_JOB_NAME`                                   | 파이프라인     | 작업의 이름입니다. |
| `CI_JOB_NAME_SLUG`                              | 파이프라인     | `CI_JOB_NAME` (소문자로 변환, 63바이트로 단축, `0-9`와 `a-z` 외 모든 항목이 `-`로 교체). `-` 앞이나 뒤에 없음. 경로에 사용합니다. |
| `CI_JOB_RETRY_COUNT`                            | 작업 전용     | 현재 파이프라인에서 작업이 재시도된 횟수입니다. 첫 번째 실행에서는 `0`, 재시도할 때마다 1씩 증가합니다. GitLab 19.3에서 도입되었습니다. |
| `CI_JOB_STAGE`                                  | 파이프라인     | 작업 스테이지의 이름입니다. |
| `CI_JOB_STATUS`                                 | 작업 전용     | 각 러너 스테이지가 실행될 때 작업의 상태입니다. [`after_script`](../yaml/_index.md#after_script)와 함께 사용합니다. `success`, `failed` 또는 `canceled`이 될 수 있습니다. |
| `CI_JOB_TAGS`                                   | 작업 전용     | 작업의 [러너 태그](../yaml/_index.md#tags)의 JSON 배열입니다. 예: `["tag_1", "tag_2"]`. GitLab 19.3에서 도입되었습니다. |
| `CI_JOB_TIMEOUT`                                | 작업 전용     | 작업 타임아웃(초)입니다. |
| `CI_JOB_TOKEN`                                  | 작업 전용     | [특정 API 엔드포인트](../jobs/ci_job_token.md)로 인증하는 토큰입니다. 이 토큰은 작업이 실행되는 동안 유효합니다. |
| `CI_JOB_URL`                                    | 작업 전용     | 작업 세부정보 URL입니다. |
| `CI_JOB_STARTED_AT`                             | 작업 전용     | 작업이 시작된 날짜 및 시간([ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A) 형식). 예를 들어, `2022-01-31T16:47:55Z`입니다. [기본적으로 UTC](../../administration/timezone.md)입니다. |
| `CI_JOB_STARTED_AT_SLUG`                        | 작업 전용     | `CI_JOB_STARTED_AT` (소문자로 변환, 63바이트로 단축, `0-9`와 `a-z` 외 모든 항목이 `-`로 교체). `-` 앞이나 뒤에 없음. Docker 이미지 태그 및 기타 식별자에 사용하기에 적합합니다. GitLab 18.7에서 도입되었습니다. |
| `CI_KUBERNETES_ACTIVE`                          | 파이프라인 전 | 파이프라인에 배포에 사용 가능한 Kubernetes 클러스터가 있을 경우에만 사용할 수 있습니다. `true` 사용 가능합니다. |
| `CI_NODE_INDEX`                                 | 파이프라인     | 작업 집합에서 작업의 인덱스입니다. 작업이 [`parallel`](../yaml/_index.md#parallel)를 사용하는 경우에만 사용 가능합니다. |
| `CI_NODE_TOTAL`                                 | 파이프라인     | 병렬로 실행 중인 이 작업의 총 인스턴스 수입니다. 작업이 [`parallel`](../yaml/_index.md#parallel)를 사용하지 않는 경우 `1`로 설정합니다. |
| `CI_OPEN_MERGE_REQUESTS`                        | 파이프라인 전 | 현재 브랜치와 프로젝트를 머지 리퀘스트 소스로 사용하는 최대 4개의 머지 리퀘스트를 쉼표로 구분한 목록입니다. 브랜치에 관련된 머지 리퀘스트가 있을 경우 브랜치 파이프라인 및 머지 리퀘스트 파이프라인에서만 사용 가능합니다. 예를 들어, `gitlab-org/gitlab!333,gitlab-org/gitlab-foss!11`입니다. |
| `CI_PAGES_DOMAIN`                               | 파이프라인 전 | GitLab Pages를 호스팅하는 인스턴스의 도메인입니다(네임스페이스 하위 도메인 제외). 전체 호스트 이름을 사용하려면 `CI_PAGES_HOSTNAME`을 대신 사용합니다. |
| `CI_PAGES_HOSTNAME`                             | 작업 전용     | Pages 배포의 전체 호스트 이름입니다. |
| `CI_PAGES_URL`                                  | 작업 전용     | GitLab Pages 사이트의 URL입니다. 항상 `CI_PAGES_DOMAIN`의 하위 도메인입니다. GitLab 17.9 이상에서는 하나를 지정하면 값이 `path_prefix`를 포함합니다. |
| `CI_PIPELINE_ID`                                | 작업 전용     | 현재 파이프라인의 ID입니다. 이 ID는 GitLab 인스턴스의 모든 프로젝트 중에 고유합니다. |
| `CI_PIPELINE_IID`                               | 파이프라인     | 현재 파이프라인의 IID(내부 ID)입니다. 이 ID는 현재 프로젝트 내에서만 고유합니다. |
| `CI_PIPELINE_SOURCE`                            | 파이프라인 전 | 파이프라인을 트리거한 방법입니다. 값은 [파이프라인 소스](../jobs/job_rules.md#ci_pipeline_source-predefined-variable) 중 하나입니다. |
| `CI_PIPELINE_TRIGGERED`                         | 파이프라인     | [트리거 토큰으로 트리거된](../triggers/_index.md) 파이프라인의 경우 `true`입니다. [`trigger`](../yaml/_index.md#trigger) 키워드로 트리거된 파이프라인의 경우 [`CI_PIPELINE_SOURCE`](../jobs/job_rules.md#ci_pipeline_source-predefined-variable)를 대신 사용합니다. |
| `CI_PIPELINE_URL`                               | 작업 전용     | 파이프라인 세부정보의 URL입니다. |
| `CI_PIPELINE_CREATED_AT`                        | 작업 전용     | 파이프라인이 생성된 날짜 및 시간([ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A) 형식). 예를 들어, `2022-01-31T16:47:55Z`입니다. [기본적으로 UTC](../../administration/timezone.md)입니다. |
| `CI_PIPELINE_NAME`                              | 파이프라인 전 | [`workflow:name`](../yaml/_index.md#workflowname)에서 정의된 파이프라인 이름입니다. |
| `CI_PIPELINE_SCHEDULE_DESCRIPTION`              | 파이프라인 전 | 파이프라인 일정의 설명입니다. 예약된 파이프라인에서만 사용 가능합니다. GitLab 17.8에서 도입되었습니다. |
| `CI_PROJECT_DIR`                                | 작업 전용     | 리포지토리가 복제되는 전체 경로이며 작업이 실행되는 위치입니다. 러너의 `builds_dir` 매개변수가 설정되어 있으면 이 변수는 `builds_dir`의 값을 기준으로 설정됩니다. 자세한 내용은 [고급 러너 구성](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section)을 참조합니다. |
| `CI_PROJECT_ID`                                 | 파이프라인 전 | 현재 프로젝트의 ID입니다. 이 ID는 GitLab 인스턴스의 모든 프로젝트 중에 고유합니다. |
| `CI_PROJECT_NAME`                               | 파이프라인 전 | 프로젝트를 위한 디렉터리의 이름입니다. 예를 들어 프로젝트 URL이 `gitlab.example.com/group-name/project-1`이면 `CI_PROJECT_NAME`는 `project-1`입니다. |
| `CI_PROJECT_NAMESPACE`                          | 파이프라인 전 | 작업의 프로젝트 네임스페이스(사용자 이름 또는 그룹 이름)입니다. |
| `CI_PROJECT_NAMESPACE_ID`                       | 파이프라인 전 | 작업의 프로젝트 네임스페이스 ID입니다. |
| `CI_PROJECT_NAMESPACE_SLUG`                     | 파이프라인 전 | `$CI_PROJECT_NAMESPACE` (소문자로 변환, 63바이트로 단축, `0-9`와 `a-z` 외 모든 항목이 `-`로 교체). `-` 앞이나 뒤에 없음. |
| `CI_PROJECT_PATH_SLUG`                          | 파이프라인 전 | `$CI_PROJECT_PATH` (소문자로 변환, 63바이트로 단축, `0-9`와 `a-z` 외 모든 항목이 `-`로 교체). `-` 앞이나 뒤에 없음. URL 및 도메인 이름에 사용합니다. |
| `CI_PROJECT_PATH`                               | 파이프라인 전 | 프로젝트 이름이 포함된 프로젝트 네임스페이스입니다. |
| `CI_PROJECT_REPOSITORY_LANGUAGES`               | 파이프라인 전 | 리포지토리에서 사용되는 언어의 쉼표로 구분한 소문자 목록입니다. 예: `ruby,javascript,html,css`. 최대 언어 수는 5개로 제한됩니다. 이슈에서 [제한 증가를 제안](https://gitlab.com/gitlab-org/gitlab/-/issues/368925)합니다. |
| `CI_PROJECT_ROOT_NAMESPACE`                     | 파이프라인 전 | 작업의 루트 프로젝트 네임스페이스(사용자 이름 또는 그룹 이름)입니다. 예를 들어 `CI_PROJECT_NAMESPACE`가 `root-group/child-group/grandchild-group`이면 `CI_PROJECT_ROOT_NAMESPACE`는 `root-group`입니다. |
| `CI_PROJECT_ROOT_NAMESPACE_SLUG`                | 파이프라인 전 | `$CI_PROJECT_ROOT_NAMESPACE` (소문자로 변환, 63바이트로 단축, `0-9`와 `a-z` 외 모든 항목이 `-`로 교체). `-` 앞이나 뒤에 없음. GitLab 19.0에서 도입되었습니다. |
| `CI_PROJECT_TITLE`                              | 파이프라인 전 | GitLab 웹 인터페이스에 표시되는 사람이 읽을 수 있는 프로젝트 이름입니다. |
| `CI_PROJECT_DESCRIPTION`                        | 파이프라인 전 | GitLab 웹 인터페이스에 표시되는 프로젝트 설명입니다. |
| `CI_PROJECT_TOPICS`                             | 파이프라인 전 | 프로젝트에 할당된 [항목](../../user/project/project_topics.md)의 쉼표로 구분한 소문자 목록(처음 20개로 제한)입니다. GitLab 18.3에서 도입되었습니다. |
| `CI_PROJECT_URL`                                | 파이프라인 전 | 프로젝트의 HTTP(S) 주소입니다. |
| `CI_PROJECT_VISIBILITY`                         | 파이프라인 전 | 프로젝트 표시 여부입니다. `internal`, `private` 또는 `public`이 될 수 있습니다. |
| `CI_PROJECT_CLASSIFICATION_LABEL`               | 파이프라인 전 | 프로젝트 [외부 인증 분류 레이블](../../administration/settings/external_authorization.md)입니다. |
| `CI_REGISTRY`                                   | 파이프라인 전 | [컨테이너 레지스트리](../../user/packages/container_registry/_index.md) 서버의 주소입니다(`<host>[:<port>]` 형식). 예: `registry.gitlab.example.com`. GitLab 인스턴스에 대해 컨테이너 레지스트리가 활성화된 경우에만 사용 가능합니다. |
| `CI_REGISTRY_IMAGE`                             | 파이프라인 전 | 프로젝트의 이미지를 푸시, 풀 또는 태그하기 위한 컨테이너 레지스트리의 기본 주소입니다(`<host>[:<port>]/<project_full_path>` 형식). 예: `registry.gitlab.example.com/my_group/my_project`. 이미지 이름은 [컨테이너 레지스트리 명명 규칙](../../user/packages/container_registry/_index.md#naming-convention-for-your-container-images)을 따라야 합니다. 프로젝트에 대해 컨테이너 레지스트리가 활성화된 경우에만 사용 가능합니다. |
| `CI_REGISTRY_PASSWORD`                          | 작업 전용     | GitLab 프로젝트의 컨테이너 레지스트리에 컨테이너를 푸시하는 암호입니다. 프로젝트에 대해 컨테이너 레지스트리가 활성화된 경우에만 사용 가능합니다. 이 암호 값은 `CI_JOB_TOKEN`과 동일하며 작업이 실행되는 동안만 유효합니다. 레지스트리에 대한 장기 액세스를 위해 `CI_DEPLOY_PASSWORD`를 사용합니다 |
| `CI_REGISTRY_USER`                              | 작업 전용     | 프로젝트의 GitLab 컨테이너 레지스트리에 컨테이너를 푸시하는 사용자 이름입니다. 프로젝트에 대해 컨테이너 레지스트리가 활성화된 경우에만 사용 가능합니다. |
| `CI_RELEASE_DESCRIPTION`                        | 파이프라인     | 릴리스의 설명입니다. 태그의 파이프라인에서만 사용 가능합니다. 설명 길이는 처음 1024자로 제한됩니다. |
| `CI_REPOSITORY_URL`                             | 작업 전용     | [CI/CD 작업 토큰](../jobs/ci_job_token.md)으로 리포지토리를 Git 클론(HTTP)하는 전체 경로입니다(`https://gitlab-ci-token:$CI_JOB_TOKEN@gitlab.example.com/my-group/my-project.git` 형식). |
| `CI_RUNNER_DESCRIPTION`                         | 작업 전용     | 러너의 설명입니다. |
| `CI_RUNNER_EXECUTABLE_ARCH`                     | 작업 전용     | 러너 실행 파일의 OS/아키텍처입니다. 실행기의 환경과 같지 않을 수 있습니다. |
| `CI_RUNNER_ID`                                  | 작업 전용     | 사용 중인 러너의 고유 ID입니다. |
| `CI_RUNNER_REVISION`                            | 작업 전용     | 작업을 실행하는 러너의 수정 버전입니다. |
| `CI_RUNNER_SHORT_TOKEN`                         | 작업 전용     | 새 작업 요청 인증에 사용되는 러너의 고유 ID입니다. 토큰에는 접두사가 포함되며 처음 17자가 사용됩니다. |
| `CI_RUNNER_TAGS`                                | 작업 전용     | 작업을 선택한 러너에 구성된 러너 태그의 JSON 배열입니다. 예: `["tag_1", "tag_2"]`. |
| `CI_RUNNER_VERSION`                             | 작업 전용     | 작업을 실행하는 러너의 버전입니다. |
| `CI_SERVER_FQDN`                                | 파이프라인 전 | 인스턴스의 FQDN(정규화된 도메인 이름)입니다. 예: `gitlab.example.com:8080`. |
| `CI_SERVER_HOST`                                | 파이프라인 전 | GitLab 인스턴스 URL의 호스트입니다(프로토콜 또는 포트 제외). 예: `gitlab.example.com`. |
| `CI_SERVER_NAME`                                | 파이프라인 전 | 작업을 조정하는 CI/CD 서버의 이름입니다. |
| `CI_SERVER_PORT`                                | 파이프라인 전 | GitLab 인스턴스 URL의 포트입니다(호스트 또는 프로토콜 제외). 예: `8080`. |
| `CI_SERVER_PROTOCOL`                            | 파이프라인 전 | GitLab 인스턴스 URL의 프로토콜입니다(호스트 또는 포트 제외). 예: `https`. |
| `CI_SERVER_SHELL_SSH_HOST`                      | 파이프라인 전 | SSH를 통한 Git 액세스에 사용되는 GitLab 인스턴스의 SSH 호스트입니다. 예: `gitlab.com`. |
| `CI_SERVER_SHELL_SSH_PORT`                      | 파이프라인 전 | SSH를 통한 Git 액세스에 사용되는 GitLab 인스턴스의 SSH 포트입니다. 예: `22`. |
| `CI_SERVER_REVISION`                            | 파이프라인 전 | 작업을 예약하는 GitLab 수정 버전입니다. |
| `CI_SERVER_TLS_CA_FILE`                         | 파이프라인     | [러너 설정](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section)에서 `tls-ca-file`이 설정된 경우 GitLab 서버를 확인하기 위한 TLS CA 인증서를 포함하는 파일입니다. |
| `CI_SERVER_TLS_CERT_FILE`                       | 파이프라인     | [러너 설정](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section)에서 `tls-cert-file`이 설정된 경우 GitLab 서버를 확인하기 위한 TLS 인증서를 포함하는 파일입니다. |
| `CI_SERVER_TLS_KEY_FILE`                        | 파이프라인     | [러너 설정](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section)에서 `tls-key-file`이 설정된 경우 GitLab 서버를 확인하기 위한 TLS 키를 포함하는 파일입니다. |
| `CI_SERVER_URL`                                 | 파이프라인 전 | 프로토콜 및 포트를 포함한 GitLab 인스턴스의 기본 URL입니다. 예: `https://gitlab.example.com:8080`. |
| `CI_SERVER_VERSION_MAJOR`                       | 파이프라인 전 | GitLab 인스턴스의 주요 버전입니다. 예를 들어 GitLab 버전이 `17.2.1`이면 `CI_SERVER_VERSION_MAJOR`는 `17`입니다. |
| `CI_SERVER_VERSION_MINOR`                       | 파이프라인 전 | GitLab 인스턴스의 보조 버전입니다. 예를 들어 GitLab 버전이 `17.2.1`이면 `CI_SERVER_VERSION_MINOR`는 `2`입니다. |
| `CI_SERVER_VERSION_PATCH`                       | 파이프라인 전 | GitLab 인스턴스의 패치 버전입니다. 예를 들어 GitLab 버전이 `17.2.1`이면 `CI_SERVER_VERSION_PATCH`는 `1`입니다. |
| `CI_SERVER_VERSION`                             | 파이프라인 전 | GitLab 인스턴스의 전체 버전입니다. |
| `CI_SERVER`                                     | 작업 전용     | CI/CD에서 실행되는 모든 작업에서 사용할 수 있습니다. `yes` 사용 가능합니다. |
| `CI_SHARED_ENVIRONMENT`                         | 파이프라인     | 작업이 공유 환경(CI/CD 호출 간에 지속되는 것, 예: `shell` 또는 `ssh` 실행기)에서 실행되는 경우에만 사용할 수 있습니다. `true` 사용 가능합니다. |
| `CI_TEMPLATE_REGISTRY_HOST`                     | 파이프라인 전 | CI/CD 템플릿에서 사용하는 레지스트리의 호스트입니다. `registry.gitlab.com`로 기본값 지정합니다. |
| `CI_TRIGGER_SHORT_TOKEN`                        | 작업 전용     | 현재 작업의 [트리거 토큰](../triggers/_index.md#create-a-pipeline-trigger-token)의 처음 4자입니다. 파이프라인이 [트리거 토큰으로 트리거된](../triggers/_index.md) 경우에만 사용 가능합니다. 예를 들어 `glptt-1234567890abcdefghij`의 트리거 토큰의 경우 `CI_TRIGGER_SHORT_TOKEN`는 `1234`가 됩니다. GitLab 17.0에서 도입되었습니다.  |
| `CI_UPSTREAM_JOB_ID`                            | 파이프라인 전 | 다중 프로젝트 또는 상위-하위 파이프라인에서 현재 파이프라인을 트리거한 업스트림 트리거 작업의 ID입니다. GitLab 18.9에서 도입되었습니다. |
| `CI_UPSTREAM_PIPELINE_ID`                       | 파이프라인 전 | 다중 프로젝트 또는 상위-하위 파이프라인에서 현재 파이프라인을 트리거한 업스트림 파이프라인의 ID입니다. GitLab 18.9에서 도입되었습니다. |
| `CI_UPSTREAM_PROJECT_ID`                        | 파이프라인 전 | 다중 프로젝트 또는 상위-하위 파이프라인에서 현재 파이프라인을 트리거한 업스트림 프로젝트의 ID입니다. GitLab 18.9에서 도입되었습니다. |
| `CI_TRACEPARENT`                                | 작업 전용     | 작업에 대한 [W3C Trace Context](https://www.w3.org/TR/trace-context/) `traceparent` 헤더 값으로, `00-<trace_id>-<span_id>-01` 형식입니다. `trace_id`는 32자리 16진수 문자열(0으로 패딩됨)로 된 루트 파이프라인 ID이며, 상위 및 하위 파이프라인을 포함하여 동일한 파이프라인 계층 구조의 모든 작업에서 공유됩니다. `span_id`는 루트 파이프라인 ID와 작업 ID에서 파생된 결정론적 해시로, 작업마다 고유합니다. 이 변수를 사용하여 CI/CD 작업을 외부 분산 추적 시스템과 연관시킬 수 있습니다. |
| `CI_TRACESTATE`                                 | 작업 전용     | [W3C Trace Context](https://www.w3.org/TR/trace-context/#tracestate-header) `tracestate` 헤더 값으로 GitLab 관련 추적 메타데이터를 포함합니다. 형식: `gitlab=pipeline:<pipeline_id>;job:<job_id>`. |
| `GITLAB_CI`                                     | 파이프라인 전 | CI/CD에서 실행되는 모든 작업에서 사용할 수 있습니다. `true` 사용 가능합니다. |
| `GITLAB_FEATURES`                               | 파이프라인 전 | GitLab 인스턴스 및 라이선스에 사용 가능한 라이선스 기능의 쉼표로 구분한 목록입니다. |
| `GITLAB_USER_EMAIL`                             | 파이프라인     | 파이프라인을 시작한 사용자의 이메일입니다(작업이 수동 작업인 경우 제외). 수동 작업의 경우 값은 작업을 시작한 사용자의 이메일입니다. |
| `GITLAB_USER_ID`                                | 파이프라인     | 파이프라인을 시작한 사용자의 숫자 ID입니다(작업이 수동 작업인 경우 제외). 수동 작업의 경우 값은 작업을 시작한 사용자의 ID입니다. |
| `GITLAB_USER_LOGIN`                             | 파이프라인     | 파이프라인을 시작한 사용자의 고유한 사용자 이름입니다(작업이 수동 작업인 경우 제외). 수동 작업의 경우 값은 작업을 시작한 사용자의 사용자 이름입니다. |
| `GITLAB_USER_NAME`                              | 파이프라인     | 파이프라인을 시작한 사용자의 표시 이름(프로필 설정의 사용자 정의 **이름**)입니다(작업이 수동 작업인 경우 제외). 수동 작업의 경우 값은 작업을 시작한 사용자의 이름입니다. |
| `KUBECONFIG`                                    | 파이프라인     | 모든 공유 에이전트 연결에 대한 컨텍스트가 있는 `kubeconfig` 파일의 경로입니다. [Kubernetes용 GitLab 에이전트가 프로젝트에 액세스할 권한이 있음](../../user/clusters/agent/ci_cd_workflow.md#authorize-agent-access)인 경우에만 사용할 수 있습니다. |
| `TRIGGER_PAYLOAD`                               | 파이프라인     | 웹후크 페이로드입니다. 파이프라인이 [웹후크로 트리거된](../triggers/_index.md#access-webhook-payload) 경우에만 사용할 수 있습니다. |

## 머지 리퀘스트 파이프라인의 사전 정의된 변수 {#predefined-variables-for-merge-request-pipelines}

이 변수는 GitLab이 파이프라인을 생성하기 전에(파이프라인 전) 사용 가능합니다. 이 변수는 [`include:rules`](../yaml/includes.md#use-rules-with-include)와 함께 사용하거나 작업의 환경 변수로 사용할 수 있습니다.

파이프라인은 [머지 리퀘스트 파이프라인](../pipelines/merge_request_pipelines.md)이어야 하며 머지 리퀘스트는 열려 있어야 합니다.

| 변수                                    | 설명 |
|---------------------------------------------|-------------|
| `CI_MERGE_REQUEST_APPROVED`                 | 머지 리퀘스트의 승인 상태입니다. `true` [머지 리퀘스트 승인](../../user/project/merge_requests/approvals/_index.md)을 사용할 수 있으며 머지 리퀘스트가 승인되었을 때입니다. |
| `CI_MERGE_REQUEST_ASSIGNEES`                | 머지 리퀘스트의 피할당인 사용자 이름의 쉼표로 구분한 목록입니다. 머지 리퀘스트에 최소한 한 명의 피할당인이 있을 경우에만 사용 가능합니다. |
| `CI_MERGE_REQUEST_DIFF_BASE_SHA`            | 머지 리퀘스트 diff의 기본 SHA입니다. |
| `CI_MERGE_REQUEST_DIFF_ID`                  | 머지 리퀘스트 diff의 버전입니다. |
| `CI_MERGE_REQUEST_EVENT_TYPE`               | 머지 리퀘스트의 이벤트 유형입니다. `detached`, `merged_result` 또는 `merge_train`이 될 수 있습니다. |
| `CI_MERGE_REQUEST_DESCRIPTION`              | 머지 리퀘스트의 설명입니다. 설명이 2700자보다 길면 처음 2700자만 변수에 저장됩니다. |
| `CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED` | 머지 리퀘스트의 설명이 너무 길어서 `CI_MERGE_REQUEST_DESCRIPTION`이 2700자로 잘린 경우 `true`, 그렇지 않으면 `false`입니다. |
| `CI_MERGE_REQUEST_ID`                       | 머지 리퀘스트의 ID입니다. ID는 GitLab 인스턴스의 모든 프로젝트 중에 고유합니다. |
| `CI_MERGE_REQUEST_IID`                      | 머지 리퀘스트의 IID(내부 ID)입니다. 이 ID는 현재 프로젝트에 대해 고유하며 머지 리퀘스트 URL, 페이지 제목 및 기타 표시되는 위치에 사용되는 번호입니다. |
| `CI_MERGE_REQUEST_LABELS`                   | 머지 리퀘스트의 쉼표로 구분한 레이블 이름입니다. 머지 리퀘스트에 최소한 한 개의 레이블이 있을 경우에만 사용 가능합니다. |
| `CI_MERGE_REQUEST_MILESTONE`                | 머지 리퀘스트의 마일스톤 제목입니다. 머지 리퀘스트에 마일스톤이 설정된 경우에만 사용 가능합니다. |
| `CI_MERGE_REQUEST_PROJECT_ID`               | 머지 리퀘스트의 프로젝트 ID입니다. |
| `CI_MERGE_REQUEST_PROJECT_PATH`             | 머지 리퀘스트의 프로젝트 경로입니다. 예: `namespace/awesome-project`. |
| `CI_MERGE_REQUEST_PROJECT_URL`              | 머지 리퀘스트의 프로젝트 URL입니다. 예를 들어, `http://192.168.10.15:3000/namespace/awesome-project`입니다. |
| `CI_MERGE_REQUEST_REF_PATH`                 | 머지 리퀘스트의 참조 경로입니다. 예를 들어, `refs/merge-requests/1/head`입니다. |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_NAME`       | 머지 리퀘스트의 소스 브랜치 이름입니다. |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_PROTECTED`  | 머지 리퀘스트의 소스 브랜치가 [보호됨](../../user/project/repository/branches/protected.md)일 경우 `true`입니다. |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA`        | 머지 리퀘스트의 소스 브랜치의 HEAD SHA입니다. 이 변수는 머지 리퀘스트 파이프라인에서 비어 있습니다. SHA는 [병합 결과 파이프라인](../pipelines/merged_results_pipelines.md)에만 있습니다. |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_ID`        | 머지 리퀘스트의 소스 프로젝트 ID입니다. |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_PATH`      | 머지 리퀘스트의 소스 프로젝트 경로입니다. |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_URL`       | 머지 리퀘스트의 소스 프로젝트 URL입니다. |
| `CI_MERGE_REQUEST_SQUASH_ON_MERGE`          | [병합 시 스쿼시](../../user/project/merge_requests/squash_and_merge.md) 옵션이 설정된 경우 `true`입니다. |
| `CI_MERGE_REQUEST_TARGET_BRANCH_NAME`       | 머지 리퀘스트의 대상 브랜치 이름입니다. |
| `CI_MERGE_REQUEST_TARGET_BRANCH_PROTECTED`  | 머지 리퀘스트의 대상 브랜치가 [보호됨](../../user/project/repository/branches/protected.md)일 경우 `true`입니다. |
| `CI_MERGE_REQUEST_TARGET_BRANCH_SHA`        | 머지 리퀘스트의 대상 브랜치의 HEAD SHA입니다. 이 변수는 머지 리퀘스트 파이프라인에서 비어 있습니다. SHA는 [병합 결과 파이프라인](../pipelines/merged_results_pipelines.md)에만 있습니다. |
| `CI_MERGE_REQUEST_TITLE`                    | 머지 리퀘스트의 제목입니다. |
| `CI_MERGE_REQUEST_DRAFT`                    | 머지 리퀘스트가 초안인 경우 `true`입니다. GitLab 17.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/275981)되었습니다. |

## 외부 풀 리퀘스트 파이프라인의 사전 정의된 변수 {#predefined-variables-for-external-pull-request-pipelines}

이 변수는 다음인 경우에만 사용할 수 있습니다.

- 파이프라인은 [외부 풀 리퀘스트 파이프라인](../ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests)입니다
- 풀 리퀘스트가 열려 있습니다.

| 변수                                      | 설명 |
|-----------------------------------------------|-------------|
| `CI_EXTERNAL_PULL_REQUEST_IID`                | GitHub의 풀 리퀘스트 ID입니다. |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_REPOSITORY`  | 풀 리퀘스트의 소스 리포지토리 이름입니다. |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_REPOSITORY`  | 풀 리퀘스트의 대상 리포지토리 이름입니다. |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_NAME` | 풀 리퀘스트의 소스 브랜치 이름입니다. |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_SHA`  | 풀 리퀘스트의 소스 브랜치의 HEAD SHA입니다. |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_NAME` | 풀 리퀘스트의 대상 브랜치 이름입니다. |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_SHA`  | 풀 리퀘스트의 대상 브랜치의 HEAD SHA입니다. |

## 배포 변수 {#deployment-variables}

배포 설정을 담당하는 통합은 빌드 환경에 설정된 자체 사전 정의된 변수를 정의할 수 있습니다. 이 변수는 [배포 작업](../environments/_index.md)에만 정의됩니다.

예를 들어 [Kubernetes 통합](../../user/project/clusters/deploy_to_cluster.md#deployment-variables)은 통합과 함께 사용할 수 있는 배포 변수를 정의합니다.

[각 통합의 설명서](../../user/project/integrations/_index.md)에서 통합에 사용 가능한 배포 변수가 있는지 설명합니다.

## 자동 DevOps 변수 {#auto-devops-variables}

[자동 DevOps](../../topics/autodevops/_index.md)가 활성화되면 일부 추가 [파이프라인 전](#variable-availability) 변수를 사용할 수 있습니다.

- `AUTO_DEVOPS_EXPLICITLY_ENABLED`: `1`의 값을 사용하여 자동 DevOps가 활성화되어 있음을 나타냅니다.
- `STAGING_ENABLED`: [자동 DevOps 배포 전략](../../topics/autodevops/requirements.md#auto-devops-deployment-strategy)을 참조하세요.
- `INCREMENTAL_ROLLOUT_MODE`: [자동 DevOps 배포 전략](../../topics/autodevops/requirements.md#auto-devops-deployment-strategy)을 참조하세요.
- `INCREMENTAL_ROLLOUT_ENABLED`: 지원 중단됨.

## 통합 변수 {#integration-variables}

일부 통합은 작업에서 변수를 사용할 수 있습니다. 이 변수는 [작업 전용 사전 정의된 변수](#variable-availability)로 사용 가능합니다.

- [Harbor](../../user/project/integrations/harbor.md):
  - `HARBOR_URL`
  - `HARBOR_HOST`
  - `HARBOR_OCI`
  - `HARBOR_PROJECT`
  - `HARBOR_USERNAME`
  - `HARBOR_PASSWORD`
- [Apple App Store Connect](../../user/project/integrations/apple_app_store.md):
  - `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
  - `APP_STORE_CONNECT_API_KEY_KEY_ID`
  - `APP_STORE_CONNECT_API_KEY_KEY`
  - `APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64`
- [Google Play](../../user/project/integrations/google_play.md):
  - `SUPPLY_PACKAGE_NAME`
  - `SUPPLY_JSON_KEY_DATA`
- [Diffblue Cover](../../integration/diffblue_cover.md):
  - `DIFFBLUE_LICENSE_KEY`
  - `DIFFBLUE_ACCESS_TOKEN_NAME`
  - `DIFFBLUE_ACCESS_TOKEN`

## 문제 해결 {#troubleshooting}

`script` 명령으로 [작업에 사용 가능한 모든 변수의 값을 출력](variables_troubleshooting.md#list-all-variables)할 수 있습니다.
