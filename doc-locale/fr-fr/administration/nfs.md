---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser NFS avec GitLab
description: Utiliser NFS avec GitLab.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

NFS peut être utilisé comme alternative au stockage d'objets, mais cette option n'est généralement pas recommandée pour des raisons de performances.

Pour les objets de données tels que LFS, les chargements et les artefacts, un [service de stockage d'objets](object_storage.md) est recommandé plutôt que NFS dans la mesure du possible, en raison de meilleures performances. Lors de l'élimination de l'utilisation de NFS, des [étapes supplémentaires sont nécessaires](object_storage.md#alternatives-to-file-system-storage) en plus du passage au stockage d'objets.

NFS ne peut pas être utilisé pour le stockage de dépôt.

Pour connaître les étapes permettant de tester les performances du système de fichiers, consultez [Évaluation des performances du système de fichiers](operations/filesystem_benchmarking.md).

## Recherche rapide des clés SSH autorisées {#fast-lookup-of-authorized-ssh-keys}

La fonctionnalité de [recherche rapide des clés SSH](operations/fast_ssh_key_lookup.md) peut améliorer les performances des instances GitLab, même si elles utilisent un stockage en bloc.

[La recherche rapide des clés SSH](operations/fast_ssh_key_lookup.md) remplace `authorized_keys` (dans `/var/opt/gitlab/.ssh`) en utilisant la base de données GitLab.

NFS augmente la latence. La recherche rapide est donc recommandée si `/var/opt/gitlab` est déplacé vers NFS.

Nous étudions l'utilisation de [la recherche rapide comme option par défaut](https://gitlab.com/groups/gitlab-org/-/epics/3104).

## Serveur NFS {#nfs-server}

L'installation du package `nfs-kernel-server` vous permet de partager des répertoires avec les clients exécutant l'application GitLab :

```shell
sudo apt-get update
sudo apt-get install nfs-kernel-server
```

### Fonctionnalités requises {#required-features}

**Verrouillage des fichiers** : GitLab **nécessite** le verrouillage consultatif des fichiers, qui n'est supporté nativement que dans NFS version 4. NFSv3 supporte également le verrouillage tant que le noyau Linux 2.6.5+ est utilisé. Nous recommandons d'utiliser la version 4 et ne testons pas spécifiquement NFSv3.

### Options recommandées {#recommended-options}

Lorsque vous définissez vos exports NFS, nous vous recommandons d'ajouter également les options suivantes :

- `no_root_squash` - NFS remplace généralement l'utilisateur `root` par `nobody`. Il s'agit d'une bonne mesure de sécurité lorsque les partages NFS sont accessibles par de nombreux utilisateurs différents. Cependant, dans ce cas, seul GitLab utilise le partage NFS, ce qui est donc sûr. GitLab recommande le paramètre `no_root_squash` car nous devons gérer automatiquement les permissions des fichiers. Sans ce paramètre, vous pourriez recevoir des erreurs lorsque le package Linux tente de modifier les permissions. GitLab et les autres composants intégrés ne s'exécutent **pas** en tant que `root` mais en tant qu'utilisateurs non privilégiés. La recommandation pour `no_root_squash` est de permettre au package Linux de définir la propriété et les permissions sur les fichiers, selon les besoins. Dans certains cas où l'option `no_root_squash` n'est pas disponible, le flag `root` peut produire le même résultat.
- `sync` - Forcer le comportement synchrone. Le comportement par défaut est asynchrone et, dans certaines circonstances, cela peut entraîner une perte de données si une défaillance se produit avant la synchronisation des données.

En raison de la complexité de l'exécution du package Linux avec LDAP et de la complexité du maintien du mappage d'ID sans LDAP, dans la plupart des cas, vous devez activer les UIDs et GIDs numériques (qui sont désactivés par défaut dans certains cas) pour simplifier la gestion des permissions entre les systèmes :

- [Instructions NetApp](https://docs.netapp.com/a/ontap/7-mode/8.2.4/File-Access-And-Protocols-Management-Guide-For-7-Mode.pdf)
- Pour les appareils non NetApp, désactivez le `idmapping` NFSv4 en effectuant l'opération inverse de [l'activation du idmapper NFSv4](https://wiki.archlinux.org/title/NFS#Enabling_NFSv4_idmapping)

### Désactiver la délégation du serveur NFS {#disable-nfs-server-delegation}

Nous recommandons à tous les utilisateurs NFS de désactiver la fonctionnalité de délégation du serveur NFS. Ceci afin d'éviter un [bug du noyau Linux](https://bugzilla.redhat.com/show_bug.cgi?id=1552203) qui provoque un ralentissement brutal des clients NFS en raison d'un [trafic réseau excessif généré par de nombreux messages NFS `TEST_STATEID`](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/52017).

Pour désactiver la délégation du serveur NFS, procédez comme suit :

1. Sur le serveur NFS, exécutez :

   ```shell
   echo 0 > /proc/sys/fs/leases-enable
   sysctl -w fs.leases-enable=0
   ```

1. Redémarrez le processus du serveur NFS. Par exemple, sur CentOS, exécutez `service nfs restart`.

> [!note]
> Le bug du noyau a peut-être été corrigé dans [des noyaux plus récents avec ce commit](https://github.com/torvalds/linux/commit/95da1b3a5aded124dd1bda1e3cdb876184813140). Red Hat Enterprise 7 a [publié une mise à jour du noyau](https://access.redhat.com/errata/RHSA-2019:2029) le 6 août 2019 qui a peut-être également résolu ce problème. Vous n'aurez peut-être pas besoin de désactiver la délégation du serveur NFS si vous savez que vous utilisez une version du noyau Linux qui a été corrigée. Cela dit, GitLab encourage toujours les administrateurs d'instances à maintenir la délégation du serveur NFS désactivée.

## Client NFS {#nfs-client}

Le `nfs-common` fournit les fonctionnalités NFS sans installer les composants serveur dont nous n'avons pas besoin sur les nœuds d'application.

```shell
apt-get update
apt-get install nfs-common
```

### Options de montage {#mount-options}

Voici un exemple d'extrait à ajouter à `/etc/fstab` :

```plaintext
10.1.0.1:/var/opt/gitlab/.ssh /var/opt/gitlab/.ssh nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
10.1.0.1:/var/opt/gitlab/gitlab-rails/uploads /var/opt/gitlab/gitlab-rails/uploads nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
10.1.0.1:/var/opt/gitlab/gitlab-rails/shared /var/opt/gitlab/gitlab-rails/shared nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
10.1.0.1:/var/opt/gitlab/gitlab-ci/builds /var/opt/gitlab/gitlab-ci/builds nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
```

Vous pouvez consulter les informations et les options définies pour chacun des systèmes de fichiers NFS montés en exécutant `nfsstat -m` et `cat /etc/fstab`.

Notez qu'il existe plusieurs options que vous devriez envisager d'utiliser :

| Paramètre                | Description |
|------------------------|-------------|
| `vers=4.1`             | NFS v4.1 devrait être utilisé à la place de v4.0 car il existe un [bug du client NFS Linux dans la v4.0](https://gitlab.com/gitlab-org/gitaly/-/issues/1339) qui peut causer des problèmes importants en raison de données périmées. |
| `nofail`               | Ne pas interrompre le processus de démarrage en attendant que ce montage soit disponible. |
| `lookupcache=positive` | Indique au client NFS de respecter les résultats de cache `positive` mais invalide tout résultat de cache `negative`. Les résultats de cache négatifs causent des problèmes avec Git. Plus précisément, un `git push` peut ne pas s'enregistrer de manière uniforme sur tous les clients NFS. Le cache négatif amène les clients à « mémoriser » que les fichiers n'existaient pas auparavant. |
| `hard`                 | Au lieu de `soft`. [Plus de détails](#soft-mount-option). |
| `cto`                  | `cto` est l'option par défaut, que vous devriez utiliser. N'utilisez pas `nocto`. [Plus de détails](#nocto-mount-option). |
| `_netdev`              | Attendre pour monter le système de fichiers jusqu'à ce que le réseau soit en ligne. Voir aussi l'option [`high_availability['mountpoint']`](https://docs.gitlab.com/omnibus/settings/configuration/#start-linux-package-installation-services-only-after-a-given-file-system-is-mounted). |

#### Option de montage `soft` {#soft-mount-option}

Il est recommandé d'utiliser `hard` dans vos options de montage, sauf si vous avez une raison spécifique d'utiliser `soft`.

Lorsque GitLab.com utilisait NFS, nous utilisions `soft` car il arrivait que des serveurs NFS redémarrent et que `soft` améliorait la disponibilité, mais l'infrastructure de chacun est différente. Si votre NFS est fourni par des baies de stockage sur site avec des contrôleurs redondants, par exemple, vous ne devriez pas avoir à vous soucier de la disponibilité du serveur NFS.

La page de manuel NFS indique :

> Le délai d'expiration « soft » peut entraîner une corruption silencieuse des données dans certains cas

Lisez la [page de manuel Linux](https://linux.die.net/man/5/nfs) pour comprendre la différence, et si vous utilisez `soft`, assurez-vous d'avoir pris des mesures pour atténuer les risques.

Si vous constatez un comportement qui pourrait avoir été causé par des écritures sur le disque du serveur NFS ne se produisant pas, comme des commits manquants, utilisez l'option `hard`, car (d'après la page de manuel) :

> utilisez l'option soft uniquement lorsque la réactivité du client est plus importante que l'intégrité des données

D'autres fournisseurs formulent des recommandations similaires, notamment [les options de montage recommandées pour les répertoires en lecture-écriture](https://help.sap.com/docs/SUPPORT_CONTENT/basis/3354611703.html) et la [base de connaissances](https://kb.netapp.com/on-prem/ontap/da/NAS/NAS-KBs/What_are_the_differences_between_hard_mount_and_soft_mount) de NetApp ; ils soulignent que si le pilote client NFS met les données en cache, `soft` signifie qu'il n'y a aucune certitude que les écritures de GitLab sont réellement sur le disque.

Les points de montage définis avec l'option `hard` peuvent ne pas fonctionner aussi bien, et si le serveur NFS tombe en panne, `hard` provoque le blocage des processus lors de l'interaction avec le point de montage. Utilisez `SIGKILL` (`kill -9`) pour traiter les processus bloqués. L'option `intr` [a cessé de fonctionner dans le noyau 2.6](https://access.redhat.com/solutions/157873).

#### Option de montage `nocto` {#nocto-mount-option}

N'utilisez pas `nocto`. Utilisez plutôt `cto`, qui est l'option par défaut.

Lors de l'utilisation de `nocto`, le cache dentry est toujours utilisé, jusqu'à `acdirmax` secondes (durée du cache d'attributs) à partir du moment où il est créé.

Cela entraîne des problèmes de cache dentry périmé avec plusieurs clients, où chaque client peut voir une version différente (mise en cache) d'un répertoire.

Depuis la [page de manuel Linux](https://linux.die.net/man/5/nfs), les parties importantes :

> Si l'option `nocto` est spécifiée, le client utilise une heuristique non standard pour déterminer quand les fichiers sur le serveur ont changé.
>
> L'utilisation de l'option `nocto` peut améliorer les performances pour les montages en lecture seule, mais ne devrait être utilisée que si les données sur le serveur changent seulement occasionnellement.

Nous avons remarqué ce comportement dans un ticket concernant les [références introuvables après un push](https://gitlab.com/gitlab-org/gitlab/-/issues/326066), où des références libres nouvellement ajoutées peuvent être vues comme manquantes sur un client différent avec un cache dentry local, comme [décrit dans ce ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/326066#note_539436931).

### Un seul montage NFS {#a-single-nfs-mount}

Il est recommandé d'imbriquer tous les répertoires de données GitLab dans un montage, ce qui permet une restauration automatique des sauvegardes sans déplacer manuellement les données existantes.

```plaintext
mountpoint
└── gitlab-data
    ├── builds
    ├── shared
    └── uploads
```

Pour ce faire, configurez le package Linux avec les chemins vers chaque répertoire imbriqué dans le point de montage comme suit :

Montez `/gitlab-nfs` puis utilisez la configuration suivante du package Linux pour déplacer chaque emplacement de données vers un sous-répertoire :

```ruby
gitlab_rails['uploads_directory'] = '/gitlab-nfs/gitlab-data/uploads'
gitlab_rails['shared_path'] = '/gitlab-nfs/gitlab-data/shared'
gitlab_ci['builds_directory'] = '/gitlab-nfs/gitlab-data/builds'
```

Exécutez `sudo gitlab-ctl reconfigure` pour commencer à utiliser l'emplacement central. Sachez que si vous aviez des données existantes, vous devez les copier manuellement ou les synchroniser avec rsync vers ces nouveaux emplacements, puis redémarrer GitLab.

### Montages liés (Bind mounts) {#bind-mounts}

Au lieu de modifier la configuration dans le package Linux, des montages liés (bind mounts) peuvent être utilisés pour stocker les données sur un montage NFS.

Les montages liés (bind mounts) permettent de spécifier un seul montage NFS, puis de lier les emplacements de données GitLab par défaut au montage NFS. Commencez par définir votre point de montage NFS unique comme vous le feriez normalement dans `/etc/fstab`. Supposons que votre point de montage NFS soit `/gitlab-nfs`. Ensuite, ajoutez les montages liés suivants dans `/etc/fstab` :

```shell
/gitlab-nfs/gitlab-data/.ssh /var/opt/gitlab/.ssh none bind 0 0
/gitlab-nfs/gitlab-data/uploads /var/opt/gitlab/gitlab-rails/uploads none bind 0 0
/gitlab-nfs/gitlab-data/shared /var/opt/gitlab/gitlab-rails/shared none bind 0 0
/gitlab-nfs/gitlab-data/builds /var/opt/gitlab/gitlab-ci/builds none bind 0 0
```

L'utilisation de montages liés vous oblige à vérifier manuellement que les répertoires de données sont vides avant de tenter une restauration. En savoir plus sur les [prérequis de restauration](backup_restore/_index.md).

### Montages NFS multiples {#multiple-nfs-mounts}

Lors de l'utilisation de la configuration par défaut du package Linux, vous devez partager 3 emplacements de données entre tous les nœuds du cluster GitLab. Aucun autre emplacement ne doit être partagé. Voici les 3 emplacements à partager :

| Emplacement | Description | Configuration par défaut |
| -------- | ----------- | --------------------- |
| `/var/opt/gitlab/gitlab-rails/uploads` | Pièces jointes téléchargées par les utilisateurs | `gitlab_rails['uploads_directory'] = '/var/opt/gitlab/gitlab-rails/uploads'` |
| `/var/opt/gitlab/gitlab-rails/shared` | Objets tels que les artefacts de build, GitLab Pages, les objets LFS et les fichiers temporaires. Si vous utilisez LFS, cela peut également représenter une grande partie de vos données | `gitlab_rails['shared_path'] = '/var/opt/gitlab/gitlab-rails/shared'` |
| `/var/opt/gitlab/gitlab-ci/builds` | Traces de build GitLab CI/CD | `gitlab_ci['builds_directory'] = '/var/opt/gitlab/gitlab-ci/builds'` |

Les autres répertoires GitLab ne doivent pas être partagés entre les nœuds. Ils contiennent des fichiers spécifiques aux nœuds et du code GitLab qui n'a pas besoin d'être partagé. Pour envoyer les journaux vers un emplacement centralisé, envisagez d'utiliser le syslog distant. Le package Linux fournit une configuration pour [l'envoi de journaux UDP](https://docs.gitlab.com/omnibus/settings/logs/#udp-log-forwarding).

L'utilisation de plusieurs montages NFS vous oblige à vérifier manuellement que les répertoires de données sont vides avant de tenter une restauration. En savoir plus sur les [prérequis de restauration](backup_restore/_index.md).

## Tester NFS {#testing-nfs}

Une fois le serveur et le client NFS configurés, vous pouvez vérifier que NFS est correctement configuré en testant les commandes suivantes :

```shell
sudo mkdir /gitlab-nfs/test-dir
sudo chown git /gitlab-nfs/test-dir
sudo chgrp root /gitlab-nfs/test-dir
sudo chmod 0700 /gitlab-nfs/test-dir
sudo chgrp gitlab-www /gitlab-nfs/test-dir
sudo chmod 0751 /gitlab-nfs/test-dir
sudo chgrp git /gitlab-nfs/test-dir
sudo chmod 2770 /gitlab-nfs/test-dir
sudo chmod 2755 /gitlab-nfs/test-dir
sudo -u git mkdir /gitlab-nfs/test-dir/test2
sudo -u git chmod 2755 /gitlab-nfs/test-dir/test2
sudo ls -lah /gitlab-nfs/test-dir/test2
sudo -u git rm -r /gitlab-nfs/test-dir
```

Toute erreur `Operation not permitted` signifie que vous devriez examiner les options d'export de votre serveur NFS.

## NFS dans un environnement avec pare-feu {#nfs-in-a-firewalled-environment}

Si le trafic entre votre serveur NFS et vos clients NFS est soumis à un filtrage des ports par un pare-feu, vous devez reconfigurer ce pare-feu pour autoriser la communication NFS.

[Ce guide du Linux Documentation Project (TDLP)](https://tldp.org/HOWTO/NFS-HOWTO/security.html#FIREWALLS) couvre les bases de l'utilisation de NFS dans un environnement avec pare-feu. De plus, nous vous encourageons à rechercher et à consulter la documentation spécifique à votre système d'exploitation ou distribution et à votre logiciel de pare-feu.

Exemple pour Ubuntu :

Vérifiez que le trafic NFS provenant du client est autorisé par le pare-feu sur l'hôte en exécutant la commande : `sudo ufw status`. S'il est bloqué, vous pouvez autoriser le trafic provenant d'un client spécifique avec la commande ci-dessous.

```shell
sudo ufw allow from <client_ip_address> to any port nfs
```

## Problèmes connus {#known-issues}

### Éviter d'utiliser des systèmes de fichiers basés sur le cloud {#avoid-using-cloud-based-file-systems}

GitLab déconseille fortement l'utilisation de systèmes de fichiers basés sur le cloud tels que :

- AWS Elastic File System (EFS).
- Google Cloud Filestore.
- Azure Files.

Notre équipe de support ne peut pas vous aider pour les problèmes de performances liés à l'accès aux systèmes de fichiers basés sur le cloud.

Des clients et des utilisateurs ont signalé que ces systèmes de fichiers ne fonctionnent pas bien pour les accès au système de fichiers requis par GitLab. Les charges de travail où de nombreux petits fichiers sont écrits de manière sérialisée, comme `git`, ne sont pas bien adaptées aux systèmes de fichiers basés sur le cloud.

Si vous choisissez de les utiliser, évitez d'y stocker les fichiers journaux de GitLab (par exemple, ceux se trouvant dans `/var/log/gitlab`), car cela affecte également les performances. Nous recommandons de stocker les fichiers journaux sur un volume local.

Pour plus de détails sur l'expérience d'utilisation de systèmes de fichiers basés sur le cloud avec GitLab, consultez cette [vidéo Commit Brooklyn 2019](https://youtu.be/K6OS8WodRBQ?t=313).

### Éviter d'utiliser CephFS et GlusterFS {#avoid-using-cephfs-and-glusterfs}

GitLab déconseille fortement l'utilisation de CephFS et GlusterFS. Ces systèmes de fichiers distribués ne sont pas adaptés aux modèles d'accès entrée/sortie de GitLab, car Git utilise de nombreux petits fichiers et les délais de propagation des temps d'accès et de verrouillage des fichiers rendent l'activité Git très lente.

### Éviter d'utiliser PostgreSQL avec NFS {#avoid-using-postgresql-with-nfs}

GitLab déconseille fortement d'exécuter votre base de données PostgreSQL via NFS. L'équipe de support GitLab n'est pas en mesure d'aider pour les problèmes de performances liés à cette configuration.

De plus, cette configuration est spécifiquement déconseillée dans la [documentation PostgreSQL](https://www.postgresql.org/docs/16/creating-cluster.html#CREATING-CLUSTER-NFS) :

>PostgreSQL ne fait rien de spécial pour les systèmes de fichiers NFS, ce qui signifie qu'il suppose que NFS se comporte exactement comme des disques connectés localement. Si l'implémentation NFS du client ou du serveur ne fournit pas la sémantique standard des systèmes de fichiers, cela peut causer des problèmes de fiabilité. Plus précisément, les écritures différées (asynchrones) sur le serveur NFS peuvent entraîner des problèmes de corruption des données.

Pour l'architecture de base de données supportée, consultez notre documentation sur la [configuration d'une base de données pour la réplication et le basculement](postgresql/replication_and_failover.md).

## Dépannage {#troubleshooting}

### Identification des requêtes effectuées vers NFS {#finding-the-requests-that-are-being-made-to-nfs}

En cas de problèmes liés à NFS, il peut être utile de tracer les requêtes du système de fichiers effectuées en utilisant `perf` :

```shell
sudo perf trace -e 'nfs4:*' -p $(pgrep -fd ',' puma)
```
