---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Routeur de jobs
description: Acheminez les jobs CI/CD via le routeur de jobs pour une orchestration avancée des jobs.
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated
- Statut : Version expérimentale

{{< /details >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/19607) dans GitLab 18.7 [avec des feature flags](../../../administration/feature_flags/_index.md) nommés `job_router` et `job_router_instance_runners`. Désactivé par défaut.
- [Contrôle d'admission introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/584394) dans GitLab 18.9 [avec un flag](../../../administration/feature_flags/_index.md) nommé `job_router_admission_control`. Désactivé par défaut.

{{< /history >}}

Le routeur de jobs est un composant de GitLab Relay (KAS) qui fournit des capacités avancées d'orchestration de jobs pour GitLab CI/CD. Au lieu de runners qui interrogent GitLab directement pour les jobs, les runners se connectent au routeur de jobs, qui gère la distribution des jobs et fournit des fonctionnalités telles que le contrôle d'admission.

## Architecture {#architecture}

```plaintext
GitLab Instance → Job Router (KAS) → Runner
                        ↓
              Runner Controller (optional)
```

Le routeur de jobs :

- Reçoit les requêtes de jobs des runners
- Répond aux runners avec les jobs à exécuter
- Consulte optionnellement les contrôleurs de runner pour les décisions d'admission

## Prérequis {#prerequisites}

Pour utiliser le routeur de jobs, vous devez disposer des éléments suivants :

- Instance GitLab avec les feature flags suivants définis sur `true` :
  - `job_router` :  Pour les runners de groupe et de projet
  - `job_router_instance_runners` :  Pour les runners d'instance
  - `job_router_admission_control` :  Pour le contrôle d'admission (optionnel)
- GitLab Runner 18.9 ou version ultérieure avec la variable d'environnement `FF_USE_JOB_ROUTER` définie sur `true`.

## Découvrir les informations du routeur de jobs {#discover-job-router-information}

Les runners peuvent découvrir l'URL du routeur de jobs en utilisant l'[API de découverte du routeur de jobs](../../../api/runners.md#discover-job-router-information).

## Contrôleurs de runner {#runner-controllers}

Les contrôleurs de runner permettent le contrôle d'admission pour les jobs acheminés via le routeur de jobs. Pour plus d'informations, consultez [les contrôleurs de runner](runner_controllers.md).

## Sujets connexes {#related-topics}

- [Contrôleurs de runner](runner_controllers.md)
- [API des contrôleurs de runner](../../../api/runner_controllers.md)
- [API des portées de contrôleurs de runner](../../../api/runner_controllers.md#runner-controller-scopes)
- [API des tokens de contrôleurs de runner](../../../api/runner_controller_tokens.md)
- [Tutoriel : Créer un contrôleur d'admission de runner](../../../tutorials/build_runner_admission_controller/_index.md)
