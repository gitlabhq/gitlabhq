---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Create and maintain a custom feature flag for your GitLab application.
title: 機能フラグ
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

機能フラグを使用すると、アプリケーションの新しい機能をより小さなバッチで本番環境にデプロイできます。機能をオンまたはオフにして、ユーザーのサブセットを切り替えることで、継続的なデリバリーを実現できます。機能フラグは、リスクを軽減し、制御されたTestを実行し、機能の提供を顧客のローンチから分離するのに役立ちます。

GitLab の[機能フラグの完全なリスト](../user/feature_flags.md)も利用できます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> 機能フラグの実際の動作例については、[機能フラグによるリスクの排除](https://www.youtube.com/watch?v=U9WqoK9froI)を参照してください。
<!-- Video published on 2024-02-01 -->

クリックスルー デモについては、[機能フラグ](https://tech-marketing.gitlab.io/static-demos/feature-flags/feature-flags-html.html)を参照してください。
<!-- Demo published on 2023-07-13 -->

{{< alert type="note" >}}

GitLab 製品の開発に貢献するには、代わりに[この機能フラグのコンテンツ](../development/feature_flags/_index.md)を表示してください。

{{< /alert >}}

## 仕組み

GitLab は、機能フラグ用の [Unleash](https://github.com/Unleash/unleash) 互換 API を提供します。

GitLab でフラグを有効または無効にすると、アプリケーションは有効または無効にする機能を判断できます。

GitLab で機能フラグを作成し、アプリケーションから API を使用して、機能フラグとその状態のリストを取得できます。アプリケーションは GitLab と通信するようにConfigureする必要があるため、互換性のあるクライアントライブラリを使用し、[機能フラグをアプリに統合する](#integrate-feature-flags-with-your-application)のはデベロッパー次第です。

## 機能フラグを作成

機能フラグを作成して有効にするには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **デプロイ > 機能フラグ**を選択します。
1. **新しい機能フラグ**を選択します。
1. 文字で始まり、小文字、数字、アンダースコア（`_`）またはダッシュ（`-`）のみを含み、ダッシュ（`-`）またはアンダースコア（`_`）で終わらない名前を入力します。
1. 任意。説明を入力します(最大255文字)。
1. フラグの適用方法を定義するには、機能フラグ[**ストラテジ**](#feature-flag-strategies)を追加します。各ストラテジについて、**タイプ**（デフォルトは[**すべてのユーザー**](#all-users)）と**環境**（デフォルトはすべての環境）を含めます。
1. **機能フラグの作成**を選択します。

これらの設定を変更するには、リスト内の任意の機能フラグの横にある**編集**（{{< icon name="pencil" >}}）を選択します。

## 機能フラグの最大数

GitLab Self-Managed のプロジェクトごとの機能フラグの最大数は 200 です。GitLab.com の場合、最大数は[プラン](https://about.gitlab.com/pricing/)によって決まります:

| プラン     | プロジェクトごとの機能フラグ (GitLab.com) | プロジェクトごとの機能フラグ (GitLab Self-Managed) |
|----------|----------------------------------|------------------------------------------|
| Free     | 50                               | 200                                      |
| Premium  | 150                              | 200                                      |
| Ultimate | 200                              | 200                                      |

## 機能フラグのストラテジ

ストラテジを複数回定義しなくても、複数環境に機能フラグのストラテジを適用できます。

GitLab の機能フラグは[Unleash](https://docs.getunleash.io/)に基づいています。Unleash には、詳細な機能フラグ制御のための[ストラテジ](https://docs.getunleash.io/reference/activation-strategies)があります。GitLab の機能フラグには複数のストラテジを設定でき、サポートされているストラテジは次のとおりです。

- [すべてのユーザー](#all-users)
- [ユーザーの割合](#percent-of-users)
- [ユーザーID](#user-ids)
- [ユーザーリスト](#user-list)

ストラテジは、[機能フラグの作成](#create-a-feature-flag)時、または**デプロイ > 機能フラグ**に移動し、**編集** ({{< icon name="pencil" >}}) を選択して、作成後に既存の機能フラグを編集することで、機能フラグに追加できます。

### すべてのユーザー

すべてのユーザーに対して機能を有効にします。Standard (`default`) Unleash アクティベーション[ストラテジ](https://docs.getunleash.io/reference/activation-strategies#standard)を使用します。

### ロールアウト率

動作の一貫性を設定可能にして、ページビューの割合に対して機能を有効にします。この一貫性は、スティッキー性とも呼ばれます。Gradual Rollout (`flexibleRollout`) Unleash アクティベーション[ストラテジ](https://docs.getunleash.io/reference/activation-strategies#gradual-rollout)を使用します。

一貫性は、以下に基づいてConfigureできます:

- **ユーザーID**:各ユーザーIDは、セッションIDを無視して、一貫した動作をします。
- **セッションID**:各セッションIDは、ユーザーIDを無視して、一貫した動作をします。
- **ランダム**:一貫した動作は保証されません。機能は、ページビューの選択された割合に対してランダムに有効になります。ユーザーIDとセッションIDは無視されます。
- **利用可能なID**:ユーザーの状態に基づいて一貫した動作が試みられます:
  - ユーザーがログインしている場合、ユーザーIDに基づいて動作を一貫させます。
  - ユーザーが匿名の場合、セッションIDに基づいて動作を一貫させます。
  - ユーザーIDまたはセッションIDがない場合、機能はページビューの選択された割合に対してランダムに有効になります。

たとえば、**利用可能なID**に基づいて15%の値を設定して、ページビューの15%に対して機能を有効にします。認証済みユーザーの場合、これはユーザーIDに基づいています。セッションIDを持つ匿名のユーザーの場合、ユーザーIDがないため、代わりにセッションIDに基づいています。次に、セッションIDが提供されていない場合は、ランダムに戻ります。

ロールアウト率は0%から100%です。

ユーザーIDに基づいて一貫性を選択すると、[ユーザーの割合](#percent-of-users)ロールアウトと同じように機能します。

{{< alert type="warning" >}}

**ランダム**を選択すると、個々のユーザーに対して一貫性のないアプリケーションの動作が提供されます。

{{< /alert >}}

### ユーザーの割合

認証済みユーザーの割合に対して機能を有効にします。Unleash アクティベーション ストラテジ[`gradualRolloutUserId`](https://docs.getunleash.io/reference/activation-strategies#gradual-rollout)を使用します。

たとえば、15%の値を設定して、認証済みユーザーの15%に対して機能を有効にします。

ロールアウト率は0%から100%です。

スティッキー性(同じユーザーに対して一貫したアプリケーションの動作)は、認証済みユーザーには保証されますが、匿名ユーザーには保証されません。

**ユーザーID**に基づいて一貫性のある[ロールアウト率](#percent-rollout)は、同じ動作をします。ユーザーの割合よりもロールアウト率の方が柔軟性があるため、ロールアウト率を使用することをお勧めします。

{{< alert type="warning" >}}

ユーザーの割合ストラテジを選択した場合、機能を有効にするには、Unleash クライアントにユーザーIDを**指定する**必要があります。以下の[Ruby の例](#ruby-application-example)を参照してください。

{{< /alert >}}

### ユーザーID

ターゲットユーザーのリストに対して機能を有効にします。Unleash UserIDs (`userWithId`) アクティベーション[ストラテジ](https://docs.getunleash.io/reference/activation-strategies#userids)を使用して実装されます。

ユーザーIDを、コンマ区切りの値のリストとして入力します(例: `user@example.com, user2@example.com`、または`username1,username2,username3`など)。ユーザーIDは、アプリケーションユーザーの識別子です。GitLab ユーザーである必要はありません。

{{< alert type="warning" >}}

ターゲットユーザーに対して機能を有効にするには、Unleash クライアントにユーザーIDを**指定する**必要があります。以下の[Ruby の例](#ruby-application-example)を参照してください。

{{< /alert >}}

### ユーザーリスト

[機能フラグ UI](#create-a-user-list)で作成されたユーザーのリスト、または[機能フラグユーザーリスト API](../api/feature_flag_user_lists.md)で作成されたユーザーのリストに対して機能を有効にします。[ユーザーID](#user-ids)と同様に、Unleash UsersIDs (`userWithId`) アクティベーション[ストラテジ](https://docs.getunleash.io/reference/activation-strategies#userids)を使用します。

特定のユーザーに対して特定の機能を無効にすることはできませんが、ユーザーリストに対して機能を有効にすることで、同様の結果を得ることができます。

次に例を示します:

- `Full-user-list` = `User1A, User1B, User2A, User2B, User3A, User3B, ...`
- `Full-user-list-excluding-B-users` = `User1A, User2A, User3A, ...`

#### ユーザーリストを作成

ユーザーリストを作成するには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **デプロイ > 機能フラグ**を選択します。
1. **ユーザーリストを表示**を選択します
1. **新しいユーザーリスト**を選択します。
1. リストの名前を入力します。
1. **作成**を選択します。

リストを表示するには、横にある**編集** ({{< icon name="pencil" >}}) を選択して、ユーザーIDを表示できます。リストを表示している場合は、**編集** ({{< icon name="pencil" >}}) を選択して名前を変更できます。

#### ユーザーをユーザーリストに追加

ユーザーをユーザーリストに追加するには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **デプロイ > 機能フラグ**を選択します。
1. ユーザーを追加するリストの横にある**編集** ({{< icon name="pencil" >}}) を選択します。
1. **ユーザーの追加**を選択します。
1. ユーザーIDを、コンマ区切りの値のリストとして入力します。たとえば、`user@example.com, user2@example.com`、または`username1,username2,username3`などです。
1. **追加**を選択します。

#### ユーザーをユーザーリストから削除

ユーザーをユーザーリストから削除するには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **デプロイ > 機能フラグ**を選択します。
1. 変更するリストの横にある**編集** ({{< icon name="pencil" >}}) を選択します。
1. 削除するIDの横にある**削除** ({{< icon name="remove" >}}) を選択します。

## コード参照を検索

{{< details >}}

- プラン:Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

クリーンアップ中にコードから機能フラグを削除するには、それに対するプロジェクト参照を見つけます。

機能フラグのコード参照を検索するには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **デプロイ > 機能フラグ**を選択します。
1. 削除する機能フラグを編集します。
1. **その他のアクション** ({{< icon name="ellipsis_v" >}}) を選択します。
1. **コード参照の検索**を選択します。

## 特定の環境の機能フラグを無効にする

特定の環境の機能フラグを無効にするには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **デプロイ > 機能フラグ**を選択します。
1. 無効にする機能フラグについて、**編集** ({{< icon name="pencil" >}}) を選択します。
1. フラグを無効にするには:
   - 適用される各ストラテジについて、**環境**の下で、環境を削除します。
1. **変更を保存**を選択します。

## すべての環境の機能フラグを無効にする

すべての環境の機能フラグを無効にするには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **デプロイ > 機能フラグ**を選択します。
1. 無効にする機能フラグについて、\[状態]切替を**無効**にスライドさせます。

機能フラグは、\[**無効**]タブに表示されます。

## 機能フラグをアプリケーションと統合する

アプリケーションで機能フラグを使用するには、GitLab からアクセス認証情報を取得します。次に、クライアントライブラリを使用してアプリケーションを準備します。

### アクセス認証情報を取得する

アプリケーションが GitLab と通信するために必要なアクセス認証情報を取得するには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **デプロイ > 機能フラグ**を選択します。
1. **Configure**を選択して、以下を表示します:
   - **API URL**:クライアント(アプリケーション)が機能フラグのリストを取得するために接続するURL。
   - **インスタンスID**:機能フラグの取得を承認する一意のトークン。
   - **アプリケーション名**:アプリケーションが実行される*環境*の名前(アプリケーション自体の名前ではありません)。

     たとえば、アプリケーションが本番環境サーバーで実行されている場合、**アプリケーション名**は`production`または同様のものになる可能性があります。この値は、環境仕様の評価に使用されます。

これらのフィールドの意味は、時間の経過とともに変わる可能性があります。たとえば、**インスタンスID**が、**環境**に割り当てられた単一のトークンか複数のトークンかは不明です。また、**アプリケーション名**は、実行環境ではなくアプリケーションのバージョンを記述している可能性があります。

### クライアントライブラリを選択する

GitLab は、Unleash クライアントと互換性のある単一のバックエンドを実装します。

Unleash クライアントを使用すると、デベロッパーはアプリケーションコードで、フラグのデフォルト値を定義できます。各機能フラグの評価では、提供された設定ファイルにフラグが存在しない場合に、目的の結果を表現できます。

Unleash は現在、[さまざまな言語とフレームワーク用の多くの SDK を提供しています](https://github.com/Unleash/unleash#unleash-sdks)。

### 機能フラグ API 情報

API コンテンツについては、以下を参照してください:

- [機能フラグ API](../api/feature_flags.md)
- [機能フラグユーザーリスト API](../api/feature_flag_user_lists.md)

### Go アプリケーションの例

Go アプリケーションに機能フラグを統合する方法の例を次に示します:

```go
package main

import (
    "io"
    "log"
    "net/http"

    "github.com/Unleash/unleash-client-go/v3"
)

type metricsInterface struct {
}

func init() {
    unleash.Initialize(
        unleash.WithUrl("https://gitlab.com/api/v4/feature_flags/unleash/42"),
        unleash.WithInstanceId("29QmjsW6KngPR5JNPMWx"),
        unleash.WithAppName("production"), // Set to the running environment of your application
        unleash.WithListener(&metricsInterface{}),
    )
}

func helloServer(w http.ResponseWriter, req *http.Request) {
    if unleash.IsEnabled("my_feature_name") {
        io.WriteString(w, "Feature enabled\n")
    } else {
        io.WriteString(w, "hello, world!\n")
    }
}

func main() {
    http.HandleFunc("/", helloServer)
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

### Ruby アプリケーションの例

Ruby アプリケーションに機能フラグを統合する方法の例を次に示します。

Unleash クライアントには、**ロールアウト率 (% ロールアウト、ログイン ユーザー)**または**ターゲットユーザー**のリストで使用するためのユーザーIDが与えられます。

```ruby
#!/usr/bin/env ruby

require 'unleash'
require 'unleash/context'

unleash = Unleash::Client.new({
  url: 'http://gitlab.com/api/v4/feature_flags/unleash/42',
  app_name: 'production', # Set to the running environment of your application
  instance_id: '29QmjsW6KngPR5JNPMWx'
})

unleash_context = Unleash::Context.new
# Replace "123" with the ID of an authenticated user.
# Note that the context's user ID must be a string:
# https://unleash.github.io/docs/unleash_context
unleash_context.user_id = "123"

if unleash.is_enabled?("my_feature_name", unleash_context)
  puts "Feature enabled"
else
  puts "hello, world!"
end
```

### Unleash Proxy の例

[Unleash Proxy](https://docs.getunleash.io/reference/unleash-proxy) バージョン 0.2 以降、プロキシは機能フラグと互換性があります。

GitLab.com の本番環境では Unleash Proxy を使用する必要があります。詳細については、[パフォーマンスに関する注意](#maximum-supported-clients-in-application-nodes)を参照してください。

プロジェクトの機能フラグに接続するための Docker コンテナを実行するには、次のコマンドを実行します:

```shell
docker run \
  -e UNLEASH_PROXY_SECRETS=<secret> \
  -e UNLEASH_URL=<project feature flags URL> \
  -e UNLEASH_INSTANCE_ID=<project feature flags instance ID> \
  -e UNLEASH_APP_NAME=<project environment> \
  -e UNLEASH_API_TOKEN=<tokenNotUsed> \
  -p 3000:3000 \
  unleashorg/unleash-proxy
```

| 変数                    | 値                                                                                                                                |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `UNLEASH_PROXY_SECRETS`      | [Unleash Proxy クライアント](https://docs.getunleash.io/reference/unleash-proxy#how-to-connect-to-the-proxy)をConfigureするために使用される共有シークレット。 |
| `UNLEASH_URL`         | プロジェクトの API URL。詳細については、[アクセス認証情報を取得する](#get-access-credentials)をお読みください。 |
| `UNLEASH_INSTANCE_ID` | プロジェクトのインスタンス ID。詳細については、[アクセス認証情報を取得する](#get-access-credentials)をお読みください。 |
| `UNLEASH_APP_NAME`    | アプリケーションが実行される環境の名前。詳細については、[アクセス認証情報を取得する](#get-access-credentials)をお読みください。 |
| `UNLEASH_API_TOKEN`   | Unleash Proxy を起動するために必要ですが、GitLab への接続には使用されません。任意の値に設定できます。 |

Unleash Proxy を使用する場合、各プロキシインスタンスは`UNLEASH_APP_NAME`で指定された環境のフラグのみをリクエストできるという制限があります。プロキシはクライアントの代わりにこれを GitLab に送信します。つまり、クライアントはこれを上書きできません。

## 機能フラグ関連のイシュー

{{< details >}}

- プラン:Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

関連するイシューを機能フラグにリンクできます。機能フラグの**「リンクされたイシュー」**セクションで、`+`ボタンを選択し、イシューの参照番号またはイシューの完全な URL を入力します。すると、イシューが関連する機能フラグに表示され、その逆も同様です。

この機能は、[リンクされたイシュー](../user/project/issues/related_issues.md)機能に似ています。

## パフォーマンス要因

GitLab 機能フラグは、あらゆるアプリケーションで使用できます。大規模なアプリケーションでは、高度な設定が必要になる場合があります。このセクションでは、機能を使用する前に組織が行う必要のあることを特定するのに役立つパフォーマンス要因について説明します。詳細に入る前に、[仕組み](#how-it-works)セクションをお読みください。

### アプリケーションノードでサポートされるクライアントの最大数

GitLab は、[レート制限](../security/rate_limits.md)に達するまで、可能な限り多くのクライアントリクエストを受け入れます。機能フラグ API は、**認証されていないトラフィック（特定の IP アドレスから）**と見なされます。GitLab.com については、[GitLab.com 固有の制限](../user/gitlab_com/_index.md)を参照してください。

ポーリングレートは SDK で設定可能です。すべてのクライアントが同じ IP からリクエストしていると仮定すると:

- 1分あたり1回リクエスト...500のクライアントをサポートできます。
- 15秒あたり1回リクエスト...125のクライアントをサポートできます。

よりスケーラブルなソリューションをお探しのアプリケーションの場合は、[Unleash Proxy](#unleash-proxy-example)を使用する必要があります。GitLab.com では、エンドポイント全体でレート制限される可能性を減らすために、Unleash Proxy を使用する必要があります。このプロキシサーバーは、サーバーとクライアントの間にあります。クライアントグループの代わりにサーバーにリクエストを行うため、送信リクエストの数を大幅に削減できます。それでも `429` の応答が得られる場合は、Unleash Proxy で `UNLEASH_FETCH_INTERVAL` の値を大きくしてください。

現在のレート制限により多くのキャパシティを与える[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/295472)もあります。

### ネットワークエラーからの回復

一般に、[Unleash クライアント](https://github.com/Unleash/unleash#unleash-sdks)には、サーバーがエラーコードを返したときのフォールバックメカニズムがあります。たとえば、`unleash-ruby-client` は、アプリケーションが現在の状態で実行し続けることができるように、ローカルバックアップからフラグデータを読み取ります。

詳細については、SDK プロジェクトのドキュメントをお読みください。

### GitLab Self-Managed

機能性に関しては、違いはありません。GitLab.com と GitLab Self-Managed はどちらも同じように動作します。

スケーラビリティに関しては、GitLab インスタンスのスペック次第です。たとえば、GitLab.com は HA アーキテクチャを使用しているため、多くの同時リクエストを処理できます。ただし、性能の低いマシン上の GitLab Self-Managed インスタンスでは、同等のパフォーマンスは得られません。詳細については、[リファレンスアーキテクチャー](../administration/reference_architectures/_index.md)を参照してください。
