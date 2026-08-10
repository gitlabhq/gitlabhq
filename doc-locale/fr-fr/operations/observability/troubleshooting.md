---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: Surveillez les performances des applications et résolvez les problèmes de performance.
ignore_in_report: true
title: "Dépannage de l'Observability"
---


{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : version expérimentale

{{< /details >}}

Lorsque vous utilisez Observability, vous pouvez rencontrer les problèmes suivants.

## Problèmes d'instance GitLab Observability {#gitlab-observability-instance-issues}

Vérifiez le statut du conteneur :

```shell
docker ps
```

Affichez les logs du conteneur :

```shell
docker logs [container_name]
```

## Le menu n'apparaît pas {#menu-doesnt-appear}

1. Vérifiez que l'URL du service Observability est configurée pour votre groupe :

   ```ruby
   group = Group.find_by_path('your-group-name')
   group.observability_group_o11y_setting&.o11y_service_url
   ```

1. Assurez-vous que les routes sont correctement enregistrées :

   ```ruby
   Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?('observability') }.map(&:path)
   ```

## Problèmes de performance {#performance-issues}

Si vous rencontrez des problèmes de connexion SSH ou de mauvaises performances :

- Vérifiez que le type d'instance répond aux exigences minimales (2 vCPU, 8 Go de RAM).
- Envisagez de redimensionner vers un type d'instance plus grand.
- Vérifiez l'espace disque et augmentez-le si nécessaire.

## La télémétrie n'apparaît pas {#telemetry-doesnt-show-up}

Si vos données de télémétrie n'apparaissent pas dans GitLab Observability :

1. Vérifiez que les ports 4317 et 4318 sont ouverts dans votre groupe de sécurité.
1. Testez la connectivité avec :

   ```shell
   nc -zv [your-o11y-instance-ip] 4317
   nc -zv [your-o11y-instance-ip] 4318
   ```

1. Vérifiez les logs du conteneur pour détecter d'éventuelles erreurs :

   ```shell
   docker logs otel-collector-standard
   docker logs o11y-otel-collector
   docker logs o11y
   ```

1. Essayez d'utiliser le point de terminaison HTTP (4318) au lieu de gRPC (4317).
1. Ajoutez des informations de débogage supplémentaires à votre configuration OpenTelemetry.
