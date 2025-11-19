---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Akismet
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、公開プロジェクトでのスパムイシューの作成を防ぐために[Akismet](https://akismet.com/)を使用します。ウェブユーザーインターフェースまたはAPIを通じて作成されたイシューは、レビューのためにAkismetに送信でき、インスタンスの管理者は[スニペットをスパムとしてマーク](../user/snippets.md#mark-snippet-as-spam)できます。

検出されたスパムは拒否され、**管理者**エリアの**Spam log**（スパムログ）セクションにエントリが追加されます。

プライバシーに関する注記: GitLabは、ユーザーのIPとユーザーエージェントをAkismetに送信します。

{{< alert type="note" >}}

GitLabはすべてのイシューをAkismetに送信します。

{{< /alert >}}

Akismetの設定は、GitLab Self-Managedのユーザーが利用できます。AkismetはGitLab SaaS（GitLab.com）ですでに有効になっており、その設定と管理はGitLab Inc.によって処理されます。

## Akismetの設定 {#configure-akismet}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Akismetを使用するには:

1. [Akismetサインインページ](https://akismet.com/account/)に移動します。
1. サインインするか、新しいアカウントを作成してください。
1. **表示**を選択してAPIキーを表示し、APIキーの値をコピーします。
1. 管理者としてGitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **レポート**を選択します。
1. **スパムとアンチボット対策**を展開します。
1. **Akismetを有効にする**チェックボックスを選択します。
1. ステップ3のAPIキーを入力します。
1. 設定を保存します。

## Akismetフィルターをトレーニングする {#train-the-akismet-filter}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

スパムとハムをより適切に区別するために、誤検出または偽陰性が発生した場合は常に、Akismetフィルターをトレーニングできます。

エントリがスパムとして認識されると、拒否され、スパムログに追加されます。ここから、エントリが本当にスパムであるかどうかをレビューできます。それらの1つが本当にスパムでない場合は、**ハムとして送信**を選択して、エントリがスパムとして誤って認識されたことをAkismetに伝えます。

実際にスパムであるエントリがそのように認識されなかった場合は、**スパムとしてレポート**を使用して、この情報をAkismetに送信します。**スパムとしてレポート**ボタンは、管理者ユーザーにのみ表示されます。

Akismetをトレーニングすると、将来スパムをより正確に認識できるようになります。
