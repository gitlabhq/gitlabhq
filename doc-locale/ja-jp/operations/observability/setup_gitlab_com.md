---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: アプリケーションのパフォーマンスをモニタリングし、パフォーマンスに関するイシューをトラブルシューティングを行う。
ignore_in_report: true
title: GitLab.comでの可観測性の設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: 実験的機能

{{< /details >}}

GitLab.comでGitLab可観測性を設定するには、グループでGitLab可観測性を有効にします。

前提条件: 

- グループのデベロッパー、メンテナー、またはオーナーのロールが必要です。

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**可観測性** > **セットアップ**を選択します。
1. **可観測性を有効にする**を選択します。
1. 有効にすると、OpenTelemetry (OTEL) エンドポイントURLが生成され、ページに表示されます。

OTELエンドポイントURLをコピーして、アプリケーションの計測時に使用します。

## 次のステップ {#next-steps}

- [テレメトリーデータをGitLab可観測性に送信する](send.md)。
- [CI/CDパイプラインのテレメトリーを表示](ci_cd.md)。
- [トラブルシューティング情報を取得する](troubleshooting.md)。
