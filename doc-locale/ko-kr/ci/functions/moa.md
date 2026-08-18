---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Moa 표현식 언어
---

Moa는 작업 실행 중에 값을 동적으로 구성하기 위한 표현식 언어입니다. 표현식은 `${{ }}` 구분 기호로 둘러싸여 있으며 GitLab Functions 및 CI/CD 입력에서 사용됩니다.

Moa는 문자열 조작, 산술, 비교, 논리 연산, 속성 액세스 및 함수 호출을 지원합니다.

## CI/CD 표현식과의 차이점 {#differences-from-cicd-expressions}

GitLab에는 파이프라인 수명 주기의 다양한 단계에서 다양한 목적으로 사용되는 세 가지 표현식 구문이 있습니다.

- [Rules](../yaml/_index.md#rules)는 작업 포함을 제어하기 위해 `rules:` 키워드 내에서 자신의 표현식 구문을 사용합니다. 이들은 파이프라인 생성 중에 평가되며 CI/CD 변수 비교 및 패턴 매칭을 지원하지만 산술을 수행하거나 런타임 상태에 액세스할 수 없습니다.
- CI/CD 변수 표현식은 `$[[ ]]` 구문을 사용하며 파이프라인 생성 중에 평가되고, 어떤 작업도 실행되기 전에 평가됩니다. 이러한 표현식은 [CI/CD 입력](../inputs/_index.md), [행렬 값](../yaml/matrix_expressions.md) 및 [구성 요소 입력](../components/_index.md)에 대한 값 대체를 수행합니다. 산술, 비교 또는 논리를 수행할 수 없으며 런타임 상태에 액세스할 수 없습니다. 자세한 내용은 [CI/CD 변수 표현식](../yaml/expressions.md)을 참조하세요.
- Moa는 `${{ }}` 구문을 사용하며 러너에 의해 작업 실행 중에 평가됩니다. Moa는 연산자, 데이터 구조 및 함수 호출이 있는 완전한 표현식 언어입니다.

세 가지 구문 모두 동일한 파이프라인에 공존할 수 있습니다. GitLab Functions를 포함하는 CI/CD 구성 요소는 세 가지를 모두 사용할 수 있습니다:

```yaml
spec:
  inputs:
    echo_version:
      type: string
---

hi-job:
  # rules expression - evaluated when the pipeline is created
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  run:
    - name: say_hi
      # $[[ ]] - resolved when the pipeline is created
      step: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo@$[[ inputs.echo_version ]]
      inputs:
        # ${{ }} - resolved when the job runs
        message: "Hello, ${{ vars.CI_PROJECT_NAME }}"
```

Moa는 파이프라인 생성 시간에 사용할 수 없는 기능이 필요하기 때문에 별도의 언어로 존재합니다:

- 런타임 평가: 단계 출력은 함수가 실행될 때까지 존재하지 않습니다. `${{ steps.build.outputs.image_ref }}`과 같은 표현식은 실행 중에만 평가될 수 있습니다.
- 유형화된 값: Moa는 네이티브 유형(숫자, 부울, 배열 및 개체)을 보존하고 문자열로 변환하지 않고 함수 간에 전달합니다.
- 연산자 및 논리: GitLab Functions는 변수 및 출력에서 단계 입력을 구성하기 위해 산술(`major_version + 1`), 비교(`vulnerabilities == 0`) 및 단락 논리(`inputs.tag || "latest"`)가 필요합니다.
- 민감한 값 추적: Moa는 작업을 통해 민감한 값을 전파합니다. 민감한 값을 문자열로 연결하거나 함수 호출을 통해 전달하면 결과도 민감한 것으로 처리됩니다. 이렇게 하면 로그 및 출력에서 비밀 우발적 공개를 방지합니다.

## 컨텍스트 참조 {#context-reference}

표현식에서 사용 가능한 값은 표현식이 사용되는 위치에 따라 달라집니다.

| 컨텍스트       | 다음에서 사용 가능                                                                                             | 형식   | 평가됨                        | 설명                                                                                                                             |
|---------------|----------------------------------------------------------------------------------------------------------|--------|----------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `job.inputs`  | 작업 구성: `script`, `before_script`, `after_script`, `artifacts`, `cache`, `image`, `services`  | 개체 | 러너가 작업을 받을 때 | 작업에 대해 정의된 입력 값입니다. `job.inputs.<name>`을(를) 사용하여 개별 변수에 액세스합니다.                                                 |
| `env`         | GitLab Functions                                                                                         | 개체 | 함수가 실행되기 전         | 함수에서 사용할 수 있는 환경 변수입니다. `env.<name>`을(를) 사용하여 개별 변수에 액세스합니다.                                         |
| `inputs`      | GitLab Functions                                                                                         | 개체 | 함수가 실행되기 전         | 함수에 전달된 입력 값입니다. `inputs.<name>`을(를) 사용하여 개별 입력에 액세스합니다.                                                     |
| `vars`        | GitLab Functions                                                                                         | 개체 | 함수가 실행되기 전         | CI 작업에서 전달된 작업 변수입니다. `vars.<name>`을(를) 사용하여 개별 변수에 액세스합니다.                                                   |
| `steps`       | GitLab Functions                                                                                         | 개체 | 함수가 실행되기 전         | 현재 함수에서 이전에 실행된 단계의 결과입니다. `steps.<step_name>.outputs.<output_name>`을(를) 사용하여 단계의 출력에 액세스합니다. |
| `export_file` | GitLab Functions                                                                                         | 문자열 | 함수가 실행되기 전         | 함수가 후속 단계로 내보낼 환경 변수를 쓸 수 있는 파일의 경로입니다.                                      |
| `output_file` | GitLab Functions                                                                                         | 문자열 | 함수가 실행되기 전         | 함수가 출력 값을 쓰는 파일의 경로입니다.                                                                           |
| `func_dir`    | GitLab Functions                                                                                         | 문자열 | 함수가 실행되기 전         | 함수의 정의 파일이 포함된 디렉터리의 경로입니다. 함수와 함께 번들된 파일을 참조하는 데 사용합니다.                      |
| `work_dir`    | GitLab Functions                                                                                         | 문자열 | 함수가 실행되기 전         | 현재 실행의 작업 디렉터리 경로입니다.                                                                                |

## 템플릿 구문 {#template-syntax}

### 보간 {#interpolation}

표현식을 평가하려면 `${{ }}`에서 식을 래핑합니다:

```yaml
script:
  - echo "Hello, ${{ job.inputs.name }}"
```

텍스트가 표현식을 둘러싸면 결과는 항상 문자열로 변환됩니다. 여러 표현식이 단일 값에 나타날 수 있습니다:

```yaml
script:
  - echo "${{ job.inputs.greeting }}, ${{ job.inputs.name }}!"
```

### 네이티브 유형 통과 {#native-type-passthrough}

`${{ expression }}`이(가) 주변 텍스트 없이 전체 값인 경우 표현식은 네이티브 유형을 반환합니다. 네이티브 유형 표현식을 사용하여 단계 간에 숫자, 부울, 배열 및 개체와 같은 문자열이 아닌 값을 문자열로 변환하지 않고 전달합니다.

```yaml
inputs:
  count: ${{ steps.previous.outputs.total }}
```

이 예제에서 `total`이(가) 숫자이면 `count`은(는) 문자열 표현이 아닌 숫자를 수신합니다.

### Moa 표현식 이스케이프 {#escape-moa-expressions}

보간을 트리거하지 않고 텍스트에 리터럴 `${{`을(를) 포함하려면 백슬래시로 이스케이프합니다:

```yaml
script:
  - echo "Use \${{ to start an expression"
```

이 명령은 평가 없이 `Use ${{ to start an expression` 텍스트를 출력합니다.

## 리터럴 {#literals}

### Null {#null}

키워드 `null`은(는) 값이 없음을 나타냅니다.

```yaml
${{ null }}
```

### 부울 {#booleans}

키워드 `true` 및 `false`은(는) 부울 값을 나타냅니다.

```yaml
${{ true }}
${{ false }}
```

### 숫자 {#numbers}

숫자는 53비트 유효 자릿수 정밀도가 있는 IEEE 754 배정밀도 부동 소수점 값입니다. 정수, 소수 및 과학 표기법이 지원됩니다.

```yaml
${{ 42 }}
${{ 3.14 }}
${{ 1.5e3 }}
${{ 2E-4 }}
```

### 문자열 {#strings}

문자열을 큰따옴표 또는 작은따옴표로 묶습니다. 두 개의 인용 부호 유형은 이스케이프 시퀀스 및 템플릿 표현식을 다르게 처리합니다.

큰따옴표 문자열은 템플릿 표현식과 전체 이스케이프 시퀀스 집합을 지원합니다:

| 시퀀스  | 의미                                 |
|-----------|-----------------------------------------|
| `\\`      | 백슬래시                               |
| `\"`      | 큰따옴표                            |
| `\n`      | 줄바꿈                                 |
| `\r`      | 캐리지 반환                         |
| `\t`      | 탭                                     |
| `\a`      | 경고(벨)                            |
| `\b`      | 백스페이스                               |
| `\f`      | 용지 공급                               |
| `\v`      | 수직 탭                            |
| `\/`      | 앞슬래시                           |
| `\uXXXX`  | 유니코드 코드 포인트                      |
| `\${{`    | 리터럴 `${{`(보간 방지)  |

템플릿 표현식(`${{ }}`)은(는) 큰따옴표 문자열 내에서 평가되고 문자열로 보간됩니다.

작은따옴표 문자열은 최소 해석이 있는 원시 문자열 리터럴입니다. 작은따옴표 문자열 내의 템플릿 표현식은 평가되지 않습니다. 두 가지 이스케이프 시퀀스만 지원됩니다:

| 시퀀스 | 의미      |
|----------|--------------|
| `\\`     | 백슬래시    |
| `\'`     | 작은따옴표 |

```yaml
${{ "Hello\nWorld" }}
${{ 'It\'s a string' }}
${{ 'Literal ${{ not evaluated }}' }}
```

## 식별자 {#identifiers}

식별자는 표현식 컨텍스트의 값을 참조합니다. 식별자는 문자 또는 밑줄로 시작하며 문자, 숫자 및 밑줄을 포함할 수 있습니다. 식별자는 대소문자를 구분합니다: `foo`, `Foo` 및 `FOO`은(는) 세 개의 다른 식별자입니다.

```yaml
${{ env }}
${{ my_variable }}
```

식별자는 사용 가능한 컨텍스트에 대해 확인됩니다. 각 컨텍스트에서 사용 가능한 값은 [컨텍스트 참조](#context-reference)를 참조하세요.

식별자가 컨텍스트 개체를 참조하면 전체 개체가 반환됩니다. 예를 들어 `${{ vars }}`은(는) 모든 작업 변수를 개체로 반환합니다.

## 연산자 {#operators}

### 산술 연산자 {#arithmetic-operators}

산술 연산자는 숫자에서 작동합니다. `+` 연산자도 문자열을 연결합니다. 연산자는 암시적 유형 변환을 수행하지 않으므로 `"hello" + 42`은(는) 오류가 발생합니다.

| 연산자 | 설명                 | 예제             | 결과     |
|----------|-----------------------------|---------------------|------------|
| `+`      | 더하기                    | `${{ 2 + 3 }}`      | `5`        |
| `+`      | 연결               | `${{ "a" + "b" }}`  | `"ab"`     |
| `-`      | 빼기                 | `${{ 10 - 4 }}`     | `6`        |
| `*`      | 곱셈              | `${{ 3 * 4 }}`      | `12`       |
| `/`      | 나누기                    | `${{ 10 / 3 }}`     | `3.333...` |
| `%`      | 모듈로(잘린 나누기) | `${{ 10 % 3 }}`     | `1`        |

0으로 나누기 오류가 발생합니다.

### 비교 연산자 {#comparison-operators}

비교 연산자는 부울 값을 반환합니다.

| 연산자 | 설명           | 예제            | 결과  |
|----------|-----------------------|--------------------|---------|
| `==`     | 같음                 | `${{ 1 == 1 }}`    | `true`  |
| `!=`     | 같지 않음             | `${{ 1 != 2 }}`    | `true`  |
| `<`      | 보다 작음             | `${{ 1 < 2 }}`     | `true`  |
| `<=`     | 보다 작거나 같음    | `${{ 2 <= 2 }}`    | `true`  |
| `>`      | 보다 큼          | `${{ 3 > 2 }}`     | `true`  |
| `>=`     | 보다 크거나 같음 | `${{ 3 >= 3 }}`    | `true`  |

다른 유형의 값은 유형별로 비교되므로 `1 == "1"`은(는) `false`로 계산됩니다. 동일한 유형의 값은 다음 비교 규칙을 따릅니다:

- 숫자: 숫자 비교입니다.
- 문자열: 사전식 비교(UTF-8 바이트 순서)입니다.
- 부울: `false`은(는) `true`보다 작습니다.
- 배열: 요소별 비교입니다.
- 개체: 길이, 키, 값 순서로 비교됩니다. 키 순서는 중요하지 않습니다.
- Null: `null`은(는) `null`과(와) 같습니다.

### 논리 연산자 {#logical-operators}

논리 연산자는 단락 평가를 사용하고 반드시 부울이 아닌 피연산자 중 하나를 반환합니다. 이 동작은 JavaScript `&&` 및 `||` 연산자와 유사합니다.

| 연산자   | 설명 | 동작                                                                                      |
|------------|-------------|-----------------------------------------------------------------------------------------------|
| `\|\|`     | 논리 OR  | 왼쪽 피연산자가 참이면 반환하고, 그렇지 않으면 오른쪽 피연산자를 평가하고 반환합니다.  |
| `&&`       | 논리 AND | 왼쪽 피연산자가 거짓이면 반환하고, 그렇지 않으면 오른쪽 피연산자를 평가하고 반환합니다.   |
| `!`        | 논리 NOT | 피연산자가 거짓이면 `true`을(를) 반환하고, 참이면 `false`을(를) 반환합니다.                                    |

`||` 연산자는 기본값을 제공하는 데 사용됩니다:

```yaml
${{ inputs.name || "default" }}
```

`inputs.name`이(가) 비어 있지 않은 문자열이면 그대로 반환됩니다. 비어 있거나 null이면 `"default"`이(가) 반환됩니다.

### 단항 연산자 {#unary-operators}

| 연산자 | 설명    | 예제          | 결과  |
|----------|----------------|------------------|---------|
| `+`      | 단항 플러스     | `${{ +5 }}`      | `5`     |
| `-`      | 단항 부정 | `${{ -5 }}`      | `-5`    |
| `!`      | 논리 NOT    | `${{ !true }}`   | `false` |

### 연산자 우선순위 {#operator-precedence}

연산자는 가장 높은 우선순위부터 가장 낮은 우선순위 순서로 나열됩니다. 같은 행의 연산자는 같은 우선순위를 갖습니다. 모든 이진 연산자는 왼쪽 결합입니다.

| 우선순위  | 연산자                        |
|-------------|----------------------------------|
| 7(최상위) | `.`, `[]`, `()`                  |
| 6           | `+`, `-`, `!`                    |
| 5           | `*`, `/`, `%`                    |
| 4           | `+`, `-`                         |
| 3           | `==`, `!=`, `<`, `<=`, `>`, `>=` |
| 2           | `&&`                             |
| 1(최하위)  | `\|\|`                           |

괄호를 사용하여 우선순위를 재정의합니다:

```yaml
${{ (1 + 2) * 3 }}
```

## 데이터 구조 {#data-structures}

### 배열 {#arrays}

대괄호 표기법으로 배열을 만듭니다. 요소는 모든 유형일 수 있으며 유형을 혼합할 수 있습니다. 후행 쉼표를 사용할 수 있습니다.

```yaml
${{ [1, 2, 3] }}
${{ ["a", 1, true, null] }}
${{ [] }}
```

### 개체 {#objects}

중괄호 표기법으로 개체를 만듭니다. 키는 문자열로 평가되어야 합니다. 값은 모든 유형일 수 있습니다. 후행 쉼표는 허용됩니다.

```yaml
${{ {name: "runner", version: 1} }}
${{ {"string-key": true} }}
${{ {} }}
```

개체 키로 사용되는 단순 식별자는 변수 참조가 아닌 문자열 리터럴로 처리됩니다. 변수를 키로 사용하려면 괄호로 감싸세요:

```yaml
${{ {name: "Alice"} }}           # "name" is the string "name", not a variable reference
${{ {(obj.prop): "value"} }}     # key is the value of obj.prop, which must be a string
```

## 속성 액세스 {#property-access}

### 점 표기법 {#dot-notation}

점 표기법으로 개체 속성에 액세스합니다:

```yaml
${{ env.HOME }}
${{ steps.build.outputs.artifact_path }}
```

### 대괄호 표기법 {#bracket-notation}

인덱스로 배열 요소에 액세스하거나 문자열 키로 개체 속성에 액세스합니다:

```yaml
${{ my_array[0] }}
${{ my_object["property-name"] }}
```

속성 이름에 하이픈과 같은 특수 문자가 포함되어 있으면 대괄호 표기법이 필요합니다.

### 연결 {#chaining}

속성 액세스 및 함수 호출을 연결합니다:

```yaml
${{ steps.build.outputs.items[0] }}
```

## 함수 호출 {#function-calls}

괄호를 사용하여 이름으로 함수를 호출합니다:

```yaml
${{ str(42) }}
${{ num("3.14") }}
```

## 참성 {#truthiness}

논리 연산자 및 `!` 연산자는 다음 참성 규칙을 사용합니다:

| 형식    | 참일 때             | 거짓일 때        |
|---------|-------------------------|-------------------|
| 부울 | `true`                  | `false`           |
| 문자열  | `0`보다 큽니다. | 빈 문자열 `""` |
| 숫자  | `0` 아님                 | `0`               |
| 배열   | `0`보다 큽니다. | 빈 배열 `[]`  |
| 개체  | `0`보다 큽니다. | 빈 개체 `{}` |
| Null    | 절대 안 됨                   | 항상            |

## 기본 제공 함수 {#built-in-functions}

### `str(value)` {#strvalue}

모든 값을 문자열 표현으로 변환합니다.

```yaml
${{ str(42) }}       # "42"
${{ str(true) }}     # "true"
${{ str(null) }}     # "<null>"
```

### `num(value)` {#numvalue}

문자열을 숫자로 변환합니다. 문자열은 유효한 숫자 표현이어야 합니다.

```yaml
${{ num("42") }}     # 42
${{ num("3.14") }}   # 3.14
```

### `bool(value)` {#boolvalue}

모든 값을 [참성](#truthiness)을 기반으로 부울로 변환합니다.

```yaml
${{ bool("hello") }}  # true
${{ bool("") }}       # false
${{ bool(0) }}        # false
${{ bool(1) }}        # true
```

## 예약된 단어 {#reserved-words}

다음 단어는 예약되어 있으며 식별자로 사용할 수 없습니다. 이들은 잠재적인 향후 언어 기능을 위해 예약되어 있습니다.

`array`, `as`, `break`, `case`, `const`, `continue`, `default`, `else`, `fallthrough`, `float`, `for`, `func`, `function`, `goto`, `if`, `import`, `in`, `int`, `let`, `loop`, `map`, `namespace`, `number`, `object`, `package`, `range`, `return`, `string`, `struct`, `switch`, `type`, `var`, `void`, `while`

키워드 `null`, `true` 및 `false`도 리터럴 값으로 예약되어 있습니다.

## 예제 {#examples}

### 전략 선택을 사용한 배포 {#deploy-with-strategy-selection}

```yaml
deploy job:
  when: manual
  inputs:
    environment:
      default: staging
      options: [staging, production]
      description: Target deployment environment
    strategy:
      default: rolling
      options: [rolling, blue-green, canary]
      description: Deployment strategy
    replicas:
      type: number
      default: 3
      description: Number of replicas to deploy
  image: ${{ job.inputs.environment == "production" && "deploy-tools:stable" || "deploy-tools:latest" }}
  script:
    - 'echo "Deploying to ${{ job.inputs.environment }} using ${{ job.inputs.strategy }}"'
    - deploy
        --env ${{ job.inputs.environment }}
        --strategy ${{ job.inputs.strategy }}
        --replicas ${{ str(job.inputs.replicas) }}
```

### 부울 작업 입력으로부터 조건부 플래그 {#conditional-flags-from-boolean-job-inputs}

```yaml
test_job:
  inputs:
    coverage:
      type: boolean
      default: false
    verbose:
      type: boolean
      default: false
  script:
    - pytest ${{ job.inputs.verbose && "-v" || "" }} ${{ job.inputs.coverage && "--cov=src" || "" }}
```

### 작업 변수에서 이미지 참조 빌드 {#building-an-image-reference-from-job-variables}

```yaml
build_job:
  run:
    - name: build
      func: ./docker-build
      inputs:
        image: ${{ vars.CI_REGISTRY + "/" + vars.CI_PROJECT_PATH + ":" + vars.CI_PIPELINE_IID }}
```

### 게이트 계속 {#continue-gate}

```yaml
security_scan_job:
  run:
    - name: scan
      func: ./security-scan
    - name: gate
      func: ./quality-gate
      inputs:
        should_proceed: ${{ steps.scan.outputs.critical == 0 && steps.scan.outputs.high < 5 }}
```

### 버전 관리 {#version-management}

```yaml
increment_version_job:
  run:
    - name: current
      func: ./find-version
    - name: bump
      func: ./bump-version
      inputs:
        new_version: ${{ str(steps.current.outputs.major + 1) + ".0.0" }}
```

### 환경별 구성 {#environment-specific-configuration}

```yaml
deploy_job:
  run:
    - name: deploy
      func: ./deploy
      inputs:
        registry: ${{ (vars.CI_COMMIT_REF_NAME == "main" && "prod.registry.com") || "staging.registry.com" }}
        replicas: ${{ (vars.CI_COMMIT_REF_NAME == "main" && 5) || 2 }}
```

### A/B 테스트 구성 {#configure-ab-testing}

```yaml
configure_job:
  run:
    - name: configure_ab
      func: ./traffic-split
      inputs:
        variants: |
          ${{ [
            {name: "control", use_new_feature: false, weight: 90},
            {name: "experiment", use_new_feature: true, weight: 10}
          ] }}
```
