---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CD から AWS へのデプロイ
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、AWSへのデプロイに必要なライブラリとツールを含む Dockerイメージを提供します。CI/CD パイプラインでこれらのイメージを参照できます。

GitLab.com を使用し、[Amazon Elastic Container Service](https://aws.amazon.com/ecs/) (ECS) にデプロイする場合は、[ECS へのデプロイ](ecs/deploy_to_aws_ecs.md)についてお読みください。

{{< alert type="note" >}}

自分でデプロイメントを設定することに慣れていて、AWS の認証情報を取得する必要がある場合は、[ID トークンと OpenID Connect](../cloud_services/aws/_index.md)の使用を検討してください。IDトークンは、CI/CD変数に認証情報を保存するよりもSecureですが、このページのガイダンスでは機能しません。

{{< /alert >}}

## GitLab を AWS で認証する

GitLab CI/CD を使用して AWS に接続するには、認証する必要があります。認証を設定したら、CI/CD を Configure してデプロイできます。

1. AWS アカウントにサインオンします。
1. [IAM ユーザー](https://console.aws.amazon.com/iam/home#/home)を作成します。
1. ユーザーを選択して、詳細にアクセスします。**\[セキュリティ認証情報] > \[新しいアクセスキーの作成]**に移動します。
1. **アクセスキー ID**と**シークレットアクセスキー**をメモしておきます。
1. GitLabプロジェクトで、**\[設定] > \[CI/CD]**に移動します。次の[CI/CD変数](../variables/_index.md)を設定します:

   | 環境変数名      | 値                   |
   |:-------------------------------|:------------------------|
   | `AWS_ACCESS_KEY_ID`            | アクセスキー ID。     |
   | `AWS_SECRET_ACCESS_KEY`        | シークレットアクセスキー。 |
   | `AWS_DEFAULT_REGION`           | リージョンコード。使用する予定の AWS サービスが選択したリージョンで[利用可能であることを確認](https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/)することをお勧めします。 |

1. 変数は[デフォルトで保護されています](../variables/_index.md#protect-a-cicd-variable)。保護されていないブランチまたは tag で GitLab CI/CD を使用するには、**\[変数を保護する]**チェックボックスをオフにします。

## イメージを使用して AWS コマンドを実行する

イメージに[AWS コマンドラインインターフェース（CLI）](https://aws.amazon.com/cli/)が含まれている場合は、プロジェクトの `.gitlab-ci.yml` ファイルでイメージを参照できます。次に、CI/CD ジョブで `aws` コマンドを実行できます。

次に例を示します:

```yaml
deploy:
  stage: deploy
  image: registry.gitlab.com/gitlab-org/cloud-deploy/aws-base:latest
  script:
    - aws s3 ...
    - aws create-deployment ...
  environment: production
```

GitLab は、AWS CLI を含む Docker イメージを提供します。

- イメージは、GitLab コンテナレジストリでホストされています。最新のイメージは `registry.gitlab.com/gitlab-org/cloud-deploy/aws-base:latest` です。
- [イメージは GitLab リポジトリに保存されます](https://gitlab.com/gitlab-org/cloud-deploy/-/tree/master/aws)。

または、[Amazon Elastic Container Registry (ECR)](https://aws.amazon.com/ecr/)イメージを使用することもできます。[ECR リポジトリにイメージをプッシュする方法](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html)について説明します。

サードパーティ製レジストリのイメージも使用できます。

## アプリケーションを ECS にデプロイする

[Amazon ECS](https://aws.amazon.com/ecs/)クラスターへのアプリケーションのデプロイを自動化できます。

前提要件:

- [GitLab で AWS を認証します](#authenticate-gitlab-with-aws)。
- Amazon ECS でクラスターを作成します。
- ECS サービスや Amazon RDS のデータベースなど、関連コンポーネントを作成します。
- `containerDefinitions[].name`属性の値が、ターゲットの ECS サービスで定義されている`Container name`と同じである ECS タスク定義を作成します。タスク定義は、次のいずれかにすることができます。
  - ECS 内の既存のタスク定義。
  - GitLabプロジェクトの JSON ファイル。[AWS ドキュメントのテンプレート](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-task-definition.html#task-definition-template)を使用して、プロジェクトにファイルを保存します。たとえば、`<project-root>/ci/aws/task-definition.json`などです。

ECS クラスターにデプロイするには:

1. GitLabプロジェクトで、**\[設定] > \[CI/CD]**に移動します。次の[CI/CD変数](../variables/_index.md)を設定します:これらの名前は、[Amazon ECS ダッシュボード](https://console.aws.amazon.com/ecs/home)でターゲットクラスターを選択すると確認できます。

   | 環境変数名      | 値                   |
   |:-------------------------------|:------------------------|
   | `CI_AWS_ECS_CLUSTER`           | デプロイのターゲットにしている AWS ECS クラスターの名前。 |
   | `CI_AWS_ECS_SERVICE`           | AWS ECS クラスターに紐付けられた、ターゲットサービスの名前。この変数が適切な環境 (`production`、`staging`、`review/*`) にスコープされていることを確認してください。 |
   | `CI_AWS_ECS_TASK_DEFINITION`   | タスク定義が ECS にある場合は、サービスに紐付けられたタスク定義の名前。 |
   | `CI_AWS_ECS_TASK_DEFINITION_FILE` | タスク定義が GitLab の JSON ファイルである場合は、パスを含むファイル名。たとえば、`ci/aws/my_task_definition.json`などです。JSON ファイル内のタスク定義の名前が、ECS 内の既存のタスク定義と同じ名前である場合、CI/CD の実行時に新しいリビジョンが作成されます。それ以外の場合は、完全に新しいタスク定義がリビジョン 1 から作成されます。 |

   {{< alert type="warning" >}}

   `CI_AWS_ECS_TASK_DEFINITION_FILE`と`CI_AWS_ECS_TASK_DEFINITION`の両方を定義した場合、`CI_AWS_ECS_TASK_DEFINITION_FILE`が優先されます。

   {{< /alert >}}

1. このテンプレートを`.gitlab-ci.yml`に含めます:

   ```yaml
   include:
     - template: AWS/Deploy-ECS.gitlab-ci.yml
   ```

   `AWS/Deploy-ECS` テンプレートは GitLab に付属しており、[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/AWS/Deploy-ECS.gitlab-ci.yml)で利用できます。

1. 更新した`.gitlab-ci.yml`をコミットして、プロジェクトのリポジトリにプッシュします。

アプリケーションの Docker イメージがリビルドされ、GitLab コンテナレジストリにプッシュされます。イメージがプライベートレジストリにある場合は、タスク定義が [`repositoryCredentials`属性で Configure されている](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/private-auth.html)ことを確認してください。

ターゲットのタスク定義が新しい Docker イメージの場所で更新され、その結果、新しいリビジョンが ECS で作成されます。

最後に、AWS ECS サービスがタスク定義の新しいリビジョンで更新され、クラスターがアプリケーションの最新バージョンをプルするようになります。

{{< alert type="note" >}}

ECS デプロイジョブは、ロールアウトが完了するまで待機してから終了します。この動作を無効にするには、`CI_AWS_ECS_WAIT_FOR_ROLLOUT_COMPLETE_DISABLED`を空でない値に設定します。

{{< /alert >}}

{{< alert type="warning" >}}

[`AWS/Deploy-ECS.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/AWS/Deploy-ECS.gitlab-ci.yml) テンプレートには、[`Jobs/Build.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Build.gitlab-ci.yml) と [`Jobs/Deploy/ECS.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy/ECS.gitlab-ci.yml) の 2 つのテンプレートが含まれています。これらのテンプレートを単独で含めないでください。`AWS/Deploy-ECS.gitlab-ci.yml` テンプレートのみを含めます。これらの他のテンプレートは、メインテンプレートでのみ使用するようにデザインされています。予告なしに移動または変更される可能性があります。また、これらのテンプレートのジョブ名も変更される可能性があります。名前が変更されたときにオーバーライドが機能しなくなるため、独自のパイプラインでこれらのジョブ名を上書きしないでください。

{{< /alert >}}

## アプリケーションを EC2 にデプロイする

GitLab は、Amazon EC2 へのデプロイを支援するために、`AWS/CF-Provision-and-Deploy-EC2`というテンプレートを提供します。

関連する JSON オブジェクトを Configure し、テンプレートを使用すると、パイプラインは次のようになります。

1. **スタックを作成**:インフラストラクチャは、[AWS CloudFormation](https://aws.amazon.com/cloudformation/) API を使用してプロビジョニングされます。
1. **S3 バケットにプッシュ**:ビルドを実行すると、アーティファクトが作成されます。アーティファクトは、[AWS S3](https://aws.amazon.com/s3/) バケットにプッシュされます。
1. **EC2 にデプロイ**:コンテンツは、次の図に示すように、[AWS EC2](https://aws.amazon.com/ec2/) インスタンスにデプロイされます。

![インフラストラクチャのプロビジョニング、S3 へのアーティファクトのプッシュ、EC2 へのデプロイの手順など、CF-Provision-and-Deploy-EC2 パイプラインを示します。](../img/cf_ec2_diagram_v13_5.png)

### テンプレートと JSON を Configure する

EC2 にデプロイするには、次の手順を実行します。

1. スタックの JSON を作成します。[AWS テンプレート](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html)を使用します。
1. S3 にプッシュする JSON を作成します。次の詳細を含めます。

   ```json
   {
     "applicationName": "string",
     "source": "string",
     "s3Location": "s3://your/bucket/project_built_file...]"
   }
   ```

   `source`は、`build` ジョブがアプリケーションをビルドした場所です。ビルドは [`artifacts:paths`](../yaml/_index.md#artifactspaths) に保存されます。

1. EC2 にデプロイする JSON を作成します。[AWS テンプレート](https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html)を使用します。
1. JSON オブジェクトをパイプラインからアクセスできるようにします:
   - これらの JSON オブジェクトをリポジトリに保存する場合は、オブジェクトを 3 つの個別のファイルとして保存します。

     `.gitlab-ci.yml` ファイルで、プロジェクトルートからのファイルパスを指す[CI/CD変数](../variables/_index.md)を追加します。たとえば、JSON ファイルが `<project_root>/aws` フォルダーにある場合:

     ```yaml
     variables:
       CI_AWS_CF_CREATE_STACK_FILE: 'aws/cf_create_stack.json'
       CI_AWS_S3_PUSH_FILE: 'aws/s3_push.json'
       CI_AWS_EC2_DEPLOYMENT_FILE: 'aws/create_deployment.json'
     ```

   - これらの JSON オブジェクトをリポジトリに保存しない場合は、各オブジェクトをプロジェクト設定で個別の[ファイルタイプの CI/CD変数](../variables/_index.md#use-file-type-cicd-variables)として追加します。上記と同じ変数名を使用します。

1. `.gitlab-ci.yml` ファイルで、スタックの名前の CI/CD変数を作成します。次に例を示します:

   ```yaml
   variables:
     CI_AWS_CF_STACK_NAME: 'YourStackName'
   ```

1. `.gitlab-ci.yml` ファイルで、CI テンプレートを追加します:

   ```yaml
   include:
     - template: AWS/CF-Provision-and-Deploy-EC2.gitlab-ci.yml
   ```

1. パイプラインを実行します。

   - AWS CloudFormation スタックは、`CI_AWS_CF_CREATE_STACK_FILE`変数の内容に基づいて作成されます。スタックが既に存在する場合、この手順はスキップされますが、それが属する`provision` ジョブは引き続き実行されます。
   - ビルドされたアプリケーションは S3 バケットにプッシュされ、関連する JSON オブジェクトの内容に基づいて EC2 インスタンスにデプロイされます。EC2 へのデプロイが完了または失敗すると、デプロイジョブが完了します。

## トラブルシューティング

### エラー `'ascii' codec can't encode character '\uxxxx'`

このエラーは、Cloud Deploy イメージで使用される `aws-cli` ユーティリティからの応答に Unicode 文字が含まれている場合に発生する可能性があります。提供する Cloud Deploy イメージにはロケールが定義されておらず、デフォルトで ASCII を使用します。このエラーを解決するには、次の CI/CD変数を追加します。

```yaml
variables:
  LANG: "UTF-8"
```
