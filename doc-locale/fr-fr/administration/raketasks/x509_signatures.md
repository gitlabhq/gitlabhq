---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tâche Rake pour les signatures X.509
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Lors de la [signature des commits avec X.509](../../user/project/repository/signed_commits/x509.md), l'ancre de confiance peut changer et les signatures stockées dans la base de données doivent être mises à jour.

## Mettre à jour toutes les signatures X.509 {#update-all-x509-signatures}

Cette tâche :

- Itère à travers tous les commits signés avec X.509.
- Met à jour leur statut de vérification en fonction du magasin de certificats actuel.
- Modifie uniquement les entrées de base de données pour les signatures.
- Laisse les commits inchangés.

Pour mettre à jour toutes les signatures X.509, exécutez :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:x509:update_signatures
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
sudo -u git -H bundle exec rake gitlab:x509:update_signatures RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec des certificats X.509, vous pouvez rencontrer les problèmes suivants.

### Erreur : `GRPC::DeadlineExceeded` lors des mises à jour de signatures {#error-grpcdeadlineexceeded-during-signature-updates}

Vous pourriez obtenir une erreur indiquant `GRPC::DeadlineExceeded` lors de la mise à jour des signatures X.509.

Ce problème survient lorsque des délais d'expiration réseau ou des problèmes de connectivité empêchent la tâche de se terminer.

Pour résoudre ce problème, la tâche effectue automatiquement jusqu'à 5 nouvelles tentatives pour chaque signature par défaut. Vous pouvez personnaliser la limite de nouvelles tentatives en définissant la variable d'environnement `GRPC_DEADLINE_EXCEEDED_RETRY_LIMIT` :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
GRPC_DEADLINE_EXCEEDED_RETRY_LIMIT=2 sudo gitlab-rake gitlab:x509:update_signatures
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
GRPC_DEADLINE_EXCEEDED_RETRY_LIMIT=2 sudo -u git -H bundle exec rake gitlab:x509:update_signatures RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}
