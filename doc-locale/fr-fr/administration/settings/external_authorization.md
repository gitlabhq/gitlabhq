---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: "Contrôle d'autorisation externe"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Déplacé](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/27056) de GitLab Premium vers GitLab Free dans la version 11.10.

{{< /history >}}

Dans les environnements hautement contrôlés, il peut être nécessaire que la politique d'accès soit contrôlée par un service externe qui autorise l'accès en fonction de la classification du projet et de l'accès utilisateur. GitLab fournit un moyen de vérifier l'autorisation de projet avec votre propre service défini.

Une fois le service externe configuré et activé, lorsqu'un projet est consulté, une requête est envoyée au service externe avec les informations de l'utilisateur et le label de classification du projet attribué au projet. Lorsque le service répond avec une réponse connue, le résultat est mis en cache pendant six heures.

Si l'autorisation externe est activée, GitLab bloque en outre les pages et les fonctionnalités qui affichent des données inter-projets. Cela inclut :

- La plupart des pages du tableau de bord (Activité, Jalons, Extraits, Merge requests assignés, Tickets assignés, Liste de tâches).
- Pour un groupe spécifique (Activité, Analytique de contribution, Tickets, Tableaux de tickets, Labels, Jalons, Merge requests).
- Les recherches globale et de groupe sont désactivées.

Cela permet d'éviter d'envoyer trop de requêtes simultanées au service d'autorisation externe.

Chaque fois que l'accès est accordé ou refusé, cela est consigné dans un fichier journal appelé `external-policy-access-control.log`. Apprenez-en davantage sur les journaux que GitLab conserve dans la [documentation du paquet Linux](https://docs.gitlab.com/omnibus/settings/logs/).

Lorsque vous utilisez l'authentification TLS avec un certificat auto-signé, le certificat CA doit être approuvé par l'installation OpenSSL. Si vous utilisez GitLab installé avec le paquet Linux, apprenez à installer un CA personnalisé dans la [documentation du paquet Linux](https://docs.gitlab.com/omnibus/settings/ssl/). Vous pouvez également savoir où installer des certificats personnalisés en utilisant `openssl version -d`.

## Configuration {#configuration}

Le service d'autorisation externe peut être activé par un administrateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Autorisation externe**.
1. Remplissez les champs.
1. Sélectionnez **Sauvegarder les modifications**.

### Autoriser l'autorisation externe avec les jetons de déploiement et les clés de déploiement {#allow-external-authorization-with-deploy-tokens-and-deploy-keys}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/386656) dans GitLab 15.9.
- La fin de la possibilité pour les jetons de déploiement d'accéder aux registres de conteneurs ou de paquets a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/387721) dans GitLab 16.0.

{{< /history >}}

Vous pouvez configurer votre instance pour autoriser l'autorisation externe pour les opérations Git avec les [jetons de déploiement](../../user/project/deploy_tokens/_index.md) ou les [clés de déploiement](../../user/project/deploy_keys/_index.md).

Prérequis :

- Vous devez utiliser des labels de classification sans URL de service pour l'autorisation externe.

Pour autoriser l'autorisation avec les jetons et clés de déploiement :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Autorisation externe**, puis :
   - Laissez le champ URL du service vide.
   - Sélectionnez **Autoriser les jetons et clés de déploiement à être utilisés avec une permission externe**.
1. Sélectionnez **Sauvegarder les modifications**.

> [!warning]
> Si vous activez l'autorisation externe, les jetons de déploiement ne peuvent pas accéder aux registres de conteneurs ou de paquets. Si vous utilisez des jetons de déploiement pour accéder à ces registres, cette mesure interrompt cette utilisation de ces jetons. Désactivez l'autorisation externe pour utiliser les jetons avec les registres de conteneurs ou de paquets.

## Comment GitLab se connecte à un service d'autorisation externe {#how-gitlab-connects-to-an-external-authorization-service}

Lorsque GitLab demande un accès, il envoie une requête POST JSON au service externe avec ce corps :

```json
{
  "user_identifier": "jane@acme.org",
  "project_classification_label": "project-label",
  "user_ldap_dn": "CN=Jane Doe,CN=admin,DC=acme",
  "identities": [
    { "provider": "ldap", "extern_uid": "CN=Jane Doe,CN=admin,DC=acme" },
    { "provider": "bitbucket", "extern_uid": "2435223452345" }
  ]
}
```

Le `user_ldap_dn` est facultatif et n'est envoyé que lorsque l'utilisateur est connecté via LDAP.

`identities` contient les détails de toutes les identités associées à l'utilisateur. Il s'agit d'un tableau vide s'il n'y a aucune identité associée à l'utilisateur.

Lorsque le service d'autorisation externe répond avec un code de statut 200, l'accès est accordé à l'utilisateur. Lorsque le service externe répond avec un code de statut 401 ou 403, l'accès est refusé à l'utilisateur. Dans tous les cas, la requête est mise en cache pendant six heures.

Lors du refus d'accès, un `reason` peut être optionnellement spécifié dans le corps JSON :

```json
{
  "reason": "You are not allowed access to this project."
}
```

Tout code de statut autre que 200, 401 ou 403 refuse également l'accès à l'utilisateur, mais la réponse n'est pas mise en cache.

Si le service expire (après 500 ms), le message « External Policy Server did not respond » s'affiche.

## Labels de classification {#classification-labels}

Vous pouvez utiliser votre propre label de classification dans la page **Paramètres** > **Général** > **General project settings** dans le champ « Classification label ». Lorsqu'aucun label de classification n'est spécifié pour un projet, le label par défaut défini dans les [paramètres globaux](#configuration) est utilisé.

Sur toutes les pages du projet, dans le coin supérieur droit, le label apparaît.

![Un label rouge remplacé avec une icône de cadenas ouvert s'affiche dans le coin supérieur droit d'un projet.](img/classification_label_on_project_page_v14_8.png)
