---
title: Child pipelines can depend on parent jobs optionally
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: verify
co_create: false
documentation_link: "../../../ci/yaml/#needspipelinejob"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/349538
categories: [ Continuous Integration (CI) ]
level: secondary
weight: 20
---

Many development teams split large CI/CD setups into parent and child pipelines so each part is easier to manage.
Until now, a child pipeline job couldn't safely depend on a parent job that only runs under certain conditions,
such as tests that run only when certain files change. If that parent job was skipped,
the child job broke, so teams had to work around it with duplicate jobs or brittle scripts.

Now you can mark these dependencies as optional. If the parent job runs, the child waits for it as usual.
If it doesn't run, the child job goes ahead without it. Pipelines stay fast and reliable without the workarounds,
and a failure in a job that does run still stops the pipeline, so quality checks aren't weakened.

Thank you to [Jimmy Spagnola](https://gitlab.com/jspagnola) for this contribution!
