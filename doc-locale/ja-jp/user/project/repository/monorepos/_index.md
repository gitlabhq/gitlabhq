---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: モノレポのパフォーマンスを改善する
---

モノレポは、サブプロジェクトを含むリポジトリです。単一アプリケーションには、相互に依存するプロジェクトが含まれていることがよくあります。たとえば、バックエンド、Webフロントエンド、iOSアプリケーション、Androidアプリケーションなどです。モノレポは一般的ですが、パフォーマンスのリスクを伴う場合があります。一般的な問題は次のとおりです:

- 大規模バイナリファイル。
- 履歴の長い多数のファイル。
- 多数の同時クローンとプッシュ。
- 垂直スケールの制限。
- ネットワーク帯域幅の制限。
- ディスク帯域幅の制限。

GitLab自体はGitベースです。そのGitストレージサービスである[Gitaly](https://gitlab.com/gitlab-org/gitaly)は、モノレポに関連するパフォーマンス上の制約を経験します。私たちが学んだことは、独自のモノレポをより適切に管理するのに役立ちます。

- リポジトリの特性がパフォーマンスに与える影響。
- モノレポを最適化するためのいくつかのツールと手順。

## モノレポ向けGitalyの最適化 {#optimize-gitaly-for-monorepos}

Gitはオブジェクトを[パックファイル](https://git-scm.com/book/en/v2/Git-Internals-Packfiles)に圧縮して、使用するスペースを減らします。クローン、フェッチ、またはプッシュすると、Gitはパックファイルを使用します。これらはディスクスペースとネットワーク帯域幅を削減しますが、パックファイルの作成には多くのCPUとメモリが必要です。

大規模なモノレポは、小規模なリポジトリよりも多くのコミット、ファイル、ブランチ、およびタグを含んでいます。オブジェクトが大きくなり、転送に時間がかかるようになると、パックファイルの作成はより高価になり、遅くなります。Gitでは、[`git-pack-objects`](https://git-scm.com/docs/git-pack-objects)プロセスが最もリソースを大量に消費する操作です。これは、次の理由によります:

1. コミット履歴とファイルを分析します。
1. クライアントに送り返すファイルを決定します。
1. パックファイルを作成します。

`git clone`と`git fetch`からのトラフィックは、サーバー上で`git-pack-objects`プロセスを開始します。GitLab CI/CDのような自動化された継続的インテグレーションシステムは、このトラフィックの多くを引き起こす可能性があります。大量の自動化されたCI/CDのトラフィックは、多数のクローンとフェッチリクエストを送信し、Gitalyサーバーに負担をかける可能性があります。

Gitalyサーバーへの負荷を軽減するには、これらの戦略を使用してください。

### Gitalyの`pack-objects`キャッシュを有効にする {#enable-the-gitaly-pack-objects-cache}

[Gitaly `pack-objects`キャッシュ](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)を有効にすると、クローンとフェッチのサーバー負荷が軽減されます。

Gitクライアントがクローンまたはフェッチリクエストを送信すると、`git-pack-objects`によって生成されたデータは再利用のためにキャッシュできます。モノレポが頻繁にクローンされる場合、[Gitaly `pack-objects`キャッシュ](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)を有効にすると、サーバー負荷が軽減されます。有効にすると、Gitalyは各クローンまたはフェッチ呼び出しの応答データを再生成する代わりに、インメモリキャッシュを維持します。

詳細については、[Pack-objectsキャッシュ](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)を参照してください。

### GitバンドルURIの設定 {#configure-git-bundle-uris}

低レイテンシーのサードパーティストレージに[Gitバンドル](https://git-scm.com/docs/bundle-uri)を作成し、保存します（CDNなど）。Gitは最初にバンドルからパッケージをダウンロードし、次に残りのオブジェクトと参照をGitリモートからフェッチします。このアプローチにより、オブジェクトデータベースの起動が高速化され、Gitalyへの負荷が軽減されます。

- これにより、GitLabサーバーへのネットワーク接続が悪いユーザーのクローンとフェッチが高速化されます。
- CI/CDジョブを実行するサーバーの負荷を、バンドルを事前に読み込むことで軽減します。

詳細については、[Bundle URI](../../../../administration/gitaly/bundle_uris.md)を参照してください。

### Gitalyネゴシエーションのタイムアウトの設定 {#configure-gitaly-negotiation-timeouts}

フェッチまたはリポジトリのアーカイブを試行すると、次の場合に`fatal: the remote end hung up unexpectedly`エラーが発生する可能性があります:

- 大規模なリポジトリ。
- 多数のリポジトリを並行処理。
- 同じ大規模リポジトリを並行処理。

この問題を軽減するには、[デフォルトのネゴシエーションタイムアウト値](../../../../administration/settings/gitaly_timeouts.md#configure-the-negotiation-timeouts)を増やしてください。

### ハードウェアを適切にサイズ設定する {#size-your-hardware-correctly}

モノレポは通常、多くのユーザーを抱える大規模な組織向けです。モノレポをサポートするには、GitLab環境がGitLabテストプラットフォームおよびサポートチームによって提供される[リファレンスアーキテクチャ](../../../../administration/reference_architectures/_index.md)のいずれかに一致する必要があります。これらのアーキテクチャは、パフォーマンスを維持しながらGitLabを大規模にデプロイするための推奨される方法です。

### Git参照の数を減らす {#reduce-the-number-of-git-references}

Gitでは、[参照](https://git-scm.com/book/en/v2/Git-Internals-Git-References)は特定のコミットを指すブランチおよびタグ名です。Gitは参照を、リポジトリの`.git/refs`フォルダーにルーズファイルとして保存します。リポジトリ内のすべての参照を表示するには、`git for-each-ref`を実行します。

リポジトリ内の参照の数が増えると、特定の参照を見つけるのに必要なシーク時間も長くなります。Gitが参照を解析するたびに、シーク時間が増加し、レイテンシーが増大します。

この問題を修正するために、Gitは[pack-refs](https://git-scm.com/docs/git-pack-refs)を使用して、そのリポジトリのすべての参照を含む単一の`.git/packed-refs`ファイルを作成します。この方法は、refsに必要なストレージスペースを削減します。また、単一ファイルでのシークはディレクトリ内のすべてのファイルをシークするよりも高速であるため、シーク時間が短縮されます。

Gitは、新しく作成または更新された参照をルーズファイルで処理します。`git pack-refs`を実行するまで、これらはクリーンアップされて`.git/packed-refs`ファイルに追加されません。Gitalyは[ハウスキーピング](../../../../administration/housekeeping.md#heuristical-housekeeping)中に`git pack-refs`を実行します。これは多くのリポジトリに役立ちますが、書き込み負荷の高いリポジトリには依然として次のパフォーマンス問題があります:

- 参照を作成または更新すると、新しいルーズファイルが作成されます。
- 参照を削除するには、既存の`packed-refs`ファイルを編集して既存の参照を削除する必要があります。

Gitは、フェッチまたはリポジトリをクローンするときに、すべての参照をイテレーションを行うします。サーバーは、各参照の内部グラフ構造をレビュー（「ウォーク」）し、不足しているオブジェクトを見つけてクライアントに送信します。イテレーションおよびウォークプロセスはCPUを大量に消費し、レイテンシーが増加します。このレイテンシーは、アクティビティが多いリポジトリでドミノ効果を引き起こす可能性があります。各操作が遅くなり、各操作が後続の操作を停止させます。

モノレポ内の多数の参照の影響を軽減するには:

- 古いブランチをクリーンアップするための自動化プロセスを作成します。
- 特定の参照をクライアントに表示する必要がない場合は、[`transfer.hideRefs`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-transferhideRefs)設定を使用して非表示にします。Gitalyはサーバー上のGit設定を無視するため、`/etc/gitlab/gitlab.rb`でGitaly設定自体を変更する必要があります:

  ```ruby
  gitaly['configuration'] = {
    # ...
    git: {
      # ...
      config: [
        # ...
        { key: "transfer.hideRefs", value: "refs/namespace_to_hide" },
      ],
    },
  }
  ```

Git 2.42.0以降では、オブジェクトグラフウォークを行う際に、異なるGit操作が非表示の参照をスキップできます。

### リポジトリ最適化タスクのスケジュール {#schedule-repository-optimization-tasks}

Gitリポジトリのオブジェクトデータベースにデータが格納される方法は、時間の経過とともに非効率になり、Git操作が遅くなります。最大実行時間を指定して[Gitalyで日次バックグラウンドタスクをスケジュール](../../../../administration/housekeeping.md#configure-scheduled-housekeeping)することで、これらの項目をクリーンアップし、パフォーマンスを向上させることができます。

## モノレポ向けCI/CDの最適化 {#optimize-cicd-for-monorepos}

GitLabをモノレポと共にスケールする状態に保つには、CI/CDジョブがリポジトリとどのように連携するかを最適化します。大規模で長いパイプラインは、モノレポの一般的な問題点です。モノレポのパイプライン設定で、変更の種類を検出する[ビルドルール](../../../../ci/yaml/_index.md#rules)を使用し、次のことを行います:

- 不要なジョブをスキップします。
- 関連するジョブのみを子パイプラインで実行します。

### CI/CDでの同時クローン数を減らす {#reduce-concurrent-clones-in-cicd}

CI/CDパイプラインの並行処理を、[スケジュールされたパイプラインをずらして](../../../../ci/pipelines/schedules.md#distribute-pipeline-schedules-to-prevent-system-load)異なる時間に実行することで軽減します。数分の違いでも役立ちます。

CI/CDの負荷は、パイプラインが[特定の時間にスケジュールされる](../../../../ci/pipelines/pipeline_efficiency.md#reduce-how-often-jobs-run)ため、多くの場合並行処理されます。これらの時間帯には、リポジトリへのGitリクエストが急増し、CI/CDプロセスとユーザーのパフォーマンスに影響を与える可能性があります。

### CI/CDプロセスでシャロークローンとフィルターを使用する {#use-shallow-clones-and-filters-in-cicd-processes}

CI/CDシステムでの`git clone`および`git fetch`の呼び出しでは、これらのオプションで転送されるデータ量を制限できます:

- [`--depth`](https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt)
- [`--filter`](https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---filterfilter-spec)

#### CI/CDでのシャロークローン {#shallow-clone-in-cicd}

`--depth`フィルターは、いわゆる_シャロークローン_を作成します。GitLabとGitLab Runnerは、デフォルトで[シャロークローン](../../../../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone)を実行します。

クローン深度は、`GIT_DEPTH`を使用してGitLab CI/CDパイプライン設定で構成できます。例:

```yaml
variables:
  GIT_DEPTH: 10

test:
  script:
    - ls -al
```

#### CI/CDでの部分クローン {#partial-clone-in-cicd}

`--filter`オプションを使用すると、_部分クローン_を作成できます。この引数を`git-clone`に渡すには、`GIT_CLONE_EXTRA_FLAGS`変数を設定します。たとえば、blobの最大サイズを1MBに制限するには、次を追加します:

```yaml
variables:
  GIT_CLONE_EXTRA_FLAGS: --filter=blob:limit=1m
```

### パスとオブジェクトの種類をフィルターで除外する {#filter-out-paths-and-object-types}

特定のタイプまたは特定のパスのオブジェクトをフィルターで除外するには、`git sparse-checkout`オプションを使用します。詳細については、[ファイルパスでフィルター](../../../../topics/git/clone.md#filter-by-file-path)を参照してください。

### CI/CD操作で`git fetch`を使用する {#use-git-fetch-in-cicd-operations}

リポジトリの実行コピーを維持できる場合は、CI/CDシステムで`git clone`の代わりに`git fetch`を使用してください。`git fetch`はサーバーからの作業が少なくて済みます:

- `git clone`はリポジトリ全体を最初からリクエストします。`git-pack-objects`はすべてのブランチとタグを処理して送信する必要があります。
- `git fetch`は、リポジトリに不足しているGit参照のみをリクエストします。`git-pack-objects`は、Git参照の合計のうち、サブセットのみを処理します。この戦略は、転送される総データ量も削減します。

デフォルトでは、GitLabは大規模なリポジトリに推奨される[`fetch` Git戦略](../../../../ci/runners/configure_runners.md#git-strategy)を使用します。

### `git clone`パスを設定する {#set-a-git-clone-path}

モノレポがフォークベースのワークフローで使用される場合、[`GIT_CLONE_PATH`](../../../../ci/runners/configure_runners.md#custom-build-directories)を設定してリポジトリをクローンする場所を制御することを検討してください。

Gitはフォークを、別個のリポジトリとして別個のワークツリーで保存します。GitLab Runnerはワークツリーの使用を最適化できません。GitLab Runnerのexecutorは、指定されたプロジェクトに対してのみ設定および使用してください。プロセスをより効率的にするために、異なるプロジェクト間で共有しないでください。

[`GIT_CLONE_PATH`](../../../../ci/runners/configure_runners.md#custom-build-directories)は`$CI_BUILDS_DIR`で設定されたディレクトリ内にある必要があります。ディスクから任意のパスを選択することはできません。

### CI/CDジョブでの`git clean`を無効にする {#disable-git-clean-on-cicd-jobs}

`git clean`コマンドは、ワークツリーから追跡されていないファイルを削除します。大規模なリポジトリでは、大量のディスクI/Oを使用します。既存のマシンを再利用し、既存のワークツリーを再利用できる場合は、CI/CDジョブでこれを無効にすることを検討してください。たとえば、`GIT_CLEAN_FLAGS: -ffdx -e .build/`を使用すると、実行間でワークツリーからディレクトリを削除することを回避できます。これにより、増分ビルドが高速化される可能性があります。

CI/CDジョブで`git clean`を無効にするには、[`GIT_CLEAN_FLAGS`](../../../../ci/runners/configure_runners.md#git-clean-flags)を`none`に設定します。

デフォルトでは、GitLabは以下を保証します:

- 指定されたSHAにワークツリーがあります。
- リポジトリがクリーンです。

`GIT_CLEAN_FLAGS`が受け入れる正確なパラメータについては、[`git clean`](https://git-scm.com/docs/git-clean)のGitドキュメントを参照してください。使用可能なパラメータは、Gitのバージョンによって異なります。

### `git fetch`の動作をフラグで変更する {#change-git-fetch-behavior-with-flags}

`git fetch`の動作を変更して、CI/CDジョブが不要なデータを除外するようにします。プロジェクトに多数のタグが含まれており、CI/CDジョブでこれらが不要な場合は、`GIT_FETCH_EXTRA_FLAGS`を使用して[`--no-tags`](https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---no-tags)を設定します。この設定により、フェッチをより高速かつコンパクトにできます。

リポジトリに多くのタグが含まれていなくても、`--no-tags`がパフォーマンスを向上させる場合があります。詳細については、[イシュー746](https://gitlab.com/gitlab-com/gl-infra/observability/team/-/issues/746)および[`GIT_FETCH_EXTRA_FLAGS` Gitドキュメント](../../../../ci/runners/configure_runners.md#git-fetch-extra-flags)を参照してください。

### Runnerにロングポーリングを使用する {#use-long-polling-for-runners}

Runnerは、新しいCI/CDジョブのためにGitLabインスタンスを定期的にポーリングします。ポーリングの間隔は、次の両方に依存します:

- `check_interval`設定。
- Runner設定ファイルで構成されたRunnerの数。

サーバーが多数のRunnerを処理する場合、このポーリングは、キューイング時間の延長やCPU使用率の増加など、GitLabインスタンスのパフォーマンス問題を引き起こす可能性があります。ロングポーリングは、新しいジョブの準備が整うまで、Runnerからのジョブリクエストを保持します。

設定手順については、[ロングポーリング](../../../../ci/runners/long_polling.md)を参照してください。

## モノレポ向けGitの最適化 {#optimize-git-for-monorepos}

GitLabをモノレポと共にスケールする状態に保つには、リポジトリ自体を最適化します。

### 開発でのシャロークローンを避ける {#avoid-shallow-clones-for-development}

開発でのシャロークローンは避けてください。シャロークローンは、変更をプッシュするのに必要な時間を大幅に増やします。シャロークローンはCI/CDジョブとうまく連携します。これは、リポジトリのコンテンツがチェックアウト後に変更されないためです。

ローカル開発では、代わりに[部分クローン](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---filterltfilter-specgt)を使用して、次のことを行います:

- blobをフィルターで除外する（`git clone --filter=blob:none`を使用）。
- ツリーをフィルターで除外する（`git clone --filter=tree:0`を使用）。

詳細については、[クローンサイズの削減](../../../../topics/git/clone.md#reduce-clone-size)を参照してください。

### リポジトリをプロファイルして問題を見つける {#profile-your-repository-to-find-problems}

大規模なリポジトリは、一般的にGitでパフォーマンスの問題を経験します。[`git-sizer`](https://github.com/github/git-sizer)プロジェクトはリポジトリをプロファイルし、潜在的な問題を理解するのに役立ちます。これは、パフォーマンス問題を防ぐための軽減戦略を開発するのに役立ちます。リポジトリを分析するには、すべてのGit参照が存在することを確認するために、完全なGitミラーまたはベアクローンが必要です。

`git-sizer`を使用してリポジトリをプロファイルするには:

1. [`git-sizer`](https://github.com/github/git-sizer?tab=readme-ov-file#getting-started)をインストールします。
1. `git-sizer`と互換性のあるベアGit形式でリポジトリをクローンするには、このコマンドを実行します:

   ```shell
   git clone --mirror <git_repo_url>
   ```

1. Gitリポジトリのディレクトリで、すべての統計情報とともに`git-sizer`を実行します:

   ```shell
   git-sizer -v
   ```

処理後、`git-sizer`の出力はこの例のようになります。各行には、リポジトリのその側面に対する**Level of concern**が含まれます。懸念レベルが高いほど、より多くのアスタリスクで表示されます。極めて懸念レベルが高い項目には、感嘆符が表示されます。この例では、いくつかの項目に高い懸念レベルがあります:

```shell
Processing blobs: 1652370
Processing trees: 3396199
Processing commits: 722647
Matching commits to trees: 722647
Processing annotated tags: 534
Processing references: 539
| Name                         | Value     | Level of concern               |
| ---------------------------- | --------- | ------------------------------ |
| Overall repository size      |           |                                |
| * Commits                    |           |                                |
|   * Count                    |   723 k   | *                              |
|   * Total size               |   525 MiB | **                             |
| * Trees                      |           |                                |
|   * Count                    |  3.40 M   | **                             |
|   * Total size               |  9.00 GiB | ****                           |
|   * Total tree entries       |   264 M   | *****                          |
| * Blobs                      |           |                                |
|   * Count                    |  1.65 M   | *                              |
|   * Total size               |  55.8 GiB | *****                          |
| * Annotated tags             |           |                                |
|   * Count                    |   534     |                                |
| * References                 |           |                                |
|   * Count                    |   539     |                                |
|                              |           |                                |
| Biggest objects              |           |                                |
| * Commits                    |           |                                |
|   * Maximum size         [1] |  72.7 KiB | *                              |
|   * Maximum parents      [2] |    66     | ******                         |
| * Trees                      |           |                                |
|   * Maximum entries      [3] |  1.68 k   | *                              |
| * Blobs                      |           |                                |
|   * Maximum size         [4] |  13.5 MiB | *                              |
|                              |           |                                |
| History structure            |           |                                |
| * Maximum history depth      |   136 k   |                                |
| * Maximum tag depth      [5] |     1     |                                |
|                              |           |                                |
| Biggest checkouts            |           |                                |
| * Number of directories  [6] |  4.38 k   | **                             |
| * Maximum path depth     [7] |    13     | *                              |
| * Maximum path length    [8] |   134 B   | *                              |
| * Number of files        [9] |  62.3 k   | *                              |
| * Total size of files    [9] |   747 MiB |                                |
| * Number of symlinks    [10] |    40     |                                |
| * Number of submodules       |     0     |                                |
```

### 大規模バイナリファイルにGit LFSを使用する {#use-git-lfs-for-large-binary-files}

バイナリファイル（パッケージ、オーディオ、ビデオ、グラフィックスなど）をGit Large File Storage（LFS）オブジェクトとして保存します。

ユーザーがファイルをGitにコミットすると、Gitはblob [object type](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects)を使用してそのコンテンツを保存および管理します。Gitは大規模なバイナリデータを効率的に処理しないため、大規模なblobはGitにとって問題となります。`git-sizer`が10MBを超えるblobを報告する場合、通常、リポジトリには大規模なバイナリファイルがあります。大規模なバイナリファイルは、サーバーとクライアントの両方に問題を引き起こします:

- サーバーの場合: テキストベースのソースコードとは異なり、バイナリデータは多くの場合、すでに圧縮されています。Gitはバイナリデータをこれ以上圧縮できないため、大規模なパックファイルにつながります。大規模なパックファイルは、作成と送信により多くのCPU、メモリ、帯域幅を必要とします。
- クライアントの場合: Gitはblobコンテンツをパックファイル（通常は`.git/objects/pack/`内）と通常のファイル（[ワークツリー](https://git-scm.com/docs/git-worktree)内）の両方に保存しますが、バイナリファイルはテキストベースのソースコードよりもはるかに多くのスペースを必要とします。

Git LFSは、オブジェクトストレージなどの外部にオブジェクトを保存します。Gitリポジトリには、バイナリファイル自体ではなく、オブジェクトの場所へのポインターが含まれています。これにより、リポジトリのパフォーマンスを向上させることができます。詳細については、[Git LFSドキュメント](../../../../topics/git/lfs/_index.md)を参照してください。

## 関連トピック {#related-topics}

- [Gitalyを設定する](../../../../administration/gitaly/configure_gitaly.md)
