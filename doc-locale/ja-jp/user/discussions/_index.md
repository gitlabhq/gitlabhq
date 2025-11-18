---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: コメントを使用して、作業について話し合ったり、ユーザーにメンションしたり、変更を提案したりできます。
title: コメントとスレッド
description: メンション、ロックされたディスカッション、内部メモ、およびスレッドの解決。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- Wikiページのコメントとスレッドは、GitLab 17.7で`wiki_comments`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/14461)されました。デフォルトでは無効になっています。
- Wikiページのコメントとスレッドは、GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/502847)になりました。機能フラグ`wiki_comments`は削除されました。

{{< /history >}}

GitLabでは、コメント、スレッド、[コードの変更提案](../project/merge_requests/reviews/suggestions.md)を通じてコミュニケーションを奨励しています。コメントは[Markdown](../markdown.md)と[クイックアクション](../project/quick_actions.md)をサポートしています。

次の2種類のコメントを使用できます。

- 標準コメント。
- スレッド内のコメント。これは[解決](../project/merge_requests/_index.md#resolve-a-thread)できます。

コミット差分コメントで[コードの変更を提案](../project/merge_requests/reviews/suggestions.md)できます。ユーザーは、UIからその提案を承認できます。

## コメントを追加できる場所 {#places-you-can-add-comments}

次のような場所にコメントを作成できます。

- コミットの差分。
- コミット。
- デザイン。
- エピック。
- イシュー。
- マージリクエスト。
- スニペット。
- タスク。
- OKR。
- Wikiページ。

各オブジェクトには、最大5,000件のコメントを付けることができます。

## メンション {#mentions}

GitLabインスタンス内のユーザーまたはグループ（[サブグループ](../group/subgroups/_index.md#mention-subgroups)を含む）を、`@username`または`@groupname`でメンションできます。GitLabは、メンションされたすべてのユーザーにto-doアイテムとメールを通知します。ユーザーは、[通知設定](../profile/notifications.md)でこの設定を自分で変更できます。

GitLabでは、自分（現在の認証済みユーザー）へのメンションが別の色で強調表示されるため、どのコメントが自分に関係するのかをすばやく確認できます。

### すべてのメンバーにメンションする {#mentioning-all-members}

{{< history >}}

- [フラグ](../../administration/feature_flags/_index.md)`disable_all_mention`はGitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110586)されました。デフォルトでは無効になっています。[GitLab.comで有効になっています。](https://gitlab.com/gitlab-org/gitlab/-/issues/18442)

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

コメントと説明では、`@all`のメンションは避けてください。`@all`は、プロジェクト、イシュー、またはマージリクエストの参加者だけでなく、そのプロジェクトの親グループのすべてのメンバーもメンションするためです。メンションされたユーザーが、このメール通知とto-doアイテムを受け取った結果、スパムであると受け取ってしまう可能性があります。

この機能フラグを有効にすると、コメントと説明に`@all`と入力すると、すべてのユーザーをメンションする代わりにプレーンテキストになります。この機能を無効にすると、Markdownテキスト内の既存の`@all`メンションは変更されず、リンクとして残ります。今後の`@all`メンションのみがプレーンテキストとして表示されます。

通知とメンションは、[グループの設定](../group/manage.md#disable-email-notifications)で無効にできます。

### イシューまたはマージリクエストでグループをメンションする {#mention-a-group-in-an-issue-or-merge-request}

コメントでグループをメンションすると、グループのすべてのメンバーのto-doアイテムがto-doリストに追加されます。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. マージリクエストの場合は、**コード > マージリクエスト**を選択して、マージリクエストを見つけます。
1. イシューの場合は、**計画 > イシュー**を選択して、イシューを見つけます。
1. コメントで、`@`の後にユーザー、グループ、またはサブグループのネームスペースを入力します。たとえば、`@alex`、`@alex-team`、または`@alex-team/marketing`などです。
1. **コメント**を選択します。

GitLabは、すべてのグループおよびサブグループメンバーのto-doアイテムを作成します。

サブグループのメンションの詳細については、[サブグループをメンションする](../group/subgroups/_index.md#mention-subgroups)を参照してください。

## マージリクエストの差分にコメントを追加する {#add-a-comment-to-a-merge-request-diff}

マージリクエストの差分にコメントを追加すると、次の場合でも、これらのコメントは保持されます。

- リベース後に強制プッシュする。
- コミットを修正する。

コミット差分コメントを追加するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード > マージリクエスト**を選択して、マージリクエストを見つけます。
1. **コミット**タブを選択し、コミットメッセージを選択します。
1. コメントを開始します。
   - ファイル全体にコメントするには、コメントするファイルを見つけ、ファイルヘッダーで、**このファイルにコメントする**（{{< icon name="comment" >}}）を選択します。
   - 特定の行にコメントするには、コメントする行番号を見つけます。行番号にカーソルを合わせるて、**コメント**（{{< icon name="comment" >}}）を選択します。複数の行を選択するには、**コメント**（{{< icon name="comment" >}}）アイコンをドラッグします。
1. コメントを入力します。
1. コメントを送信します。
   - コメントをすぐに送信するには、**今すぐコメントを追加**を選択するか、キーボードショートカットを使用します。
     - macOS: <kbd>Shift</kbd> + <kbd>Command</kbd> + <kbd>Enter</kbd>
     - その他すべてのOS: <kbd>Shift</kbd> + <kbd>Control</kbd> + <kbd>Enter</kbd>
   - レビューを完了するまでコメントを公開しないようにするには、**レビューを開始**を選択するか、キーボードショートカットを使用します。
     - macOS: <kbd>Command</kbd> + <kbd>Enter</kbd>
     - その他すべてのOS: <kbd>Control</kbd> + <kbd>Enter</kbd>

コメントは、マージリクエストの**概要**タブに表示されます。

コメントは、プロジェクトの**コード > コミット**ページには表示されません。

{{< alert type="note" >}}

コメントにマージリクエストに含まれるコミットへの参照が含まれている場合、マージリクエストのコンテキストではリンクに変換されます。たとえば、`28719b171a056960dfdc0012b625d0b47b123196`は`28719b17`になり、`https://gitlab.example.com/example-group/example-project/-/merge_requests/12345/diffs?commit_id=28719b171a056960dfdc0012b625d0b47b123196`にリンクされます。

{{< /alert >}}

## メールを送信してコメントに返信する {#reply-to-a-comment-by-sending-email}

[「メールで返信」](../../administration/reply_by_email.md)が構成されている場合は、メールを送信してコメントに返信できます。

- 標準コメントに返信すると、別の標準コメントが作成されます。
- スレッドコメントに返信すると、スレッドに返信が作成されます。
- [イシューのメールアドレスにメールを送信](../project/issues/managing_issues.md#copy-issue-email-address)すると、標準コメントが作成されます。

メールの返信で、[Markdown](../markdown.md)と[クイックアクション](../project/quick_actions.md)を使用できます。

## コメントを編集する {#edit-a-comment}

自分のコメントはいつでも編集できます。メンテナー以上の役割を持つユーザーは、他のユーザーが作成したコメントも編集できます。

コメントを編集するには、次の手順に従います。

1. コメントで、**コメントの編集**（{{< icon name="pencil" >}}）を選択します。
1. 編集を行います。
1. **変更を保存**を選択します。

### メンションを追加するためにコメントを編集する {#edit-a-comment-to-add-a-mention}

デフォルトでは、ユーザーをメンションすると、GitLabは[そのユーザーのto-doアイテムを作成](../todos.md#actions-that-create-to-do-items)し、[通知メール](../profile/notifications.md)を送信します。

既存のコメントを編集して、以前になかったユーザーメンションを追加すると、GitLabは次のようになります。

- メンションされたユーザーのto-doアイテムを作成します。
- 通知メールは送信されません。

## ディスカッションをロックしてコメントを防止する {#prevent-comments-by-locking-the-discussion}

イシューまたはマージリクエストでパブリックコメントを防止できます。その場合、プロジェクトメンバーのみがコメントを追加および編集できます。

前提要件: 

- マージリクエストでは、少なくともデベロッパーの役割が必要です。
- イシューでは、少なくともレポーターの役割が必要です。

イシューまたはマージリクエストをロックするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. マージリクエストの場合は、**コード > マージリクエスト**を選択して、マージリクエストを見つけます。
1. イシューの場合は、**計画 > イシュー**を選択して、イシューを見つけます。
1. 右上隅で、**マージリクエストアクション**または**イシューアクション**（{{< icon name="ellipsis_v" >}}）を選択し、**ディスカッションのロック**を選択します。

GitLabが、システムノートをページの詳細に追加します。

イシューまたはマージリクエストを再度開くには、クローズされたイシューまたはマージリクエストで、ロックされたすべてのディスカッションのロックを解除する必要があります。

## 機密アイテムに関するコメント {#comments-on-confidential-items}

機密アイテムにアクセスする権限を持つユーザーのみが、そのアイテムに関するコメントの通知を受け取ります。アイテムが以前に機密にされていなかった場合、アクセス権のないユーザーが参加者として表示されることがあります。これらのユーザーは、アイテムが機密である間は通知を受け取りません。

通知を受け取ることができるユーザー:

- ロールに関係なく、アイテムに割り当てられたユーザー。
- 少なくともゲストロールを持つ場合、アイテムを作成したユーザー。
- アイテムが属するグループまたはプロジェクト内で、少なくともプランナーロールを持つユーザー。

## 内部メモを追加する {#add-an-internal-note}

{{< history >}}

- GitLab 16.9で、マージリクエストの内部コメントが[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142003)されました。

{{< /history >}}

公開イシュー、エピック、またはマージリクエストに追加された情報を保護するには、内部メモを使用します。内部メモは公開コメントとは異なります。

- 少なくともレポーターの役割を持つプロジェクトメンバーのみが、内部メモを表示できます。
- 内部メモを通常のコメントに変換することはできません。
- 内部メモへのすべての返信も内部ノートです。
- 内部メモには**内部メモ**バッジが表示され、公開コメントとは異なる色で表示されます。

![内部メモ](img/add_internal_note_v16_9.png)

前提要件: 

- プロジェクトのレポーターロール以上を持っている必要があります。

内部メモを追加するには、次の手順に従います。

1. イシュー、エピック、またはマージリクエストの**コメント**テキストボックスに、コメントを入力します。
1. コメントの下にある**これを内部メモにする**を選択します。
1. **内部メモを追加**を選択します。

イシュー全体を[機密としてマーク](../project/issues/confidential_issues.md)したり、[機密マージリクエスト](../project/merge_requests/confidential.md)を作成したりすることもできます。

## コメントのみを表示する {#show-only-comments}

コメントが多いディスカッションでは、ディスカッションをフィルターリングして、コメントまたは変更履歴（[システムノート](../project/system_notes.md)）のみを表示します。システムノートには、説明の変更、他のGitLabオブジェクトでのメンション、またはラベル、担当者、マイルストーンへの変更が含まれます。GitLabは設定を保存し、表示するすべてのイシュー、マージリクエスト、またはエピックに適用します。

1. マージリクエスト、イシュー、またはエピックで、**概要**タブを選択します。
1. ページの右側にある**並べ替えとフィルタリング**ドロップダウンリストから、次のフィルターを選択します。
   - **すべてのアクティビティーを表示**: すべてのユーザーコメントとシステムノートを表示します。
   - **コメントのみ表示**: ユーザーコメントのみを表示します。
   - **履歴のみ表示**: アクティビティノートのみを表示します。

## アクティビティの並べ替え順序を変更する {#change-activity-sort-order}

既定の順序を逆にして、上部に最新のアイテムが並べ替えられたアクティビティフィードを操作します。GitLabはローカルストレージに設定を保存し、表示するすべてのイシュー、マージリクエスト、またはエピックに適用します。イシューとエピックは同じ並べ替え設定を共有しますが、マージリクエストはそれぞれ個別の設定を保持します。

アクティビティの並べ替え順序を変更するには、次の手順に従います。

1. イシューを開くか、マージリクエストまたはエピックで**概要**タブを開きます。
1. **アクティビティ**の見出しまでスクロールします。
1. ページの右側で、並べ替え順序を変更します。
   - **イシューとエピック**: **並べ替えとフィルタリング**ドロップダウンリストから、**新しい順**または**古い順**（デフォルト）を選択します。
   - **マージリクエスト**: 並べ替え方向の矢印ボタンを使用して、**ソート順: 昇順**（古い順、デフォルト）または**ソート順: 降順**（新しい順）を切り替えます。

## 説明の変更履歴を表示する {#view-description-change-history}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

履歴にリストされている説明への変更を確認できます。

変更を比較するには、**前のバージョンと比較**を選択します。

## コメントしているユーザーにイシューを割り当てる {#assign-an-issue-to-the-commenting-user}

コメントをしたユーザーにイシューを割り当てることができます。

1. コメントで、**その他のアクション**（{{< icon name="ellipsis_v" >}}）メニューを選択します。
1. **コメント作成者にアサインする**を選択します。
1. コメンターの割り当てを解除するには、ボタンをもう一度選択します。

## 標準コメントに返信してスレッドを作成する {#create-a-thread-by-replying-to-a-standard-comment}

標準コメントに返信すると、スレッドが作成されます。

前提要件: 

- 少なくともゲストの役割が必要です。
- イシュー、マージリクエスト、またはエピックにいる必要があります。コミットとスニペットのスレッドはサポートされていません。

コメントに返信してスレッドを作成するには、次の手順に従います。

1. コメントの右上隅にある**コメントに返信**（{{< icon name="reply" >}}）を選択して、返信セクションを表示します。
1. 返信を入力します。
1. **返信**または**今すぐコメントを追加**（UIのどこに返信しているかによって異なります）を選択します。

GitLabは、上部のコメントをスレッドに変換します。

## コメントに返信せずにスレッドを作成する {#create-a-thread-without-replying-to-a-comment}

標準コメントに返信せずにスレッドを作成できます。

前提要件: 

- 少なくともゲストの役割が必要です。
- イシュー、マージリクエスト、コミット、またはスニペットにいる必要があります。

スレッドを作成するには、次の手順に従います。

1. コメントを入力します。
1. コメントの下の**コメント**の右側にある下矢印（{{< icon name="chevron-down" >}}）を選択します。
1. リストから、**スレッドを開始**を選択します。
1. もう一度**スレッドを開始**を選択します。

![スレッドを作成する](img/create_thread_v16_6.png)

## スレッドを解決する {#resolve-a-thread}

{{< history >}}

- イシューの解決可能なスレッドは、GitLab 16.3で`resolvable_issue_threads`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/31114)されました。デフォルトでは無効になっています。
- GitLab 16.4で、イシューの解決可能なスレッドが[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/31114)になりました。
- GitLab 16.7で、イシューの解決可能なスレッドが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/31114)になりました。機能フラグ`resolvable_issue_threads`は削除されました。
- タスク、目標、および主な成果の解決可能なスレッドは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/458818)になりました。
- エピックの解決可能なスレッドは、GitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/458818)されました。[エピックの新しい外観](../group/epics/_index.md#epics-as-work-items)を有効にする必要があります。
- エピックの解決可能なスレッドが、GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/468310)になりました。

{{< /history >}}

会話を終了したい場合は、スレッドを解決できます。

前提要件: 

- エピック、イシュー、タスク、目標、主な成果、またはマージリクエストにいる必要があります。
- 少なくともデベロッパーロールを持っているか、イシューまたはマージリクエストの作成者である必要があります。

スレッドを解決するには、次の手順に従います。

1. スレッドに移動します。
1. 次のいずれかを実行します。
   - 元のコメントの右上隅で、**スレッドを解決する** （{{< icon name="check-circle" >}}）を選択します。
   - 最後の返信の下にある**返信**欄で、**スレッドを解決する**を選択します。
   - 最後の返信の下にある**返信**欄にテキストを入力し、**スレッドを解決にする**チェックボックスを選択して、**今すぐコメントを追加**を選択します。

さらに、マージリクエストでは、[スレッドでより多くのことを行う](../project/merge_requests/_index.md#resolve-a-thread)ことができます。たとえば、次の通りです。

- 新しいイシューに未解決のスレッドを移動します。
- すべてのスレッドが解決されるまで、マージを禁止する。

## Duo Chatでイシューのディスカッションを要約する {#summarize-issue-discussions-with-duo-chat}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- GitLab Self-Managed、GitLab DedicatedのLLM: Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)
- GitLab.comのLLM: Anthropic [Claude 3.7 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-7-sonnet)
- Amazon QのLLM: Amazon Q Developer
- [GitLab Duoセルフホストモデル](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能です。はい

{{< /details >}}

{{< history >}}

- GitLab 16.0で[実験的機能](../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/10344)されました。
- GitLab Duoに[移行](https://gitlab.com/gitlab-org/gitlab/-/issues/454550)し、GitLab 17.3で`summarize_notes_with_duo`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ](../../policy/development_stages_support.md#beta)にプロモートしました。デフォルトでは無効になっています。
- GitLab 17.4では、[デフォルトで有効になっています](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162122)。
- GitLab 17.6以降では、GitLab Duoアドオンが必須となりました。
- GitLab 18.0で、Premiumを含めるように変更されました。

{{< /history >}}

イシューに関するディスカッションのサマリーを生成します。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[概要を見る](https://www.youtube.com/watch?v=IcdxLfTIUgc)
<!-- Video published on 2024-03-28 -->

前提要件: 

- イシューを表示する権限が必要です。

イシューのディスカッションのサマリーを生成するには、次の手順に従います。

1. イシューで、**アクティビティー**セクションまでスクロールします。
1. **サマリーを表示**を選択します。

イシューのコメントが、最大10個のリスト項目に要約されます。回答に基づいてフォローアップの質問をすることができます。

データ使用量: この機能を使用すると、イシューのすべてのコメントのテキストが大規模言語モデルに送信されます。
