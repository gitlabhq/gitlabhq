---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: モノレポのパフォーマンスを改善する
---

モノレポとは、サブプロジェクトを含むGitリポジトリです。単一アプリケーションには、相互に依存するプロジェクトが含まれていることがよくあります。たとえば、バックエンド、ウェブフロントエンド、iOSアプリケーション、Androidアプリケーションなどがあります。モノレポは一般的ですが、パフォーマンス上のリスクをもたらす可能性があります。一般的な問題：

- 大きなバイナリファイル。
- 長い履歴を持つ多数のファイル。
- 多数の同時クローンとプッシュ。
- 垂直方向のスケール制限。
- ネットワーク帯域幅の制限。
- ディスク帯域幅の制限。

GitLab自体がGitに基づいています。Gitストレージサービスである[Gitaly](https://gitlab.com/gitlab-org/gitaly)は、モノレポに関連するパフォーマンスの制約を受けます。私たちが学んだことは、独自のモノレポをより良く管理するのに役立ちます。

- リポジトリの特性がパフォーマンスにどのような影響を与えるか。
- モノレポを最適化するためのツールと手順。

## モノレポ向けにGitalyを最適化する {#optimize-gitaly-for-monorepos}

Gitは、使用するスペースを削減するために、オブジェクトを[パックファイル](https://git-scm.com/book/en/v2/Git-Internals-Packfiles)に圧縮します。クローン、フェッチ、またはプッシュすると、Gitはパックファイルを使用します。これらはディスク容量とネットワーク帯域幅を削減しますが、パックファイルの作成には多くのCPUとメモリが必要です。

大規模なモノレポは、小規模なリポジトリよりも、コミット、ファイル、ブランチ、およびタグが多くなります。オブジェクトが大きくなり、転送に時間がかかるようになると、パックファイルの作成はよりコストがかかり、遅くなります。Gitでは、[`git-pack-objects`](https://git-scm.com/docs/git-pack-objects)プロセスは、次の理由により、最もリソースを消費する操作です。

1. コミット履歴とファイルを解析します。
1. クライアントに送り返すファイルを決定します。
1. パックファイルを作成します。

`git clone`と`git fetch`からのトラフィックは、サーバー上で`git-pack-objects`プロセスを開始します。GitLab CI/CDのような自動化された継続的インテグレーションシステムは、このトラフィックの多くを引き起こす可能性があります。自動化されたCI/CDからの大量のトラフィックは、多数のクローンおよびフェッチリクエストを送信し、Gitalyサーバーに負荷をかける可能性があります。

これらの戦略を使用して、Gitalyサーバーの負荷を軽減します。

### Gitaly `pack-objects`キャッシュを有効にする {#enable-the-gitaly-pack-objects-cache}

[Gitaly `pack-objects`キャッシュ](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)を有効にすると、クローンとフェッチのサーバー負荷が軽減されます。

Gitクライアントがクローンまたはフェッチリクエストを送信すると、`git-pack-objects`によって生成されたデータをキャッシュして再利用できます。モノレポが頻繁に複製される場合は、[Gitaly `pack-objects`キャッシュ](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)を有効にすると、サーバーの負荷が軽減されます。有効にすると、Gitalyは、クローンまたはフェッチ呼び出しごとに応答データを再生成する代わりに、インメモリキャッシュを保持します。

詳細については、[Pack-objects cache](../../../../administration/gitaly/configure_gitaly.md#pack-objects-cache)を参照してください。

### GitバンドルURIをConfigureする {#configure-git-bundle-uris}

低レイテンシーのサードパーティ製ストレージ（CDNなど）に[Gitバンドル](https://git-scm.com/docs/bundle-uri)を作成して保存します。Gitは最初にバンドルからパッケージをダウンロードし、次に残りのオブジェクトと参照をGitリモートからフェッチします。このアプローチにより、オブジェクトデータベースのブートストラップが高速化され、Gitalyの負荷が軽減されます。

- GitLabサーバーへのネットワーキング接続が不十分なユーザーのために、クローンとフェッチが高速化されます。
- バンドルをプリロードすることにより、CI/CDジョブを実行するサーバーの負荷を軽減します。

詳細については、[バンドルURI](../../../../administration/gitaly/bundle_uris.md)を参照してください。

### GitalyネゴシエーションのタイムアウトをConfigureする {#configure-gitaly-negotiation-timeouts}

リポジトリをフェッチまたはアーカイブしようとすると、次の場合に`fatal: the remote end hung up unexpectedly`エラーが発生する可能性があります。

- 大規模なリポジトリ。
- 多数のリポジトリが並行して存在します。
- 同じ大規模リポジトリが並行して存在します。

この問題を緩和するには、[デフォルトのネゴシエーションのタイムアウト値](../../../../administration/settings/gitaly_timeouts.md#configure-the-negotiation-timeouts)を大きくします。

### ハードウェアのサイズを正しく設定する {#size-your-hardware-correctly}

モノレポは通常、多数のユーザーがいる大規模な組織向けです。モノレポをサポートするには、GitLab環境が、GitLabテストプラットフォームおよびサポートチームが提供する[参照アーキテクチャ](../../../../administration/reference_architectures/_index.md)のいずれかと一致する必要があります。これらのアーキテクチャは、パフォーマンスを保持しながらGitLabをスケールするための推奨される方法です。

### Git参照の数を減らす {#reduce-the-number-of-git-references}

Gitでは、[参照](https://git-scm.com/book/en/v2/Git-Internals-Git-References)は、特定のコミットを指すブランチ名およびタグ名です。Gitは、参照をリポジトリの`.git/refs`フォルダーに緩いファイルとして保存します。リポジトリ内のすべての参照を表示するには、`git for-each-ref`を実行します。

リポジトリ内の参照の数が増えると、特定の参照を見つけるために必要なシーク時間も長くなります。Gitが参照を解析するたびに、シーク時間が増加するとレイテンシーが増加します。

この問題を修正するために、Gitは[pack-refs](https://git-scm.com/docs/git-pack-refs)を使用して、そのリポジトリのすべての参照を含む単一の`.git/packed-refs`ファイルを作成します。このメソッドは、refsに必要なストレージ容量を削減します。また、単一のファイルをシークする方がディレクトリ内のすべてのファイルをシークするよりも高速であるため、シーク時間も短縮されます。

Gitは、新しく作成または更新された参照を緩いファイルで処理します。これらは、`git pack-refs`を実行するまで`.git/packed-refs`ファイルにクリーンアップされ、追加されません。Gitalyは、[ハウスキーピング](../../../../administration/housekeeping.md#heuristical-housekeeping)中に`git pack-refs`を実行します。これは多くのリポジトリに役立ちますが、書き込み負荷の高いリポジトリには、次のパフォーマンスの問題がまだあります。

- 参照を作成または更新すると、新しい緩いファイルが作成されます。
- 参照を削除するには、既存の`packed-refs`ファイルを編集して、既存の参照を削除する必要があります。

リポジトリをフェッチまたはクローンすると、Gitはすべての参照をイテレーション処理します。サーバーは、各参照の内部オブジェクトグラフ構造をレビュー（「ウォーク」）し、欠落しているオブジェクトを見つけて、クライアントに送信します。イテレーション処理とウォーキングプロセスはCPUを大量に消費し、レイテンシーを増加させます。このレイテンシーにより、アクティビティーが多いリポジトリでドミノ効果が発生する可能性があります。各操作が遅くなり、各操作で後続の操作が停止します。

モノレポ内の多数の参照の影響を緩和するには：

- 古いブランチをクリーンアップするための自動化されたプロセスを作成します。
- 特定の参照をクライアントに表示する必要がない場合は、[`transfer.hideRefs`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-transferhideRefs)設定を使用して除外します。Gitalyはサーバー上のGit設定を無視するため、`/etc/gitlab/gitlab.rb`でGitaly設定自体を変更する必要があります。

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

Git 2.42.0以降では、異なるGit操作でオブジェクトグラフウォークを実行するときに、非表示の参照をスキップできます。

## モノレポのCI/CDを最適化する {#optimize-cicd-for-monorepos}

GitLabをモノレポでスケールできるようにするには、CI/CDジョブがリポジトリとどのように相互作用するかを最適化します。

### CI/CDの同時クローンを削減する {#reduce-concurrent-clones-in-cicd}

実行する時間をずらすために[CI/CDパイプラインの並行処理をずらす](../../../../ci/pipelines/schedules.md#distribute-pipeline-schedules-to-prevent-system-load)ことで、CI/CDパイプラインの並行処理を削減します。数分間隔でも効果があります。

CI/CDの負荷は、パイプラインが[特定の時間にスケジュール](../../../../ci/pipelines/pipeline_efficiency.md#reduce-how-often-jobs-run)されているため、同時に発生することがよくあります。リポジトリへのGitリクエストは、これらの時間帯に急増する可能性があり、CI/CDプロセスとユーザーのパフォーマンスに影響を与える可能性があります。

### CI/CD処理でシャロークローンを使用する {#use-shallow-clones-in-cicd-processes}

CI/CDシステムでの`git clone`および`git fetch`呼び出しの場合は、[`--depth`](https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt)オプションを10などの小さい数値で設定します。深さ10は、特定のブランチの最後の10個の変更のみをリクエストするようにGitに指示します。リポジトリに長いバックログがある場合、または多数の大きなファイルがある場合、この変更によりGitフェッチが大幅に高速化されます。これにより、転送されるデータ量が削減されます。

GitLabおよびGitLab Runnerは、デフォルトで[シャロークローン](../../../../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone)を実行します。

このGitLab CI/CDパイプライン設定例では、`GIT_DEPTH`を設定します。

```yaml
variables:
  GIT_DEPTH: 10

test:
  script:
    - ls -al
```

### CI/CD操作で`git fetch`を使用する {#use-git-fetch-in-cicd-operations}

リポジトリの実行コピーを保持できる場合は、CI/CDシステムで`git clone`の代わりに`git fetch`を使用します。`git fetch`は、サーバーからの作業が少なくて済みます。

- `git clone`リクエストは、リポジトリ全体を最初からやり直します。`git-pack-objects`は、すべてのブランチとタグを処理して送信する必要があります。
- `git fetch`リクエストは、リポジトリから欠落しているGit参照のみをリクエストします。`git-pack-objects`は、Git参照の合計のサブセットのみを処理します。この戦略は、転送される合計データも削減します。

デフォルトでは、GitLabは大規模リポジトリに推奨される[`fetch`Git戦略](../../../../ci/runners/configure_runners.md#git-strategy)を使用します。

### `git clone`パスを設定する {#set-a-git-clone-path}

モノレポがフォークベースのワークフローで使用されている場合は、リポジトリをクローンする場所を制御するために[`GIT_CLONE_PATH`](../../../../ci/runners/configure_runners.md#custom-build-directories)を設定することを検討してください。

Gitは、フォークを個別のワークツリーを持つ個別のリポジトリとして保存します。GitLab Runnerは、ワークツリーの使用を最適化できません。指定されたプロジェクトに対してのみ、GitLab RunnerエグゼキューターをConfigureして使用します。プロセスをより効率的にするために、異なるプロジェクト間で共有しないでください。

[`GIT_CLONE_PATH`](../../../../ci/runners/configure_runners.md#custom-build-directories)は、`$CI_BUILDS_DIR`で設定されたディレクトリにある必要があります。ディスクからパスを選択することはできません。

### CI/CDジョブで`git clean`を無効にする {#disable-git-clean-on-cicd-jobs}

`git clean`コマンドは、ワークツリーから追跡していないファイルを削除します。大規模なリポジトリでは、大量のディスクI / Oを使用します。既存のマシンを再利用し、既存のワークツリーを再利用できる場合は、CI/CDジョブで無効にすることを検討してください。たとえば、`GIT_CLEAN_FLAGS: -ffdx -e .build/`を使用すると、実行間でワークツリーからディレクトリを削除することを回避できます。これにより、インクリメンタルビルドを高速化できます。

CI/CDジョブで`git clean`を無効にするには、[`GIT_CLEAN_FLAGS`](../../../../ci/runners/configure_runners.md#git-clean-flags)を`none`に設定します。

デフォルトでは、GitLabは以下を保証します。

- 指定されたSHAにワークツリーがあります。
- リポジトリがcleanです。

`GIT_CLEAN_FLAGS`で受け入れられる正確なパラメータについては、[`git clean`のGitドキュメント](https://git-scm.com/docs/git-clean)を参照してください。使用可能なパラメータは、Gitのバージョンによって異なります。

### フラグを使用して`git fetch`の動作を変更する {#change-git-fetch-behavior-with-flags}

CI/CDジョブが必要としないデータを除外するために、`git fetch`の動作を変更します。プロジェクトに多数のタグが含まれており、CI/CDジョブでそれらを必要としない場合は、`GIT_FETCH_EXTRA_FLAGS`を使用して[`--no-tags`](https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---no-tags)を設定します。この設定により、フェッチがより高速かつコンパクトになります。

リポジトリに多数のタグが含まれていない場合でも、`--no-tags`を使用すると、場合によってはパフォーマンスが向上します。詳細については、[課題746](https://gitlab.com/gitlab-com/gl-infra/observability/team/-/issues/746)および[`GIT_FETCH_EXTRA_FLAGS`Gitドキュメント](../../../../ci/runners/configure_runners.md#git-fetch-extra-flags)を参照してください。

## モノレポのGitを最適化する {#optimize-git-for-monorepos}

GitLabをモノレポでスケールできるようにするには、リポジトリ自体を最適化します。

### 開発用シャロークローンを避ける {#avoid-shallow-clones-for-development}

開発用シャロークローンは避けてください。シャロークローンは、変更をプッシュするのに必要な時間を大幅に増加させます。チェックアウト後にリポジトリの内容が変更されないため、シャロークローンはCI/CDジョブでうまく機能します。

ローカル開発では、代わりに[部分クローン](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---filterltfilter-specgt)を使用して、以下を行います。

- Blobを`git clone --filter=blob:none`でフィルタリングします
- ツリーを`git clone --filter=tree:0`でフィルタリングします

詳細については、[クローンサイズの削減](../../../../topics/git/clone.md#reduce-clone-size)を参照してください。

### リポジトリをプロファイリングして問題を検出する {#profile-your-repository-to-find-problems}

大規模なリポジトリでは通常、Gitでパフォーマンスの問題が発生します。[`git-sizer`](https://github.com/github/git-sizer)プロジェクトは、リポジトリをプロファイルし、潜在的な問題を理解するのに役立ちます。パフォーマンスの問題を防ぐための軽減戦略を開発するのに役立ちます。リポジトリを分析するには、すべてのGit参照が存在することを確認するために、完全なGitミラーまたはベアクローンが必要です。

`git-sizer`でリポジトリをプロファイルするには：

1. [`git-sizer`をインストール](https://github.com/github/git-sizer?tab=readme-ov-file#getting-started)。
1. このコマンドを実行して、`git-sizer`と互換性のあるベアGit形式でリポジトリをクローンします。

   ```shell
   git clone --mirror <git_repo_url>
   ```

1. Gitリポジトリのディレクトリで、すべての統計を使用して`git-sizer`を実行します。

   ```shell
   git-sizer -v
   ```

処理後、`git-sizer`の出力はこの例のように表示されます。各行には、リポジトリのその側面に対する**懸念のレベル**が含まれています。懸念のレベルが高いほど、アスタリスクが多く表示されます。懸念のレベルが非常に高いアイテムは、感嘆符で示されます。この例では、いくつかのアイテムの懸念レベルが高くなっています。

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

### 大きなバイナリファイルにGit LFSを使用する {#use-git-lfs-for-large-binary-files}

バイナリファイル（パッケージ、オーディオ、ビデオ、グラフィックなど）をGit LFS (LFS) オブジェクトとして保存します。

ユーザーがファイルをGitにコミットすると、GitはBLOB [オブジェクトタイプ](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects)を使用してコンテンツを保存および管理します。Gitは大きなバイナリデータを効率的に処理できないため、大きなバイナリラージオブジェクトはGitにとって問題となります。`git-sizer`が10 MBを超えるバイナリラージオブジェクトをレポートする場合、通常、リポジトリに大きなバイナリファイルがあります。大きなバイナリファイルは、サーバーとクライアントの両方で問題を引き起こします。

- サーバーの場合：テキストベースのコードとは異なり、バイナリデータは多くの場合すでに圧縮されています。Gitはバイナリデータをさらに圧縮できないため、大きなパックファイルにつながります。大きなパックファイルは、作成および送信するためにより多くのCPU、メモリ、および帯域幅を必要とします。
- クライアントの場合：Gitは、バイナリラージオブジェクトコンテンツをパックファイル（通常は`.git/objects/pack/`）と通常のファイル（[working-tree](https://git-scm.com/docs/git-worktree)）の両方に格納します。バイナリファイルは、テキストベースのコードよりもはるかに多くのスペースを必要とします。

Git LFSは、オブジェクトストレージなど、外部にオブジェクトを保存します。Gitリポジトリには、バイナリファイル自体ではなく、オブジェクトの場所へのポインターが含まれています。これにより、リポジトリのパフォーマンスが向上する可能性があります。詳細については、[LFSドキュメント](../../../../topics/git/lfs/_index.md)を参照してください。
