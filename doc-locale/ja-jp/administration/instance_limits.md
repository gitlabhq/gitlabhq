---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabアプリケーションの制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ほとんどの大規模アプリケーションと同様に、GitLabもパフォーマンスの最低限の品質を維持するために、特定の機能に制限を設けています。特定の機能を無制限に利用できるようにすると、セキュリティ、パフォーマンス、データに影響を与える可能性があり、アプリケーションに割り当てられたリソースを使い果たすおそれもあります。

## インスタンス設定

インスタンス設定ページでは、現在のGitLabインスタンスで使用している一部の設定に関する情報を確認できます。

設定している制限に応じて、以下を確認できます。

- SSHホストキー情報
- CI/CDの制限
- GitLab Pagesの制限
- パッケージレジストリの制限
- レート制限
- サイズ制限

このページは誰でも閲覧できるため、認証されていないユーザーには自分に関連する情報のみが表示されます。

インスタンス設定ページにアクセスするには、次の手順に従います。

1. 左側のサイドバーで、**ヘルプ**（{{< icon name="question-o" >}}）> **ヘルプ**を選択します。
1. ヘルプページで、**現在のインスタンス設定を確認する**を選択します。

直接アクセスする場合のURLは、`<gitlab_url>/help/instance_configuration`です。GitLab.comの場合は、<https://gitlab.com/help/instance_configuration>にアクセスします。

## レート制限

レート制限を使用すると、GitLabのセキュリティと耐久性を向上させることができます。

[レート制限の設定](../security/rate_limits.md)の詳細を参照してください。

### イシュー作成

この設定は、イシュー作成エンドポイントへのリクエストレートを制限します。

[イシュー作成のレート制限](settings/rate_limit_on_issues_creation.md)の詳細を参照してください。

- **デフォルトのレート制限**: デフォルトで無効になっています。

### ユーザーまたはIP別

この設定は、ユーザーまたはIPごとのリクエストレートを制限します。

[ユーザーとIPレートの制限](settings/user_and_ip_rate_limits.md)の詳細を参照してください。

- **デフォルトのレート制限**: デフォルトで無効になっています。

### Rawエンドポイント別

この設定は、エンドポイントごとのリクエストレートを制限します。

[Rawエンドポイントのレート制限](settings/rate_limits_on_raw_endpoints.md)の詳細を参照してください。

- **デフォルトのレート制限**: プロジェクト、コミット、ファイルパスごとに300件のリクエスト。

### 保護されたパス別

この設定は、特定のパスに対してリクエストレートを制限します。

GitLabでは、デフォルトで次のパスのレートが制限されています。

```plaintext
'/users/password',
'/users/sign_in',
'/api/#{API::API.version}/session.json',
'/api/#{API::API.version}/session',
'/users',
'/users/confirmation',
'/unsubscribes/',
'/import/github/personal_access_token',
'/admin/session'
```

[保護されたパスのレート制限](settings/protected_paths.md)の詳細を参照してください。

- **デフォルトのレート制限**: 10件のリクエストの後、クライアントは60秒間待機してから再試行する必要があります。

### パッケージレジストリ

この設定は、ユーザーまたはIPアドレスごとのPackages APIに対するリクエストレートを制限します。詳細については、[パッケージレジストリレート制限](settings/package_registry_rate_limits.md)を参照してください。

- **デフォルトのレート制限**: デフォルトで無効になっています。

### Git LFS

この設定は、ユーザーごとの[Git LFS](../topics/git/lfs/_index.md)リクエストに対してリクエストレートを制限します。詳細については、[GitLab Git Large File Storage（LFS）の管理](lfs/_index.md)を参照してください。

- **デフォルトのレート制限**: デフォルトで無効になっています。

### Files API

この設定は、ユーザーまたはIPアドレスごとのFiles APIに対するリクエストレートを制限します。詳細については、[Files APIのレート制限](settings/files_api_rate_limits.md)を参照してください。

- **デフォルトのレート制限**: デフォルトで無効になっています。

### 非推奨のAPIエンドポイント

この設定は、ユーザーまたはIPアドレスごとの非推奨のAPIエンドポイントに対するリクエストレートを制限します。詳細については、[非推奨のAPIのレート制限](settings/deprecated_api_rate_limits.md)を参照してください。

- **デフォルトのレート制限**: デフォルトで無効になっています。

### インポート/エクスポート

この設定は、グループおよびプロジェクトに対するインポート/エクスポートアクションを制限します。

| 制限                   | デフォルト（ユーザーごとに毎分） |
|-------------------------|-------------------------------|
| プロジェクトのインポート          | 6                             |
| プロジェクトのエクスポート          | 6                             |
| プロジェクトのエクスポートのダウンロード | 1                             |
| グループのインポート            | 6                             |
| グループのエクスポート            | 6                             |
| グループのエクスポートのダウンロード   | 1                             |

[インポート/エクスポートのレート制限](settings/import_export_rate_limits.md)の詳細を参照してください。

### メンバーの招待

グループ階層ごとに、1日に招待できるメンバーの最大数を制限します。

- GitLab.com: Freeのメンバーは1日あたり20人のメンバーを招待でき、PremiumトライアルおよびUltimateトライアルのメンバーは1日あたり50人のメンバーを招待できます。
- GitLab Self-Managed: 招待数に制限はありません。

### Webhookのレート制限

{{< history >}}

- GitLab 15.1で、フックごとからトップレベルのネームスペースごとに[制限が変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89591)されました。

{{< /history >}}

トップレベルのネームスペースごとに、Webhookを1分間に呼び出せる回数を制限します。これは、プロジェクトおよびグループのWebhookにのみ適用されます。

レート制限を超えた呼び出しは、`auth.log`に記録されます。

GitLab Self-Managedインスタンスでこの制限を設定するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(web_hook_calls: 10)
```

制限を`0`に設定すると、無効になります。

- **デフォルトのレート制限**: 無効（無制限）。

### 検索のレート制限

{{< history >}}

- GitLab 15.9で、イシュー、マージリクエスト、エピックの検索もレート制限の対象になるように[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104208)されました。
- GitLab 16.0で、認証済みリクエストの[検索スコープ](../user/search/_index.md#disable-global-search-scopes)にもレート制限が適用されるように[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118525)されました。

{{< /history >}}

この設定では、検索リクエストを次のように制限します。

| 制限                | デフォルト（1分あたりのリクエスト数） |
|----------------------|-------------------------------|
| 認証済みユーザー   | 30                            |
| 未認証ユーザー | 10                            |

1分あたりの検索レート制限を超えた検索リクエストは、次のエラーを返します。

```plaintext
This endpoint has been requested too many times. Try again later.
```

### オートコンプリートユーザーのレート制限

{{< history >}}

- GitLab 17.10で、`autocomplete_users_rate_limit`[フラグ](feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/368926)されました。デフォルトで無効になっています。

{{< /history >}}

この設定は、オートコンプリートユーザーのリクエストを次のように制限します。

| 制限                | デフォルト（1分あたりのリクエスト数） |
|----------------------|-------------------------------|
| 認証済みユーザー   | 300                           |
| 未認証ユーザー | 100                           |

1分あたりのオートコンプリートのレート制限を超えたオートコンプリートリクエストは、次のエラーを返します。

```plaintext
This endpoint has been requested too many times. Try again later.
```

### パイプライン作成のレート制限

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/362475)されました。

{{< /history >}}

この設定は、パイプライン作成エンドポイントへのリクエストレートを制限します。

[パイプライン作成のレート制限](settings/rate_limit_on_pipelines_creation.md)の詳細を参照してください。

## Gitaly並行処理の制限

クローントラフィックは、Gitalyサービスに大きな負荷をかける可能性があります。このようなワークロードがGitalyサーバーに過剰な負荷をかけることを防ぐために、Gitalyの設定ファイルで並行処理の制限を設定できます。

[Gitaly並行処理の制限](gitaly/concurrency_limiting.md#limit-rpc-concurrency)の詳細を参照してください。

- **デフォルトのレート制限**: 無効。

## イシュー、マージリクエスト、コミットごとのコメント数

イシュー、マージリクエスト、コミットで送信できるコメント数には制限があります。制限に達した場合でも、システムノートは追加できるためイベントの履歴が失われることはありませんが、ユーザーが送信したコメントは失敗します。

- **最大数**: 5,000件のコメント。

## イシュー、マージリクエスト、エピックのコメントおよび説明のサイズ

イシュー、マージリクエスト、エピックのコメントおよび説明のサイズには制限があります。制限を超えるテキスト本文を追加しようとするとエラーが発生し、そのアイテムも作成されません。

この制限は、将来的に引き下げられる可能性があります。

- **最大サイズ**: 約100万文字/約1 MB。

## コミットのタイトルおよび説明のサイズ

サイズの大きいメッセージを含むコミットをGitLabにプッシュすることは可能ですが、次の表示制限が適用されます。

- **タイトル** \- コミットメッセージの最初の行。1 KiBに制限されています。
- **説明** \- コミットメッセージの残りの部分。1 MiBに制限されています。

コミットがプッシュされると、GitLabはタイトルと説明を処理して、イシュー（`#123`）およびマージリクエスト（`!123`）への参照を、イシューおよびマージリクエストへのリンクに置き換えます。

多数のコミットを含むブランチをプッシュすると、最後の100件のコミットのみが処理されます。

## マイルストーン概要のイシュー数

マイルストーン概要ページに読み込まれるイシューの最大数は500件です。この制限を超えると、ページにアラートが表示され、マイルストーン内のすべてのイシューがページングされた[イシューリスト](../user/project/issues/managing_issues.md)へのリンクが表示されます。

- **制限**: 500件のイシュー。

## Gitプッシュごとのパイプライン数

複数のタグまたはブランチなど、1回のGitプッシュで複数の変更をプッシュする場合、トリガーできるタグまたはブランチのパイプラインは4つまでです。この制限により、`git push --all`または`git push --mirror`を使用する際に、意図せず大量のパイプラインが作成されるのを防ぐことができます。

[マージリクエストパイプライン](../ci/pipelines/merge_request_pipelines.md)は制限されていません。Gitプッシュによって複数のマージリクエストを同時に更新する場合、更新されたすべてのマージリクエストに対してマージリクエストパイプラインをトリガーできます。

1回のGitプッシュイベントで任意の数のパイプラインをトリガーできるように制限を解除する場合、管理者は`git_push_create_all_pipelines`[機能フラグ](feature_flags.md)を有効にできます。この機能フラグを有効にすることは推奨されません。一度に多数の変更がプッシュされ、意図せず大量のパイプラインが作成された場合に、GitLabインスタンスに過度の負荷がかかる可能性があるためです。

## アクティビティ履歴の保持

プロジェクトおよび個人のプロファイルのアクティビティ履歴は3年間に制限されます。

## 埋め込みメトリクスの数

パフォーマンス上の理由から、GitLab Flavored Markdown（GLFM）にメトリクスを埋め込む場合は制限があります。

- **最大数**: 100個の埋め込み。

## Webhookの制限

[Webhookのレート制限](#webhook-rate-limit)も参照してください。

### Webhookの数

GitLab Self-ManagedインスタンスでグループまたはプロジェクトのWebhookの最大数を設定するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

# For project webhooks
Plan.default.actual_limits.update!(project_hooks: 200)

# For group webhooks
Plan.default.actual_limits.update!(group_hooks: 100)
```

制限を`0`に設定すると、無効になります。

Webhookのデフォルトの最大数は、プロジェクトあたり`100`、グループあたり`50`です。サブグループのWebhookは、親グループのWebhook制限にはカウントされません。

GitLab.comについては、[GitLab.comのWebhook制限](../user/gitlab_com/_index.md#webhooks)を参照してください。

### Webhookペイロードのサイズ

Webhookペイロードの最大サイズは25 MBです。

### Webhookタイムアウト

GitLabがWebhookを送信した後、HTTP応答を待機する秒数です。

Webhookのタイムアウト値を変更するには、次の手順に従います。

1. Sidekiqを実行しているすべてのGitLabノードで、`/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['webhook_timeout'] = 60
   ```

1. ファイルを保存します。
1. 変更を有効にするには、GitLabを再設定して再起動します。

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

[GitLab.comのWebhook制限](../user/gitlab_com/_index.md#other-limits)も参照してください。

### 再帰的なWebhook

GitLabは、再帰的なWebhookや、他のWebhookからトリガーできるWebhookの制限を超えたWebhookを検出してブロックします。これにより、GitLabは、Webhookを使用してAPIを非再帰的に呼び出すワークフロやー、不合理な数の他のWebhookをトリガーしないワークフローを引き続きサポートできます。

再帰は、Webhookが自身のGitLabインスタンス（APIなど）を呼び出すように設定されている場合に発生する可能性があります。この呼び出しが同じWebhookをトリガーし、無限ループを生み出します。

他のWebhookをトリガーする一連のWebhookが、インスタンスに対して行えるリクエストの最大数は100件です。この制限に達すると、GitLabはそれ以降にトリガーされる他のWebhookをブロックします。

ブロックされた再帰的なWebhook呼び出しは、`auth.log`に`"Recursive webhook blocked from executing"`というメッセージとともに記録されます。

## インポート時のプレースホルダーユーザーの制限

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/455903)されました。

{{< /history >}}

インポート中に作成される[プレースホルダーユーザー](../user/project/import/_index.md#placeholder-users)の数は、トップレベルのネームスペースごとに制限できます。

[GitLab Self-Managed](../subscriptions/self_managed/_index.md)のデフォルトの制限は`0`（無制限）です。

GitLab Self-Managedインスタンスでこの制限を変更するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(import_placeholder_user_limit_tier_1: 200)
```

制限を`0`に設定すると、無効になります。

## プルミラーリング間隔

[プル更新間の最小待機時間](../user/project/repository/mirror/_index.md)は、デフォルトで300秒（5分）に設定されています。たとえば、特定の300秒間に何回トリガーしても、プル更新は1回しか実行されません。

この設定は、[Projects API](../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project)を使用して実行したプル更新のコンテキスト、または**設定 > リポジトリ > リポジトリのミラーリング**で、**今すぐ更新**（{{< icon name="retry" >}}）を選択して強制的に更新する場合に適用されます。この設定は、Sidekiqが自動的に実行する30分間隔の[プルミラーリング](../user/project/repository/mirror/pull.md)のスケジュールには影響しません。

GitLab Self-Managedインスタンスでこの制限を変更するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(pull_mirror_interval_seconds: 200)
```

## 自動応答からの受信メール

GitLabは、`X-Autoreply`ヘッダーを確認することで、自動応答から送信された受信メールをすべて無視します。このようなメールによって、イシューまたはマージリクエストにコメントが作成されることはありません。

## エラートラッキングを通じてSentryから送信されるデータ量

{{< history >}}

- GitLab 15.6で[すべてのSentry応答に対する制限](https://gitlab.com/gitlab-org/gitlab/-/issues/356448)が導入されました。

{{< /history >}}

セキュリティ上の理由とメモリ消費を制限するため、SentryからGitLabに送信されるペイロードのサイズは、最大1 MBに制限されています。

## REST APIにおけるオフセットベースのページネーションで許可される最大オフセット

REST APIでオフセットベースのページネーションを使用する場合、結果セットに対してリクエストできる最大オフセットの制限があります。この制限は、キーセットベースのページネーションもサポートしているエンドポイントにのみ適用されます。ページネーションオプションの詳細については、[APIドキュメントのページネーションに関するセクション](../api/rest/_index.md#pagination)を参照してください。

GitLab Self-Managedインスタンスでこの制限を設定するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(offset_pagination_limit: 10000)
```

- **デフォルトのオフセットページネーション制限**: `50000`。

制限を`0`に設定すると、無効になります。

## CI/CDの制限

### アクティブなパイプライン内のジョブ数

アクティブなパイプラインに含まれるジョブの総数は、プロジェクトごとに制限できます。この制限は、新しいパイプラインが作成されるたびにチェックされます。アクティブなパイプラインとは、次のいずれかの状態にあるパイプラインです。

- `created`
- `pending`
- `running`

新しいパイプラインによってジョブの総数が制限を超える場合、そのパイプラインは`job_activity_limit_exceeded`エラーで失敗します。

- GitLab.comでは、[サブスクリプションプランごとに制限が定義](../user/gitlab_com/_index.md#cicd)されており、この制限はそのプランのすべてのプロジェクトに影響します。
- GitLab Self-Managedの[PremiumまたはUltimate](https://about.gitlab.com/pricing/)サブスクリプションでは、この制限は`default`プランで定義され、すべてのプロジェクトに影響します。この制限は、デフォルトで無効（`0`）になっています。

GitLab Self-Managedインスタンスでこの制限を設定するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(ci_active_jobs: 500)
```

制限を`0`に設定すると、無効になります。

### ジョブが実行できる最大時間

ジョブが実行できるデフォルトの最大時間は60分です。60分を超えて実行されるジョブはタイムアウトになります。

ジョブがタイムアウトになるまでの最大実行時間は変更できます。

- プロジェクトレベル: 特定のプロジェクトについて、[プロジェクトのCI/CD設定](../ci/pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run)で変更します。この制限は、10分から1か月の間でなければなりません。
- [Runnerレベル](../ci/runners/configure_runners.md#set-the-maximum-job-timeout): この制限は10分以上でなければなりません。

### パイプライン内のデプロイジョブの最大数

パイプライン内のデプロイジョブの最大数を制限できます。デプロイとは、[`environment`](../ci/environments/_index.md)が指定されたジョブのことです。パイプライン内のデプロイ数は、パイプラインの作成時にチェックされます。デプロイが多すぎるパイプラインは、`deployments_limit_exceeded`エラーで失敗します。

すべての[GitLab Self-ManagedおよびGitLab.comサブスクリプション](https://about.gitlab.com/pricing/)におけるデフォルトの制限は500です。

GitLab Self-Managedインスタンスの制限を変更するには、次の[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)のコマンドで、`default`プランの制限を変更します。

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(ci_pipeline_deployments: 500)
```

制限を`0`に設定すると、無効になります。

### プロジェクトに対するCI/CDサブスクリプションの数

サブスクリプションの総数は、プロジェクトごとに制限できます。この制限は、新しいサブスクリプションが作成されるたびにチェックされます。

新しいサブスクリプションによってサブスクリプションの総数が制限を超える場合、そのサブスクリプションは無効と見なされます。

- GitLab.comでは、[サブスクリプションプランごとに制限が定義](../user/gitlab_com/_index.md#cicd)されており、この制限はそのプランのすべてのプロジェクトに影響します。
- GitLab Self-Managedの[PremiumまたはUltimate](https://about.gitlab.com/pricing/)では、この制限は`default`プランで定義され、すべてのプロジェクトに影響します。デフォルトでは、サブスクリプション数の制限は`2`です。

GitLab Self-Managedインスタンスでこの制限を設定するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
Plan.default.actual_limits.update!(ci_project_subscriptions: 500)
```

制限を`0`に設定すると、無効になります。

### パイプライントリガー数を制限する

プロジェクトごとにパイプライントリガーの最大数を制限できます。この制限は、新しいトリガーが作成されるたびにチェックされます。

新しいトリガーによってパイプライントリガーの総数が制限を超える場合、そのトリガーは無効と見なされます。

制限を`0`に設定すると、無効になります。GitLab Self-Managedでは、デフォルトの制限は`25000`です。

GitLab Self-Managedインスタンスでこの制限を`100`に設定するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
Plan.default.actual_limits.update!(pipeline_triggers: 100)
```

この制限は[GitLab.comで有効](../user/gitlab_com/_index.md#cicd)になっています。

### パイプラインスケジュール数

パイプラインスケジュールの総数は、プロジェクトごとに制限できます。この制限は、新しいパイプラインスケジュールが作成されるたびにチェックされます。新しいパイプラインスケジュールによってパイプラインスケジュールの総数が制限を超える場合、そのパイプラインスケジュールは作成されません。

GitLab.comでは、[サブスクリプションプランごとに制限が定義](../user/gitlab_com/_index.md#cicd)されており、この制限はそのプランのすべてのプロジェクトに影響します。

GitLab Self-Managedの[PremiumまたはUltimate](https://about.gitlab.com/pricing/)では、この制限は`default`プランで定義され、すべてのプロジェクトに影響します。デフォルトでは、パイプラインスケジュール数の制限は`10`です。

GitLab Self-Managedインスタンスでこの制限を設定するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
Plan.default.actual_limits.update!(ci_pipeline_schedules: 100)
```

### 1日にパイプラインスケジュールによって作成できるパイプラインの数を制限する

パイプラインスケジュールが1日にトリガーできるパイプラインの数を制限できます。

制限を超えてパイプラインを実行しようとするスケジュールは、最大実行頻度まで抑制されます。この頻度は、1,440（1日の分数）を制限値で割ることで計算されます。最大頻度ごとの例を示します。

- 1分に1回の場合、制限値は`1440`になります。
- 10分に1回の場合、制限値は`144`になります。
- 60分に1回の場合、制限値は`24`になります。

最小値は`24`、つまり60分に1回です。最大値の制限はありません。

GitLab Self-Managedインスタンスでこの制限を`1440`に設定するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
Plan.default.actual_limits.update!(ci_daily_pipeline_schedule_triggers: 1440)
```

この制限は[GitLab.comで有効](../user/gitlab_com/_index.md#cicd)になっています。

### セキュリティポリシープロジェクトに定義できるスケジュールルールの数を制限する

{{< history >}}

- GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/335659)されました。

{{< /history >}}

セキュリティポリシープロジェクトごとに、スケジュールルールの総数を制限できます。この制限は、スケジュールルールを含むポリシーが更新されるたびにチェックされます。新しいスケジュールルールによってスケジュールルールの総数が制限を超える場合、新しいスケジュールルールは処理されません。

デフォルトでは、GitLab Self-Managedでは処理可能なスケジュールルール数に制限はありません。

GitLab Self-Managedインスタンスでこの制限を設定するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
Plan.default.actual_limits.update!(security_policy_scan_execution_schedules: 100)
```

この制限は[GitLab.comで有効](../user/gitlab_com/_index.md#cicd)になっています。

### CI/CD変数の制限

{{< history >}}

- GitLab 15.7で、グループおよびプロジェクト変数の制限が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/362227)されました。

{{< /history >}}

プロジェクト、グループ、インスタンスの各設定で定義できる[CI/CD変数](../ci/variables/_index.md)の数は、インスタンス全体で制限されています。これらの制限は、新しい変数が作成されるたびにチェックされます。新しい変数によって変数の総数がそれぞれの制限を超える場合、新しい変数は作成されません。

GitLab Self-Managedインスタンスで、これらの制限の`default`プランを更新するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

- [インスタンスレベルのCI/CD変数](../ci/variables/_index.md#for-an-instance)制限（デフォルト: `25`）:

  ```ruby
  Plan.default.actual_limits.update!(ci_instance_level_variables: 30)
  ```

- [グループレベルのCI/CD変数](../ci/variables/_index.md#for-a-group)制限（グループごと、デフォルト: `30000`）:

  ```ruby
  Plan.default.actual_limits.update!(group_ci_variables: 40000)
  ```

- [プロジェクトレベルのCI/CD変数](../ci/variables/_index.md#for-a-project)制限（プロジェクトごと、デフォルト: `8000`）:

  ```ruby
  Plan.default.actual_limits.update!(project_ci_variables: 10000)
  ```

### アーティファクトのタイプごとの最大ファイルサイズ

{{< history >}}

- GitLab 16.3で`ci_max_artifact_size_annotations`制限が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/38337)されました。
- GitLab 17.8で`ci_max_artifact_size_lsif`制限が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175684)されました。

{{< /history >}}

[`artifacts:reports`](../ci/yaml/_index.md#artifactsreports)で定義されたジョブアーティファクトについて、Runnerによってアップロードされたファイルが最大ファイルサイズ制限を超える場合、そのファイルは拒否されます。この制限は、プロジェクトの[最大アーティファクトサイズ設定](settings/continuous_integration.md#maximum-artifacts-size)と、指定されたアーティファクトタイプに対するインスタンスの制限を比較し、小さい方の値が適用されます。

制限はメガバイト単位で設定されるため、定義できる最小値は`1 MB`です。

アーティファクトのタイプごとにサイズ制限を設定できます。デフォルトが`0`の場合、その特定のアーティファクトタイプには制限がなく、プロジェクトの最大アーティファクトサイズ設定が使用されます。

| アーティファクト制限名                         | デフォルト値 |
|---------------------------------------------|---------------|
| `ci_max_artifact_size_accessibility`        | 0             |
| `ci_max_artifact_size_annotations`          | 0             |
| `ci_max_artifact_size_api_fuzzing`          | 0             |
| `ci_max_artifact_size_archive`              | 0             |
| `ci_max_artifact_size_browser_performance`  | 0             |
| `ci_max_artifact_size_cluster_applications` | 0             |
| `ci_max_artifact_size_cobertura`            | 0             |
| `ci_max_artifact_size_codequality`          | 0             |
| `ci_max_artifact_size_container_scanning`   | 0             |
| `ci_max_artifact_size_coverage_fuzzing`     | 0             |
| `ci_max_artifact_size_dast`                 | 0             |
| `ci_max_artifact_size_dependency_scanning`  | 0             |
| `ci_max_artifact_size_dotenv`               | 0             |
| `ci_max_artifact_size_junit`                | 0             |
| `ci_max_artifact_size_license_management`   | 0             |
| `ci_max_artifact_size_license_scanning`     | 0             |
| `ci_max_artifact_size_load_performance`     | 0             |
| `ci_max_artifact_size_lsif`                 | 200 MB        |
| `ci_max_artifact_size_metadata`             | 0             |
| `ci_max_artifact_size_metrics_referee`      | 0             |
| `ci_max_artifact_size_metrics`              | 0             |
| `ci_max_artifact_size_network_referee`      | 0             |
| `ci_max_artifact_size_performance`          | 0             |
| `ci_max_artifact_size_requirements`         | 0             |
| `ci_max_artifact_size_requirements_v2`      | 0             |
| `ci_max_artifact_size_sast`                 | 0             |
| `ci_max_artifact_size_secret_detection`     | 0             |
| `ci_max_artifact_size_terraform`            | 5 MB          |
| `ci_max_artifact_size_trace`                | 0             |
| `ci_max_artifact_size_cyclonedx`            | 5 MB          |

たとえば、`ci_max_artifact_size_junit`制限をGitLab Self-Managedで10 MBに設定するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
Plan.default.actual_limits.update!(ci_max_artifact_size_junit: 10)
```

### GitLab Pages Webサイトごとのファイル数

ファイルエントリの総数（ディレクトリとシンボリックリンクを含む）は、GitLab Pages Webサイトごとに`200,000`件に制限されています。

これは、[GitLab Self-ManagedおよびGitLab.com](https://about.gitlab.com/pricing/)のデフォルトの制限です。

GitLab Self-Managedインスタンスで制限を更新するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)を使用します。たとえば、制限を`100`に変更するには、次のコマンドを実行します。

```ruby
Plan.default.actual_limits.update!(pages_file_entries: 100)
```

### GitLab Pages Webサイトごとのカスタムドメイン数

GitLab Pages Webサイトごとのカスタムドメインの総数は、[GitLab.com](../subscriptions/gitlab_com/_index.md)では`150`に制限されています。

[GitLab Self-Managed](../subscriptions/self_managed/_index.md)のデフォルトの制限は`0`（無制限）です。インスタンスに制限を設定するには、[**管理者**エリア](pages/_index.md#set-maximum-number-of-gitlab-pages-custom-domains-for-a-project)を使用します。

### Pagesの並列デプロイ数

[Pagesの並列デプロイ](../user/project/pages/_index.md#parallel-deployments)を使用する場合、トップレベルのネームスペースで許可されるPagesの並列デプロイの総数は1,000です。

### スコープごとの登録Runner数

{{< history >}}

- GitLab 17.1で、Runnerの非アクティブタイムアウトは、3か月から7日に[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155795)されました。

{{< /history >}}

グループとプロジェクトに登録できるRunnerの総数は制限されています。新しいRunnerが登録されるたびに、GitLabは過去7日間に作成された、またはアクティブだったRunnerに対してこの制限をチェックします。Runner登録トークンで決定されるスコープの制限を超えた場合、Runnerの登録は失敗します。制限値がゼロに設定されている場合、制限は無効になります。

GitLab.comのサブスクライバーは、サブスクリプションごとに異なる制限が定義されており、そのサブスクリプションを使用するすべてのプロジェクトに影響します。

GitLab Self-ManagedのPremiumおよびUltimateでは、この制限はデフォルトプランで定義され、すべてのプロジェクトに影響します。

| Runnerのスコープ                    | デフォルト値 |
|---------------------------------|---------------|
| `ci_registered_group_runners`   | 1,000          |
| `ci_registered_project_runners` | 1,000          |

これらの制限を更新するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
# Use ci_registered_group_runners or ci_registered_project_runners
# depending on desired scope
Plan.default.actual_limits.update!(ci_registered_project_runners: 100)
```

### ジョブログの最大ファイルサイズ

GitLabのジョブログファイルサイズの制限は、デフォルトで100 MBです。制限を超過したジョブは失敗とマークされ、Runnerによって破棄されます。

この制限は[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で変更できます。`ci_jobs_trace_size_limit`に、新しい値をメガバイト単位で設定します。

```ruby
Plan.default.actual_limits.update!(ci_jobs_trace_size_limit: 125)
```

GitLab Runnerには、Runner内の最大ログサイズを指定する[`output_limit`という設定](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)もあります。Runnerの制限を超えたジョブは引き続き実行されますが、ログは制限に達すると切り詰められます。

### プロジェクトごとのアクティブなDASTプロファイルスケジュールの最大数

プロジェクトごとのアクティブなDASTプロファイルスケジュールの数を制限できます。DASTプロファイルスケジュールは、アクティブまたは非アクティブにすることができます。

この制限は[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で変更できます。`dast_profile_schedules`に新しい値を設定します。

```ruby
Plan.default.actual_limits.update!(dast_profile_schedules: 50)
```

### CIアーティファクトアーカイブの最大サイズ

この設定は、[動的な子パイプライン](../ci/pipelines/downstream_pipelines.md#dynamic-child-pipelines)におけるYAMLのサイズを制限するために使用されます。

CIアーティファクトアーカイブのデフォルトの最大サイズは5メガバイトです。

この制限を変更するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)を使用します。CIアーティファクトアーカイブの最大サイズを更新するには、`max_artifacts_content_include_size`に新しい値設定します。たとえば、20 MBに設定するには、次のコマンドを実行します。

```ruby
ApplicationSetting.update(max_artifacts_content_include_size: 20.megabytes)
```

### CI/CD設定YAMLファイルの最大サイズと最大深度

単一のCI/CD設定YAMLファイルに対するデフォルトの最大サイズは1メガバイトで、デフォルトの最大深度は100です。

これらの制限は、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で変更できます。

- YAMLの最大サイズを更新するには、`max_yaml_size_bytes`に新しい値をメガバイト単位で設定します。

  ```ruby
  ApplicationSetting.update(max_yaml_size_bytes: 2.megabytes)
  ```

  `max_yaml_size_bytes`の値はYAMLファイルのサイズに直接関係するのではなく、関連オブジェクトに割り当てられるメモリに関係します。

- YAMLの最大深度を更新するには、`max_yaml_depth`に行数単位で新しい値を設定します。

  ```ruby
  ApplicationSetting.update(max_yaml_depth: 125)
  ```

### CI/CD設定全体の最大サイズ

すべてのYAML設定ファイルを含む、パイプライン設定全体に対して割り当て可能な最大メモリ量（バイト単位）です。

新しいGitLab Self-Managedインスタンスの場合、デフォルトは`157286400`バイト（150 MB）です。

GitLab 16.3以降にアップグレードする既存のインスタンスの場合、デフォルトは、[`max_yaml_size_bytes`（デフォルト1 MB）](#maximum-size-and-depth-of-cicd-configuration-yaml-files)に[`ci_max_includes`（デフォルト150）](../api/settings.md#available-settings)を乗算することで計算されます。両方の制限が変更されていない場合、デフォルトは1 MB x 150 = `157286400`バイト（150 MB）に設定されます。

この制限を変更するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)を使用します。CI/CD設定に割り当て可能な最大メモリ量を更新するには、`ci_max_total_yaml_size_bytes`に新しい値を設定します。たとえば、20 MBに設定するには、次のコマンドを実行します。

```ruby
ApplicationSetting.update(ci_max_total_yaml_size_bytes: 20.megabytes)
```

### dotenv変数を制限する

dotenvアーティファクト内の変数の最大数に制限を設定できます。この制限は、dotenvファイルがアーティファクトとしてエクスポートされるたびにチェックされます。

制限を`0`に設定すると、無効になります。GitLab Self-Managedでは、デフォルトの制限は`20`です。

インスタンスでこの制限を`100`に設定するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
Plan.default.actual_limits.update!(dotenv_variables: 100)
```

この制限は、[GitLab UI](settings/continuous_integration.md#set-cicd-limits)または[Plan limits API](../api/plan_limits.md)を使用して設定することもできます。

この制限は[GitLab.comで有効](../user/gitlab_com/_index.md#cicd)になっています。

### dotenvファイルサイズを制限する

dotenvアーティファクトの最大サイズに制限を設定できます。この制限は、dotenvファイルがアーティファクトとしてエクスポートされるたびにチェックされます。

制限を`0`に設定すると、無効になります。デフォルトは5 KBです。

GitLab Self-Managedインスタンスでこの制限を5 KBに設定するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
Plan.default.actual_limits.update!(dotenv_size: 5.kilobytes)
```

### CI/CDジョブのアノテーション数を制限する

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/38337)されました。

{{< /history >}}

CI/CDジョブごとの[アノテーション](../ci/yaml/artifacts_reports.md#artifactsreportsannotations)の最大数に制限を設定できます。

制限を`0`に設定すると、無効になります。GitLab Self-Managedでは、デフォルトの制限は`20`です。

インスタンスでこの制限を`100`に設定するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
Plan.default.actual_limits.update!(ci_job_annotations_num: 100)
```

### CI/CDジョブのアノテーションファイルサイズを制限する

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/38337)されました。

{{< /history >}}

CI/CDジョブの[アノテーション](../ci/yaml/artifacts_reports.md#artifactsreportsannotations)の最大サイズに制限を設定できます。

制限を`0`に設定すると、無効になります。デフォルトは80 KBです。

GitLab Self-Managedインスタンスでこの制限を100 KBに設定するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
Plan.default.actual_limits.update!(ci_job_annotations_size: 100.kilobytes)
```

## インスタンスのモニタリングとメトリクス

### 受信できるインシデント管理アラートを制限する

この設定は、一定期間に受信できるアラートのペイロード数を制限します。

[インシデント管理のレート制限](settings/rate_limit_on_pipelines_creation.md)の詳細を参照してください。

### PrometheusアラートのJSONペイロード

`notify.json`エンドポイントに送信されるPrometheusアラートのペイロードは、サイズが1 MBに制限されています。

### 汎用アラートのJSONペイロード

`notify.json`エンドポイントに送信されるアラートのペイロードは、サイズが1 MBに制限されています。

### メトリクスダッシュボードのYAMLファイル

解析済みのメトリクスダッシュボードのYAMLファイルが占有するメモリは、最大1 MBまでです。

各YAMLファイルの最大深度は100に制限されています。YAMLファイルの最大深度とは、最もネストされたキーのネストの深さのことです。最も深くネストされたキーへのパス上にあるすべてのハッシュおよび配列が、深度としてカウントされます。たとえば、次のYAMLファイルにおける最もネストされたキーの深度は7です。

```yaml
dashboard: 'Test dashboard'
links:
- title: Link 1
  url: https://gitlab.com
panel_groups:
- group: Group A
  priority: 1
  panels:
  - title: "Super Chart A1"
    type: "area-chart"
    y_label: "y_label"
    weight: 1
    max_value: 1
    metrics:
    - id: metric_a1
      query_range: 'query'
      unit: unit
      label: Legend Label
```

## 環境ダッシュボードの制限

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

表示されるプロジェクトの最大数については、[環境ダッシュボード](../ci/environments/environments_dashboard.md#adding-a-project-to-the-dashboard)を参照してください。

## デプロイボードの環境データ

[デプロイボード](../user/project/deploy_boards.md)は、Kubernetesからポッドとデプロイに関する情報を読み込みます。ただし、特定の環境についてKubernetesから読み取られたデータが10 MBを超える場合、そのデータは表示されません。

## マージリクエスト

### 差分の制限

GitLabには、以下の制限があります。

- 単一ファイルのパッチサイズ。[これはGitLab Self-Managedで設定可能です](diff_limits.md)。
- マージリクエストに含まれるすべての差分の合計サイズ。

以下のそれぞれに、上限と下限が適用されます。

- 変更されたファイル数
- 変更された行数
- 表示される変更の累積サイズ

下限に到達すると、追加の差分が折りたたまれます。上限を上回ると、それ以上の変更は表示されません。これらの制限の詳細については、[開発ドキュメントを参照してください](../development/merge_request_concepts/diffs/_index.md#diff-limits)。

### 差分バージョンの制限

{{< history >}}

- GitLab 17.10で、`merge_requests_diffs_limit`[フラグ](feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/521970)されました。デフォルトで無効になっています。
- GitLab 17.10の[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/521970)。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については履歴を参照してください。この機能はテストには使用できますが、本番環境での使用には適していません。

{{< /alert >}}

GitLabでは、各マージリクエストを1,000個の[差分バージョン](../user/project/merge_requests/versions.md)に制限しています。この制限に達したマージリクエストは、それ以上更新できません。代わりに、影響を受けたマージリクエストをクローズし、新しいマージリクエストを作成してください。

### マージリクエストのレポートサイズ制限

20 MBを超えるレポートは読み込まれません。影響を受けるレポートは次のとおりです。

- [マージリクエストのセキュリティレポート](../ci/testing/_index.md#security-reports)
- [CI/CDパラメーター`artifacts:expose_as`](../ci/yaml/_index.md#artifactsexpose_as)
- [単体試験レポート](../ci/testing/unit_test_reports.md)

## 高度な検索の制限

### インデックスが作成されるファイルの最大サイズ

Elasticsearchでインデックスを作成するリポジトリファイルの内容に、制限を設定できます。この制限よりも大きいファイルは、ファイル名のみがインデックス作成の対象となります。ファイルの内容についてはインデックスが作成されず、検索できません。

制限を設定することで、インデックス作成プロセスのメモリ使用量とインデックス全体のサイズを削減できます。この値は、デフォルトで`1024 KiB`（1 MiB）に設定されています。これよりも大きいテキストファイルは、人間が読むことを目的としていない可能性が高いためです。

無制限のファイルサイズはサポートしていないため、必ず制限を設定する必要があります。この値をGitLab Sidekiqノードのメモリ量よりも大きく設定すると、インデックス作成時にこのメモリ量が事前に割り当てられるため、GitLab Sidekiqノードのメモリが不足する可能性があります。

### 最大フィールド長

高度な検索用にインデックスが作成されるテキストフィールドの内容に、制限を設定できます。最大値を設定すると、インデックス作成プロセスの負荷を軽減できます。テキストフィールドがこの制限を超えると、テキストは指定した文字数に切り詰められます。テキストの残りの部分についてはインデックスが作成されず、検索できません。別の制限が適用されるリポジトリファイルを除く、インデックス作成対象のすべてのデータにこの制限が適用されます。詳細については、[インデックスが作成されるファイルの最大サイズ](#maximum-file-size-indexed)を参照してください。

- GitLab.comでは、フィールドの文字数制限は20,000文字です。
- GitLab Self-Managedインスタンスの場合、デフォルトでフィールドの文字数に制限はありません。

[Elasticsearchを有効にする](../integration/advanced_search/elasticsearch.md#enable-advanced-search)際に、GitLab Self-Managedインスタンスに対してこの制限を設定できます。制限を`0`に設定すると、無効になります。

## 数式のレンダリング制限

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132939)されました。
- Wikiおよびリポジトリファイルに対する50ノードの制限が[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/368009)されました。
- GitLab 16.9で、数式レンダリング制限を無効にできるグループレベルの設定が[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/368009)され、Wikiおよびリポジトリファイルの数式制限がデフォルトで再度有効になりました。

{{< /history >}}

GitLabでは、Markdownフィールドで数式をレンダリングする際に、デフォルトの制限が課せられます。これらの制限により、セキュリティとパフォーマンスが向上します。

イシュー、マージリクエスト、エピック、Wiki、リポジトリファイルに対する制限は次のとおりです。

- マクロ展開の最大数: `1000`
- ユーザー指定の最大サイズ（[em](https://en.wikipedia.org/wiki/Em_(typography))単位）: `20`
- レンダリングされるノードの最大数: `50`
- 数式ブロック内の最大文字数: `1000`
- 最大レンダリング時間: `2000 ms`

GitLab Self-Managedを実行しており、ユーザー入力を信頼できる場合は、これらの制限を無効にできます。

[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)を使用します。

```ruby
ApplicationSetting.update(math_rendering_limits_enabled: false)
```

これらの制限は、GraphQLまたはREST APIを使用して、グループ単位で無効にすることもできます。

この制限を無効にすると、イシュー、マージリクエスト、エピック、Wiki、リポジトリファイル内の数式はほぼ無制限にレンダリングされます。これは、悪意のあるアクターが、ブラウザでの閲覧時にDoSを引き起こす可能性のある数式を_追加できる_ことを意味します。そのため、信頼できるユーザーのみがコンテンツを追加できるようにする必要があります。

## Wikiの制限

- [Wikiページコンテンツのサイズ制限](wikis/_index.md#wiki-page-content-size-limit)
- [ファイル名とディレクトリ名の長さ制限](../user/project/wiki/_index.md#length-restrictions-for-file-and-directory-names)

## スニペットの制限

[スニペットの設定に関するドキュメント](snippets/_index.md)を参照してください。

## 設計管理の制限

[イシューにデザインを追加する](../user/project/issues/design_management.md#add-a-design-to-an-issue)セクションの制限を参照してください。

## プッシュイベントの制限

### 最大プッシュサイズ

許可される[プッシュサイズ](settings/account_and_limit_settings.md#max-push-size)の最大値。

GitLab Self-Managedでは、デフォルトで設定されていません。GitLab.comについては、[アカウントと制限の設定](../user/gitlab_com/_index.md#account-and-limit-settings)を参照してください。

### Webhookとプロジェクトサービス

単一のプッシュで行われる変更（ブランチまたはタグ）の合計数。変更数が指定された制限を超えると、フックは実行されません。

詳細については、以下を参照してください。

- [Webhookプッシュイベント](../user/project/integrations/webhook_events.md#push-events)
- [プロジェクトインテグレーションのプッシュフック制限](../user/project/integrations/_index.md#push-hook-limit)

### アクティビティ

単一のプッシュにおける変更（ブランチまたはタグ）の合計数。この値を基準に、個別のプッシュイベントを作成するか、一括プッシュイベントを作成するかが決まります。

詳細については、[プッシュイベントアクティビティの制限と一括プッシュイベントに関するドキュメント](settings/push_event_activities_limit.md)を参照してください。

## パッケージレジストリの制限

### ファイルサイズの制限

[GitLabパッケージレジストリ](../user/packages/package_registry/_index.md)にアップロードされるパッケージのデフォルトの最大ファイルサイズは、形式によって異なります。

- Conan: 3 GB
- 汎用: 5 GB
- Helm: 5 MB
- Maven: 3 GB
- npm: 500 MB
- NuGet: 500 MB
- PyPI: 3 GB
- Terraform: 1 GB

[GitLab.comの最大ファイルサイズ](../user/gitlab_com/_index.md#package-registry-limits)は異なる場合があります。

GitLab Self-Managedインスタンスでこれらの制限を設定するには、[**管理者**エリアを使用する](settings/continuous_integration.md#package-file-size-limits)か、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
# File size limit is stored in bytes

# For Conan Packages
Plan.default.actual_limits.update!(conan_max_file_size: 100.megabytes)

# For npm Packages
Plan.default.actual_limits.update!(npm_max_file_size: 100.megabytes)

# For NuGet Packages
Plan.default.actual_limits.update!(nuget_max_file_size: 100.megabytes)

# For Maven Packages
Plan.default.actual_limits.update!(maven_max_file_size: 100.megabytes)

# For PyPI Packages
Plan.default.actual_limits.update!(pypi_max_file_size: 100.megabytes)

# For Debian Packages
Plan.default.actual_limits.update!(debian_max_file_size: 100.megabytes)

# For Helm Charts
Plan.default.actual_limits.update!(helm_max_file_size: 100.megabytes)

# For Generic Packages
Plan.default.actual_limits.update!(generic_packages_max_file_size: 100.megabytes)
```

制限を`0`に設定すると、ファイルサイズは無制限になります。

### 返されるパッケージのバージョン数

指定されたNuGetパッケージ名のバージョンを要求すると、GitLabパッケージレジストリは最大300件のバージョンを返します。

## 依存プロキシの制限

[依存プロキシ](../user/packages/dependency_proxy/_index.md)でキャッシュされるイメージの最大ファイルサイズは、ファイルタイプによって異なります。

- イメージblob: 5 GB
- イメージmanifest: 10 MB

## 担当者とレビュアーの最大数

{{< history >}}

- GitLab 15.6で、担当者の最大数が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/368936)されました。
- GitLab 15.9で、レビュアーの最大数が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/366485)されました。

{{< /history >}}

イシューとマージリクエストでは、次の最大数が適用されます。

- 担当者の最大数: 200
- レビュアーの最大数: 200

## GitLab.comのCDNベースの制限

アプリケーションベースの制限に加えて、GitLab.comでは、Cloudflare（標準的なDDoS保護）とSpectrum（SSH経由のGitアクセスの保護）を使用するよう設定されています。CloudflareはクライアントTLS接続を終端しますが、アプリケーションを認識しないため、ユーザーやグループに関連付けられた制限には使用できません。Cloudflareのページルールとレート制限はTerraformで設定されています。これらの設定は、悪意のあるアクティビティを検出するセキュリティ対策や不正行為防止対策が含まれているため、[公開されていません](https://handbook.gitlab.com/handbook/communication/confidentiality-levels/#not-public)。公開すると、これらの対策の効果が損なわれるおそれがあります。

## コンテナリポジトリのタグ削除制限

コンテナリポジトリタグはコンテナレジストリ内にあるため、タグを削除するたびに、コンテナレジストリへのネットワークリクエストがトリガーされます。このため、1回のAPIコールで削除できるタグの数を20に制限しています。

## プロジェクトレベルのSecure Files APIの制限

[Secure Files API](../api/secure_files.md)には、次の制限が適用されます。

- ファイルは5 MB未満である必要があります。
- プロジェクトに登録できるセキュアファイルの最大数は100です。

## Changelog APIの制限

{{< history >}}

- GitLab 15.1で、`changelog_commits_limitation`[フラグ](feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89032)されました。デフォルトで無効になっています。
- GitLab 15.3の[GitLab.comで有効になり、GitLab Self-Managedではデフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/33893)になりました。
- GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/364101)になりました。機能フラグ`changelog_commits_limitation`が削除されました。

{{< /history >}}

[Changelog API](../api/repositories.md#add-changelog-data-to-a-changelog-file)には、次の制限が適用されます。

- `from`と`to`の間のコミット範囲は、15,000コミットを超えることはできません。

## バリューストリーム分析の制限

- 各ネームスペース（グループやプロジェクトなど）は、最大50個のバリューストリームを持つことができます。
- 各バリューストリームは、最大15個のステージを持つことができます。

## 監査イベントストリーミングの配信先の制限

### カスタムHTTPエンドポイント

- 各トップレベルグループには、最大5つのカスタムHTTPストリーミング配信先を設定できます。

### Google Cloud Logging

- 各トップレベルグループには、最大5つのGoogle Cloud Loggingストリーミング配信先を設定できます。

### Amazon S3

- 各トップレベルグループには、最大5つのAmazon S3ストリーミング配信先を設定できます。

## すべてのインスタンス制限値を一覧表示する

すべてのインスタンス制限値を一覧表示するには、[GitLab Railsコンソール](operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
Plan.default.actual_limits
```

出力例: 

```ruby
id: 1,
plan_id: 1,
ci_pipeline_size: 0,
ci_active_jobs: 0,
project_hooks: 100,
group_hooks: 50,
ci_project_subscriptions: 3,
ci_pipeline_schedules: 10,
offset_pagination_limit: 50000,
ci_instance_level_variables: "[FILTERED]",
storage_size_limit: 0,
ci_max_artifact_size_lsif: 200,
ci_max_artifact_size_archive: 0,
ci_max_artifact_size_metadata: 0,
ci_max_artifact_size_trace: "[FILTERED]",
ci_max_artifact_size_junit: 0,
ci_max_artifact_size_sast: 0,
ci_max_artifact_size_dependency_scanning: 350,
ci_max_artifact_size_container_scanning: 150,
ci_max_artifact_size_dast: 0,
ci_max_artifact_size_codequality: 0,
ci_max_artifact_size_license_management: 0,
ci_max_artifact_size_license_scanning: 100,
ci_max_artifact_size_performance: 0,
ci_max_artifact_size_metrics: 0,
ci_max_artifact_size_metrics_referee: 0,
ci_max_artifact_size_network_referee: 0,
ci_max_artifact_size_dotenv: 0,
ci_max_artifact_size_cobertura: 0,
ci_max_artifact_size_terraform: 5,
ci_max_artifact_size_accessibility: 0,
ci_max_artifact_size_cluster_applications: 0,
ci_max_artifact_size_secret_detection: "[FILTERED]",
ci_max_artifact_size_requirements: 0,
ci_max_artifact_size_coverage_fuzzing: 0,
ci_max_artifact_size_browser_performance: 0,
ci_max_artifact_size_load_performance: 0,
ci_needs_size_limit: 2,
conan_max_file_size: 3221225472,
maven_max_file_size: 3221225472,
npm_max_file_size: 524288000,
nuget_max_file_size: 524288000,
pypi_max_file_size: 3221225472,
generic_packages_max_file_size: 5368709120,
golang_max_file_size: 104857600,
debian_max_file_size: 3221225472,
project_feature_flags: 200,
ci_max_artifact_size_api_fuzzing: 0,
ci_pipeline_deployments: 500,
pull_mirror_interval_seconds: 300,
daily_invites: 0,
rubygems_max_file_size: 3221225472,
terraform_module_max_file_size: 1073741824,
helm_max_file_size: 5242880,
ci_registered_group_runners: 1000,
ci_registered_project_runners: 1000,
ci_daily_pipeline_schedule_triggers: 0,
ci_max_artifact_size_cluster_image_scanning: 0,
ci_jobs_trace_size_limit: "[FILTERED]",
pages_file_entries: 200000,
dast_profile_schedules: 1,
external_audit_event_destinations: 5,
dotenv_variables: "[FILTERED]",
dotenv_size: 5120,
pipeline_triggers: 25000,
project_ci_secure_files: 100,
repository_size: 0,
security_policy_scan_execution_schedules: 0,
web_hook_calls_mid: 0,
web_hook_calls_low: 0,
project_ci_variables: "[FILTERED]",
group_ci_variables: "[FILTERED]",
ci_max_artifact_size_cyclonedx: 1,
rpm_max_file_size: 5368709120,
pipeline_hierarchy_size: 1000,
ci_max_artifact_size_requirements_v2: 0,
enforcement_limit: 0,
notification_limit: 0,
dashboard_limit_enabled_at: nil,
web_hook_calls: 0,
project_access_token_limit: 0,
google_cloud_logging_configurations: 5,
ml_model_max_file_size: 10737418240,
limits_history: {},
audit_events_amazon_s3_configurations: 5
```

[Railsコンソールでのフィルタリング](operations/rails_console.md#filtered-console-output)により、一部の制限値はリストに`[FILTERED]`と表示されます。
