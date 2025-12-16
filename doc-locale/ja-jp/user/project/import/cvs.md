---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CVSからの移行
description: "CVSからGitへ移行します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[CVS](https://savannah.nongnu.org/projects/cvs)は、[SVN](https://subversion.apache.org/)と同様の古い集中型バージョン管理システムです。

## CVSとGitの比較 {#cvs-vs-git}

以下は、CVSとGitの主な違いを示しています:

- Gitは分散型です。一方、CVSは集中型であり、クライアント/サーバーアーキテクチャを使用します。これは、作業領域がリポジトリ全体のコピーであるため、Gitがより柔軟なワークフローを持つことを意味します。これにより、たとえば、リモートサーバーと通信する必要がないため、ブランチの切り替えまたはマージ時のオーバーヘッドが軽減されます。
- アトミック処理。Gitでは、すべての操作が[アトミック](https://en.wikipedia.org/wiki/Atomic_commit)であり、全体として成功するか、変更なしに失敗するかのいずれかです。CVSでは、コミット（およびその他の操作）はアトミックではありません。リポジトリでの操作が途中で中断された場合、リポジトリは一貫性のない状態になる可能性があります。
- ストレージ方法。CVSの変更はファイルごと（チェンジセット）ですが、Gitでは、コミットされたファイルは全体（スナップショット）として保存されます。つまり、Gitでは変更全体を元に戻したり、取り消したりすることが非常に簡単です。
- バージョンID。CVSでの変更がファイルごとであるという事実は、リビジョンIDがバージョン番号で示されています。たとえば、`1.4`は、特定のファイルが変更された回数を反映しています。Gitでは、プロジェクト全体の各バージョン（各コミット）には、SHA-1によって与えられた一意の名前があります。
- マージ追跡。Gitは、CVSのようにマージ前にコミットする（または更新してからコミットする）アプローチではなく、コミット前にマージするアプローチを使用します。新しいコミット（新しいリビジョン）を作成する準備中に、誰かが同じブランチに新しいコミットを作成して中央リポジトリにプッシュした場合、CVSは、コミットを許可する前に、最初に作業ディレクトリを更新してコンフリクトを解決することを強制します。Gitではそうではありません。最初にコミットして、バージョン管理で状態を保存してから、他のデベロッパーの変更をマージします。他のデベロッパーにマージを実行させ、コンフリクトを解決させることもできます。
- 署名されたコミット。Gitは、追加のセキュリティと、コミットが実際に元の作成者からのものであることの検証のために、[署名されたコミットを署名](../repository/signed_commits/_index.md)することをサポートしています。GitLabは、署名されたコミットが正しく検証されているかどうかを表示します。

上記の項目のいくつかは、この優れた[スタックオーバーフローの投稿](https://stackoverflow.com/a/824241/974710)から引用しました。相違点のより完全なリストについては、[さまざまなバージョン管理システムの比較](https://en.wikipedia.org/wiki/Comparison_of_version_control_software)に関するWikipediaの記事を参照してください。

## 移行する理由 {#why-migrate}

CVSは古く、2008年以降新しいリリースはありません。Gitはより多くのツールを提供し（`git bisect`など）、より生産的なワークフローを実現します。Git/GitLabへの移行は、次の点でメリットがあります:

- 学習曲線が短い。Gitには大規模なコミュニティと、開始に役立つ多数のチュートリアルがあります（[Gitのトピック](../../../topics/git/_index.md)をご覧ください）。
- 最新のツールとのインテグレーション。移行をGitとGitLabに行うことで、オープンソースのエンドツーエンドのソフトウェア開発プラットフォームを、組み込みのバージョン管理システム、イシュートラッキング、コードレビュー、CI/CDなどで利用できます。
- 多くのネットワーキングプロトコルのサポート。GitはSSH、HTTP/HTTPS、rsyncなどをサポートしていますが、CVSはSSHとその独自の脆弱な`pserver`プロトコルのみをサポートしており、ユーザー認証はありません。

## 移行方法 {#how-to-migrate}

次に、移行を開始するためのいくつかのリンクを示します:

- [`cvs-fast-export`ツールを使用して移行する](https://gitlab.com/esr/cvs-fast-export)
- [CVSリポジトリのインポートに関するスタックオーバーフローの投稿](https://stackoverflow.com/a/11490134/974710)
- [`git-cvsimport`ツールのマニュアルページ](https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-cvsimport.html)
- [`reposurgeon`を使用して移行する](http://www.catb.org/~esr/reposurgeon/repository-editing.html#conversion)
