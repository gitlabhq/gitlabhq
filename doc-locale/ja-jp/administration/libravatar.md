---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabでLibravatarサービスを使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは[Gravatar](https://gravatar.com)アバターサービスをデフォルトでサポートしています。

Libravatarは、アバター（プロフィール画像）を他のウェブサイトに配信する別のサービスです。Libravatar APIは[Gravatarに大きく基づいている](https://wiki.libravatar.org/api/)ため、Libravatarアバターサービス、または独自のLibravatarサーバーに切り替えることができます。

## Libravatarサービスを独自のサービスに変更する {#change-the-libravatar-service-to-your-own-service}

[`gitlab.yml` Gravatarセクション](https://gitlab.com/gitlab-org/gitlab/-/blob/68dac188ec6b1b03d53365e7579422f44cbe7a1c/config/gitlab.yml.example#L469-476)で、設定オプションを次のように設定します:

Linuxパッケージインストールの場合:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['gravatar_enabled'] = true
   #### For HTTPS
   gitlab_rails['gravatar_ssl_url'] = "https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
   #### Use this line instead for HTTP
   # gitlab_rails['gravatar_plain_url'] = "http://cdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
   ```

1. 変更を適用するには、`sudo gitlab-ctl reconfigure`を実行します。

自己コンパイルによるインストールの場合: 

1. `config/gitlab.yml`を編集します:

   ```yaml
     gravatar:
       enabled: true
       # default: https://www.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon
       plain_url: "http://cdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
       # default: https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon
       ssl_url: https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
   ```

1. ファイルを保存してから、変更を有効にするためにGitLabを[再起動](restart_gitlab.md#self-compiled-installations)します。

## Libravatarサービスをデフォルト（Gravatar）に設定する {#set-the-libravatar-service-to-default-gravatar}

Linuxパッケージインストールの場合:

1. `/etc/gitlab/gitlab.rb`から`gitlab_rails['gravatar_ssl_url']`または`gitlab_rails['gravatar_plain_url']`を削除します。
1. 変更を適用するには、`sudo gitlab-ctl reconfigure`を実行します。

自己コンパイルによるインストールの場合: 

1. `config/gitlab.yml`から`gravatar:`セクションを削除します。
1. ファイルを保存し、変更を適用するためにGitLabを[再起動](restart_gitlab.md#self-compiled-installations)します。

## Gravatarサービスを無効にする {#disable-gravatar-service}

Gravatarを無効にするには（たとえば、サードパーティのサービスを禁止するなど）、次の手順を実行します:

Linuxパッケージインストールの場合:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['gravatar_enabled'] = false
   ```

1. 変更を適用するには、`sudo gitlab-ctl reconfigure`を実行します。

自己コンパイルによるインストールの場合: 

1. `config/gitlab.yml`を編集します:

   ```yaml
     gravatar:
       enabled: false
   ```

1. ファイルを保存し、変更を適用するためにGitLabを[再起動](restart_gitlab.md#self-compiled-installations)します。

### 独自のLibravatarサーバー {#your-own-libravatar-server}

[独自のLibravatarサービスを実行している](https://wiki.libravatar.org/running_your_own/)場合、URLは設定で異なりますが、GitLabがURLを正しく解析できるように、同じプレースホルダーを指定する必要があります。

たとえば、`https://libravatar.example.com`でサービスをホストし、`gitlab.yml`で指定する必要がある`ssl_url`は次のとおりです:

`https://libravatar.example.com/avatar/%{hash}?s=%{size}&d=identicon`

## 画像が見つからない場合のデフォルトのURL {#default-url-for-missing-images}

[Libravatarは](https://wiki.libravatar.org/api/)、Libravatarサービスに見つからないユーザーメールアドレスに対して、異なる画像のセットをサポートしています。

`identicon`以外のセットを使用するには、URLの`&d=identicon`の部分を、サポートされている別のセットに置き換えます。たとえば、`retro`セットを使用できます。その場合、URLは`ssl_url: "https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=retro"`のようになります。

## Microsoft Office 365のユースケースの例 {#usage-examples-for-microsoft-office-365}

ユーザーがOffice 365ユーザーの場合、`GetPersonaPhoto`サービスを使用できます。このサービスにはログインが必要なため、すべてのユーザーがOffice 365にアクセスできる企業インストールで、このユースケースが最も役立ちます。

```ruby
gitlab_rails['gravatar_plain_url'] = 'http://outlook.office.com/owa/service.svc/s/GetPersonaPhoto?email=%{email}&size=HR120x120'
gitlab_rails['gravatar_ssl_url'] = 'https://outlook.office.com/owa/service.svc/s/GetPersonaPhoto?email=%{email}&size=HR120x120'
```
