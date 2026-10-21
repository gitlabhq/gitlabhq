---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: ビジネスロジックスキャンは、AIエージェントを使用して、ソースコード内の認可およびアクセス制御の脆弱性を検出します。
title: ビジネスロジックスキャン
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.5で、`bl_security_analyzer`（`experiment`タイプ）および`agentic_analyzer_security_ingestion`（`gitlab_com_derisk`タイプ）という名前の[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/257199)されました。デフォルトでは無効になっています。
- GitLab Duo Chatからスキャンを開始するには、`duo_chat_flow_commands`（`wip`タイプ）という名前の[機能フラグ](../../../administration/feature_flags/_index.md)も必要です。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

ビジネスロジックスキャンは、AIエージェントであるビジネスロジックセキュリティアナライザー（BLSA）を使用して、アプリケーションが独自のルールをどのように適用しているかにおける脆弱性を検出します。[SAST](../sast/_index.md)のようなパターンベースのアナライザーでは、コードが有効であり意図のみが誤っているため、これらの脆弱性を見逃すことがよくあります。

## ビジネスロジックスキャンで検出される内容 {#what-business-logic-scanning-finds}

ビジネスロジックスキャンは、次のような脆弱性を検出します:

- 破損したオブジェクトレベル認可（BOLA）。安全でない直接オブジェクト参照（IDOR）とも呼ばれます。たとえば、エンドポイントがURL内のIDによって請求書を読み込み、その請求書が認証済みユーザーに属していることを確認しない場合です。
- 認可の欠落。たとえば、管理操作がユーザーが認証済みであることは確認するが、そのユーザーが管理者であることは確認しない場合です。
- マスアサインメント。たとえば、更新エンドポイントがすべてのリクエストパラメータをモデルに渡すため、ユーザーが自分自身の`role`属性や`is_admin`属性を変更できてしまう場合です。

## ビジネスロジックスキャンの仕組み {#how-business-logic-scanning-works}

ビジネスロジックスキャンは、CI/CDパイプライン内のジョブとしてではなく、[GitLab Duo Agent Platform](../../duo_agent_platform/_index.md)の基本フローとして実行されます。`.gitlab-ci.yml`ファイルにテンプレートやジョブを追加する必要はありません。

スキャンは次のいずれかの方法で開始されます:

| スキャンの開始方法 | スキャン対象 | 有効化方法 |
|---------------------|---------------|-------------------|
| [マージリクエストで自動的に実行](#automatic-merge-request-scans) | マージリクエストが追加または変更したファイル。部分的なスキャン。 | プロジェクトにビジネスロジックスキャンプロファイルをアタッチします。 |
| [GitLab Duo Chatから](#start-a-scan-from-gitlab-duo-chat) | デフォルトブランチ上のリポジトリ全体。リポジトリ全体をスキャンするための推奨方法。 | GitLab Duo Chatでフローコマンドを送信します。 |
| [APIを使用](#start-a-scan-with-the-api) | デフォルトブランチ上のリポジトリ全体。 | APIリクエストを送信します。 |
| [スケジュールによる実行](#scheduled-default-branch-scans) | まだ利用できません。 | まだ利用できません。 |

## ビジネスロジックスキャンを有効にする {#turn-on-business-logic-scanning}

ビジネスロジックスキャンはクローズドベータ版です。GitLab.comでは、GitLabが参加しているトップレベルグループに対して機能フラグを有効にします。アクセスをリクエストするには、アカウントチームにお問い合わせください。

前提条件: 

- GitLab Ultimateサブスクリプション。
- トップレベルグループに対して[GitLab Duo Agent Platformが有効になっている](../../duo_agent_platform/turn_on_off.md)こと。
- トップレベルグループに対して`bl_security_analyzer`および`agentic_analyzer_security_ingestion`機能フラグが有効になっていること。`agentic_analyzer_security_ingestion`がない場合、スキャン結果は脆弱性レポートに表示されません。GitLab Self-Managedでは、管理者がこれらの機能フラグを有効にする必要があります。

ビジネスロジックスキャンを有効にするには:

1. トップレベルグループのオーナーロールを持つユーザーとして、**ビジネスロジックセキュリティスキャン**フローを含む[基本フローを有効にします](../../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off)。
1. スキャンする各プロジェクトに[ビジネスロジックスキャンプロファイルをアタッチします](../configuration/security_configuration_profiles.md#business-logic-profile)。スキャンプロファイルUIが利用可能になるまでは、[GraphQL APIを使用してプロファイルをアタッチします](../configuration/security_configuration_profiles.md#apply-a-profile-with-the-graphql-api)。

## マージリクエストの自動スキャン {#automatic-merge-request-scans}

プロジェクトにビジネスロジックスキャンプロファイルがアタッチされている場合、各マージリクエストに対してスキャンが実行されます:

- スキャンは、マージリクエストのheadパイプライン（オープンなマージリクエストのマージリクエストパイプラインまたはブランチパイプラインのいずれか）で実行されます。
- スキャンはパイプラインが成功した後に開始されます。パイプラインが失敗した場合、またはプロジェクトにCI/CDパイプラインがない場合、スキャンは実行されません。
- スキャンは、マージリクエストが追加または変更したファイルのみをチェックします。
- パイプラインを実行したユーザーは、デベロッパーロール以上を持ち、GitLab Duo Agent Platformにアクセスできる人間のユーザーである必要があります。

次のマージリクエストはスキャンされません:

- フォークからのマージリクエスト。
- ファイルの削除のみを行うマージリクエスト。
- プロジェクトアクセストークンやサービスアカウントなど、ボットによって実行されたパイプラインを持つマージリクエスト。
- マージトレインのパイプライン、および新しいコミットによって置き換えられたマージリクエストパイプライン。

マージリクエストのスキャンは変更されたファイルのみをチェックするため、GitLab Advanced SASTの[差分ベースのスキャン](../sast/gitlab_advanced_sast.md#diff-based-scanning)と同様に部分的なスキャンです。スキャンされなかったファイル内の脆弱性は、修正済みとして報告されません。

## スケジュールされたデフォルトブランチのスキャン {#scheduled-default-branch-scans}

スケジュールされたスキャンはまだ利用できません。自動スキャンはデフォルトブランチでは実行されません。デフォルトブランチをスキャンするには、[GitLab Duo Chatからスキャンを開始する](#start-a-scan-from-gitlab-duo-chat)か、[APIを使用](#start-a-scan-with-the-api)してください。

## GitLab Duo Chatからスキャンを開始する {#start-a-scan-from-gitlab-duo-chat}

リポジトリ全体をスキャンするには、GitLab Duo Chatからスキャンを開始します。スキャンはデフォルトブランチをチェックし、追跡可能なGitLab Duo Agent Platformセッションとして実行されます。結果は[脆弱性レポート](../vulnerability_report/_index.md)に表示されます。

前提条件: 

- プロジェクトのデベロッパーロール以上が必要です。
- [GitLab Duo Agent Platformの前提条件](../../duo_agent_platform/_index.md#prerequisites)を満たしている必要があります。
- `bl_security_analyzer`、`agentic_analyzer_security_ingestion`、`duo_chat_flow_commands`機能フラグが有効になっており、**ビジネスロジックセキュリティスキャン**フローが有効になっている必要があります。プロジェクトにビジネスロジックスキャンプロファイルは必要ありません。

スキャンを開始するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. [GitLab Duo Chat](../../gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-the-gitlab-ui)を開き、**エージェント**トグルが有効になっていることを確認します。
1. チャットのテキストボックスに`/flow:`と入力し、**ビジネスロジックセキュリティスキャン**を選択します。
1. 他のテキストを追加せずにコマンドを送信します。
1. エージェントセッションでスキャンを追跡します。セッションが終了すると、結果が脆弱性レポートに表示されます。

スキャンのCI/CDジョブは、フローのサービスアカウントとして実行されます。

> [!warning]
> コマンドの後にマージリクエスト番号やその他のテキストを追加しないでください。GitLab Duo Chatからのスキャンは常にデフォルトブランチで実行されるため、マージリクエストの変更ではなくリポジトリ全体をスキャンします。

## APIでスキャンを開始する {#start-a-scan-with-the-api}

[GitLab Duo Agent Platform flows API](../../../api/duo_agent_platform_flows.md#trigger-a-flow)を使用して、デフォルトブランチの完全スキャンを開始できます。このスキャンは、ユーザーの権限とGitLab Duo Agent Platformアクセスを使用して、ユーザーの代わりに実行され、リポジトリ全体をチェックします。結果は脆弱性レポートに表示されます。

前提条件: 

- プロジェクトのデベロッパーロール以上が必要です。
- `api`スコープを持つパーソナルアクセストークンが必要です。
- `bl_security_analyzer`および`agentic_analyzer_security_ingestion`機能フラグが有効になっており、**ビジネスロジックセキュリティスキャン**フローが有効になっている必要があります。プロジェクトにビジネスロジックスキャンプロファイルは必要ありません。

スキャンを開始するには、リクエストを送信します:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "project_id=<project_id>" \
  --data "workflow_definition=bl_security/experimental" \
  --data "start_workflow=true" \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

`workflow_definition`の代わりに、プロジェクトの**ビジネスロジックセキュリティスキャン**フローコンシューマーのIDを指定して`ai_catalog_item_consumer_id`を渡すことができます。IDを取得するには、`aiCatalogConfiguredItems`のGraphQLクエリを使用します。詳細は[コンシューマーIDを調べる](../../../api/duo_agent_platform_flows.md#look-up-the-consumer-id)を参照してください。

マージリクエストが変更したファイルのみをスキャンするには、マージリクエストのIIDを`goal`として、マージリクエストのソースブランチを`source_branch`として渡します。マージリクエストはフォークからのものであってはなりません。デフォルトブランチ以外のブランチでは、[`BL_TARGET_FILES`](#configure-a-scan) CI/CD変数が設定されている場合、マージリクエストの変更されたファイルを置き換えます。それ以外の場合、スキャンはリポジトリ全体をチェックします。

## 結果を表示する {#view-results}

ビジネスロジックスキャンは、他のセキュリティスキャナーと同じ場所に脆弱性を報告します:

- マージリクエストのスキャンについては、[マージリクエストセキュリティウィジェット](../detect/security_scanning_results.md#merge-request-reports)内。
- デフォルトブランチのスキャンについては、脆弱性レポート内。

## スキャンを設定する {#configure-a-scan}

ビジネスロジックスキャンの実行方法を変更するには、[プロジェクトのCI/CD変数](../../../ci/variables/_index.md#for-a-project)を追加します。環境スコープを**すべて (デフォルト)**に設定します。他のスコープを持つ変数は無視されます。

保護された変数とファイルタイプの変数は無視されます。これらは、`*`環境スコープを持つ通常の保護されていない変数として定義してください。

| CI/CD変数    | 説明 |
|-------------------|-------------|
| `BL_SCAN_EFFORT`  | スキャンの処理量レベル: `low`、`standard`、または`high`。未設定、空、またはそれ以外の値の場合、レベルは`low`になります。より高いレベルでは、より深くスキャンし、より多くのGitLab Duo Agent Platformの使用量を消費します。 |
| `BL_TARGET_FILES` | スキャンするファイルパスの、改行またはカンマ区切りのリスト。デフォルトブランチ以外のブランチでのスキャンに適用され、マージリクエストが変更したファイルを置き換えます。デフォルトブランチでは無視されるため、デフォルトブランチのスキャンはリポジトリ全体をチェックします。 |

スキャンは開始時に、プロジェクトのCI/CD設定からこれらの変数を読み取ります。`.gitlab-ci.yml`で設定された変数や、パイプライン実行時に設定された変数は適用されません。

## 既知の問題 {#known-issues}

ビジネスロジックスキャンには、以下の既知の問題があります:

- マージリクエストが400を超えるファイルを変更する場合、またはその差分が大きすぎて収集できない場合、スキャンは変更されたファイルに限定されません。代わりにリポジトリ全体のフルスキャンが実行され、その結果は部分的なスキャンにはなりません。
- スキャンは、一定量までのコードを分析します。この上限に達したスキャンも、フルスキャンとしてカウントされます。スキャンがスキップしたコード内の脆弱性は、検出されなくなったものとしてマークされ、後のスキャンで再び出現することがあります。
- スキャンは、前提条件にある機能フラグが有効になっている場合にのみ実行されます。自動スキャンは、[マージリクエストの自動スキャン](#automatic-merge-request-scans)に記載されているユーザーに対してのみ実行されます。
- スケジュールされたスキャンはまだ利用できません。詳細については、[スケジュールされたデフォルトブランチのスキャン](#scheduled-default-branch-scans)を参照してください。
- GitLab Duo Chatからのスキャンは常にデフォルトブランチで実行されます。フローコマンドの後にマージリクエスト番号やその他のテキストを追加しても、スキャンはリポジトリ全体をチェックします。マージリクエストの変更はチェックされません。他のテキストを追加せずにコマンドを送信します。マージリクエストの変更をスキャンするには、[APIを使用してください](#start-a-scan-with-the-api)。

## コスト {#cost}

各スキャンはGitLab Duo Agent Platformセッションであり、[GitLabクレジット](../../../subscriptions/gitlab_credits.md)を消費します。大規模なマージリクエストやリポジトリ全体のスキャンは、小さな変更のスキャンよりも多くのクレジットを消費します。
