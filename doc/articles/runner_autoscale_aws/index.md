---
last_updated: 2017-11-24
---

> **[Article Type](../../development/writing_documentation.html#types-of-technical-articles):** Admin guide ||
> **Level:** intermediary ||
> **Author:** [Achilleas Pipinellis](https://gitlab.com/axil) ||
> **Publication date:** 2017/11/24

# Autoscaling GitLab Runner on AWS

One of the biggest advantages of GitLab Runner is its ability to automatically
spin up and down VMs to make sure your builds get processed immediately. It's a
great feature, and if used correctly, it can be extremely useful in situations
where you don't use your Runners 24/7 and want to have a cost-effective and
scalable solution.

## Introduction

In this tutorial, we'll explore how to properly configure a GitLab Runner in
AWS that will serve as the bastion where it will spawn new Docker machines on
demand.

In addition, we'll make use of [Amazon's EC2 Spot instances][spot] which will
greatly reduce the costs of the Runner instances while still using quite
powerful autoscaling machines.

## Prerequisites

NOTE: **Note:**
A familiarity with Amazon Web Services (AWS) is required as this is where most
of the configuration will take place.

Your GitLab instance is going to need to talk to the Runners over the network,
and that is something you need think about when configuring any AWS security
groups or when setting up your DNS configuration.

For example, you can keep the EC2 resources segmented away from public traffic
in a different VPC to better strengthen your network security. Your environment
is likely different, so consider what works best for your situation.

### AWS security groups

Docker Machine will attempt to use a
[default security group](https://docs.docker.com/machine/drivers/aws/#security-group)
with rules for port `2376`, which is required for communication with the Docker
daemon. Instead of relying on Docker, you can create a security group with the
rules you need and provide that in the Runner options as we will
[see below](#the-runners-machine-section). This way, you can customize it to your
liking ahead of time based on your networking environment.

### AWS credentials

You'll need an [AWS Access Key](https://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html)
tied to a user with permission to scale (EC2) and update the cache (via S3).
Create a new user with [policies](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-policies-for-amazon-ec2.html)
for EC2 (AmazonEC2FullAccess) and S3 (AmazonS3FullAccess). To be more secure,
you can disable console login for that user. Keep the tab open or copy paste the
security credentials in an editor as we'll use them later during the
[Runner configuration](#the-runners-machine-section).

## Prepare the bastion instance

The first step is to install GitLab Runner in an EC2 instance that will serve
as the bastion that spawns new machines. This doesn't have to be a powerful
machine since it will not run any jobs itself, a `t2.micro` instance will do.
This machine will be a dedicated host since we need it always up and running,
thus it will be the only standard cost.

NOTE: **Note:**
For the bastion instance, choose a distribution that both Docker and GitLab
Runner support, for example either Ubuntu, Debian, CentOS or RHEL will work fine.

Install the prerequisites:

1. Log in to your server
1. [Install GitLab Runner from the official GitLab repository](https://docs.gitlab.com/runner/install/linux-repository.html)
1. [Install Docker](https://docs.docker.com/engine/installation/#server)
1. [Install Docker Machine](https://docs.docker.com/machine/install-machine/)

Now that the Runner is installed, it's time to register it.

## Registering the GitLab Runner

Before configuring the GitLab Runner, you need to first register it, so that
it connects with your GitLab instance:

1. [Obtain a Runner token](../../ci/runners/README.md)
1. [Register the Runner](https://docs.gitlab.com/runner/register/index.html#gnu-linux)
1. When asked the executor type, enter `docker+machine`

You can now move on to the most important part, configuring the GitLab Runner.

TIP: **Tip:**
If you want every user in your instance to be able to use the autoscaled Runners,
register the Runner as a shared one.

## Configuring the GitLab Runner

Now that the Runner is registered, you need to edit its configuration file and
add the required options for the AWS machine driver.

Let's first break it down to pieces.

### The global section

In the global section, you can define the limit of the jobs that can be run
concurrently across all Runners (`concurrent`). This heavily depends on your
needs, like how many users your Runners will accommodate, how much time your
builds take, etc. You can start with something low like `10`, and increase or
decrease its value going forward.

The `check_interval` option defines how often the Runner should check GitLab
for new jobs, in seconds.

Example:

```toml
concurrent = 10
check_interval = 0
```

[Read more](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section)
about all the options you can use.

### The `runners` section

From the `[[runners]]` section, the most important part is the `executor` which
must be set to `docker+machine`. Most of those settings are taken care of when
you register the Runner for the first time.

`limit` sets the maximum number of machines (running and idle) that this Runner
will spawn. For more info check the [relationship between `limit`, `concurrent`
and `IdleCount`](https://docs.gitlab.com/runner/configuration/autoscale.html#how-concurrent-limit-and-idlecount-generate-the-upper-limit-of-running-machines).

Example:

```toml
[[runners]]
  name = "gitlab-aws-autoscaler"
  url = "<URL of your GitLab instance>"
  token = "<Runner's token>"
  executor = "docker+machine"
  limit = 20
```

[Read more](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)
about all the options you can use under `[[runners]]`.

### The `runners.docker` section

In the `[runners.docker]` section you can define the default Docker image to
be used by the child Runners if it's not defined in [`.gitlab-ci.yml`](../../ci/yaml/README.md).
By using `privileged = true`, all Runners will be able to run
[Docker in Docker](../../ci/docker/using_docker_build.md#use-docker-in-docker-executor)
which is useful if you plan to build your own Docker images via GitLab CI/CD.

Next, we use `disable_cache = true` to disable the Docker executor's inner
cache mechanism since we will use the distributed cache mode as described
in the following section.

Example:

```toml
  [runners.docker]
    image = "alpine"
    privileged = true
    disable_cache = true
```

[Read more](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-docker-section)
about all the options you can use under `[runners.docker]`.

### The `runners.cache` section

To speed up your jobs, GitLab Runner provides a cache mechanism where selected
directories and/or files are saved and shared between subsequent jobs.
While not required for this setup, it is recommended to use the distributed cache
mechanism that GitLab Runner provides. Since new instances will be created on
demand, it is essential to have a common place where the cache is stored.

In the following example, we use Amazon S3:

```toml
  [runners.cache]
    Type = "s3"
    ServerAddress = "s3.amazonaws.com"
    AccessKey = "<your AWS Access Key ID>"
    SecretKey = "<your AWS Secret Access Key>"
    BucketName = "<the bucket where your cache should be kept>"
    BucketLocation = "us-east-1"
    Shared = true
```

Here's some more info to further explore the cache mechanism:

- [Reference for `runners.cache`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-cache-section)
- [Deploying and using a cache server for GitLab Runner](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching)
- [How cache works](../../ci/yaml/README.md#cache)

### The `runners.machine` section

This is the most important part of the configuration and it's the one that
tells GitLab Runner how and when to spawn new or remove old Docker Machine
instances.

We will focus on the AWS machine options, for the rest of the settings read
about the:

- [Autoscaling algorithm and the parameters it's based on](https://docs.gitlab.com/runner/configuration/autoscale.html#autoscaling-algorithm-and-parameters) - depends on the needs of your organization
- [Off peak time configuration](https://docs.gitlab.com/runner/configuration/autoscale.html#off-peak-time-mode-configuration) - useful when there are regular time periods in your organization when no work is done, for example weekends

Here's an example of the `runners.machine` section:

```toml
  [runners.machine]
    IdleCount = 1
    IdleTime = 1800
    MaxBuilds = 10
    OffPeakPeriods = [
      "* * 0-9,18-23 * * mon-fri *",
      "* * * * * sat,sun *"
    ]
    OffPeakIdleCount = 0
    OffPeakIdleTime = 1200
    MachineDriver = "amazonec2"
    MachineName = "gitlab-docker-machine-%s"
    MachineOptions = [
      "amazonec2-access-key=XXXX",
      "amazonec2-secret-key=XXXX",
      "amazonec2-region=us-central-1",
      "amazonec2-vpc-id=vpc-xxxxx",
      "amazonec2-subnet-id=subnet-xxxxx",
      "amazonec2-use-private-address=true",
      "amazonec2-tags=runner-manager-name,gitlab-aws-autoscaler,gitlab,true,gitlab-runner-autoscale,true",
      "amazonec2-security-group=docker-machine-scaler",
      "amazonec2-instance-type=m4.2xlarge",
    ]
```

The Docker Machine driver is set to `amazonec2` and the machine name has a
standard prefix followed by `%s` (required) that is replaced by the ID of the
child Runner: `gitlab-docker-machine-%s`.

Now, depending on your AWS infrastructure, there are many options you can set up
under `MachineOptions`. Below you can see the most common ones.

| Machine option | Description |
| -------------- | ----------- |
| `amazonec2-access-key=XXXX` | The AWS access key of the user that has permissions to create EC2 instances, see [AWS credentials](#aws-credentials). |
| `amazonec2-secret-key=XXXX` | The AWS secret key of the user that has permissions to create EC2 instances, see [AWS credentials](#aws-credentials). |
| `amazonec2-region=eu-central-1` | The region to use when launching the instance. You can omit this entirely and the default `us-east-1` will be used. |
| `amazonec2-vpc-id=vpc-xxxxx` | Your [VPC ID](https://docs.docker.com/machine/drivers/aws/#vpc-id) to launch the instance in. |
| `amazonec2-subnet-id=subnet-xxxx` | The AWS VPC subnet ID. |
| `amazonec2-use-private-address=true` | Use the private IP address of Docker Machines, but still create a public IP address. Useful to keep the traffic internal and avoid extra costs.|
| `amazonec2-tags=runner-manager-name,gitlab-aws-autoscaler,gitlab,true,gitlab-runner-autoscale,true` | AWS extra tag key-value pairs, useful to identify the instances on the AWS console. The "Name" tag is set to the machine name by default. We set the "runner-manager-name" to match the Runner name set in `[[runners]]`, so that we can filter all the EC2 instances created by a specific manager setup. Read more about [using tags in AWS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html). |
| `amazonec2-security-group=docker-machine-scaler` | AWS VPC security group name, see [AWS security groups](#aws-security-groups). |
| `amazonec2-instance-type=m4.2xlarge` | The instance type that the child Runners will run on. |

TIP: **Tip:**
Under `MachineOptions` you can add anything that the [AWS Docker Machine driver
supports](https://docs.docker.com/machine/drivers/aws/#options). You are highly
encouraged to read Docker's docs as your infrastructure setup may warrant
different options to be applied.

NOTE: **Note:**
The child instances will use by default Ubuntu 16.04 unless you choose a
different AMI ID by setting `amazonec2-ami`.

NOTE: **Note:**
If you specify `amazonec2-private-address-only=true` as one of the machine
options, your EC2 instance won't get assigned a public IP. This is ok if your
VPC is configured correctly with an Internet Gateway (IGW) and routing is fine,
but it’s something to consider if you've got a more complex configuration. Read
more in [Docker docs about VPC connectivity](https://docs.docker.com/machine/drivers/aws/#vpc-connectivity).

[Read more](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-machine-section)
about all the options you can use under `[runners.machine]`.

### Getting it all together

Here's the full example of `/etc/gitlab-runner/config.toml`:

```toml
concurrent = 10
check_interval = 0

[[runners]]
  name = "gitlab-aws-autoscaler"
  url = "<URL of your GitLab instance>"
  token = "<Runner's token>"
  executor = "docker+machine"
  limit = 20
  [runners.docker]
    image = "alpine"
    privileged = true
    disable_cache = true
  [runners.cache]
    Type = "s3"
    ServerAddress = "s3.amazonaws.com"
    AccessKey = "<your AWS Access Key ID>"
    SecretKey = "<your AWS Secret Access Key>"
    BucketName = "<the bucket where your cache should be kept>"
    BucketLocation = "us-east-1"
    Shared = true
  [runners.machine]
    IdleCount = 1
    IdleTime = 1800
    MaxBuilds = 100
    OffPeakPeriods = [
      "* * 0-9,18-23 * * mon-fri *",
      "* * * * * sat,sun *"
    ]
    OffPeakIdleCount = 0
    OffPeakIdleTime = 1200
    MachineDriver = "amazonec2"
    MachineName = "gitlab-docker-machine-%s"
    MachineOptions = [
      "amazonec2-access-key=XXXX",
      "amazonec2-secret-key=XXXX",
      "amazonec2-region=us-central-1",
      "amazonec2-vpc-id=vpc-xxxxx",
      "amazonec2-subnet-id=subnet-xxxxx",
      "amazonec2-use-private-address=true",
      "amazonec2-tags=runner-manager-name,gitlab-aws-autoscaler,gitlab,true,gitlab-runner-autoscale,true",
      "amazonec2-security-group=docker-machine-scaler",
      "amazonec2-instance-type=m4.2xlarge",
    ]
```

## Cutting down costs with Amazon EC2 Spot instances

As [described by][spot] Amazon:

>
Amazon EC2 Spot instances allow you to bid on spare Amazon EC2 computing capacity.
Since Spot instances are often available at a discount compared to On-Demand
pricing, you can significantly reduce the cost of running your applications,
grow your application’s compute capacity and throughput for the same budget,
and enable new types of cloud computing applications.

In addition to the [`runners.machine`](#the-runners-machine-section) options
you picked above, in `/etc/gitlab-runner/config.toml` under the `MachineOptions`
section, add the following:

```toml
    MachineOptions = [
      "amazonec2-request-spot-instance=true",
      "amazonec2-spot-price=0.03",
      "amazonec2-block-duration-minutes=60"
    ]
```

With this configuration, Docker Machines are created on Spot instances with a
maximum bid price of $0.03 per hour and the duration of the Spot instance is
capped at 60 minutes. The `0.03` number mentioned above is just an example, so
be sure to check on the current pricing based on the region you picked.

To learn more about Amazon EC2 Spot instances, visit the following links:

- https://aws.amazon.com/ec2/spot/
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-requests.html
- https://aws.amazon.com/blogs/aws/focusing-on-spot-instances-lets-talk-about-best-practices/

### Caveats of Spot instances

While Spot instances is a great way to use unused resources and minimize the
costs of your infrastructure, you must be aware of the implications.

Running CI jobs on Spot instances may increase the failure rates because of the
Spot instances pricing model. If the price exceeds your bid, the existing Spot
instances will be immediately terminated and all your jobs on that host will fail.

As a consequence, the auto-scale Runner would fail to create new machines while
it will continue to request new instances. This eventually will make 60 requests
and then AWS won't accept any more. Then once the Spot price is acceptable, you
are locked out for a bit because the call amount limit is exceeded.

If you encounter that case, you can use the following command in the bastion
machine to see the Docker Machines state:

```sh
docker-machine ls -q --filter state=Error --format "{{.NAME}}"
```

NOTE: **Note:**
There are some issues regarding making GitLab Runner gracefully handle Spot
price changes, and there are reports of `docker-machine` attempting to
continually remove a Docker Machine. GitLab has provided patches for both cases
in the upstream project. For more information, see issues
[#2771](https://gitlab.com/gitlab-org/gitlab-runner/issues/2771) and
[#2772](https://gitlab.com/gitlab-org/gitlab-runner/issues/2772).

## Conclusion

In this guide we learned how to install and configure a GitLab Runner in
autoscale mode on AWS.

Using the autoscale feature of GitLab Runner can save you both time and money.
Using the Spot instances that AWS provides can save you even more, but you must
be aware of the implications. As long as your bid is high enough, there shouldn't
be an issue.

You can read the following use cases from which this tutorial was (heavily)
influenced:

- [HumanGeo - Scaling GitLab CI](http://blog.thehumangeo.com/gitlab-autoscale-runners.html)
- [subtrakt Health - Autoscale GitLab CI Runners and save 90% on EC2 costs](https://substrakthealth.com/news/gitlab-ci-cost-savings/)

[spot]: https://aws.amazon.com/ec2/spot/
