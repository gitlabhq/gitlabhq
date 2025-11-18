---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 統合エラートラッキング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

このガイドでは、さまざまな言語の例を使用して、プロジェクトの統合エラートラッキングを設定する方法に関する基本的な情報を提供します。

GitLab可観測性によって提供されるエラートラッキングは、[Sentry SDK](https://docs.sentry.io/)に基づいています。アプリケーションでSentry SDKを使用する方法の詳細と例については、[Sentry SDKのドキュメント](https://docs.sentry.io/platforms/)を参照してください。

## プロジェクトのエラートラッキングを有効にする {#enable-error-tracking-for-a-project}

使用するプログラミング言語に関係なく、最初にGitLabプロジェクトのエラートラッキングを有効にする必要があります。このガイドでは、`GitLab.com`インスタンスを使用します。

前提要件:

- エラートラッキングを有効にするプロジェクトが必要です。[プロジェクトの作成](../user/project/_index.md)方法を参照してください。

GitLabをバックエンドとしてエラートラッキングを有効にするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **モニタリング**に移動します。
1. **エラートラッキング**を展開します。
1. **エラートラッキングを有効にする**で、**アクティブ**を選択します。
1. **バックエンドのトラッキングエラー**で**GitLab**を選択します。
1. **変更を保存**を選択します。
1. **Data Source Name (DSN)**（データソース名（DSN））文字列をコピーします。SDK実装を構成するために必要になります。

## ユーザートラッキングの設定 {#configure-user-tracking}

エラーの影響を受けるユーザー数を追跡するには:

- 初期化コードで、各ユーザーが一意に識別されるようにします。ユーザー追跡するには、ユーザーID、名前、メールアドレス、またはIPアドレスを使用できます。

たとえば、[Python](https://docs.sentry.io/platforms/python/enriching-events/identify-user/)を使用している場合は、メールでユーザーを識別できます:

```python
sentry_sdk.set_user({ email: "john.doe@example.com" });
```

ユーザーの識別に関する詳細については、[Sentry](https://docs.sentry.io/)ドキュメントを参照してください。

## 追跡されたエラーを表示する {#view-tracked-errors}

アプリケーションがSentry SDKを介してエラートラッキングAPIにエラーを送信すると、それらのエラーがGitLab UIで使用できるようになります。それらを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング**>**エラートラッキング**に移動して、未解決のエラーのリストを表示します:

   ![MonitorListErrors](img/list_errors_v16_0.png)

1. エラーを選択して、**Error details**（エラーの詳細）ビューを表示します:

   ![MonitorDetailErrors](img/detail_errors_v16_0.png)

   このページには、例外の詳細が次のように表示されます:

   - 合計発生回数。
   - 影響を受けたユーザーの合計。
   - 初回閲覧日：日付とコミット（{{< icon name="commit" >}}）。
   - 最終閲覧日。相対日付として表示。タイムスタンプを表示するには、日付にカーソルを合わせます。
   - 1時間あたりのエラー頻度の棒グラフ。特定の時間の合計エラー数を表示するには、バーにカーソルを合わせます。
   - スタックトレース。

### エラーからイシューを作成する {#create-an-issue-from-an-error}

エラーに関連する作業を追跡する場合は、エラーから直接イシューを作成できます:

- **Error details**（エラーの詳細）ビューで、**イシューの作成**を選択します。

イシューが作成されます。イシューの説明には、エラースタックトレースが含まれています。

### エラーの詳細を分析する {#analyze-an-errors-details}

エラーの完全なタイムスタンプを表示するには:

- **Error details**（エラーの詳細）ページで、**最終閲覧**日にカーソルを合わせます。

次の例では、エラーは11:41 CESTに発生しました。

![MonitorDetailErrors](img/last_seen_v16_10.png)

**直近の24時間**グラフは、このエラーが1時間あたりに発生した回数を測定します。`11 am`バーをポイントすると、ダイアログにエラーが239回表示されたことが示されます:

![MonitorDetailErrors](img/error_bucket_v16_10.png)

**最終閲覧**フィールドは、[`import * as timeago from 'timeago.js'`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/lib/utils/datetime/timeago_utility.js#L1)を呼び出すために使用されるライブラリが原因で、1時間が完了するまで更新されません。

## エラーを出力 {#emit-errors}

### サポートされている言語SDKとSentryのタイプ {#supported-language-sdks--sentry-types}

GitLabエラートラッキングは、次のイベントタイプをサポートしています:

| 言語 | テスト済みのSDKクライアントとバージョン   | エンドポイント   | サポートされているアイテムタイプ              |
| -------- | ------------------------------- | ---------- | --------------------------------- |
| Go       | `sentry-go/0.20.0`              | `store`    | `exception`、`message`            |
| Java     | `sentry.java:6.18.1`            | `envelope` | `exception`、`message`            |
| NodeJS   | `sentry.javascript.node:7.38.0` | `envelope` | `exception`、`message`            |
| PHP      | `sentry.php/3.18.0`             | `store`    | `exception`、`message`            |
| Python   | `sentry.python/1.21.0`          | `envelope` | `exception`、`message`、`session` |
| Ruby     | `sentry.ruby:5.9.0`             | `envelope` | `exception`、`message`            |
| Rust     | `sentry.rust/0.31.0`            | `envelope` | `exception`、`message`、`session` |

このテーブルの詳細バージョンについては、[issue 1737](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/1737)を参照してください。

例外、イベント、またはメッセージをそのSDKでキャプチャする方法を示す、サポートされている言語SDKの作業[例](https://gitlab.com/gitlab-org/opstrace/opstrace/-/tree/main/test/sentry-sdk/testdata/supported-sdk-clients)も参照してください。詳細については、特定の言語の[Sentry SDKのドキュメント](https://docs.sentry.io/)を参照してください。

## 生成されたDSNをローテートする {#rotate-generated-dsn}

{{< alert type="warning" >}}

Sentryによると、[DSNを公開しても安全](https://docs.sentry.io/concepts/key-terms/dsn-explainer/#dsn-utilization)ですが、これにより、悪意のあるユーザーによってジャンクイベントがSentryに送信される可能性が開かれます。したがって、可能であれば、DSNをシークレットにしておく必要があります。これは、DSNが読み込むため、ユーザーのデバイスに保存されるクライアント側のアプリケーションには適用されません。

{{< /alert >}}

前提要件:

- プロジェクトの数値[プロジェクトID](../user/project/working_with_projects.md#find-the-project-id)が必要です。

Sentry DSNをローテートするには:

1. `api`のスコープを持つ[アクセストークンを作成](../user/profile/personal_access_tokens.md#create-a-personal-access-token)します。今後の手順で必要になるため、この値をコピーしてください。
1. [error tracking API](../api/error_tracking.md)を使用して新しいSentry DSNを作成し、`<your_access_token>`と`<your_project_number>`を自分の値に置き換えます:

   ```shell
   curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_number>/error_tracking/client_keys"
   ```

1. 使用可能なクライアントキー（Sentry DSN）を取得します。新しく作成したSentry DSNが配置されていることを確認します。古いクライアントキーのキーIDを使用して次のコマンドを実行し、`<your_access_token>`と`<your_project_number>`を自分の値に置き換えます:

   ```shell
   curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_number>/error_tracking/client_keys"
   ```

1. 古いクライアントキーを削除します:

   ```shell
   curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_number>/error_tracking/client_keys/<key_id>"
   ```

## SDKのイシューをデバッグする {#debug-sdk-issues}

Sentryでサポートされているほとんどの言語は、初期化の一部として`debug`オプションを公開しています。`debug`オプションは、エラーの送信に関するイシューをデバッグするときに役立ちます。APIにデータを送信する前にJSONを出力するその他のオプションがあります。

## データ保持 {#data-retention}

GitLabには、すべてのエラーに対する90日間の保持制限があります。

エラートラッキングのバグまたは機能に関するフィードバックを残すには、[フィードバックイシュー](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2362)にコメントするか、[新しいイシュー](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/new)を開いてください。
