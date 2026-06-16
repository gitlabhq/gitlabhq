---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 짧은 수명의 작업 토큰을 사용하여 GitLab 기능으로 CI/CD 작업을 인증합니다.
title: CI/CD 작업 토큰
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD 파이프라인 작업이 실행되려고 할 때, GitLab은 고유한 토큰을 생성하여 [`CI_JOB_TOKEN` 사전 정의 변수](../variables/predefined_variables.md)로 작업에 제공합니다. 토큰은 작업이 실행되는 동안에만 유효합니다. 작업이 완료된 후에는 토큰 액세스가 취소되고 더 이상 토큰을 사용할 수 없습니다.

CI/CD 작업 토큰을 사용하여 실행 중인 작업에서 특정 GitLab 기능으로 인증합니다. 토큰은 파이프라인을 트리거한 사용자와 동일한 액세스 수준을 받지만, [더 적은 리소스에 액세스](#job-token-access)할 수 있으며 개인 액세스 토큰보다는 기능이 제한됩니다. 사용자는 커밋을 푸시하거나, 수동 작업을 실행하거나, 예약된 파이프라인을 소유하여 작업을 트리거할 수 있습니다. 이 사용자는 리소스에 액세스하기 위해 [필수 권한이 있는 역할](../../user/permissions.md#project-cicd)을 가져야 합니다.

작업 토큰을 사용하여 GitLab으로 인증하고 다른 그룹 또는 프로젝트의 리소스(대상 프로젝트)에 액세스할 수 있습니다. 기본적으로 작업 토큰의 그룹 또는 프로젝트는 [대상 프로젝트의 허용 목록에 추가](#add-a-group-or-project-to-the-job-token-allowlist)되어야 합니다.

프로젝트가 공개 또는 내부인 경우, 허용 목록에 없어도 일부 기능에 액세스할 수 있습니다. 예를 들어 프로젝트의 공개 파이프라인에서 작업 아티팩트를 가져올 수 있습니다. 이 액세스는 [제한](#limit-job-token-scope-for-public-or-internal-projects)될 수도 있습니다.

## 작업 토큰 액세스 {#job-token-access}

{{< history >}}

- 단일 태그를 가져올 수 있는 권한이 GitLab 18.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216463)되었습니다.

{{< /history >}}

CI/CD 작업 토큰은 다음 리소스에 액세스할 수 있습니다:

| 리소스                                                                                              | 참고 |
| ----------------------------------------------------------------------------------------------------- | ----- |
| [브랜치 API](../../api/branches.md)                                                                 | `GET /projects/:id/repository/branches` 엔드포인트에 액세스할 수 있습니다. |
| [커밋 API](../../api/commits.md)                                                                   | `GET /projects/:id/repository/commits/:sha` 및 `GET /projects/:id/repository/commits/:sha/merge_requests` 엔드포인트에 액세스할 수 있습니다. |
| [컨테이너 레지스트리](../../user/packages/container_registry/build_and_push_images.md#use-gitlab-cicd) | `$CI_REGISTRY_PASSWORD` [사전 정의 변수](../variables/predefined_variables.md)로 사용되어 작업의 프로젝트와 연결된 컨테이너 레지스트리로 인증합니다. |
| [패키지 레지스트리](../../user/packages/package_registry/_index.md#to-build-packages)                  | 레지스트리로 인증하는 데 사용됩니다. |
| [Terraform 모듈 레지스트리](../../user/packages/terraform_module_registry/_index.md)                  | 레지스트리로 인증하는 데 사용됩니다. |
| [보안 파일](../secure_files/_index.md#use-secure-files-in-cicd-jobs)                               | [`glab securefile`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/securefile) 명령으로 작업에서 보안 파일을 사용합니다. |
| [컨테이너 레지스트리 API](../../api/container_registry.md)                                             | 작업의 프로젝트와 연결된 컨테이너 레지스트리로만 인증할 수 있습니다. |
| [배포 API](../../api/deployments.md)                                                           | 이 API의 모든 엔드포인트에 액세스할 수 있습니다. |
| [환경 API](../../api/environments.md)                                                         | 이 API의 모든 엔드포인트에 액세스할 수 있습니다. |
| [파일 API](../../api/repository_files.md)                                                            | `GET /projects/:id/repository/files/:file_path/raw` 엔드포인트에 액세스할 수 있습니다. |
| [작업 API](../../api/jobs.md#retrieve-a-job-by-job-token)                                             | `GET /job` 엔드포인트만 액세스할 수 있습니다. |
| [작업 아티팩트 API](../../api/job_artifacts.md)                                                       | 다운로드 엔드포인트만 액세스할 수 있습니다. |
| [머지 리퀘스트 API](../../api/merge_requests.md)                                                     | `GET /projects/:id/merge_requests` 및 `GET /projects/:id/merge_requests/:merge_request_iid` 엔드포인트에 액세스할 수 있습니다. |
| [메모 API](../../api/notes.md)                                                                       | `GET /projects/:id/merge_requests/:merge_request_iid/notes` 및 `GET /projects/:id/merge_requests/:merge_request_iid/notes/:note_id` 엔드포인트에 액세스할 수 있습니다. |
| [패키지 API](../../api/packages.md)                                                                 | 이 API의 모든 엔드포인트에 액세스할 수 있습니다. |
| [파이프라인 트리거 토큰 API](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)         | `POST /projects/:id/trigger/pipeline` 엔드포인트만 액세스할 수 있습니다. |
| [파이프라인 API](../../api/pipelines.md#update-pipeline-metadata)                                      | `PUT /projects/:id/pipelines/:pipeline_id/metadata` 엔드포인트만 액세스할 수 있습니다. |
| [릴리스 링크 API](../../api/releases/links.md)                                                      | 이 API의 모든 엔드포인트에 액세스할 수 있습니다. |
| [릴리스 API](../../api/releases/_index.md)                                                          | 이 API의 모든 엔드포인트에 액세스할 수 있습니다. |
| [리포지토리 API](../../api/repositories.md#generate-changelog-data)                                 | 공개 리포지토리의 `GET /projects/:id/repository/changelog` 엔드포인트만 액세스할 수 있습니다. |
| [태그 API](../../api/tags.md)                                                                         | `GET /projects/:id/repository/tags` 및 `GET /projects/:id/repository/tags/:tag_name` 엔드포인트에 액세스할 수 있습니다. |

권한을 더 세밀하게 조정하기 위한 공개 [제안](https://gitlab.com/groups/gitlab-org/-/epics/3559)이 있습니다.

## GitLab CI/CD 작업 토큰 보안 {#gitlab-cicd-job-token-security}

작업 토큰이 유출되면 CI/CD 작업을 실행한 사용자가 액세스할 수 있는 비공개 데이터에 액세스하는 데 사용될 수 있습니다. 이 토큰의 유출 또는 오용을 방지하기 위해 GitLab은:

- 작업 로그에서 작업 토큰을 마스킹합니다.
- 작업이 실행 중일 때만 작업 토큰에 권한을 부여합니다.

또한 [러너](../runners/_index.md)를 보안 상태로 구성해야 합니다:

- 머신을 재사용할 경우 Docker `privileged` 모드 사용을 피합니다.
- 작업이 같은 머신에서 실행될 때 [`shell` 실행기](https://docs.gitlab.com/runner/executors/shell/) 사용을 피합니다.

보안되지 않은 GitLab 러너 구성은 다른 작업에서 토큰을 도용할 위험을 증가시킵니다.

## 프로젝트에 대한 작업 토큰 액세스 제어 {#control-job-token-access-to-your-project}

어떤 그룹 또는 프로젝트가 작업 토큰을 사용하여 인증하고 프로젝트의 일부 리소스에 액세스할 수 있는지 제어할 수 있습니다.

기본적으로 작업 토큰 액세스는 프로젝트의 파이프라인에서 실행되는 CI/CD 작업에만 제한됩니다. 다른 그룹 또는 프로젝트가 다른 프로젝트의 파이프라인에서 작업 토큰으로 인증하도록 허용하려면:

- [그룹 또는 프로젝트를 작업 토큰 허용 목록에 추가](#add-a-group-or-project-to-the-job-token-allowlist)해야 합니다.
- 작업을 트리거하는 사용자는 프로젝트의 멤버여야 합니다.
- 사용자는 작업을 수행할 [권한](../../user/permissions.md)이 있어야 합니다.

프로젝트가 공개 또는 내부인 경우, 일부 공개적으로 액세스 가능한 리소스에 모든 프로젝트의 작업 토큰으로 액세스할 수 있습니다. 이러한 리소스는 [허용 목록의 프로젝트에만 액세스 제한](#limit-job-token-scope-for-public-or-internal-projects)될 수도 있습니다.

GitLab Self-Managed 관리자는 [이 설정을 무시하고 강제 적용](../../administration/settings/continuous_integration.md#access-job-token-permission-settings)할 수 있습니다. 설정이 강제 적용되면 CI/CD 작업 토큰은 항상 프로젝트의 허용 목록으로 제한됩니다.

### 작업 토큰 허용 목록에 그룹 또는 프로젝트 추가 {#add-a-group-or-project-to-the-job-token-allowlist}

{{< history >}}

- GitLab 15.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/346298/)되었습니다. [`:inbound_ci_scoped_job_token` 기능 플래그 뒤에 배포](../../administration/feature_flags/_index.md)되었으며, 기본적으로 활성화됩니다.
- GitLab 15.10에서 [기능 플래그 제거](https://gitlab.com/gitlab-org/gitlab/-/issues/346298/)됨.
- **Allow access to this project with a CI_JOB_TOKEN** 설정이 GitLab 16.3에서 [**Limit access to this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406)으로 이름 변경되었습니다.
- 작업 토큰 허용 목록에 그룹 추가가 GitLab 17.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)되었습니다.
- **Token Access** 섹션이 **작업 토큰 권한**으로 이름 변경되었으며, [**Limit access to this project** 설정이 **승인된 그룹 및 프로젝트**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)로 GitLab 17.2에서 이름 변경되었습니다.
- [**승인된 그룹 및 프로젝트** 설정이 **CI/CD 작업 토큰 허용 목록**](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160078)으로 GitLab 17.3에서 이름 변경되었습니다.
- **프로젝트 추가** 옵션이 GitLab 17.6에서 [**추가**](https://gitlab.com/gitlab-org/gitlab/-/issues/470880/)로 이름 변경되었습니다.

{{< /history >}}

프로젝트의 리소스에 액세스하기 위해 작업 토큰을 사용하여 그룹 또는 프로젝트를 작업 토큰 허용 목록에 추가할 수 있습니다. 기본적으로 프로젝트의 허용 목록은 자신을 포함합니다. 교차 프로젝트 액세스가 필요한 경우에만 그룹 또는 프로젝트를 허용 목록에 추가합니다.

허용 목록에 프로젝트를 추가하면 허용 목록된 프로젝트의 멤버에게 추가 [권한](../../user/permissions.md)이 주어지지 않습니다. 프로젝트의 리소스에 액세스하는 허용 목록된 프로젝트의 작업 토큰을 사용하여 프로젝트에 액세스하려면 먼저 프로젝트의 리소스에 액세스할 권한이 있어야 합니다.

예를 들어 프로젝트 A는 프로젝트 B를 프로젝트 A의 허용 목록에 추가할 수 있습니다. 프로젝트 B의 CI/CD 작업("허용된 프로젝트")은 이제 CI/CD 작업 토큰을 사용하여 프로젝트 A에 액세스하기 위해 API 호출을 인증할 수 있습니다.

전제 조건:

- 현재 프로젝트에 대한 유지보수자 또는 소유자 역할이 있어야 합니다. 허용된 프로젝트가 내부 또는 비공개인 경우, 해당 프로젝트에서 게스트, 플래너, 리포터, 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.
- 허용 목록에 200개 이상의 그룹과 프로젝트를 추가할 수 없습니다.

그룹 또는 프로젝트를 허용 목록에 추가하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **작업 토큰 권한**을 확장합니다.
1. **CI/CD 작업 토큰 허용 목록**의 오른쪽에서 **추가**를 선택합니다.
1. **그룹 또는 프로젝트**를 선택합니다.
1. 허용 목록에 추가할 그룹 또는 프로젝트의 경로를 입력하고 **추가**를 선택합니다.

[API로](../../api/graphql/reference/_index.md#mutationcijobtokenscopeaddgrouporproject) 그룹 또는 프로젝트를 허용 목록에 추가할 수도 있습니다.

### 공개 또는 내부 프로젝트의 작업 토큰 범위 제한 {#limit-job-token-scope-for-public-or-internal-projects}

{{< history >}}

- GitLab 16.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/405369)되었습니다.
- 리포지토리에 대한 액세스가 GitLab 17.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/439158)되었습니다.

{{< /history >}}

허용 목록에 없는 프로젝트는 공개 또는 내부 프로젝트로 인증하기 위해 작업 토큰을 사용할 수 있습니다:

- 아티팩트를 가져옵니다.
- 컨테이너 레지스트리에 액세스합니다.
- 패키지 레지스트리에 액세스합니다.
- 릴리스, 배포 및 환경에 액세스합니다.
- 리포지토리에 액세스합니다.

각 기능을 프로젝트 멤버에게만 표시되도록 설정하여 허용 목록의 프로젝트에만 이러한 작업에 대한 액세스를 제한할 수 있습니다.

전제 조건:

- 프로젝트에 대한 유지보수자 역할이 있어야 합니다.

프로젝트 멤버에게만 표시되도록 기능을 설정하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. 액세스를 제한하려는 기능에 대해 표시 여부를 **Only project members**으로 설정합니다.
   - 아티팩트를 가져오는 기능은 CI/CD 표시 여부 설정으로 제어됩니다.
1. **변경사항 저장**을 선택합니다.

### 모든 프로젝트가 프로젝트에 액세스하도록 허용 {#allow-any-project-to-access-your-project}

{{< details >}}

- 제공:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- **Allow access to this project with a CI_JOB_TOKEN** 설정이 GitLab 16.3에서 [**Limit access to this project**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406)으로 이름 변경되었습니다.
- **Token Access** 섹션이 **작업 토큰 권한**으로 이름 변경되었으며, [**Limit access to this project** 설정이 **승인된 그룹 및 프로젝트**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)로 GitLab 17.2에서 이름 변경되었습니다.
- [**승인된 그룹 및 프로젝트** 설정이 **CI/CD 작업 토큰 허용 목록**](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160078)으로 GitLab 17.3에서 이름 변경되었습니다.

{{< /history >}}

> [!warning]
> 토큰 액세스 제한 및 허용 목록을 비활성화하는 것은 보안 위험입니다. 악의적인 사용자가 승인되지 않은 프로젝트에서 생성된 파이프라인을 손상시키려고 시도할 수 있습니다. 파이프라인이 유지보수자 중 한 명에 의해 생성된 경우, 작업 토큰을 사용하여 프로젝트에 액세스를 시도할 수 있습니다.

CI/CD 작업 토큰 허용 목록을 비활성화하면, 모든 프로젝트의 작업이 작업 토큰으로 프로젝트에 액세스할 수 있습니다. 파이프라인을 트리거하는 사용자는 프로젝트에 액세스할 권한이 있어야 합니다. 테스트 또는 유사한 이유로 이 설정을 비활성화해야 하며, 가능한 한 빨리 다시 활성화해야 합니다.

이 옵션은 [**Enable and enforce job token allowlist for all projects** 설정](../../administration/settings/continuous_integration.md#enforce-job-token-allowlist)이 비활성화된 GitLab Self-Managed 또는 GitLab Dedicated 인스턴스에서만 사용할 수 있습니다.

전제 조건:

- 프로젝트에 대한 유지보수자 또는 소유자 역할이 있어야 합니다.

작업 토큰 허용 목록을 비활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **작업 토큰 권한**을 확장합니다.
1. **모든 그룹과 프로젝트**를 선택합니다.
1. 권장됨. 테스트를 마치면 **This project and any groups and projects in the allowlist**를 선택하여 작업 토큰 허용 목록을 다시 활성화합니다.

또한 [GraphQL](../../api/graphql/reference/_index.md#mutationprojectcicdsettingsupdate) (`inboundJobTokenScopeEnabled`) 또는 [REST](../../api/project_job_token_scopes.md#update-the-cicd-job-token-access-settings-for-a-project) API로 이 설정을 수정할 수 있습니다.

### 프로젝트 리포지토리에 Git 푸시 요청 허용 {#allow-git-push-requests-to-your-project-repository}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/389060) 되었습니다. [기능 플래그](../../administration/feature_flags/_index.md) `allow_push_repository_for_job_token` 이름으로. 기본적으로 비활성화됨.
- **Token Access** 섹션이 **작업 토큰 권한**으로 이름 변경되었으며, [**Limit access to this project** 설정이 **승인된 그룹 및 프로젝트**](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)로 GitLab 17.2에서 이름 변경되었습니다.
- [**승인된 그룹 및 프로젝트** 설정이 **CI/CD 작업 토큰 허용 목록**](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160078)으로 GitLab 17.3에서 이름 변경되었습니다.
- GitLab 18.3에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/468320)됨.
- GitLab 18.4에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/468320). 기능 플래그 `allow_push_repository_for_job_token` 제거됨.

{{< /history >}}

CI/CD 작업 토큰으로 인증된 Git 푸시 요청을 허용하도록 프로젝트를 구성할 수 있습니다. 이 설정은 기본적으로 꺼져 있습니다.

이 설정을 활성화하면, 프로젝트 파이프라인에서 실행되는 CI/CD 작업에 의해 생성된 작업 토큰만 프로젝트에 푸시할 수 있습니다.

작업 토큰을 사용하여 프로젝트에 푸시하면, CI/CD 파이프라인이 트리거되지 않습니다. 작업 토큰은 작업을 시작한 사용자와 동일한 액세스 권한을 갖습니다.

`semantic-release` 도구를 사용하면, [이 설정이 파이프라인 생성을 방지](#the-semantic-release-tool-and-job-tokens)할 수 있습니다.

> [!warning]
> [풀 미러](../../user/project/repository/mirror/pull.md) 로 구성된 프로젝트에서는 이 설정을 활성화하지 마십시오. 특히 [미러 업데이트에 대해 파이프라인이 실행](../../user/project/repository/mirror/pull.md#trigger-pipelines-for-mirror-updates)되는 경우 더욱 그렇습니다. 업스트림 리포지토리 소유자는 `CI_JOB_TOKEN`을 사용하여 미러된 프로젝트에 커밋을 푸시하려고 시도할 수 있습니다.

전제 조건:

- 프로젝트에 대한 유지보수자 또는 소유자 역할이 있어야 합니다.

프로젝트에서 생성된 작업 토큰에 프로젝트의 리포지토리에 푸시할 수 있는 권한을 부여하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **작업 토큰 권한**을 확장합니다.
1. **권한** 섹션에서 **리포지토리에 Git 푸시 요청 허용**을 선택합니다.

또한 [프로젝트 API](../../api/projects.md#update-a-project)의 `ci_push_repository_for_job_token_allowed` 매개변수로 이 설정을 제어할 수 있습니다.

### 허용 목록된 프로젝트에서 교차 프로젝트 Git 푸시 요청 허용 {#allow-cross-project-git-push-requests-from-allowlisted-projects}

{{< history >}}

- GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/479907) 되었습니다. [기능 플래그](../../administration/feature_flags/_index.md) `allow_push_to_allowlisted_projects` 이름으로. 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 이력을 참조하세요.

허용 목록된 프로젝트의 CI/CD 작업 토큰이 프로젝트 리포지토리에 푸시할 수 있도록 허용할 수 있습니다. 이는 GitOps 워크플로, 서브모듈 태깅 및 수명이 긴 액세스 토큰이 없는 교차 리포지토리 CI/CD 파이프라인에 유용합니다.

작업 토큰 푸시가 성공하면, 대상 프로젝트에서 CI/CD 파이프라인이 트리거되지 않습니다.

> [!warning]
> [풀 미러](../../user/project/repository/mirror/pull.md) 로 구성된 프로젝트에서는 이 설정을 활성화하지 마십시오. 특히 [파이프라인이 미러 업데이트에 대해 트리거](../../user/project/repository/mirror/pull.md#trigger-pipelines-for-mirror-updates)되는 경우 더욱 그렇습니다. 허용 목록된 소스 프로젝트의 소유자는 CI/CD 작업 토큰을 사용하여 미러된 프로젝트에 커밋을 푸시할 수 있습니다.

교차 프로젝트 푸시가 작동하려면 다음의 모든 사항이 참이어야 합니다:

- 대상 프로젝트는 **리포지토리에 Git 푸시 요청 허용**이 활성화되어 있습니다.
- 대상 프로젝트는 **Allow cross-project Git push requests from allowlisted projects**이 활성화되어 있습니다.
- 대상 프로젝트는 [작업 토큰 허용 목록](#add-a-group-or-project-to-the-job-token-allowlist)이 활성화되어 있습니다.
- 소스 프로젝트는 `admin_repositories` [세밀한 권한](fine_grained_permissions.md)이 있는 대상 프로젝트의 허용 목록에 있거나, 기본 권한(세밀한 제한이 설정되지 않음)이 있습니다. 소스 프로젝트를 포함하는 허용 목록의 그룹 항목도 이 요구 사항을 충족합니다.
- 파이프라인을 시작한 사용자는 대상 프로젝트에서 최소한 개발자 역할을 갖습니다.

전제 조건:

- 프로젝트에 대한 유지보수자 또는 소유자 역할이 있어야 합니다.

교차 프로젝트 푸시 요청을 허용하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. **설정** > **CI/CD**를 선택합니다.
1. **작업 토큰 권한**을 확장합니다.
1. **권한** 섹션에서 **리포지토리에 Git 푸시 요청 허용**을 선택합니다.
1. **Allow cross-project Git push requests from allowlisted projects**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.
1. [소스 프로젝트 또는 해당 그룹을 허용 목록에 추가](#add-a-group-or-project-to-the-job-token-allowlist)하고 `ADMIN_REPOSITORIES` 세밀한 권한을 사용하거나, 기본 권한을 활성화된 상태로 유지합니다.

## 작업 토큰의 세밀한 권한 {#fine-grained-permissions-for-job-tokens}

세밀한 권한을 사용하여 제한된 REST API 엔드포인트 집합에 대한 액세스를 명시적으로 허용할 수 있습니다.

자세한 내용은 [CI/CD 작업 토큰의 세밀한 권한](fine_grained_permissions.md)을 참조하세요.

## Git 리포지토리 복제 {#git-repository-cloning}

작업 토큰을 사용하여 CI/CD 작업에서 비공개 프로젝트의 리포지토리를 인증하고 복제할 수 있습니다. `gitlab-ci-token`을 사용자로 사용하고, 작업 토큰의 값을 비밀번호로 사용합니다.

예를 들어:

```shell
git clone https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.example.com/<namespace>/<project>
```

HTTPS 프로토콜이 [그룹, 프로젝트 또는 인스턴스 설정으로 비활성화](../../administration/settings/visibility_and_access_controls.md#configure-enabled-git-access-protocols)된 경우에도 이 작업 토큰을 사용하여 리포지토리를 복제할 수 있습니다.

## REST API 인증 {#rest-api-authentication}

작업 토큰을 사용하여 다음 방법을 사용하는 특정 REST API 엔드포인트에 대한 요청을 인증할 수 있습니다:

- 헤더: `--header "JOB-TOKEN: $CI_JOB_TOKEN"` (권장)
- 양식: `--form "token=$CI_JOB_TOKEN"`
- 데이터: `--data "job_token=$CI_JOB_TOKEN"`
- URL의 쿼리 문자열: `?job_token=$CI_JOB_TOKEN` (권장하지 않음)

예를 들어 권장 헤더 방법을 사용합니다:

```shell
curl --verbose --request POST --header "JOB-TOKEN: $CI_JOB_TOKEN" --form ref=master "https://gitlab.com/api/v4/projects/1234/trigger/pipeline"
```

토큰 보안 지침은 [보안 고려 사항](../../security/tokens/_index.md#security-considerations)을 참조하세요.

GraphQL 요청을 인증하는 데 작업 토큰을 사용할 수 없습니다.

## 작업 토큰 인증 로그 {#job-token-authentication-log}

{{< history >}}

- GitLab 17.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467292/)되었습니다.

{{< /history >}}

다른 프로젝트가 작업 토큰으로 프로젝트를 인증하는 데 사용하는 경우를 인증 로그에서 추적할 수 있습니다. 로그를 확인하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **작업 토큰 권한**을 확장합니다. **인증 로그** 섹션은 작업 토큰으로 인증하여 프로젝트에 액세스한 다른 프로젝트의 목록을 표시합니다.
1. 선택 사항. **CSV 다운로드**를 선택하여 전체 인증 로그를 CSV 형식으로 다운로드합니다.

인증 로그는 최대 100개의 인증 이벤트를 표시합니다. 이벤트의 수가 100개를 초과하면 CSV 파일을 다운로드하여 로그를 봅니다.

새로운 프로젝트 인증은 인증 로그에 나타나는 데 최대 5분이 걸릴 수 있습니다.

## CI/CD 토큰에 대해 레거시 형식 사용 {#use-legacy-format-for-cicd-tokens}

{{< history >}}

- GitLab 17.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/514860)되었습니다.

{{< /history >}}

GitLab 19.0부터 CI/CD 작업 토큰은 기본적으로 JWT 표준을 사용합니다. 프로젝트는 프로젝트의 최상위 그룹을 구성하여 레거시 형식을 계속 사용할 수 있습니다. 이 설정은 GitLab 20.0 릴리스까지만 사용할 수 있습니다.

CI/CD 토큰에 대해 레거시 형식을 사용하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **일반 파이프라인**을 확장합니다.
1. **CI/CD 작업 토큰에 JWT 형식 사용**을 끕니다.

CI/CD 토큰이 이제 레거시 형식을 사용합니다. 나중에 JWT 형식을 다시 사용하려면 이 설정을 다시 활성화할 수 있습니다.

## 문제 해결 {#troubleshooting}

CI 작업 토큰 실패는 일반적으로 `404 Not Found` 또는 유사한 응답으로 표시됩니다:

- 승인되지 않은 Git 복제:

  ```plaintext
  $ git clone https://gitlab-ci-token:$CI_JOB_TOKEN@gitlab.com/fabiopitino/test2.git

  Cloning into 'test2'...
  remote: The project you were looking for could not be found or you don't have permission to view it.
  fatal: repository 'https://gitlab-ci-token:[MASKED]@gitlab.com/<namespace>/<project>.git/' not found
  ```

- 승인되지 않은 패키지 다운로드:

  ```plaintext
  $ wget --header="JOB-TOKEN: $CI_JOB_TOKEN" ${CI_API_V4_URL}/projects/1234/packages/generic/my_package/0.0.1/file.txt

  --2021-09-23 11:00:13--  https://gitlab.com/api/v4/projects/1234/packages/generic/my_package/0.0.1/file.txt
  Resolving gitlab.com (gitlab.com)... 172.65.251.78, 2606:4700:90:0:f22e:fbec:5bed:a9b9
  Connecting to gitlab.com (gitlab.com)|172.65.251.78|:443... connected.
  HTTP request sent, awaiting response... 404 Not Found
  2021-09-23 11:00:13 ERROR 404: Not Found.
  ```

- 승인되지 않은 API 요청:

  ```plaintext
  $ curl --verbose --request POST --form "token=$CI_JOB_TOKEN" --form ref=master "https://gitlab.com/api/v4/projects/1234/trigger/pipeline"

  < HTTP/2 404
  < date: Thu, 23 Sep 2021 11:00:12 GMT
  {"message":"404 Not Found"}
  < content-type: application/json
  ```

CI/CD 작업 토큰 인증 문제를 문제 해결하는 동안 다음에 유의하세요:

- [GraphQL 예제 변경](../../api/graphql/getting_started.md#update-project-settings)은 프로젝트별로 범위 설정을 토글하는 데 사용할 수 있습니다.
- [이 주석](https://gitlab.com/gitlab-org/gitlab/-/issues/351740#note_1335673157)은 GraphQL과 Bash 및 cURL을 함께 사용하는 방법을 보여줍니다:
  - 인바운드 토큰 액세스 범위를 활성화합니다.
  - 프로젝트 A에서 프로젝트 B로 액세스 권한을 부여하거나 B를 A의 허용 목록에 추가합니다.
  - 프로젝트 액세스를 제거합니다.
- CI 작업 토큰은 작업이 더 이상 실행되지 않거나 지워지거나 프로젝트가 삭제 중인 경우 유효하지 않게 됩니다.

### `semantic-release` 도구 및 작업 토큰 {#the-semantic-release-tool-and-job-tokens}

`semantic-release` 도구를 [**리포지토리에 Git 푸시 요청 허용** 설정](#allow-git-push-requests-to-your-project-repository)으로 사용하는 경우 알려진 문제가 있습니다. 활성화된 경우:

- 도구는 작업 토큰으로 인증하며, 개인 액세스 토큰을 사용하도록 구성된 경우에도 그렇습니다.
- 작업 토큰은 새로운 파이프라인을 트리거하지 않으므로, 릴리스 파이프라인이 실행되지 않을 수 있습니다.

자세한 내용은 [문제 891](https://github.com/semantic-release/gitlab/issues/891)을 참조하세요.

### JWT 형식 작업 토큰 오류 {#jwt-format-job-token-errors}

CI/CD 작업 토큰의 JWT 형식과 관련된 알려진 문제가 있습니다.

#### `Error when persisting the task ARN.` EC2 Fargate 러너 실행기 오류 {#error-when-persisting-the-task-arn-error-with-ec2-fargate-runner-custom-executor}

EC2 Fargate 실행기의 버전 `0.5.0` 및 그 이전 버전에서 [버그](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/fargate/-/issues/86)가 있습니다. 이 문제는 다음 오류를 발생시킵니다:

- `Error when persisting the task ARN. Will stop the task for cleanup`

이 문제를 해결하려면 Fargate 실행기의 버전 `0.5.1` 이상으로 업그레이드합니다.

#### `invalid character '\n' in string literal` `base64` 인코딩 오류 {#invalid-character-n-in-string-literal-error-with-base64-encoding}

`base64`을 사용하여 작업 토큰을 인코딩하면 `invalid character '\n'` 오류를 받을 수 있습니다.

`base64` 명령의 기본 동작은 79자보다 긴 문자열을 줄바꿈합니다. 작업 실행 중에 JWT 형식 작업 토큰을 `base64` 인코딩할 때, 예를 들어 `echo $CI_JOB_TOKEN | base64`을 사용하면 토큰이 무효화됩니다.

이 문제를 해결하려면 `base64 -w0`을 사용하여 토큰의 자동 줄바꿈을 비활성화합니다.

#### 오류: `403 Forbidden` 장시간 실행되는 작업에서 {#error-403-forbidden-in-long-running-jobs}

GitLab 18.8 이전 버전에서 JWT 형식 작업 토큰을 사용할 때 작업이 `403 Forbidden` 오류로 실패할 수 있습니다. 이는 다음에서 발생할 수 있습니다:

- [`needs`](../yaml/_index.md#needs)를 사용하는 작업.
- [자식 파이프라인](../pipelines/downstream_pipelines.md#parent-child-pipelines)의 작업.
- 콘솔 출력을 생성하지 않고 약 6분 이상 실행되는 작업.

오류는 일반적으로 러너 로그에 다음과 같이 나타났습니다:

```plaintext
WARNING: Submitting job to coordinator... job failed
  code=403 job=<job_id> status=PUT https://gitlab.com/api/v4/jobs/<job_id>: 403 Forbidden
```

이 문제를 방지하려면 GitLab 18.9로 업데이트합니다.
