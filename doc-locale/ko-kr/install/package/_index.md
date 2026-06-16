---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Linux 패키지를 사용하여 GitLab을 설치, 구성 및 업그레이드합니다."
title: Linux 패키지를 사용하여 GitLab 설치
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Linux 패키지는 성숙하고 확장 가능하며 GitLab.com에서 사용됩니다. 추가 유연성과 복원력이 필요한 경우 [참조 아키텍처 설명서](../../administration/reference_architectures/_index.md)에서 설명한 대로 GitLab을 배포하는 것을 권장합니다.

Linux 패키지는 설치가 빠르고 업그레이드가 쉬우며 다른 설치 방법에서 찾을 수 없는 신뢰성 향상 기능이 포함되어 있습니다. GitLab을 실행하는 데 필요한 모든 다양한 서비스와 도구를 번들로 제공하는 단일 패키지(Omnibus GitLab이라고도 함)를 통해 설치합니다. [설치 요구 사항](../requirements.md)을 참조하여 최소 하드웨어 요구 사항을 알아봅니다.

Linux 패키지는 패키지 리포지토리에서 다음과 같이 사용할 수 있습니다:

- [GitLab Enterprise Edition](https://packages.gitlab.com/ui/browse/gitlab/gitlab-ee)
- [GitLab Community Edition](https://packages.gitlab.com/ui/browse/gitlab/gitlab-ce)

필요한 GitLab 버전이 호스트 운영 체제에서 사용 가능한지 확인합니다.

## 지원되는 플랫폼 {#supported-platforms}

GitLab은 아래 나열된 운영 체제용 Linux 패키지를 제공합니다. 이러한 플랫폼용 패키지를 빌드하고 배포합니다. 표는 각 운영 체제에서 사용 가능한 GitLab 버전을 보여줍니다.

공급업체 지원 수명 주기를 기반으로 운영 체제용 Linux 패키지를 제공합니다. 장기 지원(LTS) 버전이 존재하는 경우 해당 버전을 대상으로 하지만 모든 운영 체제가 LTS 모델을 따르는 것은 아닙니다.

패키지 빌드는 일반적으로 운영 체제가 공급업체 지원 종료(EOL)에 도달할 때까지 계속됩니다. 표준 또는 유지 보수 지원 타임라인을 따르며, 확장 또는 프리미엄 지원 기간은 아닙니다.

공급업체 EOL 전에 다음 이유로 패키지 빌드를 중단할 수 있습니다:

- 비즈니스 고려 사항:  낮은 고객 채택, 불균형적인 유지 보수 비용, 또는 전략적 제품 방향 변경을 포함하되 이에 한정되지 않습니다.
- 기술적 제약:  타사 종속성, 보안 요구 사항 또는 기본 기술 변경이 계속된 패키지 빌드를 비실용적이거나 불가능하게 만드는 경우입니다.
- 공급업체 조치:  운영 체제 공급업체가 소프트웨어의 기능에 근본적으로 영향을 미치는 변경을 하거나 필요한 구성 요소를 사용할 수 없게 되는 경우입니다.

운영 체제 버전 지원을 중단하기 전에 최소 6개월의 공지를 제공하는 것을 목표로 합니다. 기술적 제한 사항이나 공급업체 제약으로 인해 더 짧은 공지가 필요한 경우 가능한 한 빨리 변경 사항을 알립니다.

> [!note]
> `amd64`와 `x86_64`은 동일한 64비트 아키텍처를 나타냅니다. `arm64`와 `aarch64`는 상호 교환 가능하며 동일한 아키텍처를 나타냅니다.

| 운영 체제                                                                   | 처음 지원되는 GitLab 버전 | 아키텍처          | 운영 체제 EOL | 제안된 마지막 지원 GitLab 버전  | 업스트림 릴리스 정보                                                                                        |
|------------------------------------------------------------------------------------|--------------------------------|-----------------------|----------------------|-------------------------------|---------------------------------------------------------------------------------------------------------------|
| [AlmaLinux 8](almalinux.md)                         | GitLab CE / GitLab EE 14.5.0   | `x86_64`, `aarch64` <sup>1</sup> | 2029년 3월             | GitLab CE / GitLab EE 21.10.0 | [AlmaLinux 정보](https://almalinux.org/)                                                                   |
| [AlmaLinux 9](almalinux.md)                         | GitLab CE / GitLab EE 16.0.0   | `x86_64`, `aarch64` <sup>1</sup> | 2032년 5월             | GitLab CE / GitLab EE 25.0.0  | [AlmaLinux 정보](https://almalinux.org/)                                                                   |
| [AlmaLinux 10](almalinux.md)                         | GitLab CE / GitLab EE 18.6.0   | `x86_64`, `aarch64` <sup>1</sup> | 2035년 5월             | GitLab CE / GitLab EE 28.0.0  | [AlmaLinux 정보](https://almalinux.org/)                                                                  |
| [Amazon Linux 2](amazonlinux_2.md)                  | GitLab CE / GitLab EE 14.9.0   | `amd64`, `arm64` <sup>1</sup>    | 2026년 6월            | GitLab CE / GitLab EE 19.1.0  | [Amazon Linux 정보](https://aws.amazon.com/amazon-linux-2/faqs/)                                           |
| [Amazon Linux 2023](amazonlinux_2023.md)            | GitLab CE / GitLab EE 16.3.0   | `amd64`, `arm64` <sup>1</sup>    | 2029년 6월            | GitLab CE / GitLab EE 22.1.0  | [Amazon Linux 정보](https://docs.aws.amazon.com/linux/al2023/ug/release-cadence.html)                      |
| [Debian 11](debian.md)                              | GitLab CE / GitLab EE 14.6.0   | `amd64`, `arm64` <sup>1</sup>    | 2026년 8월             | GitLab CE / GitLab EE 19.3.0  | [Debian Linux 정보](https://wiki.debian.org/LTS)                                                           |
| [Debian 12](debian.md)                              | GitLab CE / GitLab EE 16.1.0   | `amd64`, `arm64` <sup>1</sup>    | 2028년 6월            | GitLab CE / GitLab EE 19.3.0  | [Debian Linux 정보](https://wiki.debian.org/LTS)                                                           |
| [Debian 13](debian.md)                              | GitLab CE / GitLab EE 18.5.0   | `amd64`, `arm64` <sup>1</sup>    | 2030년 6월            | GitLab CE / GitLab EE 23.1.0  | [Debian Linux 정보](https://wiki.debian.org/LTS)                                                           |
| [openSUSE Leap 15.6](suse.md)              | GitLab CE / GitLab EE 17.6.0   | `x86_64`, `aarch64` <sup>1</sup> | 2025년 12월             | TBD  | [openSUSE 정보](https://en.opensuse.org/Lifetime)                                                          |
| [SUSE Linux Enterprise Server 12](suse.md) | GitLab EE 9.0.0                | `x86_64`              | 2027년 10월             | TBD  | [SUSE Linux Enterprise Server 정보](https://www.suse.com/lifecycle/)                                       |
| [SUSE Linux Enterprise Server 15](suse.md) | GitLab EE 14.8.0               | `x86_64`              | 2024년 12월             | TBD  | [SUSE Linux Enterprise Server 정보](https://www.suse.com/lifecycle/)                                       |
| [Oracle Linux 8](almalinux.md)                      | GitLab CE / GitLab EE 12.8.1   | `x86_64`              | 2029년 7월            | GitLab CE / GitLab EE 22.2.0  | [Oracle Linux 정보](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf)                           |
| [Oracle Linux 9](almalinux.md)                      | GitLab CE / GitLab EE 16.2.0   | `x86_64`              | 2032년 6월            | GitLab CE / GitLab EE 25.1.0  | [Oracle Linux 정보](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf)                           |
| [Oracle Linux 10](almalinux.md)                      | GitLab CE / GitLab EE 18.6.0   | `x86_64`              | 2035년 6월            | GitLab CE / GitLab EE 28.1.0  | [Oracle Linux 정보](https://www.oracle.com/a/ocom/docs/elsp-lifetime-069338.pdf)                           |
| [Red Hat Enterprise Linux 8](almalinux.md)          | GitLab CE / GitLab EE 12.8.1   | `x86_64`, `arm64` <sup>1</sup>   | 2029년 5월             | GitLab CE / GitLab EE 22.0.0  | [Red Hat Enterprise Linux 정보](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Red Hat Enterprise Linux 9](almalinux.md)          | GitLab CE / GitLab EE 16.0.0   | `x86_64`, `arm64` <sup>1</sup>   | 2032년 5월             | GitLab CE / GitLab EE 25.0.0  | [Red Hat Enterprise Linux 정보](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Red Hat Enterprise Linux 10](almalinux.md)          | GitLab CE / GitLab EE 18.6.0   | `x86_64`, `arm64` <sup>1</sup>   | 2035년 5월             | GitLab CE / GitLab EE 28.0.0  | [Red Hat Enterprise Linux 정보](https://access.redhat.com/support/policy/updates/errata/#Life_Cycle_Dates) |
| [Ubuntu 22.04](ubuntu.md)                           | GitLab CE / GitLab EE 15.5.0   | `amd64`, `arm64` <sup>1</sup>    | 2027년 4월           | GitLab CE / GitLab EE 19.11.0 | [Ubuntu 정보](https://wiki.ubuntu.com/Releases) FIPS 패키지는 GitLab 18.4에 추가되었습니다. Ubuntu 20.04에서 업그레이드하기 전에 [업그레이드 정보](#ubuntu-2204-fips)를 참조하십시오. |
| [Ubuntu 24.04](ubuntu.md)                           | GitLab CE / GitLab EE 17.1.0   | `amd64`, `arm64` <sup>1</sup>    | 2029년 4월           | GitLab CE / GitLab EE 21.11.0 | [Ubuntu 정보](https://wiki.ubuntu.com/Releases)                                                            |

**각주**:

1. [알려진 이슈](https://gitlab.com/groups/gitlab-org/-/epics/4397)가 ARM에서 GitLab을 실행하기 위해 존재합니다.

### 공식적이지 않은 지원되지 않는 설치 방법 {#unofficial-unsupported-installation-methods}

다음 설치 방법은 광범위한 GitLab 커뮤니티에서 제공되며 GitLab에서 지원되지 않습니다:

- [Debian 기본 패키지](https://wiki.debian.org/gitlab/) (Pirate Praveen 작성)
- [FreeBSD 패키지](http://www.freshports.org/www/gitlab-ce) (Torsten Zühlsdorff 작성)
- [Arch Linux 패키지](https://archlinux.org/packages/extra/x86_64/gitlab/) (Arch Linux 커뮤니티 작성)
- [Puppet 모듈](https://forge.puppet.com/puppet/gitlab) (Vox Pupuli 작성)
- [Ansible 플레이북](https://github.com/geerlingguy/ansible-role-gitlab) (Jeff Geerling 작성)
- [GitLab 가상 어플라이언스(KVM)](https://marketplace.opennebula.io/appliance/6b54a412-03a5-11e9-8652-f0def1753696) (OpenNebula 작성)
- [Cloudron의 GitLab](https://cloudron.io/store/com.gitlab.cloudronapp.html) (Cloudron 앱 라이브러리를 통해)

## 지원 종료 버전 {#end-of-life-versions}

아래 표에서 지원이 중단된 운영 체제 및 해당 최종 GitLab 릴리스 목록을 찾을 수 있습니다:

| OS 버전       | 지원 종료                                                                         | 지원되는 마지막 GitLab 버전 |
|:-----------------|:------------------------------------------------------------------------------------|:------------------------------|
| CentOS 6 및 RHEL 6 | [2020년 11월](https://www.centos.org/about/)                                   | GitLab CE / GitLab EE 13.6 |
| CentOS 7 및 RHEL 7 | [2024년 6월](https://www.centos.org/about/)                                       | GitLab CE / GitLab EE 17.7 |
| CentOS 8         | [2021년 12월](https://www.centos.org/about/)                                      | GitLab CE / GitLab EE 14.6 |
| Oracle Linux 7   | [2024년 12월](https://endoflife.date/oracle-linux)                                | GitLab CE / GitLab EE 17.7 |
| Scientific Linux 7 | [2024년 6월](https://scientificlinux.org/downloads/sl-versions/sl7/)               | GitLab CE / GitLab EE 17.7 |
| Debian 7 Wheezy  | [2018년 5월](https://www.debian.org/News/2018/20180601)                               | GitLab CE / GitLab EE 11.6 |
| Debian 8 Jessie  | [2020년 6월](https://www.debian.org/News/2020/20200709)                              | GitLab CE / GitLab EE 13.3 |
| Debian 9 Stretch | [2022년 6월](https://lists.debian.org/debian-lts-announce/2022/07/msg00002.html)     | GitLab CE / GitLab EE 15.2 |
| Debian 10 Buster | [2024년 6월](https://www.debian.org/News/2024/20240615)                              | GitLab CE / GitLab EE 17.5 |
| OpenSUSE 42.1    | [2017년 5월](https://en.opensuse.org/Lifetime#Discontinued_distributions)             | GitLab CE / GitLab EE 9.3 |
| OpenSUSE 42.2    | [2018년 1월](https://en.opensuse.org/Lifetime#Discontinued_distributions)         | GitLab CE / GitLab EE 10.4 |
| OpenSUSE 42.3    | [2019년 7월](https://en.opensuse.org/Lifetime#Discontinued_distributions)            | GitLab CE / GitLab EE 12.1 |
| OpenSUSE 13.2    | [2017년 1월](https://en.opensuse.org/Lifetime#Discontinued_distributions)         | GitLab CE / GitLab EE 9.1 |
| OpenSUSE 15.0    | [2019년 12월](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | GitLab CE / GitLab EE 12.5 |
| OpenSUSE 15.1    | [2020년 11월](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | GitLab CE / GitLab EE 13.12 |
| OpenSUSE 15.2    | [2021년 12월](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | GitLab CE / GitLab EE 14.7 |
| OpenSUSE 15.3    | [2022년 12월](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | GitLab CE / GitLab EE 15.10 |
| OpenSUSE 15.4    | [2023년 12월](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | GitLab CE / GitLab EE 16.7 |
| OpenSUSE 15.5    | [2024년 12월](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | GitLab CE / GitLab EE 17.8 |
| SLES 15 SP2      | [2024년 12월](https://www.suse.com/lifecycle/#suse-linux-enterprise-server-15)    | GitLab EE 18.1 |
| Raspbian Wheezy  | [2015년 5월](https://downloads.raspberrypi.org/raspbian/images/raspbian-2015-05-07/)  | GitLab CE 8.17 |
| Raspbian Jessie  | [2017년 5월](https://downloads.raspberrypi.org/raspbian/images/raspbian-2017-07-05/)  | GitLab CE 11.7 |
| Raspbian Stretch | [2020년 6월](https://downloads.raspberrypi.org/raspbian/images/raspbian-2019-04-09/) | GitLab CE 13.3 |
| Raspberry Pi OS Buster | [2024년 6월](https://www.debian.org/News/2024/20240615)                        | GitLab CE 17.7 |
| Ubuntu 12.04     | [2017년 4월](https://ubuntu.com/info/release-end-of-life)                           | GitLab CE / GitLab EE 9.1 |
| Ubuntu 14.04     | [2019년 4월](https://ubuntu.com/info/release-end-of-life)                           | GitLab CE / GitLab EE 11.10 |
| Ubuntu 16.04     | [2021년 4월](https://ubuntu.com/info/release-end-of-life)                           | GitLab CE / GitLab EE 13.12 |
| Ubuntu 18.04     | [2023년 6월](https://ubuntu.com/info/release-end-of-life)                            | GitLab CE / GitLab EE 16.11 |
| Ubuntu 20.04     | [2025년 5월](https://ubuntu.com/info/release-end-of-life)                            | GitLab CE / GitLab EE 18.11 |

### Raspberry Pi OS (32비트 - Raspbian) {#raspberry-pi-os-32-bit---raspbian}

GitLab은 Raspberry Pi OS(32비트 - Raspbian) 지원을 중단했으며, GitLab 17.11이 32비트 플랫폼에서 사용 가능한 마지막 버전입니다. GitLab 18.0부터 Raspberry Pi OS(64비트)로 이동하고 [Debian arm64 패키지](debian.md)를 사용해야 합니다.

32비트 OS에서 데이터를 백업하고 64비트 OS로 복원하는 방법에 대한 정보는 [PostgreSQL용 운영 체제 업그레이드](../../administration/postgresql/upgrading_os.md)를 참조하십시오.

## Linux 패키지 제거 {#uninstall-the-linux-package}

Linux 패키지를 제거하려면 데이터(리포지토리, 데이터베이스, 구성)를 유지하거나 모두 제거하도록 선택할 수 있습니다:

1. 선택사항. 패키지를 제거하기 전에 [Linux 패키지에서 생성된 모든 사용자 및 그룹](https://docs.gitlab.com/omnibus/settings/configuration/#disable-user-and-group-account-management)을 제거합니다:

   ```shell
   sudo gitlab-ctl stop && sudo gitlab-ctl remove-accounts
   ```

   > [!note]
   > 계정이나 그룹 제거에 문제가 있으면 `userdel` 또는 `groupdel`을 수동으로 실행하여 삭제합니다. `/home/`에서 남은 사용자 홈 디렉터리를 수동으로 제거할 수도 있습니다.

1. 데이터를 유지할지 또는 모두 제거할지 선택합니다:

   - 데이터(리포지토리, 데이터베이스, 구성)를 보존하려면 GitLab을 중지하고 해당 감독 프로세스를 제거합니다:

     ```shell
     sudo systemctl stop gitlab-runsvdir
     sudo systemctl disable gitlab-runsvdir
     sudo rm /usr/lib/systemd/system/gitlab-runsvdir.service
     sudo systemctl daemon-reload
     sudo systemctl reset-failed
     sudo gitlab-ctl uninstall
     ```

   - 모든 데이터를 제거하려면:

     ```shell
     sudo gitlab-ctl cleanse && sudo rm -r /opt/gitlab
     ```

1. 패키지 제거(GitLab FOSS가 설치되어 있으면 `gitlab-ce`로 바꿉니다):

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

GitLab 18.4 이상에서는 Ubuntu 22.04용 FIPS 빌드를 사용할 수 있습니다.

업그레이드하기 전에:

1. 모든 활성 사용자에 대한 암호 해시 마이그레이션 확인:  GitLab 17.11 이상에서는 사용자가 로그인할 때 사용자 암호가 자동으로 향상된 솔트로 재해시됩니다.

   이 해시 마이그레이션을 완료하지 않은 사용자는 Ubuntu 22 FIPS 설치에 로그인할 수 없으며 암호를 재설정해야 합니다.

   마이그레이션하지 않은 사용자를 찾으려면 Ubuntu 22.04로 업그레이드하기 전에 [이 Rake 작업](../../administration/raketasks/password.md#check-password-hashes)을 사용합니다.

1. GitLab 비밀 JSON 확인:  Rails는 이제 쿠키를 발급하기 위해 더 강력한 활성 디스패치 솔트가 필요합니다. Linux 패키지는 기본적으로 Ubuntu 22.04에서 충분한 길이의 정적 값을 사용합니다. 그러나 Linux 패키지 구성에서 다음 키를 설정하여 이러한 솔트를 사용자 지정할 수 있습니다:

   ```ruby
   gitlab_rails['signed_cookie_salt'] = 'custom value'
   gitlab_rails['authenticated_encrypted_cookie_salt'] = 'another custom value'
   ```

   값은 `gitlab-secrets.json`에 기록되며 모든 Rails 노드에서 동기화되어야 합니다.

1. FIPS 140-3로 업그레이드할 때 OAuth 토큰 마이그레이션 준비:  GitLab 18.6.0, 18.5.2 및 18.4.4는 FIPS 140-3 요구 사항을 준수하기 위해 OAuth 토큰용 SHA512 해싱을 도입했습니다. 이전에 GitLab은 FIPS 140-3 호환 시스템(예: Ubuntu 22.04)과 호환되지 않는 솔트 없이 PBKDF2를 사용했습니다.

   > [!note]
   > 이 마이그레이션은 FIPS 140-3 호환 운영 체제(예: Ubuntu 22.04)로 이동할 때만 필요합니다. 이미 이전 FIPS 버전(예: Ubuntu 20.04)에서 실행 중이거나 FIPS가 아닌 시스템에 남아 있으면 변경이 필요하지 않습니다.

   FIPS가 아닌 인스턴스 또는 이전 FIPS 버전에서 FIPS 140-3 인스턴스로 마이그레이션할 때:

   1. GitLab 18.4 이상으로 업그레이드합니다.
   1. 활성 OAuth 액세스 토큰이 정상적인 사용 중에 자동으로 재해시될 수 있는 충분한 시간을 허용합니다.
   1. 모든 새로 발급된 토큰이 FIPS 호환 해싱 알고리즘을 사용하도록 OAuth 애플리케이션 비밀을 회전합니다.
   1. 사용자에게 토큰을 최근에 사용하지 않은 경우 OAuth 통합 애플리케이션으로 재인증해야 할 수 있음을 알립니다.
