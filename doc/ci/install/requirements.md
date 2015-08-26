# Requirements

## Operating Systems

### Supported Unix distributions

- Ubuntu
- Debian
- CentOS
- Red Hat Enterprise Linux (please use the CentOS packages and instructions)
- Scientific Linux (please use the CentOS packages and instructions)
- Oracle Linux (please use the CentOS packages and instructions)

For the installations options please see [the installation page on the GitLab website](https://about.gitlab.com/installation/).

### Unsupported Unix distributions

- OS X
- Arch Linux
- Fedora
- Gentoo
- FreeBSD

### Non-Unix operating systems such as Windows

GitLab CI is developed for Unix operating systems.
GitLab CI does **not** run on Windows and we have no plans of supporting it in the near future.
Please consider using a virtual machine to run GitLab CI.

## Ruby versions

GitLab requires Ruby (MRI) 2.0 or 2.1
You will have to use the standard MRI implementation of Ruby.
We love [JRuby](http://jruby.org/) and [Rubinius](http://rubini.us/) but GitLab CI needs several Gems that have native extensions.


### Memory

You need at least 1GB of addressable memory (RAM + swap) to install and use GitLab CI!

## Unicorn Workers

It's possible to increase the amount of unicorn workers and this will usually help for to reduce the response time of the applications and increase the ability to handle parallel requests.

For most instances we recommend using: CPU cores + 1 = unicorn workers.
So for a machine with 2 cores, 3 unicorn workers is ideal.

For all machines that have 1GB and up we recommend a minimum of three unicorn workers.
If you have a 512MB machine with a magnetic (non-SSD) swap drive we recommend to configure only one Unicorn worker to prevent excessive swapping.
With one Unicorn worker only git over ssh access will work because the git over HTTP access requires two running workers (one worker to receive the user request and one worker for the authorization check).
If you have a 512MB machine with a SSD drive you can use two Unicorn workers, this will allow HTTP access although it will be slow due to swapping.

To change the Unicorn workers when you have the Omnibus package please see [the Unicorn settings in the Omnibus GitLab documentation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/unicorn.md#unicorn-settings).

## Supported web browsers

- Chrome (Latest stable version)
- Firefox (Latest released version and [latest ESR version](https://www.mozilla.org/en-US/firefox/organizations/))
- Safari 7+ (known problem: required fields in html5 do not work)
- Opera (Latest released version)
- IE 10+
