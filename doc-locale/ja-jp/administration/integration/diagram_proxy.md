---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 図プロキシ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223314)されました。

{{< /history >}}

ブラウザが図のコンテンツをKrokiやPlantUMLのような外部サービスに送信するのを防ぐために、図プロキシを使用します。GitLabはユーザーに代わって図をフェッチし、使用後に期限切れとなるワンタイムURLを通じて提供します。

## ダイアグラムプロキシをオンにする {#turn-on-the-diagram-proxy}

ダイアグラムプロキシを[Kroki](kroki.md)と[PlantUML](plantuml.md)インテグレーションに個別にオンにします。Kroki、PlantUML、またはその両方に対して図プロキシを有効にできます。

前提条件: 

- 管理者アクセス権が必要です。

図プロキシを有効にするには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. 展開する**Kroki**または**PlantUML**。
1. **KrokiダイアグラムをGitLab経由でプロキシ**または**PlantUMLダイアグラムをGitLab経由でプロキシ**チェックボックスを選択します。
1. **変更を保存**を選択します。
