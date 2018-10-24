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

> [Introduced][https://gitlab.com/gitlab-org/gitlab-ce/issues/45912] in GitLab 11.4.

The JupyterHub app offered via GitLab’s Kubernetes integration now ships 
with Nurtch’s Rubix library, providing a simple way to create DevOps 
runbooks. A sample runbook is provided, showcasing common operations.

The below video provides an overview of how this is acomplished in GitLab.

<iframe width="560" height="315" src="https://www.youtube.com/embed/Q_OqHIIUPjE" 
frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>

## Requirements

To create an executable runbook, you will need:

1. **Kubernetes Cluster** - 
1. **Helm Tiller** - 
1. **Ingress** -
1. **JupyterHub** -