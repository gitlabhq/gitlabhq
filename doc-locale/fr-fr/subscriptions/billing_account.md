---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Modifiez les données de compte de facturation et les modes de paiement, payez les factures et associez votre compte GitLab dans le Portail clients."
title: Gérer le compte de facturation
---

Le Portail clients est votre hub de libre-service complet pour [gérer les abonnements GitLab](manage_subscription.md) et la facturation. Vous pouvez acheter des produits GitLab, gérer vos abonnements tout au long du cycle de vie de l'abonnement, consulter et payer les factures, et accéder à vos informations de facturation et coordonnées.

Si vous avez effectué votre achat via un revendeur agréé, vous devez le contacter directement pour apporter des modifications à votre abonnement. Pour plus d'informations, voir [les clients ayant effectué leur achat via un revendeur](#subscription-purchased-through-a-reseller).

## Se connecter au Portail clients {#sign-in-to-customers-portal}

Vous pouvez vous connecter au Portail clients avec votre compte GitLab.com ou via un lien de connexion à usage unique envoyé à votre adresse e-mail (si vous n'avez pas encore [associé votre compte Portail clients à votre compte GitLab.com](#link-a-gitlabcom-account)).

> [!note]
> Si vous vous êtes inscrit au Portail clients avec votre compte GitLab.com, connectez-vous avec ce compte.

Pour vous connecter au Portail clients avec votre compte GitLab.com :

1. Accédez au [Portail clients](https://customers.gitlab.com/customers/sign_in).
1. Sélectionnez **Continue with GitLab.com account**.

Pour vous connecter au Portail clients avec votre adresse e-mail et recevoir un lien de connexion à usage unique :

1. Accédez au [Portail clients](https://customers.gitlab.com/customers/sign_in).
1. Sélectionnez **Sign in with your email**.
1. Saisissez le **Courriel** associé à votre profil Portail clients. Vous recevrez un e-mail contenant un lien de connexion à usage unique.
1. Dans l'e-mail reçu, sélectionnez **Connexion**.

> [!note]
> Le lien de connexion à usage unique expire dans 24 heures et ne peut être utilisé qu'une seule fois.

## Confirmer l'adresse e-mail du Portail clients {#confirm-customers-portal-email-address}

La première fois que vous vous connectez au Portail clients avec un lien de connexion à usage unique, vous devez confirmer votre adresse e-mail pour conserver l'accès au Portail clients. Si vous vous connectez au Portail clients via GitLab.com, vous n'avez pas besoin de confirmer votre adresse e-mail.

Vous devez également confirmer toute mise à jour de l'adresse e-mail du profil. Vous recevrez un e-mail automatique contenant des instructions sur la marche à suivre pour confirmer, que vous pouvez [renvoyer](https://customers.gitlab.com/customers/confirmation/new) si nécessaire.

## Modifier les informations du propriétaire du profil {#change-profile-owner-information}

L'adresse e-mail du propriétaire du profil est utilisée pour la [connexion héritée au Portail clients](#sign-in-to-customers-portal). Si le propriétaire du profil est également un [gestionnaire de compte de facturation](#subscription-and-billing-contacts), ses coordonnées personnelles sont utilisées sur les factures et dans les e-mails relatifs aux licences et aux abonnements.

Pour modifier les détails du profil, notamment le nom et l'adresse e-mail :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Sélectionnez **My profile** > **Profile settings**.
1. Modifiez **Your personal details**.
1. Sélectionnez **Enregistrer les modifications**.

## Modifier les détails de votre entreprise {#change-your-company-details}

Pour modifier les détails de votre entreprise, notamment le nom de l'entreprise et l'identifiant fiscal :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Sélectionnez **Billing account settings**.
1. Faites défiler jusqu'à la section **Company information**.
1. Modifiez les détails de l'entreprise.
1. Sélectionnez **Enregistrer les modifications**.

## Contacts d'abonnement et de facturation {#subscription-and-billing-contacts}

Les utilisateurs impliqués dans la gestion des abonnements peuvent avoir trois rôles distincts avec des niveaux de permissions et de visibilité variables sur l'abonnement :

- Gestionnaire de compte de facturation : a accès pour consulter et modifier les abonnements, les modes de paiement et les paramètres du compte de facturation. Peut payer et télécharger des factures, et mettre à jour le contact d'abonnement vers n'importe quel gestionnaire de compte de facturation répertorié.
- Contact d'abonnement (ou contact « Vendu à ») : le propriétaire de l'abonnement et le contact principal de votre compte de facturation. Reçoit les notifications relatives aux événements d'abonnement et les informations sur l'application de l'abonnement. Ce rôle est également gestionnaire de compte de facturation par défaut.
- Contact de facturation (ou contact « Facturé à ») : reçoit toutes les factures et les notifications relatives aux événements d'abonnement. Ne dispose pas d'un compte Portail clients avec accès à l'abonnement, sauf si ce rôle est également gestionnaire de compte de facturation.

Un utilisateur peut avoir les trois rôles à la fois.

### Modifier votre contact d'abonnement {#change-your-subscription-contact}

Pour modifier le contact d'abonnement :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Dans la barre latérale gauche, sélectionnez **Billing account settings**.
1. Faites défiler jusqu'à la section **Company information**, puis jusqu'à **Subscription contact**.
1. Pour sélectionner un autre contact d'abonnement, choisissez-en un dans la liste déroulante **Billing account manager**.
1. Modifiez les coordonnées du contact.
1. Sélectionnez **Enregistrer les modifications**.

### Ajouter un gestionnaire de compte de facturation {#add-a-billing-account-manager}

Pour ajouter un autre gestionnaire de compte de facturation à votre compte :

1. Assurez-vous qu'un compte existe dans le [Portail clients](https://customers.gitlab.com/customers/sign_in) pour l'utilisateur que vous souhaitez ajouter.
1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Dans la barre latérale gauche, sélectionnez **Billing account settings**.
1. Faites défiler jusqu'à la section **Billing account managers**.
1. Sélectionnez **Invite billing account manager**.
1. Saisissez l'adresse e-mail de l'utilisateur que vous souhaitez ajouter.
1. Sélectionnez **Inviter**.

L'utilisateur invité reçoit un e-mail contenant une invitation au Portail clients. L'invitation est valable sept jours. Si l'utilisateur n'accepte pas l'invitation avant son expiration, vous pouvez lui envoyer une nouvelle invitation. Vous pouvez avoir au maximum 15 invitations en attente à la fois.

### Supprimer un gestionnaire de compte de facturation {#remove-a-billing-account-manager}

Vous pouvez supprimer des gestionnaires de compte de facturation de votre compte à tout moment. Après avoir supprimé un gestionnaire de compte de facturation, celui-ci n'a plus accès pour consulter ou modifier les informations de votre compte de facturation.

Pour supprimer un gestionnaire de compte de facturation :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Dans la barre latérale gauche, sélectionnez **Billing account settings**.
1. Faites défiler jusqu'à la section **Billing account managers**.
1. Dans la liste, en regard du gestionnaire de compte de facturation que vous souhaitez supprimer, sélectionnez **Supprimer**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Supprimer** pour confirmer l'action.

### Révoquer une invitation de gestionnaire de compte de facturation {#revoke-a-billing-account-manager-invitation}

Vous pouvez révoquer les invitations qui n'ont pas encore été acceptées. Les utilisateurs qui ont été invités mais n'ont pas encore accepté l'invitation affichent le nom **Awaiting user registration**.

Pour révoquer une invitation :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Dans la barre latérale gauche, sélectionnez **Billing account settings**.
1. Faites défiler jusqu'à la section **Billing account managers**.
1. Dans la liste, en regard de l'utilisateur invité portant le nom **Awaiting user registration**, sélectionnez **Supprimer**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Supprimer** pour révoquer l'invitation.

### Modifier votre contact de facturation {#change-your-billing-contact}

Le contact de facturation reçoit toutes les factures et les notifications relatives aux événements d'abonnement.

Pour modifier le contact de facturation :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Dans la barre latérale gauche, sélectionnez **Billing account settings**.
1. Faites défiler jusqu'à la section **Company information**, puis jusqu'à **Billing contact**.

   - Pour remplacer votre contact de facturation par votre contact d'abonnement :

     1. Sélectionnez **Billing contact is the same as subscription contact**.
     1. Sélectionnez **Enregistrer les modifications**.

   - Pour remplacer votre contact de facturation par un autre gestionnaire de compte de facturation :

     1. Décochez la case **Billing contact is the same as subscription contact**.
     1. Sélectionnez un autre gestionnaire de compte de facturation dans la liste déroulante **Utilisateur ou utilisatrice**.
     1. Modifiez les coordonnées du contact.
     1. Sélectionnez **Enregistrer les modifications**.

   - Pour remplacer votre contact de facturation par un contact personnalisé :

     1. Décochez la case **Billing contact is the same as subscription contact**.
     1. Sélectionnez **Enter a custom contact** dans la liste déroulante **Utilisateur ou utilisatrice**.
     1. Saisissez les coordonnées du contact.
     1. Sélectionnez **Enregistrer les modifications**.

## Modifier votre mode de paiement {#change-your-payment-method}

Les achats dans le Portail clients nécessitent l'enregistrement d'une carte bancaire comme mode de paiement. Vous pouvez ajouter plusieurs cartes bancaires à votre compte, afin que les achats de différents produits soient débités sur la bonne carte.

Si vous souhaitez utiliser un autre mode de paiement, [contactez notre équipe commerciale](https://customers.gitlab.com/contact_us).

Pour modifier votre mode de paiement :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Dans la barre latérale gauche, sélectionnez **Billing account settings**.
1. **Éditer** les informations d'un mode de paiement existant ou **Add new payment method**.
1. Sélectionnez **Enregistrer les modifications**.

### Définir un mode de paiement par défaut {#set-a-default-payment-method}

Le renouvellement automatique d'un abonnement est débité sur votre mode de paiement par défaut. Pour définir un mode de paiement par défaut :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Dans la barre latérale gauche, sélectionnez **Billing account settings**.
1. **Éditer** le mode de paiement sélectionné et cochez la case **Make default payment method**.
1. Sélectionnez **Enregistrer les modifications**.

### Supprimer un mode de paiement par défaut {#delete-a-default-payment-method}

Vous ne pouvez pas supprimer votre mode de paiement par défaut directement via le Portail clients. Pour supprimer un mode de paiement par défaut, [contactez notre équipe de facturation](https://customers.gitlab.com/contact_us) pour obtenir de l'aide.

## Payer une facture {#pay-for-an-invoice}

Vous pouvez payer vos factures dans le Portail clients avec une carte bancaire.

Pour payer une facture :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Dans la barre latérale gauche, sélectionnez **Invoices**.
1. Sur la facture que vous souhaitez payer, sélectionnez **Pay for invoice**.
1. Remplissez le formulaire de paiement.

Si vous souhaitez utiliser un autre mode de paiement, [contactez notre équipe de facturation](https://customers.gitlab.com/contact_us#contact-billing-team).

## Associer un compte GitLab.com {#link-a-gitlabcom-account}

Suivez ce guide si vous disposez d'un profil Portail clients hérité pour vous connecter.

Pour associer un compte GitLab.com à votre profil Portail clients :

1. Déclenchez l'envoi d'un lien de connexion à usage unique à votre adresse e-mail depuis votre compte [Portail clients](https://customers.gitlab.com/customers/sign_in?legacy=true).
1. Recherchez l'e-mail et sélectionnez le lien de connexion à usage unique pour vous connecter à votre compte Portail clients.
1. Sélectionnez **My profile** > **Profile settings**.
1. Sous **Your GitLab.com account**, sélectionnez **Link account**.
1. Connectez-vous au compte [GitLab.com](https://gitlab.com/users/sign_in) que vous souhaitez associer au profil Portail clients.

## Modifier le compte associé {#change-the-linked-account}

Si vous souhaitez associer votre compte Portail clients à un autre compte GitLab.com, vous devez utiliser votre compte GitLab.com pour vous inscrire et créer un nouveau profil Portail clients.

Si vous souhaitez modifier les contacts d'abonnement, vous pouvez plutôt effectuer l'une des actions suivantes :

- [Modifier le contact de facturation](#change-your-billing-contact).
- [Modifier le contact d'abonnement](#change-your-subscription-contact).

Si vous disposez d'un profil Portail clients hérité qui n'est pas associé à un compte GitLab.com, vous pouvez toujours vous [connecter](https://customers.gitlab.com/customers/sign_in?legacy=true) à l'aide d'un lien de connexion à usage unique envoyé à votre adresse e-mail. Toutefois, vous devriez [créer](https://gitlab.com/users/sign_up) et [associer un compte GitLab.com](#change-the-linked-account) pour garantir un accès continu au Portail clients.

Pour modifier le compte GitLab.com associé à votre profil Portail clients :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Dans un onglet de navigateur séparé, accédez à [GitLab.com](https://gitlab.com/users/sign_in) et assurez-vous que vous n'êtes pas connecté.
1. Sur la page du Portail clients, sélectionnez **My profile** > **Profile settings**.
1. Sous **Your GitLab.com account**, sélectionnez **Change linked account**.
1. Connectez-vous au compte [GitLab.com](https://gitlab.com/users/sign_in) que vous souhaitez associer au profil Portail clients.

## Transférer la propriété de l'abonnement {#transfer-subscription-ownership}

Vous pouvez transférer la propriété de l'abonnement dans le Portail clients vers ou depuis un contact.

### Vers un nouveau gestionnaire de compte de facturation {#to-a-new-billing-account-manager}

Pour transférer la propriété de l'abonnement à un contact qui n'est pas répertorié comme gestionnaire de compte de facturation :

1. Invitez le contact en tant que gestionnaire de compte de facturation.
1. Une fois que le contact a accepté l'invitation, modifiez le contact d'abonnement en désignant le nouveau gestionnaire de compte de facturation.

### Vers un nouveau contact d'abonnement {#to-a-new-subscription-contact}

Si vous êtes le contact d'abonnement actuel et souhaitez transférer la propriété à une autre personne qui ne dispose pas de compte Portail clients :

1. Remplacez les informations du propriétaire de votre profil par les coordonnées du nouveau contact.
1. Demandez au nouveau contact de se connecter au Portail clients avec son adresse e-mail à l'aide d'un lien de connexion à usage unique.
1. Demandez au nouveau contact de remplacer le compte GitLab.com associé par son propre compte GitLab.com.

### Depuis un contact qui a quitté l'organisation {#from-a-contact-who-has-left-the-organization}

Si vous avez accès à la boîte de réception e-mail du contact d'abonnement :

1. Connectez-vous au Portail clients avec l'adresse e-mail du contact d'abonnement à l'aide d'un lien de connexion à usage unique.
1. Remplacez les informations du contact d'abonnement par vos propres coordonnées.
1. Remplacez le compte associé par votre compte GitLab.com.

Si vous n'avez pas accès à la boîte de réception e-mail du contact d'abonnement, [contactez le Support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) pour demander le transfert de la propriété de l'abonnement. Vous devez fournir une preuve de propriété pour que le Support puisse traiter votre demande.

Vous pouvez utiliser le modèle suivant pour la demande de Support :

```plaintext
Hi Support,

Please update subscription ownership for my subscription/billing account. I confirm that I am not able to make this change in the Customers Portal. Here are the relevant details:

- Old subscription contact's email address:
- New subscription contact's email address:
- (Optional) Subscription or Billing account name:
- Proof of ownership:
```

## Identifiant fiscal pour les clients non américains {#tax-id-for-non-us-customers}

Un identifiant fiscal est un numéro unique attribué par les autorités fiscales aux entreprises enregistrées pour la taxe sur la valeur ajoutée (TVA), la taxe sur les produits et services (TPS) ou des taxes indirectes similaires.

La fourniture d'un identifiant fiscal valide peut réduire votre charge fiscale en nous permettant d'appliquer des mécanismes d'autoliquidation au lieu de facturer la TVA/TPS sur vos factures. Sans identifiant fiscal valide, les taux de TVA/TPS applicables sont déterminés en fonction de votre localisation.

Si votre entreprise n'est pas enregistrée pour les taxes indirectes (en raison de seuils de taille ou d'autres raisons), GitLab applique le taux de TVA/TPS standard conformément aux réglementations locales.

Pour les formats d'identifiants fiscaux détaillés par pays et des informations supplémentaires, consultez notre [guide de référence complet sur les identifiants fiscaux](https://handbook.gitlab.com/handbook/finance/tax/#frequently-asked-questions---tax-id-for-non-us-customers).

## Dépannage {#troubleshooting}

Si vous rencontrez des problèmes ou avez des questions concernant votre abonnement GitLab, visitez la page [Nous contacter](https://customers.gitlab.com/contact_us). Accédez aux ressources, services et options de contact des équipes commerciales, de facturation et de support pour obtenir rapidement l'aide dont vous avez besoin.

### Abonnement acheté via un revendeur {#subscription-purchased-through-a-reseller}

Si vous avez acheté un abonnement via un revendeur agréé (y compris les marketplaces GCP et AWS), vous avez accès au Portail clients pour :

- Consulter votre abonnement.
- Associer votre abonnement au groupe concerné (GitLab.com) ou télécharger la licence (GitLab Self-Managed).
- Gérer les informations de contact.

Les autres modifications et demandes doivent être effectuées via le revendeur, notamment :

- Les modifications apportées à l'abonnement
- L'achat de sièges supplémentaires, de stockage ou de capacité de calcul
- Les demandes de factures, car celles-ci sont émises par le revendeur et non par GitLab

Les revendeurs n'ont pas accès au Portail clients ni aux comptes de leurs clients.

Une fois votre commande d'abonnement traitée, vous recevrez plusieurs e-mails :

- Un e-mail « Bienvenue dans le Portail clients », incluant des instructions sur la procédure de connexion
- Un e-mail de confirmation d'achat contenant des instructions sur la manière de provisionner l'accès

### Les noms des contacts de facturation et d'abonnement ne correspondent pas {#billing-and-subscription-contacts-names-dont-match}

Si l'adresse e-mail du gestionnaire de compte de facturation est associée à des contacts portant des prénoms ou noms de famille différents, vous serez invité à mettre à jour le nom.

Si vous êtes le gestionnaire de compte de facturation, suivez les instructions pour [mettre à jour votre profil personnel](#change-profile-owner-information).

Si vous n'êtes pas le gestionnaire de compte de facturation, notifiez-le afin qu'il mette à jour son profil personnel.

### Le contact d'abonnement n'est plus gestionnaire de compte {#subscription-contact-is-no-longer-account-manager}

Si le contact d'abonnement n'est plus gestionnaire de compte de facturation, vous serez invité à sélectionner un nouveau contact. Suivez les instructions pour [modifier votre contact d'abonnement](#change-your-subscription-contact).

### Erreur : `Email has already been taken` {#error-email-has-already-been-taken}

Si l'adresse e-mail avec laquelle vous souhaitez vous inscrire est déjà utilisée dans le Portail clients, vous pouvez :

- Fournir une autre adresse e-mail.
- Transférer la propriété de l'abonnement.
