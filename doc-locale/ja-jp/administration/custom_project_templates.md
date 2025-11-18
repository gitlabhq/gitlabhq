---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: プロジェクトテンプレートを設定し、GitLabインスタンス上のすべてのプロジェクトで利用できるようにします。
title: インスタンスのカスタムプロジェクトテンプレート
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インスタンスでのプロジェクトの作成を迅速化するために、テンプレートプロジェクトを含むグループを設定します。これにより、ユーザーは指定した共通ツールと設定を含む[テンプレートに基づいて新しいプロジェクト](../user/project/_index.md#create-a-project-from-a-custom-template)を作成できます。

テンプレートプロジェクトからコピーされるデータの詳細については、[テンプレートからコピーされるもの](../user/group/custom_project_templates.md#what-is-copied-from-the-templates)を参照してください。

テンプレートプロジェクトをインスタンスで利用できるようにする前に、テンプレートを管理するグループを選択してください。テンプレートへの予期しない変更を防ぐために、既存のグループを再利用するのではなく、この目的のために新しいグループを作成してください。別の目的で作成された既存のグループを再利用すると、メンテナーロールを持つユーザーが、副次効果を理解せずにテンプレートプロジェクトを編集する可能性があります。

## テンプレートプロジェクトを管理するグループを選択します {#select-a-group-to-manage-template-projects}

インスタンスのプロジェクトテンプレートを管理するグループを選択するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定**を選択します。**テンプレート** > **テンプレート**を選択します。
1. **カスタムプロジェクトテンプレート**を展開します。
1. 使用するグループを選択します。
1. **変更を保存**を選択します。

プロジェクトテンプレートのソースとしてグループを設定すると、このグループに追加された新しいプロジェクトがテンプレートとして使用できるようになります。

## テンプレートとして使用するプロジェクトを設定します {#configure-a-project-for-use-as-a-template}

テンプレートプロジェクトを管理するグループを作成したら、各テンプレートプロジェクトの表示レベルと機能の可用性を設定します。

前提要件: 

- インスタンスの管理者、またはプロジェクトを設定できるロールを持つユーザーである必要があります。

1. プロジェクトがサブグループ経由ではなく、グループに直接属していることを確認してください。選択したグループのサブグループのプロジェクトは、テンプレートとして使用できません。
1. プロジェクトテンプレートを選択できるユーザーを設定するには、[プロジェクトの表示レベル](../user/public_access.md#change-project-visibility)を設定します:
   - **公開**プロジェクトと**内部**プロジェクトは、すべての認証済みユーザーが選択できます。
   - **プライベート**プロジェクトは、そのプロジェクトのメンバーのみが選択できます。
1. プロジェクトの[設定](../user/project/settings/_index.md#configure-project-features-and-permissions)をレビューします。有効になっているすべてのプロジェクト機能は、**アクセスできる人すべて**に設定する必要があります。**GitLab Pages**と**セキュリティとコンプライアンス**を除きます。

各新規プロジェクトにコピーされるリポジトリとデータベースの情報は、[GitLabプロジェクトインポート/エクスポート](../user/project/settings/import_export.md)でエクスポートされるデータと同じです。

## 関連トピック {#related-topics}

- [グループのカスタムプロジェクトテンプレート](../user/group/custom_project_templates.md)。
