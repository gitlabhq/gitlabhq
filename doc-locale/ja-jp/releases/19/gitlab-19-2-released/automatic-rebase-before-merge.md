---
title: マージ前の自動リベース
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Free, Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/methods/#automatic-rebase-before-merge"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/16803
categories: [ Code Review Workflow ]
---


以前のバージョンのGitLabでは、プロジェクトで半線形または早送りマージ方式を使用している場合、ソースブランチがターゲットブランチより遅れると追加の手順が必要でした。
マージするには、**リベース**を選択して完了を待ち、その後マージリクエストに戻って**マージ**を選択する必要がありました。
この2段階の操作により、すべてのマージに余分な手間が生じていました。

プロジェクトのマージリクエスト設定で**マージ前の自動リベースを有効にする**を選択できるようになりました。
この設定を有効にすると、GitLabはマージ時にソースブランチをターゲットブランチにリベースするため、1回の操作でマージできます。
個々のコミットのGPG署名を保持することが重要な場合は、この設定をオフのままにしておくことができます。
