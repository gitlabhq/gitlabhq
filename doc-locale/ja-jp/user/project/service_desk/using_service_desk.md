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

サービスデスクを使用して、[チケットを作成](#as-an-end-user-ticket-creator)したり、[チケットに返信](#as-a-responder-to-the-ticket)したりできます。これらのチケットでは、親切な近所の[サポートボット](configure.md#support-bot-user)も確認できます。

## サービスデスクのメールアドレスを表示 {#view-service-desk-email-address}

プロジェクトのサービスデスクメールアドレスを確認するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **サービスデスク**を選択します。

メールアドレスは、チケットリストの一番上に表示されています。

## エンドユーザー（チケット作成者）として {#as-an-end-user-ticket-creator}

サービスデスクチケットを作成するために、エンドユーザーはGitLabインスタンスについて何も知る必要はありません。メールで指定されたアドレスに送信するだけで、GitLabサポートボットから受領確認のメールが返信されます:

```plaintext
Thank you for your support request! We are tracking your request as ticket `#%{issue_iid}`, and will respond as soon as we can.
```

このメールでは、エンドユーザーに購読解除のオプションも提供されます。

購読解除を選択しない場合、チケットに追加された新しいコメントはすべてメールとして送信されます。

メールで送信された返信はすべて、チケット自体に表示されます。

詳細については、[外部参加者](external_participants.md)と[メールを処理するために使用されるヘッダー](../../../administration/incoming_email.md#accepted-headers)を参照してください。

### GitLab UIでサービスデスクチケットを作成 {#create-a-service-desk-ticket-in-gitlab-ui}

{{< history >}}

- GitLab 16.9で`convert_to_ticket_quick_action`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)されました。デフォルトでは無効になっています。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)になりました。機能フラグ`convert_to_ticket_quick_action`は削除されました。

{{< /history >}}

UIからサービスデスクチケットを作成するには:

1. [イシューを作成する](../issues/create_issues.md)
1. クイックアクション`/convert_to_ticket user@example.com`のみを含むコメントを追加します。[GitLabサポートボット](configure.md#support-bot-user)からのコメントが表示されるはずです。
1. UIにタイプ変更が反映されるように、ページをリロードします。
1. オプション。オプション。チケットにコメントを追加して、外部参加者に最初のサービスデスクメールを送信します。

<i class="fa-youtube-play" aria-hidden="true"></i>ウォークスルーについては、[UIとAPIでサービスデスクチケットを作成（GitLab 16.10）](https://www.youtube.com/watch?v=ibUGNc2wifQ)を参照してください。
<!-- Video published on 2024-03-05 -->

## チケットへの応答者として {#as-a-responder-to-the-ticket}

チケットへの応答者にとっては、すべてがGitLabイシューと同じように機能します。GitLabは、顧客サポートリクエストを通じて作成されたチケットを応答者が確認し、フィルタリングしたり、操作したりできる、見慣れたチケットトラッカーを表示します。

![サービスデスクチケットトラッカー](img/service_desk_issue_tracker_v16_10.png)

エンドユーザーからのメッセージは、特別な[サポートボットユーザー](../../../subscriptions/manage_users_and_seats.md#criteria-for-non-billable-users)からのものとして表示されます。GitLabで通常行うように、コメントを読み書きできます:

- プロジェクトの表示レベル（非公開、内部公開、公開）は、サービスデスクに影響しません。
- グループまたはネームスペースを含むプロジェクトへのパスは、メールに表示されます。

### サービスデスクチケットを表示 {#view-service-desk-tickets}

前提条件: 

- プロジェクトのレポーター、デベロッパー、メンテナー、またはオーナーのロールを持っている必要があります。

サービスデスクチケットを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **サービスデスク**を選択します。

#### 再設計されたチケットリスト {#redesigned-ticket-list}

{{< history >}}

- GitLab 16.1で`service_desk_vue_list`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/413092)されました。デフォルトでは無効になっています。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/415385)になりました。機能フラグ`service_desk_vue_list`は削除されました。

{{< /history >}}

サービスデスクチケットリストは、通常のイシューリストに似ています。利用可能な機能は次のとおりです:

- [イシューリスト](../issues/sorting_issue_lists.md)と同じソートおよび並べ替えオプション。
- [OR演算子](#filter-the-list-of-tickets)と[チケットIDによるフィルタリング](#filter-tickets-by-id)を含む同じフィルター。

サービスデスクチケットリストから新しいチケットを作成するオプションはなくなりました。この決定は、専用のメールアドレスにメールを送信することによって新しいチケットが作成されるサービスデスクの性質をよりよく反映しています。

##### チケットリストをフィルタリングする {#filter-the-list-of-tickets}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **サービスデスク**を選択します。
1. チケットリストの上で、**結果を検索またはフィルタリング**を選択します。
1. 表示されるドロップダウンリストで、フィルタリングする属性を選択します。
1. 属性のフィルタリングに使用する演算子を選択または入力します。次の演算子を使用できます。
   - `=`: 等しい
   - `!=`: 次のいずれでもない
1. 属性でフィルタリングするテキストを入力します。一部の属性は、**なし**または**任意**でフィルタリングできます。
1. 複数の属性でフィルタリングするには、このプロセスを繰り返します。複数の属性は、論理`AND`で結合されます。

##### OR演算子でフィルタリングする {#filter-with-the-or-operator}

[OR演算子によるフィルタリング](../issues/managing_issues.md#filter-the-list-of-issues)が有効になっている場合、次の項目で[チケットリストをフィルタリング](#filter-the-list-of-tickets)する際に、**is one of: `||`**を使用できます:

- 担当者
- ラベル

`is one of`は、包含的ORを表します。たとえば、`Assignee is one of Sidney Jones`と`Assignee is one of Zhang Wei`でフィルタリングすると、GitLabは`Sidney`、`Zhang`、またはその両方が割り当てられているチケットを表示します。

##### チケットをIDでフィルタリング {#filter-tickets-by-id}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **サービスデスク**を選択します。
1. **検索**ボックスで、チケットIDを入力します。たとえば、`#10`を入力してチケット10のみを返します。

## メールの内容と書式設定 {#email-contents-and-formatting}

### メール内の特殊なHTML書式設定 {#special-html-formatting-in-html-emails}

{{< history >}}

- GitLab 15.9で`service_desk_html_to_text_email_handler`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/109811)されました。デフォルトでは無効になっています。
- GitLab 15.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116809)になりました。機能フラグ`service_desk_html_to_text_email_handler`は削除されました。

{{< /history >}}

サービスデスクチケットから送信されたHTMLメールには、次のようなHTML書式設定が表示されます:

- テーブル
- 引用ブロック
- 画像
- 折りたたみ可能なセクション

### コメントに添付されたファイル {#files-attached-to-comments}

{{< history >}}

- GitLab 15.8で`service_desk_new_note_email_native_attachments`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/11733)されました。デフォルトでは無効になっています。
- GitLab.comおよびGitLabセルフマネージドで[有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/386860)（GitLab 15.10）。
- GitLab 16.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/11733)になりました。機能フラグ`service_desk_new_note_email_native_attachments`は削除されました。

{{< /history >}}

コメントに添付ファイルがあり、それらの合計サイズが10 MB以下の場合、これらの添付ファイルはメールの一部として送信されます。その他の場合は、メールに添付ファイルへのリンクが含まれています。

GitLab 15.9および以前では、コメントへのアップロードはメール内のリンクとして送信されます。

## 通常のイシューをサービスデスクチケットに変換 {#convert-a-regular-issue-to-a-service-desk-ticket}

{{< history >}}

- GitLab 16.9で`convert_to_ticket_quick_action`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)されました。デフォルトでは無効になっています。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)になりました。機能フラグ`convert_to_ticket_quick_action`は削除されました。

{{< /history >}}

クイックアクション`/convert_to_ticket external-ticket-author@example.com`を使用して、通常のイシューをサービスデスクチケットに変換します。これにより、提供されたメールアドレスがチケットの外部作成者として割り当てられ、外部参加者リストに追加されます。彼らはチケットに対する公開コメントのサービスデスクメールを受信し、これらのメールに返信できます。返信すると、チケットに新しいコメントが追加されます。

GitLabは[デフォルトの`thank_you`メール](configure.md#customize-emails-sent-to-external-participants)を送信しません。チケットに公開コメントを追加して、エンドユーザーにチケットが作成されたことを知らせることができます。

## プライバシーに関する考慮事項 {#privacy-considerations}

{{< history >}}

- GitLab 15.9で作成者と参加者のメールを表示するために必要な最小ロールが[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108901)されました。

{{< /history >}}

サービスデスクチケットは[機密](../issues/confidential_issues.md)であるため、プロジェクトメンバーのみに表示されます。プロジェクトオーナーは[チケットを公開](../issues/confidential_issues.md#in-an-existing-issue)できます。サービスデスクチケットが公開されると、チケット作成者と参加者のメールアドレスは、プロジェクトに対してレポーター、デベロッパー、メンテナー、またはオーナーロールを持つサインインユーザーに表示されます。

GitLab 15.8および以前では、サービスデスクチケットが公開されると、チケット作成者のメールアドレスは、プロジェクトを表示できる全員に開示されます。

プロジェクト内の誰でも、サービスデスクのメールアドレスを使用して、プロジェクト内のチケットを作成できます。**regardless of their role**。

固有の内部メールアドレスは、GitLabインスタンスで少なくともプランナーロールを持つプロジェクトメンバーに表示されます。外部ユーザー（チケット作成者）は、情報メモに表示されている内部メールアドレスを見ることはできません。

### サービスデスクチケットの移動 {#moving-a-service-desk-ticket}

{{< history >}}

- GitLab 15.7で、サービスデスクチケットが移動された場合でも顧客は引き続き通知を受け取るように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/372246)されました。

{{< /history >}}

GitLabで[通常のイシューを移動](../issues/managing_issues.md#move-an-issue)するのと同じ方法でサービスデスクチケットを移動できます。

サービスデスクが有効な別のプロジェクトにサービスデスクチケットが移動された場合、チケットを作成者した顧客は引き続きメール通知を受け取ります。移動されたチケットはまず閉じられ、その後コピーされるため、顧客は両方のチケットの参加者と見なされます。彼らは古いチケットと新しいチケットの両方で通知を受け取り続けます。
