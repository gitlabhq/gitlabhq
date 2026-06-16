---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Webhook
description: "プロジェクトとグループのWebhookをGitLabで設定および管理します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Webhookは、リアルタイム通知によってGitLabを他のツールやシステムに接続します。GitLabで重要なイベントが発生すると、Webhookはその情報を外部アプリケーションに直接送信します。マージリクエスト、コードプッシュ、イシューの更新に反応して自動化ワークフローをビルドします。

Webhookを使用すると、変更発生時にチームが連携の取れた状態を維持できます。

- GitLabイシューが変更されると、外部イシュートラッカーが自動的に更新されます。
- チャットアプリケーションが、パイプラインの完了をチームメンバーに通知します。
- コードがmainブランチに到達すると、カスタムスクリプトがアプリケーションをデプロイします。
- モニタリングシステムが、組織全体での開発アクティビティを追跡します。

## Webhookイベント {#webhook-events}

Webhookは、GitLabのさまざまなイベントによってトリガーできます。例: 

- リポジトリへのコードプッシュ。
- イシューへのコメントの投稿。
- マージリクエストの作成。

## Webhookの制限 {#webhook-limits}

GitLab.comは、次の[Webhookの制限](../../gitlab_com/_index.md#webhooks)を適用します。

- プロジェクトまたはグループごとのWebhookの最大数。
- 1分あたりのWebhook呼び出し数。
- Webhookのタイムアウト期間。

GitLab Self-Managedでは、管理者がこれらの制限を変更できます。

### プッシュイベントの制限 {#push-event-limits}

GitLabは、複数の変更を含むプッシュイベントに対するWebhookのトリガーを制限します:

- デフォルトの制限: プッシュごとに3つのブランチまたはタグ。
- 超過した場合の動作: プッシュイベント全体に対してWebhookはトリガーされません。
- 適用対象: プロジェクトWebhookとシステムフックの両方。
- 設定: GitLab Self-Managedの管理者は、アプリケーション設定APIを通じて`push_event_hooks_limit`設定を変更できます。

複数のタグやブランチを同時に頻繁にプッシュする必要があり、Webhook通知が必要な場合は、GitLabの管理者に連絡してこの制限を増やしてもらってください。

## グループWebhook {#group-webhooks}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

グループWebhookは、グループとそのサブグループ内のすべてのプロジェクトのイベントに関する通知を送信するカスタムHTTPコールバックです。

### グループWebhookイベントの種類 {#types-of-group-webhook-events}

次のイベントをリッスンするようにグループWebhookを設定できます。

- グループおよびサブグループ内のプロジェクトで発生するすべてのイベント
- グループメンバーイベント、プロジェクトイベント、サブグループイベントを含む、グループ固有のイベント

### プロジェクトとグループの両方のWebhook {#webhooks-in-both-a-project-and-a-group}

グループとそのグループ内のプロジェクトの両方で同一のWebhookを設定すると、そのプロジェクト内のイベントに対して両方のWebhookがトリガーされます。これにより、GitLab組織のさまざまなレベルで柔軟なイベント処理が可能になります。

## Webhookを設定する {#configure-webhooks}

GitLabでWebhookを作成、設定して、プロジェクトのワークフローと統合します。これらの機能を使用して、特定の要件を満たすWebhookを設定します。

### Webhookを作成する {#create-a-webhook}

{{< history >}}

- GitLab 16.9で**名前**と**説明**が[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141977)。
- **署名トークン**テキストボックスは、GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/19367)され、`webhook_signing_token`という名前の[フラグ](../../../administration/feature_flags/_index.md)が付けられました。デフォルトでは有効になっています。
- 機能フラグ`webhook_signing_token`は、GitLab 19.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/596374)されました。

{{< /history >}}

新しいWebhookには、シークレットトークンの代わりに署名トークンを使用します。署名トークンは、ペイロードのHMAC-SHA256署名を計算するため、お使いのエンドポイントはリクエストの真正性と整合性の両方を検証することができます。シークレットトークンは、ヘッダーにプレーンテキスト値を提供するだけであり、保証は弱くなります。新しいWebhookにはシークレットトークンの使用は推奨されません。

プロジェクトまたはグループ内のイベントに関する通知を送信するWebhookを作成します。

前提条件: 

- プロジェクトWebhookの場合、プロジェクトのメンテナーまたはオーナーロールが必要です。
- グループWebhookの場合、グループのオーナーロールを持っている必要があります。

Webhookを作成するには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**設定** > **Webhooks**を選択します。
1. **新しいWebhookを追加**を選択します。
1. **URL**に、WebhookエンドポイントのURLを入力します。特殊文字にはパーセントエンコードを使用します。
1. （オプション）Webhookの**名前**と**説明**を入力します。
1. （オプション）リクエスト認証を設定します。より強力なセキュリティのために署名トークンを使用します:
   - **署名トークン**: **署名トークンを生成**を選択します。トークンは一度しか表示されないため、今すぐコピーして保存してください。お使いのWebhookエンドポイントは、このトークンを使用して[HMAC-SHA256署名を検証](#verify-the-signature)できます。
   - **シークレットトークン**: **シークレットトークン**フィールドにトークンを入力します。このトークンは`X-Gitlab-Token` HTTPヘッダーでプレーンテキストとして送信され、署名トークンよりもセキュリティ保証が弱くなります。新しいWebhookには、代わりに署名トークンを使用します。
1. **トリガー**セクションで、Webhookをトリガーするイベントを選択します。
1. （オプション）SSL検証を無効にするには、**SSLの検証を有効にする**チェックボックスをオフにします。
1. **Webhookを追加**を選択します。

### 署名トークン {#signing-tokens}

{{< history >}}

- GitLab 19.0で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/19367)、`webhook_signing_token`という名前の[フラグで](../../../administration/feature_flags/_index.md)。デフォルトでは有効になっています。
- GitLab 19.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/596374)されました。機能フラグ`webhook_signing_token`は削除されました。

{{< /history >}}

署名トークンを使用して、WebhookのペイロードがGitLabから送信され、改ざんされていないことを検証することができます。シークレットトークンとは異なり、署名トークンはペイロードのHMAC-SHA256署名を計算するために使用されます。これは、受信者が受信したペイロードの真正性と整合性の両方を個別に検証することができることを意味します。

GitLabのWebhook配信は、[Standard Webhooks](https://www.standardwebhooks.com/)の仕様に従っています。すべてのWebhookリクエストには、`webhook-id`と`webhook-timestamp`のヘッダーが含まれます。署名トークンが設定されている場合、GitLabはHMAC-SHA256署名とともに`webhook-signature`ヘッダーも含まれます。各署名は`v1,{base64_signature}`の形式です。ヘッダーには、スペースで区切られた複数の署名が含まれる場合があります。GitLabは現在1つの署名を送信しますが、これは将来変更される可能性があります。署名は`{message_id}.{timestamp}.{body}`の文字列に基づいて計算されます。ここで:

- `{message_id}`は`webhook-id`ヘッダーの値です。
- `{timestamp}`は`webhook-timestamp`ヘッダーの値です。
- `{body}`はraw JSONリクエストボディです。

#### 署名を検証する {#verify-the-signature}

Webhookエンドポイントで署名を検証するには:

1. `webhook-id`、`webhook-timestamp`、および`webhook-signature`ヘッダーの値を取得する。
1. `webhook-signature`の値をスペースで分割して署名リストを取得します。
1. メッセージ文字列`"{message_id}.{timestamp}.{body}"`を構築します。
1. 署名トークンをデコードします: `whsec_`プレフィックスを削除し、残りをbase64デコードします。
1. デコードされたキーを使用してHMAC-SHA256ダイジェストを計算します。
1. ダイジェストをbase64としてエンコードし、`v1,`をプレフィックスとして付加します。
1. 計算された署名が署名リスト内のいずれかのエントリと一致するかどうかを確認します。タイミング攻撃を防ぐために定時間比較を使用します。

Rubyでの例:

```ruby
require 'base64'
require 'openssl'

def valid_signature?(signing_token, message_id, timestamp, body, received_signatures)
  raw_key = Base64.strict_decode64(signing_token.delete_prefix('whsec_'))
  message = "#{message_id}.#{timestamp}.#{body}"
  digest = OpenSSL::HMAC.digest('sha256', raw_key, message)
  expected = "v1,#{Base64.strict_encode64(digest)}"
  received_signatures.split(' ').any? do |sig|
    ActiveSupport::SecurityUtils.secure_compare(expected, sig)
  end
end
```

Pythonでの例:

```python
import base64
import hashlib
import hmac

def valid_signature(signing_token, message_id, timestamp, body, received_signatures):
    raw_key = base64.b64decode(signing_token.removeprefix('whsec_'))
    message = f"{message_id}.{timestamp}.{body}".encode('utf-8')
    digest = hmac.new(raw_key, message, hashlib.sha256).digest()
    expected = "v1," + base64.b64encode(digest).decode('utf-8')
    return any(
        hmac.compare_digest(expected, sig)
        for sig in received_signatures.split(' ')
    )
```

#### 下位互換性 {#backward-compatibility}

署名トークンは、既存のシークレットトークンと連携して機能します。両方を同じWebhookで設定できます:

- シークレットトークンが設定されている場合、`X-Gitlab-Token`ヘッダーは引き続き送信されます。
- 署名トークンが設定されている場合、`webhook-signature`および`webhook-id`ヘッダーが送信されます。

ダウンタイムなしで既存のWebhookをシークレットトークンから署名トークンに移行するには、移行中に両方のトークンを同じWebhookで設定します。Webhookレシーバーを更新して、`webhook-signature`が存在する場合は署名を検証するようにし、それ以外の場合はシークレットトークンにフォールバックするようにします。

Webhookレシーバーが署名を正しく処理するようになったら、Webhook設定からシークレットトークンを削除できます。

#### セキュリティに関する考慮事項 {#security-considerations}

リプレイ攻撃を防ぐために、`webhook-timestamp`のタイムスタンプが新しいことをペイロードの処理前に検証する。

署名トークンはAPIによって返されることはありません。

### Webhook URLの機密部分をマスクする {#mask-sensitive-portions-of-webhook-urls}

セキュリティを強化するため、Webhook URLの機密部分をマスクします。マスクされた部分は、Webhookの実行時に設定された値に置き換えられ、ログに記録されず、データベースでの保存時には暗号化されます。

Webhook URLの機密部分をマスクするには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**設定** > **Webhooks**を選択します。
1. **URL**に、Webhookの完全なURLを入力します。
1. マスクする部分を定義するには、**URLマスキングの追加**を選択します。
1. **URLの機密部分**に、マスクするURLの部分を入力します。
1. **UIの外観について**に、マスクされた部分の代わりに表示する値を入力します。変数名には、小文字（`a-z`）、数字（`0-9`）、アンダースコア（`_`）のみを使用する必要があります。
1. **変更を保存**を選択します。

マスクされた値はUIでは非表示になります。たとえば、変数`path`と`value`を定義した場合、Webhook URLは次のようになります。

```plaintext
https://webhook.example.com/{path}?key={value}
```

### カスタムヘッダー {#custom-headers}

{{< history >}}

- GitLab 16.11で`custom_webhook_headers`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146702)されました。デフォルトでは有効になっています。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/448604)になりました。機能フラグ`custom_webhook_headers`は削除されました。

{{< /history >}}

外部サービスへの認証のために、カスタムヘッダーをWebhookリクエストに追加します。Webhookごとに最大20個のカスタムヘッダーを設定できます。

カスタムヘッダーは以下の条件を満たしている必要があります。

- 配信ヘッダーの値を上書きしない。
- 英数字、ピリオド、ダッシュ、アンダースコアのみが含まれている。
- 文字で始まり、文字または数字で終わる。
- 連続したピリオド、ダッシュ、またはアンダースコアがない。

カスタムヘッダーは、マスクされた値とともに**最近のイベント**に表示されます。

### カスタムWebhookテンプレート {#custom-webhook-template}

{{< history >}}

- GitLab 16.10で`custom_webhook_template`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142738)されました。デフォルトでは有効になっています。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/439610)になりました。機能フラグ`custom_webhook_template`は削除されました。
- 補間されたフィールド値のJSONシリアライズは、GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197992)され、`custom_webhook_template_serialization`という名前の[フラグ](../../../administration/feature_flags/_index.md)が付けられました。デフォルトでは無効になっています。
- 補間されたフィールド値のJSONシリアライズは、GitLab 18.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212407)されました。機能フラグ`custom_webhook_template_serialization`はデフォルトで有効です。
- 機能フラグ`custom_webhook_template_serialization`は、GitLab 18.10で[削除](https://gitlab.com/gitlab-org/gitlab/-/work_items/580460)されました。

{{< /history >}}

リクエスト本文で送信されるデータを制御するWebhookのカスタムペイロードテンプレートを作成します。

#### カスタムWebhookテンプレートを作成する {#create-a-custom-webhook-template}

- プロジェクトWebhookの場合、プロジェクトのメンテナーまたはオーナーロールが必要です。
- グループWebhookの場合、グループのオーナーロールを持っている必要があります。

カスタムWebhookテンプレートを作成するには、次の手順に従います。

1. Webhookの設定に移動します。
1. カスタムWebhookテンプレートを設定します。
1. テンプレートが有効なJSONとしてレンダリングされることを確認します。

テンプレート内でイベントのペイロードからフィールドを使用します。例: 

- `{{build_name}}`（ジョブイベント）
- `{{deployable_url}}`（デプロイイベント）

ネストされたプロパティにアクセスするには、ピリオドを使用してパスセグメントを区切ります。

#### カスタムWebhookテンプレートの例 {#example-custom-webhook-template}

次のカスタムペイロードテンプレートの場合

```json
{
  "event": "{{object_kind}}",
  "project_name": "{{project.name}}"
}
```

その結果作成される`push`イベントのリクエストペイロードは次のようになります。

```json
{
  "event": "push",
  "project_name": "Example"
}
```

カスタムWebhookテンプレートは、配列内のプロパティにアクセスできません。

### ブランチでプッシュイベントをフィルタリングする {#filter-push-events-by-branch}

Webhookエンドポイントに送信される`push`イベントをブランチ名でフィルタリングします。次のいずれかのフィルタリングオプションを使用します。

- **全てのブランチ**: すべてのブランチからプッシュイベントを受信します。
- **ワイルドカードパターン**: ワイルドカードパターンに一致するブランチからプッシュイベントを受信します。
- **正規表現**: 正規表現（regex）に一致するブランチからプッシュイベントを受信します。

#### ワイルドカードパターンを使用する {#use-a-wildcard-pattern}

ワイルドカードパターンを使用してフィルタリングするには、次の手順に従います。

1. Webhook設定で**ワイルドカードパターン**を選択します。
1. パターンを入力します。例: 
   - `*-stable`は、`-stable`で終わるブランチに一致します。
   - `production/*`は、`production/`ネームスペース内のブランチに一致します。

#### 正規表現を使用する {#use-a-regular-expression}

正規表現を使用してフィルタリングするには、次の手順に従います。

1. Webhook設定で**正規表現**を選択します。
1. [RE2構文](https://github.com/google/re2/wiki/Syntax)に従っている正規表現パターンを入力します。

たとえば、`main`ブランチを除外するには、次を使用します。

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

前提条件: 

- GitLab管理者である必要があります。

Webhookの相互TLSを設定するには、次の手順に従います。

1. PEM形式のクライアント証明書を準備します。
1. （オプション）PEMパスフレーズで証明書を保護します。
1. 証明書を使用するようにGitLabを設定します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['http_client']['tls_client_cert_file'] = '<PATH TO CLIENT PEM FILE>'
   gitlab_rails['http_client']['tls_client_cert_password'] = '<OPTIONAL PASSWORD>'
   ```

1. ファイルを保存し、GitLabを再設定します:

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

1. ファイルを保存し、GitLabを再起動します: 

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

1. ファイルを保存し、GitLabを再起動します: 

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

GitLabがWebhookを送信する方法に基づいて、Webhookトラフィックのファイアウォールを設定します。

- Sidekiqノードから非同期的に送信（最も一般的）
- Railsノードから同期的に送信（特定のケース）

UIでWebhookをテストまたは再試行すると、WebhookはRailsノードから同期的に送信されます。

ファイアウォールを設定するときには、SidekiqノードとRailsノードの両方がWebhookトラフィックを送信できることを確認してください。

## Webhookを管理する {#manage-webhooks}

GitLabで設定済みWebhookをモニタリングおよび保守します。

### Webhookリクエストの履歴を表示する {#view-webhook-request-history}

Webhookリクエストの履歴を表示して、パフォーマンスをモニタリングし、問題のトラブルシューティングを行います。

前提条件: 

- プロジェクトWebhookの場合、プロジェクトのメンテナーまたはオーナーロールが必要です。
- グループWebhookの場合、グループのオーナーロールを持っている必要があります。

Webhookのリクエスト履歴を表示するには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**設定** > **Webhooks**を選択します。
1. Webhookの**編集**を選択します。
1. **最近のイベント**セクションに移動します。

**最近のイベント**セクションには、過去2日間にWebhookに対して行われたすべてのリクエストが表示されます。テーブルには以下の内容が示されます。

- HTTPステータスコード:
  - コード`200`～`299`の場合は緑
  - その他のコードの場合は赤
  - 配信に失敗した場合は`internal error`
- トリガーされたイベント
- リクエストの経過時間
- リクエストが行われた時点の相対時間

![Webhookイベントログ (ステータスコードと応答時間)](img/webhook_logs_v14_4.png)

#### リクエストと応答の詳細を調べる {#inspect-request-and-response-details}

前提条件: 

- プロジェクトWebhookの場合、プロジェクトのメンテナーまたはオーナーロールが必要です。
- グループWebhookの場合、グループのオーナーロールを持っている必要があります。

**最近のイベント**にある各Webhookリクエストには、**リクエストの詳細**ページがあります。このページには、次の本文とヘッダーが含まれています。

- GitLabがWebhookレシーバーエンドポイントから受信した応答
- GitLabが送信したWebhookリクエスト

Webhookイベントのリクエストと応答の詳細を調べるには、次のようにします。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**設定** > **Webhooks**を選択します。
1. Webhookの**編集**を選択します。
1. **最近のイベント**セクションに移動します。
1. イベントの**詳細を表示**を選択します。

同じデータと同じ`Idempotency-Key`ヘッダーでリクエストを再度送信するには、**リクエストを再送する**を選択します。Webhook URLが変更された場合、リクエストを再送信できません。プロジェクトWebhook APIを通じて、リクエストをプログラムで再送信することもできます。

### Webhookをテストする {#test-a-webhook}

Webhookが正しく機能していることを確認したり、無効になっているWebhookを再度有効にしたりするには、Webhookをテストします。

前提条件: 

- プロジェクトWebhookの場合、プロジェクトのメンテナーまたはオーナーロールが必要です。
- グループWebhookの場合、グループのオーナーロールを持っている必要があります。
- `push events`をテストするには、プロジェクトに少なくとも1つのコミットが必要です。

Webhookをテストするには、次のようにします。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**設定** > **Webhooks**を選択して、このプロジェクトのすべてのWebhookを表示します。
1. 設定済みWebhookのリストから直接Webhookをテストするには:
   1. テストするWebhookを見つけます。
   1. **テスト**ドロップダウンリストから、テストするイベントの種類を選択します。
1. Webhookを編集中にテストするには:
   1. テストするWebhookを見つけて、**編集**を選択します。
   1. Webhookに変更を加えます。
   1. **Test**ドロップダウンリストを選択し、テストするイベントのタイプを選択します。

プロジェクトWebhookとグループWebhookの特定の種類のイベントでは、テストはサポートされていません。詳細については、[イシュー379201](https://gitlab.com/gitlab-org/gitlab/-/issues/379201)を参照してください。

## Webhookリファレンス {#webhook-reference}

このテクニカルリファレンスは、次の目的で使用します。

- GitLab Webhookの仕組みを理解する。
- システムとWebhookを統合する。
- Webhookの設定、トラブルシューティング、最適化を行う。

### Webhookレシーバーの要件 {#webhook-receiver-requirements}

信頼性の高いWebhook配信を確保するために、高速で安定したWebhookレシーバーエンドポイントを実装します。

遅い、不安定な、または誤って設定されたWebhookレシーバーは自動的に無効になる可能性があります。無効なHTTP応答は、失敗したリクエストとして扱われます。

Webhookレシーバーを最適化するには、次の手順に従います。

1. `200`または`201`のステータスで迅速に応答します。
   - 同じリクエストでWebhookを処理しないでください。
   - 受信後、キューを使用してWebhookを処理します。
   - タイムアウト制限内に応答して、GitLab.comでの自動無効化を防ぎます。
1. 潜在的な重複イベントを処理します。
   - Webhookがタイムアウトする場合の重複イベントに備えます。
   - エンドポイントが常に高速かつ安定していることを確認します。
1. 応答ヘッダーと本文を最小限に抑える。
   - GitLabは、後で検査できるように応答ヘッダーとボディを保存します。
   - 返されるヘッダーの数とサイズを制限します。
   - 空の本文で応答することを検討してください。
1. 適切なステータスコードを使用します。
   - クライアントエラーステータス応答（`4xx`の範囲）は、誤った設定のWebhookに対してのみ返します。
   - サポートされていないイベントの場合は、`400`を返すか、ペイロードを無視します。
   - 処理されたイベントに対する`500`サーバーエラー応答を回避します。

### 自動的に無効化されたWebhook {#auto-disabled-webhooks}

{{< history >}}

- GitLab 15.10のグループWebhookで[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385902)されました。
- GitLab 15.10で、プロジェクトWebhookに対して[GitLab Self-Managedで無効化](https://gitlab.com/gitlab-org/gitlab/-/issues/390157)され、`auto_disabling_web_hooks`という名前の[フラグ](../../../administration/feature_flags/_index.md)が付けられました。
- GitLab 17.11で、**接続に失敗しました**と**接続に失敗しています**が**無効**と**一時的に無効**に[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166329)。
- GitLab 17.11で、40回連続して失敗すると永久に無効になるように[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166329)。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

GitLabは、4回連続して失敗したプロジェクトまたはグループのWebhookを自動的に無効にします。

自動的に無効になったWebhookを表示するには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**設定** > **Webhooks**を選択します。

Webhookリストでは、自動的に無効になったWebhookは次のように表示されます。

- 4回連続で失敗した場合、**一時的に無効**になります。
- 40回連続で失敗した場合、**無効**になります。

![無効および一時的に無効なステータスバッジを示すWebhookリスト。](img/failed_badges_v17_11.png)

#### 一時的に無効化されたWebhook {#temporarily-disabled-webhooks}

Webhookは4回連続して失敗すると、一時的に無効になります。Webhookが40回連続で失敗すると、完全に無効になります。

次の場合に失敗が発生します:

- Webhookレシーバーは、`4xx`または`5xx`の範囲の応答コードを返します。
- WebhookがWebhookレシーバーへの接続を試行中にタイムアウトします。
- Webhookでその他のHTTPエラーが発生した場合。

一時的に無効化されたWebhookは、最初は1分間無効になります。この期間は、後続の失敗発生時に延長され、最大で24時間まで延長されます。この期間が経過すると、これらのWebhookは自動的に再度有効になります。

#### 永久に無効化されたWebhook {#permanently-disabled-webhooks}

Webhookは、40回連続して失敗すると永久に無効になります。一時的に無効化されたWebhookとは異なり、これらのWebhookは自動的に再度有効になりません。

GitLab 17.10以前に永久に無効化されたWebhookに対してデータ移行が行われました。これらのWebhookは、UIでは40回の失敗が表示されていても、**最近のイベント**では4回の失敗が表示される場合があります。

#### 無効化されたWebhookを再度有効にする {#re-enable-disabled-webhooks}

無効になっているWebhookを再度有効にするには、テストリクエストを送信します。テストリクエストが`2xx`の範囲の応答コードを返すと、Webhookが再度有効になります。

### 配信ヘッダー {#delivery-headers}

{{< history >}}

- GitLab 16.2で`X-Gitlab-Webhook-UUID`ヘッダーが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/230830)されました。
- GitLab 17.4で`Idempotency-Key`ヘッダーが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/388692)されました。
- `webhook-id`および`webhook-timestamp`ヘッダーは、GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/19367)されました。
- `webhook-signature`ヘッダーは、GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/19367)され、`webhook_signing_token`という名前の[フラグ](../../../administration/feature_flags/_index.md)が付けられました。デフォルトでは有効になっています。
- 機能フラグ`webhook_signing_token`は、GitLab 19.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/596374)されました。

{{< /history >}}

GitLabは、お使いのエンドポイントへのWebhookリクエストに以下のヘッダーを含みます。

| ヘッダー                   | 説明                                                                                                                                                     | 例 |
|:-------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------|
| `Idempotency-Key`        | Webhookの再試行全体で一貫性のある一意のID。互換性のために利用可能ですが、`webhook-id`を優先してください。                                                                 | `"f5e5f430-f57b-4e6e-9fac-d9128cd7232f"` |
| `User-Agent`             | `"Gitlab/<VERSION>"`形式のユーザーエージェント。                                                                                                                  | `"GitLab/15.5.0-pre"` |
| `webhook-id`             | Webhookの再試行全体で一貫性のあるユニークなメッセージID。`Idempotency-Key`と等しい。                                                                                | `"f5e5f430-f57b-4e6e-9fac-d9128cd7232f"` |
| `webhook-signature`      | スペースで区切られたHMAC-SHA256署名リストで、各署名は`v1,{base64_signature}`の形式です。[署名トークン](#signing-tokens)が設定されている場合にのみ含まれます。 | `"v1,abc123def456=="` |
| `webhook-timestamp`      | リクエストが生成されたときのUnixタイムスタンプ（エポックからの秒数）。                                                                                            | `"1744578123"` |
| `X-Gitlab-Event-UUID`    | 非再帰Webhookの一意のID。再帰Webhook（以前のWebhookによってトリガーされる）は同じ値を共有します。                                                  | `"13792a34-cac6-4fda-95a8-c58e00a3954e"` |
| `X-Gitlab-Event`         | Webhookタイプ名。`"<EVENT> Hook"`の形式のイベントタイプに対応します。                                                                                   | `"Push Hook"` |
| `X-Gitlab-Instance`      | Webhookを送信したGitLabインスタンスのホスト名。                                                                                                          | `"https://gitlab.com"` |
| `X-Gitlab-Token`         | Webhookのシークレットトークンで、プレーンテキストとして送信されます。シークレットトークンが設定されている場合にのみ含まれます。                                                              | `"my-secret-token"` |
| `X-Gitlab-Webhook-UUID`  | 各Webhookの一意のID。                                                                                                                                     | `"02affd2d-2cba-4033-917d-ec22d5dc4b38"` |

### Webhook本文での画像URLの表示 {#image-url-display-in-webhook-body}

GitLabは、Webhook本文内の相対的な画像参照を絶対URLに書き換えます。

#### 画像URLの書き換えの例 {#image-url-rewriting-example}

マージリクエスト、コメント、またはWikiページ内の元の画像参照が次のようであるとします。

```markdown
![A Markdown image with a relative URL.](/uploads/$sha/image.png)
```

Webhook本文内で書き換えられた画像参照は次のようになります。

```markdown
![A Markdown image with an absolute URL.](https://gitlab.example.com/-/project/:id/uploads/<SHA>/image.png)
```

この例では、以下を前提としています。

- GitLabが`gitlab.example.com`にインストールされている。
- プロジェクトIDが`123`にある。

#### 画像URLの書き換えの例外 {#exceptions-to-image-url-rewriting}

次の場合、GitLabは画像URLを書き換えません。

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
- [GitLabラベルを自動的に適用する](https://about.gitlab.com/blog/applying-gitlab-labels-automatically/)
