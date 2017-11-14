---
last_updated: 2017-11-10
---

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

In addition, we'll make use of [Amazon's EC2 Spot instances](https://aws.amazon.com/ec2/spot/)
which will greatly reduce the costs of the Runner instances while still using
quite powerful autoscaling machines.

## Prerequisites

The first step is to install GitLab Runner in an EC2 instance that will serve
as the bastion to spawning new machines. This doesn't have to be a powerful
machine since it will not run any jobs itself, a `t2.micro` instance will do.
This machine will be a dedicated host since we need it always up and running,
thus it will be the only standard cost.

NOTE: **Note:**
For the bastion instance, choose a distribution that both Docker and GitLab
Runner support, for example either Ubuntu, Debian, CentOS or RHEL will work fine.

Install the prerequisites:

1. Log in your server
1. [Install GitLab Runner from the official GitLab repository](https://docs.gitlab.com/runner/install/linux-repository.html)
1. [Install Docker](https://docs.docker.com/engine/installation/#server)
1. [Install Docker Machine](https://docs.docker.com/machine/install-machine/)

Before configuring the GitLab Runner, you need to first register it, so that
it connects with your GitLab instance:

1. [Obtain a Runner token](../../ci/runners/README.md)
1. [Register the Runner](https://docs.gitlab.com/runner/register/index.html#gnu-linux)
1. When asked the executor type, enter `docker+machine`

TIP: **Tip:**
If you want every user in your instance to be able to use the autoscaled Runners,
register the Runner as a shared one.

You can now move on to the most important part, configuring GitLab Runner.

## Configuring GitLab Runner to use the AWS machine driver

Now that the Runner is registered, you need to edit its configuration file and
add the required options for the AWS machine driver.

Here's a full example of `/etc/gitlab-runner/config.toml`. Open it with your
editor and edit as you see fit:

```toml
concurrent = 10
check_interval = 0

[[runners]]
  name = "gitlab-aws-autoscaler"
  url = "<URL of your GitLab instance>"
  token = "<Runner's token>"
  executor = "docker+machine"
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
    MachineDriver = "amazonec2"
    MachineName = "gitlab-docker-machine-%s"
    OffPeakPeriods = ["* * 0-7,19-23 * * mon-fri *", "* * * * * sat,sun *"]
    OffPeakIdleCount = 0
    OffPeakIdleTime = 1200
    MachineOptions = [
      "amazonec2-access-key=XXXX",
      "amazonec2-secret-key=XXXX",
      "amazonec2-region=us-east-1",
      "amazonec2-vpc-id=vpc-xxxxx",
      "amazonec2-subnet-id=subnet-xxxxx",
      "amazonec2-use-private-address=true",
      "amazonec2-tags=Name,gitlab-runner-autoscale",
      "amazonec2-security-group=docker-machine-scaler",
      "amazonec2-instance-type=m4.2xlarge",
      "amazonec2-ssh-user=ubuntu",
      "amazonec2-ssh-keypath=/etc/gitlab-runner/certs/gitlab-aws-autoscaler",
      "amazonec2-zone=a",
      "amazonec2-root-size=32",
    ]
```

Let's break it down to pieces.

### Global section

```toml
concurrent = 10
check_interval = 0
```

In the global section, you can define the limit of the jobs that can be run
concurrently across all Runners (`concurrent`). This heavily depends on your
needs, like how many users your Runners will accommodate, how much time your
builds take, etc. You can start with something low, and increase its value going
forward.

The `check_interval` setting defines in seconds how often the Runner should
check GitLab for new jobs.

[Read more](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section)
about all the options you can use.

### `[[runners]]`

```toml
[[runners]]
  name = "gitlab-aws-autoscaler"
  url = "<URL of your GitLab instance>"
  token = "<Runner's token>"
  executor = "docker+machine"
```

From the `[[runners]]` section, the most important part is the `executor` which
must be set to `docker+machine`. All those settings are taken care of when you
register the Runner for the first time.

[Read more](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)
about all the options you can use under `[[runners]]`.

### `[runners.docker]`

```toml
  [runners.docker]
    image = "alpine"
    privileged = true
    disable_cache = true
```

In the `[runners.docker]` section you can define the default Docker image to
be used by the child Runners if it's not defined in [`.gitlab-ci.yml`](../../ci/yaml/README.md).
Using `privileged = true`, all Runners will be able to run Docker in Docker
which is useful if you plan to build your own Docker images via GitLab CI/CD.

Next, we use `disable_cache = true` to disable the Docker executor's inner
cache mechanism since we will use the distributed cache mode as described
below.

[Read more](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-docker-section)
about all the options you can use under `[runners.docker]`.

### `[runners.cache]`

To speed up your jobs, GitLab Runner provides a cache mechanism where selected
directories and/or files are saved and shared between subsequent jobs.
While not required for this setup, it is recommended to use the distributed cache
mechanism that GitLab Runner provides. Since new instances will be created on
demand, it is essential to have a common place where cache is stored.

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

Here's some more info to get you started:

- [The `[runners.cache]` section reference](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-cache-section)
- [Deploying and using a cache server for GitLab Runner](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching)
- [How cache works](../../ci/yaml/README.md#cache)

### `[runners.machine]`

This is the most important part of the configuration and it's the one that
tells GitLab Runner how and when to spawn new Docker Machine instances.

```toml
  [runners.machine]
    IdleCount = 1
    IdleTime = 1800
    MaxBuilds = 100
    MachineDriver = "amazonec2"
    MachineName = "gitlab-docker-machine-%s"
    OffPeakPeriods = ["* * 0-7,19-23 * * mon-fri *", "* * * * * sat,sun *"]
    OffPeakIdleCount = 0
    OffPeakIdleTime = 1200
    MachineOptions = [
      "amazonec2-access-key=XXXX",
      "amazonec2-secret-key=XXXX",
      "amazonec2-region=us-east-1",
      "amazonec2-vpc-id=vpc-xxxxx",
      "amazonec2-subnet-id=subnet-xxxxx",
      "amazonec2-use-private-address=true",
      "amazonec2-tags=Name,gitlab-runner-autoscale",
      "amazonec2-security-group=docker-machine-scaler",
      "amazonec2-instance-type=m4.2xlarge",
      "amazonec2-ssh-user=ubuntu",
      "amazonec2-ssh-keypath=/etc/gitlab-runner/certs/gitlab-aws-autoscaler",
      "amazonec2-zone=a",
      "amazonec2-root-size=32",
    ]
```

TIP: **Tip:**
Under `MachineOptions` you can add anything that the [AWS Docker Machine driver
supports](https://docs.docker.com/machine/drivers/aws/#options).

[Read more](/runner/configuration/advanced-configuration.html#the-runners-machine-section)
about all the options you can use under `[runners.machine]`.

## Cutting down costs with Amazon EC2 Spot instances

As described by Amazon:

>
Amazon EC2 Spot instances allow you to bid on spare Amazon EC2 computing capacity.
Since Spot instances are often available at a discount compared to On-Demand
pricing, you can significantly reduce the cost of running your applications,
grow your application’s compute capacity and throughput for the same budget,
and enable new types of cloud computing applications.

In `/etc/gitlab-runner/config.toml` under the `MachineOptions` section:

```toml
    MachineOptions = [
      "amazonec2-request-spot-instance=true",
      "amazonec2-spot-price=0.03",
      "amazonec2-block-duration-minutes=60"
    ]
```

With this configuration, Docker Machines are created on Spot instances with a
maximum bid price of $0.03 per hour and the duration of the Spot instance is
capped at 60 minutes.

To learn more about Amazon EC2 Spot instances, visit the following links:

- https://aws.amazon.com/ec2/spot/
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-requests.html
- https://aws.amazon.com/blogs/aws/focusing-on-spot-instances-lets-talk-about-best-practices/

### Caveats of Spot instances

If the Spot price raises, the auto-scale Runner would fail to create new machines.

This eventually eats 60 requests and then AWS won't accept any more. Then once
the spot price is acceptable, you are locked out for a bit because the call amount
limit is exceeded.

You can use the following command in the bastion machine to see the Docker Machines
state:

```sh
docker-machine ls -q --filter state=Error --format "{{.NAME}}"
```

NOTE: **Note:**
Follow [issue 2771](https://gitlab.com/gitlab-org/gitlab-runner/issues/2771)
for more information.

## Conclusion

Using the autoscale feature of GitLab Runner can save you both time and money.
Using the spot instances that AWS provides can save you even more.

You can read the following user cases from which this tutorial was influenced:

- [HumanGeo - Scaling GitLab CI](http://blog.thehumangeo.com/gitlab-autoscale-runners.html)
- [subtrakt Health - Autoscale GitLab CI Runners and save 90% on EC2 costs](https://substrakthealth.com/news/gitlab-ci-cost-savings/)
