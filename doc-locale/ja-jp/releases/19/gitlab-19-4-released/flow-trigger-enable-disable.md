---
title: フロートリガーを削除せずにオフにする
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../../user/duo_agent_platform/triggers/#turn-a-trigger-on-or-off"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/598439
categories: [ DAP Triggers ]
level: secondary
---

以前のバージョンのGitLabでは、フローが自動的に開始されないようにするには、トリガーを完全に削除するしか方法がありませんでした。
トリガーを削除すると、設定済みの複雑なフィルター設定も失われてしまいます。

今回のリリースで、フロートリガーをオフにしても設定を保持できるようになりました。
新しい切り替えを使用して、いつでもオンに戻すことができます。

トリガーを管理するには、**AI** > **トリガー**に移動します。
