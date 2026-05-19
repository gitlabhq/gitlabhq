---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Concurrent Versions Systemから移行する
description: "Concurrent Versions SystemからGitへ移行する。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Concurrent Versions System](https://savannah.nongnu.org/projects/cvs) （CVS）は、[SVN](https://subversion.apache.org/)に似た集中型バージョン管理システムです。

CVSとGitの相違点の概要については、この[スタックオーバーフローの投稿](https://stackoverflow.com/a/824241/974710)を参照してください。より詳細な相違点については、[異なるバージョン管理ソフトウェアを比較する](https://en.wikipedia.org/wiki/Comparison_of_version_control_software)ウィキペディアの記事を参照してください。

## Gitへの移行 {#migrate-to-git}

CVSからGitへ移行するためのツールは提供していません。移行に関する情報は、以下のリソースを参照してください:

- [`cvs-fast-export`ツールを使用して移行する](https://gitlab.com/esr/cvs-fast-export)
- [CVSリポジトリをインポートするためのスタックオーバーフローの投稿](https://stackoverflow.com/questions/11362676/how-to-import-and-keep-updated-a-cvs-repository-in-git/11490134#11490134)
- [`git-cvsimport`ツールのManページ](https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-cvsimport.html)
- [`reposurgeon`を使用して移行する](http://www.catb.org/~esr/reposurgeon/repository-editing.html#conversion)
