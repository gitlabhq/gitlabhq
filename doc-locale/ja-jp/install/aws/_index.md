---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabが提供するコミュニティAMIを使用して、AWSにGitLabをインストールします。
title: Amazon Web Services（AWS）にGitLab POCをインストールする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このページでは、公式Linuxパッケージを使用してAWS上にGitLabを構築する一般的な設定の流れを説明します。ニーズに合わせてカスタマイズしてください。

> [!note]
> 1,000ユーザー以下の組織の場合、推奨されるAWSインストール方法は、EC2シングルボックスの[Linuxパッケージインストールを開始し、データのバックアップにスナップショット戦略を実装することです。](https://about.gitlab.com/install/)詳細については、[20 RPSまたは1,000ユーザーのリファレンスアーキテクチャ](../../administration/reference_architectures/1k_users.md)を参照してください。

## 本番環境グレードのGitLabの使用を開始する {#getting-started-for-production-grade-gitlab}

> [!note]
> このドキュメントは、概念実証インスタンスのインストールガイドです。これはリファレンスアーキテクチャではなく、高可用性設定にもなりません。代わりに、[GitLab Environment Toolkit（GET）](https://gitlab.com/gitlab-org/gitlab-environment-toolkit)を使用することを強くおすすめします。

このガイドに正確に従うと、概念実証インスタンスを構築できます。これは、**非HA**構成の[40 RPSまたは2,000ユーザーのリファレンスアーキテクチャ](../../administration/reference_architectures/2k_users.md)における**2つのアベイラビリティーゾーン実装**を**縮小**した形に相当します。2,000ユーザーのリファレンスアーキテクチャは、コストと複雑さを抑えながらある程度のスケーリングを実現することを主な目的としているため、HAではありません。[60 RPSまたは3,000ユーザーのリファレンスアーキテクチャ](../../administration/reference_architectures/3k_users.md)が、GitLab HAとしての最小構成です。この構成では、HAを実現するための追加のサービスロールを含みます。特筆すべき点は、GitリポジトリストレージをGitaly Cluster (Praefect)でHA化し、三重冗長を規定していることです。

GitLabは、主に2種類のリファレンスアーキテクチャを維持およびテストしています。**Linuxパッケージアーキテクチャ**はインスタンスのコンピューティングリソース上に実装され、**クラウドネイティブハイブリッドアーキテクチャ**はKubernetesクラスターを最大限に活用します。クラウドネイティブハイブリッドのリファレンスアーキテクチャ仕様は、リファレンスアーキテクチャのサイズ別ページの追補セクションとして掲載されています。これらのページは、Linuxパッケージアーキテクチャの説明から始まります。たとえば、60 RPSまたは3,000ユーザーのクラウドネイティブリファレンスアーキテクチャは、60 RPSまたは3,000ユーザーのリファレンスアーキテクチャページの、[Helmチャートを使用したクラウドネイティブハイブリッドのリファレンスアーキテクチャ（代替）](../../administration/reference_architectures/3k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative)というサブセクションに掲載されています。

### 本番環境グレードのLinuxパッケージインストールの使用を開始する {#getting-started-for-production-grade-linux-package-installations}

Infrastructure as Codeツールである[GitLab Environment Tool（GET）](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/tree/main)は、AWS上でLinuxパッケージを使用して構築する際の出発点として最適です。とりわけ、HA構成を目標とする場合に有用です。GETはすべてを自動化するわけではありませんが、Gitaly Cluster (Praefect)のような複雑なセットアップを自動構成します。GETはオープンソースであるため、誰でも機能を追加したり、改善にコントリビュートしたりできます。

### 本番環境グレードのクラウドネイティブハイブリッドGitLabの使用を開始する {#getting-started-for-production-grade-cloud-native-hybrid-gitlab}

[GitLab Environment Toolkit（GET）](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/README.md)は、明確な設計思想に基づいたTerraformおよびAnsibleのスクリプト群です。これらのスクリプトは、選択したクラウドプロバイダー上でLinuxパッケージまたはクラウドネイティブハイブリッド環境をデプロイする際に役立ち、GitLabデベロッパーが[GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md)（例）で使用します。

GitLab Environment Toolkitを使用して、AWS上にクラウドネイティブハイブリッド環境をデプロイできます。ただし必須ではなく、すべての有効な組み合わせをサポートしているとは限りません。なお、スクリプトは現状のまま提供されており、必要に応じて調整できます。

## はじめに {#introduction}

このセットアップでは主にLinuxパッケージを使用しますが、ネイティブAWSサービスも活用します。LinuxパッケージにバンドルされているPostgreSQLやRedisの代わりに、Amazon RDSとElastiCacheを使用します。

このガイドでは、マルチノードのセットアップについて説明します。まず、Virtual Private Cloudとサブネットを設定し、その後、データベースサーバー用のRDS、Redisクラスター構成のElastiCacheなどのサービスを統合し、最終的にカスタムスケーリングポリシーを適用したオートスケールグループでそれらを管理します。

## 要件 {#requirements}

[AWS](https://docs.aws.amazon.com/)および[Amazon EC2](https://docs.aws.amazon.com/ec2/)の基本的な知識に加えて、次のものが必要です。

- [AWSアカウント](https://console.aws.amazon.com/console/home)
- [SSHキーを作成またはアップロード](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)して、SSH経由でインスタンスに接続していること。
- GitLabインスタンスのドメイン名。
- ドメインを保護するSSL/TLS証明書。まだお持ちでない場合は、[AWS Certificate Manager](https://aws.amazon.com/certificate-manager/)（ACM）を使用して無料のパブリックSSL/TLS証明書をプロビジョニングし、このガイドで作成する[Elastic Load Balancer](#load-balancer)で使用できます。

> [!note]
> ACMを介してプロビジョニングされた証明書を検証するには数時間かかる場合があります。後の作業を遅らせないために、できるだけ早く証明書をリクエストしてください。

## アーキテクチャ {#architecture}

次の図は、推奨アーキテクチャの概要を示しています。

![2つのアベイラビリティーゾーンを持つ、非HA構成の縮小版AWSアーキテクチャ。](img/aws_ha_architecture_diagram_v17_0.png)

## AWSのコスト {#aws-costs}

GitLabは次のAWSサービスを使用しています。各サービスの価格情報はリンク先を参照してください:

- **EC2**: GitLabは共有ハードウェアにデプロイされ、[オンデマンド料金](https://aws.amazon.com/ec2/pricing/on-demand/)が適用されます。専有インスタンスまたはリザーブドインスタンスでGitLabを実行する場合、コストの詳細については[EC2の料金ページ](https://aws.amazon.com/ec2/pricing/)を参照してください。
- **S3**: GitLabはS3（[料金ページ](https://aws.amazon.com/s3/pricing/)）を使用して、バックアップ、アーティファクト、LFSオブジェクトを保存します。
- **NLB**: GitLabインスタンスにリクエストをルーティングするためのネットワークロードバランサー（[料金ページ](https://aws.amazon.com/elasticloadbalancing/pricing/)）。
- **RDS**: PostgreSQLを使用するAmazon Relational Database Service（[料金ページ](https://aws.amazon.com/rds/postgresql/pricing/)）。
- **ElastiCache**: Redis構成を提供するために使用するインメモリキャッシュ環境（[料金ページ](https://aws.amazon.com/elasticache/pricing/)）。

## IAM EC2インスタンスのロールとプロファイルを作成する {#create-an-iam-ec2-instance-role-and-profile}

[Amazon S3オブジェクトストレージ](#amazon-s3-object-storage)を使用しているため、EC2インスタンスにはS3バケットに対する読み取り、書き込み、一覧表示の権限が必要です。GitLabの設定にAWSキーを埋め込むのを避けるため、[IAMロール](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)を使用して、GitLabインスタンスにこのアクセス権を付与します。IAMロールにアタッチするためのIAMポリシーを作成する必要があります。

### IAMポリシーを作成する {#create-an-iam-policy}

1. IAMダッシュボードに移動し、左側のメニューで**Policies**を選択します。
1. **Create policy**を選択し、`JSON`タブを選択して、ポリシーを追加します。[セキュリティのベストプラクティスに従い、_最小権限_の原則を適用する](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege)ことで、必要なアクションを実行するために必要な権限のみをロールに付与します。
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

1. **Next**を選択して、ポリシーを確認します。ポリシーに名前を付け（この例では`gl-s3-policy`）、**Create policy**を選択します。

### IAMロールを作成する {#create-an-iam-role}

1. 引き続きIAMダッシュボードで、左側のメニューの**Roles**を選択し、**Create role**を選択します。
1. **Trusted entity type**で、`AWS service`を選択します。**Use case**で、ドロップダウンリストとラジオボタンの両方で`EC2`を選択し、**Next**を選択します。
1. ポリシーフィルターで、先ほど作成した`gl-s3-policy`を検索して選択し、**Next**を選択します。
1. ロールに名前を付けます（この例では`GitLabS3Access`）。必要に応じてタグを追加します。**Create role**を選択します。

このロールは、後で[起動テンプレートを作成](#create-a-launch-template)するときに使用します。

> [!note]
> GitLabは、AWSインスタンスメタデータサービスバージョン2 (IMDSv2)をサポートしています。GitLabは、利用可能な場合は自動的にIMDSv2を使用し、必要に応じてIMDSv1にフォールバックします。セキュリティを強化するために、EC2インスタンスでIMDSv2を安全に要求できます。

## ネットワークを設定する {#configuring-the-network}

まず、GitLabクラウドインフラストラクチャ用のVPCを作成します。次に、少なくとも2つの[アベイラビリティーゾーン（AZ）](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html)にパブリックインスタンスとプライベートインスタンスを配置するためのサブネットを作成します。パブリックサブネットには、ルートテーブルの設定と関連付けられたインターネットゲートウェイが必要です。

### Virtual Private Cloud（VPC）を作成する {#creating-the-virtual-private-cloud-vpc}

ここで、ユーザーが制御する仮想ネットワーキング環境であるVPCを作成します:

1. [Amazon Web Services](https://console.aws.amazon.com/vpc/home)にサインインします。
1. 左側のメニューから**Your VPCs**を選択し、**Create VPC**を選択します。「Name tag」に`gitlab-vpc`と入力し、「IPv4 CIDR block」に`10.0.0.0/16`と入力します。専用ハードウェアが不要な場合、「Tenancy」はデフォルトのままでかまいません。準備ができたら、**Create VPC**を選択します。

   ![GitLabクラウドインフラストラクチャ用のVPCを作成します。](img/create_vpc_v17_0.png)

1. VPCを選択し、**Actions**、**Edit VPC Settings**の順に選択し、**Enable DNS resolution**をオンにします。完了したら、**Save**を選択します。

### サブネット {#subnets}

ここでは、さまざまなアベイラビリティーゾーンにサブネットをいくつか作成します。各サブネットが、先ほど作成したVPCに関連付けられ、CIDRブロックが重複していないことを確認してください。これにより、冗長性を確保するためのマルチAZを有効にすることもできます。

ロードバランサーとRDSインスタンスに対応するように、プライベートサブネットとパブリックサブネットも作成します。

1. 左側のメニューから**Subnets**を選択します。
1. **Create subnet**を選択します。IPに基づいたわかりやすい名前タグ（例: `gitlab-public-10.0.0.0`）を付け、先ほど作成したVPCを選択します。アベイラビリティーゾーンを選択し（この例では`us-west-2a`）、IPv4 CIDR blockには/24サブネットの`10.0.0.0/24`を指定します:

   ![サブネットを作成します。](img/create_subnet_v17_0.png)

1. 同様の手順に従って、次のすべてのサブネットを作成します。

   | 名前タグ                  | タイプ    | アベイラビリティーゾーン | CIDRブロック    |
   | ------------------------- | ------- | ----------------- | ------------- |
   | `gitlab-public-10.0.0.0`  | public  | `us-west-2a`      | `10.0.0.0/24` |
   | `gitlab-private-10.0.1.0` | private | `us-west-2a`      | `10.0.1.0/24` |
   | `gitlab-public-10.0.2.0`  | public  | `us-west-2b`      | `10.0.2.0/24` |
   | `gitlab-private-10.0.3.0` | private | `us-west-2b`      | `10.0.3.0/24` |

1. すべてのサブネットを作成したら、2つのパブリックサブネットに対して**Auto-assign IPv4**を有効にします。
   1. 各パブリックサブネットを順番に選択し、**Actions**、**Edit subnet settings**の順に選択します。**Enable auto-assign public IPv4 address**オプションをオンにして、保存します。

### インターネットゲートウェイ {#internet-gateway}

次に、同じダッシュボードで、Internet Gatewaysに移動して、新しいゲートウェイを作成します。

1. 左側のメニューから**Internet Gateways**を選択します。
1. **Create internet gateway**を選択し、`gitlab-gateway`という名前を付けて、**Create**を選択します。
1. 作成したインターネットゲートウェイをテーブルから選択し、**Actions**ドロップダウンリストから「Attach to VPC」を選択します。

   ![インターネットゲートウェイを作成します。](img/create_gateway_v17_0.png)

1. リストから`gitlab-vpc`を選択し、**Attach**をクリックします。

### NATゲートウェイを作成する {#create-nat-gateways}

プライベートサブネットにデプロイされたインスタンスは、アップデートのためにインターネットに接続する必要がありますが、パブリックインターネットからアクセスされないように設定します。そのために、各パブリックサブネットにデプロイされた[NATゲートウェイ](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)を使用します。

1. VPCダッシュボードに移動し、左側のメニューバーで**NAT Gateways**を選択します。
1. **Create NAT Gateway**を選択し、次の項目を設定します。
   1. **Availability mode**: `Zonal`を選択します。
   1. **Subnet**: ドロップダウンリストから`gitlab-public-10.0.0.0`を選択します。
   1. **Elastic IP Allocation ID**: 既存のElastic IPを入力するか、**Allocate Elastic IP address**を選択し、NATゲートウェイに新しいIPを割り当てます。
   1. 必要に応じてタグを追加します。
   1. **Create NAT Gateway**を選択します。

2つ目のNATゲートウェイを作成します。今回は、2つ目のパブリックサブネットである`gitlab-public-10.0.2.0`に配置します。

### ルートテーブル {#route-tables}

#### パブリックルートテーブル {#public-route-table}

前の手順で作成したインターネットゲートウェイ経由でパブリックサブネットがインターネットにアクセスできるように、ルートテーブルを作成する必要があります。

VPCダッシュボードで、次の手順に従います。

1. 左側のメニューから**Route Tables**を選択します。
1. **Create Route Table**を選択します。
1. 「Name tag」に`gitlab-public`と入力し、「VPC」で`gitlab-vpc`を選択します。
1. **Create**を選択します。

次に、インターネットゲートウェイを新しいターゲットとして追加し、すべての宛先からトラフィックを受信するように設定する必要があります。

1. 左側のメニューから**Route Tables**を選択し、`gitlab-public`ルートを選択して、下部のオプションを表示します。
1. **Routes**タブを選択し、**Edit routes** > **Add route**を選択して、宛先に`0.0.0.0/0`を設定します。ターゲット列で、**Internet Gateway**を選択し、先ほど作成した`gitlab-gateway`を選択します。完了したら**Save changes**を選択します。

次に、**パブリック**サブネットをルートテーブルに関連付ける必要があります。

1. **Subnet Associations**タブを選択し、**Edit subnet associations**を選択します。
1. パブリックサブネットのチェックボックスのみをオンにし、**Save associations**を選択します。

#### プライベートルートテーブル {#private-route-tables}

各プライベートサブネット内のインスタンスが、同じアベイラビリティーゾーン内の対応するパブリックサブネットにあるNATゲートウェイ経由でインターネットにアクセスできるように、2つのプライベートルートテーブルを作成する必要があります。

1. 先ほどと同様の手順に従って、プライベートルートテーブルを2つ作成し、`gitlab-private-a`および`gitlab-private-b`という名前を付けます。
1. 次に、各プライベートルートテーブルに新しいルートを追加します。宛先を`0.0.0.0/0`とし、ターゲットには先ほど作成したNATゲートウェイのいずれかを指定します。
   1. `gitlab-private-a`ルートテーブルの新しいルートには、`gitlab-public-10.0.0.0`に作成したNATゲートウェイをターゲットとして追加します。
   1. 同様に、`gitlab-private-b`の新しいルートには、`gitlab-public-10.0.2.0`にあるNATゲートウェイをターゲットとして追加します。
1. 最後に、各プライベートサブネットをプライベートルートテーブルに関連付けます。
   1. `gitlab-private-10.0.1.0`を`gitlab-private-a`に関連付けます。
   1. `gitlab-private-10.0.3.0`を`gitlab-private-b`に関連付けます。

## ロードバランサー {#load-balancer}

ロードバランサーを作成し、GitLabアプリケーションサーバー全体に受信トラフィックを均等に分散します。後ほど作成する[スケーリングポリシー](#create-an-auto-scaling-group)に基づいて、必要に応じてインスタンスがロードバランサーに追加または削除されます。さらに、ロードバランサーはインスタンスに対してヘルスチェックを実行します。

AWSはこのアーキテクチャに2つのアプローチを提供します:

- **Network Load Balancer (NLB) only**: 小規模なデプロイに適した、よりシンプルなセットアップです。NLBは、すべてのトラフィック (SSH (ポート22)、HTTP (ポート80)、HTTPS (ポート443))をRailsノードに直接処理し、NLBでSSL/TLS終端を行います。
- **Hybrid NLB->ALB approach**: 懸念事項を分離する、よりスケーラブルなセットアップです。NLBはTCPトラフィック (SSH (ポート22))を処理し、Application Load Balancer (ALB)はSSL/TLS終端を伴うHTTP/HTTPSトラフィックを処理します。このアプローチにより、AWS WAFインテグレーションと、より優れたトラフィック管理が可能になります。

あなたのデプロイに最適なアプローチを選択してください:

- NLBのみ:

  ```mermaid
  graph TB
      subgraph Diagram1["NLB Only"]
        U1["Users"]
        NLB1["Network Load Balancer<br/>(Port 22, 80, 443)"]
        R1A["Rails Node 1<br/>(Port 22, 80)"]
        R1B["Rails Node 2<br/>(Port 22, 80)"]

        U1 -->|SSH| NLB1
        U1 -->|HTTP| NLB1
        U1 -->|HTTPS| NLB1
        NLB1 -->|Port 22| R1A
        NLB1 -->|Port 22| R1B
        NLB1 -->|"Port 80, 443"| R1A
        NLB1 -->|"Port 80, 443"| R1B
    end
    ```

- ハイブリッドNLB/ALB:

  ```mermaid
  graph TB
      subgraph Diagram2["Hybrid NLB/ALB"]
          U2["Users"]
          NLB2["Network Load Balancer<br/>(Port 22, 443)"]
          ALB["Application Load Balancer<br/>(Port 443)"]
          R2A["Rails Node 1<br/>(Port 22, 80)"]
          R2B["Rails Node 2<br/>(Port 22, 80)"]

          U2 -->|SSH| NLB2
          U2 -->|HTTPS| NLB2
          NLB2 -->|Port 22| R2A
          NLB2 -->|Port 22| R2B
          NLB2 -->|Port 443| ALB
          ALB -->|Port 80| R2A
          ALB -->|Port 80| R2B
      end
  ```

{{< tabs >}}

{{< tab title="Network Load Balancer (NLB) Only" >}}

このセクションでは、単一のNetwork Load Balancerがすべてのトラフィックタイプを処理し、SSH、HTTP、およびHTTPSをRailsノードに直接ルーティングする、よりシンプルなNLBのみのアプローチについて説明します。

このアーキテクチャにはセキュリティグループが必要です:

1. **NLB Security Group** (`gitlab-nlb-sec-group`):
   - 受信: 任意の場所からのTCPポート22 (SSHの場合は信頼されたIP範囲に制限することも可能)
   - 受信: 任意の場所からのTCPポート80
   - 受信: 任意の場所からのTCPポート443
   - 送信: すべてのトラフィック

このセキュリティグループを作成するには:

1. EC2ダッシュボードで、左側のメニューバーから**Security Groups**を選択します。
1. **Create security group**を選択します。
1. 説明的な名前と説明を付け、**VPC**ドロップダウンリストから`gitlab-vpc`を選択します。
1. 上記で指定した受信ルールを追加する。
1. 設定が完了したら、**Create security group**を選択します。

ターゲットグループを作成します:

1. EC2ダッシュボードで、左側のメニューバーから**Target Groups**を選択します。
1. **SSH Target Group**に対して**Create target group**を選択します:

   | 設定 | 値 |
   |---------|-------|
   | ターゲットタイプ | インスタンス |
   | ターゲットグループ名 | `gitlab-nlb-ssh-target` |
   | プロトコル | TCP |
   | ポート | 22 |
   | VPC | `gitlab-vpc` |
   | ヘルスチェックプロトコル | TCP |

   **Next**を2回選択し、次に**Create target group**を選択します。ターゲットは以降に登録します。

1. **HTTP Target Group**に対して再度**Create target group**を選択します:

   | 設定 | 値 |
   |---------|-------|
   | ターゲットタイプ | インスタンス |
   | ターゲットグループ名 | `gitlab-nlb-http-target` |
   | プロトコル | TCP |
   | ポート | 80 |
   | VPC | `gitlab-vpc` |
   | ヘルスチェックプロトコル | HTTP |
   | ヘルスチェックパス | `/-/readiness` |

   > [!note]
   > [ヘルスチェックエンドポイント](../../administration/monitoring/health_check.md)については、[VPC IPアドレス範囲 (CIDR)](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-security-groups.html)を[IP許可リスト](../../administration/monitoring/ip_allowlist.md)に追加する必要があります。

   **Next**を選択し、**Register Later**を選択し、次に**Next**を2回選択してから**Create target group**を選択します。

ネットワークロードバランサーを作成します:

1. EC2ダッシュボードで、左側のナビゲーションバーにある**Load Balancers**を探し、**Create Load Balancer**を選択します。
1. **Network Load Balancer**を選択し、**作成**を選択します。
1. ロードバランサーを次の設定で設定します:

   | 設定 | 値 |
   |---------|-------|
   | Load Balancer name | `gitlab-nlb` |
   | Scheme | インターネット向け |
   | IPアドレスタイプ | IPv4 |
   | VPC | `gitlab-vpc` |
   | マッピング | 両方のパブリックサブネットを選択します |
   | セキュリティグループ | `gitlab-nlb-sec-group` |

1. **Listeners and routing**セクションで、次を設定します:

   | プロトコル | ポート | ターゲットグループ |
   |----------|------|--------------|
   | TCP | 22 | `gitlab-nlb-ssh-target` |
   | TCP | 80 | `gitlab-nlb-http-target` |
   | TLS | 443 | `gitlab-nlb-http-target` |

   ポート443のTLSリスナーの場合、**Security Policy**設定で:
   - **Policy name**: ドロップダウンリストから定義済みのセキュリティポリシーを選択します。AWSドキュメントの[Predefined SSL Security Policies for Network Load Balancers](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/create-tls-listener.html#describe-ssl-policies)を参照してください。[サポートされているSSL暗号およびプロトコル](https://gitlab.com/gitlab-org/gitlab/-/blob/9ee7ad433269b37251e0dd5b5e00a0f00d8126b4/lib/support/nginx/gitlab-ssl#L97-99)の一覧は、GitLabコードベースで確認できます。
   - **Default SSL/TLS server certificate**: ACMからSSL/TLS証明書を選択するか、証明書をIAMにアップロードします。

1. **Create load balancer**を選択します。

> [!note]
> `gitlab-nlb-ssh-target`と`gitlab-nlb-http-target`ターゲットグループのターゲットは、このガイドの以降で作成される[オートスケールグループでインスタンスが起動されると自動的に登録されます。](#create-an-auto-scaling-group)

{{< /tab >}}

{{< tab title="Hybrid NLB->ALB Approach" >}}

このセクションでは、Network Load BalancerがSSHトラフィックを処理し、Application Load BalancerがHTTP/HTTPSトラフィックを処理するハイブリッドアプローチについて説明します。NLBはTCPポート22 (SSH)をRailsノードに直接ルーティングし、TCPポート443 (HTTPS)をALBにルーティングします。ALBはSSL/TLSを終端し、HTTPトラフィックをポート80のRailsノードにルーティングします。このアプローチにより、AWS WAFインテグレーションと、より優れたトラフィック管理が可能になります。

このアーキテクチャには3つのセキュリティグループが必要です:

1. **NLB Security Group** (`gitlab-nlb-sec-group`):
   - 受信: 任意の場所からのTCPポート22 (SSHの場合は信頼されたIP範囲に制限することも可能)
   - 受信: 任意の場所からのTCPポート443 (HTTPSの場合は信頼されたIP範囲に制限することも可能)
   - 送信: TCPポート22を`gitlab-rails-sec-group`へ
   - 送信: TCPポート443を`gitlab-alb-sec-group`へ

1. **ALB Security Group** (`gitlab-alb-sec-group`):
   - 受信: `gitlab-nlb-sec-group`からのTCPポート443
   - 受信: `gitlab-rails-sec-group`からのTCPポート80
   - 送信: TCPポート80を`gitlab-rails-sec-group`へ

1. **Rails Security Group** (`gitlab-rails-sec-group`):
   - 受信: `gitlab-nlb-sec-group`からのTCPポート22
   - 受信: `gitlab-alb-sec-group`からのTCPポート80

これらのセキュリティグループを作成するには:

1. EC2ダッシュボードで、左側のメニューバーから**Security Groups**を選択します。
1. **SSH Target Group**に対して**Create security group**を選択します:
1. それぞれに説明的な名前と説明を付け、**VPC**ドロップダウンリストから`gitlab-vpc`を選択します。
1. 上記で指定した受信ルールを追加する。ソースを選択する際は、**Security group**を選択し、ドロップダウンから適切なセキュリティグループを選択します。
1. 設定が完了したら、**Create security group**を選択します。

ターゲットグループを作成します:

1. EC2ダッシュボードで、左側のメニューバーから**Target Groups**を選択します。
1. 次の設定で**NLB SSH Target Group**を作成します:

   | 設定 | 値 |
   |---------|-------|
   | ターゲットタイプ | インスタンス |
   | ターゲットグループ名 | `gitlab-nlb-ssh-target` |
   | プロトコル | TCP |
   | ポート | 22 |
   | VPC | `gitlab-vpc` |
   | ヘルスチェックプロトコル | TCP |

   **Next**を2回選択し、次に**Create target group**を選択します。ターゲットは以降に登録します。

1. **NLB to ALB Target Group**に対して再度**Create target group**を選択します:

   | 設定 | 値 |
   |---------|-------|
   | ターゲットタイプ | Application Load Balancer |
   | ターゲットグループ名 | `gitlab-nlb-alb-target` |
   | プロトコル | TCP |
   | ポート | 443 |
   | VPC | `gitlab-vpc` |
   | ヘルスチェックプロトコル | HTTPS |
   | ヘルスチェックパス | `/-/readiness` |

   **Next**を選択し、Application Load Balancerに対して**Register Later**を選択し、次に**Next**を選択してから**Create target group**を選択します。

1. **ALB HTTP Target Group**に対して再度**Create target group**を選択します:

   | 設定 | 値 |
   |---------|-------|
   | ターゲットタイプ | インスタンス |
   | ターゲットグループ名 | `gitlab-alb-http-target` |
   | プロトコル | HTTP |
   | ポート | 80 |
   | VPC | `gitlab-vpc` |
   | プロトコルバージョン | HTTP1.1 |
   | ヘルスチェックプロトコル | HTTP |
   | ヘルスチェックパス | `/-/readiness` |

   > [!note]
   > [ヘルスチェックエンドポイント](../../administration/monitoring/health_check.md)については、[VPC IPアドレス範囲 (CIDR)](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-security-groups.html)を[IP許可リスト](../../administration/monitoring/ip_allowlist.md)に追加する必要があります。

   **Next**を選択し、**Register Later**を選択し、次に**Next**を2回選択してから**Create target group**を選択します。

アプリケーションロードバランサーを作成します:

1. EC2ダッシュボードで、左側のナビゲーションバーにある**Load Balancers**を探し、**Create Load Balancer**を選択します。
1. **Application Load Balancer**を選択し、**作成**を選択します。
1. ロードバランサーを次の設定で設定します:

   | 設定 | 値 |
   |---------|-------|
   | Load Balancer name | `gitlab-alb` |
   | Scheme | インターネット向け |
   | IPアドレスタイプ | IPv4 |
   | VPC | `gitlab-vpc` |
   | マッピング | 両方のパブリックサブネット`gitlab-public-10.0.0.0`と`gitlab-public-10.0.2.0`を選択します|
   | セキュリティグループ | `gitlab-alb-sec-group` |

1. **Listeners and routing**セクションで、次を設定します:

   | プロトコル | ポート | アクション | ターゲットグループ |
   |----------|------|--------|--------------|
   | HTTPS | 443 | 転送先 | `gitlab-alb-http-target` |

   HTTPSリスナーの場合、ACM証明書を選択し、適切なセキュリティポリシーを選択します ([Predefined SSL Security Policies for Application Load Balancers](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html)を参照)。

1. **Create load balancer**を選択します。

ネットワークロードバランサーを作成します:

1. EC2ダッシュボードで、左側のナビゲーションバーにある**Load Balancers**を探し、**Create Load Balancer**を選択します。
1. **Network Load Balancer**を選択し、**作成**を選択します。
1. ロードバランサーを次の設定で設定します:

   | 設定 | 値 |
   |---------|-------|
   | Load Balancer name | `gitlab-nlb` |
   | Scheme | インターネット向け |
   | IPアドレスタイプ | IPv4 |
   | VPC | `gitlab-vpc` |
   | マッピング | 両方のパブリックサブネット`gitlab-public-10.0.0.0`と`gitlab-public-10.0.2.0`を選択します|
   | セキュリティグループ | `gitlab-nlb-sec-group` |

1. **Listeners and routing**セクションで、次を設定します:

   | プロトコル | ポート | ターゲットグループ |
   |----------|------|--------------|
   | TCP | 22 | `gitlab-nlb-ssh-target` |
   | TCP | 443 | `gitlab-nlb-alb-target` |

1. **Create load balancer**を選択します。

ALBをNLBのターゲットとして登録します:

1. EC2ダッシュボードで、左側のメニューバーから**Target Groups**を選択します。
1. `gitlab-nlb-alb-target`ターゲットグループを選択します。
1. **Targets**タブで、**Register targets**を選択します。
1. `gitlab-alb` Application Load Balancerを選択し、**Register pending targets**を選択します。
1. **保存**を選択します。

> [!note]
> `gitlab-nlb-ssh-target`と`gitlab-alb-http-target`ターゲットグループのターゲットは、このガイドの以降で作成される[オートスケールグループでインスタンスが起動されると自動的に登録されます。](#create-an-auto-scaling-group)

{{< /tab >}}

{{< /tabs >}}

NLBロードバランサーが稼働したら、Security Groupsを再確認して、NLBを介したアクセスのみに制限し、その他の要件を設定できます。

一部の属性は、ロードバランサーが作成された後にのみ設定できます。以下は、要件に基づいて設定できるいくつかの機能です:

- [Client IP preservation](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#client-ip-preservation)は、ターゲットグループではデフォルトで有効になっています。これにより、ロードバランサーに接続しているクライアントのIPがGitLabアプリケーションで保持されます。要件に基づいてこれを有効/無効にできます。
- [Proxy Protocol](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#proxy-protocol)は、ターゲットグループではデフォルトで無効になっています。これにより、ロードバランサーがプロキシプロトコルヘッダーを使用して追加情報を送信できるようになります。この機能を有効にする場合は、内部ロードバランサーやNGINXなど、他の環境コンポーネントも同様に設定されていることを確認してください。このPOCの場合、[後でGitLabノード](#proxy-protocol)で有効にするだけで、プロキシプロトコルの設定が完了します。

### ロードバランサーのDNSを設定する {#configure-dns-for-load-balancer}

Route 53ダッシュボードで、左側のナビゲーションバーの**Hosted zones**を選択します。

1. 既存のホストゾーンを選択するか、ドメインのホストゾーンがまだない場合は、**Create Hosted Zone**を選択し、ドメイン名を入力して**Create**を選択します。
1. **Create record**を選択し、次の値を指定します。
   1. **Name**: ドメイン名（デフォルト値）を使用するか、サブドメインを入力します。
   1. **Type**: **A - IPv4 address**を選択します。
   1. **Alias**: デフォルトでは**disabled**になっています。このオプションを有効にします。
   1. **Route traffic to**: **Alias to Network Load Balancer**を選択します。
   1. **Region**: ネットワークロードバランサーが存在するリージョンを選択します。
   1. **Choose network load balancer**: 先ほど作成したネットワークロードバランサーを選択します。
   1. **Routing Policy**: ここでは**Simple**を使用しますが、ユースケースに応じて別のポリシーを選択することもできます。
   1. **Evaluate Target Health**: この値は**No**に設定しますが、ターゲットヘルスに基づいてロードバランサーがトラフィックをルーティングするよう設定することもできます。
   1. **Create**を選択します。
1. Route 53を通じてドメインを登録した場合、これで完了です。別のドメインレジストラを使用している場合は、そのドメインレジストラでDNSレコードを更新する必要があります。これを行うには、次の手順に従います。
   1. **Hosted zones**を選択し、先ほど追加したドメインを選択します。
   1. `NS`レコードの一覧が表示されます。ドメインレジストラの管理者パネルから、これらの各`NS`レコードをドメインのDNSレコードに追加します。この手順は、ドメインレジストラによって異なる場合があります。行き詰まった場合は、**「レジストラの名前」DNSレコードの追加**をGoogleで検索すると、ドメインレジストラに固有のヘルプ記事が見つかります。

具体的な手順は使用するレジストラによって異なり、このガイドの範囲外です。

## PostgreSQLとRDS {#postgresql-with-rds}

データベースサーバーには、冗長性を確保するためにマルチAZを提供するAmazon RDS for PostgreSQLを使用します（[Auroraはサポートして**いません**](https://gitlab.com/gitlab-partners-public/aws/aws-known-issues/-/issues/10)）。まず、セキュリティグループとサブネットグループを作成し、次に実際のRDSインスタンスを作成します。

### RDSセキュリティグループ {#rds-security-group}

データベース用のセキュリティグループを作成し、後で`gitlab-nlb-sec-group`にデプロイするインスタンスからの受信トラフィックを許可します。

1. EC2ダッシュボードで、左側のメニューバーから**Security Groups**を選択します。
1. **Create security group**を選択します。
1. 名前（この例では`gitlab-rds-sec-group`）と説明を入力し、**VPC**ドロップダウンリストから`gitlab-vpc`を選択します。
1. **Inbound rules**セクションで、**Add rule**を選択し、次の項目を設定します。
   1. **Type**: **PostgreSQL**ルールを検索して選択します。
   1. **Source type**: 「Custom」に設定します。
   1. **ソース**: ロードバランサーのアプローチに基づいて適切なセキュリティグループを選択します:
      - **NLB only**: `gitlab-nlb-sec-group`
      - **Hybrid NLB->ALB**: `gitlab-rails-sec-group`
1. 設定が完了したら、**Create security group**を選択します。

### RDSサブネットグループ {#rds-subnet-group}

1. RDSダッシュボードに移動し、左側のメニューから**Subnet Groups**を選択します。
1. **Create DB Subnet Group**を選択します。
1. **Subnet group details**で、名前（この例では`gitlab-rds-group`）と説明を入力し、VPCドロップダウンリストから`gitlab-vpc`を選択します。
1. **Availability Zones**ドロップダウンリストから、設定済みのサブネットを含むアベイラビリティーゾーンを選択します。この例では、`us-west-2a`と`us-west-2b`を追加します。
1. **Subnets**ドロップダウンリストから、[サブネットセクション](#subnets)で定義した2つのプライベートサブネット（`10.0.1.0/24`と`10.0.3.0/24`）を選択します。
1. 準備ができたら**Create**を選択します。

### データベースを作成する {#create-the-database}

> [!warning]
> CPUクレジットが持続的な高負荷時に枯渇するため、データベースにバースト可能なインスタンス (tクラスインスタンス)を使用することは避けてください。パフォーマンスの問題につながる可能性があります。

それでは、データベースを作成しましょう。

1. RDSダッシュボードに移動し、左側のメニューから**Databases**を選択し、**Create database**を選択します。
1. データベースの作成方法では**Standard Create**を選択します。
1. データベースエンジンとして**PostgreSQL**を選択し、GitLabバージョンの[データベース要件](../requirements.md#postgresql)で定義されている最小PostgreSQLバージョンを選択します。
1. これは本番環境サーバーであるため、**Templates**セクションで**Production**を選択します。
1. **Availability & durability**で、**Multi-AZ DB instance**を選択し、別の[アベイラビリティーゾーン](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)にスタンバイRDSインスタンスをプロビジョニングします。
1. **Settings**（設定）で、次の値を使用します。
   - DB instance identifier: `gitlab-db-ha`。
   - master username: `gitlab`。
   - master password: 非常に安全なパスワード。

   これらの情報は後で必要になるため、メモしておきます。

1. DB instance sizeには**Standard classes**を選択し、要件を満たすインスタンスサイズをドロップダウンリストから選択します。ここでは`db.m5.large`インスタンスを使用します。
1. **Storage**で、次の項目を設定します。
   1. ストレージタイプのドロップダウンリストから**Provisioned IOPS（SSD）**を選択します。Provisioned IOPS（SSD）ストレージは、この用途に最適です（ただし、コスト削減のためにGeneral Purpose（SSD）を選択することもできます）。詳細については、[Amazon RDSのストレージ](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html)を参照してください。
   1. ストレージを割り当て、プロビジョニングされたIOPSを設定します。ここでは、最小値である`100`と`1000`を使用します。
   1. ストレージのオートスケールを有効にし（オプション）、ストレージの最大しきい値を設定します。
1. **Connectivity**で、次の項目を設定します。
   1. **Virtual Private Cloud（VPC）**ドロップダウンリストで、先ほど作成したVPC（`gitlab-vpc`）を選択します。
   1. **DB subnet group**で、先ほど作成したサブネットグループ（`gitlab-rds-group`）を選択します。
   1. パブリックアクセスを**No**に設定します。
   1. **VPC security group**で、**Choose existing**を選択し、ドロップダウンリストから先ほど作成した`gitlab-rds-sec-group`を選択します。
   1. **Additional configuration**で、データベースポートをデフォルトの`5432`のままにします。
1. **Database authentication**で、**Password authentication**を選択します。
1. **Additional configuration**セクションを展開し、次の項目を設定します。
   1. 初期データベース名（この例では`gitlabhq_production`）。
   1. 必要に応じてバックアップを設定します。
   1. 最後に、**Maintenance**でマイナーバージョンの自動更新を無効にします。
   1. その他すべての設定はそのままにするか、必要に応じて微調整します。
   1. 問題がなければ、**Create database**を選択します。

これで、データベースが作成されました。次に、ElastiCacheを使用してRedisをセットアップします。

## ElastiCacheを使用したRedis {#redis-with-elasticache}

ElastiCacheは、ホストされるインメモリキャッシュ型のソリューションです。Redisは独自の永続性を保持し、GitLabアプリケーションのセッションデータ、一時的なキャッシュ情報、バックグラウンドジョブキューの保存に使用されます。

### Redisセキュリティグループを作成する {#create-a-redis-security-group}

1. EC2ダッシュボードに移動します。
1. 左側のメニューから**Security Groups**を選択します。
1. **Create security group**を選択し、詳細を入力します。名前（この例では`gitlab-redis-sec-group`）を付けて説明を追加し、先ほど作成したVPC（`gitlab-vpc`）を選択します。
1. **Inbound rules**セクションで、**ルールを追加する**を選択し、**Custom TCP**ルールを追加してポート`6379`を設定し、ロードバランサーのアプローチに基づいて"Custom" ソースを設定します:
   - **NLB only**: `gitlab-nlb-sec-group`
   - **Hybrid NLB->ALB**: `gitlab-rails-sec-group`
1. 設定が完了したら、**Create security group**を選択します。

### Redisサブネットグループ {#redis-subnet-group}

1. AWSコンソールからElastiCacheダッシュボードに移動します。
1. 左側のメニューの**Subnet Groups**に移動し、新しいサブネットグループを作成します（この例では`gitlab-redis-group`という名前を付けます）。先ほど作成したVPC（`gitlab-vpc`）を選択し、Selected subnetsテーブルに[プライベートサブネット](#subnets)のみが含まれていることを確認します。
1. 準備ができたら**Create**を選択します。

   ![GitLab Redisグループのサブネットグループを作成します。](img/ec_subnet_v17_0.png)

### Redisクラスターを作成する {#create-the-redis-cluster}

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

> [!note]
> バスティオンホストを維持したくない場合は、インスタンスにアクセスするために[AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)をセットアップできます。この設定は、このドキュメントの範囲外です。

### 踏み台ホストAを作成する {#create-bastion-host-a}

1. EC2ダッシュボードに移動し、**Launch instance**を選択します。
1. **Name and tags**セクションで、**Name**に`Bastion Host A`と指定します。
1. 最新の**Ubuntu Server LTS (HVM)** AMIを選択します。[サポート対象の最新のOSバージョン](../package/_index.md)については、GitLabドキュメントを確認してください。
1. インスタンスタイプを選択します。ここでは、踏み台ホストを使用して他のインスタンスにSSHで接続するだけなので、`t2.micro`を使用します。
1. **Key pair**セクションで、**Create new key pair**を選択します。
   1. キーペアに名前（この例では`bastion-host-a`）を付け、後で使用するために`bastion-host-a.pem`ファイルを保存します。
1. Network settingsセクションを編集します。
   1. **VPC**で、ドロップダウンリストから`gitlab-vpc`を選択します。
   1. **Subnet**で、先ほど作成したパブリックサブネット（`gitlab-public-10.0.0.0`）を選択します。
   1. **Auto-assign Public IP**で、**Disabled**が選択されていることを確認します。[Elastic IPアドレス](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html)は、[次のセクション](#assign-elastic-ip-to-the-bastion-host-a)でホストに割り当てます。
   1. **Firewall**で、**Create security group**を選択し、**Security group name**（この例では`bastion-sec-group`）を入力し、説明を追加します。
   1. すべての送信元からのSSHアクセスを有効にします（`0.0.0.0/0`）。より厳密なセキュリティを適用する必要がある場合は、単一のIPアドレスまたはCIDR表記のIPアドレス範囲を指定します。
1. ストレージについては、すべてをデフォルトのままにし、8 GBのルートボリュームのみを追加します。このインスタンスには何も保存しません。
1. すべての設定を確認し、問題がなければ、**Launch Instance**を選択します。

#### 踏み台ホストAにElastic IPを割り当てる {#assign-elastic-ip-to-the-bastion-host-a}

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

### 踏み台ホストBを作成する {#create-bastion-host-b}

1. 先ほどと同じ手順に従ってEC2インスタンスを作成しますが、次の点を変更します。
   1. **Subnet**には、先ほど作成した2つ目のパブリックサブネット（`gitlab-public-10.0.2.0`）を選択します。
   1. **Add Tags**セクションで、2つのインスタンスを識別できるように`Key: Name`と`Value: Bastion Host B`を設定します。
   1. セキュリティグループには、先ほど作成した既存の`bastion-sec-group`を選択します。

### SSHエージェント転送を使用する {#use-ssh-agent-forwarding}

Linuxを実行するEC2インスタンスでは、SSH認証に秘密キーファイルを使用します。SSHクライアントを使用し、クライアントに保存されている秘密キーファイルで踏み台ホストに接続します。踏み台ホストには秘密キーファイルが存在しないため、プライベートサブネット内のインスタンスには接続できません。

踏み台ホストに秘密キーファイルを保存するのは不適切です。この問題を回避するには、クライアントでSSHエージェント転送を使用します。

たとえば、コマンドラインの`ssh`クライアントは、次のような`-A`スイッチでエージェント転送を使用します。

```shell
ssh -A user@<bastion-public-IP-address>
```

他のクライアントでSSHエージェント転送を使用する手順については、[Securely Connect to Linux Instances Running in a Private Amazon VPC](https://aws.amazon.com/blogs/security/securely-connect-to-linux-instances-running-in-a-private-amazon-vpc/)を参照してください。

## GitLabをインストールしてカスタムAMIを作成する {#install-gitlab-and-create-custom-ami}

後で起動設定に使用するため、設定済みのカスタムGitLab AMIが必要です。まず公式のGitLab AMIを使用してGitLabインスタンスを作成します。次に、PostgreSQL、Redis、Gitaly向けのカスタム設定を追加します。必要に応じて、公式のGitLab AMIを使用せず、独自に選択したEC2インスタンスを起動し、[GitLabを手動でインストール](https://about.gitlab.com/install/)することもできます。

### GitLabをインストールする {#install-gitlab}

EC2ダッシュボードで、次の手順に従います。

1. [Find official GitLab-created AMI IDs on AWS](#find-official-gitlab-created-ami-ids-on-aws)というタイトルの以下のセクションを使用して、正しいAMIを見つけて**Launch**を選択します。
1. **Name and tags**セクションで、**Name**に`GitLab`と指定します。
1. **Instance type**ドロップダウンリストで、ワークロードに応じてインスタンスタイプを選択します。[ハードウェア要件](../requirements.md)を参照し、ニーズに合ったタイプを選択します（少なくとも`c5.2xlarge`。これは100人のユーザーに十分対応できます）。
1. **Key pair**セクションで、**Create new key pair**を選択します。
   1. キーペアに名前（この例では`gitlab`）を付け、後で使用するために`gitlab.pem`ファイルを保存します。
1. **Network settings**セクション:
   1. **VPC**: 先ほど作成した`gitlab-vpc`を選択します。
   1. **Subnet**: 先ほど作成したサブネットの一覧から`gitlab-private-10.0.1.0`を選択します。
   1. **Auto-assign Public IP**: `Disable`を選択します。
   1. **Firewall**: **Select existing security group**を選択し、ロードバランサーのアプローチに基づいて適切なセキュリティグループを選択します:
      - **NLB only**: `gitlab-nlb-sec-group`と`bastion-sec-group`
      - **Hybrid NLB->ALB**: `gitlab-rails-sec-group`と`bastion-sec-group`

      `bastion-sec-group`は、[SSH Agent Forwarding](#use-ssh-agent-forwarding)を使用して、管理および設定タスクのためにバスティオンホストからのSSHアクセスを許可します。
1. ストレージについては、ルートボリュームはデフォルトで8 GiBに設定されています。ここにはデータを保存しないため、この容量で十分です。
1. すべての設定を確認し、問題がなければ、**Launch Instance**を選択します。

### カスタム設定を追加する {#add-custom-configuration}

[SSHエージェント転送](#use-ssh-agent-forwarding)を使用し、**踏み台ホストA**経由でGitLabインスタンスに接続します。接続したら、次のカスタム設定を追加します。

#### Let's Encryptを無効にする {#disable-lets-encrypt}

ロードバランサーでSSL証明書を追加するため、GitLabに組み込まれているLet's Encryptのサポートは必要ありません。`https`ドメインを使用する場合、Let's Encryptは[デフォルトで有効](https://docs.gitlab.com/omnibus/settings/ssl/#enable-the-lets-encrypt-integration)になっているため、明示的に無効にする必要があります。

1. `/etc/gitlab/gitlab.rb`を開き、無効にします。

   ```ruby
   letsencrypt['enable'] = false
   ```

1. ファイルを保存し、変更を反映するために再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

#### PostgreSQLに必要な拡張機能をインストールする {#install-the-required-extensions-for-postgresql}

> [!note]
> `gitlab`ユーザーが[`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles)ロールを持っている場合、GitLabは必要な拡張機能を自動的にインストールできます。その場合、以下の手動手順は必要ありません。

GitLabインスタンスからRDSインスタンスに接続してアクセスを検証し、[required PostgreSQL extensions](../postgresql_extensions.md)をインストールします。

ホストまたはエンドポイントを見つけるには、**Amazon RDS** > **Databases**に移動し、先ほど作成したデータベースを選択します。**Connectivity & security**タブでエンドポイントを探します。

`-h`には、RDSエンドポイントのホスト名のみを使用し、末尾のコロンとポート番号は省略します:

```shell
sudo /opt/gitlab/embedded/bin/psql -U gitlab -h <rds-endpoint> -d gitlabhq_production
```

次に、`CREATE EXTENSION`を使用して各[required extension](../postgresql_extensions.md)をインストールします:

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS ...;
```

`\dx`でインストールされた拡張機能を検証します。

#### PostgreSQLとRedisに接続するようにGitLabを設定する {#configure-gitlab-to-connect-to-postgresql-and-redis}

1. `/etc/gitlab/gitlab.rb`を編集し、`external_url 'http://<domain>'`オプションを見つけて、使用している`https`ドメインに変更します。

1. GitLabデータベース設定を探して、必要に応じてコメントアウトを解除します。今回のケースでは、データベースアダプター、エンコード、ホスト、データベース名、ユーザー名、パスワードを指定します。

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

   # Adjust based on your Redis setting
   gitlab_rails['redis_ssl'] = true
   ```

1. 最後に、変更を反映するためにGitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. チェックとサービスステータスを実行して、すべてが正しく設定されていることを確認することもできます。

   ```shell
   sudo gitlab-rake gitlab:check
   sudo gitlab-ctl status
   ```

#### Gitalyを設定する {#set-up-gitaly}

> [!warning]
> このアーキテクチャでは、単一のGitalyサーバーが単一障害点になります。この制限を解消するには、[Gitaly Cluster (Praefect)](../../administration/gitaly/praefect/_index.md)を使用します。

Gitalyは、Gitリポジトリへの高レベルのRPCアクセスを提供するサービスです。以前に設定した[プライベートサブネット](#subnets)のいずれかに配置した個別のEC2インスタンス上で、Gitalyを有効にして設定する必要があります。

GitalyをインストールするEC2インスタンスを作成します。

1. EC2ダッシュボードで**Launch instance**を選択します。
1. **Name and tags**セクションで、**Name**に`Gitaly`と指定します。
1. AMIを選択します。この例では、最新の**Ubuntu Server LTS (HVM), SSD Volume Type**を選択します。[サポート対象の最新のOSバージョン](../package/_index.md)については、GitLabドキュメントを確認してください。
1. インスタンスタイプを選択します。`m5.xlarge`を選択します。
1. **Key pair**セクションで、**Create new key pair**を選択します。
   1. キーペアに名前（この例では`gitaly`）を付け、後で使用するために`gitaly.pem`ファイルを保存します。
1. Network settingsセクション:
   1. **VPC**で、ドロップダウンリストから`gitlab-vpc`を選択します。
   1. **Subnet**で、先ほど作成したプライベートサブネット（`gitlab-private-10.0.1.0`）を選択します。
   1. **Auto-assign Public IP**で、**Disable**が選択されていることを確認します。
   1. **Firewall**で、**Create security group**を選択し、**Security group name**（この例では`gitlab-gitaly-sec-group`）を入力し、説明を追加します。
      1. **Custom TCP**ルールを作成し、ポート`8075`を**Port Range**に追加します。**ソース**には、ロードバランサーのアプローチに基づいて適切なセキュリティグループを選択します:
         - **NLB only**: `gitlab-nlb-sec-group`
         - **Hybrid NLB->ALB**: `gitlab-rails-sec-group`
      1. さらに、踏み台ホストから[SSHエージェント転送](#use-ssh-agent-forwarding)を使用して接続できるように、`bastion-sec-group`からのSSH接続を許可するインバウンドルールを追加します。
1. Root volume sizeを`20 GiB`に増やし、**Volume Type**を`Provisioned IOPS SSD (io1)`に変更します。（ボリュームサイズには任意の値を設定できます。リポジトリストレージ要件を満たす十分な容量を確保してください。）
   1. **IOPS**には`1000`（20 GiB x 50 IOPS）を設定します。1 GiBあたり最大50 IOPSまでプロビジョニングできます。より大きなボリュームを選択する場合は、それに応じてIOPSを増やします。`git`のように、多数の小さなファイルを直列的に書き込むワークロードでは、高性能ストレージが必要となるため、`Provisioned IOPS SSD (io1)`を選択します。
1. すべての設定を確認し、問題がなければ、**Launch Instance**を選択します。

> [!note]
> 設定およびリポジトリストレージデータをルートボリュームに保存する代わりに、追加のEBSボリュームをリポジトリストレージとして追加することもできます。前述のガイダンスと同様の手順に従ってください。[Amazon EBSの料金ページ](https://aws.amazon.com/ebs/pricing/)を参照してください。

EC2インスタンスの準備が整ったので、[ドキュメントに従ってGitLabをインストールし、Gitalyを専用サーバー上にセットアップ](../../administration/gitaly/configure_gitaly.md#run-gitaly-on-its-own-server)します。先ほど[作成したGitLabインスタンス](#install-gitlab)で、前述のドキュメントに記載されたクライアント側のセットアップ手順を実行します。

##### Elastic File System（EFS） {#elastic-file-system-efs}

> [!warning]
> EFSはGitLabのパフォーマンスに悪影響を及ぼす可能性があるため、使用はお勧めしません。詳細については、[クラウドベースのファイルシステムの回避に関するドキュメント](../../administration/nfs.md#avoid-using-cloud-based-file-systems)を参照してください。

それでもEFSを使用する場合は、[PosixUser](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-efs-accesspoint.html#cfn-efs-accesspoint-posixuser)属性を省略するか、Gitalyがインストールされているシステム上の`git`ユーザーのUIDとグループID（GID）を正しく指定してください。UIDとGIDは、次のコマンドで取得できます。

```shell
# UID
id -u git

# GID
id -g git
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

カスタムAMIの一部として静的ホストキーを作成することで、この手順を自動化します。また、これらのホストキーはEC2インスタンスが起動するたびにローテーションされるため、カスタムAMIに「ハードコード」することで、この問題を回避できます。

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

共有ストレージとしてNFSを使用していないため、バックアップ、アーティファクト、LFSオブジェクト、アップロード、マージリクエストの差分、コンテナレジストリのイメージなどを保存するために[Amazon S3](https://aws.amazon.com/s3/)バケットを使用します。GitLabのドキュメントには、これらの各データタイプに対して[オブジェクトストレージを設定する方法](../../administration/object_storage.md)や、GitLabでオブジェクトストレージを使用する際の詳細情報が記載されています。

> [!note]
> 以前に作成した[AWS IAM profile](#create-an-iam-role)を使用しているため、オブジェクトストレージを設定する際にAWSアクセスキーとシークレットアクセスキー/キー/バリューペアを省略するようにしてください。代わりに、先ほどリンクを紹介したオブジェクトストレージに関するドキュメントに記載されているとおり、設定で`'use_iam_profile' => true`を使用します。
>
> S3アクセスにIAMロールを使用する場合、GitLabはIMDSv1とIMDSv2の両方をサポートし、利用可能な場合は自動的にIMDSv2を使用します。

`gitlab.rb`ファイルへの変更を保存した後、必ず`sudo gitlab-ctl reconfigure`を実行してください。

---

これで、GitLabインスタンスの設定変更は完了です。次に、このインスタンスを基にカスタムAMIを作成し、起動設定とオートスケールグループに使用します。

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

先ほど作成した[ロードバランサー](#load-balancer)でプロキシプロトコルが有効になっている場合は、`gitlab.rb`ファイルでもこれを[有効](https://docs.gitlab.com/omnibus/settings/nginx/#configuring-the-proxy-protocol)にする必要があります。

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

- 公式のGitLab AMIを使用した場合は、インスタンスID。
- `/etc/gitlab/initial_root_password`に24時間保存されるランダム生成パスワード。

デフォルトのパスワードを変更するには、`root`ユーザーとしてデフォルトのパスワードでサインインし、[ユーザープロファイルで変更](../../user/profile/user_passwords.md#change-your-password)します。

[オートスケールグループ](#create-an-auto-scaling-group)が新しいインスタンスを起動すると、ユーザー名`root`と新しく作成されたパスワードでサインインできます。

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
1. **Select existing security group**をチェックし、ロードバランサーのアプローチに基づいて適切なセキュリティグループを選択します:
   - **NLB only**: `gitlab-nlb-sec-group`と`bastion-sec-group`
   - **Hybrid NLB->ALB**: `gitlab-rails-sec-group`と`bastion-sec-group`

   `bastion-sec-group`は、[SSH Agent Forwarding](#use-ssh-agent-forwarding)を使用して、管理および設定タスクのためにバスティオンホストからのSSHアクセスを許可します。
1. **Advanced details**セクション:
   1. **IAM instance profile**: [先ほど作成](#create-an-iam-role)した`GitLabS3Access`ロールを選択します。
1. すべての設定を確認し、問題がなければ**Create launch template**を選択します。

### オートスケールグループを作成する {#create-an-auto-scaling-group}

EC2ダッシュボードで、次の手順に従います。

1. 左側のメニューから**Auto scaling groups**を選択し、**Create Auto Scaling group**を選択します。
1. **Group name**を入力します（この例では`gitlab-auto-scaling-group`）。
1. **Launch template**で、先ほど作成した起動テンプレートを選択します。**Next**を選択します。
1. Network settingsセクション:
   1. **VPC**で、ドロップダウンリストから`gitlab-vpc`を選択します。
   1. **Availability Zones and subnets**で、[先ほど作成したプライベートサブネット](#subnets)（`gitlab-private-10.0.1.0`と`gitlab-private-10.0.3.0`）を選択します。
   1. **Next**を選択します。
1. Load Balancing settingsセクション:
   1. **Attach to an existing load balancer**を選択します。
   1. **Existing load balancer target groups**ドロップダウンリストで、ロードバランサーのアプローチに基づいて適切なターゲットグループを選択します:
      - **NLB only**: `gitlab-nlb-ssh-target`と`gitlab-nlb-http-target`を選択します
      - **Hybrid NLB->ALB**: `gitlab-nlb-ssh-target`と`gitlab-alb-http-target`を選択します。オートスケールグループは、起動されたすべてのインスタンスをこれらのターゲットグループに自動的に登録します。
   1. **Health Check Type**で、**Turn on Elastic Load Balancing health checks**オプションをオンにします。**Health Check Grace Period**は、デフォルトの`300`秒のままにします。
   1. **Next**を選択します。
1. **Group size**で、**Desired capacity**を`2`に設定します。
1. Scaling settingsセクションで、次の手順に従います。
   1. **No scaling policies**を選択します。ポリシーは以降に設定されます。
   1. **Min desired capacity**: `2`に設定します。
   1. **Max desired capacity**: `4`に設定します。
   1. **Next**を選択します。
1. 最後に、必要に応じて通知とタグを設定し、変更内容を確認してから、オートスケールグループを作成します。
1. オートスケールグループを作成したら、[CloudWatch](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html)でスケールアップおよびスケールダウンポリシーを作成し、それらを割り当てる必要があります。
   1. 先ほど作成した**オートスケールグループ**の**EC2**インスタンスから取得したメトリクスに対して、`CPUUtilization`のアラームを作成します。
   1. 次の条件を使用して[スケールアップポリシー](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html#step-scaling-create-scale-out-policy)を作成します。
      1. `CPUUtilization`が60%以上の場合は、キャパシティユニットを`1`**追加**します。
      1. **Scaling policy name**を`Scale Up Policy`に設定します。

   ![スケールアップポリシーを設定します。](img/scale_up_policy_v17_0.png)

   1. 次の条件を使用して[スケールダウンポリシー](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html#step-scaling-create-scale-in-policy)を作成します。
      1. `CPUUtilization`が45%以下の場合は、キャパシティユニットを`1`**削除**します。
      1. **Scaling policy name**を`Scale Down Policy`に設定します。

   ![スケールダウンポリシーを設定します。](img/scale_down_policy_v17_0.png)

   1. 先ほど作成したオートスケールグループに、新しい動的スケーリングポリシーを割り当てます。

オートスケールグループが作成されると、EC2ダッシュボード上で新しいインスタンスが起動していることを確認できます。また、ロードバランサーに新しいインスタンスが追加されていることも確認できます。インスタンスがヘルスチェックに合格すると、ロードバランサーからトラフィックを受信する準備が整います。

インスタンスはオートスケールグループによって作成されるため、インスタンスに戻り、[先ほど手動で作成したインスタンス](#install-gitlab)を終了します。このインスタンスは、カスタムAMIを作成する目的にのみ使用しました。

## Prometheusによるヘルスチェックとモニタリング {#health-check-and-monitoring-with-prometheus}

さまざまなサービスで有効化できるAmazon CloudWatchとは別に、GitLabはPrometheusに基づく独自の統合モニタリングソリューションを提供しています。設定方法の詳細については、[GitLab Prometheus](../../administration/monitoring/prometheus/_index.md)を参照してください。

GitLabにはさまざまな[ヘルスチェックエンドポイント](../../administration/monitoring/health_check.md)が用意されており、pingしてレポートを取得できます。

## GitLab Runner {#gitlab-runner}

[GitLab CI/CD](../../ci/_index.md)を活用するには、少なくとも1つの[Runner](https://docs.gitlab.com/runner/)を設定する必要があります。

[AWS上でオートスケール対応のGitLab Runner](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/)を設定する方法については、リンク先を参照してください。

## バックアップと復元 {#backup-and-restore}

GitLabには、Gitデータ、データベース、添付ファイル、LFSオブジェクトなどを[バックアップ](../../administration/backup_restore/_index.md)および復元するためのツールが用意されています。

知っておくべき重要な点:

- バックアップ/復元ツールは、シークレットなどの一部の設定ファイルを**保存しません**。これらは[手動で設定](../../administration/backup_restore/backup_gitlab.md#storing-configuration-files)する必要があります。
- デフォルトでは、バックアップファイルはローカルに保存されますが、[S3を使用してGitLabをバックアップ](../../administration/backup_restore/backup_gitlab.md#using-amazon-s3)することもできます。
- [バックアップから特定のディレクトリを除外](../../administration/backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup)できます。

### GitLabをバックアップする {#backing-up-gitlab}

GitLabをバックアップするには、次の手順に従います。

1. インスタンスにSSHで接続します。
1. バックアップを作成します。

   ```shell
   sudo gitlab-backup create
   ```

### バックアップからGitLabを復元する {#restoring-gitlab-from-a-backup}

GitLabを復元するには、まず[復元に関するドキュメント](../../administration/backup_restore/_index.md#restore-gitlab)、特に復元の前提条件を確認してください。次に、[Linuxパッケージインストールセクション](../../administration/backup_restore/restore_gitlab.md#restore-for-linux-package-installations)に記載された手順に従います。

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

- [GitLabのスケーリング](../../administration/reference_architectures/_index.md): GitLabはさまざまなクラスタリングをサポートしています。
- [Geoレプリケーション](../../administration/geo/_index.md): Geoは、広範な地域に分散した開発チーム向けのソリューションです。
- [Linuxパッケージ](https://docs.gitlab.com/omnibus/): GitLabインスタンスの管理について知っておくべきすべての情報が掲載されています。
- [ライセンスの追加](../../administration/license.md): ライセンスを適用すると、GitLab Enterprise Editionのすべての機能を有効にできます。
- [価格](https://about.gitlab.com/pricing/): 各プランの価格をご確認ください。

## トラブルシューティング {#troubleshooting}

### インスタンスがヘルスチェックに失敗する {#instances-are-failing-health-checks}

インスタンスがロードバランサーのヘルスチェックに失敗する場合は、以前に設定したヘルスチェックエンドポイントからステータス`200`が返されていることを確認してください。ステータス`302`などのリダイレクトを含む、その他のステータスが返されるとヘルスチェックは失敗します。

ヘルスチェックに合格するために、`root`ユーザーにパスワードを設定し、サインインエンドポイントでの自動リダイレクトを防ぐ必要がある場合があります。

### メッセージ: `The change you requested was rejected (422)` {#message-the-change-you-requested-was-rejected-422}

Webインターフェースでパスワードを設定しようとした際にこのページが表示される場合は、`gitlab.rb`内の`external_url`がリクエスト元のドメインと一致していることを確認してください。ファイルに変更を加えた場合は、`sudo gitlab-ctl reconfigure`を実行します。

### 一部のジョブログがオブジェクトストレージにアップロードされない {#some-job-logs-are-not-uploaded-to-object-storage}

GitLabデプロイを複数のノードにスケールアップすると、一部のジョブログが[オブジェクトストレージ](../../administration/object_storage.md)に正常にアップロードされない場合があります。CIでオブジェクトストレージを使用するには、[増分ログが必要](../../administration/object_storage.md#alternatives-to-file-system-storage)です。

まだ有効にしていない場合は、[増分ログ](../../administration/cicd/job_logs.md#incremental-logging)を有効にします。
