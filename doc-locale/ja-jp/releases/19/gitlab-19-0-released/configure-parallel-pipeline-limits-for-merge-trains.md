---
title: マージトレインの並列パイプライン上限を設定する
stage: verify
level: secondary
tier: [ Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
documentation_link: "../../../administration/cicd/limits/#merge-train-parallel-pipeline-limit"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/374188"
categories: [ Continuous Integration (CI) ]
weight: 90
---

以前のバージョンのGitLabでは、マージトレインの並列パイプライン数の上限が20に固定されており、Runnerに過大な負荷をかけるか、マージトレインを使用しないかの選択を迫られていました。
今回のリリースで、マージトレインごとに並列パイプラインの上限を設定できるようになり、Runnerの負荷とマージのスループットのバランスを取ることが可能になりました。
上限はプロジェクト単位またはインスタンス全体で設定できます。
上限を1に設定すると、各マージリクエストがクリーンなターゲットブランチに対して1件ずつ順番に実行されます。

このコミュニティへのコントリビュートをいただいた[Norman Debald (@Modjo85)](https://gitlab.com/Modjo85)さんに感謝します。
