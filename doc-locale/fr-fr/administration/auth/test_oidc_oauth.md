---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tester OIDC/OAuth dans GitLab
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour tester OIDC/OAuth dans GitLab, vous devez :

1. [Activer OIDC/OAuth](#enable-oidcoauth-in-gitlab)
1. [Tester OIDC/OAuth avec votre application cliente](#test-oidcoauth-with-your-client-application)
1. [Vérifier l'authentification OIDC/OAuth](#verify-oidcoauth-authentication)

## Prérequis {#prerequisites}

Avant de pouvoir tester OIDC/OAuth sur GitLab, vous devez :

- Disposer d'une instance accessible publiquement.
- Être administrateur de cette instance.
- Disposer d'une application cliente que vous souhaitez utiliser pour tester OIDC/OAuth.

## Activer OIDC/OAuth dans GitLab {#enable-oidcoauth-in-gitlab}

Vous devez d'abord créer une application OIDC/OAuth sur votre instance GitLab. Pour ce faire :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Applications**.
1. Sélectionnez **Ajouter une nouvelle application**.
1. Renseignez les détails de votre application cliente, notamment le nom, l'URI de redirection et les portées autorisées.
1. Assurez-vous que la portée `openid` est activée.
1. Sélectionnez **Enregistrer l'application** pour créer la nouvelle application OAuth.

## Tester OIDC/OAuth avec votre application cliente {#test-oidcoauth-with-your-client-application}

Une fois votre application OAuth créée dans GitLab, vous pouvez l'utiliser pour tester OIDC/OAuth :

1. Vous pouvez utiliser <https://openidconnect.net> comme environnement de test OIDC/OAuth.
1. Déconnectez-vous de GitLab.
1. Visitez votre application cliente et lancez le flow OIDC/OAuth, en utilisant l'application OAuth GitLab que vous avez créée à l'étape précédente.
1. Suivez les invites pour vous connecter à GitLab et autoriser l'application cliente à accéder à votre compte GitLab.
1. Une fois le flow OIDC/OAuth terminé, votre application cliente devrait avoir reçu un jeton d'accès qu'elle peut utiliser pour s'authentifier auprès de GitLab.

## Vérifier l'authentification OIDC/OAuth {#verify-oidcoauth-authentication}

Pour vérifier que l'authentification OIDC/OAuth fonctionne correctement sur GitLab, vous pouvez effectuer les vérifications suivantes :

1. Vérifiez que le jeton d'accès reçu à l'étape précédente est valide et peut être utilisé pour vous authentifier auprès de GitLab. Pour ce faire, effectuez une requête API de test vers GitLab en utilisant le jeton d'accès pour vous authentifier. Par exemple :

   ```shell
   curl --header "Authorization: Bearer <access_token>" https://mygitlabinstance.com/api/v4/user
   ```

    Remplacez `<access_token>` par le jeton d'accès réel que vous avez reçu à l'étape précédente. Si la requête API réussit et renvoie des informations sur l'utilisateur authentifié, alors l'authentification OIDC/OAuth fonctionne correctement.

1. Vérifiez que les portées que vous avez spécifiées dans votre application OAuth sont correctement appliquées. Pour ce faire, effectuez des requêtes API qui nécessitent les portées spécifiques et vérifiez qu'elles réussissent ou échouent comme prévu.

C'est tout ! Grâce à ces étapes, vous devriez être en mesure de tester l'authentification OIDC/OAuth sur votre instance GitLab à l'aide de votre application cliente.
