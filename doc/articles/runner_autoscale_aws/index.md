---
last_updated: 2017-11-10
---

# Autoscaling GitLab Runner on AWS

GitLab Runner has the ability to autoscale which means automatically spawning
new machines on demand. This proves very useful in situations where you
don't use your Runners 24/7 and want to have a cost-effective and scalable
solution.

## Introduction

In this tutorial, we'll explore how to properly configure a GitLab Runner in
AWS that will serve as the bastion where it will spawn new Docker machines on
demand.

## Installation and configuration

The bastion will not run any jobs itself.

Edit `/etc/gitlab-runner/config.toml`:

```toml
concurrent = 3
check_interval = 0

[[runners]]
  name = "gitlab-aws-autoscaler"
  url = "<url to your GitLab CI host>"
  token = "<registration token>"
  executor = "docker+machine"
  environment = ["GODEBUG=netdns=cgo"]
  output_limit = 16384
  limit = 4
  [runners.docker]
    image = "ruby:2.1"
    privileged = true
    disable_cache = false
    volumes = ["/cache"]
    extra_hosts = ["gitlab.thehumangeo.com:<our internal GitLab IP>", "nexus.thehumangeo.com:<our internal Nexus IP>"]
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
      "amazonec2-ami=ami-996372fd",
      "amazonec2-zone=a",
      "amazonec2-root-size=32",
    ]
```

## Cutting costs with AWS spot instances

>
Amazon EC2 Spot instances allow you to bid on spare Amazon EC2 computing capacity.
Since Spot instances are often available at a discount compared to On-Demand
pricing, you can significantly reduce the cost of running your applications,
grow your application’s compute capacity and throughput for the same budget,
and enable new types of cloud computing applications.

- https://aws.amazon.com/ec2/spot/
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-requests.html
- https://aws.amazon.com/blogs/aws/focusing-on-spot-instances-lets-talk-about-best-practices/


In `/etc/gitlab-runner/config.toml` under the `MachineOptions` section:

```toml
    MachineOptions = [
      "amazonec2-request-spot-instance=true",
      "amazonec2-spot-price=0.03",
      "amazonec2-block-duration-minutes=180"
    ]
```

### Caveats of spot instances

If the spot price raises, the auto-scale Runner would fail to create new machines.

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
