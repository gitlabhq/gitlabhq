---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アイデンティティ検証
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 15.4で`identity_verification`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95722)されました。デフォルトでは無効になっています。
- GitLab 16.0のGitLab.comで有効になりました。
- GitLab 16.11で一般提供となりました。機能フラグ`identity_verification`は削除されました。

{{< /history >}}

本人確認は、複数のGitLabアカウントセキュリティレイヤーを提供します。[リスクスコア](../integration/arkose.md)によっては、アカウントを登録するために、最大3つのステージの検証を実行する必要がある場合があります:

- **すべてのユーザー** \- メール検証。
- **Medium-risk users**（中リスクユーザー） - 電話番号認証。
- **High-risk users**（高リスクユーザー） - クレジットカード認証。

[SAML SSO for GitLab.com groups](../user/group/saml_sso/_index.md)でサインインした後に作成されたユーザーは、本人確認を免除されます。

## メール検証 {#email-verification}

アカウントを登録するには、有効なメールアドレスを入力する必要があります。[新規ユーザーにメール確認をリクエストする](user_email_confirmation.md)を参照してください。

## 電話番号認証 {#phone-number-verification}

メール検証に加えて、有効な電話番号を入力し、ワンタイムコードを確認する必要がある場合があります。

禁止されたユーザーに関連付けられている電話番号でアカウントを確認することはできません。

### サポートされていない国 {#unsupported-countries}

電話番号認証は、次の国からの番号ではサポートされていません:

- バングラデシュ
- 中国
- キューバ
- 香港
- インドネシア
- イラン
- マカオ
- マレーシア
- 北朝鮮
- パキスタン
- ロシア
- サウジアラビア
- シリア
- アラブ首長国連邦
- ベトナム

サポートされていない国の電話番号をお持ちのユーザーは、[クレジットカード認証](#credit-card-verification)を試すか、[サポートチケット](https://about.gitlab.com/support/)を作成してください。

### 部分的にサポートされている国 {#partially-supported-countries}

電話番号が部分的にサポートされている国のものである場合、ユーザーはワンタイムパスワード（OTP）を受信できない可能性があります。メッセージが配信されるかどうかは、国の執行と規制によって異なります。

部分的にサポートされている国は次のとおりです:

<!-- vale gitlab_base.Spelling = NO -->

- アルメニア
- ベラルーシ
- カンボジア
- エスワティニ
- ハイチ
- カザフスタン
- ケニア
- クウェート
- メキシコ
- ミャンマー
- ナイジェリア
- オマーン
- フィリピン
- カタール
- 南アフリカ
- タンザニア
- タイ
- トルコ
- ウガンダ
- ウクライナ
- ウズベキスタン

<!-- vale gitlab_base.Spelling = YES -->

部分的にサポートされている国の電話番号をお持ちのユーザーは、[クレジットカード認証](#credit-card-verification)を試すか、[サポートチケット](https://about.gitlab.com/support/)を作成してください。

## クレジットカード認証 {#credit-card-verification}

メールおよび電話番号の検証に加えて、有効なクレジットカード番号を入力する必要がある場合があります。

アカウントを確認するには、メールアドレスと電話番号に加えて、有効なクレジットカード番号を入力する必要がある場合があります。GitLabは、カードの詳細を直接保存したり、料金を請求したりすることはありません。GitLabは、カードの詳細を直接保存したり、料金を請求したりすることはありません。

禁止されたユーザーに関連付けられているクレジットカード番号でアカウントを確認することはできません。
