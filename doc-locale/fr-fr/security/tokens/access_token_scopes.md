---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: "Portées des jetons d'accès"
description: "Permissions accordées par chaque portée pour les jetons d'accès personnels, de groupe et de projet."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `read_service_ping` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/42692#note_1222832412) dans GitLab 17.1. Jetons d'accès personnels uniquement.
- `manage_runner` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/460721) dans GitLab 17.1.
- `self_rotate` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111) dans GitLab 17.9. Activés par défaut.

{{< /history >}}

Les portées définissent ce qu'un jeton d'accès peut faire à un niveau organisationnel spécifique. Chaque portée accorde un ensemble spécifique de permissions.

Le type de jeton détermine la portée d'un jeton :

- Un jeton d'accès personnel peut accéder à tous les groupes et projets disponibles pour l'utilisateur.
- Un jeton d'accès de groupe peut accéder aux sous-groupes et aux projets de son groupe.
- Un jeton d'accès au projet ne peut accéder qu'à son propre projet.

Pour restreindre un jeton d'accès personnel à des ressources et des permissions spécifiques, consultez [les jetons d'accès personnels à granularité fine](../../auth/tokens/fine_grained_access_tokens.md).

| Portée | Disponibilité du jeton | Description |
|-------|------------|-------------|
| `api` | Personnel, groupe, projet | Accorde un accès complet en lecture et en écriture à l'API pour la portée du jeton. Inclut le [registre de conteneurs](../../user/packages/container_registry/_index.md), le [proxy de dépendances](../../user/packages/dependency_proxy/_index.md) et le [registre de paquets](../../user/packages/package_registry/_index.md). <sup>1</sup> |
| `read_api` | Personnel, groupe, projet | Accorde un accès en lecture à l'API pour la portée du jeton. Pour un jeton d'accès personnel, inclut le registre de conteneurs et le registre de paquets ; pour les jetons d'accès de groupe et de projet, le registre de paquets uniquement. |
| `read_repository` | Personnel, groupe, projet | Accorde un accès en lecture (pull) aux dépôts pour la portée du jeton : les projets privés pour un jeton d'accès personnel, tous les dépôts du groupe pour un jeton d'accès de groupe, ou le dépôt du projet pour un jeton d'accès au projet. Utilise Git-over-HTTP ou l'[API des fichiers du dépôt](../../api/repository_files.md). |
| `write_repository` | Personnel, groupe, projet | Accorde un accès en lecture et en écriture (pull et push) aux dépôts pour la portée du jeton : les projets privés pour un jeton d'accès personnel, tous les dépôts du groupe pour un jeton d'accès de groupe, ou le dépôt du projet pour un jeton d'accès au projet. Utilise Git-over-HTTP. Ne prend pas en charge l'authentification par API. |
| `read_registry` | Personnel, groupe, projet | Accorde un accès en lecture (pull) aux images du [registre de conteneurs](../../user/packages/container_registry/_index.md) lorsqu'une autorisation est requise. Disponible uniquement lorsque le registre de conteneurs est activé. La condition de confidentialité diffère selon le type de jeton : elle s'applique à un jeton d'accès personnel lorsqu'un projet est privé, à un jeton d'accès de groupe lorsqu'un projet du groupe est privé, et à un jeton d'accès au projet lorsque le projet est privé. |
| `write_registry` | Personnel, groupe, projet | Accorde un accès en écriture (push) aux images du [registre de conteneurs](../../user/packages/container_registry/_index.md). Disponible uniquement lorsque le registre de conteneurs est activé. Pour les jetons d'accès de groupe et de projet, vous devez également inclure la portée `read_registry` pour envoyer des images. |
| `self_rotate` | Personnel, groupe, projet | Accorde la permission de faire pivoter ce jeton. Ne peut pas faire pivoter d'autres jetons. Pour faire pivoter les jetons d'accès personnels, consultez l'[API des jetons d'accès personnels](../../api/personal_access_tokens.md#rotate-a-personal-access-token). |
| `read_virtual_registry` | Personnel, groupe | Accorde un accès en lecture (pull) aux images de conteneurs via le [proxy de dépendances](../../user/packages/dependency_proxy/_index.md). Disponible uniquement lorsque le proxy de dépendances est activé. <sup>2</sup> |
| `write_virtual_registry` | Personnel, groupe | Accorde un accès en lecture et en écriture (pull, push et suppression) aux images de conteneurs via le [proxy de dépendances](../../user/packages/dependency_proxy/_index.md). Disponible uniquement lorsque le proxy de dépendances est activé. <sup>2</sup> |
| `create_runner` | Personnel, groupe, projet | Accorde la permission de créer des runners pour la portée du jeton. |
| `manage_runner` | Personnel, groupe, projet | Accorde la permission de gérer les runners pour la portée du jeton. |
| `ai_features` | Personnel, groupe, projet | Accorde la permission d'effectuer des actions d'API pour GitLab Duo, l'API Code Suggestions et l'API GitLab Duo Chat. Conçu pour fonctionner avec le plugin GitLab Duo pour JetBrains. Pour toutes les autres extensions, consultez la documentation de l'extension concernée. Ne fonctionne pas pour les versions 16.5, 16.6 et 16.7 de GitLab Self-Managed. Sur GitLab Self-Managed et GitLab Dedicated, cette portée n'est disponible que lorsque GitLab Duo est activé. |
| `k8s_proxy` | Personnel, groupe, projet | Accorde la permission d'effectuer des appels API Kubernetes via l'agent pour Kubernetes. |
| `admin_mode` | Personnel | Accorde la permission d'effectuer des actions d'API lorsque le [mode administrateur](../../administration/settings/sign_in_restrictions.md#admin-mode) est activé. Disponible uniquement pour les administrateurs sur les instances GitLab Self-Managed. |
| `read_service_ping` | Personnel | Accorde l'accès au téléchargement des charges utiles Service Ping via l'API lorsqu'authentifié en tant qu'administrateur. |
| `sudo` | Personnel | Accorde la permission d'effectuer des actions d'API en tant que n'importe quel utilisateur du système, lorsqu'authentifié en tant qu'administrateur. |
| `read_user` | Personnel | Accorde un accès en lecture seule au profil de l'utilisateur authentifié via le point de terminaison API `/user`, qui inclut le nom d'utilisateur, l'adresse e-mail publique et le nom complet. Accorde également l'accès aux points de terminaison API en lecture seule sous [`/users`](../../api/users.md). |

> [!warning]
> Si vous avez activé l'[autorisation externe](../../administration/settings/external_authorization.md), les jetons d'accès personnels et les jetons d'accès au projet ne peuvent pas accéder aux registres de conteneurs ou de paquets. Pour rétablir l'accès, désactivez l'autorisation externe.

**Notes de bas de page** :

1. Pour un jeton d'accès personnel, `api` accorde également un accès complet en lecture et en écriture au registre et au dépôt via Git-over-HTTP. Les jetons d'accès de groupe et de projet n'incluent pas cette clause Git-over-HTTP.
1. Pour un jeton d'accès personnel, les portées du registre virtuel s'appliquent uniquement lorsqu'un projet est privé et qu'une autorisation est requise. Les jetons d'accès de groupe ne sont soumis à aucune condition de ce type.

## Sujets connexes {#related-topics}

- [Jetons d'accès personnels](../../user/profile/personal_access_tokens.md)
- [Jetons d'accès de groupe](../../user/group/settings/group_access_tokens.md)
- [Jetons d'accès au projet](../../user/project/settings/project_access_tokens.md)
- [Vue d'ensemble des jetons](../../security/tokens/_index.md)
