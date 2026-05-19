---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicatedのネットワークアクセスとセキュリティ設定を構成します。
title: GitLab Dedicatedのネットワークアクセスとセキュリティ
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

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

### 標準設定 {#standard-configuration}

この設定では、お客様のドメインがCNAMEレコードを使用してGitLabインスタンスに直接接続します。GitLabはLet's Encryptを使用してSSL証明書を自動的に管理します。これは、公開DNSルックアップを通じてドメインの所有権を検証し、90日ごとに証明書を自動的に更新します。

> [!note]
> プライベートネットワーク経由でインスタンスにアクセスする場合でも、SSL証明書管理のためには、カスタムドメインがパブリックインターネットからアクセス可能である必要があります。

プライベートネットワーキング（AWS PrivateLinkなど）で設定されたインスタンスの場合、他のすべてのアクセスがプライベートネットワークに制限されている場合でも、パブリックDNSアクセスにより証明書管理が適切に機能することが保証されます。

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

この設定では、Cloudflare Web Application Firewall (WAF) を介してトラフィックをルーティングできるように、お客様のドメインをNSレコードを使用してGitLabに委任する必要があります。Cloudflareは、お客様のドメインのすべてのDNS設定を管理し、強化されたセキュリティ機能を提供します。

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

- 2つのCloudflareネームサーバー (`name1.ns.cloudflare.com`および`name2.ns.cloudflare.com`など)。
- DNSSECパラメータ（FedRAMPのお客様のみ）、以下を含む:
  - キータグ: 数値識別子（GitLabによって提供）
  - アルゴリズム: 通常13 (ECDSA P-256 with SHA-256) または8 (RSA/SHA-256)
  - ダイジェストタイプ: 通常2 (SHA-256)
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

## 外部サービス向けのカスタム認証局 {#custom-certificate-authorities-for-external-services}

GitLab Dedicatedは、HTTPS経由で外部サービスに接続する際に証明書を検証します。デフォルトでは、GitLab Dedicatedは公開で認識された認証局のみを信頼し、信頼できない認証局からの証明書を持つサービスへの接続を拒否します。

外部サービスがプライベートまたは内部認証局からの証明書を使用している場合、その認証局をGitLab Dedicatedインスタンスに追加する必要があります。

カスタム認証局が必要となる場合があります:

- 内部Webhookエンドポイントに接続する
- プライベートコンテナレジストリからイメージをプルする
- 企業の公開キーインフラストラクチャの背後にあるオンプレミスサービスと統合する

### カスタム証明書を追加する {#add-a-custom-certificate}

証明書チェーンブロック（単一のテキストブロックに複数の証明書）はサポートされていません。チェーンに複数の証明書がある場合は、各証明書を個別にインストールします。

カスタム証明書を追加するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページ上部で、**設定**を選択します。
1. **Custom certificates**を展開します。
1. **\+ Add Certificate**を選択します。
1. 単一の証明書をテキストボックスに貼り付けます。`-----BEGIN CERTIFICATE-----`と`-----END CERTIFICATE-----`の行を含めます。
1. **保存**を選択します。
1. チェーン内の追加の各証明書について、手順4～6を繰り返します。
1. ページ上部までスクロールし、変更をすぐに適用するか、次回のメンテナンス期間中に適用するかを選択します。

スイッチボードを使用してカスタム証明書を追加できない場合は、[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を開き、各カスタム証明書を個別のファイルとして添付します。

## AWS PrivateLink接続 {#aws-private-link-connectivity}

### 受信プライベートリンク {#inbound-private-link}

[AWS PrivateLink](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html)を使用すると、AWS上のVPC内のユーザーとアプリケーションが、ネットワークトラフィックをパブリックインターネット経由で送信することなく、GitLab Dedicatedエンドポイントに安全に接続できます。

プライベートリンクは、GitLab DedicatedインスタンスがデプロイされているプライマリおよびセカンダリのAWSリージョンでのみ作成できます。

プライベートリンクを作成する際、アクセスを制御するIAMプリンシパルを指定します。指定したIAMプリンシパルのみが、インスタンスに接続するためのVPCエンドポイントを作成できます。

エンドポイントサービスは、オンボーディング中に選択された、またはランダムに選択された2つのアベイラビリティゾーンで利用可能です。

#### 必要なIAM権限 {#required-iam-permissions}

インターフェースVPCエンドポイントを作成するには、IAMプリンシパルは以下の権限を持っている必要があります:

- `ec2:CreateVpcEndpoint`
- `ec2:DescribeVpcEndpointServices`
- `ec2:DescribeVpcEndpoints`
- `ec2:DescribeVpcs`
- `route53:AssociateVPCWithHostedZone`

これらの権限により、以下を行うことができます:

- GitLabが提供するエンドポイントサービスを検出する。
- インターフェースVPCエンドポイントを作成する。
- **Private DNS**が有効になっている場合、エンドポイントをRoute 53プライベートホストゾーンに関連付ける。

たとえば、VPCエンドポイントを作成するロールまたはユーザーに以下のIAMポリシーをアタッチします:

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

#### 受信プライベートリンクを作成する {#create-an-inbound-private-link}

前提条件: 

- お客様のVPCは、GitLab Dedicatedインスタンスと同じリージョンにある必要があります。
- IAMプリンシパルは、必要なIAM権限を持っている必要があります。
- ロール名を持つIAMプリンシパルのみを使用してください。ロールパスを含めないでください。
  - 有効: `arn:aws:iam::AWS_ACCOUNT_ID:role/RoleName`
  - 無効: `arn:aws:iam::AWS_ACCOUNT_ID:role/somepath/AnotherRoleName`

受信プライベートリンクを作成するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページ上部で、**設定**を選択します。
1. **Inbound private link**を展開します。
1. **Add endpoint service**を選択します。利用可能なすべてのリージョンにすでにプライベートリンクがある場合、このボタンは利用できません。
1. リージョンを選択します。
1. VPCエンドポイントを確立するAWS組織内のAWSユーザーまたはロールのIAMプリンシパルを追加します。IAMプリンシパルは[IAM role principals](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-roles)または[IAM user principals](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-users)である必要があります。
1. **保存**を選択します。
1. GitLabはエンドポイントサービスを作成し、プライベートDNSのドメイン検証を処理します。サービスエンドポイント名は、**設定**ページで利用可能になります。
1. お客様のAWSアカウントで、VPCに[エンドポイントインターフェース](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html)を作成します。
1. エンドポイントインターフェースを以下の設定で設定します:

   - **Service endpoint name**: スイッチボードの**設定**ページにある名前を使用します。
   - **Private DNS names enabled**: **可能**を選択します。
   - **Subnets**: 一致するすべてのサブネットを選択します。

1. オンボーディング中に提供されたインスタンスURLを使用して、お客様のVPCからGitLab Dedicatedインスタンスに接続します。

#### 受信プライベートリンク向けにKASとレジストリを有効にする {#enable-kas-and-registry-for-inbound-private-link}

受信プライベートリンクを使用してGitLab Dedicatedインスタンスに接続する場合、メインインスタンスURLのみがプライベートネットワークを介した自動DNS解決を行います。

プライベートネットワークを介してKAS（Kubernetes向けGitLabエージェント）およびレジストリサービスにアクセスするには、お客様のVPCに新しいDNS設定を作成する必要があります。

前提条件: 

- GitLab Dedicatedインスタンス向けに受信プライベートリンクを設定していること。
- お客様のAWSアカウントでRoute 53プライベートホストゾーンを作成する権限があること。

プライベートネットワークを介してKASとレジストリを有効にするには:

1. お客様のAWSコンソールで、`gitlab-dedicated.com`のプライベートホストゾーンを作成し、お客様のプライベートリンク接続を含むVPCに関連付けます。
1. プライベートホストゾーンを作成したら、以下のDNSレコードを追加します（`example`をお客様のインスタンス名に置き換えます）:

   1. GitLab Dedicatedインスタンスの`A`レコードを作成します:
      - 完全なインスタンスドメイン（例: `example.gitlab-dedicated.com`）を、VPCエンドポイントにエイリアスとして解決されるように設定します。
      - アベイラビリティゾーン参照を含まないVPCエンドポイントを選択します。

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

この設定は、特定のIPアドレスではなくVPCエンドポイントインターフェースを使用するため、IPアドレスの変更に対して堅牢です。

##### 受信プライベートリンク向けにPagesを有効にする {#enable-pages-for-inbound-private-link}

お客様のVPCに追加のDNS設定を作成することで、KASとレジストリの設定と同様に、プライベートネットワークを介してGitLab Pagesにアクセスします。

プライベートネットワークを介してPagesを有効にするには:

1. お客様のAWSコンソールで、`<your_instance_name>.gitlab-pages.site`のプライベートホストゾーンを作成し、お客様のプライベートリンク接続を含むVPCに関連付けます。
1. プライベートホストゾーンを作成したら、以下のDNSレコードを追加します:
   1. VPCエンドポイント用のApex `A`エイリアスレコードを作成します。
   1. `*.<your_instance_name>.gitlab-pages.site`の`CNAME`ワイルドカードを作成し、`<your_instance_name>.gitlab-pages.site`を指すようにします。

#### トラブルシューティング {#troubleshooting}

##### エラー: `Service name could not be verified` {#error-service-name-could-not-be-verified}

VPCエンドポイントの作成を試行する際、`Service name could not be verified`と記載されたエラーが発生する場合があります。

この問題は、サポートチケットで提供されたカスタムIAMロールが、お客様のAWSアカウントで適切な権限または信頼ポリシーが設定されていない場合に発生します。

この問題を解決するには、次の手順に従います:

1. サポートチケットでGitLabに提供されたカスタムIAMロールを引き受けることができることを確認します。
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

### 送信プライベートリンク {#outbound-private-link}

送信プライベートリンクにより、GitLab Dedicatedインスタンスと、GitLab Dedicated用のホストされたRunnerが、トラフィックをパブリックインターネットに公開することなく、AWSのお客様のVPCで実行されているサービスと安全に通信できます。

この種の接続により、GitLabの機能がプライベートサービスにアクセスできます:

- GitLab Dedicatedインスタンスの場合:

  - [Webhook](../../../user/project/integrations/webhooks.md)
  - プロジェクトとリポジトリをインポートまたはミラーする
- ホストされたRunnerの場合:

  - カスタムシークレットマネージャー
  - お客様のインフラストラクチャに保存されているアーティファクトまたはジョブイメージ
  - お客様のインフラストラクチャへのデプロイ

次の点を考慮してください:

- プライベートリンクを作成できるのは、同じAWSリージョン内でのみです。お客様のVPCが、GitLab Dedicatedインスタンスがデプロイされているのと同じリージョンにあることを確認してください。
- 接続には、オンボーディング中に選択したリージョン内の2つのアベイラビリティゾーン (AZ) の[Availability Zone IDs (AZ IDs)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#az-ids)が必要です。
- Dedicatedへのオンボーディング中にAZを指定しなかった場合、GitLabは両方のAZ IDをランダムに選択します。AZ IDは、スイッチボードの概要ページにプライマリおよびセカンダリリージョンの両方について表示されます。
- GitLab Dedicatedは、送信プライベートリンク接続の数を10に制限します。

#### スイッチボードで送信プライベートリンクを追加する {#add-an-outbound-private-link-with-switchboard}

前提条件: 

- お客様の内部サービスがGitLab Dedicatedで利用可能になるように、[エンドポイントサービスを作成](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html)します。
- Dedicatedインスタンスがデプロイされているアベイラビリティゾーン (AZ) で、エンドポイントサービス用にネットワークロードバランサー (NLB) を設定します。次のいずれかの操作を行います:
  - 設定済みのAZを使用します。AZ IDはスイッチボードの概要ページに表示されます。
  - リージョン内のすべてのAZでNLBを有効にします。
- GitLab Dedicatedがお客様のエンドポイントサービスに接続するために使用するロールのARNを、エンドポイントサービスのAllowed Principalsリストに追加します。このARNは、スイッチボードの送信プライベートリンクIAMプリンシパルで見つけることができます。詳細については、[Manage permissions](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions)を参照してください。
- 推奨。推奨。**Acceptance required**を**いいえ**に設定して、GitLab Dedicatedが単一の操作で接続できるようにします。**可能**に設定されている場合、接続が開始された後に手動で承認する必要があります。

  > [!note] 
  > **Acceptance required**を**可能**に設定した場合、スイッチボードはいつリンクが承認されたかを正確に判断できません。手動でリンクを承認した後、次回のスケジュールされたメンテナンスまでは、ステータスは**保留中**と表示され、**アクティブ**とは表示されません。メンテナンス後、リンクステータスは更新され、接続済みとして表示されます。

- エンドポイントサービスが作成されたら、サービス名と、Private DNSを有効にしているかどうかをメモします。

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページ上部で、**設定**を選択します。
1. **Outbound private link**を展開します。
1. フィールドに入力します。
1. エンドポイントサービスを追加するには、**Add endpoint service**を選択します。各リージョンに最大10個のエンドポイントサービスを追加できます。リージョンを保存するには、少なくとも1つのエンドポイントサービスが必要です。
1. **保存**を選択します。
1. オプション。任意。2番目のリージョンに送信プライベートリンクを追加するには、**Add outbound connection**を選択し、その後、前の手順を繰り返します。

#### スイッチボードで送信プライベートリンクを削除する {#delete-an-outbound-private-link-with-switchboard}

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページ上部で、**設定**を選択します。
1. **Outbound private link**を展開します。
1. 削除したい送信プライベートリンクに移動し、**削除** ({{< icon name="remove" >}}) を選択します。
1. **削除**を選択します。
1. オプション。リージョン内のすべてのリンクを削除するには、リージョンヘッダーから**削除** ({{< icon name="remove" >}}) を選択します。これにより、リージョン設定も削除されます。

#### サポートチケットで送信プライベートリンクを追加する {#add-an-outbound-private-link-with-a-support-request}

1. お客様の内部サービスがGitLab Dedicatedで利用可能になるように、[エンドポイントサービスを作成](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html)します。新しい[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)で、関連する`Service Endpoint Name`を提供します。
1. Dedicatedインスタンスがデプロイされているアベイラビリティゾーン (AZ) で、エンドポイントサービス用にネットワークロードバランサー (NLB) を設定します。次のいずれかの操作を行います:
   - 設定済みのAZを使用します。AZ IDはスイッチボードの概要ページに表示されます。
   - リージョン内のすべてのAZでNLBを有効にします。
1. お客様の[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)で、GitLabは、お客様のエンドポイントサービスへの接続を開始するIAMロールのARNを提供します。AWSの[ドキュメント](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions)に記載されているとおり、このARNがエンドポイントサービスの「Allowed Principals」リストに含まれているか、またはその他のエントリによってカバーされていることを確認する必要があります。オプションではありますが、`Acceptance required`をいいえに設定できるように、明示的に追加する必要があります。これにより、Dedicatedが単一の操作で接続できます。`Acceptance required`を可能のままにした場合、Dedicatedがそれを開始した後、手動で接続を承認する必要があります。
1. エンドポイントを使用してサービスに接続するには、DedicatedサービスにはDNS名が必要です。プライベートリンクは内部名を自動的に作成しますが、それは機械生成されたものであり、通常は直接役立ちません。2つのオプションが利用可能です:
   - お客様のエンドポイントサービスで[Private DNS name](https://docs.aws.amazon.com/vpc/latest/privatelink/manage-dns-names.html)を有効にし、必要な検証を実行し、このオプションを使用していることをサポートチケットでGitLabに通知します。お客様のエンドポイントサービスで`Acceptance Required`が可能に設定されている場合、DedicatedがPrivate DNSなしで接続を開始し、お客様がそれが承認されたことを確認するのを待ち、その後接続を更新してPrivate DNSの使用を有効にする必要があるため、サポートチケットにもこれを記載してください。
   - Dedicatedは、Dedicated AWSアカウント内でプライベートホストゾーン (PHZ) を管理し、任意のDNS名をエンドポイントにエイリアスして、それらの名前に対するリクエストをお客様のエンドポイントサービスにルーティングできます。これらのエイリアスはPHZエントリとして知られています。詳細については、[Private hosted zones](#private-hosted-zones)を参照してください。

GitLabは、お客様が提供したサービス名に基づいて、テナントインスタンスが必要なエンドポイントインターフェースを作成するように設定します。テナントインスタンスから行われるすべての一致する送信接続は、PrivateLinkを介してお客様のVPCにルーティングされます。

#### トラブルシューティング {#troubleshooting-1}

送信プライベートリンクが設定された後で接続を確立するのに問題がある場合、お客様のAWSインフラストラクチャ内のいくつかのことが問題の原因である可能性があります。確認すべき具体的な事柄は、修正しようとしている予期しない動作によって異なります。確認すべき事項は以下のとおりです:

- お客様のネットワークロードバランサー (NLB) でクロスゾーンロードバランシングが有効になっていることを確認してください。
- 適切なセキュリティグループのInbound Rulesセクションが、正しいIP範囲からのトラフィックを許可していることを確認してください。
- 受信トラフィックがエンドポイントサービスの正しいポートにマップされていることを確認してください。
- スイッチボードで**Outbound private link**を展開し、詳細が期待どおりに表示されることを確認してください。
- [Webhookとインテグレーションからのローカルネットワークへのリクエストを許可](../../../security/webhooks.md#allow-requests-to-the-local-network-from-webhooks-and-integrations)していることを確認してください。

## プライベートホストゾーン {#private-hosted-zones}

プライベートホストゾーン (PHZ) は、GitLab Dedicatedインスタンスのネットワークで解決されるカスタムDNSレコード（A、CNAME、またはその他のレコードタイプなど）を作成します。

PHZは次の場合に使用します:

- 単一のエンドポイントを使用する複数のDNSレコード（AやCNAMEレコードなど）を作成する場合（複数のサービスに接続するためにリバースプロキシを実行する場合など）。
- パブリックDNSによって検証できないプライベートドメインを使用する場合。

PHZは、AWSが生成したエンドポイント名を使用する代わりに、リバースPrivateLinkと組み合わせて読みやすいドメイン名を作成するために一般的に使用されます。たとえば、`vpce-0987654321fedcba0-k99y1abc.vpce-svc-0a123bcd4e5f678gh.eu-west-1.vpce.amazonaws.com`の代わりに`alpha.beta.tenant.gitlab-dedicated.com`を使用できます。

場合によっては、PHZを使用して、公開アクセス可能なDNS名に解決されるDNSレコードを作成することもできます。たとえば、内部システムがプライベート名を通じてサービスにアクセスする必要がある場合、パブリックエンドポイントに解決される内部DNS名を作成できます。

> [!note]
> プライベートホストゾーンへの変更は、これらのレコードを使用するサービスを最大5分間中断させる可能性があります。

### PHZドメイン構造 {#phz-domain-structure}

PHZレコードは異なるタイプのターゲットを指すことができます。最も一般的で推奨されるアプローチは、AWS VPCエンドポイントのDNS名を指すことです。

GitLab DedicatedインスタンスのドメインをVPCエンドポイントとのエイリアスの一部として使用する場合、メインドメインの前に少なくとも1つのサブドメインを含める必要があります。例: 

- 有効なPHZエントリ: `subdomain1.<your-tenant-id>.gitlab-dedicated.com`。
- 無効なPHZエントリ: `<your-tenant-id>.gitlab-dedicated.com`。

カスタムドメインの場合、`phz-entry.phz-name.com`の形式でPHZ名とPHZエントリを指定する必要があります。

PHZレコードがVPCエンドポイントではないDNS名を指す場合、メインドメインの前に少なくとも2つのサブドメインを含める必要があります。例: `subdomain1.subdomain2.tenant.gitlab-dedicated.com`。

### スイッチボードでプライベートホストゾーンを追加する {#add-a-private-hosted-zone-with-switchboard}

プライベートホストゾーンを追加するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページ上部で、**設定**を選択します。
1. **Private hosted zones**を展開します。
1. **Add private hosted zone entry**を選択します。
1. フィールドに入力します。
   - **ホスト名**フィールドに、お客様のプライベートホストゾーン (PHZ)エントリを入力します。
   - **Link type**には、以下のいずれかを選択します:
     - 送信プライベートリンクPHZエントリの場合は、ドロップダウンリストからエンドポイントサービスを選択します。`Available`または`Pending Acceptance`ステータスのリンクのみが表示されます。
     - その他のPHZエントリについては、DNSエイリアスのリストを提供します。
1. **保存**を選択します。お客様のPHZエントリとエイリアスはリストに表示されるはずです。
1. ページ上部までスクロールし、変更をすぐに適用するか、次回のメンテナンス期間中に適用するかを選択します。

### サポートチケットでプライベートホストゾーンを追加する {#add-a-private-hosted-zone-with-a-support-request}

スイッチボードを使用してプライベートホストゾーンを追加できない場合は、[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を開き、送信プライベートリンク用のエンドポイントサービスに解決するべきDNS名のリストを提供できます。リストは必要に応じて更新できます。

## IP許可リスト {#ip-allowlist}

IP許可リストを使用して、どのIPアドレスがインスタンスにアクセスできるかを制御します。IP許可リストを有効にすると、IP許可リストにないIPアドレスはブロックされ、インスタンスにアクセスしようとすると`HTTP 403 Forbidden`応答を受け取ります。

スイッチボードを使用してIP許可リストを設定および管理するか、スイッチボードが利用できない場合はサポートチケットを提出してください。

### スイッチボードでIPアドレスを許可リストに追加する {#add-ip-addresses-to-the-allowlist-with-switchboard}

IPアドレスを許可リストに追加するには:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページ上部で、**設定**を選択します。
1. **IP allowlist**を展開し、**IP allowlist**を選択してIP許可リストページに移動します。
1. IP許可リストを有効にするには、縦方向の省略記号 ({{< icon name="ellipsis_v" >}}) を選択し、**有効**を選択します。
1. 次のいずれかを実行します。

   - 単一のIPアドレスを追加するには:

   1. **Add IP address**を選択します。
   1. **IPアドレス**テキストボックスに、以下のいずれかを入力します:
      - 単一のIPv4アドレス（例: `192.168.1.1`）。
      - CIDR表記のIPv4アドレス範囲（例: `192.168.1.0/24`）。
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

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページ上部で、**設定**を選択します。
1. **IP allowlist**を展開し、**IP allowlist**を選択してIP許可リストページに移動します。
1. 次のいずれかを実行します。

   - 単一のIPアドレスを削除するには:

   1. 削除したいIPアドレスの横にあるゴミ箱アイコン ({{< icon name="remove" >}}) を選択します。
   1. **Delete IP address**を選択します。

   - 複数のIPアドレスを削除するには:

   1. 削除したいIPアドレスのチェックボックスを選択します。
   1. 現在のページのすべてのIPアドレスを選択するには、ヘッダー行のチェックボックスを選択します。
   1. IPアドレステーブルの上で、**削除**を選択します。
   1. **削除**を選択して確定します。

1. ページ上部で、変更をすぐに適用するか、次回のメンテナンス期間中に適用するかを選択します。

### サポートチケットでIPを許可リストに追加する {#add-an-ip-to-the-allowlist-with-a-support-request}

スイッチボードを使用してIP許可リストを更新できない場合は、[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を開き、インスタンスにアクセスできるコンマ区切りのIPアドレスのリストを指定します。

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
