---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Guide d'utilisation de GitLab Duo Workflow pour appliquer automatiquement des directives de style de codage Java à des projets, avec la configuration, l'exécution et des exemples de cas d'utilisation."
title: "Cas d'utilisation de Duo Workflow pour l'application d'un style de codage"
---

{{< details >}}

- Édition : Ultimate avec GitLab Duo Workflow
- Offre : GitLab.com
- Statut : version expérimentale

{{< /details >}}

## Premiers pas {#getting-started}

### Télécharger le composant de solution {#download-the-solution-component}

1. Obtenez le code d'invitation auprès de votre équipe de compte.
1. Téléchargez le composant de solution depuis [la boutique de composants de solution](https://cloud.gitlab-accelerator-marketplace.com) en utilisant votre code d'invitation.

## Cas d'utilisation de Duo Workflow : améliorer une application Java avec un guide de style {#duo-workflow-use-case-improve-java-application-with-style-guide}

Ce document décrit la solution GitLab Duo Workflow avec sa bibliothèque de prompts et de contexte. L'objectif de la solution est d'améliorer le codage des applications en fonction d'un style défini.

Cette solution fournit un ticket GitLab comme prompt et le guide de style comme contexte, conçue pour automatiser les directives de style Java sur des bases de code à l'aide de GitLab Duo Workflow. La bibliothèque de prompts et de contexte permet à Duo Workflow de :

1. Accéder au contenu centralisé du guide de style stocké dans le dépôt GitLab,
1. Comprendre les normes de codage spécifiques à un domaine, et
1. Appliquer une mise en forme cohérente au code Java tout en préservant les fonctionnalités.

Pour des informations détaillées sur GitLab Duo Workflow, consultez [le document ici](../../../user/duo_agent_platform/_index.md).

### Avantages clés {#key-benefits}

- **Enforces consistent style** sur toutes les bases de code Java
- **Automates style application** sans effort manuel
- **Maintains code functionality** tout en améliorant la lisibilité
- **Integrates with GitLab for VS Code** pour une implémentation fluide
- **Reduces code review time** consacré au traitement des problèmes de style
- **Serves as a learning tool** pour aider les équipes de développement à comprendre les directives de style

### Exemple de résultat {#sample-result}

Lorsqu'il est correctement configuré, le prompt transforme votre code pour qu'il corresponde aux normes d'entreprise, comme le montre la transformation illustrée dans ce diff :

![Vue Duo Workflow affichant les instructions, l'analyse des tâches et les étapes de résolution](img/duoworkflow-style_output_v17_10.png)

![Extrait de code mis à jour avec une mise en forme cohérente après la transformation par le guide de style de Duo Workflow](img/duoworkflow_style_code_transform_v17_10.png)

## Configurer la bibliothèque de prompts et de contexte de la solution {#configure-the-solution-prompt-and-context-library}

### Configuration de base {#basic-setup}

Pour exécuter le workflow agentique afin de réviser et d'appliquer le style à votre application, vous devez configurer ce prompt de cas d'utilisation et cette bibliothèque de contexte.

1. **Set up the prompt and context library** en clonant le projet `Enterprise Code Quality Standards`
1. **Create a GitLab issue** `Review and Apply Style` avec le contenu du prompt issu du fichier de bibliothèque `.gitlab/workflows/java-style-workflow.md`
1. **In the issue** `Review and Apply Style`, configurez les variables du workflow comme décrit dans la [section Configuration](#configuration-guide)
1. **In your VS code** avec le projet `Enterprise Code Quality Standards`, démarrez Duo Workflow avec un simple [prompt de workflow](#example-duo-workflow-prompt)
1. **Work with the Duo Workflow** en examinant le plan proposé et les tâches automatisées ; si nécessaire, apportez des informations supplémentaires au workflow
1. **Review and commit** des modifications de code stylisées dans votre dépôt

### Exemple de prompt Duo Workflow {#example-duo-workflow-prompt}

```yaml
Follow the instructions in issue <issue_reference_id> for the file <path/file_name.java>. Make sure to access any issues or GitLab projects mentioned in the issue to retrieve all necessary information.
```

Ce prompt simple est efficace car il indique à Duo Workflow de :

1. Lire les exigences détaillées dans un ID de ticket spécifique
1. Accéder au dépôt du guide de style référencé
1. Appliquer les directives au fichier spécifié
1. Suivre toutes les instructions du ticket

## Guide de configuration {#configuration-guide}

Le prompt est défini dans le fichier `.gitlab/workflows/java-style-workflow.md` du package de solution. Ce fichier sert de modèle pour créer des tickets GitLab qui indiquent à l'agent de workflow de concevoir le plan d'automatisation de la revue du guide de style sur votre application et d'appliquer les modifications.

Dans la première section de `.gitlab/workflows/java-style-workflow.md`, il définit les variables à configurer pour le prompt.

### Définition des variables {#variable-definition}

Les variables sont définies directement dans le fichier `.gitlab/workflows/java-style-workflow.md`. Ce fichier sert de modèle pour créer des tickets GitLab qui indiquent à l'agent d'IA comment procéder. Vous modifierez les variables dans ce fichier avant de créer un nouveau ticket avec son contenu.

#### 1\. Dépôt du guide de style comme contexte {#1-style-guide-repository-as-the-context}

Le prompt doit être configuré pour pointer vers le dépôt du guide de style de votre organisation. Dans le fichier `java-style-prompt.md`, remplacez les variables suivantes :

- `{{GITLAB_INSTANCE}}` : L'URL de votre instance GitLab (par exemple, `https://gitlab.example.com`)
- `{{STYLE_GUIDE_PROJECT_ID}}` : L'ID de projet GitLab contenant votre guide de style Java
- `{{STYLE_GUIDE_PROJECT_NAME}}` : le nom d'affichage de votre projet de guide de style
- `{{STYLE_GUIDE_BRANCH}}` : la branche contenant le guide de style le plus à jour (par défaut : main)
- `{{STYLE_GUIDE_PATH}}` : le chemin vers le document du guide de style dans le dépôt

Exemple :

```yaml
GITLAB_INSTANCE=https://gitlab.example.com
STYLE_GUIDE_PROJECT_ID=gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards
STYLE_GUIDE_PROJECT_NAME=Enterprise Java Standards
STYLE_GUIDE_BRANCH=main
STYLE_GUIDE_PATH=coding-style/java/guidelines/java-coding-standards.md
```

#### 2\. Dépôt cible pour l'application des améliorations de style {#2-target-repository-to-apply-style-improvement}

Dans le même fichier `java-style-prompt.md`, configurez les fichiers auxquels appliquer le guide de style :

- `{{TARGET_PROJECT_ID}}` : L'ID GitLab de votre projet Java
- `{{TARGET_FILES}}` : les fichiers ou les patterns spécifiques à cibler (par exemple, « src/main/java/\*\*/\*.java »)

Exemple :

```yaml
TARGET_PROJECT_ID=royal-reserve-bank
TARGET_FILES=asset-management-api/src/main/java/com/royal/reserve/bank/asset/management/api/service/AssetManagementService.java
```

### Remarques importantes sur le code généré par l'IA {#important-notes-about-ai-generated-code}

**⚠️ Avertissement important** :

GitLab for VS Code utilise une IA agentique non déterministe, ce qui signifie que :

- Les résultats peuvent varier d'une exécution à l'autre, même avec des entrées identiques
- La compréhension et l'application des directives de style par l'agent d'IA peuvent légèrement différer à chaque fois
- Les exemples fournis dans cette documentation sont illustratifs et vos résultats réels peuvent différer

**Bonnes pratiques pour travailler avec du code généré par l'IA** :

1. **Always review generated code** : ne jamais fusionner les modifications générées par l'IA sans une révision humaine approfondie
1. **Follow proper merge request processes** : utiliser vos procédures standard de revue de code
1. **Run all tests** : s'assurer que tous les tests unitaires et d'intégration réussissent avant la fusion
1. **Verify style compliance** : confirmer que les modifications correspondent à vos attentes en matière de guide de style
1. **Incremental application** : envisager d'appliquer les modifications de style à des ensembles de fichiers plus petits dans un premier temps

N'oubliez pas que cet outil est destiné à assister les équipes de développement, et non à remplacer le jugement humain dans le processus de revue de code.

## Implémentation étape par étape {#step-by-step-implementation}

1. **Create a Style Guide Issue**

   - Créer un nouveau ticket dans votre projet (par exemple, le ticket n° 3)
   - Inclure des informations détaillées sur les directives de style à appliquer
   - Référencer le dépôt externe du guide de style le cas échéant
   - Spécifier les exigences comme suit :

     ```yaml
     Task: Code Style Update
     Description: Apply the enterprise standard Java style guidelines to the codebase.
     Reference Style Guide: Enterprise Java Style Guidelines (https://gitlab.com/gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards/-/blob/main/coding-style/java/guidelines/java-coding-standards.md)
     Constraints:
     - Adhere to Enterprise Standard Java Style Guide
     - Maintain Functionality
     - Implement automated style checks
     ```

1. **Configure the Prompt**

   - Copier le modèle depuis `java-style-prompt.md`
   - Renseigner toutes les variables de configuration
   - Ajouter les exceptions ou exigences spécifiques au projet

1. **Execute via GitLab for VS Code**

   - Soumettre le prompt configuré à Duo Workflow
   - Duo Workflow s'exécute selon un processus en plusieurs étapes, comme illustré dans l'exemple d'exécution du workflow :

     - Planifier la tâche avec des outils spécifiques (`run_read_only_git_command`, `read_file`, `find_files`, `edit_file`)
     - Accéder au ticket référencé
     - Récupérer le guide de style Java d'entreprise
     - Analyser la structure actuelle du code
     - Appliquer les directives de style au(x) fichier(s) spécifié(s)
     - Vérifier que les modifications préservent les fonctionnalités
     - Fournir un rapport détaillé des modifications apportées

1. **Review and Implement**

   - Réviser les modifications suggérées
   - Implémenter les modifications dans votre base de code
   - Exécuter les tests pour s'assurer que les fonctionnalités sont préservées
   - Surveiller la progression de la tâche via l'interface GitLab for VS Code

## Exemple d'exécution de workflow {#sample-workflow-execution}

Lorsqu'il est correctement configuré, l'extension GitLab for VS Code exécute un plan détaillé pour l'application des directives de style. Voici un exemple de ce à quoi ressemble l'exécution du workflow :

### Exemple de plan de workflow {#sample-workflow-plan}

L'agent d'IA crée d'abord un plan d'exécution avec des outils spécifiques :

1. Accéder aux directives de style Java en récupérant le contenu du projet Enterprise Java Standards à l'aide de `run_read_only_git_command` sur `https://gitlab.com/gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards.git` pour le fichier `coding-style/java/guidelines/java-coding-standards.md`, pris en charge par : `run_read_only_git_command`
1. Lire et analyser le contenu actuel de `AssetManagementService.java` à l'aide de l'outil `read_file` pour comprendre sa structure et identifier les zones nécessitant des mises à jour de style, pris en charge par `read_file`
1. Rechercher des fichiers similaires dans le projet à l'aide de find_files pour garantir une application cohérente du style dans les classes de service associées, pris en charge par `find_files`
1. Modifier AssetManagementService.java à l'aide de l'outil edit_file pour appliquer les directives de style, en se concentrant sur :

   - Organisation des packages et des imports
   - Documentation des classes et des méthodes
   - Indentation et espacement du code
   - Placement des annotations
   - Mise en forme des paramètres de méthode, pris en charge par `edit_file`

1. Vérifier que toutes les annotations Lombok (@Service, @RequiredArgsConstructor, @Slf4j) sont correctement mises en forme conformément au guide de style à l'aide de grep_files pour vérifier les patterns d'annotations dans la base de code, pris en charge par `grep_files`

### Exemple de sortie d'analyse {#sample-analysis-output}

L'assistant analyse ensuite les fichiers et les exigences :

J'ai analysé le ticket n° 3 et le fichier `AssetManagementService.java`. Voici ce que j'ai trouvé :

1. Le ticket n° 3 concerne l'application des directives de style Java standard d'entreprise à la base de code Royal Banking.
1. Le fichier `AssetManagementService.java` est situé dans le module `asset-management-api`.
1. Les directives de style sont stockées dans un projet GitLab distinct à l'adresse `gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards`.
1. Le fichier `AssetManagementService.java` actuel contient :

   1. Déclarations de packages et d'imports
   1. Classe de service avec des annotations Spring
   1. Une méthode publique pour vérifier la disponibilité des actifs
   1. Annotations Lombok
   1. Commentaires Javadoc

Le ticket exige :

1. La mise en forme conformément aux directives de style Java standard d'entreprise
1. La mise en œuvre de contrôles de style automatisés
1. Le maintien des fonctionnalités existantes
1. La validation de tous les tests après les mises à jour de style

Pour procéder à l'implémentation, vous devrez :

1. Accéder aux directives de style Java depuis le projet Enterprise Java Standards
1. Appliquer les directives de style à AssetManagementService.java
1. Vérifier que les modifications n'affectent pas les fonctionnalités
1. S'assurer que tous les tests réussissent après les mises à jour

### Exemple de résultat d'implémentation {#sample-implementation-result}

Après l'exécution, l'assistant fournit le code transformé avec des explications sur les modifications apportées, notamment :

1. Un résumé des directives de style appliquées
1. Le code transformé avec une mise en forme appropriée
1. Des explications sur les principales modifications de style
1. Des recommandations pour l'application automatisée du style

Les modifications incluent généralement :

- L'ordre standardisé des imports
- L'espacement cohérent autour des opérateurs
- La mise en forme correcte des Javadocs
- L'alignement standardisé des paramètres de méthode
- Le placement cohérent des accolades

Le tout en garantissant que le code conserve ses fonctionnalités d'origine.

## Exemple de tutoriel de cas d'utilisation : projet Java Royal Reserve Bank {#sample-tutorial-use-case-royal-reserve-bank-java-project}

Ce dépôt inclut un exemple de tutoriel bancaire pour démontrer le fonctionnement de l'application du guide de style dans un scénario réel. Le projet Royal Reserve Bank suit une architecture de microservices avec plusieurs services Java :

- Account API
- Asset Management API
- Transaction API
- Notification API
- API Gateway
- Config Server
- Discovery Server

Les exemples appliquent les directives de style d'entreprise à la classe `AssetManagementService.java`, en démontrant la mise en forme appropriée pour :

1. Organisation des imports
1. Normes Javadoc
1. Alignement des paramètres de méthode
1. Conventions de nommage des variables
1. Patterns de gestion des exceptions

## Personnalisation pour votre organisation {#customizing-for-your-organization}

Pour adapter ce prompt aux besoins de votre organisation :

1. **Style Guide Replacement**

   - Pointer vers le dépôt du guide de style de votre organisation
   - Référencer votre document de guide de style spécifique

1. **Target File Selection**

   - Choisir des fichiers ou des patterns spécifiques auxquels appliquer le guide de style
   - Donner la priorité aux fichiers de code à haute visibilité pour l'implémentation initiale

1. **Additional Validation**

   - Ajouter des exigences de validation personnalisées
   - Spécifier les exceptions aux règles de style standard

1. **Integration with CI/CD**

   - Configurer le prompt pour qu'il s'exécute dans le cadre de votre pipeline CI/CD
   - Mettre en place des contrôles de style automatisés pour garantir une conformité continue

## Dépannage {#troubleshooting}

Problèmes courants et leurs solutions :

- **Guide de style introuvable** : vérifier que le chemin et la branche du guide de style sont corrects
- **Modifications de fonctionnalité** : exécuter tous les tests après l'application des modifications de style pour vérifier les fonctionnalités
- **Functionality Changes** : exécuter tous les tests après l'application des modifications de style pour vérifier les fonctionnalités

## Contribution {#contributing}

N'hésitez pas à améliorer ce prompt en :

- Ajoutant des explications supplémentaires sur les règles de style
- Créant des exemples pour différents types de projets Java
- Améliorant le workflow de validation
- Ajoutant une intégration avec des outils d'analyse statique supplémentaires
