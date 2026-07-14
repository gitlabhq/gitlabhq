---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: REST APIの非推奨
description: "非推奨フィールドと、GitLabのREST APIにおける計画された破壊的な変更の一覧。"
---

以下の非推奨事項を定期的に確認し、推奨される変更を行う必要があります。これらの非推奨事項は、多くの場合、API機能の改善を示すものであり、機能のために新しいフィールドまたはエンドポイントを使用することを推奨しています。

一部の非推奨事項ではv5 REST APIに言及していますが、v5 REST APIの開発は現在行われていません。GitLabは、REST API v4内でこれらの変更を行いません。また、[REST APIにセマンティックバージョニングを採用しています](_index.md#versioning-and-deprecations)。

## `geo_nodes` APIエンドポイント {#geo_nodes-api-endpoints}

破壊的な変更。[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/369140)。

The [`geo_nodes` APIエンドポイント](../geo_nodes.md)は非推奨となり、[`geo_sites`](../geo_sites.md)に置き換えられました。これは、[Geoデプロイの参照方法](../../administration/geo/glossary.md)に関するグローバルな変更の一部です。ノードはアプリケーション全体でサイトに名前が変更されます。両方のエンドポイントの機能は同じままです。

## `merged_by` APIフィールド {#merged_by-api-field}

破壊的な変更。[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/350534)。

[マージリクエストAPI](../merge_requests.md#list-merge-requests)の`merged_by`フィールドは非推奨となり、`merge_user`フィールドが代わりに推奨されます。これは、単純なマージ以外の操作（自動マージに設定、マージトレインに追加など）を実行した際に、誰がマージリクエストをマージしたかをより正確に識別します。

APIユーザーは、代わりに新しい`merge_user`フィールドを使用することを推奨されます。`merged_by`フィールドは、GitLab REST APIのv5で削除されます。

## `merge_status` APIフィールド {#merge_status-api-field}

破壊的な変更。[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/382032)。

[マージリクエストAPI](../merge_requests.md#merge-status)の`merge_status`フィールドは非推奨となり、`detailed_merge_status`フィールドが代わりに推奨されます。これは、マージリクエストがとりうるすべての潜在的なステータスをより正確に識別します。APIユーザーは、代わりに新しい`detailed_merge_status`フィールドを使用することを推奨されます。`merge_status`フィールドは、GitLab REST APIのv5で削除されます。

### ユーザーAPIにおける`private_profile`属性のNull値 {#null-value-for-private_profile-attribute-in-user-api}

破壊的な変更。[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/387005)。

APIを介してユーザーを作成および更新する際、`null`は`private_profile`属性の有効な値であり、内部的にデフォルト値に変換されていました。GitLab REST APIのv5では、`null`はこのパラメータの有効な値ではなくなり、使用された場合は400の応答が返されます。この変更後、有効な値は`true`と`false`のみになります。

## 単一のマージリクエストの変更APIエンドポイント {#single-merge-request-changes-api-endpoint}

破壊的な変更。[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/322117)。

[単一のマージリクエストから変更を取得するための](../merge_requests.md#retrieve-merge-request-changes)エンドポイントは非推奨となり、代わりに[マージリクエスト差分の一覧](../merge_requests.md#list-merge-request-diffs)のエンドポイントが推奨されます。APIユーザーは、代わりに新しい差分エンドポイントに切り替えることを推奨されます。

`changes from a single merge request`エンドポイントは、GitLab REST APIのv5で削除されます。

## 管理ライセンスAPIエンドポイント {#managed-licenses-api-endpoint}

破壊的な変更。[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/397067)。

特定のプロジェクトのすべての管理ライセンスを取得するためのエンドポイントは非推奨となり、[ライセンス承認ポリシー](../../user/compliance/license_approval_policies.md)機能が代わりに推奨されます。

検出されたライセンスに基づいて承認を引き続き適用したい場合は、代わりに新しい[ライセンス承認ポリシー](../../user/compliance/license_approval_policies.md)を作成することをおすすめします。

`managed licenses`エンドポイントは、GitLab REST APIのv5で削除されます。

## マージリクエスト承認APIにおける承認者およびApprover Groupフィールド {#approvers-and-approver-group-fields-in-merge-request-approval-api}

破壊的な変更。[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/353097)。

プロジェクトの承認の設定を取得するエンドポイントは、`approvers`と`approval_groups`に対して空の配列を返します。これらのフィールドは非推奨となり、マージリクエストの[すべての承認ルールを一覧表示する](../merge_request_approvals.md#list-all-approval-rules-for-a-merge-request)エンドポイントが代わりに推奨されます。APIユーザーは、代わりにこのエンドポイントに切り替えることを推奨されます。

これらのフィールドは、GitLab REST APIのv5で`get configuration`エンドポイントから削除されます。

## Runnerにおける`active`の使用が`paused`に置き換えられます {#runner-usage-of-active-replaced-by-paused}

破壊的な変更。[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)。

GitLab Runner GraphQL APIエンドポイントにおける`active`識別子は、GitLab 16.0で`paused`に名前が変更されます。

- REST APIのv4では、`active`の代わりに`paused`プロパティを使用できます。
- REST APIのv5では、この変更は`active`プロパティを受け取るか返すエンドポイント（例えば以下）に影響します:
  - `GET /runners`
  - `GET /runners/all`
  - `GET /runners/:id` / `PUT /runners/:id`
  - `PUT --form "active=false" /runners/:runner_id`
  - `GET /projects/:id/runners` / `POST /projects/:id/runners`
  - `GET /groups/:id/runners`

GitLab Runnerの16.0リリースでは、Runnerを登録する際に`paused`プロパティの使用を開始します。

## Runnerステータスは`paused`を返しません {#runner-status-will-not-return-paused}

破壊的な変更。[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/344648)。

将来のREST API v5では、GitLab Runnerのエンドポイントは`paused`または`active`を返さなくなります。

Runnerのステータスは、`online`、`offline`、`not_connected`など、Runnerの接続ステータスのみに関連します。ステータス`paused`または`active`は表示されなくなります。

Runnerが`paused`かどうかを確認する場合、APIユーザーは、代わりにブール属性`paused`が`true`であるかどうかを確認することをおすすめします。Runnerが`active`かどうかを確認する場合は、`paused`が`false`であるかどうかを確認します。

## Runnerは`ip_address`を返しません {#runner-will-not-return-ip_address}

破壊的な変更。[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/415159)。

GitLab 17.0では、[Runner API](../runners.md)はRunnerに対して`ip_address`の代わりに`""`を返します。REST APIのv5では、このフィールドは削除されます。

## `default_branch_protection` APIフィールド {#default_branch_protection-api-field}

破壊的な変更。[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/408315)。

`default_branch_protection`フィールドは、GitLab 17.0で以下のAPIに対して非推奨です:

- [新規グループAPI](../groups.md#create-a-group)。
- [グループAPIを更新](../groups.md#update-group-attributes)。
- [アプリケーション設定API](../settings.md#update-application-settings)

代わりに`default_branch_protection_defaults`フィールドを使用してください。これにより、デフォルトのブランチ保護に対して、よりきめ細かな制御が可能になります。

`default_branch_protection`フィールドは、GitLab REST APIのv5で削除されます。

## `require_password_to_approve` APIフィールド {#require_password_to_approve-api-field}

`require_password_to_approve`は、GitLab 16.9で非推奨になりました。代わりに`require_reauthentication_to_approve`フィールドを使用します。両方のフィールドに値を指定した場合、`require_reauthentication_to_approve`フィールドが優先されます。

`require_password_to_approve`フィールドは、GitLab REST APIのv5で削除されます。

## プロジェクトAPIエンドポイントを使用したプルミラーリング設定 {#pull-mirroring-configuration-with-the-projects-api-endpoint}

破壊的な変更。[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/494294)。

GitLab 17.6では、[プロジェクトAPIを使用したプルミラーリング設定](../project_pull_mirroring.md#update-pull-mirroring-for-a-project-deprecated)は非推奨です。これは、新しい設定とエンドポイントである[`projects/:id/mirror/pull`](../project_pull_mirroring.md#update-project-pull-mirroring-settings)に置き換えられます。

プロジェクトAPIを使用した以前の設定は、GitLab REST APIのv5で削除されます。

## プロジェクトAPIエンドポイントの`restrict_user_defined_variables`パラメータ {#restrict_user_defined_variables-parameter-with-the-projects-api-endpoint}

GitLab 17.7では、[プロジェクトAPIの`restrict_user_defined_variables`パラメータ](../projects.md#update-a-project)は非推奨となり、`ci_pipeline_variables_minimum_override_role`のみを使用することが推奨されます。

`restrict_user_defined_variables: false`と同じ動作に一致させるには、`ci_pipeline_variables_minimum_override_role`を`developer`として設定します。

## プロジェクトインポートAPIエンドポイントの`namespace`パラメータ {#namespace-parameter-in-project-import-api-endpoints}

破壊的な変更。[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/511053)。

GitLab 18.7では、[プロジェクトインポートおよびエクスポートAPI](../project_import_export.md)の`namespace`パラメータは非推奨となり、`namespace_id`および`namespace_path`パラメータが代わりに推奨されます。`namespace`パラメータはIDまたはパスの両方を受け入れていたため、ネームスペースパスが数字のみで構成されている場合に曖昧さが発生していました。

代わりに、以下を使用してください:

- `namespace_id`は、数値のIDでネームスペースを指定する場合。
- `namespace_path`は、パスでネームスペースを指定する場合。

`namespace`パラメータは、GitLab REST APIのv5で削除されます。
