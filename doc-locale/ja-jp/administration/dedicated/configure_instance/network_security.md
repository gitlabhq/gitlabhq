---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicatedインスタンスのネットワーキングアクセスとセキュリティ設定を構成します。
title: GitLab Dedicatedのネットワークアクセスとセキュリティ
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

これらの設定を使用して、GitLab Dedicatedインスタンスがインターネットおよびプライベートインフラストラクチャに接続する方法を制御します。カスタムドメインを構成したり、外部サービスの認証局を管理したり、AWS PrivateLinkでプライベートネットワーキング接続を構成したり、IP許可リストでアクセスを制限したり、インスタンスが使用する送信IPを表示したりできます。

## カスタムドメイン {#custom-domains}

デフォルトの`your-tenant.gitlab-dedicated.com`の代わりに、カスタムドメインを構成してGitLab Dedicatedインスタンスにアクセスできます。

カスタムドメインを追加すると、次のようになります:

- そのドメインは、インスタンスへのアクセスに使用される外部URLに含まれます。
- デフォルトの`tenant.gitlab-dedicated.com`ドメインを使用するインスタンスへの接続は、利用できなくなります。

GitLabは、[Let's Encrypt](https://letsencrypt.org/)を使用して、カスタムドメインのSSL/TLS証明書を自動的に管理します。Let's Encryptは、ドメインの所有権を検証するために[HTTP-01 challenge](https://letsencrypt.org/docs/challenge-types/#http-01-challenge)を使用します。これには以下が必要です:

- CNAMEレコードがDNSを通じて公開で解決可能であること。
- 90日ごとの証明書自動更新に対する、同じ公開検証プロセス。

プライベートネットワーキング（AWS PrivateLinkなど）で設定されたインスタンスの場合、他のすべてのアクセスがプライベートネットワークに制限されている場合でも、パブリックDNS解決により証明書管理が適切に機能することが保証されます。

GitLab Dedicatedは、次の2つの設定方法でカスタムドメインをサポートしています:

- 標準設定: CNAMEレコードとLet's Encrypt証明書を使用します。お客様ご自身でDNSレコードを設定し、サポートを通じてドメインアクティベーションをリクエストします。
- Cloudflareセキュリティ設定: NSレコードとLet's Encrypt証明書を使用します。GitLabはDNS設定の詳細を提供し、お客様はサポートと連携してそれらを実装します。

お客様のインスタンスにどの設定方法が適用されるかを決定するために、カスタマーサクセスマネージャーに連絡してください。

### カスタムドメインの詳細を表示 {#view-your-custom-domain-details}

**Custom domains**セクションには、GitLab Dedicatedインスタンスのアクティブなドメイン設定が表示されます。これには以下が含まれます:

- GitLabインスタンスドメイン: GitLabインスタンスのカスタムドメイン。
- レジストリドメイン: コンテナレジストリのカスタムドメイン。
- KASドメイン: Kubernetes向けGitLabエージェントサーバー（KAS）のカスタムドメイン。

この情報を使用して、次を行います:

- 現在のカスタムドメイン設定を確認します。
- 外部インテグレーションの参照ドメイン。
- DNS管理用の設定詳細をコピーします。

カスタムドメインの詳細を表示するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. 左サイドバーで、**設定**を選択します。
1. **Custom domains**を展開します。

#### DNSSECの詳細 {#dnssec-details}

{{< details >}}

- プラン: Ultimate
- 提供形態: 政府機関向けGitLab Dedicated

{{< /details >}}

カスタムドメインがCloudflare Web Application Firewall（WAF）で構成されている場合、スイッチボードはCloudflareネームサーバーやFedRAMPコンプライアンス向けのDNSSECパラメータを含む追加の設定詳細を表示します。

追加の詳細には以下が含まれます:

- Cloudflareネームサーバー: Cloudflare管理ドメイン用のDNSネームサーバー。
- キータグ: DNSSECキーの数値識別子。
- アルゴリズム: 使用される暗号学的アルゴリズム（通常、ECDSA P-256 with SHA-256の場合は13）。
- ダイジェストタイプ: 使用されるハッシュアルゴリズム（通常、SHA-256の場合は2）。
- ダイジェスト: 公開キーの暗号学的ハッシュ。

これらの値を使用して、DNSプロバイダーでDNS委任およびDNSSEC検証を構成します。

### 標準設定 {#standard-configuration}

この設定では、お客様のドメインがCNAMEレコードを使用してGitLabインスタンスに直接接続します。お客様ご自身でDNSレコードを設定し、サポートを通じてドメインアクティベーションをリクエストします。

> [!note]
> プライベートネットワーキングを介してインスタンスにアクセスする場合でも、SSL証明書管理のためにカスタムドメインが公開インターネットからアクセス可能である必要があります。

#### DNSレコードを設定する {#configure-dns-records}

前提条件: 

- ドメインホストのDNS設定へのアクセス。

DNSレコードを設定するには:

1. ドメインホストのウェブサイトにサインインします。
1. DNS設定に移動します。
1. カスタムドメインをGitLab Dedicatedインスタンスにポイントする`CNAME`レコードを追加します。例: 

   ```plaintext
   gitlab.my-company.com.  CNAME  my-tenant.gitlab-dedicated.com
   ```

1. オプション。任意。`CAA`レコードが既存のドメインにある場合、有効な認証局としてLet's Encryptを含めるように更新します。例: 

   ```plaintext
   gitlab.my-company.com.  IN  CAA 0 issue "pki.goog"
   gitlab.my-company.com.  IN  CAA 0 issue "letsencrypt.org"
   ```

   `CAA`レコードは、どの認証局がドメインの証明書を発行できるかを定義します。

1. 変更を保存し、DNS変更が有効になるまで待ちます。

カスタムドメインを使用している間は、DNSレコードを保持します。

#### カスタムドメインを有効にする {#enable-a-custom-domain}

前提条件: 

- DNSレコードを設定済みであること。

カスタムドメインを有効にするには:

1. [サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を提出します。
1. サポートチケットで、以下を指定します:
   - カスタムドメイン名。例: `gitlab.company.com`。
   - コンテナレジストリとKubernetes向けGitLabエージェントサーバーにカスタムドメインが必要な場合は、使用したいドメイン名を含めます。たとえば、`registry.company.com`および`kas.company.com`。

### Cloudflareセキュリティ設定 {#cloudflare-security-configuration}

この設定では、Cloudflare Web Application Firewall（WAF）を介してトラフィックをルーティングできるように、お客様のドメインをNSレコードを使用してGitLabに委任する必要があります。Cloudflareは、お客様のドメインのすべてのDNS設定を管理し、強化されたセキュリティ機能を提供します。

> [!note]
> このアプローチには、カスタマーサクセスマネージャーとの連携が必要です。設定はインスタンスのメンテナンス期間中に適用されます。

#### カスタムドメインをリクエストする {#request-a-custom-domain}

カスタムドメインをリクエストするには:

1. [サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を提出します。
1. サポートチケットで、以下を指定します:
   - カスタムドメイン名。例: `gitlab.company.com`。
   - コンテナレジストリとKubernetes向けGitLabエージェントサーバーにカスタムドメインが必要な場合は、使用したいドメイン名を含めます。たとえば、`registry.company.com`および`kas.company.com`。
   - お客様のコンプライアンス要件。たとえば、FedRAMP。

GitLabはCloudflareでお客様のドメインを設定し、以下を提供します:

- 2つのCloudflareネームサーバー（`name1.ns.cloudflare.com`および`name2.ns.cloudflare.com`など）。
- DNSSECパラメータ（FedRAMPのお客様のみ）、以下を含む:
  - キータグ: 数値識別子（GitLabによって提供）
  - アルゴリズム: 通常13（ECDSA P-256 with SHA-256）または8（RSA/SHA-256）
  - ダイジェストタイプ: 通常2（SHA-256）
  - ダイジェスト: 公開キーの暗号学的ハッシュ（GitLabによって提供）

#### DNSレコードを設定する {#configure-dns-records-1}

DNSプロバイダーでNSレコードを設定し、サブドメインをCloudflareに委任します。

前提条件: 

- ドメインホストのDNS設定へのアクセス。
- GitLabがネームサーバーとDNSSECパラメータ（該当する場合）を提供していること。

DNSレコードを設定するには:

1. ドメインホストのウェブサイトにサインインします。
1. DNS設定に移動します。
1. GitLabによって提供されたネームサーバーを使用してNSレコードを作成します。例: 

   ```plaintext
   gitlab.company.com.     NS    name1.ns.cloudflare.com.
   gitlab.company.com.     NS    name2.ns.cloudflare.com.
   ```

1. 同じサブドメインの競合するA、AAAA、またはCNAMEレコードを削除します。
1. FedRAMPのお客様のみ。GitLabによって提供された値を使用してDSレコードを追加します:

   ```plaintext
   gitlab.company.com.     DS    [Key Tag] [Algorithm] [Digest Type] [Digest]
   ```

   例: 

   ```plaintext
   gitlab.company.com.     DS    12345 13 2 A1B2C3D4E5F6...
   ```

1. 変更を保存します。DNSの変更が有効になるまでに最大48時間かかることがあります。
1. 構成を検証する:

   ```shell
   # Verify nameserver delegation
   dig +short NS gitlab.company.com

   # Verify DNS resolution
   dig gitlab.company.com

   # Verify DNSSEC (if configured)
   dig +dnssec gitlab.company.com
   ```

1. サポートチケットを通じて、DNS設定が完了したことをGitLabに通知します。

その後、GitLabは次の処理を行います。

- DNS委任を検証します。
- SSL/TLS証明書を設定します。
- カスタムドメインがアクティブになったことを確認します。

## コンテナレジストリのネットワーキングアクセス {#container-registry-network-access}

コンテナレジストリのFQDN（完全修飾ドメイン名）は、インスタンスのコンテナレジストリデータを保存するS3バケットを識別します。

### コンテナレジストリのFQDNを表示 {#view-your-container-registry-fqdn}

IPアドレスの代わりにFQDNを使用して、レジストリのストレージ場所を参照するファイアウォールルールとネットワーキングポリシーを構成します。S3バケットのIPアドレスは時間とともに変化する可能性があります。

コンテナレジストリのFQDNを表示するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. 左サイドバーで、**設定**を選択します。
1. **リソースアクセス**を展開します。
1. **コンテナレジストリ**で、**クリップボードにコピー**（{{< icon name="copy-to-clipboard" >}}）を選択します。

## 外部サービス向けのカスタム認証局 {#custom-certificate-authorities-for-external-services}

GitLab Dedicatedは、HTTPS経由で外部サービスに接続する際に証明書を検証します。デフォルトでは、GitLab Dedicatedは公開で認識された認証局のみを信頼し、信頼できない認証局からの証明書を持つサービスへの接続を拒否します。

外部サービスがプライベートまたは内部認証局からの証明書を使用している場合、その認証局をGitLab Dedicatedインスタンスに追加する必要があります。

カスタム認証局が必要となる場合があります:

- 内部Webhookエンドポイントに接続します。
- プライベートコンテナレジストリからイメージをプルします。
- 企業の公開キーインフラストラクチャの背後にあるオンプレミスサービスと統合します。

### カスタム証明書を追加する {#add-a-custom-certificate}

証明書チェーンブロック（単一のテキストブロックに複数の証明書）はサポートされていません。チェーンに複数の証明書がある場合は、各証明書を個別にインストールします。

カスタム証明書を追加するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. 左サイドバーで、**設定**を選択します。
1. **Custom certificate authorities**を展開します。
1. **\+ Add Certificate**を選択します。
1. 単一の証明書をテキストボックスに貼り付けます。`-----BEGIN CERTIFICATE-----`と`-----END CERTIFICATE-----`の行を含めます。
1. **保存**を選択します。
1. チェーン内の追加の各証明書について、手順4～6を繰り返します。
1. ページ上部までスクロールし、変更をすぐに適用するか、次回のメンテナンス期間中に適用するかを選択します。

スイッチボードを使用してカスタム証明書を追加できない場合は、[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を開き、各カスタム証明書を個別のファイルとして添付します。

## AWS PrivateLink接続 {#aws-privatelink-connectivity}

AWS PrivateLinkは、AWSインフラストラクチャとGitLab Dedicatedインスタンス間のプライベートネットワーキング接続を、パブリックインターネット経由でトラフィックをルーティングすることなく有効にします。すべてのトラフィックはAWSネットワーク内にとどまり、外部の脅威への露出を減らし、プライベートネットワーキングのコンプライアンス要件を満たすのに役立ちます。

GitLab Dedicatedは2種類のPrivateLink接続をサポートしています:

- 受信PrivateLink接続: VPC内のユーザーとアプリケーションは、GitLab Dedicatedインスタンスにプライベートに接続します。インスタンスがパブリックインターネット経由でアクセスできないようにアクセスを制限する場合にこれを使用します。
- 送信PrivateLink接続: GitLab DedicatedインスタンスとホストされたRunnerは、VPCで実行されているサービスにプライベートに接続します。これをWebhook、プロジェクトミラーリング、シークレットマネージャー、またはインフラストラクチャへのデプロイに使用します。

PrivateLink接続はGitLab Dedicatedインスタンスと同じAWSリージョンにある必要があり、プライマリおよびセカンダリAWSリージョンでのみエンドポイントサービスを作成できます。

AWS PrivateLinkの詳細については、[what is AWS PrivateLink?](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html)を参照してください。

### 受信PrivateLink接続 {#inbound-privatelink-connections}

受信PrivateLink接続により、VPC内のユーザーとアプリケーションがGitLab Dedicatedインスタンスにプライベートに接続できます。

エンドポイントサービスを作成する際、アクセスを制御するIAMプリンシパルを指定します。指定したIAMプリンシパルのみが、インスタンスに接続するためのVPCエンドポイントを作成できます。

各エンドポイントサービスは、オンボーディング中に選択されるか、ランダムに選択される2つのアベイラビリティーゾーンで利用できます。

IAMプリンシパルは、地域ごとに個別に構成されます。地域間で同じプリンシパルを再利用することも、セカンダリ地域が別のAWSアカウントを使用している場合は異なるプリンシパルを使用することもできます。

#### 受信PrivateLink接続を作成する {#create-an-inbound-privatelink-connection}

受信PrivateLink接続を作成して、VPC内のユーザーとアプリケーションがGitLab Dedicatedインスタンスにプライベートに接続できるようにします。

地域的なフェイルオーバー中にこの接続を維持するには、セカンダリ地域エンドポイントを構成します。これがないと、プライマリ地域が利用できなくなった場合、インスタンスにプライベートにアクセスできません。

前提条件: 

- 構成したい地域ごとのVPC。
- GitLabが提供するエンドポイントサービスを検出する権限、インターフェースVPCエンドポイントを作成する権限、およびプライベートDNSが有効な場合にそれをRoute 53プライベートホストゾーンに関連付ける権限を持つIAMプリンシパル。
- ロールパスなしで、ロール名のみを持つIAMプリンシパル。
  - 有効: `arn:aws:iam::AWS_ACCOUNT_ID:role/RoleName`
  - 無効: `arn:aws:iam::AWS_ACCOUNT_ID:role/somepath/AnotherRoleName`

受信PrivateLink接続を作成するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. 左サイドバーで、**設定**を選択します。
1. **Inbound PrivateLink connections**を展開します。
1. **Add endpoint service**を選択します。
1. リージョンを選択します。
1. **IAM principals**の下で、エンドポイントサービスへの接続を開始できるAWSユーザーまたはロールを追加します。IAMプリンシパルは、[IAM role principals](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-roles)または[IAM user principals](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-users)である必要があります。
1. AWSアカウントで、VPCエンドポイントを作成するロールまたはユーザーに、以下の権限を持つポリシーをアタッチします:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "GitLabDedicatedInboundPrivateLink",
         "Effect": "Allow",
         "Action": [
           "ec2:CreateVpcEndpoint",
           "ec2:DescribeVpcEndpointServices",
           "ec2:DescribeVpcEndpoints",
           "ec2:DescribeVpcs",
           "route53:AssociateVPCWithHostedZone"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

1. 推奨。推奨。セカンダリ地域を構成するには、**地域**の下の**Secondary region**を選択します。これにより、指定されたIAMプリンシパルを使用して、両方の地域にエンドポイントサービスが作成されます。
1. **保存**を選択します。GitLabはエンドポイントサービスを作成し、サービスエンドポイント名は**設定**ページで利用可能になります。

次に、構成した地域ごとに、AWSセットアップを完了します:

1. お客様のAWSアカウントで、VPCに[エンドポイントインターフェース](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html)を作成します。
1. エンドポイントインターフェースを以下の設定で設定します:
   - **Service endpoint name**: スイッチボードの**設定**ページから、その地域の名前を使用します。
   - **Private DNS names enabled**: **可能**を選択します。
   - **Subnets**: 一致するすべてのサブネットを選択します。
1. オンボーディング中に提供されたインスタンスURLを使用して、お客様のVPCからGitLab Dedicatedインスタンスに接続します。

AWS VPCエンドポイントの設定を自動化するには、[`terraform-inbound-privatelink`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-inbound-privatelink) Terraformモジュールを使用できます。このモジュールは、DNSをスイッチする際に必要となるRoute 53レコードも出力します。

#### KASとレジストリのDNSを構成する {#configure-dns-for-kas-and-registry}

VPCに追加のDNS設定を作成して、プライベートネットワーキング経由でKAS（Kubernetes向けGitLabエージェントサーバー）とコンテナレジストリにアクセスします。

前提条件: 

- 受信PrivateLink接続を構成済みであること。
- AWSアカウントでRoute 53プライベートホストゾーンを作成する権限があること。

KASとレジストリのDNSを構成するには:

1. AWSコンソールで、`gitlab-dedicated.com`用のプライベートホストゾーンを作成し、受信PrivateLink接続を含むVPCに関連付けます。
1. プライベートホストゾーンを作成したら、以下のDNSレコードを追加します（`example`をお客様のインスタンス名に置き換えます）:

   1. GitLab Dedicatedインスタンスの`A`レコードを作成します:
      - 完全なインスタンスドメイン（例: `example.gitlab-dedicated.com`）を、VPCエンドポイントをエイリアスとして解決するように構成します。
      - アベイラビリティーゾーンの参照を含まないVPCエンドポイントを選択します。

        ![AZ参照がハイライトされていない正しいエンドポイントを示すVPCエンドポイントドロップダウンリスト。](../img/vpc_endpoint_dns_v18_3.png)

   1. KASとレジストリの両方について、GitLab Dedicatedインスタンスドメイン（`example.gitlab-dedicated.com`）に解決されるように`CNAME`レコードを作成します:
      - `kas.example.gitlab-dedicated.com`
      - `registry.example.gitlab-dedicated.com`

1. 接続を検証するには、お客様のVPC内のリソースから以下のコマンドを実行します:

   ```shell
   nslookup kas.example.gitlab-dedicated.com
   nslookup registry.example.gitlab-dedicated.com
   nslookup example.gitlab-dedicated.com
   ```

   すべてのコマンドは、お客様のVPC内のプライベートIPアドレスに解決されるはずです。

この設定では、特定のIPアドレスではなくVPCエンドポイントインターフェースを使用するため、IPアドレスが変更されても安定した状態が維持されます。

#### GitLab PagesのDNSを構成する {#configure-dns-for-gitlab-pages}

プライベートネットワーキング経由でGitLab Pagesにアクセスするには、VPCに追加のDNS設定を作成します。

GitLab PagesのDNSを構成するには:

1. AWSコンソールで、`<tenant_name>.gitlab-dedicated.site`用のプライベートホストゾーンを作成し、受信PrivateLink接続を含むVPCに関連付けます。
1. プライベートホストゾーンを作成したら、以下のDNSレコードを追加します:
   1. VPCエンドポイント用のApex `A`エイリアスレコードを作成します。
   1. `*.<tenant_name>.gitlab-dedicated.site`を`<tenant_name>.gitlab-dedicated.site`にポイントするワイルドカード`CNAME`を作成します。

### 送信PrivateLink接続 {#outbound-privatelink-connections}

送信PrivateLink接続により、GitLab DedicatedインスタンスとホストされたRunnerは、パブリックインターネットにトラフィックを公開することなく、VPCで実行されているサービスとプライベートに通信できます。

送信PrivateLink接続を使用して、Webhookを送信したり、プロジェクトをインポートまたはミラーリングしたり、ホストされたRunnerにカスタムシークレットマネージャー、アーティファクト、ジョブイメージ、インフラストラクチャへのデプロイへのアクセス権を付与したりします。

地域ごとに最大10個の送信PrivateLink接続を作成できます。10を超えるバックエンドサービスを単一の接続の背後に統合するには、[`terraform-outbound-proxy`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-outbound-proxy) Terraformモジュールを使用して、TLSパススルー、HTTPルーティング、およびSMTP転送を備えた高可用性NGINXリバースプロキシをデプロイできます。

スイッチボードの送信PrivateLink接続は、接続を管理するためにサービス接続を使用します。サービス接続は、DNSエイリアスをAWSアカウントのVPCエンドポイントサービスにリンクします。各サービス接続には、地域ごとに1つ（プライマリとセカンダリ）の、最大2つのVPCエンドポイントを持つことができます。サービス接続を作成するときに、DNSがどのように解決されるかを選択します:

- GitLab管理DNS: GitLabは、VPCエンドポイントとともにエイリアスのプライベートホストゾーン（PHZ）とDNSレコードを作成します。
- プライベートDNS: AWSは、エンドポイントサービスのプライベートDNS名を使用してDNS解決を自動的に処理します。この場合、GitLabはDNSレコードを作成しません。

VPCエンドポイントを必要としないエイリアスの場合は、代わりに[create a custom DNS record](#create-a-custom-dns-record)を作成できます。

#### サービス接続を作成する {#create-a-service-connection}

GitLab Dedicatedインスタンスからの送信トラフィックを、AWS PrivateLink経由でVPC内のサービスにルーティングするサービス接続を作成します。

地域的なフェイルオーバー中にこの接続を維持するには、セカンダリ地域エンドポイントを構成します。これがないと、プライマリ地域が利用できなくなった場合、送信接続は利用できなくなります。サービス接続が1つの地域にのみVPCエンドポイントを持っている場合、スイッチボードは警告を表示します。

前提条件: 

- 内部サービス用に作成されたエンドポイントサービス（サービス名をメモ済み）。詳細については、[create an endpoint service](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html)を参照してください。
- インスタンスがデプロイされているアベイラビリティーゾーンで構成されたネットワークロードバランサー（NLB）。構成済みのAZ（スイッチボードの**概要**ページに表示）を使用するか、地域のすべてのAZでNLBを有効にします。

サービス接続を作成するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. 左サイドバーで、**設定**を選択します。
1. **Outbound PrivateLink connections**を展開し、次に**Outbound PrivateLink connections**を選択します。
1. **Set up endpoint service in AWS**を展開し、**Outbound PrivateLink IAM principal**からARNをコピーします。
1. AWSエンドポイントサービスで、ARNを**Allowed Principals**リストに追加します。詳細については、[manage permissions](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions)を参照してください。
1. **Service connections**タブを選択します。
1. **Create service connection**を選択します。
1. フィールドに入力します:
   - **Alias**: GitLab Dedicatedインスタンスがサービスに到達するために使用するDNS名を入力します。例: `my-service.example.com`。
   - オプション。**説明**: この接続の説明を入力します。
1. プライマリ地域の下で、フィールドに入力します:
   - **VPC endpoint**: **New VPC endpoint**を選択し、AWSアカウントからVPCエンドポイントサービス名（例: `com.amazonaws.vpce.us-east-1.vpce-svc-0a123bcd4e5f678gh`）を入力するか、**Existing VPC endpoint**を選択してドロップダウンリストからエンドポイントを選択します。
   - オプション。**説明**: この地域のエンドポイントの説明を入力します。
   - **DNS**: GitLabにプライベートホストゾーンレコードを保持させるには**GitLab-managed DNS**を選択するか、AWSのVPCエンドポイントサービスで構成されたプライベートDNS名を使用するには**Private DNS**を選択します。
1. セカンダリ地域に対して、次のいずれかを実行します:
   - VPCエンドポイントを追加するには、プライマリ地域と同じフィールドに入力します。
   - セカンダリ地域をスキップするには、セクションの右上にある**削除**を選択します。
1. **保存**を選択します。

GitLabは、必要なVPCエンドポイントとDNSレコードを作成するようにインスタンスを構成します（ただし、**Private DNS**が選択されている場合は、AWSがDNS解決を管理します）。セットアップ後、GitLabは、一致する送信接続をPrivateLink経由でVPCにルーティングします。

#### カスタムDNSレコードを作成する {#create-a-custom-dns-record}

VPCエンドポイントをポイントしないDNSエイリアスには、カスタムDNSレコードを使用します。たとえば、GitLab Dedicatedインスタンスがプライベートドメイン名をパブリックにアクセス可能なサービスまたは内部でルーティングされるサービスに解決する必要がある場合に、カスタムDNSレコードを使用します。

デフォルトでは、エイリアスは最初のドットでレコード名とプライベートホストゾーン名に分割されます。たとえば、`service.example.com`はレコード名`service`とゾーン`example.com`に分割されます。この分割がドメインシャドウイングを引き起こしたり、既存のサービス接続エイリアスやカスタムドメインと競合したりする場合は、詳細オプションを使用して分割をカスタマイズします。

プライベートホストゾーン（PHZ）は、Amazon Route 53がGitLab Dedicated VPC内のドメインとそのサブドメインに対するDNSクエリにどのように応答するかに関する情報を保持するコンテナです。詳細については、[private hosted zones](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-private.html)を参照してください。

カスタムDNSレコードの変更、またはGitLab管理DNS（プライベートホストゾーン）を使用している場合のサービス接続の変更は、これらのレコードを使用するサービスを最大5分間中断する可能性があります。

カスタムDNSレコードを追加するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. 左サイドバーで、**設定**を選択します。
1. **Outbound PrivateLink connections**を展開し、次に**Outbound PrivateLink connections**を選択します。
1. **Custom DNS records**タブを選択します。
1. **Create DNS record**を選択します。
1. フィールドに入力します:
   - **Alias**: GitLab Dedicatedインスタンスがサービスに到達するために使用するDNS名を入力します。例: `my-internal-service.example.com`。
   - オプション。**説明**: このレコードの説明を入力します。
   - オプション。オプション。**Customize DNS record and zone split（advanced）**を選択して、レコード名がレコード名とプライベートホストゾーンに分割される方法を制御します。選択すると、**Record name**テキストボックスは読み取り専用になり、入力した**Record name**と**Private hosted zone name**の値から自動的に構成されます。
1. 各地域の下で、エイリアスが解決する**Target domain name**を入力します。フェイルオーバーをサポートするために、プライマリとセカンダリの両方の地域にターゲットドメイン名を入力します。
1. **保存**を選択します。
1. ページ上部までスクロールし、変更をすぐに適用するか、次回のメンテナンス期間中に適用するかを選択します。

#### サポートリクエストで送信PrivateLink接続を構成する {#configure-outbound-privatelink-connections-with-a-support-request}

スイッチボードを使用して送信PrivateLink接続を構成できない場合:

1. [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を開き、以下を提供します:
   - VPCエンドポイントサービス名。
   - 該当する場合、使用したいDNSエイリアス。
   - エンドポイントサービスでプライベートDNSが有効になっているかどうか。
1. GitLabから提供されたIAMプリンシパルのARNをコピーし、エンドポイントサービスの**Allowed Principals**リストに追加します。詳細については、[manage permissions](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions)を参照してください。

#### 送信PrivateLink接続を削除する {#delete-an-outbound-privatelink-connection}

サービス接続またはVPCエンドポイントを個別に削除できます。それぞれがスイッチボードに独自のタブを持っています: **Service connections**と**VPC endpoints**。

サービス接続を削除するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. 左サイドバーで、**設定**を選択します。
1. **Outbound PrivateLink connections**を展開します。
1. **Service connections**タブを選択します。
1. 削除したい接続に移動し、**削除**（{{< icon name="remove" >}}）を選択します。
1. **削除**を選択します。

VPCエンドポイントを削除するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. 左サイドバーで、**設定**を選択します。
1. **Outbound PrivateLink connections**を展開します。
1. **VPC endpoints**タブを選択します。
1. 削除したいエンドポイントに移動し、**削除**（{{< icon name="remove" >}}）を選択します。
1. **削除**を選択します。

## IPv6接続 {#ipv6-connectivity}

IPv6接続により、クライアントはIPv4に加えてIPv6経由でGitLab Dedicatedインスタンスに到達できます。Cloudflareはこのトラフィックを受信し、IPv4に変換してから、インスタンスの既存のIPv4インフラストラクチャにリクエストを転送します。GitLab Dedicatedプラットフォームサービス間の内部通信はIPv4のみです。

インスタンスでIPv6を有効にすると:

- インスタンスはデュアルスタックモードで動作します。IPv4アクセスはIPv6とともに動作し続けます。
- GitLabウェブインターフェースはIPv6経由で利用可能になります。
- SSH Git操作（クローン、プッシュ、プルなど）はIPv6経由で利用可能になります。

前提条件: 

- インスタンスはCloudflare WAFを経由してプロキシされる必要があります。インスタンスでCloudflare WAFが有効になっているかどうかわからない場合は、カスタマーサクセスマネージャーに問い合わせてください。
- インスタンスはGitLab 18.11.4以降を実行している必要があります。

スイッチボードはこの設定をサポートしていません。IPv6接続を有効にするには、[support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を開き、インスタンスへのHTTPSおよびSSHアクセスにIPv6接続を有効にしたいことを確認してください。

IPv6が有効になると、インスタンスのパブリックIPアドレスはIPv4とIPv6の両方で変更されます。これらのアドレスをファイアウォール、DNSレコード、またはモニタリングシステムで許可リストに登録している場合は、変更が適用された後にこれらの設定を更新してください。IPv6を無効にすると、IPアドレスが再び変更されます。

この設定は、次回のメンテナンス期間中に適用されます。

## IP許可リスト {#ip-allowlist}

IP許可リストを使用して、どのIPアドレスがインスタンスにアクセスできるかを制御します。IP許可リストを有効にすると、IP許可リストにないIPアドレスはブロックされ、インスタンスにアクセスしようとすると`HTTP 403 Forbidden`応答を受け取ります。

スイッチボードを使用してIP許可リストを設定および管理するか、スイッチボードが利用できない場合はサポートチケットを提出してください。

### スイッチボードでIPアドレスを許可リストに追加する {#add-ip-addresses-to-the-allowlist-with-switchboard}

IPアドレスを許可リストに追加するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. 左サイドバーで、**設定**を選択します。
1. **IP allowlist**を展開し、**IP allowlist**を選択してIP許可リストページに移動します。
1. IP許可リストを有効にするには、縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、**有効**を選択します。
1. 次のいずれかを実行します。

   - 単一のIPアドレスを追加するには:

   1. **Add IP address**を選択します。
   1. **IPアドレス**テキストボックスに、以下のいずれかを入力します:
      - 単一のIPv4またはIPv6アドレス（例: `192.168.1.1`または`2001:db8::1`）。
      - CIDR表記のIPv4またはIPv6アドレス範囲（例: `192.168.1.0/24`または`2001:db8::/32`）。
   1. **説明**テキストボックスに説明を入力します。
   1. **追加**を選択します。

   - 複数のIPアドレスをインポートするには:

   1. **インポート**を選択します。
   1. CSVファイルをアップロードするか、IPアドレスのリストを貼り付けます。
   1. **続行する**を選択します。
   1. 無効なエントリまたは重複するエントリを修正し、**次に進む**を選択します。
   1. 変更を確認し、**インポート**を選択します。

1. ページ上部で、変更をすぐに適用するか、次回のメンテナンス期間中に適用するかを選択します。

### スイッチボードで許可リストからIPアドレスを削除する {#delete-ip-addresses-from-the-allowlist-with-switchboard}

許可リストからIPアドレスを削除するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. 左サイドバーで、**設定**を選択します。
1. **IP allowlist**を展開し、**IP allowlist**を選択してIP許可リストページに移動します。
1. 次のいずれかを実行します。

   - 単一のIPアドレスを削除するには:

   1. 削除したいIPアドレスの横にあるゴミ箱アイコン（{{< icon name="remove" >}}）を選択します。
   1. **Delete IP address**を選択します。

   - 複数のIPアドレスを削除するには:

   1. 削除したいIPアドレスのチェックボックスを選択します。
   1. 現在のページのすべてのIPアドレスを選択するには、ヘッダー行のチェックボックスを選択します。
   1. IPアドレステーブルの上で、**削除**を選択します。
   1. **削除**を選択して確定します。

1. ページ上部で、変更をすぐに適用するか、次回のメンテナンス期間中に適用するかを選択します。

### サポートチケットでIPを許可リストに追加する {#add-an-ip-to-the-allowlist-with-a-support-request}

スイッチボードを使用してIP許可リストを更新できない場合は、[support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を開き、インスタンスにアクセスできるIPアドレスのコンマ区切りリストを指定してください。

### IP許可リスト向けにOpenID Connectを有効にする {#enable-openid-connect-for-your-ip-allowlist}

[OpenID Connect identity provider](../../../integration/openid_connect_provider.md)としてGitLabを使用すると、OpenID Connect検証エンドポイントへのインターネットアクセスが必要です。

IP許可リストを維持しながらOpenID Connectエンドポイントへのアクセスを有効にするには:

- [サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)で、OpenID Connectエンドポイントへのアクセスを許可するようリクエストします。

この設定は、次回のメンテナンス期間中に適用されます。

### IP許可リスト向けにSCIMプロビジョニングを有効にする {#enable-scim-provisioning-for-your-ip-allowlist}

外部Identity Providerと組み合わせてSCIMを使用し、ユーザーを自動的にプロビジョニングおよび管理できます。SCIMを使用するには、お客様のIdentity ProviderがインスタンスSCIMAPIエンドポイントにアクセスできる必要があります。デフォルトでは、IP許可リストはこれらのエンドポイントへの通信をブロックします。

IP許可リストを維持しながらSCIMを有効にするには:

- [サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)で、SCIMエンドポイントへのインターネットアクセスを有効にするようリクエストします。

この設定は、次回のメンテナンス期間中に適用されます。

## NATゲートウェイIPアドレス {#nat-gateway-ip-addresses}

NATゲートウェイIPアドレスは、インスタンスの外部サービスへの送信接続を識別します。通常は一貫していますが、地域的なフェイルオーバーが発生した場合は、インスタンスが新しいインフラストラクチャで再構築されるため、変更される可能性があります。

これらのIPアドレスを使用して、Webhookレシーバーを構成し、インスタンスからの接続を受け入れる外部サービス用の許可リストを設定します。

NATゲートウェイIPアドレスを表示するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. 左サイドバーで、**設定**を選択します。
1. **リソースアクセス**を展開します。
1. **NAT gateways**の下で、**クリップボードにコピー**（{{< icon name="copy-to-clipboard" >}}）を選択します。

## AWS PrivateLink接続のトラブルシューティング {#troubleshooting-aws-privatelink-connectivity}

AWS PrivateLink接続を使用する際に、以下の問題が発生する可能性があります。

### エラー: `Service name could not be verified` {#error-service-name-could-not-be-verified}

受信PrivateLink接続用のVPCエンドポイントを作成する際に、`Service name could not be verified`というエラーが表示されることがあります。

この問題は、サポートチケットで提供されたカスタムIAMロールに、必要な権限または信頼ポリシーがAWSアカウントで構成されていない場合に発生します。

この問題を解決するには、次の手順に従います:

1. サポートチケットでGitLabに提供されたカスタムIAMロールを引き受けられることを確認します。
1. カスタムロールに引き受けることを許可する信頼ポリシーがあることを検証します。例: 

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Sid": "Statement1",
               "Effect": "Allow",
               "Principal": {
                   "AWS": "arn:aws:iam::CONSUMER_ACCOUNT_ID:user/user-name"
               },
               "Action": "sts:AssumeRole"
           }
       ]
   }
   ```

1. カスタムロールにVPCエンドポイントとEC2アクションを許可する権限ポリシーがあることを検証します。例: 

   ```json
   {
      "Version": "2012-10-17",
      "Statement": [
         {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "vpce:*",
            "Resource": "*"
         },
         {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                  "ec2:CreateVpcEndpoint",
                  "ec2:DescribeVpcEndpointServices",
                  "ec2:DescribeVpcEndpoints"
            ],
            "Resource": "*"
         }
      ]
   }
   ```

1. カスタムロールを使用して、お客様のAWSコンソールまたはCLIでVPCエンドポイントの作成を再試行します。

### 送信PrivateLink接続が失敗する {#outbound-privatelink-connection-fails}

送信PrivateLink接続が機能しない場合は、以下を確認してください:

- お客様のネットワークロードバランサー（NLB）でクロスゾーンロードバランシングが有効になっていることを確認してください。
- 適切なセキュリティグループのインバウンドルールセクションが、正しいIP範囲からのトラフィックを許可していることを確認します。
- インバウンドトラフィックが、エンドポイントサービスの正しいポートにマップされていることを確認します。
- スイッチボードで**Outbound PrivateLink connections**を展開し、詳細が期待どおりに表示されていることを確認します。
- [Webhookとインテグレーションからのローカルネットワークへのリクエストを許可](../../../security/webhooks.md#allow-requests-to-the-local-network-from-webhooks-and-integrations)していることを確認してください。
