---
stage: Analytics
group: Knowledge Graph
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Orbit
description: GitLab Self-Managedインスタンス用にGitLab Orbitを設定します。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## トップレベルグループネームスペースを自動的にインデックス化 {#index-top-level-group-namespaces-automatically}

{{< history >}}

- GitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/606375)されました。

{{< /history >}}

前提条件: 

- 管理者アクセス権が必要です。
- インスタンスには、Orbit機能付きのライセンスが必要です。

既存および新規のトップレベルグループネームスペースを自動的にインデックス化するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Orbit**を選択します。
1. **Orbit設定**を展開します。
1. **ルートネームスペースを自動的にインデックス化する**を選択します。
1. **変更を保存**を選択します。

バックグラウンドジョブは5分ごとに実行され、まだ登録されていないトップレベルグループネームスペースを登録します。パーソナルネームスペースは登録されません。

**ルートネームスペースを自動的にインデックス化する**をクリアすると、既存の登録は残ります。バックグラウンドジョブは、その設定を再度選択するまで、新しいトップレベルグループを登録しません。

> [!note]
> この設定はGitLab.comには影響しません。

## Orbitステータスを表示 {#view-orbit-status}

Orbitの設定とインデックス作成ステータスを表示するには、以下を実行します:

```shell
sudo gitlab-rake gitlab:orbit:info
```
