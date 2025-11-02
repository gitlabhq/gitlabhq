---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Webhookを使用して外部ソースからアラートを受信し、アラートフィールドをマップし、テストアラートをトリガーし、PrometheusやOpsgenieなどのツールと統合します。
title: インテグレーション
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、Webhookレシーバーを介して、あらゆるソースからのアラートを受け入れることができます。[アラート通知](alerts.md)は、[オンコールのローテーションの](paging.md#paging)したり、[インシデントの作成](manage_incidents.md#from-an-alert)に使用したりできます。

## インテグレーションリスト {#integrations-list}

少なくともメンテナーロールがあれば、プロジェクトのサイドバーメニューの**設定** > **モニタリング**に移動し、**アラート**セクションを展開することで、設定されたアラートインテグレーションのリストを表示できます。リストには、インテグレーション名、タイプ、ステータス（有効または無効）が表示されます:

![設定されたアラートの詳細を示す表](img/integrations_list_v13_5.png)

## 設定 {#configuration}

GitLabは、設定したHTTPエンドポイントを介してアラートを受信できます。

### 単一のアラートエンドポイント {#single-alerting-endpoint}

GitLabプロジェクトでアラートエンドポイントを有効にすると、JSON形式でアラートペイロードを受信できるようになります。いつでも、好みに合わせて[ペイロードをカスタマイズ](#customize-the-alert-payload-outside-of-gitlab)できます。

1. メンテナーロールを持つユーザーとしてGitLabにサインインします。
1. プロジェクトで、**設定** > **モニタリング**に移動します。
1. **アラート**セクションを展開し、**インテグレーションタイプを選択する**ドロップダウンリストで、Prometheusからのアラートの場合は**Prometheus**を、その他のモニタリングツールの場合は**HTTPエンドポイント**を選択します。
1. **有効**アラート設定を切り替えます。Webhook設定のURLと認可キーは、インテグレーションを保存した後、**認証情報の表示**タブで確認できます。外部サービスでURLと認可キーも入力する必要があります。

### アラートエンドポイント {#alerting-endpoints}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[GitLab Premium](https://about.gitlab.com/pricing/)では、複数の固有なアラートエンドポイントを作成して、JSON形式であらゆる外部ソースからアラートを受信したり、[ペイロードをカスタマイズ](#customize-the-alert-payload-outside-of-gitlab)したりできます。

1. メンテナーロールを持つユーザーとしてGitLabにサインインします。
1. プロジェクトで、**設定** > **モニタリング**に移動します。
1. **アラート**セクションを展開します。
1. 作成するエンドポイントごとに:

   1. **新しいインテグレーションを追加**を選択します。
   1. **インテグレーションタイプを選択する**ドロップダウンリストで、Prometheusからのアラートの場合は**Prometheus**を、その他のモニタリングツールの場合は**HTTPエンドポイント**を選択します。詳細を参照
   1. インテグレーションに名前を付けます。
   1. **有効**アラート設定を切り替えます。Webhook設定の**URL**と**Authorization Key**（認可キー）は、インテグレーションを保存した後、**認証情報の表示**タブで確認できます。外部サービスでURLと認可キーも入力する必要があります。
   1. オプション。モニタリングツールのアラートのフィールドをGitLabフィールドにマップするには、サンプルペイロードを入力し、**Parse payload for custom mapping**（カスタムマッピングのペイロードを解析）を選択します。有効なJSONが必要です。サンプルペイロードを更新する場合は、フィールドも再マップする必要があります。Prometheusインテグレーションの場合、ペイロード全体の代わりに、ペイロードの`alerts`キーから単一のアラートを入力します。

   1. オプション。有効なサンプルペイロードを入力した場合は、**ペイロードアラートキー**の各値を選択して、[マップして**GitLabアラートキー**にします](#map-fields-in-custom-alerts)。
   1. インテグレーションを保存するには、**Save Integration**（インテグレーションの保存）を選択します。必要に応じて、インテグレーションを作成した後、インテグレーションの**テストアラートの送信**タブからテストアラートを送信できます。

新しいHTTPエンドポイントが[インテグレーションリスト](#integrations-list)に表示されます。インテグレーションを編集するには、{{< icon name="settings" >}}設定アイコンをインテグレーションリストの右側で選択します。

#### カスタムアラートのフィールドをマップする {#map-fields-in-custom-alerts}

モニタリングツールのアラート形式をGitLabアラートと統合できます。[アラートリスト](alerts.md#alert-list)と[アラート詳細ページ](alerts.md#alert-details-page)に正しい情報を表示するには、[HTTPエンドポイントを作成するときに、アラートのフィールドをGitLabフィールドにマップします。](#alerting-endpoints):

![アラート管理リスト](img/custom_alert_mapping_v13_11.png)

### Alertmanagerにインテグレーション認証情報を追加する（Prometheusインテグレーションのみ） {#add-integration-credentials-to-alertmanager-prometheus-integrations-only}

Prometheusアラート通知をGitLabに送信するには、[Prometheusのインテグレーション](#single-alerting-endpoint)からURLと認可キーをPrometheus Alertmanager設定の[`webhook_configs`](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config)セクションにコピーします:

```yaml
receivers:
  - name: gitlab
    webhook_configs:
      - http_config:
          authorization:
            type: Bearer
            credentials: 1234567890abdcdefg
        send_resolved: true
        url: http://IP_ADDRESS:PORT/root/manual_prometheus/prometheus/alerts/notify.json
        # Rest of configuration omitted
        # ...
```

## GitLabの外部でアラートペイロードをカスタマイズする {#customize-the-alert-payload-outside-of-gitlab}

### 予期されるHTTPリクエスト属性 {#expected-http-request-attributes}

[カスタムマッピング](#map-fields-in-custom-alerts)のないHTTPエンドポイントの場合、次のパラメータを送信してペイロードをカスタマイズできます。すべてのフィールドはオプションです。受信アラートに`Title`フィールドの値が含まれていない場合、`New: Alert`のデフォルト値が適用されます。

| プロパティ                  | 型            | 説明 |
| ------------------------- | --------------- | ----------- |
| `title`                   | 文字列          | アラートのタイトル。|
| `description`             | 文字列          | 問題の概要。 |
| `start_time`              | 日時        | アラートの時間。指定されていない場合、現在の時刻が使用されます。 |
| `end_time`                | 日時        | アラートの解決時間。指定されている場合、アラートは解決されます。 |
| `service`                 | 文字列          | 影響を受けるサービス。 |
| `monitoring_tool`         | 文字列          | 関連付けられているモニタリングツールの名前。 |
| `hosts`                   | 文字列または配列 | インシデントが発生した1つ以上のホスト。 |
| `severity`                | 文字列          | アラートの重大度。大文字と小文字を区別しません。次のいずれかです：`critical`、`high`、`medium`、`low`、`info`、`unknown`。値がない場合、またはこのリストにない場合は、`critical`がデフォルトになります。 |
| `fingerprint`             | 文字列または配列 | アラートの固有識別子。これを使うことにより、同じアラートの発生をまとめることができます。`generic_alert_fingerprinting`機能が有効になっている場合、フィンガープリントは（`start_time`、`end_time`、および`hosts`パラメータを除外して）ペイロードに基づいて自動的に生成されます。 |
| `gitlab_environment_name` | 文字列          | 関連付けられているGitLabの[環境](../../ci/environments/_index.md)の名前。[ダッシュボードにアラートを表示する](../../user/operations_dashboard/_index.md#adding-a-project-to-the-dashboard)ために必要です。 |

カスタムフィールドをアラートのペイロードに追加することもできます。追加のパラメータの値は、プリミティブ型（文字列や数値など）に限定されませんが、ネストされたJSONオブジェクトにすることができます。次に例を示します: 

```json
{ "foo": { "bar": { "baz": 42 } } }
```

{{< alert type="note" >}}

リクエストが[ペイロードアプリケーションの制限](../../administration/instance_limits.md#generic-alert-json-payloads)よりも小さくなっていることを確認してください。

{{< /alert >}}

#### リクエスト例 {#example-request-body}

サンプルペイロード:

```json
{
  "title": "Incident title",
  "description": "Short description of the incident",
  "start_time": "2019-09-12T06:00:55Z",
  "service": "service affected",
  "monitoring_tool": "value",
  "hosts": "value",
  "severity": "high",
  "fingerprint": "d19381d4e8ebca87b55cda6e8eee7385",
  "foo": {
    "bar": {
      "baz": 42
    }
  }
}
```

### 予想されるPrometheusリクエスト属性 {#expected-prometheus-request-attributes}

アラートは、Prometheus [Webhookレシーバー](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config)用にフォーマットされることが想定されています。

トップレベルの必須属性:

- `alerts`
- `commonAnnotations`
- `commonLabels`
- `externalURL`
- `groupKey`
- `groupLabels`
- `receiver`
- `status`
- `version`

Prometheusペイロードの`alerts`から、GitLabアラートは配列内の各項目に対して作成されます。以下に示すネストされたパラメータを変更して、GitLabアラートを設定できます。

| 属性                                                                  | 型     | 必須 | 説明                          |
| -------------------------------------------------------------------------- | -------- | -------- | ------------------------------------ |
| `annotations/title`、`annotations/summary`、`labels/alertname`のいずれか。   | 文字列   | はい      | アラートのタイトル。              |
| `startsAt`                                                                 | 日時 | はい      | アラートの開始時間。         |
| `annotations/description`                                                  | 文字列   | いいえ       | 問題の概要。 |
| `annotations/gitlab_incident_markdown`                                     | 文字列   | いいえ       | アラートから作成されたすべてのインシデントに追加される[GitLab Flavored Markdown](../../user/markdown.md)。 |
| `annotations/runbook`                                                      | 文字列   | いいえ       | このアラートを管理する方法については、ドキュメントまたは手順へのリンク。 |
| `endsAt`                                                                   | 日時 | いいえ       | アラートの解決時間。    |
| `g0.expr`の`generatorUrl`クエリパラメータ                                | 文字列   | いいえ       | 関連するメトリクスのクエリ。          |
| `labels/gitlab_environment_name`                                           | 文字列   | いいえ       | 関連付けられているGitLabの[環境](../../ci/environments/_index.md)の名前。[ダッシュボードにアラートを表示する](../../user/operations_dashboard/_index.md#adding-a-project-to-the-dashboard)ために必要です。 |
| `labels/severity`                                                          | 文字列   | いいえ       | アラートの重大度。[Prometheusの重大度オプション](#prometheus-severity-options)のいずれかである必要があります。値がない場合、またはこのリストにない場合は、`critical`がデフォルトになります。 |
| `status`                                                                   | 文字列   | いいえ       | Prometheusのアラートのステータス。値が「resolved」の場合、アラートは解決されます。 |
| `annotations/gitlab_y_label`、`annotations/title`、`annotations/summary`、`labels/alertname`のいずれか。 | 文字列 | いいえ | [GitLab Flavored Markdown](../../user/markdown.md)でこのアラートのメトリクスを埋め込むときに使用されるY軸ラベル。 |

`annotations`に含まれる追加の属性は、[アラートの詳細ページ](alerts.md#alert-details-page)で利用できます。その他の属性は無視されます。

属性は、プリミティブ型（文字列や数値など）に限定されませんが、ネストされたJSONオブジェクトにすることができます。次に例を示します: 

```json
{
    "target": {
        "user": {
            "id": 42
        }
    }
}
```

{{< alert type="note" >}}

リクエストが[ペイロードアプリケーションの制限](../../administration/instance_limits.md#generic-alert-json-payloads)よりも小さくなっていることを確認してください。

{{< /alert >}}

#### Prometheusの重大度オプション {#prometheus-severity-options}

Prometheusからのアラートは、[アラート重大度](alerts.md#alert-severity)に関して、大文字と小文字を区別しない次の値のいずれかを提供できます:

- **クリティカル**: `critical`、`s1`、`p1`、`emergency`、`fatal`
- **高**: `high`、`s2`、`p2`、`major`、`page`
- **中**: `medium`、`s3`、`p3`、`error`、`alert`
- **低**: `low`、`s4`、`p4`、`warn`、`warning`
- **情報**: `info`、`s5`、`p5`、`debug`、`information`、`notice`

値がない場合、またはこのリストにない場合、重大度は`critical`デフォルトになります。

#### Prometheusアラートの例 {#example-prometheus-alert}

アラートルールの例:

```yaml
groups:
- name: example
  rules:
  - alert: ServiceDown
    expr: up == 0
    for: 5m
    labels:
      severity: high
    annotations:
      title: "Example title"
      runbook: "http://example.com/my-alert-runbook"
      description: "Service has been down for more than 5 minutes."
      gitlab_y_label: "y-axis label"
      foo:
        bar:
          baz: 42
```

リクエストペイロードの例:

```json
{
  "version" : "4",
  "groupKey": null,
  "status": "firing",
  "receiver": "",
  "groupLabels": {},
  "commonLabels": {},
  "commonAnnotations": {},
  "externalURL": "",
  "alerts": [{
    "startsAt": "2022-010-30T11:22:40Z",
    "generatorURL": "http://host?g0.expr=up",
    "endsAt": null,
    "status": "firing",
    "labels": {
      "gitlab_environment_name": "production",
      "severity": "high"
    },
    "annotations": {
      "title": "Example title",
      "runbook": "http://example.com/my-alert-runbook",
      "description": "Service has been down for more than 5 minutes.",
      "gitlab_y_label": "y-axis label",
      "foo": {
        "bar": {
          "baz": 42
        }
      }
    }
  }]
}
```

{{< alert type="note" >}}

[テストアラートをトリガーする](#triggering-test-alerts)場合は、例に示すようにペイロード全体を入力します。[カスタムマッピングを設定する](#map-fields-in-custom-alerts)場合は、サンプルペイロードとして`alerts`配列から最初の項目のみを入力します。

{{< /alert >}}

## 認証 {#authorization}

次の認可方法が使用できます:

- ヘッダーにAuthZ（認可）を指定する。
- 基本認証

`<authorization_key>`と`<url>`の値は、アラートインテグレーションを設定するときに見つけることができます。

### Bearer AuthZ（認可） {#bearer-authorization-header}

認可キーは、ベアラートークンとして使用できます:

```shell
curl --request POST \
  --data '{"title": "Incident title"}' \
  --header "Authorization: Bearer <authorization_key>" \
  --header "Content-Type: application/json" \
  <url>
```

### 基本認証 {#basic-authentication}

認可キーは、`password`として使用できます。`username`は空白のままにします:

- ユーザー名: `<blank>`
- パスワード: `<authorization_key>`

```shell
curl --request POST \
  --data '{"title": "Incident title"}' \
  --header "Authorization: Basic <base_64_encoded_credentials>" \
  --header "Content-Type: application/json" \
  <url>
```

基本認証は、認証情報をURLで直接使用することもできます:

```shell
curl --request POST \
  --data '{"title": "Incident title"}' \
  --header "Content-Type: application/json" \
  <username:password@url>
```

{{< alert type="warning" >}}

URLで認可キーを使用すると、サーバーログに表示されるため、脆弱です。ツールでサポートされている場合は、前に説明したヘッダーオプションのいずれかを使用することをお勧めします。

{{< /alert >}}

## レスポンスボディ {#response-body}

JSONレスポンスビルドには、リクエスト内で作成されたすべてのアラートのリストが含まれています:

```json
[
  {
    "iid": 1,
    "title": "Incident title"
  },
  {
    "iid": 2,
    "title": "Second Incident title"
  }
]
```

成功したレスポンスは、`200`レスポンスコードを返します。

## テストアラートをトリガーする {#triggering-test-alerts}

[プロジェクトメンテナーまたはオーナー](../../user/permissions.md)がインテグレーションを設定した後、テストアラートをトリガーして、インテグレーションが正しく動作することを確認できます。

1. 少なくともデベロッパーロールを持つユーザーとしてサインインします。
1. プロジェクトで、**設定** > **モニタリング**に移動します。
1. **アラート**を選択して、セクションを展開します。
1. {{< icon name="settings" >}}設定アイコンを、[リスト](#integrations-list)のインテグレーションの右側で選択します。
1. **テストアラートの送信**タブを選択して開きます。
1. ペイロードフィールドにテストペイロードを入力します（有効なJSONが必要です）。
1. **送信**を選択します。

GitLabには、テストの結果に応じて、エラーまたは成功メッセージが表示されます。

## 同一アラートの自動グループ化 {#automatic-grouping-of-identical-alerts}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、アラートをペイロードに基づいてグループ化します。受信アラートに別のアラートと同じペイロードが含まれている場合（`start_time`と`hosts`の属性を除外）、GitLabはこれらのアラートをまとめてグループ化し、[アラート管理リスト](incidents.md)と詳細ページにカウンターを表示します。

既存のアラートがすでに`resolved`の場合、GitLabは代わりに新しいアラートを作成します。

![アラート管理リスト](img/alert_list_v13_1.png)

## リカバリーアラート {#recovery-alerts}

GitLabのアラートは、HTTPエンドポイントがアラートの終了時間が設定されたペイロードを受信すると、自動的に解決されます。[カスタムマッピング](#map-fields-in-custom-alerts)のないHTTPエンドポイントの場合、予期されるフィールドは`end_time`です。カスタムマッピングを使用すると、予期されるフィールドを選択できます。

GitLabは、ペイロードの一部として指定できる`fingerprint`の値に基づいて、解決するアラートを決定します。アラートのプロパティとマッピングの詳細については、[GitLabの外部でアラートペイロードをカスタマイズする](#customize-the-alert-payload-outside-of-gitlab)を参照してください。

アラートが解決されるときに、関連付けられた[インシデントを自動的にクローズする](manage_incidents.md#automatically-close-incidents-via-recovery-alerts)ように設定することもできます。

## Opsgenieアラートへのリンク {#link-to-your-opsgenie-alerts}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/groups/gitlab-org/-/epics/3066)GitLab 13.2でされました。

{{< /history >}}

{{< alert type="warning" >}}

[HTTPエンドポイントインテグレーション](#single-alerting-endpoint)を通じて、Opsgenieやその他のアラートツールとのより深い統合を構築しているので、GitLabインターフェースでアラートを確認できます。

{{< /alert >}}

[Opsgenie](https://www.atlassian.com/software/opsgenie)とのGitLabインテグレーションを使用して、アラートをモニタリングできます。

Opsgenieインテグレーションを有効にすると、他のGitLabアラートサービスを同時にアクティブにすることはできません。

Opsgenieインテグレーションを有効にするには:

1. 少なくともメンテナーロールを持つユーザーとしてサインインします。
1. **モニタリング** > **アラート**に移動します。
1. **インテグレーション**の選択ボックスで、**Opsgenie**（Opsgenie）を選択します。
1. **有効**切り替えを選択します。
1. **API URL**フィールドに、OpsgenieインテグレーションのベースURL（`https://app.opsgenie.com/alert/list`など）を入力します。
1. **変更を保存**を選択します。

インテグレーションを有効にした後、**アラート**ページ（**モニタリング** > **アラート**）に移動し、**View alerts in Opsgenie**（Opsgenieでアラートを表示）を選択します。
