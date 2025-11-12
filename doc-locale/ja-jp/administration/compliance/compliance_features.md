---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 管理者向けのコンプライアンス機能
description: コンプライアンスセンター、監査イベント、セキュリティポリシー、コンプライアンスフレームワーク。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

管理者向けのGitLabコンプライアンス機能は、お使いのGitLabインスタンスが一般的なコンプライアンス標準を満たすようにします。多くの機能は、グループやプロジェクトでも利用できます。

## コンプライアンスに準拠したワークフローの自動化 {#compliant-workflow-automation}

コンプライアンスチームが、自分たちの管理と要件が正しく設定されているだけでなく、正しく設定された状態を維持していることを確信することは重要です。これを行う1つの方法は、定期的に設定を手動で確認することですが、これはエラーが発生しやすく、時間がかかります。より良いアプローチは、信頼できる唯一の情報源である設定と自動化を使用して、コンプライアンスチームが構成したものが何であれ、構成された状態を維持し、正しく動作するようにすることです。これらの機能は、コンプライアンスの自動化に役立ちます:

| 機能                                                                                                                                       | インスタンス                             | グループ                               | プロジェクト                              | 説明 |
|:----------------------------------------------------------------------------------------------------------------------------------------------|:--------------------------------------|:-------------------------------------|:--------------------------------------|:------------|
| [マージリクエスト承認ポリシーの承認設定](../../user/application_security/policies/merge_request_approval_policies.md#approval_settings) | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | 複数の承認者を強制し、GitLabインスタンスまたはグループ全体のすべての強制グループまたはプロジェクトで、さまざまなプロジェクト設定をオーバーライドするマージリクエスト承認ポリシーを適用します。 |

## 監査イベント管理 {#audit-management}

あらゆるコンプライアンスプログラムの重要な部分は、何が起こったのか、いつ起こったのか、誰が責任者であったのかを遡って理解できることです。これは、監査イベントの状況だけでなく、問題が発生した場合に根本原因を理解するためにも使用できます。

低レベルのrawな監査イベントデータの一覧と、高レベルの監査イベントデータの要約一覧の両方があると便利です。これら2つを組み合わせることで、コンプライアンスチームは問題が存在するかどうかを迅速に特定し、それらの問題の特定にドリルダウンできます。これらの機能は、GitLabへの可視性を提供し、何が起こっているかを監査イベントするのに役立ちます:

| 機能                                                  | インスタンス                            | グループ                               | プロジェクト                             | 説明 |
|:---------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [監査イベント](audit_event_reports.md)                   | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | コードの整合性を維持するために、監査イベントを使用すると、管理者は高度な監査イベントシステムでGitLabサーバーで行われた変更を表示できるため、すべての変更を制御、分析、追跡できます。 |
| [監査イベントレポート](audit_event_reports.md)                  | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | 発生した監査イベントに基づいて、レポートを作成してアクセスします。事前構築済みのGitLabレポートまたはAPIを使用して、独自のレポートをビルドします。 |
| [監査イベントストリーミング](audit_event_streaming.md) | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | GitLab監査イベントをHTTPエンドポイントまたはAWS S3やGCP Loggingなどのサードパーティサービスにストリーミングします。 |
| [監査担当者ユーザー](../auditor_users.md)                        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}不可 | 監査担当者ユーザーは、GitLabインスタンス上のすべてのプロジェクト、グループ、およびその他のリソースへの読み取り専用アクセス権を付与されたユーザーです。 |

## ポリシー管理 {#policy-management}

組織には、組織標準または規制機関からの指示により、固有のポリシー要件があります。以下の機能は、ワークフロー要件、職務分離、および安全なサプライチェーンのベストプラクティスを遵守するためのルールとポリシーを定義するのに役立ちます:

| 機能                                                                       | インスタンス                            | グループ                               | プロジェクト                             | 説明 |
|:------------------------------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [認証情報インベントリ](../credentials_inventory.md)                             | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}不可 | GitLabインスタンス内のすべてのユーザーが使用する認証情報を追跡します。 |
| [詳細なユーザーロール<br/>と柔軟な権限](../../user/permissions.md)    | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | 5つの異なるユーザーロールと外部ユーザーの設定を使用して、アクセスと権限を管理します。リポジトリへの読み取りまたは書き込みアクセスではなく、ユーザーのロールに応じて権限を設定します。イシュートラッカーへのアクセスのみを必要とするユーザーとコードを共有しないでください。 |
| [マージリクエストの承認](../../user/project/merge_requests/approvals/_index.md) | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | マージリクエストに必要な承認を構成します。 |
| [プッシュルール](../../user/project/repository/push_rules.md)                        | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | リポジトリへのプッシュを制御します。 |
| [セキュリティポリシー](../../user/application_security/policies/_index.md)。          | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | ポリシーのルールに基づいてマージリクエストの承認を要求するか、コンプライアンス要件のためにプロジェクトパイプラインで実行するセキュリティスキャナーを強制する、カスタマイズ可能なポリシーを構成します。ポリシーは、特定のプロジェクト、またはグループまたはサブグループ内のすべてのプロジェクトに対して、細かく適用できます。 |

## その他のコンプライアンス機能 {#other-compliance-features}

これらの機能は、コンプライアンス要件にも役立ちます:

| 機能                                                                                                                         | インスタンス                            | グループ                               | プロジェクト                             | 説明 |
|:--------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [プロジェクトのすべてのユーザーにメールを送信するか、<br/>グループ、またはサーバー全体](../email_from_gitlab.md)                                               | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}不可 | プロジェクトまたはグループメンバーシップに基づいてユーザーのグループにメールを送信するか、GitLabインスタンスを使用しているすべての人にメールを送信します。これらのメールは、スケジュールされたメンテナンスやアップグレードに最適です。 |
| [利用規約の承諾を強制する](../settings/terms.md)                                                                                     | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}不可 | GitLabトラフィックをブロックすることにより、新しい利用規約を受け入れるようにユーザーに強制します。 |
| [権限に関するレポートを生成する<br/>ユーザーのレベル](../admin_area.md#user-permission-export)                                      | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}不可 | インスタンス内のグループとプロジェクトに対するすべてのユーザーのアクセス許可を一覧表示するレポートを生成します。 |
| [LDAPグループ同期](../auth/ldap/ldap_synchronization.md#group-sync)。                                                                 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}不可 | グループを自動的に同期し、SSHキー、権限、および認証を管理するため、ツールを構成するのではなく、製品のビルドに集中できます。 |
| [LDAPグループ同期フィルター](../auth/ldap/ldap_synchronization.md#group-sync)                                                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}不可 | フィルターに基づいてLDAPとの同期をより柔軟に行えるため、LDAP属性を活用してGitLabの権限をマップできます。 |
| [Linuxパッケージのインストールをサポート<br/>ログ転送](https://docs.gitlab.com/omnibus/settings/logs.html#udp-log-forwarding) | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}不可 | ログを中央システムに転送します。 |
| [SSHキーを制限する](../../security/ssh_keys_restrictions.md)                                                                       | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}不可 | GitLabへのアクセスに使用されるSSHキーのテクノロジーとキー長を制御します。 |

## 関連トピック {#related-topics}

- [GitLabによるソフトウェアコンプライアンス](https://about.gitlab.com/solutions/compliance/)
- [GitLabを保護する](../../security/_index.md)
- [ユーザー向けのコンプライアンス機能](../../user/compliance/_index.md)
