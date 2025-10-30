---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ロールと権限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ユーザーをプロジェクトまたはグループに追加する際に、ロールを割り当てます。このロールによって、GitLabでユーザーが実行できる操作が決まります。

プロジェクトが属するグループとプロジェクト自体の両方にユーザーを追加した場合、より上位の権限を持つロールが適用されます。

GitLab[管理者](../administration/_index.md)は、すべての権限を持っています。

<!-- Keep these tables sorted according the following rules in order:
1. By minimum role.
2. By the object being accessed (for example, issue, security dashboard, or pipeline)
3. By the action: view, create, change, edit, manage, run, delete, all others
4. Alphabetically.

List only one action (for example, view, create, or delete) per line.
It's okay to list multiple related objects per line (for example, "View pipelines and pipeline details").
-->

## ロール {#roles}

{{< history >}}

- プランナーロールは、GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/482733)されました。

{{< /history >}}

ユーザーには、デフォルトロールまたは[カスタムロール](custom_roles/_index.md)を割り当てることができます。

利用可能なデフォルトロールは次のとおりです:

- ゲスト（このロールは[非公開プロジェクトおよび内部プロジェクト](public_access.md)にのみ適用されます。）
- プランナー
- レポーター
- デベロッパー
- メンテナー
- オーナー
- 最小アクセス（トップレベルグループのみ利用可能）

ゲストロールが割り当てられたユーザーは最も権限が少なく、オーナーは最も権限が多くなります。

デフォルトでは、すべてのユーザーがトップレベルグループを作成し、ユーザー名を変更できます。GitLab管理者は、GitLabインスタンスの[この動作を変更](../administration/user_settings.md)できます。

## グループメンバーの権限 {#group-members-permissions}

グループの唯一のオーナーでない限り、どのユーザーもグループから自分自身を削除できます。

次の表は、各ロールで利用可能なグループ権限を示しています:

### 分析グループの権限 {#analytics-group-permissions}

[分析](analytics/_index.md)機能（バリューストリーム、プロダクト分析、インサイトなど）のグループ権限:

| アクション                                                             | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ------------------------------------------------------------------ | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| [インサイト](project/insights/_index.md)を表示                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [インサイト](project/insights/_index.md)チャートを表示                 |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [イシュー分析](group/issues_analytics/_index.md)を表示           |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| コントリビュート分析を表示                                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| バリューストリーム分析を表示                                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [生産性分析](analytics/productivity_analytics.md)を表示 |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [グループDevOpsアドプション](group/devops_adoption/_index.md)を表示      |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| メトリクスダッシュボードの注釈を表示                                 |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| メトリクスダッシュボードの注釈を管理                               |       |         |          |     ✓     |     ✓      |   ✓   |

### アプリケーションセキュリティグループの権限 {#application-security-group-permissions}

依存関係管理、セキュリティアナライザー、セキュリティポリシー、脆弱性管理などの[アプリケーションセキュリティ](application_security/secure_your_application.md)機能のグループ権限。

| アクション                                                                           | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| -------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| [依存関係リスト](application_security/dependency_list/_index.md)を表示           |       |         |          |     ✓     |     ✓      |   ✓   |
| [脆弱性レポート](application_security/vulnerability_report/_index.md)を表示 |       |         |          |     ✓     |     ✓      |   ✓   |
| [セキュリティダッシュボード](application_security/security_dashboard/_index.md)を表示     |       |         |          |     ✓     |     ✓      |   ✓   |
| [セキュリティポリシープロジェクト](application_security/policies/_index.md)を作成        |       |         |          |           |            |   ✓   |
| [セキュリティポリシープロジェクト](application_security/policies/_index.md)を割り当て        |       |         |          |           |            |   ✓   |

### CI/CDグループの権限 {#cicd-group-permissions}

Runner、変数、保護環境などの[CI/CD](../ci/_index.md)機能のグループ権限:

| アクション                                | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| インスタンスRunnerを表示                  |   ✓   |    ✓    |     ✓    |    ✓      |     ✓      |   ✓   |
| グループRunnerを表示                    |       |         |          |           |     ✓      |   ✓   |
| グループレベルのKubernetesクラスターを管理 |       |         |          |           |     ✓      |   ✓   |
| グループRunnerを管理                  |       |         |          |           |            |   ✓   |
| グループレベルのCI/CD変数を管理    |       |         |          |           |            |   ✓   |
| グループの保護環境を管理   |       |         |          |           |            |   ✓   |

### コンプライアンスグループの権限 {#compliance-group-permissions}

コンプライアンスセンター、監査イベント、コンプライアンスフレームワーク、ライセンスなどの[コンプライアンス](compliance/_index.md)機能のグループ権限。

| アクション                                                                                 | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| -------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| [監査イベント](compliance/audit_events.md)を表示<sup>1</sup>                           |       |         |          |     ✓     |     ✓      |   ✓   |
| [依存関係リスト](application_security/dependency_list/_index.md)のライセンスを表示     |       |         |          |     ✓     |     ✓      |   ✓   |
| [コンプライアンスセンター](compliance/compliance_center/_index.md)を表示                       |       |         |          |           |            |   ✓   |
| [コンプライアンスフレームワーク](compliance/compliance_frameworks/_index.md)を管理             |       |         |          |           |            |   ✓   |
| [コンプライアンスフレームワーク](compliance/compliance_frameworks/_index.md)をプロジェクトに割り当て |       |         |          |           |            |   ✓   |
| [監査ストリーム](compliance/audit_event_streaming.md)を管理                            |       |         |          |           |            |   ✓   |

**脚注**

1. ユーザーは、個々のアクションに基づいたイベントのみを表示できます。詳細については、[前提要件](compliance/audit_events.md#prerequisites)を参照してください。

### GitLab Duoグループの権限 {#gitlab-duo-group-permissions}

[GitLab Duo](gitlab_duo/_index.md)のグループ権限:

| アクション                                                                                                     | 非メンバー | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ---------------------------------------------------------------------------------------------------------- | :--------: | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| GitLab Duoの機能を使用<sup>1</sup>                                                                       |            |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [GitLab Duo機能の可用性](gitlab_duo/turn_on_off.md#for-a-group-or-subgroup)を設定             |            |       |         |          |           |     ✓      |   ✓   |
| [GitLab Duo Self Hosted](../administration/gitlab_duo_self_hosted/configure_duo_features.md)を設定     |            |       |         |          |           |            |   ✓   |
| [ベータ版および実験的機能](gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)を有効化  |            |       |         |          |           |            |   ✓   |
| [GitLab Duoシート](../subscriptions/subscription-add-ons.md#purchase-additional-gitlab-duo-seats)を購入 |            |       |         |          |           |            |   ✓   |

**脚注**

1. ユーザーがGitLab Duo ProまたはGitLab Duo Enterpriseを使用している場合、[そのGitLab Duoアドオンにアクセスするには、ユーザーにシートを割り当てる必要があります](../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats)。ユーザーがGitLab Duo Coreを使用している場合、他の要件はありません。

### グループのグループ権限 {#groups-group-permissions}

[グループ機能](group/_index.md)のグループ権限:

| アクション                                                                                      | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ------------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| グループを閲覧                                                                                |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| グループ内のプロジェクトを[検索](search/_index.md)                                                |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| グループの[監査イベント](compliance/audit_events.md)を表示<sup>1</sup>                          |       |         |          |     ✓     |     ✓      |   ✓   |
| グループにプロジェクトを作成<sup>2</sup>                                                        |       |         |          |     ✓     |     ✓      |   ✓   |
| サブグループを作成<sup>3</sup>                                                                |       |         |          |           |     ✓      |   ✓   |
| [プロジェクトインテグレーション](project/integrations/_index.md)のカスタム設定を変更           |       |         |          |           |            |   ✓   |
| [エピック](group/epics/_index.md)のコメントを編集（ユーザーを問わず投稿されたもの）                            |       |    ✓    |          |           |     ✓      |   ✓   |
| プロジェクトをグループにフォーク                                                                   |       |         |          |           |     ✓      |   ✓   |
| [請求](../subscriptions/manage_subscription.md#view-subscription)を表示<sup>4</sup>      |       |         |          |           |            |   ✓   |
| グループの[使用量クォータ](storage_usage_quotas.md)ページを表示<sup>4</sup>                        |       |         |          |           |            |   ✓   |
| [グループを移行](group/import/_index.md)                                                     |       |         |          |           |            |   ✓   |
| グループをアーカイブ                                                                                |       |         |          |           |            |   ✓   |
| グループを削除                                                                                |       |         |          |           |            |   ✓   |
| [サブスクリプション、ストレージ、コンピューティング時間](../subscriptions/gitlab_com/_index.md)を管理 |       |         |          |           |            |   ✓   |
| [グループアクセストークン](group/settings/group_access_tokens.md)を管理                         |       |         |          |           |            |   ✓   |
| グループの表示レベルを変更                                                               |       |         |          |           |            |   ✓   |
| グループ設定を編集                                                                         |       |         |          |           |            |   ✓   |
| プロジェクトテンプレートを設定                                                                 |       |         |          |           |            |   ✓   |
| [SAML SSO](group/saml_sso/_index.md)を設定<sup>4</sup>                                 |       |         |          |           |            |   ✓   |
| 通知メールを無効化                                                                 |       |         |          |           |            |   ✓   |
| [プロジェクト](project/settings/import_export.md)をインポート                                         |       |         |          |           |     ✓      |   ✓   |

**脚注**

1. デベロッパーとメンテナーは、個々のアクションに基づいたイベントのみを表示できます。詳細については、[前提要件](compliance/audit_events.md#prerequisites)を参照してください。
1. デベロッパー、メンテナー、オーナー: [インスタンス](../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects)または[グループ](group/_index.md#specify-who-can-add-projects-to-a-group)にプロジェクト作成ロールが設定されている場合にのみ適用されます。
   <br>デベロッパー: デベロッパーは、[デフォルトブランチ保護](group/manage.md#change-the-default-branch-protection-of-a-group)が「部分的に保護されている」または「保護されていない」に設定されている場合にのみ、新しいプロジェクトのデフォルトブランチにコミットをプッシュできます。
1. メンテナー: メンテナーロールを持つユーザーが[サブグループを作成できる](group/subgroups/_index.md#change-who-can-create-subgroups)場合にのみ適用されます。
1. サブグループには適用されません。

### プロジェクト計画グループの権限 {#project-planning-group-permissions}

| アクション                                                                              | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ----------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| エピックを表示                                                                           |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| エピックを[検索](search/_index.md)<sup>1</sup>                                       |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [エピック](group/epics/_index.md)にイシューを追加<sup>2</sup>                         |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [子エピック](group/epics/manage_epics.md#multi-level-child-epics)を追加<sup>3</sup> |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| 内部メモを追加                                                                  |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| エピックを作成                                                                        |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| エピックの詳細を更新                                                                 |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [エピックボード](group/epics/epic_boards.md)を管理                                    |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| エピックを削除                                                                        |       |    ✓    |          |           |            |   ✓   |

**脚注**

1. [エピックを表示](group/epics/manage_epics.md#who-can-view-an-epic)する権限が必要です。
1. [エピックを表示](group/epics/manage_epics.md#who-can-view-an-epic)し、イシューを編集する権限が必要です。
1. 親エピックと子エピックを[表示](group/epics/manage_epics.md#who-can-view-an-epic)する権限が必要です。

[Wiki](project/wiki/group.md)のグループ権限:

| アクション                                              | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| --------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| グループWikiを表示<sup>1</sup>                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| グループWikiを[検索](search/_index.md)<sup>2</sup> |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| グループWikiページを作成                             |       |    ✓    |          |     ✓     |     ✓      |   ✓   |
| グループWikiページを編集                               |       |    ✓    |          |     ✓     |     ✓      |   ✓   |
| グループWikiページを削除                             |       |    ✓    |          |     ✓     |     ✓      |   ✓   |

**脚注**

1. ゲスト: さらに、グループが公開または内部の場合、グループを表示できるすべてのユーザーは、グループWikiページも表示できます。
1. ゲスト: さらに、グループが公開または内部の場合、グループを表示できるすべてのユーザーは、グループWikiページも表示できます。

### パッケージとレジストリのグループ権限 {#packages-and-registries-group-permissions}

[コンテナレジストリ](packages/_index.md)のグループ権限:

| アクション                                          | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ----------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| コンテナレジストリイメージをプル<sup>1</sup>     |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| 依存プロキシでコンテナイメージをプル |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| コンテナレジストリイメージを削除                |       |         |          |     ✓     |     ✓      |   ✓   |

**脚注**

1. ゲストは、個々のアクションに基づいたイベントのみを表示できます。

[パッケージレジストリ](packages/_index.md)のグループ権限:

| アクション                                   | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ---------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| パッケージをプル                            |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| パッケージを公開                         |       |         |          |     ✓     |     ✓      |   ✓   |
| パッケージを削除                          |       |         |          |           |     ✓      |   ✓   |
| パッケージ設定を管理                  |       |         |          |           |            |   ✓   |
| 依存プロキシのクリーンアップポリシーを管理 |       |         |          |           |            |   ✓   |
| 依存プロキシを有効化                  |       |         |          |           |            |   ✓   |
| 依存プロキシを無効化                 |       |         |          |           |            |   ✓   |
| グループ依存プロキシをパージ         |       |         |          |           |            |   ✓   |
| パッケージリクエスト転送を有効化        |       |         |          |           |            |   ✓   |
| パッケージリクエスト転送を無効化       |       |         |          |           |            |   ✓   |

### リポジトリグループ権限 {#repository-group-permissions}

マージリクエスト、プッシュルール、デプロイトークンなどの[リポジトリ](project/repository/_index.md)機能のグループ権限。

| アクション                                                                                 | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| -------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| [デプロイトークン](project/deploy_tokens/_index.md)を管理                                |       |         |          |           |            |   ✓   |
| [マージリクエストの設定](group/manage.md#group-merge-request-approval-settings)を管理 |       |         |          |           |            |   ✓   |
| [プッシュルール](group/access_and_permissions.md#group-push-rules)を管理                  |       |         |          |           |            |   ✓   |

### ユーザー管理グループ権限 {#user-management-group-permissions}

ユーザー管理のグループ権限:

| アクション                          | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| メンバーの2FAステータスを表示      |       |         |          |           |            |   ✓   |
| 2FAステータスによるメンバーのフィルタリング    |       |         |          |           |            |   ✓   |
| グループメンバーを管理            |       |         |          |           |            |   ✓   |
| グループレベルのカスタムロールを管理 |       |         |          |           |            |   ✓   |
| グループにグループを共有（招待） |       |         |          |           |            |   ✓   |

### ワークスペースのグループ権限 {#workspace-group-permissions}

ワークスペースのグループ権限:

| アクション                                                    | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| --------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| グループにマッピングされたワークスペースクラスタエージェントを表示           |       |         |          |           |     ✓      |   ✓   |
| ワークスペースクラスタエージェントのグループとの間のマッピングまたはマッピング解除 |       |         |          |           |            |   ✓   |

## プロジェクトメンバーの権限 {#project-members-permissions}

ユーザーのロールによって、プロジェクトで持つ権限が決まります。オーナーロールはすべての権限を提供しますが、次のロールでのみ使用できます:

- グループおよびプロジェクトのオーナー。
- 管理者。

個人の[ネームスペース](namespace/_index.md)オーナーについて:

- ネームスペース内のプロジェクトではメンテナーロールとして表示されますが、実際にはオーナーロールと同じ権限を持っています。
- ネームスペース内の新しいプロジェクトでは、オーナーロールとして表示されます。

プロジェクトメンバーの管理方法の詳細については、[プロジェクトのメンバー](project/members/_index.md)を参照してください。

次の表に、ロールごとに使用できるプロジェクト権限を示します。

### 分析 {#analytics}

バリューストリーム、使用状況トレンド、プロダクト分析、インサイトなどの[分析](analytics/_index.md)機能のプロジェクト権限。

| アクション                                                                                     | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ------------------------------------------------------------------------------------------ | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| [イシュー分析](group/issues_analytics/_index.md)を表示                                   |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [バリューストリーム分析](group/value_stream_analytics/_index.md)を表示                      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [CI/CDの分析](analytics/ci_cd_analytics.md)を表示                                       |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [コードレビュー分析](analytics/code_review_analytics.md)を表示                           |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [DORAメトリクス](analytics/ci_cd_analytics.md)を表示                                          |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [マージリクエスト分析](analytics/merge_request_analytics.md)を表示                       |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [リポジトリの分析](analytics/repository_analytics.md)を表示                             |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [バリューストリームダッシュボードとAIインパクト分析](analytics/value_streams_dashboard.md)を表示 |       |         |    ✓     |     ✓     |     ✓      |   ✓   |

### アプリケーションセキュリティ {#application-security}

依存関係管理、セキュリティアナライザー、セキュリティポリシー、脆弱性管理などの[アプリケーションセキュリティ](application_security/secure_your_application.md)機能のプロジェクト権限。

| アクション                                                                                                                              | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ----------------------------------------------------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| [依存関係リスト](application_security/dependency_list/_index.md)を表示                                                              |       |         |          |     ✓     |     ✓      |   ✓   |
| [依存関係リスト](application_security/dependency_list/_index.md)のライセンスを表示                                                  |       |         |          |     ✓     |     ✓      |   ✓   |
| [セキュリティダッシュボード](application_security/security_dashboard/_index.md)を表示                                                        |       |         |          |     ✓     |     ✓      |   ✓   |
| [脆弱性レポート](application_security/vulnerability_report/_index.md)を表示                                                    |       |         |          |     ✓     |     ✓      |   ✓   |
| [脆弱性を手動で](application_security/vulnerability_report/_index.md#manually-add-a-vulnerability)作成                   |       |         |          |           |     ✓      |   ✓   |
| 脆弱性検出結果から[イシュー](application_security/vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability)を作成 |       |         |          |     ✓     |     ✓      |   ✓   |
| [オンデマンドDASTスキャン](application_security/dast/on-demand_scan.md)を作成                                                          |       |         |          |     ✓     |     ✓      |   ✓   |
| [オンデマンドDASTスキャン](application_security/dast/on-demand_scan.md)を実行                                                             |       |         |          |     ✓     |     ✓      |   ✓   |
| [個々のセキュリティポリシー](application_security/policies/_index.md)を作成                                                      |       |         |          |     ✓     |     ✓      |   ✓   |
| [個々のセキュリティポリシー](application_security/policies/_index.md)を変更                                                      |       |         |          |     ✓     |     ✓      |   ✓   |
| [個々のセキュリティポリシー](application_security/policies/_index.md)を削除                                                      |       |         |          |     ✓     |     ✓      |   ✓   |
| [CVE IDリクエスト](application_security/cve_id_request.md)を作成                                                                     |       |         |          |           |     ✓      |   ✓   |
| 脆弱性のステータスを変更<sup>1</sup>                                                                                            |       |         |          |           |     ✓      |   ✓   |
| [セキュリティポリシープロジェクト](application_security/policies/_index.md)を作成                                                           |       |         |          |           |            |   ✓   |
| [セキュリティポリシープロジェクト](application_security/policies/_index.md)を割り当て                                                           |       |         |          |           |            |   ✓   |
| [セキュリティ設定](application_security/detect/security_configuration.md)を管理                                             |       |         |          |           |     ✓      |   ✓   |

**脚注**

1. `admin_vulnerability`権限は、GitLab 17.0でデベロッパーロールから[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/412693)されました。

### CI/CD {#cicd}

一部のロールに対する[GitLab CI/CD](../ci/_index.md)権限は、次の設定で変更できます:

- [プロジェクトベースのパイプラインの表示レベル](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines): 公開に設定すると、特定のCI/CD機能へのアクセスがゲストプロジェクトメンバーに許可されます。
- [パイプラインの表示レベル](../ci/pipelines/settings.md#change-pipeline-visibility-for-non-project-members-in-public-projects): **アクセスできるすべてのユーザー**に設定すると、特定のCI/CD「表示」機能へのアクセスがプロジェクトメンバー以外のユーザーに許可されます。

プロジェクトオーナーはリストされているすべてのアクションを実行でき、パイプラインを削除できます。

| アクション                                                                                                      | 非メンバー | ゲスト | プランナー | レポーター | デベロッパー | メンテナー |
| ----------------------------------------------------------------------------------------------------------- | :--------: | :---: | :-----: | :------: | :-------: | :--------: |
| インスタンスRunnerを表示                                                                                        |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| 既存のアーティファクトを表示<sup>1</sup>                                                                        |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| ジョブのリストを表示<sup>2</sup>                                                                              |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| アーティファクトを表示<sup>3</sup>                                                                                 |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| アーティファクトをダウンロード<sup>3</sup>                                                                             |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| [環境](../ci/environments/_index.md)を表示<sup>1</sup>                                              |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| ジョブのログとジョブ詳細ページを表示<sup>2</sup>                                                             |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| パイプラインとパイプライン詳細ページを表示<sup>2</sup>                                                      |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| MRのパイプラインタブを表示<sup>1</sup>                                                                       |     ✓      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| [パイプラインの脆弱性](application_security/detect/security_scanning_results.md)を表示<sup>4</sup> |            |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |
| 保護環境のデプロイジョブを実行<sup>5</sup>                                                 |            |       |         |    ✓     |     ✓     |     ✓      |
| [Kubernetesエージェント](clusters/agent/_index.md)を表示                                                      |            |       |         |          |     ✓     |     ✓      |
| プロジェクトの[セキュアファイル](../api/secure_files.md)を表示                                                         |            |       |         |          |     ✓     |     ✓      |
| プロジェクトの[セキュアファイル](../api/secure_files.md)をダウンロード                                                     |            |       |         |          |     ✓     |     ✓      |
| [デバッグログの生成](../ci/variables/variables_troubleshooting.md#enable-debug-logging)を使用してジョブを表示          |            |       |         |          |     ✓     |     ✓      |
| [環境](../ci/environments/_index.md)を作成                                                         |            |       |         |          |     ✓     |     ✓      |
| [環境](../ci/environments/_index.md)を削除                                                         |            |       |         |          |     ✓     |     ✓      |
| [環境](../ci/environments/_index.md)を停止                                                           |            |       |         |          |     ✓     |     ✓      |
| CI/CDパイプラインまたはジョブを実行、再実行、または再試行                                                                  |            |       |         |          |     ✓     |     ✓      |
| 保護ブランチのCI/CDパイプラインまたはジョブを実行、再実行、または再試行<sup>6</sup>                              |            |       |         |          |     ✓     |     ✓      |
| ジョブログまたはジョブアーティファクトを削除<sup>7</sup>                                                               |            |       |         |          |     ✓     |     ✓      |
| [レビューアプリ](../ci/review_apps/_index.md)を有効化                                                           |            |       |         |          |     ✓     |     ✓      |
| ジョブをキャンセル<sup>8</sup>                                                                                    |            |       |         |          |     ✓     |     ✓      |
| [Terraform](infrastructure/_index.md)ステートの読み取り                                                            |            |       |         |          |     ✓     |     ✓      |
| [インタラクティブWebターミナル](../ci/interactive_web_terminal/_index.md)を実行                                   |            |       |         |          |     ✓     |     ✓      |
| パイプラインエディタを使用                                                                                         |            |       |         |          |     ✓     |     ✓      |
| プロジェクトRunnerを表示<sup>9</sup>                                                                           |            |       |         |          |           |     ✓      |
| プロジェクトRunnerを管理<sup>9</sup>                                                                         |            |       |         |          |           |     ✓      |
| プロジェクトRunnerを削除<sup>10</sup>                                                                        |            |       |         |          |           |     ✓      |
| [Kubernetesエージェント](clusters/agent/_index.md)を管理                                                    |            |       |         |          |           |     ✓      |
| CI/CD設定を管理                                                                                       |            |       |         |          |           |     ✓      |
| ジョブトリガーを管理                                                                                         |            |       |         |          |           |     ✓      |
| プロジェクトのCI/CD変数を管理                                                                              |            |       |         |          |           |     ✓      |
| プロジェクトの保護環境を管理                                                                       |            |       |         |          |           |     ✓      |
| プロジェクトの[セキュアファイル](../api/secure_files.md)を管理                                                       |            |       |         |          |           |     ✓      |
| [Terraform](infrastructure/_index.md)ステートを管理                                                          |            |       |         |          |           |     ✓      |
| プロジェクトRunnerをプロジェクトに追加<sup>11</sup>                                                                |            |       |         |          |           |     ✓      |
| Runnerキャッシュを手動でクリア                                                                                |            |       |         |          |           |     ✓      |
| プロジェクトでインスタンスRunnerを有効化                                                                          |            |       |         |          |           |     ✓      |

**脚注**

<!-- Disable ordered list rule https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md029---ordered-list-item-prefix -->
<!-- markdownlint-disable MD029 -->

1. 非メンバーとゲスト: プロジェクトが公開の場合のみ。
2. 非メンバー: プロジェクトが公開されており、**プロジェクトベースのパイプラインの表示レベル**が**プロジェクトの設定 > CI/CD**で有効になっている場合のみ。
   <br>ゲスト: **プロジェクトベースのパイプラインの表示レベル**が**プロジェクトの設定 > CI/CD**で有効になっている場合のみ。
3. 非メンバー: プロジェクトが公開されており、**プロジェクトベースのパイプラインの表示レベル**が**プロジェクトの設定 > CI/CD**で有効になっており、[`artifacts:public: false`](../ci/yaml/_index.md#artifactspublic)がジョブに設定されていない場合のみ。
   <br>ゲスト: **プロジェクトベースのパイプラインの表示レベル**が**プロジェクトの設定 > CI/CD**で有効になっており、`artifacts:public: false`がジョブに設定されていない場合のみ。<br>レポーター: `artifacts:public: false`がジョブに設定されていない場合のみ。
4. ゲスト: **プロジェクトベースのパイプラインの表示レベル**が**プロジェクトの設定 > CI/CD**で有効になっている場合のみ。
5. レポーター: ユーザーが[保護環境へのアクセス権を持つグループのメンバー](../ci/environments/protected_environments.md#deployment-only-access-to-protected-environments)である場合のみ。
   <br>デベロッパーとメンテナー: ユーザーが[保護環境へのデプロイを許可されている](../ci/environments/protected_environments.md#protecting-environments)場合のみ。
6. デベロッパーとメンテナー: ユーザーが[保護ブランチへのマージまたはプッシュを許可されている](../ci/pipelines/_index.md#pipeline-security-on-protected-branches)場合のみ。
7. デベロッパー: ジョブがユーザーによってトリガーされ、保護されていないブランチに対して実行される場合のみ。
8. キャンセル権限は、[パイプライン設定で制限](../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs)できます。
9. メンテナー: Runnerに関連付けられたプロジェクトのメンテナーロールが必要です。
10. メンテナー: [オーナープロジェクト](../ci/runners/runners_scope.md#project-runner-ownership)（Runnerに最初に関連付けられたプロジェクト）のメンテナーロールが必要です。
11. メンテナー: 追加されるプロジェクトと、すでにRunnerに関連付けられたプロジェクトのメンテナーロールが必要です。

<!-- markdownlint-enable MD029 -->

この表は、特定のロールによってトリガーされたジョブに付与される権限を示しています。

プロジェクトオーナーはリストされているアクションを実行できますが、ソースとLFSを一緒にプッシュすることはできません。ゲストユーザーとレポーターロールのメンバーは、これらのアクションを実行できません。

| アクション                                                    | デベロッパー | メンテナー |
| --------------------------------------------------------- | :-------: | :--------: |
| 現在のプロジェクトからソースとLFSをクローン                 |     ✓     |     ✓      |
| 公開プロジェクトからソースとLFSをクローン                 |     ✓     |     ✓      |
| 内部プロジェクトからソースとLFSをクローン<sup>1</sup>  |     ✓     |     ✓      |
| 非公開プロジェクトからソースとLFSをクローン<sup>2</sup>   |     ✓     |     ✓      |
| 現在のプロジェクトからコンテナイメージをプル                |     ✓     |     ✓      |
| 公開プロジェクトからコンテナイメージをプル                |     ✓     |     ✓      |
| 内部プロジェクトからコンテナイメージをプル<sup>1</sup> |     ✓     |     ✓      |
| 非公開プロジェクトからコンテナイメージをプル<sup>2</sup>  |     ✓     |     ✓      |
| 現在のプロジェクトにコンテナイメージをプッシュ<sup>3</sup>     |     ✓     |     ✓      |

**脚注**

1. デベロッパーとメンテナー: トリガーユーザーが外部ユーザーでない場合のみ。
1. トリガーユーザーがプロジェクトのメンバーである場合のみ。[プルポリシー`if-not-present`での非公開Dockerイメージの使用](https://docs.gitlab.com/runner/security/#usage-of-private-docker-images-with-if-not-present-pull-policy)も参照してください。
1. コンテナイメージを他のプロジェクトにプッシュすることはできません。

### コンプライアンス {#compliance}

コンプライアンスセンター、監査イベント、コンプライアンスフレームワーク、ライセンスなどを含む、[コンプライアンス](compliance/_index.md)機能のプロジェクト権限。

| アクション                                                                                                          | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| --------------------------------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| [MRで許可および拒否されたライセンス](compliance/license_scanning_of_cyclonedx_files/_index.md)を表示<sup>1</sup> |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [監査イベント](compliance/audit_events.md)を表示<sup>2</sup>                                                    |       |         |          |     ✓     |     ✓      |   ✓   |
| [依存関係リスト](application_security/dependency_list/_index.md)のライセンスを表示                              |       |         |          |     ✓     |     ✓      |   ✓   |
| [監査ストリーム](compliance/audit_event_streaming.md)を管理                                                     |       |         |          |           |            |   ✓   |

**脚注**

1. GitLab Self-Managedでは、ゲストロールを持つユーザーは、公開および内部プロジェクトでのみこのアクションを実行できます（非公開プロジェクトでは実行できません）。[外部ユーザー](../administration/external_users.md)は、プロジェクトが内部であっても、少なくともレポーターロールを持っている必要があります。GitLab.comのゲストロールを持つユーザーは、内部の表示レベルが利用できないため、公開プロジェクトでのみこのアクションを実行できます。
1. ユーザーは、個々のアクションに基づいたイベントのみを表示できます。詳細については、[前提要件](compliance/audit_events.md#prerequisites)を参照してください。

### GitLab Duo {#gitlab-duo}

[GitLab Duo](gitlab_duo/_index.md)のプロジェクト権限:

| アクション                                                                               | 非メンバー | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ------------------------------------------------------------------------------------ | :--------: | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| GitLab Duo機能を使用<sup>1</sup>                                                 |            |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [GitLab Duo機能の可用性](gitlab_duo/turn_on_off.md#for-a-project)を設定 |            |       |         |          |           |     ✓      |   ✓   |

**脚注**

1. コード提案では、[ユーザーがGitLab Duoアドオンにアクセスするためのシートが割り当て済みである](../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats)必要があります。

### 機械学習モデルレジストリと実験 {#machine-learning-model-registry-and-experiment}

[モデルレジストリ](project/ml/model_registry/_index.md)と[モデル実験](project/ml/experiment_tracking/_index.md)のプロジェクト権限。

| アクション                                                                          | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| [モデルとバージョン](project/ml/model_registry/_index.md)を表示<sup>1</sup>    |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [モデル実験](project/ml/experiment_tracking/_index.md)を表示<sup>2</sup> |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| モデル、バージョン、およびアーティファクトを作成<sup>3</sup>                             |       |         |          |     ✓     |     ✓      |   ✓   |
| モデル、バージョン、およびアーティファクトを編集                                            |       |         |          |     ✓     |     ✓      |   ✓   |
| モデル、バージョン、およびアーティファクトを削除                                          |       |         |          |     ✓     |     ✓      |   ✓   |
| 実験と候補を作成                                               |       |         |          |     ✓     |     ✓      |   ✓   |
| 実験と候補を編集                                                 |       |         |          |     ✓     |     ✓      |   ✓   |
| 実験と候補を削除                                               |       |         |          |     ✓     |     ✓      |   ✓   |

**脚注**

1. 非メンバーは**アクセスできるすべてのユーザー**の表示レベルで、公開プロジェクトのモデルとバージョンのみを表示できます。非メンバーはログインしていても内部プロジェクトを表示できません。
1. 非メンバーは**アクセスできるすべてのユーザー**の表示レベルで、公開プロジェクトのモデル実験のみを表示できます。非メンバーはログインしていても内部プロジェクトを表示できません。
1. パッケージレジストリAPIを使用して、アーティファクトをアップロードおよびダウンロードすることもできます。これには別の権限セットが使用されます。

### モニタリング {#monitoring}

[エラートラッキング](../operations/error_tracking.md)や[インシデント管理](../operations/incident_management/_index.md)などのモニタリングのプロジェクト権限:

| アクション                                                                                                              | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ------------------------------------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| [インシデント](../operations/incident_management/incidents.md)を表示                                                  |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [インシデント管理](../operations/incident_management/_index.md)アラートを割り当て                                  |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [インシデント管理](../operations/incident_management/_index.md)のオンコールローテーションに参加              |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [アラート](../operations/incident_management/alerts.md)を表示                                                          |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [エラートラッキング](../operations/error_tracking.md)リストを表示                                                         |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [エスカレーションポリシー](../operations/incident_management/escalation_policies.md)を表示                                |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [オンコールスケジュール](../operations/incident_management/oncall_schedules.md)を表示                                     |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [インシデント](../operations/incident_management/incidents.md)を作成                                                   |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [アラートステータス](../operations/incident_management/alerts.md#change-an-alerts-status)を変更                          |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [インシデントの重大度](../operations/incident_management/manage_incidents.md#change-severity)を変更                   |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [インシデントのエスカレーションステータス](../operations/incident_management/manage_incidents.md#change-status)を変更            |       |         |          |     ✓     |     ✓      |   ✓   |
| [インシデントのエスカレーションポリシー](../operations/incident_management/manage_incidents.md#change-escalation-policy)を変更 |       |         |          |     ✓     |     ✓      |   ✓   |
| [エラートラッキング](../operations/error_tracking.md)を管理                                                            |       |         |          |           |     ✓      |   ✓   |
| [エスカレーションポリシー](../operations/incident_management/escalation_policies.md)を管理                              |       |         |          |           |     ✓      |   ✓   |
| [オンコールスケジュール](../operations/incident_management/oncall_schedules.md)を管理                                   |       |         |          |           |     ✓      |   ✓   |

### プロジェクト計画 {#project-planning}

[イシュー](project/issues/_index.md)のプロジェクト権限:

| アクション                                                                            | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| --------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| イシューを表示                                                                       |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| イシューとコメントを[検索](search/_index.md)                                    |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| イシューを作成                                                                     |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [非公開イシュー](project/issues/confidential_issues.md)を表示                 |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| 機密情報イシューとコメントを[検索](search/_index.md)                       |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| メタデータ、アイテムのロック、スレッドの解決を含むイシューを編集<sup>1</sup> |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| 内部メモを追加                                                                |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| イシューを完了/再開<sup>2</sup>                                              |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [設計管理](project/issues/design_management.md)ファイルを管理             |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [イシューボード](project/issue_board.md)を管理                                     |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [マイルストーン](project/milestones/_index.md)を管理                                 |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| マイルストーンを[検索](search/_index.md)                                             |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [要求事項](project/requirements/_index.md)をアーカイブまたは再開<sup>3</sup>     |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [要求事項](project/requirements/_index.md)を作成または編集<sup>4</sup>        |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [要求事項](project/requirements/_index.md)をインポートまたはエクスポート                   |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [テストケース](../ci/test_cases/_index.md)をアーカイブ                                  |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [テストケース](../ci/test_cases/_index.md)を作成                                   |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [テストケース](../ci/test_cases/_index.md)を移動                                     |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [テストケース](../ci/test_cases/_index.md)を再開                                   |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| イシューをCSVファイルから[インポート](project/issues/csv_import.md)                     |       |    ✓    |          |     ✓     |     ✓      |   ✓   |
| イシューをCSVファイルに[エクスポート](project/issues/csv_export.md)                       |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| イシューを削除                                                                     |       |         |          |           |            |   ✓   |
| [機能フラグ](../operations/feature_flags.md)を管理                            |       |         |          |     ✓     |     ✓      |   ✓   |

**脚注**

1. メタデータには、ラベル、担当者、マイルストーン、エピック、ウェイト、公開設定、タイムトラッキングなどが含まれます。ゲストユーザーは、イシューの作成時にのみメタデータを設定できます。既存のイシューのメタデータは変更できません。ゲストユーザーは、作成したイシューまたは割り当て済みのイシューのタイトルと説明を変更できます。
1. ゲストユーザーは、作成したイシューまたは割り当て済みのイシューに対して、完了および再開が可能です。
1. ゲストユーザーは、作成したイシューまたは割り当て済みのイシューに対して、アーカイブおよび再開が可能です。
1. ゲストユーザーは、作成したイシューまたは割り当て済みのイシューのタイトルと説明を変更できます。

[タスク](tasks.md)のプロジェクト権限:

| アクション                                                                           | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| -------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| タスクを表示                                                                       |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| タスクを[検索](search/_index.md)                                                 |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| タスクを作成                                                                     |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| メタデータ、アイテムのロック、スレッドの解決を含むタスクを編集<sup>1</sup> |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| リンクされたアイテムを追加                                                                |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| 別のアイテムタイプに変換                                                     |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| イシューから削除                                                                |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| 内部メモを追加                                                                |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| タスクを削除<sup>2</sup>                                                        |       |    ✓    |          |           |            |   ✓   |

**脚注**

1. ゲストユーザーは、作成したイシューまたは割り当て済みのイシューのタイトルと説明を変更できます。
1. プランナーまたはオーナーのロールを持たないユーザーは、自分が作成したタスクを削除できます。

[OKR](okrs.md)のプロジェクト権限:

| アクション                                                             | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ------------------------------------------------------------------ | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| OKRを表示                                                          |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| OKRを[検索](search/_index.md)                                    |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| OKRを作成                                                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| メタデータ、アイテムのロック、スレッドの解決を含むOKRを編集 |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| 子OKRを追加                                                    |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| リンクされたアイテムを追加                                                  |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| 別のアイテムタイプに変換                                       |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| OKRを編集                                                          |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| OKRの公開設定を変更                                      |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| 内部メモを追加                                                  |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |

[Wiki](project/wiki/_index.md)のプロジェクト権限:

| アクション                           | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| -------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| Wikiを表示                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Wikiを[検索](search/_index.md) |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| Wikiページを作成                |       |    ✓    |          |     ✓     |     ✓      |   ✓   |
| Wikiページを編集                  |       |    ✓    |          |     ✓     |     ✓      |   ✓   |
| Wikiページを削除                |       |    ✓    |          |     ✓     |     ✓      |   ✓   |

### パッケージとレジストリ {#packages-and-registry}

[コンテナレジストリ](packages/_index.md)のプロジェクト権限:

| アクション                                                                                           | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ------------------------------------------------------------------------------------------------ | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| コンテナレジストリイメージをプル<sup>1</sup>                                                      |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| コンテナレジストリイメージをプッシュ                                                                   |       |         |          |     ✓     |     ✓      |   ✓   |
| コンテナレジストリイメージを削除                                                                 |       |         |          |     ✓     |     ✓      |   ✓   |
| クリーンアップポリシーを管理                                                                          |       |         |          |           |     ✓      |   ✓   |
| [タグ保護](packages/container_registry/protected_container_tags.md)ルールを作成           |       |         |          |           |     ✓      |   ✓   |
| [イミュータブルタグ保護](packages/container_registry/immutable_container_tags.md)ルールを作成 |       |         |          |           |            |   ✓   |

**脚注**:

1. コンテナレジストリの表示およびイメージのプルは、[コンテナレジストリの表示レベル権限](packages/container_registry/_index.md#container-registry-visibility-permissions)によって制御されます。ゲストロールには、非公開プロジェクトでの表示またはプルの権限がありません。

[パッケージレジストリ](packages/_index.md)のプロジェクト権限:

| アクション                                  | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| --------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| パッケージをプル<sup>1</sup>              |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| パッケージを公開                        |       |         |          |     ✓     |     ✓      |   ✓   |
| パッケージを削除                         |       |         |          |           |     ✓      |   ✓   |
| パッケージに関連付けられたファイルを削除  |       |         |          |           |     ✓      |   ✓   |

**脚注**

1. GitLab Self-Managedでは、ゲストロールを持つユーザーは、公開および内部プロジェクトでのみこのアクションを実行できます（非公開プロジェクトでは実行できません）。[外部ユーザー](../administration/external_users.md)には、プロジェクトが内部であっても、明示的なアクセス権（少なくとも**レポーター**ロール）を付与する必要があります。GitLab.comのゲストロールのユーザーは、内部表示レベルを利用できないため、公開プロジェクトでのみこのアクションを実行できます。

### プロジェクト {#projects}

[プロジェクト機能](project/organize_work_with_projects.md)のプロジェクト権限:

| アクション                                                                                 | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| -------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| プロジェクトをダウンロード<sup>1</sup>                                                          |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| コメントを残す                                                                         |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| 画像上のコメントの位置を変更（ユーザーを問わずアップロードされたもの）<sup>2</sup>                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [インサイト](project/insights/_index.md)を表示                                            |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [要求事項](project/requirements/_index.md)を表示                                    |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [タイムトラッキング](project/time_tracking.md)レポートを表示<sup>1</sup>                    |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [スニペット](snippets.md)を表示                                                           |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [スニペット](snippets.md)とコメントを[検索](search/_index.md)                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [プロジェクトトラフィック統計](../api/project_statistics.md)を表示                        |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [スニペット](snippets.md)を作成                                                         |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [リリース](project/releases/_index.md)を表示<sup>3</sup>                               |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [リリース](project/releases/_index.md)を管理<sup>4</sup>                             |       |         |          |           |     ✓      |   ✓   |
| [Webhook](project/integrations/webhooks.md)を設定                                 |       |         |          |           |     ✓      |   ✓   |
| [プロジェクトアクセストークン](project/settings/project_access_tokens.md)を管理<sup>5</sup> |       |         |          |           |     ✓      |   ✓   |
| [プロジェクトをエクスポート](project/settings/import_export.md)                                    |       |         |          |           |     ✓      |   ✓   |
| プロジェクト名を変更                                                                         |       |         |          |           |     ✓      |   ✓   |
| プロジェクトバッジを編集                                                                    |       |         |          |           |     ✓      |   ✓   |
| プロジェクト設定を編集                                                                  |       |         |          |           |     ✓      |   ✓   |
| [プロジェクトの機能の表示](public_access.md)レベルを変更<sup>6</sup>              |       |         |          |           |     ✓      |   ✓   |
| [プロジェクトインテグレーション](project/integrations/_index.md)のカスタム設定を変更      |       |         |          |           |     ✓      |   ✓   |
| 他のユーザーが投稿したコメントを編集                                                    |       |         |          |           |     ✓      |   ✓   |
| [デプロイキー](project/deploy_keys/_index.md)を追加                                       |       |         |          |           |     ✓      |   ✓   |
| [プロジェクトオペレーション](../operations/_index.md)を管理                                   |       |         |          |           |     ✓      |   ✓   |
| [使用量クォータ](storage_usage_quotas.md)ページを表示                                      |       |         |          |           |     ✓      |   ✓   |
| [スニペット](snippets.md)を全体削除                                                |       |         |          |           |     ✓      |   ✓   |
| [スニペット](snippets.md)を全体編集                                                  |       |         |          |           |     ✓      |   ✓   |
| プロジェクトをアーカイブ                                                                        |       |         |          |           |            |   ✓   |
| プロジェクトの表示レベルを変更                                                        |       |         |          |           |            |   ✓   |
| プロジェクトを削除                                                                         |       |         |          |           |            |   ✓   |
| 通知メールを無効化                                                            |       |         |          |           |            |   ✓   |
| プロジェクトを移行                                                                       |       |         |          |           |            |   ✓   |

**脚注**

<!-- Disable ordered list rule https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md029---ordered-list-item-prefix -->
<!-- markdownlint-disable MD029 -->

1. GitLab Self-Managedでは、ゲストロールを持つユーザーは、公開および内部プロジェクトでのみこのアクションを実行できます（非公開プロジェクトでは実行できません）。[外部ユーザー](../administration/external_users.md)には、プロジェクトが内部であっても、明示的なアクセス権（少なくとも**レポーター**ロール）を付与する必要があります。GitLab.comのゲストロールのユーザーは、内部表示レベルを利用できないため、公開プロジェクトでのみこのアクションを実行できます。
2. [設計管理](project/issues/design_management.md)のデザインに関するコメントにのみ適用されます。
3. ゲストユーザーは、アセットをダウンロードするためにGitLab[**リリース**](project/releases/_index.md)にアクセスできますが、ソースコードをダウンロードしたり、[コミットやリリースエビデンスなどのリポジトリ情報](project/releases/_index.md#view-a-release-and-download-assets)を表示したりすることはできません。
4. [タグが保護されている](project/protected_tags.md)場合、デベロッパーとメンテナーに付与されたアクセス権によって異なります。
5. GitLab Self-Managedの場合、プロジェクトアクセストークンは全プランで利用できます。GitLab.comの場合、プロジェクトアクセストークンはPremiumおよびUltimateプランでサポートされています（[トライアルライセンス](https://about.gitlab.com/free-trial/)を除く）。
6. [プロジェクトの表示レベル](public_access.md)が非公開に設定されている場合、メンテナーまたはオーナーはプロジェクトの機能の表示レベルを変更できません。

   <!-- markdownlint-enable MD029 -->

[GitLab Pages](project/pages/_index.md)のプロジェクト権限:

| アクション                                                                                 | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| -------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| [アクセス制御](project/pages/pages_access_control.md)で保護されたGitLab Pagesを表示 |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| GitLab Pagesを管理                                                                    |       |         |          |           |     ✓      |   ✓   |
| GitLab Pagesのドメインと証明書を管理                                            |       |         |          |           |     ✓      |   ✓   |
| GitLab Pagesを削除                                                                    |       |         |          |           |     ✓      |   ✓   |

### リポジトリ {#repository}

[リポジトリ](project/repository/_index.md)機能（ソースコード、ブランチ、プッシュルールなど）のプロジェクト権限:

| アクション                                                                | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| --------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| プロジェクトコードを表示<sup>1</sup>                                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| プロジェクトコードを[検索](search/_index.md)<sup>2</sup>                  |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| コミットとコメントを[検索](search/_index.md)<sup>3</sup>          |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| プロジェクトコードをプル<sup>4</sup>                                        |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| コミットステータスを表示                                                    |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| コミットステータスを作成<sup>5</sup>                                     |       |         |          |     ✓     |     ✓      |   ✓   |
| コミットステータスを更新<sup>5</sup>                                     |       |         |          |     ✓     |     ✓      |   ✓   |
| [Gitタグ](project/repository/tags/_index.md)を作成                  |       |         |          |     ✓     |     ✓      |   ✓   |
| [Gitタグ](project/repository/tags/_index.md)を削除                  |       |         |          |     ✓     |     ✓      |   ✓   |
| 新しい[ブランチ](project/repository/branches/_index.md)を作成          |       |         |          |     ✓     |     ✓      |   ✓   |
| 保護されていないブランチにプッシュ                                        |       |         |          |     ✓     |     ✓      |   ✓   |
| 保護されていないブランチに強制プッシュ                                  |       |         |          |     ✓     |     ✓      |   ✓   |
| 保護されていないブランチを削除                                         |       |         |          |     ✓     |     ✓      |   ✓   |
| [保護ブランチ](project/repository/branches/protected.md)を管理 |       |         |          |           |     ✓      |   ✓   |
| 保護ブランチにプッシュ<sup>5</sup>                               |       |         |          |           |     ✓      |   ✓   |
| 保護ブランチを削除                                             |       |         |          |           |     ✓      |   ✓   |
| [保護タグ](project/protected_tags.md)を管理                    |       |         |          |           |     ✓      |   ✓   |
| [プッシュルール](project/repository/push_rules.md)を管理                 |       |         |          |           |     ✓      |   ✓   |
| フォーク関係を削除                                              |       |         |          |           |            |   ✓   |
| 保護ブランチに強制プッシュ<sup>6</sup>                         |       |         |          |           |            |       |

**脚注**

<!-- Disable ordered list rule https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md029---ordered-list-item-prefix -->
<!-- markdownlint-disable MD029 -->

1. GitLab Self-Managedでは、ゲストロールを持つユーザーは、公開および内部プロジェクトでのみこのアクションを実行できます（非公開プロジェクトでは実行できません）。[外部ユーザー](../administration/external_users.md)には、プロジェクトが内部であっても、明示的なアクセス権（少なくとも**レポーター**ロール）を付与する必要があります。GitLab.comのゲストロールのユーザーは、内部表示レベルを利用できないため、公開プロジェクトでのみこのアクションを実行できます。GitLab 15.9以降では、Ultimateプランのライセンスを持つゲストロールのユーザーは、管理者（GitLab Self-ManagedまたはGitLab Dedicated）またはグループオーナー（GitLab.com）が許可した場合、非公開リポジトリのコンテンツを表示できます。管理者またはグループオーナーは、APIまたはUIから[カスタムロール](custom_roles/_index.md)を作成し、そのロールをユーザーに割り当てることができます。
2. GitLab Self-Managedでは、ゲストロールを持つユーザーは、公開および内部プロジェクトでのみこのアクションを実行できます（非公開プロジェクトでは実行できません）。[外部ユーザー](../administration/external_users.md)には、プロジェクトが内部であっても、明示的なアクセス権（少なくとも**レポーター**ロール）を付与する必要があります。GitLab.comのゲストロールのユーザーは、内部表示レベルを利用できないため、公開プロジェクトでのみこのアクションを実行できます。GitLab 15.9以降では、Ultimateプランのライセンスを持つゲストロールのユーザーは、管理者（Self-ManagedまたはGitLab Dedicated）またはグループオーナー（GitLab.com）が許可した場合、非公開リポジトリのコンテンツを検索できます。管理者またはグループオーナーは、APIまたはUIから[カスタムロール](custom_roles/_index.md)を作成し、そのロールをユーザーに割り当てることができます。
3. GitLab Self-Managedでは、ゲストロールを持つユーザーは、公開および内部プロジェクトでのみこのアクションを実行できます（非公開プロジェクトでは実行できません）。[外部ユーザー](../administration/external_users.md)には、プロジェクトが内部であっても、明示的なアクセス権（少なくとも**レポーター**ロール）を付与する必要があります。GitLab.comのゲストロールのユーザーは、内部表示レベルを利用できないため、公開プロジェクトでのみこのアクションを実行できます。
4. [ブランチが保護されている](project/repository/branches/protected.md)場合、デベロッパーとメンテナーに付与されたアクセス権によって異なります。
5. GitLab Self-Managedでは、ゲストロールを持つユーザーは、公開および内部プロジェクトでのみこのアクションを実行できます（非公開プロジェクトでは実行できません）。[外部ユーザー](../administration/external_users.md)には、プロジェクトが内部であっても、明示的なアクセス権（少なくとも**レポーター**ロール）を付与する必要があります。GitLab.comのゲストロールのユーザーは、内部表示レベルを利用できないため、公開プロジェクトでのみこのアクションを実行できます。GitLab 15.9以降では、Ultimateプランのライセンスを持つゲストロールのユーザーは、管理者（GitLab Self-ManagedまたはGitLab Dedicated）またはグループオーナー（GitLab.com）が許可した場合、非公開リポジトリのコンテンツを表示できます。管理者またはグループオーナーは、APIまたはUIから[カスタムロール](custom_roles/_index.md)を作成し、そのロールをユーザーに割り当てることができます。
6. ゲスト、レポーター、デベロッパー、メンテナー、またはオーナーには許可されていません。[保護ブランチ](project/repository/branches/protected.md#allow-force-push)を参照してください。

<!-- markdownlint-enable MD029 -->

### マージリクエスト {#merge-requests}

[マージリクエスト](project/merge_requests/_index.md)のプロジェクト権限:

| アクション                                                                                    | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ----------------------------------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| マージリクエストを[表示](project/merge_requests/_index.md#view-merge-requests)<sup>1</sup> |   ✓   |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| マージリクエストとコメントを[検索](search/_index.md)<sup>1</sup>                       |   ✓   |         |    ✓     |     ✓     |     ✓      |   ✓   |
| 内部メモを追加                                                                         |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| コメントおよび提案を追加                                                               |       |    ✓    |    ✓     |     ✓     |     ✓      |   ✓   |
| [スニペット](snippets.md)を作成                                                            |       |         |    ✓     |     ✓     |     ✓      |   ✓   |
| [マージリクエスト](project/merge_requests/creating_merge_requests.md)を作成<sup>2</sup>    |       |         |          |     ✓     |     ✓      |   ✓   |
| マージリクエストの詳細を更新<sup>3</sup>                                                 |       |         |          |     ✓     |     ✓      |   ✓   |
| [マージリクエストの設定](project/merge_requests/approvals/settings.md)を管理             |       |         |          |           |     ✓      |   ✓   |
| [マージリクエスト承認ルール](project/merge_requests/approvals/rules.md)を管理          |       |         |          |           |     ✓      |   ✓   |
| マージリクエストを削除                                                                      |       |         |          |           |            |   ✓   |

**脚注**

1. GitLab Self-Managedでは、ゲストロールを持つユーザーは、公開および内部プロジェクトでのみこのアクションを実行できます（非公開プロジェクトでは実行できません）。[外部ユーザー](../administration/external_users.md)には、プロジェクトが内部であっても、明示的なアクセス権（少なくとも**レポーター**ロール）を付与する必要があります。GitLab.comのゲストロールのユーザーは、内部表示レベルを利用できないため、公開プロジェクトでのみこのアクションを実行できます。
1. 外部メンバーからのコントリビュートを受け入れるプロジェクトでは、ユーザーは自分のマージリクエストを作成、編集、および完了できます。**非公開**プロジェクトの場合、ゲストロールは[非公開プロジェクトをクローンできない](public_access.md#private-projects-and-groups)ため除外されます。**内部**プロジェクトの場合、[内部プロジェクトをクローンできる](public_access.md#internal-projects-and-groups)ため、プロジェクトへの読み取り専用アクセス権を持つユーザーが含まれます。
1. マージリクエストの適格な承認者については、[適格な承認者](project/merge_requests/approvals/rules.md#eligible-approvers)を参照してください。

### ユーザー管理 {#user-management}

[ユーザー管理](project/members/_index.md)のプロジェクト権限。

| アクション                                                           | ゲスト | プランナー | レポーター | デベロッパー | メンテナー | オーナー |
| ---------------------------------------------------------------- | :---: | :-----: | :------: | :-------: | :--------: | :---: |
| メンバーの2FAステータスを表示                                       |       |         |          |           |     ✓      |   ✓   |
| [プロジェクトメンバー](project/members/_index.md)を管理<sup>1</sup> |       |         |          |           |     ✓      |   ✓   |
| グループとプロジェクトを共有（招待）<sup>2</sup>                 |       |         |          |           |     ✓      |   ✓   |

**脚注**

1. メンテナーは、オーナーを作成、降格、または削除することはできず、ユーザーをオーナーロールにプロモートすることもできません。また、オーナーロールのアクセスリクエストを承認することもできません。
1. [グループ共有ロック](project/members/sharing_projects_groups.md#prevent-a-project-from-being-shared-with-groups)が有効になっている場合、プロジェクトを他のグループと共有することはできません。グループとグループの間の共有には影響しません。

## サブグループの権限 {#subgroup-permissions}

メンバーをサブグループに追加すると、そのメンバーは親グループからメンバーシップと権限レベルを継承します。このモデルにより、親グループのいずれかにメンバーシップを持っていれば、ネストされたグループへのアクセスが許可されます。

詳細については、[サブグループメンバーシップ](group/subgroups/_index.md#subgroup-membership)を参照してください。

## 最小アクセス権を持つユーザー {#users-with-minimal-access}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 最小アクセスロールを持つユーザーを招待する機能は、GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106438)されました。

{{< /history >}}

最小アクセスロールを持つユーザーは、次の対象にはなりません:

- トップレベルグループのプロジェクトおよびサブグループに自動的にアクセスできる。
- GitLab Self-ManagedのUltimateサブスクリプションまたはGitLab.comサブスクリプションで、ライセンスシートとしてカウントされる（ユーザーがインスタンスまたはGitLab.comネームスペース内のどこにも他のロールを持っていない場合）。

オーナーは、これらのユーザーを特定のサブグループおよびプロジェクトに明示的に追加する必要があります。

[GitLab.comグループのSAML SSO](group/saml_sso/_index.md)で最小アクセスロールを使用して、グループ階層内のグループおよびプロジェクトへのアクセスを制御できます。SSOを介してトップレベルグループに自動的に追加されたメンバーのデフォルトロールを最小アクセスに設定できます。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定 > SAML SSO**を選択します。
1. **デフォルトのメンバーシップロール**ドロップダウンリストから、**最小アクセス**を選択します。
1. **変更を保存**を選択します。

### 最小アクセスユーザーが404エラーを受け取る場合 {#minimal-access-users-receive-404-errors}

[未解決の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/267996)のため、最小アクセスロールを持つユーザーは以下の状況で404エラーを受け取ります:

- 標準のWeb認証でサインインすると、親グループにアクセスするときに`404`エラーが表示されます。
- グループSSOでサインインすると、親グループページにリダイレクトされるため、すぐに`404`エラーが表示されます。

この問題を回避するには、これらのユーザーに親グループ内の任意のプロジェクトまたはサブグループに対するゲストロール以上を付与します。ゲストユーザーは、Premiumプランではライセンスシートを消費しますが、Ultimateプランでは消費しません。

## 関連トピック {#related-topics}

- [リポジトリを保護する](project/repository/protect.md)
- [カスタムロール](custom_roles/_index.md)
- [メンバー](project/members/_index.md)
- [保護ブランチ](project/repository/branches/protected.md)の権限のカスタマイズ
- [LDAPユーザー権限](group/access_and_permissions.md#manage-group-memberships-with-ldap)
- [バリューストリーム分析の権限](group/value_stream_analytics/_index.md#access-permissions)
- [プロジェクトエイリアス](project/working_with_projects.md#project-aliases)
- [監査担当者ユーザー](../administration/auditor_users.md)
- [非公開イシュー](project/issues/confidential_issues.md)
- [コンテナレジストリの権限](packages/container_registry/_index.md#container-registry-visibility-permissions)
- [リリース権限](project/releases/_index.md#release-permissions)
- [読み取り専用ネームスペース](read_only_namespaces.md)
