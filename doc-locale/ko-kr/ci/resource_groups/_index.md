---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab CI/CD에서 작업 동시성 제어
title: 리소스 그룹
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

기본적으로 GitLab CI/CD의 파이프라인은 동시에 실행됩니다. 동시성은 머지 리퀘스트의 피드백 루프를 개선하는 중요한 요소이지만, 배포 작업의 동시성을 제한하여 작업을 하나씩 실행하고 싶은 경우가 있습니다. 리소스 그룹을 사용하여 작업 동시성을 전략적으로 제어하고 지속적 배포 워크플로우를 안전하게 최적화하세요.

## 리소스 그룹 추가 {#add-a-resource-group}

리소스 그룹에는 하나의 리소스만 추가할 수 있습니다.

다음 파이프라인 구성(리포지토리의 `.gitlab-ci.yml` 파일)이 있다고 가정하세요:

```yaml
build:
  stage: build
  script: echo "Your build script"

deploy:
  stage: deploy
  script: echo "Your deployment script"
  environment: production
```

브랜치에 새로운 커밋을 푸시할 때마다 `build`과 `deploy`의 두 작업을 포함하는 새로운 파이프라인이 실행됩니다. 하지만 짧은 시간 내에 여러 커밋을 푸시하면 여러 파이프라인이 동시에 실행되기 시작합니다. 예를 들어:

- 첫 번째 파이프라인은 `build` -> `deploy` 작업을 실행합니다.
- 두 번째 파이프라인은 `build` -> `deploy` 작업을 실행합니다.

이 경우 서로 다른 파이프라인 간의 `deploy` 작업이 `production` 환경에 동시에 실행될 수 있습니다. 동일한 인프라에 여러 배포 스크립트를 실행하면 인스턴스에 해를 끼치거나 혼동을 야기할 수 있으며, 최악의 경우 손상된 상태로 남길 수 있습니다.

`deploy` 작업이 한 번에 하나씩 실행되도록 하려면 동시성에 민감한 작업에 [`resource_group` 키워드](../yaml/_index.md#resource_group)를 지정할 수 있습니다:

```yaml
deploy:
  # ...
  resource_group: production
```

이 구성을 사용하면 배포 안전성이 보장되면서도 `build` 작업을 동시에 실행하여 파이프라인 효율성을 최대화할 수 있습니다.

## 전제 조건 {#prerequisites}

- [GitLab CI/CD 파이프라인](../pipelines/_index.md) 숙지
- [GitLab 환경 및 배포](../environments/_index.md) 숙지
- CI/CD 파이프라인을 구성하기 위한 프로젝트의 Developer, Maintainer 또는 Owner 역할

## 프로세스 모드 {#process-modes}

배포 기본 설정에 따라 작업 동시성을 제어하는 프로세스 모드를 선택할 수 있습니다. 다음 모드가 지원됩니다:

| 프로세스 모드 | 설명 | 사용 시기  |
|---------------|-------------|-------------|
| `unordered` | 기본 프로세스 모드입니다. 작업이 실행 준비가 되면 언제든 작업을 처리합니다. | 작업 실행 순서는 중요하지 않습니다. 사용하기 가장 간단한 옵션입니다. |
| `oldest_first` | 리소스가 자유로워지면 파이프라인 ID를 오름차순으로 정렬한 예정된 작업 목록에서 첫 번째 작업을 선택합니다. | 가장 오래된 파이프라인에서 작업을 먼저 실행하려고 합니다. `unordered` 모드보다 효율성은 낮지만 지속적 배포에는 더 안전합니다. |
| `newest_first` | 리소스가 자유로워지면 파이프라인 ID를 내림차순으로 정렬한 예정된 작업 목록에서 첫 번째 작업을 선택합니다. | 최신 파이프라인에서 작업을 실행하고 [오래된 배포 작업 방지](../environments/deployment_safety.md#prevent-outdated-deployment-jobs)를 원합니다. 각 작업은 멱등성을 가져야 합니다. |
| `newest_ready_first` | 리소스가 자유로워지면 이 리소스에서 대기 중인 예정된 작업 목록에서 첫 번째 작업을 선택합니다. 작업은 파이프라인 ID를 내림차순으로 정렬합니다. | `newest_first`이 현재 파이프라인을 배포하기 전에 새로운 파이프라인을 우선 처리하는 것을 방지하려고 합니다. `newest_first`보다 빠릅니다. 각 작업은 멱등성을 가져야 합니다. |

### 프로세스 모드 변경 {#change-the-process-mode}

리소스 그룹의 프로세스 모드를 변경하려면 API를 사용하고 `process_mode`를 지정하여 [기존 리소스 그룹 편집](../../api/resource_groups.md#update-a-resource-group)에 요청을 보내야 합니다:

- `unordered`
- `oldest_first`
- `newest_first`
- `newest_ready_first`

### 프로세스 모드 간의 차이점 예시 {#an-example-of-difference-between-the-process-modes}

다음 `.gitlab-ci.yml`을 고려하세요. 이는 `build` 작업과 `deploy` 작업을 포함합니다. 각 작업은 자신의 스테이지에서 실행되며 `deploy` 작업에는 `production`로 설정된 리소스 그룹이 있습니다:

```yaml
build:
  stage: build
  script: echo "Your build script"

deploy:
  stage: deploy
  script: echo "Your deployment script"
  environment: production
  resource_group: production
```

짧은 시간 내에 프로젝트에 3개의 커밋이 푸시되면 거의 동시에 3개의 파이프라인이 실행된다는 의미입니다:

- 첫 번째 파이프라인은 `build` -> `deploy` 작업을 실행합니다. 이 배포 작업을 `deploy-1`이라고 부르겠습니다.
- 두 번째 파이프라인은 `build` -> `deploy` 작업을 실행합니다. 이 배포 작업을 `deploy-2`이라고 부르겠습니다.
- 세 번째 파이프라인은 `build` -> `deploy` 작업을 실행합니다. 이 배포 작업을 `deploy-3`이라고 부르겠습니다.

리소스 그룹의 프로세스 모드에 따라:

- 프로세스 모드가 `unordered`로 설정되어 있으면:
  - `deploy-1`, `deploy-2` 및 `deploy-3`은 동시에 실행되지 않습니다.
  - 작업 실행 순서에 대한 보장이 없습니다. 예를 들어 `deploy-1`은 `deploy-3`이 실행되기 전이나 후에 실행될 수 있습니다.
- 프로세스 모드가 `oldest_first`이면:
  - `deploy-1`, `deploy-2` 및 `deploy-3`은 동시에 실행되지 않습니다.
  - `deploy-1`이 먼저 실행되고, `deploy-2`이 두 번째로 실행되며, `deploy-3`이 마지막으로 실행됩니다.
- 프로세스 모드가 `newest_first`이면:
  - `deploy-1`, `deploy-2` 및 `deploy-3`은 동시에 실행되지 않습니다.
  - `deploy-3`이 먼저 실행되고, `deploy-2`이 두 번째로 실행되며, `deploy-1`이 마지막으로 실행됩니다.

## 교차 프로젝트/상위-하위 파이프라인을 사용한 파이프라인 수준 동시성 제어 {#pipeline-level-concurrency-control-with-cross-projectparent-child-pipelines}

동시 실행에 민감한 다운스트림 파이프라인에 대해 `resource_group`을 정의할 수 있습니다. [`trigger` 키워드](../yaml/_index.md#trigger)는 다운스트림 파이프라인을 트리거할 수 있으며, [`resource_group` 키워드](../yaml/_index.md#resource_group)는 함께 존재할 수 있습니다. `resource_group`은 배포 파이프라인의 동시성을 제어하는 데 효율적이면서 다른 작업은 계속 동시에 실행될 수 있습니다.

다음 예시에는 프로젝트의 두 파이프라인 구성이 있습니다. 파이프라인이 실행되기 시작하면 민감하지 않은 작업이 먼저 실행되며 다른 파이프라인의 동시 실행에 영향을 받지 않습니다. 그러나 GitLab은 배포(하위) 파이프라인을 트리거하기 전에 다른 배포 파이프라인이 실행되지 않도록 합니다. 다른 배포 파이프라인이 실행 중이면 GitLab은 해당 파이프라인이 완료될 때까지 기다렸다가 다른 파이프라인을 실행합니다.

```yaml
# .gitlab-ci.yml (parent pipeline)

build:
  stage: build
  script: echo "Building..."

test:
  stage: test
  script: echo "Testing..."

deploy:
  stage: deploy
  trigger:
    include: deploy.gitlab-ci.yml
    strategy: mirror
  resource_group: AWS-production
```

```yaml
# deploy.gitlab-ci.yml (child pipeline)

stages:
  - provision
  - deploy

provision:
  stage: provision
  script: echo "Provisioning..."

deployment:
  stage: deploy
  script: echo "Deploying..."
  environment: production
```

다운스트림 파이프라인이 완료될 때까지 잠금이 해제되지 않도록 [`trigger:strategy`](../yaml/_index.md#triggerstrategy)를 정의해야 합니다.

## 관련 항목 {#related-topics}

- [API 문서](../../api/resource_groups.md)
- [로그 문서](../../administration/logs/_index.md#ci_resource_groups_jsonlog)
- [안전한 배포를 위한 GitLab](../environments/deployment_safety.md)

## 문제 해결 {#troubleshooting}

### 파이프라인 구성에서 교착 상태 방지 {#avoid-dead-locks-in-pipeline-configurations}

[`oldest_first` 프로세스 모드](#process-modes)는 작업을 파이프라인 순서에 따라 실행하도록 강제하므로, 다른 CI 기능과 잘 작동하지 않는 경우가 있습니다.

예를 들어 부모 파이프라인과 동일한 리소스 그룹이 필요한 [하위 파이프라인](../pipelines/downstream_pipelines.md#parent-child-pipelines)을 실행할 때 교착 상태가 발생할 수 있습니다. 다음은 나쁜 설정의 예시입니다:

```yaml
# BAD
test:
  stage: test
  trigger:
    include: child-pipeline-requires-production-resource-group.yml
    strategy: mirror

deploy:
  stage: deploy
  script: echo
  resource_group: production
  environment: production
```

부모 파이프라인에서 `test` 작업을 실행하고 이어서 하위 파이프라인을 실행하며, [`strategy: mirror` 옵션](../yaml/_index.md#triggerstrategy)은 `test` 작업이 하위 파이프라인이 완료될 때까지 기다리도록 합니다. 부모 파이프라인은 다음 스테이지에서 `deploy` 작업을 실행하며, 이는 `production` 리소스 그룹에서 리소스가 필요합니다. 프로세스 모드가 `oldest_first`이면 가장 오래된 파이프라인에서 작업을 실행하며, 이는 `deploy` 작업이 다음에 실행됨을 의미합니다.

그러나 하위 파이프라인도 `production` 리소스 그룹에서 리소스가 필요합니다. 하위 파이프라인이 부모 파이프라인보다 최신이므로, 하위 파이프라인은 `deploy` 작업이 완료될 때까지 기다리며, 이는 절대 발생하지 않습니다.

이 경우 부모 파이프라인 구성에서 `resource_group` 키워드를 지정해야 합니다:

```yaml
# GOOD
test:
  stage: test
  trigger:
    include: child-pipeline.yml
    strategy: mirror
  resource_group: production # Specify the resource group in the parent pipeline

deploy:
  stage: deploy
  script: echo
  resource_group: production
  environment: production
```

### 작업이 `Waiting for resource`에서 고착됨 {#jobs-get-stuck-in-waiting-for-resource}

때때로 작업이 `Waiting for resource: <resource_group>` 메시지로 행(hang)합니다. 해결하려면 먼저 리소스 그룹이 올바르게 작동하는지 확인하세요:

1. 작업 세부 정보 페이지로 이동하세요.
1. 리소스가 작업에 할당된 경우 **현재 리소스를 사용 중인 작업 보기**를 선택하고 작업 상태를 확인하세요.

   - 상태가 `running` 또는 `pending`이면 기능이 올바르게 작동합니다. 작업이 완료되고 리소스를 릴리스할 때까지 기다리세요.
   - 상태가 `created`이고 [프로세스 모드](#process-modes)가 **가장 오래된 것부터** 또는 **최신순**이면 기능이 올바르게 작동합니다. 작업의 파이프라인 페이지를 방문하고 어느 상위 스테이지 또는 작업이 실행을 차단하는지 확인하세요.
   - 위의 조건 중 하나도 충족되지 않으면 기능이 올바르게 작동하지 않을 수 있습니다. [GitLab에 이슈를 보고](#report-an-issue)하세요.

1. **현재 리소스를 사용 중인 작업 보기**를 사용할 수 없으면 리소스가 작업에 할당되지 않습니다. 대신 리소스의 예정된 작업을 확인하세요.

   1. [REST API](../../api/resource_groups.md#list-upcoming-jobs-for-a-specific-resource-group)를 사용하여 리소스의 예정된 작업을 가져오세요.
   1. 리소스 그룹의 [프로세스 모드](#process-modes)가 **가장 오래된 것부터**인지 확인하세요.
   1. 예정된 작업 목록에서 첫 번째 작업을 찾고, [GraphQL을 사용하여](#get-job-details-through-graphql) 작업 세부 정보를 가져오세요.
   1. 첫 번째 작업의 파이프라인이 더 오래된 파이프라인이면 파이프라인 또는 작업 자체를 취소하려고 시도하세요.
   1. 선택 사항. 다음 예정된 작업이 여전히 더 이상 실행되지 않아야 하는 더 오래된 파이프라인에 있으면 이 프로세스를 반복하세요.
   1. 이슈가 계속되면 [GitLab에 이슈를 보고](#report-an-issue)하세요.

#### 복잡하거나 바쁜 파이프라인의 경합 상태 {#race-conditions-in-complex-or-busy-pipelines}

위의 솔루션으로 이슈를 해결할 수 없으면 알려진 경합 상태 이슈가 발생할 수 있습니다. 경합 상태는 복잡하거나 바쁜 파이프라인에서 발생합니다. 예를 들어 다음이 있는 경우 경합 상태가 발생할 수 있습니다:

- 여러 하위 파이프라인이 있는 파이프라인
- 동시에 여러 파이프라인을 실행하는 단일 프로젝트

이 이슈가 발생할 수 있다고 생각되면 [GitLab에 이슈를 보고](#report-an-issue)하고 [이슈 436988](https://gitlab.com/gitlab-org/gitlab/-/issues/436988)에 새로운 이슈로 연결되는 댓글을 남기세요. 문제를 확인하기 위해 GitLab은 전체 파이프라인 구성과 같은 추가 세부 정보를 요청할 수 있습니다.

임시 해결책으로 다음을 수행할 수 있습니다:

- 새 파이프라인을 시작하세요.
- 고착된 작업과 동일한 리소스 그룹을 가진 완료된 작업을 다시 실행하세요.

  예를 들어 동일한 리소스 그룹을 가진 `setup_job`과 `deploy_job`이 있는 경우 `setup_job`은 완료될 수 있지만 `deploy_job`은 `waiting for resource`에 고착됩니다. `setup_job`을 다시 실행하여 전체 프로세스를 다시 시작하고 `deploy_job`이 완료되도록 하세요.

#### GraphQL을 통한 작업 세부 정보 가져오기 {#get-job-details-through-graphql}

GraphQL API에서 작업 정보를 가져올 수 있습니다. 트리거 작업이 UI에서 접근할 수 없으므로 [교차 프로젝트/상위-하위 파이프라인을 사용한 파이프라인 수준 동시성 제어](#pipeline-level-concurrency-control-with-cross-projectparent-child-pipelines)를 사용하는 경우 GraphQL API를 사용해야 합니다.

GraphQL API에서 작업 정보를 가져오려면:

1. 파이프라인 세부 정보 페이지로 이동합니다.
1. **작업** 탭을 선택하고 고착된 작업의 ID를 찾으세요.
1. [대화형 GraphQL 탐색기](../../api/graphql/_index.md#interactive-graphql-explorer)로 이동합니다.
1. 다음 쿼리를 실행합니다:

   ```graphql
   {
     project(fullPath: "<fullpath-to-your-project>") {
       name
       job(id: "gid://gitlab/Ci::Build/<job-id>") {
         name
         status
         detailedStatus {
           action {
             path
             buttonTitle
           }
         }
       }
     }
   }
   ```

    `job.detailedStatus.action.path` 필드에는 리소스를 사용하고 있는 작업 ID가 포함됩니다.

1. 다음 쿼리를 실행하고 위의 기준에 따라 `job.status` 필드를 확인하세요. `pipeline.path` 필드에서 파이프라인 페이지를 방문할 수도 있습니다.

   ```graphql
   {
     project(fullPath: "<fullpath-to-your-project>") {
       name
       job(id: "gid://gitlab/Ci::Build/<job-id-currently-using-the-resource>") {
         name
         status
         pipeline {
           path
         }
       }
     }
   }
   ```

### 이슈 보고 {#report-an-issue}

다음 정보로 [새 이슈 열기](https://gitlab.com/gitlab-org/gitlab/-/issues/new):

- 영향을 받은 작업의 ID
- 작업 상태
- 문제가 얼마나 자주 발생하는지
- 문제를 재현하는 단계

  추가 지원을 받거나 개발팀에 연락하려면 [지원 팀에 문의](https://support.gitlab.com/hc/en-us/articles/11626483177756-GitLab-Support#contact-support)할 수도 있습니다.
