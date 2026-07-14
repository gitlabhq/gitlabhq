---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Déploiements progressifs avec GitLab CI/CD
description: "Kubernetes, CI/CD, atténuation des risques et déploiement."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lors du déploiement de modifications dans votre application, il est possible de publier les changements en production uniquement sur une partie de vos pods Kubernetes, dans le cadre d'une stratégie d'atténuation des risques. En publiant progressivement les modifications en production, il est possible de surveiller les taux d'erreurs ou la dégradation des performances, et si aucun problème n'est détecté, tous les pods peuvent être mis à jour.

GitLab prend en charge les déploiements progressifs déclenchés manuellement et planifiés vers un système Kubernetes de production. Lors de l'utilisation des déploiements manuels, la release de chaque tranche de pods est déclenchée manuellement. Avec les déploiements planifiés, la release est effectuée par tranches après une pause par défaut de 5 minutes. Les déploiements planifiés peuvent également être déclenchés manuellement avant l'expiration de la période de pause.

Les déploiements manuels et planifiés sont inclus automatiquement dans les projets gérés par [Auto DevOps](../../topics/autodevops/_index.md), mais ils sont également configurables via GitLab CI/CD dans le fichier de configuration `.gitlab-ci.yml`.

Les déploiements déclenchés manuellement peuvent être mis en œuvre avec la livraison continue, tandis que les déploiements planifiés ne nécessitent aucune intervention et peuvent faire partie de votre stratégie de déploiement continu. Vous pouvez également combiner les deux de manière à ce que l'application soit déployée automatiquement, sauf si vous intervenez manuellement si nécessaire.

Les exemples d'applications suivants illustrent les trois options. Vous pouvez les utiliser comme exemples pour créer les vôtres :

- [Déploiements progressifs manuels](https://gitlab.com/gl-release/incremental-rollout-example/blob/master/.gitlab-ci.yml)
- [Déploiements progressifs planifiés](https://gitlab.com/gl-release/timed-rollout-example/blob/master/.gitlab-ci.yml)
- [Déploiements manuels et planifiés combinés](https://gitlab.com/gl-release/incremental-timed-rollout-example/blob/master/.gitlab-ci.yml)

## Déploiements manuels {#manual-rollouts}

Il est possible de configurer GitLab pour effectuer des déploiements progressifs manuellement via `.gitlab-ci.yml`. La configuration manuelle permet un meilleur contrôle de cette fonctionnalité. Les étapes d'un déploiement progressif dépendent du nombre de pods définis pour le déploiement, qui sont configurés lors de la création du cluster Kubernetes.

Par exemple, si votre application dispose de 10 pods et qu'un job de déploiement à 10 % s'exécute, la nouvelle instance de l'application est déployée sur un seul pod, tandis que les autres pods affichent l'instance précédente de l'application.

Tout d'abord, [définissez le modèle comme manuel](https://gitlab.com/gl-release/incremental-rollout-example/blob/master/.gitlab-ci.yml#L100-103) :

```yaml
.manual_rollout_template: &manual_rollout_template
  <<: *rollout_template
  stage: production
  when: manual
```

Ensuite, [définissez la quantité de déploiement pour chaque étape](https://gitlab.com/gl-release/incremental-rollout-example/blob/master/.gitlab-ci.yml#L152-155) :

```yaml
rollout 10%:
  <<: *manual_rollout_template
  variables:
    ROLLOUT_PERCENTAGE: 10
```

Une fois les jobs créés, sélectionnez **Exécution** ({{< icon name="play" >}}) à côté du nom du job pour publier chaque étape de pods. Vous pouvez également effectuer un rollback en exécutant un job avec un pourcentage inférieur. Une fois les 100 % atteints, il n'est plus possible de revenir en arrière avec cette méthode. Pour effectuer un rollback d'un déploiement, consultez [relancer ou annuler un déploiement](deployments.md#retry-or-roll-back-a-deployment).

Une [application déployable](https://gitlab.com/gl-release/incremental-rollout-example) est disponible, illustrant les déploiements progressifs déclenchés manuellement.

## Déploiements planifiés {#timed-rollouts}

Les déploiements planifiés se comportent de la même manière que les déploiements manuels, à la différence que chaque job est défini avec un délai en minutes avant son déploiement. La sélection du job affiche le compte à rebours.

![Un déploiement planifié en cours.](img/timed_rollout_v17_9.png)

Il est possible de combiner cette fonctionnalité avec des déploiements progressifs manuels, de sorte que le job effectue un compte à rebours avant de déployer.

Tout d'abord, [définissez le modèle comme planifié](https://gitlab.com/gl-release/timed-rollout-example/blob/master/.gitlab-ci.yml#L86-89) :

```yaml
.timed_rollout_template: &timed_rollout_template
  <<: *rollout_template
  when: delayed
  start_in: 1 minutes
```

Vous pouvez définir la période de délai à l'aide de la clé `start_in` :

```yaml
start_in: 1 minutes
```

Ensuite, [définissez la quantité de déploiement pour chaque étape](https://gitlab.com/gl-release/timed-rollout-example/blob/master/.gitlab-ci.yml#L97-101) :

```yaml
timed rollout 30%:
  <<: *timed_rollout_template
  stage: timed rollout 30%
  variables:
    ROLLOUT_PERCENTAGE: 30
```

Une [application déployable](https://gitlab.com/gl-release/timed-rollout-example) est disponible, [illustrant la configuration des déploiements planifiés](https://gitlab.com/gl-release/timed-rollout-example/blob/master/.gitlab-ci.yml#L86-95).

## Déploiement bleu/vert {#blue-green-deployment}

> [!note]
> Les équipes peuvent exploiter une annotation Ingress et [définir le poids du trafic](../../user/project/canary_deployments.md#how-to-change-the-traffic-weight-on-a-canary-ingress-deprecated) comme alternative à la stratégie de déploiement bleu/vert documentée ici.

Également connue sous le nom de déploiement A/B ou déploiement rouge/noir, cette technique est utilisée pour réduire les interruptions de service et les risques lors d'un déploiement. Combinée aux déploiements progressifs, elle permet de minimiser l'impact d'un déploiement causant un problème.

Avec cette technique, il existe deux déploiements (« bleu » et « vert », mais tout autre nommage peut être utilisé). Un seul de ces déploiements est actif à tout moment, sauf lors d'un déploiement progressif.

Par exemple, votre déploiement bleu peut être actif en production, tandis que le déploiement vert est « actif » pour les tests, mais n'est pas déployé en production. Si des problèmes sont détectés, le déploiement vert peut être mis à jour sans affecter le déploiement en production (actuellement bleu). Si les tests ne révèlent aucun problème, vous basculez la production vers le déploiement vert, et le bleu est désormais disponible pour tester la prochaine release.

Ce processus réduit les interruptions de service, car il n'est pas nécessaire d'arrêter le déploiement en production pour basculer vers un autre déploiement. Les deux déploiements s'exécutent en parallèle et peuvent être activés à tout moment.

Un [exemple d'application déployable](https://gitlab.com/gl-release/blue-green-example) est disponible, avec un [fichier de configuration CI/CD `.gitlab-ci.yml`](https://gitlab.com/gl-release/blue-green-example/blob/master/.gitlab-ci.yml) illustrant les déploiements bleu/vert.
