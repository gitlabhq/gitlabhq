---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: リポジトリX-Rayは、コード提案がプロジェクトのコードベースや依存関係をより深く理解できるようにします。
title: リポジトリX-Rayとコード提案
---

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/groups/gitlab-org/-/epics/12060)されました。

{{< /history >}}

リポジトリX-Rayは、以下の機能を自動的に強化します:

- [GitLab Duoコード提案](_index.md)のコード生成リクエスト。具体的には、プロジェクトの依存関係に関する追加コンテキストを提供し、コードレコメンデーションの精度と関連性を向上させます。
- [コードのリファクタリング](../../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide)、[コードの修正](../../../gitlab_duo_chat/examples.md#fix-code-in-the-ide)、[テストの作成](../../../gitlab_duo_chat/examples.md#write-tests-in-the-ide)のリクエスト。

これを実現するため、リポジトリX-Rayは次の方法で、コードアシスタントにプロジェクトのコードベースや依存関係に関する高度なインサイトを提供します:

- 依存関係マネージャーの設定ファイル（例: `Gemfile.lock`、`package.json`、`go.mod`）を検索する。
- 検索した内容からライブラリのリストを抽出する。
- 抽出したリストを追加のコンテキストとして提供し、GitLab Duoコード提案がコード生成、リファクタリング、修正、テスト作成の各リクエストに活用できるようにする。

使用中のライブラリやその他の依存関係を把握することで、リポジトリX-Rayは、プロジェクトで採用されているコードパターン、スタイル、技術に合わせてコードアシスタントが提案を調整できるよう支援します。これにより、対象の技術スタックにシームレスに統合され、ベストプラクティスに従ったコード提案が可能になります。

> [!note]
> リポジトリX-Rayはコード生成リクエストのみを強化し、コード補完リクエストは強化しません。

## リポジトリX-Rayの仕組み {#how-repository-x-ray-works}

{{< history >}}

- GitLab 17.6でライブラリの最大数が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/500365)されました。

{{< /history >}}

プロジェクトのデフォルトブランチに新しいコミットをプッシュすると、リポジトリX-Rayはバックグラウンドジョブをトリガーします。このジョブは、リポジトリ内の該当する設定ファイルをスキャンして解析します。

通常、各プロジェクトで一度に実行されるスキャンジョブは1つだけです。2回目のスキャンがトリガーされたときに、スキャンがすでに進行中の場合、2回目のスキャンは、最初のスキャンが完了するまで実行を待機します。これにより、最新の設定ファイルデータがデータベースで解析および更新されるまでに、わずかな遅延が発生する可能性があります。

コード生成リクエストが行われると、解析されたデータからの最大300個のライブラリが追加のコンテキストとしてプロンプトに含まれます。

## リポジトリX-Rayを有効にする {#enable-repository-x-ray}

{{< history >}}

- GitLab 17.4で`ai_enable_internal_repository_xray_service`[フラグ](../../../../administration/feature_flags/list.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/476180)されました。デフォルトでは無効になっています。
- GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/483928)になりました。機能フラグ`ai_enable_internal_repository_xray_service`は削除されました。

{{< /history >}}

プロジェクトが[GitLab Duoコード提案](_index.md)にアクセスできる場合、リポジトリX-Rayサービスは自動的に有効になります。

## サポートされている言語と依存関係マネージャー {#supported-languages-and-dependency-managers}

リポジトリX-Rayは、リポジトリのルートから最大2つのディレクトリレベルを検索します。たとえば、`Gemfile.lock`、`api/Gemfile.lock`、または`api/client/Gemfile.lock`はサポートされますが、`api/v1/client/Gemfile.lock`はサポートされません。言語ごとに、最初に一致する依存関係マネージャーのみが処理されます。ロックファイルが存在する場合は、ロックファイルではない対応ファイルよりもロックファイルが優先されます。

| 言語   | 依存関係マネージャー | 設定ファイル                  | GitLabバージョン |
| ---------- |--------------------| ----------------------------------- | -------------- |
| C/C++      | Conan              | `conanfile.py`                      | 17.5以降  |
| C/C++      | Conan              | `conanfile.txt`                     | 17.5以降  |
| C/C++      | vcpkg              | `vcpkg.json`                        | 17.5以降  |
| C#         | NuGet              | `*.csproj`                          | 17.5以降  |
| Go         | Go Modules         | `go.mod`                            | 17.4以降  |
| Java       | Gradle             | `build.gradle`                      | 17.4以降  |
| Java       | Maven              | `pom.xml`                           | 17.4以降  |
| JavaScript | NPM                | `package-lock.json`、`package.json` | 17.5以降  |
| Kotlin     | Gradle             | `build.gradle.kts`                  | 17.5以降  |
| PHP        | Composer           | `composer.lock`、`composer.json`    | 17.5以降  |
| Python     | Conda              | `environment.yml`                   | 17.5以降  |
| Python     | Pip                | `*requirements*.txt` <sup>1</sup>   | 17.5以降  |
| Python     | Poetry             | `poetry.lock`、`pyproject.toml`     | 17.5以降  |
| Ruby       | RubyGems           | `Gemfile.lock`                      | 17.4以降  |

補足説明:

1. Python Pipの場合、`*requirements*.txt` globパターンに一致するすべての設定ファイルが処理されます。
