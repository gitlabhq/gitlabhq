---
type: reference, howto
---

# Threat Monitoring **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/14707) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.9.

The **Threat Monitoring** page provides metrics for the GitLab
application runtime security features. You can access these metrics by
navigating to your project's **Security & Compliance > Threat Monitoring** page.

GitLab supports statistics for the following security features:

- [Web Application Firewall](../../clusters/applications.md#web-application-firewall-modsecurity)

## Web Application Firewall

The Web Application Firewall section provides metrics for the NGINX
Ingress controller and ModSecurity firewall. This section has the
following prerequisites:

- Project has to have at least one [environment](../../../ci/environments.md).
- [Web Application Firewall](../../clusters/applications.md#web-application-firewall-modsecurity) has to be enabled.
- [Elastic Stack](../../clusters/applications.md#web-application-firewall-modsecurity) has to be installed.

If you are using custom Helm values for the Elastic Stack you have to
configure Filebeat similarly to the [vendored values](https://gitlab.com/gitlab-org/gitlab/-/blob/f610a080b1ccc106270f588a50cb3c07c08bdd5a/vendor/elastic_stack/values.yaml).

The **Web Application Firewall** section displays the following information
about your Ingress traffic:

- The total amount of requests to your application
- The proportion of traffic that is considered anomalous according to
  the configured rules
- The request breakdown graph for the selected time interval

If a significant percentage of traffic is anomalous, you should
investigate it for potential threats by
[examining the application logs](../../clusters/applications.md#web-application-firewall-modsecurity).
