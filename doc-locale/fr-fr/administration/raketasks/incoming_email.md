---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tâches Rake pour les e-mails entrants
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108279) dans GitLab 15.9.

{{< /history >}}

Les éléments suivants sont des tâches Rake liées aux e-mails entrants.

## Secrets {#secrets}

GitLab peut utiliser les secrets [d'e-mail entrant](../incoming_email.md) lus depuis un fichier chiffré au lieu de les stocker en texte brut dans le système de fichiers. Les tâches Rake suivantes sont fournies pour mettre à jour le contenu du fichier chiffré.

### Afficher le secret {#show-secret}

Afficher le contenu des secrets d'e-mail entrant actuels.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:incoming_email:secret:show
```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

Utilisez un secret Kubernetes pour stocker le mot de passe des e-mails entrants. Pour plus d'informations, consultez la page sur les [secrets Helm IMAP](https://docs.gitlab.com/charts/installation/secrets/#imap-password-for-incoming-emails).

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
sudo docker exec -t <container name> gitlab:incoming_email:secret:show
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake gitlab:incoming_email:secret:show RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

#### Exemple de sortie {#example-output}

```plaintext
password: 'examplepassword'
user: 'incoming-email@mail.example.com'
```

### Modifier le secret {#edit-secret}

Ouvre le contenu du secret dans votre éditeur et écrit le contenu résultant dans le fichier secret chiffré lorsque vous quittez.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:incoming_email:secret:edit EDITOR=vim
```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

Utilisez un secret Kubernetes pour stocker le mot de passe des e-mails entrants. Pour plus d'informations, consultez la page sur les [secrets Helm IMAP](https://docs.gitlab.com/charts/installation/secrets/#imap-password-for-incoming-emails).

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
sudo docker exec -t <container name> gitlab:incoming_email:secret:edit EDITOR=editor
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake gitlab:incoming_email:secret:edit RAILS_ENV=production EDITOR=vim
```

{{< /tab >}}

{{< /tabs >}}

### Écrire un secret brut {#write-raw-secret}

Écrivez le nouveau contenu du secret en le fournissant via `STDIN`.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
echo -e "password: 'examplepassword'" | sudo gitlab-rake gitlab:incoming_email:secret:write
```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

Utilisez un secret Kubernetes pour stocker le mot de passe des e-mails entrants. Pour plus d'informations, consultez la page sur les [secrets Helm IMAP](https://docs.gitlab.com/charts/installation/secrets/#imap-password-for-incoming-emails).

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
sudo docker exec -t <container name> /bin/bash
echo -e "password: 'examplepassword'" | gitlab-rake gitlab:incoming_email:secret:write
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
echo -e "password: 'examplepassword'" | bundle exec rake gitlab:incoming_email:secret:write RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

### Exemples de secrets {#secrets-examples}

**Exemple d'éditeur**

La tâche d'écriture peut être utilisée dans les cas où la commande de modification ne fonctionne pas avec votre éditeur :

```shell
# Write the existing secret to a plaintext file
sudo gitlab-rake gitlab:incoming_email:secret:show > incoming_email.yaml
# Edit the incoming_email file in your editor
...
# Re-encrypt the file
cat incoming_email.yaml | sudo gitlab-rake gitlab:incoming_email:secret:write
# Remove the plaintext file
rm incoming_email.yaml
```

**Exemple d'intégration KMS**

Elle peut également être utilisée comme application réceptrice pour du contenu chiffré avec un KMS :

```shell
gcloud kms decrypt --key my-key --keyring my-test-kms --plaintext-file=- --ciphertext-file=my-file --location=us-west1 | sudo gitlab-rake gitlab:incoming_email:secret:write
```

**Exemple d'intégration de secrets Google Cloud**

Elle peut également être utilisée comme application réceptrice pour des secrets provenant de Google Cloud :

```shell
gcloud secrets versions access latest --secret="my-test-secret" > $1 | sudo gitlab-rake gitlab:incoming_email:secret:write
```
