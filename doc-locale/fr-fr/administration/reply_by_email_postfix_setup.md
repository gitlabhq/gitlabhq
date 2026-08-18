---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer Postfix pour les e-mails entrants
description: Configurer Postfix pour les e-mails entrants.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Ce document vous guide à travers les étapes de configuration d'un serveur de messagerie Postfix de base avec authentification IMAP sur Ubuntu, à utiliser avec les [e-mails entrants](incoming_email.md).

Les instructions supposent que vous utilisez l'adresse e-mail `incoming@gitlab.example.com`, c'est-à-dire le nom d'utilisateur `incoming` sur l'hôte `gitlab.example.com`. N'oubliez pas de le remplacer par votre hôte réel lors de l'exécution des exemples d'extraits de code.

## Configurer le pare-feu de votre serveur {#configure-your-server-firewall}

1. Ouvrez le port 25 sur votre serveur afin que les personnes puissent envoyer des e-mails vers le serveur via SMTP.
1. Si le serveur de messagerie est différent du serveur exécutant GitLab, ouvrez le port 143 sur votre serveur afin que GitLab puisse lire les e-mails depuis le serveur via IMAP.

## Installer les packages {#install-packages}

1. Installez le package `postfix` s'il n'est pas déjà installé :

   ```shell
   sudo apt-get install postfix
   ```

   Lorsqu'on vous demande l'environnement, sélectionnez « Internet Site ». Lorsqu'on vous demande de confirmer le nom d'hôte, assurez-vous qu'il correspond à `gitlab.example.com`.

1. Installez le package `mailutils`.

   ```shell
   sudo apt-get install mailutils
   ```

## Créer un utilisateur {#create-user}

1. Créez un utilisateur pour les e-mails entrants.

   ```shell
   sudo useradd -m -s /bin/bash incoming
   ```

1. Définissez un mot de passe pour cet utilisateur.

   ```shell
   sudo passwd incoming
   ```

   Veillez à ne pas l'oublier, vous en aurez besoin plus tard.

## Tester la configuration prête à l'emploi {#test-the-out-of-the-box-setup}

1. Connectez-vous au serveur SMTP local :

   ```shell
   telnet localhost 25
   ```

   Vous devriez voir une invite comme celle-ci :

   ```shell
   Trying 127.0.0.1...
   Connected to localhost.
   Escape character is '^]'.
   220 gitlab.example.com ESMTP Postfix (Ubuntu)
   ```

   Si vous obtenez plutôt une erreur `Connection refused`, vérifiez que `postfix` est en cours d'exécution :

   ```shell
   sudo postfix status
   ```

   S'il ne l'est pas, démarrez-le :

   ```shell
   sudo postfix start
   ```

1. Envoyez un e-mail au nouvel utilisateur `incoming` pour tester le SMTP, en saisissant ce qui suit dans l'invite SMTP :

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
   > Le `.` est un point littéral seul sur sa propre ligne.

   Si vous recevez une erreur après avoir saisi `rcpt to: incoming@localhost`, alors la configuration `my_network` de votre Postfix n'est pas correcte. L'erreur indiquera « Temporary lookup failure ». Consultez [Configurer Postfix pour recevoir des e-mails depuis Internet](#configure-postfix-to-receive-email-from-the-internet).

1. Vérifiez si l'utilisateur `incoming` a reçu l'e-mail :

   ```shell
   su - incoming
   mail
   ```

   Vous devriez voir une sortie comme celle-ci :

   ```plaintext
   "/var/mail/incoming": 1 message 1 unread
   >U   1 root@localhost                           59/2842  Re: Some issue
   ```

   Quittez l'application de messagerie :

   ```shell
   q
   ```

1. Déconnectez-vous du compte `incoming` et redevenez `root` :

   ```shell
   logout
   ```

## Configurer Postfix pour utiliser des boîtes aux lettres de style Maildir {#configure-postfix-to-use-maildir-style-mailboxes}

Courier, que nous installons plus tard pour ajouter l'authentification IMAP, nécessite que les boîtes aux lettres soient au format Maildir, plutôt que mbox.

1. Configurez Postfix pour utiliser des boîtes aux lettres de style Maildir :

   ```shell
   sudo postconf -e "home_mailbox = Maildir/"
   ```

1. Redémarrez Postfix :

   ```shell
   sudo /etc/init.d/postfix restart
   ```

1. Testez la nouvelle configuration :

   1. Suivez les étapes 1 et 2 de [Tester la configuration prête à l'emploi](#test-the-out-of-the-box-setup).
   1. Vérifiez si l'utilisateur `incoming` a reçu l'e-mail :

      ```shell
      su - incoming
      MAIL=/home/incoming/Maildir
      mail
      ```

      Vous devriez voir une sortie comme celle-ci :

      ```plaintext
      "/home/incoming/Maildir": 1 message 1 unread
      >U   1 root@localhost                           59/2842  Re: Some issue
      ```

      Quittez l'application de messagerie :

      ```shell
      q
      ```

   Si `mail` renvoie une erreur `Maildir: Is a directory`, alors votre version de `mail` ne prend pas en charge les boîtes aux lettres de style Maildir. Installez `heirloom-mailx` en exécutant `sudo apt-get install heirloom-mailx`. Ensuite, réessayez les étapes précédentes en remplaçant la commande `mail` par `heirloom-mailx`.

1. Déconnectez-vous du compte `incoming` et redevenez `root` :

   ```shell
   logout
   ```

## Installer le serveur IMAP Courier {#install-the-courier-imap-server}

1. Installez le package `courier-imap` :

   ```shell
   sudo apt-get install courier-imap
   ```

   Ubuntu 24.04 ne dispose pas du package `courier-imap`. Pour plus d'informations, consultez [Ubuntu bug 2071662](https://bugs.launchpad.net/ubuntu/+source/courier/+bug/2071662).

   Après avoir installé `courier-imap`, démarrez `imapd` :

   ```shell
   imapd start
   ```

1. Le `courier-authdaemon` ne démarre pas après l'installation. Sans lui, l'authentification IMAP échoue :

   ```shell
   sudo service courier-authdaemon start
   ```

   Vous pouvez également configurer `courier-authdaemon` pour qu'il démarre au démarrage du système :

   ```shell
   sudo systemctl enable courier-authdaemon
   ```

## Configurer Postfix pour recevoir des e-mails depuis Internet {#configure-postfix-to-receive-email-from-the-internet}

1. Indiquez à Postfix les domaines qu'il doit considérer comme locaux :

   ```shell
   sudo postconf -e "mydestination = gitlab.example.com, localhost.localdomain, localhost"
   ```

1. Indiquez à Postfix les adresses IP qu'il doit considérer comme faisant partie du réseau local :

   Supposons que `192.168.1.0/24` est votre réseau local. Vous pouvez ignorer cette étape sans risque si vous n'avez pas d'autres machines sur le même réseau local.

   ```shell
   sudo postconf -e "mynetworks = 127.0.0.0/8, 192.168.1.0/24"
   ```

1. Configurez Postfix pour recevoir des e-mails sur toutes les interfaces, y compris Internet :

   ```shell
   sudo postconf -e "inet_interfaces = all"
   ```

1. Configurez Postfix pour utiliser le délimiteur `+` pour le sous-adressage :

   ```shell
   sudo postconf -e "recipient_delimiter = +"
   ```

1. Redémarrez Postfix :

   ```shell
   sudo service postfix restart
   ```

## Tester la configuration finale {#test-the-final-setup}

1. Testez le SMTP avec la nouvelle configuration :

   1. Connectez-vous au serveur SMTP :

      ```shell
      telnet gitlab.example.com 25
      ```

      Vous devriez voir une invite comme celle-ci :

      ```shell
      Trying 123.123.123.123...
      Connected to gitlab.example.com.
      Escape character is '^]'.
      220 gitlab.example.com ESMTP Postfix (Ubuntu)
      ```

      Si vous obtenez plutôt une erreur `Connection refused`, assurez-vous que votre pare-feu est configuré pour autoriser le trafic entrant sur le port 25.

   1. Envoyez un e-mail à l'utilisateur `incoming` pour tester le SMTP, en saisissant ce qui suit dans l'invite SMTP :

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
      > Le `.` est un point littéral seul sur sa propre ligne.

   1. Vérifiez si l'utilisateur `incoming` a reçu l'e-mail :

      ```shell
      su - incoming
      MAIL=/home/incoming/Maildir
      mail
      ```

      Vous devriez voir une sortie comme celle-ci :

      ```plaintext
      "/home/incoming/Maildir": 1 message 1 unread
      >U   1 root@gitlab.example.com                           59/2842  Re: Some issue
      ```

      Quittez l'application de messagerie :

      ```shell
      q
      ```

   1. Déconnectez-vous du compte `incoming` et redevenez `root` :

      ```shell
      logout
      ```

1. Testez l'IMAP avec la nouvelle configuration :

   1. Connectez-vous au serveur IMAP :

      ```shell
      telnet gitlab.example.com 143
      ```

      Vous devriez voir une invite comme celle-ci :

      ```shell
      Trying 123.123.123.123...
      Connected to mail.gitlab.example.com.
      Escape character is '^]'.
      - OK [CAPABILITY IMAP4rev1 UIDPLUS CHILDREN NAMESPACE THREAD=ORDEREDSUBJECT THREAD=REFERENCES SORT QUOTA IDLE ACL ACL2=UNION] Courier-IMAP ready. Copyright 1998-2011 Double Precision, Inc.  See COPYING for distribution information.
      ```

   1. Connectez-vous en tant qu'utilisateur `incoming` pour tester l'IMAP, en saisissant ce qui suit dans l'invite IMAP :

      ```plaintext
      a login incoming PASSWORD
      ```

      Remplacez PASSWORD par le mot de passe que vous avez défini pour l'utilisateur `incoming` précédemment.

      Vous devriez voir une sortie comme celle-ci :

      ```plaintext
      a OK LOGIN Ok.
      ```

   1. Déconnectez-vous du serveur IMAP :

      ```shell
      a logout
      ```

## Terminé {#done}

Si tous les tests ont réussi, Postfix est entièrement configuré et prêt à recevoir des e-mails ! Poursuivez avec le guide sur les [e-mails entrants](incoming_email.md) pour configurer GitLab.

---

_Ce document a été adapté depuis <https://help.ubuntu.com/community/PostfixBasicSetupHowto>, par les contributeurs au wiki de documentation Ubuntu._
