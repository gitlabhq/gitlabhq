---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Dedicatedのネットワークアクセスとセキュリティの設定。
title: GitLab Dedicatedのネットワークアクセスとセキュリティ
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

## Bring your own domain（BYOD） {#bring-your-own-domain-byod}

デフォルトでは、GitLab Dedicatedインスタンスには、`your-tenant.gitlab-dedicated.com`のようなURLでアクセスできます。Bring your own domain（BYOD）を使用すると、独自のカスタムドメイン名を使用して、GitLab Dedicatedインスタンスとそのサービスにアクセスできます。たとえば、`gitlab.company.com`の代わりに`your-tenant.gitlab-dedicated.com`でインスタンスにアクセスできます。

カスタムドメインを追加すると:

- ドメインは、インスタンスへのアクセスに使用される外部URLに含まれます。
- デフォルトの`tenant.gitlab-dedicated.com`ドメインを使用しているインスタンスへの接続は利用できなくなります。

GitLabは、[Let's Encrypt](https://letsencrypt.org/)を使用して、カスタムドメインのSSL/TLS証明書を自動的に管理します。Let's Encryptは、ドメインの所有権を検証するために[HTTP-01 Challenge](https://letsencrypt.org/docs/challenge-types/#http-01-challenge)を使用します。これには以下が必要です:

- DNSを介してパブリックに解決できるCNAMEレコード。
- 90日ごとの自動証明書更新のための同じパブリック検証プロセス。

（AWS PrivateLinkなど）プライベートネットワーキングで設定されたインスタンスの場合、他のすべてのアクセスがプライベートネットワークに制限されている場合でも、パブリックDNS解決により、証明書管理が適切に機能します。

### DNSレコードの設定 {#configure-dns-records}

カスタムドメインを使用するには、まずドメインのDNSレコードを更新します。

前提要件: 

- ドメインホストのDNS設定へのアクセス。

GitLab DedicatedでカスタムドメインのDNSレコードを設定するには:

1. ドメインホストのウェブサイトにサインインします。
1. DNS設定に移動します。
1. カスタムドメインをGitLab Dedicatedテナントに向ける`CNAME`レコードを追加します。例: 

   ```plaintext
   gitlab.my-company.com.  CNAME  my-tenant.gitlab-dedicated.com
   ```

1. オプション。ドメインに既存の`CAA`レコードがある場合は、有効な認証局として[Let's Encrypt](https://letsencrypt.org/docs/caa/)を含めるように更新します。ドメインに`CAA`レコードがない場合は、このステップをスキップできます。例: 

   ```plaintext
   example.com.  IN  CAA 0 issue "pki.goog"
   example.com.  IN  CAA 0 issue "letsencrypt.org"
   ```

   この例では、`CAA`レコードは、ドメインの証明書を発行できる認証局として、Google Trust Services（`pki.goog`）とLet's Encrypt（`letsencrypt.org`）を定義します。

1. 変更を保存し、DNSの変更が反映されるまで待ちます。

GitLab Dedicatedインスタンスでカスタムドメインを使用している限り、これらのDNSレコードをそのままにしておきます。

{{< alert type="note" >}}

プライベートネットワーク経由でインスタンスにアクセスする場合でも、カスタムドメインはSSL証明書管理のためにDNSを介してパブリックに解決できる必要があります。

{{< /alert >}}

### カスタムドメインをリクエスト {#request-a-custom-domain}

DNSレコードを設定したら、[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を送信して、カスタムドメインを有効にします。

サポートチケットで、次を指定します:

- カスタムドメイン名。
- バンドルされた[container registry](../../packages/container_registry.md)と[Kubernetes向けGitLabエージェントサーバー](../../clusters/kas.md)にカスタムドメインが必要かどうか。例えば、`registry.company.com`、`kas.company.com`。

## カスタム認証局 {#custom-certificate-authority}

GitLab Dedicatedインスタンスが、プライベートまたは内部認証局（CA）からの証明書を使用して外部サービスに接続する場合、そのCAをインスタンスに追加する必要があります。デフォルトでは、GitLabは、パブリックに認識された認証局のみを信頼し、信頼できないソースからの証明書を持つサービスへの接続を拒否します。

たとえば、次のものに接続するために認証局を追加する必要がある場合があります:

- 内部Webhookエンドポイント
- プライベートコンテナレジストリ

### スイッチボードを使用したカスタム証明書の追加 {#add-a-custom-certificate-with-switchboard}

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページの上部にある**設定**を選択します。
1. **Custom certificates**（カスタム証明書）を展開します。
1. **\+ Add Certificate**（+ 証明書を追加）を選択します。
1. 証明書をテキストボックスに貼り付けます。
1. **保存**を選択します。
1. ページの上部までスクロールし、変更をすぐに適用するか、次回のメンテナンス期間中に適用するかを選択します。

### サポートリクエストを使用したカスタム証明書の追加 {#add-a-custom-certificate-with-a-support-request}

スイッチボードを使用してカスタム証明書を追加できない場合は、[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を開き、この変更をリクエストするためにカスタムパブリック証明書ファイルを添付できます。

## AWS PrivateLink接続 {#aws-private-link-connectivity}

### 受信プライベートリンク {#inbound-private-link}

[AWS PrivateLink](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html)を使用すると、トラフィックをパブリックインターネット経由で送信することなく、AWS上のVPC内のユーザーとアプリケーションをGitLab Dedicatedエンドポイントに安全に接続できます。

以下を検討してください:

- 同じAWSリージョン内にのみプライベートリンクを作成できます。VPCが、GitLab Dedicatedインスタンスがデプロイされているリージョンと同じリージョンにあることを確認してください。

受信プライベートリンクを有効にするには:

1. [サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を開きます。サポートチケットの本文に、AWSアカウントでVPCエンドポイントを確立しているAWSユーザーまたはロールのIAMプリンシパルを含めます。IAMプリンシパルは、[IAMロールプリンシパル](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-roles)または[IAMユーザープリンシパル](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-users)である必要があります。GitLab Dedicatedは、これらのIAMプリンシパルをアクセス制御に使用します。これらのIAMプリンシパルのみが、サービスへのエンドポイントを設定できます。
1. IAMプリンシパルが許可リストに登録されると、GitLabは[Endpoint Serviceを作成](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html)し、サポートチケットで`Service Endpoint Name`を伝えます。サービス名は、サービスエンドポイントの作成時にAWSによって生成されます。
   - GitLabは、プライベートDNS名のドメイン検証を処理するため、VPC内のテナントインスタンスドメイン名のDNS解決がプライベートリンクエンドポイントに解決されます。
   - エンドポイントサービスは、2つのアベイラビリティーゾーンで利用できます。これらのアベイラビリティーゾーンは、オンボーディング中に選択したゾーン、または指定しなかった場合は、ランダムに選択された2つのゾーンです。
1. 独自のAWSアカウントで、次の設定を使用して、VPCに[Endpoint Interface](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html)を作成します:
   - Service Endpoint Name: サポートチケットでGitLabから提供された名前を使用します。
   - Private DNS names enabled: yes。
   - Subnets: 一致するすべてのサブネットを選択します。

1. エンドポイントを作成したら、オンボーディング中に提供されたインスタンスのURLを使用して、トラフィックをパブリックインターネット経由で送信せずに、VPCからGitLab Dedicatedインスタンスに安全に接続します。

#### 受信プライベートリンクのKASとレジストリを有効にする {#enable-kas-and-registry-for-inbound-private-link}

受信プライベートリンクを使用してGitLab Dedicatedインスタンスに接続すると、プライベートネットワークを介してDNSが自動的に解決されるのは、mainインスタンスのURLのみです。

プライベートネットワークを介してKAS（Kubernetes向けGitLabエージェント）およびレジストリサービスにアクセスするには、VPCで追加のDNS設定を作成する必要があります。

前提要件: 

- GitLab Dedicatedインスタンスの受信プライベートリンクを設定しました。
- AWSアカウントでRoute 53プライベートホストゾーンを作成する権限があります。

プライベートネットワーク経由でKASとレジストリを有効にするには:

1. AWSコンソールで、`gitlab-dedicated.com`のプライベートホストゾーンを作成し、プライベートリンク接続を含むVPCに関連付けます。
1. プライベートホストゾーンを作成したら、次のDNSレコードを追加します（`example`をインスタンス名に置き換えます）:

   1. GitLab Dedicatedインスタンスの`A`レコードを作成します:
      - VPCエンドポイントにエイリアスとして解決するように、完全なインスタンスドメイン（たとえば、`example.gitlab-dedicated.com`）を設定します。
      - アベイラビリティーゾーン参照を含まないVPCエンドポイントを選択します。

        ![AZ参照が強調表示されていない、正しいエンドポイントを表示するVPCエンドポイントドロップダウンリスト。](../img/vpc_endpoint_dns_v18_3.png)

   1. KASとレジストリの両方の`CNAME`レコードを作成して、GitLab Dedicatedインスタンスドメイン（`example.gitlab-dedicated.com`）に解決します:
      - `kas.example.gitlab-dedicated.com`
      - `registry.example.gitlab-dedicated.com`

1. 接続を検証するには、VPC内のリソースから次のコマンドを実行します:

   ```shell
   nslookup kas.example.gitlab-dedicated.com
   nslookup registry.example.gitlab-dedicated.com
   nslookup example.gitlab-dedicated.com
   ```

   すべてのコマンドは、VPC内のプライベートIPアドレスに解決される必要があります。

この設定は、特定のIPアドレスではなく、VPCエンドポイントインターフェースを使用するため、IPアドレスの変更に対して堅牢です。

#### トラブルシューティング {#troubleshooting}

##### エラー: `Service name could not be verified` {#error-service-name-could-not-be-verified}

VPCエンドポイントの作成を試みると、`Service name could not be verified`というエラーが発生する場合があります。

この問題は、サポートチケットで提供されたカスタムIAMロールに、AWSアカウントで設定された適切な権限または信頼ポリシーがない場合に発生します。

この問題を解決するには、以下を実行します:

1. サポートチケットでGitLabに提供されたカスタムIAMロールを引き受けることができることを確認します。
1. カスタムロールに、それを引き受けることを許可する信頼ポリシーがあることを検証します。例: 

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

1. カスタムロールに、VPCエンドポイントとEC2アクションを許可する権限ポリシーがあることを検証します。例: 

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

1. カスタムロールを使用して、AWSコンソールまたはCLIでVPCエンドポイントの作成を再試行します。

### 送信プライベートリンク {#outbound-private-link}

送信プライベートリンクを使用すると、GitLab DedicatedインスタンスとGitLab DedicatedのホストRunnerは、トラフィックをパブリックインターネットに公開することなく、AWSのVPCで実行されているサービスと安全に通信できます。

このタイプの接続により、GitLabの機能はプライベートサービスにアクセスできます:

- GitLab Dedicatedインスタンスの場合:

  - [Webhook](../../../user/project/integrations/webhooks.md)
  - プロジェクトとリポジトリをインポートまたはミラーします

- ホストされるRunnerの場合:

  - カスタムシークレットマネージャー
  - インフラストラクチャに保存されているアーティファクトまたはジョブイメージ
  - インフラストラクチャへのデプロイ

以下を検討してください:

- 同じAWSリージョン内にのみプライベートリンクを作成できます。VPCが、GitLab Dedicatedインスタンスがデプロイされているリージョンと同じリージョンにあることを確認してください。
- 接続には、オンボーディング中に選択したリージョンにある2つのアベイラビリティーゾーン（AZ）の[アベイラビリティーゾーンID（AZ ID）](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#az-ids)が必要です。
- Dedicatedへのオンボーディング中にAZを指定しなかった場合、GitLabは両方のAZ IDをランダムに選択します。AZ IDは、プライマリリージョンとセカンダリリージョンの両方のスイッチボードの概要ページに表示されます。
- GitLab Dedicatedは、送信プライベートリンク接続の数を10に制限しています。

#### スイッチボードを使用した送信プライベートリンクの追加 {#add-an-outbound-private-link-with-switchboard}

前提要件: 

- GitLab Dedicatedで利用できるように、内部サービス用の[エンドポイントサービスを作成](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html)します。
- Dedicatedインスタンスがデプロイされているアベイラビリティーゾーン（AZ）で、エンドポイントサービスのネットワークロードバランサー（NLB）を設定します。次のいずれかの操作を行います:
  - 設定されたAZを使用します。AZ IDは、スイッチボードの概要ページに表示されます。
  - リージョンのすべてのAZでNLBを有効にします。
- GitLab Dedicatedがエンドポイントサービスへの接続に使用するロールのARNを、Endpoint Serviceの[許可されたプリンシパル]リストに追加します。このARNは、送信プライベートリンクIAMプリンシパルの下のスイッチボードにあります。詳細については、[権限の管理](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions)を参照してください。
- （推奨）GitLab Dedicatedが1回の操作で接続できるように、**Acceptance required**を**No**に設定します。**可能**に設定した場合は、開始後に手動で接続を承認する必要があります。

  {{< alert type="note" >}}

  **Acceptance required**を**Yes**に設定した場合、スイッチボードはリンクが承認されたタイミングを正確に判断できません。リンクを手動で承認すると、次回の定期メンテナンスまで、ステータスが**保留中**ではなく**有効**として表示されます。メンテナンス後、リンクステータスが更新され、接続済みとして表示されます。

  {{< /alert >}}

- エンドポイントサービスが作成されたら、サービス名と、プライベートDNSを有効にしたかどうかを書き留めます。

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページの上部にある**設定**を選択します。
1. **Outbound private link**（送信プライベートリンク）を展開します。
1. フィールドに入力します。
1. エンドポイントサービスを追加するには、**Add endpoint service**（エンドポイントサービスの追加）を選択します。リージョンごとに最大10個のエンドポイントサービスを追加できます。リージョンを保存するには、少なくとも1つのエンドポイントサービスが必要です。
1. **保存**を選択します。
1. オプション。2番目のリージョンの送信プライベートリンクを追加するには、**Add outbound connection**（送信接続を追加）を選択し、前の手順を繰り返します。

#### スイッチボードを使用した送信プライベートリンクの削除 {#delete-an-outbound-private-link-with-switchboard}

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページの上部にある**設定**を選択します。
1. **Outbound private link**（送信プライベートリンク）を展開します。
1. 削除する送信プライベートリンクに移動し、**Delete**（{{< icon name="remove" >}}）を選択します。
1. **Delete**を選択します。
1. オプション。リージョン内のすべてのリンクを削除するには、リージョンヘッダーから**Delete**（{{< icon name="remove" >}}）を選択します。これにより、リージョンの設定も削除されます。

#### サポートリクエストを使用した送信プライベートリンクの追加 {#add-an-outbound-private-link-with-a-support-request}

1. GitLab Dedicatedで内部サービスを利用できるようにするため、[エンドポイントサービスを作成](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html)します。新しい[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)に関連付けられた`Service Endpoint Name`を提供します。
1. Dedicatedインスタンスがデプロイされているアベイラビリティーゾーン（AZ）で、エンドポイントサービスのネットワークロードバランサー（NLB）を設定します。次のいずれかの操作を行います:
   - 設定されたAZを使用します。AZ IDは、スイッチボードの概要ページに表示されます。
   - リージョンのすべてのAZでNLBを有効にします。
1. [サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)では、GitLabは、エンドポイントサービスへの接続を開始するIAMロールのARNを提供します。このARNが、[AWSドキュメント](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions)に記載されているように、エンドポイントサービスの「Allowed Principals」の一覧に含まれているか、または他のエントリでカバーされていることを確認する必要があります。必須ではありませんが、明示的に追加しておくことをおすすめします。そうすれば、`Acceptance required`をNoに設定し、Dedicatedが1回の操作で接続できるようになります。`Acceptance required`をYesのままにする場合、Dedicatedが接続を開始した後に手動で接続を承認する必要があります。
1. エンドポイントを使用してサービスに接続するには、DedicatedサービスにDNS名が必要です。プライベートリンクは内部名を自動的に作成しますが、マシンによって生成され、一般に直接役立つわけではありません。2つのオプションがあります:
   - エンドポイントサービスで、[Private DNS name](https://docs.aws.amazon.com/vpc/latest/privatelink/manage-dns-names.html)を有効にし、必要な検証を実行して、このオプションを使用していることをサポートチケットでGitLabに通知します。`Acceptance Required`がEndpoint Serviceで[はい]に設定されている場合は、プライベートDNSなしでDedicatedが接続を開始し、承認されたことを確認するまで待ってから、接続を更新してプライベートDNSの使用を有効にする必要があるため、サポートチケットにこれについても書き留めてください。
   - Dedicatedは、Dedicated AWSアカウント内のPrivate Hosted Zone（PHZ）を管理し、エンドポイントへの任意のDNS名をエイリアスして、それらの名前へのリクエストをエンドポイントサービスに転送できます。これらのエイリアスは、PHZエントリとして知られています。詳細については、[Private Hosted Zone](#private-hosted-zones)を参照してください。

次に、GitLabは、提供されたサービス名に基づいて、必要なエンドポイントインターフェイスを作成するようにテナントインスタンスを構成します。テナントインスタンスから行われた一致する送信接続は、PrivateLinkを介してVPCに転送されます。

#### トラブルシューティング {#troubleshooting-1}

送信Private Linkの設定後に接続の確立で問題が発生した場合は、AWSインフラストラクチャのいくつかのものが問題の原因となっている可能性があります。確認すべき具体的な事項は、修正しようとしている予期しない動作によって異なります。確認すべき事項は次のとおりです:

- ネットワークロードバランサー（NLB）でクロスゾーンロードバランシングが有効になっていることを確認します。
- 適切なセキュリティグループの受信ルールセクションが、正しいIP範囲からのトラフィックを許可していることを確認します。
- 受信トラフィックがエンドポイントサービスの正しいポートにマップされていることを確認します。
- スイッチボードで、**Outbound private link**を展開し、詳細が期待どおりに表示されることを確認します。
- [ローカルネットワークからのWebhookおよびインテグレーションへのリクエストを許可](../../../security/webhooks.md#allow-requests-to-the-local-network-from-webhooks-and-integrations)していることを確認してください。

## Private Hosted Zone {#private-hosted-zones}

Private Hosted Zone（PHZ）は、GitLab Dedicatedインスタンスのネットワークで解決されるカスタムDNSエイリアス（CNAME）を作成します。

PHZは、次の場合に使用します:

- 複数のサービスに接続するためにリバースプロキシを実行する場合など、単一のエンドポイントを使用する複数のDNS名またはエイリアスを作成する。
- パブリックDNSで検証できないプライベートドメインを使用する。

PHZは通常、リバースPrivateLinkで使用され、AWS生成のエンドポイント名の代わりに読み取り可能なドメイン名を作成します。たとえば、`alpha.beta.tenant.gitlab-dedicated.com`を`vpce-0987654321fedcba0-k99y1abc.vpce-svc-0a123bcd4e5f678gh.eu-west-1.vpce.amazonaws.com`の代わりに使用できます。

場合によっては、PHZを使用して、公開されているDNS名に解決されるエイリアスを作成することもできます。たとえば、内部システムがプライベート名でサービスにアクセスする必要がある場合に、パブリックエンドポイントに解決される内部DNS名を作成できます。

{{< alert type="note" >}}

Private Hosted Zoneを変更すると、これらのレコードを使用するサービスが最大5分間中断される可能性があります。

{{< /alert >}}

### PHZドメイン構造 {#phz-domain-structure}

GitLab Dedicatedインスタンスのドメインをエイリアスの一部として使用する場合は、メインドメインの前に2つのサブドメインを含める必要があります:

- 最初のサブドメインは、PHZの名前になります。
- 2番目のサブドメインは、エイリアスのレコードエントリになります。

例: 

- 有効なPHZエントリ: `subdomain2.subdomain1.<your-tenant-id>.gitlab-dedicated.com`。
- 無効なPHZエントリ: `subdomain1.<your-tenant-id>.gitlab-dedicated.com`。

GitLab Dedicatedインスタンスドメインを使用しない場合でも、以下を指定する必要があります:

- Private Hosted Zone（PHZ）名
- 形式`phz-entry.phz-name.com`のPHZエントリ

Dedicatedテナント内でドメインを作成するときにパブリックDNSドメインのシャドウイングを防ぐには、PHZエントリのパブリックドメインの下に少なくとも2つの追加のサブドメインレベルを使用します。たとえば、テナントが`tenant.gitlab-dedicated.com`でホストされている場合、PHZエントリは少なくとも`subdomain1.subdomain2.tenant.gitlab-dedicated.com`にする必要があります。または、`customer.com`を所有している場合は、少なくとも`subdomain1.subdomain2.customer.com`にする必要があります（`subdomain2`はパブリックドメインではありません）。

### スイッチボードでPrivate Hosted Zoneを追加する {#add-a-private-hosted-zone-with-switchboard}

Private Hosted Zoneを追加するには、次の手順に従います:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページの上部にある**設定**を選択します。
1. **Private hosted zones**を展開します。
1. **Add private hosted zone entry**を選択します。
1. フィールドに入力します。
   - **ホスト名**フィールドに、Private Hosted Zone（PHZ）エントリを入力します。
   - **Link type**で、次のいずれかを選択します:
     - 送信Private Link PHZエントリの場合は、ドロップダウンリストからエンドポイントサービスを選択します。`Available`または`Pending Acceptance`ステータスのリンクのみが表示されます。
     - 他のPHZエントリの場合は、DNSエイリアスのリストを指定します。
1. **保存**を選択します。PHZエントリとエイリアスはリストに表示されます。
1. ページの上部までスクロールし、変更をすぐに適用するか、次回のメンテナンス期間中に適用するかを選択します。

### サポートチケットでPrivate Hosted Zoneを追加する {#add-a-private-hosted-zone-with-a-support-request}

スイッチボードを使用してPrivate Hosted Zoneを追加できない場合は、[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を開き、送信Private Linkのエンドポイントサービスに解決する必要があるDNS名のリストを提供できます。リストは必要に応じて更新できます。

## IP許可リスト {#ip-allowlist}

IP許可リストを使用して、どのIPアドレスがインスタンスにアクセスできるかを制御します。IP許可リストを有効にすると、許可リストにないIPアドレスはブロックされ、インスタンスにアクセスしようとすると`HTTP 403 Forbidden`応答を受信します。

スイッチボードを使用してIP許可リストを構成および管理するか、スイッチボードが利用できない場合はサポートチケットを送信します。

### スイッチボードで許可リストにIPアドレスを追加する {#add-ip-addresses-to-the-allowlist-with-switchboard}

許可リストにIPアドレスを追加するには、次の手順に従います:

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページの上部にある**設定**を選択します。
1. **IP allowlist**（IP許可リスト）を展開し、**IP allowlist**（IP許可リスト）を選択して、IP許可リストページに移動します。
1. IP許可リストを有効にするには、縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、**有効**を選択します。
1. 次のいずれかを実行します:

   - 単一のIPアドレスを追加するには、次の手順に従います:

   1. **Add IP address**（IPアドレスの追加）を選択します。
   1. **IPアドレス**テキストボックスに、次のいずれかを入力します:
      - 単一のIPv4アドレス（例: `192.168.1.1`）。
      - CIDR表記のIPv4アドレス範囲（例: `192.168.1.0/24`）。
   1. **説明**テキストボックスに、説明を入力します。
   1. **追加**を選択します。

   - 複数のIPアドレスをインポートするには、次の手順に従います:

   1. **インポート**を選択します。
   1. CSVファイルをアップロードするか、IPアドレスのリストを貼り付けます。
   1. **次に進む**を選択します。
   1. 無効なエントリまたは重複するエントリを修正し、**次に進む**を選択します。
   1. 変更をレビューし、**インポート**を選択します。

1. ページの上部で、変更をすぐに適用するか、次回のメンテナンス期間中に適用するかを選択します。

### スイッチボードを使用して許可リストからIPアドレスを削除する {#delete-ip-addresses-from-the-allowlist-with-switchboard}

1. [スイッチボード](https://console.gitlab-dedicated.com/)にサインインします。
1. ページの上部にある**設定**を選択します。
1. **IP allowlist**（IP許可リスト）を展開し、**IP allowlist**（IP許可リスト）を選択して、IP許可リストページに移動します。
1. 次のいずれかを実行します:

   - 単一のIPアドレスを削除するには、次の手順に従います:

   1. 削除するIPアドレスの横にあるごみ箱アイコン（{{< icon name="remove" >}}）を選択します。
   1. **Delete IP address**（IPアドレスの削除）を選択します。

   - 複数のIPアドレスを削除するには、次の手順に従います:

   1. 削除するIPアドレスのチェックボックスを選択します。
   1. 現在のページ上のすべてのIPアドレスを選択するには、ヘッダー行のチェックボックスを選択します。
   1. IPアドレステーブルの上にある**削除**を選択します。
   1. **削除**を選択して確定します。

1. ページの上部で、変更をすぐに適用するか、次回のメンテナンス期間中に適用するかを選択します。

### サポートチケットで許可リストにIPを追加する {#add-an-ip-to-the-allowlist-with-a-support-request}

スイッチボードを使用してIP許可リストを更新できない場合は、[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)を開き、インスタンスにアクセスできるIPアドレスのコンマ区切りリストを指定します。

### IP許可リストのOpenID Connectを有効にする {#enable-openid-connect-for-your-ip-allowlist}

[GitLabをOpenID Connectアイデンティティプロバイダーとして使用する](../../../integration/openid_connect_provider.md)には、OpenID Connect検証エンドポイントへのインターネットアクセスが必要です。

IP許可リストを維持しながら、OpenID Connectエンドポイントへのアクセスを有効にするには、次の手順に従います:

- [サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)で、OpenID Connectエンドポイントへのアクセスを許可するようにリクエストします。

構成は、次回のメンテナンス期間中に適用されます。

### IP許可リストのSCIMプロビジョニングを有効にする {#enable-scim-provisioning-for-your-ip-allowlist}

SCIMを外部のアイデンティティプロバイダーとともに使用して、ユーザーを自動的にプロビジョニングおよび管理できます。SCIMを使用するには、アイデンティティプロバイダーがインスタンスのSCIM APIエンドポイントにアクセスできる必要があります。デフォルトでは、IP許可リストはこれらのエンドポイントへの通信をブロックします。

IP許可リストを維持しながらSCIMを有効にするには、次の手順に従います:

- [サポートチケット](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)で、SCIMエンドポイントがインターネットに接続できるようにリクエストします。

構成は、次回のメンテナンス期間中に適用されます。
