---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kerberos 통합으로 GitLab 문제 해결
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

Kerberos 통합으로 GitLab을 사용할 때 다음과 같은 이슈가 발생할 수 있습니다.

## Google Chrome에서 Windows AD에 대한 Kerberos 인증 사용 {#using-google-chrome-with-kerberos-authentication-against-windows-ad}

Google Chrome을 사용하여 Kerberos로 GitLab에 로그인할 때는 전체 사용자 이름을 입력해야 합니다. 예를 들어, `username@domain.com`입니다.

전체 사용자 이름을 입력하지 않으면 로그인에 실패합니다. 로그를 확인하여 로그인 실패의 증거로 다음 이벤트 메시지를 확인합니다:

```plain
"message":"OmniauthKerberosController: failed to process Negotiate/Kerberos authentication: gss_accept_sec_context did not return GSS_S_COMPLETE: An unsupported mechanism was requested\nUnknown error".
```

## GitLab과 Kerberos 서버 간 연결 테스트 {#test-connectivity-between-the-gitlab-and-kerberos-servers}

[`kinit`](https://web.mit.edu/kerberos/krb5-1.12/doc/user/user_commands/kinit.html) 및 [`klist`](https://web.mit.edu/kerberos/krb5-1.12/doc/user/user_commands/klist.html)와 같은 유틸리티를 사용하여 GitLab 서버와 Kerberos 서버 간의 연결을 테스트할 수 있습니다. 이를 설치하는 방법은 특정 OS에 따라 다릅니다.

`klist`을(를) 사용하여 `keytab` 파일에서 사용 가능한 서비스 사용자 이름(SPN)과 각 SPN의 암호화 유형을 확인합니다:

```shell
klist -ke /etc/http.keytab
```

Ubuntu 서버에서 출력은 다음과 비슷합니다:

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

`kinit`을(를) 자세한 정보 모드에서 사용하여 GitLab에서 keytab 파일을 사용하여 Kerberos 서버에 연결할 수 있는지 테스트합니다:

```shell
KRB5_TRACE=/dev/stdout kinit -kt /etc/http.keytab HTTP/my.gitlab.domain@MY.REALM
```

이 명령은 인증 프로세스의 상세한 출력을 표시합니다.

## 지원되지 않는 GSSAPI 메커니즘 {#unsupported-gssapi-mechanism}

Kerberos SPNEGO 인증을 사용하면 브라우저는 지원하는 메커니즘 목록을 GitLab으로 보내야 합니다. GitLab에서 지원하는 메커니즘을 지원하지 않으면 인증이 실패하고 로그에 다음과 같은 메시지가 나타납니다:

```plaintext
OmniauthKerberosController: failed to process Negotiate/Kerberos authentication: gss_accept_sec_context did not return GSS_S_COMPLETE: An unsupported mechanism was requested Unknown error
```

이 오류 메시지에는 여러 가지 잠재적 원인과 해결책이 있습니다.

### Kerberos 통합이 전용 포트를 사용하지 않음 {#kerberos-integration-not-using-a-dedicated-port}

Kerberos 통합이 [전용 포트 사용](kerberos.md#http-git-access-with-kerberos-token-passwordless-authentication)으로 구성되지 않으면 GitLab CI/CD가 Kerberos 활성화 GitLab 인스턴스에서 작동하지 않습니다.

### 클라이언트 머신과 Kerberos 서버 간 연결 부족 {#lack-of-connectivity-between-client-machine-and-kerberos-server}

이는 일반적으로 브라우저가 Kerberos 서버에 직접 연결할 수 없을 때 나타납니다. [`IAKERB`](https://k5wiki.kerberos.org/wiki/Projects/IAKERB)로 알려진 지원되지 않는 메커니즘으로 대체되며, 이는 GitLab 서버를 Kerberos 서버의 중개자로 사용하려고 합니다.

이 오류가 발생하면 클라이언트 머신과 Kerberos 서버 간의 연결이 있는지 확인합니다. 이는 필수 조건입니다! 트래픽이 방화벽에 의해 차단되거나 DNS 레코드가 잘못되었을 수 있습니다.

### `GitLab DNS record is a CNAME record` 오류 {#gitlab-dns-record-is-a-cname-record-error}

GitLab이 `CNAME` 레코드로 참조될 때 Kerberos가 이 오류로 실패합니다. 이 이슈를 해결하려면 GitLab의 DNS 레코드가 `A` 레코드인지 확인합니다.

### GitLab 인스턴스 호스트 이름에 대한 정방향 및 역방향 DNS 레코드 불일치 {#mismatched-forward-and-reverse-dns-records-for-gitlab-instance-hostname}

또 다른 실패 모드는 GitLab 서버의 정방향 및 역방향 DNS 레코드가 일치하지 않을 때 발생합니다. 대부분의 경우 Windows 클라이언트는 작동하지만 Linux 클라이언트는 실패합니다. Kerberos 영역을 감지하는 동안 역방향 DNS를 사용합니다. 잘못된 영역을 얻으면 일반적인 Kerberos 메커니즘이 실패하므로 클라이언트는 `IAKERB`을(를) 협상하려고 대체되어 이전 인증 오류 메시지가 발생합니다.

이를 해결하려면 GitLab 서버의 정방향 및 역방향 DNS가 일치하는지 확인합니다. 예를 들어 GitLab에 `gitlab.example.com`로 액세스하고 IP 주소 `10.0.2.2`로 확인되면 `2.2.0.10.in-addr.arpa`이(가) `PTR` 레코드여야 하고 `gitlab.example.com`입니다.

### 브라우저 또는 클라이언트 머신에서 Kerberos 라이브러리 누락 {#missing-kerberos-libraries-on-browser-or-client-machine}

마지막으로 브라우저 또는 클라이언트 머신이 Kerberos 지원이 완전히 부족할 수 있습니다. Kerberos 라이브러리가 설치되어 있고 다른 Kerberos 서비스에 인증할 수 있는지 확인합니다.

## HTTP Basic: 복제 시 액세스 거부됨 {#http-basic-access-denied-when-cloning}

```shell
remote: HTTP Basic: Access denied
fatal: Authentication failed for '<KRB5 path>'
```

Git v2.11 이상을 사용하고 복제할 때 이전 오류가 표시되면 `http.emptyAuth` Git 옵션을 `true`로 설정하여 이를 해결할 수 있습니다:

```shell
git config --global http.emptyAuth true
```

## 프록시된 HTTPS를 통한 Git 복제 {#git-cloning-with-kerberos-over-proxied-https}

다음의 경우 주석 처리해야 합니다:

- `http://` URL이 **Clone with KRB5 Git Cloning** 옵션에 표시되는데 `https://` URL이 필요합니다.
- HTTPS가 GitLab 인스턴스에서 종료되지 않지만 대신 로드 밸런서 또는 로컬 트래픽 관리자에 의해 프록시됩니다.

```shell
# gitlab_rails['kerberos_https'] = false
```

참고 항목: [Git v2.11 릴리스 정보](https://github.com/git/git/blob/master/Documentation/RelNotes/2.11.0.adoc?plain=1#L482-L486)

## 유용한 링크 {#helpful-links}

- <https://help.ubuntu.com/community/Kerberos>
- <https://blog.manula.org/2012/04/setting-up-kerberos-server-with-debian.html>
- <https://www.roguelynn.com/words/explain-like-im-5-kerberos/>
