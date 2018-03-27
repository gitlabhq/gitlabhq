# Monitoring AWS Resources

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/12621) in GitLab 9.4

GitLab has support for automatically detecting and monitoring AWS resources, starting with the [Elastic Load Balancer](https://aws.amazon.com/elasticloadbalancing/). This is provided by leveraging the official [Cloudwatch exporter](https://github.com/prometheus/cloudwatch_exporter), which translates [Cloudwatch metrics](https://aws.amazon.com/cloudwatch/) into a Prometheus readable form.

## Requirements

The [Prometheus service](../prometheus/index.md) must be enabled.

## Metrics supported

| Name | Query |
| ---- | ----- |
| Throughput (req/sec) | sum(aws_elb_request_count_sum{%{environment_filter}}) / 60 |
| Latency (ms) | avg(aws_elb_latency_average{%{environment_filter}}) * 1000 |
| HTTP Error Rate (%) | sum(aws_elb_httpcode_backend_5_xx_sum{%{environment_filter}}) / sum(aws_elb_request_count_sum{%{environment_filter}}) |

## Configuring Prometheus to monitor for Cloudwatch metrics

To get started with Cloudwatch monitoring, you should install and configure the [Cloudwatch exporter](https://github.com/hnlq715/nginx-vts-exporter) which retrieves and parses the specified Cloudwatch metrics and translates them into a Prometheus monitoring endpoint.

Right now, the only AWS resource supported is the Elastic Load Balancer, whose Cloudwatch metrics can be found [here](http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-cloudwatch-metrics.html).

A sample Cloudwatch Exporter configuration file, configured for basic AWS ELB monitoring, is [available for download](../samples/cloudwatch.yml).

## Specifying the Environment label

In order to isolate and only display relevant metrics for a given environment
however, GitLab needs a method to detect which labels are associated. To do this, GitLab will [look for an `environment` label](metrics.md#identifying-environments).
