---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab CI/CDからAWS（EC2およびECSを含む）へのデプロイは、GitLabが提供するDockerイメージとCloudFormationテンプレートを使用して行います。
title: GitLab CI/CDからAWSにデプロイする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabでは、AWSへのデプロイに必要なライブラリとツールを含むDockerイメージを提供しています。CI/CDパイプラインでこれらのイメージを参照できます。

GitLab.comを使用して、[Amazon Elastic Container Service](https://aws.amazon.com/ecs/) （ECS）にデプロイする場合は、[ECSへのデプロイ](ecs/deploy_to_aws_ecs.md)についての説明をお読みください。

{{< alert type="note" >}}

自分でデプロイを設定することに慣れていて、AWSの認証情報を取得する必要がある場合は、[IDトークンとOpenID Connect](../cloud_services/aws/_index.md)の使用を検討してください。IDトークンの使用は、CI/CD変数に認証情報を保存することよりも安全ですが、このページのガイダンスには当てはまりません。

{{< /alert >}}

## AWSでGitLabを認証する {#authenticate-gitlab-with-aws}

GitLab CI/CDを使用してAWSに接続するには、認証する必要があります。認証を設定したら、CI/CDを設定してデプロイできます。

1. AWSアカウントにサインインします。
1. [IAMユーザー](https://console.aws.amazon.com/iam/home#/home)を作成します。
1. ユーザーを選択して、その詳細にアクセスします。**Security credentials**（セキュリティ認証情報） > **Create a new access key**（新しいアクセスキーを作成）に移動します。
1. **Access key ID**（アクセスキーID）と**Secret access key**（シークレットアクセスキー）をメモしておきます。
1. GitLabプロジェクトで、**設定** > **CI/CD**に移動します。次の[CI/CD変数](../variables/_index.md)を設定します:

   | 環境変数名 | 値 |
   |:--------------------------|:------|
   | `AWS_ACCESS_KEY_ID`       | アクセスキーID。 |
   | `AWS_SECRET_ACCESS_KEY`   | シークレットアクセスキー。 |
   | `AWS_DEFAULT_REGION`      | リージョンコード。使用する予定のAWSサービスが[選択したリージョンで利用可能である](https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/)ことを確認することをお勧めします。 |

1. 変数は[デフォルトで保護されています](../variables/_index.md#protect-a-cicd-variable)。保護されていないブランチまたはタグでGitLab CI/CDを使用するには、**変数の保護**チェックボックスをオフにします。

## イメージを使用してAWSコマンドを実行する {#use-an-image-to-run-aws-commands}

イメージに[AWS CLI](https://aws.amazon.com/cli/)が含まれている場合は、プロジェクトの`.gitlab-ci.yml`ファイルでイメージを参照できます。次に、CI/CDジョブで`aws`コマンドを実行できます。

例: 

```yaml
deploy:
  stage: deploy
  image: registry.gitlab.com/gitlab-org/cloud-deploy/aws-base:latest
  script:
    - aws s3 ...
    - aws create-deployment ...
  environment: production
```

GitLabでは、AWS CLIを含むDockerイメージを提供しています:

- イメージは、GitLabコンテナレジストリでホスティングされています。最新のイメージは`registry.gitlab.com/gitlab-org/cloud-deploy/aws-base:latest`です。
- [イメージはGitLabリポジトリに保存されます](https://gitlab.com/gitlab-org/cloud-deploy/-/tree/master/aws)。

または、[Amazon Elastic Container Registry（ECR）](https://aws.amazon.com/ecr/)イメージを使用することもできます。[ECRリポジトリにイメージをプッシュする方法を確認してください](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html)。

サードパーティ製レジストリのイメージも使用できます。

## アプリケーションをECSにデプロイする {#deploy-your-application-to-ecs}

[Amazon ECS](https://aws.amazon.com/ecs/)クラスターへのアプリケーションのデプロイを自動化できます。

前提要件: 

- [GitLabでAWSを認証します](#authenticate-gitlab-with-aws)。
- Amazon ECSでクラスターを作成します。
- ECSサービスやAmazon RDSのデータベースなど、関連コンポーネントを作成します。
- `containerDefinitions[].name`属性の値が、ターゲットのECSサービスで定義されている`Container name`と同じであるECSタスク定義を作成します。タスク定義としては、次のいずれかが可能です:
  - ECS内の既存のタスク定義。
  - GitLabプロジェクトのJSONファイル。[AWSドキュメントのテンプレート](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-task-definition.html#task-definition-template)を使用して、プロジェクトにファイルを保存します。たとえば、`<project-root>/ci/aws/task-definition.json`などです。

ECSクラスターにデプロイするには、次のようにします:

1. GitLabプロジェクトで、**設定** > **CI/CD**に移動します。次の[CI/CD変数](../variables/_index.md)を設定します。これらの名前は、[Amazon ECSダッシュボード](https://console.aws.amazon.com/ecs/home)でターゲットクラスターを選択すると確認できます。

   | 環境変数名         | 値 |
   |:----------------------------------|:------|
   | `CI_AWS_ECS_CLUSTER`              | デプロイのターゲットにしているAWS ECSクラスターの名前。 |
   | `CI_AWS_ECS_SERVICE`              | AWS ECSクラスターに紐付けられた、ターゲットサービスの名前。この変数のスコープが適切な環境（`production`、`staging`、`review/*`）に設定されていることを確認してください。 |
   | `CI_AWS_ECS_TASK_DEFINITION`      | タスク定義がECSにある場合、サービスに紐付けられたタスク定義の名前。 |
   | `CI_AWS_ECS_TASK_DEFINITION_FILE` | タスク定義がGitLabのJSONファイルである場合、パスを含むファイル名。たとえば`ci/aws/my_task_definition.json`などです。JSONファイル内のタスク定義の名前が、ECS内の既存のタスク定義と同じ名前である場合、CI/CDの実行時に新しいリビジョンが作成されます。それ以外の場合は、完全に新しいタスク定義がリビジョン1から作成されます。 |

   {{< alert type="warning" >}}

   `CI_AWS_ECS_TASK_DEFINITION_FILE`と`CI_AWS_ECS_TASK_DEFINITION`の両方を定義した場合、`CI_AWS_ECS_TASK_DEFINITION_FILE`が優先されます。

   {{< /alert >}}

1. このテンプレートを`.gitlab-ci.yml`に含めます:

   ```yaml
   include:
     - template: AWS/Deploy-ECS.gitlab-ci.yml
   ```

   `AWS/Deploy-ECS`テンプレートはGitLabに付属しており、[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/AWS/Deploy-ECS.gitlab-ci.yml)で利用できます。

1. 更新した`.gitlab-ci.yml`をコミットして、プロジェクトのリポジトリにプッシュします。

アプリケーションのDockerイメージが再ビルドされ、GitLabコンテナレジストリにプッシュされます。イメージがプライベートレジストリにある場合は、タスク定義の[設定に`repositoryCredentials`属性が含まれている](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/private-auth.html)ことを確認してください。

ターゲットのタスク定義が新しいDockerイメージの場所で更新され、その結果、新しいリビジョンがECSで作成されます。

最後に、AWS ECSサービスがタスク定義の新しいリビジョンで更新され、クラスターがアプリケーションの最新バージョンをプルするようになります。

{{< alert type="note" >}}

ECSデプロイジョブは、ロールアウトが完了するまで待機してから終了します。この動作を無効にするには、`CI_AWS_ECS_WAIT_FOR_ROLLOUT_COMPLETE_DISABLED`を空でない値に設定します。

{{< /alert >}}

{{< alert type="warning" >}}

[`AWS/Deploy-ECS.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/AWS/Deploy-ECS.gitlab-ci.yml)テンプレートには、[`Jobs/Build.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Build.gitlab-ci.yml)と[`Jobs/Deploy/ECS.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy/ECS.gitlab-ci.yml)の2つのテンプレートが含まれています。これらのテンプレートを単独で含めないようにしてください。`AWS/Deploy-ECS.gitlab-ci.yml`テンプレートだけを含めます。これらの他のテンプレートは、メインテンプレートでのみ使用するように設計されています。予告なしに移動または変更される可能性があります。また、これらのテンプレートのジョブ名も変更される可能性があります。名前が変更されたときにオーバーライドが機能しなくなるため、独自のパイプラインでこれらのジョブ名を上書きしないでください。

{{< /alert >}}

## アプリケーションをEC2にデプロイする {#deploy-your-application-to-ec2}

GitLabは、Amazon EC2へのデプロイを支援するために、`AWS/CF-Provision-and-Deploy-EC2`というテンプレートを提供します。

関連するJSONオブジェクトを設定して、テンプレートを使用する場合、パイプラインは次のようになります:

1. **Creates the stack**（スタックを作成します）: インフラストラクチャは、[AWS CloudFormation](https://aws.amazon.com/cloudformation/) APIを使用してプロビジョニングされます。
1. **Pushes to an S3 bucket**（S3バケットにプッシュします）: ビルドを実行すると、アーティファクトが作成されます。そのアーティファクトが[AWS S3](https://aws.amazon.com/s3/)バケットにプッシュされます。
1. **Deploys to EC2**（EC2にデプロイします）: 次の図に示すように、コンテンツが[AWS EC2](https://aws.amazon.com/ec2/)インスタンスにデプロイされます:

![インフラストラクチャのプロビジョニング、S3へのアーティファクトのプッシュ、EC2へのデプロイの手順など、CF-Provision-and-Deploy-EC2パイプラインを示します。](img/cf_ec2_diagram_v13_5.png)

### テンプレートとJSONを設定する {#configure-the-template-and-json}

EC2にデプロイするには、次の手順を実行します。

1. スタックのJSONを作成します。[AWSテンプレート](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html)を使用します。
1. S3にプッシュするJSONを作成します。次の詳細を含めます。

   ```json
   {
     "applicationName": "string",
     "source": "string",
     "s3Location": "s3://your/bucket/project_built_file...]"
   }
   ```

   `source`は、`build`ジョブがアプリケーションをビルドした場所です。ビルドは[`artifacts:paths`](../yaml/_index.md#artifactspaths)に保存されます。

1. EC2にデプロイするJSONを作成します。[AWSテンプレート](https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html)を使用します。
1. JSONオブジェクトをパイプラインからアクセスできるようにします:
   - これらのJSONオブジェクトをリポジトリに保存する場合は、オブジェクトを3つの個別のファイルとして保存します。

     `.gitlab-ci.yml`ファイルで、プロジェクトルートからの相対ファイルパスを指す[CI/CD変数](../variables/_index.md)を追加します。たとえば、JSONファイルが`<project_root>/aws`フォルダーにある場合は、次のようにします:

     ```yaml
     variables:
       CI_AWS_CF_CREATE_STACK_FILE: 'aws/cf_create_stack.json'
       CI_AWS_S3_PUSH_FILE: 'aws/s3_push.json'
       CI_AWS_EC2_DEPLOYMENT_FILE: 'aws/create_deployment.json'
     ```

   - これらのJSONオブジェクトをリポジトリに保存しない場合は、プロジェクト設定で各オブジェクトを個別の[ファイルタイプCI/CD変数](../variables/_index.md#use-file-type-cicd-variables)として追加します。前と同じ変数名を使用してください。

1. `.gitlab-ci.yml`ファイルで、スタックの名前のCI/CD変数を作成します。例: 

   ```yaml
   variables:
     CI_AWS_CF_STACK_NAME: 'YourStackName'
   ```

1. `.gitlab-ci.yml`ファイルで、CIテンプレートを追加します:

   ```yaml
   include:
     - template: AWS/CF-Provision-and-Deploy-EC2.gitlab-ci.yml
   ```

1. パイプラインを実行します。

   - AWS CloudFormationスタックは、`CI_AWS_CF_CREATE_STACK_FILE`変数の内容に基づいて作成されます。スタックが既に存在する場合、この手順はスキップされますが、それが属する`provision`ジョブは引き続き実行されます。
   - ビルドされたアプリケーションはS3バケットにプッシュされ、関連するJSONオブジェクトの内容に基づいてEC2インスタンスにデプロイされます。EC2へのデプロイが完了または失敗すると、デプロイジョブが完了します。

## トラブルシューティング {#troubleshooting}

### エラー`'ascii' codec can't encode character '\uxxxx'` {#error-ascii-codec-cant-encode-character-uxxxx}

このエラーは、Cloud Deployイメージで使用される`aws-cli`ユーティリティからの応答にUnicode文字が含まれている場合に発生する可能性があります。Cloud Deployイメージには、定義されたロケールがなく、デフォルトではASCIIを使用します。このエラーを解決するには、次のCI/CD変数を追加します:

```yaml
variables:
  LANG: "UTF-8"
```
