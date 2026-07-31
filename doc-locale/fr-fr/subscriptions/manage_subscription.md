---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Achetez, consultez et renouvelez vos abonnements GitLab."
title: "Gérer l'abonnement"
---

## Acheter un abonnement {#buy-a-subscription}

Après avoir [créé votre compte](https://gitlab.com/users/sign_up) GitLab, vous pouvez acheter un abonnement pour GitLab.com ou GitLab Self-Managed. L'abonnement détermine les fonctionnalités disponibles pour vos projets privés.

Une fois abonné à GitLab, vous pouvez gérer les détails de votre abonnement. Si vous rencontrez des problèmes, consultez la page [Dépannage de l'abonnement GitLab](gitlab_com/gitlab_subscription_troubleshooting.md).

Les organisations disposant de projets open source publics peuvent postuler au [programme GitLab for Open Source](community_programs.md#gitlab-for-open-source).

### Pour GitLab.com {#for-gitlabcom}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

GitLab.com est l'offre GitLab SaaS (software-as-a-service) mutualisée. Vous n'avez rien à installer pour utiliser GitLab.com ; il vous suffit de [créer un compte](https://gitlab.com/users/sign_up). Lors de la création de votre compte, vous choisissez :

- [Un abonnement](https://about.gitlab.com/pricing/). Consultez la [comparaison des fonctionnalités GitLab.com](https://about.gitlab.com/pricing/feature-comparison/) et décidez quelle édition vous convient.
- Le nombre de sièges souhaités.
- Une option GitLab Credits.

Un abonnement GitLab.com s'applique à un groupe principal. Les membres de chaque sous-groupe et projet du groupe :

- Peuvent utiliser les fonctionnalités de l'abonnement.
- Consomment des sièges dans l'abonnement.

Si un utilisateur consulte ou sélectionne un autre groupe principal (qu'il a créé lui-même, par exemple) et que ce groupe ne dispose pas d'un abonnement payant, l'utilisateur ne voit aucune des fonctionnalités payantes.

Un utilisateur peut appartenir à deux groupes principaux différents avec des abonnements différents. Dans ce cas, l'utilisateur ne voit que les fonctionnalités disponibles pour cet abonnement.

Pour vous abonner à GitLab.com :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Facturation**.
1. Sélectionnez **Passer à un abonnement supérieur**.
1. Sélectionnez une édition et une option GitLab Credits.
1. Sélectionnez **Passer au paiement**. Vous êtes redirigé vers le portail clients.
1. Dans le champ **Sièges**, saisissez le nombre de sièges souhaités.
1. Vérifiez les détails de l'abonnement et les informations de facturation.
1. Cochez la case **I accept the Privacy Statement and Terms of Service**.
1. Sélectionnez **S'abonner**.

### Pour GitLab Self-Managed {#for-gitlab-self-managed}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour vous abonner à GitLab pour une instance GitLab Self-Managed :

- Accédez à la [page de tarification](https://about.gitlab.com/pricing/) et sélectionnez un forfait self-managed. Vous êtes redirigé vers le [portail clients](https://customers.gitlab.com/) pour finaliser votre achat.

> [!note]
> Si vous achetez un abonnement pour une instance GitLab Self-Managed existante en édition **Gratuite**, assurez-vous d'acheter suffisamment de sièges pour [couvrir vos utilisateurs](../administration/admin_area.md#administering-users).

## Activer l'abonnement {#activate-subscription}

Après avoir acheté un abonnement :

- Sur GitLab.com, votre abonnement s'applique automatiquement à votre groupe principal. Vous n'avez pas besoin d'un code d'activation. Si vous avez acheté l'abonnement via un représentant de compte ou un partenaire GitLab, vous devez d'abord associer l'abonnement à votre groupe principal.
- Sur GitLab Self-Managed, vous recevez un code d'activation à l'adresse e-mail associée à votre compte du portail clients.

Pour commencer à utiliser votre abonnement :

1. Pour GitLab Self-Managed, [activez votre licence](../administration/license.md) avec le code d'activation.
1. Consultez votre abonnement pour confirmer l'édition, le nombre de sièges, ainsi que les dates de début et de fin.
1. Pour GitLab.com, si l'abonnement n'est pas appliqué au bon groupe principal, associez l'abonnement à un groupe.
1. Vérifiez votre compte pour confirmer votre mode de paiement, ainsi que vos contacts de facturation et d'abonnement.
1. Ajoutez ou modifiez des contacts d'abonnement afin que les bonnes personnes reçoivent les notifications d'abonnement.
1. Ajoutez des utilisateurs, gérez les sièges et attribuez des extensions à votre équipe.

## Consulter l'abonnement {#view-subscription}

### Pour GitLab.com {#for-gitlabcom-1}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Pour voir le statut de votre abonnement GitLab.com :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Facturation**.

Les informations suivantes sont affichées :

| Champ                       | Description |
|:----------------------------|:------------|
| **Sièges dans l'abonnement**   | Si ce forfait est payant, indique le nombre de sièges achetés pour ce groupe (y compris les sièges Enterprise Agile Planning). |
| **Sièges actuellement utilisés**  | Nombre de sièges utilisés. Sélectionnez **Voir l'utilisation** pour afficher la liste des utilisateurs qui utilisent ces sièges. |
| **Maximum seats used**      | Nombre le plus élevé de sièges utilisés. |
| **Sièges dus**              | **Nombre max. de sièges utilisés** - **Sièges dans l'abonnement**. |
| **Date de début de l'abonnement** | Date à laquelle votre abonnement a débuté. |
| **Date de fin de l'abonnement**   | Date à laquelle votre abonnement actuel se termine. |

### Pour GitLab Self-Managed {#for-gitlab-self-managed-1}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Prérequis :

- Être administrateur.

Vous pouvez consulter le statut de votre abonnement :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Abonnement**.

La page **Abonnement** comprend les informations suivantes :

- Titulaire de la licence
- Forfait
- Date de chargement, de début et d'expiration
- Nombre d'utilisateurs dans l'abonnement (y compris les sièges Enterprise Agile Planning)
- Nombre d'utilisateurs facturables
- Nombre maximum d'utilisateurs
- Nombre d'utilisateurs dépassant l'abonnement

## Vérifier votre compte {#review-your-account}

Vous devez régulièrement vérifier les paramètres de votre compte de facturation et vos informations d'achat.

Pour vérifier les paramètres de votre compte de facturation :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Sélectionnez **Billing account settings**.
1. Vérifiez ou mettez à jour :
   - Sous **Payment methods**, la carte de crédit enregistrée.
   - Sous **Company information**, les coordonnées de l'abonnement et du contact de facturation.
1. Enregistrez toutes les modifications.

Vous devez également vérifier régulièrement vos comptes utilisateurs pour vous assurer que vous renouvelez uniquement pour le nombre correct d'utilisateurs facturables actifs. Les comptes utilisateurs inactifs :

- Peuvent être comptabilisés comme utilisateurs facturables. Vous payez plus que nécessaire si vous renouvelez des comptes utilisateurs inactifs.
- Peuvent représenter un risque de sécurité. Un examen régulier permet de réduire ce risque.

Pour plus d'informations, consultez la documentation sur :

- [Statistiques des utilisateurs](../administration/admin_area.md#users-statistics)
- [Utilisation des licences](../administration/license_usage.md)
- [Gestion des utilisateurs et des sièges d'abonnement](manage_seats.md)

## Mettre à niveau l'édition d'abonnement {#upgrade-subscription-tier}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

Prérequis :

- Vous devez être gestionnaire de compte de facturation.

Pour mettre à niveau votre [édition GitLab](https://about.gitlab.com/pricing/) :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Sélectionnez **Mise à niveau du forfait** sur la carte d'abonnement concernée.
1. Sélectionnez le forfait vers lequel vous souhaitez effectuer la mise à niveau.
1. Sélectionnez **Passer au paiement**.
1. Vérifiez les détails de la mise à niveau et les informations de facturation.
1. Cochez la case **I accept the Privacy Statement and Terms of Service**.
1. Sélectionnez **Passer à un abonnement supérieur**.

Les éléments suivants vous sont envoyés par e-mail :

- Un reçu de paiement. Vous pouvez également accéder à ces informations dans le portail clients sous [**Invoices**](https://customers.gitlab.com/invoices).
- Sur GitLab Self-Managed, un nouveau code d'activation pour votre licence.

Sur GitLab Self-Managed, la nouvelle édition prend effet lors de la prochaine synchronisation de l'abonnement. Vous pouvez également [synchroniser votre abonnement manuellement](#subscription-data-synchronization) pour effectuer la mise à niveau immédiatement.

Sur GitLab.com, vous pouvez également sélectionner une option GitLab Credits lors de l'achat d'un abonnement.

## Renouveler l'abonnement {#renew-subscription}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

Avant la date de renouvellement de votre abonnement, vérifiez votre compte pour contrôler votre utilisation actuelle des sièges et vos utilisateurs facturables.

Vous pouvez renouveler votre abonnement automatiquement ou manuellement. Vous devez renouveler votre abonnement manuellement si vous souhaitez :

- Renouveler pour un nombre de sièges inférieur.
- Augmenter ou diminuer les quantités de produits renouvelés.
- Supprimer les produits complémentaires qui ne sont plus nécessaires pour la période d'abonnement renouvelée.
- Mettre à niveau l'édition d'abonnement.

La date de début de la période de renouvellement est affichée sur la page Facturation du groupe sous **Date de début de la prochaine période d'abonnement**.

Contactez :

- [L'équipe d'assistance](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) si vous avez besoin d'aide pour accéder au portail clients ou pour changer le contact qui gère votre abonnement.
- [L'équipe commerciale](https://customers.gitlab.com/contact_us) si vous avez besoin d'aide pour renouveler votre abonnement.

### Vérifier la date d'expiration de l'abonnement {#check-when-subscription-expires}

15 jours avant l'expiration d'un abonnement, une bannière affichant la date d'expiration de l'abonnement s'affiche pour les administrateurs dans l'interface utilisateur GitLab.

Vous ne pouvez pas renouveler manuellement votre abonnement plus de 15 jours avant son expiration. Pour vérifier à quel moment vous pouvez renouveler :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Sélectionnez **Subscription actions** ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Renouveler l'abonnement** pour afficher la date à laquelle vous pouvez renouveler.

### Renouveler automatiquement {#renew-automatically}

Prérequis :

- Pour GitLab Self-Managed, vous devez [synchroniser les données d'abonnement](#subscription-data-synchronization) et vérifier votre compte au moins deux jours avant le renouvellement pour vous assurer que vos modifications sont synchronisées.

Lorsqu'un abonnement est configuré pour le renouvellement automatique, il se renouvelle automatiquement à minuit UTC à la date d'expiration, sans interruption du service disponible. Vous recevez des [notifications par e-mail](#renewal-notifications) avant qu'un abonnement se renouvelle automatiquement.

Le nombre de sièges ne diminue pas automatiquement lors du renouvellement. Si vous avez plus d'utilisateurs facturables que la quantité prévue dans votre abonnement actuel au moment du renouvellement, votre nombre de sièges augmente automatiquement pour correspondre au nombre actuel d'utilisateurs dans votre [groupe](manage_seats.md#view-seat-usage) ou votre [instance](../administration/moderate_users.md#view-users). Pour éviter de renouveler votre abonnement avec plus de sièges que prévu, découvrez comment [renouveler pour un nombre de sièges inférieur](#renew-for-fewer-seats).

Les abonnements achetés via le portail clients sont configurés pour le renouvellement automatique par défaut, mais vous pouvez [désactiver le renouvellement automatique de l'abonnement](#turn-on-or-turn-off-automatic-subscription-renewal).

#### Activer ou désactiver le renouvellement automatique de l'abonnement {#turn-on-or-turn-off-automatic-subscription-renewal}

Vous pouvez utiliser le portail clients pour activer ou désactiver le renouvellement automatique de l'abonnement :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in). Vous accédez à la page **Subscriptions & purchases**.
1. Vérifiez la carte d'abonnement :
   - Si la carte affiche **Expires on DATE**, votre abonnement n'est pas configuré pour le renouvellement automatique. Pour activer le renouvellement automatique, dans **Subscription actions** ({{< icon name="ellipsis_v" >}}), sélectionnez **Turn on auto-renew**.
   - Si la carte affiche **Auto-renews on DATE**, votre abonnement est configuré pour le renouvellement automatique. Pour désactiver le renouvellement automatique :
     1. Dans **Subscription actions** ({{< icon name="ellipsis_v" >}}), sélectionnez **Cancel subscription**.
     1. Sélectionnez un motif d'annulation.
     1. Facultatif. Dans **Would you like to add anything?**, saisissez toute information pertinente.
     1. Sélectionnez **Cancel subscription**.

### Renouveler manuellement {#renew-manually}

Pour renouveler manuellement votre abonnement :

1. Déterminez le nombre d'utilisateurs dont vous aurez besoin au cours de la prochaine période d'abonnement.
1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Sous votre abonnement existant, sélectionnez **Start renewal**. Ce bouton ne s'affiche que 15 jours avant l'expiration de l'abonnement.
1. Si vous renouvelez des produits Premium ou Ultimate, dans la zone de texte **Sièges**, saisissez le nombre total de sièges utilisateur dont vous avez besoin pour l'année à venir.

   > [!note]
   > Assurez-vous que ce nombre est égal ou supérieur au nombre d'[utilisateurs facturables](manage_seats.md#billable-users) dans le système au moment du renouvellement.

1. Facultatif. Pour GitLab Self-Managed, si le nombre maximum d'utilisateurs dans votre instance a dépassé le nombre pour lequel vous avez été licencié lors de la période d'abonnement précédente, le [dépassement](quarterly_reconciliation.md) est dû lors du renouvellement.

   Dans la zone de texte **Users over license**, saisissez le nombre d'[utilisateurs dépassant l'abonnement](manage_seats.md#users-over-subscription-limit) correspondant au dépassement d'utilisateurs constaté.
1. Facultatif. Si vous renouvelez des produits complémentaires, vérifiez et mettez à jour la quantité souhaitée. Vous pouvez également supprimer des produits.
1. Facultatif. Si vous mettez à niveau l'édition d'abonnement, sélectionnez l'option souhaitée.
1. Vérifiez les détails de votre renouvellement et sélectionnez **Renouveler l'abonnement** pour finaliser le processus de paiement.
1. Pour GitLab Self-Managed, sur la page [Subscriptions & purchases](https://customers.gitlab.com/subscriptions), dans la carte d'abonnement concernée, sélectionnez **Copy activation code** pour obtenir une copie du code d'activation de la période de renouvellement, puis [ajoutez le code d'activation](../administration/license.md) à votre instance.

Pour ajouter des produits à votre abonnement, [contactez l'équipe commerciale](https://customers.gitlab.com/contact_us).

### Renouveler pour un nombre de sièges inférieur {#renew-for-fewer-seats}

Les renouvellements d'abonnement avec un nombre de sièges inférieur doivent atteindre ou dépasser le nombre actuel d'utilisateurs facturables.

Avant de renouveler votre abonnement :

- Pour GitLab.com, [réduisez le nombre d'utilisateurs facturables](manage_seats.md#remove-users-from-subscription) s'il dépasse le nombre de sièges pour lequel vous souhaitez renouveler.
- Pour GitLab Self-Managed, [bloquez les utilisateurs inactifs ou indésirables](../administration/moderate_users.md#block-a-user).

Pour renouveler manuellement votre abonnement avec un nombre de sièges inférieur, vous pouvez :

- [Renouveler manuellement](#renew-manually) dans les 15 jours suivant la date de renouvellement de l'abonnement. Assurez-vous de spécifier la quantité de sièges lors du renouvellement.
- [Désactiver le renouvellement automatique de votre abonnement](#turn-on-or-turn-off-automatic-subscription-renewal) et contacter l'[équipe commerciale](https://customers.gitlab.com/contact_us) pour le renouveler avec le nombre de sièges souhaité.

### Notifications de renouvellement {#renewal-notifications}

15 jours avant le renouvellement automatique d'un abonnement, un e-mail contenant des informations sur le renouvellement est envoyé.

- Si votre carte de crédit a expiré, l'e-mail vous indique comment la mettre à jour.
- Si vous avez des dépassements en cours ou si votre abonnement ne peut pas se renouveler automatiquement pour toute autre raison, l'e-mail vous invite à contacter notre équipe commerciale ou à renouveler manuellement dans le portail clients.
- Si tout est en ordre, l'e-mail précise :
  - Les noms et les quantités des produits renouvelés.
  - Le montant total dû. Si votre utilisation augmente avant le renouvellement, ce montant peut changer.

### Gérer la facture de renouvellement {#manage-renewal-invoice}

Une facture est générée pour votre renouvellement. Pour afficher ou télécharger cette facture de renouvellement, accédez à la [page des factures du portail clients](https://customers.gitlab.com/invoices).

Si votre compte dispose d'une [carte de crédit enregistrée](billing_account.md#change-your-payment-method), celle-ci est débitée du montant de la facture.

Si un paiement ne peut pas être traité ou si le renouvellement automatique échoue pour toute autre raison, vous disposez de 14 jours pour renouveler votre abonnement, après quoi votre édition GitLab est rétrogradée.

## Abonnement expiré {#expired-subscription}

Les abonnements expirent au début de la date d'expiration, à 00:00 (heure du serveur).

Par exemple, si un abonnement est valide du 1er janvier 2024 au 1er janvier 2025 :

- Il expire à 23:59:59 UTC le 31 décembre 2024.
- Il est considéré comme expiré à partir de 00:00:00 UTC le 1er janvier 2025.

Si votre abonnement a expiré, vous pouvez toujours le renouveler manuellement dans les 15 jours suivant la date d'expiration. Après 15 jours, l'option de renouvellement manuel n'est plus disponible et vous devez acheter un nouvel abonnement pour rétablir l'accès aux fonctionnalités payantes.

### Pour GitLab.com {#for-gitlabcom-2}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

Lorsque votre abonnement expire, les fonctionnalités payantes ne sont plus disponibles. Vous pouvez cependant continuer à utiliser les fonctionnalités gratuites. Pour rétablir les fonctionnalités payantes, renouvelez votre abonnement.

### Pour GitLab Self-Managed {#for-gitlab-self-managed-2}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Lorsque votre licence expire :

- Votre instance passe en mode lecture seule.
- GitLab verrouille les fonctionnalités, comme les push Git et la création de tickets.
- Un message d'expiration s'affiche pour tous les administrateurs de l'instance.

Après l'expiration de votre licence :

- Pour rétablir les fonctionnalités, [activez un nouvel abonnement](../administration/license_file.md#activate-subscription-during-installation).
- Pour continuer à utiliser uniquement les fonctionnalités de l'édition Gratuite, [supprimez la licence expirée](../administration/license_file.md#remove-a-license).

## Synchronisation des données d'abonnement {#subscription-data-synchronization}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Prérequis :

- GitLab Enterprise Edition (EE).
- Connexion à Internet, sans environnement hors ligne.
- [Activation](../administration/license.md) de votre instance avec un code d'activation.

Vos [données d'abonnement](#subscription-data) sont automatiquement synchronisées une fois par jour entre votre instance GitLab Self-Managed et GitLab.

Aux alentours de 3h00 (UTC), ce job de synchronisation quotidien envoie les [données d'abonnement](#subscription-data) au portail clients. C'est pourquoi les mises à jour et les renouvellements peuvent ne pas s'appliquer immédiatement.

Les données sont envoyées de manière sécurisée via une connexion HTTPS chiffrée vers `customers.gitlab.com` sur le port `443`. Si le job échoue, il réessaie jusqu'à 12 fois sur une période d'environ 17 heures.

Une fois la synchronisation automatique des données configurée, les processus suivants sont également automatisés.

- [Réconciliation trimestrielle de l'abonnement](quarterly_reconciliation.md)
- Renouvellements d'abonnement
- Mises à jour de l'abonnement, telles que l'ajout de sièges supplémentaires ou la mise à niveau d'une édition GitLab

### Synchroniser manuellement les données d'abonnement {#manually-synchronize-subscription-data}

Prérequis :

- Disposer d'un accès administrateur.

Vous pouvez également synchroniser manuellement les données d'abonnement à tout moment.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Abonnement**.
1. Dans la section **Détails de l'abonnement**, sélectionnez **Sync** ({{< icon name="retry" >}}).

Un job de synchronisation est alors mis en file d'attente. Une fois le job terminé, les détails de l'abonnement sont mis à jour.

### Données d'abonnement {#subscription-data}

{{< history >}}

- ID d'instance unique [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189399) dans GitLab 18.1.

{{< /history >}}

Le job de synchronisation quotidien envoie les informations suivantes au portail clients :

- Date
- Horodatage
- Clé de licence, avec les éléments suivants chiffrés dans la clé :
  - Nom de l'entreprise
  - Nom du titulaire de la licence
  - E-mail du titulaire de la licence
- [Nombre maximum d'utilisateurs](manage_seats.md#self-managed-billing-and-usage) historique
- [Nombre d'utilisateurs facturables](manage_seats.md#billable-users)
- Version de GitLab
- Nom d'hôte
- ID d'instance
- ID d'instance unique

De plus, vous obtenez des métriques sur les extensions, telles que :

- Type d'extension
- Sièges achetés
- Sièges attribués

Exemple de requête de synchronisation de licence :

```json
{
  "gitlab_version": "14.1.0-pre",
  "timestamp": "2021-06-14T12:00:09Z",
  "date": "2021-06-14",
  "license_key": "XXX",
  "max_historical_user_count": 75,
  "billable_users_count": 75,
  "hostname": "gitlab.example.com",
  "instance_id": "9367590b-82ad-48cb-9da7-938134c29088",
  "unique_instance_id": "a98bab6e-73e3-5689-a487-1e7b89a56901",
  "add_on_metrics": [
    {
      "add_on_type": "duo_enterprise",
      "purchased_seats": 100,
      "assigned_seats": 50
    }
  ]
}
```

## Associer l'abonnement à un groupe {#link-subscription-to-a-group}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

Prérequis :

- Un espace de nommage de groupe

Un seul espace de nommage de groupe peut être associé à un abonnement.

Si votre abonnement Premium ou Ultimate est associé à un espace de nommage personnel, avant d'associer votre abonnement, vous devez soit :

- [Transférer votre projet](../user/project/working_with_projects.md#transfer-a-project) vers un groupe.
- [Convertir votre espace de nommage personnel en groupe](../tutorials/convert_personal_namespace_to_group/_index.md) pour conserver votre URL existante.

Pour associer votre abonnement à un groupe ou modifier le groupe associé à un abonnement GitLab.com :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in) avec un compte GitLab.com [associé](billing_account.md#link-a-gitlabcom-account).
1. Effectuez l'une des actions suivantes :
   - Si l'abonnement n'est pas associé à un groupe, sélectionnez **Link subscription to a group**.
   - Si l'abonnement est déjà associé à un groupe, sélectionnez **Subscription actions** ({{< icon name="ellipsis_v" >}}) > **Change linked group**.
1. Sélectionnez le groupe souhaité dans la liste déroulante **New Namespace**. Pour qu'un groupe apparaisse ici, vous devez disposer du rôle Propriétaire pour ce groupe.
1. Si le [nombre total d'utilisateurs](manage_seats.md#view-seat-usage) dans votre groupe dépasse le nombre de sièges de votre abonnement, vous êtes invité à payer pour les utilisateurs supplémentaires. Les frais d'abonnement sont calculés sur la base du nombre total d'utilisateurs dans un groupe, y compris ses sous-groupes et projets imbriqués.

   Si vous avez acheté votre abonnement via un revendeur agréé, vous ne pouvez pas payer pour des utilisateurs supplémentaires. Vous pouvez soit :

   - Supprimer les utilisateurs supplémentaires afin qu'aucun dépassement ne soit détecté.
   - Contacter le partenaire pour acheter des sièges supplémentaires maintenant ou à la fin de votre période d'abonnement.

1. Sélectionnez **Confirm changes**.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une démonstration, consultez [Linking GitLab Subscription to the Namespace](https://youtu.be/8iOsN8ajBUw).

## Ajouter ou modifier des contacts d'abonnement {#add-or-change-subscription-contacts}

Les contacts peuvent renouveler un abonnement, annuler un abonnement ou transférer l'abonnement vers un autre espace de nommage.

Vous pouvez [modifier les informations du propriétaire du profil](billing_account.md#change-profile-owner-information) et [ajouter un autre gestionnaire de compte de facturation](billing_account.md#add-a-billing-account-manager).

### Restrictions de transfert {#transfer-restrictions}

Vous pouvez modifier l'espace de nommage associé, mais cette opération n'est pas prise en charge pour tous les types d'abonnement.

Vous ne pouvez pas transférer :

- Un abonnement expiré ou d'essai.
- Un abonnement avec des minutes de calcul déjà associé à un espace de nommage
- Un abonnement avec un forfait Premium ou Ultimate vers un espace de nommage qui dispose déjà d'un forfait Premium ou Ultimate
- Un abonnement avec une extension GitLab Duo vers un espace de nommage qui dispose déjà d'abonnements avec une extension GitLab Duo
- Un abonnement avec un forfait Premium ou Ultimate vers un espace de nommage personnel
- Un abonnement acheté avec un code de réduction
