---
title: シークレット検出がデフォルトブランチへのプッシュ時にコミット履歴をスキャン
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: application_security_testing
documentation_link: "../../../user/application_security/secret_detection/pipeline"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/607941
categories: [ Secret Detection ]
level: secondary
weight: 30
---

デフォルトブランチのシークレット検出では、直前のコミット参照が利用可能な場合、最新のディレクトリ内容のみをスキャンするのではなく、プッシュ内のすべてのコミット差分をスキャンするようになりました。この変更により、同一プッシュ内で導入・削除されたシークレットが検出されないというギャップが解消されます。この動作は、マージリクエストやフィーチャーブランチでのシークレット検出の動作と一致するようになりました。

このスキャンにより、パイプラインの完了前に削除された場合でも、リポジトリの履歴に一時的に存在したシークレットを検出できます。セキュリティチームは、HEADに存在するシークレットだけでなく、かつてコミットされたシークレットも特定できるようになりました。

詳細については、[パイプラインシークレット検出のカバレッジ](../../../user/application_security/secret_detection/pipeline/_index.md#coverage)を参照してください。
