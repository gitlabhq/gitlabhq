---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: パッケージレジストリのレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[GitLabパッケージレジストリ](../../user/packages/package_registry/_index.md)を使用すると、さまざまな一般的なパッケージマネージャー向けにGitLabをプライベートまたはパブリックレジストリとして使用できます。パッケージを公開および共有でき、他のユーザーは[Packages API](../../api/packages.md)を介してダウンストリームプロジェクトの依存として利用できます。

ダウンストリームプロジェクトがそのような依存を頻繁にダウンロードする場合、Packages APIを介して多くのリクエストが行われます。そのため、強制された[ユーザーおよびIPレート制限](user_and_ip_rate_limits.md)に達する可能性があります。この問題を解決するために、Packages APIの特定のレート制限を定義できます:

- [認証されていないリクエスト（IPごと）](#enable-unauthenticated-request-rate-limit-for-packages-api)。
- [認証されたAPIリクエスト（ユーザーごと）](#enable-authenticated-api-request-rate-limit-for-packages-api)。

これらの制限はデフォルトで無効になっています。

有効にすると、Packages APIへのリクエストに対する一般的なユーザーおよびIPレート制限よりも優先されます。したがって、一般的なユーザーおよびIPレート制限を維持し、Packages APIのレート制限を増やすことができます。この優先順位の他にも、一般的なユーザーおよびIPレート制限と比較して機能に違いはありません。

## packages APIの認証されていないリクエストレート制限を有効にする {#enable-unauthenticated-request-rate-limit-for-packages-api}

前提条件: 

- 管理者アクセス権。

認証されていないリクエストレート制限を有効にするには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **ネットワーク**を選択します。
1. **パッケージレジストリレート制限**を展開する。
1. **Enable unauthenticated request rate limit**を選択します。

   - オプション。**Maximum unauthenticated requests per rate limit period per IP**の値を更新します。`800`がデフォルトです。
   - オプション。**Unauthenticated rate limit period in seconds**の値を更新します。`15`がデフォルトです。

## packages APIの認証されたAPIリクエストレート制限を有効にする {#enable-authenticated-api-request-rate-limit-for-packages-api}

前提条件: 

- 管理者アクセス権。

認証されたAPIリクエストレート制限を有効にするには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **パッケージレジストリレート制限**を展開する。
1. **認証されたAPIリクエストのレート制限を有効にする**を選択します。

   - オプション。**ユーザーあたりのレート制限期間あたりの最大認証API要求数**の値を更新します。`1000`がデフォルトです。
   - オプション。**認証されたAPIレート制限期間(秒単位)** の値を更新します。`15`がデフォルトです。
