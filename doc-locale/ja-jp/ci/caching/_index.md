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

キャッシュキーの高度な戦略として、以下を使用できます:

- [`cache:key:files`](../yaml/_index.md#cachekeyfiles): 特定のファイルのコンテンツにリンクされたキーを生成します。
- [`cache:key:files_commits`](../yaml/_index.md#cachekeyfiles_commits): 特定のファイルの最新のコミットにリンクされたキーを生成します。

その他のユースケースと例については、[CI/CD caching examples](examples.md)を参照してください。

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

キャッシュの可用性を最大限に高めるには、次の1つ以上を行います。

- [Runnerにタグを付け](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)、キャッシュを共有するジョブでそのタグを使用する。
- [特定のプロジェクトでのみ利用可能なRunnerを使用する](../runners/runners_scope.md#prevent-a-project-runner-from-being-enabled-for-other-projects)。
- ワークフローに合った[`key`を使用する](../yaml/_index.md#cachekey)。たとえば、ブランチごとに異なるキャッシュを設定できます。

Runnerがキャッシュと効率的に連携できるようにするには、次のいずれかを実行する必要があります。

- すべてのジョブに単一のRunnerを使用する。
- [分散キャッシュ](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching)を持つ複数のRunnerを使用する。この場合、キャッシュはS3バケットに保存されます。GitLab.comのインスタンスRunnerは、この方法で動作します。これらのRunnerはオートスケールモードにできますが、そうである必要はありません。キャッシュオブジェクトを管理するには、ライフサイクルルールを適用して、一定期間後にキャッシュオブジェクトを削除します。ライフサイクルルールは、オブジェクトストレージサーバーで利用できます。
- 同じアーキテクチャを持つ複数のRunnerを使用し、これらのRunnerが共通のネットワークマウントされたディレクトリを共有してキャッシュを保存するようにする。このディレクトリは、NFSまたは同様のものを使用する必要があります。これらのRunnerはオートスケールモードである必要があります。

## 複数のキャッシュを使用する {#use-multiple-caches}

ジョブごとに最大4つのキャッシュを持つことができます:

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

各キャッシュエントリは、[`fallback_keys`キーワード](../yaml/_index.md#cachefallback_keys)で最大5つのフォールバックキーをサポートします。ジョブがキャッシュキーを見つけられない場合、ジョブは代わりにフォールバックキャッシュの取得を試みます。キャッシュが見つかるまで、フォールバックキーが順番に検索されます。キャッシュが見つからない場合、ジョブはキャッシュを使用せずに実行されます。例: 

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

この例では:

1. ジョブは`cache-$CI_COMMIT_REF_SLUG`キャッシュを探します。
1. `cache-$CI_COMMIT_REF_SLUG`が見つからない場合、ジョブはフォールバックオプションとして`cache-$CI_DEFAULT_BRANCH`を探します。
1. `cache-$CI_DEFAULT_BRANCH`も見つからない場合、ジョブは2番目のフォールバックオプションとして`cache-default`を探します。
1. いずれも見つからない場合、ジョブはキャッシュを使用せずにすべてのRuby依存関係をダウンロードしますが、ジョブが完了すると`cache-$CI_COMMIT_REF_SLUG`の新しいキャッシュを作成します。

フォールバックキーは、`cache:key`と同じ処理ロジックに従います。

- [キャッシュを手動でクリア](#clear-the-cache-manually)すると、キャッシュごとのフォールバックキーには、他のキャッシュキーと同じようにインデックスが付加されます。
- [**保護ブランチに個別のキャッシュを使用する**設定](#cache-key-names)が有効になっている場合、キャッシュごとのフォールバックキーには`-protected`または`-non_protected`が付加されます。

### グローバルフ​​ォールバックキー {#global-fallback-key}

[定義済み変数](../variables/predefined_variables.md)`$CI_COMMIT_REF_SLUG`を使用すれば、自分の[`cache:key`](../yaml/_index.md#cachekey)を指定できます。たとえば、`$CI_COMMIT_REF_SLUG`が`test`の場合、`test`でタグ付けされたキャッシュをダウンロードするようにジョブを設定できます。

このタグが付いたキャッシュが見つからない場合は、`CACHE_FALLBACK_KEY`を使用して、そのキャッシュが存在しない場合に使用するキャッシュを指定できます。

次の例では、`$CI_COMMIT_REF_SLUG`が見つからない場合、ジョブは`CACHE_FALLBACK_KEY`変数で定義されたキーを使用します。

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

キャッシュ抽出の順序は次のとおりです。

1. `cache:key`を取得試行する
1. `fallback_keys`の各エントリを順番に取得試行する
1. `CACHE_FALLBACK_KEY`のグローバルフ​​ォールバックキーを取得試行する

最初のキャッシュが正常に取得された後、キャッシュ抽出プロセスは停止します。

## 特定のジョブのキャッシュを無効にする {#disable-cache-for-specific-jobs}

キャッシュをグローバルに定義すると、どのジョブも同じ定義を使用するようになります。ジョブごとにこの動作をオーバーライドできます。

ジョブに対してキャッシュを完全に無効にするには、次のように空のリストを使用します。

```yaml
job:
  cache: []
```

## グローバル設定を継承するが、ジョブごとに特定の設定をオーバーライドする {#inherit-global-configuration-but-override-specific-settings-per-job}

[アンカー](../yaml/yaml_optimization.md#anchors)を使用すると、グローバルキャッシュを上書きせずにキャッシュ設定をオーバーライドできます。たとえば、1つのジョブの`policy`をオーバーライドする場合、次のようになります。

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

## キャッシュキー名 {#cache-key-names}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/330047)されました。
- GitLab 18.4.5で、メンテナーロール以上の`-protected`サフィックスが[導入されました](https://about.gitlab.com/releases/2025/11/26/patch-release-gitlab-18-6-1-released/)。

{{< /history >}}

[グローバルフ​​ォールバックキャッシュキー](#global-fallback-key)を除き、サフィックスがキャッシュキーに追加されます。

パイプラインが以下の場合、キャッシュキーには`-protected`サフィックスが付きます:

- 保護ブランチまたはタグに対して実行されます。ユーザーは、[保護されたブランチ](../../user/project/repository/branches/protected.md)にマージする権限、または[保護されたタグ](../../user/project/protected_tags.md)を作成する権限を持っている必要があります。
- 少なくともメンテナーロールを持つユーザーによって開始されました。

他のパイプラインで生成されたキーには、`non_protected`サフィックスが付きます。

次に例を示します:

- `cache:key`が`$CI_COMMIT_REF_SLUG`に設定されます。
- `main`保護ブランチです。
- `feature`は保護されていないブランチです。

| ブランチ      | デベロッパーロールのキャッシュキー | メンテナーロールのキャッシュキー |
|-------------|--------------------------|---------------------------|
| `main`      | `main-protected`         | `main-protected`          |
| `feature`   | `feature-non_protected`  | `feature-protected`       |

さらに、タグのパイプラインの場合、パイプラインが実行されるブランチではなく、タグの保護ステータスがサフィックスよりも優先されます。この動作により、トリガー参照がキャッシュアクセス権を決定するため、一貫したセキュリティ境界が保証されます。

次に例を示します:

- `cache:key`が`$CI_COMMIT_TAG`に設定されます。
- `main`保護ブランチです。
- `feature`は保護されていないブランチです。
- `1.0.0`は保護されたタグです。
- `1.1.1-rc1`は保護されていないタグです。

| タグ         | ブランチ    | デベロッパーロールのキャッシュキー  | メンテナーロールのキャッシュキー |
|-------------|-----------|---------------------------|---------------------------|
| `1.0.0`     | `main`    | `1.0.0-protected`         | `1.0.0-protected`         |
| `1.0.0`     | `feature` | `1.0.0-protected`         | `1.0.0-protected`         |
| `1.1.1-rc1` | `main`    | `1.1.1-rc1-non_protected` | `1.1.1-rc1-protected`     |
| `1.1.1-rc1` | `feature` | `1.1.1-rc1-non_protected` | `1.1.1-rc1-protected`     |

### すべてのブランチで同じキャッシュを使用する {#use-the-same-cache-for-all-branches}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/361643)されました。

{{< /history >}}

[キャッシュキー名](#cache-key-names)を使用しない場合は、すべてのブランチ（保護ブランチと保護されていないブランチ）で同じキャッシュを使用できます。

[キャッシュキー名](#cache-key-names)を使用したキャッシュの分離はセキュリティ機能であり、この機能を無効にできるのは、デベロッパーロールを付与されているすべてのユーザーの信頼性が極めて高い環境のみです。

すべてのブランチで同じキャッシュを使用するには、次のようにします。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **一般パイプライン**を展開します。
1. **保護ブランチに別のキャッシュを使用する**チェックボックスをオフにします。
1. **変更を保存**を選択します。

## キャッシュの可用性 {#availability-of-the-cache}

キャッシュの目的は最適化ですが、常に機能することが保証されているわけではありません。場合によっては、キャッシュが必要な各ジョブでキャッシュされたファイルを再生成する必要があります。

[`.gitlab-ci.yml`でキャッシュを定義](../yaml/_index.md#cache)した後、キャッシュの可用性は次の要素に左右されます。

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

### アーカイブと抽出の仕組み {#how-archiving-and-extracting-works}

次の例は、2つの連続するステージでの2つのジョブを示しています。

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

1台のマシンに1つのRunnerがインストールされている場合、プロジェクトのすべてのジョブが同じホスト上で実行されます。

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

キャッシュプロセス中には、考慮すべき点がいくつかあります。

- 別のキャッシュ設定がある別のジョブが同じzipファイルにキャッシュを保存した場合、キャッシュが上書きされます。S3ベースの共有キャッシュが使用される場合、ファイルはキャッシュキーに基づいたオブジェクトとしてS3に追加でアップロードされます。したがって、パスが異なる2つのジョブが同じキャッシュキーを持つ場合、キャッシュが上書きされます。
- `cache.zip`からキャッシュを抽出する場合、zipファイルのすべての内容がジョブの作業ディレクトリ（通常はプルダウンされるリポジトリ）に抽出され、Runnerは、`job A`のアーカイブが`job B`のアーカイブの内容を上書きするかどうかを問題としません。

あるRunnerに対して作成されたキャッシュは、別のRunnerで使用される場合は有効でないことが多いため、このように動作します。異なるRunnerは、異なるアーキテクチャで実行される可能性があります（たとえば、キャッシュにバイナリファイルが含まれている場合）。また、異なるステップは、異なるマシンで実行されているRunnerによって実行される可能性があるため、これは安全なデフォルトです。

## キャッシュをクリアする {#clearing-the-cache}

Runnerは[キャッシュ](../yaml/_index.md#cache)を使用して、既存のデータを再利用し、ジョブの実行を高速化します。これにより、一貫性のない動作が発生する場合があります。

キャッシュを新たに始める方法は2つあります。

### `cache:key`を変更してキャッシュをクリアする {#clear-the-cache-by-changing-cachekey}

`.gitlab-ci.yml`ファイルで`cache: key`の値を変更します。次回パイプラインが実行されると、キャッシュは別の場所に保存されます。

### キャッシュを手動でクリアする {#clear-the-cache-manually}

GitLab UIでキャッシュをクリアできます。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **パイプライン**を選択します。
1. 右上隅で、**Runnerキャッシュを削除**を選択します。

次のコミットで、CI/CDジョブは新しいキャッシュを使用します。

> [!note]キャッシュを手動でクリアするたびに、[内部キャッシュ名](#where-the-caches-are-stored)が更新されます。名前は`cache-<index>`の形式を使用し、インデックスは1ずつ増分します。古いキャッシュは削除されません。これらのファイルは、Runnerストレージから手動で削除できます。

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

2つのジョブのキャッシュキーが同じでもパスが異なる場合、キャッシュが上書きされる可能性があります。例: 

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

2回目のパイプラインの実行時に、`job A`と`job B`がそれぞれのキャッシュを再利用するようにしたいとします（この場合は異なります）。

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

同時実行Runner間でキャッシュを共有するには、次のいずれかを行います。

- `[runners.docker]`の`config.toml`セクションを使用して、ホスト上の単一のマウントポイントを構成し、`volumes = ["/mnt/gitlab-runner/cache-for-all-concurrent-jobs:/cache"]`など、各コンテナ内の`/cache`にマップします。この方法では、Runnerが同時ジョブの一意のボリューム名を作成できなくなります。
- 分散キャッシュを使用します。
