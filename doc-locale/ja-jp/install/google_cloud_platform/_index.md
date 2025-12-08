---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Google Cloud Platformの仮想マシンにGitLabインスタンスをインストールします。
title: Google Cloud PlatformへのGitLabのインストール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

公式のLinuxパッケージを使用すると、[Google Cloud Platform（GCP）](https://cloud.google.com/)にGitLabをインストールできます。必要に応じてカスタマイズする必要があります。ニーズに合わせてカスタマイズしてください。

{{< alert type="note" >}}

本番環境対応のGitLabをGoogle Kubernetes Engineにデプロイするには、Google Cloud Platformの[`Click to Deploy`手順](https://github.com/GoogleCloudPlatform/click-to-deploy/blob/master/k8s/gitlab/README.md)に従ってください。これは、GCP VMを使用する代わりの方法であり、[Cloud native GitLab Helmチャート](https://docs.gitlab.com/charts/)を使用します。

{{< /alert >}}

## 前提要件 {#prerequisites}

GCPにGitLabをインストールするには、2つの前提条件があります:

1. Googleアカウントを持っている必要があります。
1. GCPプログラムにサインアップする必要があります。初めての場合は、Googleから[60日間で使用できる300ドルのクレジット](https://console.cloud.google.com/freetrial)が無料で提供されます。

これらの2つの手順を実行したら、[VMを作成](#creating-the-vm)できます。

## VMの作成 {#creating-the-vm}

GCPにGitLabをデプロイするには、仮想マシンを作成する必要があります:

1. <https://console.cloud.google.com/compute/instances>にアクセスし、Google認証情報でサインインします。
1. **作成**を選択します。

   ![「インスタンスを作成」を選択してインスタンスを作成します。](img/launch_vm_v10_6.png)

1. 次のページでは、VMのタイプと予想コストを選択できます。インスタンスの名前、希望するデータセンター、およびマシンタイプを入力します。[さまざまなユーザーベース規模に対するハードウェア要件](../requirements.md)に注意してください。

   ![インスタンスを構成します。](img/vm_details_v13_1.png)

1. サイズ、種類、および必要な[オペレーティングシステム](../../install/package/_index.md)を選択するには、`Boot disk`の下の**変更**を選択します。完了したら**選択**を選択します。

1. 最後の手順として、HTTPおよびHTTPSトラフィックを許可し、**作成**を選択します。プロセスは数秒で完了します。

## GitLabのインストール {#installing-gitlab}

数秒後、インスタンスが作成され、サインインできるようになります。次のステップでは、GitLabをインスタンスにインストールします。

![インスタンスが正常に作成されました。](img/vm_created_v10_6.png)

1. 後の手順で必要になるため、インスタンスの外部IPアドレスをメモしてください。<!-- using future tense is okay here -->
1. connect列の**SSH**を選択して、インスタンスに接続します。
1. 新しいウィンドウが表示され、インスタンスにログインします。

   ![インスタンスのコマンドラインインターフェース](img/ssh_terminal_v10_6.png)

1. 次に、<https://about.gitlab.com/install/>で、選択したオペレーティングシステム用のGitLabをインストールする手順に従います。前にメモした外部IPアドレスをホスト名として使用できます。

1. おつかれさまでした。GitLabがインストールされ、ブラウザからアクセスできるようになりました。インストールを完了するには、ブラウザーでURLを開き、最初の管理者パスワードを入力します。このアカウントのユーザー名は`root`です。

   ![インストール後のGitLabの最初のサインイン。](img/first_signin_v10_6.png)

## 次の手順 {#next-steps}

これらは、GitLabを初めてインストールした後に実行する最も重要な次のステップです。

### 静的IPの割り当て {#assigning-a-static-ip}

デフォルトでは、Googleは一時的なIPをインスタンスに割り当てます。ドメイン名を持つ本番環境でGitLabを使用する場合は、静的IPを割り当てる必要があります。

詳細については、[一時的な外部IPアドレスのプロモート](https://cloud.google.com/vpc/docs/reserve-static-external-ip-address#promote_ephemeral_ip)を参照してください。

### ドメイン名の使用 {#using-a-domain-name}

ドメイン名を所有していて、前の手順で構成した静的IPを指すようにDNSが正しく設定されていると仮定すると、変更を認識するようにGitLabを構成する方法は次のとおりです:

1. VMにSSH接続します。Googleコンソールで**SSH**を選択すると、新しいウィンドウがポップアップ表示されます。

   ![SSHボタンを使用してログインするインスタンスの詳細。](img/vm_created_v10_6.png)

   将来的には、代わりに[SSHキーで接続](https://cloud.google.com/compute/docs/connect/standard-ssh)を設定することをお勧めします。

1. お気に入りのエディタを使用して、Linuxパッケージの設定ファイルを編集します:

   ```shell
   sudo vim /etc/gitlab/gitlab.rb
   ```

1. `external_url`値を、GitLabで使用するドメイン名に`https`**without**（なし）で設定します:

   ```ruby
   external_url 'http://gitlab.example.com'
   ```

   次の手順でHTTPSを設定するため、今すぐ行う必要はありません。<!-- using future tense is okay here -->

1. 変更を有効にするには、GitLabを再構成します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. これで、ドメイン名を使用してGitLabにアクセスできます。

### ドメイン名を使用したHTTPSの構成 {#configuring-https-with-the-domain-name}

必須ではありませんが、[TLS証明書](https://docs.gitlab.com/omnibus/settings/ssl/)を使用してGitLabを保護することを強くお勧めします。

### メールSMTP設定の構成 {#configuring-the-email-smtp-settings}

メールSMTP設定を正しく構成する必要があります。そうしないと、GitLabはコメントやパスワードの変更などの通知メールを送信できません。その方法については、[Linuxパッケージドキュメント](https://docs.gitlab.com/omnibus/settings/smtp.html#smtp-settings)を確認してください。

## さらに詳しく {#further-reading}

GitLabは、LDAP、SAML、Kerberosなどの他のOAuthプロバイダーで認証するように構成できます。興味のあるドキュメントを次に示します:

- [Linuxパッケージドキュメント](https://docs.gitlab.com/omnibus/)
- [インテグレーションドキュメント](../../integration/_index.md)
- [GitLab Pagesの構成](../../administration/pages/_index.md)
- [GitLabコンテナレジストリの構成](../../administration/packages/container_registry.md)
