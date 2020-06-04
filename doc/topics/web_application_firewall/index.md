# Web Application Firewall - ModSecurity

A web application firewall (or WAF) filters, monitors, and blocks HTTP traffic to
and from a web application. By inspecting HTTP traffic, it can prevent attacks
stemming from web application security flaws. It can be used to detect SQL injection,
Cross-Site Scripting (XSS), Remote File Inclusion, Security Misconfigurations, and
much more.

## Overview

GitLab provides a WAF out of the box after Ingress is deployed.
All you need to do is deploy your application along with a service
and Ingress resource.

In GitLab's [Ingress](../../user/clusters/applications.md#ingress) deployment, the [ModSecurity](https://modsecurity.org/) module is loaded
into Ingress-NGINX by default and monitors the traffic going to the
applications which have an Ingress.

The ModSecurity module runs with the [OWASP Core Rule Set (CRS)](https://coreruleset.org/) by default. The OWASP CRS will detect and log a wide range of common attacks.

NOTE: **Note**
The WAF is deployed in "Detection-only mode" by default and will only log attack
attempts.

## Requirements

The Web Application Firewall requires:

- **Kubernetes**

  To enable the WAF, you need:

  - Kubernetes 1.12+.
  - A load balancer. You can use NGINX-Ingress by deploying it to your
    Kubernetes cluster by either:
    - Using the [`nginx-ingress` Helm chart](https://github.com/helm/charts/tree/master/stable/nginx-ingress).
    - Installing the [Ingress GitLab Managed App](../../user/clusters/applications.md#ingress) with WAF enabled.

- **Configured Kubernetes objects**

  To use the WAF on an application, you need to deploy the following Kubernetes resources:

  - [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
  - [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
  - [Ingress Resource](https://kubernetes.io/docs/concepts/services-networking/ingress/)

## Quick start

If you are using GitLab.com, see the [quick start guide](quick_start_guide.md) for
how to use the WAF with GitLab.com and a Kubernetes cluster on Google Kubernetes Engine (GKE).

If you are using a self-managed instance of GitLab, you need to configure the
[Google OAuth2 OmniAuth Provider](../../integration/google.md) before
you can configure a cluster on GKE. Once this is set up, you can follow the steps on the [quick start guide](quick_start_guide.md) to get started.

NOTE: **Note**
This guide shows how the WAF can be deployed using Auto DevOps. The WAF
is available by default to all applications no matter how they are deployed,
as long as they are using Ingress.

## Network firewall vs. Web Application Firewall

A network firewall or packet filter looks at traffic at the Network (L3) and Transport (L4) layers
of the [OSI Model](https://en.wikipedia.org/wiki/OSI_model), and denies packets from entry based on
a set of rules regarding the network in general.

A Web Application Firewall operates at the Application (L7) layer of the OSI Model and can
examine all the packets traveling to and from a specific application. A WAF can set
more advanced rules around threat detection.

## Features

ModSecurity is enabled with the [OWASP Core Rule Set (CRS)](https://github.com/coreruleset/coreruleset/) by
default. The OWASP CRS logs attempts to the following attacks:

- [SQL Injection](https://wiki.owasp.org/index.php/OWASP_Periodic_Table_of_Vulnerabilities_-_SQL_Injection)
- [Cross-Site Scripting](https://wiki.owasp.org/index.php/OWASP_Periodic_Table_of_Vulnerabilities_-_Cross-Site_Scripting_(XSS))
- [Local File Inclusion](https://wiki.owasp.org/index.php/Testing_for_Local_File_Inclusion)
- [Remote File Inclusion](https://wiki.owasp.org/index.php/OWASP_Periodic_Table_of_Vulnerabilities_-_Remote_File_Inclusion)
- [Code Injection](https://wiki.owasp.org/index.php/Code_Injection)
- [Session Fixation](https://wiki.owasp.org/index.php/Session_fixation)
- [Scanner Detection](https://wiki.owasp.org/index.php/Category:Vulnerability_Scanning_Tools)
- [Metadata/Error Leakages](https://wiki.owasp.org/index.php/Improper_Error_Handling)

It is good to have a basic knowledge of the following:

- [Kubernetes](https://kubernetes.io/docs/home/)
- [Ingress](https://kubernetes.github.io/ingress-nginx/)
- [ModSecurity](https://www.modsecurity.org/)
- [OWASP Core Rule Set](https://github.com/coreruleset/coreruleset/)

## Roadmap

More information on the direction of the WAF can be
found in [Product Vision - Defend](https://about.gitlab.com/direction/defend/#waf)
