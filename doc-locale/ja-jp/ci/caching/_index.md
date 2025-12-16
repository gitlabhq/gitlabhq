---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDでのキャッシュ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

キャッシュとは、ジョブがダウンロードして保存する1つ以上のファイルのことです。同じキャッシュを使用する後続のジョブは、ファイルを再度ダウンロードする必要がないため、より高速に実行されます。

`.gitlab-ci.yml`ファイルでキャッシュを定義する方法については、[`cache`のリファレンス](../yaml/_index.md#cache)を参照してください。

高度なキャッシュキー戦略については、以下を使用できます:

- [`cache:key:files`](../yaml/_index.md#cachekeyfiles): 特定のファイルの内容にリンクされたキーを生成します。
- [`cache:key:files_commits`](../yaml/_index.md#cachekeyfiles_commits): 特定のファイルの最新のコミットにリンクされたキーを生成します。

## キャッシュとアーティファクトの違い {#how-cache-is-different-from-artifacts}

インターネットからダウンロードしたパッケージなどの依存関係にはキャッシュを使用します。キャッシュはGitLab Runnerがインストールされている場所に保存され、[分散キャッシュが有効になっている](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching)場合はS3にアップロードされます。

ステージ間で中間ビルドの結果を渡すには、アーティファクトを使用します。アーティファクトはジョブによって生成され、GitLabに保存され、ダウンロードが可能です。

アーティファクトとキャッシュはどちらも、プロジェクトディレクトリからの相対パスを定義します。また、外部のファイルにリンクすることはできません。

### キャッシュ {#cache}

- `cache`キーワードを使用して、ジョブごとにキャッシュを定義します。それ以外の場合は無効になります。
- 後続のパイプラインでそのキャッシュを使用することができます。
- 依存関係が同一である場合、同じパイプライン内の後続のジョブはキャッシュを使用できます。
- 異なるプロジェクト間でキャッシュを共有することはできません。
- デフォルトでは、保護ブランチと保護されていないブランチは[キャッシュを共有しません](#cache-key-names)。ただし、[この動作を変更](#use-the-same-cache-for-all-branches)できます。

### アーティファクト {#artifacts}

- ジョブごとにアーティファクトを定義します。
- 同じパイプラインの後続のステージのジョブは、アーティファクトを使用できます。
- アーティファクトは、デフォルトで30日後に有効期限が切れます。カスタムの[有効期限](../yaml/_index.md#artifactsexpire_in)を定義できます。
- [最新のアーティファクトを保持する](../jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)設定が有効になっている場合、最新のアーティファクトは有効期限切れになりません。
- [依存関係](../yaml/_index.md#dependencies)を使用して、アーティファクトをフェッチするジョブを制御します。

## キャッシュに関する優れたプラクティス {#good-caching-practices}

キャッシュの可用性を最大限に高めるには、次の1つ以上を行います:

- [Runnerにタグを付け](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)、キャッシュを共有するジョブでそのタグを使用する。
- [特定のプロジェクトでのみ利用可能なRunnerを使用する](../runners/runners_scope.md#prevent-a-project-runner-from-being-enabled-for-other-projects)。
- ワークフローに合った[`key`を使用する](../yaml/_index.md#cachekey)。たとえば、ブランチごとに異なるキャッシュを設定できます。

Runnerがキャッシュと効率的に連携できるようにするには、次のいずれかを実行する必要があります:

- すべてのジョブに単一のRunnerを使用する。
- [分散キャッシュ](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching)を持つ複数のRunnerを使用する。この場合、キャッシュはS3バケットに保存されます。GitLab.comのインスタンスRunnerは、この方法で動作します。これらのRunnerはオートスケールモードにできますが、そうである必要はありません。キャッシュオブジェクトを管理するには、ライフサイクルルールを適用して、一定期間後にキャッシュオブジェクトを削除します。ライフサイクルルールは、オブジェクトストレージサーバーで利用できます。
- 同じアーキテクチャを持つ複数のRunnerを使用し、これらのRunnerが共通のネットワークマウントされたディレクトリを共有してキャッシュを保存するようにする。このディレクトリは、NFSまたは同様のものを使用する必要があります。これらのRunnerはオートスケールモードである必要があります。

## 複数のキャッシュを使用する {#use-multiple-caches}

1つのジョブにつき、最大4つのキャッシュを使用できます:

```yaml
test-job:
  stage: build
  cache:
    - key:
        files:
          - Gemfile.lock
      paths:
        - vendor/ruby
    - key:
        files:
          - yarn.lock
      paths:
        - .yarn-cache/
  script:
    - bundle config set --local path 'vendor/ruby'
    - bundle install
    - yarn install --cache-folder .yarn-cache
    - echo Run tests...
```

複数のキャッシュがフォールバックキャッシュキーと組み合わされている場合、キャッシュが見つからないときは常にグローバルフ​​ォールバックキャッシュがフェッチされます。

## フォールバックキャッシュキーを使用する {#use-a-fallback-cache-key}

### キャッシュごとのフォールバックキー {#per-cache-fallback-keys}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110467)されました。

{{< /history >}}

各キャッシュエントリは、[`fallback_keys`キーワード](../yaml/_index.md#cachefallback_keys)で最大5つのフォールバックキーをサポートします。ジョブがキャッシュキーを見つけられない場合、ジョブは代わりにフォールバックキャッシュの取得を試みます。キャッシュが見つかるまで、フォールバックキーが順番に検索されます。キャッシュが見つからない場合、ジョブはキャッシュを使用せずに実行されます。次に例を示します:

```yaml
test-job:
  stage: build
  cache:
    - key: cache-$CI_COMMIT_REF_SLUG
      fallback_keys:
        - cache-$CI_DEFAULT_BRANCH
        - cache-default
      paths:
        - vendor/ruby
  script:
    - bundle config set --local path 'vendor/ruby'
    - bundle install
    - echo Run tests...
```

この例では、次のようになります:

1. ジョブは`cache-$CI_COMMIT_REF_SLUG`キャッシュを探します。
1. `cache-$CI_COMMIT_REF_SLUG`が見つからない場合、ジョブはフォールバックオプションとして`cache-$CI_DEFAULT_BRANCH`を探します。
1. `cache-$CI_DEFAULT_BRANCH`も見つからない場合、ジョブは2番目のフォールバックオプションとして`cache-default`を探します。
1. いずれも見つからない場合、ジョブはキャッシュを使用せずにすべてのRuby依存関係をダウンロードしますが、ジョブが完了すると`cache-$CI_COMMIT_REF_SLUG`の新しいキャッシュを作成します。

フォールバックキーは、`cache:key`と同じ処理ロジックに従います:

- [キャッシュを手動でクリア](#clear-the-cache-manually)すると、キャッシュごとのフォールバックキーには、他のキャッシュキーと同じようにインデックスが付加されます。
- [**保護ブランチに別のキャッシュを使用する**設定](#cache-key-names)が有効になっている場合、キャッシュごとのフォールバックキーには`-protected`または`-non_protected`が付加されます。

### グローバルフ​​ォールバックキー {#global-fallback-key}

[定義済み変数](../variables/predefined_variables.md)`$CI_COMMIT_REF_SLUG`を使用すれば、自分の[`cache:key`](../yaml/_index.md#cachekey)を指定できます。たとえば、`$CI_COMMIT_REF_SLUG`が`test`の場合、`test`でタグ付けされたキャッシュをダウンロードするようにジョブを設定できます。

このタグが付いたキャッシュが見つからない場合は、`CACHE_FALLBACK_KEY`を使用して、そのキャッシュが存在しない場合に使用するキャッシュを指定できます。

次の例では、`$CI_COMMIT_REF_SLUG`が見つからない場合、ジョブは`CACHE_FALLBACK_KEY`変数で定義されたキーを使用します:

```yaml
variables:
  CACHE_FALLBACK_KEY: fallback-key

job1:
  script:
    - echo
  cache:
    key: "$CI_COMMIT_REF_SLUG"
    paths:
      - binaries/
```

キャッシュ抽出の順序は次のとおりです:

1. `cache:key`を取得試行する
1. `fallback_keys`の各エントリを順番に取得試行する
1. `CACHE_FALLBACK_KEY`のグローバルフ​​ォールバックキーを取得試行する

最初のキャッシュが正常に取得された後、キャッシュ抽出プロセスは停止します。

## 特定のジョブのキャッシュを無効にする {#disable-cache-for-specific-jobs}

キャッシュをグローバルに定義すると、どのジョブも同じ定義を使用するようになります。ジョブごとにこの動作をオーバーライドできます。

ジョブに対してキャッシュを完全に無効にするには、次のように空のリストを使用します:

```yaml
job:
  cache: []
```

## グローバル設定を継承するが、ジョブごとに特定の設定をオーバーライドする {#inherit-global-configuration-but-override-specific-settings-per-job}

[アンカー](../yaml/yaml_optimization.md#anchors)を使用すると、グローバルキャッシュを上書きせずにキャッシュ設定をオーバーライドできます。たとえば、1つのジョブの`policy`をオーバーライドする場合、次のようになります:

```yaml
default:
  cache: &global_cache
    key: $CI_COMMIT_REF_SLUG
    paths:
      - node_modules/
      - public/
      - vendor/
    policy: pull-push

job:
  cache:
    # inherit all global cache settings
    <<: *global_cache
    # override the policy
    policy: pull
```

詳細については、[`cache: policy`](../yaml/_index.md#cachepolicy)を参照してください。

## キャッシュの一般的なユースケース {#common-use-cases-for-caches}

通常、キャッシュは、ジョブを実行するたびに依存関係やライブラリなどのコンテンツをダウンロードするのを防ぐために使用します。Node.jsパッケージ、PHPパッケージ、Ruby gem、Pythonライブラリなどをキャッシュできます。

例については、[GitLab CI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)を参照してください。

### 同じブランチ内のジョブ間でキャッシュを共有する {#share-caches-between-jobs-in-the-same-branch}

各ブランチのジョブで同じキャッシュを使用するには、`key: $CI_COMMIT_REF_SLUG`を使用してキャッシュを定義します:

```yaml
cache:
  key: $CI_COMMIT_REF_SLUG
```

この設定により、キャッシュを誤って上書きすることを防ぐことができます。ただし、マージリクエストの最初のパイプラインは遅くなります。次回コミットがブランチにプッシュされると、キャッシュが再利用され、ジョブがより速く実行されます。

次のコマンドで、ジョブごとおよびブランチごとにキャッシュを有効にできます:

```yaml
cache:
  key: "$CI_JOB_NAME-$CI_COMMIT_REF_SLUG"
```

次のコマンドで、ステージごとおよびブランチごとにキャッシュを有効にできます:

```yaml
cache:
  key: "$CI_JOB_STAGE-$CI_COMMIT_REF_SLUG"
```

### 異なるブランチのジョブ間でキャッシュを共有する {#share-caches-across-jobs-in-different-branches}

すべてのブランチとすべてのジョブでキャッシュを共有するには、すべてに同じキーを使用します:

```yaml
cache:
  key: one-key-to-rule-them-all
```

ブランチ間でキャッシュを共有しつつ、ジョブごとにキャッシュが一意になるようにするには、次のようにします:

```yaml
cache:
  key: $CI_JOB_NAME
```

### 変数を使用してジョブのキャッシュポリシーを制御する {#use-a-variable-to-control-a-jobs-cache-policy}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/371480)されました。

{{< /history >}}

プルポリシーだけが異なるジョブの重複を減らすには、[CI/CD変数](../variables/_index.md)を使用します。

次に例を示します:

```yaml
conditional-policy:
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      variables:
        POLICY: pull-push
    - if: $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH
      variables:
        POLICY: pull
  stage: build
  cache:
    key: gems
    policy: $POLICY
    paths:
      - vendor/bundle
  script:
    - echo "This job pulls and pushes the cache depending on the branch"
    - echo "Downloading dependencies..."
```

この例では、ジョブのキャッシュポリシーは次のとおりです:

- デフォルトブランチへの変更の場合: `pull-push`
- 他のブランチへの変更の場合: `pull`

### Node.jsの依存関係をキャッシュする {#cache-nodejs-dependencies}

プロジェクトで[npm](https://www.npmjs.com/)を使用してNode.jsの依存関係をインストールする場合、次の例では、すべてのジョブがそれを継承するようにデフォルトの`cache`を定義します。デフォルトでは、npmはホームフォルダー（`~/.npm`）にキャッシュデータを保存します。ただし、[プロジェクトディレクトリの外にあるものをキャッシュすることはできません](../yaml/_index.md#cachepaths)。代わりに、`./.npm`を使用するようにnpmに指示し、次のように、ブランチごとにキャッシュします:

```yaml
default:
  image: node:latest
  cache:  # Cache modules in between jobs
    key: $CI_COMMIT_REF_SLUG
    paths:
      - .npm/
  before_script:
    - npm ci --cache .npm --prefer-offline

test_async:
  script:
    - node ./specs/start.js ./specs/async.spec.js
```

#### ロックファイルからキャッシュキーを計算する {#compute-the-cache-key-from-the-lock-file}

[`cache:key:files`](../yaml/_index.md#cachekeyfiles)を使用して、`package-lock.json`や`yarn.lock`などのロックファイルからキャッシュキーを計算し、多くのジョブで再利用できます。

```yaml
default:
  cache:  # Cache modules using lock file
    key:
      files:
        - package-lock.json
    paths:
      - .npm/
```

[Yarn](https://yarnpkg.com/)を使用している場合は、[`yarn-offline-mirror`](https://classic.yarnpkg.com/blog/2016/11/24/offline-mirror/)を使用して、zip形式の`node_modules`tarballをキャッシュできます。圧縮する必要のあるファイルが少ないため、キャッシュの生成がより迅速になります:

```yaml
job:
  script:
    - echo 'yarn-offline-mirror ".yarn-cache/"' >> .yarnrc
    - echo 'yarn-offline-mirror-pruning true' >> .yarnrc
    - yarn install --frozen-lockfile --no-progress
  cache:
    key:
      files:
        - yarn.lock
    paths:
      - .yarn-cache/
```

### Ccacheを使用してC/C++コンパイルをキャッシュする {#cache-cc-compilation-using-ccache}

C/C++プロジェクトをコンパイルする場合、[Ccache](https://ccache.dev/)を使用してビルド時間を短縮できます。Ccacheは、以前のコンパイルをキャッシュし、同じコンパイルがいつ再度実行されるかを検出することで、再コンパイルをスピードアップします。Linuxカーネルのような大規模なプロジェクトをビルドするときに、コンパイルが大幅にスピードアップすることが期待できます。

`cache`を使用して、作成されたキャッシュをジョブ間で再利用します。次に例を示します:

```yaml
job:
  cache:
    paths:
      - ccache
  before_script:
    - export PATH="/usr/lib/ccache:$PATH"  # Override compiler path with ccache (this example is for Debian)
    - export CCACHE_DIR="${CI_PROJECT_DIR}/ccache"
    - export CCACHE_BASEDIR="${CI_PROJECT_DIR}"
    - export CCACHE_COMPILERCHECK=content  # Compiler mtime might change in the container, use checksums instead
  script:
    - ccache --zero-stats || true
    - time make                            # Actually build your code while measuring time and cache efficiency.
    - ccache --show-stats || true
```

単一のリポジトリに複数のプロジェクトがある場合、各プロジェクトに個別の`CCACHE_BASEDIR`は必要ありません。

### PHPの依存関係をキャッシュする {#cache-php-dependencies}

プロジェクトで[Composer](https://getcomposer.org/)を使用してPHPの依存関係をインストールする場合、次の例では、デフォルトの`cache`を定義し、すべてのジョブがその依存関係を継承するようにします。PHPライブラリモジュールは`vendor/`にインストールされ、ブランチごとにキャッシュされます:

```yaml
default:
  image: php:latest
  cache:  # Cache libraries in between jobs
    key: $CI_COMMIT_REF_SLUG
    paths:
      - vendor/
  before_script:
    # Install and run Composer
    - curl --show-error --silent "https://getcomposer.org/installer" | php
    - php composer.phar install

test:
  script:
    - vendor/bin/phpunit --configuration phpunit.xml --coverage-text --colors=never
```

### Pythonの依存関係をキャッシュする {#cache-python-dependencies}

プロジェクトで[pip](https://pip.pypa.io/en/stable/)を使用してPythonの依存関係をインストールする場合、次の例では、デフォルトの`cache`を定義し、すべてのジョブがその依存関係を継承するようにします。pipのキャッシュは`.cache/pip/`の下に定義され、ブランチごとにキャッシュされます:

```yaml
default:
  image: python:latest
  cache:                      # Pip's cache doesn't store the python packages
    paths:                    # https://pip.pypa.io/en/stable/topics/caching/
      - .cache/pip
  before_script:
    - python -V               # Print out python version for debugging
    - pip install virtualenv
    - virtualenv venv
    - source venv/bin/activate

variables:  # Change pip's cache directory to be inside the project directory because GitLab can only cache local items.
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"

test:
  script:
    - python setup.py test
    - pip install ruff
    - ruff --format=gitlab .
```

### Rubyの依存関係をキャッシュする {#cache-ruby-dependencies}

プロジェクトで[Bundler](https://bundler.io)を使用してgemの依存関係をインストールする場合、次の例では、デフォルトの`cache`を定義し、すべてのジョブがその依存関係を継承するようにします。gemは`vendor/ruby/`にインストールされ、ブランチごとにキャッシュされます:

```yaml
default:
  image: ruby:latest
  cache:                                            # Cache gems in between builds
    key: $CI_COMMIT_REF_SLUG
    paths:
      - vendor/ruby
  before_script:
    - ruby -v                                       # Print out ruby version for debugging
    - bundle config set --local path 'vendor/ruby'  # The location to install the specified gems to
    - bundle install -j $(nproc)                    # Install dependencies into ./vendor/ruby

rspec:
  script:
    - rspec spec
```

異なるgemを必要とするジョブがある場合は、グローバルな`cache`定義で`prefix`キーワードを使用します。この設定により、ジョブごとに異なるキャッシュが生成されます。

たとえば、テストジョブでは、本番環境にデプロイするジョブと同じgemが必要ない場合があります:

```yaml
default:
  cache:
    key:
      files:
        - Gemfile.lock
      prefix: $CI_JOB_NAME
    paths:
      - vendor/ruby

test_job:
  stage: test
  before_script:
    - bundle config set --local path 'vendor/ruby'
    - bundle install --without production
  script:
    - bundle exec rspec

deploy_job:
  stage: production
  before_script:
    - bundle config set --local path 'vendor/ruby'   # The location to install the specified gems to
    - bundle install --without test
  script:
    - bundle exec deploy
```

### Goの依存関係をキャッシュする {#cache-go-dependencies}

プロジェクトで[Goモジュール](https://go.dev/wiki/Modules)を使用してGoの依存関係をインストールする場合、次の例では、すべてのジョブが拡張できる`go-cache`テンプレートで`cache`を定義します。Goモジュールは`${GOPATH}/pkg/mod/`にインストールされ、`go`プロジェクトのすべてに対してキャッシュされます:

```yaml
.go-cache:
  variables:
    GOPATH: $CI_PROJECT_DIR/.go
  before_script:
    - mkdir -p .go
  cache:
    paths:
      - .go/pkg/mod/

test:
  image: golang:latest
  extends: .go-cache
  script:
    - go test ./... -v -short
```

### cURLのダウンロードをキャッシュする {#cache-curl-downloads}

プロジェクトで[cURL](https://curl.se/)を使用して依存関係またはファイルをダウンロードする場合、ダウンロードしたコンテンツをキャッシュすることができます。新しいダウンロードが利用可能になると、ファイルは自動的に更新されます。

```yaml
job:
  script:
    - curl --remote-time --time-cond .curl-cache/caching.md --output .curl-cache/caching.md "https://docs.gitlab.com/ci/caching/"
  cache:
    paths:
      - .curl-cache/
```

この例の場合、cURLはWebサーバーからファイルをダウンロードし、`.curl-cache/`のローカルファイルに保存します。`--remote-time`フラグはサーバーからレポートされた最終変更時刻を保存し、cURLは`--time-cond`を使うことにより、その最終変更時刻を、キャッシュされたファイルのタイムスタンプと比較します。リモートファイルのタイムスタンプのほうが新しい場合、ローカルキャッシュは自動的に更新されます。

## キャッシュの可用性 {#availability-of-the-cache}

キャッシュの目的は最適化ですが、常に機能することが保証されているわけではありません。場合によっては、キャッシュが必要な各ジョブでキャッシュされたファイルを再生成する必要があります。

[`.gitlab-ci.yml`でキャッシュを定義](../yaml/_index.md#cache)した後、キャッシュの可用性は次の要素に左右されます:

- Runnerのexecutorタイプ。
- ジョブ間でキャッシュを渡すために異なるRunnerが使用されるかどうか。

### キャッシュが保存される場所 {#where-the-caches-are-stored}

ジョブに対して定義されたすべてのキャッシュは、単一の`cache.zip`ファイルにアーカイブされます。Runnerの設定では、ファイルの保存場所を定義します。デフォルトでは、キャッシュはGitLab Runnerがインストールされているマシンに保存されます。場所は、executorのタイプによっても異なります。

| Runner executor        | キャッシュのデフォルトパス |
| ---------------------- | ------------------------- |
| [Shell](https://docs.gitlab.com/runner/executors/shell.html) | ローカルでは、`gitlab-runner`ユーザーのホームディレクトリ（`/home/gitlab-runner/cache/<user>/<project>/<cache-key>/cache.zip`）にあります。 |
| [Docker](https://docs.gitlab.com/runner/executors/docker.html) | ローカルでは、[Dockerボリューム](https://docs.gitlab.com/runner/executors/docker.html#configure-directories-for-the-container-build-and-cache)（`/var/lib/docker/volumes/<volume-id>/_data/<user>/<project>/<cache-key>/cache.zip`）にあります。 |
| [Docker Machine](https://docs.gitlab.com/runner/executors/docker_machine.html)（オートスケールRunner） | Docker executorと同じです。 |

ジョブでキャッシュとアーティファクトを使用して同じパスを保存する場合、キャッシュはアーティファクトの前に復元されるため、キャッシュが上書きされる可能性があります。

#### キャッシュキー名 {#cache-key-names}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/330047)されました。

{{< /history >}}

[グローバルフ​​ォールバックキャッシュキー](#global-fallback-key)を除き、サフィックスがキャッシュキーに追加されます。

例として、`cache.key`が`$CI_COMMIT_REF_SLUG`に設定され、2つのブランチである`main`と`feature`があると仮定すると、次の表は結果として得られるキャッシュのキーを表しています:

| ブランチ名 | キャッシュキー               |
|-------------|-------------------------|
| `main`      | `main-protected`        |
| `feature`   | `feature-non_protected` |

##### タグトリガーによるキャッシュサフィックス {#cache-suffix-with-tag-triggers}

パイプラインがタグ（`$CI_COMMIT_TAG`など）によってトリガーされる場合、キャッシュサフィックス（`-protected`または`-non_protected`）は、パイプラインが実行されるブランチではなく、タグの保護ステータスによって決定されます。

この動作により、トリガー参照がキャッシュアクセス許可を決定するため、一貫したセキュリティ境界が確保されます。

たとえば、異なるブランチでパイプラインをトリガーするタグの場合:

| トリガーの種類                | タグ保護 | ブランチ                  | キャッシュサフィックス     |
|-----------------------------|----------------|-------------------------|------------------|
| タグ`0.26.1` (保護されていません)  | 保護されていません    | `main` (保護)      | `-non_protected` |
| タグ`1.0.0` (保護)     | 保護      | `main` (保護)      | `-protected`     |
| タグ`dev-123` (保護されていません) | 保護されていません    | `feature` (保護されていません) | `-non_protected` |

##### すべてのブランチで同じキャッシュを使用する {#use-the-same-cache-for-all-branches}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/361643)されました。

{{< /history >}}

[キャッシュキー名](#cache-key-names)を使用しない場合は、すべてのブランチ（保護ブランチと保護されていないブランチ）で同じキャッシュを使用できます。

[キャッシュキー名](#cache-key-names)を使用したキャッシュの分離はセキュリティ機能であり、この機能を無効にできるのは、デベロッパーロールを付与されているすべてのユーザーの信頼性が極めて高い環境のみです。

すべてのブランチで同じキャッシュを使用するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **一般パイプライン**を展開します。
1. **保護ブランチに別のキャッシュを使用する**チェックボックスをオフにします。
1. **変更を保存**を選択します。

### アーカイブと抽出の仕組み {#how-archiving-and-extracting-works}

次の例は、2つの連続するステージでの2つのジョブを示しています:

```yaml
stages:
  - build
  - test

default:
  cache:
    key: build-cache
    paths:
      - vendor/
  before_script:
    - echo "Hello"

job A:
  stage: build
  script:
    - mkdir vendor/
    - echo "build" > vendor/hello.txt
  after_script:
    - echo "World"

job B:
  stage: test
  script:
    - cat vendor/hello.txt
```

1台のマシンに1つのRunnerがインストールされている場合、プロジェクトのすべてのジョブが同じホスト上で実行されます:

1. パイプラインが開始されます。
1. `job A`が実行されます。
1. キャッシュが抽出されます（見つかった場合）。
1. `before_script`が実行されます。
1. `script`が実行されます。
1. `after_script`が実行されます。
1. `cache`が実行され、`vendor/`ディレクトリが圧縮されて`cache.zip`に入れられます。このファイルは、[Runnerの設定](#where-the-caches-are-stored)と`cache: key`に基づいてディレクトリに保存されます。
1. `job B`が実行されます。
1. キャッシュが抽出されます（見つかった場合）。
1. `before_script`が実行されます。
1. `script`が実行されます。
1. パイプラインが完了します。

1台のマシンで単一のRunnerを使用すると、`job B`が`job A`とは異なるRunnerで実行される可能性があるという問題が発生しません。この設定により、複数のステージ間でキャッシュを再利用できることが保証されます。これは、実行が同じRunner/マシン内の`build`ステージから`test`ステージに移行する場合にのみ機能します。それ以外の場合、キャッシュが[利用できない可能性](#cache-mismatch)があります。

キャッシュプロセス中には、考慮すべき点がいくつかあります:

- 別のキャッシュ設定がある別のジョブが同じzipファイルにキャッシュを保存した場合、キャッシュが上書きされます。S3ベースの共有キャッシュが使用される場合、ファイルはキャッシュキーに基づいたオブジェクトとしてS3に追加でアップロードされます。したがって、パスが異なる2つのジョブが同じキャッシュキーを持つ場合、キャッシュが上書きされます。
- `cache.zip`からキャッシュを抽出する場合、zipファイルのすべての内容がジョブの作業ディレクトリ（通常はプルダウンされるリポジトリ）に抽出され、Runnerは、`job A`のアーカイブが`job B`のアーカイブの内容を上書きするかどうかを問題としません。

あるRunnerに対して作成されたキャッシュは、別のRunnerで使用される場合は有効でないことが多いため、このように動作します。異なるRunnerは、異なるアーキテクチャで実行される可能性があります（たとえば、キャッシュにバイナリファイルが含まれている場合）。また、異なるステップは、異なるマシンで実行されているRunnerによって実行される可能性があるため、これは安全なデフォルトです。

## キャッシュをクリアする {#clearing-the-cache}

Runnerは[キャッシュ](../yaml/_index.md#cache)を使用して、既存のデータを再利用し、ジョブの実行を高速化します。これにより、一貫性のない動作が発生する場合があります。

キャッシュを新たに始める方法は2つあります。

### `cache:key`を変更してキャッシュをクリアする {#clear-the-cache-by-changing-cachekey}

`.gitlab-ci.yml`ファイルで`cache: key`の値を変更します。次回パイプラインが実行されると、キャッシュは別の場所に保存されます。

### キャッシュを手動でクリアする {#clear-the-cache-manually}

GitLab UIでキャッシュをクリアできます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **ビルド** > **パイプライン**を選択します。
1. 右上隅で、**Runnerキャッシュを削除**を選択します。

次のコミットで、CI/CDジョブは新しいキャッシュを使用します。

{{< alert type="note" >}}

キャッシュを手動でクリアするたびに、[内部キャッシュ名](#where-the-caches-are-stored)が更新されます。名前は`cache-<index>`の形式を使用し、インデックスは1ずつ増分します。古いキャッシュは削除されません。これらのファイルは、Runnerストレージから手動で削除できます。

{{< /alert >}}

## トラブルシューティング {#troubleshooting}

### キャッシュの不一致 {#cache-mismatch}

キャッシュの不一致が発生した場合は、次の手順に従って問題を解決してください。

| キャッシュの不一致の理由 | 修正方法 |
| --------------------------- | ------------- |
| 共有キャッシュを使用せずに、1つのプロジェクトにアタッチされた複数のスタンドアロンRunner（オートスケールモードではない）を使用している。 | プロジェクトにRunnerを1つだけ使用するか、分散キャッシュが有効になっている複数のRunnerを使用します。 |
| 分散キャッシュを有効にせずに、オートスケールモードでRunnerを使用している。 | 分散キャッシュを使用するようにオートスケールRunnerを設定します。 |
| Runnerがインストールされているマシンでディスク容量が不足してる。分散キャッシュを設定している場合は、キャッシュが保存されているS3バケットに十分な容量がない。 | 新しいキャッシュを保存できるように、必ずスペースを空けておいてください。これを自動実行する方法はありません。 |
| 異なるパスをキャッシュするジョブに対して同じ`key`を使用している。 | キャッシュアーカイブが別の場所に保存されるように、かつ間違ったキャッシュを上書きしないように、異なるキャッシュキーを使用します。 |
| [Runnerでの分散Runnerキャッシュ](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching)を有効にしていない。 | `Shared = false`を設定して、Runnerを再プロビジョニングします。 |

#### キャッシュの不一致の例1 {#cache-mismatch-example-1}

プロジェクトに割り当てられているRunnerが1つしかない場合、キャッシュはデフォルトでRunnerのマシンに保存されます。

2つのジョブのキャッシュキーが同じでもパスが異なる場合、キャッシュが上書きされる可能性があります。次に例を示します:

```yaml
stages:
  - build
  - test

job A:
  stage: build
  script: make build
  cache:
    key: same-key
    paths:
      - public/

job B:
  stage: test
  script: make test
  cache:
    key: same-key
    paths:
      - vendor/
```

1. `job A`が実行されます。
1. `public/`は`cache.zip`としてキャッシュされます。
1. `job B`が実行されます。
1. 以前のキャッシュ（もしあれば）は、解凍されます。
1. `vendor/`は`cache.zip`としてキャッシュされ、以前のキャッシュを上書きします。
1. 次回`job A`が実行されるとき、異なる`job B`のキャッシュを使用するため、効果がありません。

この問題を修正するには、ジョブごとに異なる`keys`を使用します。

#### キャッシュの不一致の例2 {#cache-mismatch-example-2}

この例では、プロジェクトに複数のRunnerが割り当てられており、分散キャッシュが有効になっていません。

2回目のパイプラインの実行時に、`job A`と`job B`がそれぞれのキャッシュを再利用するようにしたいとします（この場合は異なります）:

```yaml
stages:
  - build
  - test

job A:
  stage: build
  script: build
  cache:
    key: keyA
    paths:
      - vendor/

job B:
  stage: test
  script: test
  cache:
    key: keyB
    paths:
      - vendor/
```

`key`が異なっていても、後続のパイプラインでジョブが異なるRunnerで実行される場合、キャッシュされたファイルは各ステージの前に「クリーニング」される可能性があります。

### 同時実行Runnerでローカルキャッシュが見つからない {#concurrent-runners-missing-local-cache}

Docker executorを使用して複数の同時実行Runnerを設定している場合、ローカルにキャッシュされたファイルは、同時実行ジョブに期待どおりに存在しない可能性があります。キャッシュボリュームの名前はRunnerインスタンスごとに一意に構築されるため、あるRunnerインスタンスによってキャッシュされたファイルは、別のRunnerインスタンスのキャッシュでは見つかりません。

同時実行Runner間でキャッシュを共有するには、次のいずれかを行います:

- Runnerの`config.toml`の`[runners.docker]`セクションを使用して、ホスト上の単一のマウントポイントを構成し、`volumes = ["/mnt/gitlab-runner/cache-for-all-concurrent-jobs:/cache"]`など、各コンテナの`/cache`にマップします。このアプローチにより、Runnerが同時ジョブの一意のボリューム名を作成することを防ぎます。
- 分散キャッシュを使用します。
