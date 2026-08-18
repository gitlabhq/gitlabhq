---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Authentification et autorisation
description: "Identité des utilisateurs, authentification, autorisations, contrôles d'accès et bonnes pratiques de sécurité."
---

GitLab utilise l'authentification et l'autorisation pour protéger vos ressources sans limiter la collaboration.

L'authentification vérifie votre identité à l'aide de méthodes telles que les mots de passe, l'authentification à deux facteurs, les clés SSH, les jetons d'accès et les fournisseurs d'identité externes tels que SAML et OAuth. L'autorisation détermine ce que vous pouvez faire, grâce aux rôles et aux autorisations granulaires permettant de contrôler l'accès aux groupes, aux projets et aux ressources. Ensemble, ces systèmes créent un cadre de sécurité qui s'adapte aussi bien aux utilisateurs individuels qu'aux organisations d'entreprise.

La compréhension du modèle de sécurité de GitLab vous aide à mettre en œuvre des contrôles d'accès qui équilibrent les exigences de sécurité et l'efficacité opérationnelle.

{{< cards >}}

- [Identité des utilisateurs](../administration/auth/_index.md)
- [Authentification des utilisateurs](user_authentication.md)
- [Autorisations utilisateur](user_permissions.md)
- [Bonnes pratiques d'authentification et d'autorisation](auth_practices.md)
- [Glossaire d'authentification et d'autorisation](auth_glossary.md)

{{< /cards >}}
