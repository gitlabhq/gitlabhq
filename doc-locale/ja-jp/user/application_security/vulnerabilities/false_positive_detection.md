---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SASTの誤検出判定
description: SAST検出結果における誤検出の自動検出とフィルタリング。
---

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/groups/gitlab-org/-/epics/18977)され、[ベータ](../../../policy/development_stages_support.md#beta)版[機能フラグ](../../../administration/feature_flags/_index.md)として`enable_vulnerability_fp_detection`および`ai_experiment_sast_fp_detection`という名前が付けられました。デフォルトでは有効になっています。
- GitLab 18.10で[一般提供](https://gitlab.com/groups/gitlab-org/-/work_items/19789)になりました。

{{< /history >}}

静的アプリケーションセキュリティテスト（SAST）スキャンを実行すると、GitLab Duoは、重大度クリティカルおよび高の各SAST脆弱性を自動的に分析して、それが誤検出である可能性を判断します。この検知機能は、[GitLabがサポートするSASTアナライザー](../sast/analyzers.md)から報告された脆弱性に対して利用できます。

GitLab Duoの評価には次の内容が含まれます:

- 信頼度スコア: その検出結果が誤検出である可能性を示す数値スコア。
- 説明: コードのコンテキストと脆弱性の特性に基づいて、検出結果が真陽性であるか、そうでないかのコンテキスト推論。
- ビジュアルインジケーター: 誤検出の評価を示す脆弱性レポートのバッジ。

この検出は、セキュリティスキャンのたびに自動的に実行されます。手動でのトリガーは不要です。

結果はAIによる分析に基づいており、セキュリティ担当者によるレビューが必要です。この機能を使用するには、アクティブなサブスクリプションのGitLab Duoが必要です。

クリックスルーデモについては、[SAST誤検出判定フロー](https://gitlab.navattic.com/sast-fp-detection-flow)を参照してください。
<!-- Demo published on 2026-02-17 -->

## 自動検出 {#automatic-detection}

誤検出判定は、次の場合に自動的に実行されます:

- デフォルトブランチでSASTセキュリティスキャンが正常に完了した。
- スキャンによって、重大度が致命的または高い脆弱性が検出された。
- GitLab Duo機能がプロジェクトで有効になっている。

分析はバックグラウンドで行われ、処理が完了すると、脆弱性レポートに結果が表示されます。

## 手動トリガー {#manual-trigger}

既存の脆弱性に対して、手動で誤検出判定をトリガーできます:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **脆弱性レポート**を選択します。
1. 分析する脆弱性を選択します。
1. 右上隅で、**誤検知のチェック**を選択して、誤検出判定をトリガーします。

GitLab Duoの分析が実行され、結果が脆弱性の詳細ページに表示されます。

## 設定 {#configuration}

誤検出判定を使用するには、以下が必要です:

- GitLab Duoアドオンのサブスクリプション（GitLab Duo Core、Pro、またはEnterprise）。
- プロジェクトまたはグループで[GitLab Duoを有効になっている](../../gitlab_duo/turn_on_off.md)。
- ユーザー環境設定で[デフォルトのGitLab Duoネームスペースが設定](../../profile/preferences.md#set-a-default-gitlab-duo-namespace)されていること。
- GitLab 18.7以降。

### 誤検出判定を有効にする {#enable-false-positive-detection}

誤検出判定は、デフォルトでオフになっています。この機能を使用するには、グループの基本フローを有効にし、プロジェクトの機能をオンにする必要があります。

#### グループの基本フローを許可する {#allow-foundational-flow-for-a-group}

グループ内のすべてのプロジェクトで基本フローを使用することを許可できます。個々のプロジェクトでは、そのプロジェクト設定で機能を有効にする必要があります。グループ内のすべてのプロジェクトで誤検出判定を許可するには:

1. 左サイドバーで、**検索または移動先**を選択し、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **基本フローを許可**の下で、**SAST誤検出**チェックボックスを選択します。
1. **変更を保存**を選択します。

#### プロジェクトをオンにする {#turn-on-for-a-project}

特定のプロジェクトで誤検出判定をオンにするには:

1. 左サイドバーで、**検索または移動先**を選択し、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**を展開します。
1. **SAST誤検出判定を有効にする**切替をオンにします。
1. **変更を保存**を選択します。

グループで誤検出判定を許可し、プロジェクトでそれをオンにすると、この機能は既存のSASTスキャナーと自動的に連携します。

## 信頼度スコア {#confidence-scores}

信頼度スコアは、GitLab Duoの評価がどの程度正しいかの推定値です:

- **誤検出の可能性が高い（80〜100%）**: GitLab Duoは、検出結果が誤検出である可能性が非常に高いと判断しています。
- **誤検出の可能性あり（60〜79%）**: GitLab Duoは、検出結果が誤検出である可能性があると一定の確信を持っていますが、手動での確認を推奨します。
- **誤検出の可能性は低い（60%未満）**: GitLab Duoは、検出結果が誤検出であるとは考えていません。脆弱性を無視する前に、手動での確認を強く推奨します。

## 誤検出を無視する {#dismissing-false-positives}

GitLab Duoの分析により脆弱性が誤検出と識別された場合、次のオプションがあります:

- 脆弱性を無視する
- 誤検出フラグを削除する

### 脆弱性を無視する {#dismiss-the-vulnerability}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **脆弱性レポート**を選択します。
1. 無視する脆弱性を選択します。
1. **ステータスを変更**を選択します。
1. **ステータス**ドロップダウンリストから、**却下済み**を選択します。
1. **Set dismissal reason**ドロップダウンリストから、**偽陽性**を選択します。
1. **コメントの追加**入力で、誤検出として無視する理由に関するコンテキストを提供します。
1. **ステータスを変更**を選択します。

脆弱性は無視としてマークされ、再導入されない限り、将来のスキャンには表示されません。

### 誤検出フラグを削除する {#remove-the-false-positive-flag}

誤検出の評価を削除して、脆弱性を保持する場合は、以下の手順に従います:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **脆弱性レポート**を選択します。
1. 誤検出フラグが付いた脆弱性を見つけます。
1. 脆弱性の誤検出バッジにカーソルを合わせます。
1. **誤検出フラグを削除する**を選択します。

誤検出フラグが削除され、FP信頼度スコアが0に戻ります。脆弱性はレポートに残っており、将来のスキャンで再評価できます。

## フィードバックを提供する {#providing-feedback}

誤検出判定はベータ機能です。フィードバックをお待ちしております。問題が発生した場合、または改善のための提案がある場合は、[イシュー583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697)でフィードバックをお寄せください。

## 関連トピック {#related-topics}

- [脆弱性の詳細](_index.md)
- [脆弱性レポート](../vulnerability_report/_index.md)
- [SAST](../sast/_index.md)
- [GitLab Duo](../../gitlab_duo/_index.md)
