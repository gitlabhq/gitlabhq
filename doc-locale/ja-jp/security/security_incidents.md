---
stage: Security
group: Security Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabにおけるセキュリティインシデントの検出、調査、対応を行います。
title: セキュリティインシデント
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabセキュリティオペレーションチームは、GitLab Self-Managedインスタンスの管理者およびメンテナー、GitLab.com上のグループが、GitLabに関連するセキュリティインシデントを検出して対応できるように、これらの推奨事項を作成しました。これらは、組織が定めたセキュリティプロセスを置き換えるためではなく、補完するために使用してください。

検出と対応は連携して機能します:

1. 検出: 監査イベントとログを収集し、セキュリティ情報イベント管理（SIEM）システムに集約し、不審なアクティビティを警告する検出ルールをデプロイします。
1. 対応: 検出がトリガーされ、インシデントを確認したら、脅威を封じ込め、その範囲を特定し、影響を受けたアカウント、認証情報、設定を修正します。

## セキュリティテレメトリを収集する {#collect-security-telemetry}

GitLabが生成するセキュリティテレメトリの種類、それぞれが示す情報、そして自社の提供形態とサブスクリプションのプランで収集できる内容（表示可能な監査イベント、SIEMにストリーミングできる監査イベント、アプリケーションログ）を理解します。

詳細については、[セキュリティテレメトリ](security_telemetry.md)を参照してください。

## セキュリティインシデントを検出する {#detect-security-incidents}

GitLabにおけるセキュリティ関連のアクティビティに対する検出範囲を構築します。収集するデータソース、SIEMへの監査イベントのストリーミング方法、オープンソースのTLDR検出フレームワークの使用方法、一般的なインシデントシナリオで監視すべきシグナルについて学びます。

詳細については、[セキュリティインシデントの検出](detecting_security_incidents.md)を参照してください。

## セキュリティインシデントに対応する {#respond-to-security-incidents}

漏えいした認証情報、侵害されたユーザーアカウント、CI/CD関連のインシデント、侵害されたインスタンス、誤って設定されたプロジェクトまたはグループの設定など、GitLabにおける一般的なセキュリティインシデントを封じ込め、修正します。

詳細については、[セキュリティインシデント対応](responding_to_security_incidents.md)を参照してください。

## 関連トピック {#related-topics}

- [GitLabを保護する](_index.md)
- [強化の推奨事項](hardening.md)
- [監査イベントタイプ](../user/compliance/audit_event_types.md)
