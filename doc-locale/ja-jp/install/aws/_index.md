---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Read through the GitLab installation methods.
title: Amazon Web Services（AWS）でGitLab POCをインストールする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページでは、公式のLinuxパッケージを使用してAWS上にGitLabを構築するための一般的な構成について説明します。ニーズに合わせてカスタマイズする必要があります。

{{< alert type="note" >}}

1,000人以下のユーザーを抱える組織の場合、推奨されるAWSインストール方法は、EC2シングルボックスの[Linuxパッケージインストール](https://about.gitlab.com/install/)を起動し、データをバックアップするためのスナップショット戦略を実装することです。詳細については、[20 RPSまたは1,000ユーザーのリファレンスアーキテクチャ](../../administration/reference_architectures/1k_users.md)を参照してください。

{{< /alert >}}

## 本番環境グレードのGitLabを使用する {#getting-started-for-production-grade-gitlab}

{{< alert type="note" >}}

このドキュメントは、概念実証インスタンスのインストールガイドです。これはリファレンスアーキテクチャではなく、高可用性構成にはなりません。代わりに、[GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) を使用することを強くおすすめします。

{{< /alert >}}

このガイドに正確に従うと、**非HA**構成の[40 RPSまたは2,000ユーザーのリファレンスアーキテクチャ](../../administration/reference_architectures/2k_users.md)の**2つの可用性ゾーン実装**を持つ**縮小**バージョンにほぼ相当する概念実証インスタンスになります。2,000リファレンスアーキテクチャは、コストと複雑さを抑えながらある程度のスケーリングを提供することを主な目的としているため、HAではありません。[60 RPSまたは3,000 ユーザーのリファレンスアーキテクチャ](../../administration/reference_architectures/3k_users.md) は、GitLab HAの最小サイズです。HAを実現するための追加のサービスロールがあり、最も注目すべきは、GitリポジトリストレージのHAを実現するためにGitaly Clusterを使用し、トリプル冗長性を指定していることです。

GitLabは、2つのメインタイプのリファレンスアーキテクチャを維持およびテストしています。**Linuxパッケージアーキテクチャ**はインスタンスコンピューティング上に実装され、**クラウドネイティブハイブリッドアーキテクチャ**はKubernetesクラスターの使用を最大化します。クラウドネイティブハイブリッドリファレンスアーキテクチャの仕様は、Linuxパッケージアーキテクチャの説明から始まるリファレンスアーキテクチャのサイズページへの覚書セクションです。たとえば、60 RPSまたは3,000ユーザーのクラウドネイティブリファレンスアーキテクチャは、60 RPSまたは3,000ユーザーのリファレンスアーキテクチャページの[Helm Chartを使用したクラウドネイティブハイブリッドリファレンスアーキテクチャ（代替）](../../administration/reference_architectures/3k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative)というサブセクションにあります。

### 本番環境グレードのLinuxパッケージインストールを使用する {#getting-started-for-production-grade-linux-package-installations}

Infrastructure as Codeツールである[GitLab Environment Tool (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/tree/main)は、AWS上のLinuxパッケージを使用して構築を開始するのに最適な場所であり、特にHAセットアップをターゲットにしている場合はそうです。すべてを自動化するわけではありませんが、Gitaly Clusterのような複雑なセットアップを完了します。GETはオープンソースであるため、誰でもその上に構築し、改善に貢献できます。

### 本番環境グレードのクラウドネイティブハイブリッドGitLabを使用する {#getting-started-for-production-grade-cloud-native-hybrid-gitlab}

[GitLab Environment Toolkit（GET）](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/README.md)は、一連の確立されたTerraformおよびAnsibleスクリプトです。これらのスクリプトは、選択したクラウドプロバイダーへのLinuxパッケージまたはクラウドネイティブハイブリッド環境のデプロイに役立ち、GitLab開発者が[GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md)などに使用します。

GitLab Environment Toolkitを使用して、AWS上にクラウドネイティブハイブリッド環境をデプロイできます。ただし必須ではなく、すべての有効な組み合わせをサポートしているとは限りません。なお、スクリプトは現状のまま提供されており、必要に応じて調整できます。

## はじめに {#introduction}

セットアップでは主にLinuxパッケージを使用しますが、ネイティブAWSサービスも活用します。Linuxパッケージに同梱されているPostgreSQLおよびRedisを使用する代わりに、Amazon RDSおよびElastiCacheを使用します。

このガイドでは、マルチノードセットアップについて説明します。まず、Virtual Private Cloudとサブネットを設定し、データベースサーバー用のRDSやRedisクラスターとしてのElastiCacheなどのサービスを後で統合し、最後にカスタムスケーリングポリシーを使用して自動スケーリンググループで管理します。

## 要件 {#requirements}

[AWS](https://docs.aws.amazon.com/)および[Amazon EC2](https://docs.aws.amazon.com/ec2/)の基本的な知識に加えて、次のものが必要です。

- [AWSアカウント](https://console.aws.amazon.com/console/home)
- [SSH鍵を作成またはアップロード](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)してSSH経由でインスタンスに接続する
- GitLabインスタンスのドメイン名
- ドメインを保護するSSL/TLS証明書。まだお持ちでない場合は、作成する[Elasticロードバランサー](#load-balancer)で使用するために、[AWS Certificate Manager](https://aws.amazon.com/certificate-manager/) (ACM) 経由で無料のパブリックSSL/TLS証明書をプロビジョニングできます。

{{< alert type="note" >}}

ACM経由でプロビジョニングした証明書の検証には、数時間かかる場合があります。後の作業を遅らせないために、できるだけ早く証明書をリクエストしてください。

{{< /alert >}}

## アーキテクチャ {#architecture}

以下は、推奨されるアーキテクチャの図です。

![縮小された2可用性ゾーンを持つ非HAのAWSアーキテクチャ](img/aws_ha_architecture_diagram_v17_0.png)

## AWSのコスト {#aws-costs}

GitLabは次のAWSサービスを使用しています。各サービスの価格情報はリンク先を参照してください。

- **EC2**: GitLabは共有ハードウェアにデプロイされ、[オンデマンド料金](https://aws.amazon.com/ec2/pricing/on-demand/)が適用されます。専用または予約インスタンスでGitLabを実行する場合は、そのコストについて[EC2の料金ページ](https://aws.amazon.com/ec2/pricing/)を参照してください。
- **S3**: GitLabはS3（[料金ページ](https://aws.amazon.com/s3/pricing/)）を使用して、バックアップ、アーティファクト、およびLFSオブジェクトを保存します。
- **NLB**: GitLabインスタンスへのリクエストのルーティングに使用されるネットワークロードバランサー（[料金ページ](https://aws.amazon.com/elasticloadbalancing/pricing/)）
- **RDS**: PostgreSQLを使用するAmazon Relational Database Service（[料金ページ](https://aws.amazon.com/rds/postgresql/pricing/)）
- **ElastiCache**: Redis設定を提供するために使用されるインメモリキャッシュ環境（[料金ページ](https://aws.amazon.com/elasticache/pricing/)）

## IAM EC2インスタンスのロールとプロファイルを作成する {#create-an-iam-ec2-instance-role-and-profile}

[Amazon S3オブジェクトストレージ](#amazon-s3-object-storage)を使用しているため、EC2インスタンスにはS3バケットに対する読み取り、書き込み、リストの権限が必要です。GitLab設定にAWSキーを埋め込むことを避けるために、[IAMロール](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)を使用して、このアクセス権を持つGitLabインスタンスを許可します。IAMロールにアタッチするIAMポリシーを作成する必要があります。

### IAMポリシーを作成する {#create-an-iam-policy}

1. IAMダッシュボードに移動し、左側のメニューで**Policies(ポリシー)**を選択します。
1. **Create policy(ポリシーの作成)**を選択し、`JSON`タブを選択して、ポリシーを追加します。[セキュリティのベストプラクティスに従い、_最小の権限_を付与する](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege)ことで、必要なアクションを実行するために必要な権限のみをロールに付与します。
   1. 図に示すように、S3バケット名のプレフィックスが`gl-`であると仮定して、次のポリシーを追加します。

   ```json
   {   "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "s3:PutObject",
                   "s3:GetObject",
                   "s3:DeleteObject",
                   "s3:PutObjectAcl"
               ],
               "Resource": "arn:aws:s3:::gl-*/*"
           },
           {
               "Effect": "Allow",
               "Action": [
                   "s3:ListBucket",
                   "s3:AbortMultipartUpload",
                   "s3:ListMultipartUploadParts",
                   "s3:ListBucketMultipartUploads"
               ],
               "Resource": "arn:aws:s3:::gl-*"
           }
       ]
   }
   ```

1. **Next(次へ)**を選択して、ポリシーを確認します。ポリシーに名前を付け（`gl-s3-policy`を使用）、**Create policy(ポリシーの作成)**を選択します。

### IAMロールを作成する {#create-an-iam-role}

1. 引き続きIAMダッシュボードで、左側のメニューの**Roles(ロール)**を選択し、**Create role(ロールの作成)**を選択します。
1. **Trusted entity type(信頼できるエンティティタイプ)**で、`AWS service`を選択します。**Use cases(ユースケース)** で、ドロップダウンリストとラジオボタンの両方で`EC2`を選択し、**Next(次へ)**を選択します。
1. ポリシーフィルターで、上で作成した`gl-s3-policy`を検索して選択し、**Next(次へ)**を選択します。
1. ロールに名前を付けます(`GitLabS3Access`を使用)。必要に応じて、タグを追加します。**Create role(ロールの作成)**を選択します。

このロールは、後で[起動テンプレートを作成する](#create-a-launch-template)ときに使用します。

## ネットワークを設定する {#configuring-the-network}

まず、GitLabクラウドインフラストラクチャ用のVPCを作成します。次に、少なくとも2つの[アベイラビリティーゾーン（AZ）](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html)にパブリックインスタンスとプライベートインスタンスを配置するためのサブネットを作成します。パブリックサブネットには、ルートテーブルの設定と関連付けられたインターネットゲートウェイが必要です。

### Virtual Private Cloud（VPC）を作成する {#creating-the-virtual-private-cloud-vpc}

ここで、ユーザーが制御する仮想ネットワーキング環境であるVPCを作成します。

1. [Amazon Web Services](https://console.aws.amazon.com/vpc/home)にサインインします。
1. 左側のメニューから**Your VPCs**を選択し、**Create VPC**を選択します。「Name tag」に`gitlab-vpc`と入力し、「IPv4 CIDR block」に`10.0.0.0/16`と入力します。専用ハードウェアが不要な場合、「Tenancy」はデフォルトのままでかまいません。準備ができたら、**Create VPC**を選択します。

   ![GitLabクラウドインフラストラクチャ用のVPCを作成します。](img/create_vpc_v17_0.png)

1. VPCを選択し、**Actions(アクション)**、**Edit VPC Settings(VPC設定の編集)**の順に選択し、**Enable DNS resolution(DNS解決を有効にする)**をオンにします。完了したら**Save(保存)**を選択します。

### サブネット {#subnets}

次に、さまざまな可用性ゾーンにサブネットをいくつか作成しましょう。各サブネットが、作成したVPCに関連付けられ、CIDRブロックが重複していないことを確認してください。これにより、冗長性のためにマルチAZを有効にできます。

ロードバランサーとRDSインスタンスに対応するように、プライベートサブネットとパブリックサブネットも作成します。

1. 左側のメニューから **Subnet(サブネット)**を選択します。
1. **Create subnet(サブネットの作成)**を選択します。IPに基づくわかりやすい名前タグを付けます（例: `gitlab-public-10.0.0.0`）。先ほど作成したVPCを選択し、可用性ゾーンを選択します（ここでは`us-west-2a`を使用します）。IPv4 CIDRブロックでは、24サブネット`10.0.0.0/24`を指定します。

   ![サブネットの作成](img/create_subnet_v17_0.png)

1. 同様の手順に従って、次のすべてのサブネットを作成します。

   | 名前タグ                  | タイプ    | アベイラビリティーゾーン | CIDRブロック    |
   | ------------------------- | ------- | ----------------- | ------------- |
   | `gitlab-public-10.0.0.0`  | public  | `us-west-2a`      | `10.0.0.0/24` |
   | `gitlab-private-10.0.1.0` | private | `us-west-2a`      | `10.0.1.0/24` |
   | `gitlab-public-10.0.2.0`  | public  | `us-west-2b`      | `10.0.2.0/24` |
   | `gitlab-private-10.0.3.0` | private | `us-west-2b`      | `10.0.3.0/24` |

1. すべてのサブネットが作成されたら、2つのパブリックサブネットに対して**Auto-assign IPv4(IPv4の自動割り当て)**を有効にします。
   1. 各パブリックサブネットを順番に選択し、**Action(アクション)**、**Edit subet setting(サブネット設定の編集)** の順に選択します。**Enable auto-assign public IPv4 address(パブリックIPv4アドレスの自動割り当てを有効にする)**オプションをオンにして、保存します。

### インターネットゲートウェイ {#internet-gateway}

次に、同じダッシュボードで、Internet Gatewaysに移動して、新しいゲートウェイを作成します。

1. 左側のメニューから**Internet Gateways(インターネットゲートウェイ)**を選択します。
1. **Create internet gateway(インターネットゲートウェイの作成)**を選択し、`gitlab-gateway`という名前を付けて、**Create(作成)**を選択します。
1. テーブルから選択し、**Action(アクション)**ドロップダウンリストから「Attach to VPC(VPCにアタッチ)」を選択します。

   ![インターネットゲートウェイを作成する](img/create_gateway_v17_0.png)

1. リストから`gitlab-vpc`を選択し、**Attach(アタッチ)**をクリックします。

### NATゲートウェイを作成する {#create-nat-gateways}

プライベートサブネットにデプロイされたインスタンスは、アップデートのためにインターネットに接続する必要がありますが、パブリックインターネットからアクセスできないように設定します。そうするには、各パブリックサブネットにデプロイされた[NATゲートウェイ](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)を使用します。

1. VPCダッシュボードに移動し、左側のメニューバーで**NAT Gateways(NATゲートウェイ)**を選択します。
1. **Create NAT Gateway(NATゲートウェイの作成)**を選択し、次を完了します。
   1. **Submet(サブネット)**: ドロップダウンリストから`gitlab-public-10.0.0.0`を選択します。
   1. **Elastic IP Allocation ID(Elastic IPの割り当てID)**: 既存のElastic IPを入力するか、**Allocate Elastic IP address(Elastic IPアドレスを割り当てる)**を選択して、NATゲートウェイに新しいIPを割り当てます。
   1. 必要に応じてタグを追加します。
   1. **Create NAT Gateway(NATゲートウェイの作成)**を選択します。

2番目のNATゲートウェイを作成しますが、今回は2番目のパブリックサブネット`gitlab-public-10.0.2.0`に配置します。

### ルートテーブル {#route-tables}

#### パブリックルートテーブル {#public-route-table}

前の手順で作成したインターネットゲートウェイ経由でパブリックサブネットがインターネットにアクセスできるように、ルートテーブルを作成する必要があります。

VPCダッシュボードで、次の手順に従います。

1. 左側のメニューから**Route Tables(ルートテーブル)**を選択します。
1. **Create Route Table(ルートテーブルの作成)**を選択します。
1. 「Name tag(名前タグ)」に`gitlab-public`を入力し、「VPC」で`gitlab-vpc`を選択します。
1. **Create(作成)**を選択します。

次に、インターネットゲートウェイを新しいターゲットとして追加し、すべての宛先からトラフィックを受信するように設定する必要があります。

1. 左側のメニューから**Route Tables(ルートテーブル)**を選択し、`gitlab-public`ルートを選択して、下部のオプションを表示します。
1. **Routes(ルート)**タブを選択し、**Edit routes(ルートの編集) > Add route(ルートの追加)**を選択して、宛先として`0.0.0.0/0`を設定します。ターゲット列で、**Internet Gateway(インターネットゲートウェイ)**を選択し、先ほど作成した`gitlab-gateway`を選択します。完了したら**Save Changes(変更を保存)**を選択します。

次に、**パブリック**サブネットをルートテーブルに関連付ける必要があります。

1. **Subnet Associations(サブネットの関連付け)**タブを選択し、**Edit subnet associations(サブネットの関連付けの編集)**を選択します。
1. パブリックサブネットのみをオンにし、**Save associations(関連付けの保存)**を選択します。

#### プライベートルートテーブル {#private-route-tables}

各プライベートサブネット内のインスタンスが、同じアベイラビリティーゾーン内の対応するパブリックサブネットにあるNATゲートウェイ経由でインターネットにアクセスできるように、2つのプライベートルートテーブルを作成する必要があります。

1. 上記と同じ手順に従って、2つのプライベートルートテーブルを作成します。それらに`gitlab-private-a`と`gitlab-private-b`という名前を付けます。
1. 次に、宛先が`0.0.0.0/0`で、ターゲットが先ほど作成したNATゲートウェイのいずれかである新しいルートを各プライベートルートテーブルに追加します。
   1. `gitlab-public-10.0.0.0`で作成したNATゲートウェイを、`gitlab-private-a`ルートテーブルの新しいルートのターゲットとして追加します。
   1. 同様に、`gitlab-public-10.0.2.0`のNATゲートウェイを、`gitlab-private-b`の新しいルートのターゲットとして追加します。
1. 最後に、各プライベートサブネットをプライベートルートテーブルに関連付けます。
   1. `gitlab-private-10.0.1.0`を`gitlab-private-a`に関連付けます。
   1. `gitlab-private-10.0.3.0`を`gitlab-private-b`に関連付けます。

## ロードバランサー {#load-balancer}

ロードバランサーを作成し、GitLabアプリケーションサーバー間でポート`80`および`443`に対する受信トラフィックを均等に分散させます。後ほど作成する[スケーリングポリシー](#create-an-auto-scaling-group)に基づいて、必要に応じてインスタンスがロードバランサーに追加または削除されます。さらに、ロードバランサーはインスタンスに対してヘルスチェックを実行します。SSL/TLSを環境内で処理するには[さまざまな方法](../../administration/load_balancer.md#ssl)がありますが、このPOCではバックエンドでSSLを使用せず、ロードバランサーでSSLの終端を行います。

EC2ダッシュボードで、左側のナビゲーションバーの**Load Balancers(ロードバランサー)**を探します。

1. **Create Load Balancer(ロードバランサーの作成)**を選択します。
1. **Network Load Balancer(ネットワークロードバランサー)**を選択し、**Create(作成)**を選択します。
1. ロードバランサー名を`gitlab-loadbalancer`に設定します。次の追加オプションを設定します。
   - スキーム: **Internet-facing(インターネット向け)**を選択します
   - IPアドレスの種類: **IPv4**を選択します
   - VPC: ドロップダウンリストから`gitlab-vpc`を選択します。
   - マッピング: ロードバランサーが両方の可用性ゾーンにトラフィックをルーティングできるように、リストから両方のパブリックサブネットを選択します。
1. ロードバランサーがトラフィックの許可を制御するファイアウォールとして機能するように、セキュリティグループを追加します。セキュリティグループセクションで、**create a new security group(新しいセキュリティグループを作成)**を選択し、名前(ここでは`gitlab-loadbalancer-sec-group`を使用)と説明を付けて、すべての場所からのHTTPおよびHTTPSトラフィックを許可します(`0.0.0.0/0, ::/0`)。また、SSHトラフィックを許可し、カスタムソースを選択して、信頼できる単一のIPアドレス、またはCIDR表記のIPアドレス範囲を追加します。これにより、ユーザーはSSH経由でGitアクションを実行できます。
1. **Listeners and routing(リスナーとルーティング)**セクションで、ポート`22`、`80`、および`443`のリスナーを、以下のターゲットグループを考慮してセットアップします。

   | プロトコル | ポート | ターゲットグループ |
   | ------ | ------ | ------ |
   | TCP | 22 | `gitlab-loadbalancer-ssh-target` |
   | TCP | 80 | `gitlab-loadbalancer-http-target` |
   | TLS | 443 | `gitlab-loadbalancer-http-target` |

   1. ポート`443`のTLSリスナーの場合は、**Security Policy(セキュリティポリシー)**設定を次のようにします。
      1. **Policy name(ポリシー名):** ドロップダウンリストから定義済みのセキュリティポリシーを選択します。AWSドキュメントで、[ネットワークロードバランサーの定義済みSSLセキュリティポリシー](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/create-tls-listener.html#describe-ssl-policies)の詳細を確認できます。GitLabコードベースで、[サポートされているSSL暗号とプロトコル](https://gitlab.com/gitlab-org/gitlab/-/blob/9ee7ad433269b37251e0dd5b5e00a0f00d8126b4/lib/support/nginx/gitlab-ssl#L97-99)のリストを確認します。
      1. **Default SSL/TLS server certificate(デフォルトのSSL/TLSサーバー証明書):** ACMからSSL/TLS証明書を選択するか、証明書をIAMにアップロードします。

1. 作成した各リスナーに対して、ターゲットグループを作成し、前の表に基づいて割り当てる必要があります。まだEC2インスタンスを作成していないため、ターゲットを登録する必要はありません。EC2インスタンスは後で[自動スケーリンググループのセットアップ](#create-an-auto-scaling-group)の一部として作成され、割り当てられます。
   1. `Create target group`を選択します。ターゲットタイプとして**Instances(インスタンス)**を選択します。
   1. 各リスナーに適切な`Target group name`を選択します。
      - `gitlab-loadbalancer-http-target` - ポート80のTCPプロトコル
      - `gitlab-loadbalancer-ssh-target` - ポート22のTCPプロトコル
   1. IP address typeには**IPv4**を選択します。
   1. VPCドロップダウンリストから`gitlab-vpc`を選択します。
   1. `gitlab-loadbalancer-http-target`のヘルスチェックでは、[準備状況チェックエンドポイントを使用](../../administration/load_balancer.md#readiness-check)する必要があります。[ヘルスチェックエンドポイント](../../administration/monitoring/health_check.md)の[IP許可リスト](../../administration/monitoring/ip_allowlist.md)に、[VPC IPアドレス範囲（CIDR）](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-security-groups.html)を追加する必要があります。
   1. `gitlab-loadbalancer-ssh-target`のヘルスチェックでは、**TCP**を選択します。
      - ポート80と443の両方のリスナーに`gitlab-loadbalancer-http-target`を割り当てます。
      - ポート22のリスナーに`gitlab-loadbalancer-ssh-target`を割り当てます。
   1. 一部の属性は、ターゲットグループの作成後にのみ設定できます。要件に応じて設定できる機能の例を次に示します。
      - [Client IP preservation](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#client-ip-preservation)は、ターゲットグループではデフォルトで有効になっています。これにより、ロードバランサーに接続しているクライアントのIPがGitLabアプリケーションで保持されます。要件に応じて、有効/無効を切り替えることができます。

      - ターゲットグループでは、[プロキシプロトコル](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#proxy-protocol)がデフォルトで無効になっています。この機能により、ロードバランサーはプロキシプロトコルヘッダーに追加情報を送信できます。これを有効にする場合は、内部ロードバランサー、NGINXなどの他の環境コンポーネントも同様に構成されていることを確認してください。このPOCでは、[後でGitLabノード](#proxy-protocol)で有効にするだけで済みます。

1. **Create Load Balancer(ロードバランサーの作成)**を選択します。

ロードバランサーが起動して稼働したら、Security Groupsに戻り、NLB経由のアクセスのみに制限するなど、必要に応じてアクセス設定を調整します。

### ロードバランサーのDNSを設定する {#configure-dns-for-load-balancer}

Route 53ダッシュボードで、左側のナビゲーションバーの**Hosted zones(ホストゾーン)**を選択します。

1. 既存のホストゾーンを選択するか、ドメインのホストゾーンがまだない場合は、**Create Hosted Zone(ホストゾーンの作成)**を選択してドメイン名を入力し、**Create(作成)**を選択します。
1. **Create record(レコードの作成)**を選択し、次の値を指定します。
   1. **Name(名前):** ドメイン名(デフォルト値)を使用するか、サブドメインを入力します。
   1. **Type(種類):** **A - IPv4 address(A - IPv4アドレス)**を選択します。
   1. **Alias(エイリアス):** デフォルトでは**無効**になっています。このオプションを有効にします。
   1. **Route traffic to(トラフィックのルーティング先):** **Alias to Network Load Balancer(ネットワークロードバランサーへのエイリアス)**を選択します。
   1. **Region(リージョン):** ネットワークロードバランサーが存在するリージョンを選択します。
   1. **Choose network load balancer(ネットワークロードバランサーの選択):** 先ほど作成したネットワークロードバランサーを選択します。
   1. **Routing Policy(ルーティングポリシー):** **Simple(シンプル)**を使用しますが、ユースケースに基づいて別のポリシーを選択できます。
   1. **Evaluate Target Health(ターゲットヘルスの評価):** これを**No(いいえ)**に設定しますが、ターゲットのヘルス状態に基づいてロードバランサーがトラフィックをルーティングするように選択できます。
   1. **Create(作成)**を選択します。
1. Route 53を通じてドメインを登録した場合、これで完了です。別のドメインレジストラを使用した場合は、ドメインレジストラでDNSレコードを更新する必要があります。次を行う必要があります。
   1. **Hosted zones(ホストゾーン)**を選択し、上記で追加したドメインを選択します。
   1. `NS`レコードのリストが表示されます。ドメインレジストラの管理者パネルから、それぞれをドメインのDNSレコードに`NS`レコードとして追加します。これらの手順は、ドメインレジストラによって異なる場合があります。行き詰まった場合は、**「レジストラの名前」DNSレコードの追加**をGoogleで検索すると、ドメインレジストラに固有のヘルプ記事が見つかります。

具体的な手順は使用するレジストラによって異なり、このガイドの範囲外です。

## PostgreSQLとRDS {#postgresql-with-rds}

データベースサーバーには、冗長性を確保するためにマルチAZを提供するAmazon RDS for PostgreSQLを使用します（[Auroraはサポートして**いません**](https://gitlab.com/gitlab-partners-public/aws/aws-known-issues/-/issues/10)）。まず、セキュリティグループとサブネットグループを作成し、次に実際のRDSインスタンスを作成します。

### RDSセキュリティグループ {#rds-security-group}

データベースのセキュリティグループを作成することで、後で`gitlab-loadbalancer-sec-group`にデプロイするインスタンスからのインバウンドトラフィックを許可します。

1. EC2ダッシュボードで、左側のメニューバーから**Security Groups(セキュリティグループ)**を選択します。
1. **Create security group(セキュリティグループを作成)**を選択します。
1. 名前（ここでは`gitlab-rds-sec-group`を使用）、説明を入力し、**VPC**ドロップダウンリストから`gitlab-vpc`を選択します。
1. **Inbound rules(インバウンドルール)**セクションで、**Add rule(ルールを追加)**を選択し、次を設定します。
   1. **Type(種類):** **PostgreSQL**ルールを検索して選択します。
   1. **Source type(ソースタイプ):** 「Custom(カスタム)」に設定します。
   1. **Source(ソース):** 先ほど作成した`gitlab-loadbalancer-sec-group`を選択します。
1. 完了したら、**Create security group(セキュリティグループを作成)**を選択します。

### RDSサブネットグループ {#rds-subnet-group}

1. RDSダッシュボードに移動し、左側のメニューから**Subnet Groups(サブネットグループ)**を選択します。
1. **Create DB Subnet Group(DBサブネットグループを作成)**を選択します。
1. **Subnet group details(サブネットグループの詳細)**で、名前（ここでは`gitlab-rds-group`を使用）、説明を入力し、VPCドロップダウンリストから`gitlab-vpc`を選択します。
1. **Availability Zones(可用性ゾーン)**ドロップダウンリストから、設定したサブネットを含む可用性ゾーンを選択します。この例では、`eu-west-2a`と`eu-west-2b`を追加します。
1. **Subnets(サブネット)**ドロップダウンリストから、[サブネットセクション](#subnets)で定義した2つのプライベートサブネット（`10.0.1.0/24`と`10.0.3.0/24`）を選択します。
1. 準備ができたら**Create(作成)**を選択します。

### データベースを作成する {#create-the-database}

{{< alert type="warning" >}}

データベースには、バースト可能インスタンス（tクラスインスタンス）を使用しないでください。高負荷状態が長時間続くとCPUクレジットが枯渇し、パフォーマンスの問題が発生する可能性があります。

{{< /alert >}}

それでは、データベースを作成しましょう。

1. RDSダッシュボードに移動し、左側のメニューから**Databases(データベース)**を選択し、**Create database(データベースを作成)**を選択します。
1. データベースの作成方法として **Standard Create(標準作成)**を選択します。
1. データベースエンジンとして**PostgreSQL**を選択し、[データベース要件](../requirements.md#postgresql)でGitLabバージョンに定義されている最小PostgreSQLバージョンを選択します。
1. これは本番環境サーバーであるため、**Templates(テンプレート)**セクションから**Production(本番環境)**を選択しましょう。
1. **Availability & durability(可用性と耐久性)**で、**Multi-AZ DB instance(マルチAZ DBインスタンス)**を選択して、別の[可用性ゾーン](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)にプロビジョニングされたスタンバイRDSインスタンスを作成します。
1. **Settings(設定)**で、以下を使用します。
   - DBインスタンス識別子の`gitlab-db-ha`
   - マスターユーザー名の`gitlab`
   - 非常に安全なマスターパスワード

   これらの情報は後で必要になるため、メモしておきます。

1. DBインスタンスのサイズについては、**Standard classes(標準クラス)**を選択し、ドロップダウンリストから要件を満たすインスタンスサイズを選択します。ここでは`db.m5.large`インスタンスを使用します。
1. **Storage(ストレージ)**で、次を設定します。
   1. ストレージタイプのドロップダウンリストから**Provisioned IOPS (SSD)(プロビジョニングされたIOPS (SSD))**を選択します。プロビジョニングされたIOPS (SSD)ストレージは、この用途に最適です(ただし、コスト削減のために汎用(SSD)を選択することもできます)。詳細については、[Amazon RDSのストレージ](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html)を参照してください。
   1. ストレージを割り当て、プロビジョニングされたIOPSを設定します。ここでは、それぞれ最小値の`100`と`1000`を使用します。
   1. ストレージの自動スケールを有効にし(オプション)、ストレージの最大しきい値を設定します。
1. **Connectivity(接続)**で、次を設定します。
   1. **Virtual Private Cloud (VPC)**ドロップダウンリストで、先ほど作成したVPC（`gitlab-vpc`）を選択します。
   1. **DB subnet group(DBサブネットグループ)** で、先ほど作成したサブネットグループ（`gitlab-rds-group`）を選択します。
   1. パブリックアクセスを**No(いいえ)**に設定します。
   1. **VPC security group(VPCセキュリティグループ)**で、**Choose existing(既存のものを選択)**を選択し、ドロップダウンリストから上記で作成した`gitlab-rds-sec-group`を選択します。
   1. **Additional configuration(追加設定)**で、データベースポートをデフォルトの`5432`のままにします。
1. **Database authentication(データベース認証)**で、**Password authentication(パスワード認証)**を選択します。
1. **Additional configuration(追加設定)**セクションを展開し、次を完了します。
   1. 初期データベース名。ここでは`gitlabhq_production`を使用します。
   1. 優先するバックアップ設定を構成します。
   1. ここで行うもう1つの変更は、**Maintenance(メンテナンス)**でマイナーバージョンの自動更新を無効にすることです。
   1. 他のすべての設定はそのままにするか、必要に応じて微調整します。
   1. 問題なければ、**Create database(データベースを作成)**を選択します。

これで、データベースが作成されました。次に、ElastiCacheを使用してRedisをセットアップします。

## ElastiCacheを使用したRedis {#redis-with-elasticache}

ElastiCacheは、ホストされるインメモリキャッシュ型のソリューションです。Redisは独自の永続性を保持し、GitLabアプリケーションのセッションデータ、一時的なキャッシュ情報、バックグラウンドジョブキューの保存に使用されます。

### Redisセキュリティグループを作成する {#create-a-redis-security-group}

1. EC2ダッシュボードに移動します。
1. 左側のメニューから**Security Groups(セキュリティグループ)**を選択します。
1. **Create security group(セキュリティグループを作成)**を選択し、詳細を入力します。名前(ここでは`gitlab-redis-sec-group`を使用)を付け、説明を追加して、先ほど作成したVPC(`gitlab-vpc`)を選択します。
1. **Inbound rules(インバウンドルール)**セクションで、**Add rule(ルールを追加)**を選択し、**Custom TCP(カスタムTCP)**ルールを追加して、ポート`6379`を設定し、「カスタム」ソースを先ほど作成した`gitlab-loadbalancer-sec-group`として設定します。
1. 完了したら、**Create security group(セキュリティグループを作成)**を選択します。

### Redisサブネットグループ {#redis-subnet-group}

1. AWSコンソールからElastiCacheダッシュボードに移動します。
1. 左側のメニューの**Subnet Groups(サブネットグループ)**に移動し、新しいサブネットグループを作成します(ここでは`gitlab-redis-group`という名前を付けます)。先ほど作成したVPC(`gitlab-vpc`)を選択し、選択したサブネットテーブルに[プライベートサブネット](#subnets)のみが含まれていることを確認します。
1. 準備ができたら**Create(作成)**を選択します。

   ![サブネットグループを作成](img/ec_subnet_v17_0.png)

### Redis Clusterを作成する {#create-the-redis-cluster}

1. ElastiCacheダッシュボードに戻ります。
1. 左側のメニューで**Redis caches**を選択し、**Create Redis cache**を選択して、新しいRedisクラスターを作成します。
1. **Deployment option**で、**Design your own cache**を選択します。
1. **Creation method**で、**Cluster cache**を選択します。
1. **Cluster mode**は[サポートされていない](../../administration/redis/replication_and_failover_external.md#requirements)ため、**Disabled**を選択します。クラスターモードを無効にしても、複数のアベイラビリティーゾーンにRedisをデプロイすることは可能です。
1. **Cluster info**で、クラスター名（`gitlab-redis`）と説明を入力します。
1. **Location**で、**AWS Cloud**を選択し、**Multi-AZ**オプションを有効にします。
1. Cluster settingsセクション:
   1. Engine versionでは、[Redis要件](../requirements.md#redis)に記載されている、ご利用のGitLabバージョンに対応するRedisバージョンを選択します。
   1. ポートは`6379`のままにします。これは先ほどRedisセキュリティグループで使用した値です。
   1. ノードタイプ（少なくとも`cache.t3.medium`、必要に応じて調整）とレプリカの数を選択します。
1. Connectivity settingsセクション:
   1. **Network type**: IPv4
   1. **Subnet groups**: **Choose existing subnet group**を選択し、先ほど作成した`gitlab-redis-group`を選択します。
1. Availability Zone placementsセクション:
   1. 優先するアベイラビリティーゾーンを手動で選択し、「Replica 2」で他の2つとは異なるゾーンを選択します。

      ![Redisグループに使用するアベイラビリティーゾーンを選択します。](img/ec_az_v17_0.png)

1. **Next**を選択します。
1. セキュリティ設定で、セキュリティグループを編集し、先ほど作成した`gitlab-redis-sec-group`を選択します。**Next**を選択します。
1. 残りの設定はデフォルト値のままにするか、必要に応じて編集します。
1. 完了したら**Create**を選択します。

## 踏み台ホストを設定する {#setting-up-bastion-hosts}

GitLabインスタンスはプライベートサブネット内にあるため、設定変更やアップグレードなどを行う際に、SSHを使用してこれらのインスタンスに接続する方法が必要です。その手段の1つが、[踏み台ホスト](https://en.wikipedia.org/wiki/Bastion_host)を使用することです。ジャンプボックスとも呼ばれます。

{{< alert type="note" >}}

踏み台ホストを管理したくない場合は、インスタンスへのアクセスに[AWS Systems ManagerのSession Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)を使用するよう設定できます。この設定は、このドキュメントの範囲外です。

{{< /alert >}}

### 踏み台サーバーAを作成する {#create-bastion-host-a}

1. EC2ダッシュボードに移動し、**Launch instance(インスタンスを起動)**を選択します。
1. **Name and tags(名前とタグ)**セクションで、**Name(名前)**を`Bastion Host A`に設定します。
1. 最新の**Ubuntu Server LTS (HVM)** AMIを選択します。[サポートされるOSバージョンの最新情報](../../administration/package_information/supported_os.md)については、GitLabドキュメントを確認してください。
1. インスタンスタイプを選択します。ここでは、踏み台サーバーを使用して他のインスタンスにSSH接続するだけなので、`t2.micro`を使用します。
1. **Key pair(キーペア)**セクションで、**Create new key pair(新しいキーペアを作成)**を選択します。
   1. キーペアに名前(ここでは`bastion-host-a`を使用)を付け、後で使用するために`bastion-host-a.pem`ファイルを保存します。
1. ネットワーク設定セクションを編集します。
   1. **VPC**で、ドロップダウンリストから`gitlab-vpc`を選択します。
   1. **Subnet(サブネット)**で、先ほど作成したパブリックサブネット(`gitlab-public-10.0.0.0`)を選択します。
   1. **Auto-assign Public IP(パブリックIPの自動割り当て)**で、**Disabled(無効)**が選択されていることを確認します。[Elastic IPアドレス](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html)は、[次のセクション](#assign-elastic-ip-to-the-bastion-host-a)でサーバーに後で割り当てられます。
   1. **Firewall(ファイアウォール)** で **Create security group(セキュリティグループを作成)**を選択し、**Security group name(セキュリティグループ名)**(ここでは`bastion-sec-group`を使用)を入力して、説明を追加します。
   1. あらゆる場所からのSSHアクセスを有効にします(`0.0.0.0/0`)。より厳格なセキュリティが必要な場合は、CIDR表記で単一のIPアドレスまたはIPアドレス範囲を指定します。
1. ストレージについては、すべてをデフォルトのままにし、8 GBのルートボリュームのみを追加します。このインスタンスには何も保存しません。
1. すべての設定を確認し、問題なければ、**Launch Instance(インスタンスを起動)**を選択します。

#### 踏み台サーバーAにElastic IPを割り当てる {#assign-elastic-ip-to-the-bastion-host-a}

1. EC2ダッシュボードに移動し、**Network & Security**を選択します。
1. **Elastic IPs**を選択し、`Network border group`を`us-west-2`に設定します。
1. **Allocate**を選択します。
1. 作成されたElastic IPアドレスを選択します。
1. **Actions**、**Associate Elastic IP address**の順に選択します。
1. **Resource Type**で**Instance**を選択し、**Instance**ドロップダウンリストから`Bastion Host A`ホストを選択します。
1. **Associate**を選択します。

#### インスタンスにSSHで接続できることを確認する {#confirm-that-you-can-ssh-into-the-instance}

1. EC2ダッシュボードで、左側のメニューから**Instances**を選択します。
1. インスタンスの一覧から**Bastion Host A**を選択します。
1. **Connect**を選択し、表示される接続手順に従います。
1. 正常に接続できたら、冗長性を確保するために2つ目の踏み台ホストの設定に進みます。

### 踏み台サーバーBを作成する {#create-bastion-host-b}

1. 上記と同じ手順に従ってEC2インスタンスを作成しますが、次の変更を加えます。
   1. **Subnet(サブネット)** では、先ほど作成した2番目のパブリックサブネット(`gitlab-public-10.0.2.0`)を選択します。
   1. **Add Tags(タグの追加)**セクションで、2つのインスタンスを簡単に識別できるように、`Key: Name`と`Value: Bastion Host B`を設定します。
   1. セキュリティグループは、上記で作成した既存の`bastion-sec-group`を選択します。

### SSHエージェント転送を使用する {#use-ssh-agent-forwarding}

Linuxを実行しているEC2インスタンスでは、SSH認証にプライベートキーファイルを使用します。SSHクライアントとクライアントに保存されているプライベートキーファイルを使用して、踏み台サーバーに接続します。プライベートキーファイルが踏み台サーバーに存在しないため、プライベートサブネット内のインスタンスに接続することはできません。

踏み台サーバーにプライベートキーファイルを保存するのは良くありません。そうする代わりに、クライアントでSSHエージェント転送を使用します。

たとえば、コマンドラインの`ssh`クライアントは、次のような`-A`スイッチでエージェント転送を使用します。

```shell
ssh –A user@<bastion-public-IP-address>
```

他のクライアントでSSHエージェント転送を使用する手順については、[Securely Connect to Linux Instances Running in a Private Amazon VPC](https://aws.amazon.com/blogs/security/securely-connect-to-linux-instances-running-in-a-private-amazon-vpc/)を参照してください。

## GitLabをインストールしてカスタムAMIを作成する {#install-gitlab-and-create-custom-ami}

後で起動設定に使用するため、設定済みのカスタムGitLab AMIが必要です。まず公式のGitLab AMIを使用してGitLabインスタンスを作成します。次に、PostgreSQL、Redis、Gitaly向けのカスタム設定を追加します。必要に応じて、公式のGitLab AMIを使用せず、独自に選択したEC2インスタンスを起動し、[GitLabを手動でインストール](https://about.gitlab.com/install/)することもできます。

### GitLabをインストールする {#install-gitlab}

EC2ダッシュボードで、次の手順に従います。

1. 以下の「[AWSで公式GitLab作成AMI IDを見つける](#find-official-gitlab-created-ami-ids-on-aws)」というタイトルのセクションを使用して、正しいAMIを見つけ、**Launch(起動)**を選択します。
1. **Name and tags(名前とタグ)**セクションで、**Name(名前)**を`GitLab`に設定します。
1. **Instance type(インスタンスタイプ)**ドロップダウンリストで、ワークロードに基づくインスタンスタイプを選択します。[ハードウェア要件](../requirements.md)を参照して、ニーズに合ったものを選択します(少なくとも`c5.2xlarge`で、100人のユーザーに対応すれば十分です)。
1. **Key pair(キーペア)**セクションで、**Create new key pair(新しいキーペアを作成)**を選択します。
   1. キーペアに名前(ここでは`gitlab`を使用)を付け、後で使用するために`gitlab.pem`ファイルを保存します。
1. **Network settings(ネットワーク設定)**セクションで:
   1. **VPC**: 先ほど作成したVPCである`gitlab-vpc`を選択します。
   1. **Submet(サブネット)**: 先ほど作成したサブネットのリストから`gitlab-private-10.0.1.0`を選択します。
   1. **Auto-assign Public IP(パブリックIPの自動割り当て)**: `Disable`を選択します。
   1. **Firewall**: **Select existing security group**を選択し、先ほど作成した`gitlab-loadbalancer-sec-group`を選択します。
1. ストレージの場合、ルートボリュームはデフォルトで8 GiBであり、そこにデータを保存しないことを考えると十分なはずです。
1. すべての設定を確認し、問題なければ、**Launch Instance(インスタンスを起動)**を選択します。

### カスタム構成を追加する {#add-custom-configuration}

[SSHエージェント転送](#use-ssh-agent-forwarding)を使用して、**踏み台サーバーA**経由でGitLabインスタンスに接続します。接続したら、次のカスタム構成を追加します。

#### Let's Encryptを無効にする {#disable-lets-encrypt}

ロードバランサーでSSL証明書を追加するため、GitLab組み込みのLet's Encryptのサポートは必要ありません。`https`ドメインを使用する場合、 Let's Encrypt[はデフォルトで有効](https://docs.gitlab.com/omnibus/settings/ssl/#enable-the-lets-encrypt-integration)になっているため、明示的に無効にする必要があります。

1. `/etc/gitlab/gitlab.rb`を開き、無効にします。

   ```ruby
   letsencrypt['enable'] = false
   ```

1. ファイルを保存し、変更を有効にするために再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

#### PostgreSQLに必要な拡張機能をインストールする {#install-the-required-extensions-for-postgresql}

GitLabインスタンスからRDSインスタンスに接続し、アクセスを確認して、必要な拡張機能`pg_trgm`および`btree_gist`をインストールします。

ホストまたはエンドポイントを見つけるには、**Amazon RDS > Database(データベース)**に移動し、先ほど作成したデータベースを選択します。**Connectivity & security(接続とセキュリティ)**タブのエンドポイントを探します。

コロンとポート番号を含めないでください。

```shell
sudo /opt/gitlab/embedded/bin/psql -U gitlab -h <rds-endpoint> -d gitlabhq_production
```

`psql`プロンプトで拡張機能を作成します。完了したらセッションを終了します。

```shell
psql (10.9)
Type "help" for help.

gitlab=# CREATE EXTENSION pg_trgm;
gitlab=# CREATE EXTENSION btree_gist;
gitlab=# \q
```

#### PostgreSQLおよびRedisに接続するようにGitLabを設定する {#configure-gitlab-to-connect-to-postgresql-and-redis}

1. `/etc/gitlab/gitlab.rb`を編集し、`external_url 'http://<domain>'`オプションを見つけて、使用している`https`ドメインに変更します。

1. GitLabデータベースの設定を探し、必要に応じてコメントアウトを解除します。現在のケースでは、データベースアダプター、エンコード、ホスト、名前、ユーザー名、パスワードを指定します。

   ```ruby
   # Disable the built-in Postgres
    postgresql['enable'] = false

   # Fill in the connection details
   gitlab_rails['db_adapter'] = "postgresql"
   gitlab_rails['db_encoding'] = "unicode"
   gitlab_rails['db_database'] = "gitlabhq_production"
   gitlab_rails['db_username'] = "gitlab"
   gitlab_rails['db_password'] = "mypassword"
   gitlab_rails['db_host'] = "<rds-endpoint>"
   ```

1. 次に、Redisセクションを設定し、ホストを追加してポートのコメントアウトを解除する必要があります。

   ```ruby
   # Disable the built-in Redis
   redis['enable'] = false

   # Fill in the connection details
   gitlab_rails['redis_host'] = "<redis-endpoint>"
   gitlab_rails['redis_port'] = 6379
   ```

1. 最後に、変更を有効にするためにGitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. チェックとサービスステータスを実行して、すべてが正しく設定されていることを確認することもできます。

   ```shell
   sudo gitlab-rake gitlab:check
   sudo gitlab-ctl status
   ```

#### Gitalyを設定する {#set-up-gitaly}

{{< alert type="warning" >}}

このアーキテクチャでは、単一のGitalyサーバーを持つと、単一障害点が発生します。この制限を解消するには、[Gitaly Cluster](../../administration/gitaly/praefect.md)を使用します。

{{< /alert >}}

Gitalyは、Gitリポジトリへの高レベルのRPCアクセスを提供するサービスです。以前に構成した[プライベートサブネット](#subnets)のいずれかにある個別のEC2インスタンス上で、Gitalyを有効にして構成する必要があります。

GitalyをインストールするEC2インスタンスを作成します。

1. EC2ダッシュボードで**Launch instance**を選択します。
1. **Name and tags**セクションで、**Name**に`Gitaly`と指定します。
1. AMIを選択します。この例では、最新の**Ubuntu Server LTS (HVM), SSD Volume Type**を選択します。[サポート対象の最新のOSバージョン](../../install/package/_index.md)については、GitLabドキュメントを確認してください。
1. インスタンスタイプを選択します。`m5.xlarge`を選択します。
1. **Key pair**セクションで、**Create new key pair**を選択します。
   1. キーペアに名前（この例では`gitaly`）を付け、後で使用するために`gitaly.pem`ファイルを保存します。
1. Network settingsセクション:
   1. **VPC**で、ドロップダウンリストから`gitlab-vpc`を選択します。
   1. **Subnet**で、先ほど作成したプライベートサブネット（`gitlab-private-10.0.1.0`）を選択します。
   1. **Auto-assign Public IP**で、**Disable**が選択されていることを確認します。
   1. **Firewall**で、**Create security group**を選択し、**Security group name**（この例では`gitlab-gitaly-sec-group`）を入力し、説明を追加します。
      1. **Custom TCP**ルールを作成し、ポート`8075`を**Port Range**に追加します。**Source**には`gitlab-loadbalancer-sec-group`を選択します。
      1. さらに、踏み台ホストから[SSHエージェント転送](#use-ssh-agent-forwarding)を使用して接続できるように、`bastion-sec-group`からのSSH接続を許可するインバウンドルールを追加します。
1. Root volume sizeを`20 GiB`に増やし、**Volume Type**を`Provisioned IOPS SSD (io1)`に変更します。（ボリュームサイズには任意の値を設定できます。リポジトリストレージ要件を満たす十分な容量を確保してください。）
   1. **IOPS**には`1000`（20 GiB x 50 IOPS）を設定します。1 GiBあたり最大50 IOPSまでプロビジョニングできます。より大きなボリュームを選択する場合は、それに応じてIOPSを増やします。`git`のように、多数の小さなファイルを直列的に書き込むワークロードでは、高性能ストレージが必要となるため、`Provisioned IOPS SSD (io1)`を選択します。
1. すべての設定を確認し、問題がなければ、**Launch Instance**を選択します。

{{< alert type="note" >}}

設定やリポジトリデータをルートボリュームに保存する代わりに、リポジトリストレージとして追加のEBSボリュームを割り当てることもできます。前述のガイダンスと同様の手順に従ってください。[Amazon EBSの料金ページ](https://aws.amazon.com/ebs/pricing/)を参照してください。

{{< /alert >}}

EC2インスタンスの準備が整ったので、[ドキュメントに従ってGitLabをインストールし、Gitalyを専用サーバー上にセットアップ](../../administration/gitaly/configure_gitaly.md#run-gitaly-on-its-own-server)します。先ほど[作成したGitLabインスタンス](#install-gitlab)で、前述のドキュメントに記載されたクライアント側のセットアップ手順を実行します。

##### Elastic File System（EFS） {#elastic-file-system-efs}

{{< alert type="warning" >}}

GitLabのパフォーマンスに悪影響を与える可能性があるため、EFSの使用は推奨されません。詳細については、[クラウドベースのファイルシステムの回避に関するドキュメント](../../administration/nfs.md#avoid-using-cloud-based-file-systems)を参照してください。

{{< /alert >}}

それでもEFSを使用する場合は、[PosixUser](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-efs-accesspoint.html#cfn-efs-accesspoint-posixuser)属性を省略するか、Gitalyがインストールされているシステム上の`git`ユーザーの固有識別子（UID）とグループID（GID）を正しく指定してください。UIDとGIDは、次のコマンドで取得できます。

```shell
# UID
$ id -u git

# GID
$ id -g git
```

また、複数の[アクセスポイント](https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html)を設定しないでください。特に、異なる認証情報を指定している場合は避ける必要があります。Gitaly以外のアプリケーションが、Gitalyストレージディレクトリに対する権限を操作し、Gitalyが正常に動作しなくなるおそれがあります。この問題の具体例については、[`omnibus-gitlab`イシュー8893](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8893)を参照してください。

#### プロキシ経由のSSLのサポートを追加する {#add-support-for-proxied-ssl}

[ロードバランサー](#load-balancer)でSSLを終端しているため、`/etc/gitlab/gitlab.rb`でこの設定を行うには、[プロキシ経由のSSLをサポートする](https://docs.gitlab.com/omnibus/settings/ssl/#configure-a-reverse-proxy-or-load-balancer-ssl-termination)手順に従います。

`gitlab.rb`ファイルへの変更を保存した後、必ず`sudo gitlab-ctl reconfigure`を実行してください。

#### 承認されたSSHキーの高速検索 {#fast-lookup-of-authorized-ssh-keys}

GitLabへのアクセスを許可されたユーザーの公開SSHキーは、`/var/opt/gitlab/.ssh/authorized_keys`に保存されています。通常は共有ストレージを使用し、ユーザーがSSH経由でGitアクションを実行する際に、すべてのインスタンスがこのファイルにアクセスできるようにします。しかし、今回のセットアップでは共有ストレージを使用していないため、GitLabデータベース内のインデックス検索を使用してSSHユーザーを認証するように設定を更新します。

[SSHキーの高速検索の設定](../../administration/operations/fast_ssh_key_lookup.md#set-up-fast-lookup)手順に従って、`authorized_keys`ファイルの使用からデータベースに切り替えてください。

高速検索を設定しない場合、SSH経由でGitアクションを実行すると次のエラーが返されます。

```shell
Permission denied (publickey).
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

#### ホストキーを設定する {#configure-host-keys}

通常は、プライマリアプリケーションサーバー上の`/etc/ssh/`の内容（プライマリキーと公開キー）を、すべてのセカンダリサーバー上の`/etc/ssh`に手動でコピーします。これにより、ロードバランサーの背後にあるクラスター内のサーバーにアクセスする際に、誤った中間者攻撃のアラートが発生するのを防ぐことができます。

カスタムAMIの一部として静的ホストキーを作成することで、これを自動化します。これらのホストキーもEC2インスタンスが起動するたびにローテーションされるため、カスタムAMIに「ハードコーディング」することは回避策となります。

GitLabインスタンスで、次のコマンドを実行します。

```shell
sudo mkdir /etc/ssh_static
sudo cp -R /etc/ssh/* /etc/ssh_static
```

`/etc/ssh/sshd_config`で、次の内容を更新します。

```shell
# HostKeys for protocol version 2
HostKey /etc/ssh_static/ssh_host_rsa_key
HostKey /etc/ssh_static/ssh_host_dsa_key
HostKey /etc/ssh_static/ssh_host_ecdsa_key
HostKey /etc/ssh_static/ssh_host_ed25519_key
```

#### Amazon S3オブジェクトストレージ {#amazon-s3-object-storage}

共有ストレージにNFSを使用しないため、バックアップ、アーティファクト、LFSオブジェクト、アップロード、マージリクエストの差分、コンテナレジストリのイメージなどを保存するために[Amazon S3](https://aws.amazon.com/s3/)バケットを使用します。ドキュメントには、これらの各データ型に対する [オブジェクトストレージの設定方法](../../administration/object_storage.md)、およびGitLabでのオブジェクトストレージの使用に関するその他の情報が含まれています。

{{< alert type="note" >}}

先ほど作成した[AWS IAMプロファイル](#create-an-iam-role)を使用しているため、オブジェクトストレージの設定時にAWSアクセスキーとシークレットアクセスキーのキー/バリューペアを省略してください。代わりに、上記リンクのオブジェクトストレージドキュメントに示すように、構成で`'use_iam_profile' => true`を使用します。

{{< /alert >}}

`gitlab.rb`ファイルへの変更を保存した後、必ず`sudo gitlab-ctl reconfigure`を実行してください。

---

これで、GitLabインスタンスの構成変更は完了です。次に、このインスタンスに基づいてカスタムAMIを作成し、起動構成と自動スケーリンググループに使用します。

### IP許可リスト {#ip-allowlist}

先ほど作成した`gitlab-vpc`の[VPC IPアドレス範囲（CIDR）](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-security-groups.html)を、[ヘルスチェックエンドポイント](../../administration/monitoring/health_check.md)の[IP許可リスト](../../administration/monitoring/ip_allowlist.md)に追加する必要があります。

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '10.0.0.0/16']
   ```

1. GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### プロキシプロトコル {#proxy-protocol}

先ほど作成した[ロードバランサー](#load-balancer)でプロキシプロトコルが有効になっている場合は、`gitlab.rb`ファイルでもこれを[有効](https://docs.gitlab.com/omnibus/settings/nginx.html#configuring-the-proxy-protocol)にする必要があります。

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   nginx['proxy_protocol'] = true
   nginx['real_ip_trusted_addresses'] = [ "127.0.0.0/8", "IP_OF_THE_PROXY/32"]
   ```

1. GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 初めてサインインする {#sign-in-for-the-first-time}

[ロードバランサーのDNS](#configure-dns-for-load-balancer)を設定したときに使用したドメイン名を使用すると、ブラウザでGitLabにアクセスできるようになります。

GitLabのインストール方法や、他の手段でパスワードを変更したかどうかに応じて、デフォルトのパスワードは次のいずれかになります。

- 公式のGitLab AMIを使用した場合のインスタンスID
- `/etc/gitlab/initial_root_password`に24時間保存されるランダムに生成されたパスワード

デフォルトのパスワードを変更するには、`root`ユーザーとしてデフォルトのパスワードでサインインし、[ユーザープロファイルで変更](../../user/profile/user_passwords.md#change-your-password)します。

[自動スケーリンググループ](#create-an-auto-scaling-group)が新しいインスタンスを起動すると、ユーザー名`root`と新しく作成されたパスワードでサインインできます。

### カスタムAMIを作成する {#create-custom-ami}

EC2ダッシュボードで、次の手順に従います。

1. [先ほど作成](#install-gitlab)した`GitLab`インスタンスを選択します。
1. **Actions**を選択し、**Image and templates**までスクロールダウンして**Create image**を選択します。
1. イメージの名前と説明を入力します（この例ではどちらにも`GitLab-Source`を使用します）。
1. それ以外の設定はすべてデフォルトのままにして、**Create Image**を選択します。

これで、次のステップで起動設定を作成するために使用するカスタムAMIが作成されました。

## オートスケールグループ内にGitLabをデプロイする {#deploy-gitlab-inside-an-auto-scaling-group}

### 起動テンプレートを作成する {#create-a-launch-template}

EC2ダッシュボードで、次の手順に従います。

1. 左側のメニューから**Launch Templates**を選択し、**create launch template**を選択します。
1. 起動テンプレートの名前を入力します（この例では`gitlab-launch-template`）。
1. **Launch template contents**を選択し、**My AMIs**タブを選択します。
1. **Owned by me**を選択し、先ほど作成したカスタムAMIである`GitLab-Source`を選択します。
1. ニーズに最適なインスタンスタイプを選択します（少なくとも`c5.2xlarge`）。
1. **Key pair**セクションで、**Create new key pair**を選択します。
   1. キーペアに名前（この例では`gitlab-launch-template`）を付け、後で使用するために`gitlab-launch-template.pem`ファイルを保存します。
1. ルートボリュームはデフォルトで8 GiBに設定されています。ここにはデータを保存しないため、この容量で十分です。**Configure Security Group**を選択します。
1. **Select and existing security group**チェックボックスをオンにして、先ほど作成した`gitlab-loadbalancer-sec-group`を選択します。
1. **Network settings**セクション:
   1. **Firewall**: **Select existing security group**を選択し、先ほど作成した`gitlab-loadbalancer-sec-group`を選択します。
1. **Advanced details**セクション:
   1. **IAM instance profile**: [先ほど作成](#create-an-iam-role)した`GitLabS3Access`ロールを選択します。
1. すべての設定を確認し、問題がなければ**Create launch template**を選択します。

### オートスケールグループを作成する {#create-an-auto-scaling-group}

EC2ダッシュボードで、次の手順に従います。

1. 左側のメニューから**Auto scaling groups(自動スケーリンググループ)**を選択し、**Create Auto Scaling group(自動スケーリンググループを作成)**を選択します。
1. **Group name(グループ名)**を入力します（`gitlab-auto-scaling-group`を使用します）。
1. **Launch template(起動テンプレート)**で、先ほど作成した起動テンプレートを選択します。**Next(次へ)**を選択します
1. ネットワーク設定セクションで:
   1. **VPC**で、ドロップダウンリストから`gitlab-vpc`を選択します。
   1. **Availability Zones and subnets(可用性ゾーンとサブネット)**で、[以前に作成したプライベートサブネット](#subnets)(`gitlab-private-10.0.1.0`と`gitlab-private-10.0.3.0`)を選択します。
   1. **Next(次へ)**を選択します。
1. ロードバランシング設定セクションで:
   1. **Attach to an existing load balancer(既存のロードバランサーにアタッチ)**を選択します。
   1. **Existing load balancer target groups(既存のロードバランサーターゲットグループ)**ドロップダウンリストで、先ほど作成したターゲットグループを選択します。
   1. **Health Check Type(ヘルスチェックタイプ)**で、**Turn on Elastic Load Balancing health checks(Elasticロードバランシングヘルスチェックをオンにする**オプションをオンにします。**Health Check Grace Period(ヘルスチェック猶予期間)**は、デフォルトの`300`秒のままにします。
   1. **Next(次へ)**を選択します。
1. **Group size(グループサイズ)**で、**Desired capacity(希望する容量)**を`2`に設定します。
1. スケーリング設定セクションで:
   1. **No scaling policies(スケーリングポリシーなし)**を選択します。ポリシーは後で設定されます。
   1. **Min desired capacity(最小希望容量):** `2`に設定します。
   1. **Max desired capacity(最大希望容量):** `4`に設定します。
   1. **Next(次へ)**を選択します。
1. 最後に、必要に応じて通知とタグを構成し、変更を確認して、自動スケーリンググループを作成します。
1. 自動スケーリンググループが作成されたら、[CloudWatch](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html)でスケールアップおよびスケールダウンポリシーを作成し、それらを割り当てる必要があります。
   1. 先ほど作成した**By Auto Scaling Group(自動スケーリンググループ)**の**EC2**インスタンスからのメトリクスに対して、`CPUUtilization`のアラームを作成します。
   1. 次の条件を使用して[スケールアップポリシー](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html#step-scaling-create-scale-out-policy)を作成します。
      1. `CPUUtilization`が60%以上の場合は、`1`キャパシティユニットを**Add(追加)**します。
      1. **Scaling policy name(スケーリングポリシー名)**を`Scale Up Policy`に設定します。

   ![スケールアップポリシー](img/scale_up_policy_v17_0.png)

   1. 次の条件を使用して[スケールダウンポリシー](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html#step-scaling-create-scale-in-policy)を作成します。
      1. `CPUUtilization`が45%以下の場合は、`1`キャパシティユニットを**Remove(削除)**します。
      1. **Scaling policy name(スケーリングポリシー名)**を`Scale Down Policy`に設定します。

   ![スケールダウンポリシー](img/scale_down_policy_v17_0.png)

   1. 先ほど作成したオートスケールグループに、新しい動的スケーリングポリシーを割り当てます。

オートスケールグループが作成されると、EC2ダッシュボード上で新しいインスタンスが起動していることを確認できます。また、ロードバランサーに新しいインスタンスが追加されていることも確認できます。インスタンスがヘルスチェックに合格すると、ロードバランサーからトラフィックを受信する準備が整います。

インスタンスは自動スケーリンググループによって作成されるため、インスタンスに戻り、[上記で手動で作成したインスタンス](#install-gitlab)を終了します。このインスタンスは、カスタムAMIの作成にのみ必要です。

## Prometheusによるヘルスチェックとモニタリング {#health-check-and-monitoring-with-prometheus}

さまざまなサービスで有効化できるAmazon CloudWatchとは別に、GitLabはPrometheusに基づく独自の統合モニタリングソリューションを提供しています。設定方法の詳細については、[GitLab Prometheus](../../administration/monitoring/prometheus/_index.md)を参照してください。

GitLabにはさまざまな[ヘルスチェックエンドポイント](../../administration/monitoring/health_check.md)が用意されており、pingしてレポートを取得できます。

## GitLab Runner {#gitlab-runner}

[GitLab CI/CD](../../ci/_index.md)を活用するには、少なくとも1つの[Runner](https://docs.gitlab.com/runner/)を設定する必要があります。

[AWSでGitLab Runnerの自動スケール](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/)を設定する方法について詳しくはこちらをご覧ください。

## バックアップと復元 {#backup-and-restore}

GitLabには、Gitデータ、データベース、添付ファイル、LFSオブジェクトなどを[バックアップ](../../administration/backup_restore/_index.md)および復元するためのツールが用意されています。

知っておくべき重要な点:

- バックアップ/復元ツールは、シークレットなどの一部の構成ファイルを**保存しません**。これらは[自分で設定](../../administration/backup_restore/backup_gitlab.md#storing-configuration-files)する必要があります。
- デフォルトでは、バックアップファイルはローカルに保存されますが、[S3を使用してGitLabをバックアップ](../../administration/backup_restore/backup_gitlab.md#using-amazon-s3)できます。
- [バックアップから特定のディレクトリを除外](../../administration/backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup)できます。

### GitLabをバックアップする {#backing-up-gitlab}

GitLabをバックアップするには、次の手順に従います。

1. インスタンスにSSHで接続します。
1. バックアップを作成します。

   ```shell
   sudo gitlab-backup create
   ```

### バックアップからGitLabを復元する {#restoring-gitlab-from-a-backup}

GitLabを復元するには、まず[復元ドキュメント](../../administration/backup_restore/_index.md#restore-gitlab)、特に復元の前提条件を確認してください。次に、[Linuxパッケージのインストール](../../administration/backup_restore/restore_gitlab.md#restore-for-linux-package-installations)セクションの手順に従ってください。

## GitLabを更新する {#updating-gitlab}

GitLabでは、毎月[リリース日](https://about.gitlab.com/releases/)に新しいバージョンをリリースしています。新しいバージョンがリリースされたら、GitLabインスタンスを更新できます。

1. インスタンスにSSHで接続します。
1. バックアップを作成します。

   ```shell
   sudo gitlab-backup create
   ```

1. リポジトリを更新し、GitLabをインストールします。

   ```shell
   sudo apt update
   sudo apt install gitlab-ee
   ```

数分後には、新しいバージョンが起動して稼働を開始します。

## AWS上でGitLabが提供する公式AMI IDを見つける {#find-official-gitlab-created-ami-ids-on-aws}

[GitLabがリリースしているAMI](../../solutions/cloud/aws/gitlab_single_box_on_aws.md#official-gitlab-releases-as-amis)の使用方法については、リンク先をご覧ください。

## まとめ {#conclusion}

このガイドでは、主にスケーリングといくつかの冗長化オプションについて説明しましたが、必要な作業内容は環境によって異なります。

すべてのソリューションは、コストと複雑さ、そしてアップタイムの間でバランスを取る必要があります。必要とするアップタイムが長くなるほど、ソリューションは複雑になります。そしてソリューションが複雑になるほど、セットアップやメンテナンスに必要な作業も増えます。

以下のその他のリソースもぜひご覧ください。追加の資料をご希望の場合は、[イシューを開いて](https://gitlab.com/gitlab-org/gitlab/-/issues/new)リクエストしてください。

- [GitLabのスケーリング](../../administration/reference_architectures/_index.md): GitLabは、いくつかのタイプのクラスタリングをサポートしています。
- [Geoレプリケーション](../../administration/geo/_index.md): Geoは、広範な分散型開発チーム向けのソリューションです。
- [Linuxパッケージ](https://docs.gitlab.com/omnibus/) \- GitLabインスタンスの管理について知っておくべきこと。
- [ライセンスを追加](../../administration/license.md): ライセンスを使用して、すべてのGitLab Enterpriseエディションの機能を有効にします。
- [価格](https://about.gitlab.com/pricing/): さまざまなプランの料金。

## トラブルシューティング {#troubleshooting}

### インスタンスがヘルスチェックに失敗する {#instances-are-failing-health-checks}

インスタンスがロードバランサーのヘルスチェックに失敗する場合は、以前に設定したヘルスチェックエンドポイントからステータス`200`が返されていることを確認してください。ステータス`302`などのリダイレクトを含む、その他のステータスが返されるとヘルスチェックは失敗します。

ヘルスチェックに合格するために、`root`ユーザーにパスワードを設定し、サインインエンドポイントでの自動リダイレクトを防ぐ必要がある場合があります。

### 「要求された変更は拒否されました（422）」  {#the-change-you-requested-was-rejected-422}

Webインターフェースでパスワードを設定しようとした際にこのページが表示される場合は、`gitlab.rb`内の`external_url`がリクエスト元のドメインと一致していることを確認してください。ファイルに変更を加えた場合は、`sudo gitlab-ctl reconfigure`を実行します。

### 一部のジョブログがオブジェクトストレージにアップロードされない {#some-job-logs-are-not-uploaded-to-object-storage}

GitLabデプロイが複数のノードにスケールアップされると、一部のジョブログが[オブジェクトストレージ](../../administration/object_storage.md)に正常にアップロードされない場合があります。CIでオブジェクトストレージを使用するには、[増分ログの生成が必要です](../../administration/object_storage.md#alternatives-to-file-system-storage)。

まだ有効になっていない場合は、[増分ログの生成](../../administration/cicd/job_logs.md#enable-or-disable-incremental-logging)を有効にします。
