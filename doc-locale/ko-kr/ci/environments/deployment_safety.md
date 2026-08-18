---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 배포 안정성
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[배포 작업](../jobs/_index.md#deployment-jobs)은 특정한 유형의 CI/CD 작업입니다. 배포 작업은 파이프라인의 다른 작업보다 더 민감할 수 있으며 특별한 주의가 필요할 수 있습니다. GitLab은 배포 보안과 안정성을 유지하는 데 도움이 되는 여러 기능을 제공합니다.

다음을 수행할 수 있습니다.

- 프로젝트에 적절한 역할을 설정합니다. [프로젝트 구성원 권한](../../user/permissions.md#project-permissions)을 참조하여 GitLab이 지원하는 다양한 사용자 역할과 각 역할의 권한을 확인합니다.
- [중요한 환경에 대한 쓰기 액세스 제한](#restrict-write-access-to-a-critical-environment)
- [배포 동결 기간 중 배포 방지](#prevent-deployments-during-deploy-freeze-windows)
- [프로덕션 시크릿 보호](#protect-production-secrets)
- [배포용 별도 프로젝트](#separate-project-for-deployments)

지속적 배포 워크플로우를 사용 중이며 동일한 환경에 대한 동시 배포가 발생하지 않도록 하려면 다음을 수행해야 합니다:

- [한 번에 하나의 배포 작업만 실행](#ensure-only-one-deployment-job-runs-at-a-time)
- [오래된 배포 작업 방지](#prevent-outdated-deployment-jobs)

<i class="fa-youtube-play" aria-hidden="true"></i> 개요는 [CD 파이프라인/워크플로우를 보호하는 방법](https://www.youtube.com/watch?v=Mq3C1KveDc0)을 참조하세요.

## 중요한 환경에 대한 쓰기 액세스 제한 {#restrict-write-access-to-a-critical-environment}

기본적으로 환경은 개발자 역할 이상을 가진 모든 팀 구성원이 수정할 수 있습니다. 중요한 환경(예: `production` 환경)에 대한 쓰기 액세스를 제한하려면 [보호 환경](protected_environments.md)을 설정할 수 있습니다.

## 한 번에 하나의 배포 작업만 실행 {#ensure-only-one-deployment-job-runs-at-a-time}

GitLab CI/CD의 파이프라인 작업은 병렬로 실행되므로 두 개의 서로 다른 파이프라인에 있는 두 개의 배포 작업이 동일한 환경에 동시에 배포하려고 시도할 수 있습니다. 배포는 순차적으로 진행되어야 하므로 이는 바람직하지 않은 동작입니다.

`.gitlab-ci.yml`에서 [`resource_group` 키워드](../yaml/_index.md#resource_group)를 사용하여 한 번에 하나의 배포 작업만 실행되도록 보장할 수 있습니다.

예를 들어:

```yaml
deploy:
 script: deploy-to-prod
 resource_group: prod
```

리소스 그룹 없이 문제가 있는 파이프라인 플로우의 예:

1. 파이프라인-A의 `deploy` 작업이 실행을 시작합니다.
1. 파이프라인-B의 `deploy` 작업이 실행을 시작합니다. *이는 예기치 않은 결과를 초래할 수 있는 동시 배포입니다.*
1. 파이프라인-A의 `deploy` 작업이 완료됩니다.
1. 파이프라인-B의 `deploy` 작업이 완료됩니다.

리소스 그룹이 포함된 개선된 파이프라인 플로우:

1. 파이프라인-A의 `deploy` 작업이 실행을 시작합니다.
1. 파이프라인-B의 `deploy` 작업이 시작하려고 하지만 첫 번째 `deploy` 작업이 완료될 때까지 대기합니다.
1. 파이프라인-A의 `deploy` 작업이 완료됩니다.
1. 파이프라인-B의 `deploy` 작업이 실행을 시작합니다.

자세한 정보는 [리소스 그룹 문서](../resource_groups/_index.md)를 참조하세요.

## 오래된 배포 작업 방지 {#prevent-outdated-deployment-jobs}

{{< history >}}

- GitLab 15.5에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/363328)되었으며 오래된 작업 실행을 방지합니다.

{{< /history >}}

파이프라인 작업의 실행 순서는 실행할 때마다 달라질 수 있으며 이는 바람직하지 않은 동작을 초래할 수 있습니다. 예를 들어 새로운 파이프라인의 [배포 작업](../jobs/_index.md#deployment-jobs)이 오래된 파이프라인의 배포 작업보다 먼저 완료될 수 있습니다. 이는 오래된 배포가 나중에 완료되어 "새로운" 배포를 덮어쓰는 경합 조건을 만듭니다.

[**오래된 배포 작업 방지**](../pipelines/settings.md#prevent-outdated-deployment-jobs) 설정을 사용하여 새로운 배포 작업이 시작될 때 오래된 배포 작업이 실행되지 않도록 할 수 있습니다.

오래된 배포 작업이 시작되면 실패하고 다음과 같이 레이블이 지정됩니다:

- 파이프라인 보기에서 `failed outdated deployment job`.
- 완료된 작업을 볼 때 `The deployment job is older than the latest deployment, and therefore failed.`.

오래된 배포 작업이 수동인 경우 **실행** ({{< icon name="play" >}}) 버튼은 `This deployment job does not run automatically and must be started manually, but it's older than the latest deployment, and therefore can't run.` 메시지와 함께 비활성화됩니다.

작업 나이는 커밋 시간이 아닌 작업 시작 시간으로 결정되므로 새로운 커밋이 경우에 따라 방지될 수 있습니다. 예를 들어 파이프라인 A(오래된 커밋)와 파이프라인 B(새로운 커밋)는 모두 수동 배포 작업을 가지고 있습니다. Pipeline B를 생성한 후 Pipeline A의 작업을 시작하면 파이프라인 자체가 더 최신이지만 Pipeline B의 수동 배포 작업은 오래된 것으로 차단됩니다.

### 배포 롤백을 위한 작업 재시도 {#job-retries-for-rollback-deployments}

{{< history >}}

- 작업 재시도를 통한 롤백이 GitLab 15.6에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/378359)되었습니다.
- 배포 롤백을 위한 작업 재시도 체크박스가 GitLab 16.3에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/410427)되었습니다.

{{< /history >}}

안정적이고 오래된 배포로 빠르게 롤백해야 할 수도 있습니다. 기본적으로 [배포 롤백](deployments.md#deployment-rollback)을 위한 파이프라인 작업 재시도는 활성화되어 있습니다.

파이프라인 재시도를 비활성화하려면 **배포 롤백을 위한 작업 재시도 허용** 체크박스를 선택 해제합니다. 민감한 프로젝트에서는 파이프라인 재시도를 비활성화해야 합니다.

롤백이 필요한 경우 이전 커밋을 사용하여 새 파이프라인을 실행해야 합니다.

### 예 {#example}

**오래된 배포 작업 방지** 설정이 비활성화된 경우 문제가 있는 파이프라인 플로우의 예:

1. 파이프라인-A가 기본 브랜치에서 생성됩니다.
1. 나중에 파이프라인-B가 기본 브랜치에서 생성됩니다(새로운 커밋 SHA 포함).
1. 파이프라인-B의 `deploy` 작업이 먼저 완료되고 새로운 코드를 배포합니다.
1. 파이프라인-A의 `deploy` 작업이 나중에 완료되고 오래된 코드를 배포하여 새로운(최신) 배포를 **덮어씁니다**.

설정이 활성화된 경우 개선된 파이프라인 플로우:

1. 파이프라인-A가 기본 브랜치에서 생성됩니다.
1. 나중에 파이프라인-B가 기본 브랜치에서 생성됩니다(새로운 SHA 포함).
1. 파이프라인-B의 `deploy` 작업이 먼저 완료되고 새로운 코드를 배포합니다.
1. 파이프라인-A의 `deploy` 작업이 실패하므로 최신 파이프라인의 배포를 덮어쓰지 않습니다.

## 배포 동결 기간 중 배포 방지 {#prevent-deployments-during-deploy-freeze-windows}

특정 기간(예: 대부분의 직원이 부재중인 계획된 휴가 기간) 동안 배포를 방지하려면 [배포 동결](../../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze)을 설정할 수 있습니다. 배포 동결 기간 동안 배포를 실행할 수 없습니다. 이는 배포가 예기치 않게 발생하지 않도록 보장하는 데 도움이 됩니다.

다음으로 구성된 배포 동결이 [환경 배포 목록](_index.md#view-environments-and-deployments) 페이지의 맨 위에 표시됩니다.

## 프로덕션 시크릿 보호 {#protect-production-secrets}

프로덕션 시크릿은 성공적으로 배포하기 위해 필요합니다. 예를 들어 클라우드에 배포할 때 클라우드 제공자는 서비스에 연결하기 위해 이러한 시크릿이 필요합니다. 프로젝트 설정에서 이러한 시크릿에 대한 CI/CD 변수를 정의하고 보호할 수 있습니다. [보호된 변수](../variables/_index.md#protect-a-cicd-variable)는 [보호된 브랜치](../../user/project/repository/branches/protected.md) 또는 [보호된 태그](../../user/project/protected_tags.md)에서 실행 중인 파이프라인에만 전달됩니다. 다른 파이프라인은 보호된 변수를 얻지 못합니다. [변수를 특정 환경으로 범위 지정](../variables/where_variables_can_be_used.md#variables-with-an-environment-scope)할 수도 있습니다. 시크릿이 의도치 않게 노출되지 않도록 보호 환경에서 보호된 변수를 사용할 것을 권장합니다. [러너 측](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information)에서 프로덕션 시크릿을 정의할 수도 있습니다. 이렇게 하면 관리자 역할을 가진 다른 사용자가 시크릿을 읽지 못하도록 방지하고 러너가 보호된 브랜치에서만 실행되도록 합니다.

자세한 정보는 [파이프라인 보안](../pipelines/_index.md#pipeline-security-on-protected-branches)을 참조하세요.

## 배포용 별도 프로젝트 {#separate-project-for-deployments}

프로젝트에 대한 관리자 역할을 가진 모든 사용자는 프로덕션 시크릿에 액세스할 수 있습니다. 프로덕션 환경에 배포할 수 있는 사용자 수를 제한해야 하는 경우 별도의 프로젝트를 만들고 새로운 권한 모델을 구성하여 CD 권한을 원래 프로젝트에서 격리하고 원래 프로젝트에 대한 관리자 역할을 가진 원래 사용자가 프로덕션 시크릿 및 CD 구성에 액세스하지 못하도록 할 수 있습니다. [다중 프로젝트 파이프라인](../pipelines/downstream_pipelines.md#multi-project-pipelines)을 사용하여 CD 프로젝트를 개발 프로젝트에 연결할 수 있습니다.

## `.gitlab-ci.yml`의 변경 방지 {#protect-gitlab-ciyml-from-change}

`.gitlab-ci.yml`에 프로덕션 서버에 애플리케이션을 배포하기 위한 규칙이 포함될 수 있습니다. 이 배포는 일반적으로 머지 리퀘스트를 푸시한 후에 자동으로 실행됩니다. 개발자가 `.gitlab-ci.yml`를 변경하지 못하도록 하려면 다른 리포지토리에서 이를 정의할 수 있습니다. 구성은 완전히 다른 권한 집합을 가진 다른 프로젝트의 파일을 참조할 수 있습니다([배포를 위한 프로젝트 분리](#separate-project-for-deployments)와 유사). 이 시나리오에서 `.gitlab-ci.yml`은 공개적으로 액세스 가능하지만 다른 프로젝트에서 적절한 권한을 가진 사용자만 편집할 수 있습니다.

자세한 정보는 [사용자 지정 CI/CD 구성 경로](../pipelines/settings.md#specify-a-custom-cicd-configuration-file)를 참조하세요.

## 배포 전에 승인 필요 {#require-an-approval-before-deploying}

배포를 프로덕션 환경으로 올리기 전에 전담 테스트 그룹과 교차 검증하는 것이 안전을 보장하는 효과적인 방법입니다. 자세한 정보는 [배포 승인](deployment_approvals.md)을 참조하세요.
