---
stage: Fulfillment
group: Utilization
info: This page is maintained by Developer Relations, author @dnsmichi, see <https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation>
title: 스토리지 관리 자동화
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 페이지에서는 GitLab REST API를 사용하여 스토리지 분석 및 정리를 자동화하고 스토리지 사용량을 관리하는 방법을 설명합니다.

[파이프라인 효율성](../ci/pipelines/pipeline_efficiency.md)을 개선하여 스토리지 사용량을 관리할 수도 있습니다.

API 자동화에 대한 추가 지원을 원하면 [GitLab 커뮤니티 포럼 및 Discord](https://about.gitlab.com/community/)를 사용할 수 있습니다.

> [!warning]
> 이 페이지의 스크립트 예제는 시연용으로만 제공되며 프로덕션 환경에서 사용하면 안 됩니다. 예제를 사용하여 스토리지 자동화에 대한 자신의 스크립트를 설계하고 테스트할 수 있습니다.

## API 요구 사항 {#api-requirements}

스토리지 관리를 자동화하려면 GitLab.com 또는 GitLab Self-Managed 인스턴스가 [GitLab REST API](../api/api_resources.md)에 액세스할 수 있어야 합니다.

### API 인증 범위 {#api-authentication-scope}

다음 범위를 사용하여 API로 [인증](../api/rest/authentication.md)합니다:

- 스토리지 분석:
  - `read_api` 범위를 사용한 읽기 API 액세스입니다.
  - 모든 프로젝트에 대한 개발자, 유지보수자 또는 소유자 역할입니다.
- 스토리지 정리:
  - `api` 범위를 사용한 전체 API 액세스입니다.
  - 모든 프로젝트에 대한 유지보수자 또는 소유자 역할입니다.

명령줄 도구나 프로그래밍 언어를 사용하여 REST API와 상호작용할 수 있습니다.

### 명령줄 도구 {#command-line-tools}

API 요청을 보내려면 다음 중 하나를 설치합니다:

- 원하는 패키지 관리자와 함께 curl을 사용합니다.
- [GitLab CLI](https://docs.gitlab.com/cli/) 및 `glab api` 하위 명령을 사용합니다.

JSON 응답의 형식을 지정하려면 `jq`을 설치합니다. 자세한 내용은 [생산성 높은 DevOps 워크플로우: jq 및 CI/CD 린팅 자동화를 통한 JSON 형식](https://about.gitlab.com/blog/devops-workflows-json-format-jq-ci-cd-lint/)을 참조하십시오.

REST API와 함께 이 도구를 사용하려면:

{{< tabs >}}

{{< tab title="curl" >}}

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

#### GitLab CLI 사용 {#using-the-gitlab-cli}

일부 API 엔드포인트는 [페이지네이션](../api/rest/_index.md#pagination) 및 후속 페이지 가져오기가 필요하여 모든 결과를 검색합니다. GitLab CLI는 `--paginate` 플래그를 제공합니다.

JSON 데이터로 형식이 지정된 POST 본문이 필요한 요청은 `key=value` 쌍으로 작성하고 `--raw-field` 매개변수로 전달할 수 있습니다.

자세한 내용은 [GitLab CLI 엔드포인트 설명서](https://docs.gitlab.com/cli/#commands)를 참조하십시오.

### API 클라이언트 라이브러리 {#api-client-libraries}

이 페이지에서 설명하는 스토리지 관리 및 정리 자동화 방법은 다음을 사용합니다:

- [`python-gitlab` 라이브러리는 기능이 풍부한 프로그래밍 인터페이스를 제공합니다.](https://python-gitlab.readthedocs.io/en/stable/)
- [GitLab API with Python](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-python/) 프로젝트의 `get_all_projects_top_level_namespace_storage_analysis_cleanup_example.py` 스크립트입니다.

`python-gitlab` 라이브러리의 사용 사례에 대한 자세한 내용은 [효율적인 DevSecOps 워크플로우: `python-gitlab` API 자동화](https://about.gitlab.com/blog/efficient-devsecops-workflows-hands-on-python-gitlab-api-automation/)를 참조하십시오.

다른 API 클라이언트 라이브러리에 대한 자세한 내용은 [타사 클라이언트](../api/rest/third_party_clients.md)를 참조하십시오.

> [!note]
> GitLab Duo 코드 제안을 사용하여 더 효율적으로 코드를 작성합니다.

## 스토리지 분석 {#storage-analysis}

### 스토리지 유형 식별 {#identify-storage-types}

[프로젝트 API 엔드포인트](../api/projects.md#list-all-projects)는 GitLab 인스턴스의 프로젝트에 대한 통계를 제공합니다. 프로젝트 API 엔드포인트를 사용하려면 `statistics` 키를 부울 `true`로 설정합니다. 이 데이터는 다음 스토리지 유형별 프로젝트의 스토리지 사용량에 대한 통찰력을 제공합니다:

- `storage_size`: 전체 스토리지
- `lfs_objects_size`: LFS 개체 스토리지
- `job_artifacts_size`: 작업 아티팩트 스토리지
- `packages_size`: 패키지 스토리지
- `repository_size`: Git 리포지토리 스토리지
- `snippets_size`: 스니펫 스토리지
- `uploads_size`: 업로드 스토리지
- `wiki_size`: 위키 스토리지

스토리지 유형을 식별하려면:

{{< tabs >}}

{{< tab title="curl" >}}

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

프로젝트 통계를 터미널에 인쇄하려면 `GL_GROUP_ID` 환경 변수를 내보내고 스크립트를 실행합니다:

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

### 프로젝트 및 그룹의 스토리지 분석 {#analyze-storage-in-projects-and-groups}

여러 프로젝트와 그룹의 분석을 자동화할 수 있습니다. 예를 들어 최상위 네임스페이스 수준에서 시작하여 모든 하위 그룹과 프로젝트를 재귀적으로 분석할 수 있습니다. 다양한 스토리지 유형도 분석할 수 있습니다.

다음은 여러 하위 그룹과 프로젝트를 분석하는 알고리즘의 예입니다:

1. 최상위 네임스페이스 ID를 가져옵니다. [네임스페이스/그룹 개요](namespace/_index.md#types-of-namespaces)에서 ID 값을 복사할 수 있습니다.
1. 최상위 그룹에서 모든 [하위 그룹](../api/groups.md#list-subgroups)을 가져오고 ID를 목록에 저장합니다.
1. 모든 그룹을 반복하고 각 그룹에서 [모든 프로젝트를 가져오고](../api/groups.md#list-projects) ID를 목록에 저장합니다.
1. 분석할 스토리지 유형을 식별하고 프로젝트 통계 및 작업 아티팩트와 같은 프로젝트 특성에서 정보를 수집합니다.
1. 모든 프로젝트를 그룹별로 그룹화한 개요 및 해당 스토리지 정보를 인쇄합니다.

`glab`를 사용한 쉘 접근 방식이 더 작은 분석에 더 적합할 수 있습니다. 더 큰 분석을 위해서는 API 클라이언트 라이브러리를 사용하는 스크립트를 사용해야 합니다. 이 유형의 스크립트는 가독성, 데이터 스토리지, 흐름 제어, 테스트 및 재사용성을 개선할 수 있습니다.

스크립트가 [API 속도 제한](../rate_limits/_index.md)에 도달하지 않도록 다음 예제 코드는 병렬 API 요청에 최적화되지 않습니다.

이 알고리즘을 구현하려면:

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

스크립트는 JSON 형식의 목록으로 프로젝트 작업 아티팩트를 출력합니다:

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

## CI/CD 파이프라인 스토리지 관리 {#manage-cicd-pipeline-storage}

작업 아티팩트는 대부분의 파이프라인 스토리지를 사용하며, 작업 로그도 수백 킬로바이트를 생성할 수 있습니다. 불필요한 작업 아티팩트를 먼저 삭제한 다음 분석 후 작업 로그를 정리해야 합니다.

> [!warning]
> 작업 로그와 아티팩트를 삭제하는 것은 되돌릴 수 없는 파괴적인 작업입니다. 주의하여 사용하십시오. 보고서 아티팩트, 작업 로그 및 메타데이터 파일을 포함한 특정 파일을 삭제하면 이 파일을 데이터 소스로 사용하는 GitLab 기능이 영향을 받습니다.

### 작업 아티팩트 나열 {#list-job-artifacts}

파이프라인 스토리지를 분석하려면 [작업 API 엔드포인트](../api/jobs.md#list-all-jobs-for-a-project)를 사용하여 작업 아티팩트 목록을 검색합니다. 엔드포인트는 작업 아티팩트 `file_type` 키를 `artifacts` 특성으로 반환합니다. `file_type` 키는 아티팩트 유형을 나타냅니다:

- `archive`은 zip 파일로 생성된 작업 아티팩트에 사용됩니다.
- `metadata`은 Gzip 파일의 추가 메타데이터에 사용됩니다.
- `trace`은 원본 파일로 `job.log`에 사용됩니다.

작업 아티팩트는 디스크에 캐시 파일로 작성할 수 있는 데이터 구조를 제공하며, 이를 사용하여 구현을 테스트할 수 있습니다.

모든 프로젝트를 가져오는 예제 코드를 기반으로 Python 스크립트를 확장하여 더 많은 분석을 수행할 수 있습니다.

다음 예제는 프로젝트의 작업 아티팩트 쿼리의 응답을 보여줍니다:

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

스크립트를 구현하는 방법에 따라 다음 중 하나를 수행할 수 있습니다:

- 모든 작업 아티팩트를 수집하고 스크립트의 끝에 요약 테이블을 인쇄합니다.
- 정보를 즉시 인쇄합니다.

다음 예제에서 작업 아티팩트는 `ci_job_artifacts` 목록에 수집됩니다. 스크립트는 모든 프로젝트를 반복하고 다음을 가져옵니다:

- 모든 특성을 포함하는 `project_obj` 개체 변수입니다.
- `job` 개체의 `artifacts` 특성입니다.

[키셋 페이지네이션](https://python-gitlab.readthedocs.io/en/stable/api-usage.html#pagination)을 사용하여 파이프라인 및 작업의 큰 목록을 반복할 수 있습니다.

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

스크립트의 끝에서 작업 아티팩트는 Markdown 형식의 테이블로 인쇄됩니다. 테이블 콘텐츠를 이슈 주석 또는 설명에 복사하거나 GitLab 리포지토리의 Markdown 파일을 채울 수 있습니다.

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

### 작업 아티팩트 일괄 삭제 {#delete-job-artifacts-in-bulk}

Python 스크립트를 사용하여 작업 아티팩트 유형을 필터링하고 일괄 삭제할 수 있습니다.

API 쿼리 결과를 필터링하여 비교합니다:

- 아티팩트 나이를 계산하는 `created_at` 값입니다.
- 아티팩트가 크기 임계값을 충족하는지 확인하는 `size` 특성입니다.

일반적인 요청:

- 지정된 일 수보다 오래된 작업 아티팩트를 삭제합니다.
- 지정된 스토리지 양을 초과하는 작업 아티팩트를 삭제합니다. 예: 100MB.

다음 예제에서 스크립트는 작업 특성을 반복하고 삭제를 위해 표시합니다. 컬렉션 루프가 개체 잠금을 제거하면 스크립트는 삭제를 위해 표시된 작업 아티팩트를 삭제합니다.

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

### 프로젝트의 모든 작업 아티팩트 삭제 {#delete-all-job-artifacts-for-a-project}

프로젝트의 [작업 아티팩트](../ci/jobs/job_artifacts.md)가 필요 없으면 다음 명령을 사용하여 모든 작업 아티팩트를 삭제할 수 있습니다. 이 작업은 되돌릴 수 없습니다.

아티팩트 삭제는 삭제할 아티팩트의 수에 따라 몇 분에서 몇 시간이 걸릴 수 있습니다. 후속 API 쿼리는 아티팩트를 거짓 양성 결과로 반환할 수 있습니다. 결과 혼동을 피하려면 추가 API 요청을 즉시 실행하지 마십시오.

[가장 최근의 성공한 작업의 아티팩트](../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)는 기본적으로 보관됩니다.

프로젝트의 모든 작업 아티팩트를 삭제하려면:

{{< tabs >}}

{{< tab title="curl" >}}

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

### 작업 로그 삭제 {#delete-job-logs}

작업 로그를 삭제하면 [전체 작업도 삭제됩니다](../api/jobs.md#erase-a-job).

GitLab CLI의 예:

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

`python-gitlab` API 라이브러리에서 [`job.erase()`](https://python-gitlab.readthedocs.io/en/stable/gl_objects/pipelines_and_jobs.html#jobs)를 사용하지 않고 `job.delete_artifacts()`를 사용합니다. 이 API 호출이 차단되지 않도록 하려면 작업 아티팩트를 삭제하는 호출 사이에 짧은 시간 동안 대기하도록 스크립트를 설정합니다:

```python
    for job in jobs_marked_delete_artifacts:
        # delete the artifacts and job log
        print("DEBUG", job)
        #job.delete_artifacts()
        job.erase()
        # Sleep for 1 second
        time.sleep(1)
```

작업 로그의 보관 정책 생성 지원은 [이슈 374717](https://gitlab.com/gitlab-org/gitlab/-/issues/374717)에서 제안됩니다.

### 오래된 파이프라인 삭제 {#delete-old-pipelines}

파이프라인은 전체 스토리지 사용량에 추가되지 않지만 필요한 경우 [삭제를 자동화](../ci/pipelines/settings.md#automatic-pipeline-cleanup)할 수 있습니다.

특정 날짜를 기반으로 파이프라인을 삭제하려면 `created_at` 키를 지정합니다. 날짜를 사용하여 현재 날짜와 파이프라인이 생성된 시점 사이의 차이를 계산할 수 있습니다. 나이가 임계값보다 크면 파이프라인이 삭제됩니다.

> [!note]
> `created_at` 키를 타임스탬프에서 Unix epoch 시간으로 변환해야 하며, 예를 들어 `date -d '2023-08-08T18:59:47.581Z' +%s`을 사용합니다.

GitLab CLI의 예:

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

Bash 스크립트를 사용하는 다음 예제에서:

- `jq` 및 GitLab CLI가 설치되고 인증됩니다.
- 내보낸 환경 변수 `GL_PROJECT_ID`입니다. GitLab 사전 정의된 변수 `CI_PROJECT_ID`로 기본 설정됩니다.
- GitLab 인스턴스 URL을 가리키는 내보낸 환경 변수 `CI_SERVER_HOST`입니다.

{{< tabs >}}

{{< tab title="glab을 사용한 API 사용" >}}

전체 스크립트 `get_cicd_pipelines_compare_age_threshold_example.sh`는 [GitLab API with Linux Shell](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-linux-shell) 프로젝트에 있습니다.

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

{{< tab title="glab CLI 사용" >}}

전체 스크립트 `cleanup-old-pipelines.sh`는 [GitLab API with Linux Shell](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-linux-shell) 프로젝트에 있습니다.

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

{{< tab title="Python을 사용한 API 사용" >}}

[`python-gitlab` API 라이브러리](https://python-gitlab.readthedocs.io/en/stable/gl_objects/pipelines_and_jobs.html#project-pipelines) 및 `created_at` 특성을 사용하여 작업 아티팩트 나이를 비교하는 유사한 알고리즘을 구현할 수도 있습니다:

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

### 작업 아티팩트의 만료 설정 나열 {#list-expiry-settings-for-job-artifacts}

아티팩트 스토리지를 관리하기 위해 아티팩트가 만료되는 시점을 업데이트하거나 구성할 수 있습니다. 아티팩트의 만료 설정은 `.gitlab-ci.yml`의 각 작업 구성에서 구성됩니다.

여러 프로젝트가 있고 CI/CD 구성에서 작업 정의가 어떻게 구성되어 있는지에 따라 만료 설정을 찾기 어려울 수 있습니다. 스크립트를 사용하여 전체 CI/CD 구성을 검색할 수 있습니다. 여기에는 `extends` 또는 `!reference`과 같이 값을 상속한 후 확인되는 개체에 대한 액세스가 포함됩니다.

스크립트는 병합된 CI/CD 구성 파일을 검색하고 아티팩트 키를 검색합니다:

- 만료 설정이 없는 작업을 식별합니다.
- 아티팩트 만료가 구성된 작업의 만료 설정을 반환합니다.

다음 프로세스는 스크립트가 아티팩트 만료 설정을 검색하는 방법을 설명합니다:

1. 병합된 CI/CD 구성을 생성하기 위해 스크립트는 모든 프로젝트를 반복하고 [`ci_lint()` 메서드](https://python-gitlab.readthedocs.io/en/stable/gl_objects/ci_lint.html)를 호출합니다.
1. `yaml_load` 함수는 병합된 구성을 Python 데이터 구조로 로드하여 더 분석할 수 있도록 합니다.
1. `script` 키도 포함하는 사전은 자신을 작업 정의로 식별하며, 여기서 `artifacts` 키가 존재할 수 있습니다.
1. 그렇다면 스크립트는 하위 키 `expire_in`을 파싱하고 나중에 Markdown 테이블 요약에서 인쇄할 세부정보를 저장합니다.

```python
    ci_job_artifacts_expiry = {}

    # Loop over projects, fetch .gitlab-ci.yml, run the linter to get the full translated config, and extract the `artifacts:` setting
    # https://python-gitlab.readthedocs.io/en/stable/gl_objects/ci_lint.html
    for project in projects:
            project_obj = gl.projects.get(project.id)
            project_name = project_obj.name
            project_web_url = project_obj.web_url
            try:
                lint_result = project_obj.ci_lint.get()
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

스크립트는 다음을 포함하는 Markdown 요약 테이블을 생성합니다:

- 프로젝트 이름 및 URL입니다.
- 작업 이름입니다.
- `artifacts:expire_in` 설정 또는 설정이 없으면 `N/A`입니다.

스크립트는 다음과 같은 작업 템플릿을 인쇄하지 않습니다:

- `.` 문자로 시작합니다.
- 아티팩트를 생성하는 런타임 작업 개체로 인스턴스화되지 않습니다.

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

`get_all_cicd_config_artifacts_expiry.py` 스크립트는 [GitLab API with Python 프로젝트](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-python/)에 있습니다.

대신 API 요청으로 [고급 검색](search/advanced_search.md)을 사용할 수 있습니다. 다음 예제는 모든 `*.yml` 파일에서 문자열 `artifacts`을 검색하는 [범위: blobs](../api/search.md#scope-blobs)를 사용합니다:

```shell
# https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs
export GL_PROJECT_ID=48349263

glab api --method GET projects/$GL_PROJECT_ID/search --field "scope=blobs" --field "search=expire_in filename:*.yml"
```

인벤토리 접근 방식에 대한 자세한 내용은 [GitLab이 Docker Hub의 오픈 소스 컨테이너 이미지 삭제를 완화하는 방법](https://about.gitlab.com/blog/how-gitlab-can-help-mitigate-deletion-open-source-images-docker-hub/)을 참조하십시오.

### 작업 아티팩트의 기본 만료 설정 {#set-default-expiry-for-job-artifacts}

프로젝트에서 작업 아티팩트의 기본 만료를 설정하려면 `.gitlab-ci.yml` 파일에서 `expire_in` 값을 지정합니다:

```yaml
default:
    artifacts:
        expire_in: 1 week
```

## 컨테이너 레지스트리 스토리지 관리 {#manage-container-registries-storage}

컨테이너 레지스트리는 [프로젝트용](../api/container_registry.md#within-a-project) 또는 [그룹용](../api/container_registry.md#within-a-group)으로 제공됩니다. 두 위치를 모두 분석하여 정리 전략을 구현할 수 있습니다.

### 컨테이너 레지스트리 나열 {#list-container-registries}

프로젝트에서 컨테이너 레지스트리를 나열하려면:

{{< tabs >}}

{{< tab title="curl" >}}

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

### 컨테이너 이미지 일괄 삭제 {#delete-container-images-in-bulk}

[컨테이너 이미지 태그를 일괄 삭제](../api/container_registry.md#delete-registry-repository-tags-in-bulk)할 때 다음을 구성할 수 있습니다:

- 유지할 태그 이름 및 이미지와 삭제할 태그 이름 및 이미지(`name_regex_delete`)에 대한 정규식 (`name_regex_keep`) 일치
- 태그 이름을 일치시키는 유지할 이미지 태그 수 (`keep_n`)
- 이미지 태그를 삭제할 수 있는 일 수 (`older_than`)

> [!warning]
> GitLab.com에서 컨테이너 레지스트리의 규모로 인해 이 API로 삭제된 태그 수는 제한됩니다. 컨테이너 레지스트리에 삭제할 태그 수가 많은 경우 일부만 삭제됩니다. API를 여러 번 호출해야 할 수도 있습니다. 태그를 자동으로 삭제하려면 대신 [정리 정책](#create-a-cleanup-policy-for-containers)을 사용하십시오.

다음 예제는 [`python-gitlab` API 라이브러리](https://python-gitlab.readthedocs.io/en/stable/gl_objects/repository_tags.html)를 사용하여 태그 목록을 가져오고 `delete_in_bulk()` 메서드를 필터 매개변수로 호출합니다.

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

### 컨테이너의 정리 정책 만들기 {#create-a-cleanup-policy-for-containers}

프로젝트 REST API 엔드포인트를 사용하여 컨테이너의 [정리 정책을 만듭니다](packages/container_registry/reduce_container_registry_storage.md#use-the-cleanup-policy-api). 정리 정책을 설정한 후 사양과 일치하는 모든 컨테이너 이미지가 자동으로 삭제됩니다. 추가 API 자동화 스크립트가 필요하지 않습니다.

특성을 본문 매개변수로 보내려면:

- `--input -` 매개변수를 사용하여 표준 입력에서 읽습니다.
- `Content-Type` 헤더를 설정합니다.

다음 예제는 GitLab CLI를 사용하여 정리 정책을 만듭니다:

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

### 컨테이너 이미지 최적화 {#optimize-container-images}

컨테이너 이미지를 최적화하여 이미지 크기와 컨테이너 레지스트리의 전체 스토리지 사용량을 줄일 수 있습니다. [파이프라인 효율성 설명서](../ci/pipelines/pipeline_efficiency.md#optimize-docker-images)에서 자세히 알아보세요.

## 패키지 레지스트리 스토리지 관리 {#manage-package-registry-storage}

패키지 레지스트리는 [프로젝트용](../api/packages.md#for-a-project) 또는 [그룹용](../api/packages.md#for-a-group)으로 제공됩니다.

### 패키지 및 파일 나열 {#list-packages-and-files}

다음 예제는 GitLab CLI를 사용하여 정의된 프로젝트 ID에서 패키지를 가져오는 방법을 보여줍니다. 결과 세트는 `jq` 명령 체인으로 필터링할 수 있는 사전 항목의 배열입니다.

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

패키지 ID를 사용하여 패키지의 파일 및 해당 크기를 검사합니다.

```shell
glab api --method GET projects/$GL_PROJECT_ID/packages/16669383/package_files | jq --compact-output '.[]' |
 jq --compact-output '.package_id,.file_name,.size'

16669383
"nighly.tar.gz"
10487563
```

유사한 자동화 쉘 스크립트는 [오래된 파이프라인 삭제](#delete-old-pipelines) 섹션에서 생성됩니다.

다음 스크립트 예제는 `python-gitlab` 라이브러리를 사용하여 루프에서 모든 패키지를 가져오고 해당 패키지 파일을 반복하여 `file_name` 및 `size` 특성을 인쇄합니다.

```python
        packages = project.packages.list(order_by="created_at")

        for package in packages:

            package_files = package.package_files.list()
            for package_file in package_files:
                print("Package name: {p} File name: {f} Size {s}".format(
                    p=package.name, f=package_file.file_name, s=render_size_mb(package_file.size)))
```

### 패키지 삭제 {#delete-packages}

[패키지의 파일 삭제](../api/packages.md#delete-a-package-file)는 패키지를 손상시킬 수 있습니다. 자동화된 정리 유지보수를 수행할 때 패키지를 삭제해야 합니다.

패키지를 삭제하려면 GitLab CLI를 사용하여 `--method` 매개변수를 `DELETE`로 변경합니다:

```shell
glab api --method DELETE projects/$GL_PROJECT_ID/packages/16669383
```

패키지 크기를 계산하고 크기 임계값과 비교하려면 `python-gitlab` 라이브러리를 사용하여 [패키지 및 파일 나열](#list-packages-and-files) 섹션에서 설명하는 코드를 확장할 수 있습니다.

다음 코드 예제는 패키지 나이도 계산하고 조건이 일치할 때 패키지를 삭제합니다:

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

코드는 추가 분석에 사용할 수 있는 다음 출력을 생성합니다:

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

### 종속성 프록시 {#dependency-proxy}

[정리 정책](packages/dependency_proxy/reduce_dependency_proxy_storage.md#cleanup-policies)을 검토하고 [API를 사용하여 캐시를 제거](packages/dependency_proxy/reduce_dependency_proxy_storage.md#use-the-api-to-clear-the-cache)하는 방법을 참조하십시오.

## 출력 가독성 개선 {#improve-output-readability}

타임스탬프 초를 기간 형식으로 변환하거나 원본 바이트를 더 대표적인 형식으로 인쇄해야 할 수도 있습니다. 다음 도우미 함수를 사용하여 값을 변환하여 가독성을 개선할 수 있습니다:

```shell
# Current Unix timestamp
date +%s

# Convert `created_at` date time with timezone to Unix timestamp
date -d '2023-08-08T18:59:47.581Z' +%s
```

`python-gitlab` API 라이브러리를 사용하는 Python의 예:

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

## 스토리지 관리 자동화 테스트 {#testing-for-storage-management-automation}

스토리지 관리 자동화를 테스트하려면 테스트 데이터를 생성하거나 스토리지를 채워 분석 및 삭제가 예상대로 작동하는지 확인해야 할 수 있습니다. 다음 섹션은 짧은 시간 내에 스토리지 Blob을 테스트하고 생성하는 것에 대한 도구 및 팁을 제공합니다.

### 작업 아티팩트 생성 {#generate-job-artifacts}

CI/CD 작업 행렬 빌드를 사용하여 가짜 아티팩트 Blob을 생성하는 테스트 프로젝트를 만듭니다. CI/CD 파이프라인을 추가하여 일일 아티팩트를 생성합니다.

1. 새 프로젝트를 만듭니다.
1. 다음 스니펫을 `.gitlab-ci.yml`에 추가하여 작업 아티팩트 생성기 구성을 포함합니다.

   ```yaml
   include:
       - remote: https://gitlab.com/gitlab-da/use-cases/efficiency/job-artifact-generator/-/raw/main/.gitlab-ci.yml
   ```

1. [파이프라인 일정을 구성합니다](../ci/pipelines/schedules.md#create-a-pipeline-schedule).
1. [파이프라인을 수동으로 트리거합니다](../ci/pipelines/schedules.md#run-manually).

또는 86MB 일일 생성 MB를 `MB_COUNT` 변수의 다른 값으로 줄입니다.

```yaml
include:
    - remote: https://gitlab.com/gitlab-da/use-cases/efficiency/job-artifact-generator/-/raw/main/.gitlab-ci.yml

generator:
    parallel:
        matrix:
            - MB_COUNT: [1, 5, 10, 20, 50]

```

자세한 내용은 [작업 아티팩트 생성기 README](https://gitlab.com/gitlab-da/use-cases/efficiency/job-artifact-generator)와 [예제 그룹](https://gitlab.com/gitlab-da/playground/artifact-gen-group)을 참조하십시오.

### 만료를 사용하여 작업 아티팩트 생성 {#generate-job-artifacts-with-expiry}

프로젝트 CI/CD 구성은 다음에서 작업 정의를 지정합니다:

- 주 `.gitlab-ci.yml` 구성 파일입니다.
- `artifacts:expire_in` 설정입니다.
- 프로젝트 파일 및 템플릿입니다.

분석 스크립트를 테스트하려면 [`gen-job-artifacts-expiry-included-jobs` 프로젝트](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs)에서 예제 구성을 제공합니다.

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

### 컨테이너 이미지 생성 {#generate-container-images}

예제 그룹 [`container-package-gen-group`](https://gitlab.com/gitlab-da/playground/container-package-gen-group)은 다음을 제공하는 프로젝트를 제공합니다:

- Dockerfile의 기본 이미지를 사용하여 새 이미지를 빌드합니다.
- GitLab.com에서 이미지를 빌드하려면 `Docker.gitlab-ci.yml` 템플릿을 포함합니다.
- 새 이미지를 매일 생성하도록 파이프라인 일정을 구성합니다.

포크할 수 있는 예제 프로젝트:

- [`docker-alpine-generator`](https://gitlab.com/gitlab-da/playground/container-package-gen-group/docker-alpine-generator)
- [`docker-python-generator`](https://gitlab.com/gitlab-da/playground/container-package-gen-group/docker-python-generator)

### 제네릭 패키지 생성 {#generate-generic-packages}

예제 프로젝트 [`generic-package-generator`](https://gitlab.com/gitlab-da/playground/container-package-gen-group/generic-package-generator)는 다음을 제공하는 프로젝트를 제공합니다:

- 임의의 텍스트 Blob을 생성하고 현재 Unix 타임스탬프를 릴리스 버전으로 사용하여 tarball을 생성합니다.
- Tarball을 제네릭 패키지 레지스트리에 업로드하고 Unix 타임스탬프를 릴리스 버전으로 사용합니다.

제네릭 패키지를 생성하려면 이 독립 실행형 `.gitlab-ci.yml` 구성을 사용할 수 있습니다:

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

### 포크를 사용한 스토리지 사용량 생성 {#generate-storage-usage-with-forks}

다음 프로젝트를 사용하여 [포크의 비용 계수](storage_usage_quotas.md#view-project-fork-storage-usage)로 스토리지 사용을 테스트합니다:

- [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab)을 새 네임스페이스 또는 그룹(LFS, Git 리포지토리 포함)으로 포크합니다.
- [`gitlab-com/www-gitlab-com`](https://gitlab.com/gitlab-com/www-gitlab-com)을 새 네임스페이스 또는 그룹으로 포크합니다.

## 커뮤니티 리소스 {#community-resources}

다음 리소스는 공식적으로 지원되지 않습니다. 되돌릴 수 없는 파괴적인 정리 명령을 실행하기 전에 스크립트 및 자습서를 테스트해야 합니다.

- 포럼 주제: [스토리지 관리 자동화 리소스](https://forum.gitlab.com/t/storage-management-automation-resources/91184)
- 스크립트: [GitLab Storage Analyzer](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-storage-analyzer)는 [GitLab Developer Evangelism 팀](https://gitlab.com/gitlab-da/)의 비공식 프로젝트입니다. 이 설명서 방법에서 유사한 코드 예제를 찾을 수 있습니다.
