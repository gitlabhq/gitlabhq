---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Démarrez un essai GitLab Ultimate sur GitLab.com ou GitLab Self-Managed.
title: Essais GitLab Ultimate
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

Vous pouvez obtenir une licence d'essai pour l'édition GitLab Ultimate.

Pendant la période d'essai, vous avez accès à presque toutes les fonctionnalités d'GitLab Ultimate.

Une licence d'essai pour GitLab Ultimate est valide pendant 30 jours.

L'essai commence lorsque vous recevez l'e-mail de confirmation contenant le code d'activation, et non lorsque vous l'activez.

Lorsque la période d'essai est terminée, vous perdez l'accès aux fonctionnalités payantes. Pour maintenir l'accès, vous pouvez [acheter un abonnement](manage_subscription.md#buy-a-subscription).

## Essais GitLab Duo Agent Platform {#gitlab-duo-agent-platform-trials}

Prérequis :

- Pour GitLab Self-Managed, vous devez disposer de GitLab 18.9 ou d'une version ultérieure.
- Pour GitLab.com, votre essai doit démarrer après le 10 février 2026.

Si vous utilisez l'édition Gratuite et que vous démarrez un essai GitLab Ultimate, votre essai inclut 24 [GitLab Credits](gitlab_credits.md#included-credits) par utilisateur. Vous pouvez utiliser les crédits pour tester les fonctionnalités de GitLab Duo Agent Platform.

Pour GitLab.com, si vous avez déjà [acheté un Monthly Commitment Pool](gitlab_credits.md#for-the-free-tier), aucun crédit supplémentaire ne vous est alloué pour la période d'essai. Les crédits utilisés pendant la période d'essai sont déduits du pool.

Les crédits sont valides pendant toute la durée de l'essai (30 jours). Les crédits non utilisés ne sont pas reportés si vous achetez un abonnement ou lorsque votre essai se termine. Si vous utilisez tous les crédits inclus avant la fin de votre essai, vous ne pouvez pas en obtenir davantage.

Si vous n'avez pas défini d'[espace de nommage GitLab Duo par défaut](../user/profile/preferences.md#set-a-default-gitlab-duo-namespace), vous ne pouvez pas utiliser les fonctionnalités d'IA nécessitant l'utilisation d'un point de terminaison proxy pendant votre essai. Cela inclut les agents externes et les appels directs à l'API `/v1/proxy` (par exemple, les CLI, les IDE ou les scripts personnalisés appelant le proxy avec un jeton GitLab). Cette restriction n'affecte pas Agentic Chat, ni les agents par défaut et personnalisés, ni les flows.

Si vous avez déjà démarré ou terminé un essai qui n'incluait pas de crédits, vous pouvez démarrer un nouvel essai :

- Si votre essai a expiré, vous pouvez démarrer un nouvel essai immédiatement.
- Si votre essai est encore actif, vous devez terminer votre période d'essai en cours avant d'en démarrer un nouveau.

Si vous utilisez l'édition GitLab Premium, votre essai ne fournit pas de crédits supplémentaires au-delà de vos crédits inclus existants par utilisateur. Vous pouvez demander des [crédits d'évaluation temporaires](gitlab_credits.md#temporary-evaluation-credits) supplémentaires pour tester les fonctionnalités de GitLab Duo Agent Platform.

## Démarrer un essai sur GitLab.com {#start-a-trial-on-gitlabcom}

Vous pouvez démarrer un essai même si vous n'avez pas encore créé de compte GitLab.

### Si vous n'avez pas de compte {#if-you-dont-have-an-account}

Si vous n'avez pas de compte GitLab, pour démarrer un essai gratuit :

1. Accédez à <https://gitlab.com/-/trial_registrations/new>.
1. Renseignez les détails du formulaire et sélectionnez **Continuer**.
1. Effectuez les étapes restantes et sélectionnez **Créer le projet**. Vous êtes redirigé vers votre nouveau projet et connecté en tant que le nouvel utilisateur que vous avez créé.
1. Dans la barre latérale gauche, en bas, un widget affiche le type de votre essai et le nombre de jours restants dans votre essai.

### Si vous avez déjà un compte {#if-you-already-have-an-account}

Si vous avez déjà un compte GitLab, vous pouvez démarrer un essai directement depuis les paramètres de votre groupe.

Prérequis :

- Vous devez disposer du rôle Propriétaire pour le groupe principal auquel l'essai doit être appliqué. La propriété indirecte via l'appartenance à un groupe n'est pas suffisante.
- Le groupe principal ne doit pas avoir bénéficié d'un essai précédent avec des GitLab Credits.

Pour démarrer un essai :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Facturation**.
1. Sélectionnez **Commencer un essai gratuit**.
1. Remplissez les champs.
1. Sélectionnez **Continuer**.
1. Sélectionnez le groupe auquel l'essai doit être appliqué.
1. Sélectionnez **Activer mon essai**.

Votre essai démarre immédiatement. Dans la barre latérale gauche, en bas, un widget affiche le type de votre essai et le nombre de jours restants dans votre essai.

## Démarrer un essai sur GitLab Self-Managed {#start-a-trial-on-gitlab-self-managed}

Pour démarrer un essai pour GitLab Self-Managed, remplissez un formulaire afin de recevoir une licence d'essai par e-mail.

Prérequis :

- Vous devez disposer d'une instance GitLab Self-Managed [installée](../install/_index.md) et configurée.
- Votre instance doit être en mesure de [synchroniser vos données d'abonnement](manage_subscription.md#subscription-data-synchronization) avec GitLab.
- Être administrateur.

Pour démarrer un essai :

1. Accédez à la page d'essai [GitLab Ultimate](https://about.gitlab.com/free-trial/?hosted=self-managed).
1. Remplissez les champs.
1. Sélectionnez **Commencer**.
1. Vérifiez votre e-mail pour obtenir le code d'activation de l'essai. L'e-mail contenant le code d'activation est envoyé peu après la soumission de la demande d'essai, à l'adresse e-mail fournie dans le formulaire de demande d'essai. Le code d'activation n'est valide que pour une seule utilisation.
1. Connectez-vous à GitLab en tant qu'administrateur.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Abonnement**.
1. Collez le code d'activation dans **Code d'activation**.
1. Lisez et acceptez les conditions d'utilisation.
1. Sélectionnez **Activer**.

L'abonnement est activé.

## Afficher les jours restants de la période d'essai {#view-remaining-trial-period-days}

Vous pouvez suivre le temps restant de votre période d'essai pour vous aider à planifier une mise à niveau de votre abonnement.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, en bas, un widget affiche le type de votre essai et le nombre de jours restants dans votre essai.
1. Sur GitLab Self-Managed, pour accéder aux informations sur les fonctionnalités disponibles lors de votre mise à niveau, sélectionnez **En savoir plus**.
