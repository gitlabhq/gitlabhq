---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tâches Rake SMTP
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les éléments suivants sont des tâches Rake liées à SMTP.

## Secrets {#secrets}

GitLab peut utiliser des secrets de configuration SMTP pour lire à partir d'un fichier chiffré. Les tâches Rake suivantes sont fournies pour mettre à jour le contenu du fichier chiffré.

### Afficher le secret {#show-secret}

Afficher le contenu des secrets SMTP actuels.

- Installations avec le paquet Linux :

  ```shell
  sudo gitlab-rake gitlab:smtp:secret:show
  ```

- Installations auto-compilées :

  ```shell
  bundle exec rake gitlab:smtp:secret:show RAILS_ENV=production
  ```

**Exemple de sortie** :

```plaintext
password: '123'
user_name: 'gitlab-inst'
```

### Modifier le secret {#edit-secret}

Ouvre le contenu du secret dans votre éditeur et écrit le contenu résultant dans le fichier secret chiffré lorsque vous quittez.

- Installations avec le paquet Linux :

  ```shell
  sudo gitlab-rake gitlab:smtp:secret:edit EDITOR=vim
  ```

- Installations auto-compilées :

  ```shell
  bundle exec rake gitlab:smtp:secret:edit RAILS_ENV=production EDITOR=vim
  ```

### Écrire le secret brut {#write-raw-secret}

Écrivez le nouveau contenu du secret en le fournissant sur `STDIN`.

- Installations avec le paquet Linux :

  ```shell
  echo -e "password: '123'" | sudo gitlab-rake gitlab:smtp:secret:write
  ```

- Installations auto-compilées :

  ```shell
  echo -e "password: '123'" | bundle exec rake gitlab:smtp:secret:write RAILS_ENV=production
  ```

### Exemples de secrets {#secrets-examples}

**Exemple d'éditeur**

La tâche d'écriture peut être utilisée dans les cas où la commande de modification ne fonctionne pas avec votre éditeur :

```shell
# Write the existing secret to a plaintext file
sudo gitlab-rake gitlab:smtp:secret:show > smtp.yaml
# Edit the smtp file in your editor
...
# Re-encrypt the file
cat smtp.yaml | sudo gitlab-rake gitlab:smtp:secret:write
# Remove the plaintext file
rm smtp.yaml
```

**Exemple d'intégration KMS**

Elle peut également être utilisée comme application réceptrice pour du contenu chiffré avec un KMS :

```shell
gcloud kms decrypt --key my-key --keyring my-test-kms --plaintext-file=- --ciphertext-file=my-file --location=us-west1 | sudo gitlab-rake gitlab:smtp:secret:write
```

**Exemple d'intégration de secrets Google Cloud**

Elle peut également être utilisée comme application réceptrice pour les secrets provenant de Google Cloud :

```shell
gcloud secrets versions access latest --secret="my-test-secret" > $1 | sudo gitlab-rake gitlab:smtp:secret:write
```
