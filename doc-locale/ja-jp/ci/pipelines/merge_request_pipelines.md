---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab CI/CDでマージリクエストパイプラインを使用することにより、マージの前に、変更を効率的にテストし、対象を絞ったジョブを実行し、コード品質を向上させる方法について説明します。
title: マージリクエストパイプライン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

マージリクエストのソースブランチに変更を加えるたびに実行されるよう、パイプラインを設定できます。

このタイプのパイプラインはマージリクエストパイプラインと呼ばれ、次の場合に実行されます:

- 1つ以上のコミットを含むソースブランチから新しいマージリクエストを作成する。
- マージリクエストのソースブランチに新しいコミットをプッシュする。
- マージリクエストの**パイプライン**タブに移動し、**パイプラインの実行**を選択する。

さらに、マージリクエストパイプラインには、以下の特徴があります:

- [より多くの定義済み変数](merge_request_pipelines.md#available-predefined-variables)にアクセスできる。
- [必要に応じて保護された変数やRunnerにアクセス](#control-access-to-protected-variables-and-runners)できる。

これらのパイプラインは、パイプラインリストに`merge request`ラベルを表示します。

マージリクエストパイプラインは、ターゲットブランチの内容を無視して、ソースブランチの内容のみで実行されます。ソースブランチとターゲットブランチのマージ結果をテストするパイプラインを実行するには、マージ結果パイプラインを使用します。

## 前提要件 {#prerequisites}

マージリクエストパイプラインを使用するには:

- プロジェクトの`.gitlab-ci.yml`ファイルに、[マージリクエストパイプラインで実行されるジョブが設定](#add-jobs-to-merge-request-pipelines)されている必要があります。
- マージリクエストパイプラインを実行するには、ソースプロジェクトのデベロッパーロール以上が必要です。
- リポジトリは、[外部リポジトリ](../ci_cd_for_external_repos/_index.md)ではなく、GitLabリポジトリである必要があります。

## マージリクエストパイプラインにジョブを追加する {#add-jobs-to-merge-request-pipelines}

[`rules`](../yaml/_index.md#rules)キーワードを使用して、ジョブをマージリクエストパイプラインで実行するように設定します。次に例を示します:

```yaml
job1:
  script:
    - echo "This job runs in merge request pipelines"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

[`workflow: rules`](../yaml/_index.md#workflowrules)キーワードを使用して、パイプライン全体をマージリクエストパイプラインで実行するように設定することもできます。次に例を示します:

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'

job1:
  script:
    - echo "This job runs in merge request pipelines"

job2:
  script:
    - echo "This job also runs in merge request pipelines"
```

一般的な`workflow`の例については、以下を参照してください:

- [ブランチパイプラインとマージリクエストパイプラインを切り替える](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines)
- [マージリクエストパイプラインを使用したGit Flow](../yaml/workflow.md#git-flow-with-merge-request-pipelines)

[セキュリティスキャンツールをマージリクエストパイプラインで使用する](../../user/application_security/detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)には、CI/CD変数`AST_ENABLE_MR_PIPELINES`または`latest`テンプレートエディションを使用します。

## フォークしたプロジェクトで使用する {#use-with-forked-projects}

フォークで作業する外部のコントリビューターは、親プロジェクト内にパイプラインを作成できません。

フォークから親プロジェクトに送信されたマージリクエストは、次のパイプラインをトリガーします:

- 親（ターゲット）プロジェクトではなく、フォーク（ソース）プロジェクトで作成および実行される。
- フォークプロジェクトのCI/CD設定、リソース、およびプロジェクトCI/CD変数を使用する。

フォークのパイプラインは、親プロジェクト内で**フォーク**バッジとともに表示されます。

### 親プロジェクトでパイプラインを実行する {#run-pipelines-in-the-parent-project}

親プロジェクトのプロジェクトメンバーは、フォークプロジェクトから送信されたマージリクエストに対して、マージリクエストパイプラインをトリガーできます。このパイプラインの特徴は、次のとおりです:

- フォーク（ソース）プロジェクトではなく、親（ターゲット）プロジェクトで作成および実行される。
- フォークプロジェクトのブランチに存在するCI/CD設定を使用する。
- 親プロジェクトのCI/CD設定、リソース、およびプロジェクトCI/CD変数を使用する。
- パイプラインをトリガーする親プロジェクトメンバーの権限を使用する。

フォークプロジェクトのMRでパイプラインを実行し、マージ後のパイプラインが親プロジェクトで正常に完了することを確認します。さらに、フォークプロジェクトのRunnerを信頼できない場合、親プロジェクトでパイプラインを実行すれば、親プロジェクトの信頼できるRunnerが使用されます。

{{< alert type="warning" >}}

フォークからのマージリクエストには、マージ前であってもパイプラインの実行時に親プロジェクトのシークレットを盗もうとする悪意のあるコードが含まれている可能性があります。レビュアーは、パイプラインをトリガーする前に、マージリクエストの変更を慎重に確認してください。APIまたは[`/rebase`クイックアクション](../../user/project/quick_actions.md#issues-merge-requests-and-epics)でパイプラインをトリガーした場合を除き、GitLabは警告を表示し、ユーザーはパイプラインを実行する前に承認する必要があります。それ以外の場合、**警告は表示されません**。

{{< /alert >}}

前提要件:

- 親プロジェクトの`.gitlab-ci.yml`ファイルは、[マージリクエストパイプラインでジョブを実行](#prerequisites)するように設定されている必要があります。
- [CI/CDパイプラインを実行する権限](../../user/permissions.md#cicd)を持つ、親プロジェクトのメンバーである必要があります。ブランチが保護されている場合、追加の権限が必要になることがあります。
- パイプラインを実行するユーザーがフォークプロジェクトを[参照](../../user/public_access.md)できる必要があります。そうでない場合、マージリクエストに**パイプライン**タブは表示されません。

UIを使用して、フォークプロジェクトからのマージリクエストに対して親プロジェクトでパイプラインを実行するには、次のようにします:

1. マージリクエストで、**パイプライン**タブに移動します。
1. **パイプラインの実行**を選択します。警告を読んで承認する必要があります。そうしないと、パイプラインは実行されません。

### フォークプロジェクトからのパイプラインを防止する {#prevent-pipelines-from-fork-projects}

ユーザーが親プロジェクトでフォークプロジェクトの新しいパイプラインを実行できないようにするには、[プロジェクトAPI](../../api/projects.md#edit-a-project)を使用して、`ci_allow_fork_pipelines_to_run_in_parent_project`設定を無効にします。

{{< alert type="warning" >}}

設定が無効になる前に作成されたパイプラインには影響せず、引き続き実行されます。古いパイプラインでジョブを再実行すると、ジョブはパイプラインの初回作成時と同じコンテキストを使用します。

{{< /alert >}}

## 利用可能な定義済み変数 {#available-predefined-variables}

マージリクエストパイプラインを使用する場合は、以下を使用できます:

- ブランチパイプラインで使用可能なすべての[定義済み変数](../variables/predefined_variables.md)。
- マージリクエストパイプラインのジョブでのみ使用可能な[追加の定義済み変数](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines)。

## 保護された変数とRunnerへのアクセスを制御する {#control-access-to-protected-variables-and-runners}

{{< history >}}

- GitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188008)されました。

{{< /history >}}

マージリクエストパイプラインから、[保護されたCI/CD変数](../variables/_index.md#protect-a-cicd-variable)と[保護されたRunner](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information)へのアクセスを制御できます。

マージリクエストパイプラインがこれらの保護されたリソースにアクセスできるのは、マージリクエストのソースブランチとターゲットブランチの両方が[保護されている](../../user/project/repository/branches/protected.md)場合のみです。また、パイプラインをトリガーするユーザーには、マージリクエストのターゲットブランチに対するプッシュ/マージアクセス権が必要です。マージリクエストパイプラインがこれらの保護されたリソースにアクセスできるのは、ソースブランチとターゲットブランチが同じプロジェクトに属している場合のみです。リポジトリのフォークからのマージリクエストパイプラインは、これらの保護されたリソースにアクセスできません。

前提要件:

- プロジェクトのメンテナーロールが必要です。

保護された変数とRunnerへのアクセスを制御するには、次のようにします:

- **設定** > **CI/CD**に移動します。
- **変数**を展開します。
- **マージリクエストパイプライン内で保護されたリソースへのアクセス**で、**マージリクエストパイプラインが保護された変数やRunnerにアクセスすることを許可する**オプションをオンまたはオフにします。
