---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Installer, configurer et mettre à niveau GitLab en utilisant le package Linux."
title: "Installer GitLab à l'aide du package Linux"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Les packages Linux sont matures, évolutifs et sont utilisés sur GitLab.com. Si vous avez besoin de davantage de flexibilité et de résilience, nous recommandons de déployer GitLab comme décrit dans la [documentation sur l'architecture de référence](../../administration/reference_architectures/_index.md).

Le package Linux est plus rapide à installer, plus facile à mettre à niveau et contient des fonctionnalités pour améliorer la fiabilité que l'on ne trouve pas dans d'autres méthodes d'installation. L'installation s'effectue via un package unique (également connu sous le nom d'Omnibus GitLab) qui regroupe tous les services et outils nécessaires à l'exécution de GitLab. Consultez les [conditions d'installation](../requirements.md) pour en savoir plus sur les configurations matérielles minimales requises.

Les packages Linux sont disponibles dans notre dépôt de packages pour :

- [GitLab Enterprise Edition](https://packages.gitlab.com/ui/browse/gitlab/gitlab-ee).
- [GitLab Community Edition](https://packages.gitlab.com/ui/browse/gitlab/gitlab-ce).

Vérifiez que la version de GitLab requise est disponible pour votre système d'exploitation hôte.

## Plateformes prises en charge {#supported-platforms}

GitLab fournit des packages Linux pour les systèmes d'exploitation répertoriés ci-dessous. Nous créons et distribuons des packages pour ces plateformes. Le tableau indique quelles versions de GitLab sont disponibles pour chaque système d'exploitation.

Nous fournissons des packages Linux pour les systèmes d'exploitation en fonction des cycles de vie de support des fournisseurs. Lorsque des versions à support à long terme (LTS) existent, nous les ciblons, bien que tous les systèmes d'exploitation ne suivent pas un modèle LTS.

Les compilations de packages se poursuivent généralement jusqu'à ce qu'un système d'exploitation atteigne la fin de vie (EOL) du fournisseur. Nous suivons les calendriers de support standard ou de maintenance, et non les périodes de support étendu ou premium.

Nous pouvons interrompre les compilations de packages avant la fin de vie du fournisseur pour les raisons suivantes :

- Considérations commerciales :  Y compris, sans s'y limiter, la faible adoption par les clients, les coûts de maintenance disproportionnés ou les changements de direction stratégique du produit.
- Contraintes techniques :  Lorsque des dépendances tierces, des exigences de sécurité ou des changements technologiques sous-jacents rendent la poursuite des compilations de packages peu pratique ou impossible.
- Actions du fournisseur :  Lorsque les fournisseurs de systèmes d'exploitation apportent des modifications qui ont un impact fondamental sur les fonctionnalités de notre logiciel ou lorsque des composants requis deviennent indisponibles.

Nous nous efforçons de fournir un préavis d'au moins 6 mois avant d'interrompre le support de toute version de système d'exploitation. Lorsque des limitations techniques ou des contraintes du fournisseur nécessitent un préavis plus court, nous communiquerons les changements dès que possible.

> [!note]
> `amd64` et `x86_64` font référence à la même architecture 64 bits. Les noms `arm64` et `aarch64` sont également interchangeables et font référence à la même architecture.

| Système d'exploitation                                                                   | Première version GitLab prise en charge | Architecture          | Fin de vie du système d'exploitation | Dernière version GitLab prise en charge proposée  | Notes de release en amont                                                                                        |
|------------------------------------------------------------------------------------|--------------------------------|-----------------------|----------------------|-------------------------------|---------------------------------------------------------------------------------------------------------------|
| [AlmaLinux 8](almalinux.md)                         | GitLab CE / GitLab EE 14.5.0   | `x86_64`, `aarch64` <sup>1</sup> | Mar 2029             | GitLab CE / GitLab EE 21.10.0 | [Détails AlmaLinux](https://almalinux.org/)                                                                   |
| [AlmaLinux 9](almalinux.md)                         | GitLab CE / GitLab EE 16.0.0   | `x86_64`, `aarch64` <sup>1</sup> | Mai 2032             | GitLab CE / GitLab EE 25.0.0  | [Détails AlmaLinux](https://almalinux.org/)                                                                   |
| [AlmaLinux 10](almalinux.md)                         | GitLab CE / GitLab EE 18.6.0   | `x86_64`, `aarch64` <sup>1</sup> | Mai 2035             | GitLab CE / GitLab EE 28.0.0  | [Détails AlmaLinux](https://almalinux.org/)                                                                  |
| [Amazon Linux 2](amazonlinux_2.md)                  | GitLab CE / GitLab EE 14.9.0   | `amd64`, `arm64` <sup>1</sup>    | Juin 2026            | GitLab CE / GitLab EE 19.1.0  | [Détails Amazon Linux](https://aws.amazon.com/amazon-linux-2/faqs/)                                           |
| [Amazon Linux 2023](amazonlinux_2023.md)            | GitLab CE / GitLab EE 16.3.0   | `amd64`, `arm64` <sup>1</sup>    | Juin 2029            | GitLab CE / GitLab EE 22.1.0  | [Détails Amazon Linux](https://docs.aws.amazon.com/linux/al2023/ug/release-cadence.html)                      |
| [Debian 11](debian.md)                              | GitLab CE / GitLab EE 14.6.0   | `amd64`, `arm64` <sup>1</sup>    | Août 2026             | GitLab CE / GitLab EE 19.3.0  | [Détails Debian Linux](https://wiki.debian.org/LTS)                                                           |
| [Debian 12](debian.md)                              | GitLab CE / GitLab EE 16.1.0   | `amd64`, `arm64` <sup>1</sup>    | Juin 2028            | GitLab CE / GitLab EE 19.3.0  | [Détails Debian Linux](https://wiki.debian.org/LTS)                                                           |
| [Debian 13](debian.md)                              | GitLab CE / GitLab EE 18.5.0   | `amd64`, `arm64` <sup>1</sup>    | Juin 2030            | GitLab CE / GitLab EE 23.1.0  | [Détails Debian Linux](https://wiki.debian.org/LTS)                                                           |
| [openSUSE Leap 15.6](suse.md)              | GitLab CE / GitLab EE 17.6.0   | `x86_64`, `aarch64` <sup>1</sup> | Déc 2025             | À définir  | [Détails openSUSE](https://en.opensuse.org/Lifetime)                                                          |
| [SUSE Linux Enterprise Server 12](suse.md) | GitLab EE 9.0.0                | `x86_64`              | Oct 2027             | À définir  | [Détails SUSE Linux Enterprise Server](https://www.suse.com/lifecycle/)                                       |
| [SUSE Linux Enterprise Server 15](suse.md) | GitLab EE 14.8.0               | `x86_64`              | Déc 2024             | À définir  | [Détails SUSE Linux Enterprise Server](https://www.suse.com/lifecycle/)                                       |
| [Oracle Linux 8](almalinux.md)                      | GitLab CE / GitLab EE 12.8.1   | `x86_64`              | Juillet 2029            | GitLab CE / GitLab EE 22.2.0  | [Détails Oracle Linux](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf)                           |
| [Oracle Linux 9](almalinux.md)                      | GitLab CE / GitLab EE 16.2.0   | `x86_64`              | Juin 2032            | GitLab CE / GitLab EE 25.1.0  | [Détails Oracle Linux](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf)                           |
| [Oracle Linux 10](almalinux.md)                      | GitLab CE / GitLab EE 18.6.0   | `x86_64`              | Juin 2035            | GitLab CE / GitLab EE 28.1.0  | [Détails Oracle Linux](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf)                           |
| [Red Hat Enterprise Linux 8](almalinux.md)          | GitLab CE / GitLab EE 12.8.1   | `x86_64`, `arm64` <sup>1</sup>   | Mai 2029             | GitLab CE / GitLab EE 22.0.0  | [Détails Red Hat Enterprise Linux](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Red Hat Enterprise Linux 9](almalinux.md)          | GitLab CE / GitLab EE 16.0.0   | `x86_64`, `arm64` <sup>1</sup>   | Mai 2032             | GitLab CE / GitLab EE 25.0.0  | [Détails Red Hat Enterprise Linux](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Red Hat Enterprise Linux 10](almalinux.md)          | GitLab CE / GitLab EE 18.6.0   | `x86_64`, `arm64` <sup>1</sup>   | Mai 2035             | GitLab CE / GitLab EE 28.0.0  | [Détails Red Hat Enterprise Linux](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Ubuntu 22.04](ubuntu.md)                           | GitLab CE / GitLab EE 15.5.0   | `amd64`, `arm64` <sup>1</sup>    | Avril 2027           | GitLab CE / GitLab EE 19.11.0 | [Détails Ubuntu](https://wiki.ubuntu.com/Releases). Les packages FIPS ont été ajoutés dans GitLab 18.4. Avant de mettre à niveau depuis Ubuntu 20.04, consultez les [notes de mise à niveau](#ubuntu-2204-fips). |
| [Ubuntu 24.04](ubuntu.md)                           | GitLab CE / GitLab EE 17.1.0   | `amd64`, `arm64` <sup>1</sup>    | Avril 2029           | GitLab CE / GitLab EE 21.11.0 | [Détails Ubuntu](https://wiki.ubuntu.com/Releases)                                                            |

**Footnotes** :

1. Des [problèmes connus](https://gitlab.com/groups/gitlab-org/-/epics/4397) existent lors de l'exécution de GitLab sur ARM.

### Méthodes d'installation non officielles et non prises en charge {#unofficial-unsupported-installation-methods}

Les méthodes d'installation suivantes sont fournies telles quelles par la communauté GitLab au sens large et ne sont pas prises en charge par GitLab :

- [Package natif Debian](https://wiki.debian.org/gitlab/) (par Pirate Praveen)
- [Package FreeBSD](http://www.freshports.org/www/gitlab-ce) (par Torsten Zühlsdorff)
- [Package Arch Linux](https://archlinux.org/packages/extra/x86_64/gitlab/) (par la communauté Arch Linux)
- [Module Puppet](https://forge.puppet.com/puppet/gitlab) (par Vox Pupuli)
- [Playbook Ansible](https://github.com/geerlingguy/ansible-role-gitlab) (par Jeff Geerling)
- [Appliance virtuelle GitLab (KVM)](https://marketplace.opennebula.io/appliance/6b54a412-03a5-11e9-8652-f0def1753696) (par OpenNebula)
- [GitLab sur Cloudron](https://cloudron.io/store/com.gitlab.cloudronapp.html) (via la bibliothèque d'applications Cloudron)

## Versions en fin de vie {#end-of-life-versions}

Vous trouverez ci-dessous la liste des systèmes d'exploitation obsolètes et la dernière release GitLab pour chacun d'eux :

| Version du système d'exploitation       | Fin de vie                                                                         | Dernière version GitLab prise en charge |
|:-----------------|:------------------------------------------------------------------------------------|:------------------------------|
| CentOS 6 et RHEL 6 | [Novembre 2020](https://www.centos.org/about/)                                   | GitLab CE / GitLab EE 13.6 |
| CentOS 7 et RHEL 7 | [Juin 2024](https://www.centos.org/about/)                                       | GitLab CE / GitLab EE 17.7 |
| CentOS 8         | [Décembre 2021](https://www.centos.org/about/)                                      | GitLab CE / GitLab EE 14.6 |
| Oracle Linux 7   | [Décembre 2024](https://endoflife.date/oracle-linux)                                | GitLab CE / GitLab EE 17.7 |
| Scientific Linux 7 | [Juin 2024](https://scientificlinux.org/downloads/sl-versions/sl7/)               | GitLab CE / GitLab EE 17.7 |
| Debian 7 Wheezy  | [Mai 2018](https://www.debian.org/News/2018/20180601)                               | GitLab CE / GitLab EE 11.6 |
| Debian 8 Jessie  | [Juin 2020](https://www.debian.org/News/2020/20200709)                              | GitLab CE / GitLab EE 13.3 |
| Debian 9 Stretch | [Juin 2022](https://lists.debian.org/debian-lts-announce/2022/07/msg00002.html)     | GitLab CE / GitLab EE 15.2 |
| Debian 10 Buster | [Juin 2024](https://www.debian.org/News/2024/20240615)                              | GitLab CE / GitLab EE 17.5 |
| OpenSUSE 42.1    | [Mai 2017](https://en.opensuse.org/Lifetime#Discontinued_distributions)             | GitLab CE / GitLab EE 9.3 |
| OpenSUSE 42.2    | [Janvier 2018](https://en.opensuse.org/Lifetime#Discontinued_distributions)         | GitLab CE / GitLab EE 10.4 |
| OpenSUSE 42.3    | [Juillet 2019](https://en.opensuse.org/Lifetime#Discontinued_distributions)            | GitLab CE / GitLab EE 12.1 |
| OpenSUSE 13.2    | [Janvier 2017](https://en.opensuse.org/Lifetime#Discontinued_distributions)         | GitLab CE / GitLab EE 9.1 |
| OpenSUSE 15.0    | [Décembre 2019](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | GitLab CE / GitLab EE 12.5 |
| OpenSUSE 15.1    | [Novembre 2020](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | GitLab CE / GitLab EE 13.12 |
| OpenSUSE 15.2    | [Décembre 2021](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | GitLab CE / GitLab EE 14.7 |
| OpenSUSE 15.3    | [Décembre 2022](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | GitLab CE / GitLab EE 15.10 |
| OpenSUSE 15.4    | [Décembre 2023](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | GitLab CE / GitLab EE 16.7 |
| OpenSUSE 15.5    | [Décembre 2024](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | GitLab CE / GitLab EE 17.8 |
| SLES 15 SP2      | [Décembre 2024](https://www.suse.com/lifecycle/#suse-linux-enterprise-server-15)    | GitLab EE 18.1 |
| Raspbian Wheezy  | [Mai 2015](https://downloads.raspberrypi.org/raspbian/images/raspbian-2015-05-07/)  | GitLab CE 8.17 |
| Raspbian Jessie  | [Mai 2017](https://downloads.raspberrypi.org/raspbian/images/raspbian-2017-07-05/)  | GitLab CE 11.7 |
| Raspbian Stretch | [Juin 2020](https://downloads.raspberrypi.org/raspbian/images/raspbian-2019-04-09/) | GitLab CE 13.3 |
| Raspberry Pi OS Buster | [Juin 2024](https://www.debian.org/News/2024/20240615)                        | GitLab CE 17.7 |
| Ubuntu 12.04     | [Avril 2017](https://ubuntu.com/info/release-end-of-life)                           | GitLab CE / GitLab EE 9.1 |
| Ubuntu 14.04     | [Avril 2019](https://ubuntu.com/info/release-end-of-life)                           | GitLab CE / GitLab EE 11.10 |
| Ubuntu 16.04     | [Avril 2021](https://ubuntu.com/info/release-end-of-life)                           | GitLab CE / GitLab EE 13.12 |
| Ubuntu 18.04     | [Juin 2023](https://ubuntu.com/info/release-end-of-life)                            | GitLab CE / GitLab EE 16.11 |
| Ubuntu 20.04     | [Mai 2025](https://ubuntu.com/info/release-end-of-life)                            | GitLab CE / GitLab EE 18.11 |

### Raspberry Pi OS (32 bits - Raspbian) {#raspberry-pi-os-32-bit---raspbian}

GitLab a abandonné le support de Raspberry Pi OS (32 bits - Raspbian), GitLab 17.11 étant la dernière version disponible pour la plateforme 32 bits. À partir de GitLab 18.0, vous devez passer à Raspberry Pi OS (64 bits) et utiliser le [package Debian arm64](debian.md).

Pour obtenir des informations sur la sauvegarde des données sur un système d'exploitation 32 bits et leur restauration sur un système d'exploitation 64 bits, voir [Mise à niveau des systèmes d'exploitation pour PostgreSQL](../../administration/postgresql/upgrading_os.md).

## Désinstaller le package Linux {#uninstall-the-linux-package}

Pour désinstaller le package Linux, vous pouvez choisir de conserver vos données (dépôts, base de données, configuration) ou de les supprimer entièrement :

1. Facultatif. Pour supprimer [tous les utilisateurs et groupes créés par le package Linux](https://docs.gitlab.com/omnibus/settings/configuration/#disable-user-and-group-account-management) avant de supprimer le package :

   ```shell
   sudo gitlab-ctl stop && sudo gitlab-ctl remove-accounts
   ```

   > [!note]
   > Si vous rencontrez un problème lors de la suppression des comptes ou des groupes, exécutez `userdel` ou `groupdel` manuellement pour les supprimer. Vous pouvez également supprimer manuellement les répertoires personnels d'utilisateurs restants dans `/home/`.

1. Choisissez si vous souhaitez conserver vos données ou les supprimer entièrement :

   - Pour conserver vos données (dépôts, base de données, configuration), arrêtez GitLab et supprimez son processus de supervision :

     ```shell
     sudo systemctl stop gitlab-runsvdir
     sudo systemctl disable gitlab-runsvdir
     sudo rm /usr/lib/systemd/system/gitlab-runsvdir.service
     sudo systemctl daemon-reload
     sudo systemctl reset-failed
     sudo gitlab-ctl uninstall
     ```

   - Pour supprimer toutes les données :

     ```shell
     sudo gitlab-ctl cleanse && sudo rm -r /opt/gitlab
     ```

1. Désinstallez le package (remplacez par `gitlab-ce` si GitLab FOSS est installé) :

   {{< tabs >}}

   {{< tab title="apt" >}}

   ```shell
   # Debian/Ubuntu
   sudo apt remove gitlab-ee
   ```

   {{< /tab >}}

   {{< tab title="dnf" >}}

   ```shell
   # AlmaLinux/RHEL/Oracle Linux/Amazon Linux 2023
   sudo dnf remove gitlab-ee
   ```

   {{< /tab >}}

   {{< tab title="zypper" >}}

   ```shell
   # OpenSUSE Leap/SLES
   sudo zypper remove gitlab-ee
   ```

   {{< /tab >}}

   {{< tab title="yum" >}}

   ```shell
   # Amazon Linux 2
   sudo yum remove gitlab-ee
   ```

   {{< /tab >}}

   {{< /tabs >}}

### Ubuntu 22.04 FIPS {#ubuntu-2204-fips}

Dans GitLab 18.4 et versions ultérieures, les compilations FIPS sont disponibles pour Ubuntu 22.04.

Avant de procéder à la mise à niveau :

1. Vérifiez la migration du hachage de mot de passe pour tous les utilisateurs actifs :  Dans GitLab 17.11 et versions ultérieures, les mots de passe des utilisateurs sont automatiquement rehachés avec un sel amélioré lors de la connexion.

   Tout utilisateur n'ayant pas effectué cette migration de hachage ne pourra pas se connecter aux installations Ubuntu 22 FIPS et devra effectuer une réinitialisation de mot de passe.

   Pour identifier les utilisateurs qui n'ont pas migré, utilisez [cette tâche Rake](../../administration/raketasks/password.md#check-password-hashes) avant la mise à niveau vers Ubuntu 22.04.

1. Vérifiez le fichier JSON des secrets GitLab :  Rails nécessite désormais des sels de dispatch actifs plus robustes pour émettre des cookies. Le package Linux utilise des valeurs statiques d'une longueur suffisante par défaut sur Ubuntu 22.04. Cependant, vous pouvez personnaliser ces sels en définissant les clés suivantes dans votre configuration du package Linux :

   ```ruby
   gitlab_rails['signed_cookie_salt'] = 'custom value'
   gitlab_rails['authenticated_encrypted_cookie_salt'] = 'another custom value'
   ```

   Les valeurs sont écrites dans `gitlab-secrets.json` et doivent être synchronisées sur tous les nœuds Rails.

1. Préparez-vous à la migration des jetons OAuth lors de la mise à niveau vers FIPS 140-3 :  GitLab 18.6.0, 18.5.2 et 18.4.4 ont introduit le hachage SHA512 pour les jetons OAuth afin de se conformer aux exigences FIPS 140-3. Auparavant, GitLab utilisait PBKDF2 sans sel, ce qui est incompatible avec les systèmes conformes FIPS 140-3 tels qu'Ubuntu 22.04.

   > [!note]
   > Cette migration est uniquement requise lors du passage à des systèmes d'exploitation conformes FIPS 140-3 (tels qu'Ubuntu 22.04). Aucune modification n'est nécessaire si vous utilisez déjà des versions FIPS plus anciennes (telles qu'Ubuntu 20.04) ou si vous restez sur des systèmes non FIPS.

   Lors de la migration depuis une instance non FIPS ou une version FIPS plus ancienne vers une instance FIPS 140-3 :

   1. Mettez à niveau vers GitLab 18.4 ou version ultérieure.
   1. Accordez suffisamment de temps pour que les jetons d'accès OAuth actifs soient automatiquement rehachés lors d'une utilisation normale.
   1. Renouvelez les secrets d'application OAuth pour vous assurer que tous les jetons nouvellement émis utilisent l'algorithme de hachage conforme FIPS.
   1. Informez les utilisateurs qu'ils devront peut-être se réauthentifier auprès des applications intégrées OAuth si leurs jetons n'ont pas été utilisés récemment.
