---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use Code Owners to define experts for your code base, and set review requirements based on file type or location.
title: コードオーナー
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コードオーナー機能を使用すると、プロジェクトのコードベースの特定の部分に関する専門知識を持つ担当者を定義できます。リポジトリ内のファイルとディレクトリのオーナーを定義して、以下を行います。

- **オーナーに変更の承認を求めます。**保護ブランチとコードオーナーを組み合わせて、エキスパートが保護ブランチにマージリクエストをマージする前に承認するよう要求します。詳細については、「[コードオーナーと保護ブランチ](#code-owners-and-protected-branches)」を参照してください。
- **オーナーを特定します。**コードオーナーの名前は、所有するファイルとディレクトリに表示されます。

  ![UIに表示されるコードオーナー](../img/codeowners_in_UI_v15_10.png)

## コードオーナーと承認ルール

コードオーナーとマージリクエストの[承認ルール](../merge_requests/approvals/rules.md)（オプションまたは必須）を組み合わせて柔軟な承認ワークフローをビルドします。

- **コードオーナー**を使用して、品質を確保します。リポジトリ内の特定のパスについて、ドメインの専門知識を持つユーザーを定義します。
- **承認ルール**を使用して、リポジトリ内の特定のファイルパスに対応しない専門分野を定義します。承認ルールは、マージリクエストの作成者が、フロントエンドデベロッパーやセキュリティチームなど、適切なレビュアーを決定するのに役立ちます。

次に例を示します。

| タイプ | 名前 | スコープ  | コメント    |
|------|------|--------|------------|
| 承認ルール            | ユーザーエクスペリエンス                   | すべてのファイル     | ユーザーエクスペリエンス（UX）チームのメンバーが、プロジェクトで行われたすべての変更のユーザーエクスペリエンスをレビューします。 |
| 承認ルール            | セキュリティ             | すべてのファイル     | セキュリティチームのメンバーが、すべての変更に脆弱性がないかレビューします。 |
| コードオーナーの承認ルール | フロントエンド:コードスタイル | `*.css`ファイル | フロントエンドエンジニアが、プロジェクトのスタイル標準への準拠について、CSSファイルへの変更をレビューします。 |
| コードオーナーの承認ルール | バックエンド:コードレビュー | `*.rb`ファイル  | バックエンドエンジニアが、Rubyファイルのロジックとコードスタイルをレビューします。 |

<div class="video-fallback">
  ビデオによる紹介: <a href="https://www.youtube.com/watch?v=RoyBySTUSB0">Code Owners</a>（コードオーナー）。
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/RoyBySTUSB0" frameborder="0" allowfullscreen></iframe>
</figure>

## コードオーナーと保護ブランチ

[`CODEOWNERS`ファイル](#codeowners-file)で指定されたコードオーナーがマージリクエストの変更をレビューおよび承認するようにするには、マージリクエストのターゲットブランチを[保護](../repository/branches/protected.md)し、[コードオーナーの承認](../repository/branches/protected.md#require-code-owner-approval-on-a-protected-branch)が有効になっている必要があります。

保護ブランチでコードオーナーの承認を有効にすると、次の機能が利用可能になります。

- [コードオーナーからの承認を必須にする](../repository/branches/protected.md#require-code-owner-approval-on-a-protected-branch)。
- [コードオーナーからの複数承認を必須にする](advanced.md#require-multiple-approvals-from-code-owners)。
- [コードオーナーからの承認を任意にする](reference.md#optional-sections)。

### 実践的な例

プロジェクトでは、`config/`ディレクトリに機密情報と重要な情報が含まれています。以下を実行できます。

1. ディレクトリの所有権を割り当てます。これを行うには、`CODEOWNERS`を設定します。
1. デフォルトブランチの保護ブランチを作成します。たとえば、`main`などです。
1. 保護ブランチで**コードオーナーからの承認を必須にする**を有効にします。
1. オプション: `CODEOWNERS`ファイルを編集して、複数承認のルールを追加します。

この設定では、`config/`ディレクトリ内のファイルを変更し、`main`ブランチをターゲットにするマージリクエストには、マージする前に指定されたコードオーナーからの承認が必要です。

## ファイルまたはディレクトリのコードオーナーを表示する

ファイルまたはディレクトリのコードオーナーを表示するには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを検索します。
1. **コード>リポジトリ**を選択します。
1. コードオーナーを表示するファイルまたはディレクトリに移動します。
1. オプション: ブランチまたはタグを選択します。

GitLabでは、ページの上部にコードオーナーが表示されます。

## コードオーナーを設定する

前提要件:

- デフォルトブランチにプッシュする権限またはマージリクエストを作成する権限が必要です。

1. [推奨される場所](#codeowners-file)に`CODEOWNERS`ファイルを作成します。
1. [`CODEOWNERS`構文](reference.md)に従って、ファイルにいくつかのルールを定義します。次に、いくつかの提案を示します。
   - [すべての対象となる承認者](../merge_requests/approvals/rules.md#code-owners-as-eligible-approvers)承認ルールを設定します。
   - 保護ブランチで[コードオーナーから承認を必須](../repository/branches/protected.md#require-code-owner-approval-on-a-protected-branch)にします。
1. 変更をコミットし、GitLabにプッシュします。

## `CODEOWNERS`ファイル

`CODEOWNERS`ファイルは、GitLabプロジェクトのコード責任者を定義します。目的は次のとおりです。

- 特定のファイルとディレクトリのコードオーナーを定義する。
- 保護ブランチの承認要件を適用する。
- プロジェクトのコード所有権を伝達する。

このファイルは、誰が変更をレビューおよび承認する必要があるかを決定し、適切な専門家がコードの変更に関与するようにします。

各リポジトリで1つの`CODEOWNERS`ファイルを使用します。GitLabは、リポジトリ内の次の場所をこの順序で確認します。最初に見つかった`CODEOWNERS`ファイルが使用され、その他はすべて無視されます。

1. ルートディレクトリ内: `./CODEOWNERS`。
1. `docs`ディレクトリ内: `./docs/CODEOWNERS`。
1. `.gitlab`ディレクトリ内: `./.gitlab/CODEOWNERS`。

詳細については、「[`CODEOWNERS`構文](reference.md)」と「[高度な`CODEOWNERS`設定](advanced.md)」を参照してください。

## プッシュを許可する

**プッシュを許可**されたユーザーは、変更のマージリクエストを作成するか、変更をブランチに直接プッシュするかを選択できます。ユーザーがマージリクエストプロセスをスキップすると、マージリクエストに組み込まれている保護ブランチ機能とコードオーナーの承認もスキップされます。

この権限は、多くの場合、自動化（[内部ユーザー](../../../administration/internal_users.md)およびリリースツールに関連付けられたアカウントに付与されます。

**プッシュを許可**権限が_ない_ユーザーからの変更はすべて、マージリクエストを介してルーティングする必要があります。

## 関連トピック

- [`CODEOWNERS`構文](reference.md)
- [高度な`CODEOWNERS`設定](advanced.md)
- [開発ガイドライン](../../../development/code_owners/_index.md)
- [保護ブランチ](../repository/branches/protected.md)
- [コードオーナーのトラブルシューティング](troubleshooting.md)
