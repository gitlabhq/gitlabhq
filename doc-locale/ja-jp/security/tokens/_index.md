---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabトークンの概要
description: 異なる認証トークンとそのセキュリティへの影響を理解します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このドキュメントでは、GitLabで使用されるトークン、その目的、および該当する場合のセキュリティガイダンスについて説明します。

## セキュリティに関する考慮事項 {#security-considerations}

トークンを安全に保つために、次の点に注意してください。

- トークンはパスワードと同様に扱い、安全に保管してください。
- スコープ付きトークンを作成する場合は、誤って漏洩した場合の影響を軽減するため、可能な限り最も制限されたスコープを使用してください。
  - 個別のプロセスで異なるスコープ（たとえば、`read`と`write`）が必要な場合は、スコープごとに個別のトークンを使用することを検討してください。1つのトークンが漏洩した場合、完全なAPIアクセスのような広範なスコープを持つ単一のトークンよりもアクセス権限が少なくなります。
- トークンを作成する際は、次のようにします。
  - 以下の[トークンの命名規則](#token-naming-guidance)に従って名前を選択します。
  - タスク完了時に期限切れになるトークンの設定を検討してください。たとえば、1回限りのインポートを実行する必要がある場合は、数時間後にトークンの有効期限が切れるように設定します。
  - 関連するURLを含む、さらに詳しいコンテキストを提供する説明を追加します。
- URLの代わりにヘッダーでトークンを渡します:
  - 個人、プロジェクトアクセストークン、およびグループアクセストークンには`PRIVATE-TOKEN`を使用します。
  - ジョブトークンには`JOB-TOKEN`を使用します。
- デモ環境をお持ちの場合は、ビデオを録画したり、プロジェクトに関するブログ記事を公開したりした後、すべてのトークンを失効してください。
- トークンは[Git認証情報ストレージ](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)を使用して保存できます。
- すべての種類のアクティブなアクセストークンを定期的に確認し、不要なものはすべて失効させてください。

禁止事項: 

- URLにトークンを追加します:
  - トークンを含むURLでクローンを作成したりリモートを追加したりすると、GitはそのURLをプレーンテキストで`.git/config`ファイルに書き込みます。
  - URLはプロキシやアプリケーションサーバーによってログに記録されることが多く、これらの認証情報がシステム管理者に漏洩する可能性があります。
- プロジェクト内でトークンをプレーンテキストで保存しないでください。
  - トークンがGitLab CI/CD用の外部シークレットである場合は、[CI/CD](../../ci/secrets/_index.md)で外部シークレットを使用する方法を確認してください。
- イシュー、MRの説明、コメント、またはその他のフリーテキスト入力欄に、コード、コンソールコマンド、ログ出力を貼り付ける際に、トークンを含めないでください。
- 認証情報をコンソールログやアーティファクトに記録しないでください。認証情報の[保護](../../ci/variables/_index.md#protect-a-cicd-variable)と[マスキング](../../ci/variables/_index.md#mask-a-cicd-variable)を検討してください。

### トークンの命名規則 {#token-naming-guidance}

一貫した命名規則により、アクセストークンの監査、その目的の理解、および各トークンのローテーションまたは失効による影響の評価が容易になります。

命名規則はチームによって異なりますが、有用な規則は次の質問に答えます:

- トークンはどのようなアクションを実行しますか？例: `ci-deploy`、`api-read`。
- トークンはどのリソースまたはサービスに対して動作しますか？例: `gitlab`、`terraform`。
- トークンはどの環境またはオーナーに関連付けられていますか？例: `production`、`auth-team`。

例: 

| トークン名 | 目的 |
| --- | --- |
| `ci-deploy-gitlab-production` | GitLabプロジェクトの本番環境におけるCI/CDデプロイジョブ |
| `api-read-reporting-dashboard` | レポートダッシュボード用の読み取り専用APIアクセス |
| `automation-sync-vulnmapper-staging` | ステージングでのデータの同期を自動化するスクリプト |

- 具体的にします。`test`、`mytoken`、`token1`、`GITLAB_API_TOKEN`、`API_TOKEN`、`default`のような一般的な名前は避けてください。これらでは、監査中にトークンの目的を特定することができません。
- 使用するシステムまたはツールを含めます。特定のアプリケーション、スクリプト、またはインテグレーションでトークンが使用される場合は、その名前を含めます。例: `terraform-state-backend`または`grafana-metrics-reader`。
- 環境を含めます。該当する場合は、トークンが`production`、`staging`、`development`のいずれを対象とするかを示します。これにより、より低い環境で本番環境トークンが誤って使用されることを防ぎます。
- 機密情報の埋め込みは避けてください。トークン名は監査ログとUIに表示されるため、ユーザー名、メールアドレス、またはその他の個人を特定できる情報（PII）をトークン名に含めないでください。
- 大文字と小文字の規則および句読点規則を標準化して設定します。一貫した大文字と小文字の使用および区切り文字により、トークンの読み取りと検索が容易になります。例として、アンダースコア（_）よりもハイフン（-）を使用します。
- 説明フィールドを使用します。トークンの説明フィールドを使用すると、関連するイシューへのリンクや、トークンを使用するチームの名前などの追加の詳細を追加できます。

### CI/CDのトークン {#tokens-in-cicd}

パーソナルアクセストークンはスコープが広いため、可能な限りCI/CD変数として使用することは避けてください。CI/CDジョブから他のリソースへのアクセスが必要な場合は、次のいずれかを使用します（アクセススコープの狭い順）。

1. ジョブトークン（最もアクセススコープが狭い）
1. プロジェクトトークン
1. グループトークン

[CI/CD変数のセキュリティ](../../ci/variables/_index.md#cicd-variable-security)に関する追加の推奨事項: 

- すべての認証情報に[シークレットストレージ](../../ci/pipeline_security/_index.md#secrets-storage)を使用してください。
- 機密情報を含むCI/CD変数は、[保護](../../ci/variables/_index.md#protect-a-cicd-variable)と[マスキング](../../ci/variables/_index.md#mask-a-cicd-variable)を行い、[非表示](../../ci/variables/_index.md#hide-a-cicd-variable)にする必要があります。

## パーソナルアクセストークン {#personal-access-tokens}

[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)を作成し、以下の認証に使用できます。

- GitLab API。
- GitLabリポジトリ。
- GitLabレジストリ。

パーソナルアクセストークンのスコープを制限し、有効期限を設定できます。デフォルトでは、パーソナルアクセストークンは、トークンを作成したユーザーの権限を継承します。

パーソナルアクセストークンAPIを使用して、[パーソナルアクセストークンのローテーション](../../api/personal_access_tokens.md#rotate-a-personal-access-token)などの操作をプログラムで実行できます。

パーソナルアクセストークンの有効期限が近づくと、[メールが届きます](../../user/profile/personal_access_tokens.md#personal-access-token-expiry-emails)。

トークンによる権限を必要とするCI/CDジョブを検討する際は、特にCI/CD変数として保存する場合、パーソナルアクセストークンの使用は避けてください。CI/CDジョブトークンやプロジェクトアクセストークンを使用すると、リスクを大幅に軽減しながら同様の結果が得られることがよくあります。

## OAuth 2.0トークン {#oauth-20-tokens}

GitLabは[OAuth 2.0プロバイダー](../../api/oauth2.md)として機能し、他のサービスがユーザーに代わってGitLab APIにアクセスすることを許可できます。

OAuth 2.0トークンのスコープを制限し、ライフタイムを設定できます。

## 代理トークン {#impersonation-tokens}

[代理トークン](../../api/rest/authentication.md#impersonation-tokens)は特殊なパーソナルアクセストークンで、特定のユーザーに対して、管理者のみが作成できます。代理トークンは、特定のユーザーとしてGitLab API、リポジトリ、GitLabレジストリに対して認証するアプリケーションやスクリプトを構築するのに役立ちます。

代理トークンのスコープを制限し、有効期限を設定できます。

## プロジェクトアクセストークン {#project-access-tokens}

[プロジェクトアクセストークン](../../user/project/settings/project_access_tokens.md)は、プロジェクトにスコープが限定されます。パーソナルアクセストークンと同様に、以下の認証に使用できます。

- GitLab API。
- GitLabリポジトリ。
- GitLabレジストリ。

プロジェクトアクセストークンのスコープを設定し、有効期限を設定できます。プロジェクトアクセストークンを作成すると、GitLabは[プロジェクトのボットユーザー](../../user/project/settings/project_access_tokens.md#bot-users-for-projects)を作成します。プロジェクトのボットユーザーはサービスアカウントであり、ライセンスされたシートとしてはカウントされません。

[プロジェクトアクセストークンAPI](../../api/project_access_tokens.md)を使用して、[プロジェクトアクセストークンのローテーション](../../api/project_access_tokens.md#rotate-a-project-access-token)などの操作をプログラムで実行できます。

メンテナーまたはオーナーロールを持つプロジェクトのメンバーは、プロジェクトアクセストークンの期限が近づくと[メール](../../user/project/settings/project_access_tokens.md#project-access-token-expiry-emails)を受信します。

## グループアクセストークン {#group-access-tokens}

[グループアクセストークン](../../user/group/settings/group_access_tokens.md)は、グループにスコープが限定されます。パーソナルアクセストークンと同様に、以下の認証に使用できます。

- GitLab API。
- GitLabリポジトリ。
- GitLabレジストリ。

グループアクセストークンのスコープを設定し、有効期限を設定できます。グループアクセストークンを作成すると、GitLabは[グループのボットユーザー](../../user/group/settings/group_access_tokens.md#bot-users-for-groups)を作成します。グループのボットユーザーはサービスアカウントであり、ライセンスされたシートとしてはカウントされません。

[グループアクセストークンAPI](../../api/group_access_tokens.md)を使用して、[グループアクセストークンのローテーション](../../api/group_access_tokens.md#rotate-a-group-access-token)などの操作をプログラムで実行できます。

グループアクセストークンの有効期限が近づくと、オーナーロールを持つグループのメンバーに[メールが届きます](../../user/group/settings/group_access_tokens.md#group-access-token-expiry-emails)。

## デプロイトークン {#deploy-tokens}

[デプロイトークン](../../user/project/deploy_tokens/_index.md)を使用すると、ユーザーとパスワードなしで、プロジェクトのパッケージとコンテナレジストリイメージをクローン、プッシュ、プルできます。デプロイトークンはGitLab APIでは使用できません。

デプロイトークンを管理するには、少なくともメンテナーロールを持つプロジェクトのメンバーである必要があります。

## デプロイキー {#deploy-keys}

[デプロイキー](../../user/project/deploy_keys/_index.md)を使用すると、SSH公開キーをGitLabインスタンスにインポートすることで、リポジトリへの読み取り専用または読み取り/書き込みアクセスが可能になります。デプロイキーはGitLab APIまたはレジストリでは使用できません。

デプロイキーを使用することで、仮のユーザーアカウントを設定せずに、リポジトリを継続的インテグレーションサーバーにクローンできます。

プロジェクトのデプロイキーを追加または有効にするには、少なくともメンテナーロールが必要です。

## Runner認証トークン {#runner-authentication-tokens}

GitLab 16.0以降では、Runnerを登録する際に、Runner登録トークンの代わりにRunner認証トークンを使用できます。Runner登録トークンは[非推奨](../../ci/runners/new_creation_workflow.md)となっています。

Runnerとその設定を作成すると、Runnerの登録に使用するRunner認証トークンが付与されます。Runner認証トークンはローカルの[`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration/)ファイルに保存されます。このファイルを使用してRunnerを設定します。

Runnerは、ジョブキューからジョブを取得する際に、Runner認証トークンを使用してGitLabに対して認証します。RunnerがGitLabで認証されると、Runnerは[ジョブトークン](../../ci/jobs/ci_job_token.md)を受け取り、これを使用してジョブを実行します。

Runner認証トークンはRunnerのマシン上に留まります。次のexecutorの実行環境は、ジョブトークンのみにアクセスでき、Runner認証トークンにはアクセスできません。

- Docker Machine
- Kubernetes
- VirtualBox
- Parallels
- SSH

Runnerのファイルシステムへの悪意のあるアクセスにより、`config.toml`ファイルやRunner認証トークンが漏洩するおそれがあります。攻撃者はそのRunner認証トークンを使用して、[Runnerのクローンを作成](https://docs.gitlab.com/runner/security/#cloning-a-runner)する可能性があります。

Runners APIを使用して、[Runner認証トークンをローテーションまたは失効させる](../../api/runners.md#reset-runners-authentication-token-by-using-the-current-token)ことができます。

## Runner登録トークン（レガシー） {#runner-registration-tokens-legacy}

> [!warning]
> Runner登録トークンを渡すオプションと、特定の設定引数のサポートは、レガシーと見なされ、推奨されません。[Runner作成ワークフロー](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)を使用して、Runnerを登録するための認証トークンを生成します。このプロセスは、Runnerの所有権の完全なトレーサビリティを提供し、Runnerフリートのセキュリティを強化します。GitLabでは新しい[GitLab Runnerトークンアーキテクチャ](../../ci/runners/new_creation_workflow.md)を実装し、新しいRunner登録方法を導入したことで、Runner登録トークンは不要になりました。

Runner登録トークンは、[Runner](https://docs.gitlab.com/runner/)をGitLabに[登録](https://docs.gitlab.com/runner/register/)するために使用します。グループまたはプロジェクトのオーナー、またはインスタンス管理者は、GitLabのユーザーインターフェースを通じてトークンを取得できます。登録トークンはRunnerの登録に限定されており、それ以上のスコープはありません。

このRunner登録トークンを使用して、プロジェクトまたはグループでジョブを実行するRunnerを追加できます。Runnerはプロジェクトのコードにアクセスできるため、プロジェクトまたはグループへの権限を割り当てる際は注意してください。

## CI/CDジョブトークン {#cicd-job-tokens}

[CI/CD](../../ci/jobs/ci_job_token.md)ジョブトークンは、ジョブの実行期間のみ有効な短期間のトークンです。これにより、CI/CDジョブは限られた数のAPIエンドポイントにアクセスできます。API認証では、ジョブをトリガーしたユーザーの権限を使用してジョブトークンを使用します。

ジョブトークンは、そのライフタイムの短さとスコープの制限によって、セキュリティが確保されています。同じマシン上で複数のジョブを実行している（たとえば、[Shell Runner](https://docs.gitlab.com/runner/security/#usage-of-shell-executor)を使用している）場合、このトークンが漏洩する可能性があります。ジョブトークンがアクセスできるものをさらに制限するために、[プロジェクト許可リスト](../../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)を使用できます。

Docker Machine Runnerでは、[`MaxBuilds=1`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runnersmachine-section)を設定する必要があります。これにより、Runnerマシンは1つのビルドのみを実行し、その後削除されるようになります。プロビジョニングには時間がかかるため、この設定はパフォーマンスに影響を与える可能性があります。

## GitLabクラスターエージェントトークン {#gitlab-cluster-agent-tokens}

[Kubernetes向けGitLabエージェントを登録](../../user/clusters/agent/install/_index.md#register-the-agent-with-gitlab)すると、GitLabはそのクラスターエージェントがGitLabに対して認証するためのアクセストークンを生成します。

このクラスターエージェントトークンを失効させるには、次のいずれかを実行します。

- [エージェントAPI](../../api/cluster_agents.md#revoke-an-agent-token)でトークンを失効させる。
- [トークンをリセットする](../../user/clusters/agent/work_with_agent.md#reset-the-agent-token)。

どちらの方法でも、トークン、エージェント、およびプロジェクトIDを知っている必要があります。この情報を確認するには、[Railsコンソール](../../administration/operations/rails_console.md)を使用します。

```ruby
# Find token ID
Clusters::AgentToken.find_by_token('glagent-xxx').id

# Find agent ID
Clusters::AgentToken.find_by_token('glagent-xxx').agent.id
=> 1234

# Find project ID
Clusters::AgentToken.find_by_token('glagent-xxx').agent.project_id
=> 12345
```

Railsコンソールでトークンを直接失効させることもできます。

```ruby
# Revoke token with RevokeService, including generating an audit event
Clusters::AgentTokens::RevokeService.new(token: Clusters::AgentToken.find_by_token('glagent-xxx'), current_user: User.find_by_username('admin-user')).execute

# Revoke token manually, which does not generate an audit event
Clusters::AgentToken.find_by_token('glagent-xxx').revoke!
```

## その他のトークン {#other-tokens}

### フィードトークン {#feed-token}

各ユーザーには、有効期限のない長期間有効なフィードトークンが付与されています。このトークンは以下の認証に使用できます。

- パーソナライズされたRSSフィードを読み込むためのRSSリーダー。
- パーソナライズされたカレンダーを読み込むためのカレンダーアプリケーション。

このトークンを使用して他のデータにアクセスすることはできません。

ユーザースコープのフィードトークンは、すべてのフィードに使用できます。ただし、フィードやカレンダーのURLは、それぞれ1つのフィードのみに有効な別のトークンを使用して生成されます。

トークンを持っている人であれば誰でも本人になりすまして、機密性の高いイシューを含むフィードのアクティビティを閲覧できます。トークンが漏洩したと思われる場合は、すぐに[トークンをリセット](../../user/profile/contributions_calendar.md#reset-the-user-activity-feed-token)してください。

#### フィードトークンを無効にする {#disable-a-feed-token}

前提条件: 

- 管理者である必要があります。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **表示レベルとアクセス制御**を展開します。
1. **フィードトークン**で、**フィードトークンを無効にする**チェックボックスをオンにし、**変更を保存**を選択します。

### 受信メールトークン {#incoming-email-token}

各ユーザーには、有効期限のない受信メールトークンが付与されています。このトークンは、パーソナルプロジェクトに関連付けられたメールアドレスに含まれており、[メールで新しいイシューを作成](../../user/project/issues/create_issues.md#by-sending-an-email)する際に使用します。

このトークンを使用して他のデータにアクセスすることはできません。トークンを持っている人は誰でも、本人になりすましてイシューとマージリクエストを作成できます。トークンが漏洩したと思われる場合は、すぐにトークンをリセットしてください。

### ワークスペーストークン {#workspace-token}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194097)されました。

{{< /history >}}

各[workspace](../../user/workspace/_index.md)（ワークスペース）には、期限切れにならない、内部で自動的に管理されるトークンがあります。これにより、ワークスペースとのHTTPおよびSSH通信が可能になります。これは、ワークスペースが**実行中**（実行中）状態になるようにリクエストされた場合に存在し、ワークスペースによって自動的に挿入および使用されます。

停止したワークスペースを起動すると、新しいワークスペーストークンが作成されます。実行中のワークスペースを再起動すると、既存のトークンが削除され、新しいトークンが作成されます。

この内部トークンを直接表示または管理することはできません。このトークンを使用して他のデータにアクセスすることはできません。

ワークスペーストークンを失効するには、[**stop**（停止）または**terminate**（終了）ワークスペース](../../user/workspace/_index.md#manage-workspaces-from-a-project)します。トークンはすぐに削除されます。

## 使用可能なスコープ {#available-scopes}

この表は、トークンごとのデフォルトのスコープを示しています。一部のトークンでは、トークンの作成時にスコープをさらに制限できます。

| トークン名                  | APIアクセス              | レジストリアクセス         | リポジトリアクセス |
|-----------------------------|-------------------------|-------------------------|-------------------|
| パーソナルアクセストークン       | {{< yes >}}             | {{< yes >}}             | {{< yes >}}       |
| OAuth 2.0トークン             | {{< yes >}}             | {{< no >}}              | {{< yes >}}       |
| 代理トークン         | {{< yes >}}             | {{< yes >}}             | {{< yes >}}       |
| プロジェクトアクセストークン        | {{< yes >}}<sup>1</sup> | {{< yes >}}<sup>1</sup> | {{< yes >}}<sup>1</sup> |
| グループアクセストークン          | {{< yes >}}<sup>2</sup> | {{< yes >}}<sup>2</sup> | {{< yes >}}<sup>2</sup> |
| デプロイトークン                | {{< no >}}              | {{< yes >}}             | {{< yes >}}       |
| デプロイキー                  | {{< no >}}              | {{< no >}}              | {{< yes >}}       |
| Runner登録トークン   | {{< no >}}              | {{< no >}}              | 制限付き<sup>3</sup> |
| Runner認証トークン | {{< no >}}              | {{< no >}}              | 制限付き<sup>3</sup> |
| ジョブトークン                   | 制限付き<sup>4</sup>     | {{< no >}}              | {{< yes >}}       |

**補足説明**:

1. 1つのプロジェクトに限定されます。
1. 1つのグループに限定されます。
1. Runner登録およびRunner認証トークンには、リポジトリへの直接アクセス権はありませんが、リポジトリにアクセスできるジョブを実行する新しいRunnerを登録および認証するために使用できます。
1. [特定のエンドポイント](../../ci/jobs/ci_job_token.md)のみ。

## トークンのプレフィックス {#token-prefixes}

次のテーブルは、トークンの種類ごとのプレフィックスを示しています。パーソナルアクセストークンを除き、これらのプレフィックスは標準識別となるように設計されているため、設定できません。

|            トークン名             |      プレフィックス        |
|-----------------------------------|--------------------|
| パーソナルアクセストークン             | `glpat-`           |
| OAuthアプリケーションシークレット          | `gloas-`           |
| 代理トークン               | `glpat-`           |
| プロジェクトアクセストークン              | `glpat-`           |
| グループアクセストークン                | `glpat-`           |
| デプロイトークン                      | `gldt-`（[GitLab 16.7で追加](https://gitlab.com/gitlab-org/gitlab/-/issues/376752)） |
| Runner認証トークン       | `glrt-`または登録トークンを介して作成された場合は`glrtr-` |
| CI/CDジョブトークン                   | `glcbt-`<br /> • （GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/426137)され、機能フラグ`prefix_ci_build_tokens`で制御されます。デフォルトでは無効です。）<br /> • （GitLab 16.9で[一般提供](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17299)になりました。機能フラグ`prefix_ci_build_tokens`は削除されました。） |
| トリガートークン                     | `glptt-`           |
| フィードトークン                        | `glft-`            |
| 受信メールトークン               | `glimt-`           |
| Kubernetes向けGitLabエージェントトークン | `glagent-`         |
| ワークスペーストークン                   | `glwt-`（Added in GitLab 18.2） |
| GitLabセッションクッキー            | `_gitlab_session=` |
| SCIMトークン                       | `glsoat-`<br /> • （GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/435096)され、機能フラグ`prefix_scim_tokens`で制御されます。デフォルトでは無効です。）<br > • （GitLab 16.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/435423)になりました。機能フラグ`prefix_scim_tokens`は削除されました。） |
| 機能フラグクライアントトークン        | `glffct-`          |
