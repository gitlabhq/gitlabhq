---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザー向けのコンプライアンス機能
description: コンプライアンス機能。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ユーザー向けのGitLabコンプライアンス機能を使用すると、GitLabのグループとプロジェクトが一般的なコンプライアンス標準を満たすようになります。

## コンプライアンスに準拠したワークフローの自動化 {#compliant-workflow-automation}

コンプライアンスチームが、自分たちの管理と要件が正しく設定されているだけでなく、正しく設定された状態を維持していることを確信することは重要です。これを行う1つの方法は、定期的に設定を手動で確認することですが、これはエラーが発生しやすく、時間がかかります。より良いアプローチは、信頼できる唯一の情報源である設定と自動化を使用して、コンプライアンスチームが構成したものが何であれ、構成された状態を維持し、正しく動作するようにすることです。これらの機能は、コンプライアンスの自動化に役立ちます:

| 機能                                                                                                                                  | インスタンス                            | グループ                               | プロジェクト                             | 説明 |
|:-----------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [コンプライアンスフレームワーク](compliance_frameworks/_index.md)                                                                      | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | プロジェクトが従う必要のあるコンプライアンス要件の種類について説明します。 |
| [コンプライアンスパイプライン](compliance_pipelines.md)                                                                                 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | 特定のコンプライアンスフレームワークを持つプロジェクトに対して実行するパイプライン設定を定義します。 |
| [マージリクエスト承認ポリシーの承認設定](../application_security/policies/merge_request_approval_policies.md#approval_settings) | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | 複数の承認者を強制し、GitLabインスタンスまたはグループ全体のすべての強制グループまたはプロジェクトで、さまざまなプロジェクト設定をオーバーライドするマージリクエスト承認ポリシーを適用します。 |

## 監査イベント管理 {#audit-management}

あらゆるコンプライアンスプログラムの重要な部分は、何が起こったのか、いつ起こったのか、誰が責任者であったのかを遡って理解できることです。これは、監査イベントの状況だけでなく、問題が発生した場合に根本原因を理解するためにも使用できます。

低レベルのrawな監査イベントデータの一覧と、高レベルの監査イベントデータの要約一覧の両方があると便利です。これら2つを組み合わせることで、コンプライアンスチームは問題が存在するかどうかを迅速に特定し、それらの問題の特定にドリルダウンできます。これらの機能は、GitLabへの可視性を提供し、何が起こっているかを監査イベントするのに役立ちます:

| 機能                                           | インスタンス                            | グループ                               | プロジェクト                             | 説明 |
|:--------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [監査イベント](audit_events.md)                   | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | コードの整合性を維持するために、監査イベントを使用すると、管理者は高度な監査イベントシステムでGitLabサーバーで行われた変更を表示できるため、すべての変更を制御、分析、追跡できます。 |
| [監査イベントレポート](audit_events.md)                  | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | 発生した監査イベントに基づいて、レポートを作成してアクセスします。事前構築済みのGitLabレポートまたはAPIを使用して、独自のレポートをビルドします。 |
| [監査イベントストリーミング](audit_event_streaming.md) | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | GitLab監査イベントをHTTPエンドポイントまたはAWS S3やGCP Loggingなどのサードパーティサービスにストリーミングします。 |
| [コンプライアンスセンター](compliance_center/_index.md)  | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | コンプライアンス標準の遵守状況のレポートと違反レポートを通じて、組織のコンプライアンス体制を迅速に可視化します。グループのコンプライアンスフレームワークを一元的に管理します。 |

## ポリシー管理 {#policy-management}

組織には、組織標準または規制機関からの指示により、固有のポリシー要件があります。以下の機能は、ワークフロー要件、職務分離、および安全なサプライチェーンのベストプラクティスを遵守するためのルールとポリシーを定義するのに役立ちます:

| 機能                                                                                                                                                                                                                                                                | インスタンス                            | グループ                               | プロジェクト                             | 説明 |
|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [詳細なユーザーロール<br/>と柔軟な権限](../permissions.md)                                                                                                                                                                                                  | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | 5つの異なるユーザーロールと外部ユーザーの設定を使用して、アクセスと権限を管理します。リポジトリへの読み取りまたは書き込みアクセスではなく、ユーザーのロールに応じて権限を設定します。イシュートラッカーへのアクセスのみを必要とするユーザーとコードを共有しないでください。 |
| [マージリクエストの承認](../project/merge_requests/approvals/_index.md)                                                                                                                                                                                               | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | マージリクエストに必要な承認を構成します。 |
| [プッシュルール](../project/repository/push_rules.md)                                                                                                                                                                                                                      | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | リポジトリへのプッシュを制御します。 |
| 職務分離の利用<br/>[保護ブランチ](../project/repository/branches/protected.md#require-code-owner-approval)の使用<br/>[カスタムCI/CD構成パス](../../ci/pipelines/settings.md#specify-a-custom-cicd-configuration-file) | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 | GitLabクロスプロジェクトのYAML設定を活用して、コードのデプロイヤーとコードのデベロッパーを定義します。[職務分離デプロイプロジェクト](https://gitlab.com/guided-explorations/separation-of-duties-deploy/blob/master/README.md)および[職務分離プロジェクト](https://gitlab.com/guided-explorations/separation-of-duties/blob/master/README.md)で、この設定を使用してこれらのロールを定義する方法をご覧ください。 |
| [セキュリティポリシー](../application_security/policies/_index.md)                                                                                                                                                                                                        | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | ポリシーのルールに基づいてマージリクエストの承認を要求するか、コンプライアンス要件のためにプロジェクトパイプラインで実行するセキュリティスキャナーを強制する、カスタマイズ可能なポリシーを構成します。ポリシーは、特定のプロジェクト、またはグループまたはサブグループ内のすべてのプロジェクトに対して、細かく適用できます。 |

## その他のコンプライアンス機能 {#other-compliance-features}

これらの機能は、コンプライアンス要件にも役立ちます:

| 機能                                                                                                                        | インスタンス                            | グループ                               | プロジェクト                             | 説明 |
|:-------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------|:-------------------------------------|:-------------------------------------|:------------|
| [外部ステータスチェック](../project/merge_requests/status_checks.md)                                                           | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 | 開発中に既に使用しているサードパーティシステムとインターフェースをとり、コンプライアンスを維持できるようにします。 |
| [ライセンス承認ポリシー](license_approval_policies.md)                                                                      | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 | 依存関係にあるもののライセンスを検索します。これにより、プロジェクトの依存関係にあるもののライセンスが、プロジェクトのライセンスと互換性があるかどうかを判断できます。 |
| [プロジェクトメンバーシップをグループにロック](../group/access_and_permissions.md#prevent-members-from-being-added-to-projects-in-a-group) | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | グループオーナーは、新しいメンバーがグループ内のプロジェクトに追加されないようにすることができます。 |

## 関連トピック {#related-topics}

- [GitLabによるソフトウェアコンプライアンス](https://about.gitlab.com/solutions/compliance/)
- [GitLabを保護する](../../security/_index.md)
- [管理者向けのコンプライアンス機能](../../administration/compliance/compliance_features.md)
