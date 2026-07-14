---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Contrôler la concurrence des jobs dans GitLab CI/CD
title: Groupe de ressources
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Par défaut, les pipelines dans GitLab CI/CD s'exécutent de façon simultanée. La simultanéité est un facteur important pour améliorer la boucle de rétroaction dans les merge requests. Cependant, dans certaines situations, vous pouvez souhaiter limiter la simultanéité des jobs de déploiement afin de les exécuter un par un. Utilisez des groupes de ressources pour contrôler de façon stratégique la simultanéité des jobs et optimiser votre workflow de déploiement continu en toute sécurité.

## Ajouter un groupe de ressources {#add-a-resource-group}

Vous ne pouvez ajouter qu'une seule ressource à un groupe de ressources.

À condition que vous disposiez de la configuration de pipeline suivante (fichier `.gitlab-ci.yml` dans votre dépôt) :

```yaml
build:
  stage: build
  script: echo "Your build script"

deploy:
  stage: deploy
  script: echo "Your deployment script"
  environment: production
```

Chaque fois que vous poussez un nouveau commit vers une branche, un nouveau pipeline est exécuté avec deux jobs `build` et `deploy`. Mais si vous poussez plusieurs commits dans un court intervalle de temps, plusieurs pipelines commencent à s'exécuter simultanément, par exemple :

- Le premier pipeline exécute les jobs `build` -> `deploy`
- Le deuxième pipeline exécute les jobs `build` -> `deploy`

Dans ce cas, les jobs `deploy` de différents pipelines pourraient s'exécuter simultanément dans l'environnement `production`. L'exécution de plusieurs scripts de déploiement sur la même infrastructure pourrait endommager ou perturber l'instance et la laisser dans un état corrompu dans le pire des cas.

Pour vous assurer qu'un job `deploy` s'exécute une seule fois à la fois, vous pouvez spécifier le [mot-clé `resource_group`](../yaml/_index.md#resource_group) pour le job sensible à la simultanéité :

```yaml
deploy:
  # ...
  resource_group: production
```

Avec cette configuration, la sécurité des déploiements est garantie, tout en vous permettant d'exécuter les jobs `build` de façon simultanée pour maximiser l'efficacité du pipeline.

## Prérequis {#prerequisites}

- Familiarité avec les [pipelines GitLab CI/CD](../pipelines/_index.md)
- Familiarité avec les [environnements et déploiements GitLab](../environments/_index.md)
- le rôle Developer, Maintainer ou Owner pour le projet afin de configurer les pipelines CI/CD.

## Modes de traitement {#process-modes}

Vous pouvez sélectionner un mode de traitement pour contrôler la simultanéité des jobs selon vos préférences de déploiement. Les modes suivants sont pris en charge :

| Mode de traitement | Description | Quand l'utiliser  |
|---------------|-------------|-------------|
| `unordered` | Le mode de traitement par défaut. Traite les jobs dès qu'un job est prêt à s'exécuter. | L'ordre d'exécution des jobs n'a pas d'importance. L'option la plus simple à utiliser. |
| `oldest_first` | Lorsqu'une ressource est libre, sélectionne le premier job dans la liste des jobs à venir, triée par ID de pipeline dans l'ordre croissant. | Vous souhaitez exécuter les jobs du pipeline le plus ancien en premier. Moins efficace que le mode `unordered`, mais plus sûr pour les déploiements continus. |
| `newest_first` | Lorsqu'une ressource est libre, sélectionne le premier job dans la liste des jobs à venir, triée par ID de pipeline dans l'ordre décroissant. | Vous souhaitez exécuter les jobs du pipeline le plus récent et [empêcher les jobs de déploiement obsolètes](../environments/deployment_safety.md#prevent-outdated-deployment-jobs). Chaque job doit être idempotent. |
| `newest_ready_first` | Lorsqu'une ressource est libre, sélectionne le premier job dans la liste des jobs à venir en attente de cette ressource. Les jobs sont triés par ID de pipeline dans l'ordre décroissant. | Vous souhaitez empêcher `newest_first` de prioriser les nouveaux pipelines avant de déployer le pipeline actuel. Plus rapide que `newest_first`. Chaque job doit être idempotent. |

### Modifier le mode de traitement {#change-the-process-mode}

Pour modifier le mode de traitement d'un groupe de ressources, vous devez utiliser l'API et envoyer une requête pour [modifier un groupe de ressources existant](../../api/resource_groups.md#update-a-resource-group) en spécifiant le paramètre `process_mode` :

- `unordered`
- `oldest_first`
- `newest_first`
- `newest_ready_first`

### Exemple de différence entre les modes de traitement {#an-example-of-difference-between-the-process-modes}

Considérez le fichier `.gitlab-ci.yml` suivant, qui contient un job `build` et un job `deploy`. Chaque job s'exécute dans sa propre étape, et le job `deploy` dispose d'un groupe de ressources défini sur `production` :

```yaml
build:
  stage: build
  script: echo "Your build script"

deploy:
  stage: deploy
  script: echo "Your deployment script"
  environment: production
  resource_group: production
```

Si trois commits sont poussés vers le projet dans un court intervalle de temps, cela signifie que trois pipelines s'exécutent presque simultanément :

- Le premier pipeline exécute les jobs `build` -> `deploy`. Appelons ce job de déploiement `deploy-1`.
- Le deuxième pipeline exécute les jobs `build` -> `deploy`. Appelons ce job de déploiement `deploy-2`.
- Le troisième pipeline exécute les jobs `build` -> `deploy`. Appelons ce job de déploiement `deploy-3`.

Selon le mode de traitement du groupe de ressources :

- Si le mode de traitement est défini sur `unordered` :
  - `deploy-1`, `deploy-2` et `deploy-3` ne s'exécutent pas simultanément.
  - L'ordre d'exécution des jobs n'est pas garanti. Par exemple, `deploy-1` pourrait s'exécuter avant ou après `deploy-3`.
- Si le mode de traitement est `oldest_first` :
  - `deploy-1`, `deploy-2` et `deploy-3` ne s'exécutent pas simultanément.
  - `deploy-1` s'exécute en premier, `deploy-2` s'exécute en deuxième et `deploy-3` s'exécute en dernier.
- Si le mode de traitement est `newest_first` :
  - `deploy-1`, `deploy-2` et `deploy-3` ne s'exécutent pas simultanément.
  - `deploy-3` s'exécute en premier, `deploy-2` s'exécute en deuxième et `deploy-1` s'exécute en dernier.

## Contrôle de la simultanéité au niveau du pipeline avec les pipelines interprojets/parent-enfant {#pipeline-level-concurrency-control-with-cross-projectparent-child-pipelines}

Vous pouvez définir `resource_group` pour les pipelines downstream sensibles aux exécutions simultanées. Le [mot-clé `trigger`](../yaml/_index.md#trigger) peut déclencher des pipelines downstream et le [mot-clé `resource_group`](../yaml/_index.md#resource_group) peut coexister avec lui. `resource_group` est efficace pour contrôler la simultanéité des pipelines de déploiement, tandis que les autres jobs peuvent continuer à s'exécuter de façon simultanée.

L'exemple suivant présente deux configurations de pipeline dans un projet. Lorsqu'un pipeline commence à s'exécuter, les jobs non sensibles sont exécutés en premier et ne sont pas affectés par les exécutions simultanées dans d'autres pipelines. Cependant, GitLab s'assure qu'aucun autre pipeline de déploiement n'est en cours d'exécution avant de déclencher un pipeline de déploiement (enfant). Si d'autres pipelines de déploiement sont en cours d'exécution, GitLab attend que ces pipelines se terminent avant d'en exécuter un autre.

```yaml
# .gitlab-ci.yml (parent pipeline)

build:
  stage: build
  script: echo "Building..."

test:
  stage: test
  script: echo "Testing..."

deploy:
  stage: deploy
  trigger:
    include: deploy.gitlab-ci.yml
    strategy: mirror
  resource_group: AWS-production
```

```yaml
# deploy.gitlab-ci.yml (child pipeline)

stages:
  - provision
  - deploy

provision:
  stage: provision
  script: echo "Provisioning..."

deployment:
  stage: deploy
  script: echo "Deploying..."
  environment: production
```

Vous devez définir [`trigger:strategy`](../yaml/_index.md#triggerstrategy) pour vous assurer que le verrou n'est pas libéré avant la fin du pipeline downstream.

## Sujets connexes {#related-topics}

- [Documentation de l'API](../../api/resource_groups.md)
- [Documentation des logs](../../administration/logs/_index.md#ci_resource_groups_jsonlog)
- [GitLab pour des déploiements sécurisés](../environments/deployment_safety.md)

## Dépannage {#troubleshooting}

### Éviter les interblocages dans les configurations de pipeline {#avoid-dead-locks-in-pipeline-configurations}

Étant donné que le [mode de traitement `oldest_first`](#process-modes) impose l'exécution des jobs dans l'ordre du pipeline, il existe des cas où il ne fonctionne pas correctement avec d'autres fonctionnalités CI.

Par exemple, lorsque vous exécutez [un pipeline enfant](../pipelines/downstream_pipelines.md#parent-child-pipelines) qui nécessite le même groupe de ressources que le pipeline parent, un interblocage peut se produire. Voici un exemple de configuration incorrecte :

```yaml
# BAD
test:
  stage: test
  trigger:
    include: child-pipeline-requires-production-resource-group.yml
    strategy: mirror

deploy:
  stage: deploy
  script: echo
  resource_group: production
  environment: production
```

Dans un pipeline parent, le job `test` est exécuté, ce qui déclenche ensuite un pipeline enfant. L'[option `strategy: mirror`](../yaml/_index.md#triggerstrategy) fait attendre le job `test` jusqu'à ce que le pipeline enfant se soit terminé. Le pipeline parent exécute le job `deploy` dans l'étape suivante, qui nécessite une ressource du groupe de ressources `production`. Si le mode de traitement est `oldest_first`, les jobs des pipelines les plus anciens sont exécutés en premier, ce qui signifie que le job `deploy` est exécuté ensuite.

Cependant, un pipeline enfant nécessite également une ressource du groupe de ressources `production`. Étant donné que le pipeline enfant est plus récent que le pipeline parent, le pipeline enfant attend que le job `deploy` se termine, ce qui n'arrive jamais.

Dans ce cas, vous devriez plutôt spécifier le mot-clé `resource_group` dans la configuration du pipeline parent :

```yaml
# GOOD
test:
  stage: test
  trigger:
    include: child-pipeline.yml
    strategy: mirror
  resource_group: production # Specify the resource group in the parent pipeline

deploy:
  stage: deploy
  script: echo
  resource_group: production
  environment: production
```

### Les jobs restent bloqués dans `Waiting for resource` {#jobs-get-stuck-in-waiting-for-resource}

Parfois, un job se bloque avec le message `Waiting for resource: <resource_group>`. Pour résoudre ce problème, vérifiez d'abord que le groupe de ressources fonctionne correctement :

1. Accédez à la page des détails du job.
1. Si la ressource est attribuée à un job, sélectionnez **Voir le job qui utilise actuellement la ressource** et vérifiez le statut du job.

   - Si le statut est `running` ou `pending`, la fonctionnalité fonctionne correctement. Attendez que le job se termine et libère la ressource.
   - Si le statut est `created` et que le [mode de traitement](#process-modes) est **Plus ancien en premier** ou **Plus récent en premier**, la fonctionnalité fonctionne correctement. Visitez la page du pipeline du job et vérifiez quelle étape ou quel job en amont bloque l'exécution.
   - Si aucune des conditions précédentes n'est remplie, il est possible que la fonctionnalité ne fonctionne pas correctement. [Signalez le ticket à GitLab](#report-an-issue).

1. Si **Voir le job qui utilise actuellement la ressource** n'est pas disponible, la ressource n'est pas attribuée à un job. Vérifiez plutôt les jobs à venir de la ressource.

   1. Obtenez les jobs à venir de la ressource avec l'[API REST](../../api/resource_groups.md#list-upcoming-jobs-for-a-specific-resource-group).
   1. Vérifiez que le [mode de traitement](#process-modes) du groupe de ressources est **Plus ancien en premier**.
   1. Trouvez le premier job dans la liste des jobs à venir et obtenez les détails du job [via GraphQL](#get-job-details-through-graphql).
   1. Si le pipeline du premier job est un pipeline plus ancien, essayez d'annuler le pipeline ou le job lui-même.
   1. Facultatif. Répétez ce processus si le prochain job à venir est encore dans un pipeline plus ancien qui ne devrait plus s'exécuter.
   1. Si le problème persiste, [signalez le ticket à GitLab](#report-an-issue).

#### Conditions de concurrence dans les pipelines complexes ou très sollicités {#race-conditions-in-complex-or-busy-pipelines}

Si vous ne parvenez pas à résoudre votre problème avec les solutions ci-dessus, vous rencontrez peut-être un problème de condition de concurrence connu. La condition de concurrence se produit dans les pipelines complexes ou très sollicités. Par exemple, vous pourriez rencontrer la condition de concurrence si vous avez :

- Un pipeline avec plusieurs pipelines enfant.
- Un seul projet avec plusieurs pipelines s'exécutant simultanément.

Si vous pensez rencontrer ce problème, [signalez le ticket à GitLab](#report-an-issue) et laissez un commentaire sur le [ticket 436988](https://gitlab.com/gitlab-org/gitlab/-/issues/436988) avec un lien vers votre nouveau ticket. Pour confirmer le problème, GitLab peut demander des informations complémentaires, telles que la configuration complète de votre pipeline.

En guise de solution temporaire, vous pouvez :

- Démarrer un nouveau pipeline.
- Réexécuter un job terminé qui appartient au même groupe de ressources que le job bloqué.

  Par exemple, si vous avez un `setup_job` et un `deploy_job` avec le même groupe de ressources, le `setup_job` peut se terminer alors que le `deploy_job` est bloqué `waiting for resource`. Réexécutez le `setup_job` pour redémarrer l'ensemble du processus et permettre à `deploy_job` de se terminer.

#### Obtenir les détails d'un job via GraphQL {#get-job-details-through-graphql}

Vous pouvez obtenir des informations sur les jobs depuis l'API GraphQL. Vous devriez utiliser l'API GraphQL si vous utilisez le [contrôle de la simultanéité au niveau du pipeline avec les pipelines interprojets/parent-enfant](#pipeline-level-concurrency-control-with-cross-projectparent-child-pipelines), car les jobs de déclenchement ne sont pas accessibles depuis l'interface utilisateur.

Pour obtenir des informations sur les jobs depuis l'API GraphQL :

1. Accédez à la page des détails du pipeline.
1. Sélectionnez l'onglet **Jobs** et trouvez l'ID du job bloqué.
1. Accédez à l'[explorateur GraphQL interactif](../../api/graphql/_index.md#interactive-graphql-explorer).
1. Exécutez la requête suivante :

   ```graphql
   {
     project(fullPath: "<fullpath-to-your-project>") {
       name
       job(id: "gid://gitlab/Ci::Build/<job-id>") {
         name
         status
         detailedStatus {
           action {
             path
             buttonTitle
           }
         }
       }
     }
   }
   ```

    Le champ `job.detailedStatus.action.path` contient l'ID du job utilisant la ressource.

1. Exécutez la requête suivante et vérifiez le champ `job.status` selon les critères ci-dessus. Vous pouvez également visiter la page du pipeline depuis le champ `pipeline.path`.

   ```graphql
   {
     project(fullPath: "<fullpath-to-your-project>") {
       name
       job(id: "gid://gitlab/Ci::Build/<job-id-currently-using-the-resource>") {
         name
         status
         pipeline {
           path
         }
       }
     }
   }
   ```

### Signaler un ticket {#report-an-issue}

[Ouvrez un nouveau ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/new) avec les informations suivantes :

- L'ID du job concerné.
- Le statut du job.
- La fréquence à laquelle le problème se produit.
- Les étapes pour reproduire le problème.

  Vous pouvez également [contacter le support](https://support.gitlab.com/hc/en-us/articles/11626483177756-GitLab-Support#contact-support) pour obtenir une assistance supplémentaire ou pour prendre contact avec l'équipe de développement.
