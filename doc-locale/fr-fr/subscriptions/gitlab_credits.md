---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Comprendre le fonctionnement des GitLab Credits et consulter votre utilisation des crédits.
title: "GitLab Credits et facturation à l'usage"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduits dans GitLab 18.7.
- GitLab Duo Agent Platform et GitLab Credits sont pris en charge sur GitLab 18.8 et versions ultérieures.
- Introduits pour les abonnements communautaires dans GitLab 18.11.

{{< /history >}}

Les GitLab Credits constituent la devise de consommation standardisée pour la facturation à l'usage. Les crédits sont utilisés pour [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md), où chaque action d'utilisation consomme un certain nombre de crédits.

[GitLab Duo Pro et Enterprise](subscription-add-ons.md#gitlab-duo-pro-and-enterprise) et leurs [fonctionnalités GitLab Duo](../user/gitlab_duo/feature_summary.md) associées ne sont pas facturés à l'utilisation et ne consomment pas de GitLab Credits.

Les crédits sont calculés en fonction des fonctionnalités et des modèles que vous utilisez, comme indiqué dans les tableaux des coefficients multiplicateurs de crédits. Vous êtes facturé pour les fonctionnalités qui sont [en disponibilité générale](../policy/development_stages_support.md#generally-available). Certaines fonctionnalités en version préliminaire entraînent également des frais d'utilisation. Si des frais s'appliquent, la page de documentation de la fonctionnalité le signale.

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

Les crédits inclus sont attribués à tous les utilisateurs disposant d'une édition GitLab Premium ou GitLab Ultimate. Ces crédits sont individuels et ne peuvent pas être partagés entre les utilisateurs. Les crédits inclus sont réinitialisés au début de chaque mois. Les crédits non utilisés ne sont pas reportés au mois suivant.

Les [abonnements aux programmes communautaires](community_programs.md) ne reçoivent pas de crédits inclus.

Les sujets non humains ne reçoivent pas de crédits inclus. Leur consommation est facturée au niveau de l'espace de nommage depuis le pool d'engagement mensuel et les crédits à la demande, dans le même ordre d'utilisation que pour les utilisateurs humains.

Pour plus d'informations sur les crédits inclus, consultez les [Conditions générales des promotions GitLab](https://about.gitlab.com/pricing/terms/).

## Pool d'engagement mensuel {#monthly-commitment-pool}

Le pool d'engagement mensuel est un pool de crédits partagé disponible pour tous les utilisateurs de l'abonnement. Tous les utilisateurs de votre abonnement peuvent puiser dans ce pool partagé après avoir consommé leurs crédits inclus.

Vous ne pouvez pas réserver le pool pour un sous-ensemble d'utilisateurs ni isoler la consommation à des utilisateurs, des groupes ou des projets spécifiques. Pour limiter la consommation des utilisateurs individuels, utilisez des plafonds d'utilisation.

Vous pouvez souscrire au pool d'engagement mensuel sous forme d'abonnement annuel récurrent ou pluriannuel. Le nombre de GitLab Credits achetés pour l'année est divisé par 12.

Par exemple, lorsque vous souscrivez à un pool d'engagement mensuel de 1 000 crédits, vous disposerez de 1 000 crédits chaque mois pendant la durée du contrat.

Vous pouvez augmenter votre engagement à tout moment auprès de votre équipe de compte GitLab. L'engagement supplémentaire s'applique pour le reste de la durée de votre contrat. Vous ne pouvez diminuer votre engagement qu'au moment du renouvellement.

Vous pouvez souscrire à un engagement de crédits avec une remise par paliers intégrée. L'engagement est facturé d'avance au début de la durée du contrat.

Les crédits deviennent disponibles immédiatement après l'achat et sont réinitialisés le premier de chaque mois. Les crédits non utilisés ne sont pas reportés au mois suivant.

> [!note]
> En souscrivant à un pool d'engagement mensuel, vous acceptez les conditions de facturation à l'usage, y compris l'utilisation des crédits à la demande. Une fois les conditions acceptées, la facturation à la demande reste active pour le reste de votre abonnement et les renouvellements en libre-service ultérieurs, et vous ne pouvez pas vous désinscrire.

## Crédits à la demande {#on-demand-credits}

Les crédits à la demande couvrent l'utilisation effectuée après avoir utilisé tous les crédits inclus et ceux du pool d'engagement mensuel. Les crédits à la demande sont facturés mensuellement.

Les crédits à la demande sont consommés au prix catalogue de 1 $ par crédit utilisé.

Les crédits à la demande peuvent être utilisés après avoir accepté les conditions de facturation à l'usage. Vous pouvez accepter ces conditions lors de la souscription à votre engagement mensuel, ou directement dans le tableau de bord GitLab Credits dans le portail clients. En acceptant les conditions de facturation à l'usage, vous acceptez de payer tous les frais à la demande déjà engagés au cours de la période de facturation mensuelle en cours, ainsi que tous les frais à la demande futurs.

Si vous n'avez pas accepté les conditions de facturation à l'usage, vous ne pouvez pas utiliser GitLab Duo Agent Platform ni consommer des crédits à la demande. Vous pouvez retrouver l'accès à GitLab Duo Agent Platform en souscrivant à un engagement mensuel ou en acceptant les conditions de facturation à l'usage.

Par exemple, un abonnement dispose d'un engagement mensuel de 50 crédits par mois. Si 75 crédits sont utilisés ce mois-là, les 50 premiers crédits font partie du pool d'engagement mensuel, et les 25 crédits supplémentaires sont facturés dans le cadre de l'utilisation à la demande.

## Ordre d'utilisation {#usage-order}

Les GitLab Credits sont consommés dans l'ordre suivant :

1. Les GitLab Credits d'évaluation temporaires sont utilisés en premier.
1. Les GitLab Credits inclus sont consommés par chaque utilisateur avant tout GitLab Credits partagé.
1. Le Monthly Commitment Pool de GitLab Credits est utilisé après que tous les GitLab Credits inclus ont été consommés.
1. Les crédits à la demande sont utilisés une fois que tous les autres crédits disponibles (crédits inclus et pool d'engagement mensuel, le cas échéant) ont été épuisés et que les conditions de facturation à l'usage ont été acceptées.

## Crédits d'évaluation temporaires {#temporary-evaluation-credits}

Si vous n'avez pas souscrit au pool d'engagement mensuel ou accepté les conditions de facturation à l'usage pour les crédits à la demande, vous pouvez demander un pool temporaire gratuit de crédits pour évaluer les fonctionnalités de GitLab Duo Agent Platform.

Les crédits sont attribués selon le nombre d'utilisateurs que vous demandez pour l'évaluation, et ajoutés à un pool partagé destiné à ces utilisateurs. Les crédits sont valables 30 jours et ne peuvent pas être utilisés après leur expiration.

Pour demander des crédits, [contactez l'équipe commerciale](https://about.gitlab.com/sales/).

Si vous utilisez l'édition Gratuite et souhaitez essayer les crédits, vous pouvez démarrer un [essai GitLab Ultimate](free_trials.md).

## Pour l'édition Gratuite {#for-the-free-tier}

{{< details >}}

- Édition : Gratuite
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduits](https://gitlab.com/groups/gitlab-org/-/work_items/20165) dans GitLab 18.10 pour GitLab.com.
- Activés sur GitLab Self-Managed dans GitLab 19.0.

{{< /history >}}

Les utilisateurs de l'édition Gratuite peuvent souscrire à un pool d'engagement mensuel de GitLab Credits pour leur instance ou leur espace de nommage de groupe. Ils peuvent ainsi accéder à un ensemble de [fonctionnalités de GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md), sans avoir besoin d'un abonnement GitLab Premium ou GitLab Ultimate.

L'utilisation à la demande pour les espaces de nommage de l'édition Gratuite est plafonnée à 25 000 $ par mois civil. Lorsque cette limite est atteinte, l'utilisation à la demande est automatiquement désactivée et réinitialisée au début du mois suivant.

## Acheter des GitLab Credits {#buy-gitlab-credits}

Vous pouvez acheter des GitLab Credits pour votre pool d'engagement mensuel dans le portail clients.

{{< tabs >}}

{{< tab title="Portail clients" >}}

Prérequis :

- Vous devez être gestionnaire de compte de facturation.

1. Connectez-vous au [portail clients](https://customers.gitlab.com/).
1. Sur la carte d'abonnement correspondante, sélectionnez **Tableau de bord GitLab Credits**.
1. Sélectionnez **Souscrire à un engagement mensuel** ou **Augmenter l'engagement mensuel**.
1. Saisissez le nombre de crédits que vous souhaitez acheter.
1. Sélectionnez **Vérifier la commande**. Vérifiez que le nombre de crédits, les informations client et le mode de paiement sont corrects.
1. Sélectionnez **Confirmer l'achat**.

{{< /tab >}}

{{< tab title="GitLab.com" >}}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Sur l'édition GitLab Premium et GitLab Ultimate :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Credits**.
1. Sélectionnez **Souscrire à un engagement mensuel** ou **Augmenter l'engagement mensuel**.
1. Dans le formulaire du portail clients, saisissez le nombre de crédits que vous souhaitez acheter.
1. Sélectionnez **Vérifier la commande**. Vérifiez que le nombre de crédits, les informations client et le mode de paiement sont corrects.
1. Sélectionnez **Confirmer l'achat**.

Sur l'édition Gratuite :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre groupe principal.
1. Sélectionnez **Paramètres** > **Facturation**.
1. Si vous :
   - N'avez pas de période d'essai en cours : sur la carte GitLab Credits, sélectionnez **Acheter des crédits** ou **Augmenter les crédits**.
   - Avez une période d'essai en cours : sur la carte GitLab Credits, sélectionnez **Souscrire à un engagement mensuel** ou **Augmenter les crédits**.
1. Dans le formulaire du portail clients, saisissez le nombre de crédits que vous souhaitez acheter.
1. Sélectionnez **Vérifier la commande**. Vérifiez que le nombre de crédits, les informations client et le mode de paiement sont corrects.
1. Sélectionnez **Confirmer l'achat**.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

Prérequis :

- Vous devez être administrateur.
- Votre instance doit être en mesure de synchroniser les données de votre abonnement avec GitLab.

Sur l'édition GitLab Premium et GitLab Ultimate :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Credits**.
1. Sélectionnez **Souscrire à un engagement mensuel** ou **Augmenter l'engagement mensuel**.
1. Dans le formulaire du portail clients, saisissez le nombre de crédits que vous souhaitez acheter.
1. Sélectionnez **Vérifier la commande**. Vérifiez que le nombre de crédits, les informations client et le mode de paiement sont corrects.
1. Sélectionnez **Confirmer l'achat**.

Sur l'édition Gratuite :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Abonnement**.
1. Sur la carte GitLab Credits, sélectionnez **Acheter des crédits**.
1. Si vous n'avez pas de compte sur le portail clients, effectuez d'abord les étapes de création d'un compte. Utilisez ensuite vos identifiants pour vous connecter.
1. Dans le formulaire du portail clients, saisissez le nombre de crédits que vous souhaitez acheter.
1. Sélectionnez **Vérifier la commande**. Vérifiez que le nombre de crédits, les informations client et le mode de paiement sont corrects.
1. Sélectionnez **Confirmer l'achat**.

{{< /tab >}}

{{< /tabs >}}

Vos GitLab Credits sont affichés dans le portail clients sur la carte d'abonnement et dans le tableau de bord GitLab Credits.

## Coefficients multiplicateurs de crédits {#credit-multipliers}

L'utilisation des crédits est calculée en fonction des fonctionnalités et des modèles utilisés. Certaines fonctionnalités proposent plusieurs modèles, tandis que d'autres n'utilisent qu'un seul modèle.

Une requête représente une action unique (facturable) initiée par un utilisateur (par exemple, l'envoi d'un message de chat ou une demande de génération de code). Cela représente une seule interaction du point de vue de l'utilisateur.

Un appel de modèle représente les appels API sous-jacents effectués aux LLM pour satisfaire une requête d'utilisateur. Une seule requête d'utilisateur peut déclencher plusieurs appels de modèle. Par exemple, un appel pour comprendre le contexte et un autre appel pour générer une réponse.

### Modèles {#models}

Le tableau suivant répertorie le nombre d'appels LLM que vous pouvez effectuer avec un GitLab Credit pour différents [modèles](../user/duo_agent_platform/model_selection.md). Les modèles plus récents et plus complexes ont un coefficient multiplicateur plus élevé et nécessitent davantage de crédits.

Vous êtes facturé pour l'utilisation des modèles selon les méthodes de facturation suivantes :

- Tarification variable pour les modèles gérés par GitLab : une requête équivaut à un seul appel LLM. Un flow effectue un ou plusieurs appels. Le coût en crédits dépend du modèle utilisé.
- Tarification variable pour les modèles auto-hébergés : une requête équivaut à un seul appel LLM. Un flow effectue un ou plusieurs appels. Vous pouvez effectuer huit requêtes avec un crédit pour un modèle auto-hébergé [pris en charge](../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) ou [compatible](../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models).
- Tarification fixe pour les fonctionnalités GitLab Duo : chaque exécution de bout en bout consomme un nombre prédéfini de GitLab Credits, quel que soit le nombre d'appels LLM (modèles gérés par GitLab et modèles auto-hébergés) effectués pendant l'exécution. Les fonctionnalités qui s'exécutent sur un modèle auto-hébergé bénéficient d'une remise de 20 % sur les GitLab Credits consommés pour une exécution.
- La déduction de GitLab Credits en cas d'échec d'exécution dépend de l'offre :
  - Sur GitLab.com avec des modèles gérés par GitLab, un flow qui échoue avant d'être terminé ne déduit aucun GitLab Credits, même si certains appels LLM ont déjà été effectués.
  - Sur GitLab Self-Managed avec des modèles auto-hébergés, pour les fonctionnalités qui n'utilisent pas de tarif fixe, la facturation est basée sur les appels LLM individuels, et non sur l'achèvement du flow. Chaque appel est mesuré à son démarrage ; ainsi, les appels effectués avant l'échec d'un flow sont toujours facturés. Cela signifie qu'un flow qui échoue en cours d'exécution peut tout de même consommer des GitLab Credits pour les appels déjà initiés. Pour les fonctionnalités à tarif fixe, le tarif fixe complet est facturé même si le flow échoue, quel que soit le nombre d'appels LLM réellement effectués.

Pour les modèles subventionnés avec intégration simple :

| Modèle | Appels avec un crédit |
|-------|------------------------|
| `claude-3-haiku` | 8,0 |
| `codestral-2501` | 8,0 |
| `gemini-2.5-flash` | 8,0 |
| `gpt-5-mini` | 8,0 |
| `gpt-5-4-nano` | 8,0 |

Pour les modèles de pointe avec intégration optimisée :

| Modèle | Appels avec un crédit |
|-------|------------------------|
| `gpt-5.6-luna` | 8,0 |
| `claude-4.5-haiku` | 6,7 |
| `gemini-3.6-flash` <sup>1</sup> | 6,7 |
| `gemini-3.7-flash` <sup>1</sup> | 6,7 |
| `gpt-5-4-mini` | 6,7 |
| `gemini-3.5-flash` | 3,3 |
| `gpt-5` | 3,3 |
| `gpt-5-codex` | 3,3 |
| `claude-sonnet-5` <sup>2</sup> | 3.2 |
| `gpt-5.2` | 2,5 |
| `gpt-5.2-codex` | 2,5 |
| `gpt-5.3-codex` | 2,5 |
| `gpt-5.6-terra` <sup>3</sup> | 2,5 |
| `claude-3.5-sonnet` | 2,0 |
| `claude-3.7-sonnet` | 2,0 |
| `claude-sonnet-4.5` | 2,0 |
| `claude-sonnet-4.6` | 2,0 |
| `gpt-5.4` <sup>3</sup> | 2,0 |
| `gpt-5.6-terra` <sup>4</sup> | 1.43 |
| `claude-opus-4.5` | 1,2 |
| `gpt-5.4` <sup>4</sup> | 1.11 |
| `claude-opus-4.6` | 1,1 |
| `claude-opus-4.7` | 1,1 |
| `claude-opus-4.8` | 1,1 |
| `claude-opus-5` | 1,1 |
| `gpt-5.5` <sup>3</sup> | 1.0 |
| `gpt-5.6-sol` <sup>3</sup> | 1.0 |
| `claude-fable-5` | 0.6 |
| `gpt-5.5` <sup>4</sup> | 0.57 |
| `gpt-5.6-sol` <sup>4</sup> | 0.57 |

**Notes de bas de page** :

1. Tarification promotionnelle jusqu'au 31 décembre 2026. Ensuite, le tarif passe à environ 3,3 appels par crédit.
1. Tarification promotionnelle jusqu'au 31 août 2026. Ensuite, le tarif passe à environ 2,1 appels par crédit.
1. Fenêtre de contexte courte pouvant atteindre 272 000 tokens.
1. Fenêtre de contexte longue de plus de 272 000 tokens.

### Fonctionnalités {#features}

{{< history >}}

- Remise sur modèle auto-hébergé introduite dans GitLab 19.1 [avec un feature flag](../administration/feature_flags/_index.md) nommé `self_hosted_flat_pricing_discount`.

{{< /history >}}

> [!flag]
> La disponibilité de la remise sur modèle auto-hébergé est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Le tableau suivant répertorie le nombre d'exécutions que vous pouvez effectuer avec un GitLab Credit pour différentes fonctionnalités. Cette tarification s'applique à tous les modèles (y compris les modèles auto-hébergés) disponibles pour la fonctionnalité.

Une fonctionnalité qui s'exécute sur un [modèle auto-hébergé](../administration/gitlab_duo_self_hosted/_index.md) bénéficie d'une remise de 20 %.

| Fonctionnalité | Exécutions avec un crédit (modèle géré par GitLab) | Exécutions avec un crédit (modèle auto-hébergé) |
|---------|----------------------------|------------------------------------------------|
| [Suggestions de code GitLab Duo](../user/duo_agent_platform/code_suggestions/_index.md) | 50 | 62.5 |
| Flow Code Review | 4 | 5 |
| Flow SAST False Positive Detection | 1 | 1.25 |
| Flow SAST Vulnerability Resolution | 0,25 | 0.3125 |

Pour GitLab Duo Agentic Chat, un message envoyé compte comme une ou plusieurs requêtes facturables, car un ou plusieurs appels LLM sont effectués pour répondre à la question. Une fenêtre de conversation peut inclure plusieurs messages, et donc plusieurs requêtes facturables. La tarification dépend du modèle sélectionné.

Le GitLab Secrets Manager consomme également des GitLab Credits, mais selon [un modèle de consommation différent](../ci/secrets/secrets_manager/secrets_manager_billing.md).

## Tableau de bord GitLab Credits {#gitlab-credits-dashboard}

{{< details >}}

- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Introduit dans GitLab 18.7.
- Tri des résultats [introduit](https://gitlab.com/groups/gitlab-org/-/work_items/21008) dans GitLab 18.10.

{{< /history >}}

Le tableau de bord GitLab Credits affiche des informations sur votre utilisation des GitLab Credits. Utilisez le tableau de bord pour surveiller la consommation de crédits, suivre les tendances et identifier les schémas d'utilisation.

Pour vous aider à gérer la consommation de crédits, GitLab envoie par e-mail les informations suivantes aux administrateurs et aux propriétaires d'abonnement :

- Récapitulatifs mensuels de l'utilisation des crédits
- Notifications lorsque les seuils d'utilisation des crédits atteignent 50 %, 80 % et 100 %

Vous pouvez accéder au tableau de bord dans le portail clients et dans GitLab.

> [!note]
> Les données d'utilisation ne sont pas affichées en temps réel. Les données d'utilisation sont synchronisées régulièrement avec les tableaux de bord ; elles devraient donc apparaître dans les heures qui suivent la consommation effective. Cela signifie que votre tableau de bord affiche l'utilisation récente, mais peut ne pas refléter les actions effectuées au cours des dernières heures.

### Dans le portail clients {#in-customers-portal}

Le tableau de bord GitLab Credits dans le portail clients offre la vue la plus détaillée de votre utilisation et de vos coûts.

Dans le tableau de bord, les crédits utilisés représentent des déductions des crédits disponibles. Pour les dépassements (crédits à la demande), les crédits utilisés représentent l'utilisation à la demande qui sera payée ultérieurement, si vous avez accepté les conditions de facturation à l'usage.

Le tableau de bord affiche des cartes récapitulatives des indicateurs clés :

- Utilisation pour le mois en cours : total des GitLab Credits utilisés au cours du mois (si vous disposez d'un engagement mensuel)
- Crédits inclus : total des crédits inclus dans votre abonnement (si vous disposez d'un engagement mensuel)
- Crédits engagés : crédits provenant de votre pool d'engagement mensuel (le cas échéant)
- Exonérations mensuelles : crédits restants issus des exonérations (le cas échéant)
- Utilisation à la demande : crédits consommés au-delà de vos montants inclus et engagés. Si vous disposez de suffisamment de crédits d'exonération pour compenser tous les crédits à la demande, le tableau de bord GitLab Credits masque la carte **À la demande** et affiche à la place la carte **Exonération mensuelle**.
- État du contrôle de l'utilisation : si certains utilisateurs ont été bloqués et ne peuvent plus accéder à GitLab Duo Agent Platform parce qu'ils ont atteint leur limite de crédits par utilisateur.

### Dans GitLab {#in-gitlab}

{{< history >}}

- Utilisation de Secrets Manager introduite dans GitLab 19.1.

{{< /history >}}

> [!note]
> Ce tableau de bord affiche l'utilisation de toutes les fonctionnalités de GitLab Duo Agent Platform, y compris les fonctionnalités bêta et expérimentales non facturables. Pour afficher uniquement l'utilisation facturable, accédez au Portail clients.
>
> Certaines fonctionnalités en version préliminaire, telles que le Security Review Flow, sont facturables et soumises aux frais de GitLab Credits.

Le tableau de bord GitLab Credits dans GitLab offre une visibilité opérationnelle sur l'utilisation des crédits dans votre organisation. Utilisez le tableau de bord pour comprendre quels utilisateurs, groupes ou projets génèrent de l'utilisation, et pour prendre des décisions éclairées concernant l'allocation des ressources.

Le tableau de bord affiche les informations suivantes :

- **Utilisation dans l'organisation** : utilisation totale de GitLab Credits, utilisateurs actifs, moyenne quotidienne de GitLab Credits et utilisation maximale journalière sur l'ensemble de votre instance ou groupe GitLab
- **Crédits totaux consommés** : consommation quotidienne de crédits pour tous les produits, affichée sous forme de graphique à barres
- **Utilisation par utilisateur** : nombre de crédits utilisés par chaque utilisateur
- **Vue détaillée par utilisateur** : événements d'utilisation individuels pour chaque utilisateur, avec des liens vers les détails de session de GitLab Duo Agent Platform
- **Utilisation par produit** : nombre de GitLab Credits utilisés et pourcentage du total de GitLab Credits pour GitLab Duo Agent Platform et Secrets Manager

> [!note]
> Pendant que [GitLab Secrets Manager](../ci/secrets/secrets_manager/_index.md) est en version bêta, GitLab ne facture pas l'utilisation. Secrets Manager apparaît dans le tableau de bord GitLab Credits, mais n'affiche aucune donnée d'utilisation jusqu'à la fin de la période de version bêta.

### Afficher le tableau de bord GitLab Credits {#view-the-gitlab-credits-dashboard}

{{< history >}}

- Sélection de la période pour l'historique d'utilisation [introduite](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/15910) dans GitLab 18.11.

{{< /history >}}

{{< tabs >}}

{{< tab title="Portail clients" >}}

Prérequis :

- Pour afficher des informations d'utilisation détaillées, vous devez être gestionnaire de compte de facturation.

1. Connectez-vous au [portail clients](https://customers.gitlab.com/).
1. Sur la carte d'abonnement, sélectionnez **Tableau de bord GitLab Credits**.
1. Facultatif. Pour afficher un mois précédent, dans la liste déroulante **Période d'utilisation**, sélectionnez la période que vous souhaitez consulter.
1. Facultatif. Pour trier les résultats par **Utilisateur** ou par **Crédits totaux utilisés**, sélectionnez la colonne correspondante.

{{< /tab >}}

{{< tab title="GitLab.com" >}}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Credits**.
1. Facultatif. Pour trier les résultats par **Utilisateur** ou par **Crédits totaux utilisés**, sélectionnez la colonne correspondante.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

Prérequis :

- Vous devez être administrateur.
- Votre instance doit être en mesure de synchroniser les données de votre abonnement avec GitLab.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Credits**.
1. Facultatif. Pour trier les résultats par **Utilisateur** ou par **Crédits totaux utilisés**, sélectionnez la colonne correspondante.

{{< /tab >}}

{{< /tabs >}}

Par défaut, les données d'utilisateurs individuels ne sont pas affichées dans le tableau de bord GitLab Credits. Pour les afficher, vous devez activer ce paramètre pour votre [groupe](../user/group/manage.md#display-gitlab-credits-user-data) ou votre [instance](../administration/settings/visibility_and_access_controls.md#display-gitlab-credits-user-data).

### Utilisation par les sujets non humains {#non-human-subject-usage}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/596238) dans GitLab 19.0.

{{< /history >}}

La consommation de crédits peut être déclenchée par un utilisateur humain ou un sujet non humain (par exemple, une fonctionnalité d'IA comme le flow SAST False Positive Detection).

Pour vous aider à identifier où les crédits sont consommés, l'onglet **Utilisation par utilisateur** du tableau de bord GitLab Credits affiche un badge **Flow automatisé** à côté des lignes représentant des sujets non humains. Les lignes sans badge représentent des utilisateurs humains.

L'affichage du badge **Flow automatisé** est contrôlé par le paramètre **Afficher les données utilisateur de GitLab Credits**, disponible pour les [groupes](../user/group/manage.md#display-gitlab-credits-user-data) et les [instances](../administration/settings/visibility_and_access_controls.md#display-gitlab-credits-user-data).

### Plafonds d'utilisation {#usage-caps}

{{< history >}}

- [Introduits](https://gitlab.com/groups/gitlab-org/-/work_items/19881) dans GitLab 18.11 [avec un feature flag](../administration/feature_flags/_index.md) nommé `budget_caps_graphql_api`. Activés par défaut.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/607551) dans GitLab 19.3. Suppression du feature flag `budget_caps_graphql_api`.

{{< /history >}}

Vous pouvez définir un plafond mensuel de GitLab Credits au niveau de l'abonnement et de l'utilisateur pour éviter des frais de dépassement inattendus. Lorsque la consommation de crédits atteint le plafond configuré, l'accès aux fonctionnalités qui consomment des GitLab Credits (par exemple, GitLab Duo Agent Platform) est automatiquement suspendu jusqu'au début de la prochaine période de facturation, ou jusqu'à ce qu'un administrateur ajuste ou désactive le plafond.

Les types de plafonds suivants sont disponibles :

| Type de plafond | S'applique à | Sources de crédits comptabilisées | Géré via |
|---|---|---|---|
| Plafond de l'abonnement | Tous les utilisateurs de l'abonnement | À la demande uniquement | Portail clients |
| Plafond utilisateur fixe | Utilisateurs individuels (limite par défaut) | Tous | API GraphQL |
| Remplacement par utilisateur | Utilisation totale d'un utilisateur spécifique, y compris ses GitLab Credits inclus. Remplace le plafond fixe. Un utilisateur peut donc consommer jusqu'à la valeur la plus élevée entre son allocation incluse et son plafond. | Tous | API GraphQL |

Lorsque l'utilisation à la demande au cours de la période de facturation en cours atteint ou dépasse le plafond configuré, toutes les fonctionnalités Agent Platform (Duo Chat, Code Suggestions, Flows et Agents) sont suspendues pour tous les utilisateurs de cet abonnement ou de cette instance, et GitLab envoie une notification par e-mail aux gestionnaires de comptes de facturation. Pour les plafonds au niveau utilisateur, seul l'accès de l'utilisateur ayant atteint son plafond est suspendu.

Les plafonds utilisateur fixes et les plafonds de dérogation par utilisateur s'appliquent à l'utilisation au-delà de l'allocation incluse d'un utilisateur. Tant qu'un utilisateur dispose encore de GitLab Credits inclus, il peut continuer à consommer ses GitLab Credits inclus même après que son utilisation a atteint le plafond. Le plafond n'est appliqué qu'après épuisement des GitLab Credits inclus de l'utilisateur.

Les utilisateurs ayant atteint leur plafond ne peuvent pas accéder aux fonctionnalités de GitLab Duo Agent Platform jusqu'à ce que le plafond soit relevé ou que la prochaine période de facturation commence.

Les compteurs d'utilisation sont automatiquement réinitialisés au début de chaque période de facturation. Les valeurs de plafond sont reconduites d'une période de facturation à l'autre, sauf modification.

Les plafonds sont appliqués en utilisant les données d'utilisation les plus récentes disponibles. Les données n'étant pas en temps réel, une utilisation supplémentaire limitée de GitLab Credits peut survenir avant que la restriction n'entre en vigueur.

Les plafonds n'empêchent pas les utilisateurs de consommer leurs GitLab Credits inclus. L'application commence par utilisateur, et uniquement après épuisement de l'allocation incluse de cet utilisateur. Jusqu'à ce moment, l'utilisateur conserve un accès complet à GitLab Duo Agent Platform, quelle que soit la valeur du plafond, y compris un plafond de `0`.

Pour arrêter immédiatement toute consommation de GitLab Credits, quelle que soit la situation des soldes inclus, désactivez GitLab Duo pour les utilisateurs ou l'espace de nommage concernés.

La manière dont la valeur du plafond est appliquée dépend ensuite du type de plafond :

- Un **subscription-level cap** s'applique uniquement à l'utilisation à la demande. Le plafond correspond au montant d'utilisation à la demande autorisé pour l'ensemble de l'abonnement, en plus des GitLab Credits inclus de chaque utilisateur.
- Un **per-user cap** s'applique à l'utilisation totale d'un utilisateur, y compris ses GitLab Credits inclus. Un utilisateur peut donc consommer jusqu'à la valeur la plus élevée entre son allocation incluse et son plafond.

#### Exemples {#examples}

Pour un plafond au niveau de l'abonnement, prenons un abonnement comprenant 10 utilisateurs, chacun disposant de 100 GitLab Credits inclus. Le gestionnaire de compte de facturation définit le plafond à la demande au niveau de l'abonnement sur `0`.

- Un utilisateur qui a déjà utilisé la totalité de ses 100 GitLab Credits inclus est immédiatement bloqué pour accéder aux fonctionnalités Agent Platform (lors du prochain contrôle d'application), car toute utilisation supplémentaire serait à la demande.
- Un utilisateur qui n'a utilisé que 40 de ses GitLab Credits inclus peut continuer à utiliser les fonctionnalités Agent Platform et consommer ses 60 GitLab Credits inclus restants. Le plafond `0` ne leur est pas encore applicable.

Pour un plafond par utilisateur, prenons un utilisateur disposant de 24 GitLab Credits inclus.

- Avec un plafond par utilisateur de `50`, l'utilisateur est bloqué après 50 GitLab Credits au total, soit 26 GitLab Credits au-delà de son allocation incluse.
- Avec un plafond par utilisateur de `10`, l'utilisateur est bloqué après 24 GitLab Credits, lorsque son allocation incluse est épuisée.

#### Définir un plafond d'utilisation au niveau de l'abonnement {#set-a-subscription-level-usage-cap}

Prérequis :

- Vous devez être gestionnaire de compte de facturation.

1. Connectez-vous au [portail clients](https://customers.gitlab.com/).
1. Sur la carte d'abonnement, sélectionnez **Tableau de bord GitLab Credits**.
1. Sélectionnez **Spend controls**.
1. Dans le panneau **On-demand credit cap**, activez le bouton bascule **Set on-demand credit cap**.
1. Saisissez le nombre maximum de GitLab Credits à la demande autorisé par période de facturation.
1. Sélectionnez **Enregistrer les modifications**.

Si le plafond est défini en dessous du total d'utilisation à la demande actuellement déclaré pour la période de facturation en cours, il est considéré comme atteint dès le prochain contrôle de conformité.

Pour désactiver le plafond, désactivez le bouton bascule **Set on-demand credit cap**. Lorsque ce bouton est désactivé, aucun plafond de GitLab Credits à la demande n'est appliqué au niveau de l'abonnement, et le système revient au mode de facturation habituel.

Vous pouvez utiliser l'API GraphQL pour [consulter les plafonds d'utilisation](../api/graphql/reference/_index.md#gitlabsubscriptionbudgetcaps) et définir un [plafond fixe au niveau utilisateur](../api/graphql/reference/_index.md#mutationupsertflatusercap) ou un [plafond de remplacement par utilisateur](../api/graphql/reference/_index.md#mutationupsertuserbudgetcapoverrides).

### État du contrôle de l'utilisation {#usage-control-status}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/594635) dans GitLab 18.11.

{{< /history >}}

Lorsque les plafonds de crédits par utilisateur sont activés, l'onglet **Utilisation par utilisateur** du tableau de bord GitLab Credits affiche la colonne **État du contrôle d'utilisation**. Cette colonne indique si chaque utilisateur peut accéder aux fonctionnalités de [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md) ou s'il est bloqué parce qu'il a atteint son plafond de crédits.

La colonne **État du contrôle d'utilisation** affiche le statut **Bloqué** uniquement lorsque GitLab applique le plafond à l'encontre de l'utilisateur. GitLab applique le plafond après épuisement des GitLab Credits inclus de l'utilisateur. Un utilisateur qui a atteint son plafond mais dispose encore de GitLab Credits inclus a le statut **Normal**, car il peut continuer à consommer ses GitLab Credits inclus.

La colonne affiche l'un des statuts suivants :

| Statut | Description |
|--------|-------------|
| **Normal** | L'utilisateur n'a pas atteint son plafond de GitLab Credits, ou a atteint son plafond mais dispose encore de GitLab Credits inclus, et peut utiliser les fonctionnalités GitLab Duo Agent Platform. |
| **Bloqué : plafond de l'abonnement atteint** | L'utilisateur a atteint le plafond fixe par utilisateur défini au niveau de l'abonnement. |
| **Bloqué : plafond de l'utilisateur atteint** | L'utilisateur a atteint un plafond de remplacement par utilisateur défini spécifiquement pour lui. |

#### Débloquer un utilisateur ayant atteint son plafond de crédits {#unblock-a-user-who-reached-their-credit-cap}

Vous pouvez restaurer l'accès d'un utilisateur bloqué en utilisant l'API GraphQL de remplacement par utilisateur.

Pour débloquer un utilisateur, vous pouvez :

- Augmenter le plafond : définir un plafond de remplacement par utilisateur plus élevé afin que son utilisation soit inférieure à la nouvelle limite.
- Supprimer le plafond : supprimer le remplacement par utilisateur afin que l'utilisateur ne soit plus soumis à un plafond individuel.

Après la mise à jour du plafond, le statut de l'utilisateur passe à **Normal** et il peut à nouveau utiliser les fonctionnalités de GitLab Duo Agent Platform.

### Afficher les détails d'utilisation des crédits d'un utilisateur {#view-user-credit-usage-details}

{{< history >}}

- Lien vers les détails de session de GitLab Duo Agent Platform [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/579139) dans GitLab 18.10.

{{< /history >}}

Pour afficher les événements d'utilisation individuels d'un utilisateur dans une vue détaillée :

1. Dans le tableau de bord GitLab Credits, sélectionnez l'onglet **Utilisation par utilisateur**.
1. Dans la colonne **Utilisateur**, sélectionnez l'utilisateur que vous souhaitez consulter.
1. Pour afficher les détails de session, dans la colonne **Action**, sélectionnez l'action que vous souhaitez consulter.

> [!note]
> Les liens de session sont disponibles uniquement pour les événements d'utilisation de GitLab Duo Agent Platform déclenchés dans un projet et ayant un identifiant de session associé. Les événements d'utilisation déclenchés au sein d'un groupe, les événements hérités et les actions effectuées en dehors d'Agent Platform ne comportent pas de liens.

### Exporter les données d'utilisation {#export-usage-data}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/14504) dans GitLab 18.10.

{{< /history >}}

Vous pouvez exporter les données d'utilisation des crédits d'un abonnement sous forme de fichier CSV depuis le portail clients. Le fichier CSV répertorie les événements d'utilisation et les crédits utilisés chaque jour du mois en cours.

Prérequis :

- Vous devez être gestionnaire de compte de facturation.

1. Connectez-vous au [portail clients](https://customers.gitlab.com/).
1. Sur la carte d'abonnement, sélectionnez **Tableau de bord GitLab Credits**.
1. Dans la liste déroulante **Période d'utilisation**, sélectionnez la période pour laquelle vous souhaitez exporter les données.
1. Sélectionnez **Exporter les données d'utilisation**.
