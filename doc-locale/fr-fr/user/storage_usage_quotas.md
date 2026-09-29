---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Stockage
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

Les projets GitLab disposent d'une limite de stockage pour leur dépôt Git et leur stockage de fichiers volumineux (LFS). Seuls le dépôt et le LFS du projet sont inclus dans la limite de stockage. Le registre de conteneurs, le registre de paquets et les artefacts de build ne sont pas inclus dans la limite.

Lorsque le dépôt et le LFS d'un projet dépassent la limite, le projet est mis en [état lecture seule](read_only_namespaces.md) et certaines actions deviennent restreintes.

## Limite gratuite {#free-limit}

{{< details >}}

- Édition : Gratuite

{{< /details >}}

Chaque projet dans un espace de nommage de l'édition Gratuite sur GitLab.com dispose de 10 Gio de stockage gratuit.

Pour augmenter le stockage du dépôt et du LFS du projet au-delà de 10 Gio, vous devez acheter du stockage supplémentaire.

## Limite fixe de projet {#fixed-project-limit}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate

{{< /details >}}

Chaque projet dans l'édition GitLab Premium ou GitLab Ultimate sur GitLab.com dispose de 500 Gio de stockage.

Lorsqu'un projet dépasse la limite de stockage, les propriétaires du groupe et de l'espace de nommage de niveau supérieur reçoivent des notifications via l'interface utilisateur et par e-mail.

Pour gérer l'utilisation du stockage, contactez votre équipe de compte ou le support GitLab.

## Stockage expiré {#expired-storage}

Un stockage expiré peut exister lorsque le stockage acheté n'est pas déprovisionné à la fin de votre période d'abonnement. Si vous constatez une baisse inattendue du stockage acheté, le stockage expiré a peut-être été supprimé de votre compte. Pour plus d'informations et de solutions, contactez le support.

## Afficher le stockage {#view-storage}

{{< details >}}

- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez afficher les statistiques suivantes sur l'utilisation du stockage dans les projets et les espaces de nommage :

- Utilisation du stockage dépassant la limite de stockage GitLab.com ou les [limites de stockage GitLab Self-Managed](../administration/settings/account_and_limit_settings.md#repository-size-limit).
- Stockage acheté disponible pour GitLab.com.

Prérequis :

- Pour afficher l'utilisation du stockage pour un projet, vous devez disposer du rôle Mainteneur ou Propriétaire pour le projet, ou du rôle Propriétaire pour l'espace de nommage.
- Pour afficher l'utilisation du stockage pour un espace de nommage de groupe, vous devez disposer du rôle Propriétaire pour l'espace de nommage.

Pour afficher le stockage :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet ou votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Quotas d'utilisation**.
1. Sélectionnez l'onglet **Stockage** pour afficher l'utilisation du stockage de l'espace de nommage.
1. Pour afficher l'utilisation du stockage pour un projet, dans le tableau en bas, sélectionnez un projet. L'utilisation du stockage est mise à jour toutes les 90 minutes.

Si votre espace de nommage affiche `'Not applicable.'`, envoyez un commit vers n'importe quel projet de l'espace de nommage pour recalculer le stockage.

L'utilisation du stockage et du réseau est calculée avec le système de mesure binaire (multiples de 1024 unités). L'utilisation du stockage est affichée en kibioctets (Kio), mébioctets (Mio) ou gibioctets (Gio). 1 Kio correspond à 2<sup>10</sup> octets (1024 octets), 1 Mio correspond à 2<sup>20</sup> octets (1024 kibioctets) et 1 Gio correspond à 2<sup>30</sup> octets (1024 mébioctets).

## Afficher l'utilisation du stockage des duplications de projet {#view-project-fork-storage-usage}

Un facteur de coût est appliqué au stockage consommé par les duplications de projet, de sorte que les duplications consomment moins de stockage d'espace de nommage que leur taille réelle. Les facteurs de coût pour la réduction du stockage des duplications s'appliquent uniquement au stockage de l'espace de nommage. Ils ne s'appliquent pas aux limites de stockage du dépôt de projet.

Pour afficher la quantité de stockage d'espace de nommage utilisée par la duplication :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet ou votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Quotas d'utilisation**.
1. Sélectionnez l'onglet **Stockage**. La colonne **Total** affiche la quantité de stockage d'espace de nommage utilisée par la duplication, exprimée en proportion de la taille réelle de la duplication sur le disque.

Le facteur de coût s'applique au dépôt du projet, aux objets LFS, aux artefacts de job, aux paquets, aux extraits de code et au wiki.

Le facteur de coût ne s'applique pas aux duplications privées dans les espaces de nommage sous le plan Gratuit.

## Utilisation du stockage excédentaire {#excess-storage-usage}

{{< details >}}

- Édition : Gratuite

{{< /details >}}

L'utilisation du stockage excédentaire correspond au montant dépassant les 10 Gio de stockage gratuit du dépôt et du LFS d'un projet. Si aucun stockage acheté n'est disponible, le projet est mis en état lecture seule. Vous ne pouvez pas envoyer de modifications vers un projet en lecture seule.

Pour supprimer l'état lecture seule, vous devez acheter du stockage supplémentaire pour l'espace de nommage. Une fois l'achat effectué, l'état lecture seule est supprimé et les projets sont automatiquement restaurés. La quantité de stockage acheté disponible doit toujours être supérieure à zéro.

L'onglet **Stockage** de la page **Quotas d'utilisation** affiche les informations suivantes :

- Le stockage acheté disponible est presque épuisé.
- Les projets risquant de passer en lecture seule si le stockage acheté disponible est nul.
- Les projets en lecture seule parce que le stockage acheté disponible est nul. Les projets en lecture seule sont marqués d'une icône d'information ({{< icon name="information-o" >}}) à côté de leur nom.

Le stockage total inclut le stockage gratuit et le stockage excédentaire acheté. Le stockage excédentaire restant est exprimé en pourcentage et calculé comme suit : 100 % - ((stockage excédentaire utilisé - stockage excédentaire acheté) × 100).

### Exemple de stockage excédentaire {#excess-storage-example}

L'exemple suivant décrit un scénario de stockage excédentaire pour des projets dans un espace de nommage :

| Dépôt | Stockage utilisé | Stockage excédentaire | Quota  | Statut               |
|------------|--------------|----------------|--------|----------------------|
| Rouge        | 10 Gio        | 0 Gio           | 10 Gio  | Lecture seule {{< icon name="lock" >}} |
| Bleu       | 8 Gio         | 0 Gio           | 10 Gio  | Pas en lecture seule        |
| Vert      | 10 Gio        | 0 Gio           | 10 Gio  | Lecture seule {{< icon name="lock" >}} |
| Jaune     | 2 Gio         | 0 Gio           | 10 Gio  | Pas en lecture seule        |
| **Totaux** | **30 Gio**    | **0 Gio**       | -      | -                    |

Les projets Rouge et Vert sont en lecture seule car leurs dépôts et LFS ont atteint le quota. Dans cet exemple, aucun stockage supplémentaire n'a encore été acheté.

Pour supprimer l'état lecture seule des projets Rouge et Vert, 50 Gio de stockage supplémentaire sont achetés.

Si les dépôts et le LFS de certains projets dépassent le quota de 10 Gio, le stockage acheté disponible diminue.

| Dépôt | Stockage utilisé | Stockage excédentaire | Quota   | Statut            |
|------------|--------------|----------------|---------|-------------------|
| Rouge        | 15 Gio        | 5 Gio         | 10 Gio  | Pas en lecture seule     |
| Bleu       | 14 Gio        | 4 Gio         | 10 Gio  | Pas en lecture seule     |
| Vert      | 11 Gio        | 1 Gio         | 10 Gio  | Pas en lecture seule     |
| Jaune     | 5 Gio         | 0 Gio         | 10 Gio  | Pas en lecture seule     |
| **Totaux** | **45 Gio**    | **10 Gio**    | -       | -                 |

Dans cet exemple :

- Le stockage acheté disponible est de 40 Gio : 50 Gio (stockage acheté) - 10 Gio (stockage excédentaire total utilisé). Par conséquent, les projets ne sont plus en lecture seule.
- L'utilisation du stockage excédentaire est de 20 % : 10 Gio / 50 Gio × 100.
- Le stockage acheté restant est de 80 %.

## Gérer l'utilisation du stockage {#manage-storage-usage}

Pour gérer votre stockage, si vous êtes Propriétaire d'un espace de nommage GitLab.com Gratuit, vous pouvez acheter du stockage supplémentaire pour l'espace de nommage.

Dans l'édition GitLab Premium et GitLab Ultimate, selon votre rôle, vous pouvez également [réduire la taille du dépôt](project/repository/repository_size.md#methods-to-reduce-repository-size). Pour automatiser l'analyse et la gestion de l'utilisation du stockage, consultez [l'automatisation de la gestion du stockage](storage_management_automation.md).

En plus de gérer votre utilisation du stockage, vous pouvez envisager ces options pour augmenter vos consommables :

- Si vous êtes éligible, faites une demande d'[abonnement à un programme communautaire](../subscriptions/community_programs.md) :
  - GitLab for Education
  - GitLab for Open Source
  - GitLab for Startups
- Envisagez un [abonnement GitLab Self-Managed](../subscriptions/manage_subscription.md), qui ne comporte pas de limites de stockage.
- [Parlez à un expert](https://page.gitlab.com/usage_limits_help.html) pour plus d'informations sur vos options.

## Acheter plus de stockage {#purchase-more-storage}

{{< details >}}

- Édition : Gratuite

{{< /details >}}

> [!note]
> Pour dépasser la limite gratuite de 10 Gio sur votre espace de nommage GitLab.com Gratuit, vous pouvez acheter du stockage supplémentaire pour votre espace de nommage personnel ou de groupe.

Prérequis :

- Vous devez disposer du rôle Propriétaire ou être gestionnaire de compte de facturation.
- Le compte de facturation doit être lié à l'abonnement de l'espace de nommage personnel ou de groupe.

> [!note]
> Les abonnements de stockage se renouvellent automatiquement chaque année. Vous pouvez [désactiver le renouvellement automatique de l'abonnement](../subscriptions/manage_subscription.md#turn-on-or-turn-off-automatic-subscription-renewal).

### Pour votre espace de nommage personnel {#for-your-personal-namespace}

1. Connectez-vous à GitLab.com.
1. Depuis votre page d'accueil personnelle ou la page du groupe, accédez à **Paramètres** > **Quotas d'utilisation**.
1. Sélectionnez l'onglet **Stockage**.
1. Pour chaque projet en lecture seule, calculez le total du dépassement de l'**Utilisation** par rapport au quota gratuit et au stockage acheté. Vous devez acheter l'incrément de stockage qui dépasse ce total.
1. Sélectionnez **Acheter du stockage**. Vous êtes redirigé vers le portail clients.
1. Dans la section **Détails de l'abonnement**, sélectionnez le nom de l'utilisateur dans la liste déroulante.
1. Saisissez la quantité souhaitée de packs de stockage.
1. Dans la section **Informations client**, vérifiez votre adresse.
1. Dans la section **Informations de facturation**, sélectionnez le mode de paiement dans la liste déroulante.
1. Cochez les cases **Politique de confidentialité** et **Conditions d'utilisation**.
1. Sélectionnez **Acheter du stockage**.

Le total **Stockage acheté disponible** est augmenté du montant acheté. L'état lecture seule de tous les projets est supprimé et leur utilisation excédentaire est déduite du stockage supplémentaire.

### Pour votre espace de nommage de groupe {#for-your-group-namespace}

Si vous utilisez GitLab.com, vous pouvez acheter du stockage supplémentaire afin que vos pipelines ne soient pas bloqués après avoir utilisé tout votre stockage de votre quota principal. Vous pouvez consulter les tarifs du stockage supplémentaire sur la [page de tarification GitLab](https://about.gitlab.com/pricing/#storage).

Pour acheter du stockage supplémentaire pour votre groupe sur GitLab.com :

{{< tabs >}}

{{< tab title="Propriétaire du groupe" >}}

1. Connectez-vous à GitLab.com.
1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Quotas d'utilisation**.
1. Sélectionnez l'onglet **Stockage**.
1. Sélectionnez **Acheter du stockage**. Vous êtes redirigé vers le portail clients.
1. Dans la section **Détails de l'abonnement**, dans le champ **Quantité**, saisissez la quantité souhaitée de packs de stockage.
1. Dans la section **Informations client**, vérifiez votre adresse.
1. Dans la section **Informations de facturation**, sélectionnez un mode de paiement dans la liste déroulante.
1. Cochez la case **Politique de confidentialité** et **Conditions d'utilisation**.
1. Sélectionnez **Acheter du stockage**.

{{< /tab >}}

{{< tab title="Gestionnaire de compte de facturation" >}}

1. Accédez au [portail clients](https://customers.gitlab.com/customers/sign_in).
1. Sur la carte d'abonnement, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}) puis **Acheter plus de stockage**.
1. Dans la section **Détails de l'abonnement**, dans le champ **Quantité**, saisissez la quantité souhaitée de packs de stockage.
1. Dans la section **Informations client**, vérifiez votre adresse.
1. Dans la section **Informations de facturation**, sélectionnez un mode de paiement dans la liste déroulante.
1. Cochez la case **Politique de confidentialité** et **Conditions d'utilisation**.
1. Sélectionnez **Acheter du stockage**.

{{< /tab >}}

{{< /tabs >}}

Une fois votre paiement traité, le stockage supplémentaire est disponible pour votre espace de nommage de groupe.

Pour confirmer le stockage disponible, suivez les trois premières étapes indiquées précédemment.

Le total **Stockage acheté disponible** est augmenté du montant acheté. Tous les projets verrouillés sont déverrouillés et leur utilisation excédentaire est déduite du stockage supplémentaire.
