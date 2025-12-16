---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDパイプライン
description: 設定、自動化、ステージ、スケジュール、効率性。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI/CDパイプラインは、GitLab CI/CDの基本的な構成要素です。パイプラインは、`.gitlab-ci.yml`ファイルで[YAMLキーワード](../yaml/_index.md)を使用して設定されます。

パイプラインは、ブランチへのプッシュ、マージリクエストの作成、設定されたスケジュールなど、特定のイベントが発生した際に自動的に実行するよう設定できます。必要な場合は、パイプラインを手動で実行することもできます。

パイプラインは以下で構成されています:

- プロジェクトのパイプラインの全体的な動作を制御する[グローバルYAMLキーワード](../yaml/_index.md#global-keywords)。
- タスクを実行するためのコマンドを実行する[ジョブ](../jobs/_index.md)。たとえば、ジョブはコードをコンパイル、テスト、またはデプロイできます。ジョブは互いに独立して、[Runner](../runners/_index.md)によって実行されます。
- ジョブをグループ化する方法を定義するステージ。ステージは順番に実行されますが、ステージ内のジョブは並行して実行されます。たとえば、アーリーステージのジョブではコードのlintやコンパイルを実行するのに対して、後のステージのジョブではコードのテストやデプロイを実行できます。ステージ内のすべてのジョブが成功すると、パイプラインは次のステージに進みます。ステージ内のいずれかのジョブが失敗した場合、次のステージは（通常は）実行されず、パイプラインは途中で終了します。

小規模なパイプラインは、次の順序で実行される3つのステージで構成できます:

- プロジェクトのコードをコンパイルする`compile`というジョブを含む`build`ステージ。
- コードに対してさまざまなテストを実行する`test1`と`test2`という2つのジョブを含む`test`ステージ。これらのテストは、`compile`ジョブが正常に完了した場合にのみ実行されます。
- `deploy-to-production`というジョブがある`deploy`ステージ。このジョブは、`test`ステージの両方のジョブが開始され、正常に完了した場合にのみ実行されます。

初めてのパイプラインを開始するには、[初めてのGitLab CI/CDパイプラインを作成して実行する](../quick_start/_index.md)を参照してください。

## パイプラインの種類 {#types-of-pipelines}

パイプラインは、さまざまな方法で設定できます:

- [基本的なパイプライン](pipeline_architectures.md#basic-pipelines)では、各ステージのすべてのジョブを同時に実行し、その後に次のステージを実行します。
- [`needs`キーワードを使用するパイプライン](../yaml/needs.md)は、ジョブ間の依存関係に基づいて実行され、基本的なパイプラインよりも速く実行できます。
- [マージリクエストパイプライン](merge_request_pipelines.md)は、（すべてのコミットではなく）マージリクエストに対してのみ実行されます。
- [マージ結果パイプライン](merged_results_pipelines.md)は、ソースブランチからの変更がすでにターゲットブランチにマージされているかのように動作するマージリクエストパイプラインです。
- [マージトレイン](merge_trains.md)は、マージ結果パイプラインを使用して、マージを順番にキューに入れます。
- [親子パイプライン](downstream_pipelines.md#parent-child-pipelines)は、複雑なパイプラインを、複数の子サブパイプラインをトリガーできる1つの親パイプラインに分割します。これらはすべて同じプロジェクト内で同じSHAで実行されます。このパイプラインアーキテクチャは、一般的にモノリポジトリで使用されます。
- [マルチプロジェクトパイプライン](downstream_pipelines.md#multi-project-pipelines)は、異なる複数のプロジェクトのパイプラインを結合します。

## パイプラインを設定する {#configure-a-pipeline}

パイプラインとその構成要素であるジョブやステージは、各プロジェクトのCI/CDパイプライン設定ファイルに[YAMLキーワード](../yaml/_index.md)を使用して定義されます。GitLabでCI/CD設定を編集するときは、[パイプラインエディタ](../pipeline_editor/_index.md)を使用する必要があります。

GitLab UIを使用してパイプラインの特定の側面を設定することもできます:

- 各プロジェクトの[パイプライン設定](settings.md)。
- [パイプラインスケジュール](schedules.md)。
- [カスタムCI/CD変数](../variables/_index.md#for-a-project)。

VS Codeを使用してGitLab CI/CD設定を編集する場合、[VS Code用GitLab Workflow拡張機能](../../editor_extensions/visual_studio_code/_index.md)を使用すると、[設定を検証](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#validate-gitlab-ci-configuration)し、[パイプラインのステータスを表示](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#information-about-your-branch-pipelines-mr-closing-issue)できます。

### 手動でパイプラインを実行する {#run-a-pipeline-manually}

{{< history >}}

- GitLab 17.7で、**パイプラインの実行**から**新しいパイプライン**に名称が[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/482718)。
- **入力**オプションは、GitLab 17.11で`ci_inputs_for_pipelines`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/525504)されました。デフォルトでは有効になっています。
- **入力**オプションは、GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/536548)になりました。機能フラグ`ci_inputs_for_pipelines`は削除されました。

{{< /history >}}

パイプラインは、定義済み変数、または手動で指定された[変数](../variables/_index.md)を使用して、手動で実行できます。

パイプラインの結果（たとえば、コードビルド）がパイプラインの標準的な操作以外で必要な場合に、手動で実行することがあります。

パイプラインを手動で実行するには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **ビルド** > **パイプライン**を選択します。
1. **新しいパイプライン**を選択します。
1. **ブランチ名またはタグで実行**フィールドで、パイプラインを実行するブランチまたはタグを選択します。
1. オプション。以下を入力します:
   - パイプラインを実行するために必要な[入力](../inputs/_index.md)。入力のデフォルト値は事前入力されていますが、変更可能です。入力値は、予期される型に従ったものでなければなりません。
   - [CI/CD変数](../variables/_index.md)。[フォームに値が事前入力される](#prefill-variables-in-manual-pipelines)ように変数を設定できます。パイプラインの動作を制御するために入力を使用すると、CI/CD変数よりもセキュリティと柔軟性が向上します。
1. **新しいパイプライン**を選択します。

これでパイプラインは設定どおりにジョブを実行するようになります。

#### マニュアルパイプライン変数を表示する {#view-manual-pipeline-variables}

{{< history >}}

- GitLab 17.2で`ci_show_manual_variables_in_pipeline`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/323097)されました。デフォルトでは無効になっています。
- プロジェクト設定として、GitLab 18.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/505440)になりました。機能フラグ`ci_show_manual_variables_in_pipeline`は削除されました。

{{< /history >}}

パイプラインを手動で実行するときに指定されたすべての変数を確認できます。

前提要件:

- プロジェクトのオーナーロールが必要です。

必要なロールは実行する内容によって異なります:

| アクション | 最低限必要なロール |
|--------|-------------|
| 変数名を表示する | ゲスト |
| 変数の値を表示する | デベロッパー |
| 表示レベルを設定する | オーナー |

{{< alert type="warning" >}}

この設定をオンにすると、デベロッパーロールのユーザーは、手動で実行したパイプラインから機密情報を含む可能性がある変数の値を参照できます。認証情報やトークンなどの機密データについては、マニュアルパイプライン変数ではなく、[保護された変数](../variables/_index.md#protect-a-cicd-variable)または[外部シークレット管理](../secrets/_index.md)を使用してください。

{{< /alert >}}

マニュアルパイプライン変数を参照するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **パイプライン変数を表示する**を選択します。
1. **ビルド** > **パイプライン**に移動し、手動で実行されたパイプラインを選択します。
1. **マニュアル変数**タブを選択します。

変数の値は、デフォルトでマスクされます。少なくともデベロッパーロールをお持ちの場合は、目のアイコンを選択して値を表示できます。

#### 手動パイプラインの変数を事前入力する {#prefill-variables-in-manual-pipelines}

{{< history >}}

- **パイプラインの実行**ページでのMarkdownのレンダリングは、GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/441474)されました。

{{< /history >}}

[`description`および`value`](../yaml/_index.md#variablesdescription)キーワードを使用して、パイプラインを手動で実行するときに事前入力される[パイプラインレベル（グローバル）変数を定義](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)できます。descriptionは、変数の用途や許容値などの情報を説明するために使用します。説明にはMarkdownを使用できます。

ジョブレベル変数は事前入力できません。

手動でトリガーされるパイプラインでは、**新しいパイプライン**ページに、`.gitlab-ci.yml`ファイルで`description`が定義されているパイプラインレベルの変数がすべて表示されます。説明は変数の下に表示されます。

事前入力された値は変更できます。変更すると、その単一のパイプライン実行のみに対して[値がオーバーライド](../variables/_index.md#use-pipeline-variables)されます。このプロセスでオーバーライドされた変数は[展開](../variables/_index.md#allow-cicd-variable-expansion)され、[マスク](../variables/_index.md#mask-a-cicd-variable)されません。設定ファイルで変数の`value`を定義しない場合、変数名は一覧表示されますが、値フィールドは空白になります。

次に例を示します:

```yaml
variables:
  DEPLOY_CREDENTIALS:
    description: "The deployment credentials."
  DEPLOY_ENVIRONMENT:
    description: "Select the deployment target. Valid options are: 'canary', 'staging', 'production', or a stable branch of your choice."
    value: "canary"
```

この例では: 

- `DEPLOY_CREDENTIALS`は**新しいパイプライン**ページに表示されますが、値は設定されていません。ユーザーは、パイプラインを手動で実行するたびに値を定義する必要があります。
- `DEPLOY_ENVIRONMENT`は、**新しいパイプライン**ページでデフォルト値として`canary`が事前入力され、メッセージにはその他のオプションについての説明があります。

{{< alert type="note" >}}

[既知の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/382857)により、[コンプライアンスパイプライン](../../user/compliance/compliance_pipelines.md)を使用するプロジェクトでは、パイプラインを手動で実行するときに事前入力された変数が表示されない場合があります。この問題を回避するには、[コンプライアンスパイプライン設定を変更](../../user/compliance/compliance_pipelines.md#prefilled-variables-are-not-shown)します。

{{< /alert >}}

#### 選択可能な事前入力される変数値のリストを設定する {#configure-a-list-of-selectable-prefilled-variable-values}

{{< history >}}

- GitLab 15.5で`run_pipeline_graphql`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/363660)されました。デフォルトでは無効になっています。
- `options`キーワードは、GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105502)されました。
- GitLab 15.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106038)になりました。機能フラグ`run_pipeline_graphql`は削除されました。
- [バグ](https://gitlab.com/gitlab-org/gitlab/-/issues/386245)により変数リストが正しく表示されないことがありましたが、GitLab 15.9で解決されました。

{{< /history >}}

パイプラインを手動で実行するときにユーザーが選択できるCI/CD変数値の配列を定義できます。これらの値は、**新しいパイプライン**ページのドロップダウンリストに表示されます。`options`に値オプションのリストを追加し、`value`でデフォルト値を設定します。`value`の文字列も`options`リストに含める必要があります。

次に例を示します:

```yaml
variables:
  DEPLOY_ENVIRONMENT:
    value: "staging"
    options:
      - "production"
      - "staging"
      - "canary"
    description: "The deployment target. Set to 'staging' by default."
```

### URLクエリ文字列を使用してパイプラインを実行する {#run-a-pipeline-by-using-a-url-query-string}

クエリ文字列を使用して、**新しいパイプライン**ページに自動入力できます。たとえば、クエリ文字列が`.../pipelines/new?ref=my_branch&var[foo]=bar&file_var[file_foo]=file_bar`なら、**新しいパイプライン**ページに次の内容が自動入力されます:

- **Run for**（実行）フィールド: `my_branch`。
- **変数**セクション:
  - 変数:
    - キー: `foo`
    - 値: `bar`
  - ファイル:
    - キー: `file_foo`
    - 値: `file_bar`

`pipelines/new` URLの形式は次のとおりです:

```plaintext
.../pipelines/new?ref=<branch>&var[<variable_key>]=<value>&file_var[<file_key>]=<value>
```

次のパラメータがサポートされています:

- `ref`: **Run for**（実行）フィールドに入力するブランチを指定します。
- `var`: `Variable`変数を指定します。
- `file_var`: `File`変数を指定します。

`var`または`file_var`ごとに、キーと値が必要です。

### パイプラインに手動操作を追加する {#add-manual-interaction-to-your-pipeline}

[手動ジョブ](../jobs/job_control.md#create-a-job-that-must-be-run-manually)を使用すると、パイプラインを進める前に手動での操作が必要になります。

これは、パイプライングラフから直接行うことができます。特定のジョブを実行するには、**実行**（{{< icon name="play" >}}）を選択します。

たとえば、パイプラインは自動的に開始できますが、[本番環境にデプロイ](../environments/deployments.md#configure-manual-deployments)するには手動アクションが必要、というようにできます。次の例の場合、`production`ステージに手動アクションを含むジョブがあります:

![4つのステージ（ビルド、テスト、カナリア、本番環境）を示すパイプライングラフ。最初の3つのステージは緑色のチェックマークで完了したジョブを示し、本番環境ステージは保留中のデプロイジョブを示しています。](img/manual_job_v17_9.png)

#### ステージ内のすべての手動ジョブを開始する {#start-all-manual-jobs-in-a-stage}

ステージに手動ジョブのみが含まれている場合は、ステージの上にある**すべての手動ジョブを実行**（{{< icon name="play" >}}）を選択して、すべてのジョブを同時に開始できます。ステージに手動以外のジョブが含まれている場合、このオプションは表示されません。

### パイプラインをスキップする {#skip-a-pipeline}

パイプラインをトリガーせずにコミットをプッシュするには、コミットメッセージに、大文字と小文字を区別せずに、`[ci skip]`または`[skip ci]`を追加します。

または、Git 2.10以降では、`ci.skip` [Gitプッシュオプション](../../topics/git/commit.md#push-options-for-gitlab-cicd)を使用します。`ci.skip`プッシュオプションは、マージリクエストパイプラインをスキップしません。

### パイプラインを削除する {#delete-a-pipeline}

プロジェクトのオーナーロールを持つユーザーは、パイプラインを削除できます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **ビルド** > **パイプライン**を選択します。
1. 削除するパイプラインのパイプラインID（`#123456789`など）またはパイプラインのステータスアイコン（**成功**など）を選択します。
1. パイプラインの詳細ページの右上にある**削除**を選択します。

パイプラインを削除しても、[子パイプライン](downstream_pipelines.md#parent-child-pipelines)は自動的に削除されません。詳細については、[イシュー39503](https://gitlab.com/gitlab-org/gitlab/-/issues/39503)を参照してください。

{{< alert type="warning" >}}

パイプラインを削除すると、すべてのパイプラインキャッシュが期限切れになり、ジョブ、ログ、アーティファクト、トリガーなど、直接関連するすべてのオブジェクトが削除されます。**This action cannot be undone**（この操作は元に戻すことができません）。

{{< /alert >}}

### 保護ブランチでのパイプラインセキュリティ {#pipeline-security-on-protected-branches}

[保護ブランチ](../../user/project/repository/branches/protected.md)でパイプラインが実行される場合、厳格なセキュリティモデルが適用されます。

ユーザーが特定のブランチへの[マージまたはプッシュを許可](../../user/project/repository/branches/protected.md)されている場合、保護ブランチでは次のアクションが許可されます:

- 手動パイプラインの実行（[Web UI](#run-a-pipeline-manually)または[パイプラインAPI](#pipelines-api)を使用）。
- スケジュールされたパイプラインの実行。
- トリガーを使用したパイプラインの実行。
- オンデマンドDASTスキャンの実行。
- 既存のパイプラインでの手動アクションのトリガー。
- 既存のジョブの再試行またはキャンセル（Web UIまたはパイプラインAPIを使用）。

**保護**としてマークされた**変数**は、保護ブランチのパイプラインで実行されるジョブからアクセスできます。デプロイ認証情報やトークンなどの機密情報にアクセスする権限があるユーザーにのみ、保護ブランチにマージする権限を割り当てます。

**保護**としてマークされた**Runners**は、保護ブランチでのみジョブを実行できます。信頼できないコードが保護されたRunnerで実行されるのを防ぎ、デプロイキーやその他の認証情報が誤ってアクセスされるのを防ぎます。保護されたRunnerで実行されるように設計されたジョブが標準のRunnerを使用しないようにするには、適切に[タグ付け](../yaml/_index.md#tags)する必要があります。

保護された変数とRunnerへのアクセスが[マージリクエストパイプライン](merge_request_pipelines.md#control-access-to-protected-variables-and-runners)のコンテキストでどのように機能するかを確認してください。

パイプラインを保護するための追加のセキュリティに関する推奨事項については、[デプロイの安全性](../environments/deployment_safety.md)ページを確認してください。

## アップストリームプロジェクトが再ビルドされたときにパイプラインをトリガーする（非推奨） {#trigger-a-pipeline-when-an-upstream-project-is-rebuilt}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

別のプロジェクトのタグに基づいてパイプラインを自動的にトリガーするようにプロジェクトを設定できます。サブスクライブされたプロジェクトの新しいタグパイプラインが完了すると、タグパイプラインの成功、失敗、またはキャンセルに関係なく、プロジェクトのデフォルトブランチでパイプラインがトリガーされます。

別のパイプラインが実行されたときにパイプラインをトリガーするには、代わりに[パイプライントリガートークン](../triggers/_index.md#use-a-cicd-job)を使用したCI/CDジョブを使用できます。この方法は、パイプラインサブスクリプションよりも信頼性が高く柔軟性があり、推奨されるアプローチです。

前提要件:

- アップストリームプロジェクトは[公開](../../user/public_access.md)されている必要があります。
- ユーザーはアップストリームプロジェクトでデベロッパーロールを持っている必要があります。

アップストリームプロジェクトが再ビルドされたときにパイプラインをトリガーするには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **パイプラインのサブスクリプション**を展開します。
1. **プロジェクトを追加**を選択します。
1. サブスクライブするプロジェクトを`<namespace>/<project>`形式で入力します。たとえば、プロジェクトが`https://gitlab.com/gitlab-org/gitlab`の場合は、`gitlab-org/gitlab`を使用します。
1. **サブスクライブ**を選択します。

アップストリームパイプラインサブスクリプションの最大数は、アップストリームプロジェクトとダウンストリームプロジェクトの両方において、デフォルトで2です。GitLab Self-Managedでは、管理者がこの[制限](../../administration/instance_limits.md#number-of-cicd-subscriptions-to-a-project)を変更できます。

## パイプラインの所要時間の計算方法 {#how-pipeline-duration-is-calculated}

パイプラインの合計実行時間には、以下は含まれません:

- 再試行または手動で再実行されたジョブの初回実行の所要時間。
- 待機（キュー）時間。

つまり、ジョブが再試行または手動で再実行された場合、最新の実行の所要時間のみが合計実行時間に含まれます。

各ジョブは`Period`として表されます。これは以下で構成されます:

- `Period#first`（ジョブの開始時）。
- `Period#last`（ジョブの終了時）。

簡単な例を次に示します:

- A (0, 2)
- A' (2, 4)
  - これはAを再試行しています
- B (1, 3)
- C (6, 7)

この例では、次のようになります:

- Aは0で始まり、2で終わります。
- A'は2で始まり、4で終わります。
- Bは1で始まり、3で終わります。
- Cは6で始まり、7で終わります。

視覚的には、次のように表示できます:

```plaintext
0  1  2  3  4  5  6  7
AAAAAAA
   BBBBBBB
      A'A'A'A
                  CCCC
```

Aがリトライされるため無視され、ジョブA'のみがカウントされます。B、A'、およびCの結合は(1, 4)および(6, 7)です。したがって、合計実行時間は次のようになります:

```plaintext
(4 - 1) + (7 - 6) => 4
```

## パイプラインを表示する {#view-pipelines}

プロジェクトで実行されたすべてのパイプラインを表示するには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **ビルド** > **パイプライン**を選択します。

次の条件で**パイプライン**ページをフィルタリングできます:

- トリガー作成者
- ブランチ名
- ステータス
- タグ
- ソース

右上にあるドロップダウンリストで**パイプラインID**を選択すると、インスタンス全体で一意のIDであるパイプラインIDが表示されます。**pipeline IID**（パイプラインIID）を選択すると、パイプラインIID（内部ID、プロジェクト内でのみ一意）が表示されます。

次に例を示します:

![トリガー作成者、ブランチ名、ステータス、タグ名、およびソースによるフィルター機能が付いた、パイプラインページに表示されるパイプラインのリスト。](img/pipeline_list_v16_11.png)

特定のマージリクエストに関連するパイプラインを表示するには、マージリクエストの**パイプライン**タブに移動します。

### パイプラインの詳細 {#pipeline-details}

{{< history >}}

- パイプラインの詳細表示は、GitLab 16.6で`new_pipeline_graph`[フラグ](../../administration/feature_flags/_index.md)とともに[更新](https://gitlab.com/gitlab-org/gitlab/-/issues/424403)されました。デフォルトでは無効になっています。
- 更新されたパイプラインの詳細表示は、GitLab 16.8の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/426902)になりました。

{{< /history >}}

パイプラインを選択して、パイプライン内のすべてのジョブを表示するパイプラインの詳細ページを開きます。このページから、実行中のパイプラインのキャンセル、失敗したジョブの再試行、または[パイプラインの削除](#delete-a-pipeline)を実行できます。

パイプラインの詳細ページには、パイプライン内のすべてのジョブのグラフが表示されます:

![パイプラインの詳細ページ](img/pipeline_details_v17_9.png)

標準URLを使用して、特定のパイプラインの詳細にアクセスできます:

- `gitlab.example.com/my-group/my-project/-/pipelines/latest`: プロジェクト内のデフォルトブランチの最新のコミットに対する、最新のパイプラインの詳細ページ。
- `gitlab.example.com/my-group/my-project/-/pipelines/<branch>/latest`: プロジェクトの`<branch>`ブランチの最新のコミットに対する、最新のパイプラインの詳細ページ。

#### ステージまたは`needs`設定でジョブをグループ化する {#group-jobs-by-stage-or-needs-configuration}

[`needs`](../yaml/_index.md#needs)キーワードを使用してジョブを設定する場合、パイプライン詳細ページでジョブをグループ化する方法は2通りあります。ステージ設定でジョブをグループ化するには、**ジョブをグループ化**セクションで**stage**（ステージ）を選択します:

![各ステージの下にグループ化されたジョブが表示されているパイプライングラフ](img/pipeline_stage_view_v17_9.png)

[`needs`](../yaml/_index.md#needs)設定によってジョブをグループ化するには、**ジョブの依存関係**を選択します。必要に応じて、**依存関係を表示**を選択すると、依存関係にあるジョブ間に線を表示できます。

![ジョブの依存関係でグループ化されたジョブ](img/pipeline_dependency_view_v17_9.png)

左端の列のジョブが最初に実行され、それらに依存するジョブが次の列にグループ化されます。この例では: 

- `lint-job`は、`needs: []`が設定されており、どのジョブにも依存しないため、`test`ステージにありますが、最初の列に表示されます。
- `test-job1`は`build-job1`に依存し、`test-job2`は`build-job1`と`build-job2`の両方に依存するため、両方のテストジョブが2列目に表示されます。
- 両方の`deploy`ジョブは2列目のジョブ（それ自体が他の先行ジョブに依存する）に依存するため、デプロイジョブは3列目に表示されます。

**ジョブの依存関係**表示でジョブにカーソルを合わせると、選択したジョブの前に実行する必要があるすべてのジョブが強調表示されます:

![カーソルを合わせてパイプラインの依存関係を表示](img/pipeline_dependency_view_on_hover_v17_9.png)

### パイプラインミニグラフ {#pipeline-mini-graphs}

パイプラインミニグラフは占有スペースが少なく、すべてのジョブが成功したか、失敗したジョブがあるかを一目で確認できます。単一のコミットに関連するすべてのジョブと、パイプラインの各ステージの最終結果を示しています。何が失敗したかをすばやく確認して修正できます。

パイプラインミニグラフは常にステージごとにジョブをグループ化し、パイプラインやコミットの詳細を表示するときにGitLabの各所で表示されます。

![パイプラインミニグラフ](img/pipeline_mini_graph_v16_11.png)

パイプラインミニグラフのステージは展開できます。各ステージにマウスカーソルを合わせ、名前とステータスを確認し、ステージを選択してジョブリストを展開します。

### ダウンストリームパイプライングラフ {#downstream-pipeline-graphs}

パイプラインに[ダウンストリームパイプライン](downstream_pipelines.md)をトリガーするジョブが含まれている場合、パイプラインの詳細表示とミニグラフでダウンストリームパイプラインを表示できます。

パイプラインの詳細表示では、パイプライングラフの右側に、トリガーされたダウンストリームパイプラインごとにカードが表示されます。カードにカーソルを合わせ、どのジョブがダウンストリームパイプラインをトリガーしたかを確認します。カードを選択して、パイプライングラフの右側にダウンストリームパイプラインを表示します。

パイプラインミニグラフでは、トリガーされたすべてのダウンストリームパイプラインのステータスが、ミニグラフの右側に追加のステータスアイコンとして表示されます。ダウンストリームパイプラインのステータスアイコンを選択して、そのダウンストリームパイプラインの詳細ページに移動します。

## パイプラインの成功と期間のチャート {#pipeline-success-and-duration-charts}

パイプライン分析は、[**CI/CDの分析**ページ](../../user/analytics/ci_cd_analytics.md)で確認できます。

## パイプラインバッジ {#pipeline-badges}

パイプラインステータスとテストカバレッジレポートバッジは、各プロジェクトで使用および設定できます。パイプラインバッジをプロジェクトに追加する方法については、[パイプラインバッジ](settings.md#pipeline-badges)を参照してください。

## パイプラインAPI {#pipelines-api}

GitLabは、次の目的でAPIエンドポイントを提供します:

- 基本的な機能を実行するため。詳細については、[パイプラインAPI](../../api/pipelines.md)を参照してください。
- パイプラインスケジュールを管理するため。詳細については、[パイプラインスケジュールAPI](../../api/pipeline_schedules.md)を参照してください。
- パイプラインの実行をトリガーするため。詳細については、以下を参照してください:
  - [APIでパイプラインをトリガーする](../triggers/_index.md)。
  - [パイプライントリガーAPI](../../api/pipeline_triggers.md)。

## Runnerのrefspec {#ref-specs-for-runners}

Runnerがパイプラインジョブを取得すると、GitLabはそのジョブのメタデータを提供します。これには、[Git refspec](https://git-scm.com/book/en/v2/Git-Internals-The-Refspec)が含まれます。Git refspecは、どのref（ブランチまたはタグなど）とコミット（SHA1）をプロジェクトリポジトリからチェックアウトするかを定義します。

以下の表に、各パイプラインタイプに挿入されるrefspecを示します:

| パイプラインタイプ                                                     | refspec |
|-------------------------------------------------------------------|----------|
| ブランチのパイプライン                                             | `+<sha>:refs/pipelines/<id>`と`+refs/heads/<name>:refs/remotes/origin/<name>` |
| タグのパイプライン                                                 | `+<sha>:refs/pipelines/<id>`と`+refs/tags/<name>:refs/tags/<name>` |
| [マージリクエストパイプライン](merge_request_pipelines.md)              | `+refs/pipelines/<id>:refs/pipelines/<id>` |

`refs/heads/<name>`と`refs/tags/<name>`のrefは、プロジェクトリポジトリに存在します。GitLabは、パイプラインジョブの実行中に特別なref（`refs/pipelines/<id>`）を生成します。このrefは、関連付けられているブランチまたはタグが削除された後でも作成される場合があります。そのため、[環境の自動停止](../environments/_index.md#stopping-an-environment)やブランチ削除後にパイプラインを実行する可能性のある[マージトレイン](merge_trains.md)などの一部の機能で役立ちます。

## トラブルシューティング {#troubleshooting}

### ユーザー削除後もパイプラインサブスクリプションが継続する {#pipeline-subscriptions-continue-after-user-deletion}

ユーザーが[GitLab.comアカウントを削除](../../user/profile/account/delete_account.md#delete-your-own-account)しても、削除は7日間行われません。この期間中、そのユーザーが作成したパイプラインサブスクリプションは、そのユーザーの元の権限で引き続き実行されます。不正なパイプライン実行を防ぐため、削除されたユーザーのパイプラインサブスクリプション設定は、すぐに更新してください。

### **New Pipeline**（新しいパイプライン）ページに事前入力された変数が表示されない {#pre-filled-variables-do-not-show-up-in-new-pipeline-page}

パイプラインの定義済み変数が[別のファイルで定義されている](../yaml/includes.md)場合、**New Pipeline**（新しいパイプライン）ページに表示されないことがあります。別のファイルにアクセスする権限が必要です。そうでない場合、定義済みの変数を表示できません。
