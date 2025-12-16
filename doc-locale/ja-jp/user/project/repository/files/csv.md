---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: コンマ区切り値（CSV）ファイルがGitLabプロジェクトにどのように表示されるか。
title: CSVファイル
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コンマ区切り値（CSV）ファイルは、値を区切るためにコンマを使用する区切りテキストファイルです。ファイルの各行はデータレコードです。各レコードは、コンマで区切られた1つ以上のフィールドで構成されています。フィールド区切り文字としてコンマを使用することが、このファイル形式の名前の由来です。CSVファイルは通常、表形式のデータ（数値とテキスト）をプレーンテキストで保存します。この場合、各行のフィールド数は同じになります。

CSVファイル形式は完全には標準化されていません。他の文字を列区切り文字として使用できます。特殊文字をエスケープするために、フィールドが囲まれている場合と囲まれていない場合があります。

リポジトリに追加すると、`.csv`拡張子のファイルはGitLabで表示するとテーブルとしてレンダリングされます:

![テーブルとしてレンダリングされたCSVファイル](img/csv_as_table_v17_10.png)

## CSV解析に関する考慮事項 {#csv-parsing-considerations}

GitLabは、[Papa Parse](https://github.com/mholt/PapaParse/)ライブラリを使用してCSVファイルを解析します。このライブラリは[RFC4180](https://datatracker.ietf.org/doc/html/rfc4180)に準拠しており、特定のCSV形式で解析のイシューを引き起こす可能性のある厳密な形式要件があります。

例: 

- コンマ（`,`）区切り文字と二重引用符（`"`）の周りのスペースは、解析エラーを引き起こす可能性があります。
- コンマと二重引用符の両方を含むフィールドは、パーサーがフィールドの境界を誤って識別する原因となる可能性があります。

次の形式は、解析エラーを引き起こします:

```plaintext
"field1", "field2", "field3"
```

次の形式は正常に解析されます:

```plaintext
"field1","field2","field3"
```

CSVファイルがGitLabに正しく表示されない場合:

- フィールドが二重引用符（`"`）で囲まれている場合は、二重引用符とコンマ（`,`）区切り文字が間にスペースを入れずにすぐ隣接していることを確認してください。
- 特殊文字を含むすべてのフィールドを二重引用符（`"`）で囲みます。
- 変更を加えた後、CSVファイルがGitLabにどのように表示されるかをテストします。

これらの解析要件は、CSVファイルの視覚的なレンダリングにのみ影響し、リポジトリに保存されている実際のファイルコンテンツには影響しません。
