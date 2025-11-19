---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Git HTTPリクエストに対するレート制限をGitLab Self-Managedで構成します。
title: Git HTTPのレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147112)されました。

{{< /history >}}

リポジトリでGit HTTPを使用している場合、一般的なGit操作で多数のGit HTTPリクエストが生成される可能性があります。GitLabは、認証されたGit HTTPリクエストと認証されていないGit HTTPリクエストの両方に対してレート制限を適用し、Webアプリケーションのセキュリティと耐久性を向上させることができます。

{{< alert type="note" >}}

[一般ユーザーおよびIPレート制限](user_and_ip_rate_limits.md)は、Git HTTPリクエストには適用されません。

{{< /alert >}}

## 認証されていないGit HTTPレート制限を構成する {#configure-unauthenticated-git-http-rate-limits}

GitLabは、デフォルトでは、認証されていないGit HTTPリクエストに対するレート制限を無効にします。

認証認証パラメータを含まないGit HTTPリクエストにレート制限を適用するには、これらの制限を有効にして構成します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **ネットワーク**を選択します。
1. **Git HTTPレート制限**を展開します。
1. **認証されていないGit HTTPリクエストのレート制限を有効にする**を選択します。
1. **Max unauthenticated Git HTTP requests per period per user**（期間ごとのユーザーあたりの認証されていないGit HTTPリクエストの最大数）の値を入力します。
1. **認証されていないGit HTTPレート制限期間(秒単位)**の値を入力します。
1. **変更を保存**を選択します。

## 認証済みのGit HTTPレート制限を構成する {#configure-authenticated-git-http-rate-limits}

{{< history >}}

- 認証済みのGit HTTPレート制限は、`git_authenticated_http_limit`という名前の[フラグ付き](../../administration/feature_flags/_index.md)でGitLab 18.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191552)。デフォルトでは無効になっています。
- [GitLab.com、GitLab Self-Managed、およびGitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/543768)でGitLab 18.3で有効になりました。
- GitLab 18.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/561577)になりました。機能フラグ`git_authenticated_http_limit`は削除されました。

{{< /history >}}

GitLabは、デフォルトでは、認証されたGit HTTPリクエストに対するレート制限を無効にします。

認証パラメータを含むGit HTTPリクエストにレート制限を適用するには、これらの制限を有効にして構成します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **ネットワーク**を選択します。
1. **Git HTTPレート制限**を展開します。
1. **Enable authenticated Git HTTP request rate limit**（認証されたGit HTTPリクエストのレート制限を有効にする）を選択します。
1. **Max authenticated Git HTTP requests per period per user**（期間ごとのユーザーあたりの認証されたGit HTTPリクエストの最大数）の値を入力します。
1. **認証されているGit HTTPレート制限期間(秒単位)**の値を入力します。
1. **変更を保存**を選択します。

必要に応じて、[特定のユーザーに認証されたリクエストのレート制限の回避を許可する](user_and_ip_rate_limits.md#allow-specific-users-to-bypass-authenticated-request-rate-limiting)ことができます。

## 関連トピック {#related-topics}

- [レート制限](../../security/rate_limits.md)
- [ユーザーとIPのレート制限](user_and_ip_rate_limits.md)
