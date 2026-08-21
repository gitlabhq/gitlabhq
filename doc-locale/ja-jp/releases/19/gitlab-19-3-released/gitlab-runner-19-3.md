---
title: GitLab Runner 19.3
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: https://docs.gitlab.com/runner
work_item: https://gitlab.com/gitlab-org/gitlab-runner/-/issues/?milestone_title=19.3&state=closed
categories: [ GitLab Runner Core ]
level: secondary
---

本日、GitLab Runner 19.3もリリースしました。GitLab Runnerは、CI/CDジョブを実行してその結果をGitLabインスタンスに送信する、高いスケーラビリティを持つビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

**新機能**

- [Job Routerバージョン互換性マトリックスのドキュメント化](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39408)
- [Job RouterのKASからRailsへのリクエストパスにWorkhorse が含まれることを確認](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39383)

**バグ修正**

- [`IMAGE_FILTER_FLAGS`が空の場合、`clear-docker-cache`が未使用のイメージをすべて削除する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39621)
- [Concreteモードのディスパッチで`When`が未設定のステップがスキップされる](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39539)
- [`PrintPodWarningEvents`が機能しない](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/38982)
- [`.git`フォルダーが破損している場合にカスタムexecutorが失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/27540)

すべての変更点の一覧は、GitLab Runnerの[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-3-stable/CHANGELOG.md)をご覧ください。
