---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tâches Rake pour les e-mails du Service Desk
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108279) dans GitLab 15.9.

{{< /history >}}

Les éléments suivants sont des tâches Rake liées aux e-mails du Service Desk.

## Secrets {#secrets}

GitLab peut utiliser les secrets d'[e-mail du Service Desk](../../user/project/service_desk/configure.md#configure-service-desk-alias-email) lus depuis un fichier chiffré au lieu de les stocker en texte brut dans le système de fichiers. Les tâches Rake suivantes sont fournies pour mettre à jour le contenu du fichier chiffré.

### Afficher le secret {#show-secret}

Affiche le contenu des secrets d'e-mail du Service Desk actuels.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:service_desk_email:secret:show
```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

Utilisez un secret Kubernetes pour stocker le mot de passe de l'e-mail du Service Desk. Pour plus d'informations, consultez la page sur les [secrets IMAP Helm](https://docs.gitlab.com/charts/installation/secrets/#imap-password-for-service-desk-emails).

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
sudo docker exec -t <container name> gitlab:service_desk_email:secret:show
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake gitlab:service_desk_email:secret:show RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

#### Exemple de sortie {#example-output}

```plaintext
password: 'examplepassword'
user: 'service-desk-email@mail.example.com'
```

### Modifier le secret {#edit-secret}

Ouvre le contenu du secret dans votre éditeur et écrit le contenu résultant dans le fichier secret chiffré lorsque vous quittez.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:service_desk_email:secret:edit EDITOR=vim
```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

Utilisez un secret Kubernetes pour stocker le mot de passe de l'e-mail du Service Desk. Pour plus d'informations, consultez la page sur les [secrets IMAP Helm](https://docs.gitlab.com/charts/installation/secrets/#imap-password-for-service-desk-emails).

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
sudo docker exec -t <container name> gitlab:service_desk_email:secret:edit EDITOR=editor
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake gitlab:service_desk_email:secret:edit RAILS_ENV=production EDITOR=vim
```

{{< /tab >}}

{{< /tabs >}}

### Écrire le secret brut {#write-raw-secret}

Écrivez le nouveau contenu du secret en le fournissant sur `STDIN`.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
echo -e "password: 'examplepassword'" | sudo gitlab-rake gitlab:service_desk_email:secret:write
```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

Utilisez un secret Kubernetes pour stocker le mot de passe de l'e-mail du Service Desk. Pour plus d'informations, consultez la page sur les [secrets IMAP Helm](https://docs.gitlab.com/charts/installation/secrets/#imap-password-for-service-desk-emails).

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
sudo docker exec -t <container name> /bin/bash
echo -e "password: 'examplepassword'" | gitlab-rake gitlab:service_desk_email:secret:write
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
echo -e "password: 'examplepassword'" | bundle exec rake gitlab:service_desk_email:secret:write RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

### Exemples de secrets {#secrets-examples}

**Exemple d'éditeur**

La tâche d'écriture peut être utilisée dans les cas où la commande de modification ne fonctionne pas avec votre éditeur :

```shell
# Write the existing secret to a plaintext file
sudo gitlab-rake gitlab:service_desk_email:secret:show > service_desk_email.yaml
# Edit the service_desk_email file in your editor
...
# Re-encrypt the file
cat service_desk_email.yaml | sudo gitlab-rake gitlab:service_desk_email:secret:write
# Remove the plaintext file
rm service_desk_email.yaml
```

**Exemple d'intégration KMS**

Elle peut également être utilisée comme application réceptrice pour le contenu chiffré avec un KMS :

```shell
gcloud kms decrypt --key my-key --keyring my-test-kms --plaintext-file=- --ciphertext-file=my-file --location=us-west1 | sudo gitlab-rake gitlab:service_desk_email:secret:write
```

**Exemple d'intégration de secrets Google Cloud**

Elle peut également être utilisée comme application réceptrice pour les secrets provenant de Google Cloud :

```shell
gcloud secrets versions access latest --secret="my-test-secret" > $1 | sudo gitlab-rake gitlab:service_desk_email:secret:write
```
