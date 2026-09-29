---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: Git HTTP、Git LFS、およびGit SSH操作のレート制限を設定します。
title: Git操作レート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

クローン、フェッチ、プッシュといった一般的なGit操作は、短時間で多くのリクエストを生成する可能性があります。Git HTTP、Git LFS、Git SSH操作のレート制限は、GitLabインスタンスのセキュリティと耐久性を保護します。これらの各制限は、[一般的なユーザーとIPのレート制限](../administration/settings/user_and_ip_rate_limits.md)とは異なる動作をします。各セクションでその方法を説明します。

## Git HTTP {#git-http}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147112)されました。

{{< /history >}}

リポジトリでGit HTTPを使用する場合、一般的なGit操作は多くのGit HTTPリクエストを生成する可能性があります。GitLabは、認証されたGit HTTPリクエストと認証されていないGit HTTPリクエストの両方にレート制限を適用して、ウェブアプリケーションのセキュリティと耐久性を向上させることができます。

> [!note]
> [一般的なユーザーとIPのレート制限](../administration/settings/user_and_ip_rate_limits.md)はGit HTTPリクエストには適用されません。

### GitLab.comでのGit HTTP {#git-http-on-gitlabcom}

GitLab.comでは、Git HTTPリクエストは[Git HTTPSリクエストのレート制限](../user/gitlab_com/_index.md#rate-limits-on-gitlabcom)の対象となります。

### 認証されていないGit HTTPレート制限の設定 {#configure-unauthenticated-git-http-rate-limits}

GitLabはデフォルトで、認証されていないGit HTTPリクエストのレート制限を無効にしています。

前提条件: 

- 管理者アクセス権が必要です。

認証パラメータを含まないGit HTTPリクエストにレート制限を適用するには、これらの制限を有効にして設定します:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **Git HTTPレート制限**を展開します。
1. **認証されていないGit HTTPリクエストのレート制限を有効にする**を選択します。
1. **ユーザーあたりの期間あたりの認証されていない最大Git HTTPリクエスト**に値を入力します。
1. **認証されていないGit HTTPレート制限期間（秒単位）** に値を入力します。
1. **変更を保存**を選択します。

### 認証されているGit HTTPレート制限の設定 {#configure-authenticated-git-http-rate-limits}

{{< history >}}

- GitLab 18.1で`git_authenticated_http_limit`[機能フラグ](../administration/feature_flags/_index.md)とともに、認証済みGit HTTPのレート制限が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191552)されました。デフォルトでは無効になっています。
- GitLab 18.3で[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/543768)。
- GitLab 18.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/561577)になりました。機能フラグ`git_authenticated_http_limit`は削除されました。

{{< /history >}}

GitLabはデフォルトで、認証されたGit HTTPリクエストのレート制限を無効にしています。

前提条件: 

- 管理者アクセス権が必要です。

認証パラメータを含むGit HTTPリクエストにレート制限を適用するには、これらの制限を有効にして設定します:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **Git HTTPレート制限**を展開します。
1. **認証されているGit HTTPリクエストのレート制限を有効にする**を選択します。
1. **ユーザーあたりの期間あたりの認証された最大Git HTTPリクエスト**に値を入力します。
1. **認証されているGit HTTPレート制限期間（秒単位）** に値を入力します。
1. **変更を保存**を選択します。

必要に応じて、[特定のユーザーが認証されたリクエストのレート制限をバイパスできるようにする](../administration/settings/user_and_ip_rate_limits.md#allow-specific-users-to-bypass-authenticated-request-rate-limiting)ことができます。

## Git LFS {#git-lfs}

[Git Large File Storage（LFS）](../topics/git/lfs/_index.md)は、大きなファイルを扱うためのGit拡張機能です。Git LFSを使用するリポジトリは、多数のLFSリクエストを生成する可能性があります。[一般的なユーザーとIPのレート制限](../administration/settings/user_and_ip_rate_limits.md)を適用できますが、一般的な設定を上書きしてGit LFSリクエストに追加の制限を適用することもできます。この上書きにより、ウェブアプリケーションのセキュリティと耐久性を向上させることができます。

### GitLab.comでのGit LFS {#git-lfs-on-gitlabcom}

GitLab.comでは、Git LFSリクエストは[認証されたウェブリクエストのレート制限](../user/gitlab_com/_index.md#rate-limits-on-gitlabcom)の対象となります。これらの制限は、ユーザーあたり1分間に1000リクエストに設定されています。

アップロードまたはダウンロードされる各Git LFSオブジェクトは、この制限に対してカウントされるHTTPリクエストを生成します。

> [!note]
> 複数の大きなファイルを持つプロジェクトでは、HTTPレート制限エラーが発生する可能性があります。このエラーは、CI/CDパイプラインのような自動化された環境で、単一のIPアドレスから実行された場合に、クローンまたはプル中に発生します。

### Git LFSレート制限の設定 {#configure-git-lfs-rate-limits}

Git LFSレート制限は、GitLab Self-Managedインスタンスではデフォルトで無効になっています。管理者は、Git LFSトラフィック専用のレート制限を設定できます。これらの専用LFSレート制限が有効になっている場合、デフォルトの[ユーザーとIPのレート制限](../administration/settings/user_and_ip_rate_limits.md)を上書きします。

前提条件: 

- インスタンスの管理者である必要があります。

Git LFSレート制限を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **Git LFSレート制限**を展開します。
1. **認証されたGit LFSリクエストレート制限を有効にする**を選択します。
1. **ユーザーあたりの期間あたりの認証された最大Git LFSリクエスト**に値を入力します。
1. **認証されたGit LFSレート制限期間（秒単位）** に値を入力します。
1. **変更を保存**を選択します。

## Git SSH操作 {#git-ssh-operations}

GitLabは、SSHを使用するGit操作に、ユーザーアカウントとプロジェクトごとにレート制限を適用します。ユーザーがレート制限を超過すると、GitLabはそのユーザーからのプロジェクトに対するそれ以上の接続リクエストを拒否します。

レート制限は、Gitコマンド（[配管（Plumbing）](https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain)）レベルで適用されます。デフォルトでは、各コマンドには1分あたり600のレート制限があります。例: 

- `git push`には1分あたり600のレート制限があります。
- `git pull`には独自の1分あたり600のレート制限があります。

`git-upload-pack`、`git pull`、および`git clone`の各コマンドは、コマンドを共有するため、レート制限も共有します。

> [!note]
> [一般的なユーザーとIPのレート制限](../administration/settings/user_and_ip_rate_limits.md)はGit SSH操作には適用されません。SSHトラフィックは内部APIを介してGitLabに到達するため、この制限に対してのみカウントされます。

### GitLab.comでのGit SSH操作 {#git-ssh-operations-on-gitlabcom}

GitLab.comでは、Git SSH操作はデフォルトの1分あたり600操作のレート制限を使用します。この制限は変更できません。

### GitLab Shell操作制限の設定 {#configure-the-gitlab-shell-operation-limit}

`Git operations using SSH`はデフォルトで有効になっています。デフォルトはユーザーあたり1分間に600です。

前提条件: 

- 管理者アクセス権。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **Git SSH操作のレート制限**を展開します。
1. **1分あたりのgit操作の最大数**に値を入力します。
   - レート制限を無効にするには、`0`に設定します。
1. **変更を保存**を選択します。

## 関連トピック {#related-topics}

- [レート制限](_index.md)
- [ユーザーとIPのレート制限](../administration/settings/user_and_ip_rate_limits.md)
- [設定不可能なレート制限](non_configurable.md)
