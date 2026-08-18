---
stage: Systems
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Installez GitLab depuis Azure Marketplace.
title: Installer GitLab sur Microsoft Azure
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour les utilisateurs du cloud professionnel Microsoft Azure, GitLab propose une offre préconfigurée sur le [Azure Marketplace](https://azuremarketplace.microsoft.com/en-us/marketplace/). Ce tutoriel décrit l'installation de GitLab Enterprise Edition dans une seule machine virtuelle (VM).

## Prérequis {#prerequisites}

- Un compte Azure. Utilisez l'une des méthodes suivantes :
  - Si vous ou votre entreprise disposez déjà d'un compte avec un abonnement, utilisez ce compte.
  - [Créez un compte gratuit](https://azure.microsoft.com/en-us/free/), ce qui vous octroie un crédit de 200 $ pour explorer Azure pendant 30 jours. Pour plus d'informations, consultez [Azure free account](https://azure.microsoft.com/en-us/pricing/offers/ms-azr-0044p/).
  - Si vous disposez d'un abonnement MSDN, activez vos avantages d'abonné Azure. Votre abonnement MSDN vous offre des crédits Azure récurrents chaque mois.
- Un accès administrateur pour maintenir votre instance GitLab.

## Déployer et configurer GitLab {#deploy-and-configure-gitlab}

Étant donné que GitLab est déjà installé dans une image préconfigurée, il vous suffit de créer une nouvelle VM :

1. [Consultez l'offre GitLab sur la marketplace](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/gitlabinc1586447921813.gitlabee?tab=Overview)
1. Sélectionnez **Get it now** et la fenêtre **Create this app in Azure** s'ouvre. Sélectionnez **Continuer**.
1. Sélectionnez l'une des options suivantes dans le portail Azure :
   - Sélectionnez **Créer** pour créer une VM de toutes pièces.
   - Sélectionnez **Start with a pre-set configuration** pour démarrer avec des options préconfigurées. Vous pouvez modifier ces configurations à tout moment.

Pour les besoins de ce guide, créons la VM de toutes pièces en sélectionnant **Créer**.

> [!note]
> Sachez qu'Azure facture des frais de calcul dès que votre VM est active (« allouée »), même si vous utilisez des crédits d'essai gratuits. [comment arrêter correctement une VM Azure pour économiser de l'argent](https://build5nines.com/properly-shutdown-azure-vm-to-save-money/). Consultez la [calculatrice de prix Azure](https://azure.microsoft.com/en-us/pricing/calculator/) pour connaître le coût des ressources.

Après avoir créé la machine virtuelle, utilisez les informations des sections suivantes pour la configurer.

### Configurer l'onglet Basics {#configure-the-basics-tab}

Les premiers éléments à configurer sont les paramètres de base de la machine virtuelle sous-jacente :

1. Sélectionnez le modèle d'abonnement et un groupe de ressources (créez-en un nouveau s'il n'existe pas).
1. Saisissez un nom pour la VM, par exemple `GitLab`.
1. Sélectionnez une région.
1. Dans **Availability options**, sélectionnez **Availability zone** et définissez-la sur `1`. En savoir plus sur les [zones de disponibilité](https://learn.microsoft.com/en-us/azure/virtual-machines/availability).
1. Assurez-vous que l'image sélectionnée est définie sur **GitLab - Gen1**.
1. Sélectionnez la taille de la VM en fonction des [configurations matérielles requises](../requirements.md). Étant donné que la configuration système minimale pour exécuter un environnement GitLab pour jusqu'à 500 utilisateurs est couverte par la taille `D4s_v3`, sélectionnez cette option.
1. Définissez le type d'authentification sur **Clé SSH publique**.
1. Saisissez un nom d'utilisateur ou conservez celui qui est créé automatiquement. Il s'agit de l'utilisateur qu'Azure utilise pour se connecter à la VM via SSH. Par défaut, l'utilisateur dispose d'un accès root.
1. Déterminez si vous souhaitez fournir votre propre clé SSH ou laisser Azure en créer une pour vous. Pour plus d'informations sur la configuration des clés SSH publiques, consultez [SSH](../../user/ssh.md).

Vérifiez les paramètres saisis, puis passez à l'onglet Disks.

### Configurer l'onglet Disks {#configure-the-disks-tab}

Pour les disques :

1. Pour le type de disque du système d'exploitation, sélectionnez **Premium SSD**.
1. Sélectionnez le chiffrement par défaut.

[En savoir plus sur les types de disques](https://learn.microsoft.com/en-us/azure/virtual-machines/managed-disks-overview) qu'Azure propose.

Vérifiez vos paramètres, puis passez à l'onglet Networking.

### Configurer l'onglet Networking {#configure-the-networking-tab}

Utilisez cet onglet pour définir la connectivité réseau de votre machine virtuelle en configurant les paramètres de la carte d'interface réseau (NIC). Vous pouvez les laisser à leurs paramètres par défaut.

Azure crée un groupe de sécurité par défaut et la VM lui est assignée. L'image GitLab sur la marketplace présente les ports ouverts suivants par défaut :

| Port | Description |
|------|-------------|
| 80   | Permet à la VM de répondre aux requêtes HTTP, autorisant l'accès public. |
| 443  | Permet à notre VM de répondre aux requêtes HTTPS, autorisant l'accès public. |
| 22   | Permet à notre VM de répondre aux demandes de connexion SSH, autorisant l'accès public (avec authentification) aux sessions de terminal à distance. |

Si vous souhaitez modifier les ports ou ajouter des règles, vous pouvez le faire après la création de la VM en sélectionnant Networking settings dans la barre latérale gauche, depuis le tableau de bord de la VM.

### Configurer l'onglet Management {#configure-the-management-tab}

Utilisez cet onglet pour configurer les options de surveillance et de gestion de votre VM. Vous n'avez pas besoin de modifier les paramètres par défaut.

### Configurer l'onglet Advanced {#configure-the-advanced-tab}

Utilisez cet onglet pour ajouter une configuration supplémentaire, des agents, des scripts ou des applications via des extensions de machine virtuelle ou `cloud-init`. Vous n'avez pas besoin de modifier les paramètres par défaut.

### Configurer l'onglet Tags {#configure-the-tags-tab}

Utilisez cet onglet pour ajouter des paires nom/valeur vous permettant de catégoriser les ressources. Vous n'avez pas besoin de modifier les paramètres par défaut.

### Vérifier et créer la VM {#review-and-create-the-vm}

L'onglet final vous présente toutes les options sélectionnées, où vous pouvez revoir et modifier vos choix issus des étapes précédentes. Azure exécute des tests de validation en arrière-plan et, si vous avez fourni tous les paramètres requis, vous pouvez créer la VM.

Après avoir sélectionné **Créer**, si vous avez choisi de laisser Azure créer une paire de clés SSH pour vous, une invite apparaît pour télécharger la clé SSH privée. Téléchargez la clé, car elle est nécessaire pour se connecter à la VM via SSH.

Après avoir téléchargé la clé, le déploiement commence.

### Terminer le déploiement {#finish-deployment}

À ce stade, Azure commence à déployer votre nouvelle VM. Le processus de déploiement prend quelques minutes. Une fois terminé, la nouvelle VM et ses ressources associées s'affichent dans le tableau de bord Azure. Sélectionnez **Go to resource** pour accéder au tableau de bord de la VM.

GitLab est maintenant déployé et prêt à être utilisé. Avant de le faire, cependant, vous devez configurer le nom de domaine et configurer GitLab pour l'utiliser.

### Configurer un nom de domaine {#set-up-a-domain-name}

La VM dispose d'une adresse IP publique (statique par défaut), mais Azure vous permet d'attribuer un nom DNS descriptif à la VM :

1. Depuis le tableau de bord de la VM, sélectionnez **Configurer** sous **DNS name**.
1. Saisissez un nom DNS descriptif pour votre instance dans le champ **DNS name label**, par exemple `gitlab-prod`. Cela rend la VM accessible à l'adresse `gitlab-prod.eastus.cloudapp.azure.com`.
1. Sélectionnez **Enregistrer**.

À terme, la plupart des utilisateurs souhaitent utiliser leur propre nom de domaine. Pour ce faire, vous devez ajouter un enregistrement DNS `A` auprès de votre bureau d'enregistrement de domaine qui pointe vers l'adresse IP publique de votre VM Azure. Vous pouvez utiliser [Azure DNS](https://learn.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns) ou un [autre bureau d'enregistrement](https://docs.gitlab.com/omnibus/settings/dns/).

### Modifier l'URL externe de GitLab {#change-the-gitlab-external-url}

GitLab utilise `external_url` dans son fichier de configuration pour définir le nom de domaine. Si vous ne configurez pas cela, lorsque vous accédez au nom convivial Azure, le navigateur vous redirigera vers l'IP publique.

Pour configurer l'URL externe de GitLab :

1. Connectez-vous à GitLab via SSH en accédant à **Paramètres** > **Connecter** depuis le tableau de bord de la VM, puis suivez les instructions. N'oubliez pas de vous connecter avec le nom d'utilisateur et la clé SSH que vous avez spécifiés lors de la [création de la VM](#configure-the-basics-tab). Le nom de domaine de la VM Azure est celui que vous avez [configuré précédemment](#set-up-a-domain-name). Si vous n'avez pas configuré de nom de domaine pour votre VM, vous pouvez utiliser l'adresse IP à la place.

   Dans le cas de notre exemple :

   ```shell
   ssh -i <private key path> gitlab-azure@gitlab-prod.eastus.cloudapp.azure.com
   ```

   > [!note]
   > Si vous devez réinitialiser vos identifiants, consultez [comment réinitialiser les identifiants SSH pour un utilisateur sur une VM Azure](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/linux/troubleshoot-ssh-connection#reset-ssh-credentials-for-a-user).

1. Ouvrez `/etc/gitlab/gitlab.rb` avec votre éditeur.
1. Trouvez `external_url` et remplacez-le par votre propre nom de domaine. Pour les besoins de cet exemple, utilisez le nom de domaine par défaut qu'Azure configure. L'utilisation de `https` dans l'URL [active automatiquement](https://docs.gitlab.com/omnibus/settings/ssl/#lets-encrypt-integration) Let's Encrypt et configure HTTPS par défaut :

   ```ruby
   external_url 'https://gitlab-prod.eastus.cloudapp.azure.com'
   ```

1. Trouvez les paramètres suivants et commentez-les, afin que GitLab ne récupère pas les mauvais certificats :

   ```ruby
   # nginx['redirect_http_to_https'] = true
   # nginx['ssl_certificate'] = "/etc/gitlab/ssl/server.crt"
   # nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/server.key"
   ```

1. Reconfigurez GitLab pour que les modifications prennent effet. Exécutez la commande suivante chaque fois que vous apportez des modifications à `/etc/gitlab/gitlab.rb` :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Pour éviter que le nom de domaine ne soit [réinitialisé après un redémarrage](https://docs.bitnami.com/aws/apps/gitlab/configuration/change-default-address/), renommez l'utilitaire utilisé par Bitnami :

   ```shell
   sudo mv /opt/bitnami/apps/gitlab/bnconfig /opt/bitnami/apps/gitlab/bnconfig.bak
   ```

Vous pouvez maintenant accéder à GitLab depuis votre navigateur à l'aide de la nouvelle URL externe.

### Première visite de GitLab {#visit-gitlab-for-the-first-time}

Utilisez le nom de domaine que vous avez configuré précédemment pour accéder à votre nouvelle instance GitLab dans votre navigateur. Dans cet exemple, il s'agit de `https://gitlab-prod.eastus.cloudapp.azure.com`.

La première chose qui apparaît est la page de connexion. GitLab crée un utilisateur administrateur par défaut. Les identifiants sont :

- Nom d'utilisateur : `root`
- Mot de passe : le mot de passe est créé automatiquement et il existe [deux façons de le trouver](https://docs.bitnami.com/virtual-machine/faq/get-started/find-credentials/).

Après vous être connecté, veillez à [changer immédiatement le mot de passe](../../user/profile/user_passwords.md#change-your-password).

## Maintenir votre instance GitLab {#maintain-your-gitlab-instance}

Il est important de maintenir votre environnement GitLab à jour. L'équipe GitLab apporte constamment des améliorations et vous pouvez parfois avoir besoin d'effectuer une mise à jour pour des raisons de sécurité. Utilisez les informations de cette section chaque fois que vous devez mettre à jour GitLab.

### Vérifier la version actuelle {#check-the-current-version}

Pour déterminer la version de GitLab que vous utilisez actuellement :

1. dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Tableau de bord**.
1. Trouvez la version dans le tableau **Composants**.

Si une version plus récente de GitLab contenant un ou plusieurs correctifs de sécurité est disponible, GitLab affiche une notification **Update asap** vous invitant à [effectuer la mise à jour](#update-gitlab).

### Mettre à jour GitLab {#update-gitlab}

Pour mettre à jour GitLab vers la dernière version :

1. Connectez-vous à la VM via SSH.
1. Mettez à jour GitLab :

   ```shell
   sudo apt update
   sudo apt install gitlab-ee
   ```

   Cette commande met à jour GitLab et ses composants associés vers les dernières versions et peut prendre un certain temps. Pendant ce temps, le terminal affiche les différentes tâches de mise à jour effectuées dans votre terminal.

   > [!note]
   > Si vous obtenez une erreur du type `E: The repository 'https://packages.gitlab.com/gitlab/gitlab-ee/debian buster InRelease' is not signed.`, consultez la [section de dépannage](#update-the-gpg-key-for-the-gitlab-repositories).

1. Une fois le processus de mise à jour terminé, un message similaire au suivant apparaît :

   ```plaintext
   Upgrade complete! If your GitLab server is misbehaving try running

      sudo gitlab-ctl restart

   before anything else.
   ```

Actualisez votre instance GitLab dans le navigateur et accédez à la zone **Admin**. Votre instance GitLab est maintenant à jour.

## Étapes suivantes et configuration avancée {#next-steps-and-further-configuration}

Maintenant que vous disposez d'une instance GitLab fonctionnelle, suivez les [étapes suivantes](../next_steps.md) pour découvrir ce que vous pouvez faire de plus avec votre nouvelle installation.

## Dépannage {#troubleshooting}

Cette section décrit les erreurs courantes que vous pouvez rencontrer.

### Mettre à jour la clé GPG pour les dépôts GitLab {#update-the-gpg-key-for-the-gitlab-repositories}

> [!note]
> Il s'agit d'un correctif temporaire jusqu'à ce que l'image GitLab soit mise à jour avec la nouvelle clé GPG.

L'image GitLab préconfigurée dans Azure (fournie par Bitnami) utilise une clé GPG [dépréciée en avril 2020](https://about.gitlab.com/blog/gpg-key-for-gitlab-package-repositories-metadata-changing/).

Si vous essayez de mettre à jour les dépôts, le système renvoie l'erreur suivante :

```plaintext
[   21.023494] apt-setup[1198]: W: GPG error: https://packages.gitlab.com/gitlab/gitlab-ee/debian buster InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
[   21.024033] apt-setup[1198]: E: The repository 'https://packages.gitlab.com/gitlab/gitlab-ee/debian buster InRelease' is not signed.
```

Pour corriger ce problème, récupérez la nouvelle clé GPG :

```shell
sudo apt install gpg-agent
sudo curl --fail --silent --show-error \
     --output /etc/apt/trusted.gpg.d/gitlab.asc \
     --url "https://gitlab-org.gitlab.io/omnibus-gitlab/gitlab_new_gpg.key"
```

Vous pouvez maintenant [mettre à jour GitLab](#update-gitlab). Pour plus d'informations, consultez la documentation sur les [signatures des paquets](https://docs.gitlab.com/omnibus/update/package_signatures/).
