---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisation des sièges, minutes de calcul, limites de stockage, informations de renouvellement."
gitlab_dedicated: yes
title: "Dépannage de l'abonnement GitLab"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous achetez ou utilisez des abonnements GitLab, vous pouvez rencontrer les problèmes suivants.

## Problèmes de paiement et de carte {#payment-and-card-issues}

### Erreur : carte de crédit refusée {#error-credit-card-declined}

Lorsque vous achetez un abonnement GitLab, votre carte de crédit peut être refusée pour les raisons suivantes :

- Les informations de la carte de crédit sont incorrectes. La cause la plus fréquente est une adresse incomplète ou fictive.
- Le compte de carte de crédit ne dispose pas de fonds suffisants.
- La carte de crédit a expiré.
- La transaction dépasse la limite de crédit ou le montant maximum de transaction de la carte.
- La [transaction n'est pas autorisée](#error-transaction_not_allowed).

Vérifiez auprès de votre établissement financier si l'une de ces raisons s'applique. Si aucune ne s'applique, contactez le [support GitLab](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

#### Erreur : `transaction_not_allowed` {#error-transaction_not_allowed}

Lorsque vous achetez un abonnement GitLab, vous pouvez obtenir une erreur indiquant :

```plaintext
Transaction declined.402 - [card_error/card_declined/transaction_not_allowed]
Your card does not support this type of purchase.
```

Cette erreur indique que le type de transaction que vous effectuez est restreint par votre émetteur de carte. Il s'agit d'une mesure de sécurité conçue pour protéger votre compte.

Votre transaction peut être refusée pour une ou plusieurs des raisons suivantes :

- Votre carte a été émise en Inde et la transaction n'est pas conforme aux [règles e-mandat de la RBI](https://www.rbi.org.in/Scripts/NotificationUser.aspx?Id=12051&Mode=0).
- Votre carte n'est pas activée pour les achats en ligne.
- Votre carte a des limitations d'utilisation spécifiques. Par exemple, il s'agit d'une carte de débit limitée aux transactions locales uniquement.
- La transaction déclenche les protocoles de sécurité de votre banque.

Pour résoudre ce problème, essayez les actions suivantes :

- Pour les cartes émises en Inde : traitez votre transaction via un revendeur local agréé. Contactez l'un des partenaires GitLab suivants en Inde :
  - [Datamato Technologies Private Limited](https://about.gitlab.com/partners/channel-partners/#/1345598)
  - [FineShift Software Private Limited](https://about.gitlab.com/partners/channel-partners/#/1737250)
- Pour les cartes émises en dehors des États-Unis : assurez-vous que votre carte est activée pour les utilisations internationales et vérifiez s'il existe des restrictions spécifiques à certains pays.
- Contactez votre établissement financier : demandez la raison pour laquelle votre transaction a été refusée et demandez que votre carte soit activée pour ce type de transaction.

#### Erreur : `Attempt_Exceed_Limitation` {#error-attempt_exceed_limitation}

Lorsque vous achetez un abonnement GitLab, vous pouvez obtenir l'erreur `Attempt_Exceed_Limitation - Attempt exceed the limitation, refresh page to try again.`.

Ce problème survient lorsque le formulaire de carte de crédit est soumis à nouveau trois fois en une minute ou six fois en une heure. Pour résoudre ce problème, attendez quelques minutes et réessayez l'achat.

## Problèmes d'authentification et de compte {#authentication-and-account-issues}

### Erreur : `must be authenticated to make a purchase` {#error-must-be-authenticated-to-make-a-purchase}

Vous pouvez voir cette erreur lorsque vous essayez d'effectuer un achat sans être connecté à votre compte.

Pour résoudre ce problème, connectez-vous à votre compte GitLab avant d'essayer d'acheter un abonnement.

### Erreur : aucun achat répertorié dans le compte du portail clients {#error-no-purchases-listed-in-the-customers-portal-account}

Pour afficher les achats dans le portail clients sur la page **Subscriptions & purchases**, vous devez être ajouté en tant que contact dans votre organisation pour l'abonnement.

Pour être ajouté en tant que contact, [créez un ticket auprès de l'équipe de support GitLab](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

## Problèmes de liaison entre espace de nommage et abonnement {#namespace-and-subscription-linking-issues}

### Erreur : `GitLab namespace is required` {#error-gitlab-namespace-is-required}

Vous pouvez voir cette erreur lorsque l'espace de nommage GitLab n'est pas spécifié pendant le processus d'achat.

Pour résoudre ce problème, assurez-vous de sélectionner un espace de nommage GitLab valide avant de poursuivre votre achat.

### Erreur : `Unable to link subscription to namespace` {#error-unable-to-link-subscription-to-namespace}

Sur GitLab.com, si vous ne pouvez pas lier un abonnement à votre espace de nommage, vous disposez peut-être de permissions insuffisantes. Assurez-vous de disposer du rôle Propriétaire pour cet espace de nommage et consultez les [restrictions de transfert](../manage_subscription.md#transfer-restrictions).

### Erreur : `Subscription not found` {#error-subscription-not-found}

Vous pouvez voir cette erreur lorsque vous essayez de modifier un abonnement qui n'existe pas ou qui est introuvable.

Pour résoudre ce problème :

- Vérifiez que vous utilisez le bon identifiant ou nom d'abonnement.
- Assurez-vous que l'abonnement existe dans votre compte.
- Vérifiez que vous avez accès à l'abonnement que vous essayez de modifier.

Si vous continuez à rencontrer des problèmes, contactez le [support GitLab](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

## Erreurs de validation d'espace de nommage lors de l'achat {#namespace-validation-errors-during-purchase}

Lorsque vous achetez un abonnement GitLab sur GitLab.com, vous pouvez rencontrer des erreurs de validation d'espace de nommage qui vous empêchent de finaliser l'achat.

### Erreur : `GitLab namespace is not valid` {#error-gitlab-namespace-is-not-valid}

Vous pouvez voir cette erreur lorsque l'espace de nommage :

- N'est pas spécifié dans l'URL d'achat.
- N'existe pas sur GitLab.com.
- N'appartient pas à votre compte utilisateur.
- N'est pas un groupe principal (il s'agit d'un sous-groupe ou d'un projet).
- N'a aucun membre facturable.

Pour résoudre ce problème :

- Vérifiez que l'espace de nommage existe et que vous disposez du [rôle Propriétaire](../../user/permissions.md#roles). Si ce n'est pas le cas, demandez à un Propriétaire existant de vous ajouter.
- Assurez-vous que l'espace de nommage est un groupe principal. Les abonnements ne peuvent pas être appliqués à des sous-groupes ou à des projets : appliquez plutôt l'abonnement au groupe parent.
- [Vérifiez que l'espace de nommage compte au moins un utilisateur facturable](../manage_seats.md#billable-users). Ajoutez des membres si nécessaire.
- Vérifiez que l'URL d'achat inclut le paramètre `gl_namespace_id` correct (par exemple, `?gl_namespace_id=123`).

Si vous continuez à rencontrer des problèmes après avoir suivi les étapes ci-dessus, contactez le [support GitLab](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

### Erreur : `Subscription does not belong to GitLab namespace` {#error-subscription-does-not-belong-to-gitlab-namespace}

Vous pouvez voir cette erreur lorsque l'abonnement que vous essayez de modifier n'appartient pas à l'espace de nommage que vous avez spécifié dans l'URL d'achat.

Pour résoudre ce problème :

- Vérifiez que vous utilisez le bon identifiant ou nom d'abonnement.
- Assurez-vous que l'espace de nommage dans l'URL correspond à l'espace de nommage propriétaire de l'abonnement.
- Si vous devez modifier l'espace de nommage auquel un abonnement est lié, consultez les [restrictions de transfert](../manage_subscription.md#transfer-restrictions).

Si vous continuez à rencontrer des problèmes après avoir suivi les étapes ci-dessus, contactez le [support GitLab](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

## Problèmes liés aux produits et aux modules complémentaires {#product-and-add-on-issues}

### Erreur : `Product is required` {#error-product-is-required}

Vous pouvez voir cette erreur lorsque le produit n'est pas spécifié pendant le processus d'achat.

Pour résoudre ce problème, assurez-vous de sélectionner un produit avant de poursuivre votre achat.

### Erreur : `cannot purchase more product through the Customers Portal` {#error-cannot-purchase-more-product-through-the-customers-portal}

Lorsque vous achetez des modules complémentaires d'abonnement (tels que des sièges supplémentaires, des minutes de calcul, du stockage ou GitLab Duo Pro), vous pouvez voir cette erreur.

Ce problème survient lorsque vous avez un abonnement actif qui :

- A été [acheté via un revendeur](../billing_account.md#subscription-purchased-through-a-reseller).
- Est un abonnement pluriannuel.

Pour résoudre ce problème, contactez votre [représentant commercial GitLab](https://customers.gitlab.com/contact_us) pour obtenir de l'aide.

### Erreur : `Product is not available in this purchase flow` {#error-product-is-not-available-in-this-purchase-flow}

Vous pouvez voir cette erreur lorsque le produit que vous essayez d'acheter n'est pas disponible via le flux d'achat en libre-service.

Cela peut se produire parce que :

- Le produit nécessite une configuration ou une approbation spéciale.
- Le produit est uniquement disponible via la vente directe.
- Votre compte ne remplit pas les conditions requises pour ce produit.

Pour résoudre ce problème, contactez votre [représentant commercial GitLab](https://customers.gitlab.com/contact_us) pour obtenir de l'aide avec votre achat.

#### Erreur : `Product is not available for sale through the Customers Portal` {#error-product-is-not-available-for-sale-through-the-customers-portal}

Vous pouvez voir cette erreur lorsque :

- Le plan tarifaire du produit comporte plusieurs frais, qui ne sont pas pris en charge dans le flux d'achat en libre-service.
- Le plan tarifaire du produit n'est pas disponible pour les achats en libre-service.

Pour résoudre ce problème, contactez votre [représentant commercial GitLab](https://customers.gitlab.com/contact_us) pour obtenir de l'aide.

## Problèmes de déploiement et de configuration {#deployment-and-configuration-issues}

### Erreur : `The deployment type of the purchase does not match your subscription's deployment type` {#error-the-deployment-type-of-the-purchase-does-not-match-your-subscriptions-deployment-type}

Vous pouvez voir cette erreur lorsque le type de déploiement que vous avez spécifié ne correspond pas au produit que vous essayez d'acheter.

Pour résoudre ce problème :

- Vérifiez que vous achetez le bon produit pour votre type de déploiement.
  - Les abonnements GitLab.com sont destinés aux déploiements SaaS multi-locataires.
  - Les abonnements GitLab Self-Managed sont destinés aux déploiements sur site ou dans des clouds privés.
- Assurez-vous d'utiliser l'URL d'achat correcte pour votre type de déploiement.
- Si vous avez besoin d'un abonnement pour un autre type de déploiement, démarrez un nouvel achat avec le bon produit.

## Problèmes d'infrastructure et de synchronisation {#infrastructure-and-synchronization-issues}

### Erreur : échec de la synchronisation des données d'abonnement {#error-subscription-data-fails-to-synchronize}

Sur GitLab Self-Managed ou GitLab Dedicated, la synchronisation de vos données d'abonnement peut échouer. Ce problème peut survenir lorsque le trafic réseau entre votre instance GitLab et certaines adresses IP n'est pas autorisé.

Pour résoudre ce problème, autorisez le trafic réseau depuis votre instance GitLab vers les adresses IP `172.64.146.11:443` et `104.18.41.245:443` (`customers.gitlab.com`).

Pour plus d'informations, consultez [le dépannage des problèmes de connectivité](../../administration/license.md#error-cannot-activate-instance-due-to-a-connectivity-issue).
