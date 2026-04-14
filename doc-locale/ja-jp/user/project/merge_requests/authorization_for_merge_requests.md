---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabのマージリクエストの最も一般的なフローは、フォーク、保護ブランチ、またはその両方を使用します。
title: マージリクエストのワークフロー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabのマージリクエストは、通常、次のいずれかのフローに従います:

- 単一のリポジトリで[保護ブランチ](../repository/branches/protected.md)を操作します。
- 権威あるプロジェクトのフォークを操作します。

## 保護ブランチフロー {#protected-branch-flow}

保護ブランチフローでは、全員がフォークではなく、同じGitLabプロジェクトで作業します。

プロジェクトのメンテナーはメンテナーロールを、一般的なデベロッパーはデベロッパーロールを取得します。

メンテナーは権威あるブランチを「Protected」とマークします。

デベロッパーはフィーチャーブランチをプロジェクトにプッシュし、フィーチャーブランチのレビューと保護ブランチへのマージを行うためにマージリクエストを作成します。

デフォルトでは、メンテナーロールを持つユーザーのみが、保護ブランチに変更をマージすることができます。

- 利点:
  - プロジェクトが少ないほど、煩雑さが軽減されます。
  - デベロッパーは1つのリモートリポジトリのみを考慮すれば済みます。
- 欠点:
  - 新しいプロジェクトごとに保護ブランチの手動設定が必要です。

保護ブランチフローを設定するには:

1. まず、デフォルトブランチが、[デフォルトブランチ保護](../repository/branches/default.md)で保護されていることを確認します。
1. チームに複数のブランチがあり、変更をマージすることができるユーザー、および明示的にプッシュするまたは強制プッシュするオプションを持つユーザーを管理したい場合は、それらのブランチを保護することを検討してください:

   - [ブランチを管理および保護する](../repository/branches/_index.md#manage-and-protect-branches)
   - [保護ブランチ](../repository/branches/protected.md)

1. コードへの各変更は、コミットとして行われます。フォーマットとセキュリティ対策 (たとえば、コードベースへの変更に対してSSHキー署名を要求するなど) は、プッシュルールで指定できます:

   - [プッシュルール](../repository/push_rules.md)

1. チーム内の適切な人物によってコードがレビューおよびチェックされるようにするには、以下を使用します:

   - [コードオーナー](../codeowners/_index.md)
   - [マージリクエスト承認ルール](approvals/rules.md)

Ultimateでも利用可能:

- [Status checks](status_checks.md)
- [Security approvals](approvals/rules.md#security-approvals)

## フォーク型ワークフロー {#forking-workflow}

フォーク型ワークフローでは、メンテナーはメンテナーロールを、一般的なデベロッパーは権威あるリポジトリのレポーターロールを取得し、変更をプッシュすることを禁じられます。

デベロッパーは正規プロジェクトのフォークを作成し、自分のフォークにフィーチャーブランチをプッシュします。

変更をデフォルトブランチに組み込むには、フォーク間でマージリクエストを作成する必要があります。

- 利点:
  - 適切に設定されたGitLabグループでは、新しいプロジェクトは自動的に通常のデベロッパーに必要なアクセス制限を取得します。これにより、新しいプロジェクトの認可を設定するための手動手順が少なくなります。
- 欠点:
  - プロジェクトはフォークを最新の状態に保つ必要があり、これにはより高度なGitスキル（複数のリモートの管理）が必要です。
