---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab에서 첫 번째 CI/CD 파이프라인을 구성하고 실행합니다.
title: '튜토리얼: 첫 번째 GitLab CI/CD 파이프라인 만들고 실행하기'
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 튜토리얼은 GitLab에서 첫 번째 CI/CD 파이프라인을 구성하고 실행하는 방법을 보여줍니다.

[기본 CI/CD 개념](../_index.md)에 이미 익숙하다면 [튜토리얼에서 일반적인 키워드를 배울 수 있습니다: 복잡한 파이프라인 만들기](tutorial.md).

## 전제 조건 {#prerequisites}

시작하기 전에 다음을 확인하세요:

- CI/CD를 사용할 GitLab의 프로젝트입니다.
- 프로젝트에 대한 Maintainer 또는 Owner 역할.

프로젝트가 없으면 <https://gitlab.com>에서 공개 프로젝트를 무료로 만들 수 있습니다.

## 단계 {#steps}

첫 번째 파이프라인을 만들고 실행하려면:

1. [사용 가능한 러너가 있는지 확인](#ensure-you-have-runners-available)하여 작업을 실행합니다.

   GitLab.com을 사용 중이면 이 단계를 건너뛸 수 있습니다. GitLab.com은 인스턴스 러너를 제공합니다.

1. 리포지토리의 루트에 [`.gitlab-ci.yml` 파일 만들기](#create-a-gitlab-ciyml-file). 이 파일은 CI/CD 작업을 정의하는 위치입니다.

파일을 리포지토리에 커밋하면 러너가 작업을 실행합니다. 작업 결과는 [파이프라인에 표시](#view-the-status-of-your-pipeline-and-jobs)됩니다.

## 사용 가능한 러너가 있는지 확인 {#ensure-you-have-runners-available}

GitLab에서 러너는 CI/CD 작업을 실행하는 에이전트입니다.

GitLab.com을 사용 중이면 이 단계를 건너뛸 수 있습니다. GitLab.com은 인스턴스 러너를 제공합니다.

사용 가능한 러너를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **러너**를 확장합니다.

활성 러너가 하나 이상 있고 옆에 녹색 원이 있으면 작업을 처리할 러너를 사용할 수 있습니다.

이 설정에 접근할 수 없으면 GitLab 관리자에게 문의하세요.

### 러너가 없는 경우 {#if-you-dont-have-a-runner}

러너가 없는 경우:

1. 로컬 머신에 [러너 설치](https://docs.gitlab.com/runner/install/).
1. 프로젝트에 [러너 등록](https://docs.gitlab.com/runner/register/). `shell` 실행기를 선택합니다.

CI/CD 작업을 실행할 때 이후 단계에서 로컬 머신에서 실행됩니다.

## `.gitlab-ci.yml` 파일 만들기 {#create-a-gitlab-ciyml-file}

이제 `.gitlab-ci.yml` 파일을 만듭니다. GitLab CI/CD에 대한 지침을 지정하는 [YAML](https://en.wikipedia.org/wiki/YAML) 파일입니다.

이 파일에서 다음을 정의합니다:

- 러너가 실행해야 하는 작업의 구조 및 순서입니다.
- 특정 조건이 발생할 때 러너가 내려야 할 결정입니다.

프로젝트에서 `.gitlab-ci.yml` 파일을 만들려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **Code** > **Repository**를 선택합니다.
1. 파일 목록 위에서 커밋할 브랜치를 선택합니다. 확실하지 않으면 `master` 또는 `main`를 그대로 둡니다. 그런 다음 오른쪽 위 모서리에서 더하기 아이콘({{< icon name="plus" >}}) 및 **새 파일**을 선택합니다:

   ![현재 폴더에 파일을 만드는 새 파일 버튼입니다.](img/new_file_v18_11.png)

1. **파일명**의 경우 `.gitlab-ci.yml`을(를) 입력하고 더 큰 창에 이 샘플 코드를 붙여넣습니다:

   ```yaml
   build-job:
     stage: build
     script:
       - echo "Hello, $GITLAB_USER_LOGIN!"

   test-job1:
     stage: test
     script:
       - echo "This job tests something"

   test-job2:
     stage: test
     script:
       - echo "This job tests something, but takes more time than test-job1."
       - echo "After the echo commands complete, it runs the sleep command for 20 seconds"
       - echo "which simulates a test that runs 20 seconds longer than test-job1"
       - sleep 20

   deploy-prod:
     stage: deploy
     script:
       - echo "This job deploys something from the $CI_COMMIT_BRANCH branch."
     environment: production
   ```

   이 예는 네 개의 작업을 보여줍니다: `build-job`, `test-job1`, `test-job2`, `deploy-prod`. `echo` 명령에 나열된 주석은 작업을 볼 때 UI에 표시됩니다. [사전 정의된 변수](../variables/predefined_variables.md) `$GITLAB_USER_LOGIN` 및 `$CI_COMMIT_BRANCH`의 값은 작업이 실행될 때 채워집니다.

1. **Commit changes**를 선택합니다.

파이프라인이 시작되고 `.gitlab-ci.yml` 파일에 정의한 작업을 실행합니다.

## 파이프라인 및 작업의 상태 보기 {#view-the-status-of-your-pipeline-and-jobs}

이제 파이프라인 및 그 안의 작업을 확인해봅시다.

1. **빌드** > **파이프라인**으로 이동합니다. 3개의 스테이지가 있는 파이프라인이 표시되어야 합니다:

   ![파이프라인 목록은 3개의 스테이지로 실행 중인 파이프라인을 표시합니다.](img/three_stages_v18_11.png)

1. 파이프라인 ID(`#676` 이 예)를 선택하여 파이프라인의 시각적 표현을 봅니다:

   ![파이프라인 그래프는 각 작업, 해당 상태 및 모든 스테이지에서의 종속성을 보여줍니다.](img/pipeline_graph_v18_11.png)

1. 작업 이름을 선택하여 작업의 세부 정보를 봅니다. 예를 들어 `deploy-prod`:

   ![작업 세부 정보 페이지에는 현재 상태, 타이밍 정보 및 작업 로그의 출력이 표시됩니다.](img/job_details_v18_11.png)

GitLab에서 첫 번째 CI/CD 파이프라인을 성공적으로 만들었습니다. 축하합니다!

이제 `.gitlab-ci.yml` 사용자 지정을 시작하고 더 고급 작업을 정의할 수 있습니다.

## `.gitlab-ci.yml` 팁 {#gitlab-ciyml-tips}

`.gitlab-ci.yml` 파일로 작업을 시작하는 데 도움이 되는 팁입니다.

완전한 `.gitlab-ci.yml` 구문은 전체 [CI/CD YAML 구문 참조](../yaml/_index.md)를 참조하세요.

- [파이프라인 편집기](../pipeline_editor/_index.md)를 사용하여 `.gitlab-ci.yml` 파일을 편집합니다.
- 각 작업은 스크립트 섹션을 포함하고 스테이지에 속합니다:
  - [`stage`](../yaml/_index.md#stage)는 작업의 순차적 실행을 설명합니다. 러너를 사용할 수 있으면 단일 스테이지의 작업이 병렬로 실행됩니다.
  - [`needs` 키워드](../yaml/_index.md#needs)를 사용하여 [작업을 스테이지 순서로 실행](../yaml/needs.md)하고 파이프라인 속도와 효율을 높입니다.
- 추가 구성을 설정하여 작업 및 스테이지의 성능을 사용자 지정할 수 있습니다:
  - [`rules`](../yaml/_index.md#rules) 키워드를 사용하여 작업을 실행하거나 건너뛸 시기를 지정합니다. `only` 및 `except` 레거시 키워드는 계속 지원되지만 `rules`을(를) 동일한 작업과 함께 사용할 수 없습니다.
  - [`cache`](../yaml/_index.md#cache) 및 [`artifacts`](../yaml/_index.md#artifacts)를 사용하여 파이프라인에서 작업 및 스테이지 간에 정보를 지속적으로 유지합니다. 이 키워드는 각 작업에 대해 임시 러너를 사용할 때도 종속성과 작업 출력을 저장하는 방법입니다.
  - [`default`](../yaml/_index.md#default) 키워드를 사용하여 모든 작업에 적용되는 추가 구성을 지정합니다. 이 키워드는 모든 작업에서 실행되어야 하는 [`before_script`](../yaml/_index.md#before_script) 및 [`after_script`](../yaml/_index.md#after_script) 섹션을 정의하는 데 자주 사용됩니다.

## 관련 항목 {#related-topics}

마이그레이션 출처:

- [Bamboo](../migration/bamboo.md)
- [CircleCI](../migration/circleci.md)
- [GitHub Actions](../migration/github_actions.md)
- [Jenkins](../migration/jenkins.md)
- [TeamCity](../migration/teamcity.md)
