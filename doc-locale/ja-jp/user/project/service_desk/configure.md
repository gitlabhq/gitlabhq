---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: サービスデスクを設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

デフォルトでは、サービスデスクは新規プロジェクトでアクティブになっています。アクティブでない場合、プロジェクトの設定でアクティブにできます。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。
- GitLab Self-Managedでは、GitLabインスタンスの[受信メールを設定](../../../administration/incoming_email.md#set-it-up)する必要があります。[メールのサブアドレッシング](../../../administration/incoming_email.md#email-sub-addressing)を使用する必要がありますが、[すべてをキャッチするメールボックス](../../../administration/incoming_email.md#catch-all-mailbox)も使用できます。これを行うには、管理者アクセスが必要です。
- プロジェクトの[イシュー](../settings/_index.md#configure-project-features-and-permissions)トラッカーを有効にする必要があります。

プロジェクトでサービスデスクを有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **サービスデスクを有効にする**切替をオンにします。
1. オプション。フィールドに入力します。
   - サービスデスクメールアドレスに[サフィックスを追加](#configure-a-suffix-for-service-desk-alias-email)します。
   - **全てのサービスデスクのイシューに追加するテンプレート**の下のリストが空の場合、リポジトリに[説明テンプレート](../description_templates.md)を作成してください。
1. **変更を保存**を選択します。

このプロジェクトでサービスデスクが有効になりました。**サービスデスクで使用するメールアドレス**の下に表示されているアドレスに誰かがメールを送信すると、GitLabはメールの内容を含む機密チケットを作成します。

## サービスデスク用語集 {#service-desk-glossary}

この用語集は、サービスデスクに関連する用語の定義を提供します。

| 用語                                             | 定義 |
|--------------------------------------------------|------------|
| [外部参加者](external_participants.md) | GitLabアカウントを持たないユーザーで、イシューまたはサービスデスクチケットとメールのみでやり取りできるユーザー。 |
| リクエスタ                                        | サービスデスクチケットを作成した、または[`/convert_to_ticket`クイックアクション](using_service_desk.md#create-a-service-desk-ticket-in-gitlab-ui)を使用してリクエスタとして追加された外部参加者。 |

## プロジェクトのセキュリティを向上させる {#improve-your-projects-security}

サービスデスクプロジェクトのセキュリティを向上させるには、次のことを行う必要があります:

- サービスデスクのメールアドレスをメールシステム上のエイリアスの背後に置いて、後で変更できるようにします。
- GitLabインスタンスで[Akismetを有効](../../../integration/akismet.md)にして、このサービスにスパムチェックを追加します。ブロックされていないメールスパムにより、多くのスパムイシューが作成される可能性があります。

## 外部参加者へのメールをカスタマイズする {#customize-emails-sent-to-external-participants}

{{< history >}}

- `UNSUBSCRIBE_URL`、`SYSTEM_HEADER`、`SYSTEM_FOOTER`、および`ADDITIONAL_TEXT`プレースホルダーがGitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/285512)されました。
- `%{ISSUE_DESCRIPTION}`がGitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/223751)されました。
- `%{ISSUE_URL}`はGitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/408793)されました。

{{< /history >}}

外部参加者には、次の場合にメールが送信されます:

- リクエスタがサービスデスクにメールを送信して新しいチケットを提出した場合。
- 外部参加者がサービスデスクチケットに追加された場合。
- サービスデスクチケットに新しい公開コメントが追加された場合。
  - コメントを編集しても、新しいメールの送信はトリガーされません。

これらのメールメッセージの本文は、サービスデスクのメールテンプレートでカスタマイズできます。テンプレートには、[GitLab Flavored Markdown](../../markdown.md)と[一部のHTMLタグ](../../markdown.md#inline-html)を含めることができます。たとえば、メールを組織のブランドガイドラインに従ってヘッダーとフッターを含むようにフォーマットできます。サービスデスクチケットまたはGitLabインスタンスに固有の動的コンテンツを表示するために、以下のプレースホルダーを含めることもできます。

| プレースホルダー            | `thank_you.md`と`new_participant` | `new_note.md`          | 説明 |
|------------------------|--------------------------------------|------------------------|-------------|
| `%{ISSUE_ID}`          | {{< yes >}}               | {{< yes >}} | チケットIID。 |
| `%{ISSUE_PATH}`        | {{< yes >}}               | {{< yes >}} | チケットIIDが追加されたプロジェクトパス。 |
| `%{ISSUE_URL}`         | {{< yes >}}               | {{< yes >}} | チケットのURL。プロジェクトが公開されており、チケットが機密でない場合（サービスデスクチケットはデフォルトで機密です）にのみ、外部参加者はチケットを表示できます。 |
| `%{ISSUE_DESCRIPTION}` | {{< yes >}}               | {{< yes >}} | チケットの説明。ユーザーが説明を編集した場合、外部参加者に配信されることを意図しない機密情報が含まれている可能性があります。このプレースホルダーは慎重に使用し、チケットの説明を決して変更しない場合、またはチームがテンプレートの設計を認識している場合にのみ使用してください。 |
| `%{UNSUBSCRIBE_URL}`   | {{< yes >}}               | {{< yes >}} | 購読解除URL。外部参加者として[購読解除する方法](external_participants.md#unsubscribing-from-notification-emails)と、GitLabからの通知メールで[購読解除ヘッダーを使用する方法](../../profile/notifications.md#using-an-email-client-or-other-software)を学びます。 |
| `%{NOTE_TEXT}`         | {{< no >}}                | {{< yes >}} | ユーザーによってチケットに追加された新しいコメント。このプレースホルダーを`new_note.md`に含めるように注意してください。そうしないと、外部参加者はサービスデスクチケットの更新を見ることができない場合があります。 |

### 感謝メール {#thank-you-email}

リクエスタがサービスデスクを介してイシューを提出すると、GitLabは**thank you email**を送信します。追加の設定がない場合、GitLabはデフォルトのサンキューメールを送信します。

カスタムサンキューメールテンプレートを作成するには:

1. リポジトリの`.gitlab/service_desk_templates/`ディレクトリに、`thank_you.md`という名前のファイルを作成します。
1. Markdownファイルにテキスト、[GitLab Flavored Markdown](../../markdown.md) 、[一部の選択されたHTMLタグ](../../markdown.md#inline-html)、およびプレースホルダーを入力して、サービスデスクリクエスタへの返信をカスタマイズします。

### 新規参加者メール {#new-participant-email}

{{< history >}}

- `new_participant`メールがGitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/299261)されました。

{{< /history >}}

[外部参加者](external_participants.md)がチケットに追加されると、GitLabは**new participant email**を送信して、彼らが会話に参加していることを知らせます。追加の設定がない場合、GitLabはデフォルトの新規参加者メールを送信します。

カスタム新規参加者メールテンプレートを作成するには:

1. リポジトリの`.gitlab/service_desk_templates/`ディレクトリに、`new_participant.md`という名前のファイルを作成します。
1. Markdownファイルにテキスト、[GitLab Flavored Markdown](../../markdown.md) 、[一部の選択されたHTMLタグ](../../markdown.md#inline-html)、およびプレースホルダーを入力して、サービスデスクリクエスタへの返信をカスタマイズします。

### 新規メモメール {#new-note-email}

サービスデスクチケットに新しい公開コメントがある場合、GitLabは**new note email**を送信します。追加の設定がない場合、GitLabはコメントの内容を送信します。

メールのブランドを維持するために、カスタム新規メモメールテンプレートを作成できます。これを行うには、次の手順に従います。

1. リポジトリの`.gitlab/service_desk_templates/`ディレクトリに、`new_note.md`という名前のファイルを作成します。
1. Markdownファイルにテキスト、[GitLab Flavored Markdown](../../markdown.md)、[一部の選択されたHTMLタグ](../../markdown.md#inline-html)、およびプレースホルダーを入力して、新規メモメールをカスタマイズします。メールの受信者がコメントの内容を読めるように、テンプレートに`%{NOTE_TEXT}`を含めるようにしてください。

### インスタンス全体のメールヘッダー、フッター、および追加テキスト {#instance-wide-email-header-footer-and-additional-text}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/344819)されました。

{{< /history >}}

インスタンス管理者は、GitLabインスタンスにヘッダー、フッター、または追加テキストを追加し、それらをGitLabから送信されるすべてのメールに適用できます。カスタム`thank_you.md`、`new_participant.md`、または`new_note.md`を使用している場合は、このコンテンツを含めるために、テンプレートに`%{SYSTEM_HEADER}`、`%{SYSTEM_FOOTER}`、または`%{ADDITIONAL_TEXT}`を追加してください。

詳細については、[システムヘッダーとフッターメッセージ](../../../administration/appearance.md#add-system-header-and-footer-messages)および[カスタム追加テキスト](../../../administration/settings/email.md#custom-additional-text)を参照してください。

## サービスデスクチケットにカスタムテンプレートを使用する {#use-a-custom-template-for-service-desk-tickets}

新しいサービスデスクチケットの説明ごとに、1つの[説明テンプレート](../description_templates.md#create-a-description-template)を**per project**に選択して追加できます。

説明テンプレートはさまざまなレベルで設定できます:

- [インスタンス](../description_templates.md#set-instance-level-description-templates)全体。
- 特定の[グループまたはサブグループ](../description_templates.md#set-group-level-description-templates)。
- 特定の[プロジェクト](../description_templates.md#set-a-default-template-for-merge-requests-and-issues)。

テンプレートは継承されます。たとえば、プロジェクトでは、インスタンスまたはプロジェクトの親グループ用に設定されたテンプレートにもアクセスできます。

前提条件: 

- [説明テンプレートを作成](../description_templates.md#create-a-description-template)している必要があります。

サービスデスクでカスタム説明テンプレートを使用するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. ドロップダウンリストの**全てのサービスデスクのイシューに追加するテンプレート**から、テンプレートを検索または選択します。

## サポートボットユーザー {#support-bot-user}

舞台裏では、サービスデスクは特別なサポートボットユーザーがチケットを作成することで機能します。このユーザーは、[請求対象ユーザー](../../../subscriptions/manage_seats.md#criteria-for-non-billable-users)ではないため、ライセンス制限数にはカウントされません。

GitLab 16.0および以前では、サービスデスクメールから生成されたコメントは、`GitLab Support Bot`を作成者として表示します。In [GitLab 16.1 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/226995)では、これらのコメントはメールを送信したユーザーのメールを表示します。この機能は、GitLab 16.1および以降で作成されたコメントにのみ適用されます。

### サポートボットの表示名を変更する {#change-the-support-bots-display-name}

サポートボットユーザーの表示名を変更できます。サービスデスクチケットから送信されるメールは、`From`ヘッダーにこの名前を使用します。デフォルトの表示名は`GitLab Support Bot`です。

カスタムメール表示名を編集するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **メールの表示名**の下に、新しい名前を入力します。
1. **変更を保存**を選択します。

## デフォルトのチケット表示レベル {#default-ticket-visibility}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/33091)。

{{< /history >}}

新規チケットはデフォルトで機密扱いであるため、プランナー、レポーター、デベロッパー、メンテナー、またはオーナーロールを持つプロジェクトメンバーのみが表示できます。

プライベートおよび内部プロジェクトでは、新規チケットがデフォルトで機密でないようにGitLabを設定でき、どのプロジェクトメンバーでも表示できます。

公開プロジェクトでは、新規チケットは常にデフォルトで機密であるため、この設定は利用できません。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

この設定を無効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **デフォルトでは、新規チケットは非公開です**チェックボックスをオフにします。
1. **変更を保存**を選択します。

## 外部参加者がコメントした場合にチケットを再オープンする {#reopen-tickets-when-an-external-participant-comments}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/8549)

{{< /history >}}

外部参加者がメールでチケットに新しいコメントを追加した場合に、閉じたチケットを再オープンするようにGitLabを設定できます。これにより、チケットの割り当て先が言及された内部コメントも追加され、彼らのためのTo-Doアイテムが作成されます。

<i class="fa-youtube-play" aria-hidden="true"></i>ウォークスルーについては、[短いショーケースビデオ](https://youtu.be/163wDM1e43o)をご覧ください。
<!-- Video published on 2023-12-12 -->

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

この設定を有効にするには、次の手順に従います: 

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **Reopen issues on a new note from an external participant**チェックボックスを選択します。
1. **変更を保存**を選択します。

## カスタムメールアドレス {#custom-email-address}

{{< details >}}

- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 16.3で`service_desk_custom_email`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/329990)されました。デフォルトでは無効になっています。
- GitLab.comおよびGitLab Self-ManagedでGitLab 16.4に[有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/387003)されました。
- SMTP認証方法を選択する機能がGitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429680)されました。
- GitLab 16.7で[機能フラグ`service_desk_custom_email`が削除](https://gitlab.com/gitlab-org/gitlab/-/issues/387003)されました。
- GitLab Self-ManagedのSMTPホストに対してローカルネットワークがGitLab 16.7で[許可](https://gitlab.com/gitlab-org/gitlab/-/issues/435206)されました。

{{< /history >}}

サポート通信の送信者として表示されるカスタムメールアドレスを設定します。ブランドアイデンティティを維持し、認識しているドメインでサポートリクエスタに信頼を植え付けます。

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[短いショーケースビデオ](https://youtu.be/_moD5U3xcQs)をご覧ください。
<!-- Video published on 2023-09-12 -->

この機能は[ベータ版](../../../policy/development_stages_support.md#beta)です。ベータ機能は本番環境対応ではありませんが、リリース前に大幅に変更される可能性は低いでしょう。ユーザーにはベータ機能を試用し、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/416637)でフィードバックを提供するようお勧めします。

### 前提条件 {#prerequisites}

サービスデスクにはプロジェクトごとに1つのカスタムメールアドレスを使用でき、それはインスタンス全体で一意である必要があります。

使用するカスタムメールアドレスは、以下のすべての要件を満たす必要があります:

- メール転送を設定できます。
- 転送されたメールは元の`From`ヘッダーを保持します。
- サービスプロバイダーはサブアドレッシングをサポートしている必要があります。メールアドレスは、ローカル部分（`@`の前のすべて）とドメイン部分で構成されます。

  メールサブアドレッシングを使用すると、ローカル部分に`+`記号とその後に任意のテキストを追加することで、メールアドレスの一意のバリエーションを作成できます。`support@example.com`のメールアドレスが与えられた場合、`support+1@example.com`にメールを送信してサブアドレッシングがサポートされているかどうかを確認してください。このメールはメールボックスに表示されるはずです。
- SMTP認証情報を持っていること（理想的にはアプリパスワードを使用する必要があります）。ユーザー名とパスワードは、Advanced Encryption Standard (AES) を使用して256ビットキーでデータベースに保存されます。
- **SMTPホスト**は、GitLabインスタンスのネットワーク（GitLab Self-Managedの場合）またはパブリックインターネット（GitLab.comの場合）から解決可能である必要があります。
- プロジェクトのメンテナーまたはオーナーロールが必要です。
- サービスデスクがプロジェクト用に設定されている必要があります。

### カスタムメールアドレスを設定 {#configure-a-custom-email-address}

自身のメールアドレスを使用してサービスデスクメールを送信する場合、カスタムメールアドレスを設定および検証します。

> [!warning]
> メール転送を設定する際は、カスタムメールフォームの**メールを転送するためのサービスデスクのメールアドレス**フィールドにあるアドレス（`incoming+...`アドレス）を使用してください。サービスデスクの設定ページ上部にあるエイリアスアドレス（`contact-project+...`）には転送しないでください。エイリアスアドレスへの転送は、`Incorrect forwarding target`の検証失敗を引き起こします。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開するして、**カスタムメールアドレスを設定**セクションを見つけます。
1. **メールを転送するためのサービスデスクのメールアドレス**フィールドからメールアドレスをコピーします。これは、転送先として使用する必要がある`incoming+...`メールアドレスです。
1. ご使用のメールプロバイダー（例: GmailまたはMicrosoft 365）で、カスタムメールアドレスから前のステップでコピーしたアドレスへのメール転送を設定します。
1. GitLabに戻り、残りのフィールドに入力してください。
1. **Save & test connection**を選択します。

設定が保存され、カスタムメールアドレスの検証がトリガーされます。

#### 検証 {#verification}

1. 設定を完了すると、すべてのプロジェクトオーナーとカスタムメール設定を保存した管理者は通知メールを受け取ります。
1. 提供されたSMTP認証情報を使用して、カスタムメールアドレス（サブアドレッシング部分を含む）に検証メールが送信されます。メールには検証トークンが含まれています。メール転送が正しく設定され、すべての前提条件が満たされている場合、メールはサービスデスクアドレスに転送され、GitLabによってインジェストされます。GitLabは次の条件を確認します:
   1. GitLabはSMTP認証情報を使用してメールを送信できます。
   1. サブアドレッシングはサポートされています（`+verify`のサブアドレッシング部分を含む）。
   1. `From`ヘッダーは転送後も保持されます。
   1. 検証トークンが正しい。
   1. メールが30分以内に受信される。

通常、このプロセスには数分しかかかりません。

いつでも検証をキャンセルするか、失敗した場合は**カスタムメールをリセット**を選択します。設定ページはそれに応じて更新され、検証の現在の状態を反映します。SMTP認証情報は削除され、設定を再度開始できます。

失敗および成功時には、すべてのプロジェクトオーナーと検証プロセスをトリガーしたユーザーは、検証結果を含む通知メールを受け取ります。検証が失敗した場合、メールにはその理由の詳細も含まれます。

検証が成功した場合、カスタムメールアドレスは使用準備ができています。これで、カスタムメールアドレスでサービスデスクメールの送信を有効にできます。

#### 設定のトラブルシューティング {#troubleshooting-your-configuration}

カスタムメールを設定する際に、以下のイシューに遭遇する可能性があります。

##### 無効な認証情報 {#invalid-credentials}

次のようなエラーが表示される場合があります:

```plaintext
The given credentials (username and password) were rejected by the SMTP server,
or you need to explicitly set an authentication method.
```

このイシューは、SMTPサーバーが認証認証情報を拒否した場合に発生します。

この問題を解決するには、次の手順に従います:

1. ユーザー名とパスワードが正しいことを確認します。
1. GitLabがサポートされている認証方法を自動的に選択できない場合は、次のいずれかを実行します:
   - 利用可能な認証方法をテストします: **プレーン**、**ログイン**、および**CRAM-MD5**。
   - GitLabサーバーでこのコマンドを実行して、SMTPサーバーがサポートする認証方法を確認します:

     ```shell
          swaks --to user@example.com \
                --from support@example.com \
                --auth-user support@example.com \
                --server smtp@example.com:587 \
                -tls-optional \
                --auth-password your-app-password
     ```

     出力で`250-AUTH`で始まる行を見つけてから、カスタムメールセットアップフォームでサポートされている認証方法のいずれかを選択します。

1. Microsoft 365を使用していてエラーが解決しない場合は、条件付きアクセスを無効にして前の手順を繰り返します。

##### 不適切な転送ターゲット {#incorrect-forwarding-target}

不適切な転送ターゲットが使用されたことを示すエラーが表示される場合があります。

これは、検証メールが、カスタムメール設定フォームに表示されているプロジェクト固有のサービスデスクアドレスとは異なるメールアドレスに転送された場合に発生します。

`incoming_email`から生成されたサービスデスクアドレスを使用する必要があります。`service_desk_email`から生成された追加のサービスデスクエイリアスアドレスへの転送は、すべてのメールによる返信機能をサポートしていないため、サポートされていません。

これをトラブルシューティングを行うには:

1. メールの転送先の正しいメールアドレスを見つけます。次のいずれかの操作を行います:
   - すべてのプロジェクトオーナーと検証プロセスをトリガーしたユーザーが受け取る検証結果メールからアドレスをメモします。
   - カスタムメールセットアップフォームの**メールを転送するためのサービスデスクのメールアドレス**入力からアドレスをコピーします。
1. すべてのメールをカスタムメールアドレスから正しいターゲットメールアドレスに転送します。

### カスタムメールアドレスを有効または無効にする {#enable-or-disable-the-custom-email-address}

カスタムメールアドレスが検証された後、管理者はカスタムメールアドレスでサービスデスクメールの送信を有効または無効にできます。

カスタムメールアドレスを**enable**にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **Enable custom email**切替をオンにします。外部参加者へのサービスデスクメールは、SMTP認証情報を使用して送信されます。

カスタムメールアドレスを**disable**にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **Enable custom email**切替をオフにします。メール転送を設定したため、カスタムメールアドレスへのメールは引き続き処理され、プロジェクトのサービスデスクチケットとして表示されます。

   外部参加者へのサービスデスクメールは、GitLabインスタンスのデフォルト送信メール設定を使用して送信されるようになりました。

### カスタムメール設定の変更または削除 {#change-or-remove-custom-email-configuration}

カスタムメール設定を変更するには、それをリセットして削除し、カスタムメールを再度設定する必要があります。

プロセスの任意のステップで設定をリセットするには、**カスタムメールをリセット**を選択します。認証情報はデータベースから削除されます。

### カスタムメール返信アドレス {#custom-email-reply-address}

外部参加者はサービスデスクチケットに[メールで返信](../../../administration/reply_by_email.md)できます。GitLabは、チケットに対応する32文字の返信キーを含むメール返信アドレスを使用します。カスタムメールが設定されている場合、GitLabはそのメールから返信アドレスを生成します。

### 独自のドメインでGoogle Workspaceを使用する {#use-google-workspace-with-your-own-domain}

独自のドメインでGoogle Workspaceを使用する場合、サービスデスク用にカスタムメールアドレスを設定します。

前提条件: 

- Google Workspaceアカウントを既に持っていること。
- テナント用に新しいアカウントを作成できること。

Google Workspaceでカスタムサービスデスクメールアドレスを設定するには:

1. [Google Workspaceアカウントを構成](#configure-a-google-workspace-account)します。
1. [Google Workspaceでメール転送を設定](#configure-email-forwarding-in-google-workspace)します。
1. [Google Workspaceアカウントを使用してカスタムメールアドレスを構成](#configure-custom-email-address-using-a-google-workspace-account)します。

#### Google Workspaceアカウントを構成する {#configure-a-google-workspace-account}

まず、Google Workspaceアカウントを作成し、設定する必要があります。

Google Workspaceで:

1. 使用したいカスタムメールアドレスの新しいアカウントを作成します（例: `support@example.com`）。
1. そのアカウントにサインインし、[2要素認証を有効](https://myaccount.google.com/u/3/signinoptions/two-step-verification)にします。
1. SMTPパスワードとして使用できる[アプリパスワードを作成](https://myaccount.google.com/u/3/apppasswords)します。安全な場所に保管し、文字間のスペースを削除してください。

次に、[Google Workspaceでメール転送を設定](#configure-email-forwarding-in-google-workspace)する必要があります。

#### Google Workspaceでメール転送を設定する {#configure-email-forwarding-in-google-workspace}

以下の手順では、GitLabとGoogle Workspaceの間を移動する必要があります。

GitLabで、次の手順を実行します。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **メールを転送するためのサービスデスクのメールアドレス**の下のメールアドレスをメモします。

Google Workspaceで:

1. カスタムメールアカウントにサインインし、[**Forwarding and POP/IMAP**](https://mail.google.com/mail/u/0/#settings/fwdandpop)の設定を開きます。
1. **Add a forwarding address**を選択します。
1. カスタムメールフォームからサービスデスクアドレスを入力します。
1. **Next**を選択します。
1. 入力を確認し、**続行**を選択します。Googleはサービスデスクアドレスにメールを送信し、確認コードを要求します。

GitLabで、次の手順を実行します。

1. **Plan** > **作業アイテム**を選択し、**タイプ** = **Issue**でフィルタリングします。Googleからの確認メールから新しいイシューが作成されるのを待ちます。
1. そのイシューを選択し、確認コードをメモします。
1. オプション。イシューを削除します。

Google Workspaceで:

1. 確認コードを入力し、**Verify**を選択します。
1. **Forward a copy of incoming mail to**を選択し、ドロップダウンリストからサービスデスクアドレスが選択されていることを確認します。
1. ページの下部で、**変更を保存**を選択します。

次に、サービスデスクで使用するために[Google Workspaceアカウントを使用してカスタムメールアドレスを構成](#configure-custom-email-address-using-a-google-workspace-account)します。

#### Google Workspaceアカウントを使用してカスタムメールアドレスを構成する {#configure-custom-email-address-using-a-google-workspace-account}

GitLabで、次の手順を実行します。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開するして、カスタムメール設定を見つけます。
1. フィールドに入力します:
   - **カスタムメールアドレス**: あなたのカスタムメールアドレス。
   - **SMTPホスト**: `smtp.gmail.com`。
   - **SMTPポート**: `587`。
   - **SMTPユーザー名**: カスタムメールアドレスで事前に埋められます。
   - **SMTPパスワード**: カスタムメールアカウント用に以前に作成したアプリパスワード。
   - **SMTP認証方法**: GitLabにサーバーがサポートする方法を選択させる（推奨）。
1. **接続の保存とテスト**を選択します。
1. [検証プロセス](#verification)の後、カスタムメールアドレスを[有効](#enable-or-disable-the-custom-email-address)にできるはずです。

### 独自のドメインでMicrosoft 365 (Exchange Online) を使用する {#use-microsoft-365-exchange-online-with-your-own-domain}

{{< history >}}

- GitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/496396)されました。

{{< /history >}}

独自のドメインでMicrosoft 365 (Exchange) を使用する場合、サービスデスク用にカスタムメールアドレスを設定します。

前提条件: 

- Microsoft 365アカウントを既に持っていること。
- テナント用に新しいアカウントを作成できること。

Microsoft 365でカスタムサービスデスクメールアドレスを設定するには:

1. [Microsoft 365アカウントを設定](#configure-a-microsoft-365-account)します。
1. [Microsoft 365でメール転送を設定](#configure-email-forwarding-in-microsoft-365)します。
1. [Microsoft 365アカウントを使用してカスタムメールアドレスを設定](#configure-custom-email-address-using-a-microsoft-365-account)します。

#### Microsoft 365アカウントを設定する {#configure-a-microsoft-365-account}

まず、Microsoft 365アカウントを作成し、設定する必要があります。このガイドでは、カスタムメールボックスにライセンスユーザーを使用します。他の設定オプションを実験することもできます。

[Microsoft 365管理センター](https://admin.microsoft.com/Adminportal/Home#/homepage)で:

1. 使用したいカスタムメールアドレスの新しいアカウントを作成します（例: `support@example.com`）。
   1. **ユーザー**セクションを展開するして、メニューから**アクティブユーザー**を選択します。
   1. **Add a user**を選択し、画面の指示に従います。
1. Microsoft Entra（旧称Active Directory）で、アカウントの2要素認証を有効にします。
1. [ユーザーがアプリパスワードを作成できるようにします](https://learn.microsoft.com/en-us/entra/identity/authentication/howto-mfa-app-passwords)。
1. アカウントで**Authenticated SMTP**を有効にします。
   1. リストからアカウントを選択します。
   1. ドロワーで**Mail**を選択します。
   1. **Email apps**の下で**Manage email apps**を選択します。
   1. **Authenticated SMTP**をチェックし、**変更を保存**を選択します。
1. 全体的なExchange Online設定によっては、以下のものを設定する必要がある場合があります:
   1. Azure Cloud Shellを使用してSMTPクライアント認証を許可します:

      ```powershell
      Set-TransportConfig -SmtpClientAuthenticationDisabled $false
      ```

   1. Azure Cloud Shellを使用して[SMTP AUTHを使用するレガシーTLSクライアント](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/opt-in-exchange-online-endpoint-for-legacy-tls-using-smtp-auth)を許可します:

      ```powershell
      Set-TransportConfig -AllowLegacyTLSClients $true
      ```

   1. 外部受信者に転送したい場合は、[外部メール転送](https://learn.microsoft.com/en-gb/defender-office-365/outbound-spam-policies-external-email-forwarding)を有効にする方法に関するこのガイドを参照してください。また、[送信アンチスパムポリシーを作成](https://security.microsoft.com/antispam)して、必要なユーザーのみが外部受信者に転送できるようにすることもできます。
1. そのアカウントにサインインし、2要素認証を有効にします。
   <!-- vale gitlab_base.SubstitutionWarning = NO -->
   1. 右上隅のメニューから、**View account**を選択し、[**Security Info**に移動](https://mysignins.microsoft.com/security-info)します。
   <!-- vale gitlab_base.SubstitutionWarning = YES -->
   1. **Add sign-in method**を選択し、自分に合った方法（認証アプリ、電話、またはメール）を選択します。
   1. 画面の指示に従います。
<!-- vale gitlab_base.SubstitutionWarning = NO -->
1. [**Security Info**](https://mysignins.microsoft.com/security-info)ページで、SMTPパスワードとして使用できるアプリパスワードを作成します。
<!-- vale gitlab_base.SubstitutionWarning = YES -->
   1. **Add sign-in method**を選択し、ドロップダウンリストから**App password**を選択します。
   1. アプリパスワードの記述的な名前を`GitLab SD`のように設定します。
   1. **Next**を選択します。
   1. 表示されたパスワードをコピーし、安全な場所に保管します。
   1. オプション。[`swaks`コマンドラインツール](https://www.jetmore.org/john/code/swaks/)を使用してSMTPでメールを送信できることを確認します。
   1. 認証情報を使用して次のコマンドを実行し、アプリパスワードを`auth-password`として使用します:

      ```shell
      swaks --to your-email@example.com \
            --from custom-email@example.com \
            --auth-user custom-email@example.com \
            --server smtp.office365.com:587 \
            -tls-optional \
            --auth-password <your_app_password>
      ```

次に、[Microsoft 365でメール転送を設定](#configure-email-forwarding-in-microsoft-365)する必要があります。

#### Microsoft 365でメール転送を設定する {#configure-email-forwarding-in-microsoft-365}

以下の手順では、GitLabとMicrosoft 365管理センターの間を移動する必要があります。

GitLabで、次の手順を実行します。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. サブアドレス部分なしで、**メールを転送するためのサービスデスクのメールアドレス**の下のメールアドレスをメモします。

   受信者アドレスにサブアドレス（GitLabによって生成された返信アドレスなど）が含まれており、転送メールアドレスにサブアドレス（**メールを転送するためのサービスデスクのメールアドレス**）が含まれている場合、メールは転送されません。

   たとえば、`incoming+group-project-12346426-issue-@incoming.gitlab.com`は`incoming@incoming.gitlab.com`になります。Exchange Onlineは転送後もカスタムメールアドレスを`To`ヘッダーに保持し、GitLabはカスタムメールアドレスに基づいて正しいプロジェクトを割り当てることができるため、問題ありません。

[Microsoft 365管理センター](https://admin.microsoft.com/Adminportal/Home#/homepage)で:

<!-- vale gitlab_base.SubstitutionWarning = NO -->
1. **ユーザー**セクションを展開するして、メニューから**アクティブユーザー**を選択します。
<!-- vale gitlab_base.SubstitutionWarning = YES -->
1. リストからカスタムメールに使用するアカウントを選択します。
1. ドロワーで**Mail**を選択します。
1. **Email forwarding**の下で**Manage email forwarding**を選択します。
1. **Forward all emails sent to this mailbox**をチェックします。
1. カスタムメールフォームの**Forwarding email address**に、サブアドレス部分なしでサービスデスクアドレスを入力します。
1. **変更を保存**を選択します。

次に、サービスデスクで使用するために[Microsoft 365アカウントを使用してカスタムメールアドレスを設定](#configure-custom-email-address-using-a-microsoft-365-account)します。

#### Microsoft 365アカウントを使用してカスタムメールアドレスを設定する {#configure-custom-email-address-using-a-microsoft-365-account}

GitLabで、次の手順を実行します。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開するして、カスタムメール設定を見つけます。
1. フィールドに入力します:
   - **カスタムメールアドレス**: あなたのカスタムメールアドレス。
   - **SMTPホスト**: `smtp.office365.com`。
   - **SMTPポート**: `587`。
   - **SMTPユーザー名**: カスタムメールアドレスで事前に埋められます。
   - **SMTPパスワード**: カスタムメールアカウント用に以前に作成したアプリパスワード。
   - **SMTP認証方法**: ログイン
1. **接続の保存とテスト**を選択します。
1. [検証プロセス](#verification)の後、カスタムメールアドレスを[有効](#enable-or-disable-the-custom-email-address)にできるはずです。

### 既知の問題 {#known-issues}

- 一部のサービスプロバイダーは、もはやSMTP接続を許可していません。多くの場合、ユーザーごとに有効にしてアプリパスワードを作成できます。

## 追加のサービスデスクエイリアスメールを使用する {#use-an-additional-service-desk-alias-email}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インスタンスのサービスデスクに追加のエイリアスメールアドレスを使用できます。

これを行うには、インスタンス設定で[`service_desk_email`](#configure-service-desk-alias-email)を設定する必要があります。[カスタムサフィックス](#configure-a-suffix-for-service-desk-alias-email)を設定して、サブアドレッシング部分のデフォルトの`-issue-`部分を置き換えることもできます。

### サービスデスクエイリアスメールを設定する {#configure-service-desk-alias-email}

> [!note]
> GitLab.comでは、カスタムメールボックスが`contact-project+%{key}@incoming.gitlab.com`をメールアドレスとして既に設定されています。プロジェクト設定で[カスタムサフィックス](#configure-a-suffix-for-service-desk-alias-email)を設定することは引き続き可能です。

サービスデスクは、デフォルトで[受信メール](../../../administration/incoming_email.md)設定を使用します。ただし、サービスデスク用に個別のメールアドレスを使用するには、プロジェクト設定で`service_desk_email`を[カスタムサフィックス](#configure-a-suffix-for-service-desk-alias-email)で設定します。

前提条件: 

- `address`は、アドレスの`user`部分に`@`の前に`+%{key}`プレースホルダーを含める必要があります。プレースホルダーは、イシューが作成されるプロジェクトを識別するために使用されます。
- サービスデスクメールが正しく処理されるように、`service_desk_email`と`incoming_email`の設定は常に別々のメールボックスを使用する必要があります。

IMAPでサービスデスクのカスタムメールボックスを設定するには、以下のスニペットを設定ファイルにすべて追加します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

> [!note]
> GitLab 15.3および以降では、サービスデスクはSidekiqジョブをエンキューする代わりに、デフォルトで`webhook`（内部APIコール）を使用します。GitLab 15.3を実行しているLinuxパッケージインストールで`webhook`を使用するには、シークレットファイルを生成する必要があります。詳細については、[マージリクエスト5927](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5927)を参照してください。GitLab 15.4では、Linuxパッケージの再設定によりこのシークレットファイルが自動的に生成されるため、シークレットファイルの設定は必要ありません。詳細については、[イシュー1462](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1462)を参照してください。

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

設定オプションは、[受信メール](../../../administration/incoming_email.md#set-it-up)を設定する場合と同じです。

#### 暗号化された認証情報を使用する {#use-encrypted-credentials}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108279)されました。

{{< /history >}}

サービスデスクメール認証情報を設定ファイルにプレーンテキストで保存する代わりに、受信メール認証情報に暗号化されたファイルを使用することもできます。

前提条件: 

- 暗号化された認証情報を使用するには、まず[暗号化設定](../../../administration/encrypted_configuration.md)を有効にする必要があります。

暗号化されたファイルでサポートされている設定項目は次のとおりです。

- `user`
- `password`

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. 最初に`/etc/gitlab/gitlab.rb`のサービスデスク設定が次のようであった場合:

   ```ruby
   gitlab_rails['service_desk_email_email'] = "service-desk-email@mail.example.com"
   gitlab_rails['service_desk_email_password'] = "examplepassword"
   ```

1. 暗号化されたシークレットを編集します。

   ```shell
   sudo gitlab-rake gitlab:service_desk_email:secret:edit EDITOR=vim
   ```

1. サービスデスクメールシークレットの暗号化されていないコンテンツを入力します:

   ```yaml
   user: 'service-desk-email@mail.example.com'
   password: 'examplepassword'
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、`email`および`password`に関する`service_desk`設定を削除します。
1. ファイルを保存し、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

Kubernetesシークレットを使用してサービスデスクメールパスワードを保存します。詳細については、[Helm IMAPシークレット](https://docs.gitlab.com/charts/installation/secrets/#imap-password-for-service-desk-emails)を参照してください。

{{< /tab >}}

{{< tab title="Docker" >}}

1. 最初に`docker-compose.yml`のサービスデスク設定が次のようであった場合:

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

1. コンテナ内に入り、暗号化されたシークレットを編集します。

   ```shell
   sudo docker exec -t <container_name> bash
   gitlab-rake gitlab:service_desk_email:secret:edit EDITOR=editor
   ```

1. サービスデスクシークレットの暗号化されていないコンテンツを入力します:

   ```yaml
   user: 'service-desk-email@mail.example.com'
   password: 'examplepassword'
   ```

1. `docker-compose.yml`を編集し、`email`および`password`に関する`service_desk`設定を削除します。
1. ファイルを保存し、GitLabを再起動します: 

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. 最初に`/home/git/gitlab/config/gitlab.yml`のサービスデスク設定が次のようであった場合:

   ```yaml
   production:
     service_desk_email:
       user: 'service-desk-email@mail.example.com'
       password: 'examplepassword'
   ```

1. 暗号化されたシークレットを編集します。

   ```shell
   bundle exec rake gitlab:service_desk_email:secret:edit EDITOR=vim RAILS_ENVIRONMENT=production
   ```

1. サービスデスクシークレットの暗号化されていないコンテンツを入力します:

   ```yaml
   user: 'service-desk-email@mail.example.com'
   password: 'examplepassword'
   ```

1. `/home/git/gitlab/config/gitlab.yml`を編集し、`user`および`password`に関する`service_desk_email:`設定を削除します。
1. ファイルを保存し、GitLabとMailroomを再起動します。

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

- GitLab 15.11で[自己コンパイル（ソース）インストール向けに導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116494)。

{{< /history >}}

`service_desk_email`は、IMAPの代わりにMicrosoft Graph APIを使用してMicrosoft Exchange Onlineメールボックスを読み取るように設定できます。Microsoft Graph用のOAuth 2.0アプリケーションを[受信メールと同じ方法](../../../administration/incoming_email.md#microsoft-graph)で設定します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、必要な値に置き換えて次の行を追加します。

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

   Microsoft Cloud for US Governmentまたは[その他のAzureデプロイ](https://learn.microsoft.com/en-us/graph/deployments)の場合、`azure_ad_endpoint`と`graph_endpoint`の設定を設定します。例: 

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

1. [OAuth 2.0アプリケーションクライアントシークレットを含むKubernetesシークレットを作成](https://docs.gitlab.com/charts/installation/secrets/#microsoft-graph-client-secret-for-service-desk-emails)します:

   ```shell
   kubectl create secret generic service-desk-email-client-secret --from-literal=secret=<YOUR-CLIENT_SECRET>
   ```

1. [GitLabサービスデスクメール認証トークン用のKubernetesシークレットを作成](https://docs.gitlab.com/charts/installation/secrets/#gitlab-service-desk-email-auth-token)します。GitLabインストールの[Helmリリース名](https://helm.sh/docs/intro/using_helm/)を`<name>`に置き換えます:

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

   Microsoft Cloud for US Governmentまたは[その他のAzureデプロイ](https://learn.microsoft.com/en-us/graph/deployments)の場合、`azureAdEndpoint`と`graphEndpoint`の設定を設定します。これらのフィールドは大文字と小文字を区別します:

   ```yaml
   global:
     appConfig:
     serviceDeskEmail:
       [..]
       azureAdEndpoint: https://login.microsoftonline.us
       graphEndpoint: https://graph.microsoft.us
       [..]
   ```

1. ファイルを保存し、新しい値を適用します: 

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

1. ファイルを保存し、GitLabを再起動します: 

   ```shell
   docker compose up -d
   ```

Microsoft Cloud for US Governmentまたは[その他のAzureデプロイ](https://learn.microsoft.com/en-us/graph/deployments)の場合、`azure_ad_endpoint`と`graph_endpoint`の設定を設定します:

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

1. ファイルを保存し、GitLabを再起動します: 

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

   Microsoft Cloud for US Governmentまたは[その他のAzureデプロイ](https://learn.microsoft.com/en-us/graph/deployments)の場合、`azure_ad_endpoint`と`graph_endpoint`の設定を設定します。例: 

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

プロジェクトのサービスデスク設定でカスタムサフィックスを設定できます。

サフィックスには、小文字（`a-z`）、数字（`0-9`）、またはアンダースコア（`_`）のみを含めることができます。

設定すると、カスタムサフィックスは`service_desk_email_address`の設定と`<project_full_path>-<custom_suffix>`の形式のキーで構成される新しいサービスデスクメールアドレスを作成します。

前提条件: 

- [サービスデスクエイリアスメールを設定](#configure-service-desk-alias-email)している必要があります。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **メールアドレスのサフィックス**の下に、使用するサフィックスを入力します。
1. **変更を保存**を選択します。

たとえば、`mygroup/myproject`プロジェクトのサービスデスク設定が次のように設定されているとします:

- メールアドレスサフィックスが`support`に設定されています。
- サービスデスクメールアドレスは`contact+%{key}@example.com`に設定されています。

このプロジェクトのサービスデスクメールアドレスは: `contact+mygroup-myproject-support@example.com`です。The [受信メール](../../../administration/incoming_email.md) address still works.

カスタムサフィックスを設定しない場合、プロジェクトの識別にデフォルトのプロジェクト識別が使用されます。

## マルチノード環境でのメール取り込みを設定する {#configure-email-ingestion-in-multi-node-environments}

マルチノード環境は、GitLabがスケーラビリティ、フォールトトレランス、およびパフォーマンスのために複数のサーバーで実行されるセットアップです。

GitLabは、`mail_room`と呼ばれる別のプロセスを使用して、`incoming_email`および`service_desk_email`のメールボックスから新しい未読メールをインジェストします。

### Helmチャート (Kubernetes) {#helm-chart-kubernetes}

[GitLab Helmチャート](https://docs.gitlab.com/charts/)は複数のサブチャートで構成されており、その1つが[Mailroomサブチャート](https://docs.gitlab.com/charts/charts/gitlab/mailroom/)です。[`incoming_email`の共通設定](https://docs.gitlab.com/charts/installation/command-line-options/#incoming-email-configuration)と[`service_desk_email`の共通設定](https://docs.gitlab.com/charts/installation/command-line-options/#service-desk-email-configuration)を設定します。

### Linuxパッケージ（Omnibus） {#linux-package-omnibus}

マルチノードLinuxパッケージインストール環境では、`mail_room`を1つのノードでのみ実行します。これを単一ノードの`rails`ノード（例: `application_role`）で実行するか、完全に個別に実行します。

#### すべてのノードを設定する {#set-up-all-nodes}

1. `incoming_email`と`service_desk_email`の基本設定をすべてのノードに追加して、Web UIと生成されたメールにメールアドレスを表示します。

   `/etc/gitlab/gitlab.rb`で`incoming_email`または`service_desk_email`セクションを見つけます:

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

1. GitLabは、`mail_room`からGitLabアプリケーションにメールを転送する2つの方法を提供します。各メール設定に対して`delivery_method`を個別に設定できます:
   1. 推奨: `webhook`（GitLab 15.3および以降のデフォルト）は、メールペイロードをAPI POSTリクエストとともにGitLabアプリケーションに送信します。共有トークンを使用して認証するします。この方法を選択する場合、`mail_room`プロセスがAPIエンドポイントにアクセスでき、共有トークンをすべてのアプリケーションノードに配布できることを確認してください。

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

   1. `webhook`のセットアップでイシューが発生した場合は、`sidekiq`を使用してメールペイロードをRedisを使用してGitLab Sidekiqに直接配信します。

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

1. メール取り込みを実行すべきではないすべてのノードで`mail_room`を無効にします。たとえば、`/etc/gitlab/gitlab.rb`で:

   ```ruby
   mailroom['enable'] = false
   ```

1. 変更を反映するために[GitLabを再設定](../../../administration/restart_gitlab.md)します。

#### 単一ノードのメール取り込みノードを設定する {#set-up-a-single-email-ingestion-node}

すべてのノードを設定し、`mail_room`プロセスを無効にした後、単一ノードで`mail_room`を有効にします。このノードは、定期的に`incoming_email`と`service_desk_email`のメールボックスをポーリングし、新しい未読メールをGitLabに移動します。

1. メール取り込みも処理する既存のノードを選択します。
1. `incoming_email`と`service_desk_email`の[完全な設定と認証情報](../../../administration/incoming_email.md#configuration-examples)を追加します。
1. このノードで`mail_room`を有効にします。たとえば、`/etc/gitlab/gitlab.rb`で:

   ```ruby
   mailroom['enable'] = true
   ```

1. 変更を有効にするために、このノードで[GitLabを再構成](../../../administration/restart_gitlab.md)します。
