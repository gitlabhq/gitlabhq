---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: Gitの不正利用レート制限（管理）
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.2で`git_abuse_rate_limit_feature_flag`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/8066)されました。デフォルトでは無効になっています。
- GitLab 15.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/394996)になりました。機能フラグ`git_abuse_rate_limit_feature_flag`は削除されました。

{{< /history >}}

これは管理者向けのドキュメントです。グループのGitの不正利用レート制限については、[グループのドキュメント](../../user/group/reporting/git_abuse_rate_limit.md)を参照してください。

Gitの不正利用レート制限は、所定の時間内にインスタンス内の任意のプロジェクトで、指定された数を超えるリポジトリをダウンロード、クローン、またはフォークする[ユーザーをBANする](../moderate_users.md#ban-and-unban-users)機能です。BANされたユーザーは、インスタンスにサインインできず、HTTPまたはSSH経由で非公開グループにアクセスできません。レート制限は、[個人](../../user/profile/personal_access_tokens.md)または[グループアクセストークン](../../user/group/settings/group_access_tokens.md)で認証するユーザーにも適用されます。

Gitの不正利用レート制限は、インスタンスの管理者、[デプロイトークン](../../user/project/deploy_tokens/_index.md) 、または[デプロイキー](../../user/project/deploy_keys/_index.md)には適用されません。

GitLabがユーザーのレート制限をどのように決定するかは、現在開発中です。GitLabのチームメンバーは、この機密情報エピック(`https://gitlab.com/groups/gitlab-org/modelops/anti-abuse/-/epics/14`)で詳細情報を確認できます。

## Gitの不正利用レート制限を設定する {#configure-git-abuse-rate-limiting}

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **レポート**を選択します。
1. **Gitの不正利用率制限**を展開する。
1. Gitの不正利用レート制限の設定を更新します:
   1. **リポジトリの数**フィールドに、`0`以上、`10000`以下の数値を入力します。この数値は、ユーザーがBANされるまでに、指定された期間内にダウンロードできる一意のリポジトリの最大数を指定します。`0`に設定すると、Gitの不正利用レート制限が無効になります。
   1. **レポート期間（秒）**フィールドに、`0`以上、`864000`（10日間）以下の数値を入力します。この数値は、ユーザーがBANされるまでに、最大数のリポジトリをダウンロードできる時間（秒単位）を指定します。`0`に設定すると、Gitの不正利用レート制限が無効になります。
   1. オプション。最大`100`人のユーザーを**除外ユーザー**フィールドに追加して、除外します。除外されたユーザーは自動的にBANされません。
   1. 最大`100`人のユーザーを**通知を送信**フィールドに追加します。少なくとも1人のユーザーを選択する必要があります。すべてのアプリケーション管理者はデフォルトで選択されています。
   1. オプション。**Automatically ban users from this namespace when they exceed the specified limits**（指定された制限を超えた場合に、このネームスペースからユーザーを自動的にBANする）切替をオンにすると、自動BANが有効になります。
1. **変更を保存**を選択します。

## 自動BAN通知 {#automatic-ban-notifications}

自動BANが無効になっている場合、ユーザーが制限を超えても自動的にBANされることはありません。ただし、通知は、**通知を送信**の下にリストされているユーザーに送信されます。自動BANを有効にする前に、この設定を使用してレート制限の設定の正しい値を決定できます。

自動BANが有効になっている場合、ユーザーがBANされようとするとメール通知が送信され、ユーザーはGitLabインスタンスから自動的にBANされます。

## ユーザーのBANを解除 {#unban-a-user}

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. **BAN**タブを選択し、BANを解除するアカウントを検索します。
1. **ユーザー管理**ドロップダウンリストから**ユーザーをBAN解除**を選択します。
1. 確認ダイアログで、**ユーザーをBAN解除**を選択します。
