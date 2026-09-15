---
title: CI/CDジョブトークンを使用したクロスプロジェクトへのプッシュ
stage: verify
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../ci/jobs/ci_job_token/#allow-cross-project-git-push-requests-from-allowlisted-projects"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/issues/479907"
categories: [ Continuous Integration (CI) ]
weight: 120
---

以前のバージョンのGitLabでは、CI/CDジョブトークン（`CI_JOB_TOKEN`）を使用してプッシュできるのは、パイプラインが実行されている同じリポジトリのみでした。クロスプロジェクトへのプッシュには、個人アクセストークンまたはデプロイトークンが必要でした。

以下の条件を満たす場合、ジョブトークンを使用して別のプロジェクトにプッシュできるようになりました。

1. ターゲットプロジェクトがオプトインしている。
1. パイプラインを開始するユーザーが、ターゲットプロジェクトで少なくともデベロッパーロールを持っている。

この機能は機能フラグ `allow_push_to_allowlisted_projects` の背後にあり、GitLab 19.0ではデフォルトで無効になっています。管理者に有効化を依頼してください。
