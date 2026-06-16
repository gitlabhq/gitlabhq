---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Comprendre le fonctionnement des GitLab Credits et consulter votre utilisation des crédits.
title: "GitLab Credits et facturation basée sur l'utilisation"
---

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduit dans GitLab 18.7.
- GitLab Duo Agent Platform et GitLab Credits sont pris en charge sur GitLab 18.8 et versions ultérieures.
- Introduit pour les abonnements communautaires dans GitLab 18.11.

{{< /history >}}

Les GitLab Credits constituent la devise de consommation standardisée pour la facturation basée sur l'utilisation. Les crédits sont utilisés pour [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md), où chaque action d'utilisation consomme un certain nombre de crédits.

[GitLab Duo Pro et Enterprise](subscription-add-ons.md#gitlab-duo-pro-and-enterprise) et leurs [fonctionnalités GitLab Duo](../user/gitlab_duo/feature_summary.md) associées ne sont pas facturés en fonction de l'utilisation et ne consomment pas de GitLab Credits.

Les crédits sont calculés en fonction des fonctionnalités et des modèles que vous utilisez, comme indiqué dans les tables de multiplicateurs de crédits. Vous êtes facturé pour les fonctionnalités qui sont [en disponibilité générale](../policy/development_stages_support.md#generally-available).

La facturation s'effectue au niveau de l'espace de nommage racine ou du groupe principal, et non au niveau du projet. L'utilisation des crédits est attribuée au sujet qui effectue l'action, quel que soit le projet dans lequel il utilise les fonctionnalités. Un sujet est soit un utilisateur humain, soit un sujet non humain (par exemple, un compte de service ou un bot exécutant un flow automatisé).

Toute l'utilisation dans un espace de nommage racine ou un groupe principal est consolidée à des fins de facturation.

GitLab propose trois façons d'obtenir des crédits :

- Crédits inclus
- Pool d'engagement mensuel
- Crédits à la demande

Pour une démonstration interactive, consultez [GitLab Credits](https://gitlab.navattic.com/credits-dashboard).
<!-- Demo published on 2026-01-28 -->

Pour plus d'informations sur la tarification des crédits, consultez [les tarifs GitLab](https://about.gitlab.com/pricing/).

## Crédits inclus {#included-credits}

Les crédits inclus sont alloués à tous les utilisateurs disposant d'un niveau Premium ou Ultimate. Ces crédits sont individuels et ne peuvent pas être partagés entre les utilisateurs. Les crédits inclus sont réinitialisés au début de chaque mois. Les crédits non utilisés ne sont pas reportés au mois suivant.

Les [abonnements aux programmes communautaires](community_programs.md) ne reçoivent pas de crédits inclus.

Les sujets non humains ne reçoivent pas de crédits inclus. Leur consommation est facturée au niveau de l'espace de nommage depuis le Pool d'engagement mensuel et les crédits à la demande, dans le même ordre d'utilisation que pour les utilisateurs humains.

Pour plus d'informations sur les crédits inclus, consultez les [Conditions générales des promotions GitLab](https://about.gitlab.com/pricing/terms/).

## Pool d'engagement mensuel {#monthly-commitment-pool}

Le Pool d'engagement mensuel est un pool de crédits partagé disponible pour tous les utilisateurs de l'abonnement. Tous les utilisateurs de votre abonnement peuvent puiser dans ce pool partagé après avoir consommé leurs crédits inclus.

Vous pouvez souscrire au Pool d'engagement mensuel sous forme d'abonnement annuel récurrent ou pluriannuel. Le nombre de crédits achetés pour l'année est divisé en 12.

Par exemple, lorsque vous souscrivez à un pool d'engagement mensuel de 1 000 crédits, vous disposerez de 1 000 crédits chaque mois pendant la durée du contrat.

Vous pouvez augmenter votre engagement à tout moment auprès de votre équipe de compte GitLab. L'engagement supplémentaire s'applique pour le reste de la durée de votre contrat. Vous ne pouvez diminuer votre engagement qu'au moment du renouvellement.

Vous pouvez souscrire à un engagement de crédits avec une remise par paliers intégrée. L'engagement est facturé d'avance au début de la durée du contrat.

Les crédits deviennent disponibles immédiatement après l'achat et sont réinitialisés le premier de chaque mois. Les crédits non utilisés ne sont pas reportés au mois suivant.

> [!note]
> En souscrivant à un pool d'engagement mensuel, vous acceptez les conditions de facturation basée sur l'utilisation, y compris l'utilisation des crédits à la demande. Une fois les conditions acceptées, la facturation à la demande reste active pour le reste de votre abonnement et les renouvellements en libre-service ultérieurs, et vous ne pouvez pas vous désinscrire.

## Crédits à la demande {#on-demand-credits}

Les crédits à la demande couvrent l'utilisation engagée après avoir utilisé tous les crédits inclus et les crédits du Pool d'engagement mensuel. Les crédits à la demande sont facturés mensuellement.

Les crédits à la demande sont consommés au prix catalogue de 1 $ par crédit utilisé.

Les crédits à la demande peuvent être utilisés après avoir accepté les conditions de facturation basée sur l'utilisation. Vous pouvez accepter ces conditions lors de la souscription à votre engagement mensuel, ou directement dans le tableau de bord des crédits GitLab dans le Portail clients. En acceptant les conditions de facturation basée sur l'utilisation, vous acceptez de payer tous les frais à la demande déjà engagés au cours de la période de facturation mensuelle en cours, ainsi que tous les frais à la demande futurs.

Si vous n'avez pas accepté les conditions de facturation basée sur l'utilisation, vous ne pouvez pas utiliser GitLab Duo Agent Platform ni consommer des crédits à la demande. Vous pouvez retrouver l'accès à GitLab Duo Agent Platform en souscrivant à un engagement mensuel ou en acceptant les conditions de facturation basée sur l'utilisation.

Par exemple, un abonnement dispose d'un engagement mensuel de 50 crédits par mois. Si 75 crédits sont utilisés ce mois-là, les 50 premiers crédits font partie du pool d'engagement mensuel, et les 25 crédits supplémentaires sont facturés comme utilisation à la demande.

## Ordre d'utilisation {#usage-order}

Les GitLab Credits sont consommés dans l'ordre suivant :

1. Les crédits inclus sont utilisés en premier par chaque utilisateur.
1. Le Pool d'engagement mensuel de crédits est utilisé après que tous les crédits inclus ont été consommés.
1. Les crédits à la demande sont utilisés après tous les autres crédits disponibles (crédits inclus et Pool d'engagement mensuel, le cas échéant) sont épuisés et que les conditions de facturation basée sur l'utilisation sont signées.

## Crédits d'évaluation temporaires {#temporary-evaluation-credits}

Si vous n'avez pas souscrit au Pool d'engagement mensuel ou accepté les conditions de facturation basée sur l'utilisation pour les crédits à la demande, vous pouvez demander un pool temporaire gratuit de crédits pour évaluer les fonctionnalités de GitLab Duo Agent Platform.

Les crédits sont alloués en fonction du nombre d'utilisateurs que vous demandez pour l'évaluation, et ajoutés à un pool partagé pour ces utilisateurs. Les crédits sont valables 30 jours et ne peuvent pas être utilisés après leur expiration.

Pour demander des crédits, [contactez l'équipe commerciale](https://about.gitlab.com/sales/).

Si vous utilisez le niveau Free et souhaitez essayer les crédits, vous pouvez démarrer un [essai Ultimate](free_trials.md).

## Pour le niveau Free {#for-the-free-tier}

{{< details >}}

- Niveau : Free
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/20165) dans GitLab 18.10 pour GitLab.com.
- Activé sur GitLab Self-Managed dans GitLab 19.0.

{{< /history >}}

Les utilisateurs du niveau Free peuvent souscrire à un Pool d'engagement mensuel de GitLab Credits pour leur instance ou leur espace de nommage de groupe. Cela permet d'accéder à un ensemble de [fonctionnalités de GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md), sans avoir besoin d'un abonnement Premium ou Ultimate.

L'utilisation à la demande pour les espaces de nommage Free est plafonnée à 25 000 $ par mois civil. Lorsque cette limite est atteinte, l'utilisation à la demande est automatiquement désactivée et réinitialisée au début du mois suivant.

## Acheter des GitLab Credits {#buy-gitlab-credits}

Vous pouvez acheter des GitLab Credits pour votre Pool d'engagement mensuel dans le Portail clients.

{{< tabs >}}

{{< tab title="Portail clients" >}}

Prérequis :

- Vous devez être gestionnaire de compte de facturation.

1. Connectez-vous au [Portail clients](https://customers.gitlab.com/).
1. Sur la carte d'abonnement correspondante, sélectionnez **Tableau de bord des crédits GitLab**.
1. Sélectionnez **Souscrire à un abonnement mensuel** ou **Augmenter le montant de l'abonnement mensuel**.
1. Saisissez le nombre de crédits que vous souhaitez acheter.
1. Sélectionnez **Vérifier la commande**. Vérifiez que le nombre de crédits, les informations client et le mode de paiement sont corrects.
1. Sélectionnez **Confirmer l'achat**.

{{< /tab >}}

{{< tab title="GitLab.com" >}}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Sur le niveau Premium et Ultimate :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe principal.
1. Sélectionnez **Paramètres** > **Crédits GitLab**.
1. Sélectionnez **Souscrire à un abonnement mensuel** ou **Augmenter le montant de l'abonnement mensuel**.
1. Dans le formulaire du Portail clients, saisissez le nombre de crédits que vous souhaitez acheter.
1. Sélectionnez **Vérifier la commande**. Vérifiez que le nombre de crédits, les informations client et le mode de paiement sont corrects.
1. Sélectionnez **Confirmer l'achat**.

Sur le niveau Free :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe principal.
1. Sélectionnez **Paramètres** > **Facturation**.
1. Si vous :
   - N'êtes pas en période d'essai : Sur la carte Crédits GitLab, sélectionnez **Acheter des crédits** ou **Augmenter les crédits**.
   - Êtes en période d'essai active : Sur la carte Crédits GitLab, sélectionnez **Souscrire à un engagement mensuel** ou **Augmenter les crédits**.
1. Dans le formulaire du Portail clients, saisissez le nombre de crédits que vous souhaitez acheter.
1. Sélectionnez **Vérifier la commande**. Vérifiez que le nombre de crédits, les informations client et le mode de paiement sont corrects.
1. Sélectionnez **Confirmer l'achat**.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

Prérequis :

- Vous devez être administrateur.
- Votre instance doit être en mesure de synchroniser les données de votre abonnement avec GitLab.

Sur le niveau Premium et Ultimate :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Crédits GitLab**.
1. Sélectionnez **Souscrire à un abonnement mensuel** ou **Augmenter le montant de l'abonnement mensuel**.
1. Dans le formulaire du Portail clients, saisissez le nombre de crédits que vous souhaitez acheter.
1. Sélectionnez **Vérifier la commande**. Vérifiez que le nombre de crédits, les informations client et le mode de paiement sont corrects.
1. Sélectionnez **Confirmer l'achat**.

Sur le niveau Free :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Abonnement**.
1. Sur la carte Crédits GitLab, sélectionnez **Acheter des crédits**.
1. Si vous n'avez pas de compte sur le Portail clients, effectuez d'abord les étapes de création d'un compte. Utilisez ensuite vos identifiants pour vous connecter.
1. Dans le formulaire du Portail clients, saisissez le nombre de crédits que vous souhaitez acheter.
1. Sélectionnez **Vérifier la commande**. Vérifiez que le nombre de crédits, les informations client et le mode de paiement sont corrects.
1. Sélectionnez **Confirmer l'achat**.

{{< /tab >}}

{{< /tabs >}}

Vos GitLab Credits sont affichés dans le Portail clients sur la carte d'abonnement et dans le tableau de bord des crédits GitLab.

## Multiplicateurs de crédits {#credit-multipliers}

L'utilisation des crédits est calculée en fonction des fonctionnalités et des modèles utilisés. Certaines fonctionnalités proposent plusieurs options de modèles, tandis que d'autres n'utilisent qu'un seul modèle.

Une requête représente une action unique (facturable) initiée par un utilisateur (par exemple, l'envoi d'un message de chat ou une demande de génération de code). Cela représente une seule interaction du point de vue de l'utilisateur.

Un appel de modèle représente les appels API sous-jacents effectués aux LLM pour satisfaire une requête d'utilisateur. Une seule requête d'utilisateur peut déclencher plusieurs appels de modèle. Par exemple, un appel pour comprendre le contexte et un autre appel pour générer une réponse.

### Modèles {#models}

Le tableau suivant répertorie le nombre d'appels LLM que vous pouvez effectuer avec un GitLab Credit pour différents [modèles](../user/duo_agent_platform/model_selection.md). Les modèles plus récents et plus complexes ont un multiplicateur plus élevé et nécessitent davantage de crédits.

Vous êtes facturé pour l'utilisation des modèles selon les méthodes de facturation suivantes :

- Tarification variable pour les modèles gérés par GitLab : Une requête équivaut à un seul appel LLM. Un flow effectue un ou plusieurs appels. Le coût en crédits dépend du modèle utilisé.
- Tarification variable pour les modèles auto-hébergés : Une requête équivaut à un seul appel LLM. Un flow effectue un ou plusieurs appels. Vous pouvez effectuer huit requêtes avec un crédit pour tout modèle auto-hébergé [pris en charge](../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) ou [compatible](../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models).
- Tarification fixe pour les fonctionnalités GitLab Duo : Chaque exécution complète de bout en bout consomme un montant prédéfini de crédits, quel que soit le nombre d'appels LLM (modèles gérés par GitLab et auto-hébergés) effectués lors de l'exécution.

Seuls les appels ou exécutions complétés sont facturés. Si un appel ou une exécution échoue, aucun crédit n'est déduit.

Pour les modèles subventionnés avec intégration de base :

| Modèle | Appels avec un crédit |
|-------|------------------------|
| `claude-3-haiku` | 8,0 |
| `codestral-2501` | 8,0 |
| `gemini-2.5-flash` | 8,0 |
| `gpt-5-mini` | 8,0 |
| `gpt-5-4-nano` | 8,0 |

Pour les modèles premium avec intégration optimisée :

| Modèle | Appels avec un crédit |
|-------|------------------------|
| `claude-4.5-haiku` | 6,7 |
| `gpt-5-4-mini` | 6,7 |
| `gpt-5-codex` | 3,3|
| `gpt-5` | 3,3 |
| `gpt-5.2` | 2,5 |
| `gpt-5.2-codex` | 2,5 |
| `gpt-5.3-codex` | 2,5 |
| `claude-3.5-sonnet` | 2,0 |
| `claude-3.7-sonnet` | 2,0 |
| `claude-sonnet-4` | 2,0 |
| `claude-sonnet-4.5` | 2,0 |
| `claude-sonnet-4.6` | 2,0 |
| `claude-opus-4.5` | 1,2 |
| `claude-opus-4.6`  | 1,1 |
| `claude-opus-4.7` | 1,1 |

### Fonctionnalités {#features}

Le tableau suivant répertorie le nombre d'exécutions que vous pouvez effectuer avec un GitLab Credit pour différentes fonctionnalités. Cette tarification s'applique à tous les modèles (y compris les modèles auto-hébergés) disponibles pour la fonctionnalité.

| Fonctionnalité | Exécutions avec un crédit |
|---------|---------------------------|
| [GitLab Duo Code Suggestions](../user/duo_agent_platform/code_suggestions/_index.md) | 50 |
| flow Code Review | 4 |
| flow SAST False Positive Detection | 1 |
| flow SAST Vulnerability Resolution | 0,25 |

Pour GitLab Duo Agentic Chat, un message envoyé compte comme une ou plusieurs requêtes facturables, car un ou plusieurs appels LLM sont effectués pour répondre à la question. Une fenêtre de conversation peut inclure plusieurs messages, et donc plusieurs requêtes facturables. La tarification dépend du modèle sélectionné.

## Tableau de bord des crédits GitLab {#gitlab-credits-dashboard}

{{< details >}}

- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Introduit dans GitLab 18.7.
- Tri des résultats [introduit](https://gitlab.com/groups/gitlab-org/-/work_items/21008) dans GitLab 18.10.

{{< /history >}}

Le tableau de bord des crédits GitLab affiche des informations sur votre utilisation des GitLab Credits. Utilisez le tableau de bord pour surveiller la consommation de crédits, suivre les tendances et identifier les schémas d'utilisation.

Pour vous aider à gérer la consommation de crédits, GitLab envoie par e-mail les informations suivantes aux administrateurs et aux propriétaires d'abonnement :

- Récapitulatifs mensuels de l'utilisation des crédits
- Notifications lorsque les seuils d'utilisation des crédits atteignent 50 %, 80 % et 100 %

Vous pouvez accéder au tableau de bord dans le Portail clients et dans GitLab.

> [!note]
> Les données d'utilisation ne sont pas affichées en temps réel. Les données sont synchronisées périodiquement avec les tableaux de bord, de sorte que les données d'utilisation devraient apparaître dans les quelques heures suivant la consommation effective. Cela signifie que votre tableau de bord affiche l'utilisation récente, mais peut ne pas refléter les actions effectuées au cours des dernières heures.

### Dans le Portail clients {#in-customers-portal}

Le tableau de bord des crédits GitLab dans le Portail clients offre la vue la plus détaillée de votre utilisation et de vos coûts.

Dans le tableau de bord, les crédits utilisés représentent des déductions des crédits disponibles. Pour les dépassements (crédits à la demande), les crédits utilisés représentent l'utilisation à la demande qui sera payée ultérieurement, si vous avez accepté les conditions de facturation basée sur l'utilisation.

Le tableau de bord affiche des cartes récapitulatives des indicateurs clés :

- Utilisation du mois en cours : Total des GitLab Credits utilisés au cours du mois en cours (si vous disposez d'un engagement mensuel)
- Crédits inclus : Total des crédits inclus dans votre abonnement (si vous disposez d'un engagement mensuel)
- Crédits engagés : Crédits provenant de votre Pool d'engagement mensuel (le cas échéant)
- Remises mensuelles : Crédits restants issus de remises (le cas échéant)
- Utilisation à la demande : Crédits consommés au-delà de vos montants inclus et engagés. Si vous disposez de suffisamment de crédits de remise pour compenser tous les crédits à la demande, le tableau de bord des crédits GitLab masque la carte **À la demande** et affiche à la place la carte **Exonération mensuelle**.
- État du contrôle d'utilisation : Indique si des utilisateurs individuels ont été bloqués depuis l'accès à Agent Platform en raison de l'atteinte de leur plafond de crédits par utilisateur.

### Dans GitLab {#in-gitlab}

> [!note]
> Ce tableau de bord affiche l'utilisation de toutes les fonctionnalités de GitLab Duo Agent Platform, y compris les fonctionnalités bêta et expérimentales non facturables. Pour l'utilisation facturable uniquement, consultez le tableau de bord dans le Portail clients.

Le tableau de bord des crédits GitLab dans GitLab offre une visibilité opérationnelle sur l'utilisation des crédits dans votre organisation. Utilisez le tableau de bord pour comprendre quels utilisateurs, groupes ou projets génèrent de l'utilisation, et pour prendre des décisions éclairées concernant l'allocation des ressources.

Le tableau de bord affiche les informations suivantes :

- **Utilisation dans l'organisation** : Utilisation totale des crédits dans votre instance ou groupe GitLab
- **Crédits totaux consommés** : Consommation quotidienne de crédits pour tous les produits, affichée sous forme de graphique à barres
- **Utilisation par l'utilisateur/utilisatrice** : Nombre de crédits utilisés par chaque utilisateur
- **Vue détaillée par utilisateur** : Événements d'utilisation individuels pour chaque utilisateur, avec des liens vers les détails de session de GitLab Duo Agent Platform

### Afficher le tableau de bord des crédits GitLab {#view-the-gitlab-credits-dashboard}

{{< history >}}

- Sélection de la période d'utilisation historique [introduite](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/15910) dans GitLab 18.11.

{{< /history >}}

{{< tabs >}}

{{< tab title="Portail clients" >}}

Prérequis :

- Pour afficher des informations d'utilisation détaillées, vous devez être gestionnaire de compte de facturation.

1. Connectez-vous au [Portail clients](https://customers.gitlab.com/).
1. Sur la carte d'abonnement, sélectionnez **Tableau de bord des crédits GitLab**.
1. Facultatif. Pour afficher un mois précédent, dans la liste déroulante **Période d'utilisation**, sélectionnez la période que vous souhaitez consulter.
1. Facultatif. Pour trier les résultats par **Utilisateur/utilisatrice** ou **Crédits totaux utilisés**, sélectionnez la colonne correspondante.

{{< /tab >}}

{{< tab title="GitLab.com" >}}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe principal.
1. Sélectionnez **Paramètres** > **Crédits GitLab**.
1. Facultatif. Pour trier les résultats par **Utilisateur/utilisatrice** ou **Crédits totaux utilisés**, sélectionnez la colonne correspondante.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

Prérequis :

- Vous devez être administrateur.
- Votre instance doit être en mesure de synchroniser les données de votre abonnement avec GitLab.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Crédits GitLab**.
1. Facultatif. Pour trier les résultats par **Utilisateur/utilisatrice** ou **Crédits totaux utilisés**, sélectionnez la colonne correspondante.

{{< /tab >}}

{{< /tabs >}}

Par défaut, les données d'utilisateurs individuels ne sont pas affichées dans le tableau de bord des crédits GitLab. Pour les afficher, vous devez activer ce paramètre pour votre [groupe](../user/group/manage.md#display-gitlab-credits-user-data) ou votre [instance](../administration/settings/visibility_and_access_controls.md#display-gitlab-credits-user-data).

### Utilisation par les sujets non humains {#non-human-subject-usage}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/596238) dans GitLab 19.0.

{{< /history >}}

La consommation de crédits peut être déclenchée par un utilisateur humain ou un sujet non humain (par exemple, une fonctionnalité d'IA comme le flow SAST False Positive Detection).

Pour vous aider à identifier où les crédits sont consommés, l'onglet **Utilisation par l'utilisateur/utilisatrice** du tableau de bord des crédits GitLab affiche un badge **Automated flow** à côté des lignes représentant des sujets non humains. Les lignes sans badge représentent des utilisateurs humains.

L'affichage du badge **Flow automatisé** est contrôlé par le paramètre **Afficher les données utilisateur de GitLab Credits**, disponible pour les [groupes](../user/group/manage.md#display-gitlab-credits-user-data) et les [instances](../administration/settings/visibility_and_access_controls.md#display-gitlab-credits-user-data).

### Plafonds d'utilisation {#usage-caps}

{{< details >}}

- Statut : Bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/19881) dans GitLab 18.11 [avec un feature flag](../administration/feature_flags/_index.md) nommé `budget_caps_graphql_api`. Activé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Vous pouvez définir un plafond mensuel de GitLab Credits au niveau de l'abonnement et de l'utilisateur pour éviter des frais de dépassement inattendus. Lorsque la consommation de crédits atteint le plafond configuré, l'accès aux fonctionnalités qui consomment des GitLab Credits (par exemple, GitLab Duo Agent Platform) est automatiquement suspendu jusqu'au début de la prochaine période de facturation, ou jusqu'à ce qu'un administrateur ajuste ou désactive le plafond.

Les types de plafonds suivants sont disponibles :

| Type de plafond | S'applique à | Sources de crédits comptabilisées | Géré via |
|---|---|---|---|
| Plafond d'abonnement | Tous les utilisateurs de l'abonnement | À la demande uniquement | Portail clients |
| Plafond utilisateur fixe | Utilisateurs individuels (limite par défaut) | Tous | GraphQL API |
| Remplacement par utilisateur | Utilisateurs spécifiques (remplace le plafond fixe) | Tous | GraphQL API |

Lorsque l'utilisation à la demande au cours de la période de facturation en cours atteint ou dépasse le plafond configuré, toutes les fonctionnalités d'Agent Platform (Duo Chat, Code Suggestions, Flows et Agents) sont suspendues pour tous les utilisateurs de cet abonnement ou de cette instance. Pour les plafonds au niveau utilisateur, seul l'utilisateur individuel ayant atteint son plafond est suspendu.

Les utilisateurs ayant atteint leur plafond ne peuvent pas accéder aux fonctionnalités d'Agent Platform jusqu'à ce que le plafond soit relevé ou que la prochaine période de facturation commence.

Les compteurs d'utilisation sont automatiquement réinitialisés au début de chaque période de facturation. Les valeurs de plafond persistent d'une période de facturation à l'autre, sauf modification.

Les plafonds sont appliqués en utilisant les données d'utilisation les plus récentes disponibles. Les données n'étant pas en temps réel, une utilisation supplémentaire limitée de GitLab Credits peut survenir avant que l'application du plafond ne prenne effet.

Lorsque l'utilisation à la demande de l'abonnement atteint le plafond configuré, GitLab envoie une notification par e-mail aux gestionnaires de compte de facturation.

#### Définir un plafond d'utilisation au niveau de l'abonnement {#set-a-subscription-level-usage-cap}

Prérequis :

- Vous devez être gestionnaire de compte de facturation.

1. Connectez-vous au [Portail clients](https://customers.gitlab.com/).
1. Sur la carte d'abonnement, sélectionnez **Tableau de bord des crédits GitLab**.
1. Dans le panneau **Plafond de crédits à la demande**, activez le bouton **Plafond mensuel de crédits à la demande**.
1. Saisissez le nombre maximum de GitLab Credits à la demande autorisé par période de facturation.
1. Sélectionnez **Enregistrer**.

Si le plafond est défini en dessous du total d'utilisation à la demande actuellement déclaré pour la période de facturation en cours, le plafond est considéré comme atteint immédiatement lors du prochain contrôle d'application.

Pour désactiver le plafond, désactivez le bouton **Plafond mensuel de crédits à la demande**. Lorsqu'il est désactivé, aucun plafond de GitLab Credits à la demande au niveau de l'abonnement n'est appliqué, et le comportement revient à la facturation existante.

Vous pouvez utiliser l'API GraphQL pour [consulter les plafonds d'utilisation](../api/graphql/reference/_index.md#gitlabsubscriptionbudgetcaps) et définir un [plafond fixe au niveau utilisateur](../api/graphql/reference/_index.md#mutationupsertflatusercap) ou un [plafond de remplacement par utilisateur](../api/graphql/reference/_index.md#mutationupsertuserbudgetcapoverrides).

### État du contrôle d'utilisation {#usage-control-status}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/594635) dans GitLab 18.11.

{{< /history >}}

Lorsque les plafonds de crédits par utilisateur sont activés, l'onglet **Utilisation par l'utilisateur/utilisatrice** du tableau de bord des crédits GitLab affiche une colonne **État du contrôle d'utilisation**. Cette colonne indique si chaque utilisateur peut accéder aux fonctionnalités de [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md) ou s'il est bloqué parce qu'il a atteint son plafond de crédits.

La colonne affiche l'un des statuts suivants :

| Statut | Description |
|--------|-------------|
| **Normal** | L'utilisateur n'a pas atteint son plafond de crédits et peut utiliser les fonctionnalités de GitLab Duo Agent Platform. |
| **Bloqué : plafond de l'abonnement atteint** | L'utilisateur a atteint le plafond fixe par utilisateur défini au niveau de l'abonnement. |
| **Bloqué : plafond de l'utilisateur atteint** | L'utilisateur a atteint un plafond de remplacement par utilisateur défini spécifiquement pour lui. |

#### Débloquer un utilisateur ayant atteint son plafond de crédits {#unblock-a-user-who-reached-their-credit-cap}

Vous pouvez restaurer l'accès d'un utilisateur bloqué en utilisant l'API GraphQL de remplacement par utilisateur.

Pour débloquer un utilisateur, vous pouvez :

- Augmenter le plafond : Définir un plafond de remplacement par utilisateur plus élevé afin que l'utilisation de l'utilisateur soit inférieure à la nouvelle limite.
- Supprimer le plafond : Supprimer le remplacement par utilisateur afin que l'utilisateur ne soit plus soumis à un plafond individuel.

Après la mise à jour du plafond, le statut de l'utilisateur passe à **Normal** et il peut à nouveau utiliser les fonctionnalités de GitLab Duo Agent Platform.

### Afficher les détails d'utilisation des crédits d'un utilisateur {#view-user-credit-usage-details}

{{< history >}}

- Lien vers les détails de session de GitLab Duo Agent Platform [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/579139) dans GitLab 18.10.

{{< /history >}}

Pour afficher les événements d'utilisation individuels d'un utilisateur dans une vue détaillée :

1. Dans le tableau de bord des crédits GitLab, sélectionnez l'onglet **Utilisation par l'utilisateur/utilisatrice**.
1. Dans la colonne **Utilisateur/utilisatrice**, sélectionnez l'utilisateur que vous souhaitez consulter.
1. Pour afficher les détails de session, dans la colonne **Action**, sélectionnez l'action que vous souhaitez consulter.

> [!note]
> Les liens de session sont disponibles uniquement pour les événements d'utilisation de GitLab Duo Agent Platform déclenchés dans un projet et ayant un identifiant de session associé. Les événements d'utilisation déclenchés dans un groupe, les événements hérités et les actions en dehors d'Agent Platform n'ont pas de liens.

### Exporter les données d'utilisation {#export-usage-data}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/14504) dans GitLab 18.10.

{{< /history >}}

Vous pouvez exporter les données d'utilisation des crédits d'un abonnement sous forme de fichier CSV dans le Portail clients. Le fichier CSV répertorie les événements d'utilisation et les crédits utilisés chaque jour du mois en cours.

Prérequis :

- Vous devez être gestionnaire de compte de facturation.

1. Connectez-vous au [Portail clients](https://customers.gitlab.com/).
1. Sur la carte d'abonnement, sélectionnez **Tableau de bord des crédits GitLab**.
1. Dans la liste déroulante **Période d'utilisation**, sélectionnez la période pour laquelle vous souhaitez exporter les données.
1. Sélectionnez **Exporter les données d'utilisation**.
