---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: CI/CD 설정
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Admin 영역에서 GitLab 인스턴스의 CI/CD 설정을 구성합니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

다음 설정을 사용할 수 있습니다:

- 변수:  인스턴스의 모든 프로젝트에서 사용할 수 있는 CI/CD 변수를 구성합니다.
- 지속적 통합 및 배포:  Auto DevOps, 작업, 아티팩트, 인스턴스 러너 및 파이프라인 기능에 대한 설정을 구성합니다.
- 패키지 레지스트리:  패키지 전달 및 파일 크기 한도를 구성합니다.
- 러너:  러너 등록, 버전 관리 및 토큰 설정을 구성합니다.
- 작업 토큰 권한:  프로젝트 간 작업 토큰 액세스를 제어합니다.
- 작업 로그:  증분 로깅과 같은 작업 로그 설정을 구성합니다.
- [CI/CD 한도](../cicd/limits.md).

## 지속적 통합 및 배포 설정 액세스 {#access-continuous-integration-and-deployment-settings}

Auto DevOps, 인스턴스 러너 및 작업 아티팩트를 포함한 CI/CD 설정을 사용자 지정합니다.

이 설정에 액세스하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **지속적 통합 및 배포**를 확장합니다.

### 모든 프로젝트에 대한 Auto DevOps 구성 {#configure-auto-devops-for-all-projects}

[Auto DevOps](../../topics/autodevops/_index.md)를 구성하여 `.gitlab-ci.yml` 파일이 없는 모든 프로젝트에서 실행되도록 합니다. 이는 기존 프로젝트와 새 프로젝트에 모두 적용됩니다.

인스턴스의 모든 프로젝트에 대해 Auto DevOps를 구성하려면:

1. **모든 프로젝트에 대한 자동 DevOps 파이프라인 기본값으로 설정** 확인란을 선택합니다.
1. 선택사항. Auto Deploy 및 Auto Review Apps를 사용하려면 [Auto DevOps 기본 도메인](../../topics/autodevops/requirements.md#auto-devops-base-domain)을 지정합니다.
1. **변경 사항 저장**을 선택합니다.

### 인스턴스 러너 {#instance-runners}

#### 새 프로젝트에 대한 인스턴스 러너 활성화 {#enable-instance-runners-for-new-projects}

기본적으로 모든 새 프로젝트에서 인스턴스 러너를 사용할 수 있게 합니다.

새 프로젝트에서 인스턴스 러너를 사용할 수 있게 하려면:

1. **새 프로젝트에 대한 인스턴스 러너 활성화** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

#### 인스턴스 러너에 대한 세부 정보 추가 {#add-details-for-instance-runners}

인스턴스 러너에 대한 설명 텍스트를 추가합니다. 이 텍스트는 모든 프로젝트의 러너 설정에 표시됩니다.

인스턴스 러너 세부 정보를 추가하려면:

1. **Instance runner details** 텍스트 상자에 텍스트를 입력합니다. Markdown 형식을 사용할 수 있습니다.
1. **변경 사항 저장**을 선택합니다.

렌더링된 세부 정보를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하여 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.

![프로젝트의 러너 설정은 인스턴스 러너 지침에 대한 메시지를 표시합니다.](img/continuous_integration_instance_runner_details_v17_6.png)

#### 여러 프로젝트와 프로젝트 러너 공유 {#share-project-runners-with-multiple-projects}

여러 프로젝트와 프로젝트 러너를 공유합니다.

전제 조건:

- 등록된 [프로젝트 러너](../../ci/runners/runners_scope.md#project-runners)가 있어야 합니다.

여러 프로젝트와 프로젝트 러너를 공유하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. 편집할 러너를 선택합니다.
1. 오른쪽 상단 모서리에서 **편집** ({{< icon name="pencil" >}})을 선택합니다.
1. **Restrict projects for this runner** 아래에서 프로젝트를 검색합니다.
1. 프로젝트의 왼쪽에서 **사용**을 선택합니다.
1. 각 추가 프로젝트에 대해 이 프로세스를 반복합니다.

### 작업 아티팩트 {#job-artifacts}

[작업 아티팩트](../cicd/job_artifacts.md)가 GitLab 인스턴스 전체에서 저장되고 관리되는 방식을 제어합니다.

#### 최대 아티팩트 크기 설정 {#set-maximum-artifacts-size}

저장소 사용을 제어하기 위해 작업 아티팩트에 대한 크기 한도를 설정합니다. 작업의 각 아티팩트 파일은 기본 최대 크기가 100MB입니다.

`artifacts:reports` 로 정의된 작업 아티팩트는 [다른 한도](../cicd/limits.md#maximum-file-size-per-type-of-artifact)를 가질 수 있습니다. 다른 한도가 적용되면 더 작은 값이 사용됩니다.

> [!note]
> 이 설정은 작업의 개별 파일이 아닌 최종 아카이브 파일의 크기에 적용됩니다.

아티팩트 크기 한도를 다음에 대해 구성할 수 있습니다:

- 인스턴스:  모든 프로젝트 및 그룹에 적용되는 기본 설정입니다.
- 그룹:  그룹의 모든 프로젝트에 대해 인스턴스 설정을 무시합니다.
- 프로젝트:  특정 프로젝트에 대해 인스턴스 및 그룹 설정을 모두 무시합니다.

GitLab.com 한도는 [아티팩트 최대 크기](../../user/gitlab_com/_index.md#cicd)를 참조하세요.

인스턴스의 최대 아티팩트 크기를 변경하려면:

1. **최대 아티팩트 크기(MB)** 텍스트 상자에 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

그룹 또는 프로젝트의 최대 아티팩트 크기를 변경하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하여 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **일반 파이프라인**을 확장합니다.
1. **최대 아티팩트 크기** 값을 변경합니다(MB 단위).
1. **변경 사항 저장**을 선택합니다.

#### 기본 아티팩트 만료 설정 {#set-default-artifacts-expiration}

작업 아티팩트가 자동으로 삭제되기 전에 유지되는 기간을 설정합니다. 기본 만료 시간은 30일입니다.

기간의 구문은 [`artifacts:expire_in`](../../ci/yaml/_index.md#artifactsexpire_in)에 설명되어 있습니다. 개별 작업 정의는 프로젝트의 `.gitlab-ci.yml` 파일에서 이 기본값을 재정의할 수 있습니다.

이 설정에 대한 변경 사항은 새 아티팩트에만 적용됩니다. 기존 아티팩트는 원래 만료 시간을 유지합니다. 이전 아티팩트를 수동으로 만료하는 방법에 대한 정보는 [문제 해결 설명서](../cicd/job_artifacts_troubleshooting.md#delete-old-builds-and-artifacts)를 참조하세요.

작업 아티팩트의 기본 만료 시간을 설정하려면:

1. **기본 아티팩트 만료** 텍스트 상자에 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

#### 최신 성공한 파이프라인에서 아티팩트 유지 {#keep-artifacts-from-latest-successful-pipelines}

각 Git ref(브랜치 또는 태그)에 대해 가장 최근의 성공한 파이프라인에서 아티팩트를 유지하고, 만료 시간에 관계없이 보존합니다.

기본적으로 이 설정은 켜져 있습니다.

이 설정은 [프로젝트 설정](../../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)보다 우선합니다. 인스턴스에서 비활성화하면 개별 프로젝트에 대해 활성화할 수 없습니다.

이 기능이 비활성화되면 기존의 보존된 아티팩트가 즉시 만료되지 않습니다. 새로운 성공한 파이프라인이 브랜치에서 실행되어야 아티팩트가 만료될 수 있습니다.

> [!note]
> 모든 애플리케이션 설정에는 [사용자 지정 가능한 캐시 만료 간격](../application_settings_cache.md)이 있으며, 이는 설정 변경의 영향을 지연시킬 수 있습니다.

최신 성공한 파이프라인에서 아티팩트를 유지하려면:

1. **최근 성공한 파이프라인의 모든 작업에 대한 최신 아티팩트 유지** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

만료 설정에 따라 아티팩트가 만료되도록 허용하려면 대신 확인란을 선택 취소합니다.

#### 외부 리디렉션 경고 페이지 표시 또는 숨기기 {#display-or-hide-the-external-redirect-warning-page}

사용자가 GitLab Pages를 통해 작업 아티팩트를 볼 때 경고 페이지를 표시할지 여부를 제어합니다. 이 경고는 사용자 생성 콘텐츠의 잠재적 보안 위험에 대해 알립니다.

외부 리디렉션 경고 페이지는 기본적으로 표시됩니다. 숨기려면:

1. **Enable the external redirect page for job artifacts** 확인란을 선택 취소합니다.
1. **변경 사항 저장**을 선택합니다.

### 파이프라인 {#pipelines}

#### 파이프라인 아카이빙 {#archive-pipelines}

지정된 기간이 지난 후 이전 파이프라인 및 모든 작업을 자동으로 아카이빙합니다. 아카이빙된 작업:

- 작업 로그 상단에 정보 공지 **This job is archived**을 표시합니다.
- 다시 실행하거나 다시 시도할 수 없습니다.
- 환경이 자동으로 중지될 때 [중지 배포 작업](../../ci/environments/_index.md#stopping-an-environment)으로 실행할 수 없습니다.
- 계속해서 표시되는 작업 로그를 가집니다.

아카이빙 기간은 파이프라인이 생성된 시간부터 측정됩니다. 최소 1일이어야 합니다. 유효한 기간의 예로는 `15 days`, `1 month`, `2 years`이 있습니다. 이 필드를 비워두면 파이프라인이 자동으로 아카이빙되지 않습니다.

GitLab.com의 경우 [파이프라인 아카이빙](../../user/gitlab_com/_index.md#cicd)을 참조하세요.

작업 아카이빙을 설정하려면:

1. **파이프라인 아카이빙** 텍스트 상자에 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

#### 기본적으로 파이프라인 변수 허용 {#allow-pipeline-variables-by-default}

{{< history >}}

- GitLab 18.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190833)되었습니다.

{{< /history >}}

새 그룹의 새 프로젝트에서 기본적으로 파이프라인 변수를 허용할지 여부를 제어합니다.

비활성화하면 [파이프라인 변수를 사용할 수 있는 기본 역할](../../user/group/access_and_permissions.md#set-the-default-role-that-can-use-pipeline-variables) 설정이 새 그룹에 대해 **아무에게도 허락되지 않음**으로 설정되며, 이는 새 그룹의 새 프로젝트에 계속됩니다. 활성화하면 설정이 대신 **개발자**로 기본값이 설정됩니다.

> [!warning]
> 새 그룹 및 프로젝트에 대해 가장 안전한 기본값을 유지하려면 이 설정을 비활성화로 설정하는 것이 좋습니다.

새 그룹의 모든 새 프로젝트에서 기본적으로 파이프라인 변수를 허용하려면:

1. **Allow pipeline variables by default in new groups** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

그룹 또는 프로젝트를 생성한 후 유지보수자는 다른 설정을 선택할 수 있습니다.

#### 기본적으로 CI/CD 변수 보호 {#protect-cicd-variables-by-default}

프로젝트 및 그룹의 모든 새 CI/CD 변수를 기본적으로 보호되도록 설정합니다. 보호된 변수는 보호된 브랜치 또는 보호된 태그에서 실행되는 파이프라인에만 사용 가능합니다.

모든 새 CI/CD 변수를 기본적으로 보호하려면:

1. **기본적으로 CI/CD 변수 보호** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

#### 최대 포함 설정 {#set-maximum-includes}

{{< history >}}

- GitLab 16.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/207270)되었습니다.

{{< /history >}}

[`include` 키워드](../../ci/yaml/includes.md)를 사용하여 파이프라인이 포함할 수 있는 외부 YAML 파일의 수를 제한합니다. 이 한도는 파이프라인이 너무 많은 파일을 포함할 때 성능 이슈를 방지합니다.

기본적으로 파이프라인은 최대 150개 파일을 포함할 수 있습니다. 파이프라인이 이 한도를 초과하면 오류가 발생하고 실패합니다.

파이프라인당 포함된 파일의 최대 수를 설정하려면:

1. **최대 포함** 텍스트 상자에 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

#### 다운스트림 파이프라인 트리거 속도 제한 {#limit-downstream-pipeline-trigger-rate}

{{< history >}}

- GitLab 16.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144077)되었습니다.

{{< /history >}}

단일 소스에서 분당 트리거될 수 있는 [다운스트림 파이프라인](../../ci/pipelines/downstream_pipelines.md)의 수를 제한합니다.

최대 다운스트림 파이프라인 트리거 속도는 프로젝트, 사용자 및 커밋의 주어진 조합에 대해 분당 트리거될 수 있는 다운스트림 파이프라인의 수를 제한합니다. 기본값은 `0`이며, 이는 제한이 없음을 의미합니다.

#### 기본 CI/CD 구성 파일 지정 {#specify-a-default-cicd-configuration-file}

모든 새 프로젝트에서 CI/CD 구성 파일의 기본값으로 사용할 사용자 지정 경로 및 파일 이름을 설정합니다. 기본적으로 GitLab은 프로젝트의 루트 디렉터리에서 `.gitlab-ci.yml` 파일을 사용합니다.

이 설정은 변경한 후 생성된 새 프로젝트에만 적용됩니다. 기존 프로젝트는 현재 CI/CD 구성 파일 경로를 계속 사용합니다.

사용자 지정 기본 CI/CD 구성 파일 경로를 설정하려면:

1. **기본 CI/CD 구성 파일** 텍스트 상자에 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

개별 프로젝트는 [사용자 지정 CI/CD 구성 파일 지정](../../ci/pipelines/settings.md#specify-a-custom-cicd-configuration-file)으로 이 인스턴스 기본값을 재정의할 수 있습니다.

#### 파이프라인 제안 배너 표시 또는 숨기기 {#display-or-hide-the-pipeline-suggestion-banner}

파이프라인이 없는 머지 리퀘스트에 지침 배너를 표시할지 여부를 제어합니다. 이 배너는 `.gitlab-ci.yml` 파일을 추가하는 방법에 대한 설명을 제공합니다.

![배너는 GitLab 파이프라인을 시작하는 방법에 대한 지침을 표시합니다.](img/suggest_pipeline_banner_v14_5.png)

파이프라인 제안 배너는 기본적으로 표시됩니다. 숨기려면:

1. **파이프라인 제안 배너 활성화** 확인란을 선택 취소합니다.
1. **변경 사항 저장**을 선택합니다.

#### Jenkins 마이그레이션 배너 표시 또는 숨기기 {#display-or-hide-the-jenkins-migration-banner}

{{< history >}}

- GitLab 17.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/470025)되었습니다.

{{< /history >}}

Jenkins에서 GitLab CI/CD로의 마이그레이션을 권장하는 배너를 표시할지 여부를 제어합니다. 이 배너는 [Jenkins 통합이 활성화](../../integration/jenkins.md)된 프로젝트의 머지 리퀘스트에 표시됩니다.

![Jenkins에서 GitLab CI로의 마이그레이션을 촉구하는 배너](img/suggest_migrate_from_jenkins_v17_7.png)

Jenkins 마이그레이션 배너는 기본적으로 표시됩니다. 숨기려면:

1. **Jenkins 배너에서 마이그레이션 표시** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 패키지 레지스트리 설정 액세스 {#access-package-registry-settings}

NuGet 패키지 유효성 검증, Helm 패키지 한도, 패키지 파일 크기 한도 및 패키지 전달을 구성합니다.

이 설정에 액세스하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **패키지 레지스트리**를 확장합니다.

### NuGet 패키지 메타데이터 URL 유효성 검증 생략 {#skip-nuget-package-metadata-url-validation}

NuGet 패키지의 `projectUrl`, `iconUrl` 및 `licenseUrl` 메타데이터 유효성 검증을 생략합니다.

기본적으로 GitLab은 이 URL을 유효성 검증합니다. GitLab 인스턴스에 인터넷 액세스가 없으면 이 유효성 검증이 실패하고 NuGet 패키지 업로드가 방지됩니다.

NuGet 패키지 메타데이터 URL 유효성 검증을 생략하려면:

1. **NuGet 패키지에 대한 메타데이터 URL 유효성 검증 생략** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### 채널당 최대 Helm 패키지 설정 {#set-maximum-helm-packages-per-channel}

채널당 나열할 수 있는 최대 Helm 패키지 수를 설정합니다.

Helm 패키지 한도를 설정하려면:

1. **패키지 한도** 아래에서 **채널당 Helm 패키지의 최대 수** 필드에 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

### 패키지 파일 크기 한도 설정 {#set-package-file-size-limits}

저장소 사용을 제어하고 시스템 성능을 유지하기 위해 각 패키지 유형에 대한 최대 파일 크기 한도를 설정합니다.

다음 패키지에 대한 최대 파일 크기 한도를 구성할 수 있습니다(바이트 단위):

- Conan 패키지
- Helm 차트
- Maven 패키지
- npm 패키지
- NuGet 패키지
- PyPI 패키지
- Terraform 모듈 패키지
- 제네릭 패키지

패키지 파일 크기 한도를 구성하려면:

1. **패키지 파일 크기 제한** 아래에서 구성할 한도에 대한 값을 입력합니다.
1. **Save size limits**을 선택합니다.

### 패키지 전달 제어 {#control-package-forwarding}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab 패키지 레지스트리에서 패키지를 찾을 수 없을 때 패키지 요청을 공개 레지스트리로 전달할지 여부를 제어합니다.

기본적으로 GitLab은 패키지 요청을 해당 공개 레지스트리로 전달합니다:

- Maven 요청은 [Maven Central](https://search.maven.org/)로 전달됩니다.
- npm 요청은 [npmjs.com](https://www.npmjs.com/)으로 전달됩니다.
- PyPI 요청은 [pypi.org](https://pypi.org/)로 전달됩니다.

패키지 전달을 끄려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **그룹**을 선택하여 그룹을 찾습니다.
1. **설정** > **CI/CD**를 선택합니다.
1. **패키지 레지스트리**를 확장합니다.
1. 다음 확인란 중 하나를 선택 취소합니다:
   - **Forward npm package requests**
   - **Forward PyPI package requests**
1. **변경 사항 저장**을 선택합니다.

Maven 패키지에 대한 요청 전달을 끄려면 [패키지 레지스트리의 Maven 패키지](../../user/packages/maven_repository/_index.md#request-forwarding-to-maven-central)를 참조하세요.

## 러너 설정 액세스 {#access-runner-settings}

러너 버전 관리 및 등록 설정을 구성합니다.

이 설정에 액세스하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.

### 러너 버전 관리 제어 {#control-runner-version-management}

인스턴스가 GitLab.com에서 공식 러너 버전 데이터를 가져와 [러너가 업그레이드되어야 하는지 확인](../../ci/runners/runners_scope.md#determine-which-runners-need-to-be-upgraded)하는지 여부를 제어합니다.

기본적으로 GitLab은 러너 버전 데이터를 가져옵니다. 이 데이터 가져오기를 중지하려면:

1. **러너 버전 관리** 아래에서 **GitLab.com에서 러너 릴리스 버전 데이터 가져오기** 확인란을 선택 취소합니다.
1. **변경 사항 저장**을 선택합니다.

### 러너 등록 제어 {#control-runner-registration}

{{< history >}}

- **러너 등록 토큰 허용** 설정이 GitLab 16.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147559)되었습니다.

{{< /history >}}

러너를 등록할 수 있는 사람과 등록 토큰을 허용할지 여부를 제어합니다.

> [!warning]
> 러너 등록 토큰을 전달하는 옵션과 특정 구성 인수에 대한 지원은 레거시로 간주되며 권장되지 않습니다. [러너 생성 워크플로우](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)를 사용하여 러너를 등록할 인증 토큰을 생성합니다. 이 프로세스는 러너 소유권의 완전한 추적성을 제공하고 러너 플릿의 보안을 강화합니다.
>
> 자세한 정보는 [새로운 러너 등록 워크플로우로 마이그레이션](../../ci/runners/new_creation_workflow.md)을 참조하세요.

기본적으로 러너 등록 토큰과 프로젝트 및 그룹 구성원 등록이 모두 허용됩니다. 러너 등록을 제한하려면:

1. **러너 등록** 아래에서 다음 확인란 중 하나를 선택 취소합니다:
   - **러너 등록 토큰 허용**
   - **Members of the project can create runners**
   - **Members of the group can create runners**
1. **변경 사항 저장**을 선택합니다.

> [!note]
> 프로젝트 구성원에 대한 러너 등록을 비활성화하면 등록 토큰이 자동으로 회전합니다. 이전 토큰은 유효하지 않으며 프로젝트의 새 등록 토큰을 사용해야 합니다.

### 특정 그룹에 대한 러너 등록 제한 {#restrict-runner-registration-for-a-specific-group}

특정 그룹의 구성원이 러너를 등록할 수 있는지 여부를 제어합니다.

전제 조건:

- **Members of the group can create runners** 확인란이 [러너 등록 설정](#control-runner-registration)에서 선택되어 있어야 합니다.

특정 그룹에 대한 러너 등록을 제한하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **그룹**을 선택하여 그룹을 찾습니다.
1. **편집**을 선택합니다.
1. **러너 등록** 아래에서 **새 그룹 러너 등록 가능** 확인란을 선택 취소합니다.
1. **변경 사항 저장**을 선택합니다.

## 작업 토큰 권한 설정 액세스 {#access-job-token-permission-settings}

CI/CD 작업 토큰이 프로젝트에 액세스하는 방식을 제어합니다.

이 설정에 액세스하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **작업 토큰 권한**을 확장합니다.

### 작업 토큰 허용 목록 적용 {#enforce-job-token-allowlist}

{{< history >}}

- GitLab 17.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/496647)되었습니다.

{{< /history >}}

모든 프로젝트가 허용 목록을 사용하여 작업 토큰 액세스를 제어하도록 합니다.

이 설정이 활성화되면:

- CI/CD 작업 토큰은 토큰의 소스 프로젝트가 허용 목록에 추가되었을 때만 프로젝트에 액세스할 수 있습니다.
- [CI/CD 작업 토큰 범위 API](../../api/project_job_token_scopes.md#update-the-cicd-job-token-access-settings-for-a-project)는 사용자가 허용 목록을 비활성화하려고 시도하면 오류를 반환합니다.

자세한 정보는 [프로젝트에 대한 작업 토큰 액세스 제어](../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project)를 참조하세요.

작업 토큰 허용 목록을 적용하려면:

1. **승인된 그룹 및 프로젝트** 아래에서 **Enable and enforce job token allowlist for all projects** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 작업 로그 설정 액세스 {#access-job-log-settings}

CI/CD 작업 로그가 저장되고 처리되는 방식을 제어합니다.

이 설정에 액세스하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **작업 로그**를 확장합니다.

### 증분 로깅 구성 {#configure-incremental-logging}

{{< history >}}

- 인스턴스 설정이 GitLab 17.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186182)되었으며, `ci_enable_live_trace` [기능 플래그](../feature_flags/_index.md)를 대체합니다.
- `ci_enable_live_trace` 기능 플래그가 GitLab 18.0에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189232)되었습니다.

{{< /history >}}

작업 로그의 임시 캐싱을 위해 Redis를 사용하고 아카이빙된 로그를 객체 저장소에 증분 방식으로 업로드합니다. 이는 성능을 향상시키고 디스크 공간 사용을 줄입니다.

자세한 정보는 [증분 로깅](../cicd/job_logs.md#incremental-logging)을 참조하세요.

전제 조건:

- CI/CD 아티팩트, 로그 및 빌드에 대해 [객체 저장소를 구성](../cicd/job_artifacts.md#using-object-storage)해야 합니다.

모든 프로젝트에 대해 증분 로깅을 켜려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **작업 로그** 섹션을 확장합니다.
1. **Incremental logging configuration** 아래에서 **증분 로그 켜기** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## CI/CD 카탈로그 설정 {#cicd-catalog-settings}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/582044)되었습니다.

{{< /history >}}

[CI/CD 카탈로그](../../ci/components/_index.md)에 구성 요소를 발행할 수 있는 프로젝트를 제어합니다.

이 설정에 액세스하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **Catalog**를 확장합니다.

### CI/CD 카탈로그 발행 제한 {#restrict-cicd-catalog-publishing}

기본적으로 모든 프로젝트가 CI/CD 카탈로그에 구성 요소를 발행할 수 있습니다. 허용 목록을 구성하여 특정 프로젝트에 대한 발행을 제한할 수 있습니다.

허용 목록이 다음과 같을 때:

- 비어 있음(기본값):  모든 프로젝트가 카탈로그에 발행할 수 있습니다.
- 다수의 프로젝트로 채워짐:  허용 목록의 항목과 일치하는 프로젝트만 발행할 수 있습니다.

다음을 사용하여 허용 목록에 항목을 정의할 수 있습니다:

- 정확한 프로젝트 경로(예: `my-group/my-project`).
- 정규식(예:
  - `my-group/.*`: 그룹의 모든 프로젝트.
  - `my-group/security-.*`:  `security-`로 시작하는 프로젝트.

CI/CD 카탈로그 발행 허용 목록을 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **Catalog**를 확장합니다.
1. **CI/CD 카탈로그 발행 허용목록** 텍스트 영역에 한 줄에 하나의 경로 패턴을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

허용 목록에 없는 프로젝트는 구성 요소 버전을 발행하려고 할 때 `not authorized to publish` 오류가 발생합니다.

## 필수 파이프라인 구성(더 이상 사용되지 않음) {#required-pipeline-configuration-deprecated}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.9에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/389467).
- GitLab 17.0에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/389467)됨.
- GitLab 17.4에서 [다시 추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165111) 되었으며 [플래그 포함](../feature_flags/_index.md) `required_pipelines`. 기본적으로 비활성화됨.

{{< /history >}}

> [!warning]
> 이 기능은 GitLab 15.9에서 [더 이상 사용되지 않으며](https://gitlab.com/gitlab-org/gitlab/-/issues/389467) 17.0에서 제거되었습니다. 17.4부터는 기능 플래그 `required_pipelines` 뒤에만 사용 가능하며 기본적으로 비활성화되어 있습니다. 대신 [규정 준수 파이프라인](../../user/compliance/compliance_pipelines.md)을 사용합니다. 이는 주요 변경입니다.

GitLab 인스턴스의 모든 프로젝트에 대한 필수 파이프라인 구성으로 CI/CD 템플릿을 설정할 수 있습니다. 다음에서 템플릿을 사용할 수 있습니다:

- 기본 CI/CD 템플릿.
- [인스턴스 템플릿 리포지토리](instance_template_repository.md)에 저장된 사용자 지정 템플릿.

  > [!note]
  > 인스턴스 템플릿 리포지토리에 정의된 구성을 사용할 때 중첩된 [`include:`](../../ci/yaml/_index.md#include) 키워드(`include:file`, `include:local`, `include:remote`, `include:template` 포함)는 [작동하지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/35345).

파이프라인이 실행될 때 프로젝트 CI/CD 구성이 필수 파이프라인 구성에 병합됩니다. 병합된 구성은 필수 파이프라인 구성이 [`include` 키워드](../../ci/yaml/_index.md#include)로 프로젝트 구성을 추가한 것과 동일합니다. 프로젝트의 전체 병합된 구성을 보려면 파이프라인 편집기에서 [전체 구성 보기](../../ci/pipeline_editor/_index.md#view-full-configuration)를 선택합니다.

필수 파이프라인 구성에 대한 CI/CD 템플릿을 선택하려면:

1. 왼쪽 사이드바 맨 아래에서 **Admin**을 선택합니다.
1. **설정** > **CI/CD**를 선택합니다.
1. **필수 파이프라인 구성** 섹션을 확장합니다.
1. 드롭다운 목록에서 CI/CD 템플릿을 선택합니다.
1. **변경 사항 저장**을 선택합니다.
