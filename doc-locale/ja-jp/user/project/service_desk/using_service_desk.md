---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: サービスデスクを使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

サービスデスクを使用して、[チケットを作成](#as-an-end-user-ticket-creator)したり、[応答](#as-a-responder-to-the-ticket)したりできます。これらのチケットでは、使い慣れた[サポートボット](configure.md#support-bot-user)も表示されます。

## サービスデスクメールアドレスの表示 {#view-service-desk-email-address}

プロジェクトのサービスデスクメールアドレスを確認するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **サービスデスク**を選択します。

メールアドレスはチケットリストの一番上に表示されます。

## エンドユーザー（チケット作成者）として {#as-an-end-user-ticket-creator}

サービスデスクチケットを作成するために、エンドユーザーはGitLabインスタンスについて何も知る必要はありません。提供されたメールアドレスにメールを送信するだけで、GitLabサポートボットから受領確認のメールが返信されます:

```plaintext
Thank you for your support request! We are tracking your request as ticket `#%{issue_iid}`, and will respond as soon as we can.
```

このメールは、エンドユーザーに登録解除のオプションも提供します。

登録解除を選択しない場合、チケットに追加された新しいコメントはすべてメールとして送信されます。

メールで送信された応答はすべて、チケット自体に表示されます。

詳細については、[外部参加者](external_participants.md)とメールの処理に使用される[ヘッダー](../../../administration/incoming_email.md#accepted-headers)を参照してください。

### GitLab UIでサービスデスクチケットを作成する {#create-a-service-desk-ticket-in-gitlab-ui}

{{< history >}}

- GitLab 16.9で`convert_to_ticket_quick_action`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)されました。デフォルトでは無効になっています。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)になりました。機能フラグ`convert_to_ticket_quick_action`は削除されました。

{{< /history >}}

UIからサービスデスクチケットを作成するには:

1. [イシューを作成する](../issues/create_issues.md)
1. クイックアクション`/convert_to_ticket user@example.com`のみを含むコメントを追加します。[GitLabサポートボット](configure.md#support-bot-user)からのコメントが表示されるはずです。
1. UIにタイプ変更が反映されるようにページをリロードします。
1. オプション。外部参加者に初期のサービスデスクメールを送信するために、チケットにコメントを追加します。

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[UIとAPIでサービスデスクチケットを作成する方法（GitLab 16.10）](https://www.youtube.com/watch?v=ibUGNc2wifQ)を参照してください。
<!-- Video published on 2024-03-05 -->

## チケットへの応答者として {#as-a-responder-to-the-ticket}

チケットへの応答者にとって、すべてはGitLabイシューとまったく同じように機能します。GitLabには、応答者が顧客サポートリクエストを通じて作成されたチケットを表示し、フィルタリングまたは操作できる、おなじみのチケットトラッカーが表示されます。

![サービスデスクチケットトラッカー](img/service_desk_issue_tracker_v16_10.png)

エンドユーザーからのメッセージは、特別な[サポートボットユーザー](../../../subscriptions/manage_seats.md#criteria-for-non-billable-users)からのものとして表示されます。GitLabで通常通りコメントを読み取り、書き込みできます:

- プロジェクトの表示レベル（プライベート、内部、公開）はサービスデスクに影響しません。
- プロジェクトへのパス（グループまたはネームスペースを含む）は、メールに表示されます。

### サービスデスクチケットの表示 {#view-service-desk-tickets}

前提条件: 

- プロジェクトのレポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

サービスデスクチケットを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **サービスデスク**を選択します。

#### 再設計されたチケットリスト {#redesigned-ticket-list}

{{< history >}}

- GitLab 16.1で`service_desk_vue_list`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/413092)されました。デフォルトでは無効になっています。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/415385)になりました。機能フラグ`service_desk_vue_list`は削除されました。

{{< /history >}}

サービスデスクのチケットリストは、通常のイシューリストとより一致しています。利用可能な機能は次のとおりです:

- [イシューリスト](../issues/sorting_issue_lists.md)と同じソートと順序のオプション。
- [OR演算子](#filter-the-list-of-tickets)や[チケットID](#filter-tickets-by-id)によるフィルタリングを含む、同じフィルター。

サービスデスクのチケットリストから新しいチケットを作成するオプションはなくなりました。この決定は、専用のメールアドレスにメールを送信することで新しいチケットが作成されるサービスデスクの性質をよりよく反映しています。

##### チケットリストのフィルタリング {#filter-the-list-of-tickets}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **サービスデスク**を選択します。
1. チケットリストの上にある**結果を検索またはフィルタリング**を選択します。
1. 表示されるドロップダウンリストで、フィルタリングする属性を選択します。
1. 属性のフィルタリングに使用する演算子を選択または入力します。次の演算子を使用できます。
   - `=`: 等しい
   - `!=`: 次のいずれでもない
1. 属性でフィルタリングするテキストを入力します。一部の属性は、**なし**または**任意**でフィルタリングできます。
1. 複数の属性でフィルタリングするには、このプロセスを繰り返します。複数の属性は、論理`AND`で結合されます。

##### OR演算子でフィルタリングする {#filter-with-the-or-operator}

[OR演算子によるフィルタリング](../issues/managing_issues.md#filter-the-list-of-issues)が有効な場合、[チケットのリストをフィルタリング](#filter-the-list-of-tickets)する際に、**is one of: `||`**を使用できます:

- 担当者
- ラベル

`is one of`は、包含的ORを表します。たとえば、`Assignee is one of Sidney Jones`と`Assignee is one of Zhang Wei`でフィルタリングすると、GitLabは`Sidney`、`Zhang`、またはその両方が担当者であるチケットを表示します。

##### IDでチケットをフィルタリング {#filter-tickets-by-id}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **サービスデスク**を選択します。
1. **検索**ボックスにチケットIDを入力します。たとえば、`#10`を入力すると、チケット10のみが返されます。

## メールの内容とフォーマット {#email-contents-and-formatting}

### HTMLメールでの特別なHTMLフォーマット {#special-html-formatting-in-html-emails}

{{< history >}}

- GitLab 15.9で`service_desk_html_to_text_email_handler`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/109811)されました。デフォルトでは無効になっています。
- GitLab 15.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116809)になりました。機能フラグ`service_desk_html_to_text_email_handler`は削除されました。

{{< /history >}}

サービスデスクチケットから送信されたHTMLメールには、次のようなHTMLフォーマットが表示されます:

- テーブル
- 引用ブロック
- 画像
- 折りたたみ可能なセクション

### コメントに添付されたファイル {#files-attached-to-comments}

{{< history >}}

- GitLab 15.8で`service_desk_new_note_email_native_attachments`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/11733)されました。デフォルトでは無効になっています。
- GitLab.comおよびGitLab Self-Managedで[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/386860)になりました（GitLab 15.10）。
- GitLab 16.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/11733)になりました。機能フラグ`service_desk_new_note_email_native_attachments`は削除されました。

{{< /history >}}

コメントに添付ファイルが含まれており、その合計サイズが10 MB以下の場合は、これらの添付ファイルはメールの一部として送信されます。それ以外の場合、メールには添付ファイルへのリンクが含まれます。

GitLab 15.9以前では、コメントへのアップロードはメール内のリンクとして送信されます。

## 通常のイシューをサービスデスクチケットに変換する {#convert-a-regular-issue-to-a-service-desk-ticket}

{{< history >}}

- GitLab 16.9で`convert_to_ticket_quick_action`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)されました。デフォルトでは無効になっています。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)になりました。機能フラグ`convert_to_ticket_quick_action`は削除されました。

{{< /history >}}

クイックアクション`/convert_to_ticket external-ticket-author@example.com`を使用して、通常のイシューをサービスデスクチケットに変換します。これにより、指定されたメールアドレスがチケットの外部作成者として割り当てられ、外部参加者のリストに追加されます。彼らはチケットへの公開コメントに対するサービスデスクメールを受信し、これらのメールに返信できます。返信はチケットに新しいコメントを追加します。

GitLabはデフォルトの[`thank_you`メール](configure.md#customize-emails-sent-to-external-participants)を送信しません。エンドユーザーにチケットが作成されたことを知らせるために、チケットに公開コメントを追加できます。

## プライバシーに関する考慮事項 {#privacy-considerations}

{{< history >}}

- GitLab 15.9で、作成者と参加者のメールを表示するために必要な最小ロールが[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108901)されました。

{{< /history >}}

サービスデスクチケットは[機密](../issues/confidential_issues.md)であるため、プロジェクトメンバーのみに表示されます。プロジェクトオーナーは、[チケットを公開](../issues/confidential_issues.md#in-an-existing-issue)できます。サービスデスクチケットが公開されると、チケット作成者と参加者のメールアドレスは、プロジェクトのレポーター、デベロッパー、メンテナー、またはオーナーロールを持つサインインユーザーに表示されます。

GitLab 15.8以前では、サービスデスクチケットが公開されると、チケット作成者のメールアドレスは、プロジェクトを表示できる全員に開示されます。

プロジェクト内の誰でも、サービスデスクメールアドレスを使用して、プロジェクトでの**regardless of their role**このプロジェクトでチケットを作成できます。

ユニークな内部メールアドレスは、GitLabインスタンスでプランナーロール以上のプロジェクトメンバーに表示されます。外部ユーザー（チケット作成者）は、情報メモに表示されている内部メールアドレスを見ることはできません。

### サービスデスクチケットの移動 {#moving-a-service-desk-ticket}

{{< history >}}

- GitLab 15.7で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/372246): サービスデスクチケットが移動された場合でも、顧客は引き続き通知を受信します。

{{< /history >}}

サービスデスクチケットは、GitLabで[通常のイシューを移動](../issues/managing_issues.md#move-an-issue)するのと同じ方法で移動できます。

サービスデスクチケットがサービスデスクが有効になっている別のプロジェクトに移動された場合、チケットを作成した顧客は引き続きメール通知を受信します。移動されたチケットはまずクローズされてからコピーされるため、顧客は両方のチケットの参加者と見なされます。彼らは古いチケットと新しいチケットの両方で引き続き通知を受信します。
