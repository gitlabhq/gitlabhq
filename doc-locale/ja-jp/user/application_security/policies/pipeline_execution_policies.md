---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプライン実行ポリシー
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.2で`pipeline_execution_policy_type`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/13266)されました。デフォルトでは有効になっています。
- GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/454278)になりました。機能フラグ`pipeline_execution_policy_type`は削除されました。

{{< /history >}}

パイプライン実行ポリシーを使用して、単一の設定で複数のプロジェクトのCI/CDジョブを管理および適用します。

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> ビデオチュートリアルについては、[Security Policies:Pipeline Execution Policy Type（セキュリティポリシー: パイプライン実行ポリシーの種類）](https://www.youtube.com/watch?v=QQAOpkZ__pA)をご覧ください。

## スキーマ {#schema}

{{< history >}}

- GitLab 17.4で`suffix`フィールドを[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159858)にしました。
- GitLab 17.7で、`.pipeline-policy-pre`ステージが完了するまで、それ以降のステージが待機するようにパイプラインの実行を[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165096)しました。

{{< /history >}}

パイプライン実行ポリシーを含むYAMLファイルは、`pipeline_execution_policy`キーの下にネストされたパイプライン実行ポリシーのスキーマに一致するオブジェクトの配列で構成されます。セキュリティポリシープロジェクトごとに、`pipeline_execution_policy`キーの下に最大5つのポリシーを設定できます。最初の5つのポリシーの後に設定されたポリシーは適用されません。

新しいポリシーを保存すると、GitLabは[このJSONスキーマ](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json)に照らしてその内容を検証します。[JSONスキーマ](https://json-schema.org/)に精通していない方は、以下のセクションと表を参照してください。

| フィールド | 型 | 必須 | 説明 |
|-------|------|----------|-------------|
| `pipeline_execution_policy` | パイプライン実行ポリシーの`array` | はい | パイプライン実行ポリシーのリスト（最大5つ） |

## `pipeline_execution_policy`スキーマ {#pipeline_execution_policy-schema}

| フィールド | 型 | 必須 | 説明 |
|-------|------|----------|-------------|
| `name` | `string` | はい | ポリシーの名前。最大255文字。|
| `description`（オプション） | `string` | はい | ポリシーの説明。 |
| `enabled` | `boolean` | はい | ポリシーを有効（`true`）または無効（`false`）にするフラグ。 |
| `content` | [`content`](#content-type)の`object` | はい | プロジェクトのパイプラインに挿入するCI/CD設定への参照。 |
| `pipeline_config_strategy` | `string` | いいえ | `inject_policy`、`inject_ci`（非推奨）または`override_project_ci`を指定できます。詳細については、[パイプライン戦略](#pipeline-configuration-strategies)を参照してください。 |
| `policy_scope` | [`policy_scope`](_index.md#configure-the-policy-scope)の`object` | いいえ | 指定したプロジェクト、グループ、またはコンプライアンスフレームワークのラベルに基づいてポリシーのスコープを設定します。 |
| `suffix` | `string` | いいえ | `on_conflict`（デフォルト）または`never`のいずれかを指定できます。ジョブの命名の競合を処理するための動作を定義します。`on_conflict`は、一意性を損なうジョブに対して、ジョブ名に一意のサフィックスを適用します。`never`は、プロジェクトおよび適用可能なすべてのポリシーでジョブ名が一意でない場合、パイプラインを失敗させます。 |
| `skip_ci` | [`skip_ci`](pipeline_execution_policies.md#skip_ci-type)の`object` | いいえ | ユーザーが`skip-ci`ディレクティブを適用できるかどうかを定義します。デフォルトでは、`skip-ci`の使用は無視されるため、パイプライン実行ポリシーを含むパイプラインはスキップできません。 |
| `variables_override` | [`variables_override`](pipeline_execution_policies.md#variables_override-type)の`object` | いいえ | ポリシー変数の動作をユーザーがオーバーライドできるかどうかを制御します。デフォルトでは、ポリシー変数は最優先で適用され、ユーザーはオーバーライドできません。 |

注意点:

- パイプラインをトリガーするユーザーには、少なくとも、パイプライン実行ポリシーに指定されたパイプライン実行ファイルに対する読み取りアクセス権が必要です。そうでない場合、パイプラインは開始されません。
- パイプライン実行ファイルの削除または名前の変更が行われた場合、ポリシーが適用されたプロジェクトのパイプラインが動作しなくなる可能性があります。
- パイプライン実行ポリシーのジョブは、次の2つの予約済みステージのいずれかに割り当てることができます。
  - パイプラインの先頭にある`.pipeline-policy-pre`（`.pre`ステージの前）。
  - パイプラインの最後にある`.pipeline-policy-post`（`.post`ステージの後）。
- 予約済みステージのいずれかにジョブを挿入すると、常に動作することが保証されます。実行ポリシーのジョブは、標準（ビルド、テスト、デプロイ）ステージまたはユーザー定義のステージに割り当てることもできます。ただし、この場合、ジョブはプロジェクトのパイプライン設定に応じて無視されることがあります。
- パイプライン実行ポリシーの外部でジョブを予約済みステージに割り当てることはできません。
- パイプライン実行ポリシーには、一意のジョブ名を選択してください。一部のCI/CD設定はジョブ名に基づいているため、同じパイプラインに同じジョブ名が複数ある場合、望ましくない結果が生じる可能性があります。たとえば、`needs`キーワードを使用すると、あるジョブが別のジョブに依存します。`example`という名前のジョブが複数ある場合、`example`ジョブ名を`needs`で指定しているジョブは、複数の`example`ジョブインスタンスの中からランダムに1つだけに依存します。
- パイプライン実行ポリシーは、プロジェクトにCI/CD設定ファイルがない場合でも有効です。
- 適用されるサフィックスについては、ポリシーの順序が重要になります。
- 特定のプロジェクトに適用されるポリシーに`suffix: never`があり、同じ名前の別のジョブがパイプラインにすでに存在する場合は、パイプラインが失敗します。
- パイプライン実行ポリシーは、すべてのブランチおよびパイプラインソースで適用されます。[ワークフロールール](../../../ci/yaml/workflow.md)を使用して、パイプライン実行ポリシーを適用するタイミングを制御できます。

### `.pipeline-policy-pre`ステージ {#pipeline-policy-pre-stage}

`.pipeline-policy-pre`ステージのジョブは常に実行されます。このステージは、セキュリティとコンプライアンスのユースケース向けに設計されています。`.pipeline-policy-pre`ステージが完了するまで、パイプライン内のジョブは開始されません。

ワークフローでこの動作が不要な場合は、代わりに`.pre`ステージまたはカスタムステージを使用できます。

#### `.pipeline-policy-pre`が成功することを確認する {#ensure-that-pipeline-policy-pre-succeeds}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< alert type="note" >}}

この機能は実験的なものであり、今後のリリースで変更される可能性があります。本番環境では不安定になる可能性があるため、本番環境以外の環境でのみ十分にテストしてください。

{{< /alert >}}

`.pipeline-policy-pre`が完了して成功することを確認するには、セキュリティポリシー設定で`ensure_pipeline_policy_pre_succeeds`実験を有効にします。`.gitlab/security-policies/policy.yml` YAML設定ファイルは、セキュリティポリシープロジェクトに保存されています。

```yaml
experiments:
  ensure_pipeline_policy_pre_succeeds:
    enabled: true
```

`.pipeline-policy-pre`ステージが失敗するか、このステージ内のすべてのジョブがスキップされた場合、以降のステージ内のすべてのジョブがスキップされます。これには、次のジョブが含まれます。

- `needs: []`を使用したジョブ
- `when: always`を使用したジョブ

複数のパイプライン実行ポリシーが適用される場合、それらのいずれかで実験が有効になっていれば、その実験が有効になり、`.pipeline-policy-pre`が必ず成功します。

### ジョブの命名に関するベストプラクティス {#job-naming-best-practice}

{{< history >}}

- 命名の競合処理はGitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/473189)されました。

{{< /history >}}

ジョブがセキュリティポリシーによって生成されたことを示す目に見えるインジケーターはありません。ポリシーによって作成されたジョブを特定しやすくし、ジョブ名の衝突を回避するために、ジョブ名に一意のプレフィックスまたはサフィックスを付加します。

例:

- `policy1:deployments:sast`を使用してください。この名前は、他のすべてのポリシーとプロジェクト全体で一意であると考えられます。
- `sast`を使用しないでください。この名前は、他のポリシーやプロジェクトで重複している可能性があります。

パイプライン実行ポリシーは、`suffix`属性に応じて命名の競合を処理します。同じ名前のジョブが複数ある場合、次のようになります。

- `on_conflict`（デフォルト）を使用すると、ジョブ名がパイプライン内の別のジョブと競合する場合にサフィックスがジョブに追加されます。
- `never`を使用すると、競合が発生した場合にサフィックスは追加されず、パイプラインは失敗します。

サフィックスは、ジョブがメインパイプラインにマージされる順序に基づいて追加されます。

順序は次のとおりです。

1. プロジェクトパイプラインのジョブ
1. プロジェクトポリシーのジョブ（該当する場合）
1. グループポリシーのジョブ（該当する場合、階層順。トップレベルグループが最後に適用される）

適用されるサフィックスの形式は次のとおりです。

`:policy-<security-policy-project-id>-<policy-index>`。

サフィックスが追加されたジョブの例: `sast:policy-123456-0`。

セキュリティポリシープロジェクト内の複数のポリシーが同じジョブ名を定義している場合、数値サフィックスは競合するポリシーのインデックスに対応します。

サフィックスが追加されたジョブの例:

- `sast:policy-123456-0`
- `sast:policy-123456-1`

### ジョブステージに関するベストプラクティス {#job-stage-best-practice}

パイプライン実行ポリシーで定義されたジョブは、プロジェクトのCI/CD設定で定義された任意の[ステージ](../../../ci/yaml/_index.md#stage)を使用でき、予約済みステージ`.pipeline-policy-pre`と`.pipeline-policy-post`も使用できます。

{{< alert type="note" >}}

ポリシーに`.pre`ステージと`.post`ステージのみのジョブが含まれている場合、ポリシーのパイプラインは`empty`として評価されます。これは、プロジェクトのパイプラインとマージされません。

パイプライン実行ポリシーで`.pre`ステージと`.post`ステージを使用するには、別のステージで実行されるジョブを少なくとも1つ含める必要があります。たとえば、`.pipeline-policy-pre`のようになります。

{{< /alert >}}

`inject_policy`[パイプライン戦略](#pipeline-configuration-strategies)を使用するときに、対象のプロジェクトに独自の`.gitlab-ci.yml`ファイルがない場合、すべてのポリシーステージがパイプラインに挿入されます。

（非推奨の）`inject_ci`[パイプライン戦略](#pipeline-configuration-strategies)を使用するときに、対象のプロジェクトに独自の`.gitlab-ci.yml`ファイルがない場合、使用できるステージはデフォルトのパイプラインステージと予約済みステージのみになります。

変更する権限がないCI/CD設定を持つプロジェクトにパイプライン実行ポリシーを適用する場合は、`.pipeline-policy-pre`ステージと`.pipeline-policy-post`ステージでジョブを定義する必要があります。これらのステージは、プロジェクトのCI/CD設定に関係なく、常に使用できます。

`override_project_ci`[パイプライン戦略](#pipeline-configuration-strategies)、複数のパイプライン実行ポリシー、カスタムステージを同時に使用する場合、ステージを同じ相対順序で定義して、相互の互換性を確保する必要があります。

有効な設定例:

```yaml
  - override-policy-1 stages: [build, test, policy-test, deploy]
  - override-policy-2 stages: [test, deploy]
```

無効な設定例:

```yaml
  - override-policy-1 stages: [build, test, policy-test, deploy]
  - override-policy-2 stages: [deploy, test]
```

1つ以上の`override_project_ci`ポリシーに無効な`stages`設定がある場合、パイプラインは失敗します。

### `content`型 {#content-type}

| フィールド | 型 | 必須 | 説明 |
|-------|------|----------|-------------|
| `project` | `string` | はい | 同じGitLabインスタンス上のプロジェクトへのGitLabプロジェクトのフルパス。 |
| `file` | `string` | はい | ルートディレクトリ（/）を基準にしたファイルのフルパス。YAMLファイルの拡張子は`.yml`または`.yaml`でなければなりません。 |
| `ref` | `string` | いいえ | ファイルの取得元のref。指定しない場合、デフォルトはプロジェクトのHEADです。 |

別のリポジトリに保存されているCI/CD設定を参照するには、ポリシーで`content`タイプを使用します。これにより、複数のポリシーで同じCI/CD設定を再利用できるため、これらの設定のメンテナンスのオーバーヘッドを削減できます。たとえば、ポリシーAとポリシーBで適用するカスタムシークレット検出CI/CD設定がある場合は、1つのYAML設定ファイルを作成し、両方のポリシーでその設定を参照できます。

前提要件:

- `content`タイプを含むポリシーが適用されているプロジェクトでパイプライン実行をトリガーするユーザーには、少なくとも、CI/CDを含むプロジェクトに対する読み取り専用アクセス権が必要です。
- パイプライン実行ポリシーを適用するプロジェクトでは、パイプラインをトリガーするために、ユーザーに少なくとも、CI/CD設定を含むプロジェクトに対する読み取り専用アクセス権が必要です。

  GitLab 17.4以降では、`content`タイプを使用して、セキュリティポリシープロジェクトで指定されたCI/CD設定ファイルに必要な読み取り専用アクセス権を付与できます。これを行うには、セキュリティポリシープロジェクトの一般設定で**パイプライン実行ポリシー**設定を有効にします。この設定を有効にすると、パイプラインをトリガーしたユーザーに、パイプライン実行ポリシーによって適用されるCI/CD設定ファイルを読み取るためのアクセス権が付与されます。この設定では、設定ファイルが保存されているプロジェクトの他の部分へのアクセス権はユーザーに付与されません。詳細については、[アクセス権を自動的に付与する](#grant-access-automatically)を参照してください。

### `skip_ci`型 {#skip_ci-type}

{{< history >}}

- GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173480)されました。

{{< /history >}}

パイプライン実行ポリシーは、誰が`[skip ci]`ディレクティブを使用できるかを制御します。`[skip ci]`を使用できる特定のユーザーまたはサービスアカウントを指定すると同時に、重要なセキュリティとコンプライアンスのチェックが確実に実行されるようにすることができます。

`skip_ci`キーワードを使用して、ユーザーが`skip_ci`ディレクティブを適用してパイプラインをスキップできるかどうかを指定します。キーワードを指定しなかった場合、`skip_ci`ディレクティブは無視され、すべてのユーザーはパイプライン実行ポリシーをバイパスできません。

| フィールド                   | 型     | 使用可能な値          | 説明 |
|-------------------------|----------|--------------------------|-------------|
| `allowed` | `boolean`   | `true`、`false` | パイプライン実行ポリシーが適用されたパイプラインで、`skip-ci`ディレクティブの使用を許可（`true`）または禁止（`false`）するフラグ。 |
| `allowlist`             | `object` | `users` | `allowed`フラグに関係なく、`skip-ci`ディレクティブの使用が常に許可されるユーザーを指定します。`users:`の後に、ユーザーIDを表す`id`キーを含んだオブジェクトの配列を指定します。 |

### `variables_override`型 {#variables_override-type}

{{< history >}}

- GitLab 18.1で[導入](https://gitlab.com/groups/gitlab-org/-/epics/16430)されました。

{{< /history >}}

| フィールド                   | 型     | 使用可能な値          | 説明 |
|-------------------------|----------|--------------------------|-------------|
| `allowed` | `boolean`   | `true`、`false` | `true`の場合、他の設定はポリシー変数をオーバーライドできます。`false`の場合、他の設定はポリシー変数をオーバーライドできません。 |
| `exceptions` | `array` | `array`の`string` | グローバルルールの例外となる変数。`allowed: false`の場合、`exceptions`は許可リストです。`allowed: true`の場合、`exceptions`は拒否リストです。 |

このオプションは、ポリシーが適用されたパイプラインでユーザー定義変数がどのように処理されるかを制御します。この機能を使用すると、次のことが可能になります。

- デフォルトでユーザー定義変数を拒否します（推奨）。これにより、セキュリティが強化されますが、カスタマイズ可能なすべての変数を`exceptions`許可リストに追加する必要があります。
- デフォルトでユーザー定義変数を許可します。これにより、柔軟性が向上しますが、ポリシーの適用に影響を与える可能性のある変数を`exceptions`拒否リストに追加する必要があるため、セキュリティは低下します。
- `allowed`グローバルルールに例外を定義します。

ユーザー定義変数は、パイプライン内の任意のポリシージョブの動作に影響を与える可能性があり、さまざまなソースから送信される可能性があります。

- [パイプライン変数](../../../ci/variables/_index.md#use-pipeline-variables)。
- [プロジェクト変数](../../../ci/variables/_index.md#for-a-project)。
- [グループ変数](../../../ci/variables/_index.md#for-a-group)。
- [インスタンス変数](../../../ci/variables/_index.md#for-an-instance)。

`variables_override`オプションが指定されていない場合、「最優先」の動作が保持されます。この動作の詳細については、[パイプライン実行ポリシーでの変数の優先順位](#precedence-of-variables-in-pipeline-execution-policies)を参照してください。

パイプライン実行ポリシーが変数の優先順位を制御する場合、ジョブログには設定された`variables_override`オプションとポリシー名が記述されます。これらのログを表示するには、`gitlab-runner`をバージョン18.1以降に更新する必要があります。

#### `variables_override`の設定例 {#example-variables_override-configuration}

`variables_override`オプションをパイプライン実行ポリシー設定に追加します。

```yaml
pipeline_execution_policy:
  - name: Security Scans
    description: 'Enforce security scanning'
    enabled: true
    pipeline_config_strategy: inject_policy
    content:
      include:
        - project: gitlab-org/security-policies
          file: security-scans.yml
    variables_override:
      allowed: false
      exceptions:
        - CS_IMAGE
        - SAST_EXCLUDED_ANALYZERS
```

##### コンテナカスタマイズを許可しながらセキュリティスキャンを適用する（許可リストアプローチ） {#enforcing-security-scans-while-allowing-container-customization-allowlist-approach}

セキュリティスキャンを適用しながら、プロジェクトチームが独自のコンテナイメージを指定できるようにするには、次のようにします。

```yaml
variables_override:
  allowed: false
  exceptions:
    - CS_IMAGE
```

この設定は、`CS_IMAGE`を除くすべてのユーザー定義変数をブロックし、セキュリティスキャンを無効にできないようにしながら、チームがコンテナイメージをカスタマイズできるようにします。

##### 特定のセキュリティ変数のオーバーライドを防ぐ（拒否リストアプローチ） {#prevent-specific-security-variable-overrides-denylist-approach}

ほとんどの変数を許可しながら、セキュリティスキャンを無効にできないようにするには、次のようにします。

```yaml
variables_override:
  allowed: true
  exceptions:
    - SECRET_DETECTION_DISABLED
    - SAST_DISABLED
    - DEPENDENCY_SCANNING_DISABLED
    - DAST_DISABLED
    - CONTAINER_SCANNING_DISABLED
```

この設定では、セキュリティスキャンを無効にする可能性のあるものを除き、すべてのユーザー定義変数を許可します。

{{< alert type="warning" >}}

この設定は柔軟性を備えていますが、セキュリティへの影響があるため、推奨されません。`exceptions`に明示的にリストされていない変数は、ユーザーが挿入できます。そのため、ポリシー設定は、`allowlist`アプローチを利用した場合ほど適切に保護されません。

{{< /alert >}}

### `policy scope`スキーマ {#policy-scope-schema}

ポリシーの適用をカスタマイズするには、ポリシーのスコープを定義して、指定したプロジェクト、グループ、またはコンプライアンスフレームワークのラベルを含めるか、除外します。詳細については、[スコープ](_index.md#configure-the-policy-scope)を参照してください。

## CI/CD設定へのアクセスを管理する {#manage-access-to-the-cicd-configuration}

プロジェクトにパイプライン実行ポリシーを適用する場合、パイプラインをトリガーするユーザーには、少なくとも、ポリシーのCI/CD設定を含むプロジェクトに対する読み取り専用アクセス権が必要です。プロジェクトへのアクセス権は手動または自動で付与できます。

### アクセス権を手動で付与する {#grant-access-manually}

パイプライン実行ポリシーが適用されたパイプラインをユーザーまたはグループが実行できるようにするには、ポリシーのCI/CD設定を含むプロジェクトに招待します。

### アクセス権を自動的に付与する {#grant-access-automatically}

パイプライン実行ポリシーが適用されたプロジェクトでパイプラインを実行するすべてのユーザーに対して、ポリシーのCI/CD設定へのアクセス権を自動的に付与できます。

前提要件:

- パイプライン実行ポリシーのCI/CD設定がセキュリティポリシープロジェクトに保存されていることを確認してください。
- セキュリティポリシープロジェクトの一般設定で、**パイプライン実行ポリシー**設定を有効にします。

セキュリティポリシープロジェクトがまだなく、最初のパイプライン実行ポリシーを作成する場合は、空のプロジェクトを作成し、セキュリティポリシープロジェクトとしてリンクします。プロジェクトをリンクするには、次の手順を実行します。

1. ポリシーを適用するグループまたはプロジェクトで、**セキュリティ** > **ポリシー** > **ポリシープロジェクトを編集**を選択します。
1. セキュリティポリシープロジェクトを選択します。

プロジェクトはセキュリティポリシープロジェクトになり、設定が利用可能になります。

{{< alert type="note" >}}

`$CI_JOB_TOKEN`を使用してダウンストリームパイプラインを作成するには、プロジェクトとグループによるセキュリティポリシープロジェクトのリクエストが許可されていることを確認する必要があります。セキュリティポリシープロジェクトで、**設定 > CI/CD > ジョブトークンの権限**に移動し、許可されたグループとプロジェクトを許可リストに追加します。**CI/CD**設定が表示されない場合は、**設定 > 一般 > 可視性、プロジェクトの機能、権限**に移動し、**CI/CD**を有効にします。

{{< /alert >}}

#### 設定 {#configuration}

1. ポリシープロジェクトで、**設定** > **一般** > **可視性、プロジェクトの機能、権限**を選択します。
1. 設定**パイプライン実行ポリシー: セキュリティポリシーのソースとしてこのセキュリティポリシープロジェクトにリンクされているプロジェクトのCI/CD設定へのアクセス権を付与します**を有効にします。
1. ポリシープロジェクトで、ポリシーのCI/CD設定のファイルを作成します。

   ```yaml
   # policy-ci.yml

   policy-job:
     script: ...
   ```

1. ポリシーを適用するグループまたはプロジェクトで、パイプライン実行ポリシーを作成し、セキュリティポリシープロジェクトのCI/CD設定ファイルを指定します。

   ```yaml
   pipeline_execution_policy:
   - name: My pipeline execution policy
     description: Enforces CI/CD jobs
     enabled: true
     pipeline_config_strategy: inject_policy
     content:
       include:
       - project: my-group/my-security-policy-project
         file: policy-ci.yml
   ```

## パイプライン設定の戦略 {#pipeline-configuration-strategies}

パイプライン設定の戦略は、ポリシー設定をプロジェクトパイプラインにマージする方法を定義します。パイプライン実行ポリシーは、`.gitlab-ci.yml`ファイルで定義されたジョブを分離されたパイプラインで実行します。このパイプラインは対象のプロジェクトのパイプラインにマージされます。

### `inject_policy`型 {#inject_policy-type}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/475152)されました。

{{< /history >}}

この戦略では、プロジェクトの元のCI/CD設定を完全に置き換えることなく、カスタムCI/CD設定を既存のプロジェクトパイプラインに追加します。これは、新しいセキュリティスキャン、コンプライアンスチェック、カスタムスクリプトの追加など、追加の手順で現在のパイプラインを強化または拡張する場合に適しています。

非推奨の`inject_ci`戦略とは異なり、`inject_policy`を使用すると、カスタムポリシーのステージをパイプラインに挿入できるため、CI/CDワークフローでポリシールールが適用される場所をよりきめ細かく制御できます。

複数のポリシーが有効になっている場合、この戦略は各ポリシーからすべてのジョブを挿入します。

この戦略を使用する場合、各パイプラインには分離されたYAML設定があるため、プロジェクトのCI/CD設定はポリシーパイプラインで定義された動作をオーバーライドできません。

`.gitlab-ci.yml`ファイルがないプロジェクトの場合、この戦略は`.gitlab-ci.yml`ファイルを暗黙的に作成します。実行されるパイプラインには、パイプライン実行ポリシーで定義されたジョブのみが追加されます。

{{< alert type="note" >}}

パイプライン実行ポリシーで、ポリシージョブが実行されないようにするワークフロールールを使用する場合、プロジェクトのCI/CDジョブのみが実行されます。プロジェクトで、プロジェクトのCI/CDジョブが実行されないようにするワークフロールールを使用する場合、パイプライン実行ポリシーのジョブのみが実行されます。

{{< /alert >}}

#### ステージの挿入 {#stages-injection}

ポリシーパイプラインのステージは、通常のCI/CD設定に従います。カスタムステージの前後にステージを挿入することにより、カスタムポリシーステージをプロジェクトパイプラインに挿入する順序を定義します。

プロジェクトとポリシーのパイプラインステージは、有向非巡回グラフ（DAG）で表されます。この場合、ノードがステージであり、エッジが依存関係を表します。パイプラインを組み合わせる場合、個別のDAGは1つの大きなDAGにマージされます。その後、トポロジカルソートが実行され、すべてのパイプラインのステージを実行する順序が決定されます。このソートにより、最終的な順序ですべての依存関係が確実に守られます。競合する依存関係がある場合、パイプラインは実行に失敗します。依存関係を修正するには、プロジェクトとポリシーで使用するステージが一致していることを確認します。

ポリシーパイプライン設定でステージが明示的に定義されていない場合、パイプラインはデフォルトのステージ`stages: [build, test, deploy]`を使用します。これらのステージが含まれているにもかかわらず、異なる順序でリストされている場合、パイプラインは`Cyclic dependencies detected when enforcing policies`エラーで失敗します。

以下の例は、この動作を示しています。すべての例は、以下のプロジェクトのCI/CD設定を前提としています。

```yaml
# .gitlab-ci.yml
stages: [build, test, deploy]

project-build-job:
  stage: build
  script: ...

project-test-job:
  stage: test
  script: ...

project-deploy-job:
  stage: deploy
  script: ...
```

##### 例1 {#example-1}

```yaml
# policy-ci.yml
stages: [test, policy-stage, deploy]

policy-job:
  stage: policy-stage
  script: ...
```

この例では、`policy-stage`ステージは次の場所に挿入する必要があります。

- 存在する場合、`test`ステージの後
- 存在する場合、`deploy`ステージの前

結果: パイプラインには、ステージ`[build, test, policy-stage, deploy]`が含まれます。

特別なケース:

- `.gitlab-ci.yml`がステージを`[build, deploy, test]`として指定した場合、制約を満たすことができないため、パイプラインはエラー`Cyclic dependencies detected when enforcing policies`で失敗します。失敗を修正するには、プロジェクト設定を調整して、ステージをポリシーに合わせます。
- `.gitlab-ci.yml`がステージを`[build]`として指定した場合、結果のパイプラインにはステージ`[build, policy-stage]`が含まれます。

##### 例2 {#example-2}

```yaml
# policy-ci.yml
stages: [policy-stage, deploy]

policy-job:
  stage: policy-stage
  script: ...
```

この例では、`policy-stage`ステージは次の場所に挿入する必要があります。

- 存在する場合、`deploy`ステージの前

結果: パイプラインには、ステージ`[build, test, policy-stage, deploy]`が含まれます。

特別なケース:

- `.gitlab-ci.yml`がステージを`[build, deploy, test]`として指定した場合、結果のパイプラインのステージは`[build, policy-stage, deploy, test]`になります。
- プロジェクトパイプラインに`deploy`ステージがない場合、`policy-stage`ステージはパイプラインの最後（`.pipeline-policy-post`の直前）に挿入されます。

##### 例3 {#example-3}

```yaml
# policy-ci.yml
stages: [test, policy-stage]

policy-job:
  stage: policy-stage
  script: ...
```

この例では、`policy-stage`ステージは次の場所に挿入する必要があります。

- 存在する場合、`test`ステージの後

結果: パイプラインには、ステージ`[build, test, deploy, policy-stage]`が含まれます。

特別なケース:

- プロジェクトパイプラインに`test`ステージがない場合、`policy-stage`ステージはパイプラインの最後（`.pipeline-policy-post`の直前）に挿入されます。

##### 例4 {#example-4}

```yaml
# policy-ci.yml
stages: [policy-stage]

policy-job:
  stage: policy-stage
  script: ...
```

この例では、`policy-stage`ステージには制約がありません。

結果: パイプラインには、ステージ`[build, test, deploy, policy-stage]`が含まれます。

##### 例5 {#example-5}

```yaml
# policy-ci.yml
stages: [check, lint, test, policy-stage, deploy, verify, publish]

policy-job:
  stage: policy-stage
  script: ...
```

この例では、`policy-stage`ステージは次の場所に挿入する必要があります。

- 存在する場合、`check`、`lint`、`test`ステージの後
- 存在する場合、`deploy`、`verify`、`publish`ステージの前

結果: パイプラインには、ステージ`[build, test, policy-stage, deploy]`が含まれます。

特別なケース:

- `.gitlab-ci.yml`がステージを`[check, publish]`として指定した場合、結果のパイプラインにはステージ`[check, policy-stage, publish]`が含まれます。

#### デフォルトのステージ順序 {#default-stage-order}

ポリシーでステージが定義されていない場合、GitLabは、次のデフォルトのステージ順序を適用します。

1. `.pre`
1. `build`
1. `test`
1. `deploy`
1. `.post`

デフォルトの順序は、これらのデフォルトステージを異なる順序で使用するプロジェクトと競合する可能性があります。たとえば、`stages: [test, build, deploy]`で`test`を`build`の前に使用する場合です。

#### 循環依存関係を回避する {#avoiding-cyclic-dependencies}

循環依存関係のエラーは、ポリシーのステージ順序がプロジェクトのステージ順序と競合する場合に発生します。これらのエラーを回避するには、次のようにします。

- ステージ順序を明確にして、プロジェクトと互換性があるようにするために、ポリシーでステージを常に明示的に定義します。ポリシーでデフォルトステージの`build`、`test`、または`deploy`を使用する場合は、順序がすべてのプロジェクトで適用されることに注意してください。
- 予約済みステージ（`.pipeline-policy-pre`および`.pipeline-policy-post`）のみを使用する場合は、これらの予約済みステージは常にパイプラインの最初と最後に配置されるため、ポリシーでデフォルトステージを定義する必要はありません。

これらのガイドラインに従うことで、異なるステージ設定を持つプロジェクト間で確実に動作するポリシーを作成できます。

### `inject_ci`（非推奨） {#inject_ci-deprecated}

{{< alert type="warning" >}}

この機能は、GitLab 17.9で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/475152)になりました。代わりに[`inject_policy`](#inject_policy-type)を使用してください。この機能はカスタムポリシーのステージの適用をサポートしています。

{{< /alert >}}

この戦略では、プロジェクトの元のCI/CD設定を完全に置き換えることなく、カスタムCI/CD設定を既存のプロジェクトパイプラインに追加します。これは、新しいセキュリティスキャン、コンプライアンスチェック、カスタムスクリプトの追加など、追加の手順で現在のパイプラインを強化または拡張する場合に適しています。

複数のポリシーを有効にすると、すべてのジョブが付加的に挿入されます。

この戦略を使用する場合、各パイプラインには分離されたYAML設定があるため、プロジェクトのCI/CD設定はポリシーパイプラインで定義された動作をオーバーライドできません。

`.gitlab-ci.yml`ファイルがないプロジェクトの場合、この戦略は`.gitlab-ci.yml`ファイルを暗黙的に作成します。つまり、パイプライン実行ポリシーで定義されたジョブのみを含むパイプラインが実行されます。

{{< alert type="note" >}}

パイプライン実行ポリシーで、ポリシージョブが実行されないようにするワークフロールールを使用する場合、プロジェクトのCI/CDジョブのみが実行されます。プロジェクトで、プロジェクトのCI/CDジョブが実行されないようにするワークフロールールを使用する場合、パイプライン実行ポリシーのジョブのみが実行されます。

{{< /alert >}}

### `override_project_ci` {#override_project_ci}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175088)されたワークフロールールの処理は、`policies_always_override_project_ci`[フラグ](../../../administration/feature_flags/_index.md)とともに更新されました。デフォルトでは有効になっています。
- GitLab 17.9で、[`override_project_ci`の更新された処理](https://gitlab.com/gitlab-org/gitlab/-/issues/504434)により、スキャン実行ポリシーがパイプライン実行ポリシーと一緒に実行できるようになりました。
- ワークフロールールの更新された処理は、GitLab 17.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/512877)になりました。機能フラグ`policies_always_override_project_ci`は削除されました。

{{< /history >}}

この戦略は、プロジェクトの既存のCI/CD設定を、パイプライン実行ポリシーによって定義された新しい設定に置き換えます。この戦略は、組織全体のCI/CD標準や、規制の厳しい業界のコンプライアンス要件を適用する場合など、パイプライン全体を標準化または置き換える必要がある場合に最適です。パイプライン設定をオーバーライドするには、CI/CDジョブを定義し、`include:project`を使用しないでください。

この戦略は、`inject_ci`戦略または`inject_policy`戦略を使用する他のポリシーよりも優先されます。`override_project_ci`を含むポリシーが適用される場合、プロジェクトのCI/CD設定は無視されます。ただし、他のセキュリティポリシー設定はオーバーライドされません。

スキャン実行ポリシーとパイプライン実行ポリシーの両方で`override_project_ci`を使用すると、CI/CD設定がマージされ、両方のポリシーが結果のパイプラインに適用されます。

または、プロジェクトのCI/CD設定をオーバーライドする代わりに、プロジェクトの`.gitlab-ci.yml`とマージできます。設定をマージするには、`include:project`を使用します。この戦略を使用すると、ユーザーはプロジェクトのCI/CD設定をパイプライン実行ポリシー設定に含めることができるため、ユーザーはポリシーのジョブをカスタマイズできます。たとえば、ポリシーとプロジェクトのCI/CD設定を1つのYAMLファイルに結合して、`before_script`設定をオーバーライドしたり、スキャンするコンテナに必要なパスを定義するために`CS_IMAGE`などの必要な変数を定義したりできます。[こちら](https://youtu.be/W8tubneJ1X8)に、この動作の短いデモがあります。次の図は、プロジェクトレベルおよびポリシーレベルで定義された変数が、結果のパイプラインでどのように選択されるかを示しています。

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
graph TB

classDef yaml text-align:left

ActualPolicyYAML["<pre>
variables:
  MY_VAR: 'policy'
policy-job:
  stage: test
</pre>"]

class ActualPolicyYAML yaml

ActualProjectYAML["<pre>
variables:
  MY_VAR: 'project'
project-job:
  stage: test
</pre>"]

class ActualProjectYAML yaml

PolicyVariablesYAML["<pre>
variables:
  MY_VAR: 'policy'
</pre>"]

class PolicyVariablesYAML yaml

ProjectVariablesYAML["<pre>
variables:
  MY_VAR: 'project'
</pre>"]

class ProjectVariablesYAML yaml

ResultingPolicyVariablesYAML["<pre>
variables:
  MY_VAR: 'policy'
</pre>"]

class ResultingPolicyVariablesYAML yaml

ResultingProjectVariablesYAML["<pre>
variables:
  MY_VAR: 'project'
</pre>"]

class ResultingProjectVariablesYAML yaml

PolicyCiYAML(Policy CI YAML) --> ActualPolicyYAML
ProjectCiYAML(<code>.gitlab-ci.yml</code>) --> ActualProjectYAML

subgraph "Policy Pipeline"
  subgraph "Test stage"
    subgraph "<code>policy-job</code>"
      PolicyVariablesYAML
    end
  end
end

subgraph "Project Pipeline"
  subgraph "Test stage"
    subgraph "<code>project-job</code>"
      ProjectVariablesYAML
    end
  end
end

ActualPolicyYAML -- "Used as source" --> PolicyVariablesYAML
ActualProjectYAML -- "Used as source" --> ProjectVariablesYAML

subgraph "Resulting Pipeline"
  subgraph "Test stage"
    subgraph "<code>policy-job</code> "
      ResultingPolicyVariablesYAML
    end

    subgraph "<code>project-job</code> "
      ResultingProjectVariablesYAML
    end
  end
end

PolicyVariablesYAML -- "Inject <code>policy-job</code> if Test Stage exists" --> ResultingPolicyVariablesYAML
ProjectVariablesYAML -- "Basis of the resulting pipeline" --> ResultingProjectVariablesYAML
```

{{< alert type="note" >}}

パイプライン実行ポリシーのワークフロールールは、プロジェクトの元のCI/CD設定をオーバーライドします。ポリシーでワークフロールールを定義することにより、ブランチパイプラインの使用を禁止するなど、リンクされているすべてのプロジェクトに適用されるルールを設定できます。

{{< /alert >}}

### パイプライン実行ポリシーの設定にプロジェクトのCI/CD設定を含める {#include-a-projects-cicd-configuration-in-the-pipeline-execution-policy-configuration}

`override_project_ci`戦略を使用する場合、プロジェクトの設定をパイプライン実行ポリシーの設定に含めることができます。

```yaml
include:
  - project: $CI_PROJECT_PATH
    ref: $CI_COMMIT_SHA
    file: $CI_CONFIG_PATH
    rules:
      - exists:
          paths:
            - '$CI_CONFIG_PATH'
          project: '$CI_PROJECT_PATH'
          ref: '$CI_COMMIT_SHA'

compliance_job:
 ...
```

## CI/CD変数 {#cicd-variables}

{{< alert type="warning" >}}

変数はプレーンテキストのポリシー設定の一部としてGitリポジトリに保存されるため、機密情報や認証情報を変数に保存しないでください。

{{< /alert >}}

パイプライン実行ジョブは分離して実行されます。別のポリシーまたはプロジェクトの`.gitlab-ci.yml`ファイルで定義された変数は、パイプライン実行ポリシーでは使用できず、[variables_override type](#variables_override-type)型によって許可されない限り、外部からオーバーライドできません。

変数は、グループまたはプロジェクトの設定を使用してパイプライン実行ポリシーと共有できます。これは、標準の[CI/CD変数の優先順位](../../../ci/variables/_index.md#cicd-variable-precedence)ルールに従います。ただし、優先順位ルールは、パイプライン実行ポリシー戦略に応じて異なる可能性があるため、パイプライン実行ポリシーを使用する場合はより複雑になります。

- `inject_policy`戦略: 変数がパイプライン実行ポリシーで定義されている場合、ジョブは常にこの値を使用します。変数がパイプライン実行ポリシーで定義されていない場合、ジョブはグループまたはプロジェクトの設定からの値を適用します。
- `inject_ci`戦略: 変数がパイプライン実行ポリシーで定義されている場合、ジョブは常にこの値を使用します。変数がパイプライン実行ポリシーで定義されていない場合、ジョブはグループまたはプロジェクトの設定からの値を適用します。
- `override_project_ci`戦略: 結果のパイプライン内のすべてのジョブは、ポリシーのジョブとして処理されます。ポリシーで定義された変数（含まれているファイル内の変数を含む）は、プロジェクト変数およびグループ変数よりも優先されます。つまり、含まれているプロジェクトのCI/CD設定にあるジョブの変数が、プロジェクトとグループの設定で定義された変数よりも優先されます。

パイプライン実行ポリシーの変数の詳細については、[パイプライン実行ポリシーでの変数の優先順位](#precedence-of-variables-in-pipeline-execution-policies)を参照してください。

[UIでプロジェクトまたはグループの変数を定義できます](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)。

### パイプライン実行ポリシーでの変数の優先順位 {#precedence-of-variables-in-pipeline-execution-policies}

特に`override_project_ci`戦略と一緒にパイプライン実行ポリシーを使用する場合、複数の場所で定義された変数の値の優先順位は、標準のCI/CDパイプラインとは異なる場合があります。理解しておくべき重要な点を次に示します。

- `override_project_ci`を使用する場合、結果のパイプライン内のすべてのジョブは、含まれているプロジェクトのCI/CD設定からのジョブを含め、ポリシーのジョブと見なされます。
- ポリシーパイプラインで定義された変数（インスタンス全体またはジョブを対象）は、プロジェクトまたはグループの設定で定義された変数よりも優先されます。
- この動作は、プロジェクトのCI/CD設定ファイル（`.gitlab-ci.yml`）に含まれているジョブを含め、すべてのジョブに適用されます。

#### 例 {#example}

プロジェクトのCI/CD設定の変数と、含まれている`.gitlab-ci.yml`ファイルに定義されているジョブの変数が同じ名前を持つ場合、`override_project_ci`を使用するとジョブの変数が優先されます。

プロジェクトのCI/CD設定に、`MY_VAR`変数が定義されています。

- キー: `MY_VAR`
- 値: `Project configuration variable value`

含まれているプロジェクトの`.gitlab-ci.yml`に、同じ変数が定義されています。

```yaml
project-job:
  variables:
    MY_VAR: "Project job variable value"
  script:
    - echo $MY_VAR  # This will output "Project job variable value"
```

この場合、ジョブの変数の値`Project job variable value`が優先されます。

## `[skip ci]`を使用する場合の動作 {#behavior-with-skip-ci}

デフォルトでは、標準のパイプラインがトリガーされないようにするために、ユーザーはコミットメッセージに`[skip ci]`を追加して、保護ブランチにコミットをプッシュできます。ただし、ポリシーは`[skip ci]`ディレクティブを無視するため、パイプライン実行ポリシーで定義されたジョブは常にトリガーされます。これにより、デベロッパーはポリシーで定義されたジョブの実行をスキップできなくなり、重要なセキュリティとコンプライアンスのチェックが常に実行されるようになります。

`[skip ci]`動作のより柔軟な制御については、[`skip_ci`タイプ](#skip_ci-type)セクションを参照してください。

## 例 {#examples}

次の例は、パイプライン実行ポリシーで実現できることを示しています。

### パイプライン実行ポリシー {#pipeline-execution-policy}

[セキュリティポリシープロジェクト](enforcement/security_policy_projects.md)に保存されている`.gitlab/security-policies/policy.yml`ファイルで、次の例を使用できます。

```yaml
---
pipeline_execution_policy:
- name: My pipeline execution policy
  description: Enforces CI/CD jobs
  enabled: true
  pipeline_config_strategy: override_project_ci
  content:
    include:
    - project: my-group/pipeline-execution-ci-project
      file: policy-ci.yml
      ref: main # optional
  policy_scope:
    projects:
      including:
      - id: 361
```

### プロジェクト変数に基づいて適用されるジョブをカスタマイズする {#customize-enforced-jobs-based-on-project-variables}

プロジェクト変数の有無に基づいて、適用されるジョブをカスタマイズできます。この例では、`CS_IMAGE`の値は、ポリシーで`alpine:latest`として定義されています。ただし、プロジェクトが`PROJECT_CS_IMAGE`の値も定義している場合、代わりにその値が使用されます。CI/CD変数は、プロジェクトの`.gitlab-ci.yml`ファイルで定義されるのではなく、定義済みのプロジェクト変数である必要があります。

```yaml
variables:
  CS_ANALYZER_IMAGE: "$CI_TEMPLATE_REGISTRY_HOST/security-products/container-scanning:8"
  CS_IMAGE: alpine:latest

policy::container-security:
  stage: .pipeline-policy-pre
  rules:
    - if: $PROJECT_CS_IMAGE
      variables:
        CS_IMAGE: $PROJECT_CS_IMAGE
    - when: always
  script:
    - echo "CS_ANALYZER_IMAGE:$CS_ANALYZER_IMAGE"
    - echo "CS_IMAGE:$CS_IMAGE"
```

### `.gitlab-ci.yml`とアーティファクトを使用して適用されるジョブをカスタマイズする {#customize-enforced-jobs-using-gitlab-ciyml-and-artifacts}

ポリシーパイプラインは分離して実行されるため、パイプライン実行ポリシーは`.gitlab-ci.yml`から変数を直接読み取りできません。プロジェクトのCI/CD設定で変数を定義する代わりに、`.gitlab-ci.yml`の変数を使用する場合は、アーティファクトを使用して、`.gitlab-ci.yml`設定から変数をパイプライン実行ポリシーのパイプラインに渡すことができます。

```yaml
# .gitlab-ci.yml

build-job:
  stage: build
  script:
    - echo "BUILD_VARIABLE=value_from_build_job" >> build.env
  artifacts:
    reports:
      dotenv: build.env
```

```yaml
stages:
- build
- test

test-job:
  stage: test
  script:
    - echo "$BUILD_VARIABLE" # Prints "value_from_build_job"
```

### プロジェクトの設定に`before_script`があるセキュリティスキャナーの動作をカスタマイズする {#customize-security-scanners-behavior-with-before_script-in-project-configurations}

プロジェクトの`.gitlab-ci.yml`にあるポリシーによって適用されるセキュリティジョブの動作をカスタマイズするには、`before_script`をオーバーライドします。これを行うには、ポリシーで`override_project_ci`戦略を使用し、プロジェクトのCI/CD設定を含めます。パイプライン実行ポリシー設定の例を次に示します。

```yaml
# policy.yml
type: pipeline_execution_policy
name: Secret detection
description: >
  This policy enforces secret detection and allows projects to override the
  behavior of the scanner.
enabled: true
pipeline_config_strategy: override_project_ci
content:
  include:
    - project: gitlab-org/pipeline-execution-policies/compliance-project
      file: secret-detection.yml
```

```yaml
# secret-detection.yml
include:
  - project: $CI_PROJECT_PATH
    ref: $CI_COMMIT_SHA
    file: $CI_CONFIG_PATH
  - template: Jobs/Secret-Detection.gitlab-ci.yml
```

プロジェクトの`.gitlab-ci.yml`で、スキャナーの`before_script`を定義できます。

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

secret_detection:
  before_script:
    - echo "Before secret detection"
```

`override_project_ci`を使用し、プロジェクトの設定を含めることで、YAML設定をマージできます。

### リソース固有の変数の制御を設定する {#configure-resource-specific-variable-control}

パイプライン実行ポリシーの変数をオーバーライドするグローバル変数をチームが設定できるようにすると同時に、ジョブ固有のオーバーライドを許可することができます。これにより、チームは、セキュリティスキャンに適切なデフォルトを設定して、他のジョブに適切なリソースを使用できるようになります。

以下を`resource-optimized-scans.yml`に含めます。

```yaml
variables:
  # Default resource settings for all jobs
  KUBERNETES_MEMORY_REQUEST: 4Gi
  KUBERNETES_MEMORY_LIMIT: 4Gi
  # Default values that teams can override via project variables
  SAST_KUBERNETES_MEMORY_REQUEST: 4Gi

sast:
  variables:
    SAST_EXCLUDED_ANALYZERS: 'spotbugs'
    KUBERNETES_MEMORY_REQUEST: $SAST_KUBERNETES_MEMORY_REQUEST
    KUBERNETES_MEMORY_LIMIT: $SAST_KUBERNETES_MEMORY_REQUEST
```

以下を`policy.yml`に含めます。

```yaml
pipeline_execution_policy:
- name: Resource-Optimized Security Policy
  description: Enforces security scans with efficient resource management
  enabled: true
  pipeline_config_strategy: inject_ci
  content:
    include:
    - project: security/policy-templates
      file: resource-optimized-scans.yml
      ref: main

  variables_override:
    allowed: false
    exceptions:
      # Allow scan-specific resource overrides
      - SAST_KUBERNETES_MEMORY_REQUEST
      - SECRET_DETECTION_KUBERNETES_MEMORY_REQUEST
      - CS_KUBERNETES_MEMORY_REQUEST
      # Allow necessary scan customization
      - CS_IMAGE
      - SAST_EXCLUDED_PATHS
```

このアプローチにより、チームは、パイプラインのすべてのジョブに影響を与えることなく、変数のオーバーライドを使用してスキャン固有のリソース変数（`SAST_KUBERNETES_MEMORY_REQUEST`などの）を設定できるので、大規模なプロジェクトのリソース管理を改善できます。この例は、他の一般的なスキャンカスタマイズオプションの使用法も示しています。また、これらのオプションをデベロッパーに対して展開できます。利用可能な変数を文書化して、開発チームが活用できるようにしてください。

### パイプライン実行ポリシーでグループ変数またはプロジェクト変数を使用する {#use-group-or-project-variables-in-a-pipeline-execution-policy}

パイプライン実行ポリシーでグループ変数またはプロジェクト変数を使用できます。

`PROJECT_VAR="I'm a project"`のプロジェクト変数を使用すると、次のパイプライン実行ポリシージョブの結果は`I'm a project`になります。

```yaml
pipeline execution policy job:
    stage: .pipeline-policy-pre
    script:
    - echo "$PROJECT_VAR"
```

### パイプライン実行ポリシーを使用して変数の値を適用する {#enforce-a-variables-value-by-using-a-pipeline-execution-policy}

パイプライン実行ポリシーで定義された変数の値は、同じ名前のグループ変数またはポリシー変数の値をオーバーライドします。この例では、変数`PROJECT_VAR`のプロジェクト値が上書きされ、ジョブの結果は`I'm a pipeline execution policy`になります。

```yaml
variables:
  PROJECT_VAR: "I'm a pipeline execution policy"

pipeline execution policy job:
    stage: .pipeline-policy-pre
    script:
    - echo "$PROJECT_VAR"
```

### セキュリティポリシーのスコープが指定された`policy.yml`の例 {#example-policyyml-with-security-policy-scopes}

この例では、セキュリティポリシーの`policy_scope`で以下を指定します。

- ID `9`が適用されたコンプライアンスフレームワークを持つすべてのプロジェクトを含めます。
- ID `456`のプロジェクトを除外します。

```yaml
pipeline_execution_policy:
- name: Pipeline execution policy
  description: ''
  enabled: true
  pipeline_config_strategy: inject_policy
  content:
    include:
    - project: my-group/pipeline-execution-ci-project
      file: policy-ci.yml
  policy_scope:
    compliance_frameworks:
    - id: 9
    projects:
      excluding:
      - id: 456
```

### パイプライン実行ポリシーで`ci_skip`を設定する {#configure-ci_skip-in-a-pipeline-execution-policy}

次の例では、パイプライン実行ポリシーが適用され、[CIのスキップ](#skip_ci-type)は、ID `75`のユーザーを除き、許可されません。

```yaml
pipeline_execution_policy:
  - name: My pipeline execution policy with ci.skip exceptions
    description: 'Enforces CI/CD jobs'
    enabled: true
    pipeline_config_strategy: inject_policy
    content:
      include:
        - project: group-a/project1
          file: README.md
    skip_ci:
      allowed: false
      allowlist:
        users:
          - id: 75
```

### `exists`条件を設定する {#configure-the-exists-condition}

`exists`ルールを使用して、特定のファイルが存在する場合に、プロジェクトからCI/CD設定ファイルを組み込むようにパイプライン実行ポリシーを設定します。

次の例では、`Dockerfile`が存在する場合、パイプライン実行ポリシーはプロジェクトからCI/CD設定を組み込みます。`'$CI_PROJECT_PATH'`を`project`として使用するように`exists`ルールを設定する必要があります。設定しない場合、GitLabでは、セキュリティポリシーCI/CD設定を保持するプロジェクトのどこにファイルが存在するかが評価されます。

```yaml
include:
  - project: $CI_PROJECT_PATH
    ref: $CI_COMMIT_SHA
    file: $CI_CONFIG_PATH
    rules:
      - exists:
          paths:
            - 'Dockerfile'
          project: '$CI_PROJECT_PATH'
```

このアプローチを使用するには、グループまたはプロジェクトで`override_project_ci`戦略を使用する必要があります。

### パイプライン実行ポリシーを使用してコンテナスキャン`component`を適用する {#enforce-a-container-scanning-component-using-a-pipeline-execution-policy}

セキュリティスキャンコンポーネントを使用して、バージョニングの処理と適用を改善できます。

```yaml
include:
  - component: gitlab.com/components/container-scanning/container-scanning@main
    inputs:
      cs_image: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

container_scanning: # override component with additional configuration
  variables:
    CS_REGISTRY_USER: $CI_REGISTRY_USER
    CS_REGISTRY_PASSWORD: $CI_REGISTRY_PASSWORD
    SECURE_LOG_LEVEL: debug # add for verbose debugging of the container scanner
  before_script:
  - echo $CS_IMAGE # optionally add a before_script for additional debugging
```
