---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: "Paramètres d'importation et d'exportation"
description: "Configurez les paramètres des sources d'importation, des limites d'exportation, des tailles de fichiers, du mappage des utilisateurs et des utilisateurs fictifs sur votre instance GitLab Self-Managed."
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Paramètres des fonctionnalités liées à l'importation et à l'exportation.

## Configurer les sources d'importation autorisées {#configure-allowed-import-sources}

Avant de pouvoir importer des projets depuis d'autres systèmes, vous devez activer la [source d'importation](../../user/gitlab_com/_index.md#default-import-sources) pour ce système.

1. Connectez-vous à GitLab en tant qu'utilisateur avec le niveau d'accès Administrateur.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Paramètres d'importation et d'exportation**.
1. Sélectionnez chacune des **Sources d'importation** à autoriser.
1. Sélectionnez **Sauvegarder les modifications**.

## Désactiver les sources d'importation inutilisées {#disable-unused-import-sources}

N'importez des projets qu'à partir de sources de confiance. Si vous importez un projet depuis une source non fiable, un attaquant pourrait dérober vos données sensibles. Par exemple, un projet importé contenant un fichier `.gitlab-ci.yml` malveillant pourrait permettre à un attaquant d'exfiltrer les variables CI/CD de groupe.

Les administrateurs de GitLab Self-Managed peuvent réduire leur surface d'attaque en désactivant les sources d'importation dont ils n'ont pas besoin :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Paramètres d'importation et d'exportation**.
1. Faites défiler jusqu'à **Sources d'importation**.
1. Décochez les cases des importateurs qui ne sont pas requis.

## Activer l'exportation de projet {#enable-project-export}

Pour activer l'exportation des [projets et de leurs données](../../user/project/settings/import_export.md#export-a-project-and-its-data) :

1. Connectez-vous à GitLab en tant qu'utilisateur avec le niveau d'accès Administrateur.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Paramètres d'importation et d'exportation**.
1. Faites défiler jusqu'à **Exportation de projet**.
1. Cochez la case **Activé**.
1. Sélectionnez **Sauvegarder les modifications**.

## Activer la migration des groupes et des projets par transfert direct {#enable-migration-of-groups-and-projects-by-direct-transfer}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/383268) dans GitLab 15.8.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/461326) dans GitLab 18.3.

{{< /history >}}

> [!warning]
> Dans GitLab 16.1 et les versions antérieures, vous ne devez pas utiliser le transfert direct avec les [politiques d'exécution d'analyse planifiées](../../user/application_security/policies/scan_execution_policies.md). Si vous utilisez le transfert direct, effectuez d'abord une mise à niveau vers GitLab 16.2 et assurez-vous que les bots de politique de sécurité sont activés dans les projets que vous appliquez.

La migration des groupes et des projets par transfert direct est désactivée par défaut. Pour activer la migration des groupes et des projets par transfert direct :

1. Connectez-vous à GitLab en tant qu'utilisateur avec le niveau d'accès Administrateur.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Paramètres d'importation et d'exportation**.
1. Faites défiler jusqu'à **Autoriser la migration des groupes et des projets GitLab par transfert direct**.
1. Cochez la case **Activé**.
1. Sélectionnez **Sauvegarder les modifications**.

Le même paramètre [est disponible](../../api/settings.md#available-settings) dans l'API en tant qu'attribut `bulk_import_enabled`.

## Activer les exportations silencieuses par les administrateurs {#enable-silent-admin-exports}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151278) dans GitLab 17.0 [avec un indicateur](../feature_flags/_index.md) nommé `export_audit_events`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153351) dans GitLab 17.1. Indicateur de feature flag `export_audit_events` supprimé.
- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152143) pour les téléchargements d'exportations de fichiers dans GitLab 17.1.

{{< /history >}}

Activez les exportations silencieuses par les administrateurs pour empêcher la génération d'[événements d'audit](../compliance/audit_event_reports.md) lorsque les administrateurs de l'instance déclenchent une [exportation de fichier de projet ou de groupe](../../user/project/settings/import_export.md) ou téléchargent le fichier d'exportation. Les exportations effectuées par des non-administrateurs génèrent toujours des événements d'audit.

Pour activer les exportations silencieuses de fichiers de projet et de groupe par les administrateurs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**, puis développez **Paramètres d'importation et d'exportation**.
1. Faites défiler jusqu'à **Silent exports by admins**.
1. Cochez la case **Activé**.

## Autoriser le mappage des contributions aux administrateurs {#allow-contribution-mapping-to-administrators}

{{< history >}}

- Introduit dans GitLab 17.5 [avec un indicateur](../feature_flags/_index.md) nommé `importer_user_mapping`. Désactivé par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175371) dans GitLab 17.7.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/508944) dans GitLab 18.3. Indicateur de feature flag `importer_user_mapping` supprimé.

{{< /history >}}

Pour autoriser le mappage des contributions des utilisateurs importés aux administrateurs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**, puis développez **Paramètres d'importation et d'exportation**.
1. Faites défiler jusqu'à **Allow contribution mapping to administrators**.
1. Cochez la case **Activé**.

## Ignorer la confirmation lorsque les administrateurs réattribuent des utilisateurs fictifs {#skip-confirmation-when-administrators-reassign-placeholder-users}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/534330) dans GitLab 18.1 [avec un indicateur](../feature_flags/_index.md) nommé `importer_user_mapping_allow_bypass_of_confirmation`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/541373) dans GitLab 18.6. Indicateur de feature flag `importer_user_mapping_allow_bypass_of_confirmation` supprimé.

{{< /history >}}

Prérequis :

- Assurez-vous que [l'usurpation d'identité des utilisateurs n'est pas désactivée](../../api/rest/authentication.md#disable-impersonation) sur l'instance GitLab.

Pour ignorer la confirmation lorsque les administrateurs réattribuent des utilisateurs fictifs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Paramètres d'importation et d'exportation**.
1. Sous **Skip confirmation when administrators reassign placeholder users**, cochez la case **Activé**.

Lorsque ce paramètre est activé, les administrateurs peuvent réattribuer des contributions et des appartenances à des utilisateurs non-bots ayant l'un des états suivants :

- `active`
- `banned`
- `blocked`
- `blocked_pending_approval`
- `deactivated`
- `ldap_blocked`

## Taille maximale d'exportation {#max-export-size}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86124) dans GitLab 15.0.

{{< /history >}}

Pour modifier la taille maximale des fichiers pour les exportations dans GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**, puis développez **Paramètres d'importation et d'exportation**.
1. Augmentez ou diminuez en modifiant la valeur dans **Taille maximale de l'exportation (Mio)**.

## Taille maximale d'importation {#max-import-size}

Pour modifier la taille maximale des fichiers pour les importations dans GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Paramètres d'importation et d'exportation**.
1. Augmentez ou diminuez en modifiant la valeur dans **Taille maximale de l'importation (Mio)**.

Ce paramètre s'applique uniquement aux dépôts [importés depuis un fichier d'exportation GitLab](../../user/project/settings/import_export.md#import-a-project-and-its-data).

Si vous choisissez une taille supérieure à la valeur configurée pour le serveur web, vous pourriez recevoir des erreurs. Consultez la [section de dépannage](account_and_limit_settings.md#troubleshooting) pour plus de détails.

Pour les limites de taille des dépôts GitLab.com, consultez les [paramètres des comptes et des limites](../../user/gitlab_com/_index.md#account-and-limit-settings).

## Taille maximale des fichiers distants pour les importations {#maximum-remote-file-size-for-imports}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/384976) dans GitLab 16.3.

{{< /history >}}

Par défaut, la taille maximale des fichiers distants pour les importations depuis des stockages d'objets externes (par exemple, AWS) est de 10 Gio.

Pour modifier ce paramètre :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Paramètres d'importation et d'exportation**.
1. Dans **Taille maximale (Mo) des fichiers distants pour les importations**, saisissez une valeur. Définissez la valeur à `0` pour ne pas limiter la taille des fichiers.

## Taille maximale des fichiers à télécharger pour les importations par transfert direct {#maximum-download-file-size-for-imports-by-direct-transfer}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/384976) dans GitLab 16.3.

{{< /history >}}

Par défaut, la taille maximale des fichiers à télécharger pour les importations par transfert direct est de 5 Gio.

Pour modifier ce paramètre :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Paramètres d'importation et d'exportation**.
1. Dans **Taille maximale du fichier à télécharger (Mio)**, saisissez une valeur. Définissez la valeur à `0` pour ne pas limiter la taille des fichiers.

## Taille maximale des fichiers décompressés pour les archives importées {#maximum-decompressed-file-size-for-imported-archives}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128218) dans GitLab 16.3.
- Le champ **Maximum decompressed file size for archives from imports** a été [renommé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130081) depuis **Maximum decompressed size** dans GitLab 16.4.

{{< /history >}}

Lorsque vous importez un projet à l'aide des [exportations de fichiers](../../user/project/settings/import_export.md) ou du [transfert direct](../../user/group/import/_index.md), vous pouvez spécifier la taille maximale des fichiers décompressés pour les archives importées. La valeur par défaut est 25 Gio.

Lorsque vous importez un fichier compressé, la taille décompressée ne peut pas dépasser la limite de taille maximale des fichiers décompressés. Si la taille décompressée dépasse la limite configurée, l'erreur suivante est renvoyée :

```plaintext
Decompressed archive size validation failed.
```

Pour modifier ce paramètre :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Paramètres d'importation et d'exportation**.
1. Définissez une autre valeur pour **Taille maximale des fichiers décompressés pour les archives issues des importations (Mio)**.

## Délai d'expiration pour la décompression des fichiers archivés {#timeout-for-decompressing-archived-files}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128218) dans GitLab 16.4.

{{< /history >}}

Lorsque vous [importez un projet](../../user/project/settings/import_export.md), vous pouvez spécifier le délai d'expiration maximal pour la décompression des archives importées. La valeur par défaut est 210 secondes.

Pour modifier la taille maximale des fichiers décompressés pour les importations dans GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Paramètres d'importation et d'exportation**.
1. Définissez une autre valeur pour **Délai d'expiration pour la décompression des fichiers archivés (secondes)**.

## Nombre maximal de jobs d'importation simultanés {#maximum-number-of-simultaneous-import-jobs}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875) dans GitLab 16.11.

{{< /history >}}

Vous pouvez spécifier le nombre maximal de jobs d'importation exécutés simultanément pour :

- [Importateur GitHub](../../user/project/import/github.md)
- [Importateur Bitbucket Cloud](../../user/import/bitbucket_cloud.md)
- [Importateur Bitbucket Server](../../user/import/bitbucket_server.md)

La limite de jobs n'est pas appliquée lors de l'importation de merge requests car il existe une limite codée en dur pour les merge requests afin d'éviter de surcharger les serveurs.

La limite de jobs par défaut est :

- Pour l'importateur GitHub, 1 000.
- Pour les importateurs Bitbucket Cloud et Bitbucket Server, 100. Les importateurs Bitbucket ont une limite par défaut basse car nous n'avons pas encore déterminé une bonne limite par défaut. Les administrateurs d'instances doivent expérimenter avec une limite plus élevée.

Pour modifier ce paramètre :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Paramètres d'importation et d'exportation**.
1. Définissez une autre valeur pour **Maximum number of simultaneous import jobs** pour l'importateur souhaité.

## Nombre maximal de jobs d'exportation par lots simultanés {#maximum-number-of-simultaneous-batch-export-jobs}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169122) dans GitLab 17.6.

{{< /history >}}

Les exportations par transfert direct peuvent consommer une quantité importante de ressources. Pour éviter d'épuiser la base de données ou les processus Sidekiq, les administrateurs peuvent configurer le paramètre `concurrent_relation_batch_export_limit`.

La valeur par défaut est `8` jobs, ce qui correspond à une [architecture de référence pour jusqu'à 40 RPS ou 2 000 utilisateurs](../reference_architectures/2k_users.md). Si vous rencontrez des erreurs `PG::QueryCanceled: ERROR: canceling statement due to statement timeout` ou des jobs interrompus en raison des limites de mémoire de Sidekiq, vous pouvez réduire ce nombre. Si vous disposez de suffisamment de ressources, vous pouvez augmenter ce nombre pour traiter davantage de jobs d'exportation simultanés.

Pour modifier ce paramètre, envoyez une requête API à `/api/v4/application/settings` avec `concurrent_relation_batch_export_limit`. Pour plus d'informations, consultez l'[API des paramètres d'application](../../api/settings.md).

### Taille des lots d'exportation {#export-batch-size}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194607) dans GitLab 18.2.

{{< /history >}}

Pour mieux gérer l'utilisation de la mémoire et la charge de la base de données, utilisez le paramètre `relation_export_batch_size` pour contrôler le nombre d'enregistrements traités dans chaque lot lors des opérations d'exportation.

La valeur par défaut est `50` enregistrements par lot. Pour modifier ce paramètre, envoyez une requête API à `/api/v4/application/settings` avec `relation_export_batch_size`. Pour plus d'informations, consultez l'[API des paramètres d'application](../../api/settings.md).

## Dépannage {#troubleshooting}

## Erreur : `Help page documentation base url is blocked: execution expired` {#error-help-page-documentation-base-url-is-blocked-execution-expired}

Lors de l'activation des paramètres d'application tels que la [source d'importation](#configure-allowed-import-sources), vous pourriez obtenir une erreur `Help page documentation base url is blocked: execution expired`. Pour contourner cette erreur :

1. Ajoutez `docs.gitlab.com`, ou [l'URL des pages d'aide de redirection](help_page.md#redirect-help-pages), à la [liste d'autorisation](../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains).
1. Sélectionnez **Enregistrer les modifications**.

## Sujets connexes {#related-topics}

- [Importer et migrer vers GitLab](../../user/import/_index.md).
- [Configuration Sidekiq pour les importations](../sidekiq/configuration_for_imports.md).
- [Exécution de plusieurs processus Sidekiq](../sidekiq/extra_sidekiq_processes.md).
- [Traitement de classes de jobs spécifiques](../sidekiq/processing_specific_job_classes.md).
