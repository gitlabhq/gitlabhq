---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabでコンプライアンスのために、プロジェクトの変更とマージの詳細を追跡するために、管理の連鎖レポートを生成してエクスポートします。
title: 管理の連鎖レポート
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 13.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/213364)。
- メールで送信される管理の連鎖レポートは、`async_chain_of_custody_report`というフラグを使用してGitLab 15.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/342594)。デフォルトでは無効になっています。
- GitLab 15.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/370100)になりました。機能フラグ`async_chain_of_custody_report`は削除されました。
- 管理の連鎖レポートには、（マージコミットだけでなく）すべてのコミットが含まれており、`all_commits_compliance_report`というフラグを使用してGitLab 15.9で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/267601)。デフォルトでは無効になっています。
- GitLab 15.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112092)になりました。機能フラグ`all_commits_compliance_report`は削除されました。

{{< /history >}}

管理の連鎖レポートは、グループ下のプロジェクトに対するすべてのコミットの1か月間のローリングウィンドウを提供します。

すべてのコミットのレポートを生成するために、GitLabは以下を行います:

1. グループ下のすべてのプロジェクトをフェッチします。
1. 各プロジェクトについて、過去1か月間のコミットを時系列順（最新のものから順に）にフェッチします。各プロジェクトは1024コミットに制限されています。1か月間に1024を超えるコミットがある場合、切り詰められます。
1. 一貫した順序付けのために、コミットSHAによる決定論的なセカンダリソートで、（降順で）コミットされた日付ですべてのコミットをソートします。
1. コミットをCSVファイルに書き込みます。このファイルは、レポートが添付ファイルとしてメールで送信されるため、15 MBに切り詰められます。

レポートには以下が含まれます:

- コミットSHA。
- コミット作成者。
- コミッター（コミッターのメールに基づいて、利用可能な場合はGitLabのユーザー名に正規化されます）。
- コミットされた日付（UTC形式のミリ秒精度）。
- グループ。
- プロジェクト。

コミットにマージコミットが関連付けられている場合は、以下も含まれます:

- マージコミット 。
- マージリクエストID。
- マージリクエストをマージしたユーザー。
- マージ日。
- パイプラインID。
- マージリクエストの承認者。

## 管理の連鎖レポートを生成 {#generate-chain-of-custody-report}

管理の連鎖レポートを生成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **コンプライアンスセンター**を選択します。
1. 右上隅で、**エクスポート**を選択します。
1. **管理の連鎖レポートのエクスポート**を選択します。

GitLabのバージョンによっては、管理の連鎖レポートがメールで送信されるか、ダウンロードできます。

## コミット固有の管理の連鎖レポートを生成 {#generate-commit-specific-chain-of-custody-report}

{{< history >}}

- GitLab 13.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/267629)。
- マージコミットの代わりにすべてのコミットを含めるサポートが、GitLab 15.10で[追加されました](https://gitlab.com/gitlab-org/gitlab/-/issues/393446)。

{{< /history >}}

指定されたコミットSHAに対して、コミット固有の管理の連鎖レポートを生成できます。このレポートは、指定されたコミットSHAの詳細のみを提供します。

コミット固有の管理の連鎖レポートを生成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **コンプライアンスセンター**を選択します。
1. 右上隅で、**エクスポート**を選択します。
1. **特定のコミットの管理レポートをエクスポート**を選択します。
1. コミットSHAを入力し、**管理の連鎖レポートのエクスポート**を選択します。

GitLabのバージョンによっては、管理の連鎖レポートがメールで送信されるか、ダウンロードできます。

または、直接リンク`https://gitlab.com/groups/<group-name>/-/security/merge_commit_reports.csv?commit_sha={optional_commit_sha}`を使用し、オプションの値を`commit_sha`クエリパラメータに渡します。
