---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 内部ユーザー
description: GitLabの機能のために、内部ボットユーザーを介して自動化されたシステム操作を有効にします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97584)、ボットはユーザーリストにバッジで示されます。

{{< /history >}}

GitLabでは、通常のユーザーに起因しないアクションまたは機能を実行するために、内部ユーザー（「ボット」と呼ばれることもあります）を使用します。

内部ユーザー:

- プログラムで作成され、ライセンス制限にはカウントされません。
- 従来のユーザーアカウントが該当しない場合に使用されます。たとえば、アラートの生成時や自動レビューフィードバック時などです。
- アクセスが制限され、非常に特定の目的があります。認証またはAPIリクエストなど、通常のユーザーアクションには使用できません。
- 実行するすべてのアクションに起因するメールアドレスと名前があります。

内部ユーザーは、機能開発の一環として作成されることがあります。たとえば、GitLabスニペットから[バージョン管理されたスニペット](../user/snippets.md#versioned-snippets)に[移行](https://gitlab.com/gitlab-org/gitlab/-/issues/216120)するためのGitLab移行ボットなどです。スニペットの元の作成者が利用できない場合、GitLab移行ボットはスニペットの作成者として使用されました。たとえば、ユーザーが無効になっている場合などです。

内部ユーザーのその他の例:

- [GitLab Automation Bot](../user/group/iterations/_index.md#gitlab-automation-bot-user)
- [GitLab Security Bot](#gitlab-security-bot)
- [GitLab Security Policy Bot](#gitlab-security-policy-bot)
- [アラートボット](../operations/incident_management/alerts.md#trigger-actions-from-alerts)。
- [Ghostユーザー](../user/profile/account/delete_account.md#associated-records)。
- [サポートボット](../user/project/service_desk/configure.md#support-bot-user)。
- [プレースホルダユーザー](../user/project/import/_index.md#placeholder-users)（インポート時に作成）
- ビジュアルレビューボット。
- リソースアクセストークン（[プロジェクトアクセストークン](../user/project/settings/project_access_tokens.md) 、[グループアクセストークン](../user/group/settings/group_access_tokens.md)など）。これらは、`project_{project_id}_bot_{random_string}`および`group_{group_id}_bot_{random_string}`の`PersonalAccessToken`ユーザーです。

## GitLab管理者ボット {#gitlab-admin-bot}

[GitLab管理者ボット](https://gitlab.com/gitlab-org/gitlab/-/blob/1d38cfdbed081f8b3fa14b69dd743440fe85081b/lib/users/internal.rb#L104)は、通常のユーザーがアクセスまたは変更できない内部ユーザーであり、次の多くのタスクを担当します:

- [デフォルト](../user/compliance/compliance_frameworks/_index.md#default-compliance-frameworks)コンプライアンスフレームワークをプロジェクトに適用する。
- [休眠ユーザーを自動的に非アクティブ化](moderate_users.md#automatically-deactivate-dormant-users)。
- [未確認のユーザーを自動的に削除](moderate_users.md#automatically-delete-unconfirmed-users)。
- [休止プロジェクトの削除](dormant_project_deletion.md)。
- [ユーザーのロック](../security/unlock_user.md)。

## GitLab Securityボット {#gitlab-security-bot}

[セキュリティポリシー](../user/application_security/policies/_index.md)に違反するマージリクエストにコメントする責任を負う内部ユーザーがGitLab Security Botです。

## GitLab Security Policyボット {#gitlab-security-policy-bot}

[セキュリティポリシー](../user/application_security/policies/_index.md#gitlab-security-policy-bot-user)で定義されたスケジュールされたパイプラインをトリガーする責任を負う内部ユーザーがGitLab Security Policy Botです。このアカウントは、セキュリティポリシーが適用されるすべてのプロジェクトで作成されます。
