---
title: 依存関係およびライセンススキャンにおけるSPDXライセンス表現のサポート
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: ../../../user/compliance/license_scanning_of_cyclonedx_files/
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/16801
categories: [ "Software Composition Analysis" ]
level: primary
---

GitLabのライセンスデータに、`MIT OR Apache-2.0`や`GPL-2.0-only WITH Classpath-exception-2.0`などの複合宣言を含むSPDXライセンス表現が対応しました。
以前は、これらの表現は依存関係リストで`unknown`として報告され、ライセンス承認ポリシーからは参照できませんでした。

複合ライセンスは、演算子（`AND`、`OR`、`WITH`）とともに依存関係リストに表示されるようになり、ライセンス承認ポリシーで単一ライセンスの依存関係と同様に許可または拒否できます。

CycloneDX SBOMで宣言された表現はGitLab 19.3からサポートされています。
今回のリリースでは、GitLabが同期するライセンスデータにも対応しました。
オフラインインスタンスでは、[v3ライセンスデータのダウンロード](../../../topics/offline/quick_start_guide.md#download-v3-license-data)後にのみ表現を受け取ることができます。
