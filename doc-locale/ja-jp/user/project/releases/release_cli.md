---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Release CLIツール（非推奨）
---

<!--- start_remove The following content will be removed on remove_date: '2026-06-19' -->

{{< alert type="warning" >}}

この機能はGitLab 18.0で[deprecated](https://gitlab.com/gitlab-org/cli/-/issues/7859)となり、19.0で削除される予定です。代わりに[GitLab CLI](../../../editor_extensions/gitlab_cli/_index.md)を使用してください。

これは破壊的な変更です。

{{< /alert >}}

## `release-cli`から`glab`に移行する {#migrate-from-release-cli-to-glab-cli}

`release-cli`から`glab`に移行するには、`release`キーワードでジョブを更新し、`cli:latest`イメージを使用します:

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  rules:
    - if: $CI_COMMIT_TAG
  script:
    - echo "Running the release job."
  release:
    tag_name: $CI_COMMIT_TAG
    name: 'Release $CI_COMMIT_TAG'
    description: 'Release created using the CLI.'
```

詳細については、[`release`](../../../ci/yaml/_index.md#release)を参照してください。

## `release-cli`へのフォールバック {#fall-back-to-release-cli}

{{< history >}}

- GitLab 18.0で`ci_glab_for_release`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/524346)されました。デフォルトでは有効になっています。
- GitLab 18.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/537398)になりました。機能フラグ`ci_glab_for_release`は削除されました。

{{< /history >}}

`release`キーワードを使用するCI/CDジョブは、必要な`glab`バージョンがRunnerで使用できない場合、`release-cli`を使用するようにフォールバックするスクリプトを使用します。このフォールバックロジックは、`glab` CLIを使用するためにまだ移行していないプロジェクトで引き続き作業できるようにするための安全対策です。

このフォールバックは、`release-cli`の削除とともにGitLab 19.0で[削除される予定](https://gitlab.com/gitlab-org/gitlab/-/issues/537919)です。

<!--- end_remove -->
