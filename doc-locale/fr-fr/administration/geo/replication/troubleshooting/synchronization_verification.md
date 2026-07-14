---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage des erreurs de synchronisation et de vérification Geo
description: "Résoudre les échecs de synchronisation et de vérification Geo, couvrant les procédures de nouvelle tentative manuelle, les opérations en masse, le diagnostic des erreurs et la restauration de la cohérence des données."
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Si vous remarquez des échecs de réplication ou de vérification dans `Admin > Geo > Sites` ou dans la [tâche Rake de statut de synchronisation](common.md#sync-status-rake-task), vous pouvez essayer de résoudre les échecs en suivant les étapes générales ci-dessous :

1. Geo réessaie automatiquement les échecs. Si les échecs sont récents et peu nombreux, ou si vous pensez que la cause principale est déjà résolue, vous pouvez attendre pour voir si les échecs disparaissent.
1. Si les échecs sont présents depuis longtemps, de nombreuses tentatives ont déjà eu lieu et l'intervalle entre les nouvelles tentatives automatiques a augmenté jusqu'à 4 heures selon le type d'échec. Si vous pensez que la cause principale est déjà résolue, vous pouvez [relancer manuellement la réplication ou la vérification](#manually-retry-replication-or-verification) pour éviter l'attente.
1. Si les échecs persistent, utilisez les sections suivantes pour essayer de les résoudre.

## Procédures de diagnostic {#diagnostic-procedures}

Avant de tenter des nouvelles tentatives manuelles, vous pouvez utiliser ces procédures de diagnostic améliorées pour mieux comprendre la portée et la nature des problèmes de synchronisation.

### Vérification du statut du modèle {#model-status-check}

Cette procédure fournit des informations détaillées sur le statut de toutes les [classes de modèles de types de données Geo](#geo-data-type-model-classes) et aide à identifier les échecs de checksumming. Ces échecs surviennent lorsque la somme de contrôle d'un objet réplicable ne peut pas être calculée. Ils sont aussi parfois appelés « échecs de vérification principal ».

Vous pouvez afficher les échecs de somme de contrôle depuis l'interface utilisateur ou la console Rails.

{{< tabs >}}

{{< tab title="UI" >}}

Sur le site **principal**, utilisez la [page Gestion des données](../../../admin_area.md#data-management).

{{< /tab >}}

{{< tab title="Console Rails" >}}

Vous pouvez utiliser le script suivant pour afficher des informations détaillées pour chaque type de modèle, notamment :

- Nombre total d'enregistrements
- Nombre d'enregistrements en échec, vérifiés et en attente
- Exemples d'enregistrements en échec pour investigation

> [!note]
> La classe `ModelMapper` a été ajoutée dans [GitLab 18.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196293). Pour les versions plus anciennes, vous devez spécifier manuellement la liste des [classes de modèles de types de données Geo](#geo-data-type-model-classes).

1. Sur le site **principal**, [démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session).
1. Exécutez le script suivant pour obtenir une vue d'ensemble complète :

   ```ruby
   def output_geo_verification_failures
     model_classes = ::Gitlab::Geo::ModelMapper.available_models

     model_classes.each do |klass|
       total = klass.count
       state_klass = klass.verification_state_table_class
       failed_examples = []

       puts "\n=== #{klass.name} ==="
       puts "Total: #{total}"
       ::Geo::VerificationState::VERIFICATION_STATE_VALUES.each do |key, value|
         records = state_klass.where(verification_state: value)
         failed_examples = records if key == 'verification_failed'

         puts "#{key.gsub('verification_', '').camelize}: #{records.size}"
       end

       if failed_examples.any?
         puts "\nSample failed records:"
         failed_examples.limit(3).each { |record| puts "  ID: #{record.id}, Checksum: #{record.verification_checksum || 'nil'}, Error: #{record.verification_failure}" }
       end
     end

     nil
   end

   output_geo_verification_failures
   ```

{{< /tab >}}

{{< /tabs >}}

### Vérification du statut du registre {#registry-status-check}

Cette procédure fournit des informations détaillées sur le statut de tous les types de registres Geo et aide à identifier les modèles d'échecs.

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **secondaire**.
1. Exécutez le script suivant pour obtenir une vue d'ensemble complète :

   ```ruby
   def output_geo_failures()
     registry_classes = [
       Geo::UploadRegistry,
       Geo::JobArtifactRegistry,
       Geo::PackageFileRegistry,
       Geo::PagesDeploymentRegistry,
       Geo::ProjectRepositoryRegistry,
       Geo::TerraformStateVersionRegistry,
       Geo::MergeRequestDiffRegistry,
       Geo::LfsObjectRegistry,
       Geo::PipelineArtifactRegistry,
       Geo::CiSecureFileRegistry,
       Geo::ContainerRepositoryRegistry
     ]

     registry_classes.each do |klass|
       puts "\n=== #{klass.name} ==="
       puts "Total: #{klass.count}"
       puts "Failed: #{klass.failed.count}"
       puts "Synced: #{klass.synced.count}"
       puts "Pending: #{klass.pending.count}"
       puts "Started: #{klass.with_state(:started).count}"

       if klass.failed.count > 0
          puts "\nSample failed records:"
          klass.failed.limit(3).each { |record| puts "  ID: #{record.id}, Error: #{record.last_sync_failure}" }
       end
     end

     nil
   end

   output_geo_failures()
   ```

1. Ce script affiche des informations détaillées pour chaque type de registre, notamment :
   - Nombre total d'enregistrements
   - Nombre d'enregistrements en échec, synchronisés et en attente
   - Exemples d'enregistrements en échec pour investigation

## Relancer manuellement la réplication ou la vérification {#manually-retry-replication-or-verification}

Dans la [console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) d'un site Geo secondaire, vous pouvez :

- [Resynchroniser et revérifier manuellement des composants individuels](#resync-and-reverify-individual-components)
- [Resynchroniser et revérifier manuellement plusieurs composants](#resync-and-reverify-multiple-components)

### Resynchroniser et revérifier des composants individuels {#resync-and-reverify-individual-components}

Sur le site secondaire, accédez à **Admin** > **Geo** > **Replication** pour forcer une resynchronisation ou une revérification d'éléments individuels.

Cependant, si cela ne fonctionne pas, vous pouvez effectuer la même action en utilisant la console Rails. Les sections suivantes décrivent comment utiliser les commandes internes de l'application dans la [console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) pour déclencher la réplication ou la vérification d'enregistrements individuels de manière synchrone ou asynchrone.

#### Obtenir une instance de Replicator {#obtaining-a-replicator-instance}

> [!warning]
> Les commandes qui modifient des données peuvent causer des dommages si elles ne sont pas exécutées correctement ou dans les bonnes conditions. Exécutez toujours les commandes dans un environnement de test d'abord et ayez une instance de sauvegarde prête à restaurer.

Avant de pouvoir effectuer des opérations de synchronisation ou de vérification, vous devez obtenir une instance de Replicator.

Premièrement, [démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur un site **principal** ou **secondaire**, selon ce que vous souhaitez faire.

Site **Principal** :

- Vous pouvez calculer la somme de contrôle d'une ressource

Site **Secondaire** :

- Vous pouvez synchroniser une ressource
- Vous pouvez calculer la somme de contrôle d'une ressource et la vérifier par rapport à la somme de contrôle du site principal

Ensuite, exécutez l'un des extraits de code suivants pour obtenir une instance de Replicator.

##### À partir de l'ID d'un enregistrement de modèle {#given-a-model-records-id}

- Remplacez `123` par l'ID réel.
- Remplacez `Packages::PackageFile` par l'une des [classes de modèles de types de données Geo](#geo-data-type-model-classes).

```ruby
model_record = Packages::PackageFile.find_by(id: 123)
replicator = model_record.replicator
```

##### À partir de l'ID d'un enregistrement de registre {#given-a-registry-records-id}

- Remplacez `432` par l'ID réel. Un enregistrement de registre peut ou non avoir la même valeur d'ID que l'enregistrement de modèle qu'il suit.
- Remplacez `Geo::PackageFileRegistry` par l'une des [classes de registre Geo](#geo-registry-classes).

Sur un site Geo secondaire :

```ruby
registry_record = Geo::PackageFileRegistry.find_by(id: 432)
replicator = registry_record.replicator
```

##### À partir d'un message d'erreur dans le champ `last_sync_failure` d'un enregistrement de registre {#given-an-error-message-in-a-registry-records-last_sync_failure}

- Remplacez `Geo::PackageFileRegistry` par l'une des [classes de registre Geo](#geo-registry-classes).
- Remplacez `error message here` par le message d'erreur réel.

```ruby
registry = Geo::PackageFileRegistry.find_by("last_sync_failure LIKE '%error message here%'")
replicator = registry.replicator
```

##### À partir d'un message d'erreur dans le champ `verification_failure` d'un enregistrement de registre {#given-an-error-message-in-a-registry-records-verification_failure}

- Remplacez `Geo::PackageFileRegistry` par l'une des [classes de registre Geo](#geo-registry-classes).
- Remplacez `error message here` par le message d'erreur réel.

```ruby
registry = Geo::PackageFileRegistry.find_by("verification_failure LIKE '%error message here%'")
replicator = registry.replicator
```

#### Effectuer des opérations avec une instance de Replicator {#performing-operations-with-a-replicator-instance}

Une fois que vous avez une instance de Replicator stockée dans une variable `replicator`, vous pouvez effectuer de nombreuses opérations :

##### Synchronisation dans la console {#sync-in-the-console}

Cet extrait de code ne fonctionne que sur un site **secondaire**.

Cela exécute le code de synchronisation de manière synchrone dans la console, afin que vous puissiez observer la durée de synchronisation d'une ressource ou afficher une trace d'erreur complète.

```ruby
replicator.sync
```

Facultativement, rendez le niveau de journalisation de la console plus détaillé que le niveau de journalisation configuré, puis effectuez une synchronisation :

```ruby
Rails.logger.level = :debug
```

##### Somme de contrôle ou vérification dans la console {#checksum-or-verify-in-the-console}

Cet extrait de code fonctionne sur n'importe quel site **principal** ou **secondaire**.

Sur un site **principal**, il calcule la somme de contrôle de la ressource et stocke le résultat dans la base de données GitLab principale. Sur un site **secondaire**, il calcule la somme de contrôle de la ressource, la compare à la somme de contrôle de la base de données GitLab principale (générée par le site **principal**), et stocke le résultat dans la base de données de suivi Geo.

Cela exécute le code de somme de contrôle et de vérification de manière synchrone dans la console, afin que vous puissiez observer la durée ou afficher une trace d'erreur complète.

```ruby
replicator.verify
```

##### Synchronisation dans un job Sidekiq {#sync-in-a-sidekiq-job}

Cet extrait de code ne fonctionne que sur un site **secondaire**.

Il met en file d'attente un job pour que Sidekiq effectue une [synchronisation](#sync-in-the-console) de la ressource.

```ruby
replicator.enqueue_sync
```

##### Vérification dans un job Sidekiq {#verify-in-a-sidekiq-job}

Cet extrait de code fonctionne sur n'importe quel site **principal** ou **secondaire**.

Il met en file d'attente un job pour que Sidekiq effectue une [somme de contrôle ou une vérification](#checksum-or-verify-in-the-console) de la ressource.

```ruby
replicator.verify_async
```

##### Obtenir un enregistrement de modèle {#get-a-model-record}

Cet extrait de code fonctionne sur n'importe quel site **principal** ou **secondaire**.

```ruby
replicator.model_record
```

##### Obtenir un enregistrement de registre {#get-a-registry-record}

Cet extrait de code ne fonctionne que sur un site **secondaire** car les tables de registre sont stockées dans la base de données de suivi Geo.

```ruby
replicator.registry
```

#### Classes de modèles de types de données Geo {#geo-data-type-model-classes}

Un type de données Geo est une classe de données spécifique requise par une ou plusieurs fonctionnalités de GitLab pour stocker des données pertinentes et répliquée par Geo vers les sites secondaires.

- **Blob types** :
  - `Ci::JobArtifact`
  - `Ci::PipelineArtifact`
  - `Ci::SecureFile`
  - `LfsObject`
  - `MergeRequestDiff`
  - `Packages::PackageFile`
  - `PagesDeployment`
  - `Terraform::StateVersion`
  - `Upload`
  - `DependencyProxy::Manifest`
  - `DependencyProxy::Blob`
- **Git Repository types** :
  - `DesignManagement::Repository`
  - `ProjectRepository`
  - `ProjectWikiRepository`
  - `SnippetRepository`
  - `GroupWikiRepository`
- **Other types** :
  - `ContainerRepository`

Les principaux types de classes sont Registry, Model et Replicator. Si vous avez une instance de l'une de ces classes, vous pouvez obtenir les autres. Les classes Registry et Model gèrent principalement l'état de la base de données PostgreSQL. Le Replicator sait comment répliquer ou vérifier les données non-PostgreSQL (fichier/dépôt Git/dépôt de conteneurs).

#### Classes de registre Geo {#geo-registry-classes}

Dans le contexte de GitLab Geo, un **registry record** fait référence aux tables de registre dans la base de données de suivi Geo. Chaque enregistrement suit un seul élément réplicable dans la base de données GitLab principale, comme un fichier LFS ou un dépôt Git de projet. Les modèles Rails correspondant aux tables de registre Geo qui peuvent être interrogées sont :

- **Blob types** :
  - `Geo::CiSecureFileRegistry`
  - `Geo::DependencyProxyBlobRegistry`
  - `Geo::DependencyProxyManifestRegistry`
  - `Geo::JobArtifactRegistry`
  - `Geo::LfsObjectRegistry`
  - `Geo::MergeRequestDiffRegistry`
  - `Geo::PackageFileRegistry`
  - `Geo::PagesDeploymentRegistry`
  - `Geo::PipelineArtifactRegistry`
  - `Geo::ProjectWikiRepositoryRegistry`
  - `Geo::SnippetRepositoryRegistry`
  - `Geo::TerraformStateVersionRegistry`
  - `Geo::UploadRegistry`
- **Git Repository types** :
  - `Geo::DesignManagementRepositoryRegistry`
  - `Geo::ProjectRepositoryRegistry`
  - `Geo::ProjectWikiRepositoryRegistry`
  - `Geo::SnippetRepositoryRegistry`
  - `Geo::GroupWikiRepositoryRegistry`
- **Other types** :
  - `Geo::ContainerRepositoryRegistry`

### Resynchroniser et revérifier plusieurs composants {#resync-and-reverify-multiple-components}

{{< history >}}

- Resynchronisation et revérification en masse [ajoutées](https://gitlab.com/gitlab-org/gitlab/-/issues/364729) dans GitLab 16.5.

{{< /history >}}

Lorsque des ressources de composants échouent à se synchroniser ou à être vérifiées, vous pouvez déclencher des actions en masse pour relancer la file d'attente de réplication. Ces actions réinitialisent le compteur de nouvelles tentatives et l'heure planifiée à 0, ce qui permet au système de traiter les ressources en échec plus tôt plutôt que d'attendre jusqu'à 1 heure.

> [!note]
> Ces actions ne traitent pas immédiatement les ressources. Au lieu de cela, elles remettent en file d'attente les tâches d'arrière-plan qui gèrent la synchronisation et la vérification. Le travail de réplication effectif se produit de manière asynchrone via le processus de réplication Geo standard.

#### Fonctionnement de la resynchronisation et de la revérification {#how-resync-and-reverification-works}

Lorsque vous déclenchez une action de resynchronisation ou de revérification, le système marque les enregistrements correspondants comme `pending`. Les workers d'arrière-plan de resynchronisation et de revérification Geo récupèrent ces enregistrements et les traitent selon la priorité normale de la file d'attente. Ce mécanisme vous permet d'accélérer le traitement des ressources en échec sans bloquer immédiatement l'opération.

> [!note]
> Il n'est pas possible de revérifier un enregistrement qui n'a pas été synchronisé avec succès. Seul un enregistrement synchronisé peut être vérifié.

Il est possible de déclencher des actions en masse depuis l'interface utilisateur ou depuis la console Rails.

#### Depuis l'interface utilisateur {#from-the-ui}

Vous pouvez planifier une resynchronisation complète de toutes les ressources d'un composant depuis l'interface utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Sous **Replication details**, sélectionnez le composant souhaité.

##### Resynchroniser les ressources pour le composant sélectionné {#resync-resources-for-the-selected-component}

1. Sélectionnez **Tout resynchroniser** : cette action réinitialise le statut de tous les enregistrements pour la ressource sélectionnée, qu'ils soient déjà synchronisés ou non.
1. Sélectionnez **Resynchroniser tous les éléments en échec** : cette action réinitialise tous les enregistrements pour lesquels la synchronisation a échoué.

##### Revérifier les ressources pour le composant sélectionné {#reverify-resources-for-the-selected-component}

1. Sélectionnez **Tout revérifier** : cette action réinitialise le statut de tous les enregistrements pour la ressource sélectionnée, qu'ils soient déjà vérifiés ou non.
1. Sélectionnez **Vérifier à nouveau tous les éléments en échec** : cette action réinitialise tous les enregistrements pour lesquels la vérification a échoué, mais dont la synchronisation est réussie.

##### Revérifier un composant sur tous les sites {#reverify-one-component-on-all-sites}

Si les sommes de contrôle du site **principal** sont remises en question, vous devez faire recalculer les sommes de contrôle par le site **principal**. Une « revérification complète » est alors réalisée, car après que chaque somme de contrôle est recalculée sur un site **principal**, des événements sont générés et propagés à tous les sites **secondaire**, les amenant à recalculer leurs sommes de contrôle et à comparer les valeurs. Tout décalage marque le registre comme `sync failed`, ce qui entraîne la planification de nouvelles tentatives de synchronisation.

Vous pouvez recalculer la somme de contrôle du site principal depuis l'interface utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Gestion des données**.
1. Sélectionnez le composant souhaité dans la liste déroulante.
1. Sélectionnez **Vérifier tout**.

> [!warning]
> **Tout resynchroniser**, **Tout revérifier** et **Vérifier tout** déclenchent une mise à jour de toutes les ressources, qu'elles soient déjà synchronisées ou vérifiées. Cette action ne doit pas être exécutée lorsqu'il y a des milliers d'objets d'un certain type dans l'instance (par exemple, les artefacts de job CI).

#### Depuis la console Rails {#from-the-rails-console}

> [!warning]
> Les commandes qui modifient des données peuvent causer des dommages si elles ne sont pas exécutées correctement ou dans les bonnes conditions. Exécutez toujours les commandes dans un environnement de test d'abord et ayez une instance de sauvegarde prête à restaurer.

Les sections suivantes décrivent comment utiliser les commandes internes de l'application dans la [console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) pour déclencher la réplication ou la vérification en masse.

##### Synchroniser toutes les ressources d'un composant qui ont échoué à se synchroniser {#sync-all-resources-of-one-component-that-failed-to-sync}

Le script suivant :

- Parcourt tous les dépôts en échec.
- Affiche les métadonnées de synchronisation et de vérification Geo, y compris les raisons du dernier échec.
- Tente de resynchroniser le dépôt.
- Signale si un échec se produit et pourquoi.
- Peut prendre un certain temps à s'exécuter. Chaque vérification de dépôt doit se terminer avant de renvoyer le résultat. Si votre session expire, prenez des mesures pour permettre au processus de continuer à s'exécuter, par exemple en démarrant une session `screen`, ou en l'exécutant via le [Rails runner](../../../operations/rails_console.md#using-the-rails-runner) et `nohup`.

Exécutez ce script **on the secondary Geo site**.

```ruby
Geo::ProjectRepositoryRegistry.failed.find_each do |registry|
   begin
     puts "ID: #{registry.id}, Project ID: #{registry.project_id}, Last Sync Failure: '#{registry.last_sync_failure}'"
     registry.replicator.sync
     puts "Sync initiated for registry ID: #{registry.id}"
   rescue => e
     puts "ID: #{registry.id}, Project ID: #{registry.project_id}, Failed: '#{e}'", e.backtrace.join("\n")
   end
end; nil
```

##### Revérifier toutes les ressources dont le calcul de somme de contrôle a échoué sur le site principal {#reverify-all-resources-that-failed-to-checksum-on-the-primary-site}

Le système revérifie automatiquement toutes les ressources dont le calcul de somme de contrôle a échoué sur le site principal, mais il utilise un schéma de recul progressif pour éviter un volume excessif d'échecs.

Facultativement, par exemple si vous avez effectué une intervention, vous pouvez déclencher manuellement la revérification plus tôt :

1. Connectez-vous en SSH à un nœud GitLab Rails sur le site **principal**.
1. Ouvrez la [console Rails](../../../operations/rails_console.md#starting-a-rails-console-session).
1. En remplaçant `Upload` par l'une des [classes de modèles de types de données Geo](#geo-data-type-model-classes), marquez toutes les ressources comme `pending verification` :

   ```ruby
   Upload.verification_state_table_class.where(verification_state: 3).each_batch do |relation|
     relation.update_all(verification_state: 0)
   end
   ```

## Erreurs {#errors}

### Message : `The file is missing on the Geo primary site` {#message-the-file-is-missing-on-the-geo-primary-site}

L'échec de synchronisation `The file is missing on the Geo primary site` est courant lors de la configuration initiale d'un site Geo secondaire, causé par des incohérences de données sur le site principal.

Des incohérences de données et des fichiers manquants peuvent survenir en raison d'erreurs système ou humaines lors de l'exploitation de GitLab. Par exemple, un administrateur d'instance supprime manuellement plusieurs artefacts sur le système de fichiers local. Ces modifications ne sont pas correctement propagées à la base de données et entraînent des incohérences. Ces incohérences persistent et peuvent causer des frictions. Les sites Geo secondaires peuvent continuer à essayer de répliquer ces fichiers car ils sont toujours référencés dans la base de données mais n'existent plus.

> [!note]
> En cas de migration récente du stockage local vers le stockage d'objets, consultez la [section dédiée au dépannage du stockage d'objets](../../../object_storage.md#inconsistencies-after-migrating-to-object-storage).

#### Identifier les incohérences {#identify-inconsistencies}

Lorsque des fichiers manquants ou des incohérences sont présents, vous pouvez rencontrer des entrées dans `geo.log` telles que les suivantes. Prenez note du champ `"primary_missing_file" : true` :

```json
{
   "bytes_downloaded" : 0,
   "class" : "Geo::BlobDownloadService",
   "correlation_id" : "01JT69C1ECRBEMZHA60E5SAX8E",
   "download_success" : false,
   "download_time_s" : 0.196,
   "gitlab_host" : "gitlab.example.com",
   "mark_as_synced" : false,
   "message" : "Blob download",
   "model_record_id" : 55,
   "primary_missing_file" : true,
   "reason" : "Not Found",
   "replicable_name" : "upload",
   "severity" : "WARN",
   "status_code" : 404,
   "time" : "2025-05-01T16:02:44.836Z",
   "url" : "http://gitlab.example.com/api/v4/geo/retrieve/upload/55"
}
```

Les mêmes erreurs sont également reflétées dans l'interface utilisateur sous **Admin** > **Geo** > **Sites** lors de la révision du statut de synchronisation de réplicables spécifiques. Dans ce scénario, un envoi de fichier spécifique est manquant :

![Le tableau de bord des envois de fichiers Geo affichant toutes les erreurs d'échec.](img/geo_uploads_file_missing_v17_11.png)

![Le tableau de bord des envois de fichiers Geo affichant l'erreur de fichier manquant.](img/geo_uploads_file_missing_details_v17_11.png)

#### Nettoyer les incohérences {#clean-up-inconsistencies}

> [!warning]
> Assurez-vous de disposer d'une sauvegarde récente et fonctionnelle avant d'émettre des commandes de suppression.

Pour supprimer ces erreurs, identifiez d'abord les ressources particulières affectées. Ensuite, exécutez les commandes `destroy` appropriées pour vous assurer que la suppression est propagée sur tous les sites Geo et leurs bases de données. Sur la base du scénario précédent, un **upload** est à l'origine de ces erreurs, utilisé comme exemple ci-dessous.

1. Faites correspondre les incohérences identifiées au nom de leur [classe de modèle Geo](#geo-data-type-model-classes) respective. Le nom de classe est nécessaire dans les étapes suivantes. Dans ce scénario, pour les envois de fichiers, cela correspond à `Upload`.
1. Démarrez une [console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le **Geo primary site**.
1. Interrogez toutes les ressources dont la vérification a échoué en raison de fichiers manquants, en vous basant sur la *classe de modèle Geo* de l'étape précédente. Ajustez ou supprimez `limit(20)` pour afficher plus de résultats. Observez comment les ressources listées doivent correspondre à celles en échec affichées dans l'interface utilisateur :

   ```ruby
   Upload.verification_failed.where("verification_failure like '%File is not checksummable%'").limit(20)

   => #<Upload:0x00007b362bb6c4e8
    id: 55,
    size: 13346,
    path: "503d99159e2aa8a3ac23602058cfdf58/openbao.png",
    checksum: "db29d233de49b25d2085dcd8610bac787070e721baa8dcedba528a292b6e816b",
    model_id: 1,
    model_type: "Project",
    uploader: "FileUploader",
    created_at: Thu, 01 May 2025 15:54:10.549178000 UTC +00:00,
    store: 1,
    mount_point: nil,
    secret: "[FILTERED]",
    version: 2,
    uploaded_by_user_id: 1,
    organization_id: nil,
    namespace_id: nil,
    project_id: 1,
    verification_checksum: nil>
   ```

1. Facultativement, utilisez l'`id` des ressources affectées pour déterminer si elles sont encore nécessaires :

   ```ruby
   Upload.find(55)

   => #<Upload:0x00007b362bb6c4e8
    id: 55,
    size: 13346,
    path: "503d99159e2aa8a3ac23602058cfdf58/openbao.png",
    checksum: "db29d233de49b25d2085dcd8610bac787070e721baa8dcedba528a292b6e816b",
    model_id: 1,
    model_type: "Project",
    uploader: "FileUploader",
    created_at: Thu, 01 May 2025 15:54:10.549178000 UTC +00:00,
    store: 1,
    mount_point: nil,
    secret: "[FILTERED]",
    version: 2,
    uploaded_by_user_id: 1,
    organization_id: nil,
    namespace_id: nil,
    project_id: 1,
    verification_checksum: nil>
   ```

   - Si vous déterminez que les ressources affectées doivent être récupérées, vous pouvez explorer les options suivantes (non exhaustives) pour les récupérer :
     - Vérifiez si le site secondaire possède l'objet et copiez-le manuellement vers le site principal.
     - Cherchez dans les anciennes sauvegardes et copiez manuellement l'objet vers le site principal.
     - Effectuez des vérifications ponctuelles pour essayer de déterminer s'il est probablement acceptable de détruire les enregistrements, par exemple, s'il s'agit de très anciens artefacts, ils ne sont peut-être pas des données critiques.

1. Utilisez l'`id` des ressources identifiées pour les supprimer correctement individuellement ou en masse en utilisant `destroy`. Assurez-vous d'utiliser le nom de *classe de modèle Geo* approprié.
   - Supprimer des ressources individuelles :

     ```ruby
     Upload.find(55).destroy
     ```

   - Supprimer toutes les ressources affectées :

     ```ruby
     def destroy_uploads_not_checksummable
       uploads = Upload.verification_failed.where("verification_failure like '%File is not checksummable%'");1
       puts "Found #{uploads.count} resources that failed verification with 'File is not checksummable'."
       puts "Enter 'y' to continue: "
       prompt = STDIN.gets.chomp
       if prompt != 'y'
         puts "Exiting without action..."
         return
       end

       puts "Destroying all..."
       uploads.destroy_all
     end

     destroy_uploads_not_checksummable
     ```

Répétez les étapes pour toutes les ressources affectées et tous les types de données Geo.

### Message : `"Error during verification","error":"File is not checksummable"` {#message-error-during-verificationerrorfile-is-not-checksummable}

L'erreur `"Error during verification","error":"File is not checksummable"` est causée par des incohérences sur le site principal. Depuis GitLab 18.9, le message d'erreur inclut des détails supplémentaires sur la cause :

- `File is not checksummable - file does not exist at: <path>` :  Le fichier est absent du stockage. Le chemin affiché aide à identifier le fichier manquant.
- `File is not checksummable - <ModelClass> <ID> is excluded from verification` :  L'enregistrement est exclu de la portée de vérification.

Suivez les instructions fournies dans [Le fichier est absent du site Geo principal](#message-the-file-is-missing-on-the-geo-primary-site).

### Échec de vérification des envois de fichiers sur le site Geo principal {#failed-verification-of-uploads-on-the-primary-geo-site}

Si la vérification de certains envois de fichiers échoue sur le site Geo principal avec `verification_checksum = nil` et que `verification_failure` contient ``Error during verification: undefined method `underscore' for NilClass:Class`` ou ``The model which owns this upload is missing.``, cela est dû à des envois de fichiers orphelins. L'enregistrement parent propriétaire de l'envoi de fichier (le « modèle » de l'envoi) a été supprimé d'une façon ou d'une autre, mais l'enregistrement d'envoi existe toujours. Cela est généralement dû à un bug dans l'application, introduit en implémentant la suppression en masse du « modèle » tout en oubliant de supprimer en masse ses enregistrements d'envoi de fichiers associés. Ces échecs de vérification ne sont donc pas des échecs à vérifier, mais plutôt des erreurs résultant de données incorrectes dans Postgres.

Vous pouvez trouver ces erreurs dans le fichier `geo.log` sur le site Geo principal.

Pour confirmer que des enregistrements de modèle sont manquants, vous pouvez exécuter une tâche Rake sur le site Geo principal :

```shell
sudo gitlab-rake gitlab:uploads:check
```

Vous pouvez supprimer ces enregistrements d'envoi de fichiers sur le site Geo principal pour éliminer ces échecs en exécutant le script suivant depuis la [console Rails](../../../operations/rails_console.md) :

```ruby
def delete_orphaned_uploads(dry_run: true)
  if dry_run
    p "This is a dry run. Upload rows will only be printed."
  else
    p "This is NOT A DRY RUN! Upload rows will be deleted from the DB!"
  end

  subquery = Geo::UploadState.where("(verification_failure LIKE 'Error during verification: The model which owns this upload is missing.%' OR verification_failure = 'Error during verification: undefined method `underscore'' for NilClass:Class') AND verification_checksum IS NULL")
  uploads = Upload.where(upload_state: subquery)
  p "Found #{uploads.count} uploads with a model that does not exist"

  uploads_deleted = 0
  begin
    uploads.each do |upload|

      if dry_run
        p upload
      else
        uploads_deleted=uploads_deleted + 1
        p upload.destroy!
      end
    rescue => e
      puts "checking upload #{upload.id} failed with #{e.message}"
    end
  end

  p "#{uploads_deleted} remote objects were destroyed." unless dry_run
end
```

Le script précédent définit une méthode nommée `delete_orphaned_uploads` que vous pouvez appeler comme suit pour effectuer un test à blanc :

```ruby
delete_orphaned_uploads(dry_run: true)
```

Et pour supprimer réellement les lignes d'envoi de fichiers orphelines :

```ruby
delete_orphaned_uploads(dry_run: false)
```

### Clés de bail exclusif orphelines bloquant la synchronisation du dépôt {#orphaned-exclusive-lease-keys-blocking-repository-sync}

La synchronisation du dépôt peut être bloquée lorsqu'une clé de bail exclusif est orpheline, empêchant les opérations de synchronisation pendant jusqu'à 8 heures.

**Symptoms :**

- Synchronisation du dépôt bloquée : l'état de réplication du dépôt affecté alterne entre les états `pending` et `failed`.
- Nombre accru de lignes de journal avec le message « Cannot obtain an exclusive lease » dans `geo.log`.
- Aucun job de synchronisation actif en cours d'exécution pour le dépôt affecté.
- Affecte un seul dépôt pendant jusqu'à 8 heures jusqu'à l'expiration du bail.

**Diagnosis :**

1. Confirmez que le dépôt n'est pas en cours de synchronisation active en vérifiant l'interface d'administration Geo.
1. Vérifiez `geo.log` pour un nombre accru de messages « Cannot obtain an exclusive lease » :

   ```shell
   grep "Cannot obtain an exclusive lease" /var/log/gitlab/geo/geo.log
   ```

1. Vérifiez que toutes ces lignes de journal incluent un champ `lease_key` avec la valeur `geo_sync_ssf_service:project_repository:<repository id>`, où `<repository id>` est l'ID unique du dépôt affecté.
1. Vérifiez qu'aucun job de synchronisation actif ne s'exécute dans Sidekiq pour le dépôt affecté.

**Workaround :**

> [!warning]
> L'approche recommandée est d'attendre l'expiration du bail de 8 heures. La libération manuelle du bail ne doit être utilisée que lorsque la synchronisation immédiate est critique et que vous avez confirmé qu'aucun job de synchronisation n'est en cours d'exécution.

Pour libérer manuellement une clé de bail orpheline :

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **secondaire**.
1. Trouvez l'ID de projet du dépôt affecté (remplacez `<project-path>` par le chemin du projet réel) :

   ```ruby
   project = Project.find_by_full_path('<project-path>')
   project_id = project.id
   ```

1. Dans la même session, libérez le bail orphelin :

   ```ruby
   replicator = Geo::ProjectRepositoryRegistry.find_by(project_id: project_id).replicator
   sync_service = Geo::FrameworkRepositorySyncService.new(replicator)
   uuid = Gitlab::ExclusiveLease.get_uuid(sync_service.lease_key)

   if uuid
     Gitlab::ExclusiveLease.cancel(sync_service.lease_key, uuid)
     puts "Lease released for project ID #{project_id}"
   else
     puts "No active lease found for project ID #{project_id}"
   end
   ```

1. Vérifiez que le bail a été libéré et déclenchez une nouvelle synchronisation :

   ```ruby
   replicator.sync
   ```

> [!note]
> Après la libération du bail, la synchronisation du dépôt sera relancée selon le calendrier de synchronisation Geo normal, ou vous pouvez déclencher manuellement une synchronisation comme indiqué ci-dessus.

### Erreur : `Error syncing repository: 13:fatal: could not read Username` {#error-error-syncing-repository-13fatal-could-not-read-username}

L'erreur `last_sync_failure` `Error syncing repository: 13:fatal: could not read Username for 'https://gitlab.example.com': terminal prompts disabled` indique que l'authentification JWT échoue lors d'une requête de clonage ou de récupération Geo.

Vérifiez d'abord que les horloges système sont synchronisées. Exécutez la [tâche Rake de vérification de santé](common.md#health-check-rake-task), ou vérifiez manuellement que `date`, sur tous les nœuds Sidekiq du site secondaire et tous les nœuds Puma du site principal, sont identiques.

Si les horloges système sont synchronisées, le jeton JWT peut expirer pendant que Git fetch effectue des calculs entre ses deux requêtes HTTP distinctes. Consultez le [ticket 464101](https://gitlab.com/gitlab-org/gitlab/-/issues/464101), qui existait dans toutes les versions de GitLab jusqu'à ce qu'il soit corrigé dans GitLab 17.1.0, 17.0.5 et 16.11.7.

Pour valider si vous êtes confronté à ce problème :

1. Appliquez un patch à chaud (monkey patch) dans une [console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) pour augmenter la période de validité du jeton de 1 minute à 10 minutes. Exécutez ceci dans la console Rails sur le site secondaire :

   ```ruby
   module Gitlab; module Geo; class BaseRequest
     private
     def geo_auth_token(message)
       signed_data = Gitlab::Geo::SignedData.new(geo_node: requesting_node, validity_period: 10.minutes).sign_and_encode_data(message)

       "#{GITLAB_GEO_AUTH_TOKEN_TYPE} #{signed_data}"
     end
   end;end;end
   ```

1. Dans la même console Rails, resynchronisez un projet affecté :

   ```ruby
   Project.find_by_full_path('<mygroup/mysubgroup/myproject>').replicator.resync
   ```

1. Regardez l'état de synchronisation :

   ```ruby
   Project.find_by_full_path('<mygroup/mysubgroup/myproject>').replicator.registry
   ```

1. Si `last_sync_failure` n'inclut plus l'erreur `fatal: could not read Username`, alors vous êtes affecté par ce problème. L'état devrait maintenant être `2`, ce qui signifie qu'il est synchronisé. Si c'est le cas, vous devez mettre à niveau vers une version de GitLab contenant le correctif. Vous pouvez également voter pour ou commenter le [ticket 466681](https://gitlab.com/gitlab-org/gitlab/-/issues/466681) qui aurait réduit la gravité de ce problème.

Pour contourner le problème, vous devez appliquer un patch à chaud sur tous les nœuds Sidekiq du site secondaire pour prolonger le délai d'expiration JWT :

1. Modifiez `/opt/gitlab/embedded/service/gitlab-rails/ee/lib/gitlab/geo/signed_data.rb`.
1. Trouvez `Gitlab::Geo::SignedData.new(geo_node: requesting_node)` et ajoutez-y `, validity_period: 10.minutes` :

   ```diff
   - Gitlab::Geo::SignedData.new(geo_node: requesting_node)
   + Gitlab::Geo::SignedData.new(geo_node: requesting_node, validity_period: 10.minutes)
   ```

1. Redémarrez Sidekiq :

   ```shell
   sudo gitlab-ctl restart sidekiq
   ```

1. Sauf si vous mettez à niveau vers une version contenant le correctif, vous devrez répéter cette solution de contournement après chaque mise à niveau de GitLab.

### Erreur : `Error syncing repository: 13:creating repository: cloning repository: exit status 128` {#error-error-syncing-repository-13creating-repository-cloning-repository-exit-status-128}

Vous pouvez voir cette erreur pour des projets qui ne se synchronisent pas correctement.

Le code de sortie 128 lors de la création d'un dépôt signifie que Git a rencontré une erreur fatale lors du clonage. Cela peut être dû à une corruption du dépôt, à des problèmes réseau, à des problèmes d'authentification, à des limites de ressources, ou parce que le projet n'a pas de dépôt Git associé. Des informations supplémentaires sur la cause spécifique de ces échecs peuvent être trouvées dans les journaux Gitaly.

En cas de doute sur la marche à suivre, effectuez une vérification d'intégrité sur le dépôt source du site Principal en [exécutant manuellement la commande `git fsck` en ligne de commande](../../../repository_checks.md#run-a-check-using-the-command-line).

#### Code de sortie 128 causé par une erreur HTTP 504 d'un équilibreur de charge {#exit-status-128-caused-by-http-504-from-a-load-balancer}

Pour les grands dépôts, les journaux Gitaly sur le site secondaire peuvent afficher :

```plaintext
error: RPC failed; HTTP 504 curl 22 The requested URL returned error: 504
fatal: expected 'packfile'
```

Cette erreur se produit lorsqu'un équilibreur de charge ou un proxy devant le site principal met fin à la connexion lors du transfert du packfile de clonage Git. Cela se produit fréquemment avec les AWS Application Load Balancers (ALB), qui ont un délai d'inactivité par défaut de 60 secondes. Pour les grands dépôts où Gitaly prend du temps à préparer le packfile avant le début du transfert de données, l'ALB peut interrompre la connexion avant qu'aucune donnée ne soit envoyée et déclencher l'erreur.

Pour résoudre ce problème :

1. Augmentez le délai d'inactivité sur l'équilibreur de charge devant le site principal pour accommoder les clonages de grands dépôts. Pour AWS ALB, mettez à jour le paramètre de délai d'inactivité dans les attributs de l'équilibreur de charge dans la AWS Management Console.
1. Réinitialisez les registres en échec :
   1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **secondaire**.
   1. Identifiez et réinitialisez les dépôts affectés :

      ```ruby
      project_ids = Geo::ProjectRepositoryRegistry.failed
                      .where("last_sync_failure LIKE '%exit status 128%'")
                      .pluck(:project_id)

      puts "Found #{project_ids.count} repositories failing with exit status 128"

      # state: 0 sets the registry back to pending so Geo retries the sync
      Geo::ProjectRepositoryRegistry.where(project_id: project_ids).update_all(
        state: 0,
        retry_count: 0,
        retry_at: nil,
        last_sync_failure: nil
      )

      puts "Reset #{project_ids.count} registries to pending"
      ```

1. Attendez que Geo relance la synchronisation automatiquement, ou [relancez manuellement la réplication](#manually-retry-replication-or-verification).

### Erreur : `gitmodulesUrl: disallowed submodule url` {#error-gitmodulesurl-disallowed-submodule-url}

Certains dépôts de projets échouent systématiquement à se synchroniser avec l'erreur `Error syncing repository: 13:creating repository: cloning repository: exit status 128`. Cependant, pour certains dépôts, le message d'erreur spécifique dans les journaux Gitaly est différent : `gitmodulesUrl: disallowed submodule url`. Cet échec se produit lorsque des dépôts contiennent des URL de sous-modules invalides dans leurs fichiers `.gitmodules`.

**Root Cause:** Ce problème est causé par des **historical commits** dans le dépôt Git qui contiennent des fichiers `.gitmodules` avec des URL malformées. Le problème se produit lors des vérifications de cohérence de Git (`git fsck`) qui s'exécutent lorsque Geo tente de cloner le dépôt du site principal vers le site secondaire.

Le problème se situe dans l'historique des commits du dépôt. Les URL de sous-modules dans les fichiers `.gitmodules` contiennent des formats invalides, utilisant `:` au lieu de `/` dans le chemin :

- Invalide : `https://example.gitlab.com:group/project.git`
- Valide : `https://example.gitlab.com/group/project.git`

**Why this breaks Geo synchronization :**

1. **Git's strict validation** :  À partir de GitLab 17.0 et des nouvelles versions de Git, Git effectue des vérifications `fsck` plus strictes lors des opérations de clonage
1. **Historical data persistence** :  Même si le fichier `.gitmodules` actuel est correct, Git stocke toutes les versions historiques sous forme de « blobs » dans le dépôt
1. **Clone-time failure** :  Lorsque Geo tente de cloner le dépôt, le `fsck` de Git examine **all objects** (y compris les historiques) et échoue lorsqu'il trouve des URL malformées
1. **Complete sync failure** :  L'opération de clonage entière échoue, empêchant le dépôt d'atteindre le site secondaire

**Important :** La modification du fichier `.gitmodules` actuel ne **not** ce problème car les données problématiques existent dans l'historique Git du dépôt, pas seulement dans la version actuelle du fichier.

Ce problème est connu dans GitLab 17.0 et versions ultérieures, et résulte de vérifications de cohérence de dépôt plus strictes. Ce nouveau comportement résulte d'une modification de Git lui-même, où cette vérification a été ajoutée. Ce n'est pas spécifique à GitLab Geo ou Gitaly. Pour plus d'informations, consultez le [ticket 468560](https://gitlab.com/gitlab-org/gitlab/-/issues/468560).

#### Solution de contournement {#workaround}

1. **Backup projects**

   Avant de continuer, assurez-vous de sauvegarder les projets au préalable, en utilisant l'[option d'exportation de projet](../../../../user/project/settings/import_export.md).

1. **Identify problematic blob IDs**

   Pour chaque projet affecté, identifiez les ID de blobs problématiques en utilisant l'une de ces méthodes :

   - Utilisez `git fsck` :  Clonez le dépôt, puis exécutez `git fsck` pour confirmer le problème :

     ```shell
     git clone https://example.gitlab.com/group/project.git
     cd project
     git fsck
     ```

     La sortie montre le blob problématique :

     ```plaintext
     Checking object directories: 100% (256/256), done.
     error in blob <SHA>: gitmodulesUrl: disallowed submodule url: https://example.gitlab.com:group/project.git
     Checking objects: 100% (12/12), done.
     ```

   - Consultez les journaux Gitaly. Recherchez les messages d'erreur contenant `gitmodulesUrl` pour trouver le SHA de blob spécifique.

1. **Supprimer les objets blob**

   Pour chaque projet affecté, [supprimez les ID de blobs problématiques](../../../../user/project/repository/repository_size.md#remove-blobs) identifiés lors de l'étape précédente.

   **Important limitation :** Si l'un de ces dépôts fait partie d'un réseau de duplication, la méthode de suppression de blob peut ne pas fonctionner (les blobs contenus dans des pools d'objets ne peuvent pas être supprimés de cette façon).

1. **Fix .gitmodules invalid URLs if required**

   Vérifiez l'état des fichiers `.gitmodules` dans chaque dépôt affecté

   Si le fichier `.gitmodules` contient toujours des URL invalides comme `https://example.gitlab.com:foo/bar.git` au lieu de `https://example.gitlab.com/foo/bar.git`, le client doit :

   - Corriger les URL dans le fichier `.gitmodules`
   - Pousser un commit avec des URL valides

> [!warning]
> Après la correction, tous les développeurs travaillant sur les projets affectés doivent supprimer leurs copies locales actuelles et cloner de nouveaux dépôts. Sinon, ils pourraient réintroduire les blobs problématiques lors de la transmission de modifications.

### Erreur : `fetch remote: signal: terminated: context deadline exceeded` exactement à 3 heures {#error-fetch-remote-signal-terminated-context-deadline-exceeded-at-exactly-3-hours}

Si Git fetch échoue exactement à trois heures lors de la synchronisation d'un dépôt Git :

1. Modifiez `/etc/gitlab/gitlab.rb` pour augmenter le délai d'expiration Git par rapport à la valeur par défaut de 10800 secondes :

   ```ruby
   # Git timeout in seconds
   gitlab_rails['gitlab_shell_git_timeout'] = 21600
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Erreur `Failed to open TCP connection to localhost:5000` sur le site secondaire lors de la configuration de la réplication du registre {#error-failed-to-open-tcp-connection-to-localhost5000-on-secondary-when-configuring-registry-replication}

Vous pouvez rencontrer l'erreur suivante lors de la configuration de la réplication du registre de conteneurs sur le site secondaire :

```plaintext
Failed to open TCP connection to localhost:5000 (Connection refused - connect(2) for \"localhost\" port 5000)"
```

Cela se produit si le registre de conteneurs n'est pas activé sur le site secondaire. Pour corriger cela, vérifiez que le registre de conteneurs est [activé sur le site secondaire](../../../packages/container_registry.md#enable-the-container-registry). Si l'[intégration Let's Encrypt est désactivée](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually) , le registre de conteneurs est également désactivé et vous devez [le configurer manuellement](../../../packages/container_registry.md#configure-container-registry-under-its-own-domain).

### Erreur : `Verification timed out after 28800` {#error-verification-timed-out-after-28800}

**Possible Root Cause :** Des enregistrements de registre en double causant des conflits de vérification dans différents types de registres.

**Diagnosis :**

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **secondaire**.
1. Vérifiez la présence de registres en double dans différents types :

   ```ruby
   # Check for duplicate upload registries
   upload_ids = Geo::UploadRegistry.group(:file_id).having('COUNT(*) > 1').pluck(:file_id)
   puts "Duplicate upload IDs count: #{upload_ids.size}"
   puts 'Duplicate Upload IDs:', upload_ids

   # Check for duplicate job artifact registries
   artifact_ids = Geo::JobArtifactRegistry.group(:artifact_id).having('COUNT(*) > 1').pluck(:artifact_id)
   puts "Duplicate artifact IDs count: #{artifact_ids.size}"
   puts 'Duplicate Artifact IDs:', artifact_ids

   # Check for duplicate package file registries
   package_file_ids = Geo::PackageFileRegistry.group(:package_file_id).having('COUNT(*) > 1').pluck(:package_file_id)
   puts "Duplicate package file IDs count: #{package_file_ids.size}"
   puts 'Duplicate Package File IDs:', package_file_ids

   # Check for duplicate LFS object registries
   lfs_object_ids = Geo::LfsObjectRegistry.group(:lfs_object_id).having('COUNT(*) > 1').pluck(:lfs_object_id)
   puts "Duplicate LFS object IDs count: #{lfs_object_ids.size}"
   puts 'Duplicate LFS Object IDs:', lfs_object_ids

   # Check for duplicate pages deployment registries
   pages_deployment_ids = Geo::PagesDeploymentRegistry.group(:pages_deployment_id).having('COUNT(*) > 1').pluck(:pages_deployment_id)
   puts "Duplicate pages deployment IDs count: #{pages_deployment_ids.size}"
   puts 'Duplicate Pages Deployment IDs:', pages_deployment_ids

   # Check for duplicate terraform state version registries
   terraform_state_ids = Geo::TerraformStateVersionRegistry.group(:terraform_state_version_id).having('COUNT(*) > 1').pluck(:terraform_state_version_id)
   puts "Duplicate terraform state version IDs count: #{terraform_state_ids.size}"
   puts 'Duplicate Terraform State Version IDs:', terraform_state_ids
   ```

**Resolution :**

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **secondaire**.
1. Supprimez les entrées de registre en double pour chaque type affecté :

   ```ruby
   # Remove duplicate upload registries
   upload_ids = Geo::UploadRegistry.group(:file_id).having('COUNT(*) > 1').pluck(:file_id)
   if upload_ids.any?
     Geo::UploadRegistry.where(file_id: upload_ids).delete_all
     puts "Removed #{upload_ids.size} duplicate upload registry entries"
   end

   # Remove duplicate job artifact registries
   artifact_ids = Geo::JobArtifactRegistry.group(:artifact_id).having('COUNT(*) > 1').pluck(:artifact_id)
   if artifact_ids.any?
     Geo::JobArtifactRegistry.where(artifact_id: artifact_ids).delete_all
     puts "Removed #{artifact_ids.size} duplicate job artifact registry entries"
   end

   # Remove duplicate package file registries
   package_file_ids = Geo::PackageFileRegistry.group(:package_file_id).having('COUNT(*) > 1').pluck(:package_file_id)
   if package_file_ids.any?
     Geo::PackageFileRegistry.where(package_file_id: package_file_ids).delete_all
     puts "Removed #{package_file_ids.size} duplicate package file registry entries"
   end

   # Remove duplicate LFS object registries
   lfs_object_ids = Geo::LfsObjectRegistry.group(:lfs_object_id).having('COUNT(*) > 1').pluck(:lfs_object_id)
   if lfs_object_ids.any?
     Geo::LfsObjectRegistry.where(lfs_object_id: lfs_object_ids).delete_all
     puts "Removed #{lfs_object_ids.size} duplicate LFS object registry entries"
   end

   # Remove duplicate pages deployment registries
   pages_deployment_ids = Geo::PagesDeploymentRegistry.group(:pages_deployment_id).having('COUNT(*) > 1').pluck(:pages_deployment_id)
   if pages_deployment_ids.any?
     Geo::PagesDeploymentRegistry.where(pages_deployment_id: pages_deployment_ids).delete_all
     puts "Removed #{pages_deployment_ids.size} duplicate pages deployment registry entries"
   end

   # Remove duplicate terraform state version registries
   terraform_state_ids = Geo::TerraformStateVersionRegistry.group(:terraform_state_version_id).having('COUNT(*) > 1').pluck(:terraform_state_version_id)
   if terraform_state_ids.any?
     Geo::TerraformStateVersionRegistry.where(terraform_state_version_id: terraform_state_ids).delete_all
     puts "Removed #{terraform_state_ids.size} duplicate terraform state version registry entries"
   end
   ```

1. Vérifiez le nettoyage sur tous les types de registres :

   ```ruby
   # Verify no remaining duplicates
   upload_duplicates = Geo::UploadRegistry.group(:file_id).having('COUNT(*) > 1').count
   artifact_duplicates = Geo::JobArtifactRegistry.group(:artifact_id).having('COUNT(*) > 1').count
   package_duplicates = Geo::PackageFileRegistry.group(:package_file_id).having('COUNT(*) > 1').count
   lfs_duplicates = Geo::LfsObjectRegistry.group(:lfs_object_id).having('COUNT(*) > 1').count
   pages_duplicates = Geo::PagesDeploymentRegistry.group(:pages_deployment_id).having('COUNT(*) > 1').count
   terraform_duplicates = Geo::TerraformStateVersionRegistry.group(:terraform_state_version_id).having('COUNT(*) > 1').count

   puts "Remaining duplicates:"
   puts "  Uploads: #{upload_duplicates.size}"
   puts "  Job Artifacts: #{artifact_duplicates.size}"
   puts "  Package Files: #{package_duplicates.size}"
   puts "  LFS Objects: #{lfs_duplicates.size}"
   puts "  Pages Deployments: #{pages_duplicates.size}"
   puts "  Terraform State Versions: #{terraform_duplicates.size}"
   ```

### Erreur : `Checksum does not match the primary checksum` {#error-checksum-does-not-match-the-primary-checksum}

**Possible Root Cause :** Des modifications de l'intervalle de vérification du dépôt ou du registre de conteneurs causant des incohérences de somme de contrôle.

**Diagnosis :**

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **secondaire**.
1. Vérifiez les dépôts ou les registres de conteneurs en échec :

   ```ruby
   failed_repos = Geo::ProjectRepositoryRegistry.failed.limit(100)
   failed_repos.each do |repo|
     puts "Project ID: #{repo.project_id}"
     puts "Primary checksum: #{repo.verification_checksum_mismatched}"
     puts "Secondary checksum: #{repo.verification_checksum}"
     puts "Error: #{repo.last_sync_failure}"
     puts "---"
   end
   ```

   ```ruby
   failed_container_repos = Geo::ContainerRepositoryRegistry.failed.limit(100)
   failed_container_repos.each do |repo|
     puts "Container Repo Id: #{repo.model_record_id}"
     puts "Primary checksum: #{repo.verification_checksum_mismatched}"
     puts "Secondary checksum: #{repo.verification_checksum}"
     puts "Error: #{repo.last_sync_failure}"
     puts "---"
   end
   ```

**Resolution :**

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **principal**.
1. Forcez la revérification pour des projets spécifiques ou des registres de conteneurs :

   ```ruby
   project_ids = [1, 2, 3] # Replace with actual failing project IDs

   project_ids.each do |project_id|
     project = Project.find(project_id)
     puts "Reverifying project: #{project.full_path}"

     project_state = project.project_state
     project_state.update!(verification_state: 0)

     puts "Project #{project_id} marked for reverification"
   end
   ```

   ```ruby
   container_repo_ids = [1, 2, 3]

   container_repo_ids.each do |repo_id|
     container_repo = ContainerRepository.find(repo_id)
     puts "Reverifying container repository: #{container_repo.path}"

     state = container_repo.container_repository_state
     state.update!(verification_state: 0)

     puts "Container Repo #{repo_id} marked for reverification"
   end
   ```

### Dépannage spécifique au type d'objet pour `Error during verification: File is not checksummable` {#object-type-specific-troubleshooting-for-error-during-verification-file-is-not-checksummable}

Les différents types de données Geo ont des caractéristiques uniques et des modèles d'échec courants. Cette section fournit un dépannage ciblé pour des types d'objets spécifiques.

#### Envois de fichiers {#uploads}

**Diagnosis :**

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **principal**.
1. Identifiez les envois de fichiers avec des fichiers manquants. Mettez à jour `limit(5)` si nécessaire pour voir plus de résultats :

   ```ruby
   checksummable_failures = Upload.verification_failed
                                   .where("verification_failure LIKE '%File is not checksummable%'")

   puts "Found #{checksummable_failures.count} uploads with missing files"

   checksummable_failures.limit(5).each_with_index do |record, index|
     puts "Record #{index + 1}:"
     puts "  ID: #{record.id}"
     puts "  Path: #{record.path}"
     puts "  Model: #{record.model_type} (ID: #{record.model_id})"
     puts "  Created: #{record.created_at}"
     puts "---"
   end
   ```

**Resolution :**

Pour résoudre ces échecs, suivez les étapes de la section [échec de vérification des envois de fichiers sur le site Geo principal](#failed-verification-of-uploads-on-the-primary-geo-site).

#### Déploiements Pages {#pages-deployments}

**Diagnosis :**

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **principal**.
1. Inspectez les déploiements Pages problématiques :

   ```ruby
   checksummable_failures = PagesDeployment.verification_failed
                                           .where("verification_failure LIKE '%File is not checksummable%'")

   checksummable_failures.each_with_index do |record, index|
     puts "Record #{index + 1}:"
     puts "  ID: #{record.id}"
     puts "  Project: #{record.project.full_path}"
     puts "  Created: #{record.created_at}"
     puts "  File exists: #{record.file.exists?}"
     puts "---"
   end
   ```

**Resolution :**

> [!warning]
> Assurez-vous de disposer d'une sauvegarde récente et fonctionnelle avant de supprimer des enregistrements de déploiement Pages. Coordonnez avec votre équipe pour confirmer que ces déploiements peuvent être supprimés en toute sécurité.

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **principal**.
1. Après confirmation avec votre équipe que les déploiements peuvent être supprimés en toute sécurité :

   ```ruby
   def destroy_pages_deployments_not_checksummable(dry_run: true)
     deployments = PagesDeployment.verification_failed.where("verification_failure LIKE '%File is not checksummable%'")
     puts "Found #{deployments.count} pages deployments that failed verification with 'File is not checksummable'."

     if dry_run
       puts "DRY RUN - No changes made"
       deployments.each { |d| puts "Would remove: ID #{d.id}, Project: #{d.project.full_path}" }
       return
     end

     puts "Enter 'y' to continue: "
     prompt = STDIN.gets.chomp
     if prompt != 'y'
       puts "Exiting without action..."
       return
     end

     puts "Destroying all..."
     deployments.destroy_all
     puts "Done!"
   end

   # Run in dry run mode first
   destroy_pages_deployments_not_checksummable(dry_run: true)
   ```

#### Objets LFS {#lfs-objects}

**Diagnosis :**

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **principal**.
1. Inspectez les objets LFS problématiques :

   ```ruby
   checksummable_failures = LfsObject.verification_failed
                                     .where("verification_failure LIKE '%File is not checksummable%'")

   checksummable_failures.each_with_index do |record, index|
     puts "Record #{index + 1}:"
     puts "  OID: #{record.oid}"
     puts "  Size: #{record.size} bytes"
     puts "  File Store: #{record.file_store}"
     puts "  Created: #{record.created_at}"

     # Show associated projects
     associations = record.lfs_objects_projects.includes(:project)
     puts "  Associated projects (#{associations.count}):"
     associations.each do |assoc|
       project = assoc.project
       if project
         puts "    - #{project.full_path}"
       else
         puts "    - Project ID: #{assoc.project_id} (not found)"
       end
     end
     puts "---"
   end
   ```

**Resolution :**

> [!warning]
> La suppression des objets LFS affecte tous les projets qui les référencent. Assurez-vous de disposer de sauvegardes et coordonnez avec les mainteneurs de projets avant la suppression.

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **principal**.
1. Supprimez les objets LFS avec des fichiers manquants :

   ```ruby
   def destroy_lfs_not_checksummable(dry_run: true)
     lfs_objects = LfsObject.verification_failed.where("verification_failure like '%File is not checksummable%'")
     puts "Found #{lfs_objects.count} LFS objects that failed verification with 'File is not checksummable'."

     if dry_run
       puts "DRY RUN - No changes made"
       lfs_objects.each { |obj| puts "Would remove: OID #{obj.oid}, Size: #{obj.size}" }
       return
     end

     puts "Enter 'y' to continue with deletion: "
     prompt = STDIN.gets.chomp
     if prompt != 'y'
       puts "Exiting without action..."
       return
     end

     puts "Destroying all..."
     lfs_objects.each do |lfs_object|
       lfs_object.lfs_objects_projects.destroy_all
       lfs_object.destroy!
     end
     puts "Done!"
   end

   # Run in dry run mode first
   destroy_lfs_not_checksummable(dry_run: true)
   ```

#### Artefacts de job {#job-artifacts}

**Diagnosis :**

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **principal**.
1. Vérifiez la présence d'artefacts avec des fichiers manquants :

   ```ruby
   failed_artifacts = Ci::JobArtifact.verification_failed.where("verification_failure LIKE '%File is not checksummable%'")

   failed_artifacts.each do |registry|
     artifact = Ci::JobArtifact.find_by(id: registry.id)
     if artifact
       puts "Artifact ID: #{artifact.id}"
       puts "Job ID: #{artifact.job_id}"
       puts "Project ID: #{artifact.project_id}"
       puts "File exists: #{artifact.file.exists?}"
       puts "File path: #{artifact.file.path}"
     else
       puts "Artifact ID #{artifact.id} not found in database"
     end
     puts "---"
   end
   ```

**Resolution :**

> [!warning]
> Assurez-vous de disposer d'une sauvegarde récente et fonctionnelle avant de supprimer des enregistrements d'artefacts de job. Coordonnez avec votre équipe pour confirmer que ces artefacts peuvent être supprimés en toute sécurité.

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **principal**.
1. Nettoyez les artefacts avec des fichiers manquants :

   ```ruby
   def cleanup_missing_artifacts(dry_run: true)
     missing_file_artifacts = []

     Ci::JobArtifact.find_each do |artifact|
       unless artifact.file.exists?
         missing_file_artifacts << artifact.id
         puts "Missing file for artifact #{artifact.id}" if dry_run
       end
     end

     puts "Found #{missing_file_artifacts.size} artifacts with missing files"

     unless dry_run
       Ci::JobArtifact.where(id: missing_file_artifacts).destroy_all
       puts "Removed #{missing_file_artifacts.size} artifacts with missing files"
     end
   end

   # Run in dry run mode first
   cleanup_missing_artifacts(dry_run: true)
   ```

#### Fichiers de packages {#package-files}

Cette erreur se produit lorsque des fichiers de packages sont absents du stockage sur le site principal.

Pour identifier les fichiers de packages affectés :

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **principal**.
1. Interrogez les enregistrements affectés. Mettez à jour `limit(5)` si nécessaire pour voir plus de résultats :

   ```ruby
   checksummable_failures = Packages::PackageFile.verification_failed
                                                  .where("verification_failure LIKE '%File is not checksummable%'")

   puts "Found #{checksummable_failures.count} package files with missing files"

   checksummable_failures.limit(5).each_with_index do |record, index|
     puts "Record #{index + 1}:"
     puts "  ID: #{record.id}"
     puts "  File Name: #{record.file_name}"
     puts "  Package ID: #{record.package_id}"
     puts "  Created: #{record.created_at}"
     puts "---"
   end
   ```

> [!warning]
> Assurez-vous de disposer d'une sauvegarde récente et fonctionnelle avant de supprimer des enregistrements de fichiers de packages. Coordonnez avec votre équipe pour confirmer que ces fichiers de packages peuvent être supprimés en toute sécurité.

Pour supprimer les fichiers de packages affectés :

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **principal**.
1. Supprimez les enregistrements affectés :

   ```ruby
   def destroy_packages_not_checksummable(dry_run: true)
     packages = Packages::PackageFile.verification_failed
                  .where("packages_package_file_states.verification_failure LIKE '%File is not checksummable%'")
     puts "Found #{packages.count} packages that failed verification with 'File is not checksummable'."

     if dry_run
       puts "DRY RUN - No changes made"
       packages.each { |p| puts "Would remove: ID #{p.id}, File: #{p.file_name}" }
       return
     end

     puts "Enter 'y' to continue: "
     prompt = STDIN.gets.chomp
     if prompt != 'y'
       puts "Exiting without action..."
       return
     end

     puts "Destroying all..."
     packages.destroy_all
     puts "Done!"
   end

   # Run in dry run mode first
   destroy_packages_not_checksummable(dry_run: true)
   ```

#### Artefacts de pipeline {#pipeline-artifacts}

**Diagnosis :**

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **principal**.
1. Vérifiez la présence d'artefacts avec des fichiers manquants :

   ```ruby
   failed_pipeline_artifacts = Ci::PipelineArtifact.verification_failed.where("verification_failure LIKE '%checksummable%'")

   failed_pipeline_artifacts.each do |registry|
     artifact = Ci::PipelineArtifact.find_by(id: registry.id)
     if artifact
       puts "Artifact ID: #{artifact.id}"
       puts "Pipeline ID: #{artifact.pipeline_id}"
       puts "Project ID: #{artifact.project_id}"
       puts "File exists: #{artifact.file.exists?}"
       puts "File path: #{artifact.file.path}"
     else
       puts "Artifact ID #{artifact.id} not found in database"
     end
     puts "---"
   end
   ```

**Resolution :**

> [!warning]
> Assurez-vous de disposer d'une sauvegarde récente et fonctionnelle avant de supprimer des enregistrements d'artefacts de pipeline. Coordonnez avec votre équipe pour confirmer que ces artefacts peuvent être supprimés en toute sécurité.

1. [Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) sur le site **principal**.
1. Supprimez les artefacts de pipeline avec des fichiers manquants :

   ```ruby
   def destroy_pipeline_artifacts_not_checksummable
     artifacts = Ci::PipelineArtifact.verification_failed.where("verification_failure like '%File is not checksummable%'")
     puts "Found #{artifacts.count} pipeline artifacts that failed verification with 'File is not checksummable'."
     puts "Enter 'y' to continue: "
     prompt = STDIN.gets.chomp
     if prompt != 'y'
       puts "Exiting without action..."
       return
     end

     puts "Destroying all..."
     artifacts.destroy_all
     puts "Done!"
   end

   destroy_pipeline_artifacts_not_checksummable
   ```

### Objets LFS désynchronisés en raison d'un délai d'expiration {#lfs-objects-out-of-sync-due-to-timeout}

Les objets LFS peuvent échouer à se synchroniser avec `Sync timed out after 28800` lorsque des fichiers volumineux dépassent le délai d'expiration de téléchargement de blob de 8 heures par défaut.

#### Augmenter le délai d'expiration de téléchargement de blob {#increase-the-blob-download-timeout}

Dans GitLab 18.10 et versions ultérieures, le délai d'expiration de téléchargement de blob est configurable par site Geo.

Pour augmenter le délai d'expiration de téléchargement de blob, remplacez `<secondary_id>` par l'ID de votre site secondaire et `<token>` par un jeton d'API administrateur :

```shell
curl --header "PRIVATE-TOKEN: <token>" \
  --request PUT \
  --data '{"blob_download_timeout": 43200}' \
  "https://gitlab.example.com/api/v4/geo_nodes/<secondary_id>"
```

Après avoir augmenté le délai d'expiration, attendez que Geo réessaie automatiquement, ou [relancez manuellement la réplication](#manually-retry-replication-or-verification).

#### Identifier et valider les objets LFS dont le délai a expiré {#identify-and-validate-timed-out-lfs-objects}

Si les objets LFS continuent d'échouer après l'augmentation du délai d'expiration, identifiez les objets affectés et confirmez que les fichiers existent sur le site principal.

1. Identifiez les objets affectés sur le site **secondaire** :

   ```ruby
   registries = Geo::LfsObjectRegistry.failed.where("last_sync_failure LIKE '%timed out%'")

   puts "Found #{registries.count} LFS objects that failed with a timeout"
   registries.each do |registry|
     lfs_object = LfsObject.find_by(id: registry.lfs_object_id)
     size_gb = lfs_object ? (lfs_object.size / 1024.0 / 1024.0 / 1024.0).round(2) : 'unknown'
     puts "  Registry ID: #{registry.id}, LFS Object ID: #{registry.lfs_object_id}, Size: #{size_gb} GB, Failure: #{registry.last_sync_failure}, Retries: #{registry.retry_count}"
   end
   ```

1. En utilisant les valeurs `lfs_object_id` de l'étape précédente, confirmez que les fichiers existent sur le site **principal** :

   ```ruby
   [lfs_object_id1, lfs_object_id2, lfs_object_id3].each do |id|
     lfs_object = LfsObject.find_by(id: id)

     if lfs_object.nil?
       puts "LFS Object ID: #{id} not found"
       next
     end

     puts "LFS Object ID: #{id}, Size: #{(lfs_object.size / 1024.0 / 1024.0 / 1024.0).round(2)} GB, File exists?: #{lfs_object.file.exists?}, Path: #{lfs_object.file.path}"
   end
   ```

#### Copier les fichiers du site principal vers le site secondaire {#copy-files-from-primary-to-secondary}

Si les fichiers existent sur le site principal mais sont absents du site secondaire, utilisez le chemin de l'étape précédente pour localiser le fichier :

- Pour le stockage d'objets : le chemin est la clé d'objet dans le bucket LFS configuré. Localisez et téléchargez le fichier depuis le bucket principal, puis téléversez-le vers la même clé dans le bucket secondaire.
- Pour le stockage local : le chemin est relatif à `/var/opt/gitlab/gitlab-rails/shared/lfs-objects/` sur le site principal. Copiez le fichier vers le même chemin relatif sur le site secondaire.

#### Marquer les objets LFS comme synchronisés {#mark-lfs-objects-as-synced}

Une fois les fichiers présents sur le site secondaire, marquez-les comme synchronisés et déclenchez la vérification :

```ruby
[lfs_object_id1, lfs_object_id2, lfs_object_id3].each do |lfs_object_id|
  begin
    registry = Geo::LfsObjectRegistry.find_by(lfs_object_id: lfs_object_id)

    if registry.nil?
      puts "Registry not found for LFS Object #{lfs_object_id}"
      next
    end

    registry.update!(
      state: 2,
      success: true,
      last_synced_at: Time.current,
      last_sync_failure: nil,
      retry_count: 0,
      retry_at: nil
    )
    registry.replicator.verify

    puts "LFS Object #{lfs_object_id}: marked as synced and verification triggered"
  rescue => e
    puts "Error processing LFS Object #{lfs_object_id}: #{e.message}"
  end
end
```

### Erreur : `Projects - Error during verification: Repository does not exist` {#error-projects---error-during-verification-repository-does-not-exist}

**Root Cause :** Des projets sans dépôts Git causant des échecs de vérification.

**Symptoms :**

- Les projets affichent des erreurs « Repository does not exist » lors de la vérification
- Signalement d'erreurs incorrectes dans l'interface Geo pour des projets qui n'ont légitimement aucun dépôt
- Tentatives de synchronisation gaspillées sur des dépôts inexistants

**Workaround :**

Créez des dépôts de projet sur le site principal lorsqu'ils n'existent pas :

```ruby
failed_projects = Project.verification_failed.where("verification_failure LIKE '%Repository does not exist%'")
puts "Found #{failed_projects.count} project repos with 'Repository does not exist' verification failure"
failed_projects.find_each do |p|
  puts "#{p.full_path} #{p.ensure_repository.inspect}"
end
```

### Erreur : `Expected(200) <=> Actual(403 Forbidden)` {#error-expected200--actual403-forbidden}

**Root Cause :** Absence de la permission `ListBucket` causant le retour de 403 au lieu de 404 par l'API S3.

**Symptoms :**

- Erreurs 403 dans les journaux avec les endpoints S3
- Requêtes HEAD échouant vers les buckets S3
- Échecs de synchronisation pour les types de données stockés dans le stockage d'objets

**Resolution :**

Cela nécessite l'intervention de l'équipe d'infrastructure pour ajouter la permission `ListBucket` à la politique IAM S3 utilisée par GitLab.

### Message : `Synchronization failed - Error syncing repository` {#message-synchronization-failed---error-syncing-repository}

> [!warning]
> Si de grands dépôts sont affectés par ce problème, leur resynchronisation peut prendre beaucoup de temps et causer une charge significative sur vos sites Geo, vos systèmes de stockage et réseau.

Le message d'erreur suivant indique une erreur de vérification de cohérence lors de la synchronisation du dépôt :

```plaintext
Synchronization failed - Error syncing repository [..] fatal: fsck error in packed object
```

Plusieurs problèmes peuvent déclencher cette erreur. Par exemple, des problèmes avec les adresses e-mail :

```plaintext
Error syncing repository: 13:fetch remote: "error: object <SHA>: badEmail: invalid author/committer line - bad email
   fatal: fsck error in packed object
   fatal: fetch-pack: invalid index-pack output
```

Un autre problème pouvant déclencher cette erreur est `object <SHA>: hasDotgit: contains '.git'`. Vérifiez les erreurs spécifiques car vous pourriez avoir plusieurs problèmes dans tous vos dépôts.

Une deuxième erreur de synchronisation peut également être causée par des problèmes de vérification de dépôt :

```plaintext
Error syncing repository: 13:Received RST_STREAM with error code 2.
```

Ces erreurs peuvent être observées en [synchronisant immédiatement tous les dépôts en échec](#sync-all-resources-of-one-component-that-failed-to-sync).

La suppression des objets malformés causant des erreurs de cohérence implique la réécriture de l'historique du dépôt, ce qui n'est généralement pas une option.

Pour ignorer ces vérifications de cohérence, reconfigurez Gitaly **on the secondary Geo sites** pour ignorer ces problèmes `git fsck`. L'exemple de configuration suivant :

- [Utilise la nouvelle structure de configuration](../../../../update/versions/gitlab_16_changes.md#gitaly-configuration-structure-change) requise à partir de GitLab 16.0.
- Ignore cinq échecs de vérification courants.

[La documentation Gitaly contient plus de détails](../../../gitaly/consistency_checks.md) sur les autres échecs de vérification Git et les versions antérieures de GitLab.

```ruby
gitaly['configuration'] = {
  git: {
    config: [
      { key: "fsck.duplicateEntries", value: "ignore" },
      { key: "fsck.badFilemode", value: "ignore" },
      { key: "fsck.missingEmail", value: "ignore" },
      { key: "fsck.badEmail", value: "ignore" },
      { key: "fsck.hasDotgit", value: "ignore" },
      { key: "fetch.fsck.duplicateEntries", value: "ignore" },
      { key: "fetch.fsck.badFilemode", value: "ignore" },
      { key: "fetch.fsck.missingEmail", value: "ignore" },
      { key: "fetch.fsck.badEmail", value: "ignore" },
      { key: "fetch.fsck.hasDotgit", value: "ignore" },
      { key: "receive.fsck.duplicateEntries", value: "ignore" },
      { key: "receive.fsck.badFilemode", value: "ignore" },
      { key: "receive.fsck.missingEmail", value: "ignore" },
      { key: "receive.fsck.badEmail", value: "ignore" },
      { key: "receive.fsck.hasDotgit", value: "ignore" },
    ],
  },
}
```

Une liste complète des erreurs `fsck` peut être trouvée dans la [documentation Git](https://git-scm.com/docs/git-fsck#_fsck_messages).

GitLab 16.1 et versions ultérieures [incluent une amélioration](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5879) qui pourrait résoudre certains de ces problèmes.

Le [ticket Gitaly 5625](https://gitlab.com/gitlab-org/gitaly/-/issues/5625) propose de s'assurer que Geo réplique les dépôts même si le dépôt source contient des commits problématiques.

### Erreur associée `does not appear to be a git repository` {#related-error-does-not-appear-to-be-a-git-repository}

Vous pouvez également obtenir le message d'erreur `Synchronization failed - Error syncing repository` accompagné des messages de journal suivants. Cette erreur indique que le remote Geo attendu n'est pas présent dans le fichier `.git/config` d'un dépôt sur le système de fichiers du site Geo secondaire :

```json
{
  "created": "@1603481145.084348757",
  "description": "Error received from peer unix:/var/opt/gitlab/gitaly/gitaly.socket",
  …
  "grpc_message": "exit status 128",
  "grpc_status": 13
}
{  …
  "grpc.request.fullMethod": "/gitaly.RemoteService/FindRemoteRootRef",
  "grpc.request.glProjectPath": "<namespace>/<project>",
  …
  "level": "error",
  "msg": "fatal: 'geo' does not appear to be a git repository
          fatal: Could not read from remote repository. …",
}
```

Pour résoudre ce problème :

1. Connectez-vous à l'interface web du site Geo secondaire.
1. Sauvegardez [le dossier `.git`](../../../repository_storage_paths.md#translate-hashed-storage-paths).
1. Facultatif. [Vérifiez ponctuellement](../../../logs/log_parsing.md#find-all-projects-affected-by-a-fatal-git-problem) quelques-uns de ces ID pour confirmer qu'ils correspondent bien à un projet avec des échecs de réplication Geo connus. Utilisez `fatal: 'geo'` comme terme `grep` et l'appel API suivant :

   ```shell
   curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<first_failed_geo_sync_ID>"
   ```

1. Accédez à la [console Rails](../../../operations/rails_console.md) et exécutez :

   ```ruby
   failed_project_registries = Geo::ProjectRepositoryRegistry.failed

   if failed_project_registries.any?
     puts "Found #{failed_project_registries.count} failed project repository registry entries:"

     failed_project_registries.each do |registry|
       puts "ID: #{registry.id}, Project ID: #{registry.project_id}, Last Sync Failure: '#{registry.last_sync_failure}'"
     end
   else
     puts "No failed project repository registry entries found."
   end
   ```

1. Exécutez les commandes suivantes pour lancer une nouvelle synchronisation pour chaque projet :

   ```ruby
   failed_project_registries.each do |registry|
     registry.replicator.sync
     puts "Sync initiated for registry ID: #{registry.id}, Project ID: #{registry.project_id}"
   end
   ```

## Échecs lors du remplissage {#failures-during-backfill}

Lors d'un [remplissage](../../_index.md#backfill), les échecs sont planifiés pour être réessayés à la fin de la file d'attente de remplissage, donc ces échecs ne se résolvent qu'**after** la fin du remplissage.

## Message : `unexpected disconnect while reading sideband packet` {#message-unexpected-disconnect-while-reading-sideband-packet}

Des conditions réseau instables peuvent faire échouer Gitaly lors de la récupération de données de grand dépôt depuis le site principal. Ces conditions peuvent entraîner cette erreur :

```plaintext
curl 18 transfer closed with outstanding read data remaining & fetch-pack:
unexpected disconnect while reading sideband packet
```

Cette erreur est plus susceptible de se produire si un dépôt doit être répliqué depuis zéro entre les sites.

Geo réessaie plusieurs fois, mais si la transmission est systématiquement interrompue par des instabilités réseau, une méthode alternative comme `rsync` peut être utilisée pour contourner `git` et créer la copie initiale de tout dépôt qui ne parvient pas à être répliqué par Geo.

Nous recommandons de transférer chaque dépôt en échec individuellement et de vérifier la cohérence après chaque transfert. Suivez les [instructions `rsync` vers un autre serveur](../../../operations/moving_repositories.md#use-rsync-to-another-server) pour transférer chaque dépôt affecté du site principal vers le site secondaire.

## Trouver les échecs de vérification de dépôt sur un site Geo secondaire {#find-repository-check-failures-in-a-geo-secondary-site}

> [!note]
> Tous les types de données de dépôts ont été migrés vers le Geo Self-Service Framework dans GitLab 16.3. Il existe un [ticket pour réimplémenter cette fonctionnalité dans le Geo Self-Service Framework](https://gitlab.com/gitlab-org/gitlab/-/issues/426659).

Pour GitLab 16.2 et versions antérieures :

Lorsqu'elles sont [activées pour tous les projets](../../../repository_checks.md#enable-repository-checks-for-all-projects), les [vérifications de dépôt](../../../repository_checks.md) sont également effectuées sur les sites Geo secondaires. Les métadonnées sont stockées dans la base de données de suivi Geo.

Les échecs de vérification de dépôt sur un site Geo secondaire n'impliquent pas nécessairement un problème de réplication. Voici une approche générale pour résoudre ces échecs.

1. Trouvez les dépôts affectés comme mentionné ci-dessous, ainsi que leurs [erreurs enregistrées](../../../repository_checks.md#what-to-do-if-a-check-failed).
1. Essayez de diagnostiquer les erreurs `git fsck` spécifiques. La gamme des erreurs possibles est large, essayez de les rechercher dans des moteurs de recherche.
1. Testez les fonctions typiques des dépôts affectés. Effectuez un pull depuis le site secondaire et affichez les fichiers.
1. Vérifiez si la copie du dépôt sur le site principal présente une erreur `git fsck` identique. Si vous planifiez un basculement, envisagez de prioriser le fait que le site secondaire dispose des mêmes informations que le site principal. Assurez-vous de disposer d'une sauvegarde du site principal et suivez les [directives de basculement planifié](../../disaster_recovery/planned_failover.md).
1. Poussez vers le site principal et vérifiez si la modification est répliquée vers le site secondaire.
1. Si la réplication ne fonctionne pas automatiquement, essayez de synchroniser manuellement le dépôt.

[Démarrez une session de console Rails](../../../operations/rails_console.md#starting-a-rails-console-session) pour effectuer les étapes de dépannage de base suivantes.

> [!warning]
> Les commandes qui modifient des données peuvent causer des dommages si elles ne sont pas exécutées correctement ou dans les bonnes conditions. Exécutez toujours les commandes dans un environnement de test d'abord et ayez une instance de sauvegarde prête à restaurer.

### Obtenir le nombre de dépôts ayant échoué à la vérification de dépôt {#get-the-number-of-repositories-that-failed-the-repository-check}

```ruby
Geo::ProjectRegistry.where(last_repository_check_failed: true).count
```

### Trouver les dépôts ayant échoué à la vérification de dépôt {#find-the-repositories-that-failed-the-repository-check}

```ruby
Geo::ProjectRegistry.where(last_repository_check_failed: true)
```

## Supprimer définitivement un dépôt du cluster Gitaly et resynchroniser {#hard-delete-a-repository-from-gitaly-cluster-and-resync}

> [!warning]
> Cette procédure est risquée et radicale. Utilisez-la en dernier recours uniquement lorsque les autres méthodes de dépannage ont échoué. Cette procédure entraîne une perte de données temporaire jusqu'à ce que le dépôt soit resynchronisé.

Cette procédure supprime le dépôt du cluster Gitaly du site secondaire et le resynchronise. Envisagez de l'utiliser uniquement si vous comprenez les risques et si toutes ces conditions sont remplies :

- `git clone` fonctionne pour un dépôt sur le site principal.
- `p.replicator.sync_repository` (où `p` est une instance de modèle de projet) consigne une erreur Gitaly sur un site secondaire.
- Le dépannage standard n'a pas résolu le problème.

Prérequis :

- Assurez-vous d'avoir un accès administratif à la fois à la console Rails du site secondaire et aux nœuds Praefect.
- Vérifiez que le dépôt est accessible et fonctionne correctement sur le site principal.
- Prévoyez un plan de secours au cas où vous devriez annuler cette procédure.

Pour ce faire :

1. Connectez-vous à la console Rails sur le site secondaire.
1. Instanciez un modèle de projet et enregistrez-le dans une variable `p`, en utilisant l'une de ces options :

   - Si vous connaissez l'ID du projet concerné (par exemple, `60087`) :

     ```ruby
     p = Project.find(60087)
     ```

   - Si vous connaissez le chemin du projet concerné dans GitLab (par exemple, `my-group/my-project`) :

     ```ruby
     p = Project.find_by_full_path('my-group/my-project')
     ```

1. Affichez le stockage virtuel du dépôt Git du projet et notez-le pour plus tard :

   ```ruby
   p.repository.storage
   ```

   Exemple de sortie :

   ```ruby
   irb(main):002:0> p.repository.storage
   => "default"
   ```

1. Affichez le chemin relatif du dépôt Git du projet et notez-le pour plus tard :

   ```ruby
   p.repository.disk_path + '.git'
   ```

   Exemple de sortie :

   ```ruby
   irb(main):003:0> p.repository.disk_path + '.git'
   => "@hashed/66/b2/66b2fc8562b3432399acc2d0108fcd2782b32bd31d59226c7a03a20b32c76ee8.git"
   ```

1. Connectez-vous en SSH à un nœud Praefect sur le site secondaire.
1. Suivez la procédure pour [Supprimer manuellement des dépôts du cluster Gitaly](../../../gitaly/praefect/recovery.md#manually-remove-repositories), en utilisant le stockage virtuel et le chemin relatif que vous avez notés lors des étapes précédentes.

   Le dépôt Git sur le site secondaire est maintenant supprimé.

1. Dans la console Rails, avant de resynchroniser, définissez un ID de corrélation. Cet ID vous aide à rechercher tous les journaux liés aux commandes que vous exécutez dans cette session :

   ```ruby
   Gitlab::ApplicationContext.push({})
   ```

   Exemple de sortie :

   ```ruby
   [2] pry(main)> Gitlab::ApplicationContext.push({})
   => #<Labkit::Context:0x0000000122aa4060 @data={"correlation_id"=>"53da64ae800bd4794a2b61ab1c80b028"}>
   ```

1. Synchronisez le dépôt Git du projet :

   ```ruby
   p.replicator.sync_repository
   ```

Le dépôt Git devrait maintenant être resynchronisé depuis le site principal vers le site secondaire. Surveillez le processus de synchronisation via l'interface d'administration Geo, ou en vérifiant le statut de synchronisation du dépôt dans la console Rails.

## Considérations relatives à l'infrastructure et aux performances {#infrastructure-and-performance-considerations}

Certains problèmes de synchronisation sont causés par des problèmes au niveau de l'infrastructure ou des contraintes de performance.

### Problèmes de concurrence élevée {#high-concurrency-issues}

Une concurrence excessive de vérification Geo peut surcharger la base de données et entraîner des échecs de synchronisation.

**Symptoms :**

- Délais d'expiration des connexions à la base de données
- Utilisation élevée du processeur sur les serveurs de base de données
- Progression lente de la synchronisation malgré une infrastructure saine

**Diagnosis and Resolution :**

Réduisez les paramètres de concurrence sur le site **principal** via l'[interface utilisateur](../tuning.md#changing-the-syncverification-concurrency-values)

## Mises à jour manuelles du statut de synchronisation {#manual-sync-status-updates}

Dans certains cas, vous devrez peut-être marquer manuellement un type d'objet comme synchronisé après avoir résolu les problèmes sous-jacents. Ce scénario se produit lorsque le problème ne peut être résolu que par un téléchargement manuel du fichier vers le compartiment d'objets sur le site secondaire. Normalement, cette opération ne devrait pas être nécessaire, mais elle peut se produire en raison de bogues de version. Ce qui suit montre comment marquer ces types d'objets téléchargés manuellement (dans ce cas, des téléchargements) comme synchronisés.

> [!warning]
> Marquez les objets comme synchronisés uniquement si vous avez vérifié que les fichiers sont réellement présents et accessibles sur le site secondaire.

```ruby
def mark_upload_synced(upload_id)
  upload = Upload.find(upload_id)
  registry = upload.replicator.registry
  registry.start
  registry.synced!
  puts "Marked upload #{upload_id} as synced"
end

# Mark specific uploads as synced
upload_ids = [107221, 107320] # Replace with actual IDs
upload_ids.each { |id| mark_upload_synced(id) }
```

## Réinitialisation de la réplication du site **secondaire** Geo {#resetting-geo-secondary-site-replication}

Si vous obtenez un site **secondaire** dans un état défaillant et souhaitez réinitialiser l'état de réplication pour recommencer de zéro, voici quelques étapes qui peuvent vous aider :

1. Arrêtez Sidekiq et le curseur de journal Geo.

   Il est possible de faire arrêter Sidekiq correctement, en l'empêchant de recevoir de nouveaux jobs et en attendant que les jobs en cours se terminent.

   Vous devez envoyer un signal d'arrêt **SIGTSTP** pour la première phase, puis un signal **SIGTERM** lorsque tous les jobs sont terminés. Sinon, utilisez simplement les commandes `gitlab-ctl stop`.

   ```shell
   gitlab-ctl status sidekiq
   # run: sidekiq: (pid 10180) <- this is the PID you will use
   kill -TSTP 10180 # change to the correct PID

   gitlab-ctl stop sidekiq
   gitlab-ctl stop geo-logcursor
   ```

   Vous pouvez surveiller les [journaux Sidekiq](../../../logs/_index.md#sidekiq-logs) pour savoir quand le traitement des jobs Sidekiq est terminé :

   ```shell
   gitlab-ctl tail sidekiq
   ```

1. Effacez les données de Gitaly et du cluster Gitaly (Praefect).

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```shell
   mv /var/opt/gitlab/git-data/repositories /var/opt/gitlab/git-data/repositories.old
   sudo gitlab-ctl reconfigure
   ```

   {{< /tab >}}

   {{< tab title="Gitaly Cluster (Praefect)" >}}

   1. Facultatif. Désactivez l'équilibreur de charge interne de Praefect.
   1. Arrêtez Praefect sur chaque serveur Praefect :

      ```shell
      sudo gitlab-ctl stop praefect
      ```

   1. Réinitialisez la base de données Praefect :

      ```shell
      sudo /opt/gitlab/embedded/bin/psql -U praefect -d template1 -h localhost -c "DROP DATABASE praefect_production WITH (FORCE);"
      sudo /opt/gitlab/embedded/bin/psql -U praefect -d template1 -h localhost -c "CREATE DATABASE praefect_production WITH OWNER=praefect ENCODING=UTF8;"
      ```

   1. Renommez/supprimez les données du dépôt sur chaque nœud Gitaly :

      ```shell
      sudo mv /var/opt/gitlab/git-data/repositories /var/opt/gitlab/git-data/repositories.old
      sudo gitlab-ctl reconfigure
      ```

   1. Sur votre nœud de déploiement Praefect, exécutez la reconfiguration pour configurer la base de données :

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. Démarrez Praefect sur chaque serveur Praefect :

      ```shell
      sudo gitlab-ctl start praefect
      ```

   1. Facultatif. Si vous l'avez désactivé, réactivez l'équilibreur de charge interne de Praefect.

   {{< /tab >}}

   {{< /tabs >}}

   > [!note]
   > Vous pouvez supprimer le répertoire `/var/opt/gitlab/git-data/repositories.old` à l'avenir, dès que vous avez confirmé que vous n'en avez plus besoin, afin d'économiser de l'espace disque.

1. Facultatif. Renommez les autres dossiers de données et créez-en de nouveaux.

   > [!warning]
   > Il se peut que vous ayez encore des fichiers sur le site **secondaire** qui ont été supprimés du site **principal**, mais cette suppression n'a pas encore été prise en compte. Si vous ignorez cette étape, ces fichiers ne seront pas supprimés du site Geo **secondaire**.

   Tout contenu téléchargé (comme les pièces jointes, les avatars ou les objets LFS) est stocké dans un sous-dossier dans l'un de ces chemins :

   - `/var/opt/gitlab/gitlab-rails/shared`
   - `/var/opt/gitlab/gitlab-rails/uploads`

   Pour tous les renommer :

   ```shell
   gitlab-ctl stop

   mv /var/opt/gitlab/gitlab-rails/shared /var/opt/gitlab/gitlab-rails/shared.old
   mkdir -p /var/opt/gitlab/gitlab-rails/shared

   mv /var/opt/gitlab/gitlab-rails/uploads /var/opt/gitlab/gitlab-rails/uploads.old
   mkdir -p /var/opt/gitlab/gitlab-rails/uploads

   gitlab-ctl start postgresql
   gitlab-ctl start geo-postgresql
   ```

   Reconfigurez pour recréer les dossiers et vérifier que les permissions et la propriété sont correctes :

   ```shell
   gitlab-ctl reconfigure
   ```

1. Réinitialisez la base de données de suivi.

   > [!warning]
   > Si vous avez ignoré l'étape 3 facultative, assurez-vous que les services `geo-postgresql` et `postgresql` sont en cours d'exécution.

   ```shell
   gitlab-rake db:drop:geo DISABLE_DATABASE_ENVIRONMENT_CHECK=1   # on a secondary app node
   gitlab-ctl reconfigure     # on the tracking database node
   gitlab-rake db:migrate:geo # on a secondary app node
   ```

1. Redémarrez les services précédemment arrêtés.

   ```shell
   gitlab-ctl start
   ```
