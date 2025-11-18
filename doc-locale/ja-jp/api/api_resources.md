---
stage: Developer Experience
group: API
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: REST APIのリソース
description: "GitLab REST APIリソースをコンテキスト（プロジェクト、グループ、スタンドアロン、およびテンプレート）別に整理し、エンドポイントパスを示します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab REST APIを使用すると、GitLabリソースをプログラムで制御できます。既存のツールとのインテグレーションを構築し、反復タスクを自動化し、カスタムレポートのデータを抽出します。Webインターフェースを使用せずに、プロジェクト、グループ、イシュー、マージリクエストにアクセスして操作します。

REST APIを使用して以下の操作を行います。

- プロジェクトの作成とユーザー管理を自動化する。
- 外部システムからCI/CDパイプラインをトリガーする。
- カスタムダッシュボード用にイシューとマージリクエストのデータを抽出する。
- GitLabをサードパーティアプリケーションと連携させる。
- 複数のリポジトリにわたるカスタムワークフローを実装する。

REST APIリソースは次のように編成されています。

- [プロジェクトリソース](#project-resources)
- [グループリソース](#group-resources)
- [スタンドアロンリソース](#standalone-resources)
- [テンプレートリソース](#template-resources)

## プロジェクトリソース {#project-resources}

以下のAPIリソースは、プロジェクトのコンテキストで使用できます。

| リソース                                                                       | 利用可能なエンドポイント |
|--------------------------------------------------------------------------------|---------------------|
| [アクセスリクエスト](access_requests.md)                                          | `/projects/:id/access_requests`（グループでも利用可能） |
| [アクセストークン](project_access_tokens.md)                                      | `/projects/:id/access_tokens`（グループでも利用可能） |
| [エージェント](cluster_agents.md)                                                    | `/projects/:id/cluster_agents` |
| [ブランチ](branches.md)                                                        | `/projects/:id/repository/branches/`、`/projects/:id/repository/merged_branches` |
| [コミット](commits.md)                                                          | `/projects/:id/repository/commits`、`/projects/:id/statuses` |
| [コンテナレジストリ](container_registry.md)                                    | `/projects/:id/registry/repositories` |
| [コンテナリポジトリ保護ルール](container_repository_protection_rules.md)  | `/projects/:id/registry/protection/repository/rules` |
| [カスタム属性](custom_attributes.md)                                      | `/projects/:id/custom_attributes`（グループおよびユーザーでも利用可能） |
| [[Composer](packages/composer.md)ディストリビューション](packages/composer.md)                                 | `/projects/:id/packages/composer`（グループでも利用可能） |
| [Conan v1ディストリビューション](packages/conan_v1.md)                                       | `/projects/:id/packages/conan`（スタンドアロンでも利用可能） |
| [Conan v2ディストリビューション](packages/conan_v2.md)                                       | `/projects/:id/packages/conan`（スタンドアロンでも利用可能） |
| [Debianディストリビューション](packages/debian_project_distributions.md)               | `/projects/:id/debian_distributions`（グループでも利用可能） |
| [Debianパッケージ](packages/debian.md)                                          | `/projects/:id/packages/debian`（グループでも利用可能） |
| [依存関係](dependencies.md)                                                | `/projects/:id/dependencies` |
| [デプロイキー](deploy_keys.md)                                                  | `/projects/:id/deploy_keys`（スタンドアロンでも利用可能） |
| [デプロイトークン](deploy_tokens.md)                                              | `/projects/:id/deploy_tokens`（グループおよびスタンドアロンでも利用可能） |
| [デプロイ](deployments.md)                                                  | `/projects/:id/deployments` |
| [ディスカッション](discussions.md)（スレッド形式のコメント）                              | `/projects/:id/issues/.../discussions`、`/projects/:id/snippets/.../discussions`、`/projects/:id/merge_requests/.../discussions`、`/projects/:id/commits/.../discussions`（グループでも利用可能） |
| [ドラフトノート](draft_notes.md)（コメント）                                       | `/projects/:id/merge_requests/.../draft_notes` |
| [絵文字リアクション](emoji_reactions.md)                                          | `/projects/:id/issues/.../award_emoji`、`/projects/:id/merge_requests/.../award_emoji`、`/projects/:id/snippets/.../award_emoji` |
| [環境](environments.md)                                                | `/projects/:id/environments` |
| [エラートラッキング](error_tracking.md)                                            | `/projects/:id/error_tracking/settings` |
| [イベント](events.md)                                                            | `/projects/:id/events`（ユーザーおよびスタンドアロンでも利用可能） |
| [外部ステータスチェック](status_checks.md)                                     | `/projects/:id/external_status_checks` |
| [機能フラグのユーザーリスト](feature_flag_user_lists.md)                          | `/projects/:id/feature_flags_user_lists` |
| [機能フラグ](feature_flags.md)                                              | `/projects/:id/feature_flags` |
| [フリーズ期間](freeze_periods.md)                                            | `/projects/:id/freeze_periods` |
| [Go Proxy](packages/go_proxy.md)                                               | `/projects/:id/packages/go` |
| [Helmリポジトリ](packages/helm.md)                                            | `/projects/:id/packages/helm_repository` |
| [インテグレーション](project_integrations.md)（旧称「サービス」）                          | `/projects/:id/integrations` |
| [招待](invitations.md)                                                  | `/projects/:id/invitations`（グループでも利用可能） |
| [イシューボード](boards.md)                                                      | `/projects/:id/boards` |
| [イシューリンク](issue_links.md)                                                  | `/projects/:id/issues/.../links` |
| [イシュー統計](issues_statistics.md)                                      | `/projects/:id/issues_statistics`（グループおよびスタンドアロンでも利用可能） |
| [イシュー](issues.md)                                                            | `/projects/:id/issues`（グループおよびスタンドアロンでも利用可能） |
| [イテレーション](iterations.md)                                                    | `/projects/:id/iterations`（グループでも利用可能） |
| [プロジェクトCI/CDジョブトークンスコープ](project_job_token_scopes.md)                   | `/projects/:id/job_token_scope` |
| [ジョブ](jobs.md)                                                                | `/projects/:id/jobs`、`/projects/:id/pipelines/.../jobs` |
| [ジョブアーティファクト](job_artifacts.md)                                             | `/projects/:id/jobs/:job_id/artifacts` |
| [ラベル](labels.md)                                                            | `/projects/:id/labels` |
| [Mavenリポジトリ](packages/maven.md)                                          | `/projects/:id/packages/maven`（グループおよびスタンドアロンでも利用可能） |
| [メンバー](members.md)                                                          | `/projects/:id/members`（グループでも利用可能） |
| [マージリクエスト承認](merge_request_approvals.md)                          | `/projects/:id/approvals`、`/projects/:id/merge_requests/.../approvals` |
| [マージリクエスト](merge_requests.md)                                            | `/projects/:id/merge_requests`（グループおよびスタンドアロンでも利用可能） |
| [マージトレイン](merge_trains.md)                                                | `/projects/:id/merge_trains` |
| [メタデータ](metadata.md)                                                        | `/metadata` |
| [モデルレジストリ](model_registry.md)                                            | `/projects/:id/packages/ml_models/` |
| [ノート](notes.md)（コメント）                                                   | `/projects/:id/issues/.../notes`、`/projects/:id/snippets/.../notes`、`/projects/:id/merge_requests/.../notes`（グループでも利用可能） |
| [通知設定](notification_settings.md)                              | `/projects/:id/notification_settings`（グループおよびスタンドアロンでも利用可能） |
| [NPMリポジトリ](packages/npm.md)                                              | `/projects/:id/packages/npm` |
| [NuGetパッケージ](packages/nuget.md)                                            | `/projects/:id/packages/nuget`（グループでも利用可能） |
| [パッケージ](packages.md)                                                        | `/projects/:id/packages` |
| [Pagesドメイン](pages_domains.md)                                              | `/projects/:id/pages/domains`（スタンドアロンでも利用可能） |
| [Pagesの設定](pages.md)                                                     | `/projects/:id/pages` |
| [パイプラインスケジュール](pipeline_schedules.md)                                    | `/projects/:id/pipeline_schedules` |
| [パイプライントリガー](pipeline_triggers.md)                                      | `/projects/:id/triggers` |
| [パイプライン](pipelines.md)                                                      | `/projects/:id/pipelines` |
| [プロジェクトバッジ](project_badges.md)                                            | `/projects/:id/badges` |
| [プロジェクトクラスター](project_clusters.md)                                        | `/projects/:id/clusters` |
| [プロジェクトのインポート/エクスポート](project_import_export.md)                              | `/projects/:id/export`、`/projects/import`、`/projects/:id/import` |
| [プロジェクトマイルストーン](milestones.md)                                            | `/projects/:id/milestones` |
| [プロジェクトスニペット](project_snippets.md)                                        | `/projects/:id/snippets` |
| [プロジェクトテンプレート](project_templates.md)                                      | `/projects/:id/templates` |
| [プロジェクトの脆弱性](project_vulnerabilities.md)                         | `/projects/:id/vulnerabilities` |
| [プロジェクトWiki](wikis.md)                                                      | `/projects/:id/wikis` |
| [プロジェクトレベルの変数](project_level_variables.md)                          | `/projects/:id/variables` |
| [プロジェクト](projects.md)（Webhookの設定を含む）                             | `/projects`、`/projects/:id/hooks`（ユーザーでも利用可能） |
| [保護ブランチ](protected_branches.md)                                    | `/projects/:id/protected_branches` |
| [保護されたコンテナレジストリ](container_repository_protection_rules.md)       | `/projects/:id/registry/protection/rules` |
| [保護環境](protected_environments.md)                            | `/projects/:id/protected_environments` |
| [保護パッケージ](project_packages_protection_rules.md)                     | `/projects/:id/packages/protection/rules` |
| [保護タグ](protected_tags.md)                                            | `/projects/:id/protected_tags` |
| [PyPIパッケージ](packages/pypi.md)                                              | `/projects/:id/packages/pypi`（グループでも利用可能） |
| [リリースリンク](releases/links.md)                                             | `/projects/:id/releases/.../assets/links` |
| [リリース](releases/_index.md)                                                 | `/projects/:id/releases` |
| [リモートミラー](remote_mirrors.md)                                            | `/projects/:id/remote_mirrors` |
| [リポジトリ](repositories.md)                                                | `/projects/:id/repository` |
| [リポジトリファイル](repository_files.md)                                        | `/projects/:id/repository/files` |
| [リポジトリサブモジュール](repository_submodules.md)                              | `/projects/:id/repository/submodules` |
| [リソースラベルイベント](resource_label_events.md)                              | `/projects/:id/issues/.../resource_label_events`、`/projects/:id/merge_requests/.../resource_label_events`（グループでも利用可能） |
| [Ruby gem](packages/rubygems.md)                                              | `/projects/:id/packages/rubygems` |
| [Runner](runners.md)                                                          | `/projects/:id/runners`（スタンドアロンでも利用可能） |
| [検索](search.md)                                                            | `/projects/:id/search`（グループおよびスタンドアロンでも利用可能） |
| [タグ](tags.md)                                                                | `/projects/:id/repository/tags` |
| [Terraformモジュール](packages/terraform-modules.md)                             | `/projects/:id/packages/terraform/modules`（スタンドアロンでも利用可能） |
| [`.gitlab-ci.yml`ファイルを検証](lint.md)                                      | `/projects/:id/ci/lint` |
| [脆弱性](vulnerabilities.md)                                          | `/vulnerabilities/:id` |
| [脆弱性エクスポート](vulnerability_exports.md)                              | `/projects/:id/vulnerability_exports` |
| [脆弱性検出結果](vulnerability_findings.md)                            | `/projects/:id/vulnerability_findings` |

## グループリソース {#group-resources}

以下のAPIリソースは、グループのコンテキストで使用できます。

| リソース                                                       | 利用可能なエンドポイント |
|----------------------------------------------------------------|---------------------|
| [アクセスリクエスト](access_requests.md)                          | `/groups/:id/access_requests/`（プロジェクトでも利用可能） |
| [アクセストークン](group_access_tokens.md)                        | `/groups/:id/access_tokens`（プロジェクトでも利用可能） |
| [カスタム属性](custom_attributes.md)                      | `/groups/:id/custom_attributes`（プロジェクトおよびユーザーでも利用可能） |
| [Debianディストリビューション](packages/debian_group_distributions.md) | `/groups/:id/-/packages/debian`（プロジェクトでも利用可能） |
| [デプロイトークン](deploy_tokens.md)                              | `/groups/:id/deploy_tokens`（プロジェクトおよびスタンドアロンでも利用可能） |
| [ディスカッション](discussions.md)（コメントとスレッド）           | `/groups/:id/epics/.../discussions`（プロジェクトでも利用可能） |
| [エピックイシュー](epic_issues.md)                                  | `/groups/:id/epics/.../issues` |
| [エピックリンク](epic_links.md)                                    | `/groups/:id/epics/.../epics` |
| [エピック](epics.md)                                              | `/groups/:id/epics` |
| [グループ](groups.md)                                            | `/groups`、`/groups/.../subgroups` |
| [グループバッジ](group_badges.md)                                | `/groups/:id/badges` |
| [グループイシューボード](group_boards.md)                          | `/groups/:id/boards` |
| [グループイテレーション](group_iterations.md)                        | `/groups/:id/iterations`（プロジェクトでも利用可能） |
| [グループラベル](group_labels.md)                                | `/groups/:id/labels` |
| [グループレベルの変数](group_level_variables.md)              | `/groups/:id/variables` |
| [グループマイルストーン](group_milestones.md)                        | `/groups/:id/milestones` |
| [グループリリース](group_releases.md)                            | `/groups/:id/releases` |
| [グループSSH証明書](group_ssh_certificates.md)            | `/groups/:id/ssh_certificates` |
| [グループWiki](group_wikis.md)                                  | `/groups/:id/wikis` |
| [招待](invitations.md)                                  | `/groups/:id/invitations`（プロジェクトでも利用可能） |
| [イシュー](issues.md)                                            | `/groups/:id/issues`（プロジェクトおよびスタンドアロンでも利用可能） |
| [イシュー統計](issues_statistics.md)                      | `/groups/:id/issues_statistics`（プロジェクトおよびスタンドアロンでも利用可能） |
| [リンクされたエピック](linked_epics.md)                                | `/groups/:id/epics/.../related_epics` |
| [メンバーロール](member_roles.md)                                | `/groups/:id/member_roles` |
| [メンバー](members.md)                                          | `/groups/:id/members`（プロジェクトでも利用可能） |
| [マージリクエスト](merge_requests.md)                            | `/groups/:id/merge_requests`（プロジェクトおよびスタンドアロンでも利用可能） |
| [ノート](notes.md)（コメント）                                   | `/groups/:id/epics/.../notes`（プロジェクトでも利用可能） |
| [通知設定](notification_settings.md)              | `/groups/:id/notification_settings`（プロジェクトおよびスタンドアロンでも利用可能） |
| [リソースラベルイベント](resource_label_events.md)              | `/groups/:id/epics/.../resource_label_events`（プロジェクトでも利用可能） |
| [検索](search.md)                                            | `/groups/:id/search`（プロジェクトおよびスタンドアロンでも利用可能） |

## スタンドアロンリソース {#standalone-resources}

以下のAPIリソースは、プロジェクトおよびグループのコンテキストの外部で使用できます（`/users`を含む）。

| リソース                                                                                     | 利用可能なエンドポイント |
|----------------------------------------------------------------------------------------------|---------------------|
| [外観](appearance.md)                                                                  | `/application/appearance` |
| [アプリケーション](applications.md)                                                              | `/applications` |
| [監査イベント](audit_events.md)                                                              | `/audit_events` |
| [アバター](avatar.md)                                                                          | `/avatar` |
| [ブロードキャストメッセージ](broadcast_messages.md)                                                  | `/broadcast_messages` |
| [コードスニペット](snippets.md)                                                                 | `/snippets` |
| [コード提案](code_suggestions.md)                                                      | `/code_suggestions` |
| [カスタム属性](custom_attributes.md)                                                    | `/users/:id/custom_attributes`（グループおよびプロジェクトでも利用可能） |
| [依存関係リストのエクスポート](dependency_list_export.md)                                         | `/pipelines/:id/dependency_list_exports`、`/projects/:id/dependency_list_exports`、`/groups/:id/dependency_list_exports`、`/security/dependency_list_exports/:id`、`/security/dependency_list_exports/:id/download` |
| [デプロイキー](deploy_keys.md)                                                                | `/deploy_keys`（プロジェクトでも利用可能） |
| [デプロイトークン](deploy_tokens.md)                                                            | `/deploy_tokens`（プロジェクトおよびグループでも利用可能） |
| [イベント](events.md)                                                                          | `/events`、`/users/:id/events`（プロジェクトでも利用可能） |
| [機能フラグ](features.md)                                                                 | `/features` |
| [Geoノード](geo_nodes.md)                                                                    | `/geo_nodes` |
| [グループアクティビティー分析](group_activity_analytics.md)                                      | `/analytics/group_activity/{issues_count}` |
| [ストレージ間グループリポジトリ移動](group_repository_storage_moves.md)                          | `/group_repository_storage_moves` |
| [GitHubからリポジトリをインポート](import.md#import-repository-from-github)                     | `/import/github` |
| [Bitbucket Serverからリポジトリをインポート](import.md#import-repository-from-bitbucket-server) | `/import/bitbucket_server` |
| [インスタンスクラスター](instance_clusters.md)                                                    | `/admin/clusters` |
| [インスタンスレベルのCI/CD変数](instance_level_ci_variables.md)                             | `/admin/ci/variables` |
| [イシュー統計](issues_statistics.md)                                                    | `/issues_statistics`（グループおよびプロジェクトでも利用可能） |
| [イシュー](issues.md)                                                                          | `/issues`（グループおよびプロジェクトでも利用可能） |
| [ジョブ](jobs.md)                                                                              | `/job` |
| [キー](keys.md)                                                                              | `/keys` |
| [ライセンス](license.md)                                                                        | `/license` |
| [Markdown](markdown.md)                                                                      | `/markdown` |
| [マージリクエスト](merge_requests.md)                                                          | `/merge_requests`（グループおよびプロジェクトでも利用可能） |
| [ネームスペース](namespaces.md)                                                                  | `/namespaces` |
| [通知設定](notification_settings.md)                                            | `/notification_settings`（グループおよびプロジェクトでも利用可能） |
| [コンプライアンスとポリシー](compliance_policy_settings.md)         | `/admin/security/compliance_policy_settings` |
| [Pagesドメイン](pages_domains.md)                                                            | `/pages/domains`（プロジェクトでも利用可能） |
| [パーソナルアクセストークン](personal_access_tokens.md)                                          | `/personal_access_tokens` |
| [プランの制限](plan_limits.md)                                                                | `/application/plan_limits` |
| [プロジェクトリポジトリのストレージ移動](project_repository_storage_moves.md)                      | `/project_repository_storage_moves` |
| [プロジェクト](projects.md)                                                                      | `/users/:id/projects`（プロジェクトでも利用可能） |
| [Runner](runners.md)                                                                        | `/runners`（プロジェクトでも利用可能） |
| [検索](search.md)                                                                          | `/search`（グループおよびプロジェクトでも利用可能） |
| [サービスデータ](usage_data.md)                                                                | `/usage_data`（GitLabインスタンスの[管理者](../user/permissions.md)ユーザーのみ） |
| [設定](settings.md)                                                                      | `/application/settings` |
| [Sidekiqのメトリクス](sidekiq_metrics.md)                                                        | `/sidekiq` |
| [Sidekiqキューの管理](admin_sidekiq_queues.md)                                     | `/admin/sidekiq/queues/:queue_name` |
| [スニペットリポジトリのストレージ移動](snippet_repository_storage_moves.md)                      | `/snippet_repository_storage_moves` |
| [統計](statistics.md)                                                                  | `/application/statistics` |
| [提案](suggestions.md)                                                                | `/suggestions` |
| [システムフック](system_hooks.md)                                                              | `/hooks` |
| [To Do](todos.md)                                                                           | `/todos` |
| [トークン情報](admin/token.md)                                                          | `/admin/token` |
| [トピック](topics.md)                                                                          | `/topics` |
| [ユーザー](users.md)                                                                            | `/users` |
| [Webコミット](web_commits.md)                                                                | `/web_commits/public_key` |
| [バージョン](version.md)                                                                        | `/version` |

## テンプレートリソース {#template-resources}

エンドポイントは以下で利用できます。

- [Dockerfileテンプレート](templates/dockerfiles.md)
- [`.gitignore`テンプレート](templates/gitignores.md)
- [GitLab CI/CD YAMLテンプレート](templates/gitlab_ci_ymls.md)
- [オープンソースライセンステンプレート](templates/licenses.md)
