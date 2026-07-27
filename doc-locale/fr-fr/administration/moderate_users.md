---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Bloquer, désactiver, bannir ou faire confiance aux utilisateurs pour contrôler l'accès à l'instance et son activité."
gitlab_dedicated: yes
title: Modérer les utilisateurs
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Si vous êtes un administrateur d'instance, vous disposez de plusieurs options pour modérer et contrôler l'accès des utilisateurs.

> [!note]
> Cette rubrique concerne spécifiquement la modération des utilisateurs dans GitLab Self-Managed. Pour les informations relatives aux groupes, consultez la [documentation des groupes](../user/group/moderate_users.md).

## Afficher les utilisateurs {#view-users}

Pour afficher tous les utilisateurs de votre instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.

Sélectionnez un utilisateur pour afficher les informations de son compte.

### Afficher les utilisateurs par type {#view-users-by-type}

{{< history >}}

- Le filtrage des utilisateurs par type a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/541186) dans GitLab 18.1.

{{< /history >}}

Les instances GitLab établies peuvent souvent avoir un grand nombre d'utilisateurs humains et de bots. Vous pouvez filtrer la liste des utilisateurs pour n'afficher que les utilisateurs humains ou les [utilisateurs bots](internal_users.md).

Pour afficher les utilisateurs par type :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Dans la zone de recherche, saisissez un filtre.
   - Pour afficher les utilisateurs humains, saisissez **Type=Humans**.
   - Pour afficher les utilisateurs bots, saisissez **Type=Bots**.
1. Appuyez sur <kbd>Entrée</kbd>.

## Utilisateurs facturables {#billable-users}

Vous pouvez afficher et mettre à jour les [utilisateurs facturables](../subscriptions/manage_seats.md#billable-users) de votre instance via la console Rails.

### Vérifier les utilisateurs facturables quotidiens et historiques {#check-daily-and-historical-billable-users}

Pour obtenir une liste des utilisateurs facturables quotidiens et historiques dans votre instance GitLab :

1. [Démarrez une session de console Rails](operations/rails_console.md#starting-a-rails-console-session).
1. Comptez le nombre d'utilisateurs dans l'instance :

   ```ruby
   User.billable.count
   ```

1. Obtenez le nombre maximum historique d'utilisateurs sur l'instance au cours de l'année écoulée :

   ```ruby
   ::HistoricalData.max_historical_user_count(from: 1.year.ago.beginning_of_day, to: Time.current.end_of_day)
   ```

### Mettre à jour les utilisateurs facturables quotidiens et historiques {#update-daily-and-historical-billable-users}

Pour déclencher une mise à jour manuelle des utilisateurs facturables quotidiens et historiques dans votre instance GitLab :

1. [Démarrez une session de console Rails](operations/rails_console.md#starting-a-rails-console-session).
1. Forcez une mise à jour des utilisateurs facturables quotidiens :

   ```ruby
   identifier = Analytics::UsageTrends::Measurement.identifiers[:billable_users]
   ::Analytics::UsageTrends::CounterJobWorker.new.perform(identifier, User.minimum(:id), User.maximum(:id), Time.zone.now)
   ```

1. Forcez une mise à jour du nombre maximum historique d'utilisateurs facturables :

   ```ruby
   ::HistoricalDataWorker.new.perform
   ```

## Utilisateurs en attente d'approbation {#users-pending-approval}

Un utilisateur en état d'attente d'approbation nécessite une action de la part d'un administrateur. L'inscription d'un utilisateur peut être en état d'attente d'approbation parce qu'un administrateur a activé l'une des options suivantes :

- Paramètre [Exiger l'approbation de l'administrateur pour la création de nouveaux comptes utilisateur](settings/sign_up_restrictions.md#require-administrator-approval-for-new-user-accounts).
- [Limite d'utilisateurs](settings/sign_up_restrictions.md#user-cap).
- [Accès restreint](settings/sign_up_restrictions.md#restricted-access) sans siège sous licence disponible, lorsqu'un [utilisateur inactif](settings/sign_up_restrictions.md#dormant-user-reactivation) tente de se reconnecter.
- [Bloquer les utilisateurs créés automatiquement (OmniAuth)](../integration/omniauth.md#configure-common-settings)
- [Bloquer les utilisateurs créés automatiquement (LDAP)](auth/ldap/_index.md#basic-configuration-settings)

Lorsqu'un utilisateur s'inscrit à un compte alors que ce paramètre est activé :

- L'utilisateur est placé dans un état **En attente d'approbation**.
- L'utilisateur voit un message lui indiquant que son compte est en attente d'approbation par un administrateur.

Un utilisateur en attente d'approbation :

- Est fonctionnellement identique à un utilisateur [bloqué](#block-a-user).
- Ne peut pas se connecter.
- Ne peut pas accéder aux dépôts Git ni à l'API GitLab.
- Ne reçoit aucune notification de GitLab.
- Ne consomme pas de [siège](../subscriptions/manage_seats.md#billable-users).

Un administrateur doit [approuver leur inscription](#approve-or-reject-a-new-user-account) pour leur permettre de se connecter.

### Afficher les inscriptions d'utilisateurs en attente d'approbation {#view-user-sign-ups-pending-approval}

{{< history >}}

- Le filtrage des utilisateurs par état a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/238183) dans GitLab 17.0.

{{< /history >}}

Pour afficher les inscriptions d'utilisateurs en attente d'approbation :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Dans la zone de recherche, filtrez par **State=Pending approval**, puis appuyez sur <kbd>Entrée</kbd>.

### Approuver ou rejeter un nouveau compte utilisateur {#approve-or-reject-a-new-user-account}

{{< history >}}

- Le filtrage des utilisateurs par état a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/238183) dans GitLab 17.0.

{{< /history >}}

Une inscription d'utilisateur en attente d'approbation peut être approuvée ou rejetée depuis la zone **Admin**.

Pour approuver ou rejeter une inscription d'utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Dans la zone de recherche, filtrez par **State=Pending approval** et appuyez sur <kbd>Entrée</kbd>.
1. Pour l'inscription d'utilisateur que vous souhaitez approuver ou rejeter, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}), puis **Approuver** ou **Rejeter**.

Approuver un utilisateur :

- Active leur compte.
- Change l'état de l'utilisateur en actif.
- Consomme un [siège](../subscriptions/manage_seats.md#billable-users) d'abonnement.

Rejeter un utilisateur :

- Empêche l'utilisateur de se connecter ou d'accéder aux informations de l'instance.
- Supprime l'utilisateur.

## Afficher les utilisateurs en attente de promotion de rôle {#view-users-pending-role-promotion}

Si l'[approbation de l'administrateur pour les promotions de rôle](settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions) est activée, les demandes d'adhésion qui font passer des utilisateurs existants à un rôle facturable nécessitent l'approbation de l'administrateur.

Pour afficher les utilisateurs en attente de promotion de rôle :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Sélectionnez **Promotions de rôle**.

Une liste des utilisateurs avec le rôle le plus élevé demandé s'affiche. Vous pouvez **Approuver** ou **Rejeter** les demandes.

## Bloquer et débloquer des utilisateurs {#block-and-unblock-users}

Les administrateurs GitLab peuvent bloquer et débloquer des utilisateurs. Vous devez bloquer un utilisateur lorsque vous ne souhaitez pas qu'il accède à l'instance, mais que vous souhaitez conserver ses données.

Un utilisateur bloqué :

- Ne peut pas se connecter ni accéder à aucun dépôt.
  - Toutes les données associées restent dans ces dépôts.
- Ne peut pas utiliser les [commandes slash dans Slack](../user/project/integrations/gitlab_slack_application.md#slash-commands).
- N'occupe pas de [siège](../subscriptions/manage_seats.md#billable-users).

### Bloquer un utilisateur {#block-a-user}

Prérequis :

- Vous devez être un administrateur de l'instance.

Vous pouvez bloquer l'accès d'un utilisateur à l'instance.

Pour bloquer un utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Pour l'utilisateur que vous souhaitez bloquer, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}), puis **Bloquer**.

Pour signaler un abus de la part d'autres utilisateurs, consultez [signaler un abus](../user/report_abuse.md). Pour plus d'informations sur les signalements d'abus dans la zone **Admin**, consultez [résoudre les signalements d'abus](review_abuse_reports.md#resolving-abuse-reports).

### Débloquer un utilisateur {#unblock-a-user}

{{< history >}}

- Le filtrage des utilisateurs par état a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/238183) dans GitLab 17.0.

{{< /history >}}

Vous pouvez débloquer un utilisateur pour lui redonner accès à l'instance.

Pour débloquer un utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Dans la zone de recherche, filtrez par **State=Blocked** et appuyez sur <kbd>Entrée</kbd>.
1. Pour l'utilisateur que vous souhaitez débloquer, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}), puis **Débloquer**.

L'état de l'utilisateur est défini sur actif et il consomme un [siège](../subscriptions/manage_seats.md#billable-users).

> [!note]
> Les utilisateurs peuvent également être débloqués à l'aide de l'[API GitLab](../api/user_moderation.md#unblock-access-to-a-user).

L'option de déblocage peut être indisponible pour les utilisateurs LDAP. Pour activer l'option de déblocage, l'identité LDAP doit d'abord être supprimée :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Dans la zone de recherche, filtrez par **State=Blocked** et appuyez sur <kbd>Entrée</kbd>.
1. Sélectionnez un utilisateur.
1. Sélectionnez l'onglet **Identités**.
1. Trouvez le fournisseur LDAP et sélectionnez **Supprimer**.

## Désactiver et réactiver des utilisateurs {#deactivate-and-reactivate-users}

Les administrateurs GitLab peuvent désactiver et réactiver des utilisateurs. Vous devez désactiver un utilisateur s'il n'a aucune activité récente et que vous ne souhaitez pas qu'il occupe un siège sur l'instance.

GitLab détermine l'activité récente d'un utilisateur sur la base de l'horodatage `last_active_at`, qui est le plus récent entre :

- `last_activity_on` : L'horodatage de la dernière activité enregistrée de l'utilisateur dans GitLab (comme la création de tickets, de merge requests ou de commentaires).
- `current_sign_in_at` : L'horodatage de la connexion la plus récente de l'utilisateur.

Si l'horodatage de connexion actuel d'un utilisateur est plus récent que sa dernière activité enregistrée, l'utilisateur est considéré comme récemment actif, même s'il n'a utilisé aucune fonctionnalité GitLab depuis sa connexion.

Un utilisateur désactivé :

- Peut se connecter à GitLab.
  - Si un utilisateur désactivé se connecte, il est automatiquement réactivé.
- Ne peut pas accéder aux dépôts ni à l'API.
- Ne peut pas utiliser les [commandes slash dans Slack](../user/project/integrations/gitlab_slack_application.md#slash-commands).
- N'occupe pas de siège. Pour plus d'informations, consultez [les utilisateurs facturables](../subscriptions/manage_seats.md#billable-users).

Lorsque vous désactivez un utilisateur, ses projets, groupes et historique sont conservés.

### Désactiver un utilisateur {#deactivate-a-user}

Prérequis :

- L'utilisateur n'a eu aucune activité au cours des 90 derniers jours.

Pour désactiver un utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Pour l'utilisateur que vous souhaitez désactiver, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}) puis **Désactiver**.
1. Dans la boîte de dialogue, sélectionnez **Désactiver**.

L'utilisateur reçoit une notification par e-mail indiquant que son compte a été désactivé. Après cet e-mail, il ne reçoit plus de notifications. Pour plus d'informations, consultez [les e-mails de désactivation d'utilisateur](settings/email.md#user-deactivation-emails).

Pour désactiver des utilisateurs avec l'API GitLab, consultez [désactiver un utilisateur](../api/user_moderation.md#deactivate-a-user). Pour des informations sur les restrictions permanentes d'utilisateurs, consultez [bloquer et débloquer des utilisateurs](#block-and-unblock-users).

Pour supprimer un utilisateur d'un abonnement GitLab.com, consultez [Supprimer des utilisateurs de votre abonnement](../subscriptions/manage_seats.md#remove-users-from-subscription).

### Désactiver automatiquement les utilisateurs inactifs {#automatically-deactivate-dormant-users}

{{< history >}}

- Période de temps personnalisable [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/336747) dans GitLab 15.4
- La limite inférieure de la période d'inactivité fixée à 90 jours [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/100793) dans GitLab 15.5

{{< /history >}}

Les administrateurs peuvent activer la désactivation automatique des utilisateurs qui :

- Ont été créés il y a plus d'une semaine et ne se sont pas connectés.
- N'ont eu aucune activité pendant une période spécifiée (par défaut et minimum : 90 jours).

Pour désactiver automatiquement les membres inactifs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Limitations du compte**.
1. Sous **Utilisateurs inactifs**, cochez **Désactiver les utilisateurs inactifs après une période d'inactivité**.
1. Sous **Jours d'inactivité avant désactivation**, saisissez le nombre de jours avant la désactivation. La valeur minimale est de 90 jours.
1. Sélectionnez **Sauvegarder les modifications**.

Lorsque cette fonctionnalité est activée, GitLab exécute un job quotidien pour désactiver les utilisateurs inactifs.

Un maximum de 100 000 utilisateurs peut être désactivé par jour.

Par défaut, les utilisateurs reçoivent une notification par e-mail lorsque leur compte est désactivé. Vous pouvez désactiver les [e-mails de désactivation d'utilisateur](settings/email.md#user-deactivation-emails).

> [!note]
> Les bots générés par GitLab sont exclus de la désactivation automatique des utilisateurs inactifs.

### Supprimer automatiquement les utilisateurs non confirmés {#automatically-delete-unconfirmed-users}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/352514) dans GitLab 16.1 [avec un indicateur](feature_flags/_index.md) nommé `delete_unconfirmed_users_setting`. Désactivé par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124982) dans GitLab 16.2.

{{< /history >}}

Prérequis :

- Vous devez être administrateur.

Vous pouvez activer la suppression automatique des utilisateurs qui :

- N'ont jamais confirmé leur adresse e-mail.
- Se sont inscrits à GitLab il y a plus d'un nombre de jours spécifié.

Vous pouvez configurer ces paramètres à l'aide de l'[API Settings](../api/settings.md) ou dans une console Rails :

```ruby
 Gitlab::CurrentSettings.update(delete_unconfirmed_users: true)
 Gitlab::CurrentSettings.update(unconfirmed_users_delete_after_days: 365)
```

Lorsque le paramètre `delete_unconfirmed_users` est activé, GitLab exécute un job toutes les heures pour supprimer les utilisateurs non confirmés. Le job ne supprime que les utilisateurs qui se sont inscrits il y a plus de `unconfirmed_users_delete_after_days` jours.

Ce job ne s'exécute que lorsque `email_confirmation_setting` est défini sur `soft` ou `hard`.

Un maximum de 240 000 utilisateurs peut être supprimé par jour.

### Réactiver un utilisateur {#reactivate-a-user}

{{< history >}}

- Le filtrage des utilisateurs par état a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/238183) dans GitLab 17.0.

{{< /history >}}

Pour réactiver un utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Dans la zone de recherche, filtrez par **State=Deactivated** et appuyez sur <kbd>Entrée</kbd>.
1. Pour l'utilisateur que vous souhaitez réactiver, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}), puis **Activer**.

L'état de l'utilisateur est défini sur actif et il consomme un [siège](../subscriptions/manage_seats.md#billable-users).

> [!note]
> Un utilisateur désactivé peut également réactiver son compte lui-même en se reconnectant via l'interface utilisateur. Les utilisateurs peuvent également être réactivés à l'aide de l'[API GitLab](../api/user_moderation.md#reactivate-a-user).
>
> Lorsque l'[accès restreint](settings/sign_up_restrictions.md#restricted-access) est actif et qu'aucun siège sous licence n'est disponible, les utilisateurs inactifs qui tentent de se reconnecter sont mis en attente d'approbation au lieu d'être réactivés.

## Bannir et débannir des utilisateurs {#ban-and-unban-users}

{{< history >}}

- Le masquage des merge requests des utilisateurs bannis a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107836) dans GitLab 15.8 [avec un indicateur](feature_flags/_index.md) nommé `hide_merge_requests_from_banned_users`. Désactivé par défaut.
- Le masquage des commentaires des utilisateurs bannis a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112973) dans GitLab 15.11 [avec un indicateur](feature_flags/_index.md) nommé `hidden_notes`. Désactivé par défaut.
- Le masquage des projets des utilisateurs bannis a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121488) dans GitLab 16.2 [avec un indicateur](feature_flags/_index.md) nommé `hide_projects_of_banned_users`. Désactivé par défaut.
- Le masquage des merge requests des utilisateurs bannis est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188770) dans GitLab 18.0. Indicateur de feature flag `hide_merge_requests_from_banned_users` supprimé.

{{< /history >}}

Les administrateurs GitLab peuvent bannir et débannir des utilisateurs. Vous devez bannir un utilisateur lorsque vous souhaitez le bloquer et masquer son activité sur l'instance.

Un utilisateur banni :

- Ne peut pas se connecter ni accéder à aucun dépôt.
  - Tous les projets, tickets, merge requests ou commentaires associés sont masqués.
- Ne peut pas utiliser les [commandes slash dans Slack](../user/project/integrations/gitlab_slack_application.md#slash-commands).
- N'occupe pas de [siège](../subscriptions/manage_seats.md#billable-users).

### Bannir un utilisateur {#ban-a-user}

Vous pouvez bannir un utilisateur pour le bloquer et masquer ses contributions.

Pour bannir un utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. À côté du membre que vous souhaitez bannir, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}).
1. Dans la liste déroulante, sélectionnez **Bannir le membre**.

### Débannir un utilisateur {#unban-a-user}

{{< history >}}

- Le filtrage des utilisateurs par état a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/238183) dans GitLab 17.0.

{{< /history >}}

Pour débannir un utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Dans la zone de recherche, filtrez par **State=Banned** et appuyez sur <kbd>Entrée</kbd>.
1. À côté du membre que vous souhaitez bannir, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}).
1. Dans la liste déroulante, sélectionnez **Unban member**.

L'état de l'utilisateur est défini sur actif et il consomme un [siège](../subscriptions/manage_seats.md#billable-users).

## Supprimer un utilisateur {#delete-a-user}

Pour supprimer un utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Pour l'utilisateur que vous souhaitez supprimer, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}), puis **Supprimer l'utilisateur**.
1. Saisissez le nom d'utilisateur.
1. Sélectionnez l'une des options suivantes :
   - **Supprimer l'utilisateur**, pour supprimer uniquement l'utilisateur.
   - **Supprimer l'utilisateur et ses contributions**, pour supprimer l'utilisateur et ses contributions, telles que les merge requests, les tickets et les groupes dont il est le seul propriétaire.

> [!note]
> Vous ne pouvez supprimer un utilisateur que s'il est un propriétaire hérité ou direct d'un groupe. Vous ne pouvez pas supprimer un utilisateur s'il est le seul propriétaire du groupe.

## Faire confiance aux utilisateurs et ne plus leur faire confiance {#trust-and-untrust-users}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132402) dans GitLab 16.5.
- Le filtrage des utilisateurs par état a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/238183) dans GitLab 17.0.

{{< /history >}}

Par défaut, les utilisateurs ne sont pas approuvés et sont bloqués lorsqu'ils tentent de créer des tickets, des notes et des extraits de code considérés comme du spam. Lorsque vous faites confiance à un utilisateur, il peut créer des tickets, des notes et des extraits de code sans être bloqué.

### Faire confiance à un utilisateur {#trust-a-user}

Pour faire confiance à un utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Sélectionnez un utilisateur.
1. Dans la liste déroulante **Administration des utilisateurs**, sélectionnez **Faire confiance à l'utilisateur**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Faire confiance à l'utilisateur**.

### Ne plus faire confiance à un utilisateur {#untrust-a-user}

Pour ne plus faire confiance à un utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Dans la zone de recherche, filtrez par **State=Trusted** et appuyez sur <kbd>Entrée</kbd>.
1. Sélectionnez un utilisateur.
1. Dans la liste déroulante **Administration des utilisateurs**, sélectionnez **Ne plus faire confiance à l'utilisateur**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Ne plus faire confiance à l'utilisateur**.

## Dépannage {#troubleshooting}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

Lors de la modération des utilisateurs, vous pouvez avoir besoin d'effectuer des actions en masse sur ceux-ci en fonction de certaines conditions. Les scripts de console Rails suivants montrent quelques exemples de cela. Vous pouvez [démarrer une session de console Rails](operations/rails_console.md#starting-a-rails-console-session) et utiliser des scripts similaires aux suivants :

### Désactiver les utilisateurs n'ayant aucune activité récente {#deactivate-users-that-have-no-recent-activity}

Les administrateurs peuvent désactiver les utilisateurs n'ayant aucune activité récente.

> [!warning]
> Les commandes qui modifient des données peuvent causer des dommages si elles ne sont pas exécutées correctement ou dans les bonnes conditions. Exécutez toujours les commandes dans un environnement de test d'abord et ayez une instance de sauvegarde prête à restaurer.

```ruby
days_inactive = 90
inactive_users = User.active.where("last_activity_on <= ?", days_inactive.days.ago)

inactive_users.each do |user|
    puts "user '#{user.username}': #{user.last_activity_on}"
    user.deactivate!
end
```

### Bloquer les utilisateurs n'ayant aucune activité récente {#block-users-that-have-no-recent-activity}

Les administrateurs peuvent bloquer les utilisateurs n'ayant aucune activité récente.

> [!warning]
> Les commandes qui modifient des données peuvent causer des dommages si elles ne sont pas exécutées correctement ou dans les bonnes conditions. Exécutez toujours les commandes dans un environnement de test d'abord et ayez une instance de sauvegarde prête à restaurer.

```ruby
days_inactive = 90
inactive_users = User.active.where("last_activity_on <= ?", days_inactive.days.ago)

inactive_users.each do |user|
    puts "user '#{user.username}': #{user.last_activity_on}"
    user.block!
end
```

### Bloquer ou supprimer les utilisateurs n'ayant aucun projet ni groupe {#block-or-delete-users-that-have-no-projects-or-groups}

Les administrateurs peuvent bloquer ou supprimer les utilisateurs n'ayant aucun projet ni groupe.

> [!warning]
> Les commandes qui modifient des données peuvent causer des dommages si elles ne sont pas exécutées correctement ou dans les bonnes conditions. Exécutez toujours les commandes dans un environnement de test d'abord et ayez une instance de sauvegarde prête à restaurer.

```ruby
users = User.where('id NOT IN (select distinct(user_id) from project_authorizations)')

# How many users are removed?
users.count

# If that count looks sane:

# You can either block the users:
users.each { |user|  user.blocked? ? nil  : user.block! }

# Or you can delete them:
  # need 'current user' (your user) for auditing purposes
current_user = User.find_by(username: '<your username>')

users.each do |user|
  DeleteUserWorker.perform_async(current_user.id, user.id)
end
```
