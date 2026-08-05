---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: ClickHouse
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version bêta sur GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Disponible de manière générale](https://gitlab.com/groups/gitlab-org/-/work_items/20337) pour GitLab Self-Managed dans GitLab 18.11.

{{< /history >}}

[ClickHouse](https://clickhouse.com) est un système de gestion de bases de données orienté colonnes et open-source. Il peut filtrer, agréger et interroger efficacement de grands ensembles de données.

GitLab utilise ClickHouse comme magasin de données secondaire pour activer des fonctionnalités d'analytique avancées telles que GitLab Duo, les tendances SDLC et CI Analytics. GitLab ne stocke dans ClickHouse que les données nécessaires à ces fonctionnalités.

Nous vous recommandons d'utiliser [ClickHouse Cloud](https://clickhouse.com/cloud) pour connecter ClickHouse à GitLab.

Vous pouvez également [apporter votre propre instance ClickHouse](https://clickhouse.com/docs/en/install). Pour plus d'informations, consultez [les recommandations ClickHouse pour GitLab Self-Managed](https://clickhouse.com/docs/guides/sizing-and-hardware-recommendations).

## Analytique disponible avec ClickHouse {#analytics-available-with-clickhouse}

Une fois ClickHouse configuré, vous pouvez utiliser les fonctionnalités d'analytique suivantes :

| Fonctionnalité | Description |
|----------------------|---------------------|
| [Tableau de bord de la flotte de runners](../ci/runners/runner_fleet_dashboard.md#dashboard-metrics)  | Affiche les métriques d'utilisation des runners et les temps d'attente des jobs. Permet l'export de fichiers CSV contenant le nombre de jobs et les minutes de runner exécutées par type de runner et statut de job pour chaque projet.   |
| [Analytique des contributions](../user/group/contribution_analytics/_index.md)  | Fournit des analyses des contributions des membres du groupe (événements push, tickets, merge requests) au fil du temps. ClickHouse réduit le risque de problèmes de délai d'expiration pour les instances volumineuses. |
| [GitLab Duo et les tendances SDLC](../user/analytics/duo_and_sdlc_trends.md)  | Mesure l'impact de GitLab Duo sur les performances du développement logiciel. Suit les métriques de développement (fréquence de déploiement, délai d'exécution, taux d'échec des changements, temps de restauration) ainsi que les indicateurs spécifiques à l'IA (adoption des sièges GitLab Duo, taux d'acceptation des suggestions de code et utilisation de GitLab Duo Chat). |
| [API GraphQL pour les métriques IA](../api/graphql/duo_and_sdlc_trends.md) | Fournit un accès programmatique aux données de tendances GitLab Duo et SDLC via les endpoints `AiMetrics`, `AiUserMetrics` et `AiUsageData`. Permet l'export de métriques pré-agrégées et de données d'événements brutes pour l'intégration avec des outils de BI et des analyses personnalisées. |

## Versions de ClickHouse prises en charge {#supported-clickhouse-versions}

La version de ClickHouse prise en charge varie selon votre version de GitLab :

- GitLab 17.7 et versions ultérieures prennent en charge ClickHouse 23.x. Pour utiliser ClickHouse 24.x ou 25.x, utilisez la [solution de contournement](#database-schema-migrations-on-gitlab-1800-and-earlier).
- GitLab 18.1 et versions ultérieures prennent en charge ClickHouse 23.x, 24.x et 25.x.
- GitLab 18.8 et versions ultérieures prennent en charge ClickHouse 23.x, 24.x, 25.x et le moteur de base de données Replicated.
  - Les clusters plus anciens nécessiteront une autorisation supplémentaire (`dictGet`), consultez le [snippet](#database-dictionary-read-support).
- GitLab 19.0 et versions ultérieures prennent en charge ClickHouse 25.x et 26.x. La prise en charge de ClickHouse 23.x et 24.x a été supprimée.

ClickHouse Cloud est toujours compatible avec la dernière release stable de GitLab.

> [!warning]
> Si vous utilisez ClickHouse 25.12, notez qu'il a introduit une [modification incompatible avec les versions antérieures](https://clickhouse.com/docs/whats-new/changelog#backward-incompatible-change) dans `ALTER MODIFY COLUMN`. Cela interrompt le processus de migration pour l'intégration GitLab ClickHouse dans les versions antérieures à 18.8. Une mise à niveau de GitLab vers la version 18.8+ est requise.

## Configurer ClickHouse {#set-up-clickhouse}

Choisissez votre type de déploiement en fonction de vos exigences opérationnelles :

- **[ClickHouse Cloud](#set-up-clickhouse-cloud)** (recommandé) : service entièrement géré avec mises à niveau automatiques, sauvegardes et mise à l'échelle.
- **[ClickHouse pour GitLab Self-Managed (BYOC)](#set-up-clickhouse-for-gitlab-self-managed-byoc)** : contrôle total sur votre infrastructure et votre configuration.

Après avoir configuré votre instance ClickHouse :

1. [Créez la base de données et l'utilisateur GitLab](#create-database-and-user).
1. [Configurez la connexion GitLab](#configure-the-gitlab-connection).
1. [Vérifiez la connexion](#verify-the-connection).
1. [Exécutez les migrations ClickHouse](#run-clickhouse-migrations).
1. [Activez ClickHouse pour Analytics](#enable-clickhouse-for-analytics).

### Configurer ClickHouse Cloud {#set-up-clickhouse-cloud}

Prérequis :

- Disposer d'un compte ClickHouse Cloud.
- Activer la connectivité réseau entre votre instance GitLab et ClickHouse Cloud.
- Être administrateur de votre instance GitLab.

Pour configurer ClickHouse Cloud :

1. Connectez-vous à [ClickHouse Cloud](https://clickhouse.cloud).
1. Sélectionnez **New Service**.
1. Choisissez votre niveau de service :
   - **Développement** : pour les environnements de test et de développement.
   - **Production** : pour les charges de travail de production avec haute disponibilité.
1. Sélectionnez votre fournisseur de cloud et votre région. Choisissez une région proche de votre instance GitLab pour des performances optimales.
1. Configurez le nom et les paramètres de votre service.
1. Sélectionnez **Create Service**.
1. Une fois le provisionnement effectué, notez vos informations de connexion depuis le tableau de bord du service :
   - Hôte
   - Port (`8443` pour les connexions HTTPS utilisées par GitLab, ou `9440` pour le TCP natif avec TLS utilisé par `clickhouse-client`)
   - Nom d'utilisateur
   - Mot de passe

> [!note]
> ClickHouse Cloud gère automatiquement les mises à niveau de version et les correctifs de sécurité. Les clients Enterprise Edition (EE) peuvent planifier les mises à niveau pour contrôler leur moment et éviter les interruptions de service inattendues pendant les heures ouvrables. Pour plus d'informations, consultez [mettre à niveau ClickHouse](#upgrade-clickhouse).

Après avoir créé votre service ClickHouse Cloud, [créez la base de données et l'utilisateur GitLab](#create-database-and-user).

### Configurer ClickHouse pour GitLab Self-Managed (BYOC) {#set-up-clickhouse-for-gitlab-self-managed-byoc}

Prérequis :

- Disposer d'une instance ClickHouse installée et en cours d'exécution. Si ClickHouse n'est pas installé, consultez :
  - [Guide d'installation officiel de ClickHouse](https://clickhouse.com/docs/en/install).
  - [Recommandations ClickHouse pour GitLab Self-Managed](https://clickhouse.com/docs/guides/sizing-and-hardware-recommendations).
- Disposer d'une [version de ClickHouse prise en charge](#supported-clickhouse-versions).
- Activer la connectivité réseau entre votre instance GitLab et ClickHouse.
- Être administrateur à la fois de ClickHouse et de votre instance GitLab.

> [!warning]
> Pour ClickHouse avec GitLab Self-Managed, vous êtes responsable de la planification et de l'exécution des mises à niveau de version, des correctifs de sécurité et des sauvegardes. Pour plus d'informations, consultez [Mettre à niveau ClickHouse](#upgrade-clickhouse).

#### Configurer la haute disponibilité {#configure-high-availability}

Pour une configuration multi-nœuds à haute disponibilité (HA), GitLab prend en charge le moteur de table Replicated dans ClickHouse.

Prérequis :

- Disposer d'un cluster ClickHouse avec plusieurs nœuds. Un minimum de trois nœuds est recommandé.
- Définir un cluster dans la section de configuration `remote_servers`.
- Configurer les macros suivantes dans votre configuration ClickHouse :
  - `cluster`
  - `shard`
  - `replica`

Lors de la configuration de la base de données pour la HA, vous devez exécuter les instructions avec la clause `ON CLUSTER`.

Pour plus d'informations, consultez la [documentation du moteur de base de données Replicated de ClickHouse](https://clickhouse.com/docs/en/engines/database-engines/replicated).

#### Configurer le répartiteur de charge {#configure-load-balancer}

L'application GitLab communique avec le cluster ClickHouse via l'interface HTTP/HTTPS. Pour les déploiements HA, utilisez un proxy HTTP ou un répartiteur de charge pour distribuer les requêtes entre les nœuds du cluster ClickHouse.

Options de répartiteur de charge recommandées :

- [chproxy](https://www.chproxy.org/) \- Proxy HTTP spécifique à ClickHouse avec mise en cache et routage intégrés.
- HAProxy - Répartiteur de charge TCP/HTTP à usage général.
- NGINX - Serveur web avec fonctionnalités de répartition de charge.
- Répartiteurs de charge des fournisseurs cloud (AWS Application Load Balancer, GCP Load Balancer, Azure Load Balancer).

Exemple de configuration chproxy de base :

```yaml
server:
  http:
    listen_addr: ":8080"

clusters:
  - name: "clickhouse_cluster"
    nodes: [
      "http://ch-node1:8123",
      "http://ch-node2:8123",
      "http://ch-node3:8123"
    ]

users:
  - name: "gitlab"
    password: "your_secure_password"
    to_cluster: "clickhouse_cluster"
    to_user: "gitlab"
```

Lorsque vous utilisez un répartiteur de charge, configurez GitLab pour qu'il se connecte à l'URL du répartiteur de charge plutôt qu'aux nœuds ClickHouse individuels.

Pour plus d'informations, consultez la [documentation chproxy](https://www.chproxy.org/).

Après avoir configuré votre instance ClickHouse pour GitLab Self-Managed, [créez la base de données et l'utilisateur GitLab](#create-database-and-user).

### Vérifier l'installation de ClickHouse {#verify-clickhouse-installation}

Avant de configurer la base de données, vérifiez que ClickHouse est installé et accessible :

1. Vérifiez que ClickHouse est en cours d'exécution :

   ```shell
   clickhouse-client --query "SELECT version()"
   ```

   Si ClickHouse est en cours d'exécution, le numéro de version s'affiche (par exemple, `24.3.1.12`).
1. Vérifiez que vous pouvez vous connecter avec des identifiants :

   ```shell
   clickhouse-client --host your-clickhouse-host --port 9440 --secure --user default --password 'your-password'
   ```

   > [!note]
   > Si vous n'avez pas encore configuré TLS, utilisez le port `9000` sans l'indicateur `--secure` pour les tests initiaux.

### Créer la base de données et l'utilisateur {#create-database-and-user}

Pour créer les objets de base de données et d'utilisateur nécessaires :

1. Générez un mot de passe sécurisé et enregistrez-le.
1. Connectez-vous à :
   - Pour ClickHouse Cloud, la console SQL ClickHouse.
   - Pour ClickHouse avec GitLab Self-Managed, le `clickhouse-client`.
1. Exécutez les commandes suivantes en remplaçant `PASSWORD_HERE` par le mot de passe généré.

{{< tabs >}}

{{< tab title="Nœud unique ou ClickHouse Cloud" >}}

```sql
CREATE DATABASE gitlab_clickhouse_main_production;
CREATE USER gitlab IDENTIFIED WITH sha256_password BY 'PASSWORD_HERE';
CREATE ROLE gitlab_app;
GRANT SELECT, INSERT, ALTER, CREATE, UPDATE, DROP, TRUNCATE, OPTIMIZE, dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app;
GRANT SELECT ON information_schema.* TO gitlab_app;
GRANT gitlab_app TO gitlab;
```

{{< /tab >}}

{{< tab title="ClickHouse HA pour GitLab Self-Managed" >}}

Remplacez `CLUSTER_NAME_HERE` par le nom de votre cluster :

```sql
CREATE DATABASE gitlab_clickhouse_main_production ON CLUSTER CLUSTER_NAME_HERE ENGINE = Replicated('/clickhouse/databases/{cluster}/gitlab_clickhouse_main_production', '{shard}', '{replica}');
CREATE USER gitlab IDENTIFIED WITH sha256_password BY 'PASSWORD_HERE' ON CLUSTER CLUSTER_NAME_HERE;
CREATE ROLE gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
GRANT SELECT, INSERT, ALTER, CREATE, UPDATE, DROP, TRUNCATE, OPTIMIZE, dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
GRANT SELECT ON information_schema.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
GRANT gitlab_app TO gitlab ON CLUSTER CLUSTER_NAME_HERE;
```

{{< /tab >}}

{{< /tabs >}}

### Configurer la connexion GitLab {#configure-the-gitlab-connection}

{{< tabs >}}

{{< tab title="Package Linux" >}}

Pour fournir à GitLab les identifiants ClickHouse :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['clickhouse_databases']['main']['database'] = 'gitlab_clickhouse_main_production'
   gitlab_rails['clickhouse_databases']['main']['url'] = 'https://your-clickhouse-host:port'
   gitlab_rails['clickhouse_databases']['main']['username'] = 'gitlab'
   gitlab_rails['clickhouse_databases']['main']['password'] = 'PASSWORD_HERE' # replace with the actual password
   ```

   Remplacez l'URL par :
   - Pour ClickHouse Cloud : `https://your-service.clickhouse.cloud:8443`
   - ClickHouse pour GitLab Self-Managed : `https://your-clickhouse-host:8443`
   - Pour ClickHouse pour GitLab Self-Managed HA avec répartiteur de charge : `https://your-load-balancer:8080` (ou l'URL de votre répartiteur de charge)

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Enregistrez le mot de passe ClickHouse en tant que secret Kubernetes :

   ```shell
   kubectl create secret generic gitlab-clickhouse-password --from-literal="main_password=PASSWORD_HERE"
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     clickhouse:
       enabled: true
       main:
         username: gitlab
         password:
           secret: gitlab-clickhouse-password
           key: main_password
         database: gitlab_clickhouse_main_production
         url: 'https://your-clickhouse-host:port'
   ```

   Remplacez l'URL par :
   - Pour ClickHouse Cloud : `https://your-service.clickhouse.cloud:8443`
   - Pour ClickHouse pour GitLab Self-Managed nœud unique : `https://your-clickhouse-host:8443`
   - Pour ClickHouse pour GitLab Self-Managed HA avec répartiteur de charge : `https://your-load-balancer:8080` (ou l'URL de votre répartiteur de charge)

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

> [!note]
> Pour les déploiements en production, configurez TLS/SSL sur votre instance ClickHouse et utilisez des URL `https://`. Pour les installations GitLab Self-Managed, consultez la documentation [Sécurité réseau](#network-security).

### Vérifier la connexion {#verify-the-connection}

Pour vérifier que votre connexion est correctement configurée :

1. Connectez-vous à la [console Rails](../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Exécutez la commande suivante :

   ```ruby
   ClickHouse::Client.select('SELECT 1', :main)
   ```

   En cas de succès, la commande retourne `[{"1"=>1}]`.

Si la connexion échoue, vérifiez :

- Le service ClickHouse est en cours d'exécution et accessible.
- La connectivité réseau entre GitLab et ClickHouse. Vérifiez que les pare-feux et les groupes de sécurité autorisent les connexions.
- L'URL de connexion est correcte (hôte, port, protocole).
- Les identifiants sont corrects.
- Pour les déploiements en cluster HA : le répartiteur de charge est correctement configuré et achemine les requêtes.

### Exécuter les migrations ClickHouse {#run-clickhouse-migrations}

> [!note]
> Cette étape est obligatoire. Si vous la sautez, les tableaux de bord Analytics n'affichent pas de données et affichent une erreur « Failed to fetch data ».

{{< tabs >}}

{{< tab title="Package Linux" >}}

Pour créer les objets de base de données requis, exécutez :

```shell
sudo gitlab-rake gitlab:clickhouse:migrate
```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

Les migrations sont exécutées automatiquement avec le [chart GitLab-Migrations](https://docs.gitlab.com/charts/charts/gitlab/migrations/).

Vous pouvez également exécuter les migrations en lançant la commande suivante dans le pod Toolbox :

```shell
gitlab-rake gitlab:clickhouse:migrate
```

{{< /tab >}}

{{< /tabs >}}

### Activer ClickHouse pour Analytics {#enable-clickhouse-for-analytics}

Une fois votre instance GitLab connectée à ClickHouse, vous pouvez activer les fonctionnalités qui utilisent ClickHouse :

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.
- La connexion ClickHouse est configurée et vérifiée.
- Les migrations ont été effectuées avec succès.

Pour activer ClickHouse pour Analytics :

1. Dans la barre latérale gauche, en bas, sélectionnez **Admin**.
1. Sélectionnez **Paramètres** > **Généralités**.
1. Développez **ClickHouse**.
1. Sélectionnez **Enable ClickHouse for Analytics**.
1. Sélectionnez **Enregistrer les modifications**.

### Désactiver ClickHouse pour Analytics {#disable-clickhouse-for-analytics}

Pour désactiver ClickHouse pour Analytics :

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour désactiver :

1. Dans la barre latérale gauche, en bas, sélectionnez **Admin**.
1. Sélectionnez **Paramètres** > **Généralités**.
1. Développez **ClickHouse**.
1. Décochez la case **Enable ClickHouse for Analytics**.
1. Sélectionnez **Enregistrer les modifications**.

> [!note]
> La désactivation de ClickHouse pour Analytics empêche GitLab d'interroger ClickHouse, mais ne supprime aucune donnée de votre instance ClickHouse. Les fonctionnalités d'analytique qui dépendent de ClickHouse se replieront sur des sources de données alternatives ou deviendront indisponibles.

## Mettre à niveau ClickHouse {#upgrade-clickhouse}

### ClickHouse Cloud {#clickhouse-cloud}

ClickHouse Cloud gère automatiquement les mises à niveau de version et les correctifs de sécurité. Aucune intervention manuelle n'est requise.

Pour des informations sur la planification des mises à niveau et les fenêtres de maintenance, consultez [les mises à niveau de ClickHouse Cloud](https://clickhouse.com/docs/manage/updates).

> [!note]
> ClickHouse Cloud vous notifie à l'avance des mises à niveau à venir. Consultez le [journal des modifications de ClickHouse Cloud](https://clickhouse.com/docs/whats-new/cloud) pour rester informé des nouvelles fonctionnalités et des changements.

### ClickHouse pour GitLab Self-Managed (BYOC) {#clickhouse-for-gitlab-self-managed-byoc}

Pour ClickHouse avec GitLab Self-Managed, vous êtes responsable de la planification et de l'exécution des mises à niveau de version.

Prérequis :

- Disposer d'un accès administrateur à l'instance ClickHouse.
- Sauvegardez vos données avant la mise à niveau. Consultez [Reprise après sinistre](#disaster-recovery).

Avant la mise à niveau :

1. Consultez les [notes de release ClickHouse](https://clickhouse.com/docs/category/changelog) pour identifier les changements incompatibles.
1. Vérifiez la [compatibilité](#supported-clickhouse-versions) avec votre version de GitLab.
1. Testez la mise à niveau dans un environnement non destiné à la production.
1. Planifiez les temps d'arrêt potentiels ou utilisez une stratégie de mise à niveau progressive pour les clusters HA.

Pour mettre à niveau ClickHouse :

1. Pour les déploiements à nœud unique, suivez la [documentation de mise à niveau de ClickHouse](https://clickhouse.com/docs/manage/updates).
1. Pour les déploiements en cluster HA, effectuez une mise à niveau progressive pour minimiser les temps d'arrêt :
   - Mettez à niveau un nœud à la fois.
   - Attendez que le nœud rejoigne le cluster.
   - Vérifiez l'état du cluster avant de passer au nœud suivant.

> [!warning]
> Assurez-vous toujours que la version de ClickHouse reste compatible avec votre version de GitLab. Des versions incompatibles peuvent provoquer la mise en pause de l'indexation et l'échec de fonctionnalités. Pour plus d'informations, consultez [les versions de ClickHouse prises en charge](#supported-clickhouse-versions)

Pour les procédures de mise à niveau détaillées, consultez la [documentation ClickHouse sur les mises à jour](https://clickhouse.com/docs/manage/updates).

## Opérations {#operations}

### Vérifier le statut des migrations {#check-migration-status}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour vérifier le statut des migrations ClickHouse :

1. Dans la barre latérale gauche, en bas, sélectionnez **Admin**.
1. Sélectionnez **Paramètres** > **Généralités**.
1. Développez **ClickHouse**.
1. Consultez la section **Migration status** si disponible.

Vous pouvez également vérifier les migrations en attente à l'aide de la console Rails :

```ruby
# Sign in to Rails console
# Run this to check migrations
ClickHouse::MigrationSupport::Migrator.new(:main).pending_migrations
```

### Relancer les migrations ayant échoué {#retry-failed-migrations}

Si une migration ClickHouse échoue :

1. Consultez les journaux pour obtenir les détails de l'erreur. Les erreurs liées à ClickHouse sont enregistrées dans les journaux de l'application GitLab.
1. Résolvez le problème sous-jacent (par exemple, mémoire insuffisante, problèmes de connectivité).
1. Relancez la migration :

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:clickhouse:migrate

   # For self-compiled installations
   bundle exec rake gitlab:clickhouse:migrate RAILS_ENV=production
   ```

> [!note]
> Les migrations sont conçues pour être idempotentes et peuvent être relancées en toute sécurité. Si une migration échoue en cours d'exécution, la relancer la reprend là où elle s'est arrêtée ou ignore les étapes déjà effectuées.

## Tâches Rake ClickHouse {#clickhouse-rake-tasks}

GitLab fournit plusieurs tâches Rake pour gérer votre base de données ClickHouse.

Les tâches Rake suivantes sont disponibles :

| Tâche | Description |
|------|-------------|
| [`sudo gitlab-rake gitlab:clickhouse:migrate`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | Exécute toutes les migrations ClickHouse en attente pour créer ou mettre à jour le schéma de base de données. |
| [`sudo gitlab-rake gitlab:clickhouse:drop`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | Supprime toutes les bases de données ClickHouse. À utiliser avec une extrême prudence car cela supprime toutes les données. |
| [`sudo gitlab-rake gitlab:clickhouse:create`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | Crée les bases de données ClickHouse si elles n'existent pas. |
| [`sudo gitlab-rake gitlab:clickhouse:setup`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | Crée les bases de données et exécute toutes les migrations. Équivaut à l'exécution des tâches `create` et `migrate`. |
| [`sudo gitlab-rake gitlab:clickhouse:schema:dump`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | Exporte le schéma de base de données actuel dans un fichier à des fins de sauvegarde ou de contrôle de version. |
| [`sudo gitlab-rake gitlab:clickhouse:schema:load`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | Charge le schéma de base de données depuis un fichier de dump. |

> [!note]
> Pour les installations compilées depuis les sources, utilisez `bundle exec rake` à la place de `sudo gitlab-rake` et ajoutez `RAILS_ENV=production` à la fin de la commande.

### Exemples de tâches courantes {#common-task-examples}

#### Vérifier la connexion et le schéma ClickHouse {#verify-clickhouse-connection-and-schema}

Pour vérifier que votre connexion ClickHouse fonctionne :

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:clickhouse:info

# For self-compiled installations
bundle exec rake gitlab:clickhouse:info RAILS_ENV=production
```

Cette tâche affiche des informations de débogage sur la connexion et la configuration ClickHouse.

#### Réexécuter toutes les migrations {#re-run-all-migrations}

Pour exécuter toutes les migrations en attente :

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:clickhouse:migrate

# For self-compiled installations
bundle exec rake gitlab:clickhouse:migrate RAILS_ENV=production
```

#### Réinitialiser la base de données {#reset-the-database}

> [!warning]
> Cela supprime toutes les données de votre base de données ClickHouse. À utiliser uniquement en développement ou lors du dépannage.

Pour supprimer et recréer la base de données :

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:clickhouse:drop
sudo gitlab-rake gitlab:clickhouse:setup

# For self-compiled installations
bundle exec rake gitlab:clickhouse:drop RAILS_ENV=production
bundle exec rake gitlab:clickhouse:setup RAILS_ENV=production
```

### Variables d'environnement {#environment-variables}

Vous pouvez utiliser des variables d'environnement pour contrôler le comportement des tâches Rake :

| Variable d'environnement | Type de données | Description |
|---------------------|-----------|-------------|
| `VERBOSE` | Booléen | Définissez sur `true` pour afficher une sortie détaillée pendant les migrations. Exemple : `VERBOSE=true sudo gitlab-rake gitlab:clickhouse:migrate` |

## Optimisation des performances {#performance-tuning}

> [!note]
> Pour le dimensionnement des ressources et les recommandations de déploiement en fonction du nombre d'utilisateurs, consultez [la configuration requise](#system-requirements).

Pour des informations sur l'architecture de ClickHouse et l'optimisation des performances, consultez la [documentation ClickHouse sur l'architecture](https://clickhouse.com/docs/architecture/introduction).

## Reprise après sinistre {#disaster-recovery}

### Sauvegarde et restauration {#backup-and-restore}

Vous devez effectuer une sauvegarde complète avant de mettre à niveau l'application GitLab. Les données ClickHouse ne sont pas incluses dans les outils de sauvegarde GitLab.

La stratégie de sauvegarde et de restauration dépend du choix de déploiement.

#### ClickHouse Cloud {#clickhouse-cloud-1}

ClickHouse Cloud gère automatiquement :

- Les sauvegardes et les restaurations.
- La création et la conservation de sauvegardes quotidiennes.

Aucune configuration supplémentaire n'est nécessaire.

Pour plus d'informations, consultez [les sauvegardes ClickHouse Cloud](https://clickhouse.com/docs/cloud/manage/backups).

#### ClickHouse pour GitLab Self-Managed {#clickhouse-for-gitlab-self-managed}

Si vous gérez votre propre instance ClickHouse, vous devez effectuer des sauvegardes régulières pour garantir la sécurité des données :

- Effectuez des sauvegardes complètes initiales des tables (à l'exclusion des tables système comme `metrics` ou `logs`) vers un [bucket de stockage d'objets, par exemple AWS S3](https://clickhouse.com/docs/en/operations/backup#configuring-backuprestore-to-use-an-s3-endpoint).
- Effectuez des [sauvegardes incrémentielles](https://clickhouse.com/docs/en/operations/backup#take-an-incremental-backup) après cette sauvegarde complète initiale.

Cela duplique les données pour chaque sauvegarde complète, mais représente l'[approche la plus simple pour restaurer les données](https://clickhouse.com/docs/en/operations/backup#restore-from-the-incremental-backup).

Vous pouvez également utiliser [`clickhouse-backup`](https://github.com/Altinity/clickhouse-backup). Il s'agit d'un outil tiers qui offre des fonctionnalités similaires avec des fonctions supplémentaires telles que la planification et la gestion du stockage distant.

## Surveillance {#monitoring}

Pour garantir la stabilité de l'intégration GitLab, vous devez surveiller l'état et les performances de votre cluster ClickHouse.

### ClickHouse Cloud {#clickhouse-cloud-2}

ClickHouse Cloud fournit une [intégration Prometheus](https://clickhouse.com/docs/integrations/prometheus) native qui expose les métriques via un endpoint d'API sécurisé.

Après avoir généré les identifiants d'API, vous pouvez configurer des collecteurs pour récupérer les métriques de ClickHouse Cloud. Par exemple, un [déploiement Prometheus](https://clickhouse.com/docs/integrations/prometheus#configuring-prometheus).

### ClickHouse pour GitLab Self-Managed {#clickhouse-for-gitlab-self-managed-1}

ClickHouse peut exposer des [métriques au format Prometheus](https://clickhouse.com/docs/operations/server-configuration-parameters/settings#prometheus). Pour activer cela :

1. Configurez la section `prometheus` dans votre `config.xml` pour exposer les métriques sur un port dédié (la valeur par défaut est `9363`).

   ```xml
   <prometheus>
       <endpoint>/metrics</endpoint>
       <port>9363</port>
       <metrics>true</metrics>
       <events>true</events>
       <asynchronous_metrics>true</asynchronous_metrics>
   </prometheus>
   ```

1. Configurez Prometheus ou un serveur compatible similaire pour récupérer `http://<clickhouse-host>:9363/metrics`.

### Métriques à surveiller {#metrics-to-monitor}

Vous devez configurer des alertes pour les métriques suivantes afin de détecter les problèmes susceptibles d'affecter les fonctionnalités GitLab :

| Nom de la métrique | Description | Seuil d'alerte (recommandation) |
| :--- | :--- | :--- |
| `ClickHouse_Metrics_Query` | Nombre de requêtes en cours d'exécution. Une hausse soudaine peut indiquer un goulot d'étranglement des performances. | Déviation de la baseline (par exemple `> 100`) |
| `ClickHouseProfileEvents_FailedSelectQuery` | Nombre de requêtes SELECT ayant échoué | Déviation de la baseline (par exemple `> 50`) |
| `ClickHouseProfileEvents_FailedInsertQuery` | Nombre de requêtes INSERT ayant échoué | Déviation de la baseline (par exemple `> 10`) |
| `ClickHouse_AsyncMetrics_ReadonlyReplica` | Indique si un réplica est passé en mode lecture seule (souvent en raison d'une perte de connexion à ZooKeeper). | `> 0` (prendre des mesures immédiates) |
| `ClickHouse_ProfileEvents_NetworkErrors` | Erreurs réseau (réinitialisations/délais d'expiration de connexion). Des erreurs fréquentes peuvent provoquer l'échec des jobs d'arrière-plan GitLab. | Taux `> 0` |

### Vérification de disponibilité {#liveness-check}

Si ClickHouse est disponible derrière un répartiteur de charge, vous pouvez utiliser l'endpoint HTTP `/ping` pour vérifier la disponibilité. La réponse attendue est `Ok` avec le code HTTP 200.

## Sécurité et audit {#security-and-auditing}

Pour garantir la sécurité de vos données et l'auditabilité, appliquez les pratiques de sécurité suivantes.

### Sécurité réseau {#network-security}

- Chiffrement TLS : configurez les serveurs ClickHouse pour [utiliser le chiffrement TLS](#network-security) afin de valider les connexions.

  Lors de la configuration de l'URL de connexion dans GitLab, vous devez utiliser le protocole `https://` (par exemple, `https://clickhouse.example.com:8443`) pour le spécifier.
- Listes d'autorisation IP : limitez l'accès au port ClickHouse (par défaut `8443` ou `9440`) aux seuls nœuds de l'application GitLab et aux autres réseaux autorisés.

### Journalisation des audits {#audit-logging}

L'application GitLab ne tient pas de journal d'audit distinct pour les requêtes ClickHouse individuelles. Pour satisfaire des exigences spécifiques concernant l'accès aux données (qui a interrogé quoi et quand), vous pouvez activer la journalisation côté ClickHouse.

#### ClickHouse Cloud {#clickhouse-cloud-3}

Dans ClickHouse Cloud, la journalisation des requêtes est activée par défaut. Vous pouvez accéder à ces journaux en interrogeant la table `system.query_log`.

#### ClickHouse pour GitLab Self-Managed {#clickhouse-for-gitlab-self-managed-2}

Pour les instances auto-gérées, assurez-vous que le paramètre de configuration `query_log` est activé dans la configuration de votre serveur :

1. Vérifiez que la section `query_log` existe dans votre `config.xml` ou `users.xml` :

   ```xml
   <query_log>
       <database>system</database>
       <table>query_log</table>
       <partition_by>toYYYYMM(event_date)</partition_by>
       <flush_interval_milliseconds>7500</flush_interval_milliseconds>
       <ttl>event_date + INTERVAL 30 DAY</ttl>  <!-- Keep only 30 days -->
   </query_log>
   ```

1. Une fois activé, toutes les requêtes exécutées sont enregistrées dans la table `system.query_log`, permettant une piste d'audit.

## Configuration requise {#system-requirements}

La configuration système recommandée varie en fonction du nombre d'utilisateurs.

### Référence rapide de la matrice de décision de déploiement {#deployment-decision-matrix-quick-reference}

| Utilisateurs | Recommandation principale | Instance AWS ARM comparable | Instance GCP ARM comparable | Instance Azure ARM comparable | Type de déploiement |
|---|---|---|---|---|---|
| 1 000 | ClickHouse Cloud Basic | - | - | - | Géré |
| 2 000 | ClickHouse Cloud Basic | `m8g.xlarge` | `c4a-standard-4` |  `Standard_D4ps_v6` | Géré ou nœud unique |
| 3 000 | ClickHouse Cloud Scale | `m8g.2xlarge` | `c4a-standard-8` | `Standard_D8ps_v6` | Géré ou nœud unique |
| 5 000 | ClickHouse Cloud Scale | `m8g.4xlarge` | `c4a-standard-16` | `Standard_D16ps_v6` | Géré ou nœud unique |
| 10 000 | ClickHouse Cloud Scale | `m8g.4xlarge` | `c4a-standard-16` | `Standard_D16ps_v6` | Géré ou nœud unique/HA |
| 25 000 | ClickHouse pour GitLab Self-Managed ou ClickHouse Cloud Scale | `m8g.8xlarge` ou 3×`m8g.4xlarge` | `c4a-standard-32` ou 3×`c4a-standard-16` | `Standard_D32ps_v6` ou 3x`Standard_D16ps_v6` | Géré ou nœud unique/HA |
| 50 000 | ClickHouse pour GitLab Self-Managed en haute disponibilité (HA) ou ClickHouse Cloud Scale | 3×`m8g.4xlarge` | 3×`c4a-standard-16` | 3x`Standard_D16ps_v6` | Géré ou cluster HA |

### 1 000 utilisateurs {#1k-users}

Recommandation : ClickHouse Cloud Basic offrant une bonne rentabilité sans complexité opérationnelle.

### 2 000 utilisateurs {#2k-users}

Recommandation : ClickHouse Cloud Basic offrant le meilleur rapport qualité-prix sans complexité opérationnelle.

Recommandation alternative pour le déploiement ClickHouse sur GitLab Self-Managed :

- AWS : m8g.xlarge (4 vCPU, 16 Go)
- GCP : c4a-standard-4 ou n4-standard-4 (4 vCPU, 16 Go)
- Azure : Standard_D4ps_v6 (4 vCPU, 16 Go)
- Stockage : 20 Go avec un niveau de performances faible à moyen

### 3 000 utilisateurs {#3k-users}

Recommandation : ClickHouse Cloud Scale

Recommandation alternative pour le déploiement ClickHouse sur GitLab Self-Managed :

- AWS : m8g.2xlarge (8 vCPU, 32 Go)
- GCP : c4a-standard-8 ou n4-standard-8 (8 vCPU, 32 Go)
- Azure : Standard_D8ps_v6 (8 vCPU, 32 Go)
- Stockage : 100 Go avec un niveau de performances moyen

> [!note]
> Les déploiements HA ne sont pas rentables à cette échelle.

### 5 000 utilisateurs {#5k-users}

Recommandation : ClickHouse Cloud Scale

Recommandation alternative pour le déploiement ClickHouse sur GitLab Self-Managed :

- AWS : m8g.4xlarge (16 vCPU, 64 Go)
- GCP : c4a-standard-16 ou n4-standard-16 (16 vCPU, 64 Go)
- Azure : Standard_D16ps_v6 (16 vCPU, 64 Go)
- Stockage : 100 Go avec un niveau de performances élevé
- Déploiement : nœud unique recommandé

### 10 000 utilisateurs {#10k-users}

Recommandation : ClickHouse Cloud Scale

Recommandation alternative pour le déploiement ClickHouse sur GitLab Self-Managed :

- AWS : m8g.4xlarge (16 vCPU, 64 Go)
- GCP : c4a-standard-16 ou n4-standard-16 (16 vCPU, 64 Go)
- Azure : Standard_D16ps_v6 (16 vCPU, 64 Go)
- Stockage : 200 Go avec un niveau de performances élevé
- Option HA : un cluster à 3 nœuds devient viable pour les charges de travail critiques

### 25 000 utilisateurs {#25k-users}

Recommandation : ClickHouse Cloud Scale ou ClickHouse pour GitLab Self-Managed. Les deux options sont économiquement viables à cette échelle.

Recommandations pour le déploiement ClickHouse sur GitLab Self-Managed :

- Nœud unique :

  - AWS : m8g.8xlarge (32 vCPU, 128 Go)
  - GCP : c4a-standard-32 ou n4-standard-32 (32 vCPU, 128 Go)
  - Azure : Standard_D32ps_v6 (32 vCPU, 128 Go)
- Déploiement HA :

  - AWS : 3 × m8g.4xlarge (16 vCPU, 64 Go chacun)
  - GCP : 3 × c4a-standard-16 ou 3 × n4-standard-16 (16 vCPU, 64 Go chacun)
  - Azure : 3 x Standard_D16ps_v6 (16 vCPU, 64 Go chacun)
- Stockage : 400 Go par nœud avec un niveau de performances élevé.

### 50 000 utilisateurs {#50k-users}

Recommandation : ClickHouse pour GitLab Self-Managed HA ou ClickHouse Cloud Scale. L'option auto-gérée est légèrement plus rentable à cette échelle.

Recommandations pour le déploiement ClickHouse sur GitLab Self-Managed :

- Nœud unique :

  - AWS : m8g.8xlarge (32 vCPU, 128 Go)
  - GCP : c4a-standard-32 ou n4-standard-32 (32 vCPU, 128 Go)
  - Azure : Standard_D32ps_v6 (32 vCPU, 128 Go)
- Déploiement HA (recommandé) :

  - AWS : 3 × m8g.4xlarge (16 vCPU, 64 Go chacun)
  - GCP : 3 × c4a-standard-16 ou 3 × n4-standard-16 (16 vCPU, 64 Go chacun)
  - Azure : 3 x Standard_D16ps_v6 (16 vCPU, 64 Go chacun)
- Stockage : 1 000 Go par nœud avec un niveau de performances élevé.

#### Considérations HA pour le déploiement ClickHouse sur GitLab Self-Managed {#ha-considerations-for-clickhouse-for-gitlab-self-managed-deployment}

La configuration HA devient rentable uniquement à partir de 10 000 utilisateurs.

- Minimum : trois nœuds ClickHouse pour le quorum.
- [ClickHouse Keeper](https://clickhouse.com/clickhouse/keeper) : trois nœuds pour la coordination (peuvent être colocalisés ou séparés).
- Répartiteur de charge : recommandé pour la distribution des requêtes.
- Réseau : une connectivité à faible latence entre les nœuds est essentielle.

## Glossaire {#glossary}

- Cluster : un ensemble de nœuds (serveurs) qui travaillent ensemble pour stocker et traiter les données.
- MergeTree : [`MergeTree`](https://clickhouse.com/docs/engines/table-engines/mergetree-family/mergetree) est un moteur de table dans ClickHouse conçu pour des taux d'ingestion de données élevés et de grands volumes de données. Il s'agit du moteur de stockage principal de ClickHouse, offrant des fonctionnalités telles que le stockage en colonnes, le partitionnement personnalisé, les index primaires épars et la prise en charge des fusions de données en arrière-plan.
- Parts : un fichier physique sur un disque qui stocke une partie des données de la table. Une part est différente d'une partition, qui est une division logique des données d'une table créée à l'aide d'une clé de partition.
- Replica : une copie des données stockées dans une base de données ClickHouse. Vous pouvez avoir n'importe quel nombre de réplicas des mêmes données pour assurer la redondance et la fiabilité. Les réplicas sont utilisés conjointement avec le moteur de table ReplicatedMergeTree, qui permet à ClickHouse de maintenir plusieurs copies de données synchronisées sur différents serveurs.
- Shard : un sous-ensemble de données. ClickHouse dispose toujours d'au moins un shard pour vos données. Si vous ne répartissez pas les données sur plusieurs serveurs, vos données sont stockées dans un seul shard. Le sharding des données sur plusieurs serveurs peut être utilisé pour diviser la charge si vous dépassez la capacité d'un seul serveur.
- TTL (Time To Live) : le Time To Live (TTL) est une fonctionnalité ClickHouse qui déplace, supprime ou consolide automatiquement des colonnes/lignes après une certaine période. Cela vous permet de gérer le stockage plus efficacement car vous pouvez supprimer, déplacer ou archiver les données auxquelles vous n'avez plus besoin d'accéder fréquemment.

## Dépannage {#troubleshooting}

### Migrations du schéma de base de données sur GitLab 18.0.0 et versions antérieures {#database-schema-migrations-on-gitlab-1800-and-earlier}

> [!warning]
> Sur GitLab 18.0.0 et versions antérieures, l'exécution des migrations du schéma de base de données pour ClickHouse peut échouer pour ClickHouse 24.x et 25.x avec le message d'erreur suivant :
>
> ```plaintext
> Code: 344. DB::Exception: Projection is fully supported in ReplacingMergeTree with deduplicate_merge_projection_mode = throw. Use 'drop' or 'rebuild' option of deduplicate_merge_projection_mode
> ```
>
> Sans l'exécution de toutes les migrations, l'intégration ClickHouse ne fonctionnera pas.

Pour contourner ce problème et exécuter les migrations :

1. Connectez-vous à la [console Rails](../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Exécutez la commande suivante :

   ```ruby
   ClickHouse::Client.execute("INSERT INTO schema_migrations (version) VALUES ('20231114142100'), ('20240115162101')", :main)
   ```

1. Migrez à nouveau la base de données :

   ```shell
   sudo gitlab-rake gitlab:clickhouse:migrate
   ```

Cette fois, la migration de la base de données devrait se terminer avec succès.

### Prise en charge de la lecture du dictionnaire de base de données {#database-dictionary-read-support}

À partir de GitLab 18.8, GitLab commence à utiliser les [dictionnaires ClickHouse](https://clickhouse.com/docs/dictionary) pour la dénormalisation des données. Les instructions `GRANT` antérieures à 18.8 n'accordaient pas à l'utilisateur `gitlab` la permission d'interroger les dictionnaires, une étape de modification manuelle est donc nécessaire :

1. Connectez-vous à :
   - Pour ClickHouse Cloud, la console SQL ClickHouse.
   - Pour ClickHouse avec GitLab Self-Managed, le `clickhouse-client`.
1. Exécutez les commandes suivantes en remplaçant `PASSWORD_HERE` par le mot de passe généré.

{{< tabs >}}

{{< tab title="Nœud unique ou ClickHouse Cloud" >}}

```sql
GRANT dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app;
```

{{< /tab >}}

{{< tab title="ClickHouse HA pour GitLab Self-Managed" >}}

Remplacez `CLUSTER_NAME_HERE` par le nom de votre cluster :

```sql
GRANT dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
```

{{< /tab >}}

{{< /tabs >}}

Sans l'octroi de cette permission, la migration ClickHouse (`CreateNamespaceTraversalPathsDict`) échouera avec l'erreur suivante :

```plaintext
DB::Exception: gitlab: Not enough privileges.
```

Après avoir accordé la permission, la migration peut être relancée en toute sécurité (idéalement, attendez 1 à 2 heures que le verrou de migration distribué soit libéré).

### Incohérences de données dans les vues matérialisées des données des jobs CI ClickHouse {#clickhouse-ci-job-data-materialized-view-data-inconsistencies}

Dans GitLab 18.5 et versions antérieures, des données en double pouvaient être insérées dans les tables ClickHouse (telles que `ci_finished_pipelines` et `ci_finished_builds`) lorsque les workers Sidekiq relançaient des requêtes après des délais d'expiration réseau. Ce problème entraînait l'affichage de métriques agrégées incorrectes dans les tableaux de bord d'analytique par les vues matérialisées, y compris le tableau de bord de la flotte de runners.

Ce problème a été corrigé dans GitLab 18.9 et reporté dans les versions 18.6, 18.7 et 18.8. Pour résoudre ce problème, mettez à niveau vers GitLab 18.6 ou une version ultérieure.

Si vous disposez de données en double existantes, un correctif pour reconstruire les vues matérialisées affectées est prévu pour GitLab 18.10 dans le [ticket 586319](https://gitlab.com/gitlab-org/gitlab/-/issues/586319). Pour obtenir de l'aide, contactez le support GitLab.
