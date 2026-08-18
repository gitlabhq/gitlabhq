---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Flux d'événements d'audit pour les groupes principaux"
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Enregistrement des événements de sous-groupe](https://gitlab.com/gitlab-org/gitlab/-/issues/366878) corrigé dans GitLab 15.2.
- L'interface utilisateur des en-têtes HTTP personnalisés a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/361630) dans GitLab 15.2 [avec un flag](../../administration/feature_flags/list.md) nommé `custom_headers_streaming_audit_events_ui`. Désactivée par défaut.
- L'interface utilisateur des en-têtes HTTP personnalisés a été [rendue généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/365259) dans GitLab 15.3. [Le feature flag `custom_headers_streaming_audit_events_ui`](https://gitlab.com/gitlab-org/gitlab/-/issues/365259) a été supprimé.
- [Amélioration de l'expérience utilisateur](https://gitlab.com/gitlab-org/gitlab/-/issues/367963) dans GitLab 15.3.
- Le champ **Nom** de la destination HTTP a été [ajouté](https://gitlab.com/gitlab-org/gitlab/-/issues/411357) dans GitLab 16.3.
- La fonctionnalité de la case à cocher **Actif** a été [ajoutée](https://gitlab.com/gitlab-org/gitlab/-/issues/415268) dans GitLab 16.5.

{{< /history >}}

Grâce au flux d'événements d'audit pour les groupes principaux, les propriétaires de groupes peuvent :

- Définir une destination de flux pour un groupe principal afin de recevoir tous les événements d'audit concernant le groupe, les sous-groupes et les projets sous forme de JSON structuré.
- Gérer leurs journaux d'audit dans des systèmes tiers. Tout service capable de recevoir des données JSON structurées peut être utilisé comme destination de flux.

Chaque destination de flux :

- Peut inclure jusqu'à 20 en-têtes HTTP personnalisés avec chaque événement diffusé.
- Pour GitLab.com, doit autoriser le trafic provenant de la [plage d'adresses IP de GitLab.com](../gitlab_com/_index.md#ip-range).

GitLab peut diffuser un même événement plusieurs fois vers la même destination. Utilisez la clé `id` dans le payload pour dédupliquer les données entrantes.

Les événements d'audit sont envoyés via le protocole de méthode de requête POST pris en charge par HTTP.

> [!warning]
> Les destinations de flux reçoivent toutes les données des événements d'audit, qui peuvent inclure des informations sensibles. Assurez-vous de faire confiance à la destination de flux.

## Destinations HTTP {#http-destinations}

Prérequis :

- Pour une meilleure sécurité, il est recommandé d'utiliser un certificat SSL sur l'URL de destination.

Gérez les destinations de flux HTTP pour les groupes principaux.

### Ajouter une nouvelle destination HTTP {#add-a-new-http-destination}

Ajoutez une nouvelle destination de flux HTTP à un groupe principal.

Prérequis :

- Rôle Propriétaire pour un groupe principal.

Pour ajouter des destinations de flux à un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez **Ajouter une destination de flux** et sélectionnez **Point de terminaison HTTP** pour afficher la section d'ajout de destinations.
1. Dans les champs **Nom** et **URL de destination**, ajoutez un nom et une URL de destination.
1. facultatif. Localisez le tableau **Custom HTTP headers**.
1. Pour activer l'en-tête, cochez la case **Actif**. L'en-tête sera envoyé avec l'événement d'audit.
1. Sélectionnez **Ajouter un en-tête** pour créer une nouvelle paire nom/valeur. Saisissez autant de paires nom/valeur que nécessaire. Vous pouvez ajouter jusqu'à 20 en-têtes par destination de flux.
1. Une fois tous les en-têtes renseignés, sélectionnez **Ajouter** pour ajouter la nouvelle destination de flux.

### Mettre à jour une destination HTTP {#update-an-http-destination}

Prérequis :

- Rôle Propriétaire pour un groupe.

Pour mettre à jour le nom d'une destination de flux :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Dans les champs **Nom**, ajoutez un nom de destination à mettre à jour.
1. Sélectionnez **Enregistrer** pour mettre à jour la destination de flux.

Pour mettre à jour les en-têtes HTTP personnalisés d'une destination de flux :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Localisez le tableau **Custom HTTP headers**.
1. Localisez l'en-tête que vous souhaitez mettre à jour.
1. Pour activer l'en-tête, cochez la case **Actif**. L'en-tête sera envoyé avec l'événement d'audit.
1. Sélectionnez **Ajouter un en-tête** pour créer une nouvelle paire nom/valeur. Saisissez autant de paires nom/valeur que nécessaire. Vous pouvez ajouter jusqu'à 20 en-têtes par destination de flux.
1. Sélectionnez **Enregistrer** pour mettre à jour la destination de flux.

### Vérifier l'authenticité des événements {#verify-event-authenticity}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/360814) dans GitLab 15.2.

{{< /history >}}

Chaque destination de flux dispose d'un jeton de vérification unique (`verificationToken`) qui peut être utilisé pour vérifier l'authenticité de l'événement. Ce jeton est soit spécifié par le Propriétaire, soit généré automatiquement lors de la création de la destination d'événement et ne peut pas être modifié.

Le paramètre `verificationToken` ne peut être défini qu'en utilisant l'[API GraphQL](../../api/graphql/audit_event_streaming_groups.md#add-a-new-streaming-destination).

Chaque événement diffusé contient le jeton de vérification dans l'en-tête HTTP `X-Gitlab-Event-Streaming-Token`, qui peut être vérifié par rapport à la valeur de la destination lors de l'affichage des destinations de flux.

Prérequis :

- Rôle Propriétaire pour un groupe.

Pour répertorier les destinations de flux et consulter les jetons de vérification :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Localisez le champ **Jeton de vérification**.

### Mettre à jour les filtres d'événements {#update-event-filters}

{{< history >}}

- Le filtrage par type d'événement dans l'interface utilisateur avec une liste définie de types d'événements d'audit a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/413581) dans GitLab 16.1.

{{< /history >}}

Lorsque cette fonctionnalité est activée pour un groupe, vous pouvez autoriser les utilisateurs à filtrer les événements d'audit diffusés par destination. Si la fonctionnalité est activée sans filtre, la destination reçoit tous les événements d'audit.

Une destination de flux dont un filtre par type d'événement est défini porte le label **filtré** ({{< icon name="filter" >}}).

Pour mettre à jour les filtres d'événements d'une destination de flux :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Localisez la liste déroulante **Filtrer par type d'événement d'audit**.
1. Sélectionnez la liste déroulante, puis sélectionnez ou désélectionnez les types d'événements requis.
1. Sélectionnez **Enregistrer** pour mettre à jour les filtres d'événements.

### Mettre à jour les filtres d'espace de nommage {#update-namespace-filters}

{{< history >}}

- Le filtrage par espace de nommage dans l'interface utilisateur a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/390133) dans GitLab 16.7.

{{< /history >}}

Lorsque cette fonctionnalité est activée pour un groupe, vous pouvez autoriser les utilisateurs à filtrer les événements d'audit diffusés par destination. Si la fonctionnalité est activée sans filtre, la destination reçoit tous les événements d'audit.

Une destination de flux dont un filtre d'espace de nommage est défini porte le label **filtré** ({{< icon name="filter" >}}).

Pour mettre à jour les filtres d'espace de nommage d'une destination de flux :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Localisez la liste déroulante **Filtrer par groupes ou par projets**.
1. Sélectionnez la liste déroulante, puis sélectionnez ou désélectionnez les espaces de nommage requis.
1. Sélectionnez **Enregistrer** pour mettre à jour le filtre d'espace de nommage.

### Remplacer l'en-tête de type de contenu par défaut {#override-default-content-type-header}

Par défaut, les destinations de flux utilisent un en-tête `content-type` avec la valeur `application/x-www-form-urlencoded`. Cependant, vous pouvez souhaiter définir l'en-tête `content-type` sur une autre valeur. Par exemple, `application/json`.

Pour remplacer la valeur par défaut de l'en-tête `content-type` pour une destination de flux d'un groupe principal, utilisez l'une des options suivantes :

- L'[interface utilisateur GitLab](#update-an-http-destination).
- L'[API GraphQL](../../api/graphql/audit_event_streaming_groups.md#update-streaming-destinations).

## Destinations Google Cloud Logging {#google-cloud-logging-destinations}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124384) dans GitLab 16.2.

{{< /history >}}

Gérez les destinations Google Cloud Logging pour les groupes principaux.

### Prérequis {#prerequisites}

Avant de configurer le flux d'événements d'audit Google Cloud Logging, vous devez :

1. Activer l'[API Cloud Logging](https://console.cloud.google.com/marketplace/product/google/logging.googleapis.com) sur votre projet Google Cloud.
1. Créer un compte de service pour Google Cloud avec les identifiants et les autorisations appropriés. Ce compte est utilisé pour configurer l'authentification du flux de journaux d'audit. Pour plus d'informations, consultez la [documentation Google Cloud sur la création et la gestion des comptes de service](https://cloud.google.com/iam/docs/service-accounts-create#creating).
1. Activez le rôle **Logs Writer** pour le compte de service afin d'activer la journalisation sur Google Cloud. Pour plus d'informations, consultez [Contrôle d'accès avec IAM](https://cloud.google.com/logging/docs/access-control#logging.logWriter).
1. Créez une clé JSON pour le compte de service. Pour plus d'informations, consultez [Création d'une clé de compte de service](https://cloud.google.com/iam/docs/keys-create-delete#creating).

### Ajouter une nouvelle destination Google Cloud Logging {#add-a-new-google-cloud-logging-destination}

Prérequis :

- Rôle Propriétaire pour un groupe principal.

Pour ajouter des destinations de flux Google Cloud Logging à un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez **Ajouter une destination de flux** et sélectionnez **Google Cloud Logging** pour afficher la section d'ajout de destinations.
1. Saisissez une chaîne aléatoire à utiliser comme nom pour la nouvelle destination.
1. Saisissez l'ID de projet Google, l'e-mail client Google et la clé privée Google issus de la clé de compte de service Google Cloud créée précédemment pour les ajouter à la nouvelle destination.
1. Saisissez une chaîne aléatoire à utiliser comme ID de journal pour la nouvelle destination. Vous pourrez l'utiliser ultérieurement pour filtrer les résultats des journaux dans Google Cloud.
1. Sélectionnez **Ajouter** pour ajouter la nouvelle destination de flux.

### Mettre à jour une destination Google Cloud Logging {#update-a-google-cloud-logging-destination}

{{< history >}}

- Le bouton pour ajouter une clé privée a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/419675) dans GitLab 16.3.

{{< /history >}}

Prérequis :

- Rôle Propriétaire pour un groupe principal.

Pour mettre à jour les destinations de flux Google Cloud Logging d'un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux Google Cloud Logging pour le développer.
1. Saisissez une chaîne aléatoire à utiliser comme nom pour la destination.
1. Saisissez l'ID de projet Google et l'e-mail client Google issus de la clé de compte de service Google Cloud créée précédemment pour mettre à jour la destination.
1. Saisissez une chaîne aléatoire pour mettre à jour l'ID de journal de la destination. Vous pourrez l'utiliser ultérieurement pour filtrer les résultats des journaux dans Google Cloud.
1. Sélectionnez **Ajouter une nouvelle clé privée** et saisissez une clé privée Google pour mettre à jour la clé privée.
1. Sélectionnez **Enregistrer** pour mettre à jour la destination de flux.

## Destinations AWS S3 {#aws-s3-destinations}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132603) dans GitLab 16.6 [avec un flag](../../administration/feature_flags/list.md) nommé `allow_streaming_audit_events_to_amazon_s3`. Activés par défaut.
- [Le feature flag `allow_streaming_audit_events_to_amazon_s3`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137391) a été supprimé dans GitLab 16.7.

{{< /history >}}

Gérez les destinations AWS S3 pour les groupes principaux.

### Prérequis {#prerequisites-1}

Avant de configurer le flux d'événements d'audit AWS S3, vous devez :

1. Créer une clé d'accès pour AWS avec les identifiants et les autorisations appropriés. Ce compte est utilisé pour configurer l'authentification du flux de journaux d'audit. Pour plus d'informations, consultez [Gestion des clés d'accès](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html?icmpid=docs_iam_console#Using_CreateAccessKey).
1. Créer un compartiment AWS S3. Ce compartiment est utilisé pour stocker les données du flux de journaux d'audit. Pour plus d'informations, consultez [Création d'un compartiment](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html)

### Ajouter une nouvelle destination AWS S3 {#add-a-new-aws-s3-destination}

Prérequis :

- Rôle Propriétaire pour un groupe principal.

Pour ajouter des destinations de flux AWS S3 à un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez **Ajouter une destination de flux** et sélectionnez **AWS S3** pour afficher la section d'ajout de destinations.
1. Saisissez une chaîne aléatoire à utiliser comme nom pour la nouvelle destination.
1. Saisissez l'**ID de la clé d'accès**, la **Clé d'accès secrète**, le **Nom du compartiment** et la **Région AWS** issus de la clé d'accès et du compartiment AWS créés précédemment pour les ajouter à la nouvelle destination.
1. Sélectionnez **Ajouter** pour ajouter la nouvelle destination de flux.

### Mettre à jour une destination AWS S3 {#update-an-aws-s3-destination}

Prérequis :

- Rôle Propriétaire pour un groupe principal.

Pour mettre à jour une destination de flux AWS S3 pour un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux AWS S3 pour le développer.
1. Saisissez une chaîne aléatoire à utiliser comme nom pour la destination.
1. Pour mettre à jour la destination, saisissez l'**ID de la clé d'accès**, la **Clé d'accès secrète**, le **Nom du compartiment** et la **Région AWS** issus de la clé d'accès et du compartiment AWS créés précédemment.
1. Pour mettre à jour la clé d'accès secrète, sélectionnez **Add a new Secret Access Key** et saisissez une clé d'accès secrète AWS.
1. Sélectionnez **Enregistrer**.

## Répertorier les destinations de flux {#list-streaming-destinations}

Prérequis :

- Rôle Propriétaire pour un groupe principal.

Pour répertorier les destinations de flux d'un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.

## Activer ou désactiver les destinations de flux {#activate-or-deactivate-streaming-destinations}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/537096) dans GitLab 18.2.

{{< /history >}}

Vous pouvez temporairement désactiver le flux d'événements d'audit vers une destination sans supprimer la configuration de la destination. Lorsqu'une destination de flux est désactivée :

- Les événements d'audit cessent immédiatement d'être diffusés vers cette destination.
- La configuration de la destination est conservée.
- Vous pouvez réactiver la destination à tout moment.
- Les autres destinations actives continuent de recevoir des événements.

### Désactiver une destination de flux {#deactivate-a-streaming-destination}

Prérequis :

- Rôle Propriétaire pour un groupe principal.

Pour désactiver une destination de flux :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Décochez la case **Actif**.
1. Sélectionnez **Enregistrer**.

La destination cesse de recevoir des événements d'audit.

### Activer une destination de flux {#activate-a-streaming-destination}

Pour réactiver une destination de flux précédemment désactivée :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Cochez la case **Actif**.
1. Sélectionnez **Enregistrer**.

La destination reprend immédiatement la réception des événements d'audit.

## Supprimer des destinations de flux {#delete-streaming-destinations}

Supprimez les destinations de flux pour un groupe principal. Lorsque la dernière destination est supprimée avec succès, le flux est désactivé pour le groupe principal.

Prérequis :

- Rôle Propriétaire pour un groupe principal.

Pour supprimer des destinations de flux pour un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Sélectionnez **Supprimer la destination**.
1. Pour confirmer, sélectionnez **Supprimer la destination**.

### Supprimer uniquement les en-têtes HTTP personnalisés {#delete-only-custom-http-headers}

Prérequis :

- Rôle Propriétaire pour un groupe principal.

Pour supprimer uniquement les en-têtes HTTP personnalisés d'une destination de flux :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Localisez le tableau **Custom HTTP headers**.
1. Localisez l'en-tête que vous souhaitez supprimer.
1. À droite de l'en-tête, sélectionnez **Supprimer** ({{< icon name="remove" >}}).
1. Sélectionnez **Enregistrer**.

## Sujets connexes {#related-topics}

- [Flux d'événements d'audit pour les instances](../../administration/compliance/audit_event_streaming.md)
