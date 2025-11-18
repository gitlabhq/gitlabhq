---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: レート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

GitLab.comの場合、[GitLab.com固有のレート制限](../user/gitlab_com/_index.md#rate-limits-on-gitlabcom)を参照してください。

{{< /alert >}}

レート制限は、Webアプリケーションのセキュリティと耐久性を向上させるためによく使用される手法です。

たとえば、簡単なスクリプトで1秒あたり数千件のWebリクエストを送信できます。リクエストは次のいずれかである可能性があります:

- 悪意のある。
- 無関心。
- 単なるバグ。

アプリケーションとインフラストラクチャが負荷に対応できない可能性があります。詳細については、[サービス拒否](https://en.wikipedia.org/wiki/Denial-of-service_attack)を参照してください。ほとんどの場合、単一のIPアドレスからのリクエストのレート制限によって軽減できます。

ほとんどの[総当たり攻撃](https://en.wikipedia.org/wiki/Brute-force_attack)も同様に、レート制限によって軽減されます。

{{< alert type="note" >}}

APIリクエストのレート制限は、これらのリクエストが常にWebトラフィックとしてカウントされるため、フロントエンドからのリクエストには影響しません。

{{< /alert >}}

## 設定可能なレート制限 {#configurable-limits}

これらのレート制限は、インスタンスの**管理者**エリアで設定できます: 

- [インポート/エクスポートのレート制限](../administration/settings/import_export_rate_limits.md)
- [イシューのレート制限](../administration/settings/rate_limit_on_issues_creation.md)
- [Noteレート制限](../administration/settings/rate_limit_on_notes_creation.md)
- [保護パス](../administration/settings/protected_paths.md)
- [raw](../administration/settings/rate_limits_on_raw_endpoints.md)エンドポイントのレート制限
- [ユーザーとIPのレート制限](../administration/settings/user_and_ip_rate_limits.md)
- [パッケージレジストリのレート制限](../administration/settings/package_registry_rate_limits.md)
- [Git LFSのレート制限](../administration/settings/git_lfs_rate_limits.md)
- [Git SSH操作のレート制限](../administration/settings/rate_limits_on_git_ssh_operations.md)
- [ファイルAPIのレート制限](../administration/settings/files_api_rate_limits.md)
- [非推奨のAPIのレート制限](../administration/settings/deprecated_api_rate_limits.md)
- [GitLab Pagesのレート制限](../administration/pages/_index.md#rate-limits)
- [パイプラインのレート制限](../administration/settings/rate_limit_on_pipelines_creation.md)
- [インシデント管理のレート制限](../administration/settings/incident_management_rate_limits.md)
- [プロジェクトAPIのレート制限](../administration/settings/rate_limit_on_projects_api.md)
- [グループAPIのレート制限](../administration/settings/rate_limit_on_groups_api.md)
- [ユーザーAPIのレート制限](../administration/settings/rate_limit_on_users_api.md)
- [組織APIのレート制限](../administration/settings/rate_limit_on_organizations_api.md)

これらのレート制限は、[ApplicationSettings API](../api/settings.md)を使用して設定できます: 

- [オートコンプリートユーザーのレート制限](../administration/instance_limits.md#autocomplete-users-rate-limit)

これらのレート制限は、Railsコンソールを使用して設定できます: 

- [Webhookのレート制限](../administration/instance_limits.md#webhook-rate-limit)

## Gitとコンテナレジストリの認証失敗によるBAN {#failed-authentication-ban-for-git-and-container-registry}

単一のIPアドレスから3分間に30回の認証失敗リクエストを受信した場合、GitLabは1時間`403`のHTTPステータスコードを返します。これは、以下を組み合わせた場合にのみ適用されます: 

- Gitリクエスト。
- コンテナレジストリ (`/jwt/auth`) リクエスト。

この制限は、次のようになります: 

- 認証に成功したリクエストでリセットされます。たとえば、29回の認証失敗リクエストの後に1回の成功リクエストがあり、その後にさらに29回の認証失敗リクエストが続いても、BANはトリガーされません。
- `gitlab-ci-token`で認証されたJSON Webトークンリクエストには適用されません。
- デフォルトでは無効になっています。

応答ヘッダーは提供されません。

レート制限を回避するには、次の方法があります: 

- 自動パイプラインの実行を段階的に行います。
- 認証の試行に[指数バックオフと再試行](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html)を設定します。
- ドキュメント化されたプロセスと[ベストプラクティス](https://about.gitlab.com/blog/2023/10/25/access-token-lifetime-limits/#how-to-minimize-the-impact)を使用して、トークンの有効期限を管理します。

設定情報については、[Linuxパッケージの設定オプション](https://docs.gitlab.com/omnibus/settings/configuration.html#configure-a-failed-authentication-ban)を参照してください。

## 設定できない制限 {#non-configurable-limits}

### リポジトリアーカイブ {#repository-archives}

[リポジトリアーカイブのダウンロード](../api/repositories.md#get-file-archive)のレート制限が利用可能です。この制限は、プロジェクトと、UIまたはAPIを介してダウンロードを開始するユーザーに適用されます。

**rate limit**（レート制限）は、ユーザーあたり1分あたり5リクエストです。

### Webhookのテスト {#webhook-testing}

[Webhookのテスト](../user/project/integrations/webhooks.md#test-a-webhook)にはレート制限があり、Webhook機能の悪用を防ぎます。

**rate limit**（レート制限）は、ユーザーあたり1分あたり5リクエストです。

### ユーザーサインアップ {#users-sign-up}

`/users/sign_up`エンドポイントには、IPアドレスごとのレート制限があります。これは、エンドポイントの誤用を試みることを軽減するためです。たとえば、使用中のユーザー名またはメールアドレスを大量に検出します。

**rate limit**（レート制限）は、IPアドレスあたり1分あたり20コールです。

### ユーザー名の更新 {#update-username}

ユーザー名を変更できる頻度には、レート制限があります。これは、機能の誤用を軽減するために実施されます。たとえば、使用中のユーザー名を大量に検出します。

**rate limit**（レート制限）は、認証済みユーザーあたり1分あたり10コールです。

### ユーザー名の存在 {#username-exists}

選択したユーザー名がすでに使用されているかどうかを確認するためにサインアップ時に使用される内部エンドポイント`/users/:username/exists`には、レート制限があります。これは、使用中のユーザー名の大規模な発見など、誤用のリスクを軽減するためです。

**rate limit**（レート制限）は、IPアドレスあたり1分あたり20コールです。

### プロジェクトジョブAPIエンドポイント {#project-jobs-api-endpoint}

{{< history >}}

- GitLab 15.7で`ci_enforce_rate_limits_jobs_api`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/382985)されました。デフォルトでは無効になっています。
- GitLab 16.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/384186)になりました。機能フラグ`ci_enforce_rate_limits_jobs_api`は削除されました。

{{< /history >}}

ジョブの取得時にタイムアウトを減らすために適用されるエンドポイント`project/:id/jobs`には、レート制限があります。

**rate limit**（レート制限）は、認証済みユーザーあたり、デフォルトで600コールです。レート制限を[設定](../administration/settings/user_and_ip_rate_limits.md)できます。

### AIアクション {#ai-action}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118010)されました。

{{< /history >}}

このエンドポイントの悪用を防ぐために適用されるGraphQL`aiAction`ミューテーションには、レート制限があります。

**rate limit**（レート制限）は、認証済みユーザーあたり8時間あたり160コールです。

### APIを使用したメンバーの削除 {#delete-a-member-using-the-api}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118296)されました。

{{< /history >}}

[APIエンドポイントを使用してプロジェクトまたはグループメンバーを削除する](../api/members.md#remove-a-member-from-a-group-or-project)`/groups/:id/members`または`/project/:id/members`には、レート制限があります。

**rate limit**（レート制限）は、1分あたり60件の削除です。

### リポジトリのblobとファイルアクセス {#repository-blob-and-file-access}

{{< history >}}

- GitLab 18.1で[導入](https://gitlab.com/gitlab-org/security/gitlab/-/issues/1302)されました。

{{< /history >}}

レート制限は、特定リポジトリAPIエンドポイントを介して大きなファイルにアクセスするときに適用されます。10 MBを超えるファイルの場合、レート制限は、オブジェクトごと、プロジェクトごとに1分あたり5コールです: 

- [リポジトリblobエンドポイント](../api/repositories.md#get-a-blob-from-repository)：`/projects/:id/repository/blobs/:sha`
- [リポジトリファイルエンドポイント](../api/repository_files.md#get-file-from-repository)：`/projects/:id/repository/files/:file_path`

これらの制限は、APIを介して大規模なリポジトリファイルにアクセスする際の過度のリソース使用を防ぐのに役立ちます。

### 通知メール {#notification-emails}

{{< history >}}

- GitLab 17.1で`rate_limit_notification_emails`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/439101)されました。デフォルトでは無効になっています。
- GitLab 17.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/439101)になりました。機能フラグ`rate_limit_notification_emails`は削除されました。

{{< /history >}}

プロジェクトまたはグループに関連する通知メールには、レート制限があります。

**rate limit**（レート制限）は、プロジェクトまたはグループごと、ユーザーあたり24時間あたり1,000件の通知です。

### GitHubのインポート {#github-import}

GitHubからのプロジェクトのインポートのトリガーには、レート制限があります。

**rate limit**（レート制限）は、ユーザーあたり1分あたり6つのトリガーされたインポートです。

### FogBugzのインポート {#fogbugz-import}

{{< history >}}

- GitLab 17.6で導入されました。

{{< /history >}}

FogBugzからのプロジェクトのインポートのトリガーには、レート制限があります。

**rate limit**（レート制限）は、ユーザーあたり1分あたり1つのトリガーされたインポートです。

### コミット差分ファイル {#commit-diff-files}

これは、展開されたコミット差分ファイル（`/[group]/[project]/-/commit/[:sha]/diff_files?expanded=1`）のレート制限であり、このエンドポイントの悪用を防ぐために適用されます。

**rate limit**は、ユーザー（認証済みユーザー）またはIPアドレス（認証なし）あたり1分あたり6リクエストです。

### 変更履歴の生成 {#changelog-generation}

`:id/repository/changelog`エンドポイントには、プロジェクトごとにユーザーごとのレート制限があります。これは、エンドポイントの誤用を試みることを軽減するためです。レート制限は、GETアクションとPOSTアクションの間で共有されます。

**rate limit**（レート制限）は、プロジェクトごとにユーザーあたり1分あたり5コールです。

## トラブルシューティング {#troubleshooting}

### Rack Attackがロードバランサーを拒否リストに登録している {#rack-attack-is-denylisting-the-load-balancer}

すべてのトラフィックがロードバランサーから送信されているように見える場合、Rack Attackがロードバランサーをブロックする可能性があります。その場合は、次の操作を行う必要があります: 

1. [`nginx[real_ip_trusted_addresses]`を設定](https://docs.gitlab.com/omnibus/settings/nginx.html#configuring-gitlab-trusted_proxies-and-the-nginx-real_ip-module)します。これにより、ユーザーのIPがロードバランサーのIPとしてリストされなくなります。
1. 許可リストロードバランサーのIPアドレス。
1. GitLabを再設定します: 

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Redisを使用して、Rack AttackからブロックされたIPを削除する {#remove-blocked-ips-from-rack-attack-with-redis}

ブロックされたIPを削除するには:

1. 実稼働ログでブロックされているIPを見つけます: 

   ```shell
   grep "Rack_Attack" /var/log/gitlab/gitlab-rails/auth.log
   ```

1. 拒否リストはRedisに保存されているため、`redis-cli`を開く必要があります: 

   ```shell
   /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
   ```

1. 次の構文を使用してブロックを削除できます。`<ip>`を拒否リストに登録されている実際のIPに置き換えます: 

   ```plaintext
   del cache:gitlab:rack::attack:allow2ban:ban:<ip>
   ```

1. IPを含むキーが表示されなくなったことを確認します: 

   ```plaintext
   keys *rack::attack*
   ```

   デフォルトでは、[`keys`コマンドが無効になっています](https://docs.gitlab.com/omnibus/settings/redis.html#renamed-commands)。

1. オプションで、[許可リストにIPを追加](https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-rack-attack)して、再度拒否リストに登録されないようにします。
