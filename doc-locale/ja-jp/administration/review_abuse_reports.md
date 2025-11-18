---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: 不正行為の報告を確認する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabユーザーからの不正利用レポートを表示し、解決する。

GitLab管理者は、**管理者**エリアで不正利用レポートを表示し、[解決](#resolving-abuse-reports)できます。

## メールで不正利用レポートの通知を受信する {#receive-notification-of-abuse-reports-by-email}

メールで新しい不正利用レポートの通知を受信するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **レポート**を選択します。
1. **不正利用レポート**セクションを展開する。
1. メールアドレスを入力し、**変更を保存**を選択します。

通知メールアドレスは、[APIを使用して](../api/settings.md#available-settings)設定および取得することもできます。

## 不正のレポート {#reporting-abuse}

不正のレポートの詳細については、[不正利用レポートのユーザードキュメント](../user/report_abuse.md)を参照してください。

## 不正利用レポートを解決する {#resolving-abuse-reports}

{{< history >}}

- **ユーザーを信頼する**がGitLab 16.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131102)。

{{< /history >}}

不正利用レポートにアクセスするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **不正利用レポート**を選択します。

各方法のボタンを使用して、不正利用レポートを解決する方法は4つあります:

- ユーザーとレポートを削除します。これ:
  - インスタンスから[報告されたユーザーを削除します](../user/profile/account/delete_account.md)。
  - 不正利用レポートを一覧から削除します。
- [ユーザーをブロック](#blocking-users)。
- レポートを削除します。これ:
  - 不正利用レポートを一覧から削除します。
  - 報告されたユーザーのアクセス制限を削除します。
- ユーザーを信頼する。これ:
  - スパムでブロックされずに、ユーザーがイシュー、ノート、スニペット、マージリクエストを作成できるようにします。
  - このユーザーに対して不正利用レポートが作成されないようにします。

以下は、**不正利用レポート**ページの例です:

![さまざまなユーザーから送信された不正利用レポートの例の一覧。それぞれに使用できる解決アクションがあります。](img/abuse_reports_page_v13_11.png)

### ユーザーのブロック {#blocking-users}

ブロックされたユーザーはサインインしたり、任意のリポジトリにアクセスしたりすることはできませんが、すべてのデータは残ります。

ユーザーをブロック:

- 不正利用レポート一覧に残します。
- **ユーザーをブロック**ボタンを無効の**ブロック済み**ボタンに変更します。

ユーザーには、次のメッセージが通知されます:

```plaintext
Your account has been blocked. If you believe this is in error, contact a staff member.
```

ブロック後も、次のいずれかを実行できます:

- 必要に応じて、ユーザーとレポートを削除します。
- レポートを削除します。

以下は、**不正利用レポート**ページにリストされている、ブロックされたユーザーの例です:

![ユーザーが既にブロックされているため、不正利用レポートに対して、ユーザーのブロックアクションは使用できません。](img/abuse_report_blocked_user_v11_7.png)

## 関連トピック {#related-topics}

- [ユーザーのモデレート（管理者）](moderate_users.md)
- [スパムログを確認する](review_spam_logs.md)
