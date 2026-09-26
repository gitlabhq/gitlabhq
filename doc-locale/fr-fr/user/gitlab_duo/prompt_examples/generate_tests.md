---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Générer des tests complets pour les fonctions et classes existantes.
title: Générer des tests pour le code existant
---

Suivez ces instructions lorsque vous devez créer une couverture de test complète pour des fonctions ou des classes existantes.

- Durée estimée : 10 à 20 minutes
- Niveau : débutant
- Prérequis : fichier de code ouvert dans un IDE, GitLab Duo Chat disponible, code existant à tester

## Le défi {#the-challenge}

Créez une couverture de test approfondie pour le code existant sans avoir à écrire manuellement des cas de test standard et du code de configuration.

## L'approche {#the-approach}

Sélectionnez du code, générez des tests et affinez la couverture en utilisant GitLab Duo Chat et Code Suggestions.

### Étape 1 :  générer {#step-1-generate}

Sélectionnez la fonction ou la classe que vous souhaitez tester, puis utilisez GitLab Duo Chat pour générer des tests.

```plaintext
Generate tests for the selected [function_name/ClassName] by using [test_framework]:

1. Include test cases for normal operation
2. Add edge cases and error conditions
3. Test boundary values and invalid inputs
4. Follow [testing_conventions] for our project
5. Include setup and teardown if needed

Make the tests comprehensive but readable.
```

Résultat attendu : fichier de test complet avec plusieurs cas de test couvrant différents scénarios.

### Étape 2 :  affiner {#step-2-refine}

Passez en revue les tests générés et demandez des améliorations spécifiques.

```plaintext
Review the generated tests and:
1. Add any missing edge cases for [specific_functionality]
2. Improve test names to be more descriptive
3. Add comments explaining complex test scenarios
4. Ensure tests follow [specific_style_guide]

Focus on making tests maintainable and clear.
```

Résultat attendu : fichier de test finalisé avec une couverture claire et complète.

### Étape 3 :  étendre {#step-3-extend}

Utilisez Code Suggestions pour ajouter des cas de test supplémentaires. Saisissez ce texte dans votre fichier.

```plaintext
// Test [specific_edge_case_scenario]
// Test [error_condition]
// Test [boundary_condition]
```

Résultat attendu : Code Suggestions vous aide à compléter des cas de test supplémentaires.

## Conseils {#tips}

- Sélectionnez des fonctions ou des classes spécifiques plutôt que des fichiers entiers pour de meilleurs résultats.
- Soyez précis quant à votre framework de test (par exemple, Jest, pytest, RSpec).
- Demandez à Chat d'expliquer le raisonnement derrière les cas de test si vous êtes en phase d'apprentissage.
- Utilisez Code Suggestions pour ajouter rapidement des modèles de tests similaires.
- Demandez à la fois des cas de test positifs et négatifs pour une couverture complète.

## Vérifier {#verify}

Assurez-vous que :

- Les tests couvrent les fonctionnalités principales et les cas limites courants.
- Les noms des tests décrivent clairement ce qui est testé.
- Les tests respectent les conventions et le style de test de votre projet.
- Tous les tests réussissent lorsqu'ils sont exécutés sur le code existant.
