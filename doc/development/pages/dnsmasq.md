---
stage: Plan
group: Knowledge
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: "dnsmasq configuration guidelines for GitLab Pages"
title: Using `dnsmasq` to dynamically handle GitLab Pages subdomains
---

You can use [`dnsmasq`](https://wiki.debian.org/dnsmasq) to test
GitLab Pages sites locally without having to configure each site on `/etc/hosts`.

## Use `dnsmasq` on macOS

To use `dnsmasq` on macOS:

1. Install `dnsmasq`:

```console
brew install dnsmasq
```

1. Set up the `*.test` domain lookup:

```console
# Ensure the configuration directory exists
mkdir -p $(brew --prefix)/etc/

# Add `*.test` to the `127.0.0.1` lookup
echo 'address=/.test/127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf

# Start `dnsmasq`
sudo brew services start dnsmasq
```

1. Create a DNS resolver:

```console
# Ensure the resolver directory exists
sudo mkdir -p /etc/resolver

# Add the localhost address as a resolver for `.test` domains
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/test
```

You can now create a GitLab Pages site locally with a dynamic domain.
If you [configure GitLab Pages](_index.md#configuring-gitlab-pages-with-gdk) and
create a `root/html` project, that project is accessible through `http://root.gdk.pages.test:3010/html`.

## Troubleshooting

For GitLab Runner, you must define `gdk.test` in `/etc/hosts`.
If you're using GitLab Runner locally, you must also configure `/etc/hosts`:

```console
# Append GDK configuration in `/etc/hosts`
cat <<-EOF | sudo tee -a /etc/hosts

## GDK
127.0.0.1  gdk.test
::1        gdk.test
# ----------------------------
EOF
```
