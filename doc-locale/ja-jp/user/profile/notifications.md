---
stage: Growth
group: Engagement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 通知メール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 強化されたメールスタイリングは、GitLab 14.9で`enhanced_notify_css`[機能フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78604)されました。デフォルトでは無効になっています。
- 強化されたメールスタイリングは、GitLab 14.9の[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/355907)。
- 強化されたメールスタイリングは、GitLab 15.0の[GitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/355907)。
- GitLab 18.3では、高度なメールスタイリングが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/355907)されています。機能フラグ`enhanced_notify_css`は削除されました。
- プロダクトマーケティングメールは、GitLab 16.6で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/418137)。

{{< /history >}}

メール通知によりGitLabで何が起こっているかを常に把握できます。イシュー、マージリクエスト、エピック、およびデザインのアクティビティーに関する更新を受信できます。

GitLab管理者がユーザーにメッセージを送信するために使用できるツールについては、[GitLabからのメール](../../administration/email_from_gitlab.md)をお読みください。

GitLab 17.2以降では、通知は、24時間ごとにプロジェクト/グループまたはユーザー単位で[レート制限](../../security/rate_limits.md#notification-emails)されます。

## 通知を受け取るユーザー {#who-receives-notifications}

イシュー、マージリクエスト、またはエピックで通知が有効になっている場合、GitLabはそこで発生するアクションを通知します。

次のいずれかの理由で通知を受信する場合があります。

- イシュー、マージリクエスト、エピック、またはデザインに参加している。コメントや編集をしたり、誰かがユーザー名に言及すると、あなたはそのスレッドの参加者になります。
- [イシュー、マージリクエスト、またはエピックで通知を有効にしている](#issue-merge-request-and-epic-events)。
- [プロジェクト](#change-level-of-project-notifications)または[グループ](#group-notifications)の通知を設定している。
- パイプラインメール[インテグレーション](../project/integrations/_index.md)を介して、グループまたはプロジェクトのパイプライン通知をサブスクライブしている。

GitLabは、次の場合に通知を送信しません。

- アカウントがプロジェクトボットである。
- アカウントがデフォルトのメールアドレスを持つサービスアカウントである。
- アカウントがブロック（BAN）または非アクティブ化されている。
- [コメントが編集され、ユーザーメンションが含まれている](../discussions/_index.md#edit-a-comment-to-add-a-mention)。
- 管理者が通知をブロックしている。

## グローバル通知設定 {#global-notification-settings}

グローバル通知設定は、プロジェクトまたはグループに対して別の値を指定しない限り、デフォルトの設定になります。たとえば、特定のプロジェクト内のすべてのアクティビティーについて通知を受けたい場合があります。他のプロジェクトでは、名前でメンションされた場合のみに通知を受けたいと考えています。

これらの通知設定は、自分のみに適用されます。他の人が受け取る通知には影響しません。

### 通知設定の編集 {#edit-notification-settings}

通知設定を編集するには:

1. 右上隅でアバターを選択します。
1. **設定**を選択します。
1. 左側のサイドバーで、**通知**を選択します。
1. **グローバル通知メール**で、通知の送信先メールアドレスを入力します。デフォルトでは、プライマリメールアドレスになります。
1. **グローバル通知レベル**で、デフォルトの[通知レベル](#notification-levels)を選択して、通知に適用します。
1. **自身のアクティビティーに関する通知を受信する**チェックボックスをオンにすると、自分のアクティビティーに関する通知を受信できます。デフォルトでは選択されていません。

### 通知レベル {#notification-levels}

各プロジェクトとグループの右側で、通知レベルを選択できます:

| レベル           | 説明 |
|-----------------|-------------|
| **グローバル**      | デフォルトのグローバル設定が適用されます。 |
| **すべて通知**       | ほとんどのアクティビティーの通知を受信します。 |
| **参加** | 参加したスレッドに関する通知を受信します。 |
| **メンション時**  | コメントで[メンション](../discussions/_index.md#mentions)された場合に通知を受信します。 |
| **無効**    | 通知を受信しません。 |
| **カスタム**      | **参加**と同じですが、選択した通知イベントが追加されます。 |

### 通知スコープ {#notification-scope}

プロジェクトおよびグループごとに異なる通知レベルを選択することで、通知のスコープを調整できます。

通知スコープは、最も広範なレベルから最も具体的なレベルに適用されます。

- アクティビティーが発生したプロジェクトまたはグループの通知レベルを選択していない場合、グローバルまたは_デフォルト_の通知レベルが適用されます。
- グループ設定は、デフォルト設定よりも優先されます。
- プロジェクト設定は、グループ設定よりも優先されます。

プロジェクトまたはサブグループに対して通知レベルを**グローバル**設定しても、グローバル通知設定は直接継承されません。代わりに、グローバル通知レベルよりも階層が高い設定済み通知レベルを次の順序で継承します。

1. プロジェクト設定。
1. 親グループ設定。
1. 祖先グループ設定（階層を上がります）。
1. 最終的なフォールバック設定としてのグローバル通知の設定。

たとえば、デフォルトのグローバル通知設定を**すべて通知**に設定し、グループとプロジェクトの通知レベルを次のように設定します。

```mermaid
%%{init: { "fontFamily": "GitLab Sans", 'theme':'neutral' }}%%
flowchart TD
  accTitle: Notification hierarchy
  accDescr: Example of a group, subgroup, and project

    N[Default/global notification level set to Watch]
    N --> A
    A[Group A: Notification level set to Global]
    A-. Inherits Watch level .-> N
    A --> B[Subgroup B: Notification level set to Participate]
    B --> C[Project C: Notification level set to Global]
    C-. Inherits Participate level .-> B
```

プロジェクトCは、サブグループBから**参加**通知レベルを継承します。グローバル通知設定から**すべて通知**通知レベルを継承しません。

### グループ通知 {#group-notifications}

グループごとに、通知レベルとメールアドレスを選択できます。

#### グループ通知のレベルを変更 {#change-level-of-group-notifications}

グループの通知レベルを選択するには、次のいずれかの方法を使用します。

1. 右上隅でアバターを選択します。
1. **設定**を選択します。
1. 左側のサイドバーで、**通知**を選択します。
1. **グループ**セクションでグループを見つけます。
1. 目的の[通知レベル](#notification-levels)を選択します。

または:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. ベルアイコン（{{< icon name="notifications" >}}）の横にある通知ドロップダウンリストを選択します。
1. 目的の[通知レベル](#notification-levels)を選択します。

#### グループ通知に使用されるメールアドレスを変更 {#change-email-address-used-for-group-notifications}

自分が所属するグループごとに、通知を受信するメールアドレスを選択できます。たとえば、フリーランスで仕事をしている場合、クライアントのプロジェクトに関するメールを個別に管理したいときに、グループ通知を使用できます。

1. 右上隅でアバターを選択します。
1. **設定**を選択します。
1. 左側のサイドバーで、**通知**を選択します。
1. **グループ**セクションでグループを見つけます。
1. 目的のメールアドレスを選択します。

### プロジェクト通知のレベルを変更 {#change-level-of-project-notifications}

最新情報を常に把握できるように、プロジェクトごとに通知レベルを選択できます。

プロジェクトの通知レベルを選択するには、次のいずれかの方法を使用します。

1. 右上隅でアバターを選択します。
1. **設定**を選択します。
1. 左側のサイドバーで、**通知**を選択します。
1. **プロジェクト**セクションでプロジェクトを見つけます。
1. 目的の[通知レベル](#notification-levels)を選択します。

または:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. ベルアイコン（{{< icon name="notifications" >}}）の横にある通知ドロップダウンリストを選択します。
1. 目的の[通知レベル](#notification-levels)を選択します。

<i class="fa-youtube-play" aria-hidden="true"></i>新しいリリースが利用可能になったときに通知を受け取る方法については、[リリースの通知](https://www.youtube.com/watch?v=qyeNkGgqmH4)をご覧ください。

## 通知イベント {#notification-events}

ユーザー、プロジェクト、またはグループイベント、および作業アイテムのアクティビティーの通知が送信されます。

### ユーザーイベント {#user-events}

{{< history >}}

- パーソナルアクセストークンのローテーションに関する通知は、GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199360)されました。

{{< /history >}}

ユーザーの通知イベント:

| イベント                                    | 送信先 | 詳細 |
|------------------------------------------|---------|---------|
| メールアドレスが変更された                            | ユーザー    | 常に送信されるセキュリティメール。 |
| グループアクセスレベルが変更された               | ユーザー    |         |
| 新しいメールアドレスが追加された                  | ユーザー    | 新しく追加されたメールアドレスに送信されるセキュリティメール。 |
| 新しいメールアドレスが追加された                  | ユーザー    | プライマリメールアドレスに送信されるセキュリティメール。 |
| 新しいSSHキーが追加された                        | ユーザー    | 常に送信されるセキュリティメール。 |
| 新しいユーザーが作成された                         | ユーザー    | ユーザーの作成時に送信されます。OmniAuth（LDAP）は除きます。 |
| パスワードが変更された                         | ユーザー    | ユーザーが自分のパスワードを変更すると常に送信されるセキュリティメール。 |
| 管理者によってパスワードが変更された        | ユーザー    | 管理者が別のユーザーのパスワードを変更すると常に送信されるセキュリティメール。 |
| パーソナルアクセストークンが失効した   | ユーザー    | 常に送信されるセキュリティメール。 |
| パーソナルアクセストークンがローテーションされました   | ユーザー    | 常に送信されるセキュリティメール。 |
| パーソナルアクセストークンの有効期限が近づいている     | ユーザー    | 常に送信されるセキュリティメール。 |
| パーソナルアクセストークンが作成された | ユーザー    | 常に送信されるセキュリティメール。 |
| パーソナルアクセストークンの有効期限が切れた      | ユーザー    | 常に送信されるセキュリティメール。 |
| SSHキーの有効期限が切れた                      | ユーザー    | 常に送信されるセキュリティメール。 |
| 2要素認証が無効       | ユーザー    | 常に送信されるセキュリティメール。 |

### プロジェクトイベント {#project-events}

{{< history >}}

- プロジェクトアクセス期限切れの通知は、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/12704)されました。
- プロジェクトのアクセストークンの期限切れが近づいていることの通知は、GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/367706)されました。
- プロジェクトのデプロイトークンの期限切れが近づいていることの通知は、GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/512197)されました。
- プロジェクトの削除がスケジュールされていることの通知は、GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/522883)されました。

{{< /history >}}

プロジェクトの通知イベント:

| イベント                               | 送信先                               | 詳細 |
|-------------------------------------|---------------------------------------|---------|
| 新しいリリース                         | プロジェクトメンバー                       | **リリースが作成されました**カスタム通知レベルが選択されている場合にのみ送信されます。 |
| プロジェクトアクセスの有効期限が切れた              | プロジェクトメンバー                       | プロジェクトへのユーザーのアクセス権が7日後に期限切れになる場合に送信されます。 |
| プロジェクトアクセスレベルが変更された        | プロジェクトメンバー                       | ユーザープロジェクトのアクセスレベルが変更された場合に送信されます。 |
| プロジェクトアクセストークンの有効期限が近づいている | プロジェクトのオーナーとメンテナーに直接送信 | 常に送信されるセキュリティメール。 |
| プロジェクトのデプロイトークンの期限切れが近づいています | プロジェクトのオーナーとメンテナー        | 常に送信されるセキュリティメール。 |
| プロジェクトが移動した                       | プロジェクトメンバー                       | 通知レベルが無効になっている場合、または**プロジェクトが移動されました**カスタム通知レベルが選択されている場合を除き、すべての通知レベルで送信されます。 |
| プロジェクトの削除がスケジュールされた      | プロジェクトオーナー                        | プロジェクトの削除がスケジュールされている場合に送信されます。 |
| ユーザーがプロジェクトに追加された               | ユーザー                                  | ユーザーがプロジェクトに追加されたときに送信されます。 |

### グループイベント {#group-events}

{{< history >}}

- グループアクセス期限切れの通知は、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/12704)されました。
- グループアクセストークンの期限切れが近づいていることの通知は、GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/367705)されました。
- グループの削除がスケジュールされていることの通知は、GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/522883)されました。

{{< /history >}}

グループの通知イベント:

| イベント                             | 送信先             | 詳細 |
|-----------------------------------|---------------------|---------|
| グループアクセスの有効期限が切れた              | グループメンバー       | グループへのユーザーのアクセス権が7日後に期限切れになる場合に送信されます。 |
| グループアクセストークンの有効期限が近づいている | 直接グループオーナー | 常に送信されるセキュリティメール。 |
| グループの削除がスケジュールされた      | グループオーナー        | グループの削除がスケジュールされている場合に送信されます。 |
| ユーザーがグループに追加された               | ユーザー                | ユーザーがグループに追加されたときに送信されます。 |
| 新しいSAML/SCIMユーザーがプロビジョニングされた    | ユーザー                | ユーザーがSAML/SCIMを介してプロビジョニングされた場合に送信されます。 |

### イシュー、マージリクエスト、およびエピックイベント {#issue-merge-request-and-epic-events}

{{< history >}}

- 承認できるマージリクエストの通知は、GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/12855)され、GitLab 17.11で[名前が変更](https://gitlab.com/gitlab-org/gitlab/-/issues/465347)されました。
- サービスアカウントのパイプラインの通知は、GitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178740)されました。

{{< /history >}}

イベントは、選択された[通知レベル](#notification-levels)に基づいて通知を生成します。一部の通知は、オプションで**カスタム**通知レベルを選択し、目的のイベントを選択することで有効にできます。エピック、イシュー、またはマージリクエストの[通知をサブスクライブ](#subscribe-to-notifications-for-a-specific-issue-merge-request-or-epic)することもできます。

デフォルトでは、作成したイシュー、マージリクエスト、またはエピックの通知は受信しません。[自分自身のアクティビティーに関する通知](#global-notification-settings)をオンにすることができます。

エピックイベントの通知は、次の通知レベルで送信されます:

| イベント       | すべて通知 | 参加 | 言及時 | 登録 | カスタム   | 追加の詳細 |
|-------------|-------|-------------|------------|------------|----------|--------------------|
| 完了      | はい   | はい         |            | はい        | はい      |                    |
| 新しいエピック    | はい   | はい         | はい        |            | はい      | 誰かが説明でユーザー名で言及されたときに送信されます。 |
| 新しいコメント | はい   | はい         | はい        | はい        | **コメントが追加されました**が選択されている場合 | 誰かがコメントでユーザー名で言及されたときにも送信されます。 |
| 再開    | はい   | はい         |            | はい        | はい      |                    |

イシューイベントの通知は、次の通知レベルで送信されます:

| イベント                        | すべて通知 | 参加 | 言及時 | 登録 | カスタム   | 追加の詳細 |
|------------------------------|-------|-------------|------------|------------|----------|--------------------|
| 完了                       | はい   | はい         |            | はい        | **イシューがクローズされました**が選択されている場合 |                    |
| 期日は明日                 |       | はい         |            |            | **イシューの期限は明日です**が選択されている場合 | この通知は、次のカレンダー日の期日が開いているイシューの場合、サーバーのタイムゾーン（GitLab.comの場合はUTC）で00:50に送信されます。 |
| マイルストーンが変更された            | はい   | はい         |            | はい        | はい      |                    |
| マイルストーンが削除された            | はい   | はい         |            | はい        | はい      |                    |
| 新しいイシュー                    | はい   | はい         | はい        |            | **イシューが作成されました**が選択されている場合 | 誰かが説明でユーザー名で言及されたときにも送信されます。 |
| 新しいコメント                  | はい   | はい         | はい        | はい        | **コメントが追加されました**が選択されている場合 | 誰かがコメントでユーザー名で言及されたときにも送信されます。 |
| タイトルまたは説明が変更された | はい   |             | はい        |            |          | ユーザー名による新しいメンション。 |
| 再割り当てされた                   | はい   | はい         |            | はい        | **イシューが再アサインされました**が選択されている場合 | 以前の担当者にも送信されます。 |
| 再開                     | はい   | はい         |            | はい        | **イシューが再オープンしました**が選択されている場合 |                    |

<!-- For issue due timing source, see 'issue_due_scheduler_worker' in https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/1_settings.rb -->

マージリクエストの通知は、次の通知レベルで送信されます:

| イベント                                                  | すべて通知 | 参加 | 言及時 | 登録 | カスタム   | 追加の詳細 |
|--------------------------------------------------------|-------|-------------|------------|------------|----------|--------------------|
| 完了                                                 | はい   | はい         |            | はい        | **マージリクエストがクローズしました**が選択されている場合 |                    |
| 競合                                               | はい   |             |            |            |          | 作成者、およびマージリクエストを自動マージに設定したすべてのユーザー。 |
| [準備完了としてマークされた](../project/merge_requests/drafts.md) | はい   | はい         |            |            | はい      |                    |
| マージされた                                                 | はい   | はい         |            | はい        | **マージリクエストがマージされました**が選択されている場合 |                    |
| 自動マージに設定                                      | はい   | はい         |            | はい        | **マージリクエストが自動マージに設定されました**が選択されている場合 | カスタム通知レベルは、作成者、ウォッチャー、およびサブスクライバーに対して無視されます。 |
| マイルストーンが変更された                                      | はい   | はい         |            | はい        | はい      |                    |
| マイルストーンが削除された                                      | はい   | はい         |            | はい        | はい      |                    |
| 新しいマージリクエスト                                      | はい   | はい         | はい        |            | **マージリクエストが作成されました**が選択されている場合 | 説明でユーザー名が記載されているすべての人。 |
| 新しいコメント                                            | はい   | はい         | はい        | はい        | **コメントが追加されました**が選択されている場合 | コメントでユーザー名が記載されているすべての人。 |
| 新しいプッシュ                                               |       | はい         |            |            | **マージリクエストがプッシュを受信しました**が選択されている場合 |                    |
| 再割り当てされた                                             | はい   | はい         |            | はい        | **マージリクエストが再割り当てされました**が選択されている場合 | 以前の担当者にも送信されます。 |
| レビュアーが変更されました                                  | はい   | はい         |            | はい        | **マージリクエストのレビュアーが変更されました**が選択されている場合 | 以前のレビュアーにも送信されます。 |
| 再開                                               | はい   | はい         |            | はい        | **マージリクエストが再開されました**が選択されている場合 |                    |
| タイトルまたは説明が変更された                           | はい   |             | はい        |            |          | ユーザー名による新しいメンション。 |
| 承認できる新しいマージリクエスト。          |       |             |            |            | **あなたの承認が必要なマージリクエストが作成されました**が選択されている場合 |                    |

パイプラインイベントの通知は、次の通知レベルで送信されます:

| イベント      | すべて通知 | パイプラインの作成者 | カスタム   | 追加の詳細 |
|------------|-------|-----------------|----------|--------------------|
| 失敗した     | はい   | はい             | **パイプラインが失敗しました**が選択されている場合 |                    |
| 修正された      |       | はい             | **パイプラインが修正されました**が選択されている場合 |                    |
| 成功 | はい   | はい             | **パイプラインが完了しました**が選択されている場合 | パイプラインが以前に失敗した場合、失敗後に最初に成功したパイプラインに対して「パイプラインが修正されました」というメッセージが送信され、その後、成功したパイプラインに対して「パイプラインが成功しました」というメッセージが送信されます。 |

サービスアカウントパイプラインイベントの通知は、次の通知レベルで送信されます:

| イベント      | すべて通知 | カスタム |
|------------|-------|--------|
| 失敗した     | はい   | **サービスアカウントによるパイプラインが失敗しました**が選択されている場合 |
| 修正された      |       | **サービスアカウントによるパイプラインが修正されました**が選択されている場合 |
| 成功 | はい   | **サービスアカウントによるパイプラインが完了**が選択されている場合 |

イシュー[501083](https://gitlab.com/gitlab-org/gitlab/-/issues/501083)は、すべてのイベントを**すべて通知**レベルに追加することを追跡します。

#### 特定のイシュー、マージリクエスト、またはエピックの通知をサブスクライブ {#subscribe-to-notifications-for-a-specific-issue-merge-request-or-epic}

特定のイシュー、マージリクエスト、またはエピックの通知を切り替えるには:

1. 右側のサイドバーの上部で、次を選択します:
   - **通知オン**（{{< icon name="notifications" >}}）を選択して通知を有効にします。
   - **通知オフ**（{{< icon name="notifications-off" >}}）を選択して通知を無効にします。

#### 通知の移動 {#moved-notifications}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.5で`notifications_todos_buttons`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132678)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag] この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能フラグを有効にすると、通知とTo Doアイテムのボタンがページ右上に移動します。

通知を**オン**にすると、ディスカッションに参加していなくても、更新ごとに通知を受け取るようになります。エピックで通知をオンにしても、エピックにリンクされたイシューは自動的にサブスクライブされません。

通知を**オフ**にすると、更新に関する通知の受信が停止されます。この切替をオフにすると、このイシュー、マージリクエスト、またはエピックに関連する更新のみからサブスクライブ解除されます。[GitLabからのすべてのメールをオプトアウトする方法](#opt-out-of-all-gitlab-emails)をご覧ください。

### 特定のイベントを無効にする {#disable-specific-events}

`always sent` GitLab Self-ManagedインスタンスとGitLab Dedicatedで通知のセキュリティメールを無効にするには、インスタンスの管理者が個々の[バックグラウンドジョブ](../../administration/maintenance_mode/_index.md#background-jobs)を無効にできます。

例: 

- `personal_access_tokens_expiring_worker`
- `personal_access_tokens_expired_notification_worker`
- `ssh_keys_expiring_soon_notification_worker`
- `ssh_keys_expired_notification_worker`
- `send_recurring_notifications_worker`
- `deploy_tokens_expiring_worker`
- `members_expiring_worker`

## 不明なサインインに関する通知 {#notifications-for-unknown-sign-ins}

{{< history >}}

- サインインしたユーザーのフルネームとユーザー名を一覧表示する機能は、GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/225183)されました。
- 地理的な場所は、GitLab 17.5で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/296128)されました。

{{< /history >}}

> [!note]この機能は、GitLab Self-Managedインスタンスではデフォルトで有効になっています。管理者は、UIの[サインインの制限](../../administration/settings/sign_in_restrictions.md#email-notification-for-unknown-sign-ins)セクションからこの機能を無効にできます。この機能は、GitLab.comで常に有効になっています。

ユーザーが以前に不明なIPアドレスまたはデバイスから正常にサインインすると、GitLabはメールでユーザーに通知します。このようにして、GitLabは潜在的に悪意のあるまたは不正なサインインをユーザーに事前に警告します。この通知メールには以下が含まれます。

- ホスト名。
- ユーザーの名前とユーザー名。
- IPアドレス。
- 地理的な場所。
- サインインの日時。

GitLabは、既知のサインインを識別するためにいくつかのメソッドを使用します。通知メールが送信されるには、すべてのメソッドが失敗する必要があります。

- 最終サインインIP: 現在のサインインIPアドレスは、最終サインインIPアドレスと照合されます。
- 現在のアクティブセッション: ユーザーが同じIPアドレスからの既存アクティブセッションを持っている場合。[アクティブセッション](active_sessions.md)を参照してください。
- Cookie: 正常なサインインの後、暗号化されたCookieがブラウザに保存されます。このCookieは、最後の正常なサインインから14日後に期限切れになるように設定されています。

## 誤った確認コードを使用したサインインの試行に関する通知 {#notifications-for-attempted-sign-ins-using-incorrect-verification-codes}

{{< history >}}

- GitLab 15.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/374740)。

{{< /history >}}

GitLabは、誤った2要素認証（2FA）コードを使用してアカウントにサインインしようとする試みを検出した場合、メール通知を送信します。これにより、悪意のある第三者がユーザー名とパスワードにアクセスし、2FAをブルートフォース攻撃しようとしていることを検出できます。

## デザインに関する通知 {#notifications-on-designs}

誰かがデザインにコメントすると、参加者にメール通知が送信されます。

参加者は次のとおりです:

- デザインの作成者（異なる作成者が異なるバージョンのデザインをアップロードした場合、複数の人がいる可能性があります）。
- デザインに関するコメントの作成者。
- デザインに関するコメントで[メンション](../discussions/_index.md#mentions)されたすべてのユーザー。

## グループまたはプロジェクトのアクセス有効期限に関する通知 {#notifications-on-group-or-project-access-expiration}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/12704)されました。

{{< /history >}}

ユーザーのグループまたはプロジェクトへのアクセスが7日後に期限切れになる場合、GitLabはメール通知を送信します。これにより、グループまたはプロジェクトのメンバーは、必要に応じてアクセス期間を延長するように促されます。

## すべてのGitLabメールをオプトアウトする {#opt-out-of-all-gitlab-emails}

メール通知をもう受信したくない場合は、次の手順を実行します。

1. 右上隅でアバターを選択します。
1. **設定**を選択します。
1. 左側のサイドバーで、**通知**を選択します。
1. **グローバル通知レベル**を**無効**に設定します。
1. **自身のアクティビティーに関する通知を受信する**チェックボックスをオフにします。
1. グループまたはプロジェクトに所属している場合は、通知設定を**グローバル**または**無効**に設定します。

GitLab Self-ManagedインスタンスとGitLab Dedicatedのインスタンスでは、これを実行した後でも、特定のイベント通知が送信されます:

- インスタンスの管理者は[引き続きメールを送信できます](../../administration/email_from_gitlab.md)
- [通知イベント](#notification-events)は`always sent`です

## 通知メールをサブスクライブ解除する {#unsubscribe-from-notification-emails}

リソース単位（たとえば、特定のイシュー）でGitLabからの通知メールをサブスクライブ解除できます。

### サブスクライブ解除リンクを使用する {#using-the-unsubscribe-link}

GitLabからのすべての通知メールの下部に、サブスクライブ解除リンクが含まれています。

サブスクライブ解除するには:

1. メールのサブスクライブ解除リンクを選択します。
1. ブラウザでGitLabにサインインしている場合は、すぐにサブスクライブ解除されます。
1. サインインしていない場合は、アクションを確認する必要があります。

### メールクライアントまたはその他のソフトウェアを使用する {#using-an-email-client-or-other-software}

メールクライアントは、GitLabからのメールを表示するときに**配信停止**ボタンを表示する場合があります。サブスクライブ解除するには、このボタンを選択します。

GitLabからの通知メールには、特別なヘッダーが含まれています。これらのヘッダーにより、サポートされているメールクライアントおよびその他のソフトウェアがユーザーのサブスクライブを自動的に解除できるようになります。次に例を示します。

```plaintext
List-Unsubscribe: <https://gitlab.com/-/sent_notifications/[REDACTED]/unsubscribe>,<mailto:incoming+[REDACTED]-unsubscribe@incoming.gitlab.com>
List-Unsubscribe-Post: List-Unsubscribe=One-Click
```

`List-Unsubscribe`ヘッダーには次の2つのエントリがあります。

- ソフトウェアが`POST`リクエストを送信するためのリンク。このアクションは、ユーザーをリソースから直接サブスクライブ解除します。このリンクに`GET`リクエストを送信すると、サブスクライブ解除する代わりに確認ダイアログが表示されます。
- ソフトウェアがサブスクライブ解除メールを送信するためのメールアドレス。メールの内容は無視されます。

メールによる登録解除は、メールによる返信と同じ2年間の[保持ポリシー](../../administration/reply_by_email.md#retention-policy-for-notifications)の対象となります。

## メールのフィルタリングに使用できるメールヘッダー {#email-headers-you-can-use-to-filter-email}

通知メールメッセージには、GitLab固有のヘッダーが含まれます。通知をより適切に管理するために、これらのヘッダーの内容に基づいて通知メールをフィルタリングできます。

たとえば、マージリクエストまたはイシューが割り当てられている特定のプロジェクトからのすべてのメールをフィルタリングできます。

次の表に、GitLab固有のすべてのメールヘッダーを示します。

| ヘッダー                        | 説明 |
|-------------------------------|-------------|
| `List-Id`                     | RFC 2919メーリングリスト識別子のプロジェクトのパス。フィルターを使用して組織のメールを整理するために使用できます。 |
| `X-GitLab-(Resource)-ID`      | 通知の対象となるリソースのID。たとえば、リソースは、`Issue`、`MergeRequest`、`Commit`、またはその他のこのようなリソースです。 |
| `X-GitLab-(Resource)-State`   | 通知の対象となるリソースの状態。たとえば、リソースは、`Issue`や`MergeRequest`などです。値は、`opened`、`closed`、`merged`、`locked`などです。GitLab 16.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130967)。 |
| `X-GitLab-ConfidentialIssue`  | 通知のイシューの機密性を示すブール値。GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/222908)されました。 |
| `X-GitLab-Discussion-ID`      | コメントの通知メールで示される、コメントが属するスレッドのID。 |
| `X-GitLab-Group-Id`           | グループのID。[エピック](../group/epics/_index.md)の通知メールにのみ存在します。 |
| `X-GitLab-Group-Path`         | グループのパス。[エピック](../group/epics/_index.md)の通知メールにのみ存在します。 |
| `X-GitLab-NotificationReason` | 通知の理由。[可能な値を参照](#x-gitlab-notificationreason)してください。 |
| `X-GitLab-Pipeline-Id`        | パイプラインの通知メールで示される、通知の対象となるパイプラインのID。 |
| `X-GitLab-Project-Id`         | プロジェクトのID。 |
| `X-GitLab-Project-Path`       | プロジェクトのパス。 |
| `X-GitLab-Project`            | 通知が属するプロジェクトの名前。 |
| `X-GitLab-Reply-Key`          | メールによる返信をサポートする一意のトークン。 |

### X-GitLab-NotificationReason {#x-gitlab-notificationreason}

`X-GitLab-NotificationReason`ヘッダーには、通知の理由が含まれています。値は次のいずれかであり、優先度順に並べられています。

- `own_activity`
- `assigned`
- `review_requested`
- `mentioned`
- `subscribed`

通知の理由は、通知メールのフッターにも含まれています。たとえば、理由が`assigned`のメールには、フッターに次の文が含まれています。

```plaintext
You are receiving this email because you have been assigned an item on <configured GitLab hostname>.
```

#### オンコールアラート通知 {#on-call-alerts-notifications}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[オンコールアラート](../../operations/incident_management/oncall_schedules.md)通知メールには、[アラートの](../../operations/incident_management/alerts.md)次のいずれかの状態が含まれています。

- `alert_triggered`
- `alert_acknowledged`
- `alert_resolved`
- `alert_ignored`

#### インシデントエスカレーション通知 {#incident-escalation-notifications}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[インシデントエスカレーション](../../operations/incident_management/escalation_policies.md)通知メールには、[インシデントの](../../operations/incident_management/incidents.md)次のいずれかの状態が含まれています。

- `incident_triggered`
- `incident_acknowledged`
- `incident_resolved`
- `incident_ignored`

`X-GitLab-NotificationReason`ヘッダーに含めるイベントのリストを拡張することについては、[イシュー20689](https://gitlab.com/gitlab-org/gitlab/-/issues/20689)で追跡されています。

## トラブルシューティング {#troubleshooting}

### 通知の受信者のリストをプルする {#pull-a-list-of-recipients-for-notifications}

プロジェクトから通知を受信する受信者のリストをプルする場合は（主にカスタム通知のトラブルシューティングに使用）、Railsコンソールで`sudo gitlab-rails c`を実行し、プロジェクト名を必ず更新してください。

```plaintext
project = Project.find_by_full_path '<project_name>'
merge_request = project.merge_requests.find_by(iid: 1)
current_user = User.first
recipients = NotificationRecipients::BuildService.build_recipients(merge_request, current_user, action: "push_to"); recipients.count
recipients.each { |notify| puts notify.user.username }
```

### 存在しない失敗したパイプラインに関する通知 {#notifications-about-failed-pipeline-that-doesnt-exist}

存在しなくなった失敗したパイプラインに関する通知（メールまたはSlack経由）を受信する場合は、メッセージをトリガーした可能性のある重複したGitLabインスタンスがないか再確認してください。

### メール通知は有効になっているが、受信されない {#email-notifications-are-enabled-but-not-received}

GitLabでメール通知を有効にしたのに、ユーザーが期待どおりに通知を受信しない場合は、メールプロバイダーがGitLabインスタンスからのメールをブロックしていないことを確認してください。多くのメールプロバイダー（Outlookなど）は、あまり知られていないSelf-ManagedメールサーバーのIPアドレスからのメールをブロックします。確認するには、インスタンスのSMTPサーバーから直接メールを送信してみてください。たとえば、Sendmailからのテストメールは次のようになります。

```plaintext
# (echo subject: test; echo) | $(which sendmail) -v -Am -i <valid email address>
```

メールプロバイダーがメッセージをブロックしている場合は、次のような出力が表示される場合があります（メールプロバイダーとSMTPサーバーによって異なります）。

```plaintext
Diagnostic-Code: smtp; 550 5.7.1 Unfortunately, messages from [xx.xx.xx.xx]
weren't sent. For more information, please go to
http://go.microsoft.com/fwlink/?LinkID=526655 (http://go.microsoft.com/fwlink/?LinkID=526655) AS(900)
```

通常、この問題は、SMTPサーバーのIPアドレスをメールプロバイダーの許可リストに追加することで解決できます。手順については、メールプロバイダーのドキュメントを確認してください。
