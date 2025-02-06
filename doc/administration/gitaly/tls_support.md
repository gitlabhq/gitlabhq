---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitaly TLS support
---

Gitaly supports TLS encryption. To communicate with a Gitaly instance that listens for secure
connections, use the `tls://` URL scheme in the `gitaly_address` of the corresponding
storage entry in the GitLab configuration.

Gitaly provides the same server certificates as client certificates in TLS
connections to GitLab. This can be used as part of a mutual TLS authentication strategy
when combined with reverse proxies (for example, NGINX) that validate client certificate
to grant access to GitLab.

You must supply your own certificates as this isn't provided automatically. The certificate
corresponding to each Gitaly server must be installed on that Gitaly server.

Additionally, the certificate (or its certificate authority) must be installed on all:

- Gitaly servers.
- Gitaly clients that communicate with it.

If you use a load balancer, it must be able to negotiate HTTP/2 using the ALPN TLS extension.

## Certificate requirements

- The certificate must specify the address you use to access the Gitaly server. You must add the hostname or IP address as a Subject Alternative Name to the certificate.
- You can configure Gitaly servers with both an unencrypted listening address `listen_addr` and an
  encrypted listening address `tls_listen_addr` at the same time. This allows you to gradually
  transition from unencrypted to encrypted traffic if necessary.
- The certificate's Common Name field is ignored.

## Configure Gitaly with TLS

[Configure Gitaly](configure_gitaly.md) before configuring TLS support.

The process for configuring TLS support depends on your installation type.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Create certificates for Gitaly servers.
1. On the Gitaly clients, copy the certificates (or their certificate authority) into
   `/etc/gitlab/trusted-certs`:

   ```shell
   sudo cp cert.pem /etc/gitlab/trusted-certs/
   ```

1. On the Gitaly clients, edit `gitlab_rails['repositories_storages']` in `/etc/gitlab/gitlab.rb` as follows:

   ```ruby
   gitlab_rails['repositories_storages'] = {
     'default' => { 'gitaly_address' => 'tls://gitaly1.internal:9999' },
     'storage1' => { 'gitaly_address' => 'tls://gitaly1.internal:9999' },
     'storage2' => { 'gitaly_address' => 'tls://gitaly2.internal:9999' },
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. On the Gitaly servers, create the `/etc/gitlab/ssl` directory and copy your key and certificate
   there:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 /etc/gitlab/ssl/cert.pem
   sudo chmod 600 /etc/gitlab/ssl/key.pem
   # For Linux package installations, 'git' is the default username. Modify the following command if it was changed from the default
   sudo chown -R git /etc/gitlab/ssl
   ```

1. Copy all Gitaly server certificates (or their certificate authority) to
   `/etc/gitlab/trusted-certs` on all Gitaly servers and clients
   so that Gitaly servers and clients trust the certificate when calling into themselves
   or other Gitaly servers:

   ```shell
   sudo cp cert1.pem cert2.pem /etc/gitlab/trusted-certs/
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add:

   <!-- Updates to following example must also be made at https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab -->

   ```ruby
   gitaly['configuration'] = {
      # ...
      tls_listen_addr: '0.0.0.0:9999',
      tls: {
        certificate_path: '/etc/gitlab/ssl/cert.pem',
        key_path: '/etc/gitlab/ssl/key.pem',
      },
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. Run `sudo gitlab-rake gitlab:gitaly:check` on the Gitaly client (for example, the
   Rails application) to confirm it can connect to Gitaly servers.
1. Verify Gitaly traffic is being served over TLS by
   [observing the types of Gitaly connections](#observe-type-of-gitaly-connections).
1. Optional. Improve security by:
   1. Disabling non-TLS connections by commenting out or deleting `gitaly['configuration'][:listen_addr]` in
      `/etc/gitlab/gitlab.rb`.
   1. Saving the file.
   1. [Reconfiguring GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

:::TabTitle Self-compiled (source)

1. Create certificates for Gitaly servers.
1. On the Gitaly clients, copy the certificates into the system trusted certificates:

   ```shell
   sudo cp cert.pem /usr/local/share/ca-certificates/gitaly.crt
   sudo update-ca-certificates
   ```

1. On the Gitaly clients, edit `storages` in `/home/git/gitlab/config/gitlab.yml` as follows:

   ```yaml
   gitlab:
     repositories:
       storages:
         default:
           gitaly_address: tls://gitaly1.internal:9999
           path: /some/local/path
         storage1:
           gitaly_address: tls://gitaly1.internal:9999
           path: /some/local/path
         storage2:
           gitaly_address: tls://gitaly2.internal:9999
           path: /some/local/path
   ```

   NOTE:
   `/some/local/path` should be set to a local folder that exists, however no data is stored
   in this folder. This requirement is scheduled to be removed when
   [Gitaly issue #1282](https://gitlab.com/gitlab-org/gitaly/-/issues/1282) is resolved.

1. Save the file and [restart GitLab](../restart_gitlab.md#self-compiled-installations).
1. On the Gitaly servers, create or edit `/etc/default/gitlab` and add:

   ```shell
   export SSL_CERT_DIR=/etc/gitlab/ssl
   ```

1. On the Gitaly servers, create the `/etc/gitlab/ssl` directory and copy your key and certificate there:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 /etc/gitlab/ssl/cert.pem
   sudo chmod 600 /etc/gitlab/ssl/key.pem
   # Set ownership to the same user that runs Gitaly
   sudo chown -R git /etc/gitlab/ssl
   ```

1. Copy all Gitaly server certificates (or their certificate authority) to the system trusted
   certificates folder so Gitaly server trusts the certificate when calling into itself or other Gitaly
   servers.

   ```shell
   sudo cp cert.pem /usr/local/share/ca-certificates/gitaly.crt
   sudo update-ca-certificates
   ```

1. Edit `/home/git/gitaly/config.toml` and add:

   ```toml
   tls_listen_addr = '0.0.0.0:9999'

   [tls]
   certificate_path = '/etc/gitlab/ssl/cert.pem'
   key_path = '/etc/gitlab/ssl/key.pem'
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#self-compiled-installations).
1. Verify Gitaly traffic is being served over TLS by
   [observing the types of Gitaly connections](#observe-type-of-gitaly-connections).
1. Optional. Improve security by:
   1. Disabling non-TLS connections by commenting out or deleting `listen_addr` in
      `/home/git/gitaly/config.toml`.
   1. Saving the file.
   1. [Restarting GitLab](../restart_gitlab.md#self-compiled-installations).

::EndTabs

### Update the certificates

To update the Gitaly certificates after initial configuration:

::Tabs

:::TabTitle Linux package (Omnibus)

If the content of your SSL certificates under the `/etc/gitlab/ssl` directory have been updated, but no configuration changes have been made to
`/etc/gitlab/gitlab.rb`, then reconfiguring GitLab doesn’t affect Gitaly. Instead, you must restart Gitaly manually for the certificates to be loaded
by the Gitaly process:

```shell
sudo gitlab-ctl restart gitaly
```

If you change or update the certificates in `/etc/gitlab/trusted-certs` without making changes to the `/etc/gitlab/gitlab.rb` file, you must:

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) so the symlinks for the trusted certificates are updated.
1. Restart Gitaly manually for the certificates to be loaded by the Gitaly process:

   ```shell
   sudo gitlab-ctl restart gitaly
   ```

:::TabTitle Self-compiled (source)

If the content of your SSL certificates under the `/etc/gitlab/ssl` directory have been updated, you must
[restart GitLab](../restart_gitlab.md#self-compiled-installations) for the certificates to be loaded by the Gitaly process.

If you change or update the certificates in `/usr/local/share/ca-certificates`, you must:

1. Run `sudo update-ca-certificates` to update the system's trusted store.
1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations) for the certificates to be loaded by the Gitaly process.

::EndTabs

## Observe type of Gitaly connections

For information on observing the type of Gitaly connections being served, see the
[relevant documentation](monitoring.md#queries).
