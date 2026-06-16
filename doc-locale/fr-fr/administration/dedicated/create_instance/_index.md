---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Complétez le processus d'intégration Switchboard pour créer votre instance GitLab Dedicated et y accéder."
title: Créer votre instance GitLab Dedicated
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

Utilisez Switchboard, le portail de gestion GitLab Dedicated, pour créer votre instance GitLab Dedicated.

Ce processus comprend les étapes suivantes :

- Obtenir l'accès à Switchboard.
- Créer votre instance.
- Accéder à votre nouvelle instance.

## Obtenir l'accès à Switchboard {#get-access-to-switchboard}

Pour accéder à Switchboard :

1. Fournissez à votre équipe de compte les informations suivantes :

   - Nombre d'utilisateurs prévu
   - [Total du stockage acheté](storage_types.md#total-purchased-storage)
   - Taille de stockage initiale pour vos dépôts en Gio
   - Adresses e-mail des utilisateurs qui ont besoin d'un accès Switchboard pour créer votre instance GitLab Dedicated
   - Si vous souhaitez utiliser la migration Geo
   - Si vous souhaitez utiliser vos propres clés de chiffrement pour sécuriser vos données plutôt que de laisser GitLab gérer le chiffrement pour vous

   Si vous souhaitez utiliser vos propres clés de chiffrement, GitLab fournit un ID de compte AWS pour la configuration des clés.

1. Vérifiez votre e-mail pour une invitation contenant des identifiants Switchboard temporaires.

   > [!note]
   > Les identifiants Switchboard sont distincts de tout identifiant GitLab.com ou GitLab Self-Managed existant.

1. Connectez-vous à Switchboard en utilisant les identifiants temporaires.
1. Mettez à jour votre mot de passe et configurez l'authentification multifacteur (MFA).

## Créer votre instance {#create-your-instance}

Pour créer votre instance GitLab Dedicated :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. Sur la page **Account details**, examinez et confirmez vos paramètres d'abonnement :

   - **Reference architecture** :  Le niveau de dimensionnement de l'infrastructure pour votre instance, basé sur la charge prévue et les modèles d'utilisation. Nommé par le nombre maximum d'utilisateurs recommandé (par exemple, « Jusqu'à 3 000 utilisateurs »). Déterminé par votre équipe de compte en fonction de vos exigences contractuelles. Pour plus d'informations, consultez [expected load](../../reference_architectures/_index.md#expected-load).
   - **Total du stockage acheté** :  L'espace de stockage total acheté (dépôt et stockage d'objets) inclus dans votre contrat. Prédéfini par votre équipe de compte.
   - **Stockage du dépôt** :  L'espace de stockage total disponible pour tous les dépôts (par exemple, 16 Gio). Basé sur les discussions de planification initiale de la capacité à l'aide de l'[outil Evaluate](https://gitlab.com/gitlab-org/professional-services-automation/tools/utilities/evaluate). Peut être augmenté mais pas diminué après le provisionnement.

   Ces paramètres sont prédéfinis par votre contrat et les discussions avec votre équipe de compte.

1. Sur la page **Configuration**, renseignez les champs :

   - **Tenant name** :  Saisissez un nom pour l'URL de votre instance (`<tenant_name>.gitlab-dedicated.com`). Ne peut pas être modifié après le provisionnement, sauf si vous configurez un domaine personnalisé.
   - **Primary region** :  Sélectionnez votre région AWS pour les opérations et le stockage des données. Ne peut pas être modifié après le provisionnement car toute l'infrastructure (calcul, stockage, bases de données) est provisionnée dans cette région.
   - **Primary region Availability Zone IDs (AZ IDs)** :  Choisissez la façon dont GitLab sélectionne les zones de disponibilité :
     - **Default AZ IDs** (recommandé) :  GitLab sélectionne les zones de disponibilité pour votre instance.
     - **Custom AZ IDs** :  Sélectionnez deux AZ IDs correspondant à votre infrastructure AWS existante. Requis pour connecter votre propre infrastructure AWS à votre instance GitLab Dedicated au sein de zones de disponibilité spécifiques, y compris les connexions PrivateLink. Ne peut pas être modifié après le provisionnement.
   - **Secondary region** :  Facultatif. Sélectionnez votre région AWS pour la reprise après sinistre basée sur Geo. Ne peut pas être modifié après le provisionnement. Non requis si vous utilisez une méthode de migration Geo.
   - **Secondary region Availability Zone IDs (AZ IDs)** :  Disponible uniquement si vous configurez une région secondaire. Choisissez la façon dont GitLab sélectionne les zones de disponibilité :
     - **Default AZ IDs** (recommandé) :  GitLab sélectionne les zones de disponibilité pour votre instance.
     - **Custom AZ IDs** :  Sélectionnez deux AZ IDs correspondant à votre infrastructure AWS existante. Ne peut pas être modifié après le provisionnement.
   - **Backup region** :  Sélectionnez votre région AWS pour la réplication des sauvegardes. Peut être identique aux régions primaire et secondaire ou différente pour une redondance accrue. Ne peut pas être modifié après le provisionnement car les coffres de sauvegarde et la réplication sont configurés lors du provisionnement.
   - **Maintenance window** :  Sélectionnez votre fenêtre hebdomadaire préférée de 4 heures pour les mises à jour et la [maintenance](../maintenance.md). Les options s'alignent sur les fuseaux horaires (APAC, UE, États-Unis). Pour plus d'informations, consultez le [portail d'informations GitLab Dedicated](https://gitlab-com.gitlab.io/cs-tools/gitlab-cs-tools/dedicated-info-portal/).

1. Sur la page **Sécurité**, configurez le chiffrement pour votre instance.

   GitLab gère les clés de chiffrement automatiquement (recommandé), ou vous pouvez gérer vos propres clés pour répondre aux exigences de conformité.

   > [!warning]
   > Les clés de chiffrement gérées par le client nécessitent une configuration supplémentaire et une gestion continue dans votre propre compte AWS. Vous devez créer et configurer des clés AWS KMS avant de provisionner votre instance. Une fois configurés, ces paramètres ne peuvent pas être modifiés après le provisionnement.

   Pour le chiffrement géré par GitLab (recommandé) :

   - Laissez tous les champs AWS Key Management Service (KMS) vides. GitLab configure automatiquement le chiffrement pour tous les services (sauvegarde, disques EBS, base de données RDS, stockage d'objets S3 et recherche avancée).

   Pour le chiffrement géré par le client :

   1. [Créer des clés de chiffrement](../encryption.md#create-encryption-keys).
   1. Facultatif. Créez des [clés de réplica](../encryption.md#create-replica-keys) uniquement si vous avez sélectionné une région secondaire pour la reprise après sinistre basée sur Geo.
   1. Collectez le nom de ressource Amazon (ARN) pour chaque clé ou clé de réplica. Le format ARN est : `arn:aws:kms:<REGION>:<ACCOUNT-ID>:key/<KEY-ID>`.

      Par exemple : `arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012`

   1. Pour chaque région AWS que vous avez sélectionnée (primaire, secondaire, sauvegarde), renseignez les champs de clé à l'aide de ce mappage :

      - **Primary region Default** :  Utilisez l'ARN de clé de la région primaire.
      - **Secondary region Default** :  Utilisez l'ARN de clé de réplica (uniquement si vous avez configuré une région secondaire pour Geo).
      - **Backup region Default** :  Utilisez l'ARN de clé de la région de sauvegarde. Si votre région de sauvegarde est identique à votre région primaire, utilisez le même ARN de clé.

   1. Pour chaque service (**Backup**, **EBS (disks)**, **RDS (database)**, **S3 (object storage)**, **Recherche avancée**) :  Laissez vide pour utiliser la clé par défaut pour cette région, ou saisissez un ARN de clé KMS spécifique pour ce service. Les clés spécifiques à un service doivent provenir de la même région AWS que la clé par défaut correspondante.
   1. Laissez les champs vides pour les régions que vous n'utilisez pas. Par exemple, si vous n'avez qu'une région primaire, laissez les champs des régions secondaire et de sauvegarde vides.
   1. Vérifiez que tous les ARN sont corrects avant de continuer.

1. Facultatif. Sur la page **Geo migration secrets**, collectez et chargez les secrets chiffrés de votre instance GitLab Self-Managed :

   > [!note]
   > Cette étape est uniquement requise si vous sélectionnez la migration Geo lors de la configuration du compte.

   1. Téléchargez le script correspondant à votre type d'installation et exécutez-le sur votre instance GitLab Self-Managed.
   1. Chargez votre fichier `migration_secrets.json.age`.
   1. Facultatif. Chargez votre fichier `ssh_host_keys.json.age` (recommandé si vous prévoyez d'utiliser un domaine personnalisé).

   Pour des instructions détaillées et le dépannage, consultez [migrer vers GitLab Dedicated avec Geo](../geo_migration.md).

1. Sur la page **Tenant summary**, examinez tous les détails de configuration.

   > [!warning]
   > Vous ne pouvez pas modifier ces paramètres après le provisionnement :
   > - Configuration des clés AWS KMS (BYOK)
   > - Régions AWS (régions primaire, secondaire et de sauvegarde)
   > - IDs des zones de disponibilité AWS (régions primaire et secondaire)
   > - Capacité du dépôt (peut uniquement être augmentée)
   > - Nom et URL du tenant

1. Sélectionnez **Create tenant**.

Le provisionnement de votre instance peut prendre jusqu'à trois heures. Vous recevrez un e-mail de confirmation lorsque la configuration sera terminée.

## Accéder à votre instance {#access-your-instance}

Pour accéder à votre instance GitLab Dedicated :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. Dans la bannière **Access your GitLab Dedicated instance**, sélectionnez **Afficher les identifiants**.
1. Copiez l'URL du tenant et les identifiants root temporaires.

   > [!note]
   > Vous ne pouvez récupérer les identifiants root temporaires qu'une seule fois. Stockez-les en lieu sûr avant de quitter Switchboard.

1. Accédez à l'URL de votre tenant et connectez-vous avec les identifiants root temporaires.
1. [Modifiez votre mot de passe root temporaire](../../../user/profile/user_passwords.md#change-your-password).
1. Dans la zone **Admin**, [ajoutez la clé de licence](../../license_file.md#add-license-in-the-admin-area).
1. Revenez à Switchboard et [ajoutez des utilisateurs](../configure_instance/users_notifications.md#add-switchboard-users) si nécessaire.

## Étapes suivantes {#next-steps}

Consultez le [calendrier de déploiement des releases](../releases.md#release-rollout-schedule) pour les mises à niveau et la maintenance.

Planifiez à l'avance si vous avez besoin de l'une des fonctionnalités suivantes :

- [Connexions PrivateLink entrantes](../configure_instance/network_security.md#inbound-privatelink-connections)
- [Connexions PrivateLink sortantes](../configure_instance/network_security.md#outbound-privatelink-connections)
- [SAML SSO](../configure_instance/authentication/saml.md)
- [Domaines personnalisés](../configure_instance/network_security.md#custom-domains)

Pour toutes les options de configuration, consultez [configurer votre instance GitLab Dedicated](../configure_instance/_index.md).

> [!note]
> Les instances GitLab Dedicated utilisent les mêmes paramètres par défaut que les instances GitLab Self-Managed.
>
> À partir de GitLab 18.0, les fonctionnalités de [GitLab Duo Core](../../../subscriptions/subscription-add-ons.md#gitlab-duo-core) sont activées par défaut pour les nouvelles instances. Pour vous conformer aux exigences de résidence des données ou aux politiques d'utilisation de l'IA, vous pouvez [désactiver GitLab Duo Core](../../../user/gitlab_duo/turn_on_off.md#for-an-instance).
