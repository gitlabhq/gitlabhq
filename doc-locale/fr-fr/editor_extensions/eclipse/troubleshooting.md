---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connectez-vous et utilisez GitLab Duo dans Eclipse.
title: "Dépannage d'Eclipse"
---

{{< details >}}

- Édition : [Gratuite](../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : Version bêta

{{< /details >}}

{{< history >}}

- [Passage](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163) de la version expérimentale à la version bêta dans GitLab 17.11.
- L'accès à GitLab Duo Non-Agentic Chat a été supprimé pour les clients GitLab Duo Core le 21 mai 2026 dans le cadre de la version GitLab 19.0, avec un feature flag nommé `no_duo_classic_for_duo_core_users`. Activé par défaut.

{{< /history >}}

> [!disclaimer]

Si les étapes de cette page ne résolvent pas votre problème, consultez la [liste des tickets ouverts](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/?sort=created_date&state=opened&first_page_size=100) dans le projet du plugin Eclipse. Si un ticket correspond à votre problème, mettez-le à jour. Si aucun ticket ne correspond à votre problème, [créez un nouveau ticket](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/new) avec les [informations requises pour le support](#required-information-for-support).

## Consulter le journal des erreurs {#review-the-error-log}

1. Dans la barre de menus de votre IDE, sélectionnez **Window**.
1. Développez **Show View**, puis sélectionnez **Error Log**.
1. Recherchez les erreurs faisant référence aux plugins `gitlab-eclipse-plugin`.

## Localiser le fichier journal du workspace Eclipse {#locate-the-eclipse-workspace-log-file}

Le fichier journal du workspace Eclipse, nommé `.log`, se trouve dans le répertoire `<your-eclipse-workspace>/.metadata`.

## Activer les journaux de débogage du serveur de langage GitLab {#enable-gitlab-language-server-debug-logs}

Pour activer les journaux de débogage du serveur de langage GitLab :

1. Dans votre IDE, ouvrez les préférences :
   - Pour macOS, sélectionnez **Eclipse** > **Paramètres**.
   - Sur Windows ou Linux, sélectionnez **Window** > **Préférences**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Dans **Language Server Log Level**, saisissez `debug`.
1. Sélectionnez **Apply and Close**.

Les journaux de débogage sont disponibles dans le fichier `language_server.log`. Pour afficher ce fichier, effectuez l'une des opérations suivantes :

- Accédez au répertoire suivant en remplaçant `<user>` et `<eclipse-version>` par les valeurs appropriées :
  - Pour macOS : `/Users/<user>/eclipse-workspace/.metadata/.plugins/com.gitlab.eclipse.gitlab-eclipse-plugin`
  - Pour Windows : `<drive>:\Users\<user>\eclipse-workspace\.metadata\.plugins\com.gitlab.eclipse.gitlab-eclipse-plugin`
  - Pour Linux : `/home/<user>/eclipse-workspace/.metadata/.plugins/com.gitlab.eclipse.gitlab-eclipse-plugin`
- Ouvrez le journal **Error Log**. Recherchez le journal `Language server logs saved to: <file>.` où `<file>` est le chemin absolu vers le fichier `language_server.log`.

## Informations requises pour le support {#required-information-for-support}

Lors de la création d'une demande de support, fournissez les informations suivantes :

1. Votre version actuelle du plugin GitLab pour Eclipse.
   1. Ouvrez la boîte de dialogue `About Eclipse` dans votre IDE.
      - Pour macOS, sélectionnez **Eclipse** > **About Eclipse**.
      - Sur Windows ou Linux, sélectionnez **Aide** > **About Eclipse IDE**.
   1. Sélectionnez **Installation details**.
   1. Localisez **GitLab for Eclipse** et copiez la valeur **Version**.
1. Votre version d'Eclipse.
   1. Ouvrez la boîte de dialogue `About Eclipse` dans votre IDE.
      - Pour macOS, sélectionnez **Eclipse** > **About Eclipse**.
      - Sur Windows ou Linux, sélectionnez **Aide** > **About Eclipse IDE**.
1. Votre système d'exploitation.
1. Utilisez-vous une instance GitLab.com, GitLab Self-Managed ou GitLab Dedicated ?
1. Utilisez-vous un proxy ?
1. Utilisez-vous un certificat auto-signé ?
1. Les journaux du workspace Eclipse.
1. Les journaux de débogage du serveur de langage.
1. Le cas échéant, une vidéo ou une capture d'écran du problème.
1. Le cas échéant, les étapes pour reproduire le problème.
1. Le cas échéant, les étapes tentées pour résoudre le problème.

## Erreurs de certificat {#certificate-errors}

Si votre machine se connecte à votre instance GitLab via un proxy, vous pourriez rencontrer des erreurs de certificat SSL dans Eclipse. GitLab Duo tente de détecter les certificats dans votre magasin système ; cependant, le serveur de langage ne peut pas effectuer cette opération. Si vous voyez des erreurs provenant du serveur de langage concernant les certificats, essayez d'activer l'option permettant de transmettre un certificat d'autorité de certification (CA) :

Pour ce faire :

1. Dans le coin inférieur droit de votre IDE, sélectionnez l'icône GitLab.
1. Dans la boîte de dialogue, sélectionnez **Show Settings**. La boîte de dialogue **Paramètres** s'ouvre sur **Outils** > **GitLab Duo**.
1. Sélectionnez **GitLab Language Server** pour développer la section.
1. Sélectionnez **HTTP Agent Options** pour le développer.
1. L'une ou l'autre des options :
   - Sous **Language Server**, pour **CA certificate**, sélectionnez **Parcourir** et choisissez votre fichier `.pem` contenant les certificats CA.
   - Sous **Connexion**, cochez la case **Ignore Certificate Errors**.
1. Sélectionnez **Apply and Close**.

### Ignorer les erreurs de certificat {#ignore-certificate-errors}

Si GitLab Duo ne parvient toujours pas à se connecter, vous devrez peut-être ignorer les erreurs de certificat. Des erreurs peuvent apparaître dans les journaux du serveur de langage GitLab après l'activation du mode débogage :

```plaintext
2024-10-31T10:32:54:165 [error]: fetch: request to https://gitlab.com/api/v4/personal_access_tokens/self failed with:
request to https://gitlab.com/api/v4/personal_access_tokens/self failed, reason: unable to get local issuer certificate
FetchError: request to https://gitlab.com/api/v4/personal_access_tokens/self failed, reason: unable to get local issuer certificate
```

Par conception, ce paramètre représente un risque de sécurité : ces erreurs vous alertent sur des failles de sécurité potentielles. Vous ne devez activer ce paramètre que si vous êtes absolument certain que le proxy est à l'origine du problème.

Prérequis :

- Vous avez vérifié la chaîne de certificats dans votre navigateur système ou l'administrateur de votre machine a confirmé que cette erreur peut être ignorée en toute sécurité.

Pour ce faire :

1. Consultez la documentation Eclipse sur les certificats SSL.
1. Dans votre IDE, ouvrez les préférences :
   - Pour macOS, sélectionnez **Eclipse** > **Paramètres**.
   - Sur Windows ou Linux, sélectionnez **Window** > **Préférences**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Confirmez que votre navigateur par défaut fait confiance à la valeur **URL to GitLab instance**.
1. Cochez la case **Ignore certificate errors**.
1. Sélectionnez **Verify Setup**.
1. Sélectionnez **Apply and Close**.
