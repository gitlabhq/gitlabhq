---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Switchboardのユーザーの管理と、SMTPメールサービス設定を含む、通知設定の構成を行います。
title: GitLab Dedicatedのユーザーと通知
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

スイッチボードにアクセスできるユーザーを管理し、GitLab Dedicatedインスタンスのメール通知を構成します。

## スイッチボードのユーザー管理 {#switchboard-user-management}

スイッチボードは、GitLab Dedicatedインスタンスを管理するための管理インターフェースです。スイッチボードのユーザーは、インスタンスを構成および監視できる管理者です。

{{< alert type="note" >}}

スイッチボードのユーザーは、GitLab Dedicatedインスタンスのユーザーとは異なります。スイッチボードとGitLab Dedicatedインスタンスの両方の認証の構成については、[GitLab Dedicatedの認証](authentication/_index.md)を参照してください。

{{< /alert >}}

### スイッチボードのユーザーの追加 {#add-switchboard-users}

管理者は、GitLab Dedicatedインスタンスを管理および表示するために、2種類のスイッチボードユーザーを追加できます:

- **Read only**（読み取り専用）: ユーザーは、インスタンスデータを表示することしかできません。
- **管理者**: ユーザーは、インスタンスの設定を編集し、ユーザーを管理できます。

GitLab Dedicatedインスタンスのスイッチボードに新しいユーザーを追加するには、次の手順に従います:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページの上部から、**ユーザー**を選択します。
1. **新規ユーザー**を選択します。
1. **メール**を入力し、ユーザーの**ロール**を選択します。
1. **作成**を選択します。

スイッチボードを使用するための招待状がユーザーに送信されます。

### パスワードのリセット {#reset-your-password}

スイッチボードのパスワードをリセットするには、次の手順に従います:

1. スイッチボードのサインインページで、メールアドレスを入力し、**次に進む**を選択します。
1. **パスワードをお忘れの場合**を選択します。
1. **Send verification code**（確認コードを送信） を選択します。
1. メールで確認コードを確認します。
1. 確認コードを入力し、**次に進む**を選択します。
1. 新しいパスワードを入力して確認します。
1. **パスワードを保存**を選択します。

パスワードがリセットされると、スイッチボードに自動的にサインインします。多要素認証（MFA）がアカウントに設定されている場合は、MFAの確認コードを入力するように求められます。

### 多要素認証のリセット {#reset-multi-factor-authentication}

スイッチボードのMFAをリセットするには、[サポートチケットを送信](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)してください。サポートチームが、アカウントへのアクセス権を取り戻すお手伝いをします。

## メール通知 {#email-notifications}

インスタンスのインシデント、メンテナンス、パフォーマンスの問題、セキュリティの更新に関するメール通知を受信します。

通知は以下に送信されます:

- スイッチボードのユーザー: 自身の通知設定に基づいて通知を受信します。
- 運用担当者: 通知設定に関係なく、重要なインスタンスイベントおよびサービスアップデートの通知を受信します。

運用担当者は、受信者が以下の場合でも、顧客通知を受信します:

- スイッチボードのユーザーではありません。
- スイッチボードにサインインしていません。
- メール通知をオフにします。

### 運用担当者のメールアドレスの管理 {#manage-email-addresses-for-operational-contacts}

運用担当者のメールアドレスを追加、編集、または削除するには、次の手順に従います:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページの上部にある**設定**を選択します。
1. **Contact information**（連絡先情報）を展開する。
1. **Operational email addresses**（運用メールアドレス）の下:
   - 新しいアドレスを追加するには、次の手順に従います:
     1. **メールアドレスを追加**を選択します。
     1. メールアドレスを入力します。
     1. **保存**を選択します。
   - 既存のアドレスを編集するには、次の手順に従います:
     1. アドレスの横にある鉛筆 ({{< icon name="pencil" >}}) を選択します。
     1. メールアドレスを編集します。
     1. **保存**を選択します。
   - アドレスを削除するには、次の手順に従います:
     1. アドレスの横にあるゴミ箱 ({{< icon name="remove" >}}) を選択します。
     1. 確認ダイアログで、**削除**を選択します。

### 通知設定の管理 {#manage-notification-preferences}

メール通知を受信するには、まず以下を行う必要があります:

- メールでの招待を受信し、スイッチボードにサインインします。
- パスワードと2要素認証（2要素認証）を設定します。

個人の通知をオンまたはオフにするには、次の手順に従います:

1. ユーザー名の横にあるドロップダウンリストを選択します。
1. **Toggle email notifications off**（メール通知をオフにする） または**Toggle email notifications on**（メール通知をオンにする）を選択します。

通知設定が更新されたことを確認するアラートが表示されます。

## SMTPメールサービス {#smtp-email-service}

GitLab Dedicatedインスタンスの[SMTP](../../../subscriptions/gitlab_dedicated/_index.md#email-service)メールサービスを構成できます。

SMTPメールサービスを構成するには、SMTPサーバーの認証情報と設定を記載した[サポートチケットを送信](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)してください。
