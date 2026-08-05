---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer les déploiements Kubernetes (déprécié)
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> Cette fonctionnalité a été [dépréciée](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) dans GitLab 14.5.

Si vous effectuez un déploiement vers un [cluster Kubernetes](../../user/infrastructure/clusters/_index.md) associé à votre projet, vous pouvez configurer ces déploiements depuis votre fichier `.gitlab-ci.yml`.

> [!note]
> La configuration Kubernetes n'est pas prise en charge pour les clusters Kubernetes [gérés par GitLab](../../user/project/clusters/gitlab_managed_clusters.md).

Les options de configuration suivantes sont prises en charge :

- [`namespace`](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

Dans l'exemple suivant, le job déploie votre application dans l'espace de nommage Kubernetes `production`.

```yaml
deploy:
  stage: deploy
  script:
    - echo "Deploy to production server"
  environment:
    name: production
    url: https://example.com
    kubernetes:
      agent: path/to/agent/project:agent-name
      dashboard:
        namespace: production
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

Lorsque vous utilisez l'intégration Kubernetes de GitLab pour effectuer un déploiement vers un cluster Kubernetes, vous pouvez consulter les informations relatives au cluster et à l'espace de nommage. Sur la page du job de déploiement, ces informations s'affichent au-dessus de la trace du job :

![Informations sur le cluster de déploiement avec le cluster et l'espace de nommage.](img/environments_deployment_cluster_v12_8.png)

## Configurer les déploiements progressifs {#configure-incremental-rollouts}

Découvrez comment déployer des modifications en production vers une partie seulement de vos pods Kubernetes avec les [déploiements progressifs](incremental_rollouts.md).

## Sujets connexes {#related-topics}

- [Deploy boards (déprécié)](../../user/project/deploy_boards.md)
