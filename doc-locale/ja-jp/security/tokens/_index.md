---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabトークンの概要
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このドキュメントでは、GitLabで使用されるトークン、その目的、および該当する場合はセキュリティガイダンスについて説明します。

## セキュリティに関する考慮事項

トークンを安全に保つために、次の点に注意してください。

- トークンはパスワードと同様に扱い、安全に保管してください。
- スコープ付きトークンを作成する場合は、誤って漏えいしたトークンの影響を軽減するため、可能な限り最も制限されたスコープを使用してください。
  - 個別のプロセスで異なるスコープ（たとえば、`read`と`write`）が必要な場合は、それぞれのスコープに対応した個別のトークンを使用することを検討してください。そうすれば、1つのトークンが漏えいしても、APIへのフルアクセスのような広いスコープを持つ1つのトークンが漏えいした場合よりもアクセス権が制限されます。
- トークンを作成する際は、タスクの完了時に有効期限が切れるようトークンを設定することを検討してください。たとえば、1回限りのインポートを実行する必要がある場合は、数時間後にトークンの有効期限が切れるように設定します。
- 作業中のプロジェクトを紹介するためにデモ環境をセットアップし、そのプロジェクトを説明するビデオを録画したりブログ記事を作成したりする場合は、シークレットを誤って漏えいしないように注意してください。デモが終了したら、デモ中に作成したすべてのシークレットを失効させてください。
- URLにトークンを追加すると、セキュリティ上のリスクが生じる可能性があります。代わりに、[`Private-Token`](../../api/rest/authentication.md#personalprojectgroup-access-tokens)のようなヘッダーを使用してトークンを渡します。
  - トークンを含むURLでクローンを作成したりリモートを追加したりすると、GitはそのURLをプレーンテキストで`.git/config`ファイルに書き込みます。
  - URLはプロキシやアプリケーションサーバーによってログに記録されることが多く、これらの認証情報がシステム管理者に漏えいする可能性があります。
- トークンは[Git認証情報ストレージ](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)を使用して保存できます。
- すべての種類のアクティブなアクセストークンを定期的に確認し、不要なものはすべて失効させてください。

禁止事項:

- プロジェクト内でトークンをプレーンテキストで保存しないでください。トークンがGitLab CI/CD用の外部シークレットである場合は、[CI/CDでの外部シークレットの使用](../../ci/secrets/_index.md)方法に関する推奨事項を確認してください。
- イシュー、MRの説明、コメント、またはその他のフリーテキスト入力欄に、コード、コンソールコマンド、ログ出力を貼り付ける際に、トークンを含めないでください。
- 認証情報をコンソールログやアーティファクトに記録しないでください。認証情報の[保護](../../ci/variables/_index.md#protect-a-cicd-variable)と[マスキング](../../ci/variables/_index.md#mask-a-cicd-variable)を検討してください。

### CI/CDのトークン

パーソナルアクセストークンはスコープが広いため、可能な限りCI/CD変数として使用することは避けてください。CI/CDジョブから他のリソースへのアクセスが必要な場合は、次のいずれかを使用します（アクセススコープの狭い順に並んでいます）。

1. ジョブトークン（最もアクセススコープが狭い）
1. プロジェクトトークン
1. グループトークン

[CI/CD変数のセキュリティ](../../ci/variables/_index.md#cicd-variable-security)に関する追加の推奨事項:

- すべての認証情報に[シークレットストレージ](../../ci/pipelines/pipeline_security.md#secrets-storage)を使用してください。
- 機密情報を含むCI/CD変数は、[保護](../../ci/variables/_index.md#protect-a-cicd-variable)と[マスキング](../../ci/variables/_index.md#mask-a-cicd-variable)を行い、[非表示](../../ci/variables/_index.md#hide-a-cicd-variable)にする必要があります。

## パーソナルアクセストークン

[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)を作成し、以下の認証に使用できます。

- GitLab API
- GitLabリポジトリ
- GitLabレジストリ

パーソナルアクセストークンのスコープを制限し、有効期限を設定できます。デフォルトでは、パーソナルアクセストークンは、トークンを作成したユーザーの権限を継承します。

Personal Access Tokens APIを使用して、[パーソナルアクセストークンのローテーション](../../api/personal_access_tokens.md#rotate-a-personal-access-token)などの操作をプログラムで実行できます。

パーソナルアクセストークンの有効期限が近づくと、[メールが届きます](../../user/profile/personal_access_tokens.md#personal-access-token-expiry-emails)。

トークンによる権限を必要とするCI/CDジョブを検討する際は、特にCI/CD変数として保存する場合、パーソナルアクセストークンの使用は避けてください。CI/CDジョブトークンやプロジェクトアクセストークンを使用すると、リスクを大幅に軽減しながら同様の結果が得られることがよくあります。

## OAuth 2.0トークン

GitLabは[OAuth 2.0プロバイダー](../../api/oauth2.md)として機能し、他のサービスがユーザーに代わってGitLab APIにアクセスすることを許可できます。

OAuth 2.0トークンのスコープを制限し、ライフタイムを設定できます。

## 代理トークン

[代理トークン](../../api/rest/authentication.md#impersonation-tokens)は特殊なパーソナルアクセストークンで、特定のユーザーに対して、管理者のみが作成できます。代理トークンは、特定のユーザーとしてGitLab API、リポジトリ、GitLabレジストリに対して認証するアプリケーションやスクリプトを構築するのに役立ちます。

代理トークンのスコープを制限し、有効期限を設定できます。

## プロジェクトアクセストークン

[プロジェクトアクセストークン](../../user/project/settings/project_access_tokens.md)は、プロジェクトにスコープが限定されます。パーソナルアクセストークンと同様に、以下の認証に使用できます。

- GitLab API
- GitLabリポジトリ
- GitLabレジストリ

プロジェクトアクセストークンのスコープを設定し、有効期限を設定できます。プロジェクトアクセストークンを作成すると、GitLabは[プロジェクトのボットユーザー](../../user/project/settings/project_access_tokens.md#bot-users-for-projects)を作成します。プロジェクトのボットユーザーはサービスアカウントであり、ライセンスされたシートとしてはカウントされません。

[Project Access Tokens API](../../api/project_access_tokens.md)を使用して、[プロジェクトアクセストークンのローテーション](../../api/project_access_tokens.md#rotate-a-project-access-token)などの操作をプログラムで実行できます。

プロジェクトアクセストークンの有効期限が近づくと、少なくともメンテナーロールを持つプロジェクトのメンバーに[メールが届きます](../../user/project/settings/project_access_tokens.md#project-access-token-expiry-emails)。

## グループアクセストークン

[グループアクセストークン](../../user/group/settings/group_access_tokens.md)は、グループにスコープが限定されます。パーソナルアクセストークンと同様に、以下の認証に使用できます。

- GitLab API
- GitLabリポジトリ
- GitLabレジストリ

グループアクセストークンのスコープを設定し、有効期限を設定できます。グループアクセストークンを作成すると、GitLabは[グループのボットユーザー](../../user/group/settings/group_access_tokens.md#bot-users-for-groups)を作成します。グループのボットユーザーはサービスアカウントであり、ライセンスされたシートとしてはカウントされません。

[Group Access Tokens API](../../api/group_access_tokens.md)を使用して、[グループアクセストークンのローテーション](../../api/group_access_tokens.md#rotate-a-group-access-token)などの操作をプログラムで実行できます。

グループアクセストークンの有効期限が近づくと、オーナーロールを持つグループのメンバーに[メールが届きます](../../user/group/settings/group_access_tokens.md#group-access-token-expiry-emails)。

## デプロイトークン

[デプロイトークン](../../user/project/deploy_tokens/_index.md)を使用すると、ユーザーとパスワードなしで、プロジェクトのパッケージとコンテナレジストリイメージをクローン、プッシュ、プルできます。デプロイトークンはGitLab APIでは使用できません。

デプロイトークンを管理するには、少なくともメンテナーロールを持つプロジェクトのメンバーである必要があります。

## デプロイキー

[デプロイキー](../../user/project/deploy_keys/_index.md)を使用すると、SSH公開鍵をGitLabインスタンスにインポートすることで、リポジトリへの読み取り専用または読み取り/書き込みアクセスが可能になります。デプロイキーはGitLab APIまたはレジストリでは使用できません。

デプロイキーを使用することで、仮のユーザーアカウントを設定せずに、リポジトリを継続的インテグレーションサーバーにクローンできます。

プロジェクトのデプロイキーを追加または有効にするには、少なくともメンテナーロールが必要です。

## Runner認証トークン

GitLab 16.0以降では、Runnerを登録する際に、Runner登録トークンの代わりにRunner認証トークンを使用できます。Runner登録トークンは[非推奨](../../ci/runners/new_creation_workflow.md)となっています。

Runnerとその設定を作成すると、Runnerの登録に使用するRunner認証トークンが付与されます。Runner認証トークンはローカルの[`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html)ファイルに保存されます。このファイルを使用してRunnerを設定します。

Runnerは、ジョブキューからジョブを取得する際に、Runner認証トークンを使用してGitLabに対して認証します。RunnerがGitLabで認証されると、Runnerは[ジョブトークン](../../ci/jobs/ci_job_token.md)を受け取り、これを使用してジョブを実行します。

Runner認証トークンはRunnerのマシン上に留まります。次のexecutorの実行環境は、ジョブトークンのみにアクセスでき、Runner認証トークンにはアクセスできません。

- Docker Machine
- Kubernetes
- VirtualBox
- Parallels
- SSH

Runnerのファイルシステムへの悪意のあるアクセスにより、`config.toml`ファイルやRunner認証トークンが漏えいするおそれがあります。攻撃者はそのRunner認証トークンを使用して、[Runnerのクローンを作成](https://docs.gitlab.com/runner/security/#cloning-a-runner)する可能性があります。

Runners APIを使用して、[Runner認証トークンをローテーションまたは失効させる](../../api/runners.md#reset-runners-authentication-token-by-using-the-current-token)ことができます。

## Runner登録トークン（非推奨）

{{< alert type="warning" >}}

Runner登録トークンを渡す機能は[非推奨](../../ci/runners/new_creation_workflow.md)となり、特定の設定引数のサポートとともにGitLab 18.0で削除される予定です。これは破壊的な変更です。GitLabでは新しい[GitLab Runnerトークンアーキテクチャ](../../ci/runners/new_creation_workflow.md)を実装し、新しいRunner登録方法を導入したことで、Runner登録トークンは不要になりました。

{{< /alert >}}

Runner登録トークンは、[Runner](https://docs.gitlab.com/runner/)をGitLabに[登録](https://docs.gitlab.com/runner/register/)するために使用します。グループやプロジェクトのオーナー、またはインスタンス管理者は、GitLabのユーザーインターフェースを通じてトークンを取得できます。登録トークンはRunnerの登録に限定されており、それ以上のスコープはありません。

このRunner登録トークンを使用して、プロジェクトまたはグループでジョブを実行するRunnerを追加できます。Runnerはプロジェクトのコードにアクセスできるため、プロジェクトまたはグループへの権限を割り当てる際は注意してください。

## CI/CDジョブトークン

[CI/CD](../../ci/jobs/ci_job_token.md)ジョブトークンは、ジョブの実行期間のみ有効な短期間のトークンです。これにより、CI/CDジョブは限られた数のAPIエンドポイントにアクセスできます。API認証では、ジョブをトリガーしたユーザーの権限を使用してジョブトークンを使用します。

ジョブトークンは、そのライフタイムの短さとスコープの制限によって、セキュリティが確保されています。同じマシン上で複数のジョブを実行している（たとえば、[shell runner](https://docs.gitlab.com/runner/security/#usage-of-shell-executor)を使用している）場合、このトークンが漏えいする可能性があります。[プロジェクトの許可リスト](../../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)を使用して、ジョブトークンがアクセスできる対象をさらに制限できます。Docker Machine Runnerでは、[`MaxBuilds=1`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section)を設定する必要があります。これにより、Runnerマシンは1つのビルドのみを実行し、その後破棄されるようになります。プロビジョニングには時間がかかるため、この設定はパフォーマンスに影響を与える可能性があります。

## GitLabクラスターエージェントトークン

[Kubernetes向けGitLabエージェントを登録](../../user/clusters/agent/install/_index.md#register-the-agent-with-gitlab)すると、GitLabはそのクラスターエージェントがGitLabに対して認証するためのアクセストークンを生成します。

このクラスターエージェントトークンを失効させるには、次のいずれかを実行します。

- [Agents API](../../api/cluster_agents.md#revoke-an-agent-token)でトークンを失効させる。
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

## その他のトークン

### フィードトークン

各ユーザーには、有効期限のない長期間有効なフィードトークンが付与されています。このトークンは以下の認証に使用できます。

- パーソナライズされたRSSフィードを読み込むためのRSSリーダー
- パーソナライズされたカレンダーを読み込むためのカレンダーアプリケーション

このトークンを使用して他のデータにアクセスすることはできません。

ユーザースコープのフィードトークンは、すべてのフィードに使用できます。ただし、フィードやカレンダーのURLは、それぞれ1つのフィードのみに有効な別のトークンを使用して生成されます。

トークンを持っている人であれば誰でも本人になりすまして、機密性の高いイシューを含むフィードのアクティビティを閲覧できます。トークンが漏えいしたと思われる場合は、すぐに[トークンをリセット](../../user/profile/contributions_calendar.md#reset-the-user-activity-feed-token)してください。

#### フィードトークンを無効にする

前提要件:

- 管理者である必要があります。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > 一般**を選択します。
1. **表示レベルとアクセス制御**を展開します。
1. **フィードトークン**で、**フィードトークンを無効にする**チェックボックスをオンにし、**変更の保存**を選択します。

### 受信メールトークン

各ユーザーには、有効期限のない受信メールトークンが付与されています。このトークンは、パーソナルプロジェクトに関連付けられたメールアドレスに含まれており、[メールで新しいイシューを作成](../../user/project/issues/create_issues.md#by-sending-an-email)する際に使用します。

このトークンを使用して他のデータにアクセスすることはできません。トークンを持っている人は誰でも、本人になりすましてイシューとマージリクエストを作成できます。トークンが漏えいしたと思われる場合は、すぐにトークンをリセットしてください。

## 使用可能なスコープ

この表は、トークンごとのデフォルトのスコープを示しています。一部のトークンでは、トークンの作成時にスコープをさらに制限できます。

| トークン名                  | APIアクセス                         | レジストリアクセス                    | リポジトリアクセス |
|-----------------------------|------------------------------------|------------------------------------|-------------------|
| パーソナルアクセストークン       | {{< icon name="check-circle" >}} 可能             | {{< icon name="check-circle" >}} 可能             | {{< icon name="check-circle" >}} 可能 |
| OAuth 2.0トークン             | {{< icon name="check-circle" >}} 可能             | {{< icon name="dotted-circle" >}} 不可             | {{< icon name="check-circle" >}} 可能 |
| 代理トークン         | {{< icon name="check-circle" >}} 可能             | {{< icon name="check-circle" >}} 可能             | {{< icon name="check-circle" >}} 可能 |
| プロジェクトアクセストークン        | {{< icon name="check-circle" >}} 可能<sup>1</sup> | {{< icon name="check-circle" >}} 可能<sup>1</sup> | {{< icon name="check-circle" >}} 可能<sup>1</sup> |
| グループアクセストークン          | {{< icon name="check-circle" >}} 可能<sup>2</sup> | {{< icon name="check-circle" >}} 可能<sup>2</sup> | {{< icon name="check-circle" >}} 可能<sup>2</sup> |
| デプロイトークン                | {{< icon name="dotted-circle" >}} 不可             | {{< icon name="check-circle" >}} 可能             | {{< icon name="check-circle" >}} 可能 |
| デプロイキー                  | {{< icon name="dotted-circle" >}} 不可             | {{< icon name="dotted-circle" >}} 不可             | {{< icon name="check-circle" >}} 可能 |
| Runner登録トークン   | {{< icon name="dotted-circle" >}} 不可             | {{< icon name="dotted-circle" >}} 不可             | {{< icon name="check-circle-dashed" >}} 限定的<sup>3</sup> |
| Runner認証トークン | {{< icon name="dotted-circle" >}} 不可             | {{< icon name="dotted-circle" >}} 不可             | {{< icon name="check-circle-dashed" >}} 限定的<sup>3</sup> |
| ジョブトークン                   | {{< icon name="check-circle-dashed" >}} 限定的<sup>4</sup> | {{< icon name="dotted-circle" >}} 不可  | {{< icon name="check-circle" >}} 可能 |

**脚注:**

1. 1つのプロジェクトに限定されます。
1. 1つのグループに限定されます。
1. Runner登録およびRunner認証トークンには、リポジトリへの直接アクセス権はありませんが、リポジトリにアクセスできるジョブを実行する新しいRunnerを登録および認証するために使用できます。
1. [特定のエンドポイント](../../ci/jobs/ci_job_token.md)のみ。

## トークンのプレフィックス

次の表は、トークンの種類ごとのプレフィックスを示しています。

|            トークン名             |      プレフィックス        |
|-----------------------------------|--------------------|
| パーソナルアクセストークン             | `glpat-`           |
| OAuthアプリケーションシークレット          | `gloas-`           |
| 代理トークン               | `glpat-`           |
| プロジェクトアクセストークン              | `glpat-`           |
| グループアクセストークン                | `glpat-`           |
| デプロイトークン                      | `gldt-`（[GitLab 16.7で追加](https://gitlab.com/gitlab-org/gitlab/-/issues/376752)） |
| Runner認証トークン       | `glrt-`            |
| CI/CDジョブトークン                   | `glcbt-`<br /> •（GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/426137)され、機能フラグ`prefix_ci_build_tokens`で制御されます。デフォルトでは無効です。）<br /> •（GitLab 16.9で[一般提供](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17299)になりました。機能フラグ`prefix_ci_build_tokens`が削除されました。） |
| トリガートークン                     | `glptt-`           |
| フィードトークン                        | `glft-`            |
| 受信メールトークン               | `glimt-`           |
| Kubernetes向けGitLabエージェントトークン | `glagent-`         |
| GitLabセッションCookie            | `_gitlab_session=` |
| SCIMトークン                       | `glsoat-`<br /> •（GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/435096)され、機能フラグ`prefix_scim_tokens`で制御されます。デフォルトでは無効です。）<br > •（GitLab 16.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/435423)になりました。機能フラグ`prefix_scim_tokens`が削除されました。） |
| 機能フラグクライアントトークン        | `glffct-`          |
