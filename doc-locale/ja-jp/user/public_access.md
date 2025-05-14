---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトとグループの表示レベル
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabのプロジェクトとグループは、非公開、内部、または公開に設定できます。

プロジェクトまたはグループの表示レベルは、プロジェクトやグループのメンバー同士が互いを表示できるかどうかには影響しません。プロジェクトとグループは、共同作業を目的としています。この共同作業は、すべてのメンバー同士がお互いを知らなければ実行できません。

プロジェクトまたはグループのメンバーは、自分が所属するプロジェクトやグループのすべてのメンバーを表示できます。プロジェクトまたはグループのメンバーは、アクセスできるプロジェクトやグループの全メンバーのメンバーシップのorigin（元のプロジェクトまたはグループ）を表示できます。

## 非公開プロジェクトおよびグループ

非公開プロジェクトの場合、非公開プロジェクトまたはグループのメンバーのみが以下を実行できます。

- プロジェクトを複製する。
- 公開アクセスディレクトリ（`/public`）を表示する。

Guestロールのユーザーは、プロジェクトを複製できません。

非公開グループには、非公開のサブグループとプロジェクトのみを含めることができます。

{{< alert type="note" >}}

[非公開グループを別のグループと共有する](project/members/sharing_projects_groups.md#invite-a-group-to-a-group)と、非公開グループへのアクセス権を持たないユーザーは、エンドポイント`https://gitlab.com/groups/<inviting-group-name>/-/autocomplete_sources/members`を通じて、招待グループへのアクセス権を持つユーザーのリストを表示できます。ただし、非公開グループの名前とパスはマスクされます。また、ユーザーのメンバーシップソースは表示されません。

{{< /alert >}}

## 内部プロジェクトおよびグループ

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

内部プロジェクトの場合、Guestロールを持つユーザーを含め、認証済みのすべてのユーザーは以下を実行できます。

- プロジェクトを複製する。
- 公開アクセスディレクトリ（`/public`）を表示する。

内部メンバーのみが内部コンテンツを表示できます。

[外部ユーザー](../administration/external_users.md)は、プロジェクトを複製できません。

内部グループには、内部または非公開のサブグループとプロジェクトを含めることができます。

## 公開プロジェクトおよびグループ

公開プロジェクトの場合、認証されていないユーザーを含め、すべてのユーザーが以下を実行できます。

- プロジェクトを複製する。
- 公開アクセスディレクトリ（`/public`）を表示する。

公開グループには、公開、内部、または非公開のサブグループとプロジェクトを含めることができます。

{{< alert type="note" >}}

管理者が[**公開**表示レベル](../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels)を制限している場合、公開アクセスディレクトリ（`/public`）は認証済みのユーザーのみに表示されます。

{{< /alert >}}

## プロジェクトの表示レベルを変更する

プロジェクトの表示レベルを変更できます。

前提要件:

- プロジェクトのオーナーロールが必要です。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **設定 > 一般**を選択します。
1. **表示レベル、プロジェクトの機能、権限**を展開します。
1. **プロジェクトの表示レベル**ドロップダウンリストから、オプションを選択します。プロジェクトの表示レベルは、その親グループの表示レベルと同等以上の制限を設定する必要があります。
1. **変更を保存**を選択します。

## プロジェクト内の個々の機能の表示レベルを変更する

プロジェクト内の個々の機能の表示レベルを変更できます。

前提要件:

- プロジェクトのメンテナー以上のロールが必要です。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **設定 > 一般**を選択します。
1. **表示レベル、プロジェクトの機能、権限**を展開します。
1. 機能を有効または無効にするには、機能の切替えをオンまたはオフにします。
1. **変更を保存**を選択します。

## グループの表示レベルを変更する

グループ内のすべてのプロジェクトの表示レベルを変更できます。

前提要件:

- グループのオーナーロールが必要です。
- プロジェクトとサブグループには、親グループの新しい設定と同等の表示レベル制限を設定しておく必要があります。たとえば、グループ内のプロジェクトまたはサブグループが公開されている場合、グループを非公開に設定することはできません。

1. 左側のサイドバーで、**検索または移動**を選択して、グループを見つけます。
1. **設定 > 一般**を選択します。
1. **名前、表示レベル**を展開します。
1. **表示レベル**で、オプションを選択します。プロジェクトの表示レベルは、その親グループの表示レベルと同等以上の制限を設定する必要があります。
1. **変更を保存**を選択します。

## 公開または内部プロジェクトの使用を制限する

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

管理者は、ユーザーがプロジェクトまたはスニペットの作成時に選択可能な表示レベルを制限できます。この設定は、ユーザーが誤ってリポジトリを公開することを防ぐのに役立ちます。

詳細については、[表示レベルを制限する](../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels)を参照してください。

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
