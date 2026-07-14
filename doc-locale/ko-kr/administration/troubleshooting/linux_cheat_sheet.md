---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linux 치트 시트
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

이것은 GitLab 지원팀이 Linux와 관련하여 수집한 정보로, 문제를 해결할 때 때때로 사용합니다. 이 정보는 투명성을 위해 나열되었으며, Linux 경험이 있는 사용자를 위한 것입니다. 현재 GitLab 문제가 발생하는 경우, 이 정보를 사용하기 전에 먼저 [지원 옵션](https://about.gitlab.com/support/)을 확인하는 것이 좋습니다.

> [!warning]
> GitLab 지원이 [시스템 관리 지원을 벗어난 범위](https://about.gitlab.com/support/statement-of-support/#training)입니다. GitLab 관리자는 자신이 선택한 배포판에 대해 이러한 명령을 알아야 합니다. GitLab 지원 엔지니어인 경우, 이것을 `yum` -> `apt-get` 등으로 변환하는 상호 참조로 고려하세요.

아래의 대부분의 명령어는 어떤 배포판에서 작동하는지 표시되지 않습니다. 이를 추가하는 데 도움이 될 기여를 환영합니다.

## 시스템 명령어 {#system-commands}

### 배포판 정보 {#distribution-information}

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

### 종료 또는 재부팅 {#shut-down-or-reboot}

```shell
shutdown -h now
reboot
```

### 권한 {#permissions}

```shell
# change the user:group ownership of a file/dir
chown root:git <file_or_dir>

# make a file executable
chmod u+x <file>
```

### 파일 및 디렉토리 {#files-and-directories}

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

### 설정된 모든 환경 변수 보기 {#see-all-set-environment-variables}

```shell
env
```

## 검색 {#searching}

### 파일 이름 {#filenames}

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

### 파일 내용 {#file-contents}

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

## 리소스 관리 {#managing-resources}

### 메모리, 디스크 및 CPU 사용량 {#memory-disk--cpu-usage}

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

strace가 실행 중일 때 시스템 성능에 큰 영향을 미칠 수 있음을 유의하세요.

#### Strace 리소스 {#strace-resources}

- [strace zine](https://wizardzines.com/zines/strace/)을 참조하여 빠른 설명을 확인하세요.
- Brendan Gregg는 [strace 사용 방법](http://www.brendangregg.com/blog/2014-05-11/strace-wow-much-syscall.html)에 대해 더 자세한 설명을 제공합니다.
- GitLab을 이해하기 위해 strace를 사용하는 방법에 대한 [GitLab Unfiltered 비디오 시리즈](https://www.youtube.com/playlist?list=PL05JrBw4t0KoC7cIkoAFcRhr4gsVesekg)가 있습니다.

### Strace Parser 도구 {#the-strace-parser-tool}

우리의 [strace-parser 도구](https://gitlab.com/wchandler/strace-parser)를 사용하여 `strace` 출력의 높은 수준의 요약을 제공할 수 있습니다. `strace -C`과 유사하지만 훨씬 더 자세한 통계를 제공합니다.

MacOS 및 Linux 바이너리는 [사용 가능](https://gitlab.com/gitlab-com/support/toolbox/strace-parser/-/tags)하거나 Rust 컴파일러가 있으면 소스에서 빌드할 수 있습니다.

#### 도구 사용 방법 {#how-to-use-the-tool}

먼저 `summary` 플래그를 사용하여 도구를 실행하여 시간에 따라 정렬된 상위 프로세스의 요약을 얻습니다. `-s` 또는 `--sort` 플래그를 사용하여 총 시간, 시스템 호출 수, PID 수 및 자식 프로세스 수를 기준으로 정렬할 수도 있습니다. 결과 수는 기본적으로 25개 프로세스이지만 `-c`/`--count` 옵션을 사용하여 변경할 수 있습니다. 전체 세부 정보는 `--help`을 참조하세요.

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

요약을 기반으로 `-p`/`--pid`를 사용하여 특정 프로세스의 시스템 호출 세부 정보를 보거나 `-s`/`--stats` 플래그를 사용하여 정렬된 목록을 볼 수 있습니다. `--stats`는 요약과 동일한 정렬 및 개수 옵션을 사용합니다.

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

이전 예제에서 `PID 16815`에서 열기에 더 오래 걸린 파일을 확인할 수 있습니다.

결과에서 특별히 눈에 띄는 것이 없으면, 고객이 수행하는 작업을 수행하면서 자신의 GitLab 인스턴스에서 `strace`을 실행한 후 두 결과의 요약을 비교하고 차이점을 자세히 살펴보는 것이 좋습니다.

#### 개방형 시스템 호출의 통계 {#stats-for-the-open-syscall}

`open` 및 `openat` 호출(파일 액세스에 사용)의 대략적인 수치입니다(다양한 구성에서). 느린 스토리지는 Gitaly에서 `DeadlineExceeded` 오류를 야기할 수 있습니다.

파일 시스템 성능을 확인하기 위해 고객이 수행할 수 있는 빠른 테스트를 위해 핸드북에서 [이 항목을 참조](../operations/filesystem_benchmarking.md)하세요.

`strace`의 타이밍 정보는 종종 다소 부정확하므로 작은 차이는 의미 있는 것으로 간주되지 않아야 함을 명심하세요.

|설정          | 액세스 시간  |
|:--------------|:--------------|
| EFS           | 10 - 30ms     |
| 로컬 스토리지 | 0.01 - 1ms    |

## 네트워킹 {#networking}

### 포트 {#ports}

```shell
# Find the programs that are listening on ports
netstat -plnt
ss -plnt
lsof -i -P | grep <port>
```

### 인터넷/DNS {#internetdns}

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

## 패키지 관리 {#package-management}

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

## 로그 {#logs}

```shell
# Print last lines in log file where 'n'
# is the number of lines to print
tail -n /path/to/log/file
```
