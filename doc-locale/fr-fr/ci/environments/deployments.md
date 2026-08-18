---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Déploiements
description: "Déploiements, restaurations, sécurité et approbations."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous déployez une version de votre code dans un environnement, vous créez un déploiement. Il n'y a généralement qu'un seul déploiement actif par environnement.

GitLab :

- Fournit un historique complet des déploiements pour chaque environnement.
- Effectue le suivi de vos déploiements, de sorte que vous savez toujours ce qui est déployé sur vos serveurs.

Si vous disposez d'un service de déploiement tel que [Kubernetes](../../user/infrastructure/clusters/_index.md) associé à votre projet, vous pouvez l'utiliser pour faciliter vos déploiements.

Une fois un déploiement créé, vous pouvez le déployer progressivement auprès des utilisateurs.

## Configurer des déploiements manuels {#configure-manual-deployments}

Vous pouvez créer un job qui nécessite qu'une personne démarre manuellement le déploiement. Par exemple :

```yaml
deploy_prod:
  stage: deploy
  script:
    - echo "Deploy to production server"
  environment:
    name: production
    url: https://example.com
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
```

L'action `when: manual` :

- Affiche le bouton **Exécution** ({{< icon name="play" >}}) pour le job dans l'interface GitLab, avec le texte **Can be manually deployed to `<environment>`**.
- Indique que le job `deploy_prod` doit être déclenché manuellement.

Vous pouvez trouver **Exécution** ({{< icon name="play" >}}) dans les vues des pipelines, des environnements, des déploiements et des jobs.

## Suivre les merge requests nouvellement incluses par déploiement {#track-newly-included-merge-requests-per-deployment}

GitLab peut suivre les merge requests nouvellement incluses par déploiement. Lorsqu'un déploiement réussit, le système calcule les diff de commits entre le dernier déploiement et le déploiement précédent. Vous pouvez récupérer les informations de suivi via l'[API Deployment](../../api/deployments.md#list-all-merge-requests-associated-with-a-deployment) ou les consulter dans un pipeline post-merge sur les [pages de merge request](../../user/project/merge_requests/_index.md).

Pour activer le suivi, configurez votre environnement de façon à ce que l'une ou l'autre des conditions suivantes soit remplie :

- Le [nom d'environnement](../yaml/_index.md#environmentname) n'utilise pas de dossiers avec `/` (environnements de longue durée ou de niveau supérieur).
- Le [niveau d'environnement](_index.md#deployment-tier-of-environments) est soit `production` soit `staging`.

  Voici quelques exemples de configurations utilisant le [mot-clé `environment`](../yaml/_index.md#environment) dans `.gitlab-ci.yml` :

  ```yaml
  # Trackable
  environment: production
  environment: production/aws
  environment: development

  # Non Trackable
  environment: review/$CI_COMMIT_REF_SLUG
  environment: testing/aws
  ```

Les modifications de configuration s'appliquent uniquement aux nouveaux déploiements. Les enregistrements de déploiement existants ne comportent pas de merge requests liées ou déliées.

## Consulter les déploiements localement {#check-out-deployments-locally}

Une référence dans le dépôt Git est sauvegardée pour chaque déploiement, de sorte que connaître l'état de vos environnements actuels est à portée d'une commande `git fetch`.

Dans votre configuration Git, ajoutez au bloc `[remote "<your-remote>"]` une ligne fetch supplémentaire :

```plaintext
fetch = +refs/environments/*:refs/remotes/origin/environments/*
```

## Archiver les anciens déploiements {#archive-old-deployments}

Lorsqu'un nouveau déploiement se produit dans votre projet, GitLab crée [une référence Git spéciale vers le déploiement](#check-out-deployments-locally). Ces références Git étant alimentées depuis le dépôt GitLab distant, certaines opérations Git, telles que `git-fetch` et `git-pull`, peuvent devenir plus lentes à mesure que le nombre de déploiements dans votre projet augmente.

Pour maintenir l'efficacité de vos opérations Git, GitLab ne conserve que les références de déploiement récentes (jusqu'à 50 000) et supprime le reste des anciennes références de déploiement. Les déploiements archivés restent disponibles, dans l'interface utilisateur ou via l'API, à des fins d'audit. De plus, vous pouvez toujours récupérer le commit déployé depuis le dépôt en spécifiant le SHA du commit (par exemple, `git checkout <deployment-sha>`), même après l'archivage.

> [!note]
> GitLab conserve tous les commits sous forme de [refs `keep-around`](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size) afin que les commits déployés ne soient pas supprimés par le ramasse-miettes, même s'ils ne sont pas référencés par les références de déploiement.

## Restauration de déploiement {#deployment-rollback}

Lorsque vous restaurez un déploiement sur un commit spécifique, un nouveau déploiement est créé. Ce déploiement possède son propre identifiant de job unique. Il pointe vers le commit vers lequel vous effectuez la restauration.

Pour que la restauration réussisse, le processus de déploiement doit être défini dans le `script` du job.

Seuls les [jobs de déploiement](../jobs/_index.md#deployment-jobs) sont exécutés. Dans les cas où un job précédent génère des artefacts qui doivent être régénérés lors du déploiement, vous devez exécuter manuellement les jobs nécessaires depuis la page des pipelines. Par exemple, si vous utilisez Terraform et que vos commandes `plan` et `apply` sont séparées en plusieurs jobs, vous devez exécuter manuellement les jobs pour déployer ou effectuer une restauration.

### Réessayer ou restaurer un déploiement {#retry-or-roll-back-a-deployment}

En cas de problème avec un déploiement, vous pouvez le réessayer ou le restaurer.

Pour réessayer ou restaurer un déploiement :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. Sélectionnez l'environnement.
1. À droite du nom du déploiement :
   - Pour réessayer un déploiement, sélectionnez **Redéployer dans l'environnement**.
   - Pour restaurer un déploiement, à côté d'un déploiement précédemment réussi, sélectionnez **Restaurer l'environnement**.

> [!note]
> Si vous avez [empêché les jobs de déploiement obsolètes](deployment_safety.md#prevent-outdated-deployment-jobs) dans votre projet, les boutons de restauration peuvent être masqués ou désactivés. Dans ce cas, consultez [les nouvelles tentatives de job pour les déploiements de restauration](deployment_safety.md#job-retries-for-rollback-deployments).

## Sujets connexes {#related-topics}

- [Environnements](_index.md)
- [Pipelines downstream pour les déploiements](../pipelines/downstream_pipelines.md#downstream-pipelines-for-deployments)
- [Déployer dans plusieurs environnements avec GitLab CI/CD (article de blog)](https://about.gitlab.com/blog/ci-deployment-and-environments/)
- [Environnements éphémères](../review_apps/_index.md)
- [Suivre les déploiements d'un outil de déploiement externe](external_deployment_tools.md)

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec des déploiements, vous pouvez rencontrer les problèmes suivants.

### Les références de déploiement sont introuvables {#deployment-refs-are-not-found}

GitLab [supprime les anciennes références de déploiement](#archive-old-deployments) pour maintenir les performances de votre dépôt Git.

Si vous devez restaurer des références Git archivées sur GitLab Self-Managed, demandez à un administrateur d'exécuter la commande suivante dans la console Rails :

```ruby
Project.find_by_full_path(<your-project-full-path>).deployments.where(archived: true).each(&:create_ref)
```

GitLab pourrait abandonner cette prise en charge à l'avenir pour des raisons de performance. Vous pouvez ouvrir un ticket dans le [GitLab Issue Tracker](https://gitlab.com/gitlab-org/gitlab/-/issues/new) pour discuter du comportement de cette fonctionnalité.
