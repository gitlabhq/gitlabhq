---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépannage de l'administration de l'application GitLab pour Jira Cloud"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Lors de l'administration de l'application GitLab pour Jira Cloud, vous pouvez rencontrer les problèmes suivants.

Pour le dépannage des utilisateurs, consultez [l'application GitLab pour Jira Cloud](../../integration/jira/connect-app.md#troubleshooting).

## Message de connexion affiché alors que vous êtes déjà connecté {#sign-in-message-displayed-when-already-signed-in}

Il est possible que vous receviez le message suivant vous invitant à vous connecter à GitLab.com alors que vous êtes déjà connecté :

```plaintext
Sign in or sign up before continuing.
```

L'application GitLab pour Jira Cloud utilise un iframe pour ajouter des groupes sur la page des paramètres. Certains navigateurs bloquent les cookies intersites, ce qui peut conduire à ce problème.

Pour résoudre ce problème, configurez [l'authentification OAuth](jira_cloud_app.md#set-up-oauth-authentication).

## Échec de l'installation manuelle {#manual-installation-fails}

Vous pouvez obtenir l'une des erreurs suivantes si vous avez installé l'application GitLab pour Jira Cloud depuis la liste officielle du Marketplace et l'avez remplacée par une [installation manuelle](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually) :

```plaintext
The app "gitlab-jira-connect-gitlab.com" could not be installed as a local app as it has previously been installed from Atlassian Marketplace
```

```plaintext
The app host returned HTTP response code 401 when we tried to contact it during installation. Please try again later or contact the app vendor.
```

Pour résoudre ce problème, désactivez le paramètre **URL du proxy Jira Connect**.

Prérequis :

- Accès administrateur.

Pour désactiver le paramètre **URL du proxy Jira Connect** :

- Dans GitLab 15.7 :
  1. Ouvrez une [console Rails](../operations/rails_console.md#starting-a-rails-console-session).
  1. Exécutez `ApplicationSetting.current_without_cache.update(jira_connect_proxy_url: nil)`.
- Dans GitLab 15.8 et versions ultérieures :
  1. Dans le coin supérieur droit, sélectionnez **Admin**.
  1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
  1. Développez **Application GitLab pour Jira**.
  1. Effacez le contenu du champ de texte **URL du proxy Jira Connect**.
  1. Sélectionnez **Sauvegarder les modifications**.

Si le problème persiste, vérifiez que votre instance peut se connecter à `connect-install-keys.atlassian.com` pour obtenir la clé publique d'Atlassian. Pour tester la connectivité, exécutez la commande suivante :

```shell
# A `404 Not Found` is expected because you're not passing a token
curl --head "https://connect-install-keys.atlassian.com"
```

## Consulter les modifications d'installation de l'application GitLab pour Jira Cloud {#review-installation-changes-to-the-gitlab-for-jira-cloud-app}

Il existe plusieurs méthodes pour consulter les modifications d'installation de l'application GitLab pour Jira Cloud. Pour plus d'informations, consultez la [documentation Jira](https://support.atlassian.com/jira/kb/how-to-check-who-installed-enabled-disabled-uninstalled-plugin-in-jira/) officielle.

## Échec de la synchronisation des données avec `Invalid JWT` {#data-sync-fails-with-invalid-jwt}

Si l'application GitLab pour Jira Cloud échoue continuellement à synchroniser les données de votre instance, un jeton secret est peut-être obsolète. Atlassian peut envoyer de nouveaux jetons secrets à GitLab. Si GitLab ne parvient pas à traiter ou à stocker ces jetons, une erreur `Invalid JWT` se produit.

Pour résoudre ce problème :

- Confirmez que l'instance est accessible publiquement par :
  - GitLab.com (si vous avez [installé l'application depuis la liste officielle de l'Atlassian Marketplace](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace)).
  - Jira Cloud (si vous avez [installé l'application manuellement](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)).
- Assurez-vous que la requête de jeton envoyée au point d'accès `/-/jira_connect/events/installed` lors de l'installation de l'application est accessible depuis Jira. La commande suivante doit renvoyer un `401 Unauthorized` :

  ```shell
  curl --include --request POST "https://gitlab.example.com/-/jira_connect/events/installed"
  ```

- Si votre instance a [SSL configuré](https://docs.gitlab.com/omnibus/settings/ssl/), vérifiez que vos [certificats sont valides et approuvés publiquement](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting/#useful-openssl-debugging-commands).

Selon la façon dont vous avez installé l'application, vous pouvez vérifier les éléments suivants :

- Si vous avez [installé l'application depuis la liste officielle de l'Atlassian Marketplace](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace), basculez entre les versions de GitLab dans l'application GitLab pour Jira Cloud :

  <!-- markdownlint-disable MD044 -->

  1. Dans Jira, sélectionnez les points de suspension horizontaux ({{< icon name="ellipsis_h" >}}) à côté de **Apps** et sélectionnez **Manage your apps**.

  1. Accédez à l'application en utilisant l'une de ces méthodes :

     **For instances with centralized app management :**

     1. Si le message « App management has moved to Administration » s'affiche, sélectionnez **Take me there**. Sinon, suivez les instructions **For instances with legacy app management** ci-dessous.
     1. Dans l'onglet **Installed apps**, localisez l'application **GitLab for Jira (gitlab.com)**, sélectionnez les points de suspension horizontaux ({{< icon name="ellipsis_h" >}}) puis sélectionnez **Démarrer**.

     **For instances with legacy app management :**

     1. Localisez l'application **GitLab for Jira (gitlab.com)**, sélectionnez le chevron ({{< icon name="chevron-right" >}}) puis sélectionnez **Démarrer**.

  1. Sélectionnez **Modifier la version de GitLab**.
  1. Sélectionnez **GitLab.com (SaaS)**, puis sélectionnez **Enregistrer**.
  1. Sélectionnez à nouveau **Modifier la version de GitLab**.
  1. Sélectionnez **GitLab (autogéré)**, puis sélectionnez **Suivant**.
  1. Cochez toutes les cases, puis sélectionnez **Suivant**.
  1. Saisissez votre **URL de l'instance GitLab**, puis sélectionnez **Enregistrer**.

  <!-- markdownlint-enable MD044 -->

  Si cette méthode ne fonctionne pas, [soumettez un ticket de support](https://support.gitlab.com/hc/en-us/requests/new) si vous êtes client Premium ou Ultimate. Fournissez l'URL de votre instance GitLab et l'URL de Jira. Le support GitLab peut essayer d'exécuter les scripts suivants pour résoudre le problème :

  ```ruby
  # Check if GitLab.com can connect to the GitLab Self-Managed instance
  checker = Gitlab::TcpChecker.new("gitlab.example.com", 443)

  # Returns `true` if successful
  checker.check

  # Returns an error if the check fails
  checker.error
  ```

  ```ruby
  # Locate the installation record for the GitLab Self-Managed instance
  installation = JiraConnectInstallation.find_by_instance_url("https://gitlab.example.com")

  # Try to send the token again from GitLab.com to the GitLab Self-Managed instance
  ProxyLifecycleEventService.execute(installation, :installed, installation.instance_url)
  ```

- Si vous avez [installé l'application manuellement](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually) :
  - Demandez au [support Jira Cloud](https://support.atlassian.com/jira-software-cloud/) de vérifier que Jira peut se connecter à votre instance.
  - [Réinstallez l'application](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually). Cette méthode peut supprimer toutes les [données synchronisées](../../integration/jira/connect-app.md#gitlab-data-synced-to-jira) du [panneau de développement Jira](../../integration/jira/development_panel.md).

## Erreur : `Failed to update the GitLab instance` {#error-failed-to-update-the-gitlab-instance}

Lorsque vous configurez l'application GitLab pour Jira Cloud, vous pouvez obtenir une erreur `Failed to update the GitLab instance` après avoir saisi l'URL de votre instance GitLab auto-hébergée.

Pour résoudre ce problème, assurez-vous que tous les prérequis de votre méthode d'installation sont satisfaits :

- [Prérequis pour la connexion de l'application GitLab pour Jira Cloud](jira_cloud_app.md#prerequisites)
- [Prérequis pour l'installation manuelle de l'application GitLab pour Jira Cloud](jira_cloud_app.md#prerequisites-1)

Si vous avez configuré une URL de proxy Jira Connect et que le problème persiste après vérification des prérequis, consultez [Débogage des problèmes de proxy Jira Connect](#debugging-jira-connect-proxy-issues).

Si vous utilisez GitLab 15.8 ou une version antérieure et avez précédemment activé les feature flags `jira_connect_oauth_self_managed` et `jira_connect_oauth`, vous devez désactiver le feature flag `jira_connect_oauth_self_managed` en raison d'un [problème connu](https://gitlab.com/gitlab-org/gitlab/-/issues/388943). Pour vérifier ces flags :

1. Ouvrez une [console Rails](../operations/rails_console.md#starting-a-rails-console-session).
1. Exécutez le code suivant :

   ```ruby
   # Check if both feature flags are enabled.
   # If the flags are enabled, these commands return `true`.
   Feature.enabled?(:jira_connect_oauth)
   Feature.enabled?(:jira_connect_oauth_self_managed)

   # If both flags are enabled, disable the `jira_connect_oauth_self_managed` flag.
   Feature.disable(:jira_connect_oauth_self_managed)
   ```

### Erreur : `Invalid audience` {#error-invalid-audience}

Si vous utilisez un [reverse proxy](jira_cloud_app.md#using-a-reverse-proxy), [`exceptions_json.log`](../logs/_index.md#exceptions_jsonlog) peut contenir un message du type :

```plaintext
Invalid audience. Expected https://proxy.example.com/-/jira_connect, received https://gitlab.example.com/-/jira_connect
```

Pour résoudre ce problème, définissez le FQDN du reverse proxy comme [audience JWT supplémentaire](jira_cloud_app.md#set-an-additional-jwt-audience).

### Débogage des problèmes de proxy Jira Connect {#debugging-jira-connect-proxy-issues}

Si vous définissez **URL du proxy Jira Connect** sur `https://gitlab.com` lors de la [configuration de votre instance](jira_cloud_app.md#set-up-your-instance-for-atlassian-marketplace-installation), vous pouvez :

- Inspecter le trafic réseau dans les outils de développement de votre navigateur.
- Reproduire l'erreur `Failed to update the GitLab instance` pour obtenir plus d'informations.

Vous devriez voir une requête `GET` vers `https://gitlab.com/-/jira_connect/installations`.

Cette requête devrait renvoyer un `200 OK`, mais elle peut renvoyer un `422 Unprocessable Entity` en cas de problème. Vous pouvez vérifier le corps de la réponse pour identifier l'erreur.

Si vous ne parvenez pas à résoudre le problème et que vous êtes client GitLab, contactez le [support GitLab](https://about.gitlab.com/support/) pour obtenir de l'aide. Fournissez au support GitLab :

- L'URL de votre instance GitLab auto-hébergée.
- Votre nom d'utilisateur GitLab.com.
- Facultatif. L'en-tête de réponse `X-Request-Id` pour la requête `GET` échouée vers `https://gitlab.com/-/jira_connect/installations`.
- Facultatif. [Un fichier HAR](https://support.zendesk.com/hc/en-us/articles/4408828867098-Generating-a-HAR-file-for-troubleshooting) que vous avez traité avec [`harcleaner`](https://gitlab.com/gitlab-com/support/toolbox/harcleaner) qui capture le problème.

Le support GitLab peut alors examiner le problème dans les journaux du serveur GitLab.com.

#### Support GitLab {#gitlab-support}

> [!note]
> Ces étapes ne peuvent être effectuées que par le support GitLab.

Chaque requête `GET` envoyée à l'URL du proxy Jira Connect `https://gitlab.com/-/jira_connect/installations` génère deux entrées de journal.

Pour localiser les entrées de journal pertinentes dans Kibana :

- Si vous disposez de la valeur `X-Request-Id` ou de l'identifiant de corrélation pour la requête `GET` vers `https://gitlab.com/-/jira_connect/installations`, les journaux [Kibana](https://log.gprd.gitlab.net/app/r/s/0FdPP) doivent être filtrés par `json.meta.caller_id: JiraConnect::InstallationsController#update`, `NOT json.status: 200` et `json.correlation_id: <X-Request-Id>`. Cela devrait renvoyer deux entrées de journal.

- Si vous disposez de l'URL auto-hébergée du client :
  1. Les journaux [Kibana](https://log.gprd.gitlab.net/app/r/s/QVsD4) doivent être filtrés par `json.meta.caller_id: JiraConnect::InstallationsController#update`, `NOT json.status: 200` et `json.params.value: {"instance_url"=>"https://gitlab.example.com"}`. L'URL auto-hébergée ne doit pas avoir de barre oblique finale. Cela devrait renvoyer l'une des entrées de journal.
  1. Ajoutez `json.correlation_id` au filtre.
  1. Supprimez le filtre `json.params.value`. Cela devrait renvoyer l'autre entrée de journal.

Pour le premier journal :

- `json.status` est `422 Unprocessable Entity`.
- `json.params.value` doit correspondre à l'URL GitLab auto-hébergée `[[FILTERED], {"instance_url"=>"https://gitlab.example.com"}]`.

Pour le deuxième journal, vous pouvez rencontrer l'un des scénarios suivants :

- Scénario 1 :
  - `json.message`, `json.jira_status_code` et `json.jira_body` sont présents.
  - `json.message` est `Proxy lifecycle event received error response` ou similaire.
  - `json.jira_status_code` et `json.jira_body` peuvent contenir la réponse reçue de l'instance GitLab auto-hébergée ou d'un proxy en amont de l'instance.
  - Si `json.jira_status_code` est `401 Unauthorized` et `json.jira_body` est `(empty)` :
    - [**URL du proxy Jira Connect**](jira_cloud_app.md#set-up-your-instance-for-atlassian-marketplace-installation) n'est peut-être pas défini sur `https://gitlab.com`.
    - L'instance GitLab auto-hébergée bloque peut-être les connexions sortantes. Assurez-vous que votre instance GitLab auto-hébergée peut se connecter à `connect-install-keys.atlassian.com` et à `gitlab.com`.
    - L'instance GitLab auto-hébergée ne peut pas déchiffrer le jeton JWT de Jira. [À partir de GitLab 16.11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147234) , [`exceptions_json.log`](../logs/_index.md#exceptions_jsonlog) contient plus d'informations sur l'erreur.
    - Si un [reverse proxy](jira_cloud_app.md#using-a-reverse-proxy) se trouve devant votre instance GitLab auto-hébergée, l'en-tête `Host` envoyé à l'instance GitLab auto-hébergée peut ne pas correspondre au FQDN du reverse proxy. Vérifiez les [journaux Workhorse](../logs/_index.md#workhorse-logs) sur l'instance GitLab auto-hébergée :

      ```shell
      grep /-/jira_connect/events/installed /var/log/gitlab/gitlab-workhorse/current
      ```

      La sortie peut contenir les éléments suivants :

      ```json
      {
        "host":"gitlab.mycompany.com:443", // The host should match the reverse proxy FQDN entered into the GitLab for Jira Cloud app
        "remote_ip":"34.74.226.3", // This IP should be within the GitLab.com IP range https://docs.gitlab.com/user/gitlab_com/#ip-range
        "status":401,
        "uri":"/-/jira_connect/events/installed"
      }
      ```

  - Si `json.jira_status_code` est `404 Not Found` et que `json.jira_body` contient le code HTML d'une page 404 GitLab standard, confirmez que la [liste d'autorisation des intégrations](project_integration_management.md#integration-allowlist) sur l'instance auto-hébergée autorise l'application GitLab pour Jira Cloud.

- Scénario 2 :
  - `json.exception.class` et `json.exception.message` sont présents.
  - `json.exception.class` et `json.exception.message` indiquent si un problème est survenu lors de la communication avec l'instance GitLab auto-hébergée.

## Erreur : `The Jira user is not a site or organization administrator` {#error-the-jira-user-is-not-a-site-or-organization-administrator}

Lorsque vous essayez de lier un groupe GitLab, vous pouvez obtenir l'une des erreurs suivantes :

```plaintext
The Jira user is not a site or organization administrator. Check the permissions in Jira and try again.
```

```plaintext
Failed to link group. Please try again.
```

Ce problème se produit lorsque l'utilisateur Jira n'est pas membre du groupe `site-admins` ou `org-admins`. GitLab vérifie l'appartenance au groupe en appelant le point d'accès de l'API Jira `/rest/api/3/user?expand=groups` et en vérifiant que l'utilisateur appartient à l'un de ces deux groupes.

Un utilisateur peut apparaître comme administrateur de site dans [l'organisation Atlassian](https://admin.atlassian.com) et disposer de tous les privilèges d'administrateur, mais s'il n'est pas explicitement ajouté au groupe `site-admins` ou `org-admins`, la vérification des autorisations GitLab échoue. Cela signifie également que les privilèges d'administrateur attribués via des groupes personnalisés ou des rôles spécifiques à un produit ne sont pas détectés par GitLab.

Pour résoudre ce problème, ajoutez l'utilisateur Jira au groupe `org-admins` ou `site-admins` :

1. Connectez-vous à votre [organisation Atlassian](https://admin.atlassian.com).
1. Accédez à **Répertoire** > **Groupes**.
1. Sélectionnez le groupe `org-admins` (recommandé) ou le groupe `site-admins`. Si le groupe n'existe pas, [créez-le](https://support.atlassian.com/user-management/docs/create-groups/).
1. Ajoutez l'utilisateur Jira au groupe.

Pour plus d'informations sur les exigences relatives aux utilisateurs Jira, consultez [Exigences relatives aux utilisateurs Jira](jira_cloud_app.md#jira-user-requirements).

GitLab ne peut pas utiliser l'API des autorisations de Jira pour vérifier directement le statut d'administrateur en raison des limitations de portée OAuth. Pour plus de contexte, consultez le [ticket #420687](https://gitlab.com/gitlab-org/gitlab/-/issues/420687) et le [merge request !135771](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135771).

## Erreur : `Failed to link group` {#error-failed-to-link-group}

Lorsque vous liez un groupe, vous pouvez obtenir l'erreur suivante :

```plaintext
Failed to link group. Please try again.
```

Cette erreur peut être renvoyée pour plusieurs raisons.

- Un `403 Forbidden` peut être renvoyé si les informations de l'utilisateur ne peuvent pas être récupérées depuis Jira en raison de permissions insuffisantes. Pour résoudre ce problème, assurez-vous que l'utilisateur Jira qui installe et configure l'application remplit certaines [exigences](jira_cloud_app.md#jira-user-requirements).

- Cette erreur peut également se produire si vous utilisez une réécriture ou un sous-filtre avec un [reverse proxy](jira_cloud_app.md#using-a-reverse-proxy). La clé d'application utilisée dans les requêtes contient une partie du nom d'hôte du serveur, que certains filtres de reverse proxy peuvent capturer. La clé d'application dans Atlassian et GitLab doit correspondre pour que l'authentification fonctionne correctement.

- Cette erreur peut se produire si l'instance GitLab a été initialement mal configurée lors de la première installation de l'application GitLab pour Jira Cloud. Dans ce cas, les données de la table `jira_connect_installation` peuvent devoir être supprimées. Ne supprimez ces données que si vous êtes certain qu'aucune installation existante de l'application GitLab pour Jira ne doit être conservée.

  1. Désinstallez l'application GitLab pour Jira Cloud de tous les projets Jira.
  1. Pour supprimer les enregistrements, exécutez cette commande dans la [console Rails GitLab](../operations/rails_console.md#starting-a-rails-console-session) :

     ```ruby
     JiraConnectInstallation.delete_all
     ```

## Erreur : `Failed to load Jira Connect Application ID` {#error-failed-to-load-jira-connect-application-id}

Lorsque vous vous connectez à l'application GitLab pour Jira Cloud après avoir pointé l'application vers votre instance GitLab auto-hébergée, vous pouvez obtenir l'erreur suivante :

```plaintext
Failed to load Jira Connect Application ID. Please try again.
```

Lorsque vous vérifiez la console du navigateur, vous pouvez également voir le message suivant :

```plaintext
Cross-Origin Request Blocked: The Same Origin Policy disallows reading the remote resource at https://gitlab.example.com/-/jira_connect/oauth_application_id. (Reason: CORS header 'Access-Control-Allow-Origin' missing). Status code: 403.
```

Pour résoudre ce problème :

1. Assurez-vous que `/-/jira_connect/oauth_application_id` est accessible publiquement et renvoie une réponse JSON :

   ```shell
   curl --include "https://gitlab.example.com/-/jira_connect/oauth_application_id"
   ```

1. Si vous avez [installé l'application depuis la liste officielle de l'Atlassian Marketplace](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace), assurez-vous que [**URL du proxy Jira Connect**](jira_cloud_app.md#set-up-your-instance-for-atlassian-marketplace-installation) est défini sur `https://gitlab.com` sans barre oblique de fin.

## Erreur : `Missing required parameter: client_id` {#error-missing-required-parameter-client_id}

Lorsque vous vous connectez à l'application GitLab pour Jira Cloud après avoir pointé l'application vers votre instance GitLab auto-hébergée, vous pouvez obtenir l'erreur suivante :

```plaintext
Missing required parameter: client_id
```

Pour résoudre ce problème, assurez-vous que tous les prérequis de votre méthode d'installation sont satisfaits :

- [Prérequis pour la connexion de l'application GitLab pour Jira Cloud](jira_cloud_app.md#prerequisites)
- [Prérequis pour l'installation manuelle de l'application GitLab pour Jira Cloud](jira_cloud_app.md#prerequisites-1)

## Erreur : `Failed to sign in to GitLab` {#error-failed-to-sign-in-to-gitlab}

Lorsque vous vous connectez à l'application GitLab pour Jira Cloud après avoir pointé l'application vers votre instance GitLab auto-hébergée, vous pouvez obtenir l'erreur suivante :

```plaintext
Failed to sign in to GitLab
```

Pour résoudre ce problème, assurez-vous que les cases **Fiables** et **Confidentiel** sont décochées dans l'[application OAuth](jira_cloud_app.md#set-up-oauth-authentication) créée pour l'application. Si l'erreur persiste, consultez le [ticket 581765](https://gitlab.com/gitlab-org/gitlab/-/work_items/581765).

Si vous utilisez Google Chrome pour l'application, essayez d'utiliser un autre navigateur.
