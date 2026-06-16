---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Correction automatique
description: Ouvrir automatiquement des merge requests pour corriger les dépendances vulnérables.
---

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut :  Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/17403) dans GitLab 19.0 en tant qu'[expérience](../../../policy/development_stages_support.md#experiment) [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `dependency_management_auto_remediation`. Désactivé par défaut.

{{< /history >}}

La correction automatique ouvre automatiquement une merge request pour mettre à niveau une dépendance vulnérable vers une version non vulnérable lorsqu'une telle version est disponible. Un compte de service crée la merge request sans aucune intervention humaine, qui passe ensuite par le processus standard de révision et d'approbation.

Pour le roadmap bêta et les améliorations prévues, consultez l'[epic 18236](https://gitlab.com/groups/gitlab-org/-/work_items/18236).

## Activer la correction automatique {#turn-on-auto-remediation}

Prérequis :

- Vous devez avoir au moins un Maintainer pour le projet.
- Le `dependency_management_auto_remediation` [feature flag](../../../administration/feature_flags/_index.md) doit être activé.
- [L'analyse des dépendances](../dependency_scanning/_index.md) doit être activée et produire des résultats.
- Le projet doit utiliser un [gestionnaire de paquets pris en charge](#supported-package-managers).

Pour déclencher la détection des vulnérabilités et la correction automatique, exécutez un pipeline. La correction automatique se déclenche automatiquement lorsque des vulnérabilités disposant de correctifs disponibles sont détectées.

## Fonctionnement de la correction automatique {#how-auto-remediation-works}

Après chaque pipeline, GitLab vérifie les résultats de l'analyse des dépendances à la recherche de vulnérabilités dont les versions corrigées sont connues. Pour chaque vulnérabilité éligible :

1. GitLab détermine le chemin de mise à niveau sans rupture le plus proche (correctif ou mise à niveau de version mineure).
1. Un compte de service ouvre une merge request qui met à jour le fichier manifeste concerné.
1. La merge request passe par le processus d'approbation standard de votre projet.

Pendant la phase d'expérience, GitLab traite trois vulnérabilités à la fois, en commençant par le résultat ayant la gravité la plus élevée.

## Gestionnaires de paquets pris en charge {#supported-package-managers}

La correction automatique prend en charge les gestionnaires de paquets suivants :

| Langage | Gestionnaire de paquets | Fichiers                     |
| -------- | --------------- | ------------------------- |
| Ruby     | Bundler         | `Gemfile`, `Gemfile.lock` |

La prise en charge d'écosystèmes supplémentaires est prévue. Pour plus de détails, consultez l'[epic 21643](https://gitlab.com/groups/gitlab-org/-/work_items/21643).

## Problèmes connus {#known-issues}

Pendant la phase d'expérience :

- Limite de merge requests ouvertes :  Un maximum de trois merge requests de correction automatique peuvent être ouvertes par projet. Les nouvelles merge requests ne sont pas créées tant que les existantes ne sont pas fusionnées ou fermées.
- Portée de la mise à niveau de version :  Seules les mises à niveau de version corrective et mineure sont proposées. Les mises à niveau de version majeure, qui peuvent introduire des changements de rupture, ne sont pas tentées.
- Une vulnérabilité par exécution de pipeline :  Chaque exécution de pipeline cible une seule vulnérabilité disposant d'un correctif disponible. Le regroupement de plusieurs correctifs dans une seule merge request est prévu pour la version bêta.
- Aucun correctif disponible :  Si aucune version corrigée sans rupture n'existe pour une vulnérabilité, aucune merge request n'est créée pour ce résultat.
