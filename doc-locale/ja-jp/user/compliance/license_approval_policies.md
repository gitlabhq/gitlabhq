---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ライセンス承認ポリシー
description: マージする前にマージリクエストの承認を得るために、ライセンス承認ポリシーを使用して条件を指定する方法について説明します。保護されたターゲットブランチのみに適用されます。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.9で`license_scanning_policies`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/8092)されました。
- GitLab 15.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/397644)になりました。機能フラグ`license_scanning_policies`は削除されました。

{{< /history >}}

ライセンス承認ポリシーを使用して、マージリクエストの承認を得る時期を決定する基準を指定します。

ライセンス承認ポリシーは、[保護された](../project/repository/branches/protected.md)ターゲットブランチにのみ適用されます。

次の動画では、これらのポリシーの概要を説明します。

<div class="video-fallback">
  参照用動画: <a href="https://www.youtube.com/watch?v=34qBQ9t8qO8">GitLabライセンス承認ポリシーの概要</a>。
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/34qBQ9t8qO8" frameborder="0" allowfullscreen> </iframe>
</figure>

## 新しいライセンス承認ポリシーを作成するための前提条件 {#prerequisites-to-creating-a-new-license-approval-policy}

ライセンス承認ポリシーは、要件が満たされていることを確認するために、依存関係スキャンジョブの出力に依存します。依存関係スキャンが適切に設定されていない場合、したがって、オープンマージリクエストに関連する依存関係スキャンジョブが実行されない場合、ポリシーには要件を確認するためのデータがありません。セキュリティポリシーに評価用のデータがない場合、デフォルトではクローズに失敗し、マージリクエストに脆弱性が含まれている可能性があると想定します。`fallback_behavior`プロパティを使用してデフォルトの動作をオプトアウトし、ポリシーがオープンに失敗するように設定できます。オープンに失敗するポリシーは、無効で強制不可能なすべてのルールがブロック解除されています。

ポリシーの適用を確実にするには、ターゲットブランチの開発プロジェクトで依存関係スキャンを有効にする必要があります。これを実現するには、いくつかの異なる方法があります:

- すべてのターゲットブランチの開発プロジェクトで依存関係スキャンが実行されるように強制する[スキャン実行ポリシー](../application_security/policies/scan_execution_policies.md)を作成します。
- 開発チームと協力して、各プロジェクトの`.gitlab-ci.yml`ファイルで[依存関係スキャン](../application_security/dependency_scanning/_index.md)を設定するか、[セキュリティ設定](../application_security/detect/security_configuration.md)を使用して有効にします。

ライセンス承認ポリシーでは、[GitLabがサポートするパッケージ](license_scanning_of_cyclonedx_files/_index.md#supported-languages-and-package-managers)からのライセンス情報が必要です。

## 新しいライセンス承認ポリシーを作成 {#create-a-new-license-approval-policy}

ライセンスコンプライアンスを強制するために、ライセンス承認ポリシーを作成します。

ライセンス承認ポリシーを作成するには、次の手順に従います:

1. [セキュリティポリシープロジェクトをリンク](../application_security/policies/enforcement/security_policy_projects.md#link-to-a-security-policy-project)を開発グループ、サブグループ、またはプロジェクト（オーナーロールが必要です）にリンクします。
1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **ポリシー**を選択します。
1. 新しい[マージリクエスト承認ポリシー](../application_security/policies/merge_request_approval_policies.md)を作成します。
1. ポリシー規則で、**License scanning**（ライセンススキャン）を選択します。

## 承認が必要なライセンスを定義する基準 {#criteria-defining-which-licenses-require-approval}

次の種類の基準を使用して、「承認済み」または「拒否済み」であり、承認が必要なライセンスを判断できます。

- 明示的に禁止されているライセンスのリストにあるライセンスが検出された場合。
- 許容できるものとして明示的にリストされているライセンスを除き、ライセンスが検出された場合。

## デフォルトブランチのライセンスとマージリクエストブランチで検出されたライセンスを比較する基準 {#criteria-to-compare-licenses-detected-in-the-merge-request-branch-to-licenses-in-the-default-branch}

次の種類の基準を使用して、デフォルトブランチに存在するライセンスに基づいて承認が必要かどうかを判断できます:

- 拒否されたライセンスは、拒否されたライセンスがデフォルトブランチにまだ存在しない依存の一部である場合にのみ、承認を要求するように設定できます。
- 拒否されたライセンスは、拒否されたライセンスがデフォルトブランチにすでに存在するコンポーネントに存在する場合、承認を要求するように設定できます。

![ライセンス承認ポリシー](img/license_approval_policy_v15_9.png)

ライセンス承認ポリシーに違反するライセンスが見つかった場合、マージリクエストをブロックし、デベロッパーに削除するように指示します。`denied`ライセンスが削除されるまで、マージリクエストはマージできません。ただし、ライセンス承認ポリシーの対象となる承認者がマージリクエストを承認する場合は除きます。

![拒否されたライセンスを含むマージリクエスト](img/denied_licenses_v15_3.png)

## トラブルシューティング {#troubleshooting}

### ライセンスコンプライアンスウィジェットがロード状態のままになる {#the-license-compliance-widget-is-stuck-in-a-loading-state}

読み込みスピナーは、次のシナリオで表示されます:

- パイプラインの進行中。
- パイプラインが完了しても、バックグラウンドで結果を解析中の場合。
- ライセンススキャンジョブが完了しても、パイプラインがまだ実行されている場合。

ライセンスコンプライアンスウィジェットは、更新された結果を数秒ごとにトリガーします。パイプラインが完了すると、パイプライン完了後の最初の呼び出しで結果の解析中がトリガーされます。これは、生成されたレポートのサイズに応じて数秒かかる場合があります。

最終状態は、パイプラインの実行が正常に完了し、解析中され、ウィジェットにライセンスが表示されるときです。

### `unknown`ライセンスが原因でライセンス承認ポリシーがマージリクエストをブロックする {#license-approval-policies-block-merge-requests-due-to-unknown-licenses}

ライセンス承認ポリシーは、特定のシナリオで`unknown`ライセンスが原因でマージリクエストをブロックする場合があります。これは、次のいずれかの状況で発生する可能性があります:

- 依存関係スキャンジョブが特定のコンポーネントのライセンスを識別できません。
- 新しいまたは一般的なライセンスが使用されていますが、スキャンツールで認識されていません。
- コンポーネントのメタデータにライセンス情報がないか、不完全です。

この問題を解決するには、次の手順に従います:

1. パイプラインページの**ライセンス**タブを確認して、どのコンポーネントに`unknown`ライセンスがあるかを特定するか、GitLabセキュリティポリシーボットによって生成された`out-of-policy`ライセンスを確認します。
1. これらのコンポーネントを手動で調査して、実際のライセンスを特定します。
1. ライセンスを特定できない場合、または許容できない場合は、影響を受けるコンポーネントの削除または交換を検討してください。

`unknown`ライセンスを使用して一時的にマージを許可する必要がある場合:

1. ライセンス承認ポリシーを編集します。
1. 許可されたライセンスのリストに`unknown`を追加します。
1. 問題に対処したら、適切なライセンスコンプライアンスを維持するために、許可されたライセンスリストから`unknown`を削除することを忘れないでください。

ライセンスコンプライアンスの問題に対処する場合は、特に`unknown`ライセンスを処理する場合は、必ず法務チームに相談してください。
