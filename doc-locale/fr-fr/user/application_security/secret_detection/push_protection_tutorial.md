---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutoriel : protéger votre projet avec la protection push des secrets'
---

Si votre application utilise des ressources externes, vous devez généralement l'authentifier avec un secret, comme un jeton ou une clé. Si un secret est poussé vers un dépôt distant, toute personne ayant accès au dépôt peut usurper votre identité ou celle de votre application.

Avec la protection push des secrets, si GitLab détecte un secret dans l'historique des commits, il peut bloquer un push pour éviter une fuite. Activer la protection push des secrets est un bon moyen de réduire le temps que vous consacrez à l'examen de vos commits pour détecter les données sensibles et à la remédiation des fuites si elles surviennent.

Dans ce tutoriel, vous allez configurer la protection push des secrets et observer ce qui se passe lorsque vous essayez de committer un faux secret. Vous apprendrez également comment ignorer la protection push des secrets, au cas où vous auriez besoin de contourner un faux positif.

<i class="fa-youtube-play" aria-hidden="true"></i> Ce tutoriel est adapté des vidéos GitLab Unfiltered suivantes :

- [Introduction à la protection push des secrets](https://www.youtube.com/watch?v=SFVuKx3hwNI)
  <!-- Video published on 2024-06-21 -->
- [Configuration - Activer la protection push des secrets pour votre projet](https://www.youtube.com/watch?v=t1DJN6Vsmp0)
  <!-- Video published on 2024-06-23 -->
- [Ignorer la protection push des secrets](https://www.youtube.com/watch?v=wBAhe_d2DkQ)
  <!-- Video published on 2024-06-04 -->

## Avant de commencer {#before-you-begin}

Avant de commencer ce tutoriel, assurez-vous de disposer des éléments suivants :

- Un abonnement GitLab Ultimate.
- Un projet de test. Vous pouvez utiliser n'importe quel projet, mais envisagez d'en créer un spécifiquement pour ce tutoriel.
- Une certaine familiarité avec Git en ligne de commande.

De plus, sur GitLab Self-Managed uniquement, assurez-vous que la protection push des secrets est [activée sur l'instance](secret_push_protection/_index.md#allow-the-use-of-secret-push-protection-in-your-gitlab-instance).

## Activer la protection push des secrets {#enable-secret-push-protection}

Pour utiliser la protection push des secrets, vous devez l'activer pour chaque projet que vous souhaitez protéger. Commençons par l'activer dans un projet de test.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Activez le bouton bascule **Protection Push de détection des secrets**.

Ensuite, vous allez tester la protection push des secrets.

## Essayer de pousser un secret vers votre projet {#try-pushing-a-secret-to-your-project}

GitLab identifie les secrets en faisant correspondre des motifs spécifiques de lettres, de chiffres et de symboles. Ces motifs sont également utilisés pour identifier le type de secret. Testons cette fonctionnalité en ajoutant le faux secret `glpat-12345678901234567890` à notre projet : <!-- gitleaks:allow -->

1. Dans le projet, extrayez une nouvelle branche :

   ```shell
   git checkout -b push-protection-tutorial
   ```

1. Créez un nouveau fichier avec le contenu suivant. Veillez à supprimer les espaces avant et après le `-` pour correspondre au format exact d'un jeton d'accès personnel :

   ```plaintext
   hello, world!

   # To make the example work, remove
   # the spaces before and after the dash:
   glpat - 12345678901234567890
   ```

1. Committez le fichier dans votre branche :

   ```shell
   git add .
   git commit -m "Add fake secret"
   ```

   Le secret est maintenant enregistré dans l'historique des commits. La protection push des secrets ne vous empêche pas de committer un secret ; elle vous alerte uniquement lorsque vous poussez.
1. Poussez les modifications vers GitLab. Vous devriez voir quelque chose comme ceci :

   ```shell
   $ git push
   remote: GitLab:
   remote: PUSH BLOCKED: Secrets detected in code changes
   remote:
   remote: Secret push protection found the following secrets in commit: 123abc
   remote: -- myFile.txt:2 | GitLab Personal Access Token
   remote:
   remote: To push your changes you must remove the identified secrets.
   To gitlab.com:
    ! [remote rejected] push-protection-tutorial -> main (pre-receive hook declined)
   ```

   GitLab détecte le secret et bloque le push. D'après le rapport d'erreur, nous pouvons voir :

   - Le commit qui contient le secret (`123abc`)
   - Le fichier et le numéro de ligne qui contiennent le secret (`myFile.txt:2`)
   - Le type de secret (`GitLab Personal Access Token`)

Si nous avions réussi à pousser nos modifications, nous aurions dû consacrer un temps et des efforts considérables à révoquer et remplacer le secret. À la place, nous pouvons [supprimer le secret de l'historique des commits](remove_secrets_tutorial.md) et avoir l'esprit tranquille en sachant que nous avons empêché la fuite du secret.

## Ignorer la protection contre l'envoi de secrets par push {#skip-secret-push-protection}

Parfois, vous devez pousser un commit, même si la protection push des secrets a identifié un secret. Cela peut se produire lorsque GitLab détecte un faux positif. Pour illustrer cela, nous allons pousser notre dernier commit vers GitLab.

### Avec une option de push {#with-a-push-option}

Vous pouvez utiliser une option de push pour ignorer la protection push des secrets :

- Poussez votre commit avec l'option `secret_push_protection.skip_all` :

  ```shell
  git push -o secret_push_protection.skip_all
  ```

La protection push des secrets est ignorée et les modifications sont poussées vers le dépôt distant.

### Avec un message de commit {#with-a-commit-message}

Si vous n'avez pas accès à la ligne de commande, ou si vous ne souhaitez pas utiliser une option de push :

- Ajoutez la chaîne `[skip secret push protection]` au message de commit. Par exemple :

  ```shell
  git commit --amend -m "Add fake secret [skip secret push protection]"
  ```

Vous devez uniquement ajouter `[skip secret push protection]` à l'un des messages de commit pour pouvoir pousser vos modifications, même s'il y a plusieurs commits.

## Étapes suivantes {#next-steps}

Envisagez d'activer la [détection des secrets dans le pipeline](pipeline/_index.md) pour améliorer davantage la sécurité de vos projets.
