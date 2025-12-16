---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: reCAPTCHA
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、スパムや悪用から保護するために[reCAPTCHA](https://www.google.com/recaptcha/about/)を活用しています。GitLabは、ボットではなく実際のユーザーがアカウントを作成しようとしていることを確認するために、サインアップページにCAPTCHAフォームを表示します。

## 設定 {#configuration}

reCAPTCHAを使用するには、まずサイトとプライベートキーを作成します。

1. [Google reCAPTCHA page](https://www.google.com/recaptcha/admin)に移動します。
1. reCAPTCHA v2キーを取得するには、フォームに必要事項を入力し、**送信**を選択します。
1. 管理者としてGitLabサーバーにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **レポート**を選択します。
1. **スパムとアンチボット対策**を展開します。
1. reCAPTCHAフィールドに、前の手順で取得したキーを入力します。
1. **reCAPTCHAを有効にする**チェックボックスを選択します。
1. パスワードによるログインに対してreCAPTCHAを有効にするには、**Enable reCAPTCHA for login**（ログインにreCAPTCHAを有効にする）チェックボックスを選択します。
1. **変更を保存**を選択します。
1. スパムチェックを回避し、`recaptcha_html`を返すようにトリガーするには、以下を実行します:
   1. `app/services/spam/spam_verdict_service.rb`を開きます。
   1. `#execute`メソッドの最初の行を`return CONDITIONAL_ALLOW`に変更します。

{{< alert type="note" >}}

パブリックプロジェクトでイシューを表示していることを確認してください。もしイシューを使用している場合は、そのイシューは公開されています。

{{< /alert >}}

## HTTPヘッダーを使用してユーザーログインにreCAPTCHAを有効にする {#enable-recaptcha-for-user-logins-using-the-http-header}

パスワードによるユーザーログインに対するreCAPTCHAの有効化は、[ユーザーインターフェース](#configuration)で、または`X-GitLab-Show-Login-Captcha` HTTPヘッダーを設定することで可能です。たとえば、NGINXでは、これは`proxy_set_header`設定変数によって行うことができます:

```nginx
proxy_set_header X-GitLab-Show-Login-Captcha 1;
```

Linuxパッケージのインスタンスの場合は、`/etc/gitlab/gitlab.rb`で設定します:

```ruby
nginx['proxy_set_headers'] = { 'X-GitLab-Show-Login-Captcha' => '1' }
```
