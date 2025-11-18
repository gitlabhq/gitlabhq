---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: 受信メール
description: 受信メールを設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabには、受信メールメッセージの受信に基づくいくつかの機能があります:

- [メールによる返信](reply_by_email.md)：GitLabユーザーがイシューとマージリクエストについて、通知メールに返信することでコメントできるようにします。
- [メールによるイシューの新規作成](../user/project/issues/create_issues.md#by-sending-an-email)：GitLabユーザーが、ユーザー固有のメールアドレスにメールを送信することで、新しいイシューを作成できるようにします。
- [メールによるマージリクエストの新規作成](../user/project/merge_requests/creating_merge_requests.md#by-sending-an-email)：GitLabユーザーが、ユーザー固有のメールアドレスにメールを送信することで、新しいマージリクエストを作成できるようにします。
- [サービスデスク](../user/project/service_desk/_index.md)：GitLabを介して、お客様にメールサポートを提供します。

## 要件 {#requirements}

GitLabインスタンス宛てのメッセージ**のみ**を受信するメールアドレスを使用することをお勧めします。GitLab宛てではない受信メールメッセージは、リジェクト通知を受け取ります。

受信メールメッセージの処理には、[IMAP](https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol)対応のメールアカウントが必要です。GitLabでは、次の3つの戦略のいずれかが必要です:

- メールのサブアドレス指定（推奨）
- すべてをキャッチするメールボックス
- 専用メールアドレス（メールによる返信のみをサポート）

これらのオプションについて、それぞれ説明します。

### メールのサブアドレス指定 {#email-sub-addressing}

[サブアドレス指定](https://en.wikipedia.org/wiki/Email_address#Sub-addressing)は、`user+arbitrary_tag@example.com`宛てのすべてのメールが`user@example.com`のメールボックスに届くメールサーバーの機能です。Gmail、Google Apps、Yahoo!などのプロバイダーでサポートされています。Mail、Outlook.com、iCloud、および[Postfixメールサーバー](reply_by_email_postfix_setup.md)（オンプレミスで実行可能）などがあります。Microsoft Exchange Serverは[サブアドレス指定をサポートしていません](#microsoft-exchange-server) 。また、Microsoft Office 365は[デフォルトでサブアドレス指定をサポートしていません](#microsoft-office-365)。

{{< alert type="note" >}}

プロバイダーまたはサーバーがメールのサブアドレス指定をサポートしている場合は、それを使用することをお勧めします。専用メールアドレスは、メールによる返信機能のみをサポートしています。すべてをキャッチするメールボックスはサブアドレス指定と同じ機能をサポートしますが、メールアドレスが1つしか使用されず、すべてをキャッチするメールボックスをGitLab以外の他の目的で使用できるため、サブアドレス指定が推奨されます。

{{< /alert >}}

### すべてをキャッチするメールボックス {#catch-all-mailbox}

ドメインの[すべてをキャッチするメールボックス](https://en.wikipedia.org/wiki/Catch-all)は、メールサーバーに存在するどのアドレスにも一致しない、そのドメイン宛てのすべてのメールメッセージを受信します。

すべてをキャッチするメールボックスはメールのサブアドレス指定と同じ機能をサポートしていますが、すべてをキャッチするメールボックスを他の目的に予約できるように、メールのサブアドレス指定が引き続き推奨されます。

### 専用メールアドレス {#dedicated-email-address}

このソリューションをセットアップするには、ユーザーからのGitLab通知への返信を受信する専用メールアドレスを作成する必要があります。ただし、この方法は返信のみをサポートし、受信メールの他の機能はサポートしません。

## 許可されるヘッダー {#accepted-headers}

{{< history >}}

- `Cc`ヘッダーの許可 (GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/348572))。
- `X-Original-To`ヘッダーの許可 (GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149874))。
- `X-Forwarded-To`ヘッダーの許可 (GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168716))。
- `X-Delivered-To`ヘッダーの許可 (GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170221))。

{{< /history >}}

設定されたメールアドレスが次のヘッダーのいずれかに存在する場合、メールは正しく処理されます（チェックされる順にソート）:

- `To`
- `Delivered-To`
- `X-Delivered-To`
- `Envelope-To`または`X-Envelope-To`
- `Received`
- `X-Original-To`
- `X-Forwarded-To`
- `Cc`

`References`ヘッダーも許可されますが、これは特に既存のディスカッションスレッドにメールの返信を関連付けるために使用されます。これは、メールによるイシューの作成には使用されません。

GitLab 14.6以降では、[サービスデスク](../user/project/service_desk/_index.md)も許可されるヘッダーをチェックします。

通常、`To`フィールドには、プライマリ受信者のメールアドレスが含まれています。ただし、次の場合、設定されたGitLabメールアドレスが含まれていない可能性があります:

- アドレスが`BCC`フィールドにある。
- メールが転送された。

`Received`ヘッダーには、複数のメールアドレスを含めることができます。これらは、表示される順にチェックされます。最初の一致が使用されます。

## 拒否されたヘッダー {#rejected-headers}

自動メールシステムからの不要なイシュー作成を防ぐため、GitLabは次のヘッダーを含むすべての受信メールを無視します:

- `Auto-Submitted`（`no`以外の値）。
- `X-Autoreply`（`yes`の値）。

## セットアップ {#set-it-up}

受信メールにGmail / Google Appsを使用する場合は、[IMAPアクセスが有効](https://support.google.com/mail/answer/7126229)になっていること、[安全性の低いアプリからのアカウントへのアクセスを許可](https://support.google.com/accounts/answer/6010255)していること、または[2段階認証をオン](https://support.google.com/accounts/answer/185839)にして、[アプリケーションパスワード](https://support.google.com/mail/answer/185833)を使用していることを確認してください。

Office 365を使用し、2要素認証が有効になっている場合は、メールボックスの通常のパスワードの代わりに[アプリパスワード](https://support.microsoft.com/en-us/account-billing/app-passwords-for-a-work-or-school-account-d6dc8c6d-4bf7-4851-ad95-6d07799387e9)を使用していることを確認してください。

UbuntuでIMAPアクセスを使用して基本的なPostfixメールサーバーをセットアップするには、[Postfixセットアップドキュメント](reply_by_email_postfix_setup.md)に従ってください。

### セキュリティに関する懸念: {#security-concerns}

{{< alert type="warning" >}}

受信メールの受信に使用するドメインを選択する際は注意してください。

{{< /alert >}}

たとえば、最上位の会社のドメインが`hooli.com`であるとします。社内のすべての従業員は、Google Workspaceを介してそのドメインにメールアドレスを持っており、会社のプライベートSlackインスタンスにサインアップするには、有効な`@hooli.com`メールアドレスが必要です。

`hooli.com`で公開されているGitLabインスタンスもホストし、受信メールドメインを`hooli.com`に設定すると、攻撃者がSlackにサインアップするときにプロジェクト固有のアドレスをメールとして使用して、メールによるイシューの新規作成または[メールによるマージリクエストの新規作成](../user/project/merge_requests/creating_merge_requests.md#by-sending-an-email)機能を悪用する可能性があります。これにより確認メールが送信され、攻撃者が所有するプロジェクトに新しいイシューまたはマージリクエストが作成され、確認リンクを選択して会社のプライベートSlackインスタンスでアカウントを検証できるようになります。

`incoming.hooli.com`のようなサブドメインで受信メールを受信し、`*.hooli.com.`のようなメールアドレスへのアクセスのみに基づいて認証するサービスを使用しないようにすることをお勧めします。または、`hooli-gitlab.com`のようなGitLabメール通信専用のドメインを使用します。

この悪用の実例については、GitLabイシュー[\#30366](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30366)を参照してください。

{{< alert type="warning" >}}

スパムを減らすように構成されたメールサーバーを使用してください。たとえば、デフォルト設定で実行されているPostfixメールサーバーは、悪用につながる可能性があります。構成されたメールボックスで受信したすべてのメッセージが処理され、GitLabインスタンス宛てではないメッセージはリジェクト通知を受け取ります。送信者のアドレスがスプーフィングされている場合、リジェクト通知はスプーフィングされた`FROM`アドレスに配信され、メールサーバーのIPまたはドメインがブロックリストに表示される可能性があります。

{{< /alert >}}

{{< alert type="warning" >}}

ユーザーは、最初に認証するために2要素認証（2FA）を使用しなくても、受信メール機能を使用できます。これは、インスタンスに対して[強制2要素認証](../security/two_factor_authentication.md)を有効にしている場合でも当てはまります。{{< /alert >}}

### Linuxパッケージインストール {#linux-package-installations}

1. `/etc/gitlab/gitlab.rb`の`incoming_email`セクションを見つけて機能を有効にし、特定のIMAPサーバーとメールアカウントの詳細を入力します（以下の[例](#configuration-examples)を参照）。

1. 変更を有効にするには、GitLabを再設定してください:

   ```shell
   sudo gitlab-ctl reconfigure

   # Needed when enabling or disabling for the first time but not for password changes.
   # See https://gitlab.com/gitlab-org/gitlab-foss/-/issues/23560#note_61966788
   sudo gitlab-ctl restart
   ```

1. すべてが正しく設定されていることを検証します:

   ```shell
   sudo gitlab-rake gitlab:incoming_email:check
   ```

メールによる返信が機能するはずです。

### 自己コンパイルによるインストール {#self-compiled-installations}

1. GitLabインストールディレクトリに移動します:

   ```shell
   cd /home/git/gitlab
   ```

1. `gitlab-mail_room` gemを手動でインストールします:

   ```shell
   gem install gitlab-mail_room
   ```

   {{< alert type="note" >}}

   この手順は、スレッドのデッドロックを回避し、最新のMailRoom機能をサポートするために必要です。

   {{< /alert >}}

1. `config/gitlab.yml`の`incoming_email`セクションを見つけて機能を有効にし、特定のIMAPサーバーとメールアカウントの詳細を入力します（以下の[例](#configuration-examples)を参照）。

systemdユニットを使用してGitLabを管理する場合は、次のようにします:

1. `gitlab-mailroom.service`を`gitlab.target`への依存関係として追加します:

   ```shell
   sudo systemctl edit gitlab.target
   ```

   開いたエディタで、以下を追加してファイルを保存します:

   ```plaintext
   [Unit]
   Wants=gitlab-mailroom.service
   ```

1. RedisとPostgreSQLを同じマシンで実行する場合は、Redisへの依存関係を追加する必要があります。以下を実行します:

   ```shell
   sudo systemctl edit gitlab-mailroom.service
   ```

   開いたエディタで、以下を追加してファイルを保存します:

   ```plaintext
   [Unit]
   Wants=redis-server.service
   After=redis-server.service
   ```

1. `gitlab-mailroom.service`を起動します:

   ```shell
   sudo systemctl start gitlab-mailroom.service
   ```

1. すべてが正しく設定されていることを検証します:

   ```shell
   sudo -u git -H bundle exec rake gitlab:incoming_email:check RAILS_ENV=production
   ```

SysV initスクリプトを使用してGitLabを管理する場合は、次のようにします:

1. `/etc/default/gitlab`のinitスクリプトで`mail_room`を有効にします:

   ```shell
   sudo mkdir -p /etc/default
   echo 'mail_room_enabled=true' | sudo tee -a /etc/default/gitlab
   ```

1. GitLabを再起動します:

   ```shell
   sudo service gitlab restart
   ```

1. すべてが正しく設定されていることを検証します:

   ```shell
   sudo -u git -H bundle exec rake gitlab:incoming_email:check RAILS_ENV=production
   ```

メールによる返信が機能するはずです。

### 設定例 {#configuration-examples}

#### Postfix {#postfix}

Postfixメールサーバーの構成例。メールボックス`incoming@gitlab.example.com`を想定しています。

Linuxパッケージのインストールの例:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@gitlab.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming+%{key}@gitlab.example.com"

# Email account username
# With third party providers, this is usually the full email address.
# With self-hosted email servers, this is usually the user part of the email address.
gitlab_rails['incoming_email_email'] = "incoming"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "gitlab.example.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 143
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = false
# Whether the IMAP server uses StartTLS
gitlab_rails['incoming_email_start_tls'] = false

# The mailbox where incoming mail will end up. Usually "inbox".
gitlab_rails['incoming_email_mailbox_name'] = "inbox"
# The IDLE command timeout.
gitlab_rails['incoming_email_idle_timeout'] = 60

# If you are using Microsoft Graph instead of IMAP, set this to false to retain
# messages in the inbox because deleted messages are auto-expunged after some time.
gitlab_rails['incoming_email_delete_after_delivery'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
# Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
gitlab_rails['incoming_email_expunge_deleted'] = true
```

セルフコンパイルインストールの例:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@gitlab.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    address: "incoming+%{key}@gitlab.example.com"

    # Email account username
    # With third party providers, this is usually the full email address.
    # With self-hosted email servers, this is usually the user part of the email address.
    user: "incoming"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "gitlab.example.com"
    # IMAP server port
    port: 143
    # Whether the IMAP server uses SSL
    ssl: false
    # Whether the IMAP server uses StartTLS
    start_tls: false

    # The mailbox where incoming mail will end up. Usually "inbox".
    mailbox: "inbox"
    # The IDLE command timeout.
    idle_timeout: 60

    # If you are using Microsoft Graph instead of IMAP, set this to false to retain
    # messages in the inbox because deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    # Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
    expunge_deleted: true
```

#### Gmail {#gmail}

Gmail / Google Workspaceの構成例。メールボックス`gitlab-incoming@gmail.com`を想定しています。

{{< alert type="note" >}}

`incoming_email_email`はGmailエイリアスアカウントにできません。

{{< /alert >}}

Linuxパッケージのインストールの例:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@gmail.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "gitlab-incoming+%{key}@gmail.com"

# Email account username
# With third party providers, this is usually the full email address.
# With self-hosted email servers, this is usually the user part of the email address.
gitlab_rails['incoming_email_email'] = "gitlab-incoming@gmail.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "imap.gmail.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true
# Whether the IMAP server uses StartTLS
gitlab_rails['incoming_email_start_tls'] = false

# The mailbox where incoming mail will end up. Usually "inbox".
gitlab_rails['incoming_email_mailbox_name'] = "inbox"
# The IDLE command timeout.
gitlab_rails['incoming_email_idle_timeout'] = 60

# If you are using Microsoft Graph instead of IMAP, set this to false if you want to retain
# messages in the inbox because deleted messages are auto-expunged after some time.
gitlab_rails['incoming_email_delete_after_delivery'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
# Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
gitlab_rails['incoming_email_expunge_deleted'] = true
```

セルフコンパイルインストールの例:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@gmail.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    address: "gitlab-incoming+%{key}@gmail.com"

    # Email account username
    # With third party providers, this is usually the full email address.
    # With self-hosted email servers, this is usually the user part of the email address.
    user: "gitlab-incoming@gmail.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "imap.gmail.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true
    # Whether the IMAP server uses StartTLS
    start_tls: false

    # The mailbox where incoming mail will end up. Usually "inbox".
    mailbox: "inbox"
    # The IDLE command timeout.
    idle_timeout: 60

    # If you are using Microsoft Graph instead of IMAP, set this to falseto retain
    # messages in the inbox because deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    # Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
    expunge_deleted: true
```

#### Microsoft Exchange Server {#microsoft-exchange-server}

IMAPが有効になっているMicrosoft Exchange Serverの構成例。Exchangeはサブアドレス指定をサポートしていないため、次の2つのオプションのみが存在します:

- [すべてをキャッチするメールボックス](#catch-all-mailbox)（Exchange専用に推奨）
- [専用メールアドレス](#dedicated-email-address)（メールによる返信のみをサポート）

##### すべてをキャッチするメールボックス {#catch-all-mailbox-1}

すべてをキャッチするメールボックス`incoming@exchange.example.com`を想定しています。

Linuxパッケージのインストールの例:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress-%{key}@exchange.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
# Exchange does not support sub-addressing, so a catch-all mailbox must be used.
gitlab_rails['incoming_email_address'] = "incoming-%{key}@exchange.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@ad-domain.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "exchange.example.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
# Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
gitlab_rails['incoming_email_expunge_deleted'] = true
```

セルフコンパイルインストールの例:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress-%{key}@exchange.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    # Exchange does not support sub-addressing, so a catch-all mailbox must be used.
    address: "incoming-%{key}@exchange.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@ad-domain.example.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "exchange.example.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # If you are using Microsoft Graph instead of IMAP, set this to false to retain
    # messages in the inbox because deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

##### 専用メールアドレス {#dedicated-email-address-1}

{{< alert type="note" >}}

[メールによる返信](reply_by_email.md)のみをサポートします。[サービスデスク](../user/project/service_desk/_index.md)をサポートできません。

{{< /alert >}}

専用メールアドレス`incoming@exchange.example.com`を想定しています。

Linuxパッケージのインストールの例:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# Exchange does not support sub-addressing, and we're not using a catch-all mailbox so %{key} is not used here
gitlab_rails['incoming_email_address'] = "incoming@exchange.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@ad-domain.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "exchange.example.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

セルフコンパイルインストールの例:

```yaml
incoming_email:
    enabled: true

    # Exchange does not support sub-addressing,
    # and we're not using a catch-all mailbox so %{key} is not used here
    address: "incoming@exchange.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@ad-domain.example.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "exchange.example.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # If you are using Microsoft Graph instead of IMAP, set this to false to retain
    # messages in the inbox because deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

#### Microsoft Office 365 {#microsoft-office-365}

IMAPが有効になっているMicrosoft Office 365の構成例。

##### サブアドレス指定メールボックス {#sub-addressing-mailbox}

{{< alert type="note" >}}

2020年9月以降、サブアドレス指定のサポートが[Office 365に追加されました](https://support.microsoft.com/en-us/office/uservoice-pages-430e1a78-e016-472a-a10f-dc2a3df3450a)。この機能はデフォルトでは有効になっておらず、PowerShellを使用して有効にする必要があります。

{{< /alert >}}

この一連のPowerShellコマンドは、Office 365の組織レベルで[サブアドレス指定](#email-sub-addressing)を有効にします。これにより、組織内のすべてのメールボックスがサブアドレス指定されたメールを受信できるようになります。

サブアドレス指定を有効にするには:

1. [PowerShellギャラリー](https://www.powershellgallery.com/packages/ExchangeOnlineManagement/3.7.1)から`ExchangeOnlineManagement`モジュールをダウンロードしてインストールします。
1. PowerShellで、次のコマンドを実行します:

   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   Import-Module ExchangeOnlineManagement
   Connect-ExchangeOnline
   Set-OrganizationConfig -DisablePlusAddressInRecipients $false
   Disconnect-ExchangeOnline
   ```

このLinuxパッケージインストールの例では、メールボックス`incoming@office365.example.com`を想定しています:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@office365.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming+%{key}@office365.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@office365.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "outlook.office365.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

このセルフコンパイルインストールの例では、メールボックス`incoming@office365.example.com`を想定しています:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@office365.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    address: "incoming+%{key}@office365.example.comm"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@office365.example.comm"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "outlook.office365.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

##### すべてをキャッチするメールボックス {#catch-all-mailbox-2}

このLinuxパッケージインストールの例では、すべてをキャッチするメールボックス`incoming@office365.example.com`を想定しています:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress-%{key}@office365.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming-%{key}@office365.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@office365.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "outlook.office365.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

このセルフコンパイルインストールの例では、すべてをキャッチするメールボックス`incoming@office365.example.com`を想定しています:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@office365.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    address: "incoming-%{key}@office365.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@ad-domain.example.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "outlook.office365.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

##### 専用メールアドレス {#dedicated-email-address-2}

{{< alert type="note" >}}

[メールによる返信](reply_by_email.md)のみをサポートします。[サービスデスク](../user/project/service_desk/_index.md)をサポートできません。

{{< /alert >}}

このLinuxパッケージインストールの例では、専用メールアドレス`incoming@office365.example.com`を想定しています:

```ruby
gitlab_rails['incoming_email_enabled'] = true

gitlab_rails['incoming_email_address'] = "incoming@office365.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@office365.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "outlook.office365.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

このセルフコンパイルインストールの例では、専用メールアドレス`incoming@office365.example.com`を想定しています:

```yaml
incoming_email:
    enabled: true

    address: "incoming@office365.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@office365.example.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "outlook.office365.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

#### Microsoft Graph {#microsoft-graph}

GitLabは、IMAPの代わりにMicrosoft Graph APIを使用して受信メールを読み取りできます。[MicrosoftがBasic認証でのIMAPの使用を非推奨にしている](https://techcommunity.microsoft.com/blog/exchange/announcing-oauth-2-0-support-for-imap-and-smtp-auth-protocols-in-exchange-online/1330432)ため、新しいMicrosoft Exchange OnlineメールボックスにはMicrosoft Graph APIが必要になります。

Microsoft Graph用にGitLabを構成するには、すべてのメールボックスに対する`Mail.ReadWrite`権限を持つOAuth 2.0アプリケーションをAzure Activeディレクトリに登録する必要があります。詳細については、[MailRoomステップバイステップガイド](https://github.com/tpitale/mail_room/#microsoft-graph-configuration)および[Microsoftの説明](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)を参照してください。

OAuth 2.0アプリケーションを構成するときは、以下を記録してください:

- Azure ActiveディレクトリのテナントID
- OAuth 2.0アプリケーションのクライアントID
- OAuth 2.0アプリケーションのクライアントのシークレットキー

##### メールボックスアクセスの制限 {#restrict-mailbox-access}

MailRoomをサービスアカウントとして機能させるには、Azure Activeディレクトリに作成するアプリケーションで、すべてのメールボックスでメールを読み取り/書き込みするための`Mail.ReadWrite`プロパティを設定する必要があります。

セキュリティ上の懸念を軽減するために、[Microsoftドキュメント](https://learn.microsoft.com/en-us/graph/auth-limit-mailbox-access)で説明されているように、すべてのアカウントのメールボックスアクセスを制限するアプリケーションアクセスポリシーを構成することをお勧めします。

このLinuxパッケージインストールの例では、次のメールボックスを使用していることを前提としています：`incoming@example.onmicrosoft.com`:

##### Microsoft Graphを設定する {#configure-microsoft-graph}

{{< history >}}

- Azureの代替デプロイ（GitLab 14.9で[導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5978)）。

{{< /history >}}

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@example.onmicrosoft.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming+%{key}@example.onmicrosoft.com"

# Email account username
gitlab_rails['incoming_email_email'] = "incoming@example.onmicrosoft.com"
gitlab_rails['incoming_email_delete_after_delivery'] = false

gitlab_rails['incoming_email_inbox_method'] = 'microsoft_graph'
gitlab_rails['incoming_email_inbox_options'] = {
   'tenant_id': '<YOUR-TENANT-ID>',
   'client_id': '<YOUR-CLIENT-ID>',
   'client_secret': '<YOUR-CLIENT-SECRET>',
   'poll_interval': 60  # Optional
}
```

米国政府機関向けMicrosoft Cloudまたは[他のAzureデプロイ](https://learn.microsoft.com/en-us/graph/deployments)の場合は、`azure_ad_endpoint`および`graph_endpoint`設定を構成します。

- 米国政府機関向けMicrosoft Cloudの例:

```ruby
gitlab_rails['incoming_email_inbox_options'] = {
   'azure_ad_endpoint': 'https://login.microsoftonline.us',
   'graph_endpoint': 'https://graph.microsoft.us',
   'tenant_id': '<YOUR-TENANT-ID>',
   'client_id': '<YOUR-CLIENT-ID>',
   'client_secret': '<YOUR-CLIENT-SECRET>',
   'poll_interval': 60  # Optional
}
```

Microsoft Graph APIは、セルフコンパイルインストールではまだサポートされていません。詳細については、[こちらのイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/326169)を参照してください。

### 暗号化された認証情報を使用する {#use-encrypted-credentials}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108279)されました。

{{< /history >}}

受信認証情報を設定ファイルに平文で保存する代わりに、オプションで暗号化されたファイルを使用することもできます。

前提要件: 

- 暗号化された認証情報を使用するには、まず[暗号化設定](encrypted_configuration.md)を有効にする必要があります。

暗号化されたファイルでサポートされている設定項目は次のとおりです:

- `user`
- `password`

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. 最初に`/etc/gitlab/gitlab.rb`の受信メール構成が次のようになっている場合:

   ```ruby
   gitlab_rails['incoming_email_email'] = "incoming-email@mail.example.com"
   gitlab_rails['incoming_email_password'] = "examplepassword"
   ```

1. 暗号化されたシークレットを編集します:

   ```shell
   sudo gitlab-rake gitlab:incoming_email:secret:edit EDITOR=vim
   ```

1. 受信メールシークレットの暗号化されていない内容を入力します:

   ```yaml
   user: 'incoming-email@mail.example.com'
   password: 'examplepassword'
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、`incoming_email`の`email`と`password`の設定を削除します。
1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

Kubernetesシークレットを使用して、受信メールパスワードを格納します。詳細については、[Helm IMAPシークレット](https://docs.gitlab.com/charts/installation/secrets.html#imap-password-for-incoming-emails)を参照してください。

{{< /tab >}}

{{< tab title="Docker" >}}

1. 最初に`docker-compose.yml`の受信メール構成が次のようになっている場合:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['incoming_email_email'] = "incoming-email@mail.example.com"
           gitlab_rails['incoming_email_password'] = "examplepassword"
   ```

1. コンテナ内に入り、暗号化されたシークレットを編集します:

   ```shell
   sudo docker exec -t <container_name> bash
   gitlab-rake gitlab:incoming_email:secret:edit EDITOR=editor
   ```

1. 受信メールシークレットの暗号化されていない内容を入力します:

   ```yaml
   user: 'incoming-email@mail.example.com'
   password: 'examplepassword'
   ```

1. `docker-compose.yml`を編集し、`incoming_email`の`email`と`password`の設定を削除します。
1. ファイルを保存して、GitLabを再起動します:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. 最初に`/home/git/gitlab/config/gitlab.yml`の受信メール構成が次のようになっている場合:

   ```yaml
   production:
     incoming_email:
       user: 'incoming-email@mail.example.com'
       password: 'examplepassword'
   ```

1. 暗号化されたシークレットを編集します:

   ```shell
   bundle exec rake gitlab:incoming_email:secret:edit EDITOR=vim RAILS_ENVIRONMENT=production
   ```

1. 受信メールシークレットの暗号化されていない内容を入力します:

   ```yaml
   user: 'incoming-email@mail.example.com'
   password: 'examplepassword'
   ```

1. `/home/git/gitlab/config/gitlab.yml`を編集し、`incoming_email:`の`user`と`password`の設定を削除します。
1. ファイルを保存してGitLabとMailroomを再起動します

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## トラブルシューティング {#troubleshooting}

### 16.6.0でメールの取り込みが機能しない {#email-ingestion-doesnt-work-in-1660}

GitLab 16.6では、リグレッションにより、`mail_room`（メールの取り込み）が起動しません。サービスデスクやその他のメールによる返信機能は動作しません。このイシューは16.6.1で修正されました。詳細については、[432257のイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/432257)を参照してください。

この回避策では、影響を受けるファイルをパッチするために、GitLabインストールで次のコマンドを実行します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
curl --output /tmp/mailroom.patch --url "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137279.diff"
patch -p1 -d /opt/gitlab/embedded/service/gitlab-rails < /tmp/mailroom.patch
gitlab-ctl restart mailroom
```

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
curl --output /tmp/mailroom.patch --url "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137279.diff"
cd /opt/gitlab/embedded/service/gitlab-rails
patch -p1 < /tmp/mailroom.patch
gitlab-ctl restart mailroom
```

{{< /tab >}}

{{< /tabs >}}

### メールアドレス制限のあるプロバイダーによって受信メールが拒否される {#incoming-emails-are-rejected-by-providers-with-email-address-limit}

一部のメールプロバイダーでは、メールアドレスのローカル部分（`@`の前）に64文字の制限が課せられているため、GitLabインスタンスが受信メールを受信しない可能性があります。この制限を超えるアドレスからのすべてのメールは、拒否されたメールです。

回避策として、短いパスを維持してください:

- `incoming_email_address`の`%{key}`の前に構成されたローカル部分が、できるだけ短く、31文字を超えないようにしてください。
- 指定されたプロジェクトを、より高いグループ階層に配置します。
- [グループ](../user/group/manage.md#change-a-groups-path)と[プロジェクト](../user/project/working_with_projects.md#rename-a-repository)の名前をより短い名前に変更します。

[460206のイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/460206)でこの機能を追跡する。
