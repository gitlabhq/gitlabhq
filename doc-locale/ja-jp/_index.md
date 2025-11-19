---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: ソフトウェア開発向けの、最もスケーラブルなGitベースの完全統合プラットフォームであるGitLabの使用方法と管理方法について説明します。
title: GitLabドキュメント
---

<!-- markdownlint-disable MD041 MD044-->

<div class="d-none">
  <h3>最新バージョンのヘルプ情報、強化されたナビゲーション、フォーマット、検索については、<a href="https://docs.gitlab.com/ee/">docs.gitlab.com</a>をご覧ください。</h3>
</div>
<!-- the div tag will not display on the docs site but will display on /help -->

<!-- markdownlint-enable MD044 -->

ドキュメントのさまざまな領域を調査する:

|                         |                         |
|:------------------------|:------------------------|
| [**GitLabを使用する**](user/_index.md)<br>GitLabの機能の使用を開始します。 | [**GitLabを管理する**](administration/_index.md)<br/>Self-ManagedインスタンスのGitLabを管理します。 |
| [**GitとGitLabを初めて使用する**](tutorials/_index.md)<br/>GitとGitLabについて学習を開始します。 | [**GitLabソフトウェア開発にコントリビュートする**](#contribute-to-gitlab)<br/>新しいGitLabの機能とGitLabドキュメントを作成します。 |
| [**別のプラットフォームからGitLabに移行する**](#coming-to-gitlab-from-another-platform)<br/>GitLabへの移行方法について説明します。 | [**GitLabとのインテグレーションを構築する**](#build-an-integration-with-gitlab)<br/>Jiraやその他の一般的なアプリケーションとインテグレーションします。 |
| [**サブスクリプションを選択する**](subscriptions/_index.md)<br/>どのサブスクリプション層が自分に適しているかを判断します。 | [**GitLabをインストールする**](install/_index.md)<br/>さまざまなプラットフォームにGitLabをインストールします。 |
| [**リファレンスアーキテクチャ**](administration/reference_architectures/_index.md)<br/>大規模環境向け推奨デプロイをご確認ください。 | [**GitLabをアップグレードする**](update/_index.md)<br/>Self-ManagedインスタンスのGitLabを最新バージョンにアップグレードします。 |

## 人気のトピック {#popular-topics}

最も人気のあるトピックをいくつか表示します:

| 人気のトピック                                                                  | 説明 |
|:-------------------------------------------------------------------------------|:------------|
| [CI/CD YAML構文リファレンス](ci/yaml/_index.md)                                | `.gitlab-ci.yml`ファイルで使用可能な設定オプション。 |
| [REST API](api/rest/_index.md)                                                  | REST APIを使用してGitLabを拡張します。 |
| [環境とデプロイ](ci/environments/_index.md)                       | アプリケーションをさまざまな環境にデプロイします。 |
| [Runnerの設定](ci/runners/configure_runners.md)                         | Runnerの使用を開始します。 |
| [2要素認証](user/profile/account/two_factor_authentication.md) | GitLabアカウントのセキュリティを強化します。 |
| [GitLabのバックアップと復元](administration/backup_restore/_index.md)           | Self-ManagedインスタンスのGitLabをバックアップおよび復元する。 |
| [GitLabのリリースおよびメンテナンスポリシー](policy/maintenance.md)                 | アップグレードの方法とタイミングを決定します。 |
| [SSHキー](user/ssh.md)                                                        | SSHキーを使用してGitLabと通信します。 |

## ユーザーアカウント {#user-accounts}

GitLabアカウントの管理について説明します:

| トピック                                                      | 説明 |
|:-----------------------------------------------------------|:------------|
| [ユーザーアカウント](user/profile/_index.md)                      | アカウントを管理します。 |
| [認証](administration/auth/_index.md)           | 2要素認証によるアカウントセキュリティ、SSHキーのセットアップ、およびプロジェクトへの安全なアクセス用のデプロイキー。 |
| [ユーザー設定](user/profile/_index.md#access-your-user-settings) | ユーザー設定、2要素認証などを管理します。 |
| [ユーザー権限](user/permissions.md)                    | プロジェクト内の各ロールで何ができるかについて説明します。 |

## 別のプラットフォームからGitLabに移行する {#coming-to-gitlab-from-another-platform}

別のプラットフォームからGitLabに移行する場合:

| トピック                                                                                  | 説明 |
|:---------------------------------------------------------------------------------------|:------------|
| [GitLabにインポート](user/project/import/_index.md)                                       | GitHub、Bitbucket、GitLab.com、FogBugz、SVNからGitLabにプロジェクトをインポートします。 |
| [SVNから移行する](user/project/import/_index.md#import-repositories-from-subversion)   | SVNリポジトリをGitおよびGitLabに変換します。 |

## GitLabとのインテグレーションをビルドする {#build-an-integration-with-gitlab}

GitLabとのインテグレーションをビルドするには:

| トピック                                       | 説明 |
|:--------------------------------------------|:------------|
| [GitLab REST API](api/rest/_index.md)       | REST APIを使用してGitLabとインテグレーションします。 |
| [GitLab GraphQL API](api/graphql/_index.md) | GraphQL APIを使用してGitLabとインテグレーションします。 |
| [インテグレーション](integration/_index.md)       | サードパーティ製品とのインテグレーション |

## GitLabにコントリビュートする {#contribute-to-gitlab}

GitLabにコントリビュートする:

| トピック                                                       | 説明 |
|:------------------------------------------------------------|:------------|
| [GitLabソフトウェア開発にコントリビュートする](development/_index.md)。  | GitLabソフトウェア開発にコントリビュートする。 |
| [GitLabドキュメントにコントリビュートする](development/documentation/_index.md) | GitLabドキュメントにコントリビュートする。 |
