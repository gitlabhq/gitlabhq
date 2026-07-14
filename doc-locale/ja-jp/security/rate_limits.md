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
> GitLab.comについては、[GitLab.com固有のレート制限](../user/gitlab_com/_index.md#rate-limits-on-gitlabcom)を参照してください。
>
> GitLab Dedicatedについては、[認証済みユーザーレート制限](../administration/dedicated/user_rate_limits.md)を参照してください。

レート制限は、Webアプリケーションのセキュリティと耐久性を向上させるための一般的な手法です。

たとえば、単純なスクリプトで毎秒数千ものWebリクエストを生成できます。リクエストは次のいずれかの可能性があります:

- 悪意のあるもの。
- 無関心なもの。
- 単なるバグ。

お使いのアプリケーションとインフラストラクチャは、この負荷に対応できない可能性があります。詳細については、[サービス拒否](https://en.wikipedia.org/wiki/Denial-of-service_attack)を参照してください。ほとんどのケースは、単一のIPアドレスからのリクエストのレートを制限することで軽減できます。

ほとんどの[ブルートフォース攻撃](https://en.wikipedia.org/wiki/Brute-force_attack)も、同様にレート制限によって軽減されます。

> [!note]
> APIリクエストに対するレート制限は、フロントエンドで行われたリクエストには影響しません。これらのリクエストは常にWebトラフィックとしてカウントされるためです。

## 構成可能な制限 {#configurable-limits}

これらのレート制限は、インスタンスの**管理者**エリアで設定できます:

- [インポート/エクスポートレート制限](../administration/settings/import_export_rate_limits.md)
- [イシューレート制限](../administration/settings/rate_limit_on_issues_creation.md)
- [ノートレート制限](../administration/settings/rate_limit_on_notes_creation.md)
- [保護されたパス](../administration/settings/protected_paths.md)
- [rawエンドポイントレート制限](../administration/settings/rate_limits_on_raw_endpoints.md)
- [ユーザーとIPレート制限](../administration/settings/user_and_ip_rate_limits.md)
- [パッケージレジストリレート制限](../administration/settings/package_registry_rate_limits.md)
- [Git LFSレート制限](../administration/settings/git_lfs_rate_limits.md)
- [Git SSHオペレーションのレート制限](../administration/settings/rate_limits_on_git_ssh_operations.md)
- [ファイルAPIレート制限](../administration/settings/files_api_rate_limits.md)
- [非推奨APIレート制限](../administration/settings/deprecated_api_rate_limits.md)
- [GitLab Pagesレート制限](../administration/pages/_index.md#rate-limits)
- [パイプラインレート制限](../administration/settings/rate_limit_on_pipelines_creation.md)
- [インシデント管理レート制限](../administration/settings/incident_management_rate_limits.md)
- [プロジェクトAPIレート制限](../administration/settings/rate_limit_on_projects_api.md)
- [グループAPIレート制限](../administration/settings/rate_limit_on_groups_api.md)
- [ユーザーAPIレート制限](../administration/settings/rate_limit_on_users_api.md)
- [組織APIレート制限](../administration/settings/rate_limit_on_organizations_api.md)

これらのレート制限は、[ApplicationSettings API](../api/settings.md)を使用して設定できます:

- [オートコンプリートユーザーのレート制限](../administration/instance_limits.md#autocomplete-users-rate-limit)

これらのレート制限は、Railsコンソールを使用して設定できます:

- [Webhookのレート制限](../administration/instance_limits.md#webhook-rate-limit)

## Gitおよびコンテナレジストリの認証失敗BAN {#failed-authentication-ban-for-git-and-container-registry}

単一のIPアドレスから3分間に30件の認証失敗リクエストが受信された場合、GitLabは1時間HTTPステータスコード`403`を返します。これは、以下の組み合わせにのみ適用されます:

- Gitリクエスト。
- コンテナレジストリ (`/jwt/auth`) リクエスト。

この制限は、次のようになります。

- 認証に成功したリクエストでリセットされます。例えば、29回の認証失敗リクエスト、それに続く1回の成功したリクエスト、さらに29回の認証失敗リクエストという場合、BANはトリガーされません。
- `gitlab-ci-token`で認証されたJSON Webトークンリクエストには適用されません。
- デフォルトで無効になっています。

応答ヘッダーは提供されません。

レート制限を回避するには、次のことができます:

- 自動化されたパイプラインの実行をずらす。
- 失敗した認証試行のために、[指数関数的バックオフとリトライ](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html)を構成します。
- ドキュメント化されたプロセスと[ベストプラクティス](https://about.gitlab.com/blog/access-token-lifetime-limits/#how-to-minimize-the-impact)を使用して、トークンの有効期限を管理します。

設定情報については、[Linuxパッケージ設定オプション](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-failed-authentication-ban)を参照してください。

## 設定できない制限 {#non-configurable-limits}

### リポジトリアーカイブ {#repository-archives}

[リポジトリアーカイブのダウンロード](../api/repositories.md#retrieve-file-archive-from-a-repository)のレート制限が利用可能です。この制限は、UIまたはAPIを通じてダウンロードを開始するプロジェクトおよびユーザーに適用されます。

レート制限は、ユーザーあたり1分間に5リクエストです。

### Webhookテスト {#webhook-testing}

[Webhookのテスト](../user/project/integrations/webhooks.md#test-a-webhook)にはレート制限があり、Webhook機能の悪用を防ぎます。

レート制限は、ユーザーあたり1分間に5リクエストです。

### ユーザー登録 {#users-sign-up}

`/users/sign_up`エンドポイントには、IPアドレスあたりのレート制限があります。これは、エンドポイントの悪用を軽減するためのものです。例えば、使用中のユーザー名やメールアドレスの一括発見などです。

レート制限は、IPアドレスあたり1分間に20呼び出しです。

### ユーザー名の更新 {#update-username}

ユーザー名の変更頻度にはレート制限があります。これは、機能の悪用を軽減するために適用されます。例えば、どのユーザー名が使用中であるかを一括で発見するためなどです。

レート制限は、認証済みユーザーあたり1分間に10呼び出しです。

### ユーザー名が存在します {#username-exists}

選択したユーザー名がすでに使用されているかを確認するためのサインアップ時に使用される内部エンドポイント`/users/:username/exists`には、レート制限があります。これは、使用中のユーザー名の一括発見などの悪用リスクを軽減するためのものです。

レート制限は、IPアドレスあたり1分間に20呼び出しです。

### プロジェクトジョブAPIエンドポイント {#project-jobs-api-endpoint}

{{< history >}}

- GitLab 15.7で`ci_enforce_rate_limits_jobs_api`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/382985)されました。デフォルトでは無効になっています。
- GitLab 16.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/384186)になりました。機能フラグ`ci_enforce_rate_limits_jobs_api`は削除されました。

{{< /history >}}

ジョブの取得時にタイムアウトを減らすために適用されるエンドポイント`project/:id/jobs`には、レート制限があります。

レート制限は、認証済みユーザーあたり600呼び出しにデフォルト設定されています。[レート制限を構成](../administration/settings/user_and_ip_rate_limits.md)できます。

### AIアクション {#ai-action}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118010)されました。

{{< /history >}}

GraphQL `aiAction`ミューテーションにはレート制限があり、このエンドポイントの悪用を防ぐために適用されます。

レート制限は、認証済みユーザーあたり8時間で160呼び出しです。

### APIを使用したメンバーの削除 {#delete-a-member-using-the-api}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118296)されました。

{{< /history >}}

[APIエンドポイントを使用したプロジェクトまたはグループメンバーの削除](../api/group_members.md#remove-a-group-member) (`/groups/:id/members`または`/project/:id/members`) には、レート制限があります。

レート制限は1分間に60削除です。

### APIを使用したプロジェクトメンバーのリスト表示 {#list-project-members-using-the-api}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211239)されました。

{{< /history >}}

グループまたはプロジェクト内のすべてのプロジェクトメンバーをリスト表示するためのレート制限を設定します。次のエンドポイントでは、デフォルトで1分あたり200リクエストに設定されています:

```plaintext
GET /groups/:id/members/all
GET /projects/:id/members/all
```

管理者は、プロジェクトエンドポイントの[レート制限を構成](../administration/settings/rate_limit_on_groups_api.md)できます。

### リポジトリblobとファイルアクセス {#repository-blob-and-file-access}

{{< history >}}

- GitLab 18.1で[導入](https://gitlab.com/gitlab-org/security/gitlab/-/issues/1302)されました。

{{< /history >}}

特定のリポジトリAPIエンドポイントを介して大きなファイルにアクセスする場合に、レート制限が適用されます。10 MBを超えるファイルの場合、レート制限はオブジェクトあたりプロジェクトあたり1分間に5呼び出しです:

- [リポジトリblobエンドポイント](../api/repositories.md#retrieve-a-blob-from-a-repository): `/projects/:id/repository/blobs/:sha`
- [リポジトリファイルエンドポイント](../api/repository_files.md#retrieve-a-file-from-a-repository): `/projects/:id/repository/files/:file_path`

これらの制限は、APIを介して大きなリポジトリファイルにアクセスする際の過剰なリソース使用を防ぐのに役立ちます。

### 通知メール {#notification-emails}

{{< history >}}

- GitLab 17.1で`rate_limit_notification_emails`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/439101)されました。デフォルトでは無効になっています。
- GitLab 17.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/439101)になりました。機能フラグ`rate_limit_notification_emails`は削除されました。

{{< /history >}}

プロジェクトまたはグループに関連する通知メールには、レート制限があります。

レート制限は、ユーザーあたりプロジェクトまたはグループあたり24時間で1,000件の通知です。

### GitHubインポート {#github-import}

GitHubからのプロジェクトインポートをトリガーするには、レート制限があります。

レート制限は、ユーザーあたり1分間に6回のトリガーされたインポートです。

### FogBugzインポート {#fogbugz-import}

{{< history >}}

- GitLab 17.6で導入されました。

{{< /history >}}

FogBugzからのプロジェクトインポートをトリガーするには、レート制限があります。

レート制限は、ユーザーあたり1分間に1回のトリガーされたインポートです。

### コミット差分ファイル {#commit-diff-files}

これは、展開されたコミット差分ファイル (`/[group]/[project]/-/commit/[:sha]/diff_files?expanded=1`) に対するレート制限であり、このエンドポイントの悪用を防ぐために適用されます。

レート制限は、ユーザーあたり (認証済み) またはIPアドレスあたり (未認証) 1分間に6リクエストです。

### 変更履歴の生成 {#changelog-generation}

`:id/repository/changelog`エンドポイントには、ユーザーあたりプロジェクトあたりのレート制限があります。これは、エンドポイントの悪用を軽減するためのものです。レート制限は、GETアクションとPOSTアクションの間で共有されます。

レート制限は、ユーザーあたりプロジェクトあたり1分間に5呼び出しです。

## トラブルシューティング {#troubleshooting}

### Rack Attackがロードバランサーを拒否リストに追加しています {#rack-attack-is-denylisting-the-load-balancer}

すべてのトラフィックがロードバランサーから来ているように見える場合、Rack Attackはロードバランサーをブロックする可能性があります。その場合、次のことを行う必要があります:

1. [`nginx[real_ip_trusted_addresses]`を構成します](https://docs.gitlab.com/omnibus/settings/nginx/#configure-gitlab-trusted-proxies-and-nginx-real_ip-module)。これにより、ユーザーのIPがロードバランサーのIPとしてリストされるのを防ぎます。
1. ロードバランサーのIPアドレスを許可リストに追加します。
1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### RedisでRack AttackからブロックされたIPを削除 {#remove-blocked-ips-from-rack-attack-with-redis}

ブロックされたIPを削除するには:

1. 本番環境ログでブロックされたIPを見つけます:

   ```shell
   grep "Rack_Attack" /var/log/gitlab/gitlab-rails/auth.log
   ```

1. 拒否リストはRedisに保存されているため、`redis-cli`を開く必要があります:

   ```shell
   /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
   ```

1. `<ip>`を実際に拒否リストに追加されたIPに置き換えて、次の構文を使用してブロックを解除できます:

   ```plaintext
   del cache:gitlab:rack::attack:allow2ban:ban:<ip>
   ```

1. IPを含むキーが表示されなくなったことを確認します:

   ```plaintext
   keys *rack::attack*
   ```

   デフォルトでは、[`keys`コマンドは無効になっています](https://docs.gitlab.com/omnibus/settings/redis/#renamed-commands)。

1. オプションで、IPが再び拒否リストに追加されるのを防ぐために、[IPを許可リストに追加](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-failed-authentication-ban)します。
