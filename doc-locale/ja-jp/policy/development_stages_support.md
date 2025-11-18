---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: サポートの詳細。
title: 開発のさまざまな段階にある機能のサポート
---

GitLabでは、試験段階やベータなど、開発のさまざまな段階で機能をリリースすることがあります。ユーザーはオプトインして、新しいユーザーエクスペリエンスをテストできます。このような機能のリリースには、次のような理由があります:

- 設計されたすべてのユースケースに対して、現在の形式の機能のスケール、サポート、およびメンテナンスの負荷のエッジケースを検証する。
- 機能は、最低限実現可能な変更と見なすには十分ではありませんが、開発プロセスの一部としてコードベースに追加されます。

一部の機能は、推奨事項が実施される前に開発された場合、またはチームが代替の実装アプローチが必要であると判断した場合、これらの推奨事項に沿っていない可能性があります。

他のすべての機能は、一般に公開されていると見なされます。

## 実験的な機能。 {#experiment}

実験的な機能:

- 本番環境での使用には適していません。
- [サポートはご利用いただけません](https://about.gitlab.com/support/statement-of-support/#experiment-beta-features)。このような機能に関するイシューは、[GitLabイシュートラッカー](https://gitlab.com/gitlab-org/gitlab/-/issues)でオープンする必要があります。
- 不安定な場合があります。
- いつでも削除される可能性があります。
- データ損失のリスクがある可能性があります。
- ドキュメントがないか、情報がGitLabイシューまたはブログに限定されている可能性があります。
- 最終的なユーザーエクスペリエンスがない可能性があり、クイックアクションまたはAPIリクエストを介してのみアクセスできる場合があります。

## ベータ {#beta}

ベータ機能:

- 本番環境での使用には適していない可能性があります。
- [商業的に合理的な努力に基づいてサポート](https://about.gitlab.com/support/statement-of-support/#experiment-beta-features)されますが、イシューの問題解決には、開発からの余分な時間と支援が必要になることが予想されます。
- 不安定な場合があります。
- 設定と依存関係は変更されない可能性があります。
- 機能と関数は変更されない可能性があります。ただし、破壊的な変更は、メジャーリリースの範囲外で発生したり、一般に利用可能な機能よりも短い通知で発生したりする可能性があります。
- データ損失のリスクは低くなっています。
- ユーザーエクスペリエンスは完了またはほぼ完了しています。
- パートナーの「パブリックプレビュー」ステータスと同等になる可能性があります。

## 一般公開 {#public-availability}

2種類の一般リリースが利用可能です:

- 利用制限
- 一般提供

どちらのタイプも本番環境に対応していますが、スコープが異なります。

### 利用制限 {#limited-availability}

利用制限のある機能:

- スケールが縮小された本番環境での使用に対応しています。
- 最初に1つ以上のGitLabプラットフォーム（GitLab.com、GitLab Self-Managed、GitLab Dedicated）で利用できる場合があります。
- 最初はFreeですが、一般公開されると有料になる場合があります。
- 一般公開される前に割引価格で提供される場合があります。
- 一般公開されると、新しい契約の商用条件が変更される場合があります。
- [完全にサポート](https://about.gitlab.com/support/statement-of-support/)され、ドキュメント化されています。
- GitLabの設計標準に沿った完全なユーザーエクスペリエンスを備えています。

### 一般公開 {#generally-available}

一般に利用可能な機能:

- あらゆるスケールの本番環境での使用に対応しています。
- [完全にサポート](https://about.gitlab.com/support/statement-of-support/)され、ドキュメント化されています。
- GitLabの設計標準に沿った完全なユーザーエクスペリエンスを備えています。
- すべてのGitLabプラットフォーム（GitLab.com、GitLab.com Cells、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated）で利用できる必要があります。
