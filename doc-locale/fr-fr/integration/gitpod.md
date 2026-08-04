---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Utilisez Ona pour créer et configurer des environnements de développement préconstruits pour votre projet GitLab.
title: Ona
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

Avec [Ona](https://ona.com/) (anciennement Gitpod), vous pouvez décrire votre environnement de développement sous forme de code afin d'obtenir des environnements de développement entièrement configurés, compilés et testés pour n'importe quel projet GitLab. Les environnements de développement ne sont pas seulement automatisés, mais aussi préconstruits, ce qui signifie qu'Ona génère en continu vos branches Git comme un serveur CI/CD.

Cela signifie que vous n'avez pas à attendre le téléchargement des dépendances et le démarrage des builds pour commencer à coder immédiatement. Avec Ona, vous pouvez commencer à coder instantanément sur n'importe quel projet, branche et merge request depuis votre navigateur.

Pour utiliser l'intégration GitLab Ona, vous devez l'activer pour votre instance GitLab et dans vos préférences. Utilisateurs de :

- GitLab.com peut l'utiliser immédiatement après l'avoir [activée dans leurs préférences utilisateur](#enable-ona-in-your-user-preferences).
- Les instances GitLab Self-Managed peuvent l'utiliser après :
  1. Elle est [activée et configurée par un administrateur GitLab](#configure-a-gitlab-self-managed-instance).
  1. Elle est [activée dans leurs paramètres utilisateur](#enable-ona-in-your-user-preferences).

Pour plus d'informations sur Ona, consultez les [fonctionnalités](https://ona.com/) et la [documentation](https://ona.com/docs) d'Ona.

## Activer Ona dans vos préférences utilisateur {#enable-ona-in-your-user-preferences}

Une fois l'intégration Ona activée pour votre instance GitLab, pour l'activer pour vous-même :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Préférences**.
1. Sous **Préférences**, localisez la section **Intégrations**.
1. Cochez la case **Activer l'intégration d'Ona** et sélectionnez **Sauvegarder les modifications**.

## Configurer une instance GitLab Self-Managed {#configure-a-gitlab-self-managed-instance}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour GitLab Self-Managed, un administrateur GitLab doit :

1. Activer l'intégration Ona dans GitLab :
   1. dans le coin supérieur droit, sélectionnez **Admin**.
   1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
   1. Développez la section de configuration **Ona**.
   1. Cochez la case **Activer l'intégration d'Ona**.
   1. Saisissez l'URL de l'instance Ona (par exemple, `https://app.ona.com`).
   1. Sélectionnez **Enregistrer les modifications**.
1. Enregistrez l'instance dans Ona. Pour plus d'informations, consultez la [documentation Ona](https://ona.com/docs/ona/source-control/gitlab).

Les utilisateurs GitLab peuvent alors [activer l'intégration Ona pour eux-mêmes](#enable-ona-in-your-user-preferences).

## Lancer Ona dans GitLab {#launch-ona-in-gitlab}

Après avoir [activé Ona](#enable-ona-in-your-user-preferences), vous pouvez le lancer depuis GitLab de l'une des façons suivantes :

- Depuis un dépôt de projet :
  1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
  1. En haut à droite, sélectionnez **Code** > **Ona**.
- Depuis une merge request :
  1. Accédez à votre merge request.
  1. Dans le coin supérieur droit, sélectionnez **Code** > **Ouvrir dans Ona**.

Ona génère votre environnement de développement pour votre branche.
