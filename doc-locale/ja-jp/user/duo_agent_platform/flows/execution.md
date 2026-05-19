---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: フロー実行を設定する
---

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/477166)されました。

{{< /history >}}

フローはエージェントを使用してタスクを実行します。

- GitLab UIから実行されるフローは、CI/CDを使用します。
- IDEで実行されるフローは、ローカルで実行されます。

フローがCI/CD経由で実行される環境を設定できます。また、[独自のRunnerを使用する](#configure-runners) 、および[ジョブで変数を指定する](execution_variables.md)こともできます。

## フローのセキュリティ {#flow-security}

フローがGitLab CI/CDで実行される場合:

- アクセスを制限するために、フローは[複合アイデンティティ](../composite_identity.md)を使用します。
- それらは一時的な[ワークロードパイプライン](../../../ci/pipelines/pipeline_types.md#workload-pipeline)を作成し、フローが完了すると削除されます。
- フローが使用できるツールは、フローの目的に応じて制限されます。これらのツールには、マージリクエストの作成、実行環境でのローカルShellコマンドの実行などが含まれます。

デフォルトでは、フローはGitLabインスタンスにのみネットワークアクセスできます。ネットワークアクセスルールに関する詳細は、[ネットワークポリシーを設定する方法](../environment_sandbox.md#configure-a-network-policy)を参照してください。この分離された環境により、Shellコマンドの実行による意図しない結果から保護されます。

GitLab UIでフローが自律的に実行されるのを防ぐため、[フローの実行をオフ](foundational_flows/_index.md#turn-foundational-flows-on-or-off)にすることができます。

## Executorアーキテクチャ {#executor-architecture}

フローがCI/CDで実行されると、Runnerは次のように動作します:

1. `@gitlab/duo-cli`パッケージをnpmレジストリからダウンロードします。
1. GitLab Duo CLIを実行します。これはWebSocketを使用してGitLab Duoワークフローサービスに接続します。
1. AIモデルの指示に従ってツール（ファイル操作、Gitコマンド）を実行します。

ExecutorのバージョンはGitLabによって管理され、定期的なリリースの一部として更新されます。

> [!note]
> `@gitlab/duo-cli` npmパッケージは、スタンドアロンCLIの使用においては「実験的」と表示されます。フロー内で使用される場合、関連する機能はフローと同じサポートレベルでカバーされます。

## CI/CD実行を設定する {#configure-cicd-execution}

プロジェクト内にエージェント設定ファイルを作成することで、CI/CDにおけるフローの実行方法をカスタマイズできます。

> [!note]
> このシナリオでは、事前定義されたCI/CD変数は使用できません。[利用可能な変数のリスト](execution_variables.md#available-variables)を参照してください。

## 設定ファイルを作成する {#create-the-configuration-file}

1. プロジェクトのリポジトリに`.gitlab/duo/`フォルダーが存在しない場合は作成します。
1. そのフォルダー内に、`agent-config.yml`という名前の設定ファイルを作成します。
1. 必要な設定オプションを追加します（以下のセクションを参照してください）。
1. ファイルをデフォルトブランチにコミットしてプッシュします。

プロジェクトのCI/CDでフローが実行されると、設定が適用されます。

### デフォルトのDockerイメージを変更する {#change-the-default-docker-image}

デフォルトでは、CI/CDで実行されるすべてのフローは、GitLabが提供する標準のDockerイメージを使用します。このDockerイメージには、[Anthropic Sandbox Runtime（`srt`）](https://github.com/anthropic-experimental/sandbox-runtime)を使用したネットワーク保護が自動的に含まれています。Dockerイメージを変更し、独自のものを指定できます。独自のイメージは、特定の依存関係やツールを必要とする複雑なプロジェクトに役立ちます。これを行う場合で、引き続きネットワーク保護を使用したい場合は、お好みのバージョンの`srt`をDockerイメージに追加してください:

```Docker
# Install srt sandboxing with cache clearing and verification
ARG SANDBOX_RUNTIME_VERSION=0.0.20
RUN npm cache clean --force && \
    npm install -g @anthropic-ai/sandbox-runtime@${SANDBOX_RUNTIME_VERSION} && \
    test -s "$(npm root -g)/@anthropic-ai/sandbox-runtime/package.json" && \
    srt --version
```

SRTおよびカスタムイメージへのインストール方法の詳細については、[リモート実行環境サンドボックス](../environment_sandbox.md)を参照してください。

デフォルトのDockerイメージを変更するには、次の内容を`agent-config.yml`ファイルに追加します:

```yaml
image: YOUR_DOCKER_IMAGE
```

例: 

```yaml
image: python:3.11-slim
```

または、Node.jsプロジェクトの場合:

```yaml
image: node:20-alpine
```

#### カスタムイメージの要件 {#custom-image-requirements}

カスタムDockerイメージを使用する場合は、エージェントが正しく機能するために、次のコマンドが利用可能であることを確認してください:

- `git`
- `npm`と互換性のあるNode.jsバージョンを持つ`@gitlab/duo-cli`。詳細については、[GitLab Duo CLIの前提条件](../../gitlab_duo_cli/_index.md#install)を参照してください。

ほとんどのベースイメージには、デフォルトでこれらのコマンドが含まれています。ただし、最小構成イメージ（`alpine`バリアントなど）では、明示的にインストールする必要がある場合があります。必要に応じて、[セットアップスクリプトの設定](#configure-setup-scripts)で不足しているコマンドをインストールできます。

> [!note]
> GitLab 18.9および以前では、カスタムイメージ内のより新しい`git`のバージョンでフローが失敗する可能性があるという[既知のイシュー (587996)](https://gitlab.com/gitlab-org/gitlab/-/work_items/587996)があります。このイシューは、`@gitlab/duo-cli`バージョン8.71.0で解決されました。
>
> `@gitlab/duo-cli`バージョン8.71.0または以前をご利用の場合、新しいGitバージョンでフローが失敗するのを避けるために、以下のいずれかの方法を実行できます:
>
> - カスタムイメージでGitバージョン`2.43.7`または以前のものを使用します
> - `@gitlab/duo-cli`バージョン8.71.0を使用します。

さらに、フローの実行中にエージェントが行うツール呼び出しの内容によっては、その他の一般的なユーティリティが必要になる場合があります。

たとえば、Alpineベースのイメージを使用する場合:

```yaml
image: python:3.11-alpine
setup_script:
  - apk add --update git nodejs npm
```

> [!note]
> カスタムDockerイメージを使用する場合、[環境サンドボックス](../environment_sandbox.md)は、Anthropic Sandbox Runtime (SRT) がカスタムイメージに含まれている場合にのみ適用されます。SRTが含まれていない場合、フローはRunnerから到達可能な任意のドメインと完全なファイルシステムにアクセスできます。カスタムイメージでネットワーク分離が必要な場合は、[イメージにSRTをインストール](../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)し、[ネットワークポリシーを設定](../environment_sandbox.md#configure-a-network-policy)するか、Runner上でネットワークレベルの制御（例: ファイアウォールルールやネットワークポリシー）を設定してください。カスタムイメージに`@gitlab-org/duo-cli` npmパッケージを含める場合、フローの起動時にnpmダウンロード手順がスキップされ、ジョブの起動時間が約15～20秒短縮されます。

### セットアップスクリプトを設定する {#configure-setup-scripts}

フローの実行前に実行されるセットアップスクリプトを定義できます。これは、依存関係のインストール、環境の設定、必要な初期化を行う場合に役立ちます。

セットアップスクリプトを追加するには、次の内容を`agent-config.yml`ファイルに追加します:

```yaml
setup_script:
  - apt-get update && apt-get install -y curl
  - pip install -r requirements.txt
  - echo "Setup complete"
```

これらのコマンドは:

- メインのワークフローコマンドの前に実行されます。
- 指定された順序で実行されます。
- 単一のコマンドまたはコマンド配列として指定できます。

> [!note]
> `setup_script`のユーザーコンテキストはDockerイメージによって異なります。デフォルトのGitLabイメージは`root`として実行されます。カスタムイメージは、イメージの`USER`ディレクティブで定義されたユーザーとして実行されます。お使いの`setup_script`がrootアクセスを必要とする場合（例えばシステムパッケージをインストールするため）、カスタムイメージがそれに応じて設定されていることを確認してください。

### キャッシュを設定する {#configure-caching}

キャッシュを設定すると、実行間でファイルやディレクトリを保持することで、後続のフロー実行を高速化できます。キャッシュは、`node_modules`などの依存関係フォルダーや、Python仮想環境に役立ちます。

#### 基本的なキャッシュ設定 {#basic-cache-configuration}

特定のパスをキャッシュするには、次の内容を`agent-config.yml`ファイルに追加します:

```yaml
cache:
  paths:
    - node_modules/
    - .npm/
```

#### キーを使用したキャッシュ {#cache-with-keys}

キャッシュキーを使用すると、異なるシナリオに応じてさまざまなキャッシュを作成できます。キャッシュキーは、キャッシュがプロジェクトの状態に基づいていることを保証するのに役立ちます。

##### 文字列キーを使用する {#use-a-string-key}

```yaml
cache:
  key: my-project-cache
  paths:
    - vendor/
    - .bundle/
```

##### ファイルシステムベースのキャッシュキーを使用する {#use-file-based-cache-keys}

ファイルの内容（ロックファイルなど）に基づいて動的なキャッシュキーを作成します。これらのファイルが変更されると、新しいキャッシュが作成されます。これにより、指定されたファイルからSHAチェックサムが生成されます:

```yaml
cache:
  key:
    files:
      - package-lock.json
      - yarn.lock
  paths:
    - node_modules/
```

##### ファイルベースのキーとプレフィックスを組み合わせる {#use-a-prefix-with-file-based-keys}

キャッシュキーのファイルから計算されたSHAと、プレフィックスを組み合わせます:

```yaml
cache:
  key:
    files:
      - package-lock.json
    prefix: $CI_JOB_NAME
  paths:
    - node_modules/
    - .npm/
```

この例では、ジョブ名が`test`で、SHAチェックサムが`abc123`の場合、キャッシュキーは`test-abc123`になります。

#### キャッシュの制限事項 {#cache-limitations}

- キャッシュキーの生成には、最大2つのファイルを指定できます。3つ以上のファイルが指定されている場合は、最初の2つのみが使用されます。
- キャッシュの`paths`フィールドは必須です。パスが指定されていないキャッシュ設定は効果がありません。
- キャッシュキーの`prefix`フィールドではCI/CD変数をサポートしています。

### すべてのオプションを使用した設定例 {#complete-configuration-example}

利用可能なすべてのオプションを使用した`agent-config.yml`ファイルの例を示します:

```yaml
# Custom Docker image
image: python:3.11

# Setup script to run before the flow
setup_script:
  - apt-get update && apt-get install -y build-essential
  - pip install --upgrade pip
  - pip install -r requirements.txt

# Cache configuration
cache:
  key:
    files:
      - requirements.txt
      - Pipfile.lock
    prefix: python-deps
  paths:
    - .cache/pip
    - venv/

# Network configuration
network_policy:
  include_recommended_allowed: true
  allow_all_unix_sockets: true
  allowed_domains:
    - my-own-site.com
  denied_domains:
    - malicious.com
```

この設定では:

- Python 3.11をベースイメージとして使用します。
- フローの実行前に、ビルドツールおよびPythonの依存関係をインストールします。
- pipおよび仮想環境のディレクトリをキャッシュします。
- `requirements.txt`または`Pipfile.lock`が変更されたときに、`python-deps`のプレフィックスを使用して新しいキャッシュを作成します。

## Runnerを設定する {#configure-runners}

CI/CDを使用するフローは、Runnerで実行されます。これらのRunnerは、次の条件を満たす必要があります:

- Dockerイメージをサポートする[executor](https://docs.gitlab.com/runner/executors/)を使用していること。たとえば、`docker`、`docker-autoscaler`、`kubernetes`などが該当します。`shell` executorはサポートされていません。
- Runnerが適切なジョブを選択できるように、`gitlab--duo`タグが存在すること。
- インスタンスRunnerであるか、トップレベルグループに割り当てられていること。フローでは、サブグループまたはプロジェクト用に設定されたRunnerは使用できません。GitLab Self-Managedでは、`duo_runner_restrictions` FFを無効にすることで、この制限を無効にできます。

さらに、GitLab Self-ManagedのRunnerでは次の条件があります:

- GitLabインスタンス用に設定されたGitLab Duo Agent Platformサービスへのネットワークトラフィックを許可する必要があります。
  - GitLab Duo Agent Platformサービスには[AIゲートウェイ](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)が付属しています。ご自身でAIゲートウェイをホストし、Agent PlatformのローカルURLを設定しない場合、エージェント型機能は`duo-workflow-svc.runway.gitlab.net`のポート`443`にトラフィックをルーティングします。
- `registry.gitlab.com`からデフォルトのイメージをダウンロードできること、または[指定したDockerイメージ](#change-the-default-docker-image)にアクセスできること。

証明書チェーンに自己署名証明書を含むGitLabインスタンスの場合、GitLab Duo CLIには[追加の設定](../../gitlab_duo_cli/_index.md#custom-ssl-certificates)が必要です。

> [!note]
> RunnerのGitLab Duo Agent Platformサービスへの接続は、GitLabインスタンスを介してルーティングされます。Runnerは`duo-workflow-svc.runway.gitlab.net`に直接接続しません。`duo-workflow-svc.runway.gitlab.net`のポート`443`に関するファイアウォール要件は、GitLabインスタンスに適用され、Runnerには適用されません。お使いのRunnerのネットワーク設定は、GitLabインスタンスへの送信HTTPSトラフィックを許可する必要があります。

GitLab.comでは、フローは以下を使用できます:

- GitLabが提供する[ホストRunner](../../../ci/runners/hosted_runners/_index.md)。

> [!note]
> トップレベルグループで[IPアドレス制限](../../group/access_and_permissions.md#restrict-group-access-by-ip-address)が有効になっている場合、ホストされたRunnerはフローに使用できません。ホストされたRunnerは、クラウドプロバイダーのプールからの動的IPアドレスを使用するため、グループのIP許可リストに追加できません。代わりに、トップレベルグループレベルで`gitlab--duo`タグを使用して独自のグループRunnerを設定し、そのIPアドレスがグループの許可リストに含まれていることを確認してください。

Runnerで実行されるフローは、ネットワークとファイルシステムの分離を実現するランタイムサンドボックスによって保護できます。サンドボックスのメリットを享受するには、次の条件を満たす必要があります:

1. [Runnerの設定](https://docs.gitlab.com/runner/configuration/advanced-configuration/)で`privileged = true`を指定し、[特権](https://docs.gitlab.com/runner/security/#reduce-the-security-risk-of-using-privileged-containers)モードを有効にすること。
1. 以下のいずれかを使用します。
   - GitLab Duo Agent PlatformのデフォルトDockerベースイメージ
   - A [SRTがインストールされたカスタムイメージ](../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)

### Runnerの特権モード {#runner-privileged-mode}

[環境サンドボックス](../environment_sandbox.md)保護を使用する場合、特権モードが必要です。これは、デフォルトのGitLabが提供するイメージ、またはSRTがインストールされたカスタムイメージを使用する場合に適用されます。SRTなしでカスタムDockerイメージを使用する場合、サンドボックスは適用できないため、特権モードは必要ありません。

| 設定 | 特権モードが必要です | サンドボックスが有効 |
|---------------|------------------------|----------------|
| デフォルトイメージ | はい | はい |
| [SRTがインストールされたカスタムイメージ](../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image) | はい | はい |
| SRTなしのカスタムイメージ | いいえ | いいえ |
