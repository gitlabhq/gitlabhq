---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDでGitサブモジュールを使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Gitサブモジュール](https://git-scm.com/book/en/v2/Git-Tools-Submodules)を使用して、Gitリポジトリを別のGitリポジトリのサブディレクトリとして保持します。別のリポジトリのクローンをプロジェクトに作成し、コミットを分離した状態で保持できます。

## `.gitmodules`ファイルを設定する {#configure-the-gitmodules-file}

Gitサブモジュールを使用する場合、プロジェクトには`.gitmodules`という名前のファイルが必要です。複数のオプションを使用して、GitサブモジュールをGitLab CI/CDジョブで動作するように設定できます。

### 絶対URLを使用する {#using-absolute-urls}

{{< history >}}

- GitLab Runner 15.11で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3198)されました。

{{< /history >}}

たとえば、以下の条件では、生成される`.gitmodules`設定は次のようになります:

- プロジェクトが`https://gitlab.com/secret-group/my-project`にある。
- プロジェクトが`https://gitlab.com/group/project`に依存しており、これをサブモジュールとして含める。
- `git@gitlab.com:secret-group/my-project.git`などのSSHアドレスを使用してソースをチェックアウトする。

```ini
[submodule "project"]
  path = project
  url = git@gitlab.com:group/project.git
```

この場合、[`GIT_SUBMODULE_FORCE_HTTPS`](configure_runners.md#rewrite-submodule-urls-to-https)変数を使用して、サブモジュールのクローンを作成する前にURLをHTTPSに変換するようにGitLab Runnerに指示します。

または、ローカルでHTTPSも使用する場合は、HTTPS URLを設定できます。

```ini
[submodule "project"]
  path = project
  url = https://gitlab.com/group/project.git
```

この場合、追加の変数を設定する必要はありませんが、ローカルでクローンを作成するには[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)を使用する必要があります。

### 相対URLを使用する {#using-relative-urls}

{{< alert type="warning" >}}

相対URLを使用すると、フォーク型ワークフローでサブモジュールが適切に解決されない場合があります。プロジェクトにフォークが予想される場合は、絶対URLを使用してください。

{{< /alert >}}

サブモジュールが同じGitLabサーバー上にある場合は、`.gitmodules`ファイルで相対URLを使用することもできます。

```ini
[submodule "project"]
  path = project
  url = ../../project.git
```

前述の設定では、ソースのクローン時に使用するURLを自動的に推測するようにGitに指示します。すべてのCI/CDジョブでHTTPSを使用してクローンを作成できます。また、引き続きSSHを使用してローカルでクローンを作成することもできます。

同じGitLabサーバー上にないサブモジュールの場合は、常に完全なURLを使用します。

```ini
[submodule "project-x"]
  path = project-x
  url = https://gitserver.com/group/project-x.git
```

## CI/CDジョブでGitサブモジュールを使用する {#use-git-submodules-in-cicd-jobs}

前提要件:

- パイプラインジョブで[`CI_JOB_TOKEN`](../jobs/ci_job_token.md)を使用してサブモジュールのクローンを作成する場合、コードをプルするには、サブモジュールリポジトリに対しレポーター以上のロールが必要です。
- [CI/CDジョブトークンアクセス](../jobs/ci_job_token.md#control-job-token-access-to-your-project)は、アップストリームのサブモジュールプロジェクトで適切に設定する必要があります。

CI/CDジョブでサブモジュールを正しく動作させるには、次の手順に従います。

1. `GIT_SUBMODULE_STRATEGY`変数を`normal`または`recursive`のいずれかに設定して、[ジョブの前にサブモジュールをフェッチする](configure_runners.md#git-submodule-strategy)ようにRunnerに指示できます。

   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: recursive
   ```

1. 同じGitLabサーバー上にあり、GitまたはSSH URLで設定されたサブモジュールについては、[`GIT_SUBMODULE_FORCE_HTTPS`](configure_runners.md#rewrite-submodule-urls-to-https)変数が設定されていることを確認します。

1. `GIT_SUBMODULE_DEPTH`を使用して、[`GIT_DEPTH`](configure_runners.md#shallow-cloning)変数とは関係なく、サブモジュールのクローンの深さを設定します。

   ```yaml
   variables:
     GIT_SUBMODULE_DEPTH: 1
   ```

1. [`GIT_SUBMODULE_PATHS`](configure_runners.md#sync-or-exclude-specific-submodules-from-ci-jobs)を使用して、特定のサブモジュールをフィルタリングまたは除外し、同期するサブモジュールを制御できます。

   ```yaml
   variables:
     GIT_SUBMODULE_PATHS: submoduleA submoduleB
   ```

1. [`GIT_SUBMODULE_UPDATE_FLAGS`](configure_runners.md#git-submodule-update-flags)を使用して、追加のフラグを指定し、高度なチェックアウト動作を制御できます。

   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: recursive
     GIT_SUBMODULE_UPDATE_FLAGS: --jobs 4
   ```

## トラブルシューティング {#troubleshooting}

### `.gitmodules`ファイルが見つからない {#cant-find-the-gitmodules-file}

通常、`.gitmodules`ファイルは隠しファイルになっているため、見つけにくい場合があります。隠しファイルを見つけて表示する方法については、対象OSのドキュメントを確認してください。

`.gitmodules`ファイルがない場合は、サブモジュールの設定が[`git config`](https://www.atlassian.com/git/tutorials/setting-up-a-repository/git-config)ファイルにある可能性があります。

### エラー: `fatal: run_command returned non-zero status` {#error-fatal-run_command-returned-non-zero-status}

サブモジュールを操作しており、`GIT_STRATEGY`が`fetch`に設定されている場合、このエラーがジョブで発生する可能性があります。

`GIT_STRATEGY`を`clone`に設定すると、問題が解決するはずです。

### エラー: `fatal: could not read Username for 'https://gitlab.com': No such device or address` {#error-fatal-could-not-read-username-for-httpsgitlabcom-no-such-device-or-address}

GitLabでホストされているRunnerを使用している場合、CI/CDジョブがGitサブモジュールのクローン作成やGitサブモジュールのフェッチを試みると、このエラーが発生することがあります。

CI/CDパイプラインの実行中に、GitLab RunnerはGit URLの置換を自動的に行い、`CI_JOB_TOKEN`を介して認証します。

```shell
git config --global url."https://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_FQDN}".insteadOf "${CI_SERVER_FQDN}"
```

GitLabでホストされているRunnerの場合、`CI_SERVER_FQDN`は`https://gitlab.com`とは異なります。サブモジュールが`https://gitlab.com`に存在する場合、この置換は実行されず、エラーが発生します。

このエラーを解決する方法の1つは、`pre_get_sources_script`を作成し、`CI_JOB_TOKEN`を使用してURLの置換を手動で設定することです。

   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: recursive
     GIT_SUBMODULE_DEPTH: 1
   hooks:
     pre_get_sources_script:
       - git config --global url."https://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_FQDN}".insteadOf "${SUBMODULE_URL}"
   ```
