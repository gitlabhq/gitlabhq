---
title: マージトレインを強制する
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: "../../../ci/pipelines/merge_trains/#enforce-merge-trains"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/597962
categories: [ Merge Trains ]
level: secondary
weight: 10
---

以前のバージョンのGitLabでは、マージがマージトレインを回避するのを防ぐ手段がありませんでした。即時マージのオプションとREST APIのいずれも、制限なしにマージトレインの保護を回避できていました。高速なモノレポを運用するチームにとって、マージトレインを回避した1回のマージが進行中のすべてのパイプラインをキャンセルして再起動させ、CIコストを増大させ、インフラストラクチャに負荷をかける原因となっていました。

今回のリリースで、プロジェクトレベルの単一設定によってUIとAPI全体でマージトレインの使用を強制できるようになりました。これにより、進行中のパイプラインをキャンセルして再起動させる回避を防止できます。オーナーと管理者は、必要に応じて引き続き設定をオーバーライドできます。
