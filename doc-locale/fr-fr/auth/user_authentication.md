---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Authentification des utilisateurs
description: "Mots de passe, authentification à deux facteurs, clés SSH, jetons d'accès, inventaire des identifiants."
---

GitLab propose plusieurs méthodes d'authentification pour sécuriser l'accès des utilisateurs à leur compte et leurs interactions avec les dépôts. Utilisez des mots de passe avec une authentification à deux facteurs facultative pour l'accès web, des clés SSH pour les opérations Git, et différents types de jetons d'accès pour les interactions avec l'API et l'automatisation.

Sur GitLab Self-Managed et GitLab Dedicated, les administrateurs peuvent configurer le fonctionnement de l'authentification, surveiller l'utilisation des identifiants et mettre en œuvre des politiques de sécurité pour protéger leur instance. Les utilisateurs peuvent gérer leur méthode d'authentification, consulter les sessions actives et configurer des mesures de sécurité supplémentaires, telles que l'authentification à deux facteurs.

{{< cards >}}

- [Mots de passe des utilisateurs](../user/profile/user_passwords.md)
- [Authentification à deux facteurs](../user/profile/account/two_factor_authentication.md)
- [Inventaire des identifiants](../administration/credentials_inventory.md)
- [Clés SSH](../user/ssh.md)
- [Jetons d'accès](../security/tokens/_index.md)
- [Authentification par carte à puce](../administration/auth/smartcard.md)
- [Vérification de l'adresse e-mail du compte](../security/email_verification.md)

{{< /cards >}}
