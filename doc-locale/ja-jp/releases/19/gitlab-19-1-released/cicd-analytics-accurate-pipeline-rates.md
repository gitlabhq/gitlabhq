---
title: CI/CD分析で正確なパイプライン率を表示
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: verify
documentation_link: "../../../user/analytics/ci_cd_analytics"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/599923
categories: [ Continuous Integration (CI) ]
level: secondary
---

以前のバージョンのGitLabでは、CI/CD分析ページ（`<project>/-/pipelines/charts`）の失敗率と成功率のメトリクスに、キャンセルされたパイプラインとスキップされたパイプラインが計算に含まれていました。これにより、両方の率が予想より低く表示されていました。たとえば、`gitlab-org/gitlab`では、2つの率の合計が約100%ではなく98%にとどまっていました。

今回のリリースで、GitLabは完了したパイプラインのみを使用して失敗率と成功率を計算するようになり、結果がパイプラインの健全性を正確に反映するようになりました。
