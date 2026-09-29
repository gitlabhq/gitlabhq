---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabアプリケーションに組み込まれているレート制限。
title: 設定不可能なレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabはアプリケーションで次のレート制限を適用します。

| 制限                                | レート制限                                                     | 詳細 |
|:-------------------------------------|:---------------------------------------------------------------|:--------|
| 変更履歴生成                 | ユーザーあたり、プロジェクトあたり毎分5回の呼び出し                        | `:id/repository/changelog`エンドポイントに適用されます。この制限は、`GET`と`POST`のアクション間で共有されます。 |
| コミット差分ファイル                    | 1分あたり6リクエスト                                          | 展開されたコミット差分ファイル（`/[group]/[project]/-/commit/[:sha]/diff_files?expanded=1`）に適用されます。この制限は、認証済みリクエストの場合はユーザーごと、未認証リクエストの場合はIPアドレスごとに適用されます。 |
| デプロイの削除                  | 認証済みユーザーあたり1分あたり500リクエスト                 | [デプロイの削除](../api/deployments.md#delete-a-deployment)（`DELETE /projects/:id/deployments/:deployment_id`を使用）に適用されます。大量のデプロイ削除によるインフラへの影響を軽減します。GitLab 19.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/243738)されました。 |
| FogBugzインポート                       | ユーザーあたり1分あたり1回のトリガーされたインポート                         | FogBugzからのプロジェクトインポートをトリガーすることに適用されます。GitLab 17.6で導入されました。 |
| GitHubインポート                        | ユーザーあたり1分あたり6回のトリガーされたインポート                        | GitHubからのプロジェクトインポートをトリガーすることに適用されます。 |
| 新規ユーザーアカウント                    | IPアドレスあたり1分あたり20呼び出し                             | `/users/sign_up`エンドポイントに適用されます。使用中のユーザー名またはメールアドレスの大量検出試行を軽減します。 |
| 通知メール                  | ユーザーあたり、プロジェクトまたはグループあたり24時間あたり1,000通知 | プロジェクトまたはグループに関連する通知メールに適用されます。GitLab 17.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/439101)になりました。 |
| オフライン転送のエクスポートとインポート | ユーザーあたり1分あたり6リクエスト                                 | 個別に制限される[オフライン転送](../user/import/gitlab_instances/offline-transfer-migrations.md)のエクスポートとインポートに適用されます。GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209344)されました。 |
| リポジトリアーカイブ                  | ユーザーあたり1分あたり5リクエスト                                 | UIまたはAPIを介した[リポジトリアーカイブのダウンロード](../api/repositories.md#retrieve-file-archive-from-a-repository)に適用されます。この制限は、プロジェクトおよびダウンロードを開始するユーザーに適用されます。 |
| リポジトリblobおよびファイルアクセス      | プロジェクトあたり、オブジェクトあたり1分あたり5呼び出し                      | [リポジトリblob](../api/repositories.md#retrieve-a-blob-from-a-repository)および[リポジトリファイル](../api/repository_files.md#retrieve-a-file-from-a-repository)エンドポイントにある10 MBを超えるファイルに適用されます。GitLab 18.1で[導入](https://gitlab.com/gitlab-org/security/gitlab/-/issues/1302)されました。 |
| スニペット作成                     | 認証済みユーザーあたり1時間あたり300リクエスト                   | `POST /snippets`を使用した[スニペットの作成](../api/snippets.md#create-a-snippet)、`POST /projects/:id/snippets`を使用した[プロジェクトスニペットの作成](../api/project_snippets.md#create-a-snippet)、およびGitLab UIで使用される`createSnippet` GraphQLミューテーションに適用されます。この制限は3つすべてで共有されます。GitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251927)されました。 |
| ユーザー名の更新                      | 認証済みユーザーあたり1分あたり10呼び出し                     | ユーザー名を変更できる頻度を制限します。使用中のユーザー名を大量検出する試行を軽減します。 |
| ユーザー名の存在確認                      | IPアドレスあたり1分あたり20呼び出し                             | 選択したユーザー名が使用されているかどうかをチェックする内部`/users/:username/exists`エンドポイントに適用されます。 |

## 関連トピック {#related-topics}

- [レート制限](_index.md)
- [不正利用と認証失敗の利用停止](abuse_bans.md)
