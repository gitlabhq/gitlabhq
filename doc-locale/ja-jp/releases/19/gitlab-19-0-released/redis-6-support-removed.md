---
title: Redis 6のサポートを終了
stage: gitlab_delivery
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed ]
documentation_link: "../../../install/requirements/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/585839"
categories: [ Omnibus Package ]
weight: 30
---

GitLab 19.0では、Redis 6のサポートが終了しました。外部のRedis 6デプロイを使用している場合は、アップグレード前にRedis 7.2またはValkey 7.2に移行してください。Linuxパッケージに同梱されているバンドル版Redisは、GitLab 16.2以降Redis 7を使用しており、影響を受けません。
