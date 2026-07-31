---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Comprendre les processus de facturation pour les dépassements de sièges sur votre abonnement GitLab.
title: Facturation pour les dépassements de sièges
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque votre abonnement GitLab compte plus d'utilisateurs facturables que de sièges achetés, vous êtes facturé pour les sièges supplémentaires.

Conformément à [l'accord d'abonnement GitLab](https://about.gitlab.com/terms/), GitLab examine votre utilisation des sièges et vous envoie une facture pour les dépassements, soit trimestriellement (processus de rapprochement trimestriel), soit annuellement (processus de régularisation annuelle).

- **Quarterly reconciliation** : vous êtes facturé par trimestre au prorata pour la portion restante de la durée de l'abonnement. Vous payez pour le nombre maximal de sièges que vous avez utilisés au cours du trimestre. Vous payez moins annuellement, ce qui peut générer des économies substantielles.
- **Annual true-up** : vous payez la totalité des frais d'abonnement annuels pour les utilisateurs ajoutés à tout moment au cours de l'année.

En savoir plus :

- [Comment l'utilisation des sièges est déterminée](manage_seats.md#gitlabcom-billing-and-usage) sur GitLab.com.
- [Comment GitLab facture les utilisateurs](manage_seats.md#self-managed-billing-and-usage) sur GitLab Self-Managed.

Pour éviter les dépassements, vous pouvez activer l'accès restreint pour votre [groupe](../user/group/manage.md#turn-on-restricted-access) ou votre [instance](../administration/settings/sign_up_restrictions.md#turn-on-restricted-access). Ce paramètre empêche les groupes d'ajouter de nouveaux utilisateurs facturables lorsqu'il ne reste plus de sièges dans l'abonnement.

## Exemple {#example}

Par exemple, en janvier, vous avez acheté une licence annuelle pour 100 utilisateurs, où chaque siège supplémentaire coûte 100 $. Tout au long de l'année, le nombre d'utilisateurs a fluctué entre 95 et 120. Cela signifie que, durant l'année, vous avez dépassé la licence de 20 utilisateurs.

Le graphique suivant illustre le nombre d'utilisateurs durant l'année, par mois et par trimestre.

![Graphique à barres indiquant le nombre d'utilisateurs par mois et par trimestre](img/quarterly_reconciliation_v14_7.png)

Si vous êtes facturé trimestriellement :

- Au T1, vous aviez 110 utilisateurs. 10 utilisateurs au-dessus de l'abonnement x 25 $ par utilisateur x 3 trimestres = 750 $. Vous payez désormais une licence pour 110 utilisateurs.
- Au T2, vous aviez 105 utilisateurs. Vous n'avez pas dépassé 110 utilisateurs, vous n'êtes donc pas facturé.
- Au T3, vous aviez 120 utilisateurs. 10 utilisateurs au-dessus de l'abonnement x 25 $ par utilisateur x 1 trimestre restant = 250 $. Vous payez désormais une licence pour 120 utilisateurs.
- Au T4, vous aviez 120 utilisateurs. Vous n'avez pas dépassé le nombre d'utilisateurs du T3, vous n'êtes donc pas facturé. Cependant, même si vous aviez dépassé ce nombre, vous n'auriez pas été facturé, car au T4, il n'y a pas de frais pour le dépassement de nombre.
- Le coût total annuel est de 1 000 $.

Si vous êtes facturé annuellement :

- Pour les sièges supplémentaires, vous payez 100 $ x 20 utilisateurs.
- Le coût total annuel est de 2 000 $.

## Rapprochement trimestriel {#quarterly-reconciliation}

### Éligibilité {#eligibility}

Vous êtes automatiquement inscrit au rapprochement trimestriel si :

- La carte de crédit que vous avez utilisée pour acheter votre abonnement est toujours associée à votre compte GitLab.
- Vous avez acheté votre abonnement par le biais d'une facture.

Vous êtes exclu du rapprochement trimestriel si vous :

- Avez acheté votre abonnement auprès d'un revendeur ou d'un autre partenaire de distribution.
- Avez acheté un abonnement dont la durée n'est pas de 12 mois (inclut les abonnements pluriannuels et de durée non standard).
- Avez acheté votre abonnement avec un bon de commande.
- Avez acheté un produit [Enterprise Agile Planning](manage_seats.md#enterprise-agile-planning).
- Êtes un client du secteur public.
- Disposez d'un environnement hors ligne et avez utilisé un fichier de licence pour activer votre abonnement.
- Êtes inscrit à un programme proposant une édition Gratuite, tel que GitLab for Education, GitLab for Open Source Program ou GitLab for Startups.

Si vous êtes exclu du rapprochement trimestriel et que vous n'utilisez pas une édition Gratuite, vos régularisations sont réconciliées annuellement. Vous pouvez également régulariser tout dépassement en [achetant des sièges supplémentaires](manage_seats.md#buy-more-seats).

### Facturation et paiement {#invoicing-and-payment}

À la fin de chaque trimestre d'abonnement, GitLab vous informe des dépassements. La date à laquelle vous êtes informé du dépassement n'est pas la même que la date à laquelle vous êtes facturé.

1. Un e-mail communiquant la [quantité de sièges en dépassement](manage_seats.md#users-over-subscription-limit) et le montant de la facture prévu est envoyé :

   - Sur GitLab.com : à la date de rapprochement, aux propriétaires de groupe et aux gestionnaires de compte de facturation.
   - Sur GitLab Self-Managed : Six jours après la date de rapprochement, aux gestionnaires de compte de facturation.

1. Sept jours après la notification par e-mail, l'abonnement est mis à jour pour inclure les sièges supplémentaires, et une facture est générée pour un montant au prorata. Si une carte de crédit est enregistrée, le paiement est appliqué automatiquement. Dans le cas contraire, vous recevez une facture, soumise à vos conditions de paiement.

## Régularisation annuelle {#annual-true-up}

La facturation de votre abonnement est par défaut soumise au processus de régularisation annuelle si vous :

- Optez explicitement pour ne pas participer au rapprochement trimestriel par le biais d'un avenant contractuel.
- N'êtes pas éligible au rapprochement trimestriel.

## Dépannage {#troubleshooting}

### Échec de paiement {#failed-payment}

Si votre carte de crédit est refusée lors du processus de rapprochement trimestriel, vous recevez un e-mail avec l'objet `Action required: Your GitLab subscription failed to reconcile`. Pour résoudre ce problème :

1. [Mettez à jour vos informations de paiement](billing_account.md#change-your-payment-method).
1. [Définissez votre méthode de paiement choisie comme méthode par défaut](billing_account.md#set-a-default-payment-method).

Une fois la méthode de paiement mise à jour, le rapprochement est relancé automatiquement.
