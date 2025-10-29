---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: ワークスペースとは、GitLab開発環境を作成および管理するための仮想サンドボックス環境です。
title: ワークスペース
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 機能フラグ`remote_development_feature_flag`は、GitLab 16.0の[GitLab.comとGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/391543)。
- GitLab 16.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136744)になりました。機能フラグ`remote_development_feature_flag`は削除されました。

{{< /history >}}

ワークスペースは、GitLabのコード用の仮想サンドボックス環境です。ワークスペースを使用すると、GitLabプロジェクト用の隔離された開発環境を作成および管理できます。これらの環境により、異なるプロジェクトが互いに干渉しないようにすることができます。

各ワークスペースは、独自の依存関係、ライブラリ、ツールで構成され、各プロジェクトの特定のニーズに合わせてカスタマイズできます。

ワークスペースは、最大で約1暦年（`8760`時間）使用できます。この期間を過ぎると、ワークスペースは自動的に終了します。

クリックスルーデモについては、[GitLabワークスペース](https://tech-marketing.gitlab.io/static-demos/workspaces/ws_html.html)を参照してください。

{{< alert type="note" >}}

ワークスペースは、`linux/amd64` Kubernetesクラスタ上で実行され、Kubernetes向けGitLabエージェント (`agentk`)をサポートします。sudoコマンドの実行、またはワークスペースでのコンテナのビルドと実行が必要な場合は、プラットフォーム固有の要件がある場合があります。

詳細については、[プラットフォームの互換性](configuration.md#platform-compatibility)を参照してください。

{{< /alert >}}

## ワークスペースとプロジェクト {#workspaces-and-projects}

ワークスペースのスコープはプロジェクトに設定されます。ワークスペースを作成する場合は、次の手順を実行する必要があります:

- ワークスペースを特定のプロジェクトに割り当てます。
- [devfile](#devfile)を使用してプロジェクトを選択します。

ワークスペースは、現在のユーザー権限によって定義されたアクセスレベルで、GitLab APIとやり取りできます。ユーザー権限が後で取り消された場合でも、実行中のワークスペースにユーザーは引き続きアクセスできます。

### プロジェクトからワークスペースを管理する {#manage-workspaces-from-a-project}

{{< history >}}

- GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125331)されました。

{{< /history >}}

プロジェクトからワークスペースを管理するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 右上にある**コード**を選択します。
1. ドロップダウンリストの**あなたのワークスペース**で、次の操作を実行できます:
   - 既存のワークスペースを再起動、停止、または終了します。
   - 新しいワークスペースを作成します。

{{< alert type="warning" >}}

ワークスペースを終了すると、GitLabはそのワークスペース内の保存されていないデータまたはコミットされていないデータをすべて削除します。データを復元することはできません。

{{< /alert >}}

### ワークスペースに関連付けられたリソースを削除する {#deleting-resources-associated-with-a-workspace}

ワークスペースを終了すると、ワークスペースに関連付けられているすべてのリソースが削除されます。実行中のワークスペースに関連付けられているプロジェクト、`agentk`、ユーザー、またはトークンを削除すると、次の処理が行われます:

- ワークスペースはUIから削除されます。
- Kubernetesクラスターでは、実行中のワークスペースリソースは孤立状態になり、自動的に削除されません。

孤立したリソースをクリーンアップするには、管理者はKubernetesでワークスペースを手動で削除する必要があります。

[イシュー414384](https://gitlab.com/gitlab-org/gitlab/-/issues/414384)で、この動作を変更することが提案されています。

## エージェントレベルでワークスペースを管理する {#manage-workspaces-at-the-agent-level}

{{< history >}}

- GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/419281)されました。

{{< /history >}}

`agentk`に関連付けられているすべてのワークスペースを管理するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作** > **Kubernetesクラスター**を選択します。
1. リモート開発用に設定されたエージェントを選択します。
1. **ワークスペース**タブを選択します。
1. リストから、既存のワークスペースを再起動、停止、または終了できます。

{{< alert type="warning" >}}

ワークスペースを終了すると、GitLabはそのワークスペース内の保存されていないデータまたはコミットされていないデータをすべて削除します。データを復元することはできません。

{{< /alert >}}

### 実行中のワークスペースからエージェントを特定する {#identify-an-agent-from-a-running-workspace}

複数の`agentk`インストールを含むデプロイでは、実行中のワークスペースからエージェントを特定することが必要になる場合があります。

実行中のワークスペースに関連付けられているエージェントを特定するには、次のいずれかのGraphQLエンドポイントを使用します:

- `agent-id`は、エージェントが属するプロジェクトを返します。
- `Query.workspaces`は、以下を返します:
  - ワークスペースに関連付けられているクラスタエージェント。
  - エージェントが属するプロジェクト。

## devfile {#devfile}

ワークスペースには、devfileのサポートが組み込まれています。devfileは、GitLabプロジェクトに必要なツール、言語、ランタイム、その他のコンポーネントを指定して開発環境を定義するファイルです。このファイルを使用して、定義された仕様で開発環境を自動的に設定します。使用するマシンやプラットフォームに関係なく、一貫性のある再現可能な開発環境が作成されます。

ワークスペースは、GitLabのデフォルトのdevfileとカスタムdevfileの両方をサポートしています。

### GitLabのデフォルトのdevfile {#gitlab-default-devfile}

{{< history >}}

- GitLab 17.8で[Goとともに導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171230)されました。
- GitLab 17.9で[Node、Ruby、Rustのサポートが追加されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185393)。
- GitLab 18.0で[Python、PHP、Java、GCCのサポートが追加されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188199)。

{{< /history >}}

ワークスペースを作成すると、すべてのプロジェクトでGitLabのデフォルトのdevfileを使用できます。このdevfileの内容は次のとおりです:

```yaml
schemaVersion: 2.2.0
components:
  - name: development-environment
    attributes:
      gl/inject-editor: true
    container:
      image: "registry.gitlab.com/gitlab-org/gitlab-build-images/workspaces/ubuntu-24.04:[VERSION_TAG]"
```

{{< alert type="note" >}}

このコンテナ`image`は定期的にアップデートされます。`[VERSION_TAG]`はプレースホルダーです。最新バージョンについては、[デフォルトの`default_devfile.yaml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/remote_development/settings/default_devfile.yaml)を参照してください。

{{< /alert >}}

ワークスペースのデフォルトイメージには、Ruby、Node.js、Rust、Go、Python、Java、PHP、GCC、およびそれに対応するパッケージマネージャーなどの開発ツールが含まれています。これらのツールは定期的に更新されます。

GitLabのデフォルトのdevfileは、すべての開発環境設定に適しているとは限りません。このような場合は、[カスタムdevfile](#custom-devfile)を作成できます。

### カスタムDevfile {#custom-devfile}

特定の開発環境設定が必要な場合は、カスタムdevfileを作成します。プロジェクトのルートディレクトリを基準にして、次の場所にdevfileを定義できます:

```plaintext
- /.devfile.yaml
- /.devfile.yml
- /.devfile/{devfile_name}.yaml
- /.devfile/{devfile_name}.yml
```

{{< alert type="note" >}}

Devfileは、`.devfile`フォルダーに直接配置する必要があります。ネストされたサブフォルダーはサポートされていません。たとえば、`.devfile/subfolder/devfile.yaml`は認識されません。

{{< /alert >}}

### 検証ルール {#validation-rules}

- `schemaVersion`は[`2.2.0`](https://devfile.io/docs/2.2.0/devfile-schema)である必要があります。
- devfileには、少なくとも1つのコンポーネントが必要です。
- Devfileのサイズは3MBを超えてはなりません。
- `components`の場合:
  - 名前を`gl-`で始めることはできません。
  - `container`と`volume`のみがサポートされています。
- `commands`の場合:
  - `gl-`の場合、IDをで始めることはできません。
  - `exec`および`apply`コマンドタイプのみがサポートされています。
  - `exec`コマンドの場合、次のオプションのみがサポートされています：`commandLine`、`component`、`label`、および`hotReloadCapable`。
  - `hotReloadCapable`が`exec`コマンドに指定されている場合、`false`に設定する必要があります。
- `events`の場合:
  - 名前を`gl-`で始めることはできません。
  - `preStart`と`postStart`のみがサポートされています。
  - Devfile標準では、`postStart`イベントにリンクできるのはexecコマンドのみです。Applyコマンドが必要な場合は、`preStart`イベントを使用する必要があります。
- `parent`、`projects`、`starterProjects`はサポートされていません。
- `variables`の場合、キーを`gl-`、`gl_`、`GL-`、または`GL_`で始めることはできません。
- `attributes`の場合:
  - `pod-overrides`は、ルートレベルまたは`components`で設定しないでください。
  - `container-overrides`は`components`で設定しないでください。

### `container`コンポーネントタイプ {#container-component-type}

`container`コンポーネントタイプを使用して、コンテナイメージをワークスペースの実行環境として定義します。ベースイメージ、依存関係、およびその他の設定を指定できます。

`container`コンポーネントタイプは、次のスキーマプロパティのみをサポートします:

| プロパティ             | 説明 |
|----------------------|-------------|
| `image` <sup>1</sup> | ワークスペースに使用するコンテナイメージの名前。 |
| `memoryRequest`      | コンテナが使用できるメモリの最小量。 |
| `memoryLimit`        | コンテナが使用できるメモリの最大量。 |
| `cpuRequest`         | コンテナが使用できるCPUの最小量。 |
| `cpuLimit`           | コンテナが使用できるCPUの最大量。 |
| `env`                | コンテナで使用する環境変数。名前を`gl-`で始めることはできません。 |
| `endpoints`          | コンテナから公開するポートマッピング。名前を`gl-`で始めることはできません。 |
| `volumeMounts`       | コンテナにマウントするストレージボリューム。 |
| `overrideCommand`    | キープアライブコマンドでコンテナエントリポイントをオーバーライドします。デフォルトはコンポーネントタイプによって異なります。 |

**Footnotes**（脚注）: 

1. `image`プロパティのカスタムコンテナイメージを作成する場合は、[ワークスペースベースイメージ](#workspace-base-image)を基盤として使用できます。これには、SSHアクセス、ユーザー権限、およびワークスペースの互換性に関する重要な設定が含まれます。ベースイメージを使用しない場合は、カスタムイメージがすべてのワークスペース要件を満たしていることを確認してください。

#### `overrideCommand`属性 {#overridecommand-attribute}

`overrideCommand`属性は、ワークスペースがコンテナエントリポイントをどのように処理するかを制御するブール値です。この属性は、コンテナの元のエントリポイントを保持するか、キープアライブコマンドで置き換えるかを決定します。

`overrideCommand`のデフォルト値は、コンポーネントタイプによって異なります:

- 属性`gl/inject-editor: true`を持つmainコンポーネント: 指定されていない場合、`true`がデフォルトになります。
- 他のすべてのコンポーネント: 指定されていない場合、`false`がデフォルトになります。

`true`の場合、コンテナを実行状態に保つために、コンテナエントリポイントは`tail -f /dev/null`に置き換えられます。`false`の場合、コンテナは、devfileコンポーネント`command`/`args`またはビルドされたコンテナイメージの`Entrypoint`/`Cmd`のいずれかを使用します。

次の表に、`overrideCommand`がコンテナの動作にどのように影響するかを示します。明確にするために、次の用語が表で使用されています:

- Devfileコンポーネント: Devfileコンポーネントエントリの`command`および`args`プロパティ。
- コンテナイメージ: OCIコンテナイメージの`Entrypoint`および`Cmd`フィールド。

| `overrideCommand` | Devfileコンポーネント | コンテナイメージ。 | 結果: |
|-------------------|-------------------|-----------------|--------|
| `true`            | 指定         | 指定       | 検証エラー: `overrideCommand`が`true`の場合、devfileコンポーネント`command`/`args`は指定できません。 |
| `true`            | 指定         | 未指定   | 検証エラー: `overrideCommand`が`true`の場合、devfileコンポーネント`command`/`args`は指定できません。 |
| `true`            | 未指定     | 指定       | コンテナエントリポイントは`tail -f /dev/null`に置き換えられました。 |
| `true`            | 未指定     | 未指定   | コンテナエントリポイントは`tail -f /dev/null`に置き換えられました。 |
| `false`           | 指定         | 指定       | Devfileコンポーネント`command`/`args`がエントリポイントとして使用されます。 |
| `false`           | 指定         | 未指定   | Devfileコンポーネント`command`/`args`がエントリポイントとして使用されます。 |
| `false`           | 未指定     | 指定       | コンテナイメージの`Entrypoint``Cmd`を使用。 |
| `false`           | 未指定     | 未指定   | コンテナが途中で失敗します (`CrashLoopBackOff`)。<sup>1</sup> |

**Footnotes**（脚注）: 

1. ワークスペースを作成するときに、プライベートレジストリまたは内部レジストリなどから、コンテナイメージの詳細にアクセスすることはできません。`overrideCommand`が`false`で、Devfileが`command`または`args`を指定していない場合、GitLabはコンテナイメージを検証したり、必須の`Entrypoint`または`Cmd`フィールドを確認したりしません。Devfileまたはコンテナのいずれかがこれらのフィールドを指定しているか、コンテナが途中で終了してワークスペースの起動に失敗することを確認する必要があります。

### ユーザー定義の`postStart`イベント {#user-defined-poststart-events}

ワークスペースの起動後にコマンドを実行するには、devfileでカスタム`postStart`イベントを定義できます。これらの`postStart`イベントは、ワークスペースのアクセシビリティをブロックしません。カスタム`postStart`コマンドがまだ実行されているか、実行されるのを待っている場合でも、内部初期化が完了するとすぐにワークスペースが使用可能になります。

このタイプのイベントを使用して、次の操作を行います:

- 開発依存関係を設定します。
- ワークスペース環境を設定します。
- 初期化スクリプトを実行します。

`postStart`イベント名は`gl-`で開始できず、`exec`タイプのコマンドのみを参照できます。

`postStart`イベントを設定する方法を示す例については、[サンプル設定](#example-configurations)を参照してください。

#### `postStart`コマンドの作業ディレクトリ {#working-directory-for-poststart-commands}

デフォルトでは、`postStart`コマンドは、コンポーネントに応じて異なる作業ディレクトリで実行されます:

- 属性`gl/inject-editor: true`を持つmainコンポーネント: コマンドはプロジェクトディレクトリ (`/projects/<project-path>`) で実行されます。
- その他のコンポーネント: コマンドは、コンテナのデフォルトの作業ディレクトリで実行されます。

コマンド定義で`workingDir`を指定することにより、デフォルトの動作をオーバーライドできます:

```yaml
commands:
  - id: install-dependencies
    exec:
      component: tooling-container
      commandLine: "npm install"
      workingDir: "/custom/path"
  - id: setup-project
    exec:
      component: tooling-container
      commandLine: "echo 'Setting up in project directory'"
      # Runs in project directory by default
```

#### `postStart`イベントの進捗を監視 {#monitor-poststart-event-progress}

ワークスペースが`postStart`イベントを実行すると、その進捗を監視し、ワークスペースのログをチェックできます。`postStart`スクリプトの進捗状況を確認するには:

1. ワークスペースでターミナルを開きます。
1. ワークスペースログディレクトリに移動します:

   ```shell
   cd /tmp/workspace-logs/
   ```

1. 出力ログを表示して、コマンドの結果を確認します:

   ```shell
   tail -f poststart-stdout.log
   ```

すべての`postStart`コマンドの出力は、[ワークスペースログディレクトリ](#workspace-logs-directory)にあるログファイルにキャプチャされます。

### 設定例 {#example-configurations}

次に、devfileの設定例を示します:

```yaml
schemaVersion: 2.2.0
variables:
  registry-root: registry.gitlab.com
components:
  - name: tooling-container
    attributes:
      gl/inject-editor: true
    container:
      image: "{{registry-root}}/gitlab-org/remote-development/gitlab-remote-development-docs/ubuntu:22.04"
      env:
        - name: KEY
          value: VALUE
      endpoints:
        - name: http-3000
          targetPort: 3000
  - name: database-container
    container:
      image: mysql
      env:
        - name: MYSQL_ROOT_PASSWORD
          value: "my-secret-pw"
commands:
  # Command 1: Container 1, no working directory (uses project directory)
  - id: install-dependencies
    exec:
      component: tooling-container
      commandLine: "npm install"

  # Command 2: Container 1, with working directory
  - id: setup-environment
    exec:
      component: tooling-container
      commandLine: "echo 'Setting up development environment'"
      workingDir: "/home/gitlab-workspaces"

  # Command 3: Container 2, no working directory (uses container default)
  - id: init-database
    exec:
      component: database-container
      commandLine: "echo 'Database initialized' > db-init.log"

  # Command 4: Container 2, with working directory
  - id: setup-database
    exec:
      component: database-container
      commandLine: "mkdir -p /var/lib/mysql/logs && echo 'DB setup complete' > setup.log"
      workingDir: "/var/lib/mysql"

events:
  postStart:
    - install-dependencies
    - setup-environment
    - init-database
    - setup-database
```

{{< alert type="note" >}}

この`image`は、デモのみを目的としています。

{{< /alert >}}

その他の例については、[`examples`プロジェクト](https://gitlab.com/gitlab-org/remote-development/examples)を参照してください。

## ワークスペースコンテナの要件 {#workspace-container-requirements}

デフォルトでは、ワークスペースは、devfileに定義された`gl/inject-editor`属性を持つコンテナに[GitLab VS Codeフォーク](https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork)を挿入して起動します。GitLab VS Codeフォークが挿入されるワークスペースコンテナは、次のシステム要件を満たしている必要があります:

- システムアーキテクチャ: AMD64
- システムライブラリ:
  - `glibc` 2.28以降
  - `glibcxx` 3.4.25以降

これらの要件は、Debian 10.13とUbuntu 20.04でテスト済みです。

{{< alert type="note" >}}

GitLabは常に、ワークスペースツールインジェクターイメージをGitLabレジストリ (`registry.gitlab.com`) からプルします。このイメージはオーバーライドできません。

他のイメージにプライベートコンテナレジストリを使用している場合でも、GitLabはこれらの特定のイメージをGitLabレジストリからフェッチする必要があります。この要求事項は、オフライン環境など、厳格なネットワークコントロールを備えた環境に影響を与える可能性があります。

{{< /alert >}}

## ワークスペースベースイメージ {#workspace-base-image}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab-build-images/-/merge_requests/983)されました。

{{< /history >}}

GitLabは、すべてのワークスペース環境の基盤として機能するワークスペースベースイメージ (`registry.gitlab.com/gitlab-org/gitlab-build-images:workspaces-base`) を提供します。

ベースイメージには、以下が含まれます:

- 安定したLinuxオペレーティングシステムの基盤。
- ワークスペース操作に適切なユーザー権限が事前に設定されたユーザー。
- 不可欠な開発ツールとシステムライブラリ。
- プログラミング言語およびツールのバージョン管理。
- リモートアクセス用のSSHサーバー設定。
- 任意のユーザーIDサポートのセキュリティ設定。

ワークスペースベースイメージを使用しない場合は、カスタムワークスペースイメージを作成できます。GitLabがカスタムイメージを適切に初期化して接続できるようにするには、必要な設定コマンドを[base image Dockerfile](https://gitlab.com/gitlab-org/gitlab-build-images/-/blob/master/Dockerfile.workspaces-base)から独自のDockerfileにコピーします。

### ベースイメージの拡張 {#extend-the-base-image}

ワークスペースベースイメージに基づいて、カスタムワークスペースイメージを作成できます。次に例を示します: 

```dockerfile
FROM registry.gitlab.com/gitlab-org/gitlab-build-images:workspaces-base

# Install additional tools
RUN sudo apt-get update && sudo apt-get install -y \
    your-additional-package \
    && sudo rm -rf /var/lib/apt/lists/*

# Install specific language versions
RUN mise install python@3.11 && mise use python@3.11
```

## ワークスペースのアドオン {#workspace-add-ons}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/385157)。

{{< /history >}}

ワークスペースには、VS Code用GitLab Workflow拡張機能がデフォルトで設定されています。

この拡張機能を使用すると、イシューの表示、マージリクエストの作成、CI/CDパイプラインの管理を行うことができます。この拡張機能は、GitLab Duoコード提案やGitLab Duo ChatなどのAI機能を強化します。

## 拡張機能マーケットプレース {#extension-marketplace}

{{< details >}}

- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 16.9で`allow_extensions_marketplace_in_workspace`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438491)されました。デフォルトでは無効になっています。
- 機能フラグ`allow_extensions_marketplace_in_workspace`は、GitLab 17.6で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/454669)されました。

{{< /history >}}

VS Code拡張機能マーケットプレースを使用すると、Web IDEの機能を強化する拡張機能にアクセスできます。デフォルトでは、GitLab Web IDEは[Open VSXレジストリ](https://open-vsx.org/)に接続します。

詳細については、[VS Code拡張機能マーケットプレースを設定する](../../administration/settings/vscode_extension_marketplace.md)を参照してください。

## パーソナルアクセストークン {#personal-access-token}

{{< history >}}

- GitLab 16.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129715)。
- GitLab 17.2で`api`権限が[追加されました](https://gitlab.com/gitlab-org/gitlab/-/issues/385157)。

{{< /history >}}

ワークスペースを作成すると、`write_repository`と`api`の権限を持つパーソナルアクセストークンを取得します。このトークンを使用して、ワークスペースの起動時に、最初にプロジェクトのクローンを作成したり、VS Code用GitLab Workflow拡張機能を設定したりします。

ワークスペースで実行するGit操作は、認証と認可にこのトークンを使用します。ワークスペースを終了すると、トークンは失効します。

ワークスペースでGit認証を行うには、`GIT_CONFIG_COUNT`、`GIT_CONFIG_KEY_n`、および`GIT_CONFIG_VALUE_n`[環境変数](https://git-scm.com/docs/git-config/#Documentation/git-config.txt-GITCONFIGCOUNT)を使用します。これらの変数は、ワークスペースコンテナでGit 2.31以降が必要です。

## クラスター内のポッドのやり取り {#pod-interaction-in-a-cluster}

ワークスペースは、Kubernetesクラスター内のポッドとして実行されます。GitLabは、ポッドが相互にやり取りする方法に制限を加えません。

この要求事項があるため、この機能をクラスター内の他のコンテナから隔離することを検討してください。

## ネットワークアクセスとワークスペースの認証 {#network-access-and-workspace-authorization}

GitLabはAPIを制御できないため、Kubernetesコントロールプレーンへのネットワークアクセスを制限する責任はクライアント側にあります。

ワークスペースの作成者のみが、ワークスペースおよびワークスペースで公開されているすべてのエンドポイントにアクセスできます。ワークスペースの作成者は、OAuthでユーザー認証を行った後にのみ、ワークスペースにアクセスすることが認可されます。

## コンピューティングリソースとボリュームストレージ {#compute-resources-and-volume-storage}

ワークスペースを停止すると、GitLabはそのワークスペースのコンピューティングリソースをゼロにスケールダウンします。ただし、ワークスペース用にプロビジョニングされたボリュームは引き続き存在します。

プロビジョニングされたボリュームを削除するには、ワークスペースを終了する必要があります。

## ワークスペースの自動停止と終了 {#automatic-workspace-stop-and-termination}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14910)されました。

{{< /history >}}

デフォルトでは、ワークスペースは自動的に次のように処理されます:

- ワークスペースが最後に起動または再起動されてから36時間後に停止します。
- ワークスペースが最後に停止されてから722時間後に終了します。

## 任意のユーザーID {#arbitrary-user-ids}

コンテナイメージを自分で用意できます。このイメージは、任意のLinuxユーザーIDとして実行できます。

GitLabでは、コンテナイメージのLinuxユーザーIDを予測できません。GitLabは、Linux `root`グループID権限を使用して、コンテナ内でファイルを作成、更新、または削除します。Kubernetesクラスターで使用されるコンテナランタイムでは、すべてのコンテナのデフォルトのLinuxグループIDが`0`であることを確認する必要があります。

任意のユーザーIDをサポートしていないコンテナイメージがある場合、ワークスペース内でファイルを作成、更新、または削除することはできません。任意のユーザーIDをサポートするコンテナイメージを作成する場合は、[任意のユーザーIDをサポートするカスタムワークスペースイメージを作成する](create_image.md)を参照してください。

## ワークスペースのログディレクトリ {#workspace-logs-directory}

ワークスペースが起動すると、GitLabはログディレクトリを作成して、さまざまな初期化プロセスと起動プロセスからの出力をキャプチャします。

ワークスペースのログは`/tmp/workspace-logs/`に保存されます。

このディレクトリは、ワークスペースの起動の進捗状況を監視し、`postStart`イベント、開発ツール、およびその他のワークスペースコンポーネントに関するイシューのトラブルシューティングに役立ちます。詳細については、[Debug `postStart`イベント](workspaces_troubleshooting.md#debug-poststart-events)を参照してください。

### 利用可能なログファイル {#available-log-files}

ログディレクトリには、次のログファイルが含まれています:

| ログファイル               | 目的                    | コンテンツ |
|------------------------|----------------------------|---------|
| `poststart-stdout.log` | `postStart`コマンド出力 | ユーザー定義のコマンドと内部GitLab起動タスクを含む、すべての`postStart`コマンドからの標準出力。 |
| `poststart-stderr.log` | `postStart`コマンドエラー | `postStart`コマンドからのエラー出力と`stderr`。これらのログを使用して、失敗した起動スクリプトのトラブルシューティングを行うことができます。 |
| `start-vscode.log`     | VS Codeサーバーの起動     | GitLab VS Codeフォークしたサーバーの初期化からのログ。 |
| `start-sshd.log`       | SSHデーモンの起動         | サーバーの起動や設定の詳細など、SSHデーモンの初期化からの出力。 |
| `clone-unshallow.log`  | Gitリポジトリの変換  | シャロークローンをフルクローンに変換し、プロジェクトの完全なGit履歴を取得するバックグラウンドプロセスからのログ。 |

{{< alert type="note" >}}

ワークスペースを再起動するたびに、ログファイルが再作成されます。ワークスペースを停止して再起動しても、以前のログファイルは保持されません。

{{< /alert >}}

## シャロークローン {#shallow-cloning}

{{< history >}}

- GitLab 18.2で`workspaces_shallow_clone_project`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/543982)されました。デフォルトでは無効になっています。
- GitLab 18.3の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/550330)になりました。
- GitLab 18.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/558154)になりました。機能フラグ`workspaces_shallow_clone_project`は削除されました。

{{< /history >}}

ワークスペースを作成すると、GitLabはパフォーマンスを向上させるためにシャロークローンを使用します。シャロークローンは、完全なGit履歴ではなく、最新のコミット履歴のみをダウンロードするため、大規模なリポジトリの最初のクローン作成時間を大幅に短縮します。

ワークスペースが起動すると、Gitはバックグラウンドでシャロークローンをフルクローンに変換します。このプロセスは透過的であり、開発ワークフローに影響を与えません。

## 関連トピック {#related-topics}

- [ワークスペースを作成する](configuration.md#create-a-workspace)
- [ワークスペースの設定](settings.md)
- [ワークスペースのトラブルシューティング](workspaces_troubleshooting.md)
- [GitLab Duoコード提案](../project/repository/code_suggestions/_index.md):
- [GitLab Duo Chat](../gitlab_duo_chat/_index.md)
- [GraphQL APIリファレンス](../../api/graphql/reference/_index.md)。
- [Devfileドキュメント](https://devfile.io/docs/2.2.0/devfile-schema)
- [任意のユーザーIDに関するOpenShiftドキュメント](https://docs.openshift.com/container-platform/4.12/openshift_images/create-images.html#use-uid_create-images)
