---
stage: Fulfillment
group: Utilization
info: This page is maintained by Developer Relations, author @dnsmichi, see https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation
title: Automate storage management
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This page describes how to automate storage analysis and cleanup to manage your storage usage
with the GitLab REST API.

You can also manage your storage usage by improving [pipeline efficiency](../ci/pipelines/pipeline_efficiency.md).

For more help with API automation, you can also use the [GitLab community forum and Discord](https://about.gitlab.com/community/).

WARNING:
The script examples in this page are for demonstration purposes only and should not
be used in production. You can use the examples to design and test your own scripts for storage automation.

## API requirements

To automate storage management, your GitLab.com SaaS or self-managed instance must have access to the [GitLab REST API](../api/api_resources.md).

### API authentication scope

Use the following scopes to [authenticate](../api/rest/authentication.md) with the API:

- Storage analysis:
  - Read API access with the `read_api` scope.
  - At least the Developer role on all projects.
- Storage clean up:
  - Full API access with the `api` scope.
  - At least the Maintainer role on all projects.

You can use command-line tools or a programming language to interact with the REST API.

### Command line tools

To send API requests, install either:

- curl with your preferred package manager.
- [GitLab CLI](../editor_extensions/gitlab_cli/_index.md) and use the `glab api` subcommand.

To format JSON responses, install `jq`. For more information, see [Tips for productive DevOps workflows: JSON formatting with jq and CI/CD linting automation](https://about.gitlab.com/blog/2021/04/21/devops-workflows-json-format-jq-ci-cd-lint/).

To use these tools with the REST API:

::Tabs

:::TabTitle curl

```shell
export GITLAB_TOKEN=xxx

curl --silent --header "Authorization: Bearer $GITLAB_TOKEN" "https://gitlab.com/api/v4/user" | jq
```

:::TabTitle GitLab CLI

```shell
glab auth login

glab api groups/YOURGROUPNAME/projects
```

::EndTabs

#### Using the GitLab CLI

Some API endpoints require [pagination](../api/rest/_index.md#pagination) and subsequent page fetches to retrieve all results. The GitLab CLI provides the flag `--paginate`.

Requests that require a POST body formatted as JSON data can be written as `key=value` pairs passed to the `--raw-field` parameter.

For more information, see the [GitLab CLI endpoint documentation](../editor_extensions/gitlab_cli/_index.md#core-commands).

### API client libraries

The storage management and cleanup automation methods described in this page use:

- The [`python-gitlab`](https://python-gitlab.readthedocs.io/en/stable/) library, which provides
  a feature-rich programming interface.
- The `get_all_projects_top_level_namespace_storage_analysis_cleanup_example.py` script in the [GitLab API with Python](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-python/) project.

For more information about use cases for the `python-gitlab` library,
see [Efficient DevSecOps workflows: Hands-on `python-gitlab` API automation](https://about.gitlab.com/blog/2023/02/01/efficient-devsecops-workflows-hands-on-python-gitlab-api-automation/).

For more information about other API client libraries, see [Third-party clients](../api/rest/third_party_clients.md).

NOTE:
Use [GitLab Duo Code Suggestions](project/repository/code_suggestions/_index.md) to write code more efficiently.

## Storage analysis

### Identify storage types

The [projects API endpoint](../api/projects.md#list-all-projects) provides statistics for projects
in your GitLab instance. To use the projects API endpoint, set the `statistics` key to boolean `true`.
This data provides insight into storage consumption of the project by the following storage types:

- `storage_size`: Overall storage
- `lfs_objects_size`: LFS objects storage
- `job_artifacts_size`: Job artifacts storage
- `packages_size`: Packages storage
- `repository_size`: Git repository storage
- `snippets_size`: Snippets storage
- `uploads_size`: Uploads storage
- `wiki_size`: Wiki storage

To identify storage types:

::Tabs

:::TabTitle curl

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

:::TabTitle GitLab CLI

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

:::TabTitle Python

```python
project_obj = gl.projects.get(project.id, statistics=True)

print("Project {n} statistics: {s}".format(n=project_obj.name_with_namespace, s=json.dump(project_obj.statistics, indent=4)))
```

::EndTabs

To print statistics for the project to the terminal, export the `GL_GROUP_ID` environment variable and run the script:

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

### Analyze storage in projects and groups

You can automate analysis of multiple projects and groups. For example, you can start at the top namespace level,
and recursively analyze all subgroups and projects. You can also analyze different storage types.

Here's an example of an algorithm to analyze multiple subgroups and projects:

1. Fetch the top-level namespace ID. You can copy the ID value from the [namespace/group overview](namespace/_index.md#types-of-namespaces).
1. Fetch all [subgroups](../api/groups.md#list-subgroups) from the top-level group, and save the IDs in a list.
1. Loop over all groups and fetch all [projects from each group](../api/groups.md#list-projects) and save the IDs in a list.
1. Identify the storage type to analyze, and collect the information from project attributes, like project statistics, and job artifacts.
1. Print an overview of all projects, grouped by group, and their storage information.

The shell approach with `glab` might be more suitable for smaller analyses. For larger analyses, you should use a script that
uses the API client libraries. This type of script can improve readability, data storage, flow control, testing, and reusability.

To ensure the script doesn't reach [API rate limits](../security/rate_limits.md), the following
example code is not optimized for parallel API requests.

To implement this algorithm:

::Tabs

:::TabTitle GitLab CLI

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

:::TabTitle Python

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

::EndTabs

The script outputs the project job artifacts in a JSON formatted list:

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

## Manage CI/CD pipeline storage

Job artifacts consume most of the pipeline storage, and job logs can also generate several hundreds of kilobytes.
You should delete the unnecessary job artifacts first and then clean up job logs after analysis.

WARNING:
Deleting job log and artifacts is a destructive action that cannot be reverted. Use with caution. Deleting certain files, including report artifacts, job logs, and metadata files, affects GitLab features that use these files as data sources.

### List job artifacts

To analyze pipeline storage, you can use the [Job API endpoint](../api/jobs.md#list-project-jobs) to retrieve a list of
job artifacts. The endpoint returns the job artifacts `file_type` key in the `artifacts` attribute.
The `file_type` key indicates the artifact type:

- `archive` is used for the generated job artifacts as a zip file.
- `metadata` is used for additional metadata in a Gzip file.
- `trace` is used for the `job.log` as a raw file.

Job artifacts provide a data structure that can be written as a cache file to
disk, which you can use to test the implementation.

Based on the example code for fetching all projects, you can extend the Python script to do more analysis.

The following example shows a response from a query for job artifacts in a project:

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

Based on how you implement the script, you could either:

- Collect all job artifacts and print a summary table at the end of the script.
- Print the information immediately.

In the following example, job artifacts are collected in the `ci_job_artifacts` list. The script
loops over all projects, and fetches:

- The `project_obj` object variable that contains all attributes.
- The `artifacts` attribute from the `job` object.

You can use [keyset pagination](https://python-gitlab.readthedocs.io/en/stable/api-usage.html#pagination)
to iterate over large lists of pipelines and jobs.

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
        print("|Project|Job|Artifact name|Artifact type|Artifact size|\n|-|-|-|-|-|") #Start markdown friendly table
        for artifact in ci_job_artifacts:
            print('| [{project_name}]({project_web_url}) | {job_name} | {artifact_name} | {artifact_type} | {artifact_size} |'.format(project_name=artifact['project_path_with_namespace'], project_web_url=artifact['project_web_url'], job_name=artifact['job_id'], artifact_name=artifact['artifact_filename'], artifact_type=artifact['artifact_file_type'], artifact_size=render_size_mb(artifact['artifact_size'])))
    else:
        print("No artifacts found.")
```

At the end of the script, job artifacts are printed as a Markdown formatted table. You can copy the table
content to an issue comment or description, or populate a Markdown file in a GitLab repository.

```shell
$ python3 get_all_projects_top_level_namespace_storage_analysis_cleanup_example.py

|Project|Job|Artifact name|Artifact type|Artifact size|
|-|-|-|-|-|
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297946 | artifacts.zip | archive | 50.0154 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297946 | metadata.gz | metadata | 0.0001 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297946 | job.log | trace | 0.0030 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297945 | artifacts.zip | archive | 20.0063 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297945 | metadata.gz | metadata | 0.0001 |
| [gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4](Gen Job Artifacts 4) | 4828297945 | job.log | trace | 0.0030 |
```

### Delete job artifacts in bulk

You can use a Python script to filter the types of job artifacts to delete in bulk.

Filter the API queries results to compare:

- The `created_at` value to calculate the artifact age.
- The `size` attribute to determine if artifacts meet the size threshold.

A typical request:

- Deletes job artifacts older than the specified number of days.
- Deletes job artifacts that exceed a specified amount of storage. For example, 100 MB.

In the following example, the script loops through job attributes and marks them for deletion.
When the collection loops remove the object locks, the script deletes the job artifacts marked for deletion.

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
                # ... removed analysis collection code for readability

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

### Delete all job artifacts for a project

If you do not need the project's [job artifacts](../ci/jobs/job_artifacts.md), you can
use the following command to delete all job artifacts. This action cannot be reverted.

Artifact deletion can take several minutes or hours, depending on the number of artifacts to delete. Subsequent
analysis queries against the API might return the artifacts as a false-positive result.
To avoid confusion with results, do not immediately run additional API requests.

The [artifacts for the most recent successful jobs](../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs) are kept by default.

To delete all job artifacts for a project:

::Tabs

:::TabTitle curl

```shell
export GL_PROJECT_ID=48349590

curl --silent --header "Authorization: Bearer $GITLAB_TOKEN" --request DELETE "https://gitlab.com/api/v4/projects/$GL_PROJECT_ID/artifacts"
```

:::TabTitle GitLab CLI

```shell
glab api --method GET projects/$GL_PROJECT_ID/jobs | jq --compact-output '.[]' | jq --compact-output '.id, .artifacts'

glab api --method DELETE projects/$GL_PROJECT_ID/artifacts
```

:::TabTitle Python

```python
        project.artifacts.delete()
```

::EndTabs

### Delete job logs

When you delete a job log you also [erase the entire job](../api/jobs.md#erase-a-job).

Example with the GitLab CLI:

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

In the `python-gitlab` API library, use [`job.erase()`](https://python-gitlab.readthedocs.io/en/stable/gl_objects/pipelines_and_jobs.html#jobs) instead of `job.delete_artifacts()`.
To avoid this API call from being blocked, set the script to sleep for a short amount of time between calls
that delete the job artifact:

```python
    for job in jobs_marked_delete_artifacts:
        # delete the artifacts and job log
        print("DEBUG", job)
        #job.delete_artifacts()
        job.erase()
        # Sleep for 1 second
        time.sleep(1)
```

Support for creating a retention policy for job logs is proposed in [issue 374717](https://gitlab.com/gitlab-org/gitlab/-/issues/374717).

### Delete old pipelines

Pipelines do not add to the overall storage usage, but if required you can automate their deletion.

To delete pipelines based on a specific date, specify the `created_at` key.
You can use the date to calculate the difference between the current date and
when the pipeline was created. If the age is larger than the threshold, the pipeline is deleted.

NOTE:
The `created_at` key must be converted from a timestamp to Unix epoch time,
for example with `date -d '2023-08-08T18:59:47.581Z' +%s`.

Example with GitLab CLI:

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

In the following example that uses a Bash script:

- `jq` and the GitLab CLI are installed and authorized.
- The exported environment variable `GL_PROJECT_ID`. Defaults to the GitLab predefined variable `CI_PROJECT_ID`.
- The exported environment variable `CI_SERVER_HOST` that points to the GitLab instance URL.

::Tabs

:::TabTitle Using the API with glab

The full script `get_cicd_pipelines_compare_age_threshold_example.sh` is located in the [GitLab API with Linux Shell](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-linux-shell) project.

```shell
#!/bin/bash

# Required programs:
# - GitLab CLI (glab): https://docs.gitlab.com/ee/editor_extensions/gitlab_cli/index.html
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

:::TabTitle Using the glab CLI

The full script `cleanup-old-pipelines.sh` is located in the [GitLab API with Linux Shell](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-linux-shell) project.

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

:::TabTitle Using the API with Python

You can also use the [`python-gitlab` API library](https://python-gitlab.readthedocs.io/en/stable/gl_objects/pipelines_and_jobs.html#project-pipelines) and
the `created_at` attribute to implement a similar algorithm that compares the job artifact age:

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

::EndTabs

Automatic deletion of old pipelines is proposed in [issue 338480](https://gitlab.com/gitlab-org/gitlab/-/issues/338480).

### List expiry settings for job artifacts

To manage artifact storage, you can update or configure when an artifact expires.
The expiry setting for artifacts are configured in each job configuration in the `.gitlab-ci.yml`.

If there are multiple projects, and based on how job definitions are organized in the CI/CD configuration, it might be difficult
to locate the expiry setting. You can use a script to search the entire CI/CD configuration. This includes access to objects that
are resolved after they inherit values, like `extends` or `!reference`.

The script retrieves merged CI/CD configuration files and searches for the artifacts key to:

- Identify jobs that do not have an expiry setting.
- Return expiry settings for jobs that have the artifact expiry configured.

The following process describes how the script searches for the artifact expiry setting:

1. To generate a merged CI/CD configuration, the script loops over all projects and calls
   the [`ci_lint()`](https://python-gitlab.readthedocs.io/en/stable/gl_objects/ci_lint.html) method.
1. The `yaml_load` function loads the merged configuration into Python data structures for more analysis.
1. A dictionary that also has the key `script` identifies itself as a job definition, where the `artifacts`
   key might exists.
1. If yes, the script parses the sub key `expire_in` and stores the details to print later in a Markdown table summary.

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
        print("|Project|Job|Artifact expiry|\n|-|-|-|") #Start markdown friendly table
        for k, details in ci_job_artifacts_expiry.items():
            if details['job_name'][0] == '.':
                continue # ignore job templates that start with a '.'
            print(f'| [{ details["project_name"] }]({details["project_web_url"]}) | { details["job_name"] } | { details["artifacts_expiry"] if details["artifacts_expiry"] is not None else "❌ N/A" } |')
```

The script generates a Markdown summary table with:

- Project name and URL.
- Job name.
- The `artifacts:expire_in` setting, or `N/A` if there is no setting.

The script does not print job templates that:

- Start with a `.` character.
- Are not instantiated as runtime job objects that generate artifacts.

```shell
export GL_GROUP_ID=56595735

# Install script dependencies
python3 -m pip install 'python-gitlab[yaml]'

python3 get_all_cicd_config_artifacts_expiry.py

|Project|Job|Artifact expiry|
|-|-|-|
| [Gen Job Artifacts 4](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-4) | generator | 30 days |
| [Gen Job Artifacts with expiry and included jobs](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs) | included-job10 | 10 days |
| [Gen Job Artifacts with expiry and included jobs](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs) | included-job1 | 1 days |
| [Gen Job Artifacts with expiry and included jobs](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs) | included-job30 | 30 days |
| [Gen Job Artifacts with expiry and included jobs](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs) | generator | 30 days |
| [Gen Job Artifacts 2](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-2) | generator | ❌ N/A |
| [Gen Job Artifacts 1](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-1) | generator | ❌ N/A |
```

The `get_all_cicd_config_artifacts_expiry.py` script is located in the [GitLab API with Python project](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-api-python/).

Alternatively, you can use [advanced search](search/advanced_search.md) with API requests. The following example uses the [scope: blobs](../api/search.md#scope-blobs) to searches for the string `artifacts` in all `*.yml` files:

```shell
# https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs
export GL_PROJECT_ID=48349263

glab api --method GET projects/$GL_PROJECT_ID/search --field "scope=blobs" --field "search=expire_in filename:*.yml"
```

For more information about the inventory approach, see [How GitLab can help mitigate deletion of open source container images on Docker Hub](https://about.gitlab.com/blog/2023/03/16/how-gitlab-can-help-mitigate-deletion-open-source-images-docker-hub/).

### Set default expiry for job artifacts

To set the default expiry for job artifacts in a project, specify the `expire_in` value in the `.gitlab-ci.yml` file:

```yaml
default:
    artifacts:
        expire_in: 1 week
```

## Manage Container Registries storage

Container registries are available [for projects](../api/container_registry.md#within-a-project) or [for groups](../api/container_registry.md#within-a-group). You can analyze both locations to implement a cleanup strategy.

### List container registries

To list Container Registries in a project:

::Tabs

:::TabTitle curl

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

:::TabTitle GitLab CLI

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

::EndTabs

### Delete container images in bulk

When you [delete container image tags in bulk](../api/container_registry.md#delete-registry-repository-tags-in-bulk),
you can configure:

- The matching regular expressions for tag names and images to keep (`name_regex_keep`) or delete (`name_regex_delete`)
- The number of image tags to keep matching the tag name (`keep_n`)
- The number of days before an image tag can be deleted (`older_than`)

WARNING:
On GitLab.com, due to the scale of the container registry, the number of tags deleted by this API is limited.
If your container registry has a large number of tags to delete, only some of them are deleted. You might need
to call the API multiple times. To schedule tags for automatic deletion, use a [cleanup policy](#create-a-cleanup-policy-for-containers) instead.

The following example uses the [`python-gitlab` API library](https://python-gitlab.readthedocs.io/en/stable/gl_objects/repository_tags.html) to fetch a list of tags, and calls the `delete_in_bulk()` method with filter parameters.

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

### Create a cleanup policy for containers

Use the project REST API endpoint to [create cleanup policies](packages/container_registry/reduce_container_registry_storage.md#use-the-cleanup-policy-api) for containers. After you set the cleanup policy, all container images that match your specifications are deleted automatically. You do not need additional API automation scripts.

To send the attributes as a body parameter:

- Use the `--input -` parameter to read from the standard input.
- Set the `Content-Type` header.

The following example uses the GitLab CLI to create a cleanup policy:

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

### Optimize container images

You can optimize container images to reduce the image size and overall storage consumption in the container registry. Learn more in the [pipeline efficiency documentation](../ci/pipelines/pipeline_efficiency.md#optimize-docker-images).

## Manage package registry storage

Package registries are available [for projects](../api/packages.md#for-a-project) or [for groups](../api/packages.md#for-a-group).

### List packages and files

The following example shows fetching packages from a defined project ID using the GitLab CLI. The result set is an array of dictionary items that can be filtered with the `jq` command chain.

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

Use the package ID to inspect the files and their size in the package.

```shell
glab api --method GET projects/$GL_PROJECT_ID/packages/16669383/package_files | jq --compact-output '.[]' |
 jq --compact-output '.package_id,.file_name,.size'

16669383
"nighly.tar.gz"
10487563
```

A similar automation shell script is created in the [delete old pipelines](#delete-old-pipelines) section.

The following script example uses the `python-gitlab` library to fetch all packages in a loop,
and loops over its package files to print the `file_name` and `size` attributes.

```python
        packages = project.packages.list(order_by="created_at")

        for package in packages:

            package_files = package.package_files.list()
            for package_file in package_files:
                print("Package name: {p} File name: {f} Size {s}".format(
                    p=package.name, f=package_file.file_name, s=render_size_mb(package_file.size)))
```

### Delete packages

[Deleting a file in a package](../api/packages.md#delete-a-package-file) can corrupt the package. You should delete the package when performing automated cleanup maintenance.

To delete a package, use the GitLab CLI to change the `--method`
parameter to `DELETE`:

```shell
glab api --method DELETE projects/$GL_PROJECT_ID/packages/16669383
```

To calculate the package size and compare it against a size threshold, you can use the `python-gitlab` library
to extend the code described in the [list packages and files](#list-packages-and-files) section.

The following code example also calculates the package age and deletes the package when the conditions match:

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

The code generates the following output that you can use for further analysis:

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

### Dependency Proxy

Review the [cleanup policy](packages/dependency_proxy/reduce_dependency_proxy_storage.md#cleanup-policies) and how to [purge the cache using the API](packages/dependency_proxy/reduce_dependency_proxy_storage.md#use-the-api-to-clear-the-cache)

## Improve output readability

You might need to convert timestamp seconds into a duration format, or print raw bytes in a more
representative format. You can use the following helper functions to transform values for improved
readability:

```shell
# Current Unix timestamp
date +%s

# Convert `created_at` date time with timezone to Unix timestamp
date -d '2023-08-08T18:59:47.581Z' +%s
```

Example with Python that uses the `python-gitlab` API library:

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

## Testing for storage management automation

To test storage management automation, you might need to generate test data, or populate
storage to verify that the analysis and deletion works as expected. The following sections
provide tools and tips about testing and generating storage blobs in a short amount of time.

### Generate job artifacts

Create a test project to generate fake artifact blobs using CI/CD job matrix builds. Add a CI/CD pipeline to generate artifacts on a daily basis

1. Create a new project.
1. Add the following snippet to `.gitlab-ci.yml` to include the job artifact generator configuration.

   ```yaml
   include:
       - remote: https://gitlab.com/gitlab-da/use-cases/efficiency/job-artifact-generator/-/raw/main/.gitlab-ci.yml
   ```

1. [Configure pipeline schedules](../ci/pipelines/schedules.md#add-a-pipeline-schedule).
1. [Trigger the pipeline manually](../ci/pipelines/schedules.md#run-manually).

Alternatively, reduce the 86 MB daily generated MB to different values in the `MB_COUNT` variable.

```yaml
include:
    - remote: https://gitlab.com/gitlab-da/use-cases/efficiency/job-artifact-generator/-/raw/main/.gitlab-ci.yml

generator:
    parallel:
        matrix:
            - MB_COUNT: [1, 5, 10, 20, 50]

```

For more information, see the [Job Artifact Generator README](https://gitlab.com/gitlab-da/use-cases/efficiency/job-artifact-generator), with an [example group](https://gitlab.com/gitlab-da/playground/artifact-gen-group).

### Generate job artifacts with expiry

The project CI/CD configuration specifies job definitions in:

- The main `.gitlab-ci.yml` configuration file.
- The `artifacts:expire_in` setting.
- Project files and templates.

To test the analysis scripts, the [`gen-job-artifacts-expiry-included-jobs`](https://gitlab.com/gitlab-da/playground/artifact-gen-group/gen-job-artifacts-expiry-included-jobs) project provides an example configuration.

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

### Generate container images

The example group [`container-package-gen-group`](https://gitlab.com/gitlab-da/playground/container-package-gen-group) provides projects that:

- Use a base image in Dockerfile to build a new image.
- Include the `Docker.gitlab-ci.yml` template to build images on GitLab.com SaaS.
- Configure pipeline schedules to generate new images daily.

Example projects available to fork:

- [`docker-alpine-generator`](https://gitlab.com/gitlab-da/playground/container-package-gen-group/docker-alpine-generator)
- [`docker-python-generator`](https://gitlab.com/gitlab-da/playground/container-package-gen-group/docker-python-generator)

### Generate generic packages

The example project [`generic-package-generator`](https://gitlab.com/gitlab-da/playground/container-package-gen-group/generic-package-generator) provides projects that:

- Generate a random text blob, and create a tarball with the current Unix timestamp as release version.
- Upload the tarball into the generic package registry, using the Unix timestamp as release version.

To generate generic packages, you can use this standalone `.gitlab-ci.yml` configuration:

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

### Generate storage usage with forks

Use the following projects to test storage usage with [cost factors for forks](storage_usage_quotas.md#view-project-fork-storage-usage):

- Fork [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab) into a new namespace or group (includes LFS, Git repository).
- Fork [`gitlab-com/www-gitlab-com`](https://gitlab.com/gitlab-com/www-gitlab-com) into a new namespace or group.

## Community resources

The following resources are not officially supported. Ensure to test scripts and tutorials before running destructive cleanup commands that may not be reverted.

- Forum topic: [Storage management automation resources](https://forum.gitlab.com/t/storage-management-automation-resources/91184)
- Script: [GitLab Storage Analyzer](https://gitlab.com/gitlab-da/use-cases/gitlab-api/gitlab-storage-analyzer), unofficial project by the [GitLab Developer Evangelism team](https://gitlab.com/gitlab-da/). You find similar code examples in this documentation how-to here.
