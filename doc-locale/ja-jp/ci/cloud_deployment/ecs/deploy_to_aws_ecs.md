---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabプロジェクトをAmazon Amazon Elastic Container Serviceにデプロイします。アプリケーションをコンテナ化し、継続的デプロイ、レビューアプリ、セキュリティテストを設定します。
title: Amazon Elastic Container Service (ECS) にデプロイします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このステップごとのガイドでは、GitLab.comでホストされているプロジェクトをAmazon [Elastic Container Service（ECS）](https://aws.amazon.com/ecs/)にデプロイするのに役立ちます。

このガイドでは、まずAWSコンソールを使用して、ECSクラスタリングを手動で作成します。GitLabテンプレートから作成したシンプルなアプリケーションを作成し、デプロイします。

これらの手順は、GitLab.comとGitLab Self-Managedインスタンスの両方で機能します。独自の[Runnerが設定されている](../../runners/_index.md)ことを確認してください。

## 前提要件 {#prerequisites}

- [AWS](https://repost.aws/knowledge-center/create-and-activate-aws-account)アカウント。既存のAWSアカウントでサインインするか、新しいアカウントを作成します。
- このガイドでは、[`us-east-2`リージョン](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html)にインフラストラクチャを作成します。どのリージョンでも使用できますが、開始後に変更しないでください。

## AWSでインフラストラクチャと最初のデプロイを作成します {#create-an-infrastructure-and-initial-deployment-on-aws}

GitLabからアプリケーションをデプロイするには、最初にAWSでインフラストラクチャと最初のデプロイを作成する必要があります。これには、[ECSクラスタ](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html)や、[ECSタスク定義](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html) 、[ECSサービス](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html)、コンテナ化されたアプリケーションイメージなどの関連コンポーネントが含まれます。

最初の手順として、プロジェクトテンプレートからデモアプリケーションを作成します。

### テンプレートから新しいプロジェクトを作成する {#create-a-new-project-from-a-template}

GitLabプロジェクトテンプレートを使用して開始します。名前が示すように、これらのプロジェクトは、定評のあるフレームワーク上に構築された、必要最小限のアプリケーションを提供します。

1. GitLabの左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **テンプレートから作成**を選択して、Ruby on Rails、Spring、またはNodeJS Expressプロジェクトから選択できます。このガイドでは、Ruby on Railsテンプレートを使用します。
1. プロジェクトに名前を付けます。この例では、`ecs-demo`という名前が付けられています。[GitLab Ultimateプラン](https://about.gitlab.com/pricing/)で利用できる機能を活用できるように、公開してください。
1. **プロジェクトを作成**を選択します。

デモプロジェクトを作成したので、アプリケーションをコンテナ化し、レジストリにプッシュする必要があります。

### コンテナ化されたアプリケーションイメージをGitLabレジストリにプッシュする {#push-a-containerized-application-image-to-gitlab-container-registry}

[ECS](https://aws.amazon.com/ecs/)はコンテナオーケストレーションサービスであるため、インフラストラクチャのビルド中に、コンテナ化されたアプリケーションイメージを提供する必要があります。そのためには、GitLab [Auto DevOps](../../../topics/autodevops/stages.md#auto-build)と[Container Registry](../../../user/packages/container_registry/_index.md)を使用します。

1. 左側のサイドバーで、**検索または移動先**を選択して、`ecs-demo`プロジェクトを見つけます。
1. **CI/CDを設定**を選択します。`.gitlab-ci.yml`の作成フォームが表示されます。
1. 次のコンテンツを空の`.gitlab-ci.yml`にコピーして貼り付けます。これにより、ECSへの継続的なデプロイのためのパイプラインが定義されます。

   ```yaml
   include:
     - template: AWS/Deploy-ECS.gitlab-ci.yml
   ```

1. **Commit Changes**（変更をコミット）を選択します。新しいパイプラインが自動的にトリガーされます。このパイプラインでは、`build`ジョブがアプリケーションをコンテナ化し、イメージを[GitLab container registry](../../../user/packages/container_registry/_index.md)にプッシュします。

1. **デプロイ** > **Container Registry**（コンテナレジストリ）にアクセスします。アプリケーションイメージがプッシュされたことを確認してください。

   ![GitLabコンテナレジストリ内のコンテナ化されたアプリケーションイメージ。](img/registry_v13_10.png)

これで、AWSからプルできるコンテナ化されたアプリケーションイメージができました。次に、このアプリケーションイメージがAWSでどのように使用されるかの仕様を定義します。

ECSクラスタがまだ接続されていないため、`production_ecs`ジョブが失敗します。これは後で修正できます。

### ECSタスク定義を作成する {#create-an-ecs-task-definition}

[ECSタスク定義](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)は、アプリケーションイメージが[ECSサービス](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html)によってどのように起動されるかに関する仕様です。

1. **ECS** > **Task Definitions**（タスク定義）に移動します（[AWSコンソール](https://aws.amazon.com/)）。
1. **Create new Task Definition**（新しいタスク定義の作成）を選択します。

   ![「新しいタスク定義を作成」ボタンがあるタスク定義ページ。](img/ecs-task-definitions_v13_10.png)

1. 起動タイプとして**EC2**を選択します。**Next Step**（次のステップ）を選択します。
1. **Task Definition Name**（タスク定義名）に`ecs_demo`を設定します。
1. **Task Size**（タスクサイズ） > **Task memory**（タスクメモリ）および**Task CPU**（タスクCPU）に`512`を設定します。
1. **Container Definitions**（コンテナ定義） > **Add container**（コンテナの追加）を選択します。これにより、コンテナ登録フォームが開きます。
1. **Container name**（コンテナ名）に`web`を設定します。
1. **イメージ**に`registry.gitlab.com/<your-namespace>/ecs-demo/master:latest`を設定します。または、[GitLabコンテナレジストリページ](#push-a-containerized-application-image-to-gitlab-container-registry)からイメージパスをコピーして貼り付けることもできます。

   ![コンテナ名とイメージフィールドが完了しました。](img/container-name_v13_10.png)

1. ポートマッピングを追加します。**Host Port**（ホストポート）に`80`、**Container port**（コンテナポート）に`5000`を設定します。

   ![ポートマッピングフィールドが完了しました。](img/container-port-mapping_v13_10.png)

1. **作成**を選択します。

これで、初期タスク定義ができました。次に、アプリケーションイメージを実行するための実際のインフラストラクチャを作成します。

### ECSクラスタを作成する {#create-an-ecs-cluster}

[ECSクラスタ](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html)は、[ECSサービス](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html)の仮想グループです。また、計算リソースとしてEC2またはFargateに関連付けられています。

1. **ECS** > **Clusters**（クラスタ）に移動します（[AWSコンソール](https://aws.amazon.com/)）。
1. **Create Cluster**（クラスタの作成）を選択します。
1. クラスタテンプレートとして**EC2 Linux + Networking**（EC2 Linux + ネットワーキング）を選択します。**Next Step**（次のステップ）を選択します。
1. **Cluster Name**（クラスタ名）に`ecs-demo`を設定します。
1. **Networking**（ネットワーキング）でデフォルトの[VPC](https://aws.amazon.com/vpc/?vpc-blogs.sort-by=item.additionalFields.createdDate&vpc-blogs.sort-order=desc)を選択します。既存のVPCがない場合は、そのままにして新しいVPCを作成できます。
1. VPCの利用可能なすべてのサブネットを**Subnets**（サブネット）に設定します。
1. **作成**を選択します。
1. ECSクラスタが正常に作成されたことを確認してください。

   ![すべてのインスタンスが実行されている状態で、ECSクラスタが正常に作成されました。](img/ecs-launch-status_v13_10.png)

次のステップで、ECSサービスをECSクラスタに登録できます。

次の点に注意してください:

- オプションで、作成フォームでSSHペアを設定できます。これにより、デバッグのためにEC2インスタンスにSSHできます。
- 既存のVPCを選択しない場合、デフォルトで新しいVPCが作成されます。アカウントで許可されているインターネットゲートウェイの最大数に達すると、エラーが発生する可能性があります。
- クラスタにはEC2インスタンスが必要なので、[インスタンスタイプに応じて](https://aws.amazon.com/ec2/pricing/on-demand/)コストがかかります。

### ECSサービスを作成する {#create-an-ecs-service}

[ECSサービス](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html)は、[ECSタスク定義](#create-an-ecs-task-definition)に基づいてアプリケーションコンテナを作成するデーモンです。

1. **ECS** > **Clusters**（クラスタ） > **ecs-demo** > **サービス**に移動します（[AWSコンソール](https://aws.amazon.com/)）。
1. **デプロイ**を選択します。これにより、サービス作成フォームが開きます。
1. **Launch Type**（起動タイプ）で`EC2`を選択します。
1. **Task definition**（タスク定義）に`ecs_demo`を設定します。これは、[以前に作成したタスク定義](#create-an-ecs-task-definition)に対応します。
1. **サービス名**に`ecs_demo`を設定します。
1. **Desired tasks**（必要なタスク）に`1`を設定します。

   ![すべての入力が完了したサービスページ。](img/service-parameter_v13_10.png)

1. **デプロイ**を選択します。
1. 作成されたサービスがアクティブであることを確認してください。

   ![タスクを実行しているアクティブなサービス。](img/service-running_v13_10.png)

AWSコンソールのユーザーインターフェースは随時変更されます。手順に関連するコンポーネントが見つからない場合は、最も近いものを選択してください。

### デモアプリケーションを表示する {#view-the-demo-application}

これで、デモアプリケーションにインターネットからアクセスできるようになりました。

1. **EC2** > **インスタンス**に移動します（[AWSコンソール](https://aws.amazon.com/)）。
1. `ECS Instance`で検索して、[ECSクラスタが作成した](#create-an-ecs-cluster)対応するEC2インスタンスを見つけます。
1. EC2インスタンスのIDを選択します。これにより、インスタンスの詳細ページが表示されます。
1. **Public IPv4 address**（パブリックIPv4アドレス）をコピーして、ブラウザに貼り付けます。これで、デモアプリケーションが実行されているのがわかります。

   ![ブラウザで実行されているデモアプリケーション。](img/view-running-app_v13_10.png)

このガイドでは、HTTPS/SSLは**not**（構成されていません）。HTTP経由でのみアプリケーションにアクセスできます（例：`http://<ec2-ipv4-address>`）。

## GitLabから継続的なデプロイを設定する {#set-up-continuous-deployment-from-gitlab}

ECSでアプリケーションを実行しているので、GitLabから継続的なデプロイを設定できます。

### デプロイ担当者として新しいIAMユーザーを作成する {#create-a-new-iam-user-as-a-deployer}

GitLabが以前に作成したECSクラスタ、サービス、およびタスク定義にアクセスするには、AWSにデプロイ担当者ユーザーを作成する必要があります:

1. **IAM** > **ユーザー**に移動します（[AWSコンソール](https://aws.amazon.com/)）。
1. **ユーザーの追加**を選択します。
1. **User name**に`ecs_demo`を設定します。
1. **Programmatic access**チェックボックスをオンにします。**次へを選択します**: 権限
1. **Set permissions**（権限の設定）で`Attach existing policies directly`を選択します。
1. ポリシーリストから`AmazonECS_FullAccess`を選択します。**次へを選択します: タグ**と**次へ: レビュー**。

   ![選択された`AmazonECS_FullAccess`ポリシー。](img/ecs-policy_v13_10.png)

1. **ユーザーの作成**を選択します。
1. 作成したユーザーの**Access key ID**（アクセスキーID）と**Secret access key**（シークレットアクセスキー）をメモしておきます。

{{< alert type="note" >}}

シークレットアクセスキーを公開されている場所に共有しないでください。安全な場所に保存する必要があります。

{{< /alert >}}

### パイプラインジョブがECSにアクセスできるようにGitLabで認証情報を設定する {#setup-credentials-in-gitlab-to-let-pipeline-jobs-access-to-ecs}

[GitLab CICD変数を設定](../../variables/_index.md)でアクセス情報を登録できます。これらの変数はパイプラインジョブに挿入され、ECSAPIにアクセスできます。

1. 左側のサイドバーで、**検索または移動先**を選択して、`ecs-demo`プロジェクトを見つけます。
1. **設定** > **CI/CD** > **変数**に移動します。
1. **Add Variable**（変数の追加）を選択し、次のキー/バリューペアを設定します。

   | キー                          | 値                                 | メモ |
   |------------------------------|---------------------------------------|------|
   | `AWS_ACCESS_KEY_ID`          | `<Access key ID of the deployer>`     | `aws`コマンドラインインターフェースを認証するため。 |
   | `AWS_SECRET_ACCESS_KEY`      | `<Secret access key of the deployer>` | `aws`コマンドラインインターフェースを認証するため。 |
   | `AWS_DEFAULT_REGION`         | `us-east-2`                           | `aws`コマンドラインインターフェースを認証するため。 |
   | `CI_AWS_ECS_CLUSTER`         | `ecs-demo`                            | ECSクラスタは`production_ecs`ジョブによってアクセスされます。 |
   | `CI_AWS_ECS_SERVICE`         | `ecs_demo`                            | クラスタのECSサービスは、`production_ecs`ジョブによって更新されます。この変数のスコープが適切な環境（`production`、`staging`、`review/*`）に設定されていることを確認してください。 |
   | `CI_AWS_ECS_TASK_DEFINITION` | `ecs_demo`                            | ECSタスク定義は、`production_ecs`ジョブによって更新されます。 |

### デモアプリケーションを変更する {#make-a-change-to-the-demo-application}

プロジェクト内のファイルを変更し、ECS上のデモアプリケーションに反映されているかどうかを確認します:

1. 左側のサイドバーで、**検索または移動先**を選択して、`ecs-demo`プロジェクトを見つけます。
1. `app/views/welcome/index.html.erb`ファイルを開きます。
1. **編集**を選択します。
1. テキストを`You're on ECS!`に変更します。
1. **Commit Changes**（変更をコミット）を選択します。これにより、新しいパイプラインが自動的にトリガーされます。完了するまで待ちます。
1. [ECSクラスタで実行中のアプリケーションにアクセスする](#view-the-demo-application)。次のように表示されます:

   ![確認メッセージ付きでECSで実行されているアプリケーション。](img/view-running-app-2_v13_10.png)

おつかれさまでした。ECSへの継続的なデプロイを正常に設定しました。

{{< alert type="note" >}}

ECSデプロイジョブは、ロールアウトが完了するまで待機してから終了します。この動作を無効にするには、`CI_AWS_ECS_WAIT_FOR_ROLLOUT_COMPLETE_DISABLED`を空でない値に設定します。

{{< /alert >}}

## レビューアプリを設定する {#set-up-review-apps}

ECSでレビューアプリを使用するには:

1. 新しい[サービス](#create-an-ecs-service)をセットアップします。
1. `CI_AWS_ECS_SERVICE`変数を使用して、名前を設定します。
1. 環境スコープを`review/*`に設定します。

このサービスはすべてのレビューアプリで共有されているため、一度にデプロイできるレビューアプリは1つだけです。

## セキュリティテストを設定する {#set-up-security-testing}

### SASTを構成する {#configure-sast}

ECSで[SAST](../../../user/application_security/sast/_index.md)を使用するには、次の内容を`.gitlab-ci.yml`ファイルに追加します:

```yaml
include:
   - template: Jobs/SAST.gitlab-ci.yml
```

詳細および設定オプションについては、[SASTドキュメント](../../../user/application_security/sast/_index.md#configuration)を参照してください。

### DASTを構成する {#configure-dast}

[DAST](../../../user/application_security/dast/_index.md)をデフォルト以外のブランチで使用するには、[レビューアプリを設定](#set-up-review-apps)し、次の内容を`.gitlab-ci.yml`ファイルに追加します:

```yaml
include:
  - template: Security/DAST.gitlab-ci.yml
```

デフォルトブランチでDASTを使用するには:

1. 新しい[サービス](#create-an-ecs-service)をセットアップします。このサービスは、一時的なDAST環境をデプロイするために使用されます。
1. `CI_AWS_ECS_SERVICE`変数を使用して、名前を設定します。
1. `dast-default`環境にスコープを設定します。
1. 次の内容を`.gitlab-ci.yml`ファイルに追加します:

```yaml
include:
  - template: Security/DAST.gitlab-ci.yml
  - template: Jobs/DAST-Default-Branch-Deploy.gitlab-ci.yml
```

詳細および設定オプションについては、[DASTドキュメント](../../../user/application_security/dast/_index.md)を参照してください。

## さらに詳しく {#further-reading}

- クラウドへの継続的なデプロイの詳細については、[クラウドデプロイ](../_index.md)を参照してください。
- プロジェクトでDevSecOpsをすばやく設定する場合は、[Auto DevOps](../../../topics/autodevops/_index.md)を参照してください。
- 本番環境レベルの環境をすばやく設定する場合は、[5 Minute Production App](https://gitlab.com/gitlab-org/5-minute-production-app/deploy-template/-/blob/master/README.md)を参照してください。
