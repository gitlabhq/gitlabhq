---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Synchronisation LDAP
description: "Découvrez comment configurer la synchronisation LDAP pour les utilisateurs et les groupes, et ajuster le calendrier de synchronisation."
---

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Si vous avez [configuré LDAP pour fonctionner avec GitLab](_index.md), GitLab peut synchroniser automatiquement les utilisateurs et les groupes.

La synchronisation LDAP met à jour les informations des utilisateurs et des groupes pour les utilisateurs GitLab existants auxquels une identité LDAP est assignée. Elle ne crée pas de nouveaux utilisateurs GitLab via LDAP.

Vous pouvez modifier le moment où la synchronisation se produit.

## Serveurs LDAP avec limites de débit {#ldap-servers-with-rate-limits}

Certains serveurs LDAP ont des limites de débit configurées.

GitLab interroge le serveur LDAP une fois pour chaque :

- Utilisateur lors du processus de [synchronisation des utilisateurs](#user-sync) planifié.
- Groupe lors du processus de [synchronisation des groupes](#group-sync) planifié.

Dans certains cas, davantage de requêtes vers le serveur LDAP peuvent être déclenchées. Par exemple, lorsqu'une [requête de synchronisation de groupe retourne un attribut `memberuid`](#queries).

Si le serveur LDAP a une limite de débit configurée et que cette limite est atteinte lors du :

- Processus de synchronisation des utilisateurs, le serveur LDAP répond avec un code d'erreur et GitLab bloque cet utilisateur.
- Processus de synchronisation des groupes, le serveur LDAP répond avec un code d'erreur et GitLab supprime les appartenances aux groupes de cet utilisateur.

Vous devez tenir compte des limites de débit de votre serveur LDAP lors de la configuration de la synchronisation LDAP pour éviter les blocages d'utilisateurs indésirables et les suppressions d'appartenance aux groupes.

## Synchronisation des utilisateurs {#user-sync}

{{< history >}}

- Empêcher la synchronisation du nom de profil de l'utilisateur LDAP [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/11336) dans GitLab 15.11.

{{< /history >}}

Une fois par jour, GitLab exécute un worker pour vérifier et mettre à jour les utilisateurs GitLab par rapport à LDAP.

Le processus exécute les vérifications d'accès suivantes :

- S'assurer que l'utilisateur est toujours présent dans LDAP.
- Si le serveur LDAP est Active Directory, s'assurer que l'utilisateur est actif (pas dans un état bloqué/désactivé). Cette vérification est effectuée uniquement si `active_directory: true` est défini dans la configuration LDAP.

Dans Active Directory, un utilisateur est marqué comme désactivé/bloqué si l'attribut de contrôle de compte utilisateur (`userAccountControl:1.2.840.113556.1.4.803`) a le bit 2 activé.

<!-- vale gitlab_base.Spelling = NO -->

Pour plus d'informations, consultez [Bitmask Searches in LDAP](https://ctovswild.com/2009/09/03/bitmask-searches-in-ldap/).

<!-- vale gitlab_base.Spelling = YES -->

Le processus met également à jour les informations utilisateur suivantes :

- Nom. En raison d'un [problème de synchronisation](https://gitlab.com/gitlab-org/gitlab/-/issues/342598), `name` n'est pas synchronisé si [**Empêcher les utilisateurs de modifier leur nom de profil**](../../settings/account_and_limit_settings.md#disable-user-profile-name-changes) est activé ou si `sync_name` est défini sur `false`.
- Adresse e-mail.
- Clés publiques SSH si `sync_ssh_keys` est défini.
- Identité Kerberos si Kerberos est activé.

> [!note]
> Si votre serveur LDAP a une limite de débit, cette limite pourrait être atteinte lors du processus de synchronisation des utilisateurs. Consultez la [documentation sur les limites de débit](#ldap-servers-with-rate-limits) pour plus d'informations.

### Synchroniser le nom de profil de l'utilisateur LDAP {#synchronize-ldap-users-profile-name}

Par défaut, GitLab synchronise le champ du nom de profil de l'utilisateur LDAP.

Pour empêcher cette synchronisation, vous pouvez définir `sync_name` sur `false`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'sync_name' => false,
       }
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             sync_name: false
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'sync_name' => false,
               }
           }
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           sync_name: false
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### Utilisateurs bloqués {#blocked-users}

Un utilisateur est bloqué si l'une des conditions suivantes est remplie :

- [La vérification d'accès échoue](#user-sync) et cet utilisateur est défini dans un état `ldap_blocked` dans GitLab.
- Le serveur LDAP n'est pas disponible lorsque cet utilisateur se connecte.

Si un utilisateur est bloqué, il ne peut pas se connecter, ni envoyer ou récupérer du code.

Un utilisateur bloqué est débloqué lorsqu'il se connecte avec LDAP si toutes les conditions suivantes sont remplies :

- Toutes les conditions de vérification d'accès sont vraies.
- Le serveur LDAP est disponible lorsque l'utilisateur se connecte.

**Tous les utilisateurs** sont bloqués si le serveur LDAP n'est pas disponible lors de l'exécution d'une synchronisation des utilisateurs LDAP.

> [!note]
> Si tous les utilisateurs sont bloqués en raison de l'indisponibilité du serveur LDAP lors de l'exécution d'une synchronisation des utilisateurs LDAP, une synchronisation ultérieure des utilisateurs LDAP ne débloque pas automatiquement ces utilisateurs.

## Synchronisation des groupes {#group-sync}

Si votre LDAP prend en charge la propriété `memberof`, lorsque l'utilisateur se connecte pour la première fois, GitLab déclenche une synchronisation pour les groupes dont l'utilisateur devrait être membre. Ainsi, ils n'ont pas à attendre la synchronisation horaire pour obtenir l'accès à leurs groupes et projets.

Un processus de synchronisation des groupes s'exécute chaque heure, à l'heure pile, et `group_base` doit être défini dans la configuration LDAP pour que les synchronisations LDAP basées sur le CN de groupe fonctionnent. Cela permet à l'appartenance aux groupes GitLab d'être automatiquement mise à jour en fonction des membres des groupes LDAP.

La configuration `group_base` doit être un « conteneur » LDAP de base, tel qu'une « organisation » ou une « unité organisationnelle », qui contient des groupes LDAP devant être disponibles pour GitLab. Par exemple, `group_base` pourrait être `ou=groups,dc=example,dc=com`. Dans le fichier de configuration, cela ressemble à ce qui suit.

> [!note]
> Si votre serveur LDAP a une limite de débit, cette limite pourrait être atteinte lors du processus de synchronisation des groupes. Consultez la [documentation sur les limites de débit](#ldap-servers-with-rate-limits) pour plus d'informations.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'group_base' => 'ou=groups,dc=example,dc=com',
       }
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             group_base: ou=groups,dc=example,dc=com
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'group_base' => 'ou=groups,dc=example,dc=com',
               }
           }
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           group_base: ou=groups,dc=example,dc=com
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

Pour tirer parti de la synchronisation des groupes, les propriétaires de groupes ou les utilisateurs disposant du [rôle Maintainer](../../../user/permissions.md) doivent [créer un ou plusieurs liens de groupes LDAP](../../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap).

> [!note]
> Si vous rencontrez fréquemment des problèmes de connexion entre votre serveur LDAP et votre instance GitLab, essayez de réduire la fréquence à laquelle GitLab effectue une synchronisation des groupes LDAP en définissant l'intervalle du worker de synchronisation des groupes à une valeur supérieure à la valeur par défaut de 1 heure.

### Ajouter des liens de groupes {#add-group-links}

Pour obtenir des informations sur l'ajout de liens de groupes à l'aide de CN et de filtres, consultez la [documentation sur les groupes GitLab](../../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap).

### Assigner un rôle d'administrateur à un groupe LDAP {#assign-an-admin-role-to-an-ldap-group}

En tant qu'extension de la synchronisation des groupes, vous pouvez gérer automatiquement vos administrateurs GitLab globaux. Spécifiez un CN de groupe pour `admin_group` et tous les membres du groupe LDAP reçoivent des privilèges d'administrateur. La configuration ressemble à ce qui suit.

> [!note]
> Les administrateurs ne sont pas synchronisés à moins que `group_base` ne soit également spécifié avec `admin_group`. De plus, spécifiez uniquement le CN de `admin_group`, et non le DN complet. De plus, si un utilisateur LDAP a un rôle `admin`, mais n'est pas membre du groupe `admin_group`, GitLab révoque son rôle `admin` lors de la synchronisation.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'group_base' => 'ou=groups,dc=example,dc=com',
       'admin_group' => 'my_admin_group',
       }
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             group_base: ou=groups,dc=example,dc=com
             admin_group: my_admin_group
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'group_base' => 'ou=groups,dc=example,dc=com',
               'admin_group' => 'my_admin_group',
               }
           }
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           group_base: ou=groups,dc=example,dc=com
           admin_group: my_admin_group
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### Assigner un rôle personnalisé d'administrateur à un groupe LDAP {#assign-a-custom-admin-role-to-an-ldap-group}

{{< details >}}

- Niveau : Ultimate

{{< /details >}}

Vous pouvez assigner un rôle personnalisé d'administrateur à tous les utilisateurs synchronisés à partir d'un groupe LDAP externe. Cette option n'est pas disponible pour les groupes SAML.

Si un utilisateur appartient à plusieurs groupes LDAP avec différents rôles personnalisés assignés, GitLab assigne le rôle associé au groupe LDAP lié en premier.

> [!note]
> Si un utilisateur LDAP avec un rôle personnalisé d'administrateur est supprimé du groupe LDAP après la configuration d'une synchronisation, le rôle personnalisé n'est pas supprimé avant la prochaine synchronisation.

Prérequis :

- Un serveur LDAP intégré à votre instance.
- Accès administrateur.

{{< tabs >}}

{{< tab title="Assign with an LDAP CN" >}}

Pour assigner un rôle personnalisé d'administrateur avec un CN LDAP :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rôles et autorisations**.
1. Dans l'onglet **Synchronisation LDAP**, sélectionnez un **LDAP Server**.
1. Dans le champ **Méthode de synchronisation**, sélectionnez `Group cn`.
1. Dans le champ **Nom du groupe**, commencez à saisir le CN du groupe. Une liste déroulante apparaît avec les CN correspondants dans le `group_base` configuré.
1. Dans la liste déroulante, sélectionnez votre CN.
1. Dans le champ **Rôle d'administrateur personnalisé**, sélectionnez un rôle personnalisé d'administrateur.
1. Sélectionnez **Ajouter**.

GitLab commence à lier le rôle aux utilisateurs LDAP correspondants. Ce processus peut prendre plus d'une heure.

{{< /tab >}}

{{< tab title="Assign with an LDAP filter" >}}

Pour assigner un rôle personnalisé d'administrateur avec un filtre LDAP :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rôles et autorisations**.
1. Dans l'onglet **Synchronisation LDAP**, sélectionnez un **LDAP Server**.
1. Dans le champ **Méthode de synchronisation**, sélectionnez `User filter`.
1. Dans la zone de texte **Utiliser un filtre**, saisissez un filtre. Pour plus de détails, consultez [configurer le filtre utilisateur LDAP](_index.md#set-up-ldap-user-filter).
1. Dans le champ **Rôle d'administrateur personnalisé**, sélectionnez un rôle personnalisé d'administrateur.
1. Sélectionnez **Ajouter**.

GitLab commence à lier le rôle aux utilisateurs LDAP correspondants. Ce processus peut prendre plus d'une heure.

{{< /tab >}}

{{< /tabs >}}

### Verrouillage global des appartenances aux groupes LDAP {#global-ldap-group-memberships-lock}

Les administrateurs GitLab peuvent empêcher les membres de groupes d'inviter de nouveaux membres dans les sous-groupes dont l'appartenance est synchronisée avec LDAP.

Le verrouillage global des appartenances aux groupes s'applique uniquement aux sous-groupes du groupe principal où la synchronisation LDAP est configurée. Aucun utilisateur ne peut modifier l'appartenance d'un groupe principal configuré pour la synchronisation LDAP.

Lorsque le verrouillage global des appartenances aux groupes est activé :

- Vous ne pouvez pas définir un groupe ou un sous-groupe en tant que propriétaire du code. Pour plus d'informations, consultez [Incompatibilité avec les verrouillages globaux des appartenances aux groupes](../../../user/project/codeowners/troubleshooting.md#incompatibility-with-global-group-memberships-locks).
- Seul un administrateur peut gérer les appartenances de n'importe quel groupe, y compris les niveaux d'accès.
- Les utilisateurs ne sont pas autorisés à partager un projet avec d'autres groupes ou à inviter des membres dans un projet créé dans un groupe.

Pour activer le verrouillage global des appartenances aux groupes :

1. [Configurer LDAP](_index.md#configure-ldap).
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Assurez-vous que la case **Verrouiller les adhésions à la synchronisation LDAP** est cochée.

### Gérer les paramètres de synchronisation des groupes LDAP {#change-ldap-group-synchronization-settings-management}

Par défaut, les membres du groupe ayant le rôle Propriétaire peuvent gérer les [paramètres de synchronisation des groupes LDAP](../../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap).

Les administrateurs GitLab peuvent supprimer cette autorisation des propriétaires de groupes :

1. [Configurer LDAP](_index.md#configure-ldap).
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Assurez-vous que la case **Autoriser les propriétaires de groupe à gérer les paramètres liés à LDAP** n'est pas cochée.

Lorsque **Autoriser les propriétaires de groupe à gérer les paramètres liés à LDAP** est désactivé :

- Les propriétaires de groupes ne peuvent pas modifier les paramètres de synchronisation LDAP pour les groupes principaux ni pour les sous-groupes.
- Les administrateurs d'instance peuvent gérer les paramètres de synchronisation des groupes LDAP sur tous les groupes d'une instance.

### Groupes externes {#external-groups}

L'utilisation du paramètre `external_groups` vous permet de marquer tous les utilisateurs appartenant à ces groupes comme [utilisateurs externes](../../external_users.md). L'appartenance aux groupes est vérifiée périodiquement via la tâche en arrière-plan `LdapGroupSync`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'external_groups' => ['interns', 'contractors'],
       }
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             external_groups: ['interns', 'contractors']
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'external_groups' => ['interns', 'contractors'],
             }
           }
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           external_groups: ['interns', 'contractors']
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### Module complémentaire GitLab Duo pour les groupes {#gitlab-duo-add-on-for-groups}

Le paramètre `duo_add_on_groups` [gère automatiquement les sièges du module complémentaire GitLab Duo](../../duo_add_on_seat_management_with_ldap.md) pour les utilisateurs qui s'authentifient via LDAP. Cette fonctionnalité aide les organisations à rationaliser leur processus d'allocation de sièges **GitLab Duo** en fonction des appartenances aux groupes LDAP.

La synchronisation des sièges GitLab Duo s'effectue de deux façons :

- **On user sign-in** : Lorsqu'un utilisateur se connecte via LDAP, GitLab vérifie immédiatement ses appartenances aux groupes.
- **Scheduled sync** : GitLab synchronise automatiquement tous les utilisateurs LDAP quotidiennement à 02h00 (heure du serveur) pour s'assurer que les attributions de sièges sont à jour même sans connexion des utilisateurs.

Pour activer la gestion des sièges du module complémentaire pour les groupes, vous devez configurer le paramètre `duo_add_on_groups` dans votre instance GitLab :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'duo_add_on_groups' => ['duo_group_1', 'duo_group_2'],
       }
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             duo_add_on_groups: ['duo_group_1', 'duo_group_2']
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
                 'duo_add_on_groups' => ['duo_group_1', 'duo_group_2'],
             }
           }
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           duo_add_on_groups: ['duo_group_1', 'duo_group_2']
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### Détails techniques de la synchronisation des groupes {#group-sync-technical-details}

Cette section décrit quelles requêtes LDAP sont exécutées et quel comportement vous pouvez attendre de la synchronisation des groupes.

Si l'appartenance d'un utilisateur à un groupe LDAP change, son niveau d'accès au groupe peut être rétrogradé. Par exemple, si un utilisateur a le rôle Propriétaire dans un groupe et que la prochaine synchronisation des groupes révèle qu'il ne devrait avoir que le rôle Développeur, son accès est ajusté en conséquence. La seule exception est si l'utilisateur est le dernier propriétaire d'un groupe. Les groupes ont besoin d'au moins un propriétaire pour remplir les fonctions administratives.

#### Attribution du rôle d'accès minimum avec accès restreint {#minimal-access-role-assignment-with-restricted-access}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206932) dans GitLab 18.6 [avec un indicateur](../../feature_flags/_index.md) nommé `bso_minimal_access_fallback`. Désactivé par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225777) dans GitLab 18.10.

{{< /history >}}

Lorsque l'[accès restreint](../../../user/group/manage.md#restricted-access) est activé et qu'aucun siège d'abonnement n'est disponible, les utilisateurs se voient attribuer le rôle d'accès minimum lors de la synchronisation des groupes LDAP.

Pour plus d'informations, consultez [Comportement de provisionnement avec SAML, SCIM et LDAP](../../../user/group/manage.md#provisioning-behavior-with-saml-scim-and-ldap).

#### Types/attributs de groupes LDAP pris en charge {#supported-ldap-group-typesattributes}

GitLab prend en charge les groupes LDAP qui utilisent les attributs de membre :

- `member`
- `submember`
- `uniquemember`
- `memberof`
- `memberuid`

Cela signifie que la synchronisation des groupes prend en charge (au moins) les groupes LDAP avec les classes d'objets suivantes :

- `groupOfNames`
- `posixGroup`
- `groupOfUniqueNames`

Les autres classes d'objets devraient fonctionner si les membres sont définis comme l'un des attributs mentionnés.

Active Directory prend en charge les groupes imbriqués. La synchronisation des groupes résout récursivement les appartenances si `active_directory: true` est défini dans le fichier de configuration.

##### Appartenances aux groupes imbriqués {#nested-group-memberships}

Les appartenances aux groupes imbriqués ne sont résolues que si le groupe imbriqué est trouvé dans le `group_base` configuré. Par exemple, si GitLab voit un groupe imbriqué avec le DN `cn=nested_group,ou=special_groups,dc=example,dc=com` mais que le `group_base` configuré est `ou=groups,dc=example,dc=com`, `cn=nested_group` est ignoré.

#### Requêtes {#queries}

- Chaque groupe LDAP est interrogé au maximum une fois avec la base `group_base` et le filtre `(cn=<cn_from_group_link>)`.
- Si le groupe LDAP a l'attribut `memberuid`, GitLab exécute une autre requête LDAP par membre pour obtenir le DN complet de chaque utilisateur. Ces requêtes sont exécutées avec la base `base`, la portée `baseObject`, et un filtre selon que `user_filter` est défini. Le filtre peut être `(uid=<uid_from_group>)` ou une combinaison de `user_filter`.

#### Benchmarks {#benchmarks}

La synchronisation des groupes a été conçue pour être aussi performante que possible. Les données sont mises en cache, les requêtes de base de données sont optimisées et les requêtes LDAP sont réduites au minimum. Le dernier test de performance a révélé les métriques suivantes :

Pour 20 000 utilisateurs LDAP, 11 000 groupes LDAP et 1 000 groupes GitLab avec 10 liens de groupes LDAP chacun :

- La synchronisation initiale (aucun membre existant assigné dans GitLab) a pris 1,8 heure
- Les synchronisations suivantes (vérification des appartenances, sans écriture) ont pris 15 minutes

Ces métriques sont destinées à fournir une base de référence et les performances peuvent varier en fonction de nombreux facteurs. Ce benchmark était extrême et la plupart des instances n'ont pas autant d'utilisateurs ou de groupes. La vitesse du disque, les performances de la base de données, le réseau et le temps de réponse du serveur LDAP affectent ces métriques.

## Ajuster le calendrier de synchronisation LDAP {#adjust-ldap-sync-schedule}

Vous pouvez modifier l'heure et l'intervalle auxquels LDAP synchronise les utilisateurs, les groupes et les sièges du module complémentaire GitLab Duo.

### Pour les utilisateurs {#for-users}

Par défaut, GitLab exécute un worker une fois par jour à 01h30 (heure du serveur) pour vérifier et mettre à jour les utilisateurs GitLab par rapport à LDAP.

> [!warning]
> N'exécutez pas le processus de synchronisation trop fréquemment, car cela pourrait entraîner l'exécution simultanée de plusieurs synchronisations. La plupart des installations n'ont pas besoin de modifier le calendrier de synchronisation. Pour plus d'informations, consultez la [documentation sur la sécurité LDAP](_index.md#security).

Vous pouvez configurer manuellement les heures de synchronisation des utilisateurs LDAP en définissant les valeurs de configuration suivantes, au format cron. Si nécessaire, vous pouvez utiliser un [générateur crontab](https://it-tools.tech/crontab-generator). L'exemple ci-dessous montre comment configurer la synchronisation des utilisateurs LDAP pour qu'elle s'exécute une fois toutes les 12 heures, à l'heure pile.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_sync_worker_cron'] = "0 */12 * * *"
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       cron_jobs:
         ldap_sync_worker:
           cron: "0 */12 * * *"
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_sync_worker_cron'] = "0 */12 * * *"
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     ee_cron_jobs:
       ldap_sync_worker:
         cron: "0 */12 * * *"
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### Pour les groupes {#for-groups}

Par défaut, GitLab exécute un processus de synchronisation des groupes chaque heure, à l'heure pile. Les valeurs affichées sont au format cron. Si nécessaire, vous pouvez utiliser un [générateur crontab](https://it-tools.tech/crontab-generator).

> [!warning]
> Ne démarrez pas le processus de synchronisation trop fréquemment, car cela pourrait entraîner l'exécution simultanée de plusieurs synchronisations. La plupart des installations n'ont pas besoin de modifier le calendrier de synchronisation.

Vous pouvez configurer manuellement les heures de synchronisation des groupes LDAP en définissant les valeurs de configuration suivantes. L'exemple ci-dessous montre comment configurer la synchronisation des groupes pour qu'elle s'exécute une fois toutes les deux heures, à l'heure pile.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_group_sync_worker_cron'] = "0 */2 * * *"
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       cron_jobs:
         ldap_group_sync_worker:
           cron: "*/30 * * * *"
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_group_sync_worker_cron'] = "0 */2 * * *"
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     ee_cron_jobs:
       ldap_group_sync_worker:
         cron: "*/30 * * * *"
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### Pour les sièges du module complémentaire GitLab Duo {#for-gitlab-duo-add-on-seats}

Par défaut, GitLab exécute un processus de synchronisation des sièges du module complémentaire GitLab Duo une fois par jour à 02h00 (heure du serveur) pour vérifier les appartenances aux groupes LDAP et assigner ou retirer les sièges du module complémentaire GitLab Duo en conséquence.

> [!warning]
> Ne démarrez pas le processus de synchronisation trop fréquemment, car cela pourrait entraîner l'exécution simultanée de plusieurs synchronisations. La plupart des installations n'ont pas besoin de modifier le calendrier de synchronisation.

Vous pouvez configurer manuellement les heures de synchronisation des sièges du module complémentaire GitLab Duo LDAP en définissant des valeurs de configuration. L'exemple suivant montre comment configurer la synchronisation pour qu'elle s'exécute une fois toutes les quatre heures.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_add_on_seat_sync_worker_cron'] = "0 */4 * * *"
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       cron_jobs:
         ldap_add_on_seat_sync_worker:
           cron: "0 */4 * * *"
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_add_on_seat_sync_worker_cron'] = "0 */4 * * *"
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     ee_cron_jobs:
       ldap_add_on_seat_sync_worker:
         cron: "0 */4 * * *"
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}
