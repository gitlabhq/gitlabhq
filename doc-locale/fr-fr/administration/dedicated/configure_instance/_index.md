---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurez votre instance GitLab Dedicated avec Switchboard.
title: Configurer GitLab Dedicated
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

Les instructions de cette page vous guident dans la configuration de votre instance GitLab Dedicated, notamment l'activation et la mise à jour des paramètres pour les [fonctionnalités disponibles](../../../subscriptions/gitlab_dedicated/_index.md#available-features).

Les administrateurs peuvent configurer des paramètres supplémentaires dans leur application GitLab en utilisant la [zone **Admin**](../../admin_area.md).

Cependant, étant donné que GitLab Dedicated est une solution gérée, vous ne pouvez pas modifier les fonctionnalités contrôlées par les paramètres au niveau de l'environnement. Ceux-ci incluent les configurations `gitlab.rb` et l'accès au shell, à la console Rails et à la console PostgreSQL.

Les ingénieurs GitLab Dedicated n'ont pas d'accès direct à votre environnement, sauf dans les [situations d'accès d'urgence](../../../subscriptions/gitlab_dedicated/_index.md#access-controls).

> [!note]
> Une instance fait référence à un déploiement GitLab Dedicated, tandis qu'un tenant fait référence à un client.

## Configurer votre instance avec Switchboard {#configure-your-instance-using-switchboard}

Vous pouvez utiliser Switchboard pour apporter des modifications de configuration limitées à votre instance GitLab Dedicated.

Les paramètres de configuration suivants sont disponibles dans Switchboard :

- [Liste d'autorisation IP](network_security.md#ip-allowlist)
- [Paramètres SAML](authentication/saml.md)
- [Autorités de certification personnalisées](network_security.md#custom-certificate-authorities-for-external-services)
- [Connexions PrivateLink sortantes](network_security.md#outbound-privatelink-connections)
- [Zones hébergées privées](network_security.md#private-hosted-zones)

Prérequis :

- Vous devez disposer du rôle [Admin](users_notifications.md#add-switchboard-users).

Pour apporter une modification de configuration :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. En haut de la page, sélectionnez **Configuration**.
1. Suivez les instructions dans les sections pertinentes ci-dessous.

Pour toutes les autres configurations d'instance, soumettez un ticket d'assistance conformément à la [politique de demande de modification de configuration](_index.md#request-configuration-changes-with-a-support-ticket).

### Appliquer les modifications de configuration dans Switchboard {#apply-configuration-changes-in-switchboard}

Vous pouvez appliquer immédiatement les modifications de configuration effectuées dans Switchboard ou les reporter jusqu'à votre prochaine [fenêtre de maintenance](../maintenance.md#maintenance-windows) hebdomadaire planifiée.

Lorsque vous appliquez les modifications immédiatement :

- Le déploiement peut prendre jusqu'à 90 minutes.
- Les modifications sont appliquées dans l'ordre dans lequel elles sont enregistrées.
- Vous pouvez enregistrer plusieurs modifications et les appliquer en un seul lot.
- Votre instance reste disponible pendant le déploiement.
- Les modifications apportées aux zones hébergées privées peuvent perturber les services dépendants pendant jusqu'à 5 minutes.

Une fois le déploiement terminé, tous les utilisateurs ayant accès à la consultation ou à la modification de votre tenant reçoivent une notification pour chaque modification. Pour activer ou désactiver les notifications, consultez [gérer les paramètres de notification](users_notifications.md#manage-notification-settings).

## Journal des modifications de configuration {#configuration-change-log}

La page **Configuration change log** dans Switchboard suit les modifications apportées à votre instance GitLab Dedicated.

Chaque entrée du journal des modifications inclut les détails suivants :

| Champ                | Description                                                                                                                                   |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| Modification de configuration | Nom du paramètre de configuration qui a été modifié.                                                                                               |
| Utilisateur                 | Adresse e-mail de l'utilisateur qui a effectué la modification de configuration. Pour les modifications effectuées par un opérateur GitLab, cette valeur apparaît comme `GitLab Operator`. |
| IP                   | Adresse IP de l'utilisateur qui a effectué la modification de configuration. Pour les modifications effectuées par un opérateur GitLab, cette valeur apparaît comme `Unavailable`.        |
| Statut               | Indique si la modification de configuration est initiée, en cours, terminée ou différée.                                                           |
| Heure de début           | Date et heure de début lorsque la modification de configuration est initiée, en UTC.                                                                       |
| Heure de fin             | Date et heure de fin lorsque la modification de configuration est déployée, en UTC.                                                                          |

Chaque modification de configuration possède un statut :

| Statut      | Description |
|-------------|-------------|
| Initiée   | La modification de configuration est effectuée dans Switchboard, mais n'est pas encore déployée sur l'instance. |
| En cours | La modification de configuration est activement déployée sur l'instance. |
| Terminée    | La modification de configuration a été déployée sur l'instance. |
| Différée     | Le job initial chargé de déployer une modification a échoué et la modification n'a pas encore été assignée à un nouveau job. |

### Afficher le journal des modifications de configuration {#view-the-configuration-change-log}

Pour afficher le journal des modifications de configuration :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. En haut de la page, sélectionnez **Configuration change log**.

Chaque modification de configuration apparaît comme une entrée dans le tableau. Sélectionnez **Afficher les détails** pour voir plus d'informations sur chaque modification.

## Demander des modifications de configuration avec un ticket d'assistance {#request-configuration-changes-with-a-support-ticket}

Certaines modifications de configuration nécessitent que vous soumettiez un ticket d'assistance pour demander les modifications. Pour plus d'informations sur la création d'un ticket d'assistance, consultez [créer un ticket](https://about.gitlab.com/support/portal/#creating-a-ticket).

Les modifications de configuration demandées via un [ticket d'assistance](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) respectent les politiques suivantes :

- Sont appliquées pendant la fenêtre de maintenance hebdomadaire de quatre heures de votre environnement.
- Peuvent être demandées pour les options spécifiées lors de l'intégration ou pour les fonctionnalités facultatives répertoriées sur cette page.
- Peuvent être reportées à la semaine suivante si GitLab doit effectuer des tâches de maintenance hautement prioritaires.
- Ne peuvent pas être appliquées en dehors de la fenêtre de maintenance hebdomadaire, sauf si elles sont éligibles au [support d'urgence](https://about.gitlab.com/support/#how-to-engage-emergency-support).

> [!note]
> Même si une demande de modification satisfait au délai minimum, elle pourrait ne pas être appliquée pendant la prochaine fenêtre de maintenance.
