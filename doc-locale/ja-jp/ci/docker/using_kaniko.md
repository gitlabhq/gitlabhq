---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: kanikoを使用してDockerイメージをビルドする（削除済み）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[kaniko](https://github.com/GoogleContainerTools/kaniko)は、メンテナンスが終了したプロジェクトです。詳細については、[イシュー3348](https://github.com/GoogleContainerTools/kaniko/issues/3348)を参照してください代わりに、[DockerイメージをビルドするにはDocker](using_docker_build.md)または[Buildah](using_docker_build.md#buildah-example)、[Dockerコマンドを実行するにはPodman](https://docs.gitlab.com/runner/executors/docker/#use-podman-to-run-docker-commands)、または[KubernetesでGitLab RunnerとPodmanを組み合わせて](https://docs.gitlab.com/runner/executors/kubernetes/use_podman_with_kubernetes/)使用してください。
