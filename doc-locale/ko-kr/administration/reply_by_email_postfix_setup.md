---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 들어오는 이메일용 Postfix 설정
description: 들어오는 이메일을 위해 Postfix를 구성합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

이 문서에서는 Ubuntu에서 IMAP 인증을 사용하는 기본 Postfix 메일 서버를 설정하는 단계를 안내하며, [들어오는 이메일](incoming_email.md)에 사용됩니다.

이 지침에서는 `incoming@gitlab.example.com` 이메일 주소를 사용 중이며, 호스트 `gitlab.example.com`에서 사용자명은 `incoming`이라고 가정합니다. 예제 코드 스니펫을 실행할 때 실제 호스트로 변경하는 것을 잊지 마세요.

## 서버 방화벽 구성 {#configure-your-server-firewall}

1. 서버의 포트 25를 열어서 SMTP를 통해 사용자들이 서버로 이메일을 보낼 수 있도록 합니다.
1. 메일 서버가 GitLab을 실행하는 서버와 다른 경우, 서버의 포트 143을 열어서 GitLab이 IMAP을 통해 서버에서 이메일을 읽을 수 있도록 합니다.

## 패키지 설치 {#install-packages}

1. `postfix` 패키지가 아직 설치되지 않은 경우 설치합니다:

   ```shell
   sudo apt-get install postfix
   ```

   환경에 대해 물어보면 'Internet Site'를 선택합니다. 호스트명을 확인하도록 요청하면 `gitlab.example.com`와 일치하는지 확인합니다.

1. `mailutils` 패키지를 설치합니다.

   ```shell
   sudo apt-get install mailutils
   ```

## 사용자 생성 {#create-user}

1. 들어오는 이메일용 사용자를 생성합니다.

   ```shell
   sudo useradd -m -s /bin/bash incoming
   ```

1. 이 사용자의 비밀번호를 설정합니다.

   ```shell
   sudo passwd incoming
   ```

   이것을 잊지 마세요. 나중에 필요합니다.

## 기본 설정 테스트 {#test-the-out-of-the-box-setup}

1. 로컬 SMTP 서버에 연결합니다:

   ```shell
   telnet localhost 25
   ```

   다음과 같은 프롬프트가 표시되어야 합니다:

   ```shell
   Trying 127.0.0.1...
   Connected to localhost.
   Escape character is '^]'.
   220 gitlab.example.com ESMTP Postfix (Ubuntu)
   ```

   `Connection refused` 오류가 표시되면 `postfix`가 실행 중인지 확인합니다:

   ```shell
   sudo postfix status
   ```

   실행 중이 아니면 시작합니다:

   ```shell
   sudo postfix start
   ```

1. 새 `incoming` 사용자에게 이메일을 보내 SMTP를 테스트하려면 SMTP 프롬프트에 다음을 입력합니다:

   ```plaintext
   ehlo localhost
   mail from: root@localhost
   rcpt to: incoming@localhost
   data
   Subject: Re: Some issue

   Sounds good!
   .
   quit
   ```

   > [!note]
   > `.`는 자신의 줄에 있는 리터럴 마침표입니다.

   `rcpt to: incoming@localhost`을 입력한 후 오류가 발생하면 Postfix `my_network` 구성이 올바르지 않습니다. 오류는 'Temporary lookup failure'를 표시합니다. [인터넷에서 이메일을 받도록 Postfix 구성](#configure-postfix-to-receive-email-from-the-internet)을 참조하세요.

1. `incoming` 사용자가 이메일을 받았는지 확인합니다:

   ```shell
   su - incoming
   mail
   ```

   다음과 같은 출력이 표시되어야 합니다:

   ```plaintext
   "/var/mail/incoming": 1 message 1 unread
   >U   1 root@localhost                           59/2842  Re: Some issue
   ```

   메일 앱을 종료합니다:

   ```shell
   q
   ```

1. `incoming` 계정에서 로그아웃하고 `root` 상태로 돌아갑니다:

   ```shell
   logout
   ```

## Maildir 스타일 사서함을 사용하도록 Postfix 구성 {#configure-postfix-to-use-maildir-style-mailboxes}

나중에 IMAP 인증을 추가하기 위해 설치하는 Courier는 mbox가 아닌 Maildir 형식의 사서함이 필요합니다.

1. Postfix를 Maildir 스타일 사서함을 사용하도록 구성합니다:

   ```shell
   sudo postconf -e "home_mailbox = Maildir/"
   ```

1. Postfix를 다시 시작합니다:

   ```shell
   sudo /etc/init.d/postfix restart
   ```

1. 새 설정을 테스트합니다:

   1. [기본 설정 테스트](#test-the-out-of-the-box-setup)의 1단계와 2단계를 따릅니다.
   1. `incoming` 사용자가 이메일을 받았는지 확인합니다:

      ```shell
      su - incoming
      MAIL=/home/incoming/Maildir
      mail
      ```

      다음과 같은 출력이 표시되어야 합니다:

      ```plaintext
      "/home/incoming/Maildir": 1 message 1 unread
      >U   1 root@localhost                           59/2842  Re: Some issue
      ```

      메일 앱을 종료합니다:

      ```shell
      q
      ```

   `mail`이 `Maildir: Is a directory` 오류를 반환하면 `mail`의 버전이 Maildir 스타일 사서함을 지원하지 않습니다. `heirloom-mailx`을 `sudo apt-get install heirloom-mailx`을 실행하여 설치합니다. 그런 다음 이전 단계를 다시 시도하여 `heirloom-mailx`을 `mail` 명령으로 대체합니다.

1. `incoming` 계정에서 로그아웃하고 `root` 상태로 돌아갑니다:

   ```shell
   logout
   ```

## Courier IMAP 서버 설치 {#install-the-courier-imap-server}

1. `courier-imap` 패키지를 설치합니다:

   ```shell
   sudo apt-get install courier-imap
   ```

   Ubuntu 24.04에는 `courier-imap` 패키지가 없습니다. 자세한 내용은 [Ubuntu 버그 2071662](https://bugs.launchpad.net/ubuntu/+source/courier/+bug/2071662)를 참조하세요.

   `courier-imap`을 설치한 후 `imapd`을 시작합니다:

   ```shell
   imapd start
   ```

1. `courier-authdaemon`은 설치 후 시작되지 않습니다. 이것이 없으면 IMAP 인증이 실패합니다:

   ```shell
   sudo service courier-authdaemon start
   ```

   `courier-authdaemon`을 부팅 시 시작하도록 구성할 수도 있습니다:

   ```shell
   sudo systemctl enable courier-authdaemon
   ```

## 인터넷에서 이메일을 받도록 Postfix 구성 {#configure-postfix-to-receive-email-from-the-internet}

1. Postfix에 로컬로 간주해야 할 도메인을 알립니다:

   ```shell
   sudo postconf -e "mydestination = gitlab.example.com, localhost.localdomain, localhost"
   ```

1. Postfix에 LAN의 일부로 간주해야 할 IP를 알립니다:

   `192.168.1.0/24`이 로컬 LAN이라고 가정합시다. 같은 로컬 네트워크에 다른 시스템이 없으면 이 단계를 건너뛸 수 있습니다.

   ```shell
   sudo postconf -e "mynetworks = 127.0.0.0/8, 192.168.1.0/24"
   ```

1. Postfix를 인터넷을 포함한 모든 인터페이스에서 메일을 받도록 구성합니다:

   ```shell
   sudo postconf -e "inet_interfaces = all"
   ```

1. Postfix를 `+` 구분 기호를 사용하여 하위 주소 지정을 위해 구성합니다:

   ```shell
   sudo postconf -e "recipient_delimiter = +"
   ```

1. Postfix를 다시 시작합니다:

   ```shell
   sudo service postfix restart
   ```

## 최종 설정 테스트 {#test-the-final-setup}

1. 새 설정에서 SMTP를 테스트합니다:

   1. SMTP 서버에 연결합니다:

      ```shell
      telnet gitlab.example.com 25
      ```

      다음과 같은 프롬프트가 표시되어야 합니다:

      ```shell
      Trying 123.123.123.123...
      Connected to gitlab.example.com.
      Escape character is '^]'.
      220 gitlab.example.com ESMTP Postfix (Ubuntu)
      ```

      `Connection refused` 오류가 표시되면 포트 25에 인바운드 트래픽을 허용하도록 방화벽이 설정되어 있는지 확인합니다.

   1. `incoming` 사용자에게 이메일을 보내 SMTP를 테스트하려면 SMTP 프롬프트에 다음을 입력합니다:

      ```plaintext
      ehlo gitlab.example.com
      mail from: root@gitlab.example.com
      rcpt to: incoming@gitlab.example.com
      data
      Subject: Re: Some issue

      Sounds good!
      .
      quit
      ```

      > [!note]
      > `.`는 자신의 줄에 있는 리터럴 마침표입니다.

   1. `incoming` 사용자가 이메일을 받았는지 확인합니다:

      ```shell
      su - incoming
      MAIL=/home/incoming/Maildir
      mail
      ```

      다음과 같은 출력이 표시되어야 합니다:

      ```plaintext
      "/home/incoming/Maildir": 1 message 1 unread
      >U   1 root@gitlab.example.com                           59/2842  Re: Some issue
      ```

      메일 앱을 종료합니다:

      ```shell
      q
      ```

   1. `incoming` 계정에서 로그아웃하고 `root` 상태로 돌아갑니다:

      ```shell
      logout
      ```

1. 새 설정에서 IMAP을 테스트합니다:

   1. IMAP 서버에 연결합니다:

      ```shell
      telnet gitlab.example.com 143
      ```

      다음과 같은 프롬프트가 표시되어야 합니다:

      ```shell
      Trying 123.123.123.123...
      Connected to mail.gitlab.example.com.
      Escape character is '^]'.
      - OK [CAPABILITY IMAP4rev1 UIDPLUS CHILDREN NAMESPACE THREAD=ORDEREDSUBJECT THREAD=REFERENCES SORT QUOTA IDLE ACL ACL2=UNION] Courier-IMAP ready. Copyright 1998-2011 Double Precision, Inc.  See COPYING for distribution information.
      ```

   1. `incoming` 사용자로 로그인하여 IMAP을 테스트하려면 IMAP 프롬프트에 다음을 입력합니다:

      ```plaintext
      a login incoming PASSWORD
      ```

      PASSWORD를 앞서 `incoming` 사용자에게 설정한 비밀번호로 바꿉니다.

      다음과 같은 출력이 표시되어야 합니다:

      ```plaintext
      a OK LOGIN Ok.
      ```

   1. IMAP 서버에서 연결을 끊습니다:

      ```shell
      a logout
      ```

## 완료 {#done}

모든 테스트가 성공하면 Postfix가 모두 설정되어 이메일을 받을 준비가 되었습니다! GitLab을 구성하려면 [들어오는 이메일](incoming_email.md) 가이드를 계속 진행하세요.

---

_이 문서는 <https://help.ubuntu.com/community/PostfixBasicSetupHowto>에서 각색되었으며 Ubuntu 문서 위키 기여자들이 작성했습니다._
