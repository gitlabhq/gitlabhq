---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Diffusion d'événements d'audit pour les instances"
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/398107) dans GitLab 16.1 [avec un feature flag](../feature_flags/_index.md) nommé `ff_external_audit_events`. Désactivé par défaut.
- [Feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) activé par défaut dans GitLab 16.2.
- Les destinations de diffusion d'instance [sont généralement disponibles](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) dans GitLab 16.4. [Feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/417708) supprimé.
- L'interface utilisateur des en-têtes HTTP personnalisés a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/361630) dans GitLab 15.2 [avec un feature flag](../feature_flags/_index.md) nommé `custom_headers_streaming_audit_events_ui`. Désactivé par défaut.
- L'interface utilisateur des en-têtes HTTP personnalisés [est généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/365259) dans GitLab 15.3. [Feature flag `custom_headers_streaming_audit_events_ui`](https://gitlab.com/gitlab-org/gitlab/-/issues/365259) supprimé.
- [Amélioration de l'expérience utilisateur](https://gitlab.com/gitlab-org/gitlab/-/issues/367963) dans GitLab 15.3.
- Le champ **Nom** de la destination HTTP [a été ajouté](https://gitlab.com/gitlab-org/gitlab/-/issues/411357) dans GitLab 16.3.
- La fonctionnalité de la case à cocher **Actif** [a été ajoutée](https://gitlab.com/gitlab-org/gitlab/-/issues/415268) dans GitLab 16.5.

{{< /history >}}

Pour la diffusion d'événements d'audit pour les instances, les administrateurs peuvent :

- Définir une destination de diffusion pour une instance entière afin de recevoir tous les événements d'audit concernant cette instance sous forme de JSON structuré.
- Gérer leurs journaux d'audit dans des systèmes tiers. Tout service pouvant recevoir des données JSON structurées peut être utilisé comme destination de diffusion.

Chaque destination de diffusion peut inclure jusqu'à 20 en-têtes HTTP personnalisés avec chaque événement diffusé.

GitLab peut diffuser un même événement plusieurs fois vers la même destination. Utilisez la clé `id` dans la charge utile pour dédupliquer les données entrantes.

Les événements d'audit sont envoyés à l'aide du protocole de méthode de requête POST pris en charge par HTTP.

> [!warning]
> Les destinations de diffusion reçoivent **l'ensemble** des données d'événements d'audit, ce qui peut inclure des informations sensibles. Assurez-vous que vous faites confiance à la destination de diffusion.

Gérez les destinations de diffusion pour une instance entière.

## Destinations HTTP {#http-destinations}

Prérequis :

- Pour une meilleure sécurité, vous devriez utiliser un certificat SSL sur l'URL de destination.

Gérez les destinations de diffusion HTTP pour une instance entière.

### Ajouter une nouvelle destination HTTP {#add-a-new-http-destination}

Ajoutez une nouvelle destination de diffusion HTTP à une instance.

Prérequis :

- Accès administrateur sur l'instance.

Pour ajouter une destination de diffusion pour une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez **Ajouter une destination de flux** et sélectionnez **Point de terminaison HTTP** pour afficher la section d'ajout de destinations.
1. Dans les champs **Nom** et **URL de destination**, ajoutez un nom et une URL de destination.
1. Facultatif. Pour ajouter des en-têtes HTTP personnalisés, sélectionnez **Ajouter un en-tête** pour créer une nouvelle paire nom/valeur, et saisissez leurs valeurs. Répétez cette étape pour autant de paires nom/valeur que nécessaire. Vous pouvez ajouter jusqu'à 20 en-têtes par destination de diffusion.
1. Pour rendre l'en-tête actif, cochez la case **Actif**. L'en-tête sera envoyé avec l'événement d'audit.
1. Sélectionnez **Ajouter un en-tête** pour créer une nouvelle paire nom/valeur. Répétez cette étape pour autant de paires nom/valeur que nécessaire. Vous pouvez ajouter jusqu'à 20 en-têtes par destination de diffusion.
1. Une fois tous les en-têtes remplis, sélectionnez **Ajouter** pour ajouter la nouvelle destination de diffusion.

### Mettre à jour une destination HTTP {#update-an-http-destination}

Prérequis :

- Accès administrateur sur l'instance.

Pour mettre à jour le nom d'une destination de diffusion d'instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Dans le champ **Nom**, ajoutez un nom de destination à mettre à jour.
1. Sélectionnez **Enregistrer** pour mettre à jour la destination de diffusion.

Pour mettre à jour les en-têtes HTTP personnalisés d'une destination de diffusion d'instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Repérez le tableau **Custom HTTP headers**.
1. Repérez l'en-tête que vous souhaitez mettre à jour.
1. Pour rendre l'en-tête actif, cochez la case **Actif**. L'en-tête sera envoyé avec l'événement d'audit.
1. Sélectionnez **Ajouter un en-tête** pour créer une nouvelle paire nom/valeur. Saisissez autant de paires nom/valeur que nécessaire. Vous pouvez ajouter jusqu'à 20 en-têtes par destination de diffusion.
1. Sélectionnez **Enregistrer** pour mettre à jour la destination de diffusion.

### Vérifier l'authenticité des événements {#verify-event-authenticity}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/398107) dans GitLab 16.1 [avec un feature flag](../feature_flags/_index.md) nommé `ff_external_audit_events`. Désactivé par défaut.
- [Feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) activé par défaut dans GitLab 16.2.
- Les destinations de diffusion d'instance [sont généralement disponibles](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) dans GitLab 16.4. [Feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/417708) supprimé.

{{< /history >}}

Chaque destination de diffusion possède un jeton de vérification unique (`verificationToken`) pouvant être utilisé pour vérifier l'authenticité de l'événement. Ce jeton est soit spécifié par le propriétaire, soit généré automatiquement lors de la création de la destination de l'événement, et ne peut pas être modifié.

Chaque événement diffusé contient le jeton de vérification dans l'en-tête HTTP `X-Gitlab-Event-Streaming-Token`, qui peut être vérifié par rapport à la valeur de la destination lors de la liste des destinations de diffusion.

Prérequis :

- Accès administrateur sur l'instance.

Pour lister les destinations de diffusion d'une instance et afficher les jetons de vérification :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Affichez le jeton de vérification sur le côté droit de chaque élément.

### Mettre à jour les filtres d'événements {#update-event-filters}

{{< history >}}

- Le filtrage par type d'événement dans l'interface utilisateur avec une liste définie de types d'événements d'audit a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/415013) dans GitLab 16.3.

{{< /history >}}

Lorsque cette fonctionnalité est activée, vous pouvez permettre aux utilisateurs de filtrer les événements d'audit diffusés par destination. Si la fonctionnalité est activée sans filtres, la destination reçoit tous les événements d'audit.

Une destination de diffusion disposant d'un filtre de type d'événement porte le label **filtré** ({{< icon name="filter" >}}).

Pour mettre à jour les filtres d'événements d'une destination de diffusion :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Repérez la liste déroulante **Filtrer par type d'événement d'audit**.
1. Sélectionnez la liste déroulante et sélectionnez ou désélectionnez les types d'événements requis.
1. Sélectionnez **Enregistrer** pour mettre à jour les filtres d'événements.

### Remplacer l'en-tête de type de contenu par défaut {#override-default-content-type-header}

Par défaut, les destinations de diffusion utilisent un en-tête `content-type` avec la valeur `application/x-www-form-urlencoded`. Cependant, vous pourriez vouloir définir l'en-tête `content-type` sur une autre valeur. Par exemple, `application/json`.

Pour remplacer la valeur par défaut de l'en-tête `content-type` pour une destination de diffusion d'instance, utilisez l'une des méthodes suivantes :

- L'[interface utilisateur GitLab](#update-an-http-destination).
- L'[API GraphQL](../../api/graphql/audit_event_streaming_instances.md#update-streaming-destinations).

## Destinations Google Cloud Logging {#google-cloud-logging-destinations}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131851) dans GitLab 16.5.

{{< /history >}}

Gérez les destinations Google Cloud Logging pour une instance entière.

### Prérequis {#prerequisites}

Avant de configurer la diffusion des événements d'audit Google Cloud Logging, vous devez :

1. Activer [Cloud Logging API](https://console.cloud.google.com/marketplace/product/google/logging.googleapis.com) sur votre projet Google Cloud.
1. Créer un compte de service pour Google Cloud avec les informations d'identification et les autorisations appropriées. Ce compte est utilisé pour configurer l'authentification de la diffusion des journaux d'audit. Pour plus d'informations, consultez [Créer et gérer des comptes de service dans la documentation Google Cloud](https://cloud.google.com/iam/docs/service-accounts-create#creating).
1. Activez le rôle **Logs Writer** pour le compte de service afin d'activer la journalisation sur Google Cloud. Pour plus d'informations, consultez [Contrôle d'accès avec IAM](https://cloud.google.com/logging/docs/access-control#logging.logWriter).
1. Créez une clé JSON pour le compte de service. Pour plus d'informations, consultez [Création d'une clé de compte de service](https://cloud.google.com/iam/docs/keys-create-delete#creating).

### Ajouter une nouvelle destination Google Cloud Logging {#add-a-new-google-cloud-logging-destination}

Prérequis :

- Accès administrateur sur l'instance.

Pour ajouter des destinations de diffusion Google Cloud Logging à une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez **Ajouter une destination de flux** et sélectionnez **Google Cloud Logging** pour afficher la section d'ajout de destinations.
1. Saisissez une chaîne aléatoire à utiliser comme nom pour la nouvelle destination.
1. Saisissez l'ID de projet Google et l'adresse e-mail du client Google à partir de la clé de compte de service Google Cloud précédemment créée.
1. Saisissez la clé privée Google à partir de la clé de compte de service Google Cloud précédemment créée. Elle doit être au format PEM et commencer par `-----BEGIN PRIVATE KEY-----`. Ne chargez pas l'intégralité de la clé JSON.
1. Saisissez une chaîne aléatoire à utiliser comme ID de journal pour la nouvelle destination. Vous pourrez l'utiliser ultérieurement pour filtrer les résultats des journaux dans Google Cloud.
1. Sélectionnez **Ajouter** pour ajouter la nouvelle destination de diffusion.

### Mettre à jour une destination Google Cloud Logging {#update-a-google-cloud-logging-destination}

Prérequis :

- Accès administrateur sur l'instance.

Pour mettre à jour les destinations de diffusion Google Cloud Logging vers une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux Google Cloud Logging pour le développer.
1. Saisissez une chaîne aléatoire à utiliser comme nom pour la destination.
1. Saisissez l'ID de projet Google et l'adresse e-mail du client Google à partir de la clé de compte de service Google Cloud précédemment créée pour mettre à jour la destination.
1. Saisissez une chaîne aléatoire pour mettre à jour l'ID de journal de la destination. Vous pourrez l'utiliser ultérieurement pour filtrer les résultats des journaux dans Google Cloud.
1. Sélectionnez **Ajouter une nouvelle clé privée** et saisissez une clé privée Google pour mettre à jour la clé privée.
1. Sélectionnez **Enregistrer** pour mettre à jour la destination de diffusion.

## Destinations AWS S3 {#aws-s3-destinations}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138245) dans GitLab 16.7 [avec un feature flag](../feature_flags/_index.md) nommé `allow_streaming_instance_audit_events_to_amazon_s3`. Désactivé par défaut.
- [Feature flag `allow_streaming_instance_audit_events_to_amazon_s3`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137391) supprimé dans GitLab 16.8.

{{< /history >}}

Gérez les destinations AWS S3 pour l'instance entière.

### Prérequis {#prerequisites-1}

Avant de configurer la diffusion des événements d'audit AWS S3, vous devez :

1. Créer une clé d'accès pour AWS avec les informations d'identification et les autorisations appropriées. Ce compte est utilisé pour configurer l'authentification de la diffusion des journaux d'audit. Pour plus d'informations, consultez [Gestion des clés d'accès](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html?icmpid=docs_iam_console#Using_CreateAccessKey).
1. Créer un compartiment AWS S3. Ce compartiment est utilisé pour stocker les données de diffusion des journaux d'audit. Pour plus d'informations, consultez [Création d'un compartiment](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html)

### Ajouter une nouvelle destination AWS S3 {#add-a-new-aws-s3-destination}

Prérequis :

- Accès administrateur sur l'instance.

Pour ajouter des destinations de diffusion AWS S3 à une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez **Ajouter une destination de flux** et sélectionnez **AWS S3** pour afficher la section d'ajout de destinations.
1. Saisissez une chaîne aléatoire à utiliser comme nom pour la nouvelle destination.
1. Saisissez l'**ID de la clé d'accès**, la **Clé d'accès secrète**, le **Nom du compartiment** et la **Région AWS** à partir de la clé d'accès et du compartiment AWS précédemment créés pour les ajouter à la nouvelle destination.
1. Sélectionnez **Ajouter** pour ajouter la nouvelle destination de diffusion.

### Mettre à jour une destination AWS S3 {#update-an-aws-s3-destination}

Prérequis :

- Accès administrateur sur l'instance.

Pour mettre à jour une destination de diffusion AWS S3 vers une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux AWS S3 pour le développer.
1. Saisissez une chaîne aléatoire à utiliser comme nom pour la destination.
1. Pour mettre à jour la destination, saisissez l'**ID de la clé d'accès**, la **Clé d'accès secrète**, le **Nom du compartiment** et la **Région AWS** à partir de la clé d'accès et du compartiment AWS précédemment créés.
1. Sélectionnez **Add a new Secret Access Key** et saisissez une clé d'accès secrète AWS pour mettre à jour la clé d'accès secrète.
1. Sélectionnez **Enregistrer**.

## Lister les destinations de diffusion {#list-streaming-destinations}

Prérequis :

- Accès administrateur sur l'instance.

Pour lister les destinations de diffusion d'une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.

## Activer ou désactiver les destinations de diffusion {#activate-or-deactivate-streaming-destinations}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/537096) dans GitLab 18.2.

{{< /history >}}

Vous pouvez temporairement désactiver la diffusion des événements d'audit vers une destination sans supprimer la configuration de la destination. Lorsqu'une destination de diffusion est désactivée :

- Les événements d'audit cessent immédiatement d'être diffusés vers cette destination.
- La configuration de la destination est conservée.
- Vous pouvez réactiver la destination à tout moment.
- Les autres destinations actives continuent de recevoir les événements.

### Désactiver une destination de diffusion {#deactivate-a-streaming-destination}

Prérequis :

- Accès administrateur sur l'instance.

Pour désactiver une destination de diffusion :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Décochez la case **Actif**.
1. Sélectionnez **Enregistrer**.

La destination cesse de recevoir des événements d'audit.

### Activer une destination de diffusion {#activate-a-streaming-destination}

Pour réactiver une destination de diffusion précédemment désactivée :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Cochez la case **Actif**.
1. Sélectionnez **Enregistrer**.

La destination reprend immédiatement la réception des événements d'audit.

## Supprimer les destinations de diffusion {#delete-streaming-destinations}

Supprimez les destinations de diffusion pour une instance entière. Lorsque la dernière destination est supprimée avec succès, la diffusion est désactivée pour l'instance.

Prérequis :

- Accès administrateur sur l'instance.

Pour supprimer des destinations de diffusion sur une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. Sélectionnez le flux pour le développer.
1. Sélectionnez **Supprimer la destination**.
1. Pour confirmer, sélectionnez **Supprimer la destination**.

### Supprimer uniquement les en-têtes HTTP personnalisés {#delete-only-custom-http-headers}

Prérequis :

- Accès administrateur sur l'instance.

Pour supprimer uniquement les en-têtes HTTP personnalisés d'une destination de diffusion :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Événements d'audit**.
1. Dans la zone principale, sélectionnez l'onglet **Flux**.
1. À droite de l'élément, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Repérez le tableau **Custom HTTP headers**.
1. Repérez l'en-tête que vous souhaitez supprimer.
1. À droite de l'en-tête, sélectionnez **Supprimer** ({{< icon name="remove" >}}).
1. Sélectionnez **Enregistrer**.

## Sujets connexes {#related-topics}

- [Diffusion d'événements d'audit pour les groupes principaux](../../user/compliance/audit_event_streaming.md)
