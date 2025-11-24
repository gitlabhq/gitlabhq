---
stage: None - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
group: Unassigned - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: 利用規約とプライバシーポリシー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

管理者は、利用規約とプライバシーポリシーの同意を強制できます。このオプションが有効になっている場合、新規および既存の認証済みユーザーは利用規約に同意する必要があります。

有効にすると、`-/users/terms`インスタンスのページで利用規約を表示できます（例: `https://gitlab.example.com/-/users/terms`）。

いずれかの利用規約が定義されている場合、リンク`Terms and privacy`がヘルプメニューに表示されます。

## 利用規約とプライバシーポリシーを適用する {#enforce-a-terms-of-service-and-privacy-policy}

利用規約とプライバシーポリシーの同意を強制するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **利用規約とプライバシーポリシー**セクションを展開します。
1. **GitLabにアクセスするには、すべてのユーザーが利用規約とプライバシーポリシーに同意する必要があります**チェックボックスをオンにします。
1. **利用規約とプライバシーポリシー**のテキストを入力します。このテキストボックスで[Markdown](../../user/markdown.md)を使用できます。
1. **変更を保存**を選択します。

利用規約を更新するたびに、新しいバージョンが保存されます。認証済みユーザーが利用規約に同意または拒否すると、GitLabは同意または拒否したバージョンを記録します。

既存の認証済みユーザーは、次回のGitLab操作時に利用規約に同意する必要があります。認証済みユーザーが利用規約を拒否すると、サインアウトされます。

有効にすると、新しい認証済みユーザーのサインアップページに必須のチェックボックスが追加されます:

![必須の利用規約同意チェックボックス付きのサインアップフォーム](img/sign_up_terms_v11_0.png)
