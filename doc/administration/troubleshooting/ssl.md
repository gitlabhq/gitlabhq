---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Troubleshooting SSL **(FREE SELF)**

This page contains a list of common SSL-related errors and scenarios that you
may encounter while working with GitLab. It should serve as an addition to the
main SSL docs available here:

- [Omnibus SSL Configuration](https://docs.gitlab.com/omnibus/settings/ssl.html).
- [Self-signed certificates or custom Certification Authorities for GitLab Runner](https://docs.gitlab.com/runner/configuration/tls-self-signed.html).
- [Manually configuring HTTPS](https://docs.gitlab.com/omnibus/settings/nginx.html#manually-configuring-https).

## Using an internal CA certificate with GitLab

After configuring a GitLab instance with an internal CA certificate, you might
not be able to access it by using various CLI tools. You may see experience the
following issues:

- `curl` fails:

  ```shell
  curl "https://gitlab.domain.tld"
  curl: (60) SSL certificate problem: unable to get local issuer certificate
  More details here: https://curl.haxx.se/docs/sslcerts.html
  ```

- Testing by using the [rails console](../operations/rails_console.md#starting-a-rails-console-session)
  also fails:

  ```ruby
  uri = URI.parse("https://gitlab.domain.tld")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = 1
  response = http.request(Net::HTTP::Get.new(uri.request_uri))
  ...
  Traceback (most recent call last):
        1: from (irb):5
  OpenSSL::SSL::SSLError (SSL_connect returned=1 errno=0 state=error: certificate verify failed (unable to get local issuer certificate))
  ```

- The error `SSL certificate problem: unable to get local issuer certificate`
  is displayed when setting up a [mirror](../../user/project/repository/repository_mirroring.md#repository-mirroring)
  from this GitLab instance.
- `openssl` works when specifying the path to the certificate:

  ```shell
  /opt/gitlab/embedded/bin/openssl s_client -CAfile /root/my-cert.crt -connect gitlab.domain.tld:443
  ```

If you have the previously described issues, add your certificate to
`/etc/gitlab/trusted-certs`, and then run `sudo gitlab-ctl reconfigure`.

## X.509 key values mismatch error

After configuring your instance with a certificate bundle, NGINX may display
the following error message:

`SSL: error:0B080074:x509 certificate routines:X509_check_private_key:key values mismatch`

This error message means that the server certificate and key you have provided
don't match. You can confirm this by running the following command and then
comparing the output:

```shell
openssl rsa -noout -modulus -in path/to/your/.key | openssl md5
openssl x509 -noout -modulus -in path/to/your/.crt | openssl md5
```

The following is an example of an md5 output between a matching key and
certificate. Note the matching md5 hashes:

```shell
$ openssl rsa -noout -modulus -in private.key | openssl md5
4f49b61b25225abeb7542b29ae20e98c
$ openssl x509 -noout -modulus -in public.crt | openssl md5
4f49b61b25225abeb7542b29ae20e98c
```

This is an opposing output with a non-matching key and certificate which shows
different md5 hashes:

```shell
$ openssl rsa -noout -modulus -in private.key | openssl md5
d418865077299af27707b1d1fa83cd99
$ openssl x509 -noout -modulus -in public.crt | openssl md5
4f49b61b25225abeb7542b29ae20e98c
```

If the two outputs differ like the previous example, there's a mismatch between
the certificate and key. Contact the provider of the SSL certificate for
further support.

## Using GitLab Runner with a GitLab instance configured with internal CA certificate or self-signed certificate

Besides getting the errors mentioned in
[Using an internal CA certificate with GitLab](ssl.md#using-an-internal-ca-certificate-with-gitlab),
your CI pipelines may get stuck in `Pending` status. In the runner logs you may
see the following error message:

```shell
Dec  6 02:43:17 runner-host01 gitlab-runner[15131]: #033[0;33mWARNING: Checking for jobs... failed
#033[0;m  #033[0;33mrunner#033[0;m=Bfkz1fyb #033[0;33mstatus#033[0;m=couldn't execute POST against
https://gitlab.domain.tld/api/v4/jobs/request: Post https://gitlab.domain.tld/api/v4/jobs/request:
x509: certificate signed by unknown authority
```

If you encounter a similar problem, add your certificate to `/etc/gitlab-runner/certs`,
and the restart the runner by running `gitlab-runner restart`.

## Mirroring a remote GitLab repository that uses a self-signed SSL certificate

When configuring a local GitLab instance to [mirror a repository](../../user/project/repository/repository_mirroring.md)
from a remote GitLab instance that uses a self-signed certificate, you may see
the `SSL certificate problem: self signed certificate` error message in the
user interface.

The cause of the issue can be confirmed by checking if:

- `curl` fails:

  ```shell
  $ curl "https://gitlab.domain.tld"
  curl: (60) SSL certificate problem: self signed certificate
  More details here: https://curl.haxx.se/docs/sslcerts.html
  ```

- Testing by using the Rails console also fails:

  ```ruby
  uri = URI.parse("https://gitlab.domain.tld")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = 1
  response = http.request(Net::HTTP::Get.new(uri.request_uri))
  ...
  Traceback (most recent call last):
        1: from (irb):5
  OpenSSL::SSL::SSLError (SSL_connect returned=1 errno=0 state=error: certificate verify failed (unable to get local issuer certificate))
  ```

To fix this problem:

- Add the self-signed certificate from the remote GitLab instance to the
  `/etc/gitlab/trusted-certs` directory on the local GitLab instance, and then
  run `sudo gitlab-ctl reconfigure` as per the instructions for
  [installing custom public certificates](https://docs.gitlab.com/omnibus/settings/ssl.html#install-custom-public-certificates).
- If your local GitLab instance was installed using the Helm Charts, you can
  [add your self-signed certificate to your GitLab instance](https://docs.gitlab.com/runner/install/kubernetes.html#providing-a-custom-certificate-for-accessing-gitlab).

You may also get another error message when trying to mirror a repository from
a remote GitLab instance that uses a self-signed certificate:

```shell
2:Fetching remote upstream failed: fatal: unable to access &amp;#39;https://gitlab.domain.tld/root/test-repo/&amp;#39;:
SSL: unable to obtain common name from peer certificate
```

In this case, the problem can be related to the certificate itself:

1. Validate that your self-signed certificate isn't missing a common name. If it
   is, regenerate a valid certificate
1. Add the certificate to `/etc/gitlab/trusted-certs`.
1. Run `sudo gitlab-ctl reconfigure`.

## Unable to perform Git operations due to an internal or self-signed certificate

If your GitLab instance is using a self-signed certificate, or if the
certificate is signed by an internal certificate authority (CA), you might
experience the following errors when attempting to perform Git operations:

```shell
$ git clone https://gitlab.domain.tld/group/project.git
Cloning into 'project'...
fatal: unable to access 'https://gitlab.domain.tld/group/project.git/': SSL certificate problem: self signed certificate
```

```shell
$ git clone https://gitlab.domain.tld/group/project.git
Cloning into 'project'...
fatal: unable to access 'https://gitlab.domain.tld/group/project.git/': server certificate verification failed. CAfile: /etc/ssl/certs/ca-certificates.crt CRLfile: none
```

To fix this problem:

- If possible, use SSH remotes for all Git operations. This is considered more
  secure and convenient to use.
- If you must use HTTPS remotes, you can try the following:
  - Copy the self-signed certificate or the internal root CA certificate to a
    local directory (for example, `~/.ssl`) and configure Git to trust your
    certificate:

    ```shell
    git config --global http.sslCAInfo ~/.ssl/gitlab.domain.tld.crt
    ```

  - Disable SSL verification in your Git client. Note that this intended as a
    temporary measure, as it could be considered a security risk.

    ```shell
    git config --global http.sslVerify false
    ```

## SSL_connect wrong version number

A misconfiguration may result in:

- `gitlab-rails/exceptions_json.log` entries containing:

  ```plaintext
  "exception.class":"Excon::Error::Socket","exception.message":"SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)",
  "exception.class":"Excon::Error::Socket","exception.message":"SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)",
  ```

- `gitlab-workhorse/current` containing:

  ```plaintext
  http: server gave HTTP response to HTTPS client
  http: server gave HTTP response to HTTPS client
  ```

- `gitlab-rails/sidekiq.log` or `sidekiq/current` containing:

  ```plaintext
  message: SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)
  message: SSL_connect returned=1 errno=0 state=error: wrong version number (OpenSSL::SSL::SSLError)
  ```

Some of these errors come from the Excon Ruby gem, and could be generated in
circumstances where GitLab is configured to initiate an HTTPS session to a
remote server that is serving only HTTP.

One scenario is that you're using [object storage](../object_storage.md), which
isn't served under HTTPS. GitLab is misconfigured and attempts a TLS handshake,
but the object storage will respond with plain HTTP.

## `schannel: SEC_E_UNTRUSTED_ROOT`

If you're on Windows and get the following error:

```plaintext
Fatal: unable to access 'https://gitlab.domain.tld/group/project.git': schannel: SEC_E_UNTRUSTED_ROOT (0x80090325) - The certificate chain was issued by an authority that is not trusted."
```

You may need to specify that Git should use OpenSSL:

```shell
git config --system http.sslbackend openssl
```
