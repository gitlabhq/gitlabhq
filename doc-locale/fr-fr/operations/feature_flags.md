---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Créer et gérer des feature flags personnalisés pour votre application.
title: Feature flags
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Avec les feature flags, vous pouvez déployer les nouvelles fonctionnalités de votre application en production par lots plus petits. Vous pouvez activer ou désactiver une fonctionnalité pour des sous-ensembles d'utilisateurs, ce qui vous aide à atteindre la livraison continue. Les feature flags aident à réduire les risques, en vous permettant d'effectuer des tests contrôlés et de séparer la livraison des fonctionnalités du lancement client.

Une [liste complète des feature flags](../administration/feature_flags/list.md) dans GitLab est également disponible.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour un exemple de feature flags en action, voir [Eliminating risk with feature flags](https://www.youtube.com/watch?v=U9WqoK9froI).
<!-- Video published on 2024-02-01 -->

Pour une démonstration interactive, voir [Feature Flags](https://tech-marketing.gitlab.io/static-demos/feature-flags/feature-flags-html.html).
<!-- Demo published on 2023-07-13 -->

## Utilisation des feature flags {#using-feature-flags}

GitLab propose une API compatible avec [Unleash](https://github.com/Unleash/unleash) pour les feature flags.

En activant ou désactivant un indicateur dans GitLab, votre application peut déterminer les fonctionnalités à activer ou désactiver.

Vous pouvez créer des feature flags dans GitLab et utiliser l'API depuis votre application pour obtenir la liste des feature flags et leurs statuts. L'application doit être configurée pour communiquer avec GitLab. Il appartient donc aux développeurs d'utiliser une bibliothèque cliente compatible et d'[intégrer les feature flags dans votre application](#integrate-feature-flags-with-your-application).

## Créer un feature flag {#create-a-feature-flag}

Pour créer et activer un feature flag :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Déployer** > **Feature flags**.
1. Sélectionnez **Nouveau feature flag**.
1. Saisissez un nom commençant par une lettre et contenant uniquement des lettres minuscules, des chiffres, des traits de soulignement (`_`), ou des tirets (`-`), et ne se terminant pas par un tiret (`-`) ou un trait de soulignement (`_`).
1. Facultatif. Saisissez une description (255 caractères maximum).
1. Ajoutez des [**Stratégies**](#feature-flag-strategies) de feature flag pour définir comment l'indicateur doit être appliqué. Pour chaque stratégie, indiquez le **Type** (par défaut [**Tous les utilisateurs**](#all-users)) et les **Environnements** (par défaut, tous les environnements).
1. Sélectionnez **Créer un indicateur de fonctionnalité**.

Pour modifier ces paramètres, sélectionnez **Éditer** ({{< icon name="pencil" >}}) à côté de n'importe quel feature flag dans la liste.

## Nombre maximum de feature flags {#maximum-number-of-feature-flags}

Le nombre maximum de feature flags par projet sur GitLab Self-Managed est de 200. Pour GitLab.com, le nombre maximum est déterminé par l'[édition](https://about.gitlab.com/pricing/) :

| Édition     | Feature flags par projet (GitLab.com) | Feature flags par projet (GitLab Self-Managed) |
|----------|----------------------------------|------------------------------------------|
| Gratuite     | 50                               | 200                                      |
| GitLab Premium  | 150                              | 200                                      |
| GitLab Ultimate | 200                              | 200                                      |

## Stratégies de feature flag {#feature-flag-strategies}

Vous pouvez appliquer une stratégie de feature flag dans plusieurs environnements, sans avoir à définir la stratégie plusieurs fois.

Les feature flags GitLab sont basés sur [Unleash](https://docs.getunleash.io/). Dans Unleash, il existe des [stratégies](https://docs.getunleash.io/reference/activation-strategies) pour un contrôle granulaire des feature flags. Les feature flags GitLab peuvent avoir plusieurs stratégies. Les stratégies prises en charge sont :

- [Tous les utilisateurs](#all-users)
- [Percent of Users](#percent-of-users)
- [ID des utilisateurs](#user-ids)
- [User List](#user-list)

Il est possible d'ajouter des stratégies aux feature flags lors de la [création d'un feature flag](#create-a-feature-flag), ou en modifiant un feature flag existant après sa création via **Déployer** > **Feature flags** et en sélectionnant **Éditer** ({{< icon name="pencil" >}}).

### Tous les utilisateurs {#all-users}

Active la fonctionnalité pour tous les utilisateurs. Il utilise la [stratégie](https://docs.getunleash.io/reference/activation-strategies#standard) d'activation Unleash Standard (`default`).

### Déploiement progressif {#percent-rollout}

Active la fonctionnalité pour un pourcentage de pages vues, avec une cohérence de comportement configurable. Cette cohérence est également connue sous le nom de stickiness. Il utilise la [stratégie](https://docs.getunleash.io/reference/activation-strategies#gradual-rollout) d'activation Unleash Gradual Rollout (`flexibleRollout`).

Vous pouvez configurer la cohérence en fonction de :

- **ID des utilisateurs** : chaque ID utilisateur a un comportement cohérent, en ignorant les ID de session.
- **Session IDs** : chaque ID de session a un comportement cohérent, en ignorant les ID utilisateur.
- **Aléatoire** : un comportement cohérent n'est pas garanti. La fonctionnalité est activée pour le pourcentage sélectionné de pages vues de façon aléatoire. Les ID utilisateur et les ID de session sont ignorés.
- **ID disponible** : un comportement cohérent est tenté en fonction du statut de l'utilisateur :
  - Si l'utilisateur est connecté, le comportement est rendu cohérent en fonction de l'ID utilisateur.
  - Si l'utilisateur est anonyme, le comportement est rendu cohérent en fonction de l'ID de session.
  - S'il n'y a pas d'ID utilisateur ni d'ID de session, la fonctionnalité est activée pour le pourcentage sélectionné de pages vues de façon aléatoire.

Par exemple, définissez une valeur de 15 % basée sur **ID disponible** pour activer la fonctionnalité pour 15 % des pages vues. Pour les utilisateurs authentifiés, cette valeur est basée sur leur ID utilisateur. Pour les utilisateurs anonymes disposant d'un ID de session, elle sera basée sur leur ID de session, car ils n'ont pas d'ID utilisateur. Si aucun ID de session n'est fourni, la méthode revient à l'aléatoire.

Le pourcentage de déploiement peut aller de 0 % à 100 %.

La sélection d'une cohérence basée sur les ID utilisateur fonctionne de la même manière que le déploiement [Percent of Users](#percent-of-users).

> [!warning]
> La sélection de **Aléatoire** entraîne un comportement d'application incohérent pour les utilisateurs individuels.

### Pourcentage d'utilisateurs {#percent-of-users}

Active la fonctionnalité pour un pourcentage d'utilisateurs authentifiés. Il utilise la stratégie d'activation Unleash [`gradualRolloutUserId`](https://docs.getunleash.io/reference/activation-strategies#gradual-rollout).

Par exemple, définissez une valeur de 15 % pour activer la fonctionnalité pour 15 % des utilisateurs authentifiés.

Le pourcentage de déploiement peut aller de 0 % à 100 %.

La stickiness (comportement cohérent de l'application pour le même utilisateur) est garantie pour les utilisateurs authentifiés, mais pas pour les utilisateurs anonymes.

Le [déploiement progressif](#percent-rollout) avec une cohérence basée sur les **ID des utilisateurs** a le même comportement. Vous devriez utiliser le déploiement progressif car il est plus flexible que le pourcentage d'utilisateurs.

> [!warning]
> Si la stratégie de pourcentage d'utilisateurs est sélectionnée, le client Unleash **doit** recevoir un ID utilisateur pour que la fonctionnalité soit activée. Consultez l'[exemple Ruby](#ruby-application-example) ci-dessous.

### ID des utilisateurs {#user-ids}

Active la fonctionnalité pour une liste d'utilisateurs cibles. Elle est implémentée à l'aide de la [stratégie](https://docs.getunleash.io/reference/activation-strategies#userids) d'activation Unleash UserIDs (`userWithId`).

Saisissez les ID utilisateur sous forme de liste de valeurs séparées par des virgules (par exemple, `user@example.com, user2@example.com`, ou `username1,username2,username3`, et ainsi de suite). Les ID utilisateur sont des identifiants pour les utilisateurs de votre application. Il n'est pas nécessaire qu'ils soient des utilisateurs GitLab.

> [!warning]
> Le client Unleash **doit** recevoir un ID utilisateur pour que la fonctionnalité soit activée pour les utilisateurs cibles. Consultez l'[exemple Ruby](#ruby-application-example) ci-dessous.

### Liste d'utilisateurs {#user-list}

Active la fonctionnalité pour des listes d'utilisateurs créées [dans l'interface des feature flags](#create-a-user-list), ou avec l'[API de liste d'utilisateurs de feature flag](../api/feature_flag_user_lists.md). Semblable aux [ID des utilisateurs](#user-ids), elle utilise la [stratégie](https://docs.getunleash.io/reference/activation-strategies#userids) d'activation Unleash UsersIDs (`userWithId`).

Vous ne pouvez pas désactiver une fonctionnalité spécifique pour un utilisateur, mais vous pouvez obtenir des résultats similaires en l'activant pour une liste d'utilisateurs.

Par exemple :

- `Full-user-list` = `User1A, User1B, User2A, User2B, User3A, User3B, ...`
- `Full-user-list-excluding-B-users` = `User1A, User2A, User3A, ...`

#### Créer une liste d'utilisateurs {#create-a-user-list}

Pour créer une liste d'utilisateurs :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Déployer** > **Feature flags**.
1. Sélectionnez **Afficher les listes d'utilisateurs**
1. Sélectionnez **Nouvelle liste d'utilisateurs**.
1. Saisissez un nom pour la liste.
1. Sélectionnez **Créer**.

Vous pouvez afficher les ID utilisateur d'une liste en sélectionnant **Éditer** ({{< icon name="pencil" >}}) à côté de celle-ci. Lorsque vous consultez une liste, vous pouvez la renommer en sélectionnant **Éditer** ({{< icon name="pencil" >}}).

#### Ajouter des utilisateurs à une liste d'utilisateurs {#add-users-to-a-user-list}

Pour ajouter des utilisateurs à une liste d'utilisateurs :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Déployer** > **Feature flags**.
1. Sélectionnez **Éditer** ({{< icon name="pencil" >}}) à côté de la liste à laquelle vous souhaitez ajouter des utilisateurs.
1. Sélectionnez **Ajouter des utilisateurs**.
1. Saisissez les ID utilisateur sous forme de liste de valeurs séparées par des virgules. Par exemple, `user@example.com, user2@example.com`, ou `username1,username2,username3`, et ainsi de suite.
1. Sélectionnez **Ajouter**.

#### Supprimer des utilisateurs d'une liste d'utilisateurs {#remove-users-from-a-user-list}

Pour supprimer des utilisateurs d'une liste d'utilisateurs :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Déployer** > **Feature flags**.
1. Sélectionnez **Éditer** ({{< icon name="pencil" >}}) à côté de la liste que vous souhaitez modifier.
1. Sélectionnez **Supprimer** ({{< icon name="remove" >}}) à côté de l'ID que vous souhaitez supprimer.

## Rechercher des références de code {#search-for-code-references}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour supprimer le feature flag du code lors du nettoyage, recherchez toutes les références du projet à cet indicateur.

Pour rechercher des références de code d'un feature flag :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Déployer** > **Feature flags**.
1. Modifiez le feature flag que vous souhaitez supprimer.
1. Sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Rechercher des références de code**.

## Désactiver un feature flag pour un environnement spécifique {#disable-a-feature-flag-for-a-specific-environment}

Pour désactiver un feature flag pour un environnement spécifique :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Déployer** > **Feature flags**.
1. Pour le feature flag que vous souhaitez désactiver, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Pour désactiver l'indicateur :
   - Pour chaque stratégie à laquelle il s'applique, sous **Environnements**, supprimez l'environnement.
1. Sélectionnez **Enregistrer les modifications**.

## Désactiver un feature flag pour tous les environnements {#disable-a-feature-flag-for-all-environments}

Pour désactiver un feature flag pour tous les environnements :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Déployer** > **Feature flags**.
1. Pour le feature flag que vous souhaitez désactiver, faites glisser le bouton de statut sur **Désactivé**.

Le feature flag s'affiche dans l'onglet **Désactivé**.

## Intégrer les feature flags à votre application {#integrate-feature-flags-with-your-application}

Pour utiliser des feature flags avec votre application, obtenez les identifiants d'accès auprès de GitLab. Préparez ensuite votre application avec une bibliothèque cliente.

### Obtenir les identifiants d'accès {#get-access-credentials}

Pour obtenir les identifiants d'accès dont votre application a besoin pour communiquer avec GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Déployer** > **Feature flags**.
1. Sélectionnez **Configurer** pour afficher les éléments suivants :
   - **URL de l'API** : URL à laquelle le client (application) se connecte pour obtenir la liste des feature flags.
   - **ID d'instance** : jeton unique qui autorise la récupération des feature flags.
   - **Nom de l'application** : le nom de l'environnement dans lequel l'application s'exécute (et non le nom de l'application elle-même).

     Par exemple, si l'application s'exécute sur un serveur de production, le **Nom de l'application** peut être `production` ou similaire. Cette valeur est utilisée pour l'évaluation des spécifications d'environnement.

La signification de ces champs peut évoluer avec le temps. Par exemple, **ID d'instance** peut être un jeton unique ou plusieurs jetons attribués à l'**Environnement**. De même, **Nom de l'application** peut décrire la version de l'application plutôt que l'environnement d'exécution.

### Choisir une bibliothèque cliente {#choose-a-client-library}

GitLab implémente un backend unique compatible avec les clients Unleash.

Avec le client Unleash, les développeurs peuvent définir, dans le code de l'application, les valeurs par défaut des indicateurs. Chaque évaluation de feature flag peut exprimer le résultat souhaité si l'indicateur n'est pas présent dans le fichier de configuration fourni.

Unleash [propose actuellement de nombreux SDK pour divers langages et frameworks](https://github.com/Unleash/unleash#unleash-sdks).

### Informations sur l'API des feature flags {#feature-flags-api-information}

Pour le contenu de l'API, voir :

- [API des feature flags](../api/feature_flags.md)
- [API des listes d'utilisateurs de feature flag](../api/feature_flag_user_lists.md)

### Exemple d'application Go {#go-application-example}

Voici un exemple d'intégration de feature flags dans une application Go :

```go
package main

import (
    "io"
    "log"
    "net/http"

    "github.com/Unleash/unleash-client-go/v3"
)

type metricsInterface struct {
}

func init() {
    unleash.Initialize(
        unleash.WithUrl("https://gitlab.com/api/v4/feature_flags/unleash/42"),
        unleash.WithInstanceId("29QmjsW6KngPR5JNPMWx"),
        unleash.WithAppName("production"), // Set to the running environment of your application
        unleash.WithListener(&metricsInterface{}),
    )
}

func helloServer(w http.ResponseWriter, req *http.Request) {
    if unleash.IsEnabled("my_feature_name") {
        io.WriteString(w, "Feature enabled\n")
    } else {
        io.WriteString(w, "hello, world!\n")
    }
}

func main() {
    http.HandleFunc("/", helloServer)
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

### Exemple d'application Ruby {#ruby-application-example}

Voici un exemple d'intégration de feature flags dans une application Ruby.

Le client Unleash reçoit un ID utilisateur à utiliser avec une stratégie de déploiement **Percent rollout (logged in users)** ou une liste de **Target Users**.

```ruby
#!/usr/bin/env ruby

require 'unleash'
require 'unleash/context'

unleash = Unleash::Client.new({
  url: 'http://gitlab.com/api/v4/feature_flags/unleash/42',
  app_name: 'production', # Set to the running environment of your application
  instance_id: '29QmjsW6KngPR5JNPMWx'
})

unleash_context = Unleash::Context.new
# Replace "123" with the ID of an authenticated user.
# The context's user ID must be a string:
# https://unleash.github.io/docs/unleash_context
unleash_context.user_id = "123"

if unleash.is_enabled?("my_feature_name", unleash_context)
  puts "Feature enabled"
else
  puts "hello, world!"
end
```

### Exemple de proxy Unleash {#unleash-proxy-example}

À partir de la version 0.2 du [proxy Unleash](https://docs.getunleash.io/reference/unleash-proxy), le proxy est compatible avec les feature flags.

Vous devriez utiliser le proxy Unleash pour la production sur GitLab.com. Consultez la [note sur les performances](#maximum-supported-clients-in-application-nodes) pour plus de détails.

Pour exécuter un conteneur Docker afin de vous connecter aux feature flags de votre projet, exécutez la commande suivante :

```shell
docker run \
  -e UNLEASH_PROXY_SECRETS=<secret> \
  -e UNLEASH_URL=<project feature flags URL> \
  -e UNLEASH_INSTANCE_ID=<project feature flags instance ID> \
  -e UNLEASH_APP_NAME=<project environment> \
  -e UNLEASH_API_TOKEN=<tokenNotUsed> \
  -p 3000:3000 \
  unleashorg/unleash-proxy
```

| Variable                    | Valeur                                                                                                                                |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `UNLEASH_PROXY_SECRETS`      | Secret partagé utilisé pour configurer un [client de proxy Unleash](https://docs.getunleash.io/reference/unleash-proxy#how-to-connect-to-the-proxy). |
| `UNLEASH_URL`         | L'URL de l'API de votre projet. Pour plus de détails, consultez [Obtenir les identifiants d'accès](#get-access-credentials). |
| `UNLEASH_INSTANCE_ID` | L'ID d'instance de votre projet. Pour plus de détails, consultez [Obtenir les identifiants d'accès](#get-access-credentials). |
| `UNLEASH_APP_NAME`    | Le nom de l'environnement dans lequel l'application s'exécute. Pour plus de détails, consultez [Obtenir les identifiants d'accès](#get-access-credentials). |
| `UNLEASH_API_TOKEN`   | Requis pour démarrer le proxy Unleash, mais non utilisé pour se connecter à GitLab. Peut être défini sur n'importe quelle valeur. |

Il existe une limitation lors de l'utilisation du proxy Unleash : chaque instance de proxy ne peut demander des indicateurs que pour l'environnement nommé dans `UNLEASH_APP_NAME`. Le proxy envoie cela à GitLab au nom du client, ce qui signifie que le client ne peut pas le remplacer.

## Tickets liés aux feature flags {#feature-flag-related-issues}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez lier des tickets associés à un feature flag. Dans la section **Linked issues** du feature flag, sélectionnez le bouton `+` et saisissez le numéro de référence du ticket ou l'URL complète du ticket. Les tickets apparaissent ensuite dans le feature flag associé, et inversement.

Cette fonctionnalité est similaire à la fonctionnalité des [tickets liés](../user/project/issues/related_issues.md).

## Facteurs de performance {#performance-factors}

Les feature flags GitLab peuvent être utilisés dans n'importe quelle application. Les applications volumineuses peuvent nécessiter une configuration avancée. Cette section explique les facteurs de performance pour aider votre organisation à identifier ce qui doit être fait avant d'utiliser la fonctionnalité. Pour plus d'informations, voir [Utilisation des feature flags](#using-feature-flags).

### Nombre maximum de clients pris en charge dans les nœuds d'application {#maximum-supported-clients-in-application-nodes}

GitLab accepte autant de requêtes clients que possible jusqu'à atteindre la [limite de débit](../security/rate_limits.md). L'API des feature flags est considérée comme **Unauthenticated traffic (from a given IP address)**. Pour GitLab.com, consultez les [limites spécifiques à GitLab.com](../user/gitlab_com/_index.md).

Le taux d'interrogation est configurable dans les SDK. Si tous les clients effectuent des requêtes depuis la même adresse IP :

- À raison d'une requête par minute, prend en charge environ 500 clients (8 RPS).
- À raison d'une requête toutes les 15 secondes, prend en charge environ 125 clients.

Pour les applications nécessitant une solution plus évolutive, vous devriez utiliser le [proxy Unleash](#unleash-proxy-example). Sur GitLab.com, vous devriez utiliser le proxy Unleash pour réduire le risque d'être soumis à une limite de débit sur les endpoints. Ce serveur proxy se situe entre le serveur et les clients. Il effectue des requêtes auprès du serveur au nom des groupes de clients, ce qui permet de réduire considérablement le nombre de requêtes sortantes. Si vous recevez toujours des réponses `429`, augmentez la valeur `UNLEASH_FETCH_INTERVAL` dans le proxy Unleash.

Il existe également un [ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/295472) pour augmenter la capacité de la limite de débit actuelle.

### Récupération après des erreurs réseau {#recovering-from-network-errors}

En général, les [clients Unleash](https://github.com/Unleash/unleash#unleash-sdks) disposent d'un mécanisme de repli lorsque le serveur renvoie un code d'erreur. Par exemple, `unleash-ruby-client` lit les données d'indicateur à partir de la sauvegarde locale afin que l'application puisse continuer à fonctionner dans son état actuel.

Consultez la documentation d'un projet SDK pour plus d'informations.

### GitLab Self-Managed {#gitlab-self-managed}

Sur le plan fonctionnel, il n'y a aucune différence. GitLab.com et GitLab Self-Managed se comportent de la même manière.

En termes d'évolutivité, tout dépend de la configuration de l'instance GitLab. GitLab.com utilise une architecture hautement évolutive pour gérer de nombreuses requêtes simultanées.

Cependant, les instances GitLab Self-Managed dont la capacité est insuffisante selon les [architectures de référence](../administration/reference_architectures/_index.md#additional-workloads) ne fourniront pas des performances comparables et peuvent même être surchargées par le trafic des feature flags. Tenez compte du nombre d'utilisateurs de votre application déployée _en plus_ de vos utilisateurs GitLab.
