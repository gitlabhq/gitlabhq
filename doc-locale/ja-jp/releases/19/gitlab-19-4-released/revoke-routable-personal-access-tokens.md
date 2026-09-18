---
title: ルーティング可能なパーソナルアクセストークンの自動失効
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: application_security_testing
documentation_link: "../../../user/application_security/secret_detection/automatic_response"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/623418
categories: [ Secret Detection ]
---

シークレット検出が公開プロジェクトで漏洩したGitLabパーソナルアクセストークンを検出すると、自動レスポンスによってそのトークンが失効します。GitLab 19.4より前のバージョンでは、失効処理は1つの検出ルールのみを使用し、レガシートークン形式のみを失効させていました。GitLab 18.3以降で作成されたトークンは、ルーティング可能形式またはバージョン付きルーティング可能形式を使用します。GitLabはこれらのトークンを検出してレポートしていましたが、失効させることはありませんでした。

GitLab 19.4以降では、失効処理がGitLabパーソナルアクセストークンの3つの検出ルールすべてに対応しました。

- `gitlab_personal_access_token`
- `gitlab_personal_access_token_routable`
- `gitlab_personal_access_token_routable_versioned`

失効処理は、[GitLab Secret Scanning for Source Code](../../../user/application_security/secret_detection/gitlab_secret_scanner/_index.md)および[Gitleaksベースのアナライザー](../../../user/application_security/secret_detection/pipeline/_index.md)からの検出結果にも対応しています。設定を変更する必要はありません。自動レスポンスが有効なインスタンスでは、この拡張されたカバレッジがすぐに適用されます。
