---
stage: Application Security Testing
group: Composition Analysis
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'チュートリアル: Dockerコンテナの脆弱性をスキャンする'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[コンテナスキャン](../../user/application_security/container_scanning/_index.md)を使用して、[コンテナレジストリ](../../user/packages/container_registry/_index.md)に保存されているコンテナイメージの脆弱性をチェックできます。

コンテナスキャンの設定は、プロジェクトのパイプラインの設定に追加されます。このチュートリアルでは、次のことを行います:

1. [新しいプロジェクト](#create-a-new-project)を作成します。
1. [`Dockerfile`ファイル](#add-a-dockerfile-to-new-project)をプロジェクトに追加します。この`Dockerfile`には、Dockerイメージを作成するために必要な最小限の設定が含まれています。
1. 新しいプロジェクトの[パイプライン設定](#create-pipeline-configuration)を作成して、`Dockerfile`からDockerイメージを作成し、Dockerイメージをコンテナレジストリにプッシュし、脆弱性がないかDockerイメージをスキャンします。
1. [レポートされた脆弱性](#check-for-reported-vulnerabilities)を確認します。
1. [Dockerイメージを更新](#update-the-docker-image)し、更新されたイメージをスキャンします。

## 新しいプロジェクトを作成 {#create-a-new-project}

新しいプロジェクトを作成するには

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. **プロジェクト名**に、`Tutorial container scanning project`を入力します。
1. **プロジェクトのURL**で、プロジェクトのネームスペースを選択します。
1. **プロジェクトを作成**を選択します。

## 新しいプロジェクトに`Dockerfile`を追加 {#add-a-dockerfile-to-new-project}

コンテナスキャンが機能するものを提供するには、最小限の設定で`Dockerfile`を作成します:

1. `Tutorial container scanning project`プロジェクトで、{{< icon name="plus" >}} > **新しいファイル**を選択します。
1. ファイル名`Dockerfile`を入力し、ファイルのコンテンツを次のように指定します:

   ```Dockerfile
   FROM hello-world:latest
   ```

この`Dockerfile`から作成されたDockerイメージは、[`hello-world`](https://hub.docker.com/_/hello-world) Dockerイメージに基づいています。

1. **変更をコミットする**を選択します。

## パイプラインの設定を作成 {#create-pipeline-configuration}

これで、パイプライン設定を作成する準備ができました。パイプラインの設定:

1. `Dockerfile`ファイルからDockerイメージをビルドし、Dockerイメージをコンテナレジストリにプッシュします。`build-image`ジョブは[Docker-in-Docker](../../ci/docker/using_docker_build.md)を[CI/CDサービス](../../ci/services/_index.md)として使用して、Dockerイメージをビルドします。
1. `Container-Scanning.gitlab-ci.yml`テンプレートを含めて、コンテナレジストリに保存されているDockerイメージをスキャンします。

パイプライン設定を作成するには:

1. プロジェクトのルートディレクトリで、{{< icon name="plus" >}} > **新しいファイル**を選択します。
1. ファイル名`.gitlab-ci.yml`を入力し、ファイルのコンテンツを次のように指定します:

   ```yaml
   include:
     - template: Jobs/Container-Scanning.gitlab-ci.yml

   container_scanning:
     variables:
       CS_IMAGE: $CI_REGISTRY_IMAGE/tutorial-image

   build-image:
     image: docker:24.0.2-cli
     stage: build
     services:
       - docker:24.0.2-dind
     script:
       - docker build --tag $CI_REGISTRY_IMAGE/tutorial-image --file Dockerfile .
       - docker login --username gitlab-ci-token --password $CI_JOB_TOKEN $CI_REGISTRY
       - docker push $CI_REGISTRY_IMAGE/tutorial-image
   ```

1. **変更をコミットする**を選択します。

ほぼ完了です。ファイルをコミットすると、新しいパイプラインがこの設定で開始されます。完了したら、スキャンの結果を確認できます。

## レポートされた脆弱性を確認 {#check-for-reported-vulnerabilities}

スキャンの脆弱性は、スキャンを実行したパイプラインにあります。レポートされた脆弱性を確認するには:

1. **CI/CD** > **パイプライン**を選択し、最新のパイプラインを選択します。このパイプラインは、`container_scanning`というジョブで構成されている必要があります。`test`ステージ。
1. `container_scanning`ジョブが成功した場合は、**セキュリティ**タブを選択します。脆弱性が見つかった場合は、そのページに一覧表示されます。

## Dockerイメージを更新 {#update-the-docker-image}

`hello-world:latest`に基づくDockerイメージは、脆弱性を示す可能性は低いです。脆弱性を報告するスキャンの例:

1. プロジェクトのルートディレクトリで、既存の`Dockerfile`ファイルを選択します。
1. **編集**を選択します。
1. `FROM hello-world:latest`を、[`FROM`](https://docs.docker.com/reference/dockerfile/#from)命令の別のDockerイメージに置き換えます。コンテナスキャンを示す最適なDockerイメージは次のとおりです:
   - オペレーティングシステムのパッケージ。たとえば、Debian、Ubuntu、Alpine、またはRed Hatから。
   - プログラミング言語のパッケージ。たとえば、NPMパッケージまたはPythonパッケージ。
1. **変更をコミットする**を選択します。

ファイルへの変更をコミットすると、この更新された`Dockerfile`で新しいパイプラインが開始されます。完了したら、新しいスキャンの結果を確認できます。
