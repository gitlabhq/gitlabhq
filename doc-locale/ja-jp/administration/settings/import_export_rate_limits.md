---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトとグループのインポートとエクスポートのレート制限
description: "プロジェクトまたはグループをインポートまたはエクスポートする際に、GitLabインスタンスのレート制限設定を構成します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

プロジェクトとグループのインポートとエクスポートのレート制限を構成できます:

レート制限を変更するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **インポートとエクスポートのレート制限**を展開します。
1. 任意のレート制限の値を変更します。レート制限は、IPアドレスごとではなく、ユーザーごとに1分あたりの制限です。レート制限を無効にするには、`0`に設定します。

| 制限                   | デフォルト |
|-------------------------|---------|
| プロジェクトのインポート          | 6       |
| プロジェクトのエクスポート          | 6       |
| プロジェクトのエクスポートのダウンロード | 1       |
| グループのインポート            | 6       |
| グループのエクスポート            | 6       |
| グループのエクスポートのダウンロード   | 1       |

ユーザーがレート制限を超過すると、`auth.log`に記録されます。
