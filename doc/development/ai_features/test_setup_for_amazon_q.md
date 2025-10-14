---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Test Setup For Amazon Q with GitLab
---

## 1. Obtain a Linux package for GitLab from the feature branch

- Apply the `"pipeline:run-all-e2e"` label on your merge request and run a new pipeline
- Go to the *Stage qa-->e2e:test-on-omnibus-ee-->Downstream TRIGGERED_EE_PIPELINE* pipeline and select the job for the desired Ubuntu version, for example, `Ubuntu-22.04-branch`
- Download the job artifacts and extract the contents

## 2. Setup a Linux instance on GCP

- Follow the [instructions](https://handbook.gitlab.com/handbook/company/infrastructure-standards/realms/sandbox/#individual-aws-account-or-gcp-project) to create a GCP project
  - Select the `gcp-669306fb(organizations/769164969568)` Cloud Provider while creating the Cloud Account
- Go to the [GCP Compute Engine page](https://console.cloud.google.com/compute/instances) and click on `Create Instance`
- Choose the `e2-standard-4` (4 vCPUs, 16 GB Memory) machine configuration
- By default, the `Debian` operating system and `Debian GNU/Linux 12` version are selected. `Ubuntu` can also be selected on the `OS and storage` tab.
- Select a disk size of 100 GB
- Click on `Create`
- SSH into the instance using `gcloud compute ssh --zone <zone_name> <instance_name> --project <project_name>` - This command is available in the UI under the `Connect` column, `View gcloud command` sub-menu.
- Confirm the OS version using a command such as `cat /etc/os-release`
- Allow access to ports 443 and 80 using the commands

  ``` sh
  gcloud compute firewall-rules create default-allow-https \
    --project=<project_name> \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:443 \
    --source-ranges=0.0.0.0/0

  gcloud compute firewall-rules create default-allow-http \
    --project=<project_name>
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=0.0.0.0/0
    ```

## 3. Configure DNS

- Purchase a [Non-Trademark Domain Name](https://internal.gitlab.com/handbook/it/it-self-service/it-guides/domains-dns/#non-trademark-domain-names) by following these [instructions](https://cloud.google.com/domains/docs/register-domain)
- Registering a [Cloud Domain](https://console.cloud.google.com/net-services/domains/registrations/list) also creates a [Cloud DNS Entry](https://console.cloud.google.com/net-services/dns/zones)
- Get the public IP for the VM using the command `gcloud compute instances describe <vm_name> --zone=<zone_name> --project=<project_name> --format='get(networkInterfaces[0].accessConfigs[0].natIP)'`
- Create `A` records for the root domain and the sub-domain using the command `gcloud dns record-sets create <dns_name> --zone=<zone_name> --project=<project_name> --type="A" --ttl="300" --rrdatas=<public_ip>`
- Verify DNS setup using `nslookup` or `dig`

## 4. Install the package on the VM

- Transfer the downloaded artifact to the VM using the command `gcloud compute scp <source_file> <instance_name>:<destination_path>  --zone <zone_name> --project <project_name>`
- Complete the [pre-installation steps](../../install/package/debian.md#enable-ssh-and-open-firewall-ports)
- Install required packages

  ``` sh
  sudo apt-get update
  sudo apt-get install -y curl openssh-server ca-certificates perl
  ```

- Install the package using the command `sudo dpkg -i <package_name>`
- Set the `external_url` in `/etc/gitlab/gitlab.rb` to the domain name (including `https://`) configured in the previous step and run `sudo gitlab-ctl reconfigure`
- The initial root password is available under `/etc/gitlab/initial_root_password`
- Confirm all services are healthy using `sudo gitlab-ctl status`
- Activate an `Ultimate` EE license based on these [instructions](../../administration/license.md)

### 4.a. Update the installed package on the VM

- SSH into the VM using the command `gcloud compute ssh --zone <zone_name> <instance_name> --project <project_name>`
- Transfer the updated package using the command `gcloud compute scp <full_path_to_package_file>:/home/<user_name>  --zone <zone_name> --project <project_name>`
- Run the following commands:

  ``` sh
  sudo touch /etc/gitlab/skip-auto-backup
  sudo apt update
  sudo dpkg -i <package_name>
  sudo rm /etc/gitlab/skip-auto-backup
  ```

## 5. Configure AWS

- Follow the [instructions](https://handbook.gitlab.com/handbook/company/infrastructure-standards/realms/sandbox/#individual-aws-account-or-gcp-project) to create an AWS account
- Follow the [instructions](https://handbook.gitlab.com/handbook/company/infrastructure-standards/realms/sandbox/#accessing-your-aws-account) to access the account
- Follow the [instructions](../../user/duo_amazon_q/setup.md#set-up-gitlab-duo-with-amazon-q) to set up GitLab Duo with Amazon Q
- There is a [Free tier](https://aws.amazon.com/q/developer/pricing/) available on Amazon Q Developer, so no additional Amazon license is required if an `Ultimate` EE license with the `GitLab Duo with Amazon Q` addon is activated

## 6. Test

Test the features for [issues](../../user/duo_amazon_q/_index.md#use-gitlab-duo-with-amazon-q-in-an-issue) and [merge requests](../../user/duo_amazon_q/_index.md#use-gitlab-duo-with-amazon-q-in-a-merge-request)
