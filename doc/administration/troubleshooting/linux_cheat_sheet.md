---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linux cheat sheet
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

This is the GitLab Support Team's collection of information regarding Linux, that they
sometimes use while troubleshooting. It is listed here for transparency,
and for users with experience with Linux. If you are currently
having an issue with GitLab, you may want to check your [support options](https://about.gitlab.com/support/)
first, before attempting to use this information.

WARNING:
It is [beyond the scope of GitLab Support to assist in systems administration](https://about.gitlab.com/support/statement-of-support/#training). GitLab administrators are expected to know these commands for their distribution
of choice. If you are a GitLab Support Engineer, consider this a cross-reference to
translate `yum` -> `apt-get` and the like.

Most of the commands below have not been labeled as to which distribution they work
on. Contributions are welcome to help add them.

## System Commands

### Distribution Information

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

### Shut down or Reboot

```shell
shutdown -h now
reboot
```

### Permissions

```shell
# change the user:group ownership of a file/dir
chown root:git <file_or_dir>

# make a file executable
chmod u+x <file>
```

### Files and directories

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

### See all set environment variables

```shell
env
```

## Searching

### Filenames

```shell
# search for a file in a filesystem
find . -name 'filename.rb' -print

# locate a file
locate <filename>

# see command history
history

# search CLI history
<ctrl>-R
```

### File contents

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

### CLI

```shell
# View command history
history

# Run last command that started with 'his' (3 letters min)
!his

# Search through command history
<ctrl>-R


# Execute last command with sudo
sudo !!
```

## Managing resources

### Memory, Disk, & CPU usage

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

### Strace

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

Be aware that strace can have major impacts to system performance when it is running.

#### Strace Resources

- See the [strace zine](https://wizardzines.com/zines/strace/) for a quick walkthrough.
- Brendan Gregg has a more detailed explanation of [how to use strace](http://www.brendangregg.com/blog/2014-05-11/strace-wow-much-syscall.html).
- We have a [series of GitLab Unfiltered videos](https://www.youtube.com/playlist?list=PL05JrBw4t0KoC7cIkoAFcRhr4gsVesekg) on using strace to understand GitLab.

### The Strace Parser tool

Our [strace-parser tool](https://gitlab.com/wchandler/strace-parser) can be used to
provide a high level summary of the `strace` output. It is similar to `strace -C`,
but provides much more detailed statistics.

MacOS and Linux binaries [are available](https://gitlab.com/gitlab-com/support/toolbox/strace-parser/-/tags),
or you can build it from source if you have the Rust compiler.

#### How to use the tool

First run the tool with `summary` flag to get a summary of the top processes sorted by time spent actively performing tasks.
You can also sort based on total time, # of system calls made, PID #, and # of child processes
using the `-s` or `--sort` flag. The number of results defaults to 25 processes, but
can be changed using the `-c`/`--count` option. See `--help` for full details.

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

Based on the summary, you can then view the details of system calls made by one or more
processes using the `-p`/`--pid` for a specific process, or `-s`/`--stats` flags for
a sorted list. `--stats` takes the same sorting and count options as summary.

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

In the example above, we can see which files took longer to open for `PID 16815`.

When nothing stands out in the results, a good way to get more context is to run `strace`
on your own GitLab instance while performing the action performed by the customer,
then compare summaries of both results and dive into the differences.

#### Stats for the open syscall

Rough numbers for calls to `open` and `openat` (used to access files) on various configurations.
Slow storage can cause the dreaded `DeadlineExceeded` error in Gitaly.

Also [see this entry](../operations/filesystem_benchmarking.md)
in the handbook for quick tests customers can perform to check their file system performance.

Keep in mind that timing information from `strace` is often somewhat inaccurate, so
small differences should not be considered significant.

|Setup          | access times  |
|:--------------|:--------------|
| EFS           | 10 - 30 ms     |
| Local Storage | 0.01 - 1 ms    |

## Networking

### Ports

```shell
# Find the programs that are listening on ports
netstat -plnt
ss -plnt
lsof -i -P | grep <port>
```

### Internet/DNS

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

## Package Management

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

## Logs

```shell
# Print last lines in log file where 'n'
# is the number of lines to print
tail -n /path/to/log/file
```
