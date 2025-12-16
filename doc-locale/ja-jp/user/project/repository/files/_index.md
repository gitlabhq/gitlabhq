---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabリポジトリ内のファイルを、GitLabユーザーインターフェースから直接検索します。
title: ファイル管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab UIは、ブラウザで使いやすい機能により、Gitの履歴と追跡の機能を拡張します。次のことができます: 

- ファイルを検索します。
- ファイルの処理方法を変更します。
- ファイル全体の履歴、または1行を調査します。

## UIでのファイルの種類のレンダリング方法を理解する {#understand-how-file-types-render-in-the-ui}

これらの種類のファイルをプロジェクトに追加すると、GitLabは読みやすさを向上させるためにその出力をレンダリングします:

- [GeoJSON](geojson.md)ファイルはマップとして表示されます。
- [Jupyter Notebook](jupyter_notebooks/_index.md)ファイルは、レンダリングされたHTMLとして表示されます。
- 多くのマークアップ言語のファイルは、表示するためにレンダリングされます。

### サポートされているマークアップ言語 {#supported-markup-languages}

ファイルにこれらのファイル拡張子のいずれかがある場合、GitLabはUIでファイルの[マークアップ言語](https://en.wikipedia.org/wiki/Lightweight_markup_language)のコンテンツをレンダリングします。

| マークアップ言語                                              | 拡張機能 |
|--------------------------------------------------------------|------------|
| プレーンテキスト                                                   | `txt`      |
| [Markdown](../../../markdown.md)                             | `mdown`、`mkd`、`mkdn`、`md`、`markdown` |
| [reStructuredText](https://docutils.sourceforge.io/rst.html) | `rst`      |
| [AsciiDoc](../../../asciidoc.md)                             | `adoc`、`ad`、`asciidoc` |
| [Textile](https://textile-lang.com/)                         | `textile`  |
| [Rdoc](https://rdoc.sourceforge.net/doc/index.html)          | `rdoc`     |
| [Org mode](https://orgmode.org/)                             | `org`      |
| [creole](http://www.wikicreole.org/)                         | `creole`   |
| [MediaWiki](https://www.mediawiki.org/wiki/MediaWiki)        | `wiki`、`mediawiki` |

### READMEファイルとインデックスファイル {#readme-and-index-files}

{{< history >}}

- `_index.md`ファイルのサポートは、GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206533)されました。

{{< /history >}}

`README`、`index`、または`_index`ファイルがリポジトリに存在する場合、GitLabはそのコンテンツをレンダリングします。これらのファイルは、プレーンテキストまたはサポートされているマークアップ言語の拡張子を持つことができます。

自動レンダリングの優先順位は次のとおりです:

- プレビュー可能なファイル: `README.md`、`index.md`、`_index.md`など
- プレーンテキストファイル: `README`、`index`、`_index`など

各カテゴリで最初に見つかったファイル（アルファベット順）が選択され、プレビュー可能なファイルがプレーンテキストファイルよりも優先されます。たとえば、複数のREADMEが利用可能な場合、GitLabは次の順序でレンダリングします:

  1. `README.adoc`
  1. `README.md`
  1. `README.rst`
  1. `README`

### OpenAPIファイルをレンダリングする {#render-openapi-files}

ファイル名に`openapi`または`swagger`が含まれ、拡張子が`yaml`、`yml`、または`json`の場合、GitLabはOpenAPI仕様ファイルをレンダリングします。これらの例はすべて正しいです:

- `openapi.yml`、`openapi.yaml`、`openapi.json`
- `swagger.yml`、`swagger.yaml`、`swagger.json`
- `OpenAPI.YML`、`openapi.Yaml`、`openapi.JSON`
- `openapi_gitlab.yml`、`openapi.gitlab.yml`
- `gitlab_swagger.yml`
- `gitlab.openapi.yml`

OpenAPIファイルをレンダリングするには:

1. [ファイル検索](#search-for-a-file)でリポジトリ内のOpenAPIファイルを検索します。
1. **レンダリングされたファイルを表示**を選択します。
1. 操作リストに`operationId`を表示するには、`displayOperationId=true`をクエリ文字列に追加します。

{{< alert type="note" >}}

`displayOperationId`がクエリ文字列に存在し、任意の値を持つ場合、`true`と評価されます。この動作は、Swaggerのデフォルトの動作と一致します。

{{< /alert >}}

## ファイルのGitレコードを表示 {#view-git-records-for-a-file}

リポジトリ内のファイルに関する履歴情報は、GitLab UIで利用できます:

- [Gitファイルの履歴](git_history.md): ファイル全体のコミット履歴を表示します。
- [Git blame](git_blame.md): テキストベースのファイルの各行と、その行を変更した最新のコミットを表示します。

## パーマリンクを作成する {#create-permalinks}

パーマリンクは、リポジトリ内の特定のファイル、ディレクトリ、またはコードのセクションを指す永続的なURLです。これらはリポジトリが変更されても有効なままであるため、ドキュメント、イシュー、またはマージリクエストでコードを共有および参照するのに理想的です。

パーマリンクを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. リンクするファイルまたはディレクトリに移動します。
1. オプション。特定のコードを選択する場合:
   - **Single line**（単一行）: 行番号を選択します。
   - **Multiple lines**（複数行）: 最初の行番号を選択し、<kbd>Shift</kbd>キーを押しながら最後の行番号を選択します。
   - **Markdown anchor**（Markdownアンカー）: 見出しにカーソルを合わせると、アンカーリンク（{{< icon name="link" >}}）が表示されるので、それを選択します。
1. **アクション**（{{< icon name="ellipsis_v" >}}）を選択し、**Copy Permalink**（パーマリンクをコピー） を選択します。または、<kbd>y</kbd>キーを押します。ショートカットの詳細については、[キーボードショートカット](../../../shortcuts.md)を参照してください。

## ファイルに対するオープンマージリクエストを表示 {#view-open-merge-requests-for-a-file}

{{< history >}}

- GitLab 17.10で`filter_blob_path`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/448868)されました。
- GitLab 17.11の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/505449)になりました。
- GitLab 18.0の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/505449)になりました。
- GitLab 18.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/539215)になりました。機能フラグ`filter_blob_path`は削除されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

リポジトリファイルを表示すると、GitLabは、現在のブランチを対象にしてファイルを変更する、オープンなマージリクエストの数を示すバッジを表示します。これにより、保留中の変更があるファイルを特定できます。

ファイルに対するオープンマージリクエストを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 表示したいファイルに移動します。
1. 画面の右上にあるファイル名の横で、{{< icon name="merge-request-open" >}} **オープン**マージリクエストの数を示す緑色のバッジを探します。
1. バッジを選択すると、過去30日間に作成されたオープンマージリクエストの一覧が表示されます。
1. リスト内のマージリクエストを選択すると、そのマージリクエストに移動します。

## ファイルを検索する {#search-for-a-file}

{{< history >}}

- [変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148025) GitLab 16.11のダイアログへ

{{< /history >}}

ファイルファインダーを使用して、GitLab UIからリポジトリ内のファイルを直接検索します。ファイルファインダーはあいまい検索を使用し、入力時に結果を強調表示します。

ファイルを検索するには、プロジェクト内の任意の場所で<kbd>t</kbd>キーを押すか、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **リポジトリ**を選択します。
1. 右上にある**ファイルを検索**を選択します。
1. ダイアログで、ファイル名の入力を開始します:

   ![ファイルボタンを検索](img/file_finder_v17_2.png)

1. オプション。検索オプションを絞り込むには、<kbd>Command</kbd>+<kbd>K</kbd>キーを押すか、ダイアログの右下隅にある**Commands**（コマンド）を選択します:
   - **ページまたはアクション**の場合は、<kbd>></kbd>を入力します。
   - **ユーザー**の場合は、<kbd>@</kbd>を入力します。
   - **プロジェクト**の場合は、<kbd>:</kbd>を入力します。
   - **ファイル**の場合は、<kbd>~</kbd>を入力します。
1. ドロップダウンリストから、リポジトリに表示するファイルを選択します。

**ファイル**ページに戻るには、<kbd>Esc</kbd>キーを押します。

この機能は、[`fuzzaldrin-plus`](https://github.com/jeancroy/fuzz-aldrin-plus)ライブラリを使用します。

## Gitがファイルを処理する方法を変更する {#change-how-git-handles-a-file}

ファイルまたはファイルタイプのデフォルトの処理を変更するには、[`.gitattributes`ファイル](git_attributes.md)を作成します。`.gitattributes`ファイルを使用して:

- [構文ハイライト](highlighting.md)や[生成されたファイルを折りたたむ](../../merge_requests/changes.md#collapse-generated-files)など、差分のファイル表示を構成します。
- [読み取り専用ファイルを作成](../../file_lock.md)したり、[Git LFSで](../../../../topics/git/lfs/_index.md)大きなファイルを格納するなど、ファイルのストレージと保護を制御します。

## 関連トピック {#related-topics}

- [リポジトリファイルAPI](../../../../api/repository_files.md)
- [Gitによるファイル管理](../../../../topics/git/file_management.md)

## トラブルシューティング {#troubleshooting}

### リポジトリ言語: 過剰なCPU使用率 {#repository-languages-excessive-cpu-use}

リポジトリのファイルで使用されている言語を判断するために、GitLabはRuby gemを使用します。gemがファイルを解析してそのファイルタイプを判断すると、[プロセスが過剰なCPUを使用する可能性があります](https://gitlab.com/gitlab-org/gitaly/-/issues/1565)。このgemには、どのファイル拡張子を解析するかを定義する[ヒューリスティック設定ファイル](https://github.com/github/linguist/blob/master/lib/linguist/heuristics.yml)が含まれています。これらのファイルタイプは、過剰なCPUを使用する可能性があります:

- `.txt`拡張子のファイル。
- gemで定義されていない拡張子を持つXMLファイル。

この問題を修正するには、`.gitattributes`ファイルを編集し、特定のファイル拡張子に言語を割り当てます。このアプローチを使用して、誤って識別されたファイルタイプを修正することもできます:

1. 指定する言語を識別します。このgemには、[既知のデータ型の設定ファイル](https://github.com/github/linguist/blob/master/lib/linguist/languages.yml)が含まれています。

1. たとえば、テキストファイルのエントリを追加するには:

   ```yaml
   Text:
     type: prose
     wrap: true
     aliases:
     - fundamental
     - plain text
     extensions:
     - ".txt"
   ```

1. リポジトリのルートで`.gitattributes`を追加または編集します:

   ```plaintext
   *.txt linguist-language=Text
   ```

  `*.txt`ファイルには、ヒューリスティックファイルにエントリがあります。この例では、これらのファイルの解析を防ぎます。
