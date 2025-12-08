---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトとグループの表示レベル
description: 公開、非公開、内部。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabのプロジェクトとグループは、非公開、内部、または公開に設定できます。

プロジェクトまたはグループの表示レベルは、プロジェクトやグループのメンバー同士が互いを表示できるかどうかには影響しません。プロジェクトとグループは、共同作業を目的としています。この共同作業は、すべてのメンバーがお互いを知っている場合にのみ可能です。

プロジェクトまたはグループのメンバーは、自分が所属するプロジェクトまたはグループのすべてのメンバーを表示できます。プロジェクトまたはグループのメンバーは、アクセスできるプロジェクトとグループのすべてのメンバーが追加された際の経路（元のプロジェクトまたはグループ）を表示できます。

## 非公開プロジェクトおよびグループ {#private-projects-and-groups}

非公開プロジェクトの場合、非公開プロジェクトまたはグループのメンバーのみが以下を実行できます:

- プロジェクトを複製する。
- 公開アクセスディレクトリ（`/public`）を表示する。

ゲストロールのユーザーは、プロジェクトを複製できません。

非公開グループには、非公開のサブグループとプロジェクトのみを含めることができます。

{{< alert type="note" >}}

[非公開グループを別のグループと共有する](project/members/sharing_projects_groups.md#invite-a-group-to-a-group)と、非公開グループへのアクセス権を持たないユーザーは、エンドポイント`https://gitlab.com/groups/<inviting-group-name>/-/autocomplete_sources/members`を通じて、招待グループへのアクセス権を持つユーザーのリストを表示できます。ただし、非公開グループの名前とパスはマスクされます。また、ユーザーのメンバーシップソースは表示されません。

{{< /alert >}}

## 内部プロジェクトおよびグループ {#internal-projects-and-groups}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

内部プロジェクトの場合、ゲストロールを持つユーザーを含め、認証済みユーザーは以下を実行できます:

- プロジェクトを複製する。
- 公開アクセスディレクトリ（`/public`）を表示する。

内部メンバーのみが内部コンテンツを表示できます。

[外部ユーザー](../administration/external_users.md)は、プロジェクトを複製できません。

内部グループには、内部または非公開のサブグループとプロジェクトを含めることができます。

## 公開プロジェクトおよびグループ {#public-projects-and-groups}

公開プロジェクトの場合、認証されていないユーザーを含め、すべてのユーザーが以下を実行できます:

- プロジェクトを複製する。
- 公開アクセスディレクトリ（`/public`）を表示する。

公開グループには、公開、内部、または非公開のサブグループとプロジェクトを含めることができます。

{{< alert type="note" >}}

管理者が[**公開**表示レベル](../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels)を制限している場合、公開アクセスディレクトリ（`/public`）は認証済みユーザーのみに表示されます。

{{< /alert >}}

## プロジェクトの表示レベルを変更する {#change-project-visibility}

プロジェクトの表示レベルを変更できます。

前提要件:

- プロジェクトのオーナーロールが必要です。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **プロジェクトの表示レベル**ドロップダウンリストから、オプションを選択します。プロジェクトの表示レベルは、その親グループの表示レベルと同等以上の制限を設定する必要があります。
1. **変更を保存**を選択します。

## プロジェクト内の個々の機能の表示レベルを変更する {#change-the-visibility-of-individual-features-in-a-project}

プロジェクト内の個々の機能の表示レベルを変更できます。

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. 機能を有効または無効にするには、機能の切替えをオンまたはオフにします。
1. **変更を保存**を選択します。

## グループの表示レベルを変更する {#change-group-visibility}

グループ内のすべてのプロジェクトの表示レベルを変更できます。

前提要件:

- グループのオーナーロールが必要です。
- プロジェクトとサブグループには、親グループの新しい設定と同等の表示レベル制限を設定しておく必要があります。たとえば、グループ内のプロジェクトまたはサブグループが公開されている場合、グループを非公開に設定することはできません。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオンにしている](interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **設定** > **一般**を選択します。
1. 展開する**命名、説明、表示レベル**。
1. **表示レベル**で、オプションを選択します。プロジェクトの表示レベルは、その親グループの表示レベルと同等以上の制限を設定する必要があります。
1. **変更を保存**を選択します。

## 公開または内部プロジェクトの使用を制限する {#restrict-use-of-public-or-internal-projects}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

管理者は、ユーザーがプロジェクトまたはスニペットの作成時に選択可能な表示レベルを制限できます。この設定は、ユーザーが誤ってリポジトリを公開することを防ぐのに役立ちます。

詳細については、[表示レベルを制限する](../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels)を参照してください。
