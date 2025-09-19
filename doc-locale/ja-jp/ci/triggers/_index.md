---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: APIでパイプラインをトリガーする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

特定のブランチまたはタグのパイプラインをトリガーするには、[パイプライントリガーAPIエンドポイント](../../api/pipeline_triggers.md)へのAPIコールを使用します。

[GitLab CI/CDに移行する](../migration/plan_a_migration.md)場合は、他のプロバイダーのジョブからAPIエンドポイントを呼び出すことで、GitLab CI/CDパイプラインをトリガーできます。たとえば、[Jenkins](../migration/jenkins.md)または[CircleCI](../migration/circleci.md)からの移行の一部として使用できます。

APIで認証する場合は、以下を使用できます。

- [パイプライントリガートークン](#create-a-pipeline-trigger-token)を使用して、[パイプライントリガーAPIエンドポイント](../../api/pipeline_triggers.md)でブランチまたはタグのパイプラインをトリガーする。
- [CI/CDジョブトークン](../jobs/ci_job_token.md)を使用して、[マルチプロジェクトパイプラインをトリガー](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api)する。
- [APIアクセス権を持つ別のトークン](../../security/tokens/_index.md)を使用して、[プロジェクトパイプラインAPIエンドポイント](../../api/pipelines.md#create-a-new-pipeline)経由で新しいパイプラインを作成する。

## パイプライントリガートークンを作成する {#create-a-pipeline-trigger-token}

パイプライントリガートークンを生成し、それを使用してAPIコールを認証することで、ブランチまたはタグのパイプラインをトリガーできます。このトークンは、ユーザーのプロジェクトのアクセスと権限を借用します。

前提要件:

- プロジェクトでのメンテナー以上のロールが必要です。

トリガートークンを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **パイプライントリガートークン**を展開します。
1. **新しいトークンを追加**を選択します
1. 説明を入力し、**パイプライントリガートークンの作成**を選択します。
   - 自分が作成したすべてのトリガーについては、トークン全体を表示してコピーできます。
   - 他のプロジェクトメンバーが作成したトークンについては、最初の4文字のみを表示できます。

{{< alert type="warning" >}}

パブリックプロジェクトでトークンを平文で保存したり、悪意のあるユーザーがアクセスできる方法で保存したりすることは、セキュリティ上のリスクとなります。流出したトリガートークンは、予定外のデプロイを強制したり、CI/CD変数へのアクセスを試みたり、その他の不正な目的に使用されたりする恐れがあります。[マスクされたCI/CD変数](../variables/_index.md#mask-a-cicd-variable)は、トリガートークンのセキュリティを向上させるのに役立ちます。トークンを安全に保つ方法の詳細については、[セキュリティに関する考慮事項](../../security/tokens/_index.md#security-considerations)を参照してください。

{{< /alert >}}

## パイプラインをトリガーする {#trigger-a-pipeline}

[パイプライントリガートークンを作成](#create-a-pipeline-trigger-token)したら、APIにアクセスできるツール、またはWebhookを使用して、そのトークンでパイプラインをトリガーできます。

### cURLを使用する {#use-curl}

cURLを使用して、[パイプライントリガーAPIエンドポイント](../../api/pipeline_triggers.md)でパイプラインをトリガーできます。次に例を示します。

- 複数行のcURLコマンドを使用します。

  ```shell
  curl --request POST \
       --form token=<token> \
       --form ref=<ref_name> \
       "https://gitlab.example.com/api/v4/projects/<project_id>/trigger/pipeline"
  ```

- cURLを使用し、クエリ文字列で`<token>`と`<ref_name>`を渡します。

  ```shell
  curl --request POST \
       "https://gitlab.example.com/api/v4/projects/<project_id>/trigger/pipeline?token=<token>&ref=<ref_name>"
  ```

それぞれの例で、以下の値を置き換えます。

- URLを`https://gitlab.com`またはインスタンスのURLに置き換えます。
- `<token>`をトリガートークンに置き換えます。
- `<ref_name>`を`main`などのブランチ名またはタグ名に置き換えます。
- `<project_id>`を`123456`などのプロジェクトIDに置き換えます。プロジェクトIDは、[プロジェクトの概要ページ](../../user/project/working_with_projects.md#find-the-project-id)に表示されています。

### CI/CDジョブを使用する {#use-a-cicd-job}

パイプライントリガートークンが設定されたCI/CDジョブを使用して、別のパイプラインが実行されたときにパイプラインをトリガーできます。

たとえば、`project-A`でタグが作成されたときに`project-B`の`main`ブランチでパイプラインをトリガーするには、プロジェクトAの`.gitlab-ci.yml`ファイルに次のジョブを追加します。

```yaml
trigger_pipeline:
  stage: deploy
  script:
    - 'curl --fail --request POST --form token=$MY_TRIGGER_TOKEN --form ref=main "${CI_API_V4_URL}/projects/123456/trigger/pipeline"'
  rules:
    - if: $CI_COMMIT_TAG
  environment: production
```

この例では:

- `1234`は`project-B`のプロジェクトIDです。プロジェクトIDは、[プロジェクトの概要ページ](../../user/project/working_with_projects.md#find-the-project-id)に表示されています。
- [`rules`](../yaml/_index.md#rules)により、`project-A`にタグが追加されるたびにこのジョブが実行されます。
- `MY_TRIGGER_TOKEN`は、トリガートークンを格納した[マスクされたCI/CD変数](../variables/_index.md#mask-a-cicd-variable)です。

### Webhookを使用する {#use-a-webhook}

別のプロジェクトのWebhookからパイプラインをトリガーするには、プッシュイベントとタグイベントに対して次のようなWebhook URLを使用します。

```plaintext
https://gitlab.example.com/api/v4/projects/<project_id>/ref/<ref_name>/trigger/pipeline?token=<token>
```

以下の値を置き換えます。

- URLを`https://gitlab.com`またはインスタンスのURLに置き換えます。
- `<project_id>`を`123456`などのプロジェクトIDに置き換えます。プロジェクトIDは、[プロジェクトの概要ページ](../../user/project/working_with_projects.md#find-the-project-id)に表示されています。
- `<ref_name>`を`main`などのブランチ名またはタグ名に置き換えます。この値は、Webhookペイロード内の`ref_name`よりも優先されます。ペイロードの`ref`は、ソースリポジトリでトリガーを起動したブランチです。`ref_name`にスラッシュが含まれている場合は、URLエンコードを行う必要があります。
- `<token>`をパイプライントリガートークンに置き換えます。

#### Webhookペイロードへアクセスする {#access-webhook-payload}

Webhookを使用してパイプラインをトリガーする場合は、`TRIGGER_PAYLOAD`という[定義済みCI/CD変数](../variables/predefined_variables.md)を使用してWebhookペイロードにアクセスできます。ペイロードは[ファイルタイプ変数](../variables/_index.md#use-file-type-cicd-variables)として公開されるため、`cat $TRIGGER_PAYLOAD`または同様のコマンドでデータにアクセスできます。

### APIコールでCI/CD変数を渡す {#pass-cicd-variables-in-the-api-call}

トリガーAPIコールでは任意の数の[CI/CD変数](../variables/_index.md)を渡すことができます。ただし、[パイプラインの動作を制御する場合はインプットを使用](#pass-pipeline-inputs-in-the-api-call)したほうが、CI/CD変数よりもセキュリティと柔軟性が向上します。

これらの変数は[最優先](../variables/_index.md#cicd-variable-precedence)され、同じ名前のすべての変数をオーバーライドします。

パラメータの形式は`variables[key]=value`です。次に例を示します。

```shell
curl --request POST \
     --form token=TOKEN \
     --form ref=main \
     --form "variables[UPLOAD_TO_S3]=true" \
     "https://gitlab.example.com/api/v4/projects/123456/trigger/pipeline"
```

トリガーされたパイプラインのCI/CD変数は各ジョブのページに表示されますが、オーナーおよびメンテナーロールを持つユーザーのみがその値を参照できます。

![UPLOAD_TO_CIがtrueに設定されていることを示すCIトリガーのトークン4e19の設定パネル](img/trigger_variables_v11_6.png)

パイプラインの動作を制御する場合にインプットを使用すると、CI/CD変数を使用するよりもセキュリティと柔軟性が向上します。

### APIコールでパイプラインのインプットを渡す {#pass-pipeline-inputs-in-the-api-call}

トリガーAPIコールでパイプラインのインプットを渡すことができます。[インプット](../inputs/_index.md)は、組み込みの検証とドキュメントを使用してパイプラインをパラメータ化するための構造化された方法を提供します。

パラメータの形式は`inputs[name]=value`です。次に例を示します。

```shell
curl --request POST \
     --form token=TOKEN \
     --form ref=main \
     --form "inputs[environment]=production" \
     "https://gitlab.example.com/api/v4/projects/123456/trigger/pipeline"
```

インプット値は、パイプラインの`spec:inputs`セクションで定義された型と制約に従って検証されます。

```yaml
spec:
  inputs:
    environment:
      type: string
      description: "Deployment environment"
      options: [dev, staging, production]
      default: dev
```

## パイプライントリガートークンを取り消す {#revoke-a-pipeline-trigger-token}

パイプライントリガートークンを取り消すには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **パイプラインのトリガー**を展開します。
1. 取り消すトリガートークンの左側にある、**取り消し**（{{< icon name="remove" >}}）を選択します。

取り消されたトリガートークンを元に戻すことはできません。

## トリガーされたパイプラインで実行するようにCI/CDジョブを設定する {#configure-cicd-jobs-to-run-in-triggered-pipelines}

トリガーされたパイプラインで[ジョブを実行するタイミングを設定](../jobs/job_control.md)するには、次の方法を使用します。

- [`rules`](../yaml/_index.md#rules)と[定義済みCI/CD変数](../variables/predefined_variables.md)`$CI_PIPELINE_SOURCE`を組み合わせて使用する。
- [`only`/`except`](../yaml/deprecated_keywords.md#onlyrefs--exceptrefs)キーワードを使用する。ただし、推奨されるキーワードは`rules`です。

| `$CI_PIPELINE_SOURCE`値 | `only`/`except`キーワード | トリガー方式      |
|-----------------------------|--------------------------|---------------------|
| `trigger`                   | `triggers`               | [トリガートークン](#create-a-pipeline-trigger-token)を使用して、[パイプライントリガーAPI](../../api/pipeline_triggers.md)によってトリガーされるパイプラインで適用されます。 |
| `pipeline`                  | `pipelines`              | [`$CI_JOB_TOKEN`](../jobs/ci_job_token.md)を使用するか、CI/CD設定ファイルで[`trigger`](../yaml/_index.md#trigger)キーワードを使用して、[パイプライントリガーAPI](../../api/pipeline_triggers.md)によってトリガーされる[マルチプロジェクトパイプライン](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api)で適用されます。 |

さらに、パイプライントリガートークンでトリガーされたパイプラインでは、定義済みCI/CD変数`$CI_PIPELINE_TRIGGERED`が`true`に設定されます。

## どのパイプライントリガートークンが使用されたかを確認する {#see-which-pipeline-trigger-token-was-used}

単一のジョブページにアクセスすると、どのパイプライントリガートークンによってジョブが実行されたかを確認できます。トリガートークンの一部が、右側のサイドバーの**ジョブの詳細**に表示されます。

トリガートークンでトリガーされたパイプラインでは、**ビルド > ジョブ**において、ジョブに`triggered`というラベルが付きます。

## トラブルシューティング {#troubleshooting}

### Webhookでパイプラインをトリガーしたときの`403 Forbidden` {#403-forbidden-when-you-trigger-a-pipeline-with-a-webhook}

Webhookでパイプラインをトリガーすると、APIが`{"message":"403 Forbidden"}`応答を返す場合があります。トリガーループを回避するため、[パイプラインイベント](../../user/project/integrations/webhook_events.md#pipeline-events)を使用してパイプラインをトリガーしないでください。

### パイプラインをトリガーしたときの`404 Not Found` {#404-not-found-when-triggering-a-pipeline}

パイプラインをトリガーした際に`{"message":"404 Not Found"}`応答が返される場合、原因として、パイプライントリガートークンではなく[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)を使用していることが考えられます。[新しいトリガートークンを作成](#create-a-pipeline-trigger-token)し、パーソナルアクセストークンの代わりに使用してください。

パイプラインをトリガーした際に`{"message":"404 Not Found"}`応答が返される原因として、`GET`リクエストを使用している可能性も考えられます。パイプラインは、`POST`リクエストでのみトリガーできます。

### パイプラインをトリガーしたときの`The requested URL returned error: 400` {#the-requested-url-returned-error-400-when-triggering-a-pipeline}

`ref`に存在しないブランチ名を指定してパイプラインをトリガーしようとすると、GitLabは`The requested URL returned error: 400`を返します。

たとえば、別のブランチ名をデフォルトブランチとして使用しているプロジェクトで、誤ってブランチ名に`main`を指定してしまうといったケースが考えられます。

このエラーのもう1つの原因として、`CI_PIPELINE_SOURCE`値が`trigger`の場合にパイプラインの作成を禁止するルールが設定されていることが考えられます。次に例を示します。

```yaml
rules:
  - if: $CI_PIPELINE_SOURCE == "trigger"
    when: never
```

[`workflow:rules`](../yaml/_index.md#workflowrules)を参照して、`CI_PIPELINE_SOURCE`の値が`trigger`の場合にもパイプラインが作成できることを確認してください。
