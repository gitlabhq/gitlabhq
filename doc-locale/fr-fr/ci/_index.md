---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Créez et testez votre application.
title: Premiers pas avec GitLab CI/CD
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD est une méthode continue de développement logiciel, dans laquelle vous créez, testez, déployez et surveillez en continu des modifications de code itératives.

Ce processus itératif permet de réduire le risque de développer du nouveau code basé sur des versions précédentes défectueuses ou échouées. GitLab CI/CD peut détecter les bugs tôt dans le cycle de développement et aider à s'assurer que le code déployé en production est conforme à vos standards de code établis.

Ce processus fait partie d'un workflow plus large :

![Cycle de vie GitLab DevSecOps avec les étapes Plan, Create, Verify, Secure, Release et Monitor.](img/get_started_cicd_v16_11.png)

## Étape 1 :  Configurer votre pipeline {#step-1-configure-your-pipeline}

Pour utiliser GitLab CI/CD, vous commencez par un fichier `.gitlab-ci.yml` à la racine de votre projet. Ce fichier spécifie les étapes, les jobs et les scripts à exécuter lors de votre pipeline CI/CD. Il s'agit d'un fichier YAML avec sa propre syntaxe personnalisée.

Par défaut, le fichier est nommé `.gitlab-ci.yml`, mais vous pouvez utiliser n'importe quel nom de fichier.

Dans ce fichier, vous définissez des variables, des dépendances entre les jobs et vous indiquez quand et comment chaque job doit être exécuté.

Un pipeline est défini dans le fichier `.gitlab-ci.yml` et s'exécute lorsque le fichier est lancé sur un runner.

Les pipelines sont composés d'étapes et de jobs :

- Les étapes définissent l'ordre d'exécution. Les étapes typiques peuvent être `build`, `test` et `deploy`.
- Les jobs spécifient les tâches à effectuer à chaque étape. Par exemple, un job peut compiler ou tester du code.

Les pipelines peuvent être déclenchés par divers événements, tels que des commits ou des fusions, ou peuvent être planifiés. Dans votre pipeline, vous pouvez vous intégrer à un large éventail d'outils et de plateformes.

Pour plus d'informations, consultez :

- [Tutoriel : Créez et exécutez votre premier pipeline CI/CD GitLab](quick_start/_index.md)
- [Pipelines](pipelines/_index.md)

## Étape 2 :  Trouver ou créer des runners {#step-2-find-or-create-runners}

Les runners sont les agents qui exécutent vos jobs. Ces agents peuvent s'exécuter sur des machines physiques ou des instances virtuelles. Dans votre fichier `.gitlab-ci.yml`, vous pouvez spécifier une image de conteneur à utiliser lors de l'exécution du job. Le runner charge l'image, clone votre projet et exécute le job localement ou dans le conteneur.

Si vous utilisez GitLab.com, des runners sous Linux, Windows et macOS sont déjà disponibles. Si nécessaire, vous pouvez également enregistrer vos propres runners.

Si vous n'utilisez pas GitLab.com, vous pouvez :

- Enregistrer des runners ou utiliser des runners déjà enregistrés pour votre instance GitLab Self-Managed.
- Créer un runner sur votre machine locale.

Pour plus d'informations, consultez :

- [Créez, enregistrez et exécutez votre propre runner de projet](../tutorials/create_register_first_runner/_index.md)

## Étape 3 :  Utiliser les variables CI/CD et les expressions CI/CD {#step-3-use-cicd-variables-and-expressions}

Les variables CI/CD GitLab sont des paires clé-valeur que vous utilisez pour stocker et transmettre des paramètres de configuration et des informations sensibles, comme des mots de passe ou des clés API, aux jobs dans un pipeline.

Les expressions GitLab CI/CD vous permettent d'injecter des données dynamiquement dans la configuration de votre pipeline. Les données disponibles dépendent du contexte de l'expression. Par exemple, le contexte `inputs` vous permet d'accéder aux informations transmises dans le fichier de configuration depuis un fichier parent ou lors de l'exécution d'un pipeline.

### Variables CI/CD {#cicd-variables}

Utilisez les variables CI/CD pour personnaliser les jobs en rendant les valeurs définies ailleurs accessibles aux jobs. Vous pouvez coder en dur des variables CI/CD dans votre fichier `.gitlab-ci.yml`, les définir dans les paramètres de votre projet ou les générer dynamiquement. Vous pouvez les définir pour le projet, le groupe ou l'instance.

Les types de variables suivants sont disponibles :

- Variables personnalisées :  Variables que vous créez et gérez dans l'interface utilisateur, l'API ou les fichiers de configuration.
- Variables prédéfinies :  Variables que GitLab définit automatiquement pour fournir des informations sur le job, le pipeline et l'environnement en cours.

Vous pouvez configurer des variables avec des paramètres de sécurité :

- Variables protégées :  Restreignez l'accès aux jobs s'exécutant sur des branches ou des tags protégés.
- Variables masquées :  Masquez les valeurs des variables dans les job logs pour éviter que des informations sensibles ne soient exposées.

Pour plus d'informations, consultez :

- [Variables CI/CD](variables/_index.md)

### Expressions CI/CD {#cicd-expressions}

Les expressions CI/CD utilisent la syntaxe `$[[ ]]` et sont validées lors de la création d'un pipeline. Vous pouvez également valider des expressions dans l'éditeur de pipeline avant de committer les modifications.

Les expressions permettent une configuration dynamique basée sur différents contextes :

- **Inputs context** (`$[[ inputs.INPUT_NAME ]]`) :  Accédez aux paramètres typés transmis dans les fichiers de configuration avec `include:inputs` ou lors de l'exécution d'un nouveau pipeline
- **Matrix context** (`$[[ matrix.IDENTIFIER ]]`) :  Accédez aux valeurs de matrice dans les dépendances de jobs pour créer des mappages 1:1 entre les jobs de matrice

Pour plus d'informations, consultez :

- [Expressions CI](yaml/expressions.md)

## Étape 4 :  Utiliser les composants CI/CD {#step-4-use-cicd-components}

Un composant CI/CD est une unité de configuration de pipeline réutilisable. Utilisez un composant CI/CD pour composer une configuration de pipeline entière ou une petite partie d'un pipeline plus grand.

Vous pouvez ajouter un composant à la configuration de votre pipeline avec `include:component`.

Les composants réutilisables permettent de réduire la duplication, d'améliorer la maintenabilité et de favoriser la cohérence entre les projets. Créez un projet de composant et publiez-le dans le catalogue CI/CD pour partager votre composant entre plusieurs projets.

GitLab propose également des modèles de composants CI/CD pour les tâches courantes et les intégrations.

Pour plus d'informations, consultez :

- [Composants CI/CD](components/_index.md)
