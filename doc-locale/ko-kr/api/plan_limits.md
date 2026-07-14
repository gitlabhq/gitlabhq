---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 계획 제한 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 기존 구독 계획의 애플리케이션 제한과 상호작용할 수 있습니다.

기존 계획은 GitLab 에디션에 따라 달라집니다. 커뮤니티 에디션에서는 `default` 계획만 사용할 수 있습니다. Enterprise Edition에서는 추가 계획도 사용할 수 있습니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

## 현재 계획 제한 검색 {#retrieve-current-plan-limits}

GitLab 인스턴스의 계획 현재 제한을 검색합니다.

```plaintext
GET /application/plan_limits
```

| 속성                         | 유형    | 필수 | 설명 |
| --------------------------------- | ------- | -------- | ----------- |
| `plan_name`                       | 문자열  | 아니요       | 제한을 가져올 계획의 이름입니다. 기본값: `default`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/plan_limits"
```

응답 예시:

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

## 계획 제한 업데이트 {#update-plan-limits}

GitLab 인스턴스의 계획 제한을 업데이트합니다.

```plaintext
PUT /application/plan_limits
```

| 속성                         | 유형    | 필수 | 설명 |
| --------------------------------- | ------- | -------- | ----------- |
| `plan_name`                       | 문자열  | 예      | 업데이트할 계획의 이름입니다. |
| `ci_instance_level_variables`     | 정수 | 아니요       | 정의할 수 있는 인스턴스 수준 CI/CD 변수의 최대 개수입니다. |
| `ci_pipeline_size`                | 정수 | 아니요       | 단일 파이프라인의 최대 작업 개수입니다. [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895)됨: GitLab 15.0. |
| `ci_active_jobs`                  | 정수 | 아니요       | 현재 활성 파이프라인의 총 작업 개수입니다. [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895)됨: GitLab 15.0. |
| `ci_project_subscriptions`        | 정수 | 아니요       | 파이프라인 구독의 최대 개수입니다. [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895)됨: GitLab 15.0. |
| `ci_pipeline_schedules`           | 정수 | 아니요       | 파이프라인 일정의 최대 개수입니다. [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895)됨: GitLab 15.0. |
| `ci_needs_size_limit`             | 정수 | 아니요       | 작업이 가질 수 있는 [`needs`](../ci/yaml/needs.md) 종속성의 최대 개수입니다. [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895)됨: GitLab 15.0. |
| `ci_registered_group_runners`     | 정수 | 아니요       | 지난 7일 동안 그룹에서 생성되거나 활성화된 러너의 최대 개수입니다. [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895)됨: GitLab 15.0. |
| `ci_registered_project_runners`   | 정수 | 아니요       | 지난 7일 동안 프로젝트에서 생성되거나 활성화된 러너의 최대 개수입니다. [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895)됨: GitLab 15.0. |
| `dotenv_size`                     | 정수 | 아니요       | dotenv 아티팩트의 최대 크기(바이트)입니다. [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/432529)됨: GitLab 17.1. |
| `dotenv_variables`                | 정수 | 아니요       | dotenv 아티팩트의 최대 변수 개수입니다. [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/432529)됨: GitLab 17.1. |
| `conan_max_file_size`             | 정수 | 아니요       | Conan 패키지 파일의 최대 크기(바이트)입니다. |
| `enforcement_limit`               | 정수 | 아니요       | 루트 네임스페이스 제한 적용을 위한 최대 스토리지 크기(MiB)입니다. |
| `generic_packages_max_file_size`  | 정수 | 아니요       | 일반 패키지 파일의 최대 크기(바이트)입니다. |
| `helm_max_file_size`              | 정수 | 아니요       | Helm 차트 파일의 최대 크기(바이트)입니다. |
| `maven_max_file_size`             | 정수 | 아니요       | Maven 패키지 파일의 최대 크기(바이트)입니다. |
| `notification_limit`              | 정수 | 아니요       | 루트 네임스페이스 제한 알림을 위한 최대 스토리지 크기(MiB)입니다. |
| `npm_max_file_size`               | 정수 | 아니요       | NPM 패키지 파일의 최대 크기(바이트)입니다. |
| `nuget_max_file_size`             | 정수 | 아니요       | NuGet 패키지 파일의 최대 크기(바이트)입니다. |
| `max_pipelines_per_merge_train`   | 정수 | 아니요       | 머지 트레인당 병렬 파이프라인의 최대 개수입니다. 기본값: `20`. 최소값: `1`. GitLab 19.0에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/374188). |
| `pipeline_hierarchy_size`         | 정수 | 아니요       | 파이프라인 계층 트리의 최대 다운스트림 파이프라인 개수입니다. 기본값: `1000`. 1000보다 큰 값은 [권장되지 않습니다](../administration/cicd/limits.md#limit-pipeline-hierarchy-size). |
| `pypi_max_file_size`              | 정수 | 아니요       | PyPI 패키지 파일의 최대 크기(바이트)입니다. |
| `terraform_module_max_file_size`  | 정수 | 아니요       | Terraform Module 패키지 파일의 최대 크기(바이트)입니다. |
| `storage_size_limit`              | 정수 | 아니요       | 루트 네임스페이스의 최대 스토리지 크기(MiB)입니다. |
| `web_hook_calls`                  | 정수 | 아니요       | 웹후크가 최상위 네임스페이스당 분당 호출될 수 있는 최대 횟수입니다. [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/571738)됨: GitLab 18.5. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/plan_limits?plan_name=default&conan_max_file_size=3221225472"
```

응답 예시:

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
