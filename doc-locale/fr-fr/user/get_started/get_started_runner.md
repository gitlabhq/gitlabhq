---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurer et gérer GitLab Runner.
title: Premiers pas avec GitLab Runner
---

L'administration de GitLab Runner englobe le cycle de vie complet de la gestion de votre infrastructure d'exécution des jobs CI/CD :

- Déployer et enregistrer des runners
- Configurer les exécuteurs pour des charges de travail spécifiques
- Mettre à l'échelle la capacité pour accompagner la croissance de l'organisation

Le processus d'administration des runners fait partie d'un workflow plus large :

![Workflow GitLab comprenant Plan, Create, Verify (dont la gestion des runners), Secure, Release et Monitor.](img/get_started_runner_v18_3.png)

Vous gérez l'accès aux runners via les portées et les tags, surveillez les performances et maintenez la flotte de runners.

## Étape 1 :  Installer des runners {#step-1-install-runners}

Installez GitLab Runner pour créer l'application qui exécute les jobs CI/CD.

L'installation implique de télécharger et de configurer GitLab Runner sur votre infrastructure cible. Le processus d'installation varie selon le système d'exploitation cible. GitLab fournit des binaires et des instructions d'installation pour Linux, Windows, macOS et z/OS. Choisissez votre méthode d'installation en fonction de votre plateforme et de vos besoins.

Pour plus d'informations, consultez [installer GitLab Runner](https://docs.gitlab.com/runner/install/).

## Étape 2 :  Enregistrer des runners {#step-2-register-runners}

Enregistrez vos runners pour établir une communication authentifiée entre votre instance GitLab et la machine sur laquelle GitLab Runner est installé. L'enregistrement connecte les runners individuels à votre instance GitLab à l'aide de jetons d'authentification. Lors de l'enregistrement, vous spécifiez la portée du runner, le type d'exécuteur et d'autres paramètres de configuration qui déterminent le fonctionnement du runner.

Avant d'enregistrer un runner, vous devez déterminer si vous souhaitez le limiter à un groupe ou un projet GitLab spécifique. Vous pouvez configurer des runners autogérés avec différentes portées d'accès lors de l'enregistrement pour déterminer les projets pour lesquels ils sont disponibles :

- Runners d'instance :  Disponibles pour tous les projets de votre instance GitLab
- Runners de groupe :  Disponibles pour tous les projets d'un groupe spécifique et de ses sous-groupes
- Runners de projet :  Disponibles uniquement pour un projet spécifique

Lorsque vous enregistrez un runner, ajoutez-y des tags pour acheminer les jobs vers les runners appropriés. Attribuez des tags significatifs et référencez-les dans vos fichiers `.gitlab-ci.yml` pour garantir que les jobs s'exécutent sur des runners disposant des capacités requises.

Lorsqu'un job CI/CD s'exécute, il sait quel runner utiliser en consultant les tags attribués. Les tags sont le seul moyen de filtrer la liste des runners disponibles pour un job.

Pour plus d'informations, consultez :

- [Enregistrer un runner](https://docs.gitlab.com/runner/register/)
- [Migrer vers le nouveau workflow d'enregistrement des runners](../../ci/runners/new_creation_workflow.md)
- [Runners d'instance](../../ci/runners/runners_scope.md#instance-runners)
- [Runners de groupe](../../ci/runners/runners_scope.md#group-runners)
- [Runners de projet](../../ci/runners/runners_scope.md#project-runners)
- [Tags](../../ci/yaml/_index.md#tags)

## Étape 3 :  Choisir des exécuteurs {#step-3-choose-executors}

Les exécuteurs GitLab Runner sont les différents environnements et méthodes que GitLab Runner peut utiliser pour exécuter des jobs CI/CD. Ils déterminent comment et où vos jobs de pipeline s'exécutent réellement. Une configuration appropriée garantit que les jobs s'exécutent dans des environnements adaptés avec des limites de sécurité correctes.

Lorsque vous enregistrez un runner, vous devez choisir un exécuteur. GitLab Runner utilise un système d'exécuteur pour déterminer où et comment les jobs s'exécutent. Un exécuteur détermine l'environnement dans lequel chaque job s'exécute. Sélectionnez les exécuteurs qui correspondent à votre infrastructure et aux exigences de vos jobs.

Par exemple :

- Si vous souhaitez que votre job CI/CD exécute des commandes PowerShell, vous pouvez installer GitLab Runner sur un serveur Windows, puis enregistrer un runner qui utilise l'exécuteur shell.
- Si vous souhaitez que votre job CI/CD exécute des commandes dans un conteneur Docker personnalisé, vous pouvez installer GitLab Runner sur un serveur Linux et enregistrer un runner qui utilise l'exécuteur Docker.

Ces exemples ne représentent que quelques configurations possibles. Vous pouvez installer GitLab Runner sur une machine virtuelle et lui faire utiliser une autre machine virtuelle comme exécuteur.

Pour plus d'informations, consultez [les exécuteurs](https://docs.gitlab.com/runner/executors/).

## Étape 4 :  Configurer les runners et commencer à exécuter des jobs {#step-4-configure-runners-and-start-running-jobs}

Vous pouvez configurer GitLab Runners en modifiant le fichier `config.toml`, qui est généré automatiquement lors de l'installation et de l'enregistrement d'un runner. Dans ce fichier, vous pouvez modifier les paramètres d'un runner spécifique ou de tous les runners. Configurez-le pour définir les limites de concurrence, les niveaux de journalisation, les paramètres de cache, les limites CPU et les paramètres spécifiques à l'exécuteur. Utilisez des configurations cohérentes sur l'ensemble de votre flotte de runners.

Lorsqu'un runner est configuré et disponible pour votre projet, vos jobs CI/CD peuvent l'utiliser.

Les runners traitent généralement les jobs sur la même machine sur laquelle vous avez installé GitLab Runner. Cependant, vous pouvez également faire en sorte qu'un runner traite des jobs dans un conteneur, dans un cluster Kubernetes ou dans des instances à mise à l'échelle automatique dans le cloud.

Pour plus d'informations, consultez :

- [Configurer GitLab Runners](https://docs.gitlab.com/runner/configuration/advanced-configuration/)
- [Jobs CI/CD](../../ci/jobs/_index.md)

## Étape 5 :  Continuer à configurer, mettre à l'échelle et optimiser vos runners {#step-5-continue-to-configure-scale-and-optimize-your-runners}

Les fonctionnalités avancées des runners améliorent l'efficacité de l'exécution des jobs et offrent des capacités spécialisées pour les workflows CI/CD complexes. Ces optimisations réduisent la durée d'exécution des jobs et améliorent l'expérience des développeurs grâce à la mise à l'échelle automatique, la surveillance des performances, la gestion de la flotte et des configurations spécialisées.

La mise à l'échelle automatique ajuste automatiquement la capacité des runners en fonction de la demande de jobs, tandis que l'optimisation des performances garantit une utilisation efficace des ressources. Ces capacités vous aident à gérer des charges de travail variables tout en maîtrisant les coûts d'infrastructure.

La gestion de la flotte offre un contrôle centralisé et une surveillance de plusieurs runners, permettant des déploiements de runners à l'échelle de l'entreprise. La mise à l'échelle de la flotte implique de coordonner la capacité de plusieurs runners et de mettre en œuvre les meilleures pratiques opérationnelles.

Utilisez les métriques Prometheus intégrées pour surveiller la santé et les performances de vos runners. Vous pouvez suivre des métriques clés comme le nombre de jobs actifs, l'utilisation du CPU, l'utilisation de la mémoire, les taux de réussite des jobs et les longueurs de file d'attente pour garantir le fonctionnement efficace de vos runners.

Pour plus d'informations, consultez :

- [Configuration de la mise à l'échelle automatique](https://docs.gitlab.com/runner/runner_autoscale/)
- [Mise à l'échelle de la flotte](https://docs.gitlab.com/runner/fleet_scaling/)
- [Configuration de la flotte de runners et meilleures pratiques](../../topics/runner_fleet_design_guides/_index.md)
- [Surveiller les performances des runners](https://docs.gitlab.com/runner/monitoring/)
- [Tableau de bord de la flotte de runners](../../ci/runners/runner_fleet_dashboard.md)
- [Long polling](../../ci/runners/long_polling.md)
- [Configuration Docker-in-Docker](https://docs.gitlab.com/runner/executors/docker/)
- [GitLab Runner Infrastructure Toolkit (GRIT)](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit)
