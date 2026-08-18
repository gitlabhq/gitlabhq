---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurer Elasticsearch pour utiliser la recherche avancée dans GitLab.
title: Elasticsearch
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Cette page décrit comment activer la recherche avancée. Une fois activée, la recherche avancée offre des temps de réponse plus rapides et des [fonctionnalités de recherche améliorées](../../user/search/advanced_search.md).

Pour activer la recherche avancée, vous devez :

1. [Installer un cluster Elasticsearch ou AWS OpenSearch](#install-an-elasticsearch-or-aws-opensearch-cluster).
1. [Activer la recherche avancée](#enable-advanced-search).

> [!note]
> La recherche avancée stocke tous les projets dans les mêmes indices Elasticsearch. Cependant, les projets privés n'apparaissent dans les résultats de recherche qu'aux utilisateurs qui y ont accès.

## Glossaire Elasticsearch {#elasticsearch-glossary}

Ce glossaire fournit des définitions pour les termes liés à Elasticsearch.

- **Lucene** : une bibliothèque de recherche en texte intégral écrite en Java.
- **Near real time (NRT)** : désigne la légère latence entre le moment d'indexation d'un document et le moment où il devient consultable.
- **Cluster** : un ensemble d'un ou plusieurs nœuds qui travaillent ensemble pour stocker toutes les données, offrant des capacités d'indexation et de recherche.
- **Node** : un serveur unique fonctionnant dans le cadre d'un cluster.
- **Indexer** : un ensemble de documents présentant des caractéristiques relativement similaires.
- **Document** : une unité de base d'informations pouvant être indexée.
- **Shards** : subdivisions entièrement fonctionnelles et indépendantes des indices. Chaque shard est en réalité un index Lucene.
- **Replicas** : mécanismes de basculement qui dupliquent les indices.

## Installer un cluster Elasticsearch ou AWS OpenSearch {#install-an-elasticsearch-or-aws-opensearch-cluster}

Elasticsearch et AWS OpenSearch ne sont pas inclus dans le paquet Linux. Vous pouvez installer un cluster de recherche vous-même ou utiliser une offre hébergée dans le cloud telle que :

- [Elasticsearch Service](https://www.elastic.co/elasticsearch/service) (disponible sur Amazon Web Services, Google Cloud Platform et Microsoft Azure)
- [Amazon OpenSearch Service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/gsg.html)

Vous devriez installer le cluster de recherche sur un serveur distinct. L'exécution du cluster de recherche sur le même serveur que GitLab peut entraîner des problèmes de performance.

Pour un cluster de recherche avec un seul nœud, le statut du cluster est toujours jaune car le shard primaire est alloué. Le cluster ne peut pas attribuer des shards répliques au même nœud que les shards primaires.

> [!note]
> Avant d'utiliser un nouveau cluster Elasticsearch en production, consultez la [configuration Elasticsearch importante](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html).

### Compatibilité des versions {#version-compatibility}

#### Elasticsearch {#elasticsearch}

{{< history >}}

- La prise en charge d'Elasticsearch 6.8 a été [supprimée](https://gitlab.com/gitlab-org/gitlab/-/issues/350275) dans GitLab 15.0.

{{< /history >}}

> [!warning]
> La prise en charge d'Elasticsearch 7.x a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/issues/583544) dans GitLab 18.10 et sa suppression est prévue dans la version 20.0.

La recherche avancée est compatible avec les versions suivantes d'Elasticsearch.

| Version de GitLab  | Version d'Elasticsearch |
|-----------------|-----------------------|
| 19.1 et versions ultérieures  | 8.x et 9.x           |
| 15.0 à 19.0    | 7.x et 8.x           |
| 14.0 à 14.10   | 6.8 à 7.x            |

GitLab.com utilise Elasticsearch 9.x. Utilisez Elasticsearch 9.x pour des performances optimales, les dernières fonctionnalités et la compatibilité ascendante.

La recherche avancée suit la [politique de fin de vie d'Elasticsearch](https://www.elastic.co/support/eol).

#### OpenSearch {#opensearch}

La recherche avancée est compatible avec les versions suivantes d'OpenSearch.

| Version de GitLab   | Version d'OpenSearch |
|------------------|--------------------|
| 18.1 et versions ultérieures   | 1.x et versions ultérieures      |
| 17.6.3 à 18.0   | 1.x et 2.x        |
| 15.5.3 à 17.6.2 | 1.x, 2.0 à 2.17   |
| 15.0 à 15.5.2   | 1.x                |

La recherche avancée suit la [politique de maintenance d'OpenSearch](https://opensearch.org/releases/).

### Configuration requise {#system-requirements}

Elasticsearch et AWS OpenSearch nécessitent davantage de ressources que les [exigences d'installation de GitLab](../../install/requirements.md).

Les besoins en mémoire, en CPU et en stockage dépendent de la quantité de données que vous indexez dans le cluster. Les clusters Elasticsearch très sollicités peuvent nécessiter davantage de ressources. La tâche Rake [`estimate_cluster_size`](#gitlab-advanced-search-rake-tasks) utilise la taille totale du dépôt pour estimer les besoins en stockage de la recherche avancée.

### Exigences d'accès {#access-requirements}

GitLab prend en charge les [méthodes d'authentification HTTP et basées sur les rôles](#advanced-search-configuration) selon vos besoins et le service backend que vous utilisez.

#### Contrôle d'accès basé sur les rôles pour Elasticsearch {#role-based-access-control-for-elasticsearch}

Elasticsearch peut offrir un contrôle d'accès basé sur les rôles pour renforcer la sécurité d'un cluster. Pour accéder au cluster Elasticsearch et y effectuer des opérations, le `Username` configuré dans la zone **Admin** doit disposer de rôles accordant les privilèges suivants. Le `Username` envoie des requêtes de GitLab au cluster de recherche.

Pour plus d'informations, consultez [Contrôle d'accès basé sur les rôles Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/authorization.html#roles) et [Privilèges de sécurité Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-privileges.html).

```json
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["gitlab-*"],
      "privileges": [
        "create_index",
        "delete_index",
        "view_index_metadata",
        "read",
        "manage",
        "write"
      ]
    }
  ]
}
```

#### Contrôle d'accès pour AWS OpenSearch Service {#access-control-for-aws-opensearch-service}

Prérequis :

- Vous devez disposer d'un [rôle lié au service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/slr.html) dans votre compte AWS nommé `AWSServiceRoleForAmazonOpenSearchService` lors de la création de domaines OpenSearch.
- La politique d'accès au domaine pour AWS OpenSearch doit autoriser les actions `es:ESHttp*`.

`AWSServiceRoleForAmazonOpenSearchService` est utilisé par **l'ensemble** des domaines OpenSearch. Dans la plupart des cas, ce rôle est créé automatiquement lorsque vous utilisez la console de gestion AWS pour créer le premier domaine OpenSearch. Pour créer un rôle lié au service manuellement, consultez la [documentation AWS](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/slr-aos.html#create-slr).

AWS OpenSearch Service comporte trois couches de sécurité principales :

- [Réseau](#network)
- [Politique d'accès au domaine](#domain-access-policy)
- [Contrôle d'accès précis](#fine-grained-access-control)

##### Réseau {#network}

Avec cette couche de sécurité, vous pouvez sélectionner **Accès public** lors de la création d'un domaine pour que les requêtes de n'importe quel client puissent atteindre le point de terminaison du domaine. Si vous sélectionnez **Accès VPC**, les clients doivent se connecter au VPC pour que les requêtes atteignent le point de terminaison.

Pour plus d'informations, consultez la [documentation AWS](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-access-policies).

##### Politique d'accès au domaine {#domain-access-policy}

GitLab prend en charge les méthodes suivantes de contrôle d'accès au domaine pour AWS OpenSearch :

- [**Politiques d'accès basées sur les ressources (domaine)**](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html#ac-types-resource) : le domaine AWS OpenSearch est configuré avec une politique IAM
- [**Politiques basées sur l'identité**](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html#ac-types-identity) : les clients utilisent des principaux IAM avec des politiques pour configurer l'accès

###### Exemples de politiques basées sur les ressources {#resource-based-policy-examples}

Voici un exemple de politique d'accès basée sur les ressources (domaine) où les actions `es:ESHttp*` sont autorisées :

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "es:ESHttp*"
      ],
      "Resource": "arn:aws:es:us-west-1:987654321098:domain/test-domain/*"
    }
  ]
}
```

Voici un exemple de politique d'accès basée sur les ressources (domaine) où les actions `es:ESHttp*` sont autorisées uniquement pour un principal IAM spécifique :

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::123456789012:user/test-user"
        ]
      },
      "Action": [
        "es:ESHttp*"
      ],
      "Resource": "arn:aws:es:us-west-1:987654321098:domain/test-domain/*"
    }
  ]
}
```

> [!note]
> Le `aws_role_arn` doit être fourni si vous utilisez [AWS `AssumeRole`](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html) entre différents comptes. L'ARN doit correspondre au rôle disposant des autorisations pour accéder à OpenSearch.

###### Exemples de politiques basées sur l'identité {#identity-based-policy-examples}

Voici un exemple de politique d'accès basée sur l'identité associée à un principal IAM où les actions `es:ESHttp*` sont autorisées :

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "es:ESHttp*",
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
```

##### Contrôle d'accès précis {#fine-grained-access-control}

Lorsque vous activez le contrôle d'accès précis, vous devez définir un [utilisateur principal](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-master-user) de l'une des façons suivantes :

- [Définir un ARN IAM comme utilisateur principal](#set-an-iam-arn-as-a-master-user).
- [Créer un utilisateur principal](#create-a-master-user).

###### Définir un ARN IAM comme utilisateur principal {#set-an-iam-arn-as-a-master-user}

Si vous utilisez un principal IAM comme utilisateur principal, toutes les requêtes vers le cluster doivent être signées avec AWS Signature Version 4. Vous pouvez également spécifier un ARN IAM, qui est le rôle IAM que vous avez attribué à votre instance EC2. Pour plus d'informations, consultez la [documentation AWS](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-master-user).

Prérequis :

- Disposer d'un accès administrateur.

Pour définir un ARN IAM comme utilisateur principal, vous devez utiliser AWS OpenSearch Service avec des identifiants IAM sur votre instance GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Recherche avancée**.
1. Dans la section **Identifiants IAM AWS OpenSearch** :
   1. Cochez la case **Utiliser le service AWS OpenSearch avec les identifiants IAM**.
   1. Dans **Région AWS**, saisissez la région AWS où se trouve votre domaine OpenSearch (par exemple, `us-east-1`).
   1. Dans **AWS access key** et **AWS secret access key**, saisissez vos clés d'accès pour l'authentification.

      > [!note]
      > Les déploiements GitLab s'exécutant directement sur des instances EC2 (pas dans des conteneurs) n'ont pas à saisir de clés d'accès. Votre instance GitLab obtient ces clés automatiquement depuis le [service de métadonnées d'instance AWS (IMDS)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html).

1. Sélectionnez **Enregistrer les modifications**.

###### Créer un utilisateur principal {#create-a-master-user}

Si vous créez un utilisateur principal dans la base de données d'utilisateurs interne, vous pouvez utiliser l'authentification HTTP de base pour envoyer des requêtes au cluster. Pour plus d'informations, consultez la [documentation AWS](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-master-user).

Prérequis :

- Disposer d'un accès administrateur.

Pour créer un utilisateur principal, vous devez configurer l'URL du domaine OpenSearch ainsi que le nom d'utilisateur et le mot de passe du principal sur votre instance GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Recherche avancée**.
1. Dans l'**URL du domaine OpenSearch**, saisissez l'URL du point de terminaison du domaine OpenSearch.
1. Dans **Nom d'utilisateur**, saisissez le nom d'utilisateur principal.
1. Dans **Mot de passe**, saisissez le mot de passe principal.
1. Sélectionnez **Enregistrer les modifications**.

### Mettre à niveau vers une nouvelle version d'Elasticsearch {#upgrade-to-a-new-elasticsearch-version}

{{< history >}}

- La prise en charge d'Elasticsearch 6.8 a été [supprimée](https://gitlab.com/gitlab-org/gitlab/-/issues/350275) dans GitLab 15.0.

{{< /history >}}

Prérequis :

- [Désactivez la recherche avancée](#disable-search-with-advanced-search) pour que les recherches n'échouent pas avec une erreur `HTTP 500`.
- [Suspendez l'indexation](#pause-indexing) pour que les modifications puissent toujours être suivies.

Lorsque vous mettez à niveau Elasticsearch vers une nouvelle version mineure ou majeure, vous n'avez pas à modifier la configuration GitLab. Lorsque le cluster Elasticsearch est entièrement mis à niveau et actif :

1. Validez la connectivité du cluster, l'indexation et les opérations de recherche :

   ```shell
   sudo gitlab-rake gitlab:elastic:index_and_search_validation
   ```

1. [Reprenez l'indexation](#resume-indexing).
1. Facultatif. [Vérifiez le statut d'indexation](#check-indexing-status). Pour obtenir des résultats de recherche corrects, assurez-vous que l'indexation est complète, surtout si votre instance Elasticsearch a été hors ligne pendant un certain temps.
1. [Activez la recherche avancée](#enable-search-with-advanced-search).

## Indexeur de dépôt Elasticsearch {#elasticsearch-repository-indexer}

Pour indexer les données du dépôt Git, GitLab utilise [`gitlab-elasticsearch-indexer`](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer). Pour les installations auto-compilées, consultez [installer l'indexeur](#install-the-indexer).

### Installer l'indexeur {#install-the-indexer}

Vous installez d'abord quelques dépendances, puis vous compilez et installez l'indexeur lui-même.

#### Installer les dépendances {#install-dependencies}

Ce projet repose sur [International Components for Unicode](https://icu.unicode.org/) (ICU) pour l'encodage du texte. Assurez-vous que les paquets de développement pour votre plateforme sont installés avant d'exécuter `make`.

##### Debian / Ubuntu {#debian--ubuntu}

Pour installer sur Debian ou Ubuntu, exécutez :

```shell
sudo apt install libicu-dev
```

##### CentOS / RHEL {#centos--rhel}

Pour installer sur CentOS ou RHEL, exécutez :

```shell
sudo yum install libicu-devel
```

##### macOS {#macos}

> [!note]
> Vous devez d'abord [installer Homebrew](https://brew.sh/).

Pour installer sur macOS, exécutez :

```shell
brew install icu4c
export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"
```

#### Compiler et installer {#build-and-install}

Pour compiler et installer l'indexeur, exécutez :

```shell
indexer_path=/home/git/gitlab-elasticsearch-indexer

# Run the installation task for gitlab-elasticsearch-indexer:
sudo -u git -H bundle exec rake gitlab:indexer:install[$indexer_path] RAILS_ENV=production
cd $indexer_path && sudo make install
```

`gitlab-elasticsearch-indexer` est installé dans `/usr/local/bin`.

Vous pouvez modifier le chemin d'installation avec la variable d'environnement `PREFIX`. N'oubliez pas de passer le feature flag `-E` à `sudo` si vous le faites.

Exemple :

```shell
PREFIX=/usr sudo -E make install
```

Après l'installation, assurez-vous d'[activer Elasticsearch](#enable-advanced-search).

> [!note]
> Si vous voyez une erreur telle que `Permission denied - /home/git/gitlab-elasticsearch-indexer/` lors de l'indexation, vous devrez peut-être définir le paramètre `production -> elasticsearch -> indexer_path` dans votre fichier `gitlab.yml` sur `/usr/local/bin/gitlab-elasticsearch-indexer`, qui est l'emplacement où le binaire est installé.

### Afficher les erreurs d'indexation {#view-indexing-errors}

Les erreurs de l'[indexeur GitLab Elasticsearch](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer) sont signalées dans le fichier [`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog) et dans le fichier [`sidekiq.log`](../../administration/logs/_index.md#sidekiqlog) avec un `json.exception.class` de `Gitlab::Elastic::Indexer::Error`. Ces erreurs peuvent survenir lors de l'indexation des données du dépôt Git.

## Activer la recherche avancée {#enable-advanced-search}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.
- Configurez le [nombre de shards par index](#number-of-elasticsearch-shards).
- Configurez le [nombre de répliques par index](#number-of-elasticsearch-replicas).
- Facultatif. Préparez-vous à [l'indexation de grandes instances](#index-large-instances-efficiently).

Pour activer la recherche avancée :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Configurez les [paramètres de recherche avancée](#advanced-search-configuration) pour votre cluster Elasticsearch. Ne cochez pas encore la case **Recherche avancée**.
1. [Indexez l'instance](#index-the-instance).
1. Facultatif. [Vérifiez le statut d'indexation](#check-indexing-status).
1. Une fois l'indexation terminée, cochez la case **Recherche avancée**, puis sélectionnez **Sauvegarder les modifications**.

> [!note]
> Lorsque votre cluster Elasticsearch est indisponible alors qu'Elasticsearch est activé, vous pourriez rencontrer des problèmes lors de la mise à jour de documents tels que des tickets, car votre instance met en file d'attente un job pour indexer la modification, mais ne peut pas trouver un cluster Elasticsearch valide.

Pour les instances GitLab contenant plus de 50 Go de données de dépôt, consultez [Indexer les grandes instances efficacement](#index-large-instances-efficiently).

### Indexer l'instance {#index-the-instance}

#### Depuis l'interface utilisateur {#from-the-user-interface}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/271532) dans GitLab 17.3.

{{< /history >}}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Vous pouvez effectuer une indexation initiale ou recréer un index depuis l'interface utilisateur.

Pour activer la recherche avancée et indexer l'instance depuis l'interface utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Cochez la case **Activer l'indexation pour la recherche avancée**, puis sélectionnez **Sauvegarder les modifications**.
1. Sélectionnez **Indexer l'instance**.

#### Avec une tâche Rake {#with-a-rake-task}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour indexer l'intégralité de l'instance, utilisez les tâches Rake suivantes :

```shell
# WARNING: This task deletes all existing indices
# For installations that use the Linux package
sudo gitlab-rake gitlab:elastic:index

# WARNING: This task deletes all existing indices
# For self-compiled installations
bundle exec rake gitlab:elastic:index RAILS_ENV=production
```

Pour indexer des données spécifiques, utilisez les tâches Rake suivantes :

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:elastic:index_work_items
sudo gitlab-rake gitlab:elastic:index_group_wikis
sudo gitlab-rake gitlab:elastic:index_namespaces
sudo gitlab-rake gitlab:elastic:index_projects
sudo gitlab-rake gitlab:elastic:index_snippets
sudo gitlab-rake gitlab:elastic:index_users

# For self-compiled installations
bundle exec rake gitlab:elastic:index_work_items RAILS_ENV=production
bundle exec rake gitlab:elastic:index_group_wikis RAILS_ENV=production
bundle exec rake gitlab:elastic:index_namespaces RAILS_ENV=production
bundle exec rake gitlab:elastic:index_projects RAILS_ENV=production
bundle exec rake gitlab:elastic:index_snippets RAILS_ENV=production
bundle exec rake gitlab:elastic:index_users RAILS_ENV=production
```

### Vérifier le statut d'indexation {#check-indexing-status}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour vérifier le statut d'indexation :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **État de l'indexation de la recherche avancée**.

#### Surveiller le statut des jobs en arrière-plan {#monitor-the-status-of-background-jobs}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour surveiller la progression de l'indexation, vous pouvez également vérifier le statut des jobs en arrière-plan :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Jobs en arrière-plan**.
1. Sur le tableau de bord Sidekiq, sélectionnez **Occupé(e)** et observez ces jobs d'indexation :
   - `Search::Elastic::CommitIndexerWorker` pour le code et les commits.
   - `ElasticWikiIndexerWorker` pour les données wiki.

### Activer la recherche avancée {#enable-search-with-advanced-search}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour activer la recherche avancée dans GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Cochez la case **Recherche avancée**.
1. Sélectionnez **Enregistrer les modifications**.

### Activer la recherche de code avec la recherche avancée {#enable-code-search-with-advanced-search}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour activer la recherche de code avec la recherche avancée dans GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Cochez la case **Recherche de code à l'aide de la recherche avancée**.
1. Sélectionnez **Enregistrer les modifications**.

### Configuration de la recherche avancée {#advanced-search-configuration}

Les paramètres Elasticsearch suivants sont disponibles :

| Paramètre                                                   | Description |
|-------------------------------------------------------------|-------------|
| **Activer l'indexation pour la recherche avancée**                    | Active ou désactive l'indexation et crée un index vide s'il n'en existe pas encore. Vous pouvez, par exemple, activer l'indexation tout en désactivant la recherche pour laisser le temps à l'index d'être entièrement complété. Par ailleurs, gardez à l'esprit que cette option n'a aucun impact sur les données existantes ; elle active/désactive uniquement l'indexeur en arrière-plan qui suit les modifications des données et s'assure que les nouvelles données sont indexées. |
| **Suspendre l'indexation pour la recherche avancée**                      | Suspend l'indexation de la recherche avancée. Utile pour la migration/réindexation d'un cluster. Toutes les modifications sont toujours suivies, mais elles ne sont pas validées dans l'index avant la reprise. |
| **Recherche avancée**                             | Active ou désactive les fonctionnalités de recherche avancée dans la recherche et la [gestion avancée des vulnérabilités](../../user/application_security/vulnerability_report/_index.md#advanced-vulnerability-management). |
| **Recherche de code à l'aide de la recherche avancée**                        | Active ou désactive la recherche de code avec la recherche avancée. Lorsque ce paramètre est désactivé, tout le code est supprimé de votre instance Elasticsearch. Pour réactiver ce paramètre, réindexez entièrement votre code. Si la recherche de code exacte est activée, vous devriez désactiver ce paramètre pour économiser des ressources. |
| **Remettre en file d'attente les workers d'indexation**                                | Active la remise en file d'attente automatique des workers d'indexation. Cela améliore le débit d'indexation non liée au code en mettant en file d'attente des jobs Sidekiq jusqu'à ce que tous les documents soient traités. La remise en file d'attente des workers d'indexation n'est pas recommandée pour les petites instances ou les instances avec peu de processus Sidekiq. |
| **URL**                                                     | L'URL de votre instance Elasticsearch. Utilisez une liste séparée par des virgules pour prendre en charge le clustering (par exemple, `http://host1, https://host2:9200`). Si votre instance Elasticsearch est protégée par un mot de passe, utilisez les champs `Username` et `Password`. Vous pouvez également utiliser des identifiants intégrés tels que `http://<username>:<password>@<elastic_host>:9200/`. Si vous utilisez [OpenSearch](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/vpc.html), seules les connexions sur les ports `80` et `443` sont acceptées. |
| **Nom d'utilisateur**                                                | Le `username` de votre instance Elasticsearch. |
| **Mot de passe**                                                | Le mot de passe de votre instance Elasticsearch. |
| **Number of Elasticsearch shards and replicas per index**   | Les indices Elasticsearch sont divisés en plusieurs shards pour des raisons de performance. En général, vous devriez utiliser au moins cinq shards. Les indices contenant des dizaines de millions de documents devraient avoir davantage de shards ([voir les recommandations](#guidance-on-choosing-optimal-cluster-configuration)). Les modifications de cette valeur ne prennent effet qu'après la recréation de l'index. Pour plus d'informations sur l'évolutivité et la résilience, consultez la [documentation Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/scalability.html). Chaque shard Elasticsearch peut avoir un certain nombre de répliques. Ces répliques sont une copie complète du shard et peuvent améliorer les performances des requêtes ou la résilience en cas de défaillance matérielle. L'augmentation de cette valeur accroît l'espace disque total requis par l'index. Vous pouvez définir le nombre de shards et de répliques pour chacun des indices. |
| **Limiter le nombre d'espaces de nommage et la quantité de données de projet à indexer** | Lorsque vous activez ce paramètre, vous pouvez spécifier les espaces de nommage et les projets à indexer. Tous les autres espaces de nommage et projets utilisent la recherche en base de données à la place. Si vous activez ce paramètre sans spécifier d'espace de nommage ni de projet, seuls les enregistrements de projet sont indexés. Pour plus d'informations, consultez [Limiter le nombre d'espaces de nommage et la quantité de données de projet à indexer](#limit-the-amount-of-namespace-and-project-data-to-index). |
| **Utiliser le service AWS OpenSearch avec les identifiants IAM**         | Signez vos requêtes OpenSearch en utilisant [l'autorisation AWS IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html), les [identifiants de profil d'instance AWS EC2](https://docs.aws.amazon.com/codedeploy/latest/userguide/getting-started-create-iam-instance-profile.html#getting-started-create-iam-instance-profile-cli) ou les [identifiants de tâches AWS ECS](https://docs.aws.amazon.com/AmazonECS/latest/userguide/task-iam-roles.html). Consultez [Identity and Access Management in Amazon OpenSearch Service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html) pour obtenir des détails sur la configuration de la politique d'accès au domaine OpenSearch hébergé par AWS. |
| **Région AWS**                                              | La région AWS dans laquelle votre service OpenSearch est situé. |
| **Clé d'accès AWS**                                          | La clé d'accès AWS. |
| **Clé d'accès secrète AWS**                                   | La clé d'accès secrète AWS. |
| **Maximum file size indexed**                               | Consultez [l'explication dans les limites de l'instance](../../administration/instance_limits.md#maximum-file-size-indexed). |
| **Longueur maximale de champ**                                    | Consultez [l'explication dans les limites de l'instance](../../administration/instance_limits.md#maximum-field-length). |
| **Délai d'indexation (minutes)**                              | Délai d'indexation en minutes par projet. |
| **Nombre de shards pour l'indexation non codée**                  | Nombre de shards de workers d'indexation. Cela améliore le débit d'indexation non liée au code en mettant en file d'attente davantage de jobs Sidekiq en parallèle. L'augmentation du nombre de shards n'est pas recommandée pour les petites instances ou les instances avec peu de processus Sidekiq. La valeur par défaut est `2`. |
| **Taille maximale pour les requêtes en bloc (Mio)**                         | Utilisé par les processus d'indexation Ruby et Go de GitLab. Ce paramètre indique la quantité de données devant être collectée (et stockée en mémoire) lors d'un processus d'indexation donné avant de soumettre la charge utile à l'API Bulk d'Elasticsearch. Pour l'indexeur Go de GitLab, vous devriez utiliser ce paramètre avec **Simultanéité des requêtes en bloc**. **Taille maximale pour les requêtes en bloc (Mio)** doit tenir compte des contraintes de ressources à la fois des hôtes Elasticsearch et des hôtes exécutant l'indexeur Go de GitLab, que ce soit depuis la commande `gitlab-rake` ou les tâches Sidekiq. |
| **Simultanéité des requêtes en bloc**                                | La simultanéité des requêtes en bloc indique le nombre de processus (ou threads) de l'indexeur Go de GitLab pouvant s'exécuter en parallèle pour collecter des données à soumettre ensuite à l'API Bulk d'Elasticsearch. Cela améliore les performances d'indexation, mais remplit la file d'attente des requêtes en bloc Elasticsearch plus rapidement. Ce paramètre doit être utilisé conjointement avec le paramètre **Taille maximale pour les requêtes en bloc (Mio)** et doit tenir compte des contraintes de ressources à la fois des hôtes Elasticsearch et des hôtes exécutant l'indexeur Go de GitLab, que ce soit depuis la commande `gitlab-rake` ou les tâches Sidekiq. |
| **Délai d'expiration des requêtes client**                                  | Valeur du délai d'expiration des requêtes client HTTP Elasticsearch en secondes. Une valeur de `0` utilise le délai d'expiration par défaut de 30 secondes. Les requêtes de recherche dépassant cette limite renvoient `HTTP 408` au lieu d'échouer avec un `500` après que le serveur d'application met fin à la requête. Si vos requêtes Elasticsearch prennent régulièrement plus de 30 secondes, définissez une valeur plus élevée. Le serveur d'application met fin aux requêtes après 60 secondes, ne définissez donc pas une valeur supérieure à `60`. Pour un délai d'expiration plus long, vous devriez définir une valeur entre `30` et `55`. |
| **Simultanéité d'indexation de code**                               | Nombre maximal de jobs d'indexation de code Elasticsearch en arrière-plan autorisés à s'exécuter simultanément. Cela s'applique uniquement aux opérations d'indexation de dépôt. |
| **Réessayer en cas d'échec**                                        | Nombre maximal de tentatives possibles pour les requêtes de recherche Elasticsearch. [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/486935) dans GitLab 17.6. |
| **Index prefix**                                            | Préfixe personnalisé pour les noms d'index Elasticsearch. Par défaut, `gitlab`. En cas de modification, tous les indices utiliseront ce préfixe à la place de `gitlab` (par exemple, `custom-production-issues` au lieu de `gitlab-production-issues`). Doit contenir entre 1 et 100 caractères, uniquement des caractères alphanumériques minuscules, des tirets et des underscores, et ne peut pas commencer ou se terminer par un tiret ou un underscore. [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/3421) dans GitLab 18.2. |

> [!warning]
> L'augmentation des valeurs de **Taille maximale pour les requêtes en bloc (Mio)** et de **Simultanéité des requêtes en bloc** peut nuire aux performances de Sidekiq. Rétablissez leurs valeurs par défaut si vous constatez une augmentation des durées `scheduling_latency_s` dans vos logs Sidekiq. Pour plus d'informations, consultez [l'issue 322147](https://gitlab.com/gitlab-org/gitlab/-/issues/322147).

### Limiter le nombre d'espaces de nommage et la quantité de données de projet à indexer {#limit-the-amount-of-namespace-and-project-data-to-index}

{{< history >}}

- L'indexation de tous les enregistrements de projet a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/428070) dans GitLab 16.7 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `search_index_all_projects`. Désactivé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148111) dans GitLab 16.11. Feature flag `search_index_all_projects` supprimé.
- L'indexation des enregistrements de vulnérabilité a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/536299) sur GitLab.com et GitLab Dedicated dans GitLab 18.1 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `vulnerability_es_ingestion`. Désactivé par défaut.
- L'indexation des enregistrements de vulnérabilité est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/536299) sur GitLab.com et GitLab Dedicated dans GitLab 18.2. Feature flag `vulnerability_es_ingestion` supprimé.

{{< /history >}}

> [!flag]
> Un feature flag contrôle la disponibilité de cette fonctionnalité. Pour plus d'informations, consultez l'historique.

Lorsque vous cochez la case **Limiter le nombre d'espaces de nommage et la quantité de données de projet à indexer**, vous pouvez spécifier les espaces de nommage et les projets à indexer. Si l'espace de nommage est un groupe, tous les sous-groupes et projets de ces sous-groupes sont également indexés.

Lorsque vous activez ce paramètre :

- Les espaces de nommage ou les projets doivent être spécifiés pour une indexation complète.
- Les enregistrements de projet (métadonnées telles que les noms et descriptions de projets) sont toujours indexés pour tous les projets.
- Les enregistrements de vulnérabilité sont toujours indexés pour tous les projets et espaces de nommage afin de prendre en charge le filtrage dans les rapports de sécurité.
- Les [données associées](#advanced-search-index-scopes) sont indexées uniquement pour les espaces de nommage et les projets que vous spécifiez.

> [!warning]
> Si vous ne spécifiez aucun espace de nommage ni projet après avoir activé ce paramètre, seuls les enregistrements de projet sont indexés et aucune donnée associée ne peut être recherchée.

#### Espaces de nommage indexés {#indexed-namespaces}

{{< history >}}

- La recherche globale pour une indexation limitée a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41041) dans GitLab 13.4 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `advanced_global_search_for_limited_indexing`. Désactivé par défaut.
- [Activée sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/244276) dans GitLab 14.2.
- La recherche globale pour une indexation limitée est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186727) dans GitLab 17.11 en tant qu'option d'interface utilisateur, à la place du feature flag `advanced_global_search_for_limited_indexing`.

{{< /history >}}

Lorsque vous indexez tous les espaces de nommage, vous pouvez utiliser la recherche avancée pour la recherche globale de code et de commits. Lorsque vous n'indexez que certains espaces de nommage :

- La recherche globale n'inclut pas la portée de recherche de code ou de commits.
- Les recherches de code et de commits sont disponibles uniquement dans un seul espace de nommage indexé.
- Une recherche de code ou de commit unique n'est pas possible sur plusieurs espaces de nommage indexés.
- La recherche inter-projets est disponible dans un espace de nommage indexé.

Par exemple, si vous indexez deux groupes distincts, vous devez effectuer des recherches de code séparées sur chaque groupe individuellement.

Pour activer la recherche globale pour une indexation limitée :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Recherche avancée**
1. Sélectionnez **Activer la recherche globale pour l'indexation limitée**.
1. Sélectionnez **Enregistrer les modifications**.
1. Si vous avez déjà indexé votre instance, vous devez [réindexer l'instance](#index-the-instance). Cela supprime les données de recherche existantes pour permettre au filtrage de fonctionner correctement.

## Activer les analyseurs de langue personnalisés {#enable-custom-language-analyzers}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Vous pouvez améliorer la prise en charge du chinois et du japonais en utilisant les plugins d'analyse [`smartcn`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html) et [`kuromoji`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html) d'Elastic.

Pour activer les analyseurs de langue personnalisés :

1. Installez les plugins souhaités, consultez la [documentation Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/plugins/7.9/installation.html) pour obtenir des instructions d'installation des plugins. Les plugins doivent être installés sur chaque nœud du cluster, et chaque nœud doit être redémarré après l'installation. Pour obtenir la liste des plugins, consultez le tableau plus loin dans cette section.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Localisez **Analyseurs personnalisés : prise en charge des langues**.
1. Activez la prise en charge des plugins pour l'**indexation**.
1. Sélectionnez **Sauvegarder les modifications** pour que les modifications prennent effet.
1. Déclenchez une [réindexation sans temps d'arrêt](#zero-downtime-reindexing) ou réindexez tout depuis le début pour créer un nouvel index avec des mappings mis à jour.
1. Activez la prise en charge des plugins pour **Recherche** une fois l'étape précédente terminée.

Pour obtenir des conseils sur ce qu'il faut installer, consultez les options de plugins de langue Elasticsearch suivantes :

| Paramètre                                             | Description |
|-------------------------------------------------------|-------------|
| `Enable Chinese (smartcn) custom analyzer: Indexing`   | Active ou désactive la prise en charge du chinois à l'aide de l'analyseur personnalisé [`smartcn`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html) pour les indices nouvellement créés.|
| `Enable Chinese (smartcn) custom analyzer: Search`   | Active ou désactive l'utilisation des champs [`smartcn`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html) pour la recherche avancée. N'activez cela qu'après avoir [installé le plugin](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html), activé l'indexation avec un analyseur personnalisé et recréé l'index.|
| `Enable Japanese (kuromoji) custom analyzer: Indexing`   | Active ou désactive la prise en charge du japonais à l'aide de l'analyseur personnalisé [`kuromoji`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html) pour les indices nouvellement créés.|
| `Enable Japanese (kuromoji) custom analyzer: Search`  | Active ou désactive l'utilisation des champs [`kuromoji`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html) pour la recherche avancée. N'activez cela qu'après avoir [installé le plugin](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html), activé l'indexation avec un analyseur personnalisé et recréé l'index.|

## Désactiver la recherche avancée {#disable-advanced-search}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour désactiver la recherche avancée dans GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Décochez les cases **Activer l'indexation pour la recherche avancée** et **Recherche avancée**.
1. Sélectionnez **Enregistrer les modifications**.
1. Facultatif. Pour les instances Elasticsearch toujours en ligne, supprimez les indices existants :

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:delete_index

   # For self-compiled installations
   bundle exec rake gitlab:elastic:delete_index RAILS_ENV=production
   ```

### Désactiver la recherche avancée {#disable-search-with-advanced-search}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour désactiver la recherche avancée dans GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Décochez la case **Recherche avancée**.
1. Sélectionnez **Enregistrer les modifications**.

### Désactiver la recherche de code avec la recherche avancée {#disable-code-search-with-advanced-search}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour désactiver la recherche de code avec la recherche avancée dans GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Décochez la case **Recherche de code à l'aide de la recherche avancée**.
1. Sélectionnez **Enregistrer les modifications**.

## Suspendre l'indexation {#pause-indexing}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour suspendre l'indexation :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Recherche avancée**.
1. Cochez la case **Suspendre l'indexation pour la recherche avancée**.
1. Sélectionnez **Enregistrer les modifications**.

## Reprendre l'indexation {#resume-indexing}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour reprendre l'indexation :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Recherche avancée**.
1. Décochez la case **Suspendre l'indexation pour la recherche avancée**.
1. Sélectionnez **Enregistrer les modifications**.

## Réindexation sans temps d'arrêt {#zero-downtime-reindexing}

L'idée derrière cette méthode de réindexation est d'utiliser l'[API de réindexation Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html) et la fonctionnalité d'alias d'index Elasticsearch pour effectuer l'opération. Un alias d'index se connecte à un index `primary` que GitLab utilise pour les lectures et les écritures. Lorsque le processus de réindexation démarre, les écritures dans l'index `primary` sont temporairement suspendues. Ensuite, un autre index est créé et l'API Reindex est invoquée pour migrer les données de l'index vers le nouvel index. Une fois le job de réindexation terminé, l'alias d'index bascule vers le nouvel index, qui devient le nouvel index `primary`. Enfin, les écritures reprennent et le fonctionnement normal continue.

### Utiliser la réindexation sans temps d'arrêt {#using-zero-downtime-reindexing}

Vous pouvez utiliser la réindexation sans temps d'arrêt pour configurer les paramètres d'index ou les mappings qui ne peuvent pas être modifiés sans créer un nouvel index et copier les données existantes. Vous ne devriez pas utiliser la réindexation sans temps d'arrêt pour corriger les données manquantes. La réindexation sans temps d'arrêt n'ajoute pas de données au cluster de recherche si celles-ci ne sont pas déjà indexées. Vous devez terminer toutes les [migrations de recherche avancée](#advanced-search-migrations) avant de démarrer la réindexation.

### Déclencher la réindexation {#trigger-reindexing}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour déclencher la réindexation :

1. Connectez-vous à votre instance GitLab en tant qu'administrateur.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Réindexation sans temps d'arrêt de la recherche avancée**.
1. Sélectionnez **Déclencher la réindexation du cluster**.

La réindexation peut être un processus long en fonction de la taille de votre cluster Elasticsearch.

Une fois ce processus terminé, l'index d'origine est planifié pour être supprimé après 14 jours. Vous pouvez annuler cette action en appuyant sur le bouton **Annuler** sur la même page où vous avez déclenché le processus de réindexation.

Pendant l'exécution de la réindexation, vous pouvez suivre sa progression dans cette même section.

#### Déclencher la réindexation sans temps d'arrêt {#trigger-zero-downtime-reindexing}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour déclencher la réindexation sans temps d'arrêt :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Réindexation sans temps d'arrêt de la recherche avancée**. Les paramètres suivants sont disponibles :

   - [Multiplicateur de tranches](#slice-multiplier)
   - [Nombre maximal de tranches en cours d'exécution](#maximum-running-slices)

##### Multiplicateur de tranches {#slice-multiplier}

Le multiplicateur de tranches calcule le [nombre de tranches lors de la réindexation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html#docs-reindex-slice).

GitLab utilise le [découpage manuel](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html#docs-reindex-manual-slice) pour contrôler la réindexation de manière efficace et sécurisée, ce qui permet aux utilisateurs de ne réessayer que les tranches ayant échoué.

Le multiplicateur est par défaut `2` et s'applique au nombre de shards par index. Par exemple, si cette valeur est `2` et que votre index comporte 20 shards, la tâche de réindexation est divisée en 40 tranches.

##### Nombre maximal de tranches en cours d'exécution {#maximum-running-slices}

Le paramètre de nombre maximal de tranches en cours d'exécution est par défaut `60` et correspond au nombre maximal de tranches autorisées à s'exécuter simultanément lors de la réindexation Elasticsearch.

Définir cette valeur trop haute peut avoir des impacts négatifs sur les performances, car votre cluster peut devenir fortement saturé par les recherches et les écritures. Définir cette valeur trop basse peut conduire le processus de réindexation à prendre très longtemps pour se terminer.

La meilleure valeur pour ce paramètre dépend de la taille de votre cluster, de votre disposition à accepter une dégradation des performances de recherche pendant la réindexation, et de l'importance de terminer rapidement la réindexation et de reprendre l'indexation.

### Marquer le job de réindexation le plus récent comme ayant échoué et reprendre l'indexation {#mark-the-most-recent-reindexing-job-as-failed-and-resume-indexing}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour abandonner un job de réindexation inachevé et reprendre l'indexation :

1. Marquez le job de réindexation le plus récent comme ayant échoué :

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:mark_reindex_failed

   # For self-compiled installations
   bundle exec rake gitlab:elastic:mark_reindex_failed RAILS_ENV=production
   ```

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Recherche avancée**.
1. Décochez la case **Suspendre l'indexation pour la recherche avancée**.

## Intégrité de l'index {#index-integrity}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112369) dans GitLab 15.10 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `search_index_integrity`. Désactivé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/392981) dans GitLab 16.4. Feature flag `search_index_integrity` supprimé.

{{< /history >}}

L'intégrité de l'index détecte et corrige les données de dépôt manquantes. Cette fonctionnalité est utilisée automatiquement lorsque les recherches de code limitées à un groupe ou à un projet ne renvoient aucun résultat.

## Migrations de recherche avancée {#advanced-search-migrations}

Les migrations de réindexation s'exécutent en arrière-plan, ce qui signifie que vous n'avez pas à réindexer l'instance manuellement.

[Dans GitLab 18.0 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/352424), vous pouvez utiliser le paramètre d'application `elastic_migration_worker_enabled` pour activer ou désactiver le worker de migration. Par défaut, le worker de migration est activé.

### Fichiers de dictionnaire de migration {#migration-dictionary-files}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/414674) dans GitLab 16.3.

{{< /history >}}

Chaque migration dispose d'un fichier de dictionnaire correspondant dans le dossier `ee/elastic/docs/` avec les informations suivantes :

```yaml
name:
version:
description:
group:
milestone:
introduced_by_url:
obsolete:
marked_obsolete_by_url:
marked_obsolete_in_milestone:
```

Vous pouvez utiliser ces informations, par exemple, pour identifier quand une migration a été introduite ou marquée comme obsolète.

### Vérifier les migrations en attente {#check-for-pending-migrations}

Pour vérifier les migrations de recherche avancée en attente, exécutez cette commande :

```shell
curl "$CLUSTER_URL/gitlab-production-migrations/_search?size=100&q=*" | jq .
```

Cela devrait renvoyer quelque chose de similaire à :

```json
{
  "took": 14,
  "timed_out": false,
  "_shards": {
    "total": 1,
    "successful": 1,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": {
      "value": 1,
      "relation": "eq"
    },
    "max_score": 1,
    "hits": [
      {
        "_index": "gitlab-production-migrations",
        "_type": "_doc",
        "_id": "20230209195404",
        "_score": 1,
        "_source": {
          "completed": true
        }
      }
    ]
  }
}
```

Pour déboguer les problèmes liés aux migrations, consultez le fichier [`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog).

### Réessayer une migration bloquée {#retry-a-halted-migration}

Certaines migrations sont créées avec une limite de tentatives. Si la migration ne peut pas se terminer dans la limite de tentatives, elle est bloquée et une notification s'affiche dans les paramètres d'intégration de recherche avancée.

Il est recommandé de consulter le [fichier `elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog) pour déboguer la raison du blocage de la migration et d'apporter les modifications nécessaires avant de réessayer la migration.

Lorsque vous pensez avoir corrigé la cause de l'échec :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Recherche avancée**.
1. Dans la boîte d'alerte **migration d'Elasticsearch en pause**, sélectionnez **Retenter la migration**. La migration est planifiée pour être relancée en arrière-plan.

Si vous ne parvenez pas à faire aboutir la migration, vous pouvez envisager la [dernière solution consistant à recréer l'index depuis le début](../elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index). Cela peut vous permettre de contourner le problème, car un index nouvellement créé ignore toutes les migrations puisque l'index est recréé avec le schéma correct et à jour.

### Toutes les migrations doivent être terminées avant d'effectuer une mise à niveau majeure {#all-migrations-must-be-finished-before-doing-a-major-upgrade}

Avant de mettre à niveau vers une version majeure de GitLab, vous devez effectuer toutes les migrations qui existent jusqu'à la dernière version mineure avant cette version majeure. Vous devez également résoudre et [réessayer toutes les migrations bloquées](#retry-a-halted-migration) avant de procéder à une mise à niveau vers une version majeure. Pour plus d'informations, consultez [Migrations pour les mises à niveau](../../update/background_migrations.md).

Les migrations qui ont été supprimées sont [marquées comme obsolètes](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63001). Si vous mettez à niveau GitLab avant que toutes les migrations de recherche avancée en attente soient terminées, les migrations en attente qui ont été supprimées dans la nouvelle version ne peuvent pas être exécutées ni relancées. Dans ce cas, vous devez [recréer votre index depuis le début](../elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index).

### Migrations ignorables {#skippable-migrations}

Les migrations ignorables ne sont exécutées que lorsqu'une condition est remplie. Par exemple, si une migration dépend d'une version spécifique d'Elasticsearch, elle peut être ignorée jusqu'à ce que cette version soit atteinte.

Si une migration ignorable n'est pas exécutée au moment où la migration est marquée comme obsolète, vous devez [recréer l'index](../elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index) pour appliquer la modification.

## Tâches Rake de recherche avancée GitLab {#gitlab-advanced-search-rake-tasks}

Des tâches Rake sont disponibles pour :

- [Compiler et installer](#build-and-install) l'indexeur.
- Supprimer les indices lors de la [désactivation d'Elasticsearch](#disable-advanced-search).
- Ajouter des données GitLab à un index.

Voici quelques tâches Rake disponibles :

| Tâche                                                                                                                                                       | Description |
|:-----------------------------------------------------------------------------------------------------------------------------------------------------------|:------------|
| [`sudo gitlab-rake gitlab:elastic:info`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                              | Affiche des informations de débogage pour l'intégration de recherche avancée. |
| [`sudo gitlab-rake gitlab:elastic:index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                             | Dans GitLab 17.0 et versions antérieures, active l'indexation pour la recherche avancée et exécute `gitlab:elastic:recreate_index`, `gitlab:elastic:clear_index_status`, `gitlab:elastic:index_group_entities`, `gitlab:elastic:index_projects`, `gitlab:elastic:index_snippets` et `gitlab:elastic:index_users`.<br>Dans GitLab 17.1 et versions ultérieures, met en file d'attente un job Sidekiq en arrière-plan. D'abord, le job active l'indexation pour la recherche avancée et suspend l'indexation pour s'assurer que tous les indices sont créés. Ensuite, le job recrée tous les indices, efface le statut d'indexation et met en file d'attente des jobs Sidekiq supplémentaires pour indexer les données de projet et de groupe, les snippets et les utilisateurs. Enfin, l'indexation pour la recherche avancée est reprise pour être complétée. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/421298) dans GitLab 17.1 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `elastic_index_use_trigger_indexing`. Activé par défaut. [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/434580) dans GitLab 17.3. Feature flag `elastic_index_use_trigger_indexing` supprimé. |
| [`sudo gitlab-rake gitlab:elastic:pause_indexing`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                    | Suspend l'indexation pour la recherche avancée. Les modifications sont toujours suivies. Utile pour les migrations de cluster/index. |
| [`sudo gitlab-rake gitlab:elastic:resume_indexing`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                   | Reprend l'indexation pour la recherche avancée. |
| [`sudo gitlab-rake gitlab:elastic:index_and_search_validation`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)       | Valide la connectivité du cluster, l'indexation et les opérations de recherche pour tous les indices. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200664) dans GitLab 18.3. |
| [`sudo gitlab-rake gitlab:elastic:index_projects`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                    | Itère sur tous les projets et met en file d'attente des jobs Sidekiq pour les indexer en arrière-plan. Ne peut être utilisé qu'après la création de l'index. |
| [`sudo gitlab-rake gitlab:elastic:index_group_entities`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)              | Invoque `gitlab:elastic:index_work_items` et `gitlab:elastic:index_group_wikis`. |
| [`sudo gitlab-rake gitlab:elastic:index_work_items`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                  | Indexe tous les éléments de travail des groupes où Elasticsearch est activé. |
| [`sudo gitlab-rake gitlab:elastic:index_namespaces`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                  | Indexe tous les espaces de nommage racines. |
| [`sudo gitlab-rake gitlab:elastic:index_group_wikis`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                 | Indexe tous les wikis des groupes où Elasticsearch est activé. |
| [`sudo gitlab-rake gitlab:elastic:index_snippets`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                    | Effectue une importation Elasticsearch qui indexe les données des snippets. |
| [`sudo gitlab-rake gitlab:elastic:index_users`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                       | Importe tous les utilisateurs dans Elasticsearch. |
| [`sudo gitlab-rake gitlab:elastic:index_vulnerabilities`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)             | Indexe toutes les vulnérabilités. |
| [`sudo gitlab-rake gitlab:elastic:index_projects_status`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)             | Détermine le statut global d'indexation de toutes les données de dépôt de projet (code, commits et wikis). Le statut est calculé en divisant le nombre de projets indexés par le nombre total de projets et en multipliant par 100. Cette tâche n'inclut pas les données hors dépôt telles que les tickets, les merge requests ou les jalons. |
| [`sudo gitlab-rake gitlab:elastic:index_groups_status`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)               | Détermine le statut global d'indexation de toutes les données de dépôt de groupe (wikis de groupe). Le statut est calculé en divisant le nombre de groupes indexés par le nombre total de groupes et en multipliant par 100. Cette tâche n'inclut pas les données hors dépôt telles que les epics, les merge requests ou les jalons. |
| [`sudo gitlab-rake gitlab:elastic:clear_index_status`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                | Supprime toutes les instances d'IndexStatus pour tous les projets. Cette commande entraîne un effacement complet de l'index et doit être utilisée avec précaution. |
| [`sudo gitlab-rake gitlab:elastic:create_empty_index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                | Génère des indices vides (l'index par défaut et un index de tickets séparé) et attribue un alias à chacun côté Elasticsearch uniquement s'il n'existe pas déjà. |
| [`sudo gitlab-rake gitlab:elastic:delete_index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                      | Supprime les indices et alias GitLab (s'ils existent) sur l'instance Elasticsearch. |
| [`sudo gitlab-rake gitlab:elastic:recreate_index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                    | Tâche enveloppante pour `gitlab:elastic:delete_index` et `gitlab:elastic:create_empty_index`. Ne met aucun job d'indexation en file d'attente. |
| [`sudo gitlab-rake gitlab:elastic:projects_not_indexed`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)              | Affiche les projets dont les données de dépôt ne sont pas indexées. Cette tâche n'inclut pas les données hors dépôt telles que les tickets, les merge requests ou les jalons. |
| [`sudo gitlab-rake gitlab:elastic:groups_not_indexed`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                | Affiche les groupes dont les données de dépôt ne sont pas indexées. Cette tâche n'inclut pas les données hors dépôt telles que les tickets, les merge requests ou les jalons. |
| [`sudo gitlab-rake gitlab:elastic:reindex_cluster`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                   | Planifie une tâche de réindexation de cluster sans temps d'arrêt. |
| [`sudo gitlab-rake gitlab:elastic:mark_reindex_failed`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)               | Marque le job de réindexation le plus récent comme ayant échoué. |
| [`sudo gitlab-rake gitlab:elastic:list_pending_migrations`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)           | Liste les migrations en attente. Les migrations en attente comprennent celles qui n'ont pas encore démarré, celles qui ont démarré mais ne sont pas terminées, et celles qui sont bloquées. |
| [`sudo gitlab-rake gitlab:elastic:estimate_cluster_size`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)             | Obtenez une estimation de la taille des index de code et de wiki ainsi que de la taille totale du cluster en fonction de la taille totale du dépôt. |
| [`sudo gitlab-rake gitlab:elastic:estimate_shard_sizes`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)              | Obtenez une estimation de la taille des shards pour chaque index en fonction des comptages approximatifs de la base de données. Cette estimation n'inclut pas les données du dépôt (code, commits, et wikis). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146108) dans GitLab 16.11. |
| [`sudo gitlab-rake gitlab:elastic:enable_search_with_elasticsearch`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)  | Active la recherche avancée avec Elasticsearch. |
| [`sudo gitlab-rake gitlab:elastic:disable_search_with_elasticsearch`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake) | Désactive la recherche avancée avec Elasticsearch. |

### Variables d'environnement {#environment-variables}

En plus des tâches Rake, certaines variables d'environnement peuvent être utilisées pour modifier le processus :

| Variable d'environnement | Type de données | Objectif                                                                 |
| -------------------- |:---------:| ---------------------------------------------------------------------------- |
| `ID_TO`              | Entier   | Indique à l'indexeur d'indexer uniquement les projets dont la valeur est inférieure ou égale à la valeur spécifiée.    |
| `ID_FROM`            | Entier   | Indique à l'indexeur d'indexer uniquement les projets dont la valeur est supérieure ou égale à la valeur spécifiée. |

### Indexation d'une plage de projets ou d'un projet spécifique {#indexing-a-range-of-projects-or-a-specific-project}

En utilisant les variables d'environnement `ID_FROM` et `ID_TO`, vous pouvez indexer un nombre limité de projets. Cela peut être utile pour l'indexation par étapes.

```shell
root@git:~# sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=1 ID_TO=100
```

Étant donné que `ID_FROM` et `ID_TO` utilisent la comparaison `or equal to`, vous pouvez les utiliser pour indexer un seul projet en définissant les deux sur le même ID de projet :

```shell
root@git:~# sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=5 ID_TO=5
Indexing project repositories...I, [2019-03-04T21:27:03.083410 #3384]  INFO -- : Indexing GitLab User / test (ID=33)...
I, [2019-03-04T21:27:05.215266 #3384]  INFO -- : Indexing GitLab User / test (ID=33) is done!
```

## Portées de l'index de recherche avancée {#advanced-search-index-scopes}

Lors d'une recherche, l'index GitLab utilise les portées suivantes :

| Nom de la portée       | Éléments recherchés       |
|------------------|------------------------|
| `commits`        | Données de commit            |
| `projects`       | Données du projet (par défaut) |
| `blobs`          | Code                   |
| `work_items`     | Données des éléments de travail         |
| `merge_requests` | Données des merge requests     |
| `milestones`     | Données des jalons         |
| `notes`          | Données des notes              |
| `snippets`       | Données des extraits de code           |
| `wiki_blobs`     | Contenu du wiki          |
| `users`          | Utilisateurs                  |

Sur GitLab.com et GitLab Dedicated, les enregistrements de vulnérabilités sont toujours indexés pour tous les projets et espaces de nommage afin de prendre en charge les fonctionnalités en dehors de la recherche. L'indexation des enregistrements de vulnérabilités sur GitLab Self-Managed est proposée dans [le ticket 525484](https://gitlab.com/gitlab-org/gitlab/-/issues/525484).

## Optimisation {#tuning}

### Conseils pour choisir la configuration optimale du cluster {#guidance-on-choosing-optimal-cluster-configuration}

Pour des conseils de base sur le choix d'une configuration de cluster, consultez également [Elastic Cloud Calculator](https://cloud.elastic.co/pricing).

- En général, vous devriez utiliser au moins une configuration de cluster à 2 nœuds avec un réplica, ce qui vous permet d'avoir de la résilience. Si votre utilisation du stockage augmente rapidement, vous devriez prévoir une mise à l'échelle horizontale (ajout de nœuds supplémentaires) à l'avance.
- Il n'est pas recommandé d'utiliser le stockage HDD avec le cluster de recherche, car cela nuit aux performances. Il est préférable d'utiliser le stockage SSD (par exemple, des disques SSD NVMe ou SATA).
- Vous ne devriez pas utiliser de [nœuds de coordination uniquement](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html#coordinating-only-node) avec des instances de grande taille. Les nœuds de coordination uniquement sont plus petits que les [nœuds de données](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html#data-node), ce qui peut avoir un impact sur les performances et les [migrations de recherche avancée](#advanced-search-migrations).
- Vous pouvez utiliser le [GitLab Performance Tool](https://gitlab.com/gitlab-org/quality/performance) pour comparer les performances de recherche avec différentes tailles et configurations de cluster de recherche.
- `Heap size` ne doit pas être défini à plus de 50 % de votre RAM physique. De plus, il ne doit pas être défini à une valeur supérieure au seuil des oops compressés à base zéro. Le seuil exact varie, mais 26 Go est sans risque sur la plupart des systèmes, mais peut également atteindre 30 Go sur certains systèmes. Consultez les [paramètres Heap size](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html#heap-size-settings) et les [options des paramètres JVM](https://www.elastic.co/guide/en/elasticsearch/reference/current/jvm-options.html) pour plus de détails.
- `refresh_interval` est un paramètre par index. Vous pouvez ajuster cette valeur par défaut `1s` vers une valeur plus grande si vous n'avez pas besoin de données en temps réel. Cela modifie la rapidité avec laquelle vous voyez les résultats récents. Si cela est important pour vous, vous devriez le laisser aussi proche que possible de la valeur par défaut.
- Vous pouvez envisager d'augmenter [`indices.memory.index_buffer_size`](https://www.elastic.co/guide/en/elasticsearch/reference/current/indexing-buffer.html) à 30 % ou 40 % si vous avez de nombreuses opérations d'indexation intensives.

### Paramètres de recherche avancée {#advanced-search-settings}

#### Nombre de shards Elasticsearch {#number-of-elasticsearch-shards}

{{< history >}}

- `gitlab:elastic:estimate_shard_sizes` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146108) dans GitLab 16.11.
- `gitlab:elastic:estimate_shard_sizes` [modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/348452) dans GitLab 18.3 pour inclure le dimensionnement des index contenant des données de dépôt.

{{< /history >}}

Pour les clusters à nœud unique, définissez le nombre de shards Elasticsearch par index sur le nombre de cœurs CPU des nœuds de données Elasticsearch.

Pour les clusters multi-nœuds, exécutez la tâche Rake `gitlab:elastic:estimate_shard_sizes` pour déterminer le nombre de shards pour chaque index. La tâche renvoie des recommandations concernant la taille des shards et des réplicas ainsi que des estimations du nombre de documents pour les index contenant des données de base de données.

Maintenez la taille moyenne des shards entre quelques Go et 30 Go. Si la taille moyenne des shards dépasse 30 Go, augmentez la taille des shards pour l'index et déclenchez [la réindexation sans temps d'arrêt](#zero-downtime-reindexing). Pour garantir l'intégrité du cluster, le nombre de shards par nœud ne doit pas dépasser 20 fois la taille de heap configurée. Par exemple, un nœud avec un heap de 30 Go doit avoir un maximum de 600 shards.

Pour mettre à jour le nombre de shards d'un index, modifiez le paramètre et déclenchez [la réindexation sans temps d'arrêt](#zero-downtime-reindexing).

#### Nombre de réplicas Elasticsearch {#number-of-elasticsearch-replicas}

Pour les clusters à nœud unique, définissez le nombre de réplicas Elasticsearch par index sur `0`.

Pour les clusters multi-nœuds, définissez le nombre de réplicas Elasticsearch par index sur `1` (chaque shard dispose d'un réplica). Le nombre ne doit pas être `0` car la perte d'un nœud corrompt l'index.

Si la [prise en compte de l'allocation des shards](https://www.elastic.co/docs/deploy-manage/distributed-architecture/shard-allocation-relocation-recovery/shard-allocation-awareness) est activée, le nombre total de copies par shard doit être divisible uniformément par le nombre d'attributs de prise en compte (généralement des nœuds ou des zones). La distribution uniforme des copies de shards sur tous les attributs de prise en compte garantit une tolérance aux pannes et une distribution de charge optimales.

```plaintext
(1 + `number_of_replicas`) / `number_of_awareness_attributes` = whole number
```

Pour mettre à jour le nombre de réplicas d'un index, modifiez le paramètre et déclenchez [la réindexation sans temps d'arrêt](#zero-downtime-reindexing).

### Indexer efficacement les grandes instances {#index-large-instances-efficiently}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

> [!warning]
> L'indexation d'une grande instance génère de nombreux jobs Sidekiq. Assurez-vous de vous préparer à cette tâche en disposant d'une [configuration évolutive](../../administration/reference_architectures/_index.md) ou en créant des [processus Sidekiq supplémentaires](../../administration/sidekiq/extra_sidekiq_processes.md).
>
> Les nœuds Geo primaires et secondaires pointent vers le même cluster Elasticsearch. Cependant, les workers d'indexation Elasticsearch s'exécutent uniquement sur les nœuds Sidekiq du site primaire.
>
> Pour cette raison, vous devez configurer tous les [processus Sidekiq supplémentaires](../../administration/sidekiq/extra_sidekiq_processes.md) sur les nœuds Sidekiq du site primaire.

Si [l'activation de la recherche avancée](#enable-advanced-search) pose des problèmes en raison de volumes importants de données à indexer :

1. [Configurez votre hôte et port Elasticsearch](#enable-advanced-search).
1. Créez des index vides :

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:create_empty_index

   # For self-compiled installations
   bundle exec rake gitlab:elastic:create_empty_index RAILS_ENV=production
   ```

1. S'il s'agit d'une réindexation de votre instance GitLab, effacez le statut de l'index :

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:clear_index_status

   # For self-compiled installations
   bundle exec rake gitlab:elastic:clear_index_status RAILS_ENV=production
   ```

1. [Cochez la case **Activer l'indexation pour la recherche avancée**](#enable-advanced-search).
1. L'indexation de grands dépôts Git peut prendre du temps. Pour accélérer le processus, vous pouvez [optimiser pour la vitesse d'indexation](https://www.elastic.co/guide/en/elasticsearch/reference/current/tune-for-indexing-speed.html#tune-for-indexing-speed) :

   - Vous pouvez temporairement augmenter [`refresh_interval`](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html).

   - Vous pouvez définir le nombre de réplicas sur 0. Ce paramètre contrôle le nombre de copies de chaque shard primaire d'un index. Ainsi, avoir 0 réplica désactive effectivement la réplication des shards entre les nœuds, ce qui devrait améliorer les performances d'indexation. Il s'agit d'un compromis important en termes de fiabilité et de performances des requêtes. Il est important de ne pas oublier de définir les réplicas sur une valeur appropriée une fois l'indexation initiale terminée.

   Vous pouvez vous attendre à une diminution de 20 % du temps d'indexation. Une fois l'indexation terminée, vous pouvez réinitialiser `refresh_interval` et `number_of_replicas` à leurs valeurs souhaitées.

   > [!note]
   > Cette étape est facultative mais peut contribuer à accélérer considérablement les grandes opérations d'indexation.

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "index" : {
              "refresh_interval" : "30s",
              "number_of_replicas" : 0
          } }'
   ```

1. Indexez les projets et leurs données associées :

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_projects

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_projects RAILS_ENV=production
   ```

   Cela met en file d'attente un job Sidekiq pour chaque projet qui doit être indexé. Vous pouvez interroger le statut d'indexation avec une tâche Rake :

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_projects_status

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_projects_status RAILS_ENV=production

   Indexing is 65.55% complete (6555/10000 projects). Considers only code, commits, and wikis.
   ```

   Si vous souhaitez limiter l'index à une plage de projets, vous pouvez fournir les paramètres `ID_FROM` et `ID_TO` :

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=1001 ID_TO=2000

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_projects ID_FROM=1001 ID_TO=2000 RAILS_ENV=production
   ```

   Où `ID_FROM` et `ID_TO` sont des ID de projet. Les deux paramètres sont facultatifs. L'exemple précédent indexe tous les projets depuis l'ID `1001` jusqu'à (et y compris) l'ID `2000`.

   > [!note]
   > Parfois, les jobs d'indexation de projets mis en file d'attente par `gitlab:elastic:index_projects` peuvent être interrompus. Cela peut se produire pour de nombreuses raisons, mais il est toujours sans risque de relancer la tâche d'indexation.

   Vous pouvez également utiliser la tâche Rake `gitlab:elastic:clear_index_status` pour forcer l'indexeur à « oublier » toute progression, afin qu'il recommence le processus d'indexation depuis le début.
1. Les éléments de travail, les wikis de groupe, les extraits de code personnels et les utilisateurs ne sont pas associés à un projet et doivent être indexés séparément :

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_work_items
   sudo gitlab-rake gitlab:elastic:index_group_wikis
   sudo gitlab-rake gitlab:elastic:index_snippets
   sudo gitlab-rake gitlab:elastic:index_users

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_work_items RAILS_ENV=production
   bundle exec rake gitlab:elastic:index_group_wikis RAILS_ENV=production
   bundle exec rake gitlab:elastic:index_snippets RAILS_ENV=production
   bundle exec rake gitlab:elastic:index_users RAILS_ENV=production
   ```

1. Réactivez la réplication et l'actualisation après l'indexation (uniquement si vous avez précédemment augmenté `refresh_interval`) :

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "index" : {
              "number_of_replicas" : 1,
              "refresh_interval" : "1s"
          } }'
   ```

   Un force merge doit être effectué après avoir réactivé l'actualisation.

   Pour Elasticsearch 6.x et versions ultérieures, assurez-vous que l'index est en mode lecture seule avant de procéder au force merge :

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "settings": {
            "index.blocks.write": true
          } }'
   ```

   Ensuite, initiez le force merge :

   ```shell
   curl --request POST 'localhost:9200/gitlab-production/_forcemerge?max_num_segments=5'
   ```

   Ensuite, remettez l'index en mode lecture-écriture :

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "settings": {
            "index.blocks.write": false
          } }'
   ```

1. Une fois l'indexation terminée, [cochez la case **Recherche avancée**](#enable-advanced-search).

### Indexer de grandes instances avec des nœuds ou processus Sidekiq dédiés {#index-large-instances-with-dedicated-sidekiq-nodes-or-processes}

> [!warning]
> Pour la plupart des instances, vous n'avez pas à configurer de nœuds ou processus Sidekiq dédiés. Les étapes suivantes utilisent un paramètre avancé de Sidekiq appelé [règles de routage](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules). Assurez-vous de bien comprendre les implications de l'utilisation des règles de routage pour éviter de perdre des jobs entièrement.

L'indexation d'une grande instance peut être un processus long et gourmand en ressources, susceptible de surcharger les nœuds et processus Sidekiq. Cela affecte négativement les performances et la disponibilité de GitLab.

Étant donné que GitLab vous permet de démarrer plusieurs processus Sidekiq, vous pouvez créer un processus supplémentaire dédié à l'indexation d'un ensemble de files d'attente (ou groupe de files d'attente). Ainsi, vous pouvez vous assurer que les files d'attente d'indexation disposent toujours d'un worker dédié, tandis que les autres files d'attente disposent d'un autre worker dédié pour éviter les conflits.

À cet effet, utilisez l'option [règles de routage](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules) qui permet à Sidekiq d'acheminer les jobs vers une file d'attente spécifique en fonction d'une [requête de correspondance de worker](../../administration/sidekiq/processing_specific_job_classes.md#worker-matching-query).

> [!note]
> Les règles de routage (`sidekiq['routing_rules']`) doivent être identiques sur tous les nœuds GitLab (en particulier les nœuds GitLab Rails et Sidekiq).

Vous pouvez choisir l'une des deux options suivantes pour gérer cela :

- [Utiliser deux groupes de files d'attente sur un seul nœud](#single-node-two-processes).
- [Utiliser deux groupes de files d'attente, un sur chaque nœud](#two-nodes-one-process-for-each).

Pour les étapes suivantes, considérez l'entrée de `sidekiq['routing_rules']` :

- `["feature_category=global_search", "global_search"]` car tous les jobs d'indexation sont acheminés vers la file d'attente `global_search`.
- `["*", "default"]` car tous les autres jobs non liés à l'indexation sont acheminés vers la file d'attente `default`.

Au moins un processus dans `sidekiq['queue_groups']` doit inclure la file d'attente `mailers`, sinon les jobs de messagerie ne sont pas traités du tout.

> [!warning]
> Lors du démarrage de plusieurs processus, le nombre de processus ne peut pas dépasser le nombre de cœurs CPU que vous souhaitez dédier à Sidekiq. Chaque processus Sidekiq ne peut utiliser qu'un seul cœur CPU, en fonction de la charge de travail disponible et des paramètres de concurrence. Pour plus de détails, consultez comment [exécuter plusieurs processus Sidekiq](../../administration/sidekiq/extra_sidekiq_processes.md).

#### Nœud unique, deux processus {#single-node-two-processes}

Pour créer à la fois un processus Sidekiq d'indexation et un processus Sidekiq non-indexation sur un seul nœud :

1. Sur votre nœud Sidekiq, modifiez le fichier `/etc/gitlab/gitlab.rb` comme suit :

   ```ruby
   sidekiq['enable'] = true

   sidekiq['routing_rules'] = [
      ["feature_category=global_search", "global_search"],
      ["*", "default"],
   ]

   sidekiq['queue_groups'] = [
      "global_search", # process that listens to global_search queue
      "default,mailers" # process that listens to default and mailers queue
   ]

   sidekiq['concurrency'] = 20
   ```

   Si vous utilisez GitLab 16.11 ou une version antérieure, désactivez explicitement tous les [sélecteurs de files d'attente](https://archives.docs.gitlab.com/16.11/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated) :

   ```ruby
   sidekiq['queue_selector'] = false
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../../administration/restart_gitlab.md) pour que les modifications prennent effet.
1. Sur tous les autres nœuds Rails et Sidekiq, assurez-vous que `sidekiq['routing_rules']` est identique à la configuration précédente.
1. Exécutez la tâche Rake pour [migrer les jobs existants](../../administration/sidekiq/sidekiq_job_migration.md) :

> [!note]
> Il est important d'exécuter la tâche Rake immédiatement après avoir reconfiguré GitLab. Après la reconfiguration de GitLab, les jobs existants ne sont pas traités tant que la tâche Rake n'a pas commencé à migrer les jobs.

#### Deux nœuds, un processus chacun {#two-nodes-one-process-for-each}

Pour gérer ces groupes de files d'attente sur deux nœuds :

1. Pour configurer le processus Sidekiq d'indexation, sur votre nœud Sidekiq d'indexation, modifiez le fichier `/etc/gitlab/gitlab.rb` comme suit :

   ```ruby
   sidekiq['enable'] = true

   sidekiq['routing_rules'] = [
      ["feature_category=global_search", "global_search"],
      ["*", "default"],
   ]

   sidekiq['queue_groups'] = [
     "global_search", # process that listens to global_search queue
   ]

   sidekiq['concurrency'] = 20
   ```

   Si vous utilisez GitLab 16.11 ou une version antérieure, désactivez explicitement tous les [sélecteurs de files d'attente](https://archives.docs.gitlab.com/16.11/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated) :

   ```ruby
   sidekiq['queue_selector'] = false
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../../administration/restart_gitlab.md) pour que les modifications prennent effet.
1. Pour configurer le processus Sidekiq non-indexation, sur votre nœud Sidekiq non-indexation, modifiez le fichier `/etc/gitlab/gitlab.rb` comme suit :

   ```ruby
   sidekiq['enable'] = true

   sidekiq['routing_rules'] = [
      ["feature_category=global_search", "global_search"],
      ["*", "default"],
   ]

   sidekiq['queue_groups'] = [
      "default,mailers" # process that listens to default and mailers queue
   ]

   sidekiq['concurrency'] = 20
   ```

   Si vous utilisez GitLab 16.11 ou une version antérieure, désactivez explicitement tous les [sélecteurs de files d'attente](https://archives.docs.gitlab.com/16.11/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated) :

   ```ruby
   sidekiq['queue_selector'] = false
   ```

1. Sur tous les autres nœuds Rails et Sidekiq, assurez-vous que `sidekiq['routing_rules']` est identique à la configuration précédente.
1. Enregistrez le fichier et [reconfigurez GitLab](../../administration/restart_gitlab.md) pour que les modifications prennent effet.
1. Exécutez la tâche Rake pour [migrer les jobs existants](../../administration/sidekiq/sidekiq_job_migration.md) :

   ```shell
   sudo gitlab-rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued
   ```

> [!note]
> Il est important d'exécuter la tâche Rake immédiatement après avoir reconfiguré GitLab. Après la reconfiguration de GitLab, les jobs existants ne sont pas traités tant que la tâche Rake n'a pas commencé à migrer les jobs.

### Documents supprimés {#deleted-documents}

Chaque fois qu'une modification ou une suppression est apportée à un objet GitLab indexé (description d'une merge request modifiée, fichier supprimé de la branche par défaut dans un dépôt, projet supprimé, etc.), un document dans l'index est supprimé. Cependant, comme il s'agit de suppressions « logicielles », le nombre total de « documents supprimés », et donc l'espace gaspillé, augmente.

Elasticsearch effectue une fusion intelligente des segments pour supprimer ces documents supprimés. Cependant, en fonction de la quantité et du type d'activité dans votre installation GitLab, il est possible de constater jusqu'à 50 % d'espace gaspillé dans l'index.

Vous devriez généralement laisser Elasticsearch fusionner et récupérer l'espace automatiquement avec les paramètres par défaut. D'après [gestion des documents supprimés de Lucene](https://www.elastic.co/blog/lucenes-handling-of-deleted-documents "gestion des documents supprimés de Lucene"), _« Dans l'ensemble, en dehors peut-être de la réduction de la taille maximale des segments, il est préférable de laisser les paramètres par défaut de Lucene tels quels et de ne pas trop se soucier du moment où les suppressions sont récupérées. »_

Cependant, certaines installations plus importantes peuvent souhaiter ajuster les paramètres de politique de fusion :

- Envisagez de réduire la taille de `index.merge.policy.max_merged_segment` par rapport à la valeur par défaut de 5 Go, à peut-être 2 Go ou 3 Go. La fusion ne se produit que lorsqu'un segment a au moins 50 % de suppressions. Des tailles de segments plus petites permettent à la fusion de se produire plus fréquemment.

  ```shell
  curl --request PUT localhost:9200/gitlab-production/_settings ---header 'Content-Type: application/json' \
       --data '{
         "index" : {
           "merge.policy.max_merged_segment": "2gb"
         }
       }'
  ```

- Vous pouvez également ajuster `index.merge.policy.reclaim_deletes_weight`, qui contrôle l'agressivité avec laquelle les suppressions sont ciblées. Mais cela peut conduire à des décisions de fusion coûteuses, vous ne devriez donc pas modifier ce paramètre à moins de comprendre les compromis impliqués.

  ```shell
  curl --request PUT localhost:9200/gitlab-production/_settings ---header 'Content-Type: application/json' \
       --data '{
         "index" : {
           "merge.policy.reclaim_deletes_weight": "3.0"
         }
       }'
  ```

- N'effectuez pas de [force merge](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-forcemerge.html "Force Merge") pour supprimer des documents supprimés. Un avertissement dans la [documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-forcemerge.html "Force Merge") indique que cela peut conduire à de très grands segments qui ne seront peut-être jamais récupérés, et peut également causer des problèmes de performances ou de disponibilité significatifs.

## Retour à la recherche basique {#reverting-to-basic-search}

Il peut parfois y avoir des problèmes avec les données de votre index Elasticsearch et, de ce fait, GitLab vous permet de revenir à la « recherche basique » lorsqu'il n'y a aucun résultat de recherche et en supposant que la recherche basique est prise en charge dans cette portée. Cette « recherche basique » se comporte comme si vous n'aviez pas du tout activé la recherche avancée pour votre instance et effectue des recherches en utilisant d'autres sources de données (telles que les données PostgreSQL et les données Git).

## Reprise après sinistre {#disaster-recovery}

Elasticsearch est une banque de données secondaire pour GitLab. Toutes les données stockées dans Elasticsearch peuvent être à nouveau dérivées d'autres sources de données, notamment PostgreSQL et Gitaly. Si la banque de données Elasticsearch est corrompue, vous pouvez tout réindexer depuis le début.

Si votre index Elasticsearch est trop volumineux, la réindexation complète depuis le début peut entraîner trop de temps d'arrêt. Vous ne pouvez pas automatiquement trouver des écarts et resynchroniser un index Elasticsearch, mais vous pouvez inspecter les journaux pour détecter les mises à jour manquantes. Pour récupérer les données plus rapidement, vous pouvez rejouer :

1. Toutes les mises à jour non-dépôt synchronisées en recherchant dans [`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog) les entrées [`track_items`](https://gitlab.com/gitlab-org/gitlab/-/blob/1e60ea99bd8110a97d8fc481e2f41cab14e63d31/ee/app/services/elastic/process_bookkeeping_service.rb#L25). Vous devez renvoyer ces éléments via `::Elastic::ProcessBookkeepingService.track!`.
1. Toutes les mises à jour du dépôt en recherchant dans [`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog) les entrées [`indexing_commit_range`](https://gitlab.com/gitlab-org/gitlab/-/blob/6f9d75dd3898536b9ec2fb206e0bd677ab59bd6d/ee/lib/gitlab/elastic/indexer.rb#L41). Vous devez définir [`IndexStatus#last_commit/last_wiki_commit`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/index_status.rb) sur le `from_sha` le plus ancien dans les journaux, puis déclencher une autre indexation du projet avec [`Search::Elastic::CommitIndexerWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/search/elastic/commit_indexer_worker.rb) et [`ElasticWikiIndexerWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/elastic_wiki_indexer_worker.rb).
1. Toutes les suppressions de projets en recherchant dans [`sidekiq.log`](../../administration/logs/_index.md#sidekiqlog) les entrées [`ElasticDeleteProjectWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/elastic_delete_project_worker.rb). Vous devez déclencher un autre `ElasticDeleteProjectWorker`.

Vous pouvez également effectuer des [snapshots Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html) réguliers pour réduire le temps nécessaire à la récupération après une perte de données sans tout réindexer depuis le début.
