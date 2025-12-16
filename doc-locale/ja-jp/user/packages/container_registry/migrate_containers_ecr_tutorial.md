---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: Amazon ECRからGitLabにコンテナイメージを移行する'
description: Amazon Elastic Container RegistryからGitLabにコンテナイメージの一括移行を自動化するためのチュートリアル。
---

レジストリ間でコンテナイメージを移行するには、手動で行うと時間がかかる場合があります。このチュートリアルでは、Amazon Elastic Container Registry（ECR）からGitLabコンテナレジストリへのコンテナイメージの一括移行を自動化するために、CI/CDパイプラインをセットアップする方法について説明します。

ECRからコンテナイメージを移行するには、次の手順に従います:

1. [AWS権限を設定する](#configure-aws-permissions)
1. [UIでAWS認証情報を変数として追加します](#add-aws-credentials-as-variables-in-the-ui)
1. [移行パイプラインを作成します](#create-the-migration-pipeline)
1. [移行を実行して検証します](#run-and-verify-the-migration)

すべてをまとめると、`.gitlab-ci.yml`は、このチュートリアルの最後に記載されている[サンプル設定](#example-gitlab-ciyml-configuration)に似たものになります。

## はじめる前 {#before-you-begin}

以下が必要です:

- 少なくともGitLabプロジェクトのメンテナーロール
- IAMユーザーを作成する権限を持つAWSアカウントへのアクセス
- AWSアカウントID
- ECRリポジトリが配置されているAWSリージョン
- GitLabコンテナレジストリに十分なストレージ容量

## AWS権限を設定する {#configure-aws-permissions}

AWS IAMで、ECRへの読み取り専用アクセス権を持つ新しいポリシーとユーザーを作成します:

1. AWS Management Consoleで、IAMに移動します。
1. 新しいポリシーを作成します:

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "ecr:GetAuthorizationToken",
                   "ecr:BatchCheckLayerAvailability",
                   "ecr:GetDownloadUrlForLayer",
                   "ecr:DescribeRepositories",
                   "ecr:ListImages",
                   "ecr:DescribeImages",
                   "ecr:BatchGetImage"
               ],
               "Resource": "*"
           }
       ]
   }
   ```

1. 新しいIAMユーザーを作成し、ポリシーをアタッチします。
1. IAMユーザーのアクセスキーを生成して保存します。

## UIでAWS認証情報を変数として追加します {#add-aws-credentials-as-variables-in-the-ui}

必要なAWS認証情報を、GitLabプロジェクトの変数として設定します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. **変数を追加する**を選択し、次を追加します:
   - `AWS_ACCOUNT_ID`: AWSアカウント番号。
   - `AWS_DEFAULT_REGION`: ECRリージョン。たとえば`us-east-1`などです。
   - `AWS_ACCESS_KEY_ID`: IAMユーザーからのアクセスキーID。
     - **Mask variable**（変数をマスクする） を選択します。
   - `AWS_SECRET_ACCESS_KEY`: IAMユーザーからのシークレットアクセスキー。
     - **Mask variable**（変数をマスクする） を選択します。

## 移行パイプラインを作成します {#create-the-migration-pipeline}

次の設定で、リポジトリに新しい`.gitlab-ci.yml`ファイルを作成します:

### イメージとサービスを設定する {#set-image-and-service}

コンテナ操作を処理するには、Docker-in-Dockerを使用します:

```yaml
image: docker:20.10
services:
  - docker:20.10-dind
```

### パイプライン変数を定義する {#define-pipeline-variables}

パイプラインに必要な変数を設定します:

```yaml
variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: ""
  BULK_MIGRATE: "true"
```

### 移行ジョブを設定する {#configure-the-migration-job}

転送を処理する移行ジョブを作成します:

```yaml
migration:
  stage: deploy
  script:
    # Install required tools
    - apk add --no-cache aws-cli jq

    # Verify AWS credentials
    - aws sts get-caller-identity

    # Log in to registries
    - aws ecr get-login-password | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
    - docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY}

    # Get list of ECR repositories
    - REPOS=$(aws ecr describe-repositories --query 'repositories[*].repositoryName' --output text)

    # Process each repository
    - |
      for repo in $REPOS; do
        echo "Processing repository: $repo"

        # Get all tags for this repository
        TAGS=$(aws ecr describe-images --repository-name $repo --query 'imageDetails[*].imageTags[]' --output text)

        # Process each tag
        for tag in $TAGS; do
          echo "Processing tag: $tag"

          # Pull image from ECR
          docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${repo}:${tag}

          # Tag for GitLab registry
          docker tag ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${repo}:${tag} ${CI_REGISTRY_IMAGE}/${repo}:${tag}

          # Push to GitLab
          docker push ${CI_REGISTRY_IMAGE}/${repo}:${tag}
        done
      done
```

## 移行を実行して検証します {#run-and-verify-the-migration}

パイプラインのセットアップ後:

1. `.gitlab-ci.yml`ファイルをコミットしてリポジトリにプッシュします。
1. **CI/CD** > **パイプライン**に移動して、移行の進捗状況を監視します。
1. 完了後、移行を検証します:
   - **パッケージとレジストリ > コンテナレジストリ**に移動します。
   - すべてのリポジトリとタグが存在することを確認します。
   - 移行されたイメージをいくつかプルしてテストします。

## `.gitlab-ci.yml`の設定例 {#example-gitlab-ciyml-configuration}

上記の手順をすべて実行すると、`.gitlab-ci.yml`ファイルは次のようになります:

```yaml
image: docker:20.10
services:
  - docker:20.10-dind

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: ""
  BULK_MIGRATE: "true"

migration:
  stage: deploy
  script:
    # Install required tools
    - apk add --no-cache aws-cli jq

    # Verify AWS credentials
    - aws sts get-caller-identity

    # Log in to registries
    - aws ecr get-login-password | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
    - docker login -u ${CI_REGISTRY_USER} -p ${CI_REGISTRY_PASSWORD} ${CI_REGISTRY}

    # Get list of ECR repositories
    - REPOS=$(aws ecr describe-repositories --query 'repositories[*].repositoryName' --output text)

    # Process each repository
    - |
      for repo in $REPOS; do
        echo "Processing repository: $repo"

        # Get all tags for this repository
        TAGS=$(aws ecr describe-images --repository-name $repo --query 'imageDetails[*].imageTags[]' --output text)

        # Process each tag
        for tag in $TAGS; do
          echo "Processing tag: $tag"

          # Pull image from ECR
          docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${repo}:${tag}

          # Tag for GitLab registry
          docker tag ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${repo}:${tag} ${CI_REGISTRY_IMAGE}/${repo}:${tag}

          # Push to GitLab
          docker push ${CI_REGISTRY_IMAGE}/${repo}:${tag}
        done
      done
  rules:
    - if: $BULK_MIGRATE == "true"
```
