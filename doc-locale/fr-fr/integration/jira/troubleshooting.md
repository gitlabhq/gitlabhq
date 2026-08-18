---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépannage de l'intégration des tickets Jira"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous utilisez l'[intégration des tickets Jira](configure.md), vous pouvez rencontrer les problèmes suivants.

## GitLab ne peut pas établir de lien vers un ticket Jira {#gitlab-cannot-link-to-a-jira-issue}

Lorsque vous mentionnez un identifiant de ticket Jira dans GitLab, le lien vers le ticket peut être absent. [`sidekiq.log`](../../administration/logs/_index.md#sidekiq-logs) peut contenir l'exception suivante :

```plaintext
No Link Issue Permission for issue 'JIRA-1234'
```

Pour résoudre ce problème, assurez-vous que l'utilisateur Jira que vous avez créé pour l'[intégration des tickets Jira](configure.md) dispose de l'autorisation de lier des tickets.

## GitLab ne peut pas commenter un ticket Jira {#gitlab-cannot-comment-on-a-jira-issue}

Si GitLab ne peut pas commenter un ticket Jira, assurez-vous que l'utilisateur Jira que vous avez créé pour l'[intégration des tickets Jira](configure.md) dispose de l'autorisation de :

- Publier des commentaires sur un ticket Jira
- Effectuer la transition du ticket Jira

Lorsque le [gestionnaire de tickets GitLab](../external-issue-tracker.md) est désactivé, les références aux tickets Jira et les commentaires ne fonctionnent pas. Si vous [restreignez les adresses IP pour l'accès à Jira](https://support.atlassian.com/security-and-access-policies/docs/specify-ip-addresses-for-product-access/), assurez-vous d'ajouter vos adresses IP GitLab Self-Managed ou vos [adresses IP GitLab](../../user/gitlab_com/_index.md#ip-range) à la liste d'autorisation dans Jira.

Pour identifier la cause principale, consultez le fichier [`integrations_json.log`](../../administration/logs/_index.md#integrations_jsonlog). Lorsque GitLab tente de commenter un ticket Jira, une entrée de journal `Error sending message` peut apparaître.

Dans GitLab 16.1 et versions ultérieures, en cas d'erreur, le fichier `integrations_json.log` contient des clés `client_*` dans la requête API sortante vers Jira. Vous pouvez utiliser les clés `client_*` pour consulter la [documentation de l'API Atlassian](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/#api-group-issues) afin de comprendre pourquoi l'erreur s'est produite.

Dans l'exemple suivant, Jira répond avec un `404 Not Found`. Cette erreur peut se produire si :

- L'utilisateur Jira que vous avez créé pour l'intégration des tickets Jira ne dispose pas de l'autorisation d'afficher le ticket.
- L'identifiant de ticket Jira que vous avez spécifié n'existe pas.

```json
{
  "severity": "ERROR",
  "time": "2023-07-25T21:38:56.510Z",
  "message": "Error sending message",
  "client_url": "https://my-jira-cloud.atlassian.net",
  "client_path": "/rest/api/2/issue/ALPHA-1",
  "client_status": "404",
  "exception.class": "JIRA::HTTPError",
  "exception.message": "Not Found",
}
```

Pour plus d'informations sur les codes de statut renvoyés, consultez la [documentation de l'API REST de la plateforme Jira Cloud](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issues/#api-rest-api-2-issue-issueidorkey-get-response).

### Utilisation de `curl` pour vérifier l'accès à un ticket Jira {#using-curl-to-verify-access-to-a-jira-issue}

Pour vérifier qu'un utilisateur Jira peut accéder à un ticket Jira spécifique, exécutez le script suivant :

```shell
curl --verbose --user "$USER:$API_TOKEN" "https://$ATLASSIAN_SUBDOMAIN.atlassian.net/rest/api/2/issue/$JIRA_ISSUE"
```

Si l'utilisateur peut accéder au ticket, Jira répond avec un `200 OK` et le JSON renvoyé inclut les détails du ticket Jira.

### Vérifier que GitLab peut publier un commentaire sur un ticket Jira {#verify-gitlab-can-post-a-comment-to-a-jira-issue}

> [!warning]
> Les commandes qui modifient des données peuvent causer des dommages si elles ne sont pas exécutées correctement ou dans les bonnes conditions. Exécutez toujours les commandes dans un environnement de test en premier et disposez d'une instance de sauvegarde prête à être restaurée.

Pour faciliter le dépannage de votre intégration des tickets Jira, vous pouvez vérifier si GitLab peut publier un commentaire sur un ticket Jira à l'aide des paramètres d'intégration Jira du projet.

Pour ce faire :

- Depuis une [console Rails](../../administration/operations/rails_console.md#starting-a-rails-console-session), exécutez la commande suivante :

  ```ruby
  jira_issue_id = "ALPHA-1" # Change to your Jira issue ID
  project = Project.find_by_full_path("group/project") # Change to your project's path

  integration = project.integrations.find_by(type: "Integrations::Jira")
  jira_issue = integration.client.Issue.find(jira_issue_id)
  jira_issue.comments.build.save!(body: 'This is a test comment from GitLab via the Rails console')
  ```

Si la commande réussit, un commentaire est ajouté au ticket Jira.

## GitLab ne peut pas créer un ticket Jira {#gitlab-cannot-create-a-jira-issue}

Lorsque vous essayez de créer un ticket Jira à partir d'une vulnérabilité, vous pourriez voir une erreur « champ obligatoire ». Par exemple, `Components is required` car un champ nommé « Components » est manquant. Cela se produit parce que Jira a des champs obligatoires configurés qui ne sont pas transmis par GitLab. Pour contourner ce problème :

1. Créez un nouveau [type de ticket](https://support.atlassian.com/jira-cloud-administration/docs/what-are-issue-types/) « Vulnerability » dans l'instance Jira.
1. Attribuez le nouveau type de ticket au projet.
1. Modifiez le schéma de champs pour tous les tickets « Vulnerabilities » du projet afin qu'ils ne requièrent pas le champ manquant.

## GitLab ne peut pas fermer un ticket Jira {#gitlab-cannot-close-a-jira-issue}

Si GitLab ne peut pas fermer un ticket Jira :

- Assurez-vous que l'identifiant de transition que vous avez défini dans les paramètres Jira correspond à celui que votre projet doit avoir pour fermer un ticket. Pour plus d'informations, consultez les [transitions de tickets automatiques](issues.md#automatic-issue-transitions) et les [transitions de tickets personnalisées](issues.md#custom-issue-transitions).
- Assurez-vous que le ticket Jira n'est pas déjà marqué comme résolu :
  - Vérifiez que le champ de résolution du ticket Jira n'est pas défini.
  - Vérifiez que le ticket n'est pas barré dans les listes Jira.

## CAPTCHA après des tentatives de connexion échouées {#captcha-after-failed-sign-in-attempts}

Un CAPTCHA peut être déclenché après des tentatives de connexion consécutives échouées. Ces tentatives échouées peuvent entraîner une erreur `401 Unauthorized` lors du test des paramètres d'intégration des tickets Jira. Si le CAPTCHA a été déclenché, vous ne pouvez pas utiliser l'API REST Jira pour vous authentifier auprès du site Jira.

Pour résoudre ce problème, connectez-vous à votre instance Jira et complétez le CAPTCHA.

## L'intégration ne fonctionne pas pour un projet importé {#integration-does-not-work-for-an-imported-project}

Dans GitLab 19.0 et versions antérieures, l'intégration des tickets Jira peut ne pas fonctionner pour un projet importé. Pour plus d'informations, consultez le [ticket 341571](https://gitlab.com/gitlab-org/gitlab/-/issues/341571).

Pour résoudre ce problème, désactivez puis réactivez l'intégration.

## Erreur : `certificate verify failed` {#error-certificate-verify-failed}

Lorsque vous testez les paramètres d'intégration des tickets Jira, vous pourriez obtenir l'erreur suivante :

```plaintext
Connection failed. Check your integration settings. SSL_connect returned=1 errno=0 peeraddr=<jira.example.com> state=error: certificate verify failed (unable to get local issuer certificate)
```

Cette erreur peut également apparaître dans le fichier [`integrations_json.log`](../../administration/logs/_index.md#integrations_jsonlog) :

```json
{
  "severity":"ERROR",
  "integration_class":"Integrations::Jira",
  "message":"Error sending message",
  "exception.class":"OpenSSL::SSL::SSLError",
  "exception.message":"SSL_connect returned=1 errno=0 peeraddr=x.x.x.x:443 state=error: certificate verify failed (unable to get local issuer certificate)",
}
```

L'erreur se produit parce que le certificat Jira n'est pas approuvé publiquement ou que la chaîne de certificats est incomplète. Tant que ce problème n'est pas résolu, GitLab ne se connecte pas à Jira.

Pour résoudre ce problème, consultez les [erreurs SSL courantes](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting/#common-ssl-errors).

## Modifier tous les projets Jira pour utiliser des valeurs au niveau de l'instance ou du groupe {#change-all-jira-projects-to-instance-level-or-group-level-values}

> [!warning]
> Les commandes qui modifient des données peuvent causer des dommages si elles ne sont pas exécutées correctement ou dans les bonnes conditions. Exécutez toujours les commandes dans un environnement de test en premier et disposez d'une instance de sauvegarde prête à être restaurée.

### Modifier tous les projets sur une instance {#change-all-projects-on-an-instance}

Pour modifier tous les projets Jira afin d'utiliser les paramètres d'intégration au niveau de l'instance :

1. Dans une [console Rails](../../administration/operations/rails_console.md#starting-a-rails-console-session), exécutez la commande suivante :

   ```ruby
   Integrations::Jira.where(active: true, instance: false, inherit_from_id: nil).find_each do |integration|
     default_integration = Integration.default_integration(integration.type, integration.project)

     integration.inherit_from_id = default_integration.id

     if integration.save(context: :manual_change)
       if Gitlab.version_info >= Gitlab::VersionInfo.new(16, 9)
         Integrations::Propagation::BulkUpdateService.new(default_integration, [integration]).execute
       else
         BulkUpdateIntegrationService.new(default_integration, [integration]).execute
       end
     end
   end
   ```

1. Modifiez et enregistrez l'intégration au niveau de l'instance depuis l'interface utilisateur pour propager les modifications à toutes les intégrations au niveau du groupe et du projet.

### Modifier tous les projets dans un groupe {#change-all-projects-in-a-group}

Pour modifier tous les projets Jira d'un groupe (et de ses sous-groupes) afin d'utiliser les paramètres d'intégration au niveau du groupe :

- Dans une [console Rails](../../administration/operations/rails_console.md#starting-a-rails-console-session), exécutez la commande suivante :

  ```ruby
  def reset_integration(target)
    integration = target.integrations.find_by(type: Integrations::Jira)

    return if integration.nil? # Skip if the project has no Jira issues integration
    return unless integration.inherit_from_id.nil? # Skip integrations that are already inheriting

    default_integration = Integration.default_integration(integration.type, target)

    integration.inherit_from_id = default_integration.id

    if integration.save(context: :manual_change)
      if Gitlab.version_info >= Gitlab::VersionInfo.new(16, 9)
        Integrations::Propagation::BulkUpdateService.new(default_integration, [integration]).execute
      else
        BulkUpdateIntegrationService.new(default_integration, [integration]).execute
      end
    end
  end

  parent_group = Group.find_by_full_path('top-level-group') # Add the full path of your top-level group
  current_user = User.find_by_username('admin-user') # Add the username of a user with administrator access

  unless parent_group.nil?
    groups = GroupsFinder.new(current_user, { parent: parent_group, include_parent_descendants: true }).execute

    # Reset any projects in subgroups to use the parent group integration settings
    groups.find_each do |group|
      reset_integration(group)

      group.projects.find_each do |project|
        reset_integration(project)
      end
    end

    # Reset any direct projects in the parent group to use the parent group integration settings
    parent_group.projects.find_each do |project|
      reset_integration(project)
    end
  end
  ```

## Mettre à jour le mot de passe de l'intégration pour tous les projets {#update-the-integration-password-for-all-projects}

> [!warning]
> Les commandes qui modifient des données peuvent causer des dommages si elles ne sont pas exécutées correctement ou dans les bonnes conditions. Exécutez toujours les commandes dans un environnement de test en premier et disposez d'une instance de sauvegarde prête à être restaurée.

Pour réinitialiser le mot de passe de l'utilisateur Jira pour tous les projets avec des intégrations de tickets Jira actives, exécutez la commande suivante dans une [console Rails](../../administration/operations/rails_console.md#starting-a-rails-console-session) :

```ruby
p = Project.find_by_sql("SELECT p.id FROM projects p LEFT JOIN integrations i ON p.id = i.project_id WHERE i.type_new = 'Integrations::Jira' AND i.active = true")

p.each do |project|
  project.jira_integration.update_attribute(:password, '<your-new-password>')
end
```

## Liste des tickets Jira {#jira-issue-list}

Lorsque vous [consultez les tickets Jira](configure.md#view-jira-issues) dans GitLab, vous pouvez rencontrer les problèmes suivants.

### Erreur : `500 We're sorry` {#error-500-were-sorry}

Lorsque vous accédez à un ticket Jira dans GitLab, vous pourriez obtenir une erreur `500 We're sorry. Something went wrong on our end`. Consultez [`production.log`](../../administration/logs/_index.md#productionlog) pour vérifier si le fichier contient l'exception suivante :

```plaintext
:NoMethodError (undefined method 'duedate' for #<JIRA::Resource::Issue:0x00007f406d7b3180>)
```

Si c'est le cas, assurez-vous que le champ **Date d'échéance** est [visible pour les tickets](https://confluence.atlassian.com/jirakb/due-date-field-is-missing-189431917.html) dans le projet Jira intégré.

### Erreur : `An error occurred while requesting data from Jira` {#error-an-error-occurred-while-requesting-data-from-jira}

Lorsque vous essayez de consulter la liste des tickets Jira ou de créer un ticket Jira dans GitLab, vous pourriez obtenir l'une des erreurs suivantes :

```plaintext
An error occurred while requesting data from Jira
```

```plaintext
An error occurred while fetching issue list. Connection failed. Check your integration settings.
```

Ces erreurs se produisent lorsque l'authentification pour l'intégration des tickets Jira est incomplète ou incorrecte.

Pour résoudre ce problème, [configurez à nouveau l'intégration des tickets Jira](configure.md#configure-the-integration). Assurez-vous que les informations d'authentification sont correctes, saisissez à nouveau votre jeton d'API ou votre mot de passe, et enregistrez vos modifications.

La liste des tickets Jira ne se charge pas si la clé de projet contient un mot JQL réservé. Pour plus d'informations, consultez le [ticket 426176](https://gitlab.com/gitlab-org/gitlab/-/issues/426176). La clé de votre projet Jira ne doit pas contenir de [mots et caractères restreints](https://confluence.atlassian.com/jirasoftwareserver/advanced-searching-939938733.html#Advancedsearching-restrictionsRestrictedwordsandcharacters).

### Erreurs liées aux identifiants Jira {#errors-with-jira-credentials}

Lorsque vous essayez de consulter la liste des tickets Jira dans GitLab, vous pourriez voir l'une des erreurs suivantes.

#### Erreur : `The value '<project>' does not exist for the field 'project'` {#error-the-value-project-does-not-exist-for-the-field-project}

Si vous utilisez de mauvais identifiants d'authentification pour votre installation Jira, vous pourriez voir cette erreur :

```plaintext
An error occurred while requesting data from Jira:
The value '<project>' does not exist for the field 'project'.
Check your Jira issues integration configuration and try again.
```

Les identifiants d'authentification dépendent de votre type d'installation Jira :

- **For Jira Cloud**, vous devez disposer d'un jeton d'API Jira Cloud et de l'adresse e-mail que vous avez utilisée pour créer le jeton.
- **For Jira Data Center or Jira Server**, vous devez disposer d'un nom d'utilisateur et d'un mot de passe Jira ou, dans GitLab 16.0 et versions ultérieures, d'un jeton d'accès personnel Jira.

Pour plus d'informations, consultez l'[intégration des tickets Jira](configure.md).

Pour résoudre ce problème, mettez à jour les identifiants d'authentification pour qu'ils correspondent à votre installation Jira.

#### Erreur : `The credentials for accessing Jira are not allowed to access the data` {#error-the-credentials-for-accessing-jira-are-not-allowed-to-access-the-data}

Si vos identifiants Jira ne peuvent pas accéder à la clé de projet Jira que vous avez spécifiée dans l'[intégration des tickets Jira](configure.md#configure-the-integration), vous pourriez voir cette erreur :

```plaintext
The credentials for accessing Jira are not allowed to access the data.
Check your Jira issues integration credentials and try again.
```

> [!warning]
> Atlassian a déprécié les anciens points de terminaison de recherche JQL (`GET/POST /rest/api/2/search`) pour Jira Cloud le 31 octobre 2024, avec une suppression prévue le 1er mai 2025. Jira Server et Data Center continuent d'utiliser le point de terminaison `/rest/api/2/search`. Pour plus d'informations, consultez l'[avis de dépréciation d'Atlassian](https://developer.atlassian.com/changelog/#CHANGE-2046).

Pour résoudre ce problème, assurez-vous que l'utilisateur Jira que vous avez configuré dans l'intégration des tickets Jira dispose de l'autorisation d'afficher les tickets associés à la clé de projet Jira spécifiée.

Pour vérifier que l'utilisateur Jira dispose de cette autorisation, effectuez l'une des actions suivantes :

{{< tabs >}}

{{< tab title="Jira Cloud" >}}

- Dans votre navigateur, connectez-vous à Jira avec l'utilisateur que vous avez configuré dans l'intégration des tickets Jira. Étant donné que l'API Jira prend en charge l'authentification par cookie, vous pouvez vérifier si des tickets sont renvoyés dans le navigateur :

  ```plaintext
  https://<ATLASSIAN_SUBDOMAIN>.atlassian.net/rest/api/3/search/jql?jql=project=<JIRA_PROJECT_KEY>
  ```

- Utilisez `curl` pour l'authentification HTTP de base afin d'accéder à l'API et vérifier si des tickets sont renvoyés :

  ```shell
  curl --verbose --user "$JIRA_EMAIL:$JIRA_API_TOKEN" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --request POST \
    --data '{"jql":"project='$JIRA_PROJECT_KEY'"}' \
    "https://$ATLASSIAN_SUBDOMAIN.atlassian.net/rest/api/3/search/jql" | jq
  ```

La réponse de l'API renvoie une réponse JSON :

- `issues` contient un tableau des tickets correspondant à la clé de projet Jira.
- `nextPageToken` est fourni s'il y a d'autres résultats à récupérer.

Pour plus d'informations sur les codes de statut renvoyés et les détails de l'API, consultez [la recherche de tickets via la recherche JQL améliorée (POST)](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-search/#api-rest-api-3-search-jql-post).

{{< /tab >}}

{{< tab title="Jira Server/Data Center" >}}

- Dans votre navigateur, connectez-vous à Jira avec l'utilisateur que vous avez configuré dans l'intégration des tickets Jira. Étant donné que l'API Jira prend en charge l'authentification par cookie, vous pouvez vérifier si des tickets sont renvoyés dans le navigateur :

  ```plaintext
  <JIRA_SERVER_URL>/rest/api/2/search?jql=project=<JIRA_PROJECT_KEY>
  ```

- Utilisez `curl` pour l'authentification HTTP de base afin d'accéder à l'API et vérifier si des tickets sont renvoyés :

  ```shell
  curl --verbose --header 'Authorization: Bearer '$JIRA_API_TOKEN'' \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --request POST \
    --data '{"jql":"project='$JIRA_PROJECT_KEY'"}' \
    "$JIRA_SERVER_URL/rest/api/2/search" | jq
  ```

La réponse de l'API renvoie une réponse JSON :

- `issues` contient un tableau des tickets correspondant à la clé de projet Jira.
- `total` est fourni s'il y a d'autres résultats à récupérer.

Pour plus d'informations sur les codes de statut renvoyés et les détails de l'API, consultez [effectuer une recherche avec JQL (POST)](https://developer.atlassian.com/server/jira/platform/rest/v10007/api-group-search/#api-api-2-search-post).

{{< /tab >}}

{{< /tabs >}}
