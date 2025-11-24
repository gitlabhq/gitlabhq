---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Confluence Workspace
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Confluence CloudワークスペースをプロジェクトWikiとして使用します。

このインテグレーションは、[GitLab wiki](../wiki/_index.md)の代わりにConfluence Wikiへのリンクを追加します。ConfluenceにあるコンテンツはGitLabには表示されません。

このインテグレーションをオンにすると、以下のようになります:

- 新しいメニュー項目が左側のサイドバーに追加されます: **Plan** > **Confluence**。Confluence Wikiにリンクします。
- **Plan** > **Wiki**メニュー項目が非表示になります。

  プロジェクトのGitLab Wikiにアクセスするには、URL（`<example_project_URL>/-/wikis/home`）を使用します。**Plan** > **Wiki**メニュー項目を戻すには、このインテグレーションをオフにします。

Confluence Cloudとのより包括的なインテグレーションの作成は、[epic 3629](https://gitlab.com/groups/gitlab-org/-/epics/3629)で追跡されています。

## インテグレーションを設定する {#set-up-the-integration}

このインテグレーションは、プロジェクト、またはグループやインスタンス内のすべてのプロジェクトに対してオンにできます。

### プロジェクトまたはグループ内のすべてのプロジェクトの場合 {#for-your-project-or-all-projects-in-a-group}

前提要件: 

- プロジェクトのメンテナー以上のロールを持っている必要があります。
- Confluence CloudのURL(`https://example.atlassian.net/wiki/`)を使用する必要があります。

プロジェクトまたはグループのインテグレーションを設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Confluenceのワークスペース**の横にある**設定する**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. **ConfluenceワークスペースのURL**に、ConfluenceワークスペースのURLを入力します。
1. **変更を保存**を選択します。

インテグレーションがグループに対してオンになっている場合でも、個々のプロジェクトに対してオフにすることができます。

### インスタンス上のすべてのプロジェクトの場合 {#for-all-projects-on-the-instance}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

前提要件: 

- インスタンスへの管理者アクセス権が必要です。
- Confluence CloudのURL(`https://example.atlassian.net/wiki/`)を使用する必要があります。

インスタンスのインテグレーションを設定するには:

1. 左側のサイドバーの下部で、**Admin Area**（管理者エリア）を選択します。
1. **設定** > **インテグレーション**を選択します。
1. **Confluenceのワークスペース**の横にある**設定する**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. **ConfluenceワークスペースのURL**に、ConfluenceワークスペースのURLを入力します。
1. **変更を保存**を選択します。

## GitLabからConfluenceワークスペースにアクセスする {#access-your-confluence-workspace-from-gitlab}

前提要件: 

- [プロジェクト、グループ](#for-your-project-or-all-projects-in-a-group) 、または[インスタンス](#for-all-projects-on-the-instance)のインテグレーションを設定する必要があります。

GitLabプロジェクトからConfluenceワークスペースにアクセスするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **Confluence**を選択します。
1. **Confluenceに移動**を選択します。
