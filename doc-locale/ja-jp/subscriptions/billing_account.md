---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 請求先アカウントのデータと支払い方法を変更し、請求書の支払いを行い、GitLabアカウントをGitLabカスタマーポータルにリンクします。
title: 請求先アカウントを管理する
---

GitLabカスタマーポータルは、[GitLabサブスクリプションの管理](manage_subscription.md)と請求を行うための包括的なセルフサービスハブです。GitLab製品の購入、サブスクリプションライフサイクル全体のサブスクリプション管理、請求書の表示と支払い、請求の詳細と連絡先情報へのアクセスが可能です。

認定リセラー経由で購入した場合、サブスクリプションの変更はリセラーに直接依頼する必要があります。詳細については、[リセラー経由で購入したお客様](#subscription-purchased-through-a-reseller)を参照してください。

## GitLabカスタマーポータルにサインインする {#sign-in-to-customers-portal}

GitLabカスタマーポータルには、GitLab.comアカウントまたはメールに送信されるワンタイム[GitLabカスタマーポータルアカウントをGitLab.comアカウントにリンク](#link-a-gitlabcom-account)を使用してサインインできます。

{{< alert type="note" >}}

GitLab.comアカウントでGitLabカスタマーポータルに登録した場合は、このアカウントでサインインする。

{{< /alert >}}

GitLab.comアカウントを使用してGitLabカスタマーポータルにサインインする方法:

1. [カスタマーポータル](https://customers.gitlab.com/customers/sign_in)に移動します。
1. **Continue with GitLab.com account**（GitLab.comアカウントで続行） を選択します。

メールを使用してGitLabカスタマーポータルにサインインする方法と、ワンタイムサインインリンクを受け取る方法:

1. [カスタマーポータル](https://customers.gitlab.com/customers/sign_in)に移動します。
1. **Sign in with your email**（メールでサインイン）を選択します。
1. GitLabカスタマーポータルプロフィールの**メール**を入力します。ワンタイムサインインリンクが記載されたメールが届きます。
1. 受信したメールで、**サインインする**を選択します。

{{< alert type="note" >}}

ワンタイムサインインリンクは24時間で失効し、1回のみ使用できます。

{{< /alert >}}

## GitLabカスタマーポータルのメールアドレスを確認 {#confirm-customers-portal-email-address}

ワンタイムサインインリンクを使用してGitLabカスタマーポータルに初めてサインインするときは、GitLabカスタマーポータルへのアクセスを維持するために、メールアドレスを確認する必要があります。GitLab.comからGitLabカスタマーポータルにサインインする場合、メールアドレスを確認する必要はありません。

プロフィールのメールアドレスの更新も確認する必要があります。確認方法に関する手順が記載された自動メールが届きます。必要に応じて[再送信](https://customers.gitlab.com/customers/confirmation/new)できます。

## プロファイルオーナー情報の変更 {#change-profile-owner-information}

プロファイルオーナーのメールアドレスは、[GitLabカスタマーポータルの従来のサインイン](#sign-in-to-customers-portal)に使用されます。プロファイルオーナーが[請求先アカウントマネージャー](#subscription-and-billing-contacts)でもある場合、その個人の詳細が請求書、ライセンス、サブスクリプション関連のメールに使用されます。

名前やメールアドレスなど、プロフィールの詳細を変更するには:

1. [GitLabカスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインする。
1. **My profile**（自分のプロフィール） > **Profile settings**（プロフィールの設定）を選択します。
1. **Your personal details**（個人情報を編集）します。
1. **変更を保存**を選択します。

## 会社情報の変更 {#change-your-company-details}

会社名や納税者番号など、会社情報を変更するには:

1. [GitLabカスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインする。
1. **Billing account settings**（請求先アカウント設定）を選択します。
1. **Company information**（会社情報）セクションまでスクロールダウンします。
1. 会社情報を編集します。
1. **変更を保存**を選択します。

## サブスクリプションと請求に関する連絡先 {#subscription-and-billing-contacts}

サブスクリプション管理に関与するユーザーは、サブスクリプションに対する権限レベルと表示レベルが異なる3つの異なるロールを持つことができます:

- 課金アカウントマネージャー: サブスクリプション、支払い方法、および請求先アカウントの設定を表示および編集するためのアクセス権があります。請求書の支払いとダウンロード、およびリストされているすべての請求先アカウントマネージャーへのサブスクリプション連絡先の更新が可能です。
- サブスクリプション連絡先（または「販売先」連絡先）: 請求先アカウントのサブスクリプションオーナーであり、主要な連絡先です。サブスクリプションイベントに関する通知と、サブスクリプションの適用に関する情報を受信します。このロールは、デフォルトでは請求先アカウントマネージャーでもあります。
- 請求連絡先（または「請求先」連絡先）: すべての請求書とサブスクリプションイベントに関する通知を受信します。このロールが請求先アカウントマネージャーでもある場合を除き、サブスクリプションへのアクセス権を持つGitLabカスタマーポータルアカウントを持っていません。

1人のユーザーが3つのロールすべてを持つことができます。

### サブスクリプション連絡先の変更 {#change-your-subscription-contact}

サブスクリプション連絡先を変更するには:

1. [GitLabカスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインする。
1. 左側のサイドバーで、**Billing account settings**（請求先アカウント設定）を選択します。
1. **Company information**（会社情報）セクションまでスクロールし、**Subscription contact**（サブスクリプション連絡先）までスクロールします。
1. 別のサブスクリプション連絡先を選択するには、**Billing account manager**（請求先アカウントマネージャー）ドロップダウンリストから選択します。
1. 連絡先の詳細を編集します。
1. **変更を保存**を選択します。

### 課金アカウントマネージャーを追加 {#add-a-billing-account-manager}

アカウントに別の請求先アカウントマネージャーを追加するには:

1. 追加するユーザーの[GitLabカスタマーポータル](https://customers.gitlab.com/customers/sign_in)にアカウントが存在することを確認します。
1. [GitLabカスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインする。
1. 左側のサイドバーで、**Billing account settings**（請求先アカウント設定）を選択します。
1. **Billing account managers**（請求先アカウントマネージャー）セクションまでスクロールします。
1. **Invite billing account manager**（請求先アカウントマネージャーを招待）を選択します。
1. 追加するユーザーのメールアドレスを入力します。
1. **招待**を選択します。

招待されたユーザーは、GitLabカスタマーポータルへの招待状が記載されたメールを受信します。招待は7日間有効です。ユーザーが有効期限が切れる前に招待を承諾しない場合、新しい招待を送信できます。一度に最大15件の保留中の招待状を送信できます。

### 請求先アカウントマネージャーの削除 {#remove-a-billing-account-manager}

アカウントから請求先アカウントマネージャーはいつでも削除できます。請求先アカウントマネージャーを削除すると、請求先アカウント情報を表示または編集できなくなります。

請求先アカウントマネージャーを削除するには:

1. [GitLabカスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインする。
1. 左側のサイドバーで、**Billing account settings**（請求先アカウント設定）を選択します。
1. **Billing account managers**（請求先アカウントマネージャー）セクションまでスクロールします。
1. リストで、削除する請求先アカウントマネージャーの横にある**削除**を選択します。
1. 確認ダイアログで、**削除**を選択してアクションを確定します。

### 請求先アカウントマネージャーの招待の失効する {#revoke-a-billing-account-manager-invitation}

まだ承諾されていない招待は失効することができます。招待されたものの、まだ招待を承諾していないユーザーには、**Awaiting user registration**（ユーザー登録を待機中）という名前が表示されます。

招待を失効するには:

1. [GitLabカスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインする。
1. 左側のサイドバーで、**Billing account settings**（請求先アカウント設定）を選択します。
1. **Billing account managers**（請求先アカウントマネージャー）セクションまでスクロールします。
1. リストで、**Awaiting user registration**（ユーザー登録を待機中）という名前の招待されたユーザーの横にある**削除**を選択します。
1. 確認ダイアログで、**削除**を選択して招待を削除します。

### 請求先連絡先の変更 {#change-your-billing-contact}

請求先連絡先は、すべての請求書とサブスクリプションイベントの通知を受信します。

請求先連絡先を変更するには:

1. [GitLabカスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインする。
1. 左側のサイドバーで、**Billing account settings**（請求先アカウント設定）を選択します。
1. **Company information**（会社情報）セクションまでスクロールし、**Billing contact**（請求先連絡先）までスクロールします。

   - 請求先連絡先をサブスクリプション連絡先と同一にするには:

     1. **Billing contact is the same as subscription contact**（請求先連絡先はサブスクリプション連絡先と同じです）を選択します。
     1. **変更を保存**を選択します。

   - 請求先連絡先を別の請求先アカウントマネージャーに変更するには:

     1. **Billing contact is the same as subscription contact**（請求先連絡先はサブスクリプション連絡先と同じです）チェックボックスをオフにします。
     1. **ユーザー**ドロップダウンリストから別の請求先アカウントマネージャーを選択します。
     1. 連絡先の詳細を編集します。
     1. **変更を保存**を選択します。

   - 請求先連絡先をカスタム連絡先と同一にするには:

     1. **Billing contact is the same as subscription contact**（請求先連絡先はサブスクリプション連絡先と同じです）チェックボックスをオフにします。
     1. **Enter a custom contact**（User）ドロップダウンリストから**ユーザー**を選択します。
     1. 連絡先の詳細を入力します。
     1. **変更を保存**を選択します。

## 支払い方法の変更 {#change-your-payment-method}

GitLabカスタマーポータルでの購入では、支払い方法としてクレジットカードが登録されている必要があります。アカウントに複数のクレジットカードを追加して、異なる製品の購入代金を正しいカードに請求することができます。

別の支払い方法を使用する場合は、[セールスチームにお問い合わせください](https://customers.gitlab.com/contact_us)。

支払い方法を変更するには:

1. [GitLabカスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインする。
1. 左側のサイドバーで、**Billing account settings**（請求先アカウント設定）を選択します。
1. 既存の支払い方法の情報を**編集**するか、**新しい支払い方法の追加**を追加します。
1. **変更を保存**を選択します。

### デフォルトの支払い方法の設定 {#set-a-default-payment-method}

サブスクリプションの自動更新は、デフォルトの支払い方法で請求されます。支払い方法をデフォルトとしてマークするには:

1. [GitLabカスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインする。
1. 左側のサイドバーで、**Billing account settings**（請求先アカウント設定）を選択します。
1. 選択した支払い方法を**編集**し、**Make default payment method**（デフォルトの支払い方法にする）チェックボックスを選択します。
1. **変更を保存**を選択します。

### デフォルトの支払い方法の削除 {#delete-a-default-payment-method}

Customers Portalから直接、デフォルトの支払い方法を削除することはできません。デフォルトの支払い方法を[削除](https://customers.gitlab.com/contact_us)するには、請求チームにお問い合わせください。

## 請求書の支払い {#pay-for-an-invoice}

GitLabカスタマーポータルで、クレジットカードを使用して請求書の支払いを行うことができます。

請求書を支払うには:

1. [GitLabカスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインする。
1. 左側のサイドバーで、**Invoices**（請求書）を選択します。
1. 支払う請求書で、**Pay for invoice**（請求書の支払い）を選択します。
1. 支払いフォームに入力します。

別の支払い方法を使用する場合は、[請求チームにお問い合わせください](https://customers.gitlab.com/contact_us#contact-billing-team)。

## GitLab.comアカウントのリンク {#link-a-gitlabcom-account}

従来のGitLabカスタマーポータルプロファイルでサインインする場合は、このガイドラインに従ってください。

GitLab.comアカウントをGitLabカスタマーポータルプロファイルにリンクするには:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in?legacy=true)アカウントからメールへのワンタイムサインイントリガーをトリガーします。
1. メールを見つけて、ワンタイムサインインリンクを選択して、GitLabカスタマーポータルアカウントにサインインするします。
1. **My profile**（自分のプロフィール） > **Profile settings**（プロフィールの設定）を選択します。
1. **Your GitLab.com account**（GitLab.comアカウント）で、**アカウントのリンク**を選択します。
1. GitLabカスタマーポータルプロファイルにリンクする[GitLab.com](https://gitlab.com/users/sign_in)アカウントにサインインします。

## リンクされたアカウントの変更 {#change-the-linked-account}

GitLabカスタマーポータルアカウントを別のGitLab.comアカウントにリンクする場合は、GitLab.comアカウントを使用して新しいGitLabカスタマーポータルプロファイルに登録する必要があります。

サブスクリプション連絡先を変更する場合は、代わりに次のいずれかを実行できます:

- [請求先連絡先の変更](#change-your-billing-contact)。
- [サブスクリプション連絡先の変更](#change-your-subscription-contact)。

GitLab.comアカウントにリンクされていない従来のGitLabカスタマーポータルプロファイルがある場合は、メールに送信されるワンタイムサインインリンクを使用して[サインイン](https://customers.gitlab.com/customers/sign_in?legacy=true)できます。ただし、GitLabカスタマーポータルへの継続的なアクセスを確保するには、GitLab.comアカウントを[作成](https://gitlab.com/users/sign_up)し、[リンク](#change-the-linked-account)する必要があります。

GitLabカスタマーポータルプロファイルにリンクされているGitLab.comアカウントを変更するには:

1. [GitLabカスタマーポータル](https://customers.gitlab.com/customers/sign_in)にサインインする。
1. 別のブラウザータブで、[GitLab.com](https://gitlab.com/users/sign_in)にアクセスし、ログインしていないことを確認してください。
1. GitLabカスタマーポータルページで、**My profile**（自分のプロフィール） > **Profile settings**（プロフィールの設定）を選択します。
1. **Your GitLab.com account**（GitLab.comアカウント）で、**リンクされたアカウントの変更**を選択します。
1. GitLabカスタマーポータルプロファイルにリンクする[GitLab.com](https://gitlab.com/users/sign_in)アカウントにサインインします。

## サブスクリプションの所有権の譲渡 {#transfer-subscription-ownership}

GitLabカスタマーポータルで、サブスクリプションの所有権を連絡先との間で譲渡できます。

### 新しい請求先アカウントマネージャーへ {#to-a-new-billing-account-manager}

サブスクリプションの所有権を、請求先アカウントマネージャーとしてリストされていない連絡先に譲渡するには:

1. 連絡先を請求先アカウントマネージャーとして招待します。
1. 連絡先が招待を承諾した後、サブスクリプション連絡先を新しい請求先アカウントマネージャーに変更します。

### 新しいサブスクリプション連絡先へ {#to-a-new-subscription-contact}

あなたが現在のサブスクリプション連絡先であり、GitLabカスタマーポータルアカウントを持っていない別の人に所有権を譲渡したい場合:

1. プロファイルのオーナー情報を新しい連絡先の詳細に変更します。
1. 新しい連絡先に、ワンタイムサインインリンクを使用してメールアドレスでGitLabカスタマーポータルにサインインしてもらいます。
1. 新しい連絡先に、リンクされたGitLab.comアカウントを自分のGitLab.comアカウントに変更してもらいます。

### 組織を離れた連絡先から {#from-a-contact-who-has-left-the-organization}

サブスクリプション連絡先のメールボックスにアクセスできる場合:

1. ワンタイムサインインリンクを使用して、サブスクリプション連絡先のメールアドレスでGitLabカスタマーポータルにサインインするします。
1. サブスクリプション連絡先情報を自分の詳細に変更します。
1. リンクされたアカウントを自分のGitLab.comアカウントに変更します。

サブスクリプション連絡先のメールボックスにアクセスできない場合は、[サポートに連絡](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)してサブスクリプションの所有権の譲渡をリクエストしてください。サポートがリクエストを処理するには、所有権の証明を提示する必要があります。

サポートリクエストには、次のテンプレートを使用できます:

```plaintext
Hi Support,

Please update subscription ownership for my subscription/billing account. I confirm that I am not able to make this change in the Customers Portal. Here are the relevant details:

- Old subscription contact's email address:
- New subscription contact's email address:
- (Optional) Subscription or Billing account name:
- Proof of ownership:
```

## 米国外のお客様の納税者番号 {#tax-id-for-non-us-customers}

納税者番号とは、税務当局が、付加価値税(VAT)、物品サービス税(GST)、または同様の間接税に登録された企業に割り当てる固有の番号です。

有効な納税者IDを提示すると、請求書にVAT/GSTを課金する代わりに、リバースチャージメカニズムを適用できるため、納税額を減らすことができます。有効な納税者IDがない場合、お客様の所在地に基づいて適用されるVAT/GST率を請求します。

お客様の事業が（規模の閾値またはその他の理由により）間接税に登録されていない場合、現地の規制に従って標準のVAT/GST率を適用します。

国別の詳細な納税者ID形式と追加情報については、[完全な納税者IDリファレンスガイド](https://handbook.gitlab.com/handbook/finance/tax/#frequently-asked-questions---tax-id-for-non-us-customers)を参照してください。

## トラブルシューティング {#troubleshooting}

GitLabのサブスクリプションに関する問題や質問がある場合は、[お問い合わせ](https://customers.gitlab.com/contact_us)ページをご覧ください。セールス、請求、サポートチームのリソース、サービス、連絡先オプションにアクセスして、必要なヘルプにすばやくアクセスできます。

### リセラー経由で購入したサブスクリプション {#subscription-purchased-through-a-reseller}

認定リセラー（GCPおよびAWS Marketplaceを含む）経由でサブスクリプションを購入した場合、Customers Portalにアクセスして、以下を実行できます:

- サブスクリプションを表示する。
- 関連するグループ（GitLab.com）とサブスクリプションを関連付けるか、ライセンス（GitLab Self-Managed）をダウンロードします。
- 連絡先情報を管理します。

その他の変更とリクエストは、リセラーを通じて行う必要があります。以下を含みます:

- サブスクリプションの変更。
- 追加のシート、ストレージ、またはコンピューティングの購入。
- 請求書がGitLabではなく、リセラーによって発行されるため、請求書のリクエスト。

リセラーは、Customers Portal、または顧客のアカウントにアクセスできません。

サブスクリプションの注文が処理されると、いくつかのメールが届きます:

- サインイン方法の説明を含む「Customers Portalへようこそ」というメール。
- アクセスのプロビジョニング方法の説明が記載された購入確認メール。

### 請求先とサブスクリプションの連絡先の名前が一致しません {#billing-and-subscription-contacts-names-dont-match}

請求先アカウントマネージャーのメールが、姓または名が異なる連絡先にリンクされている場合、名前を更新するように求められます。

請求先アカウントマネージャーの場合は、指示に従って[個人プロファイルを更新](#change-profile-owner-information)してください。

請求先アカウントマネージャーでない場合は、個人プロファイルを更新するように通知してください。

### サブスクリプションの連絡先は、アカウントマネージャーではなくなりました {#subscription-contact-is-no-longer-account-manager}

サブスクリプションの連絡先が請求先アカウントマネージャーでなくなった場合は、新しい連絡先を選択するように求められます。指示に従って[サブスクリプションの連絡先を変更](#change-your-subscription-contact)してください。

### エラー: `Email has already been taken` {#error-email-has-already-been-taken}

登録に使用するメールアドレスが既にCustomers Portalで使用されている場合は、次のいずれかを実行できます:

- 別のメールアドレスを入力します。
- サブスクリプションの所有権を譲渡します。
