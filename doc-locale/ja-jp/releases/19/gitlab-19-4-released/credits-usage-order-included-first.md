---
title: 含まれているクレジットが評価クレジットより先に使用される
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: fulfillment
documentation_link: "../../../subscriptions/gitlab_credits/#usage-order"
work_item: https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/18961
categories: [ Consumables Cost Management ]
level: secondary
---

サブスクリプションに一時的な評価クレジットがある場合、すべての使用量はその共有プールから先に消費されていました。各ユーザーの月次含有クレジットは、評価プールが枯渇するまで使用されず、月末にリセットされていました。

GitLabは各ユーザーの含有クレジットを先に消費するようになり、ユーザーが含有クレジットを使い切った後にのみ、一時的な評価クレジットの共有プールから消費するようになりました。月次コミットメントプール、ワンタイムチャージクレジット、およびオンデマンドクレジットは従来と同じ順序で消費されるため、請求額への影響はありません。
