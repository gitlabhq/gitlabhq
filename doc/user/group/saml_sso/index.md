# SAML SSO for Groups (Beta)

> Introduced in [GitLab Premium][https://about.gitlab.com/products/] 10.7.

This allows SAML to be used for adding users to a group on GitLab.com and other instances where using [site-wide SAML](../../../integration/saml.md) is not possible.

## Enable the beta

Enable the beta by setting the `enable_group_saml` cookie. This can be done with the below JavaScript snippet:

```javascript
javascript:void((function(d){document.cookie='enable_group_saml=' + (document.cookie.indexOf('enable_group_saml=true') >= 0 ?  'false' : 'true') + ';domain=.' + window.location.hostname + ';path=/;expires=' + new Date(Date.now() + 31536000000).toUTCString(); location.reload();})(document));
```

## How to configure

1. Navigate to the group and click Settings -> SAML SSO.
1. Configure your SAML server using the **Assertion consumer service URL** and **Issuer**. See [your identity provider's documentation](#providers) for more details.
1. Configure required assertions using the table below.
1. Find the SSO URL from your Identity Provider and enter it on GitLab.
1. Find and enter the fingerprint for the SAML token signing certificate.

## Assertions

| Field | Supported keys | Notes |
|-|----------------|-------------|
| Email | `email`, `mail` | (required) |
| Full Name | `name` |  |
| First Name | `first_name`, `firstname`, `firstName` |  |
| Last Name | `last_name`, `lastname`, `firstName` |  |

## Providers

| Provider | Documentation |
|----------|---------------|
| ADFS (Active Directory Federation Services) | [Create a Relying Party Trust](https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/operations/create-a-relying-party-trust) |
| Azure | [Configuring single sign-on to applications](https://docs.microsoft.com/en-us/azure/active-directory/active-directory-saas-custom-apps) |
| Auth0 | [Auth0 as Identity Provider](https://auth0.com/docs/protocols/saml/saml-idp-generic) |
| G Suite | [Set up your own custom SAML application](https://support.google.com/a/answer/6087519?hl=en) |
| Okta | [Setting up a SAML application in Okta](https://developer.okta.com/standards/SAML/setting_up_a_saml_application_in_okta) |
| OneLogin | [How to Use the OneLogin SAML Test Connector](https://support.onelogin.com/hc/en-us/articles/202673944-How-to-Use-the-OneLogin-SAML-Test-Connector) |
| Ping Identity | [Add and configure a new SAML application](https://docs.pingidentity.com/bundle/p1_enterpriseConfigSsoSaml_cas/page/enableAppWithoutURL.html) |

## Glossary

| Term | Description |
|------|-------------|
| Identity Provider | The service which manages your user identities such as ADFS, Okta, Onelogin or Ping Identity. |
| Service Provider | SAML considers GitLab to be a service provider. |
| Assertion | A piece of information about a user's identity, such as their name or role. Also know as claims or attributes. |
| SSO | Single Sign On. |
| Assertion consumer service URL | The callback on GitLab where users will be redirected after successfully authenticating with the identity provider. |
| Issuer | How GitLab identifies itself to the identity provider. Also known as a "Relying party trust identifier". |
| Certificate fingerprint | Used to confirm that communications over SAML are secure by checking that the server is signing communications with the correct certificate. Also known as a certificate thumbprint. |
