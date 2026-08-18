---
stage: Runtime
group: Cells Infrastructure
info: Any user with the Maintainer or Owner role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Cells
description: "Configurez et testez la fonctionnalité GitLab Cells pour les administrateurs de GitLab.com dans le cadre de tests de fonctionnalité, notamment en activant les instances Cell et en configurant les clients du service de topologie."
---

{{< details >}}

- Offre : GitLab.com
- Statut : Expérimentation

{{< /details >}}

> [!disclaimer]

Pour tester la fonctionnalité des cellules, configurez la console GitLab Rails.

> [!note]
> Cette fonctionnalité est disponible uniquement pour les administrateurs de GitLab.com. Cette fonctionnalité n'est pas disponible pour les instances GitLab Self-Managed ou GitLab Dedicated.
>
> Cells 1.0 est en cours de développement. Pour plus d'informations sur l'état du développement des cellules, consultez [epic 12383](https://gitlab.com/groups/gitlab-org/-/epics/12383).

## Configuration {#configuration}

Pour configurer votre instance GitLab en tant qu'instance Cell :

{{< tabs >}}

{{< tab title="Self-compiled (source)" >}}

La configuration liée aux cellules dans `config/gitlab.yml` est au format suivant :

```yaml
  cell:
    enabled: true
    id: 1
    database:
      skip_sequence_alteration: false
    topology_service_client:
      address: topology-service.gitlab.example.com:443
      ca_file: /home/git/gitlab/config/topology-service-ca.pem
      certificate_file: /home/git/gitlab/config/topology-service-cert.pem
      private_key_file: /home/git/gitlab/config/topology-service-key.pem
```

{{< /tab >}}

{{< tab title="Package Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez les lignes suivantes :

   ```ruby
   gitlab_rails['cell'] = {
     enabled: true,
     id: 1,
     database: {
       skip_sequence_alteration: false
     },
     topology_service_client: {
       enabled: true,
       address: 'topology-service.gitlab.example.com:443',
       ca_file: 'path/to/your/ca/.pem',
       certificate_file: 'path/to/your/cert/.pem',
       private_key_file: 'path/to/your/key/.pem'
     }
   }
   ```

1. Reconfigurez et redémarrez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

{{< /tab >}}

{{< tab title="Chart Helm" >}}

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       cell:
         enabled: true
         id: 1
         database:
           skipSequenceAlteration: false
         topologyServiceClient:
           address: "topology-service.gitlab.example.com:443"
           tls:
             enabled: true
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

| Configuration                                   | Valeur par défaut                                         | Description                                                                                                                                                                                                                                                                                                                    |
|-------------------------------------------------|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `cell.enabled`                                  | `false`                                               | Permet de configurer si l'instance est une Cell ou non. `false` signifie que toutes les fonctionnalités Cell sont désactivées. `session_cookie_prefix_token` n'est pas affecté et peut être défini séparément.                                                                                                                                                    |
| `cell.id`                                       | `nil`                                                 | Doit être un entier positif lorsque `cell.enabled` est `true`. Sinon, il doit être `nil`. Il s'agit de l'identifiant entier unique de la cellule dans un cluster. Cet ID est utilisé dans les jetons routables. Lorsque `cell.id` est `nil`, les autres attributs dans les jetons routables, comme `organization_id`, seront quand même utilisés |
| `cell.database.skip_sequence_alteration`        | `false`                                               | Lorsque `true`, ignore l'altération des séquences de base de données pour la cellule. À activer pour la cellule héritée (`cell-1`) avant que la cellule monolithe ne soit disponible, suivi dans cet epic : [Phase 6 : Cellule monolithe](https://gitlab.com/groups/gitlab-org/-/epics/14513).                                                                   |
| `cell.topology_service_client.address`          | `"topology-service.gitlab.example.com:443"`           | Requis lorsque `cell.enabled` est `true`. Adresse et port du serveur de service de topologie.                                                                                                                                                                                                                                       |
| `cell.topology_service_client.tls.enabled`      | `true`                                                | Lorsque `true`, active mTLS pour la communication avec le service de topologie. Cela nécessite que `cell.topology_service_client.tls.secret` soit correctement configuré. Si défini sur `false`, la connexion sera établie sans chiffrement TLS.                                                                                           |
| `cell.topology_service_client.tls.secret`       | `nil`                                                 | Nom du [secret TLS Kubernetes](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_secret_tls/) qui contient les identifiants mTLS. Requis lorsque TLS est activé. Le secret doit inclure les clés `tls.crt` et `tls.key`. S'il n'est pas explicitement défini, la valeur par défaut est `<release.name>-topology-tls`. Ce secret **doit être créé manuellement** ; le chart Helm ne le crée pas automatiquement.                |

## Configuration associée {#related-configuration}

Pour plus d'informations sur la configuration des autres composants de l'architecture cells, consultez :

1. [Configuration du service de topologie](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/main/docs/config.md?ref_type=heads)
1. [Configuration du routeur HTTP](https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/docs/config.md?ref_type=heads)
