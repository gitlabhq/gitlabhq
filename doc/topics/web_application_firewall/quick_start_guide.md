---
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Getting started with the Web Application Firewall

This is a step-by-step guide that will help you use GitLab's [Web Application Firewall](index.md) after
deploying a project hosted on GitLab.com to Google Kubernetes Engine using [Auto DevOps](../autodevops/index.md).

We will use GitLab's native Kubernetes integration, so you will not need
to create a Kubernetes cluster manually using the Google Cloud Platform console.
We will create and deploy a simple application that we create from a GitLab template.

These instructions will also work for a self-managed GitLab instance. However, you will
need to ensure your own [runners are configured](../../ci/runners/README.md) and
[Google OAuth is enabled](../../integration/google.md).

GitLab's Web Application Firewall is deployed with [Ingress](../../user/clusters/applications.md#ingress),
so it will be available to your applications no matter how you deploy them to Kubernetes.

## Configuring your Google account

Before creating and connecting your Kubernetes cluster to your GitLab project,
you need a Google Cloud Platform account. If you do not already have one,
sign up at <https://console.cloud.google.com>. You will need to either sign in with an existing
Google account (for example, one that you use to access Gmail, Drive, etc.) or create a new one.

1. To enable the required APIs and related services, follow the steps in the ["Before you begin" section of the Kubernetes Engine docs](https://cloud.google.com/kubernetes-engine/docs/quickstart#before-you-begin).
1. Make sure you have created a [billing account](https://cloud.google.com/billing/docs/how-to/manage-billing-account).

TIP: **Tip:**
Every new Google Cloud Platform (GCP) account receives [$300 in credit](https://console.cloud.google.com/freetrial),
and in partnership with Google, GitLab is able to offer an additional $200 for new GCP accounts to get started with GitLab's
Google Kubernetes Engine integration. All you have to do is [follow this link](https://cloud.google.com/partners/partnercredit/?PCN=a0n60000006Vpz4AAC) and apply for credit.

## Creating a new project from a template

We will use one of GitLab's project templates to get started. As the name suggests,
those projects provide a barebones application built on some well-known frameworks.

1. In GitLab, click the plus icon (**+**) at the top of the navigation bar and select
   **New project**.
1. Go to the **Create from template** tab where you can choose for example a Ruby on
   Rails, Spring, or NodeJS Express project.
   We will use the Ruby on Rails template.

   ![Select project template](../autodevops/img/guide_project_template_v12_3.png)

1. Give your project a name, optionally a description, and make it public so that
   you can take advantage of the features available in the
   [GitLab Gold plan](https://about.gitlab.com/pricing/#gitlab-com).

   ![Create project](../autodevops/img/guide_create_project_v12_3.png)

1. Click **Create project**.

Now that the project is created, the next step is to create the Kubernetes cluster
under which this application will be deployed.

## Creating a Kubernetes cluster from within GitLab

1. On the project's landing page, click **Add Kubernetes cluster**
   (note that this option is also available when you navigate to **Operations > Kubernetes**).

   ![Project landing page](../autodevops/img/guide_project_landing_page_v12_10.png)

1. On the **Create new cluster on GKE** tab, click **Sign in with Google**.

   ![Google sign in](../autodevops/img/guide_google_signin_v12_3.png)

1. Connect with your Google account and click **Allow** when asked (this
   appears only the first time you connect GitLab with your Google account).

   ![Google auth](../autodevops/img/guide_google_auth_v12_3.png)

1. The last step is to provide the cluster details.
   1. Give it a name, leave the environment scope as is, and choose the GCP project under which the cluster
      will be created (per the instructions to [configure your Google account](#configuring-your-google-account), a project should have already been created for you).
   1. Choose the [region/zone](https://cloud.google.com/compute/docs/regions-zones/) under which the cluster will be created.
   1. Enter the number of nodes you want it to have.
   1. Choose the [machine type](https://cloud.google.com/compute/docs/machine-types).

   ![GitLab GKE cluster details](../autodevops/img/guide_gitlab_gke_details_v12_3.png)

1. Click **Create Kubernetes cluster**.

After a couple of minutes, the cluster is created. You can also see its
status on your [GCP dashboard](https://console.cloud.google.com/kubernetes).

The next step is to install some applications on your cluster that are needed
to take full advantage of Auto DevOps.

## Install Ingress

GitLab's Kubernetes integration comes with some
[pre-defined applications](../../user/project/clusters/index.md#installing-applications)
for you to install.

![Cluster applications](../autodevops/img/guide_cluster_apps_v12_3.png)

For this guide, we need to install Ingress. Ingress provides load balancing,
SSL termination, and name-based virtual hosting, using NGINX behind
the scenes. Make sure to switch the toggle to the enabled position before installing.

Both logging and blocking modes are available for WAF. While logging mode is useful for
auditing anomalous traffic, blocking mode ensures the traffic doesn't reach past Ingress.

![Cluster applications](img/guide_waf_ingress_installation_v12_10.png)

After Ingress is installed, wait a few seconds and copy the IP address that
is displayed in order to add in your base **Domain** at the top of the page. For
the purpose of this guide, we will use the one suggested by GitLab. Once you have
filled in the domain, click **Save changes**.

![Cluster Base Domain](../autodevops/img/guide_base_domain_v12_3.png)

Prometheus should also be installed. It is an open-source monitoring and
alerting system that we will use to supervise the deployed application.
We will not install GitLab Runner as we will use the shared runners that
GitLab.com provides.

## Enabling Auto DevOps (optional)

Starting with GitLab 11.3, Auto DevOps is enabled by default. However, it is possible to disable
Auto DevOps at both the instance-level (for self-managed instances) and the group-level.
Follow these steps if Auto DevOps has been manually disabled:

1. Navigate to **Settings > CI/CD > Auto DevOps**.
1. Select **Default to Auto DevOps pipeline**.
1. Select the [continuous deployment strategy](../autodevops/index.md#deployment-strategy)
   which automatically deploys the application to production once the pipeline
   successfully runs on the `master` branch.
1. Click **Save changes**.

   ![Auto DevOps settings](../autodevops/img/guide_enable_autodevops_v12_3.png)

Once you complete all the above and save your changes, a new pipeline is
automatically created. To view the pipeline, go to **CI/CD > Pipelines**.

![First pipeline](../autodevops/img/guide_first_pipeline_v12_3.png)

The next section explains what each pipeline job does.

## Deploying the application

By now you should see the pipeline running, but what is it running exactly?

To navigate inside the pipeline, click its status badge (its status should be "Running").
The pipeline is split into a few stages, each running a couple of jobs.

![Pipeline stages](../autodevops/img/guide_pipeline_stages_v13_0.png)

In the **build** stage, the application is built into a Docker image and then
uploaded to your project's [Container Registry](../../user/packages/container_registry/index.md) ([Auto Build](../autodevops/stages.md#auto-build)).

In the **test** stage, GitLab runs various checks on the application.

The **production** stage is run after the tests and checks finish, and it automatically
deploys the application in Kubernetes ([Auto Deploy](../autodevops/stages.md#auto-deploy)).

The **production** stage creates Kubernetes objects
like a Deployment, Service, and Ingress resource. The
application will be monitored by the WAF automatically.

## Validating Ingress is running ModSecurity

Now we can make sure that Ingress is running properly with ModSecurity and send
a request to ensure our application is responding correctly. You must connect to
your cluster either using [Cloud Shell](https://cloud.google.com/shell/) or the [Google Cloud SDK](https://cloud.google.com/sdk/install).

1. After connecting to your cluster, check if the Ingress-NGINX controller is running and ModSecurity is enabled.

   This is done by running the following commands:

   ```shell
   $ kubectl get pods -n gitlab-managed-apps | grep 'ingress-controller'
   ingress-nginx-ingress-controller-55f9cf6584-dxljn        2/2     Running

   $ kubectl -n gitlab-managed-apps exec -it $(kubectl get pods -n gitlab-managed-apps | grep 'ingress-controller' | awk '{print $1}') -- cat /etc/nginx/nginx.conf | grep 'modsecurity on;'
           modsecurity on;
   ```

1. Verify the Rails application has been installed properly.

   ```shell
   $ kubectl get ns
   auto-devv-2-16730183-production     Active

   $ kubectl get pods -n auto-devv-2-16730183-production
   NAME                                   READY   STATUS    RESTARTS
   production-5778cfcfcd-nqjcm            1/1     Running   0
   production-postgres-6449f8cc98-r7xgg   1/1     Running   0
   ```

1. To make sure the Rails application is responding, send a request to it by running:

   ```shell
   $ kubectl get ing -n auto-devv-2-16730183-production
   NAME  HOSTS  PORTS
   production-auto-deploy  fjdiaz-auto-devv-2.34.68.60.207.nip.io,le-16730183.34.68.60.207.nip.io  80, 443

   $ curl --location --insecure fjdiaz-auto-devv-2.34.68.60.207.nip.io | grep 'Rails!' --after 2 --before 2
   <body>
       <p>You're on Rails!</p>
   </body>
   ```

Now that we have confirmed our system is properly setup, we can go ahead and test
the WAF with OWASP CRS!

## Testing out the OWASP Core Rule Set

Now let's send a potentially malicious request, as if we were a scanner,
checking for vulnerabilities within our application and examine the ModSecurity logs:

```shell
$ curl --location --insecure fjdiaz-auto-devv-2.34.68.60.207.nip.io --header "User-Agent: absinthe" | grep 'Rails!' --after 2 --before 2
<body>
    <p>You're on Rails!</p>
</body>

$ kubectl -n gitlab-managed-apps exec -it $(kubectl get pods -n gitlab-managed-apps | grep 'ingress-controller' | awk '{print $1}') -- cat /var/log/modsec/audit.log | grep 'absinthe'
{
    "message": "Found User-Agent associated with security scanner",
    "details": {
        "match": "Matched \"Operator `PmFromFile' with parameter `scanners-user-agents.data' against variable `REQUEST_HEADERS:user-agent' (Value: `absinthe' )",
        "reference": "o0,8v84,8t:lowercase",
        "ruleId": "913100",
        "file": "/etc/nginx/owasp-modsecurity-crs/rules/REQUEST-913-SCANNER-DETECTION.conf",
        "lineNumber": "33",
        "data": "Matched Data: absinthe found within REQUEST_HEADERS:user-agent: absinthe",
        "severity": "2",
        "ver": "OWASP_CRS/3.2.0",
        "rev": "",
        "tags": ["application-multi", "language-multi", "platform-multi", "attack-reputation-scanner", "OWASP_CRS", "OWASP_CRS/AUTOMATION/SECURITY_SCANNER", "WASCTC/WASC-21", "OWASP_TOP_10/A7", "PCI/6.5.10"],
        "maturity": "0",
        "accuracy": "0"
    }
}
```

You can see that ModSecurity logs the suspicious behavior. By sending a request
with the `User Agent: absinthe` header, which [absinthe](https://github.com/cameronhotchkies/Absinthe), a tool for testing for SQL injections uses, we can detect that someone was
searching for vulnerabilities on our system. Detecting scanners is useful, because we
can learn if someone is trying to exploit our system.

## Conclusion

You can now see the benefits of a using a Web Application Firewall.
ModSecurity and the OWASP Core Rule Set, offer many more benefits.
You can explore them in more detail:

- [Category Direction - Web Application Firewall](https://about.gitlab.com/direction/protect/web_application_firewall/)
- [ModSecurity](https://www.modsecurity.org/)
- [OWASP Core Rule Set](https://github.com/coreruleset/coreruleset/)
- [AutoDevOps](../autodevops/index.md)
