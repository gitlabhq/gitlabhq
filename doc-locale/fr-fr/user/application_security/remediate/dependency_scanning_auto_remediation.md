---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Remédiation automatique de l'analyse des dépendances"
description: Ouvrir automatiquement des merge requests pour corriger les dépendances vulnérables.
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version bêta

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/17403) dans GitLab 19.0 en tant que [version expérimentale](../../../policy/development_stages_support.md#experiment) [avec le feature flag](../../../administration/feature_flags/_index.md) `dependency_management_auto_remediation`. Désactivés par défaut.
- [Passage](https://gitlab.com/groups/gitlab-org/-/work_items/604588) à la [version bêta](../../../policy/development_stages_support.md#beta) dans GitLab 19.2. Le feature flag `dependency_management_auto_remediation` est activé par défaut.
- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/603392) de la résolution agentique des changements cassants dans GitLab 19.2 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `enable_dependency_bump_breaking_changes`. Désactivés par défaut.

{{< /history >}}

La remédiation automatique de l'analyse des dépendances ouvre une merge request pour mettre à jour une dépendance vulnérable vers une version non vulnérable lorsqu'une telle version est disponible. Un compte de service crée la merge request sans aucune intervention humaine, qui passe ensuite par le processus standard de révision et d'approbation.

En version bêta, la remédiation automatique de l'analyse des dépendances prend en charge deux fonctionnalités configurables indépendamment :

- Mises à jour de version des dépendances : GitLab ouvre des merge requests qui mettent à jour la dépendance vulnérable.
- Résolution agentique des changements cassants : lorsqu'une mise à jour de version provoque un échec de pipeline en raison d'un changement cassant, GitLab Duo tente de le résoudre. Pour plus d'informations, consultez [activer la résolution agentique des changements cassants](#enable-agentic-breaking-change-resolution).

Pour le roadmap de disponibilité générale, consultez l'[epic 19244](https://gitlab.com/groups/gitlab-org/-/work_items/19244).

## Activer la remédiation automatique de l'analyse des dépendances {#turn-on-dependency-scanning-auto-remediation}

Prérequis :

- Le feature flag `dependency_management_auto_remediation` [feature flag](../../../administration/feature_flags/_index.md) doit être activé pour le projet. Ce flag est activé par défaut dans GitLab 19.2.
- [L'analyse des dépendances](../dependency_scanning/_index.md) doit être activée et produire des résultats.
- Le projet doit utiliser un [gestionnaire de paquets pris en charge](#supported-package-managers).
- Un profil de remédiation automatique de l'analyse des dépendances doit être associé au projet. Pour les instructions, consultez [le profil de remédiation automatique de l'analyse des dépendances](../configuration/security_configuration_profiles.md#dependency-scanning-auto-remediation-profile).

Pour déclencher la détection des vulnérabilités et la remédiation automatique, exécutez un pipeline. La remédiation automatique de l'analyse des dépendances se déclenche automatiquement lorsque GitLab détecte des vulnérabilités pour lesquelles des correctifs sont disponibles.

## Fonctionnement des mises à jour de version des dépendances {#how-dependency-version-bumps-work}

Le profil de remédiation automatique de l'analyse des dépendances contrôle ce comportement. Avec le profil par défaut :

- Seuil de gravité : GitLab remédie aux vulnérabilités dont la gravité est égale ou supérieure à `high`.
- Période de refroidissement : GitLab exclut les versions de correctifs publiées au cours des sept derniers jours.
- Politique de mise à jour : GitLab propose uniquement des mises à jour de versions patch et mineures, sauf si la [résolution agentique des changements cassants](#enable-agentic-breaking-change-resolution) est activée.
- Limite de merge requests ouvertes : un maximum de 10 merge requests de remédiation automatique peut être ouvert par projet à la fois. GitLab ne crée pas de nouvelles merge requests tant que les existantes ne sont pas fusionnées ou fermées.

Après chaque pipeline, GitLab vérifie les résultats d'analyse des dépendances par rapport à ces valeurs. Pour chaque vulnérabilité éligible :

1. GitLab détermine le chemin de mise à jour non cassant le plus proche.
1. Un compte de service ouvre une merge request qui met à jour le fichier manifeste concerné.
1. GitLab assigne un Mainteneur actif du projet comme relecteur. Si aucun Mainteneur actif n'existe, la merge request reste ouverte sans relecteur.
1. La merge request passe par le processus d'approbation standard de votre projet.

En version bêta, GitLab traite trois vulnérabilités à la fois, en commençant par le résultat de gravité la plus élevée.

## Activer la résolution agentique des changements cassants {#enable-agentic-breaking-change-resolution}

Lorsqu'une mise à jour de version provoque un échec de pipeline en raison d'un changement cassant, GitLab Duo peut tenter de résoudre ce changement cassant automatiquement. Cette fonctionnalité est distincte de la fonctionnalité de mise à jour de version des dépendances et dispose de son propre bouton bascule.

Prérequis :

- Vous devez disposer de [GitLab Duo](../../../user/gitlab_duo/_index.md) pour le projet.
- Le feature flag `enable_dependency_bump_breaking_changes` [feature flag](../../../administration/feature_flags/_index.md) doit être activé pour l'espace de nommage racine du projet.

Pour activer la résolution agentique des changements cassants, utilisez l'[API Projects](../../../api/projects.md#update-a-project) pour définir `duo_dependency_bump_breaking_changes_enabled` sur `true` pour le projet.

## Configurer la simultanéité du planificateur {#configure-scheduler-concurrency}

Les administrateurs peuvent limiter le nombre de jobs du planificateur de remédiation automatique s'exécutant simultanément sur la flotte Sidekiq. Utilisez le [paramètre d'application](../../../api/settings.md) `security_update_scheduler_max_concurrency` pour définir la limite maximale. La valeur par défaut est `30`, et la valeur est plafonnée à `200`. Définissez la valeur sur `0` pour suspendre la planification.

## Gestionnaires de paquets pris en charge {#supported-package-managers}

La remédiation automatique de l'analyse des dépendances prend en charge les gestionnaires de paquets suivants :

| Langage                | Gestionnaire de paquets                     | Fichiers                                                                          |
| ----------------------- | ------------------------------------ | ------------------------------------------------------------------------------ |
| Ruby                    | Bundler                             | `Gemfile`, `Gemfile.lock`                                                      |
| Java                    | Maven                               | `pom.xml`                                                                      |
| Java                    | Gradle                              | `build.gradle`, `build.gradle.kts`                                             |
| Python                  | pip, pipenv, poetry, setuptools, uv | `requirements.txt`, `Pipfile`, `pyproject.toml`, `setup.py`, `uv.lock`         |
| JavaScript / TypeScript | npm, yarn, pnpm, bun                | `package.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lock` |

La prise en charge d'écosystèmes supplémentaires est proposée dans l'[epic 19244](https://gitlab.com/groups/gitlab-org/-/work_items/19244).

## Problèmes connus {#known-issues}

Pendant la phase bêta :

- Période de refroidissement : GitLab ne propose pas de version de correctif publiée au cours des sept derniers jours, afin de réduire le risque de remédier vers une version qui s'avérerait ultérieurement défectueuse ou malveillante.
- Portée de la mise à niveau de version : seules les mises à niveau de version corrective ou mineure sont proposées. Les mises à jour de versions majeures, plus susceptibles d'introduire des changements cassants, ne sont pas tentées sauf si la résolution agentique des changements cassants est activée.
Le regroupement de plusieurs correctifs en une seule merge request est proposé dans l'[epic 19244](https://gitlab.com/groups/gitlab-org/-/work_items/19244).
- Aucun correctif disponible : si aucune version corrigée non cassante n'existe pour une vulnérabilité, aucune merge request n'est créée pour ce résultat.
