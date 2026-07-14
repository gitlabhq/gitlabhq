---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: インスタンスの監査イベントストリーミング
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.1で`ff_external_audit_events`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/398107)されました。デフォルトでは無効になっています。
- [機能フラグ`ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)はGitLab 16.2でデフォルトで有効になりました。
- インスタンスのストリーミング宛先はGitLab 16.4で[一般提供されました](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)。[機能フラグ`ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/417708)は削除されました。
- カスタムHTTPヘッダーUIは、GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/361630)され、`custom_headers_streaming_audit_events_ui`という名前の[フラグ](../feature_flags/_index.md)が付けられました。デフォルトでは無効になっています。
- カスタムHTTPヘッダーUIはGitLab 15.3で[一般提供されました](https://gitlab.com/gitlab-org/gitlab/-/issues/365259)。[機能フラグ`custom_headers_streaming_audit_events_ui`](https://gitlab.com/gitlab-org/gitlab/-/issues/365259)は削除されました。
- GitLab 15.3で[UX](https://gitlab.com/gitlab-org/gitlab/-/issues/367963)が改善されました。
- HTTP宛先の**名前**フィールドはGitLab 16.3で[追加されました](https://gitlab.com/gitlab-org/gitlab/-/issues/411357)。
- **アクティブ**チェックボックスの機能はGitLab 16.5で[追加されました](https://gitlab.com/gitlab-org/gitlab/-/issues/415268)。

{{< /history >}}

インスタンスの監査イベントストリーミングでは、管理者は次のことができます:

- インスタンス全体のストリーミング宛先を設定し、そのインスタンスに関するすべての監査イベントを構造化されたJSONとして受信します。
- サードパーティシステムで監査ログを管理します。構造化されたJSONデータを受信できるサービスであれば、ストリーミング宛先として使用できます。

各ストリーミング宛先には、ストリーミングされる各イベントに最大20個のカスタムHTTPヘッダーを含めることができます。

GitLabは、単一のイベントを同じ宛先に複数回ストリーミングできます。ペイロード内の`id`キーを使用して、受信データの重複排除を行います。

監査イベントは、HTTPでサポートされているPOSTリクエストメソッドプロトコルを使用して送信されます。

> [!warning]
> ストリーミング宛先は**すべて**の監査イベントデータを受信します。これには機密情報が含まれる可能性があります。ストリーミング宛先を信頼していることを確認してください。

インスタンス全体のストリーミング宛先を管理します。

## HTTP宛先 {#http-destinations}

前提条件: 

- セキュリティ向上のため、宛先URLでSSL証明書を使用してください。

インスタンス全体のHTTPストリーミング宛先を管理します。

### 新しいHTTP宛先を追加 {#add-a-new-http-destination}

インスタンスに新しいHTTPストリーミング宛先を追加します。

前提条件: 

- インスタンスへの管理者アクセス。

インスタンスのストリーミング宛先を追加するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. メインエリアで、**ストリーム**タブを選択します。
1. **ストリーム先を追加**を選択し、**HTTPエンドポイント**を選択して宛先追加セクションを表示します。
1. **名前**および**宛先URL**フィールドに、宛先名とURLを追加します。
1. オプション。オプション。カスタムHTTPヘッダーを追加するには、**ヘッダーを追加**を選択して新しい名前と値のペアを作成し、その値を入力します。必要な数の名前と値のペアについて、この手順を繰り返します。ストリーミング宛先ごとに最大20個のヘッダーを追加できます。
1. ヘッダーをアクティブにするには、**アクティブ**チェックボックスを選択します。このヘッダーは監査イベントとともに送信されます。
1. **ヘッダーを追加**を選択して、新しい名前と値のペアを作成します。必要な数の名前と値のペアについて、この手順を繰り返します。ストリーミング宛先ごとに最大20個のヘッダーを追加できます。
1. すべてのヘッダーが入力されたら、**追加**を選択して新しいストリーミング宛先を追加します。

### HTTP宛先を更新 {#update-an-http-destination}

前提条件: 

- インスタンスへの管理者アクセス。

インスタンスのストリーミング宛先名を更新するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. メインエリアで、**ストリーム**タブを選択します。
1. ストリームを選択して展開します。
1. **名前**フィールドで、更新する宛先名を追加します。
1. **保存**を選択してストリーミング宛先を更新します。

インスタンスのストリーミング宛先のカスタムHTTPヘッダーを更新するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. メインエリアで、**ストリーム**タブを選択します。
1. ストリームを選択して展開します。
1. **Custom HTTP headers**テーブルを見つけます。
1. 更新するヘッダーを見つけます。
1. ヘッダーをアクティブにするには、**アクティブ**チェックボックスを選択します。このヘッダーは監査イベントとともに送信されます。
1. **ヘッダーを追加**を選択して、新しい名前と値のペアを作成します。必要な数の名前と値のペアを入力します。ストリーミング宛先ごとに最大20個のヘッダーを追加できます。
1. **保存**を選択してストリーミング宛先を更新します。

### イベントの認証情報を検証 {#verify-event-authenticity}

{{< history >}}

- GitLab 16.1で`ff_external_audit_events`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/398107)されました。デフォルトでは無効になっています。
- [機能フラグ`ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)はGitLab 16.2でデフォルトで有効になりました。
- インスタンスのストリーミング宛先はGitLab 16.4で[一般提供されました](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)。[機能フラグ`ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/417708)は削除されました。

{{< /history >}}

各ストリーミング宛先には、イベントの認証情報を検証するために使用できる一意の検証トークン（`verificationToken`）があります。このトークンは、オーナーによって指定されるか、イベント宛先が作成されたときに自動的に生成され、変更することはできません。

ストリーミングされる各イベントには、`X-Gitlab-Event-Streaming-Token` HTTPヘッダーに検証トークンが含まれており、ストリーミング宛先を一覧表示する際に宛先の値と照合して検証できます。

前提条件: 

- インスタンスへの管理者アクセス。

インスタンスのストリーミング宛先を一覧表示し、検証トークンを確認するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. メインエリアで、**ストリーム**タブを選択します。
1. 各項目の右側にある検証トークンを表示します。

### イベントフィルターを更新 {#update-event-filters}

{{< history >}}

- UIでの監査イベントタイプ定義リストによるイベントタイプのフィルタリングはGitLab 16.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/415013)。

{{< /history >}}

この機能が有効な場合、ユーザーは宛先ごとにストリーミングされる監査イベントをフィルタリングできます。フィルターなしで機能が有効な場合、宛先はすべての監査イベントを受信します。

イベントタイプのフィルターが設定されたストリーミング宛先には、**フィルタリング済み**（{{< icon name="filter" >}}）のラベルが表示されます。

ストリーミング宛先のイベントフィルターを更新するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. メインエリアで、**ストリーム**タブを選択します。
1. ストリームを選択して展開します。
1. **監査イベントタイプでフィルタリング**ドロップダウンリストを見つけます。
1. ドロップダウンリストを選択し、必要なイベントタイプを選択またはクリアします。
1. **保存**を選択してイベントフィルターを更新します。

### デフォルトのコンテンツタイプヘッダーを上書き {#override-default-content-type-header}

デフォルトでは、ストリーミング宛先は`content-type`ヘッダーとして`application/x-www-form-urlencoded`を使用します。ただし、`content-type`ヘッダーを別のものに設定したい場合があります。例: `application/json`。

インスタンスのストリーミング宛先の`content-type`ヘッダーのデフォルト値を上書きするには、次のいずれかを使用します:

- [GitLab UI](#update-an-http-destination)。
- [GraphQL API](../../api/graphql/audit_event_streaming_instances.md#update-streaming-destinations)。

## Google Cloud Logging宛先 {#google-cloud-logging-destinations}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131851)されました。

{{< /history >}}

インスタンス全体のGoogle Cloud Logging宛先を管理します。

### 前提条件 {#prerequisites}

Google Cloud Loggingストリーミング監査イベントを設定する前に、次の操作が必要です:

1. Google Cloudプロジェクトで[Cloud Logging API](https://console.cloud.google.com/marketplace/product/google/logging.googleapis.com)を有効にします。
1. 適切な認証情報と権限を持つGoogle Cloudのサービスアカウントを作成します。このアカウントは、監査ログストリーミング認証を設定するために使用されます。詳細については、[Google Cloudドキュメントのサービスアカウントの作成と管理](https://cloud.google.com/iam/docs/service-accounts-create#creating)を参照してください。
1. サービスアカウントの**Logs Writer**ロールを有効にして、Google Cloudでロギングを有効にします。詳細については、[IAMによるアクセス制御](https://cloud.google.com/logging/docs/access-control#logging.logWriter)を参照してください。
1. サービスアカウントのJSONキーを作成します。詳細については、[サービスアカウントキーの作成](https://cloud.google.com/iam/docs/keys-create-delete#creating)を参照してください。

### 新しいGoogle Cloud Logging宛先を追加 {#add-a-new-google-cloud-logging-destination}

前提条件: 

- インスタンスへの管理者アクセス。

インスタンスにGoogle Cloud Loggingストリーミング宛先を追加するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. メインエリアで、**ストリーム**タブを選択します。
1. **ストリーム先を追加**を選択し、**Google Cloud Logging**を選択して宛先追加セクションを表示します。
1. 新しい宛先の名前として使用するランダムな文字列を入力します。
1. 以前に作成したGoogle Cloudサービスアカウントキーから、GoogleプロジェクトIDとGoogleクライアントメールを入力します。
1. 以前に作成したGoogle Cloudサービスアカウントキーから、Googleプライベートキーを入力します。PEM形式で、`-----BEGIN PRIVATE KEY-----`で始まる必要があります。JSONキー全体をアップロードしないでください。
1. 新しい宛先のログIDとして使用するランダムな文字列を入力します。後でこれを使用して、Google Cloudでログ結果をフィルタリングできます。
1. **追加**を選択して新しいストリーミング宛先を追加します。

### Google Cloud Logging宛先を更新 {#update-a-google-cloud-logging-destination}

前提条件: 

- インスタンスへの管理者アクセス。

インスタンスにGoogle Cloud Loggingストリーミング宛先を更新するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. メインエリアで、**ストリーム**タブを選択します。
1. Google Cloud Loggingストリームを展開するには、選択します。
1. 宛先の名前として使用するランダムな文字列を入力します。
1. 以前に作成したGoogle Cloudサービスアカウントキーから、GoogleプロジェクトIDとGoogleクライアントメールを入力して宛先を更新します。
1. 宛先のログIDを更新するために、ランダムな文字列を入力します。後でこれを使用して、Google Cloudでログ結果をフィルタリングできます。
1. **新しい秘密キーを追加**を選択し、Googleプライベートキーを入力してプライベートキーを更新します。
1. **保存**を選択してストリーミング宛先を更新します。

## AWS S3宛先 {#aws-s3-destinations}

{{< history >}}

- GitLab 16.7で`allow_streaming_instance_audit_events_to_amazon_s3`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138245)されました。デフォルトでは無効になっています。
- [機能フラグ`allow_streaming_instance_audit_events_to_amazon_s3`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137391)はGitLab 16.8で削除されました。

{{< /history >}}

インスタンス全体のAWS S3宛先を管理します。

### 前提条件 {#prerequisites-1}

AWS S3ストリーミング監査イベントを設定する前に、次の操作が必要です:

1. 適切な認証情報と権限を持つAWSのアクセスキーを作成します。このアカウントは、監査ログストリーミング認証を設定するために使用されます。詳細については、[アクセスキーの管理](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html?icmpid=docs_iam_console#Using_CreateAccessKey)を参照してください。
1. AWS S3バケットを作成します。このバケットは、監査ログストリーミングデータを保存するために使用されます。詳細については、[バケットの作成](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html)を参照してください。

### 新しいAWS S3宛先を追加 {#add-a-new-aws-s3-destination}

前提条件: 

- インスタンスへの管理者アクセス。

インスタンスにAWS S3ストリーミング宛先を追加するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. メインエリアで、**ストリーム**タブを選択します。
1. **ストリーム先を追加**を選択し、**AWS S3**を選択して宛先追加セクションを表示します。
1. 新しい宛先の名前として使用するランダムな文字列を入力します。
1. 以前に作成したAWSアクセスキーとバケットから、**アクセスキーID**、**シークレットアクセスキー**、**バケット名**、および**AWSリージョン**を入力して新しい宛先に追加します。
1. **追加**を選択して新しいストリーミング宛先を追加します。

### AWS S3宛先を更新 {#update-an-aws-s3-destination}

前提条件: 

- インスタンスへの管理者アクセス。

インスタンスのAWS S3ストリーミング宛先を更新するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. メインエリアで、**ストリーム**タブを選択します。
1. AWS S3ストリームを展開するには、選択します。
1. 宛先の名前として使用するランダムな文字列を入力します。
1. 宛先を更新するには、以前に作成したAWSアクセスキーとバケットから、**アクセスキーID**、**シークレットアクセスキー**、**バケット名**、および**AWSリージョン**を入力します。
1. Select **Add a new Secret Access Key**と入力し、AWSシークレットアクセスキーを入力してシークレットアクセスキーを更新します。
1. **保存**を選択します。

## ストリーミング宛先を一覧表示 {#list-streaming-destinations}

前提条件: 

- インスタンスへの管理者アクセス。

インスタンスのストリーミング宛先を一覧表示するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. メインエリアで、**ストリーム**タブを選択します。
1. ストリームを選択して展開します。

## ストリーミング宛先を有効化または無効化 {#activate-or-deactivate-streaming-destinations}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/537096)されました。

{{< /history >}}

宛先の設定を削除せずに、宛先への監査イベントストリーミングを一時的に無効にできます。ストリーミング宛先が無効になると:

- 監査イベントは、その宛先へのストリーミングを直ちに停止します。
- 宛先設定は保持されます。
- 宛先はいつでも再アクティブ化できます。
- 他のアクティブな宛先はイベントを受信し続けます。

### ストリーミング宛先を無効化 {#deactivate-a-streaming-destination}

前提条件: 

- インスタンスへの管理者アクセス。

ストリーミング宛先を無効にするには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. メインエリアで、**ストリーム**タブを選択します。
1. ストリームを選択して展開します。
1. **アクティブ**チェックボックスをクリアします。
1. **保存**を選択します。

宛先は監査イベントの受信を停止します。

### ストリーミング宛先を有効化 {#activate-a-streaming-destination}

以前に無効化されたストリーミング宛先を再アクティブ化するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. メインエリアで、**ストリーム**タブを選択します。
1. ストリームを選択して展開します。
1. **有効**チェックボックスを選択します。
1. **保存**を選択します。

宛先は監査イベントの受信を直ちに再開します。

## AI監査イベントストリーミング {#ai-audit-event-streaming}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.1で[ベータとして導入されました。](https://gitlab.com/gitlab-org/gitlab/-/issues/591588)

{{< /history >}}

> [!warning]
> AI監査イベントストリーミングを有効にすると、インスタンスのパフォーマンスに影響を与える可能性があります。この設定は、インスタンスの負荷を評価した後にのみ有効にしてください。

GitLab Duo Agent Platformは、次のようなアクティビティのAI監査イベントを記録します:

- エージェントセッション。
- LLMリクエスト。
- ツールの呼び出し。
- ユーザー入力。

GitLabは、これらのイベントを常にデータベースに保存します。

また、個別の設定を使用して、GitLabがAI監査イベントを外部宛先にストリーミングするかどうかを制御できます。この設定はデフォルトでオフになっています。

AI監査イベントストリーミングの場合:

- 有効になっている場合、GitLabはAI監査イベントをすべてのアクティブなインスタンスストリーミング宛先にストリーミングします。イベントタイプフィルター、カスタムHTTPヘッダー、および検証トークンは、他の監査イベントと同じ方法でAI監査イベントに適用されます。
- 無効になっている場合でも、GitLabはAI監査イベントをデータベースに保存しますが、外部宛先には送信しません。他の監査イベントタイプは、各宛先の設定に従ってストリーミングを続行します。

### AI監査イベントストリーミングを有効にする {#turn-on-ai-audit-event-streaming}

前提条件: 

- インスタンスへの管理者アクセス。

AI監査イベントストリーミングを有効にするには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **Enable AI audit event streaming**チェックボックスを選択します。
1. **変更を保存**を選択します。

### AI監査イベントストリーミングを無効にする {#turn-off-ai-audit-event-streaming}

前提条件: 

- インスタンスへの管理者アクセス。

AI監査イベントストリーミングを無効にするには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **Enable AI audit event streaming**チェックボックスをクリアします。
1. **変更を保存**を選択します。

AI監査イベントは直ちにストリーミングを停止します。GitLabは引き続きデータベースに保存します。

## ストリーミング宛先を削除 {#delete-streaming-destinations}

インスタンス全体のストリーミング宛先を削除します。最後の宛先が正常に削除されると、インスタンスのストリーミングは無効になります。

前提条件: 

- インスタンスへの管理者アクセス。

インスタンスのストリーミング宛先を削除するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. メインエリアで、**ストリーム**タブを選択します。
1. ストリームを選択して展開します。
1. **移動先を削除**を選択します。
1. 確認するには、**移動先を削除**を選択します。

### カスタムHTTPヘッダーのみを削除 {#delete-only-custom-http-headers}

前提条件: 

- インスタンスへの管理者アクセス。

ストリーミング宛先のカスタムHTTPヘッダーのみを削除するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**モニタリング** > **監査イベント**を選択します。
1. メインエリアで、**ストリーム**タブを選択します。
1. 項目の右側にある**編集**（{{< icon name="pencil" >}}）を選択します。
1. **Custom HTTP headers**テーブルを見つけます。
1. 削除するヘッダーを見つけます。
1. ヘッダーの右側にある**削除**（{{< icon name="remove" >}}）を選択します。
1. **保存**を選択します。

## 関連トピック {#related-topics}

- [トップレベルグループの監査イベントストリーミング](../../user/compliance/audit_event_streaming.md)
