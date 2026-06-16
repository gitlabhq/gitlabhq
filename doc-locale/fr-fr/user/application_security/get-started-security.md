---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Testez votre application et résolvez les vulnérabilités.
title: Premiers pas pour sécuriser votre application
---

Identifiez et remédiez aux vulnérabilités dans le code source de votre application. Intégrez les tests de sécurité dans le cycle de vie du développement logiciel en analysant automatiquement votre code pour détecter les problèmes de sécurité potentiels.

Vous pouvez analyser différents langages de programmation et frameworks, et détecter des vulnérabilités comme les injections SQL, le cross-site scripting (XSS) et les dépendances non sécurisées. Les résultats des analyses de sécurité sont affichés dans l'interface utilisateur GitLab, où vous pouvez les examiner et les traiter.

Ces fonctionnalités peuvent également être intégrées à d'autres fonctionnalités GitLab, comme les merge requests et les pipelines, pour garantir que la sécurité est une priorité tout au long du processus de développement.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, voir [Adopting GitLab application security](https://www.youtube.com/watch?v=5QlxkiKR04k)

<i class="fa-youtube-play" aria-hidden="true"></i> [View an interactive reading and how-to demo playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9)

Ce processus fait partie d'un workflow plus large :

![Workflow](img/get_started_app_sec_v16_11.png)

## Étape 1 :  En savoir plus sur l'analyse {#step-1-learn-about-scanning}

La détection des secrets analyse votre dépôt pour empêcher l'exposition de vos secrets. Elle fonctionne avec tous les langages de programmation.

L'analyse des dépendances examine les dépendances de votre application à la recherche de vulnérabilités connues. Elle fonctionne avec certains langages et gestionnaires de paquets.

Pour plus d'informations, consultez :

- [Détection des secrets](secret_detection/_index.md)
- [Analyse des dépendances](dependency_scanning/_index.md)

## Étape 2 :  Choisir un projet à tester {#step-2-choose-a-project-to-test}

Si c'est la première fois que vous configurez l'analyse de sécurité GitLab, vous devriez commencer par un seul projet. Le projet doit :

- Utiliser les langages de programmation et les technologies habituels de votre organisation, car certaines fonctionnalités d'analyse fonctionnent différemment selon les langages.
- Vous permettre d'essayer de nouveaux paramètres, comme les approbations requises, sans interrompre le travail quotidien de votre équipe. Vous pouvez créer une copie d'un projet à fort trafic, ou sélectionner un projet moins actif.

## Étape 3 :  Activer l'analyse {#step-3-enable-scanning}

Pour identifier les secrets divulgués et les paquets vulnérables dans le projet, créez une merge request qui active la détection des secrets et l'analyse des dépendances.

Cette merge request met à jour votre fichier `.gitlab-ci.yml`, afin que les analyses s'exécutent dans le cadre du pipeline CI/CD de votre projet.

Dans le cadre de cette merge request, vous pouvez modifier les paramètres pour adapter la structure ou la configuration de votre projet. Par exemple, vous pouvez exclure un répertoire de code tiers.

Une fois cette merge request fusionnée dans votre branche par défaut, le système crée un scan de référence. Cette analyse identifie les vulnérabilités qui existent déjà sur la branche par défaut. Ensuite, les merge requests mettront en évidence les nouveaux problèmes introduits.

Sans scan de référence, les merge requests affichent chaque vulnérabilité dans la branche, même si la vulnérabilité existe déjà sur la branche par défaut.

Pour plus d'informations, consultez :

- [Activer la détection des secrets](secret_detection/pipeline/_index.md#getting-started)
- [Paramètres de détection des secrets](secret_detection/pipeline/configure.md)
- [Activer l'analyse des dépendances](dependency_scanning/dependency_scanning_sbom/_index.md#turn-on-dependency-scanning)
- [Paramètres d'analyse des dépendances](dependency_scanning/dependency_scanning_sbom/_index.md#available-cicd-variables)

## Étape 4 :  Examiner les résultats des analyses {#step-4-review-scan-results}

Permettez à votre équipe de se familiariser avec la consultation des résultats de sécurité dans les merge requests et le rapport de vulnérabilités.

Établissez un workflow de triage des vulnérabilités. Envisagez de créer des labels et des tableaux des tickets pour faciliter la gestion des tickets créés à partir des vulnérabilités. Grâce aux tableaux des tickets, toutes les parties prenantes disposent d'une vue commune de tous les tickets et peuvent suivre la progression de la remédiation.

Surveillez les tendances du tableau de bord de sécurité pour évaluer le succès de la remédiation des vulnérabilités existantes et la prévention de l'introduction de nouvelles.

Pour plus d'informations, consultez :

- [Afficher le rapport de vulnérabilités](vulnerability_report/_index.md)
- [Afficher les résultats de sécurité dans les merge requests](detect/security_scanning_results.md)
- [Afficher le tableau de bord de sécurité](security_dashboard/_index.md)
- [Labels](../project/labels.md)
- [Tableaux des tickets](../project/issue_board.md)

## Étape 5 :  Planifier les futurs jobs d'analyse {#step-5-schedule-future-scanning-jobs}

Appliquez des jobs d'analyse de sécurité planifiés en utilisant une politique d'exécution de scan. Ces jobs planifiés s'exécutent indépendamment de toute autre analyse de sécurité que vous pourriez avoir définie dans un pipeline de framework de conformité ou dans le fichier `.gitlab-ci.yml` du projet.

Les analyses planifiées sont particulièrement utiles pour les projets ou les branches importantes avec une faible activité de développement et pour lesquels les analyses de pipeline sont peu fréquentes.

Pour plus d'informations, consultez :

- [Politique d'exécution de scan](policies/scan_execution_policies.md)
- [Analyses de conteneurs](container_scanning/_index.md)
- [Analyse opérationnelle de conteneurs](../clusters/agent/vulnerabilities.md)

## Étape 6 :  Limiter les nouvelles vulnérabilités {#step-6-limit-new-vulnerabilities}

Pour imposer les types d'analyses requis et garantir la séparation des responsabilités entre la sécurité et l'ingénierie, utilisez des politiques d'exécution de scan.

Pour limiter les nouvelles vulnérabilités fusionnées dans votre branche par défaut, créez une politique d'approbation des merge requests.

Une fois que vous êtes familiarisé avec le fonctionnement de l'analyse, vous pouvez choisir de :

- Suivre les mêmes étapes pour activer l'analyse dans d'autres projets.
- Appliquer l'analyse à un plus grand nombre de vos projets à la fois.

Pour plus d'informations, consultez :

- [Politiques d'exécution de scan](policies/scan_execution_policies.md)
- [Politique d'approbation des merge requests](policies/_index.md)

## Étape 7 :  Continuer à analyser les nouvelles vulnérabilités {#step-7-continue-scanning-for-new-vulnerabilities}

Au fil du temps, vous souhaitez vous assurer qu'aucune nouvelle vulnérabilité n'est introduite.

- Pour faire apparaître les vulnérabilités nouvellement découvertes qui existent déjà dans votre dépôt, exécutez régulièrement des analyses de dépendances et de conteneurs.
- Pour analyser les images de conteneurs dans votre cluster de production à la recherche de vulnérabilités de sécurité, activez l'analyse opérationnelle de conteneurs.
- Activez d'autres types d'analyses, comme SAST, DAST ou les tests de fuzzing.
- Pour autoriser le DAST et le fuzzing d'API Web sur des environnements de test éphémères, envisagez d'activer les environnements éphémères.

Pour plus d'informations, consultez :

- [SAST](sast/_index.md)
- [DAST](dast/_index.md)
- [Tests de fuzzing](coverage_fuzzing/_index.md)
- [Fuzzing d'API Web](api_fuzzing/_index.md)
- [Environnements éphémères](../../ci/review_apps/_index.md)
