---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 構文ハイライトは、GitLabプロジェクト内のファイルを読み取り、ファイルの内容を特定するのに役立ちます。
title: 構文ハイライト
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、[Highlight.js](https://github.com/highlightjs/highlight.js/)と[Rouge](https://rubygems.org/gems/rouge) Ruby gemを介して、すべてのファイルの構文ハイライトを提供します。ほとんどの場合、これで十分ですが、ファイル拡張子に基づいて使用する言語を推測しようとします。

ここでのパスでは、Gitの[`.gitattributes`インターフェース](https://git-scm.com/docs/gitattributes)を使用します。

{{< alert type="note" >}}

[Web統合開発環境](../../web_ide/_index.md)と[スニペット](../../../snippets.md)は、テキストエディタに[Monaco Editor](https://microsoft.github.io/monaco-editor/)を使用します。これは内部的に構文ハイライトに[Monarch](https://microsoft.github.io/monaco-editor/monarch.html)ライブラリを使用します。

{{< /alert >}}

## ファイルタイプの構文ハイライトをオーバーライドする {#override-syntax-highlighting-for-a-file-type}

{{< alert type="note" >}}

Web統合開発環境は、[`.gitattribute`ファイルをサポートしていません](https://gitlab.com/gitlab-org/gitlab/-/issues/22014)。

{{< /alert >}}

ファイルタイプの構文ハイライトをオーバーライドするには、次の手順に従います:

1. `.gitattributes`ファイルがプロジェクトのルートディレクトリに存在しない場合は、この名前で空のファイルを作成します。
1. 変更するファイルタイプごとに、ファイル拡張子と目的の言語を宣言する行を`.gitattributes`ファイルに追加します:

   ```conf
   # This extension would typically receive Perl syntax highlighting
   # but if we also use Prolog, we may want to override highlighting for
   # files with this extension:
   *.pl gitlab-language=prolog
   ```

1. 変更をコミット、プッシュ、マージしてデフォルトブランチに反映します。

変更が[デフォルトブランチ](../branches/default.md)にマージされると、プロジェクト内のすべての`*.pl`ファイルは、選択した言語で強調表示されます。

Common Gateway Interface（CGI）オプションで、構文ハイライトを拡張することもできます（以下に例を示します）:

``` conf
# JSON file with .erb in it
/my-cool-file gitlab-language=erb?parent=json

# An entire file of highlighting errors!
/other-file gitlab-language=text?token=Error
```

## ファイルタイプの構文ハイライトを無効にする {#disable-syntax-highlighting-for-a-file-type}

ファイルタイプのハイライトを完全に無効にするには、ファイルタイプのハイライトをオーバーライドする手順に従い、`gitlab-language=text`を使用します:

```conf
# Disable syntax highlighting for this file type
*.module gitlab-language=text
```

## ハイライトの最大ファイルサイズを構成する {#configure-maximum-file-size-for-highlighting}

デフォルトでは、GitLabは512 KBを超えるすべてのファイルをプレーンテキストで表示します。この値を変更するには、次の手順に従います:

1. プロジェクトの[`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/config/gitlab.yml.example)設定ファイルを開きます。

1. このセクションを追加し、`maximum_text_highlight_size_kilobytes`を目的の値に置き換えます。

   ```yaml
   gitlab:
     extra:
       ## Maximum file size for syntax highlighting
       ## https://docs.gitlab.com/ee/user/project/highlighting.html
       maximum_text_highlight_size_kilobytes: 512
   ```

1. 変更をコミット、プッシュ、マージしてデフォルトブランチに反映します。
