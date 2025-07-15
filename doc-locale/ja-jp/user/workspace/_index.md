---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Workspaces are virtual sandbox environments for creating and managing your GitLab development environments.
title: ワークスペース
---

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.11で、`remote_development_feature_flag`という名前の[フラグとともに](../../administration/feature_flags.md)[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112397)されました。デフォルトでは無効になっています。
- GitLab 16.0の[GitLab.comおよびGitLab Self-Managedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/issues/391543)。
- GitLab 16.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136744)になりました。機能フラグ`remote_development_feature_flag`は削除されました。

{{< /history >}}

ワークスペースは、GitLabのコード用の仮想サンドボックス環境です。ワークスペースを使用すると、GitLabプロジェクト用の隔離された開発環境を作成および管理できます。これらの環境により、異なるプロジェクトが互いに干渉しないようにすることができます。

各ワークスペースは、独自の依存関係、ライブラリ、ツールで構成され、各プロジェクトの特定のニーズに合わせてカスタマイズできます。

ワークスペースは、最大で約1暦年（`8760`時間）使用できます。この期間を過ぎると、ワークスペースは自動的に終了します。

クリックスルーデモについては、[GitLabのワークスペース](https://tech-marketing.gitlab.io/static-demos/workspaces/ws_html.html)を参照してください。

## ワークスペースとプロジェクト

ワークスペースのスコープはプロジェクトに設定されます。[ワークスペースを作成](configuration.md#create-a-workspace)する場合は、次の手順を実行する必要があります。

- ワークスペースを特定のプロジェクトに割り当てます。
- [devfile](#devfile)を使用してプロジェクトを選択します。

ワークスペースは、現在のユーザー権限によって定義されたアクセスレベルで、GitLab APIとやり取りできます。ユーザー権限が後で取り消された場合でも、実行中のワークスペースにユーザーは引き続きアクセスできます。

### プロジェクトからワークスペースを管理する

{{< history >}}

- GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125331)されました。

{{< /history >}}

プロジェクトからワークスペースを管理するには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. 右上にある**編集**を選択します。
1. ドロップダウンリストの**あなたのワークスペース**で、次の操作を実行できます。
   - 既存のワークスペースを再び起動、停止、または終了する。
   - 新しいワークスペースを作成する。

{{< alert type="warning" >}}

ワークスペースを終了すると、GitLabはそのワークスペース内の保存されていないデータまたはコミットされていないデータをすべて削除します。データを復元することはできません。

{{< /alert >}}

### ワークスペースに関連付けられたリソースの削除

ワークスペースを終了すると、ワークスペースに関連付けられているすべてのリソースが削除されます。実行中のワークスペースに関連付けられているプロジェクト、エージェント、ユーザー、またはトークンを削除すると、次の処理が行われます。

- ワークスペースはユーザーインターフェースから削除されます。
- Kubernetesクラスターでは、実行中のワークスペースリソースは孤立状態になり、自動的に削除されません。

孤立したリソースをクリーンアップするには、管理者はKubernetesでワークスペースを手動で削除する必要があります。

[イシュー414384](https://gitlab.com/gitlab-org/gitlab/-/issues/414384)で、この動作を変更することが提案されています。

## エージェントレベルでワークスペースを管理する

{{< history >}}

- GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/419281)されました。

{{< /history >}}

エージェントに関連付けられているすべてのワークスペースを管理するには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **操作 > Kubernetesクラスター**を選択します。
1. リモート開発用に設定されたエージェントを選択します。
1. **ワークスペース**タブを選択します。
1. リストから、既存のワークスペースを再び起動、停止、または終了できます。

{{< alert type="warning" >}}

ワークスペースを終了すると、GitLabはそのワークスペース内の保存されていないデータまたはコミットされていないデータをすべて削除します。データを復元することはできません。

{{< /alert >}}

### 実行中のワークスペースからエージェントを特定する

複数のエージェントを含むデプロイでは、実行中のワークスペースからエージェントを特定することが必要になる場合があります。

実行中のワークスペースに関連付けられているエージェントを特定するには、次のいずれかのGraphQLエンドポイントを使用します。

- `agent-id`は、エージェントが属するプロジェクトを返します。
- [`Query.workspaces`](../../api/graphql/reference/_index.md#queryworkspaces)は、以下を返します。
  - ワークスペースに関連付けられている[クラスターエージェント](../../api/graphql/reference/_index.md#clusteragent)
  - エージェントが属するプロジェクト

## devfile

ワークスペースには、devfileのサポートが組み込まれています。devfileは、GitLabプロジェクトに必要なツール、言語、ランタイム、その他のコンポーネントを指定して開発環境を定義するファイルです。このファイルを使用して、定義された仕様で開発環境を自動的に設定します。使用するマシンやプラットフォームに関係なく、一貫性のある再現可能な開発環境が作成されます。

ワークスペースは、GitLabのデフォルトのdevfileとカスタムdevfileの両方をサポートしています。

### GitLabのデフォルトのdevfile

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171230)されました。

{{< /history >}}

ワークスペースを作成すると、すべてのプロジェクトにGitLabのデフォルトのdevfileを使用できます。このdevfileの内容は次のとおりです。

```yaml
schemaVersion: 2.2.0
components:
  - name: development-environment
    attributes:
      gl/inject-editor: true
    container:
      image: "registry.gitlab.com/gitlab-org/gitlab-build-images/workspaces/ubuntu-24.04:20250303043223-golang-1.23-docker-27.5.1@sha256:98f36ddf5d7ac53d95a270f5791ab7f50132a4cc87676e22f4f632678d8e15e1"
```

GitLabのデフォルトのdevfileは、すべての開発環境設定に適しているとは限りません。このような場合は、[カスタムdevfile](#custom-devfile)を作成できます。

### カスタムdevfile

特定の開発環境設定が必要な場合は、カスタムdevfileを作成します。プロジェクトのルートディレクトリを基準にして、次の場所にdevfileを定義できます。

```plaintext
- /.devfile.yaml
- /.devfile.yml
- /.devfile/{devfile_name}.yaml
- /.devfile/{devfile_name}.yml
```

### 検証ルール

- `schemaVersion`は[`2.2.0`](https://devfile.io/docs/2.2.0/devfile-schema)である必要があります。
- devfileには、少なくとも1つのコンポーネントが必要です。
- `components`の場合:
  - 名前を`gl-`で始めることはできません。
  - [`container`](#container-component-type)と`volume`のみがサポートされています。
- `commands`の場合、IDを`gl-`で始めることはできません。
- `events`の場合:
  - 名前を`gl-`で始めることはできません。
  - `preStart`のみがサポートされています。
- `parent`、`projects`、および`starterProjects`はサポートされていません。
- `variables`の場合、キーを`gl-`、`gl_`、`GL-`、または`GL_`で始めることはできません。
- `attributes`の場合:
  - `pod-overrides`は、ルートレベルまたは`components`で設定しないでください。
  - `container-overrides`は`components`で設定しないでください。

### `container`コンポーネントタイプ

`container`コンポーネントタイプを使用して、コンテナイメージをワークスペースの実行環境として定義します。ベースイメージ、依存関係、およびその他の設定を指定できます。

`container`コンポーネントタイプは、次のスキーマプロパティのみをサポートします。

| プロパティ       | 説明                                                                                                                    |
|----------------| -------------------------------------------------------------------------------------------------------------------------------|
| `image`        | ワークスペースに使用するコンテナイメージの名前。                                                                          |
| `memoryRequest`| コンテナが使用できるメモリの最小量。                                                                                |
| `memoryLimit`  | コンテナが使用できるメモリの最大量。                                                                                |
| `cpuRequest`   | コンテナが使用できるCPUの最小量。                                                                                   |
| `cpuLimit`     | コンテナが使用できるCPUの最大量。                                                                                   |
| `env`          | コンテナで使用する環境変数。名前を`gl-`で始めることはできません。                                                |
| `endpoints`    | コンテナから公開するポートマッピング。名前を`gl-`で始めることはできません。                                                   |
| `volumeMounts` | コンテナにマウントするストレージボリューム。                                                                                      |

### 設定例

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
```

詳細については、[devfileのドキュメント](https://devfile.io/docs/2.2.0/devfile-schema)を参照してください。その他の例については、[`examples`プロジェクト](https://gitlab.com/gitlab-org/remote-development/examples)を参照してください。

このコンテナイメージはデモのみを目的としています。自分のコンテナイメージを使用するには、「[任意のユーザーID](#arbitrary-user-ids)」を参照してください。

## ワークスペースコンテナの要件

デフォルトでは、ワークスペースは、devfileに定義された`gl/inject-editor`属性を持つコンテナに[GitLab VS Codeフォーク](https://gitlab.com/gitlab-org/gitlab-web-ide-vscode-fork)を挿入して起動します。GitLab VS Codeフォークが挿入されるワークスペースコンテナは、次のシステム要件を満たしている必要があります。

- **システムアーキテクチャ**: AMD64
- **システムライブラリ**:
  - `glibc` 2.28以降
  - `glibcxx` 3.4.25以降

これらの要件は、Debian 10.13とUbuntu 20.04でテスト済みです。詳細については、[VS Codeドキュメント](https://code.visualstudio.com/docs/remote/linux)を参照してください。

## ワークスペースのアドオン

{{< history >}}

- GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385157)されました。

{{< /history >}}

ワークスペースには、VS Code用GitLabワークフロー拡張機能がデフォルトで設定されています。

この拡張機能を使用すると、イシューの表示、マージリクエストの作成、CI/CDパイプラインの管理を行うことができます。この拡張機能は、[GitLab Duoコード提案](../project/repository/code_suggestions/_index.md)や[GitLab Duo Chat](../gitlab_duo_chat/_index.md)などのAI機能も強化します。

詳細については、[VS Code用GitLabワークフロー拡張機能](https://gitlab.com/gitlab-org/gitlab-vscode-extension)を参照してください。

## 拡張機能マーケットプレース

{{< details >}}

- 状態: ベータ

{{< /details >}}

{{< history >}}

- GitLab 16.9で、`allow_extensions_marketplace_in_workspace`という名前の[フラグとともに](../../administration/feature_flags.md)[ベータ](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438491)されました。デフォルトでは無効になっています。
- GitLab 17.6で機能フラグ`allow_extensions_marketplace_in_workspace`が[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/454669)されました。

{{< /history >}}

[拡張機能マーケットプレース](../project/web_ide/_index.md#extension-marketplace)が[有効](../profile/preferences.md#integrate-with-the-extension-marketplace)になっている場合、ワークスペースで使用できます。

拡張機能マーケットプレースは[Open VSX Registry](https://open-vsx.org/)に接続します。

## パーソナルアクセストークン

{{< history >}}

- GitLab 16.4[で導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129715)。
- GitLab 17.2で`api`権限が[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/385157)されました。

{{< /history >}}

[ワークスペースを作成](configuration.md#create-a-workspace)すると、`write_repository`権限と`api`権限が付与されたパーソナルアクセストークンを取得します。このトークンを使用して、ワークスペースの起動時に、最初にプロジェクトのクローンを作成したり、VS Code用GitLabワークフロー拡張機能を設定したりします。

ワークスペースで実行するGit操作は、認証と認可にこのトークンを使用します。ワークスペースを終了すると、トークンは失効します。

ワークスペースでGit認証を行うには、`GIT_CONFIG_COUNT`、`GIT_CONFIG_KEY_n`、および`GIT_CONFIG_VALUE_n`[環境変数](https://git-scm.com/docs/git-config/#Documentation/git-config.txt-GITCONFIGCOUNT)を使用します。GitはGit 2.31でこれらの変数のサポートを追加したため、ワークスペースコンテナで使用するGitバージョンは2.31以降である必要があります。

## クラスター内のポッドのやり取り

ワークスペースは、Kubernetesクラスター内のポッドとして実行されます。GitLabは、ポッドが相互にやり取りする方法に制限を加えません。

この要件があるため、この機能をクラスター内の他のコンテナから隔離することを検討してください。

## ネットワークアクセスとワークスペースの認証

GitLabはAPIを制御できないため、Kubernetesコントロールプレーンへのネットワークアクセスを制限する責任はクライアント側にあります。

ワークスペースの作成者のみが、ワークスペースおよびワークスペースで公開されているすべてのエンドポイントにアクセスできます。ワークスペースの作成者は、OAuthでユーザー認証を行った後にのみ、ワークスペースにアクセスすることが認可されます。

## コンピューティングリソースとボリュームストレージ

ワークスペースを停止すると、GitLabはそのワークスペースのコンピューティングリソースをゼロにスケールダウンします。ただし、ワークスペース用にプロビジョニングされたボリュームは引き続き存在します。

プロビジョニングされたボリュームを削除するには、ワークスペースを終了する必要があります。

## ワークスペースの自動停止と終了

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14910)されました。

{{< /history >}}

デフォルトでは、ワークスペースは自動的に次のように処理されます。

- ワークスペースが最後に起動または再び起動されてから36時間後に停止します。詳細については、[`max_active_hours_before_stop`](settings.md#max_active_hours_before_stop)を参照してください。
- ワークスペースが最後に停止されてから722時間後に終了します。詳細については、[`max_stopped_hours_before_termination`](settings.md#max_stopped_hours_before_termination)を参照してください。

## 任意のユーザーID

コンテナイメージを自分で用意できます。このイメージは、任意のLinuxユーザーIDとして実行できます。

GitLabでは、コンテナイメージのLinuxユーザーIDを予測できません。GitLabは、Linux `root`グループID権限を使用して、コンテナ内でファイルを作成、更新、または削除します。Kubernetesクラスターで使用されるコンテナランタイムは、すべてのコンテナのデフォルトのLinuxグループIDが`0`であることを確認する必要があります。

任意のユーザーIDをサポートしていないコンテナイメージがある場合、ワークスペース内でファイルを作成、更新、または削除することはできません。任意のユーザーIDをサポートするコンテナイメージを作成する場合は、「[任意のユーザーIDをサポートするカスタムワークスペースイメージを作成する](create_image.md)」を参照してください。

詳細については、[OpenShiftのドキュメント](https://docs.openshift.com/container-platform/4.12/openshift_images/create-images.html#use-uid_create-images)を参照してください。

## 関連トピック

- [ワークスペースの問題を解決する](workspaces_troubleshooting.md)
