---
title: "2つの新しいCI/CD変数: リトライ回数とジョブタグ"
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
co_create: true
documentation_link: "../../../ci/variables/predefined_variables/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/?sort=created_date&state=merged&milestone_title=19.3&label_name%5B%5D=Community%20contribution&label_name%5B%5D=release%20post%20item&label_name%5B%5D=group%3A%3Apipeline%20authoring
categories: [ Pipeline Composition ]
level: secondary
---

パイプラインスクリプトで、初回実行かどうかを判定できるようになりました。
`CI_JOB_RETRY_COUNT` は現在のジョブがリトライされた回数を保持し、初回実行時は `0` となります。これにより、リトライを考慮したロジックを実装する際に、状態を自分で管理する必要がなくなります。また、`CI_JOB_TAGS` はジョブ自身に設定されたタグを公開します。これまでは `CI_RUNNER_TAGS` を通じてRunnerのタグしか参照できませんでしたが、今回の変更でジョブのタグも確認できるようになりました。どちらも設定不要で利用できます。

[Giannis Kepas](https://gitlab.com/gkepas)さんと[Dwight Blake](https://gitlab.com/lunivilen)さんのコントリビュートに感謝します！
