---
stage: Fulfillment
group: Utilization
info: This page is maintained by Developer Relations, author @dnsmichi, see <https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation>
title: ストレージ管理を自動化する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このページでは、GitLab REST APIを使用してストレージの使用状況を管理するための、ストレージ分析とクリーンアップを自動化する方法について説明します。

[パイプライン効率性](../ci/pipelines/pipeline_efficiency.md)を向上させることによって、ストレージの使用状況を管理することもできます。

API自動化に関する詳細については、[GitLabコミュニティフォーラムとDiscord](https://about.gitlab.com/community/)も使用できます。

> [!warning]
> このページのスクリプト例はデモンストレーションのみを目的としており、本番環境では使用しないでください。例を使用して、ストレージ自動化用の独自のスクリプトを設計およびテストできます。

## API要件 {#api-requirements}

ストレージ管理を自動化するには、GitLab.comまたはGitLab Self-Managedのインスタンスが[GitLab REST API](../api/api_resources.md)にアクセスできる必要があります。

### API認証スコープ {#api-authentication-scope}

APIで[認証する](../api/rest/authentication.md)には、次のスコープを使用します:

- ストレージ分析:
  - `read_api`スコープを使用した読み取りAPIアクセス。
  - すべてのプロジェクトにおけるデベロッパー、メンテナー、またはオーナーのロール。
- ストレージクリーンアップ:
  - `api`スコープを使用したフルAPIアクセス。
  - すべてのプロジェクトにおけるメンテナーまたはオーナーのロール。

コマンドラインツールまたはプログラミング言語を使用して、REST APIを操作できます。

### コマンドラインツール {#command-line-tools}

APIリクエストを送信するには、次のいずれかをインストールします:

- お好みのパッケージマネージャーでcURL。
- [GitLab CLI](https://docs.gitlab.com/cli/)を使用し、`glab api`サブコマンドを使用します。

JSONレスポンスをフォーマットするには、`jq`をインストールします。詳細については、[生産的なDevOpsワークフローのヒント: を参照してください: jqとCI/CDのLint自動化によるJSONフォーマット](https://about.gitlab.com/blog/devops-workflows-json-format-jq-ci-cd-lint/)。

これらのツールをREST APIで使用するには:

{{< tabs >}}

{{< tab title="cURL" >}}

```shell
export GITLAB_TOKEN=xxx

curl --silent --header "Authorization: Bearer $GITLAB_TOKEN" "https://gitlab.com/api/v4/user" | jq
```

{{< /tab >}}

{{< tab title="GitLab CLI" >}}

```shell
glab auth login

glab api groups/YOURGROUPNAME/projects
```

{{< /tab >}}

{{< /tabs >}}

#### GitLab CLIの使用 {#using-the-gitlab-cli}

一部のAPIエンドポイントでは、すべての結果を取得するために[ページネーション](../api/rest/_index.md#pagination)と後続のページのフェッチが必要です。GitLab CLIはフラグ`--paginate`を提供します。

JSONデータとしてフォーマットされたPOSTボディを必要とするリクエストは、`key=value`のペアとして`--raw-field`パラメータに渡すことができます。

詳細については、[GitLab CLIエンドポイントのドキュメント](https://docs.gitlab.com/cli/#commands)を参照してください。

### APIクライアントライブラリ {#api-client-libraries}

このページで説明されているストレージ管理とクリーンアップの自動化メソッドでは、以下を使用します:

- 豊富な機能を持つプログラミングインターフェースを提供する[`python-gitlab`](https://python-gitlab.readthedocs.io/en/stable/)ライブラリ。
- [GitLab APIとPython](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-python/)プロジェクトにある`get_all_projects_top_level_namespace_storage_analysis_cleanup_example.py`スクリプト。

`python-gitlab`ライブラリのユースケースの詳細については、[効率的なDevSecOpsワークフロー: を参照してください: 実践的な`python-gitlab` API自動化](https://about.gitlab.com/blog/efficient-devsecops-workflows-hands-on-python-gitlab-api-automation/)。

他のAPIクライアントライブラリの詳細については、[サードパーティクライアント](../api/rest/third_party_clients.md)を参照してください。

> [!note]
> GitLab Duoコード提案を使用して、コードをより効率的に記述します。

## ストレージ分析 {#storage-analysis}

### ストレージタイプを特定する {#identify-storage-types}

[プロジェクトAPIエンドポイント](../api/projects.md#list-all-projects)は、GitLabインスタンス内のプロジェクトの統計情報を提供します。プロジェクトAPIエンドポイントを使用するには、`statistics`キーをブール値`true`に設定します。このデータは、次のストレージタイプごとのプロジェクトのストレージ消費量に関するインサイトを提供します:

- `storage_size`: 全体的なストレージ
- `lfs_objects_size`: LFSオブジェクトストレージ
- `job_artifacts_size`: ジョブアーティファクトストレージ
- `packages_size`: パッケージストレージ
- `repository_size`: Gitリポジトリストレージ
- `snippets_size`: スニペットストレージ
- `uploads_size`: アップロードストレージ
- `wiki_size`: Wikiストレージ

ストレージタイプを特定するには:

{{< tabs >}}

{{< tab title="cURL" >}}

```shell
curl --silent --header "Authorization: Bearer $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/$GL_PROJECT_ID?statistics=true" | jq --compact-output '.id,.statistics' | jq
48349590
{
  "commit_count": 2,
  "storage_size": 90241770,
  "repository_size": 3521,
  "wiki_size": 0,
  "lfs_objects_size": 0,
  "job_artifacts_size": 90238249,
  "pipeline_artifacts_size": 0,
  "packages_size": 0,
  "snippets_size": 0,
  "uploads_size": 0
}
```

{{< /tab >}}

{{< tab title="GitLab CLI" >}}

```shell
export GL_PROJECT_ID=48349590
glab api --method GET projects/$GL_PROJECT_ID --field 'statistics=true' | jq --compact-output '.id,.statistics' | jq
48349590
{
  "commit_count": 2,
  "storage_size": 90241770,
  "repository_size": 3521,
  "wiki_size": 0,
  "lfs_objects_size": 0,
  "job_artifacts_size": 90238249,
  "pipeline_artifacts_size": 0,
  "packages_size": 0,
  "snippets_size": 0,
  "uploads_size": 0
}
```

{{< /tab >}}

{{< tab title="Python" >}}

```python
project_obj = gl.projects.get(project.id, statistics=True)

print("Project {n} statistics: {s}".format(n=project_obj.name_with_namespace, s=json.dump(project_obj.statistics, indent=4)))
```

{{< /tab >}}

{{< /tabs >}}

プロジェクトの統計情報をターミナルに出力するには、`GL_GROUP_ID`環境変数をエクスポートしてスクリプトを実行します:

```shell
export GL_TOKEN=xxx
export GL_GROUP_ID=56595735

pip3 install python-gitlab
python3 get_all_projects_top_level_namespace_storage_analysis_cleanup_example.py

Project Developer Evangelism and Technical Marketing at GitLab  / playground / Artifact generator group / Gen Job Artifacts 4 statistics: {
    "commit_count": 2,
    "storage_size": 90241770,
    "repository_size": 3521,
    "wiki_size": 0,
    "lfs_objects_size": 0,
    "job_artifacts_size": 90238249,
    "pipeline_artifacts_size": 0,
    "packages_size": 0,
    "snippets_size": 0,
    "uploads_size": 0
}
```

### プロジェクトとグループのストレージを分析する {#analyze-storage-in-projects-and-groups}

複数のプロジェクトとグループの分析を自動化できます。たとえば、最上位のネームスペースレベルから開始し、すべてのサブグループとプロジェクトを再帰的に分析できます。異なるストレージタイプを分析することもできます。

複数のサブグループとプロジェクトを分析するアルゴリズムの例を次に示します:

1. 最上位ネームスペースのIDをフェッチします。[ネームスペース/グループの概要](namespace/_index.md#types-of-namespaces)からID値をコピーできます。
1. トップレベルグループからすべての[サブグループ](../api/groups.md#list-subgroups)をフェッチし、IDをリストに保存します。
1. すべてのグループをループして、各グループからすべての[プロジェクト](../api/groups.md#list-projects)をフェッチし、IDをリストに保存します。
1. 分析するストレージタイプを特定し、プロジェクト統計やジョブアーティファクトなどのプロジェクト属性から情報を収集します。
1. すべてのプロジェクトをグループごとにグループ化し、そのストレージ情報の概要を出力します。

`glab`を使用したShellアプローチは、小規模な分析により適している場合があります。大規模な分析の場合は、APIクライアントライブラリを使用するスクリプトを使用する必要があります。この種類のスクリプトは、可読性、データストレージ、フロー制御、テスト、再利用性を向上させることができます。

スクリプトが[APIレート制限](../security/rate_limits.md)に達しないようにするため、以下のサンプルコードは並列APIリクエスト用に最適化されていません。

このアルゴリズムを実装するには:

{{< tabs >}}

{{< tab title="GitLab CLI" >}}

```shell
export GROUP_NAME="gitlab-da"

# Return subgroup IDs
glab api groups/$GROUP_NAME/subgroups | jq --compact-output '.[]' | jq --compact-output '.id'
12034712
67218622
67162711
67640130
16058698
12034604

# Loop over all subgroups to get subgroups, until the result set is empty. Example group: 12034712
glab api groups/12034712/subgroups | jq --compact-output '.[]' | jq --compact-output '.id'
56595735
70677315
67218606
70812167

# Lowest group level
glab api groups/56595735/subgroups | jq --compact-output '.[]' | jq --compact-output '.id'
# empty result, return and continue with analysis

# Fetch projects from all collected groups. Example group: 56595735
glab api groups/56595735/projects | jq --compact-output '.[]' | jq --compact-output '.id'
48349590
48349263
38520467
38520405

# Fetch storage types from a project (ID 48349590): Job artifacts in the `artifacts` key
glab api projects/48349590/jobs | jq --compact-output '.[]' | jq --compact-output '.id, .artifacts'
4828297946
[{"file_type":"archive","size":52444993,"filename":"artifacts.zip","file_format":"zip"},{"file_type":"metadata","size":156,"filename":"metadata.gz","file_format":"gzip"},{"file_type":"trace","size":3140,"filename":"job.log","file_format":null}]
4828297945
[{"file_type":"archive","size":20978113,"filename":"artifacts.zip","file_format":"zip"},{"file_type":"metadata","size":157,"filename":"metadata.gz","file_format":"gzip"},{"file_type":"trace","size":3147,"filename":"job.log","file_format":null}]
4828297944
[{"file_type":"archive","size":10489153,"filename":"artifacts.zip","file_format":"zip"},{"file_type":"metadata","size":158,"filename":"metadata.gz","file_format":"gzip"},{"file_type":"trace","size":3146,"filename":"job.log","file_format":null}]
4828297943
[{"file_type":"archive","size":5244673,"filename":"artifacts.zip","file_format":"zip"},{"file_type":"metadata","size":157,"filename":"metadata.gz","file_format":"gzip"},{"file_type":"trace","size":3145,"filename":"job.log","file_format":null}]
4828297940
[{"file_type":"archive","size":1049089,"filename":"artifacts.zip","file_format":"zip"},{"file_type":"metadata","size":157,"filename":"metadata.gz","file_format":"gzip"},{"file_type":"trace","size":3140,"filename":"job.log","file_format":null}]
```

{{< /tab >}}

{{< tab title="Python" >}}

```python
#!/usr/bin/env python

import datetime
import gitlab
import os
import sys

GITLAB_SERVER = os.environ.get('GL_SERVER', 'https://gitlab.com')
GITLAB_TOKEN = os.environ.get('GL_TOKEN') # token requires developer permissions
PROJECT_ID = os.environ.get('GL_PROJECT_ID') #optional
GROUP_ID = os.environ.get('GL_GROUP_ID') #optional

if __name__ == "__main__":
    if not GITLAB_TOKEN:
        print("🤔 Please set the GL_TOKEN env variable.")
        sys.exit(1)

    gl = gitlab.Gitlab(GITLAB_SERVER, private_token=GITLAB_TOKEN, pagination="keyset", order_by="id", per_page=100)

    # Collect all projects, or prefer projects from a group id, or a project id
    projects = []

    # Direct project ID
    if PROJECT_ID:
        projects.append(gl.projects.get(PROJECT_ID))
    # Groups and projects inside
    elif GROUP_ID:
        group = gl.groups.get(GROUP_ID)

        for project in group.projects.list(include_subgroups=True, get_all=True):
            manageable_project = gl.projects.get(project.id , lazy=True)
            projects.append(manageable_project)

    for project in projects:
        jobs = project.jobs.list(pagination="keyset", order_by="id", per_page=100, iterator=True)
        for job in jobs:
            print("DEBUG: ID {i}: {a}".format(i=job.id, a=job.attributes['artifacts']))
```

{{< /tab >}}

{{< /tabs >}}

スクリプトは、プロジェクトのジョブアーティファクトをJSON形式のリストで出力します:

```json
[
    {
        "file_type": "archive",
        "size": 1049089,
        "filename": "artifacts.zip",
        "file_format": "zip"
    },
    {
        "file_type": "metadata",
        "size": 157,
        "filename": "metadata.gz",
        "file_format": "gzip"
    },
    {
        "file_type": "trace",
        "size": 3146,
        "filename": "job.log",
        "file_format": null
    }
]
```

## CI/CDパイプラインストレージを管理する {#manage-cicd-pipeline-storage}

ジョブアーティファクトはパイプラインストレージの大部分を消費し、ジョブログも数百キロバイトを生成する可能性があります。不要なジョブアーティファクトを最初に削除し、分析後にジョブログをクリーンアップする必要があります。

> [!warning]
> ジョブログとアーティファクトの削除は、元に戻すことができない破壊的なアクションです。注意して使用してください。レポートアーティファクト、ジョブログ、メタデータファイルなど、特定のファイルを削除すると、これらのファイルをデータソースとして使用するGitLab機能に影響します。

### ジョブアーティファクトをリストする {#list-job-artifacts}

パイプラインストレージを分析するには、[ジョブAPIエンドポイント](../api/jobs.md#list-all-jobs-for-a-project)を使用してジョブアーティファクトのリストを取得できます。エンドポイントは、ジョブアーティファクトの`file_type`キーを`artifacts`属性で返します。`file_type`キーは、アーティファクトタイプを示します:

- `archive`は、生成されたジョブアーティファクトをzipファイルとして使用します。
- `metadata`は、Gzipファイル内の追加メタデータに使用されます。
- `trace`は、`job.log`をrawファイルとして使用します。

ジョブアーティファクトは、キャッシュファイルとしてディスクに書き込むことができるデータ構造を提供し、実装をテストするために使用できます。

すべてのプロジェクトをフェッチするためのサンプルコードに基づいて、Pythonスクリプトを拡張してさらに分析を行うことができます。

次の例は、プロジェクト内のジョブアーティファクトに対するクエリからの応答を示しています:

```json
[
    {
        "file_type": "archive",
        "size": 1049089,
        "filename": "artifacts.zip",
        "file_format": "zip"
    },
    {
        "file_type": "metadata",
        "size": 157,
        "filename": "metadata.gz",
        "file_format": "gzip"
    },
    {
        "file_type": "trace",
        "size": 3146,
        "filename": "job.log",
        "file_format": null
    }
]
```

スクリプトをどのように実装するかによって、次のいずれかを実行できます:

- すべてのジョブアーティファクトを収集し、スクリプトの最後に概要テーブルを出力します。
- 情報を直ちに出力します。

次の例では、ジョブアーティファクトが`ci_job_artifacts`リストに収集されます。スクリプトはすべてのプロジェクトをループし、以下をフェッチします:

- すべての属性を含む`project_obj`オブジェクト変数。
- `job`オブジェクトからの`artifacts`属性。

[キーセットページネーション](https://python-gitlab.readthedocs.io/en/stable/api-usage.html#pagination)を使用して、パイプラインとジョブの大規模なリストをイテレーションを行うことができます。

```python
   ci_job_artifacts = []

    for project in projects:
        project_obj = gl.projects.get(project.id)

        jobs = project.jobs.list(pagination="keyset", order_by="id", per_page=100, iterator=True)

        for job in jobs:
            artifacts = job.attributes['artifacts']
            #print("DEBUG: ID {i}: {a}".format(i=job.id, a=json.dumps(artifacts, indent=4)))
            if not artifacts:
                continue

            for a in artifacts:
                data = {
                    "project_id": project_obj.id,
                    "project_web_url": project_obj.name,
                    "project_path_with_namespace": project_obj.path_with_namespace,
                    "job_id": job.id,
                    "artifact_filename": a['filename'],
                    "artifact_file_type": a['file_type'],
                    "artifact_size": a['size']
                }

                ci_job_artifacts.append(data)

    print("\nDone collecting data.")

    if len(ci_job_artifacts) > 0:
        print("| Project | Job | Artifact name | Artifact type | Artifact size |\n|---------|-----|---------------|---------------|---------------|") # Start markdown friendly table
        for artifact in ci_job_artifacts:
            print('| [{project_name}]({project_web_url}) | {job_name} | {artifact_name} | {artifact_type} | {artifact_size} |'.format(project_name=artifact['project_path_with_namespace'], project_web_url=artifact['project_web_url'], job_name=artifact['job_id'], artifact_name=artifact['artifact_filename'], artifact_type=artifact['artifact_file_type'], artifact_size=render_size_mb(artifact['artifact_size'])))
    else:
        print("No artifacts found.")
```

スクリプトの最後に、ジョブアーティファクトがMarkdown形式のテーブルとして出力されます。テーブルの内容をイシューのコメントまたは説明にコピーしたり、GitLabリポジトリ内のMarkdownファイルを埋めたりすることができます。

```shell
$ python3 get_all_projects_top_level_namespace_storage_analysis_cleanup_example.py

| Project | Job | Artifact name | Artifact type | Artifact size |
|---------|-----|---------------|---------------|---------------|
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297946 | artifacts.zip | archive | 50.0154 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297946 | metadata.gz | metadata | 0.0001 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297946 | job.log | trace | 0.0030 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297945 | artifacts.zip | archive | 20.0063 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297945 | metadata.gz | metadata | 0.0001 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297945 | job.log | trace | 0.0030 |
```

### ジョブアーティファクトを一括削除する {#delete-job-artifacts-in-bulk}

Pythonスクリプトを使用して、一括削除するジョブアーティファクトの種類をフィルタリングできます。

APIクエリの結果をフィルタリングして比較します:

- アーティファクトの経過時間を計算するための`created_at`値。
- アーティファクトがサイズしきい値を満たしているかどうかを判断するための`size`属性。

一般的なリクエスト:

- 指定された日数より古いジョブアーティファクトを削除します。
- 指定されたストレージ量を超えるジョブアーティファクトを削除します。たとえば、100 MB。

次の例では、スクリプトはジョブ属性をループし、削除対象としてマークします。コレクションループがオブジェクトロックを削除すると、スクリプトは削除対象としてマークされたジョブアーティファクトを削除します。

```python
   for project in projects:
        project_obj = gl.projects.get(project.id)

        jobs = project.jobs.list(pagination="keyset", order_by="id", per_page=100, iterator=True)

        for job in jobs:
            artifacts = job.attributes['artifacts']
            if not artifacts:
                continue

            # Advanced filtering: Age and Size
            # Example: 90 days, 10 MB threshold (TODO: Make this configurable)
            threshold_age = 90 * 24 * 60 * 60
            threshold_size = 10 * 1024 * 1024

            # job age, need to parse API format: 2023-08-08T22:41:08.270Z
            created_at = datetime.datetime.strptime(job.created_at, '%Y-%m-%dT%H:%M:%S.%fZ')
            now = datetime.datetime.now()
            age = (now - created_at).total_seconds()
            # Shorter: Use a function
            # age = calculate_age(job.created_at)

            for a in artifacts:
                # Analysis collection code removed for readability

                # Advanced filtering: match job artifacts age and size against thresholds
                if (float(age) > float(threshold_age)) or (float(a['size']) > float(threshold_size)):
                    # mark job for deletion (cannot delete inside the loop)
                    jobs_marked_delete_artifacts.append(job)

    print("\nDone collecting data.")

    # Advanced filtering: Delete all job artifacts marked to being deleted.
    for job in jobs_marked_delete_artifacts:
        # delete the artifact
        print("DEBUG", job)
        job.delete_artifacts()

    # Print collection summary (removed for readability)
```

### プロジェクトのすべてのジョブアーティファクトを削除する {#delete-all-job-artifacts-for-a-project}

プロジェクトの[ジョブアーティファクト](../ci/jobs/job_artifacts.md)が不要な場合は、次のコマンドを使用してすべてのジョブアーティファクトを削除できます。このアクションは元に戻すことができません。

アーティファクトの削除には、削除するアーティファクトの数に応じて、数分から数時間かかる場合があります。APIに対するその後の分析クエリは、アーティファクトを誤検出として返す可能性があります。結果との混同を避けるため、追加のAPIリクエストをすぐに実行しないでください。

最新の成功したジョブの[アーティファクト](../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)は、デフォルトで保持されます。

プロジェクトのすべてのジョブアーティファクトを削除するには:

{{< tabs >}}

{{< tab title="cURL" >}}

```shell
export GL_PROJECT_ID=48349590

curl --silent --header "Authorization: Bearer $GITLAB_TOKEN" --request DELETE "https://gitlab.com/api/v4/projects/$GL_PROJECT_ID/artifacts"
```

{{< /tab >}}

{{< tab title="GitLab CLI" >}}

```shell
glab api --method GET projects/$GL_PROJECT_ID/jobs | jq --compact-output '.[]' | jq --compact-output '.id, .artifacts'

glab api --method DELETE projects/$GL_PROJECT_ID/artifacts
```

{{< /tab >}}

{{< tab title="Python" >}}

```python
        project.artifacts.delete()
```

{{< /tab >}}

{{< /tabs >}}

### ジョブログを削除 {#delete-job-logs}

ジョブログを削除すると、[ジョブ全体を消去](../api/jobs.md#erase-a-job)します。

GitLab CLIの例:

```shell
glab api --method GET projects/$GL_PROJECT_ID/jobs | jq --compact-output '.[]' | jq --compact-output '.id'

4836226184
4836226183
4836226181
4836226180

glab api --method POST projects/$GL_PROJECT_ID/jobs/4836226180/erase | jq --compact-output '.name,.status'
"generate-package: [1]"
"success"
```

`python-gitlab` APIライブラリでは、`job.delete_artifacts()`の代わりに[`job.erase()`](https://python-gitlab.readthedocs.io/en/stable/gl_objects/pipelines_and_jobs.html#jobs)を使用します。このAPIコールがブロックされないようにするには、ジョブアーティファクトを削除するAPIコールの間にスクリプトを短時間スリープするように設定します:

```python
    for job in jobs_marked_delete_artifacts:
        # delete the artifacts and job log
        print("DEBUG", job)
        #job.delete_artifacts()
        job.erase()
        # Sleep for 1 second
        time.sleep(1)
```

ジョブログの保持ポリシー作成のサポートは、[イシュー374717](https://gitlab.com/gitlab-org/gitlab/-/issues/374717)で提案されています。

### 古いパイプラインを削除する {#delete-old-pipelines}

パイプラインは全体のストレージ使用量には追加されませんが、必要に応じて[それらの削除を自動化](../ci/pipelines/settings.md#automatic-pipeline-cleanup)できます。

特定の日付に基づいてパイプラインを削除するには、`created_at`キーを指定します。日付を使用して、現在の日付とパイプラインが作成された日付との差を計算できます。経過時間がしきい値よりも長い場合、パイプラインは削除されます。

> [!note]
> `created_at`キーは、タイムスタンプからUnixエポック時刻に変換する必要があります。`date -d '2023-08-08T18:59:47.581Z' +%s`など。

GitLab CLIの例:

```shell
export GL_PROJECT_ID=48349590

glab api --method GET projects/$GL_PROJECT_ID/pipelines | jq --compact-output '.[]' | jq --compact-output '.id,.created_at'
960031926
"2023-08-08T22:09:52.745Z"
959884072
"2023-08-08T18:59:47.581Z"

glab api --method DELETE projects/$GL_PROJECT_ID/pipelines/960031926

glab api --method GET projects/$GL_PROJECT_ID/pipelines | jq --compact-output '.[]' | jq --compact-output '.id,.created_at'
959884072
"2023-08-08T18:59:47.581Z"
```

bashスクリプトを使用する次の例では:

- `jq`とGitLab CLIがインストールされ、認証されています。
- エクスポートされた環境変数`GL_PROJECT_ID`。GitLabの事前定義された変数`CI_PROJECT_ID`にデフォルト設定されています。
- GitLabインスタンスのURLを指すエクスポートされた環境変数`CI_SERVER_HOST`。

{{< tabs >}}

{{< tab title="glabとAPIを使用する" >}}

フルスクリプト`get_cicd_pipelines_compare_age_threshold_example.sh`は、[Linux Shellを使用したGitLab API](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-linux-shell)プロジェクトにあります。

```shell
#!/bin/bash

# Required programs:
# - GitLab CLI (glab): https://docs.gitlab.com/cli/
# - jq: https://jqlang.github.io/jq/

# Required variables:
# - PAT: Project Access Token with API scope and Owner role, or Personal Access Token with API scope
# - GL_PROJECT_ID: ID of the project where pipelines must be cleaned
# - AGE_THRESHOLD (optional): Maximum age in days of pipelines to keep (default: 90)

set -euo pipefail

# Constants
DEFAULT_AGE_THRESHOLD=90
SECONDS_PER_DAY=$((24 * 60 * 60))

# Functions
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

delete_pipeline() {
    local project_id=$1
    local pipeline_id=$2
    if glab api --method DELETE "projects/$project_id/pipelines/$pipeline_id"; then
        log_info "Deleted pipeline ID $pipeline_id"
    else
        log_error "Failed to delete pipeline ID $pipeline_id"
    fi
}

# Main script
main() {
    # Authenticate
    if ! glab auth login --hostname "$CI_SERVER_HOST" --token "$PAT"; then
        log_error "Authentication failed"
        exit 1
    fi

    # Set variables
    AGE_THRESHOLD=${AGE_THRESHOLD:-$DEFAULT_AGE_THRESHOLD}
    AGE_THRESHOLD_IN_SECONDS=$((AGE_THRESHOLD * SECONDS_PER_DAY))
    GL_PROJECT_ID=${GL_PROJECT_ID:-$CI_PROJECT_ID}

    # Fetch pipelines
    PIPELINES=$(glab api --method GET "projects/$GL_PROJECT_ID/pipelines")
    if [ -z "$PIPELINES" ]; then
        log_error "Failed to fetch pipelines or no pipelines found"
        exit 1
    fi

    # Process pipelines
    echo "$PIPELINES" | jq -r '.[] | [.id, .created_at] | @tsv' | while IFS=$'\t' read -r id created_at; do
        CREATED_AT_TS=$(date -d "$created_at" +%s)
        NOW=$(date +%s)
        AGE=$((NOW - CREATED_AT_TS))

        if [ "$AGE" -gt "$AGE_THRESHOLD_IN_SECONDS" ]; then
            log_info "Pipeline ID $id created at $created_at is older than threshold $AGE_THRESHOLD days, deleting..."
            delete_pipeline "$GL_PROJECT_ID" "$id"
        else
            log_info "Pipeline ID $id created at $created_at is not older than threshold $AGE_THRESHOLD days. Ignoring."
        fi
    done
}

main
```

{{< /tab >}}

{{< tab title="glab CLIを使用する" >}}

フルスクリプト`cleanup-old-pipelines.sh`は、[Linux Shellを使用したGitLab API](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-linux-shell)プロジェクトにあります。

```shell
#!/bin/bash

set -euo pipefail

# Required environment variables:
# PAT: Project Access Token with API scope and Owner role, or Personal Access Token with API scope.
# Optional environment variables:
# AGE_THRESHOLD: Maximum age (in days) of pipelines to keep. Default: 90 days.
# REPO: Repository to clean up. If not set, the current repository will be used.
# CI_SERVER_HOST: GitLab server hostname.

# Function to display error message and exit
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Validate required environment variables
[[ -z "${PAT:-}" ]] && error_exit "PAT (Project Access Token or Personal Access Token) is not set."
[[ -z "${CI_SERVER_HOST:-}" ]] && error_exit "CI_SERVER_HOST is not set."

# Set and validate AGE_THRESHOLD
AGE_THRESHOLD=${AGE_THRESHOLD:-90}
[[ ! "$AGE_THRESHOLD" =~ ^[0-9]+$ ]] && error_exit "AGE_THRESHOLD must be a positive integer."

AGE_THRESHOLD_IN_HOURS=$((AGE_THRESHOLD * 24))

echo "Deleting pipelines older than $AGE_THRESHOLD days"

# Authenticate with GitLab
glab auth login --hostname "$CI_SERVER_HOST" --token "$PAT" || error_exit "Authentication failed"

# Delete old pipelines
delete_cmd="glab ci delete --older-than ${AGE_THRESHOLD_IN_HOURS}h"
if [[ -n "${REPO:-}" ]]; then
    delete_cmd+=" --repo $REPO"
fi

$delete_cmd || error_exit "Pipeline deletion failed"

echo "Pipeline cleanup completed."
```

{{< /tab >}}

{{< tab title="PythonとAPIを使用する" >}}

[`python-gitlab` APIライブラリ](https://python-gitlab.readthedocs.io/en/stable/gl_objects/pipelines_and_jobs.html#project-pipelines)と`created_at`属性を使用して、ジョブアーティファクトの経過時間を比較する同様のアルゴリズムを実装することもできます:

```python
        # ...

        for pipeline in project.pipelines.list(iterator=True):
            pipeline_obj = project.pipelines.get(pipeline.id)
            print("DEBUG: {p}".format(p=json.dumps(pipeline_obj.attributes, indent=4)))

            created_at = datetime.datetime.strptime(pipeline.created_at, '%Y-%m-%dT%H:%M:%S.%fZ')
            now = datetime.datetime.now()
            age = (now - created_at).total_seconds()

            threshold_age = 90 * 24 * 60 * 60

            if (float(age) > float(threshold_age)):
                print("Deleting pipeline", pipeline.id)
                pipeline_obj.delete()
```

{{< /tab >}}

{{< /tabs >}}

### ジョブアーティファクトの有効期限設定をリストする {#list-expiry-settings-for-job-artifacts}

アーティファクトストレージを管理するには、アーティファクトの有効期限が切れるタイミングを更新または設定できます。アーティファクトの有効期限設定は、`.gitlab-ci.yml`内の各ジョブ設定で構成されます。

複数のプロジェクトがあり、CI/CD設定でジョブ定義がどのように編成されているかに基づいて、有効期限設定を見つけるのが難しい場合があります。スクリプトを使用して、CI/CD設定全体を検索できます。これには、`extends`や`!reference`のように値を継承した後に解決されるオブジェクトへのアクセスが含まれます。

スクリプトは結合されたCI/CD設定ファイルを取得し、アーティファクトキーを検索して以下を実行します:

- 有効期限設定のないジョブを特定します。
- アーティファクトの有効期限が設定されているジョブの有効期限設定を返します。

スクリプトがアーティファクトの有効期限設定を検索する方法を次のプロセスで説明します:

1. 結合されたCI/CD設定を生成するには、スクリプトはすべてのプロジェクトをループし、[`ci_lint()`](https://python-gitlab.readthedocs.io/en/stable/gl_objects/ci_lint.html)メソッドを呼び出します。
1. `yaml_load`関数は、結合された設定をPythonデータ構造に読み込むして、さらなる分析を行います。
1. `script`キーも持つ辞書は、`artifacts`キーが存在する可能性のあるジョブ定義として識別されます。
1. はいの場合、スクリプトはサブキー`expire_in`を解析し、詳細を保存して後でMarkdownテーブルの概要で出力します。

```python
    ci_job_artifacts_expiry = {}

    # Loop over projects, fetch .gitlab-ci.yml, run the linter to get the full translated config, and extract the `artifacts:` setting
    # https://python-gitlab.readthedocs.io/en/stable/gl_objects/ci_lint.html
    for project in projects:
            project_obj = gl.projects.get(project.id)
            project_name = project_obj.name
            project_web_url = project_obj.web_url
            try:
                lint_result = project.ci_lint.get()
                if lint_result.merged_yaml is None:
                    continue

                ci_pipeline = yaml.safe_load(lint_result.merged_yaml)
                #print("Project {p} Config\n{c}\n\n".format(p=project_name, c=json.dumps(ci_pipeline, indent=4)))

                for k in ci_pipeline:
                    v = ci_pipeline[k]
                    # This is a job object with `script` attribute
                    if isinstance(v, dict) and 'script' in v:
                        print(".", end="", flush=True) # Get some feedback that it is still looping
                        artifacts = v['artifacts'] if 'artifacts' in v else {}

                        print("Project {p} job {j} artifacts {a}".format(p=project_name, j=k, a=json.dumps(artifacts, indent=4)))

                        expire_in = None
                        if 'expire_in' in artifacts:
                            expire_in = artifacts['expire_in']

                        store_key = project_web_url + '_' + k
                        ci_job_artifacts_expiry[store_key] = { 'project_web_url': project_web_url,
                                                        'project_name': project_name,
                                                        'job_name': k,
                                                        'artifacts_expiry': expire_in}

            except Exception as e:
                 print(f"Exception searching artifacts on ci_pipelines: {e}".format(e=e))

    if len(ci_job_artifacts_expiry) > 0:
        print("| Project | Job | Artifact expiry |\n|---------|-----|-----------------|") #Start markdown friendly table
        for k, details in ci_job_artifacts_expiry.items():
            if details['job_name'][0] == '.':
                continue # ignore job templates that start with a '.'
            print(f'| [{ details["project_name"] }]({details["project_web_url"]}) | { details["job_name"] } | { details["artifacts_expiry"] if details["artifacts_expiry"] is not None else "❌ N/A" } |')
```

スクリプトは、Markdown形式の概要テーブルを以下のように生成します:

- プロジェクト名とURL。
- ジョブ名。
- `artifacts:expire_in`設定、または設定がない場合は`N/A`。

スクリプトは、次のようなジョブテンプレートは出力しません:

- `.`文字で始まる。
- アーティファクトを生成するランタイムジョブオブジェクトとしてインスタンス化されていない。

```shell
export GL_GROUP_ID=56595735

# Install script dependencies
python3 -m pip install 'python-gitlab[yaml]'

python3 get_all_cicd_config_artifacts_expiry.py

| Project | Job | Artifact expiry |
|---------|-----|-----------------|
| [Gen Job Artifacts 4](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4) | generator | 30 days |
| [Gen Job Artifacts with expiry and included jobs](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs) | included-job10 | 10 days |
| [Gen Job Artifacts with expiry and included jobs](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs) | included-job1 | 1 days |
| [Gen Job Artifacts with expiry and included jobs](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs) | included-job30 | 30 days |
| [Gen Job Artifacts with expiry and included jobs](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs) | generator | 30 days |
| [Gen Job Artifacts 2](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-2) | generator | ❌ N/A |
| [Gen Job Artifacts 1](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-1) | generator | ❌ N/A |
```

`get_all_cicd_config_artifacts_expiry.py`スクリプトは、[PythonプロジェクトとGitLab API](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-python/)にあります。

または、APIリクエストで[高度な検索](search/advanced_search.md)を使用できます。次の例では、[スコープ: blob](../api/search.md#scope-blobs)を使用して、すべての`*.yml`ファイルで文字列`artifacts`を検索します:

```shell
# https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs
export GL_PROJECT_ID=48349263

glab api --method GET projects/$GL_PROJECT_ID/search --field "scope=blobs" --field "search=expire_in filename:*.yml"
```

インベントリのアプローチの詳細については、[GitLabがオープンソースコンテナイメージのDocker Hubからの削除を軽減するのにどのように役立つか](https://about.gitlab.com/blog/how-gitlab-can-help-mitigate-deletion-open-source-images-docker-hub/)を参照してください。

### ジョブアーティファクトのデフォルトの有効期限を設定する {#set-default-expiry-for-job-artifacts}

プロジェクトのジョブアーティファクトのデフォルトの有効期限を設定するには、`.gitlab-ci.yml`ファイルに`expire_in`値を指定します:

```yaml
default:
    artifacts:
        expire_in: 1 week
```

## コンテナレジストリストレージを管理する {#manage-container-registries-storage}

コンテナレジストリは、[プロジェクト](../api/container_registry.md#within-a-project)または[グループ](../api/container_registry.md#within-a-group)で利用できます。クリーンアップ戦略を実装するために、両方の場所を分析できます。

### コンテナレジストリをリストする {#list-container-registries}

プロジェクト内のコンテナレジストリをリストするには:

{{< tabs >}}

{{< tab title="cURL" >}}

```shell
export GL_PROJECT_ID=48057080

curl --silent --header "Authorization: Bearer $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/$GL_PROJECT_ID/registry/repositories" | jq --compact-output '.[]' | jq --compact-output '.id,.location' | jq
4435617
"registry.gitlab.com/gitlab-da/playground/container-package-gen-group/docker-alpine-generator"

curl --silent --header "Authorization: Bearer $GITLAB_TOKEN" "https://gitlab.com/api/v4/registry/repositories/4435617?size=true" | jq --compact-output '.id,.location,.size'
4435617
"registry.gitlab.com/gitlab-da/playground/container-package-gen-group/docker-alpine-generator"
3401613
```

{{< /tab >}}

{{< tab title="GitLab CLI" >}}

```shell
export GL_PROJECT_ID=48057080

glab api --method GET projects/$GL_PROJECT_ID/registry/repositories | jq --compact-output '.[]' | jq --compact-output '.id,.location'
4435617
"registry.gitlab.com/gitlab-da/playground/container-package-gen-group/docker-alpine-generator"

glab api --method GET registry/repositories/4435617 --field='size=true' | jq --compact-output '.id,.location,.size'
4435617
"registry.gitlab.com/gitlab-da/playground/container-package-gen-group/docker-alpine-generator"
3401613

glab api --method GET projects/$GL_PROJECT_ID/registry/repositories/4435617/tags | jq --compact-output '.[]' | jq --compact-output '.name'
"latest"

glab api --method GET projects/$GL_PROJECT_ID/registry/repositories/4435617/tags/latest | jq --compact-output '.name,.created_at,.total_size'
"latest"
"2023-08-07T19:20:20.894+00:00"
3401613
```

{{< /tab >}}

{{< /tabs >}}

### コンテナイメージを一括削除する {#delete-container-images-in-bulk}

When you [コンテナイメージタグを一括削除](../api/container_registry.md#delete-registry-repository-tags-in-bulk)する際に、以下を構成できます:

- タグ名と保持するイメージ（`name_regex_keep`）または削除するイメージ（`name_regex_delete`）に一致する正規表現
- タグ名に一致する保持するイメージタグの数（`keep_n`）
- イメージタグが削除されるまでの日数（`older_than`）

> [!warning]
> GitLab.comでは、コンテナレジストリの規模により、このAPIによって削除されるタグの数が制限されています。コンテナレジストリに多数のタグを削除する必要がある場合、一部のみが削除されます。APIを複数回呼び出す必要がある場合があります。タグの自動削除をスケジュールするには、代わりに[クリーンアップポリシー](#create-a-cleanup-policy-for-containers)を使用します。

次の例では、[`python-gitlab` APIライブラリ](https://python-gitlab.readthedocs.io/en/stable/gl_objects/repository_tags.html)を使用してタグのリストをフェッチし、フィルターパラメータを指定して`delete_in_bulk()`メソッドを呼び出します。

```python
        repositories = project.repositories.list(iterator=True, size=True)
        if len(repositories) > 0:
            repository = repositories.pop()
            tags = repository.tags.list()

            # Cleanup: Keep only the latest tag
            repository.tags.delete_in_bulk(keep_n=1)
            # Cleanup: Delete all tags older than 1 month
            repository.tags.delete_in_bulk(older_than="1m")
            # Cleanup: Delete all tags matching the regex `v.*`, and keep the latest 2 tags
            repository.tags.delete_in_bulk(name_regex_delete="v.+", keep_n=2)
```

### コンテナのクリーンアップポリシーを作成する {#create-a-cleanup-policy-for-containers}

プロジェクトのREST APIエンドポイントを使用して、コンテナの[クリーンアップポリシー](packages/container_registry/reduce_container_registry_storage.md#use-the-cleanup-policy-api)を作成します。クリーンアップポリシーを設定すると、仕様に一致するすべてのコンテナイメージが自動的に削除されます。追加のAPI自動化スクリプトは必要ありません。

属性をボディパラメータとして送信するには:

- 標準入力から読み取るために`--input -`パラメータを使用します。
- `Content-Type`ヘッダーを設定します。

次の例では、GitLab CLIを使用してクリーンアップポリシーを作成します:

```shell
export GL_PROJECT_ID=48057080

echo '{"container_expiration_policy_attributes":{"cadence":"1month","enabled":true,"keep_n":1,"older_than":"14d","name_regex":".*","name_regex_keep":".*-main"}}' | glab api --method PUT --header 'Content-Type: application/json;charset=UTF-8' projects/$GL_PROJECT_ID --input -

...

  "container_expiration_policy": {
    "cadence": "1month",
    "enabled": true,
    "keep_n": 1,
    "older_than": "14d",
    "name_regex": ".*",
    "name_regex_keep": ".*-main",
    "next_run_at": "2023-09-08T21:16:25.354Z"
  },

```

### コンテナイメージを最適化する {#optimize-container-images}

コンテナイメージを最適化して、コンテナレジストリ内のイメージサイズと全体のストレージ消費量を削減できます。詳細については、[パイプライン効率性のドキュメント](../ci/pipelines/pipeline_efficiency.md#optimize-docker-images)を参照してください。

## パッケージレジストリストレージを管理する {#manage-package-registry-storage}

パッケージレジストリは、[プロジェクト](../api/packages.md#for-a-project)または[グループ](../api/packages.md#for-a-group)で利用できます。

### パッケージとファイルをリストする {#list-packages-and-files}

次の例は、GitLab CLIを使用して定義されたプロジェクトIDからパッケージをフェッチする方法を示しています。結果セットは、`jq`コマンドチェーンでフィルタリングできる辞書項目の配列です。

```shell
# https://gitlab.com/gitlab-da/playground/container-package-gen-group/generic-package-generator
export GL_PROJECT_ID=48377643

glab api --method GET projects/$GL_PROJECT_ID/packages | jq --compact-output '.[]' | jq --compact-output '.id,.name,.package_type'
16669383
"generator"
"generic"
16671352
"generator"
"generic"
16672235
"generator"
"generic"
16672237
"generator"
"generic"
```

パッケージIDを使用して、パッケージ内のファイルとそのサイズを検査します。

```shell
glab api --method GET projects/$GL_PROJECT_ID/packages/16669383/package_files | jq --compact-output '.[]' |
 jq --compact-output '.package_id,.file_name,.size'

16669383
"nighly.tar.gz"
10487563
```

同様の自動化Shellスクリプトは、[古いパイプラインの削除](#delete-old-pipelines)セクションで作成されます。

次のスクリプト例では、`python-gitlab`ライブラリを使用してすべてのパッケージをループでフェッチし、そのパッケージファイルをループして`file_name`と`size`属性を出力します。

```python
        packages = project.packages.list(order_by="created_at")

        for package in packages:

            package_files = package.package_files.list()
            for package_file in package_files:
                print("Package name: {p} File name: {f} Size {s}".format(
                    p=package.name, f=package_file.file_name, s=render_size_mb(package_file.size)))
```

### パッケージを削除する {#delete-packages}

[パッケージ内のファイルを削除](../api/packages.md#delete-a-package-file)すると、パッケージが破損する可能性があります。自動クリーンアップメンテナンスを実行する際には、パッケージを削除する必要があります。

パッケージを削除するには、GitLab CLIを使用して`--method`パラメータを`DELETE`に変更します:

```shell
glab api --method DELETE projects/$GL_PROJECT_ID/packages/16669383
```

パッケージのサイズを計算し、サイズしきい値と比較するには、`python-gitlab`ライブラリを使用して[パッケージとファイルをリストする](#list-packages-and-files)セクションで説明されているコードを拡張できます。

次のコード例では、パッケージの経過時間も計算し、条件が一致した場合にパッケージを削除します:

```python
        packages = project.packages.list(order_by="created_at")
        for package in packages:
            package_size = 0.0

            package_files = package.package_files.list()
            for package_file in package_files:
                print("Package name: {p} File name: {f} Size {s}".format(
                    p=package.name, f=package_file.file_name, s=render_size_mb(package_file.size)))

                package_size =+ package_file.size

            print("Package size: {s}\n\n".format(s=render_size_mb(package_size)))

            threshold_size = 10 * 1024 * 1024

            if (package_size > float(threshold_size)):
                print("Package size {s} > threshold {t}, deleting package.".format(
                    s=render_size_mb(package_size), t=render_size_mb(threshold_size)))
                package.delete()

            threshold_age = 90 * 24 * 60 * 60
            package_age = created_at = calculate_age(package.created_at)

            if (float(package_age > float(threshold_age))):
                print("Package age {a} > threshold {t}, deleting package.".format(
                    a=render_age_time(package_age), t=render_age_time(threshold_age)))
                package.delete()
```

このコードは、さらなる分析に使用できる次の出力を生成します:

```shell
Package name: generator File name: nighly.tar.gz Size 10.0017
Package size: 10.0017
Package size 10.0017 > threshold 10.0000, deleting package.

Package name: generator File name: 1-nightly.tar.gz Size 1.0004
Package size: 1.0004

Package name: generator File name: 10-nightly.tar.gz Size 10.0018
Package name: generator File name: 20-nightly.tar.gz Size 20.0033
Package size: 20.0033
Package size 20.0033 > threshold 10.0000, deleting package.
```

### 依存プロキシ {#dependency-proxy}

[クリーンアップポリシー](packages/dependency_proxy/reduce_dependency_proxy_storage.md#cleanup-policies)と、[APIを使用してキャッシュをパージする](packages/dependency_proxy/reduce_dependency_proxy_storage.md#use-the-api-to-clear-the-cache)方法を確認してください。

## 出力の可読性を向上させる {#improve-output-readability}

タイムスタンプの秒数を期間形式に変換したり、rawバイトをより分かりやすい形式で出力したりする必要がある場合があります。以下のヘルパー関数を使用して、可読性向上のために値を変換できます:

```shell
# Current Unix timestamp
date +%s

# Convert `created_at` date time with timezone to Unix timestamp
date -d '2023-08-08T18:59:47.581Z' +%s
```

`python-gitlab` APIライブラリを使用するPythonの例:

```python
def render_size_mb(v):
    return "%.4f" % (v / 1024 / 1024)

def render_age_time(v):
    return str(datetime.timedelta(seconds = v))

# Convert `created_at` date time with timezone to Unix timestamp
def calculate_age(created_at_datetime):
    created_at_ts = datetime.datetime.strptime(created_at_datetime, '%Y-%m-%dT%H:%M:%S.%fZ')
    now = datetime.datetime.now()
    return (now - created_at_ts).total_seconds()
```

## ストレージ管理自動化のテスト {#testing-for-storage-management-automation}

ストレージ管理自動化をテストするには、テストデータを生成したり、ストレージを投入したりして、分析と削除が期待どおりに機能することを確認する必要がある場合があります。次のセクションでは、短時間でストレージblobをテストおよび生成するためのツールとヒントを提供します。

### ジョブアーティファクトを生成する {#generate-job-artifacts}

CI/CDジョブマトリックスビルドを使用して、偽のアーティファクトblobを生成するテストプロジェクトを作成します。毎日アーティファクトを生成するCI/CDパイプラインを追加します。

1. 新しいプロジェクトを作成します。
1. ジョブアーティファクトジェネレータの設定を含めるには、次のスニペットを`.gitlab-ci.yml`に追加します。

   ```yaml
   include:
       - remote: https://gitlab.com/gitlab-da/use-cases/efficiency/job-artifact-generator/-/raw/main/.gitlab-ci.yml
   ```

1. [パイプラインスケジュールを設定](../ci/pipelines/schedules.md#create-a-pipeline-schedule)します。
1. [パイプラインをトリガーする](../ci/pipelines/schedules.md#run-manually)。

または、毎日生成される86 MBを`MB_COUNT`変数で異なる値に減らします。

```yaml
include:
    - remote: https://gitlab.com/gitlab-da/use-cases/efficiency/job-artifact-generator/-/raw/main/.gitlab-ci.yml

generator:
    parallel:
        matrix:
            - MB_COUNT: [1, 5, 10, 20, 50]

```

詳細については、[ジョブアーティファクトジェネレーターReadme](https://gitlab.com/gitlab-da/use-cases/efficiency/job-artifact-generator)と[例のグループ](https://gitlab.com/gitlab-da/playground/artifact-gen-group)を参照してください。

### 有効期限付きジョブアーティファクトを生成する {#generate-job-artifacts-with-expiry}

プロジェクトのCI/CD設定は、ジョブ定義を以下で指定します:

- main `.gitlab-ci.yml`設定ファイル。
- `artifacts:expire_in`設定。
- プロジェクトファイルとテンプレート。

分析スクリプトをテストするために、[`gen-job-artifacts-expiry-included-jobs`](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs)プロジェクトは設定例を提供します。

```yaml
# .gitlab-ci.yml
include:
    - include_jobs.yml

default:
  artifacts:
      paths:
          - '*.txt'

.gen-tmpl:
    script:
        - dd if=/dev/urandom of=${$MB_COUNT}.txt bs=1048576 count=${$MB_COUNT}

generator:
    extends: [.gen-tmpl]
    parallel:
        matrix:
            - MB_COUNT: [1, 5, 10, 20, 50]
    artifacts:
        untracked: false
        when: on_success
        expire_in: 30 days

# include_jobs.yml
.includeme:
    script:
        - dd if=/dev/urandom of=1.txt bs=1048576 count=1

included-job10:
    script:
        - echo "Servus"
        - !reference [.includeme, script]
    artifacts:
        untracked: false
        when: on_success
        expire_in: 10 days

included-job1:
    script:
        - echo "Gruezi"
        - !reference [.includeme, script]
    artifacts:
        untracked: false
        when: on_success
        expire_in: 1 days

included-job30:
    script:
        - echo "Grias di"
        - !reference [.includeme, script]
    artifacts:
        untracked: false
        when: on_success
        expire_in: 30 days
```

### コンテナイメージを生成する {#generate-container-images}

例のグループ[`container-package-gen-group`](https://gitlab.com/gitlab-da/playground/container-package-gen-group)は、次のようなプロジェクトを提供します:

- Dockerfileでベースイメージを使用して新しいイメージをビルドする。
- `Docker.gitlab-ci.yml`テンプレートを含めて、GitLab.comでイメージをビルドする。
- パイプラインスケジュールを設定して、毎日新しいイメージを生成します。

フォーク可能なプロジェクト例:

- [`docker-alpine-generator`](https://gitlab.com/gitlab-da/playground/container-package-gen-group/docker-alpine-generator)
- [`docker-python-generator`](https://gitlab.com/gitlab-da/playground/container-package-gen-group/docker-python-generator)

### 汎用パッケージを生成する {#generate-generic-packages}

例のプロジェクト[`generic-package-generator`](https://gitlab.com/gitlab-da/playground/container-package-gen-group/generic-package-generator)は、次のようなプロジェクトを提供します:

- ランダムなテキストblobを生成し、現在のUnixタイムスタンプをリリースバージョンとするtarballを作成します。
- Unixタイムスタンプをリリースバージョンとして使用し、tarballを汎用パッケージレジストリにアップロードします。

汎用パッケージを生成するには、このスタンドアロンの`.gitlab-ci.yml`設定を使用できます:

```yaml
generate-package:
  parallel:
    matrix:
      - MB_COUNT: [1, 5, 10, 20]
  before_script:
    - apt update && apt -y install curl
  script:
    - dd if=/dev/urandom of="${MB_COUNT}.txt" bs=1048576 count=${MB_COUNT}
    - tar czf "generated-$MB_COUNT-nighly-`date +%s`.tar.gz" "${MB_COUNT}.txt"
    - 'curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file "generated-$MB_COUNT-nighly-`date +%s`.tar.gz" "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/generator/`date +%s`/${MB_COUNT}-nightly.tar.gz"'

  artifacts:
    paths:
      - '*.tar.gz'

```

### フォークでストレージ使用量を生成する {#generate-storage-usage-with-forks}

[フォークのコスト要因](storage_usage_quotas.md#view-project-fork-storage-usage)を使用してストレージ使用量をテストするには、次のプロジェクトを使用します:

- [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab)を新しいネームスペースまたはグループにフォークする（LFS、Gitリポジトリを含む）。
- [`gitlab-com/www-gitlab-com`](https://gitlab.com/gitlab-com/www-gitlab-com)を新しいネームスペースまたはグループにフォークする。

## コミュニティリソース {#community-resources}

次のリソースは公式にはサポートされていません。元に戻せない破壊的なクリーンアップコマンドを実行する前に、スクリプトとチュートリアルを必ずテストしてください。

- フォーラムのトピック: [ストレージ管理自動化リソース](https://forum.gitlab.com/t/storage-management-automation-resources/91184)
- スクリプト: [GitLabストレージアナライザー](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-storage-analyzer)、[GitLabデベロッパーエバンジェリズムチーム](https://gitlab.com/gitlab-da/)による非公式プロジェクト。同様のコード例は、このドキュメントのハウツーで確認できます。
