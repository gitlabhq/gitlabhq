---
title: フローでIDトークンを設定する
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: ai-powered
documentation_link: "../../../user/duo_agent_platform/flows/execution/#configure-id-tokens"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/591140
categories: [ Runner Execution, System Access ]
level: secondary
weight: 50
---

IDトークンを使用すると、長期間有効な認証情報を保存することなく、サードパーティのOpenID Connect（OIDC）サービスで認証できます。たとえば、バイナリやコミットのキーレス署名、またはシークレットマネージャーからのシークレットの取得にIDトークンを活用できます。

この機能を使用するには、エージェントの設定に`id_tokens`キーワードを追加し、GitLab Duo Agent Platformが発行するトークンを信頼するようにサービスを設定してください。
