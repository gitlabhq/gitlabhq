---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab SLSA
---

このページでは、GitLab SLSAのサポートに関する情報を提供します。

関連トピック:

- [Provenanceバージョン1 buildType仕様](provenance_v1.md)

## SLSA来歴生成 {#slsa-provenance-generation}

GitLabは、[GitLab Runnerによって生成されるすべてのBuildアーティファクトに対して自動生成できる](../../runners/configure_runners.md#artifact-provenance-metadata)SLSAレベル1準拠の来歴ステートメントが提供します。この来歴ステートメントは、Runner自体によって生成されます。

### CI/CDコンポーネントでSLSA来歴に署名して検証する {#sign-and-verify-slsa-provenance-with-a-cicd-component}

[GitLab SLSA CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/slsa)は、以下の設定を提供します:

- Runner生成来歴ステートメントへの署名
- ジョブアーティファクトの[検証サマリーアテステーション（VSA）](https://slsa.dev/spec/v1.0/verification_summary)の生成

詳細について、また設定例については、[SLSAコンポーネントのドキュメント](https://gitlab.com/components/slsa#slsa-supply-chain-levels-for-software-artifacts)を参照してください。
