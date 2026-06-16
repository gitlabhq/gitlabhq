---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Administration des événements d'audit"
description: "Affichez, exportez et gérez les événements d'audit pour l'instance GitLab, notamment l'encodage CSV et l'usurpation d'identité des utilisateurs."
---

En plus des [événements d'audit](../../user/compliance/audit_events.md), en tant qu'administrateur, vous pouvez accéder à des fonctionnalités supplémentaires.

## Événements d'audit d'instance {#instance-audit-events}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez afficher les événements d'audit résultant des actions des utilisateurs sur l'ensemble d'une instance GitLab. Pour afficher les événements d'audit d'instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Filtrez par les éléments suivants :
   - Membre du projet (utilisateur) qui a effectué l'action
   - Groupe
   - Projet
   - Plage de dates

Les événements d'audit d'instance sont également accessibles via l'[API des événements d'audit d'instance](../../api/audit_events.md#instance-audit-events).

## Exportation des événements d'audit {#exporting-audit-events}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Le type d'entité `Gitlab::Audit::InstanceScope` pour les événements d'audit d'instance a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/418185) dans GitLab 16.2.

{{< /history >}}

Vous pouvez exporter la vue actuelle (y compris les filtres) de vos événements d'audit d'instance sous forme de fichier CSV (valeurs séparées par des virgules). Pour exporter les événements d'audit d'instance au format CSV :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Sélectionnez les filtres de recherche disponibles.
1. Sélectionnez **Exporter au format CSV**.

Une boîte de dialogue de confirmation de téléchargement s'affiche alors pour vous permettre de télécharger le fichier CSV. Le CSV exporté est limité à un maximum de 100 000 événements. Les enregistrements restants sont tronqués lorsque cette limite est atteinte.

### Encodage CSV des événements d'audit {#audit-event-csv-encoding}

Le fichier CSV exporté est encodé comme suit :

- `,` est utilisé comme délimiteur de colonne
- `"` est utilisé pour mettre les champs entre guillemets si nécessaire.
- `\n` est utilisé pour séparer les lignes.

La première ligne contient les en-têtes, qui sont répertoriés dans le tableau suivant avec une description des valeurs :

| Colonne                | Description                                                                        |
| --------------------- | ---------------------------------------------------------------------------------- |
| **ID**                | Événement d'audit `id`.                                                                  |
| **ID d'auteur**         | ID de l'auteur.                                                                  |
| **Author Name**       | Nom complet de l'auteur.                                                           |
| **ID de l'entité**         | ID de la portée.                                                                   |
| **Entity Type**       | Type de la portée (`Project`, `Group`, `User`, ou `Gitlab::Audit::InstanceScope`). |
| **Entity Path**       | Chemin de la portée.                                                                 |
| **ID cible**         | ID de la cible.                                                                  |
| **Type cible**       | Type de la cible.                                                                |
| **Target Details**    | Détails de la cible.                                                             |
| **Action**            | Description de l'action.                                                         |
| **Adresse IP**        | Adresse IP de l'auteur qui a effectué l'action.                                 |
| **Created At (UTC)**  | Formaté comme suit : `YYYY-MM-DD HH:MM:SS`.                                                |

Tous les éléments sont triés par `created_at` par ordre croissant.

## Usurpation d'identité des utilisateurs {#user-impersonation}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Lorsqu'un utilisateur est [emprunté](../admin_area.md#user-impersonation), ses actions sont enregistrées en tant qu'événements d'audit avec les détails supplémentaires suivants :

- Les événements d'audit incluent des informations sur l'administrateur qui effectue l'usurpation d'identité.
- Des événements d'audit supplémentaires sont enregistrés pour le début et la fin de la session d'usurpation d'identité de l'administrateur.

![Un événement d'audit avec un utilisateur emprunté.](img/impersonated_audit_events_v15_7.png)

## Fuseaux horaires {#time-zones}

Pour plus d'informations sur les fuseaux horaires et les événements d'audit, voir [Fuseaux horaires](../../user/compliance/audit_events.md#time-zones).

## Contribuer aux événements d'audit {#contribute-to-audit-events}

Pour plus d'informations sur la contribution aux événements d'audit, voir [Contribuer aux événements d'audit](../../user/compliance/audit_events.md#contribute-to-audit-events).
