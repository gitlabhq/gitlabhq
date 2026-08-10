---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Suivi des erreurs intégré
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com

{{< /details >}}

Ce guide fournit des informations de base sur la façon de configurer le suivi des erreurs intégré pour votre projet, en utilisant des exemples tirés de différents langages.

Le suivi des erreurs fourni par GitLab Observability est basé sur [Sentry SDK](https://docs.sentry.io/). Pour plus d'informations et des exemples sur la façon d'utiliser Sentry SDK dans votre application, consultez la [documentation Sentry SDK](https://docs.sentry.io/platforms/).

## Activer le suivi des erreurs pour un projet {#enable-error-tracking-for-a-project}

Quel que soit le langage de programmation que vous utilisez, vous devez d'abord activer le suivi des erreurs pour votre projet GitLab. Ce guide utilise l'instance `GitLab.com`.

Prérequis :

- Vous devez disposer d'un projet pour lequel vous souhaitez activer le suivi des erreurs. Découvrez comment [créer un projet](../user/project/_index.md).

Pour activer le suivi des erreurs avec GitLab comme backend :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Accédez à **Paramètres** > **Supervision**.
1. Développez **Suivi des erreurs**.
1. Pour **Activer le suivi d'erreur**, sélectionnez **Actif**.
1. Pour **Backend du suivi des erreurs**, sélectionnez **GitLab**.
1. Sélectionnez **Enregistrer les modifications**.
1. Copiez la chaîne **Data Source Name (DSN)**. Vous en aurez besoin pour configurer votre implémentation SDK.

## Configurer le suivi des utilisateurs {#configure-user-tracking}

Pour suivre le nombre d'utilisateurs affectés par une erreur :

- Dans le code d'instrumentation, assurez-vous que chaque utilisateur est identifié de manière unique. Vous pouvez utiliser un identifiant utilisateur, un nom, une adresse e-mail ou une adresse IP pour identifier un utilisateur.

Par exemple, si vous utilisez [Python](https://docs.sentry.io/platforms/python/enriching-events/identify-user/), vous pouvez identifier un utilisateur par e-mail :

```python
sentry_sdk.set_user({ email: "john.doe@example.com" });
```

Pour plus d'informations sur l'identification des utilisateurs, consultez la [documentation Sentry](https://docs.sentry.io/).

## Afficher les erreurs suivies {#view-tracked-errors}

Après que votre application a émis des erreurs vers l'API de suivi des erreurs via Sentry SDK, ces erreurs sont disponibles dans l'interface GitLab. Pour les afficher :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Accédez à **Supervision** > **Suivi des erreurs** pour voir la liste des erreurs ouvertes :

   ![MonitorListErrors](img/list_errors_v16_0.png)

1. Sélectionnez une erreur pour afficher la vue **Error details** :

   ![MonitorDetailErrors](img/detail_errors_v16_0.png)

   Cette page affiche plus de détails sur l'exception, notamment :

   - Nombre total d'occurrences.
   - Total des utilisateurs affectés.
   - Première occurrence : la date et le commit ({{< icon name="commit" >}}).
   - Date de dernière occurrence, affichée sous forme de date relative. Pour afficher l'horodatage, survolez la date.
   - Un graphique à barres de la fréquence des erreurs par heure. Pour afficher le nombre total d'erreurs sur une heure spécifique, survolez une barre.
   - Une trace de la pile d'appels.

### Créer un ticket à partir d'une erreur {#create-an-issue-from-an-error}

Si vous souhaitez suivre le travail lié à une erreur, vous pouvez créer un ticket directement depuis l'erreur :

- Depuis la vue **Error details**, sélectionnez **Créer un ticket**.

Un ticket est créé. La description du ticket contient la trace de la pile d'appels de l'erreur.

### Analyser les détails d'une erreur {#analyze-an-errors-details}

Pour afficher l'horodatage complet d'une erreur :

- Sur la page **Error details**, survolez la date **Vue pour la dernière fois**.

Dans l'exemple suivant, l'erreur s'est produite à 11 h 41 CEST :

![MonitorDetailErrors](img/last_seen_v16_10.png)

Le graphique **Dernières 24 heures** mesure le nombre de fois que cette erreur s'est produite par heure. En pointant sur la barre `11 am`, la boîte de dialogue indique que l'erreur a été observée 239 fois :

![MonitorDetailErrors](img/error_bucket_v16_10.png)

Le champ **Vue pour la dernière fois** ne se met pas à jour tant que l'heure complète n'est pas écoulée, en raison de la bibliothèque utilisée pour l'appel [`import * as timeago from 'timeago.js'`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/lib/utils/datetime/timeago_utility.js#L1).

## Émettre des erreurs {#emit-errors}

### SDK de langages pris en charge & types Sentry {#supported-language-sdks--sentry-types}

Le suivi des erreurs GitLab prend en charge ces types d'événements :

| Langage | Client SDK testé et version   | Point de terminaison   | Types d'éléments pris en charge              |
| -------- | ------------------------------- | ---------- | --------------------------------- |
| Go       | `sentry-go/0.20.0`              | `store`    | `exception`, `message`            |
| Java     | `sentry.java:6.18.1`            | `envelope` | `exception`, `message`            |
| NodeJS   | `sentry.javascript.node:7.38.0` | `envelope` | `exception`, `message`            |
| PHP      | `sentry.php/3.18.0`             | `store`    | `exception`, `message`            |
| Python   | `sentry.python/1.21.0`          | `envelope` | `exception`, `message`, `session` |
| Ruby     | `sentry.ruby:5.9.0`             | `envelope` | `exception`, `message`            |
| Rust     | `sentry.rust/0.31.0`            | `envelope` | `exception`, `message`, `session` |

Pour une version détaillée de ce tableau, consultez le [ticket 1737](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/1737).

Consultez également les [exemples de SDK de langages pris en charge](https://gitlab.com/gitlab-org/opstrace/opstrace/-/tree/main/test/sentry-sdk/testdata/supported-sdk-clients), qui montrent comment capturer des exceptions, des événements ou des messages avec ce SDK. Pour plus d'informations, consultez la [documentation Sentry SDK](https://docs.sentry.io/) pour un langage spécifique.

## Renouveler le DSN généré {#rotate-generated-dsn}

> [!warning]
> Selon Sentry, [il est sûr de garder un DSN public](https://docs.sentry.io/concepts/key-terms/dsn-explainer/#dsn-utilization), mais cela ouvre la possibilité que des événements indésirables soient envoyés à Sentry par des utilisateurs malveillants. Par conséquent, si possible, vous devriez garder le DSN secret. Cela ne s'applique pas aux applications côté client où le DSN sera chargé et donc stocké sur l'appareil de l'utilisateur.

Prérequis :

- Vous avez besoin de l'[identifiant de projet](../user/project/working_with_projects.md#find-the-project-id) numérique pour votre projet.

Pour renouveler le DSN Sentry :

1. [Créez un jeton d'accès](../user/profile/personal_access_tokens.md#create-a-personal-access-token) avec la portée `api`. Copiez cette valeur, car vous en aurez besoin dans les étapes suivantes.
1. Utilisez l'[API de suivi des erreurs](../api/error_tracking.md) pour créer un nouveau DSN Sentry, en remplaçant `<your_access_token>` et `<your_project_number>` par vos valeurs :

   ```shell
   curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_number>/error_tracking/client_keys"
   ```

1. Obtenez les clés client disponibles (DSN Sentry). Assurez-vous que votre nouveau DSN Sentry est en place. Exécutez la commande suivante avec l'identifiant de clé de l'ancienne clé client, en remplaçant `<your_access_token>` et `<your_project_number>` par vos valeurs :

   ```shell
   curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_number>/error_tracking/client_keys"
   ```

1. Supprimez l'ancienne clé client :

   ```shell
   curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_number>/error_tracking/client_keys/<key_id>"
   ```

## Déboguer les problèmes de SDK {#debug-sdk-issues}

La majorité des langages pris en charge par Sentry exposent une option `debug` dans le cadre de l'initialisation. L'option `debug` peut vous aider à déboguer les problèmes d'envoi des erreurs. D'autres options permettent d'afficher le JSON avant d'envoyer les données à l'API.

## Conservation des données {#data-retention}

GitLab applique une limite de conservation de 90 jours pour toutes les erreurs.

Pour laisser des commentaires sur les bugs ou les fonctionnalités du suivi des erreurs, commentez dans le [ticket de retour d'information](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2362) ou ouvrez un [nouveau ticket](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/new).
