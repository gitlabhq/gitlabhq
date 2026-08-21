---
title: シークレットプッシュ保護のフェイルオープンシナリオに対する監査イベント
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: application_security_testing
documentation_link: "../../../user/application_security/secret_detection/secret_push_protection"
work_item: https://gitlab.com/gitlab-org/gitlab/-/issues/604787
categories: [ Secret Detection ]
---

以前のバージョンのGitLabでは、シークレットプッシュ保護がスキャンを完了できずにスキャンなしでプッシュを通過させた場合、GitLabは顧客が確認できる監査証跡を提供していませんでした。セキュリティおよびコンプライアンスチームは、シークレットプッシュ保護がリポジトリへのプッシュを暗黙的に許可したタイミングを監視する手段がありませんでした。

GitLab 19.3以降では、ルールセットエラー、ファイルおよび行数の上限超過、スキャンタイムアウト、予期しないエラーなど、すべてのフェイルオープンシナリオに対して[監査イベント](../../../user/compliance/audit_event_types.md#secret-detection)が生成されます。チームはこれらのイベントを外部のモニタリングおよびアラートツールに転送し、セキュリティ対策状況の可視性を維持できるようになりました。
