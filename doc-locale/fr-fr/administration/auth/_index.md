---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Méthodes d'authentification telles que LDAP, OmniAuth, SAML, SCIM, OIDC et OAuth"
title: "Identité de l'utilisateur"
---

GitLab s'intègre à un certain nombre d'outils et de protocoles tiers pour mieux prendre en charge l'authentification et l'autorisation.

Connectez GitLab à l'infrastructure d'identité existante de votre organisation pour centraliser la gestion des utilisateurs et appliquer des politiques de sécurité. Vous pouvez vous intégrer aux fournisseurs d'identité LDAP, SAML, OAuth ou SCIM et aux services d'annuaire pour l'authentification et l'autorisation.

Sur GitLab Self-Managed et GitLab Dedicated, les administrateurs peuvent s'intégrer à des fournisseurs d'identité tels qu'Active Directory, Google Workspace ou Azure AD pour provisionner automatiquement les utilisateurs, synchroniser les appartenances aux groupes et activer l'authentification unique. Les groupes GitLab.com peuvent également s'intégrer aux fournisseurs d'identité SAML pour centraliser l'authentification et le provisionnement des utilisateurs.

Choisissez parmi plusieurs méthodes d'intégration en fonction des besoins de votre organisation :

- LDAP pour la synchronisation des annuaires
- SAML pour l'authentification unique
- OAuth pour l'authentification tierce
- SCIM pour le provisionnement et le déprovisionnement automatisés des utilisateurs

## Concepts fondamentaux {#core-concepts}

{{< cards >}}

- [LDAP](ldap/_index.md)
- [OmniAuth](../../integration/omniauth.md)
- [SAML](../../integration/saml.md)
- [SAML Group Sync](../../user/group/saml_sso/group_sync.md)
- [SCIM](../settings/scim_setup.md)

{{< /cards >}}

## GitLab.com comparé à GitLab Self-Managed {#gitlabcom-compared-to-gitlab-self-managed}

Les fournisseurs externes d'authentification et d'autorisation peuvent prendre en charge les fonctionnalités suivantes. Pour plus d'informations, consultez les liens indiqués sur cette page pour chaque fournisseur externe.

| Fonctionnalité                                      | GitLab.com                              | GitLab Self-Managed                       |
|-------------------------------------------------|-----------------------------------------|------------------------------------|
| **User Provisioning**                           | SCIM<br>SAML <sup>1</sup> | LDAP <sup>1</sup><br>SAML <sup>1</sup><br>[OmniAuth Providers](../../integration/omniauth.md#supported-providers) <sup>1</sup><br>SCIM  |
| **User Detail Updating** (hors gestion des groupes) | Non disponible                           | LDAP Sync                          |
| **Authentification**                              | SAML au niveau du groupe principal (1 fournisseur)    | LDAP (plusieurs fournisseurs)<br>Generic OAuth 2.0<br>SAML (1 seul autorisé par fournisseur unique)<br>Kerberos<br>JWT<br>Carte à puce<br>[OmniAuth Providers](../../integration/omniauth.md#supported-providers) (1 seul autorisé par fournisseur unique) |
| **Provider-to-GitLab Role Sync**                | SAML Group Sync                         | LDAP Group Sync<br>SAML Group Sync ([GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/285150) et versions ultérieures) |
| **User Removal**                                | SCIM (supprimer l'utilisateur du groupe principal) | LDAP (supprimer l'utilisateur des groupes et bloquer l'accès à l'instance)<br>SCIM |

**Remarques** :

1. Grâce au provisionnement Just-In-Time (JIT), les comptes utilisateurs sont créés lors de la première connexion de l'utilisateur.
