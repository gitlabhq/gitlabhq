---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 脆弱性リスク評価データ
---

脆弱性リスクデータを使用して、環境への潜在的な影響を評価します。

- 重大度: 各脆弱性には、標準化されたGitLabの重大度値が割り当てられます。

- [共通脆弱性識別子（CVE）](https://www.cve.org/)カタログの脆弱性については、[脆弱性の詳細](_index.md)ページまたはGraphQLクエリを使用して、次のデータを取得できます: 
  - 悪用される可能性: [Exploit Prediction Scoring System（EPSS）](https://www.first.org/epss)スコア。
  - 既知の悪用法の有無: [既知の悪用された脆弱性（KEV）](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)ステータス。

このデータを使用して、修正と軽減アクションの優先順位付けを行います。たとえば、中程度の重大度と高いEPSSスコアを持つ脆弱性は、高い重大度と低いEPSSスコアを持つ脆弱性よりも早期の軽減が必要になる場合があります。

## EPSS {#epss}

{{< history >}}

- `epss_querying`（イシュー[470835](https://gitlab.com/gitlab-org/gitlab/-/issues/470835)内）および`epss_ingestion`（イシュー[467672](https://gitlab.com/gitlab-org/gitlab/-/issues/467672)内）という名前の[フラグ](../../../administration/feature_flags/_index.md)付きでGitLab 17.4で導入されました。デフォルトでは無効になっています。
- `cve_enrichment_querying`および`cve_enrichment_ingestion`に名前が変更され、GitLab 17.6で[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/481431)になりました。
- GitLab 17.7で[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/11544)されました。機能フラグ`cve_enrichment_querying`および`cve_enrichment_ingestion`は削除されました。

{{< /history >}}

EPSSスコアは、共通脆弱性識別子カタログにある脆弱性が今後30日以内に悪用される可能性の推定値を提供します。EPSSは、各共通脆弱性識別子に0〜1（0％〜100％に相当）のスコアを割り当てます。

## KEV {#kev}

{{< history >}}

- GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/499407)されました。

{{< /history >}}

KEVカタログには、悪用されたことが判明している脆弱性がリストされています。他の脆弱性よりも、KEVカタログの脆弱性の修正を優先する必要があります。これらの脆弱性を使用した攻撃が発生しており、攻撃者が悪用方法を知っている可能性があります。

## 到達可能性 {#reachability}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/groups/gitlab-org/-/epics/16510)されました。

{{< /history >}}

到達可能性は、脆弱性のあるパッケージがアプリケーションでアクティブに使用されているかどうかを示します。コードが直接やり取りするパッケージの脆弱性は、未使用の依存関係にある脆弱性よりもリスク評価が高くなります。攻撃者が悪用する可能性のある実際のエクスポージャーポイントを表すため、到達可能な脆弱性の修正を優先します。

## クエリリスク評価データ {#query-risk-assessment-data}

GraphQL APIを使用して、プロジェクト内の脆弱性の重大度、EPSS、およびKEVの値をクエリします。

GraphQL APIの`Vulnerability`型には`cveEnrichment`フィールドがあり、`identifiers`フィールドに共通脆弱性識別子識別子が含まれている入力されます。`cveEnrichment`フィールドには、脆弱性の共通脆弱性識別子ID、EPSSスコア、およびKEVステータスが含まれています。EPSSスコアは、小数点以下2桁に丸められます。

たとえば、次のGraphQL APIクエリは、特定のプロジェクト内のすべての脆弱性とその共通脆弱性識別子ID、EPSSスコア、およびKEVステータス（`isKnownExploit`）を返します。[GraphQLエクスプローラー](../../../api/graphql/_index.md#interactive-graphql-explorer)またはその他のGraphQLクライアントでクエリを実行します。

```graphql
{
  project(fullPath: "<full/path/to/project>") {
    vulnerabilities {
      nodes {
        severity
        identifiers {
          externalId
          externalType
        }
        cveEnrichment {
          epssScore
          isKnownExploit
          cve
        }
        reachability
      }
    }
  }
}
```

出力例: 

```json
{
  "data": {
    "project": {
      "vulnerabilities": {
        "nodes": [
          {
            "severity": "CRITICAL",
            "identifiers": [
              {
                "externalId": "CVE-2019-3859",
                "externalType": "cve"
              }
            ],
            "cveEnrichment": {
              "epssScore": 0.2,
              "isKnownExploit": false,
              "cve": "CVE-2019-3859"
            }
            "reachability": "UNKNOWN"
          },
          {
            "severity": "CRITICAL",
            "identifiers": [
              {
                "externalId": "CVE-2016-8735",
                "externalType": "cve"
              }
            ],
            "cveEnrichment": {
              "epssScore": 0.94,
              "isKnownExploit": true,
              "cve": "CVE-2016-8735"
            }
            "reachability": "IN_USE"
          },
        ]
      }
    }
  },
  "correlationId": "..."
}
```

## 脆弱性優先順位付けツール {#vulnerability-prioritizer}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

[Vulnerability Prioritizer CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/vulnerability-prioritizer)を使用して、プロジェクトの脆弱性の優先順位付けを行います。このコンポーネントは、`vulnerability-prioritizer`ジョブの出力に優先順位レポートを出力します。

脆弱性は、次の順序でリストされます。: 

1. 既知の悪用（KEV）がある脆弱性が最優先されます。
1. より高いEPSSスコア（1に近い）が優先されます。
1. 重大度は、`Critical`から`Low`の順に並べられています。

脆弱性優先順位付けツールCI/CDコンポーネントは、Common Vulnerabilities and Exposures（共通脆弱性識別子）レコードでのみ使用可能なデータを必要とするため、[依存関係スキャン](../dependency_scanning/_index.md)および[コンテナスキャン](../container_scanning/_index.md)によって検出された脆弱性のみが含まれます。さらに、[検出された（**トリアージが必要**）および確認済みの](_index.md#vulnerability-status-values)脆弱性のみが表示されます。

脆弱性優先順位付けツールCI/CDコンポーネントをプロジェクトのCI/CDパイプラインに追加するには、[Vulnerability Prioritizerのドキュメント](https://gitlab.com/components/vulnerability-prioritizer)を参照してください。
