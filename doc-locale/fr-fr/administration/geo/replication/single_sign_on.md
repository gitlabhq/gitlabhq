---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Geo avec l'authentification unique (SSO)"
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Cette documentation traite uniquement des considérations et de la configuration SSO spécifiques à Geo. Pour plus d'informations sur l'authentification générale, voir [Authentification et autorisation GitLab](../../auth/_index.md).

## Configuration du SAML à l'échelle de l'instance {#configuring-instance-wide-saml}

### Prérequis {#prerequisites}

[Le SAML à l'échelle de l'instance](../../../integration/saml.md) doit fonctionner sur votre site Geo principal.

Vous configurez SAML uniquement sur le site principal. La configuration de `gitlab_rails['omniauth_providers']` dans `gitlab.rb` sur un site secondaire n'a aucun effet. Le site secondaire s'authentifie auprès du fournisseur SAML configuré sur le site principal. En fonction du [type d'URL](#determine-the-type-of-url-your-secondary-site-uses) du site secondaire, une [configuration supplémentaire](#saml-with-separate-url-with-proxying-enabled) peut être nécessaire sur le site principal.

### Déterminer le type d'URL utilisé par votre site secondaire {#determine-the-type-of-url-your-secondary-site-uses}

La façon dont vous configurez le SAML à l'échelle de l'instance diffère selon la configuration de votre site secondaire. Déterminez si votre site secondaire utilise une :

- [URL unifiée](../secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites), ce qui signifie que `external_url` correspond exactement à `external_url` du site principal.
- [URL distincte](../secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site) avec le proxy activé. Le proxy est activé par défaut dans GitLab 15.1 et versions ultérieures.
- [URL distincte](../secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site) avec le proxy désactivé.

### SAML avec URL unifiée {#saml-with-unified-url}

Si vous avez correctement configuré SAML sur le site principal, il devrait fonctionner sur le site secondaire sans configuration supplémentaire.

### SAML avec URL distincte et proxy activé {#saml-with-separate-url-with-proxying-enabled}

> [!note]
> Lorsque le proxy est activé, SAML ne peut être utilisé pour se connecter au site secondaire que si votre fournisseur d'identité (IdP) SAML autorise une application à avoir plusieurs URL de rappel configurées. Vérifiez auprès de l'équipe de support de votre fournisseur IdP si c'est bien le cas.

Si un site secondaire utilise un `external_url` différent de celui du site principal, configurez votre fournisseur d'identité (IdP) SAML pour autoriser l'URL de rappel SAML du site secondaire. Par exemple, pour configurer Okta :

1. [Connectez-vous à Okta](https://login.okta.com/).
1. Accédez à **Okta Admin Dashboard** > **Applications** > **Your App Name** > **Général**.
1. Dans **SAML Settings**, sélectionnez **Éditer**.
1. Dans **Paramètres généraux**, sélectionnez **Suivant** pour accéder à **SAML Settings**.
1. Dans **SAML Settings** > **Général**, assurez-vous que l'**Single sign-on URL** correspond à l'URL de rappel SAML de votre site principal. Par exemple, `https://gitlab-primary.example.com/users/auth/saml/callback`. Si ce n'est pas le cas, saisissez l'URL de rappel SAML de votre site principal dans ce champ.
1. Sélectionnez **Show Advanced Settings**.
1. Dans **Other Requestable SSO URLs**, saisissez l'URL de rappel SAML de votre site secondaire. Par exemple, `https://gitlab-secondary.example.com/users/auth/saml/callback`. Vous pouvez définir **Indexer** sur n'importe quelle valeur.
1. Sélectionnez **Suivant** puis **Finish**.

Vous ne devez pas spécifier `assertion_consumer_service_url` dans la configuration du fournisseur SAML dans `gitlab_rails['omniauth_providers']` dans `gitlab.rb` du site principal. Par exemple :

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "saml",
    label: "Okta", # optional label for login button, defaults to "Saml"
    args: {
      idp_cert_fingerprint: "B5:AD:AA:9E:3C:05:68:AD:3B:78:ED:31:99:96:96:43:9E:6D:79:96",
      idp_sso_target_url: "https://<dev-account>.okta.com/app/dev-account_gitlabprimary_1/exk7k2gft2VFpVFXa5d1/sso/saml",
      issuer: "https://<gitlab-primary>",
      name_identifier_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
    }
  }
]
```

Cette configuration entraîne :

- L'utilisation de `/users/auth/saml/callback` comme URL du service consommateur d'assertion (ACS) par vos deux sites.
- La définition de l'hôte de l'URL sur l'hôte du site correspondant.

Vous pouvez vérifier cela en visitant le chemin `/users/auth/saml/metadata` de chaque site. Par exemple, la visite de `https://gitlab-primary.example.com/users/auth/saml/metadata` peut répondre avec :

```xml
<md:EntityDescriptor ID="_b9e00d84-d34e-4e3d-95de-122e3c361617" entityID="https://gitlab-primary.example.com"
  xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
  xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">
  <md:SPSSODescriptor AuthnRequestsSigned="false" WantAssertionsSigned="false" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <md:NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</md:NameIDFormat>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://gitlab-primary.example.com/users/auth/saml/callback"    index="0" isDefault="true"/>
    <md:AttributeConsumingService index="1" isDefault="true">
      <md:ServiceName xml:lang="en">Required attributes</md:ServiceName>
      <md:RequestedAttribute FriendlyName="Email address" Name="email" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
      <md:RequestedAttribute FriendlyName="Full name" Name="name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
      <md:RequestedAttribute FriendlyName="Given name" Name="first_name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
      <md:RequestedAttribute FriendlyName="Family name" Name="last_name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
    </md:AttributeConsumingService>
  </md:SPSSODescriptor>
</md:EntityDescriptor>
```

La visite de `https://gitlab-secondary.example.com/users/auth/saml/metadata` peut répondre avec :

```xml
<md:EntityDescriptor ID="_bf71eb57-7490-4024-bfe2-54cec716d4bf" entityID="https://gitlab-primary.example.com"
  xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
  xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">
  <md:SPSSODescriptor AuthnRequestsSigned="false" WantAssertionsSigned="false" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <md:NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</md:NameIDFormat>
    <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://gitlab-secondary.example.com/users/auth/saml/callback"    index="0" isDefault="true"/>
    <md:AttributeConsumingService index="1" isDefault="true">
      <md:ServiceName xml:lang="en">Required attributes</md:ServiceName>
      <md:RequestedAttribute FriendlyName="Email address" Name="email" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
      <md:RequestedAttribute FriendlyName="Full name" Name="name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
      <md:RequestedAttribute FriendlyName="Given name" Name="first_name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
      <md:RequestedAttribute FriendlyName="Family name" Name="last_name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic" isRequired="false"/>
    </md:AttributeConsumingService>
  </md:SPSSODescriptor>
</md:EntityDescriptor>
```

L'attribut `Location` du champ `md:AssertionConsumerService` pointe vers `gitlab-secondary.example.com`.

Après avoir configuré votre IdP SAML pour autoriser l'URL de rappel SAML du site secondaire, vous devriez pouvoir vous connecter avec SAML sur votre site principal ainsi que sur votre site secondaire.

### SAML avec URL distincte et proxy désactivé {#saml-with-separate-url-with-proxying-disabled}

Si vous avez correctement configuré SAML sur le site principal, il devrait fonctionner sur le site secondaire sans configuration supplémentaire.

## OpenID Connect {#openid-connect}

Si vous utilisez un fournisseur OmniAuth [OpenID Connect (OIDC)](../../auth/oidc.md), dans la plupart des cas, il devrait fonctionner sans problème :

- **OIDC with Unified URL** :  Si vous avez correctement configuré OIDC sur le site principal, il devrait fonctionner sur le site secondaire sans configuration supplémentaire.
- **OIDC with separate URL with proxying disabled** :  Si vous avez correctement configuré OIDC sur le site principal, il devrait fonctionner sur le site secondaire sans configuration supplémentaire.
- **OIDC with separate URL with proxying enabled** :  Geo avec URL distincte et proxy activé ne prend pas en charge [OpenID Connect](../../auth/oidc.md). Pour plus d'informations, voir le [ticket 396745](https://gitlab.com/gitlab-org/gitlab/-/issues/396745).

## LDAP {#ldap}

Si vous utilisez LDAP sur votre site **principal**, la même configuration LDAP s'applique également au site **secondaire**, car le site **secondaire** transmet les demandes liées à l'authentification au site **principal**.

Pour vous préparer aux scénarios de reprise après sinistre, vous devez configurer des serveurs LDAP secondaires sur chaque site **secondaire**. Dans ce cas, lorsque vous promouvez le site **secondaire**, les utilisateurs pourront s'authentifier à l'aide du service LDAP répliqué. Sinon, si le service LDAP connecté au site **principal** n'est pas disponible pour le site **secondaire** promu, les utilisateurs ne pourront pas effectuer d'opérations Git via HTTP(s) sur le site **secondaire** en utilisant l'authentification HTTP de base. Cependant, les utilisateurs peuvent toujours utiliser Git avec SSH et des jetons d'accès personnels, sauf si leur compte est verrouillé après plusieurs tentatives de connexion échouées lorsque le service LDAP est indisponible.

> [!note]
> Il est possible que tous les sites **secondaire** partagent un serveur LDAP, mais une latence supplémentaire peut poser problème. Considérez également quel serveur LDAP est disponible dans un scénario de [reprise après sinistre](../disaster_recovery/_index.md) si un site **secondaire** est promu en tant que site **principal**.

Consultez la documentation de votre service LDAP pour savoir comment configurer la réplication dans votre service LDAP. Le processus diffère selon le logiciel ou le service utilisé. Par exemple, OpenLDAP fournit cette [documentation sur la réplication](https://www.openldap.org/doc/admin24/replication.html).
