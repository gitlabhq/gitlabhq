---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation de la licence
description: "Affichez et exportez l'utilisation associée à votre licence GitLab."
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez afficher l'utilisation associée à votre licence GitLab et exporter le fichier d'utilisation de licence avec les informations suivantes :

- Clé de licence
- E-mail du titulaire de la licence
- Date de début de la licence (UTC)
- Date de fin de la licence (UTC)
- Société
- Horodatage de la génération et de l'exportation du fichier (UTC)
- Tableau du nombre d'utilisateurs historique pour chaque jour de la période :
  - Horodatage de l'enregistrement du comptage (UTC)
  - Nombre d'utilisateurs facturables

> [!note]
> Un format personnalisé est utilisé pour les [dates](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L7) et les [heures](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L13) dans les fichiers CSV.

## Exporter l'utilisation de la licence {#export-license-usage}

Prérequis :

- Vous devez être administrateur.

Vous pouvez exporter l'utilisation de votre licence dans un fichier CSV.

Ce fichier contient les informations que GitLab utilise pour traiter manuellement les [rapprochements trimestriels](../subscriptions/quarterly_reconciliation.md) et les [renouvellements](../subscriptions/manage_subscription.md#renew-subscription). Si votre instance est protégée par un pare-feu ou dans un environnement hors ligne, vous devez fournir ces informations à GitLab.

> [!warning]
> N'ouvrez pas le fichier d'utilisation de la licence. Si vous ouvrez le fichier, des échecs peuvent survenir lors de [l'envoi de vos données d'utilisation de licence](license_file.md#submit-license-usage-data).

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Abonnement**.
1. Dans le coin supérieur droit, sélectionnez **Exporter le fichier d'utilisation de licence**.
