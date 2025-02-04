---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: Provision GitLab on a single EC2 instance in AWS
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

If you want to provision a single GitLab instance on AWS, you have two options:

- The marketplace subscription
- The official GitLab AMIs

## Marketplace subscription

GitLab provides a 5 user subscription as an AWS Marketplace subscription to help teams of all sizes to get started with an Ultimate licensed instance in record time. The Marketplace subscription can be easily upgraded to any GitLab licensing via an AWS Marketplace Private Offer, with the convenience of continued AWS billing. No migration is necessary to obtain a larger, non-time based license from GitLab. Per-minute licensing is automatically removed when you accept the private offer.

For a tutorial on provisioning a GitLab Instance via a Marketplace Subscription, [use this tutorial](https://gitlab.awsworkshop.io/040_partner_setup.html). The tutorial links to the [GitLab Ultimate Marketplace Listing](https://aws.amazon.com/marketplace/pp/prodview-g6ktjmpuc33zk), but you can also use the [GitLab Premium Marketplace Listing](https://aws.amazon.com/marketplace/pp/prodview-amk6tacbois2k) to provision an instance.

## Official GitLab releases as AMIs

GitLab produces Amazon Machine Images (AMI) during the regular release process. The AMIs can be used for single instance GitLab installation or, by configuring `/etc/gitlab/gitlab.rb`, can be specialized for specific GitLab service roles (for example a Gitaly server). Older releases remain available and can be used to migrate an older GitLab server to AWS.

Initial licensing can either be the Free Enterprise License (EE) or the open source Community Edition (CE). The Enterprise Edition provides the easiest path forward to a licensed version if the need arises.

Currently the Amazon AMI uses the Amazon prepared Ubuntu AMI (x86 and ARM are available) as its starting point.

NOTE:
When deploying a GitLab instance using the official AMI, the root password to the instance is the EC2 **Instance** ID (not the AMI ID). This way of setting the root account password is specific to official GitLab published AMIs ONLY.

Instances running on Community Edition (CE) require a migration to Enterprise Edition (EE) to subscribe to the GitLab Premium or Ultimate plan. If you want to pursue a subscription, using the Free-forever plan of Enterprise Edition is the least disruptive method.

NOTE:
Because any given GitLab upgrade might involve data disk updates or database schema upgrades, swapping out the AMI is not sufficient for taking upgrades.

1. Sign in to the AWS Web Console, so that selecting the links in the following step take you directly to the AMI list.
1. Pick the edition you want:

   - [GitLab Enterprise Edition](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;owner=782774275127;search=GitLab%20EE;sort=desc:name): If you want to unlock the enterprise features, a license is needed.
   - [GitLab Community Edition](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;owner=782774275127;search=GitLab%20CE;sort=desc:name): The open source version of GitLab.
   - [GitLab Premium or Ultimate Marketplace (pre-licensed)](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;source=Marketplace;search=GitLab%20EE;sort=desc:name): 5 user license built into per-minute billing.

1. AMI IDs are unique per region. After you've loaded any of these editions, in the upper-right corner, select the desired target region of the console to see the appropriate AMIs.
1. After the console is loaded, you can add additional search criteria to narrow further. For instance, type `13.` to find only 13.x versions.
1. To launch an EC2 Machine with one of the listed AMIs, check the box at the start of the relevant row, and select **Launch** near the top of left of the page.
