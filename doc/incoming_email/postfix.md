# Set up Postfix for Reply by email

This document will take you through the steps of setting up a basic Postfix mail server with IMAP authentication on Ubuntu, to be used with Reply by email.

The instructions make the assumption that you will be using the email address `incoming@gitlab.example.com`, that is, username `incoming` on host `gitlab.example.com`. Don't forget to change it to your actual host when executing the example code snippets.

## Configure your server firewall

1. Open up port 25 on your server so that people can send email into the server over SMTP.
2. If the mail server is different from the server running GitLab, open up port 143 on your server so that GitLab can read email from the server over IMAP.

## Install packages

1. Install the `postfix` package if it is not installed already:

    ```sh
    sudo apt-get install postfix
    ```

    When asked about the environment, select 'Internet Site'. When asked to confirm the hostname, make sure it matches `gitlab.example.com`.

1. Install the `mailutils` package.

    ```sh
    sudo apt-get install mailutils
    ```

## Create user

1. Create a user for incoming email.

    ```sh
    sudo useradd -m -s /bin/bash incoming
    ```

1. Set a password for this user.

    ```sh
    sudo passwd incoming
    ```

    Be sure not to forget this, you'll need it later.

## Test the out-of-the-box setup

1. Connect to the local SMTP server:
    
    ```sh
    telnet localhost 25
    ```

    You should see a prompt like this:

    ```sh
    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is '^]'.
    220 gitlab.example.com ESMTP Postfix (Ubuntu)
    ```

    If you get a `Connection refused` error instead, verify that `postfix` is running:

    ```sh
    sudo postfix status
    ```

    If it is not, start it:

    ```sh
    sudo postfix start
    ```

1. Send the new `incoming` user a dummy email to test SMTP, by entering the following into the SMTP prompt:
    
    ```
    ehlo localhost
    mail from: root@localhost
    rcpt to: incoming@localhost
    data
    Subject: Re: Some issue

    Sounds good!
    .
    quit
    ```

    _**Note:** The `.` is a literal period on its own line._

    _**Note:** If you receive an error after entering `rcpt to: incoming@localhost`
    then your Postfix `my_network` configuration is not correct. The error will
    say 'Temporary lookup failure'. See
    [Configure Postfix to receive email from the Internet](#configure-postfix-to-receive-email-from-the-internet)._

1. Check if the `incoming` user received the email:
    
    ```sh
    su - incoming
    mail
    ```

    You should see output like this:

    ```
    "/var/mail/incoming": 1 message 1 unread
    >U   1 root@localhost                           59/2842  Re: Some issue
    ```

    Quit the mail app:

    ```sh
    q
    ```

1. Log out of the `incoming` account and go back to being `root`:

    ```sh
    logout
    ```

## Configure Postfix to use Maildir-style mailboxes

Courier, which we will install later to add IMAP authentication, requires mailboxes to have the Maildir format, rather than mbox.

1. Configure Postfix to use Maildir-style mailboxes:
    
    ```sh
    sudo postconf -e "home_mailbox = Maildir/"
    ```

1. Restart Postfix:
    
    ```sh
    sudo /etc/init.d/postfix restart
    ```

1. Test the new setup:
    
    1. Follow steps 1 and 2 of _[Test the out-of-the-box setup](#test-the-out-of-the-box-setup)_.
    1. Check if the `incoming` user received the email:
    
        ```sh
        su - incoming
        MAIL=/home/incoming/Maildir
        mail
        ```

        You should see output like this:

        ```
        "/home/incoming/Maildir": 1 message 1 unread
        >U   1 root@localhost                           59/2842  Re: Some issue
        ```

        Quit the mail app:

        ```sh
        q
        ```

    _**Note:** If `mail` returns an error `Maildir: Is a directory` then your
    version of `mail` doesn't support Maildir style mailboxes. Install
    `heirloom-mailx` by running `sudo apt-get install heirloom-mailx`. Then,
    try the above steps again, substituting `heirloom-mailx` for the `mail`
    command._

1. Log out of the `incoming` account and go back to being `root`:

    ```sh
    logout
    ```

## Install the Courier IMAP server
    
1. Install the `courier-imap` package:

    ```sh
    sudo apt-get install courier-imap
    ```

## Configure Postfix to receive email from the internet

1. Let Postfix know about the domains that it should consider local:
    
    ```sh
    sudo postconf -e "mydestination = gitlab.example.com, localhost.localdomain, localhost"
    ```

1. Let Postfix know about the IPs that it should consider part of the LAN:
    
    We'll assume `192.168.1.0/24` is your local LAN. You can safely skip this step if you don't have other machines in the same local network.
    
    ```sh
    sudo postconf -e "mynetworks = 127.0.0.0/8, 192.168.1.0/24"
    ```

1. Configure Postfix to receive mail on all interfaces, which includes the internet:
    
    ```sh
    sudo postconf -e "inet_interfaces = all"
    ```

1. Configure Postfix to use the `+` delimiter for sub-addressing:
    
    ```sh
    sudo postconf -e "recipient_delimiter = +"
    ```

1. Restart Postfix:
    
    ```sh
    sudo service postfix restart
    ```

## Test the final setup

1. Test SMTP under the new setup:
    
    1. Connect to the SMTP server:
        
        ```sh
        telnet gitlab.example.com 25
        ```

        You should see a prompt like this:

        ```sh
        Trying 123.123.123.123...
        Connected to gitlab.example.com.
        Escape character is '^]'.
        220 gitlab.example.com ESMTP Postfix (Ubuntu)
        ```

        If you get a `Connection refused` error instead, make sure your firewall is setup to allow inbound traffic on port 25.

    1. Send the `incoming` user a dummy email to test SMTP, by entering the following into the SMTP prompt:
        
        ```
        ehlo gitlab.example.com
        mail from: root@gitlab.example.com
        rcpt to: incoming@gitlab.example.com
        data
        Subject: Re: Some issue

        Sounds good!
        .
        quit
        ```

        (Note: The `.` is a literal period on its own line)

    1. Check if the `incoming` user received the email:
    
        ```sh
        su - incoming
        MAIL=/home/incoming/Maildir
        mail
        ```

        You should see output like this:

        ```
        "/home/incoming/Maildir": 1 message 1 unread
        >U   1 root@gitlab.example.com                           59/2842  Re: Some issue
        ```

        Quit the mail app:

        ```sh
        q
        ```

    1. Log out of the `incoming` account and go back to being `root`:

        ```sh
        logout
        ```

1. Test IMAP under the new setup:
    
    1. Connect to the IMAP server:
        
        ```sh
        telnet gitlab.example.com 143
        ```

        You should see a prompt like this:

        ```sh
        Trying 123.123.123.123...
        Connected to mail.example.gitlab.com.
        Escape character is '^]'.
        - OK [CAPABILITY IMAP4rev1 UIDPLUS CHILDREN NAMESPACE THREAD=ORDEREDSUBJECT THREAD=REFERENCES SORT QUOTA IDLE ACL ACL2=UNION] Courier-IMAP ready. Copyright 1998-2011 Double Precision, Inc.  See COPYING for distribution information.
        ```

    1. Sign in as the `incoming` user to test IMAP, by entering the following into the IMAP prompt:

        ```
        a login incoming PASSWORD
        ```

        Replace PASSWORD with the password you set on the `incoming` user earlier.

        You should see output like this:

        ```
        a OK LOGIN Ok.
        ```

    1. Disconnect from the IMAP server:

        ```sh
        a logout
        ```

## Done!

If all the tests were successful, Postfix is all set up and ready to receive email! Continue with the [Reply by email](./README.md) guide to configure GitLab.

---------

_This document was adapted from https://help.ubuntu.com/community/PostfixBasicSetupHowto, by contributors to the Ubuntu documentation wiki._
