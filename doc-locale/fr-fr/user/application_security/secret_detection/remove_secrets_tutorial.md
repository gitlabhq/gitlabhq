---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutoriel : supprimer un secret de vos commits'
---

Si votre application utilise des ressources externes, vous devez généralement l'authentifier à l'aide d'un secret, comme un jeton ou une clé. Si un secret est poussé vers un dépôt distant, toute personne ayant accès au dépôt peut usurper votre identité ou celle de votre application. Si vous committez accidentellement un secret, vous pouvez toujours le supprimer avant de pousser vos modifications.

Dans ce tutoriel, vous allez committer un faux secret, puis le supprimer de votre historique de commits avant de le pousser vers un projet. Vous apprendrez également ce qu'il faut faire lorsqu'un secret est poussé vers un dépôt.

<i class="fa-youtube-play" aria-hidden="true"></i> Ce tutoriel est adapté de la vidéo GitLab Unfiltered [Remove a secret from your commits](https://www.youtube.com/watch?v=2jBC3uBUlyU).
<!-- Video published on 2024-06-12 -->

## Avant de commencer {#before-you-begin}

Assurez-vous de disposer des éléments suivants avant de commencer ce tutoriel :

- Un projet de test. Vous pouvez utiliser n'importe quel projet, mais envisagez d'en créer un spécifiquement pour ce tutoriel.
- Une certaine familiarité avec Git en ligne de commande.

## Committer un secret {#commit-a-secret}

GitLab identifie les secrets en faisant correspondre des modèles spécifiques de lettres, de chiffres et de symboles. Ces modèles sont également utilisés pour identifier le type de secret. Par exemple, le faux secret `glpat-12345678901234567890` est un jeton d'accès personnel car il commence par la chaîne `glpat-`.

Bien que de nombreux secrets puissent être identifiés par leur format, vous pourriez accidentellement committer un secret pendant que vous travaillez dans un dépôt. Simulons un commit accidentel d'un secret :

1. Dans votre dépôt de test, créez une nouvelle branche :

   ```shell
   git checkout -b secret-tutorial
   ```

1. Créez un nouveau fichier texte avec le contenu suivant, en supprimant les espaces avant et après le `-` pour correspondre au format exact d'un jeton d'accès personnel :

   ```txt
   fake-secret: glpat - 12345678901234567890
   message: hello, world!
   ```

1. Committez le fichier dans votre branche :

   ```shell
   git add .
   git commit -m "Add fake secret"
   ```

Cela crée un problème : si les modifications sont poussées, le jeton d'accès personnel contenu dans le fichier texte est exposé ! Le secret doit être supprimé de l'historique des commits avant de pouvoir continuer.

## Supprimer le secret de l'historique {#remove-the-secret-from-the-history}

Si le seul commit contenant un secret est le commit le plus récent de l'historique Git, vous pouvez modifier l'historique pour le supprimer :

1. Ouvrez le fichier texte et supprimez le faux secret :

   ```txt
   fake-secret:
   message: hello, world!
   ```

1. Écrasez l'ancien commit avec les modifications :

   ```shell
   git add .
   git commit --amend
   ```

1. Poussez vos modifications vers la branche distante :

   ```shell
   git push --force-with-lease
   ```

   Étant donné que l'historique des commits a été réécrit, un `git push` classique échoue. L'indicateur `--force-with-lease` force le push tout en protégeant contre l'écrasement des commits des autres contributeurs.

Le secret est supprimé du fichier et de l'historique des commits.

### Modifier plusieurs commits {#amending-multiple-commits}

Parfois, vous ne remarquez qu'un secret a été ajouté qu'après avoir effectué plusieurs commits supplémentaires. Dans ce cas, il ne suffit pas de supprimer le secret du commit le plus récent. Vous devez apporter des modifications à chaque commit effectué après l'ajout du secret :

1. Ajoutez le faux secret à votre fichier et committez-le dans la branche.
1. Effectuez au moins un commit supplémentaire. Lorsque vous inspectez l'historique, vous devriez voir quelque chose comme ceci :

   ```shell
   $ git log
   commit 456def

       Do other things

   commit 123abc

       Add fake secret

   ...
   ```

   Même si le secret est supprimé du commit `456def`, il existe toujours dans l'historique et est exposé si les modifications sont poussées maintenant.
1. Pour corriger l'historique, démarrez un rebase interactif à partir du commit qui a introduit le secret :

   ```shell
   git rebase -i 123abc~1
   ```

1. Dans la fenêtre d'édition, pour chaque commit contenant le secret, remplacez `pick` par `edit` :

   ```txt
   edit 456def Do other things
   edit 123abc Add fake secret
   ```

1. Ouvrez votre fichier texte et supprimez le faux secret.
1. Committez vos modifications :

   ```shell
   git add .
   git commit --amend
   ```

1. Facultatif. Lorsque vous supprimez le secret, vous pourriez supprimer le seul diff du commit. Si cela se produit, Git affiche ce message :

   ```shell
   No changes
   You asked to amend the most recent commit, but doing so would make it empty.
   ```

   Supprimez le commit vide :

   ```shell
   git reset HEAD^
   ```

1. Continuez le rebase :

   ```shell
   git rebase --continue
   ```

1. Supprimez le secret du commit suivant et continuez le rebase. Répétez ce processus jusqu'à ce que le rebase soit terminé :

   ```shell
   Successfully rebased and updated refs/heads/secret-tutorial
   ```

1. Poussez vos modifications vers la branche distante :

   ```shell
   git push --force-with-lease
   ```

   Étant donné que l'historique des commits a été réécrit, un `git push` classique échoue. L'indicateur `--force-with-lease` force le push tout en protégeant contre l'écrasement des commits des autres contributeurs.

Le secret est supprimé de l'historique des commits.

## Que faire lorsque vous poussez un secret {#what-to-do-when-you-push-a-secret}

Parfois, des personnes poussent des modifications avant de remarquer qu'elles contiennent un secret. Si la protection contre le push de secrets est activée dans le projet, le push est automatiquement bloqué et les commits problématiques sont affichés.

Cependant, si un secret est poussé avec succès vers un dépôt distant, il n'est plus sécurisé et vous devez le révoquer immédiatement. Même si vous pensez que peu de personnes ont accès au secret, vous devriez le remplacer. Les secrets exposés constituent un risque de sécurité substantiel.

## Étapes suivantes {#next-steps}

Pour améliorer la sécurité de votre application, envisagez d'activer au moins l'une des méthodes de [détection des secrets](_index.md) dans votre projet.
