---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: カンマ区切り値 (CSV) ファイルがGitLabプロジェクトに表示される方法。
title: CSVファイル
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

カンマ区切り値（CSV）ファイルは、カンマを使用して値を区切る区切り記号付きテキストファイルです。ファイルの各行はデータレコードです。各レコードは、1つ以上のフィールドで構成され、カンマで区切られています。カンマをフィールド区切り文字として使用することが、このファイル形式の名前の由来です。CSVファイルは通常、表形式データ（数値とテキスト）をプレーンテキストで保存します。この場合、各行は同じ数のフィールドを持ちます。

CSVファイル形式は完全に標準化されていません。他の文字も列の区切り文字として使用できます。フィールドは特殊文字をエスケープするために囲まれている場合と囲まれていない場合があります。

リポジトリに追加すると、`.csv`拡張子のファイルはGitLabで表示したときにテーブルとしてレンダリングされます:

![テーブルとしてレンダリングされたCSVファイル](img/csv_as_table_v17_10.png)

## CSVの解析に関する考慮事項 {#csv-parsing-considerations}

GitLabは、CSVファイルを解析するために[Papa Parse](https://github.com/mholt/PapaParse/)ライブラリを使用しています。このライブラリは[RFC4180](https://datatracker.ietf.org/doc/html/rfc4180)に準拠しており、特定のCSV形式で解析上の問題を引き起こす可能性がある厳格な書式要件があります。

例: 

- コンマ (`,`) 区切り文字と二重引用符 (`"`) の周りのスペースは、解析エラーを引き起こす可能性があります。
- カンマと二重引用符の両方を含むフィールドは、パーサーがフィールド境界を誤って識別する原因となる可能性があります。

次の形式では解析エラーが発生します:

```plaintext
"field1", "field2", "field3"
```

次の形式は正常に解析されます:

```plaintext
"field1","field2","field3"
```

CSVファイルがGitLabで正しく表示されない場合:

- フィールドが二重引用符 (`"`) で囲まれている場合は、二重引用符とコンマ (`,`) 区切り文字がすぐに隣接しており、間にスペースがないことを確認してください。
- 特殊文字を含むすべてのフィールドを二重引用符 (`"`) で囲んでください。
- 変更を加えた後、GitLabでCSVファイルがどのように表示されるかテストしてください。

これらの解析要件は、CSVファイルの視覚的なレンダリングのみに影響し、リポジトリに保存されている実際のファイルコンテンツには影響しません。
