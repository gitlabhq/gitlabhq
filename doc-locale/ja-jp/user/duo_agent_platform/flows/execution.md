---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: フロー実行を設定する
---

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/477166)されました。

{{< /history >}}

エージェントは、タスクを実行するためにフローを使用します。

- GitLab UIから実行されるフローは、CI/CDを使用します。
- IDEで実行されるフローはローカルで実行されます。

## CI/CD実行の設定 {#configure-cicd-execution}

プロジェクトでエージェントの設定ファイルを作成することにより、CI/CDでフローがどのように実行されるかをカスタマイズできます。

### 設定ファイルを作成 {#create-the-configuration-file}

1. プロジェクトのリポジトリに、`.gitlab/duo/`フォルダーが存在しない場合は作成します。
1. フォルダーに、`agent-config.yml`という名前の設定ファイルを作成します。
1. 目的の設定オプションを追加します（下記のセクションを参照）。
1. ファイルをコミットしてプッシュし、デフォルトブランチにプッシュします。

フローがプロジェクトのCI/CDで実行されると、設定が適用されます。

### デフォルトDockerイメージの変更 {#change-the-default-docker-image}

デフォルトでは、CI/CDで実行されるすべてのフローは、GitLabが提供する標準のDockerイメージを使用します。ただし、Dockerイメージを変更して、独自のDockerイメージを指定することもできます。独自のDockerイメージは、特定の依存関係またはツールを必要とする複雑なプロジェクトに役立ちます。

デフォルトのDockerイメージを変更するには、`agent-config.yml`ファイルに以下を追加します:

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

カスタムDockerイメージを使用する場合は、エージェントが正しく機能するために、次のコマンドを使用できることを確認してください:

- `git`
- `wget`
- `tar`
- `chmod`

ほとんどのベースイメージには、これらのコマンドがデフォルトで含まれています。ただし、最小限のイメージ（`alpine`バリアントなど）では、明示的にインストールする必要がある場合があります。必要に応じて、[セットアップスクリプトの構成](#configure-setup-scripts)で不足しているコマンドをインストールできます。

さらに、フローの実行中にエージェントが行うツール呼び出しによっては、他の一般的なユーティリティが必要になる場合があります。

たとえば、Alpineベースのイメージを使用する場合:

```yaml
image: python:3.11-alpine
setup_script:
  - apk add --no-cache git wget tar bash
```

### セットアップスクリプトの構成 {#configure-setup-scripts}

フローの実行前に実行されるセットアップスクリプトを定義できます。これは、依存関係のインストール、環境の設定、または必要な初期化を実行する場合に役立ちます。

セットアップスクリプトを追加するには、`agent-config.yml`ファイルに以下を追加します:

```yaml
setup_script:
  - apt-get update && apt-get install -y curl
  - pip install -r requirements.txt
  - echo "Setup complete"
```

これらのコマンドは:

- メインのワークフローコマンドの前に実行します。
- 指定された順序で実行します。
- 単一のコマンドまたはコマンドの配列にすることができます。

### キャッシュの設定 {#configure-caching}

キャッシュを設定して、実行間でファイルとディレクトリを保持することにより、後続のフロー実行を高速化できます。キャッシュは、`node_modules`やPython仮想環境などの依存関係フォルダーに役立ちます。

#### 基本的なキャッシュの設定 {#basic-cache-configuration}

特定のパスをキャッシュするには、`agent-config.yml`ファイルに以下を追加します:

```yaml
cache:
  paths:
    - node_modules/
    - .npm/
```

#### キーを使用したキャッシュ {#cache-with-keys}

キーを使用して、さまざまなシナリオに対応するさまざまなキャッシュを作成できます。キーは、キャッシュがプロジェクトの状態に基づいていることを保証するのに役立ちます。

##### 文字列キーの使用 {#use-a-string-key}

```yaml
cache:
  key: my-project-cache
  paths:
    - vendor/
    - .bundle/
```

##### ファイルベースのキャッシュキーの使用 {#use-file-based-cache-keys}

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

プレフィックスと、キャッシュキーファイル用に計算されたSHAを組み合わせます:

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
- キャッシュの`paths`フィールドは必須です。パスのないキャッシュの設定は効果がありません。
- キーは、`prefix`フィールドのCI/CD変数をサポートします。

### 完全な設定の例 {#complete-configuration-example}

これは、使用可能なすべてのオプションを使用する`agent-config.yml`ファイルの例です:

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

- ベースイメージとしてPython 3.11を使用します。
- フローを実行する前に、ビルドツールとPythonの依存関係をインストールします。
- pipと仮想環境ディレクトリをキャッシュします。
- `requirements.txt`または`Pipfile.lock`が変更されると、プレフィックスが`python-deps`の新しいキャッシュが作成されます。
