---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabでマージリクエスト承認ポリシーを使ってセキュリティルールを適用し、プロジェクト全体でスキャン、承認、コンプライアンスを自動化する方法を学びます。
title: マージリクエスト承認ポリシー
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- スキャン結果ポリシーのグループレベルのサポートはGitLab 15.6で[導入されました](https://gitlab.com/groups/gitlab-org/-/epics/7622)。
- スキャン結果ポリシー機能は、GitLab 16.9でマージリクエスト承認ポリシーに名称変更されました。

{{< /history >}}

> [!note]
> スキャン結果ポリシー機能は、GitLab 16.9でマージリクエスト承認ポリシーに名称変更されました。

マージリクエスト承認ポリシーは、以下の複数の目的で使用できます:

- セキュリティスキャナーとライセンススキャナーからの結果を検出し、承認ルールを適用します。たとえば、マージリクエストポリシーの一種であるセキュリティ承認ポリシーでは、1つ以上のセキュリティスキャンジョブの検出結果に基づいて承認が必要となる場合があります。マージリクエスト承認ポリシーは、CIスキャンジョブが完全に実行された後、脆弱性およびライセンスタイプポリシーの両方が、完了したパイプラインで公開されたジョブアーティファクトレポートに基づいて評価されます。
- 特定の条件を満たすすべてのマージリクエストに承認ルールを適用します。たとえば、すべてのMRがデフォルトブランチをターゲットとする場合、MRがデベロッパーとメンテナーのロールを持つ複数のユーザーによってレビューされるように強制します。
- プロジェクトのセキュリティとコンプライアンスに関する設定を適用します。たとえば、MRに変更を作成またはコミットしたユーザーがMRを承認できないようにします。または、すべての変更がMRを介して行われるように、ユーザーがデフォルトブランチにプッシュまたは強制プッシュするのを防ぎます。

> [!note]
> 保護ブランチが作成または削除されると、ポリシー承認ルールは1分の遅延で同期されます。

次のビデオでは、GitLabのマージリクエスト承認ポリシー(旧スキャン結果ポリシー)の概要を説明します:

<div class="video-fallback">
  参照用動画: <a href="https://youtu.be/w5I9gcUgr9U">GitLabスキャン結果ポリシーの概要</a>。
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/w5I9gcUgr9U" frameborder="0" allowfullscreen> </iframe>
</figure>

## 制限事項 {#restrictions}

- マージリクエスト承認ポリシーは、[保護](../../project/repository/branches/protected.md)されたターゲットブランチでのみ適用できます。
- 各ポリシーに最大5つのルールを割り当てることができます。
- 各セキュリティポリシープロジェクトに最大5つのマージリクエスト承認ポリシーを割り当てることができます。
- グループまたはサブグループ用に作成されたポリシーが、グループ内のすべてのマージリクエストに適用されるまでに時間がかかる場合があります。所要時間は、プロジェクトの数とそれらのプロジェクト内のマージリクエストの数によって決まります。通常、所要時間は数秒です。以前の観測によると、数千ものプロジェクトとマージリクエストを抱えるグループでは、このプロセスに数分かかる場合があります。
- マージリクエスト承認ポリシーは、アーティファクトレポートで生成されたスキャン結果の整合性または信頼性をチェックしません。
- マージリクエスト承認ポリシーは、そのルールに従って評価されます。デフォルトでは、ルールが無効であるか、評価できない場合、承認が必要です。この動作は[`fallback_behavior`フィールド](#fallback_behavior)で変更できます。

## パイプラインの要件 {#pipeline-requirements}

マージリクエスト承認ポリシーは、パイプラインの結果に従って適用されます。マージリクエスト承認ポリシーを実装する際には、次の点を考慮してください:

- マージリクエスト承認ポリシーは、完了したパイプラインジョブを評価し、手動ジョブは無視します。手動ジョブが実行されると、ポリシーはマージリクエストのジョブを再評価します。
- セキュリティスキャナーの結果を評価するマージリクエスト承認ポリシーの場合、指定されたすべてのスキャナーがセキュリティレポートを出力している必要があります。そうでない場合、脆弱性が導入されるリスクを最小限に抑えるために承認が強制されます。この動作は、次の状況に影響を与える可能性があります:
  - セキュリティスキャンがまだ確立されていない新規プロジェクト。
  - セキュリティスキャンが設定される前に作成されたブランチ。
  - ブランチ間でスキャナーの設定が一貫していないプロジェクト。
- パイプラインは、有効なすべてのスキャナーについて、ソースブランチとターゲットブランチの両方のアーティファクトを生成する必要があります。そうでない場合、比較の根拠がないため、ポリシーを確実に評価できません。詳細については、「[不足しているセキュリティスキャン](#missing-security-scans)」を参照してください。この要件を強制するには、スキャン実行ポリシーを使用する必要があります。
- ポリシーの評価は、成功して完了したマージベースパイプラインに依存します。マージベースパイプラインがスキップされると、マージベースパイプラインを含むマージリクエストはブロックされます。
- ポリシーで指定されたセキュリティスキャナーは、ポリシーが適用されるプロジェクトで設定され、有効になっている必要があります。そうでない場合、マージリクエスト承認ポリシーは評価できず、対応する承認が必要になります。

## セキュリティスキャナーをマージリクエスト承認ポリシーとともに使用するためのベストプラクティス {#best-practices-for-using-security-scanners-with-merge-request-approval-policies}

新しいプロジェクトを作成する際に、マージリクエスト承認ポリシーとセキュリティスキャンの両方をそのプロジェクトに適用できます。ただし、誤って設定されたセキュリティスキャナーは、マージリクエスト承認ポリシーに影響を与える可能性があります。

新しいプロジェクトでセキュリティスキャンを設定するには、複数の方法があります:

- プロジェクトのCI/CD設定で、最初の`.gitlab-ci.yml`設定ファイルにスキャナーを追加します。
- 特定のセキュリティスキャナーがパイプラインを実行するように強制するスキャン実行ポリシーで。
- パイプライン実行ポリシーで、どのジョブがパイプラインで実行されるかを制御します。

単純なユースケースの場合は、プロジェクトのCI/CD設定を使用できます。包括的なセキュリティ戦略の場合は、マージリクエスト承認ポリシーを他のポリシータイプと組み合わせることを検討してください。

不要な承認要件を最小限に抑えるとともに、正確なセキュリティ評価を確実に行うために:

- **Run security scans on your default branch first**: フィーチャーブランチを作成する前に、デフォルトブランチでセキュリティスキャンが正常に実行されていることを確認してください。
- **Use consistent scanner configuration**: ソースブランチとターゲットブランチの両方で同じスキャナーを実行し、できれば単一のパイプラインで実行してください。
- **Verify that scans produce artifacts**: スキャンが正常に完了し、比較用のアーティファクトを生成することを確認してください。
- **Keep branches synchronized**: デフォルトブランチからの変更を定期的にフィーチャーブランチにマージします。
- **Consider pipeline configurations**: 新規プロジェクトの場合、最初の`.gitlab-ci.yml`設定にセキュリティスキャナーを含めます。

### マージリクエスト承認ポリシーを適用する前にセキュリティスキャナーを検証する {#verify-security-scanners-before-you-apply-merge-request-approval-policies}

新しいプロジェクトでセキュリティスキャンを実装してからマージリクエスト承認ポリシーを適用することで、マージリクエスト承認ポリシーに依存する前にセキュリティスキャナーが一貫して実行されることを確実にし、セキュリティスキャンの不足によりマージリクエストがブロックされる状況を回避できます。

セキュリティスキャナーとマージリクエスト承認ポリシーをまとめて作成および検証するには、この推奨されるワークフローを使用してください:

1. プロジェクトを作成します。
1. `.gitlab-ci.yml`設定、スキャン実行ポリシー、またはパイプライン実行ポリシーを使用してセキュリティスキャナーを設定します。
1. デフォルトブランチで最初のパイプラインが完了するのを待ちます。問題を解決し、パイプラインを再実行して、続行する前に正常に完了することを確認します。
1. 同じセキュリティスキャナーが設定されたフィーチャーブランチを使用してマージリクエストを作成します。ここでも、セキュリティスキャナーが正常に完了することを確認してください。
1. マージリクエスト承認ポリシーを適用します。

## 複数のパイプラインを含むマージリクエスト {#merge-request-with-multiple-pipelines}

{{< history >}}

- GitLab 16.2で`multi_pipeline_scan_result_policies`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/379108)されました。デフォルトでは無効になっています。
- GitLab 16.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/409482)。機能フラグ`multi_pipeline_scan_result_policies`は削除されました。
- 親子パイプラインのサポートは、GitLab 16.11で`approval_policy_parent_child_pipeline`という名前の[フラグ](../../../administration/feature_flags/_index.md)とともに[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/428591)。デフォルトでは無効になっています。
- GitLab 17.0で[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/451597)。
- GitLab 17.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/428591)になりました。機能フラグ`approval_policy_parent_child_pipeline`は削除されました。

{{< /history >}}

1つのプロジェクトで複数のパイプラインタイプを設定できます。単一のコミットで複数のパイプラインが開始される可能性があり、それぞれがセキュリティスキャンを含む場合があります。

- GitLab 16.3以降では、マージリクエストのソースブランチとターゲットブランチにおける最新のコミットの完了したすべてのパイプラインの結果が評価され、マージリクエスト承認ポリシーの適用に使用されます。オンデマンドDASTパイプラインは考慮されません。
- GitLab 16.2以前では、マージリクエスト承認ポリシーを適用する際に、最新の完了したパイプラインの結果のみが評価されていました。

プロジェクトで[マージリクエストパイプライン](../../../ci/pipelines/merge_request_pipelines.md)を使用している場合は、セキュリティスキャンジョブがパイプラインに存在するように、CI/CD変数`AST_ENABLE_MR_PIPELINES`を`"true"`に設定する必要があります。詳細については、「[セキュリティスキャンツールをマージリクエストパイプラインで使用する](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)」を参照してください。

最新のコミットで多数のパイプラインが実行されたプロジェクト（休止中のプロジェクトなど）の場合、ポリシー評価では、マージリクエストのソースブランチとターゲットブランチの両方から最大1,000個のパイプラインが考慮されます。

親子パイプラインの場合、ポリシー評価では最大1,000個の子パイプラインが考慮されます。

## マージリクエスト承認ポリシーエディタ {#merge-request-approval-policy-editor}

> [!note]
> プロジェクトのオーナーのみが、[権限](../../permissions.md#project-permissions)を持ってセキュリティポリシープロジェクトを選択できます。

ポリシーが完了したら、エディタの下部にある**マージリクエスト経由で設定**を選択して保存します。これにより、プロジェクトの設定されたセキュリティポリシープロジェクトのマージリクエストにリダイレクトされます。セキュリティポリシープロジェクトが自分のプロジェクトにリンクしていない場合、GitLabがそのようなプロジェクトを作成します。既存のポリシーも、エディタの下部にある**ポリシーの削除**を選択することで、エディタインターフェースから削除できます。

ほとんどのポリシー変更は、マージリクエストがマージされるとすぐに有効になります。マージリクエストを介さずにデフォルトブランチに直接コミットされた変更は、ポリシー変更が有効になるまでに最大10分かかる場合があります。

[ポリシーエディタ](_index.md#policy-editor)はYAMLモードとルールモードをサポートしています。

> [!note]
> 多数のプロジェクトを持つグループ用に作成されたマージリクエスト承認ポリシーの伝播には、完了までに時間がかかります。

## マージリクエスト承認ポリシースキーマ {#merge-request-approval-policies-schema}

マージリクエスト承認ポリシーを含むYAMLファイルは、マージリクエスト承認ポリシースキーマに一致する配列のオブジェクトが`approval_policy`キーの下にネストされた構成になっています。`approval_policy`キーの下に最大5つのポリシーを設定できます。

> [!note]
> マージリクエスト承認ポリシーは、`scan_result_policy`キーの下で定義されていました。GitLab 17.0までは、ポリシーは両方のキーの下で定義できます。GitLab 17.0からは、`approval_policy`キーのみがサポートされます。

新しいポリシーを保存すると、GitLabは[このJSONスキーマ](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json)に照らしてその内容を検証します。[JSONスキーマ](https://json-schema.org/)に精通していない方は、以下のセクションと表を参照してください。

| フィールド             | タイプ                                     | 必須 | 説明                                          |
|-------------------|------------------------------------------|----------|------------------------------------------------------|
| `approval_policy` | マージリクエスト承認ポリシーオブジェクトの`array` | true     | マージリクエスト承認ポリシーのリスト（最大5つ）。 |

## マージリクエスト承認ポリシースキーマ {#merge-request-approval-policy-schema}

{{< history >}}

- `enforcement_type`フィールド:
  - GitLab 18.4で`security_policy_approval_warn_mode`という名前の[フラグ](../../../administration/feature_flags/_index.md)とともに[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202746)。
  - GitLab 18.6で[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/505352)。機能フラグ`security_policy_approval_warn_mode`は削除されました。
  - GitLab 18.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221747)になりました。機能フラグ`security_policy_approval_warn_mode`は削除されました。

{{< /history >}}

| フィールド               | タイプ               | 必須 | 使用可能な値 | 説明                                              |
|---------------------|--------------------|----------|-----------------|----------------------------------------------------------|
| `name`              | `string`           | true     |                 | ポリシーの名前。最大255文字。           |
| `description`       | `string`           | false    |                 | ポリシーの説明。                               |
| `enabled`           | `boolean`          | true     | `true`、`false` | ポリシーを有効（`true`）または無効（`false`）にするフラグ。 |
| `rules`             | ルールの`array`   | true     |                 | ポリシーが適用するルールのリスト。                   |
| `actions`           | アクションの`array` | false    |                 | ポリシーが適用するアクションのリスト。                |
| `approval_settings` | `object`           | false    |                 | ポリシーがオーバーライドするプロジェクト設定。              |
| `fallback_behavior` | `object`           | false    |                 | 無効または強制できないルールに影響する設定。     |
| `policy_scope`      | [`policy_scope`](_index.md#configure-the-policy-scope)の`object` | false |  | 指定するプロジェクト、グループ、またはコンプライアンスフレームワークラベルに基づいて、ポリシーのスコープを定義します。 |
| `policy_tuning`     | `object`           | false    |                 | (実験的)ポリシー比較ロジックに影響する設定。     |
| `bypass_settings`   | `object`           | false    |                 | 特定のブランチ、トークン、またはアカウントがポリシーをバイパスすることができる時期に影響する設定。     |
| `enforcement_type`  | `string`           | false    | `enforce`、`warn` | ポリシーがどのように適用されるかを定義します。デフォルト値（指定しない場合）は`enforce`で、違反が検出された場合にマージリクエストをブロックします。`warn`値は、マージリクエストの続行を許可しますが、警告とボットコメントを表示します。 |

## `scan_finding`ルールタイプ {#scan_finding-rule-type}

{{< history >}}

- マージリクエスト承認ポリシーフィールド`vulnerability_attributes`:
  - GitLab 16.2で`enforce_vulnerability_attributes_rules`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123052)されました。
  - GitLab 16.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/418784)。機能フラグが削除されました。
- マージリクエスト承認ポリシーフィールド`vulnerability_age`は、GitLab 16.2で[追加されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123956)。
- `branch_exceptions`フィールド:
  - GitLab 16.3で`security_policies_branch_exceptions`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418741)されました。
  - GitLab 16.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753)になりました。機能フラグが削除されました。
- `vulnerability_states`オプション`newly_detected`はGitLab 17.0で[削除され](https://gitlab.com/gitlab-org/gitlab/-/issues/422414)、その代わりにオプション`new_needs_triage`と`new_dismissed`が追加されました。

{{< /history >}}

このルールは、セキュリティスキャンの検出結果に基づいて定義されたアクションを強制します。

| フィールド                      | タイプ                | 必須                                   | 使用可能な値                                                                                                    | 説明 |
|----------------------------|---------------------|--------------------------------------------|--------------------------------------------------------------------------------------------------------------------|-------------|
| `type`                     | `string`            | true                                       | `scan_finding`                                                                                                     | ルールのタイプ。 |
| `branches`                 | `array`の`string` | `branch_type`フィールドが存在しない場合はtrue | `[]`またはブランチの名前                                                                                          | 保護ブランチであるターゲットブランチにのみ適用されます。空の配列`[]`は、すべての保護ブランチであるターゲットブランチにルールを適用します。`branch_type`フィールドとは一緒に使用できません。 |
| `branch_type`              | `string`            | `branches`フィールドが存在しない場合はtrue    | `default`または`protected`                                                                                           | 所定のポリシーが適用される保護ブランチのタイプ。`branches`フィールドとは一緒に使用できません。デフォルトブランチも`protected`である必要があります。 |
| `branch_exceptions`        | `array`の`string` | false                                      | ブランチの名前                                                                                                  | このルールから除外するターゲットブランチ。 |
| `scanners`                 | `string`または[`scanner_with_attributes`](#scanner_with_attributes-object)オブジェクトの`array` | true | `[]`または`sast`、`secret_detection`、`dependency_scanning`、`container_scanning`、`dast`、`coverage_fuzzing`、`api_fuzzing` | このルールが考慮するセキュリティスキャナー。`sast`には、SASTとSASTIaCスキャナーの両方の結果が含まれます。空の配列`[]`は、すべてのセキュリティスキャナーにルールを適用します。スキャナーは、文字列（ルールレベルの設定を適用する場合）またはオブジェクト（`severity_levels`、`vulnerabilities_allowed`、および`vulnerability_attributes`のスキャナーごとのオーバーライドを含む場合）として指定します。 |
| `vulnerabilities_allowed`  | `integer`           | true                                       | 0以上                                                                                      | このルールが考慮されるまでに許可される脆弱性の数。 |
| `severity_levels`          | `array`の`string` | true                                       | `info`、`unknown`、`low`、`medium`、`high`、`critical`                                                             | このルールが考慮する重大度レベル。 |
| `vulnerability_states`     | `array`の`string` | true                                       | `[]`または`detected`、`confirmed`、`resolved`、`dismissed`、`new_needs_triage`、`new_dismissed`                      | すべての脆弱性は2つのカテゴリに分類されます:<br><br>**Newly Detected Vulnerabilities** \- マージリクエストブランチ自体で識別されたが、現在のMRのターゲットブランチには存在しない脆弱性。このポリシーオプションでは、脆弱性が新しく検出されたものかどうかを判断できるように、ルールが評価される前にパイプラインが完了している必要があります。マージリクエストは、パイプラインと必要なセキュリティスキャンが完了するまでブロックされます。`new_needs_triage`オプションはステータスを考慮します。<br><br> • 検出済み<br><br> `new_dismissed`オプションはステータスを考慮します。<br><br> • 無視済み<br><br>**Pre-Existing Vulnerabilities** \- これらのポリシーオプションは、デフォルトブランチで以前に検出された脆弱性のみを考慮するため、すぐに評価され、パイプラインの完了は必要ありません。<br><br> • `Detected` - ポリシーは、検出された状態の脆弱性を検索します。<br> • `Confirmed` - ポリシーは、確認された状態の脆弱性を検索します。<br> • `Dismissed` - ポリシーは、無視された状態の脆弱性を検索します。<br> • `Resolved` - ポリシーは、解決された状態の脆弱性を検索します。<br><br>空の配列`[]`は、`['new_needs_triage', 'new_dismissed']`と同じステータスをカバーします。 |
| `vulnerability_attributes` | `object`            | false                                      | [`vulnerability_attributes`](#vulnerability_attributes-object)オブジェクト | すべての脆弱性の検出結果は、デフォルトで考慮されます。特定の基準に一致する脆弱性の検出結果のみを考慮するには、これらのフィルターを適用します。詳細については、[`vulnerability_attributes`](#vulnerability_attributes-object)オブジェクトを参照してください。 |
| `vulnerability_age`        | `object`            | false                                      | N/A                                                                                                                | 既存の脆弱性の検出結果を期間でフィルターします。脆弱性の期間は、プロジェクトで検出されてからの時間として計算されます。基準は`operator`、`value`、および`interval`です。<br>- `operator`基準は、使用される期間の比較がより古い（`greater_than`）かより新しい（`less_than`）かを指定します。<br>- `value`基準は、脆弱性の期間を表す数値です。<br>- `interval`基準は、脆弱性の期間の測定単位（`day`、`week`、`month`、または`year`）を指定します。<br><br>例：`operator: greater_than`、`value: 30`、`interval: day`。 |

### `vulnerability_attributes`オブジェクト {#vulnerability_attributes-object}

{{< history >}}

- `known_exploited`、`epss_score`、および`enrichment_data_unavailable`フィールドは、GitLab 18.11で`security_policies_kev_filter`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/576860)。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

| フィールド                        | タイプ                 | 必須 | 使用可能な値                                              | 説明 |
|------------------------------|----------------------|----------|--------------------------------------------------------------|-------------|
| `false_positive`             | `boolean`            | false    | `true`、`false`                                              | 誤検出ステータスでフィルターします。`true`は誤検出のみを含み、`false`はそれらを除外します。 |
| `fix_available`              | `boolean`            | false    | `true`、`false`                                              | 修正の可用性でフィルターします。`true`は修正が利用可能な脆弱性のみを含み、`false`は利用不可能な脆弱性のみを含みます。 |
| `known_exploited`            | `boolean` | false    | `true`、`false`                               | [CISA既知の悪用された脆弱性（KEV）](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)カタログに基づいてフィルターします。trueの場合、実際に悪用されている脆弱性のみが含まれます。falseの場合、既知の悪用状況に基づいて脆弱性をフィルターしません。 |
| `epss_score`                 | `object` | false    | `{operator, value}`オブジェクト                    | [EPSS（Exploit Prediction Scoring System）](https://www.first.org/epss/)スコアに基づいてフィルターします。EPSSは、脆弱性が悪用される確率（0〜1）を推定します。オブジェクトとして：`operator`は`greater_than`、または`less_than`にすることができます。`value`は`0.0`から`1.0`までの数値です。例: `{operator: greater_than, value: 0.8}`。  |
| `enrichment_data_unavailable`| `object`             | false    | `{action: "block"}`または`{action: "ignore"}`                  | 補強データが利用できない（EPSSスコアまたは既知の悪用ステータスが欠落している）CVE脆弱性の処理方法を定義します。「ブロック」の場合、補強データがない脆弱性は、ルールレベルの基準に従って評価されます。「ignore」の場合、補強データがない脆弱性は、ポリシー評価から除外されます。 |

### `scanner_with_attributes`オブジェクト {#scanner_with_attributes-object}

{{< history >}}

- GitLab 18.10で`atomic_scanner_rule_criteria`という名前の[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/584704)されました。デフォルトでは有効になっています。GitLab 18.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230346)。機能フラグが削除されました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

スキャナーが文字列ではなくオブジェクトとして指定されている場合、各スキャナータイプは独自の基準で個別に評価されます。スキャナーレベルで指定されていないフィールドはすべて、ルールレベルの値で定義された設定にフォールバックします。

| フィールド                      | タイプ                | 必須 | 使用可能な値                                                                   | 説明 |
|----------------------------|---------------------|----------|-----------------------------------------------------------------------------------|-------------|
| `type`                     | `string`            | true     | `sast`、`secret_detection`、`dependency_scanning`、`container_scanning`、`dast`、`coverage_fuzzing`、`api_fuzzing` | スキャナーのタイプ。 |
| `severity_levels`          | `array`の`string` | false    | `info`、`unknown`、`low`、`medium`、`high`、`critical`                            | このスキャナーのルールレベルの`severity_levels`をオーバーライドします。 |
| `vulnerabilities_allowed`  | `integer`           | false    | 0以上                                                     | このスキャナーのルールレベルの`vulnerabilities_allowed`をオーバーライドします。 |
| `vulnerability_attributes` | `object`            | false    | [`vulnerability_attributes`](#vulnerability_attributes-object)オブジェクト              | このスキャナーのルールレベルの`vulnerability_attributes`をオーバーライドします。 |

スキャナーごとの基準を使用した例:

```yaml
rules:
  - type: scan_finding
    branches: []
    scanners:
      - type: dependency_scanning
        vulnerability_attributes:
          fix_available: true
        vulnerabilities_allowed: 0
        severity_levels:
          - critical
          - high
      - type: container_scanning
        vulnerability_attributes:
          known_exploited: true
          epss_score:
             value: 0.5
             operator: greater_than
          enrichment_data_unavailable:
             action: block
        vulnerabilities_allowed: 0
        severity_levels:
          - critical
    vulnerabilities_allowed: 5
    severity_levels:
      - critical
      - high
      - medium
    vulnerability_states:
      - new_needs_triage
```

この例では: 

- **依存関係スキャン**は、修正が利用可能な重大または高重大度の脆弱性が検出された場合に承認を必要とします。
- **コンテナのスキャン**は、重大かつ既知の悪用された脆弱性が検出された場合に承認を必要とします。
- 各スキャナーは、独自のしきい値に対して個別に評価されます。ルールレベルの`vulnerabilities_allowed: 5`と`severity_levels`は、明示的なオーバーライドがないスキャナーのデフォルトとして機能します。

## `license_finding`ルールタイプ {#license_finding-rule-type}

{{< history >}}

- GitLab 15.9で`license_scanning_policies`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/8092)されました。
- GitLab 15.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/397644)になりました。機能フラグ`license_scanning_policies`は削除されました。
- `branch_exceptions`フィールドは、GitLab 16.3で`security_policies_branch_exceptions`という名前の[フラグ](../../../administration/feature_flags/_index.md)とともに[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/418741)。デフォルトでは有効になっています。GitLab 16.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753)になりました。機能フラグが削除されました。
- `licenses`フィールドは、GitLab 17.11で`exclude_license_packages`という名前の[フラグ](../../../administration/feature_flags/_index.md)とともに[導入されました](https://gitlab.com/groups/gitlab-org/-/epics/10203)。機能フラグが削除されました。

{{< /history >}}

このルールは、ライセンスの検出結果に基づいて定義されたアクションを強制します。

| フィールド          | タイプ     | 必須                                      | 使用可能な値              | 説明                                                                                                                                                                                                         |
|----------------|----------|-----------------------------------------------|------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `type`         | `string` | true                                          | `license_finding`            | ルールのタイプ。                                                                                                                                                                                                    |
| `branches`     | `array`の`string` | `branch_type`フィールドが存在しない場合はtrue    | `[]`またはブランチの名前    | 保護ブランチであるターゲットブランチにのみ適用されます。空の配列`[]`は、すべての保護ブランチであるターゲットブランチにルールを適用します。`branch_type`フィールドとは一緒に使用できません。                                                 |
| `branch_type`  | `string` | `branches`フィールドが存在しない場合はtrue       | `default`または`protected`     | 所定のポリシーが適用される保護ブランチのタイプ。`branches`フィールドとは一緒に使用できません。デフォルトブランチも`protected`である必要があります。                                                                   |
| `branch_exceptions` | `array`の`string` | false                                         | ブランチの名前            | このルールから除外するターゲットブランチ。                                                                                                                                                                                 |
| `match_on_inclusion_license` | `boolean` | `licenses`フィールドが存在しない場合はtrue      | `true`、`false`              | ルールが`license_types`にリストされているライセンスの包含または除外と一致するかどうか。                                                                                                                              |
| `license_types` | `array`の`string` | `licenses`フィールドが存在しない場合はtrue      | ライセンスタイプ                | マッチさせる[SPDXライセンス名](https://spdx.org/licenses)。`Affero General Public License v1.0`や`MIT License`など。                                                                                     |
| `license_states` | `array`の`string` | true                                          | `newly_detected`、`detected` | 新しく検出されたライセンスおよび/または以前に検出されたライセンスと一致させるかどうか。`newly_detected`ステートは、新しいパッケージが導入された場合、または既存のパッケージに新しいライセンスが検出された場合に承認をトリガーします。 |
| `licenses`     | `object` | `license_types`フィールドが存在しない場合はtrue | `licenses`オブジェクト            | [SPDXライセンス名](https://spdx.org/licenses)をパッケージの例外を含めて照合します。                                                                                                                        |

### `licenses`オブジェクト {#licenses-object}

| フィールド     | タイプ     | 必須                                | 使用可能な値                                      | 説明                                                |
|-----------|----------|-----------------------------------------|------------------------------------------------------|------------------------------------------------------------|
| `denied`  | `object` | `allowed`フィールドが存在しない場合はtrue | `licenses_with_package_exclusion`オブジェクトの`array`  | パッケージの例外を含む拒否されたライセンスのリスト。  |
| `allowed` | `object` | `denied`フィールドが存在しない場合はtrue  | `licenses_with_package_exclusion`オブジェクトの`array`  | パッケージの例外を含む許可されたライセンスのリスト。 |

### `licenses_with_package_exclusion`オブジェクト {#licenses_with_package_exclusion-object}

`licenses_with_package_exclusion`オブジェクトを使用して、ライセンス名とオプションのパッケージ除外を定義します。

| フィールド  | タイプ     | 必須 | 使用可能な値   | 説明                                        |
|--------|----------|----------|-------------------|----------------------------------------------------|
| `name` | `string` | true     | SPDXライセンス名 | [SPDXライセンス名](https://spdx.org/licenses)。    |
| `packages` | `object` | false    | `packages`オブジェクト | 指定されたライセンスに対するパッケージの例外リスト。 |

> [!note]
> `name`フィールドは有効な[SPDXライセンス名](https://spdx.org/licenses)である必要があります。値`unknown`は認識されているSPDXライセンス名ではなく、`licenses`フィールドではサポートされていません。`unknown`ライセンス用に構成されたパッケージレベルの除外は、マージリクエスト承認の評価中に無視されます。`unknown`ライセンスを持つパッケージを管理するには、[`license_types`](#license_finding-rule-type)フィールドを使用するか、`unknown`をポリシーのライセンスとして許可してください。詳細については、[ライセンス承認ポリシーは`unknown`ライセンスが原因でマージリクエストをブロックする](../../compliance/license_approval_policies.md#license-approval-policies-block-merge-requests-due-to-unknown-licenses)を参照してください。

### `packages`オブジェクト {#packages-object}

`packages`オブジェクトを使用して、ライセンスエントリのパッケージURL除外を定義します。

| フィールド  | タイプ     | 必須 | 使用可能な値                                       | 説明                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|--------|----------|----------|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `excluding` | `object` | true     | {purls: `uri`形式を使用する`array`の`strings`} | 指定されたライセンスのパッケージ例外のリスト。[`purl`](https://github.com/package-url/purl-spec?tab=readme-ov-file#purl)コンポーネント`scheme:type/name@version`を使用して、パッケージ例外のリストを定義します。`scheme:type/name`コンポーネントは必須です。`@`と`version`はオプションです。特定のバージョンが指定されている場合、そのバージョンのみが例外と見なされます。バージョンが指定されておらず、`@`文字が`purl`の末尾に追加されている場合、正確な名前を持つパッケージのみが一致と見なされます。`@`文字がパッケージ名に追加されていない場合、指定されたライセンスの同じプレフィックスを持つすべてのパッケージが一致します。たとえば、purl `pkg:gem/bundler`は、`bundler`および`bundler-stats`のパッケージが両方とも同じライセンスを使用しているため、これらに一致します。`purl` `pkg:gem/bundler@`を定義すると、`bundler`パッケージのみが一致します。 |

## `any_merge_request`ルールタイプ {#any_merge_request-rule-type}

{{< history >}}

- `branch_exceptions`フィールドは、GitLab 16.3で`security_policies_branch_exceptions`という名前の[フラグ](../../../administration/feature_flags/_index.md)とともに[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/418741)。デフォルトでは有効になっています。GitLab 16.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753)になりました。機能フラグが削除されました。
- `any_merge_request`ルールタイプは、GitLab 16.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/418752)。デフォルトでは有効になっています。GitLab 16.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136298)になりました。機能フラグは[削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/432127)。

{{< /history >}}

このルールは、コミット署名に基づいて、任意のマージリクエストに定義されたアクションを強制します。

| フィールド               | タイプ                | 必須                                   | 使用可能な値           | 説明 |
|---------------------|---------------------|--------------------------------------------|---------------------------|-------------|
| `type`              | `string`            | true                                       | `any_merge_request`       | ルールのタイプ。 |
| `branches`          | `array`の`string` | `branch_type`フィールドが存在しない場合はtrue | `[]`またはブランチの名前 | 保護ブランチであるターゲットブランチにのみ適用されます。空の配列`[]`は、すべての保護ブランチであるターゲットブランチにルールを適用します。`branch_type`フィールドとは一緒に使用できません。 |
| `branch_type`       | `string`            | `branches`フィールドが存在しない場合はtrue    | `default`または`protected`  | 所定のポリシーが適用される保護ブランチのタイプ。`branches`フィールドとは一緒に使用できません。デフォルトブランチも`protected`である必要があります。 |
| `branch_exceptions` | `array`の`string` | false                                      | ブランチの名前         | このルールから除外するターゲットブランチ。 |
| `commits`           | `string`            | true                                       | `any`、`unsigned`         | ルールがすべてのコミットに一致するか、またはマージリクエストで署名なしコミットが検出された場合にのみ一致するかどうか。 |

## `require_approval`アクションタイプ {#require_approval-action-type}

{{< history >}}

- 最大5つの個別の`require_approval`アクションを指定するためのサポート:
  - GitLab 17.7で[追加され](https://gitlab.com/groups/gitlab-org/-/epics/12319)、`multiple_approval_actions`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)が設定されました。
  - GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/505374)になりました。機能フラグ`multiple_approval_actions`は削除されました。
- `role_approvers`としてカスタムロールを指定するためのサポート:
  - GitLab 17.9で`security_policy_custom_roles`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/13550)されました。デフォルトでは有効になっています。
  - GitLab 17.10で、[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/505742)になりました。機能フラグ`security_policy_custom_roles`は削除されました。

{{< /history >}}

このアクションは、定義されたポリシー内の少なくとも1つのルールが条件を満たした場合に、承認ルールを必須にします。

同じ`require_approval`ブロックで複数の承認者を指定した場合、対象となる任意の承認者が承認要件を満たすことができます。たとえば、2つの`group_approvers`と`approvals_required`を`2`として指定した場合、両方の承認が同じグループから得られます。ユニークな承認者タイプからの複数の承認を要求するには、複数の`require_approval`アクションを使用します。

| フィールド | タイプ | 必須 | 使用可能な値 | 説明 |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | true | `require_approval` | アクションのタイプ。 |
| `approvals_required` | `integer` | true | 0以上 | 必要なマージリクエスト承認の数。 |
| `user_approvers` | `array`の`string` | 条件付き | 1人以上のユーザー名 | 承認者として考慮するユーザー。ユーザーは、承認の対象となるために、プロジェクトへのアクセス権を持っている必要があります。 |
| `user_approvers_ids` | `array`の`integer` | 条件付き<sup>1</sup> | 1人以上のユーザーのID | 承認者として考慮するユーザーのID。ユーザーは、承認の対象となるために、プロジェクトへのアクセス権を持っている必要があります。 |
| `group_approvers` | `array`の`string` | 条件付き<sup>1</sup> | 1つ以上のグループのパス | 承認者として考慮するグループ。[グループの直接メンバーシップ](../../project/merge_requests/approvals/rules.md#group-approvers)を持つユーザーが、承認の対象となります。 |
| `group_approvers_ids` | `array`の`integer` | 条件付き<sup>1</sup> | 1つ以上のグループのID | 承認者として考慮するグループのID。[グループの直接メンバーシップ](../../project/merge_requests/approvals/rules.md#group-approvers)を持つユーザーが、承認の対象となります。 |
| `role_approvers` | `array`の`string` | 条件付き<sup>1</sup> | 1つ以上の[ロール](../../permissions.md#roles)（例: `owner`オーナー、`maintainer`メンテナー）。カスタムロールにマージリクエストを承認する権限がある場合、`role_approvers`としてカスタムロール（またはYAMLモードでカスタムロール識別子）を指定することもできます。カスタムロールは、ユーザーおよびグループの承認者とともに選択できます。 | 承認の対象となるロール。指定した正確なロールを持つユーザーのみが承認できます。より高い権限を持つロールは自動的に含まれません。たとえば、`developer`を選択した場合、デベロッパーロールを持つユーザーのみが承認できます。メンテナーとオーナーは、追加しない限り承認できません。 |

**補足説明:**

1. 承認者フィールド（`user_approvers`、`user_approvers_ids`、`group_approvers`、`group_approvers_ids`、または`role_approvers`）を使用して、少なくとも1人の承認者を指定する必要があります。

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

**Valid with multiple approver types:**

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

**Invalid because no approvers specified:**

```yaml
actions:
  - type: require_approval
    approvals_required: 2
    # ERROR: At least one approver field must be specified
    # This configuration will fail validation
```

## `send_bot_message`アクションタイプ {#send_bot_message-action-type}

{{< history >}}

- プロジェクトの`send_bot_message`アクションタイプ:
  - GitLab 16.11で`approval_policy_disable_bot_comment`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438269)されました。デフォルトでは無効になっています。
  - GitLab 17.0で[GitLab Self-Managed、およびGitLab Dedicatedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/454852)。
  - GitLab 17.3で[一般公開](https://gitlab.com/gitlab-org/gitlab/-/issues/454852)になりました。機能フラグ`approval_policy_disable_bot_comment`は削除されました。
- グループの`send_bot_message`アクションタイプ:
  - GitLab 17.2で`approval_policy_disable_bot_comment_group`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/469449)されました。デフォルトでは無効になっています。
  - GitLab 17.2の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/469449)になりました。
  - GitLab 17.3で[一般公開](https://gitlab.com/gitlab-org/gitlab/-/issues/469449)になりました。機能フラグ`approval_policy_disable_bot_comment_group`は削除されました。

{{< /history >}}

このアクションは、ポリシー違反が検出された場合に、マージリクエストのボットメッセージの設定を有効にします。アクションが指定されていない場合、ボットメッセージはデフォルトで有効になります。複数のポリシーが定義されている場合、それらのポリシーの少なくとも1つで`send_bot_message`アクションが有効になっている限り、ボットメッセージが送信されます。

| フィールド | タイプ | 必須 | 使用可能な値 | 説明 |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | true | `send_bot_message` | アクションのタイプ。 |
| `enabled` | `boolean` | true | `true`、`false` | ボットメッセージがポリシー違反検出時に作成されるべきかどうか。デフォルトは`true`です。 |

### ボットメッセージの例 {#example-bot-messages}

![セキュリティスキャンによって検出された脆弱性を示すボットメッセージの例。](img/scan_result_policy_example_bot_message_vulnerabilities_v17_0.png)

![ポリシー評価に必要な、不足または不完全なスキャンアーティファクトを示すボットメッセージの例。](img/scan_result_policy_example_bot_message_artifacts_v17_0.png)

## 警告モード {#warn-mode}

{{< history >}}

- GitLab 17.8で[導入され](https://gitlab.com/groups/gitlab-org/-/epics/15552)、`security_policy_approval_warn_mode`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)が設定されました。デフォルトで無効
- GitLab 18.6の[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/505352)になりました。
- ライセンススキャンのサポート:
  - GitLab 18.7で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/579664)、`security_policy_warn_mode_license_scanning`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)が設定されました。デフォルトでは有効になっています。
  - GitLab 18.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221747)になりました。機能フラグ`security_policy_approval_warn_mode`は削除されました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

警告モードを使用すると、セキュリティチームは、完全に強制する前にセキュリティポリシーの影響をテストおよび検証し、新しいセキュリティポリシーを適用する際のデベロッパーの負担を軽減できます。`enforcement_type: warn`でポリシーが設定されている場合、マージリクエストは、マージリクエスト承認ポリシー違反をバイパスするオプションを提供します。

警告モードが有効（`enforcement_type: warn`）で、マージリクエストがセキュリティポリシー違反をトリガーすると、ポリシーの適用はいくつかの点で異なります:

- 非ブロック型検証: このポリシーは、ポリシー違反をリストする情報提供ボットコメントを生成します。
- オプションの承認: ユーザーがポリシーをバイパスするために無視する理由を提供した場合、承認はオプションです。
- 強化された監査: バイパスされたセキュリティポリシーと共にマージリクエストがマージされた後、監査イベントが作成されます。
- 脆弱性レポートインテグレーション: バイパスされたポリシーを持つマージリクエストによって脆弱性が導入された場合、バイパスするの詳細は脆弱性レポートで確認できます。
- 依存関係リストインテグレーション: ポリシーをバイパスするマージリクエストがライセンスを導入した場合、依存関係リストはライセンスの横にポリシー違反バッジを表示します。ポリシー違反バッジは、プロジェクトの依存関係リストでのみ利用可能です。
- 無効な承認設定: 承認設定のオーバーライドは強制されません。

### 警告モードの設定 {#configuring-warn-mode}

マージリクエスト承認ポリシーの警告モードを有効にするには、`enforcement_type`フィールドを`warn`に設定します:

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

## `approval_settings` {#approval_settings}

{{< history >}}

- `block_group_branch_modification`フィールド:
  - GitLab 16.8で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/420724)、`scan_result_policy_block_group_branch_modification`という名前の[フラグ](../../../administration/feature_flags/_index.md)が設定されました。
  - GitLab 17.6で[GitLab.comとGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/437306)。
  - GitLab 17.7で[一般公開されました](https://gitlab.com/gitlab-org/gitlab/-/issues/503930)。機能フラグ`scan_result_policy_block_group_branch_modification`は削除されました。
- `block_unprotecting_branches`フィールド
  - GitLab 16.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/423101)、`scan_result_policy_settings`という名前の[フラグ](../../../administration/feature_flags/_index.md)が設定されました。デフォルトでは無効になっています。
  - GitLab 16.7で`block_unprotecting_branches`フィールドは`block_branch_modification`フィールドに[置き換えられました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137153)。
- 16.4で`scan_result_policies_block_unprotecting_branches`機能フラグは`scan_result_policy_settings`機能フラグに置き換えられました。
  - GitLab 16.7の[GitLab.comおよびGitLab Self-Managedで有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/423901)されました。
  - GitLab 16.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/433415)になりました。機能フラグ`scan_result_policies_block_unprotecting_branches`は削除されました。
- `prevent_approval_by_author`、`prevent_approval_by_commit_author`、`remove_approvals_with_new_commit`、および`require_password_to_approve`フィールド:
  - GitLab 16.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/418752)、`scan_result_any_merge_request`という名前の[フラグ](../../../administration/feature_flags/_index.md)が設定されました。デフォルトでは無効になっています。
  - GitLab 16.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/423988)になりました。
  - GitLab 16.7で[GitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/423988)。
  - GitLab 16.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/432127)になりました。機能フラグ`scan_result_any_merge_request`は削除されました。
- `prevent_pushing_and_force_pushing`フィールド
  - GitLab 16.4で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/420629)、`scan_result_policies_block_force_push`という名前の[フラグ](../../../administration/feature_flags/_index.md)が設定されました。デフォルトでは無効になっています。
  - GitLab 16.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/427260)になりました。
  - GitLab 16.7で[GitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/427260)。
  - GitLab 16.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/432123)になりました。機能フラグ`scan_result_policies_block_force_push`は削除されました。

{{< /history >}}

ポリシーで設定された設定は、プロジェクトの設定を上書きする。

| フィールド                               | タイプ                  | 必須 | 使用可能な値                                               | 適用可能なルールタイプ | 説明 |
|-------------------------------------|-----------------------|----------|---------------------------------------------------------------|----------------------|-------------|
| `block_branch_modification`         | `boolean`             | false    | `true`、`false`                                               | すべて                  | 有効にすると、ユーザーが保護ブランチのリストからブランチを削除したり、保護ブランチを削除したり、そのブランチがセキュリティポリシーに含まれている場合にデフォルトブランチを変更したりするのを防ぎます。これにより、ユーザーはブランチから保護ステータスを削除して、脆弱性のあるコードをマージすることができなくなります。`branches`、`branch_type`、`policy_scope`に基づいて、検出された脆弱性に関係なく強制されます。 |
| `block_group_branch_modification`   | `boolean`または`object` | false    | `true`、`false`、`{ enabled: boolean, exceptions: [{ id: Integer}] }` | すべて                  | 有効にすると、ポリシーが適用されるすべてのグループで、ユーザーがグループレベルの保護ブランチを削除するのを防ぎます。`block_branch_modification`が`true`の場合、暗黙的に`true`にデフォルト設定されます。[グループレベルの保護ブランチ](../../project/repository/branches/protected.md#in-a-group)をサポートするトップレベルグループを`exceptions`として追加します。 |
| `prevent_approval_by_author`        | `boolean`             | false    | `true`、`false`                                               | `Any merge request`  | 有効にすると、マージリクエストの作成者は自身のマージリクエストを承認できません。これにより、コード作成者が脆弱性を導入し、コードをマージすることを承認できなくなります。 |
| `prevent_approval_by_commit_author` | `boolean`             | false    | `true`、`false`                                               | `Any merge request`  | 有効にすると、マージリクエストにコードをコントリビュートしたユーザーは、承認の対象外になります。これにより、コードコミッターが脆弱性を導入し、コードをマージすることを承認できなくなります。 |
| `remove_approvals_with_new_commit`  | `boolean`             | false    | `true`、`false`                                               | `Any merge request`  | 有効にすると、マージリクエストがマージに必要なすべての承認を受け取った後、新しいコミットが追加された場合、新しい承認が必要になります。これにより、脆弱性を含む可能性のある新しいコミットが導入されないようにします。 |
| `require_password_to_approve`       | `boolean`             | false    | `true`、`false`                                               | `Any merge request`  | 有効にすると、承認者は承認する前に再度認証する必要があります。承認者は、設定された認証方法に応じて、パスワードまたはSAMLを使用して再認証することができます。これにより、承認者の身元を確保するための追加のセキュリティ層が追加されます。詳細については、[承認のためのユーザー再認証を要求する](../../project/merge_requests/approvals/settings.md#require-user-re-authentication-to-approve)を参照してください。 |
| `prevent_pushing_and_force_pushing` | `boolean`             | false    | `true`、`false`                                               | すべて                  | 有効にすると、ブランチがセキュリティポリシーに含まれている場合、ユーザーが保護ブランチにプッシュしたり、強制プッシュしたりするのを防ぎます。これにより、ユーザーはマージリクエストプロセスをバイパスすることなく、脆弱性のあるコードをブランチに追加できるようにします。 |

### 承認設定の適用スコープ {#enforcement-scope-of-approval-settings}

これらの設定は、ポリシーに対する違反があるマージリクエストにのみ適用されます:

- `prevent_approval_by_author`
- `prevent_approval_by_commit_author`
- `remove_approvals_with_new_commit`
- `require_password_to_approve`

マージリクエストにポリシー違反がない場合、設定はそのマージリクエストに影響を与えません。

ポリシーがアクティブな場合、マージリクエストにポリシー違反があるかどうかに関わらず、これらの設定は常に適用されます:

- `block_branch_modification`
- `block_group_branch_modification`
- `prevent_pushing_and_force_pushing`の設定

## `fallback_behavior` {#fallback_behavior}

{{< history >}}

- `fallback_behavior`フィールド:
  - GitLab 17.0で`security_scan_result_policies_unblock_fail_open_approval_rules`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/451784)されました。デフォルトでは無効になっています。
  - GitLab 17.0で[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効になりました](https://gitlab.com/groups/gitlab-org/-/epics/10816)。
  - GitLab 17.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/451784)になりました。機能フラグ`security_scan_result_policies_unblock_fail_open_approval_rules`は削除されました。

{{< /history >}}

| フィールド  | タイプ     | 必須 | 使用可能な値    | 説明                                                                                                          |
|--------|----------|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|
| `fail` | `string` | false    | `open`または`closed` | `closed`（デフォルト）: ポリシーの無効または強制できないルールには承認が必要です。`open`: ポリシーの無効または強制できないルールには承認は不要です。 |

## `policy_tuning` {#policy_tuning}

### `unblock_rules_using_execution_policies` {#unblock_rules_using_execution_policies}

{{< history >}}

- GitLab 17.10でパイプライン実行ポリシーでの使用が[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/498624)、`unblock_rules_using_pipeline_execution_policies`という名前の[フラグ](../../../administration/feature_flags/_index.md)が設定されました。デフォルトでは有効になっています。
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/525270)になりました。機能フラグ`unblock_rules_using_pipeline_execution_policies`は削除されました。

{{< /history >}}

| フィールド  | タイプ     | 必須 | 使用可能な値    | 説明                                                                                                          |
|--------|----------|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|
| `unblock_rules_using_execution_policies` | `boolean` | false    | `true`、`false` | 有効にすると、スキャン実行ポリシーまたはパイプライン実行ポリシーによってスキャンが必要とされるにもかかわらず、必要なスキャンアーティファクトがソースブランチから不足している場合、承認ルールはマージリクエストをブロックしません。このオプションは、プロジェクトまたはグループに、一致するスキャナーを持つ既存のスキャン実行ポリシーまたはパイプライン実行ポリシーがある場合にのみ機能します。 |

新しく検出された状態のみをターゲットとする場合（`license_states`が`newly_detected`に設定されている場合）にのみ、[ライセンス検出ルール](#license_finding-rule-type)を除外することができます。

#### 例 {#examples}

##### `policy_tuning`とスキャン実行ポリシーの例 {#example-of-policy_tuning-with-a-scan-execution-policy}

この例は、[セキュリティポリシープロジェクト](enforcement/security_policy_projects.md)に保存されている`.gitlab/security-policies/policy.yml`ファイルで使用できます:

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

##### `policy_tuning`とパイプライン実行ポリシーの例 {#example-of-policy_tuning-with-a-pipeline-execution-policy}

> [!warning]
> この機能は、GitLab 17.10より前に作成されたパイプライン実行ポリシーでは機能しません。この機能が古いパイプライン実行ポリシーで動作するようにするには、それらのポリシーをコピー、削除、および再作成します。詳細については、「[GitLab 17.10より前に作成されたパイプライン実行ポリシーを再作成する](#recreate-pipeline-execution-policies-created-before-gitlab-1710)」を参照してください。

この例は、[セキュリティポリシープロジェクト](enforcement/security_policy_projects.md)に保存されている`.gitlab/security-policies/policy.yml`ファイルで使用できます:

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

リンクされたパイプライン実行ポリシーのCI/CD設定（`policy-ci.yml`内）:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml
```

###### GitLab 17.10より前に作成されたパイプライン実行ポリシーを再作成する {#recreate-pipeline-execution-policies-created-before-gitlab-1710}

GitLab 17.10より前に作成されたパイプライン実行ポリシーには、`policy_tuning`機能を使用するために必要なデータが含まれていません。この機能が古いパイプライン実行ポリシーで動作するようにするには、古いポリシーをコピー、削除してから再作成します。

<i class="fa-youtube-play" aria-hidden="true"></i> ビデオチュートリアルについては、[セキュリティポリシー: `policy_tuning`で使用するためのパイプライン実行ポリシーを再作成する](https://youtu.be/XN0jCQWlk1A)を参照してください。
<!-- Video published on 2025-03-07 -->

パイプライン実行ポリシーを再作成するには:

<!-- markdownlint-disable MD044 -->

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **セキュリティ** > **ポリシー**を選択します。
1. 再作成するパイプライン実行ポリシーを選択します。
1. 右サイドバーで**YAML**タブを選択し、ポリシーファイル全体の内容をコピーします。
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

ビジーなプロジェクトでは、最新のパイプラインがセキュリティスキャンをすぐに完了していない可能性があり、これがセキュリティレポートの比較をブロックします。代わりに、`security_report_time_window`設定を使用して、最近完了したパイプラインからセキュリティレポートを取得します。セキュリティレポートは、ターゲットブランチパイプラインの作成より前に分単位で指定された時間枠より古くすることはできません。この設定は、選択したパイプラインがすでにセキュリティレポートを完了している場合には適用されません。

| フィールド  | タイプ     | 必須 | 使用可能な値    | 説明                                                                                                          |
|--------|----------|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|
| `security_report_time_window` | `integer` | false    | 1〜10080（7日間） | セキュリティレポートの比較のためにターゲットパイプラインを選択するための時間枠を分単位で指定します。 |

## ポリシーのスコープスキーマ {#policy-scope-schema}

政策の適用をカスタマイズするには、指定されたプロジェクト、グループ、またはコンプライアンスフレームワークラベルを含めるか除外するかにポリシーのスコープを定義できます。詳細については、[スコープ](_index.md#configure-the-policy-scope)を参照してください。

> [!note]
> `policy_scope`フィールドを空のコレクション（例: `including: []`）に設定すると、そのフィールドを省略した場合と同じように扱われるため、ポリシーはそのスコープディメンションのすべてのプロジェクトに適用されます。完全にポリシーを無効にするには、`enabled: false`を使用します。詳細については、[`policy_scope`内の空のコレクション](_index.md#empty-collections-in-policy_scope)を参照してください。

## `bypass_settings` {#bypass_settings}

`bypass_settings`フィールドを使用すると、特定のブランチ、アクセストークン、またはサービスアカウントに対するポリシーの例外を指定できます。バイパスする条件が満たされた場合、ポリシーは一致するマージリクエストまたはブランチに適用されません。

| フィールド             | タイプ    | 必須 | 説明                                                                     |
|-------------------|---------|----------|---------------------------------------------------------------------------------|
| `branches`        | 配列   | false    | ポリシーをバイパスするソースブランチおよびターゲットブランチ（名前またはパターンによる）のリスト。 |
| `access_tokens`   | 配列   | false    | ポリシーをバイパスするアクセストークンIDのリスト。                                |
| `service_accounts`| 配列   | false    | ポリシーをバイパスするサービスアカウントIDのリスト。                             |
| `users`           | 配列   | false    | ポリシーをバイパスすることができるユーザーIDのリスト。                                        |
| `groups`          | 配列   | false    | ポリシーをバイパスすることができるグループIDのリスト。                                       |
| `roles`           | 配列   | false    | ポリシーをバイパスすることができるデフォルトロールのリスト。                                   |
| `custom_roles`    | 配列   | false    | ポリシーをバイパスすることができるカスタムロールIDのリスト。                                 |

### ソースブランチの例外 {#source-branch-exceptions}

{{< history >}}

- GitLab 18.2で`approval_policy_branch_exceptions`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/18113)されました。デフォルトで有効
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/543778)になりました。機能フラグ`approval_policy_branch_exceptions`は削除されました。

{{< /history >}}

ブランチベースの例外を使用すると、特定のソースブランチとターゲットブランチの組み合わせに対する承認要件を自動的に免除するようにマージリクエスト承認ポリシーを設定できます。これにより、セキュリティガバナンスを維持し、feature-to-mainなどの特定のタイプのマージに対して厳格な承認ルールを維持しつつ、release-to-mainなどの他のタイプにはより柔軟性を持たせることができます。バイパスするイベントは、セキュリティポリシープロジェクトで監査イベントとしてログに記録されます。

| フィールド   | タイプ   | 必須 | 使用可能な値 | 説明 |
|---------|--------|----------|-----------------|-------------|
| `source`| オブジェクト | false    | `name` (string) または`pattern` (string) | ソースブランチ例外。正確な名前またはパターンを指定します。         |
| `target`| オブジェクト | false    | `name` (string) または`pattern` (string) | ターゲットブランチ例外。正確な名前またはパターンを指定します。         |

### アクセストークンとサービスアカウントの例外 {#access-token-and-service-account-exceptions}

{{< history >}}

- GitLab 18.2で`security_policies_bypass_options_tokens_accounts`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/18112)されました。デフォルトで有効
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/551129)になりました。機能フラグ`security_policies_bypass_options_tokens_accounts`は削除されました。

{{< /history >}}

アクセストークンとサービスアカウントの例外を使用すると、必要に応じてマージリクエスト承認ポリシーによって適用されるブランチ保護をバイパスすることができる特定のサービスアカウントとアクセストークンを指定できます。このアプローチにより、手動での承認なしで動作することを信頼する自動化を可能にしつつ、人間ユーザーに対する制限を維持できます。たとえば、信頼できる自動化には、CI/CDパイプライン、リポジトリのミラーリング、自動更新などが含まれます。バイパスするイベントは、セキュリティポリシープロジェクトで監査イベントとしてログに記録されます。

| フィールド | タイプ    | 必須 | 説明                                    |
|-------|---------|----------|------------------------------------------------|
| `id`  | 整数 | true     | アクセストークンまたはサービスアカウントのID。 |

### ユーザーがセキュリティポリシーをバイパスすることを許可する {#allowing-users-to-bypass-security-policies}

{{< history >}}

- GitLab 18.5で`security_policies_bypass_options_group_roles`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/18114)されました。デフォルトでは有効になっています。
- GitLab 18.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/551920)になりました。機能フラグ`security_policies_bypass_options_group_roles`は削除されました。

{{< /history >}}

緊急事態に備えるため、マージリクエスト承認ポリシーをバイパスすることができる特定のユーザー、グループ、ロール、またはカスタムロールを指定できます。この機能により、緊急対応とガバナンス統制の維持に柔軟性がもたらされます。ユーザー、グループ、ロール、またはカスタムロールがセキュリティポリシーをバイパスすることを許可するには、例外を付与します。バイパスするイベントは、セキュリティポリシープロジェクトで監査イベントとしてログに記録されます。

これらの例外を持つユーザーは、2つのレベルでバイパスすることができます:

- マージリクエスト承認要件: ユーザーは、マージリクエストUIから理由を提供することで、承認要件をバイパスすることができます。
- ブランチ保護: ユーザーは、マージリクエスト承認ポリシーのプッシュ保護を持つブランチに、[`security_policy.bypass_reason` Gitプッシュオプション](../../../topics/git/commit.md#push-options-for-security-policy)で理由を提供することにより、直接プッシュできます。

> [!note]
> `security_policy.bypass_reason`プッシュオプションは、[`approval_settings`](merge_request_approval_policies.md#approval_settings)で設定されたマージリクエスト承認ポリシーからのプッシュ保護を持つブランチにのみ機能します。マージリクエスト承認ポリシーによってカバーされていない保護ブランチへのプッシュは、このオプションではバイパスすることができません。

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

## セキュリティポリシープロジェクト内の`policy.yml`の例 {#example-policyyml-in-a-security-policy-project}

この例は、[セキュリティポリシープロジェクト](enforcement/security_policy_projects.md)に保存されている`.gitlab/security-policies/policy.yml`ファイルで使用できます:

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

- コンテナスキャンによって識別された新しい`critical`脆弱性を含むすべてのマージリクエストには、`alberto.dare`からの承認が1つ必要です。
- コンテナスキャンによって識別された、30日以上前の既存の`low`または`unknown`脆弱性を複数含むすべてのマージリクエストには、オーナーロールを持つプロジェクトメンバーまたはカスタムロール`AppSec Engineer`を持つユーザーのいずれかからの承認が1つ必要です。
- SASTスキャンによって識別された、新しい`critical`または`high`重大度の脆弱性を含むすべてのマージリクエストは、警告モードポリシーをトリガーします。警告モードはボットコメントを生成し、マージリクエストをブロックします。開発者はポリシー違反をバイパスできます。オプションで、メンテナーもマージリクエストを承認できます。

## マージリクエスト承認ポリシーエディタの例 {#example-for-merge-request-approval-policy-editor}

YAMLモードで、[マージリクエスト承認ポリシーエディタ](#merge-request-approval-policy-editor)のこの例を使用できます。これは、前の例の単一のオブジェクトに対応します:

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

## マージリクエスト承認ポリシーの承認を理解する {#understanding-merge-request-approval-policy-approvals}

{{< history >}}

- `scan_finding`のブランチ比較ロジックは、GitLab 16.8で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/428518)され、[フラグ](../../../administration/feature_flags/_index.md) `scan_result_policy_merge_base_pipeline`と共に導入されました。デフォルトでは無効になっています。
- GitLab 16.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/435297)になりました。機能フラグ`scan_result_policy_merge_base_pipeline`は削除されました。

{{< /history >}}

### マージリクエスト承認ポリシー比較のスコープ {#scope-of-merge-request-approval-policy-comparison}

- マージリクエストで承認が必要な時期を決定するために、GitLabはソースブランチとターゲットブランチのサポートされている各パイプラインソースに対して、完了したパイプラインを比較します（例: `feature`/`main`）。これにより、スキャン結果の最も包括的な評価が保証されます。
- ソースブランチの場合、比較パイプラインは、ソースブランチの最新のコミットに対して、サポートされている各パイプラインソースのすべての完了したパイプラインです。
- マージリクエスト承認ポリシーが新しく検出された状態（`new_needs_triage` & `new_dismissed`）のみを検索する場合、比較はソースとターゲットブランチ間の共通の祖先にある、サポートされているすべてのパイプラインソースに対して実行されます。マージ結果パイプラインを使用する場合、MRのターゲットブランチの先端に対して比較が行われる点が例外です。
- マージリクエスト承認ポリシーが既存の状態（`detected`、`confirmed`、`resolved`、`dismissed`）を検索する場合、比較は常にデフォルトブランチ（例: `main`）の先端に対して行われます。
- マージリクエスト承認ポリシーが新規と既存の脆弱性状態の組み合わせを検索する場合、比較はソースとターゲットブランチの共通の祖先に対して行われます。
- マージリクエスト承認ポリシーは、マージリクエストに承認が必要かどうかを決定する際に、ソースとターゲットブランチの両方からの結果を比較する際に、サポートされているすべてのパイプラインソース（[`CI_PIPELINE_SOURCE`変数](../../../ci/variables/predefined_variables.md)に基づく）を考慮します。`webide`をソースとするパイプラインはサポートされていません。
- GitLab 16.11以降では、選択された各パイプラインの子パイプラインも比較対象とされます。

### 今後のマージリクエストにおける脆弱性のリスクを受け入れ、無視する {#accepting-risk-and-ignoring-vulnerabilities-in-future-merge-requests}

新しく検出された検出結果（`new_needs_triage`または`new_dismissed`ステータス）にスコープされているマージリクエスト承認ポリシーの場合、この脆弱性状態の意味を理解することが重要です。検出結果は、マージリクエストのブランチには存在するが、ターゲットブランチには存在しない場合に、新しく検出されたとみなされます。新しく検出された検出結果を含むブランチを持つマージリクエストが承認されてマージされた場合、承認者はそれらの脆弱性の「リスクを受け入れた」ことになります。この後に同じ脆弱性が1つ以上検出された場合、ステータスは`detected`となり、`new_needs_triage`または`new_dismissed`の検出結果を考慮するように設定されたポリシーによって無視されます。例: 

- 重要なSASTの検出結果をブロックするマージリクエスト承認ポリシーが作成されます。CVE-1234に対するSASTの検出結果が承認された場合、同じ違反を伴う今後のマージリクエストでは、プロジェクトでの承認は不要になります。

`new_needs_triage`と`new_dismissed`の脆弱性状態を使用する場合、ポリシーは、検出結果が新しく、まだトリアージされていない場合、それが無視されたとしても、ポリシールールに一致するすべてのMRをブロックします。新しく検出され、その後マージリクエスト内で無視された脆弱性を無視したい場合は、`new_needs_triage`ステータスのみを使用できます。

ライセンス承認ポリシーを使用する場合、プロジェクト、コンポーネント（依存）、およびライセンスの組み合わせが評価で考慮されます。ライセンスが例外として承認された場合、今後のマージリクエストでは、プロジェクト、コンポーネント（依存）、およびライセンスの同じ組み合わせに対する承認は不要になります。この場合、コンポーネントのバージョンは考慮されません。以前に承認されたパッケージが新しいバージョンに更新されても、承認者は再承認する必要はありません。例: 

- `AGPL-1.0`に一致する新しく検出されたライセンスを持つマージリクエストをブロックするライセンス承認ポリシーが作成されます。`demo`プロジェクトのコンポーネント`osframework`に対して、ポリシーに違反する変更が加えられます。承認されてマージされた場合、プロジェクト`demo`の`osframework`への今後のマージリクエストでは、ライセンス`AGPL-1.0`の承認は不要になります。

### 追加の承認 {#additional-approvals}

マージリクエスト承認ポリシーは、一部の状況で追加の承認ステップを必要とします。例: 

- 作業ブランチ内のセキュリティジョブの数が減り、ターゲットブランチ内のセキュリティジョブの数と一致しなくなりました。ユーザーはCI/CDの設定からスキャンニングジョブを削除しても、スキャン結果ポリシーをスキップすることはできません。マージリクエスト承認ポリシールールで設定されているセキュリティスキャンのみが削除対象としてチェックされます。

  たとえば、デフォルトブランチパイプラインに4つのセキュリティスキャン（`sast`、`secret_detection`、`container_scanning`、`dependency_scanning`）がある状況を考えてみましょう。マージリクエスト承認ポリシーは、`container_scanning`と`dependency_scanning`の2つのスキャナーを適用します。MRがマージリクエスト承認ポリシーで設定されているスキャン（例えば`container_scanning`）を削除した場合、追加の承認が必要になります。
- 誰かがパイプラインのセキュリティジョブを停止すると、ユーザーはセキュリティスキャンをスキップできません。
- マージリクエストのジョブが失敗し、`allow_failure: false`で設定されています。その結果、パイプラインはブロックされた状態になります。
- パイプライン全体が成功するためには、手動ジョブが正常に実行される必要があります。

### 承認要件の評価に使用されるスキャン結果の管理 {#managing-scan-findings-used-to-evaluate-approval-requirements}

マージリクエスト承認ポリシーは、パイプラインが完了した後に、パイプライン内のスキャナーによって生成されたアーティファクトレポートを評価します。マージリクエスト承認ポリシーは、結果を評価し、スキャン結果に基づいて承認を決定して、潜在的なリスクを特定し、マージリクエストをブロックし、承認を要求することに焦点を当てています。

マージリクエスト承認ポリシーは、そのスコープを超えてアーティファクトファイルやスキャナーにまで及ぶことはありません。その代わりに、GitLabはアーティファクトレポートからの結果を信頼します。これにより、チームはスキャン実行とサプライチェーンの管理において柔軟性を持ち、必要に応じてアーティファクトレポートで生成されたスキャン結果をカスタマイズできます（例: 誤検出を除外するため）。

たとえば、ロックファイルの改ざんはセキュリティポリシー管理のスコープ外ですが、[コードオーナー](../../project/codeowners/_index.md#codeowners-file)や[外部ステータスチェック](../../project/merge_requests/status_checks.md)の使用によって軽減される可能性があります。詳細については、[イシュー433029](https://gitlab.com/gitlab-org/gitlab/-/issues/433029)を参照してください。

![スキャン結果の検出を評価する](img/scan_results_evaluation_white-bg_v16_8.png)

### **Fix Available**または**False Positive**の属性を持つポリシー違反を除外する {#filter-out-policy-violations-with-the-attributes-fix-available-or-false-positive}

不要な承認要件を避けるために、これらの追加フィルターは、最も実用的な検出結果に基づいてMRをブロックすることを保証するのに役立ちます。

YAMLで`fix_available`を`false`に設定するか、ポリシーエディタで**等しくない**と**Fix Available**を設定することで、検出結果に解決策または修正がある場合、その検出結果はポリシー違反とはみなされません。脆弱性オブジェクトの下部、「**解決策**」という見出しの下に解決策が表示されます。修正は、脆弱性オブジェクト内に**Resolve with Merge Request**ボタンとして表示されます。

**Resolve with Merge Request**ボタンは、次のいずれかの条件が満たされた場合にのみ表示されます:

1. GitLab Duo Enterpriseを持つUltimateのプロジェクトでSAST脆弱性が検出されます。
1. `GIT_STRATEGY: fetch`が設定されているジョブにおいて、Ultimateのプロジェクトでコンテナスキャン脆弱性が検出されます。さらに、脆弱性は、コンテナイメージに対して有効になっているリポジトリで利用可能な修正を含むパッケージを持っている必要があります。
1. Node.jsプロジェクトで依存関係スキャン脆弱性が検出され、yarnによって管理されており、修正が利用可能です。さらに、プロジェクトはUltimateであり、インスタンスに対してFIPSモードが無効になっている必要があります。

**Fix Available**は、依存関係スキャンとコンテナスキャンにのみ適用されます。

**False Positive**属性を使用すると、同様に、`false_positive`を`false`に設定することで（またはポリシーエディタで**次のとおりではありません**と**False Positive**に属性を設定することで）、ポリシーによって検出された検出結果を無視できます。

**False Positive**属性は、SAST結果の脆弱性抽出ツールによって検出された検出結果にのみ適用されます。

### ポリシー評価と脆弱性状態の変化 {#policy-evaluation-and-vulnerability-state-changes}

ユーザーが脆弱性のステータスを変更すると（例えば、脆弱性詳細ページで脆弱性を無視する）、パフォーマンス上の理由から、GitLabはマージリクエスト承認ポリシーを自動的に再評価しません。脆弱性レポートから更新されたデータを取得するには、マージリクエストを更新するか、関連するパイプラインを再実行してください。

この動作は、最適なシステムパフォーマンスを確保し、セキュリティポリシーの適用を維持します。ポリシー評価は、次のパイプラインの実行中またはマージリクエストが更新されたときに発生し、脆弱性の状態が変更された直後には発生しません。

ポリシーにおける脆弱性の状態変更をすぐに反映するには、手動でパイプラインを実行するか、マージリクエストに新しいコミットをプッシュしてください。

## セキュリティウィジェットとポリシーボットの不一致を理解する {#understanding-security-widget-and-policy-bot-discrepancies}

マージリクエストセキュリティウィジェットが表示する内容と、セキュリティボットのコメントが脆弱性に関して示す内容との間に不一致が見られる場合があります。これらの機能は、セキュリティ検出結果に対して異なるデータソースと比較方法を使用しており、表示される内容に違いが生じる可能性があります。

データソース:

- **Merge request security widget**: 最新のソースブランチパイプラインの結果と、デフォルトブランチのデータベースに以前保存された脆弱性を比較します。
- **Security Bot (and approval policy logic)**: 実際のパイプラインアーティファクト、具体的には最新の成功したターゲットブランチパイプラインと最新の成功したソースブランチパイプライン間の結果を比較します。

### 不一致が発生する一般的なシナリオ {#common-scenarios-where-inconsistencies-occur}

データソースの違いは、いくつかのシナリオで一貫性のない動作につながる可能性があります。

#### ターゲットブランチでのセキュリティスキャンの不足または失敗 {#missing-or-failed-security-scans-in-target-branch}

ターゲットブランチの最新のパイプラインがセキュリティスキャンを適切に実行できない場合（例えば、設定ミスやジョブの失敗のため）、セキュリティボットは結果を効果的に比較できないため、予防措置として新しい検出結果を報告し、承認を要求する場合があります。その一方で、セキュリティウィジェットは、以前に保存された脆弱性データを使用しているため、新しい脆弱性を表示しない場合があります。

#### 比較間のターゲットブランチでの変更 {#changes-in-target-branch-between-comparisons}

ターゲットブランチに複数のコミットがあり、ウィジェットが比較を行う時とボットが比較を行う時の間でセキュリティプロファイルが変更された場合、結果が異なる可能性があります。

### 一貫した結果を得るためのベストプラクティス {#best-practices-for-consistent-results}

これらのセキュリティ機能を使用する際の混乱を最小限に抑えるには:

- パイプラインが完全に実行されていることを確認する: ソースとターゲットブランチの両方でセキュリティスキャンが正常に完了していることを確認してください。
- 一貫したCI/CD設定を維持する: パイプライン内のセキュリティスキャン設定の削除や破損を避けてください。
- 新しいプロジェクトの場合: マージリクエストを作成する前に、デフォルトブランチでセキュリティスキャンを実行し、ベースラインの脆弱性データを確立します。
- スキャン実行ポリシーの使用を検討する: マージリクエスト承認ポリシーと組み合わせることで、セキュリティスキャンが必要な場所で常に実行されるようになります。

## トラブルシューティング {#troubleshooting}

### マージリクエストルールウィジェットに、マージリクエスト承認ポリシーが無効または重複していると表示される {#merge-request-rules-widget-shows-a-merge-request-approval-policy-is-invalid-or-duplicated}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Self-Managedの15.0から16.4では、最も可能性の高い原因は、プロジェクトがグループからエクスポートされ、別のグループにインポートされ、マージリクエスト承認ポリシールールを持っていたことです。これらのルールは、エクスポートされたプロジェクトとは別のプロジェクトに保存されます。その結果、プロジェクトには、インポートされたプロジェクトのグループに存在しないエンティティを参照するポリシールールが含まれています。その結果、ポリシールールは無効であるか、重複しているか、またはその両方になります。

GitLabインスタンスからすべての無効なマージリクエスト承認ポリシールールを削除するには、管理者は[Railsコンソール](../../../administration/operations/rails_console.md)で次のスクリプトを実行できます。

```ruby
Project.joins(:approval_rules).where(approval_rules: { report_type: %i[scan_finding license_scanning] }).where.not(approval_rules: { security_orchestration_policy_configuration_id: nil }).find_in_batches.flat_map do |batch|
  batch.map do |project|
    # Get projects and their configuration_ids for applicable project rules
    [project, project.approval_rules.where(report_type: %i[scan_finding license_scanning]).pluck(:security_orchestration_policy_configuration_id).uniq]
  end.uniq.map do |project, configuration_ids| # Take only unique combinations of project + configuration_ids
    # If you find more configurations than what is available for the project, take records with the extra configurations
    [project, configuration_ids - project.all_security_orchestration_policy_configurations.pluck(:id)]
  end.select { |_project, configuration_ids| configuration_ids.any? }
end.each do |project, configuration_ids|
  # For each found pair project + ghost configuration, remove these rules for a given project
  Security::OrchestrationPolicyConfiguration.where(id: configuration_ids).each do |configuration|
    configuration.delete_scan_finding_rules_for_project(project.id)
  end
  # Ensure you sync any potential rules from new group's policy
  Security::ScanResultPolicies::SyncProjectWorker.perform_async(project.id)
end
```

### 新しく検出されたCVE {#newly-detected-cves}

`new_needs_triage`と`new_dismissed`を使用する場合、マージリクエストによって導入されていない検出結果（関連する依存関係の新しいCVEなど）が承認を必要とする場合があります。これらの検出結果はMRウィジェット内には表示されませんが、ポリシーボットのコメントとパイプラインレポートで強調表示されます。

### `policy.yml`が手動で無効化された後もポリシーは有効である {#policies-still-have-effect-after-policyyml-was-manually-invalidated}

GitLab 17.2以前では、`policy.yml`ファイルで定義されたポリシーが、手動で編集され、[ポリシースキーマ](#merge-request-approval-policies-schema)に対して検証されなくなった後も、適用されている場合があります。このイシューは、ポリシー同期ロジックのバグが原因で発生します。

潜在的な症状は次のとおりです:

- `approval_settings`は引き続きブランチ保護の削除をブロックしたり、強制プッシュをブロックしたり、オープンなマージリクエストに影響を与えたりします。
- `any_merge_request`ポリシーは、オープンなマージリクエストに引き続き適用されます。

これを解決するには、次のことができます:

- ポリシーを定義する`policy.yml`ファイルを手動で編集して、再び有効にします。
- `policy.yml`ファイルが保存されているセキュリティポリシープロジェクトの割り当てを解除し、再度割り当ててください。

### セキュリティスキャンの欠落 {#missing-security-scans}

マージリクエスト承認ポリシーを使用している場合、新しいプロジェクトでマージリクエストがブロックされたり、特定のセキュリティスキャンが実行されなかったりする状況に遭遇する可能性があります。この動作は、システムへの脆弱性の導入リスクを減らすための設計上のものです。

シナリオの例:

- ソースブランチでのスキャンの欠落

  ソースブランチにセキュリティスキャンがない場合、GitLabはマージリクエストが新しい脆弱性を導入しているかどうかを効果的に評価できません。そのような場合、予防措置として承認が必要です。

- ターゲットブランチでのスキャンの欠落

  ターゲットブランチにセキュリティスキャンがない場合、GitLabはソースブランチで検出された脆弱性を効果的に比較できません。そのような場合、検出されたすべての脆弱性が新しく報告されます。

- スキャンするファイルがないプロジェクト

  選択されたセキュリティスキャンに関連するファイルが含まれていないプロジェクトでも、承認要件は引き続き適用されます。これにより、すべてのプロジェクトで一貫したセキュリティプラクティスが維持されます。

- 最初のマージリクエスト

  新しいプロジェクトで最初のマージリクエストは、デフォルトブランチにセキュリティスキャンがない場合、ソースブランチに脆弱性がなくてもブロックされる可能性があります。

これらのイシューを解決するには:

- 必要なすべてのセキュリティスキャンが、ソースとターゲットブランチの両方で設定され、正常に実行されていることを確認してください。
- 新しいプロジェクトの場合、マージリクエストを作成する前に、デフォルトブランチで必要なセキュリティスキャンを設定して実行してください。
- スキャン実行ポリシーまたはパイプライン実行ポリシーを使用して、すべてのブランチでセキュリティスキャンの一貫した実行を確保することを検討してください。
- 無効または実施できないポリシールールが承認を要求するのを防ぐために、`open`と組み合わせて[`fallback_behavior`](#fallback_behavior)を使用することを検討してください。
- セキュリティスキャンアーティファクトが不足しており、スキャン実行ポリシーが適用されているシナリオに対処するために、[`policy tuning`](#policy_tuning)設定`unblock_rules_using_execution_policies`を使用することを検討してください。これを有効にすると、ソースブランチからスキャンアーティファクトが不足しており、スキャン実行ポリシーによってスキャンが要求される場合、承認ルールはオプションになります。この機能は、一致するスキャナーを持つ既存のスキャン実行ポリシーでのみ機能します。セキュリティスキャンがアーティファクトの不足により実行できない場合、マージリクエストプロセスに柔軟性をもたらします。

### セキュリティボットのコメントにある`Target: none` {#target-none-in-security-bot-comments}

セキュリティボットのコメントに`Target: none`が表示される場合、GitLabがターゲットブランチのセキュリティレポートを見つけられなかったことを意味します。これを解決するには、次の手順に従います:

1. 必要なセキュリティスキャナーを含むパイプラインをターゲットブランチで実行してください。
1. パイプラインが正常に完了し、セキュリティレポートを生成することを確認してください。
1. ソースブランチでパイプラインを再実行してください。新しいコミットを作成すると、パイプラインも再実行するようにトリガーされます。

#### セキュリティボットメッセージ {#security-bot-messages}

ターゲットブランチにセキュリティスキャンがない場合:

- セキュリティボットは、ソースブランチで見つかったすべての脆弱性を一覧表示する場合があります。
- 脆弱性の一部はすでにターゲットブランチに存在する可能性がありますが、ターゲットブランチのスキャンがないと、GitLabはどれが新しいものかを判断できません。

潜在的な解決策:

1. **Manual approvals**: セキュリティスキャンが確立されるまで、新しいプロジェクトのマージリクエストを手動で承認してください。
1. **Targeted policies**: 異なる承認要件を持つ新しいプロジェクト用に個別のポリシーを作成してください。
1. **フォールバック動作**: 新しいプロジェクトのポリシーに`fail: open`を使用することを検討してください。ただし、これはスキャンが失敗した場合でも、ユーザーが脆弱性をマージすることを許可する可能性があることに注意してください。

### マージリクエスト承認ポリシーのデバッグに関するサポートリクエスト {#support-request-for-debugging-of-merge-request-approval-policy}

GitLab.comユーザーは、「Merge request approval policy debugging」というタイトルの[サポートチケット](https://about.gitlab.com/support/)を提出できます。次の詳細を提供してください:

- グループパス、プロジェクトパス、オプションでマージリクエストID
- 重大度
- 現在の動作
- 期待される動作

#### GitLab.com {#gitlabcom}

サポートチームは、[ログ](https://log.gprd.gitlab.net/)（`pubsub-sidekiq-inf-gprd*`）を調査して`reason`の原因を特定します。以下はログからの応答スニペットの例です。承認に関連するログを見つけるには、このクエリ（`json.event.keyword: "update_approvals"`と`json.project_path: "group-path/project-path"`）を使用できます。必要に応じて、`json.merge_request_iid`を使用してマージリクエスト識別子でさらにフィルターできます:

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

`project-path`、`api_fuzzing`、`merge_request`などのキーワードを検索します。例: `grep group-path/project-path`、および`grep merge_request`。相関IDを知っている場合は、相関IDで検索できます。たとえば、`correlation_id`の値が01HWN2NFABCEDFGの場合、`01HWN2NFABCEDFG`を検索します。次のファイルで検索してください:

- `/gitlab/gitlab-rails/production_json.log`
- `/gitlab/sidekiq/current`

一般的な失敗原因:

- MRによってスキャナーが削除されました: マージリクエスト承認ポリシーは、ポリシーで定義されたスキャナーが存在し、比較用のアーティファクトを正常に生成することを期待します。

### マージリクエスト承認ポリシーからの一貫性のない承認 {#inconsistent-approvals-from-merge-request-approval-policies}

マージリクエスト承認ルールに不一致がある場合は、ポリシーを再同期するために次のいずれかの手順を実行できます:

- [`resyncSecurityPolicies` GraphQLミューテーション](_index.md#resynchronize-policies-with-the-graphql-api)を使用してポリシーを再同期してください。
- セキュリティポリシープロジェクトの割り当てを解除し、影響を受けるグループまたはプロジェクトに再度割り当ててください。
- あるいは、ポリシーを更新して、影響を受けるグループまたはプロジェクトに対してそのポリシーを再同期するようにトリガーすることもできます。
- セキュリティポリシープロジェクト内のYAMLファイルの構文が有効であることを確認してください。

これらのアクションは、マージリクエスト承認ポリシーがすべてのマージリクエストに正しく適用され、一貫性があることを保証するのに役立ちます。

これらの手順を実行した後もマージリクエスト承認ポリシーでイシューが発生し続ける場合は、GitLabサポートにお問い合わせください。

### 検出された脆弱性を修正するマージリクエストには承認が必要です {#merge-requests-that-fix-a-detected-vulnerability-require-approval}

ポリシー設定に`detected`状態が含まれている場合、以前に検出された脆弱性を修正するマージリクエストには、引き続き承認が必要です。マージリクエスト承認ポリシーは、マージリクエストでの変更前に存在した脆弱性に基づいて評価され、既知の脆弱性に影響を与える変更に対して追加のレビューレイヤーが追加されます。

検出された脆弱性のために追加の承認なしで脆弱性を修正するマージリクエストを許可したい場合は、ポリシー設定から`detected`状態を削除することを検討してください。

### マージ結果パイプラインとブランチパイプライン間でのポリシー評価の不一致 {#inconsistent-policy-evaluation-between-merged-results-pipelines-and-branch-pipelines}

プロジェクトで[マージ結果パイプライン](../../../ci/pipelines/merged_results_pipelines.md)が有効になっており、セキュリティスキャンを含むブランチパイプラインも実行されている場合、異なるパイプラインでマージリクエスト承認ポリシーが評価される方法に不一致が発生する可能性があります。次の例を検討してください:

1. マージ結果パイプラインとブランチパイプラインの両方が、同じマージリクエストに対してセキュリティスキャンを実行します。
1. ブランチパイプラインがマージ結果パイプラインの後に完了します。
1. ポリシー評価は、マージ結果パイプラインの代わりにブランチパイプラインを比較のために選択します。

マージリクエスト承認ポリシーは、最新のコミットに対する完了したパイプラインを評価し、最後に完了したパイプラインが比較のために選択されます。ブランチパイプラインがマージ結果パイプラインの後に完了すると、ポリシーは評価のためにブランチパイプラインを使用します。

このイシューを回避するには:

- セキュリティスキャンはマージ結果パイプラインのみで実行する: マージ結果パイプラインが有効な場合、セキュリティスキャンジョブがマージリクエストパイプラインでのみ実行されるように設定してください。セキュリティジョブの実行タイミングを制御するために、[`rules`](../../../ci/jobs/job_rules.md)を使用します:

  ```yaml
  sast:
    rules:
      - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  ```

- 重複したパイプラインを回避する: [重複したパイプラインを回避する](../../../ci/jobs/job_rules.md#avoid-duplicate-pipelines)のガイダンスに従い、コミットごとに1つのパイプラインタイプでのみセキュリティスキャンが実行されるようにしてください。
- 一貫したスキャナー設定を使用する: ソースとターゲットブランチの両方で、同じパイプラインタイプで同じスキャナーを実行してください。

重複するパイプラインの詳細については、[ブランチにプッシュした際の2つのパイプライン](../../../ci/pipelines/mr_pipeline_troubleshooting.md#two-pipelines-when-pushing-to-a-branch)を参照してください。
