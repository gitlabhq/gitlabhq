---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、一般的な管理および運用プロセスを支援する[Rake](https://ruby.github.io/rake/)タスクを提供します。

すべてのRakeタスクは、タスクのドキュメントに特に記載がない限り、Railsノードで実行する必要があります。

次の方法でGitLab Rakeタスクを実行できます:

- `gitlab-rake <raketask>`は、[Linuxパッケージ](https://docs.gitlab.com/omnibus/)および[GitLab Helmチャート](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet.html#gitlab-specific-kubernetes-information)のインストール用です。
- `bundle exec rake <raketask>`は、[セルフコンパイルインストール](../../install/self_compiled/_index.md)の場合。

## 利用可能なRakeタスク {#available-rake-tasks}

以下のRakeタスクをGitLabで使用できます:

| タスク                                                                                                 | 説明 |
|:------------------------------------------------------------------------------------------------------|:------------|
| [アクセストークンexpirationタスク](tokens/_index.md)                                                     | アクセストークンの有効期限日を一括で延長または削除します。 |
| [バックアップとリストア](../backup_restore/_index.md)                                                    | サーバー間でGitLabインスタンスをバックアップ、リストア、および移行します。 |
| [クリーンアップ](cleanup.md)                                                                                | GitLabインスタンスから不要なアイテムをクリーンアップします。 |
| 開発                                                                                           | GitLabコントリビューター向けのタスクです。詳細については、開発ドキュメントを参照してください。 |
| [Elasticsearch](../../integration/advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) | GitLabインスタンスでElasticsearchをメンテナンスします。 |
| [一般的なメンテナンス](maintenance.md)                                                                 | 一般的なメンテナンスと自己チェックタスク。 |
| [GitHubインポート](../../user/project/import/github.md)                                                  | GitHubからリポジトリを取得する、インポート。 |
| [大規模なプロジェクトエクスポートのインポート](project_import_export.md#import-large-projects)                        | 大規模なGitLab[プロジェクトエクスポート](../../user/project/settings/import_export.md)をインポートします。 |
| [受信メール](incoming_email.md)                                                                   | 受信メール関連のタスク。 |
| [整合性チェック](check.md)                                                                          | リポジトリ、ファイル、LDAPなどの整合性をチェックします。 |
| [キープアラウンド参照](keep_around.md)                                                              | プロジェクトの孤立したキープアラウンド参照をすべて検索します。 |
| [LDAPメンテナンス](ldap.md)                                                                           | [LDAP](../auth/ldap/_index.md)関連のタスク。 |
| [パスワード](password.md)                                                                               | パスワード管理タスク。 |
| [Praefect Rakeタスク](praefect.md)                                                                    | [Praefect](../gitaly/praefect/_index.md)関連のタスク。 |
| [プロジェクトのインポート/エクスポート](project_import_export.md)                                                     | [プロジェクトエクスポートおよびインポート](../../user/project/settings/import_export.md)の準備。 |
| [Sidekiqジョブの移行](../sidekiq/sidekiq_job_migration.md)                                          | 将来の日付にスケジュールされたSidekiqジョブを新しいキューに移行します。 |
| [サービスデスクのメール](service_desk_email.md)                                                           | サービスデスクのメール関連のタスク。 |
| [SMTPメンテナンス](smtp.md)                                                                           | SMTP関連のタスク。 |
| [SPDXライセンスリストのインポート](spdx.md)                                                                   | [SPDXライセンスリスト](https://spdx.org/licenses/)のローカルコピーをインポートして[License approval policies](../../user/compliance/license_approval_policies.md)のマッチングを行います。 |
| [ユーザーパスワードをリセットする](../../security/reset_user_password.md#use-a-rake-task)                         | Rakeを使用してユーザーパスワードをリセットします。 |
| [アップロードの移行](uploads/migrate.md)                                                                 | ローカルストレージとオブジェクトストレージ間でアップロードを移行します。 |
| [アップロードのサニタイズ](uploads/sanitize.md)                                                               | GitLabの以前のバージョンにアップロードされた画像からEXIFデータを削除します。 |
| サービスデータ                                                                                          | Service Pingを生成して問題を解決する。詳細については、Service Ping開発ドキュメントを参照してください。 |
| [ユーザー管理](user_management.md)                                                                 | ユーザー管理タスクを実行します。 |
| [Webhook管理](web_hooks.md)                                                                | プロジェクトWebhookをメンテナンスします。 |
| [X.509署名](x509_signatures.md)                                                                | X.509コミット署名を更新します。証明書ストアが変更された場合に役立ちます。 |

利用可能なすべてのRakeタスクを一覧表示するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake -vT
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

```shell
gitlab-rake -vT
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake -vT RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}
