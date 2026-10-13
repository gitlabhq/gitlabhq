---
title: GitLab Flexの支出上限に関する早期警告
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: fulfillment
documentation_link: "../../../subscriptions/gitlab_flex/#adjust-your-reservation"
work_item: https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/18962
categories: [ Consumables Cost Management ]
level: secondary
---

GitLab 19.3では、予約しきい値に達した場合および上限付き機能が停止した瞬間に、メール通知が送信されるようになりました。ただし、支出上限自体には早期警告の仕組みがなく、上限に関する最初のメールが届く時点では、すでに使用が停止している状態でした。

GitLabでは、機能のオンデマンド使用量が月次支出上限の50%または80%に達した時点で、請求アカウント管理者にメールで通知するようになりました。通知には、対象の機能名とクレジット単位での上限額が記載されます。送信されるのは超過した最も高いしきい値のみで、請求期間ごとに機能あたり最大1回に限られます。なお、$10未満の上限は通知対象外となるため、少額の上限設定によって不要な通知が発生することはありません。
