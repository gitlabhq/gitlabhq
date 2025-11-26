---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: クラスター証明書を使用したEKSクラスターへの接続（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で非推奨になりました。[Infrastructure as Code](../../infrastructure/iac/_index.md)を使用して新しいクラスターを作成します。

{{< /alert >}}

GitLabを通じて、新しいクラスターを作成したり、Amazon Elastic Kubernetes Service（Amazon EKS）でホストされている既存のクラスターを追加したりできます。

## 既存のEKSクラスターを接続する {#connect-an-existing-eks-cluster}

すでにEKSクラスターがあり、GitLabに接続する場合は、[Kubernetes向けGitLabエージェント](../../clusters/agent/_index.md)を使用してください。

## 新しいEKSクラスターを作成する {#create-a-new-eks-cluster}

GitLabから新しいクラスターを作成するには、[Infrastructure as Code](../../infrastructure/iac/_index.md)を使用します。

### クラスター証明書を使用したEKS上に新しいクラスターを作成する方法（非推奨） {#how-to-create-a-new-cluster-on-eks-through-cluster-certificates-deprecated}

{{< history >}}

- GitLab 14.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/327908)になりました。

{{< /history >}}

前提要件: 

- [Amazon Web Services](https://aws.amazon.com/)アカウント。
- IAMリソースを管理するための権限。

インスタンスレベルのクラスターについては、[GitLab Self-Managedインスタンスの追加要件](#additional-requirements-for-gitlab-self-managed-instances)を参照してください。

証明書ベースの方法でプロジェクト、グループ、またはインスタンスの新しいKubernetesクラスターを作成するには:

1. [クラスターのアクセス制御（RBACまたはABAC）を定義します](cluster_access.md)。
1. [GitLabでクラスターを作成します](#create-a-new-eks-cluster-in-gitlab)。
1. [Amazonでクラスターを準備します](#prepare-the-cluster-in-amazon)。
1. [GitLabでクラスターのデータを設定します](#configure-your-clusters-data-in-gitlab)。

追加の手順:

1. [デフォルトのストレージクラスを作成する](#create-a-default-storage-class)。
1. [EKSにアプリをデプロイします](#deploy-the-app-to-eks)。

#### GitLabで新しいEKSクラスターを作成します {#create-a-new-eks-cluster-in-gitlab}

クラスター証明書を使用して、プロジェクト、グループ、またはインスタンスの新しいEKSクラスターを作成するには:

1. 以下に移動します:
   - プロジェクトレベルのクラスターの場合は、プロジェクトの**操作** > **Kubernetesクラスター**ページ。
   - グループレベルのクラスターの場合は、グループの**Kubernetes**ページ。
   - インスタンスレベルのクラスターの場合は、**管理者**エリアの**Kubernetes**ページ。
1. **Integrate with a cluster certificate**（クラスター証明書とのインテグレーション）を選択します。
1. **Create new cluster**（新しいクラスターの作成）タブで、**Amazon EKS**を選択すると、後続の手順で必要となる`Account ID`と`External ID`が表示されます。
1. [IAM管理コンソール](https://console.aws.amazon.com/iam/home)で、IAMポリシーを作成します:
   1. 左側のパネルから**ポリシー**を選択します。
   1. **Create Policy**（ポリシーの作成）を選択します。新しいウィンドウが開きます。
   1. **JSON**タブを選択し、既存のコンテンツの代わりに次のスニペットを貼り付けます。これらの権限により、GitLabはリソースを作成できますが、削除することはできません:

      ```json
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Effect": "Allow",
                  "Action": [
                      "autoscaling:CreateAutoScalingGroup",
                      "autoscaling:DescribeAutoScalingGroups",
                      "autoscaling:DescribeScalingActivities",
                      "autoscaling:UpdateAutoScalingGroup",
                      "autoscaling:CreateLaunchConfiguration",
                      "autoscaling:DescribeLaunchConfigurations",
                      "cloudformation:CreateStack",
                      "cloudformation:DescribeStacks",
                      "ec2:AuthorizeSecurityGroupEgress",
                      "ec2:AuthorizeSecurityGroupIngress",
                      "ec2:RevokeSecurityGroupEgress",
                      "ec2:RevokeSecurityGroupIngress",
                      "ec2:CreateSecurityGroup",
                      "ec2:createTags",
                      "ec2:DescribeImages",
                      "ec2:DescribeKeyPairs",
                      "ec2:DescribeRegions",
                      "ec2:DescribeSecurityGroups",
                      "ec2:DescribeSubnets",
                      "ec2:DescribeVpcs",
                      "eks:CreateCluster",
                      "eks:DescribeCluster",
                      "iam:AddRoleToInstanceProfile",
                      "iam:AttachRolePolicy",
                      "iam:CreateRole",
                      "iam:CreateInstanceProfile",
                      "iam:CreateServiceLinkedRole",
                      "iam:GetRole",
                      "iam:listAttachedRolePolicies",
                      "iam:ListRoles",
                      "iam:PassRole",
                      "ssm:GetParameters"
                  ],
                  "Resource": "*"
              }
          ]
      }
      ```

      このプロセス中にエラーが発生した場合、GitLabは変更をロールバックしません。リソースは手動で削除する必要があります。これを行うには、関連する[CloudFormationスタック](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-delete-stack.html)を削除します。

   1. **Review policy**（ポリシーのレビュー）を選択します。
   1. このポリシーに適した名前を入力し、**Create Policy**（ポリシーの作成）を選択します。これでこのウィンドウを閉じることができます。

### Amazonでクラスターを準備する {#prepare-the-cluster-in-amazon}

1. [クラスターの**EKS IAM role**（EKS IAMロール）を作成します](#create-an-eks-iam-role-for-your-cluster)（**role A**（ロールA））。
1. [AmazonとのGitLab認証のために**another EKS IAM role**（別のEKS IAMロール）を作成します](#create-another-eks-iam-role-for-gitlab-authentication-with-amazon)（**role B**（ロールB））。

#### クラスターのEKS IAMロールを作成する {#create-an-eks-iam-role-for-your-cluster}

[IAM管理コンソール](https://console.aws.amazon.com/iam/home)で、**EKS IAM role**（EKS IAMロール）（**role A**（ロールA））を[Amazon EKSクラスターのIAMロールの手順](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html)に従って作成します。このロールは、Amazon EKSによって管理されるKubernetesクラスターが、サービスで使用するリソースを管理するために、ユーザーに代わって他のAWSサービスを呼び出すことができるようにするために必要です。

GitLabがEKSクラスターを正しく管理するには、ガイドが提案するポリシーに加えて`AmazonEKSClusterPolicy`を含める必要があります。

#### AmazonとのGitLab認証のために別のEKS IAMロールを作成する {#create-another-eks-iam-role-for-gitlab-authentication-with-amazon}

[IAM管理コンソール](https://console.aws.amazon.com/iam/home)で、AWSとのGitLab認証のために別のIAMロール（**role B**（ロールB））を作成します:

1. AWS IAMコンソールで、左側のパネルから**ロール**を選択します。
1. **ロールを作成する**を選択します。
1. **Select type of trusted entity**（信頼されたエンティティの種類の選択）で、**Another AWS account**（別のAWSアカウント）を選択します。
1. GitLabからのアカウントIDを**アカウントID**フィールドに入力します。
1. **Require external ID**（外部IDを必須にする）をオンにします。
1. GitLabからの外部IDを［**External ID**（外部ID）］フィールドに入力します。
1. **次へを選択します: 権限**を選択し、作成したポリシーを選択します。
1. **次へを選択します: タグ**を選択し、必要に応じてこのロールに関連付けるタグを入力します。
1. **次へを選択します: 確認**を選択します。
1. 表示されたフィールドに、ロール名とオプションの説明を入力します。
1. **ロールを作成する**を選択します。新しいロール名が上部に表示されます。名前を選択し、新しく作成されたロールから`Role ARN`をコピーします。

### GitLabでクラスターのデータを設定する {#configure-your-clusters-data-in-gitlab}

1. GitLabに戻り、コピーしたAmazonリソースネームを［**Role ARN**（Amazonリソースネーム）］フィールドに入力します。
1. ［**Cluster Region**（クラスターリージョン）］フィールドに、新しいクラスターに使用する予定の[リージョン](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html)を入力します。GitLabは、ロールを認証するときに、このリージョンへのアクセス権があることを確認します。
1. **Authenticate with AWS**（AWSで認証する）を選択します。
1. [クラスターの設定](#cluster-settings)を調整します。
1. **Create Kubernetes cluster**（Kubernetesクラスターの作成）ボタンを選択します。

約10分後、クラスターを使用できるようになります。

{{< alert type="note" >}}

`kubectl`を[インストールおよび設定済み](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#get-started-kubectl)で、それを使用してクラスターを管理する場合は、AWS外部IDをAWS設定に追加する必要があります。AWS CLIの設定方法の詳細については、[AWS CLIでIAMロールを使用](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html#cli-configure-role-xaccount)を参照してください。

{{< /alert >}}

#### クラスターの設定 {#cluster-settings}

新しいクラスターを作成するときは、次の設定があります:

| 設定                 | 説明 |
| ----------------------- |------------ |
| Kubernetesクラスター名 | クラスターの名前。 |
| 環境スコープ       | [関連付けられた環境](multiple_kubernetes_clusters.md#setting-the-environment-scope)。 |
| サービスロール            | **EKS IAM role**（EKS IAMロール）（**role A**（ロールA））。 |
| Kubernetesのバージョン      | クラスターの[Kubernetesのバージョン](../../clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)。 |
| キーペア名           | ワーカーノードへの接続に使用できる[キーペア](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)。 |
| VPC:                     | EKSクラスターリソースに使用する[VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)。 |
| サブネット                 | ワーカーノードが実行されるVPC内の[サブネット](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html)。2つ必要です。 |
| セキュリティグループ          | ワーカーノードサブネットで作成される、EKS管理対象のElastic Network Interfaceに適用する[セキュリティグループ](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)。 |
| インスタンスの種類           | ワーカーノードの[インスタンスの種類](https://aws.amazon.com/ec2/instance-types/)。 |
| ノード数              | ワーカーノードの数。 |
| GitLab管理対象クラスター  | GitLabで、このクラスターのネームスペースとサービスアカウントを管理するかどうかを確認します。 |

## デフォルトのストレージクラスを作成する {#create-a-default-storage-class}

Amazon EKSには、すぐに使用できるデフォルトのストレージクラスがないため、永続ボリュームのリクエストが自動的に実行されることはありません。Auto DevOpsの一部として、デプロイされたPostgreSQLインスタンスは永続ストレージをリクエストし、デフォルトのストレージクラスがないと開始できません。

まだ存在しない場合にデフォルトのストレージクラスを作成するには、[ストレージクラス](https://docs.aws.amazon.com/eks/latest/userguide/storage.html#storage-classes)を参照してください。

または、プロジェクト変数[`POSTGRES_ENABLED`](../../../topics/autodevops/cicd_variables.md)を`false`に割り当てて、PostgreSQLを無効にします。

## EKSにアプリをデプロイする {#deploy-the-app-to-eks}

RBACが無効になり、サービスがデプロイされると、[Auto DevOps](../../../topics/autodevops/_index.md)を活用して、アプリをビルド、テスト、およびデプロイできるようになります。

まだ有効になっていない場合は、[Auto DevOpsを有効にします](../../../topics/autodevops/_index.md#per-project)。ロードバランサーに解決されるワイルドカードDNSエントリが作成された場合は、Auto DevOps設定の`domain`フィールドに入力します。そうでない場合、デプロイされたアプリはクラスターの外部では外部から利用できません。

![EKSにアプリケーションをデプロイするパイプライン。](img/pipeline_v11_0.png)

GitLabは新しいパイプラインを作成し、アプリのビルド、テスト、およびデプロイを開始します。

パイプラインが終了すると、アプリはEKSで実行され、ユーザーが利用できるようになります。**操作** > **環境**を選択します。

![デプロイされた環境のステータスとアクセスオプション。](img/environment_v11_0.png)

GitLabは、環境とそのデプロイステータスのリスト、およびアプリを閲覧したり、モニタリングメトリクスを表示したり、実行中のポッドでShellにアクセスしたりするためのオプションを表示します。

## GitLab Self-Managedインスタンスの追加要件 {#additional-requirements-for-gitlab-self-managed-instances}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Self-Managedを使用している場合は、Amazon認証情報を設定する必要があります。GitLabはこれらの認証情報を使用して、Amazon Web Services IAMロールを引き受け、クラスターを作成します。

IAMユーザーを作成し、ユーザーがEKSクラスターを作成するために必要なロールを引き受ける権限があることを確認します。

たとえば、次のポリシードキュメントでは、アカウント`123456789012`で名前が`gitlab-eks-`で始まるロールを引き受けることができます:

```json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::123456789012:role/gitlab-eks-*"
  }
}
```

### Amazon認証を設定する {#configure-amazon-authentication}

GitLabでAmazon認証を設定するには、Amazon AWSコンソールでIAMユーザーのアクセスキーを生成し、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **Amazon EKS**を展開します。
1. **Amazon EKS連携を有効にする**をオンにします。
1. **アカウントID**を入力します。
1. [アクセスキーとID](#eks-access-key-and-id)を入力します。
1. **変更を保存**を選択します。

#### EKSアクセスキーとID {#eks-access-key-and-id}

インスタンスプロファイルを使用して、必要に応じてAWSから一時的な認証情報を動的に取得することができます。この場合は、`Access key ID`フィールドと`Secret access key`フィールドを空白のままにして、[IAMロールをEC2インスタンスに渡します](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html)。

それ以外の場合は、**Access key ID**（アクセスキーID）と**Secret access key**（シークレットアクセスキー）にアクセスキー認証情報を入力します。

## トラブルシューティング {#troubleshooting}

新しいクラスターを作成する際に、次のエラーがよく発生します。

### 検証に失敗しました: Amazonリソースネームは有効なAmazon Web Servicesリソース名である必要があります {#validation-failed-role-arn-must-be-a-valid-amazon-resource-name}

`Provision Role ARN`が正しいことを確認してください。有効なAmazonリソースネームの例:

```plaintext
arn:aws:iam::123456789012:role/gitlab-eks-provision'
```

### アクセスが拒否されました」: ユーザーにリソース`arn:aws:iam::y`に対する`sts:AssumeRole`を実行する権限がありません {#access-denied-user-is-not-authorized-to-perform-stsassumerole-on-resource-arnawsiamy}

このエラーは、[Amazon認証の設定](#configure-amazon-authentication)で定義された認証情報が、プロビジョンロールAmazonリソースネームによって定義されたロールを引き受けることができない場合に発生します:

```plaintext
User `arn:aws:iam::x` is not authorized to perform: `sts:AssumeRole` on resource: `arn:aws:iam::y`
```

以下を確認してください:

1. AWS認証情報の初期セットに[AssumeRoleポリシーがある](#additional-requirements-for-gitlab-self-managed-instances)。
1. プロビジョンロールには、指定されたリージョンにクラスターを作成するアクセス権があります。
1. アカウントIDと[外部ID](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html)が、AWSの［**Trust relationships**（信頼関係）］タブで定義された値と一致すること:

   ![EKSクラスターの作成に使用されるAWS IAMロールの信頼関係設定。](img/aws_iam_role_trust_v13_7.png)

### このVPCのセキュリティグループを読み込むことができませんでした {#could-not-load-security-groups-for-this-vpc}

設定フォームでオプションを入力されたとき、GitLabは、GitLabが提供されたロールを正常に引き受けましたが、そのロールにはフォームに必要なリソースを取得するための十分な権限がないため、このエラーを返します。ロールに正しい権限が割り当てられていることを確認してください。

### キーペアが読み込まれていません {#key-pairs-are-not-loaded}

GitLabは、指定された**Cluster Region**（クラスターリージョン）からキーペアを読み込むします。キーペアがそのリージョンに存在することを確認してください。

#### クラスターの作成中に`ROLLBACK_FAILED` {#rollback_failed-during-cluster-creation}

1つまたは複数のリソースの作成中にGitLabでエラーが発生したため、作成プロセスが停止しました。関連付けられている[CloudFormationスタック](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-view-stack-data-resources.html)を調べて、作成に失敗した特定のリソースを見つけることができます。

`Cluster`リソースがエラー`The provided role doesn't have the Amazon EKS Managed Policies associated with it.`で失敗した場合、**Role name**（ロール名）で指定されたロールが正しく設定されていません。

{{< alert type="note" >}}

このロールは、[EKSクラスターのIAMロール](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html)ガイドに従って作成したロールである必要があります。ガイドが提案するポリシーに加えて、GitLabがEKSクラスターを正しく管理するためには、このロールに`AmazonEKSClusterPolicy`ポリシーを含める必要もあります。

{{< /alert >}}
