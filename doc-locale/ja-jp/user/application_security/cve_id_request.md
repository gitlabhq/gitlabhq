---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CVE IDリクエスト
description: 脆弱性の追跡とセキュリティ開示。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

パブリックプロジェクトであれば、CVE識別子（ID）をリクエストできます。

[CVE](https://cve.mitre.org/index.html)識別子は、公に公開されたソフトウェア脆弱性に割り当てられます。GitLabは、[CVE Numbering Authority](https://about.gitlab.com/security/cve/)（[CNA](https://cve.mitre.org/cve/cna.html)）です。

プロジェクト内の脆弱性にCVE IDを割り当てることで、ユーザーは安全性を維持し、常に最新の情報を得ることができます。たとえば、[dependency scanning tools](dependency_scanning/_index.md)は、プロジェクトの脆弱なバージョンが依存関係として使用されている場合を検出できます。

一般的な脆弱性のワークフローは次のとおりです:

1. 脆弱性に対するCVEをリクエストします。
1. リリースノートで、割り当てられたCVE識別子を参照します。
1. 修正がリリースされたら、脆弱性の詳細を公開します。

## 前提要件 {#prerequisites}

[CVE IDリクエストを作成](#submit-a-cve-id-request)するには、次の前提条件を満たす必要があります:

- プロジェクトがGitLab.comでホストされていること。
- プロジェクトがパブリックであること。
- プロジェクトのメンテナーであること。
- 脆弱性のイシューが[confidential](../project/issues/confidential_issues.md)であること。

## CVE IDリクエストを送信 {#submit-a-cve-id-request}

CVE IDリクエストを送信するには:

1. 脆弱性のイシューに移動し、**CVE IDリクエストを作成**を選択します。[GitLab CVE project](https://gitlab.com/gitlab-org/cves)の新しいイシューページが開きます。

1. **タイトル**ボックスに、脆弱性の簡単な説明を入力します。

1. **説明**ボックスに、次の詳細を入力します:

   - 脆弱性の詳細な説明
   - プロジェクトのベンダーと名前
   - 影響を受けるバージョン
   - 修正されたバージョン
   - 脆弱性クラス（[CWE](https://cwe.mitre.org/data/index.html)識別子）
   - [CVSS v3 vector](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator)

GitLabは、CVE IDリクエストイシューを更新します:

- リクエストの送信にCVEが割り当てられている場合。
- CVEが公開されている場合。
- CVEが公開されたことがMITREに通知された場合。
- MITREがNVDフィードにCVEを追加した場合。

## CVE割り当て {#cve-assignment}

CVE識別子が割り当てられたら、必要に応じて参照できます。CVE IDリクエストで送信された脆弱性の詳細は、スケジュールに従って公開されます。
