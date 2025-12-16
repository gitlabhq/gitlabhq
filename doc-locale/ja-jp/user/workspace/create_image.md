---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabで作成する任意のワークスペースをサポートするために、カスタムワークスペースイメージを作成します。
title: 'チュートリアル: 任意のユーザーIDをサポートするカスタムワークスペースイメージを作成する'
---

<!-- vale gitlab_base.FutureTense = NO -->

このチュートリアルでは、プロジェクトのニーズを満たすカスタムワークスペースイメージを作成する方法を説明します。完了すると、GitLabで作成する任意の[ワークスペース](_index.md)でこのカスタムイメージを使用できます。

任意のユーザーIDをサポートするカスタムワークスペースイメージを作成するには:

1. [Dockerfileを作成する](#create-a-dockerfile)。
1. [カスタムワークスペースイメージをビルドする](#build-the-custom-workspace-image)。
1. [カスタムワークスペースイメージをGitLabコンテナレジストリにプッシュする](#push-the-custom-workspace-image-to-the-gitlab-container-registry)。
1. [GitLabでカスタムワークスペースイメージを使用する](#use-the-custom-workspace-image-in-gitlab)。

## はじめる前 {#before-you-begin}

以下が必要です:

- GitLabコンテナレジストリにコンテナイメージを作成してプッシュする権限を持つGitLabアカウント。
- Dockerがローカルマシンにインストールされていること。

## Dockerfileを作成 {#create-a-dockerfile}

GitLabコンテナレジストリから[ワークスペースベースイメージ](_index.md#workspace-base-image)（`registry.gitlab.com/gitlab-org/gitlab-build-images:workspaces-base`）を起点とするDockerfileを作成します:

```Dockerfile
FROM registry.gitlab.com/gitlab-org/gitlab-build-images:workspaces-base

# Install additional tools your project needs
RUN sudo apt-get update && \
    sudo apt-get install -y tree && \
    sudo rm -rf /var/lib/apt/lists/*

# Install project-specific tools using mise
# For example, install Node.js version 20
RUN mise install node@20 && \
    mise use node@20

# Install global packages
RUN npm install -g @angular/cli

# Set up your project environment
ENV NODE_ENV=development

# Create project directories
RUN mkdir -p /home/gitlab-workspaces/projects
```

これらの手順は、プロジェクトの特定の要件に基づいてカスタマイズしてください。次に、カスタムワークスペースイメージをビルドします。

## カスタムワークスペースイメージをビルドする {#build-the-custom-workspace-image}

Dockerfileが完成したら、カスタムワークスペースイメージをビルドする準備が完了です:

1. Dockerfileを作成したディレクトリで、次のコマンドを実行します:

   ```shell
   docker build -t my-gitlab-workspace .
   ```

   これは、インターネット接続とシステムの速度によっては、数分かかる場合があります。

1. ビルドプロセスが完了したら、イメージをローカルでテストします:

   ```shell
   docker run -ti my-gitlab-workspace sh
   ```

`gitlab-workspaces`ユーザーとしてコマンドを実行する権限が付与されているはずです。完璧です。イメージがローカルで動作しています。次に、GitLabで使用できるようにします。

## カスタムワークスペースイメージをGitLabコンテナレジストリにプッシュする {#push-the-custom-workspace-image-to-the-gitlab-container-registry}

プロジェクトで使用するために、カスタムワークスペースイメージをGitLabコンテナレジストリにプッシュします:

1. GitLabアカウントにサインインする:

   ```shell
   docker login registry.gitlab.com
   ```

1. GitLabコンテナレジストリのURLでイメージにタグ付けします:

   ```shell
   docker tag my-gitlab-workspace registry.gitlab.com/your-namespace/my-gitlab-workspace:latest
   ```

   `your-namespace`は、実際のGitLabネームスペースに置き換えてください。

1. イメージをGitLabコンテナレジストリにプッシュします:

   ```shell
   docker push registry.gitlab.com/your-namespace/my-gitlab-workspace:latest
   ```

   このアップロードは、インターネット接続速度によっては、しばらく時間がかかる場合があります。

よくできました。これで、カスタムワークスペースイメージはGitLabコンテナレジストリに安全に保存され、使用できるようになりました。

## GitLabでカスタムワークスペースイメージを使用する {#use-the-custom-workspace-image-in-gitlab}

最後のステップでは、カスタムワークスペースイメージを使用するようにプロジェクトを設定します:

1. プロジェクトの`.devfile.yaml`でコンテナイメージを更新します:

   ```yaml
   schemaVersion: 2.2.0
   components:
     - name: tooling-container
       attributes:
         gl/inject-editor: true
       container:
         image: registry.gitlab.com/your-namespace/my-gitlab-workspace:latest
   ```

   `your-namespace`は、実際のGitLabネームスペースに置き換えてください。

おつかれさまでした。任意のユーザーIDをサポートするカスタムワークスペースイメージの作成と構成が正常に完了しました。このカスタムイメージは、GitLabで作成する任意の[ワークスペース](_index.md)で使用できるようになりました。

## 関連トピック {#related-topics}

- [ワークスペースのトラブルシューティング](workspaces_troubleshooting.md)
