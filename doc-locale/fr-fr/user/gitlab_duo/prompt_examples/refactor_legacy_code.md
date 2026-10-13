---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Refactorisez le code legacy dans votre dépôt.
title: Refactoriser le code legacy
---

Suivez ces consignes lorsque vous devez améliorer les performances, la lisibilité ou la maintenabilité d'un code existant.

- Durée estimée : 15 à 30 minutes
- Niveau : intermédiaire
- Prérequis : fichier de code ouvert dans l'IDE, GitLab Duo Chat disponible

## Le défi {#the-challenge}

Transformez du code complexe et difficile à maintenir en composants propres et testables sans interrompre les fonctionnalités.

## L'approche {#the-approach}

Analysez, planifiez et implémentez en utilisant GitLab Duo Chat et Code Suggestions.

### Étape 1 :  analyser {#step-1-analyze}

Utilisez GitLab Duo Chat pour comprendre l'état actuel. Sélectionnez le code que vous souhaitez refactoriser, puis demandez :

```plaintext
Analyze the [ClassName] in [file_path]. Focus on:
1. Current methods and their complexity
2. Performance bottlenecks
3. Areas where readability can be improved
4. Potential design patterns that could be applied

Provide specific examples from the code and suggest applicable refactoring patterns.
```

Résultat attendu : analyse détaillée avec des suggestions d'amélioration spécifiques.

### Étape 2 :  planifier {#step-2-plan}

Utilisez GitLab Duo Chat pour créer une proposition structurée.

```plaintext
Based on your analysis of [ClassName], create a refactoring plan:

1. Outline the new structure
2. Suggest new method names and their purposes
3. Identify any new classes or modules needed
4. Explain how this improves [performance/readability/maintainability]

Format as a structured plan with clear before/after comparisons.
```

Résultat attendu : roadmap de refactorisation étape par étape.

### Étape 3 :  implémenter {#step-3-implement}

Utilisez GitLab Duo Chat pour générer le code refactorisé. Appliquez ensuite le code et utilisez Code Suggestions pour vous aider avec la syntaxe.

```plaintext
Implement the refactoring plan for [ClassName]:

1. Create the new [language] file following our coding standards
2. Include detailed comments explaining changes
3. Update [related_file] to use the new structure
4. Write tests for the new implementation

Follow [style_guide] and document any design decisions.
```

Résultat attendu : code refactorisé complet avec les tests.

## Conseils {#tips}

- Commencez par l'analyse avant de passer à l'implémentation.
- Sélectionnez des sections de code spécifiques lorsque vous demandez une analyse à Chat.
- Demandez à Chat des exemples spécifiques tirés de votre code réel.
- Référencez les patterns de votre base de code existante par souci de cohérence.
- Utilisez des invites incrémentielles plutôt que d'essayer de tout faire en une seule fois.
- Laissez Code Suggestions vous aider avec la syntaxe lors de l'implémentation des recommandations de Chat.

## Vérifier {#verify}

Assurez-vous que :

- Le code généré respecte le guide de style de votre équipe.
- La nouvelle structure améliore réellement les problèmes identifiés.
- Les tests couvrent les fonctionnalités refactorisées.
- Aucune fonctionnalité n'a été perdue lors de la refactorisation.
