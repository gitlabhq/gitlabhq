---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: Monitor application performance and troubleshoot performance issues.
ignore_in_report: true
title: Troubleshooting Observability
---


{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

When working with Observability, you might encounter the following issues.

## GitLab Observability instance issues

Check container status:

```shell
docker ps
```

View container logs:

```shell
docker logs [container_name]
```

## Menu doesn't appear

1. Check that the Observability service URL is configured for your group:

   ```ruby
   group = Group.find_by_path('your-group-name')
   group.observability_group_o11y_setting&.o11y_service_url
   ```

1. Ensure the routes are properly registered:

   ```ruby
   Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?('observability') }.map(&:path)
   ```

## Performance issues

If experiencing SSH connection issues or poor performance:

- Verify instance type meets minimum requirements (2 vCPU, 8 GB RAM).
- Consider resizing to a larger instance type.
- Check disk space and increase if needed.

## Telemetry doesn't show up

If your telemetry data isn't appearing in GitLab Observability:

1. Verify ports 4317 and 4318 are open in your security group.
1. Test connectivity with:

   ```shell
   nc -zv [your-o11y-instance-ip] 4317
   nc -zv [your-o11y-instance-ip] 4318
   ```

1. Check container logs for any errors:

   ```shell
   docker logs otel-collector-standard
   docker logs o11y-otel-collector
   docker logs o11y
   ```

1. Try using the HTTP endpoint (4318) instead of gRPC (4317).
1. Add more debugging information to your OpenTelemetry setup.
