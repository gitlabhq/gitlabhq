---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Aide-mémoire Linux
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Il s'agit de la collection d'informations de l'équipe Support GitLab concernant Linux, qu'elle utilise parfois lors du dépannage. Elle est répertoriée ici dans un souci de transparence et pour les utilisateurs ayant de l'expérience avec Linux. Si vous rencontrez actuellement un problème avec GitLab, vous pouvez consulter vos [options de support](https://about.gitlab.com/support/) en premier lieu, avant de tenter d'utiliser ces informations.

> [!warning]
> Il est [au-delà de la portée du support GitLab d'apporter une assistance pour l'administration des systèmes](https://about.gitlab.com/support/statement-of-support/#training). Les administrateurs GitLab sont censés connaître ces commandes pour leur distribution de prédilection. Si vous êtes un ingénieur Support GitLab, considérez ceci comme une référence croisée pour traduire `yum` -> `apt-get` et ainsi de suite.

La plupart des commandes ci-dessous n'ont pas été étiquetées quant à la distribution sur laquelle elles fonctionnent. Les contributions sont les bienvenues pour aider à les ajouter.

## Commandes système {#system-commands}

### Informations sur la distribution {#distribution-information}

```shell
# Debian/Ubuntu
uname -a
lsb_release -a

# CentOS/RedHat
cat /etc/centos-release
cat /etc/redhat-release

# This will provide a lot more information
cat /etc/os-release
```

### Arrêt ou redémarrage {#shut-down-or-reboot}

```shell
shutdown -h now
reboot
```

### Permissions {#permissions}

```shell
# change the user:group ownership of a file/dir
chown root:git <file_or_dir>

# make a file executable
chmod u+x <file>
```

### Fichiers et répertoires {#files-and-directories}

```shell
# create a new directory and all subdirectories
mkdir -p dir/dir2/dir3

# Send a command's output to file.txt, no STDOUT
ls > file.txt

# Send a command's output to file.txt AND see it in STDOUT
ls | tee /tmp/file.txt

# Search and Replace within a file
sed -i 's/original-text/new-text/g' <filename>
```

### Voir toutes les variables d'environnement définies {#see-all-set-environment-variables}

```shell
env
```

## Recherche {#searching}

### Noms de fichiers {#filenames}

```shell
# search for a file in a filesystem
find . -name 'filename.rb' -print

# locate a file
locate <filename>

# see command history
history

# search CLI history
<Control>-R
```

### Contenu des fichiers {#file-contents}

```shell
# -B/A = show 2 lines before/after search_term
grep -B 2 -A 2 search_term <filename>

# -<number> shows both before and after
grep -2 search_term <filename>

# Search on all files in directory (recursively)
grep -r search_term <directory>

# Grep namespace/project/name of a GitLab repository
grep 'fullpath' /var/opt/gitlab/git-data/repositories/@hashed/<repo hash>/.git/config

# search through *.gz files is the same except with zgrep
zgrep search_term <filename>

# Fast grep printing lines containing a string pattern
fgrep -R string_pattern <filename or directory>
```

### CLI {#cli}

```shell
# View command history
history

# Run last command that started with 'his' (3 letters min)
!his

# Search through command history
<Control>-R


# Execute last command with sudo
sudo !!
```

## Gestion des ressources {#managing-resources}

### Utilisation de la mémoire, du disque et du CPU {#memory-disk--cpu-usage}

```shell
# disk space info. The '-h' gives the data in human-readable values
df -h

# size of each file/dir and its contents in the current dir
du -hd 1

# or alternative
du -h --max-depth=1

# find files greater than certain size(k, M, G) and list them in order
# get rid of the + for exact, - for less than
find / -type f -size +100M -print0 | xargs -0 du -hs | sort -h

# Find free memory on a system
free -m

# Find what processes are using memory/CPU and organize by it
# Load average is 1/CPU for 1, 5, and 15 minutes
top -o %MEM
top -o %CPU
```

### Strace {#strace}

```shell
# strace a process
strace -tt -T -f -y -yy -s 1024 -p <pid>

# -tt   print timestamps with microsecond accuracy

# -T    print the time spent in each syscall

# -f    also trace any child processes that forked

# -y    print the path associated with file handles

# -yy    print socket and device file handle details

# -s    max string length to print for an event

# -o    output file

# run strace on all puma processes
ps auwx | grep puma | awk '{ print " -p " $2}' | xargs strace -tt -T -f -y -yy -s 1024 -o /tmp/puma.txt
```

Sachez que strace peut avoir des impacts majeurs sur les performances du système lorsqu'il est en cours d'exécution.

#### Ressources Strace {#strace-resources}

- Consultez le [zine strace](https://wizardzines.com/zines/strace/) pour une présentation rapide.
- Brendan Gregg propose une explication plus détaillée sur [comment utiliser strace](http://www.brendangregg.com/blog/2014-05-11/strace-wow-much-syscall.html).
- Nous disposons d'une [série de vidéos GitLab Unfiltered](https://www.youtube.com/playlist?list=PL05JrBw4t0KoC7cIkoAFcRhr4gsVesekg) sur l'utilisation de strace pour comprendre GitLab.

### L'outil Strace Parser {#the-strace-parser-tool}

Notre [outil strace-parser](https://gitlab.com/wchandler/strace-parser) peut être utilisé pour fournir un résumé de haut niveau de la sortie `strace`. Il est similaire à `strace -C`, mais fournit des statistiques bien plus détaillées.

Les binaires MacOS et Linux [sont disponibles](https://gitlab.com/gitlab-com/support/toolbox/strace-parser/-/tags), ou vous pouvez le compiler depuis les sources si vous disposez du compilateur Rust.

#### Comment utiliser l'outil {#how-to-use-the-tool}

Exécutez d'abord l'outil avec le drapeau `summary` pour obtenir un résumé des principaux processus triés par temps passé à effectuer activement des tâches. Vous pouvez également trier en fonction du temps total, du nombre d'appels système effectués, du numéro de PID et du nombre de processus enfants à l'aide du drapeau `-s` ou `--sort`. Le nombre de résultats est par défaut de 25 processus, mais peut être modifié à l'aide de l'option `-c`/`--count`. Consultez `--help` pour les détails complets.

```shell
$ ./strace-parser sidekiq_trace.txt summary -c15 -s=pid

Top 15 PIDs by PID #
-----------

  pid         actv (ms)     wait (ms)     user (ms)    total (ms)    % of actv     syscalls     children
  -------    ----------    ----------    ----------    ----------    ---------    ---------    ---------
  16706           0.000         0.000         0.000         0.000        0.00%            0            0
  16708           0.000         0.000         0.000         0.000        0.00%            0            0
  16716           0.000         0.000         0.000         0.000        0.00%            0            0
  16717           0.000         0.000         0.000         0.000        0.00%            0            0
  16718           0.000         0.000         0.000         0.000        0.00%            0            0
  16719           0.000         0.000         0.000         0.000        0.00%            0            0
  16720           0.389      9796.434         1.090      9797.912        0.02%           16            0
  16721           0.000         0.000         0.000         0.000        0.00%            0            0
  16722           0.000         0.000         0.000         0.000        0.00%            0            0
  16723           0.000         0.000         0.000         0.000        0.00%            0            0
  16804           0.218     11099.535         1.881     11101.634        0.01%           36            0
  16813           0.000         0.000         0.000         0.000        0.00%            0            0
  16814           1.740     11825.640         4.616     11831.996        0.10%           57            0
  16815           2.364     12039.993         7.669     12050.026        0.14%           80            0
  16816           0.000         0.000         0.000         0.000        0.00%            0            0

PIDs   93
real   0m12.287s
user   0m1.474s
sys    0m1.686s
```

Sur la base du résumé, vous pouvez ensuite afficher les détails des appels système effectués par un ou plusieurs processus à l'aide de `-p`/`--pid` pour un processus spécifique, ou des drapeaux `-s`/`--stats` pour une liste triée. `--stats` prend les mêmes options de tri et de comptage que summary.

```shell
./strace-parser sidekiq_trace.txt p 16815

PID 16815

  80 syscalls, active time: 2.364ms, user time: 7.669ms, total time: 12050.026ms
  start time: 22:46:14.830267    end time: 22:46:26.880293

  syscall                 count    total (ms)      max (ms)      avg (ms)      min (ms)    errors
  -----------------    --------    ----------    ----------    ----------    ----------    --------
  futex                       5     10100.229      5400.106      2020.046         0.022    ETIMEDOUT: 2
  restart_syscall             1      1939.764      1939.764      1939.764      1939.764    ETIMEDOUT: 1
  getpid                     33         1.020         0.046         0.031         0.018
  clock_gettime              14         0.420         0.038         0.030         0.021
  stat                        6         0.277         0.072         0.046         0.031
  read                        6         0.170         0.036         0.028         0.020
  openat                      3         0.126         0.045         0.042         0.038
  close                       3         0.099         0.034         0.033         0.031
  lseek                       3         0.089         0.035         0.030         0.021
  ioctl                       3         0.082         0.033         0.027         0.023    ENOTTY: 3
  fstat                       3         0.081         0.034         0.027         0.022
  ---------------

  Slowest file open times for PID 16815:

    dur (ms)       timestamp            error         filename
  ----------    ---------------    ---------------    ---------
       0.045    22:46:16.771318           -           /opt/gitlab/embedded/service/gitlab-rails/config/database.yml
       0.043    22:46:26.877954           -           /opt/gitlab/embedded/service/gitlab-rails/config/database.yml
       0.038    22:46:22.174610           -           /opt/gitlab/embedded/service/gitlab-rails/config/database.yml
```

Dans l'exemple précédent, nous pouvons voir quels fichiers ont pris plus de temps à ouvrir pour `PID 16815`.

Lorsque rien ne ressort des résultats, une bonne façon d'obtenir plus de contexte est d'exécuter `strace` sur votre propre instance GitLab pendant que vous effectuez l'action réalisée par le client, puis de comparer les résumés des deux résultats et d'examiner les différences.

#### Statistiques pour le syscall open {#stats-for-the-open-syscall}

Chiffres approximatifs pour les appels à `open` et `openat` (utilisés pour accéder aux fichiers) sur diverses configurations. Un stockage lent peut provoquer la redoutable erreur `DeadlineExceeded` dans Gitaly.

Consultez également [cette entrée](../operations/filesystem_benchmarking.md) dans le manuel pour des tests rapides que les clients peuvent effectuer afin de vérifier les performances de leur système de fichiers.

Gardez à l'esprit que les informations de synchronisation provenant de `strace` sont souvent quelque peu inexactes, de sorte que les petites différences ne doivent pas être considérées comme significatives.

|Configuration          | temps d'accès  |
|:--------------|:--------------|
| EFS           | 10 - 30 ms     |
| Stockage local | 0,01 - 1 ms    |

## Réseau {#networking}

### Ports {#ports}

```shell
# Find the programs that are listening on ports
netstat -plnt
ss -plnt
lsof -i -P | grep <port>
```

### Internet/DNS {#internetdns}

```shell
# Show domain IP address
dig +short example.com
nslookup example.com

# Check DNS using specific nameserver
# 8.8.8.8 = google, 1.1.1.1 = cloudflare, 208.67.222.222 = opendns
dig @8.8.8.8 example.com
nslookup example.com 1.1.1.1

# Find host provider
whois <ip_address> | grep -i "orgname\|netname"

# Curl headers with redirect
curl --head --location "https://example.com"

# Test if a host is reachable on the network. `ping6` works on IPv6 networks.
ping example.com

# Show the route taken to a host. `traceroute6` works on IPv6 networks.
traceroute example.com
mtr example.com

# List details of network interfaces
ip address

# Check local DNS settings
cat /etc/hosts
cat /etc/resolv.conf
systemd-resolve --status

# Capture traffic to/from a host
sudo tcpdump host www.example.com
```

## Gestion des paquets {#package-management}

```shell
# Debian/Ubuntu

# List packages
dpkg -l
apt list --installed

# Find an installed package
dpkg -l | grep <package>
apt list --installed | grep <package>

# Install a package
dpkg -i <package_name>.deb
apt-get install <package>
apt install <package>

# CentOS/RedHat

# Install a package
yum install <package>
dnf install <package> # RHEL/CentOS 8+

rpm -ivh <package_name>.rpm

# Find an installed package
rpm -qa | grep <package>
```

## Journaux {#logs}

```shell
# Print last lines in log file where 'n'
# is the number of lines to print
tail -n /path/to/log/file
```
