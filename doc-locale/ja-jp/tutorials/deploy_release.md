---
stage: none
group: Tutorials
info: For assistance with this tutorials page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: デプロイプロセスとターゲット。
title: 'チュートリアル: アプリケーションをデプロイおよびリリースする'
---

## パッケージとコンテナの管理 {#manage-packages-and-containers}

アーティファクトを管理するために、パッケージとコンテナレジストリーの使用方法を説明します。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [GitLabパッケージとリリース機能](https://university.gitlab.com/courses/gitlab-package-and-release-functions) | この自分のペースで進められるコースで、レジストリとリリース機能の基本を学びます。 | {{< icon name="star" >}} |
| [CI/CDでパッケージを自動的にビルドして公開する](../user/packages/pypi_repository/auto_publish_tutorial.md) | PyPIパッケージを自動的にビルド、テストし、パッケージレジストリに公開する方法を学習します。 | {{< icon name="star" >}} |
| [エンタープライズの拡大に合わせてパッケージレジストリを構造化する](../user/packages/package_registry/enterprise_structure_tutorial.md) | パッケージを大規模にアップロード、管理、使用するための組織をセットアップします。 | |
| [GitLab CI/CDでPythonパッケージをビルドして署名する](../user/packages/package_registry/pypi_cosign_tutorial.md)  | GitLab CI/CDとSigstore Cosignを使用してPythonパッケージ用の安全なパイプラインをビルドする方法を学習します。 | |
| [ビルド来歴データでコンテナイメージにアノテーションを付与する](../user/packages/container_registry/cosign_tutorial.md) | Cosignを使用してコンテナイメージの構築、署名、および注釈付けのプロセスを自動化する方法について説明します。 | |
| [Amazon ECRからGitLabにコンテナイメージを移行する](../user/packages/container_registry/migrate_containers_ecr_tutorial.md) | Amazon Elastic Container Registry（ECR）からGitLabコンテナレジストリへのコンテナイメージの一括移行を自動化します。 | |

## 静的ウェブサイトを公開する {#publish-a-static-website}

GitLab Pagesを使用して、プロジェクトから直接静的ウェブサイトを公開します。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [CI/CDテンプレートからPagesウェブサイトを作成する](../user/project/pages/getting_started/pages_ci_cd_template.md) | 一般的な静的サイトジェネレーター（SSG）用のCI/CDテンプレートを使用して、プロジェクトのPagesウェブサイトをすばやく生成します。 | {{< icon name="star" >}} |
| [Pagesウェブサイトをゼロから作成する](../user/project/pages/getting_started/pages_from_scratch.md) | 空のプロジェクトからPagesウェブサイトのすべてのコンポーネントを作成します。 | |
| [GitLabでHugoサイトをビルド、テスト、デプロイする](hugo/_index.md) | CI/CDテンプレートとGitLab Pagesを使用してHugoサイトを生成します。 | {{< icon name="star" >}} |
