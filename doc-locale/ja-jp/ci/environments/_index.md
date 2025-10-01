---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 環境
description: 環境、変数、ダッシュボード、レビューアプリ。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab環境は、開発、ステージ、本番環境など、アプリケーションの特定のデプロイターゲットを表します。これは、ソフトウェアライフサイクルのさまざまな段階で複数の異なる設定を管理したり、コードをデプロイしたりするために使用します。

環境を使用すると、次のことが可能になります。

- デプロイプロセスの一貫性と再現可能性を維持する
- どのコードがどこにデプロイされているかを追跡する
- 問題が発生した場合に以前のバージョンにロールバックする
- 機密性の高い環境を不正な変更から保護する
- セキュリティ境界を維持するために、環境ごとにデプロイ変数を制御する
- 環境の健全性を監視し、問題が発生した場合はアラートを受信する

## 環境とデプロイを表示する {#view-environments-and-deployments}

前提要件:

- 非公開プロジェクトでは、レポーターロール以上が必要です。[環境の権限](#environment-permissions)を参照してください。

特定のプロジェクトの環境のリストを表示する方法はいくつかあります。

- 少なくとも1つの環境が利用可能な場合（つまり、環境が停止していない場合）は、プロジェクトの概要ページに表示されます。![利用可能な環境数のカウンターが表示されたプロジェクト概要ページ](img/environments_project_home_v15_9.png)

- 左側のサイドバーで、**操作 > 環境**を選択します。環境が表示されます。

  ![環境名、ステータス、その他の関連情報が表示されている、GitLabプロジェクトで利用可能な環境のリスト](img/environments_list_v14_8.png)

- 環境のデプロイリストを表示するには、`staging`などの環境名を選択します。![デプロイ履歴と関連情報が表示されている、選択した環境のデプロイのリスト](img/deployments_list_v13_10.png)

  デプロイがこのリストに表示されるのは、デプロイジョブによってそれらが作成された後です。

- デプロイパイプライン内のすべての手動ジョブのリストを表示するには、**実行**（{{< icon name="play" >}}）ドロップダウンリストを選択します。

  ![デプロイパイプラインの手動ジョブを表示する](img/view_manual_jobs_v17_10.png)

### 環境URL {#environment-url}

{{< history >}}

- GitLab 15.2で`soft_validation_on_external_url`[フラグ](../../administration/feature_flags/_index.md)とともに任意のURLを保持できるように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/337417)されました。デフォルトでは無効になっています。
- GitLab 15.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/337417)になりました。[機能フラグ`soft_validation_on_external_url`](https://gitlab.com/gitlab-org/gitlab/-/issues/367206)は削除されました。

{{< /history >}}

[環境URL](../yaml/_index.md#environmenturl)は、GitLabのいくつかの場所に表示されます。

- マージリクエスト内のリンクとして表示: ![マージリクエスト内の環境URL](img/environments_mr_review_app_v11_10.png)
- 環境ビュー内のボタンとして: ![環境ビューからライブ環境を開く](img/environments_open_live_environment_v14_8.png)
- デプロイビュー内のボタンとして: ![デプロイ内の環境URL](img/deployments_view_v11_10.png)

マージリクエストでこの情報が表示されるのは、次の条件を満たす場合です。

- マージリクエストが最終的にデフォルトブランチ（通常は`main`）にマージされること。
- そのブランチも環境（`staging`や`production`など）にデプロイされること。

次に例を示します。

![マージリクエストの環境URL](img/environments_link_url_mr_v10_1.png)

#### ソースファイルから公開ページに移動する {#go-from-source-files-to-public-pages}

GitLabの[ルートマップ](../review_apps/_index.md#route-maps)を使用すると、ソースファイルから、レビューアプリ用に設定された環境の公開ページに直接移動できます。

## 環境の種類 {#types-of-environments}

環境は、静的または動的のいずれかです。

静的環境:

- 通常、継続的なデプロイによって再利用される。
- 静的な名前が付けられる。例: `staging`、`production`。
- 手動で、またはCI/CDパイプラインの一部として作成される。

動的環境:

- 通常、CI/CDパイプラインで作成され、単一のデプロイでのみ使用された後、停止または削除される。
- 動的な名前が付けられる（通常、CI/CD変数の値に基づく）。
- [レビューアプリ](../review_apps/_index.md)の機能の1つ。

環境は、その[停止ジョブ](../yaml/_index.md#environmenton_stop)が実行されたかどうかに応じて、次の3つのステータスのいずれかになります。

- `available`: この環境が存在する。デプロイが存在する場合があります。
- `stopping`: _停止ジョブ_が開始された。停止ジョブが定義されていない場合、このステータスは適用されません。
- `stopped`: _停止ジョブ_が実行されたか、ユーザーが手動でジョブを停止した。

## 静的環境を作成する {#create-a-static-environment}

UIまたは`.gitlab-ci.yml`ファイルで静的環境を作成できます。

### UIの場合 {#in-the-ui}

前提要件:

- デベロッパーロール以上が必要です。

UIで静的環境を作成するには、次のようにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作 > 環境**を選択します。
1. **環境を作成**を選択します。
1. フィールドに入力します。
1. **保存**を選択します。

### `.gitlab-ci.yml`ファイルの場合 {#in-your-gitlab-ciyml-file}

前提要件:

- デベロッパーロール以上が必要です。

`.gitlab-ci.yml`ファイルで静的環境を作成するには、次のようにします。

1. `deploy`ステージでジョブを定義します。
1. ジョブで、環境の`name`と`url`を定義します。その名前の環境がパイプラインの実行時に存在しない場合は、作成されます。

{{< alert type="note" >}}

一部の文字は環境名に使用できません。`environment`キーワードの詳細については、[`.gitlab-ci.yml`キーワードリファレンス](../yaml/_index.md#environment)を参照してください。

{{< /alert >}}

たとえば、`staging`という名前の環境を作成し、URLを`https://staging.example.com`に設定するには、次のようにします。

```yaml
deploy_staging:
  stage: deploy
  script:
    - echo "Deploy to staging server"
  environment:
    name: staging
    url: https://staging.example.com
```

## 動的環境を作成する {#create-a-dynamic-environment}

動的環境を作成するには、各パイプラインに一意の[CI/CD変数](#cicd-variables)を使用します。

前提要件:

- デベロッパーロール以上が必要です。

`.gitlab-ci.yml`ファイルで動的環境を作成するには、次のようにします。

1. `deploy`ステージでジョブを定義します。
1. ジョブで、次の環境属性を定義します。
   - `name`: `$CI_COMMIT_REF_SLUG`のような関連するCI/CD変数を使用します。必要に応じて、環境名に静的なプレフィックスを追加します。これにより、同じプレフィックスを持つすべての環境が[UIでグループ化](#group-similar-environments)されます。
   - `url`: （オプション）ホスト名のプレフィックスとして、`$CI_ENVIRONMENT_SLUG`のような関連するCI/CD変数を指定します。

{{< alert type="note" >}}

一部の文字は環境名に使用できません。`environment`キーワードの詳細については、[`.gitlab-ci.yml`キーワードリファレンス](../yaml/_index.md#environment)を参照してください。

{{< /alert >}}

次の例では、`deploy_review_app`ジョブが実行されるたびに、環境の名前とURLが一意の値を使用して定義されます。

```yaml
deploy_review_app:
  stage: deploy
  script: make deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: never
    - if: $CI_COMMIT_BRANCH
```

### 動的な環境URLを設定する {#set-a-dynamic-environment-url}

一部の外部ホスティングプラットフォームでは、デプロイごとにランダムなURLを生成します（例: `https://94dd65b.amazonaws.com/qa-lambda-1234567`）。そのため、`.gitlab-ci.yml`ファイルでURLを参照することが困難になります。

この問題に対処するため、変数のセットを返すようにデプロイジョブを設定できます。このような変数には、外部サービスが動的に生成するURLが含まれます。GitLabは、[dotenv（`.env`）](https://github.com/bkeepers/dotenv)ファイル形式をサポートしており、`.env`ファイルで定義された変数を使用して`environment:url`の値を展開します。

この機能を使用するには、`.gitlab-ci.yml`で[`artifacts:reports:dotenv`](../yaml/artifacts_reports.md#artifactsreportsdotenv)キーワードを指定します。

また、`environment:url`に`https://$DYNAMIC_ENVIRONMENT_URL`のようなURLの静的な部分を指定することもできます。`DYNAMIC_ENVIRONMENT_URL`の値が`example.com`の場合、最終結果は`https://example.com`となります。

`review/your-branch-name`環境に割り当てられたURLは、UIで確認できます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[Set dynamic environment URLs after a job finished](https://youtu.be/70jDXtOf4Ig)（ジョブ完了後に動的URLを設定する）を参照してください。

次の例では、レビューアプリがマージリクエストごとに新しい環境を作成します。

- `review`ジョブはプッシュごとにトリガーされ、`review/your-branch-name`という名前の環境を作成または更新します。環境URLは`$DYNAMIC_ENVIRONMENT_URL`に設定されます。
- `review`ジョブが完了すると、GitLabは`review/your-branch-name`環境のURLを更新します。`deploy.env`レポートアーティファクトを解析し、変数のリストをランタイム作成済みとして登録し、`environment:url: $DYNAMIC_ENVIRONMENT_URL`を展開してそれを環境URLに設定します。

```yaml
review:
  script:
    - DYNAMIC_ENVIRONMENT_URL=$(deploy-script)                                 # In script, get the environment URL.
    - echo "DYNAMIC_ENVIRONMENT_URL=$DYNAMIC_ENVIRONMENT_URL" >> deploy.env    # Add the value to a dotenv file.
  artifacts:
    reports:
      dotenv: deploy.env                                                       # Report back dotenv file to rails.
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: $DYNAMIC_ENVIRONMENT_URL                                              # and set the variable produced in script to `environment:url`
    on_stop: stop_review

stop_review:
  script:
    - ./teardown-environment
  when: manual
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
```

次の点に注意してください。

- `stop_review`はdotenvレポートアーティファクトを生成しないため、`DYNAMIC_ENVIRONMENT_URL`環境変数を認識しません。このため、`stop_review`ジョブでは`environment:url`を設定しないでください。
- 環境URLが無効な場合（たとえば、URLが不正な形式の場合）、システムは環境URLを更新しません。
- `stop_review`で実行されるスクリプトがリポジトリにのみ存在し、`GIT_STRATEGY: none`または`GIT_STRATEGY: empty`を使用できない場合、これらのジョブに対して[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)を設定します。これにより、フィーチャーブランチが削除された後でも、Runnerがリポジトリをフェッチできるようになります。詳細については、[Runnerのrefspec](../pipelines/_index.md#ref-specs-for-runners)を参照してください。

{{< alert type="note" >}}

WindowsのRunnerの場合、PowerShellの`Add-Content`コマンドを使用して`.env`ファイルに書き込む必要があります。

{{< /alert >}}

```powershell
Add-Content -Path deploy.env -Value "DYNAMIC_ENVIRONMENT_URL=$DYNAMIC_ENVIRONMENT_URL"
```

## 環境のデプロイ階層 {#deployment-tier-of-environments}

`production`のような[業界標準](https://en.wikipedia.org/wiki/Deployment_environment)の環境名を使用する代わりに、`customer-portal`のようなコード名を使用したい場合があります。`customer-portal`のような名前を使用しても技術的には問題ありませんが、このような名前では、その環境が本番環境であることを示せません。また、[デプロイ頻度](../../user/analytics/dora_metrics.md#how-deployment-frequency-is-calculated)などのメトリクスの計算方法に影響を及ぼす可能性があります。

特定の環境が特定の用途であることを示すために、次のような階層を使用できます。

| 環境の階層 | 環境名の例 |
|------------------|---------------------------|
| `production`     | Production、Live          |
| `staging`        | Staging、Model、Demo      |
| `testing`        | Test、QC                  |
| `development`    | Dev、[Review apps](../review_apps/_index.md)、Trunk |
| `other`          |                           |

デフォルトでは、GitLabは[環境名](../yaml/_index.md#environmentname)に基づいて階層を想定します。UIを使用して環境階層を設定することはできません。代わりに、[`deployment_tier`キーワード](../yaml/_index.md#environmentdeployment_tier)を使用して階層を指定できます。

### 環境名を変更する {#rename-an-environment}

{{< history >}}

- APIを使用した環境名の変更は、GitLab 15.9で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/338897)になりました。
- APIを使用した環境名の変更は、GitLab 16.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/338897)されました。

{{< /history >}}

環境名は変更できません。

環境名の変更と同じ結果を得るには、次のようにします。

1. [既存の環境を停止します](#stop-an-environment-by-using-the-ui)。
1. [既存の環境を削除します](#delete-an-environment)。
1. 希望する名前で[新しい環境を作成します](#create-a-static-environment)。

## CI/CD変数 {#cicd-variables}

環境とデプロイをカスタマイズするには、任意の[定義済みCI/CD変数](../variables/predefined_variables.md)を使用して、カスタムCI/CD変数を定義します。

### CI/CD変数の環境スコープを制限する {#limit-the-environment-scope-of-a-cicd-variable}

デフォルトでは、すべての[CI/CD変数](../variables/_index.md)をパイプライン内のすべてのジョブで利用できます。ジョブ内のテストツールが侵害された場合、そのツールはジョブで利用できるすべてのCI/CD変数の取得を試みる可能性があります。このようなサプライチェーン攻撃を軽減するため、機密性の高い変数の環境スコープは、必要とするジョブのみに制限する必要があります。

CI/CD変数を利用できる環境を定義して、CI/CD変数の環境スコープを制限します。デフォルトの環境スコープは、ワイルドカードの`*`であり、すべてのジョブが変数にアクセスできます。

特定の環境を選択するには、特定のマッチングを使用します。たとえば、変数の環境スコープを`production`に設定すると、その変数にアクセスできるのは、[環境](../yaml/_index.md#environment)が`production`のジョブのみです。

ワイルドカードマッチング（`*`）を使用して、特定の環境グループを選択することもできます。たとえば、`review/*`と指定すると、すべての[レビューアプリ](../review_apps/_index.md)が対象になります。

たとえば、次の4つの環境があるとします。

- `production`
- `staging`
- `review/feature-1`
- `review/feature-2`

これらに対する環境スコープのマッチングは次のとおりです。

| ↓ スコープ / 環境 → | `production` | `staging` | `review/feature-1` | `review/feature-2` |
|:------------------------|:-------------|:----------|:-------------------|:-------------------|
| `*`                     | マッチ        | マッチ     | マッチ              | マッチ              |
| `production`            | マッチ        |           |                    |                    |
| `staging`               |              | マッチ     |                    |                    |
| `review/*`              |              |           | マッチ              | マッチ              |
| `review/feature-1`      |              |           | マッチ              |                    |

環境ごとにスコープ設定された変数は、[`rules`](../yaml/_index.md#rules)や[`include`](../yaml/_index.md#include)と組み合わせて使用しないでください。パイプラインの作成時にGitLabがパイプライン設定を検証する際、変数が定義されていない可能性があります。

## 環境を検索する {#search-environments}

{{< history >}}

- GitLab 15.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/10754)されました。
- [フォルダー内の環境の検索](https://gitlab.com/gitlab-org/gitlab/-/issues/373850)は、GitLab 15.7で[`enable_environments_search_within_folder`機能フラグ](https://gitlab.com/gitlab-org/gitlab/-/issues/382108)とともに導入されました。デフォルトでは有効になっています。
- GitLab 17.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/382108)になりました。機能フラグ`enable_environments_search_within_folder`は削除されました。

{{< /history >}}

名前で環境を検索するには、次のようにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作 > 環境**を選択します。
1. 検索ボックスに検索語句を入力します。
   - **検索語句は3文字以上**でなければなりません。
   - マッチングは環境名の先頭から適用されます。
     - たとえば、`devel`は環境名`development`と一致しますが、`elop`は一致しません。
   - フォルダー名形式の環境では、マッチングはベースフォルダー名の後から適用されます。
     - たとえば、名前が`review/test-app`の場合、検索語句`test`は`review/test-app`と一致します。
     - `review/test`のようにフォルダー名にプレフィックスを付けて検索すると、`review/test-app`と一致します。

## 類似の環境をグループ化する {#group-similar-environments}

UIで、環境を折りたたみ可能なセクションにグループ化できます。

たとえば、すべての環境名が`review`で始まる場合、UIではそれらの環境がその語句の見出しの下にグループ化されます。

![環境グループ](img/environments_dynamic_groups_v13_10.png)

次の例は、環境名を`review`で始める方法を示しています。`$CI_COMMIT_REF_SLUG`変数には、実行時にブランチ名が設定されます。

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
```

## 環境を停止する {#stopping-an-environment}

環境の停止とは、ターゲットサーバー上でそのデプロイにアクセスできなくなることを意味します。環境を削除するには、その前に環境を停止する必要があります。

環境を停止するために`on_stop`アクションを使用すると、そのジョブが[アーカイブ](../../administration/settings/continuous_integration.md#archive-pipelines)されていなければ実行されます。

### UIを使用して環境を停止する {#stop-an-environment-by-using-the-ui}

{{< alert type="note" >}}

`on_stop`アクションをトリガーし、環境ビューから手動で環境を停止するには、停止ジョブとデプロイジョブが同じ[`resource_group`](../yaml/_index.md#resource_group)に属している必要があります。

{{< /alert >}}

GitLab UIで環境を停止するには、次のようにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作 > 環境**を選択します。
1. 停止する環境の横にある**停止**を選択します。
1. 確認ダイアログで、**環境を停止**を選択します。

### デフォルトの停止動作 {#default-stopping-behavior}

GitLabは、関連付けられたブランチが削除またはマージされると、環境を自動的に停止します。この動作は、明示的な`on_stop` CI/CDジョブが定義されていない場合でも適用されます。

ただし、[イシュー428625](https://gitlab.com/gitlab-org/gitlab/-/issues/428625)では、本番環境とステージング環境については、明示的な`on_stop` CI/CDジョブが定義されている場合にのみ停止するように、この動作を変更することが提案されています。

環境の停止動作は、環境APIの[`auto_stop_setting`](../../api/environments.md#update-an-existing-environment)パラメータで設定できます。

### ブランチ削除時に環境を停止する {#stop-an-environment-when-a-branch-is-deleted}

ブランチが削除されたときに環境を停止するように設定できます。

次の例では、`deploy_review`ジョブが`stop_review`ジョブを呼び出し、環境をクリーンアップして停止します。

- 両方のジョブには、同じ[`rules`](../yaml/_index.md#rules)設定または[`only/except`](../yaml/deprecated_keywords.md#only--except)設定が必要です。設定が同じでないと、`deploy_review`ジョブを含むすべてのパイプラインに`stop_review`ジョブが含まれない可能性があり、`action: stop`をトリガーして環境を自動的に停止できなくなる可能性があります。
- 環境を開始したジョブより後のステージにある場合、[`action: stop`を含むジョブは実行されない可能性があります](#the-job-with-action-stop-doesnt-run)。
- [マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)を使用できない場合は、`stop_review`ジョブで[`GIT_STRATEGY`](../runners/configure_runners.md#git-strategy)を`none`または`empty`に設定します。その後、ブランチが削除された後に[Runner](https://docs.gitlab.com/runner/)がコードをチェックアウトしようとすることはありません。

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com
    on_stop: stop_review

stop_review:
  stage: deploy
  script:
    - echo "Remove review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

### マージリクエストのマージまたは完了時に環境を停止する {#stop-an-environment-when-a-merge-request-is-merged-or-closed}

[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)設定を使用すると、`stop`トリガーが自動的に有効になります。

次の例では、`deploy_review`ジョブが`stop_review`ジョブを呼び出し、環境をクリーンアップして停止します。

- [**パイプラインが完了している**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)設定が有効になっている場合、`stop_review`ジョブに対して[`allow_failure: true`](../yaml/_index.md#allow_failure)キーワードを設定することで、パイプラインとマージリクエストがブロックされるのを防ぐことができます。

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    on_stop: stop_review
  rules:
    - if: $CI_MERGE_REQUEST_ID

stop_review:
  stage: deploy
  script:
    - echo "Remove review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  rules:
    - if: $CI_MERGE_REQUEST_ID
      when: manual
```

{{< alert type="note" >}}

この機能をマージトレインと組み合わせて使用する場合、[重複パイプラインが回避される](../jobs/job_rules.md#avoid-duplicate-pipelines)場合にのみ`stop`ジョブがトリガーされます。

{{< /alert >}}

### 一定期間後に環境を停止する {#stop-an-environment-after-a-certain-time-period}

一定期間後に自動的に停止するように環境を設定できます。

{{< alert type="note" >}}

リソースの制限により、環境を停止するバックグラウンドワーカーは1時間に1回しか実行されません。つまり、環境は指定した正確な時間の経過後に停止されるのではなく、バックグラウンドワーカーが期限切れの環境を検出したときに停止されます。

{{< /alert >}}

`.gitlab-ci.yml`ファイルで、[`environment:auto_stop_in`](../yaml/_index.md#environmentauto_stop_in)キーワードを指定します。`1 hour and 30 minutes`や`1 day`など、自然言語で期間を指定します。指定した期間が経過すると、GitLabは環境を停止するジョブを自動的にトリガーします。

次の例では、以下が実行されます。

- マージリクエストの各コミットは、`review_app`ジョブをトリガーします。このジョブは、最新の変更を環境にデプロイして有効期限をリセットします。
- 環境が1週間以上無効である場合、GitLabは`stop_review_app`ジョブを自動的にトリガーして環境を停止します。

```yaml
review_app:
  script: deploy-review-app
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    on_stop: stop_review_app
    auto_stop_in: 1 week
  rules:
    - if: $CI_MERGE_REQUEST_ID

stop_review_app:
  script: stop-review-app
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  rules:
    - if: $CI_MERGE_REQUEST_ID
      when: manual
```

[`environment:action`](../yaml/_index.md#environmentaction)キーワードを使用して、環境の停止がスケジュールされている期間をリセットできます。詳細については、[準備または検証目的で環境にアクセスする](#access-an-environment-for-preparation-or-verification-purposes)を参照してください。

#### 環境のスケジュールされた停止日時を表示する {#view-an-environments-scheduled-stop-date-and-time}

環境が[指定された期間後に停止するようにスケジュール](#stop-an-environment-after-a-certain-time-period)されている場合は、その有効期限の日時を表示できます。

環境の有効期限の日時を表示するには、次のようにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作 > 環境**を選択します。
1. 環境名を選択します。

有効期限の日時は、左上隅にある環境名の横に表示されます。

#### 環境のスケジュールされた停止日時をオーバーライドする {#override-an-environments-scheduled-stop-date-and-time}

環境が[指定された期間後に停止するようにスケジュール](#stop-an-environment-after-a-certain-time-period)されている場合は、その有効期限をオーバーライドできます。

UIで環境の有効期限をオーバーライドするには、次のようにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作 > 環境**を選択します。
1. 環境名を選択します。
1. 右上隅の画鋲（{{< icon name="thumbtack" >}}）を選択します。

`.gitlab-ci.yml`で環境の有効期限をオーバーライドするには、次のようにします。

1. プロジェクトの`.gitlab-ci.yml`を開きます。
1. 対応するデプロイジョブの`auto_stop_in`設定を`auto_stop_in: never`に更新します。

`auto_stop_in`設定がオーバーライドされ、環境は手動で停止されるまでアクティブな状態を維持します。

### 古い環境をクリーンアップする {#clean-up-stale-environments}

{{< history >}}

- GitLab 15.8で`stop_stale_environments`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108616)されました。デフォルトでは無効になっています。
- GitLab 15.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112098)になりました。機能フラグ`stop_stale_environments`は削除されました。

{{< /history >}}

プロジェクト内の古い環境を停止する場合は、古い環境をクリーンアップします。

前提要件:

- メンテナーロール以上が必要です。

古い環境をクリーンアップするには、次のようにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作 > 環境**を選択します。
1. **環境のクリーンアップ**を選択します。
1. 環境を古いと判定する基準となる日付を選択します。
1. **クリーンアップ**を選択します。

指定した日付以降に更新されていないアクティブな環境は停止されます。保護環境は無視され、停止されません。

### 環境の停止時にパイプラインジョブを実行する {#run-a-pipeline-job-when-environment-is-stopped}

{{< history >}}

- GitLab 16.9で機能フラグ`environment_stop_actions_include_all_finished_deployments`が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/435128)されました。デフォルトでは無効になっています。
- GitLab 17.0で機能フラグ`environment_stop_actions_include_all_finished_deployments`は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150932)されました。

{{< /history >}}

環境のデプロイジョブで[`on_stop`アクション](../yaml/_index.md#environmenton_stop)を使用して、環境の停止ジョブを定義できます。

環境を停止すると、最新の完了したパイプラインに含まれる完了したデプロイに対応する停止ジョブが実行されます。デプロイまたはパイプラインは、ステータスが成功、キャンセル、または失敗になったときに完了となります。

前提要件:

- デプロイジョブと停止ジョブの両方に、同じルールまたは「次のみ」/「次を除く」の設定が必要です。
- 停止ジョブでは、次のキーワードを定義する必要があります。
  - `when`。次のいずれかで定義されます。
    - [ジョブレベル](../yaml/_index.md#when)。
    - [ルールセクション内](../yaml/_index.md#rules)。`rules`と`when: manual`を使用する場合は、ジョブが実行されなくてもパイプラインを完了できるように、[`allow_failure: true`](../yaml/_index.md#allow_failure)も設定する必要があります。
  - `environment:name`
  - `environment:action`

次の例では、以下が実行されます。

- `review_app`ジョブは、最初のジョブが完了した後に、`stop_review_app`ジョブを呼び出します。
- `stop_review_app`は、`when`で定義された内容に基づいてトリガーされます。この場合は、`manual`に設定されているため、実行するにはGitLab UIからの[手動操作](../jobs/job_control.md#create-a-job-that-must-be-run-manually)が必要です。
- `GIT_STRATEGY`は`none`に設定されています。`stop_review_app`ジョブが[自動的にトリガー](#stopping-an-environment)された場合、ブランチが削除された後にRunnerがコードをチェックアウトしようとすることはありません。

```yaml
review_app:
  stage: deploy
  script: make deploy-app
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com
    on_stop: stop_review_app

stop_review_app:
  stage: deploy
  variables:
    GIT_STRATEGY: none
  script: make delete-app
  when: manual
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
```

### 環境に対する複数の停止アクション {#multiple-stop-actions-for-an-environment}

{{< history >}}

- GitLab 15.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/358911)になりました。[機能フラグ`environment_multiple_stop_actions`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86685)は削除されました。

{{< /history >}}

環境に対して複数の**並列**停止アクションを設定するには、`.gitlab-ci.yml`ファイルで定義されているとおり、同じ`environment`に対する複数の[デプロイジョブ](../jobs/_index.md#deployment-jobs)にわたって[`on_stop`](../yaml/_index.md#environmenton_stop)キーワードを指定します。

環境が停止されると、成功したデプロイジョブに対応する`on_stop`アクションのみが、特定の順序なく並列に実行されます。

{{< alert type="note" >}}

環境に対するすべての`on_stop`アクションは、同じパイプラインに属している必要があります。[ダウンストリームパイプライン](../pipelines/downstream_pipelines.md)で複数の`on_stop`アクションを使用するには、親パイプラインで環境アクションを設定する必要があります。詳細については、[デプロイのダウンストリームパイプライン](../pipelines/downstream_pipelines.md#advanced-example)を参照してください。

{{< /alert >}}

次の例では、`test`環境に対して次の2つのデプロイジョブがあります。

- `deploy-to-cloud-a`
- `deploy-to-cloud-b`

環境が停止されると、システムは`teardown-cloud-a`と`teardown-cloud-b`の`on_stop`アクションを並列に実行します。

```yaml
deploy-to-cloud-a:
  script: echo "Deploy to cloud a"
  environment:
    name: test
    on_stop: teardown-cloud-a

deploy-to-cloud-b:
  script: echo "Deploy to cloud b"
  environment:
    name: test
    on_stop: teardown-cloud-b

teardown-cloud-a:
  script: echo "Delete the resources in cloud a"
  environment:
    name: test
    action: stop
  when: manual

teardown-cloud-b:
  script: echo "Delete the resources in cloud b"
  environment:
    name: test
    action: stop
  when: manual
```

### `on_stop`アクションを実行せずに環境を停止する {#stop-an-environment-without-running-the-on_stop-action}

定義済みの[`on_stop`](../yaml/_index.md#environmenton_stop)アクションを実行せずに環境を停止する必要がある場合があります。たとえば、[コンピューティングクォータ](../pipelines/compute_minutes.md)を消費せずに多数の環境を削除したい場合などです。

定義済みの`on_stop`アクションを実行せずに環境を停止するには、パラメータ`force=true`を指定して[環境の停止API](../../api/environments.md#stop-an-environment)を実行します。

### 環境を削除する {#delete-an-environment}

環境とそのすべてのデプロイを削除する場合は、環境を削除します。

前提要件:

- デベロッパーロール以上が必要です。
- 削除する前に、環境を[停止](#stopping-an-environment)する必要があります。

環境を削除するには、次のようにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作 > 環境**を選択します。
1. **停止中**タブを選択します。
1. 削除する環境の横にある**環境を削除**を選択します。
1. 確認ダイアログで、**環境を削除**を選択します。

## 準備または検証目的で環境にアクセスする {#access-an-environment-for-preparation-or-verification-purposes}

{{< history >}}

- GitLab 17.7で、`prepare`アクションと`access`アクションに対して`auto_stop_in`をリセットするように[更新](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)されました。

{{< /history >}}

検証や準備など、さまざまな目的で環境にアクセスするジョブを定義できます。これにより、デプロイの作成を事実上回避できるため、CDワークフローをより正確に調整できます。

そのためには、ジョブの`environment`セクションに`action: prepare`、`action: verify`、または`action: access`を追加します。

```yaml
build:
  stage: build
  script:
    - echo "Building the app"
  environment:
    name: staging
    action: prepare
    url: https://staging.example.com
```

これにより、環境ごとにスコープ設定された変数にアクセスできるようになり、不正なアクセスからビルドを保護するために使用できます。また、[古いデプロイジョブを防止](deployment_safety.md#prevent-outdated-deployment-jobs)機能を回避するためにも有効です。

環境が一定期間後に停止するように設定されている場合、`access`アクションまたは`prepare`アクションを含むジョブは、スケジュール済みの停止時刻をリセットします。スケジュール済みの停止時刻をリセットする際は、環境に対する直近の成功したデプロイジョブで設定された[`environment:auto_stop_in`](../yaml/_index.md#environmentauto_stop_in)が使用されます。たとえば、直近のデプロイで`auto_stop_in: 1 week`が使用され、その後`action: access`を含むジョブによってアクセスされた場合、その環境は、アクセスジョブの完了時点から1週間後に停止するように再スケジュールされます。

スケジュール済みの停止時刻を変更せずに環境にアクセスするには、`verify`アクションを使用します。

## 環境インシデント管理 {#environment-incident-management}

本番環境は、制御不能な理由を含め、予期せず停止する可能性があります。たとえば、外部依存関係、インフラストラクチャ、または人為的エラーなどの問題が、環境に重大な悪影響を及ぼす可能性があります。次に例を示します。

- 依存しているクラウドサービスが停止する。
- サードパーティのライブラリが更新され、アプリケーションとの互換性がなくなる。
- サーバーの脆弱なエンドポイントに対してDDoS攻撃を受ける。
- オペレーターがインフラストラクチャを誤って設定する。
- 本番環境のアプリケーションコードにバグが入り込む。

[インシデント管理](../../operations/incident_management/_index.md)を使用すると、即時対応が必要な重大な問題が発生した際にアラートを受け取ることができます。

### 環境の最新アラートを表示する {#view-the-latest-alerts-for-environments}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[アラートインテグレーションを設定](../../operations/incident_management/integrations.md#configuration)すると、環境に関するアラートが環境ページに表示されます。最も重大度の高いアラートが表示されるため、即時対応が必要な環境を特定できます。

![環境のアラート](img/alert_for_environment_v13_4.png)

アラートをトリガーした問題が解決されると、そのアラートは削除され、環境ページに表示されなくなります。

[ロールバック](deployments.md#retry-or-roll-back-a-deployment)が必要となるアラートの場合、環境ページのデプロイタブを選択して、ロールバックするデプロイを選択します。

### 自動ロールバック {#auto-rollback}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

通常の継続的デプロイワークフローでは、本番環境へのデプロイ前にCIパイプラインですべてのコミットをテストします。しかしそれでも、問題のあるコードが本番環境に導入される可能性はゼロではありません。たとえば、論理的には正しくても非効率なコードは、深刻なパフォーマンス低下を引き起こすにもかかわらず、テストには合格する可能性があります。オペレーターやサイトリライアビリティエンジニアリング（SRE）は、これらの問題をできるだけ早く検出するためにシステムをモニタリングしています。問題のあるデプロイを発見した場合、以前の安定したバージョンにロールバックできます。

GitLab自動ロールバックは、[重大なアラート](../../operations/incident_management/alerts.md)が検出された際にロールバックを自動的にトリガーし、このワークフローを簡素化します。GitLabがロールバックする際に適切な環境を選択できるようにするには、アラートに`gitlab_environment_name`キーと環境名を含める必要があります。GitLabは、直近の成功したデプロイを選択して再度デプロイします。

GitLab自動ロールバックの制限事項:

- アラートが検出された際にデプロイが実行中の場合、ロールバックはスキップされます。
- ロールバックを実行できるのは3分に1回のみです。複数のアラートが同時に検出された場合、実行されるロールバックは1回のみです。

GitLab自動ロールバックは、デフォルトで無効になっています。有効にするには、次のようにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **自動デプロイロールバック**を展開します。
1. **自動ロールバックを有効化**チェックボックスをオンにします。
1. **変更を保存**を選択します。

## 環境の権限 {#environment-permissions}

自分のロールに応じて、公開プロジェクトと非公開プロジェクトで環境を操作できます。

### 環境を表示する {#view-environments}

- 公開プロジェクトでは、メンバー以外を含め、すべてのユーザーが環境のリストを表示できます。
- 非公開プロジェクトでは、環境のリストを表示するにはレポーターロール以上が必要です。

### 環境を作成および更新する {#create-and-update-environments}

- 新しい環境を作成したり、既存の保護されていない環境を更新したりするには、デベロッパーロール以上が必要です。
- 既存の環境が保護されていてアクセス権限がない場合、その環境を更新することはできません。

### 環境を停止および削除する {#stop-and-delete-environments}

- 保護されていない環境を停止または削除するには、デベロッパーロール以上が必要です。
- 環境が保護されていてアクセス権限がない場合、その環境を停止または削除することはできません。

### 保護環境でデプロイジョブを実行する {#run-deployment-jobs-in-protected-environments}

保護されたブランチにプッシュまたはマージできる場合:

- レポーターロール以上が必要です。

保護ブランチにプッシュできない場合:

- レポーターロールを持つグループのメンバーでなければなりません。

[保護環境へのデプロイ専用アクセス](protected_environments.md#deployment-only-access-to-protected-environments)を参照してください。

## Webターミナル（非推奨） {#web-terminals-deprecated}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

{{< /alert >}}

デプロイサービス（たとえば[Kubernetesインテグレーション](../../user/infrastructure/clusters/_index.md)）を使用して環境にデプロイする場合、GitLabはその環境へのターミナルセッションを開くことができます。これにより、Webブラウザから移動することなく問題をデバッグできます。

Webターミナルはコンテナベースのデプロイであり、基本ツール（エディタなど）はなく、いつでも停止または再起動される可能性があります。停止または再起動されると、変更内容がすべて失われます。Webターミナルは包括的なオンラインIDEではなく、デバッグツールとして扱う必要があります。

Webターミナルに関する注意事項:

- プロジェクトのメンテナーとオーナーのみが利用できる。
- [有効にする](../../administration/integration/terminal.md)必要がある。

UIでWebターミナルを表示するには、次のいずれかを実行します。

- **アクション**メニューから、**ターミナル**を選択します。

  ![環境インデックスのターミナルボタン](img/environments_terminal_button_on_index_v14_3.png)

- 特定の環境のページで、右側の**ターミナル**（{{< icon name="terminal">}}）を選択します。

ボタンを選択すると、ターミナルセッションが確立されます。このターミナルは、他のターミナルと同じように機能します。デプロイで作成されたコンテナ内で作業するため、以下を実行できます。

- Shellコマンドを実行し、リアルタイムで応答を受け取る。
- ログを確認する。
- 設定またはコードの微調整を試す。

同じ環境に対して複数のターミナルを開くことができます。ターミナルごとに独自のShellセッションがあり、`screen`や`tmux`などのマルチプレクサを使用することも可能です。

## 関連トピック {#related-topics}

- [Kubernetes向けダッシュボード](kubernetes_dashboard.md)
- [デプロイ](deployments.md)
- [保護環境](protected_environments.md)
- [環境ダッシュボード](environments_dashboard.md)
- [デプロイの安全性](deployment_safety.md#restrict-write-access-to-a-critical-environment)

## トラブルシューティング {#troubleshooting}

### `action: stop`を含むジョブが実行されない {#the-job-with-action-stop-doesnt-run}

`on_stop`ジョブが設定されているにもかかわらず、環境が停止しない場合があります。これは、`action: stop`を含むジョブが、その`stages:`または`needs:`の設定が原因で実行可能な状態になっていない場合に発生します。

次に例を示します。

- 環境が、失敗したジョブを含むステージで開始されることがあります。その場合、その後のステージのジョブは開始されません。環境に対する`action: stop`を含むジョブが後続のステージに配置されている場合、そのジョブは開始されず、環境は削除されません。
- `action: stop`を含むジョブが、未完了のジョブに依存していることがあります。

`action: stop`が必要なときに常に実行されるようにするには、次のようにします。

- 両方のジョブを同じステージに配置します。

  ```yaml
  stages:
    - build
    - test
    - deploy

  ...

  deploy_review:
    stage: deploy
    environment:
      name: review/$CI_COMMIT_REF_SLUG
      url: https://$CI_ENVIRONMENT_SLUG.example.com
      on_stop: stop_review

  stop_review:
    stage: deploy
    environment:
      name: review/$CI_COMMIT_REF_SLUG
      action: stop
    when: manual
  ```

- ステージ順に従わなくてもジョブが開始されるように、[`needs`](../yaml/_index.md#needs)エントリを`action: stop`ジョブに追加します。

  ```yaml
  stages:
    - build
    - test
    - deploy
    - cleanup

  ...

  deploy_review:
    stage: deploy
    environment:
      name: review/$CI_COMMIT_REF_SLUG
      url: https://$CI_ENVIRONMENT_SLUG.example.com
      on_stop: stop_review

  stop_review:
    stage: cleanup
    needs:
      - deploy_review
    environment:
      name: review/$CI_COMMIT_REF_SLUG
      action: stop
    when: manual
  ```

### エラー: ジョブが無効なパラメータを指定して環境を作成しようとした {#error-job-would-create-an-environment-with-an-invalid-parameter}

プロジェクトが[動的環境を作成する](#create-a-dynamic-environment)ように設定されている場合、デプロイジョブで以下のエラーが発生する可能性があります。これは、動的に生成されたパラメータは環境の作成に使用できないためです。

```plaintext
This job could not be executed because it would create an environment with an invalid parameter.
```

たとえば、プロジェクトで`.gitlab-ci.yml`が次のように設定されている場合:

```yaml
deploy:
  script: echo
  environment: production/$ENVIRONMENT
```

パイプラインに`$ENVIRONMENT`変数が存在しないため、GitLabは`production/`という名前の環境を作成しようとします。しかしこれは、[環境名の制約](../yaml/_index.md#environmentname)により無効です。

この問題を修正するには、次のいずれかの解決策を実行します。

- `environment`キーワードをデプロイジョブから削除する。GitLabはすでに無効なキーワードを無視しているため、キーワードを削除してもデプロイパイプラインはそのまま維持されます。
- 変数がパイプラインに存在することを確認する。[サポートされている変数の制限](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)を確認してください。

#### レビューアプリでこのエラーが発生した場合 {#if-you-get-this-error-on-review-apps}

たとえば、`.gitlab-ci.yml`が次のように設定されているとします。

```yaml
review:
  script: deploy review app
  environment: review/$CI_COMMIT_REF_NAME
```

ブランチ名が`bug-fix!`の新しいマージリクエストを作成すると、`review`ジョブは`review/bug-fix!`という環境を作成しようとします。しかし、`!`は環境名として無効な文字であるため、デプロイジョブは環境なしで実行しようとして失敗します。

この問題を修正するには、次のいずれかの解決策を実行します。

- 無効な文字を含まない`bug-fix`などの名前でフィーチャーブランチを作り直す。
- `CI_COMMIT_REF_NAME`[定義済み変数](../variables/predefined_variables.md)を、無効な文字を除去する`CI_COMMIT_REF_SLUG`に置き換える。

  ```yaml
  review:
    script: deploy review app
    environment: review/$CI_COMMIT_REF_SLUG
  ```
