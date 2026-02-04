---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDキャッシュの例
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ジョブの実行時に毎回依存関係とビルドアーティファクトをダウンロードしなくても済むように、キャッシュを使用してください。キャッシュを使用すると、以前にダウンロードしたコンテンツが再利用されるため、CI/CDパイプラインが高速化されます。

その他の例については、[GitLab CI/CD templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)を参照してください。

## キャッシュの戦略 {#cache-strategies}

これらの例では、ジョブとブランチ間でキャッシュを共有するためのさまざまな方法を示します。

### 同じブランチ内のジョブ間でキャッシュを共有する {#share-caches-between-jobs-in-the-same-branch}

各ブランチのジョブで同じキャッシュを使用するには、`key: $CI_COMMIT_REF_SLUG`を使用してキャッシュを定義します。

```yaml
cache:
  key: $CI_COMMIT_REF_SLUG
```

この設定により、キャッシュを誤って上書きすることを防ぐことができます。ただし、マージリクエストの最初のパイプラインは遅くなります。次回コミットがブランチにプッシュされると、キャッシュが再利用され、ジョブがより速く実行されます。

次のコマンドで、ジョブごとおよびブランチごとにキャッシュを有効にできます。

```yaml
cache:
  key: "$CI_JOB_NAME-$CI_COMMIT_REF_SLUG"
```

次のコマンドで、ステージごとおよびブランチごとにキャッシュを有効にできます。

```yaml
cache:
  key: "$CI_JOB_STAGE-$CI_COMMIT_REF_SLUG"
```

### 異なるブランチのジョブ間でキャッシュを共有する {#share-caches-across-jobs-in-different-branches}

すべてのブランチとすべてのジョブでキャッシュを共有するには、すべてに同じキーを使用します。

```yaml
cache:
  key: one-key-to-rule-them-all
```

ブランチ間でキャッシュを共有しつつ、ジョブごとにキャッシュが一意になるようにするには、次のようにします。

```yaml
cache:
  key: $CI_JOB_NAME
```

### 変数を使用してジョブのキャッシュポリシーを制御する {#use-a-variable-to-control-a-jobs-cache-policy}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/371480)されました。

{{< /history >}}

プルポリシーだけが異なるジョブの重複を減らすには、[CI/CD変数](../variables/_index.md)を使用します。

例: 

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

この例では、ジョブのキャッシュポリシーは次のとおりです。

- デフォルトブランチへの変更の場合: `pull-push`
- 他のブランチへの変更の場合: `pull`

## キャッシュの依存関係 {#cache-dependencies}

これらの例では、一般的な依存関係をプログラミング言語別にキャッシュする方法を示します。

### Node.js {#nodejs}

プロジェクトで[npm](https://www.npmjs.com/)を使用してNode.jsの依存関係をインストールする場合、次の例では、すべてのジョブがそれを継承するようにデフォルトの`cache`を定義します。デフォルトでは、npmはホームフォルダー（`~/.npm`）にキャッシュデータを保存します。ただし、[プロジェクトディレクトリの外にあるものをキャッシュすることはできません](../yaml/_index.md#cachepaths)。代わりに、`./.npm`を使用するようにnpmに指示し、次のように、ブランチごとにキャッシュします。

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

#### オフラインミラーでのYarn {#yarn-with-offline-mirror}

[Yarn](https://yarnpkg.com/)を使用している場合は、[`yarn-offline-mirror`](https://classic.yarnpkg.com/blog/2016/11/24/offline-mirror/)を使用して、zip形式の`node_modules` tarballをキャッシュできます。圧縮する必要のあるファイルが少ないため、キャッシュの生成がより迅速になります。

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

### PHP {#php}

プロジェクトで[Composer](https://getcomposer.org/)を使用してPHPの依存関係をインストールする場合、次の例では、デフォルトの`cache`を定義し、すべてのジョブがその依存関係を継承するようにします。PHPライブラリモジュールは`vendor/`にインストールされ、ブランチごとにキャッシュされます。

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

### Python {#python}

プロジェクトで[pip](https://pip.pypa.io/en/stable/)を使用してPythonの依存関係をインストールする場合、次の例では、デフォルトの`cache`を定義し、すべてのジョブがその依存関係を継承するようにします。pipのキャッシュは`.cache/pip/`の下に定義され、ブランチごとにキャッシュされます。

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

### Ruby {#ruby}

プロジェクトで[Bundler](https://bundler.io)を使用してgemの依存関係をインストールする場合、次の例では、デフォルトの`cache`を定義し、すべてのジョブがその依存関係を継承するようにします。gemは`vendor/ruby/`にインストールされ、ブランチごとにキャッシュされます。

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

たとえば、テストジョブでは、本番環境にデプロイするジョブと同じgemが必要ない場合があります。

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

### Go {#go}

プロジェクトで[Goモジュール](https://go.dev/wiki/Modules)を使用してGoの依存関係をインストールする場合、次の例では、すべてのジョブが拡張できる`go-cache`テンプレートで`cache`を定義します。Goモジュールは`${GOPATH}/pkg/mod/`にインストールされ、`go`プロジェクトのすべてに対してキャッシュされます。

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

## ビルドアーティファクトとダウンロードをキャッシュする {#cache-build-artifacts-and-downloads}

これらの例では、コンパイルされたオブジェクトとダウンロードされたファイルをキャッシュして、ビルドを高速化する方法を示します。

### Ccacheを使用してC/C++コンパイルをキャッシュする {#cache-cc-compilation-using-ccache}

C/C++プロジェクトをコンパイルする場合、[Ccache](https://ccache.dev/)を使用してビルド時間を短縮できます。Ccacheは、以前のコンパイルをキャッシュし、同じコンパイルがいつ再度実行されるかを検出することで、再コンパイルをスピードアップします。Linuxカーネルのような大規模なプロジェクトをビルドするときに、コンパイルが大幅にスピードアップすることが期待できます。

`cache`を使用して、作成されたキャッシュをジョブ間で再利用します。次に例を示します。

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

### cURLでダウンロードをキャッシュする {#cache-downloads-with-curl}

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
