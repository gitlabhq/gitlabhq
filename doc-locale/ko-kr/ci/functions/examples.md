---
stage: Verify
group: CI Functions Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Functions 예제
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  실험적 기능

{{< /details >}}

다음 예제에서는 Google distroless 이미지를 사용하며, `ca-certificates`을(를) 포함하지만 패키지 관리자나 셸이 없습니다. 신뢰할 수 있는 CA 루트 인증서가 설치된 모든 이미지를 사용할 수 있습니다.

## 메시지 에코 {#echo-a-message}

이후 단계에서 사용할 메시지를 에코합니다. 전체 소스 코드는 [echo](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo)를 참조하세요.

함수 정의:

```yaml
spec:
  inputs:
    message:
      type: string
      default: "Hello World!"
      description: "The message to print to stdout"
  outputs:
    message:
      type: string
---
exec:
  command:
    - ${{ func_dir }}/echo
    - --message
    - ${{ inputs.message }}
    - --output-file
    - ${{ output_file }}
```

사용법:

```yaml
my-job:
  image: gcr.io/distroless/static-debian12
  run:
    - name: echo_hi
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
      inputs:
        message: "Hi, ${{ vars.GITLAB_USER_NAME }}"
    - name: echo_repeat
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
      inputs:
        message: "The echo_hi step said: ${{ steps.echo_hi.outputs.message }}"
```

출력:

```shell
Running step name=echo_hi
Hi, Zhang Wei
Running step name=echo_repeat
The echo_hi step said: Hi, Zhang Wei
```

## 임의 값 생성 {#produce-a-random-value}

이후 단계에서 사용할 임의 값을 생성합니다. 전체 소스 코드는 [random](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/random)을(를) 참조하세요.

함수 정의:

```yaml
spec:
  outputs:
    random_value:
      type: string
---
exec:
  command:
    - ${{ func_dir }}/random
    - --output-file
    - ${{ output_file }}
```

사용법:

```yaml
my-job:
  image: gcr.io/distroless/static-debian12
  run:
    - name: random
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/random:1
    - name: print_random
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
      inputs:
        message: "The random value is: ${{ steps.random.outputs.random_value }}"
```

출력:

```shell
Running step name=random
Running step name=print_random
The random value is: DVhV5vcd2BjDDtpV
```

## JSON에서 필드 추출 {#extract-fields-from-json}

`jq`을(를) 실행하여 JSON 입력을 필터링합니다. 전체 소스 코드는 [jq](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/jq)를 참조하세요.

함수 정의:

```yaml
spec:
  inputs:
    filter:
      type: string
      default: "."
    input:
      type: string
      default: "{}"
    input_file:
      type: string
      default: ""
  outputs:
    result:
      type: struct
---
exec:
  command:
    - ${{ func_dir }}/jq-wrapper
    - --func-dir
    - ${{ func_dir }}
    - --filter
    - ${{ inputs.filter }}
    - --input
    - ${{ inputs.input }}
    - --input-file
    - ${{ inputs.input_file }}
    - --output-file
    - ${{ output_file }}
```

사용법:

```yaml
my-job:
  image: gcr.io/distroless/static-debian12
  run:
    - name: jq
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/jq:1
      inputs:
        input: |
          {"users":[
            {"name":"Alice","role":"admin"},
            {"name":"Bob","role":"viewer"},
            {"name":"Carol","role":"admin"}
          ]}
        filter: '[.users[] | select(.role == "admin") | .name]'
    - name: print_admins
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
      inputs:
        message: "Admins: ${{ steps.jq.outputs.result.value }}"
```

출력:

```shell
Running step name=jq
Running step name=print_admins
Admins: ["Alice", "Carol"]
```

## Docker에 인증 {#authenticate-to-docker}

Docker 구성을 생성하고 이를 환경 변수 `DOCKER_AUTH_CONFIG`의 값으로 추가하여 이후 함수에서 사용할 수 있도록 합니다. 전체 소스 코드는 [Docker Auth](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth)를 참조하세요.

함수 정의:

```yaml
spec:
  inputs:
    registry:
      type: string
      default: ""
      description: "registry URL"
    username:
      type: string
      default: ""
      description: "username for auth type"
    password:
      type: string
      default: ""
      description: "password for auth type"
    helper_name:
      type: string
      default: ""
      description: "credential helper name"
    store_name:
      type: string
      default: ""
      description: "default credential store name"
    config_file:
      type: string
      default: ""
      description: "path to existing config.json (default: ~/.docker/config.json)"
  outputs:
    auth:
      type: struct
---
env:
  DOCKER_PASSWORD: ${{ inputs.password }}
exec:
  work_dir: ${{ func_dir }}
  command:
    - ${{ func_dir }}/docker-auth
    - --registry
    - ${{ inputs.registry }}
    - --username
    - ${{ inputs.username }}
    - --helper-name
    - ${{ inputs.helper_name }}
    - --store-name
    - ${{ inputs.store_name }}
    - --config
    - ${{ inputs.config_file }}
    - --output-file
    - ${{ output_file }}
    - --export-file
    - ${{ export_file }}
```

사용법:

```yaml
build-image:
  image: gcr.io/distroless/static-debian12
  run:
    - name: auth_to_my_registry
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth:1
      inputs:
        registry: my.registry.com
        username: ${{ vars.MY_REGISTRY_USER }}
        password: ${{ vars.MY_REGISTRY_PASSWORD }}
    - name: my_func
      func: my.registry.com/my-function:latest  # requires auth to fetch an image
```

출력:

```shell
Running step name=auth_to_my_registry
added basic auth for registry my.registry.com
docker auth configuration complete
Running step name=my_func
...
```
