---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ダウンストリームパイプライン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ダウンストリームパイプラインとは、別のパイプラインによってトリガーされるGitLab CI/CDパイプラインのことです。ダウンストリームパイプラインは、トリガーしたアップストリームパイプラインとは独立して同時に実行されます。

- [親子パイプライン](downstream_pipelines.md#parent-child-pipelines)は、最初のパイプラインと同じプロジェクトでトリガーされるダウンストリームパイプラインです。
- [マルチプロジェクトパイプライン](#multi-project-pipelines)は、最初のパイプラインとは異なるプロジェクトでトリガーされるダウンストリームパイプラインです。

親子パイプラインとマルチプロジェクトパイプラインは同様の目的で使用できる場合がありますが、[重要な違い](pipeline_architectures.md)があります。

パイプライン階層には、デフォルトで最大1000個のダウンストリームパイプラインを含めることができます。この制限とその変更方法について詳しくは、[パイプライン階層サイズを制限する](../../administration/instance_limits.md#limit-pipeline-hierarchy-size)を参照してください。

## 親子パイプライン {#parent-child-pipelines}

親パイプラインとは、同じプロジェクト内のダウンストリームパイプラインをトリガーするパイプラインのことです。ダウンストリームパイプラインは、子パイプラインと呼ばれます。

子パイプライン:

- 親パイプラインと同じプロジェクト、ref、コミットSHAで実行されます。
- パイプライン実行の対象となるrefの全体的なステータスには直接影響しません。たとえば、mainブランチのパイプラインが失敗した場合、一般的には「mainが壊れている」と言われます。子パイプラインのステータスは、[`trigger:strategy`](../yaml/_index.md#triggerstrategy)で子パイプラインがトリガーされた場合にのみ、refのステータスに影響します。
- 同じrefに対して新しいパイプラインが作成されるとき、パイプラインが[`interruptible`](../yaml/_index.md#interruptible)で設定されている場合、自動的にキャンセルされます。
- プロジェクトのパイプラインリストには表示されません。子パイプラインは、親パイプラインの詳細ページでのみ表示できます。

### ネストされた子パイプライン {#nested-child-pipelines}

親パイプラインと子パイプラインは、最大で2階層までの子パイプラインを持つことができます。

親パイプラインは多数の子パイプラインをトリガーでき、これらの子パイプラインも自身の子パイプラインをトリガーできます。そのさらに下の階層の子パイプラインをトリガーすることはできません。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[Nested Dynamic Pipelines](https://youtu.be/C5j3ju9je2M)（ネストされた動的パイプライン）をご覧ください。

## マルチプロジェクトパイプライン {#multi-project-pipelines}

あるプロジェクトのパイプラインが別のプロジェクトのダウンストリームパイプラインをトリガーできます。これはマルチプロジェクトパイプラインと呼ばれます。アップストリームパイプラインをトリガーするユーザーには、ダウンストリームプロジェクトでパイプラインを開始できる権限が必要です。そうでない場合、[ダウンストリームパイプラインの開始に失敗します](downstream_pipelines_troubleshooting.md#trigger-job-fails-and-does-not-create-multi-project-pipeline)。

マルチプロジェクトパイプライン:

- 別のプロジェクトのパイプラインからトリガーされますが、アップストリーム（トリガーする）パイプラインはダウンストリーム（トリガーされる）パイプラインをあまり制御できません。ただし、ダウンストリームパイプラインのrefを選択したり、CI/CD変数を渡したりすることはできます。
- ダウンストリームパイプラインが実行されるプロジェクトのrefの全体的なステータスには影響しますが、[`trigger:strategy`](../yaml/_index.md#triggerstrategy)でトリガーされない限り、トリガー元のパイプラインのrefのステータスには影響しません。
- アップストリームパイプラインで同じrefに対して新しいパイプラインが実行された場合、[`interruptible`](../yaml/_index.md#interruptible)を使用しても、ダウンストリームプロジェクトでパイプラインが自動的にキャンセルされることはありません。ダウンストリームプロジェクトで同じrefに対して新しいパイプラインがトリガーされた場合、自動的にキャンセルできます。
- ダウンストリームプロジェクトのパイプラインリストに表示されます。
- 独立しているため、ネストの制限はありません。

パブリックプロジェクトからプライベートプロジェクトのダウンストリームパイプラインをトリガーする場合は、機密性の問題がないことを確認してください。アップストリームプロジェクトのパイプラインページには、常に以下が表示されます:

- ダウンストリームプロジェクトの名前。
- パイプラインのステータス。

## `.gitlab-ci.yml`ファイル内のジョブからダウンストリームパイプラインをトリガーする {#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file}

`.gitlab-ci.yml`ファイルで[`trigger`](../yaml/_index.md#trigger)キーワードを使用して、ダウンストリームパイプラインをトリガーするジョブを作成します。このジョブは、トリガージョブと呼ばれます。

次に例を示します:

{{< tabs >}}

{{< tab title="親子パイプライン" >}}

```yaml
trigger_job:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

{{< /tab >}}

{{< tab title="マルチプロジェクトパイプライン" >}}

```yaml
trigger_job:
  trigger:
    project: project-group/my-downstream-project
```

{{< /tab >}}

{{< /tabs >}}

トリガージョブが開始されると、GitLabがダウンストリームパイプラインの作成を試行している間、ジョブの初期ステータスは`pending`になります。ダウンストリームパイプラインが正常に作成された場合、トリガージョブは`passed`を表示し、それ以外の場合は`failed`を表示します。または、代わりに[ダウンストリームパイプラインのステータスを表示するようにトリガージョブを設定](#mirror-the-status-of-a-downstream-pipeline-in-the-trigger-job)することもできます。

### `rules`を使用してダウンストリームパイプラインのジョブを制御する {#use-rules-to-control-downstream-pipeline-jobs}

CI/CD変数または[`rules`](../yaml/_index.md#rulesif)キーワードを使用して、ダウンストリームパイプラインの[ジョブの動作を制御](../jobs/job_control.md)します。

[`trigger`](../yaml/_index.md#trigger)キーワードでダウンストリームパイプラインをトリガーすると、すべてのジョブにおける[`$CI_PIPELINE_SOURCE`定義済み変数](../variables/predefined_variables.md)の値は次のようになります:

- マルチプロジェクトパイプラインの場合: `pipeline`。
- 親子パイプラインの場合: `parent_pipeline`。

たとえば、マージリクエストパイプラインも実行するプロジェクトでマルチプロジェクトパイプラインのジョブを制御するには、次のようになります:

```yaml
job1:
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline"
  script: echo "This job runs in multi-project pipelines only"

job2:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script: echo "This job runs in merge request pipelines only"

job3:
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script: echo "This job runs in both multi-project and merge request pipelines"
```

### 別のプロジェクトで子パイプライン設定ファイルを使用する {#use-a-child-pipeline-configuration-file-in-a-different-project}

トリガージョブで[`include:project`](../yaml/_index.md#includeproject)を使用して、別のプロジェクトの設定ファイルで子パイプラインをトリガーできます:

```yaml
microservice_a:
  trigger:
    include:
      - project: 'my-group/my-pipeline-library'
        ref: 'main'
        file: '/path/to/child-pipeline.yml'
```

### 複数の子パイプライン設定ファイルを結合する {#combine-multiple-child-pipeline-configuration-files}

子パイプラインを定義するときに、最大3つの設定ファイルを含めることができます。子パイプラインの設定は、マージされたすべての設定ファイルで構成されます:

```yaml
microservice_a:
  trigger:
    include:
      - local: path/to/microservice_a.yml
      - template: Jobs/SAST.gitlab-ci.yml
      - project: 'my-group/my-pipeline-library'
        ref: 'main'
        file: '/path/to/child-pipeline.yml'
```

### 動的な子パイプライン {#dynamic-child-pipelines}

プロジェクトに保存されている静的なファイルではなく、ジョブで生成されたYAMLファイルから子パイプラインをトリガーできます。この手法は、変更されたコンテンツをターゲットとするパイプラインを生成したり、ターゲットとアーキテクチャのマトリックスを構築したりするのに非常に役立ちます。

生成されたYAMLファイルを含むアーティファクトは、[インスタンスの制限](../../administration/instance_limits.md#maximum-size-of-the-ci-artifacts-archive)内に存在する必要があります。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[Create child pipelines using dynamically generated configurations](https://youtu.be/nMdfus2JWHM)（動的に生成された設定を使用して子パイプラインを作成する）をご覧ください。

動的な子パイプラインを生成するプロジェクトの例については、[Jsonnetを使用した動的な子パイプライン](https://gitlab.com/gitlab-org/project-templates/jsonnet)を参照してください。このプロジェクトでは、データテンプレート言語を使用して、ランタイム時に`.gitlab-ci.yml`を生成する方法を示しています。[Dhall](https://dhall-lang.org/)や[ytt](https://get-ytt.io/)などの他のテンプレート言語でも同様のプロセスを使用できます。

#### 動的な子パイプラインをトリガーする {#trigger-a-dynamic-child-pipeline}

動的に生成された設定ファイルから子パイプラインをトリガーするには、次の手順に従います:

1. ジョブ内で設定ファイルを生成し、[アーティファクト](../yaml/_index.md#artifactspaths)として保存します:

   ```yaml
   generate-config:
     stage: build
     script: generate-ci-config > generated-config.yml
     artifacts:
       paths:
         - generated-config.yml
   ```

1. 設定ファイルを生成したジョブの後に実行するように、トリガージョブを設定します。`include: artifact`には生成されたアーティファクトを指定し、`include: job`にはアーティファクトを生成したジョブを指定します:

   ```yaml
   child-pipeline:
     stage: test
     trigger:
       include:
         - artifact: generated-config.yml
           job: generate-config
   ```

この例では、GitLabは`generated-config.yml`を取得し、そのファイル内のCI/CD設定で子パイプラインをトリガーします。

アーティファクトのパスはRunnerではなくGitLabによって解析されるため、パスはGitLabを実行しているOSの構文に一致している必要があります。GitLabがLinuxで実行されていても、テストにWindows Runnerを使用している場合、トリガージョブのパス区切り文字は`/`になります。スクリプトなど、Windows Runnerを使用するジョブの他のCI/CD設定では、` \ `を使用します。

動的な子パイプラインの設定の`include`セクションでは、CI/CD変数を使用できません。

### マージリクエストパイプラインで子パイプラインを実行する {#run-child-pipelines-with-merge-request-pipelines}

[`rules`](../yaml/_index.md#rules)も[`workflow:rules`](../yaml/_index.md#workflowrules)も使用しない場合、子パイプラインを含むパイプラインは、デフォルトでブランチパイプラインとして実行されます。[マージリクエスト（親）パイプライン](merge_request_pipelines.md)からトリガーされたときに実行するように子パイプラインを設定するには、`rules`または`workflow:rules`を使用します。たとえば、`rules`を使用する場合は次のようになります:

1. マージリクエストで実行するように親パイプラインのトリガージョブを設定します:

   ```yaml
   trigger-child-pipeline-job:
     trigger:
       include: path/to/child-pipeline-configuration.yml
     rules:
       - if: $CI_PIPELINE_SOURCE == "merge_request_event"
   ```

1. `rules`を使用して、親パイプラインによってトリガーされたときに実行するように子パイプラインのジョブを設定します:

   ```yaml
   job1:
     script: echo "This child pipeline job runs any time the parent pipeline triggers it."
     rules:
       - if: $CI_PIPELINE_SOURCE == "parent_pipeline"

   job2:
     script: echo "This child pipeline job runs only when the parent pipeline is a merge request pipeline"
     rules:
       - if: $CI_MERGE_REQUEST_ID
   ```

子パイプラインでは、`$CI_PIPELINE_SOURCE`の値は常に`parent_pipeline`になるため、次のようになります:

- `if: $CI_PIPELINE_SOURCE == "parent_pipeline"`を使用して、子パイプラインのジョブを常に実行させることができます。
- `if: $CI_PIPELINE_SOURCE == "merge_request_event"`を使用して、マージリクエストパイプラインで実行するように子パイプラインのジョブを設定することはできません。代わりに、`if: $CI_MERGE_REQUEST_ID`を使用して、親パイプラインがマージリクエストパイプラインである場合にのみ実行するように子パイプラインのジョブを設定します。親パイプラインの[`CI_MERGE_REQUEST_*`定義済み変数](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines)は、子パイプラインのジョブに渡されます。

### マルチプロジェクトパイプラインのブランチを指定する {#specify-a-branch-for-multi-project-pipelines}

マルチプロジェクトパイプラインをトリガーするときに、使用するブランチを指定できます。GitLabは、ブランチのヘッドのコミットを使用して、ダウンストリームパイプラインを作成します。次に例を示します:

```yaml
staging:
  stage: deploy
  trigger:
    project: my/deployment
    branch: stable-11-2
```

使用方法:

- `project`キーワードを使用して、ダウンストリームプロジェクトへのフルパスを指定します。[GitLab 15.3以降](https://gitlab.com/gitlab-org/gitlab/-/issues/367660)では、[変数の展開](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)を使用できます。
- `branch`キーワードを使用して、`project`で指定されたプロジェクト内のブランチまたは[タグ](../../user/project/repository/tags/_index.md)の名前を指定します。変数の展開を使用できます。

## APIを使用してマルチプロジェクトパイプラインをトリガーする {#trigger-a-multi-project-pipeline-by-using-the-api}

[パイプライントリガーAPIエンドポイント](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)で[CI/CDジョブトークン（`CI_JOB_TOKEN`）](../jobs/ci_job_token.md)を使用して、CI/CDジョブ内からマルチプロジェクトパイプラインをトリガーできます。GitLabは、ジョブトークンでトリガーされたパイプラインを、APIコールを行ったジョブを含むパイプラインのダウンストリームパイプラインとして設定します。

次に例を示します:

```yaml
trigger_pipeline:
  stage: deploy
  script:
    - curl --request POST --form "token=$CI_JOB_TOKEN" --form ref=main "https://gitlab.example.com/api/v4/projects/9/trigger/pipeline"
  rules:
    - if: $CI_COMMIT_TAG
  environment: production
```

## ダウンストリームパイプラインを表示する {#view-a-downstream-pipeline}

[パイプラインの詳細ページ](_index.md#pipeline-details)では、ダウンストリームパイプラインは、グラフの右側にカードのリストとして表示されます。このビューでは、次のことができます:

- トリガージョブを選択して、トリガーされたダウンストリームパイプラインのジョブを表示する。
- パイプラインカードで**ジョブを展開**{{< icon name="chevron-lg-right" >}}を選択し、そのダウンストリームパイプラインのジョブを展開して表示する。同時に表示できるのは1つのダウンストリームパイプラインのみです。
- パイプラインカードの上にカーソルを合わせ、ダウンストリームパイプラインをトリガーしたジョブを強調表示する。

### ダウンストリームパイプラインで失敗およびキャンセルされたジョブを再試行する {#retry-failed-and-canceled-jobs-in-a-downstream-pipeline}

{{< history >}}

- グラフビューからの再試行は、GitLab 15.0で`downstream_retry_action`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/354974)されました。デフォルトでは無効になっています。
- グラフビューからの再試行は、GitLab 15.1で[一般提供になり、機能フラグは削除](https://gitlab.com/gitlab-org/gitlab/-/issues/357406)されました。

{{< /history >}}

失敗およびキャンセルされたジョブを再試行するには、次の場所で**再試行**（{{< icon name="retry" >}}）を選択します:

- ダウンストリームパイプラインの詳細ページ。
- パイプライングラフビューのパイプラインカード上。

### ダウンストリームパイプラインを再作成する {#recreate-a-downstream-pipeline}

{{< history >}}

- グラフビューからのトリガージョブの再試行は、GitLab 15.10で`ci_recreate_downstream_pipeline`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/367547)されました。デフォルトでは無効になっています。
- GitLab 15.11で[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/6947)になりました。機能フラグ`ci_recreate_downstream_pipeline`は削除されました。

{{< /history >}}

対応するトリガージョブを再試行することで、ダウンストリームパイプラインを再作成できます。新しく作成されたダウンストリームパイプラインは、パイプライングラフ内の現在のダウンストリームパイプラインを置き換えます。

次の方法で、ダウンストリームパイプラインを再作成できます:

- パイプライングラフビューでトリガージョブのカードの**再実行**（{{< icon name="retry" >}}）を選択する。

### ダウンストリームパイプラインをキャンセルする {#cancel-a-downstream-pipeline}

{{< history >}}

- グラフビューからの再試行は、GitLab 15.0で`downstream_retry_action`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/354974)されました。デフォルトでは無効になっています。
- グラフビューからの再試行は、GitLab 15.1で[一般提供になり、機能フラグは削除](https://gitlab.com/gitlab-org/gitlab/-/issues/357406)されました。

{{< /history >}}

まだ実行中のダウンストリームパイプラインをキャンセルするには、次の場所で**キャンセル**（{{< icon name="cancel" >}}）を選択します:

- ダウンストリームパイプラインの詳細ページ。
- パイプライングラフビューのパイプラインカード上。

### ダウンストリームパイプラインから親パイプラインを自動キャンセルする {#auto-cancel-the-parent-pipeline-from-a-downstream-pipeline}

いずれかのジョブが失敗した時点で[自動キャンセル](../yaml/_index.md#workflowauto_cancelon_job_failure)されるように子パイプラインを設定できます。

子パイプラインのジョブが失敗したときに親パイプラインが自動キャンセルされるのは、次の場合のみです:

- 親パイプラインもジョブの失敗時に自動キャンセルするように設定されている。
- トリガージョブが[`strategy: mirror`](../yaml/_index.md#triggerstrategy)で設定されている。

次に例を示します:

- `.gitlab-ci.yml`の内容:

  ```yaml
  workflow:
    auto_cancel:
      on_job_failure: all

  trigger_job:
    trigger:
      include: child-pipeline.yml
      strategy: mirror

  job3:
    script:
      - sleep 120
  ```

- `child-pipeline.yml`の内容

  ```yaml
  # Contents of child-pipeline.yml
  workflow:
    auto_cancel:
      on_job_failure: all

  job1:
    script: sleep 60

  job2:
    script:
      - sleep 30
      - exit 1
  ```

この例では、次のようになります:

1. 親パイプラインは子パイプラインと`job3`を同時にトリガーします。
1. 子パイプラインからの`job2`が失敗し、子パイプラインがキャンセルされ、`job1`も停止します。
1. 子パイプラインがキャンセルされたため、親パイプラインは自動キャンセルされます。

### トリガージョブでダウンストリームパイプラインのステータスをミラーリングする {#mirror-the-status-of-a-downstream-pipeline-in-the-trigger-job}

[`strategy: mirror`](../yaml/_index.md#triggerstrategy)を使用して、トリガージョブでダウンストリームパイプラインのステータスをミラーリングできます:

{{< tabs >}}

{{< tab title="親子パイプライン" >}}

```yaml
trigger_job:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
    strategy: mirror
```

{{< /tab >}}

{{< tab title="マルチプロジェクトパイプライン" >}}

```yaml
trigger_job:
  trigger:
    project: my/project
    strategy: mirror
```

{{< /tab >}}

{{< /tabs >}}

### パイプライングラフでマルチプロジェクトパイプラインを表示する {#view-multi-project-pipelines-in-pipeline-graphs}

{{< history >}}

- GitLab 16.8でGitLab PremiumからGitLab Freeに[移行](https://gitlab.com/gitlab-org/gitlab/-/issues/422282)しました。

{{< /history >}}

マルチプロジェクトパイプラインをトリガーすると、ダウンストリームパイプラインが[パイプライングラフ](_index.md#view-pipelines)の右側に表示されます。

[パイプラインミニグラフ](_index.md#pipeline-mini-graphs)では、ダウンストリームパイプラインはミニグラフの右側に表示されます。

## 子パイプラインのレポートをマージリクエストで表示する {#view-child-pipeline-reports-in-merge-requests}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/groups/gitlab-org/-/epics/18311)されました。

{{< /history >}}

マージリクエストウィジェットで子パイプラインからのレポートを表示できます。これにより、複数のパイプラインを手動でナビゲートして障害を特定しなくても、パイプライン階層全体のテスト結果と品質チェックの統一されたビューが提供されます。

次のレポートタイプが子パイプラインからサポートされています:

- 単体テストレポート（Junit）
- Code Qualityレポート
- Terraformレポート
- メトリクスレポート

子パイプラインからのテスト結果は、親パイプラインの**テスト**タブにも表示されます。

マージリクエストウィジェットで完全なレポート情報を確認するには、[アーティファクトレポート](../yaml/artifacts_reports.md)を生成する子パイプラインで、[`strategy: depend`](../yaml/_index.md#triggerstrategy)または[`strategy: mirror`](../yaml/_index.md#triggerstrategy)を使用する必要があります。

次に例を示します:

```yaml
test-backend:
  trigger:
    include: backend-tests.yml
    strategy: depend

test-frontend:
  trigger:
    include: frontend-tests.yml
    strategy: depend
```

## アップストリームパイプラインからアーティファクトをフェッチする {#fetch-artifacts-from-an-upstream-pipeline}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< tabs >}}

{{< tab title="親子パイプライン" >}}

[`needs:pipeline:job`](../yaml/_index.md#needspipelinejob)を使用して、アップストリームパイプラインからアーティファクトをフェッチします:

1. アップストリームパイプラインで、[`artifacts`](../yaml/_index.md#artifacts)キーワードを使用してジョブにアーティファクトを保存し、トリガージョブでダウンストリームパイプラインをトリガーします:

   ```yaml
   build_artifacts:
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   deploy:
     stage: deploy
     trigger:
       include:
         - local: path/to/child-pipeline.yml
     variables:
       PARENT_PIPELINE_ID: $CI_PIPELINE_ID
   ```

1. ダウンストリームパイプラインのジョブで`needs:pipeline:job`を使用してアーティファクトをフェッチします。

   ```yaml
   test:
     stage: test
     script:
       - cat artifact.txt
     needs:
       - pipeline: $PARENT_PIPELINE_ID
         job: build_artifacts
   ```

   `job`に、アーティファクトを作成したアップストリームパイプラインのジョブを指定します。

{{< /tab >}}

{{< tab title="マルチプロジェクトパイプライン" >}}

[`needs:project`](../yaml/_index.md#needsproject)を使用して、アップストリームパイプラインからアーティファクトをフェッチします:

1. GitLab 15.9以降では、アップストリームプロジェクトの[ジョブトークンスコープの許可リストにダウンストリームプロジェクトを追加](../jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)します。
1. アップストリームパイプラインで、[`artifacts`](../yaml/_index.md#artifacts)キーワードを使用してジョブにアーティファクトを保存し、トリガージョブでダウンストリームパイプラインをトリガーします:

   ```yaml
   build_artifacts:
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   deploy:
     stage: deploy
     trigger: my/downstream_project   # Path to the project to trigger a pipeline in
   ```

1. ダウンストリームパイプラインのジョブで`needs:project`を使用してアーティファクトをフェッチします。

   ```yaml
   test:
     stage: test
     script:
       - cat artifact.txt
     needs:
       - project: my/upstream_project
         job: build_artifacts
         ref: main
         artifacts: true
   ```

   以下を設定します:

   - `job`に、アーティファクトを作成したアップストリームパイプラインのジョブを指定します。
   - `ref`にブランチを指定します。
   - `artifacts`を`true`に設定します。

{{< /tab >}}

{{< /tabs >}}

### アップストリームマージリクエストパイプラインからアーティファクトをフェッチする {#fetch-artifacts-from-an-upstream-merge-request-pipeline}

`needs:project`を使用して[アーティファクトをダウンストリームパイプラインに渡す](#fetch-artifacts-from-an-upstream-pipeline)場合、`ref`値は通常、`main`や`development`のようなブランチ名です。

[マージリクエストパイプライン](merge_request_pipelines.md)の場合、`ref`の値は`refs/merge-requests/<id>/head`の形式になります。`id`はマージリクエストIDです。このrefは、[`CI_MERGE_REQUEST_REF_PATH`](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines) CI/CD変数で取得できます。マージリクエストパイプラインで`ref`としてブランチ名を使用しないでください。そうすると、ダウンストリームパイプラインが最新のブランチパイプラインからアーティファクトをフェッチしようとしてしまいます。

`branch`パイプラインではなく、アップストリームの`merge request`パイプラインからアーティファクトをフェッチするには、[変数の継承](#pass-yaml-defined-cicd-variables)を使用して、`CI_MERGE_REQUEST_REF_PATH`をダウンストリームパイプラインに渡します:

1. GitLab 15.9以降では、アップストリームプロジェクトの[ジョブトークンスコープの許可リストにダウンストリームプロジェクトを追加](../jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)します。
1. アップストリームパイプラインのジョブで、[`artifacts`](../yaml/_index.md#artifacts)キーワードを使用してアーティファクトを保存します。
1. ダウンストリームパイプラインをトリガーするジョブで、`$CI_MERGE_REQUEST_REF_PATH`変数を渡します:

   ```yaml
   build_artifacts:
     rules:
       - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   upstream_job:
     rules:
       - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
     variables:
       UPSTREAM_REF: $CI_MERGE_REQUEST_REF_PATH
     trigger:
       project: my/downstream_project
       branch: my-branch
   ```

1. ダウンストリームパイプラインのジョブで、`needs:project`を使用して、渡された変数を`ref`として使用し、アップストリームパイプラインからアーティファクトをフェッチします:

   ```yaml
   test:
     stage: test
     script:
       - cat artifact.txt
     needs:
       - project: my/upstream_project
         job: build_artifacts
         ref: $UPSTREAM_REF
         artifacts: true
   ```

この方法を使用してアップストリームマージリクエストパイプラインからアーティファクトをフェッチできますが、[マージ結果パイプライン](merged_results_pipelines.md)からはフェッチできません。

## ダウンストリームパイプラインに入力を渡す {#pass-inputs-to-a-downstream-pipeline}

[`inputs`](../inputs/_index.md)キーワードを使用すると、入力値をダウンストリームパイプラインに渡すことができます。変数と比べて入力には、型チェック、さまざまなオプションによる検証、説明、デフォルト値など、多くのメリットがあります。

まず、対象の設定ファイルで、`spec:inputs`を使用して入力パラメータを定義します:

```yaml
# Target pipeline configuration
spec:
  inputs:
    environment:
      description: "Deployment environment"
      options: [staging, production]
    version:
      type: string
      description: "Application version"
```

次に、パイプラインをトリガーする際に値を指定します:

{{< tabs >}}

{{< tab title="親子パイプライン" >}}

```yaml
staging:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
        inputs:
          environment: staging
          version: "1.0.0"
```

{{< /tab >}}

{{< tab title="マルチプロジェクトパイプライン" >}}

```yaml
staging:
  trigger:
    project: my-group/my-deployment-project
    inputs:
      environment: staging
      version: "1.0.0"
```

{{< /tab >}}

{{< /tabs >}}

## CI/CD変数をダウンストリームパイプラインに渡す {#pass-cicd-variables-to-a-downstream-pipeline}

変数が作成または定義された場所に基づいて、いくつかの異なる方法で[CI/CD変数](../variables/_index.md)をダウンストリームパイプラインに渡すことができます。

### YAMLで定義されたCI/CD変数を渡す {#pass-yaml-defined-cicd-variables}

{{< alert type="note" >}}

パイプラインの設定には、変数よりも入力を使用することが推奨されます。入力の方がセキュリティと柔軟性に優れているためです。

{{< /alert >}}

`variables`キーワードを使用すると、CI/CD変数をダウンストリームパイプラインに渡すことができます。これらの変数は、[変数の優先順位](../variables/_index.md#cicd-variable-precedence)においてパイプライン変数です。

次に例を示します:

{{< tabs >}}

{{< tab title="親子パイプライン" >}}

```yaml
variables:
  VERSION: "1.0.0"

staging:
  variables:
    ENVIRONMENT: staging
  stage: deploy
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

{{< /tab >}}

{{< tab title="マルチプロジェクトパイプライン" >}}

```yaml
variables:
  VERSION: "1.0.0"

staging:
  variables:
    ENVIRONMENT: staging
  stage: deploy
  trigger: my-group/my-deployment-project
```

{{< /tab >}}

{{< /tabs >}}

`ENVIRONMENT`変数は、ダウンストリームパイプラインで定義されたすべてのジョブで使用できます。

`VERSION`デフォルト変数も、ダウンストリームパイプラインで使用できます。これは、トリガージョブを含むパイプライン内のすべてのジョブが[デフォルト`variables`](../yaml/_index.md#default-variables)を継承するためです。

#### デフォルト変数が渡されないようにする {#prevent-default-variables-from-being-passed}

[`inherit:variables`](../yaml/_index.md#inheritvariables)を使用して、デフォルトのCI/CD変数がダウンストリームパイプラインに到達しないようにすることができます。継承する特定の変数のリストを指定するか、すべてのデフォルト変数をブロックできます。

次に例を示します:

{{< tabs >}}

{{< tab title="親子パイプライン" >}}

```yaml
variables:
  DEFAULT_VAR: value

trigger-job:
  inherit:
    variables: false
  variables:
    JOB_VAR: value
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

{{< /tab >}}

{{< tab title="マルチプロジェクトパイプライン" >}}

```yaml
variables:
  DEFAULT_VAR: value

trigger-job:
  inherit:
    variables: false
  variables:
    JOB_VAR: value
  trigger: my-group/my-project
```

{{< /tab >}}

{{< /tabs >}}

トリガーされたパイプラインでは`DEFAULT_VAR`変数は使用できませんが、`JOB_VAR`は使用できます。

### 定義済み変数を渡す {#pass-a-predefined-variable}

[定義済みCI/CD変数](../variables/predefined_variables.md)を使用してアップストリームパイプラインに関する情報を渡すには、補間を使用します。定義済み変数をトリガージョブの新しいジョブ変数として保存し、ダウンストリームパイプラインに渡します。次に例を示します:

{{< tabs >}}

{{< tab title="親子パイプライン" >}}

```yaml
trigger-job:
  variables:
    PARENT_BRANCH: $CI_COMMIT_REF_NAME
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

{{< /tab >}}

{{< tab title="マルチプロジェクトパイプライン" >}}

```yaml
trigger-job:
  variables:
    UPSTREAM_BRANCH: $CI_COMMIT_REF_NAME
  trigger: my-group/my-project
```

{{< /tab >}}

{{< /tabs >}}

アップストリームパイプラインの`$CI_COMMIT_REF_NAME`定義済みCI/CD変数の値を含む`UPSTREAM_BRANCH`変数が、ダウンストリームパイプラインで使用可能になります。

[マスクされた変数](../variables/_index.md#mask-a-cicd-variable)をマルチプロジェクトパイプラインに渡すために、この手法を使用しないでください。CI/CDのマスキング設定はダウンストリームパイプラインに渡されないため、ダウンストリームプロジェクトのジョブログで変数がマスク解除されるおそれがあります。

この手法を使用して[ジョブ専用変数](../variables/predefined_variables.md#variable-availability)をダウンストリームパイプラインに渡すことはできません。トリガージョブではそれらの変数を使用できないためです。

アップストリームパイプラインは、ダウンストリームパイプラインよりも優先されます。アップストリームプロジェクトとダウンストリームプロジェクトの両方で同じ名前の2つの変数が定義されている場合、アップストリームプロジェクトで定義されている変数が優先されます。

### ジョブで作成されたdotenv変数を渡す {#pass-dotenv-variables-created-in-a-job}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[`dotenv`変数の継承](../variables/job_scripts.md#pass-an-environment-variable-to-another-job)を使用して、変数をダウンストリームパイプラインに渡すことができます。

たとえば、[マルチプロジェクトパイプライン](#multi-project-pipelines)では次のようになります:

1. `.env`ファイルに変数を保存します。
1. `.env`ファイルを`dotenv`レポートとして保存します。
1. ダウンストリームパイプラインをトリガーします。

   ```yaml
   build_vars:
     stage: build
     script:
       - echo "BUILD_VERSION=hello" >> build.env
     artifacts:
       reports:
         dotenv: build.env

   deploy:
     stage: deploy
     trigger: my/downstream_project
   ```

1. ダウンストリームパイプラインの`test`ジョブを、`needs`を使用してアップストリームプロジェクトの`build_vars`ジョブから変数を継承するように設定します。`test`ジョブは`dotenv`レポートの変数を継承し、スクリプトで`BUILD_VERSION`にアクセスできます:

   ```yaml
   test:
     stage: test
     script:
       - echo $BUILD_VERSION
     needs:
       - project: my/upstream_project
         job: build_vars
         ref: master
         artifacts: true
   ```

### ダウンストリームパイプラインに転送する変数のタイプを制御する {#control-what-type-of-variables-to-forward-to-downstream-pipelines}

[`trigger:forward`キーワード](../yaml/_index.md#triggerforward)を使用して、ダウンストリームパイプラインに転送する変数のタイプを指定します。転送された変数はトリガー変数と見なされ、[優先順位が最も高く](../variables/_index.md#cicd-variable-precedence)なります。

## デプロイのダウンストリームパイプライン {#downstream-pipelines-for-deployments}

{{< history >}}

- GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/369061)されました。

{{< /history >}}

[`trigger`](../yaml/_index.md#trigger)とともに[`environment`](../yaml/_index.md#environment)キーワードを使用できます。デプロイプロジェクトとアプリケーションプロジェクトが別々に管理されている場合は、トリガージョブから`environment`を使用することをおすすめします。

```yaml
deploy:
  trigger:
    project: project-group/my-downstream-project
  environment: production
```

ダウンストリームパイプラインは、インフラストラクチャをプロビジョニングし、指定された環境にデプロイし、デプロイステータスをアップストリームプロジェクトに返すことができます。

アップストリームプロジェクトから[環境とデプロイを表示](../environments/_index.md#view-environments-and-deployments)できます。

### 高度な例 {#advanced-example}

この設定例の動作は、次のようになります:

- アップストリームプロジェクトは、ブランチ名に基づいて環境名を動的に構成します。
- アップストリームプロジェクトは、`UPSTREAM_*`変数を使用して、デプロイのコンテキストをダウンストリームプロジェクトに渡します。

アップストリームプロジェクトの`.gitlab-ci.yml`:

```yaml
stages:
  - deploy
  - cleanup

.downstream-deployment-pipeline:
  variables:
    UPSTREAM_PROJECT_ID: $CI_PROJECT_ID
    UPSTREAM_ENVIRONMENT_NAME: $CI_ENVIRONMENT_NAME
    UPSTREAM_ENVIRONMENT_ACTION: $CI_ENVIRONMENT_ACTION
  trigger:
    project: project-group/deployment-project
    branch: main
    strategy: mirror

deploy-review:
  stage: deploy
  extends: .downstream-deployment-pipeline
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    on_stop: stop-review

stop-review:
  stage: cleanup
  extends: .downstream-deployment-pipeline
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

ダウンストリームプロジェクトの`.gitlab-ci.yml`:

```yaml
deploy:
  script: echo "Deploy to ${UPSTREAM_ENVIRONMENT_NAME} for ${UPSTREAM_PROJECT_ID}"
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline" && $UPSTREAM_ENVIRONMENT_ACTION == "start"

stop:
  script: echo "Stop ${UPSTREAM_ENVIRONMENT_NAME} for ${UPSTREAM_PROJECT_ID}"
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline" && $UPSTREAM_ENVIRONMENT_ACTION == "stop"
```
