---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabを使用および管理する方法と、ソフトウェア開発のための最もスケーラブルなGitベースの完全に統合されたプラットフォームについて学びます。
title: 'GitLab: DevSecOpsプラットフォーム'
---

DevSecOpsは、開発、セキュリティ、および運用を組み合わせたものです。これは、ソフトウェア開発ライフサイクル全体にセキュリティを統合するアプローチです。

## DevSecOpsとDevOpsの比較 {#devsecops-compared-to-devops}

DevOpsは、開発と運用を組み合わせ、ソフトウェア開発およびデリバリーの効率性、速度、およびセキュリティを向上させることを目的としています。

DevOpsとは、安全なソフトウェアを最高速度で考案し、ビルドし、提供するために協力することを意味します。DevOpsのプラクティスには、自動化、コラボレーション、迅速なフィードバック、および反復的な改善が含まれます。

DevSecOpsはDevOpsの進化形です。DevSecOpsには、ソフトウェア開発のすべてのステージにおけるアプリケーションセキュリティのプラクティスが含まれます。

開発プロセス全体を通して、ツールとメソッドはライブアプリケーションを保護および監視します。新たなアタックサーフェス（攻撃対象領域）（コンテナやオーケストレーターなど）も監視および保護する必要があります。DevSecOpsツールは、セキュリティワークフローを自動化して、開発およびセキュリティチーム向けの適応性のあるプロセスを作成し、コラボレーションを改善し、サイロを解消します。ソフトウェア開発ライフサイクルにセキュリティを組み込むことで、迅速で反復的なプロセスを一貫して保護し、品質を犠牲にすることなく効率性を向上させることができます。

## DevSecOpsの基本 {#devsecops-fundamentals}

DevSecOpsの基本には以下が含まれます:

- 自動化
- コラボレーション
- ポリシーガードレール
- 表示レベル

詳細については、[DevSecOpsに関するこの記事](https://about.gitlab.com/topics/devsecops/)を参照してください。

## 実践におけるDevSecOps {#devsecops-in-practice}

次のGitLabの機能はすべて、堅牢なDevSecOpsプラットフォームの一部です:

- シフトレフトセキュリティ: 静的アプリケーションセキュリティテスト（SAST）とマージリクエストにおける依存関係スキャンは、コードマージの前に脆弱性を検出します。
- コンテナセキュリティ: イメージスキャン（共通脆弱性識別子（CVE）向け）、ランタイム保護、およびKubernetesのセキュリティポリシーは、最小特権アクセスを強制します。
- Infrastructure as Code（IaC）スキャン: Terraform、CloudFormation、およびKubernetesのマニフェストにおける設定ミスの自動検出。
- シークレット検出: プリコミットフックとCI/CDパイプラインスキャンは、リポジトリでの資格情報漏洩を防ぎます。
- セキュリティダッシュボード: 共通脆弱性評価システム（CVSS）スコアリング、悪用可能性メトリクス、および修正ワークフローを備えた、一元的な脆弱性追跡。

## DevSecOpsはあなたに適していますか？ {#is-devsecops-right-for-you}

貴社が以下のいずれかの課題に直面している場合、DevSecOpsのアプローチが適しているかもしれません。

<!-- Do not delete the double spaces at the end of these lines. They improve the rendered view. -->

- 開発、セキュリティ、および運用チームがサイロ化されています。開発と運用がセキュリティの問題から隔離されている場合、安全なソフトウェアをビルドすることはできません。また、セキュリティチームが開発プロセスの一部でない場合、積極的にリスクを特定することはできません。DevSecOpsはチームをまとめ、ワークフローを改善し、アイデアを共有します。組織は従業員の士気と保持の向上さえ見られるかもしれません。

- 長い開発サイクルは、顧客やステークホルダーの要求を満たすことを困難にしています。この苦戦の理由の1つはセキュリティかもしれません。DevSecOpsは、開発ライフサイクルのあらゆる段階でセキュリティを実装するため、堅牢なセキュリティのためにプロセス全体を停止する必要がありません。

- クラウドへの移行を検討中（または移行中）ですか？クラウドへの移行は、新しい開発プロセス、ツール、およびシステムを導入することを意味する場合が多いです。プロセスをより速く、より安全にする絶好の機会であり、DevSecOpsがそれをはるかに容易にする可能性があります。

DevSecOpsを開始するには、[詳細を学び、GitLab Ultimateを無料で試してください](https://about.gitlab.com/solutions/security-compliance/)。
