---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Achetez des minutes de calcul supplémentaires pour les espaces de nommage de groupe et personnels sur GitLab.com, avec report mensuel et dépannage."
title: Acheter des minutes de calcul supplémentaires
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

[Les minutes de calcul](../../ci/pipelines/compute_minutes.md) sont la ressource consommée lors de l'exécution de [pipelines CI/CD](../../ci/_index.md) sur les runners d'instance de GitLab.com. Vous pouvez consulter les tarifs des minutes de calcul supplémentaires sur la [page de tarification de GitLab](https://about.gitlab.com/pricing/#compute-minutes).

Les minutes de calcul supplémentaires :

- Ne sont utilisées qu'une fois le quota mensuel inclus dans votre abonnement épuisé.
- Sont [reportées au mois suivant](#monthly-rollover-of-purchased-compute-minutes), si une partie est inutilisée à la fin du mois.
- Sont valables pendant 12 mois à compter de la date d'achat si elles ne sont pas consommées avant.
- L'expiration des minutes de calcul n'est pas encore appliquée, ce qui permet de les utiliser même après la date d'expiration. Toutefois, GitLab ne garantit pas que les minutes de calcul resteront valables après la date d'expiration.
- Celles achetées dans le cadre d'un abonnement d'essai sont disponibles après la fin de la période d'essai ou lors du passage à un plan payant.
- Restent disponibles lorsque vous changez d'édition d'abonnement, y compris lors des changements entre les éditions payantes ou vers l'édition Gratuite.

## Acheter des minutes de calcul pour un groupe {#purchase-compute-minutes-for-a-group}

Vous pouvez acheter des minutes de calcul supplémentaires pour votre groupe. Vous ne pouvez pas transférer des minutes de calcul achetées d'un groupe à un autre, veillez donc à sélectionner le bon groupe.

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe ou être gestionnaire de compte de facturation.
- Le compte de facturation doit être associé à l'abonnement de l'espace de nommage du groupe.

Pour acheter des minutes de calcul pour un groupe :

{{< tabs >}}

{{< tab title="Propriétaire du groupe" >}}

1. Connectez-vous à GitLab.com.
1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Quotas d'utilisation**.
1. Sélectionnez **Pipelines**.
1. Sélectionnez **Acheter des minutes de calcul supplémentaires**. Vous êtes redirigé vers le Portail clients.
1. Dans la section **Détails de l'abonnement**, dans le champ **Quantity**, saisissez la quantité souhaitée de packs de minutes de calcul.
1. Dans la section **Customer information**, vérifiez votre adresse.
1. Dans la section **Billing information**, sélectionnez un moyen de paiement dans la liste déroulante.
1. Cochez la case **Politique de confidentialité** et **Terms of Service**.
1. Sélectionnez **Acheter des minutes de calcul**.

{{< /tab >}}

{{< tab title="Gestionnaire de compte de facturation" >}}

1. Accédez au [Portail clients](https://customers.gitlab.com/customers/sign_in).
1. Sur la carte d'abonnement, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}), puis **Acheter plus de minutes de calcul**.
1. Dans la section **Détails de l'abonnement**, dans le champ **Quantity**, saisissez la quantité souhaitée de packs de minutes de calcul.
1. Dans la section **Customer information**, vérifiez votre adresse.
1. Dans la section **Billing information**, sélectionnez un moyen de paiement dans la liste déroulante.
1. Cochez la case **Politique de confidentialité** et **Terms of Service**.
1. Sélectionnez **Acheter des minutes de calcul**.

{{< /tab >}}

{{< /tabs >}}

Une fois le paiement traité, les minutes de calcul supplémentaires sont ajoutées à l'espace de nommage de votre groupe. Les minutes de calcul supplémentaires s'affichent sous le nom **Minutes de calcul supplémentaires** sur la [page **Quotas d'utilisation**](../../ci/pipelines/instance_runner_compute_minutes.md#view-usage-for-a-group).

## Acheter des minutes de calcul pour un espace de nommage personnel {#purchase-compute-minutes-for-a-personal-namespace}

Pour acheter des minutes de calcul supplémentaires pour votre espace de nommage personnel :

1. Connectez-vous à GitLab.com.
1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Quotas d'utilisation**.
1. Sélectionnez **Acheter des minutes de calcul supplémentaires**. Vous êtes redirigé vers le Portail clients.
1. Dans la section **Détails de l'abonnement**, sélectionnez le nom de l'utilisateur dans la liste déroulante.
1. Saisissez la quantité souhaitée de packs de minutes de calcul.
1. Dans la section **Customer information**, vérifiez votre adresse.
1. Dans la section **Billing information**, sélectionnez un moyen de paiement dans la liste déroulante.
1. Cochez les cases **Politique de confidentialité** et **Terms of Service**.
1. Sélectionnez **Acheter des minutes de calcul**.

Une fois le paiement traité, les minutes de calcul supplémentaires sont ajoutées à votre espace de nommage personnel. Les minutes de calcul supplémentaires s'affichent sous le nom **Minutes de calcul supplémentaires** sur la [page **Quotas d'utilisation**](../../ci/pipelines/instance_runner_compute_minutes.md#view-usage-for-a-personal-namespace).

## Report mensuel des minutes de calcul achetées {#monthly-rollover-of-purchased-compute-minutes}

Si vous achetez des minutes de calcul supplémentaires et n'utilisez pas la totalité du montant, le montant restant est reporté au mois suivant. Les minutes de calcul supplémentaires constituent un achat unique et ne se renouvellent pas chaque mois.

Par exemple, si vous disposez d'un quota mensuel de 10 000 minutes de calcul :

- Le 1er avril, vous achetez 5 000 minutes de calcul supplémentaires, ce qui vous donne 15 000 minutes disponibles pour avril.
- Durant le mois d'avril, vous utilisez 13 000 minutes, soit 3 000 des 5 000 minutes de calcul supplémentaires.
- Le 1er mai, [le quota mensuel est réinitialisé](../../ci/pipelines/instance_runner_compute_minutes.md#monthly-reset) et les minutes de calcul inutilisées sont reportées. Vous disposez donc de 2 000 minutes de calcul supplémentaires restantes, soit un total de 12 000 minutes disponibles pour mai.

## Dépannage {#troubleshooting}

### Erreur : `Last name can't be blank` {#error-last-name-cant-be-blank}

Vous pouvez obtenir l'erreur « Last name can't be blank » lors de l'achat de minutes de calcul. Ce problème survient lorsqu'un nom de famille est absent du champ **Nom complet** de votre profil.

Pour résoudre le problème :

- Assurez-vous que votre profil utilisateur comporte un nom de famille :

  1. Dans le coin supérieur droit, sélectionnez votre avatar.
  1. Sélectionnez **Modifier le profil**.
  1. Mettez à jour le champ **Nom complet** pour qu'il contienne à la fois le prénom et le nom de famille, puis enregistrez les modifications.

- Videz le cache et les cookies de votre navigateur, puis recommencez le processus d'achat.
- Si l'erreur persiste, essayez d'utiliser un autre navigateur web ou une fenêtre de navigation privée/incognito.

### Erreur : `Attempt_Exceed_Limitation - Attempt exceed the limitation, refresh page to try again` {#error-attempt_exceed_limitation---attempt-exceed-the-limitation-refresh-page-to-try-again}

Vous pouvez obtenir l'erreur `Attempt_Exceed_Limitation - Attempt exceed the limitation, refresh page to try again.` lors de l'achat de minutes de calcul.

Ce problème survient lorsque le formulaire de carte de crédit est soumis à nouveau trop rapidement (trois soumissions en une minute ou six soumissions en une heure).

Pour résoudre ce problème, attendez quelques minutes et recommencez le processus d'achat.
