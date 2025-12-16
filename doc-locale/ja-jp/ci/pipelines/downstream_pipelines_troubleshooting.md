---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ダウンストリームパイプラインのトラブルシューティング
---

## トリガージョブが失敗し、マルチプロジェクトパイプラインが作成されない {#trigger-job-fails-and-does-not-create-multi-project-pipeline}

マルチプロジェクトパイプラインでは、トリガージョブが失敗し、次の場合にダウンストリームパイプラインが作成されません:

- ダウンストリームプロジェクトが見つからない。
- アップストリームパイプラインを作成するユーザーに、ダウンストリームプロジェクトでパイプラインを作成する[permission](../../user/permissions.md)がありません。
- ダウンストリームパイプラインが保護ブランチをターゲットにしており、ユーザーがその保護ブランチに対してパイプラインを実行する権限を持っていません。詳しくは、[保護ブランチのパイプラインセキュリティ](_index.md#pipeline-security-on-protected-branches)をご覧ください。

ダウンストリームプロジェクトで権限の問題が発生しているユーザーを特定するには、[Railsコンソール](../../administration/operations/rails_console.md)で次のコマンドを使用してトリガージョブを確認し、`user_id`属性を確認します。

```ruby
Ci::Bridge.find(<job_id>)
```

## 子パイプラインのジョブがパイプラインの実行時に作成されない {#job-in-child-pipeline-is-not-created-when-the-pipeline-runs}

親パイプラインが[マージリクエストパイプライン](merge_request_pipelines.md)の場合、子パイプラインは、[`workflow:rules`または`rules`を使用して、ジョブが確実に実行されるようにする必要があります](downstream_pipelines.md#run-child-pipelines-with-merge-request-pipelines)。

`rules`設定が不足しているか、正しくないために、子パイプラインで実行できるジョブがない場合:

- 子パイプラインが開始に失敗します。
- 親パイプラインのトリガージョブが次のように失敗します: `downstream pipeline can not be created, the resulting pipeline would have been empty. Review the`[`rules`](../yaml/_index.md#rules)`configuration for the relevant jobs.`

## `$`文字を含む変数がダウンストリームパイプラインに正しく渡されない {#variable-with--character-does-not-get-passed-to-a-downstream-pipeline-properly}

[CI/CD変数をダウンストリームパイプラインに渡す](downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline)場合、[`$$`を使用してCI/CD変数内の`$`文字をエスケープする](../variables/job_scripts.md#use-the--character-in-cicd-variables)ことはできません。ダウンストリームパイプラインは引き続き`$`を変数参照の開始として扱います。

UIで変数を設定する際に[CI/CD変数の展開を防止](../variables/_index.md#allow-cicd-variable-expansion)するか、[`variables:expand`キーワード](../yaml/_index.md#variablesexpand)を使用して、変数の値が展開されないように設定できます。これにより、`$`が変数参照として解釈されずに、変数をダウンストリームパイプラインに渡すことができます。

## `Ref is ambiguous` {#ref-is-ambiguous}

同じ名前のブランチが存在する場合、タグを使用してマルチプロジェクトパイプラインをトリガーすることはできません。ダウンストリームパイプラインの作成に失敗し、次のエラーが発生します: `downstream pipeline can not be created, Ref is ambiguous`。

ブランチ名と一致しないタグ名でマルチプロジェクトパイプラインのみをトリガーします。

## アップストリームパイプラインからジョブのアーティファクトをダウンロードする際の`403 Forbidden`エラー {#403-forbidden-error-when-downloading-a-job-artifact-from-an-upstream-pipeline}

GitLab 15.9以降では、CI/CDジョブトークンは、パイプラインが実行されるプロジェクトをスコープとします。したがって、ダウンストリームパイプライン内のジョブトークンは、デフォルトではアップストリームプロジェクトにアクセスするために使用できません。

これを解決するには、[ジョブトークンのスコープ許可リストにダウンストリームプロジェクトを追加します](../jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)。

## エラー: `needs:need pipeline should be a string` {#error-needsneed-pipeline-should-be-a-string}

動的な子パイプラインで[`needs:pipeline:job`](../yaml/_index.md#needspipelinejob)を使用すると、次のエラーが発生する可能性があります:

```plaintext
Unable to create pipeline
- jobs:<job_name>:needs:need pipeline should be a string
```

このエラーは、パイプラインIDが文字列ではなく整数として解析される場合に発生します。これを修正するには、パイプラインIDを引用符で囲みます:

```yaml
rspec:
  needs:
    - pipeline: "$UPSTREAM_PIPELINE_ID"
      job: dependency-job
      artifacts: true
```
