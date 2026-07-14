---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Runners
description: Configuration et exécution des jobs.
---

Les runners sont les agents qui exécutent l'application [GitLab Runner](https://docs.gitlab.com/runner/) pour exécuter les jobs GitLab CI/CD dans un pipeline. Ils sont responsables de l'exécution de vos builds, tests, déploiements et autres tâches CI/CD définis dans les fichiers `.gitlab-ci.yml`.

## Flux d'exécution des runners {#runner-execution-flow}

Voici un workflow de base décrivant le fonctionnement des runners :

1. Un runner doit d'abord être [enregistré](https://docs.gitlab.com/runner/register/) auprès de GitLab, ce qui établit une connexion persistante entre le runner et GitLab.
1. Lorsqu'un pipeline est déclenché, GitLab met les jobs à la disposition des runners enregistrés.
1. Les runners correspondants récupèrent les jobs, un job par runner, et les exécutent.
1. Les résultats sont remontés à GitLab en temps réel.

Pour plus d'informations, voir [Flux d'exécution des runners](https://docs.gitlab.com/runner/#runner-execution-flow).

## Planification et exécution des jobs de runner {#runner-job-scheduling-and-execution}

Lorsqu'un job CI/CD doit être exécuté, GitLab crée un job basé sur les tâches définies dans le fichier `.gitlab-ci.yml`. Les jobs sont placés dans une file d'attente. GitLab recherche les runners disponibles qui correspondent aux critères suivants :

- Tags des runners
- Types de runners (comme partagés ou groupe)
- Statut et capacité des runners
- Capacités requises

Le runner assigné reçoit les détails du job. Le runner prépare l'environnement et exécute les commandes du job telles que spécifiées dans le fichier `.gitlab-ci.yml`.

## Catégories de runners {#runner-categories}

Pour décider quels runners vous souhaitez utiliser pour exécuter vos jobs CI/CD, vous pouvez choisir :

- [Runners hébergés par GitLab](hosted_runners/_index.md) pour les utilisateurs de GitLab.com ou de GitLab Dedicated.
- [Runners auto-gérés](https://docs.gitlab.com/runner/) pour toutes les installations GitLab.

Les runners peuvent être des runners de groupe, des runners de projet ou des runners d'instance. Les runners hébergés par GitLab sont des runners d'instance.

### Runners hébergés par GitLab {#gitlab-hosted-runners}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Dedicated

{{< /details >}}

Les runners hébergés par GitLab sont :

- Entièrement gérés par GitLab.
- Disponibles immédiatement, sans configuration préalable.
- Exécutés sur de nouvelles machines virtuelles pour chaque job.
- Proposent des options Linux, Windows et macOS.
- Mis à l'échelle automatiquement en fonction de la demande.

Optez pour les runners hébergés par GitLab dans les cas suivants :

- Vous souhaitez un CI/CD sans maintenance.
- Vous avez besoin d'une configuration rapide sans gestion d'infrastructure.
- Vos jobs nécessitent une isolation entre les exécutions.
- Vous travaillez avec des environnements de build standard.
- Vous utilisez GitLab.com ou GitLab Dedicated.

### Runners auto-gérés {#self-managed-runners}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les runners auto-gérés sont :

- Installés et gérés par vos soins.
- Exécutés sur votre propre infrastructure.
- Personnalisables selon vos besoins.
- Compatibles avec divers exécuteurs (notamment Shell, Docker et Kubernetes).
- Peuvent être partagés ou associés à des projets ou groupes spécifiques.

Optez pour les runners auto-gérés dans les cas suivants :

- Vous avez besoin de configurations personnalisées.
- Vous souhaitez exécuter des jobs dans votre réseau privé.
- Vous avez besoin de contrôles de sécurité spécifiques.
- Vous avez besoin de runners de projet ou de runners de groupe.
- Vous devez optimiser la vitesse grâce à la réutilisation des runners.
- Vous souhaitez gérer votre propre infrastructure.

## Sujets connexes {#related-topics}

- [Installer GitLab Runner](https://docs.gitlab.com/runner/install/)
- [Configurer GitLab Runner](https://docs.gitlab.com/runner/configuration/)
- [Administrer GitLab Runner](https://docs.gitlab.com/runner/)
- [Runners hébergés pour GitLab Dedicated](../../administration/dedicated/hosted_runners.md)
