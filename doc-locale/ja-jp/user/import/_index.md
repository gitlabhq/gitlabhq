---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabにインポートおよび移行する
description: リポジトリの移行、サードパーティリポジトリ、ユーザーのコントリビュートマッピング。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- すべてのインポーターは、GitLab Self-Managedインスタンスでデフォルトで無効化されるように[導入され](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118970)、GitLab 16.0で利用可能になりました。

{{< /history >}}

既存の作業をGitLabに持ち込みます。

一部のサードパーティ製プラットフォームでは、移行ツールが利用可能です。一部では、ユーザーのコントリビュートとメンバーシップの[移行後マッピング](mapping/post_migration_mapping.md)をサポートしています。

| 移行元                                                                   | グループ                  | プロジェクト    | 移行ツール | 移行後マッピング |
|:-------------------------------------------------------------------------------|:------------------------|:------------|:---------------|:-----------------------|
| [GitLab（ダイレクト転送を使用）](../group/import/_index.md)                 | {{< yes >}}             | {{< yes >}} | {{< yes >}}    | {{< yes >}}            |
| [GitLab（ファイルエクスポートを使用）](../project/settings/import_export.md)          | {{< yes >}}<sup>1</sup> | {{< yes >}} | {{< yes >}}    | {{< no >}}             |
| [Bitbucket Server](bitbucket_server.md)                                        | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< yes >}}            |
| [GitHub](../project/import/github.md)                                          | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< yes >}}            |
| [Gitea](gitea.md)                                                              | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< yes >}}            |
| [Bitbucket Cloud](bitbucket_cloud.md)                                          | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< no >}}             |
| [FogBugz](third_party_systems/fogbugz.md)                                      | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< no >}}             |
| Gitリポジトリ（[マニフェストファイル](third_party_systems/manifest_file.md)を使用） | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< no >}}             |
| Gitリポジトリ（[リポジトリURL](third_party_systems/repo_by_url.md)を使用）  | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< no >}}             |
| [IBM DevOps ClearCase](third_party_systems/clearcase.md)                       | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}             |
| [Concurrent Versions System（CVS）](third_party_systems/cvs.md)                 | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}             |
| [Perforce P4](third_party_systems/perforce.md)                                 | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}             |
| [サブバージョン](#migrate-from-subversion)                                         | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}             |
| [Team Foundation Version Control（TFVC）](third_party_systems/tfvc.md)          | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}             |
| [Jira（イシューのみ）](third_party_systems/jira.md)                              | {{< no >}}              | {{< no >}}  | {{< yes >}}    | {{< no >}}             |

**補足説明**: 

1. グループ移行にファイルエクスポートを使用することは非推奨です。

## サブバージョンからの移行 {#migrate-from-subversion}

GitLabは、サブバージョンのリポジトリをGitに自動的に移行できません。サブバージョンリポジトリをGitに変換するには、例えば以下の外部ツールを使用できます:

- [`git svn`](https://git-scm.com/book/en/v2/Git-and-Other-Systems-Migrating-to-Git)は、非常に小さく基本的なリポジトリ用です。
- [`reposurgeon`](http://www.catb.org/~esr/reposurgeon/repository-editing.html)は、より大きく複雑なリポジトリ用です。

## プロフェッショナルサービスを利用して移行する {#migrate-by-engaging-professional-services}

自分で移行する代わりに、GitLabプロフェッショナルサービスを利用してグループとプロジェクトをGitLabに移行することもできます。詳細については、[Professional Servicesカタログ](https://about.gitlab.com/services/catalog/)を参照してください。

## プロジェクトインポートの履歴を表示する {#view-project-import-history}

作成したすべてのプロジェクトインポートを表示できます。該当するのは、次のような場面です:

- プロジェクトが外部システムからインポートされた場合はソースプロジェクトのパス、またはGitLabプロジェクトが移行された場合はインポート方法。
- 移行先プロジェクトのパス。
- 各インポートの開始日。
- 各インポートの状態。
- エラーが発生した場合のエラーの詳細。

履歴には、以下のいずれかから作成されたプロジェクトも含まれます:

- [組み込み](../project/_index.md#create-a-project-from-a-built-in-template)テンプレート。
- [カスタム](../project/_index.md#create-a-project-from-a-custom-template)テンプレート。

GitLabは[URLでリポジトリをインポート](third_party_systems/repo_by_url.md)して、テンプレートから新しいプロジェクトを作成します。

プロジェクトのインポート履歴を表示するには:

1. 右上隅で、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **プロジェクトをインポート**を選択します。
1. 右上隅にある**履歴**リンクを選択します。
1. 特定のインポートにエラーがある場合は、**詳細**を選択して表示します。

## LFSオブジェクトを含むプロジェクトをインポートする {#importing-projects-with-lfs-objects}

LFSオブジェクトを含むプロジェクトをインポートする場合、プロジェクトにリポジトリURLホストとは異なるURLホスト（`lfs.url`）を持つ[`.lfsconfig`](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-config.adoc)ファイルがある場合、LFSファイルはダウンロードされません。

## 関連トピック {#related-topics}

- [GitLabで管理されているリポジトリの移動](../../administration/operations/moving_repositories.md)。
