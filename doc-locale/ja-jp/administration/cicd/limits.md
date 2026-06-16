---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: インスタンスのリソース使用を制御するため、パイプライン、ジョブ、スケジュール、およびアーティファクトのCI/CD制限を設定します。
title: CI/CDの制限
---

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

多くのCI/CD関連のインスタンス制限は、[管理者エリア](../admin_area.md)を通じて管理できます。その他の制限は、インスタンスの設定をGitLab Railsコンソールから変更することによってのみ可能です。

GitLab.comは、GitLab Self-Managedのデフォルトとは異なる値を持つ場合があります。[CI/CDの制限とGitLab.comの設定](../../user/gitlab_com/_index.md#cicd)を確認してください。

## インスタンスCI/CD変数の制限 {#instance-cicd-variable-limit}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/456845)されました。

{{< /history >}}

インスタンスの設定で定義できる[CI/CD変数](../../ci/variables/_index.md)の数には制限があります。この制限は、新しい変数が作成されるたびにチェックされます。新しい変数が変数の総数を制限を超えさせる場合、新しい変数は作成されません。

この制限を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **CI/CD制限**の下で、**定義できるインスタンスレベルのCI/CD変数の最大数**の値を設定します。デフォルトは`25`です。
1. **変更を保存**を選択します。

## dotenvファイルサイズを制限する {#limit-dotenv-file-size}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155791)されました。

{{< /history >}}

dotenvアーティファクトの最大サイズに制限を設定できます。この制限は、dotenvファイルがアーティファクトとしてエクスポートされるたびにチェックされます。

この制限を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **CI/CD制限**の下で、**dotenvアーティファクトの最大サイズ(バイト)** の値を設定します。
1. **変更を保存**を選択します。

制限を`0`に設定すると、無効になります。デフォルトは5 KBです。

## dotenv変数を制限する {#limit-dotenv-variables}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155791)されました。

{{< /history >}}

dotenvアーティファクト内の変数の最大数に制限を設定できます。この制限は、dotenvファイルがアーティファクトとしてエクスポートされるたびにチェックされます。

この制限を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **CI/CD制限**の下で、**dotenvアーティファクトの変数の最大数**の値を設定します。
1. **変更を保存**を選択します。

制限を`0`に設定すると、無効になります。`20`がデフォルトです。

[プラン制限API](../../api/plan_limits.md)を使用してもこの制限を設定できます。

## パイプライン内のジョブの最大数 {#maximum-number-of-jobs-in-a-pipeline}

{{< history >}}

- [設定](https://gitlab.com/gitlab-org/gitlab/-/issues/287669)がGitLab Enterprise EditionからGitLab Community Editionに17.6で移動されました。

{{< /history >}}

パイプライン内のジョブの最大数を制限できます。パイプライン内のジョブの数は、パイプラインの作成時と新しいコミットステータスの作成時にチェックされます。ジョブが多すぎるパイプラインは、`size_limit_exceeded`エラーで失敗します。

この制限を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **CI/CD制限**の下で、**パイプラインごとの最大ジョブ数**の値を設定します。
1. **変更を保存**を選択します。

制限を`0`に設定すると、無効になります。デフォルトでは無効になっています。

## アクティブなパイプライン内のジョブ数 {#number-of-jobs-in-active-pipelines}

アクティブなパイプラインに含まれるジョブの総数は、プロジェクトごとに制限できます。この制限は、新しいパイプラインが作成されるたびにチェックされます。アクティブなパイプラインとは、次のいずれかの状態にあるパイプラインです。

- `created`
- `pending`
- `running`

新しいパイプラインによってジョブの総数が制限を超える場合、そのパイプラインは`job_activity_limit_exceeded`エラーで失敗します。

この制限を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **CI/CD制限**の下で、**現在アクティブなパイプラインの合計ジョブ数**の値を設定します。
1. **変更を保存**を選択します。

制限を`0`に設定すると、無効になります。デフォルトでは無効になっています。

## プロジェクトに対するCI/CDサブスクリプションの数 {#number-of-cicd-subscriptions-to-a-project}

サブスクリプションの総数は、プロジェクトごとに制限できます。この制限は、新しいサブスクリプションが作成されるたびにチェックされます。

新しいサブスクリプションによってサブスクリプションの総数が制限を超える場合、そのサブスクリプションは無効と見なされます。

この制限を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **CI/CD制限**の下で、**プロジェクトとの間のパイプラインサブスクリプションの最大数**の値を設定します。
1. **変更を保存**を選択します。

デフォルトでは、サブスクリプション数の制限は`2`です。制限を`0`に設定すると、無効になります。

## パイプラインスケジュール数 {#number-of-pipeline-schedules}

パイプラインスケジュールの総数は、プロジェクトごとに制限できます。この制限は、新しいパイプラインスケジュールが作成されるたびにチェックされます。新しいパイプラインスケジュールによってパイプラインスケジュールの総数が制限を超える場合、そのパイプラインスケジュールは作成されません。

この制限を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **CI/CD制限**の下で、**パイプラインスケジュールの最大数**の値を設定します。
1. **変更を保存**を選択します。

デフォルトでは、パイプラインスケジュール数の制限は`10`です。

[プラン制限API](../../api/plan_limits.md)を使用してもこの制限を設定できます。

## 必要とされる依存関係の最大数 {#maximum-number-of-needs-dependencies}

単一のジョブが持つことができる必要とされる依存関係の最大数を設定できます。

この制限を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **CI/CD制限**の下で、**ジョブが持てる必要な依存関係の最大数**の値を設定します。
1. **変更を保存**を選択します。

この制限は無効にできません。`50`がデフォルトです。

すべての必要とされる依存関係をブロックするには`0`に設定します。`needs`を使用するように設定されたジョブを含むパイプラインは、`job can only need 0 others`というエラーを返します。

## グループおよびプロジェクトの登録済みRunner数 {#number-of-registered-runners-for-groups-and-projects}

{{< history >}}

- GitLab 17.1で、Runnerの非アクティブタイムアウトは、3か月から7日に[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155795)されました。

{{< /history >}}

グループとプロジェクトに登録できるRunnerの総数は制限されています。新しいRunnerが登録されるたびに、GitLabは過去7日間に作成された、またはアクティブだったRunnerに対してこの制限をチェックします。Runner登録トークンで決定されるスコープの制限を超えた場合、Runnerの登録は失敗します。

この制限を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **CI/CD制限**の下で、次のいずれかの値を設定します:
   - **過去7日間にグループ内で作成または有効にできるRunnerの最大数**
   - **過去7日間にプロジェクト内で作成または有効にできるRunnerの最大数**
1. **変更を保存**を選択します。

制限を`0`に設定すると、無効になります。

## パイプライン階層サイズを制限する {#limit-pipeline-hierarchy-size}

デフォルトでは、[パイプライン階層](../../ci/pipelines/downstream_pipelines.md)に含めることができるダウンストリームパイプラインの最大数は1,000個です。この制限を超えると、パイプラインの作成は`downstream pipeline tree is too large`というエラーで失敗します。

> [!warning]
> この制限を増やすことは推奨されません。デフォルトの制限では、過剰なリソース消費、潜在的なパイプライン再帰、およびデータベースのオーバーロードからGitLabインスタンスが保護されます。
>
> この制限を引き上げる代わりに、大規模なパイプライン階層をより小さなパイプラインに分割して、CI/CD構成を再編成してください。単一のパイプライン内のジョブまたは依存するステージ間で`needs`を使用することを検討してください。

この制限を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **CI/CD制限**の下で、**パイプラインの階層ツリー内のダウンストリームパイプラインの最大数**の値を設定します。
1. **変更を保存**を選択します。

[プラン制限API](../../api/plan_limits.md)を使用してもこの制限を設定できます。

## マージトレインの並列パイプライン制限 {#merge-train-parallel-pipeline-limit}

{{< history >}}

- GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/374188)されました。

{{< /history >}}

デフォルトでは、各[マージトレイン](../../ci/pipelines/merge_trains.md)は最大20のパイプラインを並行して実行できます。この制限に達すると、パイプラインのスロットが利用可能になるまで、追加のマージリクエストがキューに入れられます。

この制限を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **CI/CD制限**の下で、**マージトレインごとの最大並列パイプライン数**の値を設定します。最小値は`1`です。`1`の値は、並行処理なしでマージリクエストを順次処理します。
1. **変更を保存**を選択します。

[プラン制限API](../../api/plan_limits.md)を使用してもこの制限を設定できます。

特定のプロジェクトに対して[異なる値](../../ci/pipelines/merge_trains.md#merge-train-parallel-pipeline-limit)を設定できます。

## ジョブが実行できる最大時間 {#maximum-time-jobs-can-run}

ジョブが実行できるデフォルトの最大時間は60分です。60分を超えて実行されるジョブはタイムアウトになります。

ジョブがタイムアウトになるまでの最大実行時間は変更できます。

- 特定のプロジェクトの[プロジェクトのCI/CD設定](../../ci/pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run)で。この制限は、10分から1か月の間でなければなりません。
- [Runnerの場合](../../ci/runners/configure_runners.md#set-the-maximum-job-timeout)。この制限は10分以上でなければなりません。

設定されているタイムアウト制限に関係なく、GitLabは非アクティブな期間が60分間に達したジョブをすべて終了します。非アクティブなジョブとは、新しいログまたはトレース更新を生成していないジョブのことです。

## Gitプッシュごとのパイプライン数 {#number-of-pipelines-per-git-push}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186134)されました。

{{< /history >}}

> [!warning]
> この制限を増やすことは推奨されません。多数の変更が同時にプッシュされると、GitLabインスタンスに過剰な負荷がかかり、パイプラインが大量に作成される可能性があります。

複数のタグまたはブランチなど、1回のGitプッシュで複数の変更をプッシュする場合、トリガーできるタグまたはブランチのパイプラインは、デフォルトでは4つまでです。この制限により、`git push --all`または`git push --mirror`を使用する際に、意図せず大量のパイプラインが作成されるのを防ぐことができます。

[マージリクエストパイプライン](../../ci/pipelines/merge_request_pipelines.md)は制限の対象です。Gitプッシュによって複数のマージリクエストを同時に更新する場合、制限に達するまでは、更新されたすべてのマージリクエストに対してマージリクエストパイプラインをトリガーできます。

GitLab Self-ManagedとGitLab.comのデフォルト値は`4`です。

GitLab Self-Managedインスタンスでこの制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **各Git pushのパイプラインの制限**の値を変更します。
1. **変更を保存**を選択します。

## パイプライン作成のレート制限 {#pipeline-creation-rate-limits}

{{< history >}}

- GitLab 15.0で`ci_enforce_throttle_pipelines_creation`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/362475)されました。デフォルトでは無効になっています。GitLab.comで有効化されています。
- 18.3で[デフォルトで有効化](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196545)されました。

{{< /history >}}

ユーザーとプロセスが毎分特定のパイプライン数を超えるリクエストを行えないように制限を設定できます。これらの制限は、リソースを節約し、安定性を向上させるのに役立ちます。

GitLabは、パイプライン作成に対して2種類のレート制限を適用します:

- **Per project, commit, and user**: プロジェクト、コミットSHA、およびユーザーの同じ組み合わせで作成されたパイプラインを制限します。デフォルトでは無効になっています。
- **Per user**: すべてのプロジェクトでユーザーによって作成された合計パイプラインを制限します。デフォルトでは無効になっています。

例えば、ユーザーごとの制限を`100`に設定し、ユーザーが異なるプロジェクト間で1分以内に[トリガーAPI](../../ci/triggers/_index.md)にパイプライン作成リクエストを`101`送信した場合、101番目のリクエストはブロックされます。エンドポイントへのアクセスは1分後に再度許可されます。

これらの制限はIPアドレスごとには適用されません。

制限を超過したリクエストは、`application_json.log`ファイルにログが記録されます。

### パイプラインリクエストの制限を設定 {#set-pipeline-request-limits}

前提条件: 

- 管理者アクセス権。

パイプラインリクエストの数を制限するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **ネットワーク**を選択します。
1. **Pipelines Rate Limits**を展開します。
   - **Max requests per minute per project, user, and commit**の下で、同じプロジェクト、コミット、ユーザーの組み合わせに対するパイプラインを制限するために、`0`より大きい値を入力します。
   - **Max requests per minute per user**の下で、各ユーザーが作成できる合計パイプラインを制限するために、`0`より大きい値を入力します。毎分の無制限のリクエストに対して`0`に設定します。
1. **変更を保存**を選択します。

両方のレート制限は独立して評価されます:

- プロジェクトで同じコミットSHAに対して複数のパイプラインを作成するユーザーは、**per project, user, and commit**制限の対象となります。
- 異なるプロジェクトまたはコミット間でパイプラインを作成するユーザーは、**ユーザーごと**の制限の対象となります。
- いずれかの制限を超過した場合、パイプライン作成リクエストはブロックされます。

## ダウンストリームパイプライントリガーレートを制限する {#limit-downstream-pipeline-trigger-rate}

1つのソースから1分間にトリガーできる[ダウンストリームパイプライン](../../ci/pipelines/downstream_pipelines.md)の数を制限します。

最大ダウンストリームパイプライントリガーレート制限は、プロジェクト、ユーザー、コミットの特定の組み合わせに対して、1分間にトリガーできるダウンストリームパイプラインの数を制限します。デフォルト値は`0`です。これは、制限がないことを意味します。

この制限を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **最大ダウンストリームパイプライントリガーレート**の値を設定します。
1. **変更を保存**を選択します。

## アーティファクトの最大サイズ {#maximum-artifacts-size}

ジョブアーティファクトのサイズ制限を設定して、ストレージの使用量を制限します。ジョブ内の各アーティファクトファイルのデフォルトの最大サイズは100 MBです。

`artifacts:reports`で定義されたジョブアーティファクトには、[異なる制限](#maximum-file-size-per-type-of-artifact)が適用される場合があります。異なる制限が適用される場合、小さい方の値が使用されます。

> [!note]
> この設定は最終アーカイブファイルのサイズに適用され、ジョブ内の個別のファイルには適用されません。

次のアイテムに対してアーティファクトのサイズ制限を設定できます。

- インスタンス: すべてのプロジェクトとグループに適用される基本設定です。
- グループ: グループ内のすべてのプロジェクトのインスタンス設定をオーバーライドします。
- プロジェクト: 特定のプロジェクトのインスタンスとグループの両方の設定をオーバーライドします。

GitLab.comの制限については、[アーティファクトの最大サイズ](../../user/gitlab_com/_index.md#cicd)を参照してください。

インスタンスのアーティファクトの最大サイズを変更するには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **アーティファクトサイズの上限 (MB)** テキストボックスに値を入力します。
1. **変更を保存**を選択します。

## 最大インクルード数 {#maximum-number-of-includes}

[`include`キーワード](../../ci/yaml/includes.md)を使用してパイプラインにインクルードできる外部YAMLファイルの数を制限します。この制限により、パイプラインにインクルードされるファイルが多すぎる場合のパフォーマンスの問題を防ぐことができます。

デフォルトでは、パイプラインには最大150ファイルをインクルードできます。パイプラインでこの制限を超えると、エラーが発生して失敗します。

パイプラインあたりのインクルードできるファイルの最大数を設定するには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **最大インクルード**テキストボックスに値を入力します。
1. **変更を保存**を選択します。

## CI/CD制限のインスタンス設定 {#cicd-limits-instance-configuration}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

いくつかのCI/CD制限は、インスタンスの設定を編集することによってのみ変更できます。

前提条件: 

- そのインスタンスの[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)にアクセスできる必要があります。

### パイプライン内のデプロイジョブの最大数 {#maximum-number-of-deployment-jobs-in-a-pipeline}

パイプライン内のデプロイジョブの最大数を制限できます。デプロイとは、[`environment`](../../ci/environments/_index.md)が指定されたジョブのことです。パイプライン内のデプロイ数は、パイプラインの作成時にチェックされます。デプロイが多すぎるパイプラインは、`deployments_limit_exceeded`エラーで失敗します。

制限を変更するには、次の[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)コマンドで`default`プランの制限を変更します:

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(ci_pipeline_deployments: 500)
```

デフォルトの制限は`500`です。制限を`0`に設定すると、無効になります。

### パイプライントリガー数を制限する {#limit-the-number-of-pipeline-triggers}

プロジェクトごとにパイプライントリガーの最大数を制限できます。この制限は、新しいトリガーが作成されるたびにチェックされます。

新しいトリガーによってパイプライントリガーの総数が制限を超える場合、そのトリガーは無効と見なされます。

制限を`0`に設定すると、無効になります。`25000`がデフォルトです。

この制限を`100`に設定するには、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)で以下を実行します:

```ruby
Plan.default.actual_limits.update!(pipeline_triggers: 100)
```

### 1日にパイプラインスケジュールによって作成できるパイプラインの数を制限する {#limit-the-number-of-pipelines-created-by-a-pipeline-schedule-each-day}

個々のパイプラインスケジュールが1日にトリガーできるパイプライン数を制限できます。

制限を超えてパイプラインを実行しようとするスケジュールは、最大実行頻度まで抑制されます。この頻度は、1,440（1日の分数）を制限値で割ることで計算されます。最大頻度ごとの例を示します。

- 1分に1回の場合、制限値は`1440`になります。
- 10分に1回の場合、制限値は`144`になります。
- 60分に1回の場合、制限値は`24`になります。

最小値は`24`、つまり60分に1回のパイプライン実行です。最大値の制限はありません。

GitLab Self-Managedインスタンスでこの制限を`1440`に設定するには、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
Plan.default.actual_limits.update!(ci_daily_pipeline_schedule_triggers: 1440)
```

### スケジュールされたパイプラインの最大頻度 {#maximum-scheduled-pipeline-frequency}

[スケジュールされたパイプライン](../../ci/pipelines/schedules.md)は任意の[cron値](../../topics/cron/_index.md)で設定できますが、スケジュールされた時刻に常に正確に実行されるわけではありません。「パイプラインスケジュールワーカー」と呼ばれる内部プロセスが、すべてのスケジュールされたパイプラインをキューに入れますが、継続的に実行されるわけではありません。ワーカーは独自のスケジュールで実行され、開始準備ができたスケジュールされたパイプラインは、ワーカーが次に実行されるときにのみキューに入れられます。スケジュールされたパイプラインは、ワーカーよりも頻繁に実行することはできません。

パイプラインスケジュールワーカーのデフォルト頻度は`3-59/10 * * * *`（`0:03`、`0:13`、`0:23`などから始まる10分ごと）です。GitLab.comのデフォルト頻度は、[GitLab.comの設定](../../user/gitlab_com/_index.md#cicd)に記載されています。

パイプラインスケジュールワーカーの頻度を変更するには:

1. インスタンスの`gitlab.rb`ファイルで`gitlab_rails['pipeline_schedule_worker_cron']`の値を編集します。
1. 変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

例えば、パイプラインの最大頻度を1日2回に設定するには、`pipeline_schedule_worker_cron`を`0 */12 * * *`（毎日`00:00`と`12:00`）のcron値に設定します。

多数のパイプラインスケジュールが同時に実行されると、追加の遅延が発生する可能性があります。パイプラインスケジュールワーカーは、システム負荷を分散するために、各[バッチ](https://gitlab.com/gitlab-org/gitlab/-/blob/3426be1b93852c5358240c5df40970c0ddfbdb2a/app/workers/pipeline_schedule_worker.rb#L13-14)間にわずかな遅延を置いてパイプラインを処理します。これにより、システム負荷によっては、パイプラインスケジュールが予定時刻から数分から1時間以上遅れて開始される可能性があります。

### セキュリティポリシープロジェクトに定義できるスケジュールルールの数を制限する {#limit-the-number-of-schedule-rules-defined-for-security-policy-project}

セキュリティポリシープロジェクトごとに、スケジュールルールの総数を制限できます。この制限は、スケジュールルールを含むポリシーが更新されるたびにチェックされます。新しいスケジュールルールによってスケジュールルールの総数が制限を超える場合、新しいスケジュールルールは処理されません。

デフォルトでは、GitLabは処理可能なスケジュールルールの数を制限しません。

この制限を設定するには、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)で以下を実行します:

```ruby
Plan.default.actual_limits.update!(security_policy_scan_execution_schedules: 100)
```

### グループおよびプロジェクトのCI/CD変数の制限 {#group-and-project-cicd-variable-limits}

グループおよびプロジェクトで定義できる[CI/CD変数](../../ci/variables/_index.md)の数は、インスタンス全体で制限されています。これらの制限は、新しい変数が作成されるたびにチェックされます。新しい変数によって変数の総数がそれぞれの制限を超える場合、新しい変数は作成されません。

これらの制限のいずれかの`default`プランを更新するには、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します:

- [グループレベルのCI/CD変数](../../ci/variables/_index.md#for-a-group)制限（グループごと、デフォルト: `30000`）:

  ```ruby
  Plan.default.actual_limits.update!(group_ci_variables: 40000)
  ```

- [プロジェクトレベルのCI/CD変数](../../ci/variables/_index.md#for-a-project)制限（プロジェクトごと、デフォルト: `8000`）:

  ```ruby
  Plan.default.actual_limits.update!(project_ci_variables: 10000)
  ```

### アーティファクトのタイプごとの最大ファイルサイズ {#maximum-file-size-per-type-of-artifact}

{{< history >}}

- GitLab 16.3で`ci_max_artifact_size_annotations`制限が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/38337)されました。
- `ci_max_artifact_size_jacoco`の制限は、GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159696)されました。
- GitLab 17.8で`ci_max_artifact_size_lsif`制限が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175684)されました。

{{< /history >}}

[`artifacts:reports`](../../ci/yaml/_index.md#artifactsreports)で定義されたジョブアーティファクトについて、Runnerによってアップロードされたファイルが最大ファイルサイズ制限を超える場合、そのファイルは拒否されます。この制限は、プロジェクトの[最大アーティファクトサイズ設定](#maximum-artifacts-size)と、指定されたアーティファクトタイプに対するインスタンスの制限を比較し、小さい方の値が適用されます。

制限はメガバイト単位で設定されるため、定義できる最小値は`1 MB`です。

アーティファクトのタイプごとにサイズ制限を設定できます。デフォルトが`0`の場合、その特定のアーティファクトタイプには制限がなく、プロジェクトの最大アーティファクトサイズ設定が使用されます。

| アーティファクト制限名                         | デフォルト値 |
|---------------------------------------------|---------------|
| `ci_max_artifact_size_accessibility`        | 0             |
| `ci_max_artifact_size_annotations`          | 0             |
| `ci_max_artifact_size_api_fuzzing`          | 0             |
| `ci_max_artifact_size_archive`              | 0             |
| `ci_max_artifact_size_browser_performance`  | 0             |
| `ci_max_artifact_size_cluster_applications` | 0             |
| `ci_max_artifact_size_cobertura`            | 0             |
| `ci_max_artifact_size_codequality`          | 0             |
| `ci_max_artifact_size_container_scanning`   | 0             |
| `ci_max_artifact_size_coverage_fuzzing`     | 0             |
| `ci_max_artifact_size_dast`                 | 0             |
| `ci_max_artifact_size_dependency_scanning`  | 0             |
| `ci_max_artifact_size_dotenv`               | 0             |
| `ci_max_artifact_size_jacoco`               | 0             |
| `ci_max_artifact_size_junit`                | 0             |
| `ci_max_artifact_size_license_management`   | 0             |
| `ci_max_artifact_size_license_scanning`     | 0             |
| `ci_max_artifact_size_load_performance`     | 0             |
| `ci_max_artifact_size_lsif`                 | 200 MB        |
| `ci_max_artifact_size_metadata`             | 0             |
| `ci_max_artifact_size_metrics_referee`      | 0             |
| `ci_max_artifact_size_metrics`              | 0             |
| `ci_max_artifact_size_network_referee`      | 0             |
| `ci_max_artifact_size_performance`          | 0             |
| `ci_max_artifact_size_requirements`         | 0             |
| `ci_max_artifact_size_requirements_v2`      | 0             |
| `ci_max_artifact_size_sast`                 | 0             |
| `ci_max_artifact_size_secret_detection`     | 0             |
| `ci_max_artifact_size_terraform`            | 5 MB          |
| `ci_max_artifact_size_trace`                | 0             |
| `ci_max_artifact_size_cyclonedx`            | 5 MB          |

たとえば、`ci_max_artifact_size_junit`制限をGitLab Self-Managedで10 MBに設定するには、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
Plan.default.actual_limits.update!(ci_max_artifact_size_junit: 10)
```

### ジョブログの最大ファイルサイズ {#maximum-file-size-for-job-logs}

GitLabのジョブログファイルサイズの制限は、デフォルトで100 MBです。制限を超過したジョブは失敗とマークされ、Runnerによって破棄されます。

この制限は[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)で変更できます。`ci_jobs_trace_size_limit`に、新しい値をメガバイト単位で設定します。

```ruby
Plan.default.actual_limits.update!(ci_jobs_trace_size_limit: 125)
```

GitLab Runnerには、Runner内の最大ログサイズを指定する[`output_limit`という設定](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section)もあります。Runnerの制限を超えたジョブは引き続き実行されますが、ログは制限に達すると切り詰められます。

### プロジェクトごとのアクティブなDASTプロファイルスケジュールの最大数 {#maximum-number-of-active-dast-profile-schedules-per-project}

プロジェクトごとのアクティブなDASTプロファイルスケジュールの数を制限できます。DASTプロファイルスケジュールは、アクティブまたは非アクティブにすることができます。

この制限は[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)で変更できます。`dast_profile_schedules`に新しい値を設定します。

```ruby
Plan.default.actual_limits.update!(dast_profile_schedules: 50)
```

### CIアーティファクトアーカイブの最大サイズ {#maximum-size-of-the-ci-artifacts-archive}

この設定は、[動的な子パイプライン](../../ci/pipelines/downstream_pipelines.md#dynamic-child-pipelines)におけるYAMLのサイズを制限するために使用されます。

CIアーティファクトアーカイブのデフォルトの最大サイズは5メガバイトです。

この制限を変更するには、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を使用します。CIアーティファクトアーカイブの最大サイズを更新するには、`max_artifacts_content_include_size`に新しい値を設定します。たとえば、20 MBに設定するには、次のコマンドを実行します。

```ruby
ApplicationSetting.update(max_artifacts_content_include_size: 20.megabytes)
```

### CI/CD設定YAMLファイルの最大サイズと最大深度 {#maximum-size-and-depth-of-cicd-configuration-yaml-files}

{{< history >}}

- GitLab 17.3で`max_yaml_size_bytes`のデフォルト値が[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826)されました。

{{< /history >}}

単一のCI/CD設定YAMLファイルに対するデフォルトの最大サイズは2メガバイトで、デフォルトの最大深度は100です。

これらの制限は、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)で変更できます。

- YAMLの最大サイズを更新するには、`max_yaml_size_bytes`に新しい値をメガバイト単位で設定します。

  ```ruby
  ApplicationSetting.update(max_yaml_size_bytes: 4.megabytes)
  ```

  `max_yaml_size_bytes`の値はYAMLファイルのサイズに直接関係するのではなく、関連オブジェクトに割り当てられるメモリに関係します。

- YAMLの最大深度を更新するには、`max_yaml_depth`に行数単位で新しい値を設定します。

  ```ruby
  ApplicationSetting.update(max_yaml_depth: 125)
  ```

### CI/CD設定全体の最大サイズ {#maximum-size-of-the-entire-cicd-configuration}

{{< history >}}

- GitLab 17.3で`max_yaml_size_bytes`のデフォルト値が[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826)されました。
- GitLab 17.3で`ci_max_total_yaml_size_bytes`のデフォルト値が[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826)されました。

{{< /history >}}

すべてのYAML設定ファイルを含む、パイプライン設定全体に対して割り当て可能な最大メモリ量（バイト単位）です。

デフォルト値は、[`max_yaml_size_bytes`](#maximum-size-and-depth-of-cicd-configuration-yaml-files)（デフォルトは2 MB）と[`ci_max_includes`](../../api/settings.md#available-settings)（デフォルトは150）を乗算することで算出されます。

- GitLab 17.2以前: 1 MB × 150 = `157286400`バイト（150 MB）。
- GitLab 17.3以降: 2 MB × 150 = `314572800`バイト（314.6 MB）。

この制限を変更するには、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を使用します。CI/CD設定に割り当て可能な最大メモリ量を更新するには、`ci_max_total_yaml_size_bytes`に新しい値を設定します。たとえば、20 MBに設定するには、次のコマンドを実行します。

```ruby
ApplicationSetting.update(ci_max_total_yaml_size_bytes: 20.megabytes)
```

### CI/CDジョブのアノテーション数を制限する {#limit-cicd-job-annotations}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/38337)されました。

{{< /history >}}

CI/CDジョブごとの[アノテーション](../../ci/yaml/artifacts_reports.md#artifactsreportsannotations)の最大数に制限を設定できます。

制限を`0`に設定すると、無効になります。`20`がデフォルトです。

インスタンスでこの制限を`100`に設定するには、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します。

```ruby
Plan.default.actual_limits.update!(ci_job_annotations_num: 100)
```

### CI/CDジョブのアノテーションファイルサイズを制限する {#limit-cicd-job-annotations-file-size}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/38337)されました。

{{< /history >}}

CI/CDジョブの[アノテーション](../../ci/yaml/artifacts_reports.md#artifactsreportsannotations)の最大サイズに制限を設定できます。

制限を`0`に設定すると、無効になります。デフォルトは80 KBです。

この制限を100 KBに設定するには、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)で以下を実行します:

```ruby
Plan.default.actual_limits.update!(ci_job_annotations_size: 100.kilobytes)
```

### CI/CDテーブルの最大データベースパーティションサイズ {#maximum-database-partition-size-for-cicd-tables}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189131)されました。
- GitLab 18.11で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/577314)されました。

{{< /history >}}

パーティション分割テーブルのパーティションが使用できる最大ディスク容量（バイト単位）。これを超えると新しいパーティションが自動的に作成されます。デフォルトは100 GBです。

この制限を変更するには、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を使用します。この制限を変更するには、`ci_partitions_size_limit`を新しい値で更新します。たとえば、20 GBに設定するには、次のコマンドを実行します。

```ruby
ApplicationSetting.update(ci_partitions_size_limit: 20.gigabytes)
```

### CI/CDパーティションの最大時間枠 {#maximum-time-window-for-cicd-partitions}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/577314)されました。

{{< /history >}}

新しいCIパーティションが作成され、システムが次のパーティションセットに切り替わるまでの時間枠（秒単位）。1か月から6か月の間にする必要があります。デフォルトは1か月（2592000秒）です。

この制限を変更するには、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を使用します。この制限を変更するには、`ci_partitions_in_seconds_limit`を新しい値で更新します。例えば、3か月に設定するには:

```ruby
ApplicationSetting.update(ci_partitions_in_seconds_limit: ChronicDuration.parse('3 months'))
```

### 自動パイプラインクリーンアップの最大保持期間 {#maximum-retention-period-for-automatic-pipeline-cleanup}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189191)されました。

{{< /history >}}

[自動パイプラインクリーンアップ](../../ci/pipelines/settings.md#automatic-pipeline-cleanup)の上限を設定します。デフォルトは1年です。

この制限を変更するには、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を使用します。この制限を変更するには、`ci_delete_pipelines_in_seconds_limit_human_readable`を新しい値で更新します。たとえば3年に設定するには、次のコマンドを実行します。

```ruby
ApplicationSetting.update(ci_delete_pipelines_in_seconds_limit_human_readable: '3 years')
```
