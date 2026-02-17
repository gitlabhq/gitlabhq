---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: フロー実行を設定する
---

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/477166)されました。

{{< /history >}}

フローはエージェントを使用してタスクを実行します。

- GitLab UIから実行されるフローは、CI/CDを使用します。
- IDEで実行されるフローは、ローカルで実行されます。

CI/CDを使用してフローを実行する環境を設定できます。[独自のRunnerを使用する](#configure-runners)こともできます。

## フローのセキュリティ {#flow-security}

フローがGitLab CI/CDで実行される場合:

- アクセスを制限するために、[コンポジットID](../composite_identity.md)を使用します。
- それらが自由に使用できるツールは、フローの目的に固有のものです。これらのツールには、マージリクエストの作成、または実行環境でのローカルShellコマンドの実行が含まれます。

デフォルトでは、Runner環境はGitLabインスタンスへのネットワークアクセスのみを許可しますが、[これを変更できます](#change-the-default-docker-image)。この分離された環境は、Shellコマンドの実行による意図しない結果から保護します。

GitLab UIでフローが自律的に実行されないようにするために、[フローの実行をオフにする](../../gitlab_duo/turn_on_off.md)ことができます。

## CI/CDの実行を設定する {#configure-cicd-execution}

プロジェクトでエージェントの設定ファイルを作成することにより、CI/CDでフローがどのように実行されるかをカスタマイズできます。

> [!note]このシナリオでは、事前定義されたCI/CD変数は使用できません。

### 設定ファイルを作成する {#create-the-configuration-file}

1. プロジェクトのリポジトリで、`.gitlab/duo/`フォルダーが存在しない場合は作成します。
1. フォルダーに、`agent-config.yml`という名前の設定ファイルを作成します。
1. 目的の設定オプションを追加します（以下のセクションを参照）。
1. ファイルをコミットして、mainブランチにプッシュします。

プロジェクトのCI/CDでフローが実行されると、設定が適用されます。

### デフォルトのDockerイメージを変更する {#change-the-default-docker-image}

デフォルトでは、CI/CDで実行されるすべてのフローは、GitLabが提供する標準のDockerイメージを使用します。このDockerイメージには、[Anthropic Sandbox Runtime（`srt`）](https://github.com/anthropic-experimental/sandbox-runtime)を使用することにより、ネットワーク保護が自動的に含まれています。このイメージは、GitLabインスタンスへのアクセスのみを許可するように設定されています。ただし、Dockerイメージを変更して、独自のイメージを代わりに指定できます。独自のイメージは、特定の依存関係またはツールを必要とする複雑なプロジェクトに役立ちます。これを行うと、エージェントはセッションに関連付けられているGitLab Runnerから到達可能な任意のドメインに到達できるようになります。

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

カスタムDockerイメージを使用する場合は、エージェントが正しく機能するために、次のコマンドが使用可能であることを確認してください:

- `git`
- `npm`

ほとんどのベースイメージには、デフォルトでこれらのコマンドが含まれています。ただし、最小限のイメージ（`alpine`バリアントなど）では、明示的にインストールする必要がある場合があります。必要な場合は、[セットアップスクリプトの設定](#configure-setup-scripts)で不足しているコマンドをインストールできます。

さらに、フローの実行中にエージェントが行うツールの呼び出しによっては、他の一般的なユーティリティが必要になる場合があります。

たとえば、alpineベースのイメージを使用する場合:

```yaml
image: python:3.11-alpine
setup_script:
  - apk add --update git nodejs npm
```

### セットアップスクリプトを設定する {#configure-setup-scripts}

フローの実行前に実行されるセットアップスクリプトを定義できます。これは、依存関係のインストール、環境の設定、または必要な初期化の実行に役立ちます。

セットアップスクリプトを追加するには、次の内容を`agent-config.yml`ファイルに追加します:

```yaml
setup_script:
  - apt-get update && apt-get install -y curl
  - pip install -r requirements.txt
  - echo "Setup complete"
```

これらのコマンド:

- メインのワークフローコマンドの前に実行します。
- 指定された順序で実行します。
- 単一のコマンドまたは配列コマンドにすることができます。

### キャッシングを設定する {#configure-caching}

キャッシュを設定すると、実行間でファイルとディレクトリを保持することにより、後続のフロー実行を高速化できます。キャッシュは、`node_modules`やPython仮想環境などの依存関係フォルダーに役立ちます。

#### 基本的なキャッシュの設定 {#basic-cache-configuration}

特定のパスをキャッシュするには、次の内容を`agent-config.yml`ファイルに追加します:

```yaml
cache:
  paths:
    - node_modules/
    - .npm/
```

#### キーによるキャッシュ {#cache-with-keys}

キャッシュキーを使用して、さまざまなシナリオに対してさまざまなキャッシュを作成できます。キャッシュキーは、キャッシュがプロジェクトの状態に基づいていることを保証するのに役立ちます。

##### 文字列キーを使用する {#use-a-string-key}

```yaml
cache:
  key: my-project-cache
  paths:
    - vendor/
    - .bundle/
```

##### ファイルシステムベースのキャッシュキーを使用する {#use-file-based-cache-keys}

ファイルの内容（ロックファイルなど）に基づいて動的なキャッシュキーを作成します。これらのファイルが変更されると、新しいキャッシュが作成されます。これにより、指定されたファイルのSHAチェックサムが生成されます:

```yaml
cache:
  key:
    files:
      - package-lock.json
      - yarn.lock
  paths:
    - node_modules/
```

##### ファイルベースのキーでプレフィックスを使用する {#use-a-prefix-with-file-based-keys}

キャッシュキーファイルに対してコンピューティングされたSHAとプレフィックスを組み合わせます:

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
- キャッシュの`paths`フィールドは必須です。パスのないキャッシュ設定は効果がありません。
- キャッシュキーは、`prefix`フィールドのCI/CD変数をサポートします。

### 設定例の完了 {#complete-configuration-example}

使用可能なすべてのオプションを使用する`agent-config.yml`ファイルの例を次に示します:

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
```

この設定では:

- Python 3.11をベースイメージとして使用します。
- フローを実行する前に、ビルドツールとPythonの依存関係をインストールします。
- Pipと仮想環境ディレクトリをキャッシュします。
- `requirements.txt`または`Pipfile.lock`が変更されたときに、`python-deps`のプレフィックスを使用して新しいキャッシュを作成します。

## Runnerを設定する {#configure-runners}

CI/CDを使用するフローは、Runnerで実行されます。これらのRunnerは、以下を行う必要があります:

- Dockerイメージをサポートする[executor](https://docs.gitlab.com/runner/executors/)を使用します。たとえば、`docker`、`docker-autoscaler`、`kubernetes`などです。`shell`executorはサポートされていません。
- `gitlab--duo`タグがあるため、Runnerは正しいジョブを選択できます。
- インスタンスRunnerであるか、トップレベルグループに割り当てられます。フローは、サブグループまたはプロジェクト用に設定されたRunnerを使用できません。GitLabセルフマネージドでは、`duo_runner_restrictions` FFを無効にすることで、この制限を無効にできます。

さらに、GitLabセルフマネージドのRunner:

- GitLabインスタンス用に設定されたGitLab Duoワークフローサービスへのネットワークトラフィックを許可する必要があります。カスタムモデルを使用していない場合、このトラフィックはポート`443`の`duo-workflow-svc.runway.gitlab.net`に送信されます。
- `registry.gitlab.com`からデフォルトのイメージをダウンロードできるか、[指定したDockerイメージ](#change-the-default-docker-image)にアクセスできる必要があります。
- フローの内容によっては、[特権](https://docs.gitlab.com/runner/security/#reduce-the-security-risk-of-using-privileged-containers)が必要になる場合があります。たとえば、Dockerイメージをビルドするフローには、特権Runnerが必要です。

GitLab.comでは、フローは以下を使用できます:

- [ホストされたRunner](../../../ci/runners/hosted_runners/_index.md)、GitLabが提供します。

Runnerで実行されるフローは、ネットワークとファイルシステムの分離を提供するランタイムサンドボックスで保護できます。サンドボックスのメリットを享受するには、以下を実行する必要があります:

1. [特権](https://docs.gitlab.com/runner/security/#reduce-the-security-risk-of-using-privileged-containers)モードを有効にするには、[Runnerの設定](https://docs.gitlab.com/runner/configuration/advanced-configuration/)で`privileged = true`を設定します。
1. GitLab Duo Agent Platformのデフォルトのベースイメージ[イメージ](#change-the-default-docker-image)を使用します。
