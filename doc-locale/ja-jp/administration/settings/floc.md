---
stage: None - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
group: Unassigned - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コホートの連合学習（FLoC）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コホートの連合学習（FLoC）は、インタレストベース広告のためにユーザーを異なるコホートに分類する、Google Chrome向けに提案された機能でした。FLoCは[Topics API](https://patcg-individual-drafts.github.io/topics/)に置き換えられました。このTopics APIは、広告主がユーザーをターゲットにして追跡するのに役立つ同様の機能を提供します。

デフォルトでは、GitLabは、インタレストベース広告のためのユーザー追跡をオプトアウトするために、次のヘッダーを送信します:

```plaintext
Permissions-Policy: interest-cohort=()
```

このヘッダーにより、ユーザーがあらゆるGitLabインスタンスで追跡され、分類されるのを防ぎます。このヘッダーは、Topics APIおよび非推奨のFLoCシステムと互換性があります。

インタレストベース広告のためのユーザー追跡を有効にするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **コホートの連合学習 (FLoC)**を展開します。
1. **FLoCへ参加**チェックボックスを選択します。
1. **変更を保存**を選択します。
