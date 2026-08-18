---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アクセストークンスコープ
description: 各スコープによってパーソナルアクセストークン、グループアクセストークン、およびプロジェクトアクセストークンに付与される権限。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.0で、パーソナルアクセストークンではコンテナまたはパッケージレジストリにアクセスできなくなる変更が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/387721)されました。
- `k8s_proxy`は、GitLab 16.4で`k8s_proxy_pat`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422408)されました。デフォルトでは有効になっています。
- 機能フラグ`k8s_proxy_pat`は、GitLab 16.5で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518)されました。
- `read_service_ping`は、GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/42692#note_1222832412)されました。パーソナルアクセストークンのみ。
- `manage_runner`は、GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/460721)されました。
- `self_rotate`は、GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111)されました。デフォルトでは有効になっています。

{{< /history >}}

スコープは、アクセストークンが特定の組織レベルで実行できる内容を定義します。各スコープは、特定の権限セットを付与します。

トークンタイプは、トークンの到達範囲を決定します:

- あるパーソナルアクセストークンは、ユーザーが利用できるすべてのグループとプロジェクトにアクセスできます。
- あるグループアクセストークンは、そのグループ内のサブグループとプロジェクトにアクセスできます。
- あるプロジェクトアクセストークンは、そのプロジェクトにのみアクセスできます。

パーソナルアクセストークンを特定のリソースと権限に制限するには、[詳細権限パーソナルアクセストークン](../../auth/tokens/fine_grained_access_tokens.md)を参照してください。

| スコープ | トークンの可用性 | 説明 |
|-------|------------|-------------|
| `api` | 個人、グループ、プロジェクト | アクセストークンのスコープのAPIに対する読み取りおよび書き込みの完全なアクセス権を付与します。[コンテナレジストリ](../../user/packages/container_registry/_index.md)、[依存プロキシ](../../user/packages/dependency_proxy/_index.md)、および[パッケージレジストリ](../../user/packages/package_registry/_index.md)が含まれます。<sup>1</sup> |
| `read_api` | 個人、グループ、プロジェクト | トークンのスコープのAPIに対する読み取りアクセス権を付与します。パーソナルアクセストークンの場合、コンテナレジストリとパッケージレジストリが含まれます。グループアクセストークンとプロジェクトアクセストークンの場合、パッケージレジストリのみです。 |
| `read_repository` | 個人、グループ、プロジェクト | トークンのスコープのリポジトリへの読み取りアクセス（プル）を付与します。パーソナルアクセストークンの場合はプライベートプロジェクト、グループアクセストークンの場合はグループ内のすべてのリポジトリ、プロジェクトアクセストークンの場合はプロジェクト内のリポジトリです。Git-over-HTTPまたは[リポジトリファイルAPI](../../api/repository_files.md)を使用します。 |
| `write_repository` | 個人、グループ、プロジェクト | トークンのスコープのリポジトリへの読み取りおよび書き込みアクセス（プルおよびプッシュ）を付与します。パーソナルアクセストークンの場合はプライベートプロジェクト、グループアクセストークンの場合はグループ内のすべてのリポジトリ、プロジェクトアクセストークンの場合はプロジェクト内のリポジトリです。Git-over-HTTPを使用します。API認証はサポートされていません。 |
| `read_registry` | 個人、グループ、プロジェクト | 認可が必要な場合、[コンテナレジストリ](../../user/packages/container_registry/_index.md)イメージへの読み取りアクセス（プル）を付与します。コンテナレジストリが有効になっている場合にのみ使用できます。プライバシー条件はトークンタイプによって異なります。パーソナルアクセストークンの場合、プロジェクトがプライベートであるときに適用されます。グループアクセストークンの場合、グループ内のいずれかのプロジェクトがプライベートであるときに適用されます。プロジェクトアクセストークンの場合、プロジェクトがプライベートであるときに適用されます。 |
| `write_registry` | 個人、グループ、プロジェクト | [コンテナレジストリ](../../user/packages/container_registry/_index.md)イメージへの書き込みアクセス（プッシュ）を付与します。コンテナレジストリが有効になっている場合にのみ使用できます。グループアクセストークンおよびプロジェクトアクセストークンの場合、画像をプッシュするには`read_registry`スコープも含まれている必要があります。 |
| `self_rotate` | 個人、グループ、プロジェクト | このトークンをローテーションする権限を付与します。他のトークンはローテーションできません。パーソナルアクセストークンをローテーションするには、[パーソナルアクセストークンAPI](../../api/personal_access_tokens.md#rotate-a-personal-access-token)を参照してください。 |
| `read_virtual_registry` | 個人、グループ | [依存プロキシ](../../user/packages/dependency_proxy/_index.md)を介してコンテナイメージへの読み取りアクセス（プル）を付与します。依存プロキシが有効になっている場合にのみ使用できます。<sup>2</sup> |
| `write_virtual_registry` | 個人、グループ | [依存プロキシ](../../user/packages/dependency_proxy/_index.md)を介してコンテナイメージへの読み取りおよび書き込みアクセス（プル、プッシュ、および削除）を付与します。依存プロキシが有効になっている場合にのみ使用できます。<sup>2</sup> |
| `create_runner` | 個人、グループ、プロジェクト | トークンのスコープのRunnerを作成する権限を付与します。 |
| `manage_runner` | 個人、グループ、プロジェクト | トークンのスコープのRunnerを管理する権限を付与します。 |
| `ai_features` | 個人、グループ、プロジェクト | GitLab Duo、コード提案API、およびGitLab Duo Chat APIのAPIアクションを実行する権限を付与します。JetBrains向けGitLab Duoプラグインと連携するように設計されています。その他のすべての拡張機能については、各拡張機能のドキュメントを参照してください。GitLab Self-Managedバージョン16.5、16.6、および16.7では動作しません。GitLab Self-ManagedおよびGitLab Dedicatedでは、このスコープはGitLab Duoが有効な場合にのみ利用できます。 |
| `k8s_proxy` | 個人、グループ、プロジェクト | Kubernetes向けのエージェントを介してKubernetes APIコールを実行する権限を付与します。 |
| `admin_mode` | 個人 | [管理者モード](../../administration/settings/sign_in_restrictions.md#admin-mode)が有効になっている場合にAPIアクションを実行する権限を付与します。GitLab Self-Managedインスタンスの管理者のみが使用できます。 |
| `read_service_ping` | 個人 | 管理者として認証されたときに、APIを介してService Pingペイロードをダウンロードするアクセス権を付与します。 |
| `sudo` | 個人 | 管理者として認証されている場合、システム内の任意のユーザーとしてAPIアクションを実行する権限を許可します。 |
| `read_user` | 個人 | `/user` APIエンドポイントを介して、認証済みユーザーのプロファイルへの読み取り専用アクセスを許可します。これには、ユーザー名、公開メール、および氏名が含まれます。また、[`/users`](../../api/users.md)の下にある読み取り専用APIエンドポイントへのアクセスも許可します。 |

> [!warning]
> [外部認可](../../administration/settings/external_authorization.md)をオンにしている場合、パーソナルアクセストークンとプロジェクトアクセストークンはコンテナまたはパッケージレジストリにアクセスできません。アクセスを復元するには、外部認可をオフにしてください。

**補足説明**: 

1. パーソナルアクセストークンの場合、`api`はGit-over-HTTPを介したレジストリとリポジトリへの完全な読み取りおよび書き込みアクセスも付与します。グループアクセストークンおよびプロジェクトアクセストークンには、このGit-over-HTTP句は含まれません。
1. パーソナルアクセストークンの場合、仮想レジストリのスコープは、プロジェクトがプライベートであり、認可が必要な場合にのみ適用されます。グループアクセストークンにはそのような条件はありません。

## 関連トピック {#related-topics}

- [パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)
- [グループアクセストークン](../../user/group/settings/group_access_tokens.md)
- [プロジェクトアクセストークン](../../user/project/settings/project_access_tokens.md)
- [トークンの概要](../../security/tokens/_index.md)
