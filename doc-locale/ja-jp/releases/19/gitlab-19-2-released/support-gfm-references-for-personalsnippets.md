---
title: パーソナルスニペットでのGitLab Flavored Markdownリファレンス
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: plan
documentation_link: "../../../user/markdown/#gitlab-specific-references"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/4185
categories: [ Markdown ]
level: secondary
weight: 50
ignore_in_report: true
---

<!-- categories: Markdown -->

パーソナルスニペットでGitLab Flavored Markdown（GFM）リファレンスを使用できるようになりました。使用方法は次の2通りです。

- GitLabは、プロジェクトスニペットやGitLabの他の領域と同様に、パーソナルスニペットの説明とコメント内のGFMリファレンスを処理します。
- コメントやイシュー・マージリクエストの説明など、GFMがサポートされている場所であればどこからでも、プロジェクトスニペットで既に使用できる`$<id>`構文を使用してパーソナルスニペットを参照できます。

スニペットIDはパーソナルスニペットとプロジェクトスニペット全体で一意であるため、各IDは単一のスニペットに解決されます。
