---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo
description: Distribuer GitLab géographiquement.
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Geo est la solution pour les équipes de développement largement distribuées et pour fournir un système de secours à chaud dans le cadre d'une stratégie de reprise après sinistre. Geo n'est **not** une solution HA prête à l'emploi.

> [!warning]
> Geo subit des changements importants d'une release à l'autre. Les mises à niveau sont prises en charge et [documentées](#upgrading-geo), mais vous devez vous assurer que vous utilisez la bonne version de la documentation pour votre installation.

Pour vous assurer que vous utilisez la bonne version de la documentation, accédez à [la page Geo sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/geo/_index.md) et choisissez la release appropriée dans la liste déroulante **Changer de branche/d'étiquette**. Par exemple, [`v15.7.6-ee`](https://gitlab.com/gitlab-org/gitlab/-/blob/v15.7.6-ee/doc/administration/geo/_index.md).

La récupération de grands dépôts peut prendre beaucoup de temps pour les équipes et les runners situés loin d'une instance GitLab unique.

Geo fournit des caches locaux qui peuvent être placés géographiquement près des équipes distantes et qui peuvent répondre aux requêtes de lecture. Cela peut réduire le temps nécessaire pour cloner et récupérer de grands dépôts, accélérant le développement et augmentant la productivité de vos équipes distantes.

Les sites secondaires Geo transfèrent de manière transparente les requêtes d'écriture vers le site principal. Tous les sites Geo peuvent être configurés pour répondre à une seule URL GitLab, afin de fournir une expérience cohérente, fluide et complète quel que soit le site sur lequel l'utilisateur arrive.

Geo utilise un ensemble de termes définis qui sont décrits dans le [Glossaire Geo](glossary.md). Assurez-vous de vous familiariser avec ces termes.

## Cas d'utilisation {#use-cases}

La mise en œuvre de Geo répond à plusieurs cas d'utilisation. Cette section présente quelques-uns des cas d'utilisation prévus et met en évidence leurs avantages.

### Reprise après sinistre régionale {#regional-disaster-recovery}

Geo en tant que solution de [reprise après sinistre](disaster_recovery/_index.md) vous offre un site secondaire à chaud dans une région différente de votre site principal. Les données sont continuellement synchronisées vers le site secondaire, garantissant qu'il est toujours à jour. En cas de sinistre, tel qu'une panne du centre de données, du réseau ou une défaillance matérielle, vous pouvez basculer vers un site secondaire entièrement opérationnel. Vous pouvez tester vos processus de reprise après sinistre et votre infrastructure avec des [basculements planifiés](disaster_recovery/planned_failover.md).

Avantages :

- Continuité des activités en cas de sinistre régional.
- Faibles objectifs de temps de récupération (RTO) et de point de récupération (RPO).
- Basculement automatisé (mais non automatique) avec GitLab Environment Toolkit (GET).
- Effort opérationnel minimal - La réplication et la vérification continues non assistées garantissent que vos sites secondaires sont à jour et que les données répliquées ne sont pas corrompues pendant le transit et au repos.

### Accélération des équipes distantes {#remote-team-acceleration}

Établissez des sites secondaires Geo géographiquement plus proches de vos équipes distantes pour fournir des caches locaux qui accélèrent les opérations de lecture. Vous pouvez avoir plusieurs sites secondaires Geo, chacun configuré pour synchroniser uniquement les projets dont vos équipes distantes ont besoin. [Le proxy transparent](secondary_proxy/_index.md) et le routage géographique avec une [URL unifiée](replication/location_aware_git_url.md) garantissent une expérience de développement cohérente et fluide.

Avantages :

- Améliorez l'expérience GitLab pour les équipes géographiquement distribuées. Geo offre une expérience GitLab complète sur les sites secondaires : maintenez un site GitLab principal tout en activant les sites secondaires avec un accès en lecture-écriture et une expérience d'interface utilisateur complète pour chacune de vos équipes distribuées.
- Réduisez de quelques minutes à quelques secondes le temps nécessaire à vos développeurs distribués pour cloner et récupérer de grands dépôts et projets.
- Permettez à tous vos développeurs de contribuer des idées et de travailler en parallèle, peu importe où ils se trouvent.
- Équilibrez la charge de lecture entre vos sites principal et secondaires.
- Surmontez les connexions lentes entre des bureaux distants, en gagnant du temps grâce à l'amélioration de la vitesse pour les équipes distribuées.
- Réduisez le temps de chargement pour les tâches automatisées, les intégrations personnalisées et les flux de travail internes.

### Déchargement du trafic CI/CD {#cicd-traffic-offload}

Vous pouvez configurer vos runners CI/CD pour [cloner depuis les sites secondaires Geo](secondary_proxy/runners.md). Vous pouvez adapter vos sites secondaires aux besoins de la charge de travail des runners et n'avez pas besoin de répliquer le site principal. Les requêtes de lecture prises en charge sont servies avec des données en cache sur le site secondaire, et les requêtes sont transférées de manière transparente vers le site principal lorsque les données sur le site secondaire sont obsolètes ou non disponibles.

Avantages :

- Sur le site principal, réduisez l'impact du trafic CI/CD sur l'expérience utilisateur en déplaçant le trafic vers les sites secondaires.
- Réduisez le trafic inter-régions et localisez le temps de calcul CI/CD là où c'est le plus économique pour votre organisation. Créez une seule copie inter-régions des données et rendez-la disponible pour les requêtes de lecture répétées contre le site secondaire.

### Cas d'utilisation supplémentaires {#additional-use-cases}

#### Migrations d'infrastructure {#infrastructure-migrations}

Vous pouvez utiliser Geo pour migrer vers une nouvelle infrastructure. Si vous déplacez votre instance GitLab vers un nouveau serveur ou centre de données, utilisez Geo pour migrer vos données GitLab vers la nouvelle instance en arrière-plan pendant que votre ancienne instance continue de servir vos utilisateurs. Toutes les modifications apportées à vos données GitLab actives sont copiées vers votre nouvelle instance, de sorte qu'il n'y a pas de perte de données lors du basculement.

Vous ne pouvez pas utiliser Geo pour migrer une base de données PostgreSQL d'un système d'exploitation à un autre. Voir [Mise à niveau des systèmes d'exploitation pour PostgreSQL](../postgresql/upgrading_os.md).

Avantages :

- Réduisez considérablement les temps d'arrêt lors de la migration par rapport à la méthode de migration par sauvegarde et restauration. Copiez les données vers la nouvelle instance en arrière-plan sans arrêter l'instance GitLab active avant la fenêtre de temps d'arrêt du basculement.

#### Migration vers GitLab Dedicated {#migration-to-gitlab-dedicated}

Vous pouvez également utiliser Geo pour migrer GitLab Self-Managed vers [GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md). Une migration vers GitLab Dedicated est similaire à une migration d'infrastructure.

Pour plus d'informations, voir [migrer vers GitLab Dedicated avec Geo](../dedicated/geo_migration.md).

Avantages :

- Expérience d'intégration plus fluide avec des temps d'arrêt considérablement réduits. Votre équipe peut continuer à utiliser GitLab Self-Managed pendant que la migration des données s'effectue en arrière-plan.

## Ce que Geo n'est pas conçu pour résoudre {#what-geo-is-not-designed-to-address}

Geo n'est pas conçu pour répondre à tous les cas d'utilisation. Cette section fournit des exemples de cas d'utilisation pour lesquels Geo n'est pas une solution appropriée.

### Appliquer la conformité à l'exportation des données {#enforce-data-export-compliance}

Bien que la fonctionnalité de [synchronisation sélective](replication/selective_synchronization.md) de Geo vous permette de restreindre les projets synchronisés vers les sites secondaires, elle a été conçue pour réduire le trafic inter-régions et les besoins en stockage, et non pour appliquer la conformité à l'exportation. Vous devez déterminer de manière indépendante vos obligations légales en matière de confidentialité, de cybersécurité et des lois applicables sur le contrôle des échanges, sur une base continue, en fonction de la solution et de la documentation. La solution et la documentation sont toutes deux susceptibles d'être modifiées.

### Fournir un contrôle d'accès {#provide-access-control}

La fonctionnalité de [site secondaire en lecture seule](secondary_proxy/_index.md#disable-secondary-site-git-proxying) de Geo n'est pas une fonctionnalité de première classe et pourrait ne pas être prise en charge à l'avenir. Vous ne devez pas vous fier à cette fonctionnalité à des fins de contrôle d'accès. GitLab fournit des contrôles [d'authentification et d'autorisation](../auth/_index.md) qui servent mieux cet objectif.

### Une alternative aux mises à niveau sans temps d'arrêt {#an-alternative-to-zero-downtime-upgrades}

Geo n'est pas une solution pour les [mises à niveau sans temps d'arrêt](../../update/zero_downtime.md). Vous devez mettre à niveau le site Geo principal avant de mettre à niveau les sites secondaires.

### Se protéger contre la corruption malveillante ou non intentionnelle {#protect-against-malicious-or-unintentional-corruption}

Geo réplique la corruption du site principal vers tous les sites secondaires. Pour vous protéger contre la corruption malveillante ou non intentionnelle, vous devez compléter Geo avec des [sauvegardes](../backup_restore/_index.md).

### Configuration actif-actif, haute disponibilité {#active-active-high-availability-configuration}

Geo est conçu pour être une solution actif-passif, à haute disponibilité. Il fonctionne selon un modèle de synchronisation à cohérence éventuelle, ce qui signifie que les sites secondaires ne sont pas étroitement synchronisés avec le site principal. Les sites secondaires suivent le site principal avec un petit délai, ce qui peut entraîner une petite perte de données après un sinistre. Le basculement vers un site secondaire en cas de sinistre nécessite une intervention humaine. Cependant, une grande partie du processus de promotion d'un site secondaire en site principal est automatisée par le [GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit), à condition que vous déployiez tous vos sites en utilisant GET.

## Gitaly Cluster (Praefect) {#gitaly-cluster-praefect}

Geo ne doit pas être confondu avec [Gitaly Cluster (Praefect)](../gitaly/praefect/_index.md). Pour plus d'informations sur la différence entre Geo et Gitaly Cluster (Praefect), voir [Comparaison avec Geo](../gitaly/praefect/_index.md#comparison-to-geo).

## Fonctionnement de Geo {#how-geo-works}

Voici un bref résumé du fonctionnement de Geo dans votre environnement GitLab. Pour plus de détails, consultez la documentation de développement Geo.

Votre instance Geo peut être utilisée pour cloner et récupérer des projets, en plus de lire toutes les données. Cela rend le travail avec de grands dépôts sur de longues distances beaucoup plus rapide.

![Aperçu de Geo](img/geo_overview_v11_5.png)

Lorsque Geo est activé :

- L'instance d'origine est connue comme le site **principal**.
- Les sites de réplication sont connus comme les sites **secondaire**.

Gardez à l'esprit que :

- Les sites **Secondaire** communiquent avec le site **principal** pour :
  - Obtenir les données utilisateur pour les connexions (API).
  - Répliquer les dépôts, les objets LFS et les pièces jointes (HTTPS + JWT).
- Le site **principal** communique avec les sites **secondaire** pour consulter les détails de réplication. Le site **principal** effectue une requête GraphQL vers le site **secondaire** pour les données de synchronisation et de vérification (API).
- Vous pouvez pousser directement vers un site **secondaire** (pour HTTP et SSH, y compris Git LFS), et les requêtes seront transmises par proxy au site **principal**.
- Certains [problèmes connus](#known-issues) existent lors de l'utilisation de Geo.

### Architecture {#architecture}

Le diagramme suivant illustre l'architecture sous-jacente de Geo.

![Architecture Geo](img/geo_architecture_v13_8.png)

Dans ce diagramme :

- Il y a le site **principal** et les détails d'un site **secondaire**.
- Les écritures dans la base de données ne peuvent être effectuées que sur le site **principal**. Un site **secondaire** reçoit les mises à jour de la base de données en utilisant la [réplication en streaming PostgreSQL](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION).
- S'il est présent, le [serveur LDAP](#ldap) doit être configuré pour se répliquer pour les scénarios de [reprise après sinistre](disaster_recovery/_index.md).
- Un site **secondaire** effectue différents types de synchronisations avec le site **principal**, en utilisant une autorisation spéciale protégée par JWT :
  - Les dépôts sont clonés/mis à jour via Git sur HTTPS.
  - Les pièces jointes, les objets LFS et les autres fichiers sont téléchargés via HTTPS en utilisant un point de terminaison d'API privé.

Du point de vue d'un utilisateur effectuant des opérations Git :

- Le site **principal** se comporte comme une instance GitLab complète en lecture-écriture.
- Les sites **Secondaire** se comportent comme des instances GitLab complètes en lecture-écriture. Les sites **Secondaire** transfèrent de manière transparente toutes les opérations vers le site **principal**, avec [quelques exceptions notables](secondary_proxy/_index.md#features-accelerated-by-secondary-geo-sites). En particulier, les récupérations Git sont servies par le site **secondaire** lorsqu'il est à jour.

Du point de vue d'un utilisateur naviguant dans l'interface GitLab ou utilisant l'API :

- Le site **principal** se comporte comme une instance GitLab complète en lecture-écriture.
- Les sites **Secondaire** se comportent comme des instances GitLab complètes en lecture-écriture. Les sites **Secondaire** transfèrent de manière transparente toutes les opérations vers le site **principal**, avec [quelques exceptions notables](secondary_proxy/_index.md#features-accelerated-by-secondary-geo-sites). En particulier, les ressources de l'interface web sont servies par le site **secondaire**.

Pour simplifier le diagramme, certains composants nécessaires sont omis.

- Git sur SSH nécessite [`gitlab-shell`](https://gitlab.com/gitlab-org/gitlab-shell).
- Git sur HTTPS nécessitait [`gitlab-workhorse`](https://gitlab.com/gitlab-org/gitlab-workhorse).

Un site **secondaire** nécessite deux bases de données PostgreSQL différentes :

- Une instance de base de données en lecture seule qui diffuse des données depuis la base de données GitLab principale.
- Une [instance de base de données en lecture/écriture (base de données de suivi)](#geo-tracking-database) utilisée en interne par le site **secondaire** pour enregistrer les données qui ont été répliquées.

Les sites **secondaire** exécutent également un démon supplémentaire :  [Geo Log Cursor](#geo-log-cursor).

## Prérequis pour exécuter Geo {#requirements-for-running-geo}

Les éléments suivants sont requis pour exécuter Geo :

- Un système d'exploitation prenant en charge OpenSSH 6.9 ou version ultérieure (nécessaire pour la [recherche rapide des clés SSH autorisées dans la base de données](../operations/fast_ssh_key_lookup.md)). Les systèmes d'exploitation suivants sont connus pour être livrés avec une version actuelle d'OpenSSH :
  - [CentOS](https://www.centos.org) 7.4 ou version ultérieure
  - [Ubuntu](https://ubuntu.com) 16.04 ou version ultérieure
- Dans la mesure du possible, vous devriez également utiliser la même version du système d'exploitation sur tous les sites Geo. Si vous utilisez différentes versions du système d'exploitation entre les sites Geo, vous **must** [vérifier la compatibilité des données de paramètres régionaux du système d'exploitation](replication/troubleshooting/common.md#check-os-locale-data-compatibility) entre les sites Geo pour éviter la corruption silencieuse des index de base de données.
- [Versions PostgreSQL prises en charge](https://handbook.gitlab.com/handbook/engineering/data-engineering/database-excellence/database-frameworks/postgresql-upgrade-cadence/) pour vos releases GitLab avec la [réplication en streaming](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION).
  - La [réplication logique PostgreSQL](https://www.postgresql.org/docs/16/logical-replication.html) n'est pas prise en charge.
- Tous les sites doivent exécuter [les mêmes versions de PostgreSQL](setup/database.md#postgresql-replication).
- Git 2.9 ou version ultérieure
- Git-lfs 2.4.2 ou version ultérieure côté utilisateur lors de l'utilisation de LFS
- Tous les sites doivent exécuter exactement la même version de GitLab. Les [versions majeure, mineure et de correctif](../../policy/maintenance.md#versioning) doivent toutes correspondre.
- Tous les sites doivent définir les mêmes [stockages de dépôts](../repository_storage_paths.md).
- Lorsque vous utilisez le registre de conteneurs avec Geo, vous devez configurer des instances PostgreSQL externes séparées pour la base de données de métadonnées du registre de conteneurs sur chaque site. Voir [Registre de conteneurs pour un site secondaire](replication/container_registry.md) pour plus de détails.

De plus, vérifiez les [exigences minimales](../../install/requirements.md) de GitLab et utilisez la dernière version de GitLab pour une meilleure expérience.

Comme Geo ajoute une base de données de suivi et des métadonnées de réplication en plus de l'installation GitLab de base, prévoyez au moins 40 Go d'espace disque par site pour un déploiement Geo minimal sans données de dépôt. Consultez les [exigences de stockage](../../install/requirements.md#storage) pour plus de détails.

### Règles de pare-feu {#firewall-rules}

Le tableau suivant répertorie les ports de base qui doivent être ouverts entre les sites **principal** et **secondaire** pour Geo. Pour simplifier les basculements, vous devriez ouvrir les ports dans les deux sens.

| Site source | Port source | Site de destination | Port de destination | Protocole    |
|-------------|-------------|------------------|------------------|-------------|
| Principal     | Quelconque         | Secondaire        | 80               | TCP (HTTP)  |
| Principal     | Quelconque         | Secondaire        | 443              | TCP (HTTPS) |
| Secondaire   | Quelconque         | Principal          | 80               | TCP (HTTP)  |
| Secondaire   | Quelconque         | Principal          | 443              | TCP (HTTPS) |
| Secondaire   | Quelconque         | Principal          | 5432             | TCP         |
| Secondaire   | Quelconque         | Principal          | 5000             | TCP (HTTPS) |

Consultez la liste complète des ports utilisés par GitLab dans [Paramètres par défaut du package](../package_information/defaults.md)

> [!warning]
> Pour la réplication PostgreSQL entre les sites Geo, vous devez utiliser des connexions réseau privées, telles que le peering VPC interne. N'exposez jamais les ports PostgreSQL à Internet. L'exposition des ports PostgreSQL à Internet peut entraîner un accès non autorisé avec des autorisations d'écriture complètes à votre base de données GitLab, compromettant potentiellement l'ensemble de votre instance GitLab et toutes les données associées.

De plus :

- La prise en charge du [terminal web](../../ci/environments/_index.md#web-terminals-deprecated) nécessite que votre équilibreur de charge gère correctement les connexions WebSocket. Lors de l'utilisation du proxy HTTP ou HTTPS, votre équilibreur de charge doit être configuré pour transmettre les en-têtes hop-by-hop `Connection` et `Upgrade`. Consultez le guide d'intégration du [terminal web](../integration/terminal.md) pour plus de détails.
- Lors de l'utilisation du protocole HTTPS pour le port 443, vous devez ajouter un certificat SSL aux équilibreurs de charge. Si vous souhaitez terminer le SSL au niveau du serveur d'application GitLab à la place, utilisez le protocole TCP.
- Si vous utilisez uniquement `HTTPS` pour les URL externes/internes, il n'est pas nécessaire d'ouvrir le port 80 dans le pare-feu.

#### URL interne {#internal-url}

Les requêtes HTTP provenant de tout site secondaire Geo vers le site Geo principal utilisent l'URL interne du site Geo principal. Si cela n'est pas explicitement défini dans les paramètres du site Geo principal dans la zone **Admin**, l'URL publique du site principal est utilisée.

Prérequis :

- Accès administrateur.

Pour mettre à jour l'URL interne du site Geo principal :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Sélectionnez **Éditer** sur le site principal.
1. Modifiez l'**URL interne**, puis sélectionnez **Sauvegarder les modifications**.

### Base de données de suivi Geo {#geo-tracking-database}

L'instance de base de données de suivi est utilisée comme métadonnées pour contrôler ce qui doit être mis à jour sur l'instance locale. Par exemple :

- Télécharger de nouveaux actifs.
- Récupérer les nouveaux objets LFS.
- Récupérer les modifications d'un dépôt qui a été récemment mis à jour.

Comme l'instance de base de données répliquée est en lecture seule, nous avons besoin de cette instance de base de données supplémentaire pour chaque site **secondaire**.

### Geo Log Cursor {#geo-log-cursor}

Ce démon :

- Lit un journal des événements répliqués par le site **principal** vers l'instance de base de données **secondaire**.
- Met à jour l'instance de la base de données de suivi Geo avec les modifications à exécuter.

Lorsqu'une mise à jour est marquée dans l'instance de base de données de suivi, des jobs asynchrones s'exécutant sur le site **secondaire** effectuent les opérations requises et mettent à jour l'état.

Cette nouvelle architecture permet à GitLab d'être résilient aux problèmes de connectivité entre les sites. Peu importe la durée pendant laquelle le site **secondaire** est déconnecté du site **principal**, car il est capable de rejouer tous les événements dans le bon ordre et de se resynchroniser avec le site **principal**.

## Problèmes connus {#known-issues}

> [!warning]
> Ces problèmes connus ne reflètent que la dernière version de GitLab. Si vous utilisez une version plus ancienne, des problèmes supplémentaires pourraient exister.

- Git sur SSH via un site Geo secondaire ne fonctionne pas de manière fiable. Pour plus d'informations, voir [ticket #413109](https://gitlab.com/gitlab-org/gitlab/-/issues/413109), [ticket #417186](https://gitlab.com/gitlab-org/gitlab/-/issues/417186), [ticket #454707](https://gitlab.com/gitlab-org/gitlab/-/issues/454707) et [ticket 585913](https://gitlab.com/gitlab-org/gitlab/-/issues/585913).
- Pousser directement vers un site **secondaire** redirige (pour HTTP) ou transfère par proxy (pour SSH) la requête vers le site **principal** au lieu de [la traiter directement](https://gitlab.com/gitlab-org/gitlab/-/issues/1381). Vous ne pouvez pas utiliser Git sur HTTP avec des informations d'identification intégrées dans l'URI, par exemple, `https://user:personal-access-token@secondary.tld`. Pour plus d'informations, voir comment [utiliser un site Geo](replication/usage.md).
- Le site **principal** doit être en ligne pour que la connexion OAuth se produise. Les sessions existantes et Git ne sont pas affectés. La prise en charge du site **secondaire** pour utiliser un fournisseur OAuth indépendant du site principal est [en cours de planification](https://gitlab.com/gitlab-org/gitlab/-/issues/208465).
- L'installation nécessite plusieurs étapes manuelles qui peuvent ensemble prendre environ une heure selon les circonstances. Envisagez d'utiliser les scripts Terraform et Ansible de [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) pour déployer et exploiter des instances GitLab de production basées sur nos [architectures de référence](../reference_architectures/_index.md), y compris l'automatisation des tâches quotidiennes courantes. [L'epic 1465](https://gitlab.com/groups/gitlab-org/-/epics/1465) propose d'améliorer encore davantage l'installation de Geo.
- Les mises à jour en temps réel des tickets/merge requests (par exemple, via le long polling) ne fonctionnent pas sur les sites **secondaire** où [le proxy HTTP est désactivé](secondary_proxy/_index.md#disable-secondary-site-http-proxying).
- La [synchronisation sélective](replication/selective_synchronization.md) limite uniquement les dépôts et les fichiers qui sont répliqués. L'intégralité des données PostgreSQL est toujours répliquée. La synchronisation sélective n'est pas conçue pour prendre en charge les cas d'utilisation liés à la conformité ou au contrôle des exportations.
- Le [contrôle d'accès Pages](../../user/project/pages/pages_access_control.md) ne fonctionne pas sur les sites secondaires. Pour plus d'informations, voir [ticket 9336](https://gitlab.com/gitlab-org/gitlab/-/issues/9336) pour plus de détails.
- La [reprise après sinistre](disaster_recovery/_index.md) pour les déploiements comportant plusieurs sites secondaires entraîne des temps d'arrêt en raison de la nécessité de réinitialiser la réplication en streaming PostgreSQL sur tous les sites secondaires non promus pour suivre le nouveau site principal.
- Pour Git sur SSH, pour que l'URL de clonage du projet s'affiche correctement quel que soit le site sur lequel vous naviguez, les sites secondaires doivent utiliser le même port que le site principal. Pour plus d'informations, voir [ticket 339262](https://gitlab.com/gitlab-org/gitlab/-/issues/339262).
- Les sauvegardes [ne peuvent pas être exécutées sur les sites secondaires Geo](replication/troubleshooting/postgresql_replication.md#message-error-canceling-statement-due-to-conflict-with-recovery).
- Le site secondaire Geo n'accélère pas (ne sert pas) la requête de clonage pour la première étape du pipeline dans la plupart des cas. Les étapes ultérieures ne sont pas non plus garanties d'être servies par le site secondaire, par exemple si la modification Git est volumineuse, la bande passante est faible, ou les étapes du pipeline sont courtes. En général, il sert bien la requête de clonage pour les étapes suivantes. Le [ticket 446176](https://gitlab.com/gitlab-org/gitlab/-/issues/446176) discute des raisons de cela et propose une amélioration pour augmenter les chances que les requêtes de clonage des runners soient servies depuis le site secondaire.
- Lorsqu'un seul dépôt Git reçoit des poussées à un rythme suffisamment élevé, la copie locale du site secondaire peut être perpétuellement obsolète. Cela entraîne le transfert de toutes les récupérations Git de ce dépôt vers le site principal. Pour plus d'informations, voir [ticket 455870](https://gitlab.com/gitlab-org/gitlab/-/issues/455870).
- Le [proxy](secondary_proxy/_index.md) n'est implémenté que dans l'application GitLab dans le service Puma ou le service Web, de sorte que les autres services ne bénéficient pas de ce comportement. Vous devriez utiliser une [URL séparée](secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site) pour vous assurer que les requêtes sont toujours envoyées au site principal. Ces services comprennent :
  - Registre de conteneurs GitLab - [peut être configuré pour utiliser un domaine séparé](../packages/container_registry.md#configure-container-registry-under-its-own-domain), tel que `registry.example.com`. Les registres de conteneurs des sites secondaires sont destinés uniquement à la reprise après sinistre. Les utilisateurs ne doivent pas y être acheminés, en particulier pas pour les poussées, car les données ne sont pas propagées vers le site principal.
  - GitLab Pages - doit toujours utiliser un domaine séparé, dans le cadre des [prérequis pour l'exécution de GitLab Pages](../pages/_index.md#prerequisites).
- Avec une [URL unifiée](secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites), Let's Encrypt ne peut pas générer de certificats à moins de pouvoir atteindre les deux adresses IP via le même domaine. Pour utiliser des certificats TLS avec Let's Encrypt, vous pouvez pointer manuellement le domaine vers l'un des sites Geo, générer le certificat, puis le copier vers tous les autres sites.
- Lorsqu'un [site secondaire utilise une URL séparée](secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site) du site principal, la [connexion au site secondaire via SAML](replication/single_sign_on.md#saml-with-separate-url-with-proxying-enabled) n'est prise en charge que si le fournisseur d'identité SAML (IdP) permet à une application d'être configurée avec plusieurs URL de rappel.
- Les requêtes de clonage et de récupération Git avec l'option `--depth` via SSH vers un site secondaire ne fonctionnent pas et restent bloquées indéfiniment si le site secondaire n'est pas à jour au moment où la requête est initiée. Cela est dû à des problèmes liés à la traduction de Git SSH en Git HTTPS lors du proxy. Pour plus d'informations, voir [ticket 391980](https://gitlab.com/gitlab-org/gitlab/-/issues/391980). Un nouveau flux de travail qui n'implique pas l'étape de traduction susmentionnée est désormais disponible pour les sites secondaires Geo GitLab empaqueté pour Linux, qui peut être activé avec un feature flag. Pour plus de détails, voir [le commentaire dans le ticket 454707](https://gitlab.com/gitlab-org/gitlab/-/issues/454707#note_2102067451). Le correctif pour les sites secondaires Geo GitLab Cloud Native est suivi dans le [ticket 5641](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5641).
- N'utilisez pas d'[URL relatives](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-relative-url-for-gitlab) avec GitLab Geo car elles briseront le proxy entre les sites. Pour plus d'informations, voir [ticket 456427](https://gitlab.com/gitlab-org/gitlab/-/issues/456427).

### Types de données répliquées {#replicated-data-types}

Il existe une liste complète de tous les [types de données](replication/datatypes.md) GitLab et des [types de données répliquées](replication/datatypes.md#replicated-data-types).

## Documentation post-installation {#post-installation-documentation}

Après avoir installé GitLab sur les sites **secondaire** et effectué la configuration initiale, consultez la documentation suivante pour les informations post-installation.

### Configuration de Geo {#setting-up-geo}

Pour des informations sur la configuration de Geo, voir [Configurer Geo](setup/_index.md).

### Configuration de Geo avec le stockage d'objets {#configuring-geo-with-object-storage}

Pour des informations sur la configuration de Geo avec le stockage d'objets, voir [Geo avec le stockage d'objets](replication/object_storage.md).

### Réplication du registre de conteneurs {#replicating-the-container-registry}

Pour plus d'informations sur la façon de répliquer le registre de conteneurs, voir [Registre de conteneurs pour un site **secondaire**](replication/container_registry.md).

### Configurer une URL unifiée pour les sites Geo {#set-up-a-unified-url-for-geo-sites}

Pour un exemple de configuration d'une URL unique compatible avec la localisation avec AWS Route53 ou Google Cloud DNS, voir [Configurer une URL unifiée pour les sites Geo](secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites).

### Authentification unique (SSO) {#single-sign-on-sso}

Pour plus d'informations sur la configuration de l'authentification unique (SSO), voir [Geo avec l'authentification unique (SSO)](replication/single_sign_on.md).

#### LDAP {#ldap}

Pour plus d'informations sur la configuration de LDAP, voir [Geo avec l'authentification unique (SSO) > LDAP](replication/single_sign_on.md#ldap).

### Optimisation de Geo {#tuning-geo}

Pour plus d'informations sur l'optimisation de Geo, voir [Optimisation de Geo](replication/tuning.md).

### Mise en pause et reprise de la réplication {#pausing-and-resuming-replication}

Pour plus d'informations, voir [Mise en pause et reprise de la réplication](replication/pause_resume_replication.md).

### Remplissage initial {#backfill}

Lorsqu'un site **secondaire** est configuré, il commence à répliquer les données manquantes depuis le site **principal** dans un processus connu sous le nom de **backfill**. Vous pouvez surveiller le processus de synchronisation sur chaque site Geo depuis le tableau de bord **Geo Nodes** du site **principal** dans votre navigateur.

Les échecs qui se produisent pendant un remplissage initial sont planifiés pour être retentés à la fin du remplissage initial.

### Runners {#runners}

- En plus de nos meilleures pratiques standard pour le déploiement d'une [flotte de runners](https://docs.gitlab.com/runner/fleet_scaling/), les runners peuvent également être configurés pour se connecter aux sites secondaires Geo afin de répartir la charge des jobs. Voir comment [enregistrer des runners auprès des sites secondaires](secondary_proxy/runners.md).
- Voir également comment gérer la [connectivité des runners lors d'un basculement](disaster_recovery/planned_failover.md#runner-connectivity-during-failover).

### Mise à niveau de Geo {#upgrading-geo}

Pour des informations sur la façon de mettre à jour vos sites Geo vers la dernière version de GitLab, voir [Mise à niveau des sites Geo](replication/upgrading_the_geo_sites.md).

### Revue de sécurité {#security-review}

Pour plus d'informations sur la sécurité de Geo, voir [Revue de sécurité Geo](replication/security_review.md).

## Supprimer un site Geo {#remove-geo-site}

Pour plus d'informations sur la suppression d'un site Geo, voir [Suppression des sites Geo **secondaire**](replication/remove_geo_site.md).

## Désactiver Geo {#disable-geo}

Pour savoir comment désactiver Geo, voir [Désactivation de Geo](replication/disable_geo.md).

## Fichiers journaux {#log-files}

Geo stocke les messages de journaux structurés dans un fichier `geo.log`.

Pour plus d'informations sur la façon d'accéder aux journaux Geo et de les utiliser, voir la [section Geo dans la documentation du système de journalisation](../logs/_index.md#geolog).

## Reprise après sinistre {#disaster-recovery}

Pour des informations sur l'utilisation de Geo dans des situations de reprise après sinistre afin d'atténuer la perte de données et de restaurer les services, voir [Reprise après sinistre](disaster_recovery/_index.md).

## Foire aux questions {#frequently-asked-questions}

Pour des réponses aux questions courantes, consultez la [FAQ Geo](replication/faq.md).

## Dépannage {#troubleshooting}

- Pour les étapes de dépannage de Geo, voir [Dépannage de Geo](replication/troubleshooting/_index.md).
- Pour les étapes de dépannage de la reprise après sinistre, voir [Dépannage du basculement Geo](disaster_recovery/failover_troubleshooting.md).
