---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab CI/CDを使用して、GitLabプロジェクトをHerokuにデプロイします。
title: GitLab CI/CDを使用してHerokuにデプロイする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab CI/CDを使用して、アプリケーションをHerokuにデプロイできます。

## 前提要件 {#prerequisites}

- [Heroku](https://id.heroku.com/login)アカウント。既存のHerokuアカウントでサインインするか、新しいアカウントを作成します。

## Herokuにデプロイする {#deploy-to-heroku}

1. Herokuの場合:
   1. アプリケーションを作成し、アプリケーション名をコピーします。
   1. **Account Settings**（アカウント設定）を参照して、APIキーをコピーします。
1. GitLabプロジェクトで、2つの[変数](../variables/_index.md)を作成します:
   - `HEROKU_APP_NAME`：アプリケーション名。
   - `HEROKU_PRODUCTION_KEY`：APIキー
1. `.gitlab-ci.yml`ファイルを編集して、Herokuのデプロイコマンドを追加します。この例では、Ruby用の`dpl`gemを使用します:

   ```yaml
   heroku_deploy:
     stage: production
     script:
       - gem install dpl
       - dpl --provider=heroku --app=$HEROKU_APP_NAME --api-key=$HEROKU_PRODUCTION_KEY
   ```
