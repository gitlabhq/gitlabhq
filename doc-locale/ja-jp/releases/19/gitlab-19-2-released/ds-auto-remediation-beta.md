---
title: 依存関係スキャン自動修正（ベータ版）
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: "../../../user/application_security/remediate/dependency_scanning_auto_remediation/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/604799
categories: [ Software Composition Analysis ]
level: primary
weight: 50
---

<!-- Category: Software Composition Analysis -->

GitLab 19.2では、依存関係スキャン自動修正をベータ版として導入しました。この機能は、依存関係スキャンのワークフローに自動化された脆弱性修正を直接組み込むもので、2つの機能を提供します。

- 依存関係バージョンの自動更新：GitLab.com、GitLab Self-Managed、GitLab Dedicatedで利用可能。
- エージェント型による破壊的変更の解決：GitLab.com、GitLab Self-Managed、GitLab Dedicatedで利用可能。GitLabクレジットを消費します。

依存関係バージョンの自動更新は、脆弱な依存関係を安全なバージョンに更新するマージリクエストを自動的に作成します。有効にすると、GitLabはプロジェクト内の脆弱な依存関係を監視し、手動での介入なしに修正用MRを作成します。デフォルトでは、パッチバージョンとマイナーバージョンへの更新が対象です。

エージェント型による破壊的変更の解決は、複雑な更新を処理するために修正フローを拡張します。依存関係のバージョンを更新するマージリクエストのパイプラインが破壊的変更によって失敗した場合、GitLab Duoはパイプラインのエラー、依存関係の変更履歴、およびコードでの依存関係の使用方法を分析します。

GitLab Duoは同じMRに修正をコミットし、パイプラインが成功するまで再実行します。エージェント型による破壊的変更の解決を有効にすると、バージョン更新の対象がメジャーバージョンにも拡張されます。

2つの機能を組み合わせることで、完全な修正ループが形成されます。GitLabがMRを作成し、更新が複雑な場合はGitLab Duoが解決します。

セットアップ手順については、[依存関係スキャン自動修正](../../../user/application_security/remediate/dependency_scanning_auto_remediation.md)を参照してください。

フィードバックは[ベータ版フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/605599)でお寄せください。
