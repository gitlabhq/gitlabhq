---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 지원이 중단된 키워드
---

일부 CI/CD 키워드는 지원이 중단되었으며 더 이상 사용하지 않습니다.

> [!warning]
> 이러한 키워드는 여전히 사용할 수 있지만 향후 주요 마일스톤에서 제거될 수 있습니다.

## 전역으로 정의된 `image`, `services`, `cache`, `before_script`, `after_script` {#globally-defined-image-services-cache-before_script-after_script}

`image`, `services`, `cache`, `before_script`, 그리고 `after_script`를 전역으로 정의하는 것은 지원이 중단되었습니다. 대신 [`default`](_index.md#default)를 사용하세요.

예를 들어:

```yaml
default:
  image: ruby:3.0
  services:
    - docker:dind
  cache:
    paths: [vendor/]
  before_script:
    - bundle config set path vendor/bundle
    - bundle install
  after_script:
    - rm -rf tmp/
```

## `only` / `except` {#only--except}

> [!note]
> `only`와 `except`은 지원이 중단되었습니다. 파이프라인에 작업을 추가할 시기를 제어하려면 대신 [`rules`](_index.md#rules)를 사용하세요.

`only`과 `except`를 사용하여 파이프라인에 작업을 추가할 시기를 제어할 수 있습니다.

- `only`을 사용하여 작업이 실행되는 시기를 정의하세요.
- `except`을 사용하여 작업이 실행되지 않는 시기를 정의하세요.

### `only:refs` / `except:refs` {#onlyrefs--exceptrefs}

> [!note]
> `only:refs`와 `except:refs`은 지원이 중단되었습니다. refs, 정규 표현식 또는 변수를 사용하여 파이프라인에 작업을 추가할 시기를 제어하려면 대신 [`rules:if`](_index.md#rulesif)를 사용하세요.

`only:refs`과 `except:refs` 키워드를 사용하여 브랜치 이름 또는 파이프라인 유형을 기반으로 파이프라인에 작업을 추가할 시기를 제어할 수 있습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 다음을 포함한 임의 개수의 배열:

- 브랜치 이름(예: `main` 또는 `my-feature-branch`)입니다.
- 브랜치 이름과 일치하는 정규 표현식(예: `/^feature-.*/`)입니다.
- 다음 키워드:

  | **값**                | **설명** |
  | -------------------------|-----------------|
  | `api`                    | [파이프라인 API](../../api/pipelines.md#create-a-new-pipeline)에 의해 트리거된 파이프라인입니다. |
  | `branches`               | 파이프라인의 Git 참조가 브랜치인 경우입니다. |
  | `chat`                   | [GitLab ChatOps](../chatops/_index.md) 명령을 사용하여 생성한 파이프라인입니다. |
  | `external`               | GitLab 이외의 CI 서비스를 사용하는 경우입니다. |
  | `external_pull_requests` | GitHub의 외부 풀 리퀘스트가 생성되거나 업데이트될 때입니다([외부 풀 리퀘스트용 파이프라인](../ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests) 참조). |
  | `merge_requests`         | 머지 리퀘스트 파이프라인이 생성되거나 업데이트될 때 생성된 파이프라인입니다. [머지 리퀘스트 파이프라인](../pipelines/merge_request_pipelines.md), [머지된 결과 파이프라인](../pipelines/merged_results_pipelines.md), 그리고 [머지 트레인](../pipelines/merge_trains.md)을 활성화합니다. |
  | `pipelines`              | [다중 프로젝트 파이프라인](../pipelines/downstream_pipelines.md#multi-project-pipelines)에 의해 [`CI_JOB_TOKEN`으로 API 사용](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api)하거나 [`trigger`](_index.md#trigger) 키워드로 생성됩니다. |
  | `pushes`                 | `git push` 이벤트에 의해 트리거된 파이프라인이며, 브랜치 및 태그를 포함합니다. |
  | `schedules`              | [예약된 파이프라인](../pipelines/schedules.md)입니다. |
  | `tags`                   | 파이프라인의 Git 참조가 태그인 경우입니다. |
  | `triggers`               | [트리거 토큰](../triggers/_index.md#configure-cicd-jobs-to-run-in-triggered-pipelines)을 사용하여 생성한 파이프라인입니다. |
  | `web`                    | GitLab UI에서 **새 파이프라인**을 선택하여 프로젝트의 **빌드** > **파이프라인** 섹션에서 생성한 파이프라인입니다. |

**`only:refs`과 `except:refs`의 예**:

```yaml
job1:
  script: echo
  only:
    - main
    - /^issue-.*$/
    - merge_requests

job2:
  script: echo
  except:
    - main
    - /^stable-branch.*$/
    - schedules
```

**Additional details**:

- 예약된 파이프라인은 특정 브랜치에서 실행되므로 `only: branches`로 구성된 작업도 예약된 파이프라인에서 실행됩니다. `except: schedules`를 추가하여 `only: branches` 상태의 작업이 예약된 파이프라인에서 실행되지 않도록 방지하세요.
- `only` 또는 `except`를 다른 키워드 없이 사용하는 것은 `only: refs` 또는 `except: refs`와 동일합니다. 예를 들어 다음 두 작업 구성은 동일한 동작을 합니다:

  ```yaml
  job1:
    script: echo
    only:
      - branches

  job2:
    script: echo
    only:
      refs:
        - branches
  ```

- 작업이 `only`, `except` 또는 [`rules`](_index.md#rules)를 사용하지 않으면 `only`는 기본적으로 `branches`과 `tags`로 설정됩니다.

  예를 들어 `job1`과 `job2`는 동등합니다:

  ```yaml
  job1:
    script: echo "test"

  job2:
    script: echo "test"
    only:
      - branches
      - tags
  ```

### `only:variables` / `except:variables` {#onlyvariables--exceptvariables}

> [!note]
> `only:variables`와 `except:variables`은 지원이 중단되었습니다. refs, 정규 표현식 또는 변수를 사용하여 파이프라인에 작업을 추가할 시기를 제어하려면 대신 [`rules:if`](_index.md#rulesif)를 사용하세요.

`only:variables` 또는 `except:variables` 키워드를 사용하여 [CI/CD 변수](../variables/_index.md)의 상태를 기반으로 파이프라인에 작업을 추가할 시기를 제어할 수 있습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- [CI/CD 변수 표현식](../jobs/job_rules.md#cicd-variable-expressions) 배열입니다.

**`only:variables`의 예**:

```yaml
deploy:
  script: cap staging deploy
  only:
    variables:
      - $RELEASE == "staging"
      - $STAGING
```

### `only:changes` / `except:changes` {#onlychanges--exceptchanges}

> [!note]
> `only:changes`와 `except:changes`은 지원이 중단되었습니다. 변경된 파일을 사용하여 파이프라인에 작업을 추가할 시기를 제어하려면 대신 [`rules:changes`](_index.md#ruleschanges)를 사용하세요.

`changes` 키워드를 `only`와 함께 사용하여 작업을 실행하거나 `except`과 함께 사용하여 Git 푸시 이벤트가 파일을 수정할 때 작업을 건너뛰세요.

`changes`을 다음 refs가 있는 파이프라인에서 사용하세요:

- `branches`
- `external_pull_requests`
- `merge_requests`

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**: 다음을 포함한 임의 개수의 배열:

- 파일의 경로입니다.
- 와일드카드 경로:
  - 단일 디렉터리(예: `path/to/directory/*`)입니다.
  - 디렉터리 및 모든 하위 디렉터리(예: `path/to/directory/**/*`)입니다.
- 와일드카드 [glob](https://en.wikipedia.org/wiki/Glob_(programming)) 경로는 동일한 확장명 또는 여러 확장명을 가진 모든 파일(예: `*.md` 또는 `path/to/directory/*.{rb,py,sh}`)입니다.
- 루트 디렉터리 또는 모든 디렉터리의 파일에 대한 와일드카드 경로(큰따옴표로 묶임)입니다. 예를 들어 `"*.json"` 또는 `"**/*.json"`입니다.

**`only:changes`의 예**:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  only:
    refs:
      - branches
    changes:
      - Dockerfile
      - docker/scripts/*
      - dockerfiles/**/*
      - more_scripts/*.{rb,py,sh}
      - "**/*.json"
```

**Additional details**:

- `changes`은 일치하는 파일이 변경된 경우(`OR` 작업) `true`로 확인됩니다.
- Glob 패턴은 Ruby의 [`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)로 해석되며 [플래그](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29) `File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`를 사용합니다.
- `branches`, `external_pull_requests` 또는 `merge_requests` 이외의 refs를 사용하는 경우 `changes`는 주어진 파일이 새로운지 오래된지 확인할 수 없고 항상 `true`를 반환합니다.
- `only: changes`을 다른 refs와 함께 사용하는 경우 작업은 변경 사항을 무시하고 항상 실행됩니다.
- `except: changes`을 다른 refs와 함께 사용하는 경우 작업은 변경 사항을 무시하고 절대 실행되지 않습니다.

**Related topics**:

- [작업또는 파이프라인이 `only: changes`를 사용할 때 예기치 않게 실행될 수 있습니다](../jobs/job_troubleshooting.md#jobs-or-pipelines-run-unexpectedly-when-using-changes).

### `only:kubernetes` / `except:kubernetes` {#onlykubernetes--exceptkubernetes}

> [!note]
> `only:kubernetes`와 `except:kubernetes`은 지원이 중단되었습니다. 프로젝트에서 Kubernetes 서비스가 활성 상태일 때 파이프라인에 작업을 추가할 시기를 제어하려면 [`rules:if`](_index.md#rulesif)를 [`CI_KUBERNETES_ACTIVE`](../variables/predefined_variables.md) 사전 정의된 CI/CD 변수와 함께 대신 사용하세요.

`only:kubernetes` 또는 `except:kubernetes`를 사용하여 프로젝트에서 Kubernetes 서비스가 활성 상태일 때 파이프라인에 작업을 추가할 시기를 제어하세요.

**Keyword type**: 작업별입니다. 작업의 일부로만 사용할 수 있습니다.

**Supported values**:

- `kubernetes` 전략은 `active` 키워드만 허용합니다.

**`only:kubernetes`의 예**:

```yaml
deploy:
  only:
    kubernetes: active
```

이 예에서 `deploy` 작업은 프로젝트에서 Kubernetes 서비스가 활성 상태일 때만 실행됩니다.

## `publish` 키워드 및 GitLab Pages용 `pages` 작업 이름 {#publish-keyword-and-pages-job-name-for-gitlab-pages}

GitLab Pages 배포 작업의 작업 레벨 `publish` 키워드 및 `pages` 작업 이름은 지원이 중단되었습니다.

페이지 배포를 제어하려면 [`pages`](_index.md#pages) 및 [`pages.publish`](_index.md#pagespublish) 키워드를 대신 사용하세요.

## `environment:kubernetes:namespace` 및 `environment:kubernetes:flux_resource_path` {#environmentkubernetesnamespace-and-environmentkubernetesflux_resource_path}

> [!note]
> `environment:kubernetes:namespace` 및 `environment:kubernetes:flux_resource_path`은 `kubernetes` 아래에서 직접 사용할 때 지원이 중단되었습니다. 대신 `environment:kubernetes:dashboard:namespace` 및 `environment:kubernetes:dashboard:flux_resource_path`을 사용하여 대시보드 설정을 구성하세요. 자세한 내용은 [`environment:kubernetes`](_index.md#environmentkubernetes)를 참조하세요.

`environment:kubernetes:namespace` 및 `environment:kubernetes:flux_resource_path`를 사용하여 Kubernetes 대시보드 설정을 구성할 수 있지만 `kubernetes` 섹션 아래에서 직접 사용하는 것은 지원이 중단되었습니다.

**Keyword type**: 작업 키워드입니다. 작업의 일부로만 사용할 수 있습니다.

**`environment:kubernetes:namespace`과 `environment:kubernetes:flux_resource_path`의 예**:

```yaml
deploy:
  environment:
    name: production
    kubernetes:
      agent: path/to/agent/project:agent-name
      namespace: my-namespace
      flux_resource_path: helm.toolkit.fluxcd.io/v2/namespaces/flux-system/helmreleases/helm-release
```

**`environment:kubernetes:dashboard:namespace`과 `environment:kubernetes:dashboard:flux_resource_path`의 예**:

```yaml
deploy:
  environment:
    name: production
    kubernetes:
      agent: path/to/agent/project:agent-name
      dashboard:
        namespace: my-namespace
        flux_resource_path: helm.toolkit.fluxcd.io/v2/namespaces/flux-system/helmreleases/helm-release
```
