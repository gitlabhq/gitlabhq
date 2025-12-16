---
stage: Systems
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Azure MarketplaceからGitLabをインストールします。
title: Microsoft AzureにGitLabをインストールする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Microsoft Azureのビジネスクラウドをご利用のお客様は、GitLabの事前構成済み製品を[Azure Marketplace](https://azuremarketplace.microsoft.com/en-us/marketplace/)でご利用いただけます。このチュートリアルでは、単一の仮想マシン（VM）にGitLab Enterprise Editionをインストールする方法について説明します。

## 前提条件 {#prerequisite}

Azureのアカウントが必要です。アカウントを取得するには、次の方法があります:

- お客様またはお客様の会社が既にサブスクリプションをお持ちの場合は、そのアカウントを使用してください。お持ちでない場合は、[Free](https://azure.microsoft.com/en-us/free/)アカウントを作成すると、Azureを30日間調査するための200ドルのクレジットが付与されます。詳細については、[Azure無料アカウント](https://azure.microsoft.com/en-us/pricing/offers/ms-azr-0044p/)を参照してください。
- MSDNサブスクリプションをお持ちの場合は、Azureのサブスクリプション特典を有効にできます。MSDNサブスクリプションでは、毎月定期的にAzureクレジットが付与されるため、そのクレジットを使用してGitLabを試すことができます。

## GitLabをデプロイおよび設定する {#deploy-and-configure-gitlab}

GitLabは事前設定されたイメージに既にインストールされているため、新しいVMを作成するだけで済みます:

1. [MarketplaceのGitLab製品にアクセスしてください](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/gitlabinc1586447921813.gitlabee?tab=Overview)
1. **Get it now**（今すぐ入手）を選択すると、**Create this app in Azure**（Azureでこのアプリを作成する）ウィンドウが開きます。**次に進む**を選択します。
1. Azureポータルから次のいずれかのオプションを選択します:
   - **作成**を選択して、VMをゼロから作成します。
   - 一部の事前設定されたオプションから開始するには、**Start with a pre-set configuration**（事前設定で開始）を選択します。これらの設定はいつでも変更できます。

このガイドでは、VMをゼロから作成するため、**作成**を選択しましょう。

{{< alert type="note" >}}

Azureでは、無料トライアルクレジットを使用している場合でも、VMがアクティブな場合（「割り当て済み」と呼ばれる）は常にコンピューティング料金が発生することに注意してください。[Azure VMを適切にシャットダウンしてコストを節約する方法](https://build5nines.com/properly-shutdown-azure-vm-to-save-money/)。リソースにかかるコストについては、[Azure料金計算ツール](https://azure.microsoft.com/en-us/pricing/calculator/)を参照してください。

{{< /alert >}}

仮想マシンを作成したら、以下のセクションの情報を利用して設定します。

### 基本タブを設定する {#configure-the-basics-tab}

最初に設定する必要がある項目は、基盤となる仮想マシンの基本設定です:

1. サブスクリプションモデルとリソースグループを選択します（存在しない場合は新しいリソースグループを作成します）。
1. VMの名前を入力します（例：`GitLab`）。
1. リージョンを選択します。
1. **Availability options**（可用性オプション）で、**Availability zone**（可用性ゾーン）を選択し、`1`に設定します。[可用性ゾーン](https://learn.microsoft.com/en-us/azure/virtual-machines/availability)の詳細をご覧ください。
1. 選択したイメージが**GitLab - Gen1**に設定されていることを確認してください。
1. [ハードウェア要件](../requirements.md)に基づいてVMサイズを選択します。最大500ユーザーのGitLab環境を実行するための最小システム要件は`D4s_v3`サイズでカバーされているため、そのオプションを選択します。
1. 認証タイプを**SSH公開キー**に設定します。
1. ユーザー名を入力するか、自動的に作成されたユーザー名のままにします。これは、AzureがSSH経由でVMに接続するために使用するユーザー名です。デフォルトでは、ユーザー名にはrootアクセス権があります。
1. 独自のSSHキーを提供するか、Azureに作成させるかを決定します。SSH公開キーの設定方法の詳細については、[SSH](../../user/ssh.md)を参照してください。

入力した設定をレビューし、ディスクタブに進みます。

### ディスクタブを設定する {#configure-the-disks-tab}

ディスクの場合:

1. OSディスクタイプには、**Premium SSD**を選択します。
1. デフォルトの暗号化を選択します。

Azureが提供する[ディスクの種類について詳しくはこちらをご覧ください](https://learn.microsoft.com/en-us/azure/virtual-machines/managed-disks-overview)。

設定をレビューし、ネットワーキングタブに進みます。

### ネットワークタブを設定する {#configure-the-networking-tab}

このタブを使用して、ネットワークインターフェースカード（NIC）設定を設定して、仮想マシンのネットワーク接続を定義します。これらはデフォルト設定のままにすることができます。

Azureはデフォルトでセキュリティグループを作成し、VMはそれに割り当てられます。MarketplaceのGitLabイメージには、デフォルトで次のポートが開いています:

| ポート | 説明 |
|------|-------------|
| 80   | VMがHTTPリクエストに応答できるようにし、パブリックアクセスを許可します。 |
| 443  | VMがHTTPSリクエストに応答できるようにし、パブリックアクセスを許可します。 |
| 22   | VMがSSH接続リクエストに応答できるようにし、リモートターミナルセッションへのパブリックアクセス（認証付き）を許可します。 |

ポートを変更したり、ルールを追加したりする場合は、VMダッシュボードで左側のサイドバーにある[ネットワーク]設定を選択して、VMを作成した後に行うことができます。

### 管理タブを設定する {#configure-the-management-tab}

このタブを使用して、VMのモニタリングおよび管理オプションを設定します。デフォルト設定を変更する必要はありません。

### 詳細タブを設定する {#configure-the-advanced-tab}

このタブを使用して、仮想マシン拡張機能または`cloud-init`を使用して、追加の設定、エージェント、スクリプト、またはアプリケーションを追加します。デフォルト設定を変更する必要はありません。

### タグタブを設定する {#configure-the-tags-tab}

このタブを使用して、リソースを分類できる名前/値ペアを追加します。デフォルト設定を変更する必要はありません。

### VMをレビューして作成する {#review-and-create-the-vm}

最後のタブには、選択したすべてのオプションが表示され、前の手順で選択した内容をレビューおよび変更できます。Azureはバックグラウンドで検証テストを実行し、必要な設定をすべて指定した場合は、VMを作成できます。

**作成**を選択した後、AzureにSSHキーペアを作成するように選択した場合は、プライベートSSHキーをダウンロードするように求めるプロンプトが表示されます。SSHでVMに接続するにはキーが必要なので、キーをダウンロードします。

キーをダウンロードすると、デプロイが開始されます。

### デプロイを完了する {#finish-deployment}

この時点で、Azureは新しいVMのデプロイを開始します。デプロイプロセスの完了には数分かかります。完了すると、新しいVMとその関連リソースがAzureのダッシュボードに表示されます。**Go to resource**（リソースに移動）を選択して、VMのダッシュボードにアクセスします。

これでGitLabがデプロイされ、使用できるようになりました。ただし、その前に、ドメイン名を設定し、それを使用するようにGitLabを設定する必要があります。

### ドメイン名を設定する {#set-up-a-domain-name}

VMにはパブリックIPアドレス（デフォルトでは静的）がありますが、Azureを使用すると、説明的なドメインネームシステム名をVMに割り当てることができます:

1. VMのダッシュボードから、**設定する**、**DNS name**（DNS名）の順に選択します。
1. **DNS name label**（DNS名ラベル）フィールドに、インスタンスの説明的なドメインネームシステム名を入力します（例：`gitlab-prod`）。これにより、`gitlab-prod.eastus.cloudapp.azure.com`でVMにアクセスできるようになります。
1. **保存**を選択します。

最終的に、ほとんどのユーザーは独自のドメイン名を使用したいと考えています。これを行うには、Azure VMのパブリックIPアドレスを指す`A`レコードをドメインレジストラに追加する必要があります。[Azure DNS](https://learn.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns)または[その他のレジストラ](https://docs.gitlab.com/omnibus/settings/dns.html)を使用できます。

### GitLab外部URLを変更する {#change-the-gitlab-external-url}

GitLabは、ドメイン名を設定するために、`external_url`で使用します。これを設定しない場合、Azureのフレンドリ名を表示すると、ブラウザはパブリックIPにリダイレクトします。

GitLab外部URLを設定するには:

1. VMダッシュボードから**設定**>**接続**に移動して、SSH経由でGitLabに接続し、指示に従います。VMを[作成した](#configure-the-basics-tab)ときに指定したユーザー名とSSHキーでサインインすることを忘れないでください。Azure VMのドメイン名は、[以前に設定した](#set-up-a-domain-name)ものです。VMのドメイン名を設定しなかった場合は、代わりにIPアドレスを使用できます。

   この例の場合:

   ```shell
   ssh -i <private key path> gitlab-azure@gitlab-prod.eastus.cloudapp.azure.com
   ```

   {{< alert type="note" >}}

   認証情報をリセットする必要がある場合は、[Azure VMでユーザーのSSH認証情報をリセットする方法](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/linux/troubleshoot-ssh-connection#reset-ssh-credentials-for-a-user)をお読みください。

   {{< /alert >}}

1. `/etc/gitlab/gitlab.rb`をエディタで開きます。
1. `external_url`を見つけて、独自のドメイン名に置き換えます。この例では、Azureが設定するデフォルトのドメイン名を使用します。URLで`https`を使用すると、[自動的に有効になり](https://docs.gitlab.com/omnibus/settings/ssl/#lets-encrypt-integration)、Let's EncryptがHTTPSをデフォルトで設定します:

   ```ruby
   external_url 'https://gitlab-prod.eastus.cloudapp.azure.com'
   ```

1. 次の設定を見つけてコメントアウトし、GitLabが間違った証明書を取得しないようにします:

   ```ruby
   # nginx['redirect_http_to_https'] = true
   # nginx['ssl_certificate'] = "/etc/gitlab/ssl/server.crt"
   # nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/server.key"
   ```

1. 変更を有効にするには、GitLabを再構成します。`/etc/gitlab/gitlab.rb`を変更するたびに、次のコマンドを実行します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. ドメイン名が[再起動後にリセットされる](https://docs.bitnami.com/aws/apps/gitlab/configuration/change-default-address/)のを防ぐには、Bitnamiが使用するユーティリティの名前を変更します:

   ```shell
   sudo mv /opt/bitnami/apps/gitlab/bnconfig /opt/bitnami/apps/gitlab/bnconfig.bak
   ```

これで、新しい外部URLでブラウザを使用してGitLabにアクセスできます。

### GitLabに初めて表示する {#visit-gitlab-for-the-first-time}

以前に設定したドメイン名を使用して、ブラウザで新しいGitLabインスタンスに表示します。この例では、`https://gitlab-prod.eastus.cloudapp.azure.com`です。

最初にサインインページが表示されます。GitLabはデフォルトで管理者ユーザーを作成します。認証情報は次のとおりです:

- ユーザー名: `root`
- パスワード：パスワードは自動的に作成され、[見つける方法は2つあります](https://docs.bitnami.com/azure/faq/get-started/find-credentials/)。

サインインしたら、すぐに[パスワードを変更してください](../../user/profile/user_passwords.md#change-your-password)。

## GitLabインスタンスをメンテナンスする {#maintain-your-gitlab-instance}

GitLab環境を最新の状態に保つことが重要です。GitLabチームは常に機能強化を行っており、セキュリティ上の理由から更新が必要になる場合があります。GitLabを更新する必要がある場合は、このセクションの情報を使用してください。

### 現在のバージョンをチェックする {#check-the-current-version}

現在実行しているGitLabのバージョンを確認するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある管理者、**概要**>**ダッシュボード**の順に選択します。
1. **コンポーネント**テーブルでバージョンを見つけます。

1つ以上のセキュリティ修正が含まれている、より新しいGitLabのバージョンがある場合、GitLabは**Update asap**（今すぐ更新してください）という通知メッセージを表示して、[更新](#update-gitlab)を促します。

### GitLabを更新する {#update-gitlab}

GitLabを最新バージョンに更新するには:

1. SSH経由でVMに接続します。
1. GitLabを更新します:

   ```shell
   sudo apt update
   sudo apt install gitlab-ee
   ```

   このコマンドは、GitLabとその関連コンポーネントを最新バージョンに更新し、完了するまでに時間がかかる場合があります。この間、ターミナルには、さまざまな更新タスクが完了したことが表示されます。

   {{< alert type="note" >}}

   `E: The repository 'https://packages.gitlab.com/gitlab/gitlab-ee/debian buster InRelease' is not signed.`のようなエラーが発生した場合は、[トラブルシューティングセクション](#update-the-gpg-key-for-the-gitlab-repositories)を参照してください。

   {{< /alert >}}

1. 更新プロセスが完了すると、次のようなメッセージが表示されます:

   ```plaintext
   Upgrade complete! If your GitLab server is misbehaving try running

      sudo gitlab-ctl restart

   before anything else.
   ```

ブラウザでGitLabインスタンスを更新し、**管理者**エリアに移動します。これで、最新のGitLabインスタンスが作成されました。

## 次のステップとさらなる設定 {#next-steps-and-further-configuration}

機能的なGitLabインスタンスができたので、[次のステップ](../next_steps.md)に従って、新しいインストールで何ができるかを確認してください。

## トラブルシューティング {#troubleshooting}

このセクションでは、発生する可能性のある一般的なエラーについて説明します。

### GitLabリポジトリのGPGキーを更新する {#update-the-gpg-key-for-the-gitlab-repositories}

{{< alert type="note" >}}

これは、新しいGPGキーでGitLabイメージが更新されるまでの一時的な修正です。

{{< /alert >}}

Azureで事前設定されたGitLabイメージ（Bitnami提供）は、[2020年4月に非推奨となった](https://about.gitlab.com/blog/2020/03/30/gpg-key-for-gitlab-package-repositories-metadata-changing/)GPGキーを使用しています。

リポジトリを更新しようとすると、システムは次のエラーを返します:

```plaintext
[   21.023494] apt-setup[1198]: W: GPG error: https://packages.gitlab.com/gitlab/gitlab-ee/debian buster InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
[   21.024033] apt-setup[1198]: E: The repository 'https://packages.gitlab.com/gitlab/gitlab-ee/debian buster InRelease' is not signed.
```

これを修正するには、新しいGPGキーをフェッチします:

```shell
sudo apt install gpg-agent
sudo curl --fail --silent --show-error \
     --output /etc/apt/trusted.gpg.d/gitlab.asc \
     --url "https://gitlab-org.gitlab.io/omnibus-gitlab/gitlab_new_gpg.key"
```

これで、[GitLabを更新できるようになりました](#update-gitlab)。詳細については、[パッケージ署名](https://docs.gitlab.com/omnibus/update/package_signatures.html)をお読みください。
