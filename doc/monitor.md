# Monitor

Measure how long it takes to go from planning to monitoring and ensure your
applications are always responsive and available. GitLab collects and displays
performance metrics for deployed apps using Prometheus so you can know in an
instant how code changes impact your production environment.

- [GitLab Prometheus](administration/monitoring/prometheus/index.md): Configure the bundled Prometheus to collect various metrics from your GitLab instance.
- [Prometheus project integration](user/project/integrations/prometheus.md): Configure the Prometheus integration per project and monitor your CI/CD environments.
- [Prometheus metrics](user/project/integrations/prometheus_library/metrics.md): Let Prometheus collect metrics from various services, like Kubernetes, NGINX, NGINX ingress controller, HAProxy, and Amazon Cloud Watch.
- [GitLab Performance Monitoring](administration/monitoring/performance/index.md): Use InfluxDB and Grafana to monitor the performance of your GitLab instance (will be eventually replaced by Prometheus).
- [Health check](user/admin_area/monitoring/health_check.md): GitLab provides liveness and readiness probes to indicate service health and reachability to required services.
- [GitLab Cycle Analytics](user/project/cycle_analytics.md): Cycle Analytics measures the time it takes to go from an
  [idea to production](https://about.gitlab.com/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/#from-idea-to-production-with-gitlab) for each project you have.
