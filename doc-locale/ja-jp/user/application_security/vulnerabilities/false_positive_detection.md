---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SASTの誤検出判定
description: SAST検出結果における誤検出の自動検出とフィルタリング。
---

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.7で[機能フラグ](../../../administration/feature_flags/_index.md)`enable_vulnerability_fp_detection`および`ai_experiment_sast_fp_detection`とともに[ベータ版](../../../policy/development_stages_support.md#beta)機能として[導入](https://gitlab.com/groups/gitlab-org/-/epics/18977)されました。デフォルトでは有効になっています。

{{< /history >}}

静的アプリケーションセキュリティテスト（SAST）スキャンを実行すると、GitLab Duoは、重大度クリティカルおよび高の各SAST脆弱性を自動的に分析して、それが誤検出である可能性を判断します。この検知機能は、[GitLabがサポートするSASTアナライザー](../sast/analyzers.md)から報告された脆弱性に対して利用できます。

GitLab Duoの評価には次の内容が含まれます:

- 信頼度スコア: その検出結果が誤検出である可能性を示す数値スコア。
- 説明: コードのコンテキストと脆弱性の特性に基づいて、検出結果が真陽性であるか、そうでないかのコンテキスト推論。
- ビジュアルインジケーター: 誤検出の評価を示す脆弱性レポートのバッジ。

この検出は、セキュリティスキャンのたびに自動的に実行され、手動でのトリガーは不要です。

結果はAIによる分析に基づいており、セキュリティ担当者によるレビューが必要です。この機能を使用するには、アクティブなサブスクリプションのGitLab Duoが必要です。

## 自動検出 {#automatic-detection}

誤検出は、次の場合に自動的に実行されます:

- デフォルトブランチでSASTセキュリティスキャンが正常に完了した。
- スキャンによって、重大度が致命的または高い脆弱性が検出された。
- GitLab Duo機能がプロジェクトで有効になっている。

分析はバックグラウンドで行われ、処理が完了すると、脆弱性レポートに結果が表示されます。

## 手動トリガー {#manual-trigger}

既存の脆弱性に対して、手動で誤検出をトリガーできます:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **脆弱性レポート**を選択します。
1. 分析する脆弱性を選択します。
1. 右上隅で、**誤検知のチェック**を選択して、誤検出をトリガーします。

GitLab Duoの分析が実行され、結果が脆弱性の詳細ページに表示されます。

## 設定 {#configuration}

誤検出を使用するには、以下が必要です:

- GitLab Duoアドオンのサブスクリプション（GitLab Duo Core、Pro、またはEnterprise）。
- プロジェクトまたはグループで[GitLab Duo enabled](../../gitlab_duo/turn_on_off.md)。
- GitLab 18.7以降。

### 誤検出を有効にする {#enable-false-positive-detection}

誤検出は、デフォルトでオフになっています。インスタンス、グループ、またはプロジェクトに対して有効にできます。インスタンスまたはグループの設定を有効にすると、その子孫のグループとプロジェクトすべてにその設定が適用されます。

推奨: グループ内のすべてのプロジェクトに設定を適用するには、グループの設定を有効にする必要があります。

#### グループに対して有効にする（推奨） {#enable-for-a-group-recommended}

グループ内のすべてのプロジェクトに対して誤検出を有効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **Turn on SAST false positive detection**チェックボックスを選択します。
1. **変更を保存**を選択します。

この設定は、グループ内のすべての子孫プロジェクトに適用されます。個々のプロジェクトでは、無効にする必要がある場合に、この設定をオーバーライドできます。

#### プロジェクトに対して有効にする {#enable-for-a-project}

特定のプロジェクトに対して誤検出を有効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**を展開します。
1. **Turn on SAST false positive detection**切替をオンにします。
1. **変更を保存**を選択します。

#### インスタンスに対して有効にする {#enable-for-an-instance}

GitLabの管理者は、インスタンス全体に対して誤検出を有効にできます:

1. 左側のサイドバーで**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**を展開します。
1. **Turn on SAST false positive detection**チェックボックスを選択します。
1. **変更を保存**を選択します。

誤検出は、インスタンス、グループ、またはプロジェクトに対して有効になっている場合、既存のSASTスキャナーで自動的に機能します。

## 信頼度スコア {#confidence-scores}

信頼度スコアは、GitLab Duoの評価がどの程度正しいかの推定値です:

- **Likely false positive (80-100%)**: GitLab Duoは、検出結果が誤検出であると非常に確信しています。
- **Possible false positive (60-79%)**: GitLab Duoは、検出結果が誤検出である可能性があると合理的に確信していますが、手動レビューを推奨しています。
- **Likely not a false positive (<60%)**: GitLab Duoは、検出結果が誤検出であるとは確信していません。脆弱性を無視する前に、手動レビューを強くお勧めします。

## 誤検出の無視 {#dismissing-false-positives}

GitLab Duoの分析で、脆弱性が誤検出として識別された場合、2つのオプションがあります:

### オプション1: 脆弱性を無視する {#option-1-dismiss-the-vulnerability}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **脆弱性レポート**を選択します。
1. 無視する脆弱性を選択します。
1. **ステータスを変更**を選択します。
1. **ステータス**ドロップダウンリストから、**やめる**を選択します。
1. **Set dismissal reason**ドロップダウンリストから、**誤検知**を選択します。
1. **コメントの追加**入力で、誤検出として無視する理由に関するコンテキストを提供します。
1. **ステータスを変更**を選択します。

脆弱性は無視としてマークされ、再導入されない限り、将来のスキャンには表示されません。

### オプション2: 誤検出フラグを削除する {#option-2-remove-the-false-positive-flag}

誤検出の評価を削除して、脆弱性を保持する場合は:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **脆弱性レポート**を選択します。
1. 誤検出フラグが付いた脆弱性を見つけます。
1. 脆弱性の誤検出バッジにカーソルを合わせる。
1. **Remove False Positive Flag**を選択します。

誤検出フラグが削除され、FP信頼度スコアが0に戻ります。脆弱性はレポートに残っており、将来のスキャンで再評価できます。

## フィードバックを提供する {#providing-feedback}

誤検出はベータ機能であり、フィードバックをお待ちしております。問題が発生した場合、または改善のための提案がある場合は、[issue 583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697)でフィードバックをお寄せください。

## 関連トピック {#related-topics}

- [脆弱性の詳細](_index.md)
- [脆弱性レポート](../vulnerability_report/_index.md)
- [SAST](../sast/_index.md)
- [GitLab Duo](../../gitlab_duo/_index.md)
