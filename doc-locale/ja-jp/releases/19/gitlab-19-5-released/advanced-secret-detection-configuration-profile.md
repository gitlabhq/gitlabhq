---
title: セキュリティ設定プロファイルのカスタマイズ
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/configuration/security_configuration_profiles/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/20198
categories: [ Security Testing Configuration, Secret Detection, SAST, Software Composition Analysis ]
weight: 50
---

UIでシークレット検出とSASTのプロファイルをカスタマイズできるようになりました。除外パスやカスタムアナライザーイメージ、Gitの全履歴スキャンなどのスキャンオプションをグループ単位で一度設定すれば、そのグループ配下のすべてのプロジェクトに適用できます。

これまで、セキュリティ設定プロファイルはデフォルト設定でスキャナーを有効化するものでした。デフォルト以外の設定を行うには、各プロジェクトの`.gitlab-ci.yml`を個別に編集する必要がありました。今回のリリースで、プロファイル自体にそれらの設定も含められるようになりました。

現時点では、依存関係スキャンプロファイルのカスタマイズはGraphQL APIからのみ利用可能です。UIでのカスタマイズは将来のリリースで提供予定です。
