---
title: Business Logic Security Analyzer（クローズドベータ）
tier: [ Ultimate ]
offering: [ gitlab_com ]
stage: application_security_testing
documentation_link: "../../../user/application_security/business_logic_scanning/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/632352
categories: [ SAST ]
level: secondary
---

Business Logic Security Analyzerは、GitLab Duo Agent Platformの基本フローであり、コードが何を強制するよう設計されているかを推論します。パターンベースのスキャナーが見落としがちな脆弱性、すなわちオブジェクトレベルの認可の不備、認可チェックの欠如、マスアサインメントを検出します。

GitLab Duo ChatまたはAPIからリポジトリ全体のスキャンを開始できます。マージリクエストを自動的にスキャンするには、Business Logicスキャンプロファイルをプロジェクトに関連付けてください。検出結果は脆弱性レポートおよびマージリクエストのセキュリティウィジェットに表示されます。

Business Logic Security Analyzerは、GitLab.com上のGitLab Ultimateをご利用のお客様向けにクローズドベータとして提供されています。アクセスをリクエストするには、担当のアカウントチームにお問い合わせください。各スキャンはGitLabクレジットを消費します。前提条件とセットアップについては、[ビジネスロジックスキャン](../../../user/application_security/business_logic_scanning/_index.md)を参照してください。
