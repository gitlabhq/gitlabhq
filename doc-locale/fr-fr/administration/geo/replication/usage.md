---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser un site Geo
---

<!-- Please update `EE::GitLab::GeoGitAccess::GEO_SERVER_DOCS_URL` if this file is moved -->

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Après avoir configuré la [réplication de base de données et configuré les nœuds Geo](../setup/_index.md), utilisez le site GitLab le plus proche comme vous le feriez avec le site principal.

## Opérations Git {#git-operations}

Vous pouvez pousser directement vers un site **secondaire** (à la fois HTTP, SSH y compris Git LFS), et la requête est transmise par proxy au site principal à la place.

Exemple de sortie que vous voyez lors d'un push vers un site **secondaire** :

```shell
$ git push
remote:
remote: This request to a Geo secondary node will be forwarded to the
remote: Geo primary node:
remote:
remote:   ssh://git@primary.geo/user/repo.git
remote:
Everything up-to-date
```

> [!note]
> Si vous utilisez HTTPS au lieu de [SSH](../../../user/ssh.md) pour pousser vers le site secondaire, vous ne pouvez pas stocker les identifiants dans l'URL sous la forme `user:password@URL`. À la place, vous pouvez utiliser un [fichier `.netrc`](https://www.gnu.org/software/inetutils/manual/html_node/The-_002enetrc-file.html) pour les systèmes d'exploitation de type Unix ou `_netrc` pour Windows. Dans ce cas, les identifiants sont stockés en texte brut. Si vous recherchez un moyen plus sécurisé de stocker vos identifiants, vous pouvez utiliser [Git Credential Storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).

## Interface utilisateur web {#web-user-interface}

L'interface utilisateur web sur le site **secondaire** est en lecture/écriture. En tant qu'utilisateur, toutes les actions autorisées sur le site **principal** peuvent être effectuées sur le site **secondaire** sans limitations.

Les requêtes d'accès à l'interface web sur les sites **secondaire** sont automatiquement et de manière transparente transmises par proxy vers le site **principal**.

## Récupérer les modules Go depuis les sites Geo secondaires {#fetch-go-modules-from-geo-secondary-sites}

Les modules Go peuvent être extraits depuis les sites secondaires, avec un certain nombre de limitations :

- La configuration Git (utilisant `insteadOf`) est nécessaire pour récupérer des données depuis le site Geo secondaire.
- Pour les projets privés, les informations d'authentification doivent être spécifiées dans `~/.netrc`.

Pour plus d'informations, voir [Utiliser un projet comme package Go](../../../user/project/use_project_as_go_package.md#fetch-go-modules-from-geo-secondary-sites).
