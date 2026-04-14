---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: シークレット検出の誤検出判定
description: シークレット検出の検索結果における誤検出の自動検出とフィルタリング。
---

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.10で[エピック17885](https://gitlab.com/groups/gitlab-org/-/work_items/20152)で、`duo_secret_detection_false_positive`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)を持つ[ベータ](../../../policy/development_stages_support.md#beta)機能として導入されました。[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効。](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227074)

{{< /history >}}

シークレット検出のスキャンが実行されると、GitLab Duoは検出された各シークレットを自動的に分析し、それが誤検出である可能性を判断します。[GitLabシークレット検出](../secret_detection/_index.md)で検出されたすべてのシークレットタイプで検出が可能です。

GitLab Duoの評価には、各誤検出結果に関する情報が含まれます:

- 信頼度スコア: 結果が誤検出である可能性を示す数値スコア。
- 説明: コードのコンテキストとシークレットの特性に基づいて、結果が真の陽性であるかどうかの理由。
- ビジュアルインジケーター: 脆弱性レポート内のバッジで、誤検出の評価が表示されます。

シークレット検出の誤検出判定は、手動での介入なしに各セキュリティスキャン後に自動的に実行されます。

結果はAIによる分析に基づいており、セキュリティ担当者によるレビューが必要です。この機能を使用するには、アクティブなサブスクリプションのGitLab Duoが必要です。

## 自動検出 {#automatic-detection}

誤検出判定は、次のシナリオで自動的に実行されます:

- シークレット検出スキャンがデフォルトブランチで正常に完了します。
- スキャンがシークレットを検出します。
- GitLab Duo機能がプロジェクトで有効になっている。

分析はバックグラウンドで実行され、処理が完了すると脆弱性レポートに結果が表示されます。

## 手動トリガー {#manual-trigger}

既存の脆弱性に対して、手動で誤検出判定を実行できます:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **脆弱性レポート**を選択します。
1. 分析する脆弱性を選択します。
1. 右上隅で、**誤検知のチェック**を選択して、誤検出判定をトリガーします。

GitLab Duoの分析が実行され、結果は脆弱性の詳細ページに表示されます。

## 設定 {#configuration}

誤検出判定を使用するには、次の要件を満たす必要があります:

- GitLab Duoアドオンのサブスクリプション（GitLab Duo Core、Pro、またはEnterprise）。
- プロジェクトまたはグループで[GitLab Duoを有効になっている](../../gitlab_duo/turn_on_off.md)。
- ユーザー設定で[デフォルトのGitLab Duoのネームスペースが設定されている](../../profile/preferences.md#set-a-default-gitlab-duo-namespace)こと。
- GitLab 18.10以降。

### 誤検出判定を有効にする {#enable-false-positive-detection}

誤検出判定は、デフォルトでオフになっています。この機能を使用するには、グループに対して基本フローを有効にし、プロジェクトに対して機能をオンにする必要があります。

#### グループの基本フローを許可する {#allow-foundational-flow-for-a-group}

グループ内のすべてのプロジェクトが基本フローを使用できるように許可できます。個々のプロジェクトでは、引き続きプロジェクトの設定で機能を有効にする必要があります。グループ内のすべてのプロジェクトに対して誤検出判定を許可するには:

1. 左サイドバーで、**検索または移動先**を選択し、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **基本フローを許可**の下で、**シークレット検出の誤検出**チェックボックスを選択します。
1. **変更を保存**を選択します。

#### プロジェクトでオンにする {#turn-on-for-a-project}

特定のプロジェクトに対して誤検出判定をオンにするには:

1. 左サイドバーで、**検索または移動先**を選択し、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**を展開します。
1. **Turn on secret detection false positive detection**切替をオンにします。
1. **変更を保存**を選択します。

グループに対して誤検出判定を許可し、プロジェクトに対してそれをオンにすると、既存のシークレット検出スキャナーで機能が自動的に動作します。

## 信頼度スコア {#confidence-scores}

信頼度スコアは、GitLab Duoの評価がどの程度正しいかの推定値です:

- 誤検出の可能性が高い（80-100%）: GitLab Duoは、検出結果が誤検出である可能性が非常に高いと判断しています。
- 誤検出の可能性がある（60-79%）: GitLab Duoは、検出結果が誤検出である可能性があると一定の確信を持っていますが、手動での確認を推奨します。
- 誤検出ではない可能性が高い（<60%）: GitLab Duoは、検出結果が誤検出であるとは考えていません。脆弱性を無視する前に、手動での確認を強く推奨します。

## 誤検出を無視する {#dismissing-false-positives}

GitLab Duoの分析で脆弱性が誤検出として特定された場合、次のオプションがあります:

- 脆弱性を無視する
- 誤検出フラグを削除

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

誤検出判定はベータ機能です。フィードバックをお待ちしております。問題が発生した場合、または改善の提案がある場合は、[イシュー592861](https://gitlab.com/gitlab-org/gitlab/-/work_items/592861)でフィードバックをお寄せください。

## 関連トピック {#related-topics}

- [脆弱性の詳細](_index.md)
- [脆弱性レポート](../vulnerability_report/_index.md)
- [シークレット検出](../secret_detection/_index.md)
- [GitLab Duo](../../gitlab_duo/_index.md)
