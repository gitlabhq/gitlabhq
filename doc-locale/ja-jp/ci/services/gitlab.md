---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabをマイクロサービスとして使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

多くのアプリケーションはJSON APIにアクセスする必要があるため、アプリケーションテストもAPIにアクセスする必要がある場合があります。次の例では、GitLab APIへのテストアクセスを許可するために、GitLabをマイクロサービスとして使用する方法を示します。

1. DockerまたはKubernetes executorで[Runner](../runners/_index.md)を設定します。
1. `.gitlab-ci.yml`に以下を追加します:

   ```yaml
   services:
     - name: gitlab/gitlab-ce:latest
       alias: gitlab

   variables:
     GITLAB_HTTPS: "false"             # ensure that plain http works
     GITLAB_ROOT_PASSWORD: "password"  # to access the api with user root:password
   ```

{{< alert type="note" >}}

GitLab UIで設定された変数は、サービスコンテナに渡されません。詳細については、[GitLab CI/CD変数](../variables/_index.md)を参照してください。

{{< /alert >}}

次に、`script`ファイルの`.gitlab-ci.yml`セクションのコマンドは、`http://gitlab/api/v4`でAPIにアクセスできます。

`gitlab`が`Host`に使用される理由の詳細については、[サービスをジョブにリンクする方法](../docker/using_docker_images.md#extended-docker-configuration-options)を参照してください。

[Docker Hub](https://hub.docker.com/u/gitlab)で利用可能な他のDockerイメージを使用することもできます。

`gitlab`イメージは、環境変数を受け入れることができます。詳細については、[Linuxパッケージ](../../install/_index.md)ドキュメントを参照してください。
