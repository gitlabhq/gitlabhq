---
title: 一般提供APIでフローをトリガーする
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../api/duo_agent_platform_flows/#trigger-a-flow"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/607860
categories: [ Agent Tools ]
level: secondary
weight: 50
---

以前のバージョンのGitLabでは、CI/CDパイプライン、スクリプト、その他の自動化からGitLab Duo Agent Platformのフローをトリガーするために使用するAPIエンドポイントは実験的機能であったため、本番環境で利用できるかどうかを判断することが困難でした。
今回のリリースで、Flows APIの[フロートリガーエンドポイント](../../../api/duo_agent_platform_flows.md#trigger-a-flow)が一般提供となり、GitLab REST APIの破壊的な変更ポリシーに準拠することが保証されたため、本番環境の自動化の基盤として安心してご利用いただけます。
