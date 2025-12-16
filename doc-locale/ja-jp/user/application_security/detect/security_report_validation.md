---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: セキュリティレポートの検証
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

セキュリティレポートは、コンテンツがデータベースに追加される前に検証されます。これにより、破損した脆弱性データがデータベースに取り込まれるのを防ぎます。検証に失敗したレポートは、パイプラインの**セキュリティ**タブに検証エラーメッセージとともに表示されます。

検証は、レポートで宣言されたスキーマバージョンに従って、[report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/tree/master/dist)に対して行われます:

- セキュリティレポートがサポートされているスキーマバージョンを指定している場合、GitLabはこのバージョンを使用して検証します。
- セキュリティレポートが非推奨のバージョンを使用している場合、GitLabはそのバージョンに対して検証を試み、検証結果に非推奨の警告を追加します。
- セキュリティレポートがレポートスキーマのサポートされているメジャーマイナーバージョンを使用しているが、パッチバージョンがベンダーバージョンと一致しない場合、GitLabはスキーマの最新のベンダーパッチバージョンに対して検証を試みます。
  - 例: セキュリティレポートはバージョン14.1.1を使用しますが、最新のベンダーバージョンは14.1.0です。GitLabは、スキーマバージョン14.1.0に対して検証します。
- セキュリティレポートがサポートされていないバージョンを使用している場合、GitLabはインストールで使用可能な最も古いスキーマバージョンに対して検証を試みますが、レポートをインジェストしません。
- セキュリティレポートがスキーマバージョンを指定していない場合、GitLabはGitLabで使用可能な最も古いスキーマバージョンに対して検証を試みます。`version`プロパティは必須であるため、この場合、検証は常に失敗しますが、他の検証エラーも存在する可能性があります。

サポートされているスキーマバージョンと非推奨のスキーマバージョンの詳細については、[schema validator source code](https://gitlab.com/gitlab-org/ruby/gems/gitlab-security_report_schemas/-/blob/main/supported_versions)を参照してください。
