---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ジョブアーティファクトのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[ジョブアーティファクト](job_artifacts.md)を使用するときに、次の問題が発生することがあります。

## ジョブが特定のアーティファクトを取得しない {#job-does-not-retrieve-certain-artifacts}

デフォルトでは、ジョブは前のステージからすべてのアーティファクトをフェッチしますが、`dependencies`または`needs`を使用するジョブでは、デフォルトでフェッチ対象のアーティファクトが限定されています。

これらのキーワードを使用する場合、アーティファクトは一部のジョブからのみフェッチされます。これらのキーワードでアーティファクトをフェッチする方法については、キーワードのリファレンスを確認してください。

- [`dependencies`](../yaml/_index.md#dependencies)
- [`needs`](../yaml/_index.md#needs)
- [`needs:artifacts`](../yaml/_index.md#needsartifacts)

## ジョブアーティファクトがディスク容量を過剰に使用する {#job-artifacts-use-too-much-disk-space}

ジョブアーティファクトがディスク容量を過剰に使用している場合は、[ジョブアーティファクトの管理ドキュメント](../../administration/cicd/job_artifacts_troubleshooting.md#job-artifacts-using-too-much-disk-space)を参照してください。

## エラーメッセージ`No files to upload`（アップロードするファイルがありません） {#error-message-no-files-to-upload}

このメッセージは、Runnerがアップロードするファイルを見つけられない場合にジョブログに表示されます。ファイルへのパスが間違っているか、ファイルが作成されていません。ジョブログを確認し、ファイル名と生成されなかった理由を示すその他のエラーまたは警告がないか探してください。

より詳細なジョブログを確認するには、[CI/CDのデバッグログを有効にして](../variables/variables_troubleshooting.md#enable-debug-logging)ジョブを再試行してください。このログの生成により、ファイルが作成されなかった理由に関する詳細情報を得られる場合があります。

## Windows Runnerでdotenvアーティファクトをアップロードする際のエラーメッセージ`FATAL: invalid argument`（致命的なエラー: 無効な引数） {#error-message-fatal-invalid-argument-when-uploading-a-dotenv-artifact-on-a-windows-runner}

PowerShellの`echo`コマンドは、UCS-2 LE BOM（バイトオーダーマーク）エンコードでファイルを書き込みますが、サポートされているのはUTF-8のみです。そのため、`echo`で[`dotenv`](../yaml/artifacts_reports.md)アーティファクトを作成しようとすると、`FATAL: invalid argument`（致命的なエラー: 無効な引数）エラーが発生します。

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

## ジョブアーティファクトが期限切れにならない {#job-artifacts-do-not-expire}

一部のジョブアーティファクトが想定どおりに期限切れにならない場合は、[**成功した最新のジョブのアーティファクトを保持する**](job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)設定が有効になっていないかを確認してください。

この設定が有効になっている場合、各refの成功した最新のパイプラインから生成されたジョブアーティファクトは期限切れにならず、削除されません。

## エラーメッセージ`This job could not start because it could not retrieve the needed artifacts.`（このジョブは必要なアーティファクトを取得できなかったため開始できませんでした） {#error-message-this-job-could-not-start-because-it-could-not-retrieve-the-needed-artifacts}

必要なアーティファクトをフェッチできなかった場合、ジョブは開始できず、このエラーメッセージを返します。このエラーは、次の場合に返されます。

- ジョブの依存関係が見つからない場合。デフォルトでは、後続ステージのジョブはすべての先行ステージのジョブからアーティファクトをフェッチするため、先行ジョブはすべて依存関係と見なされます。ジョブが[`dependencies`](../yaml/_index.md#dependencies)キーワードを使用している場合は、リストに指定したジョブのみに依存します。
- アーティファクトがすでに期限切れになっている場合。[`artifacts:expire_in`](../yaml/_index.md#artifactsexpire_in)で有効期限を延長できます。
- 権限不足のため、ジョブが関連リソースにアクセスできない場合。

ジョブが[`needs:artifacts`](../yaml/_index.md#needsartifacts):キーワードと次のキーワードを組み合わせて使用している場合、以下のトラブルシューティング手順を参照してください。

- [`needs:project`](#for-a-job-configured-with-needsproject)
- [`needs:pipeline:job`](#for-a-job-configured-with-needspipelinejob)

### `needs:project`で設定されたジョブの場合 {#for-a-job-configured-with-needsproject}

ジョブが次のような設定で[`needs:project`](../yaml/_index.md#needsproject)を使用している場合、`could not retrieve the needed artifacts.`（必要なアーティファクトを取得できませんでした）エラーが発生する可能性があります。

```yaml
rspec:
  needs:
    - project: my-group/my-project
      job: dependency-job
      ref: master
      artifacts: true
```

このエラーを解決するには、以下を確認してください。

- プロジェクト`my-group/my-project`がPremiumサブスクリプションプランを持つグループに属している。
- ジョブを実行しているユーザーが`my-group/my-project`のリソースにアクセスできる。
- `project`、`job`、`ref`の組み合わせが存在し、想定どおりの依存関係を構成している。
- 使用している変数がすべて正しい値に評価される。

`CI_JOB_TOKEN`を使用する場合は、そのトークンをプロジェクトの[許可リスト](ci_job_token.md#control-job-token-access-to-your-project)に追加することで、別のプロジェクトからアーティファクトをプルできるようにしてください。

### `needs:pipeline:job`で設定されたジョブの場合 {#for-a-job-configured-with-needspipelinejob}

ジョブが次のような設定で[`needs:pipeline:job`](../yaml/_index.md#needspipelinejob)を使用している場合、`could not retrieve the needed artifacts.`（必要なアーティファクトを取得できませんでした）エラーが発生する可能性があります。

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

## アップグレード後にジョブに`UnlockPipelinesInQueueWorker`が表示される {#jobs-show-unlockpipelinesinqueueworker-after-an-upgrade}

ジョブが停止し、`UnlockPipelinesInQueueWorker`というエラーが表示される場合があります。

この問題は、アップグレード後に発生します。

回避策は、`ci_unlock_pipelines_extra_low`機能フラグを有効にすることです。機能フラグを切り替えるには、管理者である必要があります。

GitLab SaaSの場合:

- 次の[ChatOps](../chatops/_index.md)コマンドを実行します。

  ```ruby
  /chatops run feature set ci_unlock_pipelines_extra_low true
  ```

GitLab Self-Managedの場合:

- `ci_unlock_pipelines_extra_low`[機能フラグを有効にします](../../administration/feature_flags/_index.md)。

詳細については、[マージリクエスト140318](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140318#note_1718600424)のコメントを参照してください。
