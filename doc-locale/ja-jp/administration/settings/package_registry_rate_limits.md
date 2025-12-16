---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: パッケージレジストリレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[GitLabパッケージレジストリ](../../user/packages/package_registry/_index.md)を使用すると、幅広い一般的なパッケージマネージャー向けに、プライベートレジストリまたはパブリックレジストリとしてGitLabを使用できます。パッケージを公開および共有すると、他のユーザーは[パッケージAPI](../../api/packages.md)を介してダウンストリームプロジェクトで依存関係として利用できます。

ダウンストリームプロジェクトがそのような依存関係を頻繁にダウンロードする場合、多くのリクエストがパッケージAPIを介して行われます。したがって、強制された[user and IP rate limits](user_and_ip_rate_limits.md)に達する可能性があります。この問題に対処するために、パッケージAPIに特定のレート制限を定義できます:

- [認証されていないリクエスト（IPごと）](#enable-unauthenticated-request-rate-limit-for-packages-api)。
- [認証済みAPIリクエスト（ユーザーごと）](#enable-authenticated-api-request-rate-limit-for-packages-api)。

これらの制限はデフォルトで無効になっています。

有効にすると、パッケージAPIへのリクエストに対する一般的なユーザーおよびIPレート制限よりも優先されます。したがって、一般的なユーザーおよびIPレート制限を維持し、パッケージAPIのレート制限を増やすことができます。この優先順位に加えて、一般的なユーザーおよびIPレート制限と比較して機能に違いはありません。

## パッケージAPIの認証されていないリクエストレート制限を有効にする {#enable-unauthenticated-request-rate-limit-for-packages-api}

認証されていないリクエストレート制限を有効にするには、次の手順を実行します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **ネットワーク**を選択します。
1. **パッケージレジストリレート制限**を展開します。
1. **Enable unauthenticated request rate limit**（認証されていないリクエストレート制限を有効にする）を選択します。

   - オプション。**Maximum unauthenticated requests per rate limit period per IP**（IPごとのレート制限期間あたりの認証されていない最大リクエスト数）の値を更新します。`800`がデフォルトです。
   - オプション。**Unauthenticated rate limit period in seconds**（認証されていないレート制限期間（秒））の値を更新します。`15`がデフォルトです。

## パッケージAPIの認証されたAPIリクエストレート制限を有効にする {#enable-authenticated-api-request-rate-limit-for-packages-api}

認証されたAPIリクエストレート制限を有効にするには、次の手順を実行します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します
1. **パッケージレジストリレート制限**を展開します。
1. **認証されたAPIリクエストのレート制限を有効にする**を選択します。

   - オプション。**ユーザーあたりのレート制限期間あたりの最大認証API要求数**の値を更新します。`1000`がデフォルトです。
   - オプション。**認証されたAPIレート制限期間(秒単位)**の値を更新します。`15`がデフォルトです。
