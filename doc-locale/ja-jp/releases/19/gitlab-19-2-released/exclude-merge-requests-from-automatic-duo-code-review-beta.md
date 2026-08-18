---
title: "マージリクエストを自動コードレビューから除外する（ベータ版）"
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Free, Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/code_review/#exclude-merge-requests-from-automatic-reviews"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21585
categories: [ DAP Code Review ]
---


以前のバージョンのGitLabでは、プロジェクトまたはグループで自動レビューが有効になっている場合、GitLab Duoはすべての対象マージリクエストをレビューしていました。
これには、ボットが作成した依存関係の更新、フィーチャーブランチ、実験的な作業など、チームが実際にフィードバックを求めていない変更も含まれていました。

除外ルールを使用して、特定のマージリクエストを自動レビューから除外できるようになりました。
プロジェクトまたはグループに `.gitlab/duo/mr-review-automated-rules.yaml` ファイルを作成し、作成者、ソースブランチ、またはターゲットブランチに基づいた除外ルールを定義します。
ルールでは `dependabot/*` や `*-bot` のようなグロブパターンをサポートしています。

除外されたマージリクエストに対しても、手動でレビューをリクエストすることは引き続き可能です。

この機能はベータ版であり、`duo_code_review_automated_rules` 機能フラグによって制御されています（デフォルトで有効）。
