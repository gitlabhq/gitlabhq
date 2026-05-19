---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
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

ワークスペースは、最大で約1暦年、`8760`時間存在できます。この期間を過ぎると、ワークスペースは自動的に終了します。

クリックスルーデモについては、[GitLabワークスペース](https://tech-marketing.gitlab.io/static-demos/workspaces/ws_html.html)を参照してください。

> [!note]
> ワークスペースは、Kubernetes向けGitLabエージェントサーバー（`agentk`）をサポートするあらゆる`linux/amd64` Kubernetesクラスター上で実行されます。`sudo`コマンドを実行したり、ワークスペース内でコンテナをビルドする必要がある場合、プラットフォーム固有の要件がある可能性があります。
>
> 詳細については、[プラットフォームの互換性](configuration.md#platform-compatibility)を参照してください。

## ワークスペースとプロジェクト {#workspaces-and-projects}

ワークスペースのスコープはプロジェクトに設定されます。ワークスペースを作成する際には、以下を行う必要があります:

- ワークスペースを特定のプロジェクトに割り当てます。
- [devfile](#devfile)を使用してプロジェクトを選択します。

ワークスペースは、現在のユーザー権限によって定義されたアクセスレベルで、GitLab APIとやり取りできます。ユーザー権限が後で取り消された場合でも、実行中のワークスペースにユーザーは引き続きアクセスできます。

### プロジェクトからワークスペースを管理する {#manage-workspaces-from-a-project}

{{< history >}}

- GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125331)されました。

{{< /history >}}

プロジェクトからワークスペースを管理するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 右上にある**コード**を選択します。
1. ドロップダウンリストの**あなたのワークスペース**で、次の操作を実行できます:
   - 既存のワークスペースを再起動、停止、または終了します。
   - 新しいワークスペースを作成します。

> [!warning]
> ワークスペースを終了すると、GitLabはそのワークスペース内の保存されていないデータやコミットされていないデータを削除します。データを復元することはできません。

### ワークスペースに関連付けられたリソースを削除する {#deleting-resources-associated-with-a-workspace}

ワークスペースを終了すると、ワークスペースに関連付けられているすべてのリソースが削除されます。プロジェクト、`agentk`、ユーザー、または実行中のワークスペースに関連付けられたトークンを削除すると:

- ワークスペースはユーザーインターフェースから削除されます。
- Kubernetesクラスターでは、実行中のワークスペースリソースは孤立状態になり、自動的に削除されません。

孤立したリソースをクリーンアップするには、管理者はKubernetesでワークスペースを手動で削除する必要があります。

[エピック11452](https://gitlab.com/groups/gitlab-org/-/work_items/11452)は、この動作を変更することを提案しています。

## エージェントレベルでワークスペースを管理する {#manage-workspaces-at-the-agent-level}

{{< history >}}

- GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/419281)されました。

{{< /history >}}

`agentk`に関連付けられているすべてのワークスペースを管理するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**操作** > **Kubernetesクラスター**を選択します。
1. リモート開発用に設定されたエージェントを選択します。
1. **ワークスペース**タブを選択します。
1. リストから、既存のワークスペースを再起動、停止、または終了できます。

> [!warning]
> ワークスペースを終了すると、GitLabはそのワークスペース内の保存されていないデータやコミットされていないデータを削除します。データを復元することはできません。

### 実行中のワークスペースからエージェントを特定する {#identify-an-agent-from-a-running-workspace}

複数の`agentk`デプロイメントを含む環境では、実行中のワークスペースからエージェントを特定したい場合があります。

実行中のワークスペースに関連付けられているエージェントを特定するには、次のいずれかのGraphQLエンドポイントを使用します。

- `agent-id`は、エージェントが属するプロジェクトを返します。
- `Query.workspaces`は以下を返します:
  - ワークスペースに関連付けられたクラスターエージェント。
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

ワークスペースを作成すると、すべてのプロジェクトでGitLabのデフォルトのdevfileを使用できます。このdevfileの内容は次のとおりです。

```yaml
schemaVersion: 2.2.0
components:
  - name: development-environment
    attributes:
      gl/inject-editor: true
    container:
      image: "registry.gitlab.com/gitlab-org/gitlab-build-images/workspaces/ubuntu-24.04:[VERSION_TAG]"
```

> [!note]
> このコンテナの`image`は定期的に更新されます。`[VERSION_TAG]`はプレースホルダーにすぎません。最新バージョンについては、[デフォルトの`default_devfile.yaml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/remote_development/settings/default_devfile.yaml)を参照してください。

ワークスペースのデフォルトイメージには、Ruby、Node.js、Rust、Go、Python、Java、PHP、GCC、およびそれに対応するパッケージマネージャーなどの開発ツールが含まれています。これらのツールは定期的に更新されます。

GitLabのデフォルトのdevfileは、すべての開発環境設定に適しているとは限りません。このような場合は、[カスタムdevfile](#custom-devfile)を作成できます。

### カスタムDevfile {#custom-devfile}

特定の開発環境設定が必要な場合は、カスタムdevfileを作成します。プロジェクトのルートディレクトリを基準にして、次の場所にdevfileを定義できます。

```plaintext
- /.devfile.yaml
- /.devfile.yml
- /.devfile/{devfile_name}.yaml
- /.devfile/{devfile_name}.yml
```

> [!note]
> devfileは`.devfile`フォルダー内に直接配置する必要があります。ネストされたサブフォルダーはサポートされていません。たとえば、`.devfile/subfolder/devfile.yaml`は認識されません。

### 検証ルール {#validation-rules}

- devfileのサイズは3 MBを超えてはなりません。

| プロパティ        | 明示的なルール                                                                                                                                                                                                                                                                                                          |
|-----------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `schemaVersion` | [`2.2.0`](https://devfile.io/docs/2.2.0/devfile-schema)である必要があります。                                                                                                                                                                                                                                                       |
| `components`    | \- devfileには少なくとも1つのコンポーネントが必要です。<br/>\- 名前は`gl-`で始まってはいけません。<br/>- `container`と`volume`のみがサポートされています。<br/>- `mountSources`と`sourceMapping`はサポートされていません。                                                                                                                  |
| `commands`      | \- IDは`gl-`で始まってはいけません。<br/>- `exec`と`apply`コマンドタイプのみがサポートされています。<br/>- `exec`コマンドの場合、以下のオプションのみがサポートされます。`commandLine`、`component`、`label`、および`hotReloadCapable`。<br/>- `hotReloadCapable`が`exec`コマンドに対して指定されている場合、`false`に設定する必要があります。 |
| `events`        | \- 名前は`gl-`で始まってはいけません。<br/>- `preStart`と`postStart`のみがサポートされています。<br/>\- Devfileの標準では、execコマンドを`postStart`イベントにのみリンクできます。applyコマンドを使用したい場合は、`preStart`イベントを使用する必要があります。                                                                        |
| `parent`        | サポートされていません。                                                                                                                                                                                                                                                                                                      |
| `projects`           | サポートされていません。                                                                                                                                                                                                                                                                                                      |
| `starterProjects`     | サポートされていません。                                                                                                                                                                                                                                                                                                      |
| `variables`  | キーは`gl-`、`gl_`、`GL-`、または`GL_`で始まってはいけません。                                                                                                                                                                                                                                                                |
| `attributes`       | - `pod-overrides`はルートレベルまたは`components`に設定してはいけません。<br/>- `container-overrides`は`components`に設定してはいけません。                                                                                                                                                                                   |

### `container`コンポーネントタイプ {#container-component-type}

`container`コンポーネントタイプを使用して、コンテナイメージをワークスペースの実行環境として定義します。ベースイメージ、依存関係、およびその他の設定を指定できます。

`container`コンポーネントタイプは、次のスキーマプロパティのみをサポートします。

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
| `command`            | コンテナのエントリポイントをオーバーライドするコマンド。[`overrideCommand`属性](#overridecommand-attribute)を参照してください。 |
| `args`               | コンテナのコマンドに対する引数。[`overrideCommand`属性](#overridecommand-attribute)を参照してください。 |

**脚注**: 

1. `image`プロパティにカスタムコンテナイメージを作成する場合、[ワークスペースベースイメージ](#workspace-base-image)を基盤として使用できます。これには、SSHアクセス、ユーザー権限、およびワークスペースの互換性に関する重要な設定が含まれています。ベースイメージを使用しない場合は、カスタムイメージがすべてのワークスペース要件を満たしていることを確認してください。

#### `overrideCommand`属性 {#overridecommand-attribute}

`overrideCommand`属性は、ワークスペースがコンテナのエントリポイントをどのように処理するかを制御するブール値です。この属性は、コンテナの元のエントリポイントが保持されるか、キープアライブコマンドに置き換えられるかを決定します。

`overrideCommand`のデフォルト値は、コンポーネントのタイプによって異なります:

- 属性が`gl/inject-editor: true`のメインコンポーネント: 指定されていない場合、`true`にデフォルト設定されます。
- その他すべてのコンポーネント: 指定されていない場合、`false`にデフォルト設定されます。

`true`の場合、コンテナのエントリポイントはコンテナを実行し続けるために`tail -f /dev/null`に置き換えられます。`false`の場合、コンテナはdevfileコンポーネントの`command`/`args`、またはビルド済みコンテナイメージの`Entrypoint`/`Cmd`のいずれかを使用します。

次の表は、`overrideCommand`がコンテナの動作にどのように影響するかを示しています。明確にするために、以下の用語が表で使用されています:

- Devfileコンポーネント: devfileコンポーネントエントリの`command`と`args`プロパティ。
- コンテナイメージ: OCIコンテナイメージの`Entrypoint`と`Cmd`フィールド。

| `overrideCommand` | Devfileコンポーネント | コンテナイメージ | 結果 |
|-------------------|-------------------|-----------------|--------|
| `true`            | 指定済み         | 指定済み       | 検証エラー: `overrideCommand`が`true`の場合、devfileコンポーネントの`command`/`args`は指定できません。 |
| `true`            | 指定済み         | 未指定   | 検証エラー: `overrideCommand`が`true`の場合、devfileコンポーネントの`command`/`args`は指定できません。 |
| `true`            | 未指定     | 指定済み       | コンテナのエントリポイントは`tail -f /dev/null`に置き換えられます。 |
| `true`            | 未指定     | 未指定   | コンテナのエントリポイントは`tail -f /dev/null`に置き換えられます。 |
| `false`           | 指定済み         | 指定済み       | Devfileコンポーネントの`command`/`args`がエントリポイントとして使用されます。 |
| `false`           | 指定済み         | 未指定   | Devfileコンポーネントの`command`/`args`がエントリポイントとして使用されます。 |
| `false`           | 未指定     | 指定済み       | コンテナイメージの`Entrypoint`/`Cmd`が使用されます。 |
| `false`           | 未指定     | 未指定   | コンテナが途中で終了します（`CrashLoopBackOff`）。<sup>1</sup> |

**脚注**: 

1. ワークスペースを作成する際、プライベートまたは内部レジストリなどからコンテナイメージの詳細にアクセスすることはできません。`overrideCommand`が`false`でDevfileが`command`または`args`を指定しない場合、GitLabはコンテナイメージを検証することも、必要な`Entrypoint`または`Cmd`フィールドをチェックすることもありません。Devfileまたはコンテナのいずれかがこれらのフィールドを指定していることを確認する必要があります。そうしないと、コンテナが途中で終了し、ワークスペースが起動に失敗します。

### ユーザー定義の`postStart`イベント {#user-defined-poststart-events}

devfileでカスタム`postStart`イベントを定義して、ワークスペースの起動後にコマンドを実行できます。これらの`postStart`イベントはワークスペースのアクセシビリティをブロックしません。内部初期化が完了するとすぐにワークスペースが利用可能になります。カスタムの`postStart`コマンドがまだ実行中または実行待機中であっても同様です。

このタイプのイベントは以下に使用します:

- 開発依存関係を設定します。
- ワークスペース環境を設定します。
- 初期化スクリプトを実行します。

`postStart`イベント名は`gl-`で始まってはならず、`exec`タイプのコマンドのみを参照できます。

`postStart`イベントを設定する方法を示す例については、[例の設定](#example-configurations)を参照してください。

#### `postStart`コマンドの作業ディレクトリ {#working-directory-for-poststart-commands}

デフォルトでは、`postStart`コマンドはコンポーネントに応じて異なる作業ディレクトリで実行されます:

- 属性が`gl/inject-editor: true`のメインコンポーネント: コマンドはプロジェクトディレクトリ（`/projects/<project-path>`）で実行されます。
- その他のコンポーネント: コマンドはコンテナのデフォルト作業ディレクトリで実行されます。

`workingDir`をコマンド定義で指定することで、デフォルトの動作をオーバーライドできます:

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

#### `postStart`イベントの進捗を監視する {#monitor-poststart-event-progress}

ワークスペースが`postStart`イベントを実行している間、その進捗を監視し、ワークスペースのログを確認できます。`postStart`スクリプトの進捗を確認するには:

1. ワークスペースでターミナルを開きます。
1. ワークスペースのログディレクトリに移動します:

   ```shell
   cd /tmp/workspace-logs/
   ```

1. 出力ログを表示してコマンド結果を確認します:

   ```shell
   tail -f poststart-stdout.log
   ```

すべての`postStart`コマンド出力は、[ワークスペースログディレクトリ](#workspace-logs-directory)にあるログファイルにキャプチャされます。

### 設定例 {#example-configurations}

次に、devfileの設定例を示します。

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
    attributes:
      overrideCommand: false
    container:
      image: mysql
      command: ["echo"]
      args: ["-n", "user-defined entrypoint command"]
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

> [!note]
> このコンテナの`image`はデモンストレーションのみを目的としています。

その他の例については、[`examples`プロジェクト](https://gitlab.com/gitlab-org/remote-development/examples)を参照してください。

## ワークスペースコンテナの要件 {#workspace-container-requirements}

デフォルトでは、ワークスペースは、devfileに定義された`gl/inject-editor`属性を持つコンテナに[GitLab VS Codeフォーク](https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork)を挿入して起動します。GitLab VS Codeフォークが挿入されるワークスペースコンテナは、次のシステム要件を満たしている必要があります。

- システムアーキテクチャ: AMD64
- システムライブラリ:
  - `glibc` 2.28以降
  - `glibcxx` 3.4.25以降

これらの要件は、Debian 10.13とUbuntu 20.04でテスト済みです。

> [!note]
> GitLabは常にワークスペースツールインジェクターイメージをGitLabレジストリ（`registry.gitlab.com`）からプルします。このイメージをオーバーライドすることはできません。
>
> 他のイメージにプライベートコンテナレジストリを使用している場合、GitLabはこれらの特定のイメージをGitLabレジストリからフェッチします。この要求事項は、オフライン環境など、厳格なネットワークコントロールを備えた環境に影響を与える可能性があります。

## ワークスペースベースイメージ {#workspace-base-image}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab-build-images/-/merge_requests/983)されました。

{{< /history >}}

GitLabは、すべてのワークスペース環境の基盤となるワークスペースベースイメージ（`registry.gitlab.com/gitlab-org/gitlab-build-images:workspaces-base`）を提供します。

ベースイメージには以下が含まれます:

- 安定したLinuxオペレーティングシステムの基盤。
- ワークスペース操作に適したユーザー権限を持つ、事前設定されたユーザー。
- 必須の開発ツールとシステムライブラリ。
- プログラミング言語とツールのバージョン管理。
- リモートアクセス用のSSHサーバー設定。
- 任意のユーザーIDをサポートするためのセキュリティ設定。

ワークスペースベースイメージを使用しない場合は、カスタムワークスペースイメージを作成できます。GitLabがカスタムイメージを適切に初期化して接続できるようにするには、必要な設定コマンドを[ベースイメージDockerfile](https://gitlab.com/gitlab-org/gitlab-build-images/-/blob/master/Dockerfile.workspaces-base)から自身のDockerfileにコピーしてください。

### ベースイメージを拡張する {#extend-the-base-image}

ワークスペースベースイメージに基づいてカスタムワークスペースイメージを作成できます。例: 

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

ワークスペースでは、VS Code用GitLab拡張機能がデフォルトで設定されています。

この拡張機能を使用すると、イシューの表示、マージリクエストの作成、CI/CDパイプラインの管理を行うことができます。この拡張機能は、GitLab Duoコード提案やGitLab Duo ChatなどのAI機能を強化します。

## 拡張機能マーケットプレース {#extension-marketplace}

{{< details >}}

- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 16.9で`allow_extensions_marketplace_in_workspace`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438491)されました。デフォルトでは無効になっています。
- 機能フラグ`allow_extensions_marketplace_in_workspace`は、GitLab 17.6で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/454669)されました。

{{< /history >}}

VS Code拡張機能マーケットプレースは、Web IDEの機能を強化する拡張機能へのアクセスを提供します。デフォルトでは、GitLab Web IDEは[Open VSX Registry](https://open-vsx.org/)に接続します。

詳細については、[VS Code拡張機能マーケットプレースを設定する](../../administration/settings/vscode_extension_marketplace.md)を参照してください。

## パーソナルアクセストークン {#personal-access-token}

{{< history >}}

- GitLab 16.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129715)。
- GitLab 17.2で`api`権限が[追加されました](https://gitlab.com/gitlab-org/gitlab/-/issues/385157)。

{{< /history >}}

ワークスペースを作成すると、`write_repository`および`api` API権限を持つ、365日で期限が切れるパーソナルアクセストークンが発行されます。このトークンは、プロジェクトを初期クローンしたり、ワークスペースを起動したり、VS Code用GitLab拡張機能を設定するために使用されます。

ワークスペースで実行するGit操作は、認証と認可にこのトークンを使用します。ワークスペースを終了すると、トークンは失効します。

ワークスペースでGit認証を行うには、`GIT_CONFIG_COUNT`、`GIT_CONFIG_KEY_n`、および`GIT_CONFIG_VALUE_n`[環境変数](https://git-scm.com/docs/git-config/#Documentation/git-config.txt-GITCONFIGCOUNT)を使用します。これらの変数には、ワークスペースコンテナでGit 2.31以降が必要です。

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

デフォルトでは、ワークスペースは自動的に次のように処理されます。

- ワークスペースが最後に起動または再起動されてから36時間後に停止します。
- ワークスペースが最後に停止されてから722時間後に終了します。

## 任意のユーザーID {#arbitrary-user-ids}

コンテナイメージを自分で用意できます。このイメージは、任意のLinuxユーザーIDとして実行できます。

GitLabでは、コンテナイメージのLinuxユーザーIDを予測できません。GitLabは、Linux `root`グループID権限を使用して、コンテナ内でファイルを作成、更新、または削除します。Kubernetesクラスターで使用されるコンテナランタイムでは、すべてのコンテナのデフォルトのLinuxグループIDが`0`であることを確認する必要があります。

任意のユーザーIDをサポートしていないコンテナイメージがある場合、ワークスペース内でファイルを作成、更新、または削除することはできません。任意のユーザーIDをサポートするコンテナイメージを作成するには、[任意のユーザーIDをサポートするカスタムワークスペースイメージを作成する](create_image.md)を参照してください。

## ワークスペースログディレクトリ {#workspace-logs-directory}

ワークスペースが起動すると、GitLabはさまざまな初期化および起動プロセスからの出力をキャプチャするためのログディレクトリを作成します。

ワークスペースのログは`/tmp/workspace-logs/`に保存されます。

このディレクトリは、ワークスペースの起動進捗を監視し、`postStart`イベント、開発ツール、およびその他のワークスペースコンポーネントに関する問題をトラブルシューティングを行うのに役立ちます。詳細については、[デバッグ`postStart`イベント](workspaces_troubleshooting.md#debug-poststart-events)を参照してください。

### 利用可能なログファイル {#available-log-files}

ログディレクトリには、以下のログファイルが含まれています:

| ログファイル               | 目的                    | 内容 |
|------------------------|----------------------------|---------|
| `poststart-stdout.log` | `postStart`コマンド出力 | ユーザー定義コマンドや内部GitLab起動タスクを含む、すべての`postStart`コマンドの標準出力。 |
| `poststart-stderr.log` | `postStart`コマンドエラー | `postStart`コマンドからのエラー出力と`stderr`。これらのログを使用して、起動スクリプトの失敗をトラブルシューティングを行うことができます。 |
| `start-vscode.log`     | VS Codeサーバー起動     | GitLab VS Codeフォークサーバーの初期化からのログ。 |
| `start-sshd.log`       | SSHデーモン起動         | SSHデーモンの初期化からの出力で、サーバー起動や設定の詳細が含まれます。 |
| `clone-unshallow.log`  | Gitリポジトリ変換  | シャロークローンをフルクローンに変換し、プロジェクトの完全なGit履歴を取得するバックグラウンドプロセスからのログ。 |

> [!note]
> ログファイルは、ワークスペースを再起動するたびに再作成されます。ワークスペースを停止して再起動しても、以前のログファイルは保持されません。

## シャロークローン {#shallow-cloning}

{{< history >}}

- GitLab 18.2で`workspaces_shallow_clone_project`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/543982)されました。デフォルトでは無効になっています。
- GitLab 18.3で[GitLab.comで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/issues/550330)。
- GitLab 18.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/558154)になりました。機能フラグ`workspaces_shallow_clone_project`は削除されました。

{{< /history >}}

ワークスペースを作成すると、GitLabはシャロークローンを使用してパフォーマンスを向上させます。シャロークローンは、完全なGit履歴ではなく最新のコミット履歴のみをダウンロードするため、大規模なリポジトリの初期クローン時間を大幅に短縮します。

ワークスペースが起動した後、Gitはバックグラウンドでシャロークローンをフルクローンに変換します。このプロセスは透過的であり、開発ワークフローに影響を与えません。

## 関連トピック {#related-topics}

- [ワークスペースを作成する](configuration.md#create-a-workspace)
- [ワークスペースの設定](settings.md)
- [ワークスペースのトラブルシューティング](workspaces_troubleshooting.md)
- [GitLab Duoコード提案](../duo_agent_platform/code_suggestions/_index.md)
- [GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md)
- [GraphQL API参照](../../api/graphql/reference/_index.md)
- [Devfileドキュメント](https://devfile.io/docs/2.2.0/devfile-schema)
- [任意のユーザーIDに関するOpenShiftドキュメント](https://docs.openshift.com/container-platform/4.12/openshift_images/create-images.html#use-uid_create-images)
