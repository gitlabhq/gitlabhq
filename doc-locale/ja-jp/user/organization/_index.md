---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 組織
description: ネームスペースの階層。
---

{{< history >}}

- GitLab 16.1で`ui_for_organizations`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/409913)されました。デフォルトでは無効になっています。
- 16.1で[GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/409913)で有効になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

{{< alert type="disclaimer" />}}

{{< alert type="note" >}}

組織は開発中です。

{{< /alert >}}

組織は、[トップレベルネームスペース](../namespace/_index.md)の上に配置され、すべての操作をGitLab管理者として管理できます。内容は以下のとおりです:

- すべてのグループ、サブグループ、およびプロジェクトに対する設定の定義と適用。
- すべてのグループ、サブグループ、およびプロジェクトからのデータの集計。

組織の開発状況について詳しくは、[エピック9265](https://gitlab.com/groups/gitlab-org/-/epics/9265)をご覧ください。

## 組織を表示 {#view-organizations}

アクセスできる組織を表示するには:

- 左側のサイドバーで、**組織**を選択します。

## 組織を作成 {#create-an-organization}

{{< alert type="note" >}}

プライベート組織のみのサポートが[cells 1.0](https://gitlab.com/groups/gitlab-org/-/epics/12383)で提案されています。

{{< /alert >}}

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新しい組織**を選択します。
1. **組織の名前**テキストボックスに、組織の名前を入力します。
1. **組織のURL**テキストボックスに、組織のパスを入力します。
1. **Organization description**（組織の説明）テキストボックスに、組織の説明を入力します。[制限されたサブセットの](#supported-markdown-for-organization-description)をサポートします。
1. **組織のアバター**フィールドで、**アップロード**を選択するか、アバターをドラッグアンドドロップします。
1. **組織を作成**を選択します。

## 組織の名前を編集 {#edit-an-organizations-name}

1. 左側のサイドバーで、**組織**を選択し、編集する組織を見つけます。
1. **設定** > **一般**を選択します。
1. **組織の名前**テキストボックスで、名前を編集します。
1. **Organization description**（組織の説明）テキストボックスで、説明を編集します。[制限されたサブセットの](#supported-markdown-for-organization-description)をサポートします。
1. **組織のアバター**フィールドで、アバターが次のようになっている場合:
   - 選択されている場合は、**アバターを消去**を選択して削除します。
   - 選択されていない場合は、**アップロード**を選択するか、アバターをドラッグアンドドロップします。
1. **変更を保存**を選択します。

## 組織のURLを変更 {#change-an-organizations-url}

1. 左側のサイドバーで、**組織**を選択し、URLを変更する組織を見つけます。
1. **設定** > **一般**を選択します。
1. **高度な設定**セクションを展開します。
1. **組織のURL**テキストボックスで、URLを編集します。
1. **組織のURLの変更**を選択します。

## 組織の表示レベルを表示 {#view-an-organizations-visibility-level}

{{< alert type="note" >}}

プライベート組織のみのサポートが[cells 1.0](https://gitlab.com/groups/gitlab-org/-/epics/12383)で提案されています。

{{< /alert >}}

1. 左側のサイドバーで、**組織**を選択し、組織を見つけます。
1. **設定** > **一般**を選択します。
1. **表示レベル**セクションを展開する。

## 組織をスイッチ {#switch-organizations}

{{< alert type="note" >}}

組織間のスイッチは、cells 1.0ではサポートされていません。組織のスイッチのサポートが[cells 1.5](https://gitlab.com/groups/gitlab-org/-/epics/12505)で提案されています。

{{< /alert >}}

組織をスイッチするには:

- 左側のサイドバーの上隅にある**現在の組織**ドロップダウンリストから、スイッチ先の組織を選択します。

## グループとプロジェクトを管理する {#manage-groups-and-projects}

1. 左側のサイドバーで、**組織**を選択し、管理する組織を見つけます。
1. **管理** > **グループとプロジェクト**を選択します。
1. オプション。結果をフィルタリングします: 
   - 特定のグループまたはプロジェクトを検索するには、検索ボックスに検索語句を入力します（3文字以上）。
   - グループまたはプロジェクトのみを表示するには、**ディスプレイ**ドロップダウンリストからオプションを選択します。
1. オプション。名前、作成日、または更新日で結果をソートするには、ドロップダウンリストからオプションを選択します。次に、昇順({{< icon name="sort-lowest" >}})または降順({{< icon name="sort-highest" >}})を選択します。

## 組織にグループを作成 {#create-a-group-in-an-organization}

1. 左側のサイドバーで、**組織**を選択し、グループを作成する組織を見つけます。
1. **管理** > **グループとプロジェクト**を選択します。
1. **新規グループ**を選択します。
1. **グループ名**テキストボックスに、グループの名前を入力します。グループ名として使用できない単語のリストについては、[予約済みの名前](../reserved_names.md)を参照してください。
1. **グループURL**テキストボックスに、[ネームスペース](../namespace/_index.md)に使用するグループのパスを入力します。
1. グループの[**表示レベル**](../public_access.md)を選択します。
1. **グループを作成**を選択します。

## ユーザーを表示する {#view-users}

1. 左側のサイドバーで、**組織**を選択し、表示する組織を見つけます。
1. **管理** > **ユーザー**を選択します。

## ユーザーのロールを変更 {#change-a-users-role}

前提要件: 

- 組織のオーナーロールを持っている必要があります。

ユーザーのロールを変更するには:

1. 左側のサイドバーで、**組織**を選択し、管理する組織を見つけます。
1. **管理** > **ユーザー**を選択します。
1. 更新するユーザーのロールを見つけます。
1. **組織のロール**ドロップダウンリストから、ロールを選択します。

{{< alert type="note" >}}

**組織のロール**ドロップダウンリストから選択できない場合、このユーザーは組織の唯一のオーナーです。このユーザーのロールを変更するには、まず別のユーザーにオーナーロールを割り当てます。

{{< /alert >}}

## 組織の説明でサポートされる {#supported-markdown-for-organization-description}

組織の説明フィールドは、以下を含む[GitLab Flavored Markdown](../markdown.md)の制限されたサブセットをサポートしています:

- [強調](../markdown.md#emphasis)
- [リンク](../markdown.md#links)
- [上付き文字/下付き文字](../markdown.md#superscripts-and-subscripts)
