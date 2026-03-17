---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 内部ユーザー
description: GitLabの機能のために、内部ボットユーザーを介して自動化されたシステム運用を有効にします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97584)され、ボットはユーザーリストにバッジで示されます。

{{< /history >}}

GitLabは、通常のユーザーに帰属できないアクションや機能を実行するために、内部ユーザー（「ボット」と呼ばれることもあります）を使用します。

内部ユーザー:

- GitLabによって自動的に作成され、ライセンス制限にはカウントされません。内部ユーザーを手動で作成することはできません。
- 従来のユーザーアカウントが適用できない場合に使用されます。たとえば、アラートの生成時や自動レビューフィードバック時などです。
- アクセスが制限されており、非常に特定の目的を持っています。認証やAPIリクエストなど、通常のユーザーアクションには使用できません。
- 実行するすべてのアクションに帰属できるメールアドレスと名前を持っています。

内部ユーザーは、機能開発の一部として作成されることがあります。たとえば、GitLabスニペットから[バージョン管理されたスニペット](../user/snippets.md#versioned-snippets)へ[移行](https://gitlab.com/gitlab-org/gitlab/-/issues/216120)するためのGitLab移行ボットなどです。GitLab移行ボットは、スニペットの元の作成者が利用できない場合に、スニペットの作成者として使用されました。たとえば、ユーザーが無効化された場合などです。

内部ユーザーの他の例:

- [GitLab Automation Bot](../user/group/iterations/_index.md#gitlab-automation-bot-user)
- [GitLab Security Bot](#gitlab-security-bot)
- [GitLab Security Policy Bot](#gitlab-security-policy-bot)
- [アラートボット](../operations/incident_management/alerts.md#trigger-actions-from-alerts)
- [Ghost User](../user/profile/account/delete_account.md#associated-records)
- [サポートボット](../user/project/service_desk/configure.md#support-bot-user)
- インポート中に作成された[プレースホルダーユーザー](../user/import/mapping.md#placeholder-users)
- VisualレビューBot
- リソースアクセストークン（[プロジェクトアクセストークン](../user/project/settings/project_access_tokens.md)および[グループアクセストークン](../user/group/settings/group_access_tokens.md)を含む）は、`project_{project_id}_bot_{random_string}`および`group_{group_id}_bot_{random_string}`のような`PersonalAccessToken`を持つユーザーです。

## GitLab管理者Bot {#gitlab-admin-bot}

[GitLab管理者Bot](https://gitlab.com/gitlab-org/gitlab/-/blob/1d38cfdbed081f8b3fa14b69dd743440fe85081b/lib/users/internal.rb#L104)は、通常のユーザーがアクセスまたは変更できない内部ユーザーであり、次の多くのタスクを担当します:

- プロジェクトへの[デフォルトのコンプライアンスフレームワーク](../user/compliance/compliance_frameworks/_index.md#default-compliance-frameworks)の適用。
- [休眠ユーザーの自動無効化](moderate_users.md#automatically-deactivate-dormant-users)。
- [未確認ユーザーの自動削除](moderate_users.md#automatically-delete-unconfirmed-users)。
- [休眠プロジェクトの削除](dormant_project_deletion.md)。
- [ユーザーのロック](../security/unlock_user.md)。

## GitLab Security Bot {#gitlab-security-bot}

GitLab Security Botは、[セキュリティポリシー](../user/application_security/policies/_index.md)に違反するマージリクエストにコメントする責任を負う内部ユーザーです。

## GitLab Security Policy Bot {#gitlab-security-policy-bot}

GitLab Security Policy Botは、[セキュリティポリシー](../user/application_security/policies/_index.md#gitlab-security-policy-bot-user)で定義されたスケジュール済みパイプラインをトリガーする責任を負う内部ユーザーです。このアカウントは、セキュリティポリシーが適用されるすべてのプロジェクトで作成されます。
