---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Installez une instance GitLab sur une machine virtuelle dans Google Cloud Platform.
title: Installation de GitLab sur Google Cloud Platform
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez installer GitLab sur [Google Cloud Platform (GCP)](https://cloud.google.com/) en utilisant le package Linux officiel. Vous devez le personnaliser selon vos besoins.

> [!note]
> Pour déployer GitLab prêt pour la production sur Google Kubernetes Engine, vous pouvez suivre les [`Click to Deploy` étapes](https://github.com/GoogleCloudPlatform/click-to-deploy/blob/master/k8s/gitlab/README.md) de Google Cloud Platform. Il s'agit d'une alternative à l'utilisation d'une VM GCP, qui utilise le [chart Helm GitLab Cloud native](https://docs.gitlab.com/charts/).

## Prérequis {#prerequisites}

Il existe deux prérequis pour installer GitLab sur GCP :

1. Vous devez disposer d'un compte Google.
1. Vous devez vous inscrire au programme GCP. Si c'est votre première fois, Google vous offre [300 $ de crédit gratuit](https://console.cloud.google.com/freetrial) à utiliser sur une période de 60 jours.

Une fois ces deux étapes effectuées, vous pouvez [créer une VM](#creating-the-vm).

## Création de la VM {#creating-the-vm}

Pour déployer GitLab sur GCP, vous devez créer une machine virtuelle :

1. Accédez à <https://console.cloud.google.com/compute/instances> et connectez-vous avec vos identifiants Google.
1. Sélectionnez **Créer**

   ![Sélectionnez « Créer » pour créer une instance.](img/launch_vm_v10_6.png)

1. Sur la page suivante, vous pouvez sélectionner le type de VM ainsi que les coûts estimés. Indiquez le nom de l'instance, le centre de données souhaité et le type de machine. Consultez nos [exigences matérielles pour différentes tailles de base d'utilisateurs](../requirements.md).

   ![Configurez votre instance.](img/vm_details_v13_1.png)

1. Pour sélectionner la taille, le type et le [système d'exploitation](../package/_index.md) souhaité, sélectionnez **Change** sous `Boot disk`. Sélectionnez **Sélectionner** une fois terminé.

1. Obligatoire pour les licences payantes. Sous **Labels**, ajoutez des labels de ressources selon la manière dont vous avez acquis votre licence GitLab :
   - Pour l'approvisionnement via Google Cloud Marketplace, ajoutez :
     - Clé : `goog-partner-solution`
     - Valeur : `isol_plb32_0014m00001h35gdqaq_i4j66u754ivftu3n2bb3vyv7fek76fjo`
   - Pour l'approvisionnement hors marketplace, ajoutez :
     - Clé : `goog-partner-solution`
     - Valeur : `isol_psn_0014m00001h35gdqaq_gitlab`

   Ces labels marquent les ressources comme liées à une installation GitLab sur Google Cloud, conformément aux exigences du contrat de partenariat. Pour plus d'informations sur les labels de ressources, consultez la [documentation Google Cloud sur l'étiquetage des ressources](https://cloud.google.com/compute/docs/labeling-resources#create_resources_with_labels).

   > [!note]
   > Vous pouvez également utiliser Terraform pour automatiser la création de l'infrastructure avec les labels appropriés. Consultez le [code Terraform d'installation de GitLab sur Google Cloud](https://gitlab.com/gitlab-partners-public/google-cloud/source-code/gitlab-installation-on-google-cloud) pour référence.

1. Autorisez le trafic HTTP et HTTPS, puis sélectionnez **Créer**. Le processus se termine en quelques secondes.

## Installation de GitLab {#installing-gitlab}

Après quelques secondes, l'instance est créée et disponible pour la connexion. L'étape suivante consiste à installer GitLab sur l'instance.

![L'instance a été créée avec succès.](img/vm_created_v10_6.png)

1. Notez l'adresse IP externe de l'instance, car vous en aurez besoin lors d'une étape ultérieure. <!-- using future tense is okay here -->
1. Sélectionnez **SSH** dans la colonne de connexion pour vous connecter à l'instance.
1. Une nouvelle fenêtre s'ouvre, avec vous connecté à l'instance.

   ![L'interface de ligne de commande de l'instance](img/ssh_terminal_v10_6.png)

1. Ensuite, suivez les instructions d'installation de GitLab pour le système d'exploitation de votre choix, à l'adresse <https://about.gitlab.com/install/>. Vous pouvez utiliser l'adresse IP externe que vous avez notée précédemment comme nom d'hôte.
1. Félicitations ! GitLab est maintenant installé et vous pouvez y accéder via votre navigateur. Pour terminer l'installation, ouvrez l'URL dans votre navigateur et saisissez le mot de passe administrateur initial. Le nom d'utilisateur de ce compte est `root`.

   ![Première connexion à GitLab après l'installation.](img/first_signin_v10_6.png)

## Étapes suivantes {#next-steps}

Voici les étapes suivantes les plus importantes à effectuer après avoir installé GitLab pour la première fois.

### Attribution d'une adresse IP statique {#assigning-a-static-ip}

Par défaut, Google attribue une adresse IP éphémère à votre instance. Si vous utilisez GitLab dans un environnement de production avec un nom de domaine, vous devez attribuer une adresse IP statique.

Pour plus d'informations, consultez [Promouvoir une adresse IP externe éphémère](https://cloud.google.com/vpc/docs/reserve-static-external-ip-address#promote_ephemeral_ip).

### Utilisation d'un nom de domaine {#using-a-domain-name}

En supposant que vous disposez d'un nom de domaine et que vous avez correctement configuré le DNS pour pointer vers l'adresse IP statique configurée à l'étape précédente, voici comment configurer GitLab pour prendre en compte ce changement :

1. Connectez-vous à la VM via SSH. Vous pouvez sélectionner **SSH** dans la console Google et une nouvelle fenêtre s'ouvre.

   ![Détails de l'instance avec un bouton SSH pour s'y connecter.](img/vm_created_v10_6.png)

   À l'avenir, vous pourriez envisager de configurer la [connexion avec une clé SSH](https://docs.cloud.google.com/compute/docs/connect/standard-ssh) à la place.

1. Modifiez le fichier de configuration du package Linux à l'aide de votre éditeur de texte préféré :

   ```shell
   sudo vim /etc/gitlab/gitlab.rb
   ```

1. Définissez la valeur `external_url` sur le nom de domaine que vous souhaitez attribuer à GitLab **sans** `https` :

   ```ruby
   external_url 'http://gitlab.example.com'
   ```

   Nous configurerons HTTPS à l'étape suivante, inutile de le faire maintenant. <!-- using future tense is okay here -->

1. Reconfigurez GitLab pour que les modifications prennent effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Vous pouvez maintenant accéder à GitLab en utilisant le nom de domaine.

### Configuration de HTTPS avec le nom de domaine {#configuring-https-with-the-domain-name}

Bien que ce ne soit pas obligatoire, il est fortement recommandé de sécuriser GitLab avec un [certificat TLS](https://docs.gitlab.com/omnibus/settings/ssl/).

### Configuration des paramètres SMTP des e-mails {#configuring-the-email-smtp-settings}

Vous devez configurer correctement les paramètres SMTP des e-mails, sinon GitLab ne peut pas envoyer de notifications par e-mail, notamment les commentaires et les changements de mot de passe. Consultez la [documentation du package Linux](https://docs.gitlab.com/omnibus/settings/smtp/#smtp-settings) pour savoir comment procéder.

## Pour aller plus loin {#further-reading}

GitLab peut être configuré pour s'authentifier auprès d'autres fournisseurs OAuth, tels que LDAP, SAML et Kerberos. Voici quelques documents qui pourraient vous intéresser :

- [Documentation du package Linux](https://docs.gitlab.com/omnibus/)
- [Documentation sur les intégrations](../../integration/_index.md)
- [Configuration de GitLab Pages](../../administration/pages/_index.md)
- [Configuration du registre de conteneurs GitLab](../../administration/packages/container_registry.md)
