---
title: カスタムフローのYAML検証
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/duo_agent_platform/flows/custom"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/597224
categories: [ AI Catalog ]
stage: ai-powered
level: secondary
weight: 50
---
AIカタログで、カスタムフローの設定を保存またはトリガーする前に検証できるようになりました。

これまでは、カスタムフローにおける構文エラーや設定ミス（例: 入力の欠落や不明なツールパラメーター）は、CIジョブが開始された後のランタイム時にしか検出できませんでした。そのため、デバッグに時間がかかり、困難を伴うことがありました。

今回のリリースで、AIカタログでカスタムフローを保存または更新する際に、GitLabが設定を事前にチェックし、エラーをUIに直接表示するようになりました。問題のないフローには影響がなく、これまでどおり保存およびトリガーできます。
