---
title: セキュリティインベントリにおけるスキャナーカバレッジの集計
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/security_inventory/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22124
categories: [ Security Asset Inventories ]
---

1つのページからグループ階層全体のスキャナーカバレッジを確認できるようになりました。以前のバージョンのGitLabでは、[セキュリティインベントリ](../../../user/application_security/security_inventory/_index.md)はサブグループごとのカバレッジを表示するのみで、グループ全体の合計は表示されていませんでした。カバレッジウィジェットにより、グループおよびそのサブグループ内のすべてのプロジェクトにわたるスキャナーカバレッジが集計され、各スキャナーが有効、無効、失敗、または古い状態になっているプロジェクトの割合と数が表示されます。SASTや依存関係スキャンなど特定のスキャナーに絞り込むには、スキャナーのドロップダウンリストを使用します。次にステータスを選択してプロジェクトリストをフィルタリングし、カバレッジされていないプロジェクトのスキャナーを有効にします。

セキュリティインベントリでは、表示する列を制御できるようになりました。**脆弱性**、**ツールカバレッジ**、**セキュリティ属性**の列を表示または非表示にするには、**表示**を選択します。
