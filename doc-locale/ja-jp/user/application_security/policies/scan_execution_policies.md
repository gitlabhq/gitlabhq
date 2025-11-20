---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: スキャン実行ポリシー
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- スキャン実行ポリシーエディターでのカスタムCI/CD変数のサポートがGitLab 16.2で[導入されました](https://gitlab.com/groups/gitlab-org/-/epics/9566)。
- 既存のGitLab CI/CD設定を持つプロジェクトに対するスキャン実行ポリシーの適用が、GitLab 16.2で`scan_execution_policy_pipelines`という[機能フラグ](../../../administration/feature_flags/_index.md)を[導入](https://gitlab.com/groups/gitlab-org/-/epics/6880)されました。機能フラグ`scan_execution_policy_pipelines`は、GitLab 16.5で削除されました。
- スキャン実行ポリシーにおける定義済み変数のオーバーライドが、GitLab 16.10で`allow_restricted_variables_at_policy_level`という[機能フラグ](../../../administration/feature_flags/_index.md)を[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440855)されました。デフォルトでは有効になっています。GitLab 17.5で機能フラグ`allow_restricted_variables_at_policy_level`は削除されました。

{{< /history >}}

スキャン実行ポリシーは、デフォルトまたは最新の[security CI/CD templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Jobs)に基づいてGitLabセキュリティスキャンを適用します。パイプラインの一部として、または指定されたスケジュールでスキャン実行ポリシーをデプロイできます。

スキャン実行ポリシーは、セキュリティポリシープロジェクトにリンクされ、ポリシーのスコープ内にあるすべてのプロジェクトに適用されます。`.gitlab-ci.yml`ファイルがないプロジェクト、またはAutoDevOpsが無効になっているプロジェクトの場合、セキュリティポリシーは暗黙的に`.gitlab-ci.yml`ファイルを作成します。`.gitlab-ci.yml`ファイルは、シークレット検出、静的な解析、またはプロジェクトでのビルドを必要としない他のスキャナーを実行するポリシーが常に実行され、適用されるようにします。

スキャン実行ポリシーとパイプライン実行ポリシーの両方で、複数のプロジェクトにわたるGitLabセキュリティスキャンを設定して、セキュリティとコンプライアンスを管理できます。スキャン実行ポリシーは、より迅速に設定できますが、カスタマイズはできません。次のいずれかのケースに該当する場合は、代わりに[パイプライン実行ポリシー](pipeline_execution_policies.md)を使用してください:

- 高度な設定が必要な場合。
- カスタムCI/CDジョブまたはスクリプトを適用する場合。
- 適用されたCI/CDジョブを介して、サードパーティのセキュリティスキャンを有効にする場合。

## スキャン実行ポリシーを作成 {#create-a-scan-execution-policy}

スキャン実行ポリシーを作成するには、次のいずれかのリソースを使用できます:

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>ビデオチュートリアルについては、[GitLabでセキュリティスキャンポリシーを設定する方法](https://youtu.be/ZBcqGmEwORA?si=aeT4EXtmHjosgjBY)をご覧ください。
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> GitLab CI/CD設定がないプロジェクトで[スキャン実行ポリシーを適用](https://www.youtube.com/watch?v=sUfwQQ4-qHs)する方法の詳細をご覧ください。
- スキャン実行ポリシーを作成する方法については、[チュートリアル: スキャン実行ポリシーを設定する](../../../tutorials/scan_execution_policy/_index.md)を参照してください

## 制限事項 {#restrictions}

- 各ポリシーに割り当てることができるルールは最大5つです。
- 各セキュリティポリシープロジェクトに割り当てることができるスキャン実行ポリシーは最大5つです。
- ローカルプロジェクトのYAMLファイルは、スキャン実行ポリシーをオーバーライドできません。これらのポリシーは、プロジェクトのCI/CD設定で同じジョブ名を使用している場合でも、パイプラインに定義されたすべての設定よりも優先されます。
- スケジュールされたポリシー（`type: schedule`）は、スケジュールされた`cadence`に従ってのみ実行されます。ポリシーを更新しても、すぐにスキャンがトリガーされるわけではありません。
- （ポリシーエディタではなく、コミットまたはプッシュで）YAML設定ファイルに直接加えたポリシーの更新がシステム全体に反映されるまでに、最大10分かかる場合があります。（この制限に対する提案された変更については、[issue 512615](https://gitlab.com/gitlab-org/gitlab/-/issues/512615)を参照してください。）

## ジョブ {#jobs}

DASTスキャン以外のスキャンのポリシージョブは、パイプラインの`test`ステージに作成されます。`test`ステージをデフォルトのパイプラインから削除すると、ジョブは代わりに`scan-policies`ステージで実行されます。このステージは、存在しない場合、評価時にCI/CDパイプラインに挿入されます。`build`ステージが存在する場合、`scan-policies`は`build`ステージの直後に挿入され、そうでない場合はパイプラインの先頭に挿入されます。DASTスキャンは常に`dast`ステージで実行されます。`dast`ステージが存在しない場合は、`dast`ステージがパイプラインの最後に挿入されます。

ジョブ名の競合を避けるために、ハイフンと数字がジョブ名に追加されます。各番号は、各ポリシーアクションの一意の値です。たとえば、`secret-detection`は`secret-detection-1`になります。

## スキャン実行ポリシーエディタ {#scan-execution-policy-editor}

{{< history >}}

- `Merge Request Security Template`はGitLab 18.2で[フラグ](../../../administration/feature_flags/_index.md)の`flexible_scan_execution`という名前で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/541689)。デフォルトでは無効になっています。
- `Merge Request Security Template`[GitLab.com、GitLab Self-Managed、GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/541689)で有効（GitLab 18.3）。

{{< /history >}}

スキャン実行ポリシーエディターを使用して、スキャン実行ポリシーを作成または編集します。

前提要件: 

- デフォルトでは、グループ、サブグループ、またはプロジェクトオーナーのみが、セキュリティポリシープロジェクトの作成または割り当てに必要な[権限](../../permissions.md#application-security)を持っています。または、[セキュリティポリシーリンクを管理](../../custom_roles/abilities.md#security-policy-management)する権限を持つカスタムロールを作成することもできます。

最初のスキャン実行ポリシーを作成する際に、最も一般的なユースケースをすぐに開始できるように、テンプレートが用意されています:

- マージリクエストセキュリティテンプレート

  - ユースケース: セキュリティスキャンは、すべてのコミットではなく、マージリクエストが作成されたときにのみ実行されるようにする必要がある。
  - 使用するケース: デフォルトまたは保護ブランチをターゲットとするソースブランチでセキュリティスキャンを実行する必要があるマージリクエストパイプラインを使用するプロジェクトの場合。
  - 最適な対象: すべてのブランチでのスキャンを回避することで、マージリクエスト承認ポリシーに準拠し、インフラストラクチャのコストを削減したいチーム。
  - パイプラインソース: 主にマージリクエストパイプライン。

- スケジュールされたスキャンテンプレート

  - ユースケース: の変更に関係なく、セキュリティスキャンをスケジュールに基づいて（毎日または毎週のように）自動的に実行する必要がある。
  - 使用するケース: 開発アクティビティーとは関係なく、定期的なケイデンスでのセキュリティスキャンの場合。
  - 最適な対象: コンプライアンスフレームワーク要件、ベースラインセキュリティモニタリング、またはコミットがまれなプロジェクト。
  - パイプラインソース: スケジュールされたパイプライン。

- リリースセキュリティテンプレートのマージ

  - ユースケース: すべての変更を`main`またはリリースブランチでセキュリティスキャンを実行する必要がある。
  - 使用するケース: リリース前、または保護ブランチで包括的なスキャンを必要とするプロジェクトの場合。
  - 最適な対象: リリースゲート型ワークフロー、本番環境デプロイ、または高度なセキュリティ環境。
  - パイプラインソース: 保護ブランチへのプッシュパイプライン、リリースパイプライン。

利用可能なテンプレートがニーズを満たしていない場合、またはよりカスタマイズされたスキャン実行ポリシーが必要な場合は、次のようにすることができます:

- **カスタム**オプションを選択し、カスタム要件で独自のスキャン実行ポリシーを作成します。
- [パイプライン実行ポリシー](pipeline_execution_policies.md)を使用して、セキュリティスキャンおよびCI適用のため、よりカスタマイズ可能なオプションにアクセスします。

ポリシーが完了したら、エディターの下部にある**マージリクエスト経由で設定**を選択して保存します。プロジェクトで設定されたセキュリティポリシープロジェクトのマージリクエストにリダイレクトされます。プロジェクトにリンクされていない場合は、セキュリティポリシープロジェクトが自動的に作成されます。エディターの下部にある**ポリシーの削除**を選択して、既存のポリシーをエディターインターフェースから削除できます。このアクションにより、`policy.yml`ファイルからポリシーを削除するマージリクエストが作成されます。

ほとんどのポリシー変更は、マージリクエストがマージされるとすぐに有効になります。既定のブランチに直接コミットされた変更は、マージリクエストの代わりに、ポリシーの変更が有効になるまでに最大10分かかります。

![スキャン実行ポリシーエディタ・ルールモード](img/scan_execution_policy_rule_mode_v17_5.png)

{{< alert type="note" >}}

DAST実行ポリシーの場合、ルールモードエディターでサイトプロファイルとスキャナープロファイルを適用する方法は、ポリシーの定義場所によって異なります:

- プロジェクトのポリシーの場合、ルールモードエディターで、プロジェクトですでに定義されているプロファイルのリストから選択します。
- グループのポリシーの場合、使用するプロファイルの名前を入力する必要があります。パイプラインエラーを防ぐために、一致する名前のプロファイルがグループのすべてのプロジェクトに存在する必要があります。

{{< /alert >}}

## スキャン実行ポリシーのスキーマ {#scan-execution-policies-schema}

スキャン実行ポリシーを使用したYAML設定は、スキャン実行ポリシースキーマに一致するオブジェクトの配列で構成されています。オブジェクトは`scan_execution_policy`キーの下にネストされています。`scan_execution_policy`キーの下に最大5つのポリシーを設定できます。最初の5つのポリシーの後に設定されたポリシーは適用されません。

新しいポリシーを保存すると、GitLabは[このJSONスキーマ](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json)に照らしてポリシーの内容を検証します。[JSON schemas](https://json-schema.org/)に精通していない場合は、以下のセクションと表で代替案を確認してください。

| フィールド | 型 | 必須 | 使用可能な値 | 説明 |
|-------|------|----------|-----------------|-------------|
| `scan_execution_policy` | スキャン実行ポリシーの`array` | はい |  | スキャン実行ポリシーのリスト（最大5つ） |

## スキャン実行ポリシーのスキーマ {#scan-execution-policy-schema}

{{< history >}}

- ポリシーあたりのアクション数の制限がGitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/472213)され、`scan_execution_policy_action_limit`（プロジェクトの場合）および`scan_execution_policy_action_limit_group`（グループの場合）という名前の[フラグ](../../../administration/feature_flags/_index.md)が付けられました。デフォルトでは無効になっています。
- ポリシーあたりのアクション数の制限がGitLab 18.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/535605)されました。機能フラグ`scan_execution_policy_action_limit`（プロジェクト用）および`scan_execution_policy_action_limit_group`（グループ用）が削除されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

| フィールド          | 型                                         | 必須 | 説明 |
|----------------|----------------------------------------------|----------|-------------|
| `name`         | `string`                                     | はい     | ポリシーの名前。最大255文字。 |
| `description`  | `string`                                     | いいえ    | ポリシーの説明。 |
| `enabled`      | `boolean`                                    | はい     | ポリシーを有効（`true`）または無効（`false`）にするフラグ。 |
| `rules`        | ルールの`array`                             | はい     | ポリシーが適用されるルールのリスト。 |
| `actions`      | アクションの`array`                           | はい     | ポリシーが適用するアクションのリスト。GitLab 18.0以降では最大10に制限されています。 |
| `policy_scope` | [`policy_scope`](_index.md#configure-the-policy-scope)の`object` | いいえ    | 指定したプロジェクト、グループ、またはコンプライアンスフレームワークラベルに基づいて、ポリシーのスコープを定義します。 |
| `skip_ci` | [`skip_ci`](#skip_ci-type)の`object` | いいえ | ユーザーが`skip-ci`ディレクティブを適用できるかどうかを定義します。 |

### `skip_ci`型 {#skip_ci-type}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/482952)されました。

{{< /history >}}

スキャン実行ポリシーは、`[skip ci]`ディレクティブを誰が使用できるかを制御します。`[skip ci]`を使用できる特定のユーザーまたはサービスアカウントを指定すると同時に、重要なセキュリティとコンプライアンスのチェックが確実に実行されるようにすることができます。

`skip_ci`キーワードを使用して、ユーザーが`skip_ci`ディレクティブを適用してパイプラインをスキップできるかどうかを指定します。キーワードを指定しなかった場合、`skip_ci`ディレクティブは無視され、すべてのユーザーはパイプライン実行ポリシーをバイパスできません。

| フィールド                   | 型     | 使用可能な値          | 説明 |
|-------------------------|----------|--------------------------|-------------|
| `allowed` | `boolean`   | `true`、`false` | パイプライン実行ポリシーが適用されたパイプラインで、`skip-ci`ディレクティブの使用を許可（`true`）または禁止（`false`）するフラグ。 |
| `allowlist`             | `object` | `users` | `allowed`フラグに関係なく、`skip-ci`ディレクティブの使用が常に許可されるユーザーを指定します。`users:`の後に、ユーザーIDを表す`id`キーを含んだオブジェクトの配列を指定します。 |

{{< alert type="note" >}}

ルールタイプ`schedule`を持つスキャン実行ポリシーは、常に`skip_ci`オプションを無視します。スケジュールされたスキャンは、最後のコミットメッセージに`[skip ci]`（またはそのバリエーション）が表示されているかどうかに関係なく、設定された時間に実行されます。これにより、CI/CDパイプラインがスキップされている場合でも、セキュリティスキャンが予測可能なスケジュールで確実に実行されます。

{{< /alert >}}

## `pipeline`ルールタイプ {#pipeline-rule-type}

{{< history >}}

- `branch_type`フィールドは、`security_policies_branch_type`という名前の[フラグ](../../../administration/feature_flags/_index.md)を付けて、GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/404774)されました。 GitLab 16.2で一般提供。機能フラグは削除されました。
- `branch_exceptions`フィールドは、`security_policies_branch_exceptions`という名前の[フラグ](../../../administration/feature_flags/_index.md)を付けて、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418741)されました。 GitLab 16.5で一般提供。機能フラグは削除されました。
- `pipeline_sources`フィールドと`branch_type`オプション`target_default`と`target_protected`は、`flexible_scan_execution`という名前の[フラグ](../../../administration/feature_flags/_index.md)を付けて、GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/541689)されました。
- `pipeline_sources`フィールドと`branch_type`オプション`target_default`と`target_protected`が、GitLab 18.3で[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/541689)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

このルールは、選択されたブランチに対してパイプラインが実行されるたびに、定義されたアクションを適用します。

| フィールド | 型 | 必須 | 使用可能な値 | 説明 |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | はい | `pipeline` | ルールの種類。 |
| `branches` <sup>1</sup> | `array`の`string` | `branch_type`フィールドが存在しない場合はtrue | `*`またはブランチの名前 | 指定されたポリシーが適用されるブランチ（ワイルドカードをサポート）。マージリクエスト承認ポリシーとの互換性のため、フィーチャーブランチとデフォルトブランチにスキャンを含めるには、すべてのブランチをターゲットにする必要があります |
| `branch_type` <sup>1</sup> | `string` | `branches`フィールドが存在しない場合はtrue | `default`、`protected`、`all`、`target_default` <sup>2</sup>、または`target_protected` <sup>2</sup> | 指定されたポリシーが適用されるブランチの種類。 |
| `branch_exceptions` | `array`の`string` | いいえ |  ブランチの名前 | このルールから除外するブランチ。 |
| `pipeline_sources` <sup>2</sup> | `array`の`string` | いいえ | `api``chat``external``external_pull_request_event``merge_request_event`<sup>3</sup>`pipeline``push`<sup>3</sup>`schedule``trigger``unknown``web` | スキャン実行ジョブをトリガーするタイミングを決定するパイプラインソース。詳細については、[ドキュメント](../../../ci/jobs/job_rules.md#ci_pipeline_source-predefined-variable)を参照してください。 |

1. `branches`または`branch_type`のいずれかを指定する必要がありますが、両方を指定することはできません。
1. 一部のオプションは、`flexible_scan_execution`機能フラグが有効になっている場合にのみ使用できます。詳細については、履歴を参照してください。
1. `branch_type`オプション`target_default`または`target_protected`が指定されている場合、`pipeline_sources`フィールドは`merge_request_event`および`push`フィールドのみをサポートします。

## `schedule`ルールタイプ {#schedule-rule-type}

{{< history >}}

- `branch_type`フィールドは、`security_policies_branch_type`という名前の[フラグ](../../../administration/feature_flags/_index.md)を付けて、GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/404774)されました。 GitLab 16.2で一般提供。機能フラグは削除されました。
- `branch_exceptions`フィールドは、`security_policies_branch_exceptions`という名前の[フラグ](../../../administration/feature_flags/_index.md)を付けて、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418741)されました。 GitLab 16.5で一般提供。機能フラグは削除されました。
- 新しい`scan_execution_pipeline_worker`ワーカーがスケジュールされたスキャンに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147691)され、GitLab 16.11でパイプラインを作成[しました](../../../administration/feature_flags/_index.md)。
- GitLab 17.1で新しいアプリケーション設定`security_policy_scheduled_scans_max_concurrency`が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152855)されました。同時実行制限は、`scan_execution_pipeline_worker`と`scan_execution_pipeline_concurrency_control`の両方が有効になっている場合に適用されます。
- `scan_execution_pipeline_concurrency_control`という名前の[フラグ](../../../administration/feature_flags/_index.md)が設定された状態で、GitLab 17.3のスキャン実行スケジュール済みジョブに対する同時実行制限を[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158636)しました。
- GitLab 17.5で、GitLab.comで`scan_execution_pipeline_worker`機能フラグが[有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/451890)。
- [機能フラグ](https://gitlab.com/gitlab-org/gitlab/-/issues/451890) `scan_execution_pipeline_worker` GitLab 17.6で削除されました。
- [機能フラグ](https://gitlab.com/gitlab-org/gitlab/-/issues/463802) `scan_execution_pipeline_concurrency_control` GitLab 17.9で削除されました。
- GitLab 17.11で、新しいアプリケーション設定`security_policy_scheduled_scans_max_concurrency`が[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178892)されました

{{< /history >}}

{{< alert type="warning" >}}

GitLab 16.1以前は、スケジュールされたスキャン実行ポリシーで[直接転送](../../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)を使用しないでください。直接転送を使用する必要がある場合は、まずGitLab 16.2にアップグレードし、適用対象のプロジェクトでセキュリティポリシーボットが有効になっていることを確認してください。

{{< /alert >}}

`schedule`ルールタイプを使用して、セキュリティスキャナーをスケジュールに基づいて実行します。

スケジュールされたパイプライン:

- プロジェクトの`.gitlab-ci.yml`ファイルで定義されているジョブではなく、ポリシーで定義されているスキャナーのみを実行します。
- `cadence`フィールドで定義されたスケジュールに従って実行します。
- CI/CDジョブからパイプラインを作成し、リポジトリのコンテンツを読み取りるためのゲストロールと権限を持つ、プロジェクト内の`security_policy_bot`ユーザーアカウントで実行されます。このアカウントは、ポリシーがグループまたはプロジェクトにリンクされるときに作成されます。
- GitLab.comでは、スキャン実行ポリシーの最初の10個の`schedule`ルールのみが適用されます。制限を超えるルールは無効です。

| フィールド      | 型 | 必須 | 使用可能な値 | 説明 |
|------------|------|----------|-----------------|-------------|
| `type`     | `string` | はい | `schedule` | ルールの種類。 |
| `branches` <sup>1</sup> | `array`の`string` | `branch_type`または`agents`フィールドが存在しない場合はtrue | `*`またはブランチの名前 | 指定されたポリシーが適用されるブランチ（ワイルドカードをサポート）。 |
| `branch_type` <sup>1</sup> | `string` | `branches`または`agents`フィールドが存在しない場合はtrue | `default`、`protected`または`all` | 指定されたポリシーが適用されるブランチの種類。 |
| `branch_exceptions` | `array`の`string` | いいえ |  ブランチの名前 | このルールから除外するブランチ。 |
| `cadence`  | `string` | はい | 制限付きオプション付きCron構文。たとえば、`0 0 * * *`は毎日午前0時（午前12時）に実行されるスケジュールを作成します。 | スケジュールされた時間を表す5つのフィールドを含む、空白で区切られた文字列。 |
| `timezone` | `string` | いいえ | タイムゾーン識別子（例：`America/New_York`） | ケイデンスに適用するタイムゾーン。値はIANAタイムゾーンデータベース識別子である必要があります。 |
| `time_window` | `object` | いいえ |  | スケジュールされたセキュリティスキャンの配信と期間の設定。 |
| `agents` <sup>1</sup>   | `object` | `branch_type`または`branches`フィールドが存在しない場合はtrue  |  | [<Kubernetes向けGitLabエージェント</Kubernetes向けGitLabエージェント>](../../clusters/agent/_index.md)の名前。[運用コンテナスキャン](../../clusters/agent/vulnerabilities.md)を実行する場所。オブジェクトキーは、GitLabでプロジェクト用に設定されたKubernetesエージェントの名前です。 |

1. `branches`、`branch_type`、または`agents`のいずれか1つのみを指定する必要があります。

### ケイデンス {#cadence}

`cadence`フィールドを使用して、ポリシーのアクションを実行するタイミングをスケジュールします。`cadence`フィールドは[Cron構文](../../../topics/cron/_index.md)を使用しますが、いくつかの制限があります:

- 次のタイプのCron構文のみがサポートされています:
  - 指定された時間帯に1時間ごとの毎日のケイデンス。例：`0 18 * * *`
  - 指定された曜日および時間帯に週に1回の毎週のケイデンス。例：`0 13 * * 0`
- コンマ（,）、ハイフン（-）、またはステップ演算子（/）を分と時間に使用することはサポートされていません。これらの文字を使用するスケジュールされたパイプラインはすべてスキップされます。

`cadence`フィールドの値を選択するときは、次の点を考慮してください:

- タイミングは、GitLab.comとGitLab Dedicatedの場合はUTCに基づいており、GitLab Self-Managedの場合はGitLabホストのシステム時間に基づいています。新しいポリシーをテストする際、パイプラインがローカルタイムゾーンではなく、サーバーのタイムゾーンでスケジュールされているため、正しくない時間に実行されることがあります。
- スケジュールされたパイプラインは、作成に必要なリソースが利用可能になるまで開始されません。言い換えれば、パイプラインはポリシーで指定されたタイミングで正確に開始されない場合があります。

`schedule`ルールタイプを`agents`フィールドとともに使用する場合:

- Kubernetes向けGitLabエージェントは、30秒ごとに適用可能なポリシーがあるかどうかを確認します。エージェントがポリシーを検出すると、定義された`cadence`に従ってスキャンが実行されます。
- cron式は、Kubernetesエージェントポッドのシステム時刻を使用して評価されます。

`schedule`ルールタイプを`branches`フィールドとともに使用する場合:

- cronワーカーは15分間隔で実行され、前の15分間に実行するようにスケジュールされたパイプラインを開始します。したがって、スケジュールされたパイプラインは、最大15分のオフセットで実行される場合があります。
- ポリシーが多数のプロジェクトまたはブランチで適用されている場合、ポリシーはバッチで処理され、すべてのパイプラインの作成に時間がかかる場合があります。

![スケジュールされたセキュリティスキャンが、潜在的な遅延を伴ってどのように処理および実行されるかを示す図。](img/scheduled_scan_execution_policies_diagram_v18_04.png)

### `agent`スキーマ {#agent-schema}

このスキーマを使用して、[`schedule`ルールタイプ](#schedule-rule-type)で`agents`オブジェクトを定義します。

| フィールド        | 型                | 必須 | 説明 |
|--------------|---------------------|----------|-------------|
| `namespaces` | `array`の`string` | はい | スキャンされるネームスペース。空の場合、すべてのネームスペースがスキャンされます。 |

#### `agent`例: {#agent-example}

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

- `cadence` (必須): スキャンを実行するタイミングの[Cron式](../../../topics/cron/_index.md)。
- `agents:<agent-name>`(必須): スキャンに使用するエージェントの名前。
- `agents:<agent-name>:namespaces`（オプション）: スキャンするKubernetesネームスペース。省略した場合、すべてのネームスペースがスキャンされます。

### `time_window`スキーマ {#time_window-schema}

[`schedule`ルールタイプ](#schedule-rule-type)の`time_window`オブジェクトを使用して、スケジュールされたスキャンが時間の経過とともにどのように分散されるかを定義します。ポリシーエディタのYAMLモードでのみ`time_window`を設定できます。

| フィールド          | 型      | 必須 | 説明                                                                                                                                                                          |
|----------------|-----------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `distribution` | `string`  | はい     | スケジュールされたスキャンの分散パターン。`random`のみをサポートします。ここで、スキャンは、`time_window`の`value`キーで定義された間隔でランダムに分散されます。 |
| `value`        | `integer` | はい     | スケジュールされたスキャンを実行する時間のタイムウィンドウ（秒単位）。3600（1時間）から86400（24時間）までの値を入力します。                                               |

#### `time_window`例: {#time_window-example}

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

### 大規模なプロジェクト向けにスケジュールされたパイプラインを最適化する {#optimize-scheduled-pipelines-for-projects-at-scale}

ポリシーが複数のプロジェクトとブランチにわたってスケジュールされたパイプラインを適用する場合、パイプラインは同時に実行されます。各プロジェクトでスケジュールされたパイプラインを最初に実行すると、そのプロジェクトのスケジュールを実行するセキュリティボットユーザーが作成されます。

大規模なプロジェクトのパフォーマンスを最適化するには:

- スケジュールされたスキャン実行ポリシーを段階的にロールアウトし、プロジェクトのサブセットから開始します。セキュリティポリシースコープを利用して、特定のグループ、プロジェクト、または特定のコンプライアンスフレームワークラベルを含むプロジェクトをターゲットにできます。
- 指定された`tag`を持つRunnerでスケジュールを実行するようにポリシーを設定できます。ポリシーから適用されたスケジュールを処理するために、各プロジェクトに専用のRunnerを設定して、他のRunnerへの影響を軽減することを検討してください。
- 本番環境にデプロイする前に、ステージング環境または下位環境で実装をテストします。パフォーマンスを監視し、結果に基づいてロールアウト計画を調整します。

### 並行処理 {#concurrency-control}

GitLabは、`time_window`プロパティを設定すると、並行処理制御を適用します。

並行性制御は、ポリシーで定義されている[`time_window`設定](#time_window-schema)に従って、スケジュールされたパイプラインを分散します。

## `scan`アクションタイプ {#scan-action-type}

{{< history >}}

- スキャン実行ポリシー変数の優先順位は、GitLab 16.7で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/424028)され、`security_policies_variables_precedence`[フラグ](../../../administration/feature_flags/_index.md)が導入されました。デフォルトでは有効になっています。[機能フラグは、GitLab 16.8で削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/435727)。
- 特定のアクションに対するセキュリティテンプレートの選択（プロジェクトの場合）は、GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/415427)されました（`scan_execution_policies_with_latest_templates`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)付き）。デフォルトでは無効になっています。
- 特定のアクションに対するセキュリティテンプレートの選択（グループの場合）は、GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/468981)されました（`scan_execution_policies_with_latest_templates_group`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)付き）。デフォルトでは無効になっています。
- 特定のアクションに対するセキュリティテンプレートの選択（プロジェクトおよびグループの場合）は、GitLab 17.2のGitLab Self-ManagedおよびGitLab Dedicated（[1](https://gitlab.com/gitlab-org/gitlab/-/issues/461474) 、[2](https://gitlab.com/gitlab-org/gitlab/-/issues/468981)）で有効になりました。
- 特定のアクションに対するセキュリティテンプレートの選択（プロジェクトおよびグループの場合）は、GitLab 17.3で一般的に利用可能になりました。機能フラグ`scan_execution_policies_with_latest_templates`および`scan_execution_policies_with_latest_templates_group`は削除されました。

{{< /history >}}

このアクションは、定義されたポリシーの少なくとも1つのルールの条件が満たされたときに、選択された`scan`を追加のパラメータで実行します。

| フィールド | 型 | 使用可能な値 | 説明 |
|-------|------|-----------------|-------------|
| `scan` | `string` | `sast`、`sast_iac`、`dast`、`secret_detection`、`container_scanning`、`dependency_scanning` | アクションのタイプ。 |
| `site_profile` | `string` | 選択された[DASTサイトプロファイル](../dast/profiles.md#site-profile)の名前。 | DASTスキャンを実行するDASTサイトプロファイル。このフィールドは、`scan`タイプが`dast`の場合にのみ設定する必要があります。 |
| `scanner_profile` | `string`または`null` | 選択された[DASTスキャナープロファイル](../dast/profiles.md#scanner-profile)の名前。 | DASTスキャンを実行するDASTスキャナープロファイル。このフィールドは、`scan`タイプが`dast`の場合にのみ設定する必要があります。|
| `variables` | `object` | | `key: value`ペアの配列として提供される<CI/CD variable>CI/CD変数</CI/CD変数>のセットで、選択したスキャンに適用および適用されます。`key`は変数名で、その`value`は文字列として指定されます。このパラメータは、GitLab CI/CDジョブが指定されたスキャンでサポートする変数をサポートします。 |
| `tags` | `array`の`string` | | ポリシーのRunnerタグのリスト。ポリシージョブは、指定されたタグを持つRunnerによって実行されます。 |
| `template` | `string` | `default`または`latest` | 適用するCI/CDテンプレートバージョン。`latest`バージョンでは、破壊的な変更が導入される可能性があり、マージリクエストに関連する`pipeline_sources`のみがサポートされます。詳細については、[セキュリティスキャンのカスタマイズ](../../application_security/detect/security_configuration.md#customize-security-scanning)を参照してください。 |
| `scan_settings` | `object` | | 選択したスキャンに適用および適用するために、`key: value`ペアの配列として提供されるスキャン設定のセット。`key`は設定名で、その`value`はブール値または文字列として指定されます。このパラメータは、[スキャン設定](#scan-settings)で定義されている設定をサポートします。 |

{{< alert type="note" >}}

プロジェクトでマージリクエストパイプラインが有効になっている場合は、適用される各スキャンのポリシーで、`AST_ENABLE_MR_PIPELINES` CI/CD変数を`"true"`に設定する必要があります。マージリクエストパイプラインでセキュリティスキャンツールを使用する方法の詳細については、[セキュリティスキャンのドキュメント](../../application_security/detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)を参照してください。

{{< /alert >}}

### スキャナーの動作 {#scanner-behavior}

一部のスキャナーは、通常のCI/CDパイプラインスキャンよりも`scan`アクションで異なる動作をします:

- 静的アプリケーションセキュリティテスト（SAST）: リポジトリに[SASTでサポートされているファイル](../sast/_index.md#supported-languages-and-frameworks)が含まれている場合にのみ実行されます。
- シークレット検出:
  - デフォルトでは、デフォルトルールセットのルールのみがサポートされています。
  - ルールセットの設定をカスタマイズするには、次のいずれかの方法を実行します:
    - デフォルトのルールセットを変更します。スキャン実行ポリシーを使用して、`SECRET_DETECTION_RULESET_GIT_REFERENCE` CI/CD変数を指定します。デフォルトでは、これはデフォルトのルールセットからのルールをオーバーライドまたは除外する[リモート設定ファイル](../secret_detection/pipeline/configure.md#with-a-remote-ruleset)を指します。この変数のみを使用しても、デフォルトのルールセットの拡張または置換はサポートされません。
    - デフォルトのルールセットを[拡張](../secret_detection/pipeline/configure.md#extend-the-default-ruleset)または[置換](../secret_detection/pipeline/configure.md#replace-the-default-ruleset)します。スキャン実行ポリシーを使用して、`SECRET_DETECTION_RULESET_GIT_REFERENCE` CI/CD変数と、[Gitパススルー](../secret_detection/pipeline/custom_rulesets_schema.md#passthrough-types)を使用してデフォルトのルールセットを拡張または置換するリモート設定ファイルを指定します。詳細なガイダンスについては、[一元管理されたパイプラインのシークレット検出設定を設定する方法](https://support.gitlab.com/hc/en-us/articles/18863735262364-How-to-set-up-a-centrally-managed-pipeline-secret-detection-configuration-applied-via-Scan-Execution-Policy)を参照してください。
  - `scheduled`スキャン実行ポリシーの場合、シークレット検出はデフォルトで最初に`historic`モード（`SECRET_DETECTION_HISTORIC_SCAN` = `true`）で実行されます。後続のスケジュールされたすべてのスキャンは、`SECRET_DETECTION_LOG_OPTIONS`が最後に実行されたコミット範囲と現在のSHAの間に設定されたデフォルトモードで実行されます。この動作は、スキャン実行ポリシーでCI/CD変数を指定することでオーバーライドできます。詳細については、[完全な履歴パイプラインのシークレット検出](../secret_detection/pipeline/_index.md#run-a-historic-scan)を参照してください。
  - `triggered`スキャン実行ポリシーの場合、シークレット検出は、通常のスキャンとまったく同じように機能します（[`.gitlab-ci.yml`で手動で設定された](../secret_detection/pipeline/_index.md#edit-the-gitlab-ciyml-file-manually)）。
- コンテナスキャン: `pipeline`ルールタイプ用に設定されたスキャンは、`agents`オブジェクトで定義されたエージェントを無視します。`agents`オブジェクトは、`schedule`ルールタイプでのみ考慮されます。`agents`オブジェクトで指定された名前のエージェントは、プロジェクト用に作成および設定する必要があります。

### DASTプロファイル {#dast-profiles}

ダイナミックアプリケーションセキュリティテスト（DAST）を適用する場合、次の要件が適用されます:

- ポリシーのスコープ内のすべてのプロジェクトについて、指定された[サイトプロファイル](../dast/profiles.md#site-profile)と[スキャナープロファイル](../dast/profiles.md#scanner-profile)が存在する必要があります。これらが利用できない場合、ポリシーは適用されず、代わりにエラーメッセージを含むジョブが作成されます。
- DASTサイトプロファイルまたはスキャナープロファイルが有効なスキャン実行ポリシーで指定されている場合、プロファイルを変更または削除することは不可能です。プロファイルを編集または削除するには、最初にポリシーをポリシーエディタで**無効**にするか、YAMLモードで`enabled: false`を設定する必要があります。
- スケジュールされたDASTスキャンでポリシーを設定する場合、セキュリティポリシープロジェクトのリポジトリ内のコミットの作成者は、スキャナーおよびサイトプロファイルにアクセスできる必要があります。そうでない場合、スキャンは正常にスケジュールされません。

### スキャン設定 {#scan-settings}

次の設定は、`scan_settings`パラメータでサポートされています:

| 設定 | 型 | 必須 | 使用可能な値 | デフォルト | 説明 |
|-------|------|----------|-----------------|-------------|-----------|
| `ignore_default_before_after_script` | `boolean` | いいえ | `true`、`false` | `false` | パイプライン設定内のデフォルトの`before_script`および`after_script`定義をスキャンジョブから除外するかどうかを指定します。 |

## CI/CD変数 {#cicd-variables}

{{< alert type="warning" >}}

変数はプレーンテキストのポリシー設定の一部としてGitリポジトリに保存されるため、機密情報や認証情報を変数に保存しないでください。

{{< /alert >}}

スキャン実行ポリシーで定義された変数は、標準の[CI/CD変数の優先順位](../../../ci/variables/_index.md#cicd-variable-precedence)に従います。

スキャン実行ポリシーが適用されるすべてのプロジェクトで、次のCI/CD変数に事前設定された値が使用されます。これらの値をオーバーライドできますが、ポリシーで宣言されている場合に**only**（のみ）可能です。これらは、グループまたはプロジェクトのCI/CD変数によって**不可能**:

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

- 接尾辞`_EXCLUDED_PATHS`が付いたCI/CD変数がポリシーで宣言されている場合、それらの値はグループまたはプロジェクトのCI/CD変数によって_オーバーライドできる_可能性があります。
- 接尾辞`_EXCLUDED_ANALYZERS`が付いたCI/CD変数がポリシーで宣言されている場合、それらの値は、ポリシー、グループ、プロジェクトのどこで定義されているかに関係なく、無視されました。

## ポリシーのスコープスキーマ {#policy-scope-schema}

ポリシーの適用をカスタマイズするには、ポリシーのスコープを定義して、指定したプロジェクト、グループ、またはコンプライアンスフレームワークのラベルを含めるか、除外します。詳細については、[スコープ](_index.md#configure-the-policy-scope)を参照してください。

## ポリシー更新の伝播 {#policy-update-propagation}

ポリシーを更新する場合、ポリシーの更新方法に応じて、変更は異なる方法で伝播されます:

- [セキュリティポリシープロジェクト](../_index.md)でマージリクエストを使用する場合: 変更は、マージリクエストがマージされた直後に有効になります。
- `.gitlab/security-policies/policy.yml`への直接コミット: 変更が有効になるまでに最大10分かかる場合があります。

### トリガー動作 {#triggering-behavior}

パイプラインベースのポリシー（`type: pipeline`）の更新は、即時のパイプラインをトリガーしたり、進行中のパイプラインに影響を与えたりしません。ポリシーの変更は、将来のパイプラインの実行に適用されます。

スケジュールされたケイデンス外でスケジュールされたポリシーのルールを手動でトリガーすることはできません。

## セキュリティポリシープロジェクトの例 {#example-security-policy-project}

[セキュリティポリシープロジェクト](enforcement/security_policy_projects.md)に格納されている`.gitlab/security-policies/policy.yml`ファイルで、この例を使用できます:

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
- name: Enforce Secret Detection and container scanning in every default branch pipeline
  description: This policy enforces pipeline configuration to have a job with Secret Detection and container scanning scans for the default branch
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

- `release/*`ワイルドカード（たとえば、ブランチ`release/v1.2.1`）に一致するブランチで実行されるすべてのパイプラインの場合
  - DASTスキャンは、`Scanner Profile A`と`Site Profile B`で実行されます。
- DASTとシークレット検出のスキャンは、10分ごとに実行されます。DASTスキャンは`Scanner Profile C`と`Site Profile D`で実行されます。
- シークレット検出、コンテナスキャン、およびSASTスキャンは、`main`ブランチで実行されるすべてのパイプラインに対して実行されます。SASTスキャンは、`SAST_EXCLUDED_ANALYZER`変数が`"brakeman"`に設定されて実行されます。

## スキャン実行ポリシーエディタの例 {#example-for-scan-execution-policy-editor}

[スキャン実行ポリシーエディタ](#scan-execution-policy-editor)のYAMLモードでこの例を使用できます。これは、前の例の単一のオブジェクトに対応します。

```yaml
name: Enforce Secret Detection and container scanning in every default branch pipeline
description: This policy enforces pipeline configuration to have a job with Secret Detection and container scanning scans for the default branch
enabled: true
rules:
  - type: pipeline
    branches:
      - main
actions:
  - scan: secret_detection
  - scan: container_scanning
```

## スキャンの重複を回避する {#avoiding-duplicate-scans}

デベロッパーがプロジェクトの`.gitlab-ci.yml`ファイルにスキャンジョブを含めると、スキャン実行ポリシーによって同じタイプのスキャナーが複数回実行される可能性があります。この動作は、スキャナーが異なる変数と設定を使用して複数回実行できるため、意図的です。たとえば、デベロッパーは、セキュリティおよびコンプライアンスチームによって適用されるものとは異なる変数を使用して、SASTスキャンを実行しようとする場合があります。この場合、2つのSASTジョブがパイプラインで実行されます:

- 1つはデベロッパーの変数を使用します。
- もう1つは、セキュリティおよびコンプライアンスチームの変数を使用します。

重複するスキャンの実行を回避するには、プロジェクトの`.gitlab-ci.yml`ファイルからスキャンを削除するか、変数を使用してローカルジョブをスキップできます。ジョブをスキップしても、スキャン実行ポリシーによって定義されたセキュリティジョブの実行は妨げられません。

変数を使用してスキャンジョブをスキップするには、次を使用します:

- `SAST_DISABLED: "true"` SASTジョブをスキップします。
- `DAST_DISABLED: "true"` DASTジョブをスキップします。
- `CONTAINER_SCANNING_DISABLED: "true"`コンテナスキャンジョブをスキップします。
- `SECRET_DETECTION_DISABLED: "true"`シークレット検出ジョブをスキップします。
- `DEPENDENCY_SCANNING_DISABLED: "true"`をスキップするには、依存関係スキャンジョブ。

ジョブをスキップできるすべての変数の概要については、[CI/CD変数ドキュメント](../../../topics/autodevops/cicd_variables.md#job-skipping-variables)を参照してください。

## トラブルシューティング {#troubleshooting}

### スキャン実行ポリシーパイプラインが作成されない {#scan-execution-policy-pipelines-are-not-created}

スキャン実行ポリシーが、期待どおりに`type: pipeline`で定義されたパイプラインを作成しない場合は、[`workflow:rules`](../../../ci/yaml/workflow.md)がプロジェクトの`.gitlab-ci.yml`ファイルにあり、ポリシーによるパイプラインの作成を妨げている可能性があります。

`type: pipeline`ルールを使用したスキャン実行ポリシーは、マージされたCI/CD設定に依存してパイプラインを作成します。プロジェクトの`workflow:rules`がパイプラインを完全に除外する場合、スキャン実行ポリシーはパイプラインを作成できません。

たとえば、次の`workflow:rules`設定では、すべてのパイプラインが作成されません:

```yaml
# .gitlab-ci.yml
workflow:
  rules:
  - if: $CI_PIPELINE_SOURCE == "push"
    when: never
```

解決:

この問題を解決するには、次のいずれかのオプションを使用できます:

- スキャン実行ポリシーでパイプラインを作成できるように、プロジェクトの`workflow:rules`を修正します`.gitlab-ci.yml`ファイル。`$CI_PIPELINE_SOURCE`変数を使用して、ポリシーによってトリガーされるパイプラインを識別できます:

  ```yaml
  workflow:
    rules:
    - if: $CI_PIPELINE_SOURCE == "security_orchestration_policy"
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
  ```

- `type: schedule`ルールの代わりに`type: pipeline`ルールを使用します。スケジュールされたスキャン実行ポリシーは`workflow:rules`の影響を受けず、定義されたスケジュールに従ってパイプラインを作成します。
- [パイプライン実行ポリシー](pipeline_execution_policies.md)を使用すると、CI/CDパイプラインでセキュリティスキャンがいつ、どのように実行されるかをより詳細に制御できます。
