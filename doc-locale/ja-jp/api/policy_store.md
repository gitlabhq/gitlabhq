---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 組織のポリシー保存場所に保存されているセキュリティポリシーを管理するためのREST API。
title: ポリシー保存場所API
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 19.3で`security_policies_v2`[機能フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/606971)されました。デフォルトでは無効になっています。
- GitLab 19.4で、ポリシーをプロセスごとのメモリではなくデータベースに永続化するように[変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/604367)されました。
- GitLab 19.4で`policy_rego`レスポンス属性を追加するように[変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/616505)されました。
- GitLab 19.4で、65536バイトを超えるRegoモジュールにコンパイルされるルールを拒否するように[変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/612905)されました。
- GitLab 19.4で`scope_dimensions`レスポンス属性を追加するように[変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/623359)されました。
- GitLab 19.4で、`rules`と`actions`をそれぞれ5つのエントリに、各エントリを4096バイトに制限するように[変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/612905)されました。
- GitLab 19.4で、`environment_advanced`と`deployment_promoted`トリガーを追加し、`deployment_requested`トリガーの表示名を`Deployment requested`に名称変更するように[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252841)されました。
- GitLab 19.4で、カタログエンドポイントを匿名アクセスではなく認証済み呼び出し元を要求するように[変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/598030)されました。

{{< /history >}}

> [!warning]
> これは[実験的機能](../policy/development_stages_support.md)です。エンドポイントは予告なく変更される場合があります。

このAPIを使用して、ポリシー保存場所で[セキュリティポリシー](../user/application_security/policies/_index.md)を作成します。ポリシーは組織に属し、単一のトリガーに応答し、その動作を構成するルールとアクションを備えています。

これらのエンドポイントは、以下のすべてが真の場合にのみ利用可能です:

- `security_policies_v2`機能フラグが有効になっている場合。
- 管理者が、**管理者** > **設定** > **セキュリティとコンプライアンス**でインスタンスのポリシー保存実験を有効にしている。
- 組織が、`organizationUpdate` GraphQLミューテーションの`policyStoreExperimentEnabled`引数を通じて設定される`policy_store_experiment_enabled`組織設定によりオプトインしていること。

これらのいずれかが真でない場合、エンドポイントは`404 Not Found`を返します。インスタンスがセキュリティオーケストレーションポリシーのライセンスを持っていない場合、`403 Forbidden`を返します。

## カタログ {#catalogs}

カタログエンドポイントは、ポリシーの構築元を記述し、対象となるすべての呼び出し元に同じ静的コンテンツを返します。呼び出し元は、その組織が`security_policies_v2`機能フラグを有効にしている認証済みユーザーである必要があります。これが真でない場合、エンドポイントは`404 Not Found`を返します。

### すべてのトリガーを一覧表示 {#list-all-triggers}

ポリシーが応答できるすべてのトリガーを一覧表示します。

```plaintext
GET /security/policy_store/triggers
```

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | タイプ   | 説明 |
| --------- | ------ | ----------- |
| `[].id`   | 文字列 | ポリシーを作成する際に`trigger_type`として使用される、トリガーのID。 |
| `[].name` | 文字列 | トリガーの表示名。 |

リクエスト例: 

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/security/policy_store/triggers"
```

レスポンス例: 

```json
[
  { "id": "deployment_requested", "name": "Deployment requested" },
  { "id": "environment_advanced", "name": "Environment advanced" },
  { "id": "deployment_promoted", "name": "Deployment promoted" }
]
```

### すべてのアクションを一覧表示 {#list-all-actions}

ポリシーが実行できるすべてのアクションを一覧表示します。

```plaintext
GET /security/policy_store/actions
```

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | タイプ   | 説明 |
| --------- | ------ | ----------- |
| `[].id`   | 文字列 | アクションのID。 |
| `[].name` | 文字列 | アクションの表示名。 |

リクエスト例: 

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/security/policy_store/actions"
```

レスポンス例: 

```json
[
  { "id": "block", "name": "Block" },
  { "id": "require_approval", "name": "Require approval" }
]
```

### すべてのルールタイプを一覧表示 {#list-all-rule-kinds}

ポリシーの構築元となるすべてのルールタイプを一覧表示します。

```plaintext
GET /security/policy_store/rules
```

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | タイプ   | 説明 |
| --------- | ------ | ----------- |
| `[].id`   | 文字列 | ルールタイプのID。 |
| `[].name` | 文字列 | ルールタイプの表示名。 |

リクエスト例: 

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/security/policy_store/rules"
```

レスポンス例: 

```json
[
  { "id": "custom", "name": "Custom" },
  { "id": "calendar", "name": "Calendar" },
  { "id": "environment", "name": "Environment" }
]
```

## ポリシー {#policies}

ポリシーエンドポイントへのすべての呼び出しは[認証済み](rest/authentication.md)である必要があり、呼び出し元は組織のオーナーまたはインスタンス管理者である必要があります。組織を管理できない呼び出し元は`403 Forbidden`を受け取り、組織をまったく表示できない呼び出し元は`404 Not Found`を受け取ります。

別の組織に属するポリシーは、存在しないポリシーと区別できません。IDを使用して組織をまたいでポリシーを読み取ったり変更したりすることはできません。

### ポリシースコープ {#policy-scope}

ポリシーは、スコープを持たない限り、どこにでも適用されます。スコープは次の2つの方法のいずれかで作成され、リクエストはいずれか一方のみを使用でき、両方を同時に使用することはできません:

- `policy_scope`: GitLabが`scope_rego`にコンパイルする構造化されたデータ。
- `scope_rego`: [Rego](https://www.openpolicyagent.org/docs/policy-language)プログラムとして直接提供され、作成されたとおりに保存されるもの。

両方を指定するリクエストは`400 Bad Request`を返します。空の`scope_rego`は2番目の形式とは見なされないため、どちらの操作も`policy_scope`と一緒にそれを受け入れます。[ポリシーの作成](#create-a-policy)では、空の値は省略した場合と同じ効果があります。[ポリシーの更新](#update-a-policy)では、作成されたプログラムを廃止し、`policy_scope`から新しいプログラムをコンパイルします。

スコープを持たないポリシーはすべてのプロジェクトに適用されるプログラムにコンパイルされるため、`scope_rego`は常にレスポンスに存在します。手書きのプログラムには構造化された形式がないため、Regoが直接作成された場合、`policy_scope`は`null`になります。

`scope_dimensions`は、ポリシーが適用されるかどうかを判断するために`scope_rego`が読み取る、`compliance_frameworks`や`project.id`のようなドット区切りのコンテキストパスをリストします。GitLabはこのリストを導出するため、属性に送信する値は無視されます。この値は常に配列であり、ポリシーがスコープ外の場合には空ですが、`policy_scope`からコンパイルされる代わりに`scope_rego`が直接作成された場合は除きます。その場合、GitLabは手書きのプログラムからパスを導出できないため、`scope_dimensions`は`null`となり、パスが空ではなく不明であることを意味します。

#### ポリシースコープ構造 {#policy-scope-structure}

`policy_scope`は1つ以上の基準を保持し、`match_mode`がそれらの組み合わせ方を制御します。基準は、整数として、または`id`キーを持つオブジェクトとしてIDを指定します。GitLabはIDを重複排除してソートするため、作成順序によってコンパイルされたプログラムが変更されることはありません。

| 属性 | タイプ | 説明 |
| --------- | ---- | ----------- |
| `application` | オブジェクト | アプリケーションセキュリティ属性IDの`including`と`excluding`リスト。 |
| `business_impact` | オブジェクト | ビジネス影響セキュリティ属性IDの`including`と`excluding`リスト。 |
| `business_unit` | オブジェクト | ビジネスユニットセキュリティ属性IDの`including`と`excluding`リスト。 |
| `compliance_frameworks` | 配列 | プロジェクトが持つ必要のあるコンプライアンスフレームワークのID。`including`と`excluding`ではなく、リストを直接受け取ります。 |
| `exposure` | オブジェクト | 露出セキュリティ属性IDの`including`と`excluding`リスト。 |
| `groups` | オブジェクト | グループIDの`including`と`excluding`リスト。 |
| `match_mode` | 文字列 | `all`または`any`のいずれか。`all`の場合、すべての基準が一致する必要があります。`any`の場合、1つの一致で十分です。その他の値は`all`として扱われます。 |
| `projects` | オブジェクト | プロジェクトIDの`including`と`excluding`リスト。`excluding`は`{"type": "personal"}`と`{"type": "archived"}`も受け入れ、これらはその種類のすべてのプロジェクトを除外します。 |

例: 

```json
{
  "match_mode": "any",
  "compliance_frameworks": [{ "id": 5 }],
  "projects": { "including": [12, 34], "excluding": [{ "type": "archived" }] },
  "groups": { "including": [{ "id": 7 }] }
}
```

GitLabがIDとして読み取れない値は`400 Bad Request`を返します。これは、数値でない値、および1から9223372036854775807の範囲外の数値に適用されます。

以下の3つのケースは受け入れられ、知っておく価値があります。なぜなら、それぞれが期待されるものとは異なる方法でポリシーをスコープ指定するためです:

- `including`リストでIDが指定されていない場合、その基準には何も一致しません。`match_mode: all`の場合、ポリシーはどのプロジェクトにも適用されません。`match_mode: any`の場合、別の基準が依然として一致する可能性があります。
- `excluding`リストでIDが指定されていない場合、何も除外されません。
- GitLabが認識しない基準は効果がありません。それが唯一の基準であった場合、ポリシーはすべてのプロジェクトに適用されます。

### ルールとアクション {#rules-and-actions}

`rules`と`actions`は配列です。各エントリには次の属性があります:

| 属性 | タイプ           | 必須 | 説明 |
| --------- | -------------- | -------- | ----------- |
| `type`    | 文字列         | はい      | ルールの場合、[すべてのルールタイプを一覧表示](#list-all-rule-kinds)によって返されるIDのいずれか。アクションの場合、[すべてのアクションを一覧表示](#list-all-actions)によって返されるIDのいずれか。 |
| `value`   | 文字列またはハッシュ | いいえ       | エントリが作用する対象。`custom`ルールはRegoソースを文字列として受け取ります。`calendar`または`environment`ルールはハッシュを受け取ります。すべてのアクションも同様です。 |

エントリを空白にすることはできません。空白のエントリは`400 Bad Request`を返し、エラーは各空白の位置の名前を指定します（例: `rules[0] is blank`）。

各配列は最大5つのエントリを受け入れ、各エントリは4096バイトを超えてシリアル化することはできません。いずれかの制限を超えると`400 Bad Request`が返されます。サイズ超過のエントリは、各違反位置の名前を指定します（例: `rules has an entry exceeding maximum size of 4096 bytes at 0`）。

リクエストは配列全体を置き換えます。単一のエントリを追加または削除することはできません。

`Content-Type: application/json`ヘッダーとともに、`rules`と`actions`をJSONとして送信します。フォームエンコードされたボディは両方の配列を運ぶことができますが、一方のすべての値は文字列として到着するため、文字列ではない`value`はそのように表現することはできません。

### レスポンス属性 {#response-attributes}

ポリシーエンドポイントは次の属性を返します:

| 属性         | タイプ            | 説明 |
| ----------------- | --------------- | ----------- |
| `actions`         | 配列           | ポリシーが実行するアクション。 |
| `created_at`      | 文字列          | ポリシーが作成された日付と時刻。 |
| `description`     | 文字列          | ポリシーの説明。 |
| `id`              | 整数         | ポリシーのID。 |
| `lifecycle_state` | 文字列          | `active`または`disabled`のいずれか。 |
| `mode`            | 文字列          | `audit`、`warn`、`enforce`のいずれかです。 |
| `name`            | 文字列          | ポリシーの名前。 |
| `namespace_id`    | 整数         | ポリシーをオーナーとするグループのID。現在、常に`null`となります。これは、エンドポイントが`namespace_id`属性を受け入れないため、このAPIを通じて作成されたすべてのポリシーはそれぞれの組織がオーナーとなるためです。 |
| `organization_id` | 整数         | ポリシーが属する組織のID。 |
| `policy_rego`     | 文字列          | ポリシーのルールで、単一のRegoモジュールにコンパイルされます。ルールがないポリシーの場合は`null`。 |
| `policy_scope`    | オブジェクト          | ポリシーの構造化されたスコープ。Regoが直接作成された場合は`null`。 |
| `rules`           | 配列           | ポリシーのルール。 |
| `scope_dimensions`| 配列           | ポリシーが適用されるかどうかを判断するために`scope_rego`が読み取るドット区切りのコンテキストパス。GitLabはこの値を導出するため、送信する値は無視されます。`scope_rego`が直接作成された場合は`null`、それ以外の場合は配列、ポリシーがスコープ外の場合は空。 |
| `scope_rego`      | 文字列          | Regoとしてコンパイルされたポリシーのスコープ。 |
| `trigger_type`    | 文字列          | ポリシーが応答するトリガー。 |
| `updated_at`      | 文字列          | ポリシーが最後に変更された日付と時刻。 |
| `version`         | 整数         | ポリシーのリビジョン。少なくとも1つの値を変更する更新は、それを1つ増やします。 |

### すべてのポリシーを一覧表示 {#list-all-policies}

組織に属するすべてのポリシーを一覧表示します。

```plaintext
GET /organizations/:id/security/policy_store
```

サポートされている属性は以下のとおりです: 

| 属性      | タイプ    | 必須 | 説明 |
| -------------- | ------- | -------- | ----------- |
| `id`           | 整数 | はい      | 組織のID。 |
| `page`         | 整数 | いいえ       | 返す結果のページ。`1`がデフォルトです。 |
| `per_page`     | 整数 | いいえ       | ページあたりの結果数。デフォルトは`20`で、`100`を超える値はすべて`100`に制限されます。 |
| `trigger_type` | 文字列  | いいえ       | このトリガーに応答するポリシーのみを返します。[すべてのトリガーを一覧表示](#list-all-triggers)によって返されるIDのいずれか。 |

このエンドポイントは[ページ分けされた](rest/_index.md#offset-based-pagination)結果を返します。パフォーマンス上の理由により、組織が持つポリシーの数に関係なく、`x-total`または`x-total-pages`ヘッダー、あるいは`rel="last"` `link`は返されません。次のページがあるかどうかは`x-next-page`を確認してください。

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と[ポリシー属性](#response-attributes)の配列を返します。

リクエスト例: 

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/organizations/1/security/policy_store?per_page=20"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "organization_id": 1,
    "namespace_id": null,
    "name": "Block deployments on critical findings",
    "description": null,
    "version": 1,
    "trigger_type": "deployment_requested",
    "rules": [{ "type": "custom", "value": "package governance" }],
    "policy_rego": "package governance\n",
    "actions": [{ "type": "block" }],
    "policy_scope": null,
    "scope_dimensions": [],
    "scope_rego": "package gitlab.scope\n\napplicable := [result.policy | some result in results; result.applies]\n...",
    "mode": "enforce",
    "lifecycle_state": "active",
    "created_at": "2026-08-07T13:56:32.985Z",
    "updated_at": "2026-08-07T13:56:32.985Z"
  }
]
```

### ポリシーの取得 {#retrieve-a-policy}

組織から単一のポリシーを取得します。

```plaintext
GET /organizations/:id/security/policy_store/:policy_id
```

サポートされている属性は以下のとおりです: 

| 属性   | タイプ    | 必須 | 説明 |
| ----------- | ------- | -------- | ----------- |
| `id`        | 整数 | はい      | 組織のID。 |
| `policy_id` | 整数 | はい      | ポリシーのID。 |

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と[ポリシー属性](#response-attributes)を返します。

リクエスト例: 

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/organizations/1/security/policy_store/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "organization_id": 1,
  "namespace_id": null,
  "name": "Block deployments on critical findings",
  "description": null,
  "version": 1,
  "trigger_type": "deployment_requested",
  "rules": [{ "type": "custom", "value": "package governance" }],
  "policy_rego": "package governance\n",
  "actions": [{ "type": "block" }],
  "policy_scope": null,
  "scope_dimensions": [],
  "scope_rego": "package gitlab.scope\n\napplicable := [result.policy | some result in results; result.applies]\n...",
  "mode": "enforce",
  "lifecycle_state": "active",
  "created_at": "2026-08-07T13:56:32.985Z",
  "updated_at": "2026-08-07T13:56:32.985Z"
}
```

### ポリシーの作成 {#create-a-policy}

組織にポリシーを作成します。

```plaintext
POST /organizations/:id/security/policy_store
```

サポートされている属性は以下のとおりです: 

| 属性         | タイプ    | 必須 | 説明 |
| ----------------- | ------- | -------- | ----------- |
| `id`              | 整数 | はい      | 組織のID。 |
| `name`            | 文字列  | はい      | ポリシーの名前。最大255文字。組織内で一意である必要があります。 |
| `rules`           | 配列   | はい      | ポリシーのルール。少なくとも1つのエントリが必要で、最大5つまで。各エントリは最大4096バイトにシリアル化される必要があります。エントリが65536バイトを超えるRegoモジュールにコンパイルされると拒否されます。そのモジュールは`policy_rego`として返されます。 |
| `trigger_type`    | 文字列  | はい      | ポリシーが応答するトリガー。[すべてのトリガーを一覧表示](#list-all-triggers)によって返されるIDのいずれか。 |
| `actions`         | 配列   | いいえ       | ポリシーが実行するアクション。最大5つのエントリ。各エントリは最大4096バイトにシリアル化される必要があります。 |
| `description`     | 文字列  | いいえ       | ポリシーの説明。最大4096文字。 |
| `lifecycle_state` | 文字列  | いいえ       | `active`または`disabled`のいずれか。`active`がデフォルトです。 |
| `mode`            | 文字列  | いいえ       | `audit`、`warn`、`enforce`のいずれかです。`enforce`がデフォルトです。 |
| `policy_scope`    | オブジェクト  | いいえ       | ポリシーの構造化されたスコープ。空でない`scope_rego`と組み合わせることはできません。Regoの4096文字を超えてコンパイルされると拒否されます。 |
| `scope_rego`      | 文字列  | いいえ       | Regoとして作成されたポリシーのスコープ。最大4096文字。空でない値を`policy_scope`と組み合わせることはできません。 |

成功した場合、[`201`](rest/troubleshooting.md#status-codes)と[ポリシー属性](#response-attributes)を返します。次の条件で`400 Bad Request`が返されます:

- 属性が無効です。
- 両方のスコープ形式が指定されています。
- その名前はすでに組織内で使用されています。
- コンパイルされた`scope_rego`が4096文字を超えています。
- `rules`が65536バイトを超えるRegoにコンパイルされます。
- `rules`または`actions`が5つ以上のエントリを保持しています。
- `rules`または`actions`のエントリが4096バイトを超えてシリアル化されます。

リクエスト例: 

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "Block deployments on critical findings",
    "trigger_type": "deployment_requested",
    "rules": [{ "type": "custom", "value": "package governance" }],
    "actions": [{ "type": "block" }],
    "policy_scope": { "compliance_frameworks": [{ "id": 5 }] }
  }' \
  --url "https://gitlab.example.com/api/v4/organizations/1/security/policy_store"
```

レスポンス例: 

```json
{
  "id": 1,
  "organization_id": 1,
  "namespace_id": null,
  "name": "Block deployments on critical findings",
  "description": null,
  "version": 1,
  "trigger_type": "deployment_requested",
  "rules": [{ "type": "custom", "value": "package governance" }],
  "policy_rego": "package governance\n",
  "actions": [{ "type": "block" }],
  "policy_scope": { "compliance_frameworks": [{ "id": 5 }] },
  "scope_dimensions": ["compliance_frameworks"],
  "scope_rego": "package gitlab.scope\n\napplicable := [result.policy | some result in results; result.applies]\n...",
  "mode": "enforce",
  "lifecycle_state": "active",
  "created_at": "2026-08-07T13:56:32.985Z",
  "updated_at": "2026-08-07T13:56:32.985Z"
}
```

### ポリシーの更新 {#update-a-policy}

組織内のポリシーを更新します。パスパラメータ以外のすべての属性はオプションですが、リクエストは少なくとも1つ指定する必要があります。送信されなかった属性はそのまま残り、少なくとも1つの値を変更する更新は`version`を1つ増やします。保存されている値を再指定するリクエストは何も変更せず、`version`はそのまま残ります。

```plaintext
PATCH /organizations/:id/security/policy_store/:policy_id
```

サポートされている属性は以下のとおりです: 

| 属性         | タイプ    | 必須 | 説明 |
| ----------------- | ------- | -------- | ----------- |
| `id`              | 整数 | はい      | 組織のID。 |
| `policy_id`       | 整数 | はい      | ポリシーのID。 |
| `actions`         | 配列   | いいえ       | ポリシーが実行するアクション。保存されているアクションを置き換え、最大5つのエントリ。各エントリは最大4096バイトにシリアル化される必要があります。 |
| `description`     | 文字列  | いいえ       | ポリシーの説明。最大4096文字。 |
| `lifecycle_state` | 文字列  | いいえ       | `active`または`disabled`のいずれか。 |
| `mode`            | 文字列  | いいえ       | `audit`、`warn`、`enforce`のいずれかです。 |
| `name`            | 文字列  | いいえ       | ポリシーの名前。最大255文字。組織内で一意である必要があります。 |
| `policy_scope`    | オブジェクト  | いいえ       | ポリシーの構造化されたスコープ。空でない`scope_rego`と組み合わせることはできません。Regoの4096文字を超えてコンパイルされると拒否されます。 |
| `rules`           | 配列   | いいえ       | ポリシーのルール。保存されているルールを置き換え、最大5つのエントリ。各エントリは最大4096バイトにシリアル化される必要があります。エントリが65536バイトを超えるRegoモジュールにコンパイルされると拒否されます。そのモジュールは`policy_rego`として返されます。 |
| `scope_rego`      | 文字列  | いいえ       | Regoとして作成されたポリシーのスコープ。最大4096文字。作成されたプログラムを廃止し、`policy_scope`から再コンパイルするには、空の値を送信します。 |
| `trigger_type`    | 文字列  | いいえ       | ポリシーが応答するトリガー。[すべてのトリガーを一覧表示](#list-all-triggers)によって返されるIDのいずれか。 |

ポリシーの名前を変更すると、ポリシー名が生成されたプログラムに表示されるため、GitLabは生成された`scope_rego`を再コンパイルする必要があります。直接作成された`scope_rego`はそのまま残されます。

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と[ポリシー属性](#response-attributes)を返します。次の条件で`400 Bad Request`が返されます:

- 変更する属性が指定されていません。
- 属性が無効です。
- 両方のスコープ形式が指定されています。
- 新しい名前はすでに組織内で使用されています。
- 再コンパイルされた`scope_rego`が4096文字を超えています。
- 置き換えられる`rules`が65536バイトを超えるRegoにコンパイルされます。
- 置き換えられる`rules`または`actions`が5つ以上のエントリを保持しています。
- 置き換えられる`rules`または`actions`のエントリが4096バイトを超えてシリアル化されます。

リクエスト例: 

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
  --data-urlencode "name=Renamed policy" \
  --url "https://gitlab.example.com/api/v4/organizations/1/security/policy_store/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "organization_id": 1,
  "namespace_id": null,
  "name": "Renamed policy",
  "description": null,
  "version": 2,
  "trigger_type": "deployment_requested",
  "rules": [{ "type": "custom", "value": "package governance" }],
  "policy_rego": "package governance\n",
  "actions": [{ "type": "block" }],
  "policy_scope": null,
  "scope_dimensions": [],
  "scope_rego": "package gitlab.scope\n\napplicable := [result.policy | some result in results; result.applies]\n...",
  "mode": "enforce",
  "lifecycle_state": "active",
  "created_at": "2026-08-07T13:56:32.985Z",
  "updated_at": "2026-08-07T14:02:47.198Z"
}
```

### ポリシーの削除 {#delete-a-policy}

組織からポリシーを削除します。

```plaintext
DELETE /organizations/:id/security/policy_store/:policy_id
```

サポートされている属性は以下のとおりです: 

| 属性   | タイプ    | 必須 | 説明 |
| ----------- | ------- | -------- | ----------- |
| `id`        | 整数 | はい      | 組織のID。 |
| `policy_id` | 整数 | はい      | ポリシーのID。 |

成功した場合、[`204`](rest/troubleshooting.md#status-codes)と空のレスポンスボディを返します。

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/organizations/1/security/policy_store/1"
```
