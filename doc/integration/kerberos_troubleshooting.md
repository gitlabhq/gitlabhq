---
stage: Software Supply Chain Security
group: Authentication
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Troubleshooting GitLab with Kerberos integration
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

When working with GitLab with Kerberos integration, you might encounter the following issues.

## Using Google Chrome with Kerberos authentication against Windows AD

When you use Google Chrome to sign in to GitLab with Kerberos, you must enter your full username. For example, `username@domain.com`.

If you do not enter your full username, the sign-in fails. Check the logs to see the following event message as evidence of this sign-in failure:

```plain
"message":"OmniauthKerberosController: failed to process Negotiate/Kerberos authentication: gss_accept_sec_context did not return GSS_S_COMPLETE: An unsupported mechanism was requested\nUnknown error".
```

## Test connectivity between the GitLab and Kerberos servers

You can use utilities like [`kinit`](https://web.mit.edu/kerberos/krb5-1.12/doc/user/user_commands/kinit.html) and [`klist`](https://web.mit.edu/kerberos/krb5-1.12/doc/user/user_commands/klist.html) to test connectivity between the GitLab server
and the Kerberos server. How you install these depends on your specific OS.

Use `klist` to see the service principal names (SPN) available in your `keytab` file and the encryption type for each SPN:

```shell
klist -ke /etc/http.keytab
```

On an Ubuntu server, the output would look similar to the following:

```shell
Keytab name: FILE:/etc/http.keytab
KVNO Principal
---- --------------------------------------------------------------------------
   3 HTTP/my.gitlab.domain@MY.REALM (des-cbc-crc)
   3 HTTP/my.gitlab.domain@MY.REALM (des-cbc-md5)
   3 HTTP/my.gitlab.domain@MY.REALM (arcfour-hmac)
   3 HTTP/my.gitlab.domain@MY.REALM (aes256-cts-hmac-sha1-96)
   3 HTTP/my.gitlab.domain@MY.REALM (aes128-cts-hmac-sha1-96)
```

Use `kinit` in verbose mode to test whether GitLab can use the keytab file to connect to the Kerberos server:

```shell
KRB5_TRACE=/dev/stdout kinit -kt /etc/http.keytab HTTP/my.gitlab.domain@MY.REALM
```

This command shows a detailed output of the authentication process.

## Unsupported GSSAPI mechanism

With Kerberos SPNEGO authentication, the browser is expected to send a list of
mechanisms it supports to GitLab. If it doesn't support any of the mechanisms
GitLab supports, authentication fails with a message like this in the log:

```plaintext
OmniauthKerberosController: failed to process Negotiate/Kerberos authentication: gss_accept_sec_context did not return GSS_S_COMPLETE: An unsupported mechanism was requested Unknown error
```

There are a number of potential causes and solutions for this error message.

### Kerberos integration not using a dedicated port

GitLab CI/CD doesn't work with a Kerberos-enabled GitLab instance unless the Kerberos integration
is configured to [use a dedicated port](kerberos.md#http-git-access-with-kerberos-token-passwordless-authentication).

### Lack of connectivity between client machine and Kerberos server

This is usually seen when the browser is unable to contact the Kerberos server
directly. It falls back to an unsupported mechanism known as
[`IAKERB`](https://k5wiki.kerberos.org/wiki/Projects/IAKERB), which tries to use
the GitLab server as an intermediary to the Kerberos server.

If you're experiencing this error, ensure there is connectivity between the
client machine and the Kerberos server - this is a prerequisite! Traffic may be
blocked by a firewall, or the DNS records may be incorrect.

### `GitLab DNS record is a CNAME record` error

Kerberos fails with this error when GitLab is referenced with a `CNAME` record.
To resolve this issue, ensure the DNS record for GitLab is an `A` record.

### Mismatched forward and reverse DNS records for GitLab instance hostname

Another failure mode occurs when the forward and reverse DNS records for the
GitLab server do not match. Often, Windows clients work in this case while
Linux clients fail. They use reverse DNS while detecting the Kerberos
realm. If they get the wrong realm then ordinary Kerberos mechanisms fail,
so the client falls back to attempting to negotiate `IAKERB`, leading to the
above error message.

To fix this, ensure that the forward and reverse DNS for your GitLab server
match. So for instance, if you access GitLab as `gitlab.example.com`, resolving
to IP address `10.0.2.2`, then `2.2.0.10.in-addr.arpa` must be a `PTR` record for
`gitlab.example.com`.

### Missing Kerberos libraries on browser or client machine

Finally, it's possible that the browser or client machine lack Kerberos support
completely. Ensure that the Kerberos libraries are installed and that you can
authenticate to other Kerberos services.

## HTTP Basic: Access denied when cloning

```shell
remote: HTTP Basic: Access denied
fatal: Authentication failed for '<KRB5 path>'
```

If you are using Git v2.11 or newer and see the above error when cloning, you can
set the `http.emptyAuth` Git option to `true` to fix this:

```shell
git config --global http.emptyAuth true
```

## Git cloning with Kerberos over proxied HTTPS

You must comment the following if:

- You see `http://` URLs in the **Clone with KRB5 Git Cloning** options, when `https://` URLs are expected.
- HTTPS is not terminated at your GitLab instance, but is instead proxied by your load balancer or local traffic manager.

```shell
# gitlab_rails['kerberos_https'] = false
```

See also: [Git v2.11 release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.11.0.txt#L482-L486)

## Helpful links

- <https://help.ubuntu.com/community/Kerberos>
- <https://blog.manula.org/2012/04/setting-up-kerberos-server-with-debian.html>
- <https://www.roguelynn.com/words/explain-like-im-5-kerberos/>
