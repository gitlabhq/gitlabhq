---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Markdown API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

MarkdownコンテンツをHTMLに変換します。

APIv4でのみ利用可能です。

## 認証が必要です {#required-authentication}

{{< history >}}

- GitLab 15.3で`authenticate_markdown_api`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93727)されました。デフォルトでは有効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

Markdown APIコールはすべて[認証](rest/authentication.md)されている必要があります。

## 任意のMarkdownドキュメントをレンダリングします {#render-an-arbitrary-markdown-document}

```plaintext
POST /markdown
```

| 属性 | 型    | 必須      | 説明                                |
| --------- | ------- | ------------- | ------------------------------------------ |
| `text`    | 文字列  | はい           | レンダリングするMarkdownテキスト                |
| `gfm`     | ブール値 | いいえ            | GitLab Flavored Markdownを使用してテキストをレンダリングします。デフォルトは`false`です |
| `project` | 文字列  | いいえ            | GitLab Flavored Markdownを使用して参照を作成する際に、`project`をコンテキストとして使用します  |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type:application/json" \
  --data '{"text":"Hello world! :tada:", "gfm":true, "project":"group_example/project_example"}' "https://gitlab.example.com/api/v4/markdown"
```

レスポンスの例:

```json
{ "html": "<p dir=\"auto\">Hello world! <gl-emoji title=\"party popper\" data-name=\"tada\" data-unicode-version=\"6.0\">🎉</gl-emoji></p>" }
```
