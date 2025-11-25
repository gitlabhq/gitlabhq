---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: リポジトリX-Rayは、コード提案に、プロジェクトのコードベースと依存関係に関するより多くのインサイトを提供します。
title: リポジトリX-Ray
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo ProまたはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/groups/gitlab-org/-/epics/12060)されました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。

{{< /history >}}

リポジトリX-Rayは以下を自動的に強化します:

- プロジェクトの依存関係に関する追加コンテキストを提供することにより、[GitLab Duo Code Suggestions](_index.md)のコード提案の生成リクエストを強化し、コード推奨の精度と関連性を向上させます。
- [コードをリファクタリングする](../../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide) 、[コードを修正する](../../../gitlab_duo_chat/examples.md#fix-code-in-the-ide) 、および[テストを作成する](../../../gitlab_duo_chat/examples.md#write-tests-in-the-ide)ためのリクエスト。

このために、リポジトリX-Rayは、コードアシスタントに、プロジェクトのコードベースと依存関係について、次の方法でより多くのインサイトを提供します:

- 依存関係マネージャーの設定ファイル（例: `Gemfile.lock`、`package.json`、`go.mod`）を検索します。
- コンテンツからライブラリのリストを抽出します。
- 抽出されたリストを、コード生成、コードをリファクタリング、コードの修正、およびテスト記述リクエストでGitLab Duo Code Suggestionsで使用される追加のコンテキストとして提供します。

リポジトリX-Rayは、使用中のライブラリやその他の依存関係を理解することで、コードアシスタントがプロジェクトで使用されているコードパターン、スタイル、およびテクノロジに合わせて提案を調整できるようにします。これにより、特定のスタックのベストプラクティスに従い、よりシームレスに統合されるコード提案が実現します。

{{< alert type="note" >}}

リポジトリX-Rayは、コード生成リクエストのみを強化し、コード補完リクエストは強化しません。

{{< /alert >}}

## リポジトリX-Rayの仕組み {#how-repository-x-ray-works}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/500365)されたライブラリの最大数。

{{< /history >}}

プロジェクトのデフォルトブランチに新しいコミットをプッシュすると、リポジトリX-Rayはバックグラウンドジョブをトリガーします。このジョブは、リポジトリ内の該当する設定ファイルをスキャンして解析します。

通常、各プロジェクトで一度に実行されるスキャンジョブは1つのみです。2回目のスキャンがトリガーされたときに、スキャンが既に進行中の場合、その2回目のスキャンは、最初のスキャンが完了するまで実行を待機します。これにより、最新の設定ファイルデータが解析され、データベースで更新されるまでにわずかな遅延が発生する可能性があります。

コード生成リクエストが作成されると、解析されたデータからの最大300個のライブラリが、追加のコンテキストとしてプロンプトに含まれます。

## リポジトリX-Rayを有効にする {#enable-repository-x-ray}

{{< history >}}

- GitLab 17.4で`ai_enable_internal_repository_xray_service`[フラグ](../../../../administration/feature_flags/list.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/476180)されました。デフォルトでは無効になっています。
- GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/483928)になりました。機能フラグ`ai_enable_internal_repository_xray_service`は削除されました。

{{< /history >}}

プロジェクトが[GitLab Duo Code Suggestions](_index.md)にアクセスできる場合、リポジトリX-Rayサービスは自動的に有効になります。

## サポートされている言語と依存関係マネージャー {#supported-languages-and-dependency-managers}

リポジトリX-Rayは、リポジトリのルートから最大2つのディレクトリレベルを検索します。たとえば、`Gemfile.lock`、`api/Gemfile.lock`、または`api/client/Gemfile.lock`はサポートされますが、`api/v1/client/Gemfile.lock`はサポートされません。言語ごとに、最初に一致する依存関係マネージャーのみが処理されます。利用可能な場合、ロックファイルは、ロックファイル以外のファイルよりも優先されます。

| 言語   | 依存関係マネージャー | 設定ファイル                  | GitLabバージョン |
| ---------- |--------------------| ----------------------------------- | -------------- |
| C/C++      | Conan              | `conanfile.py`                      | 17.5以降  |
| C/C++      | Conan              | `conanfile.txt`                     | 17.5以降  |
| C/C++      | vcpkg              | `vcpkg.json`                        | 17.5以降  |
| C#         | NuGet              | `*.csproj`                          | 17.5以降  |
| Go         | Go Modules         | `go.mod`                            | 17.4以降  |
| Java       | Gradle             | `build.gradle`                      | 17.4以降  |
| Java       | Maven              | `pom.xml`                           | 17.4以降  |
| JavaScript | NPM                | `package-lock.json`, `package.json` | 17.5以降  |
| Kotlin     | Gradle             | `build.gradle.kts`                  | 17.5以降  |
| PHP        | Composer           | `composer.lock`, `composer.json`    | 17.5以降  |
| Python     | Conda              | `environment.yml`                   | 17.5以降  |
| Python     | Pip                | `*requirements*.txt` <sup>1</sup>   | 17.5以降  |
| Python     | Poetry             | `poetry.lock`, `pyproject.toml`     | 17.5以降  |
| Ruby       | RubyGems           | `Gemfile.lock`                      | 17.4以降  |

補足説明:

1. Python Pipの場合、`*requirements*.txt` globパターンに一致するすべての設定ファイルが処理されます。
