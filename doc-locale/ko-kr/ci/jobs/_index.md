---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD 작업
description: "구성, 규칙, 캐싱, 아티팩트, 로그입니다."
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD 작업은 [GitLab CI/CD 파이프라인](../pipelines/_index.md)의 기본 요소입니다. 작업은 `.gitlab-ci.yml` 파일에서 구성되며, 코드 빌드, 테스트 또는 배포와 같은 작업을 수행하기 위해 실행할 명령어 목록을 포함합니다.

작업:

- 예를 들어 Docker 컨테이너에서 [러너](../runners/_index.md)에서 실행합니다.
- 다른 작업과 독립적으로 실행됩니다.
- [작업 로그](job_logs.md)를 포함하며, 이는 작업의 전체 실행 로그입니다.

[YAML 키워드](../yaml/_index.md)를 사용하여 작업이 정의되며, 다음을 포함하여 작업 실행의 모든 측면을 정의합니다:

- [어떻게](job_control.md) 및 [언제](job_rules.md) 작업이 실행되는지 제어합니다.
- [스테이지](../yaml/_index.md#stages)라고 불리는 컬렉션에 작업을 함께 그룹화합니다. 스테이지는 순차적으로 실행되는 반면, 스테이지 내의 모든 작업은 병렬로 실행될 수 있습니다.
- 유연한 구성을 위해 [CI/CD 변수](../variables/_index.md)를 정의합니다.
- 작업 실행 속도를 높이기 위해 [캐시](../caching/_index.md)를 정의합니다.
- 다른 작업에서 사용할 수 있는 [아티팩트](job_artifacts.md)로 파일을 저장합니다.

## 파이프라인에 작업 추가 {#add-a-job-to-a-pipeline}

작업을 파이프라인에 추가하려면 `.gitlab-ci.yml` 파일에 추가합니다. 작업은 다음을 충족해야 합니다:

- YAML 구성의 최상위 수준에서 정의됩니다.
- 고유한 [작업 이름](#job-names)을(를) 가져야 합니다.
- [`script` 섹션](../yaml/_index.md#script) 또는 [`trigger` 섹션](../yaml/_index.md#trigger)을(를) 가져야 하며, 이는 명령어를 실행하거나 [다운스트림 파이프라인](../pipelines/downstream_pipelines.md)을(를) 트리거하기 위한 것입니다.

예를 들어:

```yaml
my-ruby-job:
  script:
    - bundle install
    - bundle exec my_ruby_command

my-shell-script-job:
  script:
    - my_shell_script.sh
```

### 작업 이름 {#job-names}

이러한 키워드는 작업 이름으로 사용할 수 없습니다:

- `image`
- `services`
- `stages`
- `before_script`
- `after_script`
- `variables`
- `cache`
- `include`
- `pages:deploy` 스테이지 `deploy`에 대해 구성됨

또한 이러한 이름은 따옴표로 묶으면 유효하지만, 파이프라인 구성을 불명확하게 할 수 있으므로 권장되지 않습니다:

- `"true":`
- `"false":`
- `"nil":`

작업 이름은 255자 이하여야 합니다.

작업에 고유한 이름을 사용합니다. 파일에서 여러 작업이 같은 이름을 가지면, 하나만 파이프라인에 추가되고 어떤 것이 선택되는지 예측하기 어렵습니다. 포함된 파일 하나 이상에서 같은 작업 이름을 사용하면 [매개변수는 병합됩니다](../yaml/includes.md#override-included-configuration-values).

### 작업 숨기기 {#hide-a-job}

구성 파일에서 작업을 삭제하지 않고 임시로 비활성화하려면, 작업 이름의 시작 부분에 마침표(`.`)를 추가합니다. 숨겨진 작업은 `script` 또는 `trigger` 키워드를 포함할 필요가 없지만, 유효한 YAML 구성을 포함해야 합니다.

예를 들어:

```yaml
.hidden_job:
  script:
    - run test
```

숨겨진 작업은 GitLab CI/CD에서 처리되지 않지만, 다음을 사용하여 재사용 가능한 구성의 템플릿으로 사용할 수 있습니다:

- [`extends` 키워드](../yaml/yaml_optimization.md#use-extends-to-reuse-configuration-sections).
- [YAML 앵커](../yaml/yaml_optimization.md#anchors).

## 작업 키워드에 대한 기본값 설정 {#set-default-values-for-job-keywords}

`default` 키워드를 사용하여 기본 작업 키워드 및 값을 설정할 수 있으며, 이는 파이프라인의 모든 작업에서 기본값으로 사용됩니다.

예를 들어:

```yaml
default:
  image: 'ruby:2.4'
  before_script:
    - echo Hello World

rspec-job:
  script: bundle exec rspec
```

파이프라인이 실행될 때, 작업은 기본 키워드를 사용합니다:

```yaml
rspec-job:
  image: 'ruby:2.4'
  before_script:
    - echo Hello World
  script: bundle exec rspec
```

### 기본 키워드 및 변수 상속 제어 {#control-the-inheritance-of-default-keywords-and-variables}

다음의 상속을 제어할 수 있습니다:

- [기본 키워드](../yaml/_index.md#default) [`inherit:default`](../yaml/_index.md#inheritdefault)를 사용합니다.
- [기본 변수](../yaml/_index.md#default) [`inherit:variables`](../yaml/_index.md#inheritvariables)를 사용합니다.

예를 들어:

```yaml
default:
  image: 'ruby:2.4'
  before_script:
    - echo Hello World

variables:
  DOMAIN: example.com
  WEBHOOK_URL: https://my-webhook.example.com

rubocop:
  inherit:
    default: false
    variables: false
  script: bundle exec rubocop

rspec:
  inherit:
    default: [image]
    variables: [WEBHOOK_URL]
  script: bundle exec rspec

capybara:
  inherit:
    variables: false
  script: bundle exec capybara

karma:
  inherit:
    default: true
    variables: [DOMAIN]
  script: karma
```

이 예에서:

- `rubocop`:
  - 상속: 없음.
- `rspec`:
  - 상속: 기본 `image` 및 `WEBHOOK_URL` 변수.
  - 상속하지 않음: 기본 `before_script` 및 `DOMAIN` 변수.
- `capybara`:
  - 상속: 기본 `before_script` 및 `image`.
  - 상속하지 않음: `DOMAIN` 및 `WEBHOOK_URL` 변수.
- `karma`:
  - 상속: 기본 `image` 및 `before_script`, 그리고 `DOMAIN` 변수.
  - 상속하지 않음: `WEBHOOK_URL` 변수.

## 파이프라인에서 작업 보기 {#view-jobs-in-a-pipeline}

파이프라인에 액세스하면 해당 파이프라인의 관련 작업을 볼 수 있습니다.

파이프라인의 작업 순서는 파이프라인 그래프 유형에 따라 달라집니다.

- [전체 파이프라인 그래프](../pipelines/_index.md#pipeline-details)의 경우, 작업은 이름별로 알파벳 순서로 정렬됩니다.
- [파이프라인 미니 그래프](../pipelines/_index.md#pipeline-mini-graphs)의 경우, 작업은 상태 심각도별로 정렬되며, 실패한 작업이 먼저 나타나고 그 다음 알파벳 순서로 정렬됩니다.

개별 작업을 선택하면 [작업 로그](job_logs.md)를 표시하고 다음을 수행할 수 있습니다:

- 작업을 취소합니다.
- 실패한 경우 작업을 다시 시도합니다.
- 성공한 경우 작업을 다시 실행합니다.
- 작업 로그를 삭제합니다.

### 프로젝트 작업 보기 {#view-project-jobs}

{{< details >}}

- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- 작업 이름 필터 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/387547) [실험](../../policy/development_stages_support.md)으로 GitLab.com 및 GitLab Self-Managed에서 GitLab 17.3 [플래그](../../administration/feature_flags/_index.md) `populate_and_use_build_names_table` (API용) 및 `fe_search_build_by_name` (UI용). 기본적으로 비활성화되어 있습니다.
- GitLab 18.5에서 [정식 출시(GA)](https://gitlab.com/gitlab-org/gitlab/-/issues/512149). 기능 플래그 `populate_and_use_build_names_table` 및 `fe_search_build_by_name` 제거됨.
- 작업 종류 필터 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/555434) GitLab 18.3에서.

{{< /history >}}

프로젝트에서 실행된 작업을 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **작업**을 선택합니다.

목록을 작업 상태, 소스, 이름, 종류별로 필터링할 수 있습니다.

> [!note]
> 이름별 필터는 최근 30일 내에 생성된 작업을 반환합니다. 이 보존 기간은 UI 및 API 필터링 모두에 적용됩니다.

기본적으로 필터는 빌드 작업만 표시합니다. 트리거 작업을 보려면 필터를 지우고 **종류** > **트리거**를 선택합니다.

> [!note]
> **종류** 필터는 프로젝트 작업에만 사용 가능합니다. **운영자** 영역에서는 사용할 수 없습니다.

### 사용 가능한 작업 상태 {#available-job-statuses}

CI/CD 작업은 다음 상태를 가질 수 있습니다:

- `canceled`: 작업이 수동으로 취소되거나 자동으로 중단되었습니다.
- `canceling`: 작업이 취소 중이지만 `after_script`가 실행 중입니다.
- `created`: 작업이 생성되었지만 아직 처리되지 않았습니다.
- `failed`: 작업 실행이 실패했습니다.
- `manual`: 작업은 시작하기 위해 수동 작업이 필요합니다.
- `pending`: 작업은 러너를 기다리는 큐에 있습니다.
- `preparing`: 러너가 실행 환경을 준비 중입니다.
- `running`: 작업이 러너에서 실행 중입니다.
- `scheduled`: 작업이 예약되었지만 실행이 시작되지 않았습니다.
- `skipped`: 작업이 조건이나 종속성으로 인해 건너뛰어졌습니다.
- `success`: 작업이 성공적으로 완료되었습니다.
- `waiting_for_callback`: 작업은 외부 서비스의 콜백을 기다리고 있습니다.
- `waiting_for_resource`: 작업은 사용 가능하게 될 리소스를 기다리고 있습니다.

### 작업의 소스 보기 {#view-the-source-of-a-job}

{{< history >}}

- GitLab 17.9에서 [작업 소스 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181159) [플래그](../../administration/feature_flags/_index.md) `populate_and_use_build_source_table` 이름. 기본적으로 활성화됩니다.
- GitLab.com, GitLab Self-Managed, GitLab Dedicated에서 GitLab 17.11 [일반 공개](https://gitlab.com/groups/gitlab-org/-/epics/11796).

{{< /history >}}

GitLab CI/CD 작업은 작업을 트리거한 작업을 나타내는 소스 속성을 포함합니다. 이 속성을 사용하여 작업이 시작된 방식을 추적하거나 특정 소스를 기반으로 작업 실행을 필터링합니다.

#### 사용 가능한 작업 소스 {#available-job-sources}

소스 속성은 다음 값을 가질 수 있습니다:

- `api`: REST 호출로 시작된 작업 Jobs API.
- `chat`: GitLab ChatOps를 사용한 채팅 명령으로 시작된 작업.
- `container_registry_push`: 컨테이너 레지스트리 푸시로 시작된 작업.
- `duo_workflow`: GitLab Duo Agent Platform에 의해 시작된 작업.
- `external`: GitLab과 통합된 외부 리포지토리의 이벤트로 시작된 작업. 이는 풀 요청 이벤트를 포함하지 않습니다.
- `external_pull_request_event`: 외부 리포지토리의 풀 요청 이벤트로 시작된 작업.
- `merge_request_event`: 머지 리퀘스트 이벤트로 시작된 작업.
- `ondemand_dast_scan`: 온디맨드 DAST 스캔으로 시작된 작업.
- `ondemand_dast_validation`: 온디맨드 DAST 검증으로 시작된 작업.
- `parent_pipeline`: 부모 파이프라인에 의해 시작된 작업
- `pipeline`: 사용자가 파이프라인을 수동으로 실행하여 시작된 작업.
- `pipeline_execution_policy`: 파이프라인 실행 정책에 의해 시작된 작업.
- `pipeline_execution_policy_schedule`: 예약된 파이프라인 실행 정책에 의해 시작된 작업.
- `push`: 코드 푸시로 시작된 작업.
- `scan_execution_policy`: 검사 실행 정책에 의해 시작된 작업.
- `schedule`: 예약된 파이프라인에 의해 시작된 작업.
- `security_orchestration_policy`: 예약된 검사 실행 정책에 의해 시작된 작업.
- `trigger`: 다른 작업 또는 파이프라인에 의해 시작된 작업.
- `unknown`: 알 수 없는 소스로 시작된 작업.
- `web`: GitLab UI에서 사용자에 의해 시작된 작업.
- `webide`: Web IDE에서 사용자에 의해 시작된 작업.

### 파이프라인 보기에서 유사한 작업 함께 그룹화 {#group-similar-jobs-together-in-pipeline-views}

유사한 작업이 많은 경우 [파이프라인 그래프](../pipelines/_index.md#pipeline-details)가 길어지고 읽기 어려워집니다.

유사한 작업을 자동으로 함께 그룹화할 수 있습니다. 작업 이름이 특정 방식으로 형식화되면 일반 파이프라인 그래프(미니 그래프 아님)에서 단일 그룹으로 축소됩니다.

파이프라인에 그룹화된 작업이 있으면 재시도 또는 취소 버튼 대신 작업 이름 옆에 숫자가 표시되면 인식할 수 있습니다. 숫자는 그룹화된 작업의 양을 나타냅니다. 마우스를 올려놓으면 모든 작업이 통과했거나 실패한 경우 표시됩니다. 선택하여 확장합니다.

![여러 스테이지와 작업을 포함하는 파이프라인 그래프로 그룹화된 작업의 3개 그룹입니다.](img/pipeline_grouped_jobs_v17_9.png)

작업 그룹을 만들려면 `.gitlab-ci.yml` 파일에서 작업 이름을 숫자와 다음 중 하나로 구분합니다:

- 정방향 또는 역방향 슬래시(`/` 또는 `\`), 예를 들어 `slash-test 1/3`, `slash-test 2/3`, `slash-test 3/3`.
- 콜론(`:`), 예를 들어 `colon-test 1:3`, `colon-test 2:3`, `colon-test 3:3`.
- 공백, 예를 들어 `space-test 0 3`, `space-test 1 3`, `space-test 2 3`.

이 기호를 교대로 사용할 수 있습니다.

다음 예제에서 이 세 작업은 `build ruby`이라는 그룹에 있습니다:

```yaml
build ruby 1/3:
  stage: build
  script:
    - echo "ruby1"

build ruby 2/3:
  stage: build
  script:
    - echo "ruby2"

build ruby 3/3:
  stage: build
  script:
    - echo "ruby3"
```

파이프라인 그래프는 `build ruby`이라는 그룹을 3개의 작업과 함께 표시합니다.

작업은 왼쪽에서 오른쪽으로 숫자를 비교하여 정렬됩니다. 일반적으로 첫 번째 숫자를 인덱스로 하고 두 번째 숫자를 합계로 원합니다.

## 작업 재시도 {#retry-jobs}

최종 상태(실패, 성공 또는 취소)에 관계없이 작업이 완료된 후 다시 시도할 수 있습니다.

작업을 다시 시도할 때:

- 새 작업 ID를 사용하여 새 작업 인스턴스가 생성됩니다.
- 작업은 원본 작업과 동일한 매개변수 및 변수로 실행됩니다.
- 작업이 아티팩트를 생성하면 새로운 아티팩트가 생성되고 저장됩니다.
- 새 작업은 재시도를 시작한 사용자와 연결되며, 원본 파이프라인을 만든 사용자가 아닙니다.
- 이전에 건너뛴 모든 후속 작업은 재시도를 시작한 사용자에게 재할당됩니다.

다운스트림 파이프라인을 트리거하는 [트리거 작업](../yaml/_index.md#trigger)을 다시 시도할 때:

- 트리거 작업은 새로운 다운스트림 파이프라인을 생성합니다.
- 다운스트림 파이프라인도 재시도를 시작한 사용자와 연결됩니다.
- 다운스트림 파이프라인은 재시도 시점에 존재하는 구성으로 실행되며, 이는 원본 실행과 다를 수 있습니다.

### 작업 재시도 {#retry-a-job}

전제 조건:

- 프로젝트에 대한 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.
- 작업은 [보관되지 않은](../../administration/settings/continuous_integration.md#archive-pipelines) 상태여야 합니다.

머지 리퀘스트에서 작업을 다시 시도하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 머지 리퀘스트에서 다음 중 하나를 수행합니다:
   - 파이프라인 위젯에서 다시 시도하려는 작업 옆에 **다시 실행** ({{< icon name="retry" >}})을 선택합니다.
   - **파이프라인** 탭을 선택하고, 다시 시도하려는 작업 옆에 **다시 실행** ({{< icon name="retry" >}})을 선택합니다.

작업 로그에서 작업을 다시 시도하려면:

1. 작업의 로그 페이지로 이동합니다.
1. 오른쪽 위에서 **다시 실행** ({{< icon name="retry" >}})을 선택합니다.

파이프라인에서 작업을 다시 시도하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. 다시 시도하려는 작업을 포함하는 파이프라인을 찾습니다.
1. 파이프라인 그래프에서 다시 시도하려는 작업 옆에 **다시 실행** ({{< icon name="retry" >}})을 선택합니다.

### 파이프라인에서 모든 실패하거나 취소된 작업 다시 시도 {#retry-all-failed-or-canceled-jobs-in-a-pipeline}

파이프라인에 실패하거나 취소된 작업이 여러 개 있으면 한 번에 모두 다시 시도할 수 있습니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 다음 중 하나를 수행합니다:
   - **빌드** > **파이프라인**을 선택합니다.
   - 머지 리퀘스트로 이동하고 **파이프라인** 탭을 선택합니다.
1. 실패하거나 취소된 작업이 있는 파이프라인의 경우, **Retry all failed or canceled jobs** ({{< icon name="retry" >}})를 선택합니다.

## 작업 취소 {#cancel-jobs}

아직 완료되지 않은 CI/CD 작업을 취소할 수 있습니다. 작업을 취소할 때, 다음 일은 상태에 따라 달라집니다:

- 아직 실행을 시작하지 않은 작업의 경우 작업은 즉시 취소됩니다.
- 실행 중인 작업의 경우:
  1. 작업은 `canceling`로 표시됩니다.
  1. 실행 중인 명령은 완료될 수 있습니다. 작업의 [`before_script`](../yaml/_index.md#before_script) 또는 [`script`](../yaml/_index.md#script)의 나머지 명령은 건너뜁니다.
  1. 작업에 `after_script` 섹션이 있으면 항상 시작되고 완료될 때까지 실행됩니다.
  1. 작업은 `canceled`로 표시됩니다.

`after_script`을 기다리지 않고 작업을 즉시 취소해야 하면 [강제 취소](#force-cancel-a-job)를 사용합니다.

### 작업 취소 {#cancel-a-job}

전제 조건:

- 프로젝트에 대해 개발자, 유지관리자 또는 소유자 역할을 하거나 [파이프라인 또는 작업을 취소하기 위한 최소 역할](../pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs)이 필요합니다.

머지 리퀘스트에서 작업을 취소하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 머지 리퀘스트에서 다음 중 하나를 수행합니다:
   - 파이프라인 위젯에서 취소하려는 작업 옆에 **취소** ({{< icon name="cancel" >}})을 선택합니다.
   - **파이프라인** 탭을 선택하고, 취소하려는 작업 옆에 **취소** ({{< icon name="cancel" >}})을 선택합니다.

작업 로그에서 작업을 취소하려면:

1. 작업의 로그 페이지로 이동합니다.
1. 오른쪽 위에서 **취소** ({{< icon name="cancel" >}})을 선택합니다.

파이프라인에서 작업을 취소하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. 취소하려는 작업을 포함하는 파이프라인을 찾습니다.
1. 파이프라인 그래프에서 취소하려는 작업 옆에 **취소** ({{< icon name="cancel" >}})을 선택합니다.

### 파이프라인에서 모든 실행 중인 작업 취소 {#cancel-all-running-jobs-in-a-pipeline}

실행 중인 파이프라인의 모든 작업을 한 번에 취소할 수 있습니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 다음 중 하나를 수행합니다:
   - **빌드** > **파이프라인**을 선택합니다.
   - 머지 리퀘스트로 이동하고 **파이프라인** 탭을 선택합니다.
1. 취소하려는 파이프라인의 경우, **실행중인 파이프라인 취소** ({{< icon name="cancel" >}})를 선택합니다.

### 작업 강제 취소 {#force-cancel-a-job}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/467107) \- GitLab 17.10에서 [실험](../../policy/development_stages_support.md)으로 [플래그](../../administration/feature_flags/_index.md) `force_cancel_build`와 함께 도입되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 17.11에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/519313). 기능 플래그 `force_cancel_build`이 제거되었습니다.

{{< /history >}}

`after_script`이 완료될 때까지 기다리고 싶지 않거나 작업이 응답하지 않으면 강제 취소할 수 있습니다. 강제 취소는 작업을 `canceling` 상태에서 `canceled`로 즉시 이동합니다.

작업을 강제 취소하면 [작업 토큰](ci_job_token.md)이 즉시 취소됩니다. 러너가 여전히 작업을 실행 중이면 GitLab에 대한 액세스 권한을 잃습니다. 러너는 `after_script`이 완료될 때까지 기다리지 않고 작업을 중단합니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.
- 작업은 `canceling` 상태에 있어야 하며, 다음이 필요합니다:
  - GitLab 17.0 이상.
  - GitLab Runner 16.10 이상.

작업을 강제로 취소하려면:

1. 작업의 로그 페이지로 이동합니다.
1. 오른쪽 위에서 **강제 취소**를 선택합니다.

## 실패한 작업 문제 해결 {#troubleshoot-a-failed-job}

파이프라인이 실패하거나 실패가 허용되면 이유를 찾을 수 있는 여러 위치가 있습니다:

- [파이프라인 그래프](../pipelines/_index.md#pipeline-details)에서, 파이프라인 세부정보 보기에서.
- 파이프라인 위젯에서, 머지 리퀘스트 및 커밋 페이지에서.
- 작업 보기에서, 작업의 전역 및 상세 보기에서.

각 위치에서 실패한 작업 위에 마우스를 올려놓으면 실패한 이유를 볼 수 있습니다.

![실패한 작업과 실패 이유를 보여주는 파이프라인 그래프입니다.](img/job_failure_reason_v17_9.png)

작업 상세 페이지에서 실패한 이유를 볼 수 있습니다.

### 근본 원인 분석으로 {#with-root-cause-analysis}

GitLab Duo 근본 원인 분석을 GitLab Duo Chat에서 사용하여 [실패한 CI/CD 작업 문제 해결](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)할 수 있습니다.

## 배포 작업 {#deployment-jobs}

배포 작업은 [환경](../environments/_index.md)을 사용하는 CI/CD 작업입니다. 배포 작업은 `environment` 키워드와 [`start` 환경 `action`](../yaml/_index.md#environmentaction)를 사용하는 모든 작업입니다. 배포 작업은 `deploy` 스테이지에 있을 필요가 없습니다. 다음 `deploy me` 작업은 배포 작업의 예입니다. `action: start`은 기본 동작이며 명확히 하기 위해 여기서 정의되지만 생략할 수 있습니다:

```yaml
deploy me:
  script:
    - deploy-to-cats.sh
  environment:
    name: production
    url: https://cats.example.com
    action: start
```

배포 작업의 동작은 [배포 안전](../environments/deployment_safety.md) 설정으로 제어할 수 있습니다. 예를 들어 [오래된 배포 작업 방지](../environments/deployment_safety.md#prevent-outdated-deployment-jobs) 및 [한 번에 하나의 배포 작업만 실행 확인](../environments/deployment_safety.md#ensure-only-one-deployment-job-runs-at-a-time)입니다.
