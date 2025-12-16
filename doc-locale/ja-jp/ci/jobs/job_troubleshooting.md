---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: トラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ジョブを使用するときに、次の問題が発生することがあります。

## `changes:`を使用すると、ジョブまたはパイプラインが予期せず実行される可能性があります。 {#jobs-or-pipelines-run-unexpectedly-when-using-changes}

[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)なしで、[`rules: changes`rules: changes](../yaml/_index.md#ruleschanges)または[`only: changes`only: changes](../yaml/deprecated_keywords.md#onlychanges--exceptchanges)を使用すると、ジョブまたはパイプラインが予期せず実行されることがあります。

ブランチまたはタグ上のパイプラインは、マージリクエストとの明示的な関連付けがない場合、以前のSHAを使用して差分を計算します。この計算は`git diff HEAD~`と同等であり、以下を含む予期しない動作を引き起こす可能性があります:

- `changes`ルールは、新しいブランチまたは新しいタグをGitLabにプッシュするときに、常にtrueと評価されます。
- 新しいコミットをプッシュすると、変更されたファイルは、ベースSHAとして以前のコミットを使用して計算されます。

さらに、`changes`を使用するルールは、[スケジュールされたパイプライン](../pipelines/schedules.md)では常にtrueと評価されます。スケジュールされたパイプラインが実行されると、すべてのファイルが変更されたと見なされるため、ジョブは常に`changes`を使用するスケジュールされたパイプラインに追加される可能性があります。

## CI/CD変数のパス {#file-paths-in-cicd-variables}

CI/CD変数でファイルパスを使用する場合は注意してください。末尾のスラッシュは変数定義では正しく表示される可能性がありますが、`script:`、`changes:`、またはその他のキーワードで展開すると無効になる可能性があります。例: 

```yaml
docker_build:
  variables:
    DOCKERFILES_DIR: 'path/to/files/'  # This variable should not have a trailing '/' character
  script: echo "A docker job"
  rules:
    - changes:
        - $DOCKERFILES_DIR/*
```

`DOCKERFILES_DIR`変数が`changes:`セクションで展開されると、完全なパスは`path/to/files//*`になります。二重スラッシュは、使用されるキーワード、またはRunnerのシェルとOSのような要因に応じて、予期しない動作を引き起こす可能性があります。

## `You are not allowed to download code from this project.`エラーメッセージ {#you-are-not-allowed-to-download-code-from-this-project-error-message}

GitLabの管理者がプライベートプロジェクトで保護環境の手動ジョブを実行すると、パイプラインが失敗することがあります。

CI/CDジョブは通常、ジョブの開始時にプロジェクトをクローンし、これは[アクセス許可](../../user/permissions.md#cicd)を使用します。管理者を含むすべてのユーザーは、そのプロジェクトのソースをクローンするために、プライベートプロジェクトの直接のメンバーである必要があります。この動作を変更するために[イシューが存在します](https://gitlab.com/gitlab-org/gitlab/-/issues/23130)。

保護された手動ジョブを実行するには:

- プライベートプロジェクトの直接のメンバーとして管理者を追加します（任意のロール）。
- プロジェクトの直接のメンバーである[ユーザーを偽装](../../administration/admin_area.md#user-impersonation)します。

## CI/CDジョブを再度実行しても、新しい設定が使用されません {#a-cicd-job-does-not-use-newer-configuration-when-run-again}

パイプラインの設定は、パイプラインの作成時にのみフェッチされます。ジョブを再実行すると、毎回同じ設定が使用されます。[`include`](../yaml/_index.md#include)を使用して追加された個別のファイルを含む、設定ファイルを更新する場合は、新しい設定を使用するために新しいパイプラインを開始する必要があります。

## `Job may allow multiple pipelines to run for a single action`警告 {#job-may-allow-multiple-pipelines-to-run-for-a-single-action-warning}

`if`句のない`when`句で[`rules`](../yaml/_index.md#rules)を使用すると、複数のパイプラインが実行される可能性があります。通常、これは、関連付けられているオープンマージリクエストを持つブランチにコミットをプッシュすると発生します。

[重複したパイプラインを防ぐ](job_rules.md#avoid-duplicate-pipelines)には、[`workflow: rules`](../yaml/_index.md#workflow)を使用するか、ルールを書き換えて、実行できるパイプラインを制御します。

## `This GitLab CI configuration is invalid`変数式に対する {#this-gitlab-ci-configuration-is-invalid-for-variable-expressions}

[CI/CD変数式](job_rules.md#cicd-variable-expressions)を操作しているときに、いくつかの`This GitLab CI configuration is invalid`エラーが発生する可能性があります。これらの構文エラーは、引用符文字の不適切な使用が原因である可能性があります。

変数式では、文字列は引用符で囲む必要がありますが、変数は引用符で囲む必要はありません。例: 

```yaml
variables:
  ENVIRONMENT: production

job:
  script: echo
  rules:
    - if: $ENVIRONMENT == "production"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

この例では、`production`文字列が引用符で囲まれ、CI/CD変数が引用符で囲まれていないため、両方の`if:`句が有効です。

一方、これらの`if:`句はすべて無効です:

```yaml
variables:
  ENVIRONMENT: production

job:
  script: echo
  rules:       # These rules all cause YAML syntax errors:
    - if: ${ENVIRONMENT} == "production"
    - if: "$ENVIRONMENT" == "production"
    - if: $ENVIRONMENT == production
    - if: "production" == "production"
```

この例では: 

- `if: ${ENVIRONMENT} == "production"`は無効です。`${ENVIRONMENT}`が`if:`のCI/CD変数に対して有効な形式ではないためです。
- `if: "$ENVIRONMENT" == "production"`は、変数が引用符で囲まれているため、無効です。
- `if: $ENVIRONMENT == production`は、文字列が引用符で囲まれていないため、無効です。
- `if: "production" == "production"`は、比較するCI/CD変数がないため、無効です。

## `get_sources`ジョブセクションがHTTP/2の問題で失敗する {#get_sources-job-section-fails-because-of-an-http2-problem}

場合によっては、ジョブが次のcURLエラーで失敗することがあります:

```plaintext
++ git -c 'http.userAgent=gitlab-runner <version>' fetch origin +refs/pipelines/<id>:refs/pipelines/<id> ...
error: RPC failed; curl 16 HTTP/2 send again with decreased length
fatal: ...
```

Gitと`libcurl`を[HTTP/1.1を使用](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpversion)するように設定することで、この問題を回避できます。この設定は、以下に追加できます:

- ジョブの[`pre_get_sources_script`](../yaml/_index.md#hookspre_get_sources_script):

  ```yaml
  job_name:
    hooks:
      pre_get_sources_script:
        - git config --global http.version "HTTP/1.1"
  ```

- [Runnerの`config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html) （[Git設定環境変数](https://git-scm.com/docs/git-config#ENVIRONMENT)を使用）:

  ```toml
  [[runners]]
  ...
  environment = [
    "GIT_CONFIG_COUNT=1",
    "GIT_CONFIG_KEY_0=http.version",
    "GIT_CONFIG_VALUE_0=HTTP/1.1"
  ]
  ```

## `resource_group`を使用するジョブがスタックする {#job-using-resource_group-gets-stuck}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[`resource_group`](../yaml/_index.md#resource_group)を使用するジョブがスタックした場合、GitLabの管理者は、[Railsコンソール](../../administration/operations/rails_console.md#starting-a-rails-console-session)から次のコマンドの実行を試みることができます:

```ruby
# find resource group by name
resource_group = Project.find_by_full_path('...').resource_groups.find_by(key: 'the-group-name')
busy_resources = resource_group.resources.where('build_id IS NOT NULL')

# identify which builds are occupying the resource
# (I think it should be 1 as of today)
busy_resources.pluck(:build_id)

# it's good to check why this build is holding the resource.
# Is it stuck? Has it been forcefully dropped by the system?
# free up busy resources
busy_resources.update_all(build_id: nil)
```

## `You are not authorized to run this manual job`メッセージ {#you-are-not-authorized-to-run-this-manual-job-message}

次の条件に該当する場合、このメッセージが表示され、手動ジョブの実行を試みるときに**実行**ボタンが無効になることがあります:

- ターゲット環境が[保護環境](../environments/protected_environments.md)であり、アカウントが**デプロイ許可**リストに含まれていません。
- [期限切れのデプロイメントジョブを防ぐ](../environments/deployment_safety.md#prevent-outdated-deployment-jobs)設定が有効になっており、ジョブを実行すると、最新のデプロイが上書きされます。
