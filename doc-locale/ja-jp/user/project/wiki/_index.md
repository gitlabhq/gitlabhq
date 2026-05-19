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

Wikiは、使い慣れた形式でプロジェクトとグループのドキュメントを提供します。Wikiページには次のような機能があります。

- Markdown、RDoc、AsciiDoc、またはOrg形式で、技術ドキュメント、ガイド、ナレッジベースを生成します。
- GitLabプロジェクトおよびグループと直接統合されるコラボレーションドキュメントを作成します。
- バージョン管理とコラボレーションのために、ドキュメントをGitリポジトリに保存します。
- サイドバーのカスタマイズにより、カスタムナビゲーションと構成をサポートします。
- オフラインアクセスと共有のために、コンテンツをPDFファイルとしてエクスポートします。
- コードベースとは別にコンテンツを管理しながら、同じプロジェクトに保持します。

各Wikiは、個別のGitリポジトリです。Wikiページは、GitLab Webインターフェースを使用するか、[Gitを使用してローカルで](#create-or-edit-wiki-pages-locally)作成および編集できます。Markdownで記述されたWikiページは、すべての[Markdown機能](../../markdown.md)をサポートし、リンクに対して[Wiki固有の動作](markdown.md)を提供します。

Wikiページには[サイドバー](#sidebar)が表示されます。サイドバーはカスタマイズも可能です。

## プロジェクトWikiを表示する {#view-a-project-wiki}

プロジェクトWikiにアクセスするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. Wikiを表示するには、次のいずれかの操作を行います。
   - 左サイドバーで、**Plan** > **Wiki**を選択します。
   - プロジェクトの任意のページで、<kbd>g</kbd>+<kbd>w</kbd> [Wikiキーボードショートカット](../../shortcuts.md)を使用してください。

プロジェクトの左側のサイドバーに**Plan** > **Wiki**が表示されない場合、プロジェクト管理者によって[無効にされています](#enable-or-disable-a-project-wiki)。

## Wikiのデフォルトブランチを設定する {#configure-a-default-branch-for-your-wiki}

Wikiリポジトリは、インスタンスまたはグループから[デフォルトのブランチ名](../repository/branches/default.md)を継承します。カスタムブランチ名が設定されていない場合、GitLabは`main`を使用します。Wikiのデフォルトブランチの名前を変更するには、[デフォルトブランチの名前をリポジトリ内で更新してください](../repository/branches/default.md#update-the-default-branch-name-in-your-repository)。

## Wikiホームページを作成する {#create-the-wiki-home-page}

{{< history >}}

- ページタイトルとパスの分離は、GitLab 17.2で`wiki_front_matter`および`wiki_front_matter_title`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/30758)されました。デフォルトでは有効になっています。
- 機能フラグ`wiki_front_matter`および`wiki_front_matter_title`は、GitLab 17.3で削除されました。

{{< /history >}}

作成時のWikiは空の状態です。最初のアクセス時に、Wikiを表示するときにユーザーに表示されるホームページを作成できます。このページには、Wikiのホームページとして使用するための特定のパスが必要です。作成するには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. **最初のページを作成**を選択します。
1. オプション。ホームページの**タイトル**を変更します。
1. GitLabでは、この最初のページにパス`home`が必要です。このパスのページは、Wikiのフロントページとして機能します。
1. テキストのスタイルを設定するための**フォーマット**を選択します。
1. **コンテンツ**セクションで、ホームページのウェルカムメッセージを追加します。メッセージは後で編集できます。
1. **コミットメッセージ**を追加します。Gitにはコミットメッセージが必要です。したがって、自分で入力しない場合はGitLabが作成します。
1. **ページを作成**を選択します。

## 新しいWikiページを作成する {#create-a-new-wiki-page}

{{< history >}}

- ページタイトルとパスの分離は、GitLab 17.2で`wiki_front_matter`および`wiki_front_matter_title`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/30758)されました。デフォルトでは有効になっています。
- 機能フラグ`wiki_front_matter`と`wiki_front_matter_title`はGitLab 17.3で削除されました。 +- トップバーからWikiページを作成する機能がGitLab 18.10で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/work_items/591976)。

{{< /history >}}

前提条件: 

- デベロッパー、メンテナー、またはオーナーロール。

プロジェクトまたはグループから新しいWikiページを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、グループまたはプロジェクトを見つけます。
1. 右上隅で、**新規作成** ({{< icon name="plus" >}}) を選択し、次に**New wiki page**を選択します。

または:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、このページまたは他のWikiページで**新しいページ**を選択します。

新しいページフォームを開いた後、次の手順を完了します:

1. コンテンツ形式を選択します。
1. 新しいページの**タイトル**を追加します。
1. オプション。**タイトルからページパスを生成する**のチェックを外し、ページの**パス**を変更します。ページパスでは、サブディレクトリと書式設定に[特殊文字](#special-characters-in-page-paths)を使用します。また、パスには[長さ制限](#length-restrictions-for-file-and-directory-names)があります。
1. オプション。Wikiページにコンテンツを追加します。
1. オプション。ファイルを添付すると、GitLabはWikiのGitリポジトリに保存します。
1. **コミットメッセージ**を追加します。Gitにはコミットメッセージが必要です。したがって、自分で入力しない場合はGitLabが作成します。
1. **ページを作成**を選択します。

### テンプレートから作成する {#from-a-template}

{{< history >}}

- GitLab 18.6で、テンプレートから直接新しいWikiページを作成する機能が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/474328)されました。

{{< /history >}}

プロジェクトに少なくとも1つのテンプレートがある場合、[テンプレート](#create-a-template)から新しいWikiページを作成できます。

前提条件: 

- 少なくとも1つのテンプレートを[作成している](#create-a-template)必要があります。

{{< tabs >}}

{{< tab title="テンプレートリストから" >}}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. 利用可能なすべてのテンプレートを表示するには、**テンプレート**を選択します。
1. 使用したいテンプレートの横で、**テンプレートから作成**を選択します。
1. 新しいページフォームが開かれ、以下が表示されます:
   - テンプレートの内容がコンテンツエリアに事前に入力されています。
   - テンプレートのドロップダウンリストで選択されたテンプレート。
1. 新しいページのタイトルを入力します。
1. 必要に応じてコンテンツを修正します。
1. **ページを作成**を選択します。

{{< /tab >}}

{{< tab title="テンプレートページから" >}}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. 利用可能なすべてのテンプレートを表示するには、**テンプレート**を選択します。
1. 使用したいテンプレートを選択します。
1. ページヘッダーで、**テンプレートから作成**を選択します。
1. 新しいページフォームが、現在のテンプレートが事前に選択され、その内容が読み込まれた状態で開きます。
1. 新しいページのタイトルを入力します。
1. 必要に応じてコンテンツを修正します。
1. **ページを作成**を選択します。

{{< /tab >}}

{{< tab title="新しいページフォームから" >}}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. **新しいページ**を選択します。
1. **テンプレートを選択してください**ドロップダウンリストで、目的のテンプレートを選択します。
1. テンプレートの内容は、コンテンツエリアに自動的に読み込まれます。
1. ページのタイトルを入力します。
1. 必要に応じてコンテンツを修正します。
1. **ページを作成**を選択します。

{{< /tab >}}

{{< /tabs >}}

### Wikiページをローカルで作成または編集する {#create-or-edit-wiki-pages-locally}

WikiはGitリポジトリに基づいているため、他のすべてのGitリポジトリと同様に、ローカルで複製して編集できます。Wikiリポジトリをローカルに複製するには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**リポジトリをクローン**を選択します。
1. 画面の指示に従います。

ローカルでWikiに追加するファイルは、使用するマークアップ言語に応じて、次のサポートされている拡張子のいずれかを使用する必要があります。サポートされていない拡張子を持つファイルは、GitLabにプッシュされても表示されません。

- Markdown拡張子: `.mdown`、`.mkd`、`.mkdn`、`.md`、`.markdown`。
- AsciiDoc拡張子: `.adoc`、`.ad`、`.asciidoc`。
- その他のマークアップ拡張子: `.textile`、`.rdoc`、`.org`、`.creole`、`.wiki`、`.mediawiki`、`.rst`。

### ページパスの特殊文字 {#special-characters-in-page-paths}

{{< history >}}

- front matterベースのタイトルは、GitLab 16.7で`wiki_front_matter`および`wiki_front_matter_title`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133521)されました。デフォルトでは無効になっています。
- 機能フラグ[`wiki_front_matter`](https://gitlab.com/gitlab-org/gitlab/-/issues/435056)と[`wiki_front_matter_title`](https://gitlab.com/gitlab-org/gitlab/-/issues/428259)は、GitLab 17.2でデフォルトで有効になっています。
- 機能フラグ`wiki_front_matter`および`wiki_front_matter_title`は、GitLab 17.3で削除されました。

{{< /history >}}

WikiページはGitリポジトリ内のファイルとして保存されます。また、デフォルトではページのファイル名がタイトルになっています。ファイル名の一部の文字には特別な意味があります。

- スペースは、ページ保存時にハイフンに変換されます。
- ハイフン（`-`）は、ページの表示時にスペースに変換されます。
- スラッシュ（`/`）はパスの区切り文字として使用されます。タイトルでは表示できません。`/`文字を含むタイトルでファイルを作成すると、GitLabはそのパスの構築に必要なすべてのサブディレクトリを作成します。たとえば、`docs/my-page`というタイトルの場合、`/wikis/docs/my-page`というパスでWikiページを作成します。

これらの制限を回避するため、ページコンテンツの前にfront matterブロックにWikiページのタイトルを保存することもできます。例: 

```yaml
---
title: Page title
---
```

### ファイル名とディレクトリ名の長さ制限 {#length-restrictions-for-file-and-directory-names}

多くの一般的なファイルシステムでは、ファイル名とディレクトリ名に[255バイトの制限](https://en.wikipedia.org/wiki/Comparison_of_file_systems#Limits)があります。GitとGitLabでは、いずれもこれらの制限を超えるパスがサポートされています。ただし、ファイルシステムにこれらの制限が適用されている場合、この制限を超えるファイル名を含むWikiのローカルコピーをチェックアウトすることはできません。この問題を回避するために、GitLab WebインターフェースとAPIでは次の制限を導入します。

- ファイル名の場合は245バイト（ファイル拡張子用に10バイトを予約）。
- ディレクトリ名の場合は255バイト。

非ASCII文字は複数のバイトを占有します。

これらの制限を超えるファイルをローカルで作成することはできますが、その後チームメイトはWikiをローカルでチェックアウトできなくなる可能性があります。

## Wikiページを編集する {#edit-a-wiki-page}

{{< history >}}

- **編集**はプレビューモードで固定され、[GitLab](https://gitlab.com/gitlab-org/gitlab/-/work_items/590255) 18.11で導入されました。

{{< /history >}}

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. 編集するページに移動し、次のいずれかの操作を行います。
   - <kbd>e</kbd> Wiki[キーボードショートカット](../../shortcuts.md#wiki-pages)を使用します。
   - **編集**を選択します。
1. コンテンツを編集します。
1. **変更を保存**を選択します。

ページをプレビューしてスクロールすると、ページ上部の固定バーによって**編集**ボタンやその他のアクションにアクセスしやすくなります。

保存されていないWikiページの変更は、偶発的なデータ損失を防ぐために、ローカルブラウザストレージに保持されます。

### 目次を作成する {#create-a-table-of-contents}

{{< history >}}

- GitLab 17.2で、Wikiサイドバーの目次が[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/281570)。

{{< /history >}}

コンテンツに見出しが含まれるWikiページでは、サイドバーに目次セクションが自動的に表示されます。

必要に応じて、ページ自体に別の目次セクションを表示することもできます。Wikiページのサブ見出しから目次を生成するには、`[[_TOC_]]`タグを使用します。例については、[目次](../../markdown.md#table-of-contents)を参照してください。

## Wikiページを削除する {#delete-a-wiki-page}

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. 削除するページに移動します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**ページを削除**を選択します。
1. 削除を確認します。

## Wikiページを移動または名前変更する {#move-or-rename-a-wiki-page}

{{< history >}}

- 移動または名前を変更されたWikiページのリダイレクトは、GitLab 17.1で`wiki_redirection`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/257892)されました。デフォルトでは有効になっています。
- ページタイトルとパスの分離は、GitLab 17.2で`wiki_front_matter`および`wiki_front_matter_title`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/30758)されました。デフォルトでは有効になっています。
- 機能フラグ`wiki_redirection`、`wiki_front_matter`、`wiki_front_matter_title`は、GitLab 17.3で削除されました。

{{< /history >}}

GitLab 17.1以降では、ページを移動するかページの名前を変更すると、古いページから新しいページへのリダイレクトが自動的に設定されます。リダイレクトのリストは、Wikiリポジトリの`.gitlab/redirects.yml`ファイルに保存されます。

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. 移動または名前を変更するページに移動します。
1. **編集**を選択します。
1. ページを移動するには、**パス**フィールドに新しいパスを追加します。たとえば、`Company`の下に`About`というWikiページがあり、このページをWikiのルートに移動する場合は、**パス**を`About`から`/About`に変更します。
1. ページの名前を変更するには、**パス**を変更します。
1. **変更を保存**を選択します。

## Wikiページをエクスポートする {#export-a-wiki-page}

{{< history >}}

- GitLab 16.3で`print_wiki`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/414691)されました。デフォルトでは無効になっています。
- GitLab 16.5の[GitLab.comおよびGitLab Self-Managedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134251/)。
- 機能フラグ`print_wiki`は、GitLab 16.6で削除されました。

{{< /history >}}

Wikiページは、PDFファイルとしてエクスポートできます。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. エクスポートするページに移動します。
1. 右上隅で、**Wikiアクション** ({{< icon name="ellipsis_v" >}}) を選択し、次に**PDFとして印刷**を選択します。

WikiページのPDFが作成されます。

## Draw.ioを使用してWikiで図を作成する {#creating-diagrams-in-the-wiki-using-drawio}

diagrams.netとのインテグレーションにより、SVG図を作成してWikiページに埋め込むことができます。図エディタは、プレーンテキストエディタとリッチテキストエディタの両方で使用できます。

GitLab.comでは、このインテグレーションはすべてのユーザーに対して有効になっており、追加の設定は必要ありません。

GitLab Self-Managedでは、無料のdiagrams.net Webサイトと統合したり、オフライン環境で独自のdiagrams.netサイトをホストしたりできます。

インテグレーションを設定するには、次のことをする必要があります。

1. 無料のdiagrams.net Webサイトと統合するか、diagrams.netサーバーを設定します。
1. インテグレーションを有効にします。

インテグレーションが完了すると、指定したURLでdiagrams.netエディタが開きます。

## Wikiページテンプレート {#wiki-page-templates}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/442228)されました。

{{< /history >}}

新しいページの作成時、または既存のページに適用するテンプレートを作成できます。テンプレートは、Wikiリポジトリの`templates/`ディレクトリに保存されているWikiページです。

### テンプレートを作成する {#create-a-template}

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**テンプレート**を選択します。
1. **新規テンプレート**を選択します。
1. テンプレートのタイトル、形式、コンテンツを、通常のWikiページを作成する場合と同様に入力します。

特定の形式のテンプレートは、同じ形式のページにのみ適用できます。たとえば、MarkdownテンプレートはMarkdownページにのみ適用されます。

### テンプレートを適用する {#apply-a-template}

Wikiページの[作成](#create-a-new-wiki-page)または[編集](#edit-a-wiki-page)時にテンプレートを適用できます。

前提条件: 

- 少なくとも1つのテンプレートを[作成している](#create-a-template)必要があります。

1. **コンテンツ**セクションで、**テンプレートを選択**ドロップダウンリストを選択します。
1. リストからテンプレートを選択します。ページにすでにコンテンツがある場合は、既存のコンテンツが上書きされることを示す警告が表示されます。
1. **テンプレートを適用**を選択します。

### ページのテンプレートを以前のバージョンに復元 {#restore-a-page-template-to-a-previous-version}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/383833)されました。

{{< /history >}}

Wikiページのテンプレートをその履歴から以前のバージョンに復元することができます。これにより、復元されたコンテンツを含む新しいバージョンが作成され、完全なバージョン履歴が保持されます。

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

Wikiページのテンプレートを以前のバージョンに復元するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**テンプレート**を選択します。
1. テンプレートを選択します。
1. **Wikiアクション** ({{< icon name="ellipsis_v" >}}) を選択し、次に**テンプレートの履歴**を選択します。
1. 復元するバージョンを選択します。
1. 右上隅で、**このバージョンを復元**を選択します。
1. コミットダイアログで、このバージョンを復元する理由を説明する**コミットメッセージ**を追加します。
1. **復元**を選択します。

ページのテンプレートは選択したバージョンに復元されます。以前のすべてのバージョンはページ履歴に残ります。

同じプロセスを使用して[Wikiページを復元する](#restore-a-wiki-page-to-a-previous-version)こともできます。

## Wikiページサブスクリプション {#wiki-page-subscriptions}

Wikiページサブスクリプション機能を使用すると、関心のあるWikiページに変更があった場合に通知を受け取ることができます。この機能により、チームメンバーが重要なドキュメントの更新について常に情報を得られるようになり、コラボレーションが強化されます。

特定のWikiページを購読して、誰かが以下を行った場合に通知を受け取ることができます:

- ページにコメントを追加
- コメントに返信

### Wikiページを購読する {#subscribe-to-a-wiki-page}

1. フォローしたいWikiページを開きます。
1. 右上隅の**編集**の横にあるベルアイコン ({{< icon name="notifications" >}}) を選択します。
1. ベルアイコン ({{< icon name="notifications-off" >}}) をもう一度選択して、購読を解除します。

サブスクリプションステータスを変更すると、GitLabは確認メッセージを表示します:

- 購読している場合、`Notifications turned on`
- 購読を解除している場合、`Notifications turned off`

### サブスクリプション権限 {#subscription-permissions}

Wikiページを表示できるすべてのユーザーは、それを購読できます。あなたのサブスクリプションステータスは個人的なものであり、他のユーザーには影響しません。

### 通知設定 {#notification-settings}

通知はプロジェクトの通知設定に従います。これらは設定された通知チャンネルを通じて配信されます。

## Wikiページの履歴を表示する {#view-history-of-a-wiki-page}

Wikiページの変更履歴は、WikiのGitリポジトリに記録されます。履歴ページには、次の内容が表示されます。

- ページのリビジョン。
- ページの作成者。
- コミットメッセージ。
- 最終更新。
- **ページバージョン**列でリビジョン番号を選択すると、以前のリビジョンが表示されます。

Wikiページの変更を表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. 履歴を表示するページに移動します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**ページ履歴**を選択して、すべてのページバージョンを表示します。

### ページバージョン間の変更点を表示する {#view-changes-between-page-versions}

バージョン管理された差分ファイルビューと同様に、Wikiページのバージョンで行われた変更点を確認できます。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. 対象のWikiページに移動します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**ページの履歴**を選択して、すべてのページバージョンを表示します。
1. 対象のバージョンの**差分**列でコミットメッセージを選択します。

### Wikiページを以前のバージョンに復元する {#restore-a-wiki-page-to-a-previous-version}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/383833)されました。

{{< /history >}}

Wikiページをその履歴から以前のバージョンに復元することができます。これにより、復元されたコンテンツを含む新しいバージョンが作成され、完全なバージョン履歴が保持されます。

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

Wikiページを以前のバージョンに復元するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. 復元するページに移動します。
1. **Wikiアクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**ページ履歴**を選択して、すべてのページバージョンを表示します。
1. 復元するバージョンを選択します。
1. 右上隅で、**このバージョンを復元**を選択します。
1. コミットダイアログで、このバージョンを復元する理由を説明する**コミットメッセージ**を追加します。
1. **復元**を選択します。

ページは選択したバージョンに復元されます。以前のすべてのバージョンはページ履歴に残ります。

同じプロセスを使用して[Wikiページテンプレートを復元する](#restore-a-page-template-to-a-previous-version)こともできます。

## サイドバー {#sidebar}

{{< history >}}

- サイドバーでのタイトルによる検索は、GitLab 17.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/156054)。
- サイドバーの15項目の制限は、GitLab 17.2で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158084)。
- サイドバーはGitLab 18.6でページの右上から左上に[移動しました](https://gitlab.com/gitlab-org/gitlab/-/issues/569910)。
- フローティングサイドバー切替機能は、`wiki_floating_sidebar_toggle`という名前のフラグと共にGitLab 18.9で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221019)。デフォルトでは無効になっています。
- フローティングサイドバー切替はGitLab 18.11で[一般提供される](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227437)ようになりました。機能フラグ`wiki_floating_sidebar_toggle`は削除されました。

{{< /history >}}

Wikiページには、Wiki内のページの一覧が表示されたサイドバーが表示されます。この一覧はネストされたツリーとして表示され、兄弟ページはアルファベット順に表示されます。

サイドバーの検索ボックスを使用して、Wiki内のページのタイトルでページを検索できます。ページの左上隅にあるサイドバー切替 ({{< icon name="sidebar" >}}) を使用して、サイドバーを開閉できます。

パフォーマンス上の理由から、サイドバーに表示できるエントリは5,000件に制限されています。すべてのページの一覧を表示するには、サイドバーの**すべてのページを表示**を選択します。

### サイドバーのカスタマイズ {#customize-sidebar}

サイドバーのナビゲーションの内容は手動で編集できます。

前提条件: 

- デベロッパー、メンテナー、またはオーナーロールが必要です。

このプロセスでは、`_sidebar`という名前のWikiページを作成し、デフォルトのサイドバーナビゲーションを完全に置き換えます。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **Wiki**を選択します。
1. ページの左上隅で、**カスタムサイドバーを追加する** ({{< icon name="settings" >}}) を選択します。
1. 完了したら、**変更を保存**を選択します。

Markdownでフォーマットされた`_sidebar`の例:

```markdown
### Home

- [Hello World](hello)
- [Foo](foo)
- [Bar](bar)

---

- [Sidebar](_sidebar)
```

## プロジェクトWikiを有効または無効にする {#enable-or-disable-a-project-wiki}

WikiはGitLabではデフォルトで有効になっています。プロジェクトの[管理者](../../permissions.md)は、[共有と権限](../settings/_index.md#configure-project-features-and-permissions)の手順に従って、プロジェクトWikiを有効または無効にすることができます。

GitLab Self-Managedの管理者は、[追加のWiki設定を行うことができます](../../../administration/wikis/_index.md)。

[グループ設定](group.md#configure-group-wiki-visibility)からグループWikiを無効化できます。

## 外部Wikiにリンクする {#link-an-external-wiki}

プロジェクトの左側のサイドバーから外部Wikiへのリンクを追加するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **外部Wiki**を選択します。
1. 外部WikiのURLを追加します。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

これで、プロジェクトの左側のサイドバーで**外部Wiki**オプションを表示できます。

このインテグレーションを有効にしても、内部Wikiへのリンクは外部Wikiへのリンクに置き換わりません。サイドバーから内部Wikiを非表示にするには、[プロジェクトのWikiを無効にします](#disable-the-projects-wiki)。

外部Wikiへのリンクを非表示にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **外部Wiki**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオフにします。
1. **変更を保存**を選択します。

## プロジェクトのWikiを無効にする {#disable-the-projects-wiki}

プロジェクトの内部Wikiを無効化するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. 下にスクロールして、**Wiki**切替をオフ（グレー）にします。
1. **変更を保存**を選択します。

これで内部Wikiは無効になり、ユーザーとプロジェクトメンバーは次の操作ができなくなります。

- プロジェクトのサイドバーからWikiへのリンクを見つける。
- Wikiページを追加、削除、または編集する。
- Wikiページを表示する。

以前に追加されたWikiページは、Wikiを再度有効にする場合に備えて保持されます。再度有効にするには、Wikiを無効にする手順を繰り返し、切替をオン（青）にします。

## リッチテキストエディタ {#rich-text-editor}

{{< history >}}

- GitLab 16.2で、コンテンツエディタからリッチテキストエディタに[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/398152)。

{{< /history >}}

GitLabは、WikiでGitLab Flavored Markdownのリッチテキスト編集エクスペリエンスを提供します。

サポートには次の内容が含まれます。

- 太字、イタリック体、ブロック引用、見出し、インラインコードなどのテキストの書式設定。
- 順序付きリスト、順序なしリスト、チェックリストの書式設定。
- テーブル構造の作成と編集。
- 構文ハイライトによるコードブロックの挿入と書式設定。
- Mermaid、PlantUML、Kroki図のプレビュー。

### リッチテキストエディタを使用する {#use-the-rich-text-editor}

1. 新しいWikiページを[作成する](#create-a-new-wiki-page)か、既存のWikiページを[編集します](#edit-a-wiki-page)。
1. 形式として**Markdown**を選択します。
1. **コンテンツ**の下、左下隅にある**リッチテキスト編集に切り替え**を選択します。
1. リッチテキストエディタで使用可能なさまざまな書式設定オプションを使用して、ページの内容をカスタマイズします。
1. 新しいページの場合は**ページを作成**を、既存のページの場合は**変更を保存**を選択します。

プレーンテキストに戻るには、**テキスト編集に切り替え**を選択します。

こちらも参照してください。

- [リッチテキストエディタ](../../rich_text_editor.md)

### GitLab Flavored Markdownのサポート {#gitlab-flavored-markdown-support}

リッチテキストエディタですべてのGitLab Flavored Markdownコンテンツタイプをサポートする作業が進行中です。CommonMarkおよびGitLab Flavored Markdownサポートの開発進行状況については、以下をお読みください。

- [基本的なMarkdown形式の拡張機能](https://gitlab.com/groups/gitlab-org/-/epics/5404)エピック。
- [GitLab Flavored Markdown拡張機能](https://gitlab.com/groups/gitlab-org/-/epics/5438)エピック。

## Wikiイベントを追跡する {#track-wiki-events}

GitLabはWikiの作成、削除、更新イベントを追跡します。これらのイベントは、次のページに表示されます。

- [ユーザープロファイル](../../profile/_index.md#access-your-user-profile)。
- Wikiの種類に応じたアクティビティページ。
  - [グループアクティビティ](../../group/manage.md#view-group-activity)。
  - [プロジェクトアクティビティ](../working_with_projects.md#view-project-activity)。

Wikiへのコミットは[リポジトリ分析](../../analytics/repository_analytics.md)ではカウントされません。

## トラブルシューティング {#troubleshooting}

### Apacheリバースプロキシによるページslugのレンダリング {#page-slug-rendering-with-apache-reverse-proxy}

ページslugは、[`ERB::Util.url_encode`](https://www.rubydoc.info/stdlib/erb/ERB%2FUtil.url_encode)メソッドを使用してエンコードされます。Apacheリバースプロキシを使用する場合は、Apache設定の`ProxyPass`行に`nocanon`引数を追加して、ページslugが正しくレンダリングされるようにすることができます。

### RailsコンソールでプロジェクトWikiを再作成する {#recreate-a-project-wiki-with-the-rails-console}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!warning]
> この操作により、Wiki内のすべてのデータが削除されます。
>
> データを直接変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。念のため、インスタンスのバックアップを復元できるように準備し、Test環境で実行することを強くお勧めします。

プロジェクトWikiからすべてのデータをクリアし、空白の状態で再作成するには:

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

Wikiからのすべてのデータがクリアされ、Wikiを使用できるようになりました。

## 関連トピック {#related-topics}

- [管理者向けWiki設定](../../../administration/wikis/_index.md)
- [プロジェクトWiki API](../../../api/wikis.md)
- [グループWiki API](../../../api/group_wikis.md)
- [グループリポジトリストレージ移動API](../../../api/group_repository_storage_moves.md)
- [Wikiキーボードショートカット](../../shortcuts.md#wiki-pages)
- [GitLab Flavored Markdown](../../markdown.md)
- [AsciiDoc](../../asciidoc.md)
