---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Spamcheckアンチスパムサービス
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

Spamcheckはすべての階層で利用できますが、GitLab Enterprise Edition（EE）を使用しているインスタンスでのみ利用できます。[ライセンス上の理由](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6259#note_726605397)により、GitLab Community Edition（CE）パッケージには含まれていません。[CEからEEへ移行](../../update/convert_to_ee/package.md)できます。

{{< /alert >}}

[Spamcheck](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck)は、GitLab.comで増加しているスパムに対処するために、元々GitLabによって開発されたアンチスパムエンジンで、後にGitLab Self-Managedインスタンスで使用できるように公開されました。

## Spamcheckを有効にする {#enable-spamcheck}

Spamcheckは、パッケージベースのインストールでのみ利用できます:

1. `/etc/gitlab/gitlab.rb`を編集し、Spamcheckを有効にします:

   ```ruby
   spamcheck['enable'] = true
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 新しいサービス`spamcheck`と`spam-classifier`が起動していることを確認します:

   ```shell
   sudo gitlab-ctl status
   ```

## Spamcheckを使用するようにGitLabを設定する {#configure-gitlab-to-use-spamcheck}

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **レポート**を選択します。
1. **スパムとアンチボット対策**を展開します。
1. スパムチェック設定を更新します:
   1. 「外部APIエンドポイント経由でスパムチェックを有効にする」チェックボックスをオンにします。
   1. **外部スパムチェックエンドポイントのURL**には、`grpc://localhost:8001`を使用します。
   1. **スパムチェックAPIキー**は空白のままにします。
1. **変更を保存**を選択します。

{{< alert type="note" >}}

シングルノードのインスタンスでは、Spamcheckは`localhost`を介して実行されるため、認証されていないモードで実行されています。マルチノードインスタンスで、GitLabが1つのサーバーで実行され、Spamcheckがパブリックエンドポイントを介してリッスンする別のサーバーで実行されている場合は、APIキーとともに使用できるSpamcheckサービスの前にリバースプロキシを使用して、何らかの種類の認証を適用することをお勧めします。1つの例としては、これに`JWT`認証を使用し、ベアラートークンをAPIキーとして指定することが挙げられます。[Spamcheckのネイティブ認証が進行中です](https://gitlab.com/gitlab-com/gl-security/engineering-and-research/automation-team/spam/spamcheck/-/issues/171)。

{{< /alert >}}

## TLS経由でのSpamcheckの実行 {#running-spamcheck-over-tls}

Spamcheckサービス自体は、TLS経由でGitLabと直接通信できません。ただし、Spamcheckは、TLS終端を実行するリバースプロキシの背後にデプロイできます。このようなシナリオでは、**管理者**エリアの設定で、`grpc://`の代わりに外部SpamcheckのURLに`tls://`スキームを指定することで、GitLabがTLS経由でSpamcheckと通信できるようになります。
