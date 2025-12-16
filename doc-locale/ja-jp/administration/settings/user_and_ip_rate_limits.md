---
stage: Production Engineering
group: Networking and Incident Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザーとIPレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

レート制限は、Webアプリケーションのセキュリティと耐久性を向上させるためによく使用される手法です。詳細については、[レート制限](../../security/rate_limits.md)を参照してください。

以下の制限はデフォルトで無効になっています:

- [認証されていないAPIリクエスト（IPごと）](#enable-unauthenticated-api-request-rate-limit)。
- [認証されていないWebリクエスト（IPごと）](#enable-unauthenticated-web-request-rate-limit)。
- [認証されたAPIリクエスト（ユーザーごと）](#enable-authenticated-api-request-rate-limit)。
- [認証されたWebリクエスト（ユーザーごと）](#enable-authenticated-web-request-rate-limit)。

{{< alert type="note" >}}

デフォルトでは、すべてのGit操作は最初に認証なしで試行されます。このため、HTTP Git操作は、認証されていないリクエストに対して構成されたレート制限をトリガーする可能性があります。

{{< /alert >}}

{{< alert type="note" >}}

APIリクエストのレート制限は、フロントエンドからのリクエストには影響しません。これらは常にWebトラフィックとしてカウントされるためです。{{< /alert >}}

## 認証されていないAPIリクエストレート制限を有効にする {#enable-unauthenticated-api-request-rate-limit}

認証されていないAPIリクエストレート制限を有効にするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **ユーザーとIPレートの制限**とIPレート制限を展開します。
1. **認証されていないAPIリクエストレート制限を有効にする**を選択します。

   - オプション。**IPあたりのレート制限期間あたりの最大未認証APIリクエスト数**の値を更新します。`3600`がデフォルトです。
   - オプション。**Unauthenticated rate limit period in seconds**（認証されていないレート制限期間 (秒)）の値を更新します。`3600`がデフォルトです。

## 未認証のウェブリクエストレート制限を有効にする {#enable-unauthenticated-web-request-rate-limit}

認証されていないリクエストレート制限を有効にするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **ユーザーとIPレートの制限**とIPレート制限を展開します。
1. **未認証のウェブリクエストレート制限**を選択します。

   - オプション。**IPあたりのレート制限期間あたりの最大未認証webリクエスト数**の値を更新します。`3600`がデフォルトです。
   - オプション。**Unauthenticated rate limit period in seconds**（認証されていないレート制限期間 (秒)）の値を更新します。`3600`がデフォルトです。

## 認証されたAPIリクエストレート制限を有効にする {#enable-authenticated-api-request-rate-limit}

認証されたAPIリクエストレート制限を有効にするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **ユーザーとIPレートの制限**とIPレート制限を展開します。
1. **認証されたAPIリクエストのレート制限を有効にする**を選択します。

   - オプション。**ユーザーあたりのレート制限期間あたりの最大認証API要求数**の値を更新します。`7200`がデフォルトです。
   - オプション。**認証されたAPIレート制限期間(秒単位)**の値を更新します。`3600`がデフォルトです。

## 認証されたWebリクエストレート制限を有効にする {#enable-authenticated-web-request-rate-limit}

認証されたリクエストレート制限を有効にするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **ユーザーとIPレートの制限**とIPレート制限を展開します。
1. **認証されたAPIリクエストレート制限を有効にする**を選択します。

   - オプション。**ユーザーあたりのレート制限期間あたりの最大認証されたウェブリクエスト数**の値を更新します。`7200`がデフォルトです。
   - オプション。**認証されたWebレート制限期間(秒単位)**の値を更新します。`3600`がデフォルトです。

## カスタムレート制限レスポンスを使用する {#use-a-custom-rate-limit-response}

レート制限を超過するリクエストは、`429`レスポンスコードとプレーンテキストの本文を返します。これはデフォルトでは`Retry later`です。

カスタムレスポンスを使用するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **ユーザーとIPレートの制限**とIPレート制限を展開します。
1. **レート制限に達したクライアントに送信するプレーンテキストの応答。**テキストボックスに、プレーンテキストの応答メッセージを追加します。

## 1分あたりの`project/:id/jobs`への最大認証済みリクエスト {#maximum-authenticated-requests-to-projectidjobs-per-minute}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129319)されました。

{{< /history >}}

タイムアウトを減らすために、`project/:id/jobs`エンドポイントには、認証済みユーザーあたり600呼び出しのデフォルトの[レート制限](../../security/rate_limits.md#project-jobs-api-endpoint)があります。

リクエストの最大数を変更するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **ユーザーとIPレートの制限**とIPレート制限を展開します。
1. **`project/:id/jobs`への1分あたりの最大認証リクエスト数**の値を更新します。

## レスポンスヘッダー {#response-headers}

クライアントが関連付けられているレート制限を超えると、次のリクエストはブロックされます。サーバーは、リクエスタが特定の期間後に再試行できるように、レート制限情報で応答する場合があります。これらの情報は、レスポンスヘッダーに添付されます。

| ヘッダー                | 例                         | 説明                                                                                                                                                                                                      |
|:----------------------|:--------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `RateLimit-Limit`     | `60`                            | 毎分クライアントのリクエストクォータ。**管理者**エリアで設定されたレート制限期間が1分と異なる場合、このヘッダーの値は、最も近い60分の期間におおよそ調整されます。 |
| `RateLimit-Name`      | `throttle_authenticated_web`    | リクエストをブロックするトリガーの名前。                                                                                                                                                                      |
| `RateLimit-Observed`  | `67`                            | 時間枠内のクライアントに関連付けられたリクエストの数。                                                                                                                                                  |
| `RateLimit-Remaining` | `0`                             | 時間枠内の残りのクォータ。`RateLimit-Limit`の結果から`RateLimit-Observed`を引いた値です。                                                                                                                     |
| `RateLimit-Reset`     | `1609844400`                    | [Unix時間](https://en.wikipedia.org/wiki/Unix_time)形式で、リクエストクォータがリセットされる時間。                                                                                                             |
| `RateLimit-ResetTime` | `Tue, 05 Jan 2021 11:00:00 GMT` | [RFC2616](https://www.rfc-editor.org/rfc/rfc2616#section-3.3.1)形式で、リクエストクォータがリセットされる日時。                                                                                            |
| `Retry-After`         | `30`                            | クォータがリセットされるまでの残り時間（秒）。これは、[標準HTTPヘッダー](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After)です。                                             |

## HTTPヘッダーを使用してレート制限を回避する {#use-an-http-header-to-bypass-rate-limiting}

組織のニーズによっては、レート制限を有効にしても、一部のリクエストがレート制限を回避するようにすることがあります。

カスタムヘッダーを使用して、レート制限を回避するリクエストをマークすることで、これを行うことができます。これは、GitLabの前のロードバランサーまたはリバースプロキシ内のどこかで行う必要があります。例: 

1. 回避ヘッダーの名前を選択します。たとえば`Gitlab-Bypass-Rate-Limiting`などです。
1. GitLabレート制限を回避する必要があるリクエストで`Gitlab-Bypass-Rate-Limiting: 1`を設定するようにロードバランサーを設定します。
1. ロードバランサーを次のいずれかに設定します:
   - `Gitlab-Bypass-Rate-Limiting`を消去します。
   - レート制限の影響を受けるすべてのリクエストで、`Gitlab-Bypass-Rate-Limiting`を`1`以外の値に設定します。
1. `GITLAB_THROTTLE_BYPASS_HEADER`という環境変数を設定します。
   - [Linuxパッケージ](https://docs.gitlab.com/omnibus/settings/environment-variables.html)を使用しているセルフコンパイルインストールの場合は、`'GITLAB_THROTTLE_BYPASS_HEADER' => 'Gitlab-Bypass-Rate-Limiting'`を`gitlab_rails['env']`に設定します。
   - セルフコンパイルインストールの場合は、`export GITLAB_THROTTLE_BYPASS_HEADER=Gitlab-Bypass-Rate-Limiting`を`/etc/default/gitlab`に設定します。

ロードバランサーが、すべての受信トラフィックの回避ヘッダーを消去または上書きすることが重要です。そうしないと、ユーザーがそのヘッダーを設定せず、GitLabのレート制限を回避しないことを信頼する必要があります。

回避は、ヘッダーが`1`に設定されている場合にのみ機能します。

回避ヘッダーが原因でレート制限を回避したリクエストは、[`production_json.log`](../logs/_index.md#production_jsonlog)で`"throttle_safelist":"throttle_bypass_header"`でマークされます。

回避メカニズムを無効にするには、環境変数`GITLAB_THROTTLE_BYPASS_HEADER`が設定されていないか、空であることを確認してください。

## 特定のユーザーが認証されたリクエストレート制限を回避できるようにする {#allow-specific-users-to-bypass-authenticated-request-rate-limiting}

前に説明した回避ヘッダーと同様に、特定のユーザーセットがレート制限を回避できるようにすることができます。これは認証されたリクエストにのみ適用されます。認証されていないリクエストでは、定義上、GitLabはユーザーが誰であるかを知りません。

許可リストは、環境変数`GITLAB_THROTTLE_USER_ALLOWLIST`のコンマ区切りのユーザーIDのリストとして設定されます。ユーザー1、53、217が認証されたリクエストレート制限を回避できるようにする場合、許可リストの設定は`1,53,217`になります。

- [Linuxパッケージ](https://docs.gitlab.com/omnibus/settings/environment-variables.html)を使用しているセルフコンパイルインストールの場合は、`'GITLAB_THROTTLE_USER_ALLOWLIST' => '1,53,217'`を`gitlab_rails['env']`に設定します。
- セルフコンパイルインストールの場合は、`export GITLAB_THROTTLE_USER_ALLOWLIST=1,53,217`を`/etc/default/gitlab`に設定します。

ユーザー許可リストが原因でレート制限を回避したリクエストは、[`production_json.log`](../logs/_index.md#production_jsonlog)で`"throttle_safelist":"throttle_user_allowlist"`でマークされます。

アプリケーションの起動時に、許可リストは[`auth.log`](../logs/_index.md#authlog)にログメッセージが記録されます。

## スロットル設定を適用する前に試してみる {#try-out-throttling-settings-before-enforcing-them}

`GITLAB_THROTTLE_DRY_RUN`環境変数をスロットル名のコンマ区切りリストに設定して、スロットル設定を試すことができます。

可能な名前は次のとおりです:

- `throttle_unauthenticated`
  - GitLab 14.3で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/335300)になりました。代わりに`throttle_unauthenticated_api`または`throttle_unauthenticated_web`を使用してください。`throttle_unauthenticated`は引き続きサポートされており、両方を選択します。
- `throttle_unauthenticated_api`
- `throttle_unauthenticated_web`
- `throttle_authenticated_api`
- `throttle_authenticated_web`
- `throttle_unauthenticated_protected_paths`
- `throttle_authenticated_protected_paths_api`
- `throttle_authenticated_protected_paths_web`
- `throttle_unauthenticated_packages_api`
- `throttle_authenticated_packages_api`
- `throttle_authenticated_git_lfs`
- `throttle_unauthenticated_files_api`
- `throttle_authenticated_files_api`
- `throttle_unauthenticated_deprecated_api`
- `throttle_authenticated_deprecated_api`

たとえば、保護されていないパスへのすべての認証済みリクエストに対してスロットルを試すには、`GITLAB_THROTTLE_DRY_RUN='throttle_authenticated_web,throttle_authenticated_api'`を設定して実行できます。

すべてのスロットルのドライランモードを有効にするには、変数を`*`に設定します。

スロットルをドライランモードに設定すると、制限に達した場合に、[`auth.log`](../logs/_index.md#authlog)にメッセージがログメッセージ記録され、リクエストは続行されます。ログメッセージには、`env`フィールドに`track`が設定されたenvが含まれています。`matched`フィールドには、ヒットしたスロットルの名前が含まれています。

設定でレート制限を有効にする前に、環境変数を設定することが重要です。**管理者**エリアの設定はすぐに有効になりますが、環境変数を設定するには、すべてのPumaプロセスを再起動する必要があります。

## トラブルシューティング {#troubleshooting}

### 管理者が誤ってブロックされた後、スロットルを無効にする {#disable-throttling-after-accidentally-locking-administrators-out}

多数のユーザーが同じプロキシまたはネットワークゲートウェイを介してGitLabに接続する場合、レート制限が低すぎると、スロットルをトリガーしたリクエストと同じIPを使用しているとGitLabが認識するため、その制限によって管理者もブロックされる可能性があります。

管理者は、[Railsコンソール](../operations/rails_console.md)を使用して、[`GITLAB_THROTTLE_DRY_RUN`変数](#try-out-throttling-settings-before-enforcing-them)にリストされているものと同じ制限を無効にすることができます。例: 

```ruby
Gitlab::CurrentSettings.update!(throttle_authenticated_web_enabled: false)
```

この例では、`throttle_authenticated_web`パラメータには`_enabled`という名前のサフィックスが付いています。

制限の数値を設定するには、`_enabled`という名前のサフィックスを`_period_in_seconds`および`_requests_per_period`というサフィックスに置き換えます。
