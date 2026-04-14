---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 構文ハイライトは、GitLabプロジェクト内のファイルを読み、ファイルに何が含まれているかを特定するのに役立ちます。
title: 構文ハイライト
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、2つの補完的なシステムを通じてファイルに構文ハイライトを提供します:

- [Rouge](https://rubygems.org/gems/rouge)（Ruby gem）: GitLabサーバー上でファイルを処理するサーバーサイドのハイライト機能です。用途:
  - リポジトリファイルの閲覧
  - マージリクエストの差分
  - コミットの差分
  - 比較ビュー
  - blameビュー
- [Highlight.js](https://github.com/highlightjs/highlight.js/): ブラウザで実行されるクライアントサイドのハイライト機能です。サポートされている言語のリポジトリファイルをブラウザで表示するために使用されます。

ここでのパスは、Gitの[`.gitattributes`インターフェース](https://git-scm.com/docs/gitattributes)を使用しています。

> [!note]
> [Web IDE](../../web_ide/_index.md)と[スニペット](../../../snippets.md)は、テキスト編集に[Monaco Editor](https://microsoft.github.io/monaco-editor/)を使用しており、これは内部的に[Monarch library](https://microsoft.github.io/monaco-editor/monarch.html)を構文ハイライトに使用しています。

## ファイルタイプの構文ハイライトをオーバーライドする {#override-syntax-highlighting-for-a-file-type}

> [!note]
> Web IDEは`.gitattributes`ファイルをサポートしていません。詳細については、[エピック18651](https://gitlab.com/groups/gitlab-org/-/work_items/18651)を参照してください。

ファイルタイプの構文ハイライトをオーバーライドするには:

1. `.gitattributes`ファイルがプロジェクトのルートディレクトリに存在しない場合は、この名前で空のファイルを作成します。
1. 変更したいファイルタイプごとに、ファイル拡張子と希望のハイライト言語を宣言する行を`.gitattributes`ファイルに追加します:

   ```conf
   # This extension typically receives Perl syntax highlighting. If you
   # also use Prolog, you can override highlighting for this file extension:
   *.pl gitlab-language=prolog
   ```

1. 変更をコミット、プッシュ、マージしてデフォルトブランチに反映します。

変更が[デフォルトブランチ](../branches/default.md)にマージされると、プロジェクト内のすべての`*.pl`ファイルが選択した言語でハイライト表示されます。

Common Gateway Interface (CGI)オプションでハイライトを拡張することもできます。例:

``` conf
# JSON file with .erb in it
/my-cool-file gitlab-language=erb?parent=json

# An entire file of highlighting errors!
/other-file gitlab-language=text?token=Error
```

## ファイルタイプの構文ハイライトを無効にする {#disable-syntax-highlighting-for-a-file-type}

ファイルタイプ全体のハイライトを無効にするには、ファイルタイプのハイライトをオーバーライドする手順に従い、`gitlab-language=text`を使用します:

```conf
# Disable syntax highlighting for this file type
*.module gitlab-language=text
```

## ハイライトの最大ファイルサイズを設定する {#configure-maximum-file-size-for-highlighting}

次のファイルサイズ制限が構文ハイライターに適用されます:

- Rouge（サーバーサイド）: デフォルトで512 KB（設定可能）
  - この制限より大きいファイルは、構文ハイライトなしのプレーンテキストで表示されます。
- Highlight.js（クライアントサイド）: 2 MB（設定不可）
  - 言語がサポートされていない場合、Rougeハイライトにフォールバックします。
  - この制限より大きいファイルはフロントエンドでハイライトできず、rawコンテンツとして表示する必要があります。

Rougeハイライトの制限を変更するには:

1. プロジェクトの[`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/config/gitlab.yml.example)設定ファイルを開きます。

1. このセクションを追加し、`maximum_text_highlight_size_kilobytes`を希望する値に置き換えます。

   ```yaml
   gitlab:
     extra:
       ## Maximum file size for syntax highlighting
       ## https://docs.gitlab.com/user/project/repository/files/highlighting/#configure-maximum-file-size-for-highlighting
       maximum_text_highlight_size_kilobytes: 512
   ```

1. 変更をコミット、プッシュ、マージしてデフォルトブランチに反映します。
