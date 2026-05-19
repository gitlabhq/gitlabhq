---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: スキャン実行ポリシー
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.2で、スキャン実行ポリシーエディタにカスタムCI/CD変数のサポートが[導入](https://gitlab.com/groups/gitlab-org/-/epics/9566)されました。
- 既存のGitLab CI/CD設定を持つプロジェクトでのスキャン実行ポリシーの適用は、GitLab 16.2で`scan_execution_policy_pipelines`という[フラグ](../../../administration/feature_flags/_index.md)と共に[導入](https://gitlab.com/groups/gitlab-org/-/epics/6880)されました。機能フラグ`scan_execution_policy_pipelines`は、GitLab 16.5で削除されました。
- スキャン実行ポリシーでの定義済み変数のオーバーライドは、GitLab 16.10で`allow_restricted_variables_at_policy_level`という[フラグ](../../../administration/feature_flags/_index.md)と共に[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440855)されました。デフォルトでは有効になっています。機能フラグ`allow_restricted_variables_at_policy_level`はGitLab 17.5で削除されました。

{{< /history >}}

スキャン実行ポリシーは、デフォルトまたは最新の[セキュリティCI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Jobs)に基づいてGitLabのセキュリティスキャンを適用します。スキャン実行ポリシーは、パイプラインの一部として、または指定されたスケジュールでデプロイできます。

スキャン実行ポリシーは、セキュリティポリシープロジェクトにリンクされているすべてのプロジェクトにわたってセキュリティスキャンを適用します。`.gitlab-ci.yml`ファイルがないプロジェクト、またはAutoDevOpsが無効になっているプロジェクトの場合、セキュリティポリシーは暗黙的に`.gitlab-ci.yml`ファイルを作成します。`.gitlab-ci.yml`ファイルは、シークレット検出、静的な解析、またはプロジェクトでのビルドを必要としないその他のスキャナーを実行するポリシーが常に実行され、適用されることを保証します。

スキャン実行ポリシーとパイプライン実行ポリシーはどちらも、複数のプロジェクトにわたってGitLabセキュリティスキャンを設定し、セキュリティとコンプライアンスを管理できます。スキャン実行ポリシーは設定するのがより高速ですが、カスタマイズはできません。以下のいずれかのユースケースに該当する場合は、代わりに[パイプライン実行ポリシー](pipeline_execution_policies.md)を使用してください:

- 高度な設定が必要です。
- カスタムCI/CDジョブまたはスクリプトを適用したい場合。
- 適用されたCI/CDジョブを通じてサードパーティのセキュリティスキャンを有効にしたい場合。

## スキャン実行ポリシーを作成する {#create-a-scan-execution-policy}

スキャン実行ポリシーを作成するには、以下のいずれかのリソースを使用できます:

- <i class="fa-youtube-play" aria-hidden="true"></i>ビデオウォークスルーについては、[GitLabでセキュリティスキャンポリシーを設定する方法](https://youtu.be/ZBcqGmEwORA?si=aeT4EXtmHjosgjBY)を参照してください。
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab CI/CDの設定がないプロジェクトへのスキャン実行ポリシーの適用](https://www.youtube.com/watch?v=sUfwQQ4-qHs)について詳しくはこちら。
- スキャン実行ポリシーの作成方法については、[チュートリアル: スキャン実行ポリシーの設定](../../../tutorials/scan_execution_policy/_index.md)を参照してください。

## 制限事項 {#restrictions}

- 各ポリシーには最大5つのルールを割り当てることができます。
- 各セキュリティポリシープロジェクトには、最大5つのスキャン実行ポリシーを割り当てることができます。
- ローカルプロジェクトのYAMLファイルはスキャン実行ポリシーをオーバーライドできません。スキャン実行ポリシーは、プロジェクトのCI/CD設定で同じジョブ名を使用している場合でも、パイプライン用に定義されたすべての設定よりも優先されます。
- スケジュールされたポリシー（`type: schedule`）は、スケジュールされた`cadence`にのみ従って実行されます。ポリシーを更新しても、即時スキャンはトリガーされません。
- ポリシーの更新をYAML設定ファイルに直接行う場合（ポリシーエディタではなくコミットまたはプッシュで）、システムに伝播するまでに最大10分かかることがあります。（この制限に対する提案された変更については、[イシュー512615](https://gitlab.com/gitlab-org/gitlab/-/issues/512615)を参照してください。）

## ジョブステージ {#job-stages}

DASTスキャンは常に`dast`ステージで実行されます。`dast`ステージが存在しない場合、GitLabはパイプラインの終わりに`dast`ステージを挿入します。

他のすべてのスキャンのポリシージョブは、パイプラインの`test`ステージで実行されます。`test`ステージをデフォルトのパイプラインから削除した場合、ジョブは以下のルールに従って代わりに`scan-policies`ステージで実行されます:

- `scan-policies`ステージがまだ存在しない場合、GitLabは評価時にそのステージをCI/CDパイプラインに挿入します。
- `build`ステージが存在する場合、GitLabは`build`ステージの直後に`scan-policies`を挿入します。
- `build`ステージが存在しない場合、GitLabはパイプラインの最初に`scan-policies`を挿入します。

ジョブ名の競合を避けるため、ジョブ名にハイフンと数字が追加されます。各数字は、各ポリシーアクションの一意の値です。例えば、`secret-detection`は`secret-detection-1`になります。

## スキャン実行ポリシーエディタ {#scan-execution-policy-editor}

{{< history >}}

- `Merge Request Security Template`: 
  - GitLab 18.2で`flexible_scan_execution`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/541689)されました。デフォルトでは無効になっています。
  - [GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/issues/541689) (GitLab 18.3)。
  - GitLab 18.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/541689)になりました。機能フラグ`flexible_scan_execution`は削除されました。

{{< /history >}}

スキャン実行ポリシーエディタを使用して、スキャン実行ポリシーを作成または編集します。

前提条件: 

- デフォルトでは、グループ、サブグループ、またはプロジェクトのオーナーのみが、セキュリティポリシープロジェクトを作成または割り当てるために必要な[権限](../../permissions.md#project-application-security)を持っています。あるいは、セキュリティポリシーリンクを[管理する](../../custom_roles/abilities.md#security-policy-management)権限を持つカスタムロールを作成できます。

最初のスキャン実行ポリシーを作成する際は、一般的なユースケースのためにこれらのテンプレートから選択してください:

- マージリクエストセキュリティ
  - ユースケース: マージリクエストが作成されたときのみ、すべてのコミットではなく、セキュリティスキャンを実行したい場合。
  - 使用時期: デフォルトまたは保護ブランチをターゲットとするソースブランチでセキュリティスキャンを実行する必要があるマージリクエストパイプラインを使用するプロジェクト向け。
  - 最適な用途: マージリクエスト承認ポリシーに合わせ、すべてのブランチでスキャンを回避することでインフラストラクチャコストを削減する。
  - パイプラインソース: 主にマージリクエストパイプライン。
- スケジュールスキャン
  - ユースケース: コードの変更に関わらず、セキュリティスキャンをスケジュール（毎日または毎週など）で自動的に実行したい場合。
  - 使用時期: 開発活動とは無関係に、定期的なケイデンスでセキュリティスキャンを実行する場合。
  - 最適な用途: コンプライアンス要件、ベースラインセキュリティモニタリング、またはコミットがinfrequentなプロジェクト。
  - パイプラインソース: スケジュールされたパイプライン。
- リリースセキュリティ
  - ユースケース: `main`またはリリースブランチへのすべての変更に対してセキュリティスキャンを実行したい場合。
  - 使用時期: リリース前、または保護ブランチでの包括的なスキャンが必要なプロジェクト向け。
  - 最適な用途: リリースでゲートされたワークフロー、本番環境へのデプロイ、または高セキュリティ環境。
  - パイプラインソース: 保護ブランチへのプッシュパイプライン、リリースパイプライン。

利用可能なテンプレートがニーズに合わない場合、またはよりカスタマイズされたスキャン実行ポリシーが必要な場合は、以下を行うことができます:

- **カスタム**オプションを選択し、カスタム要件を持つ独自のスキャン実行ポリシーを作成します。
- [パイプライン実行ポリシー](pipeline_execution_policies.md)を使用して、セキュリティスキャンおよびCIの適用に関するよりカスタマイズ可能なオプションにアクセスします。

ポリシーが完成したら、エディタの下部にある**マージリクエスト経由で設定**を選択してポリシーを保存します。プロジェクトの設定されたセキュリティポリシープロジェクトにあるマージリクエストにリダイレクトされます。セキュリティポリシープロジェクトがプロジェクトにリンクされていない場合、GitLabが自動的に作成します。エディタの下部にある**ポリシーの削除**を選択することで、エディタインターフェースから既存のポリシーを削除できます。このアクションにより、`policy.yml`ファイルからポリシーを削除するためのマージリクエストが作成されます。

ほとんどのポリシー変更は、マージリクエストがマージされるとすぐに有効になります。マージリクエストを介さずにデフォルトブランチに直接コミットされた変更は、ポリシー変更が有効になるまでに最大10分かかります。

![スキャン実行ポリシーエディタルールモード](img/scan_execution_policy_rule_mode_v17_5.png)

> [!note] DAST実行ポリシーの場合、ルールモードエディタでのサイトおよびスキャンプロファイルの適用方法は、ポリシーが定義されている場所によって異なります:
>
> - プロジェクト内のポリシーの場合、ルールモードエディタで、プロジェクトにすでに定義されているプロファイルのリストから選択します。
> - グループ内のポリシーの場合、使用するプロファイルの名前を入力する必要があります。パイプラインエラーを防ぐには、グループのすべてのプロジェクトに一致する名前のプロファイルが存在する必要があります。

## スキャン実行ポリシースキーマ {#scan-execution-policies-schema}

スキャン実行ポリシーを持つYAML設定は、スキャン実行ポリシースキーマに一致するオブジェクトの配列で構成されます。オブジェクトは`scan_execution_policy`キーの下にネストされた状態です。`scan_execution_policy`キーの下には最大5つのポリシーを設定することができます。最初の5つのポリシーの後に設定されたポリシーは適用されません。

新しいポリシーを保存すると、GitLabはポリシーのコンテンツを[このJSONスキーマ](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json)に対して検証します。[JSONスキーマ](https://json-schema.org/)に慣れていない場合は、以下のセクションと表で代替案を提供します。

| フィールド | 型 | 必須 | 使用可能な値 | 説明 |
|-------|------|----------|-----------------|-------------|
| `scan_execution_policy` | `array`のスキャン実行ポリシー | true |  | スキャン実行ポリシーのリスト（最大5つ） |

## スキャン実行ポリシースキーマ {#scan-execution-policy-schema}

{{< history >}}

- ポリシーごとのアクション制限は、GitLab 17.4で`scan_execution_policy_action_limit`（プロジェクト用）および`scan_execution_policy_action_limit_group`（グループ用）という[フラグ](../../../administration/feature_flags/_index.md)と共に[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/472213)されました。デフォルトでは無効になっています。
- ポリシーごとのアクション制限は、GitLab 18.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/535605)されました。機能フラグ`scan_execution_policy_action_limit`（プロジェクト用）および`scan_execution_policy_action_limit_group`（グループ用）は削除されました。

{{< /history >}}

| フィールド          | 型                                         | 必須 | 説明 |
|----------------|----------------------------------------------|----------|-------------|
| `name`         | `string`                                     | true     | ポリシーの名前。最大255文字。 |
| `description`  | `string`                                     | false    | ポリシーの説明。 |
| `enabled`      | `boolean`                                    | true     | ポリシーを有効（`true`）または無効（`false`）にするフラグ。 |
| `rules`        | `array`のルール                             | true     | ポリシーが適用するルールのリスト。 |
| `actions`      | `array`のアクション                           | true     | ポリシーが適用するアクションのリスト。GitLab 18.0以降では最大10に制限されています。 |
| `policy_scope` | [`policy_scope`](_index.md#configure-the-policy-scope)の`object` | false    | 指定したプロジェクト、グループ、またはコンプライアンスフレームワークラベルに基づいてポリシーのスコープを定義します。 |
| `skip_ci`      | [`skip_ci`](#skip_ci-type)の`object` | false | ユーザーが`skip-ci`ディレクティブを適用できるかどうかを定義します。 |
| `no_pipeline`  | [`no_pipeline`](#no_pipeline-type)の`object` | false | ユーザーが`no_pipeline`ディレクティブを適用できるかどうかを定義します。 |

### `skip_ci`型 {#skip_ci-type}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/482952)されました。

{{< /history >}}

スキャン実行ポリシーは、誰が`[skip ci]`ディレクティブを使用できるかを制御します。`[skip ci]`を使用できる特定のユーザーまたはサービスアカウントを指定すると同時に、重要なセキュリティとコンプライアンスのチェックが確実に実行されるようにすることができます。

`skip_ci`キーワードを使用して、ユーザーが`skip_ci`ディレクティブを適用してパイプラインをスキップできるかどうかを指定します。キーワードを指定しなかった場合、`skip_ci`ディレクティブは無視され、すべてのユーザーはパイプライン実行ポリシーをバイパスできません。

| フィールド                   | 型     | 使用可能な値          | 説明 |
|-------------------------|----------|--------------------------|-------------|
| `allowed` | `boolean`   | `true`、`false` | パイプライン実行ポリシーが適用されたパイプラインで、`skip-ci`ディレクティブの使用を許可（`true`）または禁止（`false`）するフラグ。 |
| `allowlist`             | `object` | `users` | `allowed`フラグに関係なく、`skip-ci`ディレクティブの使用が常に許可されるユーザーを指定します。`users:`の後に、ユーザーIDを表す`id`キーを含んだオブジェクトの配列を指定します。 |

> [!note] `schedule`ルールタイプを持つスキャン実行ポリシーは、常に`skip_ci`オプションを無視します。スケジュールされたスキャンは、最終コミットメッセージに`[skip ci]`（またはそのバリエーション）が表示されているかどうかにかかわらず、設定された時刻に実行されます。これにより、CI/CDパイプラインがスキップされている場合でも、セキュリティスキャンが予測可能なスケジュールで実行されることが保証されます。

### `no_pipeline`型 {#no_pipeline-type}

スキャン実行ポリシーは、誰が`[no_pipeline]`ディレクティブを使用できるかを制御します。`[no_pipeline]`を使用できる特定のユーザーまたはサービスアカウントを指定すると同時に、重要なセキュリティとコンプライアンスのチェックが確実に実行されるようにすることができます。

`no_pipeline`キーワードを使用して、ユーザーがプッシュ時にパイプラインを作成しないように`no_pipeline`ディレクティブを適用することを許可されているかどうかを指定します。キーワードを指定しなかった場合、`no_pipeline`ディレクティブは無視され、すべてのユーザーはパイプライン実行ポリシーをバイパスできません。

| フィールド                   | 型     | 使用可能な値          | 説明 |
|-------------------------|----------|--------------------------|-------------|
| `allowed` | `boolean`   | `true`、`false` | パイプライン実行ポリシーが適用されたパイプラインで、`no_pipeline`ディレクティブの使用を許可（`true`）または禁止（`false`）するフラグ。 |
| `allowlist`             | `object` | `users` | `allowed`フラグに関係なく、`no_pipeline`ディレクティブの使用が常に許可されるユーザーを指定します。`users:`の後に、ユーザーIDを表す`id`キーを含んだオブジェクトの配列を指定します。 |

> [!note] `schedule`ルールタイプを持つスキャン実行ポリシーは、常に`no_pipeline`オプションを無視します。スケジュールされたスキャンは、最終コミットメッセージに`[no_pipeline]`（またはそのバリエーション）が表示されているかどうかにかかわらず、設定された時刻に実行されます。これにより、CI/CDパイプラインが作成されない場合でも、セキュリティスキャンが予測可能なスケジュールで実行されることが保証されます。

## `pipeline`ルールタイプ {#pipeline-rule-type}

{{< history >}}

- `branch_type`フィールド:
  - GitLab 16.1で`security_policies_branch_type`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/404774)されました。
  - GitLab 16.2で一般提供。機能フラグ`security_policies_branch_type`は削除されました。
- `branch_exceptions`フィールド:
  - GitLab 16.3で`security_policies_branch_exceptions`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418741)されました。
  - GitLab 16.5で一般提供。機能フラグ`security_policies_branch_exceptions`は削除されました。
- `pipeline_sources`フィールドと`branch_type`オプション`target_default`および`target_protected`:
  - GitLab 18.2で`flexible_scan_execution`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/541689)されました。
  - [GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/issues/541689) (GitLab 18.3)。
  - GitLab 18.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/541689)になりました。機能フラグ`flexible_scan_execution`は削除されました。

{{< /history >}}

このルールは、選択したブランチに対してパイプラインが実行されるたびに、定義されたアクションを適用します。

| フィールド | 型 | 必須 | 使用可能な値 | 説明 |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | true | `pipeline` | ルールのタイプ。 |
| `branches` <sup>1</sup> | `array`の`string` | `branch_type`フィールドが存在しない場合はtrue | `*`またはブランチ名 | 指定されたポリシーが適用されるブランチ（ワイルドカードをサポート）。マージリクエスト承認ポリシーとの互換性のため、フィーチャーブランチおよびデフォルトブランチにスキャンを含めるには、すべてのブランチをターゲットにする必要があります。 |
| `branch_type` <sup>1</sup> | `string` | `branches`フィールドが存在しない場合はtrue | `default`、`protected`、`all`、`target_default`<sup>2</sup>、または`target_protected`<sup>2</sup> | 指定されたポリシーが適用されるブランチのタイプ。 |
| `branch_exceptions` | `array`の`string` | false |  ブランチ名 | このルールから除外するブランチ。 |
| `pipeline_sources` <sup>2</sup> | `array`の`string` | false | `api`、`chat`、`external`、`external_pull_request_event`、`merge_request_event`<sup>3</sup>、`pipeline`、`push`<sup>3</sup>、`schedule`、`trigger`、`unknown`、`web` | スキャン実行ジョブがいつトリガーされるかを決定するパイプラインソース。詳細については、[ドキュメント](../../../ci/jobs/job_rules.md#ci_pipeline_source-predefined-variable)を参照してください。 |

1. `branches`または`branch_type`のいずれかを指定する必要がありますが、両方を指定することはできません。
1. 一部のオプションは、`flexible_scan_execution`機能フラグが有効な場合にのみ利用できます。詳細については、履歴を参照してください。
1. `branch_type`オプション`target_default`または`target_protected`が指定されている場合、`pipeline_sources`フィールドは`merge_request_event`および`push`フィールドのみをサポートします。

## `schedule`ルールタイプ {#schedule-rule-type}

{{< history >}}

- 新しい`branch_type`フィールド:
  - GitLab 16.1で`security_policies_branch_type`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/404774)されました。
  - GitLab 16.2で一般提供。機能フラグが削除されました。
- 新しい`branch_exceptions`フィールド:
  - GitLab 16.3で`security_policies_branch_exceptions`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418741)されました。
  - GitLab 16.5で一般提供。機能フラグが削除されました。
- パイプラインを作成するためのスケジュールされたスキャンに対する新しい`scan_execution_pipeline_worker`ワーカー:
  - GitLab 16.11で[フラグ](../../../administration/feature_flags/_index.md)と共に[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147691)。
  - GitLab.comでGitLab 17.5で[有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/451890)されました。
  - GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/451890)になりました。機能フラグ`scan_execution_pipeline_worker`は削除されました。
- 新しいアプリケーション設定`security_policy_scheduled_scans_max_concurrency`:
  - GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152855)されました。並行処理制限は、`scan_execution_pipeline_worker`と`scan_execution_pipeline_concurrency_control`の両方が有効な場合に適用されます。
  - GitLab 17.11で新しいアプリケーション設定`security_policy_scheduled_scans_max_concurrency`を[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178892)しました。
- スキャン実行スケジュールジョブの並行処理制限:
  - GitLab 17.3で`scan_execution_pipeline_concurrency_control`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158636)されました。
  - GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/463802)になりました。機能フラグ`scan_execution_pipeline_concurrency_control`は削除されました。

{{< /history >}}

> [!warning] GitLab 16.1以前では、[直接転送](../../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)をスケジュールされたスキャン実行ポリシーと一緒に使用しないでください。直接転送を使用する必要がある場合は、まずGitLab 16.2にアップグレードし、適用しているプロジェクトでセキュリティポリシーボットが有効になっていることを確認してください。

`schedule`ルールタイプを使用して、セキュリティスキャナーをスケジュールで実行します。

スケジュールされたパイプライン:

- ポリシーで定義されたスキャナーのみを実行し、プロジェクトの`.gitlab-ci.yml`ファイルで定義されたジョブは実行しません。
- `cadence`フィールドで定義されたスケジュールに従って実行します。
- プロジェクト内の`security_policy_bot`ユーザーアカウントの下で実行され、ゲストロールと、パイプラインを作成し、CI/CDジョブからリポジトリのコンテンツを読み取りする権限を持ちます。このアカウントは、ポリシーがグループまたはプロジェクトにリンクされるときに作成されます。
- GitLab.comでは、スキャン実行ポリシーにおける最初の10個の`schedule`ルールのみが適用されます。制限を超えるルールは効果がありません。

| フィールド      | 型 | 必須 | 使用可能な値 | 説明 |
|------------|------|----------|-----------------|-------------|
| `type`     | `string` | true | `schedule` | ルールのタイプ。 |
| `branches` <sup>1</sup> | `array`の`string` | `branch_type`または`agents`フィールドのいずれかが存在しない場合はtrue | `*`またはブランチ名 | 指定されたポリシーが適用されるブランチ（ワイルドカードをサポート）。 |
| `branch_type` <sup>1</sup> | `string` | `branches`または`agents`フィールドのいずれかが存在しない場合はtrue | `default`、`protected`、または`all` | 指定されたポリシーが適用されるブランチのタイプ。 |
| `branch_exceptions` | `array`の`string` | false |  ブランチ名 | このルールから除外するブランチ。 |
| `cadence`  | `string` | true | 制限付きオプションを持つCron式。例えば、`0 0 * * *`は毎日深夜（午前12:00）に実行されるスケジュールを作成します。 | スケジュールされた時刻を表す、空白で区切られた5つのフィールドを含む文字列。 |
| `timezone` | `string` | false | タイムゾーン識別子（例: `America/New_York`） | ケイデンスに適用するタイムゾーン。値はIANAタイムゾーンデータベース識別子である必要があります。 |
| `time_window` | `object` | false |  | スケジュールされたセキュリティスキャンの分散と期間の設定。 |
| `agents` <sup>1</sup>   | `object` | `branch_type`または`branches`フィールドのいずれかが存在しない場合はtrue  |  | [オペレーショナルコンテナスキャン](../../clusters/agent/vulnerabilities.md)が実行される[Kubernetes向けGitLabエージェント](../../clusters/agent/_index.md)の名前。オブジェクトキーは、GitLabのプロジェクト用に設定されたKubernetesエージェントの名前です。 |

1. `branches`、`branch_type`、または`agents`のいずれか1つのみを指定する必要があります。

### ケイデンス {#cadence}

`cadence`フィールドを使用して、ポリシーのアクションを実行したい時刻をスケジュールします。`cadence`フィールドは[Cron構文](../../../topics/cron/_index.md)を使用しますが、いくつかの制限があります:

- 以下のタイプのCron構文のみがサポートされています:
  - 指定された時刻を中心とした1日1回のケイデンス（例: `0 18 * * *`）
  - 指定された曜日と時刻を中心とした1週間に1回のケイデンス（例: `0 13 * * 0`）
- 分と時間には、コンマ（,）、ハイフン（-）、またはステップ演算子（/）の使用はサポートされていません。これらの文字を使用しているスケジュールされたパイプラインはスキップされます。

`cadence`フィールドの値を選択する際には、以下を考慮してください:

- GitLab.comおよびGitLab Dedicatedの場合、タイミングはUTCに基づいており、GitLab Self-Managedの場合、GitLabホストのシステム時刻に基づいています。新しいポリシーをテストする際、パイプラインはローカルタイムゾーンではなくサーバーのタイムゾーンでスケジュールされているため、不正確な時刻に実行されているように見える場合があります。
- スケジュールされたパイプラインは、作成に必要なリソースが利用可能になるまで開始されません。言い換えれば、パイプラインはポリシーで指定されたタイミングで正確に開始されない可能性があります。

`agents`フィールドで`schedule`ルールタイプを使用する場合:

- Kubernetes向けGitLabエージェントは30秒ごとに適用可能なポリシーがあるかどうかを確認します。エージェントがポリシーを見つけると、スキャンは定義された`cadence`ケイデンスに従って実行されます。
- Cron式はKubernetesエージェントポッドのシステム時間を使用して評価されます。

`branches`フィールドで`schedule`ルールタイプを使用する場合:

- Cronワーカーは15分間隔で実行され、前の15分間にスケジュールされていたすべてのパイプラインを開始します。したがって、スケジュールされたパイプラインは最大15分のオフセットで実行できます。
- 大量のプロジェクトまたはブランチに対してポリシーが適用される場合、ポリシーはバッチで処理され、すべてのパイプラインを作成するのに時間がかかることがあります。

![スケジュールされたセキュリティスキャンが潜在的な遅延を伴って処理および実行される様子を示す図](img/scheduled_scan_execution_policies_diagram_v18_04.png)

### `agent`スキーマ {#agent-schema}

[`schedule`ルールタイプ](#schedule-rule-type)で`agents`オブジェクトを定義するには、このスキーマを使用します。

| フィールド        | 型                | 必須 | 説明 |
|--------------|---------------------|----------|-------------|
| `namespaces` | `array`の`string` | true | スキャンされるネームスペース。空の場合、すべてのネームスペースがスキャンされます。 |

#### `agent`の例 {#agent-example}

```yaml
- name: Enforce container scanning in cluster connected through my-gitlab-agent for default and kube-system namespaces
  enabled: true
  rules:
  - type: schedule
    cadence: '0 10 * * *'
    agents:
      <agent-name>:
        namespaces:
        - 'default'
        - 'kube-system'
  actions:
  - scan: container_scanning
```

スケジュールルールのキーは次のとおりです:

- `cadence`（必須）: スキャンが実行される時期の[Cron式](../../../topics/cron/_index.md)。
- `agents:<agent-name>`（必須）: スキャンに使用するエージェントの名前。
- `agents:<agent-name>:namespaces`（オプション）: スキャンするKubernetesネームスペース。省略された場合、すべてのネームスペースがスキャンされます。

### `time_window`スキーマ {#time_window-schema}

[`schedule`ルールタイプ](#schedule-rule-type)の`time_window`オブジェクトを使用して、スケジュールされたスキャンが時間とともにどのように分散されるかを定義します。`time_window`は、ポリシーエディタのYAMLモードでのみ設定することができます。

| フィールド          | 型      | 必須 | 説明                                                                                                                                                                          |
|----------------|-----------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `distribution` | `string`  | true     | スケジュールされたスキャンの分散パターン。`random`のみをサポートし、スキャンは`time_window`の`value`キーによって定義された間隔でランダムに分散されます。 |
| `value`        | `integer` | true     | スケジュールされたスキャンが実行されるべき秒単位のタイムウィンドウ。3600（1時間）から2629746（約30日）の間の値を入力します。                                               |

#### `time_window`の例 {#time_window-example}

```yaml
- name: Enforce container scanning with a time window of 1 hour
  enabled: true
  rules:
  - type: schedule
    cadence: '0 10 * * *'
    time_window:
      value: 3600
      distribution: random
  actions:
  - scan: container_scanning
```

### 大規模プロジェクト向けのスケジュールされたパイプラインを最適化する {#optimize-scheduled-pipelines-for-projects-at-scale}

ポリシーが複数のプロジェクトとブランチにわたってスケジュールされたパイプラインを適用すると、パイプラインは同時に実行されます。各プロジェクトでスケジュールされたパイプラインが最初に実行されると、そのプロジェクトのスケジュールを実行する責任を負うセキュリティボットユーザーが作成されます。

大規模プロジェクトのパフォーマンスを最適化するには:

- 一部のプロジェクトから開始し、スケジュールされたスキャン実行ポリシーを段階的にロールアウトします。セキュリティポリシースコープを活用して、特定のグループ、プロジェクト、または指定されたコンプライアンスフレームワークラベルを含むプロジェクトをターゲットにすることができます。
- `tag`タグが指定されたRunnerでスケジュールを実行するようにポリシーを設定することができます。他のRunnerへの影響を軽減するために、ポリシーから適用されるスケジュールを処理するために各プロジェクトに専用のRunnerを設定することを検討してください。
- 本番環境にデプロイする前に、ステージングまたはそれより低い環境で実装をテストしてください。パフォーマンスをモニタリングし、結果に基づいてロールアウト計画を調整してください。

### スケジュールされたスキャン実行ポリシーの最大スケジュール期間を設定する {#configuring-the-maximum-scheduling-timespan-for-scheduled-scan-execution-policies}

スケジュールされたスキャン実行ポリシーは、`cadence`フィールドとCron式を使用して月次スケジュールをサポートしています。`time_window`を最大2629746秒（約30日）まで設定することで、その期間内にスキャンをランダムに分散できます。

例えば、30日間の分散ウィンドウで月次スケジュールされたスキャンをスケジュールするには:

```yaml
rules:
  - type: schedule
    cadence: '0 0 1 * *'  # Run on the first day of each month
    time_window:
      value: 2592000  # 30 days in seconds
      distribution: random
```

#### インスタンスのダウンタイム中のスケジュールされたスキャンを理解する {#understanding-scheduled-scans-during-instance-downtimes}

スケジュールされたスキャンは、次回の実行時刻を追跡します。スキャンが成功すると、システムは次回のスキャンがいつ実行されるべきかを更新します。GitLabインスタンスがスケジュールされたスキャン時刻に利用できない場合（メンテナンス、停止、または再起動のため）、システムはすでに実行されるべきだったが実行されていないスキャンを識別し、インスタンスが利用可能になったときにパイプラインを作成します。

#### スケジュールされたスキャンを含むプロジェクトを削除する {#deleting-projects-with-scheduled-scans}

プロジェクトを削除すると、関連するすべてのスケジュールされたスキャンも削除されます。削除されたプロジェクトではパイプラインは実行されません。

#### 実行中のスケジュールされたスキャンをキャンセルする {#canceling-a-running-scheduled-scan}

スケジュールされたスキャンをキャンセルするには、2つのオプションがあります:

- 個別のパイプラインをキャンセルする: プロジェクトでジョブをキャンセルするのに必要な権限がある場合、パイプラインビューから直接実行中のパイプラインをキャンセルできます。
- **Disable the policy**: ポリシーエディタで`enabled: false`を設定して、スキャン実行ポリシーを無効にします。すでに実行中、または次の15分以内（約）に実行がスケジュールされているスキャンは、引き続き実行される可能性があります。

#### 大規模デプロイメントに関する推奨事項 {#recommendations-for-large-scale-deployments}

多くのプロジェクトにわたってスケジュールされたスキャン実行ポリシーをデプロイする場合、以下の推奨事項を考慮してください:

- 段階的なロールアウトを使用する: 少数のプロジェクトから開始し、徐々にプロジェクトを追加します。[コンプライアンスフレームワークラベル](../../project/working_with_projects.md#add-a-compliance-framework-to-a-project)を使用して、ポリシーを特定のプロジェクトグループにスコープします。
- `time_window`を設定する: スケジュールされたポリシーで常に`time_window`パラメータを設定してください。これがないと、すべてのパイプラインが同じ時刻にスケジュールされ、パフォーマンスの問題やリソース競合を引き起こす可能性があります。
- ステージングでテストする: 本番環境にデプロイする前に、ステージングまたはそれより低い環境でポリシーの設定を検証してください。パフォーマンスをモニタリングし、結果に基づいて調整してください。
- Runner容量を考慮する: Runnerへの影響は、ポリシーの設定、Runnerの可用性、およびGitLabインスタンスのデプロイに依存します。特定のタグを持つRunnerを使用するようにポリシーを設定することで、負荷を分散します。

スケジュールされたスキャンの最適化に関する詳細については、[スケジュールされたパイプラインを大規模プロジェクト向けに最適化する](#optimize-scheduled-pipelines-for-projects-at-scale)を参照してください。

### 並行処理制御 {#concurrency-control}

GitLabは、`time_window`プロパティを設定すると並行処理制御を適用します。

並行処理制御は、ポリシーで定義された[`time_window`設定](#time_window-schema)に従ってスケジュールされたパイプラインを分散します。

## `scan`アクションタイプ {#scan-action-type}

{{< history >}}

- スキャン実行ポリシー変数の優先順位:
  - GitLab 16.7で`security_policies_variables_precedence`という[フラグ](../../../administration/feature_flags/_index.md)と共に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/424028)されました。デフォルトでは有効になっています。
  - GitLab 16.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/435727)になりました。機能フラグ`security_policies_variables_precedence`は削除されました。
- 指定されたアクションに対するセキュリティテンプレートの選択:
  - GitLab 17.1で、`scan_execution_policies_with_latest_templates`という[機能フラグ](../../../administration/feature_flags/_index.md)と共にプロジェクト向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/415427)。デフォルトでは無効になっています。
  - GitLab 17.2で、`scan_execution_policies_with_latest_templates_group`という[機能フラグ](../../../administration/feature_flags/_index.md)と共にグループ向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/468981)。デフォルトでは無効になっています。
  - GitLab 17.2で[GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/461474)と[GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/468981)で有効になりました。
  - GitLab 17.3で一般提供。機能フラグ`scan_execution_policies_with_latest_templates`および`scan_execution_policies_with_latest_templates_group`は削除されました。

{{< /history >}}

このアクションは、定義されたポリシー内の少なくとも1つのルールの条件が満たされた場合に、選択された`scan`を追加パラメータと共に実行します。

| フィールド | 型 | 使用可能な値 | 説明 |
|-------|------|-----------------|-------------|
| `scan` | `string` | `sast`、`sast_iac`、`dast`、`secret_detection`、`container_scanning`、`dependency_scanning` | アクションのタイプ。 |
| `site_profile` | `string` | 選択された[DASTサイトスキャンプロファイル](../dast/profiles.md#site-profile)の名前。 | DASTスキャンを実行するDASTサイトプロファイル。このフィールドは、`scan`タイプが`dast`の場合にのみ設定する必要があります。 |
| `scanner_profile` | `string`または`null` | 選択された[DASTスキャナースキャンプロファイル](../dast/profiles.md#scanner-profile)の名前。 | DASTスキャンを実行するDASTスキャナープロファイル。このフィールドは、`scan`タイプが`dast`の場合にのみ設定する必要があります。|
| `variables` | `object` | | 選択されたスキャンに適用および強制するための`key: value`ペアの配列として提供されるCI/CD変数のセット。`key`は変数名であり、その`value`は文字列として提供されます。このパラメータは、指定されたスキャンに対してGitLab CI/CDジョブがサポートする任意の変数をサポートします。 |
| `tags` | `array`の`string` | | ポリシーのRunnerタグのリスト。ポリシージョブは、指定されたタグを持つRunnerによって実行されます。 |
| `template` | `string` | `default`または`latest` | 適用するCI/CDテンプレートバージョン。`latest`バージョンは破壊的な変更を導入する可能性があり、マージリクエストに関連する`pipeline_sources`のみをサポートします。詳細については、[セキュリティスキャンをカスタマイズする](../detect/security_configuration.md#customize-security-scanning)を参照してください。 |
| `scan_settings` | `object` | | 選択されたスキャンに適用および強制するための`key: value`ペアの配列として提供されるスキャン設定のセット。`key`は設定名であり、その`value`はブール値または文字列として提供されます。このパラメータは、[スキャン設定](#scan-settings)で定義されている設定をサポートします。 |

> [!note]プロジェクトでマージリクエストパイプラインが有効になっている場合、適用される各スキャンのポリシーで`AST_ENABLE_MR_PIPELINES` CI/CD変数を`"true"`に設定する必要があります。マージリクエストパイプラインでのセキュリティスキャンツールの使用に関する詳細については、[セキュリティスキャンドキュメント](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)を参照してください。

### スキャナーの動作 {#scanner-behavior}

一部のスキャナーは、通常のCI/CDパイプラインスキャンとは異なり、`scan`アクションで異なる動作をします:

- 静的アプリケーションセキュリティテスト（SAST）: リポジトリに[SASTでサポートされるファイル](../sast/_index.md#supported-languages-and-frameworks)が含まれている場合にのみ実行されます。
- シークレット検出:
  - デフォルトでは、デフォルトルールセット内のルールのみがサポートされています。
  - ルールセットの設定をカスタマイズするには、以下のいずれかの方法があります:
    - デフォルトルールセットを変更します。スキャン実行ポリシーを使用して、`SECRET_DETECTION_RULESET_GIT_REFERENCE` CI/CD変数を指定します。デフォルトでは、これはデフォルトルールセットからのルールのみをオーバーライドまたは無効にする[リモート設定ファイル](../secret_detection/pipeline/configure.md#with-a-remote-ruleset)を指します。この変数のみを使用しても、デフォルトのルールセットを拡張または置換することはサポートされていません。
    - デフォルトルールセットを[拡張する](../secret_detection/pipeline/configure.md#extend-the-default-ruleset)か、[置換する](../secret_detection/pipeline/configure.md#replace-the-default-ruleset)か。スキャン実行ポリシーを使用して、`SECRET_DETECTION_RULESET_GIT_REFERENCE`CI/CD変数と、[Gitパススルー](../secret_detection/pipeline/custom_rulesets_schema.md#passthrough-types)を使用するリモート設定ファイルを指定し、デフォルトルールセットを拡張または置換します。詳細なガイドについては、[中央管理されたパイプラインのシークレット検出設定を設定する方法](https://support.gitlab.com/hc/en-us/articles/18863735262364-How-to-set-up-a-centrally-managed-pipeline-secret-detection-configuration-applied-via-Scan-Execution-Policy)を参照してください。
  - `scheduled`スキャン実行ポリシーの場合、シークレット検出はデフォルトで最初に`historic`モード（`SECRET_DETECTION_HISTORIC_SCAN` = `true`）で実行されます。後続のすべてのスケジュールされたスキャンは、`SECRET_DETECTION_LOG_OPTIONS`が最後の実行と現在のSHA間のコミット範囲に設定されたデフォルトモードで実行されます。この動作は、スキャン実行ポリシーでCI/CD変数を指定することでオーバーライドできます。詳細については、[完全な履歴パイプラインシークレット検出](../secret_detection/pipeline/_index.md#run-a-historic-scan)を参照してください。
  - `triggered`スキャン実行ポリシーの場合、シークレット検出は、[`.gitlab-ci.yml`で手動で設定された](../secret_detection/pipeline/_index.md#edit-the-gitlab-ciyml-file-manually)通常のスキャンと同様に機能します。
- コンテナスキャン: `pipeline`ルールタイプ用に設定されたスキャンは、`agents`オブジェクトで定義されたエージェントを無視します。`agents`オブジェクトは`schedule`ルールタイプにのみ考慮されます。`agents`オブジェクトで提供される名前を持つエージェントは、プロジェクト用に作成および設定されている必要があります。

### DASTスキャンプロファイル {#dast-profiles}

動的アプリケーションセキュリティテスト（DAST）を適用する際には、以下の要件が適用されます:

- ポリシーのスコープ内のすべてのプロジェクトに対して、指定された[サイトプロファイル](../dast/profiles.md#site-profile)と[スキャナースキャンプロファイル](../dast/profiles.md#scanner-profile)が存在する必要があります。これらが利用できない場合、ポリシーは適用されず、代わりにエラーメッセージを含むジョブが作成されます。
- 有効なスキャン実行ポリシーでDASTサイトプロファイルまたはスキャンプロファイルが指定されている場合、そのプロファイルを変更または削除することはできません。プロファイルを編集または削除するには、まずポリシーエディタでポリシーを**無効**にするか、YAMLモードで`enabled: false`を設定する必要があります。
- スケジュールされたDASTスキャンでポリシーを設定する場合、セキュリティポリシープロジェクトのリポジトリ内のコミットの作成者は、スキャナーおよびサイトプロファイルにアクセスできる必要があります。そうしないと、スキャンは正常にスケジュールされません。

### スキャン設定 {#scan-settings}

以下の設定が`scan_settings`パラメータでサポートされています:

| 設定 | 型 | 必須 | 使用可能な値 | デフォルト | 説明 |
|-------|------|----------|-----------------|-------------|-----------|
| `ignore_default_before_after_script` | `boolean` | false | `true`、`false` | `false` | パイプライン設定内のデフォルトの`before_script`および`after_script`の定義をスキャンジョブから除外するかどうかを指定します。 |

## CI/CD変数 {#cicd-variables}

> [!warning]変数はGitリポジトリ内のプレーンテキストポリシー設定の一部として保存されるため、機密情報や認証情報を変数に保存しないでください。

スキャン実行ポリシーで定義された変数は、標準の[CI/CD変数の優先順位](../../../ci/variables/_index.md#cicd-variable-precedence)に従います。

スキャン実行ポリシーが適用されるすべてのプロジェクトで、以下のCI/CD変数に事前設定された値が使用されます。ポリシーのみがこれらの値をオーバーライドできます。グループまたはプロジェクトのCI/CD変数はこれらの変数をオーバーライドできません:

```plaintext
DS_EXCLUDED_PATHS: spec, test, tests, tmp
SAST_EXCLUDED_PATHS: spec, test, tests, tmp
SECRET_DETECTION_EXCLUDED_PATHS: ''
SECRET_DETECTION_HISTORIC_SCAN: false
SAST_EXCLUDED_ANALYZERS: ''
DEFAULT_SAST_EXCLUDED_PATHS: spec, test, tests, tmp
DS_EXCLUDED_ANALYZERS: ''
SECURE_ENABLE_LOCAL_CONFIGURATION: true
```

GitLab 16.9以前:

- `_EXCLUDED_PATHS`で終わるCI/CD変数がポリシーで宣言されていた場合、それらの値はグループまたはプロジェクトのCI/CD変数によってオーバーライドされる可能性がありました。
- `_EXCLUDED_ANALYZERS`で終わるCI/CD変数がポリシーで宣言されていた場合、それらの値は、ポリシー、グループ、またはプロジェクトのどこで定義されていても無視されました。

## ポリシーのスコープスキーマ {#policy-scope-schema}

ポリシーの適用をカスタマイズするには、ポリシーのスコープを定義して、指定したプロジェクト、グループ、またはコンプライアンスフレームワークのラベルを含めるか、除外します。詳細については、[スコープ](_index.md#configure-the-policy-scope)を参照してください。

> [!note] `policy_scope`フィールドを空のコレクション（例: `including: []`）に設定することは、フィールドを省略することと同じとみなされ、そのスコープディメンションのすべてのプロジェクトにポリシーが適用されます。ポリシーを完全に無効にするには、`enabled: false`を使用します。詳細については、[`policy_scope`の空のコレクション](_index.md#empty-collections-in-policy_scope)を参照してください。

## ポリシー更新の伝播 {#policy-update-propagation}

ポリシーを更新すると、その更新方法によって変更の伝播が異なります:

- [セキュリティポリシープロジェクト](../_index.md)でのマージリクエストを使用する場合: マージリクエストがマージされた後、すぐに変更が有効になります。
- `.gitlab/security-policies/policy.yml`への直接コミット: 変更が有効になるまでに最大10分かかることがあります。

### トリガー動作 {#triggering-behavior}

パイプラインベースのポリシー（`type: pipeline`）への更新は、即時パイプラインをトリガーせず、すでに進行中のパイプラインにも影響を与えません。ポリシーの変更は、将来のパイプライン実行に適用されます。

スケジュールされたポリシーのルールを、そのスケジュールされたケイデンス外で手動でトリガーすることはできません。

## セキュリティポリシープロジェクトの例 {#example-security-policy-project}

[セキュリティポリシープロジェクト](enforcement/security_policy_projects.md)に保存されている`.gitlab/security-policies/policy.yml`ファイルで、この例を使用できます:

```yaml
---
scan_execution_policy:
- name: Enforce DAST in every release pipeline
  description: This policy enforces pipeline configuration to have a job with DAST scan for release branches
  enabled: true
  rules:
  - type: pipeline
    branches:
    - release/*
  actions:
  - scan: dast
    scanner_profile: Scanner Profile A
    site_profile: Site Profile B
- name: Enforce DAST and secret detection scans every 10 minutes
  description: This policy enforces DAST and secret detection scans to run every 10 minutes
  enabled: true
  rules:
  - type: schedule
    branches:
    - main
    cadence: "*/10 * * * *"
  actions:
  - scan: dast
    scanner_profile: Scanner Profile C
    site_profile: Site Profile D
  - scan: secret_detection
    scan_settings:
      ignore_default_before_after_script: true
- name: Enforce secret detection and container scanning in every default branch pipeline
  description: This policy enforces pipeline configuration to have a job with secret detection and container scanning scans for the default branch
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: secret_detection
  - scan: sast
    variables:
      SAST_EXCLUDED_ANALYZERS: brakeman
  - scan: container_scanning
```

この例では: 

- `release/*`ワイルドカードに一致するブランチ（例: `release/v1.2.1`ブランチ）で実行されるすべてのパイプラインの場合
  - DASTスキャンは`Scanner Profile A`および`Site Profile B`で実行されます。
- DASTおよびシークレット検出スキャンは10分ごとに実行されます。DASTスキャンは`Scanner Profile C`および`Site Profile D`で実行されます。
- シークレット検出、コンテナスキャン、およびSASTスキャンは、`main`ブランチで実行されるすべてのパイプラインに対して実行されます。SASTスキャンは、`SAST_EXCLUDED_ANALYZER`変数が`"brakeman"`に設定されて実行されます。

## スキャン実行ポリシーエディタの例 {#example-for-scan-execution-policy-editor}

[スキャン実行ポリシーエディタ](#scan-execution-policy-editor)のYAMLモードでこの例を使用できます。これは、前の例の単一のオブジェクトに対応します。

```yaml
name: Enforce secret detection and container scanning in every default branch pipeline
description: This policy enforces pipeline configuration to have a job with secret detection and container scanning scans for the default branch
enabled: true
rules:
  - type: pipeline
    branches:
      - main
actions:
  - scan: secret_detection
  - scan: container_scanning
```

## 重複スキャンを避ける {#avoiding-duplicate-scans}

プロジェクトの`.gitlab-ci.yml`ファイルにスキャンジョブを含めると、スキャン実行ポリシーによって同じタイプのスキャナーが複数回実行される可能性があります。

スキャナーは異なる変数と設定で複数回実行できるため、重複スキャンは意図的に実行されます。例えば、ポリシーを通じて適用されるものとは異なる変数でSASTスキャンを実行する場合があります。このシナリオでは、2つのSASTジョブがパイプラインで実行されます:

- カスタム変数を使用するもの。
- ポリシーによって適用される変数を使用するもの。

重複スキャンを防ぐには、プロジェクトの`.gitlab-ci.yml`ファイルからいずれかのスキャンを削除するか、変数を持つローカルジョブをスキップします。ジョブをスキップしても、スキャン実行ポリシーで定義されたセキュリティジョブの実行は妨げられません。

変数を持つスキャンジョブをスキップするには、以下を使用できます:

- `SAST_DISABLED: "true"`を使用してSASTジョブをスキップします。
- `DAST_DISABLED: "true"`を使用してDASTジョブをスキップします。
- `CONTAINER_SCANNING_DISABLED: "true"`を使用してコンテナスキャンジョブをスキップします。
- `SECRET_DETECTION_DISABLED: "true"`を使用してシークレット検出ジョブをスキップします。
- `DEPENDENCY_SCANNING_DISABLED: "true"`を使用して依存関係スキャンジョブをスキップします。

ジョブをスキップできるすべての変数の概要については、[CI/CD変数ドキュメント](../../../topics/autodevops/cicd_variables.md#job-skipping-variables)を参照してください。

## トラブルシューティング {#troubleshooting}

スキャン実行ポリシーを使用しているときに、以下のイシューに遭遇する可能性があります。

### スキャン実行ポリシーパイプラインが作成されない {#scan-execution-policy-pipelines-are-not-created}

スキャン実行ポリシーが、期待どおりに`type: pipeline`で定義されたパイプラインを作成しない場合、プロジェクトの`.gitlab-ci.yml`ファイルに、パイプラインの作成を妨げる[`workflow:rules`](../../../ci/yaml/workflow.md)がある可能性があります。

`type: pipeline`ルールを持つスキャン実行ポリシーは、マージされたCI/CD設定に依存してパイプラインを作成します。プロジェクトの`workflow:rules`がパイプライン全体をフィルタリングする場合、スキャン実行ポリシーはパイプラインを作成できません。

例えば、以下の`workflow:rules`設定は、すべてのパイプラインが作成されるのを防ぎます:

```yaml
# .gitlab-ci.yml
workflow:
  rules:
  - if: $CI_PIPELINE_SOURCE == "push"
    when: never
```

解決策:

このイシューを解決するには、以下のいずれかのオプションを使用できます:

- プロジェクトの`.gitlab-ci.yml`ファイル内の`workflow:rules`を修正して、スキャン実行ポリシーがパイプラインを作成できるようにします。`$CI_PIPELINE_SOURCE`変数を使用して、ポリシーによってトリガーされるパイプラインを識別できます:

  ```yaml
  workflow:
    rules:
    - if: $CI_PIPELINE_SOURCE == "security_orchestration_policy"
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
  ```

- `type: pipeline`ルールの代わりに`type: schedule`ルールを使用します。スケジュールされたスキャン実行ポリシーは`workflow:rules`の影響を受けず、定義されたスケジュールに従ってパイプラインを作成します。
- CI/CDパイプラインでセキュリティスキャンがいつ、どのように実行されるかをより細かく制御するには、[パイプライン実行ポリシー](pipeline_execution_policies.md)を使用します。
