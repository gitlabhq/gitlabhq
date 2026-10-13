---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabへのリクエストに対するレート制限で、インスタンスの安定性とセキュリティを保護します。
title: レート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!note]
> GitLab.comについては、[GitLab.comのレート制限](../user/gitlab_com/_index.md#rate-limits-on-gitlabcom)を参照してください。
>
> GitLab Dedicatedについては、[認証済みユーザーのレート制限](../administration/dedicated/user_rate_limits.md)を参照してください。

レート制限は、ウェブアプリケーションのセキュリティと耐久性を向上させるためによく使われる技術です。

例えば、シンプルなスクリプトで1秒あたり数千のリクエストを生成できます。リクエストは次のいずれかの可能性があります:

- 悪意のあるもの。
- 無関心なもの。
- 単なるバグ。

アプリケーションとインフラストラクチャは、その負荷に対応できない可能性があります。詳細については、[サービス拒否](https://en.wikipedia.org/wiki/Denial-of-service_attack)を参照してください。ほとんどの場合、単一のIPアドレスからのリクエストのレートを制限することで軽減できます。

ほとんどの[ブルートフォース攻撃](https://en.wikipedia.org/wiki/Brute-force_attack)は、同様にレート制限によって軽減されます。

> [!note]
> APIリクエストのレート制限は、フロントエンドからのリクエストには影響しません。これらのリクエストは常にウェブトラフィックとしてカウントされるためです。

## 設定オプション {#configuration-options}

ほとんどのレート制限は、**管理者**エリアで設定できます。一部はAPIまたはRailsコンソールからのみ利用可能で、GitLab Pagesのレート制限は設定ファイルで設定します。

### 管理者エリア {#admin-area}

これらのレート制限は、インスタンスの**管理者**エリアで設定できます:

- [APIレート制限](api/_index.md)
- [コンテンツ作成レート制限](content_creation.md)
- [Git操作レート制限](git.md)
- [インポートとエクスポートのレート制限](../administration/settings/import_export_rate_limits.md)
- [インシデント管理レート制限](../administration/settings/incident_management_rate_limits.md)
- [パイプライン作成レート制限](../administration/cicd/limits.md#pipeline-creation-rate-limits)
- [保護されたパス](../administration/settings/protected_paths.md)
- [rawエンドポイントのレート制限](../administration/settings/rate_limits_on_raw_endpoints.md)
- [ユーザーとIPのレート制限](../administration/settings/user_and_ip_rate_limits.md)
- [Webhook操作レート制限](../administration/settings/rate-limit-on-webhook-operations.md)

### APIとRailsコンソール {#api-and-rails-console}

これらのレート制限は、[アプリケーション設定API](../api/settings.md)で設定できます:

- [オートコンプリートユーザーのレート制限](../administration/instance_limits.md#autocomplete-users-rate-limit)
- [AIアクション](../api/settings.md#available-settings)（`ai_action_api_rate_limit`）: 認証済みユーザーごとに8時間あたり160回の呼び出し。GraphQLの`aiAction`ミューテーションに適用されます。
- [タグ作成レート制限](../api/settings.md#available-settings)（`tags_create_limit`）: プロジェクトごとに30分あたり100リクエスト。タグを作成するためのREST APIエンドポイント、GraphQLの`tagCreate`ミューテーション、UIでのタグ作成、および`/tag`クイックアクションに適用されます。

このレート制限は、[プラン制限API](../api/plan_limits.md)または[Railsコンソール](../administration/operations/rails_console.md#starting-a-rails-console-session)で設定できます:

- [Webhookのレート制限](../administration/instance_limits.md#webhook-rate-limit)

### 設定ファイル {#configuration-file}

これらのレート制限は、お使いのインストールの設定ファイルでのみ設定できます。例えば、Linuxパッケージインストールでは`/etc/gitlab/gitlab.rb`です:

- [GitLab Pagesのレート制限](../administration/pages/rate-limits.md)

## 設定できない制限 {#non-configurable-limits}

一部のレート制限は設定できません。これらの制限のリストについては、[設定不可能なレート制限](non_configurable.md)を参照してください。

## 利用停止とブロック {#bans-and-blocks}

一部の保護機能は、リクエストを遅くするのではなく、一定期間クライアントをブロックします。詳細については、[悪用および認証失敗による利用停止](abuse_bans.md)を参照してください。

## 関連トピック {#related-topics}

- [GitLabアプリケーションの制限](../administration/instance_limits.md)
- [CI/CDの制限](../administration/cicd/limits.md)
