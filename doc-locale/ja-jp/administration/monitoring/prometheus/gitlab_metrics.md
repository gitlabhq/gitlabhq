---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Prometheusメトリクス
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab Prometheusメトリクスを有効にするには、次の手順に従います。

1. 管理者アクセス権を持つユーザーとしてGitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定 > メトリクスとプロファイリング**を選択します。
1. **メトリクス - Prometheus**セクションを見つけて、**GitLab Prometheusメトリックエンドポイントを有効にする**を選択します。
1. 変更を反映させるため、[GitLabを再起動](../../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

自己コンパイルによるインストールの場合は、手動でこの設定を行う必要があります。

## メトリクスを収集する {#collecting-the-metrics}

GitLabは独自の内部サービスメトリクスを監視し、`/-/metrics`エンドポイントで利用できるようにします。他の[Prometheus](https://prometheus.io) exporterとは異なり、これらのメトリクスにアクセスするには、クライアントのIPアドレスを[明示的に許可](../ip_allowlist.md)する必要があります。

これらのメトリクスは、[Linuxパッケージ](https://docs.gitlab.com/omnibus/)およびHelmチャートのインストールで有効になり、収集されます。自己コンパイルによるインストールでは、これらのメトリクスを手動で有効にし、Prometheusサーバーで収集する必要があります。

Sidekiqノードのメトリクスを有効にして表示する方法については、[Sidekiqメトリクス](#sidekiq-metrics)を参照してください。

## 利用可能なメトリクス {#metrics-available}

{{< history >}}

- GitLab 15.11で、`caller_id`が`redis_hit_miss_operations_total`および`redis_cache_generation_duration_seconds`から[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/392622)されました。

{{< /history >}}

次のメトリクスを利用できます。

| メトリック                                                           | 種類        | 提供開始   | 説明                                                                                                           | ラベル                                                    |
| :--------------------------------------------------------------- | :---------- | ------: | :-------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------- |
| `gitlab_cache_misses_total`                                      | カウンター     | 10.2    | キャッシュ読み取りミス                                                                                                       | `controller`、`action`、`store`、`endpoint_id`                           |
| `gitlab_cache_operation_duration_seconds`                        | ヒストグラム   | 10.2    | キャッシュアクセス時間                                                                                                     | `operation`、`store`、`endpoint_id`                                      |
| `gitlab_cache_operations_total`                                  | カウンター     | 12.2    | コントローラーまたはアクション別のキャッシュ操作                                                                              | `controller`、`action`、`operation`、`store`、`endpoint_id`              |
| `gitlab_cache_read_multikey_count`                               | ヒストグラム   | 15.7    | マルチキーキャッシュ読み取り操作におけるキーの数                                                                      | `controller`、`action`、`store`、`endpoint_id`                   |
| `gitlab_ci_job_token_inbound_access`                             | カウンター     | 17.2   | CIジョブトークンによる受信アクセス数 | |
| `gitlab_ci_job_token_authorization_failures`                     | カウンター     | 17.11  | CIジョブトークンによる認証試行の失敗回数 | `same_root_ancestor` |
| `gitlab_ci_pipeline_builder_scoped_variables_duration`           | ヒストグラム   | 14.5   | CI/CDジョブのスコープ付き変数の作成にかかる時間（秒） | |
| `gitlab_ci_pipeline_creation_duration_seconds`                   | ヒストグラム   | 13.0    | CI/CDパイプラインの作成にかかる時間（秒）                                                                   | `gitlab`                                                  |
| `gitlab_ci_pipeline_size_builds`                                 | ヒストグラム   | 13.1    | パイプラインソースでグループ化されたパイプライン内のビルドの総数                                                 | `source`                                                  |
| `gitlab_ci_runner_authentication_success_total`                  | カウンター     | 15.2    | Runner認証が成功した回数の合計                                                        | `type`                                                    |
| `gitlab_ci_runner_authentication_failure_total`                  | カウンター     | 15.2    | Runner認証が失敗した回数の合計 | |
| `gitlab_ghost_user_migration_lag_seconds`                        | ゲージ       | 15.6    | Ghostユーザー移行のためにスケジュールされている最も古いレコードの待機時間（秒）                                   |                                                           |
| `gitlab_ghost_user_migration_scheduled_records_total`            | ゲージ       | 15.6    | スケジュールされたGhostユーザー移行の総数                                                                   |                                                           |
| `gitlab_ci_active_jobs`                                          | ヒストグラム   | 14.2    | パイプライン作成時のアクティブなジョブ数                                                                         |                                                           |
| `gitlab_database_transaction_seconds`                            | ヒストグラム   | 12.1    | データベーストランザクションに費やされた時間（秒）                                                                       |                                                           |
| `gitlab_method_call_duration_seconds`                            | ヒストグラム   | 10.2    | メソッド呼び出しの実際の所要時間                                                                                            | `controller`、`action`、`module`、`method`                |
| `gitlab_omniauth_login_total`                                    | カウンター     | 16.1    | OmniAuthログイン試行の総数                                                                              | `omniauth_provider`、`status`                             |
| `gitlab_page_out_of_bounds`                                      | カウンター     | 12.8    | PageLimiterのページネーション制限に達した場合のカウンター                                                                | `controller`、`action`、`bot`                             |
| `gitlab_rails_boot_time_seconds`                                 | ゲージ       | 14.8    | Railsプライマリプロセスが起動を完了するまでの経過時間                                               |                                                           |
| `gitlab_rails_queue_duration_seconds`                            | ヒストグラム   | 9.4     | GitLab WorkhorseがリクエストをRailsに転送する際のレイテンシーを測定                                               |                                                           |
| `gitlab_sql_duration_seconds`                                    | ヒストグラム   | 10.2    | `SCHEMA`操作および`BEGIN`/`COMMIT`を除いたSQL実行時間                                              |                                                           |
| `gitlab_sql_<role>_duration_seconds`                             | ヒストグラム   | 13.10   | `SCHEMA`操作および`BEGIN`/`COMMIT`を除いたSQL実行時間（データベースロール（プライマリ/レプリカ）でグループ化） |                                                           |
| `gitlab_ruby_threads_max_expected_threads`                       | ゲージ       | 13.3    | アプリケーションの処理を行うために実行中であると想定されるスレッドの最大数                                      |                                                           |
| `gitlab_ruby_threads_running_threads`                            | ゲージ       | 13.3    | 名前別の実行中のRubyスレッド数                                                                                |                                                           |
| `gitlab_transaction_cache_<key>_count_total`                     | カウンター     | 10.2    | Railsキャッシュ呼び出し（キーごと）の総数のカウンター                                                                         |                                                           |
| `gitlab_transaction_cache_<key>_duration_total`                  | カウンター     | 10.2    | Railsキャッシュ呼び出し（キーごと）に費やされた合計時間（秒）のカウンター                                                 |                                                           |
| `gitlab_transaction_cache_count_total`                           | カウンター     | 10.2    | Railsキャッシュ呼び出し（集計）の総数のカウンター                                                                       |                                                           |
| `gitlab_transaction_cache_duration_total`                        | カウンター     | 10.2    | Railsキャッシュ呼び出し（集計）に費やされた合計時間（秒）のカウンター                                               |                                                           |
| `gitlab_transaction_cache_read_hit_count_total`                  | カウンター     | 10.2    | Railsキャッシュ呼び出しにおけるキャッシュヒット回数のカウンター                                                                          | `controller`、`action`、`store`、`endpoint_id`                           |
| `gitlab_transaction_cache_read_miss_count_total`                 | カウンター     | 10.2    | Railsキャッシュ呼び出しにおけるキャッシュミス回数のカウンター                                                                        | `controller`、`action`、`store`、`endpoint_id`                           |
| `gitlab_transaction_duration_seconds`                            | ヒストグラム   | 10.2    | 成功したリクエストの処理時間（`gitlab_transaction_*`メトリクス）                                                     | `controller`、`action`、`endpoint_id`                                    |
| `gitlab_transaction_event_build_found_total`                     | カウンター     | 9.4     | API /jobs/requestにおいてビルドが見つかった回数のカウンター                                                                         |                                                           |
| `gitlab_transaction_event_build_invalid_total`                   | カウンター     | 9.4     | API /jobs/requestにおいて並行処理の競合によりビルドが無効となった回数のカウンター                                           |                                                           |
| `gitlab_transaction_event_build_not_found_cached_total`          | カウンター     | 9.4     | API /jobs/requestにおいてビルドが見つからなかった場合にキャッシュされた応答が返された回数のカウンター                                                  |                                                           |
| `gitlab_transaction_event_build_not_found_total`                 | カウンター     | 9.4     | API /jobs/requestにおいてビルドが見つからなかった回数のカウンター                                                                     |                                                           |
| `gitlab_transaction_event_change_default_branch_total`           | カウンター     | 9.4     | いずれかのリポジトリでデフォルトブランチが変更された回数のカウンター                                                             |                                                           |
| `gitlab_transaction_event_create_repository_total`               | カウンター     | 9.4     | いずれかのリポジトリが作成された回数のカウンター                                                                                |                                                           |
| `gitlab_transaction_event_etag_caching_cache_hit_total`          | カウンター     | 9.4     | ETagキャッシュがヒットした回数のカウンター。                                                                                           | `endpoint`                                                |
| `gitlab_transaction_event_etag_caching_header_missing_total`     | カウンター     | 9.4     | ETagキャッシュミス - ヘッダーが存在しない回数のカウンター                                                                          | `endpoint`                                                |
| `gitlab_transaction_event_etag_caching_key_not_found_total`      | カウンター     | 9.4     | ETagキャッシュミス - キーが見つからない回数のカウンター                                                                           | `endpoint`                                                |
| `gitlab_transaction_event_etag_caching_middleware_used_total`    | カウンター     | 9.4     | ETagミドルウェアがアクセスされた回数のカウンター                                                                                  | `endpoint`                                                |
| `gitlab_transaction_event_etag_caching_resource_changed_total`   | カウンター     | 9.4     | ETagキャッシュミス - リソースが変更された回数のカウンター                                                                        | `endpoint`                                                |
| `gitlab_transaction_event_fork_repository_total`                 | カウンター     | 9.4     | リポジトリのフォーク数のカウンター（RepositoryForkWorker）。ソースリポジトリが存在する場合にのみ増加                   |                                                           |
| `gitlab_transaction_event_import_repository_total`               | カウンター     | 9.4     | リポジトリのインポート数のカウンター（RepositoryImportWorker）                                                               |                                                           |
| `gitlab_transaction_event_patch_hard_limit_bytes_hit_total`      | カウンター     | 13.9    | 差分パッチサイズ制限に達した回数のカウンター                                                                                |                                                           |
| `gitlab_transaction_event_push_branch_total`                     | カウンター     | 9.4     | すべてのブランチへのプッシュ回数のカウンター                                                                                         |                                                           |
| `gitlab_transaction_event_rails_exception_total`                 | カウンター     | 9.4     | Railsの例外数のカウンター                                                                                |                                                           |
| `gitlab_transaction_event_receive_email_total`                   | カウンター     | 9.4     | 受信メール数のカウンター                                                                                           | `handler`                                                 |
| `gitlab_transaction_event_remove_branch_total`                   | カウンター     | 9.4     | いずれかのリポジトリでブランチが削除された回数のカウンター                                                                   |                                                           |
| `gitlab_transaction_event_remove_repository_total`               | カウンター     | 9.4     | リポジトリが削除された回数のカウンター                                                                                  |                                                           |
| `gitlab_transaction_event_remove_tag_total`                      | カウンター     | 9.4     | いずれかのリポジトリでタグが削除された回数のカウンター                                                                       |                                                           |
| `gitlab_transaction_event_sidekiq_exception_total`               | カウンター     | 9.4     | Sidekiqの例外数のカウンター                                                                                         |                                                           |
| `gitlab_transaction_event_stuck_import_jobs_total`               | カウンター     | 9.4     | スタックしたインポートジョブ数                                                                                            | `projects_without_jid_count`、`projects_with_jid_count`   |
| `gitlab_transaction_event_update_build_total`                    | カウンター     | 9.4     | API `/jobs/request/:id`におけるビルド更新回数のカウンター                                                                  |                                                           |
| `gitlab_transaction_new_redis_connections_total`                 | カウンター     | 9.4     | 新しいRedis接続回数のカウンター                                                                                     |                                                           |
| `gitlab_transaction_rails_queue_duration_total`                  | カウンター     | 9.4     | GitLab WorkhorseがリクエストをRailsに転送する際のレイテンシーを測定                                               | `controller`、`action`、`endpoint_id`                                    |
| `gitlab_transaction_view_duration_total`                         | カウンター     | 9.4     | ビューの処理時間                                                                                                    | `controller`、`action`、`view`、`endpoint_id`                            |
| `gitlab_view_rendering_duration_seconds`                         | ヒストグラム   | 10.2    | ビューの処理時間（ヒストグラム）                                                                                        | `controller`、`action`、`view`、`endpoint_id`                            |
| `http_requests_total`                                            | カウンター     | 9.4     | Rackリクエスト数                                                                                                    | `method`、`status`                                        |
| `http_request_duration_seconds`                                  | ヒストグラム   | 9.4     | 成功したリクエストに対するRackミドルウェアからのHTTP応答時間                                                       | `method`                                                  |
| `gitlab_transaction_db_count_total`                              | カウンター     | 13.1    | SQL呼び出しの総数のカウンター                                                                                 | `controller`、`action`、`endpoint_id`                                    |
| `gitlab_transaction_db_<role>_count_total`                       | カウンター     | 13.10   | SQL呼び出しの総数のカウンター（データベースロール（プライマリ/レプリカ）でグループ化）                                    | `controller`、`action`、`endpoint_id`                                    |
| `gitlab_transaction_db_write_count_total`                        | カウンター     | 13.1    | 書き込みSQL呼び出しの総数のカウンター                                                                           | `controller`、`action`、`endpoint_id`                                   |
| `gitlab_transaction_db_cached_count_total`                       | カウンター     | 13.1    | キャッシュされたSQL呼び出しの総数のカウンター                                                                          | `controller`、`action`、`endpoint_id`                                    |
| `gitlab_transaction_db_<role>_cached_count_total`                | カウンター     | 13.1    | キャッシュされたSQL呼び出しの総数のカウンター（データベースロール（プライマリ/レプリカ）でグループ化）                             | `controller`、`action`、`endpoint_id`                                    |
| `gitlab_transaction_db_<role>_wal_count_total`                   | カウンター     | 14.0    | WAL（先行書き込みログの位置）クエリの総数のカウンター（データベースロール（プライマリ/レプリカ）でグループ化）       | `controller`、`action`、`endpoint_id`                                    |
| `gitlab_transaction_db_<role>_wal_cached_count_total`            | カウンター     | 14.1    | キャッシュされたWAL（先行書き込みログの位置）クエリの総数のカウンター（データベースロール（プライマリ/レプリカ）でグループ化）| `controller`、`action`、`endpoint_id`                                    |
| `http_elasticsearch_requests_duration_seconds`   | ヒストグラム   | 13.1    | Webトランザクション中のElasticsearchリクエストの処理時間。PremiumおよびUltimateのみ。                                                               | `controller`、`action`、`endpoint_id`                                    |
| `http_elasticsearch_requests_total`               | カウンター     | 13.1    | Webトランザクション中のElasticsearchリクエスト数。PremiumおよびUltimateのみ。                                                                  | `controller`、`action`、`endpoint_id`                                    |
| `pipelines_created_total`                                        | カウンター     | 9.4     | 作成されたパイプラインのカウンター                                                                                          | `source`、`partition_id`                                  |
| `rack_uncaught_errors_total`                                     | カウンター     | 9.4     | Rack接続で処理された未捕捉エラーの数                                                                       |                                                           |
| `user_session_logins_total`                                      | カウンター     | 9.4     | GitLabの起動または再起動以降にログインしたユーザー数のカウンター                                        |                                                           |
| `upload_file_does_not_exist`                                     | カウンター     | 10.7    | アップロードレコードに対応するファイルが見つからなかった回数。 |                                                           |
| `failed_login_captcha_total`                                     | ゲージ       | 11.0    | ログイン時にCAPTCHA試行に失敗した回数のカウンター                                                                       |                                                           |
| `successful_login_captcha_total`                                 | ゲージ       | 11.0    | ログイン時にCAPTCHA試行に成功した回数のカウンター                                                                   |                                                           |
| `auto_devops_pipelines_completed_total`                          | カウンター     | 12.7    | 完了したAuto DevOpsパイプラインのカウンター（状態別にラベル付け）                                                         |                                                           |
| `artifact_report_<report_type>_builds_completed_total`           | カウンター     | 15.3    | レポートタイプのアーティファクトを含む完了したCIビルドのカウンター（レポートタイプ別にグループ化、状態別にラベル付け）               |                                                           |
| `action_cable_active_connections`                                | ゲージ       | 13.4    | 現在接続中のActionCable WSクライアントの数                                                                  | `server_mode`                                             |
| `action_cable_broadcasts_total`                                  | カウンター     | 13.10   | 発行されたActionCableブロードキャストの数                                                                          | `server_mode`                                             |
| `action_cable_pool_min_size`                                     | ゲージ       | 13.4    | ActionCableスレッドプール内のワーカースレッドの最小数                                                           | `server_mode`                                             |
| `action_cable_pool_max_size`                                     | ゲージ       | 13.4    | ActionCableスレッドプール内のワーカースレッドの最大数                                                           | `server_mode`                                             |
| `action_cable_pool_current_size`                                 | ゲージ       | 13.4    | ActionCableスレッドプール内の現在のワーカースレッド数                                                           | `server_mode`                                             |
| `action_cable_pool_largest_size`                                 | ゲージ       | 13.4    | ActionCableスレッドプール内でこれまでに観測されたワーカースレッドの最大数                                           | `server_mode`                                             |
| `action_cable_pool_pending_tasks`                                | ゲージ       | 13.4    | ActionCableスレッドプール内で実行待ちのタスク数                                                     | `server_mode`                                             |
| `action_cable_pool_tasks_total`                                  | ゲージ       | 13.4    | ActionCableスレッドプール内で実行されたタスクの総数                                                             | `server_mode`                                             |
| `gitlab_ci_trace_operations_total`                               | カウンター     | 13.4    | ビルドトレース上の異なる操作の総量                                                                 | `operation`                                               |
| `gitlab_ci_trace_bytes_total`                                    | カウンター     | 13.4    | 転送されたビルドトレースの総バイト数                                                                         |                                                           |
| `action_cable_single_client_transmissions_total`                 | カウンター     | 13.10   | 任意のチャンネルで任意のクライアントに送信されたActionCableメッセージの数                                           | `server_mode`                                             |
| `action_cable_subscription_confirmations_total`                  | カウンター     | 13.10   | クライアントからのActionCableサブスクリプションのうち確認された数                                                        | `server_mode`                                             |
| `action_cable_subscription_rejections_total`                     | カウンター     | 13.10   | クライアントからのActionCableサブスクリプションのうち拒否された数                                                         | `server_mode`                                             |
| `action_cable_transmitted_bytes_total`                           | カウンター     | 16.0    |  ActionCable経由で送信された総バイト数                                                                   | `operation`、`channel`                                    |
| `gitlab_issuable_fast_count_by_state_total`                      | カウンター     | 13.5    | **イシュー**ページと**マージリクエスト**ページでの行数取得操作の総数                                                |                                                           |
| `gitlab_issuable_fast_count_by_state_failures_total`             | カウンター     | 13.5    | **イシュー**ページと**マージリクエスト**ページでソフトフェイルとなった行数取得操作の数                                          |                                                           |
| `gitlab_ci_trace_finalize_duration_seconds`                      | ヒストグラム   | 13.6    | オブジェクトストレージへのビルドトレースチャンク移行処理の所要時間                                                            |                                                           |
| `gitlab_vulnerability_report_branch_comparison_real_duration_seconds`  | ヒストグラム   | 15.11    | 脆弱性レポートのデフォルトブランチ上のSQLクエリのウォールクロック実行時間                                                              |                                                           |
| `gitlab_vulnerability_report_branch_comparison_cpu_duration_seconds`  | ヒストグラム   | 15.11    | 脆弱性レポートのデフォルトブランチ上のSQLクエリのCPU実行時間                                                              |                                                           |
| `gitlab_external_http_total`                                     | カウンター     | 13.8    | 外部システムへのHTTP呼び出しの総数                                                                        | `controller`、`action`、`endpoint_id`                                   |
| `gitlab_external_http_duration_seconds`                          | カウンター     | 13.8    | 外部システムへの各HTTP呼び出しに費やされた時間（秒）                                                       |                                                           |
| `gitlab_external_http_exception_total`                           | カウンター     | 13.8    | 外部HTTP呼び出し時に発生した例外の総数                                                     |                                                           |
| `ci_report_parser_duration_seconds`                              | ヒストグラム   | 13.9    | CI/CDレポートアーティファクトの解析に費やされた時間                                                                                  | `parser`                                                  |
| `pipeline_graph_link_calculation_duration_seconds`               | ヒストグラム   | 13.9    | リンクの計算に費やされた合計時間（秒）                                                                        |                                                           |
| `pipeline_graph_links_total`                                     | ヒストグラム   | 13.9    | グラフごとのリンク数                                                                                             |                                                           |
| `pipeline_graph_links_per_job_ratio`                             | ヒストグラム   | 13.9    | グラフごとのジョブとリンクの比率                                                                                       |                                                           |
| `gitlab_ci_pipeline_security_orchestration_policy_processing_duration_seconds` | ヒストグラム   | 13.12    | CI/CDパイプラインでセキュリティポリシーの処理にかかる時間（秒）                                |                                                           |
| `gitlab_spamcheck_request_duration_seconds`                      | ヒストグラム   | 13.12   | Railsとアンチスパムエンジン間のリクエストの処理時間                                                      |                                                           |
| `service_desk_thank_you_email`                                   | カウンター     | 14.0    | 新しいサービスデスクのメールに対するメール応答の総数                                                            |                                                           |
| `service_desk_new_note_email`                                    | カウンター     | 14.0    | 新しいサービスデスクのコメントに関するメール通知の総数                                                       |                                                           |
| `email_receiver_error`                                           | カウンター     | 14.1    | 受信メール処理時のエラーの総数                                                                |                                                           |
| `gitlab_snowplow_events_total`                                   | カウンター     | 14.1    | GitLab Snowplow Analytics Instrumentationによるイベント発行の総数                                                   |                                                           |
| `gitlab_snowplow_failed_events_total`                            | カウンター     | 14.1    | GitLab Snowplow Analytics Instrumentationによるイベント発行失敗の総数                                         |                                                           |
| `gitlab_snowplow_successful_events_total`                        | カウンター     | 14.1    | GitLab Snowplow Analytics Instrumentationによるイベント発行成功の総数                                        |                                                           |
| `gitlab_ci_build_trace_errors_total`                             | カウンター     | 14.4    | ビルドトレース上の異なるエラータイプの総量                                                                | `error_reason`                                            |
| `gitlab_presentable_object_cacheless_render_real_duration_seconds`              | ヒストグラム   | 15.3     | 特定のWebリクエストオブジェクトをキャッシュおよび表示するのに費やされた実際の時間                                                    | `controller`、`action`、`endpoint_id`                                    |
| `cached_object_operations_total`                                      | カウンター     | 15.3    | 特定のWebリクエストに対してキャッシュされたオブジェクトの総数                                                                                                      | `controller`、`action`、`endpoint_id`                                    |
| `redis_hit_miss_operations_total`                                | カウンター     | 15.6    | Redisキャッシュのヒットとミスの総数                                                                           | `cache_hit`、`cache_identifier`、`feature_category`、`backing_resource` |
| `redis_cache_generation_duration_seconds`                        | ヒストグラム   | 15.6    | Redisキャッシュの生成にかかった時間                                                                                          | `cache_hit`、`cache_identifier`、`feature_category`、`backing_resource` |
| `gitlab_diffs_reorder_real_duration_seconds` | ヒストグラム | 15.8 | 差分バッチリクエストで差分ファイルの並べ替えに費やされた時間（秒） | `controller`、`action`、`endpoint_id` |
| `gitlab_diffs_collection_real_duration_seconds` | ヒストグラム | 15.8 | 差分バッチリクエストでマージリクエストの差分ファイルのクエリに費やされた時間（秒） | `controller`、`action`、`endpoint_id` |
| `gitlab_diffs_comparison_real_duration_seconds` | ヒストグラム | 15.8 | 差分バッチリクエストで比較データの取得に費やされた時間（秒） | `controller`、`action`、`endpoint_id` |
| `gitlab_diffs_unfoldable_positions_real_duration_seconds` | ヒストグラム | 15.8 | 差分バッチリクエストで展開できないノートの位置の取得に費やされた時間（秒） | `controller`、`action` |
| `gitlab_diffs_unfold_real_duration_seconds` | ヒストグラム | 15.8 | 差分バッチリクエストで位置の展開に費やされた時間（秒） | `controller`、`action`、`endpoint_id` |
| `gitlab_diffs_write_cache_real_duration_seconds` | ヒストグラム | 15.8 | 差分バッチリクエストでハイライト行と統計のキャッシュに費やされた時間（秒） | `controller`、`action`、`endpoint_id` |
| `gitlab_diffs_highlight_cache_decorate_real_duration_seconds` | ヒストグラム | 15.8 | 差分バッチリクエストでキャッシュから取得したハイライト行の設定に費やされた時間（秒） | `controller`、`action`、`endpoint_id` |
| `gitlab_diffs_render_real_duration_seconds` | ヒストグラム | 15.8 | 差分バッチリクエストで差分のシリアル化とレンダリングに費やされた時間（秒） | `controller`、`action`、`endpoint_id` |
| `gitlab_memwd_violations_total`                      | カウンター | 15.9  | Rubyプロセスがメモリのしきい値に違反した回数の合計 | |
| `gitlab_memwd_violations_handled_total`              | カウンター | 15.9  | Rubyプロセスのメモリ違反が処理された回数の合計 | |
| `gitlab_sli_rails_request_apdex_total` | カウンター | 14.4 | リクエストのApdex測定の総数。 | `endpoint_id`、`feature_category`、`request_urgency` |
| `gitlab_sli_rails_request_apdex_success_total` | カウンター | 14.4 | 緊急度に応じた目標時間内に収まった成功リクエストの総数。`gitlab_sli_rails_requests_apdex_total`で割ると、成功率を取得できます | `endpoint_id`、`feature_category`、`request_urgency` |
| `gitlab_sli_rails_request_error_total` | カウンター | 15.7 | リクエストエラーの測定回数の総数。 | `endpoint_id`、`feature_category`、`request_urgency`、`error` |
| `job_register_attempts_failed_total` | カウンター | 9.5 | Runnerによるジョブ登録の失敗回数をカウントする | |
| `job_register_attempts_total` | カウンター | 9.5 | Runnerによるジョブ登録の試行回数をカウントする | |
| `job_queue_duration_seconds` | ヒストグラム | 9.5 | リクエスト処理の実行時間 | |
| `gitlab_ci_queue_operations_total` | カウンター | 16.3 | キュー内で発生しているすべての操作の回数をカウントする | |
| `gitlab_ci_queue_depth_total` | ヒストグラム | 16.3 | 操作結果に関連するCI/CDビルドキューのサイズ | |
| `gitlab_ci_queue_size_total` | ヒストグラム | 16.3 | 初期化されたCI/CDビルドキューのサイズ | |
| `gitlab_ci_current_queue_size` | ゲージ | 16.3 | 初期化されたCI/CDビルドキューの現在のサイズ | |
| `gitlab_ci_queue_iteration_duration_seconds` | ヒストグラム | 16.3 | CI/CDキュー内でビルドを見つけるのにかかる時間 | |
| `gitlab_ci_queue_retrieval_duration_seconds` | ヒストグラム | 16.3 | ビルドキューを取得するためのSQLクエリの実行にかかる時間 | |
| `gitlab_connection_pool_size` | ゲージ | 16.7 | 接続プールのサイズ | |
| `gitlab_connection_pool_available_count` | ゲージ | 16.7 | プール内の利用可能な接続数 | |
| `gitlab_security_policies_scan_result_process_duration_seconds` | ヒストグラム | 16.7 | マージリクエスト承認ポリシーの処理にかかる時間 | |
| `gitlab_security_policies_policy_sync_duration_seconds` | ヒストグラム | 17.6 | ポリシー設定に対するポリシー変更の同期にかかる時間 | |
| `gitlab_security_policies_policy_deletion_duration_seconds` | ヒストグラム | 17.6 | ポリシー関連設定の削除にかかる時間 | |
| `gitlab_security_policies_policy_creation_duration_seconds` | ヒストグラム | 17.6 | ポリシー関連設定の作成にかかる時間 | |
| `gitlab_security_policies_sync_opened_merge_requests_duration_seconds` | ヒストグラム | 17.6 | ポリシーの変更後にオープンされたマージリクエストの同期にかかる時間 | |
| `gitlab_security_policies_scan_execution_configuration_rendering_seconds` | ヒストグラム | 17.3 | スキャン実行ポリシーのCI設定のレンダリングにかかる時間 | |
| `gitlab_security_policies_update_configuration_duration_seconds` | ヒストグラム | 17.6 | ポリシー設定の変更に対する同期スケジュールの設定にかかる時間 | |
| `gitlab_highlight_usage` | カウンター | 16.8 | `Gitlab::Highlight`が使用された回数 | `used_on` |
| `dependency_linker_usage` | カウンター | 16.8 | 依存関係リンカーが使用された回数 | `used_on` |
| `gitlab_keeparound_refs_requested_total` | カウンター | 16.10 | 作成がリクエストされたkeep-around refsの数をカウントする | `source` |
| `gitlab_keeparound_refs_created_total` | カウンター | 16.10 | 実際に作成されたkeep-around refsの数をカウントする | `source` |
| `search_advanced_index_repair_total` | カウンター | 17.3 | インデックス修復操作の回数をカウントする | `document_type` |
| `search_advanced_boolean_settings` | ゲージ | 17.3 | 高度な検索におけるブール値設定の現在の状態 | `name` |
| `gitlab_http_router_rule_total` | カウンター | 17.4 | HTTPルーターのルールにおける`rule_action`および`rule_type`の出現回数をカウントする | `rule_action`、`rule_type` |
| `gitlab_rack_attack_events_total` | カウンター | 17.6 | Rack Attackによって処理されたイベントの総数をカウントする | `event_type`、`event_name` |
| `gitlab_rack_attack_throttle_limit` | ゲージ | 17.6 | Rack Attackがスロットルを適用する前に、クライアントが実行可能なリクエストの最大数を報告する | `event_name` |
| `gitlab_rack_attack_throttle_period_seconds` | ゲージ | 17.6 | Rack Attackがスロットルを適用する前に、クライアントのリクエストをカウントする期間を報告する | `event_name` |
| `gitlab_application_rate_limiter_throttle_utilization_ratio` | ヒストグラム | 17.6 | GitLab Application Rate Limiterにおけるスロットル使用率 | `throttle_key`、`peek`、`feature_category` |
| `gitlab_find_dependency_paths_real_duration_seconds` | ヒストグラム | 18.3 |  指定されたコンポーネントの祖先依存関係パスの解決に費やされた時間（秒） | |
| `gitlab_dependency_paths_found_total` | カウンター | 18.3 |  指定された依存関係に対して見つかった祖先依存関係パスの数をカウントする | `cyclic` |

## 機能フラグで制御されるメトリクス {#metrics-controlled-by-a-feature-flag}

次のメトリクスは、機能フラグで制御できます。

| メトリック                                                         | 機能フラグ                                                       |
|:---------------------------------------------------------------|:-------------------------------------------------------------------|
| `gitlab_view_rendering_duration_seconds`                       | `prometheus_metrics_view_instrumentation`                          |
| `gitlab_ci_queue_depth_total` | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_size` | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_size_total` | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_iteration_duration_seconds` | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_current_queue_size` | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_retrieval_duration_seconds` | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_active_runners_total` | `gitlab_ci_builds_queuing_metrics` |

## Praefectメトリクス {#praefect-metrics}

メトリクスを報告するように[Praefectを設定](../../gitaly/praefect/configure.md#praefect)できます。利用可能なメトリックについては、[Monitoring Gitaly Cluster (Praefect)](../../gitaly/praefect/monitoring.md)を参照してください。

## Sidekiqメトリクス {#sidekiq-metrics}

Sidekiqジョブもメトリクスを収集することがあり、Sidekiq exporterが有効になっている場合にこれらのメトリクスにアクセスできます。たとえば、`gitlab.yml`の`monitoring.sidekiq_exporter`設定オプションを使用します。これらのメトリクスは、設定されたポートの`/metrics`パスから提供されます。

| メトリック                                         | 種類    | 提供開始 | 説明 | ラベル |
|:---------------------------------------------- |:------- |:----- |:----------- |:------ |
| `sidekiq_jobs_cpu_seconds`                     | ヒストグラム | 12.4 | Sidekiqジョブの実行にかかったCPU時間（秒）                                                              | `queue`、`boundary`、`external_dependencies`、`feature_category`、`job_status`、`urgency` |
| `sidekiq_jobs_completion_seconds`              | ヒストグラム | 12.2 | Sidekiqジョブの完了にかかった時間（秒）                                                                     | `queue`、`boundary`、`external_dependencies`、`feature_category`、`job_status`、`urgency` |
| `sidekiq_jobs_db_seconds`                      | ヒストグラム | 12.9 | Sidekiqジョブの実行にかかったDB時間（秒）                                                               | `queue`、`boundary`、`external_dependencies`、`feature_category`、`job_status`、`urgency` |
| `sidekiq_jobs_gitaly_seconds`                  | ヒストグラム | 12.9 | Sidekiqジョブの実行にかかったGitalyの処理時間（秒）                                                           | `queue`、`boundary`、`external_dependencies`、`feature_category`、`job_status`、`urgency` |
| `sidekiq_redis_requests_duration_seconds`      | ヒストグラム | 13.1 | SidekiqジョブがRedisサーバーへのクエリに費やした時間（秒）                                | `queue`、`boundary`、`external_dependencies`、`feature_category`、`job_status`、`urgency` |
| `sidekiq_elasticsearch_requests_duration_seconds`      | ヒストグラム | 13.1 | SidekiqジョブがElasticsearchサーバーへのリクエストに費やした時間（秒）                                | `queue`、`boundary`、`external_dependencies`、`feature_category`、`job_status`、`urgency` |
| `sidekiq_jobs_queue_duration_seconds`          | ヒストグラム | 12.5 | Sidekiqジョブが実行される前にキューに入れられていた時間（秒）                             | `queue`、`boundary`、`external_dependencies`、`feature_category`、`urgency` |
| `sidekiq_jobs_failed_total`                    | カウンター   | 12.2 | 失敗したSidekiqジョブの数                                                                                 | `queue`、`boundary`、`external_dependencies`、`feature_category`、`urgency` |
| `sidekiq_jobs_retried_total`                   | カウンター   | 12.2 | 再試行されたSidekiqジョブの数                                                                                | `queue`、`boundary`、`external_dependencies`、`feature_category`、`urgency` |
| `sidekiq_jobs_interrupted_total`               | カウンター   | 15.2 | 中断されたSidekiqジョブの数                                                                            | `queue`、`boundary`、`external_dependencies`、`feature_category`、`urgency` |
| `sidekiq_jobs_dead_total`                      | カウンター   | 13.7 | Sidekiqのデッドジョブの数（最大再試行回数に達したジョブ）                                               | `queue`、`boundary`、`external_dependencies`、`feature_category`、`urgency` |
| `sidekiq_redis_requests_total`                 | カウンター   | 13.1 | Sidekiqジョブの実行中に発生したRedisリクエストの数                                                       | `queue`、`boundary`、`external_dependencies`、`feature_category`、`job_status`、`urgency` |
| `sidekiq_elasticsearch_requests_total`         | カウンター   | 13.1 | Sidekiqジョブの実行中に発生したElasticsearchリクエストの数                                                       | `queue`、`boundary`、`external_dependencies`、`feature_category`、`job_status`、`urgency` |
| `sidekiq_jobs_skipped_total`                   | カウンター   | 16.2 | `drop_sidekiq_jobs`機能フラグが有効、または`run_sidekiq_jobs`機能フラグが無効な場合にスキップ（破棄または延期）されるジョブの数                          | `worker`、`action`、`feature_category`、`reason`                                                                                   |
| `sidekiq_running_jobs`                         | ゲージ     | 12.2 | 実行中のSidekiqジョブの数                                                                      | `queue`、`boundary`、`external_dependencies`、`feature_category`、`urgency` |
| `sidekiq_concurrency`                          | ゲージ     | 12.5 | Sidekiqジョブの最大数                                                                      |                                                                   |
| `sidekiq_mem_total_bytes`                      | ゲージ     | 15.3 | オブジェクトスロットを消費するオブジェクトと、mallocが必要だったオブジェクトの両方に対して割り当てられたバイト数|                                                                   |
| `sidekiq_concurrency_limit_queue_jobs`         | ゲージ     | 17.3 | 並行処理制限キューで待機しているSidekiqジョブの数|  `worker`、`feature_category`                                                             |
| `sidekiq_concurrency_limit_max_concurrent_jobs` | ゲージ    | 17.3 | 並行処理中のSidekiqジョブの最大数 |   `worker`、`feature_category`                                                           |
| `sidekiq_concurrency_limit_current_concurrent_jobs`    | ゲージ | 17.6 | 現在実行中の同時ジョブ数 |  `worker`、`feature_category`                                                             |
| `sidekiq_concurrency_limit_current_limit`      | ゲージ     | 18.3 | スロットリングの対象となる、現在実行が許可されている同時ジョブの数 |   `worker`、`feature_category`                                                           |
| `sidekiq_throttling_events_total`              | カウンター | 18.3  | Sidekiqスロットリングイベントの合計数 |   `worker`、`strategy` |
| `geo_db_replication_lag_seconds`               | ゲージ   | 10.2  | データベースのレプリケーションラグ（秒） | `url` |
| `geo_repositories`                             | ゲージ   | 10.2  | 17.9で非推奨になりました。今後のどのGitLabリリースで削除対象となるのかは、まだ確定していません。代わりに`geo_project_repositories`を使用してください。プライマリで利用可能なリポジトリの総数です | `url` |
| `geo_lfs_objects`                              | ゲージ   | 10.2  | プライマリのLFSオブジェクトの数 | `url` |
| `geo_lfs_objects_checksummed`                  | ゲージ   | 14.6  | プライマリでチェックサムの計算に成功したLFSオブジェクトの数 | `url` |
| `geo_lfs_objects_checksum_failed`              | ゲージ   | 14.6  | プライマリでチェックサムの計算に失敗したLFSオブジェクトの数 | `url` |
| `geo_lfs_objects_checksum_total`               | ゲージ   | 14.6  | プライマリでチェックサムの計算が必要なLFSオブジェクトの数 | `url` |
| `geo_lfs_objects_synced`                       | ゲージ   | 10.2  | セカンダリで同期された同期可能なLFSオブジェクトの数 | `url` |
| `geo_lfs_objects_failed`                       | ゲージ   | 10.2  | セカンダリで同期に失敗した同期可能なLFSオブジェクトの数 | `url` |
| `geo_lfs_objects_registry`                     | ゲージ   | 14.6  | レジストリ内のLFSオブジェクトの数 | `url` |
| `geo_lfs_objects_verified`                     | ゲージ   | 14.6  | セカンダリで検証に成功したLFSオブジェクトの数 | `url` |
| `geo_lfs_objects_verification_failed`          | ゲージ   | 14.6  | セカンダリで検証に失敗したLFSオブジェクトの数 | `url` |
| `geo_lfs_objects_verification_total`           | ゲージ   | 14.6  | セカンダリで検証を試行するLFSオブジェクトの数 | `url` |
| `geo_last_event_id`                            | ゲージ   | 10.2  | プライマリにおける最新のイベントログエントリのデータベースID | `url` |
| `geo_last_event_timestamp`                     | ゲージ   | 10.2  | プライマリにおける最新のイベントログエントリのUNIXタイムスタンプ | `url` |
| `geo_cursor_last_event_id`                     | ゲージ   | 10.2  | セカンダリが処理したイベントログの最後のデータベースID | `url` |
| `geo_cursor_last_event_timestamp`              | ゲージ   | 10.2  | セカンダリが処理したイベントログの最後のUNIXタイムスタンプ | `url` |
| `geo_status_failed_total`                      | カウンター | 10.2  | Geoノードからの状態の取得に失敗した回数 | `url` |
| `geo_last_successful_status_check_timestamp`   | ゲージ   | 10.2  | 状態が正常に更新された最後のタイムスタンプ | `url` |
| `geo_package_files`                            | ゲージ   | 13.0  | プライマリにおけるパッケージファイルの数 | `url` |
| `geo_package_files_checksummed`                | ゲージ   | 13.0  | プライマリでチェックサムが計算されたパッケージファイルの数 | `url` |
| `geo_package_files_checksum_failed`            | ゲージ   | 13.0  | プライマリでチェックサムの計算に失敗したパッケージファイルの数 | `url` |
| `geo_package_files_synced`                     | ゲージ   | 13.3  | セカンダリで同期された同期可能なパッケージファイルの数 | `url` |
| `geo_package_files_failed`                     | ゲージ   | 13.3  | セカンダリで同期に失敗した同期可能なパッケージファイルの数 | `url` |
| `geo_package_files_registry`                   | ゲージ   | 13.3  | レジストリ内のパッケージファイルの数 | `url` |
| `geo_terraform_state_versions`                 | ゲージ   | 13.5  | プライマリのTerraformステートバージョンの数 | `url` |
| `geo_terraform_state_versions_checksummed`     | ゲージ   | 13.5  | プライマリでチェックサムの計算に成功したTerraformステートバージョンの数 | `url` |
| `geo_terraform_state_versions_checksum_failed` | ゲージ   | 13.5  | プライマリでチェックサムの計算に失敗したTerraformステートバージョンの数 | `url` |
| `geo_terraform_state_versions_checksum_total`  | ゲージ   | 13.12  | プライマリでチェックサムの計算が必要なTerraformステートバージョンの数 | `url` |
| `geo_terraform_state_versions_synced`          | ゲージ   | 13.5  | セカンダリで同期された同期可能なTerraformステートバージョンの数 | `url` |
| `geo_terraform_state_versions_failed`          | ゲージ   | 13.5  | セカンダリで同期に失敗した同期可能なTerraformステートバージョンの数 | `url` |
| `geo_terraform_state_versions_registry`        | ゲージ   | 13.5  | レジストリ内のTerraformステートバージョンの数 | `url` |
| `geo_terraform_state_versions_verified`        | ゲージ   | 13.12  | セカンダリで検証に成功したTerraformステートバージョンの数 | `url` |
| `geo_terraform_state_versions_verification_failed` | ゲージ   | 13.12  | セカンダリで検証に失敗したTerraformステートバージョンの数 | `url` |
| `geo_terraform_state_versions_verification_total` | ゲージ   | 13.12  | セカンダリで検証を試行するTerraformステートバージョンの数 | `url` |
| `global_search_bulk_cron_queue_size`           | ゲージ   | 12.10 | 非推奨となりました。18.0で削除される予定です。`search_advanced_bulk_cron_queue_size`に置き換えられました。Elasticsearchへの同期を待機している増分データベース更新の数です | |
| `global_search_bulk_cron_initial_queue_size`   | ゲージ   | 13.1  | 非推奨となりました。18.0で削除される予定です。`search_advanced_bulk_cron_initial_queue_size`に置き換えられました。Elasticsearchへの同期を待機している初期データベース更新の数です | |
| `global_search_awaiting_indexing_queue_size`   | ゲージ   | 13.2  | 非推奨となりました。18.0で削除される予定です。`search_advanced_awaiting_indexing_queue_size`に置き換えられました。インデックス作成が一時停止されている間、Elasticsearchへの同期を待機しているデータベース更新の数です | |
| `search_advanced_bulk_cron_queue_size`           | ゲージ   | 17.6  | Elasticsearchへの同期を待機している増分データベース更新の数です | |
| `search_advanced_bulk_cron_initial_queue_size`   | ゲージ   | 17.6  |  Elasticsearchへの同期を待機している初期データベース更新の数です | |
| `search_advanced_bulk_cron_embedding_queue_size` | ゲージ   | 17.6  | Elasticsearchへの同期を待機している埋め込み更新の数 | |
| `search_advanced_awaiting_indexing_queue_size`   | ゲージ   | 17.6  | インデックス作成が一時停止されている間、Elasticsearchへの同期を待機しているデータベース更新の数です | |
| `geo_merge_request_diffs`                      | ゲージ   | 13.4  | プライマリにおけるマージリクエスト差分の数 | `url` |
| `geo_merge_request_diffs_checksum_total`       | ゲージ   | 13.12 | プライマリでチェックサムが計算されたマージリクエスト差分の数 | `url` |
| `geo_merge_request_diffs_checksummed`          | ゲージ   | 13.4  | プライマリでチェックサムの計算に成功したマージリクエスト差分の数 | `url` |
| `geo_merge_request_diffs_checksum_failed`      | ゲージ   | 13.4  | プライマリでチェックサムの計算に失敗したマージリクエスト差分の数 | `url` |
| `geo_merge_request_diffs_synced`               | ゲージ   | 13.4  | セカンダリで同期された同期可能なマージリクエスト差分の数 | `url` |
| `geo_merge_request_diffs_failed`               | ゲージ   | 13.4  | セカンダリで同期に失敗した同期可能なマージリクエスト差分の数 | `url` |
| `geo_merge_request_diffs_registry`             | ゲージ   | 13.4  | レジストリ内のマージリクエスト差分の数 | `url` |
| `geo_merge_request_diffs_verification_total`   | ゲージ   | 13.12 | セカンダリで検証を試行するマージリクエスト差分の数 | `url` |
| `geo_merge_request_diffs_verified`             | ゲージ   | 13.12 | セカンダリで検証に成功したマージリクエスト差分の数 | `url` |
| `geo_merge_request_diffs_verification_failed`  | ゲージ   | 13.12 | セカンダリで検証に失敗したマージリクエスト差分の数 | `url` |
| `geo_snippet_repositories`                     | ゲージ   | 13.4  | プライマリにおけるスニペットの数 | `url` |
| `geo_snippet_repositories_checksummed`         | ゲージ   | 13.4  | プライマリでチェックサムが計算されたスニペットの数 | `url` |
| `geo_snippet_repositories_checksum_failed`     | ゲージ   | 13.4  | プライマリでチェックサムの計算に失敗したスニペットの数 | `url` |
| `geo_snippet_repositories_synced`              | ゲージ   | 13.4  | セカンダリで同期された、同期可能なスニペットの数 | `url` |
| `geo_snippet_repositories_failed`              | ゲージ   | 13.4  | セカンダリで同期に失敗した、同期可能なスニペットの数 | `url` |
| `geo_snippet_repositories_registry`            | ゲージ   | 13.4  | レジストリ内の同期可能なスニペットの数 | `url` |
| `geo_group_wiki_repositories`                     | ゲージ   | 13.10 | プライマリにおけるグループWikiの数 | `url` |
| `geo_group_wiki_repositories_checksum_total`      | ゲージ   | 16.3  | プライマリでチェックサムが計算されたグループWikiの数 | `url` |
| `geo_group_wiki_repositories_checksummed`         | ゲージ   | 13.10 | プライマリでチェックサムの計算に成功したグループWikiの数 | `url` |
| `geo_group_wiki_repositories_checksum_failed`     | ゲージ   | 13.10 | プライマリでチェックサムの計算に失敗したグループWikiの数 | `url` |
| `geo_group_wiki_repositories_synced`              | ゲージ   | 13.10 | セカンダリで同期された同期可能なグループWikiの数 | `url` |
| `geo_group_wiki_repositories_failed`              | ゲージ   | 13.10 | セカンダリで同期に失敗した同期可能なグループWikiの数 | `url` |
| `geo_group_wiki_repositories_registry`            | ゲージ   | 13.10 | レジストリ内のグループWikiの数 | `url` |
| `geo_group_wiki_repositories_verification_total`  | ゲージ   | 16.3 | セカンダリで検証を試行するグループWikiの数 | `url` |
| `geo_group_wiki_repositories_verified`            | ゲージ   | 16.3 | セカンダリで検証に成功したグループWikiの数 | `url` |
| `geo_group_wiki_repositories_verification_failed` | ゲージ   | 16.3 | セカンダリで検証に失敗したグループWikiの数 | `url` |
| `geo_pages_deployments`                        | ゲージ   | 14.3  | プライマリにおけるPagesデプロイの数 | `url` |
| `geo_pages_deployments_checksum_total`         | ゲージ   | 14.6  | プライマリでチェックサムが計算されたPagesデプロイの数 | `url` |
| `geo_pages_deployments_checksummed`            | ゲージ   | 14.6  | プライマリでチェックサムの計算に成功したPagesデプロイの数 | `url` |
| `geo_pages_deployments_checksum_failed`        | ゲージ   | 14.6  | プライマリでチェックサムの計算に失敗したPagesデプロイの数 | `url` |
| `geo_pages_deployments_synced`                 | ゲージ   | 14.3  | セカンダリで同期された同期可能なPagesデプロイの数 | `url` |
| `geo_pages_deployments_failed`                 | ゲージ   | 14.3  | セカンダリで同期に失敗した同期可能なPagesデプロイの数 | `url` |
| `geo_pages_deployments_registry`               | ゲージ   | 14.3  | レジストリ内のPagesデプロイの数 | `url` |
| `geo_pages_deployments_verification_total`     | ゲージ   | 14.6  | セカンダリで検証を試行するPagesデプロイの数 | `url` |
| `geo_pages_deployments_verified`               | ゲージ   | 14.6  | セカンダリで検証に成功したPagesデプロイの数 | `url` |
| `geo_pages_deployments_verification_failed`    | ゲージ   | 14.6  | セカンダリで検証に失敗したPagesデプロイの数 | `url` |
| `geo_job_artifacts`                            | ゲージ   | 14.8  | プライマリにおけるジョブアーティファクトの数 | `url` |
| `geo_job_artifacts_checksum_total`             | ゲージ   | 14.8  | プライマリでチェックサムが計算されたジョブアーティファクトの数 | `url` |
| `geo_job_artifacts_checksummed`                | ゲージ   | 14.8  | プライマリでチェックサムの計算に成功したジョブアーティファクトの数 | `url` |
| `geo_job_artifacts_checksum_failed`            | ゲージ   | 14.8  | プライマリでチェックサムの計算に失敗したジョブアーティファクトの数 | `url` |
| `geo_job_artifacts_synced`                     | ゲージ   | 14.8  | セカンダリで同期された同期可能なジョブアーティファクトの数 | `url` |
| `geo_job_artifacts_failed`                     | ゲージ   | 14.8  | セカンダリで同期に失敗した同期可能なジョブアーティファクトの数 | `url` |
| `geo_job_artifacts_registry`                   | ゲージ   | 14.8  | レジストリ内のジョブアーティファクトの数 | `url` |
| `geo_job_artifacts_verification_total`         | ゲージ   | 14.8  | セカンダリで検証を試行するジョブアーティファクトの数 | `url` |
| `geo_job_artifacts_verified`                   | ゲージ   | 14.8  | セカンダリで検証に成功したジョブアーティファクトの数 | `url` |
| `geo_job_artifacts_verification_failed`        | ゲージ   | 14.8  | セカンダリで検証に失敗したジョブアーティファクトの数 | `url` |
| `limited_capacity_worker_running_jobs`         | ゲージ   | 13.5  | 実行中のジョブの数 | `worker` |
| `limited_capacity_worker_max_running_jobs`     | ゲージ   | 13.5  | 実行中のジョブの最大数 | `worker` |
| `limited_capacity_worker_remaining_work_count` | ゲージ   | 13.5  | キューに入れられるのを待機しているジョブの数 | `worker` |
| `destroyed_job_artifacts_count_total`          | カウンター | 13.6  | 破棄された期限切れのジョブアーティファクトの数 | |
| `destroyed_pipeline_artifacts_count_total`     | カウンター | 13.8  | 破棄された期限切れのパイプラインアーティファクトの数 | |
| `gitlab_optimistic_locking_retries`            | ヒストグラム | 13.10  | 楽観的リトライロックの実行の再試行回数 | |
| `geo_uploads`                      | ゲージ   | 14.1  | プライマリにおけるアップロードの数 | `url` |
| `geo_uploads_synced`               | ゲージ   | 14.1  | セカンダリで同期されたアップロードの数 | `url` |
| `geo_uploads_failed`               | ゲージ   | 14.1  | セカンダリで同期に失敗した同期可能なアップロードの数 | `url` |
| `geo_uploads_registry`             | ゲージ   | 14.1  | レジストリ内のアップロードの数 | `url` |
| `geo_uploads_checksum_total`       | ゲージ   | 14.6 | プライマリでチェックサムが計算されたアップロードの数 | `url` |
| `geo_uploads_checksummed`          | ゲージ   | 14.6  | プライマリでチェックサムの計算に成功したアップロードの数 | `url` |
| `geo_uploads_checksum_failed`      | ゲージ   | 14.6  | プライマリでチェックサムの計算に失敗したアップロードの数 | `url` |
| `geo_uploads_verification_total`   | ゲージ   | 14.6 | セカンダリで検証を試行するアップロードの数 | `url` |
| `geo_uploads_verified`             | ゲージ   | 14.6 | セカンダリで検証に成功したアップロードの数 | `url` |
| `geo_uploads_verification_failed`  | ゲージ   | 14.6 | セカンダリで検証に失敗したアップロードの数 | `url` |
| `geo_container_repositories`           | ゲージ   | 15.4  | プライマリにおけるコンテナリポジトリの数 | `url` |
| `geo_container_repositories_synced`    | ゲージ   | 15.4  | セカンダリで同期されたコンテナリポジトリの数 | `url` |
| `geo_container_repositories_failed`    | ゲージ   | 15.4  | セカンダリで同期に失敗した同期可能なコンテナリポジトリの数 | `url` |
| `geo_container_repositories_registry`  | ゲージ   | 15.4  | レジストリ内のコンテナリポジトリの数 | `url` |
| `geo_container_repositories_checksum_total`           | ゲージ   | 15.10  | プライマリでチェックサムの計算に成功したコンテナリポジトリの数 | `url` |
| `geo_container_repositories_checksummed`    | ゲージ   | 15.10  | プライマリでチェックサムの計算を試行したコンテナリポジトリの数 | `url` |
| `geo_container_repositories_checksum_failed`    | ゲージ   | 15.10  | プライマリでチェックサムの計算に失敗したコンテナリポジトリの数 | `url` |
| `geo_container_repositories_verification_total`  | ゲージ   | 15.10  | セカンダリで試行されたコンテナリポジトリの検証回数 | `url` |
| `geo_container_repositories_verified`    | ゲージ   | 15.10  | セカンダリで検証されたコンテナリポジトリの数 | `url` |
| `geo_container_repositories_verification_failed`    | ゲージ   | 15.10  | セカンダリで検証に失敗したコンテナリポジトリの数 | `url` |
| `geo_ci_secure_files`                            | ゲージ   | 15.3  | プライマリにおける安全なファイルの数 | `url` |
| `geo_ci_secure_files_checksum_total`             | ゲージ   | 15.3  | プライマリでチェックサムが計算された安全なファイルの数 | `url` |
| `geo_ci_secure_files_checksummed`                | ゲージ   | 15.3  | プライマリでチェックサムの計算に成功した安全なファイルの数 | `url` |
| `geo_ci_secure_files_checksum_failed`            | ゲージ   | 15.3  | プライマリでチェックサムの計算に失敗した安全なファイルの数 | `url` |
| `geo_ci_secure_files_synced`                     | ゲージ   | 15.3  | セカンダリで同期された同期可能な安全なファイルの数 | `url` |
| `geo_ci_secure_files_failed`                     | ゲージ   | 15.3  | セカンダリで同期に失敗した同期可能な安全なファイルの数 | `url` |
| `geo_ci_secure_files_registry`                   | ゲージ   | 15.3  | レジストリ内の安全なファイルの数 | `url` |
| `geo_ci_secure_files_verification_total`         | ゲージ   | 15.3  | セカンダリで検証を試行する安全なファイルの数 | `url` |
| `geo_ci_secure_files_verified`                   | ゲージ   | 15.3  | セカンダリで検証に成功した安全なファイルの数 | `url` |
| `geo_ci_secure_files_verification_failed`        | ゲージ   | 15.3  | セカンダリで検証に失敗した安全なファイルの数 | `url` |
| `geo_dependency_proxy_blob`                      | ゲージ   | 15.6  | プライマリにおける依存プロキシblobの数 | |
| `geo_dependency_proxy_blob_checksum_total`       | ゲージ   | 15.6  | プライマリでチェックサムが計算された依存プロキシblobの数 | |
| `geo_dependency_proxy_blob_checksummed`          | ゲージ   | 15.6  | プライマリでチェックサムの計算に成功した依存プロキシblobの数 | |
| `geo_dependency_proxy_blob_checksum_failed`      | ゲージ   | 15.6  | プライマリでチェックサムの計算に失敗した依存プロキシblobの数 | |
| `geo_dependency_proxy_blob_synced`               | ゲージ   | 15.6  | セカンダリで同期された依存プロキシblobの数 | |
| `geo_dependency_proxy_blob_failed`               | ゲージ   | 15.6  | セカンダリで同期に失敗した依存プロキシblobの数 | |
| `geo_dependency_proxy_blob_registry`             | ゲージ   | 15.6  | レジストリ内の依存プロキシblobの数 | |
| `geo_dependency_proxy_blob_verification_total`   | ゲージ   | 15.6  | セカンダリで検証を試行する依存プロキシblobの数 | |
| `geo_dependency_proxy_blob_verified`             | ゲージ   | 15.6  | セカンダリで検証に成功した依存プロキシblobの数 | |
| `geo_dependency_proxy_blob_verification_failed`  | ゲージ   | 15.6  | セカンダリで検証に失敗した依存プロキシblobの数 | |
| `geo_dependency_proxy_manifests`                     | ゲージ   | 15.6  | プライマリにおける依存プロキシマニフェストの数 | `url` |
| `geo_dependency_proxy_manifests_checksum_total`      | ゲージ   | 15.6  | プライマリでチェックサムが計算された依存プロキシマニフェストの数 | `url` |
| `geo_dependency_proxy_manifests_checksummed`         | ゲージ   | 15.6  | プライマリでチェックサムの計算に成功した依存プロキシマニフェストの数 | `url` |
| `geo_dependency_proxy_manifests_checksum_failed`     | ゲージ   | 15.6  | プライマリでチェックサムの計算に失敗した依存プロキシマニフェストの数 | `url` |
| `geo_dependency_proxy_manifests_synced`              | ゲージ   | 15.6  | セカンダリで同期された同期可能な依存プロキシマニフェストの数 | `url` |
| `geo_dependency_proxy_manifests_failed`              | ゲージ   | 15.6  | セカンダリで同期に失敗した同期可能な依存プロキシマニフェストの数 | `url` |
| `geo_dependency_proxy_manifests_registry`            | ゲージ   | 15.6  | レジストリ内の依存プロキシマニフェストの数 | `url` |
| `geo_dependency_proxy_manifests_verification_total`  | ゲージ   | 15.6  | セカンダリで検証を試行する依存プロキシマニフェストの数 | `url` |
| `geo_dependency_proxy_manifests_verified`            | ゲージ   | 15.6  | セカンダリで検証に成功した依存プロキシマニフェストの数 | `url` |
| `geo_dependency_proxy_manifests_verification_failed` | ゲージ   | 15.6  | セカンダリで検証に失敗した依存プロキシマニフェストの数 | `url` |
| `geo_project_wiki_repositories` | ゲージ | 15.10 | プライマリにおけるプロジェクトWikiリポジトリの数 | `url` |
| `geo_project_wiki_repositories_checksum_total` | ゲージ | 15.10 | プライマリでチェックサムが計算されたプロジェクトWikiリポジトリの数 | `url` |
| `geo_project_wiki_repositories_checksummed` | ゲージ | 15.10 | プライマリでチェックサムの計算に成功したプロジェクトWikiリポジトリの数 | `url` |
| `geo_project_wiki_repositories_checksum_failed` | ゲージ | 15.10 | プライマリでチェックサムの計算に失敗したプロジェクトWikiリポジトリの数 | `url` |
| `geo_project_wiki_repositories_synced` | ゲージ | 15.10 | セカンダリで同期された同期可能なプロジェクトWikiリポジトリの数 | `url` |
| `geo_project_wiki_repositories_failed` | ゲージ | 15.10 | セカンダリで同期に失敗した同期可能なプロジェクトWikiリポジトリの数 | `url` |
| `geo_project_wiki_repositories_registry` | ゲージ | 15.10 |  レジストリ内のプロジェクトWikiリポジトリの数 | `url` |
| `geo_project_wiki_repositories_verification_total` | ゲージ | 15.10 | セカンダリで検証を試行するプロジェクトWikiリポジトリの数 | `url` |
| `geo_project_wiki_repositories_verified` | ゲージ | 15.10 | セカンダリで検証に成功したプロジェクトWikiリポジトリの数 | `url` |
| `geo_project_wiki_repositories_verification_failed` | ゲージ | 15.10 | セカンダリで検証に失敗したプロジェクトWikiリポジトリの数 | `url` |
| `geo_project_repositories` | ゲージ | 16.2 | プライマリにおけるプロジェクトリポジトリの数 | `url` |
| `geo_project_repositories_checksum_total` | ゲージ | 16.2 | プライマリでチェックサムが計算されたプロジェクトリポジトリの数 | `url` |
| `geo_project_repositories_checksummed` | ゲージ | 16.2 | プライマリでチェックサムの計算に成功したプロジェクトリポジトリの数 | `url` |
| `geo_project_repositories_checksum_failed` | ゲージ | 16.2 | プライマリでチェックサムの計算に失敗したプロジェクトリポジトリの数 | `url` |
| `geo_project_repositories_synced` | ゲージ | 16.2 | セカンダリで同期された同期可能なプロジェクトリポジトリの数 | `url` |
| `geo_project_repositories_failed` | ゲージ | 16.2 | セカンダリで同期に失敗した同期可能なプロジェクトリポジトリの数 | `url` |
| `geo_project_repositories_registry` | ゲージ | 16.2 |  レジストリ内のプロジェクトリポジトリの数 | `url` |
| `geo_project_repositories_verification_total` | ゲージ | 16.2 | セカンダリで検証を試行するプロジェクトリポジトリの数 | `url` |
| `geo_project_repositories_verified` | ゲージ | 16.2 | セカンダリで検証に成功したプロジェクトリポジトリの数 | `url` |
| `geo_project_repositories_verification_failed` | ゲージ | 16.2 | セカンダリで検証に失敗したプロジェクトリポジトリの数 | `url` |
| `geo_repositories_synced`                            | ゲージ   | 10.2    | 非推奨となりました。17.0で削除される予定です。16.3と16.4では欠落しています。`geo_project_repositories_synced`に置き換えられました。セカンダリで同期されたリポジトリの数です | `url` |
| `geo_repositories_failed`                            | ゲージ   | 10.2    | 非推奨となりました。17.0で削除される予定です。16.3と16.4では欠落しています。`geo_project_repositories_failed`に置き換えられました。セカンダリで同期に失敗したリポジトリの数です | `url` |
| `geo_repositories_checksummed`                       | ゲージ   | 10.7    | 非推奨となりました。17.0で削除される予定です。16.3と16.4では欠落しています。`geo_project_repositories_checksummed`に置き換えられました。プライマリでチェックサムが計算されたリポジトリの数です | `url` |
| `geo_repositories_checksum_failed`                   | ゲージ   | 10.7    | 非推奨となりました。17.0で削除される予定です。16.3と16.4では欠落しています。`geo_project_repositories_checksum_failed`に置き換えられました。プライマリでチェックサムの計算に失敗したリポジトリの数です | `url` |
| `geo_repositories_verified`                          | ゲージ   | 10.7    | 非推奨となりました。17.0で削除される予定です。16.3と16.4では欠落しています。`geo_project_repositories_verified`に置き換えられました。セカンダリで検証に成功したリポジトリの数です | `url` |
| `geo_repositories_verification_failed`               | ゲージ   | 10.7    | 非推奨となりました。17.0で削除される予定です。16.3と16.4では欠落しています。`geo_project_repositories_verification_failed`に置き換えられました。セカンダリで検証に失敗したリポジトリの数です | `url` |
| `gitlab_memwd_violations_total`                      | カウンター | 15.9    | Sidekiqプロセスがメモリのしきい値に違反した回数の合計                                                                                        | |
| `gitlab_memwd_violations_handled_total`              | カウンター | 15.9    | Sidekiqプロセスのメモリ違反が処理された回数の合計                                                                                       | |
| `sidekiq_watchdog_running_jobs_total`                | カウンター | 15.9    | RSS制限に達したときに実行中だったジョブ                                                                                                            | `worker_class`                                                                                          |
| `gitlab_maintenance_mode`                            | ゲージ   | 15.11   | GitLabメンテナンスモードが有効かどうか | |
| `geo_design_management_repositories`                     | ゲージ   | 16.1  | プライマリにおけるデザインリポジトリの数 | `url` |
| `geo_design_management_repositories_checksum_total`      | ゲージ   | 16.1 | プライマリでチェックサムの計算を試行したデザインリポジトリの数 | `url` |
| `geo_design_management_repositories_checksummed`         | ゲージ   | 16.1 | プライマリでチェックサムの計算に成功したデザインリポジトリの数 | `url` |
| `geo_design_management_repositories_checksum_failed`     | ゲージ   | 16.1 | プライマリでチェックサムの計算に失敗したデザインリポジトリの数 | `url` |
| `geo_design_management_repositories_synced`              | ゲージ   | 16.1 | セカンダリで同期された同期可能なデザインリポジトリの数 | `url` |
| `geo_design_management_repositories_failed`              | ゲージ   | 16.1 | セカンダリで同期に失敗した同期可能なデザインリポジトリの数 | `url` |
| `geo_design_management_repositories_registry`            | ゲージ   | 16.1 | レジストリ内のデザインリポジトリの数 | `url` |
| `geo_design_management_repositories_verification_total`  | ゲージ   | 16.1 | セカンダリで試行されたデザインリポジトリの検証回数 | `url` |
| `geo_design_management_repositories_verified`            | ゲージ   | 16.1 | セカンダリで検証されたデザインリポジトリの数 | `url` |
| `geo_design_management_repositories_verification_failed` | ゲージ   | 16.1 | セカンダリで検証に失敗したデザインリポジトリの数 | `url` |
| `gitlab_ci_queue_active_runners_total`                   | ヒストグラム | 16.3 | プロジェクトでCI/CDキューを処理できるアクティブなRunnerの数 | |
| `gitlab_transaction_event_remote_mirrors_failed_total`           | カウンター     | 10.8    | 失敗したリモートミラーのカウンター                                                                                     |                                                           |
| `gitlab_transaction_event_remote_mirrors_finished_total`         | カウンター     | 10.8    | 完了したリモートミラーのカウンター                                                                                   |                                                           |
| `gitlab_transaction_event_remote_mirrors_running_total`          | カウンター     | 10.8    | 実行中のリモートミラーのカウンター                                                                                    |                                                           |

## データベースロードバランシングメトリクス {#database-load-balancing-metrics}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

次のメトリクスを利用できます。

| メトリック                                                   | 種類      | 提供開始                                                         | 説明                                                                        | ラベル                                                                                                                                   |
|:-------------------------------------------------------- |:--------- |:------------------------------------------------------------- |:---------------------------------------------------------------------------------- |:---------------------------------------------------------------------------------------------------------------------------------------- |
| `db_load_balancing_hosts`                                | ゲージ     | [12.3](https://gitlab.com/gitlab-org/gitlab/-/issues/13630)   | 現在のロードバランシングホストの数                                             |                                                                                                                                          |
| `sidekiq_load_balancing_count`                           | カウンター   | 13.11                                                         | データ整合性を`:sticky`または`:delayed`に設定したロードバランシング使用時のSidekiqジョブ | `queue`、`boundary`、`external_dependencies`、`feature_category`、`job_status`、`urgency`、`data_consistency`、`load_balancing_strategy` |
| `gitlab_transaction_caught_up_replica_pick_count_total`  | カウンター   | 14.1                                                          | 最新のレプリカに対する検索試行回数                                    | `result`                                                                                                                                 |

## データベースパーティショニングメトリクス {#database-partitioning-metrics}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

次のメトリクスを利用できます。

| メトリック                            | 種類      | 提供開始                                                         | 説明                                                       |
|:--------------------------------- |:--------- |:------------------------------------------------------------- |:----------------------------------------------------------------- |
| `db_partitions_present`           | ゲージ     | [13.4](https://gitlab.com/gitlab-org/gitlab/-/issues/227353)  | 存在するデータベースパーティションの数                             |
| `db_partitions_missing`           | ゲージ     | [13.4](https://gitlab.com/gitlab-org/gitlab/-/issues/227353)  | 現在予期されているが存在していないデータベースパーティションの数 |

## 接続プールメトリクス {#connection-pool-metrics}

これらのメトリクスは、データベースの[接続プール](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html)の状態を記録し、すべてのメトリクスには次のラベルが付いています。

- `class` - 記録対象のRubyクラス。
  - `ActiveRecord::Base`は、メインのデータベース接続。
  - `Geo::TrackingBase`は、Geoトラッキングデータベースへの接続（有効になっている場合）。
- `host` - データベースへの接続に使用するホスト名。
- `port` - データベースへの接続に使用するポート。

| メトリック                                        | 種類  | 提供開始 | 説明                                       |
|:----------------------------------------------|:------|:------|:--------------------------------------------------|
| `gitlab_database_connection_pool_size`        | ゲージ | 13.0  | 接続プールの合計容量                    |
| `gitlab_database_connection_pool_connections` | ゲージ | 13.0  | プール内の現在の接続数                   |
| `gitlab_database_connection_pool_busy`        | ゲージ | 13.0  | オーナーがまだアクティブで使用中の接続数 |
| `gitlab_database_connection_pool_dead`        | ゲージ | 13.0  | オーナーが非アクティブで使用中の接続数   |
| `gitlab_database_connection_pool_idle`        | ゲージ | 13.0  | 未使用の接続数                            |
| `gitlab_database_connection_pool_waiting`     | ゲージ | 13.0  | 現在このキューで待機しているスレッド数           |

## Rubyメトリクス {#ruby-metrics}

いくつかの基本的なRubyランタイムメトリクスを利用できます。

| メトリック                                   | 種類      | 提供開始 | 説明 |
|:---------------------------------------- |:--------- |:----- |:----------- |
| `ruby_gc_duration_seconds`               | カウンター   | 11.1  | RubyがGCで費やした時間 |
| `ruby_gc_stat_...`                       | ゲージ     | 11.1  | [GC.stat](https://ruby-doc.org/core-2.6.5/GC.html#method-c-stat)からのさまざまなメトリクス |
| `ruby_gc_stat_ext_heap_fragmentation`    | ゲージ     | 15.2  | ライブオブジェクトとエデンスロットの比率で表したRubyのヒープ断片化の程度（0 - 1の範囲） |
| `ruby_file_descriptors`                  | ゲージ     | 11.1  | プロセスごとのファイル記述子数 |
| `ruby_sampler_duration_seconds`          | カウンター   | 11.1  | 統計の収集に費やした時間 |
| `ruby_process_cpu_seconds_total`         | ゲージ     | 12.0  | プロセスごとのCPU時間の合計 |
| `ruby_process_max_fds`                   | ゲージ     | 12.0  | プロセスごとのオープンファイル記述子の最大数 |
| `ruby_process_resident_memory_bytes`     | ゲージ     | 12.0  | プロセス別のメモリ使用量（RSS/常駐セットサイズ） |
| `ruby_process_resident_anon_memory_bytes`| ゲージ     | 15.6  | プロセス別の匿名メモリ使用量（RSS/常駐セットサイズ） |
| `ruby_process_resident_file_memory_bytes`| ゲージ     | 15.6  | プロセス別のファイルバックアップメモリ使用量（RSS/常駐セットサイズ） |
| `ruby_process_unique_memory_bytes`       | ゲージ     | 13.0  | プロセス別のメモリ使用量（USS/固有セットサイズ） |
| `ruby_process_proportional_memory_bytes` | ゲージ     | 13.0  | プロセス別のメモリ使用量（PSS/比例セットサイズ） |
| `ruby_process_start_time_seconds`        | ゲージ     | 12.0  | プロセス開始時刻のUNIXタイムスタンプ |

## Pumaメトリクス {#puma-metrics}

| メトリック                            | 種類    | 提供開始 | 説明 |
|:--------------------------------- |:------- |:----- |:----------- |
| `puma_workers`                    | ゲージ   | 12.0  | ワーカーの総数 |
| `puma_running_workers`            | ゲージ   | 12.0  | 起動済みのワーカーの数 |
| `puma_stale_workers`              | ゲージ   | 12.0  | 古いワーカーの数 |
| `puma_running`                    | ゲージ   | 12.0  | 実行中のスレッドの数 |
| `puma_queued_connections`         | ゲージ   | 12.0  | そのワーカーの「to do」セット内で、ワーカースレッドを待機している接続数 |
| `puma_active_connections`         | ゲージ   | 12.0  | リクエストを処理しているスレッドの数 |
| `puma_pool_capacity`              | ゲージ   | 12.0  | そのワーカーが現在処理できるリクエストの数 |
| `puma_max_threads`                | ゲージ   | 12.0  | ワーカースレッドの最大数 |
| `puma_idle_threads`               | ゲージ   | 12.0  | リクエストを処理していない起動済みスレッドの数 |

## Redisメトリクス {#redis-metrics}

これらのクライアントメトリクスは、Redisサーバーメトリクスを補完することを目的としています。各メトリクスは[Redisインスタンス](https://docs.gitlab.com/omnibus/settings/redis.html#running-with-multiple-redis-instances)ごとに分類されています。すべてのメトリクスにRedisインスタンスを示す`storage`ラベルが付けられています。例えば、`cache`や`shared_state`です。

| メトリック                            | 種類    | 提供開始 | 説明 |
|:--------------------------------- |:------- |:----- |:----------- |
| `gitlab_redis_client_exceptions_total`                    | カウンター   | 13.2  | Redisクライアント例外の数（例外クラス別に分類） |
| `gitlab_redis_client_requests_total`                    | カウンター   | 13.2  | Redisクライアントリクエストの数 |
| `gitlab_redis_client_requests_duration_seconds`                    | ヒストグラム   | 13.2  | ブロッキングコマンドを除くRedis要求レイテンシー |
| `gitlab_redis_client_redirections_total` | カウンター | 15.10 | RedisクラスターのMOVED/ASKリダイレクトの数（リダイレクトタイプ別に分類） |
| `gitlab_redis_client_requests_pipelined_commands` | ヒストグラム | 16.4 | 単一のRedisサーバーに送信されたパイプラインあたりのコマンド数 |
| `gitlab_redis_client_pipeline_redirections_count` | ヒストグラム | 17.0 | パイプライン内のRedisクラスターのリダイレクト数 |

## Git LFSメトリクス {#git-lfs-metrics}

さまざまな[Git LFS](https://git-lfs.com/)機能を追跡するメトリクスです。

| メトリック                                             | 種類    | 提供開始 | 説明 |
|:-------------------------------------------------- |:------- |:----- |:----------- |
| `gitlab_sli_lfs_update_objects_total`              | カウンター | 16.10 | LFSオブジェクトの更新の総数 |
| `gitlab_sli_lfs_update_objects_error_total`        | カウンター | 16.10 | LFSオブジェクトの更新エラーの総数 |
| `gitlab_sli_lfs_check_objects_total`               | カウンター | 16.10 | LFSオブジェクトのチェックの総数 |
| `gitlab_sli_lfs_check_objects_error_total`         | カウンター | 16.10 | LFSオブジェクトのチェックエラーの総数 |
| `gitlab_sli_lfs_validate_link_objects_total`       | カウンター | 16.10 | LFSリンクオブジェクトの検証の総数 |
| `gitlab_sli_lfs_validate_link_objects_error_total` | カウンター | 16.10 | LFSリンクオブジェクトの検証エラーの総数 |

## メトリクス共有ディレクトリ {#metrics-shared-directory}

GitLabのPrometheusクライアントは、マルチプロセスサービス間で共有されるメトリクスデータを保存するためのディレクトリを必要とします。これらのファイルは、Pumaサーバーで実行しているすべてのインスタンス間で共有されます。実行中のすべてのPumaのプロセスから、このディレクトリにアクセスできる必要があります。そうでない場合、メトリクスは正しく機能しません。

このディレクトリの場所は、環境変数`prometheus_multiproc_dir`を使用して設定します。最高のパフォーマンスを得るには、このディレクトリを`tmpfs`に作成します。

GitLabを[Linuxパッケージ](https://docs.gitlab.com/omnibus/)を使用してインストールしており、`tmpfs`が利用可能な場合、GitLabがこのメトリクスディレクトリを自動的に設定します。
