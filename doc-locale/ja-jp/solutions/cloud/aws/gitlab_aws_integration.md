---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: GitLabとAWSのインテグレーションソリューションインデックス。
title: AWSと統合する
---

GitLabとAWSを統合する方法について学びます。

このコンテンツは、GitLabチームメンバーおよび広範なコミュニティのメンバーを対象としています。

特に記載がない限り、このすべてのコンテンツはGitLab.comとGitLab Self-Managedインスタンスの両方に適用されます。

GitLabは、一般的な設定、いずれかのプラットフォームに組み込まれた機能、および専用ソリューションを通じてAWSと統合します。

| テキストタグ                 | 設定 / ビルトイン / ソリューション                             | サポート/メンテナンス                                          |
| ------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `[AWS Configuration]`    | 既存のAWS機能の設定によるインテグレーション       | AWS                                                          |
| `[GitLab Configuration]` | 既存のGitLab機能の設定によるインテグレーション    | GitLab                                                       |
| `[AWS Built]`            | AWSインテグレーションに対応するために製品チームによってAWSに組み込まれています    | AWS                                                          |
| `[GitLab Built]`         | AWSインテグレーションに対応するために製品チームによってGitLabに組み込まれています | GitLab                                                       |
| `[AWS Solution]`         | AWSまたはAWSパートナーによってソリューション例として構築されています             | コミュニティ/例                                            |
| `[GitLab Solution]`      | GitLabまたはGitLabパートナーによってソリューション例として構築されています       | コミュニティ/例                                            |
| `[CI Solution]`          | 少なくとも一部はGitLab CIを使用して構築されているため <br />より顧客がカスタマイズ可能です。 | `[CI Solution]`とタグ付けされた項目は <br />他のタグのいずれか <br />メンテナンスステータスを示すものです。 |

## 開発アクティビティ向けインテグレーション {#integrations-for-development-activities}

これらのインテグレーションは、GitLabを使用してアプリケーションのワークロードをビルドすることと、それらをAWSにデプロイすることに関連しています。

### SCMインテグレーション {#scm-integrations}

#### AWS CodeStar Connectionインテグレーション {#aws-codestar-connection-integrations}

[2023/8/14 AWSリリースのお知らせ（GitLab.com向け）](https://aws.amazon.com/about-aws/whats-new/2023/08/aws-codepipeline-supports-gitlab/)

[2023/12/28 AWSリリースのお知らせ（GitLab Self-Managed / GitLab Dedicated向け）](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)

**AWS CodeStar Connections** \- 複数のAWSサービスへのSCM接続を有効にします。[GitLabを設定する](https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-create-gitlab.html)。[サポートされているプロバイダー](https://docs.aws.amazon.com/dtconsole/latest/userguide/supported-versions-connections.html)。[サポートされているAWSサービス](https://docs.aws.amazon.com/dtconsole/latest/userguide/integrations-connections.html) \- それぞれがGitLabをサポートするために更新が必要になる場合があります。そのため、GitLabをサポートするサブセットを次に示します。これはGitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで動作します。AWS CodeStar ConnectionsはすべてのAWSリージョンで利用できません - 除外リストについては[こちらをご覧ください](https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodestarConnectionSource.html)。（[2023/12/28](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)）`[AWS Built]`

[AWS CodeStar Connectionインテグレーションの動画解説（1分）](https://youtu.be/f7qTSa_bNig)

AWSサービスのうち、AWSアカウント内のCodeStar Connectionによって直接サポートされているもの:

- **AWS Service Catalog**はCodeStar Connectionsを直接継承します。GitLabに関する特定のドキュメントはありません。なぜなら、アカウントで作成された任意のGitLab CodeStar Connectionを使用するだけだからです。（[2023/12/28](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)）`[AWS Built]`
- **AWS Proton**はCodeStar Connectionsを直接継承します。GitLabに関する特定のドキュメントはありません。なぜなら、アカウントで作成された任意のGitLab CodeStar Connectionを使用するだけだからです。（[2023/12/28](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)）`[AWS Built]`
- **AWS CodeBuild** - [GitLab.com、Self-ManagedおよびDedicated向け - ドキュメントタブをここでクリックしてください](https://docs.aws.amazon.com/codebuild/latest/userguide/create-project-console.html#create-project-console-source)。（[2024/03/26](https://aws.amazon.com/about-aws/whats-new/2024/03/aws-codebuild-gitlab-gitlab-self-managed/)）`[AWS Built]`

ドキュメントと参照:

- [GitLab CodeStar ConnectionをGitLab.comプロジェクトに作成する](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab-managed.html)
- [AWS CodeStar ConnectionをGitLab Self-ManagedまたはGitLab Dedicated向けに作成する](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab-managed.html)（AWSからのインターネットIngressを許可するか、VPC接続を使用する必要があります）

#### AWS CodePipelineインテグレーション {#aws-codepipeline-integrations}

[AWS CodePipelineインテグレーション](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab.html) \- GitLabをCodePipelineのCodeStar Connectionsソースとして使用することで、追加のAWSサービスインテグレーションが利用可能です。（[2023/12/28](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)）`[AWS Built]`

AWSサービスのうち、AWS CodePipelineインテグレーションによってサポートされているもの:

- **Amazon SageMaker MLOps Projects**は（[ここに記載されているように](https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-projects-walkthrough-3rdgit.html#sagemaker-proejcts-walkthrough-connect-3rdgit)）CodePipelineを介して作成されます。GitLabに関する特定のドキュメントはありません。アカウントで作成された任意のGitLab CodeStar Connectionを使用するだけだからです。（[2023/12/28](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)）`[AWS Built]`

ドキュメントと参照:

- [GitLab CodePipelineインテグレーションをGitLab.comプロジェクトに作成する](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab-managed.html)
- [AWS CodePipelineインテグレーションをGitLab Self-ManagedまたはGitLab Dedicated向けに作成する](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab-managed.html)（AWSからのインターネットIngressを許可するか、VPC接続を使用する必要があります）

#### CodeStar Connectionsが有効な、GitLabではまだサポートされていないAWSサービス {#codestar-connections-enabled-aws-services-that-are-not-yet-supported-for-gitlab}

- **AWS CloudFormation**のパブリック拡張機能の公開 - まだサポートされていません。`[AWS Built]`
- **Amazon CodeGuru Reviewerリポジトリ** \- まだサポートされていません。`[AWS Built]`
- **AWS App Runner** \- まだサポートされていません。`[AWS Built]`

#### AWSサービスにおけるカスタムGitLabインテグレーション {#custom-gitlab-integration-in-aws-services}

- **Amazon SageMakerノートブック**は[Git clone URLによってGitリポジトリを指定することを許可し](https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-git-resource.html)、シークレットの設定を可能にします。そのため、GitLabは設定可能です。（[2023/12/28](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)）`[AWS Configuration]`
- **AWS Amplify** \- AWS Amplifyチームによって設計された[Gitインテグレーションメカニズムを使用します](https://docs.aws.amazon.com/amplify/latest/userguide/getting-started.html)。`[AWS Built]`
- **AWS Glueノートブックジョブ**は、GitLabリポジトリURLと、「ジョブ」レベルでのパーソナルアクセストークン（PAT）認証をサポートします。（[2022/10/03](https://aws.amazon.com/about-aws/whats-new/2022/10/aws-glue-git-integration/)）[GitLabの設定に関するAWSドキュメント](https://docs.aws.amazon.com/glue/latest/dg/edit-job-add-source-control-integration.html) `[AWS Configuration]`

#### その他のSCMインテグレーションオプション {#other-scm-integration-options}

- [GitLabプッシュミラーからAWS CodeCommitへ](../../../user/project/repository/mirror/push.md#set-up-a-push-mirror-from-gitlab-to-aws-codecommit)の回避策は、GitLabリポジトリがCodePipeline SCMトリガーを活用できるようにします。GitLabは、すでにCodePipeline向けにS3およびコンテナトリガーを活用できます。この回避策により、ドキュメント化されて以来CodePipelineの機能が有効になりました。（2020/06/06）`[GitLab Configuration]`

継続的デプロイ（CD）固有の、利用可能なインテグレーションについては、以下の[CDおよびオペレーションインテグレーション](#cd-and-operations-integrations)を参照してください。

### CIインテグレーション {#ci-integrations}

- **キー、IAM、OIDC/JWTを使用してGitLab RunnerからAWSサービスに認証する直接CIインテグレーション**
- **GitLab CIを使用したAmazon CodeGuru Reviewer CIワークフロー** \- 実施可能ですが、まだドキュメント化されていません。`[AWS Solution]` `[CI Solution]`
- [GitLab CIを使用したAmazon CodeGuru Secure Scanning](https://docs.aws.amazon.com/codeguru/latest/security-ug/get-started-gitlab.html)（[2022/06/13](https://aws.amazon.com/about-aws/whats-new/2023/06/amazon-codeguru-security-available-preview/)）`[AWS Solution]` `[CI Solution]`

### CDおよびオペレーションインテグレーション {#cd-and-operations-integrations}

- **AWS CodeDeploy Integration** \- 以前にSCMインテグレーションで説明したCodePipelineサポートを通じて。この機能により、GitLabは[AWSにおける高度なデプロイサブシステムのこのリスト](https://docs.aws.amazon.com/codepipeline/latest/userguide/integrations-action-type.html#integrations-deploy)とインターフェースできます。（[2023/12/28](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)）`[AWS Built]`
- **AWS SAM Pipelines** - [GitLab向けパイプラインサポート](https://aws.amazon.com/about-aws/whats-new/2021/07/simplify-ci-cd-configuration-serverless-applications-your-favorite-ci-cd-system-public-preview/)。（2021/7/31）
- [アプリケーションデプロイ向けにAmazon Elastic Kubernetes Serviceクラスターを統合](../../../user/infrastructure/clusters/connect/new_eks_cluster.md)。`[GitLab Built]`
- [GitLabがビルドアーティファクトをCodePipelineによって監視されているS3の場所にプッシュ](https://docs.aws.amazon.com/codepipeline/latest/userguide/pipelines-about-starting.html#change-detection-methods) `[AWS Built]`
- [GitLabがコンテナをCodePipelineによって監視されているAWS ECRにプッシュ](https://docs.aws.amazon.com/codepipeline/latest/userguide/pipelines-about-starting.html#change-detection-methods) `[AWS Built]`
- [GitLab.comのコンテナレジストリを、プルスルーキャッシュルールを介してAWS ECRのアップストリームレジストリとして使用する](https://docs.aws.amazon.com/AmazonECR/latest/userguide/pull-through-cache-creating-rule.html) [設定チュートリアル](tutorials/aws_ecr_pull_through_cache.md) `[AWS Built]`

## 特定の開発フレームワークまたはエコシステムの開発とデプロイのためのエンドツーエンドソリューション {#end-to-end-solutions-for-development-and-deployment-of-specific-development-frameworks-or-ecosystems}

一般的に、ソリューションは開発フレームワークのエンドツーエンド機能を示します。これは、すべての関連するインテグレーション手法を活用して、GitLabとAWSを一緒に使用することによる最大の価値を示すものです。

### Serverless {#serverless}

- [エンタープライズDevOpsブループリント: Serverless Framework Apps on AWS](https://gitlab.com/guided-explorations/aws/serverless/serverless-framework-aws) \- 動作する例コードとチュートリアル。`[GitLab Solution]` `[CI Solution]`
  - [チュートリアル: Serverless FrameworkのAWSへのデプロイとGitLab Serverless SASTスキャン](https://gitlab.com/guided-explorations/aws/serverless/serverless-framework-aws/-/blob/master/TUTORIAL.md) `[GitLab Solution]` `[CI Solution]`
  - [チュートリアル: GitLabセキュリティポリシー承認ルールとマネージドDevOps環境を使用した安全なServerless Framework開発](https://gitlab.com/guided-explorations/aws/serverless/serverless-framework-aws/-/blob/prod/TUTORIAL2-SecurityAndManagedEnvs.md?ref_type=heads) `[GitLab Solution]` `[CI Solution]`

### Terraform {#terraform}

- [エンタープライズDevOpsブループリント: TerraformのAWSへのデプロイ](https://gitlab.com/guided-explorations/aws/terraform/terraform-web-server-cluster)
  - [チュートリアル: TerraformのAWSへのデプロイとGitLab IaC SASTスキャン](https://gitlab.com/guided-explorations/aws/terraform/terraform-web-server-cluster/-/blob/prod/TUTORIAL.md) `[GitLab Solution]` `[CI Solution]`
  - [GitLabセキュリティポリシー承認ルールとマネージドDevOps環境を使用したTerraformのAWSへのデプロイ](https://gitlab.com/guided-explorations/aws/terraform/terraform-web-server-cluster/-/blob/prod/TUTORIAL2-SecurityAndManagedEnvs.md) `[GitLab Solution]` `[CI Solution]`

### CloudFormation {#cloudformation}

[CloudFormationの開発とデプロイ（GitLabライフサイクルマネージドDevOps環境の動作コードを使用）](https://gitlab.com/guided-explorations/aws/cloudformation-deploy) `[GitLab Solution]` `[CI Solution]`

### CDK {#cdk}

- [AWS CDKを使用したGitLabパイプラインにおけるクロスアカウントデプロイの構築](https://aws.amazon.com/blogs/apn/building-cross-account-deployment-in-gitlab-pipelines-using-aws-cdk/) `[AWS Solution]` `[CI Solution]`

### .NET on AWS {#net-on-aws}

- [.NET Framework 4.x RunnerをAWSでスケールするための動作する例コード](https://gitlab.com/guided-explorations/aws/dotnet-aws-toolkit) `[GitLab Solution]` `[CI Solution]`
- [コードのビデオウォークスルーと.NET Framework 4.xプロジェクトをビルドする](https://www.youtube.com/watch?v=_4r79ZLmDuo) `[GitLab Solution]` `[CI Solution]`

## GitLabとAWSのシステム間インテグレーション {#system-to-system-integration-of-gitlab-and-aws}

AWS Identity Provider（IDP）は、GitLabへの認証を設定できます。また、GitLabはAWSアカウントへのIDPとして機能することもできます。

GitLab.comのトップレベルグループは「ネームスペース」とも呼ばれ、会社名にちなんで名前を付けることがGitLab.comで組織のテナントを設定するための最初のステップです。ネームスペースは、SSOのような特殊な機能のために設定でき、その後IDPをGitLabに統合します。

### GitLabとAWS間のユーザー認証と認可 {#user-authentication-and-authorization-between-gitlab-and-aws}

- [GitLab.comグループ向けSAML SSO](../../../user/group/saml_sso/_index.md) `[GitLab Configuration]` - GitLab.comのみ
- [GitLabとLDAPを統合](../../../administration/auth/ldap/_index.md) `[GitLab Configuration]` - GitLab Self-Managedのみ

### Runnerワークロードの認証と認可インテグレーション {#runner-workload-authentication-and-authorization-integration}

- [OpenIDとJWT認証を使用したRunnerジョブ認証](../../../ci/cloud_services/aws/_index.md)。`[GitLab Built]`
  - [GitLabとAWS間のOpenID Connectを設定する](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws) `[GitLab Solution]` `[CI Solution]`
  - [OIDCと、GitLabおよびECSを使用したマルチアカウントデプロイ](https://gitlab.com/guided-explorations/aws/oidc-and-multi-account-deployment-with-ecs) `[GitLab Solution]` `[CI Solution]`

## AWSにデプロイされたGitLabインフラストラクチャワークロード {#gitlab-infrastructure-workloads-deployed-on-aws}

GitLabは最大500ユーザーまで単一のボックスにデプロイできますが、50,000などの非常に多くのユーザー向けに水平にスケールすると、複雑な多層プラットフォームに拡張され、AWSへのデプロイから恩恵を受けます。GitLabは、AWSサービスによって支えられている場合、サポートされ、定期的にテストされています。GitLabは、従来のスケーリング向けにEC2に、およびクラウドネイティブハイブリッド実装のAWS Amazon Elastic Kubernetes Serviceにデプロイ可能です。特定のサービスレイヤーは、Gitに共通するワークロードの形状（およびGitプロセスがそのワークロードの多様性を処理する方法に共通する）のためコンテナクラスターに配置できないため、ハイブリッドと呼ばれます。

### GitLabインスタンスコンピューティングおよびオペレーションインテグレーション {#gitlab-instance-compute--operations-integration}

- GitLab Self-ManagedをAWSにインストール
  - [GitLabをデプロイする際に使用できるAWSサービス](gitlab_instance_on_aws.md)
  - GitLab単一EC2インスタンス。`[GitLab Built]`
    - [5シートのAWSマーケットプレイスサブスクリプションを使用する](gitlab_single_box_on_aws.md#marketplace-subscription)
    - [準備されたAMIを使用する](gitlab_single_box_on_aws.md#official-gitlab-releases-as-amis) \- エンタープライズ版には独自のライセンスを使用します。
  - AWS Amazon Elastic Kubernetes ServiceとPaaSでスケールされたGitLabクラウドネイティブハイブリッド。`[GitLab Built]`
    - [GitLab Environment Toolkit（GET）を使用する](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) - `[GitLab Solution]`
  - GitLabインスタンスがAWS EC2およびPaaSでスケールされました。`[GitLab Built]`
    - [GitLab Environment Toolkit（GET）を使用する](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) - `[GitLab Solution]`
- [Amazon Managed Grafana](https://docs.aws.amazon.com/grafana/latest/userguide/gitlab-AMG-datasource.html)（GitLab Self-Managed Prometheusメトリクス向け）。`[AWS Built]`

### AWSコンピューティング上のRunner {#gitlab-runner-on-aws-compute}

- [GitLab Runner Autoscaler](https://docs.gitlab.com/runner/runner_autoscale/) \- Runnerチームによって構築されたコアテクノロジー。`[GitLab Built]`
- [Runner Infrastructure Toolkit（GRIT）](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit) \- Runnerチームが管理するマネージドInfrastructure as Code。GitLab Runner Autoscalerのようなものをデプロイするために必要です。`[GitLab Built]`
- [AWS EC2でのRunnerのオートスケール](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/)。`[GitLab Built]`
- [AWS EC2 ASG向けのGitLab HAスケーリングRunnerベンディングマシン](https://gitlab.com/guided-explorations/aws/gitlab-runner-autoscaling-aws-asg/)。`[GitLab Solution]`
  - Runnerベンディングマシンのトレーニングリソース。
- [GitLab Amazon Elastic Kubernetes Service Fargate Runner](https://gitlab.com/guided-explorations/aws/eks-runner-configs/gitlab-runner-eks-fargate/-/blob/main/README.md)。`[GitLab Solution]`
