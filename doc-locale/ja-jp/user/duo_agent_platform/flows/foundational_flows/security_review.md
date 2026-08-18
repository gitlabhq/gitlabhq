---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Security Review Flow
description: ビジネスロジックの脆弱性をマージリクエストでAIによって特定します。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/600301)されました。この機能は[ベータ版](../../../../policy/development_stages_support.md#beta)です。

{{< /history >}}

Security Review Flowは、マージリクエスト内のビジネスロジックの脆弱性を検出します。既知のパターンをスキャンする静的解析ツールとは異なり、Security Review Flowはコードの意図について推論します。認可、データ公開、および制御フローに関する誤った仮定から生じる脆弱性を特定します。

Security Review Flowは、GitLab Duo Agent Platform上に構築された[基本フロー](_index.md)です。これは[GitLab Duoコードレビュー](../../../gitlab_duo/code_review.md)と連携し、CWE分類、重大度評価、説明、そして可能な場合は1つのアクションで適用できるインラインの提案された修正を含む、スレッド化された差分コメントとして検出結果を投稿します。

> [!note]
> Security Review FlowのAI生成された結果は助言的な入力であり、権威的または完全なセキュリティ評価ではありません。所見がないとレポートされたレビューは、マージリクエストが安全であるという証明ではなく、所見には人間の判断を必要とする誤検出が含まれる可能性があります。詳細については、[既知の制限](#known-limitations)を参照してください。

Security Review Flowを次の場合に活用してください:

- アクセス制御のレビュー: 状態変更操作における欠落または誤設定された認可チェックを特定します。
- 認可ギャップの検出: 破損したオブジェクトレベルおよび機能レベルの認可イシューを明らかにします。
- ビジネスロジックの分析: 金融またはステートフルな操作における競合状態など、悪用される可能性のあるアプリケーションワークフローの欠陥を検出します。
- 情報漏えい: 不正な呼び出し元に機密情報を漏洩させる可能性のあるコードパスを特定します。
- 一括割り当てリスク: 意図しないフィールドをユーザー入力に公開する可能性のあるエンドポイントまたはモデルにフラグを付けます。

## 前提条件 {#prerequisites}

Security Review Flowを使用するには:

- プロジェクトのデベロッパー、メンテナー、またはオーナーロールを持っていること。
- 基本フローと**セキュリティレビュー**をトップレベルグループで[有効にする](_index.md#turn-foundational-flows-on-or-off)。
- グループまたはインスタンスで[GitLab Duoを有効にする](../../../gitlab_duo/turn_on_off.md)。
- GitLab Duo ProまたはEnterpriseがない場合は、トップレベルグループまたはインスタンスで[GitLab Duo Coreを有効にする](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off)。
- GitLab Self-Managedの場合、インスタンス用に[GitLab Duoを設定する](../../../../administration/gitlab_duo/configure/_index.md)。
- GitLab 18.8以降では、トップレベルグループで[Agent Platformを有効にする](../../turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off)。GitLab 18.7以前では、[ベータ版および実験的機能を有効にする](../../turn_on_off.md#turn-on-beta-and-experimental-features)。

## コスト {#cost}

Security Review Flowはレビューを実行するたびに[GitLabクレジット](../../../../subscriptions/gitlab_credits.md)を使用します。クレジットの使用量は、差分の複雑さと選択するモデルに応じてスケールします。

以下の見積もりは[デフォルトモデル](../../../../user/duo_agent_platform/model_selection.md#default-models)に適用されます:

| レビューの複雑さ                        | 概算LLM呼び出し | 推定クレジット |
|------------------------------------------|-----------------------|-------------------|
| 小さな差分または変更された少数のファイル        | 約16                   | 約8                |
| 標準的なフィーチャーブランチ                  | 約28                   | 約14               |
| 大規模またはロジックの多い複数ファイルの変更   | 約40                   | 約20               |

ベータリリース期間中は、常に手動でレビューを開始します。これにより、幅広い導入の前に、コードベースにおける一般的なクレジット使用量を評価できます。

## Security Review Flowの使用 {#use-security-review-flow}

### レビューをリクエストする {#request-a-review}

マージリクエストが作成された後、いつでもレビューをリクエストできます。レビューをリクエストすると、フローはマージリクエストの差分とその周辺コンテキストを分析します。

Security Reviewフローが有効になると、トップレベルグループに**Duo Security Review**サービスアカウントが作成され、その内部のすべてのプロジェクトとサブグループで利用可能になります。各サービスアカウント名には、関連付けられたトップレベルグループが含まれます。例: `duo-security-review-gitlab-org`。

レビューをリクエストするには:

1. 左サイドバーで、**検索または移動先**を選択し、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択して、マージリクエストを開きます。
1. 右サイドバーの**レビュアー**セクションで、**編集**を選択します。
1. 検索ボックスに`Duo Security Review`と入力し、リストからアカウントを選択します。

レビューが完了すると、フローは内部メモを投稿します。メモには、すべての検出結果とレビュースコープが要約されます。レビューで検出結果が生成されない場合、フローは内部メモでその旨を伝えます。

各検出結果について、フローは関連する行に差分スレッドを開きます。スレッドに返信すると（例えば、リスクを受け入れるか、評価に同意しない場合）、フローはあなたの返信を読み取り、それに応じて応答します。公開プロジェクトでは、検出結果は内部メモにのみ投稿され、インライン差分コメントはありません。検出結果を非公開に投稿することで、セキュリティ詳細の公開を回避できます。

フローは、検出結果の重大度に基づいてレビュアーの状態を設定します。フローは、イシューが見つからない場合でも、**承認する**状態を設定することはありません:

| 重大度             | レビュアーの状態 |
| -------------------- | -------------- |
| `critical`または`high` | **変更の要求** |
| `medium`または`low`    | **コメント**    |
| なし                 | **コメント**    |

### 検出結果への応答 {#respond-to-a-finding}

{{< history >}}

- メンションへの返信の配信は、GitLab 19.2で`ai_use_messaging_adapter_for_mentions`という名前の[フラグ](../../../../administration/feature_flags/_index.md)により[変更されました](https://gitlab.com/gitlab-org/gitlab/-/work_items/604317)。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。フラグが無効になっている場合、メンションはターゲットを絞った返信ではなく、完全なレビューを開始します。詳細については、[メンションが返信ではなく完全なレビューを開始する](#a-mention-starts-a-full-review-instead-of-a-reply)を参照してください。

検出結果に関する説明を求めたり、修正アプローチを議論したり、検出結果を誤検出としてフラグ付けしたりするために、フローをスレッドで言及します。言及された場合、フローは完全な再レビューを実行しません。

検出結果に応答するには:

1. 左サイドバーで、**検索または移動先**を選択し、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択して、マージリクエストを開きます。
1. 任意のコメントスレッドで、`@duo-security-review`と入力し、リストから**Duo Security Review**を選択します。
1. メッセージを追加し、**コメント**を選択します。

Security Review Flowはスレッドのコンテキストを読み取り、直接応答します。

### 検出結果をレビュー {#review-a-finding}

Security Review Flowは、静的解析ツールが見落としがちなロジックレベルの脆弱性に焦点を当てています。各検出結果は、変更されたコードに対する差分スレッドとして投稿されます。各スレッドには以下が含まれます:

- MITREの定義へのリンク付き脆弱性タイプ（CWE）。
- 重大度評価: `critical`、`high`、`medium`、または`low`。
- プラン分類: Tier 1（悪用可能）、Tier 2（ロジックの欠陥）、またはTier 3（設計上のイシュー）。
- ロジックの欠陥の説明。
- 可能な場合は、提案された修正。

> [!note]
> 検出結果は[脆弱性レポート](../../../application_security/vulnerability_report/_index.md)で追跡されず、[マージリクエスト承認ポリシー](../../../application_security/policies/merge_request_approval_policies.md)にはカウントされません。これらは静的な解析（SAST）の検出結果を補完しますが、置き換えるものではありません。

以下のCWE分類が検出結果に表示されることがあります:

| CWE | 説明 |
|-----|-------------|
| [CWE-639](https://cwe.mitre.org/data/definitions/639.html) | ユーザー制御のキーによる認可バイパス（BOLA / IDOR） |
| [CWE-862](https://cwe.mitre.org/data/definitions/862.html) | 不足している認可 |
| [CWE-284](https://cwe.mitre.org/data/definitions/284.html) | 不適切なアクセス制御 |
| [CWE-200](https://cwe.mitre.org/data/definitions/200.html) | 機密情報の漏洩 |
| [CWE-840](https://cwe.mitre.org/data/definitions/840.html) | ビジネスロジックのロジックエラー |
| [CWE-915](https://cwe.mitre.org/data/definitions/915.html) | 動的に決定されるオブジェクト属性の不適切に制御された変更（一括割り当て） |
| [CWE-362](https://cwe.mitre.org/data/definitions/362.html) | 競合状態とチェック時間 / 使用時間（TOCTOU） |

### 検出結果を解決する {#resolve-a-finding}

検出結果を解決するには:

- 修正を適用するには、**提案を適用**を選択します。代わりに、提案を新しいブランチにコミットするには、**提案を適用**の横にあるドロップダウンリストを選択します。
- 検出結果を無視するには、検出結果をレビューし、それが誤検出であるか、または受け入れられたリスクであると判断した場合は、**スレッドを解決にする**を選択します。
- 将来の修正のために脆弱性を追跡するには、標準のGitLab [スレッドアクション](../../../../user/project/merge_requests/_index.md#move-open-threads-to-an-issue)を使用して、検出結果からイシューを作成します。
- 検出結果の有用性を評価するには、**thumbs up**または**thumbs down**を選択します。このフィードバックはモデルの改善に役立ちます。詳細なフィードバックを[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/600304)で共有することもできます。

検出結果を解決する後に別のレビューをリクエストするには、フローをレビュアーとして再割り当てします。フローは更新された差分を分析し、検出結果の状態に応じてアクションを実行します:

- 解決済みの検出結果: フローは修正を確認し、元のスレッドを解決します。
- 誤った、または不完全な修正: フローは、元のスレッドで必要とされる追加の変更を特定します。
- 未処理の検出結果: 元のスレッドは、追加のコメントなしで開いたままになります。
- 新しい検出結果: フローは、修正によって導入された新しい脆弱性を検出し、それらの新しいコメントスレッドを作成します。

## 既知の制限事項 {#known-limitations}

Security Review Flowの出力に依存する前に、以下の制限を理解してください。

- 所見は助言であり、カバレッジを保証するものではありません。Security Review Flowの結果はAI生成されます。このフローは変更内のすべての脆弱性を表面化しない可能性があります。その分析は、制限された検索および読み取りの範囲内で機能するため、非常に大きなファイルや差分は完全にレビューされない可能性があります。所見がないとレポートされたレビューは、マージリクエストが安全であるという証明ではありません。
- 所見には誤検出が含まれる可能性があります。所見は人間の判断を必要とする入力として扱い、最終的な裁定として扱わないでください。
- Security Review Flowは他のツールを補完します。これは、人間のセキュリティレビューや、[SAST](../../../application_security/sast/_index.md)および[GitLab高度なSAST](../../../application_security/sast/gitlab_advanced_sast.md)などの他のGitLabセキュリティツールを置き換えるものではありません。

## トラブルシューティング {#troubleshooting}

Security Review Flowを使用すると、以下のイシューに遭遇する可能性があります。

### フローを割り当てることはできません {#the-flow-is-not-available-to-assign}

Security Reviewフローが有効になると、トップレベルグループに**Duo Security Review**サービスアカウントが作成されます。サービスアカウント名には、トップレベルグループ名が含まれます。例: `duo-security-review-gitlab-org`。

Security Reviewフローのステータスを確認します。

### フローが検出結果を提供しない {#the-flow-does-not-provide-findings}

すべての[前提条件](#prerequisites)を満たしていることを確認し、フローが正しく割り当てられていることを確認してください。

- **Duo Security Review**アカウント（ユーザー名は`@duo-security-review-`で始まります）を言及したことを確認してください。
- トップレベルグループで[**基本フローを許可**](_index.md#turn-foundational-flows-on-or-off)と[**コードレビュー**](code_review.md)の設定が有効になっていることを確認してください。
- GitLab Self-Managedの場合、インスタンスが[GitLab Duo用に設定済み](../../../../administration/gitlab_duo/configure/_index.md)であることを確認してください。

### フローがすべてのマージリクエストをレビューしない {#the-flow-does-not-review-every-merge-request}

このセキュリティスキャンを実行するには、マージリクエストでフローを手動でトリガーする必要があります。すべてのマージリクエストで自動的に実行されるわけではありません。フローを割り当てたにもかかわらず所見が得られなかった場合は、[フローが所見を提供しない](#the-flow-does-not-provide-findings)を参照してください。

フローがマージリクエストをレビューするとき、所見のないレポートは通常、次のことを意味します:

- セキュリティイシューは検出されませんでした: コードロジックが分析され、脆弱性は特定されませんでした。
- セキュリティ関連のロジックなし: この変更には、セキュリティに影響を与えるコード（たとえば、ドキュメントのみの更新）は含まれていません。

大規模な変更に関する注意: 大規模なマージリクエストの場合、フローは制限された検索および読み取りの範囲内で動作します。これらの場合、フローは所見をレポートしない、または所見を出力するものの、完全なマージリクエストをカバーできず、重要な脆弱性が見逃される可能性があります。完了したレビューは、完全なカバレッジを保証するものではありません。詳細については、[既知の制限](#known-limitations)を参照してください。

### メンションが返信ではなく完全なレビューを開始する {#a-mention-starts-a-full-review-instead-of-a-reply}

フローは、`ai_use_messaging_adapter_for_mentions`機能フラグが有効になっている場合にのみ、ターゲットを絞った返信でメンションに応答します。フラグが無効になっている場合、メンションは代わりにマージリクエストの完全なレビューを開始します。

- GitLab Self-ManagedおよびGitLab Dedicatedでは、管理者が`ai_use_messaging_adapter_for_mentions`という名前の機能フラグを有効にできます。
- GitLab.comでは、GitLabが返信のサポートをロールアウトしている間、このフラグは無効になっています。ロールアウトが完了するまで、メンションは完全なレビューを開始します。ロールアウトのステータスについては、[イシュー602269](https://gitlab.com/gitlab-org/gitlab/-/issues/602269)を参照してください。

### 提案された変更がクリーンに適用されない {#suggested-changes-do-not-apply-cleanly}

提案はレビュー時の差分に対して生成されます。レビュー後に新しいコミットをプッシュした場合、行番号がずれている可能性があります。現在の差分に対して更新された提案を取得するには、新しいレビューをリクエストします。

### GitLabクレジットに関するエラーが発生しました {#i-received-an-error-about-gitlab-credits}

現在の請求期間中に、お使いのインスタンスまたはグループの[GitLabクレジット](../../../../subscriptions/gitlab_credits.md)が使い果たされた可能性があります。追加のクレジットを購入するには、管理者に問い合わせるか、次の請求期間の開始時にクレジットがリセットされるまでお待ちください。
