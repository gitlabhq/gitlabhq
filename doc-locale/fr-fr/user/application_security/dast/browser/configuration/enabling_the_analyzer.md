---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Activer l'analyseur"
---

Pour exécuter un scan DAST :

- Lisez les conditions [requises](../_index.md) pour exécuter un scan DAST.
- Créez un [job DAST](#create-a-dast-cicd-job) dans votre pipeline CI/CD.
- [Authentifiez-vous](authentication.md) en tant qu'utilisateur si votre application l'exige.

Le job DAST s'exécute dans un conteneur Docker défini par le mot-clé `image` dans le fichier de modèle CI/CD DAST. Lorsque vous exécutez le job, DAST se connecte à l'application cible spécifiée par la variable CI/CD `DAST_TARGET_URL` et explore le site à l'aide d'un navigateur intégré.

## Créer un job CI/CD DAST {#create-a-dast-cicd-job}

{{< history >}}

- Ce modèle a été mis à jour vers DAST_VERSION : 4 dans GitLab 16.0.
- Ce modèle a été [mis à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151910) vers DAST_VERSION : 5 dans GitLab 17.0.
- Ce modèle a été [mis à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188703) vers DAST_VERSION : 6 dans GitLab 18.0.

{{< /history >}}

Pour ajouter le scan DAST à votre application, utilisez le job DAST défini dans le fichier de modèle CI/CD DAST de GitLab. Les mises à jour du modèle sont fournies avec les mises à niveau de GitLab, ce qui vous permet de bénéficier de toutes les améliorations et additions.

Prérequis :

- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.

Pour créer le job CI/CD :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Éditeur de pipeline**.

   Si aucun fichier `.gitlab-ci.yml` n'existe, sélectionnez **Configure pipeline**, puis supprimez le contenu d'exemple.
1. Incluez le modèle CI/CD approprié :

   - [`DAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.gitlab-ci.yml) : version stable du modèle CI/CD DAST.
   - [`DAST.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.latest.gitlab-ci.yml) : dernière version du modèle DAST.

   > [!warning]
   > La dernière version du modèle peut inclure des changements incompatibles. Utilisez le modèle stable, sauf si vous avez besoin d'une fonctionnalité disponible uniquement dans la dernière version du modèle.

1. Ajoutez une étape `dast` à la configuration des étapes CI/CD de GitLab.
1. Définissez l'URL à analyser par DAST en utilisant l'une de ces méthodes :

   - Définissez la [variable CI/CD](../../../../../ci/yaml/_index.md#variables) `DAST_TARGET_URL`. Si elle est définie, cette valeur est prioritaire.

   - L'ajout de l'URL dans un fichier `environment_url.txt` à la racine de votre projet est idéal pour les tests dans des environnements dynamiques. Pour exécuter DAST sur une application créée dynamiquement lors d'un pipeline CI/CD GitLab, écrivez l'URL de l'application dans un fichier `environment_url.txt`. DAST lit automatiquement l'URL pour trouver la cible du scan.

     Vous pouvez consulter un [exemple dans notre CI YAML Auto DevOps](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

Par exemple :

```yaml
stages:
  - dast

include:
  - template: Security/DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_USERNAME: "test_user"
    DAST_AUTH_USERNAME_FIELD: "name:user[login]"
    DAST_AUTH_PASSWORD_FIELD: "name:user[password]"
```

Vous devez définir `DAST_TARGET_URL` ou créer un fichier `environment_url.txt` pour que le job DAST s'exécute correctement.

### Connectivité réseau {#network-connectivity}

Votre runner doit se connecter à l'URL de l'application cible. Si votre application utilise un port non standard, incluez-le dans l'URL.

## Après avoir activé l'analyseur {#after-you-enable-the-analyzer}

Lorsque votre pipeline s'exécute, le job DAST :

1. Se connecte à votre application.
1. Lance un navigateur Chromium pour explorer le site.
1. Effectue des vérifications de sécurité sur les pages découvertes.

### Configurer l'authentification {#configure-authentication}

Si votre application requiert que les utilisateurs se connectent, configurez DAST pour qu'il s'authentifie avant le scan. Sans authentification, DAST ne peut analyser que les pages accessibles publiquement.

Pour configurer l'authentification, consultez [authentification](authentication.md).

### Vérifier la couverture de l'exploration {#verify-crawl-coverage}

Une fois votre premier scan terminé, vérifiez que DAST découvre correctement les pages de votre application.

Pour visualiser les résultats de l'exploration :

- Activez le graphique d'exploration à l'aide de la [variable](variables.md) `DAST_CRAWL_GRAPH`.
- Examinez le graphique pour identifier les pages manquantes ou les chemins de navigation absents.
- Si des pages sont manquantes, ajustez la [portée du scan](customize_settings.md#managing-scope).

### Dépannage {#troubleshooting}

Si vous rencontrez des problèmes :

- Pour les problèmes de configuration, consultez [configuration de DAST](../troubleshooting.md#setting-up-dast).
- Pour des informations de diagnostic détaillées, consultez [les journaux de diagnostic](../troubleshooting.md#diagnostic-logs).
- Pour le dépannage des connexions, consultez [le runner ne peut pas se connecter à l'application cible](../troubleshooting.md#runner-cannot-connect-to-target-application).
