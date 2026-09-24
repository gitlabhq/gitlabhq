---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Identifiez et corrigez les bugs dans le code ou les tests défaillants.
title: Déboguer du code défaillant
---

Suivez ces instructions lorsque vous avez du code qui ne fonctionne pas comme prévu ou des tests qui échouent.

- Estimation de la durée : 10-25 minutes
- Niveau : débutant
- Prérequis : messages d'erreur ou code défaillant disponibles, GitLab Duo Chat disponible dans l'IDE

## Le défi {#the-challenge}

Identifiez rapidement la cause première des bugs ou des échecs de tests et implémentez des correctifs efficaces sans passer des heures à déboguer manuellement.

## L'approche {#the-approach}

Analysez les erreurs, identifiez les causes et implémentez des correctifs à l'aide de GitLab Duo Chat.

### Étape 1 :  analyser {#step-1-analyze}

Copiez le message d'erreur et le code concerné. Demandez ensuite à GitLab Duo Chat d'expliquer l'erreur.

```plaintext
Explain what's causing this error and help me fix it:

Error: [paste_error_message]

Context: [brief_description_of_what_you_were_trying_to_do]

Here's the relevant code:
[paste_problematic_code]
```

Résultat attendu : explication claire de la cause de l'erreur et recommandations de correctifs spécifiques.

### Étape 2 :  implémenter {#step-2-implement}

Demandez à Chat de fournir le code corrigé.

```plaintext
Based on your analysis, please provide the corrected version of this code:

[paste_original_code]

Make sure the fix addresses [specific_error] and follows [language/framework] best practices.
```

Résultat attendu : un code fonctionnel qui résout le ticket identifié.

### Étape 3 :  prévenir {#step-3-prevent}

Demandez des conseils sur la manière d'éviter des problèmes similaires.

```plaintext
How can I prevent this type of error in the future?
What are the warning signs to watch for with [error_type] in [language/framework]?
Include any best practices or common patterns I should follow.
```

Résultat attendu : conseils préventifs et bonnes pratiques pour éviter des bugs similaires.

## Conseils {#tips}

- Incluez le message d'erreur complet, pas seulement un résumé.
- Fournissez le contexte de ce que vous tentiez d'accomplir.
- Commencez par copier uniquement la section de code spécifique qui échoue. Ajoutez davantage de code depuis le fichier si Chat nécessite plus de contexte.
- Demandez à Chat d'expliquer le correctif afin de comprendre le problème sous-jacent.
- Si la première suggestion ne fonctionne pas, indiquez à Chat ce qui s'est passé lorsque vous l'avez essayée.

## Vérifier {#verify}

Assurez-vous que :

- L'erreur ne se produit plus lorsque vous exécutez le code.
- Le correctif traite la cause première, et pas seulement les symptômes.
- La solution respecte les normes de codage de votre projet.
- Vous comprenez pourquoi l'erreur s'est produite et comment le correctif fonctionne.
