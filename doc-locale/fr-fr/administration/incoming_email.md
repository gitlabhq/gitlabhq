---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: E-mail entrant
description: Configurer les e-mails entrants.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab dispose de plusieurs fonctionnalités basées sur la réception d'e-mails entrants :

- [Répondre par e-mail](reply_by_email.md) : permet aux utilisateurs GitLab de commenter les tickets et les merge requests en répondant à l'e-mail de notification.
- [Nouveau ticket par e-mail](../user/project/issues/create_issues.md#by-sending-an-email) : permet aux utilisateurs GitLab de créer un nouveau ticket en envoyant un e-mail à une adresse e-mail spécifique à l'utilisateur.
- [Nouvelle merge request par e-mail](../user/project/merge_requests/creating_merge_requests.md#by-sending-an-email) : permet aux utilisateurs GitLab de créer une nouvelle merge request en envoyant un e-mail à une adresse e-mail spécifique à l'utilisateur.
- [Service Desk](../user/project/service_desk/_index.md) : fournit une assistance par e-mail à vos clients via GitLab.

## Prérequis {#requirements}

Vous devez utiliser une adresse e-mail qui reçoit **uniquement** les messages destinés à l'instance GitLab. Tout e-mail entrant non destiné à GitLab reçoit un avis de rejet.

La gestion des e-mails entrants nécessite un compte e-mail compatible [IMAP](https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol). GitLab requiert l'une des trois stratégies suivantes :

- Sous-adressage d'e-mail (recommandé)
- Boîte de réception catch-all
- Adresse e-mail dédiée (prend en charge uniquement la réponse par e-mail)

Passons en revue chacune de ces options.

### Sous-adressage d'e-mail {#email-sub-addressing}

[Le sous-adressage](https://en.wikipedia.org/wiki/Email_address#Sub-addressing) est une fonctionnalité de serveur de messagerie qui permet à tout e-mail envoyé à `user+arbitrary_tag@example.com` d'aboutir dans la boîte de réception de `user@example.com` . Cette fonctionnalité est prise en charge par des fournisseurs tels que Gmail, Google Apps, Yahoo! Mail, Outlook.com et iCloud, ainsi que par le [serveur de messagerie Postfix](reply_by_email_postfix_setup.md), que vous pouvez exécuter sur site. Microsoft Exchange Server [ne prend pas en charge le sous-adressage](#microsoft-exchange-server), et Microsoft Office 365 [ne prend pas en charge le sous-adressage par défaut](#microsoft-office-365).

> [!note]
> Si votre fournisseur ou serveur prend en charge le sous-adressage d'e-mail, vous devriez l'utiliser. Une adresse e-mail dédiée ne prend en charge que la fonctionnalité de réponse par e-mail. Une boîte de réception catch-all prend en charge les mêmes fonctionnalités que le sous-adressage, mais le sous-adressage reste préférable car une seule adresse e-mail est utilisée, laissant la boîte catch-all disponible pour d'autres usages au-delà de GitLab.

### Boîte de réception catch-all {#catch-all-mailbox}

Une [boîte de réception catch-all](https://en.wikipedia.org/wiki/Catch-all) pour un domaine reçoit tous les e-mails adressés au domaine qui ne correspondent à aucune adresse existant sur le serveur de messagerie.

Les boîtes de réception catch-all prennent en charge les mêmes fonctionnalités que le sous-adressage d'e-mail, mais le sous-adressage d'e-mail reste notre recommandation afin que vous puissiez réserver votre boîte catch-all à d'autres usages.

### Adresse e-mail dédiée {#dedicated-email-address}

Pour configurer cette solution, vous devez créer une adresse e-mail dédiée pour recevoir les réponses de vos utilisateurs aux notifications GitLab. Cependant, cette méthode ne prend en charge que les réponses, et non les autres fonctionnalités des e-mails entrants.

## En-têtes acceptés {#accepted-headers}

{{< history >}}

- Acceptation des en-têtes `Cc` [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/348572) dans GitLab 16.5.
- Acceptation des en-têtes `X-Original-To` [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149874) dans GitLab 17.0.
- Acceptation des en-têtes `X-Forwarded-To` [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168716) dans GitLab 17.6.
- Acceptation des en-têtes `X-Delivered-To` [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170221) dans GitLab 17.6.

{{< /history >}}

L'e-mail est traité correctement lorsqu'une adresse e-mail configurée est présente dans l'un des en-têtes suivants (triés dans l'ordre où ils sont vérifiés) :

- `To`
- `Delivered-To`
- `X-Delivered-To`
- `Envelope-To` ou `X-Envelope-To`
- `Received`
- `X-Original-To`
- `X-Forwarded-To`
- `Cc`

L'en-tête `References` est également accepté, mais il est utilisé spécifiquement pour associer les réponses par e-mail aux fils de discussion existants. Il n'est pas utilisé pour créer des tickets par e-mail.

Dans GitLab 14.6 et versions ultérieures, [Service Desk](../user/project/service_desk/_index.md) vérifie également les en-têtes acceptés.

En général, le champ `To` contient l'adresse e-mail du destinataire principal. Cependant, il peut ne pas inclure l'adresse e-mail GitLab configurée si :

- L'adresse se trouve dans le champ `BCC`.
- L'e-mail a été transféré.

L'en-tête `Received` peut contenir plusieurs adresses e-mail. Celles-ci sont vérifiées dans l'ordre dans lequel elles apparaissent. La première correspondance est utilisée.

## En-têtes rejetés {#rejected-headers}

Pour éviter la création indésirable de tickets par des systèmes d'e-mail automatiques, GitLab ignore tous les e-mails entrants contenant les en-têtes suivants :

- `Auto-Submitted` avec une valeur autre que `no`
- `X-Autoreply` avec la valeur `yes`

## Configuration {#set-it-up}

Si vous souhaitez utiliser Gmail / Google Apps pour les e-mails entrants, assurez-vous d'avoir [activé l'accès IMAP](https://support.google.com/mail/answer/7126229) et [autorisé les applications moins sécurisées à accéder au compte](https://support.google.com/accounts/answer/6010255) ou [activé la validation en 2 étapes](https://support.google.com/accounts/answer/185839) et d'utiliser [un mot de passe d'application](https://support.google.com/mail/answer/185833).

Si vous souhaitez utiliser Office 365 et que l'authentification à deux facteurs est activée, assurez-vous d'utiliser un [mot de passe d'application](https://support.microsoft.com/en-us/account-billing/app-passwords-for-a-work-or-school-account-d6dc8c6d-4bf7-4851-ad95-6d07799387e9) au lieu du mot de passe habituel pour la boîte aux lettres.

Pour configurer un serveur de messagerie Postfix de base avec accès IMAP sur Ubuntu, suivez la [documentation de configuration Postfix](reply_by_email_postfix_setup.md).

### Considérations de sécurité {#security-concerns}

> [!warning]
> Soyez prudent lors du choix du domaine utilisé pour recevoir les e-mails entrants.

Par exemple, supposons que le domaine principal de votre entreprise soit `hooli.com`. Tous les employés de votre entreprise disposent d'une adresse e-mail dans ce domaine via Google Workspace, et l'instance Slack privée de votre entreprise exige une adresse e-mail `@hooli.com` valide pour s'inscrire.

Si vous hébergez également une instance GitLab publique sur `hooli.com` et définissez votre domaine d'e-mail entrant sur `hooli.com`, un attaquant pourrait abuser des fonctionnalités Créer un nouveau ticket par e-mail ou [Créer une nouvelle merge request par e-mail](../user/project/merge_requests/creating_merge_requests.md#by-sending-an-email) en utilisant l'adresse unique d'un projet comme e-mail lors de l'inscription à Slack. Cela enverrait un e-mail de confirmation, qui créerait un nouveau ticket ou une nouvelle merge request sur le projet appartenant à l'attaquant, lui permettant de sélectionner le lien de confirmation et de valider son compte sur l'instance Slack privée de votre entreprise.

Nous recommandons de recevoir les e-mails entrants sur un sous-domaine, tel que `incoming.hooli.com`, et de veiller à ne pas utiliser de services qui s'authentifient uniquement sur la base de l'accès à un domaine d'e-mail tel que `*.hooli.com.` Alternativement, utilisez un domaine dédié aux communications e-mail GitLab tel que `hooli-gitlab.com`.

Consultez le ticket GitLab [\#30366](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30366) pour un exemple concret de cette exploitation.

> [!warning]
> Utilisez un serveur de messagerie qui a été configuré pour réduire le spam. Un serveur de messagerie Postfix fonctionnant avec une configuration par défaut, par exemple, peut être sujet aux abus. Tous les messages reçus dans la boîte aux lettres configurée sont traités et les messages non destinés à l'instance GitLab reçoivent un avis de rejet. Si l'adresse de l'expéditeur est usurpée, l'avis de rejet est remis à l'adresse `FROM` usurpée, ce qui peut faire apparaître l'IP ou le domaine du serveur de messagerie sur une liste de blocage.

Les utilisateurs peuvent utiliser les fonctionnalités d'e-mail entrant sans avoir à utiliser l'authentification à deux facteurs (2FA) pour s'authentifier au préalable. Cela s'applique même si vous avez [imposé l'authentification à deux facteurs](../security/two_factor_authentication.md) pour votre instance.

### Installations de packages Linux {#linux-package-installations}

1. Trouvez la section `incoming_email` dans `/etc/gitlab/gitlab.rb`, activez la fonctionnalité et renseignez les détails de votre serveur IMAP et de votre compte e-mail spécifiques (voir les [exemples](#configuration-examples) ci-dessous).

1. Reconfigurer GitLab pour que les modifications prennent effet :

   ```shell
   sudo gitlab-ctl reconfigure

   # Needed when enabling or disabling for the first time but not for password changes.
   # See https://gitlab.com/gitlab-org/gitlab-foss/-/issues/23560#note_61966788
   sudo gitlab-ctl restart
   ```

1. Vérifiez que tout est correctement configuré :

   ```shell
   sudo gitlab-rake gitlab:incoming_email:check
   ```

La réponse par e-mail devrait maintenant fonctionner.

### Installations compilées manuellement {#self-compiled-installations}

1. Accédez au répertoire d'installation de GitLab :

   ```shell
   cd /home/git/gitlab
   ```

1. Installez manuellement le gem `gitlab-mail_room` :

   ```shell
   gem install gitlab-mail_room
   ```

   > [!note]
   > Cette étape est nécessaire pour éviter les blocages de fils de discussion et pour prendre en charge les dernières fonctionnalités de MailRoom.

1. Trouvez la section `incoming_email` dans `config/gitlab.yml`, activez la fonctionnalité et renseignez les détails de votre serveur IMAP et de votre compte e-mail spécifiques (voir les [exemples](#configuration-examples) ci-dessous).

Si vous utilisez des unités systemd pour gérer GitLab :

1. Ajoutez `gitlab-mailroom.service` comme dépendance à `gitlab.target` :

   ```shell
   sudo systemctl edit gitlab.target
   ```

   Dans l'éditeur qui s'ouvre, ajoutez ce qui suit et enregistrez le fichier :

   ```plaintext
   [Unit]
   Wants=gitlab-mailroom.service
   ```

1. Si vous exécutez Redis et PostgreSQL sur la même machine, vous devriez ajouter une dépendance sur Redis. Exécutez :

   ```shell
   sudo systemctl edit gitlab-mailroom.service
   ```

   Dans l'éditeur qui s'ouvre, ajoutez ce qui suit et enregistrez le fichier :

   ```plaintext
   [Unit]
   Wants=redis-server.service
   After=redis-server.service
   ```

1. Démarrez `gitlab-mailroom.service` :

   ```shell
   sudo systemctl start gitlab-mailroom.service
   ```

1. Vérifiez que tout est correctement configuré :

   ```shell
   sudo -u git -H bundle exec rake gitlab:incoming_email:check RAILS_ENV=production
   ```

Si vous utilisez le script d'initialisation SysV pour gérer GitLab :

1. Activez `mail_room` dans le script d'initialisation dans `/etc/default/gitlab` :

   ```shell
   sudo mkdir -p /etc/default
   echo 'mail_room_enabled=true' | sudo tee -a /etc/default/gitlab
   ```

1. Redémarrez GitLab :

   ```shell
   sudo service gitlab restart
   ```

1. Vérifiez que tout est correctement configuré :

   ```shell
   sudo -u git -H bundle exec rake gitlab:incoming_email:check RAILS_ENV=production
   ```

La réponse par e-mail devrait maintenant fonctionner.

### Exemples de configuration {#configuration-examples}

#### Postfix {#postfix}

Exemple de configuration pour le serveur de messagerie Postfix. Suppose la boîte aux lettres `incoming@gitlab.example.com`.

Exemple pour les installations de packages Linux :

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@gitlab.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming+%{key}@gitlab.example.com"

# Email account username
# With third party providers, this is usually the full email address.
# With self-hosted email servers, this is usually the user part of the email address.
gitlab_rails['incoming_email_email'] = "incoming"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "gitlab.example.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 143
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = false
# Whether the IMAP server uses StartTLS
gitlab_rails['incoming_email_start_tls'] = false

# The mailbox where incoming mail will end up. Usually "inbox".
gitlab_rails['incoming_email_mailbox_name'] = "inbox"
# The IDLE command timeout.
gitlab_rails['incoming_email_idle_timeout'] = 60

# If you are using Microsoft Graph instead of IMAP, set this to false to retain
# messages in the inbox because deleted messages are auto-expunged after some time.
gitlab_rails['incoming_email_delete_after_delivery'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
# Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
gitlab_rails['incoming_email_expunge_deleted'] = true
```

Exemple pour les installations compilées manuellement :

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@gitlab.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    address: "incoming+%{key}@gitlab.example.com"

    # Email account username
    # With third party providers, this is usually the full email address.
    # With self-hosted email servers, this is usually the user part of the email address.
    user: "incoming"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "gitlab.example.com"
    # IMAP server port
    port: 143
    # Whether the IMAP server uses SSL
    ssl: false
    # Whether the IMAP server uses StartTLS
    start_tls: false

    # The mailbox where incoming mail will end up. Usually "inbox".
    mailbox: "inbox"
    # The IDLE command timeout.
    idle_timeout: 60

    # If you are using Microsoft Graph instead of IMAP, set this to false to retain
    # messages in the inbox because deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    # Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
    expunge_deleted: true
```

#### Gmail {#gmail}

Exemple de configuration pour Gmail/Google Workspace. Suppose la boîte aux lettres `gitlab-incoming@gmail.com`.

> [!note]
> `incoming_email_email` ne peut pas être un compte alias Gmail.

Exemple pour les installations de packages Linux :

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@gmail.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "gitlab-incoming+%{key}@gmail.com"

# Email account username
# With third party providers, this is usually the full email address.
# With self-hosted email servers, this is usually the user part of the email address.
gitlab_rails['incoming_email_email'] = "gitlab-incoming@gmail.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "imap.gmail.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true
# Whether the IMAP server uses StartTLS
gitlab_rails['incoming_email_start_tls'] = false

# The mailbox where incoming mail will end up. Usually "inbox".
gitlab_rails['incoming_email_mailbox_name'] = "inbox"
# The IDLE command timeout.
gitlab_rails['incoming_email_idle_timeout'] = 60

# If you are using Microsoft Graph instead of IMAP, set this to false if you want to retain
# messages in the inbox because deleted messages are auto-expunged after some time.
gitlab_rails['incoming_email_delete_after_delivery'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
# Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
gitlab_rails['incoming_email_expunge_deleted'] = true
```

Exemple pour les installations compilées manuellement :

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@gmail.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    address: "gitlab-incoming+%{key}@gmail.com"

    # Email account username
    # With third party providers, this is usually the full email address.
    # With self-hosted email servers, this is usually the user part of the email address.
    user: "gitlab-incoming@gmail.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "imap.gmail.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true
    # Whether the IMAP server uses StartTLS
    start_tls: false

    # The mailbox where incoming mail will end up. Usually "inbox".
    mailbox: "inbox"
    # The IDLE command timeout.
    idle_timeout: 60

    # If you are using Microsoft Graph instead of IMAP, set this to falseto retain
    # messages in the inbox because deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    # Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
    expunge_deleted: true
```

#### Microsoft Exchange Server {#microsoft-exchange-server}

Exemples de configurations pour Microsoft Exchange Server avec IMAP activé. Étant donné qu'Exchange ne prend pas en charge le sous-adressage, seulement deux options existent :

- [Boîte de réception catch-all](#catch-all-mailbox) (recommandée pour Exchange uniquement)
- [Adresse e-mail dédiée](#dedicated-email-address) (prend en charge uniquement la réponse par e-mail)

##### Boîte de réception catch-all {#catch-all-mailbox-1}

Suppose la boîte de réception catch-all `incoming@exchange.example.com`.

Exemple pour les installations de packages Linux :

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress-%{key}@exchange.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
# Exchange does not support sub-addressing, so a catch-all mailbox must be used.
gitlab_rails['incoming_email_address'] = "incoming-%{key}@exchange.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@ad-domain.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "exchange.example.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
# Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
gitlab_rails['incoming_email_expunge_deleted'] = true
```

Exemple pour les installations compilées manuellement :

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress-%{key}@exchange.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    # Exchange does not support sub-addressing, so a catch-all mailbox must be used.
    address: "incoming-%{key}@exchange.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@ad-domain.example.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "exchange.example.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # If you are using Microsoft Graph instead of IMAP, set this to false to retain
    # messages in the inbox because deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

##### Adresse e-mail dédiée {#dedicated-email-address-1}

> [!note]
> Prend en charge uniquement [la réponse par e-mail](reply_by_email.md). Ne peut pas prendre en charge [Service Desk](../user/project/service_desk/_index.md).

Suppose l'adresse e-mail dédiée `incoming@exchange.example.com`.

Exemple pour les installations de packages Linux :

```ruby
gitlab_rails['incoming_email_enabled'] = true

# Exchange does not support sub-addressing, and we're not using a catch-all mailbox so %{key} is not used here
gitlab_rails['incoming_email_address'] = "incoming@exchange.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@ad-domain.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "exchange.example.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

Exemple pour les installations compilées manuellement :

```yaml
incoming_email:
    enabled: true

    # Exchange does not support sub-addressing,
    # and we're not using a catch-all mailbox so %{key} is not used here
    address: "incoming@exchange.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@ad-domain.example.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "exchange.example.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # If you are using Microsoft Graph instead of IMAP, set this to false to retain
    # messages in the inbox because deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

#### Microsoft Office 365 {#microsoft-office-365}

Exemples de configurations pour Microsoft Office 365 avec IMAP activé.

##### Boîte aux lettres avec sous-adressage {#sub-addressing-mailbox}

> [!note]
> Depuis septembre 2020, la prise en charge du sous-adressage [a été ajoutée à Office 365](https://support.microsoft.com/en-us/office/uservoice-pages-430e1a78-e016-472a-a10f-dc2a3df3450a). Cette fonctionnalité n'est pas activée par défaut et doit être activée via PowerShell.

Cette série de commandes PowerShell active le [sous-adressage](#email-sub-addressing) au niveau de l'organisation dans Office 365. Cela permet à toutes les boîtes aux lettres de l'organisation de recevoir des e-mails avec sous-adressage.

Pour activer le sous-adressage :

1. Téléchargez et installez le module `ExchangeOnlineManagement` depuis la [galerie PowerShell](https://www.powershellgallery.com/packages/ExchangeOnlineManagement/3.7.1).
1. Dans PowerShell, exécutez les commandes suivantes :

   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   Import-Module ExchangeOnlineManagement
   Connect-ExchangeOnline
   Set-OrganizationConfig -DisablePlusAddressInRecipients $false
   Disconnect-ExchangeOnline
   ```

Cet exemple pour les installations de packages Linux suppose la boîte aux lettres `incoming@office365.example.com` :

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@office365.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming+%{key}@office365.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@office365.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "outlook.office365.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

Cet exemple pour les installations compilées manuellement suppose la boîte aux lettres `incoming@office365.example.com` :

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@office365.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    address: "incoming+%{key}@office365.example.comm"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@office365.example.comm"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "outlook.office365.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

##### Boîte de réception catch-all {#catch-all-mailbox-2}

Cet exemple pour les installations de packages Linux suppose la boîte de réception catch-all `incoming@office365.example.com` :

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress-%{key}@office365.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming-%{key}@office365.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@office365.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "outlook.office365.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

Cet exemple pour les installations compilées manuellement suppose la boîte de réception catch-all `incoming@office365.example.com` :

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@office365.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    address: "incoming-%{key}@office365.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@ad-domain.example.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "outlook.office365.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

##### Adresse e-mail dédiée {#dedicated-email-address-2}

> [!note]
> Prend en charge uniquement [la réponse par e-mail](reply_by_email.md). Ne peut pas prendre en charge [Service Desk](../user/project/service_desk/_index.md).

Cet exemple pour les installations de packages Linux suppose l'adresse e-mail dédiée `incoming@office365.example.com` :

```ruby
gitlab_rails['incoming_email_enabled'] = true

gitlab_rails['incoming_email_address'] = "incoming@office365.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@office365.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "outlook.office365.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

Cet exemple pour les installations compilées manuellement suppose l'adresse e-mail dédiée `incoming@office365.example.com` :

```yaml
incoming_email:
    enabled: true

    address: "incoming@office365.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@office365.example.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "outlook.office365.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

#### Microsoft Graph {#microsoft-graph}

GitLab peut lire les e-mails entrants à l'aide de l'API Microsoft Graph au lieu d'IMAP. Étant donné que [Microsoft abandonne l'utilisation d'IMAP avec l'authentification de base](https://techcommunity.microsoft.com/blog/exchange/announcing-oauth-2-0-support-for-imap-and-smtp-auth-protocols-in-exchange-online/1330432), l'API Microsoft Graph est requise pour les nouvelles boîtes aux lettres Microsoft Exchange Online.

Pour configurer GitLab pour Microsoft Graph, vous devez enregistrer une application OAuth 2.0 dans votre Azure Active Directory qui dispose de l'autorisation `Mail.ReadWrite` pour toutes les boîtes aux lettres. Consultez le [guide étape par étape de MailRoom](https://github.com/tpitale/mail_room/#microsoft-graph-configuration) et les [instructions Microsoft](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app) pour plus de détails.

Notez les informations suivantes lors de la configuration de votre application OAuth 2.0 :

- ID de locataire de votre Azure Active Directory
- ID client de votre application OAuth 2.0
- Secret client de votre application OAuth 2.0

##### Restriction de l'accès à la boîte aux lettres {#restrict-mailbox-access}

Pour que MailRoom fonctionne en tant que compte de service, l'application que vous créez dans Azure Active Directory exige que vous définissiez la propriété `Mail.ReadWrite` pour lire/écrire les e-mails dans toutes les boîtes aux lettres.

Pour atténuer les problèmes de sécurité, nous recommandons de configurer une stratégie d'accès aux applications qui limite l'accès aux boîtes aux lettres pour tous les comptes, comme décrit dans la [documentation Microsoft](https://learn.microsoft.com/en-us/graph/auth-limit-mailbox-access).

Cet exemple pour les installations de packages Linux suppose que vous utilisez la boîte aux lettres suivante : `incoming@example.onmicrosoft.com` :

##### Configurer Microsoft Graph {#configure-microsoft-graph}

{{< history >}}

- Déploiements Azure alternatifs [introduits](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5978) dans GitLab 14.9.

{{< /history >}}

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@example.onmicrosoft.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming+%{key}@example.onmicrosoft.com"

# Email account username
gitlab_rails['incoming_email_email'] = "incoming@example.onmicrosoft.com"
gitlab_rails['incoming_email_delete_after_delivery'] = false

gitlab_rails['incoming_email_inbox_method'] = 'microsoft_graph'
gitlab_rails['incoming_email_inbox_options'] = {
   'tenant_id': '<YOUR-TENANT-ID>',
   'client_id': '<YOUR-CLIENT-ID>',
   'client_secret': '<YOUR-CLIENT-SECRET>',
   'poll_interval': 60  # Optional
}
```

Pour Microsoft Cloud for US Government ou les [autres déploiements Azure](https://learn.microsoft.com/en-us/graph/deployments), configurez les paramètres `azure_ad_endpoint` et `graph_endpoint`.

- Exemple pour Microsoft Cloud for US Government :

```ruby
gitlab_rails['incoming_email_inbox_options'] = {
   'azure_ad_endpoint': 'https://login.microsoftonline.us',
   'graph_endpoint': 'https://graph.microsoft.us',
   'tenant_id': '<YOUR-TENANT-ID>',
   'client_id': '<YOUR-CLIENT-ID>',
   'client_secret': '<YOUR-CLIENT-SECRET>',
   'poll_interval': 60  # Optional
}
```

L'API Microsoft Graph n'est pas encore prise en charge dans les installations compilées manuellement. Consultez le [ticket 326169](https://gitlab.com/gitlab-org/gitlab/-/issues/326169) pour plus de détails.

### Utiliser des identifiants chiffrés {#use-encrypted-credentials}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108279) dans GitLab 15.9.

{{< /history >}}

Au lieu de stocker les identifiants d'e-mail entrant en texte brut dans les fichiers de configuration, vous pouvez optionnellement utiliser un fichier chiffré pour les identifiants d'e-mail entrant.

Prérequis :

- Pour utiliser des identifiants chiffrés, vous devez d'abord activer la [configuration chiffrée](encrypted_configuration.md).

Les éléments de configuration pris en charge pour le fichier chiffré sont :

- `user`
- `password`

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Si votre configuration d'e-mail entrant dans `/etc/gitlab/gitlab.rb` ressemblait initialement à ceci :

   ```ruby
   gitlab_rails['incoming_email_email'] = "incoming-email@mail.example.com"
   gitlab_rails['incoming_email_password'] = "examplepassword"
   ```

1. Modifiez le secret chiffré :

   ```shell
   sudo gitlab-rake gitlab:incoming_email:secret:edit EDITOR=vim
   ```

1. Saisissez le contenu non chiffré du secret d'e-mail entrant :

   ```yaml
   user: 'incoming-email@mail.example.com'
   password: 'examplepassword'
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et supprimez les paramètres `incoming_email` pour `email` et `password`.
1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Utilisez un secret Kubernetes pour stocker le mot de passe d'e-mail entrant. Pour plus d'informations, consultez les [secrets IMAP Helm](https://docs.gitlab.com/charts/installation/secrets/#imap-password-for-incoming-emails).

{{< /tab >}}

{{< tab title="Docker" >}}

1. Si votre configuration d'e-mail entrant dans `docker-compose.yml` ressemblait initialement à ceci :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['incoming_email_email'] = "incoming-email@mail.example.com"
           gitlab_rails['incoming_email_password'] = "examplepassword"
   ```

1. Accédez au conteneur et modifiez le secret chiffré :

   ```shell
   sudo docker exec -t <container_name> bash
   gitlab-rake gitlab:incoming_email:secret:edit EDITOR=editor
   ```

1. Saisissez le contenu non chiffré du secret d'e-mail entrant :

   ```yaml
   user: 'incoming-email@mail.example.com'
   password: 'examplepassword'
   ```

1. Modifiez `docker-compose.yml` et supprimez les paramètres `incoming_email` pour `email` et `password`.
1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Si votre configuration d'e-mail entrant dans `/home/git/gitlab/config/gitlab.yml` ressemblait initialement à ceci :

   ```yaml
   production:
     incoming_email:
       user: 'incoming-email@mail.example.com'
       password: 'examplepassword'
   ```

1. Modifiez le secret chiffré :

   ```shell
   bundle exec rake gitlab:incoming_email:secret:edit EDITOR=vim RAILS_ENVIRONMENT=production
   ```

1. Saisissez le contenu non chiffré du secret d'e-mail entrant :

   ```yaml
   user: 'incoming-email@mail.example.com'
   password: 'examplepassword'
   ```

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et supprimez les paramètres `incoming_email:` pour `user` et `password`.
1. Enregistrez le fichier et redémarrez GitLab et Mailroom

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## Dépannage {#troubleshooting}

### L'ingestion d'e-mails ne fonctionne pas dans la version 16.6.0 {#email-ingestion-doesnt-work-in-1660}

Dans GitLab 16.6, une régression empêche `mail_room` (ingestion d'e-mails) de démarrer. Service Desk et les autres fonctionnalités de réponse par e-mail ne fonctionnent pas. Ce problème a été corrigé dans la version 16.6.1. Consultez le [ticket 432257](https://gitlab.com/gitlab-org/gitlab/-/issues/432257) pour plus de détails.

La solution de contournement consiste à exécuter les commandes suivantes dans votre installation GitLab pour appliquer un correctif aux fichiers concernés :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
curl --output /tmp/mailroom.patch --url "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137279.diff"
patch -p1 -d /opt/gitlab/embedded/service/gitlab-rails < /tmp/mailroom.patch
gitlab-ctl restart mailroom
```

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
curl --output /tmp/mailroom.patch --url "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137279.diff"
cd /opt/gitlab/embedded/service/gitlab-rails
patch -p1 < /tmp/mailroom.patch
gitlab-ctl restart mailroom
```

{{< /tab >}}

{{< /tabs >}}

### Les e-mails entrants sont rejetés par les fournisseurs ayant une limite de longueur d'adresse e-mail {#incoming-emails-are-rejected-by-providers-with-email-address-limit}

Votre instance GitLab pourrait ne pas recevoir les e-mails entrants, car certains fournisseurs d'e-mail imposent une limite de 64 caractères sur la partie locale de l'adresse e-mail (avant le `@`). Tous les e-mails provenant d'adresses dépassant cette limite sont des e-mails rejetés.

Pour contourner ce problème, maintenez un chemin plus court :

- Assurez-vous que la partie locale configurée avant `%{key}` dans `incoming_email_address` est aussi courte que possible, et ne dépasse pas 31 caractères.
- Placez les projets désignés à un niveau de hiérarchie de groupe plus élevé.
- Renommez les [groupes](../user/group/manage.md#change-a-groups-path) et les [projets](../user/project/working_with_projects.md#rename-a-repository) avec des noms plus courts.

Suivez cette fonctionnalité dans le [ticket 460206](https://gitlab.com/gitlab-org/gitlab/-/issues/460206).
