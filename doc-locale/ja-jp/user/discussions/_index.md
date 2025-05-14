---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use comments to discuss work, mention users, and suggest changes.
title: コメントとスレッド
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- ページ分割されたマージリクエストのディスカッションは、GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/340172) され、`paginated_mr_discussions`という名前の[フラグ](../../administration/feature_flags.md)が付けられました。デフォルトでは無効になっています。
- ページ分割されたマージリクエストのディスカッションは、GitLab 15.2の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/364497)になりました。
- ページ分割されたマージリクエストのディスカッションは、GitLab 15.3で[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/364497)になりました。
- ページ分割されたマージリクエストのディスカッションは、GitLab 15.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/370075)されました。機能フラグ`paginated_mr_discussions`を削除しました。
- Wikiページのコメントとスレッドは、GitLab 17.7で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14461)され、`wiki_comments`という名前の[フラグ](../../administration/feature_flags.md)が付けられました。デフォルトでは無効になっています。
- Wikiページのコメントとスレッドは、GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/502847)されました。機能フラグ`wiki_comments`を削除しました。

{{< /history >}}

GitLabでは、コメント、スレッド、[コードの変更提案](../project/merge_requests/reviews/suggestions.md)を通じてコミュニケーションを奨励しています。コメントは[Markdown](../markdown.md)と[クイック アクション](../project/quick_actions.md)をサポートしています。

次の2種類のコメントを使用できます。

- 標準コメント。
- スレッド内のコメント。これは[解決](../project/merge_requests/_index.md#resolve-a-thread)できます。

コミット差分コメントで[コードの変更を提案](../project/merge_requests/reviews/suggestions.md)できます。ユーザーは、ユーザーインターフェースからその提案を承認できます。

## コメントを追加できる場所

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

## メンション

GitLabインスタンス内のユーザーまたはグループ（[サブグループ](../group/subgroups/_index.md#mention-subgroups)を含む）を、`@username`または`@groupname`でメンションできます。GitLabは、メンションされたすべてのユーザーにto-doアイテムとメールを通知します。ユーザーは、[通知設定](../profile/notifications.md)でこの設定を自分で変更できます。

GitLabでは、自分（現在の認証済みユーザー）へのメンションが別の色で強調表示されるため、どのコメントが自分に関係するのかをすばやく確認できます。

### すべてのメンバーにメンションする

{{< history >}}

- [フラグ](../../administration/feature_flags.md)`disable_all_mention`は、GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110586)されました。デフォルトでは無効になっています。[GitLab.comで有効になっています。](https://gitlab.com/gitlab-org/gitlab/-/issues/18442)

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については履歴を参照してください。

{{< /alert >}}

コメントと説明では、`@all`のメンションは避けてください。`@all`は、プロジェクト、イシュー、またはマージリクエストの参加者だけでなく、そのプロジェクトの親グループのすべてのメンバーもメンションするためです。メンションされたユーザーが、このメール通知とto-doアイテムを受け取った結果、スパムであると受け取ってしまう可能性があります。

この機能フラグを有効にすると、コメントと説明に`@all`と入力すると、すべてのユーザーをメンションする代わりにプレーンテキストになります。この機能を無効にすると、Markdownテキスト内の既存の`@all`メンションは変更されず、リンクとして残ります。今後の`@all`メンションのみがプレーンテキストとして表示されます。

通知とメンションは、[グループの設定](../group/manage.md#disable-email-notifications)で無効にできます。

### イシューまたはマージリクエストでグループをメンションする

コメントでグループをメンションすると、グループのすべてのメンバーのto-doアイテムがto-doリストに追加されます。

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを見つけます。
1. マージリクエストの場合は、**コード > マージリクエスト**を選択し、マージリクエストを見つけます。
1. イシューの場合は、**プラン > イシュー**を選択し、イシューを見つけます。
1. コメントで、`@`の後にユーザー、グループ、またはサブグループのネームスペースを入力します。たとえば、`@alex`、`@alex-team`、または`@alex-team/marketing`などです。
1. **コメント**を選択します。

GitLabは、すべてのグループおよびサブグループメンバーのto-doアイテムを作成します。

サブグループのメンションの詳細については、[サブグループをメンションする](../group/subgroups/_index.md#mention-subgroups)を参照してください。

## マージリクエストの差分にコメントを追加する

マージリクエストの差分にコメントを追加すると、次の場合でも、これらのコメントは保持されます。

- rebase後に強制プッシュする。
- コミットを修正する。

コミット差分コメントを追加するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを見つけます。
1. **コード > マージリクエスト**を選択し、マージリクエストを見つけます。
1. **コミット**タブを選択し、コミットメッセージを選択します。
1. コメントする行の横にある行番号にカーソルを合わせ、**コメント**（{{< icon name="comment" >}}）を選択します。**コメント**（{{< icon name="comment" >}}）アイコンをドラッグして、複数行を選択できます。
1. コメントを入力します。
1. コメントをすぐに送信するには、**今すぐコメントを追加**を選択するか、キーボードショートカットを使用します。
   - macOS: <kbd>Shift</kbd> + <kbd>Command</kbd> + <kbd>Enter</kbd>
   - その他すべてのOS: <kbd>Shift</kbd> + <kbd>Control</kbd> + <kbd>Enter</kbd>
1. レビューを完了するまでコメントを公開しないようにするには、**レビューを開始**を選択するか、キーボードショートカットを使用します。
   - macOS: <kbd>Command</kbd> + <kbd>Enter</kbd>
   - その他すべてのOS: <kbd>Control</kbd> + <kbd>Enter</kbd>

コメントは、マージリクエストの**概要**タブに表示されます。

コメントは、プロジェクトの**コード > コミット**ページには表示されません。

{{< alert type="note" >}}

コメントにマージリクエストに含まれるコミットへの参照が含まれている場合、マージリクエストのコンテキストではリンクに変換されます。たとえば、`28719b171a056960dfdc0012b625d0b47b123196`は`28719b17`になり、`https://gitlab.example.com/example-group/example-project/-/merge_requests/12345/diffs?commit_id=28719b171a056960dfdc0012b625d0b47b123196`にリンクされます。

{{< /alert >}}

## メールを送信してコメントに返信する

[「reply by email（メールで返信）」](../../administration/reply_by_email.md)が構成されている場合は、メールを送信してコメントに返信できます。

- 標準コメントに返信すると、別の標準コメントが作成されます。
- スレッドコメントに返信すると、スレッドに返信が作成されます。
- [イシューのメールアドレスにメールを送信](../project/issues/managing_issues.md#copy-issue-email-address)すると、標準コメントが作成されます。

メールの返信で、[Markdown](../markdown.md)と[クイックアクション](../project/quick_actions.md)を使用できます。

## コメントを編集する

自分のコメントはいつでも編集できます。メンテナー以上の役割を持つユーザーは、他のユーザーが作成したコメントも編集できます。

コメントを編集するには、次の手順に従います。

1. コメントで、**コメントの編集**（{{< icon name="pencil" >}}）を選択します。
1. 編集を行います。
1. **変更を保存**を選択します。

### メンションを追加するためにコメントを編集する

デフォルトでは、ユーザーをメンションすると、GitLabは[そのユーザーのto-doアイテムを作成](../todos.md#actions-that-create-to-do-items)し、[通知メール](../profile/notifications.md)を送信します。

既存のコメントを編集して、以前になかったユーザーメンションを追加すると、GitLabは次のようになります。

- メンションされたユーザーのto-doアイテムを作成します。
- 通知メールは送信されません。

## ディスカッションをロックしてコメントを防止する

イシューまたはマージリクエストでパブリックコメントを防止できます。その場合、プロジェクトメンバーのみがコメントを追加および編集できます。

前提要件:

- マージリクエストでは、少なくともデベロッパーの役割が必要です。
- イシューでは、少なくともレポーターの役割が必要です。

イシューまたはマージリクエストをロックするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを見つけます。
1. マージリクエストの場合は、**コード > マージリクエスト**を選択し、マージリクエストを見つけます。
1. イシューの場合は、**プラン > イシュー**を選択し、イシューを見つけます。
1. 右上隅で、**マージリクエストアクション**または**イシューアクション**（{{< icon name="ellipsis_v" >}}）を選択し、**ディスカッションのロック**を選択します。

GitLabが、システムノートをページの詳細に追加します。

イシューまたはマージリクエストを再度開くには、クローズされたイシューまたはマージリクエストで、ロックされたすべてのディスカッションのロックを解除する必要があります。

## 内部メモを追加する

{{< history >}}

- GitLab 15.0で「機密コメント」から「内部メモ」に[名前変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87403)されました。
- GitLab 15.0の[GitLab.comおよびGitLab Self-Managedで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87383)。
- GitLab 15.2で、[機能フラグ`confidential_notes`](https://gitlab.com/gitlab-org/gitlab/-/issues/362712)が削除されました。
- GitLab 15.6で、少なくともレポーターの役割が必要であるように権限が[変更されました。](https://gitlab.com/gitlab-org/gitlab/-/issues/363045)GitLab 15.5以前では、イシューまたはエピックの作成者と担当者も内部メモを読み書きできました。
- GitLab 16.9で、マージリクエストの内部コメントが[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142003)されました。

{{< /history >}}

_公開_イシュー、エピック、またはマージリクエストに追加された情報を保護するには、内部メモを使用します。内部メモは公開コメントとは異なります。

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

## コメントのみを表示する

コメントが多いディスカッションでは、ディスカッションをフィルタリングして、コメントまたは変更履歴（[システムノート](../project/system_notes.md)）のみを表示します。システムノートには、説明の変更、他のGitLabオブジェクトでのメンション、またはラベル、担当者、マイルストーンへの変更が含まれます。GitLabは設定を保存し、表示するすべてのイシュー、マージリクエスト、またはエピックに適用します。

1. マージリクエスト、イシュー、またはエピックで、**概要**タブを選択します。
1. ページの右側にある**並べ替えとフィルタリング**ドロップダウンリストから、次のフィルタを選択します。
   - **すべてのアクティビティーを表示**: すべてのユーザーコメントとシステムノートを表示します。
   - **コメントのみ表示**: ユーザーコメントのみを表示します。
   - **履歴のみ表示**: アクティビティノートのみを表示します。

## アクティビティの並べ替え順序を変更する

既定の順序を逆にして、上部に最新のアイテムが並べ替えられたアクティビティフィードを操作します。GitLabはローカルストレージに設定を保存し、表示するすべてのイシュー、マージリクエスト、またはエピックに適用します。

アクティビティの並べ替え順序を変更するには、次の手順に従います。

1. マージリクエスト、イシュー、またはエピックで、**概要**タブを開きます。
1. ページの右側にある**並べ替えとフィルタリング**ドロップダウンリストから、並べ替え順序**新しい順**または**古い順**（デフォルト）を選択します。

## 説明の変更履歴を表示する

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

履歴にリストされている説明への変更を確認できます。

変更を比較するには、**前のバージョンと比較**を選択します。

## コメントしているユーザーにイシューを割り当てる

コメントをしたユーザーにイシューを割り当てることができます。

1. コメントで、**その他のアクション**（{{< icon name="ellipsis_v" >}}）メニューを選択します。
1. **コメントするユーザーにアサインする**を選択します: ![コメントするユーザーにアサインする](img/quickly_assign_commenter_v16_6.png)
1. コメンターの割り当てを解除するには、ボタンをもう一度選択します。

## 標準コメントに返信してスレッドを作成する

標準コメントに返信すると、スレッドが作成されます。

前提要件:

- 少なくともゲストの役割が必要です。
- イシュー、マージリクエスト、またはエピックにいる必要があります。コミットとスニペットのスレッドはサポートされていません。

コメントに返信してスレッドを作成するには、次の手順に従います。

1. コメントの右上隅にある**コメントに返信**（{{< icon name="reply" >}}）を選択して、返信セクションを表示します。
1. 返信を入力します。
1. **返信**または**今すぐコメントを追加**（UIのどこに返信しているかによって異なります）を選択します。

GitLabは、上部のコメントをスレッドに変換します。

## コメントに返信せずにスレッドを作成する

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

## スレッドを解決する

{{< history >}}

- イシューの解決可能なスレッドは、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/31114)され、`resolvable_issue_threads`という名前の[フラグ](../../administration/feature_flags.md)が付けられました。デフォルトでは無効になっています。
- GitLab 16.4で、イシューの解決可能なスレッドが[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/31114)になりました。
- GitLab 16.7で、イシューの解決可能なスレッドが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/31114)されました。機能フラグ`resolvable_issue_threads`を削除しました。
- タスク、目標、および主な成果の解決可能なスレッドは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/458818)されました。
- エピックの解決可能なスレッドは、GitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/458818)されました。[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。

{{< /history >}}

会話を終了したい場合は、スレッドを解決できます。

前提要件:

- エピック、イシュー、タスク、目標、主な成果、またはマージリクエストにいる必要があります。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。
- 少なくともデベロッパーロールを持っているか、イシューまたはマージリクエストの作成者である必要があります。

スレッドを解決するには、次の手順に従います。

1. スレッドに移動します。
1. 次のいずれかを実行します。
   - 元のコメントの右上隅で、**スレッドを解決します。** ({{< icon name="check-circle" >}}) を選択します。
   - 最後の返信の下にある **返信** 欄で、**スレッドを解決します。** を選択します。
   - 最後の返信の下にある **返信**欄にテキストを入力し、**スレッドを解決にします。**チェックボックスを選択して、**今すぐコメントを追加**を選択します。

さらに、マージリクエストでは、[スレッドでより多くのことを行う](../project/merge_requests/_index.md#resolve-a-thread)ことができます。たとえば、次の通りです。

- 未解決のスレッドを新しいイシューに移動する。
- すべてのスレッドが解決されるまで、マージを禁止する。

## GitLab Duo Chatでイシューのディスカッションを要約する

{{< details >}}

- プラン: GitLab Duo Enterprise を含む Ultimate - [トライアルを開始](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- GitLab Self-Managed、GitLab Dedicated のLLM: Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)
- GitLab.comのLLM: Anthropic [Claude 3.7 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-7-sonnet)

{{< /details >}}

{{< history >}}

- [実験的機能](https://gitlab.com/groups/gitlab-org/-/epics/10344)としてGitLab 16.0で[導入](../../policy/development_stages_support.md#experiment)されました。
- GitLab Duoに[移行](https://gitlab.com/gitlab-org/gitlab/-/issues/454550)し、GitLab 17.3で`summarize_notes_with_duo`という名前の[フラグ](../../administration/feature_flags.md)付きで、[ベータ](../../policy/development_stages_support.md#beta)にプロモートしました。デフォルトでは無効になっています。
- GitLab 17.4では、[デフォルトで有効になっています](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162122)。
- GitLab 17.6以降では、GitLab Duoアドオンが必須となりました。

{{< /history >}}

イシューに関するディスカッションのサマリーを生成します。

前提要件:

- イシューを表示する権限が必要です。

イシューのディスカッションのサマリーを生成するには、次の手順に従います。

1. イシューで、**アクティビティー** セクションまでスクロールします。
1. **サマリーを表示**を選択します。

イシューのコメントが、最大10個のリスト項目に要約されます。回答に基づいてフォローアップの質問をすることができます。

**データ使用量**: この機能を使用すると、イシューのすべてのコメントのテキストが大規模言語モデルに送信されます。
