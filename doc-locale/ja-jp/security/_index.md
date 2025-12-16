---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: SSHキーの制限、2FA、トークン、強化。
title: GitLabの保護
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## 一般情報 {#general-information}

このセクションでは、プラットフォームに関する一般的な情報と推奨事項について説明します。

- [パスワードとOAuthトークンのストレージ](password_storage.md)
- 統合[認証](passwords_for_integrated_authentication_methods.md)で作成されたユーザーのパスワード生成
- [CRIME](crime_vulnerability.md)脆弱性管理
- [サードパーティのインテグレーションに対するシークレットのローテーション](rotate_integrations_secrets.md)

## 推奨事項 {#recommendations}

GitLab環境におけるセキュリティ対策状況を改善する方法については、[強化に関する推奨事項](hardening.md)をご覧ください。

### ウイルス対策ソフトウェア {#antivirus-software}

通常、GitLabホストでウイルス対策ソフトウェアを実行することは推奨されません。

ただし、使用する必要がある場合は、システム上のGitLabに関連するすべての場所をスキャン対象から除外する必要があります。誤検出によりファイルが隔離される可能性があるためです。

具体的には、次のGitLabディレクトリをスキャン対象から除外してください:

- `/var/opt/gitlab`
- `/etc/gitlab/`
- `/var/log/gitlab/`
- `/opt/gitlab/`

これらのディレクトリはすべて、[Linuxパッケージ設定に関するドキュメント](https://docs.gitlab.com/omnibus/settings/configuration.html)に記載されています。

### ユーザーアカウント {#user-accounts}

- [認証オプションを確認する](../administration/auth/_index.md)。
- [パスワードの長さ制限を設定する](password_length_limits.md)。
- [SSHキー方式を制限し、最小キー長を要求する](ssh_keys_restrictions.md)。
- [サインアップ制限でアカウント作成を制限する](../administration/settings/sign_up_restrictions.md)。
- [サインアップ時に確認メールを送信する](user_email_confirmation.md)
- [2要素認証を必須にして](two_factor_authentication.md) 、ユーザーに[2要素認証を実施する](../user/profile/account/two_factor_authentication.md)を求める。
- [複数のIPからのログインを制限する](../administration/reporting/ip_addr_restrictions.md)。
- [ユーザーパスワードをリセットする方法](reset_user_password.md)。
- [ロックされたユーザーのロックを解除する方法](unlock_user.md)。

### データアクセス {#data-access}

- [プロジェクトメンバーシップに関するセキュリティの考慮事項](../user/project/members/_index.md#security-considerations)。
- [ユーザーのファイルアップロードを保護し、削除する](user_file_uploads.md)。
- [ユーザーのプライバシー保護のため、リンクされたイメージをプロキシ処理する](asset_proxy.md)。

### プラットフォームの使用と設定 {#platform-usage-and-settings}

- [GitLabのトークンタイプと使用方法を確認する](tokens/_index.md)。
- [レート制限を設定してセキュリティと可用性を向上させる方法](rate_limits.md)。
- [送信Webhookリクエストをフィルタリングする方法](webhooks.md)。
- [インポートおよびエクスポートの制限とタイムアウトを設定する方法](../administration/settings/import_and_export_settings.md)。
- [Runnerのセキュリティに関する考慮事項と推奨事項を確認する](https://docs.gitlab.com/runner/security/)。
- [CI/CD変数のセキュリティに関する考慮事項を確認する](../ci/variables/_index.md#cicd-variable-security)。
- [CI/CDパイプラインでのシークレットの使用と保護に関するパイプラインセキュリティを確認する](../ci/pipeline_security/_index.md)。
- [インスタンス全体のコンプライアンスとセキュリティポリシーの管理](compliance_security_policy_management.md)。

### パッチ {#patching}

GitLab Self-Managedのお客様および管理者は、基盤となるホストのセキュリティと、GitLab自体を常に最新の状態に保つ責任があります。[GitLabに定期的にパッチを適用](../policy/maintenance.md)し、オペレーティングシステムおよび関連ソフトウェアにパッチを適用し、ベンダーのガイダンスに従ってホストを強化することが重要です。

## モニタリング {#monitoring}

### ログ {#logs}

- [GitLabによって生成されるログの種類と内容を確認する](../administration/logs/_index.md)。
- [Runnerのジョブログ情報を確認する](../administration/cicd/job_logs.md)。
- [相関IDを使用してログをトレースする方法](../administration/logs/tracing_correlation_id.md)。
- [ログ生成の設定とアクセス](https://docs.gitlab.com/omnibus/settings/logs.html)。
- [監査イベントストリーミングを設定する方法](../administration/compliance/audit_event_streaming.md)。

## 応答 {#response}

- [セキュリティインシデントへの対応](responding_to_security_incidents.md)。

## レート制限 {#rate-limits}

レート制限については、[レート制限](rate_limits.md)を参照してください。
