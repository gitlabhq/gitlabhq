---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# FIPS compliance

FIPS is short for "Federal Information Processing Standard", a document which
defines certain security practices for a "cryptographic module" (CM). It aims
to ensure a certain security floor is met by vendors selling products to U.S.
Federal institutions.

WARNING:
You can build a FIPS-compliant instance of GitLab, but [not all features are included](#unsupported-features-in-fips-mode).
A FIPS-compliant instance must be configured following the [FIPS install instructions](#install-gitlab-with-fips-compliance)
exactly.

There are two current FIPS standards: [140-2](https://en.wikipedia.org/wiki/FIPS_140-2)
and [140-3](https://en.wikipedia.org/wiki/FIPS_140-3). At GitLab we usually
mean FIPS 140-2.

## Current status

GitLab has completed FIPS 140-2 Compliance for the build specified in this documentation. You can find our FIPS 140-2 Attestation in our [customer assurance package](https://about.gitlab.com/security/cap/), specifically the community package.

## FIPS compliance at GitLab

To be compliant, all components (GitLab itself, Gitaly, etc) must be compliant,
along with the communication between those components, and any storage used by
them. Where functionality cannot be brought into compliance, it must be disabled
when FIPS mode is enabled.

### Leveraged Cryptographic modules

| Cryptographic module name                                | CMVP number                                                                                     | Instance type | Software component used |
|----------------------------------------------------------|-------------------------------------------------------------------------------------------------|---------------|-------------------------|
| Ubuntu 20.04 AWS Kernel Crypto API Cryptographic Module  | [4132](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/4132) | EC2           | Linux kernel |
| Ubuntu 20.04 OpenSSL Cryptographic Module                | [3966](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/3966) | EC2           | Gitaly, Rails (Puma/Sidekiq) |
| Ubuntu 20.04 Libgcrypt Cryptographic Module              | [3902](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/3902) | EC2 instances | `gpg`, `sshd` |
| Amazon Linux 2 Kernel Crypto API Cryptographic Module    | [3709](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/3709) | EKS nodes     | Linux kernel |
| Amazon Linux 2 OpenSSL Cryptographic Module              | [3553](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/3553) | EKS nodes     | NGINX |
| RedHat Enterprise Linux 8 OpenSSL Cryptographic Module   | [4271](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/4271) | EKS nodes     | UBI containers: Workhorse, Pages, Container Registry, Rails (Puma/Sidekiq), Security Analyzers |
| RedHat Enterprise Linux 8 Libgcrypt Cryptographic Module | [3784](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/3784) | EKS nodes     | UBI containers: GitLab Shell, `gpg` |

### Supported Operating Systems

The supported hybrid platforms are:

- Omnibus GitLab: Ubuntu 20.04 LTS
- Cloud Native GitLab: Amazon Linux 2 (EKS)

### Unsupported features in FIPS mode

Some GitLab features may not work when FIPS mode is enabled. The following features
are known to not work in FIPS mode. However, there may be additional features not
listed here that also do not work properly in FIPS mode:

- [Container Scanning](../user/application_security/container_scanning/index.md) support for scanning images in repositories that require authentication.
- [Code Quality](../ci/testing/code_quality.md) does not support operating in FIPS-compliant mode.
- [Dependency scanning](../user/application_security/dependency_scanning/index.md) support for Gradle.
- [Dynamic Application Security Testing (DAST)](../user/application_security/dast/index.md) supports a reduced set of analyzers. Browser-based and proxy-based analyzers are not available in FIPS mode today, however DAST API and DAST API Fuzzing images are available.
- [License compliance](../user/compliance/license_compliance/index.md).
- [Solutions for vulnerabilities](../user/application_security/vulnerabilities/index.md#resolve-a-vulnerability)
  for yarn projects.
- [Static Application Security Testing (SAST)](../user/application_security/sast/index.md)
  supports a reduced set of [analyzers](../user/application_security/sast/index.md#fips-enabled-images)
  when operating in FIPS-compliant mode.
- Advanced search is currently not included in FIPS mode. It must not be enabled to be FIPS-compliant.
- [Gravatar or Libravatar-based profile images](../administration/libravatar.md) are not FIPS-compliant.

Additionally, these package repositories are disabled in FIPS mode:

- [Conan package repository](../user/packages/conan_repository/index.md).
- [Debian package repository](../user/packages/debian_repository/index.md).

## FIPS validation at GitLab

Unlike FIPS compliance, FIPS validation is a formal declaration of compliance by
an accredited auditor. The requirements needed to pass the audit are the same as
for FIPS compliance.

A list of FIPS-validated modules can be found at the
NIST (National Institute of Standards and Technology)
[cryptographic module validation program](https://csrc.nist.gov/projects/cryptographic-module-validation-program/validated-modules).

## Install GitLab with FIPS compliance

This guide is specifically for public users or GitLab team members with a requirement
to run a production instance of GitLab that is FIPS compliant. This guide outlines
a hybrid deployment using elements from both Omnibus and our Cloud Native GitLab installations.

### Prerequisites

- Amazon Web Services account. Our first target environment is running on AWS, and uses other FIPS Compliant AWS resources.
- Ability to run Ubuntu 20.04 machines for GitLab. Our first target environment uses the hybrid architecture.

### Set up a FIPS-enabled cluster

You can use the [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) to spin
up a FIPS-enabled cluster for development and testing. As mentioned in the prerequisites, these instructions use Amazon Web Services (AWS)
because that is the first target environment.

#### Set up your environment

To get started, your AWS account must subscribe to a FIPS-enabled Amazon
Machine Image (AMI) in the [AWS Marketplace console](https://aws.amazon.com/premiumsupport/knowledge-center/launch-ec2-marketplace-subscription/).

This example assumes that the `Ubuntu Pro 20.04 FIPS LTS` AMI by
`Canonical Group Limited` has been added your account. This operating
system is used for virtual machines running in Amazon EC2.

#### Omnibus

The simplest way to get a FIPS-enabled GitLab cluster is to use an Omnibus reference architecture.
See the [GET Quick Start Guide](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_quick_start_guide.md)
for more details. The following instructions build on the Quick Start and are also necessary for [Cloud Native Hybrid](#cloud-native-hybrid) installations.

##### Terraform: Use a FIPS AMI

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

##### Ansible: Specify the FIPS Omnibus builds

The standard Omnibus GitLab releases build their own OpenSSL library, which is
not FIPS-validated. However, we have nightly builds that create Omnibus packages
that link against the operating system's OpenSSL library. To use this package,
update the `gitlab_edition` and `gitlab_repo_script_url` fields in the Ansible
`vars.yml`. For example, you might modify
`gitlab-environment-toolkit/ansible/environments/gitlab-10k/inventory/vars.yml`
in this way:

```yaml
all:
  vars:
    ...
    gitlab_repo_script_url: "https://packages.gitlab.com/install/repositories/gitlab/gitlab-fips/script.deb.sh"
    gitlab_edition: "gitlab-fips"
```

#### Cloud Native Hybrid

A Cloud Native Hybrid install uses both Omnibus and Cloud Native GitLab
(CNG) images. The previous instructions cover the Omnibus part, but two
additional steps are needed to enable FIPS in CNG:

1. Use a custom Amazon Elastic Kubernetes Service (EKS) AMI.
1. Use GitLab containers built with RedHat's Universal Base Image (UBI).

##### Build a custom EKS AMI

Because Amazon does not yet publish a FIPS-enabled AMI, you have to
build one yourself with Packer.

Amazon publishes the following Git repositories with information about custom EKS AMIs:

- [Amazon EKS AMI Build Specification](https://github.com/awslabs/amazon-eks-ami)
- [Sample EKS custom AMIs](https://github.com/aws-samples/amazon-eks-custom-amis/)

This [GitHub pull request](https://github.com/awslabs/amazon-eks-ami/pull/898) makes
it possible to create an Amazon Linux 2 EKS AMI with FIPS enabled for Kubernetes v1.21.
To build an image:

1. [Install Packer](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli).
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

##### Terraform: Use a custom EKS AMI

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

##### Ansible: Use UBI images

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

Now create `charts.yml` in the location specified above and specify tags with a `-fips` suffix.

See our [Charts documentation on FIPS](https://docs.gitlab.com/charts/advanced/fips/index.html) for more details, including
an [example values file](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/fips/values.yaml) as a reference.

You can also use release tags, but the versioning is tricky because each
component may use its own versioning scheme. For example, for GitLab v15.2:

```yaml
global:
  image:
    tagSuffix: -fips
  certificates:
    image:
      tag: 20211220-r0
  kubectl:
    image:
      tag: 1.18.20

gitlab:
  gitaly:
    image:
      tag: v15.2.0
  gitlab-exporter:
    image:
      tag: 11.17.1
  gitlab-shell:
    image:
      tag: v14.9.0
  gitlab-mailroom:
    image:
      tag: v15.2.0
  gitlab-pages:
    image:
      tag: v1.61.0
  migrations:
    image:
      tag: v15.2.0
  sidekiq:
    image:
      tag: v15.2.0
  toolbox:
    image:
      tag: v15.2.0
  webservice:
    image:
      tag: v15.2.0
    workhorse:
      tag: v15.2.0
```

## FIPS Performance Benchmarking

The Quality Engineering Enablement team assists these efforts by checking if FIPS-enabled environments perform well compared to non-FIPS environments.

Testing shows an impact in some places, such as Gitaly SSL, but it's not large enough to impact customers.

You can find more information on FIPS performance benchmarking in the following issue:

- [Benchmark performance of FIPS reference architecture](https://gitlab.com/gitlab-org/gitlab/-/issues/364051#note_1010450415)

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

You should be able to open a web browser inside the virtual machine and sign in
to the GitLab instance.

You can disable FIPS mode again by running this command, then restarting the
virtual machine:

```shell
fips-mode-setup --disable
```

#### Detect FIPS enablement in code

You can query `Gitlab::FIPS` in Ruby code to determine if the instance is FIPS-enabled:

```ruby
def default_min_key_size(name)
  if Gitlab::FIPS.enabled?
    Gitlab::SSHPublicKey.supported_sizes(name).select(&:positive?).min || -1
  else
    0
  end
end
```

## Omnibus FIPS packages

GitLab has a dedicated repository
([`gitlab/gitlab-fips`](https://packages.gitlab.com/gitlab/gitlab-fips))
for builds of the Omnibus GitLab which are built with FIPS compliance.
These GitLab builds are compiled to use the system OpenSSL, instead of
the Omnibus-embedded version of OpenSSL. These packages are built for:

- RHEL 8 (and compatible)
- AmazonLinux 2
- Ubuntu

These are [consumed by the GitLab Environment Toolkit](#install-gitlab-with-fips-compliance) (GET).

See [the section on how FIPS builds are created](#how-fips-builds-are-created).

### Nightly Omnibus FIPS builds

The Distribution team has created [nightly FIPS Omnibus builds](https://packages.gitlab.com/gitlab/nightly-fips-builds),
which can be used for *testing* purposes. These should never be used for production environments.

## Runner

See the [documentation on installing a FIPS-compliant GitLab Runner](https://docs.gitlab.com/runner/install/#fips-compliant-gitlab-runner).

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

Google maintains a [`dev.boringcrypto` branch](https://github.com/golang/go/tree/dev.boringcrypto) in the Go compiler
that makes it possible to statically link BoringSSL, a FIPS-validated module forked from OpenSSL.
However, BoringSSL is not intended for public use.

We use [`golang-fips`](https://github.com/golang-fips/go), [a fork of the `dev.boringcrypto` branch](https://github.com/golang/go/blob/2fb6bf8a4a51f92f98c2ae127eff2b7ac392c08f/README.boringcrypto.md) to build Go programs that
[dynamically link OpenSSL via `dlopen`](https://github.com/golang-fips/go/blob/go1.18.1-1-openssl-fips/src/crypto/internal/boring/boring.go#L47-L65). This has several advantages:

- Using a FIPS-validated, system OpenSSL is straightforward.
- This is the source code used by [Red Hat's go-toolset package](https://gitlab.com/redhat/centos-stream/rpms/golang#sources).
- Unlike [go-toolset](https://developers.redhat.com/blog/2019/06/24/go-and-fips-140-2-on-red-hat-enterprise-linux#), this fork appears to keep up with the latest Go releases.

However, [cgo](https://pkg.go.dev/cmd/cgo) must be enabled via `CGO_ENABLED=1` for this to work. There
is a performance hit when calling into C code.

Projects that are compiled with `golang-fips` on Linux x86 automatically
get built the crypto routines that use OpenSSL. While the `boringcrypto`
build tag is automatically present, no extra build tags are actually
needed. There are [specific build tags](https://github.com/golang-fips/go/blob/go1.18.1-1-openssl-fips/src/crypto/internal/boring/boring.go#L6)
that disable these crypto hooks.

We can [check whether a given binary is using OpenSSL](https://go.googlesource.com/go/+/dev.boringcrypto/misc/boring/#caveat) via `go tool nm`
and look for symbols named `Cfunc__goboringcrypto`. For example:

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

In addition, LabKit contains routines to [check whether FIPS is enabled](https://gitlab.com/gitlab-org/labkit/-/tree/master/fips).

## How FIPS builds are created

Many GitLab projects (for example: Gitaly, GitLab Pages) have
standardized on using `FIPS_MODE=1 make` to build FIPS binaries locally.

### Omnibus

The Omnibus FIPS builds are triggered with the `USE_SYSTEM_SSL`
environment variable set to `true`. When this environment variable is
set, the Omnibus recipes dependencies such as `curl`, NGINX, and libgit2
will link against the system OpenSSL. OpenSSL will NOT be included in
the Omnibus build.

The Omnibus builds are created using container images [that use the `golang-fips` compiler](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/-/blob/master/docker/snippets/go_fips). For
example, [this job](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/-/jobs/2363742108) created
the `registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/centos_8_fips:3.3.1` image used to
build packages for RHEL 8.

#### Add a new FIPS build for another Linux distribution

First, you need to make sure there is an Omnibus builder image for the
desired Linux distribution. The images used to build Omnibus packages are
created with [Omnibus Builder images](https://gitlab.com/gitlab-org/gitlab-omnibus-builder).

Review [this merge request](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/-/merge_requests/218). A
new image can be added by:

1. Adding CI jobs with the `_fips` suffix (for example: `ubuntu_18.04_fips`).
1. Making sure the `Dockerfile` uses `Snippets.new(fips: fips).populate` instead of `Snippets.new.populate`.

After this image has been tagged, add a new [CI job to Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/911fbaccc08398dfc4779be003ea18014b3e30e9/gitlab-ci-config/dev-gitlab-org.yml#L594-602).

### Cloud Native GitLab (CNG)

The Cloud Native GitLab CI pipeline generates images using several base images:

- Debian
- [Red Hat's Universal Base Image (UBI)](https://developers.redhat.com/products/rhel/ubi)

UBI images ship with the same OpenSSL package as those used by
RHEL. This makes it possible to build FIPS-compliant binaries without
needing RHEL. Note that RHEL 8.2 ships a [FIPS-validated OpenSSL](https://access.redhat.com/articles/2918071), but 8.5 is in
review for FIPS validation.

[This merge request](https://gitlab.com/gitlab-org/build/CNG/-/merge_requests/981)
introduces a FIPS pipeline for CNG images. Images tagged for FIPS have the `-fips` suffix. For example,
the `webservice` container has the following tags:

- `master`
- `master-ubi8`
- `master-fips`

### Testing merge requests with a FIPS pipeline

Merge requests that can trigger Package and QA, can trigger a FIPS package and a
Reference Architecture test pipeline. The base image used for the trigger is
Ubuntu 20.04 FIPS:

1. Trigger `e2e:package-and-test` job, if not already triggered.
1. On the `gitlab-omnibus-mirror` child pipeline, manually trigger `Trigger:package:fips`.
1. When the package job is complete, manually trigger the `RAT:FIPS` job.
