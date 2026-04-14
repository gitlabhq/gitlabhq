---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabリポジトリ内のファイルを、GitLabユーザーインターフェースから直接検索します。
title: ファイル管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab UIは、Gitの履歴と追跡する機能を、ブラウザで利用できるユーザーフレンドリーな機能で拡張します。次のことができます: 

- ファイルを検索します。
- ファイルの処理を変更します。
- ファイル全体の履歴、または単一行を探索します。

## UIでのファイルタイプのレンダリングを理解する {#understand-how-file-types-render-in-the-ui}

これらのタイプのファイルをプロジェクトに追加すると、GitLabは読みやすさを向上させるためにその出力をレンダリングします:

- [GeoJSON](geojson.md)ファイルはマップとして表示されます。
- [Jupyter Notebook](jupyter_notebooks/_index.md)ファイルはレンダリングされたHTMLとして表示されます。
- 多くのマークアップ言語のファイルは表示用にレンダリングされます。

### サポートされているマークアップ言語 {#supported-markup-languages}

ファイルにこれらのファイル拡張子のいずれかがある場合、GitLabはファイルの[マークアップ言語](https://en.wikipedia.org/wiki/Lightweight_markup_language)の内容をUIにレンダリングします。

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

### Readmeとインデックスファイル {#readme-and-index-files}

{{< history >}}

- `_index.md`ファイルのサポートはGitLab 18.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206533)。

{{< /history >}}

リポジトリに`README`、`index`、または`_index`ファイルが存在する場合、GitLabはその内容をレンダリングします。これらのファイルは、プレーンテキストであるか、サポートされているマークアップ言語の拡張子を持つことができます。

自動レンダリングの優先順位は次のとおりです:

- プレビュー可能なファイル: `README.md`、`index.md`、`_index.md`など。
- プレーンテキストファイル: `README`、`index`、`_index`など。

各カテゴリで見つかった最初のファイル（アルファベット順）が選択され、プレビュー可能なファイルがプレーンテキストファイルよりも優先されます。たとえば、複数のReadmeが利用可能な場合、GitLabはそれらを次の順序でレンダリングします:

1. `README.adoc`
1. `README.md`
1. `README.rst`
1. `README`

### OpenAPIファイルをレンダリングする {#render-openapi-files}

GitLabは、ファイル名に`openapi`または`swagger`が含まれ、拡張子が`yaml`、`yml`、または`json`である場合に、OpenAPI仕様ファイルをレンダリングします。これらの例はすべて正しいです:

- `openapi.yml`、`openapi.yaml`、`openapi.json`
- `swagger.yml`、`swagger.yaml`、`swagger.json`
- `OpenAPI.YML`、`openapi.Yaml`、`openapi.JSON`
- `openapi_gitlab.yml`、`openapi.gitlab.yml`
- `gitlab_swagger.yml`
- `gitlab.openapi.yml`

OpenAPIファイルをレンダリングするには:

1. リポジトリでOpenAPIファイルを[検索します](#search-for-a-file)。
1. **レンダリングされたファイルを表示**を選択します。
1. オペレーションリストに`operationId`を表示するには、`displayOperationId=true`をクエリ文字列に追加します。

> [!note]
> `displayOperationId`がクエリ文字列に存在し、何らかの値を保持する場合、`true`と評価されます。この動作は、Swaggerのデフォルト動作と一致します。

## ファイルのGitの記録を表示する {#view-git-records-for-a-file}

リポジトリ内のファイルに関する履歴情報は、GitLab UIで利用できます:

- [Gitファイルの履歴](git_history.md): ファイル全体のコミット履歴を表示します。
- [Git blame](git_blame.md): テキストベースのファイルの各行と、その行を変更した最新のコミットを表示します。

## permalinkを作成する {#create-permalinks}

permalinkは、リポジトリ内の特定のファイル、ディレクトリ、またはコードセクションを指す永続的なURLです。リポジトリが変更されても有効なままであり、ドキュメント、イシュー、またはマージリクエストでコードを共有および参照するのに理想的です。

permalinkを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. リンクしたいファイルまたはディレクトリに移動します。
1. オプション。オプション。特定のコード選択の場合:
   - **Single line**: 行番号を選択します。
   - **Multiple lines**: 最初の行番号を選択し、<kbd>Shift</kbd>を押しながら最後の行番号を選択します。
   - **Markdown anchor**: 見出しにカーソルを合わせると、アンカーリンク（{{< icon name="link" >}}）が表示されるので、それを選択します。
1. **アクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**Copy Permalink**を選択します。あるいは、<kbd>y</kbd>を押します。その他のショートカットについては、[キーボードショートカット](../../../shortcuts.md)を参照してください。

## ファイルのオープンマージリクエストを表示する {#view-open-merge-requests-for-a-file}

{{< history >}}

- GitLab 17.10で`filter_blob_path`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/448868)されました。
- GitLab.comでGitLab 17.11に[有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/505449)。
- GitLab Self-ManagedおよびGitLab DedicatedでGitLab 18.0に[有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/505449)。
- GitLab 18.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/539215)になりました。機能フラグ`filter_blob_path`は削除されました。

{{< /history >}}

> [!flag]
> この機能の利用可能性は機能フラグによって制御されます。詳細については、履歴を参照してください。

リポジトリファイルを表示すると、GitLabは現在のブランチをターゲットとし、ファイルを変更するオープンマージリクエストの数を示すバッジを表示します。これにより、保留中の変更があるファイルを特定できます。

ファイルに対するオープンマージリクエストを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 表示したいファイルに移動します。
1. 画面の右上、ファイル名の隣にある、{{< icon name="merge-request-open" >}} **オープン**マージリクエストの数を示す緑色のバッジを探します。
1. バッジを選択すると、過去30日間に作成されたオープンマージリクエストの一覧が表示されます。
1. リスト内のマージリクエストを選択すると、そのマージリクエストに移動します。

## ファイルを検索する {#search-for-a-file}

{{< history >}}

- GitLab 16.11でダイアログに[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148025)。

{{< /history >}}

GitLab UIから直接リポジトリ内のファイルを検索するためにファイルファインダーを使用します。ファイルファインダーはあいまい検索を使用し、入力中に結果をハイライト表示します。

ファイルを検索するには、プロジェクト内の任意の場所で<kbd>t</kbd>を押すか、次の手順を実行します:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**コード** > **リポジトリ**を選択します。
1. 右上で、**ファイルを検索**を選択します。
1. ダイアログで、ファイル名の入力を開始します:

   ![ファイルを検索ボタン](img/file_finder_v17_2.png)

1. オプション。オプション。検索オプションを絞り込むには、<kbd>Command</kbd>+<kbd>K</kbd>を押すか、ダイアログの右下にある**Commands**を選択します:
   - **ページまたはアクション**の場合、<kbd>></kbd>を入力します。
   - **ユーザー**の場合、<kbd>@</kbd>を入力します。
   - **プロジェクト**の場合、<kbd>:</kbd>を入力します。
   - **ファイル**の場合、<kbd>~</kbd>を入力します。
1. ドロップダウンリストからファイルを選択し、リポジトリで表示します。

**ファイル**ページに戻るには、<kbd>Esc</kbd>を押します。

この機能は[`fuzzaldrin-plus`](https://github.com/jeancroy/fuzz-aldrin-plus)ライブラリを使用しています。

## Gitがファイルを処理する方法を変更する {#change-how-git-handles-a-file}

ファイルまたはファイルタイプのデフォルトの処理を変更するには、[`.gitattributes`ファイル](git_attributes.md)を作成します。`.gitattributes`ファイルを使用して以下を実行します:

- 差分でのファイル表示（[構文ハイライト](highlighting.md)や[生成されたファイルの折りたたみ](../../merge_requests/changes.md#collapse-generated-files)など）を設定します。
- ファイルの保存と保護を制御します（[ファイルを読み取り専用にする](../../file_lock.md) 、または[Git LFSで大きなファイルを保存する](../../../../topics/git/lfs/_index.md)など）。

## 関連トピック {#related-topics}

- [リポジトリファイルAPI](../../../../api/repository_files.md)
- [Gitでのファイル管理](../../../../topics/git/file_management.md)

## トラブルシューティング {#troubleshooting}

### リポジトリ言語: 過剰なCPU使用率 {#repository-languages-excessive-cpu-use}

リポジトリのファイルにどの言語が含まれているかを判断するために、GitLabはRuby gemを使用します。gemがファイルを解析するしてそのファイルタイプを判断すると、[そのプロセスは過剰なCPUを使用する可能性があります](https://gitlab.com/gitlab-org/gitaly/-/issues/1565)。gemには、どのファイル拡張子を解析するかを定義する[ヒューリスティックな設定ファイル](https://github.com/github/linguist/blob/master/lib/linguist/heuristics.yml)が含まれています。これらのファイルタイプは過剰なCPUを消費する可能性があります:

- `.txt`拡張子を持つファイル。
- gemで定義されていない拡張子を持つXMLファイル。

この問題を修正するには、`.gitattributes`ファイルを編集し、特定のファイル拡張子に言語を割り当てます。このアプローチを使用して、誤って識別されたファイルタイプを修正することもできます:

1. 指定する言語を識別します。gemには、[既知のデータタイプの設定ファイル](https://github.com/github/linguist/blob/master/lib/linguist/languages.yml)が含まれています。

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

1. リポジトリのルートに`.gitattributes`を追加または編集します:

   ```plaintext
   *.txt linguist-language=Text
   ```

   `*.txt`ファイルにはヒューリスティックファイルにエントリがあります。この例では、これらのファイルの解析を防止します。
