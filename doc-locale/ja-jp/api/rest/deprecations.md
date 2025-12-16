---
stage: Developer Experience
group: API
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: REST APIの非推奨化
description: "GitLab REST APIで非推奨になったフィールドと計画されている破壊的な変更の一覧。"
---

以下の非推奨を定期的に確認し、推奨される変更を加えてください。これらの非推奨は、多くの場合、API機能の改善を示しており、機能に新しいフィールドまたはエンドポイントを使用することを推奨しています。

一部の非推奨ではv5 REST APIについて言及されていますが、v5 REST APIの開発はアクティブではありません。[GitLabは、REST APIのセマンティックバージョニングに従うことをコミットしている](_index.md#versioning-and-deprecations)ため、これらの変更をREST API v4内で行うことはありません。

## `geo_nodes` APIエンドポイント {#geo_nodes-api-endpoints}

破壊的な変更[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/369140)を参照してください。

[`geo_nodes` APIエンドポイント](../geo_nodes.md)は非推奨となり、[`geo_sites`](../geo_sites.md)に置き換えられました。これは、[Geoデプロイの参照方法](../../administration/geo/glossary.md)に関するグローバルな変更の一部です。ノードは、アプリケーション全体でサイトに名前が変更されました。両方のエンドポイントの機能は同じままです。

## `merged_by` APIフィールド {#merged_by-api-field}

破壊的な変更[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/350534)を参照してください。

[マージリクエストAPI](../merge_requests.md#list-merge-requests)の`merged_by`フィールドは、単純なマージ以外の操作（自動マージの設定、マージトレインへの追加）を実行する際に、誰がマージリクエストをマージしたかをより正確に識別する`merge_user`フィールドを優先して、非推奨になりました。

APIユーザーは、代わりに新しい`merge_user`フィールドを使用することをお勧めします。`merged_by`フィールドは、GitLab REST APIのv5で削除されます。

## `merge_status` APIフィールド {#merge_status-api-field}

破壊的な変更[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/382032)を参照してください。

[マージリクエストAPI](../merge_requests.md#merge-status)の`merge_status`フィールドは、マージリクエストが取り得るすべての潜在的なステータスをより正確に識別する`detailed_merge_status`フィールドを優先して、非推奨になりました。APIユーザーは、代わりに新しい`detailed_merge_status`フィールドを使用することをお勧めします。`merge_status`フィールドは、GitLab REST APIのv5で削除されます。

### User APIの`private_profile`属性のNull値 {#null-value-for-private_profile-attribute-in-user-api}

破壊的な変更[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/387005)を参照してください。

APIを介してユーザーを作成および更新する場合、`null`は`private_profile`属性の有効な値でしたが、内部的にデフォルト値に変換されていました。GitLab REST APIのv5では、`null`はこのパラメータの有効な値ではなくなり、使用すると応答は400になります。この変更後、有効な値は`true`と`false`のみになります。

## 単一のマージリクエスト変更APIエンドポイント {#single-merge-request-changes-api-endpoint}

破壊的な変更[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/322117)を参照してください。

[単一のマージリクエストからの変更](../merge_requests.md#get-single-merge-request-changes)を取得するためのエンドポイントは、[マージリクエストの差分の一覧](../merge_requests.md#list-merge-request-diffs)エンドポイントを優先して非推奨になりました。APIユーザーは、代わりに新しい差分エンドポイントに切り替えることをお勧めします。

`changes from a single merge request`エンドポイントは、GitLab REST APIのv5で削除されます。

## Managed Licenses APIエンドポイント {#managed-licenses-api-endpoint}

破壊的な変更[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/397067)を参照してください。

特定のプロジェクトのすべての管理ライセンスを取得するためのエンドポイントは、[ライセンス承認ポリシー](../../user/compliance/license_approval_policies.md)機能を優先して非推奨になりました。

検出されたライセンスに基づいて承認を引き続き適用したい場合は、代わりに新しい[ライセンス承認ポリシー](../../user/compliance/license_approval_policies.md)を作成することをおすすめします。

`managed licenses`エンドポイントは、GitLab REST APIのv5で削除されます。

## マージリクエスト承認APIの承認者と承認者グループのフィールド {#approvers-and-approver-group-fields-in-merge-request-approval-api}

破壊的な変更[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/353097)を参照してください。

プロジェクトの承認の設定を取得するためのエンドポイントは、`approvers`と`approval_groups`の空の配列を返します。これらのフィールドは、マージリクエストの[すべての承認ルールをリスト](../merge_request_approvals.md#list-all-approval-rules-for-a-merge-request)するエンドポイントを優先して非推奨になりました。APIユーザーは、代わりにこのエンドポイントに切り替えることをお勧めします。

これらのフィールドは、GitLab REST APIのv5の`get configuration`エンドポイントから削除されます。

## Runnerでの`active`の使用を`paused`に置き換え {#runner-usage-of-active-replaced-by-paused}

破壊的な変更[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)を参照してください。

GitLab GraphQL APIエンドポイントで出現する`active`識別子は、GitLab 16.0で名前が`paused`に変更されます。

- REST APIのv4では、`active`の代わりに`paused`プロパティを使用できます
- REST APIのv5では、この変更は`active`プロパティを受け取るか返すエンドポイントに影響します（以下に示すエンドポイントなど）:
  - `GET /runners`
  - `GET /runners/all`
  - `GET /runners/:id` / `PUT /runners/:id`
  - `PUT --form "active=false" /runners/:runner_id`
  - `GET /projects/:id/runners` / `POST /projects/:id/runners`
  - `GET /groups/:id/runners`

GitLab Runnerの16.0リリースでは、runnerを登録する際に`paused`プロパティの使用を開始します。

## Runnerステータスは`paused`を返しません {#runner-status-will-not-return-paused}

破壊的な変更[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/344648)を参照してください。

今後のREST API v5では、GitLab Runnerのエンドポイントも`paused`または`active`を返しません。

Runnerのステータスは、`online`、`offline`、`not_connected`など、Runnerの接続ステータスのみに関連します。ステータス`paused`または`active`は表示されなくなります。

Runnerが`paused`かどうかを確認する場合、APIユーザーは、代わりにブール属性`paused`が`true`であるかどうかを確認することをおすすめします。Runnerが`active`かどうかを確認する場合は、`paused`が`false`であるかどうかを確認します。

## Runnerは`ip_address`を返しません {#runner-will-not-return-ip_address}

破壊的な変更[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/415159)を参照してください。

GitLab 17.0では、[Runner API](../runners.md)は、runnerの`ip_address`の代わりに`""`を返します。REST APIのv5では、このフィールドは削除されます。

## `default_branch_protection` APIフィールド {#default_branch_protection-api-field}

破壊的な変更[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/408315)を参照してください。

`default_branch_protection`フィールドは、次のAPIでGitLab 17.0で非推奨になりました:

- [新しいグループAPI](../groups.md#create-a-group)。
- [グループAPIの更新](../groups.md#update-group-attributes)。
- [アプリケーション設定API](../settings.md#update-application-settings)を使用する。

代わりに`default_branch_protection_defaults`フィールドを使用する必要があります。これにより、デフォルトのブランチ保護をより細かく制御できます。

`default_branch_protection`フィールドは、GitLab REST APIのv5で削除されます。

## `require_password_to_approve` APIフィールド {#require_password_to_approve-api-field}

`require_password_to_approve`は、GitLab 16.9で非推奨になりました。代わりに`require_reauthentication_to_approve`フィールドを使用します。両方のフィールドに値を指定すると、`require_reauthentication_to_approve`フィールドが優先されます。

`require_password_to_approve`フィールドは、GitLab REST APIのv5で削除されます。

## プロジェクトAPIエンドポイントを使用したプルミラーリング設定 {#pull-mirroring-configuration-with-the-projects-api-endpoint}

破壊的な変更[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/494294)を参照してください。

GitLab 17.6では、[プロジェクトAPIを使用したプルミラーリング設定](../project_pull_mirroring.md#configure-pull-mirroring-for-a-project-deprecated)は非推奨になりました。新しい設定とエンドポイントである[`projects/:id/mirror/pull`](../project_pull_mirroring.md#configure-pull-mirroring-for-a-project)に置き換えられます。

プロジェクトAPIを使用する以前の設定は、GitLab REST APIのv5で削除されます。

## プロジェクトAPIエンドポイントの`restrict_user_defined_variables`パラメータ {#restrict_user_defined_variables-parameter-with-the-projects-api-endpoint}

GitLab 17.7では、[Projects APIの`restrict_user_defined_variables`パラメータ](../projects.md#edit-a-project)は、`ci_pipeline_variables_minimum_override_role`のみを使用することを推奨しています。

`restrict_user_defined_variables: false`と同じ動作をさせるには、`ci_pipeline_variables_minimum_override_role`を`developer`に設定します。
