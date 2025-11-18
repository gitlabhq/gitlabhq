---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CodeClimateベースのコード品質スキャンを設定する（非推奨）
---

<!--- start_remove The following content will be removed on remove_date: '2026-08-15' -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

この機能は、GitLab 17.3で[非推奨](../../update/deprecations.md#codeclimate-based-code-quality-scanning-will-be-removed)となり、19.0で削除される予定です。代わりに、[サポートされているツールの結果を直接統合](code_quality.md#import-code-quality-results-from-a-cicd-job)してください。これは破壊的な変更です。

{{< /alert >}}

Code Qualityには、組み込みのCI/CDテンプレート`Code-Quality.gitlab-ci.yaml`も含まれています。このテンプレートは、オープンソースのCodeClimateスキャンエンジンに基づいてスキャンを実行します。

CodeClimateエンジンは以下を実行します:

- [サポート対象の言語セット](https://docs.codeclimate.com/docs/supported-languages-for-maintainability)の基本的な保守性チェック。
- ソースコードを分析するための、オープンソーススキャナーをラップした設定可能な[プラグイン](https://docs.codeclimate.com/docs/list-of-engines)のセット。

## CodeClimateベースのスキャンを有効にする {#enable-codeclimate-based-scanning}

前提要件: 

- GitLab CI/CD設定（`.gitlab-ci.yml`）には、`test`ステージを含める必要があります。
- インスタンスRunnerを使用している場合、コード品質ジョブは、[Docker-in-Dockerワークフロー](../docker/using_docker_build.md#use-docker-in-docker)用に構成する必要があります。このワークフローを使用する場合、`/builds`ボリュームをレポートの保存を許可するようにマップする必要があります。
- プライベートRunnerを使用している場合は、コード品質分析をより効率的に実行するために推奨される[代替設定](#use-private-runners)を使用する必要があります。
- Runnerには、生成されたコード品質ファイルを格納するのに十分なディスク容量が必要です。たとえば、[GitLabプロジェクト](https://gitlab.com/gitlab-org/gitlab)では、ファイルのサイズは約7 GBです。

コード品質を有効にするには、次のいずれかを実行します:

- [Auto DevOps](../../topics/autodevops/_index.md)を有効にします。これには[Autoコード品質](../../topics/autodevops/stages.md#auto-code-quality)が含まれます。

- [コード品質テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Code-Quality.gitlab-ci.yml)を`.gitlab-ci.yml`ファイルに含めます。

  例: 

  ```yaml
     include:
     - template: Jobs/Code-Quality.gitlab-ci.yml
  ```

  コード品質がパイプラインで実行されるようになりました。

{{< alert type="warning" >}}

セルフマネージドのGitLabでは、悪意のあるアクターがコード品質ジョブ定義を侵害した場合、Runnerホストで特権Dockerコマンドを実行する可能性があります。適切なアクセス制御ポリシーを持つことで、信頼できるアクターのみにアクセス制御を許可することにより、この脅威ベクターを軽減できます。

{{< /alert >}}

## CodeClimateベースのスキャンを無効にする {#disable-codeclimate-based-scanning}

`code_quality`ジョブは、`$CODE_QUALITY_DISABLED` CI/CD変数が存在する場合、実行されません。変数の定義方法の詳細については、[GitLab CI/CD変数](../variables/_index.md)を参照してください。

コード品質を無効にするには、次のいずれかの`CODE_QUALITY_DISABLED`という名前のカスタムCI/CD変数を作成します:

- [プロジェクト全体](../variables/_index.md#for-a-project)。
- [単一のパイプライン](../pipelines/_index.md#run-a-pipeline-manually)。

## CodeClimate分析プラグインを構成する {#configure-codeclimate-analysis-plugins}

デフォルトでは、`code_quality`ジョブは、CodeClimateが以下を実行するように構成します:

- [特定のプラグインセット](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml.template?ref_type=heads)を使用します。
- これらのプラグインに[デフォルトの設定](https://gitlab.com/gitlab-org/ci-cd/codequality/-/tree/master/codeclimate_defaults?ref_type=heads)を使用します。

より多くの言語をスキャンするには、より多くの[プラグイン](https://docs.codeclimate.com/docs/list-of-engines)を有効にできます。また、`code_quality`ジョブがデフォルトで有効にするプラグインを無効にすることもできます。

たとえば、[SonarJavaアナライザー](https://docs.codeclimate.com/docs/sonar-java)を使用するには、次の手順に従います:

1. `.codeclimate.yml`という名前のファイルをリポジトリのルートに追加します。
1. `.codeclimate.yml`ファイルに、リポジトリのルートに対するプラグインの[イネーブルメントコード](https://docs.codeclimate.com/docs/sonar-java#enable-the-plugin)を追加します:

   ```yaml
   version: "2"
   plugins:
     sonar-java:
       enabled: true
   ```

これにより、プロジェクトに含まれる[デフォルト`.codeclimate.yml`](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml.template)の`plugins:`セクションにSonarJavaが追加されます。

`plugins:`セクションへの変更は、デフォルト`.codeclimate.yml`の`exclude_patterns`セクションには影響しません。詳細については、Code Climateの[ファイルとフォルダーの除外](https://docs.codeclimate.com/docs/excluding-files-and-folders)に関するドキュメントを参照してください。

## スキャンジョブ設定をカスタマイズする {#customize-scan-job-settings}

GitLab CI/CD YAMLで[CI/CD変数](#available-cicd-variables)を設定することで、`code_quality`スキャンジョブの動作を変更できます。

コード品質ジョブを設定するには、次の手順に従います:

1. テンプレートの組み込み後、コード品質ジョブと同じ名前でジョブを宣言します。
1. ジョブのスタンザで追加のキーを指定します。

例については、[HTML形式での出力のダウンロード](#output-in-only-html-format)を参照してください。

### 利用可能なCI/CD変数 {#available-cicd-variables}

使用可能なCI/CD変数を定義することで、コード品質をカスタマイズできます:

| CI/CD変数                  | 説明 |
|---------------------------------|-------------|
| `CODECLIMATE_DEBUG`             | [Code Climateデバッグモード](https://github.com/codeclimate/codeclimate#environment-variables)を有効にするように設定します。 |
| `CODECLIMATE_DEV`               | CLIに認識されていないエンジンを実行できるようにする`--dev`モードを有効にするように設定します。 |
| `CODECLIMATE_PREFIX`            | CodeClimateエンジンのすべての`docker pull`コマンドで使用するプレフィックスを設定します。[オフラインスキャン](https://github.com/codeclimate/codeclimate/pull/948)に役立ちます。詳細については、[プライベートコンテナイメージレジストリの使用](#use-a-private-container-image-registry)を参照してください。 |
| `CODECLIMATE_REGISTRY_USERNAME` | `CODECLIMATE_PREFIX`から解析中されたレジストリドメインのユーザー名を指定するように設定します。 |
| `CODECLIMATE_REGISTRY_PASSWORD` | `CODECLIMATE_PREFIX`から解析中されたレジストリドメインのパスワードを指定するように設定します。 |
| `CODE_QUALITY_DISABLED`         | コード品質ジョブの実行を防止します。 |
| `CODE_QUALITY_IMAGE`            | 完全にプレフィックスが付けられたイメージ名に設定します。イメージはジョブ環境からアクセスできる必要があります。 |
| `ENGINE_MEMORY_LIMIT_BYTES`     | エンジンのメモリ制限を設定します。デフォルトは、: 1,024,000,000バイト。 |
| `REPORT_STDOUT`                 | 通常のレポートファイルを生成する代わりに、`STDOUT`にレポートを印刷するように設定します。 |
| `REPORT_FORMAT`                 | 生成されたレポートファイルの形式を制御するように設定します。`json`または`html`のいずれか。 |
| `SOURCE_CODE`                   | スキャンするソースコードへのパス。クローンされたソースが格納されているディレクトリへの絶対パスである必要があります。 |
| `TIMEOUT_SECONDS`               | `codeclimate analyze`コマンドのエンジンコンテナごとのカスタムタイムアウト。デフォルトは、: 900秒（15分） |

### 出力 {#output}

コード品質は、見つかったイシューの詳細を含むレポートを出力します。このレポートの内容は内部で処理され、UIに結果が表示されます。レポートは、`code_quality`ジョブのジョブアーティファクトとしても出力され、`gl-code-quality-report.json`という名前が付けられます。オプションで、HTML形式でレポートを出力できます。たとえば、GitLab PagesでHTML形式のファイルを公開して、さらに簡単にレビューできます。

#### JSONおよびHTML形式での出力 {#output-in-json-and-html-format}

JSONおよびHTML形式でコード品質レポートを出力するには、追加のジョブを作成します。これには、コード品質を2回実行する必要があります（ファイル形式ごとに1回）。

HTML形式でコード品質レポートを出力するには、`extends: code_quality`を使用して、別のジョブをテンプレートに追加します:

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality_html:
  extends: code_quality
  variables:
    REPORT_FORMAT: html
  artifacts:
    paths: [gl-code-quality-report.html]
```

JSONファイルとHTMLファイルの両方がジョブアーティファクトとして出力されます。HTMLファイルは`artifacts.zip`ジョブアーティファクトに含まれています。

#### HTML形式のみでの出力 {#output-in-only-html-format}

HTML形式でのみコード品質レポートをダウンロードするには、`REPORT_FORMAT`を`html`に設定して、`code_quality`ジョブのデフォルト定義を上書きします。

{{< alert type="note" >}}

これにより、JSON形式のファイルは作成されないため、マージリクエストウィジェット、パイプラインレポート、または変更ビューにコード品質の結果は表示されません。

{{< /alert >}}

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  variables:
    REPORT_FORMAT: html
  artifacts:
    paths: [gl-code-quality-report.html]
```

HTMLファイルは、ジョブアーティファクトとして出力されます。

## マージリクエストパイプラインでのコード品質の使用 {#use-code-quality-with-merge-request-pipelines}

デフォルトのコード品質設定では、`code_quality`ジョブを[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)で実行できません。

マージリクエストパイプラインでコード品質を実行できるようにするには、コード品質`rules`、または[`workflow: rules`](../yaml/_index.md#workflow)を上書きして、現在の`rules`と一致するようにします。

例: 

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  rules:
    - if: $CODE_QUALITY_DISABLED
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event" # Run code quality job in merge request pipelines
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH      # Run code quality job in pipelines on the default branch (but not in other branch pipelines)
    - if: $CI_COMMIT_TAG                               # Run code quality job in pipelines for tags
```

## CodeClimateイメージのダウンロード方法を変更する {#change-how-codeclimate-images-are-downloaded}

CodeClimateエンジンは、それぞれのプラグインを実行するために、コンテナイメージをダウンロードします。デフォルトでは、イメージはDocker Hubからダウンロードされます。イメージソースを変更して、パフォーマンスを向上させたり、Docker Hubのレート制限を回避したり、プライベートレジストリを使用したりできます。

### 依存プロキシを使用してイメージをダウンロードする {#use-the-dependency-proxy-to-download-images}

依存プロキシを使用すると、依存関係をダウンロードするのにかかる時間を短縮できます。

前提要件: 

- プロジェクトのグループで[依存プロキシ](../../user/packages/dependency_proxy/_index.md)が有効になっています。

依存プロキシを参照するには、`.gitlab-ci.yml`ファイルで次の変数を設定します:

- `CODE_QUALITY_IMAGE`
- `CODECLIMATE_PREFIX`
- `CODECLIMATE_REGISTRY_USERNAME`
- `CODECLIMATE_REGISTRY_PASSWORD`

例: 

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  variables:
    ## You must add a trailing slash to `$CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX`.
    CODECLIMATE_PREFIX: $CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX/
    CODECLIMATE_REGISTRY_USERNAME: $CI_DEPENDENCY_PROXY_USER
    CODECLIMATE_REGISTRY_PASSWORD: $CI_DEPENDENCY_PROXY_PASSWORD
```

### 認証でのDocker Hubの使用 {#use-docker-hub-with-authentication}

Docker Hubをコード品質イメージの代替ソースとして使用できます。

前提要件: 

- ユーザー名とパスワードを、プロジェクトの[保護されたCI/CD変数](../variables/_index.md#for-a-project)として追加します。

DockerHubを使用するには、`.gitlab-ci.yml`ファイルで次の変数を設定します:

- `CODECLIMATE_PREFIX`
- `CODECLIMATE_REGISTRY_USERNAME`
- `CODECLIMATE_REGISTRY_PASSWORD`

例: 

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  variables:
    CODECLIMATE_PREFIX: "registry-1.docker.io/"
    CODECLIMATE_REGISTRY_USERNAME: $DOCKERHUB_USERNAME
    CODECLIMATE_REGISTRY_PASSWORD: $DOCKERHUB_PASSWORD
```

### プライベートコンテナイメージレジストリの使用 {#use-a-private-container-image-registry}

プライベートコンテナイメージレジストリを使用すると、イメージのダウンロードにかかる時間を短縮できるだけでなく、外部依存関係を減らすこともできます。コンテナ実行のネストされたメソッドのため、CodeClimateの後続の`docker pull`コマンドが個々のエンジンに渡されるように、レジストリプレフィックスを設定する必要があります。

次の変数は、必要なすべてのイメージのプルに解決できます:

- `CODE_QUALITY_IMAGE`: 完全にプレフィックスが付けられたイメージ名。これは、ジョブ環境からアクセスできる任意の場所に配置できます。独自のコピーをホストするために、ここにGitLabコンテナレジストリを使用できます。
- `CODECLIMATE_PREFIX`: 目的のコンテナイメージレジストリのドメイン。これは、[CodeClimate CLI](https://github.com/codeclimate/codeclimate/pull/948)でサポートされている設定オプションです。これを行うには、次の手順に従います:
  - 末尾にスラッシュ（`/`）を含めてください。
  - `https://`などのプロトコルプレフィックスを含めないでください。
- `CODECLIMATE_REGISTRY_USERNAME`: `CODECLIMATE_PREFIX`から解析中されたレジストリドメインのユーザー名を指定するためのオプションの変数。
- `CODECLIMATE_REGISTRY_PASSWORD`: `CODECLIMATE_PREFIX`から解析中されたレジストリドメインのパスワードを指定するためのオプションの変数。

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  variables:
    CODE_QUALITY_IMAGE: "my-private-registry.local:12345/codequality:0.85.24"
    CODECLIMATE_PREFIX: "my-private-registry.local:12345/"
```

この例は、GitLabコード品質に固有のものです。レジストリミラーを使用したDinDの設定方法に関する一般的な手順については、[Docker-in-Dockerサービスのレジストリミラーを有効にする](../docker/using_docker_build.md#enable-registry-mirror-for-dockerdind-service)を参照してください。

#### 必要なイメージ {#required-images}

次のイメージは、[デフォルトの`.codeclimate.yml`](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml.template)に必要です:

- `codeclimate/codeclimate-structure:latest`
- `codeclimate/codeclimate-csslint:latest`
- `codeclimate/codeclimate-coffeelint:latest`
- `codeclimate/codeclimate-duplication:latest`
- `codeclimate/codeclimate-eslint:latest`
- `codeclimate/codeclimate-fixme:latest`
- `codeclimate/codeclimate-rubocop:rubocop-0-92`

カスタム`.codeclimate.yml`設定ファイルを使用している場合は、指定されたプラグインをプライベートコンテナレジストリに追加する必要があります。

## Runnerの設定を変更する {#change-runner-configuration}

CodeClimateは、分析ステップごとに個別のコンテナを実行します。CodeClimateベースのスキャンを実行できるように、またはより高速に実行できるように、Runnerの設定を調整する必要がある場合があります。

### プライベートRunnerの使用 {#use-private-runners}

プライベートRunnerがある場合は、コード品質のパフォーマンスを向上させるために、この設定を使用する必要があります:

- 特権モードは使用されていません。
- Docker-in-Dockerは使用されていません。
- すべてのCodeClimateイメージを含むDockerイメージはキャッシュされ、後続のジョブのために再フェッチされません。

この代替設定では、ソケットバインディングを使用して、RunnerのDockerデーモンをジョブ環境と共有します。この設定を実装する前に、その[制限事項](../docker/using_docker_build.md#use-docker-socket-binding)を検討してください。

プライベートRunnerを使用するには、次の手順に従います:

1. 新しいRunnerを登録:

   ```shell
   $ gitlab-runner register --executor "docker" \
     --docker-image="docker:cli" \
     --url "https://gitlab.com/" \
     --description "cq-sans-dind" \
     --docker-volumes "/cache"\
     --docker-volumes "/builds:/builds"\
     --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
     --registration-token="<project_token>" \
     --non-interactive
   ```

1. **Optional, but recommended**（推奨）: ジョブアーティファクトがRunnerホストから定期的にパージされるように、ビルドディレクトリを`/tmp/builds`に設定します。このステップをスキップする場合は、デフォルトのビルドディレクトリ（`/builds`）を自分でクリーンアップする必要があります。これを行うには、前のステップで次の2つのフラグを`gitlab-runner register`に追加します。

   ```shell
   --builds-dir "/tmp/builds"
   --docker-volumes "/tmp/builds:/tmp/builds" # Use this instead of --docker-volumes "/builds:/builds"
   ```

   結果として得られる設定:

   ```toml
   [[runners]]
     name = "cq-sans-dind"
     url = "https://gitlab.com/"
     token = "<project_token>"
     executor = "docker"
     builds_dir = "/tmp/builds"
     [runners.docker]
       tls_verify = false
       image = "docker:cli"
       privileged = false
       disable_entrypoint_overwrite = false
       oom_kill_disable = false
       disable_cache = false
       volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock", "/tmp/builds:/tmp/builds"]
       shm_size = 0
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. テンプレートによって作成された`code_quality`ジョブに2つのオーバーライドを適用します:

   ```yaml
   include:
     - template: Jobs/Code-Quality.gitlab-ci.yml

   code_quality:
     services:            # Shut off Docker-in-Docker
     tags:
       - cq-sans-dind     # Set this job to only run on our new specialized runner
   ```

コード品質が標準のDockerモードで実行されるようになりました。

### プライベートRunnerでのCodeClimateルートレス実行 {#run-codeclimate-rootless-with-private-runners}

プライベートRunnerを使用していて、[ルートレスDockerモード](https://docs.docker.com/engine/security/rootless/)でコード品質スキャンを実行する場合は、コード品質が適切に実行されるように、特別な変更が必要です。ソケットバインディングの変更が他のジョブで問題を引き起こす可能性があるため、コード品質ジョブのみを実行するように専用のRunnerが必要になる場合があります。

ルートレスのプライベートRunnerを使用するには、次の手順に従います:

1. 新しいRunnerを登録:

   `/run/user/<gitlab-runner-user>/docker.sock`を、`gitlab-runner`ユーザーのローカル`docker.sock`へのパスに置き換えます。

   ```shell
   $ gitlab-runner register --executor "docker" \
     --docker-image="docker:cli" \
     --url "https://gitlab.com/" \
     --description "cq-rootless" \
     --tag-list "cq-rootless" \
     --locked="false" \
     --access-level="not_protected" \
     --docker-volumes "/cache" \
     --docker-volumes "/tmp/builds:/tmp/builds" \
     --docker-volumes "/run/user/<gitlab-runner-user>/docker.sock:/run/user/<gitlab-runner-user>/docker.sock" \
     --token "<project_token>" \
     --non-interactive \
     --builds-dir "/tmp/builds" \
     --env "DOCKER_HOST=unix:///run/user/<gitlab-runner-user>/docker.sock" \
     --docker-host "unix:///run/user/<gitlab-runner-user>/docker.sock"
   ```

   結果として得られる設定:

   ```toml
   [[runners]]
     name = "cq-rootless"
     url = "https://gitlab.com/"
     token = "<project_token>"
     executor = "docker"
     builds_dir = "/tmp/builds"
     environment = ["DOCKER_HOST=unix:///run/user/<gitlab-runner-user>/docker.sock"]
     [runners.docker]
       tls_verify = false
       image = "docker:cli"
       privileged = false
       disable_entrypoint_overwrite = false
       oom_kill_disable = false
       disable_cache = false
       volumes = ["/cache", "/run/user/<gitlab-runner-user>/docker.sock:/run/user/<gitlab-runner-user>/docker.sock", "/tmp/builds:/tmp/builds"]
       shm_size = 0
       host = "unix:///run/user/<gitlab-runner-user>/docker.sock"
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. テンプレートによって作成された`code_quality`ジョブに次のオーバーライドを適用します:

   ```yaml
   code_quality:
     services:
     variables:
       DOCKER_SOCKET_PATH: /run/user/997/docker.sock
     tags:
       - cq-rootless
   ```

コード品質が標準のDockerモードおよびルートレスで実行されるようになりました。

目標が、コード品質で[ルートレスPodmanを使用してDockerを実行する](https://docs.gitlab.com/runner/executors/docker.html#use-podman-to-run-docker-commands)場合も、同じ設定が必要です。システムで正しい`podman.sock`のパスに`/run/user/<gitlab-runner-user>/docker.sock`を置き換えるようにしてください（例：`/run/user/<gitlab-runner-user>/podman/podman.sock`）。

### KubernetesまたはOpenShiftRunnerの設定 {#configure-kubernetes-or-openshift-runners}

コード品質を使用するには、Dockerコンテナ（Docker-in-Docker）でDockerをセットアップする必要があります。Kubernetes executorは[Docker-in-Dockerをサポート](https://docs.gitlab.com/runner/executors/kubernetes/#using-dockerdind)しています。

Kubernetes executorでコード品質ジョブを実行できるようにするには、次の手順に従います:

- Dockerデーモンとの通信にTLSを使用している場合、executorは[特権モードで実行されている](https://docs.gitlab.com/runner/executors/kubernetes/#other-configtoml-settings)必要があります。さらに、証明書ディレクトリは[ボリュームマップとして指定する](../docker/using_docker_build.md#docker-in-docker-with-tls-enabled-in-kubernetes)必要があります。
- DinDサービスがコード品質ジョブの開始前に完全に起動しない可能性があります。これは、[Kubernetes executorのトラブルシューティング](https://docs.gitlab.com/runner/executors/kubernetes/troubleshooting.html#docker-cannot-connect-to-the-docker-daemon-at-tcpdocker2375-is-the-docker-daemon-running)でドキュメント化されている制限事項です。このイシューを解決するには、`before_script`を使用して、Dockerデーモンが完全に起動するまで待ちます。例については、次のセクションで説明する`.gitlab-ci.yml`ファイルの設定を参照してください。

#### Kubernetes {#kubernetes}

Kubernetesでコード品質を実行するには、次の手順に従います:

- Docker in Dockerサービスは、`config.toml`ファイルでサービスコンテナとして追加する必要があります。
- サービスコンテナ内のDockerデーモンは、コード品質で両方のソケットが必要なため、TCPソケットとUNIXソケットでリッスンする必要があります。
- Dockerソケットは、ボリュームと共有する必要があります。

[Dockerの要件](https://docs.docker.com/reference/cli/docker/container/run/#privileged)により、サービスコンテナに対して特権フラグを有効にする必要があります。

```toml
[runners.kubernetes]

[runners.kubernetes.service_container_security_context]
privileged = true
allow_privilege_escalation = true

[runners.kubernetes.volumes]

[[runners.kubernetes.volumes.empty_dir]]
mount_path = "/var/run/"
name = "docker-sock"

[[runners.kubernetes.services]]
alias = "dind"
command = [
    "--host=tcp://0.0.0.0:2375",
    "--host=unix://var/run/docker.sock",
    "--storage-driver=overlay2"
]
entrypoint = ["dockerd"]
name = "docker:20.10.12-dind"
```

{{< alert type="note" >}}

[GitLab Runner Helmチャート](https://docs.gitlab.com/runner/install/kubernetes.html)を使用している場合は、`values.yaml`ファイルの[`config`フィールド](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration.html)で、以前のKubernetes設定を使用できます。x {{< /alert >}}

パフォーマンス全体が最適な`overlay2`[ストレージドライバー](https://docs.docker.com/storage/storagedriver/select-storage-driver/)を使用するには、次の手順に従います:

- Docker CLIが通信する`DOCKER_HOST`を指定します。
- `DOCKER_DRIVER`変数を空に設定します。

`before_script`セクションを使用して、Dockerデーモンが完全に起動するまで待ちます。GitLab Runner v16.9以降では、[`HEALTHCHECK_TCP_PORT`変数を設定するだけで](https://docs.gitlab.com/runner/executors/kubernetes/#define-a-list-of-services)、これを行うこともできます。

```yaml
include:
  - template: Code-Quality.gitlab-ci.yml

code_quality:
  services: []
  variables:
    DOCKER_HOST: tcp://dind:2375
    DOCKER_DRIVER: ""
  before_script:
    - while ! docker info > /dev/null 2>&1; do sleep 1; done
```

#### OpenShift {#openshift}

OpenShiftの場合は、[GitLab Runner Operator](https://docs.gitlab.com/runner/install/operator.html)を使用する必要があります。サービスコンテナ内のDockerデーモンにストレージを初期化する権限を与えるには、`/var/lib`ディレクトリをボリュームマウントとしてマウントする必要があります。

{{< alert type="note" >}}

`/var/lib`ディレクトリをボリュームマウントとしてマウントできない場合は、`--storage-driver`を代わりに`vfs`に設定できます。`vfs`値を選択した場合、[performance](https://docs.docker.com/storage/storagedriver/select-storage-driver/)に悪影響を与える可能性があります。

{{< /alert >}}

Dockerデーモンの権限を設定するには、次のようにします:

1. この設定テンプレートで`config.toml`ファイルを作成し、Runnerの設定をカスタマイズします:

```toml
[[runners]]

[runners.kubernetes]

[runners.kubernetes.service_container_security_context]
privileged = true
allow_privilege_escalation = true

[runners.kubernetes.volumes]

[[runners.kubernetes.volumes.empty_dir]]
mount_path = "/var/run/"
name = "docker-sock"

[[runners.kubernetes.volumes.empty_dir]]
mount_path = "/var/lib/"
name = "docker-data"

[[runners.kubernetes.services]]
alias = "dind"
command = [
    "--host=tcp://0.0.0.0:2375",
    "--host=unix://var/run/docker.sock",
    "--storage-driver=overlay2"
]
entrypoint = ["dockerd"]
name = "docker:20.10.12-dind"
```

1. [カスタム設定をRunnerに設定します](https://docs.gitlab.com/runner/configuration/configuring_runner_operator.html#customize-configtoml-with-a-configuration-template)。

1. オプション。ビルドポッドに[`privileged`サービスアカウント](https://docs.openshift.com/container-platform/3.11/admin_guide/manage_scc.html)をアタッチします。これは、OpenShiftクラスターのセットアップによって異なります:

   ```shell
   oc create sa dind-sa
   oc adm policy add-scc-to-user anyuid -z dind-sa
   oc adm policy add-scc-to-user -z dind-sa privileged
   ```

1. [`[runners.kubernetes]`セクション](https://docs.gitlab.com/runner/executors/kubernetes/#other-configtoml-settings)で権限を設定します。
1. ジョブの定義はKubernetesの場合と同じままです:

   ```yaml
   include:
   - template: Code-Quality.gitlab-ci.yml

   code_quality:
   services: []
   variables:
     DOCKER_HOST: tcp://dind:2375
     DOCKER_DRIVER: ""
   before_script:
     - while ! docker info > /dev/null 2>&1; do sleep 1; done
   ```

#### ボリュームとDockerストレージ {#volumes-and-docker-storage}

Dockerはすべてのデータを`/var/lib`ボリュームに保存するため、ボリュームが大きくなる可能性があります。Docker-in-Dockerストレージをクラスター全体で再利用するには、代替手段として[永続ボリューム](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)を使用できます。
<!--- end_remove -->
