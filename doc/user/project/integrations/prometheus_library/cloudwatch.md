---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Monitoring AWS resources **(FREE)**

GitLab supports automatically detecting and monitoring AWS resources, starting
with the [Elastic Load Balancer](https://aws.amazon.com/elasticloadbalancing/) (ELB).
This is provided by leveraging the official [Cloudwatch exporter](https://github.com/prometheus/cloudwatch_exporter), which translates [Cloudwatch metrics](https://aws.amazon.com/cloudwatch/) into
a Prometheus readable form.

## Requirements

You must enable the [Prometheus service](../prometheus.md).

## Supported metrics

| Name                 | Query |
|----------------------|-------|
| Throughput (req/sec) | `sum(aws_elb_request_count_sum{%{environment_filter}}) / 60` |
| Latency (ms)         | `avg(aws_elb_latency_average{%{environment_filter}}) * 1000` |
| HTTP Error Rate (%)  | `sum(aws_elb_httpcode_backend_5_xx_sum{%{environment_filter}}) / sum(aws_elb_request_count_sum{%{environment_filter}})` |

## Configuring Prometheus to monitor for Cloudwatch metrics

To get started with Cloudwatch monitoring, install and configure the
[Cloudwatch exporter](https://github.com/prometheus/cloudwatch_exporter). The
Cloudwatch exporter retrieves and parses the specified Cloudwatch metrics, and
translates them into a Prometheus monitoring endpoint.

The only supported AWS resource is the Elastic Load Balancer, whose Cloudwatch
metrics are listed in [this AWS documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-cloudwatch-metrics.html).

You can [download a sample Cloudwatch Exporter configuration file](../samples/cloudwatch.yml)
that's configured for basic AWS ELB monitoring.

## Specifying the Environment label

To isolate and display only the relevant metrics for a given environment,
GitLab needs a method to detect which labels are associated. To do this, GitLab
[looks for an `environment` label](index.md#identifying-environments).
