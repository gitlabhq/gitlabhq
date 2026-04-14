---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabの強化に関する推奨事項
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このドキュメントは、全体的なシステムが一般的ではない攻撃に対しても「強化」されたGitLabのインスタンスを対象としています。これは、攻撃を完全に根絶することを目的としたものではなく、強力な軽減策を提供することで全体的なリスクを低減することを目的としています。一部の技術はSaaSやセルフマネージドといった、あらゆるGitLabのデプロイに適用されますが、その他の技術は基盤となるOSに適用されます。

これらの技術は現在進行中であり、大規模で（多数のユーザーがいる大規模環境など）テストされていません。これらはセルフマネージドの単一インスタンスで、Linuxパッケージのインストールが実行されている環境でテストされています。多くの技術は他のデプロイタイプにも適用可能ですが、すべてが機能するとは限りません。

記載されている推奨事項のほとんどは、一般的なドキュメントに基づいて行える特定の推奨事項や参照の選択肢を提供します。強化を行うことで、ユーザーが特に必要とする、あるいは依存している特定の機能に影響が出る可能性があります。そのため、ユーザーとコミュニケーションを取り、強化の変更を段階的なロールアウトで行う必要があります。

強化に関する説明は、理解しやすいように5つのカテゴリに分類されています。これらは次のセクションに記載されています。

## GitLabの強化に関する一般的な概念 {#gitlab-hardening-general-concepts}

これは、セキュリティへのアプローチとしての強化に関する情報と、より大きな哲学の一部を詳細に説明しています。詳細については、[一般的な強化の概念](hardening_general_concepts.md)を参照してください。

## GitLabアプリケーション設定 {#gitlab-application-settings}

GitLab GUIを使用してアプリケーション自体に行われたアプリケーション設定。詳細については、[アプリケーションの推奨事項](hardening_application_recommendations.md)を参照してください。

## GitLab CI/CD設定 {#gitlab-cicd-settings}

CI/CDはGitLabの核となるコンポーネントであり、セキュリティ原則の適用はニーズに基づきますが、CI/CDをより安全にするためにできることがいくつかあります。詳細については、[CI/CDの推奨事項](hardening_cicd_recommendations.md)を参照してください。

## GitLab設定設定 {#gitlab-configuration-settings}

アプリケーションを制御および構成するために使用される設定ファイルの設定（`gitlab.rb`など）は、別途ドキュメント化されています。詳細については、[設定の推奨事項](hardening_configuration_recommendations.md)を参照してください。

## オペレーティングシステムの設定 {#operating-system-settings}

基盤となるオペレーティングシステムを調整することで、全体的なセキュリティを向上させることができます。詳細については、[オペレーティングシステムの推奨事項](hardening_operating_system_recommendations.md)を参照してください。

## NIST 800-53コンプライアンス {#nist-800-53-compliance}

GitLab Self-ManagedをNIST 800-53セキュリティ標準へのコンプライアンスを強制するように構成できます。詳細については、[NIST 800-53コンプライアンス](hardening_nist_800_53.md)を参照してください。
