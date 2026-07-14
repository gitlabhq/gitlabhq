---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Mode silencieux de GitLab
description: Silence les communications sortantes de GitLab.
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/9826) dans GitLab 15.11. Cette fonctionnalité était une [expérience](../../policy/development_stages_support.md#experiment).
- L'activation et la désactivation du mode silencieux via l'interface Web ont été [introduites](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131090) dans GitLab 16.4.
- [Généralement disponible](../../policy/development_stages_support.md#generally-available) dans GitLab 16.6.

{{< /history >}}

Le mode silencieux vous permet de mettre en silence les communications sortantes, telles que les e-mails, depuis GitLab. Le mode silencieux n'est pas destiné à être utilisé dans des environnements en cours d'utilisation.

## Quand utiliser le mode silencieux {#when-to-use-silent-mode}

Le mode silencieux est conçu pour des scénarios de test et de validation spécifiques et ne doit pas être utilisé comme une fonctionnalité générique pour les environnements de production.

Le mode silencieux est conçu pour les scénarios suivants :

- Test de la promotion d'un site Geo :  Lors de la validation des procédures de reprise après sinistre en promouvant un site Geo secondaire tandis que le site principal reste actif.
  - Par exemple, vous disposez d'un site Geo secondaire dans le cadre de votre solution de [reprise après sinistre](../geo/disaster_recovery/_index.md). Vous souhaitez tester régulièrement sa promotion en tant que site Geo principal, conformément aux meilleures pratiques, afin de vous assurer que votre plan de reprise après sinistre fonctionne réellement. Mais vous ne souhaitez pas effectuer un basculement complet car le site principal se trouve dans une région qui offre la latence la plus faible à vos utilisateurs. Et vous ne voulez pas provoquer d'interruption de service lors de chaque test régulier. Ainsi, vous laissez le site principal en ligne, tout en promouvant le site secondaire. Vous commencez les tests de contrôle sur le site promu. Mais le site promu commence à envoyer des e-mails aux utilisateurs, les miroirs push transfèrent les modifications vers des dépôts Git externes, etc. C'est là qu'intervient le mode silencieux. Vous pouvez l'activer dans le cadre de la promotion du site, afin d'éviter ce problème.
- Validation des sauvegardes GitLab :  Lors du test de restauration de sauvegarde sur une instance de test distincte pour s'assurer que les sauvegardes sont fonctionnelles. Le mode silencieux peut être utilisé pour éviter l'envoi d'e-mails non valides aux utilisateurs.
- Test de l'environnement de staging :  Lorsque vous devez tester les fonctionnalités de GitLab sans déclencher de communications sortantes susceptibles d'affecter les utilisateurs ou les systèmes externes. En particulier si vous avez initialisé votre environnement de staging avec des données de production.

Le mode silencieux n'est pas conçu pour :

- Les environnements de production :  Le mode silencieux [désactive intentionnellement de nombreuses fonctionnalités GitLab](#behavior-of-gitlab-features-in-silent-mode). Le mode silencieux peut provoquer des erreurs inattendues, en particulier dans les nouvelles fonctionnalités. Le mode silencieux doit pécher par excès de prudence en bloquant par défaut les nouvelles communications.

## Activer le mode silencieux {#turn-on-silent-mode}

Prérequis :

- Vous devez disposer d'un accès administrateur.

Il existe plusieurs façons d'activer le mode silencieux :

- **Interface Web**

  1. Dans le coin supérieur droit, sélectionnez **Admin**.
  1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
  1. Développez **Silent Mode** et activez le bouton bascule **Enable Silent Mode**.
  1. Les modifications sont enregistrées immédiatement.

- [**API**](../../api/settings.md) :

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?silent_mode_enabled=true"
  ```

- [**Rails console**](../operations/rails_console.md#starting-a-rails-console-session) :

  ```ruby
  ::Gitlab::CurrentSettings.update!(silent_mode_enabled: true)
  ```

La prise d'effet peut prendre jusqu'à une minute. [Issue 405433](https://gitlab.com/gitlab-org/gitlab/-/issues/405433) propose de supprimer ce délai.

## Désactiver le mode silencieux {#turn-off-silent-mode}

Prérequis :

- Vous devez disposer d'un accès administrateur.

Il existe plusieurs façons de désactiver le mode silencieux :

- **Interface Web**

  1. Dans le coin supérieur droit, sélectionnez **Admin**.
  1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
  1. Développez **Silent Mode** et désactivez le bouton bascule **Enable Silent Mode**.
  1. Les modifications sont enregistrées immédiatement.

- [**API**](../../api/settings.md) :

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?silent_mode_enabled=false"
  ```

- [**Rails console**](../operations/rails_console.md#starting-a-rails-console-session) :

  ```ruby
  ::Gitlab::CurrentSettings.update!(silent_mode_enabled: false)
  ```

La prise d'effet peut prendre jusqu'à une minute. [Issue 405433](https://gitlab.com/gitlab-org/gitlab/-/issues/405433) propose de supprimer ce délai.

## Comportement des fonctionnalités GitLab en mode silencieux {#behavior-of-gitlab-features-in-silent-mode}

Cette section documente le comportement actuel de GitLab lorsque le mode silencieux est activé. Le travail pour la première itération du mode silencieux est suivi par l'epic [9826](https://gitlab.com/groups/gitlab-org/-/epics/9826).

Lorsque le mode silencieux est activé, une bannière s'affiche en haut de la page pour tous les utilisateurs, indiquant que le paramètre est activé et que **All outbound communications are blocked**.

### Communications sortantes mises en silence {#outbound-communications-that-are-silenced}

Les communications sortantes des fonctionnalités suivantes sont mises en silence par le mode silencieux.

| Fonctionnalité                                                                   | Notes                                                                                                                                                                                                                                                   |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [GitLab Duo](../../user/gitlab_duo/feature_summary.md)                         | Les fonctionnalités GitLab Duo ne peuvent pas contacter les fournisseurs de modèles de langage externes. |
| [Webhooks de projet et de groupe](../../user/project/integrations/webhooks.md) | Le déclenchement de tests de webhook via l'interface utilisateur entraîne des réponses avec le statut HTTP 500.                                                                                                                                                                               |
| [Hooks système](../system_hooks.md)                                        |                                                                                                                                                                                                                                                         |
| [Miroirs distants](../../user/project/repository/mirror/_index.md)           | Les pushs vers les miroirs distants sont ignorés. Les pulls depuis les miroirs distants sont ignorés.                                                                                                                                                                             |
| [Intégrations exécutables](../../user/project/integrations/_index.md)       | Les intégrations ne sont pas exécutées.                                                                                                                                                                                                                      |
| [Service Desk](../../user/project/service_desk/_index.md)                  | Les e-mails entrants génèrent toujours des tickets, mais les utilisateurs qui ont envoyé des e-mails au Service Desk ne sont pas notifiés de la création du ticket ou des commentaires sur leurs tickets.                                                                                                   |
| E-mails sortants                                                           | Au moment où un e-mail doit être envoyé par GitLab, il est supprimé à la place. Il n'est mis en file d'attente nulle part.                                                                                                                                                 |
| Requêtes HTTP sortantes                                                    | De nombreuses requêtes HTTP sont bloquées lorsque les fonctionnalités ne sont pas bloquées ou ignorées explicitement. Celles-ci peuvent produire des erreurs avec la classe `SilentModeBlockedError`. Si une erreur particulière est problématique pour les tests en mode silencieux, consultez [le support GitLab](https://about.gitlab.com/support/). En général, l'appelant doit quitter lorsque le mode silencieux est activé, plutôt que de tenter d'effectuer la requête HTTP. Toute exception doit être alignée avec les [utilisations prévues du mode silencieux](#when-to-use-silent-mode). |

### Communications sortantes non mises en silence {#outbound-communications-that-are-not-silenced}

Les communications sortantes des fonctionnalités suivantes ne sont pas mises en silence par le mode silencieux.

| Fonctionnalité                                                                                                     | Notes                                                                                                                                                                                                                                           |
| ----------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Proxy de dépendances](../packages/dependency_proxy.md)                                                         | L'extraction d'images non mises en cache sera effectuée depuis la source comme d'habitude. Prenez en compte les limites de débit d'extraction.                                                                                                                                              |
| [Hooks de fichiers](../file_hooks.md)                                                                              |                                                                                                                                                                                                                                                 |
| [Hooks de serveur](../server_hooks.md)                                                                          |                                                                                                                                                                                                                                                 |
| [Recherche avancée](../../integration/advanced_search/elasticsearch.md)                                       | Si deux instances GitLab utilisent la même instance de recherche avancée, elles peuvent toutes deux modifier les données de recherche. Il s'agit d'un scénario de split-brain qui peut survenir, par exemple, après la promotion d'un site Geo secondaire tandis que le site Geo principal est en ligne. |
| [Appels ClickHouse](../../integration/clickhouse.md)                                                         | Les requêtes ClickHouse ne sont pas mises en silence car elles sont considérées comme internes à un site.                                                                                                                                                            |
| Snowplow                                                                                                    | Une proposition existe dans l'[issue 409661](https://gitlab.com/gitlab-org/gitlab/-/issues/409661) pour mettre en silence ces requêtes.                                                                                                                                          |
| [Connexions Kubernetes obsolètes](../../user/clusters/agent/_index.md)                                    | Il existe [une proposition pour mettre en silence ces requêtes](https://gitlab.com/gitlab-org/gitlab/-/issues/396470).                                                                                                                                          |
| [Webhooks du registre de conteneurs](../packages/container_registry.md#configure-container-registry-notifications) | Il existe [une proposition pour mettre en silence ces requêtes](https://gitlab.com/gitlab-org/gitlab/-/issues/409682).                                                                                                                                          |
