---
stage: Verify
group: CI Functions Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Functionsの例
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

以下の例では、`ca-certificates`を含むGoogleのディストロレスイメージを使用していますが、パッケージマネージャーやShellは搭載されていません。信頼されたCAルート証明書がインストールされているイメージを使用できます。

## メッセージをエコーする {#echo-a-message}

後続のステップで使用するメッセージをエコーします。完全なソースコードについては、[echo](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo)を参照してください。

関数定義:

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

使用法:

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

出力:

```shell
Running step name=echo_hi
Hi, Zhang Wei
Running step name=echo_repeat
The echo_hi step said: Hi, Zhang Wei
```

## ランダム値を生成する {#produce-a-random-value}

後続のステップで使用するランダム値を生成します。完全なソースコードについては、[random](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/random)を参照してください。

関数定義:

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

使用法:

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

出力:

```shell
Running step name=random
Running step name=print_random
The random value is: DVhV5vcd2BjDDtpV
```

## JSONからフィールドを抽出する {#extract-fields-from-json}

JSON入力をフィルタリングするために`jq`を実行します。完全なソースコードについては、[jq](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/jq)を参照してください。

関数定義:

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

使用法:

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

出力:

```shell
Running step name=jq
Running step name=print_admins
Admins: ["Alice", "Carol"]
```

## Dockerに認証する {#authenticate-to-docker}

Docker設定を作成し、その値を環境変数`DOCKER_AUTH_CONFIG`として追加して、後続の関数で使用します。完全なソースコードについては、[Docker Auth](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth)を参照してください。

関数定義:

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

使用法:

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

出力:

```shell
Running step name=auth_to_my_registry
added basic auth for registry my.registry.com
docker auth configuration complete
Running step name=my_func
...
```
