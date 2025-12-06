---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: サービスデスクを使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

サービスデスクを使用して、[イシューを作成](#as-an-end-user-issue-creator)したり、[イシューに対応](#as-a-responder-to-the-issue)したりできます。これらのイシューでは、近所のフレンドリーな[サポートボット](configure.md#support-bot-user)も確認できます。

## サービスデスクのメールアドレスを表示 {#view-service-desk-email-address}

プロジェクトのサービスデスクのメールアドレスを確認するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、モニタリングを選択し、プロジェクトを見つけます。**モニタリング** > **サービスデスク**を選択します。

メールアドレスは、イシューリストの上部にあります。

## エンドユーザーとして（イシューの作成者） {#as-an-end-user-issue-creator}

サービスデスクイシューを作成するために、エンドユーザーはGitLabのインスタンスについて何も知る必要はありません。指定されたアドレスにメールを送信するだけで、受領確認としてGitLabサポートボットからメールが返信されます:

```plaintext
Thank you for your support request! We are tracking your request as ticket `#%{issue_iid}`, and will respond as soon as we can.
```

このメールには、エンドユーザーに登録解除のオプションも表示されます。

登録解除を選択しない場合、イシューに追加された新しいコメントはメールとして送信されます。

メールで送信されたすべての応答は、イシュー自体に表示されます。

詳細については、[外部参加者](external_participants.md)と[メールの処理に使用されるヘッダー](../../../administration/incoming_email.md#accepted-headers)を参照してください。

### GitLab UIでサービスデスクチケットを作成 {#create-a-service-desk-ticket-in-gitlab-ui}

{{< history >}}

- GitLab 16.9で`convert_to_ticket_quick_action`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)されました。デフォルトでは無効になっています。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)になりました。機能フラグ`convert_to_ticket_quick_action`は削除されました。

{{< /history >}}

UIからサービスデスクチケットを作成するには、次の手順に従います:

1. [イシューを作成する](../issues/create_issues.md)
1. クイックアクション`/convert_to_ticket user@example.com`のみを含むコメントを追加します。[GitLabサポートボット](configure.md#support-bot-user)からのコメントが表示されるはずです。
1. UIがタイプの変更を反映するように、ページをリロードします。
1. オプション。最初のサービスデスクメールを外部参加者に送信するために、チケットにコメントを追加します。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>チュートリアルについては、[UIとAPIでサービスデスクチケットを作成する（GitLab 16.10）](https://www.youtube.com/watch?v=ibUGNc2wifQ)を参照してください。
<!-- Video published on 2024-03-05 -->

## イシューへのレポーターとして {#as-a-responder-to-the-issue}

イシューへのレポーターにとって、すべては他のGitLabイシューと同じように動作します。GitLabには、顧客サポートリクエストを通じて作成されたイシューをレポーターが表示し、それらをフィルタリングまたは操作できる、見慣れた外観のイシュートラッカーが表示されます。

![サービスデスクイシュートラッカー](img/service_desk_issue_tracker_v16_10.png)

エンドユーザーからのメッセージは、特別な[サポートボットユーザー](../../../subscriptions/manage_users_and_seats.md#criteria-for-non-billable-users)からのものとして表示されます。GitLabで通常行うように、コメントを読み書きできます:

- プロジェクトの表示レベル（プライベート、内部、パブリック）は、サービスデスクに影響しません。
- グループまたはネームスペースを含むプロジェクトへのパスがメールに表示されます。

### サービスデスクイシューを表示 {#view-service-desk-issues}

前提要件: 

- プロジェクトのレポーターロール以上が必要です。

サービスデスクイシューを表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、モニタリングを選択し、プロジェクトを見つけます。**モニタリング** > **サービスデスク**を選択します。

#### 再設計されたイシューリスト {#redesigned-issue-list}

{{< history >}}

- GitLab 16.1で`service_desk_vue_list`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/413092)されました。デフォルトでは無効になっています。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/415385)になりました。機能フラグ`service_desk_vue_list`は削除されました。

{{< /history >}}

サービスデスクイシューリストは、通常のイシューリストにより近いものになっています。使用可能な機能は次のとおりです:

- [イシューリストと同じ](../issues/sorting_issue_lists.md)並べ替えおよび順序オプション。
- [OR演算子](#filter-with-the-or-operator)や[イシューIDによるフィルタリング](#filter-issues-by-id)など、同じフィルター。

サービスデスクイシューリストから新しいイシューを作成するオプションはなくなりました。この決定は、新しいイシューが専用のメールアドレスにメールを送信することで作成されるサービスデスクの性質をより良く反映しています。

##### イシューのリストをフィルタリングする {#filter-the-list-of-issues}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、モニタリングを選択し、プロジェクトを見つけます。**モニタリング** > **サービスデスク**を選択します。
1. イシューのリストの上にある**結果を検索またはフィルタリング**を選択します。
1. 表示されるドロップダウンリストで、フィルタリングする属性を選択します。
1. 属性のフィルタリングに使用する演算子を選択または入力します。次の演算子を使用できます:
   - `=`: 等しい
   - `!=`: 次のいずれでもない
1. 属性でフィルタリングするテキストを入力します。一部の属性は、**なし**または**任意**でフィルタリングできます。
1. 複数の属性でフィルタリングするには、このプロセスを繰り返します。複数の属性は、論理`AND`で結合されます。

##### OR演算子でフィルタリングする {#filter-with-the-or-operator}

[OR演算子でのフィルタリング](../issues/managing_issues.md#filter-with-the-or-operator)が有効になっている場合、次の項目で[イシューのリストをフィルタリング](#filter-the-list-of-issues)する際に**次のいずれか: `||`**を使用できます。

- 担当者
- ラベル

`is one of`は、包括的なORを表します。たとえば、`Assignee is one of Sidney Jones`と`Assignee is one of Zhang Wei`でフィルタリングすると、GitLabは、`Sidney`、`Zhang`、またはその両方が担当者に割り当てられているイシューを表示します。

##### IDでイシューをフィルタリングする {#filter-issues-by-id}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、モニタリングを選択し、プロジェクトを見つけます。**モニタリング** > **サービスデスク**を選択します。
1. **検索**ボックスに、イシューIDを入力します。たとえば、`#10`というフィルターを入力すると、イシュー10のみが返されます。

## メールの内容とフォーマット {#email-contents-and-formatting}

### HTMLメールの特別なHTMLフォーマット {#special-html-formatting-in-html-emails}

{{< history >}}

- GitLab 15.9で`service_desk_html_to_text_email_handler`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/109811)されました。デフォルトでは無効になっています。
- GitLab 15.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116809)になりました。機能フラグ`service_desk_html_to_text_email_handler`は削除されました。

{{< /history >}}

HTMLメールには、次のようなHTMLフォーマットが表示されます:

- テーブル
- 引用ブロック
- 画像
- 折りたたみ可能なセクション

### コメントに添付されたファイル {#files-attached-to-comments}

{{< history >}}

- GitLab 15.8で`service_desk_new_note_email_native_attachments`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/11733)されました。デフォルトでは無効になっています。
- GitLab 15.10の[GitLab.comおよびGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/386860)。
- GitLab 16.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/11733)になりました。機能フラグ`service_desk_new_note_email_native_attachments`は削除されました。

{{< /history >}}

コメントに添付ファイルが含まれていて、その合計サイズが10 MB以下の場合、これらの添付ファイルはメールの一部として送信されます。それ以外の場合、メールには添付ファイルへのリンクが含まれています。

GitLab 15.9以前、コメントへのアップロードはメール内のリンクとして送信されます。

## 通常のイシューをサービスデスクチケットに変換する {#convert-a-regular-issue-to-a-service-desk-ticket}

{{< history >}}

- GitLab 16.9で`convert_to_ticket_quick_action`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)されました。デフォルトでは無効になっています。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)になりました。機能フラグ`convert_to_ticket_quick_action`は削除されました。

{{< /history >}}

クイックアクション`/convert_to_ticket external-issue-author@example.com`を使用して、通常のイシューをサービスデスクチケットに変換します。これにより、指定されたメールアドレスがチケットの外部作成者として割り当てられ、外部参加者のリストに追加されます。彼らは、チケットに関する公開コメントのサービスデスクメールを受信し、これらのメールに返信できます。返信により、チケットに新しいコメントが追加されます。

GitLabは、[デフォルトの`thank_you`メール](configure.md#customize-emails-sent-to-external-participants)を送信しません。エンドユーザーにチケットが作成されたことを知らせるために、チケットに公開コメントを追加できます。

## プライバシーに関する考慮事項 {#privacy-considerations}

{{< history >}}

- [変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108901) GitLab 15.9の作成者と参加者のメールを表示するために必要な最小限のロール。

{{< /history >}}

サービスデスクイシューは[機密](../issues/confidential_issues.md)であるため、プロジェクトメンバーのみが表示できます。プロジェクトオーナーは[イシューを公開](../issues/confidential_issues.md#in-an-existing-issue)できます。サービスデスクイシューが公開されると、イシューの作成者と参加者のメールアドレスは、プロジェクトのレポーターロール以上の権限を持つサインインしたユーザーに表示されます。

GitLab 15.8以前、サービスデスクイシューが公開されると、イシューの作成者のメールアドレスは、プロジェクトを表示できるすべてのユーザーに公開されます。

プロジェクトの誰でもサービスデスクのメールアドレスを使用して、このプロジェクトにイシューを作成できます。プロジェクトでの**regardless of their role**（彼らのロールに関係なく）。

一意の内部メールアドレスは、GitLabインスタンスのプランナーロール以上のプロジェクトメンバーに表示されます。外部ユーザー（イシューの作成者）は、情報メモに表示されている内部メールアドレスを表示できません。

### サービスデスクイシューの移動 {#moving-a-service-desk-issue}

{{< history >}}

- GitLab 15.7で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/372246): サービスデスクイシューが移動された場合、顧客は引き続き通知を受信します。

{{< /history >}}

GitLabで[通常のイシューを移動](../issues/managing_issues.md#move-an-issue)するのと同じ方法で、サービスデスクイシューを移動できます。

サービスデスクイシューがサービスデスクが有効になっている別のプロジェクトに移動された場合、イシューを作成した顧客は引き続きメール通知を受信します。移動されたイシューは最初に閉じられ、次にコピーされるため、顧客は両方のイシューの参加者と見なされます。古いイシューと新しいイシューのすべての通知を受信し続けます。
