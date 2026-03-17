---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: レート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!note]
> 
> GitLab.comについては、[GitLab.com-specific rate limits](../user/gitlab_com/_index.md#rate-limits-on-gitlabcom)を参照してください。
>
> GitLab Dedicatedについては、[Authenticated user rate limits](../administration/dedicated/user_rate_limits.md)を参照してください。

レート制限は、ウェブアプリケーションのセキュリティと堅牢性を向上させるために使用される一般的な技術です。

たとえば、シンプルなスクリプトは1秒あたり数千ものウェブリクエストを行うことができます。リクエストには、次のものがあります:

- 悪意のあるもの。
- 無関心なもの。
- 単なるバグ。

お使いのアプリケーションやインフラストラクチャでは、その負荷に対応できない場合があります。詳細については、[サービス拒否](https://en.wikipedia.org/wiki/Denial-of-service_attack)を参照してください。ほとんどのケースは、単一IPアドレスからのリクエストのレート制限によって軽減できます。

ほとんどの[ブルートフォース攻撃](https://en.wikipedia.org/wiki/Brute-force_attack)も、レート制限によって同様に軽減されます。

> [!note]
> 
> APIリクエストに対するレート制限は、フロントエンドによるリクエストには影響しません。これは、これらのリクエストが常にウェブトラフィックとしてカウントされるためです。

## 設定可能な制限 {#configurable-limits}

これらのレート制限は、インスタンスの**管理者**エリアで設定できます:

- [インポート/エクスポートレート制限](../administration/settings/import_export_rate_limits.md)
- [イシューレート制限](../administration/settings/rate_limit_on_issues_creation.md)
- [Noteレート制限](../administration/settings/rate_limit_on_notes_creation.md)
- [保護されたパス](../administration/settings/protected_paths.md)
- [rawエンドポイントレート制限](../administration/settings/rate_limits_on_raw_endpoints.md)
- [ユーザーおよびIPレート制限](../administration/settings/user_and_ip_rate_limits.md)
- [パッケージレジストリレート制限](../administration/settings/package_registry_rate_limits.md)
- [Git LFSレート制限](../administration/settings/git_lfs_rate_limits.md)
- [Git SSHオペレーションに対するレート制限](../administration/settings/rate_limits_on_git_ssh_operations.md)
- [ファイルAPIレート制限](../administration/settings/files_api_rate_limits.md)
- [非推奨APIレート制限](../administration/settings/deprecated_api_rate_limits.md)
- [GitLab Pagesレート制限](../administration/pages/_index.md#rate-limits)
- [パイプラインレート制限](../administration/settings/rate_limit_on_pipelines_creation.md)
- [インシデント管理レート制限](../administration/settings/incident_management_rate_limits.md)
- [プロジェクトAPIAPIレート制限](../administration/settings/rate_limit_on_projects_api.md)
- [グループAPIレート制限](../administration/settings/rate_limit_on_groups_api.md)
- [ユーザーAPIレート制限](../administration/settings/rate_limit_on_users_api.md)
- [組織APIレート制限](../administration/settings/rate_limit_on_organizations_api.md)

これらのレート制限は、[ApplicationSettings API](../api/settings.md)を使用して設定できます:

- [オートコンプリートユーザーのレート制限](../administration/instance_limits.md#autocomplete-users-rate-limit)

これらのレート制限は、Railsコンソールを使用して設定できます:

- [Webhookのレート制限](../administration/instance_limits.md#webhook-rate-limit)

## Gitおよびコンテナレジストリに対する認証失敗時のBAN {#failed-authentication-ban-for-git-and-container-registry}

単一のIPアドレスから3分間に30回の認証失敗リクエストを受信した場合、GitLabは1時間HTTPステータス`403`を返します。これは、以下の組み合わせにのみ適用されます:

- Gitリクエスト。
- コンテナレジストリ（`/jwt/auth`）リクエスト。

この制限は、次のようになります。

- 認証に成功したリクエストでリセットされます。たとえば、29回の認証失敗リクエストの後に1回の成功リクエストが続き、さらに29回の認証失敗リクエストがあったとしても、BANはトリガーされません。
- `gitlab-ci-token`で認証されたJSON Webトークンリクエストには適用されません。
- デフォルトでは無効です。

応答ヘッダーは提供されません。

レート制限されないようにするには、次の方法があります:

- 自動パイプラインの実行をずらします。
- 失敗した認証試行のために、[指数バックオフと再試行](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html)を設定します。
- ドキュメント化されたプロセスと[ベストプラクティス](https://about.gitlab.com/blog/access-token-lifetime-limits/#how-to-minimize-the-impact)を使用して、トークンの有効期限を管理します。

設定情報については、[Linuxパッケージ設定オプション](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-failed-authentication-ban)を参照してください。

## 設定できない制限 {#non-configurable-limits}

### リポジトリアーカイブ {#repository-archives}

[リポジトリアーカイブのダウンロード](../api/repositories.md#retrieve-file-archive-from-a-repository)に対するレート制限が利用可能です。この制限は、UIまたはAPIを通じてダウンロードを開始するプロジェクトおよびユーザーに適用されます。

レート制限は、ユーザーごとに1分あたり5リクエストです。

### Webhookテスト {#webhook-testing}

[Webhookテスト](../user/project/integrations/webhooks.md#test-a-webhook)にはレート制限があり、Webhook機能の悪用を防ぎます。

レート制限は、ユーザーごとに1分あたり5リクエストです。

### ユーザー登録 {#users-sign-up}

`/users/sign_up`エンドポイントには、IPアドレスごとのレート制限があります。これは、エンドポイントの悪用を軽減するためです。たとえば、使用中のユーザー名やメールアドレスの一括検出などです。

レート制限は、IPアドレスごとに1分あたり20コールです。

### ユーザー名の更新 {#update-username}

ユーザー名を変更できる頻度にはレート制限があります。これは、機能の悪用を軽減するために適用されます。たとえば、使用中のユーザー名を一括検出するなどです。

レート制限は、認証済みユーザーごとに1分あたり10コールです。

### ユーザー名の存在確認 {#username-exists}

選択したユーザー名がすでに使用されているか確認するために登録時に使用される、内部エンドポイント`/users/:username/exists`にはレート制限があります。これは、使用中のユーザー名の一括検出などの悪用リスクを軽減するためです。

レート制限は、IPアドレスごとに1分あたり20コールです。

### プロジェクトジョブAPIエンドポイント {#project-jobs-api-endpoint}

{{< history >}}

- GitLab 15.7で`ci_enforce_rate_limits_jobs_api`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/382985)されました。デフォルトでは無効になっています。
- GitLab 16.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/384186)になりました。機能フラグ`ci_enforce_rate_limits_jobs_api`は削除されました。

{{< /history >}}

ジョブ取得時のタイムアウトを減らすために、エンドポイント`project/:id/jobs`にはレート制限が適用されます。

レート制限は、認証済みユーザーごとにデフォルトで600コールです。[レート制限を設定](../administration/settings/user_and_ip_rate_limits.md)できます。

### AIアクション {#ai-action}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118010)されました。

{{< /history >}}

GraphQL `aiAction`ミューテーションにはレート制限があり、このエンドポイントの悪用を防ぐために適用されます。

レート制限は、認証済みユーザーごとに8時間あたり160コールです。

### APIを使用したメンバーの削除 {#delete-a-member-using-the-api}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118296)されました。

{{< /history >}}

[APIエンドポイント](../api/group_members.md#remove-a-group-member)`/groups/:id/members`または`/project/:id/members`を使用してプロジェクトまたはグループメンバーを削除するにはレート制限があります。

レート制限は、1分あたり60削除です。

### APIを使用したプロジェクトメンバーのリスト表示 {#list-project-members-using-the-api}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578527)されました。

{{< /history >}}

グループまたはプロジェクト内のすべてのプロジェクトメンバーをリスト表示するためのレート制限を設定します。以下のエンドポイントでは、デフォルトで1分あたり200リクエストに制限されます:

```plaintext
GET /groups/:id/members/all
GET /projects/:id/members/all
```

管理者は、プロジェクトエンドポイントの[レート制限を設定](../administration/settings/rate_limit_on_members_api.md)できます。

### リポジトリblobおよびファイルアクセス {#repository-blob-and-file-access}

{{< history >}}

- GitLab 18.1で[導入](https://gitlab.com/gitlab-org/security/gitlab/-/issues/1302)されました。

{{< /history >}}

特定のリポジトリAPIエンドポイントを介して大きなファイルにアクセスする場合に、レート制限が適用されます。10 MBを超えるファイルの場合、レート制限は、オブジェクトごと、プロジェクトごとに1分あたり5コールです:

- [リポジトリblobエンドポイント](../api/repositories.md#retrieve-a-blob-from-a-repository): `/projects/:id/repository/blobs/:sha`
- [リポジトリファイルエンドポイント](../api/repository_files.md#retrieve-a-file-from-a-repository): `/projects/:id/repository/files/:file_path`

これらの制限は、APIを介して大きなリポジトリファイルにアクセスする際の過剰なリソース使用を防ぐのに役立ちます。

### 通知メール {#notification-emails}

{{< history >}}

- GitLab 17.1で`rate_limit_notification_emails`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/439101)されました。デフォルトでは無効になっています。
- GitLab 17.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/439101)になりました。機能フラグ`rate_limit_notification_emails`は削除されました。

{{< /history >}}

プロジェクトまたはグループに関連する通知メールにはレート制限があります。

レート制限は、ユーザー、プロジェクト、またはグループごとに24時間あたり1,000通知です。

### GitHubインポート {#github-import}

GitHubからのプロジェクトインポートをトリガーするためのレート制限があります。

レート制限は、ユーザーごとに1分あたり6回のトリガーされたインポートです。

### FogBugzインポート {#fogbugz-import}

{{< history >}}

- GitLab 17.6で導入されました。

{{< /history >}}

FogBugzからのプロジェクトインポートをトリガーするためのレート制限があります。

レート制限は、ユーザーごとに1分あたり1回のトリガーされたインポートです。

### コミット差分ファイル {#commit-diff-files}

これは、展開されたコミット差分ファイル（`/[group]/[project]/-/commit/[:sha]/diff_files?expanded=1`）に対するレート制限であり、このエンドポイントの悪用を防ぐために適用されます。

レート制限は、ユーザー（認証済み）またはIPアドレス（未認証）ごとに1分あたり6リクエストです。

### 変更履歴の生成 {#changelog-generation}

エンドポイント`:id/repository/changelog`には、ユーザー、プロジェクトごとのレート制限があります。これは、エンドポイントの悪用を軽減するためです。レート制限は、GETアクションとPOSTアクションの間で共有されます。

レート制限は、ユーザー、プロジェクトごとに1分あたり5コールです。

## トラブルシューティング {#troubleshooting}

### Rack Attackがロードバランサーを拒否リストに登録しています {#rack-attack-is-denylisting-the-load-balancer}

すべてのトラフィックがロードバランサーから来ているように見える場合、Rack Attackがロードバランサーをブロックする可能性があります。その場合、次のことを行う必要があります:

1. [`nginx[real_ip_trusted_addresses]`を設定](https://docs.gitlab.com/omnibus/settings/nginx/#configuring-gitlab-trusted_proxies-and-the-nginx-real_ip-module)します。これにより、ユーザーのIPがロードバランサーのIPとしてリストされるのを防ぎます。
1. ロードバランサーのIPアドレスを許可リストに登録します。
1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Redisを使用してRack AttackからブロックされたIPを削除する {#remove-blocked-ips-from-rack-attack-with-redis}

ブロックされたIPを削除するには:

1. 本番環境ログでブロックされたIPを見つけます:

   ```shell
   grep "Rack_Attack" /var/log/gitlab/gitlab-rails/auth.log
   ```

1. 拒否リストはRedisに保存されているため、`redis-cli`を開く必要があります:

   ```shell
   /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
   ```

1. ブロックは、`<ip>`を拒否リストに登録されている実際のIPに置き換えて、以下の構文を使用して削除できます:

   ```plaintext
   del cache:gitlab:rack::attack:allow2ban:ban:<ip>
   ```

1. IPを持つキーが表示されなくなったことを確認します:

   ```plaintext
   keys *rack::attack*
   ```

   デフォルトでは、[`keys`コマンドは無効です](https://docs.gitlab.com/omnibus/settings/redis/#renamed-commands)。

1. オプションで、IPが再度拒否リストに登録されるのを防ぐために、[そのIPを許可リストに追加](https://docs.gitlab.com/omnibus/settings/configuration/#configuring-rack-attack)します。
