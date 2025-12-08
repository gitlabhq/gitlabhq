---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabアプリケーションのカスタム機能フラグを作成して維持します。
title: 機能フラグ
description: 段階的デリバリー、制御されたデプロイ、リスク軽。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

機能フラグを使用すると、アプリケーションの新しい機能をより小さなバッチで本番環境にデプロイできます。機能をオンまたはオフにして、ユーザーのサブセットを切り替えることで、継続的デリバリーを実現できます。機能フラグは、リスクを軽減し、制御されたテストを実行し、機能の提供を顧客のローンチから分離するのに役立ちます。

GitLabの[機能フラグの完全なリスト](../administration/feature_flags/list.md)も利用できます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>機能フラグの実際の動作例については、[機能フラグによるリスクの排除](https://www.youtube.com/watch?v=U9WqoK9froI)を参照してください。
<!-- Video published on 2024-02-01 -->

クリックスルーデモについては、[機能フラグ](https://tech-marketing.gitlab.io/static-demos/feature-flags/feature-flags-html.html)を参照してください。
<!-- Demo published on 2023-07-13 -->

## 機能フラグを使用する {#using-feature-flags}

GitLabは、機能フラグ用の[Unleash](https://github.com/Unleash/unleash)互換APIを提供します。

GitLabでフラグを有効または無効にすると、アプリケーションは有効または無効にする機能を判断できます。

GitLabで機能フラグを作成し、アプリケーションからAPIを使用して、機能フラグとそのステータスのリストを取得できます。アプリケーションはGitLabと通信するように設定する必要があるため、互換性のあるクライアントライブラリを使用し、[機能フラグをアプリに統合する](#integrate-feature-flags-with-your-application)のはデベロッパー次第です。

## 機能フラグを作成する {#create-a-feature-flag}

機能フラグを作成して有効にするには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **デプロイ** > **機能フラグ**を選択します。
1. **新しい機能フラグ**を選択します。
1. 文字で始まり、小文字、数字、アンダースコア（`_`）またはダッシュ（`-`）のみを含み、ダッシュ（`-`）またはアンダースコア（`_`）で終わらない名前を入力します。
1. オプション。説明を入力します（最大255文字）。
1. フラグの適用方法を定義するには、機能フラグ[**戦略**](#feature-flag-strategies)を追加します。各ストラテジについて、**種類**（デフォルトは[**すべてのユーザー**](#all-users)）と**環境**を含めます。
1. **機能フラグを作成**を選択します。

これらの設定を変更するには、リスト内の任意の機能フラグの横にある**編集**（{{< icon name="pencil" >}}）を選択します。

## 機能フラグの最大数 {#maximum-number-of-feature-flags}

GitLab Self-Managedのプロジェクトごとの機能フラグの最大数は200です。GitLab.comの場合、最大数は[プラン](https://about.gitlab.com/pricing/)によって決まります: 

| プラン     | プロジェクトごとの機能フラグ（GitLab.com） | プロジェクトごとの機能フラグ（GitLab Self-Managed） |
|----------|----------------------------------|------------------------------------------|
| Free     | 50                               | 200                                      |
| Premium  | 150                              | 200                                      |
| Ultimate | 200                              | 200                                      |

## 機能フラグのストラテジ {#feature-flag-strategies}

ストラテジを複数回定義しなくても、複数環境に機能フラグのストラテジを適用できます。

GitLabの機能フラグは[Unleash](https://docs.getunleash.io/)に基づいています。Unleashには、きめ細かい機能フラグ制御のための[ストラテジ](https://docs.getunleash.io/reference/activation-strategies)があります。GitLabの機能フラグには複数のストラテジを設定でき、サポートされているストラテジは次のとおりです:

- [すべてのユーザー](#all-users)
- [ユーザーの割合](#percent-of-users)
- [ユーザーID](#user-ids)
- [ユーザーリスト](#user-list)

戦略は、[機能フラグの作成](#create-a-feature-flag)時、または**デプロイ** > **機能フラグ**に移動し、**編集** ({{< icon name="pencil" >}}) を選択して、作成後に既存の機能フラグを編集することで、機能フラグに追加できます。

### すべてのユーザー {#all-users}

すべてのユーザーに対して機能を有効にします。標準（`default`）Unleashアクティベーション[ストラテジ](https://docs.getunleash.io/reference/activation-strategies#standard)を使用します。

### ロールアウト率 {#percent-rollout}

動作の一貫性を設定可能にして、ページビューの割合に対して機能を有効にします。この一貫性は、スティッキー性とも呼ばれます。Gradual Rollout（`flexibleRollout`）Unleashアクティベーション[ストラテジ](https://docs.getunleash.io/reference/activation-strategies#gradual-rollout)を使用します。

一貫性は、以下に基づいて設定できます: 

- **ユーザーID**: 各ユーザーIDは、セッションIDを無視して、一貫した動作をします。
- **Session IDs**（セッションID）: 各セッションIDは、ユーザーIDを無視して、一貫した動作をします。
- **ランダム**: 一貫した動作は保証されません。機能は、ページビューの選択された割合に対してランダムに有効になります。ユーザーIDとセッションIDは無視されます。
- **利用可能なID**: ユーザーの状態に基づいて一貫した動作が試みられます: 
  - ユーザーがログインしている場合、ユーザーIDに基づいて動作を一貫させます。
  - ユーザーが匿名の場合、セッションIDに基づいて動作を一貫させます。
  - ユーザーIDまたはセッションIDがない場合、機能はページビューの選択された割合に対してランダムに有効になります。

たとえば、**利用可能なID**に基づいて15%の値を設定して、ページビューの15%に対して機能を有効にします。認証済みユーザーの場合、これはユーザーIDに基づいています。セッションIDを持つ匿名のユーザーの場合、ユーザーIDがないため、代わりにセッションIDに基づいています。次に、セッションIDが提供されていない場合は、ランダムに戻ります。

ロールアウト率は0%から100%です。

ユーザーIDに基づいて一貫性のある[ロールアウト率](#percent-of-users)は、同じ動作をします。

{{< alert type="warning" >}}

**ランダム**を選択すると、個々のユーザーに対して一貫性のないアプリケーションの動作が提供されます。

{{< /alert >}}

### ユーザーの割合 {#percent-of-users}

認証済みユーザーの割合に対して機能を有効にします。Unleashアクティベーションストラテジ[`gradualRolloutUserId`](https://docs.getunleash.io/reference/activation-strategies#gradual-rollout)を使用します。

たとえば、15%の値を設定して、認証済みユーザーの15%に対して機能を有効にします。

ロールアウト率は0%から100%です。

スティッキー性（同じユーザーに対して一貫したアプリケーションの動作）は、認証済みユーザーには保証されますが、匿名ユーザーには保証されません。

**ユーザーID**に基づいて一貫性のある[ロールアウト率](#percent-rollout)は、同じ動作をします。ユーザーの割合よりもロールアウト率の方が柔軟性があるため、ロールアウト率を使用することをお勧めします。

{{< alert type="warning" >}}

ユーザーの割合ストラテジを選択した場合、機能を有効にするには、UnleashクライアントにユーザーIDを**must**（指定する）必要があります。以下の[Rubyの例](#ruby-application-example)を参照してください。

{{< /alert >}}

### ユーザーID {#user-ids}

ターゲットユーザーのリストに対して機能を有効にします。Unleash UsersIDs（`userWithId`）アクティベーション[ストラテジ](https://docs.getunleash.io/reference/activation-strategies#userids)を使用して実装されます。

ユーザーIDを、コンマ区切りの値のリストとして入力します（例: `user@example.com, user2@example.com`、または`username1,username2,username3`など）。ユーザーIDは、アプリケーションユーザーの識別子です。GitLabユーザーである必要はありません。

{{< alert type="warning" >}}

ターゲットユーザーに対して機能を有効にするには、UnleashクライアントにユーザーIDを**must**（指定する）必要があります。以下の[Rubyの例](#ruby-application-example)を参照してください。

{{< /alert >}}

### ユーザーリスト {#user-list}

[機能フラグUI](#create-a-user-list)で作成されたユーザーのリスト、または[機能フラグユーザーリストAPI](../api/feature_flag_user_lists.md)で作成されたユーザーのリストに対して機能を有効にします。[ユーザーID](#user-ids)と同様に、Unleash UsersIDs（`userWithId`）アクティベーション[ストラテジ](https://docs.getunleash.io/reference/activation-strategies#userids)を使用します。

特定のユーザーに対して特定の機能を無効にすることはできませんが、ユーザーリストに対して機能を有効にすることで、同様の結果を得ることができます。

例:

- `Full-user-list` = `User1A, User1B, User2A, User2B, User3A, User3B, ...`
- `Full-user-list-excluding-B-users` = `User1A, User2A, User3A, ...`

#### ユーザーリストを作成 {#create-a-user-list}

ユーザーリストを作成するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **デプロイ** > **機能フラグ**を選択します。
1. **ユーザーリストを表示**を選択します
1. **新しいユーザーリスト**を選択します。
1. リストの名前を入力します。
1. **作成**を選択します。

リストを表示するには、横にある**編集**（{{< icon name="pencil" >}}）を選択して、ユーザーIDを表示できます。リストを表示している場合は、**編集**（{{< icon name="pencil" >}}）を選択して名前を変更できます。

#### ユーザーをユーザーリストに追加する {#add-users-to-a-user-list}

ユーザーをユーザーリストに追加するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **デプロイ** > **機能フラグ**を選択します。
1. ユーザーを追加するリストの横にある**編集**（{{< icon name="pencil" >}}）を選択します。
1. **ユーザーを追加**を選択します。
1. ユーザーIDを、コンマ区切りの値のリストとして入力します。たとえば、`user@example.com, user2@example.com`、または`username1,username2,username3`などです。
1. **追加**を選択します。

#### ユーザーをユーザーリストから削除する {#remove-users-from-a-user-list}

ユーザーをユーザーリストから削除するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **デプロイ** > **機能フラグ**を選択します。
1. 変更するリストの横にある**編集**（{{< icon name="pencil" >}}）を選択します。
1. 削除するIDの横にある**削除**（{{< icon name="remove" >}}）を選択します。

## コード参照を検索する {#search-for-code-references}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

クリーンアップ中にコードから機能フラグを削除するには、それに対するプロジェクト参照を見つけます。

機能フラグのコード参照を検索するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **デプロイ** > **機能フラグ**を選択します。
1. 削除する機能フラグを編集します。
1. **追加のアクション**（{{< icon name="ellipsis_v" >}}）を選択します。
1. **コードの参照を検索する**を選択します。

## 特定の環境の機能フラグを無効にする {#disable-a-feature-flag-for-a-specific-environment}

特定の環境の機能フラグを無効にするには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **デプロイ** > **機能フラグ**を選択します。
1. 無効にする機能フラグについて、**編集**（{{< icon name="pencil" >}}）を選択します。
1. フラグを無効にするには: 
   - 適用される各ストラテジについて、**環境**の下で、環境を削除します。
1. **変更を保存**を選択します。

## すべての環境の機能フラグを無効にする {#disable-a-feature-flag-for-all-environments}

すべての環境の機能フラグを無効にするには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **デプロイ** > **機能フラグ**を選択します。
1. 無効にする機能フラグについて、ステータスの切替を**無効**にスライドさせます。

機能フラグは、**無効**タブに表示されます。

## 機能フラグをアプリケーションと統合する {#integrate-feature-flags-with-your-application}

アプリケーションで機能フラグを使用するには、GitLabからアクセス認証情報を取得します。次に、クライアントライブラリを使用してアプリケーションを準備します。

### アクセス認証情報を取得する {#get-access-credentials}

アプリケーションがGitLabと通信するために必要なアクセス認証情報を取得するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **デプロイ** > **機能フラグ**を選択します。
1. **設定する**を選択して、以下を表示します: 
   - **API URL**: クライアント（アプリケーション）が機能フラグのリストを取得するために接続するURL。
   - **インスタンスID**: 機能フラグの取得を承認する一意のトークン。
   - **Application name**（アプリケーション名）: アプリケーションが実行される環境の名前（アプリケーション自体の名前ではありません）。

     たとえば、アプリケーションが本番環境サーバーで実行されている場合、**Application name**（アプリケーション名）は`production`または同様のものになる可能性があります。この値は、環境仕様の評価に使用されます。

これらのフィールドの意味は、時間の経過とともに変わる可能性があります。たとえば、**インスタンスID**は、単一のトークンまたは**環境**に割り当てられた複数のトークンである可能性があります。また、**Application name**（アプリケーション名）は、実行環境ではなくアプリケーションのバージョンを記述している可能性があります。

### クライアントライブラリを選択する {#choose-a-client-library}

GitLabは、Unleashクライアントと互換性のある単一のバックエンドを実装します。

Unleashクライアントを使用すると、デベロッパーはアプリケーションコードで、フラグのデフォルト値を定義できます。各機能フラグの評価では、提供された設定ファイルにフラグが存在しない場合に、目的の結果を表現できます。

Unleashは現在、[さまざまな言語とフレームワーク用の多くのSDKを提供しています](https://github.com/Unleash/unleash#unleash-sdks)。

### 機能フラグAPI情報 {#feature-flags-api-information}

APIコンテンツについては、以下を参照してください: 

- [機能フラグAPI](../api/feature_flags.md)
- [機能フラグユーザーリストAPI](../api/feature_flag_user_lists.md)

### Goアプリケーションの例 {#go-application-example}

Goアプリケーションに機能フラグを統合する方法の例を次に示します: 

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

### Rubyアプリケーションの例 {#ruby-application-example}

Rubyアプリケーションに機能フラグを統合する方法の例を次に示します。

Unleashクライアントには、**Percent rollout (logged in users)**（ロールアウト率（パーセントロールアウト、ログインユーザー））または**Target Users**（ターゲットユーザー）のリストで使用するためのユーザーIDが与えられます。

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
# The context's user ID must be a string:
# https://unleash.github.io/docs/unleash_context
unleash_context.user_id = "123"

if unleash.is_enabled?("my_feature_name", unleash_context)
  puts "Feature enabled"
else
  puts "hello, world!"
end
```

### Unleash Proxyの例 {#unleash-proxy-example}

[Unleash Proxy](https://docs.getunleash.io/reference/unleash-proxy)バージョン0.2以降、プロキシは機能フラグと互換性があります。

GitLab.comの本番環境ではUnleash Proxyを使用する必要があります。詳細については、[パフォーマンスに関する注意](#maximum-supported-clients-in-application-nodes)を参照してください。

プロジェクトの機能フラグに接続するためのDockerコンテナを実行するには、次のコマンドを実行します: 

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
| `UNLEASH_PROXY_SECRETS`      | [Unleash Proxyクライアント](https://docs.getunleash.io/reference/unleash-proxy#how-to-connect-to-the-proxy)を設定するために使用される共有シークレット。 |
| `UNLEASH_URL`         | プロジェクトのAPI URL。詳細については、[アクセス認証情報を取得する](#get-access-credentials)をお読みください。 |
| `UNLEASH_INSTANCE_ID` | プロジェクトのインスタンスID。詳細については、[アクセス認証情報を取得する](#get-access-credentials)をお読みください。 |
| `UNLEASH_APP_NAME`    | アプリケーションが実行される環境の名前。詳細については、[アクセス認証情報を取得する](#get-access-credentials)をお読みください。 |
| `UNLEASH_API_TOKEN`   | Unleash Proxyを起動するために必要ですが、GitLabへの接続には使用されません。任意の値に設定できます。 |

Unleash Proxyを使用する場合、各プロキシインスタンスは`UNLEASH_APP_NAME`で指定された環境の機能フラグのみをリクエストできるという制限があります。プロキシはクライアントの代わりにこれをGitLabに送信します。つまり、クライアントはこれを上書きできません。

## 機能フラグ関連のイシュー {#feature-flag-related-issues}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

関連するイシューを機能フラグにリンクできます。機能フラグの**Linked issues**（リンクされたイシュー）セクションで、`+`ボタンを選択し、イシューの参照番号またはイシューの完全なURLをインプットします。すると、イシューが関連する機能フラグに表示され、その逆も同様です。

この機能は、[リンクされたイシュー](../user/project/issues/related_issues.md)機能に似ています。

## パフォーマンス要因 {#performance-factors}

GitLab機能フラグは、あらゆるアプリケーションで使用できます。大規模なアプリケーションでは、高度な設定が必要になる場合があります。このセクションでは、機能を使用する前に組織が行う必要のあることを特定するのに役立つパフォーマンス要因について説明します。詳しくは、[機能フラグを使用する](#using-feature-flags)をご覧ください。

### アプリケーションノードでサポートされるクライアントの最大数 {#maximum-supported-clients-in-application-nodes}

GitLabは、[レート制限](../security/rate_limits.md)に達するまで、可能な限り多くのクライアントリクエストを受け入れます。機能フラグAPIは、**Unauthenticated traffic (from a given IP address)**（認証されていないトラフィック（特定のIPアドレスから））と見なされます。GitLab.comについては、[GitLab.com](../user/gitlab_com/_index.md)固有の制限を参照してください。

ポーリングレートはSDKで設定可能です。すべてのクライアントが同じIPからリクエストしていると仮定すると: 

- 1分あたり1回リクエスト...500のクライアントをサポートできます。
- 15秒あたり1回リクエスト...125のクライアントをサポートできます。

よりスケーラビリティの高いソリューションをお探しのアプリケーションの場合は、[Unleash Proxy](#unleash-proxy-example)を使用する必要があります。GitLab.comでは、エンドポイント全体でレート制限される可能性を減らすために、Unleash Proxyを使用する必要があります。このプロキシサーバーは、サーバーとクライアントの間にあります。クライアントグループの代わりにサーバーにリクエストを行うため、送信リクエストの数を大幅に削減できます。それでも`429`の応答が得られる場合は、Unleash Proxyで`UNLEASH_FETCH_INTERVAL`の値を大きくしてください。

現在のレート制限により多くのキャパシティを与える[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/295472)もあります。

### ネットワーキングエラーからの回復 {#recovering-from-network-errors}

一般に、[Unleashクライアント](https://github.com/Unleash/unleash#unleash-sdks)には、サーバーがエラーコードを返したときのフォールバックメカニズムがあります。たとえば、`unleash-ruby-client`は、アプリケーションが現在の状態で実行し続けることができるように、ローカルバックアップから機能フラグデータを読み取ります。

詳細については、SDKプロジェクトのドキュメントをお読みください。

### GitLab Self-Managed {#gitlab-self-managed}

機能に関しては、違いはありません。GitLab.comとGitLab Self-Managedはどちらも同じように動作します。

スケーラビリティに関しては、GitLabインスタンスの仕様次第です。たとえば、GitLab.comはHAアーキテクチャを使用しているため、多くの同時リクエストを処理できます。ただし、性能の低いマシン上のGitLab Self-Managedインスタンスでは、同等のパフォーマンスは得られません。詳細については、[リファレンスアーキテクチャ](../administration/reference_architectures/_index.md)を参照してください。
