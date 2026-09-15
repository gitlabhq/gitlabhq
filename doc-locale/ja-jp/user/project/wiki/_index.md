---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Wiki
description: ドキュメント、外部Wiki、Wikiイベント、履歴。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Wikiは、プロジェクトやグループのドキュメントを使い慣れた形式で提供します。Wikiページには次のような機能があります。

- Markdown、RDoc、AsciiDoc、Org形式で、技術ドキュメント、ガイド、ナレッジベースを生成する。
- GitLabプロジェクトとグループと直接統合される共同編集ドキュメントを作成する。
- バージョン管理とコラボレーションのために、ドキュメントをGitリポジトリに保存する。
- サイドバーのカスタマイズによるカスタムナビゲーションと構成をサポートする。
- オフラインアクセスと共有のために、コンテンツをPDFファイルとしてエクスポートする。
- コードベースとは別にコンテンツを管理しながら、同じプロジェクト内に保持する。
- フィードバックとエンゲージメントのために、ページで絵文字リアクションをサポートする。

各Wikiは、個別のGitリポジトリです。GitLab Webインターフェースまたは[ローカル環境のGitを使用](#create-or-edit-wiki-pages-locally)して、Wikiページを作成および編集できます。Markdownで記述されたWikiページは、すべての[Markdown機能](../../markdown.md)をサポートし、リンクについては[Wiki固有の動作](markdown.md)を提供します。

Wikiページには[サイドバー](#sidebar)が表示されます。サイドバーはカスタマイズも可能です。

## プロジェクトWikiを表示する {#view-a-project-wiki}

プロジェクトWikiにアクセスするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。

プロジェクトの左側のサイドバーに**計画** > **Wiki**が表示されない場合、プロジェクト管理者によって[無効](#enable-or-disable-a-project-wiki)にされています。

## Wikiのデフォルトブランチを設定する {#configure-a-default-branch-for-your-wiki}

Wikiリポジトリは、インスタンスまたはグループから[デフォルトブランチ名](../repository/branches/default.md)を継承します。カスタムブランチ名が設定されていない場合、GitLabは`main`を使用します。Wikiのデフォルトブランチ名を変更するには、[リポジトリ内でデフォルトブランチ名を更新](../repository/branches/default.md#update-the-default-branch-name-in-your-repository)します。

## Wikiホームページを作成する {#create-the-wiki-home-page}

{{< history >}}

- ページタイトルとパスの分離は、GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/30758)され、`wiki_front_matter`および`wiki_front_matter_title`と名付けられた[機能フラグを使用して](../../../administration/feature_flags/_index.md)います。デフォルトでは有効になっています。
- 機能フラグ`wiki_front_matter`および`wiki_front_matter_title`は、GitLab 17.3で削除されました。
- 没入型エディタ:
  - GitLab 19.1で`wiki_immersive_editor`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231662)されました。デフォルトでは有効になっています。
  - GitLab 19.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/238053)になりました。機能フラグ`wiki_immersive_editor`が削除されました。

{{< /history >}}

作成時点ではWikiは空です。初回アクセス時に、ユーザーがWikiを閲覧する際に表示されるホームページを作成できます。このページをWikiのホームページとして使用するには、特定のパスが必要です。作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. **最初のページを作成**を選択します。
1. オプション。ホームページの**タイトル**を変更します。
1. GitLabでは、この最初のページのパスを`home`にする必要があります。このパスのページがWikiのフロントページになります。
1. オプション。**ページオプションを編集**（{{< icon name="chevron-down" >}}）を選択して、次の操作を行います:
   - ページの**パス**を変更します。デフォルトでは、パスはタイトルから生成されます。ページパスでは、サブディレクトリと書式設定に[特殊文字](#special-characters-in-page-paths)を使用します。また、パスには[長さ制限](#length-restrictions-for-file-and-directory-names)があります。
   - コンテンツの**フォーマット**を変更します。
   - **テンプレート**を選択します。詳細については、[テンプレートから作成する](#from-a-template)を参照してください。
1. コンテンツエリアにホームページのウェルカムメッセージを追加します。これは後からいつでも編集できます。
1. **ページを作成**を選択します。保存前にコミットメッセージを追加するには、**ページを作成**の横にある矢印を選択し、**メッセージ付きで変更を保存**を選択します。

## 新しいWikiページを作成する {#create-a-new-wiki-page}

{{< history >}}

- ページタイトルとパスの分離は、GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/30758)され、`wiki_front_matter`および`wiki_front_matter_title`と名付けられた[機能フラグを使用して](../../../administration/feature_flags/_index.md)います。デフォルトでは有効になっています。
- 機能フラグ`wiki_front_matter`および`wiki_front_matter_title`は、GitLab 17.3で削除されました。
- GitLab 18.10で上部のバーからWikiページを作成する機能が[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/591976)されました。
- 没入型エディタ:
  - GitLab 19.1で`wiki_immersive_editor`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231662)されました。デフォルトでは有効になっています。
  - GitLab 19.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/238053)になりました。機能フラグ`wiki_immersive_editor`が削除されました。{{< /history >}}

前提条件: 

- デベロッパー、メンテナー、またはオーナーロール。

プロジェクトまたはグループから新しいWikiページを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、グループまたはプロジェクトを見つけます。
1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新しいWikiページ**を選択します。

または:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. このページまたは他のWikiページで、**Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**新しいページ**を選択します。

新しいページフォームを開いたら、次の手順を実行します:

1. エディタのヘッダーで新しいページの**タイトル**を追加します。
1. オプション。**ページオプションを編集**（{{< icon name="chevron-down" >}}）を選択して、次の操作を行います:
   - ページの**パス**を変更します。デフォルトでは、パスはタイトルから生成されます。ページパスでは、サブディレクトリと書式設定に[特殊文字](#special-characters-in-page-paths)を使用します。また、パスには[長さ制限](#length-restrictions-for-file-and-directory-names)があります。
   - コンテンツの**フォーマット**を変更します。
   - **テンプレート**を選択します。詳細については、[テンプレートから作成する](#from-a-template)を参照してください。
1. オプション。Wikiページにコンテンツを追加します。
1. オプション。ファイルを添付します。GitLabはそのファイルをWikiのGitリポジトリに保存します。
1. **ページを作成**を選択します。保存前にコミットメッセージを追加するには、**ページを作成**の横にある矢印を選択し、**メッセージ付きで変更を保存**を選択します。

### テンプレートから作成する {#from-a-template}

{{< history >}}

- GitLab 18.6でテンプレートから直接新しいWikiページを作成する機能が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/474328)されました。

{{< /history >}}

プロジェクトに少なくとも1つのテンプレートがある場合、[テンプレート](#create-a-template)から新しいWikiページを作成できます。

前提条件: 

- テンプレートを少なくとも1つ[作成済み](#create-a-template)であること。

{{< tabs >}}

{{< tab title="テンプレートリストから" >}}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. **テンプレート**を選択して、利用可能なすべてのテンプレートを表示します。
1. 使用するテンプレートの横にある**テンプレートから作成する**を選択します。
1. 新しいページフォームが開き、次の状態になります:
   - コンテンツエリアにテンプレートの内容が事前に入力されている。
   - テンプレートのドロップダウンリストで、そのテンプレートが選択されている。
1. 新しいページのタイトルを入力します。
1. 必要に応じてコンテンツを変更します。
1. **ページを作成**を選択します。

{{< /tab >}}

{{< tab title="テンプレートページから" >}}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. **テンプレート**を選択して、利用可能なすべてのテンプレートを表示します。
1. 使用するテンプレートを選択します。
1. ページヘッダーで、**テンプレートから作成する**を選択します。
1. 新しいページフォームが開き、現在のテンプレートが事前に選択され、その内容が読み込まれた状態になります。
1. 新しいページのタイトルを入力します。
1. 必要に応じてコンテンツを変更します。
1. **ページを作成**を選択します。

{{< /tab >}}

{{< tab title="新しいページフォームから" >}}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. **新しいページ**を選択します。
1. **テンプレートを選択する**ドロップダウンリストで、目的のテンプレートを選択します。
1. テンプレートの内容がコンテンツエリアに自動的に読み込まれます。
1. ページのタイトルを入力します。
1. 必要に応じてコンテンツを変更します。
1. **ページを作成**を選択します。

{{< /tab >}}

{{< /tabs >}}

### Wikiページをローカルで作成または編集する {#create-or-edit-wiki-pages-locally}

WikiはGitリポジトリに基づいているため、ローカルにクローンを作成し、他のすべてのGitリポジトリと同様に編集できます。Wikiリポジトリのクローンをローカルに作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**リポジトリをクローン**を選択します。
1. 画面の指示に従います。

ローカルでWikiに追加するファイルは、使用するマークアップ言語に応じて、次のいずれかのサポート対象拡張子を使用する必要があります。サポートされていない拡張子のファイルは、GitLabにプッシュしても表示されません。

- Markdown拡張子: `.mdown`、`.mkd`、`.mkdn`、`.md`、`.markdown`。
- AsciiDoc拡張子: `.adoc`、`.ad`、`.asciidoc`。
- その他のマークアップ拡張子: `.textile`、`.rdoc`、`.org`、`.creole`、`.wiki`、`.mediawiki`、`.rst`。

### ページパスの特殊文字 {#special-characters-in-page-paths}

{{< history >}}

- フロントマターベースのタイトルは、GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133521)され、`wiki_front_matter`および`wiki_front_matter_title`と名付けられた[機能フラグと共に](../../../administration/feature_flags/_index.md)提供されました。デフォルトでは無効になっています。
- 機能フラグ[`wiki_front_matter`](https://gitlab.com/gitlab-org/gitlab/-/issues/435056)と[`wiki_front_matter_title`](https://gitlab.com/gitlab-org/gitlab/-/issues/428259)は、GitLab 17.2でデフォルトで有効になっています。
- 機能フラグ`wiki_front_matter`および`wiki_front_matter_title`は、GitLab 17.3で削除されました。

{{< /history >}}

WikiページはGitリポジトリ内のファイルとして保存されます。また、デフォルトではページのファイル名がそのページのタイトルになっています。ファイル名に含まれる特定の文字には、特別な意味があります。

- ページを保存するとき、スペースはハイフンに変換されます。
- ページを表示するとき、ハイフン（`-`）は、スペースに変換されます。
- スラッシュ（`/`）はパスの区切り文字として使用されます。タイトルには表示できません。`/`文字を含むタイトルのファイルを作成すると、GitLabはそのパスを構築するために必要なすべてのサブディレクトリを作成します。たとえば、タイトルを`docs/my-page`にすると、パスが`/wikis/docs/my-page`のWikiページを作成します。

これらの制限を回避するため、ページコンテンツの前にあるフロントマターブロックにWikiページのタイトルを保存することもできます。例: 

```yaml
---
title: Page title
---
```

### ファイル名とディレクトリ名の長さ制限 {#length-restrictions-for-file-and-directory-names}

多くの一般的なファイルシステムでは、ファイル名とディレクトリ名に[255バイトの制限](https://en.wikipedia.org/wiki/Comparison_of_file_systems#Limits)があります。GitとGitLabはいずれも、これらの制限を超えるパスをサポートしています。ただし、ファイルシステムにこれらの制限が適用されている場合、この制限を超えるファイル名を含むWikiのローカルコピーをチェックアウトすることはできません。この問題を防ぐために、GitLab WebインターフェースとAPIでは次の制限が適用されます:

- ファイル名は245バイト（ファイル拡張子用に10バイトを予約）。
- ディレクトリ名は255バイト。

非ASCII文字は、1文字で複数バイトを使用します。

これらの制限を超えるファイルをローカルで作成することはできますが、その後、チームメイトがWikiをローカルでチェックアウトできなくなる可能性があります。

## Wikiページを編集する {#edit-a-wiki-page}

{{< history >}}

- GitLab 18.11でプレビューモードにおいて**編集**操作にアクセスできる固定バーが[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/590255)されました。
- 没入型エディタ:
  - GitLab 19.1で`wiki_immersive_editor`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231662)されました。デフォルトでは有効になっています。
  - GitLab 19.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/238053)になりました。機能フラグ`wiki_immersive_editor`が削除されました。

{{< /history >}}

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

Wikiエディタは、次の項目を含む固定ヘッダーとともに開きます:

- ページのタイトル。インラインで編集できます。
- ページのパスやフォーマットを変更する、またはテンプレートを選択するための**ページオプションを編集**（{{< icon name="chevron-down" >}}）
- Wikiサイドバーの表示と非表示を切り替えるためのサイドバー切替（{{< icon name="sidebar" >}}）。
- 変更を保存するための**変更を保存**、変更を破棄するための**キャンセル**。

Wikiページを編集するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. 編集したいページに移動し、**編集**を選択します。
1. コンテンツを編集します。
1. **変更を保存**を選択します。保存前にコミットメッセージを追加するには、**変更を保存**の横にある矢印を選択し、**メッセージ付きで変更を保存**を選択します。

ページをプレビューしてスクロールすると、ページ上部の固定バーから**編集**などのアクションに引き続きアクセスできます。

誤ってデータが失われるのを防ぐため、保存されていないWikiページの変更はローカルブラウザストレージに保持されます。

### 目次を作成する {#create-a-table-of-contents}

{{< history >}}

- GitLab 17.2でWikiサイドバーの目次が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/281570)されました。

{{< /history >}}

コンテンツに見出しが含まれるWikiページでは、サイドバーに目次セクションが自動的に表示されます。

必要に応じて、ページ自体に別の目次セクションを表示することもできます。Wikiページのサブ見出しから目次を生成するには、`[[_TOC_]]`タグを使用します。例については、[目次](../../markdown.md#table-of-contents)を参照してください。

## Wikiページにリアクションする {#react-to-a-wiki-page}

{{< history >}}

- GitLab 19.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/510116)されました。

{{< /history >}}

Wikiページに直接絵文字リアクションを追加できます。リアクションは、ページコンテンツの下、コメントセクションの上に表示されます。

Wikiページにリアクションするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. リアクションするページに移動します。
1. ページコンテンツの下で、既存の絵文字を選択してリアクションを追加するか、**リアクションを追加**（{{< icon name="slight-smile" >}}）を選択して別の絵文字を選択します。

リアクションを削除するには、その絵文字をもう一度選択します。各ユーザーは、ページごとに各種類のリアクションを1つだけ追加できます。

ページに初めてリアクションを追加すると、GitLabはそのページの通知をサブスクライブします。

## Wikiページを削除する {#delete-a-wiki-page}

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. 削除するページに移動します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**ページを削除**を選択します。
1. 削除を確認します。

## Wikiページを移動または名前変更する {#move-or-rename-a-wiki-page}

{{< history >}}

- 移動または名前変更されたWikiページのリダイレクトは、GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/257892)され、`wiki_redirection`と名付けられた[機能フラグを使用して](../../../administration/feature_flags/_index.md)います。デフォルトでは有効になっています。
- ページタイトルとパスの分離は、GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/30758)され、`wiki_front_matter`および`wiki_front_matter_title`と名付けられた[機能フラグを使用して](../../../administration/feature_flags/_index.md)います。デフォルトでは有効になっています。
- 機能フラグ`wiki_redirection`、`wiki_front_matter`、および`wiki_front_matter_title`はGitLab 17.3で削除されました。

{{< /history >}}

GitLab 17.1以降では、ページを移動するかページの名前を変更すると、古いページから新しいページへのリダイレクトが自動的に設定されます。リダイレクトのリストは、Wikiリポジトリの`.gitlab/redirects.yml`ファイルに保存されます。

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. 移動または名前を変更するページに移動します。
1. **編集**を選択します。
1. エディタのヘッダーで、**ページオプションを編集**（{{< icon name="chevron-down" >}}）を選択します。
1. ページを移動するには、**パス**フィールドを変更します。たとえば、`Company`の下に`About`というWikiページがあり、このページをWikiのルートに移動する場合は、**パス**を`About`から`/About`に変更します。
1. ページの名前を変更するには、**パス**を変更します。
1. **変更を保存**を選択します。

## Wikiページをエクスポートする {#export-a-wiki-page}

Wikiページは、PDFファイルとしてエクスポートできます。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. エクスポートするページに移動します。
1. 右上隅で、**Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**PDFとして印刷**を選択します。

WikiページのPDFが作成されます。

## Draw.ioを使用してWikiで図を作成する {#creating-diagrams-in-the-wiki-using-drawio}

diagrams.netインテグレーションを使用すると、SVG図を作成してWikiページに埋め込むことができます。図エディタは、プレーンテキストエディタとリッチテキストエディタの両方で使用できます。

GitLab.comでは、このインテグレーションがすべてのユーザーに対して有効になっており、追加の設定は必要ありません。

GitLab Self-Managedでは、無料のdiagrams.net Webサイトと統合したり、オフライン環境で独自のdiagrams.netサイトをホストしたりできます。

インテグレーションを設定するには、次の操作が必要です:

1. 無料のdiagrams.net Webサイトと統合するか、diagrams.netサーバーを設定します。
1. インテグレーションを有効にします。

インテグレーションが完了すると、指定したURLでdiagrams.netエディタが開きます。

## Wikiページテンプレート {#wiki-page-templates}

新しいページを作成する際に使用するテンプレートや、既存のページに適用するテンプレートを作成できます。テンプレートは、Wikiリポジトリの`templates/`ディレクトリに保存されるWikiページです。

### テンプレートを作成する {#create-a-template}

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**テンプレート**を選択します。
1. **新規テンプレート**を選択します。
1. テンプレートのタイトル、フォーマット、コンテンツを入力します。

テンプレートのパスはタイトルから生成され、編集できません。テンプレートの名前を変更するには、そのタイトルを変更します。タイトルはパスの一部としてのみ保存されるため、テンプレートをページに適用しても、ページコンテンツにタイトルのメタデータは挿入されません。ネストされたテンプレートを作成するには、タイトル内で「/」をパス区切り文字として使用します。

特定の形式のテンプレートは、同じ形式のページにのみ適用できます。たとえば、MarkdownテンプレートはMarkdownページにのみ適用されます。

### テンプレートを適用する {#apply-a-template}

Wikiページの[作成](#create-a-new-wiki-page)または[編集](#edit-a-wiki-page)時にテンプレートを適用できます。

前提条件: 

- テンプレートを少なくとも1つ[作成済み](#create-a-template)であること。

1. **コンテンツ**セクションで、**テンプレートを選択する**ドロップダウンリストを選択します。
1. リストからテンプレートを選択します。ページにすでにコンテンツがある場合は、既存のコンテンツが上書きされることを示す警告が表示されます。
1. **テンプレートの適用**を選択します。

### ページのテンプレートを以前のバージョンに復元する {#restore-a-page-template-to-a-previous-version}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/383833)されました。

{{< /history >}}

Wikiページのテンプレートは、履歴から以前のバージョンに復元できます。これにより、完全なバージョン履歴を保持したまま、復元されたコンテンツで新しいバージョンが作成されます。

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

Wikiページのテンプレートを以前のバージョンに復元するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**テンプレート**を選択します。
1. テンプレートを選択します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**テンプレートの履歴**を選択します。
1. 復元するバージョンを選択します。
1. 右上隅で、**このバージョンを復元**を選択します。
1. コミットダイアログで、このバージョンを復元する理由を説明する**コミットメッセージ**を追加します。
1. **復元**を選択します。

ページのテンプレートが選択したバージョンに復元されます。以前のすべてのバージョンはページの履歴に残ります。

同じ手順で[Wikiページを復元](#restore-a-wiki-page-to-a-previous-version)することもできます。

## Wikiページのサブスクリプション {#wiki-page-subscriptions}

Wikiページのサブスクリプション機能を使用すると、関心のあるWikiページに変更が加えられたときに通知を受け取ることができます。この機能により、重要なドキュメントの更新について常にチームメンバーに情報を共有し、コラボレーションを強化できます。

特定のWikiページをサブスクライブすると、誰かが次の操作を行ったときに通知を受け取ることができます:

- ページにコメントを追加する
- コメントに返信する

### Wikiページをサブスクライブする {#subscribe-to-a-wiki-page}

1. フォローするWikiページを開きます。
1. 右上隅で、**編集**の横にあるベルアイコン（{{< icon name="notifications" >}}）を選択します。
1. サブスクライブを解除するには、ベルアイコン（{{< icon name="notifications-off" >}}）をもう一度選択します。

サブスクリプションステータスを変更すると、GitLabに確認メッセージが表示されます:

- サブスクライブした場合、`Notifications turned on`
- サブスクライブを解除した場合、`Notifications turned off`

### サブスクリプションの権限 {#subscription-permissions}

Wikiページを表示するアクセス権を持つすべてのユーザーは、そのページをサブスクライブできます。ユーザーのサブスクリプションステータスは個人用であり、他のユーザーには影響しません。

### 通知設定 {#notification-settings}

通知はプロジェクトの通知設定に従います。設定済みの通知チャンネルを通じて配信されます。

## Wikiページの履歴を表示する {#view-history-of-a-wiki-page}

Wikiページの変更履歴は、WikiのGitリポジトリに記録されます。履歴ページには、次の情報が表示されます:

- ページのリビジョン。
- ページの作成者。
- コミットメッセージ。
- 最終更新。
- **ページバージョン**列でリビジョン番号を選択した場合、以前のリビジョン。

Wikiページの変更を表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. 履歴を表示するページに移動します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**ページの履歴**を選択します。

### ページバージョン間の変更点を表示する {#view-changes-between-page-versions}

バージョン管理された差分ファイルビューと同様に、Wikiページの特定のバージョンで行われた変更を確認できます。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. 目的のWikiページに移動します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**ページの履歴**を選択して、すべてのページバージョンを表示します。
1. 目的のバージョンについて、**差分**列でコミットメッセージを選択します。

### Wikiページを以前のバージョンに復元する {#restore-a-wiki-page-to-a-previous-version}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/383833)されました。

{{< /history >}}

Wikiページは、履歴から以前のバージョンに復元できます。これにより、完全なバージョン履歴を保持したまま、復元されたコンテンツで新しいバージョンが作成されます。

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

Wikiページを以前のバージョンに復元するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. 復元するページに移動します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**ページの履歴**を選択します。
1. 復元するバージョンを選択します。
1. 右上隅で、**このバージョンを復元**を選択します。
1. コミットダイアログで、このバージョンを復元する理由を説明する**コミットメッセージ**を追加します。
1. **復元**を選択します。

ページは選択したバージョンに復元されます。以前のすべてのバージョンはページの履歴に残ります。

同じ手順で[Wikiページテンプレートを復元](#restore-a-page-template-to-a-previous-version)することもできます。

## サイドバー {#sidebar}

{{< history >}}

- GitLab 17.1でサイドバーでのタイトルによる検索が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/156054)されました。
- GitLab 17.2でサイドバーの15項目の制限が[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158084)されました。
- GitLab 18.6でサイドバーがページの右上から左上に[移動](https://gitlab.com/gitlab-org/gitlab/-/issues/569910)されました。
- GitLab 18.9でフローティングサイドバー切替が`wiki_floating_sidebar_toggle`フラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221019)されました。デフォルトでは無効になっています。
- GitLab 18.11でフローティングサイドバー切替が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227437)になりました。機能フラグ`wiki_floating_sidebar_toggle`は削除されました。

{{< /history >}}

Wikiページには、Wiki内のページの一覧を含むサイドバーが表示されます。この一覧はネストされたツリーとして表示され、同じ階層のページはアルファベット順に表示されます。

サイドバーの検索ボックスを使用して、Wiki内のページをタイトルで検索できます。ページの左上隅にあるサイドバー切替（{{< icon name="sidebar" >}}）を使用して、サイドバーを開閉できます。

パフォーマンス上の理由から、サイドバーに表示できるエントリは5,000件に制限されています。すべてのページの一覧を表示するには、サイドバーで**すべてのページを表示**を選択します。

### サイドバーをカスタマイズする {#customize-sidebar}

サイドバーのナビゲーションの内容は手動で編集できます。

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

このプロセスでは、`_sidebar`という名前のWikiページが作成され、デフォルトのサイドバーナビゲーションが完全に置き換えられます。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **Wiki**を選択します。
1. ページの左上隅で、**カスタムサイドバーを追加する**（{{< icon name="settings" >}}）を選択します。
1. 完了したら、**変更を保存**を選択します。

Markdown形式の`_sidebar`の例:

```markdown
### Home

- [Hello World](hello)
- [Foo](foo)
- [Bar](bar)

---

- [Sidebar](_sidebar)
```

## プロジェクトWikiを有効または無効にする {#enable-or-disable-a-project-wiki}

GitLabでは、Wikiはデフォルトで有効になっています。プロジェクトの[管理者](../../permissions.md)は、[共有と権限](../settings/_index.md#configure-project-features-and-permissions)の手順に従って、プロジェクトWikiを有効または無効にできます。

GitLab Self-Managedの管理者は、[追加のWiki設定を行えます](../../../administration/wikis/_index.md)。

[グループ設定](group.md#configure-group-wiki-visibility)からグループWikiを無効化できます。

## 外部Wikiにリンクする {#link-an-external-wiki}

プロジェクトの左側のサイドバーから外部Wikiへのリンクを追加するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **インテグレーション**を選択します。
1. **外部Wiki**を選択します。
1. 外部WikiのURLを追加します。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

これで、プロジェクトの左側のサイドバーに**外部Wiki**オプションが表示されます。

このインテグレーションを有効にしても、外部Wikiへのリンクで内部Wikiへのリンクが置き換えられることはありません。サイドバーから内部Wikiを非表示にするには、[プロジェクトのWikiを無効](#disable-the-projects-wiki)にします。

外部Wikiへのリンクを非表示にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **インテグレーション**を選択します。
1. **外部Wiki**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオフにします。
1. **変更を保存**を選択します。

## プロジェクトのWikiを無効にする {#disable-the-projects-wiki}

プロジェクトの内部Wikiを無効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. 下にスクロールして、**Wiki**切替をオフ（グレー）にします。
1. **変更を保存**を選択します。

これで内部Wikiが無効になり、ユーザーとプロジェクトメンバーは次の操作ができなくなります。

- プロジェクトのサイドバーからWikiへのリンクを見つける。
- Wikiページを追加、削除、または編集する。
- Wikiページを表示する。

以前に追加されたWikiページは、Wikiを再度有効にする場合に備えて保持されます。再度有効にするには、Wikiを無効にする手順を繰り返し、切替をオン（青）にします。

## リッチテキストエディタ {#rich-text-editor}

GitLabでは、WikiでGitLab Flavored Markdownのリッチテキスト編集を利用できます。

サポートには次のものが含まれます:

- 太字、斜体、ブロック引用、見出し、インラインコードなどを使用したテキストの書式設定。
- 順序付きリスト、順序なしリスト、チェックリストの書式設定。
- テーブル構造の作成と編集。
- 構文ハイライトによるコードブロックの挿入と書式設定。
- Mermaid、PlantUML、Krokiの図のプレビュー。

### リッチテキストエディタを使用する {#use-the-rich-text-editor}

{{< history >}}

- 没入型エディタ:
  - GitLab 19.1で`wiki_immersive_editor`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231662)されました。デフォルトでは有効になっています。
  - GitLab 19.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/238053)になりました。機能フラグ`wiki_immersive_editor`が削除されました。

{{< /history >}}

1. 新しいWikiページを[作成](#create-a-new-wiki-page)するか、既存のWikiページを[編集](#edit-a-wiki-page)します。
1. フォーマットとして**Markdown**を選択します。**ページオプションを編集**（{{< icon name="chevron-down" >}}）をエディタヘッダーで選択し、フォーマットを変更します。
1. エディタのヘッダーで、**リッチテキスト編集に切り替える**を選択します。
1. リッチテキストエディタで使用できる各種書式設定オプションを使用して、ページのコンテンツをカスタマイズします。
1. 新しいページの場合は**ページを作成**を選択し、既存のページの場合は**変更を保存**を選択します。

プレーンテキストに戻すには、**テキスト編集に切り替える**を選択します。

関連トピック: 

- [リッチテキストエディタ](../../rich_text_editor.md)

### GitLab Flavored Markdownのサポート {#gitlab-flavored-markdown-support}

リッチテキストエディタですべてのGitLab Flavored Markdownコンテンツタイプをサポートする作業が進行中です。CommonMarkおよびGitLab Flavored Markdownサポートに関する開発状況については、以下を参照してください:

- [基本的なMarkdown形式の拡張機能](https://gitlab.com/groups/gitlab-org/-/epics/5404)エピック。
- [GitLab Flavored Markdown拡張機能](https://gitlab.com/groups/gitlab-org/-/epics/5438)エピック。

## Wikiイベントを追跡する {#track-wiki-events}

GitLabはWikiの作成、削除、更新イベントを追跡します。これらのイベントは、次のページに表示されます。

- [ユーザープロファイル](../../profile/_index.md#access-your-user-profile)。
- Wikiの種類に応じたアクティビティページ:
  - [グループアクティビティ](../../group/manage.md#view-group-activity)。
  - [プロジェクトアクティビティ](../working_with_projects.md#view-project-activity)。

Wikiへのコミットは[リポジトリ分析](../../analytics/repository_analytics.md)にはカウントされません。

## トラブルシューティング {#troubleshooting}

### Apacheリバースプロキシによるページslugのレンダリング {#page-slug-rendering-with-apache-reverse-proxy}

ページslugは、[`ERB::Util.url_encode`](https://www.rubydoc.info/stdlib/erb/ERB%2FUtil.url_encode)メソッドを使用してエンコードされます。Apacheリバースプロキシを使用する場合は、Apache設定の`ProxyPass`行に`nocanon`引数を追加すると、ページslugを正しくレンダリングできます。

### RailsコンソールでプロジェクトWikiを再作成する {#recreate-a-project-wiki-with-the-rails-console}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!warning]
> この操作により、Wiki内のすべてのデータが削除されます。
>
> データを直接変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。念のため、復元できるインスタンスのバックアップを用意したうえで、テスト環境で実行することを強くおすすめします。

プロジェクトWikiのすべてのデータを消去し、空の状態で再作成するには:

1. [Railsコンソールセッション](../../../administration/operations/rails_console.md#starting-a-rails-console-session)を開始します。
1. 次のコマンドを実行します:

   ```ruby
   # Enter your project's path
   p = Project.find_by_full_path('<username-or-group>/<project-name>')

   # This command deletes the wiki project from the filesystem.
   p.wiki.repository.remove

   # Refresh the wiki repository state.
   p.wiki.repository.expire_exists_cache
   ```

Wikiのすべてのデータが消去され、Wikiを使用できる状態になります。

## 関連トピック {#related-topics}

- [管理者向けWiki設定](../../../administration/wikis/_index.md)
- [プロジェクトWiki API](../../../api/wikis.md)
- [グループWiki API](../../../api/group_wikis.md)
- [ストレージ間グループリポジトリ移動API](../../../api/group_repository_storage_moves.md)
- [Wikiキーボードショートカット](../../shortcuts.md#wiki-pages)
- [GitLab Flavored Markdown](../../markdown.md)
- [AsciiDoc](../../asciidoc.md)
