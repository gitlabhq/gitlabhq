---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Comprendre le fonctionnement de GitLab Flex et gérer votre allocation.
title: GitLab Flex
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduit dans GitLab 19.1.

{{< /history >}}

GitLab Flex est un modèle d'achat qui offre un engagement annuel unique en dollars couvrant toutes les fonctionnalités de GitLab. Vous pouvez ajuster votre allocation de sièges et vos GitLab Credits d'un mois à l'autre, sans contrats ni avenants supplémentaires.

Avec GitLab Flex, vous vous engagez sur un montant annuel en dollars basé sur votre dépense GitLab projetée. Cet engagement crée un solde annuel que vous consommez au fur et à mesure que vous utilisez des sièges et des crédits pour les fonctionnalités basées sur les crédits, tarifés selon le [GitLab Rate Card](https://about.gitlab.com/pricing/).

GitLab Flex est également disponible pour les environnements hors ligne.

> [!note]
> Les abonnements GitLab Flex sont régis par leurs propres conditions de facturation pour les sièges et l'utilisation. Les processus de facturation standard pour les utilisateurs en extension et les utilisateurs en dépassement décrits dans le Contrat d'abonnement GitLab ne s'appliquent pas aux achats Flex. Si des conditions Flex sont en conflit avec le Contrat d'abonnement GitLab, les conditions Flex prévalent pour votre achat. Les conditions de facturation standard continuent de s'appliquer aux abonnements non Flex.

## Offres {#offerings}

| | GitLab.com | GitLab Self-Managed | GitLab Dedicated | Environnements hors ligne |
|---|---|---|---|---|
| **Mesure** | L'utilisation des crédits est suivie et débitée quotidiennement. | L'utilisation des crédits est synchronisée avec les serveurs GitLab quotidiennement. | L'utilisation des crédits est suivie par GitLab. | L'utilisation des crédits est suivie localement et signalée deux fois par an. |
| **Provisionnement** | Est instantané, les modifications s'appliquent en quelques minutes. | Nécessite l'activation des licences cloud sur votre instance. | Nécessite une coordination avec votre équipe de compte GitLab. | GitLab génère et livre les fichiers de licence. |
| **Facturation** | Les réservations sont débitées en début de mois. Les débits à l'usage et les dépassements sont prélevés au fur et à mesure de la consommation. | Les réservations sont débitées en début de mois. Les débits à l'usage et les dépassements sont prélevés au fur et à mesure de la consommation. | Les réservations sont débitées en début de mois. Les débits à l'usage et les dépassements sont prélevés au fur et à mesure de la consommation. <sup>1</sup> | Les réservations sont débitées en début de mois. L'utilisation réelle est rapprochée deux fois par an via le [true-up](quarterly_reconciliation.md#annual-true-up). |
| **Gestion des dépassements** | Facturé automatiquement chaque mois au moyen de paiement enregistré, ou sinon facturé conformément à vos conditions de paiement applicables. | Facturé automatiquement chaque mois au moyen de paiement enregistré, ou sinon facturé conformément à vos conditions de paiement applicables. | Facturé automatiquement chaque mois au moyen de paiement enregistré, ou sinon facturé conformément à vos conditions de paiement applicables. | Facturé deux fois par an en fonction de l'utilisation déclarée. |

**Remarques :**

1. Les frais d'administration et le stockage sont facturés séparément et ne sont pas prélevés sur votre engagement GitLab Flex.

## Cycle de prélèvement mensuel {#monthly-drawdown-cycle}

GitLab Flex fonctionne sur un cycle de prélèvement mensuel basé sur le mois calendaire.

- Début du mois

  - Le nombre de sièges est défini : GitLab définit votre nombre de sièges réservés pour le mois et ne facture les sièges qu'en fin de mois.
  - Les fonctionnalités deviennent actives : GitLab active toutes les fonctionnalités que vous avez provisionnées pour le mois.
  - Les crédits réservés deviennent disponibles : Votre organisation peut commencer à utiliser votre pool de crédits mensuel.
  - Le dépassement du mois précédent est facturé : Tout dépassement du mois précédent est facturé.

- Pendant le mois

  - L'utilisation est suivie : GitLab mesure votre consommation de crédits en temps réel pour les produits basés sur l'utilisation.
  - Les crédits réservés sont consommés en premier : Votre utilisation est d'abord prélevée sur votre pool réservé mensuel. Une fois le pool épuisé, l'utilisation est prélevée sur votre dépense à la demande (On-Demand).

- Fin du mois

  - Les crédits réservés inutilisés expirent : Vous perdez les crédits que vous n'avez pas utilisés pendant le mois, et ils ne sont pas reportés. GitLab a déjà débité le coût de ces crédits de votre solde en début de mois.
  - La réservation est débitée : GitLab prélève votre pool de crédits réservés et toutes les extensions réservées de votre solde Flex annuel au tarif Flex remisé. Le prélèvement réduit votre quantité réservée au tarif remisé. Il ne prélève pas un montant en dollars distinct sur votre engagement annuel.
  - Les sièges sont facturés au pic mensuel : GitLab comptabilise le nombre le plus élevé de sièges que vous avez utilisés à tout moment pendant le mois et facture ce nombre. Les sièges au-delà de votre réservation sont facturés à votre tarif par siège et prélevés sur votre solde Flex restant.
  - Le dépassement est calculé : Si votre utilisation mensuelle totale dépasse votre allocation, GitLab facture le montant supplémentaire séparément en début de mois suivant.

En début de mois suivant, une nouvelle réservation est débitée et le cycle de prélèvement recommence avec une nouvelle allocation mensuelle.

## Remises sur volume {#volume-discounts}

Des remises sur volume échelonnées sont automatiquement appliquées en fonction de votre montant total d'engagement annuel Flex. La remise sur volume ne réduit pas la valeur de votre engagement ; les crédits réservés sont débités de votre solde Flex à ce tarif remisé. Plus votre engagement annuel est élevé, plus votre tarif réservé par crédit est bas. Le prix effectif par utilisateur est une composante distincte et est déterminé indépendamment de votre niveau de remise sur volume.

## Recharges en cours de période {#mid-term-top-offs}

Vous pouvez augmenter votre engagement annuel à tout moment pendant la durée de votre contrat. Une recharge s'ajoute à votre solde Flex existant sans modifier la date de fin de votre contrat. Votre période continue comme prévu initialement, avec un solde plus important à prélever.

### Provisionnement des recharges {#top-off-provisioning}

Une recharge augmente votre engagement Flex annuel total du montant que vous achetez dans votre bon de commande. GitLab ajoute ce solde à votre engagement annuel total.

Vous pouvez allouer ce montant uniquement à partir du premier jour du mois calendaire suivant. Une recharge ne déclenche aucune modification en cours de mois de votre réservation actuelle. L'allocation du mois en cours reste verrouillée telle que provisionnée.

### Mises à niveau du niveau de remise suite à des recharges {#discount-tier-upgrades-from-top-offs}

Si votre recharge fait passer votre engagement annuel total dans un niveau de remise sur volume supérieur, vous bénéficiez du meilleur tarif à partir du premier jour du mois calendaire suivant. Le tarif mis à niveau s'applique à l'intégralité de votre engagement annuel restant, pas seulement au montant de la recharge. Le tarif mis à niveau ne s'applique pas rétroactivement au mois en cours ni aux mois précédents.

Par exemple, votre engagement initial est de 90 000 $. Une recharge en cours de période porte votre total à 120 000 $ et vous place dans le niveau de remise suivant. À partir du premier du mois suivant, vos crédits et sièges vont plus loin avec le nouveau tarif. La réservation du mois en cours continue au tarif du niveau d'origine.

### Calendrier des recharges {#top-off-timing}

Vous pouvez demander une recharge n'importe quel jour ouvrable du mois. Une fois la recharge ajoutée, vous ne pouvez pas modifier les réservations mensuelles existantes pour le mois en cours. Pendant le mois en cours, vous pouvez prélever le solde de la recharge pour compenser une utilisation qui dépasserait autrement votre budget annuel à l'usage. Cela évite une facture de dépassement.

### Demandes de recharge {#top-off-requests}

Pour demander une recharge, contactez votre équipe de compte GitLab. Elle peut confirmer le nouveau total de l'engagement et le niveau de remise applicable, puis émettre un avenant de bon de commande en cours de période reflétant l'engagement annuel mis à jour et le solde du contrat.

## Acheter GitLab Flex {#buy-gitlab-flex}

GitLab Flex est disponible sous forme d'abonnement annuel récurrent ou pluriannuel. Pour acheter GitLab Flex, contactez votre équipe de compte GitLab ou l'[équipe commerciale GitLab](https://about.gitlab.com/sales/).

Votre engagement annuel doit tenir compte des éléments suivants :

- Coûts de base des sièges : Nombre d'utilisateurs × prix de l'édition par siège (Premium ou Ultimate) × 12 mois.
- Utilisation prévue des crédits : Consommation mensuelle estimée pour les fonctionnalités basées sur les crédits × 12 mois.
- Marge de croissance : Capacité supplémentaire pour une expansion en milieu d'année ou l'adoption de nouvelles fonctionnalités.

Des remises sur volume échelonnées sont disponibles et automatiquement appliquées en fonction de la taille totale de votre engagement annuel.

Après avoir signé votre contrat GitLab Flex, vous pouvez commencer à provisionner votre allocation initiale.

## Provisionnement {#provisioning}

Vous pouvez provisionner et modifier votre allocation dans le Portail clients. Si le provisionnement réussit, GitLab envoie une confirmation par e-mail avec les informations d'allocation au contact de l'abonnement (contact « Vendu à »).

- Sur GitLab.com, les modifications sont synchronisées avec l'espace de nommage.
- Sur GitLab Self-Managed et GitLab Dedicated, vous recevez un [code d'activation](../administration/license.md) pour votre instance.

Toutes les réservations futures sont automatiquement synchronisées avec l'espace de nommage ou l'instance utilisé lors de la configuration initiale.

### Allouer la réservation mensuelle {#allocate-monthly-reservation}

Prérequis :

- Vous devez être gestionnaire de compte de facturation.

1. Connectez-vous au [portail clients](https://customers.gitlab.com/).
1. Sélectionnez **Modifier la réservation mensuelle**.
1. Allouez votre réservation mensuelle entre les sièges et les produits.
1. Vérifiez votre solde Flex annuel.
1. Sélectionnez **Sauvegarder les modifications**.

### Ajuster votre allocation {#adjust-your-allocation}

Vous pouvez ajuster votre allocation Flex d'un mois à l'autre sans avenant au contrat :

- Nombre de sièges : Augmentez ou diminuez le nombre de sièges.
- Pool de crédits réservés : Augmentez ou diminuez votre réservation mensuelle de crédits à utiliser ou perdre.
- Contrôle des dépenses : Ajustez vos dépenses mensuelles allouées pour les fonctionnalités à l'usage.

Pour ajuster votre allocation :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/).
1. Mettez à jour votre allocation pour le mois à venir.
1. Vérifiez les modifications.
1. Sélectionnez **Enregistrer**.

#### Conditions d'ajustement de l'allocation {#allocation-adjustment-conditions}

Les conditions d'ajustement suivantes s'appliquent :

- Les modifications doivent s'inscrire dans le solde restant. Vous ne pouvez pas allouer plus que votre engagement annuel restant.
- La date limite pour les modifications est la fin du mois. Vous devez soumettre les modifications avant 23 h 59 UTC du mois en cours pour qu'elles s'appliquent au mois suivant. Les modifications soumises après la date limite s'appliquent au mois suivant le mois suivant. Une fois un mois commencé, la réservation de ce mois est définitive et vous ne pouvez pas la réduire, l'annuler ou la proratiser.
- Les modifications de sièges et de réservation ne prennent effet qu'aux limites de mois. Vous ne pouvez pas modifier votre réservation en cours de mois.
- L'offre est fixe. Vous ne pouvez pas modifier l'offre sélectionnée dans votre contrat.
- La réservation mensuelle minimale est fixe. Vous ne pouvez pas modifier la réservation mensuelle obligatoire fixée dans votre contrat.
- Les changements d'édition de siège nécessitent un avenant au contrat. Si vous souhaitez passer d'une édition Premium à Ultimate ou inversement, contactez votre équipe de compte GitLab. Un changement d'édition prend effet le premier du mois et ne peut pas être appliqué en cours de mois.

## Renouveler GitLab Flex {#renew-gitlab-flex}

Vous pouvez renouveler votre engagement GitLab Flex pour une période d'un an ou pluriannuelle en collaboration avec l'équipe de compte GitLab.

90 jours avant la fin de votre contrat, votre équipe de compte GitLab vous contacte pour entamer les discussions de renouvellement. Sur la base de votre consommation depuis le début de l'année, de vos habitudes de dépassement, de vos besoins en capacité et de vos projections de croissance, vous pouvez choisir d'augmenter ou de diminuer votre engagement annuel. Le nouveau niveau de remise sur volume est basé sur le montant de l'engagement renouvelé.

## Tableau de bord Flex Usage {#flex-usage-dashboard}

Le tableau de bord Flex Usage fournit des fonctionnalités intégrées de suivi et de reporting.

Le tableau de bord affiche :

- **Engagement annuel et solde** : Engagement Flex total, consommation depuis le début de l'année et solde restant.
- **Allocation mensuelle** : Nombre de sièges, crédits réservés et budget à l'usage pour le mois en cours.
- **Utilisation des crédits par fonctionnalité** : Détail des crédits utilisés pour chaque produit basé sur l'utilisation.
- **Utilisation des crédits par projet** : Principaux projets par consommation de crédits.
- **Utilisation des crédits par offre** : Répartition de l'utilisation entre GitLab.com, GitLab Self-Managed, GitLab Dedicated et les environnements hors ligne.
- **Prévisions par rapport à l'utilisation réelle** : Consommation annuelle projetée comparée au rythme réel.
- **Récapitulatif des dépassements** : Dépassement depuis le début du mois et depuis le début de l'année.

### Contrôles d'utilisation et des dépenses {#usage-and-spend-controls}

Pour vous aider à contrôler le montant de vos dépenses par rapport à votre engagement, vous pouvez définir des plafonds de dépenses (au niveau de l'abonnement) et recevoir des alertes budgétaires.

#### Plafonds de dépenses {#spend-caps}

Les plafonds par fonctionnalité limitent la consommation qu'une fonctionnalité spécifique basée sur les crédits peut effectuer, afin qu'une fonctionnalité ne vide pas le pool partagé. Lorsqu'une fonctionnalité atteint son plafond, son utilisation s'arrête tandis que tout le reste continue de fonctionner. Le plafond est par produit et n'est pas partagé entre le pool.

Utilisez les plafonds par fonctionnalité pour les fonctionnalités non critiques ou expérimentales que vous souhaitez contenir.

Vous pouvez définir les plafonds par fonctionnalité suivants :

- Restreint : Aucun dépassement au-delà de la réservation, bloqué à la réservation. Le plafond de dépenses est égal à la réservation.
- Plafond d'utilisation : Dépassement limité au-delà de la réservation. Le plafond de dépenses correspond à la réservation plus le montant plafonné.
- Illimité : Dépassement illimité au-delà de la réservation. Aucun plafond de dépenses.

Chaque fonctionnalité dispose de son propre plafond indépendant. Par exemple, vous pouvez plafonner GitLab Duo à 5 000 $ tout en laissant Artifact Registry illimité.

#### Notifications d'utilisation {#usage-notifications}

GitLab envoie des e-mails à mesure que l'utilisation approche et dépasse des limites spécifiques, en s'appuyant sur le cadre existant de protection budgétaire. Les contacts de facturation de l'abonnement reçoivent des notifications basées sur les montants en dollars, et les administrateurs d'espace de nommage reçoivent des notifications basées sur les crédits.

GitLab envoie des notifications d'utilisation lorsque :

- Un produit dépasse 50 %, 80 % ou 100 % de sa réservation mensuelle. À 100 %, le produit commence à facturer à l'usage et entre en dépassement.
- Un produit entre pour la première fois en dépassement pour le mois, facturé au tarif catalogue sur votre engagement annuel.
- Un produit plafonné dépasse 50 % ou 80 % de son plafond (notification d'avertissement), ou atteint 100 % et est bloqué (notification de blocage).

### Afficher le tableau de bord Flex Usage {#view-the-flex-usage-dashboard}

Prérequis :

- Vous devez être un administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Flex Usage**.

### Définir un plafond de dépenses {#set-a-spend-cap}

Pour définir un plafond de dépenses par fonctionnalité :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/).
1. Sélectionnez **Tableau de bord Flex**.
1. Sélectionnez un mois pour afficher toutes les fonctionnalités.
1. Dans la ligne de l'extension que vous souhaitez plafonner, dans la liste déroulante **Contrôle des dépenses**, sélectionnez un type de plafond. Si vous saisissez une valeur pour le plafond, elle est convertie en montant en dollars au tarif de ce produit.
1. Vérifiez le récapitulatif de la réservation pour confirmer que les plafonds sont reflétés dans le sous-total et le total de vos extensions.
1. Sélectionnez **Enregistrer**.
