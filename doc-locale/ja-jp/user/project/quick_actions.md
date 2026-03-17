---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabクイックアクション
description: コマンド、ショートカット、インラインアクション。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

クイックアクションは、GitLabの一般的なアクションに対するテキストベースのショートカットを提供します。クイックアクションは、以下を行います:

- ユーザーインターフェースを使用せずに、一般的なアクションを実行する。
- イシュー、マージリクエスト、エピック、コミットの操作をサポートする。
- 説明またはコメントを保存する時に、自動的に実行する。
- 特定のコンテキストと条件に対応する。
- 別々の行に入力された複数のコマンドを処理する。

たとえば、クイックアクションを使用すると次のことができます:

- ユーザーを割り当てる。
- ラベルを追加する。
- 期限を設定する。
- 状態を変更する。
- その他の属性を設定する。

各コマンドはスラッシュ（`/`）で始まり、別の行に入力する必要があります。多くのクイックアクションはパラメータを受け入れます。パラメータは、引用符（`"`）または特定の形式で入力できます。

## パラメータ {#parameters}

多くのクイックアクションでは、パラメータが必要です。たとえば、`/assign`クイックアクションには、ユーザー名が必要です。GitLabでは、クイックアクションと組み合わせて[オートコンプリート文字](autocomplete_characters.md)を使用し、利用可能な値の一覧を表示することで、ユーザーがパラメータを入力しやすくしています。

パラメータを手動で入力する場合は、次の文字のみが含まれている場合を除き、二重引用符（`"`）で囲む必要があります:

- ASCII文字
- 数字（0-9）
- アンダースコア（`_`）、ハイフン（`-`）、疑問符（`?`）、ドット（`.`）、アンパサンド（`&`）またはアットマーク（`@`）

パラメータは大文字と小文字が区別されます。オートコンプリートはこれを処理し、引用符の挿入を自動的に行います。

## クイックアクション {#quick-actions}

{{< history >}}

- GitLab 18.1で、エピックが作業アイテムとして[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/468310)されました。
- `/cc`クイックアクションはGitLab 18.3で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/369571)されました。

{{< /history >}}

次のクイックアクションは、説明、ディスカッション、スレッドに適用できます。一部のクイックアクションは、すべてのサブスクリプションプランで利用できるとは限りません。

### `add_child` {#add_child}

1つまたは複数のアイテムを子アイテムとして追加します。

**可用性**:

- エピック（イシュー、タスク、目標、または主な成果を追加）
- イシュー（タスク、目標、または主な成果を追加）
- 目標（目標または主な成果を追加）

**パラメータ**:

- `<item>`: 子として追加するアイテム。値は、`#item`、`group/project#item`、またはアイテムのURLの形式である必要があります。複数の作業アイテムを子アイテムとして同時に追加できます。

**例**:

- 単一の子アイテムを追加します:

  ```plaintext
  /add_child #123
  ```

- 複数の子アイテムを追加します:

  ```plaintext
  /add_child #123 #456 group/project#789
  ```

- URLを使用して子アイテムを追加します:

  ```plaintext
  /add_child https://gitlab.com/group/project/-/work_items/123
  ```

### `add_contacts` {#add_contacts}

1つまたは複数のアクティブなCRMの連絡先を追加します。

**可用性**:

- イシュー

**パラメータ**:

- `[contact:email1@example.com]`: `contact:email@example.com`形式の1つまたは複数の連絡先メール。

**例**:

- 単一の連絡先を追加します:

  ```plaintext
  /add_contacts [contact:alex@example.com]
  ```

- 複数の連絡先を追加します:

  ```plaintext
  /add_contacts [contact:alex@example.com] [contact:sam@example.com]
  ```

**補足情報**:

- 詳細については、[CRMの連絡先](../crm/_index.md)を参照してください。

### `add_email` {#add_email}

最大6人のメール参加者を追加します。

{{< history >}}

- `issue_email_participants`という名前の[フラグ](../../administration/feature_flags/list.md)を使用して、GitLab 13.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/350460)されました。デフォルトでは有効になっています。

{{< /history >}}

> [!flag]この機能フラグは、機能フラグによって制御されます。詳細については、履歴を参照してください。

**可用性**:

- インシデント
- イシュー

**パラメータ**:

- `email1 email2`: スペースで区切られた1つまたは複数のメールアドレス。

**例**:

- 単一のメール参加者を追加します:

  ```plaintext
  /add_email alex@example.com
  ```

- 複数のメール参加者を追加します:

  ```plaintext
  /add_email alex@example.com sam@example.com
  ```

**補足情報**:

- [イシューテンプレート](description_templates.md)ではサポートされていません。
- 詳細については、[メール参加者](service_desk/external_participants.md)を参照してください。

### `approve` {#approve}

マージリクエストを承認します。

**可用性**:

- マージリクエスト

**例**:

- マージリクエストを承認します:

  ```plaintext
  /approve
  ```

**補足情報**:

- マージリクエストの承認を取り消すには、[`/unapprove`](#unapprove)を使用します。

### `assign` {#assign}

{{< history >}}

- GitLab 18.2でエピック向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/551805)されました。

{{< /history >}}

1人以上のユーザーを作業アイテムに割り当てます。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**パラメータ**:

- `@user1 @user2`: 割り当てる1人または複数のユーザー名。ユーザー名には`@`というプレフィックスを付ける必要があります。
- `me`: 作業アイテムに自分自身を割り当てます。

**例**:

- 単一のユーザーを割り当て:

  ```plaintext
  /assign @alex
  ```

- 複数のユーザーを割り当て:

  ```plaintext
  /assign @alex @sam
  ```

- 自分自身を割り当てます:

  ```plaintext
  /assign me
  ```

**補足情報**:

- スペースでユーザー名を区切ると、1つのコマンドで複数のユーザーを割り当てることができます。
- 担当者を削除するには、[`/unassign`](#unassign)を使用します。
- 担当者を置き換えるには、[`/reassign`](#reassign)を使用します。

### `assign_reviewer` {#assign_reviewer}

一人または複数のユーザーをレビュアーとして割り当てるか、既存のレビュアーに新しいレビューをリクエストします。

**[`/request_review`](#request_review)のエイリアス。**

**可用性**:

- マージリクエスト

**パラメータ**:

- `@user1 @user2`: レビュアーとして割り当てる1人または複数のユーザー名。ユーザー名には`@`というプレフィックスを付ける必要があります。
- `me`: 自分自身をレビュアーとして割り当てます。

**例**:

- 単一のレビュアーを割り当てます:

  ```plaintext
  /assign_reviewer @alex
  ```

- 複数のレビュアーを割り当てます:

  ```plaintext
  /assign_reviewer @alex @sam
  ```

- 自分自身をレビュアーとして割り当てます:

  ```plaintext
  /assign_reviewer me
  ```

**補足情報**:

- ユーザーがまだレビュアーでない場合は、レビュアーとして割り当てます。
- ユーザーがすでにレビュアーである場合は、新しいレビューをリクエストします（そのレビューの状態をリセットし、通知を送信します）。
- スペースでユーザー名を区切ると、1つのコマンドで複数のユーザーを割り当てることができます。
- `/reviewer`はこのコマンドのエイリアスでもあります。
- レビュアーを置き換えるには、[`/reassign_reviewer`](#reassign_reviewer)を使用します。
- レビュアーを削除するには、[`/unassign_reviewer`](#unassign_reviewer)を使用します。
- 詳細については、[`/request_review`](#request_review)を参照してください。

### `award` {#award}

絵文字リアクションを切り替えます。

{{< history >}}

- タスク、目標、主要な成果向けに、GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412275)されました。

{{< /history >}}

**可用性**:

- タスク
- 目標
- 主な成果

**パラメータ**:

- `:emoji:`: 切り替える絵文字リアクション。`:emoji_name:`形式にする必要があります。

**例**:

- 賛成リアクションを切り替えます:

  ```plaintext
  /award :thumbsup:
  ```

- ハートリアクションを切り替えます:

  ```plaintext
  /award :heart:
  ```

**補足情報**:

- `/award`は`/react`のエイリアスです。
- 詳細については、[絵文字リアクション](../emoji_reactions.md)を参照してください。

### `blocked_by` {#blocked_by}

アイテムを他のアイテムによってブロックされているとしてマークします。

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/214232)されました。

{{< /history >}}

**可用性**:

- エピック
- インシデント
- イシュー

**パラメータ**:

- `<item1> <item2>`: このアイテムをブロックする1つまたは複数のアイテム。値は、`#item`、`group/project#item`、または完全なURLの形式にする必要があります。

**例**:

- 単一のアイテムでブロックされたものとしてマークします:

  ```plaintext
  /blocked_by #123
  ```

- 複数のアイテムでブロックされたものとしてマークします:

  ```plaintext
  /blocked_by #123 group/project#456
  ```

- URLを使用してアイテムでブロックされたものとしてマークします:

  ```plaintext
  /blocked_by https://gitlab.com/group/project/-/work_items/123
  ```

**補足情報**:

- ブロック関係を削除するには、[`/unlink`](#unlink)を使用します。
- アイテムを関連するものとしてマークするには、他のブロックを使用せずに、[`/relate`](#relate)を使用します。

### `blocks` {#blocks}

アイテムを他のアイテムをブロックしているとしてマークします。

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/214232)されました。

{{< /history >}}

**可用性**:

- エピック
- インシデント
- イシュー

**パラメータ**:

- `<item1> <item2>`: このアイテムがブロックする1つまたは複数のアイテム。値は、`#item`、`group/project#item`、または完全なURLの形式にする必要があります。

**例**:

- 単一のアイテムをブロックするものとしてマークします:

  ```plaintext
  /blocks #123
  ```

- 複数のアイテムをブロックするものとしてマークします:

  ```plaintext
  /blocks #123 group/project#456
  ```

- URLを使用してアイテムをブロックするものとしてマークします:

  ```plaintext
  /blocks https://gitlab.com/group/project/-/work_items/123
  ```

**補足情報**:

- ブロック関係を削除するには、[`/unlink`](#unlink)を使用します。
- アイテムを関連するものとしてマークするには、他のブロックを使用せずに、[`/relate`](#relate)を使用します。

### `board_move` {#board_move}

イシューをボードの列に移動します。

**可用性**:

- イシュー

**パラメータ**:

- `~column`: イシューを移動するボード列のラベル名。`~`というプレフィックスを付ける必要があります。

**例**:

- 列に移動します:

  ```plaintext
  /board_move ~"In Progress"
  ```

**補足情報**:

- プロジェクトには、イシューボードが1つだけ必要です。

### `checkin_reminder` {#checkin_reminder}

目標のチェックインリマインダーをスケジュールします。

{{< history >}}

- GitLab 16.4で`okrs_mvc`および`okr_checkin_reminders`フラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422761) されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]この機能フラグは、機能フラグによって制御されます。詳細については、履歴を参照してください。

**可用性**:

- 目標

**パラメータ**:

- `<cadence>`: リマインダーのケイデンス。オプションは次のとおりです:
  - `weekly`
  - `twice-monthly`
  - `monthly`
  - `never`（デフォルト）

**例**:

- 毎週のリマインダーを設定します:

  ```plaintext
  /checkin_reminder weekly
  ```

- リマインダーを無効化します:

  ```plaintext
  /checkin_reminder never
  ```

**補足情報**:

- 詳細については、[OKRチェックインリマインダーのスケジュール](../okrs.md#schedule-okr-check-in-reminders)を参照してください。

### `clear_health_status` {#clear_health_status}

ヘルスステータスをクリアします。

**可用性**:

- エピック
- イシュー
- タスク
- 目標
- 主な成果

**例**:

- ヘルスステータスをクリアします:

  ```plaintext
  /clear_health_status
  ```

**補足情報**:

- 詳細については、[ヘルスステータス](issues/managing_issues.md#health-status)を参照してください。

### `clear_weight` {#clear_weight}

ウェイトをクリアします。

**可用性**:

- イシュー
- タスク

**例**:

- ウェイトをクリアします:

  ```plaintext
  /clear_weight
  ```

### `clone` {#clone}

指定されたグループまたはプロジェクトに作業アイテムをクローンします。

**可用性**:

- エピック
- インシデント
- イシュー

**パラメータ**:

- `<path/to/group_or_project>`: ターゲットグループまたはプロジェクトへのパス。指定されていない場合、現在のプロジェクトにクローンされます。
- `--with_notes`: クローンにコメントとシステムノートを含めるオプションのフラグ。

**例**:

- 別のプロジェクトにクローンします:

  ```plaintext
  /clone group/project
  ```

- 現在のプロジェクトにクローンします:

  ```plaintext
  /clone
  ```

- 注記を付けてクローン:

  ```plaintext
  /clone group/project --with_notes
  ```

**補足情報**:

- ターゲットにラベル、マイルストーン、エピックなどの同等のオブジェクトが含まれている限り、可能な限り多くのデータをコピーします。
- `--with_notes`が引数として指定されていない限り、コメントまたはシステムノートはコピーしません。

### `close` {#close}

作業アイテムを閉じます。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**例**:

- 作業アイテムを閉じます:

  ```plaintext
  /close
  ```

**補足情報**:

- 作業アイテムを再度開くには、[`/reopen`](#reopen)を使用します。

### `confidential` {#confidential}

作業アイテムを機密としてマークします。

{{< history >}}

- GitLab 16.4で、タスク、目標、主な成果向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412276)されました。

{{< /history >}}

**可用性**:

- エピック
- インシデント
- イシュー
- タスク
- 目標
- 主な成果

**例**:

- 機密としてマークします:

  ```plaintext
  /confidential
  ```

**補足情報**:

- 詳細については、[機密イシューを表示できるユーザー](issues/confidential_issues.md#who-can-see-confidential-issues) 、[OKR](../okrs.md#who-can-see-confidential-okrs) 、または[タスク](../tasks.md#who-can-see-confidential-tasks)を参照してください。
- アイテムを機密でないようにするには、右上隅で、**その他のアクション**（{{< icon name="ellipsis_v" >}}）を選択し、**公開に設定する**を選択します。

### `convert_to_ticket` {#convert_to_ticket}

イシューをサービスデスクチケットに変換します。

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)されました。

{{< /history >}}

**可用性**:

- インシデント
- イシュー

**パラメータ**:

- `<email address>`: チケットに関連付けるメールアドレス。

**例**:

- チケットに変換します:

  ```plaintext
  /convert_to_ticket user@example.com
  ```

**補足情報**:

- 詳細については、[サービスデスクチケットへの通常のイシューの変換](service_desk/using_service_desk.md#convert-a-regular-issue-to-a-service-desk-ticket)を参照してください。

### `copy_metadata` {#copy_metadata}

別のアイテムからラベルとマイルストーンをコピーします。

{{< history >}}

- GitLab 17.9で、タスク、目標、主な成果向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/509076)されました。

{{< /history >}}

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**パラメータ**:

- `<#item>`: メタデータのコピー元のアイテム。マージリクエストの場合は、`!MR_IID`形式を使用します。その他のアイテムの場合は、`#item`またはURLを使用します。

**例**:

- イシューからメタデータをコピーします:

  ```plaintext
  /copy_metadata #123
  ```

- マージリクエストからメタデータをコピーします:

  ```plaintext
  /copy_metadata !456
  ```

- URLを使用して作業アイテムからメタデータをコピーします:

  ```plaintext
  /copy_metadata https://gitlab.com/group/project/-/work_items/123
  ```

**補足情報**:

- メタデータのコピー元のアイテムは、同じネームスペース内にある必要があります。

### `create_merge_request` {#create_merge_request}

現在のイシューから開始して、新しいマージリクエストを作成します。

**可用性**:

- インシデント
- イシュー
- タスク

**パラメータ**:

- `<branch name>`: マージリクエスト用に作成するブランチの名前。

**例**:

- マージリクエストを作成します:

  ```plaintext
  /create_merge_request fix-bug-123
  ```

### `done` {#done}

To Doアイテムを完了としてマークします。

{{< history >}}

- GitLab 16.2で、タスク、目標、主な成果向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412277)されました。

{{< /history >}}

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**例**:

- To Doを完了としてマークします:

  ```plaintext
  /done
  ```

### `draft` {#draft}

マージリクエストのドラフトステータスを設定します。

**可用性**:

- マージリクエスト

**例**:

- 下書きとしてマークします:

  ```plaintext
  /draft
  ```

**補足情報**:

- 詳細については、[下書きの状態](merge_requests/drafts.md)を参照してください。

### `due` {#due}

期限を設定します。

**可用性**:

- エピック
- インシデント
- イシュー
- タスク
- 主な成果

**パラメータ**:

- `<date>`: 期限。有効な日付の例としては、`in 2 days`、`this Friday`、`December 31st`などがあります。

**例**:

- 特定の日付に期限を設定します:

  ```plaintext
  /due December 31st
  ```

- 今日を基準に期限を相対的に設定します:

  ```plaintext
  /due in 2 days
  ```

- 次の金曜日に期限を設定します:

  ```plaintext
  /due this Friday
  ```

**補足情報**:

- その他の日付形式の例については、[Chronicの例](https://gitlab.com/gitlab-org/ruby/gems/gitlab-chronic#examples)を参照してください。
- 期限を削除するには、[`/remove_due_date`](#remove_due_date)を使用します。

### `duplicate` {#duplicate}

このアイテムを閉じて、別のアイテムに関連するものとしてマークします。

**可用性**:

- エピック
- インシデント
- イシュー

**パラメータ**:

- `<item>`: これが重複しているアイテム。値は、`#item`、`group/project#item`、またはURLの形式にする必要があります。

**例**:

- 重複としてマークします:

  ```plaintext
  /duplicate #123
  ```

- URLを使用して重複としてマークします:

  ```plaintext
  /duplicate https://gitlab.com/group/project/-/work_items/123
  ```

### `epic` {#epic}

子アイテムとしてエピックに追加します。

**可用性**:

- エピック
- イシュー

**パラメータ**:

- `<epic>`: このアイテムを追加するエピック。値は、`&epic`、`#epic`、`group&epic`、`group#epic`、またはエピックへのURLの形式にする必要があります。

**例**:

- 参照によりエピックに追加します:

  ```plaintext
  /epic &123
  ```

- グループと参照によりエピックに追加します:

  ```plaintext
  /epic group&456
  ```

- URLを使用してエピックに追加します:

  ```plaintext
  /epic https://gitlab.com/groups/group/-/epics/123
  ```

**補足情報**:

- `/set_parent`の動作は同じですが、より多くの作業アイテムタイプで使用できます。

### `estimate` {#estimate}

時間見積もりを設定します。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト

**パラメータ**:

- `<time>`: 時間見積もり。例: `1mo 2w 3d 4h 5m`。

**例**:

- 時間見積もりを設定します:

  ```plaintext
  /estimate 1mo 2w 3d 4h 5m
  ```

- 時間見積もりを時間単位で設定します:

  ```plaintext
  /estimate 8h
  ```

**補足情報**:

- `/estimate_time`は`/estimate`のエイリアスです。
- 見積もりを削除するには、[`/remove_estimate`](#remove_estimate)を使用します。
- 詳細については、[タイムトラッキング](time_tracking.md)を参照してください。

### `health_status` {#health_status}

ヘルスステータスを設定します。

**可用性**:

- エピック
- イシュー
- タスク
- 目標
- 主な成果

**パラメータ**:

- `<value>`: ヘルスステータス値。有効なオプションは、`on_track`、`needs_attention`、および`at_risk`です。

**例**:

- ヘルスステータスを順調に設定します:

  ```plaintext
  /health_status on_track
  ```

- ヘルスステータスを要対応に設定します:

  ```plaintext
  /health_status needs_attention
  ```

- ヘルスステータスを危険に設定します:

  ```plaintext
  /health_status at_risk
  ```

**補足情報**:

- 詳細については、[ヘルスステータス](issues/managing_issues.md#health-status)を参照してください。

### `iteration` {#iteration}

イテレーションを設定します。

{{< history >}}

- GitLab 16.9で、`--current`オプションと`--next`オプション向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/384885)されました。

{{< /history >}}

**可用性**:

- インシデント
- イシュー

**パラメータ**:

- `*iteration:<iteration ID> or <iteration name>`: IDまたは名前で特定のイテレーションに設定します。
- `[cadence:<iteration cadence ID> or <iteration cadence name>] <--current or --next>`: 特定のケイデンスの現在または次のイテレーションに設定します。
- `--current`または`--next`: グループに1つのイテレーションケイデンスがある場合、現在または次のイテレーションに設定します。

**例**:

- 名前で特定のイテレーションに設定します:

  ```plaintext
  /iteration *iteration:"Late in July"
  ```

- ケイデンスの現在のイテレーションに設定します:

  ```plaintext
  /iteration [cadence:"Team cadence"] --current
  ```

- グループに1つのケイデンスがある場合、次のイテレーションに設定します:

  ```plaintext
  /iteration --next
  ```

**補足情報**:

- イテレーションを削除するには、[`/remove_iteration`](#remove_iteration)を使用します。

### `label` {#label}

1つまたは複数のラベルを追加します。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**パラメータ**:

- `~label1 ~label2`: 1つまたは複数のラベル名。ラベル名はチルダ（`~`）なしで開始することもできますが、混合構文はサポートされていません。

**例**:

- 単一のラベルを追加します:

  ```plaintext
  /label ~bug
  ```

- 複数のラベルを追加します:

  ```plaintext
  /label ~bug ~"high priority"
  ```

- チルダなしでラベルを追加します:

  ```plaintext
  /label bug "high priority"
  ```

**補足情報**:

- 名前にスペースが含まれるラベルは、二重引用符で囲む必要があります。
- `/labels`は`/label`のエイリアスです。
- ラベルを削除するには、[`/unlabel`](#unlabel)を使用します。
- ラベルを置き換えるには、[`/relabel`](#relabel)を使用します。

### `link` {#link}

インシデント内のリンクされたリソースにリンクと説明を追加します。

**可用性**:

- インシデント

**例**:

- リンクされたリソースを追加します:

  ```plaintext
  /link
  ```

**補足情報**:

- 詳細については、[リンクされたリソース](../../operations/incident_management/linked_resources.md)を参照してください。

### `lock` {#lock}

ディスカッションをロックします。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト

**例**:

- ディスカッションをロックします:

  ```plaintext
  /lock
  ```

**補足情報**:

- ディスカッションの切替を解除するには、[`/unlock`](#unlock)を使用します。

### `merge` {#merge}

変更をマージする。

**可用性**:

- マージリクエスト

**例**:

- マージリクエストをマージします:

  ```plaintext
  /merge
  ```

**補足情報**:

- プロジェクトの設定によっては、[パイプラインが成功したとき](merge_requests/auto_merge.md)、または[マージトレイン](../../ci/pipelines/merge_trains.md)に追加される場合があります。

### `milestone` {#milestone}

{{< history >}}

- GitLab 18.2でエピック向けに[導入](https://gitlab.com/groups/gitlab-org/-/epics/329)されました。

{{< /history >}}

マイルストーンを設定します。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト

**パラメータ**:

- `%milestone`: マイルストーン名。`%`というプレフィックスを付ける必要があります。

**例**:

- マイルストーンを設定します:

  ```plaintext
  /milestone %"Sprint 1"
  ```

**補足情報**:

- マイルストーンを削除するには、[`/remove_milestone`](#remove_milestone)を使用します。

### `move` {#move}

作業アイテムを別のグループまたはプロジェクトに移動します。

**可用性**:

- エピック
- インシデント
- イシュー

**パラメータ**:

- `<path/to/group_or_project>`: ターゲットグループまたはプロジェクトへのパス。

**例**:

- 別のプロジェクトに移動します:

  ```plaintext
  /move group/project
  ```

**補足情報**:

- 異なるアクセスルールがある場所へ作業アイテムを移動する際は注意してください。作業アイテムを移動する前に、機密データが含まれていないことを確認してください。

### `page` {#page}

インシデントのエスカレーションを開始します。

**可用性**:

- インシデント

**パラメータ**:

- `<policy name>`: エスカレーションポリシー名。

**例**:

- エスカレーションポリシーを開始します:

  ```plaintext
  /page "On-call policy"
  ```

### `promote_to` {#promote_to}

作業アイテムを特定のタイプにプロモートします。

{{< history >}}

- GitLab 16.1で、タスクと主な成果向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412534)されました。

{{< /history >}}

**可用性**:

- イシュー
- タスク
- 主な成果

**パラメータ**:

- `<type>`: プロモート先のタイプ。利用可能なオプションは以下のとおりです:
  - `Epic`（イシューの場合）
  - `Incident`（イシューの場合）
  - `issue`（タスクの場合）
  - `objective`（主な成果の場合）

**例**:

- イシューをエピックにプロモートします:

  ```plaintext
  /promote_to Epic
  ```

- タスクをイシューにプロモートします:

  ```plaintext
  /promote_to issue
  ```

- 主な成果を目標にプロモートします:

  ```plaintext
  /promote_to objective
  ```

**補足情報**:

- イシューの場合、`/promote_to_incident`は`/promote_to Incident`のショートカットです。
- 作業アイテムのタイプを変更するには、[`/type`](#type)も使用します。

### `promote_to_incident` {#promote_to_incident}

イシューをインシデントにプロモートします。

**可用性**:

- イシュー

**例**:

- インシデントにプロモートします:

  ```plaintext
  /promote_to_incident
  ```

**補足情報**:

- このクイックアクションは、新しいイシューの作成時にも使用できます。

### `publish` {#publish}

イシューを関連付けられたステータスページに公開します。

**可用性**:

- イシュー

**例**:

- ステータスページに公開します:

  ```plaintext
  /publish
  ```

**補足情報**:

- 詳細については、[ステータスページ](../../operations/incident_management/status_page.md)を参照してください。

### `react` {#react}

絵文字リアクションを切り替えます。

{{< history >}}

- GitLab 16.7で[名前が変更](https://gitlab.com/gitlab-org/gitlab/-/issues/409884)されました。`/award`。`/award`は、エイリアス化されたコマンドとして引き続き使用できます。

{{< /history >}}

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト

**パラメータ**:

- `:emoji:`: 切り替える絵文字リアクション。`:emoji_name:`形式にする必要があります。

**例**:

- 賛成リアクションを切り替えます:

  ```plaintext
  /react :thumbsup:
  ```

- ハートリアクションを切り替えます:

  ```plaintext
  /react :heart:
  ```

**補足情報**:

- `/award`は`/react`のエイリアスです。

### `ready` {#ready}

マージリクエストの準備完了ステータスを設定します。

**可用性**:

- マージリクエスト

**例**:

- 準備完了としてマークします:

  ```plaintext
  /ready
  ```

**補足情報**:

- 詳しくは、[マージリクエストを準備完了としてマークする](merge_requests/drafts.md#mark-merge-requests-as-ready)を参照してください。

### `reassign` {#reassign}

{{< history >}}

- GitLab 18.2でエピック向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/551805)されました。

{{< /history >}}

現在の担当者を、指定された担当者と置き換えます。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**パラメータ**:

- `@user1 @user2`: 割り当てる1人または複数のユーザー名。ユーザー名には`@`というプレフィックスを付ける必要があります。

**例**:

- 単一ユーザー名に再割り当てします:

  ```plaintext
  /reassign @alex
  ```

- 複数ユーザー名に再割り当てします:

  ```plaintext
  /reassign @alex @sam
  ```

**補足情報**:

- 以前の割り当て担当者を置き換えずに割り当て担当者を追加するには、[`/assign`](#assign)を使用します。
- 担当者を削除するには、[`/unassign`](#unassign)を使用します。
- 担当者を置き換えるには、[`/reassign`](#reassign)を使用します。

### `reassign_reviewer` {#reassign_reviewer}

現在のレビュアーを、指定されたレビュー担当者と置き換えます。

**可用性**:

- マージリクエスト

**パラメータ**:

- `@user1 @user2`: レビュアーとして割り当てる1人または複数のユーザー名。ユーザー名には`@`というプレフィックスを付ける必要があります。

**例**:

- 単一のレビュアーに再割り当てします:

  ```plaintext
  /reassign_reviewer @alex
  ```

- 複数のレビュアーに再割り当てします:

  ```plaintext
  /reassign_reviewer @alex @sam
  ```

**補足情報**:

- 以前のレビュアーを置き換えずにレビュアーを割り当てるには、[`/assign_reviewer`](#assign_reviewer)を使用します。
- レビュアーを削除するには、[`/unassign_reviewer`](#unassign_reviewer)を使用します。

### `rebase` {#rebase}

ソースブランチをターゲットブランチの最新のコミットにリベースします。競合がある場合、何も起こりません。

**可用性**:

- マージリクエスト

**例**:

- マージリクエストをリベースします:

  ```plaintext
  /rebase
  ```

**補足情報**:

- ヘルプについては、[Gitのトラブルシューティング](../../topics/git/troubleshooting_git.md)を参照してください。

### `relabel` {#relabel}

現在のラベルを、指定されたラベルと置き換えます。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**パラメータ**:

- `~label1 ~label2`: 1つまたは複数のラベル名。ラベル名はチルダ（`~`）なしで開始することもできますが、混合構文はサポートされていません。

**例**:

- 単一のラベルと置換します:

  ```plaintext
  /relabel ~bug
  ```

- 複数のラベルと置換します:

  ```plaintext
  /relabel ~bug ~"high priority"
  ```

**補足情報**:

- 名前にスペースが含まれるラベルは、二重引用符で囲む必要があります。
- 以前のラベルを置き換えずにラベルを追加するには、[`/label`](#label)を使用します。
- ラベルを削除するには、[`/unlabel`](#unlabel)を使用します。

### `relate` {#relate}

アイテムを関連としてマークします。

**可用性**:

- エピック
- インシデント
- イシュー

**パラメータ**:

- `<item1> <item2>`: 関連付ける1つまたは複数のアイテム。値は、`#item`、`group/project#item`、または完全なURLの形式にする必要があります。

**例**:

- 単一アイテムに関連付けます:

  ```plaintext
  /relate #123
  ```

- 複数アイテムに関連付けます:

  ```plaintext
  /relate #123 group/project#456
  ```

**補足情報**:

- 関係を削除するには、[`/unlink`](#unlink)を使用します。
- アイテムを相互にブロックするようにマークするには、[`/blocked_by`](#blocked_by)または[`/blocks`](#blocks)を使用します。

### `remove_child` {#remove_child}

子アイテムとしてアイテムを削除します。

{{< history >}}

- GitLab 16.10で、目標向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/132761)されました。

{{< /history >}}

**可用性**:

- エピック
- イシュー
- 目標

**パラメータ**:

- `<item>`: 子として削除するアイテム。値は、`#item`、`group/project#item`、またはアイテムのURLの形式である必要があります。

**例**:

- 子アイテムを削除します:

  ```plaintext
  /remove_child #123
  ```

- URLを使用して子アイテムを削除します:

  ```plaintext
  /remove_child https://gitlab.com/group/project/-/work_items/123
  ```

### `remove_contacts` {#remove_contacts}

1つまたは複数のCRMの連絡先を削除します。

**可用性**:

- イシュー

**パラメータ**:

- `[contact:email1@example.com]`: `contact:email@example.com`形式の1つまたは複数の連絡先メール。

**例**:

- 単一の連絡先を削除します:

  ```plaintext
  /remove_contacts [contact:alex@example.com]
  ```

- 複数の連絡先を削除します:

  ```plaintext
  /remove_contacts [contact:alex@example.com] [contact:sam@example.com]
  ```

**補足情報**:

- 詳細については、[CRMの連絡先](../crm/_index.md)を参照してください。

### `remove_due_date` {#remove_due_date}

期限を削除します。

**可用性**:

- エピック
- インシデント
- イシュー
- タスク
- 主な成果

**例**:

- 期限を削除します:

  ```plaintext
  /remove_due_date
  ```

**補足情報**:

- 期限を追加または置き換えるには、[`/due`](#due)を使用します。

### `remove_email` {#remove_email}

最大6人のメール参加者を削除します。

{{< history >}}

- `issue_email_participants`という名前の[フラグ](../../administration/feature_flags/list.md)を使用して、GitLab 13.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/350460)されました。デフォルトでは有効になっています。

{{< /history >}}

> [!flag]この機能フラグは、機能フラグによって制御されます。詳細については、履歴を参照してください。

**可用性**:

- インシデント
- イシュー

**パラメータ**:

- `email1 email2`: スペースで区切られた1つまたは複数のメールアドレス。

**例**:

- 単一のメール参加者を削除します:

  ```plaintext
  /remove_email alex@example.com
  ```

- 複数のメール参加者を削除します:

  ```plaintext
  /remove_email alex@example.com sam@example.com
  ```

**補足情報**:

- イシューテンプレート、マージリクエスト、またはエピックではサポートされていません。
- 詳細については、[メール参加者](service_desk/external_participants.md)を参照してください。

### `remove_estimate` {#remove_estimate}

時間見積もりを削除します。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト

**例**:

- 時間見積もりを削除します:

  ```plaintext
  /remove_estimate
  ```

**補足情報**:

- `/remove_time_estimate`は`/remove_estimate`のエイリアスです。
- 見積もりを追加または置き換えるには、[`/estimate`](#estimate)を使用します。

### `remove_iteration` {#remove_iteration}

イテレーションを削除します。

**可用性**:

- インシデント
- イシュー

**例**:

- イテレーションを削除します:

  ```plaintext
  /remove_iteration
  ```

**補足情報**:

- イテレーションを設定するには、[`/iteration`](#iteration)を使用します。

### `remove_milestone` {#remove_milestone}

{{< history >}}

- GitLab 18.2でエピック向けに[導入](https://gitlab.com/groups/gitlab-org/-/epics/329)されました。

{{< /history >}}

マイルストーンを削除します。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト

**例**:

- マイルストーンを削除します:

  ```plaintext
  /remove_milestone
  ```

**補足情報**:

- マイルストーンを設定するには、[`/milestone`](#milestone)を使用します。

### `remove_parent` {#remove_parent}

アイテムから親を削除します。

{{< history >}}

- GitLab 16.9で、タスクと主な成果向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/434344)されました。

{{< /history >}}

**可用性**:

- エピック
- イシュー
- タスク
- 主な成果

**例**:

- 親を削除します:

  ```plaintext
  /remove_parent
  ```

**補足情報**:

- 親アイテムを設定するには、[`/set_parent`](#set_parent)を使用します。

### `remove_time_spent` {#remove_time_spent}

費やした時間を削除します。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト

**例**:

- 費やした時間を削除します:

  ```plaintext
  /remove_time_spent
  ```

**補足情報**:

- 消費時間を追加するには、[`/spend`](#spend)を使用します。

### `remove_zoom` {#remove_zoom}

イシューからZoomミーティングを削除します。

**可用性**:

- イシュー

**例**:

- Zoomミーティングを削除します:

  ```plaintext
  /remove_zoom
  ```

**補足情報**:

- Zoomミーティングを追加するには、[`/zoom`](#zoom)を使用します。

### `reopen` {#reopen}

作業アイテムを再度開きます。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**例**:

- 作業アイテムを再度開きます:

  ```plaintext
  /reopen
  ```

**補足情報**:

- 作業アイテムを閉じるには、[`/close`](#close)を使用します。

### `request_review` {#request_review}

レビュアーを割り当てるか、1人または複数のユーザー名に新しいレビューをリクエストします。

**可用性**:

- マージリクエスト

**パラメータ**:

- `@user1 @user2`: レビューをリクエストする1つまたは複数のユーザー名。ユーザー名には`@`というプレフィックスを付ける必要があります。
- `me`: 自分自身からレビューをリクエストします。

**例**:

- 単一ユーザー名からのレビューをリクエストします:

  ```plaintext
  /request_review @alex
  ```

- 複数ユーザー名からのレビューをリクエストします:

  ```plaintext
  /request_review @alex @sam
  ```

- 自分自身からレビューをリクエストします:

  ```plaintext
  /request_review me
  ```

**補足情報**:

- [`/assign_reviewer`](#assign_reviewer)または`/reviewer`を使用して実行することもできます。
- ユーザーがまだレビュアーでない場合は、レビュアーとして割り当てます。
- ユーザーがすでにレビュアーである場合は、新しいレビューをリクエストします（そのレビューの状態をリセットし、通知を送信します）。
- 詳細については、[レビューをリクエスト](merge_requests/reviews/_index.md#request-a-review)を参照してください。

### `run_pipeline` {#run_pipeline}

マージリクエストの新しいパイプラインを実行します。

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212811)されました。

{{< /history >}}

**可用性**:

- マージリクエスト

**例**:

- 新しいパイプラインを実行します:

  ```plaintext
    /run_pipeline
  ```

**補足情報**:

- パイプラインは非同期でトリガーされ、コマンドの実行後すぐに表示されます。
- マージリクエストのパイプラインを作成する権限が必要です。
- これを他のクイックアクションと組み合わせることができます。たとえば、パイプラインを実行して自動マージを設定するには、以下のようにします:

  ```plaintext
    /run_pipeline
    /merge
  ```

### `set_parent` {#set_parent}

親アイテムを設定します。

{{< history >}}

- GitLab 16.5で、タスクと主な成果向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/420798)されました。
- イシューのエイリアス`/epic`（GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/514942)）。

{{< /history >}}

**可用性**:

- エピック
- イシュー
- タスク
- 主な成果

**パラメータ**:

- `<item>`: 親アイテム。値は、`#IID`、参照、またはアイテムへのURLの形式にする必要があります。

**例**:

- 参照で親を設定します:

  ```plaintext
  /set_parent #123
  ```

- URLを使用して親を設定します:

  ```plaintext
  /set_parent https://gitlab.com/group/project/-/work_items/123
  ```

**補足情報**:

- イシューの場合、`/epic`は`/set_parent`のエイリアスです。
- 親アイテムを削除するには、[`/remove_parent`](#remove_parent)を使用します。

### `severity` {#severity}

インシデントの重大度を設定します。

**可用性**:

- インシデント

**パラメータ**:

- `<severity>`: 重大度レベル。利用可能なオプションは以下のとおりです:
  - `S1`
  - `S2`
  - `S3`
  - `S4`
  - `critical`
  - `high`
  - `medium`
  - `low`
  - `unknown`

**例**:

- 重大度をクリティカルに設定します:

  ```plaintext
  /severity critical
  ```

- S表記を使用して重大度を設定します:

  ```plaintext
  /severity S1
  ```

### `shrug` {#shrug}

コメントに`¯\_(ツ)_/¯`を追加します。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**例**:

- 肩をすくめるジェスチャーを追加します:

  ```plaintext
  /shrug
  ```

### `spend` {#spend}

費やした時間を追加または減算します。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト

**パラメータ**:

- `<time>`: 追加または削除する時間。例: `1mo 2w 3d 4h 5m`。時間を差し引くには、負の値を使用します。
- `[<date>]`: オプション。時間が費やされた日付。

**例**:

- 費やした時間を追加します:

  ```plaintext
  /spend 1mo 2w 3d 4h 5m
  ```

- 費やした時間を差し引きます:

  ```plaintext
  /spend -1h 30m
  ```

- 特定の日付に費やした時間を追加します:

  ```plaintext
  /spend 1mo 2w 3d 4h 5m 2018-08-26
  ```

**補足情報**:

- `/spend_time`は`/spend`のエイリアスです。
- 費やした時間を削除するには、[`/remove_time_spent`](#remove_time_spent)を使用します。
- 詳細については、[タイムトラッキング](time_tracking.md)を参照してください。

### `status` {#status}

ステータスを設定します。

**可用性**:

- イシュー
- タスク

**パラメータ**:

- `<value>`: ステータス値。利用可能なオプションには、ネームスペースに設定されたステータスオプションが含まれます。

**例**:

- ステータスを設定します:

  ```plaintext
  /status "In Progress"
  ```

**補足情報**:

- 詳細については、[ステータス](../work_items/status.md)を参照してください。

### `submit_review` {#submit_review}

保留中の[レビュー](merge_requests/reviews/_index.md#submit-a-review)を送信します。

**可用性**:

- マージリクエスト

**例**:

- レビューを送信します:

  ```plaintext
  /submit_review
  ```

  ```plaintext
  /submit_review reviewed
  ```

- レビューを送信して承認します:

  ```plaintext
  /submit_review approve
  ```

- レビューを送信し、[変更をリクエスト](merge_requests/reviews/_index.md#prevent-merge-when-you-request-changes)します:

  ```plaintext
  /submit_review requested_changes
  ```

### `subscribe` {#subscribe}

作業アイテムの通知をサブスクライブします。

{{< history >}}

- GitLab 16.4で、タスク、目標、主な成果向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/420796)されました。

{{< /history >}}

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**例**:

- 通知をサブスクライブします:

  ```plaintext
  /subscribe
  ```

**補足情報**:

- 通知のサブスクライブを停止するには、[`/unsubscribe`](#unsubscribe)を使用します。

### `tableflip` {#tableflip}

コメントに`(╯°□°)╯︵ ┻━┻`を追加します。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**例**:

- テーブルフリップを追加します:

  ```plaintext
  /tableflip
  ```

### `target_branch` {#target_branch}

マージリクエストのターゲットブランチを設定します。

**可用性**:

- マージリクエスト

**パラメータ**:

- `<local branch name>`: ターゲットブランチの名前。

**例**:

- ターゲットブランチを設定します:

  ```plaintext
  /target_branch main
  ```

### `timeline` {#timeline}

インシデントにタイムラインイベントを追加します。

**可用性**:

- インシデント

**パラメータ**:

- `<timeline comment> | <date(YYYY-MM-DD)> <time(HH:MM)>`: タイムラインのコメント、日付、時刻。区切り文字は`|`。

**例**:

- タイムラインイベントを追加します:

  ```plaintext
  /timeline DB load spiked | 2022-09-07 09:30
  ```

### `title` {#title}

タイトルを変更します。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**パラメータ**:

- `<new title>`: 作業アイテムの新しいタイトル。

**例**:

- タイトルを変更します:

  ```plaintext
  /title New title for this item
  ```

### `todo` {#todo}

自分用のTo-Doアイテムを追加します。

{{< history >}}

- GitLab 16.2で、タスク、目標、主な成果向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412277)されました。

{{< /history >}}

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**例**:

- To-Doを追加します:

  ```plaintext
  /todo
  ```

### `type` {#type}

作業アイテムを特定のタイプに変換します。

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385227)されました。

{{< /history >}}

**可用性**:

- イシュー
- 主な成果
- 目標
- タスク

**パラメータ**:

- `<type>`: 変換先のタイプ。利用可能なオプションは以下のとおりです:
  - `issue`
  - `task`
  - `objective`
  - `key result`

**例**:

- イシューに変換します:

  ```plaintext
  /type issue
  ```

- タスクに変換します:

  ```plaintext
  /type task
  ```

**補足情報**:

- イシューをエピックまたはインシデントに変換するには、[`/promote_to`](#promote_to)を使用します。

### `unapprove` {#unapprove}

マージリクエストを否認します。

**可用性**:

- マージリクエスト

**例**:

- マージリクエストを却下します:

  ```plaintext
  /unapprove
  ```

**補足情報**:

- マージリクエストを承認するには、[`/approve`](#approve)を使用します。

### `unassign` {#unassign}

{{< history >}}

- GitLab 18.2でエピック向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/551805)されました。

{{< /history >}}

担当者を削除します。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**パラメータ**:

- `@user1 @user2`: オプション。割り当てを解除する1つまたは複数のユーザー名。指定しない場合は、すべての担当者が削除されます。

**例**:

- 特定の担当者を削除します:

  ```plaintext
  /unassign @alex @sam
  ```

- すべての担当者を削除します:

  ```plaintext
  /unassign
  ```

**補足情報**:

- 担当者を追加するには、[`/assign`](#assign)を使用します。
- 担当者を置き換えるには、[`/reassign`](#reassign)を使用します。

### `unassign_reviewer` {#unassign_reviewer}

レビュアーを削除します。

**可用性**:

- マージリクエスト

**パラメータ**:

- `@user1 @user2`: オプション。レビュアーとして削除する1つまたは複数のユーザー名。指定しない場合は、すべてのレビュアーが削除されます。
- `me`: 自分自身をレビュアーから削除します。

**例**:

- 特定のレビュアーを削除します:

  ```plaintext
  /unassign_reviewer @alex @sam
  ```

- 自分自身をレビュアーから削除します:

  ```plaintext
  /unassign_reviewer me
  ```

- すべてのレビュアーを削除します:

  ```plaintext
  /unassign_reviewer
  ```

**補足情報**:

- `/remove_reviewer`は`/unassign_reviewer`のエイリアスです。
- レビュアーを割り当てするには、[`/assign_reviewer`](#assign_reviewer)を使用します。
- レビュアーを置き換えるには、[`/reassign_reviewer`](#reassign_reviewer)を使用します。

### `unlabel` {#unlabel}

ラベルを削除します。

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**パラメータ**:

- `~label1 ~label2`: オプション。削除するラベル名を1つ以上指定します。指定しない場合、すべてのラベルが削除されます。

**例**:

- 特定のラベルを削除します:

  ```plaintext
  /unlabel ~bug ~"high priority"
  ```

- すべてのラベルを削除します:

  ```plaintext
  /unlabel
  ```

**補足情報**:

- 名前にスペースが含まれるラベルは、二重引用符で囲む必要があります。
- `/remove_label`は`/unlabel`のエイリアスです。
- ラベルを追加するには、[`/label`](#label)を使用します。
- ラベルを置き換えるには、[`/relabel`](#relabel)を使用します。

### `unlink` {#unlink}

別の作業アイテムへのリンクを削除します。

{{< history >}}

- GitLab 16.1で、イシューとエピック向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/414400)されました。
- GitLab 17.8で、タスク、目標、主な成果向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/481851)されました。

{{< /history >}}

**可用性**:

- エピック
- インシデント
- イシュー
- タスク
- 目標
- 主な成果

**パラメータ**:

- `<item>`: リンクを解除する作業アイテム。値は、`#item`、`group/project#item`、または完全なURLの形式にする必要があります。

**例**:

- 作業アイテムのリンクを解除します:

  ```plaintext
  /unlink #123
  ```

- URLを使用して作業アイテムのリンクを解除します:

  ```plaintext
  /unlink https://gitlab.com/group/project/-/work_items/123
  ```

**補足情報**:

- 作業アイテム間の関係を設定するには、[`/relate`](#relate) 、[`/blocks`](#blocks) 、または[`/blocked_by`](#blocked_by)を使用します。

### `unlock` {#unlock}

ディスカッションのロックを解除します。

**可用性**:

- エピック
- イシュー
- マージリクエスト

**例**:

- ディスカッションのロックを解除します:

  ```plaintext
  /unlock
  ```

**補足情報**:

- ディスカッションをロックするには、[`/lock`](#lock)を使用します。

### `unsubscribe` {#unsubscribe}

作業アイテムの通知の登録を解除します。

{{< history >}}

- GitLab 16.4で、タスク、目標、主な成果向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/420796)されました。

{{< /history >}}

**可用性**:

- エピック
- インシデント
- イシュー
- マージリクエスト
- タスク
- 目標
- 主な成果

**例**:

- 通知の登録を解除します:

  ```plaintext
  /unsubscribe
  ```

**補足情報**:

- 通知を登録するには、[`/subscribe`](#subscribe)を使用します。

### `weight` {#weight}

ウェイトを設定します。

**可用性**:

- イシュー
- タスク

**パラメータ**:

- `<value>`: ウェイト値。有効な値は、`0`、`1`、または`2`のような整数です。

**例**:

- ウェイトを設定:

  ```plaintext
  /weight 3
  ```

### `zoom` {#zoom}

Zoomミーティングをイシューまたはインシデントに追加します。

**可用性**:

- インシデント
- イシュー

**パラメータ**:

- `<Zoom URL>`: ZoomミーティングのURL。

**例**:

- Zoomミーティングを追加:

  ```plaintext
  /zoom https://zoom.us/j/123456789
  ```

**補足情報**:

- GitLab Premiumのユーザーは、[Zoomリンクをインシデントに追加する](../../operations/incident_management/linked_resources.md#link-zoom-meetings-from-an-incident)際に、短い説明を追加できます。
- Zoomミーティングを削除するには、[`/remove_zoom`](#remove_zoom)を使用します。

## コミットコメント {#commit-comments}

個々のコミットにコメントするときに、クイックアクションを使用できます。これらのクイックアクションは、コミットコメントスレッドでのみ機能し、コミットメッセージやその他のGitLabコンテキストでは機能しません。

コミットコメントでクイックアクションを使用するには、以下の手順に従います:

1. コミットリスト、マージリクエスト、またはその他のコミットリンクからコミットを選択して、コミットページに移動します。
1. コミットページの1番下にあるコメントフォームで、クイックアクションを入力します。
1. **コメント**を選択します。

次のクイックアクションは、コミットコメントに適用できます:

### `tag` {#tag}

コメントされたコミットを指すGitのタグを作成します。

**パラメータ**:

- `v1.2.3`: タグ名。
- `<message>`: オプション。タグのメッセージ。

**例**:

- メッセージ付きのタグを作成します:

  ```plaintext
  Ready for release after security fix.
  /tag v2.1.1 Security patch release
  ```

  このコメントは、メッセージ「Security patch release」で、コミットを指す`v2.1.1`というGitタグ名を作成します。

## トラブルシューティング {#troubleshooting}

### クイックアクションが実行されない {#quick-action-isnt-executed}

クイックアクションを実行しても何も起こらない場合は、クイックアクションを入力時にオートコンプリートボックスに表示されるかどうかを確認してください。表示されない場合は、次の可能性があります:

- クイックアクションに関連する機能は、サブスクリプションプランまたはグループやプロジェクトのユーザーロールに基づいて使用できない可能性があります。
- クイックアクションに必要な条件が満たされていません。たとえば、ラベルのないイシューで`/unlabel`を実行している場合などです。
