---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabにインポートおよび移行する
description: リポジトリの移行、サードパーティリポジトリ、ユーザーのコントリビュートマッピング。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- すべてのインポーターは、GitLab Self-Managedインスタンスでデフォルトで無効になっています。これは、GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118970)されました。

{{< /history >}}

既存の作業をGitLabに取り込みます。

一部のサードパーティプラットフォームでは、移行ツールを使用できます。ユーザーコントリビュートとメンバーシップの[移行後のマッピング](mapping.md)をサポートするものもあります。

| 移行元                                                                | グループ                  | プロジェクト    | 移行ツール | 移行後のマッピング |
|:----------------------------------------------------------------------------|:------------------------|:------------|:---------------|:-----------------------|
| [GitLab（直接転送を使用）](../group/import/_index.md)              | {{< yes >}}             | {{< yes >}} | {{< yes >}}    | {{< yes >}}            |
| [GitLab（ファイルエクスポートを使用）](../project/settings/import_export.md)       | {{< yes >}}<sup>1</sup> | {{< yes >}} | {{< yes >}}    | {{< no >}}             |
| [Bitbucket Server](bitbucket_server.md)                                     | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< yes >}}            |
| [GitHub](../project/import/github.md)                                       | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< yes >}}            |
| [Gitea](gitea.md)                                                           | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< yes >}}            |
| [Bitbucket Cloud](bitbucket_cloud.md)                                       | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< no >}}             |
| [FogBugz](../project/import/fogbugz.md)                                     | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< no >}}             |
| Gitリポジトリ（[マニフェストファイル](../project/import/manifest.md)を使用）     | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< no >}}             |
| Gitリポジトリ（[リポジトリURL](../project/import/repo_by_url.md)を使用） | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< no >}}             |
| [ClearCase](../project/import/clearcase.md)                                 | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}             |
| [CVS](../project/import/cvs.md)                                             | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}             |
| [Perforce Helix](../project/import/perforce.md)                             | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}             |
| [サブバージョン](#migrate-from-subversion)                                      | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}             |
| [Team Foundation Version Control（TFVC）](../project/import/tfvc.md)         | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}             |
| [Jira（イシューのみ）](../project/import/jira.md)                             | {{< no >}}              | {{< no >}}  | {{< yes >}}    | {{< no >}}             |

**脚注**: 

1. グループ移行にファイルエクスポートを使用することは非推奨です。

## サブバージョンからの移行 {#migrate-from-subversion}

GitLabは、サブバージョンリポジトリをGitに自動的に移行することはできません。サブバージョンリポジトリをGitに変換するには、次のような外部ツールを使用できます:

- [`git svn`](https://git-scm.com/book/en/v2/Git-and-Other-Systems-Migrating-to-Git)（非常に小さく基本的なリポジトリ用）。
- [`reposurgeon`](http://www.catb.org/~esr/reposurgeon/repository-editing.html)（より大きく複雑なリポジトリ用）。

## プロフェッショナルサービスを利用して移行する {#migrate-by-engaging-professional-services}

自分で移行する代わりに、GitLabプロフェッショナルサービスを利用してグループとプロジェクトをGitLabに移行することもできます。詳しくは、[プロフェッショナルサービスのフルカタログ](https://about.gitlab.com/services/catalog/)をご覧ください。

## プロジェクトインポートの履歴を表示する {#view-project-import-history}

作成したすべてのプロジェクトインポートを表示できます。このリストには、以下が含まれます:

- プロジェクトが外部システムからインポートされた場合はソースプロジェクトのパス、またはGitLabプロジェクトが移行された場合はインポート方法。
- 移行先プロジェクトのパス。
- 各インポートの開始日。
- 各インポートの状態。
- エラーが発生した場合のエラーの詳細。

履歴には、以下から作成されたプロジェクトも含まれます:

- [組み込み](../project/_index.md#create-a-project-from-a-built-in-template)テンプレート。
- [カスタム](../project/_index.md#create-a-project-from-a-custom-template)テンプレート。

GitLabは[URLでリポジトリをインポート](../project/import/repo_by_url.md)して、テンプレートから新しいプロジェクトを作成します。

プロジェクトのインポート履歴を表示するには:

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトのインポート**を選択します。
1. 右上隅にある**履歴**リンクを選択します。
1. 特定のインポートにエラーがある場合は、**詳細**を選択して表示します。

## LFSオブジェクトを含むプロジェクトをインポートする {#importing-projects-with-lfs-objects}

LFSオブジェクトを含むプロジェクトをインポートする場合、プロジェクトにリポジトリURLホストとは異なるURLホスト（`lfs.url`）を持つ[`.lfsconfig`](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-config.adoc)ファイルがある場合、LFSファイルはダウンロードされません。

## 関連トピック {#related-topics}

- [GitLabで管理されているリポジトリを移動する](../../administration/operations/moving_repositories.md)。
