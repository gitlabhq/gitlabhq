---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 작업 입력
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.10에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/17833)되었습니다.
- GitLab Runner 18.9 이상이 필요합니다.

{{< /history >}}

작업 입력을 사용하여 수동으로 실행하거나 재시도할 때 재정의할 수 있는 개별 CI/CD 작업에 대해 타입이 지정되고 검증된 매개변수를 정의합니다. [CI/CD 변수](../variables/_index.md)와 달리 작업 입력은 다음을 제공합니다:

- 타입 안전성: 입력은 `string`, `number`, `boolean` 또는 `array`이(가) 될 수 있으며 자동 검증을 지원합니다.
- 명확한 계약: 작업은(는) 정의한 입력만 허용합니다. 예상치 못한 입력은 거부됩니다.
- 재정의 기능: 입력 값은 작업을 [실행](#run-a-manual-job-with-input-values)할 때 설정할 수 있고, 작업을 [재시도](#retry-a-job-with-different-input-values)할 때 변경할 수 있습니다.

작업 입력을 작업 재실행 시 조정해야 할 수 있는 작업 동작을 제어하는 매개변수에 사용합니다. 예: 배포 대상, 테스트 구성 또는 기능 플래그.

작업 입력은 정의된 작업으로 범위가 지정되며 포함된 파일이나 다른 작업에서 액세스할 수 없습니다. 작업이나 파일 간에 구성을 공유해야 하는 경우 대신 [CI/CD 구성 입력](../inputs/_index.md)을 사용합니다.

## 작업 입력 비교 {#job-input-comparison}

### CI/CD 파이프라인 구성 입력과 비교 {#compared-to-cicd-pipeline-configuration-inputs}

작업 입력과 [CI/CD 파이프라인 구성 입력](../inputs/_index.md)은(는) 다른 용도로 사용됩니다:

| 기능        | 작업 입력                                                              | CI/CD 구성 입력 |
|----------------|-------------------------------------------------------------------------|---------------------|
| 목적        | 개별 작업 동작을 구성합니다                                       | 재사용 가능한 템플릿과 구성 요소를 구성합니다 |
| 구문         | 작업 정의의 `inputs:`                                             | 구성 헤더의 `spec:inputs:` |
| 보간  | `${{ job.inputs.INPUT_NAME }}`                                          | `$[[ inputs.INPUT_NAME ]]` |
| 평가     | 작업 생성 시 설정된 값으로, 실행/재시도 시 재정의할 수 있습니다 | 파이프라인 생성 시 설정된 값으로, 전체 파이프라인에서 고정됩니다 |
| 기본값 | 필수                                                                | 선택 사항 |
| 범위          | 단일 작업만                                                         | 전체 구성 파일 또는 포함된 파일로 전달 |

### 환경 변수와 비교 {#compared-to-environment-variables}

작업 입력은 작업 생성 시 작업 구성으로 보간됩니다. 이들은 환경 변수가 아니며 `$INPUT_NAME` 구문으로 액세스할 수 없습니다. 작업 입력을 `${{ job.inputs.INPUT_NAME }}` 구문으로 스크립트 및 기타 지원되는 키워드에서 직접 사용할 수 있습니다.

## 작업 입력 정의 및 사용 {#define-and-use-job-inputs}

작업에서 입력 매개변수를 정의하려면 `inputs` 키워드를 사용합니다. 각 입력은 기본값을 가져야 합니다. `${{ job.inputs.INPUT_NAME }}` [Moa 표현식](../functions/moa.md) 구문으로 입력 값을 참조합니다.

예를 들어:

```yaml
deploy_job:
  inputs:
    target_env:
      default: staging
      options: [staging, production]
    replicas:
      type: number
      default: 3
    debug_mode:
      type: boolean
      default: false
  script:
    - 'echo "Deploying to ${{ job.inputs.target_env }}"'
    - 'echo "Replicas - ${{ job.inputs.replicas }}"'
    - 'if [ "${{ job.inputs.debug_mode }}" == "true" ]; then set -x; fi'
    - ./deploy.sh
```

### 입력 구성 {#input-configuration}

다음 키워드로 입력을 구성합니다:

- `default`: 작업 실행 시 사용되는 기본값입니다. 모든 작업 입력은 기본값을 가져야 합니다.
- `type`: 선택 사항. 입력 유형입니다. `string` (기본값), `number`, `boolean` 또는 `array`일 수 있습니다.
- `description`: 선택 사항. 입력 목적에 대한 사용자가 읽을 수 있는 설명입니다.
- `options`: 선택 사항. 허용된 값의 목록입니다. 입력은 이러한 값 중 하나와 일치해야 합니다.
- `regex`: 선택 사항. 입력이 일치해야 하는 정규 표현식 패턴입니다.

예를 들어:

```yaml
test_job:
  inputs:
    test_framework:
      default: rspec
      description: Testing framework to use
      options: [rspec, minitest, cucumber]
    parallel_count:
      type: number
      default: 5
      description: Number of parallel test jobs
    run_integration_tests:
      type: boolean
      default: false
      description: Whether to run integration tests
    test_tags:
      type: array
      default: [smoke, regression]
      description: Test tags to run
  script:
    - bundle exec ${{ job.inputs.test_framework }}
    - 'echo "Running ${{ job.inputs.parallel_count }} parallel jobs"'
```

작업 입력은 작업 생성 시 및 입력 값이 재정의될 때 검증됩니다. 검증이 실패하면 작업이(가) 명확한 오류 메시지와 함께 시작되지 않습니다.

### 입력 형식 {#input-types}

작업 입력은 다음 유형을 지원합니다:

- `string` (기본값): 텍스트 값입니다(예: `"staging"` 또는 `"v1.2.3"`).
- `number`: 숫자 값입니다(예: `5`, `3.14` 또는 `-10`).
- `boolean`: `true` 또는 `false`의 부울 값입니다.
- `array`: 값의 목록입니다(예: `[1, 2, 3]` 또는 `["a", "b"]`).

API 또는 UI를 통해 입력 값을 전달할 때 배열은 JSON 형식이어야 합니다(예: `["value1", "value2"]`).

### 작업 입력을 사용할 수 있는 위치 {#where-you-can-use-job-inputs}

간단한 보간 또는 연산자 및 함수가 있는 더 복잡한 표현식을 사용할 수 있습니다. 전체 구문은 [Moa 표현식 언어](../functions/moa.md)를 참조하세요.

작업 입력은 다음 작업 키워드 및 해당 하위 키에서 사용할 수 있습니다:

- `script`, `before_script` 및 `after_script`
- `artifacts`
- `cache`
- `image`
- `services`

### 제한사항 {#limitations}

작업 입력은 `${{ job.inputs.INPUT_NAME }}` 구문을 사용하며, 이는 파이프라인 구성이 생성될 때가 아니라 작업이 실행될 때 평가됩니다. 작업 입력을 파이프라인 생성 시 평가해야 하는 구성 부분에 사용할 수 없습니다(예:

- 작업 이름
- `stage` 키워드
- `rules` 키워드
- `include` 키워드
- 위에 나열되지 않은 다른 작업 수준의 키워드

파이프라인의 이러한 부분을 동적으로 구성하려면 대신 [CI/CD 파이프라인 구성 입력](../inputs/_index.md)을 `$[[ inputs.* ]]` 구문과 함께 사용합니다.

## 입력 값 제공 {#provide-input-values}

다음과 같은 경우에 작업 입력 값을 제공할 수 있습니다:

- 수동 작업 실행
- 작업 완료 후 재시도

### 입력 값으로 수동 작업 실행 {#run-a-manual-job-with-input-values}

입력이 정의된 수동 작업을 실행할 때 입력 값을 지정할 수 있습니다.

특정 입력으로 수동 작업을(를) 실행하려면:

1. 파이프라인, 작업 또는 [환경](../environments/deployments.md#configure-manual-deployments) 보기로 이동합니다.
1. 수동 작업의 이름을 선택합니다. **실행** ({{< icon name="play" >}})을 선택하지 않습니다.
1. 양식에서 입력 값을 지정합니다.
1. **작업 실행**을 선택합니다.

### 다른 입력 값으로 작업 재시도 {#retry-a-job-with-different-input-values}

입력이 정의된 작업을 재시도할 때 입력 값을 업데이트할 수 있습니다.

다른 입력으로 작업을 재시도하려면:

1. 작업 세부 정보 페이지로 이동합니다.
1. **수정된 값으로 작업 다시 시도** ({{< icon name="chevron-down" >}})를 선택합니다.
1. 양식에서 입력은 이전 실행의 값으로 미리 채워집니다. 필요에 따라 입력 값을 수정합니다.
1. **작업 다시 실행**을 선택합니다.

대신 동일한 입력 값으로 재시도하려면 **재시도** ({{< icon name="retry" >}})를 선택합니다.

## 작업 입력 예제 {#job-input-examples}

### 입력이 있는 기본 배포 작업 {#basic-deployment-job-with-inputs}

```yaml
deploy:
  when: manual
  inputs:
    target_env:
      default: staging
      description: Target deployment environment
      options: [staging, production]
    version:
      default: latest
      description: Application version to deploy
  script:
    - 'echo "Deploying version ${{ job.inputs.version }} to ${{ job.inputs.target_env }}"'
    - ./deploy.sh --env ${{ job.inputs.target_env }} --version ${{ job.inputs.version }}
```

### 검증이 있는 테스트 작업 {#test-job-with-validation}

```yaml
integration_tests:
  inputs:
    test_suite:
      default: smoke
      description: Which test suite to run
      options: [smoke, regression, full]
    parallel_jobs:
      type: number
      default: 5
      description: Number of parallel test runners
    enable_debug:
      type: boolean
      default: false
      description: Enable debug logging
    tags:
      type: array
      default: ["critical"]
      description: Test tags to run
  script:
    - 'if [ "${{ job.inputs.enable_debug }}" == "true" ]; then export DEBUG=1; fi'
    - ./run_tests.sh
        --suite ${{ job.inputs.test_suite }}
        --parallel ${{ job.inputs.parallel_jobs }}
        --tags '${{ job.inputs.tags }}'
```

### 안전 검사가 있는 데이터베이스 마이그레이션 {#database-migration-with-safety-checks}

```yaml
migrate_database:
  when: manual
  inputs:
    target_db:
      default: development
      description: Database environment
      options: [development, staging, production]
    migration_name:
      default: ""
      description: Specific migration to run (leave empty for all)
      regex: ^[a-zA-Z0-9_]*$
    dry_run:
      type: boolean
      default: true
      description: Run in dry-run mode without applying changes
  script:
    - 'echo "Running migrations on ${{ job.inputs.target_db }}"'
    - |
      if [ "${{ job.inputs.dry_run }}" == "true" ]; then
        echo "DRY RUN MODE - no changes will be applied"
        MIGRATION_FLAGS="--dry-run"
      fi
    - |
      if [ -n "${{ job.inputs.migration_name }}" ]; then
        ./migrate.sh $MIGRATION_FLAGS --migration ${{ job.inputs.migration_name }}
      else
        ./migrate.sh $MIGRATION_FLAGS --all
      fi
```

## API와 함께 작업 입력 사용 {#use-job-inputs-with-the-api}

API를 사용하여 작업을 실행하거나 재시도할 때 작업 입력 값을 지정할 수 있습니다.

### 입력으로 수동 작업 실행 {#run-a-manual-job-with-inputs}

`job_inputs` 매개변수와 함께 [`POST /projects/:id/jobs/:job_id/play` 엔드포인트](../../api/jobs.md#run-a-job)를 사용합니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "job_inputs": {
      "environment": "staging",
      "version": "v2.1.0"
    }
  }' \
  "https://gitlab.example.com/api/v4/projects/1/jobs/456/play"
```

### 입력으로 작업 재시도 {#retry-a-job-with-inputs}

`job_inputs` 매개변수와 함께 [`POST /projects/:id/jobs/:job_id/retry` 엔드포인트](../../api/jobs.md#retry-a-job)를 사용합니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "job_inputs": {
      "environment": "production",
      "replicas": 10
    }
  }' \
  "https://gitlab.example.com/api/v4/projects/1/jobs/123/retry"
```

### GraphQL 사용 {#use-graphql}

`inputs` 인수와 함께 [`jobPlay` 변형](../../api/graphql/reference/_index.md#mutationjobplay) 또는 [`jobRetry` 변형](../../api/graphql/reference/_index.md#mutationjobretry)을(를) 사용할 수 있습니다:

```graphql
mutation {
  jobPlay(input: {
    id: "gid://gitlab/Ci::Build/123",
    inputs: [
      { name: "environment", value: "production" },
      { name: "replicas", value: 10 }
    ]
  }) {
    job {
      id
      status
    }
    errors
  }
}
```

## 문제 해결 {#troubleshooting}

### 작업이 `input must have a default value`로 인해 실패합니다 {#job-fails-with-input-must-have-a-default-value}

작업 입력은 입력을 수동으로 지정할 수 없는 파이프라인에서 작업을(를) 실행할 수 있도록 항상 기본값을 가져야 합니다.

이 오류를 수정하려면 모든 입력에 `default`을(를) 추가합니다:

```yaml
my_job:
  inputs:
    target_env:
      default: staging  # Default specified
  script:
    - echo ${{ job.inputs.target_env }}
```

### 입력 검증이 `unexpected value`로 인해 실패합니다 {#input-validation-fails-with-unexpected-value}

입력 검증이 실패하면 다음을 확인하세요:

- `options`을(를) 사용하는 경우 값이 정확히 허용된 옵션 중 하나와 일치하는지 확인합니다(대소문자 구분).
- `regex`을(를) 사용하는 경우 정규 표현식이 입력 값과 일치하는지 테스트합니다.
- `type: number`을(를) 사용하는 경우 값이 문자열이 아닌 숫자인지 확인합니다.
- `type: array`을(를) 사용하는 경우 API를 통해 전달할 때 값이 JSON 배열로 형식화되어 있는지 확인합니다.
