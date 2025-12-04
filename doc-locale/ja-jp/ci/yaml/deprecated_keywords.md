---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 非推奨のキーワード
---

一部のCI/CDキーワードは非推奨であり、使用は推奨されなくなりました。

{{< alert type="warning" >}}

これらのキーワードは引き続き使用して下位互換性を確保できますが、将来のメジャーマイルストーンでの削除が予定されている可能性があります。

{{< /alert >}}

## グローバル定義の`image`、`services`、`cache`、`before_script`、`after_script` {#globally-defined-image-services-cache-before_script-after_script}

`image`、`services`、`cache`、`before_script`、および`after_script`をグローバルに定義することは推奨されません。代わりに[`default`](_index.md#default)を使用してください。

例: 

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

### `only` / `except` {#only--except}

{{< alert type="note" >}}

`only`と`except`は非推奨になりました。ジョブをパイプラインに追加するタイミングを制御するには、代わりに[`rules`](_index.md#rules)を使用してください。

{{< /alert >}}

`only`と`except`を使用すると、ジョブをパイプラインに追加するタイミングを制御できます。

- `only`を使用して、ジョブの実行タイミングを定義します。
- `except`を使用して、ジョブを実行**does not**（しない）タイミングを定義します。

#### `only:refs` / `except:refs` {#onlyrefs--exceptrefs}

{{< alert type="note" >}}

`only:refs`と`except:refs`は非推奨になりました。ref、正規表現、または変数を使用してジョブをパイプラインに追加するタイミングを制御するには、代わりに[`rules:if`](_index.md#rulesif)を使用してください。

{{< /alert >}}

`only:refs`キーワードと`except:refs`キーワードを使用して、ブランチ名またはパイプラインの種類に基づいて、ジョブをパイプラインに追加するタイミングを制御できます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 次の要素を任意の数だけ含む配列:

- ブランチ名（`main`や`my-feature-branch`など）。
- ブランチ名に一致する正規表現（`/^feature-.*/`など）。
- 次のキーワード:

  | **値**                | **説明** |
  | -------------------------|-----------------|
  | `api`                    | [パイプラインAPI](../../api/pipelines.md#create-a-new-pipeline)によってトリガーされたパイプライン。 |
  | `branches`               | パイプラインのGit参照がブランチである場合。 |
  | `chat`                   | [GitLab ChatOps](../chatops/_index.md)コマンドを使用して作成されたパイプライン。 |
  | `external`               | GitLab以外のCIサービスを使用する場合。 |
  | `external_pull_requests` | GitHubで外部プルリクエストが作成または更新された場合（「[外部プルリクエストのパイプライン](../ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests)」を参照）。 |
  | `merge_requests`         | マージリクエストの作成時または更新時に作成されるパイプラインの場合。[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md) 、[マージ結果パイプライン](../pipelines/merged_results_pipelines.md) 、[マージトレイン](../pipelines/merge_trains.md)を有効にします。 |
  | `pipelines`              | [`CI_JOB_TOKEN`を使用したAPI](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api) 、または[`trigger`](_index.md#trigger)キーワードにより作成された[マルチプロジェクトパイプライン](../pipelines/downstream_pipelines.md#multi-project-pipelines)。 |
  | `pushes`                 | `git push`イベントによってトリガーされたパイプライン（ブランチとタグを含む）の場合。 |
  | `schedules`              | [スケジュールされたパイプライン](../pipelines/schedules.md)。 |
  | `tags`                   | パイプラインのGit参照がタグの場合。 |
  | `triggers`               | [トリガートークン](../triggers/_index.md#configure-cicd-jobs-to-run-in-triggered-pipelines)を使用して作成されたパイプライン。 |
  | `web`                    | GitLab UIで、プロジェクトの**ビルド** > **パイプライン**セクションから**パイプラインを新規作成**を選択して作成されたパイプライン。 |

**`only:refs`と`except:refs`の例**:

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

**補足情報**:

- スケジュールされたパイプラインは特定のブランチで実行されるため、`only: branches`で構成されたジョブもスケジュールされたパイプラインで実行されます。スケジュールされたパイプラインで`only: branches`を含むジョブが実行されないようにするには、`except: schedules`を追加します。
- 他のキーワードなしで使用される`only`または`except`は、`only: refs`または`except: refs`と同等です。たとえば、次の2つのジョブ構成の動作は同じです:

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

- ジョブが`only`、`except`、または[`rules`](_index.md#rules)のいずれも使用しない場合、デフォルトでは、`only`は`branches`と`tags`に設定されます。

  たとえば、`job1`と`job2`は同等です:

  ```yaml
  job1:
    script: echo "test"

  job2:
    script: echo "test"
    only:
      - branches
      - tags
  ```

#### `only:variables` / `except:variables` {#onlyvariables--exceptvariables}

{{< alert type="note" >}}

`only:variables`と`except:variables`は非推奨になりました。ref、正規表現、または変数を使用してジョブをパイプラインに追加するタイミングを制御するには、代わりに[`rules:if`](_index.md#rulesif)を使用してください。

{{< /alert >}}

`only:variables`または`except:variables`キーワードを使用すると、[CI/CD変数](../variables/_index.md)のステータスに基づいて、ジョブをパイプラインに追加するタイミングを制御できます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- [CI/CD変数式](../jobs/job_rules.md#cicd-variable-expressions)の配列。

**`only:variables`の例**

```yaml
deploy:
  script: cap staging deploy
  only:
    variables:
      - $RELEASE == "staging"
      - $STAGING
```

#### `only:changes` / `except:changes` {#onlychanges--exceptchanges}

{{< alert type="note" >}}

`only:changes`と`except:changes`は非推奨になりました。変更されたファイルを使用してジョブをパイプラインに追加するタイミングを制御するには、代わりに[`rules:changes`](_index.md#ruleschanges)を使用します。

{{< /alert >}}

`changes`キーワードを`only`とともに使用してジョブを実行するか、または`except`とともに使用してGitプッシュイベントでファイルが変更された場合にジョブをスキップします。

パイプラインで`changes`を次のrefとともに使用します:

- `branches`
- `external_pull_requests`
- `merge_requests`

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 次の要素を任意の数だけ含む配列:

- ファイルのパス。
- 次のもののワイルドカードパス:
  - 単一のディレクトリ（例: `path/to/directory/*`）。
  - ディレクトリとそのすべてのサブディレクトリ（例: `path/to/directory/**/*`）。
- 同じ拡張子または複数の拡張子を持つすべてのファイルを対象とするワイルドカード[glob](https://en.wikipedia.org/wiki/Glob_(programming))パス（例: `*.md`、`path/to/directory/*.{rb,py,sh}`）。
- ルートディレクトリまたはすべてのディレクトリ内のファイルを対象とするワイルドカードパス（二重引用符で囲む）。例: `"*.json"`、`"**/*.json"`。

**`only:changes`の例**

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

**補足情報**:

- 一致するファイルのいずれかに変更がある場合、`changes`の解決結果は`true`になります（`OR`演算）。
- globパターンは、Rubyの[`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)で、[フラグ](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29)`File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`を使用して解釈されます。
- `branches`、`external_pull_requests`、`merge_requests`以外のrefを使用すると、`changes`は特定のファイルが新しいか古いかを判別できず、常に`true`を返します。
- `only: changes`を他のrefとともに使用すると、ジョブは変更を無視して常に実行されます。
- `except: changes`を他のrefとともに使用すると、ジョブは変更を無視して決して実行されません。

**関連トピック**:

- [`only: changes`を使用すると、予期せずにジョブまたはパイプラインが実行される可能性があります](../jobs/job_troubleshooting.md#jobs-or-pipelines-run-unexpectedly-when-using-changes)。

#### `only:kubernetes` / `except:kubernetes` {#onlykubernetes--exceptkubernetes}

{{< alert type="note" >}}

`only:kubernetes`と`except:kubernetes`は非推奨になりました。プロジェクトでKubernetesサービスがアクティブな場合にジョブをパイプラインに追加するかどうかを制御するには、代わりに[`CI_KUBERNETES_ACTIVE`](../variables/predefined_variables.md)事前定義済みのCI/CD変数とともに[`rules:if`](_index.md#rulesif)を使用してください。

{{< /alert >}}

`only:kubernetes`または`except:kubernetes`を使用して、Kubernetesサービスがプロジェクトでアクティブな場合にジョブをパイプラインに追加するかどうかを制御します。

**キーワードのタイプ**: ジョブ固有。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `kubernetes`戦略は、`active`キーワードのみを受け入れます。

**`only:kubernetes`の例**

```yaml
deploy:
  only:
    kubernetes: active
```

この例では、`deploy`ジョブが実行されるのは、プロジェクト内でKubernetesサービスがアクティブになっている場合のみです。

### GitLab Pagesの`publish`キーワードと`pages`ジョブ名 {#publish-keyword-and-pages-job-name-for-gitlab-pages}

GitLab Pagesのデプロイメントジョブに対するジョブレベルの`publish`キーワードと`pages`ジョブ名は非推奨になりました。

pagesデプロイを制御するには、代わりに[`pages`](_index.md#pages)キーワードと[`pages.publish`](_index.md#pagespublish)キーワードを使用してください。

### `environment:kubernetes:namespace`と`environment:kubernetes:flux_resource_path` {#environmentkubernetesnamespace-and-environmentkubernetesflux_resource_path}

{{< alert type="note" >}}

`environment:kubernetes:namespace`および`environment:kubernetes:flux_resource_path`は、`kubernetes`の直下で使用すると非推奨になります。ダッシュボードの設定を構成するには、代わりに`environment:kubernetes:dashboard:namespace`と`environment:kubernetes:dashboard:flux_resource_path`を使用します。詳細については、[`environment:kubernetes`](_index.md#environmentkubernetes)を参照してください。

{{< /alert >}}

`environment:kubernetes:namespace`と`environment:kubernetes:flux_resource_path`を使用してKubernetesダッシュボードの設定を構成できますが、`kubernetes`セクションの直下で使用すると非推奨になります。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**`environment:kubernetes:namespace`と`environment:kubernetes:flux_resource_path`の例**:

```yaml
deploy:
  environment:
    name: production
    kubernetes:
      agent: path/to/agent/project:agent-name
      namespace: my-namespace
      flux_resource_path: helm.toolkit.fluxcd.io/v2/namespaces/flux-system/helmreleases/helm-release
```

**`environment:kubernetes:dashboard:namespace`と`environment:kubernetes:dashboard:flux_resource_path`の例**:

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
