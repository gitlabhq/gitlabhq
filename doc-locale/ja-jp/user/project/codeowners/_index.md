---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: コードベースのエキスパートを定義し、ファイルの種類または場所に基づいてレビュー要件を設定するには、コードオーナーを使用します。
title: GitLabコードオーナー
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コードオーナー機能を使用すると、プロジェクトのコードベースの特定の部分に関して専門知識を持つユーザーを定義できます。リポジトリ内のファイルとディレクトリのオーナーを定義して、以下を実現します:

- オーナーに変更の承認を要求する。保護ブランチをGitLabコードオーナーと組み合わせて、マージリクエストを保護ブランチにマージする前に知識豊富なユーザーが承認することを要求します。詳細については、[コードオーナーと保護ブランチ](#code-owners-and-protected-branches)を参照してください。
- オーナーを特定する。コードオーナーの名前は、所有するファイルとディレクトリに表示されます:

  ![最新の変更内容の説明の下にリストされているコードオーナーを表示するファイルビュー。](img/codeowners_in_UI_v15_10.png)

## GitLabコードオーナーと承認ルール {#code-owners-and-approval-rules}

コードオーナーとマージリクエストの[承認ルール](../merge_requests/approvals/rules.md)を組み合わせて、柔軟な承認ワークフローを構築します:

- GitLabコードオーナーを使用して品質を確保します。リポジトリ内の特定のパスに関する専門知識を持つユーザーを定義します。
- 承認ルールを使用して、リポジトリ内の特定のファイルパスに対応しない専門知識の領域を定義します。承認ルールは、マージリクエストの作成者が、フロントエンドの開発者やセキュリティチームなど、適切なレビュアーを決定するのに役立ちます。

次に例を示します:

| タイプ | 名前 | スコープ  | コメント    |
|------|------|--------|------------|
| 承認ルール            | ユーザーエクスペリエンス                   | すべてのファイル     | ユーザーエクスペリエンス（UX）チームのメンバーが、プロジェクトで行われたすべての変更のユーザーエクスペリエンスをレビューします。 |
| 承認ルール            | セキュリティ             | すべてのファイル     | セキュリティチームのメンバーが、すべての変更に脆弱性がないかレビューします。 |
| コードオーナー承認ルール | フロントエンド: コードスタイル | `*.css`ファイル | フロントエンドエンジニアは、CSSファイルの変更をレビューして、プロジェクトのスタイル標準への準拠を確認します。 |
| コードオーナー承認ルール | バックエンド: コードレビュー | `*.rb`ファイル  | バックエンドエンジニアは、Rubyファイルのロジックとコードスタイルをレビューします。 |

<div class="video-fallback">
  動画による紹介: <a href="https://www.youtube.com/watch?v=RoyBySTUSB0">GitLabコードオーナー</a>。
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/RoyBySTUSB0" frameborder="0" allowfullscreen> </iframe>
</figure>

承認者またはコードオーナーとしてマージリクエストを承認する資格のあるユーザーの詳細については、[メンバーシップタイプ別の承認者](../merge_requests/approvals/rules.md#approver-by-membership-type)を参照してください。

## GitLabコードオーナーと保護ブランチ {#code-owners-and-protected-branches}

[`CODEOWNERS`ファイル](#codeowners-file)で指定されたコードオーナーによりマージリクエストの変更を確実にレビューおよび承認するには、マージリクエストのターゲットブランチが[保護](../repository/branches/protected.md)されており、[コードオーナーの承認](../repository/branches/protected.md#require-code-owner-approval)が有効になっている必要があります。

保護ブランチでコードオーナーの承認を有効にすると、次の機能を利用できます:

- [コードオーナーからの承認を必須にする](../repository/branches/protected.md#require-code-owner-approval)。
- [コードオーナーからの複数承認を必須にする](advanced.md#require-multiple-approvals-from-code-owners)。
- [コードオーナーからの承認をオプションにする](reference.md#optional-sections)。

### 実践的な例 {#practical-example}

プロジェクトでは、`config/`ディレクトリに機密情報と重要な情報が含まれています。次のことができます:

1. ディレクトリの所有権を割り当てる。これを行うには、`CODEOWNERS`ファイルを設定します。
1. デフォルトブランチの保護ブランチを作成する（例: `main`)。
1. 保護ブランチで**Required approval from code owners**（コードオーナーからの承認を必須にする）を有効にする。
1. オプション。`CODEOWNERS`ファイルを編集して、複数承認のルールを追加する。

この構成では、`config/`ディレクトリ内のファイルを変更し、`main`ブランチをターゲットとするマージリクエストの場合、マージする前に指定されたコードオーナーからの承認が必要です。

### 保護ブランチへのプッシュとマージを許可する {#allowed-to-push-and-merge-to-a-protected-branch}

**プッシュとマージを許可**されているユーザーは、変更内容についてマージリクエストを作成するか、変更をブランチに直接プッシュするかを選択できます。ユーザーがマージリクエストプロセスをスキップすると、マージリクエストに組み込まれている保護ブランチ機能とコードオーナーの承認もスキップされます。

この権限は、多くの場合、自動化（[内部ユーザー](../../../administration/internal_users.md)）およびリリースツールに関連付けられたアカウントに付与されます。

**プッシュを許可**権限がないユーザーからのすべての変更は、マージリクエストを介してルーティングする必要があります。

## ファイルまたはディレクトリのGitLabコードオーナーを表示する {#view-code-owners-of-a-file-or-directory}

ファイルまたはディレクトリのコードオーナーは、次の手順で表示できます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **リポジトリ**を選択します。
1. コードオーナーを表示するファイルまたはディレクトリに移動します。
1. オプション。ブランチまたはタグを選択します。

GitLabでは、ページの上部にコードオーナーを表示します。

## GitLabコードオーナーを設定する {#set-up-code-owners}

前提要件:

- デフォルトブランチにプッシュするか、またはマージリクエストを作成する権限が必要です。

1. [推奨される場所](#codeowners-file)に`CODEOWNERS`ファイルを作成します。
1. [`CODEOWNERS`構文](reference.md)に従って、ファイルにいくつかのルールを定義します。この場合の推奨事項は次のとおりです:
   - [すべての適格な承認者](../merge_requests/approvals/rules.md#code-owners-as-approvers)承認ルールを設定する。
   - 保護ブランチで[コードオーナーの承認を要求する](../repository/branches/protected.md#require-code-owner-approval)。
1. 変更をコミットし、GitLabにプッシュします。

## `CODEOWNERS`ファイル {#codeowners-file}

`CODEOWNERS`ファイルは、GitLabプロジェクトのコードに対する責任者を定義します。その目的は次のとおりです:

- 特定のファイルとディレクトリのコードオーナーを定義する。
- 保護ブランチの承認要件を適用する。
- プロジェクトでコードの所有権を伝える。

このファイルにより、変更をレビューおよび承認するユーザーを決定し、適切な専門知識を持ったユーザーをコードの変更に巻き込むことができます。

各リポジトリは、単一の`CODEOWNERS`ファイルを使用します。GitLabは、リポジトリ内のこれらの場所を以下の順序でチェックします。最初に見つかった`CODEOWNERS`ファイルが使用され、その他はすべて無視されます:

1. ルートディレクトリ内: `./CODEOWNERS`。
1. `docs`ディレクトリ内: `./docs/CODEOWNERS`。
1. `.gitlab`ディレクトリ内: `./.gitlab/CODEOWNERS`。

詳細については、[`CODEOWNERS`構文](reference.md)および[高度な`CODEOWNERS`設定](advanced.md)を参照してください。

## 関連トピック {#related-topics}

- [`CODEOWNERS`構文](reference.md)
- [高度な`CODEOWNERS`設定](advanced.md)
- [コードオーナーのトラブルシューティング](troubleshooting.md)
- [リポジトリを保護する](../repository/protect.md)
- [保護ブランチ](../repository/branches/protected.md)
