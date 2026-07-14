---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: GitLabとAWSのインテグレーションソリューションのインデックス。
title: 'チュートリアル: GitLab.comプロジェクトへの認証済みアクセス用にAWS ECRプルスルーキャッシュを設定する'
---

1. <https://console.aws.amazon.com/ecr/>にアクセスして、Amazon ECRコンソールを開きます。
1. ナビゲーションバーのRegionで、プライベートレジストリ設定を行うリージョンを選択します。
1. ナビゲーションペインで、Private registry、Pull through cacheを選択します。
1. Pull through cache configurationページで、Add ruleを選択します。

ステップ1: Specify a sourceページのRegistryで、GitLab Container Registryを選択し、Nextを選択します。

ステップ2: Configure authenticationページのUpstream credentialsでは、GitLabコンテナレジストリの認証情報をAWS Secrets Managerシークレットに保存する必要があります。既存のシークレットを指定するか、Amazon ECRコンソールを使用して新しいシークレットを作成できます。

既存のシークレットを使用するには、Use an existing AWS secretを選択します。Secret nameでは、ドロップダウンを使用して既存のシークレットを選択し、Nextを選択します。Secrets Managerコンソールを使用したSecrets Managerシークレットの作成方法の詳細については、アップストリームリポジトリの認証情報をAWS Secrets Managerに保存するを参照してください。

> [!note]
> AWS Management Consoleには、名前にecr-pullthroughcache/プレフィックスが付いたSecrets Managerシークレットのみが表示されます。そのシークレットは、プルスルーキャッシュルールを作成するアカウントおよびリージョンに存在している必要があります。

新しいシークレットを作成するには、Create an AWS secretを選択し、以下の手順を実行してからNextを選択します。

Secret nameには、シークレットを識別しやすい名前を指定します。Secret nameは、1～512文字のUnicode文字で指定する必要があります。

GitLab Container Registry usernameには、GitLabコンテナレジストリのユーザー名を指定します。

GitLab Container Registry access tokenには、GitLabコンテナレジストリのアクセストークンを指定します。最小限の権限の原則に従うため、ゲストロールと`read_registry`スコープのみを付与したグループアクセストークンを作成します。

ステップ3: Specify a destinationページのAmazon ECR repository prefixには、ソースの公開レジストリからプルしたイメージをキャッシュする際に使用するリポジトリネームスペースを指定し、Nextを選択します。

デフォルトではネームスペースが入力されていますが、カスタムネームスペースを指定することもできます。

ステップ4: Review and createページで、プルスルーキャッシュルールの設定を確認し、Createを選択します。

作成するプルスルーキャッシュごとに、前のステップを繰り返します。プルスルーキャッシュルールは、リージョンごとに個別に作成されます。

ECRプルスルーキャッシュルールが正常に作成されたことを確認するには、AWS CLIで次のコマンドを実行してルールを検証します:

```shell
aws ecr validate-pull-through-cache-rule \
     --ecr-repository-prefix ecr-public \
     --region us-east-2
```

ECRプルスルーキャッシュルールによってGitLab.comアップストリームレジストリへのプルスルーアクセスが提供されていることを確認するには、`docker pull`コマンドを実行して検証します:

```shell
docker pull aws_account_id.dkr.ecr.region.amazonaws.com/{destination-namespace e.g. gitlab-ef1b}/{path to Gitlab.com project/group where image is hosted}/image_name:tag
```

`docker pull`コマンドの例:

```shell
docker pull aws_account_id.dkr.ecr.region.amazonaws.com/gitlab-ef1b/guided-explorations/ci-components/working-code-examples/kaniko-component-multiarch-build:latest
```
