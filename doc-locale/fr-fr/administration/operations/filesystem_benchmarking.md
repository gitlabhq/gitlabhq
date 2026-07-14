---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Benchmarking des performances du système de fichiers
description: Mesurer les performances du système de fichiers.
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les performances du système de fichiers ont un impact important sur les performances globales de GitLab, en particulier pour les actions qui lisent ou écrivent dans des dépôts Git. Ces informations permettent de comparer les performances du système de fichiers par rapport à des systèmes réels connus pour être bons ou mauvais.

Lorsqu'on parle de performances du système de fichiers, la principale préoccupation concerne les systèmes de fichiers réseau (NFS). Cependant, même certains disques locaux peuvent avoir des entrées/sorties lentes. Les informations de cette page peuvent être utilisées dans l'un ou l'autre scénario.

## Exécution des benchmarks {#executing-benchmarks}

### Benchmarking avec `fio` {#benchmarking-with-fio}

Vous devriez utiliser [Fio](https://fio.readthedocs.io/en/latest/fio_doc.html) pour tester les performances d'E/S. Ce test doit être exécuté sur les serveurs susceptibles d'être affectés par de faibles performances disque :

- L'hôte NFS et les nœuds d'application qui montent un lecteur NFS.
- Nœuds Gitaly.
- Nœuds PostgreSQL.

Pour installer :

- Sur Ubuntu : `apt install fio`.
- Dans les environnements gérés par `yum` : `yum install fio`.

Exécutez ensuite ce qui suit :

```shell
file="/path/to/nfs-or-postgres-or-gitaly/fio-benchmark-$(date +%s)"
fio --ioengine=libaio --direct=1 --gtod_reduce=1 --iodepth=64 --randrepeat=1 \
    --readwrite=randrw --name="$file" --filename="$file" \
    --size=4G --rwmixread=75 --bs=4k
```

Cela crée un fichier de 4 Go dans le chemin NFS, PostgreSQL ou Gitaly. Fio effectue des lectures et des écritures de 4 Ko en utilisant une répartition 75 %/25 % dans le fichier, avec 64 opérations s'exécutant simultanément. Veillez à supprimer le fichier une fois le test terminé.

La sortie varie en fonction de la version de `fio` installée. Voici un exemple de sortie de `fio` v2.2.10 sur un disque SSD réseau :

```plaintext
path/to/nfs-or-postgres-or-gitaly/fio-benchmark-1234567890: (g=0): rw=randrw, bs=4K-4K/4K-4K/4K-4K, ioengine=libaio, iodepth=64
    fio-2.2.10
    Starting 1 process
    test: Laying out IO file(s) (1 file(s) / 1024MB)
    Jobs: 1 (f=1): [m(1)] [100.0% done] [131.4MB/44868KB/0KB /s] [33.7K/11.3K/0 iops] [eta 00m:00s]
    test: (groupid=0, jobs=1): err= 0: pid=10287: Sat Feb  2 17:40:10 2019
      read : io=784996KB, bw=133662KB/s, iops=33415, runt=  5873msec
      write: io=263580KB, bw=44880KB/s, iops=11219, runt=  5873msec
      cpu          : usr=6.56%, sys=23.11%, ctx=266267, majf=0, minf=8
      IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
         submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
         complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.1%, >=64=0.0%
         issued    : total=r=196249/w=65895/d=0, short=r=0/w=0/d=0, drop=r=0/w=0/d=0
         latency   : target=0, window=0, percentile=100.00%, depth=64

    Run status group 0 (all jobs):
       READ: io=784996KB, aggrb=133661KB/s, minb=133661KB/s, maxb=133661KB/s, mint=5873msec, maxt=5873msec
      WRITE: io=263580KB, aggrb=44879KB/s, minb=44879KB/s, maxb=44879KB/s, mint=5873msec, maxt=5873msec
```

Observez les valeurs `iops` dans cette sortie. Dans cet exemple, le SSD a effectué 33 415 opérations de lecture par seconde et 11 219 opérations d'écriture par seconde. Un disque dur à plateau pourrait produire 2 000 et 700 opérations de lecture et d'écriture par seconde.

### Benchmarking simple {#simple-benchmarking}

> [!note]
> Ce test est rudimentaire mais peut être utilisé si `fio` n'est pas disponible sur le système. Il est possible d'obtenir de bons résultats avec ce test mais d'avoir quand même de mauvaises performances en raison de la vitesse de lecture et de divers autres facteurs.

Les commandes sur une seule ligne suivantes permettent d'effectuer un benchmark rapide des performances d'écriture et de lecture du système de fichiers. Cela écrit 1 000 petits fichiers dans le répertoire où la commande est exécutée, puis lit les 1 000 mêmes fichiers.

1. Accédez à la racine du [chemin de stockage du dépôt](../repository_storage_paths.md) approprié.
1. Créez un répertoire temporaire pour le test afin de pouvoir le supprimer ultérieurement :

   ```shell
   mkdir test; cd test
   ```

1. Exécutez la commande :

   ```shell
   time for i in {0..1000}; do echo 'test' > "test${i}.txt"; done
   ```

1. Pour effectuer un benchmark des performances de lecture, exécutez la commande :

   ```shell
   time for i in {0..1000}; do cat "test${i}.txt" > /dev/null; done
   ```

1. Supprimez les fichiers de test :

   ```shell
   cd ../; rm -rf test
   ```

La sortie des commandes `time for ...` ressemble à ce qui suit. La métrique importante est le temps `real`.

```shell
$ time for i in {0..1000}; do echo 'test' > "test${i}.txt"; done

real    0m0.116s
user    0m0.025s
sys     0m0.091s

$ time for i in {0..1000}; do cat "test${i}.txt" > /dev/null; done

real    0m3.118s
user    0m1.267s
sys 0m1.663s
```

D'après l'expérience avec plusieurs clients, cette tâche devrait prendre moins de 10 secondes pour indiquer de bonnes performances du système de fichiers.
