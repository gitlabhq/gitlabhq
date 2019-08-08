---
type: reference
---

# Kubernetes, GitLab and You

This is a list of useful information regarding Kubernetes that the GitLab Support
Team sometimes uses while troubleshooting. GitLab is making this public, so that anyone
can make use of the Support team's collected knowledge

CAUTION: **Caution:**
These commands **can alter or break** your Kubernetes components so use these at your own risk.

If you are on a [paid tier](https://about.gitlab.com/pricing/) and are not sure how
to use these commands, it is best to [contact Support](https://about.gitlab.com/support/)
and they will assist you with any issues you are having.

## Generic kubernetes commands

- How to authorize to your GCP project (can be especially useful if you have projects
  under different GCP accounts):

  ```bash
  gcloud auth login
  ```

- How to access Kubernetes dashboard:

  ```bash
  # for minikube:
  minikube dashboard —url
  # for non-local installations if access via kubectl is configured:
  kubectl proxy
  ```

- How to ssh to a Kubernetes node and enter the container as root
  <https://github.com/kubernetes/kubernetes/issues/30656>:

  - For GCP, you may find the node name and run `gcloud compute ssh node-name`.
  - List containers using `docker ps`.
  - Enter container using `docker exec --user root -ti container-id bash`.

- How to copy a file from local machine to a pod:

  ```bash
  kubectl cp file-name pod-name:./destination-path
  ```

- What to do with pods in `CrashLoopBackoff` status:

  - Check logs via Kubernetes dashboard.
  - Check logs via `kubectl`:

    ```bash
    kubectl logs <unicorn pod> -c dependencies
    ```

- How to tail all Kubernetes cluster events in real time:

  ```bash
  kubectl get events -w --all-namespaces
  ```

- How to get logs of the previously terminated pod instance:

  ```bash
  kubectl logs <pod-name> --previous
  ```

  NOTE: **Note:**
  No logs are kept in the containers/pods themselves, everything is written to stdout.
  This is the principle of Kubernetes, read [Twelve-factor app](https://12factor.net/)
  for details.

## Gitlab-specific kubernetes information

- Minimal config that can be used to test a Kubernetes helm chart can be found
  [here](https://gitlab.com/charts/gitlab/issues/620).

- Tailing logs of a separate pod. An example for a unicorn pod:

  ```bash
  kubectl logs gitlab-unicorn-7656fdd6bf-jqzfs -c unicorn
  ```

- It is not possible to get all the logs via `kubectl` at once, like with `gitlab-ctl tail`,
  but a number of third-party tools can be used to do it:

  - [Kubetail](https://github.com/johanhaleby/kubetail)
  - [kail: kubernetes tail](https://github.com/boz/kail)
  - [stern](https://github.com/wercker/stern)

- Check all events in the `gitlab` namespace (the namespace name can be different if you
  specified a different one when deploying the helm chart):

  ```bash
  kubectl get events -w --namespace=gitlab
  ```

- Most of the useful GitLab tools (console, rake tasks, etc) are found in the task-runner
  pod. You may enter it and run commands inside or run them from the outside:

  ```bash
  # find the pod
  kubectl get pods | grep task-runner

  # enter it
  kubectl exec -it <task-runner-pod-name> bash

  # open rails console
  # rails console can be also called from other GitLab pods
  /srv/gitlab/bin/rails console

  # source-style commands should also work
  /srv/gitlab && bundle exec rake gitlab:check RAILS_ENV=production

  # run GitLab check. Note that the output can be confusing and invalid because of the specific structure of GitLab installed via helm chart
  /usr/local/bin/gitlab-rake gitlab:check

  # open console without entering pod
  kubectl exec -it <task-runner-pod-name> /srv/gitlab/bin/rails console

  # check the status of DB migrations
  kubectl exec -it <task-runner-pod-name> /usr/local/bin/gitlab-rake db:migrate:status
  ```

  You can also use `gitlab-rake`, instead of `/usr/local/bin/gitlab-rake`.

- Troubleshooting **Operations > Kubernetes** integration:

  - Check the output of `kubectl get events -w --all-namespaces`.
  - Check the logs of pods within `gitlab-managed-apps` namespace.
  - On the side of GitLab check sidekiq log and kubernetes log. When GitLab is installed
    via helm chart, kubernetes.log can be found inside the sidekiq pod.

- How to get your initial admin password <https://docs.gitlab.com/charts/installation/deployment.html#initial-login>:

  ```bash
  # find the name of the secret containing the password
  kubectl get secrets | grep initial-root
  # decode it
  kubectl get secret <secret-name> -ojsonpath={.data.password} | base64 --decode ; echo
  ```

- How to connect to a GitLab postgres database:

  ```bash
  kubectl exec -it <task-runner-pod-name> -- /srv/gitlab/bin/rails dbconsole -p
  ```
  
- How to get info about helm installation status:

  ```bash
  helm status name-of-installation
  ```

- How to update GitLab installed using helm chart:

  ```bash
  helm repo upgrade

  # get current values and redirect them to yaml file (analogue of gitlab.rb values)
  helm get values <release name> > gitlab.yaml

  # run upgrade itself
  helm upgrade <release name> <chart path> -f gitlab.yaml
  ```

  After <https://canary.gitlab.com/charts/gitlab/issues/780> is fixed, it should
  be possible to use [Updating GitLab using the Helm Chart](https://docs.gitlab.com/ee/install/kubernetes/gitlab_chart.html#updating-gitlab-using-the-helm-chart)
  for upgrades.

- How to apply changes to GitLab config:

  - Modify the `gitlab.yaml` file.
  - Run the following command to apply changes:

    ```bash
    helm upgrade <release name> <chart path> -f gitlab.yaml
    ```

## Installation of minimal GitLab config via minukube on macOS

This section is based on [Developing for Kubernetes with Minikube](https://gitlab.com/charts/gitlab/blob/master/doc/minikube/index.md)
and [Helm](https://gitlab.com/charts/gitlab/blob/master/doc/helm/index.md). Refer
to those documents for details.

- Install kubectl via Homebrew:

  ```bash
  brew install kubernetes-cli
  ```

- Install minikube via Homebrew:

  ```bash
  brew cask install minikube
  ```

- Start minikube and configure it. If minikube cannot start, try running `minikube delete && minikube start`
  and repeat the steps:

  ```bash
  minikube start --cpus 3 --memory 8192 # minimum amount for GitLab to work
  minikube addons enable ingress
  minikube addons enable kube-dns
  ```

- Install helm via Homebrew and initialize it:

  ```bash
  brew install kubernetes-helm
  helm init --service-account tiller
  ```

- Copy the file <https://gitlab.com/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml>
  to your workstation.

- Find the IP address in the output of `minikube ip` and update the yaml file with
  this IP address.

- Install the GitLab helm chart:

  ```bash
  helm repo add gitlab https://charts.gitlab.io
  helm install --name gitlab -f <path-to-yaml-file> gitlab/gitlab
  ```

  If you want to modify some GitLab settings, you can use the above-mentioned config
  as a base and create your own yaml file.

- Monitor the installation progress via `helm status gitlab` and `minikube dashboard`.
  The installation could take up to 20-30 minutes depending on the amount of resources
  on your workstation.

- When all the pods show either a `Running` or `Completed` status, get the GitLab password as
  described in [Initial login](https://docs.gitlab.com/ee/install/kubernetes/gitlab_chart.html#initial-login),
  and log in to GitLab via the UI. It will be accessible via `https://gitlab.domain`
  where `domain` is the value provided in the yaml file.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
