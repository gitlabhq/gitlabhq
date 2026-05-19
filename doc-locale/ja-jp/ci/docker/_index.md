---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dockerインテグレーション
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Docker](https://www.docker.com)をCI/CDワークフローに組み込むには、主に2つの方法があります:

- [CI/CDジョブを実行](using_docker_images.md)し、Dockerコンテナに格納します。

  Dockerコンテナで実行されるアプリケーションをテスト、ビルド、または公開するジョブを作成します。例えば、Docker HubからNodeイメージを使用して、必要なすべてのNode依存関係を持つコンテナでジョブを実行します。

- [Docker Build](using_docker_build.md)または[BuildKit](using_buildkit.md)を使用してDockerイメージをビルドします。

  Dockerイメージをビルドし、コンテナレジストリに公開するジョブを作成します。BuildKitは、rootlessビルドを含む複数のアプローチを提供します。
