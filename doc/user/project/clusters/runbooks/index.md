# Runbooks

Runbooks are a collection of documented procedures that explain how to 
carry out a particular process, be it starting, stopping, debugging, 
or troubleshooting a particular system.

## Overview

Historically, runbooks took the form of a decision tree or a detailed 
step-by-step guide depending on the condition or system. 

Modern implementations have introduced the concept of an "executable 
runbooks", where along with a well define process, operators can execute 
code blocks or database queries against a given environment.

## Nurtch Executable Runbooks

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/45912) in GitLab 11.4.

The JupyterHub app offered via GitLab’s Kubernetes integration now ships 
with Nurtch’s Rubix library, providing a simple way to create DevOps 
runbooks. A sample runbook is provided, showcasing common operations.

**<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch this [video](https://www.youtube.com/watch?v=Q_OqHIIUPjE)
for an overview of how this is acomplished in GitLab!**

## Requirements

To create an executable runbook, you will need:

1. **Kubernetes** - A Kubernetes cluster is required to deploy the rest of the applications. 
    The simplest way to get started is to add a cluster using [GitLab's GKE integration](https://docs.gitlab.com/ee/user/project/clusters/#adding-and-creating-a-new-gke-cluster-via-gitlab).
1. **Helm Tiller** - Helm is a package manager for Kubernetes and is required to install 
    all the other applications. It is installed in its own pod inside the cluster which 
    can run the helm CLI in a safe environment.
1. **Ingress** - Ingress can provide load balancing, SSL termination, and name-based 
    virtual hosting. It acts as a web proxy for your applications.
1. **JupyterHub** - JupyterHub is a multi-user service for managing notebooks across 
    a team. Jupyter Notebooks provide a web-based interactive programming environment 
    used for data analysis, visualization, and machine learning.

## Nurtch

Nurtch is the company behind the [Rubix library](https://github.com/Nurtch/rubix). Rubix is 
an open-source python library that makes it easy to perform common DevOps tasks inside Jupyter Notebooks. 
Tasks such as plotting Cloudwatch metrics and rolling your ECS/Kubernetes app are simplified 
down to a couple of lines of code. Check the [Nurtch Documentation](http://docs.nurtch.com/en/latest) 
for more information.
