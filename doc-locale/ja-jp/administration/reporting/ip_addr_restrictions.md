---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: IPアドレスの制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

IPアドレス制限は、悪意のあるユーザーが複数のIPアドレスの背後にアクティビティーを隠蔽することを防ぐのに役立ちます。

GitLabは、ユーザーが指定された期間にリクエストを行うために使用する、固有のIPアドレスのリストを保持します。指定された制限に達すると、新しいIPアドレスからのユーザーによるリクエストは`403 Forbidden`エラーで拒否されます。

指定された期間に、そのIPアドレスからユーザーによるそれ以上のリクエストがない場合、IPアドレスはリストからクリアされます。

{{< alert type="note" >}}

Runnerが特定のユーザーとしてCI/CDジョブを実行すると、runnerのIPアドレスも、固有のIPアドレスのユーザーリストに対して保存されます。したがって、ユーザーごとのIPアドレス制限は、設定されたアクティブなrunnerの数を考慮に入れる必要があります。

{{< /alert >}}

## IPアドレス制限の設定 {#configure-ip-address-restrictions}

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **レポート**を選択します。
1. **スパムとアンチボット対策**を展開する。
1. IPアドレス制限設定を更新します:
   1. **複数のIPアドレスからのログインを制限する**チェックボックスを選択して、IPアドレス制限を有効にします。
   1. **ユーザーごとのIPアドレス**フィールドに、`1`以上の数値を入力します。この数値は、新しいIPアドレスからのリクエストが拒否される前に、ユーザーが指定された期間にGitLabにアクセスできる固有のIPアドレスの最大数を指定します。
   1. **IPアドレスの有効期限**フィールドに、`0`以上の数値を入力します。この数値は、最後のリクエストが行われた時点から、IPアドレスがユーザーの制限にカウントされる時間を秒単位で指定します。
1. **変更を保存**を選択します。
