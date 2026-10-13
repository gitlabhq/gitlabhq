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

[GitLabパッケージレジストリ](../../user/packages/package_registry/_index.md)を使用すると、GitLabを様々な一般的なパッケージマネージャーのプライベートまたはパブリックなレジストリとして利用できます。パッケージを公開共有でき、他のユーザーは[パッケージAPI](../../api/packages.md)を通じてダウンストリームプロジェクトの依存としてそれらを利用できます。

ダウンストリームプロジェクトがこのような依存を頻繁にダウンロードする場合、パッケージAPIを通じて多くのリクエストが行われます。そのため、適用されている[ユーザーおよびIPのレート制限](../../administration/settings/user_and_ip_rate_limits.md)に達する可能性があります。この問題に対処するため、パッケージAPIに固有のレート制限を定義できます:

- [認証されていないリクエスト（IPごと）](#enable-unauthenticated-request-rate-limit-for-packages-api)。
- [認証されたAPIリクエスト（ユーザーごと）](#enable-authenticated-api-request-rate-limit-for-packages-api)。

これらの制限はデフォルトで無効になっています。

有効にすると、パッケージAPIへのリクエストに対する一般的なユーザーおよびIPのレート制限を上書きします。そのため、一般的なユーザーおよびIPのレート制限を維持しつつ、パッケージAPIのレート制限を増やすことができます。この優先順位以外には、一般的なユーザーおよびIPのレート制限と比較して機能に違いはありません。

## パッケージAPIの未認証リクエストレート制限を有効にする {#enable-unauthenticated-request-rate-limit-for-packages-api}

前提条件: 

- 管理者アクセス権。

未認証リクエストのレート制限を有効にするには、次のようにします:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **パッケージレジストリレート制限**を展開します。
1. **未認証リクエストのレート制限を有効にする**を選択します。

   - オプション。**IPあたりのレート制限期間あたりの最大未認証リクエスト数**の値を更新します。`800`がデフォルトです。
   - オプション。**未認証のレート制限期間（秒）** の値を更新します。`15`がデフォルトです。

## パッケージAPIの認証済みAPIリクエストレート制限を有効にする {#enable-authenticated-api-request-rate-limit-for-packages-api}

前提条件: 

- 管理者アクセス権。

認証済みAPIリクエストのレート制限を有効にするには、次のようにします:

1. 右上隅で、**管理者**を選択します。
1. 左のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **パッケージレジストリレート制限**を展開します。
1. **認証されたAPIリクエストのレート制限を有効にする**を選択します。

   - オプション。**ユーザーあたりのレート制限期間あたりの最大認証API要求数**の値を更新します。`1000`がデフォルトです。
   - オプション。**認証されたAPIレート制限期間（秒単位）** の値を更新します。`15`がデフォルトです。
