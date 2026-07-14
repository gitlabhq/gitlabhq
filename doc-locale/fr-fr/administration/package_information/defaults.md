---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Valeurs par défaut du package
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Sauf si une configuration est spécifiée dans le fichier `/etc/gitlab/gitlab.rb`, le package utilise les valeurs par défaut indiquées ci-dessous.

## Ports {#ports}

Consultez le tableau ci-dessous pour obtenir la liste des ports que le package Linux assigne par défaut :

| Composant                 | Activé par défaut | Communique via | Alternative   | Port de connexion |
|:-------------------------:|:-------------:|:----------------:|:-------------:|:----------------|
| GitLab Rails              | Oui           | Port             |               | `80` ou `443`   |
| GitLab Shell              | Oui           | Port             |               | `22`            |
| PostgreSQL                | Oui           | Socket           | Port (`5432`) |                 |
| Redis                     | Oui           | Socket           | Port (`6379`) |                 |
| Puma                      | Oui           | Socket           | Port (`8080`) |                 |
| GitLab Workhorse          | Oui           | Socket           | Port (`8181`) |                 |
| Statut NGINX              | Oui           | Port             |               | `8060`          |
| Prometheus                | Oui           | Port             |               | `9090`          |
| Exportateur de nœud             | Oui           | Port             |               | `9100`          |
| Exportateur Redis            | Oui           | Port             |               | `9121`          |
| Exportateur PostgreSQL       | Oui           | Port             |               | `9187`          |
| Exportateur PgBouncer        | Non            | Port             |               | `9188`          |
| Exportateur GitLab           | Oui           | Port             |               | `9168`          |
| Exportateur Sidekiq          | Oui           | Port             |               | `8082`          |
| Contrôle de santé Sidekiq      | Oui           | Port             |               | `8092` <sup>1</sup> |
| Exportateur Web              | Non            | Port             |               | `8083`          |
| Geo PostgreSQL            | Non            | Socket           | Port (`5431`) |                 |
| Redis Sentinel            | Non            | Port             |               | `26379`         |
| E-mail entrant            | Non            | Port             |               | `143`           |
| Elastic search            | Non            | Port             |               | `9200`          |
| GitLab Pages              | Non            | Port             |               | `80` ou `443`   |
| GitLab Registry           | Non*           | Port             |               | `80`, `443` ou `5050` |
| GitLab Registry           | Non            | Port             |               | `5000`          |
| LDAP                      | Non            | Port             |               | Dépend de la configuration du composant |
| Kerberos                  | Non            | Port             |               | `8443` ou `8088` |
| OmniAuth                  | Oui           | Port             |               | Dépend de la configuration du composant |
| SMTP                      | Non            | Port             |               | `465`           |
| Syslog distant             | Non            | Port             |               | `514`           |
| Mattermost                | Non            | Port             |               | `8065`          |
| Mattermost                | Non            | Port             |               | `80` ou `443`   |
| PgBouncer                 | Non            | Port             |               | `6432`          |
| Consul                    | Non            | Port             |               | `8300`, `8301`(TCP et UDP), `8500`, `8600` <sup>2</sup> |
| Patroni                   | Non            | Port             |               | `8008`          |
| GitLab KAS                | Oui           | Port             |               | `8150`          |
| Gitaly                    | Oui           | Socket           | Port (`8075`) | `8075` ou `9999` (TLS) |
| Exportateur Gitaly           | Oui           | Port             |               | `9236`          |
| Praefect                  | Non            | Port             |               | `2305` ou `3305` (TLS) |
| Exportateur GitLab Workhorse | Oui           | Port             |               | `9229`          |
| Exportateur Registry         | Non            | Port             |               | `5001`          |

**Footnotes** :

1. Si les paramètres de contrôle de santé Sidekiq ne sont pas définis, ils utilisent par défaut les paramètres de l'exportateur de métriques Sidekiq. Cette valeur par défaut est dépréciée et doit être supprimée dans [GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/347509).
1. Si vous utilisez des fonctionnalités Consul supplémentaires, il peut être nécessaire d'ouvrir davantage de ports. Consultez la [documentation officielle](https://developer.hashicorp.com/consul/docs/install/ports#ports-table) pour obtenir la liste.

Légende :

- `Component` - Nom du composant.
- `On by default` - Indique si le composant est en cours d'exécution par défaut.
- `Communicates via` - Comment le composant communique avec les autres composants.
- `Alternative` - Indique s'il est possible de configurer le composant pour utiliser un type de communication différent. Le type est répertorié avec le port par défaut utilisé dans ce cas.
- `Connection port` - Port sur lequel le composant communique.

GitLab s'attend également à ce qu'un système de fichiers soit prêt pour le stockage des dépôts Git et de divers autres fichiers.

Si vous utilisez NFS (Network File System), les fichiers sont transportés sur un réseau, ce qui nécessite, selon l'implémentation, que les ports `111` et `2049` soient ouverts.

> [!note]
> Dans certains cas, le GitLab Registry est automatiquement activé par défaut. Pour plus d'informations, consultez [l'administration du registre de conteneurs GitLab](../packages/container_registry.md).
