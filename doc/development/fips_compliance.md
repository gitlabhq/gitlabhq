---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# FIPS compliance

FIPS is short for "Federal Information Processing Standard", a document which
defines certain security practices for a "cryptographic module" (CM). It aims
to ensure a certain security floor is met by vendors selling products to U.S.
Federal institutions.

WARNING:
GitLab is not FIPS compliant, even when built and run on a FIPS-enforcing
system. Large parts of the build are broken, and many features use forbidden
cryptographic primitives. Running GitLab on a FIPS-enforcing system is not
supported and may result in data loss. This document is intended to help
engineers looking to develop FIPS-related fixes. It is not intended to be used
to run a production GitLab instance.

There are two current FIPS standards: [140-2](https://en.wikipedia.org/wiki/FIPS_140-2)
and [140-3](https://en.wikipedia.org/wiki/FIPS_140-3). At GitLab we usually
mean FIPS 140-2.

## Current status

GitLab Inc has not committed to making GitLab FIPS-compliant at this time. We are
performing initial investigations to see how much work such an effort would be.

Read [Epic &5104](https://gitlab.com/groups/gitlab-org/-/epics/5104) for more
information on the status of the investigation.

## FIPS compliance at GitLab

In a FIPS context, compliance is a form of self-certification - if we say we are
"FIPS compliant", we mean that we *believe* we are. There are no external
certifications to acquire, but if we are aware of non-compliant areas
in GitLab, we cannot self-certify in good faith.

The known areas of non-compliance are tracked in [Epic &5104](https://gitlab.com/groups/gitlab-org/-/epics/5104).

To be compliant, all components (GitLab itself, Gitaly, etc) must be compliant,
along with the communication between those components, and any storage used by
them. Where functionality cannot be brought into compliance, it must be disabled
when FIPS mode is enabled.

## FIPS validation at GitLab

Unlike FIPS compliance, FIPS validation is a formal declaration of compliance by
an accredited auditor. The requirements needed to pass the audit are the same as
for FIPS compliance.

A list of FIPS-validated modules can be found at the
NIST (National Institute of Standards and Technology)
[cryptographic module validation program](https://csrc.nist.gov/projects/cryptographic-module-validation-program/validated-modules).

## Setting up a FIPS-enabled development environment

The simplest approach is to set up a virtual machine running
[Red Hat Enterprise Linux 8](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/security_hardening/using-the-system-wide-cryptographic-policies_security-hardening#switching-the-system-to-fips-mode_using-the-system-wide-cryptographic-policies).

Red Hat provide free licenses to developers, and permit the CD image to be
downloaded from the [Red Hat developer's portal](https://developers.redhat.com).
Registration is required.

After the virtual machine is set up, you can follow the [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit)
installation instructions, including the [advanced instructions for RHEL](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/advanced.md#red-hat-enterprise-linux).
Note that `asdf` is not used for dependency management because it's essential to
use the RedHat-provided Go compiler and other system dependencies.

### Enable FIPS mode

After GDK and its dependencies are installed, run this command (as
root) and restart the virtual machine:

```shell
fips-mode-setup --enable
```

You can check whether it's taken effect by running:

```shell
fips-mode-setup --check
```

In this environment, OpenSSL refuses to perform cryptographic operations
forbidden by the FIPS standards. This enables you to reproduce FIPS-related bugs,
and validate fixes.

You should be able to open a web browser inside the virtual machine and log in
to the GitLab instance.

You can disable FIPS mode again by running this command, then restarting the
virtual machine:

```shell
fips-mode-setup --disable
```

## Set up a FIPS-enabled cluster

You can use the [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) to spin
up a FIPS-enabled cluster for development and testing. These instructions use Amazon Web Services (AWS)
because that is the first target environment, but you can adapt them for other providers.

### Set up your environment

To get started, your AWS account must subscribe to a FIPS-enabled Amazon
Machine Image (AMI) in the [AWS Marketplace console](https://aws.amazon.com/premiumsupport/knowledge-center/launch-ec2-marketplace-subscription/).

This example assumes that the `Ubuntu Pro 20.04 FIPS LTS` AMI by
`Canonical Group Limited` has been added your account. This operating
system is used for virtual machines running in Amazon EC2.

### Omnibus

The simplest way to get a FIPS-enabled GitLab cluster is to use an Omnibus reference architecture.
See the [GET Quick Start Guide](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_quick_start_guide.md)
for more details. The following instructions build on the Quick Start and are also necessary for [Cloud Native Hybrid](#cloud-native-hybrid) installations.

#### Terraform: Use a FIPS AMI

1. Follow the guide to set up Terraform and Ansible.
1. After [step 2b](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_quick_start_guide.md#2b-setup-config),
   create a `data.tf` in your environment (for example, `gitlab-environment-toolkit/terraform/environments/gitlab-10k/inventory/data.tf`):

   ```tf
   data "aws_ami" "ubuntu_20_04_fips" {
     count = 1

     most_recent = true

     filter {
       name   = "name"
       values = ["ubuntu-pro-fips-server/images/hvm-ssd/ubuntu-focal-20.04-amd64-pro-fips-server-*"]
     }

     filter {
       name   = "virtualization-type"
       values = ["hvm"]
     }

     owners = ["aws-marketplace"]
   }
   ```

1. Add the custom `ami_id` to use this AMI in `environment.tf`. For
   example, in `gitlab-environment-toolkit/terraform/environments/gitlab-10k/inventory/environment.tf`:

   ```tf
   module "gitlab_ref_arch_aws" {
     source = "../../modules/gitlab_ref_arch_aws"

     prefix = var.prefix
     ami_id = data.aws_ami.ubuntu_20_04_fips[0].id
     ...
   ```

NOTE:
GET does not allow the AMI to change on EC2 instances after it has
been deployed via `terraform apply`. Since an AMI change would tear down
an instance, this would result in data loss: not only would disks be
destroyed, but also GitLab secrets would be lost. There is a [Terraform lifecycle rule](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/blob/2aaeaff8ac8067f23cd7b6bb5bf131061649089d/terraform/modules/gitlab_aws_instance/main.tf#L40)
to ignore AMI changes.

#### Ansible: Specify the FIPS Omnibus builds

The standard Omnibus GitLab releases build their own OpenSSL library,
which is not FIPS-validated. However, we have nightly builds that create
Omnibus packages that link against the operating system's OpenSSL library. To
use this package, update the `gitlab_repo_script_url` field in the
Ansible `vars.yml`. For example, you might modify
`gitlab-environment-toolkit/ansible/environments/gitlab-10k/inventory/vars.yml`
in this way:

```yaml
all:
  vars:
    ...
    gitlab_repo_script_url: "https://packages.gitlab.com/install/repositories/gitlab/nightly-fips-builds/script.deb.sh"
```

### Cloud Native Hybrid

A Cloud Native Hybrid install uses both Omnibus and Cloud Native GitLab
(CNG) images. The previous instructions cover the Omnibus part, but two
additional steps are needed to enable FIPS in CNG:

1. Use a custom Amazon Elastic Kubernetes Service (EKS) AMI.
1. Use GitLab containers built with RedHat's Universal Base Image (UBI).

#### Build a custom EKS AMI

Because Amazon does not yet publish a FIPS-enabled AMI, you have to
build one yourself with Packer.

Amazon publishes the following Git repositories with information about custom EKS AMIs:

- [Amazon EKS AMI Build Specification](https://github.com/awslabs/amazon-eks-ami)
- [Sample EKS custom AMIs](https://github.com/aws-samples/amazon-eks-custom-amis/)

This [GitHub pull request](https://github.com/awslabs/amazon-eks-ami/pull/898) makes
it possible to create an Amazon Linux 2 EKS AMI with FIPS enabled for Kubernetes v1.21.
To build an image:

1. [Install Packer](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli).
1. Run the following:

   ```shell
   git clone https://github.com/awslabs/amazon-eks-ami
   cd amazon-eks-ami
   git fetch origin pull/898/head:fips-ami
   git checkout fips-ami
   AWS_DEFAULT_REGION=us-east-1 make 1.21-fips # Be sure to set the region accordingly
   ```

If you are using a different version of Kubernetes, adjust the `make`
command and `Makefile` accordingly.

When the AMI build is done, a new AMI should be created with a message
such as the following:

```plaintext
==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:
us-west-2: ami-0a25e760cd00b027e
```

In this example, the AMI ID is `ami-0a25e760cd00b027e`, but your value may
be different.

Building a RHEL-based system with FIPS enabled should be possible, but
there is [an outstanding issue preventing the Packer build from completing](https://github.com/aws-samples/amazon-eks-custom-amis/issues/51).

#### Terraform: Use a custom EKS AMI

Now you can set the custom EKS AMI.

1. In `environment.tf`, add `eks_ami_id = var.eks_ami_id` so you can pass this variable to the
   AWS reference architecture module. For example, in
   `gitlab-environment-toolkit/terraform/environments/gitlab-10k/inventory/environment.tf`:

   ```tf
   module "gitlab_ref_arch_aws" {
     source = "../../modules/gitlab_ref_arch_aws"

     prefix = var.prefix
     ami_id = data.aws_ami.ubuntu_20_04_fips[0].id
     eks_ami_id = var.eks_ami_id
     ....
   ```

1. In `variables.tf`, define a `eks_ami_id` with the AMI ID in the
   previous step:

   ```tf
   variable "eks_ami_id" {
     default = "ami-0a25e760cd00b027e"
   }
   ```

#### Ansible: Use UBI images

CNG uses a Helm Chart to manage which container images to deploy. By default, GET
deploys the latest released versions that use Debian-based containers.

To switch to UBI-based containers, edit the Ansible `vars.yml` to use custom
Charts variables:

```yaml
all:
  vars:
    ...
    gitlab_charts_custom_config_file: '/path/to/gitlab-environment-toolkit/ansible/environments/gitlab-10k/inventory/charts.yml'
```

Now create `charts.yml` in the location specified above and specify tags with a `-ubi8` suffix. For example:

```yaml
global:
  image:
    pullPolicy: Always
  certificates:
    image:
      tag: master-ubi8

gitlab:
  gitaly:
    image:
      tag: master-ubi8
  gitlab-exporter:
    image:
      tag: master-ubi8
  gitlab-shell:
    image:
      tag: main-ubi8 # The default branch is main, not master
  gitlab-mailroom:
    image:
      tag: master-ubi8
  migrations:
    image:
      tag: master-ubi8
  sidekiq:
    image:
      tag: master-ubi8
  toolbox:
    image:
      tag: master-ubi8
  webservice:
    image:
      tag: master-ubi8
    workhorse:
      tag: master-ubi8

nginx-ingress:
  controller:
    image:
      repository: registry.gitlab.com/stanhu/gitlab-test-images/k8s-staging-ingress-nginx/controller
      tag: v1.2.0-beta.1
      pullPolicy: Always
      digest: sha256:ace38833689ad34db4a46bc1e099242696eb800def88f02200a8615530734116
```

The above example shows a FIPS-enabled [`nginx-ingress`](https://github.com/kubernetes/ingress-nginx) image.
See [this issue](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3153#note_917782207) for more details on
how to build NGINX and the Ingress Controller.

You can also use release tags, but the versioning is tricky because each
component may use its own versioning scheme. For example, for GitLab v14.10:

```yaml
global:
  certificates:
    image:
      tag: 20191127-r2-ubi8

gitlab:
  gitaly:
    image:
      tag: v14.10.0-ubi8
  gitlab-exporter:
    image:
      tag: 11.14.0-ubi8
  gitlab-shell:
    image:
      tag: v13.25.1-ubi8
  gitlab-mailroom:
    image:
      tag: v14.10.0-ubi8
  migrations:
    image:
      tag: v14.10.0-ubi8
  sidekiq:
    image:
      tag: v14.10.0-ubi8
  toolbox:
    image:
      tag: v14.10.0-ubi8
  webservice:
    image:
      tag: v14.10.0-ubi8
    workhorse:
      tag: v14.10.0-ubi8
```

## Verify FIPS

The following sections describe ways you can verify if FIPS is enabled.

### Kernel

```shell
$ cat /proc/sys/crypto/fips_enabled
1
```

### Ruby (Omnibus images)

```ruby
$ /opt/gitlab/embedded/bin/irb
irb(main):001:0> require 'openssl'; OpenSSL.fips_mode
=> true
```

### Ruby (CNG images)

```ruby
$ irb
irb(main):001:0> require 'openssl'; OpenSSL.fips_mode
=> true
```

### Go

Google maintains a [`dev.boringcrypto` branch](https://github.com/golang/go/tree/dev.boringcrypto) in the Golang compiler
that makes it possible to statically link BoringSSL, a FIPS-validated module forked from OpenSSL.
However, BoringSSL is not intended for public use.

We use [a fork of the `dev.boringcrypto` branch](https://github.com/golang-fips/go) to build Go programs that
dynamically link OpenSSL via `dlopen`. We can check whether a given
binary is using OpenSSL via `go tool nm` and look for symbols named
`Cfunc__goboringcrypto`. For example:

```plaintext
$ go tool nm nginx-ingress-controller  | grep Cfunc__goboringcrypto | tail
 2a0b650 D crypto/internal/boring._cgo_71ae3cd1ca33_Cfunc__goboringcrypto_SHA384_Final
 2a0b658 D crypto/internal/boring._cgo_71ae3cd1ca33_Cfunc__goboringcrypto_SHA384_Init
 2a0b660 D crypto/internal/boring._cgo_71ae3cd1ca33_Cfunc__goboringcrypto_SHA384_Update
 2a0b668 D crypto/internal/boring._cgo_71ae3cd1ca33_Cfunc__goboringcrypto_SHA512_Final
 2a0b670 D crypto/internal/boring._cgo_71ae3cd1ca33_Cfunc__goboringcrypto_SHA512_Init
 2a0b678 D crypto/internal/boring._cgo_71ae3cd1ca33_Cfunc__goboringcrypto_SHA512_Update
 2a0b680 D crypto/internal/boring._cgo_71ae3cd1ca33_Cfunc__goboringcrypto_internal_ECDSA_sign
 2a0b688 D crypto/internal/boring._cgo_71ae3cd1ca33_Cfunc__goboringcrypto_internal_ECDSA_verify
 2a0b690 D crypto/internal/boring._cgo_71ae3cd1ca33_Cfunc__goboringcrypto_internal_ERR_error_string_n
 2a0b698 D crypto/internal/boring._cgo_71ae3cd1ca33_Cfunc__goboringcrypto_internal_ERR_get_error
```
