---
title: その他の機能強化
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: verify
co_create: true
documentation_link: "../../../api/job_artifacts/#download-job-artifacts-by-job-id"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252518
categories: [ Job Artifacts ]
level: secondary
---

このリリースのその他の改善点は以下のとおりです。

- APIから特定のレポートアーティファクトをフェッチできるようになりました。ダウンロード可能なタイプに限定され、アーティファクトごとの認可チェックによってアクセスが制御されます。たとえば、JUnitファイルを取得するには `GET /projects/:id/jobs/:job_id/artifacts?file_type=junit` を使用します。
- 管理者は、ジョブアーティファクトおよびパッケージのダウンロードにおいて、クライアントが直接302リダイレクトとプロキシ経由の転送を選択できるように設定できます。
- パイプラインエディタが、バックエンドですでにサポートされているCI/CDキーワードを検証するようになりました。
- 件名が空のメールがバウンスされる代わりに、サービスデスクチケットが作成されるようになりました。
- `Dependency-Scanning.v2` テンプレートに新しく追加された2つのタイムアウト入力を使用して、依存関係の解決制限を自分で引き上げられるようになりました。
- 管理者は、各ユーザーがメールで送られたリンクを承認しなくても、アチーブメントがプロフィールに表示されるよう設定できます。

これらのコントリビュートをいただいた以下のユーザーの皆さんに感謝します！

- [Andreas Kunze](https://gitlab.com/and2345) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252518))
- [André Düwel](https://gitlab.com/duewel1982) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252350))
- [Paweł Farys](https://gitlab.com/vertisan) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250636))
- [Praveen Arimbrathodiyil](https://gitlab.com/pravi) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248600))
- [Niklas van Schrick](https://gitlab.com/Taucher2003) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249426))
- [BoxBoxJason](https://gitlab.com/BoxBoxJason) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249893))
