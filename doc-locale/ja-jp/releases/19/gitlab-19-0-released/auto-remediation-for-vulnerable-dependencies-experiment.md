---
title: 脆弱な依存関係の自動修正（実験的機能）
stage: software_supply_chain_security
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com ]
documentation_link: "../../../user/application_security/remediate/auto_remediation/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/17403"
categories: [ Software Composition Analysis ]
weight: 10
---

依存関係の自動修正機能が、GitLab 19.0で実験的機能として利用可能になりました。依存関係スキャンが既知の修正方法を持つ脆弱なRubyの依存関係を検出すると、GitLabは自動的にマージリクエストを作成し、人の操作なしに安全なバージョンへ更新します。実験的機能ではRubyプロジェクトのみがサポートされています。

パイプラインが実行されるたびに、GitLabはパッチまたはマイナーバージョンアップグレードが利用可能な最も重大度の高い脆弱性を特定します。GitLabはマニフェストファイルの変更を生成し、サービスアカウントを通じてマージリクエストを作成します。作成されたマージリクエストは、プロジェクトの標準的なレビューおよび承認ワークフローに従って処理されます。

実験期間中は、プロジェクトごとに最大3件の自動修正マージリクエストを同時にオープンできます。

フィードバックの共有や実験的機能の試用申請は、[エピック600511](https://gitlab.com/gitlab-org/gitlab/-/work_items/600511)にコメントしてください。プロジェクトで実験的機能を有効にするには、GitLabチームメンバーがプロジェクトに対して`dependency_management_auto_remediation`機能フラグを有効にする必要があります。
