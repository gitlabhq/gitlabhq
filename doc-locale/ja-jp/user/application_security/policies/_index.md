---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ポリシー
description: セキュリティポリシー、適用、コンプライアンス、承認、スキャン。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ポリシーを使用すると、セキュリティチームおよびコンプライアンスチームは、組織全体にコントロールを適用できます。

セキュリティチームは、次のことを確実に行えます。

- 適切な設定で、開発チームのパイプラインにセキュリティスキャナーを適用する。
- すべてのスキャンジョブを、変更または改変なしに実行する。
- スキャン結果に基づき、マージリクエストに対して適切な承認を行う。
- 検出されなくなった脆弱性を自動的に解決し、脆弱性のトリアージ作業のワークロードを軽減する。

コンプライアンスチームは、次のことを行えます。

- すべてのマージリクエストに複数の承認者を適用する。
- 組織の要件に基づいたプロジェクト設定（マージリクエストの設定またはリポジトリの設定の有効化やロックなど）を適用する。

次のポリシータイプを使用できます。

- [スキャン実行ポリシー](scan_execution_policies.md)。パイプラインの一部として、または指定されたスケジュールに従ってセキュリティスキャンを強制的に実行します。
- [マージリクエスト承認ポリシー](merge_request_approval_policies.md)。スキャン結果に基づいて、プロジェクトレベルの設定と承認ルールを強制的に適用します。
- [パイプライン実行ポリシー](pipeline_execution_policies.md)。プロジェクトのパイプラインの一部としてCI/CDジョブを強制的に実行します。
  - [スケジュールされたパイプライン実行ポリシー](scheduled_pipeline_execution_policies.md)。コミットアクティビティとは関係なく、スケジュールされたケイデンスでプロジェクト全体にカスタムCI/CDジョブを強制的に実行します。
- [脆弱性管理ポリシー](vulnerability_management_policy.md)。デフォルトブランチで検出されなくなった脆弱性を自動的に解決します。

## ポリシーのスコープを設定 {#configure-the-policy-scope}

## `policy_scope`キーワード {#policy_scope-keyword}

`policy_scope`キーワードを使用して、指定したグループ、プロジェクト、コンプライアンスフレームワーク、セキュリティ属性、またはそれらの組み合わせにのみポリシーを適用します。

セキュリティ属性によってポリシーをスコープするには、セキュリティポリシープロジェクトの`.gitlab/security-policies/policy.yml`ファイルで`security_attributes_policy_scope`実験を有効にします:

```yaml
experiments:
  security_attributes_policy_scope:
    enabled: true
```

`business_impact`、`application`、`business_unit`、`exposure`の4つの組み込みセキュリティ属性カテゴリのみでポリシーをスコープできます。これらのカテゴリでカスタム属性値を作成し、それらの値でスコープできますが、カスタムカテゴリでスコープすることはできません。

> [!note]
> `business_impact`、`application`、`business_unit`、`exposure`フィールドは、[セキュリティ属性](../attributes/_index.md)によってポリシーをスコープします。セキュリティ属性のスコープは、スキャン実行ポリシー、マージリクエスト承認、パイプライン実行ポリシー、および脆弱性管理ポリシーに適用されます。依存関係ファイアウォールポリシーには適用されません。

| フィールド                   | 型     | 使用可能な値          | 説明 |
|-------------------------|----------|--------------------------|-------------|
| `match_mode` | `string` | `all`、`any` | GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/569793)されました。ポリシーが複数のスコープ条件をどのように処理するかを決定します。すべての条件が一致するように`all`（デフォルト）を使用するか、少なくとも1つの条件が一致するように`any`を使用します。 |
| `compliance_frameworks` | `array`  | 該当なし           | スコープ内のコンプライアンスフレームワークのIDを、キー`id`を持つオブジェクトの配列でリストします。 |
| `projects`              | `object` | `including`、`excluding` | `excluding:`または`including:`を使用して、含めるまたは除外するプロジェクトのIDを、キー`id`を持つオブジェクトの配列でリストします。`type: personal`を使用して個人プロジェクトを除外するか、`type: archived`を使用してアーカイブされたプロジェクトを除外することもできます。 |
| `groups`                | `object` | `including`              | `including:`を使用して、含めるグループのIDを、キー`id`を持つオブジェクトの配列でリストします。同じセキュリティポリシープロジェクトにリンクされているグループのみ、ポリシーの対象として列挙できます。 |
| `business_impact` | `object` | `including`、`excluding` | [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227155)されたGitLab 18.11で、`security_attributes_policy_scope`フラグという名前のフラグと共に。デフォルトでは有効になっています。Business Impact [セキュリティ属性](../attributes/_index.md)値のIDを、`id`キーを持つオブジェクトの配列で含めるか除外するかをリストします。 |
| `application` | `object` | `including`、`excluding` | [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227155)されたGitLab 18.11で、`security_attributes_policy_scope`フラグという名前のフラグと共に。デフォルトでは有効になっています。Application [セキュリティ属性](../attributes/_index.md)値のIDを、`id`キーを持つオブジェクトの配列で含めるか除外するかをリストします。 |
| `business_unit` | `object` | `including`、`excluding` | [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227155)されたGitLab 18.11で、`security_attributes_policy_scope`フラグという名前のフラグと共に。デフォルトでは有効になっています。Business Unit [セキュリティ属性](../attributes/_index.md)値のIDを、`id`キーを持つオブジェクトの配列で含めるか除外するかをリストします。 |
| `exposure` | `object` | `including`、`excluding` | [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227155)されたGitLab 18.11で、`security_attributes_policy_scope`フラグという名前のフラグと共に。デフォルトでは有効になっています。Exposure [セキュリティ属性](../attributes/_index.md)値のIDを、`id`キーを持つオブジェクトの配列で含めるか除外するかをリストします。 |

### `policy_scope`内の空のコレクション {#empty-collections-in-policy_scope}

`policy_scope`フィールドが空のコレクション（`[]`）に設定されている場合、そのフィールドは完全に省略されたものとして扱われます。これは、ポリシーがいかなる制限もなくすべてのプロジェクトに適用されることを意味します。

具体的には次のとおりです。

- `projects: { including: [] }`は、0個のプロジェクトではなく、すべてのプロジェクトにポリシーを適用します。
- `groups: { including: [] }`は、0個のグループではなく、すべてのグループにポリシーを適用します。
- `compliance_frameworks: []`は、フレームワークのないプロジェクトではなく、すべてのプロジェクトにポリシーを適用します。

この動作は、フィルターが指定されていないかのように空のコレクションが扱われる既存のポリシーとの下位互換性を維持します。

ポリシーがどのプロジェクトにも適用されないようにするには、空のコレクションを使用する代わりに`enabled: false`を設定します:

```yaml
policy_scope:
  projects:
    including:
      - id: 123
enabled: false  # Disables the policy entirely
```

### `match_mode`を理解する {#understanding-match_mode}

複数のスコープ条件（例えば、`projects`と`groups`の両方）を指定すると、`match_mode`フィールドによってこれらの条件がどのように結合されるかが決まります:

- **`all`（default）**: ポリシーは、指定されたすべての条件に一致するプロジェクトにのみ適用されます。このモードはより制限的であり、既存のポリシーとの下位互換性を維持します。
- **`any`**: ポリシーは、指定されたいずれかの条件に一致するプロジェクトに適用されます。このモードはより許容的であり、単一のポリシーで異なるプロジェクトセットをターゲットにしたい場合に役立ちます。

例えば、含めるプロジェクトのリストと含めるグループのリストの両方を指定した場合:

- `match_mode: all`の場合、プロジェクトはプロジェクトリストに**と**指定されたいずれかのグループに属している必要があります。
- `match_mode: any`の場合、プロジェクトがプロジェクトリストにある**または**指定されたいずれかのグループに属している場合、スコープ内となります。

`excluding`と`including`の条件を`match_mode: any`と組み合わせる場合、`excluding`条件がポリシーの適用範囲を広げることに注意してください。ORロジックは、いずれかの条件が一致すればポリシーが適用されることを意味するため、グループ除外条件（除外されたグループのプロジェクトを除くすべてのプロジェクトに一致する）は、`including`条件で何が指定されていても、ポリシーがほとんどのプロジェクトに適用されることを意味します。

例えば、グループリストから`group-2`を除外する一方で、特定のプロジェクト`group-1/project-1-1`と`group-2/project-2-1`を含めるポリシーの場合:

 ```yaml
policy_scope:
  match_mode: any
  groups:
    excluding:
      - id: 200  # group-2
  projects:
    including:
      - id: 101  # group-1/project-1-1
      - id: 201  # group-2/project-2-1
```

この設定では、ポリシーは明示的に含まれる2つのプロジェクトだけでなく、`group-2`外のすべての他のプロジェクト（含めるプロジェクトにリストされていない`group-1/project-1-2`など）にも適用されます。グループ除外条件は`group-2`にない任意のプロジェクトに一致し、ORロジックでは、単一の一致でポリシーが適用されるのに十分です。

### スコープの例 {#scope-examples}

次の例では、スキャン実行ポリシーは、IDが`2`または`11`のコンプライアンスフレームワークが適用されたすべてのプロジェクトのすべてのリリースパイプラインでSASTスキャンを強制的に実行します。

```yaml
---
scan_execution_policy:
- name: Enforce specified scans in every release pipeline
  description: This policy enforces a SAST scan for release branches
  enabled: true
  rules:
  - type: pipeline
    branches:
    - release/*
  actions:
  - scan: sast
  policy_scope:
    compliance_frameworks:
      - id: 2
      - id: 11
```

次の例では、スキャン実行ポリシーは、IDが`203`のグループ（すべての子孫サブグループとそのプロジェクトを含む）内のすべてのプロジェクトのデフォルトブランチのパイプラインで、シークレット検出とSASTスキャンを強制的に実行します。ただし、IDが`64`のプロジェクトは除外されます。

```yaml
- name: Enforce specified scans in every default branch pipeline
  description: This policy enforces secret detection and SAST scans for the default branch
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: secret_detection
  - scan: sast
  policy_scope:
    groups:
      including:
        - id: 203
    projects:
      excluding:
        - id: 64
```

この例では、スキャン実行ポリシーは、アーカイブされたプロジェクトを除くすべてのプロジェクトに対してSASTスキャンを適用します。これは、スキャンすべきでないアーカイブされたプロジェクトが多数ある場合に役立ちます。

```yaml
- name: Enforce SAST scan excluding archived projects
  description: This policy enforces SAST scans but excludes archived projects
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: sast
  policy_scope:
    projects:
      excluding:
        - type: archived
```

この例では、スキャン実行ポリシーは`match_mode: any`を使用して、特定の高優先度プロジェクトまたは特定のグループ内のすべてのプロジェクトに対してシークレット検出スキャンを適用します。`match_mode: any`がない場合、ポリシーが適用されるには、プロジェクトがプロジェクトリストにと指定されたいずれかのグループに属している必要があります。

```yaml
- name: Enforce secret detection on priority projects or security groups
  description: This policy enforces secret detection on specific projects or all projects in security-focused groups
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: secret_detection
  policy_scope:
    match_mode: any
    projects:
      including:
        - id: 123  # High-priority project outside of security groups
        - id: 456  # Another critical project
    groups:
      including:
        - id: 78   # Security team's group
        - id: 90   # Compliance team's group
```

この例では、スキャン実行ポリシーは、IDが`5`（例えば`Mission Critical`）のBusiness Impactセキュリティ属性値を持つすべてのプロジェクトのデフォルトブランチでSASTスキャンを適用します。属性が追加または削除されると、プロジェクトはこのスコープを獲得または失い、ポリシーは変更されません。

```yaml
- name: Enforce SAST on mission-critical projects
  description: This policy enforces a SAST scan on projects with a Business Impact security attribute
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: sast
  policy_scope:
    business_impact:
      including:
        - id: 5
```

## 職務分離 {#separation-of-duties}

ポリシーの正常な実装のためには、職務分離が不可欠です。必要なコンプライアンス要件とセキュリティ要件を満たすポリシーを実装すると同時に、開発チームが目標を達成できるようにします。

セキュリティチームとコンプライアンスチーム:

- ポリシーの定義を担当し、開発チームと協力してポリシーが開発チームの要件を満たすようにする必要があります。

開発チーム:

- いかなる方法でもポリシーを無効化、変更、または回避できないようにする必要があります。

グループ、サブグループ、またはプロジェクトでセキュリティポリシープロジェクトを適用するには、次のいずれかが必要です。

- そのグループ、サブグループ、またはプロジェクトにおけるオーナーロール。
- そのグループ、サブグループ、またはプロジェクト内で`manage_security_policy_link`権限を持つカスタムロール。

オーナーロール、および`manage_security_policy_link`権限を持つカスタムロールは、グループ、サブグループ、プロジェクト全体で標準の階層ルールに従います。

| 組織単位 | グループオーナーまたはグループの`manage_security_policy_link`権限 | サブグループオーナーまたはサブグループの`manage_security_policy_link`権限 | プロジェクトオーナーまたはプロジェクトの`manage_security_policy_link`権限 |
|-------------------|---------------------------------------------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------|
| グループ             | {{< yes >}} | {{< no >}}  | {{< no >}}  |
| サブグループ          | {{< yes >}} | {{< yes >}} | {{< no >}}  |
| プロジェクト           | {{< yes >}} | {{< yes >}} | {{< yes >}} |

### 必要な権限 {#required-permissions}

セキュリティポリシーを作成および管理するには:

- グループに適用されるポリシーの場合: グループのメンテナーロールまたはオーナーロールを持っている必要があります。
- プロジェクトに適用されるポリシーの場合:
  - プロジェクトのオーナーである必要があります。
  - グループ内でプロジェクトを作成する権限を持つグループメンバーである必要があります。

> [!note]
> グループメンバーでない場合、プロジェクトのポリシーの追加または編集に制限がある場合があります。ポリシーを作成および管理するには、グループ内でプロジェクトを作成する権限が必要です。プロジェクトレベルのポリシーを扱う場合でも、グループ内で必要な権限を持っていることを確認してください。

## ポリシーの推奨事項 {#policy-recommendations}

ポリシーを実装する際は、次の推奨事項を考慮してください。

### ブランチ名 {#branch-names}

ポリシーでブランチ名を指定する場合は、個々のブランチ名ではなく、**デフォルトブランチ**や**すべての保護ブランチ**など、保護ブランチの汎用的なカテゴリを使用します。

ポリシーは、指定されたブランチがそのプロジェクト内に存在する場合にのみ、プロジェクトに適用されます。たとえば、ポリシーで`main`ブランチにルールを適用していても、スコープ内の一部のプロジェクトが`production`をデフォルトブランチとして使用している場合、そのプロジェクトにはポリシーは適用されません。

### プッシュルール {#push-rules}

GitLab 17.3以前では、プッシュルールを使用して[ブランチ名を検証する](../../project/repository/push_rules.md#validate-branch-names)場合、プレフィックス`update-policy-`を付けたブランチが作成可能であることを確認してください。このブランチ名のプレフィックスは、セキュリティポリシーの作成や修正時に使用されます。例: `update-policy-1659094451`（`1659094451`はタイムスタンプ）。プッシュルールがこのブランチの作成をブロックした場合、次のエラーが発生します。

```plaintext
Branch name `update-policy-<timestamp>` does not follow the pattern `<branch_name_regex>`.
```

GitLab 17.4以降、セキュリティポリシープロジェクトは、ブランチ名の検証を適用するプッシュルールから除外されます。

### セキュリティポリシープロジェクト {#security-policy-projects}

セキュリティポリシープロジェクトで、非公開にしておきたい機密情報が漏洩するのを防ぐため、セキュリティポリシープロジェクトを他のプロジェクトにリンクする際は、次の点に注意してください。

- セキュリティポリシープロジェクトに機密情報を含めない。
- 非公開のセキュリティポリシープロジェクトをリンクする前に、対象プロジェクトのメンバーリストを確認し、全員がポリシーの内容にアクセス可能になっても問題がないことを確かめる。
- リンク先プロジェクトの表示レベルを評価する。
- [セキュリティポリシー管理](../../compliance/audit_event_types.md#security-policy-management)の監査ログを使用して、プロジェクトのリンクを監視する。

これらの推奨事項は、次の要因による機密情報の漏洩を防ぎます。

- 表示レベルの共有: 非公開のセキュリティプロジェクトが別のプロジェクトにリンクされている場合、リンクされたプロジェクトの**セキュリティポリシー**ページへのアクセス権を持つユーザーは、`.gitlab/security-policies/policy.yml`ファイルの内容を閲覧できます。これには、非公開のセキュリティポリシープロジェクトを公開プロジェクトにリンクする場合も含まれます。これにより、公開プロジェクトにアクセスできるすべてのユーザーにポリシーの内容が公開される可能性があります。
- アクセス制御: 非公開のセキュリティプロジェクトがリンクされているプロジェクトのすべてのメンバーは、元の非公開リポジトリへのアクセス権がない場合でも、**ポリシー**ページでポリシーファイルを閲覧できます。

### セキュリティとコンプライアンスの制御 {#security-and-compliance-controls}

プロジェクトメンテナーによって作成されたプロジェクトのポリシーが、グループのポリシーの実行を妨げる可能性があります。グループのポリシーを変更できるユーザーを制限し、コンプライアンス要件を確実に満たすために、重要なセキュリティまたはコンプライアンスの制御を実装する際は、次の点に注意してください。

- カスタムロールを使用して、プロジェクトレベルでパイプライン実行ポリシーを作成または変更できるユーザーを制限する。
- セキュリティポリシープロジェクトのデフォルトブランチに対して保護ブランチを設定し、直接プッシュを防止する。
- セキュリティポリシープロジェクトでマージリクエスト承認ルールを設定し、指定された承認者からのレビューを必須にする。
- グループとプロジェクトの両方のポリシーで、すべてのポリシーの変更を監視およびレビューする。

## ポリシー管理 {#policy-management}

ポリシーページでは、利用可能なすべての環境にデプロイされたポリシーを表示できます。次の手順により、ポリシーの情報（説明や適用状況など）を確認したり、デプロイされたポリシーを作成または編集したりできます。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**安全** > **ポリシー**を選択します。

![ポリシーリストページ](img/policies_list_v17_7.png)

最初の列の緑色のチェックマークは、ポリシーが有効であり、そのスコープ内のすべてのグループとプロジェクトに適用されていることを示します。灰色のチェックマークは、そのポリシーが現在無効であることを示します。

## ポリシーエディタ {#policy-editor}

ポリシーエディタには、次の2つのモードがあります。

- ルールモード: ルールブロックと関連するコントロールを使用して、ポリシールールを構築とプレビューします。
- YAMLモード: YAML形式でポリシー定義を入力します。エキスパートユーザーと、ルールモードがサポートしていないケースに適しています。

ルールモードとYAMLモードはいつでも切り替えられます。YAMLにエラーがあるか、サポートされていないデータが含まれている場合、ルールモードは自動的にオフになります。再度ルールモードを使用するには、まずYAMLを修正してください。

ポリシーエディタを使用して、ポリシーを作成、編集、および削除できます。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**安全** > **ポリシー**を選択します。
   - 新しいポリシーを作成するには、**ポリシー**ページヘッダーで**新規ポリシー**を選択し、次にポリシータイプを選択します。
   - 既存のポリシーを編集するには、選択したポリシードロワーで**ポリシーを編集**を選択します。

1. **マージリクエスト経由で設定**を選択して変更を保存し、適用します。

   ポリシーのYAMLが検証され、その結果発生したエラーが表示されます。

1. 生成されたマージリクエストを確認してマージします。

   プロジェクトのオーナーであり、セキュリティポリシープロジェクトがこのプロジェクトに関連付けられていない場合、マージリクエストの作成時にセキュリティポリシープロジェクトが作成され、このプロジェクトにリンクされます。

### 標準エディタと拡張エディタのレイアウト {#standard-and-advanced-editor-layouts}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/450705)されました。

{{< /history >}}

ポリシーエディタには、ルールモードとYAMLモードの表示方法を決定する2つのレイアウトがあります:

- 標準エディタ: ルールモードとYAMLモードを別々のタブとして表示します。タブを選択してビューを切り替えます。ルールモードでは、読み取り専用のYAMLプレビューがサイドバーに表示されます。
- 拡張エディタ: ルールモードとYAMLモードを、サイズ変更可能な分割ビューで並べて表示します。一方のパネルでの変更は、もう一方のパネルにリアルタイムで反映されます。次のことが可能です。

  - 区切りをドラッグしてパネルのサイズを変更します。
  - どちらかのパネルを折りたたむと、1つのビューに集中できます。
  - パネルサイズをリセットするには、区切りを2回選択します。

設定したパネルサイズはセッション間で保存されます。

標準エディタと拡張エディタのレイアウトを切り替えるには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**安全** > **ポリシー**を選択します。
   - 新しいポリシーを作成するには、**ポリシー**ページヘッダーで**新規ポリシー**を選択し、次にポリシータイプを選択します。
   - 既存のポリシーを編集するには、選択したポリシードロワーで**ポリシーを編集**を選択します。

1. ポリシーエディタの上部で、**拡張エディタを有効にする**または**標準エディタを有効にする**を選択します。

設定はユーザーアカウントに保存され、セッション間で保持されます。

### `policy.yml`のIDに注釈を付ける {#annotate-ids-in-policyyml}

{{< details >}}

ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.1で、`policy.yml`ファイルで`annotate_ids`オプションを定義して、[実験的機能](../../../policy/development_stages_support.md)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/497774)されました。

{{< /history >}}

`policy.yml`ファイルを簡素化するために、GitLabでは、プロジェクトID、グループID、ユーザーID、コンプライアンスフレームワークIDなどのIDの後にコメントを自動的に付加できます。この注釈により、ユーザーが各IDの意味や由来を識別しやすくなり、`policy.yml`ファイルの内容の把握と管理が容易になります。

この実験的機能を有効にするには、セキュリティポリシープロジェクトの`.gitlab/security-policies/policy.yml`ファイルで、`experiments`セクションに`annotate_ids`セクションを追加します。

```yaml
experiments:
  annotate_ids:
    enabled: true
```

このオプションを有効にすると、GitLab[ポリシーエディタ](#policy-editor)でセキュリティポリシーを変更した際に、`policy.yml`ファイル内のIDの横に注釈コメントが作成されます。

> [!note]
> アノテーションを適用するには、ポリシーエディタを使用する必要があります。`policy.yml`ファイルを手動で編集した場合（たとえば、Gitコミットを使用）、注釈は適用されません。

例: 

```yaml
# Example policy.yml with annotated IDs
approval_policy:
- name: Your policy name
  # ... other policy fields ...
  policy_scope:
    projects:
      including:
      - id: 361 # my-group/my-project
  actions:
  - type: require_approval
    approvals_required: 1
    user_approvers_ids:
    - 75 # jane.doe
    group_approvers_ids:
    - 203 # security-approvers
```

> [!note]
> 初めてアノテーションを適用すると、GitLabは、編集していないポリシー内のIDも含め、`policy.yml`ファイル内のすべてのIDにアノテーションを作成します。

## GitLabセキュリティポリシーボットユーザー {#gitlab-security-policy-bot-user}

GitLabセキュリティポリシーボットは、GitLabインスタンス全体でセキュリティポリシーを実行する内部ユーザーです。このボットは、セキュリティポリシーとスケジュールされたパイプラインが適切に機能するために不可欠です。

セキュリティポリシーボットは以下を担当します:

- スケジュールされたパイプライン実行: `type: schedule`ルールを持つスキャン実行ポリシーで定義されたパイプラインをトリガーする。
- コンテナスキャンの自動化: `latest`タグでイメージがプッシュされたときにコンテナスキャンジョブをトリガーする。
- ポリシーの適用: セキュリティポリシーで定義されたセキュリティスキャンとコンプライアンスチェックを実行します。
- パイプラインの作成: セキュリティポリシーが適用されているプロジェクトで、ポリシー駆動のパイプラインを作成と管理します。

### アカウントの特性 {#account-characteristics}

セキュリティポリシーボットは以下の特性を持ちます:

- セキュリティポリシーが適用されているすべてのプロジェクトで自動的に作成されます。
- プロジェクト内でゲストロールの権限で実行され、特定の追加権限を持ちます。
- 内部ユーザーとしてマークされているため、ライセンス制限にはカウントされません。
- ポリシーが適用されると、各プロジェクトは独自のセキュリティポリシーボットインスタンスを取得します。

### 権限とアクセス {#permissions-and-access}

セキュリティポリシーボットは、最小限ですが不可欠な権限で動作します:

- リポジトリへのアクセス: ポリシー実行に必要なリポジトリコンテンツへの読み取り専用アクセス。
- パイプラインの作成: ポリシーの適用のためパイプラインを作成し、トリガーする機能。
- CI/CD変数: 変数の優先順位ルールに従って、プロジェクトとグループの変数にアクセス。
- レジストリへのアクセス: 適切な認証情報で設定されている場合、コンテナレジストリを認証することができます。

### 制限事項 {#limitations-and-restrictions}

GitLabセキュリティポリシーボットには以下の制限があります:

- 手動で削除できません: UIでボットを削除することはできません。
- 変更できません: ユーザー設定または権限を手動で変更することはできません。
- プロジェクトに限定: 各ボットインスタンスは特定のプロジェクトに紐付けられており、インスタンスを複数のプロジェクトで共有することはできません。
- ポリシーに依存: ボットの機能は、プロジェクト用に設定されたセキュリティポリシーに完全に依存します。

### セキュリティのトラブルシューティング {#security-troubleshooting}

> [!warning]
> 脆弱性と不正使用レポート: GitLabセキュリティポリシーボットインスタンスは、不正使用レポートシステムを通じてBANまたは削除される可能性があり、これによりスケジュールされたパイプラインの実行が妨げられる可能性があります。管理者は以下の点に注意する必要があります:
>
> - セキュリティポリシーボットの不正使用をレポートすると、ボットがBANまたは削除される可能性があります。
> - ボットをBANまたは削除すると、スケジュールされたパイプラインが失敗します。
> - 一度BANされると、標準的な管理アクションでボットを復元することはできません。
> - ボットが復元されるまで、セキュリティポリシーの適用は完全に中断されます。
>
> セキュリティポリシーの偶発的な中断を防ぐため、管理者は内部ユーザーアカウントの不正使用レポートを処理する際に注意を払う必要があります。

セキュリティポリシーボットの機能で問題が発生した場合:

#### スケジュールされたパイプラインが実行されない {#scheduled-pipelines-not-running}

設定どおりにスケジュールされたパイプラインが実行されない場合:

- ボットアカウントが存在し、BANまたは削除されていないことを確認します。
- セキュリティポリシーの設定が有効であることを確認します。
- ボットがプロジェクトに必要な権限を持っていることを確認します。

#### ポリシージョブが失敗する {#policy-jobs-failing}

ポリシージョブが失敗している場合:

- ボットが必須のCI/CD変数にアクセスできることを確認します。
- 参照されているCI/CD設定ファイルが存在し、アクセス可能であることを確認します。
- 特定のエラーメッセージについては、パイプラインログを確認してください。

#### コンテナスキャンがトリガーされない {#container-scanning-not-triggering}

設定どおりにコンテナスキャンがトリガーされない場合:

- コンテナスキャンポリシーが適切に設定されていることを確認します。
- 必要に応じて、ボットがレジストリ認証認証情報を持っていることを確認します。
- `latest`タグプッシュが予期されたポリシールールをトリガーしたことを確認します。

#### ボットアカウントが見つからない {#bot-account-missing}

ボットアカウントがなくなった場合:

- セキュリティポリシーを再適用または更新して、ボットアカウントを再作成します。
- ボットが誤って不正使用レポートによってBANまたは削除された場合は、GitLab管理者に連絡してください。

## トラブルシューティング {#troubleshooting}

セキュリティポリシーを扱う場合は、次のトラブルシューティングのヒントを考慮してください。

- セキュリティポリシープロジェクトを、開発プロジェクトと、開発プロジェクトが属するグループまたはサブグループの両方にリンクしないでください。両方にリンクすると、マージリクエスト承認ポリシーからの承認ルールが、開発プロジェクトのマージリクエストに適用されなくなります。
- マージリクエスト承認ポリシーを作成する場合、[`scan_finding`ルール](merge_request_approval_policies.md#scan_finding-rule-type)内の配列`severity_levels`や配列`vulnerability_states`を空にしないでください。ルールを正常に機能させるには、各配列に少なくとも1つのエントリが必要です。
- プロジェクトのオーナーは、そのプロジェクトに対してポリシーを適用できますが、グループ内でプロジェクトを作成する権限も持っている必要があります。グループメンバーではないプロジェクトオーナーは、ポリシーの追加または編集が制限される場合があります。プロジェクトのポリシーを管理できない場合は、グループ管理者に問い合わせて、グループ内で必要な権限が自分に付与されているかを確認してください。
- ポリシーの競合については、最も最近適用されたポリシーが優先されます。

それでも問題が発生する場合は、[最近報告されたバグを確認](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=popularity&state=opened&label_name%5B%5D=group%3A%3Asecurity%20policies&label_name%5B%5D=type%3A%3Abug&first_page_size=20)し、まだ報告されていない場合は新しいイシューを作成してください。

### GraphQL APIでポリシーを再同期する {#resynchronize-policies-with-the-graphql-api}

ポリシーが適用されていない、または承認が正しくないなど、いずれかのポリシーに矛盾がある場合は、GraphQL `resyncSecurityPolicies`ミューテーションを使用して、ポリシーの再同期を手動で強制できます。

```graphql
mutation {
  resyncSecurityPolicies(input: { fullPath: "group-or-project-path" }) {
    errors
  }
}
```

`fullPath`には、セキュリティポリシープロジェクトが割り当てられているプロジェクトまたはグループのパスを設定します。

#### GraphQL APIでプロジェクトを再同期する {#resynchronize-projects-with-the-graphql-api}

影響を受けるプロジェクトがグループまたはサブグループからポリシーを継承する場合、そのプロジェクトのみを再同期できます:

```graphql
mutation {
  resyncSecurityPolicies(
    input: {
      fullPath: "project-path"
      relationship: INHERITED
    }
  ) {
    errors
  }
}
```

ポリシーを継承するプロジェクトのパスに`fullPath`を設定します。グループ全体またはサブグループ全体を再同期せずに、そのプロジェクトによって継承されたポリシーを再同期するには、`relationship: INHERITED`を使用します。
