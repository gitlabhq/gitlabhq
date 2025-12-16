---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: クラスター証明書を使用した、プロジェクトごとの複数のクラスター（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

単一プロジェクトでの複数のKubernetesクラスターを**with cluster certificates**（クラスター証明書で使用する）のは、GitLab 14.5で[deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。クラスターをGitLabに接続するには、[Kubernetes向けGitLabエージェント](../../clusters/agent/_index.md)を使用します。

{{< /alert >}}

複数のKubernetesクラスターをプロジェクトに関連付けることができます。そうすることで、開発、ステージング、本番環境など、異なる環境ごとに異なるクラスターを持つことができます。最初に行ったときと同じように別のクラスターを追加し、新しいクラスターを他と区別する[スコープを設定](#setting-the-environment-scope)するようにしてください。

## 環境スコープの設定 {#setting-the-environment-scope}

複数のKubernetesクラスターをプロジェクトに追加する場合、環境スコープを使用してそれらを区別する必要があります。環境スコープは、[environments](../../../ci/environments/_index.md)と[環境固有のCI/CD変数](../../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)がどのように機能するかと同様に、クラスターを関連付けます。

デフォルトの環境スコープは`*`で、これはすべてのジョブが、環境に関係なく、そのクラスターを使用することを意味します。各スコープはプロジェクト内の単一のクラスターでのみ使用でき、そうでない場合は検証エラーが発生します。また、環境キーワードが設定されていないジョブは、どのクラスターにもアクセスできません。

たとえば、プロジェクトに次のKubernetesクラスターがあるとします:

| クラスター     | 環境スコープ |
| ----------- | ----------------- |
| 開発 | `*`               |
| 本番環境  | `production`      |

そして、次の環境が`.gitlab-ci.yml`ファイルに設定されています:

```yaml
stages:
  - test
  - deploy

test:
  stage: test
  script: sh test

deploy to staging:
  stage: deploy
  script: make deploy
  environment:
    name: staging
    url: https://staging.example.com/

deploy to production:
  stage: deploy
  script: make deploy
  environment:
    name: production
    url: https://example.com/
```

結果:

- Developmentクラスターの詳細は、`deploy to staging`ジョブで利用できます。
- 本番環境クラスターの詳細は、`deploy to production`ジョブで利用できます。
- 環境を定義していないため、`test`ジョブではクラスターの詳細は利用できません。
