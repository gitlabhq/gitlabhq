---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: サービスデスクを設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

デフォルトでは、サービスデスクは新規プロジェクトでアクティブになっています。アクティブでない場合は、プロジェクトの設定でアクティブにできます。

前提要件: 

- プロジェクトのメンテナー以上のロールを持っている必要があります。
- GitLabセルフマネージドでは、GitLabインスタンスの[受信メールを設定](../../../administration/incoming_email.md#set-it-up)する必要があります。[メール](../../../administration/incoming_email.md#email-sub-addressing)のサブアドレス指定を使用する必要がありますが、[すべてをキャッチするメールボックス](../../../administration/incoming_email.md#catch-all-mailbox)を使用することもできます。これを行うには、管理者アクセス権が必要です。
- プロジェクトの[イシュー](../settings/_index.md#configure-project-features-and-permissions)イシュートラッカーを有効にする必要があります。

プロジェクトでサービスデスクを有効にするには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **サービスデスクを有効にする**トグルをオンにします。
1. オプション。フィールドに入力します。
   - サービスデスクのメールアドレスに[サフィックスを追加](#configure-a-suffix-for-service-desk-alias-email)します。
   - 以下の**全てのサービスデスクのイシューに追加するテンプレート**リストが空の場合、リポジトリに[説明テンプレート](../description_templates.md)を作成します。
1. **変更を保存**を選択します。

これで、このプロジェクトでサービスデスクが有効になりました。**サービスデスクで使用するメールアドレス**の下に表示されているアドレスに誰かがメールを送信すると、GitLabはそのメールの内容を含む機密性の高いイシューを作成します。

## サービスデスクの用語集 {#service-desk-glossary}

この用語集では、サービスデスクに関連する用語の定義を提供します。

| 用語                                             | 定義 |
|--------------------------------------------------|------------|
| [外部参加者](external_participants.md) | メールでのみイシューまたはサービスデスクのサービスデスクチケットを操作できるGitLabアカウントを持たないユーザー。 |
| リクエスタ                                        | サービスデスクのサービスデスクチケットを作成した、または[`/convert_to_ticket`クイックアクション](using_service_desk.md#create-a-service-desk-ticket-in-gitlab-ui)を使用してリクエスタとして追加された外部参加者。 |

## プロジェクトのセキュリティを強化する {#improve-your-projects-security}

サービスデスクプロジェクトのセキュリティを強化するには、以下を行う必要があります:

- サービスデスクのメールアドレスをエイリアスの背後に配置して、後で変更できるようにします。
- GitLabインスタンスで[Akismetを有効にする](../../../integration/akismet.md)と、このサービスデスクにアンチスパムチェックが追加されます。ブロックされていないメールアンチスパムにより、多くのスパムイシューが作成される可能性があります。

## 外部参加者に送信されるメールをカスタマイズする {#customize-emails-sent-to-external-participants}

{{< history >}}

- `UNSUBSCRIBE_URL`、`SYSTEM_HEADER`、`SYSTEM_FOOTER`、および`ADDITIONAL_TEXT`のプレースホルダーはGitLab 15.9で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/285512)。
- `%{ISSUE_DESCRIPTION}` GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/223751)されました。
- `%{ISSUE_URL}`はGitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/408793)されました。

{{< /history >}}

外部参加者にメールが送信されるのは、次の場合です:

- リクエスタがサービスデスクにメールを送信して、新しいサービスデスクチケットを送信した場合。
- 外部参加者がサービスデスクのサービスデスクチケットに追加された場合。
- 新しいパブリックコメントがサービスデスクのサービスデスクチケットに追加された場合。
  - コメントを編集しても、新しいメールは送信されません。

これらのメールメッセージの本文は、サービスデスクのメールテンプレートでカスタマイズできます。テンプレートには、[GitLab Flavored Markdown](../../markdown.md)と[一部のHTMLタグ](../../markdown.md#inline-html)を含めることができます。たとえば、組織のブランドガイドラインに従って、ヘッダーとフッターを含むようにメールをフォーマットできます。サービスデスクのサービスデスクチケットまたはGitLabインスタンスに固有の動的コンテンツを表示するために、次のプレースホルダーを含めることもできます。

| プレースホルダー            | `thank_you.md`および`new_participant` | `new_note.md`          | 説明 |
|------------------------|--------------------------------------|------------------------|-------------|
| `%{ISSUE_ID}`          | {{< icon name="check-circle" >}}可               | {{< icon name="check-circle" >}}対応 | チケットIID。 |
| `%{ISSUE_PATH}`        | {{< icon name="check-circle" >}}可               | {{< icon name="check-circle" >}}対応 | チケットIIDが追加されたプロジェクトパス。 |
| `%{ISSUE_URL}`         | {{< icon name="check-circle" >}}可               | {{< icon name="check-circle" >}}対応 | チケットのURL。外部参加者がチケットを表示できるのは、プロジェクトがパブリックで、チケットが機密でない場合のみです（サービスデスクのチケットはデフォルトで機密になっています）。 |
| `%{ISSUE_DESCRIPTION}` | {{< icon name="check-circle" >}}可               | {{< icon name="check-circle" >}}対応 | チケットの説明。ユーザーが説明を編集した場合、その説明には、外部参加者に配信することを意図していない機密情報が含まれている可能性があります。このプレースホルダーは慎重に使用し、説明を一切変更しない場合、またはチームがテンプレートデザインを認識している場合にのみ使用するのが理想的です。 |
| `%{UNSUBSCRIBE_URL}`   | {{< icon name="check-circle" >}}可               | {{< icon name="check-circle" >}}対応 | 購読解除URL。[外部参加者として登録解除](external_participants.md#unsubscribing-from-notification-emails)する方法と、[GitLabからの通知メールで購読解除ヘッダーを使用](../../profile/notifications.md#using-an-email-client-or-other-software)する方法について説明します。 |
| `%{NOTE_TEXT}`         | {{< icon name="dotted-circle" >}}不可               | {{< icon name="check-circle" >}}対応 | ユーザーがサービスデスクチケットに追加した新しいコメント。メールの受信者がコメントの内容を読み取れるようにするには、テンプレートに`new_note.md`を含めるように注意してください。そうしないと、外部参加者はサービスデスクのサービスデスクチケットの更新を一切確認できない可能性があります。 |

### サンキューメール {#thank-you-email}

リクエスタがサービスデスクを介してイシューを送信すると、GitLabは**thank you email**（サンキューメール）を送信します。追加の設定がない場合、GitLabはデフォルトのサンキューメールを送信します。

カスタムサンキューメールテンプレートを作成するには、次の手順を実行します:

1. リポジトリの`.gitlab/service_desk_templates/`ディレクトリに、`thank_you.md`という名前のファイルを作成します。
1. マークダウンファイルにテキスト、[GitLab Flavored Markdown](../../markdown.md) 、[一部の選択されたHTMLタグ](../../markdown.md#inline-html)、およびプレースホルダーを設定して、サービスデスクのリクエスタへの返信をカスタマイズします。

### 新しい参加者メール {#new-participant-email}

{{< history >}}

- `new_participant`メールは、GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/299261)されました。

{{< /history >}}

[外部参加者](external_participants.md)がチケットに追加されると、GitLabは会話の一部であることを知らせる**new participant email**（新しい参加者メール）を送信します。追加の設定がない場合、GitLabはデフォルトの新しい参加者メールを送信します。

カスタムの新しい参加者メールテンプレートを作成するには、次の手順を実行します:

1. リポジトリの`.gitlab/service_desk_templates/`ディレクトリに、`new_participant.md`という名前のファイルを作成します。
1. マークダウンファイルにテキスト、[GitLab Flavored Markdown](../../markdown.md) 、[一部の選択されたHTMLタグ](../../markdown.md#inline-html)、およびプレースホルダーを設定して、サービスデスクのリクエスタへの返信をカスタマイズします。

### 新しいノートメール {#new-note-email}

サービスデスクのサービスデスクチケットに新しいパブリックコメントがある場合、GitLabは**new note email**（新しいノートメール）を送信します。追加の設定がない場合、GitLabはコメントの内容を送信します。

メールのブランドを維持するために、カスタムの新しいノートメールテンプレートを作成できます。これを行うには、次の手順に従います:

1. リポジトリの`.gitlab/service_desk_templates/`ディレクトリに、`new_note.md`という名前のファイルを作成します。
1. マークダウンファイルにテキスト、[GitLab Flavored Markdown](../../markdown.md) 、[一部の選択されたHTMLタグ](../../markdown.md#inline-html)、およびプレースホルダーを設定して、新しいノートメールをカスタマイズします。メールの受信者がコメントの内容を読み取れるようにするには、テンプレートに`%{NOTE_TEXT}`を必ず含めてください。

### インスタンス全体のメールヘッダー、フッター、および追加のテキスト {#instance-wide-email-header-footer-and-additional-text}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/344819)されました。

{{< /history >}}

インスタンスの管理者は、ヘッダー、フッター、または追加のテキストをGitLabインスタンスに追加して、GitLabから送信されるすべてのメールに適用できます。カスタム`thank_you.md`、`new_participant`、または`new_note.md`を使用している場合は、このコンテンツを含めるために、`%{SYSTEM_HEADER}`、`%{SYSTEM_FOOTER}`、または`%{ADDITIONAL_TEXT}`をテンプレートに追加します。

詳細については、[システムヘッダーとフッターメッセージ](../../../administration/appearance.md#add-system-header-and-footer-messages)および[カスタムの追加テキスト](../../../administration/settings/email.md#custom-additional-text)を参照してください。

## サービスデスクチケットのカスタムテンプレートを使用する {#use-a-custom-template-for-service-desk-tickets}

[説明テンプレート](../description_templates.md#create-a-description-template)を**per project**（プロジェクトごと）に1つ選択して、新しいサービスデスクチケットのすべての説明に追加できます。

説明テンプレートは、さまざまなレベルで設定できます:

- [インスタンス](../description_templates.md#set-instance-level-description-templates)全体。
- 特定の[グループまたはサブグループ](../description_templates.md#set-group-level-description-templates)。
- 特定の[プロジェクト](../description_templates.md#set-a-default-template-for-merge-requests-and-issues)。

テンプレートは継承されます。たとえば、プロジェクトでは、インスタンスまたはプロジェクトの親グループに設定されているテンプレートにもアクセスできます。

前提要件: 

- [説明テンプレートを作成](../description_templates.md#create-a-description-template)しておく必要があります。

サービスデスクでカスタムの説明テンプレートを使用するには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **全てのサービスデスクのイシューに追加するテンプレート**ドロップダウンリストから、テンプレートを検索または選択します。

## サポートボットのユーザー {#support-bot-user}

舞台裏では、サービスデスクは特別なサポートボットのユーザーがイシューを作成することで機能します。このユーザーは、[請求対象ユーザー](../../../subscriptions/manage_users_and_seats.md#criteria-for-non-billable-users)ではないため、ライセンス制限数にはカウントされません。

GitLab 16.0以前では、サービスデスクのメールから生成されたコメントは、`GitLab Support Bot`を作成者として表示します。[GitLab 16.1以降](https://gitlab.com/gitlab-org/gitlab/-/issues/226995)では、これらのコメントにはメールを送信したユーザーのメールが表示されます。この機能は、GitLab 16.1以降に作成されたコメントにのみ適用されます。

### サポートボットの表示名を変更する {#change-the-support-bots-display-name}

サポートボットのユーザーの表示名を変更できます。サービスデスクから送信されたメールには、`From`ヘッダーにこの名前が含まれています。デフォルトの表示名は`GitLab Support Bot`です。

カスタムメール表示名を編集するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **メールの表示名**の下に、新しい名前を入力します。
1. **変更を保存**を選択します。

## デフォルトのチケット表示レベル {#default-ticket-visibility}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/33091)。

{{< /history >}}

新しいチケットはデフォルトで機密性が高いため、少なくともプランナーロールを持つプロジェクトメンバーのみがそれらを表示できます。

プライベートプロジェクトおよび内部プロジェクトでは、新しいチケットがデフォルトで機密でなくなり、プロジェクトメンバーであれば誰でも閲覧できるようにGitLabを設定できます。

新しいチケットは常にデフォルトで機密であるため、パブリックプロジェクトではこの設定は使用できません。

前提要件: 

- プロジェクトのメンテナー以上のロールを持っている必要があります。

この設定を無効にするには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **デフォルトでは、新規チケットは非公開です**チェックボックスをオフにします。
1. **変更を保存**を選択します。

## 外部参加者がコメントした場合にイシューを再度開く {#reopen-issues-when-an-external-participant-comments}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/8549)。

{{< /history >}}

外部参加者がメールでイシューに新しいコメントを追加した場合に、クローズされたイシューを再度開くようにGitLabを設定できます。これにより、イシューの割り当て先をメンションし、To-Doアイテムを作成する内部コメントも追加されます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>チュートリアルについては、[短いショーケースビデオ](https://youtu.be/163wDM1e43o)をご覧ください。
<!-- Video published on 2023-12-12 -->

前提要件: 

- プロジェクトのメンテナー以上のロールを持っている必要があります。

この設定を有効にするには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **Reopen issues on a new note from an external participant**（外部参加者からの新しいノートでイシューを再度開く）チェックボックスを選択します。
1. **変更を保存**を選択します。

## カスタムメールアドレス {#custom-email-address}

{{< details >}}

- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 16.3で`service_desk_custom_email`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/329990)されました。デフォルトでは無効になっています。
- GitLab 16.4の[GitLab.comとGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/387003)。
- SMTP認証方法を選択する機能は、GitLab 16.6で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/429680)。
- GitLab 16.7で[機能フラグ`service_desk_custom_email`](https://gitlab.com/gitlab-org/gitlab/-/issues/387003)は削除されました。
- GitLabセルフマネージドでのSMTPホストで許可されているローカルネットワークは、GitLab 16.7で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/435206)。

{{< /history >}}

サポート通信の送信者として表示するカスタムメールアドレスを設定します。認識されているドメインを使用して、ブランドアイデンティティを維持し、サポートリクエスタに信頼感を植え付けます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[短いショーケースビデオ](https://youtu.be/_moD5U3xcQs)をご覧ください。
<!-- Video published on 2023-09-12 -->

この機能は[ベータ版](../../../policy/development_stages_support.md#beta)です。ベータ機能は本番環境に対応していませんが、リリース前に大幅に変更される可能性は低いです。ユーザーはベータ機能を試して、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/416637)でフィードバックを提供することをお勧めします。

### 前提要件 {#prerequisites}

プロジェクトごとに1つのサービスデスクのカスタムメールアドレスを使用でき、インスタンス全体で一意である必要があります。

使用するカスタムメールアドレスは、次のすべての要件を満たしている必要があります:

- メール転送をセットアップできます。
- 転送されたメールは、元の`From`ヘッダーを保持します。
- サービスプロバイダーは、サブアドレス指定をサポートする必要があります。メールアドレスは、ローカル部分（`@`の前にあるすべて）とドメイン部分で構成されます。

  メールサブアドレス指定を使用すると、`+`記号を追加し、その後に任意のテキストをローカル部分に追加して、メールアドレスの一意のバリエーションを作成できます。メールアドレス`support@example.com`を指定して、`support+1@example.com`にメールを送信して、サブアドレス指定がサポートされているかどうかを確認します。このメールはメールボックスに表示されます。
- SMTP認証情報が必要です（理想的には、アプリパスワードを使用する必要があります）。ユーザー名とパスワードは、256ビットキーを持つAdvanced Encryption Standard（AES）を使用してデータベースに保存されます。
- **SMTPホスト**は、GitLabインスタンス（GitLabセルフマネージドの場合）またはパブリックインターネット（GitLab.comの場合）のネットワークから解決できる必要があります。
- プロジェクトのメンテナー以上のロールを持っている必要があります。
- サービスデスクは、プロジェクト用に設定する必要があります。

### カスタムメールアドレスを設定する {#configure-a-custom-email-address}

独自のメールアドレスを使用してサービスデスクのメールを送信する場合は、カスタムメールアドレスを設定して確認します。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開し、**カスタムメールアドレスを設定**セクションを見つけます。
1. このプロジェクトに表示されているサービスデスクのアドレスをメモし、メールプロバイダー（たとえば、Gmail）を使用して、カスタムメールアドレスからサービスデスクのアドレスへのメール転送をセットアップします。
1. GitLabに戻り、フィールドに入力します。
1. **Save & test connection**（接続の保存とテスト）を選択します。

設定が保存され、カスタムメールアドレスの検証がトリガーされます。

#### 検証 {#verification}

1. 設定が完了すると、すべてのプロジェクトオーナーと、カスタムメールの設定を保存した管理者は、通知メールを受信します。
1. 指定されたSMTP認証情報を使用して、検証メールがカスタムメールアドレス（サブアドレス指定部分を含む）に送信されます。このメールには、検証トークンが含まれています。メール転送が正しくセットアップされ、すべての前提条件が満たされると、メールはサービスデスクのアドレスに転送され、GitLabによってインジェストされます。GitLabは次の条件を確認します:
   1. GitLabは、SMTP認証情報を使用してメールを送信できます。
   1. サブアドレス指定がサポートされています（`+verify`サブアドレス指定部分を使用）。
   1. `From`ヘッダーは転送後に保持されます。
   1. 検証トークンが正しい。
   1. メールは30分以内に受信されます。

通常、プロセスには数分しかかかりません。

認証をいつでもキャンセルするか、認証に失敗した場合は、**カスタムメールをリセット**を選択します。設定ページがそれに応じて更新され、認証の現在の状態が反映されます。SMTP認証情報が削除され、設定を再度開始できます。

失敗時と成功時に、すべてのプロジェクトオーナーと検証プロセスをトリガーしたユーザーは、検証結果を含む通知メールを受信します。検証に失敗した場合、メールには理由の詳細も記載されています。

検証が成功した場合、カスタムメールアドレスを使用する準備ができています。カスタムメールアドレスでサービスデスクのメールの送信を有効にできるようになりました。

#### 設定のトラブルシューティング {#troubleshooting-your-configuration}

カスタムメールを設定するときに、次の問題が発生する可能性があります。

##### 無効な認証情報 {#invalid-credentials}

無効な認証情報が使用されたことを示すエラーが表示される場合があります。

これは、SMTPサーバーが認証に失敗したことを返す場合に発生します。

この問題を解決するには、次のようにします:

1. SMTP認証情報、特にユーザー名とパスワードを確認します。
1. GitLabは、SMTPサーバーがサポートする認証方法を自動的に選択できない場合があります。次のいずれかの操作を行います:
   - 使用可能な認証方法（**プレーン**、**ログイン**、および**CRAM-MD5**）を試してください。
   - [`swaks`コマンドラインツール](https://www.jetmore.org/john/code/swaks/)を使用して、SMTPサーバーがサポートする認証方法を確認します:

     1. 認証情報を使用して次のコマンドを実行し、`250-AUTH`で始まる行を探します:

        ```shell
        swaks --to user@example.com \
              --from support@example.com \
              --auth-user support@example.com \
              --server smtp@example.com:587 \
              -tls-optional \
              --auth-password your-app-password
        ```

     1. カスタムメール設定フォームで、サポートされている認証方法のいずれかを選択します。

##### 転送先が正しくありません {#incorrect-forwarding-target}

転送先が正しくないことを示すエラーが表示される場合があります。

これは、確認メールが、カスタムメール設定フォームに表示されるプロジェクト固有のサービスデスクアドレスとは異なるメールアドレスに転送された場合に発生します。

`incoming_email`から生成されたサービスデスクアドレスを使用する必要があります。`service_desk_email`から生成された追加のサービスデスクエイリアスアドレスへの転送は、すべてのメールによる返信機能をサポートしていないため、サポートされていません。

この問題を解決するには、次のようにします:

1. メールの転送先となる正しいメールアドレスを見つけます。次のいずれかの操作を行います:
   - すべてのプロジェクトオーナーと、検証プロセスをトリガーしたユーザーが受信する検証結果メールのアドレスをメモしておきます。
   - カスタムメール設定フォームの**メールを転送するためのサービスデスクのメールアドレス**入力からアドレスをコピーします。
1. すべてのメールをカスタムメールアドレスから正しいターゲットメールアドレスに転送します。

### カスタムメールアドレスを有効または無効にする {#enable-or-disable-the-custom-email-address}

カスタムメールアドレスが検証された後、管理者は、カスタムメールアドレスでサービスデスクメールの送信を有効または無効にできます。

カスタムメールアドレスを**enable**（有効）にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開する。
1. **Enable custom email**（カスタムメールを有効にする） トグルをオンにします。外部の参加者へのサービスデスクメールは、SMTP認証情報を使用して送信されます。

カスタムメールアドレスを**disable**（無効）にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開する。
1. **Enable custom email**（カスタムメールを有効にする） トグルをオフにします。メール転送を設定したため、カスタムメールアドレス宛てのメールは引き続き処理され、プロジェクトのサービスデスクチケットとして表示されます。

   外部の参加者へのサービスデスクメールは、GitLabインスタンスのデフォルトの送信メール設定を使用して送信されるようになりました。

### カスタムメール設定を変更または削除する {#change-or-remove-custom-email-configuration}

カスタムメール設定を変更するには、リセットして削除し、もう一度カスタムメールを設定する必要があります。

プロセスの任意の手順で設定をリセットするには、**カスタムメールをリセット**を選択します。認証情報がデータベースから削除されます。

### カスタムメール返信先アドレス {#custom-email-reply-address}

外部の参加者は、メールでサービスデスクチケットに[返信](../../../administration/reply_by_email.md)できます。GitLabは、チケットに対応する32文字の返信キーを持つメール返信アドレスを使用します。カスタムメールが設定されている場合、GitLabはそのメールから返信アドレスを生成します。

### 独自のドメインでGoogle Workspaceを使用する {#use-google-workspace-with-your-own-domain}

独自のドメインでGoogle Workspaceを使用する場合、サービスデスクのカスタムメールアドレスを設定します。

前提要件: 

- Google Workspaceアカウントを既にお持ちである。
- テナントの新しいアカウントを作成できます。

Google Workspaceでカスタムサービスデスクメールアドレスを設定するには:

1. [Google Workspaceアカウントを設定します](#configure-a-google-workspace-account)。
1. [Google Workspaceでメール転送を設定します](#configure-email-forwarding-in-google-workspace)。
1. [Google Workspaceアカウントを使用してカスタムメールアドレスを設定します](#configure-custom-email-address-using-a-google-workspace-account)。

#### Google Workspaceアカウントを設定する {#configure-a-google-workspace-account}

まず、Google Workspaceアカウントを作成して設定する必要があります。

Google Workspaceの場合:

1. 使用するカスタムメールアドレスの新しいアカウントを作成します（例：`support@example.com`）。
1. そのアカウントにサインインし、[2要素認証](https://myaccount.google.com/u/3/signinoptions/two-step-verification)を有効にします。
1. SMTPパスワードとして使用できる[アプリパスワードを作成](https://myaccount.google.com/u/3/apppasswords)します。安全な場所に保存し、文字間のスペースを削除します。

次に、[Google Workspaceでメール転送を設定する必要があります](#configure-email-forwarding-in-google-workspace)。

#### Google Workspaceでメール転送を設定する {#configure-email-forwarding-in-google-workspace}

次の手順では、GitLabとGoogle Workspaceの間を移動する必要があります。

GitLabで、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定**>**一般**を選択します。
1. **サービスデスク**を展開する。
1. **メールを転送するためのサービスデスクのメールアドレス**の下のメールアドレスをメモします。

Google Workspaceの場合:

1. カスタムメールアカウントにサインインし、[転送とPOP/IMAP](https://mail.google.com/mail/u/0/#settings/fwdandpop)設定ページを開きます。
1. **Add a forwarding address**（転送先アドレスを追加）を選択します。
1. カスタムメールフォームからサービスデスクアドレスを入力します。
1. **次へ**を選択します。
1. 入力を確認し、**続行**を選択します。Googleはメールをサービスデスクアドレスに送信し、確認コードを要求します。

GitLabで、次の手順を実行します:

1. プロジェクトの**イシュー**に移動し、Googleからの確認メールから新しいイシューが作成されるのを待ちます。
1. イシューを開き、確認コードをメモします。
1. （オプション）イシューを削除します。

Google Workspaceの場合:

1. 確認コードを入力し、**Verify**（確認）を選択します。
1. **Forward a copy of incoming mail to**（受信メールのコピーを転送）を選択し、ドロップダウンリストからサービスデスクアドレスが選択されていることを確認します。
1. ページの下部にある**変更を保存**を選択します。

次に、サービスデスクで使用する[Google Workspaceアカウントを使用してカスタムメールアドレスを設定](#configure-custom-email-address-using-a-google-workspace-account)します。

#### Google Workspaceアカウントを使用してカスタムメールアドレスを設定する {#configure-custom-email-address-using-a-google-workspace-account}

GitLabで、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定**>**一般**を選択します。
1. **サービスデスク**を展開する、カスタムメール設定を見つけます。
1. フィールドに入力します:
   - **カスタムメールアドレス**: あなたのカスタムメールアドレス。
   - **SMTPホスト**：`smtp.gmail.com`。
   - **SMTPポート**：`587`。
   - **SMTPユーザー名**: カスタムメールアドレスが事前に入力されています。
   - **SMTPパスワード**: カスタムメールアカウント用に以前に作成したアプリパスワード。
   - **SMTP認証方法**: GitLabにサーバーがサポートする方法を選択させる（推奨）
1. **接続の保存とテスト**を選択
1. [確認プロセス](#verification)の後、[カスタムメールアドレスを有効にする](#enable-or-disable-the-custom-email-address)ことができるはずです。

### 独自のドメインでMicrosoft 365（Exchange Online）を使用する {#use-microsoft-365-exchange-online-with-your-own-domain}

{{< history >}}

- GitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/496396)されました。

{{< /history >}}

独自のドメインでMicrosoft 365（Exchange）を使用する場合、サービスデスクのカスタムメールアドレスを設定します。

前提要件: 

- Microsoft 365アカウントを既にお持ちである。
- テナントの新しいアカウントを作成できます。

Microsoft 365でカスタムサービスデスクメールアドレスを設定するには:

1. [Microsoft 365アカウントを設定します](#configure-a-microsoft-365-account)。
1. [Microsoft 365でメール転送を設定します](#configure-email-forwarding-in-microsoft-365)。
1. [Microsoft 365アカウントを使用してカスタムメールアドレスを設定します](#configure-custom-email-address-using-a-microsoft-365-account)。

#### Microsoft 365アカウントを設定する {#configure-a-microsoft-365-account}

まず、Microsoft 365アカウントを作成して設定する必要があります。このガイドでは、カスタムメールメールボックスにライセンスされたユーザーを使用します。他の設定オプションを試すこともできます。

[Microsoft 365管理センター](https://admin.microsoft.com/Adminportal/Home#/homepage)で:

1. 使用するカスタムメールアドレスの新しいアカウントを作成します（例：`support@example.com`）。
   1. **ユーザー**セクションを展開する、メニューから**アクティブなユーザー**を選択します。
   1. **Add a user**（ユーザー）を選択し、画面の指示に従います。
1. Microsoft Entra（以前はActive Directoryという）で、アカウントの2要素認証を有効にします。
1. [ユーザーがアプリのパスワードを作成できるようにする](https://learn.microsoft.com/en-us/entra/identity/authentication/howto-mfa-app-passwords)。
1. アカウントの**Authenticated SMTP**（認証済みSMTP）を有効にします。
   1. リストからアカウントを選択します。
   1. ドロワーで、**Mail**（メール）を選択します。
   1. **Email apps**（メールアプリ） の下で**Manage email apps**（メールアプリ）の管理] を選択します。
   1. **Authenticated SMTP**（認証済みSMTP）をチェックし、**変更を保存**を選択します。
1. 全体的なExchangeオンライン設定によっては、以下を設定する必要がある場合があります:
   1. Azure Cloudシェルを使用して、SMTPクライアント認証を許可します:

      ```powershell
      Set-TransportConfig -SmtpClientAuthenticationDisabled $false
      ```

   1. Azure Cloudシェルを使用して、[SMTP認証を使用するレガシーTLSクライアント](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/opt-in-exchange-online-endpoint-for-legacy-tls-using-smtp-auth)を許可します:

      ```powershell
      Set-TransportConfig -AllowLegacyTLSClients $true
      ```

   1. 外部受信者に転送する場合は、[外部メール転送](https://learn.microsoft.com/en-gb/defender-office-365/outbound-spam-policies-external-email-forwarding)を有効にする方法に関するこのガイドを参照してください。また、それを必要とするユーザーに対してのみ外部受信者への転送を許可するために、[送信アンチスパムポリシーを作成](https://security.microsoft.com/antispam)することもできます。
1. そのアカウントにサインインし、2要素認証を有効にします。
   <!-- vale gitlab_base.SubstitutionWarning = NO -->
   1. 右上隅のメニューから**View account**（アカウントの表示） を選択し、[**Security Info**（セキュリティ情報）](https://mysignins.microsoft.com/security-info)に移動します。
   <!-- vale gitlab_base.SubstitutionWarning = YES -->
   1. **Add sign-in method**（サインイン方法を追加）を選択し、自分に適した方法（認証アプリ、電話、またはメール）を選択します。
   1. 画面の指示に従ってください。
<!-- vale gitlab_base.SubstitutionWarning = NO -->
1. [**Security Info**（セキュリティ情報）](https://mysignins.microsoft.com/security-info)ページで、SMTPパスワードとして使用できるアプリパスワードを作成します。
<!-- vale gitlab_base.SubstitutionWarning = YES -->
   1. **Add sign-in method**（サインイン方法を追加）を選択し、ドロップダウンリストから**App password**（アプリのパスワード）を選択します。
   1. `GitLab SD`などのアプリパスワードにわかりやすい名前を設定します。
   1. **次へ**を選択します。
   1. 表示されたパスワードをコピーし、安全な場所に保管します。
   1. オプション。[`swaks`コマンドラインツール](https://www.jetmore.org/john/code/swaks/)を使用して、SMTPを使用してメールを送信できることを確認します。
   1. 認証情報を使用して次のコマンドを実行し、アプリパスワードを`auth-password`として使用します:

      ```shell
      swaks --to your-email@example.com \
            --from custom-email@example.com \
            --auth-user custom-email@example.com \
            --server smtp.office365.com:587 \
            -tls-optional \
            --auth-password <your_app_password>
      ```

次に、[Microsoft 365でメール転送を設定する必要があります](#configure-email-forwarding-in-microsoft-365)。

#### Microsoft 365でメール転送を設定する {#configure-email-forwarding-in-microsoft-365}

次の手順では、GitLabとMicrosoft 365管理センターの間を移動する必要があります。

GitLabで、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定**>**一般**を選択します。
1. **サービスデスク**を展開する。
1. サブアドレス部分なしで、**メールを転送するためのサービスデスクのメールアドレス**の下のメールアドレスをメモします。

   受信者のアドレスにサブアドレス（GitLabによって生成された返信アドレスなど）が含まれており、転送メールアドレスにサブアドレス（**メールを転送するためのサービスデスクのメールアドレス**）が含まれている場合、メールは転送されません。

   たとえば、`incoming+group-project-12346426-issue-@incoming.gitlab.com`は`incoming@incoming.gitlab.com`になります。Exchange onlineは転送後も`To`ヘッダーにカスタムメールアドレスを保持し、GitLabはカスタムメールアドレスに基づいて正しいプロジェクトを割り当てることができるため、問題ありません。

[Microsoft 365管理センター](https://admin.microsoft.com/Adminportal/Home#/homepage)で:

<!-- vale gitlab_base.SubstitutionWarning = NO -->
1. **ユーザー**セクションを展開する、メニューから**アクティブなユーザー**を選択します。
<!-- vale gitlab_base.SubstitutionWarning = YES -->
1. リストからカスタムメールに使用するアカウントを選択します。
1. ドロワーで、**Mail**（メール）を選択します。
1. **Email forwarding**（メール転送） の下で**Manage email forwarding**（メール転送の管理） を選択します。
1. **Forward all emails sent to this mailbox**（このメールボックスに送信されたすべてのメールを転送）をチェックします。
1. サブアドレス部分なしで、**Forwarding email address**（メール転送先メールアドレス） のカスタムメールフォームからサービスデスクアドレスを入力します。
1. **変更を保存**を選択します。

次に、サービスデスクで使用するために、[Microsoft 365アカウントを使用してカスタムメールアドレスを設定する](#configure-custom-email-address-using-a-microsoft-365-account)。

#### Microsoft 365アカウントを使用してカスタムメールアドレスを設定する {#configure-custom-email-address-using-a-microsoft-365-account}

GitLabで、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定**>**一般**を選択します。
1. **サービスデスク**を展開する、カスタムメール設定を見つけます。
1. フィールドに入力します:
   - **カスタムメールアドレス**: あなたのカスタムメールアドレス。
   - **SMTPホスト**：`smtp.office365.com`。
   - **SMTPポート**：`587`。
   - **SMTPユーザー名**: カスタムメールアドレスが事前に入力されています。
   - **SMTPパスワード**: カスタムメールアカウント用に以前に作成したアプリパスワード。
   - **SMTP認証方法**: ログイン
1. **接続の保存とテスト**を選択
1. [確認プロセス](#verification)の後、[カスタムメールアドレスを有効にする](#enable-or-disable-the-custom-email-address)ことができるはずです。

### 既知の問題 {#known-issues}

- 一部のサービスプロバイダーでは、SMTP接続が許可されなくなりました。多くの場合、ユーザーごとに有効にし、アプリパスワードを作成できます。

## 追加のサービスデスクエイリアスメールを使用する {#use-an-additional-service-desk-alias-email}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インスタンスのサービスデスクで、追加のエイリアスメールアドレスを使用できます。

これを行うには、インスタンスの設定で[`service_desk_email`](#configure-service-desk-alias-email)を設定する必要があります。[カスタムサフィックス](#configure-a-suffix-for-service-desk-alias-email)を設定して、サブアドレス部分の`-issue-`デフォルト部分を置き換えることもできます。

### サービスデスクエイリアスメールアドレスを設定する {#configure-service-desk-alias-email}

{{< alert type="note" >}}

GitLab.comでは、`contact-project+%{key}@incoming.gitlab.com`を使用してカスタムメールボックスがすでに設定されています。プロジェクトの設定で[カスタムサフィックス](#configure-a-suffix-for-service-desk-alias-email)を設定できます。

{{< /alert >}}

サービスデスクでは、[受信メール](../../../administration/incoming_email.md)の設定がデフォルトで使用されます。ただし、サービスデスク用に別のメールアドレスを使用するには、プロジェクトの設定で、`service_desk_email`を[カスタムサフィックス](#configure-a-suffix-for-service-desk-alias-email)で設定します。

前提要件: 

- `address`には、アドレスの`user`部分の`+%{key}`プレースホルダーを`@`の前に含める必要があります。プレースホルダーは、イシューを作成するプロジェクトを識別するために使用されます。
- `service_desk_email`と`incoming_email`の設定では、サービスデスクのメールが正しく処理されるように、常に個別のメールボックスを使用する必要があります。

IMAPでサービスデスクのカスタムメールボックスを設定するには、次のスニペットを設定ファイルに完全に追加します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

{{< alert type="note" >}}

GitLab 15.3以降、サービスデスクでは、Sidekiqジョブをエンキューする代わりに、`webhook`（内部APIコール）がデフォルトで使用されます。GitLab 15.3を実行しているLinuxパッケージインストールで`webhook`を使用するには、シークレットファイルを生成する必要があります。詳細については、[マージリクエスト5927](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5927)を参照してください。GitLab 15.4では、Linuxパッケージのインスタンスを再構成すると、このシークレットファイルが自動的に生成されるため、シークレットファイルの設定ファイル設定は必要ありません。詳細については、[イシュー1462](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1462)を参照してください。

{{< /alert >}}

```ruby
gitlab_rails['service_desk_email_enabled'] = true
gitlab_rails['service_desk_email_address'] = "project_contact+%{key}@gmail.com"
gitlab_rails['service_desk_email_email'] = "project_contact@gmail.com"
gitlab_rails['service_desk_email_password'] = "[REDACTED]"
gitlab_rails['service_desk_email_mailbox_name'] = "inbox"
gitlab_rails['service_desk_email_idle_timeout'] = 60
gitlab_rails['service_desk_email_log_file'] = "/var/log/gitlab/mailroom/mail_room_json.log"
gitlab_rails['service_desk_email_host'] = "imap.gmail.com"
gitlab_rails['service_desk_email_port'] = 993
gitlab_rails['service_desk_email_ssl'] = true
gitlab_rails['service_desk_email_start_tls'] = false
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```yaml
service_desk_email:
  enabled: true
  address: "project_contact+%{key}@example.com"
  user: "project_contact@example.com"
  password: "[REDACTED]"
  host: "imap.gmail.com"
  delivery_method: webhook
  secret_file: .gitlab-mailroom-secret
  port: 993
  ssl: true
  start_tls: false
  log_path: "log/mailroom.log"
  mailbox: "inbox"
  idle_timeout: 60
  expunge_deleted: true
```

{{< /tab >}}

{{< /tabs >}}

設定オプションは、[受信メール](../../../administration/incoming_email.md#set-it-up)の設定と同じです。

#### 暗号化された認証情報を使用する {#use-encrypted-credentials}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108279)されました。

{{< /history >}}

サービスデスクのメールの認証情報を設定ファイルに平文で保存する代わりに、オプションで、暗号化されたファイルを受信メールの認証情報に使用することもできます。

前提要件: 

- 暗号化された認証情報を使用するには、まず[暗号化設定](../../../administration/encrypted_configuration.md)を有効にする必要があります。

暗号化されたファイルでサポートされている設定項目は次のとおりです:

- `user`
- `password`

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. 最初に`/etc/gitlab/gitlab.rb`のサービスデスクの設定が次のようになっている場合:

   ```ruby
   gitlab_rails['service_desk_email_email'] = "service-desk-email@mail.example.com"
   gitlab_rails['service_desk_email_password'] = "examplepassword"
   ```

1. 暗号化されたシークレットを編集します:

   ```shell
   sudo gitlab-rake gitlab:service_desk_email:secret:edit EDITOR=vim
   ```

1. サービスデスクのメールシークレットの暗号化されていない内容を入力します:

   ```yaml
   user: 'service-desk-email@mail.example.com'
   password: 'examplepassword'
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、`service_desk`設定の`email`と`password`を削除します。
1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

Kubernetesシークレットを使用して、サービスデスクのメールパスワードを保存します。詳細については、[Helm IMAPシークレット](https://docs.gitlab.com/charts/installation/secrets.html#imap-password-for-service-desk-emails)をお読みください。

{{< /tab >}}

{{< tab title="Docker" >}}

1. 最初に`docker-compose.yml`のサービスデスクの設定が次のようになっている場合:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['service_desk_email_email'] = "service-desk-email@mail.example.com"
           gitlab_rails['service_desk_email_password'] = "examplepassword"
   ```

1. コンテナ内に入り、暗号化されたシークレットを編集します:

   ```shell
   sudo docker exec -t <container_name> bash
   gitlab-rake gitlab:service_desk_email:secret:edit EDITOR=editor
   ```

1. サービスデスクシークレットの暗号化されていない内容を入力します:

   ```yaml
   user: 'service-desk-email@mail.example.com'
   password: 'examplepassword'
   ```

1. `docker-compose.yml`を編集し、`service_desk`設定の`email`と`password`を削除します。
1. ファイルを保存して、GitLabを再起動します: 

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. 最初に`/home/git/gitlab/config/gitlab.yml`のサービスデスクの設定が次のようになっている場合:

   ```yaml
   production:
     service_desk_email:
       user: 'service-desk-email@mail.example.com'
       password: 'examplepassword'
   ```

1. 暗号化されたシークレットを編集します:

   ```shell
   bundle exec rake gitlab:service_desk_email:secret:edit EDITOR=vim RAILS_ENVIRONMENT=production
   ```

1. サービスデスクシークレットの暗号化されていない内容を入力します:

   ```yaml
   user: 'service-desk-email@mail.example.com'
   password: 'examplepassword'
   ```

1. `/home/git/gitlab/config/gitlab.yml`を編集し、`service_desk_email:`設定の`user`と`password`を削除します。
1. ファイルを保存して、GitLabとMailroomを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

#### Microsoft Graph {#microsoft-graph}

{{< history >}}

- GitLab 15.11では、[自己コンパイル（ソース）インストール用としてリリースされました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116494)。

{{< /history >}}

`service_desk_email`は、IMAPの代わりに、Microsoft Graph APIを使用してMicrosoft Exchange Onlineメールボックスを読み取りるように設定できます。[受信メールの場合と同じ方法で](../../../administration/incoming_email.md#microsoft-graph)、Microsoft GraphのOAuth 2.0アプリケーションをセットアップします。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、必要な値に置き換えて次の行を追加します:

  ```ruby
  gitlab_rails['service_desk_email_enabled'] = true
  gitlab_rails['service_desk_email_address'] = "project_contact+%{key}@example.onmicrosoft.com"
  gitlab_rails['service_desk_email_email'] = "project_contact@example.onmicrosoft.com"
  gitlab_rails['service_desk_email_mailbox_name'] = "inbox"
  gitlab_rails['service_desk_email_log_file'] = "/var/log/gitlab/mailroom/mail_room_json.log"
  gitlab_rails['service_desk_email_inbox_method'] = 'microsoft_graph'
  gitlab_rails['service_desk_email_inbox_options'] = {
    'tenant_id': '<YOUR-TENANT-ID>',
    'client_id': '<YOUR-CLIENT-ID>',
    'client_secret': '<YOUR-CLIENT-SECRET>',
    'poll_interval': 60  # Optional
  }
  ```

  米国政府機関向けMicrosoft Cloudまたは[他のAzureデプロイ](https://learn.microsoft.com/en-us/graph/deployments)の場合は、`azure_ad_endpoint`と`graph_endpoint`設定を設定します。例: 

  ```ruby
  gitlab_rails['service_desk_email_inbox_options'] = {
    'azure_ad_endpoint': 'https://login.microsoftonline.us',
    'graph_endpoint': 'https://graph.microsoft.us',
    'tenant_id': '<YOUR-TENANT-ID>',
    'client_id': '<YOUR-CLIENT-ID>',
    'client_secret': '<YOUR-CLIENT-SECRET>',
    'poll_interval': 60  # Optional
  }
  ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. [OAuth 2.0アプリケーションクライアントのシークレットキーを含むKubernetesシークレット](https://docs.gitlab.com/charts/installation/secrets.html#microsoft-graph-client-secret-for-service-desk-emails)を作成します:

   ```shell
   kubectl create secret generic service-desk-email-client-secret --from-literal=secret=<YOUR-CLIENT_SECRET>
   ```

1. [GitLabサービスデスクメール認証トークン用のKubernetesシークレット](https://docs.gitlab.com/charts/installation/secrets.html#gitlab-service-desk-email-auth-token)を作成します。`<name>`をGitLabインストールの[Helmリリース名](https://helm.sh/docs/intro/using_helm/)の名前に置き換えます:

   ```shell
   kubectl create secret generic <name>-service-desk-email-auth-token --from-literal=authToken=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
   ```

1. Helmの値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
     serviceDeskEmail:
       enabled: true
       address: "project_contact+%{key}@example.onmicrosoft.com"
       user: "project_contact@example.onmicrosoft.com"
       mailbox: inbox
       inboxMethod: microsoft_graph
       azureAdEndpoint: https://login.microsoftonline.com
       graphEndpoint: https://graph.microsoft.com
       tenantId: "YOUR-TENANT-ID"
       clientId: "YOUR-CLIENT-ID"
       clientSecret:
         secret: service-desk-email-client-secret
         key: secret
       deliveryMethod: webhook
       authToken:
         secret: <name>-service-desk-email-auth-token
         key: authToken
   ```

    米国政府機関向けMicrosoft Cloudまたは[他のAzureデプロイ](https://learn.microsoft.com/en-us/graph/deployments)の場合は、`azureAdEndpoint`と`graphEndpoint`設定を設定します。これらのフィールドでは、大文字と小文字が区別されます:

   ```yaml
   global:
     appConfig:
     serviceDeskEmail:
       [..]
       azureAdEndpoint: https://login.microsoftonline.us
       graphEndpoint: https://graph.microsoft.us
       [..]
   ```

1. ファイルを保存して、新しい値を適用します: 

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します: 

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['service_desk_email_enabled'] = true
           gitlab_rails['service_desk_email_address'] = "project_contact+%{key}@example.onmicrosoft.com"
           gitlab_rails['service_desk_email_email'] = "project_contact@example.onmicrosoft.com"
           gitlab_rails['service_desk_email_mailbox_name'] = "inbox"
           gitlab_rails['service_desk_email_log_file'] = "/var/log/gitlab/mailroom/mail_room_json.log"
           gitlab_rails['service_desk_email_inbox_method'] = 'microsoft_graph'
           gitlab_rails['service_desk_email_inbox_options'] = {
             'tenant_id': '<YOUR-TENANT-ID>',
             'client_id': '<YOUR-CLIENT-ID>',
             'client_secret': '<YOUR-CLIENT-SECRET>',
             'poll_interval': 60  # Optional
           }
   ```

1. ファイルを保存して、GitLabを再起動します: 

   ```shell
   docker compose up -d
   ```

米国政府機関向けMicrosoft Cloudまたは[他のAzureデプロイ](https://learn.microsoft.com/en-us/graph/deployments)の場合は、`azure_ad_endpoint`と`graph_endpoint`設定を設定します:

1. `docker-compose.yml`を編集します: 

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['service_desk_email_enabled'] = true
           gitlab_rails['service_desk_email_address'] = "project_contact+%{key}@example.onmicrosoft.com"
           gitlab_rails['service_desk_email_email'] = "project_contact@example.onmicrosoft.com"
           gitlab_rails['service_desk_email_mailbox_name'] = "inbox"
           gitlab_rails['service_desk_email_log_file'] = "/var/log/gitlab/mailroom/mail_room_json.log"
           gitlab_rails['service_desk_email_inbox_method'] = 'microsoft_graph'
           gitlab_rails['service_desk_email_inbox_options'] = {
             'azure_ad_endpoint': 'https://login.microsoftonline.us',
             'graph_endpoint': 'https://graph.microsoft.us',
             'tenant_id': '<YOUR-TENANT-ID>',
             'client_id': '<YOUR-CLIENT-ID>',
             'client_secret': '<YOUR-CLIENT-SECRET>',
             'poll_interval': 60  # Optional
           }
   ```

1. ファイルを保存して、GitLabを再起動します: 

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します: 

   ```yaml
     service_desk_email:
       enabled: true
       address: "project_contact+%{key}@example.onmicrosoft.com"
       user: "project_contact@example.onmicrosoft.com"
       mailbox: "inbox"
       delivery_method: webhook
       log_path: "log/mailroom.log"
       secret_file: .gitlab-mailroom-secret
       inbox_method: "microsoft_graph"
       inbox_options:
         tenant_id: "<YOUR-TENANT-ID>"
         client_id: "<YOUR-CLIENT-ID>"
         client_secret: "<YOUR-CLIENT-SECRET>"
         poll_interval: 60  # Optional
   ```

  米国政府機関向けMicrosoft Cloudまたは[他のAzureデプロイ](https://learn.microsoft.com/en-us/graph/deployments)の場合は、`azure_ad_endpoint`と`graph_endpoint`設定を設定します。例: 

   ```yaml
     service_desk_email:
       enabled: true
       address: "project_contact+%{key}@example.onmicrosoft.com"
       user: "project_contact@example.onmicrosoft.com"
       mailbox: "inbox"
       delivery_method: webhook
       log_path: "log/mailroom.log"
       secret_file: .gitlab-mailroom-secret
       inbox_method: "microsoft_graph"
       inbox_options:
         azure_ad_endpoint: "https://login.microsoftonline.us"
         graph_endpoint: "https://graph.microsoft.us"
         tenant_id: "<YOUR-TENANT-ID>"
         client_id: "<YOUR-CLIENT-ID>"
         client_secret: "<YOUR-CLIENT-SECRET>"
         poll_interval: 60  # Optional
   ```

{{< /tab >}}

{{< /tabs >}}

### サービスデスクエイリアスメールのサフィックスを設定する {#configure-a-suffix-for-service-desk-alias-email}

プロジェクトのサービスデスクの設定で、カスタムサフィックスをセットできます。

サフィックスには、小文字（`a-z`）、数字（`0-9`）、またはアンダースコア（`_`）のみを含めることができます。

設定すると、カスタムサフィックスによって、`service_desk_email_address`設定と次の形式のキーで構成される新しいサービスデスクのメールアドレスが作成されます：`<project_full_path>-<custom_suffix>`

前提要件: 

- [サービスデスクエイリアスメール](#configure-service-desk-alias-email)を設定する必要があります。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **メールアドレスのサフィックス**の下に、使用するサフィックスを入力します。
1. **変更を保存**を選択します。

たとえば、`mygroup/myproject`プロジェクトのサービスデスクの設定に次の設定があるとします:

- メールアドレスのサフィックスが`support`に設定されています。
- サービスデスクのメールアドレスが`contact+%{key}@example.com`に設定されています。

このプロジェクトのサービスデスクのメールアドレスは次のとおりです：`contact+mygroup-myproject-support@example.com`。[受信メール](../../../administration/incoming_email.md)アドレスは引き続き機能します。

カスタムサフィックスを設定しない場合、デフォルトのプロジェクト識別がプロジェクトの識別に使用されます。

## マルチノード環境でのメール取り込みを設定する {#configure-email-ingestion-in-multi-node-environments}

マルチノード環境とは、スケーラビリティ、フォールトトレランス、およびパフォーマンス上の理由から、複数のサーバーにわたってGitLabが実行されるセットアップです。

GitLabは、`mail_room`と呼ばれる別のプロセスを使用して、`incoming_email`および`service_desk_email`メールボックスから新しい未読メールをインジェストするます。

### Helm Chart（Kubernetes） {#helm-chart-kubernetes}

[GitLab Helmチャート](https://docs.gitlab.com/charts/)は複数のサブチャートで構成されており、そのうちの1つが[Mailroomサブチャート](https://docs.gitlab.com/charts/charts/gitlab/mailroom/)です。[`incoming_email`の共通設定を設定する](https://docs.gitlab.com/charts/installation/command-line-options.html#incoming-email-configuration)と[`service_desk_email`の共通設定を設定する](https://docs.gitlab.com/charts/installation/command-line-options.html#service-desk-email-configuration)。

### Linuxパッケージ（Omnibus） {#linux-package-omnibus}

マルチノードLinuxパッケージインストール環境では、`mail_room`を1つのノードでのみ実行します。単一の`rails`ノード（`application_role`など）で実行するか、完全に個別に実行します。

#### すべてのノードをセットアップする {#set-up-all-nodes}

1. すべてのノードで`incoming_email`および`service_desk_email`の基本的な設定を追加して、ウェブUIおよび生成されたメールでメールアドレスをレンダリングします。

   `/etc/gitlab/gitlab.rb`で、`incoming_email`または`service_desk_email`セクションを見つけます:

   {{< tabs >}}

   {{< tab title="`incoming_email`" >}}

   ```ruby
   gitlab_rails['incoming_email_enabled'] = true
   gitlab_rails['incoming_email_address'] = "incoming+%{key}@example.com"
   ```

   {{< /tab >}}

   {{< tab title="`service_desk_email`" >}}

   ```ruby
   gitlab_rails['service_desk_email_enabled'] = true
   gitlab_rails['service_desk_email_address'] = "project_contact+%{key}@example.com"
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. GitLabは、`mail_room`からGitLabアプリケーションにメールを転送する2つの方法を提供します。メールの設定ごとに`delivery_method`を個別に設定できます:
   1. 推奨：`webhook`（GitLab 15.3以降でデフォルト）は、API POSTリクエストを使用してメールペイロードをGitLabアプリケーションに送信します。認証には、共有トークンが使用されます。この方法を選択する場合は、`mail_room`プロセスがAPIエンドポイントにアクセスでき、すべてのアプリケーションノード間で共有トークンを配布できることを確認してください。

      {{< tabs >}}

      {{< tab title="`incoming_email`" >}}

      ```ruby
      gitlab_rails['incoming_email_delivery_method'] = "webhook"

      # The URL that mail_room can contact. You can also use an internal URL or IP,
      # just make sure mail_room can access the GitLab API with that address.
      # Do not end with "/".
      gitlab_rails['incoming_email_gitlab_url'] = "https://gitlab.example.com"

      # The shared secret file that should contain a random token. Make sure it's the same on every node.
      gitlab_rails['incoming_email_secret_file'] = ".gitlab_mailroom_secret"
      ```

      {{< /tab >}}

      {{< tab title="`service_desk_email`" >}}

      ```ruby
      gitlab_rails['service_desk_email_delivery_method'] = "webhook"

      # The URL that mail_room can contact. You can also use an internal URL or IP,
      # just make sure mail_room can access the GitLab API with that address.
      # Do not end with "/".

      gitlab_rails['service_desk_email_gitlab_url'] = "https://gitlab.example.com"

      # The shared secret file that should contain a random token. Make sure it's the same on every node.
      gitlab_rails['service_desk_email_secret_file'] = ".gitlab_mailroom_secret"
      ```

      {{< /tab >}}

      {{< /tabs >}}

   1. `webhook`のセットアップで問題が発生する場合は、`sidekiq`を使用して、Redisを使用してメールペイロードをGitLab Sidekiqに直接配信します。

      {{< tabs >}}

      {{< tab title="`incoming_email`" >}}

      ```ruby
      # It uses the Redis configuration to directly add Sidekiq jobs
      gitlab_rails['incoming_email_delivery_method'] = "sidekiq"
      ```

      {{< /tab >}}

      {{< tab title="`service_desk_email`" >}}

      ```ruby
      # It uses the Redis configuration to directly add Sidekiq jobs
      gitlab_rails['service_desk_email_delivery_method'] = "sidekiq"
      ```

      {{< /tab >}}

      {{< /tabs >}}

1. メール取り込みを実行しないすべてのノードで`mail_room`を無効にします。次に、`/etc/gitlab/gitlab.rb`の例を示します:

   ```ruby
   mailroom['enable'] = false
   ```

1. 変更を有効にするには、[GitLabを再設定します](../../../administration/restart_gitlab.md)。

#### 単一メール取り込みノードをセットアップする {#set-up-a-single-email-ingestion-node}

すべてのノードをセットアップし、`mail_room`プロセスを無効にした後、単一のノードで`mail_room`を有効にします。このノードは、`incoming_email`および`service_desk_email`のメールボックスを定期的にポーリングするし、新しい未読メールをGitLabに移動します。

1. さらにメール取り込みを処理する既存のノードを選択します。
1. `incoming_email`および`service_desk_email`の[完全な設定と認証情報](../../../administration/incoming_email.md#configuration-examples)を追加します。
1. このノードで`mail_room`を有効にします。次に、`/etc/gitlab/gitlab.rb`の例を示します:

   ```ruby
   mailroom['enable'] = true
   ```

1. 変更を有効にするには、このノードで[GitLabを再設定する](../../../administration/restart_gitlab.md)。
