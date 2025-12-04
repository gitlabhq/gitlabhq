---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: Jira認証情報を作成する'
---

このチュートリアルでは、Jiraの認証情報を作成する方法を説明します。新しいJiraの認証情報を使用して、GitLabでJira Data CenterまたはJira Server向けの[Jiraイシューのインテグレーション](configure.md)を設定できます。

Jiraの認証情報を作成するために、以下を行います:

1. [Jiraユーザーを作成](#create-a-jira-user)。
1. [ユーザー用のJiraグループを作成](#create-a-jira-group-for-the-user)。
1. [グループの権限スキーマを作成](#create-a-permission-scheme-for-the-group)。

前提要件:

- 少なくとも`Jira Administrators` [グローバルパーミッション](https://confluence.atlassian.com/adminjiraserver/managing-global-permissions-938847142.html)が必要です。

## Jiraユーザーを作成 {#create-a-jira-user}

Jiraユーザーを作成するには:

1. 上部のバーの右上隅で、**Administration**（管理）（{{< icon name="settings" >}}）> **User management**（ユーザー管理）を選択します。
1. [Jiraプロジェクトへの書き込みアクセス権を持つ新しいユーザーアカウントを作成](https://confluence.atlassian.com/adminjiraserver/create-edit-or-remove-a-user-938847025.html#Create,edit,orremoveauser-CreateusersmanuallyinJira)。

   または、`Administer Projects` [権限スキーマ](#create-a-permission-scheme-for-the-group)が付与されているJiraグループにユーザーが属している場合は、既存のユーザーアカウントを使用できます。

   - **メールアドレス**に、有効なメールアドレスを入力します。
   - **ユーザー名**に、`gitlab`と入力します。
   - **パスワード**に、パスワードを入力します（Jiraイシューのインテグレーションは、SAMLなどのシングルサインオンをサポートしていません）。
1. **ユーザーの作成**を選択します。

ユーザー`gitlab`を作成したので、ユーザーのグループを作成します。

## ユーザーのJiraグループを作成 {#create-a-jira-group-for-the-user}

ユーザーのJiraグループを作成するには:

1. 上部のバーの右上隅で、**Administration**（管理）（{{< icon name="settings" >}}）> **User management**（ユーザー管理）を選択します。
1. 左側のサイドバーで、**グループ**を選択します。
1. **グループの追加**セクションで、グループの名前（たとえば、`gitlab-developers`）を入力し、**グループの追加**を選択します。
1. 新しい`gitlab-developers`グループに`gitlab`ユーザーを追加するには、**Edit members**（メンバーの編集）を選択します。`gitlab-developers`グループが選択されたグループとして表示されます。
<!-- vale gitlab_base.BadPlurals = NO -->
1. **Add members to selected group(s)**（選択したグループにメンバーを追加）セクションで、`gitlab`を入力します。
<!-- vale gitlab_base.BadPlurals = YES -->
1. **Add selected users**（選択したユーザーを追加）を選択します。`gitlab`ユーザーがグループメンバーとして表示されます。

`gitlab`ユーザーを`gitlab-developers`という名前の新しいグループに追加したので、グループの権限スキーマを作成します。

## グループの権限スキーマを作成 {#create-a-permission-scheme-for-the-group}

グループの権限スキーマを作成するには:

1. 上部のバーの右上隅で、**Administration**（管理）（{{< icon name="settings" >}}）> **イシュー**を選択します。
1. 左側のサイドバーで、**Permission schemes**（権限スキーマ）を選択します。
1. **Add permission scheme**（権限スキーマの追加）を選択します。
1. **Add permission scheme**（権限スキーマの追加）ダイアログで:
   - スキームの名前を入力します。
   - オプション。スキームの説明を入力します。
1. **追加**を選択します。
1. **Permission schemes**（権限スキーマ）ページの**アクション**列で、新しいスキーマの**権限**を選択します。
1. **Administer Projects**（プロジェクトの管理）の横にある**編集**を選択します。
1. **Grant permission**（権限の付与）ダイアログで、**Granted to**（付与先）に**グループ**を選択します。
1. **グループ**ドロップダウンリストから、`gitlab-developers`を選択し、**Grant**（許可）を選択します。

完了しました。新しいJiraのユーザー名とパスワードを使用して、GitLabでJira Data CenterまたはJira Server向けの[Jiraイシューのインテグレーション](configure.md)を設定できます。
