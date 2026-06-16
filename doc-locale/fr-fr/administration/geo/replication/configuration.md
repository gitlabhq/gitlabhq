---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Finalisez la configuration de votre site Geo secondaire en répliquant les secrets, les clés SSH, et en ajoutant le nouveau site au site principal pour démarrer la synchronisation des données."
title: Configurer un nouveau site secondaire
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!note]
> Il s'agit de la dernière étape de la configuration d'un site Geo **secondaire**. Les étapes du processus de configuration doivent être effectuées dans l'ordre documenté. Sinon, [effectuez toutes les étapes précédentes](../setup/_index.md#using-linux-package-installations) avant de continuer.

Les étapes de base de la configuration d'un site **secondaire** sont les suivantes :

1. Répliquer les configurations requises entre le site **principal** et le site **secondaire**.
1. Configurer une base de données de suivi sur chaque site **secondaire**.
1. Démarrer GitLab sur chaque site **secondaire**.

Ce document se concentre sur le premier point. Nous vous encourageons à lire d'abord toutes les étapes avant de les exécuter dans votre environnement de test/production.

Prérequis pour **both primary and secondary sites** :

- [Configurer la réplication de la base de données](../setup/database.md)
- [Configurer la recherche rapide des clés SSH autorisées](../../operations/fast_ssh_key_lookup.md)

> [!note]
> **Do not** d'authentification personnalisée pour le site **secondaire**. Cela est géré par le site **principal**. Tout changement nécessitant un accès à la zone **Admin** doit être effectué sur le site **principal**, car le site **secondaire** est un réplica en lecture seule.

## Étape 1. Répliquer manuellement les valeurs secrètes de GitLab {#step-1-manually-replicate-secret-gitlab-values}

GitLab stocke un certain nombre de valeurs secrètes dans le fichier `/etc/gitlab/gitlab-secrets.json` qui doit être identique sur tous les nœuds d'un site. Jusqu'à ce qu'il existe un moyen de les répliquer automatiquement entre les sites (voir [issue #3789](https://gitlab.com/gitlab-org/gitlab/-/issues/3789)), ils doivent être répliqués manuellement sur **all nodes of the secondary site**.

1. Connectez-vous en SSH à un **Rails node on your primary** et exécutez la commande ci-dessous :

   ```shell
   sudo cat /etc/gitlab/gitlab-secrets.json
   ```

   Cela affiche les secrets à répliquer, au format JSON.

1. Connectez-vous en SSH **into each node on your secondary Geo site** et identifiez-vous en tant qu'utilisateur `root` :

   ```shell
   sudo -i
   ```

1. Effectuez une sauvegarde des secrets existants :

   ```shell
   mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.`date +%F`
   ```

1. Copiez `/etc/gitlab/gitlab-secrets.json` depuis le **Rails node on your primary** vers **each node on your secondary**, ou copiez-collez le contenu du fichier entre les nœuds :

   ```shell
   sudo editor /etc/gitlab/gitlab-secrets.json

   # paste the output of the `cat` command you ran on the primary
   # save and exit
   ```

1. Vérifiez que les permissions du fichier sont correctes :

   ```shell
   chown root:root /etc/gitlab/gitlab-secrets.json
   chmod 0600 /etc/gitlab/gitlab-secrets.json
   ```

1. Reconfigurez **each Rails, Sidekiq and Gitaly nodes on your secondary** pour que le changement prenne effet :

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

## Étape 2. Répliquer manuellement les clés d'hôte SSH du site **principal** {#step-2-manually-replicate-the-primary-sites-ssh-host-keys}

GitLab s'intègre au démon SSH installé sur le système, en désignant un utilisateur (généralement nommé `git`) par lequel toutes les demandes d'accès sont traitées.

Dans une situation de [reprise après sinistre](../disaster_recovery/_index.md), les administrateurs système GitLab font passer un site **secondaire** au statut de site **principal**. Les enregistrements DNS du domaine **principal** doivent également être mis à jour pour pointer vers le nouveau site **principal** (précédemment un site **secondaire**). Cela évite de devoir mettre à jour les remotes Git et les URL d'API.

Cela entraîne l'échec de toutes les requêtes SSH vers le nouveau site **principal** promu en raison d'une discordance de clé d'hôte SSH. Pour éviter cela, les clés d'hôte SSH du site principal doivent être répliquées manuellement vers le site **secondaire**.

Le chemin de la clé d'hôte SSH dépend du logiciel utilisé :

- Si vous utilisez OpenSSH, le chemin est `/etc/ssh`.
- Si vous utilisez [`gitlab-sshd`](../../operations/gitlab_sshd.md), le chemin est `/var/opt/gitlab/gitlab-sshd`.

Dans les étapes suivantes, remplacez `<ssh_host_key_path>` par celui que vous utilisez :

1. Connectez-vous en SSH à **each Rails node on your secondary** et identifiez-vous en tant qu'utilisateur `root` :

   ```shell
   sudo -i
   ```

1. Effectuez une sauvegarde des clés d'hôte SSH existantes :

   ```shell
   find <ssh_host_key_path> -iname 'ssh_host_*' -exec cp {} {}.backup.`date +%F` \;
   ```

1. Copiez les clés d'hôte SSH depuis le site **principal** :

   Si vous pouvez accéder à l'un des **nodes on your primary** gérant le trafic SSH (généralement, les nœuds principaux de l'application GitLab Rails) en utilisant l'utilisateur **root** :

   ```shell
   # Run this from the secondary site, change `<primary_site_fqdn>` for the IP or FQDN of the server
   scp root@<primary_node_fqdn>:<ssh_host_key_path>/ssh_host_*_key* <ssh_host_key_path>
   ```

   Si vous avez uniquement accès via un utilisateur disposant des privilèges `sudo` :

   ```shell
   # Run this from the node on your primary site:
   sudo tar --transform 's/.*\///g' -zcvf ~/geo-host-key.tar.gz <ssh_host_key_path>/ssh_host_*_key*

   # Run this on each node on your secondary site:
   scp <user_with_sudo>@<primary_site_fqdn>:geo-host-key.tar.gz .
   tar zxvf ~/geo-host-key.tar.gz -C <ssh_host_key_path>
   ```

1. Sur **each Rails node on your secondary**, vérifiez que les permissions du fichier sont correctes :

   ```shell
   chown root:root <ssh_host_key_path>/ssh_host_*_key*
   chmod 0600 <ssh_host_key_path>/ssh_host_*_key
   ```

1. Pour vérifier la correspondance des empreintes de clé, exécutez la commande suivante sur les nœuds principal et secondaire de chaque site :

   ```shell
   for file in <ssh_host_key_path>/ssh_host_*_key; do ssh-keygen -lf $file; done
   ```

   Vous devriez obtenir une sortie similaire à celle-ci, et elles doivent être identiques sur les deux nœuds :

   ```shell
   1024 SHA256:FEZX2jQa2bcsd/fn/uxBzxhKdx4Imc4raXrHwsbtP0M root@serverhostname (DSA)
   256 SHA256:uw98R35Uf+fYEQ/UnJD9Br4NXUFPv7JAUln5uHlgSeY root@serverhostname (ECDSA)
   256 SHA256:sqOUWcraZQKd89y/QQv/iynPTOGQxcOTIXU/LsoPmnM root@serverhostname (ED25519)
   2048 SHA256:qwa+rgir2Oy86QI+PZi/QVR+MSmrdrpsuH7YyKknC+s root@serverhostname (RSA)
   ```

1. Vérifiez que vous disposez des clés publiques correctes pour les clés privées existantes :

   ```shell
   # This will print the fingerprint for private keys:
   for file in <ssh_host_key_path>/ssh_host_*_key; do ssh-keygen -lf $file; done

   # This will print the fingerprint for public keys:
   for file in <ssh_host_key_path>/ssh_host_*_key.pub; do ssh-keygen -lf $file; done
   ```

   > [!note]
   > La sortie de la commande pour les clés privées et les clés publiques doit générer la même empreinte.

1. Redémarrez `sshd` pour OpenSSH ou le service `gitlab-sshd` sur **each Rails node on your secondary** :

   - Pour OpenSSH :

     ```shell
     # Debian or Ubuntu installations
     sudo service ssh reload

     # CentOS installations
     sudo service sshd reload
     ```

   - Pour `gitlab-sshd` :

     ```shell
     sudo gitlab-ctl restart gitlab-sshd
     ```

1. Vérifiez que SSH est toujours fonctionnel.

   Connectez-vous en SSH à votre serveur GitLab **secondaire** dans un nouveau terminal. Si vous ne pouvez pas vous connecter, vérifiez que les permissions sont correctes conformément aux étapes précédentes.

## Étape 3. Ajouter le site **secondaire** {#step-3-add-the-secondary-site}

1. Connectez-vous en SSH à **each Rails and Sidekiq node on your secondary** et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez un nom **unique** pour votre site. Vous en aurez besoin dans les prochaines étapes :

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

1. Reconfigurez **each Rails and Sidekiq node on your secondary** pour que le changement prenne effet :

   ```shell
   gitlab-ctl reconfigure
   ```

1. Accédez à l'instance GitLab du nœud principal :
   1. Dans le coin supérieur droit, sélectionnez **Admin**.
   1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
   1. Sélectionnez **Ajouter un site**. ![Ajout d'un site secondaire dans l'interface de configuration Geo](img/adding_a_secondary_v15_8.png)
   1. Dans **Nom**, saisissez la valeur de `gitlab_rails['geo_node_name']` dans `/etc/gitlab/gitlab.rb`. Ces valeurs doivent toujours correspondre **exactly**, caractère par caractère.
   1. Dans **URL externe**, saisissez la valeur de `external_url` dans `/etc/gitlab/gitlab.rb`. Ces valeurs doivent toujours correspondre, peu importe si l'une se termine par `/` et l'autre non.
   1. Facultatif. Dans **URL interne (facultatif)**, saisissez une URL interne pour le site secondaire.
   1. Facultatif. Sélectionnez les groupes ou les partitions de stockage qui doivent être répliqués par le site **secondaire**. Laissez vide pour tout répliquer. Pour plus d'informations, consultez [la synchronisation sélective](selective_synchronization.md).
   1. Sélectionnez **Sauvegarder les modifications** pour ajouter le site **secondaire**.
1. Connectez-vous en SSH à **each Rails, and Sidekiq node on your secondary** et redémarrez les services :

   ```shell
   gitlab-ctl restart
   ```

   Vérifiez s'il existe des problèmes courants avec votre configuration Geo en exécutant :

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   Si l'une des vérifications échoue, consultez la [documentation de dépannage](troubleshooting/_index.md).

1. Connectez-vous en SSH à un **Rails or Sidekiq server on your primary** et identifiez-vous en tant que root pour vérifier que le site **secondaire** est accessible ou s'il existe des problèmes courants avec votre configuration Geo :

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   Si l'une des vérifications échoue, consultez la [documentation de dépannage](troubleshooting/_index.md).

Une fois le site **secondaire** ajouté à la page d'administration Geo et redémarré, le site commence automatiquement à répliquer les données manquantes depuis le site **principal** dans un processus connu sous le nom de **backfill**. Pendant ce temps, le site **principal** commence à notifier chaque site **secondaire** de tout changement, afin que le site **secondaire** puisse agir immédiatement sur ces notifications.

Assurez-vous que le site secondaire est en cours d'exécution et accessible. Vous pouvez vous connecter au site secondaire avec les mêmes identifiants que ceux utilisés avec le site principal.

### Ajouter les URL principale et secondaire comme origines ActionCable autorisées {#add-primary-and-secondary-urls-as-allowed-actioncable-origins}

Cette étape permet aux websockets de fonctionner de manière transparente depuis les sites principal et secondaire.

1. Collectez les **external URLs** de vos sites (principal et secondaire). Vous pouvez les trouver dans les pages de sites dans la zone Admin, comme mentionné dans la section ci-dessus.
1. Connectez-vous en SSH à chaque nœud Rails et Sidekiq de votre **primary site** et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` pour ajouter les URL collectées à l'étape 1 au paramètre `action_cable_allowed_origins` :

   ```ruby
   gitlab_rails['action_cable_allowed_origins'] = ['https://secondary.example.com', 'https://primary.example.com']
   ```

1. Pour appliquer les modifications, reconfigurez chaque nœud Rails et Sidekiq et redémarrez le service :

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

## Étape 4. (Facultatif) Utilisation de certificats personnalisés {#step-4-optional-using-custom-certificates}

Vous pouvez ignorer cette étape en toute sécurité si :

- Votre site **principal** utilise un certificat HTTPS émis par une CA publique.
- Votre site **principal** se connecte uniquement à des services externes avec des certificats HTTPS émis par une CA (non auto-signés).

### Certificat personnalisé ou auto-signé pour les connexions entrantes {#custom-or-self-signed-certificate-for-inbound-connections}

Si votre site Geo GitLab **principal** utilise un [certificat personnalisé ou auto-signé pour sécuriser les connexions HTTPS entrantes](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates), il peut s'agir d'un certificat mono-domaine ou multi-domaine.

Installez le certificat approprié en fonction de votre type de certificat :

- **Multi-domain certificate** incluant les domaines des sites principal et secondaire :  Installez le certificat dans `/etc/gitlab/ssl` sur tous les nœuds **Rails, Sidekiq, and Gitaly** du site **secondaire**.
- **Single-domain certificate** où les certificats sont spécifiques au domaine de chaque site Geo :  Générez un certificat valide pour le domaine de votre site **secondaire** et installez-le dans `/etc/gitlab/ssl` en suivant [ces instructions](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates) sur tous les nœuds **Rails, Sidekiq, and Gitaly** du site **secondaire**.

### Connexion à des services externes utilisant des certificats personnalisés {#connecting-to-external-services-that-use-custom-certificates}

Une copie du certificat auto-signé du service externe doit être ajoutée au magasin de confiance sur tous les nœuds du site **principal** qui nécessitent un accès au service.

Pour que le site **secondaire** puisse accéder aux mêmes services externes, ces certificats doivent être ajoutés au magasin de confiance du site **secondaire**.

Si votre site **principal** utilise un [certificat personnalisé ou auto-signé pour les connexions HTTPS entrantes](#custom-or-self-signed-certificate-for-inbound-connections), le certificat du site **principal** doit être ajouté au magasin de confiance du site **secondaire** :

1. Connectez-vous en SSH à chaque **Rails, Sidekiq, and Gitaly node on your secondary** et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Copiez les certificats de confiance depuis le site **principal** :

   Si vous pouvez accéder à l'un des nœuds de votre site **principal** gérant le trafic SSH en utilisant l'utilisateur root :

   ```shell
   scp root@<primary_site_node_fqdn>:/etc/gitlab/trusted-certs/* /etc/gitlab/trusted-certs
   ```

   Si vous avez uniquement accès via un utilisateur avec des privilèges sudo :

   ```shell
   # Run this from the node on your primary site:
   sudo tar --transform 's/.*\///g' -zcvf ~/geo-trusted-certs.tar.gz /etc/gitlab/trusted-certs/*

   # Run this on each node on your secondary site:
   scp <user_with_sudo>@<primary_site_node_fqdn>:geo-trusted-certs.tar.gz .
   tar zxvf ~/geo-trusted-certs.tar.gz -C /etc/gitlab/trusted-certs
   ```

1. Reconfigurez chaque **Rails, Sidekiq, and Gitaly node in your secondary** :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Étape 5. Vérifier le bon fonctionnement du site **secondaire** {#step-5-verify-proper-functioning-of-the-secondary-site}

Vous pouvez vous connecter au site **secondaire** avec les mêmes identifiants que ceux utilisés avec le site **principal**. Après vous être connecté :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Vérifiez qu'il est correctement identifié comme site Geo **secondaire** et que Geo est activé.

La réplication initiale peut prendre un certain temps. Le statut du site ou du « backfill » peut encore être en cours. Vous pouvez surveiller le processus de synchronisation sur chaque site Geo depuis le tableau de bord **Sites Geo** du site **principal** dans votre navigateur.

![Tableau de bord Geo du site secondaire](img/geo_dashboard_v14_0.png)

Si votre installation ne fonctionne pas correctement, consultez le [document de dépannage](troubleshooting/_index.md).

Les deux problèmes les plus évidents qui peuvent apparaître dans le tableau de bord sont :

1. La réplication de la base de données ne fonctionne pas correctement.
1. La notification d'instance à instance ne fonctionne pas. Dans ce cas, il peut s'agir de l'un des éléments suivants :
   - Vous utilisez un certificat personnalisé ou une CA personnalisée (voir le [document de dépannage](troubleshooting/_index.md)).
   - L'instance est protégée par un pare-feu (vérifiez vos règles de pare-feu).

La désactivation d'un site **secondaire** arrête le processus de synchronisation.

Si les stockages de dépôts sont personnalisés sur le site **principal** pour plusieurs partitions de dépôts, vous devez dupliquer la même configuration sur chaque site **secondaire**.

Dirigez vos utilisateurs vers le [guide d'utilisation d'un site Geo](usage.md).

Actuellement, voici ce qui est synchronisé :

- Dépôts Git.
- Wikis.
- Objets LFS.
- Tickets, merge requests, snippets et pièces jointes aux commentaires.
- Avatars des utilisateurs, des groupes et des projets.

## Dépannage {#troubleshooting}

Consultez le [document de dépannage](troubleshooting/_index.md).
