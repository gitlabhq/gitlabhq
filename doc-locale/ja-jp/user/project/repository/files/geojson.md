---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabプロジェクトでGeoJSONファイルを表示したときのレンダリング方法。
title: GeoJSONファイル
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/14134)されました。

{{< /history >}}

GeoJSONファイルは、JavaScript Object Notation (JSON) を使用して地理データ構造をエンコードするための形式です。これは、ポイント、線、ポリゴンなどの地理的特徴とその関連属性を表すためによく使用されます。

リポジトリに追加すると、GitLabで表示されたときに、`.geojson`拡張子のファイルはGeoJSONデータを含むマップとしてレンダリングされます。

マップデータは、[OpenStreetMap](https://www.openstreetmap.org/)から[Open Database License](https://www.openstreetmap.org/copyright)に基づいて提供されます。

![GeoJSONファイルがマップとしてレンダリングされたもの](img/geo_json_file_rendered_v16_1.png)
