---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: プロジェクトとプロジェクト機能を作成、取得、更新、削除、管理するためのREST API。
title: プロジェクトAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、GitLabプロジェクトとそれに関連する設定を管理します。プロジェクトは、コードを保存し、イシューを追跡し、チームのアクティビティを編成できる、コラボレーションの中心的なハブです。詳細については、[プロジェクトを作成する](../user/project/_index.md)を参照してください。

プロジェクトAPIには、次のエンドポイントが含まれています。

- プロジェクトの情報とメタデータを取得する
- プロジェクトを作成、編集、削除する
- プロジェクトの表示レベル、アクセス権限、セキュリティ設定を制御する
- イシュートラッキング、マージリクエスト、CI/CDなどのプロジェクト機能を管理する
- プロジェクトをアーカイブおよびアーカイブ解除する
- ネームスペース間でプロジェクトを転送する
- デプロイとコンテナレジストリの設定を管理する

## 前提条件 {#prerequisites}

- プロジェクトのプロパティを読み取りできる任意の[デフォルトロール](../user/permissions.md#roles)。
- プロジェクトのプロパティを編集するには、プロジェクトのオーナーまたはメンテナーロールが必要です。

## プロジェクトの表示レベル {#project-visibility-level}

GitLabのプロジェクトには、次のいずれかの表示レベルを設定できます。

- 非公開
- 内部
- 公開

表示レベルは、プロジェクトの`visibility`フィールドによって決まります。

詳細については、[プロジェクトの表示レベル](../user/public_access.md)を参照してください。

応答で返されるフィールドは、認証済みユーザーの[権限](../user/permissions.md)によって異なります。

## プロジェクト機能の表示レベル {#project-feature-visibility-level}

プロジェクトを作成または編集する際に、プロジェクト設定の利用可能性を制御できます。例えば、既存のプロジェクトに対して`forking_access_level`を無効にするには、次のようになります:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"forking_access_level": "disabled"}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>"
```

各設定は個別に定義でき、以下の値を受け入れます:

- `disabled`: 機能を無効にします。
- `private`: 機能を有効にして、**プロジェクトメンバーのみ**に設定します。
- `enabled`: 機能を有効にして、**アクセスできる人すべて**に設定します。
- `public`: 機能を有効にして、**全員**に設定します。`pages_access_level`のみ利用可能です。

詳細については、[プロジェクト内の個々の機能の表示レベルを変更](../user/public_access.md#change-the-visibility-of-individual-features-in-a-project)を参照してください。

| 属性                              | 型   | 必須 | 説明 |
|:---------------------------------------|:-------|:---------|:------------|
| `analytics_access_level`               | 文字列 | いいえ       | [分析](../user/analytics/_index.md)の表示レベルを設定します。 |
| `builds_access_level`                  | 文字列 | いいえ       | [パイプライン](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines)の表示レベルを設定します。 |
| `container_registry_access_level`      | 文字列 | いいえ       | [コンテナレジストリ](../user/packages/container_registry/_index.md#change-visibility-of-the-container-registry)の表示レベルを設定します。 |
| `environments_access_level`            | 文字列 | いいえ       | [環境](../ci/environments/_index.md)の表示レベルを設定します。 |
| `feature_flags_access_level`           | 文字列 | いいえ       | [機能フラグ](../operations/feature_flags.md)の表示レベルを設定します。 |
| `forking_access_level`                 | 文字列 | いいえ       | [フォーク](../user/project/repository/forking_workflow.md)の表示レベルを設定します。 |
| `infrastructure_access_level`          | 文字列 | いいえ       | [インフラストラクチャ管理](../user/infrastructure/_index.md)の表示レベルを設定します。 |
| `issues_access_level`                  | 文字列 | いいえ       | [イシュー](../user/project/issues/_index.md)の表示レベルを設定します。 |
| `merge_requests_access_level`          | 文字列 | いいえ       | [マージリクエスト](../user/project/merge_requests/_index.md)の表示レベルを設定します。 |
| `model_experiments_access_level`       | 文字列 | いいえ       | [機械学習モデル実験](../user/project/ml/experiment_tracking/_index.md)の表示レベルを設定します。 |
| `model_registry_access_level`          | 文字列 | いいえ       | [機械学習モデルレジストリ](../user/project/ml/model_registry/_index.md#access-the-model-registry)の表示レベルを設定します。 |
| `monitor_access_level`                 | 文字列 | いいえ       | [アプリケーションパフォーマンスモニタリング](../operations/_index.md)の表示レベルを設定します。 |
| `pages_access_level`                   | 文字列 | いいえ       | [GitLab Pages](../user/project/pages/pages_access_control.md)の表示レベルを設定します。 |
| `releases_access_level`                | 文字列 | いいえ       | [リリース](../user/project/releases/_index.md)の表示レベルを設定します。 |
| `repository_access_level`              | 文字列 | いいえ       | [リポジトリ](../user/project/repository/_index.md)の表示レベルを設定します。 |
| `requirements_access_level`            | 文字列 | いいえ       | [要件管理](../user/project/requirements/_index.md)の表示レベルを設定します。 |
| `security_and_compliance_access_level` | 文字列 | いいえ       | [セキュリティとコンプライアンス](../user/application_security/_index.md)の表示レベルを設定します。 |
| `snippets_access_level`                | 文字列 | いいえ       | [スニペット](../user/snippets.md#change-default-visibility-of-snippets)の表示レベルを設定します。 |
| `wiki_access_level`                    | 文字列 | いいえ       | [Wiki](../user/project/wiki/_index.md#enable-or-disable-a-project-wiki)の表示レベルを設定します。 |

## 非推奨の属性 {#deprecated-attributes}

以下の属性は非推奨であり、REST APIの将来のバージョンで削除される可能性があります。代わりに代替属性を使用してください。

| 非推奨の属性     | 代替 |
|:-------------------------|:------------|
| `tag_list`               | 代わりに`topics`を使用してください。 |
| `marked_for_deletion_at` | 代わりに`marked_for_deletion_on`を使用してください。PremiumおよびUltimateのみです。 |
| `approvals_before_merge` | GitLab 16.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/work_items/353097)になりました。代わりに[マージリクエストの承認API](merge_request_approvals.md)を使用してください。PremiumおよびUltimateのみです。 |
| `packages_enabled` | GitLab 17.10で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/work_items/454759)になりました。代わりに`package_registry_access_level`を使用してください。 |
| `container_registry_enabled` | 代わりに`container_registry_access_level`を使用してください。 |
| `public_builds` | 代わりに`public_jobs`を使用してください。 |
| `emails_disabled` | 代わりに`emails_enabled`を使用してください。 |
| `issues_enabled` | 代わりに`issues_access_level`を使用してください。 |
| `jobs_enabled` | 代わりに`builds_access_level`を使用してください。 |
| `merge_requests_enabled` | 代わりに`merge_request_access_level`を使用してください。 |
| `snippets_enabled` | 代わりに`snippets_access_level`を使用してください。 |
| `wiki_enabled` | 代わりに`wiki_access_level`を使用してください。 |
| `restrict_user_defined_variables` | GitLab 17.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154510)になりました。代わりに`ci_pipeline_variables_minimum_override_role`を使用してください。 |

## プロジェクトを取得する {#retrieve-a-project}

指定されたプロジェクトを取得します。プロジェクトが公開されている場合、このエンドポイントには認証なしでアクセスできます。

```plaintext
GET /projects/:id
```

サポートされている属性:

| 属性                | 型              | 必須 | 説明 |
|:-------------------------|:------------------|:---------|:------------|
| `id`                     | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `license`                | ブール値           | いいえ       | プロジェクトのライセンスデータを含めます。 |
| `statistics`             | ブール値           | いいえ       | プロジェクトの統計を含めます。レポーター、デベロッパー、メンテナー、またはオーナーロールを持つユーザーのみ利用可能です。 |
| `with_custom_attributes` | ブール値           | いいえ       | レスポンスに[カスタム属性](custom_attributes.md)を含めます。管理者アクセス権が必要です。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                | 型              | 説明 |
|:-------------------------|:------------------|:------------|
| `id` | 整数 | プロジェクトのID。 |
| `description` | 文字列 | プロジェクトの説明。 |
| `description_html` | 文字列 | HTML形式のプロジェクトの説明。 |
| `name` | 文字列 | プロジェクトの名前。 |
| `name_with_namespace` | 文字列 | プロジェクトの名前とそのネームスペース。 |
| `path` | 文字列 | プロジェクトのパス。 |
| `path_with_namespace` | 文字列 | プロジェクトのパスとそのネームスペース。 |
| `created_at` | 日時 | プロジェクトが作成されたタイムスタンプ。 |
| `default_branch` | 文字列 | プロジェクトのデフォルトブランチ。 |
| `tag_list` | 文字列の配列 | 非推奨。代わりに`topics`を使用してください。プロジェクトのタグのリスト。 |
| `topics` | 文字列の配列 | プロジェクトのトピックのリスト。 |
| `ssh_url_to_repo` | 文字列 | リポジトリをクローンするためのSSH URL。 |
| `http_url_to_repo` | 文字列 | リポジトリをクローンするためのHTTP URL。 |
| `web_url` | 文字列 | ブラウザでプロジェクトにアクセスするためのURL。 |
| `readme_url` | 文字列 | プロジェクトのReadmeファイルへのURL。 |
| `forks_count` | 整数 | プロジェクトのフォーク数。 |
| `avatar_url` | 文字列 | プロジェクトのアバター画像へのURL。 |
| `star_count` | 整数 | プロジェクトが受け取ったスターの数。 |
| `last_activity_at` | 日時 | プロジェクトでの最終アクティビティのタイムスタンプ。 |
| `visibility` | 文字列 | プロジェクトの表示レベル。指定可能な値: `private`、`internal`、または`public`。 |
| `namespace` | オブジェクト | プロジェクトのネームスペース情報。 |
| `namespace.id` | 整数 | ネームスペースのID。 |
| `namespace.name` | 文字列 | ネームスペースの名前。 |
| `namespace.path` | 文字列 | ネームスペースのパス。 |
| `namespace.kind` | 文字列 | ネームスペースのタイプ。指定可能な値: `user`または`group`。 |
| `namespace.full_path` | 文字列 | ネームスペースのフルパス。 |
| `namespace.parent_id` | 整数 | 該当する場合、親ネームスペースのID。 |
| `namespace.avatar_url` | 文字列 | ネームスペースのアバター画像へのURL。 |
| `namespace.web_url` | 文字列 | ブラウザでネームスペースにアクセスするためのURL。 |
| `container_registry_image_prefix` | 文字列 | コンテナイメージのレジストリ用のプレフィックス。 |
| `_links` | オブジェクト | プロジェクトに関連するAPIエンドポイントリンクのコレクション。 |
| `_links.self` | 文字列 | プロジェクトリソースへのURL。 |
| `_links.issues` | 文字列 | プロジェクトのイシューへのURL。 |
| `_links.merge_requests` | 文字列 | プロジェクトのマージリクエストへのURL。 |
| `_links.repo_branches` | 文字列 | プロジェクトのリポジトリのブランチへのURL。 |
| `_links.labels` | 文字列 | プロジェクトのラベルへのURL。 |
| `_links.events` | 文字列 | プロジェクトのイベントへのURL。 |
| `_links.members` | 文字列 | プロジェクトのメンバーへのURL。 |
| `_links.cluster_agents` | 文字列 | プロジェクトのクラスターエージェントへのURL。 |
| `marked_for_deletion_at` | 日付 | 非推奨。代わりに`marked_for_deletion_on`を使用してください。プロジェクトが削除予定である日付。 |
| `marked_for_deletion_on` | 日付 | プロジェクトが削除予定である日付。 |
| `packages_enabled` | ブール値 | プロジェクトに対してパッケージレジストリが有効になっているかどうか。 |
| `empty_repo` | ブール値 | リポジトリが空であるかどうか。 |
| `archived` | ブール値 | プロジェクトがアーカイブされているかどうか。 |
| `owner` | オブジェクト | プロジェクトオーナーに関する情報。 |
| `owner.id` | 整数 | プロジェクトオーナーのID。 |
| `owner.username` | 文字列 | オーナーのユーザー名。 |
| `owner.public_email` | 文字列 | オーナーの公開メールアドレス。 |
| `owner.name` | 文字列 | プロジェクトオーナーの名前。 |
| `owner.state` | 文字列 | オーナーアカウントの現在のステータス。 |
| `owner.locked` | ブール値 | オーナーアカウントがロックされているかどうかを示します。 |
| `owner.avatar_url` | 文字列 | オーナーのアバター画像へのURL。 |
| `owner.web_url` | 文字列 | オーナーのプロファイル用Web URL。 |
| `owner.created_at` | 日時 | オーナーが作成されたタイムスタンプ。 |
| `resolve_outdated_diff_discussions` | ブール値 | 最新ではない差分ディスカッションが自動的に解決されるかどうか。 |
| `container_expiration_policy` | オブジェクト | コンテナイメージのポリシーの有効期限に関する設定。 |
| `container_expiration_policy.cadence` | 文字列 | コンテナポリシーの有効期限が実行される頻度。 |
| `container_expiration_policy.enabled` | ブール値 | コンテナポリシーの有効期限が有効になっているかどうか。 |
| `container_expiration_policy.keep_n` | 整数 | 保持するコンテナイメージの数。 |
| `container_expiration_policy.older_than` | 文字列 | この値より古いコンテナイメージを削除します。 |
| `container_expiration_policy.name_regex` | 文字列 | 非推奨。代わりに`name_regex_delete`を使用してください。コンテナイメージ名に一致する正規表現。 |
| `container_expiration_policy.name_regex_delete` | 文字列 | 削除するコンテナイメージ名に一致する正規表現。 |
| `container_expiration_policy.name_regex_keep` | 文字列 | 保持するコンテナイメージ名に一致する正規表現。 |
| `container_expiration_policy.next_run_at` | 日時 | 次回のポリシー実行予定のタイムスタンプ。 |
| `repository_object_format` | 文字列 | リポジトリで使用されるオブジェクト形式。指定可能な値: `sha1`または`sha256`。 |
| `issues_enabled` | ブール値 | プロジェクトに対してイシューが有効になっているかどうか。 |
| `merge_requests_enabled` | ブール値 | プロジェクトに対してマージリクエストが有効になっているかどうか。 |
| `wiki_enabled` | ブール値 | プロジェクトに対してWikiが有効になっているかどうか。 |
| `jobs_enabled` | ブール値 | プロジェクトに対してジョブが有効になっているかどうか。 |
| `snippets_enabled` | ブール値 | プロジェクトに対してスニペットが有効になっているかどうか。 |
| `container_registry_enabled` | ブール値 | 非推奨。代わりに`container_registry_access_level`を使用してください。コンテナレジストリが有効になっているかどうか。 |
| `service_desk_enabled` | ブール値 | プロジェクトに対してサービスデスクが有効になっているかどうか。 |
| `service_desk_address` | 文字列 | サービスデスクのメールアドレス。 |
| `can_create_merge_request_in` | ブール値 | 現在のユーザーがプロジェクトでマージリクエストを作成できるかどうか。 |
| `issues_access_level` | 文字列 | イシュー機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `repository_access_level` | 文字列 | リポジトリ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `merge_requests_access_level` | 文字列 | マージリクエスト機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `forking_access_level` | 文字列 | プロジェクトをフォークするためのアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `wiki_access_level` | 文字列 | Wiki機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `builds_access_level` | 文字列 | CI/CDのビルド機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `snippets_access_level` | 文字列 | スニペット機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `pages_access_level` | 文字列 | GitLab Pagesのアクセスレベル。指定可能な値: `disabled`、`private`、`enabled`、または`public`。 |
| `analytics_access_level` | 文字列 | アナリティクス機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `container_registry_access_level` | 文字列 | コンテナレジストリのアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `security_and_compliance_access_level` | 文字列 | セキュリティとコンプライアンス機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `releases_access_level` | 文字列 | リリース機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `environments_access_level` | 文字列 | 環境機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `feature_flags_access_level` | 文字列 | 機能フラグ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `infrastructure_access_level` | 文字列 | インフラストラクチャ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `monitor_access_level` | 文字列 | モニター機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `model_experiments_access_level` | 文字列 | モデル実験機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `model_registry_access_level` | 文字列 | モデルレジストリ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `package_registry_access_level` | 文字列 | パッケージレジストリ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `emails_disabled` | ブール値 | プロジェクトのメールが無効になっているかどうかを示します。 |
| `emails_enabled` | ブール値 | プロジェクトのメールが有効になっているかどうかを示します。 |
| `show_diff_preview_in_email` | ブール値 | メール通知に差分プレビューが表示されるかどうかを示します。 |
| `shared_runners_enabled` | ブール値 | プロジェクトに対して共有Runnerが有効になっているかどうか。 |
| `lfs_enabled` | ブール値 | プロジェクトに対してGit LFSが有効になっているかどうかを示します。 |
| `creator_id` | 整数 | プロジェクトを作成したユーザーのID。 |
| `import_url` | 文字列 | プロジェクトがインポートされたURL。 |
| `import_type` | 文字列 | プロジェクトに利用されたインポートのタイプ。 |
| `import_status` | 文字列 | プロジェクトインポートのステータス。 |
| `import_error` | 文字列 | インポートが失敗した場合のエラーメッセージ。 |
| `open_issues_count` | 整数 | 未解決のイシューの数。 |
| `updated_at` | 日時 | プロジェクトが最後に更新されたタイムスタンプ。 |
| `ci_default_git_depth` | 整数 | CI/CDパイプラインのデフォルトGit深度。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_delete_pipelines_in_seconds` | 整数 | 古いパイプラインが削除されるまでの秒数。 |
| `ci_forward_deployment_enabled` | ブール値 | 前方デプロイが有効になっているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_forward_deployment_rollback_allowed` | ブール値 | 前方デプロイに対してロールバックが許可されているかどうか。 |
| `ci_job_token_scope_enabled` | ブール値 | CI/CDジョブトークンスコープが有効になっているかどうかを示します。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_separated_caches` | ブール値 | ブランチによってCI/CDキャッシュが分離されているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | ブール値 | フォークパイプラインが親プロジェクトで実行できるかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_id_token_sub_claim_components` | 文字列の配列 | CI/CDIDトークンのサブジェクトクレームに含まれるコンポーネント。 |
| `build_git_strategy` | 文字列 | CI/CDビルドに利用されるGitストラテジー（フェッチまたはクローン）。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `keep_latest_artifact` | ブール値 | 新しいアーティファクトが作成されたときに最新のアーティファクトが保持されるかどうかを示します。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `restrict_user_defined_variables` | ブール値 | ユーザー定義の変数が制限されているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_pipeline_variables_minimum_override_role` | 文字列 | パイプライン変数をオーバーライドするために必要な最小ロール。 |
| `runner_token_expiration_interval` | 整数 | Runnerトークンの有効期限（秒）。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `group_runners_enabled` | ブール値 | プロジェクトに対してグループRunnerが有効になっているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `resource_group_default_process_mode` | 文字列 | リソースグループのデフォルト処理モード。 |
| `auto_cancel_pending_pipelines` | 文字列 | 保留中のパイプラインを自動的にキャンセルする設定。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `build_timeout` | 整数 | CI/CDジョブのタイムアウト（秒）。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `auto_devops_enabled` | ブール値 | プロジェクトに対してAuto DevOpsが有効になっているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `auto_devops_deploy_strategy` | 文字列 | Auto DevOpsのデプロイストラテジー。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_push_repository_for_job_token_allowed` | ブール値 | ジョブトークンを使用してリポジトリへのプッシュが許可されているかどうか。 |
| `runners_token` | 文字列 | プロジェクトにRunnerを登録するためのトークン。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_config_path` | 文字列 | CI/CD設定ファイルへのパス。 |
| `public_jobs` | ブール値 | ジョブログが公開アクセス可能かどうか。 |
| `shared_with_groups` | オブジェクトの配列 | プロジェクトが共有されているグループのリスト。 |
| `shared_with_groups[].group_id` | 整数 | プロジェクトが共有されているグループのID。 |
| `shared_with_groups[].group_name` | 文字列 | プロジェクトが共有されているグループの名前。 |
| `shared_with_groups[].group_full_path` | 文字列 | プロジェクトが共有されているグループのフルパス。 |
| `shared_with_groups[].group_access_level` | 整数 | グループに付与されたアクセスレベル。 |
| `only_allow_merge_if_pipeline_succeeds` | ブール値 | パイプラインが成功した場合にのみマージが許可されるかどうか。 |
| `allow_merge_on_skipped_pipeline` | ブール値 | パイプラインがスキップされた場合にマージが許可されるかどうか。 |
| `request_access_enabled` | ブール値 | ユーザーがプロジェクトへのアクセスをリクエストできるかどうか。 |
| `only_allow_merge_if_all_discussions_are_resolved` | ブール値 | すべてのディスカッションが解決された場合にのみマージが許可されるかどうか。 |
| `remove_source_branch_after_merge` | ブール値 | マージ後にソースブランチが自動的に削除されるかどうか。 |
| `printing_merge_request_link_enabled` | ブール値 | プッシュ後にマージリクエストリンクが印刷されるかどうかを示します。 |
| `printing_merge_requests_link_enabled` | ブール値 | プッシュ後にマージリクエストリンクが印刷されるかどうか。 |
| `merge_method` | 文字列 | プロジェクトに利用されるマージメソッド。指定可能な値: `merge`、`rebase_merge`、または`ff`。 |
| `merge_request_title_regex` | 文字列 | マージリクエストタイトルの検証用正規表現パターン。 |
| `merge_request_title_regex_description` | 文字列 | マージリクエストタイトルの正規表現検証の説明。 |
| `squash_option` | 文字列 | マージリクエストのスカッシュオプション。 |
| `enforce_auth_checks_on_uploads` | ブール値 | アップロードに対する認証チェックが強制されるかどうか。 |
| `suggestion_commit_message` | 文字列 | 提案用のカスタムコミットメッセージ。 |
| `merge_commit_template` | 文字列 | マージコミットメッセージのテンプレート。 |
| `squash_commit_template` | 文字列 | スカッシュコミットメッセージのテンプレート。 |
| `issue_branch_template` | 文字列 | イシューから作成されたブランチ名のテンプレート。 |
| `warn_about_potentially_unwanted_characters` | ブール値 | 不要な可能性のある文字の使用について警告するかどうか。 |
| `autoclose_referenced_issues` | ブール値 | 参照されているイシューが自動的にクローズされるかどうか。 |
| `max_artifacts_size` | 整数 | CI/CDアーティファクトの最大サイズ（MB）。 |
| `approvals_before_merge` | 整数 | 非推奨。代わりにマージリクエスト承認APIを使用してください。マージ前に必要な承認の数。 |
| `mirror` | ブール値 | プロジェクトがミラーであるかどうか。 |
| `external_authorization_classification_label` | 文字列 | 外部認可分類ラベル。 |
| `requirements_enabled` | ブール値 | 要件管理が有効になっているかどうかを示します。 |
| `requirements_access_level` | 文字列 | 要件機能のアクセスレベル。 |
| `security_and_compliance_enabled` | ブール値 | セキュリティとコンプライアンス機能が有効になっているかどうかを示します。 |
| `secret_push_protection_enabled` | ブール値 | シークレットプッシュ保護が有効になっているかどうか。 |
| `pre_receive_secret_detection_enabled` | ブール値 | プリレシーブシークレット検出が有効になっているかどうかを示します。 |
| `compliance_frameworks` | 文字列の配列 | プロジェクトに適用されるコンプライアンスフレームワーク。 |
| `issues_template` | 文字列 | イシューのデフォルトの説明。説明は、GitLab Flavored Markdownを使用して解析されます。PremiumおよびUltimateのみです。 |
| `merge_requests_template` | 文字列 | マージリクエストの説明のテンプレート。PremiumおよびUltimateのみです。 |
| `ci_restrict_pipeline_cancellation_role` | 文字列 | パイプラインをキャンセルするために必要な最小ロール。 |
| `merge_pipelines_enabled` | ブール値 | マージパイプラインが有効になっているかどうかを示します。 |
| `merge_trains_enabled` | ブール値 | マージトレインが有効になっているかどうかを示します。 |
| `merge_trains_skip_train_allowed` | ブール値 | マージトレインのスキップが許可されているかどうかを示します。 |
| `only_allow_merge_if_all_status_checks_passed` | ブール値 | すべてのステータスチェックが合格した場合にのみマージが許可されるかどうか。Ultimateのみです。 |
| `allow_pipeline_trigger_approve_deployment` | ブール値 | パイプライントリガーがデプロイを承認できるかどうか。 |
| `prevent_merge_without_jira_issue` | ブール値 | マージに連携されたJiraイシューが必要かどうかを示します。 |
| `duo_remote_flows_enabled` | ブール値 | GitLab Duoリモートフローが有効になっているかどうかを示します。 |
| `duo_foundational_flows_enabled` | ブール値 | GitLab Duo基本フローが有効になっているかどうかを示します。 |
| `duo_sast_fp_detection_enabled` | ブール値 | GitLab DuoSAST誤検出判定が有効になっているかどうかを示します。 |
| `web_based_commit_signing_enabled` | ブール値 | Webベースのコミット署名が有効になっているかどうかを示します。 |
| `spp_repository_pipeline_access` | ブール値 | セキュリティポリシーのリポジトリパイプラインアクセス。セキュリティオーケストレーションポリシー機能が利用可能な場合にのみ表示されます。 |
| `permissions` | オブジェクト | プロジェクトのユーザー権限。 |
| `permissions.project_access` | オブジェクト | ユーザーのプロジェクトアクセスユーザー権限。 |
| `permissions.project_access.access_level` | 整数 | プロジェクトのアクセスレベル。 |
| `permissions.project_access.notification_level` | 整数 | プロジェクトの通知レベル。 |
| `permissions.group_access` | オブジェクト | ユーザーのグループアクセスユーザー権限。 |
| `permissions.group_access.access_level` | 整数 | グループのアクセスレベル。 |
| `permissions.group_access.notification_level` | 整数 | グループの通知レベル。 |
| `license_url` | 文字列 | プロジェクトのライセンスファイルへのURL。 |
| `license.key` | 文字列 | ライセンスのキー識別子。 |
| `license.name` | 文字列 | ライセンスのフルネーム。 |
| `license.nickname` | 文字列 | ライセンスのニックネーム。 |
| `license.html_url` | 文字列 | ライセンスの詳細を表示するためのURL。 |
| `license.source_url` | 文字列 | ライセンスソーステキストへのURL。 |
| `repository_storage` | 文字列 | プロジェクトのリポジトリのストレージロケーション。 |
| `mirror_user_id` | 整数 | ミラーを設定したユーザーのID。 |
| `mirror_trigger_builds` | ブール値 | ミラーの更新がビルドをトリガーするかどうか。 |
| `only_mirror_protected_branches` | ブール値 | 保護された保護ブランチのみがミラーされるかどうか。 |
| `mirror_overwrites_diverged_branches` | ブール値 | ミラーが分岐したブランチを上書きするかどうか。 |
| `statistics.commit_count` | 整数 | プロジェクトのコミット数。 |
| `statistics.storage_size` | 整数 | 合計ストレージサイズ（バイト）。 |
| `statistics.repository_size` | 整数 | リポジトリストレージサイズ（バイト）。 |
| `statistics.wiki_size` | 整数 | Wikiストレージサイズ（バイト）。 |
| `statistics.lfs_objects_size` | 整数 | LFSオブジェクトストレージサイズ（バイト）。 |
| `statistics.job_artifacts_size` | 整数 | ジョブアーティファクトストレージサイズ（バイト）。 |
| `statistics.pipeline_artifacts_size` | 整数 | パイプラインアーティファクトストレージサイズ（バイト）。 |
| `statistics.packages_size` | 整数 | パッケージストレージサイズ（バイト）。 |
| `statistics.snippets_size` | 整数 | スニペットストレージサイズ（バイト）。 |
| `statistics.uploads_size` | 整数 | アップロードストレージサイズ（バイト）。 |
| `statistics.container_registry_size` | 整数 | コンテナレジストリストレージサイズ（バイト）。<sup>1</sup> |
| `forked_from_project` | オブジェクト | このプロジェクトがフォークしたアップストリームプロジェクト。アップストリームプロジェクトがプライベートな場合、このフィールドを表示するには認証トークンが必要です。 |
| `mr_default_target_self` | ブール値 | マージリクエストがデフォルトでこのプロジェクトをターゲットとするかどうか。`false`の場合、マージリクエストはアップストリームプロジェクトをターゲットとします。プロジェクトがフォークである場合にのみ表示されます。 |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>"
```

レスポンス例: 

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "container_expiration_policy": {
    "cadence": "7d",
    "enabled": false,
    "keep_n": null,
    "older_than": null,
    "name_regex": null, // to be deprecated in GitLab 13.0 in favor of `name_regex_delete`
    "name_regex_delete": null,
    "name_regex_keep": null,
    "next_run_at": "2020-01-07T21:42:58.658Z"
  },
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora",
    "avatar_url": "http://localhost:3000/uploads/group/avatar/3/foo.jpg",
    "web_url": "http://localhost:3000/groups/diaspora"
  },
  "import_url": null,
  "import_type": null,
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": false,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "ci_display_pipeline_variables": false,
  "protect_merge_request_pipelines": true,
  "public_jobs": true,
  "shared_with_groups": [
    {
      "group_id": 4,
      "group_name": "Twitter",
      "group_full_path": "twitter",
      "group_access_level": 30
    },
    {
      "group_id": 3,
      "group_name": "Gitlab Org",
      "group_full_path": "gitlab-org",
      "group_access_level": 10
    }
  ],
  "repository_storage": "default",
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "allow_pipeline_trigger_approve_deployment": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "printing_merge_requests_link_enabled": true,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "auto_devops_enabled": true,
  "auto_devops_deploy_strategy": "continuous",
  "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
  "mirror": false,
  "mirror_user_id": 45,
  "mirror_trigger_builds": false,
  "only_mirror_protected_branches": false,
  "mirror_overwrites_diverged_branches": false,
  "external_authorization_classification_label": null,
  "packages_enabled": true,
  "empty_repo": false,
  "service_desk_enabled": false,
  "service_desk_address": null,
  "autoclose_referenced_issues": true,
  "suggestion_commit_message": null,
  "enforce_auth_checks_on_uploads": true,
  "merge_commit_template": null,
  "squash_commit_template": null,
  "issue_branch_template": "gitlab/%{id}-%{title}",
  "marked_for_deletion_at": "2020-04-03", // Deprecated in favor of marked_for_deletion_on. Planned for removal in a future version of the REST API.
  "marked_for_deletion_on": "2020-04-03",
  "compliance_frameworks": [ "sox" ],
  "warn_about_potentially_unwanted_characters": true,
  "secret_push_protection_enabled": false,
  "statistics": {
    "commit_count": 37,
    "storage_size": 1038090,
    "repository_size": 1038090,
    "wiki_size" : 0,
    "lfs_objects_size": 0,
    "job_artifacts_size": 0,
    "pipeline_artifacts_size": 0,
    "packages_size": 0,
    "snippets_size": 0,
    "uploads_size": 0,
    "container_registry_size": 0
  },
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  },
  "spp_repository_pipeline_access": false // Only visible if the security_orchestration_policies feature is available
}
```

## プロジェクトのリストを取得する {#list-projects}

プロジェクトとプロジェクト属性をリスト表示。

### すべてのプロジェクトのリストを取得する {#list-all-projects}

{{< history >}}

- `web_based_commit_signing_enabled`は、GitLab 18.2で`use_web_based_commit_signing_enabled`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194650)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag] `web_based_commit_signing_enabled`属性の利用可能性は機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

認証済みユーザーがアクセスできるインスタンス上のすべてのプロジェクトをリスト表示します。未認証のリクエストは、限定された属性のサブセットを持つ公開プロジェクトのみを返します。

[カスタム属性](custom_attributes.md)でレスポンスをフィルタリングできます。

このエンドポイントはページネーションをサポートしています:

- オフセットベースのページネーションを使用して、最大50,000プロジェクトにアクセスします。
- キーセットベースのページネーションを使用して、50,000以上のプロジェクトをリスト表示します。

詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

```plaintext
GET /projects
```

サポートされている属性:

| 属性                     | 型     | 必須 | 説明 |
|:------------------------------|:---------|:---------|:------------|
| `archived`                    | ブール値  | いいえ       | アーカイブ状態で制限します。 |
| `id_after`                    | 整数  | いいえ       | 指定されたIDより大きいIDを持つプロジェクトに結果を制限します。 |
| `id_before`                   | 整数  | いいえ       | 指定されたIDより小さいIDを持つプロジェクトに結果を制限します。 |
| `imported`                    | ブール値  | いいえ       | 現在のユーザーによって外部システムからインポートされたプロジェクトに結果を制限します。 |
| `include_hidden`              | ブール値  | いいえ       | 非表示プロジェクトを含めます。_（管理者のみ）_PremiumおよびUltimateのみ。 |
| `include_pending_delete`      | ブール値  | いいえ       | 削除保留中のプロジェクトを含めます。_（管理者のみ）_ |
| `last_activity_after`         | 日時 | いいえ       | 指定された時刻以降に最後のアクティビティが行われたプロジェクトに結果を制限します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`） |
| `last_activity_before`        | 日時 | いいえ       | 指定された時刻以前に最後のアクティビティが行われたプロジェクトに結果を制限します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`） |
| `membership`                  | ブール値  | いいえ       | 現在のユーザーがメンバーであるプロジェクトで制限します。 |
| `min_access_level`            | 整数  | いいえ       | 現在のユーザーが少なくとも指定されたアクセスレベルを持つプロジェクトに限定します。使用可能な値: `5` （最小アクセス）、`10` （ゲスト）、`15` （プランナー）、`20` （レポーター）、`25` （セキュリティマネージャー）、`30` （デベロッパー）、`40` （メンテナー）、または`50` （オーナー）。 |
| `order_by`                    | 文字列   | いいえ       | `id`、`name`、`path`、`created_at`、`updated_at`、`star_count`、`last_activity_at`、または`similarity`フィールドで並べ替えられたプロジェクトを返します。`repository_size`、`storage_size`、`packages_size`、または`wiki_size`フィールドは、管理者のみが使用できます。`similarity`は検索時にのみ使用可能であり、現在のユーザーがメンバーであるプロジェクトに限定されます。デフォルトは`created_at`です。 |
| `owned`                       | ブール値  | いいえ       | 現在のユーザーが明示的に所有するプロジェクトで制限します。 |
| `repository_checksum_failed`  | ブール値  | いいえ       | リポジトリチェックサムの計算に失敗したプロジェクトを制限します。PremiumおよびUltimateのみです。 |
| `repository_storage`          | 文字列   | いいえ       | `repository_storage`に保存されているプロジェクトに結果を制限します。_（管理者のみ）_ |
| `search_namespaces`           | ブール値  | いいえ       | 検索条件に一致するときに、祖先のネームスペースを含めます。デフォルトは`false`です。 |
| `search`                      | 文字列   | いいえ       | `path`、`name`、または`description`が検索条件（大文字と小文字は区別されない、部分文字列一致）に一致するプロジェクトのリストを返します。複数の用語は、エスケープされたスペース（`+`または`%20`）で区切って指定できます。これらの用語はANDで結合されます。たとえば`one+two`は、部分文字列`one`および`two`（順不同）に一致します。 |
| `simple`                      | ブール値  | いいえ       | `true`の場合、各プロジェクトに対して限定されたフィールドのみを返します。未認証のリクエストは、`simple`が設定されていなくても、限定されたフィールドを持つ公開プロジェクトのみを返します。 |
| `sort`                        | 文字列   | いいえ       | `asc`または`desc`の順にソートされたプロジェクトを返します。デフォルトは`desc`です。 |
| `starred`                     | ブール値  | いいえ       | 現在のユーザーがStar付きに登録したプロジェクトで制限します。 |
| `statistics`                  | ブール値  | いいえ       | プロジェクトの統計を含めます。レポーター、デベロッパー、メンテナー、またはオーナーロールを持つユーザーのみ利用可能です。 |
| `topic_id`                    | 整数  | いいえ       | トピックIDで指定された、割り当てられたトピックを含むプロジェクトに結果を制限します。 |
| `topic`                       | 文字列   | いいえ       | カンマ区切りのトピック名。指定されたすべてのトピックに一致するプロジェクトに結果を制限します。`topics`属性を参照してください。 |
| `updated_after`               | 日時 | いいえ       | 指定された時刻以降に最終更新が行われたプロジェクトに結果を制限します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）。GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393979)されました。このフィルターを機能させるには、`updated_at`を`order_by`属性として指定する必要もあります。 |
| `updated_before`              | 日時 | いいえ       | 指定された時刻以前に最終更新が行われたプロジェクトに結果を制限します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）。GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393979)されました。このフィルターを機能させるには、`updated_at`を`order_by`属性として指定する必要もあります。 |
| `visibility`                  | 文字列   | いいえ       | 表示レベル（`public`、`internal`、`private`）で制限します。 |
| `wiki_checksum_failed`        | ブール値  | いいえ       | Wikiチェックサムの計算に失敗したプロジェクトを制限します。PremiumおよびUltimateのみです。 |
| `with_custom_attributes`      | ブール値  | いいえ       | 応答に[カスタム属性](custom_attributes.md)を含めます。_（管理者のみ）_ |
| `with_issues_enabled`         | ブール値  | いいえ       | 有効になっているイシュー機能で制限します。 |
| `with_merge_requests_enabled` | ブール値  | いいえ       | 有効になっているマージリクエスト機能で制限します。 |
| `with_programming_language`   | 文字列   | いいえ       | 指定されているプログラミング言語を使用するプロジェクトで制限します。 |
| `marked_for_deletion_on`      | 日付     | いいえ       | プロジェクトが削除対象としてマークされた日付でフィルタリングします。GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/463939)されました。PremiumおよびUltimateのみです。 |
| `active`                      | ブール値  | いいえ       | アーカイブされておらず、削除対象としてマークされていないプロジェクトで制限します。 |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `id` | 整数 | プロジェクトのID。 |
| `description` | 文字列 | プロジェクトの説明。 |
| `name` | 文字列 | プロジェクトの名前。 |
| `name_with_namespace` | 文字列 | プロジェクトの名前とそのネームスペース。 |
| `path` | 文字列 | プロジェクトのパス。 |
| `path_with_namespace` | 文字列 | プロジェクトのパスとそのネームスペース。 |
| `created_at` | 日時 | プロジェクトが作成されたタイムスタンプ。 |
| `default_branch` | 文字列 | プロジェクトのデフォルトブランチ。 |
| `tag_list` | 文字列の配列 | 非推奨。代わりに`topics`を使用してください。プロジェクトのタグのリスト。 |
| `topics` | 文字列の配列 | プロジェクトのトピックのリスト。 |
| `ssh_url_to_repo` | 文字列 | リポジトリをクローンするためのSSH URL。 |
| `http_url_to_repo` | 文字列 | リポジトリをクローンするためのHTTP URL。 |
| `web_url` | 文字列 | ブラウザでプロジェクトにアクセスするためのURL。 |
| `readme_url` | 文字列 | プロジェクトのReadmeファイルへのURL。 |
| `forks_count` | 整数 | プロジェクトのフォーク数。 |
| `avatar_url` | 文字列 | プロジェクトのアバター画像へのURL。 |
| `star_count` | 整数 | プロジェクトが受け取ったスターの数。 |
| `last_activity_at` | 日時 | プロジェクトでの最終アクティビティのタイムスタンプ。 |
| `visibility` | 文字列 | プロジェクトの表示レベル。指定可能な値: `private`、`internal`、または`public`。 |
| `namespace` | オブジェクト | プロジェクトのネームスペース情報。 |
| `namespace.id` | 整数 | ネームスペースのID。 |
| `namespace.name` | 文字列 | ネームスペースの名前。 |
| `namespace.path` | 文字列 | ネームスペースのパス。 |
| `namespace.kind` | 文字列 | ネームスペースのタイプ。指定可能な値: `user`または`group`。 |
| `namespace.full_path` | 文字列 | ネームスペースのフルパス。 |
| `namespace.parent_id` | 整数 | 該当する場合、親ネームスペースのID。 |
| `namespace.avatar_url` | 文字列 | ネームスペースのアバター画像へのURL。 |
| `namespace.web_url` | 文字列 | ブラウザでネームスペースにアクセスするためのURL。 |
| `container_registry_image_prefix` | 文字列 | コンテナイメージのレジストリ用のプレフィックス。 |
| `_links` | オブジェクト | プロジェクトに関連するAPIエンドポイントリンクのコレクション。 |
| `_links.self` | 文字列 | プロジェクトリソースへのURL。 |
| `_links.issues` | 文字列 | プロジェクトのイシューへのURL。 |
| `_links.merge_requests` | 文字列 | プロジェクトのマージリクエストへのURL。 |
| `_links.repo_branches` | 文字列 | プロジェクトのリポジトリのブランチへのURL。 |
| `_links.labels` | 文字列 | プロジェクトのラベルへのURL。 |
| `_links.events` | 文字列 | プロジェクトのイベントへのURL。 |
| `_links.members` | 文字列 | プロジェクトのメンバーへのURL。 |
| `_links.cluster_agents` | 文字列 | プロジェクトのクラスターエージェントへのURL。 |
| `marked_for_deletion_at` | 日付 | 非推奨。代わりに`marked_for_deletion_on`を使用してください。プロジェクトが削除予定である日付。 |
| `marked_for_deletion_on` | 日付 | プロジェクトが削除予定である日付。 |
| `packages_enabled` | ブール値 | プロジェクトに対してパッケージレジストリが有効になっているかどうか。 |
| `empty_repo` | ブール値 | リポジトリが空であるかどうか。 |
| `archived` | ブール値 | プロジェクトがアーカイブされているかどうか。 |
| `resolve_outdated_diff_discussions` | ブール値 | 最新ではない差分ディスカッションが自動的に解決されるかどうか。 |
| `container_expiration_policy` | オブジェクト | コンテナイメージのポリシーの有効期限に関する設定。 |
| `container_expiration_policy.cadence` | 文字列 | コンテナポリシーの有効期限が実行される頻度。 |
| `container_expiration_policy.enabled` | ブール値 | コンテナポリシーの有効期限が有効になっているかどうか。 |
| `container_expiration_policy.keep_n` | 整数 | 保持するコンテナイメージの数。 |
| `container_expiration_policy.older_than` | 文字列 | この値より古いコンテナイメージを削除します。 |
| `container_expiration_policy.name_regex` | 文字列 | 非推奨。代わりに`name_regex_delete`を使用してください。コンテナイメージ名に一致する正規表現。 |
| `container_expiration_policy.name_regex_keep` | 文字列 | 保持するコンテナイメージ名に一致する正規表現。 |
| `container_expiration_policy.next_run_at` | 日時 | 次回のポリシー実行予定のタイムスタンプ。 |
| `repository_object_format` | 文字列 | リポジトリで使用されるオブジェクト形式 (sha1またはsha256)。 |
| `issues_enabled` | ブール値 | プロジェクトに対してイシューが有効になっているかどうか。 |
| `merge_requests_enabled` | ブール値 | プロジェクトに対してマージリクエストが有効になっているかどうか。 |
| `wiki_enabled` | ブール値 | プロジェクトに対してWikiが有効になっているかどうか。 |
| `jobs_enabled` | ブール値 | プロジェクトに対してジョブが有効になっているかどうか。 |
| `snippets_enabled` | ブール値 | プロジェクトに対してスニペットが有効になっているかどうか。 |
| `container_registry_enabled` | ブール値 | 非推奨。代わりに`container_registry_access_level`を使用してください。コンテナレジストリが有効になっているかどうか。 |
| `service_desk_enabled` | ブール値 | プロジェクトに対してサービスデスクが有効になっているかどうか。 |
| `can_create_merge_request_in` | ブール値 | 現在のユーザーがプロジェクトでマージリクエストを作成できるかどうか。 |
| `issues_access_level` | 文字列 | イシュー機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `repository_access_level` | 文字列 | リポジトリ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `merge_requests_access_level` | 文字列 | マージリクエスト機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `forking_access_level` | 文字列 | プロジェクトをフォークするためのアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `wiki_access_level` | 文字列 | Wiki機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `builds_access_level` | 文字列 | CI/CDのビルド機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `snippets_access_level` | 文字列 | スニペット機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `pages_access_level` | 文字列 | GitLab Pagesのアクセスレベル。指定可能な値: `disabled`、`private`、`enabled`、または`public`。 |
| `analytics_access_level` | 文字列 | アナリティクス機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `container_registry_access_level` | 文字列 | コンテナレジストリのアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `security_and_compliance_access_level` | 文字列 | セキュリティとコンプライアンス機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `releases_access_level` | 文字列 | リリース機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `environments_access_level` | 文字列 | 環境機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `feature_flags_access_level` | 文字列 | 機能フラグ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `infrastructure_access_level` | 文字列 | インフラストラクチャ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `monitor_access_level` | 文字列 | モニター機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `model_experiments_access_level` | 文字列 | モデル実験機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `model_registry_access_level` | 文字列 | モデルレジストリ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `package_registry_access_level` | 文字列 | パッケージレジストリ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `emails_disabled` | ブール値 | プロジェクトのメールが無効になっているかどうかを示します。 |
| `emails_enabled` | ブール値 | プロジェクトのメールが有効になっているかどうかを示します。 |
| `show_diff_preview_in_email` | ブール値 | メール通知に差分プレビューが表示されるかどうかを示します。 |
| `shared_runners_enabled` | ブール値 | プロジェクトに対して共有Runnerが有効になっているかどうか。 |
| `lfs_enabled` | ブール値 | プロジェクトに対してGit LFSが有効になっているかどうかを示します。 |
| `creator_id` | 整数 | プロジェクトを作成したユーザーのID。 |
| `import_status` | 文字列 | プロジェクトインポートのステータス。 |
| `open_issues_count` | 整数 | 未解決のイシューの数。 |
| `description_html` | 文字列 | HTML形式のプロジェクトの説明。 |
| `updated_at` | 日時 | プロジェクトが最後に更新されたタイムスタンプ。 |
| `ci_config_path` | 文字列 | CI/CD設定ファイルへのパス。 |
| `public_jobs` | ブール値 | ジョブログが公開アクセス可能かどうか。 |
| `shared_with_groups` | オブジェクトの配列 | プロジェクトが共有されているグループのリスト。 |
| `only_allow_merge_if_pipeline_succeeds` | ブール値 | パイプラインが成功した場合にのみマージが許可されるかどうか。 |
| `allow_merge_on_skipped_pipeline` | ブール値 | パイプラインがスキップされた場合にマージが許可されるかどうか。 |
| `request_access_enabled` | ブール値 | ユーザーがプロジェクトへのアクセスをリクエストできるかどうか。 |
| `only_allow_merge_if_all_discussions_are_resolved` | ブール値 | すべてのディスカッションが解決された場合にのみマージが許可されるかどうか。 |
| `remove_source_branch_after_merge` | ブール値 | マージ後にソースブランチが自動的に削除されるかどうか。 |
| `printing_merge_request_link_enabled` | ブール値 | プッシュ後にマージリクエストリンクが印刷されるかどうかを示します。 |
| `merge_method` | 文字列 | プロジェクトに利用されるマージメソッド。指定可能な値: `merge`、`rebase_merge`、または`ff`。 |
| `merge_request_title_regex` | 文字列 | マージリクエストタイトルの検証用正規表現パターン。 |
| `merge_request_title_regex_description` | 文字列 | マージリクエストタイトルの正規表現検証の説明。 |
| `squash_option` | 文字列 | マージリクエストのスカッシュオプション。 |
| `enforce_auth_checks_on_uploads` | ブール値 | アップロードに対する認証チェックが強制されるかどうか。 |
| `suggestion_commit_message` | 文字列 | 提案用のカスタムコミットメッセージ。 |
| `merge_commit_template` | 文字列 | マージコミットメッセージのテンプレート。 |
| `squash_commit_template` | 文字列 | スカッシュコミットメッセージのテンプレート。 |
| `issue_branch_template` | 文字列 | イシューから作成されたブランチ名のテンプレート。 |
| `warn_about_potentially_unwanted_characters` | ブール値 | 不要な可能性のある文字の使用について警告するかどうか。 |
| `autoclose_referenced_issues` | ブール値 | 参照されているイシューが自動的にクローズされるかどうか。 |
| `max_artifacts_size` | 整数 | CI/CDアーティファクトの最大サイズ（MB）。 |
| `approvals_before_merge` | 整数 | 非推奨。代わりにマージリクエスト承認APIを使用してください。マージ前に必要な承認の数。 |
| `mirror` | ブール値 | プロジェクトがミラーであるかどうか。 |
| `external_authorization_classification_label` | 文字列 | 外部認可分類ラベル。 |
| `requirements_enabled` | ブール値 | 要件管理が有効になっているかどうかを示します。 |
| `requirements_access_level` | 文字列 | 要件機能のアクセスレベル。 |
| `security_and_compliance_enabled` | ブール値 | セキュリティとコンプライアンス機能が有効になっているかどうかを示します。 |
| `compliance_frameworks` | 文字列の配列 | プロジェクトに適用されるコンプライアンスフレームワーク。 |
| `issues_template` | 文字列 | イシューのデフォルトの説明。説明は、GitLab Flavored Markdownを使用して解析されます。PremiumおよびUltimateのみです。 |
| `merge_requests_template` | 文字列 | マージリクエストの説明のテンプレート。PremiumおよびUltimateのみです。 |
| `merge_pipelines_enabled` | ブール値 | マージパイプラインが有効になっているかどうかを示します。 |
| `merge_trains_enabled` | ブール値 | マージトレインが有効になっているかどうかを示します。 |
| `merge_trains_skip_train_allowed` | ブール値 | マージトレインのスキップが許可されているかどうかを示します。 |
| `only_allow_merge_if_all_status_checks_passed` | ブール値 | すべてのステータスチェックが合格した場合にのみマージが許可されるかどうか。Ultimateのみです。 |
| `allow_pipeline_trigger_approve_deployment` | ブール値 | パイプライントリガーがデプロイを承認できるかどうか。 |
| `prevent_merge_without_jira_issue` | ブール値 | マージに連携されたJiraイシューが必要かどうかを示します。 |
| `duo_remote_flows_enabled` | ブール値 | GitLab Duoリモートフローが有効になっているかどうかを示します。 |
| `duo_foundational_flows_enabled` | ブール値 | GitLab Duo基本フローが有効になっているかどうかを示します。 |
| `duo_sast_fp_detection_enabled` | ブール値 | GitLab DuoSAST誤検出判定が有効になっているかどうかを示します。 |
| `spp_repository_pipeline_access` | ブール値 | セキュリティポリシーのリポジトリパイプラインアクセス。セキュリティオーケストレーションポリシー機能が利用可能な場合にのみ表示されます。 |
| `permissions` | オブジェクト | プロジェクトのユーザー権限。 |
| `permissions.project_access` | オブジェクト | ユーザーのプロジェクトアクセス権限。 |
| `permissions.group_access` | オブジェクト | ユーザーのグループアクセス権限。 |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/projects
```

レスポンス例: 

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "default_branch": "main",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "ssh_url_to_repo": "git@gitlab.example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "https://gitlab.example.com/diaspora/diaspora-client.git",
    "web_url": "https://gitlab.example.com/diaspora/diaspora-client",
    "readme_url": "https://gitlab.example.com/diaspora/diaspora-client/blob/main/README.md",
    "avatar_url": "https://gitlab.example.com/uploads/project/avatar/4/uploads/avatar.png",
    "forks_count": 0,
    "star_count": 0,
    "last_activity_at": "2022-06-24T17:11:26.841Z",
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora",
      "parent_id": null,
      "avatar_url": "https://gitlab.example.com/uploads/project/avatar/6/uploads/avatar.png",
      "web_url": "https://gitlab.example.com/diaspora"
    },
    "container_registry_image_prefix": "registry.gitlab.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "https://gitlab.example.com/api/v4/projects/4",
      "issues": "https://gitlab.example.com/api/v4/projects/4/issues",
      "merge_requests": "https://gitlab.example.com/api/v4/projects/4/merge_requests",
      "repo_branches": "https://gitlab.example.com/api/v4/projects/4/repository/branches",
      "labels": "https://gitlab.example.com/api/v4/projects/4/labels",
      "events": "https://gitlab.example.com/api/v4/projects/4/events",
      "members": "https://gitlab.example.com/api/v4/projects/4/members",
      "cluster_agents": "https://gitlab.example.com/api/v4/projects/4/cluster_agents"
    },
    "packages_enabled": true, // deprecated, use package_registry_access_level instead
    "package_registry_access_level": "enabled",
    "empty_repo": false,
    "archived": false,
    "visibility": "public",
    "resolve_outdated_diff_discussions": false,
    "container_expiration_policy": {
      "cadence": "1month",
      "enabled": true,
      "keep_n": 1,
      "older_than": "14d",
      "name_regex": "",
      "name_regex_keep": ".*-main",
      "next_run_at": "2022-06-25T17:11:26.865Z"
    },
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": true,
    "jobs_enabled": true,
    "snippets_enabled": true,
    "container_registry_enabled": true,
    "service_desk_enabled": true,
    "can_create_merge_request_in": true,
    "issues_access_level": "enabled",
    "repository_access_level": "enabled",
    "merge_requests_access_level": "enabled",
    "forking_access_level": "enabled",
    "wiki_access_level": "enabled",
    "builds_access_level": "enabled",
    "snippets_access_level": "enabled",
    "pages_access_level": "enabled",
    "analytics_access_level": "enabled",
    "container_registry_access_level": "enabled",
    "security_and_compliance_access_level": "private",
    "emails_disabled": null,
    "emails_enabled": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "lfs_enabled": true,
    "creator_id": 1,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "open_issues_count": 0,
    "ci_default_git_depth": 20,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
    "ci_job_token_scope_enabled": false,
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "ci_display_pipeline_variables": false,
    "protect_merge_request_pipelines": true,
    "public_jobs": true,
    "build_timeout": 3600,
    "auto_cancel_pending_pipelines": "enabled",
    "ci_config_path": "",
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": null,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "request_access_enabled": true,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": true,
    "printing_merge_request_link_enabled": true,
    "merge_method": "merge",
    "squash_option": "default_off",
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "auto_devops_enabled": false,
    "auto_devops_deploy_strategy": "continuous",
    "autoclose_referenced_issues": true,
    "keep_latest_artifact": true,
    "runner_token_expiration_interval": null,
    "external_authorization_classification_label": "",
    "requirements_enabled": false,
    "requirements_access_level": "enabled",
    "security_and_compliance_enabled": false,
    "secret_push_protection_enabled": false,
    "compliance_frameworks": [],
    "warn_about_potentially_unwanted_characters": true,
    "permissions": {
      "project_access": null,
      "group_access": null
    }
  },
  {
    ...
  }
]
```

> [!note] 
> `last_activity_at`は[プロジェクトアクティビティ](../user/project/working_with_projects.md#view-project-activity)と[プロジェクトイベント](events.md)に基づいて更新されます。データベースパフォーマンスを最適化するため、このフィールドは1時間に1回のみ更新されます。最後の更新から1時間以内に発生したイベントは、タイムスタンプを変更しません。結果として、`last_activity_at`は最大1時間最新ではない可能性があります。`updated_at`は、プロジェクトレコードがデータベースで変更されるたびに更新されます。

### ユーザーの全個人プロジェクトを一覧表示する {#list-all-personal-projects-for-a-user}

指定されたユーザーの全個人プロジェクトを一覧表示します。次の制限が適用されます。

- ユーザーの個人ネームスペース内のプロジェクトのみを返します。グループまたはサブグループプロジェクトは返しません。
- ユーザープロファイルがプライベートの場合、空のリストが返されます。
- 認証なしのリクエストは、公開プロジェクトのみを返します。

このエンドポイントはページネーションをサポートしています:

- オフセットベースのページネーションを使用して、最大50,000プロジェクトにアクセスします。
- キーセットベースのページネーションを使用して、50,000以上のプロジェクトをリスト表示します。

詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

```plaintext
GET /users/:user_id/projects
```

サポートされている属性:

| 属性                     | 型     | 必須 | 説明 |
|:------------------------------|:---------|:---------|:------------|
| `user_id`                     | 文字列   | はい      | ユーザーのIDまたはユーザー名。 |
| `archived`                    | ブール値  | いいえ       | アーカイブ状態で制限します。 |
| `id_after`                    | 整数  | いいえ       | 指定されたIDより大きいIDを持つプロジェクトに結果を制限します。 |
| `id_before`                   | 整数  | いいえ       | 指定されたIDより小さいIDを持つプロジェクトに結果を制限します。 |
| `membership`                  | ブール値  | いいえ       | 現在のユーザーがメンバーであるプロジェクトで制限します。 |
| `min_access_level`            | 整数  | いいえ       | 現在のユーザーが少なくとも指定されたアクセスレベルを持つプロジェクトに限定します。使用可能な値: `5` （最小アクセス）、`10` （ゲスト）、`15` （プランナー）、`20` （レポーター）、`25` （セキュリティマネージャー）、`30` （デベロッパー）、`40` （メンテナー）、または`50` （オーナー）。 |
| `order_by`                    | 文字列   | いいえ       | `id`、`name`、`path`、`created_at`、`updated_at`、`star_count`、または`last_activity_at`のフィールドで並べ替えられたプロジェクトを返します。デフォルトは`created_at`です。 |
| `owned`                       | ブール値  | いいえ       | 現在のユーザーが明示的に所有するプロジェクトで制限します。 |
| `search`                      | 文字列   | いいえ       | 検索条件に一致するプロジェクトのリストを返します。 |
| `simple`                      | ブール値  | いいえ       | `true`の場合、各プロジェクトに対して限定されたフィールドのみを返します。未認証のリクエストは、`simple`が設定されていなくても、限定されたフィールドを持つ公開プロジェクトのみを返します。 |
| `sort`                        | 文字列   | いいえ       | `asc`または`desc`の順にソートされたプロジェクトを返します。デフォルトは`desc`です。 |
| `starred`                     | ブール値  | いいえ       | 現在のユーザーがStar付きに登録したプロジェクトで制限します。 |
| `statistics`                  | ブール値  | いいえ       | プロジェクトの統計を含めます。レポーター、デベロッパー、メンテナー、またはオーナーロールを持つユーザーのみ利用可能です。 |
| `updated_after`               | 日時 | いいえ       | 指定された時刻以降に最終更新が行われたプロジェクトに結果を制限します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）。 |
| `updated_before`              | 日時 | いいえ       | 指定された時刻以前に最終更新が行われたプロジェクトに結果を制限します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）。 |
| `visibility`                  | 文字列   | いいえ       | 表示レベルで制限します。指定可能な値: `public`、`internal`、または`private`。 |
| `with_custom_attributes`      | ブール値  | いいえ       | レスポンスに[カスタム属性](custom_attributes.md)を含めます。管理者アクセス権が必要です。 |
| `with_issues_enabled`         | ブール値  | いいえ       | 有効になっているイシュー機能で制限します。 |
| `with_merge_requests_enabled` | ブール値  | いいえ       | 有効になっているマージリクエスト機能で制限します。 |
| `with_programming_language`   | 文字列   | いいえ       | 指定されているプログラミング言語を使用するプロジェクトで制限します。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `id` | 整数 | プロジェクトのID。 |
| `description` | 文字列 | プロジェクトの説明。 |
| `name` | 文字列 | プロジェクトの名前。 |
| `name_with_namespace` | 文字列 | プロジェクトの名前とそのネームスペース。 |
| `path` | 文字列 | プロジェクトのパス。 |
| `path_with_namespace` | 文字列 | プロジェクトのパスとそのネームスペース。 |
| `created_at` | 日時 | プロジェクトが作成されたタイムスタンプ。 |
| `default_branch` | 文字列 | プロジェクトのデフォルトブランチ。 |
| `tag_list` | 文字列の配列 | 非推奨。代わりに`topics`を使用してください。プロジェクトのタグのリスト。 |
| `topics` | 文字列の配列 | プロジェクトのトピックのリスト。 |
| `ssh_url_to_repo` | 文字列 | リポジトリをクローンするためのSSH URL。 |
| `http_url_to_repo` | 文字列 | リポジトリをクローンするためのHTTP URL。 |
| `web_url` | 文字列 | ブラウザでプロジェクトにアクセスするためのURL。 |
| `readme_url` | 文字列 | プロジェクトのReadmeファイルへのURL。 |
| `forks_count` | 整数 | プロジェクトのフォーク数。 |
| `avatar_url` | 文字列 | プロジェクトのアバター画像へのURL。 |
| `star_count` | 整数 | プロジェクトが受け取ったスターの数。 |
| `last_activity_at` | 日時 | プロジェクトでの最終アクティビティのタイムスタンプ。 |
| `visibility` | 文字列 | プロジェクトの表示レベル。指定可能な値: `private`、`internal`、または`public`。 |
| `namespace` | オブジェクト | プロジェクトのネームスペース情報。 |
| `namespace.id` | 整数 | ネームスペースのID。 |
| `namespace.name` | 文字列 | ネームスペースの名前。 |
| `namespace.path` | 文字列 | ネームスペースのパス。 |
| `namespace.kind` | 文字列 | ネームスペースのタイプ。指定可能な値: `user`または`group`。 |
| `namespace.full_path` | 文字列 | ネームスペースのフルパス。 |
| `namespace.parent_id` | 整数 | 該当する場合、親ネームスペースのID。 |
| `namespace.avatar_url` | 文字列 | ネームスペースのアバター画像へのURL。 |
| `namespace.web_url` | 文字列 | ブラウザでネームスペースにアクセスするためのURL。 |
| `container_registry_image_prefix` | 文字列 | コンテナイメージのレジストリ用のプレフィックス。 |
| `_links` | オブジェクト | プロジェクトに関連するAPIエンドポイントリンクのコレクション。 |
| `_links.self` | 文字列 | プロジェクトリソースへのURL。 |
| `_links.issues` | 文字列 | プロジェクトのイシューへのURL。 |
| `_links.merge_requests` | 文字列 | プロジェクトのマージリクエストへのURL。 |
| `_links.repo_branches` | 文字列 | プロジェクトのリポジトリのブランチへのURL。 |
| `_links.labels` | 文字列 | プロジェクトのラベルへのURL。 |
| `_links.events` | 文字列 | プロジェクトのイベントへのURL。 |
| `_links.members` | 文字列 | プロジェクトのメンバーへのURL。 |
| `_links.cluster_agents` | 文字列 | プロジェクトのクラスターエージェントへのURL。 |
| `marked_for_deletion_at` | 日付 | 非推奨。代わりに`marked_for_deletion_on`を使用してください。プロジェクトが削除予定である日付。 |
| `marked_for_deletion_on` | 日付 | プロジェクトが削除予定である日付。 |
| `packages_enabled` | ブール値 | プロジェクトに対してパッケージレジストリが有効になっているかどうか。 |
| `empty_repo` | ブール値 | リポジトリが空であるかどうか。 |
| `archived` | ブール値 | プロジェクトがアーカイブされているかどうか。 |
| `resolve_outdated_diff_discussions` | ブール値 | 最新ではない差分ディスカッションが自動的に解決されるかどうか。 |
| `container_expiration_policy` | オブジェクト | コンテナイメージのポリシーの有効期限に関する設定。 |
| `container_expiration_policy.cadence` | 文字列 | コンテナポリシーの有効期限が実行される頻度。 |
| `container_expiration_policy.enabled` | ブール値 | コンテナポリシーの有効期限が有効になっているかどうか。 |
| `container_expiration_policy.keep_n` | 整数 | 保持するコンテナイメージの数。 |
| `container_expiration_policy.older_than` | 文字列 | この値より古いコンテナイメージを削除します。 |
| `container_expiration_policy.name_regex` | 文字列 | 非推奨。代わりに`name_regex_delete`を使用してください。コンテナイメージ名に一致する正規表現。 |
| `container_expiration_policy.name_regex_keep` | 文字列 | 保持するコンテナイメージ名に一致する正規表現。 |
| `container_expiration_policy.next_run_at` | 日時 | 次回のポリシー実行予定のタイムスタンプ。 |
| `repository_object_format` | 文字列 | リポジトリで使用されるオブジェクト形式 (sha1またはsha256)。 |
| `issues_enabled` | ブール値 | プロジェクトに対してイシューが有効になっているかどうか。 |
| `merge_requests_enabled` | ブール値 | プロジェクトに対してマージリクエストが有効になっているかどうか。 |
| `wiki_enabled` | ブール値 | プロジェクトに対してWikiが有効になっているかどうか。 |
| `jobs_enabled` | ブール値 | プロジェクトに対してジョブが有効になっているかどうか。 |
| `snippets_enabled` | ブール値 | プロジェクトに対してスニペットが有効になっているかどうか。 |
| `container_registry_enabled` | ブール値 | 非推奨。代わりに`container_registry_access_level`を使用してください。コンテナレジストリが有効になっているかどうか。 |
| `service_desk_enabled` | ブール値 | プロジェクトに対してサービスデスクが有効になっているかどうか。 |
| `can_create_merge_request_in` | ブール値 | 現在のユーザーがプロジェクトでマージリクエストを作成できるかどうか。 |
| `issues_access_level` | 文字列 | イシュー機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `repository_access_level` | 文字列 | リポジトリ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `merge_requests_access_level` | 文字列 | マージリクエスト機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `forking_access_level` | 文字列 | プロジェクトをフォークするためのアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `wiki_access_level` | 文字列 | Wiki機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `builds_access_level` | 文字列 | CI/CDのビルド機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `snippets_access_level` | 文字列 | スニペット機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `pages_access_level` | 文字列 | GitLab Pagesのアクセスレベル。指定可能な値: `disabled`、`private`、`enabled`、または`public`。 |
| `analytics_access_level` | 文字列 | アナリティクス機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `container_registry_access_level` | 文字列 | コンテナレジストリのアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `security_and_compliance_access_level` | 文字列 | セキュリティとコンプライアンス機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `releases_access_level` | 文字列 | リリース機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `environments_access_level` | 文字列 | 環境機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `feature_flags_access_level` | 文字列 | 機能フラグ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `infrastructure_access_level` | 文字列 | インフラストラクチャ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `monitor_access_level` | 文字列 | モニター機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `model_experiments_access_level` | 文字列 | モデル実験機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `model_registry_access_level` | 文字列 | モデルレジストリ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `package_registry_access_level` | 文字列 | パッケージレジストリ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `emails_disabled` | ブール値 | プロジェクトのメールが無効になっているかどうかを示します。 |
| `emails_enabled` | ブール値 | プロジェクトのメールが有効になっているかどうかを示します。 |
| `show_diff_preview_in_email` | ブール値 | メール通知に差分プレビューが表示されるかどうかを示します。 |
| `shared_runners_enabled` | ブール値 | プロジェクトに対して共有Runnerが有効になっているかどうか。 |
| `lfs_enabled` | ブール値 | プロジェクトに対してGit LFSが有効になっているかどうかを示します。 |
| `creator_id` | 整数 | プロジェクトを作成したユーザーのID。 |
| `import_status` | 文字列 | プロジェクトインポートのステータス。 |
| `open_issues_count` | 整数 | 未解決のイシューの数。 |
| `description_html` | 文字列 | HTML形式のプロジェクトの説明。 |
| `updated_at` | 日時 | プロジェクトが最後に更新されたタイムスタンプ。 |
| `ci_default_git_depth` | 整数 | CI/CDパイプラインのデフォルトGit深度。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_forward_deployment_enabled` | ブール値 | 前方デプロイが有効になっているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_job_token_scope_enabled` | ブール値 | CI/CDジョブトークンスコープが有効になっているかどうかを示します。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_separated_caches` | ブール値 | ブランチによってCI/CDキャッシュが分離されているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | ブール値 | フォークパイプラインが親プロジェクトで実行できるかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `build_git_strategy` | 文字列 | CI/CDビルドに利用されるGitストラテジー（フェッチまたはクローン）。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `keep_latest_artifact` | ブール値 | 新しいアーティファクトが作成されたときに最新のアーティファクトが保持されるかどうかを示します。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `restrict_user_defined_variables` | ブール値 | ユーザー定義の変数が制限されているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `runners_token` | 文字列 | プロジェクトにRunnerを登録するためのトークン。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `runner_token_expiration_interval` | 整数 | Runnerトークンの有効期限（秒）。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `group_runners_enabled` | ブール値 | プロジェクトに対してグループRunnerが有効になっているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `auto_cancel_pending_pipelines` | 文字列 | 保留中のパイプラインを自動的にキャンセルする設定。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `build_timeout` | 整数 | CI/CDジョブのタイムアウト（秒）。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `auto_devops_enabled` | ブール値 | プロジェクトに対してAuto DevOpsが有効になっているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `auto_devops_deploy_strategy` | 文字列 | Auto DevOpsのデプロイストラテジー。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_config_path` | 文字列 | CI/CD設定ファイルへのパス。 |
| `public_jobs` | ブール値 | ジョブログが公開アクセス可能かどうか。 |
| `shared_with_groups` | オブジェクトの配列 | プロジェクトが共有されているグループのリスト。 |
| `only_allow_merge_if_pipeline_succeeds` | ブール値 | パイプラインが成功した場合にのみマージが許可されるかどうか。 |
| `allow_merge_on_skipped_pipeline` | ブール値 | パイプラインがスキップされた場合にマージが許可されるかどうか。 |
| `request_access_enabled` | ブール値 | ユーザーがプロジェクトへのアクセスをリクエストできるかどうか。 |
| `only_allow_merge_if_all_discussions_are_resolved` | ブール値 | すべてのディスカッションが解決された場合にのみマージが許可されるかどうか。 |
| `remove_source_branch_after_merge` | ブール値 | マージ後にソースブランチが自動的に削除されるかどうか。 |
| `printing_merge_request_link_enabled` | ブール値 | プッシュ後にマージリクエストリンクが印刷されるかどうかを示します。 |
| `merge_method` | 文字列 | プロジェクトに利用されるマージメソッド。指定可能な値: `merge`、`rebase_merge`、または`ff`。 |
| `merge_request_title_regex` | 文字列 | マージリクエストタイトルの検証用正規表現パターン。 |
| `merge_request_title_regex_description` | 文字列 | マージリクエストタイトルの正規表現検証の説明。 |
| `squash_option` | 文字列 | マージリクエストのスカッシュオプション。 |
| `enforce_auth_checks_on_uploads` | ブール値 | アップロードに対する認証チェックが強制されるかどうか。 |
| `suggestion_commit_message` | 文字列 | 提案用のカスタムコミットメッセージ。 |
| `merge_commit_template` | 文字列 | マージコミットメッセージのテンプレート。 |
| `squash_commit_template` | 文字列 | スカッシュコミットメッセージのテンプレート。 |
| `issue_branch_template` | 文字列 | イシューから作成されたブランチ名のテンプレート。 |
| `warn_about_potentially_unwanted_characters` | ブール値 | 不要な可能性のある文字の使用について警告するかどうか。 |
| `autoclose_referenced_issues` | ブール値 | 参照されているイシューが自動的にクローズされるかどうか。 |
| `max_artifacts_size` | 整数 | CI/CDアーティファクトの最大サイズ（MB）。 |
| `approvals_before_merge` | 整数 | 非推奨。代わりにマージリクエスト承認APIを使用してください。マージ前に必要な承認の数。 |
| `mirror` | ブール値 | プロジェクトがミラーであるかどうか。 |
| `external_authorization_classification_label` | 文字列 | 外部認可分類ラベル。 |
| `requirements_enabled` | ブール値 | 要件管理が有効になっているかどうかを示します。 |
| `requirements_access_level` | 文字列 | 要件機能のアクセスレベル。 |
| `security_and_compliance_enabled` | ブール値 | セキュリティとコンプライアンス機能が有効になっているかどうかを示します。 |
| `compliance_frameworks` | 文字列の配列 | プロジェクトに適用されるコンプライアンスフレームワーク。 |
| `issues_template` | 文字列 | イシューのデフォルトの説明。説明は、GitLab Flavored Markdownを使用して解析されます。PremiumおよびUltimateのみです。 |
| `merge_requests_template` | 文字列 | マージリクエストの説明のテンプレート。PremiumおよびUltimateのみです。 |
| `merge_pipelines_enabled` | ブール値 | マージパイプラインが有効になっているかどうかを示します。 |
| `merge_trains_enabled` | ブール値 | マージトレインが有効になっているかどうかを示します。 |
| `merge_trains_skip_train_allowed` | ブール値 | マージトレインのスキップが許可されているかどうかを示します。 |
| `only_allow_merge_if_all_status_checks_passed` | ブール値 | すべてのステータスチェックが合格した場合にのみマージが許可されるかどうか。Ultimateのみです。 |
| `allow_pipeline_trigger_approve_deployment` | ブール値 | パイプライントリガーがデプロイを承認できるかどうか。 |
| `prevent_merge_without_jira_issue` | ブール値 | マージに連携されたJiraイシューが必要かどうかを示します。 |
| `duo_remote_flows_enabled` | ブール値 | GitLab Duoリモートフローが有効になっているかどうかを示します。 |
| `duo_foundational_flows_enabled` | ブール値 | GitLab Duo基本フローが有効になっているかどうかを示します。 |
| `duo_sast_fp_detection_enabled` | ブール値 | GitLab DuoSAST誤検出判定が有効になっているかどうかを示します。 |
| `spp_repository_pipeline_access` | ブール値 | セキュリティポリシーのリポジトリパイプラインアクセス。セキュリティオーケストレーションポリシー機能が利用可能な場合にのみ表示されます。 |
| `permissions` | オブジェクト | プロジェクトのユーザー権限。 |
| `permissions.project_access` | オブジェクト | ユーザーのプロジェクトアクセス権限。 |
| `permissions.group_access` | オブジェクト | ユーザーのグループアクセス権限。 |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/users/:user_id/projects
```

レスポンス例: 

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 50,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "ci_display_pipeline_variables": false,
    "protect_merge_request_pipelines": true,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "marked_for_deletion_at": "2020-04-03", // Deprecated in favor of marked_for_deletion_on. Planned for removal in a future version of the REST API.
    "marked_for_deletion_on": "2020-04-03",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  },
  {
    "id": 6,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "puppet"
    ],
    "topics": [
      "example",
      "puppet"
    ],
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "namespace": {
      "id": 4,
      "name": "Brightbox",
      "path": "brightbox",
      "kind": "group",
      "full_path": "brightbox"
    },
    "import_status": "none",
    "import_error": null,
    "permissions": {
      "project_access": {
        "access_level": 10,
        "notification_level": 3
      },
      "group_access": {
        "access_level": 50,
        "notification_level": 3
      }
    },
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 0,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "ci_display_pipeline_variables": false,
    "protect_merge_request_pipelines": true,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "auto_devops_enabled": true,
    "auto_devops_deploy_strategy": "continuous",
    "repository_storage": "default",
    "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
    "mirror": false,
    "mirror_user_id": 45,
    "mirror_trigger_builds": false,
    "only_mirror_protected_branches": false,
    "mirror_overwrites_diverged_branches": false,
    "external_authorization_classification_label": null,
    "packages_enabled": true, // deprecated, use package_registry_access_level instead
    "empty_repo": false,
    "package_registry_access_level": "enabled",
    "service_desk_enabled": false,
    "service_desk_address": null,
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

### ユーザーのすべてのプロジェクト貢献をリスト表示 {#list-all-projects-contributions-for-a-user}

指定されたユーザーに対する、可視プロジェクトへのすべての貢献をリスト表示します。過去1年間の貢献のみを返します。貢献としてカウントされるものに関する詳細については、[View projects you work with](../user/project/working_with_projects.md#view-projects-you-work-with)を参照してください。

```plaintext
GET /users/:user_id/contributed_projects
```

サポートされている属性:

| 属性  | 型    | 必須 | 説明 |
|:-----------|:--------|:---------|:------------|
| `user_id`  | 文字列  | はい      | ユーザーのIDまたはユーザー名。 |
| `order_by` | 文字列  | いいえ       | `id`、`name`、`path`、`created_at`、`updated_at`、`star_count`、または`last_activity_at`のフィールドで並べ替えられたプロジェクトを返します。デフォルトは`created_at`です。 |
| `simple`   | ブール値 | いいえ       | `true`の場合、各プロジェクトに対して限定されたフィールドのみを返します。未認証のリクエストは、`simple`が設定されていなくても、限定されたフィールドを持つ公開プロジェクトのみを返します。 |
| `sort`     | 文字列  | いいえ       | `asc`または`desc`の順にソートされたプロジェクトを返します。デフォルトは`desc`です。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|-----------|------|-------------|
| `id` | 整数 | プロジェクトのID。 |
| `description` | 文字列 | プロジェクトの説明。 |
| `name` | 文字列 | プロジェクトの名前。 |
| `name_with_namespace` | 文字列 | プロジェクトの名前とそのネームスペース。 |
| `path` | 文字列 | プロジェクトのパス。 |
| `path_with_namespace` | 文字列 | プロジェクトのパスとそのネームスペース。 |
| `created_at` | 日時 | プロジェクトが作成されたタイムスタンプ。 |
| `default_branch` | 文字列 | プロジェクトのデフォルトブランチ。 |
| `tag_list` | 文字列の配列 | 非推奨。代わりに`topics`を使用してください。プロジェクトのタグのリスト。 |
| `topics` | 文字列の配列 | プロジェクトのトピックのリスト。 |
| `ssh_url_to_repo` | 文字列 | リポジトリをクローンするためのSSH URL。 |
| `http_url_to_repo` | 文字列 | リポジトリをクローンするためのHTTP URL。 |
| `web_url` | 文字列 | ブラウザでプロジェクトにアクセスするためのURL。 |
| `readme_url` | 文字列 | プロジェクトのReadmeファイルへのURL。 |
| `forks_count` | 整数 | プロジェクトのフォーク数。 |
| `avatar_url` | 文字列 | プロジェクトのアバター画像へのURL。 |
| `star_count` | 整数 | プロジェクトが受け取ったスターの数。 |
| `last_activity_at` | 日時 | プロジェクトでの最終アクティビティのタイムスタンプ。 |
| `visibility` | 文字列 | プロジェクトの表示レベル。指定可能な値: `private`、`internal`、または`public`。 |
| `namespace` | オブジェクト | プロジェクトのネームスペース情報。 |
| `namespace.id` | 整数 | ネームスペースのID。 |
| `namespace.name` | 文字列 | ネームスペースの名前。 |
| `namespace.path` | 文字列 | ネームスペースのパス。 |
| `namespace.kind` | 文字列 | ネームスペースのタイプ。指定可能な値: `user`または`group`。 |
| `namespace.full_path` | 文字列 | ネームスペースのフルパス。 |
| `namespace.parent_id` | 整数 | 該当する場合、親ネームスペースのID。 |
| `namespace.avatar_url` | 文字列 | ネームスペースのアバター画像へのURL。 |
| `namespace.web_url` | 文字列 | ブラウザでネームスペースにアクセスするためのURL。 |
| `container_registry_image_prefix` | 文字列 | コンテナイメージのレジストリ用のプレフィックス。 |
| `_links` | オブジェクト | プロジェクトに関連するAPIエンドポイントリンクのコレクション。 |
| `_links.self` | 文字列 | プロジェクトリソースへのURL。 |
| `_links.issues` | 文字列 | プロジェクトのイシューへのURL。 |
| `_links.merge_requests` | 文字列 | プロジェクトのマージリクエストへのURL。 |
| `_links.repo_branches` | 文字列 | プロジェクトのリポジトリのブランチへのURL。 |
| `_links.labels` | 文字列 | プロジェクトのラベルへのURL。 |
| `_links.events` | 文字列 | プロジェクトのイベントへのURL。 |
| `_links.members` | 文字列 | プロジェクトのメンバーへのURL。 |
| `_links.cluster_agents` | 文字列 | プロジェクトのクラスターエージェントへのURL。 |
| `marked_for_deletion_at` | 日付 | 非推奨。代わりに`marked_for_deletion_on`を使用してください。プロジェクトが削除予定である日付。 |
| `marked_for_deletion_on` | 日付 | プロジェクトが削除予定である日付。 |
| `packages_enabled` | ブール値 | プロジェクトに対してパッケージレジストリが有効になっているかどうか。 |
| `empty_repo` | ブール値 | リポジトリが空であるかどうか。 |
| `archived` | ブール値 | プロジェクトがアーカイブされているかどうか。 |
| `resolve_outdated_diff_discussions` | ブール値 | 最新ではない差分ディスカッションが自動的に解決されるかどうか。 |
| `container_expiration_policy` | オブジェクト | コンテナイメージのポリシーの有効期限に関する設定。 |
| `container_expiration_policy.cadence` | 文字列 | コンテナポリシーの有効期限が実行される頻度。 |
| `container_expiration_policy.enabled` | ブール値 | コンテナポリシーの有効期限が有効になっているかどうか。 |
| `container_expiration_policy.keep_n` | 整数 | 保持するコンテナイメージの数。 |
| `container_expiration_policy.older_than` | 文字列 | この値より古いコンテナイメージを削除します。 |
| `container_expiration_policy.name_regex` | 文字列 | 非推奨。代わりに`name_regex_delete`を使用してください。コンテナイメージ名に一致する正規表現。 |
| `container_expiration_policy.name_regex_keep` | 文字列 | 保持するコンテナイメージ名に一致する正規表現。 |
| `container_expiration_policy.next_run_at` | 日時 | 次回のポリシー実行予定のタイムスタンプ。 |
| `repository_object_format` | 文字列 | リポジトリで使用されるオブジェクト形式 (sha1またはsha256)。 |
| `issues_enabled` | ブール値 | プロジェクトに対してイシューが有効になっているかどうか。 |
| `merge_requests_enabled` | ブール値 | プロジェクトに対してマージリクエストが有効になっているかどうか。 |
| `wiki_enabled` | ブール値 | プロジェクトに対してWikiが有効になっているかどうか。 |
| `jobs_enabled` | ブール値 | プロジェクトに対してジョブが有効になっているかどうか。 |
| `snippets_enabled` | ブール値 | プロジェクトに対してスニペットが有効になっているかどうか。 |
| `container_registry_enabled` | ブール値 | 非推奨。代わりに`container_registry_access_level`を使用してください。コンテナレジストリが有効になっているかどうか。 |
| `service_desk_enabled` | ブール値 | プロジェクトに対してサービスデスクが有効になっているかどうか。 |
| `can_create_merge_request_in` | ブール値 | 現在のユーザーがプロジェクトでマージリクエストを作成できるかどうか。 |
| `issues_access_level` | 文字列 | イシュー機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `repository_access_level` | 文字列 | リポジトリ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `merge_requests_access_level` | 文字列 | マージリクエスト機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `forking_access_level` | 文字列 | プロジェクトをフォークするためのアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `wiki_access_level` | 文字列 | Wiki機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `builds_access_level` | 文字列 | CI/CDのビルド機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `snippets_access_level` | 文字列 | スニペット機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `pages_access_level` | 文字列 | GitLab Pagesのアクセスレベル。指定可能な値: `disabled`、`private`、`enabled`、または`public`。 |
| `analytics_access_level` | 文字列 | アナリティクス機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `container_registry_access_level` | 文字列 | コンテナレジストリのアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `security_and_compliance_access_level` | 文字列 | セキュリティとコンプライアンス機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `releases_access_level` | 文字列 | リリース機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `environments_access_level` | 文字列 | 環境機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `feature_flags_access_level` | 文字列 | 機能フラグ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `infrastructure_access_level` | 文字列 | インフラストラクチャ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `monitor_access_level` | 文字列 | モニター機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `model_experiments_access_level` | 文字列 | モデル実験機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `model_registry_access_level` | 文字列 | モデルレジストリ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `package_registry_access_level` | 文字列 | パッケージレジストリ機能のアクセスレベル。指定可能な値: `disabled`、`private`、または`enabled`。 |
| `emails_disabled` | ブール値 | プロジェクトのメールが無効になっているかどうかを示します。 |
| `emails_enabled` | ブール値 | プロジェクトのメールが有効になっているかどうかを示します。 |
| `show_diff_preview_in_email` | ブール値 | メール通知に差分プレビューが表示されるかどうかを示します。 |
| `shared_runners_enabled` | ブール値 | プロジェクトに対して共有Runnerが有効になっているかどうか。 |
| `lfs_enabled` | ブール値 | プロジェクトに対してGit LFSが有効になっているかどうかを示します。 |
| `creator_id` | 整数 | プロジェクトを作成したユーザーのID。 |
| `import_status` | 文字列 | プロジェクトインポートのステータス。 |
| `open_issues_count` | 整数 | 未解決のイシューの数。 |
| `description_html` | 文字列 | HTML形式のプロジェクトの説明。 |
| `updated_at` | 日時 | プロジェクトが最後に更新されたタイムスタンプ。 |
| `ci_default_git_depth` | 整数 | CI/CDパイプラインのデフォルトGit深度。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_forward_deployment_enabled` | ブール値 | 前方デプロイが有効になっているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_job_token_scope_enabled` | ブール値 | CI/CDジョブトークンスコープが有効になっているかどうかを示します。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_separated_caches` | ブール値 | ブランチによってCI/CDキャッシュが分離されているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | ブール値 | フォークパイプラインが親プロジェクトで実行できるかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `build_git_strategy` | 文字列 | CI/CDビルドに利用されるGitストラテジー（フェッチまたはクローン）。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `keep_latest_artifact` | ブール値 | 新しいアーティファクトが作成されたときに最新のアーティファクトが保持されるかどうかを示します。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `restrict_user_defined_variables` | ブール値 | ユーザー定義の変数が制限されているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `runners_token` | 文字列 | プロジェクトにRunnerを登録するためのトークン。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `runner_token_expiration_interval` | 整数 | Runnerトークンの有効期限（秒）。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `group_runners_enabled` | ブール値 | プロジェクトに対してグループRunnerが有効になっているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `auto_cancel_pending_pipelines` | 文字列 | 保留中のパイプラインを自動的にキャンセルする設定。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `build_timeout` | 整数 | CI/CDジョブのタイムアウト（秒）。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `auto_devops_enabled` | ブール値 | プロジェクトに対してAuto DevOpsが有効になっているかどうか。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `auto_devops_deploy_strategy` | 文字列 | Auto DevOpsのデプロイストラテジー。管理者権限またはプロジェクトのオーナーロールがある場合にのみ表示されます。 |
| `ci_config_path` | 文字列 | CI/CD設定ファイルへのパス。 |
| `public_jobs` | ブール値 | ジョブログが公開アクセス可能かどうか。 |
| `shared_with_groups` | オブジェクトの配列 | プロジェクトが共有されているグループのリスト。 |
| `only_allow_merge_if_pipeline_succeeds` | ブール値 | パイプラインが成功した場合にのみマージが許可されるかどうか。 |
| `allow_merge_on_skipped_pipeline` | ブール値 | パイプラインがスキップされた場合にマージが許可されるかどうか。 |
| `request_access_enabled` | ブール値 | ユーザーがプロジェクトへのアクセスをリクエストできるかどうか。 |
| `only_allow_merge_if_all_discussions_are_resolved` | ブール値 | すべてのディスカッションが解決された場合にのみマージが許可されるかどうか。 |
| `remove_source_branch_after_merge` | ブール値 | マージ後にソースブランチが自動的に削除されるかどうか。 |
| `printing_merge_request_link_enabled` | ブール値 | プッシュ後にマージリクエストリンクが印刷されるかどうかを示します。 |
| `merge_method` | 文字列 | プロジェクトに利用されるマージメソッド。指定可能な値: `merge`、`rebase_merge`、または`ff`。 |
| `merge_request_title_regex` | 文字列 | マージリクエストタイトルの検証用正規表現パターン。 |
| `merge_request_title_regex_description` | 文字列 | マージリクエストタイトルの正規表現検証の説明。 |
| `squash_option` | 文字列 | マージリクエストのスカッシュオプション。 |
| `enforce_auth_checks_on_uploads` | ブール値 | アップロードに対する認証チェックが強制されるかどうか。 |
| `suggestion_commit_message` | 文字列 | 提案用のカスタムコミットメッセージ。 |
| `merge_commit_template` | 文字列 | マージコミットメッセージのテンプレート。 |
| `squash_commit_template` | 文字列 | スカッシュコミットメッセージのテンプレート。 |
| `issue_branch_template` | 文字列 | イシューから作成されたブランチ名のテンプレート。 |
| `warn_about_potentially_unwanted_characters` | ブール値 | 不要な可能性のある文字の使用について警告するかどうか。 |
| `autoclose_referenced_issues` | ブール値 | 参照されているイシューが自動的にクローズされるかどうか。 |
| `max_artifacts_size` | 整数 | CI/CDアーティファクトの最大サイズ（MB）。 |
| `approvals_before_merge` | 整数 | 非推奨。代わりにマージリクエスト承認APIを使用してください。マージ前に必要な承認の数。 |
| `mirror` | ブール値 | プロジェクトがミラーであるかどうか。 |
| `external_authorization_classification_label` | 文字列 | 外部認可分類ラベル。 |
| `requirements_enabled` | ブール値 | 要件管理が有効になっているかどうかを示します。 |
| `requirements_access_level` | 文字列 | 要件機能のアクセスレベル。 |
| `security_and_compliance_enabled` | ブール値 | セキュリティとコンプライアンス機能が有効になっているかどうかを示します。 |
| `compliance_frameworks` | 文字列の配列 | プロジェクトに適用されるコンプライアンスフレームワーク。 |
| `issues_template` | 文字列 | イシューのデフォルトの説明。説明は、GitLab Flavored Markdownを使用して解析されます。PremiumおよびUltimateのみです。 |
| `merge_requests_template` | 文字列 | マージリクエストの説明のテンプレート。PremiumおよびUltimateのみです。 |
| `merge_pipelines_enabled` | ブール値 | マージパイプラインが有効になっているかどうかを示します。 |
| `merge_trains_enabled` | ブール値 | マージトレインが有効になっているかどうかを示します。 |
| `merge_trains_skip_train_allowed` | ブール値 | マージトレインのスキップが許可されているかどうかを示します。 |
| `only_allow_merge_if_all_status_checks_passed` | ブール値 | すべてのステータスチェックが合格した場合にのみマージが許可されるかどうか。Ultimateのみです。 |
| `allow_pipeline_trigger_approve_deployment` | ブール値 | パイプライントリガーがデプロイを承認できるかどうか。 |
| `prevent_merge_without_jira_issue` | ブール値 | マージに連携されたJiraイシューが必要かどうかを示します。 |
| `duo_remote_flows_enabled` | ブール値 | GitLab Duoリモートフローが有効になっているかどうかを示します。 |
| `duo_foundational_flows_enabled` | ブール値 | GitLab Duo基本フローが有効になっているかどうかを示します。 |
| `duo_sast_fp_detection_enabled` | ブール値 | GitLab DuoSAST誤検出判定が有効になっているかどうかを示します。 |
| `spp_repository_pipeline_access` | ブール値 | セキュリティポリシーのリポジトリパイプラインアクセス。セキュリティオーケストレーションポリシー機能が利用可能な場合にのみ表示されます。 |
| `permissions` | オブジェクト | プロジェクトのユーザー権限。 |
| `permissions.project_access` | オブジェクト | ユーザーのプロジェクトアクセス権限。 |
| `permissions.group_access` | オブジェクト | ユーザーのグループアクセス権限。 |
<!-- markdownlint-disable-next-line MD055 MD056 -->
{.condensed}

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/5/contributed_projects"
```

レスポンス例: 

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  },
  {
    "id": 6,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "puppet"
    ],
    "topics": [
      "example",
      "puppet"
    ],
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 4,
      "name": "Brightbox",
      "path": "brightbox",
      "kind": "group",
      "full_path": "brightbox"
    },
    "import_status": "none",
    "import_error": null,
    "permissions": {
      "project_access": {
        "access_level": 10,
        "notification_level": 3
      },
      "group_access": {
        "access_level": 50,
        "notification_level": 3
      }
    },
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "allow_pipeline_trigger_approve_deployment": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "auto_devops_enabled": true,
    "auto_devops_deploy_strategy": "continuous",
    "repository_storage": "default",
    "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
    "mirror": false,
    "mirror_user_id": 45,
    "mirror_trigger_builds": false,
    "only_mirror_protected_branches": false,
    "mirror_overwrites_diverged_branches": false,
    "external_authorization_classification_label": null,
    "packages_enabled": true, // deprecated, use package_registry_access_level instead
    "empty_repo": false,
    "package_registry_access_level": "enabled",
    "service_desk_enabled": false,
    "service_desk_address": null,
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "secret_push_protection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

## 属性のリストを取得する {#list-attributes}

プロジェクトの属性のリストを取得します。

### プロジェクトのすべてのメンバーをリストする {#list-all-members-of-a-project}

指定されたプロジェクトへのアクセス権を持つすべてのメンバーをリスト表示します。

```plaintext
GET /projects/:id/users
```

サポートされている属性:

| 属性    | 型              | 必須 | 説明 |
|:-------------|:------------------|:---------|:------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `search`     | 文字列            | いいえ       | 特定のメンバーを`username`または`name`で検索します。 |
| `skip_users` | 整数の配列     | いいえ       | 指定されたIDを持つメンバーを除外します。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|:----------|:-----|:------------|
| `id` | 整数 | ユーザーのID。 |
| `username` | 文字列 | ユーザーのユーザー名。 |
| `name` | 文字列 | ユーザーのフルネーム。 |
| `state` | 文字列 | ユーザーアカウントの状態。指定可能な値: `active`または`blocked`。 |
| `avatar_url` | 文字列 | ユーザーのアバター画像へのURL。 |
| `web_url` | 文字列 | ブラウザでユーザーのプロフィールにアクセスするためのURL。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<project_id>/users" \
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "name": "John Smith",
    "state": "active",
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://localhost:3000/john_smith"
  },
  {
    "id": 2,
    "username": "jack_smith",
    "name": "Jack Smith",
    "state": "blocked",
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "web_url": "http://localhost:3000/jack_smith"
  }
]
```

### すべての祖先グループをリスト表示 {#list-all-ancestor-groups}

指定されたプロジェクトのすべての祖先グループをリスト表示します。

```plaintext
GET /projects/:id/groups
```

サポートされている属性:

| 属性                 | 型              | 必須 | 説明 |
|:--------------------------|:------------------|:---------|:------------|
| `id`                      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `search`                  | 文字列            | いいえ       | グループIDで特定のグループを検索します。 |
| `shared_min_access_level` | 整数           | いいえ       | 少なくとも指定されたアクセスレベルを持つ共有グループに限定します。使用可能な値: `5` （最小アクセス）、`10` （ゲスト）、`15` （プランナー）、`20` （レポーター）、`25` （セキュリティマネージャー）、`30` （デベロッパー）、`40` （メンテナー）、または`50` （オーナー）。 |
| `shared_visible_only`     | ブール値           | いいえ       | `true`の場合、認証済みユーザーがアクセスできる共有グループのみを返します。 |
| `skip_groups`             | 整数の配列 | いいえ       | 渡されたグループIDをスキップします。 |
| `with_shared`             | ブール値           | いいえ       | このグループと共有されているプロジェクトを含めます。デフォルトは`false`です。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|:----------|:-----|:------------|
| `id` | 整数 | グループのID。 |
| `name` | 文字列 | グループの名前。 |
| `avatar_url` | 文字列 | グループのアバター画像へのURL。 |
| `web_url` | 文字列 | ブラウザでグループにアクセスするためのURL。 |
| `full_name` | 文字列 | グループの正式名称。 |
| `full_path` | 文字列 | グループのフルパス。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/groups"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "full_name": "Foobar Group",
    "full_path": "foo-bar"
  },
  {
    "id": 2,
    "name": "Shared Group",
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/bar.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar",
    "full_name": "Shared Group",
    "full_path": "foo/shared"
  }
]
```

### プロジェクトに招待できるすべてのグループをリスト表示 {#list-all-groups-available-to-invite-to-a-project}

プロジェクトに招待できるすべてのグループをリスト表示します。

```plaintext
GET /projects/:id/share_locations
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `search`  | 文字列            | いいえ       | グループIDで特定のグループを検索します。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|:----------|:-----|:------------|
| `id` | 整数 | グループのID。 |
| `web_url` | 文字列 | ブラウザでグループにアクセスするためのURL。 |
| `name` | 文字列 | グループの名前。 |
| `avatar_url` | 文字列 | グループのアバター画像へのURL。 |
| `full_name` | 文字列 | グループの正式名称。 |
| `full_path` | 文字列 | グループのフルパス。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/share_locations"
```

レスポンス例: 

```json
[
  {
    "id": 22,
    "web_url": "http://127.0.0.1:3000/groups/gitlab-org",
    "name": "Gitlab Org",
    "avatar_url": null,
    "full_name": "Gitlab Org",
    "full_path": "gitlab-org"
  },
  {
    "id": 25,
    "web_url": "http://127.0.0.1:3000/groups/gnuwget",
    "name": "Gnuwget",
    "avatar_url": null,
    "full_name": "Gnuwget",
    "full_path": "gnuwget"
  }
]
```

### プロジェクト内のすべての招待されたグループをリスト表示 {#list-all-invited-groups-in-a-project}

プロジェクト内のすべての招待されたグループをリスト表示します。認証なしでアクセスした場合、公開されている招待済みグループのみを返します。このエンドポイントは、次の項目ごとに1分あたり60件のリクエストにレート制限されています。

- 認証済みユーザーのユーザー
- 未認証ユーザーのIPアドレス

このエンドポイントはページネーションをサポートしています:

- オフセットベースのページネーションを使用して、最大50,000プロジェクトにアクセスします。
- キーセットベースのページネーションを使用して、50,000以上のプロジェクトをリスト表示します。

詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

```plaintext
GET /projects/:id/invited_groups
```

サポートされている属性:

| 属性                | 型             | 必須 | 説明 |
|:-------------------------|:-----------------|:---------|:------------|
| `id`                     | 整数または文字列   | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `search`                 | 文字列           | いいえ       | 検索条件に一致する認証済みグループのリストを返します。 |
| `min_access_level`       | 整数          | いいえ       | 現在のユーザーが少なくとも指定されたアクセスレベルを持つグループに限定します。使用可能な値: `5` （最小アクセス）、`10` （ゲスト）、`15` （プランナー）、`20` （レポーター）、`25` （セキュリティマネージャー）、`30` （デベロッパー）、`40` （メンテナー）、または`50` （オーナー）。 |
| `relation`               | 文字列の配列 | いいえ       | リレーションでグループをフィルタリングします。指定可能な値: `direct`または`inherited`。 |
| `with_custom_attributes` | ブール値          | いいえ       | `true`の場合、応答に[カスタム属性](custom_attributes.md)を返します。管理者アクセスが必要です。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型 | 説明 |
|:----------|:-----|:------------|
| `id` | 整数 | グループのID。 |
| `web_url` | 文字列 | ブラウザでグループにアクセスするためのURL。 |
| `name` | 文字列 | グループの名前。 |
| `avatar_url` | 文字列 | グループのアバター画像へのURL。 |
| `full_name` | 文字列 | グループの正式名称。 |
| `full_path` | 文字列 | グループのフルパス。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/invited_groups"
```

レスポンス例: 

```json
[
  {
    "id": 35,
    "web_url": "https://gitlab.example.com/groups/twitter",
    "name": "Twitter",
    "avatar_url": null,
    "full_name": "Twitter",
    "full_path": "twitter"
  }
]
```

### プログラミング言語使用状況の情報を取得する {#retrieve-programming-language-usage-information}

指定されたプロジェクトで使用されているすべてのプログラミング言語に関する情報を取得します。

```plaintext
GET /projects/:id/languages
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)とプログラミング言語および使用率のリストを返します。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/languages"
```

レスポンス例: 

```json
{
  "Ruby": 66.69,
  "JavaScript": 22.98,
  "HTML": 7.91,
  "CoffeeScript": 2.42
}
```

## プロジェクトを管理する {#manage-projects}

プロジェクトを管理します（作成、削除、アーカイブなど）。

### プロジェクトを作成する {#create-a-project}

{{< history >}}

- `operations_access_level`はGitLab 16.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/385798)されました。
- `model_registry_access_level`はGitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412734)されました。
- `packages_enabled`はGitLab 17.10で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/454759)になりました。
- `package_registry_access_level`はGitLab 18.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/454759)。

{{< /history >}}

認証済みユーザーが所有するプロジェクトを作成します。

HTTPリポジトリが公開されていない場合は、URL `https://username:password@gitlab.company.com/group/project.git`に認証情報を追加します。ここで、`password`は`api`スコープが有効な公開アクセスキーです。

```plaintext
POST /projects
```

サポートされている一般的なプロジェクトの属性:

| 属性                                          | 型    | 必須                       | 説明 |
|:---------------------------------------------------|:--------|:-------------------------------|:------------|
| `name`                                             | 文字列  | はい（`path`が指定されていない場合） | 新しいプロジェクトの名前。指定されていない場合はパスと等しくなります。 |
| `path`                                             | 文字列  | はい（`name`が指定されていない場合） | 新しいプロジェクトのリポジトリ名。指定されていない場合は、名前に基づいて生成されます（小文字とダッシュを使用して生成）。パスの先頭と末尾には特殊文字を使用できません。また、連続する特殊文字を含めることはできません。 |
| `allow_merge_on_skipped_pipeline`                  | ブール値 | いいえ                             | スキップされたジョブでマージリクエストをマージできるかどうかを設定します。 |
| `approvals_before_merge`                           | 整数 | いいえ                             | デフォルトでマージリクエストを承認する必要がある承認者の数。承認ルールを設定するには、[マージリクエスト承認API](merge_request_approvals.md)を参照してください。GitLab 16.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/353097)になりました。PremiumおよびUltimateのみです。 |
| `auto_cancel_pending_pipelines`                    | 文字列  | いいえ                             | 保留中のパイプラインを自動的にキャンセルします。このアクションは、有効状態と無効状態を切り替えます。ブール値ではありません。 |
| `auto_devops_deploy_strategy`                      | 文字列  | いいえ                             | 自動デプロイ戦略（`continuous`、`manual`、または`timed_incremental`）。 |
| `auto_devops_enabled`                              | ブール値 | いいえ                             | このプロジェクトに対してAuto DevOpsを有効にします。 |
| `autoclose_referenced_issues`                      | ブール値 | いいえ                             | デフォルトブランチで参照されているイシューを自動的にクローズするかどうかを設定します。 |
| `avatar`                                           | 混合   | いいえ                             | プロジェクトのアバターの画像ファイル。 |
| `build_git_strategy`                               | 文字列  | いいえ                             | Git戦略。`fetch`がデフォルトです。 |
| `build_timeout`                                    | 整数 | いいえ                             | ジョブの最大実行可能時間（秒単位）。 |
| `ci_config_path`                                   | 文字列  | いいえ                             | CI設定ファイルへのパス。 |
| `container_expiration_policy_attributes`           | ハッシュ    | いいえ                             | このプロジェクト用のイメージのクリーンアップポリシーを更新します。`cadence`（文字列）、`keep_n`（整数）、`older_than`（文字列）、`name_regex`（文字列）、`name_regex_delete`（文字列）、`name_regex_keep`（文字列）、`enabled`（ブール値）を指定できます。`cadence`、`keep_n`、`older_than`の値の詳細については、[コンテナレジストリ](../user/packages/container_registry/reduce_container_registry_storage.md#use-the-cleanup-policy-api)のドキュメントを参照してください。 |
| `container_registry_enabled`                       | ブール値 | いいえ                             | _（非推奨）_このプロジェクトのコンテナレジストリを有効にします。代わりに`container_registry_access_level`を使用してください。 |
| `default_branch`                                   | 文字列  | いいえ                             | [デフォルトブランチ](../user/project/repository/branches/default.md)名。ブランチ名（例: `main`）または完全修飾参照（例: `refs/heads/main`）を受け入れます。完全修飾参照が提供された場合、APIは`refs/heads/`プレフィックスを削除します。`initialize_with_readme`が`true`である必要があります。 |
| `description`                                      | 文字列  | いいえ                             | プロジェクトの短い説明。 |
| `emails_disabled`                                  | ブール値 | いいえ                             | _（非推奨）_メール通知を無効にします。代わりに`emails_enabled`を使用してください。 |
| `emails_enabled`                                   | ブール値 | いいえ                             | メール通知を有効にします。 |
| `external_authorization_classification_label`      | 文字列  | いいえ                             | プロジェクトの分類ラベル。PremiumおよびUltimateのみです。 |
| `group_runners_enabled`                            | ブール値 | いいえ                             | このプロジェクトのグループRunnerを有効にします。 |
| `group_with_project_templates_id`                  | 整数 | いいえ                             | グループレベルのカスタムテンプレートの場合、すべてのカスタムプロジェクトテンプレートのソースとなるグループのIDを指定します。インスタンスレベルのテンプレートの場合は空のままにします。`use_custom_template`がtrueである必要があります。PremiumおよびUltimateのみです。 |
| `import_url`                                       | 文字列  | いいえ                             | リポジトリのインポート元のURL。URLの値が空でない場合は、`initialize_with_readme`を`true`に設定しないでください。[エラー](https://gitlab.com/gitlab-org/gitlab/-/issues/360266)（`not a git repository`）が発生する可能性があります。 |
| `initialize_with_readme`                           | ブール値 | いいえ                             | `README.md`ファイルのみを使用してGitリポジトリを作成するかどうか。デフォルトは`false`です。このブール値がtrueの場合、`import_url`、またはリポジトリの代替コンテンツを指定するこのエンドポイントの他の属性を渡してはなりません。[エラー](https://gitlab.com/gitlab-org/gitlab/-/issues/360266)（`not a git repository`）が発生する可能性があります。 |
| `issues_enabled`                                   | ブール値 | いいえ                             | _（非推奨）_このプロジェクト用にイシューを有効にします。代わりに`issues_access_level`を使用してください。 |
| `jobs_enabled`                                     | ブール値 | いいえ                             | _（非推奨）_このプロジェクト用にジョブを有効にします。代わりに`builds_access_level`を使用してください。 |
| `lfs_enabled`                                      | ブール値 | いいえ                             | LFSを有効にします。 |
| `merge_method`                                     | 文字列  | いいえ                             | プロジェクトの[マージ方法](../user/project/merge_requests/methods/_index.md)を設定します。`merge`（マージコミット）、`rebase_merge`（半線形履歴を使用するマージコミット）、または`ff`（早送りマージ）を指定できます。 |
| `merge_pipelines_enabled`                          | ブール値 | いいえ                             | マージ結果パイプラインを有効または無効にします。 |
| `merge_requests_enabled`                           | ブール値 | いいえ                             | _（非推奨）_このプロジェクト用にマージリクエストを有効にします。代わりに`merge_requests_access_level`を使用してください。 |
| `merge_trains_enabled`                             | ブール値 | いいえ                             | マージトレインを有効または無効にします。 |
| `merge_trains_skip_train_allowed`                  | ブール値 | いいえ                             | パイプラインが完了するのを待たずに、マージトレインマージリクエストをマージできるようにします。 |
| `mirror_trigger_builds`                            | ブール値 | いいえ                             | プルミラーリングがビルドをトリガーします。PremiumおよびUltimateのみです。 |
| `mirror`                                           | ブール値 | いいえ                             | プロジェクトでプルミラーリングを有効にします。PremiumおよびUltimateのみです。 |
| `namespace_id`                                     | 整数 | いいえ                             | 新しいプロジェクトのネームスペース。グループIDまたはサブグループIDを指定します。指定しない場合、デフォルトで現在のユーザーのパーソナルネームスペースが使用されます。 |
| `only_allow_merge_if_all_discussions_are_resolved` | ブール値 | いいえ                             | すべてのディスカッションが解決された場合にのみマージリクエストをマージできるようにするかどうかを設定します。 |
| `only_allow_merge_if_all_status_checks_passed`     | ブール値 | いいえ                             | すべてのステータスチェックに合格していなければ、マージリクエストのマージをブロックする必要があることを示します。デフォルトはfalseです。機能フラグ`only_allow_merge_if_all_status_checks_passed`をデフォルトで無効にして、GitLab 15.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/369859)されました。Ultimateのみです。 |
| `only_allow_merge_if_pipeline_succeeds`            | ブール値 | いいえ                             | マージリクエストを成功したパイプラインでのみマージできるようにするかどうかを設定します。この設定は、プロジェクト設定で[**パイプラインが完了している**](../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)という名前になります。 |
| `packages_enabled`                                 | ブール値 | いいえ                             | GitLab 17.10で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/454759)になりました。パッケージリポジトリ機能を有効または無効にします。代わりに`package_registry_access_level`を使用してください。 |
| `package_registry_access_level`                    | 文字列  | いいえ                             | パッケージリポジトリ機能を有効または無効にします。 |
| `printing_merge_request_link_enabled`              | ブール値 | いいえ                             | コマンドラインからプッシュするときに、マージリクエストを作成/表示するためのリンクを表示します。 |
| `public_builds`                                    | ブール値 | いいえ                             | _（非推奨）_`true`の場合、プロジェクトメンバー以外のユーザーもジョブを表示できます。代わりに`public_jobs`を使用してください。 |
| `public_jobs`                                      | ブール値 | いいえ                             | `true`の場合、プロジェクトメンバー以外のユーザーもジョブを表示できます。 |
| `repository_object_format`                         | 文字列  | いいえ                             | リポジトリオブジェクト形式。`sha1`がデフォルトです。GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/419887)されました。 |
| `remove_source_branch_after_merge`                 | ブール値 | いいえ                             | すべての新しいマージリクエストに対して、デフォルトで`Delete source branch`オプションを有効にします。 |
| `repository_storage`                               | 文字列  | いいえ                             | リポジトリが存在するストレージシャード。_（管理者のみ）_ |
| `request_access_enabled`                           | ブール値 | いいえ                             | ユーザーがメンバーアクセスをリクエストできるようにします。 |
| `resolve_outdated_diff_discussions`                | ブール値 | いいえ                             | プッシュで変更された行に関するマージリクエスト差分ディスカッションを自動的に解決します。 |
| `shared_runners_enabled`                           | ブール値 | いいえ                             | このプロジェクト用にインスタンスRunnerを有効にします。 |
| `show_default_award_emojis`                        | ブール値 | いいえ                             | デフォルトの絵文字リアクションを表示します。 |
| `snippets_enabled`                                 | ブール値 | いいえ                             | _（非推奨）_このプロジェクト用にスニペットを有効にします。代わりに`snippets_access_level`を使用してください。 |
| `squash_option`                                    | 文字列  | いいえ                             | `never`、`always`、`default_on`、`default_off`のいずれかです。 |
| `tag_list`                                         | 配列   | いいえ                             | プロジェクトのタグのリスト。最終的にプロジェクトに割り当てる必要のあるタグの配列を指定します。GitLab 14.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/328226)になりました。代わりに`topics`を使用してください。 |
| `template_name`                                    | 文字列  | いいえ                             | `use_custom_template`を指定せずに使用する場合は、[組み込みプロジェクトテンプレート](../user/project/_index.md#create-a-project-from-a-built-in-template)の名前。`use_custom_template`とともに使用する場合は、カスタムプロジェクトテンプレートの名前。 |
| `template_project_id`                              | 整数 | いいえ                             | `use_custom_template`とともに使用する場合は、カスタムプロジェクトテンプレートのプロジェクトID。プロジェクトIDを使用する方法は、`template_name`を使用する方法よりも推奨されます。これは、`template_name`はあいまいになる可能性があるためです。PremiumおよびUltimateのみです。 |
| `topics`                                           | 配列   | いいえ                             | プロジェクトのトピックのリスト。最終的にプロジェクトに割り当てる必要のあるトピックの配列を指定します。 |
| `use_custom_template`                              | ブール値 | いいえ                             | カスタム[インスタンス](../administration/custom_project_templates.md)プロジェクトテンプレートまたは[グループ](../user/group/custom_project_templates.md)（`group_with_project_templates_id`付き）プロジェクトテンプレートのいずれかを使用します。PremiumおよびUltimateのみです。 |
| `visibility`                                       | 文字列  | いいえ                             | [プロジェクトの表示レベル](#project-visibility-level)を参照してください。 |
| `warn_about_potentially_unwanted_characters`       | ブール値 | いいえ                             | このプロジェクトで不要である可能性がある文字の使用に関する警告を有効にします。 |
| `wiki_enabled`                                     | ブール値 | いいえ                             | _（非推奨）_このプロジェクト用にWikiを有効にします。代わりに`wiki_access_level`を使用してください。 |

リクエスト例: 

```shell
curl --request POST --header "PRIVATE-TOKEN: <your-token>" \
     --header "Content-Type: application/json" --data '{
        "name": "new_project", "description": "New Project", "path": "new_project",
        "namespace_id": "42", "initialize_with_readme": "true"}' \
     --url "https://gitlab.example.com/api/v4/projects/"
```

個々のプロジェクト機能の表示レベルを設定するには、[Project feature visibility level](#project-feature-visibility-level)を参照してください。

### ユーザーのプロジェクトを作成する {#create-a-project-for-a-user}

{{< history >}}

- `operations_access_level`はGitLab 16.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/385798)されました。
- `model_registry_access_level`はGitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412734)されました。
- `packages_enabled`はGitLab 17.10で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/454759)になりました。
- `package_registry_access_level`はGitLab 18.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/454759)。

{{< /history >}}

ユーザーのためにプロジェクトを作成します。

前提条件: 

- 管理者である必要があります。

HTTPリポジトリが公開されていない場合は、認証情報をURLに追加します。たとえば`https://username:password@gitlab.company.com/group/project.git`の場合、`password`は、`api`スコープが有効になっているパブリックアクセスキーです。

```plaintext
POST /projects/user/:user_id
```

サポートされている一般的なプロジェクトの属性:

| 属性                                          | 型    | 必須 | 説明 |
|:---------------------------------------------------|:--------|:---------|:------------|
| `name`                                             | 文字列  | はい      | 新しいプロジェクトの名前。 |
| `user_id`                                          | 整数 | はい      | プロジェクトオーナーのユーザーID。 |
| `allow_merge_on_skipped_pipeline`                  | ブール値 | いいえ       | スキップされたジョブでマージリクエストをマージできるかどうかを設定します。 |
| `approvals_before_merge`                           | 整数 | いいえ       | デフォルトでマージリクエストを承認する必要がある承認者の数。GitLab 16.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/353097)になりました。承認ルールを設定するには、[マージリクエスト承認API](merge_request_approvals.md)を参照してください。PremiumおよびUltimateのみです。 |
| `auto_cancel_pending_pipelines`                    | 文字列  | いいえ       | 保留中のパイプラインを自動的にキャンセルします。このアクションは、有効状態と無効状態を切り替えます。ブール値ではありません。 |
| `auto_devops_deploy_strategy`                      | 文字列  | いいえ       | 自動デプロイ戦略（`continuous`、`manual`、または`timed_incremental`）。 |
| `auto_devops_enabled`                              | ブール値 | いいえ       | このプロジェクトに対してAuto DevOpsを有効にします。 |
| `autoclose_referenced_issues`                      | ブール値 | いいえ       | デフォルトブランチで参照されているイシューを自動的にクローズするかどうかを設定します。 |
| `avatar`                                           | 混合   | いいえ       | プロジェクトのアバターの画像ファイル。 |
| `build_git_strategy`                               | 文字列  | いいえ       | Git戦略。`fetch`がデフォルトです。 |
| `build_timeout`                                    | 整数 | いいえ       | ジョブの最大実行可能時間（秒単位）。 |
| `ci_config_path`                                   | 文字列  | いいえ       | CI設定ファイルへのパス。 |
| `container_registry_enabled`                       | ブール値 | いいえ       | _（非推奨）_このプロジェクトのコンテナレジストリを有効にします。代わりに`container_registry_access_level`を使用してください。 |
| `default_branch`                                   | 文字列  | いいえ       | [デフォルトブランチ](../user/project/repository/branches/default.md)名。`initialize_with_readme`が`true`である必要があります。 |
| `description`                                      | 文字列  | いいえ       | プロジェクトの短い説明。 |
| `emails_disabled`                                  | ブール値 | いいえ       | _（非推奨）_メール通知を無効にします。代わりに`emails_enabled`を使用してください。 |
| `emails_enabled`                                   | ブール値 | いいえ       | メール通知を有効にします。 |
| `enforce_auth_checks_on_uploads`                   | ブール値 | いいえ       | アップロード時に[認証チェック](../security/user_file_uploads.md#enable-authorization-checks-for-all-media-files)を強制します。 |
| `external_authorization_classification_label`      | 文字列  | いいえ       | プロジェクトの分類ラベル。PremiumおよびUltimateのみです。 |
| `group_runners_enabled`                            | ブール値 | いいえ       | このプロジェクトのグループRunnerを有効にします。 |
| `group_with_project_templates_id`                  | 整数 | いいえ       | グループレベルのカスタムテンプレートの場合、すべてのカスタムプロジェクトテンプレートのソースとなるグループのIDを指定します。インスタンスレベルのテンプレートの場合は空のままにします。`use_custom_template`がtrueである必要があります。PremiumおよびUltimateのみです。 |
| `import_url`                                       | 文字列  | いいえ       | リポジトリのインポート元のURL。 |
| `initialize_with_readme`                           | ブール値 | いいえ       | デフォルトでは`false`です。 |
| `issue_branch_template`                            | 文字列  | いいえ       | [イシューから作成されたブランチ](../user/project/merge_requests/creating_merge_requests.md#from-an-issue)の名前を提案するために使用されるテンプレート。_（GitLab 15.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/21243)されました）_ |
| `issues_enabled`                                   | ブール値 | いいえ       | _（非推奨）_このプロジェクト用にイシューを有効にします。代わりに`issues_access_level`を使用してください。 |
| `jobs_enabled`                                     | ブール値 | いいえ       | _（非推奨）_このプロジェクト用にジョブを有効にします。代わりに`builds_access_level`を使用してください。 |
| `lfs_enabled`                                      | ブール値 | いいえ       | LFSを有効にします。 |
| `merge_commit_template`                            | 文字列  | いいえ       | マージリクエストでマージコミットメッセージを作成するために使用される[テンプレート](../user/project/merge_requests/commit_templates.md)。 |
| `merge_method`                                     | 文字列  | いいえ       | プロジェクトの[マージ方法](../user/project/merge_requests/methods/_index.md)を設定します。`merge`（マージコミット）、`rebase_merge`（半線形履歴を使用するマージコミット）、または`ff`（早送りマージ）を指定できます。 |
| `merge_requests_enabled`                           | ブール値 | いいえ       | _（非推奨）_このプロジェクト用にマージリクエストを有効にします。代わりに`merge_requests_access_level`を使用してください。 |
| `mirror_trigger_builds`                            | ブール値 | いいえ       | プルミラーリングがビルドをトリガーします。PremiumおよびUltimateのみです。 |
| `mirror`                                           | ブール値 | いいえ       | プロジェクトでプルミラーリングを有効にします。PremiumおよびUltimateのみです。 |
| `namespace_id`                                     | 整数 | いいえ       | 新しいプロジェクトのネームスペース（デフォルトは現在のユーザーのネームスペース）。 |
| `only_allow_merge_if_all_discussions_are_resolved` | ブール値 | いいえ       | すべてのディスカッションが解決された場合にのみマージリクエストをマージできるようにするかどうかを設定します。 |
| `only_allow_merge_if_all_status_checks_passed`     | ブール値 | いいえ       | すべてのステータスチェックに合格していなければ、マージリクエストのマージをブロックする必要があることを示します。デフォルトはfalseです。機能フラグ`only_allow_merge_if_all_status_checks_passed`をデフォルトで無効にして、GitLab 15.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/369859)されました。Ultimateのみです。 |
| `only_allow_merge_if_pipeline_succeeds`            | ブール値 | いいえ       | マージリクエストを成功したジョブのみとマージできるようにするかどうかを設定します。 |
| `packages_enabled`                                 | ブール値 | いいえ       | GitLab 17.10で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/454759)になりました。パッケージリポジトリ機能を有効または無効にします。代わりに`package_registry_access_level`を使用してください。 |
| `package_registry_access_level`                    | 文字列  | いいえ       | パッケージリポジトリ機能を有効または無効にします。 |
| `path`                                             | 文字列  | いいえ       | 新しいプロジェクトのカスタムリポジトリ名。デフォルトでは、名前に基づいて生成されます。 |
| `printing_merge_request_link_enabled`              | ブール値 | いいえ       | コマンドラインからプッシュするときに、マージリクエストを作成/表示するためのリンクを表示します。 |
| `public_builds`                                    | ブール値 | いいえ       | _（非推奨）_`true`の場合、プロジェクトメンバー以外のユーザーもジョブを表示できます。代わりに`public_jobs`を使用してください。 |
| `public_jobs`                                      | ブール値 | いいえ       | `true`の場合、プロジェクトメンバー以外のユーザーもジョブを表示できます。 |
| `repository_object_format`                         | 文字列  | いいえ       | リポジトリオブジェクト形式。`sha1`がデフォルトです。GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/419887)されました。 |
| `remove_source_branch_after_merge`                 | ブール値 | いいえ       | すべての新しいマージリクエストに対して、デフォルトで`Delete source branch`オプションを有効にします。 |
| `repository_storage`                               | 文字列  | いいえ       | リポジトリが存在するストレージシャード。_（管理者のみ）_ |
| `request_access_enabled`                           | ブール値 | いいえ       | ユーザーがメンバーアクセスをリクエストできるようにします。 |
| `resolve_outdated_diff_discussions`                | ブール値 | いいえ       | プッシュで変更された行に関するマージリクエスト差分ディスカッションを自動的に解決します。 |
| `shared_runners_enabled`                           | ブール値 | いいえ       | このプロジェクト用にインスタンスRunnerを有効にします。 |
| `show_default_award_emojis`                        | ブール値 | いいえ       | デフォルトの絵文字リアクションを表示します。 |
| `snippets_enabled`                                 | ブール値 | いいえ       | _（非推奨）_このプロジェクト用にスニペットを有効にします。代わりに`snippets_access_level`を使用してください。 |
| `squash_commit_template`                           | 文字列  | いいえ       | マージリクエストでスカッシュコミットメッセージを作成するために使用される[テンプレート](../user/project/merge_requests/commit_templates.md)。 |
| `squash_option`                                    | 文字列  | いいえ       | `never`、`always`、`default_on`、`default_off`のいずれかです。 |
| `suggestion_commit_message`                        | 文字列  | いいえ       | マージリクエストの[提案](../user/project/merge_requests/reviews/suggestions.md)を適用するために使用されるコミットメッセージ。 |
| `tag_list`                                         | 配列   | いいえ       | _（GitLab 14.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/328226)になりました）_プロジェクトのタグのリスト。最終的にプロジェクトに割り当てる必要があるタグの配列を指定します。代わりに`topics`を使用してください。 |
| `template_name`                                    | 文字列  | いいえ       | `use_custom_template`を指定せずに使用する場合は、[組み込みプロジェクトテンプレート](../user/project/_index.md#create-a-project-from-a-built-in-template)の名前。`use_custom_template`とともに使用する場合は、カスタムプロジェクトテンプレートの名前。 |
| `topics`                                           | 配列   | いいえ       | プロジェクトのトピックのリスト。 |
| `use_custom_template`                              | ブール値 | いいえ       | カスタム[インスタンス](../administration/custom_project_templates.md)プロジェクトテンプレートまたは[グループ](../user/group/custom_project_templates.md)（`group_with_project_templates_id`付き）プロジェクトテンプレートのいずれかを使用します。PremiumおよびUltimateのみです。 |
| `visibility`                                       | 文字列  | いいえ       | [プロジェクトの表示レベル](#project-visibility-level)を参照してください。 |
| `warn_about_potentially_unwanted_characters`       | ブール値 | いいえ       | このプロジェクトで不要である可能性がある文字の使用に関する警告を有効にします。 |
| `wiki_enabled`                                     | ブール値 | いいえ       | _（非推奨）_このプロジェクト用にWikiを有効にします。代わりに`wiki_access_level`を使用してください。 |

個々のプロジェクト機能の表示レベルを設定するには、[Project feature visibility level](#project-feature-visibility-level)を参照してください。

### プロジェクトを更新する {#update-a-project}

{{< history >}}

- `operations_access_level`はGitLab 16.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/385798)されました。
- `model_registry_access_level`はGitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412734)されました。
- `packages_enabled`はGitLab 17.10で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/454759)になりました。
- `package_registry_access_level`はGitLab 18.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/454759)。
- `protect_merge_request_pipelines`と`ci_display_pipeline_variables`はGitLab 18.10で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/584488)。

{{< /history >}}

既存のプロジェクトを更新します。

HTTPリポジトリが公開されていない場合は、URL `https://username:password@gitlab.company.com/group/project.git`に認証情報を追加します。ここで、`password`は`api`スコープが有効な公開アクセスキーです。

```plaintext
PUT /projects/:id
```

サポートされている一般的なプロジェクトの属性:

| 属性                                          | 型              | 必須 | 説明 |
|:---------------------------------------------------|:------------------|:---------|:------------|
| `id`                                               | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `allow_merge_on_skipped_pipeline`                  | ブール値           | いいえ       | スキップされたジョブでマージリクエストをマージできるかどうかを設定します。 |
| `allow_pipeline_trigger_approve_deployment`        | ブール値           | いいえ       | パイプラインのトリガー元がデプロイを承認できるかどうかを設定します。PremiumおよびUltimateのみです。 |
| `only_allow_merge_if_all_status_checks_passed`     | ブール値           | いいえ       | すべてのステータスチェックに合格していなければ、マージリクエストのマージをブロックする必要があることを示します。デフォルトはfalseです。<br/><br/>機能フラグ`only_allow_merge_if_all_status_checks_passed`をデフォルトで無効にして、GitLab 15.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/369859)されました。この機能フラグは、GitLab 15.9でデフォルトで有効になりました。Ultimateのみです。 |
| `approvals_before_merge`                           | 整数           | いいえ       | デフォルトでマージリクエストを承認する必要がある承認者の数。GitLab 16.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/353097)になりました。承認ルールを設定するには、[マージリクエスト承認API](merge_request_approvals.md)を参照してください。PremiumおよびUltimateのみです。 |
| `auto_cancel_pending_pipelines`                    | 文字列            | いいえ       | 保留中のパイプラインを自動的にキャンセルします。このアクションは、有効状態と無効状態を切り替えます。ブール値ではありません。 |
| `auto_devops_deploy_strategy`                      | 文字列            | いいえ       | 自動デプロイ戦略（`continuous`、`manual`、または`timed_incremental`）。 |
| `auto_devops_enabled`                              | ブール値           | いいえ       | このプロジェクトに対してAuto DevOpsを有効にします。 |
| `auto_duo_code_review_enabled`                     | ブール値           | いいえ       | マージリクエストでGitLab Duoによる自動レビューを有効にします。[GitLab Duo in merge requests](../user/project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)を参照してください。Ultimateのみです。 |
| `autoclose_referenced_issues`                      | ブール値           | いいえ       | デフォルトブランチで参照されているイシューを自動的にクローズするかどうかを設定します。 |
| `avatar`                                           | 混合             | いいえ       | プロジェクトのアバターの画像ファイル。 |
| `build_git_strategy`                               | 文字列            | いいえ       | Git戦略。`fetch`がデフォルトです。 |
| `build_timeout`                                    | 整数           | いいえ       | ジョブの最大実行可能時間（秒単位）。 |
| `ci_config_path`                                   | 文字列            | いいえ       | CI設定ファイルへのパス。 |
| `ci_default_git_depth`                             | 整数           | いいえ       | [シャロークローン](../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone)のリビジョンのデフォルト数。 |
| `ci_delete_pipelines_in_seconds`                   | 整数           | いいえ       | 設定された時刻よりも前のパイプラインは削除されます。 |
| `ci_display_pipeline_variables`                    | ブール値           | いいえ       | 手動でパイプラインを実行した後、パイプライン詳細ページに手動で定義されたすべての変数を表示します。 |
| `ci_forward_deployment_enabled`                    | ブール値           | いいえ       | [古いデプロイジョブを防止](../ci/pipelines/settings.md#prevent-outdated-deployment-jobs)を有効または無効にします。 |
| `ci_forward_deployment_rollback_allowed`           | ブール値           | いいえ       | [ロールバックデプロイのジョブの再試行を許可する](../ci/pipelines/settings.md#prevent-outdated-deployment-jobs)を有効または無効にします。 |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | ブール値           | いいえ       | [フォークからのマージリクエストに対して親プロジェクトでパイプラインを実行する](../ci/pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project)を有効または無効にします。_（GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/325189)されました）_ |
| `ci_id_token_sub_claim_components`                 | 配列             | いいえ       | [IDトークン](../ci/secrets/id_token_authentication.md)の`sub`クレームに含まれるフィールド。`project_path`で始まる配列を指定できます。配列には、`ref_type`、`ref`、`ref_protected`、`environment_protected`、および`deployment_tier`も含まれる場合があります。`["project_path", "ref_type", "ref"]`がデフォルトです。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/477260)されました。`environment_protected`と`deployment_tier`のサポートはGitLab 18.7で導入されました。 |
| `ci_separated_caches`                              | ブール値           | いいえ       | キャッシュをブランチの保護状態に応じて[分離](../ci/caching/_index.md#cache-key-names)するかどうかを設定します。 |
| `ci_restrict_pipeline_cancellation_role`           | 文字列            | いいえ       | [パイプラインまたはジョブをキャンセルするために必要なロール](../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs)を設定します。`developer`、`maintainer`、`no_one`のいずれかです。GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429921)されました。PremiumおよびUltimateのみです。 |
| `ci_pipeline_variables_minimum_override_role`      | 文字列            | いいえ       | 変数をオーバーライドできるロールを指定できます。`owner`、`maintainer`、`developer`、`no_one_allowed`のいずれかです。GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440338)されました。GitLab 17.1～17.7では、`restrict_user_defined_variables`を有効にする必要があります。 |
| `ci_push_repository_for_job_token_allowed`         | ブール値           | いいえ       | ジョブトークンを使用してプロジェクトリポジトリにプロジェクトをプッシュする機能を有効または無効にします。GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/389060)されました。 |
| `container_expiration_policy_attributes`           | ハッシュ              | いいえ       | このプロジェクト用のイメージのクリーンアップポリシーを更新します。`cadence`（文字列）、`keep_n`（整数）、`older_than`（文字列）、`name_regex`（文字列）、`name_regex_delete`（文字列）、`name_regex_keep`（文字列）、`enabled`（ブール値）を指定できます。 |
| `container_registry_enabled`                       | ブール値           | いいえ       | _（非推奨）_このプロジェクトのコンテナレジストリを有効にします。代わりに`container_registry_access_level`を使用してください。 |
| `default_branch`                                   | 文字列            | いいえ       | [デフォルトブランチ](../user/project/repository/branches/default.md)名。 |
| `description`                                      | 文字列            | いいえ       | プロジェクトの短い説明。 |
| `duo_remote_flows_enabled`                         | ブール値           | いいえ       | プロジェクトで[フロー](../user/duo_agent_platform/flows/_index.md)を実行できるかどうかを決定します。 |
| `emails_disabled`                                  | ブール値           | いいえ       | _（非推奨）_メール通知を無効にします。代わりに`emails_enabled`を使用してください。 |
| `emails_enabled`                                   | ブール値           | いいえ       | メール通知を有効にします。 |
| `enforce_auth_checks_on_uploads`                   | ブール値           | いいえ       | アップロード時に[認証チェック](../security/user_file_uploads.md#enable-authorization-checks-for-all-media-files)を強制します。 |
| `external_authorization_classification_label`      | 文字列            | いいえ       | プロジェクトの分類ラベル。PremiumおよびUltimateのみです。 |
| `group_runners_enabled`                            | ブール値           | いいえ       | このプロジェクトのグループRunnerを有効にします。 |
| `import_url`                                       | 文字列            | いいえ       | リポジトリのインポート元URL。 |
| `issues_enabled`                                   | ブール値           | いいえ       | _（非推奨）_このプロジェクト用にイシューを有効にします。代わりに`issues_access_level`を使用してください。 |
| `issues_template` | 文字列 | いいえ | 新しいイシューのデフォルトの説明。GitLab Flavored Markdownとしてフォーマットされます。PremiumおよびUltimateのみです。 |
| `merge_requests_template` | 文字列 | いいえ | 新しいマージリクエストのデフォルトの説明。GitLab Flavored Markdownとしてフォーマットされます。PremiumおよびUltimateのみです。 |
| `jobs_enabled`                                     | ブール値           | いいえ       | _（非推奨）_このプロジェクト用にジョブを有効にします。代わりに`builds_access_level`を使用してください。 |
| `keep_latest_artifact`                             | ブール値           | いいえ       | このプロジェクトの最新のアーティファクトを保持する機能を無効または有効にします。 |
| `lfs_enabled`                                      | ブール値           | いいえ       | LFSを有効にします。 |
| `max_artifacts_size`                               | 整数           | いいえ       | 個々のジョブアーティファクトの最大ファイルサイズ（MB単位）。 |
| `merge_commit_template`                            | 文字列            | いいえ       | マージリクエストでマージコミットメッセージを作成するために使用される[テンプレート](../user/project/merge_requests/commit_templates.md)。 |
| `merge_method`                                     | 文字列            | いいえ       | プロジェクトの[マージ方法](../user/project/merge_requests/methods/_index.md)を設定します。`merge`（マージコミット）、`rebase_merge`（半線形履歴を使用するマージコミット）、または`ff`（早送りマージ）を指定できます。 |
| `merge_pipelines_enabled`                          | ブール値           | いいえ       | マージ結果パイプラインを有効または無効にします。 |
| `merge_requests_enabled`                           | ブール値           | いいえ       | _（非推奨）_このプロジェクト用にマージリクエストを有効にします。代わりに`merge_requests_access_level`を使用してください。 |
| `merge_trains_enabled`                             | ブール値           | いいえ       | マージトレインを有効または無効にします。 |
| `merge_trains_skip_train_allowed`                  | ブール値           | いいえ       | パイプラインが完了するのを待たずに、マージトレインマージリクエストをマージできるようにします。 |
| `mirror_overwrites_diverged_branches`              | ブール値           | いいえ       | プルミラーが、分岐したブランチを上書きします。PremiumおよびUltimateのみです。 |
| `mirror_trigger_builds`                            | ブール値           | いいえ       | プルミラーリングがビルドをトリガーします。PremiumおよびUltimateのみです。 |
| `mirror_user_id`                                   | 整数           | いいえ       | プルミラーイベントに関連するすべてのアクティビティを担当するユーザー。_（管理者のみ）_PremiumとUltimateプランのみ。 |
| `mirror`                                           | ブール値           | いいえ       | プロジェクトでプルミラーリングを有効にします。PremiumおよびUltimateのみです。 |
| `mr_default_target_self`                           | ブール値           | いいえ       | フォークされたプロジェクトの場合、マージリクエストのターゲットをこのプロジェクトに設定します。`false`の場合、ターゲットはアップストリームプロジェクトになります。 |
| `name`                                             | 文字列            | いいえ       | プロジェクト名。 |
| `only_allow_merge_if_all_discussions_are_resolved` | ブール値           | いいえ       | すべてのディスカッションが解決された場合にのみマージリクエストをマージできるようにするかどうかを設定します。 |
| `only_allow_merge_if_pipeline_succeeds`            | ブール値           | いいえ       | マージリクエストを成功したジョブのみとマージできるようにするかどうかを設定します。 |
| `only_mirror_protected_branches`                   | ブール値           | いいえ       | 保護ブランチのみをミラーリングします。PremiumおよびUltimateのみです。 |
| `packages_enabled`                                 | ブール値           | いいえ       | GitLab 17.10で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/454759)になりました。パッケージリポジトリ機能を有効または無効にします。代わりに`package_registry_access_level`を使用してください。 |
| `package_registry_access_level`                    | 文字列  | いいえ                 | パッケージリポジトリ機能を有効または無効にします。 |
| `path`                                             | 文字列            | いいえ       | プロジェクトのカスタムリポジトリ名。デフォルトでは、名前に基づいて生成されます。 |
| `prevent_merge_without_jira_issue`                 | ブール値           | いいえ       | マージリクエストで、Jiraからの関連イシューを必須にするかどうかを設定します。Ultimateのみです。 |
| `printing_merge_request_link_enabled`              | ブール値           | いいえ       | コマンドラインからプッシュするときに、マージリクエストを作成/表示するためのリンクを表示します。 |
| `protect_merge_request_pipelines`                  | ブール値           | いいえ       | [control access to protected variables and runners](../ci/pipelines/merge_request_pipelines.md#control-access-to-protected-variables-and-runners)を有効または無効にします。 |
| `public_builds`                                    | ブール値           | いいえ       | _（非推奨）_`true`の場合、プロジェクトメンバー以外のユーザーもジョブを表示できます。代わりに`public_jobs`を使用してください。 |
| `public_jobs`                                      | ブール値           | いいえ       | `true`の場合、プロジェクトメンバー以外のユーザーもジョブを表示できます。 |
| `remove_source_branch_after_merge`                 | ブール値           | いいえ       | すべての新しいマージリクエストに対して、デフォルトで`Delete source branch`オプションを有効にします。 |
| `repository_storage`                               | 文字列            | いいえ       | リポジトリが存在するストレージシャード。_（管理者のみ）_ |
| `request_access_enabled`                           | ブール値           | いいえ       | ユーザーがメンバーアクセスをリクエストできるようにします。 |
| `resolve_outdated_diff_discussions`                | ブール値           | いいえ       | プッシュで変更された行に関するマージリクエスト差分ディスカッションを自動的に解決します。 |
| `restrict_user_defined_variables`                  | ブール値           | いいえ       | _（GitLab 17.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154510)となり、`ci_pipeline_variables_minimum_override_role`が推奨されます）_パイプラインをトリガーするときに、メンテナーロールを持つユーザーのみがユーザー定義変数を渡せるようにします。たとえば、UIで、APIを使用して、またはトリガートークンにより、パイプラインがトリガーされる場合などです。 |
| `service_desk_enabled`                             | ブール値           | いいえ       | サービスデスク機能を有効または無効にします。 |
| `shared_runners_enabled`                           | ブール値           | いいえ       | このプロジェクト用にインスタンスRunnerを有効にします。 |
| `show_default_award_emojis`                        | ブール値           | いいえ       | デフォルトの絵文字リアクションを表示します。 |
| `snippets_enabled`                                 | ブール値           | いいえ       | _（非推奨）_このプロジェクト用にスニペットを有効にします。代わりに`snippets_access_level`を使用してください。 |
| `issue_branch_template`                            | 文字列            | いいえ       | [イシューから作成されたブランチ](../user/project/merge_requests/creating_merge_requests.md#from-an-issue)の名前を提案するために使用されるテンプレート。_（GitLab 15.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/21243)されました）_ |
| `spp_repository_pipeline_access`                   | ブール値           | いいえ       | ユーザーとトークンに、このプロジェクトからセキュリティポリシーの設定をフェッチするための読み取り専用アクセスを許可します。このプロジェクトをセキュリティポリシーソースとして使用するプロジェクトで、セキュリティポリシーを適用するために必要です。Ultimateのみです。 |
| `squash_commit_template`                           | 文字列            | いいえ       | マージリクエストでスカッシュコミットメッセージを作成するために使用される[テンプレート](../user/project/merge_requests/commit_templates.md)。 |
| `squash_option`                                    | 文字列            | いいえ       | `never`、`always`、`default_on`、`default_off`のいずれかです。 |
| `suggestion_commit_message`                        | 文字列            | いいえ       | マージリクエストの提案を適用するために使用されるコミットメッセージ。 |
| `tag_list`                                         | 配列             | いいえ       | _（GitLab 14.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/328226)になりました）_プロジェクトのタグのリスト。最終的にプロジェクトに割り当てる必要があるタグの配列を指定します。代わりに`topics`を使用してください。 |
| `topics`                                           | 配列             | いいえ       | プロジェクトのトピックのリスト。これにより、プロジェクトにすでに追加されている既存のトピックがすべて置き換えられます。 |
| `visibility`                                       | 文字列            | いいえ       | [プロジェクトの表示レベル](#project-visibility-level)を参照してください。 |
| `warn_about_potentially_unwanted_characters`       | ブール値           | いいえ       | このプロジェクトで不要である可能性がある文字の使用に関する警告を有効にします。 |
| `wiki_enabled`                                     | ブール値           | いいえ       | _（非推奨）_このプロジェクト用にWikiを有効にします。代わりに`wiki_access_level`を使用してください。 |
| `web_based_commit_signing_enabled`                 | ブール値           | いいえ       | GitLab UIから作成されたコミットのWebベースのコミット署名を有効にします。GitLab.comでのみ利用可能です。 |

たとえば、[GitLab.comプロジェクトのインスタンスRunner](../ci/runners/_index.md)の設定を切り替えるには、次のようにします。

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your-token>" \
     --url "https://gitlab.com/api/v4/projects/<your-project-ID>" \
     --data "shared_runners_enabled=true" # to turn off: "shared_runners_enabled=false"
```

個々のプロジェクト機能の表示レベルを設定するには、[Project feature visibility level](#project-feature-visibility-level)を参照してください。

### メンバーをインポートする {#import-members}

別のプロジェクトからメンバーをインポートします。

ターゲットプロジェクトに対するインポートメンバーのロールによって、次のようになります。

- メンテナーの場合、ソースプロジェクトのオーナーロールを持つメンバーは、メンテナーロールでインポートされます。
- オーナーの場合、ソースプロジェクトのオーナーロールを持つメンバーは、オーナーロールでインポートされます。

```plaintext
POST /projects/:id/import_project_members/:project_id
```

サポートされている属性:

| 属性    | 型              | 必須 | 説明 |
|:-------------|:------------------|:---------|:------------|
| `id`         | 整数または文字列 | はい      | メンバーを受け入れるターゲットプロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `project_id` | 整数または文字列 | はい      | メンバーのインポート元のソースプロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/import_project_members/32"
```

戻り値:

- 成功した場合は`200 OK`。
- ターゲットプロジェクトまたはソースプロジェクトが存在しないか、リクエスタがアクセスできない場合は、`404 Project Not Found`。
- プロジェクトメンバーのインポートが正常に完了しなかった場合は、`422 Unprocessable Entity`。

レスポンス例:

- すべてのメールが正常に送信された場合（HTTPステータスコード`200`）:

  ```json
  {  "status":  "success"  }
  ```

- 1つ以上のメンバーのインポートでエラーが発生した場合（HTTPステータスコード`200`）:

  ```json
  {
    "status": "error",
    "message": {
                 "john_smith": "Some individual error message",
                 "jane_smith": "Some individual error message"
               },
    "total_members_count": 3
  }
  ```

- システムエラーが発生した場合（HTTPステータスコード`404`および`422`）:

```json
{  "message":  "Import failed"  }
```

### プロジェクトをアーカイブする {#archive-a-project}

指定されたプロジェクトをアーカイブします。

前提条件: 

- 管理者であるか、プロジェクトのオーナーロールが割り当てられている必要があります。

このエンドポイントはべき等です。すでにアーカイブされているプロジェクトをアーカイブしても、プロジェクトは変更されません。

```plaintext
POST /projects/:id/archive
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/archive"
```

レスポンス例: 

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "repository_object_format": "sha1",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora"
  },
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": true,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "ci_display_pipeline_variables": false,
  "protect_merge_request_pipelines": true,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "allow_pipeline_trigger_approve_deployment": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "autoclose_referenced_issues": true,
  "enforce_auth_checks_on_uploads": true,
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "secret_push_protection_enabled": false,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

### プロジェクトのアーカイブを解除する {#unarchive-a-project}

指定されたプロジェクトのアーカイブを解除します。

前提条件: 

- 管理者であるか、プロジェクトのオーナーロールが割り当てられている必要があります。

このエンドポイントはべき等です。アーカイブされていないプロジェクトのアーカイブを解除しても、プロジェクトは変更されません。

```plaintext
POST /projects/:id/unarchive
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/unarchive"
```

レスポンス例: 

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "repository_object_format": "sha1",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora"
  },
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": false,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_id_token_sub_claim_components": ["project_path", "ref_type", "ref"],
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "ci_display_pipeline_variables": false,
  "protect_merge_request_pipelines": true,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "allow_pipeline_trigger_approve_deployment": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "autoclose_referenced_issues": true,
  "enforce_auth_checks_on_uploads": true,
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "secret_push_protection_enabled": false,
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

### プロジェクトを削除する {#delete-a-project}

{{< history >}}

- GitLab 16.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/389557)になりました。PremiumおよびUltimateのみです。
- GitLab 18.0で、GitLab PremiumからGitLab Freeに[移行](https://gitlab.com/groups/gitlab-org/-/epics/17208)しました。

{{< /history >}}

前提条件: 

- 管理者であるか、プロジェクトのオーナーロールを持っている必要があります。

プロジェクトを削除対象としてマークします。プロジェクトは保持期間の終了時に削除されます:

- GitLab.comでは、プロジェクトは30日間保持されます。
- GitLab Self-Managedでは、保持期間は[インスタンスの設定](../administration/settings/visibility_and_access_controls.md#deletion-protection)によって制御されます。

このエンドポイントは、以前に削除対象としてマークされていたプロジェクトを即座に削除することもできます。

> [!warning] 
> GitLab.comでは、プロジェクトが削除された後、そのデータは30日間保持され、永続的な削除はできません。GitLab.comでプロジェクトを本当に即座に削除する必要がある場合、[サポートチケット](https://about.gitlab.com/support/)を開くことができます。

```plaintext
DELETE /projects/:id
```

サポートされている属性:

| 属性            | 型              | 必須 | 説明 |
|:---------------------|:------------------|:---------|:------------|
| `id`                 | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `full_path`          | 文字列            | いいえ       | `permanently_remove`で使用するプロジェクトのフルパス。GitLab 15.11でPremiumおよびUltimate限定で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/396500)され、18.0でGitLab Freeに移行されました。プロジェクトパスを確認するには、[単一プロジェクトの取得](projects.md#retrieve-a-project)の`path_with_namespace`を使用します。 |
| `permanently_remove` | ブール値/文字列    | いいえ       | 削除対象としてマークされているプロジェクトを即時削除します。GitLab 15.11でPremiumおよびUltimate限定で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/396500)され、18.0でGitLab Freeに移行されました。GitLab.comおよびDedicatedでは無効になっています。 |

### 削除対象としてマークされているプロジェクトを復元する {#restore-a-project-marked-for-deletion}

削除対象としてマークされていた指定されたプロジェクトを復元します。

```plaintext
POST /projects/:id/restore
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

### プロジェクトを新しいネームスペースに転送する {#transfer-a-project-to-a-new-namespace}

プロジェクトを新しいネームスペースに転送します。

プロジェクトの転送に必要な前提条件については、[プロジェクトを別のネームスペースに転送](../user/project/working_with_projects.md#transfer-a-project)を参照してください。

```plaintext
PUT /projects/:id/transfer
```

サポートされている属性:

| 属性   | 型              | 必須 | 説明 |
|:------------|:------------------|:---------|:------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `namespace` | 整数または文字列 | はい      | プロジェクトの転送先のネームスペースのIDまたはパス。 |

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/transfer?namespace=14"
```

レスポンス例: 

```json
  {
  "id": 7,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "name": "hello-world",
  "name_with_namespace": "cute-cats / hello-world",
  "path": "hello-world",
  "path_with_namespace": "cute-cats/hello-world",
  "created_at": "2020-10-15T16:25:22.415Z",
  "updated_at": "2020-10-15T16:25:22.415Z",
  "default_branch": "main",
  "tag_list": [], //deprecated, use `topics` instead
  "topics": [],
  "ssh_url_to_repo": "git@gitlab.example.com:cute-cats/hello-world.git",
  "http_url_to_repo": "https://gitlab.example.com/cute-cats/hello-world.git",
  "web_url": "https://gitlab.example.com/cute-cats/hello-world",
  "readme_url": "https://gitlab.example.com/cute-cats/hello-world/-/blob/main/README.md",
  "avatar_url": null,
  "forks_count": 0,
  "star_count": 0,
  "last_activity_at": "2020-10-15T16:25:22.415Z",
  "namespace": {
    "id": 18,
    "name": "cute-cats",
    "path": "cute-cats",
    "kind": "group",
    "full_path": "cute-cats",
    "parent_id": null,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/cute-cats"
  },
  "container_registry_image_prefix": "registry.example.com/cute-cats/hello-world",
  "_links": {
    "self": "https://gitlab.example.com/api/v4/projects/7",
    "issues": "https://gitlab.example.com/api/v4/projects/7/issues",
    "merge_requests": "https://gitlab.example.com/api/v4/projects/7/merge_requests",
    "repo_branches": "https://gitlab.example.com/api/v4/projects/7/repository/branches",
    "labels": "https://gitlab.example.com/api/v4/projects/7/labels",
    "events": "https://gitlab.example.com/api/v4/projects/7/events",
    "members": "https://gitlab.example.com/api/v4/projects/7/members"
  },
  "packages_enabled": true, // deprecated, use package_registry_access_level instead
  "package_registry_access_level": "enabled",
  "empty_repo": false,
  "archived": false,
  "visibility": "private",
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": true, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "enabled",
  "container_expiration_policy": {
    "cadence": "7d",
    "enabled": false,
    "keep_n": null,
    "older_than": null,
    "name_regex": null,
    "name_regex_keep": null,
    "next_run_at": "2020-10-22T16:25:22.746Z"
  },
  "issues_enabled": true,
  "merge_requests_enabled": true,
  "wiki_enabled": true,
  "jobs_enabled": true,
  "snippets_enabled": true,
  "service_desk_enabled": false,
  "service_desk_address": null,
  "can_create_merge_request_in": true,
  "issues_access_level": "enabled",
  "repository_access_level": "enabled",
  "merge_requests_access_level": "enabled",
  "forking_access_level": "enabled",
  "analytics_access_level": "enabled",
  "wiki_access_level": "enabled",
  "builds_access_level": "enabled",
  "snippets_access_level": "enabled",
  "pages_access_level": "enabled",
  "security_and_compliance_access_level": "enabled",
  "emails_disabled": null,
  "emails_enabled": null,
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "lfs_enabled": true,
  "creator_id": 2,
  "import_status": "none",
  "open_issues_count": 0,
  "ci_default_git_depth": 50,
  "public_jobs": true,
  "build_timeout": 3600,
  "auto_cancel_pending_pipelines": "enabled",
  "ci_config_path": null,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": null,
  "allow_pipeline_trigger_approve_deployment": false,
  "restrict_user_defined_variables": false,
  "request_access_enabled": true,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": true,
  "printing_merge_request_link_enabled": true,
  "merge_method": "merge",
  "squash_option": "default_on",
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "auto_devops_enabled": true,
  "auto_devops_deploy_strategy": "continuous",
  "autoclose_referenced_issues": true,
  "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
  "mirror": false,
  "compliance_frameworks": [],
  "warn_about_potentially_unwanted_characters": true,
  "secret_push_protection_enabled": false
}
```

#### プロジェクト転送に利用可能なグループのリストを取得する {#list-groups-available-for-project-transfer}

ユーザーがプロジェクトを転送できる転送先グループのリストを取得します。

```plaintext
GET /projects/:id/transfer_locations
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `search`  | 文字列            | いいえ       | 検索するグループ名。 |

リクエスト例: 

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/transfer_locations"
```

レスポンス例: 

```json
[
  {
    "id": 27,
    "web_url": "https://gitlab.example.com/groups/gitlab",
    "name": "GitLab",
    "avatar_url": null,
    "full_name": "GitLab",
    "full_path": "GitLab"
  },
  {
    "id": 31,
    "web_url": "https://gitlab.example.com/groups/foobar",
    "name": "FooBar",
    "avatar_url": null,
    "full_name": "FooBar",
    "full_path": "FooBar"
  }
]
```

### プロジェクトアバターをアップロードする {#upload-a-project-avatar}

指定されたプロジェクトにアバターをアップロードします。

```plaintext
PUT /projects/:id
```

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。
- ファイルのサイズは200 KB以下である必要があります。理想的な画像サイズは192 x 192ピクセルです。
- 画像は、次のいずれかのファイル形式である必要があります。
  - `.bmp`
  - `.gif`
  - `.ico`
  - `.jpeg`
  - `.png`
  - `.tiff`

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `avatar`  | 文字列            | はい      | アップロードするファイル。 |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

ファイルシステムからアバターをアップロードするには、`--form`引数を使用します。これにより、cURLはヘッダー`Content-Type: multipart/form-data`を使用してデータを送信します。`avatar=`パラメータは、ファイルシステムの画像ファイルを指しており、先頭に`@`を付ける必要があります。

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5" \
  --form "avatar=@dk.png"
```

レスポンス例: 

```json
{
  "avatar_url": "https://gitlab.example.com/uploads/-/system/project/avatar/2/dk.png"
}
```

### プロジェクトアバターをダウンロードする {#download-a-project-avatar}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144039)されました。

{{< /history >}}

プロジェクトのアバターをダウンロードします。プロジェクトが公開されている場合、このエンドポイントには認証なしでアクセスできます。

```plaintext
GET /projects/:id/avatar
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/avatar"
```

### プロジェクトアバターを削除する {#remove-a-project-avatar}

プロジェクトアバターを削除するには、`avatar`属性に空白の値を指定します。

リクエスト例: 

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "avatar=" "https://gitlab.example.com/api/v4/projects/5"
```

## プロジェクトを共有する {#share-projects}

プロジェクトをグループと共有します。

詳細については、[Invite a group to a project](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)を参照してください。

### プロジェクトをグループと共有する {#share-a-project-with-a-group}

指定されたプロジェクトをグループと共有します。

```plaintext
POST /projects/:id/share
```

サポートされている属性:

| 属性      | 型              | 必須 | 説明 |
|:---------------|:------------------|:---------|:------------|
| `group_access` | 整数           | はい      | グループに付与するアクセスレベル。使用可能な値: `5` （最小アクセス）、`10` （ゲスト）、`15` （プランナー）、`20` （レポーター）、`25` （セキュリティマネージャー）、`30` （デベロッパー）、`40` （メンテナー）、または`50` （オーナー）。 |
| `group_id`     | 整数           | はい      | 共有するグループのID。 |
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `expires_at`   | 文字列            | いいえ       | ISO 8601形式での共有有効期限。例: `2016-09-26`。 |

### グループ内の共有プロジェクトリンクを削除する {#delete-a-shared-project-link-in-a-group}

指定されたグループとのプロジェクトの共有を解除します。成功すると`204`が返されますが、コンテンツは返されません。

```plaintext
DELETE /projects/:id/share/:group_id
```

サポートされている属性:

| 属性  | 型              | 必須 | 説明 |
|:-----------|:------------------|:---------|:------------|
| `group_id` | 整数           | はい      | グループのID。 |
| `id`       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/share/17"
```

## プロジェクトのハウスキーピングタスクを開始する {#start-the-housekeeping-task-for-a-project}

プロジェクトの[ハウスキーピングタスク](../administration/housekeeping.md)を開始します。

```plaintext
POST /projects/:id/housekeeping
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `task`    | 文字列            | いいえ       | 到達不能なオブジェクトの手動プルーニングをトリガーする場合は`prune`、積極的なハウスキーピングをトリガーする場合は`eager`。 |

## リアルタイムセキュリティスキャン {#real-time-security-scan}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/479210)されました。これは[実験的機能](../policy/development_stages_support.md)です。

{{< /history >}}

リアルタイムで1つのファイルのSASTスキャン結果を返します。

```plaintext
POST /projects/:id/security_scans/sast/scan
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
 --header "Content-Type: application/json" \
 --data '{
  "file_path":"src/main.c",
  "content":"#include<string.h>\nint main(int argc, char **argv) {\n  char buff[128];\n  strcpy(buff, argv[1]);\n  return 0;\n}\n"
 }' \
 --url "https://gitlab.example.com/api/v4/projects/:id/security_scans/sast/scan"
```

レスポンス例: 

```json
{
  "vulnerabilities": [
    {
      "name": "Insecure string processing function (strcpy)",
      "description": "The `strcpy` family of functions do not provide the ability to limit or check buffer\nsizes before copying to a destination buffer. This can lead to buffer overflows. Consider\nusing more secure alternatives such as `strncpy` and provide the correct limit to the\ndestination buffer and ensure the string is null terminated.\n\nFor more information please see: https://linux.die.net/man/3/strncpy\n\nIf developing for C Runtime Library (CRT), more secure versions of these functions should be\nused, see:\nhttps://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/strncpy-s-strncpy-s-l-wcsncpy-s-wcsncpy-s-l-mbsncpy-s-mbsncpy-s-l?view=msvc-170\n",
      "severity": "High",
      "location": {
        "file": "src/main.c",
        "start_line": 5,
        "end_line": 5,
        "start_column": 3,
        "end_column": 23
      }
    }
  ]
}
```

## Gitリポジトリのスナップショットをダウンロードする {#download-snapshot-of-a-git-repository}

このエンドポイントには、管理者のみがアクセスできます。

プロジェクトのスナップショット（リクエストされた場合はWiki）のGitリポジトリをダウンロードします。このスナップショットは、常に非圧縮の[tar](https://en.wikipedia.org/wiki/Tar_(computing))形式です。

リポジトリが破損して`git clone`が機能しない場合でも、スナップショットを使用すると、一部のデータを取得できる場合があります。

```plaintext
GET /projects/:id/snapshot
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `wiki`    | ブール値           | いいえ       | プロジェクトリポジトリではなく、Wikiをダウンロードするかどうか。 |

## リポジトリストレージへのパスを取得する {#retrieve-the-path-to-repository-storage}

指定されたプロジェクトのリポジトリストレージへのパスを取得します。Gitaly Cluster (Praefect)を使用している場合は、代わりに[Praefectによって生成されたレプリカパス](../administration/gitaly/praefect/_index.md#praefect-generated-replica-paths)を参照してください。

管理者のみが利用できます。

```plaintext
GET /projects/:id/storage
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```json
[
  {
    "project_id": 1,
    "disk_path": "@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b",
    "created_at": "2012-10-12T17:04:47Z",
    "repository_storage": "default"
  }
]
```

## シークレットプッシュ保護のステータス {#secret-push-protection-status}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160960)されました。
- GitLab 17.11で`setPreReceiveSecretDetection`から[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186602)。

{{< /history >}}

セキュリティマネージャー、デベロッパー、メンテナー、またはオーナーロールを持つ場合、以下のリクエストでも`secret_push_protection_enabled`の値を返すことができます。これらのリクエストの一部には、ロールに関するより厳格な要件があります。詳細については、前述のエンドポイントを参照してください。この情報を使用して、プロジェクトに対してシークレットプッシュ保護が有効になっているかどうかを判断します。`secret_push_protection_enabled`の値を変更するには、[プロジェクトセキュリティ設定API](project_security_settings.md)を使用してください。

- `GET /projects`
- `GET /projects/:id`
- `GET /users/:user_id/projects`
- `GET /users/:user_id/contributed_projects`
- `PUT /projects/:project_id/transfer?namespace=:namespace_id`
- `PUT /projects/:id`
- `POST /projects`
- `POST /projects/user/:user_id`
- `POST /projects/:id/archive`
- `POST /projects/:id/unarchive`

レスポンス例: 

```json
{
  "id": 1,
  "project_id": 3,
  "secret_push_protection_enabled": true,
  ...
}
```

## トラブルシューティング {#troubleshooting}

### 応答の予期しない`restrict_user_defined_variables`値 {#unexpected-restrict_user_defined_variables-value-in-response}

`restrict_user_defined_variables`と`ci_pipeline_variables_minimum_override_role`に競合する値を設定すると、`pipeline_variables_minimum_override_role`設定の方が優先順位が高いため、応答の値が予期される値と異なる場合があります。

たとえば、次のような場合が該当します。

- `restrict_user_defined_variables`を`true`、`ci_pipeline_variables_minimum_override_role`を`developer`に設定すると、応答は`restrict_user_defined_variables: false`を返します。`ci_pipeline_variables_minimum_override_role`を`developer`に設定すると、優先され、変数は制限されません。
- `restrict_user_defined_variables`を`false`、`ci_pipeline_variables_minimum_override_role`を`maintainer`に設定すると、応答は`restrict_user_defined_variables: true`を返します。`ci_pipeline_variables_minimum_override_role`を`maintainer`に設定すると優先され、変数が制限されるためです。
