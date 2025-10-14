---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab クイック アクション
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

クイック アクションは、GitLabの一般的なアクションに対するテキストベースのショートカットを提供します。クイック アクション:

- ユーザーインターフェースを使用せずに、一般的なアクションを実行します。
- イシュー、マージリクエスト、エピック、コミットの操作をサポートします。
- 説明またはコメントを保存すると、自動的に実行されます。
- 特定のコンテキストと条件に対応します。
- 別々の行に入力された複数のコマンドを処理します。

たとえば、クイック アクションを使用して、次のことができます。

- ユーザーを割り当てます。
- ラベルを追加します。
- 期限を設定します。
- 状態を変更します。
- その他の属性を設定します。

各コマンドはスラッシュ（`/`）で始まり、別の行に入力する必要があります。多くのクイック アクションはパラメーターを受け入れます。パラメーターは、引用符（`"`）または特定の形式で入力できます。

## パラメータ

多くのクイック アクションでは、パラメータが必要です。たとえば、`/assign` クイック アクションには、ユーザー名が必要です。GitLabは、利用可能な値のリストを提供することにより、ユーザーがパラメータを入力するのを支援するために、クイック アクションで[オートコンプリート文字](autocomplete_characters.md)を使用します。

パラメータを手動で入力する場合は、次の文字のみが含まれている場合を除き、二重引用符（`"`）で囲む必要があります。

- ASCII文字
- 数字 (0-9)
- アンダースコア (`_`)、ハイフン (`-`)、疑問符 (`?`)、ドット (`.`)、アンパサンド (`&`) またはアットマーク (`@`)

パラメータは大文字と小文字が区別されます。オートコンプリートはこれを処理し、引用符の挿入を自動的に行います。

## イシュー、マージリクエスト、エピック

次のクイック アクションは、説明、ディスカッション、スレッドに適用できます。一部のクイック アクションは、すべてのサブスクリプションプランで利用できるとは限りません。

<!--
Keep this table sorted alphabetically

To auto-format this table, use the VS Code Markdown Table formatter: `https://docs.gitlab.com/ee/development/documentation/styleguide/#editor-extensions-for-table-formatting`.
-->

| コマンド                                                                                         | イシュー                  | マージリクエスト          | エピック                   | アクション |
|:------------------------------------------------------------------------------------------------|:-----------------------|:-----------------------|:-----------------------|:-------|
| `/add_child <item>`                       | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | `<item>` を子アイテムとして追加します。`<item>` の値は、`#item`、`group/project#item`、またはアイテムへのURLの形式である必要があります。イシューでは、タスクとOKRを追加できます。[イシューの新しい外観](issues/issue_work_items.md)を有効にする必要があります。エピックでは、イシュー、タスク、OKRを追加できます。複数の作業アイテムを子アイテムとして同時に追加できます。[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/add_contacts [contact:email1@example.com] [contact:email2@example.com]`                       | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | 1つまたは複数のアクティブな[CRM 担当者](../crm/_index.md)を追加します。 |
| `/add_email email1 email2`                                                                      | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | 最大6人の[メール参加者](service_desk/external_participants.md)を追加します。このアクションは、機能フラグ `issue_email_participants` の背後にあります。[イシューテンプレート](description_templates.md)ではサポートされていません。 |
| `/approve`                                                                                      | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | マージリクエストを承認します。 |
| `/assign @user1 @user2`                                                                         | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | 1人以上のユーザーを割り当てます。 |
| `/assign me`                                                                                    | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | 自分自身を割り当てます。 |
| `/assign_reviewer @user1 @user2` または `/reviewer @user1 @user2`                                   | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | 1人以上のユーザーをレビュアーとして割り当てます。 |
| `/assign_reviewer me` または `/reviewer me`                                                         | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | 自分自身をレビュー担当者として割り当てます。 |
| `/blocked_by <item1> <item2>`                                                                   | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | アイテムを他のアイテムによってブロックされているとしてマークします。`<item>` の値は、`#item`、`group/project#item`、または完全なURLの形式である必要があります。（GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/214232)）。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/blocks <item1> <item2>`                                                                       | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | アイテムを他のアイテムをブロックしているとしてマークします。`<item>` の値は、`#item`、`group/project#item`、または完全なURLの形式である必要があります。（GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/214232)）。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/cc @user`                                                                                     | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | ユーザーにメンションします。このコマンドはアクションを実行しません。代わりに、`CC @user` または `@user` のみを入力できます。 |
| `/clear_health_status`                                                                          | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | [ヘルスステータス](issues/managing_issues.md#health-status)をクリアします。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/clear_weight`                                                                                 | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | ウェイトをクリアします。 |
| `/clone <path/to/project> [--with_notes]`                                                       | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | 引数が指定されていない場合、イシューを指定されたプロジェクトまたは現在のプロジェクトにクローンします。ターゲットプロジェクトにラベル、マイルストーン、エピックなどの同等のオブジェクトが含まれている限り、可能な限り多くのデータをコピーします。`--with_notes` が引数として指定されていない限り、コメントまたはシステムノートはコピーしません。 |
| `/close`                                                                                        | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | クローズ。 |
| `/confidential`                                                                                 | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | イシューまたはエピックを機密としてマークします。エピックのサポートは、GitLab 15.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/213741)されました。 |
| `/convert_to_ticket <email address>`                                                            | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | [イシューをサービスデスクチケットに変換](service_desk/using_service_desk.md#convert-a-regular-issue-to-a-service-desk-ticket)します。GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/433376) |
| `/copy_metadata <!merge_request>`                                                               | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | プロジェクト内の別のマージリクエストからラベルとマイルストーンをコピーします。 |
| `/copy_metadata <#item>`                                                                       | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい| プロジェクト内の別のイシューからラベルとマイルストーンをコピーします。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/create_merge_request <branch name>`                                                           | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | 現在のイシューから開始して、新しいマージリクエストを作成します。 |
| `/done`                                                                                         | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい| To Doアイテムを完了としてマークします。 |
| `/draft`                                                                                        | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | [下書き状態](merge_requests/drafts.md)を設定します。 |
| `/due <date>`                                                                                   | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | 期限を設定します。有効な `<date>` の例としては、`in 2 days`、`this Friday`、`December 31st` などがあります。詳細については、[Chronic](https://gitlab.com/gitlab-org/ruby/gems/gitlab-chronic#examples)を参照してください。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/duplicate <item>`                                                                             | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | この<work item type>を閉じます。関連アイテムとしてマークし、<#item>の複製としてマークします。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/epic <epic>` または `/set_parent <epic>`                                                          | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい| エピック `<epic>` に子アイテムとして追加します。`<epic>` の値は、`&epic`、`group&epic`、またはエピックへのURLの形式である必要があります。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。GitLab 17.10でエイリアスが `/set_parent` [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/514942)されました。 |
| `/estimate <time>` または `/estimate_time <time>`                                                   | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 時間見積もりを設定します。例: `/estimate 1mo 2w 3d 4h 5m`。詳細については、[タイムトラッキング](time_tracking.md)を参照してください。GitLab 15.6でエイリアスが `/estimate_time` [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/16501)されました。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/health_status <value>`                                                                        | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | [ヘルスステータス](issues/managing_issues.md#health-status)を設定します。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。`<value>` の有効なオプションは、`on_track`、`needs_attention`、`at_risk`です。 |
| `/iteration *iteration:<iteration ID> or <iteration name>`                                      | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | イテレーションを設定します。たとえば、`Late in July` イテレーションを設定するには、`/iteration *iteration:"Late in July"` を使用します。 |
| `/iteration [cadence:<iteration cadence ID> or <iteration cadence name>] <--current or --next>` | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | イテレーションを、参照されるイテレーションケイデンスの現在または次に予定されているイテレーションに設定します。たとえば、`/iteration [cadence:"Team cadence"] --current` は、イテレーションを「Team cadence」という名前のイテレーションケイデンスの現在のイテレーションに設定します。GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/384885)されました。 |
| `/iteration <--current or --next>`                                                              | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | グループに1つのイテレーションケイデンスがある場合、イテレーションを現在または次に予定されているイテレーションに設定します。たとえば、`/iteration --current` は、イテレーションをイテレーションケイデンスの現在のイテレーションに設定します。GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/384885)されました。 |
| `/label ~label1 ~label2` または `/labels ~label1 ~label2`                                           | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 1つまたは複数のラベルを追加します。ラベル名はチルダ（`~`）なしで開始することもできますが、混合構文はサポートされていません。 |
| `/link`                                                                                         | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | インシデントで[リンクされたリソース](../../operations/incident_management/linked_resources.md)へのリンクと説明を追加します（GitLab 15.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/374964)）。 |
| `/lock`                                                                                         | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | ディスカッションをロックします。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/merge`                                                                                        | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | 変更をマージします。プロジェクトの設定によっては、[パイプラインが成功したとき](merge_requests/auto_merge.md)、または[マージトレイン](../../ci/pipelines/merge_trains.md)に追加される場合があります。 |
| `/milestone %milestone`                                                                         | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | マイルストーンを設定します。 |
| `/move <path/to/project>`                                                                       | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | このイシューを別のプロジェクトに移動します。異なるアクセスルールのプロジェクトにイシューを移動する場合は注意してください。イシューを移動する前に、機密データが含まれていないことを確認してください。 |
| `/page <policy name>`                                                                           | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | インシデントのエスカレーションを開始します。 |
| `/parent_epic <epic>`                                                                           | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | 親エピックを`<epic>`に設定します。`<epic>` の値は、`&epic`、`group&epic`、またはエピックへのURLの形式である必要があります。[エピックの新しい外観](../group/epics/epic_work_items.md)が有効になっている場合は、代わりに`/set_parent`を使用してください。 |
| `/promote_to_incident`                                                                          | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | イシューをインシデントにプロモートします。[GitLab 15.8以降](https://gitlab.com/gitlab-org/gitlab/-/issues/376760)では、新しいイシューを作成するときにクイック アクションを使用することもできます。 |
| `/promote`                                                                                      | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | イシューをエピックにプロモートします。[イシューの新しい外観](issues/issue_work_items.md)が有効になっている場合は、代わりに`/promote_to epic`を使用してください。 |
| `/publish`                                                                                      | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | 関連付けられた[状態ページ](../../operations/incident_management/status_page.md)にイシューを公開します。 |
| `/react :emoji:`                                                                                | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 絵文字リアクションを切り替えます。GitLab 16.7で[名前が変更](https://gitlab.com/gitlab-org/gitlab/-/issues/409884)されました。`/award`。`/award`は、エイリアス化されたコマンドとして引き続き使用できます。 |
| `/ready`                                                                                        | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | [準備完了状態](merge_requests/drafts.md#mark-merge-requests-as-ready)を設定します（GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90361)）。 |
| `/reassign @user1 @user2`                                                                       | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | 現在の担当者を、指定された担当者と置き換えます。 |
| `/reassign_reviewer @user1 @user2`                                                              | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | 現在のレビュー担当者を、指定されたレビュー担当者と置き換えます。 |
| `/rebase`                                                                                       | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | ターゲットブランチの最新のコミットでソースブランチをリベースします。ヘルプについては、[トラブルシューティング情報](../../topics/git/troubleshooting_git.md)を参照してください。 |
| `/relabel ~label1 ~label2`                                                                      | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 現在のラベルを、指定されたラベルと置き換えます。 |
| `/relate <item1> <item2>`                                                                       | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | アイテムを関連としてマークします。`<item>` の値は、`#item`、`group/project#item`、または完全なURLの形式である必要があります。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/remove_child <item>`                                                                          | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | `<item>`を子として削除します。`<item>` の値は、`#item`、`group/project#item`、またはアイテムへのURLの形式である必要があります。イシューの場合、[イシューの新しい外観](issues/issue_work_items.md)を有効にする必要があります。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/remove_child_epic <epic>`                                                                     | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | `<epic>`から子エピックを削除します。`<epic>` の値は、`&epic`、`group&epic`、またはエピックへのURLの形式である必要があります。[エピックの新しい外観](../group/epics/epic_work_items.md)が有効になっている場合は、代わりに`/remove_child`を使用してください。 |
| `/remove_contacts [contact:email1@example.com] [contact:email2@example.com]`                    | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | 1つ以上の[CRMコンタクト](../crm/_index.md)を削除します |
| `/remove_due_date`                                                                              | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | 期限を削除します。 |
| `/remove_email email1 email2`                                                                   | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | 最大6人の[メール参加者](service_desk/external_participants.md)を削除します。このアクションは、機能フラグ `issue_email_participants` の背後にあります。イシューテンプレート、マージリクエスト、またはエピックではサポートされていません。 |
| `/remove_epic`                                                                                  | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | エピックを親アイテムとして削除します。[エピックの新しい外観](../group/epics/epic_work_items.md)が有効になっている場合は、代わりに`/remove_parent`を使用してください。 |
| `/remove_estimate` または `/remove_time_estimate`                                                   | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 時間見積もりを削除します。GitLab 15.6でエイリアスが `/remove_time_estimate` [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/16501)されました。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/remove_iteration`                                                                             | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | イテレーションを削除します。 |
| `/remove_milestone`                                                                             | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | マイルストーンを削除します。 |
| `/remove_parent`                                                                                | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | アイテムから親を削除します。イシューの場合、[イシューの新しい外観](issues/issue_work_items.md)を有効にする必要があります。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/remove_parent_epic`                                                                           | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | エピックから親エピックを削除します。[エピックの新しい外観](../group/epics/epic_work_items.md)が有効になっている場合は、代わりに`/remove_parent`を使用してください。 |
| `/remove_time_spent`                                                                            | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 費やした時間を削除します。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/remove_zoom`                                                                                  | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | このイシューからZoomミーティングを削除します。 |
| `/reopen`                                                                                       | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 再開します。 |
| `/request_review @user1 @user2`                                                                 | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | 1人以上のユーザーに新しいレビューを割り当てるか、リクエストします。 |
| `/request_review me`                                                                            | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | 1人以上のユーザーに新しいレビューを割り当てるか、リクエストします。 |
| `/set_parent <item>`                                                                           | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | 親アイテムを設定します。`<item>`の値は、`#IID`、参照、またはアイテムへのURLの形式である必要があります。イシューの場合、[イシューの新しい外観](issues/issue_work_items.md)を有効にする必要があります。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/severity <severity>`                                                                          | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | 重大度を設定します。イシューの種類は`Incident`である必要があります。`<severity>`のオプションは、`S1` ... `S4`、`critical`、`high`、`medium`、`low`、`unknown`です。 |
| `/shrug`                                                                                        | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | `¯\＿(ツ)＿/¯`を追加します。 |
| `/spend <time> [<date>]` または `/spend_time <time> [<date>]`                                       | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい| 費やした時間を追加または減算します。オプションで、時間が費やされた日付を指定します。たとえば、`/spend 1mo 2w 3d 4h 5m 2018-08-26`や`/spend -1h 30m`です。詳細については、[タイムトラッキング](time_tracking.md)を参照してください。GitLab 15.6でエイリアス`/spend_time`が [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/16501)されました。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/submit_review`                                                                                | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | 保留中のレビューを送信します。 |
| `/subscribe`                                                                                    | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 通知を購読します。 |
| `/tableflip`                                                                                    | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | `(╯°□°)╯︵ ┻━┻`を追加します。 |
| `/target_branch <local branch name>`                                                            | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | ターゲットブランチを設定します。 |
| `/timeline <timeline comment> \| <date(YYYY-MM-DD)> <time(HH:MM)>`                              | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | このインシデントにタイムラインイベントを追加します。たとえば、`/timeline DB load spiked \| 2022-09-07 09:30`。（GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/368721)）。 |
| `/title <new title>`                                                                            | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | タイトルを変更します。 |
| `/todo`                                                                                         | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | To Doアイテムを追加します。 |
| `/unapprove`                                                                                    | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | マージリクエストを否認します。 |
| `/unassign @user1 @user2`                                                                       | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | 特定の担当者を削除します。 |
| `/unassign_reviewer @user1 @user2` または `/remove_reviewer @user1 @user2`                          | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | 特定レビュアーを削除します。 |
| `/unassign_reviewer me`                                                                         | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | 自分自身をレビュアーから削除します。 |
| `/unassign_reviewer` または `/remove_reviewer`                                                      | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | すべてのレビュアーを削除します。 |
| `/unassign`                                                                                     | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | すべての担当者を削除します。 |
| `/unlabel ~label1 ~label2` または `/remove_label ~label1 ~label2`                                   | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 指定されたラベルを削除します。 |
| `/unlabel` または `/remove_label`                                                                   | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | すべてのラベルを削除します。 |
| `/unlink <item>`                                                                                | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい| 指定されたイシューとのリンクを削除します。`<item>` の値は、`#item`、`group/project#item`、または完全なURLの形式である必要があります。（GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/414400)）。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。 |
| `/unlock`                                                                                       | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい| ディスカッションのロックを解除します。エピックの場合、[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。|
| `/unsubscribe`                                                                                  | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 通知の登録を解除します。 |
| `/weight <value>`                                                                               | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | ウェイトを設定します。有効な値は、`0`、`1`、または `2` のような整数です。 |
| `/zoom <Zoom URL>`                                                                              | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | このイシューまたはインシデントにZoomミーティングを追加します。[GitLab 15.3 以降](https://gitlab.com/gitlab-org/gitlab/-/issues/230853)、GitLab Premiumのユーザーは、[インシデントにZoomリンクを追加](../../operations/incident_management/linked_resources.md#link-zoom-meetings-from-an-incident)するときに、簡単な説明を追加できます。 |

## 作業アイテム

{{< history >}}

- コメントからのクイック アクションの実行（GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391282)）。

{{< /history >}}

GitLab の作業アイテムには、[タスク](../tasks.md)と [OKR](../okrs.md) が含まれます。次のクイック アクションは、作業アイテムの編集時またはコメント時に説明フィールドを通じて適用できます。

<!--
Keep this table sorted alphabetically

To auto-format this table, use the VS Code Markdown Table formatter: `https://docs.gitlab.com/ee/development/documentation/styleguide/#editor-extensions-for-table-formatting`.
-->

| コマンド                                                       | タスク                   | 目標              | 主な成果             | アクション |
|:--------------------------------------------------------------|:-----------------------|:-----------------------|:-----------------------|:-------|
| `/assign @user1 @user2`                                       | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 1人以上のユーザーを割り当てます。 |
| `/assign me`                                                  | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 自分自身を割り当てます。 |
| `/add_child <work_item>`                                                                         | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | `<work_item>` に子を追加します。`<work_item>` の値は、`#item`、`group/project#item`、または作業アイテムへの URL の形式である必要があります。複数の作業アイテムを子アイテムとして同時に追加できます。GitLab 16.5 [で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/420797)。 |
| `/award :emoji:`                                                                                 | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 絵文字リアクションを切り替えます。GitLab 16.5[で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412275) |
| `/cc @user`                                                   | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | ユーザーにメンションします。GitLab 15.0 以降、このコマンドはアクションを実行しません。代わりに、`CC @user` または `@user` のみを入力できます。 |
| `/checkin_reminder <cadence>`                                 | {{< icon name="dotted-circle" >}} いいえ| {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | [チェックインリマインダー](../okrs.md#schedule-okr-check-in-reminders)をスケジュールします。オプションは、`weekly`、`twice-monthly`、`monthly`、または `never` (デフォルト)です。[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422761) GitLab 16.4 (フラグ名は `okrs_mvc` と `okr_checkin_reminders`)。  |
| `/clear_health_status`                                        | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | [ヘルスステータス](issues/managing_issues.md#health-status)をクリアします。 |
| `/clear_weight`                                               | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | ウェイトをクリアします。 |
| `/close`                                                      | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | クローズ。 |
| `/confidential`                                               | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | GitLab 16.4に[導入された](https://gitlab.com/gitlab-org/gitlab/-/issues/412276)作業アイテムを機密としてマークします。 |
| `/copy_metadata <work_item>`                                  | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 同じネームスペース内の別の作業アイテムからラベルとマイルストーンをコピーします。`<work_item>` の値は、`#item` の形式か、作業アイテムへのURLである必要があります。GitLab 17.9 [で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/509076)。 |
| `/done`                                                       | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | To Doアイテムを完了としてマークします。GitLab 16.2 [で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412277)。 |
| `/due <date>`                                                 | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | 期限を設定します。有効な `<date>` の例としては、`in 2 days`、`this Friday`、`December 31st` などがあります。 |
| `/health_status <value>`                                      | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | [ヘルスステータス](issues/managing_issues.md#health-status)を設定します。`<value>` の有効なオプションは、`on_track`、`needs_attention`、または `at_risk` です。 |
| `/label ~label1 ~label2` または `/labels ~label1 ~label2`         | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 1つまたは複数のラベルを追加します。ラベル名はチルダ（`~`）なしで開始することもできますが、混合構文はサポートされていません。 |
| `/promote_to <type>`                                          | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | 作業アイテムを指定されたタイプにプロモートします。`<type>` で使用できるオプション：`issue` (タスクをプロモート) または `objective` (主な成果をプロモート)。GitLab 16.1[で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412534)。 |
| `/reassign @user1 @user2`                                     | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 現在の担当者を、指定された担当者と置き換えます。 |
| `/relabel ~label1 ~label2`                                    | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 現在のラベルを、指定されたラベルと置き換えます。 |
| `/remove_due_date`                                            | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | 期限を削除します。 |
| `/remove_child <work_item>`                                                                         | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | 子 `<work_item>` を削除します。`<work_item>` の値は、`#item`、`group/project#item`、または作業アイテムへの URL の形式である必要があります。GitLab 16.10[で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/132761)。 |
| `/remove_parent`                                     | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | 親作業アイテムを削除します。GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/434344)されました。 |
| `/reopen`                                                     | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 再開します。 |
| `/set_parent <work_item>`                                     | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | 親作業アイテムを `<work_item>` に設定します。`<work_item>` の値は、`#item`、`group/project#item`、または作業アイテムへの URL の形式である必要があります。GitLab 16.5 [で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/420798)。GitLab 17.10[で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/514942)された[新しいルックのイシュー](issues/issue_work_items.md)に対するエイリアス`/epic`。 |
| `/shrug`                                            | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | `¯\＿(ツ)＿/¯`を追加します。 |
| `/subscribe`                                                  | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 通知を購読します。GitLab 16.4[で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/420796) |
| `/tableflip`                                        | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | `(╯°□°)╯︵ ┻━┻`を追加します。 |
| `/title <new title>`                                          | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | タイトルを変更します。 |
| `/todo`                                                       | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | To Doアイテムを追加します。GitLab 16.2 [で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412277)。 |
| `/type`                                                       | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 作業アイテムを指定されたタイプに変換します。`<type>` で使用できるオプションには、`issue`、`task`、`objective`、`key result` があります。GitLab 16.0[で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385227)。 |
| `/unassign @user1 @user2`                                     | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 特定の担当者を削除します。 |
| `/unassign`                                                   | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | すべての担当者を削除します。 |
| `/unlabel ~label1 ~label2` または `/remove_label ~label1 ~label2` | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 指定されたラベルを削除します。 |
| `/unlabel` または `/remove_label`                                 | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | すべてのラベルを削除します。 |
| `/unlink`                                                     | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 指定された作業アイテムへのリンクを削除します。`<work item>` の値は、`#work_item`、`group/project#work_item`、または完全な作業アイテム URL の形式である必要があります。GitLab 17.8 [で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/481851)。 |
| `/unsubscribe`                                                  | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | {{< icon name="check-circle" >}} はい | 通知の登録を解除します。GitLab 16.4[で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/420796) |
| `/weight <value>`                                             | {{< icon name="check-circle" >}} はい | {{< icon name="dotted-circle" >}} いいえ | {{< icon name="dotted-circle" >}} いいえ | ウェイトを設定します。`<value>` で使用できる有効なオプションは、`0`、`1`、`2` などです。 |

## コミットメッセージ

以下のクイック アクションは、コミットメッセージに適用できます。

| コマンド                 | アクション                                    |
|:----------------------- |:------------------------------------------|
| `/tag v1.2.3 <message>` | オプションのメッセージでコミットにタグ付けをします。 |

## トラブルシューティング

### クイック アクションが実行されない

クイック アクションを実行しても何も起こらない場合は、クイック アクションを入力時にオートコンプリートボックスに表示されるかどうかを確認してください。表示されない場合は、次の可能性があります。

- クイック アクションに関連する機能は、サブスクリプションプランまたはグループやプロジェクトのユーザーロールに基づいて使用できない可能性があります。
- クイック アクションに必要な条件が満たされていません。たとえば、ラベルのないイシューで `/unlabel` を実行している場合などです。
