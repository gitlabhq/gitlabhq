---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Webhook
description: "GitLabでプロジェクトとグループのWebhookを設定および管理します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Webhookは、リアルタイム通知によってGitLabを他のツールやシステムに接続します。GitLabで重要なイベントが発生すると、Webhookはその情報を外部アプリケーションに直接送信します。マージリクエスト、コードプッシュ、イシューの更新に反応して自動化ワークフローをビルドします。

Webhookを使用すると、変更発生時にチームが連携の取れた状態を維持できます:

- GitLabイシューが変更されると、外部イシュートラッカーが自動的に更新されます。
- チャットアプリケーションが、パイプラインの完了をチームメンバーに通知します。
- コードがmainブランチに到達すると、カスタムスクリプトがアプリケーションをデプロイします。
- モニタリングシステムが、組織全体での開発アクティビティーを追跡します。

## Webhookイベント {#webhook-events}

Webhookは、GitLabのさまざまなイベントによってトリガーできます。次に例を示します:

- リポジトリへのコードプッシュ。
- イシューへのコメントの投稿。
- マージリクエストの作成。

## Webhookの制限 {#webhook-limits}

Webhookの制限には、以下が含まれます: GitLab.com:

- プロジェクトまたはグループごとのWebhookの最大数。
- 1分あたりのWebhook呼び出し数。
- Webhookのタイムアウト期間。

GitLab Self-Managedでは、管理者がこれらの制限を変更できます。

### プッシュイベントの制限 {#push-event-limits}

GitLabは、複数の変更を含むプッシュイベントのWebhookトリガーを制限します:

- デフォルトの制限: プッシュごとに3つのブランチまたはタグ。
- 超過した場合の動作: プッシュイベント全体でWebhookはトリガーされません。
- 適用対象: プロジェクトWebhookとシステムフックの両方。
- 設定: GitLabセルフマネージドの管理者は、アプリケーション設定APIを使用して、`push_event_hooks_limit`設定を変更できます。

複数のタグまたはブランチを頻繁に同時にプッシュし、Webhook通知が必要な場合は、GitLab管理者に連絡してこの制限を引き上げてください。

## グループWebhook {#group-webhooks}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

グループWebhookは、グループとそのサブグループ内のすべてのプロジェクトのイベントに関する通知を送信するカスタムHTTPコールバックです。

### グループWebhookイベントの種類 {#types-of-group-webhook-events}

次のイベントをリッスンするようにグループWebhookを設定できます:

- グループとサブグループ内のプロジェクトで発生するすべてのトリガーイベント。
- グループメンバーイベント、プロジェクトイベント、サブグループイベントなど、グループ固有のイベント

### プロジェクトとグループの両方のWebhook {#webhooks-in-both-a-project-and-a-group}

グループとそのグループ内のプロジェクトの両方で同一のWebhookを設定すると、そのプロジェクト内のイベントに対して両方のWebhookがトリガーされます。これにより、GitLab組織のさまざまなレベルで柔軟なイベント処理が可能になります。

## Webhookを設定する {#configure-webhooks}

GitLabでWebhookを作成、設定して、プロジェクトのワークフローと統合します。これらの機能を使用して、特定の要件を満たすWebhookを設定します。

### Webhookを作成する {#create-a-webhook}

{{< history >}}

- GitLab 16.9で**名前**と**説明**が[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141977)。

{{< /history >}}

プロジェクトまたはグループ内のイベントに関する通知を送信するWebhookを作成します。

前提要件: 

- プロジェクトWebhookの場合、プロジェクトのメンテナー以上のロールを持っている必要があります。
- グループWebhookの場合、グループのオーナーロールを持っている必要があります。

Webhookを作成するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **Webhooks**を選択します。
1. **新しいWebhookを追加**を選択します。
1. **URL**に、WebhookエンドポイントのURLを入力します。特殊文字にはパーセントエンコードを使用します。
1. オプション。Webhookの**名前**と**説明**を入力します。
1. オプション。**シークレットトークン**に、リクエストを検証するためのトークンを入力します。
1. **トリガー**セクションで、Webhookをトリガーするイベントを選択します。
1. オプション。**SSLの検証を有効にする**の検証を無効にするには、SSLの検証を有効にするチェックボックスをオフにします。
1. **Webhookを追加**を選択します。

シークレットトークンは、`X-Gitlab-Token` HTTPヘッダーのWebhookリクエストとともに送信されます。Webhookエンドポイントは、このトークンを使用してリクエストの正当性を検証できます。

### Webhook URLの機密部分をマスクする {#mask-sensitive-portions-of-webhook-urls}

セキュリティを強化するため、Webhook URLの機密部分をマスクします。マスクされた部分は、Webhookの実行時に設定された値に置き換えられ、ログに記録されず、データベースでの保存時には暗号化されます。

Webhook URLの機密部分をマスクするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **Webhooks**を選択します。
1. **URL**に、Webhookの完全なURLを入力します。
1. マスクする部分を定義するには、**Add URL masking**（URLマスキングの追加）を選択します。
1. **URLの機密部分**に、マスクするURLの部分を入力します。
1. **UIの外観について**に、マスクされた部分の代わりに表示する値を入力します。変数名には、小文字（`a-z`）、数字（`0-9`）、アンダースコア（`_`）のみを使用する必要があります。
1. **変更を保存**を選択します。

マスクされた値はUIでは非表示になります。たとえば、変数`path`と`value`を定義した場合、Webhook URLは次のようになります:

```plaintext
https://webhook.example.com/{path}?key={value}
```

### カスタムヘッダー {#custom-headers}

{{< history >}}

- GitLab 16.11で`custom_webhook_headers`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146702)されました。デフォルトでは有効になっています。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/448604)になりました。機能フラグ`custom_webhook_headers`は削除されました。

{{< /history >}}

外部サービスへの認証のために、カスタムヘッダーをWebhookリクエストに追加します。Webhookごとに最大20個のカスタムヘッダーを設定できます。

カスタムヘッダーは以下の条件を満たしている必要があります:

- ヘッダーの値をオーバーライドしません。
- 英数字、ピリオド、ダッシュ、アンダースコアのみが含まれている。
- 文字で始まり、文字または数字で終わる。
- 連続したピリオド、ダッシュ、またはアンダースコアがない。

カスタムヘッダーは、値がマスクされた状態で**最近のイベント**に表示されます。

### カスタムWebhookテンプレート {#custom-webhook-template}

{{< history >}}

- GitLab 16.10で`custom_webhook_template`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142738)されました。デフォルトでは有効になっています。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/439610)になりました。機能フラグ`custom_webhook_template`は削除されました。
- 挿入されたフィールド値のJSONシリアライズは、`custom_webhook_template_serialization`という[フラグ](../../../administration/feature_flags/_index.md)を使用してGitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197992)されました。デフォルトでは無効になっています。

{{< /history >}}

リクエスト本文で送信されるデータを制御するWebhookのカスタムペイロードテンプレートを作成します。

#### カスタムWebhookテンプレートを作成する {#create-a-custom-webhook-template}

- プロジェクトWebhookの場合、プロジェクトのメンテナー以上のロールを持っている必要があります。
- グループWebhookの場合、グループのオーナーロールを持っている必要があります。

カスタムWebhookテンプレートを作成するには、次の手順に従います:

1. Webhookの設定に移動します。
1. カスタムWebhookテンプレートを設定します。
1. テンプレートが有効なJSONとしてレンダリングされることを確認します。

テンプレートで、トリガーイベントのペイロードのフィールドを使用します。次に例を示します:

- `{{build_name}}`（ジョブイベント）
- `{{deployable_url}}`（デプロイイベント）

ネストされたプロパティにアクセスするには、ピリオドを使用してパスセグメントを区切ります。

#### カスタムWebhookテンプレートの例 {#example-custom-webhook-template}

次のカスタムペイロードテンプレートの場合:

```json
{
  "event": "{{object_kind}}",
  "project_name": "{{project.name}}"
}
```

その結果作成される`push`イベントのリクエストペイロードは次のようになります:

```json
{
  "event": "push",
  "project_name": "Example"
}
```

カスタムWebhookテンプレートは、配列内のプロパティにアクセスできません。この機能のサポートは、[イシュー463332](https://gitlab.com/gitlab-org/gitlab/-/issues/463332)で提案されています。

### ブランチでプッシュイベントをフィルタリングする {#filter-push-events-by-branch}

Webhookエンドポイントに送信される`push`イベントをブランチ名でフィルタリングします。次のいずれかのフィルタリングオプションを使用します:

- **すべてのブランチ**: すべてのブランチからプッシュイベントを受信します。
- **ワイルドカードパターン**: ワイルドカードパターンに一致するブランチからプッシュイベントを受信します。
- **正規表現**: 正規表現（regex）に一致するブランチからプッシュイベントを受信します。

#### ワイルドカードパターンを使用する {#use-a-wildcard-pattern}

ワイルドカードパターンを使用してフィルタリングするには、次の手順に従います:

1. Webhook設定で**ワイルドカードパターン**を選択します。
1. パターンを入力します。次に例を示します:
   - `*-stable`は、`-stable`で終わるブランチに一致します。
   - `production/*`は、`production/`ネームスペース内のブランチに一致します。

#### 正規表現を使用する {#use-a-regular-expression}

正規表現を使用してフィルタリングするには、次の手順に従います:

1. Webhook設定で**正規表現**を選択します。
1. [RE2構文](https://github.com/google/re2/wiki/Syntax)に従っている正規表現パターンを入力します。

たとえば、`main`ブランチを除外するには、次を使用します:

```plaintext
\b(?:m(?!ain\b)|ma(?!in\b)|mai(?!n\b)|[a-l]|[n-z])\w*|\b\w{1,3}\b|\W+
```

### 相互TLSをサポートするようにWebhookを設定する {#configure-webhooks-to-support-mutual-tls}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/27450)されました。

{{< /history >}}

PEM形式のグローバルクライアント証明書を設定して、相互TLSをサポートするようにWebhookを設定します。

前提要件: 

- GitLab管理者である必要があります。

Webhookの相互TLSを設定するには、次の手順に従います:

1. PEM形式のクライアント証明書を準備します。
1. オプション。PEMパスフレーズで証明書を保護します。
1. 証明書を使用するようにGitLabを設定します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitlab_rails['http_client']['tls_client_cert_file'] = '<PATH TO CLIENT PEM FILE>'
   gitlab_rails['http_client']['tls_client_cert_password'] = '<OPTIONAL PASSWORD>'
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します: 

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
            gitlab_rails['http_client']['tls_client_cert_file'] = '<PATH TO CLIENT PEM FILE>'
            gitlab_rails['http_client']['tls_client_cert_password'] = '<OPTIONAL PASSWORD>'
   ```

1. ファイルを保存して、GitLabを再起動します: 

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します: 

   ```yaml
   production: &base
     http_client:
       tls_client_cert_file: '<PATH TO CLIENT PEM FILE>'
       tls_client_cert_password: '<OPTIONAL PASSWORD>'
   ```

1. ファイルを保存して、GitLabを再起動します: 

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

設定が完了したら、GitLabはWebhook接続のTLSハンドシェイク中にこの証明書をサーバーに提示します。

### Webhookトラフィックのファイアウォールを設定する {#configure-firewalls-for-webhook-traffic}

GitLabがWebhookを送信する方法に基づいて、Webhookトラフィックのファイアウォールを設定します:

- Sidekiqノードから非同期的に送信（最も一般的）
- Railsノードから同期的に送信（特定のケース）

Webhookは、UIでWebhookをテストまたは再試行すると、Railsノードから同期的に送信されます。

ファイアウォールを設定するときには、SidekiqノードとRailsノードの両方がWebhookトラフィックを送信できることを確認してください。

## Webhookを管理する {#manage-webhooks}

GitLabで設定済みWebhookをモニタリングおよび保守します。

### Webhookリクエストの履歴を表示する {#view-webhook-request-history}

Webhookリクエストの履歴を表示して、パフォーマンスをモニタリングし、問題のトラブルシューティングを行います。

前提要件: 

- プロジェクトWebhookの場合、プロジェクトのメンテナー以上のロールを持っている必要があります。
- グループWebhookの場合、グループのオーナーロールを持っている必要があります。

Webhookのリクエスト履歴を表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **Webhooks**を選択します。
1. Webhookの**編集**を選択します。
1. **最近のイベント**セクションに移動します。

**最近のイベント**セクションには、過去2日間にWebhookに対して行われたすべてのリクエストが表示されます。テーブルには以下の内容が示されます:

- HTTPステータスコード:
  - コード`200`～`299`の場合は緑
  - その他のコードの場合は赤
  - 配信に失敗した場合は`internal error`
- トリガーされたイベント
- リクエストの経過時間
- リクエストが行われた時点の相対時間

![ステータスコードと応答時間を示すWebhookイベントログ](img/webhook_logs_v14_4.png)

#### リクエストと応答の詳細を調べる {#inspect-request-and-response-details}

前提要件: 

- プロジェクトWebhookの場合、プロジェクトのメンテナー以上のロールを持っている必要があります。
- グループWebhookの場合、グループのオーナーロールを持っている必要があります。

**最近のイベント**の各Webhookリクエストには、**リクエストの詳細**ページがあります。このページには、次の本文とヘッダーが含まれています:

- GitLabがWebhookレシーバーエンドポイントから受信した応答
- GitLabが送信したWebhookリクエスト

Webhookイベントのリクエストと応答の詳細を調べるには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **Webhooks**を選択します。
1. Webhookの**編集**を選択します。
1. **最近のイベント**セクションに移動します。
1. イベントの**詳細を表示**を選択します。

同じデータと同一の`Idempotency-Key`ヘッダーを使用してリクエストを再送信するには、**リクエストを再送する**を選択します。Webhook URLが変更された場合、リクエストを再送信できません。プロジェクトWebhook APIを介して、プログラムでリクエストを再送信することもできます。

### Webhookをテストする {#test-a-webhook}

Webhookが正しく動作していることを確認するか、無効になっているWebhookを再度有効にするには、テストを実行します。

前提要件: 

- プロジェクトWebhookの場合、プロジェクトのメンテナー以上のロールを持っている必要があります。
- グループWebhookの場合、グループのオーナーロールを持っている必要があります。
- `push events`をテストするには、プロジェクトに少なくとも1つのコミットが必要です。

Webhookをテストするには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **Webhooks**を選択すると、このプロジェクトのすべてのWebhookが表示されます。
1. 構成されたWebhookのリストから直接Webhookをテストするには:
   1. テストするWebhookを見つけます。
   1. **テスト**ドロップダウンリストから、テストするイベントの種類を選択します。
1. Webhookの編集中にWebhookをテストするには:
   1. テストするWebhookを見つけて、**編集**を選択します。
   1. Webhookに変更を加えます。
   1. **テスト**ドロップダウンリストから、テストするイベントの種類を選択します。

プロジェクトWebhookとグループWebhookの特定の種類のイベントでは、テストはサポートされていません。詳細については、[イシュー379201](https://gitlab.com/gitlab-org/gitlab/-/issues/379201)を参照してください。

## Webhookリファレンス {#webhook-reference}

このテクニカルリファレンスは、次の目的で使用します:

- GitLab Webhookの仕組みを理解する。
- システムとWebhookを統合する。
- Webhookの設定、トラブルシューティング、最適化を行う。

### Webhookレシーバーの要件 {#webhook-receiver-requirements}

信頼性の高いWebhook配信を確保するために、高速で安定したWebhookレシーバーエンドポイントを実装します。

低速、不安定、または不適切に設定されたWebhookレシーバーは、自動的に無効になることがあります。無効なHTTP応答は、失敗したリクエストとして扱われます。

Webhookレシーバーを最適化するには、次の手順に従います:

1. `200`または`201`のステータスで迅速に応答します:
   - 同じリクエストでWebhookを処理しないでください。
   - 受信後、キューを使用してWebhookを処理します。
   - GitLab.comでの自動無効化を防ぐため、タイムアウト制限より前に応答します。
1. 潜在的な重複イベントを処理します:
   - Webhookがタイムアウトする場合の重複イベントに備えます。
   - エンドポイントが常に高速かつ安定していることを確認します。
1. 応答ヘッダーと本文を最小限に抑える:
   - GitLabは、後で検査するためにリクエストのヘッダーと本文を保存します。
   - 返されるヘッダーの数とサイズを制限します。
   - 空の本文で応答することを検討してください。
1. 適切なステータスコードを使用します:
   - クライアントエラーステータス応答（`4xx`の範囲）は、誤った設定のWebhookに対してのみ返します。
   - サポートされていないイベントの場合は、`400`を返すか、ペイロードを無視します。
   - 処理されたイベントに対する`500`サーバーエラー応答を回避します。

### 自動的に無効化されたWebhook {#auto-disabled-webhooks}

{{< history >}}

- GitLab 15.10のグループWebhookで[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385902)されました。
- [GitLabセルフマネージドで無効にされた](https://gitlab.com/gitlab-org/gitlab/-/issues/390157)GitLab 15.10のプロジェクトWebhookの場合、`auto_disabling_web_hooks`という[フラグ](../../../administration/feature_flags/_index.md)を使用します。
- GitLab 17.11で、**Fails to connect**（接続に失敗しました）と**Failing to connect**（接続に失敗しています）が**無効**と**一時的に無効**に[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166329)。
- GitLab 17.11で、40回連続して失敗すると永久に無効になるように[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166329)。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLabは、4回連続して失敗したプロジェクトまたはグループのWebhookを自動的に無効にします。

自動的に無効になったWebhookを表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **Webhooks**を選択します。

Webhookリストでは、自動的に無効になったWebhookは次のように表示されます:

- Webhookは4回連続して失敗すると、**一時的に無効**になります。
- 40回連続して失敗した場合は**無効**

![無効および一時的に無効なステータスバッジを示すWebhookリスト。](img/failed_badges_v17_11.png)

#### 一時的に無効化されたWebhook {#temporarily-disabled-webhooks}

Webhookは4回連続して失敗すると、一時的に無効になります。Webhookが40回連続して失敗すると、完全に無効になります。

次の場合に失敗が発生します:

- Webhookレシーバーが`4xx`または`5xx`の範囲の応答リクエストを返した場合。
- WebhookがWebhookレシーバーへの接続を試行中に、タイムアウトが発生した場合。
- Webhookでその他のHTTPエラーが発生した場合。

一時的に無効化されたWebhookは、最初は1分間無効になります。この期間は、後続の失敗発生時に延長され、最大で24時間まで延長されます。この期間が経過すると、これらのWebhookは自動的に再度有効になります。

#### 永久に無効化されたWebhook {#permanently-disabled-webhooks}

Webhookは、40回連続して失敗すると永久に無効になります。一時的に無効になっているWebhookとは異なり、完全に無効になっているWebhookは自動的に再度有効にはなりません。

GitLab 17.10以前に永久に無効化されたWebhookに対してデータ移行が行われました。これらのWebhookは、UIが40件の失敗があると示している場合でも、**最近のイベント**に4件の失敗が表示されることがあります。

#### 無効化されたWebhookを再度有効にする {#re-enable-disabled-webhooks}

無効になっているWebhookを再度有効にするには、テストを送信します。テストリクエストが`2xx`の範囲の応答コードを返すと、Webhookが再度有効になります。

### 配信ヘッダー {#delivery-headers}

{{< history >}}

- GitLab 16.2で`X-Gitlab-Webhook-UUID`ヘッダーが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/230830)されました。
- GitLab 17.4で`Idempotency-Key`ヘッダーが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/388692)されました。

{{< /history >}}

GitLabは、エンドポイントへのWebhookリクエストに次のヘッダーを含めます:

| ヘッダー                  | 説明                                                                                                    | 例 |
| ----------------------- | -------------------------------------------------------------------------------------------------------------- | ------- |
| `User-Agent`            | `"Gitlab/<VERSION>"`形式のユーザーエージェント。                                                                 | `"GitLab/15.5.0-pre"` |
| `X-Gitlab-Instance`     | Webhookを送信したGitLabインスタンスのホスト名。                                                         | `"https://gitlab.com"` |
| `X-Gitlab-Webhook-UUID` | 各Webhookの一意のID。                                                                                    | `"02affd2d-2cba-4033-917d-ec22d5dc4b38"` |
| `X-Gitlab-Event`        | Webhookタイプ名。`"<EVENT> Hook"`形式のイベントタイプに対応します。                                  | `"Push Hook"` |
| `X-Gitlab-Event-UUID`   | 非再帰Webhookの一意のID。再帰Webhook（以前のWebhookによってトリガーされる）は同じ値を共有します。 | `"13792a34-cac6-4fda-95a8-c58e00a3954e"` |
| `Idempotency-Key`       | Webhookの再試行全体で一貫性のある一意のID。インテグレーションのべき等性を確保するために使用します。                        | `"f5e5f430-f57b-4e6e-9fac-d9128cd7232f"` |

### Webhook本文での画像URLの表示 {#image-url-display-in-webhook-body}

GitLabは、Webhook本文内の相対的な画像参照を絶対URLに書き換えます。

#### 画像URLの書き換えの例 {#image-url-rewriting-example}

マージリクエスト、コメント、またはWikiページ内の元の画像参照が次のようであるとします:

```markdown
![A Markdown image with a relative URL.](/uploads/$sha/image.png)
```

Webhook本文内で書き換えられた画像参照は次のようになります:

```markdown
![A Markdown image with an absolute URL.](https://gitlab.example.com/-/project/:id/uploads/<SHA>/image.png)
```

この例では、以下を前提としています:

- GitLabが`gitlab.example.com`にインストールされている。
- プロジェクトIDが`123`にある。

#### 画像URLの書き換えの例外 {#exceptions-to-image-url-rewriting}

次の場合、GitLabは画像URLを書き換えません:

- HTTP、HTTPS、またはプロトコル相対URLをすでに使用している場合。
- リンクラベルなど、高度なMarkdown機能を使用している場合。

## 関連トピック {#related-topics}

- [WebhookイベントとJSONペイロード](webhook_events.md)
- [Webhookの制限](../../gitlab_com/_index.md#webhooks)
- [プロジェクトWebhook API](../../../api/project_webhooks.md)
- [グループWebhook API](../../../api/group_webhooks.md)
- [システムフックAPI](../../../api/system_hooks.md)
- [Webhookのトラブルシューティング](webhooks_troubleshooting.md)
- [WebhookとTwilioでSMSアラートを送信する](https://www.datadoghq.com/blog/send-alerts-sms-customizable-webhooks-twilio/)
- [GitLabラベルを自動的に適用する](https://about.gitlab.com/blog/2016/08/19/applying-gitlab-labels-automatically/)
