---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Autorisations utilisateur
description: "Types d'utilisateurs, rôles, autorisations, appartenance, rôles personnalisés et contrôles d'accès."
---

GitLab utilise un système d'autorisations complet qui combine les types d'utilisateurs, les rôles et l'appartenance pour contrôler ce que vous pouvez faire dans les projets et les groupes. Les utilisateurs se voient attribuer des rôles qui définissent leurs autorisations dans les projets et les groupes. Les appartenances et les autorisations associées se propagent des groupes principaux aux sous-groupes et à leurs projets.

Les types d'utilisateurs ont différents niveaux d'accès dans votre instance GitLab, des utilisateurs ordinaires disposant d'autorisations standard aux administrateurs bénéficiant d'un contrôle total du système. Les utilisateurs peuvent également avoir des rôles personnalisés avec des autorisations personnalisées adaptées aux besoins de votre organisation.

## Types d'utilisateurs {#user-types}

{{< cards >}}

- [Utilisateurs auditeurs](../administration/auditor_users.md)
- [Utilisateurs externes](../administration/external_users.md)
- [Utilisateurs internes](../administration/internal_users.md)
- [Utilisateurs Enterprise](../user/enterprise_user/_index.md)
- [Comptes de service](../user/profile/service_accounts.md)

{{< /cards >}}

## Rôles et autorisations {#roles-and-permissions}

{{< cards >}}

- [Rôles et autorisations](../user/permissions.md)
- [Rôle Invité](../administration/guest_users.md)
- [Rôles personnalisés](../user/custom_roles/_index.md)
- [Autorisations personnalisées](../user/custom_roles/abilities.md)

{{< /cards >}}
