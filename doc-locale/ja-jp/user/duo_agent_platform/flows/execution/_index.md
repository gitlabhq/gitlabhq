---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo Agent Platformフローを実行するCI/CD環境、セットアップスクリプト、キャッシュ、IDトークン、およびRunnerを設定します。
title: フロー実行を設定する
---

{{< details >}}

- プラン: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/477166)されました。

{{< /history >}}

フローはエージェントを使用してタスクを実行します。

- GitLab UIから実行されるフローは、CI/CDを使用します。
- IDEで実行されるフローは、ローカルで実行されます。

フローがCI/CD経由で実行される環境を設定できます。独自の[Runnerを使用](#configure-runners-to-execute-flows)したり、[ジョブに変数を指定](execution-variables.md)したりすることもできます。

## Executorアーキテクチャ {#executor-architecture}

フローがCI/CDで実行されると、Runnerは次の処理を行います:

1. `@gitlab/duo-cli`パッケージを`npm`レジストリからダウンロードします。
1. GitLab Duo CLIを実行し、WebSocketを使用してGitLab Duo Workflow Serviceに接続します。
1. AIモデルの指示に従ってツール（ファイル操作、Gitコマンド）を実行します。

ExecutorのバージョンはGitLabによって管理され、定期的なリリースの一部として更新されます。

## CI/CD実行を設定する {#configure-cicd-execution}

CI/CDでフローを実行する方法をカスタマイズするには、プロジェクトにエージェントの設定ファイルを作成します。

サポートされているキーとそのタイプについては、[`agent-config.yml`参照](agent-config-yaml.md)を参照してください。

> [!note]
> 事前定義されたCI/CD変数を使用して`agent-config.yml`を設定することはできません。フローを実行するジョブには[変数](execution-variables.md#available-variables)を使用する必要があります。

### エージェントの設定ファイルを作成する {#create-the-agent-configuration-file}

1. プロジェクトのリポジトリに、`.gitlab/duo/`フォルダーを作成します。
1. そのフォルダー内に、`agent-config.yml`という名前の設定ファイルを作成します。
1. 必要な設定オプションを追加します。
1. ファイルをデフォルトブランチにコミットしてプッシュします。

プロジェクトのCI/CDでフローが実行されると、設定が適用されます。

完全な`agent-config.yml`ファイル例については、[`agent-config.yml`参照](agent-config-yaml.md#complete-example)を参照してください。

> [!note]
> 設定ファイルはプロジェクトのデフォルトブランチから読み取り専用です。他のブランチにコミットされたファイルは、それらのブランチからフローが実行されても無視されます。

### セットアップスクリプトを設定する {#configure-setup-scripts}

フローの実行前に実行されるセットアップスクリプトを定義できます。これは、依存関係のインストール、環境の設定、または初期化に役立ちます。

セットアップスクリプトを追加するには、`agent-config.yml`ファイルに次のコマンドを追加します:

```yaml
setup_script:
  - apt-get update && apt-get install -y curl
  - pip install -r requirements.txt
  - echo "Setup complete"
```

これらのコマンドは次のアクションを実行します:

- メインのワークフローコマンドの前に実行されます。
- 指定された順序で実行されます。
- 単一のコマンドまたはコマンド配列として指定できます。

`setup_script`のユーザーコンテキストはDockerイメージによって異なります。デフォルトのGitLabイメージは`root`として実行されます。カスタムイメージは、イメージの`USER`ディレクティブで定義されたユーザーとして実行されます。`setup_script`がルートアクセス（例えば、システムパッケージをインストールするため）を必要とする場合、カスタムイメージが適切に設定されていることを確認してください。

> [!warning]
> `setup_script`コマンドはSRTが適用される前に実行され、その外部で実行されます。これらのコマンドは、トリガーするユーザーのOAuthトークン、サービストークン、およびID詳細を含む、フロー内のすべての環境変数にアクセスできます。セキュリティモデルと推奨される保護については、[`agent-config.yml`のセキュリティへの影響](security-considerations.md#security-implications-of-agent-configyml)を参照してください。

### キャッシュを設定する {#configure-caching}

後続のフローの実行を高速化するためのキャッシュを設定するには、`agent-config.yml`ファイルを設定して、実行間でファイルとディレクトリを保持します。キャッシュは、`node_modules`などの依存関係フォルダーや、Python仮想環境に役立ちます。

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

### IDトークンを設定する {#configure-id-tokens}

{{< history >}}

- GitLab 19.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224940)されました。

{{< /history >}}

フローからサードパーティサービスを認証するには、[IDトークン](../../../../ci/secrets/id_token_authentication.md)を設定します。

IDトークンは、GitLab CI/CDが生成し、フローを実行するジョブに注入するJSON Webトークン（JWT）であり、永続的な認証情報を保存せずにキーレスのOpenID Connect（OIDC認証）を可能にします。例えば、IDトークンを使用してシークレットマネージャーからシークレットを取得するか、バイナリとGitコミットに署名できます。

IDトークンを設定するには、`agent-config.yml`ファイルに`id_tokens`ブロックを追加します。各トークンには`aud`（オーディエンス）クレームが必要です:

```yaml
id_tokens:
  VAULT_ID_TOKEN:
    aud: https://vault.example.com

network_policy:
  allowed_domains:
    - vault.example.com
```

`aud`クレームは単一の文字列または文字列のリストにすることができます:

```yaml
id_tokens:
  MY_ID_TOKEN:
    aud:
      - https://first.service.example.com
      - https://second.service.example.com

network_policy:
  allowed_domains:
    - first.service.example.com
    - second.service.example.com
```

各トークンは、トークンの名前を使用する環境変数としてフロージョブで利用できます。上記の例では、フローは`$VAULT_ID_TOKEN`と`$MY_ID_TOKEN`を使用できます。

トークン名が設定内の別の場所で宣言された変数名と一致する場合、IDトークンが優先されます。

> [!warning]
> IDトークンは、その`aud`クレームを信頼するサービスへのアクセスを許可する認証情報です。各トークンに可能な限り狭い`aud`値を設定して、不正なトークンができるだけ少ないサービスで認証できるようにします。設定ファイルはデフォルトブランチから読み取られるため、フローがリクエストできるトークンを変更できるユーザーを制御するために[推奨される保護](security-considerations.md#recommended-protections)を適用してください。

トークンペイロードとサードパーティサービスとの信頼を設定する方法の詳細については、[IDトークンを使用したOpenID Connect（OIDC認証）](../../../../ci/secrets/id_token_authentication.md)を参照してください。

## フローを実行するようにRunnerを設定する {#configure-runners-to-execute-flows}

CI/CDを使用するフローはRunnerで実行されます。

GitLab.comでは、フローはGitLabが提供する[ホスト型Runner](../../../../ci/runners/hosted_runners/_index.md)を使用できます。これらはデフォルトで有効になっています。

また、フロー用に独自のRunnerを設定するオプションもあります。

> [!note]
> トップレベルグループで[IPアドレス制限](../../../group/access_and_permissions.md#restrict-group-access-by-ip-address)が有効になっている場合、ホスト型Runnerはフローに使用できません。ホスト型Runnerは、グループのIP許可リストに追加できないクラウドプロバイダープールからの動的IPアドレスを使用します。代わりに、トップレベルグループで独自のグループRunnerを設定します。

フロー用に独自のRunnerを設定するには:

1. [インスタンスRunner](../../../../ci/runners/runners_scope.md)またはトップレベルグループに割り当てられたグループRunnerを作成します。もしフローでプロジェクトRunnerまたはサブグループに割り当てられたグループRunnerを使用したい場合は、`duo_runner_restrictions`機能フラグ（GitLab Self-Managedのみ）をオフにします。
1. Runnerに`gitlab--duo`タグを追加して、フローのジョブをピックアップするようにします。Runnerにこのタグがない場合、フローを持つジョブは無期限にキューに入ったままになります。次のいずれかの方法を使用します:
   - Runnerを作成する際に、**タグ**フィールドに`gitlab--duo`と入力します。
   - 既存のRunnerの場合は、[Runnerが実行できるジョブを編集](../../../../ci/runners/configure_runners.md#control-jobs-that-a-runner-can-run)し、**タグ**フィールドに`gitlab--duo`と入力します。
   - `config.toml`ファイルでRunnerを設定する場合は、`[[runners]]`セクションにタグを追加します:
     <!-- markdownlint-disable MD044 -->

     ```toml
     [[runners]]
       executor = "docker"
       tags = ["gitlab--duo"]
     ```

     <!-- markdownlint-enable MD044 -->
1. Runnerを`docker`、`docker-autoscaler`、または`kubernetes`のようなDockerイメージをサポートする[executor](https://docs.gitlab.com/runner/executors/)を使用するように設定します。`shell` executorはサポートされていません。
1. トップレベルグループで[IPアドレス制限](../../../group/access_and_permissions.md#restrict-group-access-by-ip-address)が有効になっている場合は、RunnerのIPアドレスをグループのIP許可リストに追加して、Runnerがグループにアクセスできるようにします。
1. GitLab Self-Managedのみ。Runnerがフローが必要とするサービスに到達できることを確認してください:
   - [GitLabインスタンスからの送信接続を許可](../../../../administration/gitlab_duo/configure/_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo)して、Agent Platformに接続します。
   - [Runnerからの送信接続を許可](../../../../administration/gitlab_duo/configure/_index.md#allow-connections-from-the-runner)して、Agent Platformに接続します。
   - 証明書チェーンに自己署名証明書があるインスタンスの場合は、[追加のGitLab Duo CLI設定](../../../gitlab_duo_cli/use.md#certificate-errors)を完了します。

### 実行環境サンドボックスを使用してフローを保護する {#use-the-execution-environment-sandbox-to-secure-flows}

ネットワークとファイルシステムの分離のために、[実行環境サンドボックス](../../environment_sandbox.md)を使用して、Runnerで実行されるフローを保護します。

サンドボックスを使用するには、次のいずれかのイメージを使用する必要があります:

- Agent Platform用のデフォルトDockerベースイメージ
- A [SRTがインストールされたカスタムイメージ](../../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)

Runnerをサンドボックスを使用するように設定するには、[Runnerの設定](https://docs.gitlab.com/runner/configuration/advanced-configuration/)で`privileged = true`を設定します。

例: 
<!-- markdownlint-disable MD044 -->

```toml
[[runners]]
  executor = "docker"
  tags = ["gitlab--duo"]
  [runners.docker]
    privileged = true
```

<!-- markdownlint-enable MD044 -->
サンドボックスは次のイメージでは使用できません:

- SRTがインストールされていないカスタムイメージ
- ハード化されたUBI 9 Minimalイメージ
