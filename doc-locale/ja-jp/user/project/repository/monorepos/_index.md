---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: モノレポのパフォーマンス改善
---

モノレポとは、サブプロジェクトを含むリポジトリです。単一アプリケーションには、相互に依存するプロジェクトが含まれていることがよくあります。たとえば、バックエンド、ウェブフロントエンド、iOSアプリケーション、Androidアプリケーションなどがあります。モノレポは一般的ですが、パフォーマンス上のリスクをもたらす可能性があります。一般的な問題点:

- 大規模なバイナリファイル。
- 長い履歴を持つ多数のファイル。
- 多数の同時クローンとプッシュ。
- 垂直方向のスケール制限。
- ネットワーク帯域幅の制限。
- ディスク帯域幅の制限。

GitLab自体がGitに基づいています。Gitストレージサービスである[Gitaly](https://gitlab.com/gitlab-org/gitaly)は、モノレポに関連するパフォーマンス上の制約を受けます。私たちが学んだことは、あなた自身のモノレポをより良く管理するのに役立ちます。

- パフォーマンスに影響を与える可能性のあるリポジトリの特性。
- モノレポを最適化するためのツールと手順。

## モノレポ用にGitalyを最適化する {#optimize-gitaly-for-monorepos}

Gitは、使用するスペースを削減するために、オブジェクトを[パックファイル](https://git-scm.com/book/en/v2/Git-Internals-Packfiles)に圧縮します。チェックアウト、フェッチ、またはプッシュすると、Gitはパックファイルを使用します。これらは、ディスクスペースとネットワーク帯域幅を削減しますが、パックファイルの作成には多くのCPUとメモリが必要です。

大規模なモノレポは、小規模なリポジトリよりも、より多くのコミット、ファイル、ブランチ、およびタグを持ちます。オブジェクトが大きくなり、転送に時間がかかるようになると、パックファイルの作成はよりコストがかかり、遅くなります。Gitでは、[`git-pack-objects`](https://git-scm.com/docs/git-pack-objects)プロセスは、以下の理由から最もリソースを消費する操作です:

1. コミットの履歴とファイルを解析します。
1. クライアントに送り返すファイルを決定します。
1. パックファイルを作成します。

`git clone`および`git fetch`からのトラフィックは、サーバー上で`git-pack-objects`プロセスを開始します。GitLab CI/CDのような自動化された継続的インテグレーションシステムは、このトラフィックの多くを引き起こす可能性があります。大量の自動化されたCI/CDトラフィックは、多数のクローンとフェッチリクエストを送信し、Gitalyサーバーに負荷をかける可能性があります。

これらの戦略を使用して、Gitalyサーバーの負荷を軽減します。

### Gitaly `pack-objects`キャッシュを有効にする {#enable-the-gitaly-pack-objects-cache}

[Gitaly `pack-objects`キャッシュ](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)を有効にすると、クローンとフェッチのサーバー負荷が軽減されます。

Gitクライアントがクローンまたはフェッチリクエストを送信すると、`git-pack-objects`によって生成されたデータをキャッシュして再利用できます。モノレポが頻繁にクローンされる場合は、[Gitaly `pack-objects`キャッシュ](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)を有効にすると、サーバーの負荷が軽減されます。有効にすると、Gitalyは、クローンまたはフェッチの呼び出しごとに応答データを再生成する代わりに、インメモリキャッシュを維持します。

詳細については、[パックオブジェクトキャッシュ](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)を参照してください。

### GitバンドルURIを構成する {#configure-git-bundle-uris}

レイテンシーの低いサードパーティストレージ（CDNなど）に[Gitバンドル](https://git-scm.com/docs/bundle-uri)を作成して保存します。Gitは、まずバンドルからパッケージをダウンロードし、次に残りのオブジェクトと参照をGitリモートからフェッチします。このアプローチは、オブジェクトデータベースをより高速にブートストラップし、Gitalyの負荷を軽減します。

- GitLabサーバーへのネットワーキング接続が悪いユーザーのために、クローンとフェッチを高速化します。
- 事前にバンドルを読み込むことにより、CI/CDジョブを実行するサーバーの負荷を軽減します。

詳細については、[バンドルURI](../../../../administration/gitaly/bundle_uris.md)を参照してください。

### Gitalyネゴシエーションタイムアウトを構成する {#configure-gitaly-negotiation-timeouts}

フェッチまたはアーカイブリポジトリを試みるとき、次の場合は、`fatal: the remote end hung up unexpectedly`エラーが発生する可能性があります:

- 大規模なリポジトリ。
- 多数のリポジトリを並行して実行。
- 同じ大規模なリポジトリを並行して実行。

この問題を軽減するには、[デフォルトネゴシエーションタイムアウト値](../../../../administration/settings/gitaly_timeouts.md#configure-the-negotiation-timeouts)を大きくします。

### ハードウェアのサイズを正しく設定する {#size-your-hardware-correctly}

モノレポは通常、多数のユーザーがいる大規模な組織向けです。モノレポをサポートするために、GitLab環境は、GitLabテストプラットフォームおよびサポートチームが提供する[参照アーキテクチャ](../../../../administration/reference_architectures/_index.md)のいずれかに一致する必要があります。これらのアーキテクチャは、パフォーマンスを維持しながら、GitLabをスケールしてデプロイするための推奨される方法です。

### Git参照の数を減らす {#reduce-the-number-of-git-references}

Gitでは、[参照](https://git-scm.com/book/en/v2/Git-Internals-Git-References)は、特定のコミットを指すブランチ名とタグ名です。Gitは、リポジトリの`.git/refs`フォルダーに参照をルーズファイルとして保存します。リポジトリ内のすべての参照を表示するには、`git for-each-ref`を実行します。

リポジトリ内の参照の数が増えると、特定の参照を見つけるのに必要なシーク時間も長くなります。Gitが参照を解析するたびに、シーク時間が増加すると、レイテンシーが増加します。

この問題を修正するために、Gitは[pack-refs](https://git-scm.com/docs/git-pack-refs)を使用して、そのリポジトリのすべての参照を含む単一の`.git/packed-refs`ファイルを作成します。このメソッドは、refsに必要なストレージスペースを削減します。また、1つのファイルでシークする方がディレクトリ内のすべてのファイルをシークするよりも速いため、シーク時間も短縮されます。

Gitは、新しく作成または更新された参照をルーズファイルで処理します。`git pack-refs`を実行するまで、`.git/packed-refs`ファイルにクリーンアップして追加されません。Gitalyは、[ハウスキーピング](../../../../administration/housekeeping.md#heuristical-housekeeping)中に`git pack-refs`を実行します。これは多くのリポジトリに役立ちますが、書き込み負荷の高いリポジトリには、依然として次のパフォーマンスの問題があります:

- 参照を作成または更新すると、新しいルーズファイルが作成されます。
- 参照を削除するには、既存の`packed-refs`ファイルを編集して、既存の参照を削除する必要があります。

Gitは、リポジトリをフェッチまたはクローンすると、すべての参照をイテレーションします。サーバーは、各参照の内部グラフ構造をレビュー（「ウォーク」）し、不足しているオブジェクトを見つけて、クライアントに送信します。イテレーション処理とウォーク処理はCPUを大量に消費し、レイテンシーが増加します。このレイテンシーにより、アクティビティーの多いリポジトリでドミノ効果が発生する可能性があります。各操作が遅くなり、各操作で後続の操作が停止します。

モノレポ内の多数の参照の影響を軽減するには:

- 古いブランチをクリーンアップするための自動化されたプロセスを作成します。
- 特定の参照をクライアントに表示する必要がない場合は、[`transfer.hideRefs`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-transferhideRefs)構成設定を使用して非表示にします。Gitalyは、サーバー上のGit構成をすべて無視するため、`/etc/gitlab/gitlab.rb`でGitaly構成自体を変更する必要があります:

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

Git 2.42.0以降では、オブジェクトグラフウォークを実行するときに、さまざまなGit操作で非表示の参照をスキップできます。

### リポジトリの最適化タスクをスケジュールする {#schedule-repository-optimization-tasks}

Gitリポジトリのオブジェクトデータベースにデータが保存される方法は、時間の経過とともに非効率になる可能性があり、Git操作が遅くなります。これらのアイテムをクリーンアップしてパフォーマンスを向上させるために、最大期間を設定して、[Gitalyに毎日のバックグラウンドタスクを実行するようにスケジュール](../../../../administration/housekeeping.md#configure-scheduled-housekeeping)できます。

## モノレポ用にCI/CDを最適化する {#optimize-cicd-for-monorepos}

モノレポでGitLabのスケーラビリティを維持するには、CI/CDジョブがリポジトリとどのように相互作用するかを最適化します。大規模で長いパイプラインは、モノレポの一般的な問題点です。モノレポのパイプライン構成で、行われた変更のタイプを検出する[ビルドルール](../../../../ci/yaml/_index.md#rules)を使用します:

- 不要なジョブをスキップします。
- 子パイプラインで関連するジョブのみを実行します。

### CI/CDでの同時クローンを削減する {#reduce-concurrent-clones-in-cicd}

実行する時間をずらすために[CI/CDパイプラインの並行処理を減らす](../../../../ci/pipelines/schedules.md#distribute-pipeline-schedules-to-prevent-system-load)。ほんの数分間隔でも効果があります。

パイプラインが[特定の時間にスケジュール](../../../../ci/pipelines/pipeline_efficiency.md#reduce-how-often-jobs-run)されているため、CI/CDの負荷は多くの場合、同時実行されます。リポジトリへのGitリクエストは、これらの時間帯に急増し、CI/CDプロセスとユーザーのパフォーマンスに影響を与える可能性があります。

### CI/CDプロセスでシャロークローンとフィルターを使用する {#use-shallow-clones-and-filters-in-cicd-processes}

CI/CDシステムでの`git clone`および`git fetch`の呼び出しの場合、転送されるデータ量を次のオプションで制限できます:

- [`--depth`](https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt)
- [`--filter`](https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---filterfilter-spec)

#### CI/CDでのシャロークローン {#shallow-clone-in-cicd}

`--depth`フィルターは、いわゆる_シャロークローン_を作成します。GitLabとGitLab Runnerは、デフォルトで[シャロークローン](../../../../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone)を実行します。

クローン深度は、たとえば`GIT_DEPTH`を使用してGitLab CI/CDパイプライン構成で構成できます:

```yaml
variables:
  GIT_DEPTH: 10

test:
  script:
    - ls -al
```

#### CI/CDでの部分クローン {#partial-clone-in-cicd}

`--filter`オプションを使用して_部分クローン_を作成します。この引数を`git-clone`に渡すには、`GIT_CLONE_EXTRA_FLAGS`変数を設定します。たとえば、blobの最大サイズを1MBに制限するには、次を追加します:

```yaml
variables:
  GIT_CLONE_EXTRA_FLAGS: --filter=blob:limit=1m
```

### パスとオブジェクトタイプを除外する {#filter-out-paths-and-object-types}

特定のタイプのオブジェクト、または特定のパスからオブジェクトを除外するには、`git sparse-checkout`オプションを使用します。詳細については、[ファイルパスでフィルタリング](../../../../topics/git/clone.md#filter-by-file-path)を参照してください。

### CI/CD操作で`git fetch`を使用する {#use-git-fetch-in-cicd-operations}

リポジトリの実行コピーを使用可能な状態に保つことができる場合は、CI/CDシステムで`git clone`の代わりに`git fetch`を使用します。`git fetch`は、サーバーからの作業が少なくて済みます:

- `git clone`は、リポジトリ全体を最初からリクエストします。`git-pack-objects`は、すべてのブランチとタグを処理して送信する必要があります。
- `git fetch`は、リポジトリにないGit参照のみをリクエストします。`git-pack-objects`は、Git参照の合計のサブセットのみを処理します。この戦略は、転送されるデータの合計も削減します。

デフォルトでは、GitLabは大規模なリポジトリに推奨される[`fetch` Git戦略](../../../../ci/runners/configure_runners.md#git-strategy)を使用します。

### `git clone`パスを設定する {#set-a-git-clone-path}

モノレポがフォークベースのワークフローで使用されている場合は、リポジトリをクローンする場所を制御するために[`GIT_CLONE_PATH`](../../../../ci/runners/configure_runners.md#custom-build-directories)を設定することを検討してください。

Gitは、フォークを個別のワークツリーを持つ個別のリポジトリとして保存します。GitLab Runnerは、ワークツリーの使用を最適化できません。指定されたプロジェクトに対してのみ、GitLab Runnerエグゼキュータを構成して使用します。プロセスをより効率的にするために、異なるプロジェクト間で共有しないでください。

[`GIT_CLONE_PATH`](../../../../ci/runners/configure_runners.md#custom-build-directories)は、`$CI_BUILDS_DIR`で設定されたディレクトリにある必要があります。ディスクから任意のパスを選択することはできません。

### CI/CDジョブで`git clean`を無効にする {#disable-git-clean-on-cicd-jobs}

`git clean`コマンドは、ワークツリーから追跡されていないファイルを削除します。大規模なリポジトリでは、大量のディスクI/Oを使用します。既存のマシンを再利用し、既存のワークツリーを再利用できる場合は、CI/CDジョブで無効にすることを検討してください。たとえば、`GIT_CLEAN_FLAGS: -ffdx -e .build/`は、実行間でワークツリーからディレクトリを削除しないようにすることができます。これにより、増分ビルドを高速化できます。

CI/CDジョブで`git clean`を無効にするには、[`GIT_CLEAN_FLAGS`](../../../../ci/runners/configure_runners.md#git-clean-flags)をそれらの`none`に設定します。

デフォルトでは、GitLabは次のことを保証します:

- 指定されたSHAにワークツリーがあります。
- リポジトリがクリーンです。

`GIT_CLEAN_FLAGS`で受け入れられる正確なパラメータについては、[`git clean`のGitドキュメント](https://git-scm.com/docs/git-clean)を参照してください。使用可能なパラメータは、Gitバージョンによって異なります。

### フラグを使用して`git fetch`の動作を変更する {#change-git-fetch-behavior-with-flags}

CI/CDジョブが必要としないデータを除外するように、`git fetch`の動作を変更します。プロジェクトに多数のタグが含まれており、CI/CDジョブがそれらを必要としない場合は、`GIT_FETCH_EXTRA_FLAGS`を使用して[`--no-tags`](https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---no-tags)を設定します。この設定により、フェッチをより高速かつコンパクトにすることができます。

リポジトリに多数のタグが含まれていない場合でも、`--no-tags`を使用すると、場合によってはパフォーマンスが向上することがあります。詳細については、[イシュー746](https://gitlab.com/gitlab-com/gl-infra/observability/team/-/issues/746)および[`GIT_FETCH_EXTRA_FLAGS` Gitドキュメント](../../../../ci/runners/configure_runners.md#git-fetch-extra-flags)を参照してください。

### Runnerのロングポーリングを使用する {#use-long-polling-for-runners}

Runnerは、新しいCI/CDジョブのGitLabインスタンスを定期的にポーリングします。ポーリング間隔は、次の両方によって異なります:

- `check_interval`設定。
- Runner構成ファイルで構成されたRunnerの数。
 
サーバーが多数のRunnerを処理する場合、このポーリングにより、キュー時間が長くなったり、CPU使用率が高くなったりするなど、GitLabインスタンスでパフォーマンスの問題が発生する可能性があります。ロングポーリングは、新しいジョブの準備ができるまで、Runnerからのジョブリクエストを保持します。

構成手順については、[ロングポーリング](../../../../ci/runners/long_polling.md)を参照してください。

## モノレポ用にGitを最適化する {#optimize-git-for-monorepos}

モノレポでGitLabのスケーラビリティを維持するには、リポジトリ自体を最適化します。

### 開発用にシャロークローンを回避する {#avoid-shallow-clones-for-development}

開発用にシャロークローンを回避します。シャロークローンは、変更をプッシュするために必要な時間を大幅に増やします。シャロークローンは、チェックアウト後にリポジトリの内容が変更されないため、CI/CDジョブでうまく機能します。

ローカル開発では、代わりに[部分クローン](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---filterltfilter-specgt)を使用して、次の操作を行います:

- `git clone --filter=blob:none`でblobを除外します。
- `git clone --filter=tree:0`でツリーを除外します。

詳細については、[クローンサイズの削減](../../../../topics/git/clone.md#reduce-clone-size)を参照してください。

### リポジトリをプロファイルして問題を検出 {#profile-your-repository-to-find-problems}

大規模なリポジトリでは、通常、Gitでパフォーマンスの問題が発生します。[`git-sizer`](https://github.com/github/git-sizer)プロジェクトは、リポジトリをプロファイルし、潜在的な問題を理解するのに役立ちます。パフォーマンスの問題を防ぐための軽減策を開発するのに役立ちます。リポジトリの分析には、すべてのGit参照が存在することを確認するために、完全なGitミラーまたはベアクローンが必要です。

`git-sizer`でリポジトリをプロファイルするには:

1. [Git-sizer `git-sizer`](https://github.com/github/git-sizer?tab=readme-ov-file#getting-started)をインストールします。
1. このコマンドを実行して、`git-sizer`と互換性のあるベアGit形式でリポジトリをクローンします:

   ```shell
   git clone --mirror <git_repo_url>
   ```

1. Gitリポジトリのディレクトリで、すべての統計情報を使用して`git-sizer`を実行します:

   ```shell
   git-sizer -v
   ```

処理後、`git-sizer`の出力はこの例のようになります。各行には、リポジトリのその側面に関する**懸念レベル**が含まれています。懸念レベルが高いほど、アスタリスクが多く表示されます。懸念レベルが非常に高いアイテムは、感嘆符で示されます。この例では、いくつかのアイテムの懸念レベルが高くなっています:

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

### 大規模なバイナリファイルにGit LFSを使用 {#use-git-lfs-for-large-binary-files}

バイナリファイル（パッケージ、オーディオ、ビデオ、グラフィックスなど）をGit Large File Storage（Git LFS）オブジェクトとして保存します。

ユーザーがGitにファイルをコミットすると、Gitはblob [オブジェクトタイプ](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects)を使用して、コンテンツを保存および管理します。Gitは大規模なバイナリデータを効率的に処理しないため、大規模なblobはGitにとって問題があります。`git-sizer`が10 MBを超えるblobをレポートする場合、通常、リポジトリに大規模なバイナリファイルがあります。大規模なバイナリファイルは、サーバーとクライアントの両方で問題を引き起こします:

- サーバーの場合: テキストベースのソースコードとは異なり、バイナリデータは多くの場合、すでに圧縮されています。Gitはバイナリデータをさらに圧縮できないため、大規模なパックファイルにつながります。大規模なパックファイルでは、作成と送信により多くのCPU、メモリ、および帯域幅が必要になります。
- クライアントの場合: Gitは、パックファイル（通常は`.git/objects/pack/`）と通常のファイル（[ワークツリー](https://git-scm.com/docs/git-worktree)）の両方にblobコンテンツを保存します。バイナリファイルは、テキストベースのソースコードよりもはるかに多くのスペースを必要とします。

Git LFSは、オブジェクトストレージなどの外部にオブジェクトを保存します。Gitリポジトリには、バイナリファイル自体ではなく、オブジェクトの場所へのポインターが含まれています。これにより、リポジトリのパフォーマンスが向上する可能性があります。詳細については、[Git LFSのドキュメント](../../../../topics/git/lfs/_index.md)を参照してください。

## 関連トピック {#related-topics}

- [Gitalyを設定する](../../../../administration/gitaly/configure_gitaly.md)
