# Installing GitLab on AWS

GitLab can be installed on Amazon Web Services (AWS) by using the official
AMIs provided with each release.

## Introduction

GitLab on AWS can leverage many of the services that are already
configurable with High Availability (HA). These services have a lot of
flexibility and are able to adopt to most companies, best of all is the
ability to automate both vertical and horizontal scaling.

In this guide we'll go through a basic HA setup where we'll start by
configuring our Virtual Private Cloud and subnets to later integrate
services such as RDS for our database server and ElastiCache as a Redis
cluster to finally manage them within an auto scaling group with custom
scaling policies.

## Requirements

A basic familiarity with AWS and EC2 is assumed. In particular, you will need:

- [An AWS account](https://console.aws.amazon.com/console/home)
- [Create or upload](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
  an SSH key to connect to the instance via SSH
- A domain name under which GitLab will be reached

## Architecture

Below is the diagram of the architecture.

<img src="img/aws_diagram.png" alt="AWS architecture diagram" class="image-noshadow">

## Costs

Here's a list of the services we will use and their costs:

- **EC2**: GitLab will deployed on shared hardware which means
  [on-demand pricing](https://aws.amazon.com/ec2/pricing/on-demand)
  will apply. If you want to run it on a dedicated or reserved instance,
  consult the [EC2 pricing page](https://aws.amazon.com/ec2/pricing/) for more
  information on the cost.
- **EBS**: We will also use an EBS volume to store the Git data. See the
  [Amazon EBS pricing](https://aws.amazon.com/ebs/pricing/).
- **S3**: We will use S3 to store backups, artifacts, LFS objects, etc. See the
  [Amazon S3 pricing](https://aws.amazon.com/s3/pricing/).
- **ALB**: An Application Load Balancer will be used to route requests to the
  GitLab instance. See the [Amazon ELB pricing](https://aws.amazon.com/elasticloadbalancing/pricing/).
- **RDS**: An Amazon Relational Database Service using PostgreSQL will be used
  to provide database High Availability. See the
  [Amazon RDS pricing](https://aws.amazon.com/rds/postgresql/pricing/).
- **ElastiCache**: An in-memory cache environment will be used to provide Redis
  High Availability. See the [Amazon ElastiCache pricing](https://aws.amazon.com/elasticache/pricing/).

## Creating an IAM EC2 instance role and profile

To minimize the permissions of the user, we'll create a new IAM role with
limited access:

1. Navigate to the IAM dashboard https://console.aws.amazon.com/iam/home and
   click on **Create role**.
1. Create a new role by choosing to **AWS service > EC2**. Once done, click on
   **Next: Permissions**.

    ![Create role](img/create_iam_role.png)

1. Choose **AmazonEC2FullAccess** and **AmazonS3FullAccess** and click on **Next: Review**.
1. Give the role the name `GitLabAdmin` and click **Create role**.

    ![Create role](img/create_iam_role_review.png)

## Configuring the network

We'll start by creating a VPC for our GitLab cloud infrastructure, then
we can create subnets to have public and private instances in at least
two AZs. Public subnets will require a Route Table keep and an associated
Internet Gateway.

### VPC

Let's create a VPC:

1. Navigate to https://console.aws.amazon.com/vpc/home
1. Select **Your VPCs** from the left menu and then click on **Create VPC**.
   At the name tag enter `gitlab-vpc` and at the IPv4 CIDR block enter `10.0.0.0/16`.
   If you don't require dedicated hardware, you can leave tenancy as default.
   Click **Yes, Create** when ready.

    ![Create VPC](img/create_vpc.png)

### Subnets

Now, let's create some subnets in different Availability Zones. Make sure
that each subnet is associated the the VPC we just created and
that CIDR blocks don't overlap. This will also
allow us to enable multi AZ for redundancy.

We will create private and public subnets to match load balancers and
RDS instances as well:

1. Select **Subnets** from the left menu.
1. Click on **Create subnet**. Give it a descriptive name tag based on the IP,
   for example `gitlab-public-10.0.0.0`, select the VPC we created previously,
   and at the IPv4 CIDR block let's give it a 24 subnet `10.0.0.0/24`:

    ![Create subnet](img/create_subnet.png)

1. Follow the same steps to create all subnets:

    | Name tag | Type |Availability Zone | CIDR block |
    | -------- | ---- | ---------------- | ---------- |
    | gitlab-public-10.0.0.0  | public  | us-west-2a | 10.0.0.0 |
    | gitlab-private-10.0.1.0 | private | us-west-2a | 10.0.1.0 |
    | gitlab-public-10.0.2.0  | public  | us-west-2b | 10.0.2.0 |
    | gitlab-private-10.0.3.0 | private | us-west-2b | 10.0.3.0 |

### Route Table

Up to now all our subnets are private. We need to create a Route Table
to associate an Internet Gateway. On the same VPC dashboard:

1. Select **Route Tables** from the left menu.
1. Click **Create Route Table**.
1. At the "Name tag" enter `gitlab-public` and choose `gitlab-vpc` under "VPC".
1. Hit **Yes, Create**.

### Internet Gateway

Now, still on the same dashboard head over to Internet Gateways and
create a new one:

1. Select **Internet Gateways** from the left menu.
1. Click on **Create internet gateway**, give it the name `gitlab-gateway` and
   click **Create**.
1. Select it from the table, and then under the **Actions** dropdown choose
   "Attach to VPC".

    ![Create gateway](img/create_gateway.png)

1. Choose `gitlab-vpc` from the list and hit **Attach**.

### Configuring subnets

We now need to add a new target which will be our Internet Gateway and have
it receive traffic from any destination.

1. Select **Route Tables** from the left menu and select the `gitlab-public`
   route to show the options at the bottom.
1. Select the **Routes** tab, hit **Edit > Add another route** and set `0.0.0.0/0`
   as destination. In the target, select the `gitlab-gateway` we created previously.
   Hit **Save** once done.

    ![Associate subnet with gateway](img/associate_subnet_gateway.png)

Next, we must associate the **public** subnets to the route table:

1. Select the **Subnet Associations** tab and hit **Edit**.
1. Check only the public subnet and hit **Save**.

    ![Associate subnet with gateway](img/associate_subnet_gateway_2.png)

---

Now that we're done with the network, let's create a security group.

## Creating a security group

The security group is basically the firewall:

1. Select **Security Groups** from the left menu.
1. Click on **Create Security Group** and fill in the details. Give it a name,
   add a description, and choose the VPC we created previously
1. Select the security group from the list and at the the bottom select the
   Inbound Rules tab. You will need to open the SSH, HTTP, and HTTPS ports. Set
   the source to `0.0.0.0/0`.

     ![Create security group](img/create_security_group.png)

     TIP: **Tip:**
     Based on best practices, you should allow SSH traffic from only a known
     host or CIDR block. In that case, change the SSH source to be custom and give
     it the IP you want to SSH from.

1. When done, click on **Save**.

## PostgreSQL with RDS

For our database server we will use Amazon RDS which offers Multi AZ
for redundancy. Let's start by creating a subnet group and then we'll
create the actual RDS instance.

### RDS Subnet Group

1. Navigate to the RDS dashboard and select **Subnet Groups** from the left menu.
1. Give it a name (`gitlab-rds-group`), a description, and choose the VPC from
   the VPC dropdown.
1. Click on "Add all the subnets related to this VPC" and
   remove the public ones, we only want the **private subnets**.
   In the end, you should see `10.0.1.0/24` and `10.0.3.0/24` (as
   we defined them in the [subnets section](#subnets)).
   Click **Create** when ready.

    ![RDS Subnet Group](img/rds_subnet_group.png)

### Creating the database

Now, it's time to create the database:

1. Select **Instances** from the left menu and click on **Create database**.
1. Select PostgreSQL and click **Next**.
1. Since this is a production server, let's choose "Production". Click **Next**.
1. Let's see the instance specifications:
    1. Leave the license model as is (`postgresql-license`).
    1. For the version, select the latest of the 9.6 series (check the
       [database requirements](../../install/requirements.md#postgresql-requirements))
       if there are any updates on this).
    1. For the size, let's select a `t2.medium` instance.
    1. Multi-AZ-deployment is recommended as redundancy, so choose "Create
       replica in different zone". Read more at
       [High Availability (Multi-AZ)](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html).
    1. A Provisioned IOPS (SSD) storage type is best suited for HA (though you can
       choose a General Purpose (SSD) to reduce the costs). Read more about it at
       [Storage for Amazon RDS](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html).

1. The rest of the settings on this page request a DB isntance identifier, username
   and a master password. We've chosen to use `gitlab-db-ha`, `gitlab` and a
   very secure password respectively. Keep these in hand for later.
1. Click on **Next** to proceed to the advanced settings.
1. Make sure to choose our gitlab VPC, our subnet group, set public accessibility to
   **No**, and to leave it to create a new security group. The only additional
    change which will be helpful is the database name for which we can use
    `gitlabhq_production`. At the very bottom, there's an option to enable
    auto updates to minor versions. You may want to turn it off.
1. When done, click **Create database**.

### Installing the `pg_trgm` extension for PostgreSQL

Once the database is created, connect to your new RDS instance to verify access
and to install a required extension.

You can find the host or endpoint by selecting the instance you just created and
after the details drop down you'll find it labeled as 'Endpoint'. Do not to
include the colon and port number:

```sh
sudo /opt/gitlab/embedded/bin/psql -U gitlab -h <rds-endpoint> -d gitlabhq_production
```

At the psql prompt create the extension and then quit the session:

```sh
psql (9.4.7)
Type "help" for help.

gitlab=# CREATE EXTENSION pg_trgm;
gitlab=# \q
```

---

Now that the database is created, let's move on setting up Redis with ElasticCache.

## Redis with ElastiCache

ElastiCache is an in-memory hosted caching solution. Redis maintains its own
persistence and is used for certain types of the GitLab application.

To set up Redis:

1. Navigate to the ElastiCache dashboard from your AWS console.
1. Go to **Subnet Groups** in the left menu, and create a new subnet group.
   Make sure to select our VPC and its [private subnets](#subnets). Click
   **Create** when ready.

    ![ElastiCache subnet](img/ec_subnet.png)

1. Select **Redis** on the left menu and click on **Create** to create a new
   Redis cluster. Depending on your load, you can choose whether to enable
   cluster mode or not. Even without cluster mode on, you still get the
   chance to deploy Redis in multi availability zones. In this guide, we chose
   not to enable it.
1. In the settings section:
    1. Give the cluster a name (`gitlab-redis`) and a description.
    1. For the version, select the latest of `3.2` series (e.g., `3.2.10`).
    1. Select the node type and the number of replicas.
1. In the advanced settings section:
   1. Select the multi-AZ auto-failover option.
   1. Select the subnet group we created previously.
   1. Manually select the preferred availability zones, and under "Replica 2"
      choose a different zone than the other two.

        ![Redis availability zones](img/ec_az.png)

1. In the security settings, edit the security groups and choose the
   `gitlab-security-group` we had previously created.
1. Leave the rest of the settings to their default values or edit to your liking.
1. When done, click **Create**.

## RDS and Redis Security Group

Let's navigate to our EC2 security groups and add a small change for our EC2
instances to be able to connect to RDS. First, copy the security group name we
defined, namely `gitlab-security-group`, select the RDS security group and edit the
inbound rules. Choose the rule type to be PostgreSQL and paste the name under
source.

Similar to the above, jump to the `gitlab-security-group` group
and add a custom TCP rule for port `6379` accessible within itself.

## Load Balancer

On the EC2 dashboard, look for Load Balancer on the left column:

1. Click the **Create Load Balancer** button.
  1. Choose the Application Load Balancer.
  1. Give it a name (`gitlab-loadbalancer`) and set the scheme to "internet-facing".
  1. In the "Listeners" section, make sure it has HTTP and HTTPS.
  1. In the "Availability Zones" section, select the `gitlab-vpc` we have created
     and associate the **public subnets**.
1. Click on the **Configure Security Settings** to go to the next section to
   select the TLS certificate. When done, go to the next step.
1. In the "Security Groups" section, create a new one by giving it a name
   (`gitlab-loadbalancer-sec-group`) and allow both HTTP ad HTTPS traffic
   from anywhere (`0.0.0.0/0, ::/0`).
1. In the next step, configure the routing and select an existing target group
   (`gitlab-public`). The Load Balancer Health will allow us to indicate where to
   ping and what makes up a healthy or unhealthy instance.
1. Leave the "Register Targets" section as is, and finally review the settings
   and create the ELB.

After the Load Balancer is up and running, you can re-visit your Security
Groups to improve access only through the ELB and any other requirement
you might have.

## Deploying GitLab inside an auto scaling group

We'll use AWS's wizard to deploy GitLab and then SSH into the instance to
configure the PostgreSQL and Redis connections.

The Auto Scaling Group option is available through the EC2 dashboard on the left
sidebar.

1. Click on the **Create Auto Scaling group** button.
1. Create a new launch configuration.

### Choose the AMI

Choose the AMI:

1. Go to the Community AMIs and search for `GitLab EE <version>`
   where `<version>` the latest version as seen  in the
   [releases page](https://about.gitlab.com/releases/).

    ![Choose AMI](img/choose_ami.png)

### Choose instance type

Based on [GitLab's requirements](../requirements.md#hardware-requirements), the
instance type should be at least `c4.xlarge`. This is enough to accommodate 100 users:

1. Choose the `c4.xlarge` instance.
1. Click **Next: Configure Instance Details**

### Configure details

In this step we'll configure some details:

1. Give it a name (`gitlab-autoscaling`).
1. Select the IAM role we created.
1. Optionally, enable CloudWatch and the EBS-optimized instance settings.
1. In the "Advanced Details" section, set the IP address type to
   "Do not assign a public IP address to any instances."
1. Click **Next: Add Storage**.

### Add storage

The root volume is 8GB by default and should be enough given that we won't store
any data there. Let's add a new EBS volume that will host the Git data. Its
size depends on your needs and you can always migrate to a bigger volume.
You will be able to [set up that volume later](#setting-up-the-ebs-volume).

### Configure security group

As a last step, configure the security group:

1. Select the existing load balancer security group we [have created](#load-balancer).
1. Select **Review**.

### Review and launch

Now is a good time to review all the previous settings. When ready, click
**Create launch configuration** and select the SSH key pair you have created previously.

### Create Auto Scaling Group

We are now able to start creating our Auto Scaling Group:

1. Give it a group name.
1. Set the group size to 2 as we want to always start with two instances.
1. Assign it our network VPC and add the **private subnets**.
1. In the "Advanced Details" section, choose to receive traffic from ELBs
   and select our ELB.
1. Choose the ELB health check.
1. Click **Next: Configure scaling policies**.

This is the really great part of Auto Scaling, we get to choose when AWS
launches new instances and when it removes them. For this group we'll
scale between 2 and 4 instances where one instance will be added if CPU
utilization is greater than 60% and one instance is removed if it falls
to less than 45%.

![Auto scaling group policies](img/policies.png)

Finally, configure notifications and tags as you see fit, and create the
auto scaling group.

You'll notice that after we save the configuration, AWS starts launching our two
instances in different AZs and without a public IP which is exactly what
we where aiming for.

## After deployment

After a few minutes, the instances should be up and accessible via the internet.
Let's connect to it and configure some things before logging in.

### Configuring GitLab to connect with postgres and Redis

While connected to your server, let's connect to the RDS instance to verify
access and to install a required extension:

```sh
sudo /opt/gitlab/embedded/bin/psql -U gitlab -h <rds-endpoint> -d gitlabhq_production
```

Edit the `gitlab.rb` file at `/etc/gitlab/gitlab.rb`
find the `external_url 'http://gitlab.example.com'` option and change it
to the domain you will be using or the public IP address of the current
instance to test the configuration.

For a more detailed description about configuring GitLab read [Configuring GitLab for HA](../../administration/high_availability/gitlab.md)

Now look for the GitLab database settings and uncomment as necessary. In
our current case we'll specify the adapter, encoding, host, db name,
username, and password:

```ruby
# Disable the built-in Postgres
postgresql['enable'] = false

# Fill in the connection details
gitlab_rails['db_adapter'] = "postgresql"
gitlab_rails['db_encoding'] = "unicode"
gitlab_rails['db_database'] = "gitlabhq_production"
gitlab_rails['db_username'] = "gitlab"
gitlab_rails['db_password'] = "mypassword"
gitlab_rails['db_host'] = "<rds-endpoint>"
```

Next we only need to configure the Redis section by adding the host and
uncommenting the port:

```ruby
# Disable the built-in Redis
redis['enable'] = false

# Fill in the connection details
gitlab_rails['redis_host'] = "<redis-endpoint>"
gitlab_rails['redis_port'] = 6379
```

The last configuration step is to [change the default file locations ](http://docs.gitlab.com/ee/administration/high_availability/nfs.html)
to make the EFS integration easier to manage.

Finally run reconfigure, you might find it useful to run a check and
a service status to make sure everything has been setup correctly.

```sh
sudo gitlab-ctl reconfigure
sudo gitlab-rake gitlab:check
sudo gitlab-ctl status
```

If everything looks good copy the Elastic IP over to your browser and
test the instance manually.

### Setting up the EBS volume

The EBS volume will host the Git repositories data:

1. First, format the `/dev/xvdb` volume and then mount it under the directory
   that the data will live, for example `/mnt/gitlab-data/`.
1. Tell GitLab to store its data to the new directory by editing
   `/etc/gitlab/gitlab.rb` with your editor:

    ```ruby
    git_data_dirs({
      "default" => { "path" => "/mnt/gitlab-data" }
    })
    ```

1. Save the file and reconfigure GitLab:

    ```sh
    sudo gitlab-ctl reconfigure
    ```

To add more than one data volumes, follow the same steps.

Read more on [storing Git data in an alternative directory](../../administration/repository_storage_paths.md).

### Using Amazon S3 object storage

The S3 object storage can be used for various GitLab objects:

- [How to store the LFS objects in S3](../../workflow/lfs/lfs_administration.md#s3-for-omnibus-installations) ((Omnibus GitLab installations))
- [How to store Container Registry images to S3](../../administration/container_registry.md#container-registry-storage-driver) (Omnibus GitLab installations)
- [How to store GitLab CI job artifacts to S3](../../administration/job_artifacts.md#using-object-storage) (Omnibus GitLab installations)

### Setting up a domain name

After you SSH into the instance, configure the domain name:

1. Open `/etc/gitlab/gitlab.rb` with your favorite editor.
1. Edit the `external_url` value:

    ```ruby
    external_url 'http://example.com'
    ```

1. Reconfigure GitLab:

    ```sh
    sudo gitlab-ctl reconfigure
    ```

You should now be able to reach GitLab at the URL you defined. To use HTTPS
(recommended), see the [HTTPS documentation](https://docs.gitlab.com/omnibus/settings/nginx.html#enable-https).

### Logging in for the first time

If you followed the previous section, you should be now able to visit GitLab
in your browser. The very first time, you will be asked to set up a password
for the `root` user which has admin privileges on the GitLab instance.

After you set it up, login with username `root` and the newly created password.

## Health check and monitoring with Prometheus

Apart from Amazon's Cloudwatch which you can enable on various services,
GitLab provides its own integrated monitoring solution based on Prometheus.
For more information on how to set it up, visit the
[GitLab Prometheus documentation](../../administration/monitoring/prometheus/index.md)

GitLab also has various [health check endpoints](../..//user/admin_area/monitoring/health_check.md)
that you can ping and get reports.

## GitLab Runners

If you want to take advantage of GitLab CI/CD, you have to set up at least one
GitLab Runner.

Read more on configuring an
[autoscaling GitLab Runner on AWS](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/).

## Backup and restore

GitLab provides [a tool to backup](../../raketasks/backup_restore.md#creating-a-backup-of-the-gitlab-system)
and restore its Git data, database, attachments, LFS objects, etc.

Some important things to know:

- The backup/restore tool does not store some configuration files, like secrets, you'll
  need to [do it yourself](../../raketasks/backup_restore.md#storing-configuration-files).
- By default, the backup files are stored locally, but you can
  [backup GitLab using S3](../../raketasks/backup_restore.md#using-amazon-s3).
- You can exclude [specific directories form the backup](../../raketasks/backup_restore.md#excluding-specific-directories-from-the-backup).

### Backing up GitLab

To backup GitLab:

1. SSH into your instance.
1. Take a backup:

    ```sh
    sudo gitlab-rake gitlab:backup:create
    ```

### Restoring GitLab from a backup

To restore GitLab, first check the [restore documentation](../../raketasks/backup_restore.md#restore)
and mainly the restore prerequisites. Then, follow the steps under the
[Omnibus installations section](../../raketasks/backup_restore.md#restore-for-omnibus-installations).

## Updating GitLab

GitLab releases a new version every month on the 22nd. Whenever a new version is
released, you can update your GitLab instance:

1. SSH into your instance
1. Take a backup:

    ```sh
    sudo gitlab-rake gitlab:backup:create
    ```

1. Update the repositories and install GitLab:

    ```sh
    sudo apt update
    sudo apt install gitlab-ee
    ```

After a few minutes, the new version should be up and running.

## Conclusion

High Availability is a very big area, we went mostly through scaling and some
redundancy options but it might also imply Geographic replication. There is a
lot of ground yet to cover so have a read through these other resources and feel
free to open an issue to request additional material:

- [GitLab High Availability](https://docs.gitlab.com/ee/administration/high_availability/):
  GitLab supports several different types of clustering and high-availability.
- [Geo replication](https://docs.gitlab.com/ee/administration/geo/replication/):
  Geo is the solution for widely distributed development teams.
- [Omnibus GitLab](https://docs.gitlab.com/omnibus/) - Everything you need to know
  about administering your GitLab instance.
- [Upload a license](https://docs.gitlab.com/ee/user/admin_area/license.html):
  Activate all GitLab Enterprise Edition functionality with a license.
- [Pricing](https://about.gitlab.com/pricing): Pricing for the different tiers.
