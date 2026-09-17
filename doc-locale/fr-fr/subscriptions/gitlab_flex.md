---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Comprendre le fonctionnement de GitLab Flex et gérer votre allocation.
title: GitLab Flex
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduit dans GitLab 19.1.

{{< /history >}}

GitLab Flex est un modèle d'achat qui couvre toutes les fonctionnalités GitLab avec un seul engagement. Vous pouvez ajuster l'allocation de vos sièges et crédits mois par mois, sans contrats ni avenants supplémentaires.

Vous vous engagez sur un montant annuel en dollars basé sur vos dépenses GitLab prévisionnelles. Cet engagement crée un solde que vous débitez au fur et à mesure que vous consommez des sièges et des crédits pour les fonctionnalités basées sur des crédits, tarifés selon le [GitLab Rate Card](https://about.gitlab.com/pricing/).

GitLab Flex est également disponible pour les environnements hors ligne.

> [!note]
> Les abonnements GitLab Flex sont régis par leurs propres conditions de facturation pour les sièges et l'utilisation. Les processus de facturation standard pour les utilisateurs en extension et les utilisateurs en dépassement décrits dans le Contrat d'abonnement GitLab ne s'appliquent pas aux achats Flex. Si des conditions Flex sont en conflit avec le Contrat d'abonnement GitLab, les conditions Flex prévalent pour votre achat. Les conditions de facturation standard continuent de s'appliquer aux abonnements non Flex.

Pour une démonstration interactive, consultez [GitLab Flex](https://click-through-demo-generator-v-2-d63870.gitlab.io/demos/flex/).
<!-- Demo published on 2026-07-08 -->

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
  - La réservation est débitée : GitLab débite votre pool de crédits réservés et les modules complémentaires réservés de votre solde Flex total à votre tarif Flex réduit. Le prélèvement réduit votre quantité réservée au tarif remisé. Aucun montant en dollars séparé n'est prélevé sur votre engagement total.
  - Les sièges sont facturés au pic mensuel : GitLab comptabilise le nombre le plus élevé de sièges que vous avez utilisés à tout moment pendant le mois et facture ce nombre. Les sièges au-delà de votre réservation sont facturés à votre tarif par siège et prélevés sur votre solde Flex restant.
  - Le dépassement est calculé : Si votre utilisation mensuelle totale dépasse votre allocation, GitLab facture le montant supplémentaire séparément en début de mois suivant.

En début de mois suivant, une nouvelle réservation est débitée et le cycle de prélèvement recommence avec une nouvelle allocation mensuelle.

## Remises sur volume {#volume-discounts}

Des remises sur volume échelonnées sont automatiquement appliquées en fonction de votre montant d'engagement Flex total. La remise sur volume ne réduit pas la valeur de votre engagement ; les crédits réservés sont débités de votre solde Flex à ce tarif remisé. Plus votre engagement est élevé, plus votre tarif réservé par crédit est bas. Le prix effectif par utilisateur est une composante distincte et est déterminé indépendamment de votre niveau de remise sur volume.

## Acheter GitLab Flex {#buy-gitlab-flex}

GitLab Flex est disponible sous forme d'abonnement annuel récurrent ou pluriannuel, pour des durées annuelles complètes de 12 mois. Pour acheter GitLab Flex, contactez votre équipe de compte GitLab ou l'[équipe commerciale GitLab](https://about.gitlab.com/sales/).

Votre engagement total doit tenir compte des éléments suivants :

- Coûts de base des sièges : Nombre d'utilisateurs × prix de l'édition par siège (Premium ou Ultimate) × 12 mois.
- Utilisation prévue des crédits : Consommation mensuelle estimée pour les fonctionnalités basées sur les crédits × 12 mois.
- Marge de croissance : Capacité supplémentaire pour une expansion en milieu d'année ou l'adoption de nouvelles fonctionnalités.

Des remises sur volume échelonnées sont disponibles et appliquées automatiquement en fonction de la taille de votre engagement total.

Les contrats pluriannuels fonctionnent comme des pools annuels distincts. Cela signifie qu'un solde non utilisé au cours d'une année ne peut pas être reporté à l'année suivante. Pour un contrat pluriannuel, votre engagement total correspond au montant pour une seule année, et non à la somme de toutes les années.

Après avoir signé votre contrat GitLab Flex, vous pouvez commencer à provisionner votre allocation initiale.

## Provisionnement {#provisioning}

Vous pouvez provisionner et modifier votre allocation dans le Portail clients. Si le provisionnement réussit, GitLab envoie une confirmation par e-mail avec les informations d'allocation au contact de l'abonnement (contact « Vendu à »).

- Sur GitLab.com, les modifications sont synchronisées avec l'espace de nommage.
- Sur GitLab Self-Managed et GitLab Dedicated, vous recevez un [code d'activation](../administration/license.md) pour votre instance.

Toutes les réservations futures sont automatiquement synchronisées avec l'espace de nommage ou l'instance utilisé lors de la configuration initiale.

### Allocation de réservation mensuelle {#monthly-reservation-allocation}

Après avoir signé votre accord GitLab Flex, vous pouvez définir votre réservation mensuelle initiale depuis le tableau de bord Flex.

La page de gestion des réservations affiche :

- **Minimum required reservation** : le montant mensuel minimum en dollars fixé dans votre contrat.
- **Maximum reservation** : le montant mensuel maximum en dollars disponible en fonction de votre solde restant.
- **Sièges** : le nombre de sièges à réserver pour le mois.
- **Credits (DAP)** : le nombre de GitLab Credits (Duo Agent Platform) à réserver pour le mois.

### Ajuster votre allocation {#adjust-your-allocation}

Vous pouvez ajuster votre allocation Flex d'un mois à l'autre sans avenant au contrat :

- Nombre de sièges : Augmentez ou diminuez le nombre de sièges.
- Pool de crédits réservés : Augmentez ou diminuez votre réservation mensuelle de crédits à utiliser ou perdre.
- Contrôle des dépenses : Ajustez vos dépenses mensuelles allouées pour les fonctionnalités à l'usage.

Prérequis :

- Vous devez être gestionnaire de compte de facturation.

Pour ajuster votre allocation pour une prochaine période de facturation :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/).
1. Sélectionnez **Tableau de bord Flex**.
1. Sélectionnez la prochaine période de facturation, marquée comme modifiable.
1. Sur la page de gestion des réservations, mettez à jour le nombre de **Sièges** et de **Crédits** (pour Duo Agent Platform).
1. Sélectionnez **Save reservation**.

Après avoir enregistré, un message de réussite confirme la mise à jour. Le tableau de bord Flex affiche les nouveaux montants réservés, qui s'appliquent à partir de la prochaine période de facturation jusqu'à ce que vous les modifiiez à nouveau.

Vous pouvez mettre à jour votre réservation autant de fois que vous le souhaitez avant le début de la prochaine période de facturation. Seule la valeur enregistrée la plus récente prend effet le 1er du mois.

#### Réservation de crédits {#credits-reservation}

Si vous définissez le nombre de **Crédits** pour GitLab Duo Agent Platform sur `0`, aucun crédit n'est réservé pour cette période de facturation. Toute consommation de crédits est prélevée sur votre solde à la demande.

#### Conditions d'ajustement de l'allocation {#allocation-adjustment-conditions}

Les conditions d'ajustement suivantes s'appliquent :

- Les modifications doivent s'inscrire dans votre engagement de départ mensuel. Il s'agit de votre engagement total initial divisé par le nombre de mois dans votre contrat. Par exemple, si votre engagement annuel est de 120 000 $, votre engagement de départ mensuel est de 120 000 $ / 12 = 10 000 $. Chaque mois, les modifications de votre réservation ne doivent pas dépasser 10 000 $. Si vous disposez d'un abonnement de 2 ans, l'engagement de départ mensuel est toujours de 10 000 $, basé sur la durée annuelle de 120 000 $, et non sur le total combiné de 240 000 $ divisé par 24 mois.
- La date limite pour les modifications est l'avant-dernier jour du mois. Vous devez soumettre les modifications avant 23h59 UTC à l'avant-dernier jour du mois en cours pour qu'elles s'appliquent au mois suivant. Par exemple, vous devez soumettre les modifications avant le 30 juillet pour qu'elles s'appliquent au mois d'août. Une fois un mois commencé, la réservation de ce mois est définitive et vous ne pouvez pas la réduire, l'annuler ou la proratiser.
- Les modifications de sièges et de réservation ne prennent effet qu'aux limites de mois. Vous ne pouvez pas modifier votre réservation en cours de mois.
- L'offre est fixe. Vous ne pouvez pas modifier l'offre sélectionnée dans votre contrat.
- La réservation mensuelle minimale est fixe. Vous ne pouvez pas modifier la réservation mensuelle obligatoire fixée dans votre contrat.
- Les changements d'édition de siège nécessitent un avenant au contrat. Si vous souhaitez passer d'une édition Premium à Ultimate ou inversement, contactez votre équipe de compte GitLab. Un changement d'édition prend effet le premier du mois et ne peut pas être appliqué en cours de mois.

#### Dépannage {#troubleshooting}

Les erreurs suivantes empêchent l'enregistrement d'une réservation :

##### Erreur : `Invalid value` {#error-invalid-value}

La quantité de sièges ou de crédits est négative.

Pour résoudre ce problème, saisissez un nombre entier supérieur ou égal à `0`.

##### Erreur : `Seats cannot be zero` {#error-seats-cannot-be-zero}

La quantité de sièges est définie sur `0`.

Pour résoudre ce problème, saisissez un nombre de sièges d'au moins `1`.

##### Erreur : `Below minimum reservation` {#error-below-minimum-reservation}

La valeur totale de la réservation (sièges plus crédits) est inférieure à la réservation minimale requise indiquée en haut de la page.

Pour résoudre ce problème, augmentez le nombre de sièges ou de crédits jusqu'à ce que le total atteigne le minimum.

##### Erreur : `Above maximum reservation` {#error-above-maximum-reservation}

La valeur totale de la réservation (sièges plus crédits) est supérieure à la réservation maximale indiquée en haut de la page.

Pour résoudre ce problème, diminuez le nombre de sièges ou de crédits jusqu'à ce que le total ne dépasse pas le maximum.

## Renouveler GitLab Flex {#renew-gitlab-flex}

Vous pouvez renouveler votre engagement GitLab Flex pour une période d'un an ou pluriannuelle en collaboration avec l'équipe de compte GitLab.

90 jours avant la fin de votre contrat, votre équipe de compte GitLab vous contacte pour entamer les discussions de renouvellement. En fonction de votre consommation depuis le début de l'année, de vos habitudes de dépassement, de vos besoins en capacité et de vos projections de croissance, vous pouvez choisir d'augmenter ou de diminuer votre engagement total. Le nouveau niveau de remise sur volume est basé sur le montant de l'engagement renouvelé.

## Tableau de bord Flex Usage {#flex-usage-dashboard}

Le tableau de bord Flex Usage fournit des fonctionnalités intégrées de suivi et de reporting.

Le tableau de bord affiche :

- **Engagement annuel et solde** : Engagement Flex total, consommation depuis le début de l'année et solde restant.
- **Allocation mensuelle** : Nombre de sièges, crédits réservés et budget à l'usage pour le mois en cours.
- **Utilisation des crédits par fonctionnalité** : Détail des crédits utilisés pour chaque produit basé sur l'utilisation.
- **Utilisation des crédits par projet** : Principaux projets par consommation de crédits.
- **Utilisation des crédits par offre** : Répartition de l'utilisation entre GitLab.com, GitLab Self-Managed, GitLab Dedicated et les environnements hors ligne.
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
- Un produit entre pour la première fois en dépassement pour le mois, facturé au tarif catalogue en déduction de votre engagement total.
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

### Afficher l'utilisation quotidienne par fonctionnalité {#view-daily-usage-by-capability}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/customers-gitlab-com/-/merge_requests/16457) dans GitLab 19.2.

{{< /history >}}

Le tableau de bord GitLab Flex affiche un graphique d'utilisation quotidienne pour chaque fonctionnalité de votre réservation, y compris les sièges. Utilisez ces graphiques pour voir la quantité de chaque fonctionnalité que vous avez consommée chaque jour d'une période de facturation.

Le graphique :

- Affiche l'utilisation cumulée pour chaque jour de la période de facturation.
- Affiche l'utilisation jusqu'à la date actuelle pour la période de facturation en cours.
- Affiche l'intégralité de la période de facturation, ou uniquement les dates au prorata si votre contrat a commencé ou s'est terminé en cours de période.
- Met en évidence en orange toute utilisation supérieure à votre réservation mensuelle, y compris les dépassements de sièges.

Pour afficher l'utilisation quotidienne par fonctionnalité :

1. Connectez-vous au [portail clients](https://customers.gitlab.com/).
1. Sélectionnez **Tableau de bord Flex**.
1. Dans la colonne **Mois**, sélectionnez le mois en cours ou un mois passé.
1. Sélectionnez l'onglet correspondant à la fonctionnalité que vous souhaitez afficher.
