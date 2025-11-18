---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: イシューを作成する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

イシューを作成する際、イシューのフィールドへの入力が求められます。イシューに割り当てる値がわかっている場合は、[クイックアクション](../quick_actions.md)を使用して入力できます。

GitLabでは、次の複数の方法でイシューを作成できます:

- [プロジェクトから](#from-a-project)
- [グループから](#from-a-group)
- [別のイシューまたはインシデントから](#from-another-issue-or-incident)
- [イシューボードから](#from-an-issue-board)
- [メールを送信する](#by-sending-an-email)
- [値を事前に入力したURLを使用する](#using-a-url-with-prefilled-values)
- [サービスデスクを使用する](#using-service-desk)

## プロジェクトから {#from-a-project}

前提要件:

- プロジェクトのゲストロール以上が必要です。

イシューを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 次のいずれかの操作を行います:

   - 左側のサイドバーで**Plan** > **イシュー**を選択し、右上隅にある**新規イシュー**を選択します。
   - 左側のサイドバーの上部にあるプラス記号（{{< icon name="plus" >}}）を選択し、**このプロジェクト内で**、**新規イシュー**を選択します。

1. [フィールド](#fields-in-the-new-issue-form)に入力します。
1. **イシューの作成**を選択します。

新しく作成されたイシューが開きます。

## グループから {#from-a-group}

イシューはプロジェクトに属していますが、グループに所属している場合、グループ内のプロジェクトに属するイシューにアクセスしたり、作成したりできます。

前提要件:

- グループ内のプロジェクトに対するゲストロール以上が必要です。

グループからイシューを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **Plan** > **イシュー**を選択します。
1. 右上隅で、**Select project to create issue**（イシューを作成するプロジェクトを選択）を選択します。
1. イシューを作成するプロジェクトを選択します。選択したプロジェクトがボタンに反映されます。
1. **New issue in `<project name>`**（で新規イシュー）を選択します。
1. [フィールド](#fields-in-the-new-issue-form)に入力します。
1. **イシューの作成**を選択します。

新しく作成されたイシューが開きます。

最近選択したプロジェクトが、次回のアクセス時のデフォルトになります。同じプロジェクトのイシューを頻繁に作成する場合、これにより時間を大幅に節約できます。

## 別のイシューまたはインシデントから {#from-another-issue-or-incident}

既存のイシューから新しいイシューを作成できます。2つのイシューを関連付けることができます。

前提要件:

- プロジェクトのゲストロール以上が必要です。

別のイシューからイシューを作成するには:

1. 既存のイシューで、**Issue actions**（イシューアクション）（{{< icon name="ellipsis_v" >}}）を選択します。
1. **New related issue**（新規関連イシュー）を選択します。
1. [フィールド](#fields-in-the-new-issue-form)に入力します。新しいイシューフォームには、**Relate to issue #123**（イシュー#123に関連付ける）チェックボックスがあります。`123`はoriginのイシューのIDです。このチェックボックスをオンにすると、2つのイシューが[リンク](related_issues.md)されます。
1. **イシューの作成**を選択します。

新しく作成されたイシューが開きます。

## イシューボードから {#from-an-issue-board}

[イシューボード](../issue_board.md)から新しいイシューを作成できます。

前提要件:

- プロジェクトのゲストロール以上が必要です。

プロジェクトイシューボードからイシューを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシューボード**を選択します。
1. ボードリストの上部で、**イシューの新規作成**（{{< icon name="plus-square" >}}）を選択します。
1. イシューのタイトルを入力します。
1. **イシューの作成**を選択します。

グループイシューボードからイシューを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **Plan** > **イシューボード**を選択します。
1. ボードリストの上部で、**イシューの新規作成**（{{< icon name="plus-square" >}}）を選択します。
1. イシューのタイトルを入力します。
1. **プロジェクト**で、イシューを割り当てるグループ内のプロジェクトを選択します。
1. **イシューの作成**を選択します。

イシューが作成され、ボードリストに表示されます。リストの特性を共有するため、リストのスコーピングがラベル`Frontend`に設定されている場合、新しいイシューにもこのラベルが設定されます。

## メールを送信する {#by-sending-an-email}

プロジェクトの**イシュー**ページで、プロジェクト内にイシューを作成するメールを送信できます。

前提要件:

- ご利用のGitLabインスタンスで、[すべてをキャッチするメールボックス](../../../administration/incoming_email.md#requirements)を使用して、[受信メール](../../../administration/incoming_email.md)を設定する必要があります。
- イシューリストに、少なくとも1つのイシューが必要です。
- プロジェクトのゲストロール以上が必要です。

プロジェクトにイシューをメールで送信するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択します。
1. ページの下部にある**Email a new issue to this project**（新規イシューをこのプロジェクトにメールで送信）を選択します。
1. **コピー**（{{< icon name="copy-to-clipboard" >}}）を選択して、メールアドレスをコピーします。
1. メールクライアントから、このアドレスにメールを送信します。件名が新しいイシューのタイトルとして使用され、メール本文が説明になります。[Markdown](../../markdown.md)と[クイックアクション](../quick_actions.md)を使用できます。

新しいイシューが作成され、ユーザーが作成者になります。このアドレスをメールクライアントの連絡先として保存すると、再度使用できます。

{{< alert type="warning" >}}

表示されるメールアドレスは、ユーザー専用に生成されたプライベートメールアドレスです。このメールアドレスを知っている人は、誰でもそのユーザーとしてイシューまたはマージリクエストを作成できるため、**Keep it to yourself**（秘密にしておいてください）。

{{< /alert >}}

メールアドレスを再生成するには:

1. **イシュー**ページで、**Email a new issue to this project**（新規イシューをこのプロジェクトにメールで送信）を選択します。
1. **reset this token**（このトークンをリセット）を選択します。

## 値を事前に入力したURLを使用する {#using-a-url-with-prefilled-values}

フィールドが事前に入力された新しいイシューページに直接リンクするには、URLでクエリ文字列パラメータを使用します。外部HTMLページにURLを埋め込んで、特定のフィールドが事前に入力されたイシューを作成できます。

事前に入力された値でイシューを作成するためのURLを構築するには、以下を組み合わせてください:

1. プロジェクトまたはグループのイシューページURLの後に続く`/new`。例: `https://gitlab.com/gitlab-org/gitlab/-/issues/new`。

1. パラメータのリストを開始する`?`。
1. URLパラメータの後に続く`=`と値。例: `issue[title]=My%20test%20issue`。
1. （オプション）追加のパラメータを結合する`&`。

| フィールド                                                                                          | URLパラメータ          | ノート |
| ---------------------------------------------------------------------------------------------- | ---------------------- | ----- |
| タイトル                                                                                          | `issue[title]`         | [URLエンコード](../../../api/rest/_index.md#namespaced-paths)する必要があります。 |
| イシュータイプ                                                                                     | `issue[issue_type]`    | `incident`または`issue`のいずれか。 |
| 説明テンプレート（イシュー、エピック、インシデント、マージリクエスト）                                   | `issuable_template`    | [URLエンコード](../../../api/rest/_index.md#namespaced-paths)する必要があります。 |
| 説明テンプレート（タスク、OKR、[新しい外観](issue_work_items.md)のイシュー、エピック） | `description_template` | [URLエンコード](../../../api/rest/_index.md#namespaced-paths)する必要があります。GitLab 17.9で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/513095)。 |
| 説明                                                                                    | `issue[description]`   | [URLエンコード](../../../api/rest/_index.md#namespaced-paths)する必要があります。`issuable_template`または[デフォルトイシューテンプレート](../description_templates.md#set-a-default-template-for-merge-requests-and-issues)と組み合わせて使用​​すると、`issue[description]`の値がテンプレートに付け加えられます。 |
| 機密                                                                                   | `issue[confidential]`  | `true`の場合、イシューは機密としてマークされます。 |
| 関連付ける…                                                                                     | `add_related_issue`    | 数値イシューID。存在する場合、イシューフォームには、新しいイシューを指定された既存のイシューにオプションでリンクするための[**Relate to**（関連付ける）チェックボックス](#from-another-issue-or-incident)が表示されます。 |

[GitLab 17.8以降](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177215)では、イシューテンプレートを選択すると、URLが変更されて使用するテンプレートが表示されます。

これらの例を参考に、フィールドが事前に入力された新しいイシューURLを作成してください。GitLabプロジェクトでイシューを作成するには、次のように指定します:

- 事前に入力されたタイトルと説明:

  ```plaintext
  https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue[title]=Whoa%2C%20we%27re%20half-way%20there&issue[description]=Whoa%2C%20livin%27%20in%20a%20URL
  ```

- 事前に入力されたタイトルと説明テンプレート:

  ```plaintext
  https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue[title]=Validate%20new%20concept&issuable_template=Feature%20Proposal%20-%20basic
  ```

- 事前に入力されたタイトル、説明、および機密としてマーク:

  ```plaintext
  https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue[title]=Validate%20new%20concept&issue[description]=Research%20idea&issue[confidential]=true
  ```

## サービスデスクを使用する {#using-service-desk}

メールサポートを提供するには、プロジェクトに対して[サービスデスク](../service_desk/_index.md)を有効にします。

顧客が新しいメールを送信すると、適切なプロジェクトに新しいイシューが作成され、そこからフォローアップできます。

## 新しいイシューフォームのフィールド {#fields-in-the-new-issue-form}

{{< history >}}

- イテレーションフィールドは、GitLab 15.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/233517)されました。

{{< /history >}}

新しいイシューを作成するときは、次のフィールドに入力できます:

- タイトル
- プロジェクト: デフォルトは現在のプロジェクト
- タイプ: イシュー（デフォルト）またはインシデント
- [説明テンプレート](../description_templates.md): 説明テキストボックス内のすべてを上書きします
- 説明: [Markdown](../../markdown.md)と[クイックアクション](../quick_actions.md)を使用できます
- イシューを[機密](confidential_issues.md)にするためのチェックボックス
- [担当者](managing_issues.md#assignees)
- [ウェイト](issue_weight.md)
- [エピック](../../group/epics/_index.md) （[イシューの新しい外観](issue_work_items.md)が有効になっている場合は親という名前が付けられています）
- [期限](due_dates.md) （[イシューの新しい外観](issue_work_items.md)が有効になっている場合は日付という名前が付けられています）
- [マイルストーン](../milestones/_index.md)
- [ラベル](../labels.md)
- [イテレーション](../../group/iterations/_index.md)
- [ヘルスステータス](managing_issues.md#health-status) （[イシューの新しい外観](issue_work_items.md)を有効にする必要があります）
- [連絡先](../../crm/_index.md) （[イシューの新しい外観](issue_work_items.md)を有効にする必要があります）
