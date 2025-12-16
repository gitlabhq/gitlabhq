---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabでマージリクエスト承認ポリシーを使用してセキュリティルールを適用し、プロジェクト全体のスキャン、承認、およびコンプライアンスを自動化する方法について説明します。
title: マージリクエスト承認ポリシー
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- グループレベルのスキャン結果ポリシーがGitLab 15.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/7622)されました。
- スキャン結果ポリシー機能は、GitLab 16.9でマージリクエスト承認ポリシーに名称変更されました。

{{< /history >}}

{{< alert type="note" >}}

スキャン結果ポリシー機能は、GitLab 16.9でマージリクエスト承認ポリシーに名称変更されました。

{{< /alert >}}

マージリクエスト承認ポリシーは、次のような複数の目的に使用できます:

- セキュリティおよびライセンススキャナーの結果を検出して、承認ルールを適用します。たとえば、ある種のマージリクエストポリシーは、1つまたは複数のセキュリティスキャンジョブの調査結果に基づいて承認を必須にすることができるセキュリティ承認ポリシーです。マージリクエスト承認ポリシーは、CIスキャンジョブが完全に実行された後に評価され、脆弱性とライセンスの種類のポリシーは、完了したパイプラインで公開されるジョブアーティファクトレポートに基づいて評価されます。
- 特定の条件を満たすすべてのマージリクエストに承認ルールを適用します。たとえば、デフォルトブランチをターゲットブランチとするすべてのマージリクエストについて、デベロッパーロールおよびメンテナーロールを持つ複数のユーザーによるレビューを強制します。
- プロジェクトのセキュリティとコンプライアンスの設定を適用します。たとえば、マージリクエストへの変更を作成またはコミットしたユーザーがマージリクエストを承認できないようにします。または、すべての変更がマージリクエストを経由するように、ユーザーがデフォルトブランチにプッシュまたは強制プッシュすることを禁止します。

{{< alert type="note" >}}

保護ブランチが作成または削除されると、ポリシー承認ルールが1分遅れて同期されます。

{{< /alert >}}

次の動画では、GitLabのマージリクエスト承認ポリシー（以前はスキャン結果ポリシー）の概要を説明します:

<div class="video-fallback">
  参照用動画: <a href="https://youtu.be/w5I9gcUgr9U">GitLabスキャン結果ポリシーの概要</a>。
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/w5I9gcUgr9U" frameborder="0" allowfullscreen> </iframe>
</figure>

## 制限事項 {#restrictions}

- マージリクエスト承認ポリシーは、[保護](../../project/repository/branches/protected.md)されたターゲットブランチでのみ適用できます。
- 各ポリシーに割り当てることができるルールは最大5つです。
- 各セキュリティポリシープロジェクトには、最大5つのマージリクエスト承認ポリシーを割り当てることができます。
- グループまたはサブグループに対して作成されたポリシーが、グループ内のすべてのマージリクエストに適用されるまでに時間がかかる場合があります。かかる時間は、プロジェクト数とそれらのプロジェクト内のマージリクエスト数によって決まります。通常、かかる時間はほんの数秒です。プロジェクトとマージリクエストが数千もあるグループの場合、以前に観察した内容に基づくと、数分かかる可能性があります。
- マージリクエスト承認ポリシーは、アーティファクトレポートで生成されたスキャン結果の完全性または信頼性をチェックしません。
- マージリクエスト承認ポリシーは、その承認ルールに従って評価されます。デフォルトでは、承認ルールが無効な場合、または評価できない場合は、承認が必要です。この動作は、[`fallback_behavior`フィールド](#fallback_behavior)で変更できます。

## パイプラインの要件 {#pipeline-requirements}

マージリクエスト承認ポリシーは、パイプラインの結果に従って適用されます。マージリクエスト承認ポリシーを実装する場合は、以下を考慮してください:

- マージリクエスト承認ポリシーは、完了したパイプラインジョブを評価し、手動ジョブは無視します。手動ジョブが実行されると、ポリシーはマージリクエストのジョブを再評価します。
- セキュリティスキャナーの結果を評価するマージリクエスト承認ポリシーの場合、指定されたすべてのスキャナーがセキュリティレポートを出力する必要があります。そうでない場合、脆弱性が導入されるリスクを最小限に抑えるために、承認が適用されます。この動作は、以下に影響を与える可能性があります:
  - セキュリティスキャンがまだ確立されていない新しいプロジェクト。
  - セキュリティスキャンが設定される前に作成されたブランチ。
  - ブランチ間でスキャナーの設定に一貫性がないプロジェクト。
- パイプラインは、ソースブランチとターゲットブランチの両方について、有効になっているすべてのスキャナーのアーティファクトを生成する必要があります。そうでない場合、比較の根拠がないため、ポリシーを評価できません。この要件を適用するには、スキャン実行ポリシーを使用する必要があります。
- ポリシーの評価は、成功し完了したマージベースパイプラインに依存します。マージベースパイプラインがスキップされた場合、マージベースパイプラインを含むマージリクエストはブロックされます。
- ポリシーで指定されたセキュリティスキャナーは、ポリシーが適用されるプロジェクトで設定および有効にする必要があります。そうでない場合、マージリクエスト承認ポリシーを評価できず、対応する承認が必要になります。

## マージリクエスト承認ポリシーでセキュリティスキャナーを使用するためのベストプラクティス {#best-practices-for-using-security-scanners-with-merge-request-approval-policies}

新しいプロジェクトを作成するときに、そのプロジェクトにマージリクエスト承認ポリシーとセキュリティスキャンの両方を適用できます。ただし、正しく設定されていないセキュリティスキャナーは、マージリクエスト承認ポリシーに影響を与える可能性があります。

新しいプロジェクトでセキュリティスキャンを設定する方法は複数あります:

- `.gitlab-ci.yml`設定ファイルにスキャナーを追加することにより、プロジェクトのCI/CD設定で設定します。
- パイプラインが特定のセキュリティスキャナーを実行することを強制するスキャン実行ポリシー。
- パイプラインでどのジョブを実行する必要があるかを制御するパイプライン実行ポリシー。

単純なユースケースでは、プロジェクトのCI/CD設定を使用できます。包括的なセキュリティ戦略を実現するには、マージリクエスト承認ポリシーを他の種類のポリシーと組み合わせることを検討してください。

不要な承認要件を最小限に抑えるために、正確なセキュリティ評価を確保します:

- **Run security scans on your default branch first**（まず、デフォルトブランチでセキュリティスキャンを実行します）: フィーチャーブランチを作成する前に、デフォルトブランチでセキュリティスキャンが正常に実行されていることを確認してください。
- **Use consistent scanner configuration**（一貫性のあるスキャナーの設定を使用します）: 同じスキャナーをソースブランチとターゲットブランチの両方で実行します（できれば単一のパイプラインで）。
- **Verify that scans produce artifacts**（スキャンがアーティファクトを生成することを確認します）: スキャンが正常に完了し、比較のためにアーティファクトが生成されることを確認します。
- **Keep branches synchronized**（ブランチを同期した状態に保ちます）: デフォルトブランチからの変更を定期的にフィーチャーブランチにマージします。
- **Consider pipeline configurations**（パイプラインの設定を検討してください）: 新しいプロジェクトの場合は、最初の`.gitlab-ci.yml`設定にセキュリティスキャナーを含めます。

### マージリクエスト承認ポリシーを適用する前にセキュリティスキャナーを検証します {#verify-security-scanners-before-you-apply-merge-request-approval-policies}

マージリクエスト承認ポリシーを適用する前に、新しいプロジェクトにセキュリティスキャンを実装することで、セキュリティスキャナーがマージリクエスト承認ポリシーに依存する前に一貫して実行されるようにすることができます。これにより、セキュリティスキャンの欠落によりマージリクエストがブロックされる状況を回避できます。

セキュリティスキャナーとマージリクエスト承認ポリシーをまとめて作成および検証するには、次の推奨されるワークフローを使用します:

1. プロジェクトを作成します。
1. `.gitlab-ci.yml`設定ファイル、スキャン実行ポリシー、またはパイプライン実行ポリシーを使用して、セキュリティスキャナーを設定します。
1. デフォルトブランチで最初のパイプラインが完了するまで待ちます。問題があれば解決し、パイプラインを再実行して、続行する前に正常に完了することを確認します。
1. 同じセキュリティスキャナーが設定されたフィーチャーブランチを使用してマージリクエストを作成します。ここでも、セキュリティスキャナーが正常に完了することを確認してください。
1. マージリクエスト承認ポリシーを適用します。

## 複数のパイプラインを含むマージリクエスト {#merge-request-with-multiple-pipelines}

{{< history >}}

- GitLab 16.2で`multi_pipeline_scan_result_policies`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/379108)されました。デフォルトでは無効になっています。
- GitLab 16.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/409482)が開始されました。機能フラグ`multi_pipeline_scan_result_policies`は削除されました。
- 親子パイプラインのサポートが、名前が`approval_policy_parent_child_pipeline`の[機能フラグ](../../../administration/feature_flags/_index.md)でGitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/428591)されました。デフォルトでは無効になっています。
- GitLab 17.0の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/451597)になりました。
- GitLab 17.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/428591)になりました。機能フラグ`approval_policy_parent_child_pipeline`は削除されました。

{{< /history >}}

プロジェクトは、複数のパイプラインタイプを設定できます。単一のコミットで複数のパイプラインを開始でき、それぞれにセキュリティスキャンが含まれている場合があります。

- GitLab 16.3以降では、マージリクエストのソースブランチとターゲットブランチの最新コミットに対する、完了したすべてのパイプラインの結果が評価され、マージリクエスト承認ポリシーの適用に使用されます。オンデマンドのDASTパイプラインは考慮されません。
- GitLab 16.2以前は、マージリクエスト承認ポリシーを適用する際に、最新の完了したパイプラインの結果のみが評価されました。

プロジェクトで[マージリクエストパイプライン](../../../ci/pipelines/merge_request_pipelines.md)を使用している場合は、セキュリティスキャンジョブをパイプラインに含めるために、CI/CD変数`AST_ENABLE_MR_PIPELINES`を`"true"`に設定する必要があります。詳細については、[マージリクエストパイプラインでセキュリティスキャンツールを使用する](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)を参照してください。

最新のコミットで多くのパイプラインが実行されているプロジェクト（たとえば、休止中のプロジェクト）の場合、ポリシー評価では、マージリクエストのソースブランチとターゲットブランチの両方から最大1,000個のパイプラインが考慮されます。

親子パイプラインの場合、ポリシー評価では最大1,000個の子パイプラインが考慮されます。

## マージリクエスト承認ポリシーエディター {#merge-request-approval-policy-editor}

{{< history >}}

- GitLab 15.6で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/369473)になりました。

{{< /history >}}

{{< alert type="note" >}}

プロジェクトのオーナーのみが、セキュリティポリシープロジェクトを選択する[権限](../../permissions.md#project-members-permissions)を持っています。

{{< /alert >}}

ポリシーが完了したら、エディターの下部にある**マージリクエスト経由で設定**を選択して保存します。これにより、プロジェクトで設定されたセキュリティポリシープロジェクトのマージリクエストにリダイレクトされます。セキュリティポリシープロジェクトがプロジェクトにリンクしていない場合、GitLabはそのようなプロジェクトを作成します。エディターの下部にある**ポリシーの削除**を選択して、既存のポリシーをエディターのインターフェースから削除することもできます。

ほとんどのポリシー変更は、マージリクエストがマージされるとすぐに有効になります。マージリクエストを経由せずにデフォルトブランチに直接コミットされた変更は、ポリシーの変更が有効になるまでに最大10分かかる場合があります。

[ポリシーエディタ](_index.md#policy-editor)は、YAML.yamlモードとルールモードをサポートしています。

{{< alert type="note" >}}

多数のプロジェクトを含むグループに対して作成されたマージリクエスト承認ポリシーを伝達するには、完了するまでに時間がかかります。

{{< /alert >}}

## マージリクエスト承認ポリシースキーマ {#merge-request-approval-policies-schema}

マージリクエスト承認ポリシーを含むYAMLファイルは、`approval_policy`キーの下にネストされたマージリクエスト承認ポリシースキーマに一致するオブジェクトの配列で構成されます。`approval_policy`キーの下に最大5つのポリシーを設定できます。

{{< alert type="note" >}}

マージリクエスト承認ポリシーは、`scan_result_policy`キーの下で定義されました。GitLab 17.0以前は、ポリシーは両方のキーの下で定義できます。GitLab 17.0以降、`approval_policy`キーのみがサポートされます。

{{< /alert >}}

新しいポリシーを保存すると、GitLabは[このJSONスキーマ](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json)に照らしてその内容を検証します。[JSONスキーマ](https://json-schema.org/)に精通していない方は、以下のセクションと表を参照してください。

| フィールド             | 型                                     | 必須 | 説明                                          |
|-------------------|------------------------------------------|----------|------------------------------------------------------|
| `approval_policy` | マージリクエスト承認ポリシーオブジェクトの`array` | はい     | マージリクエスト承認ポリシーのリスト（最大5つ）。 |

## マージリクエスト承認ポリシースキーマ {#merge-request-approval-policy-schema}

{{< history >}}

- `approval_settings`フィールドは、`scan_result_policies_block_unprotecting_branches`、`scan_result_any_merge_request`、または`scan_result_policies_block_force_push`という名前の[フラグ](../../../administration/feature_flags/_index.md)で、GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418752)されました。詳細については、以下の`approval_settings`セクションを参照してください。
- `enforcement_type`フィールドは、`security_policy_approval_warn_mode`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)を付けて、GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202746)されました{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

| フィールド               | 型               | 必須 | 使用可能な値 | 説明                                              |
|---------------------|--------------------|----------|-----------------|----------------------------------------------------------|
| `name`              | `string`           | はい     |                 | ポリシーの名前。最大255文字。           |
| `description`       | `string`           | いいえ    |                 | ポリシーの説明。                               |
| `enabled`           | `boolean`          | はい     | `true`、`false` | ポリシーを有効（`true`）または無効（`false`）にするフラグ。 |
| `rules`             | ルールの`array`   | はい     |                 | ポリシーが適用されるルールのリスト。                   |
| `actions`           | アクションの`array` | いいえ    |                 | ポリシーが適用するアクションのリスト。                |
| `approval_settings` | `object`           | いいえ    |                 | ポリシーでオーバーライドされるプロジェクト設定。              |
| `fallback_behavior` | `object`           | いいえ    |                 | 無効または適用できない承認ルールに影響を与える設定。     |
| `policy_scope`      | [`policy_scope`](_index.md#configure-the-policy-scope)の`object` | いいえ |  | 指定したプロジェクト、グループ、またはコンプライアンスフレームワークラベルに基づいて、ポリシーのスコープを定義します。 |
| `policy_tuning`     | `object`           | いいえ    |                 | （試験的）ポリシー比較ロジックに影響を与える設定。     |
| `bypass_settings`   | `object`           | いいえ    |                 | 特定のブランチ、トークン、またはアカウントがポリシーを回避することができる場合に影響を与える設定。     |
| `enforcement_type`  | `string`           | いいえ    | `enforce`、`warn` | ポリシーの適用方法を定義します。（指定されていない場合）デフォルト値は`enforce`で、違反が検出された場合にマージリクエストをブロックします。値`warn`を使用すると、マージリクエストは続行できますが、警告とボットのコメントが表示されます。 |

## `scan_finding`ルールタイプ {#scan_finding-rule-type}

{{< history >}}

- マージリクエスト承認ポリシーフィールド`vulnerability_attributes`は、名前が`enforce_vulnerability_attributes_rules`の[フラグ](../../../administration/feature_flags/_index.md)でGitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123052)されました。GitLab 16.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/418784)が開始されました。機能フラグは削除されました。
- マージリクエスト承認ポリシーフィールド`vulnerability_age`が、GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123956)されました。
- `branch_exceptions`フィールドは、`security_policies_branch_exceptions`という名前の[フラグ](../../../administration/feature_flags/_index.md)を付けて、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418741)されました。GitLab 16.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753)になりました。機能フラグは削除されました。
- `vulnerability_states`オプション`newly_detected`は、GitLab 17.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/422414)され、オプション`new_needs_triage`と`new_dismissed`が代わりに追加されました。

{{< /history >}}

この承認ルールは、セキュリティスキャンの調査結果に基づいて定義されたアクションを適用します。

| フィールド                      | 型                | 必須                                   | 使用可能な値                                                                                                    | 説明 |
|----------------------------|---------------------|--------------------------------------------|--------------------------------------------------------------------------------------------------------------------|-------------|
| `type`                     | `string`            | はい                                       | `scan_finding`                                                                                                     | ルールの種類。 |
| `branches`                 | `array`の`string` | `branch_type`フィールドが存在しない場合はtrue | `[]`またはブランチの名前                                                                                          | 保護されたターゲットブランチにのみ適用できます。空の配列`[]`は、すべての保護されたターゲットブランチにルールを適用します。`branch_type`フィールドでは使用できません。 |
| `branch_type`              | `string`            | `branches`フィールドが存在しない場合はtrue    | `default`または`protected`                                                                                           | 指定されたポリシーが適用される、保護ブランチのタイプ。`branches`フィールドでは使用できません。デフォルトブランチも`protected`である必要があります。 |
| `branch_exceptions`        | `array`の`string` | いいえ                                      | ブランチの名前                                                                                                  | このルールから除外するターゲットブランチ。 |
| `scanners`                 | `array`の`string` | はい                                       | `[]`または`sast`、`secret_detection`、`dependency_scanning`、`container_scanning`、`dast`、`coverage_fuzzing`、`api_fuzzing` | このルールで考慮するセキュリティスキャナー。`sast`には、SASTとSAST IaCスキャナーの両方の結果が含まれています。空の配列`[]`は、すべてのセキュリティスキャナーにルールを適用します。|
| `vulnerabilities_allowed`  | `integer`           | はい                                       | 0以上                                                                                      | このルールが考慮される前に許可される脆弱性の数。 |
| `severity_levels`          | `array`の`string` | はい                                       | `info`、`unknown`、`low`、`medium`、`high`、`critical`                                                             | このルールで考慮する重大度レベル。 |
| `vulnerability_states`     | `array`の`string` | はい                                       | `[]`または`detected`、`confirmed`、`resolved`、`dismissed`、`new_needs_triage`、`new_dismissed`                      | すべての脆弱性は、次の2つのカテゴリに分類されます:<br><br>**Newly Detected Vulnerabilities**（新しく検出された脆弱性） - マージリクエストブランチ自体で識別されたが、現在マージリクエストのターゲットブランチに存在しない脆弱性。このポリシーオプションでは、承認ルールを評価する前にパイプラインを完了する必要があるため、脆弱性が新しく検出されたかどうかを認識できます。マージリクエストは、パイプラインと必要なセキュリティスキャンが完了するまでブロックされます。`new_needs_triage`オプションはステータスを考慮します<br><br> • 検出済み<br><br> `new_dismissed`オプションはステータスを考慮します<br><br> • 削除済み<br><br>**Pre-Existing Vulnerabilities**（既存の脆弱性） - これらのポリシーオプションはすぐに評価され、デフォルトブランチで以前に検出された脆弱性のみを考慮するため、パイプラインの完了は必要ありません。<br><br> • `Detected` - ポリシーは、検出された状態の脆弱性を探します。<br> • `Confirmed` - ポリシーは、確認された状態の脆弱性を探します。<br> • `Dismissed` - ポリシーは、無視された状態の脆弱性を探します。<br> • `Resolved` - ポリシーは、解決済みの状態の脆弱性を探します。<br><br>空の配列`[]`は、`['new_needs_triage', 'new_dismissed']`と同じステータスをカバーします。 |
| `vulnerability_attributes` | `object`            | いいえ                                      | `{false_positive: boolean, fix_available: boolean}`                                                                | すべての脆弱性の調査結果は、デフォルトで考慮されます。ただし、属性にフィルターを適用して、脆弱性の調査結果のみを考慮することができます:<br><br> • 修正プログラムが利用可能（`fix_available: true`）<br><br> • 修正プログラムが利用できない（`fix_available: false`）<br> • 誤検出である（`false_positive: true`）<br> • 誤検出ではない（`false_positive: false`）<br> • または両方の組み合わせです。例: `fix_available: true, false_positive: false` |
| `vulnerability_age`        | `object`            | いいえ                                      | N/A                                                                                                                | 年齢別に既存の脆弱性の調査結果をフィルタリングします。脆弱性の年齢は、プロジェクトで検出されてからの時間として計算されます。基準は、`operator`、`value`、および`interval`です。<br>- `operator`の条件は、使用される期間の比較が、`greater_than` (より長い) か`less_than` (より短い) のどちらであるかを指定します。<br>- `value`の条件は、脆弱性の期間を表す数値を指定します。<br>- `interval`の条件は、脆弱性の期間の測定単位 (`day`、`week`、`month`、または`year`) を指定します。<br><br>例: `operator: greater_than`、`value: 30`、`interval: day`。 |

## `license_finding`ルールタイプ {#license_finding-rule-type}

{{< history >}}

- GitLab 15.9で`license_scanning_policies`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/8092)されました。
- GitLab 15.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/397644)になりました。機能フラグ`license_scanning_policies`は削除されました。
- `branch_exceptions`フィールドは、`security_policies_branch_exceptions`という名前の[フラグ](../../../administration/feature_flags/_index.md)を付けて、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418741)されました。デフォルトでは有効になっています。GitLab 16.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753)になりました。機能フラグは削除されました。
- `licenses`フィールドは、`exclude_license_packages`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)を付けて、GitLab 17.11で[導入](https://gitlab.com/groups/gitlab-org/-/epics/10203)されました。機能フラグは削除されました。

{{< /history >}}

このルールは、ライセンスの検出に基づいて定義されたアクションを適用します。

| フィールド          | 型     | 必須                                      | 使用可能な値              | 説明                                                                                                                                                                                                         |
|----------------|----------|-----------------------------------------------|------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `type`         | `string` | はい                                          | `license_finding`            | ルールの種類。                                                                                                                                                                                                    |
| `branches`     | `array`の`string` | `branch_type`フィールドが存在しない場合はtrue    | `[]`またはブランチの名前    | 保護されたターゲットブランチにのみ適用できます。空の配列`[]`は、すべての保護されたターゲットブランチにルールを適用します。`branch_type`フィールドでは使用できません。                                                 |
| `branch_type`  | `string` | `branches`フィールドが存在しない場合はtrue       | `default`または`protected`     | 指定されたポリシーが適用される、保護ブランチのタイプ。`branches`フィールドでは使用できません。デフォルトブランチも`protected`である必要があります。                                                                   |
| `branch_exceptions` | `array`の`string` | いいえ                                         | ブランチの名前            | このルールから除外するターゲットブランチ。                                                                                                                                                                                 |
| `match_on_inclusion_license` | `boolean` | `licenses`フィールドが存在しない場合はtrue      | `true`、`false`              | ルールが、`license_types`にリストされているライセンスを含めるか、除外するかを照合するかどうか。                                                                                                                              |
| `license_types` | `array`の`string` | `licenses`フィールドが存在しない場合はtrue      | ライセンスの種類                | 照合する[SPDXライセンス名](https://spdx.org/licenses)（`Affero General Public License v1.0`や`MIT License`など）。                                                                                     |
| `license_states` | `array`の`string` | はい                                          | `newly_detected`、`detected` | 新しく検出されたライセンスと、以前に検出されたライセンスを照合するかどうか。`newly_detected`ステートは、新しいパッケージが導入された場合、または既存のパッケージの新しいライセンスが検出された場合にトリガー承認します。 |
| `licenses`     | `object` | `license_types`フィールドが存在しない場合はtrue | `licenses`オブジェクト            | パッケージの除外を含む照合する[SPDXライセンス名](https://spdx.org/licenses)。                                                                                                                        |

### `licenses`オブジェクト {#licenses-object}

| フィールド     | 型     | 必須                                | 使用可能な値                                      | 説明                                                |
|-----------|----------|-----------------------------------------|------------------------------------------------------|------------------------------------------------------------|
| `denied`  | `object` | `allowed`フィールドが存在しない場合はtrue | `licenses_with_package_exclusion`オブジェクトの`array`  | パッケージの除外を含む、拒否されたライセンスのリスト。  |
| `allowed` | `object` | `denied`フィールドが存在しない場合はtrue  | `licenses_with_package_exclusion`オブジェクトの`array`  | パッケージの除外を含む、許可されたライセンスのリスト。 |

### `licenses_with_package_exclusion`オブジェクト {#licenses_with_package_exclusion-object}

| フィールド  | 型     | 必須 | 使用可能な値   | 説明                                        |
|--------|----------|----------|-------------------|----------------------------------------------------|
| `name` | `string` | はい     | SPDXライセンス名 | [SPDXライセンス名](https://spdx.org/licenses)。    |
| `packages` | `object` | いいえ    | `packages`オブジェクト | 指定されたライセンスのパッケージの除外のリスト。 |

### `packages`オブジェクト {#packages-object}

| フィールド  | 型     | 必須 | 使用可能な値                                       | 説明                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|--------|----------|----------|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `excluding` | `object` | はい     | {purls: `uri`形式を使用した`strings`の`array`} | 指定されたライセンスのパッケージの除外のリスト。[`purl`（）](https://github.com/package-url/purl-spec?tab=readme-ov-file#purl)コンポーネント`scheme:type/name@version`を使用して、パッケージの除外のリストを定義します。`scheme:type/name`コンポーネントは必須です。`@`と`version`はオプションです。バージョンが指定されている場合は、そのバージョンのみが除外と見なされます。バージョンが指定されておらず、`@`文字が`purl`の最後に追加されている場合は、完全に同じ名前のパッケージのみが一致すると見なされます。`@`文字がパッケージ名に追加されていない場合、指定されたライセンスに対して同じプレフィックスを持つすべてのパッケージが一致します。たとえば、purl `pkg:gem/bundler`は、両方のパッケージが同じライセンスを使用しているため、`bundler`および`bundler-stats`パッケージと一致します。`purl` `pkg:gem/bundler@`を定義すると、`bundler`パッケージのみが一致します。 |

## `any_merge_request`ルールタイプ {#any_merge_request-rule-type}

{{< history >}}

- `branch_exceptions`フィールドは、`security_policies_branch_exceptions`という名前の[フラグ](../../../administration/feature_flags/_index.md)を付けて、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418741)されました。デフォルトでは有効になっています。GitLab 16.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753)になりました。機能フラグは削除されました。
- `any_merge_request`承認ルールタイプは、GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418752)されました。デフォルトでは有効になっています。GitLab 16.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136298)になりました。機能フラグは[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/432127)されました。

{{< /history >}}

このルールは、コミットの署名に基づいて、任意のマージリクエストに対して定義されたアクションを適用します。

| フィールド               | 型                | 必須                                   | 使用可能な値           | 説明 |
|---------------------|---------------------|--------------------------------------------|---------------------------|-------------|
| `type`              | `string`            | はい                                       | `any_merge_request`       | ルールの種類。 |
| `branches`          | `array`の`string` | `branch_type`フィールドが存在しない場合はtrue | `[]`またはブランチの名前 | 保護されたターゲットブランチにのみ適用できます。空の配列`[]`は、すべての保護されたターゲットブランチにルールを適用します。`branch_type`フィールドでは使用できません。 |
| `branch_type`       | `string`            | `branches`フィールドが存在しない場合はtrue    | `default`または`protected`  | 指定されたポリシーが適用される、保護ブランチのタイプ。`branches`フィールドでは使用できません。デフォルトブランチも`protected`である必要があります。 |
| `branch_exceptions` | `array`の`string` | いいえ                                      | ブランチの名前         | このルールから除外するターゲットブランチ。 |
| `commits`           | `string`            | はい                                       | `any`、`unsigned`         | ルールがあらゆるコミットと一致するか、署名なしコミットがマージリクエストで検出された場合にのみ一致するか。 |

## `require_approval`アクションタイプ {#require_approval-action-type}

{{< history >}}

- GitLab 17.7では、`multiple_approval_actions`という名前の[フラグ](../../../administration/feature_flags/_index.md)を使用して、最大5つの個別の`require_approval`アクションのサポートが[追加](https://gitlab.com/groups/gitlab-org/-/epics/12319)されました。
- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/505374)になりました。機能フラグ`multiple_approval_actions`は削除されました。
- GitLab 17.9では、`security_policy_custom_roles`という名前の[フラグ](../../../administration/feature_flags/_index.md)を使用して、カスタムロールを`role_approvers`として指定するサポートが[導入](https://gitlab.com/groups/gitlab-org/-/epics/13550)されました。デフォルトでは有効になっています。
- GitLab 17.10で、[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/505742)になりました。機能フラグ`security_policy_custom_roles`は削除されました。

{{< /history >}}

このアクションは、定義されたセキュリティポリシールールの少なくとも1つのルールに対して条件が満たされたときに、承認ルールを必須にします。

同じ`require_approval`ブロックに複数の承認者を指定した場合、対象となる承認者はいずれも承認要件を満たすことができます。たとえば、2つの`group_approvers`と`2`を`approvals_required`として指定した場合、両方の承認が同じグループから得られる可能性があります。固有の承認者タイプからの複数の承認を要求するには、複数の`require_approval`アクションを使用します。

| フィールド | 型 | 必須 | 使用可能な値 | 説明 |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | はい | `require_approval` | アクションのタイプ。 |
| `approvals_required` | `integer` | はい | 0以上 | 必要なMR承認の数。 |
| `user_approvers` | `array`の`string` | 条件付き | 1人以上のユーザーのユーザー名 | 承認者と見なされるユーザー。ユーザーが承認の対象となるには、プロジェクトへのアクセス権を持っている必要があります。 |
| `user_approvers_ids` | `array`の`integer` | 条件付き<sup>1</sup> | 1人以上のユーザーの | 承認者と見なされるユーザーの。ユーザーが承認の対象となるには、プロジェクトへのアクセス権を持っている必要があります。 |
| `group_approvers` | `array`の`string` | 条件付き<sup>1</sup> | 1つ以上のグループのパス | 承認者と見なされるグループ。[グループに直接所属する](../../project/merge_requests/approvals/rules.md#group-approvers)ユーザーは、承認の対象となります。 |
| `group_approvers_ids` | `array`の`integer` | 条件付き<sup>1</sup> | 1つ以上のグループの | 承認者と見なされるグループの。[グループに直接所属する](../../project/merge_requests/approvals/rules.md#group-approvers)ユーザーは、承認の対象となります。 |
| `role_approvers` | `array`の`string` | 条件付き<sup>1</sup> | 1つ以上の[ロール](../../permissions.md#roles)（例: `owner`、`maintainer`）。カスタムロールがマージリクエストを承認する権限を持っている場合は、カスタムロール (またはYAMLモードのカスタムロール識別子) を`role_approvers`として指定することもできます。カスタムロールは、ユーザーおよびグループ承認者と一緒に選択できます。 | 承認の対象となるロール。 |

**補足説明:**

1. 承認者フィールド (`user_approvers`、`user_approvers_ids`、`group_approvers`、`group_approvers_ids`、または`role_approvers`) を使用して、少なくとも1人の承認者を指定する必要があります。

### 有効な設定例 {#valid-configuration-examples}

**有効な`user_approvers`:**

```yaml
actions:
  - type: require_approval
    approvals_required: 2
    user_approvers:
      - alice
      - bob
```

**有効な`group_approvers`:**

```yaml
actions:
  - type: require_approval
    approvals_required: 1
    group_approvers:
      - security-team
```

**有効な`role_approvers`:**

```yaml
actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
      - maintainer
```

**Valid with multiple approver types:**（複数の承認者タイプで有効: ）

```yaml
actions:
  - type: require_approval
    approvals_required: 2
    user_approvers:
      - alice
    group_approvers:
      - security-team
    role_approvers:
      - maintainer
```

### 無効な設定例 {#invalid-configuration-example}

**Invalid because no approvers specified:**（承認者が指定されていないため無効: ）

```yaml
actions:
  - type: require_approval
    approvals_required: 2
    # ERROR: At least one approver field must be specified
    # This configuration will fail validation
```

## `send_bot_message`アクションタイプ {#send_bot_message-action-type}

{{< history >}}

- `send_bot_message`アクションタイプは、GitLab 16.11で[プロジェクト用に導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438269)されました(`approval_policy_disable_bot_comment`という名前の[フラグ](../../../administration/feature_flags/_index.md)付き)。デフォルトでは無効になっています。
- GitLab 17.0の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/454852)になりました。
- GitLab 17.3で[一般公開](https://gitlab.com/gitlab-org/gitlab/-/issues/454852)になりました。機能フラグ`approval_policy_disable_bot_comment`は削除されました。
- `send_bot_message`アクションタイプは、GitLab 17.2で[グループ用に導入](https://gitlab.com/gitlab-org/gitlab/-/issues/469449)されました(`approval_policy_disable_bot_comment_group`という名前の[フラグ](../../../administration/feature_flags/_index.md)付き)。デフォルトでは無効になっています。
- GitLab 17.2の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/469449)になりました。
- GitLab 17.3で[一般公開](https://gitlab.com/gitlab-org/gitlab/-/issues/469449)になりました。機能フラグ`approval_policy_disable_bot_comment_group`は削除されました。

{{< /history >}}

このアクションにより、セキュリティポリシー違反が検出されたときに、マージリクエストのボットメッセージの設定が有効になります。アクションが指定されていない場合、ボットメッセージはデフォルトで有効になります。複数のセキュリティポリシーが定義されている場合、それらのセキュリティポリシーの少なくとも1つで`send_bot_message`アクションが有効になっている限り、ボットメッセージが送信されます。

| フィールド | 型 | 必須 | 使用可能な値 | 説明 |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | はい | `send_bot_message` | アクションのタイプ。 |
| `enabled` | `boolean` | はい | `true`、`false` | セキュリティポリシー違反が検出されたときに、ボットメッセージを作成するかどうか。デフォルトは`true`です。 |

### ボットメッセージの例 {#example-bot-messages}

![セキュリティスキャンによって検出された脆弱性を示すボットメッセージの例。](img/scan_result_policy_example_bot_message_vulnerabilities_v17_0.png)

![セキュリティポリシーの評価に必要な、欠落している、または不完全なスキャンアーティファクトを示すボットメッセージの例。](img/scan_result_policy_example_bot_message_artifacts_v17_0.png)

## 警告モード {#warn-mode}

{{< history >}}

- GitLab 17.8で`security_policy_approval_warn_mode`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/15552)されました。デフォルトでは無効になっています

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

警告モードを使用すると、セキュリティチームは、セキュリティポリシーを完全に適用する前に、セキュリティポリシーの影響をテストおよび検証して、新しいセキュリティポリシーの適用時にデベロッパーの摩擦を軽減できます。`enforcement_type: warn`で設定されたセキュリティポリシーでは、マージリクエストはマージリクエスト承認ポリシー違反を回避するオプションを提供します。

警告モードが有効 (`enforcement_type: warn`) で、マージリクエストがセキュリティポリシー違反をトリガーすると、ポリシーの適用がいくつかの点で異なります:

- ブロックしない検証: このポリシーは、ポリシー違反をリストする有益なボットコメントを生成します。
- オプションの承認: ユーザーがポリシーを回避し、却下の理由を提供した場合、承認はオプションです。
- 強化された監査: マージリクエストが回避されたセキュリティポリシーとマージされた後、監査証跡イベントが作成されます。
- 脆弱性レポートのインテグレーション: 脆弱性が回避されたポリシーを含むマージリクエストによって導入された場合、回避の詳細は、脆弱性レポートに表示されます。
- 承認設定は無効: 承認設定のオーバーライドは適用されません。

### 警告モードの設定 {#configuring-warn-mode}

マージリクエスト承認ポリシーに対して警告モードを有効にするには、`enforcement_type`フィールドを`warn`に設定します:

```yaml
approval_policy:
  - name: Warn mode policy
    description: ''
    enabled: true
    enforcement_type: warn
    policy_scope:
      projects:
        excluding: []
    rules:
      - type: scan_finding
        scanners:
          - secret_detection
        vulnerabilities_allowed: 0
        severity_levels: []
        vulnerability_states: []
        branch_type: protected
    actions:
      - type: require_approval
        approvals_required: 1
        role_approvers:
          - developer
          - maintainer
      - type: send_bot_message
        enabled: true
```

### サポートされているルールタイプ {#supported-rule-types}

警告モードは、次のルールタイプをサポートしています:

- `scan_finding`: セキュリティスキャンの結果
- `any_merge_request`: 一般的なマージリクエストの条件

{{< alert type="note" >}}

`license_finding`ルールタイプは、警告モードの適用ではサポートされていません。

{{< /alert >}}

## `approval_settings` {#approval_settings}

{{< history >}}

- `block_group_branch_modification`フィールドは、`scan_result_policy_block_group_branch_modification`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)を付けて、GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/420724)されました。
- GitLab 17.6で[GitLab.comとGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/437306)。
- GitLab 17.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/503930)が開始されました。機能フラグ`scan_result_policy_block_group_branch_modification`は削除されました。
- `block_unprotecting_branches`フィールドは、`scan_result_policy_settings`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)を付けて、GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/423101)されました。デフォルトでは無効になっています。
- `scan_result_policy_settings`機能フラグは、16.4で`scan_result_policies_block_unprotecting_branches`機能フラグに置き換えられました。
- `block_unprotecting_branches`フィールドは、GitLab 16.7で`block_branch_modification`フィールドに[置き換え](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137153)られました。
- GitLab 16.7の[GitLab.comおよびGitLab Self-Managedで有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/423901)されました。
- GitLab 16.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/433415)になりました。機能フラグ`scan_result_policies_block_unprotecting_branches`は削除されました。
- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418752)された`prevent_approval_by_author`、`prevent_approval_by_commit_author`、`remove_approvals_with_new_commit`、および`require_password_to_approve`フィールド（GitLab 16.4、[フラグ](../../../administration/feature_flags/_index.md)付き、`scan_result_any_merge_request`という名前）。デフォルトでは無効になっています。
- GitLab 16.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/423988)になりました。
- GitLab 16.7で[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/423988)になりました。
- GitLab 16.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/432127)になりました。機能フラグ`scan_result_any_merge_request`は削除されました。
- `prevent_pushing_and_force_pushing`フィールドは、`scan_result_policies_block_force_push`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)を付けて、GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/420629)されました。デフォルトでは無効になっています。
- GitLab 16.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/427260)になりました。
- GitLab 16.7で[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/427260)になりました。
- GitLab 16.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/432123)になりました。機能フラグ`scan_result_policies_block_force_push`は削除されました。

{{< /history >}}

セキュリティポリシーで設定された設定は、プロジェクトの設定を上書きします。

| フィールド                               | 型                  | 必須 | 使用可能な値                                               | 該当するルールタイプ | 説明 |
|-------------------------------------|-----------------------|----------|---------------------------------------------------------------|----------------------|-------------|
| `block_branch_modification`         | `boolean`             | いいえ    | `true`、`false`                                               | すべて                  | 有効にすると、ユーザーは、保護されたブランチリストからブランチを削除したり、保護されたブランチを削除したり、そのブランチがセキュリティポリシーに含まれている場合はデフォルトブランチを変更したりすることができなくなります。これにより、ユーザーが脆弱性のあるコードをマージするためにブランチから保護ステータスを削除できなくなります。`branches`、`branch_type`、および`policy_scope`に基づいて適用され、検出された脆弱性に関係なく適用されます。 |
| `block_group_branch_modification`   | `boolean`または`object` | いいえ    | `true`、`false`、`{ enabled: boolean, exceptions: [{ id: Integer}] }` | すべて                  | 有効にすると、ユーザーは、ポリシーが適用されるすべてのグループで、グループレベルで保護されたブランチを削除できなくなります。`block_branch_modification`が`true`の場合、暗黙的にデフォルトは`true`になります。[グループレベルで保護されたブランチ](../../project/repository/branches/protected.md#in-a-group)をサポートするトップレベルグループを`exceptions`として追加します |
| `prevent_approval_by_author`        | `boolean`             | いいえ    | `true`、`false`                                               | `Any merge request`  | 有効にすると、マージリクエストの作成者は自分のMRを承認できません。これにより、コードの作成者が脆弱性を導入し、マージするコードを承認できなくなります。 |
| `prevent_approval_by_commit_author` | `boolean`             | いいえ    | `true`、`false`                                               | `Any merge request`  | 有効にすると、MRにコントリビュートしたユーザーは承認の対象外となります。これにより、コミッターが脆弱性を導入し、マージするコードを承認できなくなります。 |
| `remove_approvals_with_new_commit`  | `boolean`             | いいえ    | `true`、`false`                                               | `Any merge request`  | 有効にすると、MRがマージに必要なすべての承認を受け取った後、新しいコミットが追加された場合、新しい承認が必要になります。これにより、脆弱性が含まれる可能性のある新しいコミットが導入されないようにします。 |
| `require_password_to_approve`       | `boolean`             | いいえ    | `true`、`false`                                               | `Any merge request`  | 有効にすると、承認時にパスワード検証が行われます。パスワード検証により、セキュリティのレイヤーが追加されます。 |
| `prevent_pushing_and_force_pushing` | `boolean`             | いいえ    | `true`、`false`                                               | すべて                  | 有効にすると、そのブランチがセキュリティポリシーに含まれている場合、ユーザーは保護されたブランチへのプッシュおよび強制プッシュができなくなります。これにより、ユーザーはマージリクエストプロセスを回避して、脆弱性のあるコードをブランチに追加することがなくなります。 |

## `fallback_behavior` {#fallback_behavior}

{{< history >}}

- `fallback_behavior`フィールドは、`security_scan_result_policies_unblock_fail_open_approval_rules`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)を付けて、GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/451784)されました。デフォルトでは無効になっています。
- `fallback_behavior`フィールドは、GitLab 17.0で[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効化](https://gitlab.com/groups/gitlab-org/-/epics/10816)されました。

{{< /history >}}

{{< alert type="flag" >}}

GitLabセルフマネージドでは、デフォルトで`fallback_behavior`フィールドを使用できます。この機能を非表示にするために、管理者は`security_scan_result_policies_unblock_fail_open_approval_rules`という名前の[機能フラグを無効](../../../administration/feature_flags/_index.md)にできます。GitLab.comおよびGitLab Dedicatedでは、この機能を使用できます。

{{< /alert >}}

| フィールド  | 型     | 必須 | 使用可能な値    | 説明                                                                                                          |
|--------|----------|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|
| `fail` | `string` | いいえ    | `open`または`closed` | `closed`（デフォルト）: ポリシーの無効なルールまたは適用できないルールには承認が必要です。`open`: ポリシーの無効なルールまたは適用できないルールに承認は不要です。 |

## `policy_tuning` {#policy_tuning}

### `unblock_rules_using_execution_policies` {#unblock_rules_using_execution_policies}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/498624)パイプライン実行ポリシーでの使用のサポート（GitLab 17.10、名前が`unblock_rules_using_pipeline_execution_policies`の[フラグ](../../../administration/feature_flags/_index.md)付き）。デフォルトでは有効になっています。
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/525270)になりました。機能フラグ`unblock_rules_using_pipeline_execution_policies`は削除されました。

{{< /history >}}

| フィールド  | 型     | 必須 | 使用可能な値    | 説明                                                                                                          |
|--------|----------|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|
| `unblock_rules_using_execution_policies` | `boolean` | いいえ    | `true`、`false` | 有効にすると、スキャン実行ポリシーまたはパイプライン実行ポリシーによってスキャンが要求されているものの、必要なスキャンアーティファクトがターゲットブランチにない場合、承認ルールはマージリクエストをブロックしません。このオプションは、プロジェクトまたはグループに、一致するスキャナーを備えた既存のスキャン実行ポリシーまたはパイプライン実行ポリシーがある場合にのみ機能します。 |

[ライセンス検出ルール](#license_finding-rule-type)は、新しく検出された状態のみを対象とする場合 (`license_states`が`newly_detected`に設定されている場合) にのみ除外できます。

#### 例 {#examples}

##### スキャン実行ポリシーを使用した`policy_tuning`の例 {#example-of-policy_tuning-with-a-scan-execution-policy}

[セキュリティポリシープロジェクト](enforcement/security_policy_projects.md)に格納されている`.gitlab/security-policies/policy.yml`ファイルで、この例を使用できます:

```yaml
scan_execution_policy:
- name: Enforce dependency scanning
  description: ''
  enabled: true
  policy_scope:
    projects:
      excluding: []
  rules:
  - type: pipeline
    branch_type: all
  actions:
  - scan: dependency_scanning
approval_policy:
- name: Dependency scanning approvals
  description: ''
  enabled: true
  policy_scope:
    projects:
      excluding: []
  rules:
  - type: scan_finding
    scanners:
    - dependency_scanning
    vulnerabilities_allowed: 0
    severity_levels: []
    vulnerability_states: []
    branch_type: protected
  actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
    - developer
  - type: send_bot_message
    enabled: true
  fallback_behavior:
    fail: closed
  policy_tuning:
    unblock_rules_using_execution_policies: true
```

##### パイプライン実行ポリシーを使用した`policy_tuning`の例 {#example-of-policy_tuning-with-a-pipeline-execution-policy}

{{< alert type="warning" >}}

この機能は、GitLab 17.10より前に作成されたパイプライン実行ポリシーでは機能しません。この機能を以前のパイプライン実行ポリシーで使用するには、ポリシーをコピーし、削除してから再作成してください。詳細については、[GitLab 17.10より前に作成されたパイプライン実行ポリシーの再作成](#recreate-pipeline-execution-policies-created-before-gitlab-1710)を参照してください。

{{< /alert >}}

[セキュリティポリシープロジェクト](enforcement/security_policy_projects.md)に格納されている`.gitlab/security-policies/policy.yml`ファイルで、この例を使用できます:

```yaml
---
pipeline_execution_policy:
- name: Enforce dependency scanning
  description: ''
  enabled: true
  pipeline_config_strategy: inject_policy
  content:
    include:
    - project: my-group/pipeline-execution-ci-project
      file: policy-ci.yml
      ref: main # optional
```

リンクされたパイプライン実行ポリシーCI/CD設定（`policy-ci.yml`）:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml
```

###### GitLab 17.10より前に作成されたパイプライン実行ポリシーの再作成 {#recreate-pipeline-execution-policies-created-before-gitlab-1710}

GitLab 17.10より前に作成されたパイプライン実行ポリシーには、`policy_tuning`機能を使用するために必要なデータが含まれていません。この機能を以前のパイプライン実行ポリシーで使用するには、古いポリシーをコピーして削除し、それから再作成します。

<i class="fa-youtube-play" aria-hidden="true"></i>ビデオによるチュートリアルについては、[Security Policies: `policy_tuning`で使用するパイプライン実行ポリシーを再作成します](https://youtu.be/XN0jCQWlk1A)。
<!-- Video published on 2025-03-07 -->

パイプライン実行ポリシーを再作成するには:

<!-- markdownlint-disable MD044 -->

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオン](../../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **セキュリティ** > **ポリシー**を選択します。
1. 再作成するパイプライン実行ポリシーを選択します。
1. 右側のサイドバーで、**YAML**タブを選択し、ポリシーファイル全体の内容をコピーします。
1. ポリシーテーブルの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、**削除**を選択します。
1. 生成されたマージリクエストをマージします。
1. **セキュリティ** > **ポリシー**に戻り、**新規ポリシー**を選択します。
1. **パイプライン実行ポリシー**セクションで、**ポリシーの選択**を選択します。
1. **.yamlモード**で、古いポリシーの内容を貼り付けます。
1. **マージリクエスト経由で更新**を選択し、生成されたマージリクエストをマージします。

<!-- markdownlint-enable MD044 -->

### `security_report_time_window` {#security_report_time_window}

{{< history >}}

- GitLab 18.5で`approval_policy_time_window`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/525509)されました。
- GitLab 18.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/543027)になりました。機能フラグ`approval_policy_time_window`は削除されました。

{{< /history >}}

多忙なプロジェクトでは、最新のパイプラインで、すぐに利用できるセキュリティレポートが完了していない場合があり、セキュリティレポートの比較がブロックされます。代わりに、最近完了したパイプラインからセキュリティレポートを取得するには、`security_report_time_window`設定を使用します。セキュリティレポートは、ターゲットブランチのパイプラインが作成される前の時間枠（分単位で指定）よりも古くすることはできません。選択したパイプラインに完了したセキュリティレポートが既にある場合、この設定は適用されません。

| フィールド  | 型     | 必須 | 使用可能な値    | 説明                                                                                                          |
|--------|----------|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|
| `security_report_time_window` | `integer` | いいえ    | 1～10080（7日間） | セキュリティレポートの比較のためにターゲットブランチのパイプラインを選択する時間枠を分単位で指定します。 |

## ポリシーのスコープスキーマ {#policy-scope-schema}

ポリシーの適用をカスタマイズするには、ポリシーのスコープを定義して、指定されたプロジェクト、グループ、またはコンプライアンスフレームワークのラベルを含めるか、除外することができます。詳細については、[スコープ](_index.md#configure-the-policy-scope)を参照してください。

## `bypass_settings` {#bypass_settings}

`bypass_settings`フィールドを使用すると、特定のブランチ、アクセストークン、またはサービスアカウントに対するポリシーの例外を指定できます。バイパス条件が満たされると、ポリシーは一致するマージリクエストまたはブランチに適用されません。

| フィールド             | 型    | 必須 | 説明                                                                     |
|-------------------|---------|----------|---------------------------------------------------------------------------------|
| `branches`        | 配列   | いいえ    | ポリシーをバイパスするソースブランチおよびターゲットブランチ（名前またはパターン別）のリスト。 |
| `access_tokens`   | 配列   | いいえ    | ポリシーをバイパスするアクセストークンIDのリスト。                                |
| `service_accounts`| 配列   | いいえ    | ポリシーをバイパスするサービスアカウントIDのリスト。                             |
| `users`           | 配列   | いいえ    | ポリシーをバイパスできるユーザーIDのリスト。                                        |
| `groups`          | 配列   | いいえ    | ポリシーをバイパスできるグループIDのリスト。                                       |
| `roles`           | 配列   | いいえ    | ポリシーをバイパスできるデフォルトロールのリスト。                                   |
| `custom_roles`    | 配列   | いいえ    | ポリシーをバイパスできるカスタムロールIDのリスト。                                 |

### ソースブランチの例外 {#source-branch-exceptions}

{{< history >}}

- GitLab 18.2で`approval_policy_branch_exceptions`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/18113)されました。デフォルトでは有効になっています
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/543778)になりました。機能フラグ`approval_policy_branch_exceptions`は削除されました。

{{< /history >}}

ブランチベースの例外を使用すると、特定ソースブランチとターゲットブランチの組み合わせに対するマージリクエスト承認ポリシーの承認要件を自動的に免除するように設定できます。これにより、セキュリティガバナンスを維持し、特定の種類のマージ（feature-to-mainなど）に対して厳格な承認ルールを維持しながら、他のマージ（リリース-to-mainなど）に対してより柔軟に対応できます。

| フィールド   | 型   | 必須 | 使用可能な値 | 説明 |
|---------|--------|----------|-----------------|-------------|
| `source`| オブジェクト | いいえ    | `name`（文字列）または`pattern`（文字列） | ソースブランチの例外。正確な名前またはパターンを指定します。         |
| `target`| オブジェクト | いいえ    | `name`（文字列）または`pattern`（文字列） | ターゲットブランチの例外。正確な名前またはパターンを指定します。         |

### アクセストークンとサービスアカウントの例外 {#access-token-and-service-account-exceptions}

{{< history >}}

- GitLab 18.2で`security_policies_bypass_options_tokens_accounts`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/18112)されました。デフォルトでは有効になっています
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/551129)になりました。機能フラグ`security_policies_bypass_options_tokens_accounts`は削除されました。

{{< /history >}}

アクセストークンとサービスアカウントの例外を使用すると、必要に応じてマージリクエスト承認ポリシーによって適用されるブランチ保護を回避できる特定のサービスアカウントとアクセストークンを指定できます。このアプローチにより、ヒューマンユーザーの制限を維持しながら、信頼できる自動化を手動承認なしで動作させることができます。たとえば、信頼できる自動化には、CI/CDパイプライン、リポジトリのミラーリング、自動更新などが含まれます。バイパスイベントは完全に監査証跡され、コンプライアンスと緊急アクセスニーズをサポートできます。

| フィールド | 型    | 必須 | 説明                                    |
|-------|---------|----------|------------------------------------------------|
| `id`  | 整数 | はい     | アクセストークンまたはサービスアカウントのID。 |

### ユーザーがセキュリティポリシーを回避できるようにする {#allowing-users-to-bypass-security-policies}

{{< history >}}

- GitLab 18.5で`security_policies_bypass_options_group_roles`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/18114)されました。デフォルトでは有効になっています。
- GitLab 18.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/551920)になりました。機能フラグ`security_policies_bypass_options_group_roles`は削除されました。

{{< /history >}}

特定ユーザー、グループ、デフォルトロール、またはカスタムロールがマージリクエスト承認ポリシーを回避できるように指定することで、緊急事態に備えることができます。この機能により、包括的な監査証跡を提供し、ガバナンス制御を維持しながら、緊急対応に柔軟に対応できます。ユーザー、グループ、デフォルトロール、またはカスタムロールにセキュリティポリシーを回避する機能を与えるには、例外を付与します。

これらの例外を持つユーザーは、次の2つのレベルで回避できます:

- マージリクエスト承認要件: ユーザーは、マージリクエストUIから理由を提供することにより、承認要件を回避できます。
- ブランチ保護: ユーザーは、[`security_policy.bypass_reason`Gitプッシュオプション](../../../topics/git/commit.md#push-options-for-security-policy)で理由を提供することにより、マージリクエスト承認ポリシーからのプッシュ保護を使用して、ブランチに直接プッシュできます。

{{< alert type="note" >}}

`security_policy.bypass_reason`プッシュオプションは、[approval_settings](merge_request_approval_policies.md#approval_settings)で設定されたマージリクエスト承認ポリシーからのプッシュ保護を備えたブランチでのみ機能します。マージリクエスト承認ポリシーの対象とならない保護ブランチへのプッシュは、このオプションで回避できません。

{{< /alert >}}

#### YAMLの例 {#example-yaml}

```yaml
bypass_settings:
  access_tokens:
    - id: 123
    - id: 456
  service_accounts:
    - id: 789
    - id: 1011
  users:
    - id: 123
    - id: 456
  groups:
    - id: 789
    - id: 1011
  roles:
    - maintainer
    - developer
  custom_roles:
    - id: 789
    - id: 1011
```

## セキュリティポリシープロジェクトの`policy.yml`の例 {#example-policyyml-in-a-security-policy-project}

[セキュリティポリシープロジェクト](enforcement/security_policy_projects.md)に格納されている`.gitlab/security-policies/policy.yml`ファイルで、この例を使用できます:

```yaml
---
approval_policy:
- name: critical vulnerability CS approvals
  description: critical severity level only for container scanning
  enabled: true
  rules:
  - type: scan_finding
    branches:
    - main
    scanners:
    - container_scanning
    vulnerabilities_allowed: 0
    severity_levels:
    - critical
    vulnerability_states: []
    vulnerability_attributes:
      false_positive: true
      fix_available: true
  actions:
  - type: require_approval
    approvals_required: 1
    user_approvers:
    - adalberto.dare
- name: secondary CS approvals
  description: secondary only for container scanning
  enabled: true
  rules:
  - type: scan_finding
    branches:
    - main
    scanners:
    - container_scanning
    vulnerabilities_allowed: 1
    severity_levels:
    - low
    - unknown
    vulnerability_states:
    - detected
    vulnerability_age:
      operator: greater_than
      value: 30
      interval: day
  actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
    - owner
    - 1002816 # Example custom role identifier called "AppSec Engineer"
- name: critical vulnerability CS approvals
  description: high/critical severity level only for SAST scanning
  enabled: true
  enforcement_type: warn
  rules:
  - type: scan_finding
    branch_type: default
    scanners:
    - sast
    vulnerabilities_allowed: 0
    severity_levels:
    - critical
    - high
    vulnerability_states: []
  actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
    - maintainer
```

この例では: 

- コンテナスキャンによって識別された新しい`critical`脆弱性を含むすべてのマージリクエストには、`alberto.dare`からの1つの承認が必要です。
- コンテナスキャンによって識別された30日より古い複数の既存の`low`または`unknown`脆弱性を含むすべてのマージリクエストには、オーナーロールを持つプロジェクトメンバーまたはカスタムロール`AppSec Engineer`を持つユーザーからの1つの承認が必要です。
- SASTスキャンによって識別された新しい`critical`または`high`重大度の脆弱性を含むすべてのマージリクエストは、警告モードポリシーをトリガーします。警告モードでは、ボットコメントが生成され、マージリクエストがブロックされます。次に、開発者はポリシー違反を回避できます。オプションで、メンテナーがマージリクエストを承認することもできます。

## マージリクエスト承認ポリシーエディタの例 {#example-for-merge-request-approval-policy-editor}

この例は、[MRの承認ポリシーエディタ](#merge-request-approval-policy-editor)のYAMLモードで使用できます。これは、前の例の単一のオブジェクトに対応しています:

```yaml
type: approval_policy
name: critical vulnerability CS approvals
description: critical severity level only for container scanning
enabled: true
rules:
- type: scan_finding
  branches:
  - main
  scanners:
  - container_scanning
  vulnerabilities_allowed: 1
  severity_levels:
  - critical
  vulnerability_states: []
actions:
- type: require_approval
  approvals_required: 1
  user_approvers:
  - adalberto.dare
```

## マージリクエスト承認ポリシーの承認について {#understanding-merge-request-approval-policy-approvals}

{{< history >}}

- `scan_finding`のブランチ比較ロジックは、GitLab 16.8で名前が`scan_result_policy_merge_base_pipeline`の[フラグ付き](../../../administration/feature_flags/_index.md)で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/428518)されました。デフォルトでは無効になっています。
- GitLab 16.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/435297)になりました。機能フラグ`scan_result_policy_merge_base_pipeline`は削除されました。

{{< /history >}}

### マージリクエスト承認ポリシー比較のスコープ {#scope-of-merge-request-approval-policy-comparison}

- マージリクエストで承認が必要になるタイミングを判断するために、ソースブランチとターゲットブランチ（たとえば、`feature`/`main`）のサポートされている各パイプラインソースについて、完了したパイプラインを比較します。これにより、スキャン結果を最も包括的に評価できます。
- ソースブランチの場合、比較パイプラインは、ソースブランチの最新コミットに対する、サポートされている各パイプラインソースの完了したすべてのパイプラインです。
- マージリクエスト承認ポリシーが新たに検出された状態（`new_needs_triage`および`new_dismissed`）のみを探している場合、比較はソースブランチとターゲットブランチの間の共通祖先にある、サポートされているすべてのパイプラインソースに対して実行されます。例外は、マージ結果パイプラインを使用している場合で、その場合、比較はMRのターゲットブランチの先端に対して行われます。
- マージリクエスト承認ポリシーが、既存の状態（`detected`、`confirmed`、`resolved`、`dismissed`）を探している場合、比較は常にデフォルトブランチ（たとえば、`main`）の先端に対して行われます。
- マージリクエスト承認ポリシーが新規の脆弱性状態と既存の脆弱性状態の組み合わせを探している場合、比較はソースブランチとターゲットブランチの共通の祖先に対して行われます。
- マージリクエスト承認ポリシーは、マージリクエストに承認が必要かどうかを判断するときに、ソースブランチとターゲットブランチの両方からの結果を比較するときに、サポートされているすべてのパイプラインソース（[変数`CI_PIPELINE_SOURCE`に基づく](../../../ci/variables/predefined_variables.md)）を考慮します。ソース`webide`を持つパイプラインはサポートされていません。
- GitLab 16.11以降では、選択した各パイプラインの子パイプラインも比較の対象となります。

### 将来のマージリクエストでリスクを受け入れ、脆弱性を無視する {#accepting-risk-and-ignoring-vulnerabilities-in-future-merge-requests}

新たに検出された調査結果（`new_needs_triage`または`new_dismissed`のステータス）のスコープが設定されているマージリクエスト承認ポリシーの場合、この脆弱性状態の影響を理解することが重要です。調査結果は、マージリクエストのブランチには存在するが、ターゲットブランチには存在しない場合に、新たに検出されたと見なされます。新たに検出された調査結果を含むブランチを含むマージリクエストが承認され、マージされると、承認者はこれらの脆弱性のリスクを「受け入れています」。1つ以上の同じ脆弱性がこの後に検出された場合、ステータスは`detected`になり、`new_needs_triage`または`new_dismissed`の調査結果を考慮するように構成されたポリシーでは無視されます。次に例を示します:

- 重大なSAST調査結果をブロックするようにマージリクエスト承認ポリシーが作成されます。CVE-1234のSAST調査結果が承認された場合、同じ違反を含む将来のマージリクエストでは、プロジェクトで承認は必要ありません。

`new_needs_triage`と`new_dismissed`の脆弱性状態を使用する場合、ポリシー規則に一致する調査結果が新規であり、まだトリアージされていない場合、それらが無視されている場合でも、ポリシーはMRをブロックします。マージリクエスト内で新しく検出され、無視された脆弱性を無視する場合は、`new_needs_triage`ステータスのみを使用できます。

ライセンス承認ポリシーを使用する場合、プロジェクト、コンポーネント（依存関係）、およびライセンスの組み合わせが評価で考慮されます。例外としてライセンスが承認された場合、将来のマージリクエストでは、プロジェクト、コンポーネント（依存関係）、およびライセンスの同じ組み合わせについて承認は必要ありません。この場合、コンポーネントのバージョンは考慮されません。以前に承認されたパッケージが新しいバージョンに更新された場合、承認者は再承認する必要はありません。次に例を示します:

- `AGPL-1.0`に一致する新たに検出されたライセンスを含むマージリクエストをブロックするように、ライセンス承認ポリシーが作成されます。コンポーネント`osframework`のプロジェクト`demo`で、ポリシーに違反する変更が加えられました。承認およびマージされた場合、ライセンス`AGPL-1.0`を使用したプロジェクト`demo`の`osframework`への将来のマージリクエストには、承認は必要ありません。

### 追加の承認 {#additional-approvals}

マージリクエスト承認ポリシーでは、状況によっては追加の承認手順が必要です。次に例を示します:

- 作業ブランチのセキュリティジョブの数が減少し、ターゲットブランチのセキュリティジョブの数と一致しなくなりました。ユーザーは、CI/CD設定からスキャンジョブを削除することで、スキャン結果ポリシーをスキップすることはできません。マージリクエスト承認ポリシールールで構成されたセキュリティスキャナーのみが、削除のためにチェックされます。

  たとえば、デフォルトブランチパイプラインに4つのセキュリティスキャンがある状況を考えてみましょう: `sast`、`secret_detection`、`container_scanning`、`dependency_scanning`。マージリクエスト承認ポリシーは、2つのスキャナー（`container_scanning`と`dependency_scanning`）を適用します。MRがマージリクエスト承認ポリシーで構成されたスキャン（たとえば、`container_scanning`）を削除すると、追加の承認が必要になります。
- だれかがパイプラインセキュリティジョブを停止すると、ユーザーはセキュリティスキャンをスキップできません。
- マージリクエスト内のジョブが`allow_failure: false`で構成されている場合、ジョブは失敗します。その結果、パイプラインはブロックされた状態になります。
- パイプラインには、パイプライン全体がパスするために正常に実行する必要がある手動のジョブがあります。

### 承認要件の評価に使用されるスキャン結果の管理 {#managing-scan-findings-used-to-evaluate-approval-requirements}

マージリクエスト承認ポリシーは、パイプラインの完了後、パイプライン内のスキャナーによって生成されたアーティファクトレポートを評価します。マージリクエスト承認ポリシーは、潜在的なリスクを識別し、マージリクエストをブロックし、承認を要求するために、スキャン結果の調査結果に基づいて結果を評価し、承認を決定することに重点を置いています。

マージリクエスト承認ポリシーは、そのスコープを超えてアーティファクトファイルまたはスキャナーに到達することはありません。代わりに、アーティファクトレポートからの結果を信頼します。これにより、チームはスキャンの実行とサプライチェーンを管理し、必要に応じて（たとえば、誤検出を除外するために）、アーティファクトレポートで生成されたスキャン結果をカスタマイズする柔軟性が得られます。

たとえば、ロックファイルの改ざんはセキュリティポリシー管理のスコープ外ですが、[コードオーナー](../../project/codeowners/_index.md#codeowners-file)または[外部ステータスチェック](../../project/merge_requests/status_checks.md)を使用することで軽減される場合があります。詳細については、[イシュー433029](https://gitlab.com/gitlab-org/gitlab/-/issues/433029)を参照してください。

![スキャン結果の評価](img/scan_results_evaluation_white-bg_v16_8.png)

### **Fix Available**（修正プログラムが利用可能）または**False Positive**（偽陽性）の属性を使用したポリシー違反の除外 {#filter-out-policy-violations-with-the-attributes-fix-available-or-false-positive}

不要な承認要件を回避するために、これらの追加フィルターは、最も実用的な調査結果でのみMRをブロックするようにするのに役立ちます。

`fix_available`を`false`に設定するか、ポリシーエディターで**等しくない**と**Fix Available**（修正プログラムが利用可能）に設定すると、調査結果にソリューションまたは修正が利用可能な場合、調査結果はポリシー違反とは見なされません。**解決策**という見出しの下の脆弱性オブジェクトの下部に解決策が表示されます。修正は、脆弱性オブジェクト内の**Resolve with Merge Request**（MRで解決） ボタンとして表示されます。

**Resolve with Merge Request**（MRで解決） ボタンは、次のいずれかの基準が満たされた場合にのみ表示されます:

1. SAST脆弱性は、GitLab Duo EnterpriseでUltimateプランにあるプロジェクトで検出されます。
1. コンテナスキャンの脆弱性が、`GIT_STRATEGY: fetch`が設定されているジョブのUltimateプランにあるプロジェクトで検出されます。さらに、脆弱性には、コンテナイメージで有効になっているリポジトリで利用可能な修正を含むパッケージが含まれている必要があります。
1. 依存関係スキャンの脆弱性が、yarnによって管理され、修正が利用可能なNode.jsプロジェクトで検出されます。さらに、プロジェクトはUltimateプランにあり、FIPSモードはインスタンスに対して無効になっている必要があります。

**Fix Available**（修正プログラムが利用可能）は、依存関係スキャンとコンテナスキャンにのみ適用されます。

**False Positive**（誤検出） 属性を使用すると同様に、`false_positive`を`false`に設定する（または、属性を**次のとおりではありません**と**False Positive**（誤検出） ポリシーエディタで設定する）ことで、ポリシーによって検出された結果を無視できます。

**False Positive**（誤検出） 属性は、SASTスキャナーの結果に対する脆弱性抽出ツールによって検出された結果にのみ適用されます。

### ポリシーの評価と脆弱性の状態の変化 {#policy-evaluation-and-vulnerability-state-changes}

ユーザーが脆弱性の状態を変更した場合（脆弱性の詳細ページで脆弱性を無視するなど）、パフォーマンス上の理由から、GitLabはマージリクエスト承認ポリシーを自動的に再評価しません。脆弱性レポートから更新されたデータを取得するには、マージリクエストを更新するか、関連するパイプラインを再実行します。

この動作により、最適なシステムパフォーマンスが確保され、セキュリティポリシーの適用が維持されます。ポリシーの評価は、次のパイプラインの実行中、またはマージリクエストが更新されたときに行われますが、脆弱性の状態が変化したときにすぐには行われません。

脆弱性の状態の変更をポリシーにすぐに反映するには、手動でパイプラインを実行するか、マージリクエストに新しいコミットをプッシュします。

## セキュリティウィジェットとポリシーボットの不一致について {#understanding-security-widget-and-policy-bot-discrepancies}

マージリクエストのセキュリティウィジェットの表示と、セキュリティボットのコメントが示す脆弱性に関して、不一致に気付く場合があります。これらの機能は、セキュリティ結果に対して異なるデータソースと比較方法を使用しているため、表示される内容に違いが生じる可能性があります。

データソース:

- マージリクエストの**Merge request security widget**（セキュリティウィジェット）: 最新のソースブランチのパイプラインからの結果を、デフォルトブランチのデータベースに以前に保存された脆弱性と比較します。
- **Security Bot (and approval policy logic)**（セキュリティボット（および承認ポリシーロジック））: 実際のパイプラインのアーティファクト間で、具体的には、最新の成功したターゲットブランチのパイプラインと最新の成功したソースブランチのパイプラインの間で結果を比較します。

### 不整合が発生する一般的なシナリオ {#common-scenarios-where-inconsistencies-occur}

データソースの違いにより、いくつかのシナリオで一貫性のない動作が発生する可能性があります。

#### ターゲットブランチでのセキュリティスキャンの欠落または失敗 {#missing-or-failed-security-scans-in-target-branch}

ターゲットブランチの最新のパイプラインが（設定ミスやジョブの失敗などが原因で）セキュリティスキャンを適切に実行できない場合、セキュリティボットは新しい結果をレポートし、結果を効果的に比較できないため、予防措置として承認を要求する可能性があります。一方、セキュリティウィジェットは、以前に保存された脆弱性データを使用するため、新しい脆弱性は表示されない場合があります。

#### 比較対象間のターゲットブランチの変更 {#changes-in-target-branch-between-comparisons}

ウィジェットが比較を行う時点とボットが比較を行う時点の間で、セキュリティプロファイルを変更する複数のコミットがターゲットブランチにある場合、結果が異なる可能性があります。

### 一貫性のある結果を得るためのベストプラクティス {#best-practices-for-consistent-results}

これらのセキュリティ機能を使用する際の混乱を最小限に抑えるには:

- パイプラインの完全な実行を確保: セキュリティスキャンがソースブランチとターゲットブランチの両方で正常に完了することを確認します。
- 一貫性のあるCI/CDの設定を維持: パイプラインでセキュリティスキャンの設定を削除したり、中断したりしないでください。
- 新しいプロジェクトの場合: マージリクエストを作成する前に、デフォルトブランチでセキュリティスキャンを実行して、ベースラインの脆弱性データを確立します。
- スキャン実行ポリシーの使用を検討してください: マージリクエスト承認ポリシーと組み合わせると、必要な場所で常にセキュリティスキャンが実行されるようになります。

## トラブルシューティング {#troubleshooting}

### マージリクエストルールウィジェットに、マージリクエストの承認ポリシーが無効であるか、重複していることが示される {#merge-request-rules-widget-shows-a-merge-request-approval-policy-is-invalid-or-duplicated}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabセルフマネージドの15.0から16.4では、最も可能性の高い原因は、プロジェクトがグループからエクスポートされ、別のグループにインポートされ、マージリクエスト承認ポリシールールがあったことです。これらのルールは、エクスポートされたものとは別のプロジェクトに保存されます。その結果、プロジェクトには、インポートされたプロジェクトのグループに存在しないエンティティを参照するポリシールールが含まれています。その結果、無効、重複、またはその両方のポリシールールが生成されます。

GitLabインスタンスからすべての無効なマージリクエスト承認ポリシールールを削除するために、管理者は[Railsコンソール](../../../administration/operations/rails_console.md)で次のスクリプトを実行できます。

```ruby
Project.joins(:approval_rules).where(approval_rules: { report_type: %i[scan_finding license_scanning] }).where.not(approval_rules: { security_orchestration_policy_configuration_id: nil }).find_in_batches.flat_map do |batch|
  batch.map do |project|
    # Get projects and their configuration_ids for applicable project rules
    [project, project.approval_rules.where(report_type: %i[scan_finding license_scanning]).pluck(:security_orchestration_policy_configuration_id).uniq]
  end.uniq.map do |project, configuration_ids| # We take only unique combinations of project + configuration_ids
    # If we find more configurations than what is available for the project, we take records with the extra configurations
    [project, configuration_ids - project.all_security_orchestration_policy_configurations.pluck(:id)]
  end.select { |_project, configuration_ids| configuration_ids.any? }
end.each do |project, configuration_ids|
  # For each found pair project + ghost configuration, we remove these rules for a given project
  Security::OrchestrationPolicyConfiguration.where(id: configuration_ids).each do |configuration|
    configuration.delete_scan_finding_rules_for_project(project.id)
  end
  # Ensure we sync any potential rules from new group's policy
  Security::ScanResultPolicies::SyncProjectWorker.perform_async(project.id)
end
```

### 新しく検出されたCVE {#newly-detected-cves}

`new_needs_triage`と`new_dismissed`を使用すると、一部の結果は、マージリクエストによって導入されていない場合（関連する依存関係にある新しいCVEなど）でも、承認が必要になる場合があります。これらの結果はMRウィジェット内には存在しませんが、ポリシーボットのコメントとパイプラインレポートで強調表示されます。

### `policy.yml`を手動で無効にした後もポリシーが有効なまま {#policies-still-have-effect-after-policyyml-was-manually-invalidated}

GitLab 17.2以前では、`policy.yml`ファイルで定義されたポリシーが、手動で編集され、[ポリシースキーマ](#merge-request-approval-policies-schema)に対して検証されなくなった場合でも、適用されることがわかります。この問題は、ポリシーの同期ロジックのバグが原因で発生します。

考えられる症状は次のとおりです:

- `approval_settings`は、ブランチ保護の削除をブロックしたり、強制プッシュをブロックしたり、または開いているマージリクエストに影響を与えたりします。
- `any_merge_request`ポリシーは、開いているマージリクエストに引き続き適用されます。

これを解決するには、次の手順を実行します:

- 手動で`policy.yml`ファイルを編集して、ポリシーを定義し、再び有効になるようにします。
- `policy.yml`ファイルが保存されているセキュリティポリシープロジェクトの割り当てを解除して、再割り当てます。

### セキュリティスキャンの欠落 {#missing-security-scans}

マージリクエスト承認ポリシーを使用すると、新しいプロジェクトや特定のセキュリティスキャンが実行されない場合を含め、マージリクエストがブロックされる状況が発生する可能性があります。この動作は、システムへの脆弱性の侵入リスクを軽減するために設計されたものです。

シナリオ例:

- ソースブランチまたはターゲットブランチでのスキャンの欠落

  ソースブランチまたはターゲットブランチのいずれかでセキュリティスキャンが欠落している場合、GitLabはマージリクエストが新しい脆弱性を導入しているかどうかを効果的に評価できません。このような場合、予防措置として承認が必要です。

- 新規プロジェクト

  セキュリティスキャンがまだ設定されていないか、ターゲットブランチで実行されていない新しいプロジェクトの場合、すべてのマージリクエストに承認が必要です。これにより、プロジェクトの開始時からセキュリティチェックがアクティブになります。

- スキャンするファイルがないプロジェクト

  選択されたセキュリティスキャンに関連するファイルが含まれていないプロジェクトでも、承認要件は引き続き適用されます。これにより、すべてのプロジェクトで一貫したセキュリティプラクティスが維持されます。

- 最初のマージリクエスト

  新しいプロジェクトの最初のマージリクエストは、ソースブランチに脆弱性がなくても、デフォルトブランチにセキュリティスキャンがない場合にブロックされる可能性があります。

これらの問題を解決するには:

- 必要なすべてのセキュリティスキャンが設定され、ソースブランチとターゲットブランチの両方で正常に実行されていることを確認します。
- 新しいプロジェクトの場合は、マージリクエストを作成する前に、デフォルトブランチで必要なセキュリティスキャンをセットアップして実行します。
- スキャン実行ポリシーまたはパイプライン実行ポリシーを使用して、すべてのブランチでセキュリティスキャンの一貫した実行を確保することを検討してください。
- ポリシーで無効または強制不能なルールによって承認が要求されないように、[`fallback_behavior`](#fallback_behavior)と`open`の使用を検討してください。
- セキュリティスキャンのアーティファクトが欠落していて、スキャン実行ポリシーが適用されているシナリオに対処するには、[`policy tuning`](#policy_tuning)設定`unblock_rules_using_execution_policies`の使用を検討してください。この設定を有効にすると、ターゲットブランチにスキャンのアーティファクトがなく、スキャン実行ポリシーによってスキャンが要求されている場合に、承認ルールがオプションになります。この機能は、一致するスキャナーを持つ既存のスキャン実行ポリシーでのみ機能します。これにより、特定のセキュリティスキャンがアーティファクトの欠落のために実行できない場合に、マージリクエストプロセスで柔軟性が得られます。

### セキュリティボットのコメントの`Target: none` {#target-none-in-security-bot-comments}

セキュリティボットのコメントに`Target: none`が表示される場合、それはGitLabがターゲットブランチのセキュリティレポートを見つけられなかったことを意味します。これを解決するには:

1. 必要なセキュリティスキャナーを含むターゲットブランチでパイプラインを実行します。
1. パイプラインが正常に完了し、セキュリティレポートを生成することを確認します。
1. ソースブランチでパイプラインを再実行します。新しいコミットを作成すると、パイプラインが再実行されるトリガーにもなります

#### セキュリティボットメッセージ {#security-bot-messages}

ターゲットブランチにセキュリティスキャンがない場合:

- セキュリティボットは、ソースブランチで見つかったすべての脆弱性を一覧表示する場合があります。
- 一部の脆弱性はターゲットブランチに既に存在する可能性がありますが、ターゲットブランチスキャンがない場合、GitLabはどれが新しいかを判断できません。

考えられる解決策:

1. **Manual approvals**（手動承認）: セキュリティスキャンが確立されるまで、新しいプロジェクトのマージリクエストを手動で一時的に承認します。
1. **Targeted policies**（ターゲットポリシー）: 異なる承認要件を持つ新しいプロジェクト用に個別のポリシーを作成します。
1. **フォールバック行動**: 新しいプロジェクトのポリシーには`fail: open`を使用することを検討してください。ただし、スキャンが失敗した場合でも、ユーザーが脆弱性をマージできる可能性があることに注意してください。

### マージリクエストの承認ポリシーのデバッグに関するサポートリクエスト {#support-request-for-debugging-of-merge-request-approval-policy}

GitLab.comのユーザーは、「マージリクエスト承認ポリシーのデバッグ」というタイトルの[サポートチケット](https://about.gitlab.com/support/)を送信できます。次の詳細を含めます:

- グループパス、プロジェクトパス、およびオプションでマージリクエストID
- 重大度
- 現在の動作
- 期待される動作。

#### GitLab.com {#gitlabcom}

サポートチームは、失敗の`reason`を特定するために[ログ](https://log.gprd.gitlab.net/)（`pubsub-sidekiq-inf-gprd*`）を調査します。以下は、ログからの応答スニペットの例です。このクエリを使用して、承認に関連するログを検索できます。`json.event.keyword: "update_approvals"`と`json.project_path: "group-path/project-path"`。オプションで、`json.merge_request_iid`を使用して、マージリクエスト識別子でさらにフィルタリングできます:

```json
"json": {
  "project_path": "group-path/project-path",
  "merge_request_iid": 2,
  "missing_scans": [
    "api_fuzzing"
  ],
  "reason": "Scanner removed by MR",
  "event": "update_approvals",
}
```

#### GitLab Self-Managed {#gitlab-self-managed}

`project-path`、`api_fuzzing`、`merge_request`などのキーワードを検索します。例: `grep group-path/project-path`、および`grep merge_request`。相関IDがわかっている場合は、相関IDで検索できます。たとえば、`correlation_id`の値が01HWN2NFABCEDFGの場合、`01HWN2NFABCEDFG`を検索します。次のファイルを検索します:

- `/gitlab/gitlab-rails/production_json.log`
- `/gitlab/sidekiq/current`

一般的な失敗の理由:

- MRによって削除されたスキャナー: マージリクエスト承認ポリシーは、ポリシーで定義されたスキャナーが存在し、比較のためにアーティファクトが正常に生成されることを想定しています。

### マージリクエスト承認ポリシーからの承認の不整合 {#inconsistent-approvals-from-merge-request-approval-policies}

マージリクエスト承認ルールに不整合が見られる場合は、次のいずれかの手順を実行してポリシーを再同期できます:

- [`resyncSecurityPolicies` GraphQLミューテーション](_index.md#resynchronize-policies-with-the-graphql-api)を使用して、ポリシーを再同期します。
- セキュリティポリシープロジェクトの割り当てを解除してから、影響を受けるグループまたはプロジェクトに再度割り当てます。
- または、ポリシーを更新して、影響を受けるグループまたはプロジェクトに対してそのポリシーが再同期されるようにトリガーできます。
- セキュリティポリシープロジェクトのYAMLファイルの構文が有効であることを確認します。

これらの操作は、マージリクエスト承認ポリシーがすべてのマージリクエストにわたって正しく適用され、一貫性が保たれるようにするために役立ちます。

これらの手順を実行してもマージリクエスト承認ポリシーに関する問題が引き続き発生する場合は、GitLabサポートにお問い合わせください。

### 検出された脆弱性を修正するマージリクエストには承認が必要です {#merge-requests-that-fix-a-detected-vulnerability-require-approval}

ポリシーの設定に`detected`状態が含まれている場合、以前に検出された脆弱性を修正するマージリクエストには、引き続き承認が必要です。マージリクエスト承認ポリシーは、マージリクエストの変更前に存在していた脆弱性に基づいて評価されるため、既知の脆弱性に影響を与える変更に対して追加のレイヤーのレビューが追加されます。

検出された脆弱性が原因で、追加の承認なしに脆弱性を修正するマージリクエストを許可する場合は、ポリシー設定から`detected`状態の削除を検討してください。
