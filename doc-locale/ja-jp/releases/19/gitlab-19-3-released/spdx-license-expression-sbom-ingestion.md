---
title: CycloneDX SBOMのSPDXライセンス表現がGitLabに対応
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: "../../../user/compliance/license_scanning_of_cyclonedx_files/#license-expressions"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/606225
categories: [ Software Composition Analysis ]
level: secondary
weight: 50
---

<!-- Category: Software Composition Analysis -->

GitLab 19.3では、GitLabに持ち込むCycloneDX ソフトウェア部品表（SBOM）ファイルにおいて、Software Package Data Exchange（SPDX）ライセンス表現のサポートが追加されました。
これまでは、SPDX表現構文を使用して定義された複合ライセンスやカスタムライセンスを持つコンポーネントは、不明として表示されていました。

今回のリリースにより、GitLabはCycloneDXライセンスエントリから`expression`フィールドを読み取って保存できるようになりました。`MIT AND Apache-2.0`のような複雑な表現や、`LicenseRef-[NAME]`構文を使用したカスタムライセンス参照にも対応しています。

SPDXライセンス表現のサポートは、独自のSBOMを生成しており、複雑またはカスタムのライセンス表現を持つコンポーネントが存在する組織に特に有用です。GitLabが生成するスキャンを必要とせず、ライセンスのリスク状況を正確に把握できます。

詳細については、[独自のCycloneDX SBOMを持ち込む](../../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md)を参照してください。
