---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Tâches Rake LDAP
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les éléments suivants sont des tâches Rake liées à LDAP.

## Vérification {#check}

La tâche Rake de vérification LDAP teste les identifiants `bind_dn` et `password` (si configurés) et liste un échantillon d'utilisateurs LDAP. Cette tâche est également exécutée dans le cadre de la tâche `gitlab:check`, mais peut être exécutée indépendamment à l'aide de la commande ci-dessous.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:check
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:check
```

{{< /tab >}}

{{< /tabs >}}

Par défaut, la tâche renvoie un échantillon de 100 utilisateurs LDAP. Modifiez cette limite en transmettant un nombre à la tâche de vérification :

```shell
rake gitlab:ldap:check[50]
```

## Exécuter une synchronisation de groupe {#run-a-group-sync}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

La tâche suivante exécute immédiatement une [synchronisation de groupe](../auth/ldap/ldap_synchronization.md#group-sync). Cela est utile lorsque vous souhaitez mettre à jour toutes les appartenances aux groupes configurés dans LDAP sans attendre la prochaine synchronisation de groupe planifiée.

> [!note]
> Si vous souhaitez modifier la fréquence à laquelle une synchronisation de groupe est effectuée, [ajustez le planning cron](../auth/ldap/ldap_synchronization.md#adjust-ldap-sync-schedule) à la place.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:group_sync
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:group_sync
```

{{< /tab >}}

{{< /tabs >}}

## Renommer un fournisseur {#rename-a-provider}

Si vous modifiez l'ID du serveur LDAP dans `gitlab.yml` ou `gitlab.rb`, vous devez mettre à jour toutes les identités des utilisateurs, faute de quoi ceux-ci ne pourront pas se connecter. Saisissez l'ancien et le nouveau fournisseur, et cette tâche met à jour toutes les identités correspondantes dans la base de données.

`old_provider` et `new_provider` sont dérivés du préfixe `ldap` suivi de l'ID du serveur LDAP issu du fichier de configuration. Par exemple, dans `gitlab.yml` ou `gitlab.rb`, vous pouvez voir une configuration LDAP comme celle-ci :

```yaml
main:
  label: 'LDAP'
  host: '_your_ldap_server'
  port: 389
  uid: 'sAMAccountName'
  # ...
```

`main` est l'ID du serveur LDAP. Ensemble, le fournisseur unique est `ldapmain`.

> [!warning]
> Si vous saisissez un nouveau fournisseur incorrect, les utilisateurs ne pourront pas se connecter. Si cela se produit, exécutez à nouveau la tâche en utilisant le fournisseur incorrect comme `old_provider` et le fournisseur correct comme `new_provider`.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[old_provider,new_provider]
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:rename_provider[old_provider,new_provider]
```

{{< /tab >}}

{{< /tabs >}}

### Exemple {#example}

Supposons que vous commenciez avec l'ID de serveur par défaut `main` (fournisseur complet `ldapmain`). Si nous remplaçons `main` par `mycompany`, le `new_provider` devient `ldapmycompany`. Pour renommer toutes les identités des utilisateurs, exécutez la commande suivante :

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[ldapmain,ldapmycompany]
```

Exemple de sortie :

```plaintext
100 users with provider 'ldapmain' will be updated to 'ldapmycompany'.
If the new provider is incorrect, users will be unable to sign in.
Do you want to continue (yes/no)? yes

User identities were successfully updated
```

### Autres options {#other-options}

Si vous ne spécifiez pas de `old_provider` et de `new_provider`, la tâche vous les demande :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:rename_provider
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:rename_provider
```

{{< /tab >}}

{{< /tabs >}}

**Exemple de sortie** :

```plaintext
What is the old provider? Ex. 'ldapmain': ldapmain
What is the new provider? Ex. 'ldapcustom': ldapmycompany
```

Cette tâche accepte également la variable d'environnement `force`, qui ignore la boîte de dialogue de confirmation :

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[old_provider,new_provider] force=yes
```

## Secrets {#secrets}

GitLab peut utiliser les [secrets de configuration LDAP](../auth/ldap/_index.md#use-encrypted-credentials) pour lire à partir d'un fichier chiffré. Les tâches Rake suivantes sont fournies pour mettre à jour le contenu du fichier chiffré.

### Afficher le secret {#show-secret}

Affichez le contenu des secrets LDAP actuels.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:secret:show
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:secret:show
```

{{< /tab >}}

{{< /tabs >}}

**Exemple de sortie** :

```plaintext
main:
  password: '123'
  bind_dn: 'gitlab-adm'
```

### Modifier le secret {#edit-secret}

Ouvre le contenu du secret dans votre éditeur, et écrit le contenu résultant dans le fichier secret chiffré lorsque vous quittez.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:secret:edit EDITOR=vim
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
sudo RAILS_ENV=production EDITOR=vim -u git -H bundle exec rake gitlab:ldap:secret:edit
```

{{< /tab >}}

{{< /tabs >}}

### Écrire le secret brut {#write-raw-secret}

Écrivez le nouveau contenu du secret en le fournissant via STDIN.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
echo -e "main:\n  password: '123'" | sudo gitlab-rake gitlab:ldap:secret:write
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
echo -e "main:\n  password: '123'" | sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:secret:write
```

{{< /tab >}}

{{< /tabs >}}

### Exemples de secrets {#secrets-examples}

- Exemple avec un éditeur :

  La tâche d'écriture peut être utilisée dans les cas où la commande d'édition ne fonctionne pas avec votre éditeur :

  ```shell
  # Write the existing secret to a plaintext file
  sudo gitlab-rake gitlab:ldap:secret:show > ldap.yaml
  # Edit the ldap file in your editor
  ...
  # Re-encrypt the file
  cat ldap.yaml | sudo gitlab-rake gitlab:ldap:secret:write
  # Remove the plaintext file
  rm ldap.yaml
  ```

- Exemple d'intégration KMS :

  Elle peut également être utilisée comme application réceptrice pour du contenu chiffré avec un KMS :

  ```shell
  gcloud kms decrypt --key my-key --keyring my-test-kms --plaintext-file=- --ciphertext-file=my-file --location=us-west1 | sudo gitlab-rake gitlab:ldap:secret:write
  ```

- Exemple d'intégration de secrets Google Cloud :

  Elle peut également être utilisée comme application réceptrice pour des secrets provenant de Google Cloud :

  ```shell
  gcloud secrets versions access latest --secret="my-test-secret" > $1 | sudo gitlab-rake gitlab:ldap:secret:write
  ```
