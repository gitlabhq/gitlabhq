---
stage: Release Notes
group: Monthly Release
date: 2023-06-22
title: "GitLab 16.1リリースノート"
description: "GitLab 16.1が全く新しいナビゲーションエクスペリエンスと共にリリースされました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023年6月22日、GitLab 16.1は以下の機能を備えてリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター {#this-months-notable-contributor}

Gerardoは、[ジョブトークンスコープのREST APIエンドポイント](https://gitlab.com/gitlab-org/gitlab/-/issues/351740)を提供するために、複数回のリリースにわたって一貫してイテレーションを重ねてきました。イテレーションはGitLabの[コアバリュー](https://handbook.gitlab.com/handbook/values/#iteration)の1つであり、Gerardoは機能を提供するための複数のコントリビュートでそれを実証しました。

[デフォルトの`CI_JOB_TOKEN`動作](../../update/deprecations.md)の変更により、プロジェクトの作成を自動化するユーザーは、そのプロジェクトで`CI_JOB_TOKEN`の使用を許可されたプロジェクトの追加も自動化できなくなりました。このREST APIエンドポイントにより、お客様は再びこのプロセスを自動化し、より安全な`CI_JOB_TOKEN`ワークフローの採用を促進できます。

GerardoとSiemensのクルーの皆様、ありがとうございます！

Yuriは6年前に記録された[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/18287)を拾い上げ、[行動への偏り](https://handbook.gitlab.com/handbook/values/#bias-for-action) (GitLabの価値観の1つ) を示し、修正にコントリビュートしました。

これは多くの顧客が関心を持っていた人気のある機能でした。この機能強化により、システム管理者は、グループまたはプロジェクトのパスのコンマ区切りリストに基づいて、バックアップと復元中に特定のプロジェクトをスキップできます。この機能により、システム管理者は、バックアップ実行中に古いプロジェクトやアーカイブされたプロジェクトをスキップし、ストレージスペースを節約してバックアップを高速化できます。同じオプションを使用して、バックアップから復元する際に特定のプロジェクトを除外することもできます。

Yuriの貴重なコントリビュートに感謝します！

## 主要な機能 {#primary-features}

### 全く新しいナビゲーションエクスペリエンス {#all-new-navigation-experience}

<!-- categories: Navigation & Settings -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../tutorials/left_sidebar/_index.md)

{{< /details >}}

GitLab 16.1には、全く新しいナビゲーションエクスペリエンスが搭載されています！このエクスペリエンスは、すべてのユーザーに対してデフォルトで有効になっています。開始するには、UIの右上にあるアバターに移動し、**New navigation**切替をオンにします。

新しいナビゲーションは、GitLabのナビゲートが煩雑であること、作業の中断箇所から再開するのが難しいこと、ナビゲーションをカスタマイズできないことという3つの主要なフィードバック領域を解決するために設計されました。

新しいナビゲーションには、合理化され改善された左サイドバーが含まれており、次のことができます:

- 頻繁にアクセスするアイテムを📌ピン留めします。
- サイドバーを完全に非表示にし、「必要に応じて一時的に」表示させます。
- 新しい**Your Work**および**検索**オプションを使用すると、コンテキストの切り替え、検索、およびデータのサブセットの表示を簡単に行うことができます。
- トップレベルのメニュー項目が減ったため、より迅速にスキャンできます。

この新しいナビゲーションを誇りに思っており、皆様のご意見を伺うのが楽しみです。[変更点のリスト](https://gitlab.com/groups/gitlab-org/-/epics/9044#whats-different)を確認し、ナビゲーションの[ビジョン](https://about.gitlab.com/blog/gitlab-product-navigation/)と[デザイン](https://about.gitlab.com/blog/overhauling-the-navigation-is-like-building-a-dream-home/)に関するブログ投稿をお読みください。

新しいナビゲーションを試して、[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/409005)であなたの経験についてお知らせください。すでに[フィードバック](https://gitlab.com/gitlab-org/gitlab/-/issues/409005#actions-we-are-taking-from-the-feedback)にフィードバックしており、最終的には切替を削除します。

### GitLabでKubernetesリソースを視覚化する {#visualize-kubernetes-resources-in-gitlab}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390769)

{{< /details >}}

あなたのクラスターで実行されているアプリケーションのステータスをどのように確認しますか？パイプラインステータスと環境ページは、最新のデプロイ実行に関するインサイトを提供します。しかし、以前のバージョンのGitLabでは、あなたのデプロイの状態に関するインサイトが不足していました。GitLab 16.1では、Kubernetesデプロイにおける主要なリソースの概要を確認できます。

この機能は、接続されているすべてのKubernetesクラスターで動作します。あなたがCI/CDのインテグレーションまたはGitOpsを使用してワークロードをデプロイするかどうかは問題ありません。Fluxユーザー向けの機能をさらに改善するため、環境の同期ステータス表示のサポートが[イシュー391581](https://gitlab.com/gitlab-org/gitlab/-/issues/391581)で提案されています。

### サービスアカウントで認証する {#authenticate-with-service-accounts}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/groups.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/6777)

{{< /details >}}

人間ではないユーザーが認証する必要がある多くのユースケースがあります。以前は、目的のスコープに応じて、ユーザーはパーソナルアクセストークン、プロジェクトアクセストークン、またはグループアクセストークンを使用してこのニーズを満たすことができました。これらのトークンは、人間に関連付けられている（パーソナルアクセストークンの場合）か、不必要に特権的なロール（グループアクセストークンおよびプロジェクトアクセストークンの場合）であるため、理想的ではありませんでした。

サービスアカウントは人間ユーザーに関連付けられておらず、スコープがよりきめ細かくなっています。サービスアカウントの作成と管理はAPIのみです。UIオプションのサポートは[イシュー9965](https://gitlab.com/groups/gitlab-org/-/epics/9965)で提案されています。

### GitLab Dedicatedが一般提供開始 {#gitlab-dedicated-is-now-generally-available}

<!-- categories: GitLab Dedicated -->

{{< details >}}

- プラン: Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../subscriptions/gitlab_dedicated/_index.md) | [関連イシュー](https://about.gitlab.com/dedicated/)

{{< /details >}}

GitLab Dedicatedは、厳格なコンプライアンス要件を持つ顧客のニーズに対応するために設計された、当社の包括的なDevSecOpsプラットフォームのフルマネージド型シングルテナントSaaSデプロイです。

規制の厳しい業界の顧客は、データ分離のような厳格なコンプライアンス要件のため、マルチテナントSaaS製品を採用できません。GitLab Dedicatedを使用すると、組織は高速なリリース、より優れたセキュリティ、より生産的なデベロッパーを含むDevSecOpsプラットフォームのすべてのメリットにアクセスしながら、データレジデンシー、分離、プライベートネットワーキングなどのコンプライアンス要件を満たすことができます。

今すぐGitLab Dedicatedについて[もっと詳しく](https://about.gitlab.com/dedicated/)。

### ジョブアーティファクトをアーティファクトページで管理する {#manage-job-artifacts-through-the-artifacts-page}

<!-- categories: Build Artifacts -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/jobs/job_artifacts.md#view-all-job-artifacts-in-a-project)

{{< /details >}}

以前は、ジョブアーティファクトを表示または管理するには、各ジョブの詳細ページに移動するか、APIを使用する必要がありました。これで、**ビルド > アーティファクト**からアクセスできる**アーティファクト**ページを通じて、ジョブアーティファクトを表示および管理できます。

メンテナーロール以上のユーザーは、この新しいインターフェースを使用してアーティファクトを削除することもできます。個々のアーティファクトを削除することも、手動選択またはページ上部の**すべて選択**オプションをチェックすることで、一度に最大100個のアーティファクトをまとめて削除することもできます。

この新しい機能に関するフィードバックを共有するために、アーティファクトページ上部のアンケートをご利用ください。検討中の追加のUI機能を表示するには、[Build Artifacts page enhancements epic](https://gitlab.com/groups/gitlab-org/-/epics/8311)を確認してください。

### 改善されたCI/CD変数のリスト表示 {#improved-cicd-variables-list-view}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/410383)

{{< /details >}}

CI/CD変数は、すべてのパイプラインの重要な部分であり、プロジェクトおよびグループの設定を含む複数の場所で定義できます。ユーザーが異なる階層の変数間を直感的にナビゲートできるようにする大きな改善に備えるため、変数リストの使いやすさとレイアウトの改善から着手しています。

GitLab 16.1では、これらの改善の最初のイテレーションが表示されます。「タイプ」列と「オプション」列を新しい**属性**列に統合しました。これにより、これらの関連する属性がよりよく表現されます。CI/CD変数エクスペリエンスの改善を継続する方法に関するフィードバックに感謝いたします。[変数改善エピック](https://gitlab.com/groups/gitlab-org/-/epics/10506)にコメントをいただければ幸いです。

## 規模とデプロイ {#scale-and-deployments}

### GitLabチャートの改善 {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/charts/)

{{< /details >}}

- GitLab 16.1は、`busybox` Dockerイメージを`gitlab-base` Dockerイメージに置き換え、他のGitLab Dockerイメージとレイヤーを共有します。この実装では、`gitlab-base`をヘルパーイメージ（`kubectl`や`certificates`など）として扱い、オプションでローカルオーバーライドできます。

### Omnibusの改善 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.1は、2023年6月10日にリリースされた[Debian 12 `Bookworm`](https://www.debian.org/releases/bookworm/)でのパッケージのビルドとリリースのサポートを追加します。

### ドメイン検証の改善 {#improved-domain-verification}

<!-- categories: User Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/enterprise_user/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/375492)

{{< /details >}}

ドメイン検証は、GitLab全体で複数の目的を果たします。以前は、ドメインを検証するには、GitLab Pages以外の目的でドメインを検証している場合でも、[GitLab Pages](../../user/project/pages/_index.md)ウィザードを完了する必要がありました。

現在、ドメイン検証はグループレベルで行われ、合理化されています。これにより、ドメインの検証が容易になります。

### 脆弱性レポートをカスタムロールの権限として表示 {#view-vulnerability-report-as-customizable-permission}

<!-- categories: System Access -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/permissions.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/10160)

{{< /details >}}

脆弱性レポートを表示する機能が別の権限に分割され、GitLabの管理者とグループのオーナーがこの権限を持つカスタムロールを作成できるようになりました。以前は、脆弱性レポートの表示はデベロッパーロール以上に限定されていました。これで、どのユーザーでも、その権限を持つカスタムロールが割り当てられていれば、脆弱性レポートを表示できます。

### 確認済みの任意のメールアドレスに送信されるパスワードリセットメール {#password-reset-email-sent-to-any-verified-email-address}

<!-- categories: User Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/user_passwords.md#change-your-password) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/16311)

{{< /details >}}

GitLabのパスワードを忘れた場合、検証済みの任意のメールアドレスを使用してメールでリセットできるようになりました。以前は、プライマリメールアドレスのみがリセットリクエストに使用されていました。これにより、プライマリメールの受信トレイにアクセスできない場合、パスワードリセットプロセスを完了することが困難になりました。

### ユーザーAPI応答に含まれるSCIM ID {#scim-identities-included-in-users-api-response}

<!-- categories: System Access, API -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/users.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/324247)

{{< /details >}}

ユーザーAPIは、ユーザーのSCIM IDを返すようになりました。以前は、この情報はUIには含まれていましたが、APIには含まれていませんでした。

### OmniAuth Shibbolethサポートの再導入 {#reintroduction-of-omniauth-shibboleth-support}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../integration/shibboleth.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/393065)

{{< /details >}}

Shibboleth OmniAuthサポートがGitLabに再導入されました。以前は、アップストリームサポートの不足によりGitLab 15.9で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/388959)されていました。アップストリームサポートを引き受けた[lukaskoenen](https://gitlab.com/lukaskoenen)からの寛大なコミュニティコントリビュートのおかげで、`omniauth-shibboleth-redux`がセルフマネージドGitLabでサポートされるようになりました。

### 管理者モードでパーソナルアクセストークンの管理者アクセスを選択 {#select-administrator-access-for-personal-access-tokens-in-admin-mode}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/profile/personal_access_tokens.md#personal-access-token-scopes) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/42692)

{{< /details >}}

GitLabの管理者は管理者モードを使用して非管理者ユーザーとして作業し、必要に応じて管理者アクセスを有効にすることができます。以前は、管理者のパーソナルアクセストークン（PAT）には、常に管理者としてAPIアクションを実行する権限がありました。これで、PATを追加する際に、管理者は管理者モードのスコープを選択することで、そのPATがAPIアクションを実行するための管理者アクセスを持つかどうかを決定できます。この機能を使用するには、管理者がインスタンスに対して管理者モードを有効にする必要があります。

[Jonas Wälter](https://gitlab.com/wwwjon) 、[Diego Louzán](https://gitlab.com/dlouzan) 、[Andreas Deicha](https://gitlab.com/TrueKalix)のコントリビュートに感謝します！

### ユーザーによるアカウント削除の防止 {#prevent-user-from-deleting-account}

<!-- categories: User Management -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/settings/account_and_limit_settings.md#prevent-users-from-deleting-their-accounts) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/26053)

{{< /details >}}

管理者は、新しいユーザー制限設定により、ユーザーがアカウントを削除できないようにすることができます。この設定が有効になっている場合、ユーザーはアカウントを削除できなくなり、監査可能なアカウント情報が保持されます。

### パーソナルアクセストークンの`last_used`値がより頻繁に更新されるようになりました {#personal-access-token-last_used-value-updated-more-frequently}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/personal_access_tokens.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/410168)

{{< /details >}}

パーソナルアクセストークン（PAT）の`last_used`値は、以前は24時間ごとに更新されていました。現在は10分ごとに更新されます。これにより、PATの使用状況の可視性が向上し、PATの侵害が発生した場合でも、悪意のある活動が認識されるまでの時間が短縮されるため、リスクが軽減されます。

[Jacob Torrey](https://thinkst.com/)様のごコントリビュートに感謝いたします！

### 完了したGitHubプロジェクトインポート概要のより詳細な情報 {#more-detail-in-completed-github-project-import-summary}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/import/github.md#check-status-of-imports) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/386748)

{{< /details >}}

GitHubプロジェクトのインポートが完了すると、GitLabはインポートされたエンティティの簡単な概要を表示していました。しかし、GitLabはどのGitHubエンティティのインポートが失敗したか、またインポートの失敗を引き起こしたエラーを正確には表示しませんでした。このため、インポート結果が満足のいくものかどうかを判断することが困難でした。

今回のリリースでは、インポート概要を拡張し、インポートされなかったGitHubエンティティのリストを含め、可能であればGitHub上のこれらのエンティティへの直接リンクを提供するようにしました。GitLabは、各失敗に対してエラーも表示するようになりました。これにより、インポートがどれほどうまく機能したかを理解し、問題のトラブルシューティングを行うのに役立ちます。

### サービスデスクのイシューで外部ユーザーをコメント作成者として表示 {#show-external-user-as-a-comment-author-in-service-desk-issues}

<!-- categories: Service Desk -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/service_desk/_index.md)

{{< /details >}}

リクエスタがサービスデスクのメールに返信すると、サービスデスクのエージェントにとって誰がコメントしたかを知ることは有用です。しかし、リクエスタはGitLabアカウントを持たない外部ユーザーであるか、GitLabプロジェクトへのアクセス権を持たない可能性があるため、これらのコメントは以前はGitLabサポートボットに帰属していました。今後は、リクエスタからのメール返信は外部ユーザーに帰属するようになり、GitLabのイシューで誰がコメントしたかがより明確になります。

### サービスデスクのメールでのイシューURLプレースホルダー {#issue-url-placeholder-in-service-desk-emails}

<!-- categories: Service Desk -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/service_desk/_index.md)

{{< /details >}}

サービスデスクのリクエスタにとって、サービスデスクリクエストにメールのみでやり取りするのではなく、サービスデスクのイシューに直接アクセスできると便利です。新しいプレースホルダー`%{ISSUE_URL}`を導入しています。これは、あなたのメールテンプレート（例えば、「ありがとう」メール）で使用して、リクエスタをサービスデスクのイシューに直接リンクできます。

### バックアップにプロジェクトをスキップする機能が追加されました {#backup-adds-the-ability-to-skip-projects}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/18287)

{{< /details >}}

組み込みのバックアップおよび復元ツールに、特定のリポジトリをスキップする機能が追加されました。Rakeタスクは、新しい`SKIP_REPOSITORIES_PATHS`環境変数を使用することで、バックアップまたは復元中にスキップされるカンマ区切りのグループまたはプロジェクトパスのリストを受け入れるようになりました。これにより、例えば、時間の経過とともに変更されない古いプロジェクトやアーカイブされたプロジェクトをスキップできるようになり、a) バックアップ実行の高速化による時間短縮、およびb) バックアップファイルにこのデータを含めないことによるスペース節約を実現できます。[Yuri Konotopov](https://gitlab.com/nE0sIghT)氏の[コミュニティコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121865)に感謝します！

### Geoがすべてのコンポーネントにレプリケーションステータスによるフィルタリングを追加 {#geo-adds-filtering-by-replication-status-to-all-components}

<!-- categories: Geo-replication, Disaster Recovery -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/geo/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/411981)

{{< /details >}}

Geoは、[セルフサービスフレームワーク](../../development/geo/framework.md)によって管理されるすべてのコンポーネントにレプリケーションステータスによるフィルタリングを追加しました。これで、レプリケーションの詳細ビューで「進行中」、「失敗」、および「同期済み」のステータスでアイテムをフィルタリングできるようになり、同期に失敗しているデータをより簡単かつ迅速に見つけることができます。

### Geoがデザインレポジトリを検証 {#geo-verifies-design-repositories}

<!-- categories: Geo-replication, Disaster Recovery -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/geo/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/355660)

{{< /details >}}

イシューにデザインを追加すると、デザインGitリポジトリが作成または更新され、LFSオブジェクトと（サムネイル用の）アップロードが作成されます。GeoはすでにLFSオブジェクトとアップロードを検証しており、今後はデザインリポジトリも検証します。これで[デザイン管理](../../user/project/issues/design_management.md)のすべての基盤となるデータが検証されたため、あなたのデザインデータは転送中または保存時に破損しないことが保証されます。もしGeoがディザスターリカバリー戦略の一部として使用される場合、これはデータ損失からあなたを保護します。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### マージリクエストでファイル全体にコメント {#comment-on-whole-file-in-merge-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/merge_requests/changes.md#add-a-comment-to-a-merge-request-file)

{{< /details >}}

マージリクエストはファイル全体へのコメントをサポートするようになりました。これは、すべてのマージリクエストフィードバックが特定の行に限定されるわけではないためです。ファイルが削除された場合、その理由についてより多くの情報が必要になる場合があります。ファイル名に関するフィードバックや、構造に関する一般的なコメントを提供したい場合もあります。

### GitLab CLIから変更履歴を作成 {#create-a-changelog-from-the-gitlab-cli}

<!-- categories: GitLab CLI -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/changelogs.md#from-the-gitlab-cli)

{{< /details >}}

変更履歴は、プロジェクトへのコミットに基づいて変更の包括的なリストを生成します。これらは自動化または表示が困難な場合があり、GitLab APIとの対話が必要です。

[GitLab CLI v1.30.0](https://gitlab.com/gitlab-org/cli/-/releases/v1.30.0)のリリースにより、Shellから直接プロジェクトの変更履歴を生成できるようになりました。`glab changelog generate`コマンドは、変更履歴のレビュー、自動化、公開を容易にします。

[Michael Mead](https://gitlab.com/michael-mead)さんのコントリビュートに感謝します！

### 無効なセキュリティポリシー承認チェックで失敗閉鎖 {#fail-closed-for-invalid-security-policy-approval-checks}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/merge_requests/approvals/_index.md#invalid-rules) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/389905)

{{< /details >}}

セキュリティおよびコンプライアンスポリシーにより、組織は複数のプロジェクトにわたってチェックアンドバランスを強制し、セキュリティおよびガバナンスプログラムに合わせることができます。お客様にとって、ポリシーに影響を与える変更によってガードレールが解除されないようにすることが重要です。このアップデートにより、無効なルールは「フェイルクローズ」として扱われ、すべてのスキャン結果ポリシーの無効なルールが対処されるまでMRがブロックされます。

### グループまたはサブグループからnpmパッケージをインストールする {#install-npm-packages-from-your-group-or-subgroup}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/npm_registry/_index.md#install-from-a-group) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/299834)

{{< /details >}}

プロジェクトのパッケージレジストリを使用して、npmパッケージを公開およびインストールできます。アクセストークン（パーソナル、ジョブ、デプロイ、またはプロジェクト）を使用して認証し、あなたのGitLabプロジェクトにパッケージの公開を開始するだけです。

これは、プロジェクト数が少ない場合に非常にうまく機能します。残念ながら、複数のプロジェクトがある場合、すぐに数十または数百もの異なるソースを追加することになるかもしれません。大規模な組織のチームが、ソースコードやパイプラインとともに、プロジェクトのパッケージレジストリにパッケージを公開することは一般的です。同時に、組織内のグループやサブグループ内の他のプロジェクトから依存関係を簡単にインストールできる必要があります。

プロジェクト間でパッケージの共有を容易にするため、自分のグループからパッケージをインストールできるようになりました。これにより、どのパッケージがどのプロジェクトにあるかを覚えておく必要がなくなります。選択した認証トークンを使用すると、グループをnpmパッケージのソースとして追加した後、グループのnpmパッケージをどれでもインストールできます。

### デザインアップロードに説明を追加する {#add-a-description-to-design-uploads}

<!-- categories: Portfolio Management, Design Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/issues/design_management.md#add-a-design-to-an-issue) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9694)

{{< /details >}}

現在、[デザインアップロード](../../user/project/issues/design_management.md#add-a-design-to-an-issue)には、その目的やアップロードされている理由を説明するメタデータがありません。イメージをよりよく理解できるように、説明としてテキストボックスを追加しました。

### GitLab Pagesで静的ファイルディレクトリを設定する {#configure-the-static-file-directory-in-gitlab-pages}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/pages/introduction.md#customize-the-default-folder) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/10126)

{{< /details >}}

これで、GitLab Pagesの静的ファイルディレクトリを任意の名前（デフォルトでは`public`）に設定できるようになりました。これにより、Next.js、Astro、Eleventyなどの人気のある静的サイトフレームワークでPagesを使用する際に、それらの設定で出力フォルダーを変更する必要がなくなります。

### Code Qualityアナライザーのアップデート {#code-quality-analyzer-updates}

<!-- categories: Code Quality -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/testing/code_quality.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/412459)

{{< /details >}}

GitLab Code Qualityは、[すでに実行しているツールとのインテグレーション](../../ci/testing/code_quality.md)をサポートし、CodeClimateスキャンシステムを実行する[CI/CDテンプレート](../../ci/testing/code_quality.md)も提供します。16.1のリリースマイルストーン中に、CodeClimateベースのアナライザーに対する以下のアップデートを公開しました:

- CodeClimateをバージョン0.96.0に更新しました。このバージョンには以下が含まれます:
  - 新しいプラグイン（`golangci-lint`用）。
  - 新しい利用可能なバージョン（`bundler-audit`プラグイン用）。
- Docker APIソケットへの構成可能なパスのサポートを追加しました。
  - [`@tsjnsn`](https://gitlab.com/tsjnsn)によるこの[コミュニティコントリビュート](https://gitlab.com/gitlab-org/ci-cd/codequality/-/merge_requests/73)に感謝します。この変数をCI/CDテンプレートに含めるためのアップデートは、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/409738)で追跡されています。

詳細については、[変更履歴](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/CHANGELOG.md?ref_type=heads#anchor-0960)を参照してください。

もし[GitLabマネージドのコード品質テンプレート](../../ci/testing/code_quality.md) （[`Code-Quality.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Code-Quality.gitlab-ci.yml)）を含めている場合、これらのアップデートは自動的に適用されます。

以前のリリースでのCode Qualityの変更点については、[最新のアップデート](https://about.gitlab.com/releases/2023/04/22/gitlab-15-11-released/#static-analysis-analyzer-updates)を参照してください。

### SASTアナライザーの更新 {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/application_security/sast/analyzers.md) | [関連イシュー](../../user/application_security/_index.md)

{{< /details >}}

GitLab SASTには、GitLab静的な解析チームが積極的に保守、更新、サポートする[多くのセキュリティアナライザー](../../user/application_security/sast/_index.md#supported-languages-and-frameworks)が含まれています。16.1のリリースマイルストーン中に、以下のアップデートを公開しました:

- Semgrepベースのアナライザーは、Semgrepエンジンのバージョン1.23.0を使用するように更新されました。また、C、C#、Go、Javaのスキャンに使用されるGitLabマネージドルールの[ガイダンスを明確にし、有効性を向上](https://docs.gitlab.com/#clearer-guidance-and-better-coverage-for-sast-rules)させました。詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md#v434)を参照してください。
- SpotBugsベースのアナライザーは、[`SAST_SCANNER_ALLOWED_CLI_OPTS`CI/CD変数を設定](../../user/application_security/sast/_index.md#security-scanner-configuration)することで、「労力レベル」を変更できるようになりました。これにより、スキャンの精度と脆弱性検出能力を低下させることで、パフォーマンスを向上させることができます。詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/blob/master/CHANGELOG.md#v420)を参照してください。

[GitLab管理のSASTテンプレート](../../user/application_security/sast/_index.md) （[`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)）を含め、GitLab 16.0以降を実行している場合、これらの更新を自動的に受け取ります。特定のアナライザーのバージョンを維持し、自動更新を防ぐには、[そのバージョンを固定](../../user/application_security/sast/_index.md)できます。

以前の変更については、[先月の更新](https://about.gitlab.com/releases/2023/05/22/gitlab-16-0-released/#sast-analyzer-updates)を参照してください。

### Google Cloudの流出したシークレットへの自動対応 {#automatic-response-to-leaked-google-cloud-secrets}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Gold
- リンク: [ドキュメント](../../user/application_security/secret_detection/automatic_response.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/8835)

{{< /details >}}

シークレット検出をGoogle Cloudとインテグレーションし、GitLabを使用してGoogle Cloud上でアプリケーションを開発する顧客をよりよく保護するようにしました。これで、組織がGoogle Cloudの認証情報をGitLab.com上の公開プロジェクトに漏洩した場合でも、GitLabはGoogle Cloudと連携してアカウントを保護することで、組織を自動的に保護できます。

シークレット検出は、Google Cloudが発行した以下の3種類のシークレットを検索します:

- [サービスアカウントキー](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)
- [APIキー](https://cloud.google.com/docs/authentication/api-keys)
- [OAuthクライアントシークレット](https://support.google.com/cloud/answer/6158849#rotate-client-secret)

公開された流出したシークレットは、発見された後にGoogle Cloudに送信されます。Google Cloudは漏洩を検証し、その後、不正使用から顧客アカウントを保護するために機能します。

このインテグレーションは、GitLab.comで[シークレット検出が有効化](../../user/application_security/secret_detection/_index.md)されているプロジェクトでデフォルトでオンになっています。シークレット検出スキャンはすべてのGitLab Tierで利用可能ですが、流出したシークレットへの自動応答は現在Ultimateプロジェクトでのみ利用可能です。

詳細については、[このインテグレーションに関するブログ投稿](https://about.gitlab.com/blog/how-secret-detection-can-proactively-revoke-leaked-credentials/)を参照してください。

### SASTルールに対するより明確なガイダンスとより良いカバレッジ {#clearer-guidance-and-better-coverage-for-sast-rules}

<!-- categories: SAST -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/application_security/sast/analyzers.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/382119)

{{< /details >}}

GitLab SASTルールを以下のように更新しました:

- 各ルールが対象とする脆弱性の種類と、それを修正する方法をより明確に説明します。これまでのところ、C、C#、Go、Javaのルールに関する説明とガイダンステキストを更新しました。残りの言語は[イシュー382119](https://gitlab.com/gitlab-org/gitlab/-/issues/382119)で追跡されています。
- 既存のJavaルールで追加の脆弱性を検出します。

これらの改善は、GitLab静的な解析チームと脆弱性リサーチチーム間のコラボレーションの一部であり、[デフォルトの静的な解析ルールセットを改善](https://gitlab.com/groups/gitlab-org/-/epics/8170)することを目的としています。[エピック8170](https://gitlab.com/groups/gitlab-org/-/epics/8170)でのSAST、シークレット検出、およびIaCスキャン用のデフォルトルールに関するフィードバックを歓迎します。

GitLab SASTルールの変更に関する詳細については、[CHANGELOG](https://gitlab.com/gitlab-org/security-products/sast-rules/-/blob/main/CHANGELOG.md)を参照してください。GitLab 16.1現在、[`sast-rules`プロジェクト](https://gitlab.com/gitlab-org/security-products/sast-rules)は、SemgrepベースのSASTアナライザーで使用されるすべてのGitLabマネージドデフォルトルールの単一ソースです。

### SAST、IaCスキャン、およびシークレット検出における共有ルールセットのカスタマイズ {#shared-ruleset-customizations-in-sast-iac-scanning-and-secret-detection}

<!-- categories: SAST, Secret Detection -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/application_security/sast/customize_rulesets.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/362958)

{{< /details >}}

これで、[SAST](../../user/application_security/sast/customize_rulesets.md) 、[IaCスキャン](../../user/application_security/iac_scanning/_index.md) 、または[シークレット検出](../../user/application_security/secret_detection/pipeline/_index.md)のルールセットカスタマイズを複数のプロジェクト間で共有するために、CI/CD変数を設定できます。

ルールセットを共有すると、次のことが可能になります:

- プロジェクトで重視したくない[事前定義されたルールを無効](../../user/application_security/sast/customize_rulesets.md)にします。
- 説明、メッセージ、名前、重大度など、[事前定義されたルールのフィールドを変更](../../user/application_security/sast/customize_rulesets.md)して、組織の好みを反映させます。例えば、ルールのデフォルト重大度を調整したり、検出結果を修正する方法に関する情報を追加したりできます。
- ルールを追加または置き換えることにより、[カスタムルールセットをビルド](../../user/application_security/sast/customize_rulesets.md)します。このオプションは一部のアナライザーでのみ利用可能です。

この分野のさらなる改善については、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/257928)で議論されています。

### CI/CD: `rules`で`needs`を使用する {#cicd-use-needs-in-rules}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/yaml/_index.md#rulesneeds) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/31581)

{{< /details >}}

[needs:](../../ci/yaml/_index.md#needs)キーワードは、ジョブ間の依存関係を定義します。これは、ジョブをステージ順序外で実行するように設定するために使用できます。このリリースでは、特定の`rules`条件に対してこの関係を定義する機能を追加しました。条件がルールに一致すると、ジョブの`needs`設定は、ルール内の`needs`で完全に置き換えられます。これは、ジョブが通常よりも早く開始できる場合、定義された条件に基づいてパイプラインを高速化するのに役立ちます。また、これをジョブが以前のジョブの完了を待ってから開始するように強制するためにも使用できます。これにより、より柔軟な`needs`オプションが利用できるようになりました！

### CI/CDパイプラインとジョブのUIを美しくする {#beautify-the-ui-of-cicd-pipelines-and-jobs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/pipelines/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/394768)

{{< /details >}}

GitLabの最もよく使用される機能の1つはCI/CDです。16.1では、CI/CDパイプラインとジョブのリストビュー、およびパイプライン詳細ページの使いやすさとエクスペリエンスの向上に焦点を当てました。探している情報がこれまでより簡単に見つかるようになりました！変更点に関するコメントがございましたら、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/414756)でお聞かせください。

### Linux上のGitLab SaaS Runnerのストレージが増加 {#increased-storage-for-gitlab-saas-runners-on-linux}

<!-- categories: GitLab Runner SaaS -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/linux.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/384223)

{{< /details >}}

最近、vCPUとRAMにおいて[Linux上のGitLab.com SaaS Runner](../../ci/runners/hosted_runners/linux.md)のサイズを拡大した後、`medium`および`large`マシンタイプ用のストレージも増加させました。

これで、セキュアでオンデマンドなGitLab Runner Linux環境を、GitLab CI/CDと完全にインテグレーションして、より大規模なアプリケーションをシームレスにビルド、テスト、デプロイできるようになりました。

### CI/CDジョブトークンスコープAPIエンドポイント {#cicd-job-token-scope-api-endpoint}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/jobs/ci_job_token.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/351740)

{{< /details >}}

GitLab 16.0より、すべての新規プロジェクトで[デフォルトのCI/CDジョブトークン（`CI_JOB_TOKEN`）スコープが変更](../../ci/jobs/ci_job_token.md)されました。これにより、新しいプロジェクトのセキュリティは向上しましたが、自動化を使用してプロジェクトを作成するユーザーにとっては追加の手順が必要になりました。自動化ではジョブトークンスコープも設定する必要がある場合がありますが、これはREST APIではなくGraphQL（またはUIで手動で）のみでしか行えませんでした。

この設定をREST APIを介しても設定できるようにするため、[Gerardo Navarro](https://gitlab.com/gerardo-navarro)は16.1でジョブトークンスコープを制御するための新しいエンドポイントを追加しました。プロジェクトでメンテナー以上のロールを持つユーザーが利用できます。Gerardoさん、この素晴らしいコントリビュートをありがとうございます！

### Runnerの詳細 - 設定を共有するRunnerを統合する {#runner-details---consolidate-runners-sharing-a-configuration}

<!-- categories: Runner Fleet -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner/fleet_scaling/#reusing-a-runner-configuration) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/409388/)

{{< /details >}}

新しいRunner作成方法により、同じ機能を備えた複数のRunnerを登録する必要があるシナリオで、Runner設定を再利用できます。同じ認証トークンで登録されたRunnerは、設定を共有し、新しい詳細ビューでグループ化されます。

### GitLab Runner 16.1 {#gitlab-runner-161}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 16.1もリリースします！GitLab Runnerは、CI/CDジョブを実行し、結果をGitLabインスタンスに送信する、軽量で拡張性の高いエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [Azure仮想マシン用のGitLab Runner Fleetingプラグイン（実験的）](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29410)。[vincent_stchu](https://gitlab.com/vincent_stchu)様のコントリビュートに感謝します！

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/-/blob/16-1-stable/CHANGELOG.md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.1)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.1)
- [UI改善](https://papercuts.gitlab.com/?milestone=16.1)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
