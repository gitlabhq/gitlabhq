---
title: GitLab Secret Scanning for Source Code（ベータ版）
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed ]
stage: application_security_testing
documentation_link: "../../../user/application_security/secret_detection/gitlab_secret_scanner/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21902
categories: [ Secret Detection ]
level: secondary
weight: 20
---

GitLab Secret Scanning for Source Codeがベータ版になりました。GitLabが独自に構築した新しいスキャンエンジンを搭載しています。既知のシークレットパターンのみを検出するデフォルトのアナライザーとは異なり、このアナライザーはパスワードや標準的なルールセットのカバレッジ外にある非構造化シークレットも検出します。また、複数のヒューリスティック手法を使用して誤検出を低減します。新しいアナライザーは同じ`secret_detection`ジョブ内でデフォルトのアナライザーを置き換え、重複を作成せずに既存の脆弱性の検出結果と照合します。

使い始めるには、[アナライザーを有効にする](../../../user/application_security/secret_detection/gitlab_secret_scanner/_index.md#turn-on-the-analyzer)を参照してください。
ベータ期間中は、信頼度の高い検出結果のみが報告されます。

[イシュー609578](https://gitlab.com/gitlab-org/gitlab/-/work_items/609578)へのフィードバックをお待ちしています。
