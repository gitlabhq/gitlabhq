---
title: リッチテキストエディタでのテーブル貼り付け機能の改善
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: plan
documentation_link: "../../../user/rich_text_editor/#paste-into-a-table-cell"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627112
categories: [ Text Editors ]
level: secondary
---

以前は、コピーしたテーブルをテーブルセルに貼り付けると、コピーしたセルが常に既存のテーブルにマージされていたため、ネストされたテーブルを作成することが困難でした。

現在は、貼り付けたテーブルの動作を選択できます。

- **セルに貼り付け**を選択すると、コピーしたテーブルをセル内にネストされたテーブルとして挿入します。
- **貼り付けてテーブルにマージ**を選択すると、コピーしたセルを既存のテーブル全体に分散します（デフォルトの動作）。

キーボードショートカットを使用して、テーブルをセルにネストされたテーブルとして貼り付けることもできます。macOSでは<kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>V</kbd>、WindowsおよびLinuxでは<kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>V</kbd>です。

<kbd>Control</kbd>+<kbd>V</kbd>または<kbd>Command</kbd>+<kbd>V</kbd>による標準の貼り付けは、以前と同様に動作します。
