---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Installer le package Linux sur Ubuntu
title: Installer le package Linux sur Ubuntu
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!note]
> Consultez [les plateformes prises en charge](_index.md#supported-platforms) pour obtenir la liste complète des distributions et architectures prises en charge.

## Prérequis {#prerequisites}

- Prérequis système :
  - Ubuntu 20.04
  - Ubuntu 22.04
  - Ubuntu 24.04
- Consultez les [conditions d'installation](../requirements.md) pour en savoir plus sur les configurations matérielles minimales requises.
- Avant de commencer, assurez-vous d'avoir correctement [configuré votre DNS](https://docs.gitlab.com/omnibus/settings/dns/). Remplacez `https://gitlab.example.com` dans les commandes suivantes par l'URL GitLab de votre choix. GitLab est automatiquement configuré et démarré à cette adresse.
- Pour les URLs `https://`, GitLab [demande automatiquement un certificat avec Let's Encrypt](https://docs.gitlab.com/omnibus/settings/ssl/#enable-the-lets-encrypt-integration), ce qui nécessite un accès HTTP entrant et un nom d'hôte valide. Vous pouvez également utiliser [votre propre certificat](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually), ou simplement utiliser `http://` (sans le `s`) pour une URL non chiffrée.
- Les packages Linux et autres fichiers de métadonnées associés sont stockés et distribués depuis Google Cloud Storage. Si vous utilisez un pare-feu, vous devrez autoriser l'accès aux préfixes d'URL suivants :
      - `https://packages.gitlab.com/*`
      - `https://storage.googleapis.com/packages-ops/*`

## Activer SSH et ouvrir les ports du pare-feu {#enable-ssh-and-open-firewall-ports}

Pour ouvrir les ports de pare-feu nécessaires (80, 443, 22) et pouvoir accéder à GitLab :

1. Activez et démarrez le daemon du serveur OpenSSH :

   ```shell
   sudo systemctl enable --now ssh
   ```

1. Une fois `ufw` installé, ouvrez les ports du pare-feu :

   ```shell
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

## Ajouter le dépôt de packages GitLab {#add-the-gitlab-package-repository}

Pour installer GitLab, ajoutez d'abord le dépôt de packages GitLab.

1. Installez les packages nécessaires :

   ```shell
   sudo apt update
   sudo apt install -y curl
   ```

1. Utilisez le script suivant pour ajouter le dépôt GitLab (vous pouvez coller l'URL du script dans votre navigateur pour voir ce qu'il fait avant de le rediriger vers `bash`) :

   {{< tabs >}}

   {{< tab title="Enterprise Edition" >}}

   ```shell
   curl --location "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh" | sudo bash
   ```

   {{< /tab >}}

   {{< tab title="Community Edition" >}}

   ```shell
   curl --location "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh" | sudo bash
   ```

   {{< /tab >}}

   {{< /tabs >}}

## Installer le package {#install-the-package}

Installez GitLab à l'aide du gestionnaire de packages de votre système.

> [!note]
> La définition de `EXTERNAL_URL` est facultative mais recommandée. Si vous ne le définissez pas lors de l'installation, vous pouvez [le définir ultérieurement](https://docs.gitlab.com/omnibus/settings/configuration/#configure-the-external-url-for-gitlab).

{{< tabs >}}

{{< tab title="Enterprise Edition" >}}

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" apt install gitlab-ee
```

{{< /tab >}}

{{< tab title="Community Edition" >}}

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" apt install gitlab-ce
```

{{< /tab >}}

{{< /tabs >}}

GitLab génère un mot de passe et une adresse e-mail aléatoires pour le compte administrateur root, stockés dans `/etc/gitlab/initial_root_password` pendant 24 heures. Après 24 heures, ce fichier est automatiquement supprimé pour des raisons de sécurité.

## Première connexion {#initial-sign-in}

Une fois GitLab installé, accédez à l'URL que vous avez configurée et utilisez les identifiants suivants pour vous connecter :

- Nom d'utilisateur : `root`
- Mot de passe : voir `/etc/gitlab/initial_root_password`

Après vous être connecté, modifiez votre [mot de passe](../../user/profile/user_passwords.md#change-your-password) et votre [adresse e-mail](../../user/profile/_index.md#add-emails-to-your-user-profile).

## Configuration avancée {#advanced-configuration}

Vous pouvez personnaliser votre installation GitLab en définissant les variables d'environnement facultatives suivantes avant l'installation. **Ces variables ne fonctionnent que lors de la première installation** et n'ont aucun effet sur les exécutions de reconfiguration ultérieures. Pour les installations existantes, utilisez le mot de passe provenant de `/etc/gitlab/initial_root_password` ou [réinitialisez le mot de passe root](../../security/reset_user_password.md).

| Variable | Objectif | Obligatoire | Exemple |
|----------|---------|----------|---------|
| `EXTERNAL_URL` | Définit l'URL externe de votre instance GitLab | Recommandé | `EXTERNAL_URL="https://gitlab.example.com"` |
| `GITLAB_ROOT_EMAIL` | E-mail personnalisé pour le compte administrateur root | Facultatif | `GITLAB_ROOT_EMAIL="admin@example.com"` |
| `GITLAB_ROOT_PASSWORD` | Mot de passe personnalisé (8 caractères minimum) pour le compte administrateur root | Facultatif | `GITLAB_ROOT_PASSWORD="strongpassword"` |

Si GitLab ne peut pas détecter un nom d'hôte valide lors de l'installation, la reconfiguration ne s'exécutera pas automatiquement. Dans ce cas, transmettez les variables d'environnement nécessaires à votre première commande `gitlab-ctl reconfigure`.

> [!warning]
> Bien que vous puissiez également définir le mot de passe initial dans `/etc/gitlab/gitlab.rb` en définissant `gitlab_rails['initial_root_password']`, cela n'est pas recommandé. Cela représente un risque de sécurité, car le mot de passe est en texte clair. Si vous avez configuré cela, veillez à le supprimer après l'installation.

Choisissez votre édition GitLab et personnalisez-la avec les variables d'environnement ci-dessus :

{{< tabs >}}

{{< tab title="Enterprise Edition" >}}

```shell
sudo GITLAB_ROOT_EMAIL="admin@example.com" GITLAB_ROOT_PASSWORD="strongpassword" EXTERNAL_URL="https://gitlab.example.com" apt install gitlab-ee
```

{{< /tab >}}

{{< tab title="Community Edition" >}}

```shell
sudo GITLAB_ROOT_EMAIL="admin@example.com" GITLAB_ROOT_PASSWORD="strongpassword" EXTERNAL_URL="https://gitlab.example.com" apt install gitlab-ce
```

{{< /tab >}}

{{< /tabs >}}

## Configurer vos préférences de communication {#set-up-your-communication-preferences}

Visitez notre [centre de préférences d'abonnement aux e-mails](https://about.gitlab.com/company/preference-center/) pour nous indiquer quand vous contacter. Nous appliquons une politique explicite d'opt-in par e-mail, ce qui vous donne un contrôle total sur ce que nous vous envoyons et la fréquence à laquelle nous le faisons.

Deux fois par mois, nous vous envoyons les actualités GitLab à ne pas manquer, notamment les nouvelles fonctionnalités, les intégrations, la documentation et les coulisses de nos équipes de développement. Pour les mises à jour de sécurité critiques relatives aux bugs et aux performances du système, inscrivez-vous à notre newsletter dédiée à la sécurité.

> [!note]
> Si vous ne vous inscrivez pas à la newsletter de sécurité, vous ne recevrez pas d'alertes de sécurité.

## Prochaines étapes recommandées {#recommended-next-steps}

Une fois votre installation terminée, consultez les [prochaines étapes recommandées, notamment les options d'authentification et les restrictions relatives aux nouveaux comptes utilisateur](../next_steps.md).
