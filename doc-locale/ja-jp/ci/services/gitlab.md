---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabをマイクロサービスとして使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

多くのアプリケーションがJSON APIにアクセスする必要があるため、アプリケーションテストでもAPIへのアクセスが必要になる場合があります。次の例は、GitLabをマイクロサービスとして使用して、テストにGitLab APIへのアクセスを許可する方法を示しています。

1. [Runner](../runners/_index.md)をDockerまたはKubernetes executorで設定します。
1. お使いの`.gitlab-ci.yml`に追加します:

   ```yaml
   services:
     - name: gitlab/gitlab-ce:latest
       alias: gitlab

   variables:
     GITLAB_HTTPS: "false"             # ensure that plain http works
     GITLAB_ROOT_PASSWORD: "password"  # to access the api with user root:password
   ```

> [!note]
> GitLab UIで設定された変数は、サービスコンテナには渡されません。詳細については、[GitLab CI/CD変数](../variables/_index.md)を参照してください。

その後、`.gitlab-ci.yml`ファイルの`script`セクションのコマンドは、`http://gitlab/api/v4`でAPIにアクセスできます。

`Host`に`gitlab`が使用される理由の詳細については、[ジョブにサービスがリンクされる方法](../docker/using_docker_images.md#extended-docker-configuration-options)を参照してください。

[Docker Hub](https://hub.docker.com/u/gitlab)で利用可能な他のDockerイメージも使用できます。

`gitlab`イメージは環境変数を受け入れることができます。詳細については、[Linuxパッケージドキュメント](../../install/_index.md)を参照してください。
