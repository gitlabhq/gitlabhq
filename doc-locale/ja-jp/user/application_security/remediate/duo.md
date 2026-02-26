---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AIで脆弱性を解決
---

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo Enterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- [デフォルトのLLM](../../gitlab_duo/model_selection.md#default-models)
- Amazon QのLLM: Amazon Q Developer
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

GitLab Duo脆弱性解決は、セキュリティ脆弱性を自動的に解決するのに役立ちます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [概要を見る](https://www.youtube.com/watch?v=VJmsw_C125E&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

## AI支援を責任を持って使用する {#use-ai-assistance-responsibly}

すべてのAIベースのシステムと同様に、大規模言語モデルが常に正しい結果を生成することを保証することはできません。提案された変更をマージする前に、必ずレビューする必要があります。レビューする際は、以下を確認してください:

- アプリケーションの既存の機能が維持されていること。
- その脆弱性が、組織の標準に従って解決されていること。

## 前提条件 {#prerequisites}

- プロジェクトのメンバーである必要があります。
- 脆弱性は、サポートされているアナライザーからのSAST検出である必要があります:
  - 任意の[GitLabでサポートされているアナライザー](../sast/analyzers.md)。
  - 脆弱性の場所と各脆弱性のCWE識別子を報告する、適切に統合されたサードパーティのSASTスキャナー。
- 脆弱性は、[サポートされているタイプ](#supported-vulnerabilities-for-vulnerability-resolution)である必要があります。

[すべてのGitLab Duo機能を有効にする方法](../../gitlab_duo/turn_on_off.md)の詳細をご覧ください。

## 脆弱性解決でサポートされている脆弱性 {#supported-vulnerabilities-for-vulnerability-resolution}

提案された解決策が高品質であることを保証するために、脆弱性解決は特定の脆弱性セットで利用できます。システムは、脆弱性のCommon Weakness Enumeration（CWE）識別子に基づいて、脆弱性解決を提供するかどうかを決定します。

自動化されたシステムとセキュリティ専門家によるテストに基づいて、現在の脆弱性セットを選択しました。より多くの種類の脆弱性にカバレッジを展開するために、積極的に取り組んでいます。

<details><summary style="color:#5943b6; margin-top: 1em;"><a>Vulnerability ResolutionでサポートされているCWEの完全なリストを表示する</a></summary>

<ul>
  <li>CWE-23: 相対パストラバーサル</li>
  <li>CWE-73: ファイル名またはパスの外部制御</li>
  <li>CWE-78: OSコマンドで使用される特殊文字の不適切なニュートラル化（「OSコマンドインジェクション」）</li>
  <li>CWE-80: Webページのスクリプト関連HTMLタグの不適切なニュートラル化（Basic XSS）</li>
  <li>CWE-89: SQLコマンドで使用される特殊文字の不適切なニュートラル化（「SQLインジェクション」）</li>
  <li>CWE-116: 出力の不適切なエンコードまたはエスケープ</li>
  <li>CWE-118: インデックス可能なリソースの不正なアクセス（「範囲エラー」）</li>
  <li>CWE-119: メモリーバッファの範囲内での操作の不適切な制限</li>
  <li>CWE-120: 入力サイズのチェックなしのバッファコピー（「Classicバッファオーバーフロー」）</li>
  <li>CWE-126: バッファオーバーリード</li>
  <li>CWE-190: 整数のオーバーフローまたはラップアラウンド</li>
  <li>CWE-200: 権限のないアクターへの機密情報の公開</li>
  <li>CWE-208: 観測可能なタイミングのずれ</li>
  <li>CWE-209: 機密情報を含むエラーメッセージの生成</li>
  <li>CWE-272: 最小特権の違反</li>
  <li>CWE-287: 不適切な認証</li>
  <li>CWE-295: 不適切な証明書の検証</li>
  <li>CWE-297: ホストのミスマッチによる証明書の不適切な検証</li>
  <li>CWE-305: 主要な脆弱性による認証バイパス</li>
  <li>CWE-310: 暗号学的な問題</li>
  <li>CWE-311: 機密情報の暗号化の欠落</li>
  <li>CWE-323: 暗号化におけるNonce、キーペアの再利用</li>
  <li>CWE-327: 破損した、または危険な暗号学的アルゴリズムの使用</li>
  <li>CWE-328: 脆弱なハッシュの使用</li>
  <li>CWE-330: 不十分にランダムな値の使用</li>
  <li>CWE-338: 暗号学的に脆弱な擬似乱数ジェネレーター（PRNG）の使用</li>
  <li>CWE-345: データ信頼性の不十分な検証</li>
  <li>CWE-346: オリジン検証エラー</li>
  <li>CWE-352: クロスサイトリクエストフォージェリ</li>
  <li>CWE-362: 不適切な同期を使用した共有リソースを使用した同時実行（「競合状態」）</li>
  <li>CWE-369: ゼロ除算</li>
  <li>CWE-377: 安全でない一時ファイル</li>
  <li>CWE-378: 安全でない権限を持つ一時ファイルの作成</li>
  <li>CWE-400: 制御されていないリソース消費</li>
  <li>CWE-489: アクティブなデバッグコード</li>
  <li>CWE-521: 脆弱なパスワード要件</li>
  <li>CWE-539: 機密情報を含む永続的なCookieの使用</li>
  <li>CWE-599: OpenSSL証明書の検証の欠落</li>
  <li>CWE-611: XML外部エンティティ参照の不適切な制限</li>
  <li>CWE-676: 潜在的に危険な関数の使用</li>
  <li>CWE-704: 不正な型変換またはキャスト</li>
  <li>CWE-754: 異常または例外的な状態の不適切なチェック</li>
  <li>CWE-770: 制限またはスロットリングなしのリソースの割り当て</li>
  <li>CWE-1004: 'HttpOnly'フラグのない機密Cookie</li>
  <li>CWE-1275: 不適切なSameSite属性を持つ機密Cookie</li>
</ul>
</details>

## 脆弱性解決のためにサードパーティのAI APIと共有されるデータ {#data-shared-with-third-party-ai-apis-for-vulnerability-resolution}

次のデータは、サードパーティのAI APIと共有されます:

- 脆弱性名
- 脆弱性の説明
- 識別子（CWE、OWASP）
- 脆弱なコード行を含むファイル全体
- 脆弱なコード行（行番号）

## ワークフロー {#workflows}

脆弱性解決は、さまざまなワークフローで利用できます。次のことができます: 

- 脆弱性レポートから既存の脆弱性を解決します。
- マージリクエストのコンテキストで脆弱性を解決します。

### 脆弱性レポートから既存の脆弱性を解決する {#resolve-an-existing-vulnerability-from-the-vulnerability-report}

{{< history >}}

- GitLab 16.7で、GitLab.comの[導入](https://gitlab.com/groups/gitlab-org/-/epics/10779)されました（[実験](../../../policy/development_stages_support.md#experiment)）。
- GitLab 17.3でベータに変更されました。
- GitLab 17.6以降、GitLab Duoアドオンが必須になりました。

{{< /history >}}

#### 脆弱性解決をサポートする脆弱性を見つける {#find-vulnerabilities-that-support-vulnerability-resolution}

{{< history >}}

- 脆弱性解決アクティビティアイコン:
  - [導入](https://gitlab.com/groups/gitlab-org/-/epics/15036) GitLab 17.5（[`vulnerability_report_vr_badge`](https://gitlab.com/gitlab-org/gitlab/-/issues/486549)という名前のフラグを使用）。デフォルトでは無効になっています。
  - GitLab 17.6では、[デフォルトで有効になっています](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171718)。
  - GitLab 18.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/503568)になりました。機能フラグ`vulnerability_report_vr_badge`は削除されました。

{{< /history >}}

脆弱性を解決するには、以下を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **脆弱性レポート**を選択します。
1. オプション。デフォルトのフィルターを削除するには、**クリア**（{{< icon name="clear" >}}）を選択します。
1. 脆弱性のリストの上にある、フィルターバーを選択します。
1. 表示されるドロップダウンリストで、**アクティビティ**を選択し、**GitLab Duo (AI)**カテゴリの**脆弱性の解決策は利用可能**を選択します。
1. フィルターフィールドの外側を選択します。脆弱性の重大度の合計と、一致する脆弱性のリストが更新されます。
1. 解決するSAST脆弱性を選択します。
   - 青色のアイコンは、脆弱性解決をサポートする脆弱性の横に表示されます。

#### 選択した脆弱性を解決する {#resolve-the-selected-vulnerability}

解決をサポートする脆弱性を選択したら、次の手順を実行します:

1. 右上隅で、**AIを使用して解決する**を選択します。このプロジェクトがパブリックプロジェクトである場合は、MRを作成すると、脆弱性と提供された解決策が公開されることに注意してください。MRを非公開で作成するには、[非公開フォークを作成](../../project/merge_requests/confidential.md)し、このプロセスを繰り返します。
1. 追加のコミットをMRに追加します。これにより、新しいパイプラインが強制的に実行されます。
1. パイプラインが完了したら、[パイプラインのセキュリティータブ](../detect/security_scanning_results.md)で、脆弱性が表示されなくなったことを確認します。
1. 脆弱性レポートで、[脆弱性を手動で更新](../vulnerability_report/_index.md#change-status-of-vulnerabilities)します。

AI修正の提案を含むマージリクエストが開きます。提案された変更をレビューし、標準のワークフローに従ってマージリクエストを処理します。

この機能に関するフィードバックは、[イシュー476553](https://gitlab.com/gitlab-org/gitlab/-/issues/476553)で提供してください。

### マージリクエストで脆弱性を解決する {#resolve-a-vulnerability-in-a-merge-request}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14862)されました。
- GitLab 17.7で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175150)。
- GitLab 17.11[で一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185452)になりました。機能フラグ`resolve_vulnerability_in_mr`は削除されました。

{{< /history >}}

GitLab Duo脆弱性解決をマージリクエストで使用して、マージされる前に脆弱性を修正できます。脆弱性解決は、脆弱性の検出を解決するマージリクエストの提案コメントを自動的に作成します。

脆弱性の検出を解決するには、以下を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **マージリクエスト**を選択します。
1. マージリクエストを選択します。
   - 脆弱性解決でサポートされている脆弱性の検出は、タヌキAIアイコン（{{< icon name="tanuki-ai" >}}）で示されます。
1. サポートされている検出を選択して、セキュリティ検出ダイアログを開きます。
1. 右下隅で、**AIを使用して解決する**を選択します。

AI修正の提案を含むコメントがマージリクエストで開きます。提案された変更をレビューし、標準のワークフローに従ってマージリクエストの提案を適用します。

この機能に関するフィードバックは、[イシュー476553](https://gitlab.com/gitlab-org/gitlab/-/issues/476553)で提供してください。

## トラブルシューティング {#troubleshooting}

脆弱性解決では、提案された修正を生成できない場合があります。一般的な原因は次のとおりです:

- 誤検出がある: 
  - 修正を提案する前に、AIモデルは脆弱性が有効かどうかを評価します。その脆弱性が真の脆弱性ではない、または修正する価値がないと判断する場合があります。
  - これは、脆弱性がテストコードで発生した場合に発生する可能性があります。組織は、脆弱性がテストコードで発生した場合でも、脆弱性を修正することを選択する可能性がありますが、モデルはこれらを誤検出と評価する場合があります。
  - 脆弱性が誤検出である、または修正する価値がないことに同意する場合は、[脆弱性を無視する](../vulnerabilities/_index.md#vulnerability-status-values) 、[一致する理由を選択](../vulnerabilities/_index.md#vulnerability-dismissal-reasons)する必要があります。
    - SAST設定をカスタマイズするか、GitLab SASTルールに関する問題を報告するには、[SASTルール](../sast/rules.md)を参照してください。
- 一時的または予期しないエラー: 
  - エラーメッセージには、`an unexpected error has occurred`、`the upstream AI provider request timed out`、`something went wrong`、または同様の原因が記載されている場合があります。
  - これらのエラーは、AIプロバイダーまたはGitLab Duoの一時的な問題が原因である可能性があります。
  - 新しいリクエストが成功する可能性があるため、脆弱性の解決をもう一度試すことができます。
  - これらのエラーが引き続き表示される場合は、GitLabにお問い合わせください。
- `Resolution target could not be found in the merge request, unable to create suggestion`エラー:
  - このエラーは、ターゲットブランチが完全なセキュリティスキャンパイプラインを実行していない場合に発生する可能性があります。[マージリクエストドキュメント](../detect/security_scanning_results.md)を参照してください。
