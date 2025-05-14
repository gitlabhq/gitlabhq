---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ジョブアーティファクトの問題を解決する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[ジョブアーティファクト](job_artifacts.md)を使用するときに、次の問題が発生することがあります。

## ジョブが特定のアーティファクトを取得しない

デフォルトでは、ジョブは前のステージからすべてのアーティファクトをフェッチしますが、`dependencies`または`needs`を使用するジョブは、デフォルトで一部のジョブからアーティファクトをフェッチしません。

これらのキーワードを使用する場合、アーティファクトはジョブのサブセットからのみフェッチされます。これらのキーワードでアーティファクトをフェッチする方法については、キーワード参照を確認してください。

- [`dependencies`](../yaml/_index.md#dependencies)
- [`needs`](../yaml/_index.md#needs)
- [`needs:artifacts`](../yaml/_index.md#needsartifacts)

## ジョブアーティファクトがディスク容量を過剰に使用する

ジョブアーティファクトがディスク容量を過剰に使用する場合は、[ジョブアーティファクトの管理ドキュメント](../../administration/cicd/job_artifacts_troubleshooting.md#job-artifacts-using-too-much-disk-space)を参照してください。

## エラーメッセージ`No files to upload`

このメッセージは、Runnerがアップロードするファイルを見つけられない場合にジョブログに表示されます。ファイルへのパスが間違っているか、ファイルが作成されていません。ファイル名と生成されなかった理由を示すその他のエラーまたは警告がないか、ジョブログを確認できます。

より詳細なジョブログについては、[CI/CDデバッグログを有効](../variables/_index.md#enable-debug-logging)にして、ジョブを再度試してください。このログ生成により、ファイルが作成されなかった理由に関する詳細情報を得られる場合があります。

## エラーメッセージ`Missing /usr/bin/gitlab-runner-helper. Uploading artifacts is disabled.`

{{< history >}}

- GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3068)されました。GitLab Runnerは、`DEBUG`ではなく`RUNNER_DEBUG`を使用してこの問題を修正します。

{{< /history >}}

GitLab 15.1以前では、`DEBUG`という名前のCI/CD変数を設定すると、アーティファクトのアップロードが失敗する可能性があります。

この問題を回避するには、次のいずれかを実行します。

- GitLabおよびGitLab Runner 15.2にアップデートする
- 別の変数名を使用する
- `script`コマンドで環境変数として設定する

  ```yaml
  failing_test_job:  # This job might fail due to issue gitlab-org/gitlab-runner#3068
    variables:
      DEBUG: true
    script: bin/mycommand
    artifacts:
      paths:
        - bin/results

  successful_test_job:  # This job does not define a CI/CD variable named `DEBUG` and is not affected by the issue
    script: DEBUG=true bin/mycommand
    artifacts:
      paths:
        - bin/results
  ```

## Windows Runnerでdotenvアーティファクトをアップロードする際のエラーメッセージ`FATAL: invalid argument`

PowerShellの`echo`コマンドは、UCS-2 LE BOM（バイトオーダーマーク）エンコードでファイルを書き込みますが、サポートされているのはUTF-8だけです。`echo`で[`dotenv`](../yaml/artifacts_reports.md)アーティファクトを作成しようとすると、`FATAL: invalid argument`エラーが発生します。

代わりに、UTF-8を使用するPowerShell `Add-Content`を使用してください。

```yaml
test-job:
  stage: test
  tags:
    - windows
  script:
    - echo "test job"
    - Add-Content -Path build.env -Value "MY_ENV_VAR=true"
  artifacts:
    reports:
      dotenv: build.env
```

## ジョブアーティファクトが期限切れにならない

一部のジョブアーティファクトが期待どおりに期限切れにならない場合は、[**成功した最新のジョブのアーティファクトを保持する**](job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)設定が有効になっているかどうかを確認してください。

この設定が有効になっている場合、各refの成功した最新のパイプラインからのジョブアーティファクトは期限切れにならず、削除されません。

## エラーメッセージ`This job could not start because it could not retrieve the needed artifacts.`

ジョブを開始できず、必要なアーティファクトをフェッチできなかった場合、このエラーメッセージが返されます。このエラーは、次の場合に返されます。

- ジョブの依存関係が見つからない。デフォルトでは、以降のステージのジョブは、以前のすべてのステージのジョブからアーティファクトをフェッチするため、以前のジョブはすべて依存関係と見なされます。ジョブが[`dependencies`](../yaml/_index.md#dependencies)キーワードを使用している場合、リストされているジョブのみが依存します。
- アーティファクトがすでに期限切れになっている。[`artifacts:expire_in`](../yaml/_index.md#artifactsexpire_in)でより長い有効期限を設定できます。
- 権限が不十分なため、ジョブが関連リソースにアクセスできない。

ジョブが[`needs:artifacts`](../yaml/_index.md#needsartifacts):キーワードと一緒に次のキーワードを使用している場合、以下のトラブルシューティング手順を参照してください。

- [`needs:project`](#for-a-job-configured-with-needsproject)
- [`needs:pipeline:job`](#for-a-job-configured-with-needspipelinejob)

### `needs:project`で設定されたジョブの場合

ジョブが次のような設定で[`needs:project`](../yaml/_index.md#needsproject)を使用する場合、`could not retrieve the needed artifacts.`エラーが発生する可能性があります。

```yaml
rspec:
  needs:
    - project: my-group/my-project
      job: dependency-job
      ref: master
      artifacts: true
```

このエラーを解決するには、以下を確認してください。

- プロジェクト`my-group/my-project`がPremiumサブスクリプションプランのグループに属している。
- ジョブを実行しているユーザーが`my-group/my-project`のリソースにアクセスできる。
- `project`、`job`、および`ref`の組み合わせが存在し、これによって目的の依存関係になる。
- 使用されている変数はすべて正しい値に評価される。

### `needs:pipeline:job`で設定されたジョブの場合

ジョブが次のような設定で[`needs:pipeline:job`](../yaml/_index.md#needspipelinejob)を使用する場合、`could not retrieve the needed artifacts.`エラーが発生する可能性があります。

```yaml
rspec:
  needs:
    - pipeline: $UPSTREAM_PIPELINE_ID
      job: dependency-job
      artifacts: true
```

このエラーを解決するには、以下を確認してください。

- `$UPSTREAM_PIPELINE_ID` CI/CD変数が、現在のパイプラインの親子パイプライン階層で使用できる。
- `pipeline`と`job`の組み合わせが存在し、既存のパイプラインに解決される。
- `dependency-job`が実行され、正常に完了している。

## アップグレード後にジョブに`UnlockPipelinesInQueueWorker`が表示される

ジョブが停止し、`UnlockPipelinesInQueueWorker`を示すエラーが表示される場合があります。

この問題は、アップグレード後に発生します。

回避策は、`ci_unlock_pipelines_extra_low`機能フラグを有効にすることです。機能フラグを切り替えるには、管理者である必要があります。

GitLab SaaSの場合:

- 次の[ChatOps](../chatops/_index.md)コマンドを実行します。

  ```ruby
  /chatops run feature set ci_unlock_pipelines_extra_low true
  ```

GitLab Self-Managedの場合:

- `ci_unlock_pipelines_extra_low`という名前の[機能フラグを有効にします](../../administration/feature_flags.md)。

詳細については、[マージリクエスト140318](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140318#note_1718600424)のコメントを参照してください。
