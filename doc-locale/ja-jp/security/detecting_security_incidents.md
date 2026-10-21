---
stage: Security
group: Security Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: セキュリティインシデントの検知
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

潜在的なセキュリティインシデントを早期に検知するほど、その影響を抑えることができます。

GitLab Security Operationsチームは、GitLab Self-Managedインスタンスの管理者とメンテナー、およびGitLab.com上のグループ向けにこれらの推奨事項を作成しました。これらを使用して、GitLabにおけるセキュリティ関連のアクティビティの検知範囲を構築し、潜在的なセキュリティインシデントを示すシグナルを認識してください。これらは、組織が定義する検知およびモニタリングプロセスを補完するものであり、それらを置き換えるものではありません。

インシデントを確認した場合は、[セキュリティインシデントへの対応](responding_to_security_incidents.md)に従って、封じ込めと修正を行ってください。

> [!warning]
> これらの提案や推奨事項は、自己責任で使用してください。検知範囲は、設定、サブスクリプションのプラン、および環境内のログおよびモニタリングツールによって異なります。

## 検知能力を構築する {#build-a-detection-capability}

効果的な検知には、信頼できるデータソース、それらを分析するための中央拠点、生のアクティビティを実用的なアラートに変換する調整されたルールを組み合わせます。

### 検知データソース {#detection-data-sources}

GitLabは、不審なアクティビティを検知するために使用できる、セキュリティに関連するデータのソースをいくつか生成します:

| データソース | 利用可否設定 | 表示内容 |
|-------------|--------------|---------------|
| [監査イベント](../administration/compliance/audit_event_reports.md) | Premium、Ultimate | 認証、権限の変更、プロジェクト、グループ、設定への変更。GitLabでセキュリティインシデントを検知するための主要なソースです。完全なリストについては、[監査イベントタイプ](../user/compliance/audit_event_types.md)を参照してください。 |
| [サインイン監査イベント](../user/compliance/audit_events.md#sign-in-audit-events) | すべてのプラン | ユーザープロフィールの**認証ログ**に表示される、ユーザーの成功したサインイン。 |
| [システムログ](../administration/logs/_index.md) | すべてのプラン、GitLab Self-Managedのみ | アプリケーション、API、認証、Workhorseのログ。[相関ID](../administration/logs/tracing_correlation_id.md)を使用して、複数のログにまたがる単一のリクエストをトレースできます。 |
| [CI/CDジョブログ](../ci/jobs/job_logs.md) | すべてのプラン | 攻撃者によって開始された、公開されたシークレット、予期しないコマンド、またはパイプラインのアクティビティ。 |
| [認証情報インベントリ](../administration/credentials_inventory.md) | Ultimate | インスタンスまたはトップレベルグループに存在する、パーソナル、グループ、プロジェクトのアクセストークン、SSHキー、GPGキー。 |
| [シークレットプッシュ保護](../user/application_security/secret_detection/secret_push_protection/_index.md)および[シークレット検出](../user/application_security/secret_detection/_index.md) | シークレットプッシュ保護: Ultimate。パイプラインのシークレット検出: 全プラン。 | ユーザーがプッシュしようとした、またはリポジトリにコミットされたシークレット。 |

各ソースに含まれる内容と、各提供形態およびサブスクリプションのプランでの収集方法については、[セキュリティテレメトリー](security_telemetry.md)を参照してください。

予期しない場所からのサインインや2要素認証への変更など、不審な認証を検知するには、[システムアクセス監査イベント](../user/compliance/audit_event_types.md#system-access)を確認してください。

### イベントを集約してSIEMにストリーミングする {#centralize-and-stream-events-to-a-siem}

インシデントをほぼリアルタイムで検知し、調査のためにイベントを保持するには、データをセキュリティ情報イベント管理（SIEM）システムまたは他のログ分析プラットフォームに集約してください:

- 監査イベントを外部の宛先にストリーミングします。
  - GitLab Self-ManagedおよびGitLab Dedicated: [インスタンスの監査イベントストリーミング](../administration/compliance/audit_event_streaming.md) 
  - GitLab.com: [トップレベルグループの監査イベントストリーミング](../user/compliance/audit_event_streaming.md)
- イベントをストリーミングしない場合は、[監査イベントAPI](../api/audit_events.md)を使用してスケジュールに基づいて収集できます。
- 攻撃者がログやイベントを改ざんしたり削除したりできないように、独立した書き込み一回限り（イミュータブル）のデータストアにルーティングしてください。
- データが必要になる前に、調査およびコンプライアンスの要件を満たす保持期間を定義してください。

### GitLabの検知ルールを使用する {#use-the-gitlab-detection-rules}

GitLab Security Operationsチームは、GitLab環境向けのオープンソースの検知フレームワークである[TLDR](https://gitlab.com/gitlab-security-oss/tldr)（Threat、Logs、Detection、Respond）を保守しています。

各TLDRの検知には、さまざまな情報が含まれています:

- 脅威の詳細: 脅威の説明、およびその技術的ビジネス上の影響。
- ログ: 検知に必要なログソースと、サンプルイベント。
- 検知: 一般的な[Sigma](https://github.com/SigmaHQ/sigma)形式のルールと、SIEMを使用していない環境向けの生のログクエリ。
- アトミックテスト: アクティビティを再現する手順。これにより、検知が発動することを確認できます。
- レスポンス: 真陽性を処理する方法に関するガイダンス。

検知は2つのタイプに分類されます:

- 脅威検知: 無効化された2要素認証、新しい管理者アカウント、新しいデプロイキーまたはプロジェクトアクセストークン、マージリクエストの承認や保護ブランチ設定への変更など、監査イベントに記録された不審または悪意のあるアクティビティ。

- 脆弱性検知: アプリケーションログに記録された、GitLab Self-Managedの既知の脆弱性を悪用しようとする試み。

これらの検知を使用するには:

1. 各検知に記載されているログソースをSIEMにインジェストします。
1. SigmaルールをSIEMのクエリ言語に変換します。公式の[Sigma CLI](https://github.com/SigmaHQ/sigma-cli)、またはWebベースの[sigconverter.io](https://sigconverter.io/)を使用します。
1. 最初にモニタリングのみのモードで変換されたルールをデプロイし、アラート量を確認します。
1. アラートをオンコール対応者にルーティングする前に、環境に合わせてルールを調整します。

### カバレッジをマッピングして検知を調整する {#map-coverage-and-tune-detections}

検知をデプロイした後は、正確性を維持し、組織にとって重要な脅威をカバーできるよう、定期的に見直してください:

- 検知を[MITRE ATT&CK](https://attack.mitre.org/)のようなフレームワークにマッピングし、検知可能な攻撃手法とギャップがある部分を把握してください。
- アラートが意味のある逸脱に焦点を当てるように、環境内の通常のアクティビティをベースライン化してください。
- 重大度の高いアラートの信頼性を維持できるよう、ノイズの多いルールを調整してください。
- 各検知が期待どおりに発動することをテストし、各ルールの期待される動作を文書化してください。各TLDR検知には、これに使用できるアトミックテストが含まれています。

## シナリオ別の検知対象 {#what-to-detect-by-scenario}

以下のシナリオのほとんどは、インシデント対応における[一般的なセキュリティインシデントシナリオ](responding_to_security_incidents.md#common-security-incident-scenarios)と一致しています。各シナリオについて、記載されているシグナルをモニタリングしてください。検知が発動してインシデントを確認したら、リンクされている対応手順に従ってください。

次の表は、各シナリオをMITRE ATT&CK技術の例にマッピングしています。これらのマッピングを出発点として使用し、自社の脅威モデルに合わせて調整してください。

| シナリオ | 主なシグナル | MITRE ATT&CK技術の例 |
|----------|-------------|---------------------------------|
| [認証情報の漏えいとトークンの悪用](#credential-exposure-and-token-abuse) | 新しいトークン、キー、またはユーザー、およびCI/CD変数の変更 | T1552 Unsecured Credentials、T1078 Valid Accounts、T1136 Create Account |
| [侵害されたユーザーアカウント](#compromised-user-account) | 異常なサインイン、2要素認証の変更、新しいOAuthアプリケーション | T1078 Valid Accounts、T1110 Brute Force、T1098 Account Manipulation、T1556 Modify Authentication Process |
| [CI/CDの悪用](#cicd-abuse) | パイプライン設定、変数、またはRunnerの変更 | T1195.002 Compromise Software Supply Chain、T1552 Unsecured Credentials |
| [侵害されたインスタンス](#compromised-instance) | 新しい管理者、rootユーザーのアクティビティ、ホストインジケーター | T1078 Valid Accounts、T1098 Account Manipulation、T1136 Create Account |
| [誤って設定されたプロジェクトまたはグループの設定](#misconfigured-project-or-group-settings) | 表示レベル、承認、保護ブランチの変更 | T1685 Disable or Modify Tools、T1485 Data Destruction |
| [データの流出](#data-exfiltration) | 大量のクローン、プロジェクトのエクスポート、新しいデプロイキーまたはトークン | T1213.003 Code Repositories、T1567 Exfiltration Over Web Service |
| [悪用とリソースの不正使用](#abuse-and-resource-misuse) | コンピューティングの急増、新しいアカウントの急増、過剰なGit操作 | T1496 Resource Hijacking、T1136 Create Account |

### 認証情報の漏えいとトークンの悪用 {#credential-exposure-and-token-abuse}

トークン、キー、またはその他の認証情報が漏えいまたは悪用されたことを示唆するアクティビティに注意してください:

- パーソナル、プロジェクト、またはグループのアクセストークンの作成（特に予期しないユーザーによるもの）。
- SSHキーまたはGPGキーの作成。
- 攻撃者が永続性を維持するために使用する可能性のある、新しいユーザーアカウントの作成。
- [CI/CD変数](../ci/variables/_index.md)、またはシークレットを保存する他の設定への変更。[継続的インテグレーション監査イベント](../user/compliance/audit_event_types.md#continuous-integration)に注目してください。
- 予期しないユーザーによって実行されたパイプライン。詳細は[ジョブログ](../administration/cicd/job_logs.md)を確認してください。

対応するには、[パブリックインターネットへの認証情報の漏えい](responding_to_security_incidents.md#credential-exposure-to-public-internet)を参照してください。

### 侵害されたユーザーアカウント {#compromised-user-account}

アカウントがその所有者以外の誰かによって使用されていることを示すシグナルに注意してください:

- 予期しないIPアドレス、場所、デバイスからのものなど、不審なサインインイベント。
- パーソナル、プロジェクト、またはグループのアクセストークンの作成または削除。
- SSHキーまたはGPGキーの作成または削除。
- 2要素認証設定への変更。
- メールアドレスまたは通知設定への変更。
- 認可されたOAuthアプリケーションの追加または変更。
- 接続されたSAML IDプロバイダーへの変更。

対応するには、[侵害が疑われるユーザーアカウント](responding_to_security_incidents.md#suspected-compromised-user-account)を参照してください。

### CI/CDの悪用 {#cicd-abuse}

シークレットを漏えいさせたり、攻撃者がパイプラインでコードを実行できるようにしたりする可能性のある変更に注意してください:

- CI/CD設定ファイルまたはパイプライン定義への変更。
- [マスキング](../ci/variables/_index.md#mask-a-cicd-variable)や保護設定を含む、CI/CD変数への変更。
- パイプラインまたはジョブアーティファクトを公開アクセス可能にする変更。
- 新しいRunnerの登録、または既存のRunnerへの変更。
- [CI/CDジョブトークン](../ci/jobs/ci_job_token.md#gitlab-cicd-job-token-security)の予期しない使用。

対応するには、[CI/CD関連のセキュリティインシデント](responding_to_security_incidents.md#cicd-related-security-incidents)を参照してください。

### 侵害されたインスタンス {#compromised-instance}

GitLab Self-Managedの場合、インスタンスレベルおよびホストレベルのシグナルに注意してください:

- システム設定、ユーザー権限、またはサインインイベントへの変更を示すシステムアクセス監査イベント。
- 新しい管理者アカウントの作成、または管理者権限を持つrootユーザーによるアクティビティ。
- 認識されていないバックグラウンドプロセス、予期しない開いているポート、または異常なネットワークトラフィックなどのホストレベルのインジケーター。

対応するには、[侵害が疑われるインスタンス](responding_to_security_incidents.md#suspected-compromised-instance)を参照してください。

### 誤って設定されたプロジェクトまたはグループの設定 {#misconfigured-project-or-group-settings}

データを公開したり、アクセス制御を弱めたりする可能性のある変更に注意してください:

- プロジェクトまたはグループの表示レベルへの変更。
- マージリクエストの承認設定への変更。
- プロジェクトの削除。
- 不審なWebhookまたは[サーバーフック](../administration/server_hooks.md)の追加。
- 保護ブランチ設定への変更。

`target_type`フィールドで監査イベントをフィルタリングして検索を絞り込み、[コンプライアンス管理](../user/compliance/audit_event_types.md#compliance-management)および[グループとプロジェクト](../user/compliance/audit_event_types.md#groups-and-projects)の監査イベントを確認してください。

対応するには、[誤って設定されたプロジェクトまたはグループの設定](responding_to_security_incidents.md#misconfigured-project-or-group-settings)を参照してください。

### データの流出 {#data-exfiltration}

ソースコードやその他のデータがGitLabからコピーされて持ち出されている兆候に注意してください。多くの場合、攻撃者が侵害されたアカウントやトークンを通じてアクセスを取得した後に発生します:

- 短期間に単一のユーザーまたはトークンによる多数のリポジトリのダウンロードまたはクローン。
- プロジェクトまたはグループのエクスポート、およびエクスポートファイルのダウンロード（特に通常これらを実行しないユーザーによるもの）。
- リポジトリへの長期的なアクセスを許可する、新しいデプロイキーまたはデプロイトークン。
- 予期しないユーザーによるジョブアーティファクトのダウンロード。
- プライベートなプロジェクトやグループを公開する変更。
- 以前に見られなかったIPアドレスから使用されたパーソナルアクセストークン。

対応するには、[パブリックインターネットへの認証情報の漏えい](responding_to_security_incidents.md#credential-exposure-to-public-internet)の手順に従って関連する認証情報を失効させ、組織が定義するインシデント対応プロセスに従ってください。

### 悪用とリソースの不正使用 {#abuse-and-resource-misuse}

CI/CDでの暗号通貨マイニングなど、自動化された悪用やリソースの予期しない消費に注意してください:

- パイプラインのアクティビティ、コンピューティング時間、または新しいRunner登録の急増。
- 新しいアカウント作成の急増。
- 過剰なGit操作。Ultimateでは、[Gitの悪用レート制限](../user/group/reporting/git_abuse_rate_limit.md)を設定して、これらのパターンの一部を自動的に軽減できます。

対応するには、組織が定義するインシデント対応プロセスに従い、[強化に関する推奨事項](hardening.md)を確認してください。

## 検知が発動した場合 {#when-a-detection-fires}

検知がアラートをトリガーした場合は、トリアージを行い、セキュリティインシデントが進行中かどうかを確認してください:

1. 証拠を保全します。後の調査のために、関連するログと監査イベントを書き込み一回限りの場所に保存します。
1. 影響を受けたユーザー、プロジェクト、グループ、トークン、またはホストなど、範囲を特定します。
1. 一致するシナリオからリンクされている対応手順に従って、インシデントを封じ込め、修正します。
1. 組織が定義するインシデント対応プロセスに従います。

## サポートについてGitLabに問い合わせる {#engaging-gitlab-for-assistance}

GitLabにヘルプを依頼する前に、[GitLabドキュメント](https://docs.gitlab.com)を検索してください。予備調査を完了した後も疑問がある場合や支援が必要な場合は、GitLabサポートにお問い合わせください。GitLabサポートからの支援を受ける資格は、[お使いのライセンスによって決まります](https://support.gitlab.com/hc/en-us/articles/11626483177756-GitLab-Support#gitlab-support-service-levels)。

## 関連トピック {#related-topics}

- [セキュリティインシデント](security_incidents.md)
- [セキュリティテレメトリー](security_telemetry.md)
- [GitLabを保護する](_index.md)
- [監査イベントタイプ](../user/compliance/audit_event_types.md)
