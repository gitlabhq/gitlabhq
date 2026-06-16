---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez l'authentification SAML SSO (Single Sign-On) pour GitLab Dedicated."
title: SSO SAML pour GitLab Dedicated
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

Vous pouvez configurer le Single Sign-On (SSO) SAML pour votre instance GitLab Dedicated avec jusqu'à dix fournisseurs d'identité (IdP).

Les options SSO SAML suivantes sont disponibles :

- [Signature des requêtes](#request-signing)
- [SSO SAML pour les groupes](#saml-groups)
- [Synchronisation des groupes](#group-sync)

> [!note]
> Ceci configure le SSO SAML pour les utilisateurs finaux de votre instance GitLab Dedicated. Pour configurer le SSO pour les administrateurs Switchboard, consultez [configurer le SSO Switchboard](_index.md#configure-switchboard-sso).

## Prérequis {#prerequisites}

- Vous devez [configurer le fournisseur d'identité](../../../../integration/saml.md#set-up-identity-providers) avant de pouvoir configurer SAML pour GitLab Dedicated.
- Pour configurer GitLab afin de signer les requêtes d'authentification SAML, vous devez créer une paire clé privée/certificat public pour votre instance GitLab Dedicated.

## Ajouter un fournisseur SAML avec Switchboard {#add-a-saml-provider-with-switchboard}

Pour ajouter un fournisseur SAML pour votre instance GitLab Dedicated :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. En haut de la page, sélectionnez **Configuration**.
1. Développez **SAML providers**.
1. Sélectionnez **Add SAML provider**.
1. Dans la zone de texte **SAML label**, saisissez un nom pour identifier ce fournisseur dans Switchboard.
1. Facultatif. Pour configurer les utilisateurs en fonction de leur appartenance à un groupe SAML ou utiliser la synchronisation des groupes, renseignez ces champs :
   - **SAML group attribute**
   - **Admin groups**
   - **Auditor groups**
   - **External groups**
   - **Required groups**
1. Dans la zone de texte **IdP cert fingerprint**, saisissez l'empreinte de votre certificat IdP. Cette valeur est une somme de contrôle SHA1 de l'empreinte du certificat `X.509` de votre IdP.
1. Dans la zone de texte **IdP SSO target URL**, saisissez l'URL du point de terminaison de votre IdP vers lequel GitLab Dedicated redirige les utilisateurs pour s'authentifier avec ce fournisseur.
1. Dans la liste déroulante **Name identifier format**, sélectionnez le format du NameID que ce fournisseur envoie à GitLab.
1. Facultatif. Pour configurer la signature des requêtes, renseignez ces champs :
   - **Émetteur**
   - **Attribute statements**
   - **Sécurité**
1. Pour commencer à utiliser ce fournisseur, cochez la case **Enable this provider**.
1. Sélectionnez **Enregistrer**.
1. Pour ajouter un autre fournisseur SAML, sélectionnez à nouveau **Add SAML provider** et suivez les étapes précédentes. Vous pouvez ajouter jusqu'à dix fournisseurs.
1. Faites défiler vers le haut de la page. La bannière **Initiated changes** indique que vos modifications de configuration SAML seront appliquées lors de la prochaine fenêtre de maintenance. Pour appliquer les modifications immédiatement, sélectionnez **Apply changes now**.

Une fois les modifications appliquées, vous pouvez vous connecter à votre instance GitLab Dedicated en utilisant ce fournisseur SAML. Pour utiliser la synchronisation des groupes, [configurez les liens de groupe SAML](../../../../user/group/saml_sso/group_sync.md#configure-saml-group-links).

## Vérifier votre configuration SAML {#verify-your-saml-configuration}

Pour vérifier que votre configuration SAML est réussie :

1. Déconnectez-vous et accédez à la page de connexion de votre instance GitLab Dedicated.
1. Vérifiez que le bouton SSO de votre fournisseur SAML apparaît sur la page de connexion.
1. Accédez à l'URL de métadonnées de votre instance (`https://INSTANCE-URL/users/auth/saml/metadata`). L'URL de métadonnées affiche des informations qui peuvent simplifier la configuration de votre fournisseur d'identité et vous aide à valider vos paramètres SAML.
1. Essayez de vous connecter via le fournisseur SAML pour vous assurer que le flux d'authentification fonctionne correctement.

Pour des informations de dépannage, consultez [dépannage SAML](../../../../user/group/saml_sso/troubleshooting.md).

## Ajouter un fournisseur SAML avec une demande d'assistance {#add-a-saml-provider-with-a-support-request}

Si vous ne pouvez pas utiliser Switchboard pour ajouter ou mettre à jour SAML pour votre instance GitLab Dedicated, vous pouvez ouvrir un [ticket d'assistance](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) :

1. Pour effectuer les modifications nécessaires, incluez le [bloc de configuration SAML](../../../../integration/saml.md#configure-saml-support-in-gitlab) souhaité pour votre application GitLab dans votre ticket d'assistance. Au minimum, GitLab a besoin des informations suivantes pour activer SAML pour votre instance :
   - URL cible SSO IDP
   - Empreinte du certificat ou certificat
   - Format NameID
   - Description du bouton de connexion SSO

   ```json
   "saml": {
     "attribute_statements": {
         //optional
     },
     "enabled": true,
     "groups_attribute": "",
     "admin_groups": [
       // optional
     ],
     "idp_cert_fingerprint": "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8",
     "idp_sso_target_url": "https://login.example.com/idp",
     "label": "IDP Name",
     "name_identifier_format": "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
     "security": {
       // optional
     },
     "auditor_groups": [
       // optional
     ],
     "external_groups": [
       // optional
     ],
     "required_groups": [
       // optional
     ],
   }
   ```

1. Une fois que GitLab a déployé la configuration SAML sur votre instance, vous êtes notifié sur votre ticket d'assistance.
1. Pour vérifier que la configuration SAML est réussie :
   - Vérifiez que la description du bouton de connexion SSO est affichée sur la page de connexion de votre instance.
   - Accédez à l'URL de métadonnées de votre instance, fournie par GitLab dans le ticket d'assistance. Cette page peut être utilisée pour simplifier une grande partie de la configuration du fournisseur d'identité, ainsi que pour valider manuellement les paramètres.

## Signature des requêtes {#request-signing}

Si la [signature des requêtes SAML](../../../../integration/saml.md#sign-saml-authentication-requests-optional) est souhaitée, un certificat doit être obtenu. Ce certificat peut être auto-signé, ce qui présente l'avantage de ne pas avoir à prouver la propriété d'un Common Name (CN) arbitraire auprès d'une autorité de certification (CA) publique.

> [!note]
> Étant donné que la signature des requêtes SAML nécessite la signature du certificat, vous devez effectuer ces étapes pour utiliser SAML avec cette fonctionnalité activée.

Pour activer la signature des requêtes SAML :

1. Ouvrez un [ticket d'assistance](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) et indiquez que vous souhaitez activer la signature des requêtes.
1. GitLab collaborera avec vous pour l'envoi de la demande de signature de certificat (CSR) que vous devrez signer. Alternativement, la CSR peut être signée par une CA publique.
1. Une fois le certificat signé, vous pouvez utiliser le certificat et sa clé privée associée pour compléter la section `security` de la [configuration SAML](#add-a-saml-provider-with-switchboard) dans Switchboard.

Les requêtes d'authentification de GitLab vers votre fournisseur d'identité peuvent désormais être signées.

## Groupes SAML {#saml-groups}

Avec les groupes SAML, vous pouvez configurer les utilisateurs GitLab en fonction de leur appartenance à un groupe SAML.

Pour activer les groupes SAML, ajoutez les [éléments requis](../../../../integration/saml.md#configure-users-based-on-saml-group-membership) à votre configuration SAML dans [Switchboard](#add-a-saml-provider-with-switchboard) ou au bloc SAML que vous fournissez dans un [ticket d'assistance](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

## Synchronisation des groupes {#group-sync}

Avec la [synchronisation des groupes](../../../../user/group/saml_sso/group_sync.md), vous pouvez synchroniser les utilisateurs entre les groupes du fournisseur d'identité et les groupes mappés dans GitLab.

Pour activer la synchronisation des groupes :

1. Ajoutez les [éléments requis](../../../../user/group/saml_sso/group_sync.md#configure-saml-group-sync) à votre configuration SAML dans [Switchboard](#add-a-saml-provider-with-switchboard) ou au bloc de configuration SAML que vous fournissez dans un [ticket d'assistance](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. Configurez les [liens de groupe](../../../../user/group/saml_sso/group_sync.md#configure-saml-group-links).
