---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutoriel : Configurer l''authentification unique SAML pour les groupes GitLab.com'
---

Ce tutoriel vous explique comment configurer l'authentification unique (SSO) SAML pour un groupe GitLab.com à l'aide d'un fournisseur d'identité (IdP) tel qu'Okta ou Microsoft Entra ID. Une fois la configuration terminée, les membres de votre groupe peuvent se connecter à GitLab via l'IdP.

Dans ce tutoriel, vous allez :

1. Configurer SAML via une application IdP.
1. Configurer l'authentification unique SAML dans votre groupe GitLab.
1. Tester la connexion SAML.
1. Lier un compte utilisateur pour vérifier la configuration.

## Avant de commencer {#before-you-begin}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour un groupe GitLab Premium ou Ultimate sur GitLab.com.
- Vous devez avoir un accès administrateur à votre IdP.
- Vous devez disposer d'au moins un compte utilisateur de test dans votre IdP.
- Vous devez être familiarisé avec les concepts d'authentification unique.

Durée estimée : 20 à 30 minutes

## Étape 1 : Collecter les informations GitLab {#step-1-gather-gitlab-information}

Avant de pouvoir configurer quoi que ce soit dans votre IdP, vous devez obtenir certains détails de connexion auprès de GitLab qui indiquent à votre IdP comment communiquer avec votre groupe GitLab.

Pour collecter les informations GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Authentification unique SAML**.
1. Notez ces valeurs :
   - **Identifiant**
   - **URL du service consommateur d'assertion**
   - **URL de l'authentification unique GitLab**

## Étape 2 : Créer une application IdP {#step-2-create-an-idp-application}

Maintenant que vos informations GitLab sont prêtes, créez une application dans votre IdP. Cette application met en correspondance les informations GitLab avec l'IdP et configure la manière dont les informations utilisateur circulent entre les deux systèmes.

Pour créer une application IdP :

{{< tabs >}}

{{< tab title="Okta" >}}

1. Connectez-vous à Okta en tant qu'administrateur.
1. Dans la console d'administration, sélectionnez **Applications** > **Applications**.
1. Sélectionnez **Create App Integration**.
1. Dans la section **Sign-in method**, sélectionnez **SAML 2.0**.
1. Sélectionnez **Suivant**.
1. Dans l'onglet **Paramètres généraux**, saisissez un nom pour votre application. Par exemple, `GitLab SAML`.
1. Sélectionnez **Suivant**.
1. Dans l'onglet **Configure SAML**, renseignez les champs avec les valeurs de l'étape 1 :
   - **Single sign-on URL** : Saisissez l'**URL du service consommateur d'assertion**.
   - Cochez la case **Use this for Recipient URL and Destination URL**.
   - **Audience URI (SP Entity ID)** : Saisissez l'**Identifiant**.
1. Configurez l'identifiant de nom :
   - **Application username (NameID)** : Sélectionnez **Personnalisé** et saisissez `user.getInternalProperty("id")`.
   - **Name ID Format** : Sélectionnez **Persistent**.
1. Dans la section **Attribute Statements (optional)**, ajoutez cet attribut :
   - **Nom** : `email`
   - **Valeur** : `user.email`
1. Faites défiler jusqu'aux paramètres **Application Login Page** :
   - **Login page URL** : Saisissez l'**URL de l'authentification unique GitLab**.
1. Sélectionnez **Suivant**.
1. Dans l'onglet **Feedback**, sélectionnez les options appropriées pour votre cas d'utilisation.
1. Sélectionnez **Finish**.

L'application SAML est créée dans Okta.

> [!note]
> Pour plus d'informations sur les attributs SAML et les options de configuration avancées, consultez la [documentation sur l'authentification unique SAML](../../user/group/saml_sso/_index.md#okta).

{{< /tab >}}

{{< tab title="Entra ID" >}}

1. Connectez-vous au [centre d'administration Microsoft Entra](https://entra.microsoft.com/).
1. Sélectionnez **Identité** > **Applications** > **Enterprise applications**.
1. Sélectionnez **New application**.
1. Sélectionnez **Create your own application**.
1. Dans la boîte de dialogue, renseignez les champs :
   - **Nom** : Saisissez un nom pour votre application. Pour ce tutoriel, utilisez `GitLab SAML`.
   - Sélectionnez **Integrate any other application you don't find in the gallery (Non-gallery)**.
1. Sélectionnez **Créer**.

L'application d'entreprise est créée dans Microsoft Entra ID.

1. Dans votre application d'entreprise, sélectionnez **Single sign-on** dans la barre latérale gauche.
1. Sélectionnez **SAML** comme méthode d'authentification unique.
1. Dans la section **Basic SAML Configuration**, sélectionnez **Éditer**.
1. Renseignez les champs avec les valeurs de l'étape 1 :
   - **Identifier (Entity ID)** : Saisissez l'**Identifiant**.
   - **Reply URL (Assertion Consumer Service URL)** : Saisissez l'**URL du service consommateur d'assertion**.
   - **Sign on URL** : Saisissez l'**URL de l'authentification unique GitLab**.
1. Sélectionnez **Enregistrer**.
1. Dans la section **User Attributes & Claims**, sélectionnez **Éditer**.
1. Sélectionnez **Add new claim** et renseignez les champs :
   - **Nom** : Saisissez `email`.
   - **Source attribute** : Sélectionnez `user.mail`.
1. Sélectionnez **Enregistrer**.
1. Modifiez la revendication **Unique User Identifier (Name ID)** :
   - Sélectionnez la revendication **Unique User Identifier** existante.
   - **Source attribute** : Sélectionnez `user.objectid`.
   - **Name identifier format** : Sélectionnez **Persistent**.
1. Sélectionnez **Enregistrer**.

> [!note]
> Pour plus d'informations sur les attributs SAML et les options de configuration avancées, consultez la [documentation sur l'authentification unique SAML](../../user/group/saml_sso/_index.md#azure).

{{< /tab >}}

{{< tab title="Google Workspace" >}}

1. Connectez-vous à la [console d'administration Google](https://admin.google.com/).
1. Sélectionnez **Apps** > **Web and mobile apps**.
1. Sélectionnez **Add App** > **Add custom SAML app**.
1. Dans la page **App Details**, saisissez un nom pour votre application. Par exemple, `GitLab SAML`.
1. Sélectionnez **Continuer**.
1. Dans la page **Google Identity Provider details**, laissez cette page ouverte. Vous aurez besoin de ces valeurs à l'étape 3.
1. Sélectionnez **Continuer**.
1. Dans la page **Service provider details**, renseignez les champs avec les valeurs de l'étape 1 :
   - **ACS URL** : Saisissez l'**URL du service consommateur d'assertion**.
   - **ID de l'entité** : Saisissez l'**Identifiant**.
   - **Start URL** : Saisissez l'**URL de l'authentification unique GitLab**.
   - **Name ID format** : Sélectionnez **EMAIL**.
   - **Name ID** : Sélectionnez **Informations de base** > **Adresse de courriel principale**.
1. Sélectionnez **Continuer**.
1. Dans la page **Attribute mapping**, ajoutez ces attributs :
   - **Google Directory attribute** : `Primary email`, **App attribute** : `email`
   - **Google Directory attribute** : `First name`, **App attribute** : `first_name`
   - **Google Directory attribute** : `Last name`, **App attribute** : `last_name`
1. Sélectionnez **Finish**. L'application SAML est créée dans Google Workspace.
1. Activez l'application pour vos utilisateurs :
   - Dans la section **User access**, sélectionnez **ON for everyone**.
   - Sélectionnez **Enregistrer**.

Pour plus d'informations sur les attributs SAML et les options de configuration avancées, consultez la [documentation sur l'authentification unique SAML](../../user/group/saml_sso/_index.md#google-workspace).

{{< /tab >}}

{{< tab title="OneLogin" >}}

1. Connectez-vous à OneLogin en tant qu'administrateur.
1. Sélectionnez **Administration** > **Applications**.
1. Sélectionnez **Add App**.
1. Recherchez **SAML Test Connector (Advanced)** et sélectionnez-le.
1. Dans le champ **Display Name**, saisissez un nom pour votre application. Par exemple, `GitLab SAML`.
1. Sélectionnez **Enregistrer**.
1. Sélectionnez l'onglet **Configuration**.
1. Renseignez les champs avec les valeurs de l'étape 1 :
   - **Audience (EntityID)** : Saisissez l'**Identifiant**.
   - **Recipient** : Saisissez l'**URL du service consommateur d'assertion**.
   - **ACS (Consumer) URL Validator** : Saisissez l'**URL du service consommateur d'assertion** sous forme d'expression régulière. Par exemple, `https://gitlab\.com/groups/your-group/-/saml/callback`.
   - **ACS (Consumer) URL** : Saisissez l'**URL du service consommateur d'assertion**.
   - **Login URL** : Saisissez l'**URL de l'authentification unique GitLab**.
1. Sélectionnez **Enregistrer**.
1. Sélectionnez l'onglet **Paramètres**.
1. Ajoutez l'attribut requis en sélectionnant **Add parameter** :
   - **Field name** : `email`, **Valeur** : Email
1. Pour **NameID**, sélectionnez **OneLogin ID** dans le champ de valeur.
1. Sélectionnez **Enregistrer**.
1. Sélectionnez l'onglet **Accès** pour assigner des utilisateurs ou des rôles à l'application.

L'application SAML est créée dans OneLogin.

Pour plus d'informations sur les attributs SAML et les options de configuration avancées, consultez la [documentation sur l'authentification unique SAML](../../user/group/saml_sso/_index.md#onelogin).

{{< /tab >}}

{{< tab title="Keycloak" >}}

1. Connectez-vous à Keycloak en tant qu'administrateur.
1. Accédez à **Clients** et sélectionnez **Create client**.
1. Dans la page **Paramètres généraux**, sélectionnez **SAML** comme **Client type**.
1. Renseignez les champs avec les valeurs de l'étape 1 :
   - **ID du client** : Saisissez l'**Identifiant**.
   - **Valid redirect URIs** : Saisissez l'**URL du service consommateur d'assertion**.
   - **Assertion Consumer Service POST Binding URL** : Saisissez l'**URL du service consommateur d'assertion**.
   - **Home URL** : Saisissez l'**URL de l'authentification unique GitLab**.
1. Sélectionnez **Enregistrer**.
1. Dans l'onglet **Paramètres**, dans la section **SAML capabilities** :
   - **Name ID format** : Sélectionnez `persistent`.
   - Activez le bouton bascule **Force name ID format**.
   - Activez le bouton bascule **Force POST binding**.
   - Activez le bouton bascule **Include AuthnStatement**.
1. Dans la section **Signature and Encryption**, activez le bouton bascule **Sign documents**.
1. Dans l'onglet **Clés**, assurez-vous que toutes les sections sont désactivées.
1. Dans l'onglet **Client scopes** :
   - Sélectionnez la portée du client pour GitLab.
   - Sélectionnez **Configure a new mapper**, puis sélectionnez **User Attribute** dans la fenêtre qui s'ouvre.
   - Dans la page **Add mapper**, définissez les champs **Nom**, **User Attribute** et **SAML Attribute Name** sur `email`.
   - Sélectionnez **Enregistrer**.

Le client SAML est créé dans Keycloak.

> [!note]
> Pour plus d'informations sur les attributs SAML et les options de configuration avancées, consultez la [documentation sur l'authentification unique SAML](../../user/group/saml_sso/_index.md#keycloak).

{{< /tab >}}

{{< tab title="AWS IAM Identity Center" >}}

1. Connectez-vous à la console AWS IAM Identity Center.
1. Sélectionnez **Applications**, puis sélectionnez **Add application**.
1. Sélectionnez **I have an application I want to set up**.
1. Sélectionnez **SAML 2.0** comme type d'application.
1. Sélectionnez **Suivant**.
1. Dans la page **Configure application**, saisissez un nom d'affichage pour votre application. Par exemple, `GitLab SAML`.
1. Renseignez les champs avec les valeurs de l'étape 1 :
   - **Application ACS URL** : Saisissez l'**URL du service consommateur d'assertion**.
   - **Application SAML audience** : Saisissez l'**Identifiant**.
   - **Application start URL** : Saisissez l'**URL de l'authentification unique GitLab**.
1. Sous **Attribute mappings**, configurez ces attributs :
   - **Objet** : `${user:email}`, **Format** : `unspecified`
   - **email** : `${user:email}`, **Format** : `unspecified`
   - **first_name** : `${user:givenName}`, **Format** : `unspecified`
   - **last_name** : `${user:familyName}`, **Format** : `unspecified`

   > [!warning]
   > Pour éviter les erreurs d'authentification pour les utilisateurs GitLab existants, ne définissez pas le format sur `persistent` ou `transient`.

1. Sélectionnez **Envoyer**. L'application SAML est créée dans AWS IAM Identity Center.
1. Assignez des utilisateurs à l'application GitLab.

Pour plus d'informations sur les attributs SAML et les options de configuration avancées, consultez la [documentation sur l'authentification unique SAML](../../user/group/saml_sso/_index.md#aws-iam-identity-center).

> [!note]
> AWS IAM Identity Center utilise par défaut la connexion initiée par l'IdP. Pour lier des comptes GitLab existants, les utilisateurs doivent se connecter depuis l'**URL de l'authentification unique GitLab** ou l'**Application start URL**.

{{< /tab >}}

{{< /tabs >}}

## Étape 3 : Collecter les détails de connexion {#step-3-gather-the-connection-details}

Récupérez maintenant les informations dont GitLab a besoin pour envoyer des demandes d'authentification à l'IdP.

Pour collecter les détails de connexion :

{{< tabs >}}

{{< tab title="Okta" >}}

1. Dans votre application SAML Okta, sélectionnez l'onglet **Sign On**.
1. Sur le côté droit, sélectionnez **View SAML setup instructions**.
1. Notez l'**Identity Provider Single Sign-On URL**.
1. Générez une empreinte de certificat :
   1. Dans le champ **X.509 Certificate**, copiez le texte et enregistrez-le localement.
   1. Ouvrez un terminal et accédez au répertoire où vous avez enregistré le fichier de certificat.
   1. Exécutez cette commande pour générer l'empreinte du certificat :

   ```shell
      # Replace `<certificate_filename>` with the actual filename of your downloaded certificate.
      # You might need to install OpenSSL or use an alternative method to generate the fingerprint.
       openssl x509 -noout -fingerprint -sha256 -in <certificate_filename>.crt
   ```

1. Copiez la valeur de l'empreinte après `SHA256 Fingerprint=`. L'empreinte ressemble à `A1:B2:C3:D4:E5:F6:...`.

{{< /tab >}}

{{< tab title="Entra ID" >}}

1. Dans votre application d'entreprise Entra ID, sélectionnez **Single sign-on**.
1. Dans la section **Set up GitLab SAML**, notez la **Login URL**. Le nom de cette section est basé sur le nom de votre application d'entreprise.
1. Dans la section **SAML Signing Certificate**, notez la valeur **Thumbprint**. L'empreinte ressemble à `A1B2C3D4E5F6...`.

{{< /tab >}}

{{< tab title="Google Workspace" >}}

1. Dans votre application SAML Google Workspace, accédez à la page de détails de l'application.
1. Notez la valeur **SSO URL**.
1. Notez la valeur **SHA-256 fingerprint** affichée pour le certificat. L'empreinte ressemble à `A1:B2:C3:D4:E5:F6:...`.

{{< /tab >}}

{{< tab title="OneLogin" >}}

1. Dans votre application SAML OneLogin, sélectionnez l'onglet **SSO**.
1. Notez l'URL **SAML 2.0 Endpoint (HTTP)**.
1. Dans la section **X.509 Certificate**, sélectionnez **View Details**.
1. Notez la valeur **SHA-256 Fingerprint**. L'empreinte ressemble à `A1:B2:C3:D4:E5:F6:...`.

{{< /tab >}}

{{< tab title="Keycloak" >}}

1. Dans votre client SAML Keycloak, dans la liste déroulante **Action**, sélectionnez **Download adapter config**.
1. Dans la boîte de dialogue **Download adapter config**, sélectionnez **mod-auth-mellon** dans la liste déroulante.
1. Sélectionnez **Télécharger**.
1. Extrayez l'archive téléchargée et ouvrez `idp-metadata.xml`.
1. Localisez la balise `<md:SingleSignOnService>` et notez la valeur de l'attribut `Location`.
1. Générez une empreinte de certificat :
   1. Localisez la balise `<ds:X509Certificate>` et copiez la valeur dans un fichier séparé.
   1. Convertissez la valeur au format PEM. Ajoutez `-----BEGIN CERTIFICATE-----` au début du fichier et `-----END CERTIFICATE-----` à la fin du fichier sur de nouvelles lignes.

{{< /tab >}}

{{< tab title="AWS IAM Identity Center" >}}

1. Dans votre application SAML AWS IAM Identity Center, sélectionnez l'application que vous avez créée.
1. Dans la section **IAM Identity Center SAML metadata**, notez l'**IAM Identity Center sign-in URL**.
1. Téléchargez le certificat.
1. Générez une empreinte de certificat :
   1. Ouvrez un terminal et accédez au répertoire où vous avez enregistré le fichier de certificat.
   1. Exécutez cette commande pour générer l'empreinte du certificat :

   ```shell
   # Replace `<certificate_filename>` with the actual filename of your downloaded certificate.
   # You might need to install OpenSSL or use an alternative method to generate the fingerprint.
   openssl x509 -noout -fingerprint -sha256 -in <certificate_filename>.pem
   ```

1. Copiez la valeur de l'empreinte après `SHA1 Fingerprint=`. L'empreinte ressemble à `A1:B2:C3:D4:E5:F6:...`.

> [!note]
> AWS IAM Identity Center nécessite une empreinte SHA1. Pour plus d'informations, consultez la [documentation sur l'authentification unique SAML](../../user/group/saml_sso/_index.md#aws-iam-identity-center).

{{< /tab >}}

{{< /tabs >}}

## Étape 4 : Configurer l'authentification unique SAML dans GitLab {#step-4-configure-saml-sso-in-gitlab}

Vous disposez de tout ce dont vous avez besoin pour finaliser la connexion. Retournez dans GitLab et saisissez les détails de connexion pour activer l'authentification SAML pour votre groupe.

Pour configurer SAML :

1. Retournez dans votre groupe GitLab.
1. Sélectionnez **Paramètres** > **Authentification unique SAML**.
1. Dans la section **Configuration**, renseignez les champs :
   - **URL d'authentification unique du fournisseur d'identité** : Saisissez l'URL de l'étape 3.
   - **Empreinte du certificat** : Saisissez l'empreinte de l'étape 3.
1. Cochez la case **Activer l'authentification SAML pour ce groupe**.
1. Dans la liste déroulante **Rôle d'adhésion par défaut**, sélectionnez **Accès minimal**.
1. Sélectionnez **Sauvegarder les modifications**.

La connexion SAML de base est maintenant configurée.

> [!note]
> Vous pouvez définir le rôle d'adhésion par défaut sur n'importe quel rôle. Tous les nouveaux utilisateurs se voient attribuer ce rôle lors de leur première connexion via SAML. Définir la valeur par défaut sur [**Accès minimal**](../../user/permissions.md#users-with-minimal-access) et promouvoir les utilisateurs ultérieurement réduit le risque que des utilisateurs disposent d'un accès trop étendu.

## Étape 5 : Tester la configuration SAML {#step-5-test-the-saml-configuration}

Avant d'inviter votre équipe, vérifiez que la connexion fonctionne correctement.

Pour tester la configuration SAML :

1. Dans la page **Paramètres** > **Authentification unique SAML**, sélectionnez **Vérifier la configuration SAML**. GitLab vous redirige vers l'IdP.
1. Connectez-vous avec vos identifiants IdP.
1. Confirmez que l'IdP vous redirige vers GitLab.

Si vous rencontrez des erreurs, consultez le [guide de dépannage](../../user/group/saml_sso/troubleshooting.md).

## Étape 6 : Lier un compte utilisateur pour tester le flux complet {#step-6-link-a-user-account-to-test-the-full-flow}

La configuration semble correcte. Testez maintenant l'expérience du point de vue d'un utilisateur en liant un compte de test, comme le font les membres de votre équipe lorsqu'ils se connectent pour la première fois à GitLab via l'IdP.

Pour tester la liaison d'un compte utilisateur :

1. Déconnectez-vous de GitLab.
1. Dans un autre navigateur ou une fenêtre de navigation privée, connectez-vous à votre compte GitLab de test.
1. Accédez à l'URL d'authentification unique GitLab que vous avez notée à l'étape 1.
1. Sélectionnez **Autoriser**.
1. Lorsque vous y êtes invité, connectez-vous avec vos identifiants IdP.
1. Vérifiez que vous êtes redirigé vers le groupe GitLab.

Félicitations ! Vous avez correctement lié une identité SAML à un compte GitLab.

## Étape 7 : Facultatif : Activer l'application de l'authentification unique {#step-7-optional-turn-on-sso-enforcement}

Votre configuration SAML est opérationnelle. En tant qu'étape finale facultative, vous pouvez activer l'application de l'authentification unique. L'application de l'authentification unique impose à tous les membres du groupe de s'authentifier via l'IdP, ce qui renforce la sécurité. Cependant, elle empêche l'accès via d'autres méthodes d'authentification.

Pour activer l'application de l'authentification unique :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Authentification unique SAML**.
1. Sélectionnez **Mettre en œuvre l'authentification unique SSO pour l'activité Web de ce groupe**.
1. Sélectionnez **Sauvegarder les modifications**.

Une fois l'application activée, tous les membres du groupe doivent se connecter via l'IdP avant de pouvoir accéder aux ressources du groupe.

## Étapes suivantes {#next-steps}

Vous avez correctement configuré l'authentification unique SAML pour votre groupe GitLab ! Voici quelques actions que vous pourriez souhaiter effectuer ensuite :

- [Configurer le provisionnement SCIM](../../user/group/saml_sso/scim_setup.md) pour synchroniser automatiquement les utilisateurs.
- [Configurer la synchronisation des groupes](../../user/group/saml_sso/group_sync.md) pour gérer l'appartenance aux groupes GitLab en fonction de vos groupes IdP.
- Vérifiez un domaine pour [contourner la confirmation par e-mail des utilisateurs](../../user/group/saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains) pour les nouveaux utilisateurs.
- Consultez la [documentation sur l'application de l'authentification unique](../../user/group/saml_sso/_index.md#sso-enforcement) pour les options de sécurité avancées.

## Dépannage {#troubleshooting}

Si vous rencontrez des problèmes au cours de ce tutoriel, consultez les ressources suivantes :

- [Erreurs SAML courantes et solutions](../../user/group/saml_sso/troubleshooting.md)
- [Comment dissocier et réassocier des comptes](../../user/group/saml_sso/_index.md#unlink-accounts)
- [Ressources d'assistance](https://support.gitlab.com/)
