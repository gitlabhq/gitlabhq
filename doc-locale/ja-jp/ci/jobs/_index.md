---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDジョブ
description: 設定、ルール、キャッシュ、アーティファクト、ログ。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI/CD（継続的インテグレーションとデリバリー）ジョブは、[GitLab CI/CDパイプライン](../pipelines/_index.md)の基本的な要素です。ジョブは`.gitlab-ci.yml`ファイル内で設定し、コードのビルド、テスト、デプロイなどのタスクを実行するためのコマンドのリストを指定します。

ジョブには次のような特徴があります:

- [Runner](../runners/_index.md)上で実行される（例: Dockerコンテナを実行環境として使用する）。
- 他のジョブに依存せずに実行できる。
- 完全な実行ログを含む[ジョブログ](job_logs.md)がある。

ジョブは、[YAMLキーワード](../yaml/_index.md)を使用して定義します。これらのキーワードは、ジョブの実行に関するあらゆる側面を定義します。たとえば、次のことが可能です:

- ジョブの実行[方法](job_control.md)と[タイミング](job_rules.md)を制御する。
- ジョブを[ステージ](../yaml/_index.md#stages)と呼ばれるコレクションにグループ化する。ステージは順番に実行されますが、同じステージ内のジョブはすべて並列で実行できます。
- 柔軟な設定を可能にする[CI/CD変数](../variables/_index.md)を定義する。
- ジョブの実行を高速化する[キャッシュ](../caching/_index.md)を定義する。
- 他のジョブで利用できるようにファイルを[アーティファクト](job_artifacts.md)として保存する。

## パイプラインにジョブを追加する {#add-a-job-to-a-pipeline}

ジョブをパイプラインに追加するには、`.gitlab-ci.yml`ファイルに追加します。ジョブは次の条件を満たす必要があります:

- YAML設定のトップレベルで定義されること。
- 一意の[ジョブ名](#job-names)を持つこと。
- 実行するコマンドを定義する[`script`](../yaml/_index.md#script)セクション、または[ダウンストリームパイプライン](../pipelines/downstream_pipelines.md)の実行をトリガーする[`trigger`](../yaml/_index.md#trigger)セクションのいずれかがあること。

次に例を示します:

```yaml
my-ruby-job:
  script:
    - bundle install
    - bundle exec my_ruby_command

my-shell-script-job:
  script:
    - my_shell_script.sh
```

### ジョブ名 {#job-names}

以下のキーワードをジョブ名に使用することはできません:

- `image`
- `services`
- `stages`
- `before_script`
- `after_script`
- `variables`
- `cache`
- `include`
- `pages:deploy`（`deploy`ステージ用に設定する場合）

さらに次の文字列は、引用符で囲めば有効ですが、パイプラインの設定が不明確になる可能性があるためジョブ名に使用するのは推奨されません:

- `"true":`
- `"false":`
- `"nil":`

ジョブ名は255文字以下にする必要があります。

ジョブには一意の名前を使用してください。1つのファイル内で複数のジョブが同じ名前を持つ場合、パイプラインに追加されるのは1つのみであり、どのジョブが選ばれるのかを予測するのは困難です。インクルードされたファイルで同じジョブ名が1つ以上使用されている場合、[パラメータはマージ](../yaml/includes.md#override-included-configuration-values)されます。

### ジョブを非表示にする {#hide-a-job}

ジョブを設定ファイルから削除せずに一時的に無効にするには、ジョブ名の先頭にピリオド（`.`）を追加します。非表示ジョブにはキーワードとして`script`や`trigger`を含める必要はありませんが、有効なYAML設定を含める必要があります。

次に例を示します:

```yaml
.hidden_job:
  script:
    - run test
```

非表示ジョブはGitLab CI/CDによって処理されませんが、次のような再利用可能な設定のテンプレートとして使用できます:

- [`extends`キーワード](../yaml/yaml_optimization.md#use-extends-to-reuse-configuration-sections)
- [YAMLアンカー](../yaml/yaml_optimization.md#anchors)

## ジョブキーワードのデフォルト値を設定する {#set-default-values-for-job-keywords}

`default`キーワードを使用すると、パイプライン内のすべてのジョブでデフォルトとして使用されるジョブキーワードと値を設定できます。

次に例を示します:

```yaml
default:
  image: 'ruby:2.4'
  before_script:
    - echo Hello World

rspec-job:
  script: bundle exec rspec
```

パイプラインが実行されると、ジョブはデフォルトのキーワードを使用します:

```yaml
rspec-job:
  image: 'ruby:2.4'
  before_script:
    - echo Hello World
  script: bundle exec rspec
```

### デフォルトのキーワードと変数の継承を制御する {#control-the-inheritance-of-default-keywords-and-variables}

次の継承を制御できます:

- [デフォルトのキーワード](../yaml/_index.md#default)の継承は[`inherit:default`](../yaml/_index.md#inheritdefault)で制御します。
- [デフォルトの変数](../yaml/_index.md#default)の継承は[`inherit:variables`](../yaml/_index.md#inheritvariables)で制御します。

次に例を示します:

```yaml
default:
  image: 'ruby:2.4'
  before_script:
    - echo Hello World

variables:
  DOMAIN: example.com
  WEBHOOK_URL: https://my-webhook.example.com

rubocop:
  inherit:
    default: false
    variables: false
  script: bundle exec rubocop

rspec:
  inherit:
    default: [image]
    variables: [WEBHOOK_URL]
  script: bundle exec rspec

capybara:
  inherit:
    variables: false
  script: bundle exec capybara

karma:
  inherit:
    default: true
    variables: [DOMAIN]
  script: karma
```

この例では: 

- `rubocop`: 
  - 継承する: なし。
- `rspec`: 
  - 継承する: デフォルトの`image`と`WEBHOOK_URL`変数。
  - 継承**not**（しない）: デフォルトの`before_script`と`DOMAIN`変数。
- `capybara`: 
  - 継承する: デフォルトの`before_script`と`image`。
  - 継承**not**（しない）: `DOMAIN`と`WEBHOOK_URL`変数。
- `karma`: 
  - 継承する: デフォルトの`image`、`before_script`、`DOMAIN`変数。
  - 継承**not**（しない）: `WEBHOOK_URL`変数。

## パイプライン内のジョブを表示する {#view-jobs-in-a-pipeline}

パイプラインにアクセスすると、そのパイプラインに関連するジョブを確認できます。

パイプライン内のジョブの順序は、パイプライングラフのタイプによって異なります。

- [パイプライングラフ全体](../pipelines/_index.md#pipeline-details)の場合、ジョブは名前のアルファベット順に並びます。
- [パイプラインミニグラフ](../pipelines/_index.md#pipeline-mini-graphs)の場合、ジョブはステータスの重大度順に並び、失敗したジョブが最初に表示され、その後に名前のアルファベット順に並びます。

個々のジョブを選択すると、その[ジョブログ](job_logs.md)が表示され、次の操作を行えます:

- ジョブをキャンセルする。
- ジョブが失敗した場合に再試行する。
- ジョブが正常に完了した場合に再実行する。
- ジョブログを消去する。

### プロジェクトジョブを表示する {#view-project-jobs}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- ジョブ名フィルターは、GitLab 17.3のGitLab.comおよびGitLab Self-Managedで[実験的機能](../../policy/development_stages_support.md)として[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/387547)され、API用には`populate_and_use_build_names_table`、UI用には`fe_search_build_by_name`の各[フラグ](../../administration/feature_flags/_index.md)が導入されました。デフォルトでは無効になっています。
- GitLab 18.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/512149)になりました。機能フラグ`populate_and_use_build_names_table`および`fe_search_build_by_name`は削除されました。
- GitLab 18.3でジョブの種類フィルターが[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/555434)されました。

{{< /history >}}

プロジェクトで実行されたジョブを表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **ビルド** > **ジョブ**を選択します。

ジョブのリストは、ジョブのステータス、ソース、名前、種類でフィルタリングできます。

{{< alert type="note" >}}

名前によるフィルターは、過去30日間に作成されたジョブを返します。この保持期間は、UIとAPIのフィルタリングの両方に適用されます。

{{< /alert >}}

デフォルトでは、ビルドジョブのみが表示されるようにフィルタリングされています。トリガージョブを表示するには、フィルターをクリアし、**種類** > **トリガー**を選択します。

{{< alert type="note" >}}

**種類**フィルターは、プロジェクトジョブでのみ使用可能です。**管理者**エリアでは使用できません。

{{< /alert >}}

### 使用可能なジョブステータス {#available-job-statuses}

CI/CDジョブには次のステータスがあります:

- `canceled`: ジョブは手動でキャンセルされたか、または自動的に中断されました。
- `canceling`: ジョブはキャンセル中ですが、`after_script`が実行されています。
- `created`: ジョブは作成されましたが、まだ処理されていません。
- `failed`: ジョブの実行に失敗しました。
- `manual`: ジョブを開始するには手動操作が必要です。
- `pending`: ジョブはRunnerを待機するキューに入っています。
- `preparing`: Runnerが実行環境を準備中です。
- `running`: ジョブはRunnerで実行中です。
- `scheduled`: ジョブはスケジュールされていますが、実行は開始されていません。
- `skipped`: ジョブは、条件または依存関係のためにスキップされました。
- `success`: ジョブは正常に完了しました。
- `waiting_for_resource`: ジョブはリソースが利用可能になるまで待機しています。

### ジョブのソースを表示する {#view-the-source-of-a-job}

{{< history >}}

- ジョブのソースは、GitLab 17.9で`populate_and_use_build_source_table`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181159)されました。デフォルトでは有効になっています。
- GitLab 17.11のGitLab.com、GitLab Self-Managed、GitLab Dedicatedで[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/11796)になりました。

{{< /history >}}

GitLab CI/CDジョブに、CI/CDジョブを最初にトリガーしたアクションを示すsource属性が含まれるようになりました。この属性を使用すれば、ジョブがどのように開始されたかを追跡したり、特定のソースに基づいてジョブの実行をフィルタリングしたりできます。

#### 利用可能なジョブソース {#available-job-sources}

source属性には次の値が設定されます:

- `api`: Jobs APIに対するREST呼び出しによって開始されたジョブ。
- `chat`: GitLab ChatOpsを使用したチャットコマンドによって開始されたジョブ。
- `container_registry_push`: コンテナレジストリのプッシュによって開始されたジョブ。
- `duo_workflow`: GitLab Duo Agent Platformによって開始されたジョブ。
- `external`: GitLabと統合された外部リポジトリ内のイベントによって開始されたジョブ。プルリクエストイベントは含まれません。
- `external_pull_request_event`: 外部リポジトリ内のプルリクエストイベントによって開始されたジョブ。
- `merge_request_event`: マージリクエストイベントによって開始されたジョブ。
- `ondemand_dast_scan`: オンデマンドDASTスキャンによって開始されたジョブ。
- `ondemand_dast_validation`: オンデマンドDAST検証によって開始されたジョブ。
- `parent_pipeline`: 親パイプラインによって開始されたジョブ。
- `pipeline`: ユーザーが手動でパイプラインを実行したことによって開始されたジョブ。
- `pipeline_execution_policy`: トリガーされたパイプライン実行ポリシーによって開始されたジョブ。
- `pipeline_execution_policy_schedule`: スケジュールされたパイプライン実行ポリシーによって開始されたジョブ。
- `push`: コードプッシュによって開始されたジョブ。
- `scan_execution_policy`: スキャン実行ポリシーによって開始されたジョブ。
- `schedule`: スケジュールされたパイプラインによって開始されたジョブ。
- `security_orchestration_policy`: スケジュールされたスキャン実行ポリシーによって開始されたジョブ。
- `trigger`: 別のジョブまたはパイプラインによって開始されたジョブ。
- `unknown`: 不明なソースによって開始されたジョブ。
- `web`: ユーザーによってGitLab UIから開始されたジョブ。
- `webide`: ユーザーによってWeb IDEから開始されたジョブ。

### パイプラインビューで類似のジョブをグループ化する {#group-similar-jobs-together-in-pipeline-views}

類似のジョブが多数ある場合、[パイプライングラフ](../pipelines/_index.md#pipeline-details)が長くなり、読みづらくなります。

類似のジョブは自動的にグループ化できます。ジョブ名が特定の形式で指定されている場合、（ミニグラフではない）標準のパイプライングラフでは、単一のグループに折りたたまれます。

パイプラインにグループ化されたジョブがあるかどうかは、再試行ボタンやキャンセルボタンの代わりにジョブ名の横に数値が表示されることでわかります。この数値は、グループ化されたジョブの数を示します。数値の上にカーソルを合わせると、すべてのジョブが正常に完了したか、失敗したジョブがあるかを確認できます。ジョブを選択すると展開されます。

![複数のステージとジョブが表示されたパイプライングラフに、グループ化されたジョブのグループが3つ含まれています。](img/pipeline_grouped_jobs_v17_9.png)

ジョブのグループを作成するには、`.gitlab-ci.yml`ファイルで、各ジョブ名を数値と次のいずれかで区切ります:

- スラッシュ（`/`）。例: `slash-test 1/3`、`slash-test 2/3`、`slash-test 3/3`。
- コロン（`:`）。例: `colon-test 1:3`、`colon-test 2:3`、`colon-test 3:3`。
- スペース。例: `space-test 0 3`、`space-test 1 3`、`space-test 2 3`。

上記の記号はどれも同じように動作します。

次の例では、3つのジョブが`build ruby`というグループに含まれています:

```yaml
build ruby 1/3:
  stage: build
  script:
    - echo "ruby1"

build ruby 2/3:
  stage: build
  script:
    - echo "ruby2"

build ruby 3/3:
  stage: build
  script:
    - echo "ruby3"
```

パイプライングラフには、3つのジョブを含む`build ruby`という名前のグループが表示されます。

ジョブは、左から右に数値を比較して並べ替えられます。通常、最初の数値はインデックス、2番目の数値は合計に使用します。

[この正規表現](https://gitlab.com/gitlab-org/gitlab/-/blob/2f3dc314f42dbd79813e6251792853bc231e69dd/app/models/commit_status.rb#L99): `([\b\s:]+((\[.*\])|(\d+[\s:\/\\]+\d+))){1,3}\s*\z`は、ジョブ名を評価します。1つ以上の`: [...]`、`X Y`、`X/Y`、`X\Y`というシーケンスは、ジョブ名の**end**（末尾）からのみ削除されます。ジョブ名の先頭や途中に一致する部分文字列がある場合は削除されません。

## ジョブを再試行する {#retry-jobs}

ジョブは、完了後の最終ステータス（失敗、成功、キャンセル）に関係なく再試行できます。

ジョブを再試行すると、次のようになります:

- 新しいジョブIDを持つ新しいジョブインスタンスが作成されます。
- ジョブは、元のジョブと同じパラメータと変数で実行されます。
- アーティファクトを生成するジョブの場合、新しいアーティファクトが作成され、保存されます。
- 新しいジョブは、元のパイプラインを作成したユーザーではなく、再試行を開始したユーザーに関連付けられます。
- 以前にスキップされた後続のジョブは、再試行を開始したユーザーに再割り当てされます。

ダウンストリームパイプラインをトリガーする[トリガージョブ](../yaml/_index.md#trigger)を再試行すると、次のようになります:

- トリガージョブは新しいダウンストリームパイプラインを生成します。
- そのダウンストリームパイプラインも、再試行を開始したユーザーに関連付けられます。
- ダウンストリームパイプラインは再試行時の設定で実行され、元の実行時とは異なる場合があります。

### ジョブを再試行する {#retry-a-job}

前提要件: 

- プロジェクトのデベロッパーロール以上を持っている必要があります。
- ジョブが[アーカイブ](../../administration/settings/continuous_integration.md#archive-pipelines)されていない必要があります。

マージリクエストからジョブを再試行するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. マージリクエストから、次のいずれかを実行します:
   - パイプラインウィジェットで、再試行するジョブの横にある**再実行**（{{< icon name="retry" >}}）を選択します。
   - **パイプライン**タブを選択し、再試行するジョブの横にある**再実行**（{{< icon name="retry" >}}）を選択します。

ジョブログからジョブを再試行するには、次のようにします:

1. ジョブのログページに移動します。
1. 右上隅で、**再実行**（{{< icon name="retry" >}}）を選択します。

パイプラインからジョブを再試行するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **ビルド** > **パイプライン**を選択します。
1. 再試行するジョブが含まれているパイプラインを見つけます。
1. パイプライングラフで、再試行するジョブの横にある**再実行**（{{< icon name="retry" >}}）を選択します。

### パイプライン内の失敗またはキャンセルされたジョブをすべて再試行する {#retry-all-failed-or-canceled-jobs-in-a-pipeline}

パイプライン内に失敗またはキャンセルされたジョブが複数ある場合、それらすべてを一度に再試行できます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. 次のいずれかを実行します:
   - **ビルド** > **パイプライン**を選択します。
   - マージリクエストに移動し、**パイプライン**タブを選択します。
1. 失敗またはキャンセルされたジョブを含むパイプラインに対して、**Retry all failed or canceled jobs**（失敗またはキャンセルされたすべてのジョブを再試行）（{{< icon name="retry" >}}）を選択します。

## ジョブをキャンセルする {#cancel-jobs}

未完了のCI/CDジョブをキャンセルできます。

ジョブをキャンセルした後の挙動は、ジョブのステータスとGitLab Runnerのバージョンによって異なります:

- まだ実行を開始していないジョブの場合、ジョブはすぐにキャンセルされます。
- 実行中のジョブの場合は、次のようになります:
  - GitLab Runner 16.10以降とGitLab 17.0以降の場合:
    1. ジョブは`canceling`としてマークされます。
    1. 現在実行中のコマンドは完了できます。ジョブの[`before_script`](../yaml/_index.md#before_script)または[`script`](../yaml/_index.md#script)の残りのコマンドはスキップされます。
    1. ジョブに`after_script`セクションがある場合、常に開始され、完了まで実行されます。
    1. ジョブは`canceled`としてマークされます。
  - GitLab Runner 16.9以前かつGitLab 16.11以前の場合、`after_script`を実行せず、ジョブはすぐにキャンセルされ、`canceled`とマークされます。

`after_script`を待たずにジョブをすぐにキャンセルする必要がある場合は、[強制キャンセル](#force-cancel-a-job)を使用します。

### ジョブをキャンセルする {#cancel-a-job}

前提要件: 

- 少なくともプロジェクトのデベロッパーロール、あるいは[パイプラインまたはジョブをキャンセルするために必要な最小のロール](../pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs)を持っている必要があります。

マージリクエストからジョブをキャンセルするには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. マージリクエストから、次のいずれかを実行します:
   - パイプラインウィジェットで、キャンセルするジョブの横にある**キャンセル**（{{< icon name="cancel" >}}）を選択します。
   - **パイプライン**タブを選択し、キャンセルするジョブの横にある**キャンセル**（{{< icon name="cancel" >}}）を選択します。

ジョブログからジョブをキャンセルするには、次のようにします:

1. ジョブのログページに移動します。
1. 右上隅で、**キャンセル**（{{< icon name="cancel" >}}）を選択します。

パイプラインからジョブをキャンセルするには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **ビルド** > **パイプライン**を選択します。
1. キャンセルするジョブが含まれているパイプラインを見つけます。
1. パイプライングラフで、キャンセルするジョブの横にある**キャンセル**（{{< icon name="cancel" >}}）を選択します。

### パイプラインで実行中のジョブをすべてキャンセルする {#cancel-all-running-jobs-in-a-pipeline}

実行中のパイプライン内のすべてのジョブを一度にキャンセルできます。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. 次のいずれかを実行します:
   - **ビルド** > **パイプライン**を選択します。
   - マージリクエストに移動し、**パイプライン**タブを選択します。
1. キャンセルするパイプラインに対して、**実行中のパイプラインをキャンセル**（{{< icon name="cancel" >}}）を選択します。

### ジョブを強制的にキャンセルする {#force-cancel-a-job}

{{< history >}}

- GitLab 17.10で`force_cancel_build`[フラグ](../../administration/feature_flags/_index.md)とともに[実験的機能](../../policy/development_stages_support.md)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467107)されました。デフォルトでは無効になっています。
- GitLab 17.11[で一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/519313)になりました。機能フラグ`force_cancel_build`は削除されました。

{{< /history >}}

`after_script`の完了を待機しない場合、またはジョブが応答しなくなった場合は、強制的にキャンセルできます。強制的にキャンセルすると、ジョブのステータスがすぐに`canceling`から`canceled`に移行します。

ジョブを強制的にキャンセルすると、[ジョブトークン](ci_job_token.md)が即座に失効します。Runnerがまだジョブの実行中でも、GitLabへのアクセス権を失います。Runnerは`after_script`の完了を待たずにジョブを中断します。

前提要件: 

- プロジェクトのメンテナーロール以上が必要です。
- ジョブは`canceling`ステータスである必要があります。そのためには以下が必要です:
  - GitLab 17.0以降。
  - GitLab Runner 16.10以降。

ジョブを強制的にキャンセルするには、次のようにします:

1. ジョブのログページに移動します。
1. 右上隅で、**強制的にキャンセル**を選択します。

## 失敗したジョブの問題を解決する {#troubleshoot-a-failed-job}

パイプラインが失敗した場合、または失敗が許可されている場合、原因を確認できる場所がいくつかあります:

- パイプライン詳細ビューの[パイプライングラフ](../pipelines/_index.md#pipeline-details)。
- マージリクエストページとコミットページのパイプラインウィジェット。
- ジョブビュー（ジョブのグローバルビューと詳細ビュー）。

それぞれの場所で、失敗したジョブにカーソルを合わせると、失敗した理由を確認できます。

![失敗したジョブと失敗の理由が表示されたパイプライングラフ。](img/job_failure_reason_v17_9.png)

ジョブの詳細ページでもジョブが失敗した理由を確認できます。

### 根本原因分析を使用する {#with-root-cause-analysis}

GitLab Duo ChatのGitLab Duo根本原因分析を使用して、[失敗したCI/CDジョブの問題を解決](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)できます。

## デプロイジョブ {#deployment-jobs}

デプロイジョブは、[環境](../environments/_index.md)を使用するCI/CDジョブです。デプロイジョブとは、`environment`キーワードと[`start`環境`action`](../yaml/_index.md#environmentaction)を使用するすべてのジョブを指します。デプロイジョブは、`deploy`ステージに配置する必要はありません。次の`deploy me`ジョブは、デプロイジョブの例です。`action: start`はデフォルトの動作で、説明のためにここでは定義していますが、省略しても構いません:

```yaml
deploy me:
  script:
    - deploy-to-cats.sh
  environment:
    name: production
    url: https://cats.example.com
    action: start
```

デプロイジョブの動作は、[古いデプロイジョブを防止](../environments/deployment_safety.md#prevent-outdated-deployment-jobs)や[一度に1つのデプロイジョブのみを実行](../environments/deployment_safety.md#ensure-only-one-deployment-job-runs-at-a-time)などの[デプロイの安全性](../environments/deployment_safety.md)設定を使用して制御できます。
