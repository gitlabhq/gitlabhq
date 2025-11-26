---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: OpenShift上でGitLab Self-ManagedおよびGitLab Runnerフリートを実行し、Kubernetes向けGitLabエージェントと統合します。
title: OpenShiftのサポート
---

OpenShiftとGitLabの互換性は、3つの異なる側面から対応できます。このページでは、これらの側面間の移動を支援し、OpenShiftとGitLabを使い始めるための入門情報を提供します。

## OpenShiftとは {#what-is-openshift}

OpenShiftは、コンテナベースのアプリケーションの開発、デプロイ、および管理に役立ちます。オンデマンドでアプリケーションを作成、変更、およびデプロイするためのセルフサービスプラットフォームを提供し、開発とリリースのライフサイクルを高速化します。

## OpenShiftを使用してGitLab Self-Managedを実行する {#use-openshift-to-run-gitlab-self-managed}

GitLab Operatorを使用すると、OpenShiftクラスターでGitLabを実行できます。OpenShiftでのGitLabのセットアップの詳細については、[GitLab Operator](https://docs.gitlab.com/operator/)を参照してください。

## OpenShiftを使用してGitLab Runnerフリートを実行する {#use-openshift-to-run-a-gitlab-runner-fleet}

GitLab OperatorにはGitLab Runnerは含まれていません。OpenShiftクラスターにGitLab Runner Runnerフリートをインストールおよび管理するには、[GitLab Runner Operator](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator)を使用します。

### GitLabからOpenShiftへのデプロイと統合 {#deploy-to-and-integrate-with-openshift-from-gitlab}

GitLabからOpenShift上にカスタムまたはCOTSアプリケーションをデプロイすることは、[Kubernetes向けGitLabエージェント](../../user/clusters/agent/_index.md)を使用してサポートされています。

### サポートされていないGitLabの機能 {#unsupported-gitlab-features}

#### Docker-in-Docker {#docker-in-docker}

OpenShiftを使用してGitLab Runnerフリートを実行する場合、OpenShiftのセキュリティモデルを考えると、一部のGitLab機能はサポートされていません。Docker-in-Dockerを必要とする機能は動作しない場合があります。

Auto DevOpsでは、次の機能はまだサポートされていません:

- [Auto Code Quality](../../ci/testing/code_quality.md)
- [ライセンス承認ポリシー](../../user/compliance/license_approval_policies.md)
- Auto Browser Performance Testing
- Auto Build
- [運用コンテナスキャン（OCS）](../../user/clusters/agent/vulnerabilities.md)（注: パイプラインでの[コンテナスキャン](../../user/application_security/container_scanning/_index.md)はサポートされています）
