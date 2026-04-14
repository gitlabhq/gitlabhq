---
stage: ModelOps
group: MLOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: MLflowクライアントの互換性
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.11で[導入](https://gitlab.com/groups/gitlab-org/-/epics/8560)されました。
- GitLab 17.8で[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/9341)になりました。

{{< /history >}}

[MLflow](https://mlflow.org/)は、機械学習の実験追跡に広く使われているオープンソースツールです。GitLabの[モデル実験追跡](_index.md)およびGitLabの[モデルレジストリ](../model_registry/_index.md)は、MLflowクライアントと互換性があります。この設定には、既存のコードへの最小限の変更が必要です。

## MLflowクライアントインテグレーションを有効にする {#enable-mlflow-client-integration}

前提条件: 

- GitLabと互換性のあるPythonクライアント:
  - 推奨: The [GitLab MLOps Python client](https://gitlab.com/gitlab-org/modelops/mlops/gitlab-mlops)。
  - もう1つのオプションは、MLflowクライアントバージョンです。MLflowクライアントは[GitLabと互換性](https://gitlab.com/gitlab-org/modelops/mlops/mlflow-compatibility-qa)があります。
- A [個人](../../../profile/personal_access_tokens.md) 、[プロジェクト](../../settings/project_access_tokens.md) 、または[グループ](../../../group/settings/group_access_tokens.md)アクセストークンで、デベロッパー、メンテナー、またはオーナーロールと`api`スコープを持つもの。
- プロジェクトID。プロジェクトIDを見つけるには、次の手順を実行します。
  1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
  1. **設定** > **一般**を選択します。

ローカル環境からMLflowクライアント互換性を使用するには:

1. 追跡URIとトークンの環境変数を、コードを実行するホストに設定します。これは、ローカル環境、CIパイプライン、またはリモートホストのいずれかです。例: 

   ```shell
   export MLFLOW_TRACKING_URI="<your gitlab endpoint>/api/v4/projects/<your project id>/ml/mlflow"
   export MLFLOW_TRACKING_TOKEN="<your_access_token>"
   ```

1. トレーニングコードに`mlflow.set_tracking_uri()`への呼び出しが含まれている場合は、それを削除します。

モデルレジストリで、右上にあるオーバーフローメニューから、縦方向の省略記号 ({{< icon name="ellipsis_v" >}}) を選択して追跡URIをコピーできます。

## モデル実験 {#model-experiments}

トレーニングコードを実行する際、MLflowクライアントを使用して、実験、実行、モデル、モデルバージョンを作成し、パラメータ、メトリクス、メタデータ、およびアーティファクトをGitLabに記録できます。

実験が記録されると、`/<your project>/-/ml/experiments`の下にリストされます。

実行は登録され、実験、モデル、またはモデルバージョンを選択することで探索できます。

### 実験の作成 {#creating-an-experiment}

```python
import mlflow

# Create a new experiment
experiment_id = mlflow.create_experiment(name="<your_experiment>")

# Setting the active experiment also creates a new experiment if it doesn't exist.
mlflow.set_experiment(experiment_name="<your_experiment>")
```

### 実行の作成 {#creating-a-run}

```python
import mlflow

# Creating a run requires an experiment ID or an active experiment
mlflow.set_experiment(experiment_name="<your_experiment>")

# Runs can be created with or without a context manager
with mlflow.start_run() as run:
    print(run.info.run_id)
    # Your training code

with mlflow.start_run():
    # Your training code
```

### パラメータとメトリクスの記録 {#logging-parameters-and-metrics}

```python
import mlflow

mlflow.set_experiment(experiment_name="<your_experiment>")

with mlflow.start_run():
    # Parameter keys need to be unique in the scope of the run
    mlflow.log_param(key="param_1", value=1)

    # Metrics can be updated throughout the run
    mlflow.log_metric(key="metrics_1", value=1)
    mlflow.log_metric(key="metrics_1", value=2)
```

### アーティファクトの記録 {#logging-artifacts}

```python
import mlflow

mlflow.set_experiment(experiment_name="<your_experiment>")

with mlflow.start_run():
    # Plaintext text files can be logged as artifacts using `log_text`
    mlflow.log_text('Hello, World!', artifact_file='hello.txt')

    mlflow.log_artifact(
        local_path='<local/path/to/file.txt>',
        artifact_path='<optional relative path to log the artifact at>'
    )
```

### モデルの記録 {#logging-models}

サポートされているいずれかの[MLflowモデルフレーバー](https://mlflow.org/docs/latest/models.html#built-in-model-flavors)を使用して、モデルを記録できます。モデルフレーバーを使用して記録するとメタデータが記録され、さまざまなツールや環境間でモデルを管理、読み込み、およびデプロイするのが容易になります。

```python
import mlflow
from sklearn.ensemble import RandomForestClassifier

mlflow.set_experiment(experiment_name="<your_experiment>")

with mlflow.start_run():
    # Create and train a simple model
    model = RandomForestClassifier(n_estimators=10, random_state=42)
    model.fit(X_train, y_train)

    # Log the model using MLflow sklearn mode flavour
    mlflow.sklearn.log_model(model, artifact_path="")
```

### 実行の読み込み {#loading-a-run}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/509595)されました。

{{< /history >}}

GitLabのモデルレジストリから実行を読み込み、たとえば予測を行うことができます。

```python
import mlflow
import mlflow.pyfunc

run_id = "<your_run_id>"
download_path = "models"  # Local folder to download to

mlflow.pyfunc.load_model(f"runs:/{run_id}/", dst_path=download_path)

sample_input = [[1,0,3,4],[2,0,1,2]]
model.predict(data=sample_input)
```

### 実行をCI/CDジョブに関連付ける {#associating-a-run-to-a-cicd-job}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119454)されました。
- [変更](https://gitlab.com/groups/gitlab-org/-/epics/9423)され、GitLab 17.1でベータになりました。

{{< /history >}}

トレーニングコードがCI/CDジョブから実行されている場合、GitLabはその情報を使用して実行メタデータを強化できます。実行をCI/CDジョブに関連付けるには:

1. [プロジェクトCI変数](../../../../ci/variables/_index.md)に、次の変数を含めます:
   - `MLFLOW_TRACKING_URI`: `"<your gitlab endpoint>/api/v4/projects/<your project id>/ml/mlflow"`
   - `MLFLOW_TRACKING_TOKEN`: `<your_access_token>`

1. 実行コンテキスト内のトレーニングコードに、次のコードスニペットを追加します:

   ```python
   import os
   import mlflow

   with mlflow.start_run(run_name=f"Run {index}"):
     # Your training code

     # Start of snippet to be included
     if os.getenv('GITLAB_CI'):
       mlflow.set_tag('gitlab.CI_JOB_ID', os.getenv('CI_JOB_ID'))
     # End of snippet to be included
   ```

## モデルレジストリ {#model-registry}

MLflowクライアントを使用して、モデルとモデルバージョンを管理することもできます。モデルは`/<your project>/-/ml/models`の下に登録されます。

### モデル {#models}

#### モデルの作成 {#creating-a-model}

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
description = 'Model description'
model = client.create_registered_model(model_name, description=description)
```

**備考**

- `create_registered_model`の引数`tags`は無視されます。
- `name`はプロジェクト内で一意である必要があります。
- `name`は既存の実験の名前であってはなりません。

#### モデルのフェッチ {#fetching-a-model}

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
model = client.get_registered_model(model_name)
```

#### モデルの更新 {#updating-a-model}

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
description = 'New description'
client.update_registered_model(model_name, description=description)
```

#### モデルの削除 {#deleting-a-model}

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
client.delete_registered_model(model_name)
```

### モデルへの実行の記録 {#logging-runs-to-a-model}

すべてのモデルには、`[model]`でプレフィックスされた同じ名前の関連する実験があります。モデルに実行を記録するには、正しい名前を渡して実験を使用します:

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
exp = client.get_experiment_by_name(f"[model]{model_name}")
run = client.create_run(exp.experiment_id)
```

### モデルバージョン {#model-version}

#### モデルバージョンの作成 {#creating-a-model-version}

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
description = 'Model version description'
model_version = client.create_model_version(model_name, source="", description=description)
```

バージョンパラメータが渡されない場合、最新のアップロードされたバージョンから自動的にインクリメントされます。モデルバージョン作成時にタグを渡すことで、バージョンを設定できます。このバージョンは[SemVer](https://semver.org/)形式に従う必要があります。

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
version = '<your_version>'
tags = { "gitlab.version": version }
client.create_model_version(model_name, version, description=description, tags=tags)
```

**備考**

- 引数`run_id`は無視されます。すべてのモデルバージョンは実行として機能します。実行からのモデルバージョンの作成はまだサポートされていません。
- 引数`source`は無視されます。GitLabは、モデルバージョンファイル用のパッケージの場所を作成します。
- 引数`run_link`は無視されます。
- 引数`await_creation_for`は無視されます。

#### モデルの更新 {#updating-a-model-1}

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
version = '<your_version>'
description = 'New description'
client.update_model_version(model_name, version, description=description)
```

#### モデルバージョンのフェッチ {#fetching-a-model-version}

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
version = '<your_version>'
client.get_model_version(model_name, version)
```

#### モデルの最新バージョンの取得 {#getting-latest-versions-of-a-model}

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
client.get_latest_versions(model_name)
```

**備考**

- 引数`stages`は無視されます。
- バージョンは、最も高いセマンティックバージョンによって順序付けされます。

#### モデルバージョンの読み込み {#loading-a-model-version}

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
version = '<your_version'  # for example: '1.0.0'

# Alternatively search the version
version = mlflow.search_registered_models(filter_string="name='{model_name}'")[0].latest_versions[0].version

model = mlflow.pyfunc.load_model(f"models:/{model_name}/{latest_version}")

# Or load the latest version
model = mlflow.pyfunc.load_model(f"models:/{model_name}/latest")
```

#### モデルバージョンへのメトリクスとパラメータの記録 {#logging-metrics-and-parameters-to-a-model-version}

すべてのモデルバージョンは実行でもあり、ユーザーはパラメータとメトリクスを記録できます。実行IDは、GitLabのモデルバージョンページ、またはMLflowクライアントを使用して見つけることができます:

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
version = '<your_version>'
model_version = client.get_model_version(model_name, version)
run_id = model_version.run_id

# Your training code

client.log_metric(run_id, '<metric_name>', '<metric_value>')
client.log_param(run_id, '<param_name>', '<param_value>')
client.log_batch(run_id, metric_list, param_list, tag_list)
```

各ファイルは5 GBのサイズ制限があるため、より大きなモデルをパーティション化する必要があります。

#### モデルバージョンへのアーティファクトの記録 {#logging-artifacts-to-a-model-version}

GitLabは、MLflowクライアントがファイルをアップロードするために使用できるパッケージを作成します。

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
version = '<your_version>'
model_version = client.get_model_version(model_name, version)
run_id = model_version.run_id

# Your training code

client.log_artifact(run_id, '<local/path/to/file.txt>', artifact_path="")
client.log_figure(run_id, figure, artifact_file="my_plot.png")
client.log_dict(run_id, my_dict, artifact_file="my_dict.json")
client.log_image(run_id, image, artifact_file="image.png")
```

アーティファクトは`https/<your project>/-/ml/models/<model_id>/versions/<version_id>`で利用可能になります。

#### モデルバージョンをCI/CDジョブにリンクする {#linking-a-model-version-to-a-cicd-job}

実行と同様に、モデルバージョンをCI/CDジョブにリンクすることも可能です:

```python
import os
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
version = '<your_version>'
model_version = client.get_model_version(model_name, version)
run_id = model_version.run_id

# Your training code

if os.getenv('GITLAB_CI'):
    client.set_tag(model_version.run_id, 'gitlab.CI_JOB_ID', os.getenv('CI_JOB_ID'))
```

## サポートされているMLflowクライアントメソッドと注意点 {#supported-mlflow-client-methods-and-caveats}

GitLabは、MLflowクライアントの次のメソッドをサポートしています。詳細は[MLflowドキュメント](https://mlflow.org/docs/latest/index.html)を参照してください。以下のメソッドのMlflowClientの同等機能も、同じ注意点とともにサポートされています。

| 方法                   | サポート対象       | 追加されたバージョン | コメント                                                                                     |
|--------------------------|-----------------|---------------|----------------------------------------------------------------------------------------------|
| `create_experiment`      | はい             | 15.11         |                                                                                              |
| `get_experiment`         | はい             | 15.11         |                                                                                              |
| `get_experiment_by_name` | はい             | 15.11         |                                                                                              |
| `delete_experiment`      | はい             | 17.5          |                                                                                              |
| `set_experiment`         | はい             | 15.11         |                                                                                              |
| `get_run`                | はい             | 15.11         |                                                                                              |
| `delete_run`             | はい             | 17.5          |                                                                                              |
| `start_run`              | はい             | 15.11         | (16.3) 名前が指定されていない場合、実行にはランダムなニックネームが割り当てられます。                        |
| `search_runs`            | はい             | 15.11         | (16.4) `experiment_ids`は、単一の実験IDと列またはメトリクスによる順序のみをサポートします。 |
| `log_artifact`           | はい（注意点あり） | 15.11         | (15.11) `artifact_path`は空である必要があります。ディレクトリはサポートされていません。                         |
| `log_artifacts`          | はい（注意点あり） | 15.11         | (15.11) `artifact_path`は空である必要があります。ディレクトリはサポートされていません。                         |
| `log_batch`              | はい             | 15.11         |                                                                                              |
| `log_metric`             | はい             | 15.11         |                                                                                              |
| `log_metrics`            | はい             | 15.11         |                                                                                              |
| `log_param`              | はい             | 15.11         |                                                                                              |
| `log_params`             | はい             | 15.11         |                                                                                              |
| `log_figure`             | はい             | 15.11         |                                                                                              |
| `log_image`              | はい             | 15.11         |                                                                                              |
| `log_text`               | はい（注意点あり） | 15.11         | (15.11) ディレクトリはサポートされていません。                                                        |
| `log_dict`               | はい（注意点あり） | 15.11         | (15.11) ディレクトリはサポートされていません。                                                        |
| `set_tag`                | はい             | 15.11         |                                                                                              |
| `set_tags`               | はい             | 15.11         |                                                                                              |
| `set_terminated`         | はい             | 15.11         |                                                                                              |
| `end_run`                | はい             | 15.11         |                                                                                              |
| `update_run`             | はい             | 15.11         |                                                                                              |
| `log_model`              | 部分         | 15.11         | (15.11) アーティファクトは保存されますが、モデルデータは保存されません。`artifact_path`は空である必要があります。          |
| `load_model`             | はい             | 17.5          |                                                                                              |
| `download_artifacts`     | はい             | 17.9          |                                                                                              |
| `list_artifacts`         | はい             | 17.9          |                                                                                              |

その他のMLflowClientメソッド:

| 方法                    | サポート対象        | 追加されたバージョン | コメント                                         |
|---------------------------|------------------|---------------|--------------------------------------------------|
| `create_registered_model` | はい（注意点あり） | 16.8          | [注意点を参照](#creating-a-model)                   |
| `get_registered_model`    | はい              | 16.8          |                                                  |
| `delete_registered_model` | はい              | 16.8          |                                                  |
| `update_registered_model` | はい              | 16.8          |                                                  |
| `create_model_version`    | はい（注意点あり） | 16.8          | [注意点を参照](#creating-a-model-version)           |
| `get_model_version`       | はい              | 16.8          |                                                  |
| `get_latest_versions`     | はい（注意点あり） | 16.8          | [注意点を参照](#getting-latest-versions-of-a-model) |
| `update_model_version`    | はい              | 16.8          |                                                  |
| `create_registered_model` | はい              | 16.8          |                                                  |
| `create_registered_model` | はい              | 16.8          |                                                  |

## 既知の問題 {#known-issues}

- [サポートされているメソッド](#supported-mlflow-client-methods-and-caveats)にリストされていないMLflowクライアントメソッドも機能する可能性がありますが、テストされていません。
- 実験と実行の作成中、Experimentタグは表示されませんが、保存されます。
