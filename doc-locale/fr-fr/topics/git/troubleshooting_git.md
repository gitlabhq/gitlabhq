---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Résolution des problèmes Git
description: Dépanner et résoudre les erreurs Git courantes et les problèmes de connexion.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Il arrive que les choses ne fonctionnent pas comme prévu lorsque vous utilisez Git. Voici quelques conseils pour dépanner et résoudre les problèmes liés à Git.

## Débogage {#debugging}

Lors du débogage de problèmes Git sur un serveur GitLab, utilisez `/opt/gitlab/embedded/bin/git` plutôt que le binaire `git` fourni par le système, qui pourrait être plus ancien.

### Utiliser une clé SSH personnalisée pour une commande Git {#use-a-custom-ssh-key-for-a-git-command}

```shell
GIT_SSH_COMMAND="ssh -i ~/.ssh/gitlabadmin" git <command>
```

Remplacez `<command>` par la commande Git que vous souhaitez exécuter.

### Déboguer Git via SSH {#debug-git-over-ssh}

```shell
GIT_SSH_COMMAND="ssh -vvv" git clone <git@url> 2>&1 \
| tee /tmp/gitlab-clone-test.log
```

Remplacez `<git@url>` par l'URL SSH de votre dépôt. La sortie est enregistrée dans `/tmp/gitlab-clone-test.log`.

### Déboguer Git via HTTPS {#debug-git-over-https}

```shell
GIT_TRACE_PACKET=1 GIT_TRACE=2 GIT_CURL_VERBOSE=1 git clone <url> 2>&1 \
| tee /tmp/gitlab-clone-test.log
```

Remplacez `<url>` par l'URL HTTPS de votre dépôt. La sortie est enregistrée dans `/tmp/gitlab-clone-test.log`.

### Déboguer Git avec des traces {#debug-git-with-traces}

Git inclut un ensemble complet de [traces pour le débogage des commandes Git](https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables#_debugging), par exemple :

- `GIT_TRACE_PERFORMANCE=1` : active le traçage des données de performance, indiquant la durée de chaque invocation de `git`.
- `GIT_TRACE_SETUP=1` : active le traçage de ce que `git` découvre sur le dépôt et l'environnement avec lequel il interagit.
- `GIT_TRACE_PACKET=1` : active le traçage au niveau des paquets pour les opérations réseau.
- `GIT_CURL_VERBOSE=1` : active la sortie détaillée de `curl`, qui [peut inclure des identifiants](https://curl.se/docs/manpage.html#-v).

## Erreurs `Broken pipe` lors de `git push` {#broken-pipe-errors-on-git-push}

Des erreurs `Broken pipe` peuvent se produire lors d'une tentative de push vers un dépôt distant. Lors d'un push, vous verrez généralement :

```plaintext
Write failed: Broken pipe
fatal: The remote end hung up unexpectedly
```

Pour résoudre ce problème, voici quelques solutions possibles.

### Augmenter la taille du tampon POST dans Git {#increase-the-post-buffer-size-in-git}

Lorsque vous tentez de pousser de grands dépôts avec Git via HTTPS, vous pourriez obtenir un message d'erreur tel que :

```shell
fatal: pack has bad object at offset XXXXXXXXX: inflate returned -5
```

Pour résoudre ce problème :

- Augmentez la valeur de [http.postBuffer](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httppostBuffer) dans votre configuration Git locale. La valeur par défaut est 1 Mo. Par exemple, si `git clone` échoue lors du clonage d'un dépôt de 500 Mo, exécutez ce qui suit :

  1. Ouvrez un terminal ou une invite de commandes.
  1. Augmentez la valeur de `http.postBuffer` :

     ```shell
     # Set the http.postBuffer size in bytes
     git config http.postBuffer 524288000
     ```

Si la configuration locale ne résout pas le problème, vous devrez peut-être modifier la configuration du serveur. Cette opération doit être effectuée avec précaution et uniquement si vous disposez d'un accès au serveur.

- Augmentez `http.postBuffer` côté serveur :

  1. Ouvrez un terminal ou une invite de commandes.
  1. Modifiez le fichier [`gitlab.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/13.5.1+ee.0/files/gitlab-config-template/gitlab.rb.template#L1435-1455) de l'instance GitLab :

     ```ruby
     gitaly['configuration'] = {
       # ...
       git: {
         # ...
         config: [
           # Set the http.postBuffer size, in bytes
           {key: "http.postBuffer", value: "524288000"},
         ],
       },
     }
     ```

  1. Appliquez le changement de configuration :

     ```shell
     sudo gitlab-ctl reconfigure
     ```

### Erreur : `stream 0 was not closed cleanly` {#error-stream-0-was-not-closed-cleanly}

Si vous voyez cette erreur, elle peut être causée par une connexion Internet lente :

```plaintext
RPC failed; curl 92 HTTP/2 stream 0 was not closed cleanly: INTERNAL_ERROR (err 2)
```

Si vous utilisez Git via HTTP plutôt que SSH, essayez l'une de ces solutions :

- Augmentez la taille du tampon POST dans la configuration Git avec `git config http.postBuffer 52428800`.
- Passez au protocole `HTTP/1.1` avec `git config http.version HTTP/1.1`.

Si aucune de ces approches ne corrige l'erreur, vous aurez peut-être besoin d'un fournisseur d'accès Internet différent.

### Vérifier votre configuration SSH {#check-your-ssh-configuration}

Si vous effectuez un push via SSH, vérifiez d'abord votre configuration SSH, car les erreurs « Broken pipe » peuvent parfois être causées par des problèmes sous-jacents liés à SSH (tels que l'authentification). Assurez-vous que SSH est correctement configuré en suivant les instructions de la documentation de [dépannage SSH](../../user/ssh_troubleshooting.md#password-prompt-with-git-clone).

Si vous êtes un administrateur GitLab disposant d'un accès au serveur, vous pouvez également éviter les délais d'expiration de session en configurant SSH `keep-alive` sur le client ou le serveur.

> [!note]
> La configuration des deux côtés (client et serveur) est inutile.

Pour configurer SSH côté client :

- Sur UNIX, modifiez `~/.ssh/config` (créez le fichier s'il n'existe pas) et ajoutez ou modifiez :

  ```plaintext
  Host your-gitlab-instance-url.com
    ServerAliveInterval 60
    ServerAliveCountMax 5
  ```

- Sur Windows, si vous utilisez PuTTY, accédez aux propriétés de votre session, puis allez dans **Connexion** et sous **Sending of null packets to keep session active**, définissez `Seconds between keepalives (0 to turn off)` sur `60`.

Pour configurer SSH côté serveur, modifiez `/etc/ssh/sshd_config` et ajoutez :

```plaintext
ClientAliveInterval 60
ClientAliveCountMax 5
```

### Exécution d'un `git repack` {#running-a-git-repack}

Si des erreurs de type « pack-objects » s'affichent également, vous pouvez essayer d'exécuter un `git repack` avant de tenter à nouveau un push vers le dépôt distant :

```shell
git repack
git push
```

### Mettre à jour votre client Git {#upgrade-your-git-client}

Si vous utilisez une ancienne version de Git (< 2.9), envisagez de passer à la version >= 2.9. Pour plus d'informations, consultez [broken pipe when pushing to Git repository](https://stackoverflow.com/questions/19120120/broken-pipe-when-pushing-to-git-repository/36971469#36971469).

## Erreur `ssh_exchange_identification` {#ssh_exchange_identification-error}

Les utilisateurs peuvent rencontrer l'erreur suivante lors d'une tentative de push ou de pull avec Git via SSH :

```plaintext
Please make sure you have the correct access rights
and the repository exists.
...
ssh_exchange_identification: read: Connection reset by peer
fatal: Could not read from remote repository.
```

ou

```plaintext
ssh_exchange_identification: Connection closed by remote host
fatal: The remote end hung up unexpectedly
```

ou

```plaintext
kex_exchange_identification: Connection closed by remote host
Connection closed by x.x.x.x port 22
```

Cette erreur indique généralement que la valeur `MaxStartups` du démon SSH limite les connexions SSH. Ce paramètre spécifie le nombre maximum de connexions simultanées non authentifiées au démon SSH. Cela affecte les utilisateurs disposant d'identifiants d'authentification appropriés (clés SSH), car chaque connexion est « non authentifiée » au départ. La [valeur par défaut](https://man.openbsd.org/sshd_config#MaxStartups) est `10`.

Cela peut être vérifié en examinant les journaux [`sshd`](https://en.wikibooks.org/wiki/OpenSSH/Logging_and_Troubleshooting#Server_Logs) de l'hôte. Pour les systèmes de la famille Debian, consultez `/var/log/auth.log`, et pour les dérivés RHEL, vérifiez `/var/log/secure` pour les erreurs suivantes :

```plaintext
sshd[17242]: error: beginning MaxStartups throttling
sshd[17242]: drop connection #1 from [CLIENT_IP]:52114 on [CLIENT_IP]:22 past MaxStartups
```

L'absence de cette erreur indique que le démon SSH ne limite pas les connexions, ce qui suggère que le problème sous-jacent est peut-être lié au réseau.

### Augmenter le nombre de connexions SSH simultanées non authentifiées {#increase-the-number-of-unauthenticated-concurrent-ssh-connections}

Augmentez `MaxStartups` sur le serveur GitLab en ajoutant ou en modifiant la valeur dans `/etc/ssh/sshd_config` :

```plaintext
MaxStartups 100:30:200
```

`100:30:200` signifie que jusqu'à 100 sessions SSH sont autorisées sans restriction, après quoi 30 % des connexions sont rejetées jusqu'à atteindre un maximum absolu de 200.

Après avoir modifié la valeur de `MaxStartups`, vérifiez si la configuration contient des erreurs.

```shell
sudo sshd -t -f /etc/ssh/sshd_config
```

Si la vérification de la configuration se déroule sans erreur, il devrait être possible de redémarrer le démon SSH en toute sécurité pour que la modification prenne effet.

```shell
# Debian/Ubuntu
sudo systemctl restart ssh

# CentOS/RHEL
sudo service sshd restart
```

## Délai d'expiration lors de `git push` / `git pull` {#timeout-during-git-push--git-pull}

Si un pull ou un push depuis/vers votre dépôt prend plus de 50 secondes, un délai d'expiration est déclenché. Il contient un journal du nombre d'opérations effectuées et de leurs durées respectives, comme dans l'exemple ci-dessous :

```plaintext
remote: Running checks for branch: master
remote: Scanning for LFS objects... (153ms)
remote: Calculating new repository size... (canceled after 729ms)
```

Ces informations peuvent être utilisées pour mieux analyser quelle opération est peu performante et fournir à GitLab davantage d'informations sur la façon d'améliorer le service.

### Erreur : `Operation timed out` {#error-operation-timed-out}

Si vous rencontrez une erreur de ce type lors de l'utilisation de Git, cela indique généralement un problème réseau :

```shell
ssh: connect to host gitlab.com port 22: Operation timed out
fatal: Could not read from remote repository
```

Pour aider à identifier le problème sous-jacent :

- Connectez-vous via un réseau différent (par exemple, passez du Wi-Fi aux données mobiles) pour écarter les problèmes de réseau local ou de pare-feu.
- Exécutez cette commande bash pour recueillir des informations `traceroute` et `ping` : `mtr -T -P 22 <gitlab_server>.com`. Pour en savoir plus sur MTR et comment interpréter sa sortie, consultez l'article Cloudflare sur [My Traceroute (MTR)](https://www.cloudflare.com/en-gb/learning/network-layer/what-is-mtr/).

## Erreur : `transfer closed with outstanding read data remaining` {#error-transfer-closed-with-outstanding-read-data-remaining}

Parfois, lors du clonage d'anciens dépôts ou de dépôts volumineux, l'erreur suivante s'affiche lors de l'exécution de `git clone` via HTTP :

```plaintext
error: RPC failed; curl 18 transfer closed with outstanding read data remaining
fatal: The remote end hung up unexpectedly
fatal: early EOF
fatal: index-pack failed
```

Ce problème est courant dans Git lui-même, en raison de son incapacité à gérer des fichiers volumineux ou de grandes quantités de fichiers. [Git LFS](https://about.gitlab.com/blog/getting-started-with-git-lfs-tutorial/) a été créé pour contourner ce problème ; cependant, il présente lui aussi des limitations. Cela est généralement dû à l'une des raisons suivantes :

- Le nombre de fichiers dans le dépôt.
- Le nombre de révisions dans l'historique.
- La présence de fichiers volumineux dans le dépôt.

Si cette erreur se produit lors du clonage d'un dépôt volumineux, vous pouvez [diminuer la profondeur de clonage](../../user/project/repository/monorepos/_index.md#use-shallow-clones-and-filters-in-cicd-processes) à une valeur de `1`. Par exemple :

Cette approche ne résout pas la cause sous-jacente, mais vous permet de cloner le dépôt avec succès. Pour diminuer la profondeur de clonage à `1`, exécutez :

  ```shell
  variables:
    GIT_DEPTH: 1
  ```

## Erreur `Your password expired` lors d'un Git fetch via SSH pour un utilisateur LDAP {#your-password-expired-error-on-git-fetch-with-ssh-for-ldap-user}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Si `git fetch` renvoie cette erreur `HTTP 403 Forbidden` sur GitLab Self-Managed, la date d'expiration du mot de passe (`users.password_expires_at`) de cet utilisateur dans la base de données GitLab est une date passée :

```plaintext
Your password expired. Please access GitLab from a web browser to update your password.
```

Les requêtes effectuées avec un compte SSO et pour lesquelles `password_expires_at` n'est pas `null` renvoient cette erreur :

```plaintext
"403 Forbidden - Your password expired. Please access GitLab from a web browser to update your password."
```

Pour résoudre ce problème, vous pouvez mettre à jour la date d'expiration du mot de passe de l'une des façons suivantes :

- En utilisant la [console GitLab Rails](../../administration/operations/rails_console.md) pour vérifier et mettre à jour les données utilisateur :

  ```ruby
  user = User.find_by_username('<USERNAME>')
  user.password_expired?
  user.password_expires_at
  user.update!(password_expires_at: nil)
  ```

- En utilisant `gitlab-psql` :

  ```sql
  # gitlab-psql
  UPDATE users SET password_expires_at = null WHERE username='<USERNAME>';
  ```

Le bug a été signalé dans le [ticket 332455](https://gitlab.com/gitlab-org/gitlab/-/issues/332455).

## Erreur lors d'un Git fetch : `HTTP Basic: Access Denied` {#error-on-git-fetch-http-basic-access-denied}

Si vous recevez une erreur `HTTP Basic: Access denied` lors de l'utilisation de Git via HTTP(S), consultez le [guide de dépannage de l'authentification à deux facteurs](../../user/profile/account/two_factor_authentication_troubleshooting.md).

Cette erreur peut également se produire avec [Git for Windows](https://gitforwindows.org/) 2.46.0 et versions ultérieures. Lors de l'authentification avec un jeton, le nom d'utilisateur peut être n'importe quelle valeur, mais une valeur vide pourrait déclencher l'erreur d'authentification.

Pour résoudre ce problème, spécifiez une chaîne de nom d'utilisateur. Utilisez l'une des méthodes suivantes, en remplaçant `<USERNAME>` par votre nom d'utilisateur GitLab :

- Lors du clonage d'un dépôt :

  ```shell
  git clone https://<USERNAME>@gitlab.com/path/to/a/project.git
  ```

- Mettre à jour l'URL d'un remote existant :

  ```shell
  git remote set-url origin https://<USERNAME>@gitlab.com/path/to/a/project.git
  ```

- Configurer Git pour toujours utiliser un nom d'utilisateur pour un hôte spécifique :

  ```shell
  git config --global url."https://<USERNAME>@gitlab.com/".insteadOf "https://gitlab.com/"
  ```

## Erreurs `401` enregistrées lors d'un `git clone` réussi {#401-errors-logged-during-successful-git-clone}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Lors du clonage d'un dépôt via HTTP, le fichier [`production_json.log`](../../administration/logs/_index.md#production_jsonlog) peut afficher un statut initial de `401` (non autorisé), suivi rapidement d'un `200`.

```json
{
   "method":"GET",
   "path":"/group/project.git/info/refs",
   "format":"*/*",
   "controller":"Repositories::GitHttpController",
   "action":"info_refs",
   "status":401,
   "time":"2023-04-18T22:55:15.371Z",
   "remote_ip":"x.x.x.x",
   "ua":"git/2.39.2",
   "correlation_id":"01GYB98MBM28T981DJDGAD98WZ",
   "duration_s":0.03585
}
{
   "method":"GET",
   "path":"/group/project.git/info/refs",
   "format":"*/*",
   "controller":"Repositories::GitHttpController",
   "action":"info_refs",
   "status":200,
   "time":"2023-04-18T22:55:15.714Z",
   "remote_ip":"x.x.x.x",
   "user_id":1,
   "username":"root",
   "ua":"git/2.39.2",
   "correlation_id":"01GYB98MJ0CA3G9K8WDH7HWMQX",
   "duration_s":0.17111
}
```

Cette entrée initiale `401` dans le journal est attendue pour chaque opération Git effectuée via HTTP, en raison du fonctionnement de l'[authentification HTTP basic](https://en.wikipedia.org/wiki/Basic_access_authentication).

Lorsque le client Git initie un clonage, la requête initiale envoyée à GitLab ne fournit aucune information d'authentification. GitLab renvoie un résultat `401 Unauthorized` pour cette requête. Quelques millisecondes plus tard, le client Git envoie une requête de suivi contenant les informations d'authentification. Cette deuxième requête devrait réussir et produire une entrée de journal `200 OK`.

Si une entrée de journal `401` ne dispose pas d'une entrée de journal `200` correspondante, le client Git utilise probablement :

- Un mot de passe incorrect.
- Un jeton expiré ou révoqué.

Si ce problème n'est pas corrigé, vous pourriez rencontrer des [erreurs `403` (Forbidden)](#403-error-when-performing-git-operations-over-http) à la place.

## Erreur `403` lors d'opérations Git via HTTP {#403-error-when-performing-git-operations-over-http}

Lors d'opérations Git via HTTP, une erreur `403` (Forbidden) indique que votre adresse IP a été bloquée par l'interdiction suite à des échecs d'authentification :

```plaintext
fatal: unable to access 'https://gitlab.com/group/project.git/': The requested URL returned error: 403
```

Les limites de l'interdiction suite à des échecs d'authentification diffèrent selon que vous utilisez [GitLab Self-Managed](../../security/rate_limits.md#failed-authentication-ban-for-git-and-container-registry) ou [GitLab.com](../../user/gitlab_com/_index.md#ip-blocks).

### Consulter les journaux pour les échecs d'authentification {#check-logs-for-failed-authentications}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

L'erreur `403` peut être observée dans le fichier [`production_json.log`](../../administration/logs/_index.md#production_jsonlog) :

```json
{
   "method":"GET",
   "path":"/group/project.git/info/refs",
   "format":"*/*",
   "controller":"Repositories::GitHttpController",
   "action":"info_refs",
   "status":403,
   "time":"2023-04-19T22:14:25.894Z",
   "remote_ip":"x.x.x.x",
   "user_id":1,
   "username":"root",
   "ua":"git/2.39.2",
   "correlation_id":"01GYDSAKAN2SPZPAMJNRWW5H8S",
   "duration_s":0.00875
}
```

Si votre adresse IP a été bloquée, une entrée de journal correspondante existe dans le fichier [`auth_json.log`](../../administration/logs/_index.md#auth_jsonlog) :

```json
{
    "severity":"ERROR",
    "time":"2023-04-19T22:14:25.893Z",
    "correlation_id":"01GYDSAKAN2SPZPAMJNRWW5H8S",
    "message":"Rack_Attack",
    "env":"blocklist",
    "remote_ip":"x.x.x.x",
    "request_method":"GET",
    "path":"/group/project.git/info/refs?service=git-upload-pack"}
```
