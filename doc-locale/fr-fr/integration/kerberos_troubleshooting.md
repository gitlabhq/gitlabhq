---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépannage de GitLab avec l'intégration Kerberos"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Lorsque vous utilisez GitLab avec l'intégration Kerberos, vous pouvez rencontrer les problèmes suivants.

## Utilisation de Google Chrome avec l'authentification Kerberos contre Windows AD {#using-google-chrome-with-kerberos-authentication-against-windows-ad}

Lorsque vous utilisez Google Chrome pour vous connecter à GitLab avec Kerberos, vous devez saisir votre nom d'utilisateur complet. Par exemple, `username@domain.com`.

Si vous ne saisissez pas votre nom d'utilisateur complet, la connexion échoue. Consultez les journaux pour voir le message d'événement suivant comme preuve de cet échec de connexion :

```plain
"message":"OmniauthKerberosController: failed to process Negotiate/Kerberos authentication: gss_accept_sec_context did not return GSS_S_COMPLETE: An unsupported mechanism was requested\nUnknown error".
```

## Tester la connectivité entre les serveurs GitLab et Kerberos {#test-connectivity-between-the-gitlab-and-kerberos-servers}

Vous pouvez utiliser des utilitaires tels que [`kinit`](https://web.mit.edu/kerberos/krb5-1.12/doc/user/user_commands/kinit.html) et [`klist`](https://web.mit.edu/kerberos/krb5-1.12/doc/user/user_commands/klist.html) pour tester la connectivité entre le serveur GitLab et le serveur Kerberos. La méthode d'installation dépend de votre système d'exploitation.

Utilisez `klist` pour afficher les noms de principal de service (SPN) disponibles dans votre fichier `keytab` ainsi que le type de chiffrement pour chaque SPN :

```shell
klist -ke /etc/http.keytab
```

Sur un serveur Ubuntu, la sortie ressemblerait à ce qui suit :

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

Utilisez `kinit` en mode verbeux pour tester si GitLab peut utiliser le fichier keytab pour se connecter au serveur Kerberos :

```shell
KRB5_TRACE=/dev/stdout kinit -kt /etc/http.keytab HTTP/my.gitlab.domain@MY.REALM
```

Cette commande affiche une sortie détaillée du processus d'authentification.

## Mécanisme GSSAPI non pris en charge {#unsupported-gssapi-mechanism}

Avec l'authentification Kerberos SPNEGO, le navigateur est censé envoyer à GitLab une liste des mécanismes qu'il prend en charge. S'il ne prend en charge aucun des mécanismes pris en charge par GitLab, l'authentification échoue avec un message similaire à celui-ci dans le journal :

```plaintext
OmniauthKerberosController: failed to process Negotiate/Kerberos authentication: gss_accept_sec_context did not return GSS_S_COMPLETE: An unsupported mechanism was requested Unknown error
```

Ce message d'erreur peut avoir plusieurs causes et solutions.

### Intégration Kerberos n'utilisant pas un port dédié {#kerberos-integration-not-using-a-dedicated-port}

GitLab CI/CD ne fonctionne pas avec une instance GitLab activée pour Kerberos, sauf si l'intégration Kerberos est configurée pour [utiliser un port dédié](kerberos.md#http-git-access-with-kerberos-token-passwordless-authentication).

### Absence de connectivité entre la machine cliente et le serveur Kerberos {#lack-of-connectivity-between-client-machine-and-kerberos-server}

Ce problème survient généralement lorsque le navigateur ne peut pas contacter directement le serveur Kerberos. Il se rabat sur un mécanisme non pris en charge connu sous le nom de [`IAKERB`](https://k5wiki.kerberos.org/wiki/Projects/IAKERB), qui tente d'utiliser le serveur GitLab comme intermédiaire vers le serveur Kerberos.

Si vous rencontrez cette erreur, vérifiez qu'il existe bien une connectivité entre la machine cliente et le serveur Kerberos — il s'agit d'un prérequis ! Le trafic peut être bloqué par un pare-feu, ou les enregistrements DNS peuvent être incorrects.

### Erreur `GitLab DNS record is a CNAME record` {#gitlab-dns-record-is-a-cname-record-error}

Kerberos échoue avec cette erreur lorsque GitLab est référencé avec un enregistrement `CNAME`. Pour résoudre ce problème, vérifiez que l'enregistrement DNS pour GitLab est un enregistrement `A`.

### Enregistrements DNS directs et inverses non concordants pour le nom d'hôte de l'instance GitLab {#mismatched-forward-and-reverse-dns-records-for-gitlab-instance-hostname}

Un autre mode de défaillance survient lorsque les enregistrements DNS directs et inverses du serveur GitLab ne correspondent pas. Souvent, les clients Windows fonctionnent dans ce cas, tandis que les clients Linux échouent. Ils utilisent le DNS inversé lors de la détection du domaine Kerberos. S'ils obtiennent le mauvais domaine, les mécanismes Kerberos ordinaires échouent, et le client se rabat alors sur une tentative de négociation de `IAKERB`, ce qui conduit au message d'erreur d'authentification précédent.

Pour corriger ce problème, vérifiez que les DNS directs et inverses de votre serveur GitLab correspondent. Par exemple, si vous accédez à GitLab via `gitlab.example.com`, résolu en adresse IP `10.0.2.2`, alors `2.2.0.10.in-addr.arpa` doit être un enregistrement `PTR` pour `gitlab.example.com`.

### Bibliothèques Kerberos manquantes sur le navigateur ou la machine cliente {#missing-kerberos-libraries-on-browser-or-client-machine}

Enfin, il est possible que le navigateur ou la machine cliente ne dispose d'aucune prise en charge de Kerberos. Vérifiez que les bibliothèques Kerberos sont installées et que vous pouvez vous authentifier auprès d'autres services Kerberos.

## HTTP Basic : accès refusé lors du clonage {#http-basic-access-denied-when-cloning}

```shell
remote: HTTP Basic: Access denied
fatal: Authentication failed for '<KRB5 path>'
```

Si vous utilisez Git v2.11 ou une version ultérieure et que vous voyez l'erreur précédente lors du clonage, vous pouvez définir l'option Git `http.emptyAuth` sur `true` pour résoudre ce problème :

```shell
git config --global http.emptyAuth true
```

## Clonage Git avec Kerberos via HTTPS proxysé {#git-cloning-with-kerberos-over-proxied-https}

Vous devez commenter ce qui suit si :

- Vous voyez des URL `http://` dans les options **Clone with KRB5 Git Cloning**, alors que des URL `https://` sont attendues.
- HTTPS n'est pas terminé au niveau de votre instance GitLab, mais est au contraire proxysé par votre équilibreur de charge ou votre gestionnaire de trafic local.

```shell
# gitlab_rails['kerberos_https'] = false
```

Voir aussi : [Notes de release de Git v2.11](https://github.com/git/git/blob/master/Documentation/RelNotes/2.11.0.adoc?plain=1#L482-L486)

## Liens utiles {#helpful-links}

- <https://help.ubuntu.com/community/Kerberos>
- <https://blog.manula.org/2012/04/setting-up-kerberos-server-with-debian.html>
- <https://www.roguelynn.com/words/explain-like-im-5-kerberos/>
