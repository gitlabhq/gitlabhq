# GitLab EE Omnibus packages

Below are the [gitlab-omnibus packages](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md) for GitLab Enterprise Edition.

Installation instructions are similar to the [CE Omnibus package instructions](https://about.gitlab.com/downloads/) after choosing an OS (of course your package name is different).
[Update instructions](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/update.md) can be found in the GitLab Omnibus documentation.
The [GitLab Omnibus Readme](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md) contains troubleshooting information and configuration options.

Please contact <subscribers@gitlab.com> if you have any questions.

## RPM 'package is already installed' error

If you are using RPM and you are upgrading from GitLab Community Edition you may get an error like this:

```
package gitlab-7.6.3_omnibus.5.3.0.ci-1.el7.x86_64 (which is newer than gitlab-7.5.3_ee.omnibus.5.2.1.ci-1.el7.x86_64) is already installed
```

You can override this version check with the `--oldpackage` option:

```
rpm -Uvh --oldpackage gitlab-7.5.3_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm
```

### GitLab 7.6.3 Enterprise Edition

- 7.6.3-ee/CI 5.3.0 - Ubuntu 14.04 64-bit [gitlab_7.6.3-ee.omnibus.5.3.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/3ed4b729ff7d7e45e845399901666e1c32fe6c25/ubuntu-14.04/gitlab_7.6.3-ee.omnibus.5.3.0.ci-1_amd64.deb)
+ SHA256: 5fc2e12b9eddee53385300c4596deaf82cd592ae154df2e25c9e4150dca90c61

- 7.6.3-ee/CI 5.3.0 - Ubuntu 12.04 64-bit [gitlab_7.6.3-ee.omnibus.5.3.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/aa09725dc1fdd5bcb2cd62835ad808b0c6fa1773/ubuntu-12.04/gitlab_7.6.3-ee.omnibus.5.3.0.ci-1_amd64.deb)
+ SHA256: 7e2c91e5bd34ef7fff3808e1ea503f70dca88b9d39d10419036922a62cc8cf04

- 7.6.3-ee/CI 5.3.0 - Debian 7 64-bit [gitlab_7.6.3-ee.omnibus.5.3.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/f8a9865824f4bbb758ae0204c23f4aa4b4c3d0ee/debian-7.7/gitlab_7.6.3-ee.omnibus.5.3.0.ci-1_amd64.deb)
+ SHA256: 48a894ea20113fc25e52a82bd98561402194b8ba20422ba3db5d7b918f7ef644

- 7.6.3-ee/CI 5.3.0 - CentOS 6 64-bit [gitlab-7.6.3_ee.omnibus.5.3.0.ci-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/a43a43353d96e7dd845e056af6e0f32692d1b9f1/centos-6.6/gitlab-7.6.3_ee.omnibus.5.3.0.ci-1.el6.x86_64.rpm)
+ SHA256: 9fcc935d7f6db8eaafe25e441ee77ebdbc26d5a3b8886fd060c8c32133bdbdbe

- 7.6.3-ee/CI 5.3.0 - CentOS 7 64-bit [gitlab-7.6.3_ee.omnibus.5.3.0.ci-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/6bddc4ef501939a7d5624f2784ec60d11490c1fe/centos-7.0.1406/gitlab-7.6.3_ee.omnibus.5.3.0.ci-1.el7.x86_64.rpm)
+ SHA256: b80a25250ab93f53825fc6f68c89ce01b2d641c0ae2ffe204eeafdea5058e87e


### GitLab 7.6.2 Enterprise Edition

- 7.6.2-ee/CI 5.3.0 - Ubuntu 14.04 64-bit [gitlab_7.6.2-ee.omnibus.5.3.0.ci.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/44449a1cd473eb3f6f79dd88e57d5b8254c4a16d/ubuntu-14.04/gitlab_7.6.2-ee.omnibus.5.3.0.ci.1-1_amd64.deb)
+ SHA256: 3254c613e356b58b040aa2695af78f036dde83d05150ccae1d3021e223709210

- 7.6.2-ee/CI 5.3.0 - Ubuntu 12.04 64-bit [gitlab_7.6.2-ee.omnibus.5.3.0.ci.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/4dffcf1fe07b5825f9c94c9efc02c675757057e3/ubuntu-12.04/gitlab_7.6.2-ee.omnibus.5.3.0.ci.1-1_amd64.deb)
+ SHA256: 92af46677254b58ec33a333eb6c2915fd80724165b4b732e1660ee3b129c7c8d

- 7.6.2-ee/CI 5.3.0 - Debian 7 64-bit [gitlab_7.6.2-ee.omnibus.5.3.0.ci.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/1b7f1f2e0726908205abfffee87315c3a40e1e08/debian-7.7/gitlab_7.6.2-ee.omnibus.5.3.0.ci.1-1_amd64.deb)
+ SHA256: 4fd62c0ce1db6bd5bdce8b64e236cb8f7d2bc251a20f853a9bf3a407858748af

- 7.6.2-ee/CI 5.3.0 - CentOS 6 64-bit [gitlab-7.6.2_ee.omnibus.5.3.0.ci.1-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/455b87ddd5459b8bdbd86cdabdb5e1c6783c3592/centos-6.6/gitlab-7.6.2_ee.omnibus.5.3.0.ci.1-1.el6.x86_64.rpm)
+ SHA256: 64110aaad20ba52f81dd5011bfadb960b6e1047bb2aaa8c8e39dd0d5a1475efc

- 7.6.2-ee/CI 5.3.0 - CentOS 7 64-bit [gitlab-7.6.2_ee.omnibus.5.3.0.ci.1-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/8f9278f7796b060acc0a116b6bc424cbcfd64698/centos-7.0.1406/gitlab-7.6.2_ee.omnibus.5.3.0.ci.1-1.el7.x86_64.rpm)
+ SHA256: 073385056fd0659c4f15ffd368b8b9e9f2b80a3fb211adfd06203811de082bf4


### GitLab 7.6.0 Enterprise Edition

- 7.6.0-ee/CI 5.3.0 - Ubuntu 14.04 64-bit [gitlab_7.6.0-ee.omnibus.5.3.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/fadbb1570f35a76e8b57435bb9f3bfc321b59956/ubuntu-14.04/gitlab_7.6.0-ee.omnibus.5.3.0.ci-1_amd64.deb)
    + SHA256: 72e961070688763391aafd28a94ca893b74a2f612b64f9e2d5c7aa3b972ee6ed

- 7.6.0-ee/CI 5.3.0 - Ubuntu 12.04 64-bit [gitlab_7.6.0-ee.omnibus.5.3.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/0af6270fbc92e3fc2ff621547187b852f2a0be7a/ubuntu-12.04/gitlab_7.6.0-ee.omnibus.5.3.0.ci-1_amd64.deb)
    + SHA256: 306205a5f4ebab40f423f02957d0ca1a6a899d50aaabfceac121e76bfba2e775

- 7.6.0-ee/CI 5.3.0 - Debian 7 64-bit [gitlab_7.6.0-ee.omnibus.5.3.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/5d7f757633a09bb172c5e55b0a7efc7a729927e1/debian-7.7/gitlab_7.6.0-ee.omnibus.5.3.0.ci-1_amd64.deb)
    + SHA256: 2da8df98000ea4e217e08533911f28ade2c278f8c5d7717f7a8bc9911c810530

- 7.6.0-ee/CI 5.3.0 - CentOS 6 64-bit [gitlab-7.6.0_ee.omnibus.5.3.0.ci-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/9ff0148bbf7b3f327c05ce0e4b5fdc938eb1bd7c/centos-6.6/gitlab-7.6.0_ee.omnibus.5.3.0.ci-1.el6.x86_64.rpm)
    + SHA256: fcc92c8b3723217dcad8677cea3d2f2b54cade6c235668a0bc2b11773fd3c052

#### Note: GitLab 7.6 EE for Centos 7 will be released later today

- 7.5.3-ee/CI 5.2.1 - CentOS 7 64-bit [gitlab-7.5.3_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/f08d577a156a0bf4ef06f4b42586a94707d2e456/centos-7.0.1406/gitlab-7.5.3_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm)
    + SHA256: d3e734f37841b38f37892ea5557a7c707f0e7bba8bf5f70869f309bd8f21120a


## Previous versions

### GitLab 7.4.6 Enterprise Edition

- 7.4.6-ee/CI 5.1.0 - Ubuntu 14.04 64-bit [gitlab-7.4.6_ee.omnibus.5.1.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/3875dd67b6c26a06023f411702185a941ead44f3/ubuntu-14.04/gitlab_7.4.6-ee.omnibus.5.1.0.ci-1_amd64.deb)
+ SHA256: 2f3f06b8e6b100b6f75c38e3408d74091b4b1385ae8c898673fabe982d1ee34b

- 7.4.6-ee/CI 5.1.0 - Ubuntu 12.04 64-bit [gitlab-7.4.6_ee.omnibus.5.1.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/00a23b658c73c8848d22fb5de8ac9708e5b2c0e6/ubuntu-12.04/gitlab_7.4.6-ee.omnibus.5.1.0.ci-1_amd64.deb)
+ SHA256: 1a5ee42c7c8f164251a83b3926b80476dd8afebdc24a27bf12e9321197e0ac66

- 7.4.6-ee/CI 5.1.0 - Debian 7 64-bit [gitlab-7.4.6_ee.omnibus.5.1.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/d0f6a7b0a4cf2642756aaafb91b2abab134672c2/debian-7.7/gitlab_7.4.6-ee.omnibus.5.1.0.ci-1_amd64.deb)
+ SHA256: 0c563b3d89dcd574dae72562b083a67ec374b1c93b3ccc50050203d904f3a471

- 7.4.6-ee/CI 5.1.0 - CentOS 6 64-bit [gitlab-7.4.6_ee.omnibus.5.1.0.ci-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/dfb1070550739e77367e12b528207f97ed3a158f/centos-6.6/gitlab-7.4.6_ee.omnibus.5.1.0.ci-1.el6.x86_64.rpm)
+ SHA256: 1847d52ffc3a862066a413c12833333d34525e8fa4707c7bfe22e15179174ea8

- 7.4.6-ee/CI 5.1.0 - CentOS 7 64-bit [gitlab-7.4.6_ee.omnibus.5.1.0.ci-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/8f9a976a0ae3322b32752d1e3b0c76222ba48e8ea31/centos-7.0.1406/gitlab-7.4.6_ee.omnibus.5.1.0.ci-1.el7.x86_64.rpm)
+ SHA256: 60ba7c397af0ebeafd4a898c175d9019d8cbaeed4dcdc7b4dfacdc9791129593


### GitLab 7.3.3 Enterprise Edition

- 7.3.3-ee - Ubuntu 14.04 64-bit [gitlab_7.3.3-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/bde0df299cc8c125a106d2615d75c466d458fe05/ubuntu-14.04/gitlab_7.3.3-ee.omnibus-1_amd64.deb)
+ SHA256: f0c7b7f462c951804760b1c664ea7fc854196c3ddbc337736cffb005b8cd3a88

- 7.3.3-ee - Ubuntu 12.04 64-bit [gitlab_7.3.3-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/245895117161c7ac18ab4a27ad518dc1f1777d27/ubuntu-12.04/gitlab_7.3.3-ee.omnibus-1_amd64.deb)
+ SHA256: c6cfddcdc8c52619dd8a95a75cc78df3063156499753164093d4110f116bad7d

- 7.3.3-ee - Debian 7 64-bit [gitlab_7.3.3-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/cc0679428691ad9081e28857b1e54b6b5bd80f5c/debian-7.7/gitlab_7.3.3-ee.omnibus-1_amd64.deb)
+ SHA256: 2f21da13205c67ded5963449d85862343b0e49b34e63badf9b37dd2cc57a6d75

- 7.3.3-ee - CentOS 6 64-bit [gitlab_7.3.3-ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/292ae078187c5adac9e35c30015c5f90e53fad15/centos-6.6/gitlab-7.3.3_ee.omnibus-1.el6.x86_64.rpm)
+ SHA256: 2b7f5db728894a0669af16b966c61a5ce1eb77ea8ed53a3c9ac1c49cab887bec

- 7.3.3-ee - CentOS 7 64-bit [gitlab_7.3.3-ee.omnibus-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/867df830f19339be1ca20d644b79816ad470ed68/centos-7.0.1406/gitlab-7.3.3_ee.omnibus-1.el7.x86_64.rpm)
+ SHA256: 60ddd93769779fccd7e9fe9ee027f9b847164e3df1864a77400c28f1de121027


### GitLab 7.2.3 Enterprise Edition

- 7.2.3-ee - Ubuntu 14.04 64-bit [gitlab_7.2.3-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/9a6072ca2b3055659efa5884b48fc7be0977629d/ubuntu-14.04/gitlab_7.2.3-ee.omnibus-1_amd64.deb)
+ SHA256: edcc1cc2bad2a1a17500686a4f64fa7ae67e7ea607136fcf151560bfe0ee998a

- 7.2.3-ee - Ubuntu 12.04 64-bit [gitlab_7.2.3-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/1ea4883b92e852a06631c575e037f72e0ae28da0/ubuntu-12.04/gitlab_7.2.3-ee.omnibus-1_amd64.deb)
+ SHA256: babd0cb55c63ed120f359da588dc314de239b31b5b9edc55a6c91929253f7207

- 7.2.3-ee - Debian 7 64-bit [gitlab_7.2.3-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/1e2b5da32e32a93ce16db306cbe0b81d90166a10/debian-7.7/gitlab_7.2.3-ee.omnibus-1_amd64.deb)
+ SHA256: 19a6e96456ad193f1468e8d58f0db79d526d8225953c7b8781561e283ed5cc9e

- 7.2.3-ee - CentOS 6 64-bit [gitlab_7.2.3-ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/3126e2ed3b6a00b7651f4ce916546967230e23a6/centos-6.6/gitlab-7.2.3_ee.omnibus-1.el6.x86_64.rpm)
+ SHA256: ea7c3f7f276d6300075d5f59037863e6dc8e310dc2194ed0e9d29b24ce182c11

- 7.2.3-ee - CentOS 7 64-bit [gitlab_7.2.3-ee.omnibus-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/e4a2bdfc28dca7ba3cb8f4b8b7251a91fc4deb5c/centos-7.0.1406/gitlab-7.2.3_ee.omnibus-1.el7.x86_64.rpm)
+ SHA256: 46ef77bc0677caf1c6361216fe56bcc4710c8b43f6f8c82ffc96f698c89ed866




### Ubuntu 14.04 64-bit

- 7.5.3-ee/CI 5.2.1 - Ubuntu 14.04 64-bit [gitlab_7.5.3-ee.omnibus.5.2.1.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/05998bb8ba9cca0ef22c90f4529c875003c51f23/ubuntu-14.04/gitlab_7.5.3-ee.omnibus.5.2.1.ci-1_amd64.deb)
    + SHA256: 5aa2e0c7ff9b48344d2d5bf62dd4fbff09ccd95c010331e12da78e2cd73cf430

- 7.5.2-ee/CI 5.2.1 - Ubuntu 14.04 64-bit [gitlab_7.5.2-ee.omnibus.5.2.1.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/e864efcad31bc4ede2c1e1fc8bba8951e4468e5f/ubuntu-14.04/gitlab_7.5.2-ee.omnibus.5.2.1.ci-1_amd64.deb)
    + SHA256: 70e04525b4c55eb55567f2c45b09a2ce31a1d5a59296947d86706656e79f8ae3

- 7.5.1-ee/CI 5.2.0 - Ubuntu 14.04 64-bit [gitlab_7.5.1-ee.omnibus.5.2.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/3da7e4fb16f1a15de137a5ac5d4cb4a39cef536c/ubuntu-14.04/gitlab_7.5.1-ee.omnibus.5.2.0.ci-1_amd64.deb)
    + SHA256: 834e9478e7dd6862cd9ce61c7179eb765b66d7ebe61c493ffd44e15b79f287b8

- 7.4.5-ee/CI 5.1.0 - Ubuntu 14.04 64-bit [gitlab_7.4.5-ee.omnibus.5.1.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/9ac1901f0e346f5c795262368450fda9b1f7bbb9/ubuntu-14.04/gitlab_7.4.5-ee.omnibus.5.1.0.ci-1_amd64.deb)
    + SHA256: 8e44f7cc87a73f007c882f5f9147294073a7ea58a805d9a3cb43d1ed1e0d9dfe

- 7.4.4-ee/CI 5.1.0 - Ubuntu 14.04 64-bit [gitlab_7.4.4-ee.omnibus.5.1.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/2a880962cd18293a9da61ab884c29cbdd7eebdba/ubuntu-14.04/gitlab_7.4.4-ee.omnibus.5.1.0.ci-1_amd64.deb)
    + MD5: d549fdaa96e53a2a98cb91676076259a

- 7.4.3-ee/CI 5.1.0 - Ubuntu 14.04 64-bit [gitlab_7.4.3-ee.omnibus.5.1.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/fca7e66f323d8fbffbd86fbb26a6f60eab891dc9/ubuntu-14.04/gitlab_7.4.3-ee.omnibus.5.1.0.ci-1_amd64.deb)
    + MD5: 7bd15c589f9fb81750c5fc77d3f9881f

- 7.4.3-ee - Ubuntu 14.04 64-bit [gitlab_7.4.3-ee.omnibus.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/7ebaadae0ea2ca05971a80e5000877943bb1fbfc/ubuntu-14.04/gitlab_7.4.3-ee.omnibus.1-1_amd64.deb)
    + MD5: 639e9519a9cd0629685ac16db8d68b5c

- 7.4.2-ee - Ubuntu 14.04 64-bit [gitlab_7.4.2-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/e38dad05abb276453da95d78fa1eaa41d783f390/ubuntu-14.04/gitlab_7.4.2-ee.omnibus-1_amd64.deb)
    + MD5: 7a28adaf0fc96e86fafe4a363484fe07

- 7.4.1-ee - Ubuntu 14.04 64-bit [gitlab_7.4.1-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/d6e0332c065645b2ac380890f8406224377cbcfc/ubuntu-14.04/gitlab_7.4.1-ee.omnibus-1_amd64.deb)
    + MD5: aa39962db5c6e9b5f56a6c592927d338

- 7.4.0-ee - Ubuntu 14.04 64-bit [gitlab_7.4.0-ee.omnibus.2-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/7839c59170801447b308694628378151a988ce75/ubuntu-14.04/gitlab_7.4.0-ee.omnibus.2-1_amd64.deb)
    + MD5: e091774fdd2649f3a839bef1c608399f

- 7.3.2-ee - Ubuntu 14.04 64-bit [gitlab_7.3.2-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/b4d37ee804679cdd21b3cf5c83c43ca0f40ae2a6/ubuntu-14.04/gitlab_7.3.2-ee.omnibus-1_amd64.deb)
    + MD5: 53539f5f7833a760a9918633ca8c9be5

- 7.3.1-ee - Ubuntu 14.04 64-bit [gitlab_7.3.1-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/50d2c5178c423a141f316f52e3447aefc017c77b/ubuntu-14.04/gitlab_7.3.1-ee.omnibus-1_amd64.deb)
    + MD5: e4342b4a4d7192f8f7eb04816eba6c29

- 7.3.0-ee - Ubuntu 14.04 64-bit [gitlab_7.3.0-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/bb2502342d24cc9ffd773946f7f3027be60cf612/ubuntu-14.04/gitlab_7.3.0-ee.omnibus-1_amd64.deb)
    + MD5: 6d46e3ec4051fe2fa616baf6bdf7d594

- 7.2.2-ee - Ubuntu 14.04 64-bit [gitlab_7.2.2-ee.omnibus.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/e542352a629ad69f12d29476c85f6abb27202136/ubuntu-14.04/gitlab_7.2.2-ee.omnibus-1_amd64.deb)
    + MD5: 1612bc8b722e9e01d27845f0e1102758

- 7.2.1-ee - Ubuntu 14.04 64-bit [gitlab_7.2.1-ee.omnibus.2-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/b88dc7319205954b71fe53e15e0cee5211e399d3/ubuntu-14.04/gitlab_7.2.1-ee.omnibus.2-1_amd64.deb)
    + MD5: 22b3120d14b29495741a6c04dbc88f7d

- 7.2.0-ee - Ubuntu 14.04 64-bit [gitlab_7.2.0-ee.omnibus.2-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/f8bfb6cafa08687822786ff5be822c8b36a656f5/ubuntu-14.04/gitlab_7.2.0-ee.omnibus.2-1_amd64.deb)
    + MD5: 356263bdfe56c9bed04096c40ca3a8a2

- 7.1.1-ee - Ubuntu 14.04 64-bit [gitlab_7.1.1-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/fe636f5b18be2a47198278337547124405e05051/ubuntu-14.04/gitlab_7.1.1-ee.omnibus-1_amd64.deb)
    + MD5: 4b005d4f7e92538663e993f97e9f94be

- 7.1.0-ee - Ubuntu 14.04 64-bit [gitlab_7.1.0-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/2b86ee72a2b5f469a453d4dcb2e7a54dd6d1945d/ubuntu-14.04/gitlab_7.1.0-ee.omnibus-1_amd64.deb)
    + MD5: 46372eb1f620985d199b7c364d211625

- 7.0.1-ee - Ubuntu 14.04 64-bit [gitlab_7.0.1-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/0c687476e83a80fa4fa717ad5881f41e31a41eb0/ubuntu-14.04/gitlab_7.0.1-ee.omnibus-1_amd64.deb)
    + MD5: 547d15f7a6bb05ce0b3b0776c99eb40c

- 7.0.0-ee - Ubuntu 14.04 64-bit [gitlab_7.0.0-ee.omnibus.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/7e416d0421a055dc87c471d9be981c8959615406/ubuntu-14.04/gitlab_7.0.0-ee.omnibus.1-1_amd64.deb)
    - MD5: 0a0a821a166dc08499359a72daf2aa88

### Ubuntu 12.04 64-bit

- 7.5.3-ee/CI 5.2.1 - Ubuntu 12.04 64-bit [gitlab_7.5.3-ee.omnibus.5.2.1.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/b8b21efced5fb783a8fdb67f6e62abe9b4a355f5/ubuntu-12.04/gitlab_7.5.3-ee.omnibus.5.2.1.ci-1_amd64.deb)
    + SHA256: a502347f3cde250e875dd378d83dd180ecaf02adb997c89401209b779b8f3764

- 7.5.2-ee/CI 5.2.1 - Ubuntu 12.04 64-bit [gitlab_7.5.2-ee.omnibus.5.2.1.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/3d414be81496a7c8e7ca5643a23d49787055241e/ubuntu-12.04/gitlab_7.5.2-ee.omnibus.5.2.1.ci-1_amd64.deb)
    + SHA256: abc84afdcfae11325944c037e9b070d6fd63e630d8a64627316aa056a2f1dfaa

- 7.5.1-ee/CI 5.2.0 - Ubuntu 12.04 64-bit [gitlab_7.5.1-ee.omnibus.5.2.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/d657214f75cfafb1e6e47f179fca394fd8c3c34e/ubuntu-12.04/gitlab_7.5.1-ee.omnibus.5.2.0.ci-1_amd64.deb)
    + SHA256: 843e177375f8d2f2b149405dfbd65f023952938cf017d4f8946b7badf98220a2

- 7.4.5-ee/CI 5.1.0 - Ubuntu 12.04 64-bit [gitlab_7.4.5-ee.omnibus.5.1.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/16e535efc9f100d6acafa651e28180c6573197f3/ubuntu-12.04/gitlab_7.4.5-ee.omnibus.5.1.0.ci-1_amd64.deb)
    + SHA256: 92fa8eb59efc6ae901a13ad47712061edd468d111e197517a7d96309a6798152

- 7.4.4-ee/CI 5.1.0 - Ubuntu 12.04 64-bit [gitlab_7.4.4-ee.omnibus.5.1.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/e99bcfc0601b020fc7d218bcd2e76fbcbc66c9d8/ubuntu-12.04/gitlab_7.4.4-ee.omnibus.5.1.0.ci-1_amd64.deb)
    + MD5: 61cc01a792a0b649e5bfb51bd63adb12

- 7.4.3-ee/CI 5.1.0 - Ubuntu 12.04 64-bit [gitlab_7.4.3-ee.omnibus.5.1.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/e48726116808fc8b4e859aacf32bd7f12a569eab/ubuntu-12.04/gitlab_7.4.3-ee.omnibus.5.1.0.ci-1_amd64.deb)
    + MD5: fcc033b7db38f5afc5bd21b991227ef1

- 7.4.3-ee - Ubuntu 12.04 64-bit [gitlab_7.4.3-ee.omnibus.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/d6cdce3171b469c3198828a6167f49d380817d18/ubuntu-12.04/gitlab_7.4.3-ee.omnibus.1-1_amd64.deb)
    + MD5: 1f01c05c238f380c546ffe8a767e5d48

- 7.4.2-ee - Ubuntu 12.04 64-bit [gitlab_7.4.2-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/cd86d1cb6d76231403ca0fba4ded395a6c753b9b/ubuntu-12.04/gitlab_7.4.2-ee.omnibus-1_amd64.deb)
    + MD5: 4851d59c5b304570eafd7ca1c4ce1617

- 7.4.1-ee - Ubuntu 12.04 64-bit [gitlab_7.4.1-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/fe8289d8a2ca90b5839012296ff1a89c4c58c5bd/ubuntu-12.04/gitlab_7.4.1-ee.omnibus-1_amd64.deb)
    + MD5: ee324001283b52d2d0dfd8ccba71d77e

- 7.4.0-ee - Ubuntu 12.04 64-bit [gitlab_7.4.0-ee.omnibus.2-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/417446d069cba775a883d22ea22955ac3e93d24a/ubuntu-12.04/gitlab_7.4.0-ee.omnibus.2-1_amd64.deb)
    + MD5: 879a821076353bc92add2e539ea0f6d1

- 7.3.2-ee - Ubuntu 12.04 64-bit [gitlab_7.3.2-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/c58e302c165ff0ee6eec240b6b6b15d02d82cd18/ubuntu-12.04/gitlab_7.3.2-ee.omnibus-1_amd64.deb)
    + MD5: 9b75edcb5c066bee223d69a3abd62256

- 7.3.1-ee - Ubuntu 12.04 64-bit [gitlab_7.3.1-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/84b514bea64be8ee065c222d318d7d37c237985e/ubuntu-12.04/gitlab_7.3.1-ee.omnibus-1_amd64.deb)
    + MD5: 35c573d2005f7bb7aa8406405f1a8e9d

- 7.3.0-ee - Ubuntu 12.04 64-bit [gitlab_7.3.0-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/5959588d95a915ee061daee467d1bc55a6316f7e/ubuntu-12.04/gitlab_7.3.0-ee.omnibus-1_amd64.deb)
    + MD5: e7fee9727ba8bf79aeb94afd5b219510

- 7.2.2-ee - Ubuntu 12.04 64-bit [gitlab_7.2.2-ee.omnibus.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/c55c6cbc34ea446e68382ac35d96c8722d2a87cd/ubuntu-12.04/gitlab_7.2.2-ee.omnibus-1_amd64.deb)
    + MD5: b4238977da83164e56772c17ea4e9d2c

- 7.2.1-ee - Ubuntu 12.04 64-bit [gitlab_7.2.1-ee.omnibus.2-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/c64e66c88063395e407f75174dfcdc9e833f7cc8/ubuntu-12.04/gitlab_7.2.1-ee.omnibus.2-1_amd64.deb)
    + MD5: 640703e4ff1a92ff912f56e869e4a38a

- 7.2.0-ee - Ubuntu 12.04 64-bit [gitlab_7.2.0-ee.omnibus.2-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/3173c5075e937a0f7940ceaba9f48c2249c07a7c/ubuntu-12.04/gitlab_7.2.0-ee.omnibus.2-1_amd64.deb)
    + MD5: aa9b5fb8defd6d4ed77fb7e5451442d8

- 7.1.1-ee - Ubuntu 12.04 64-bit [gitlab_7.1.1-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/71e1c0e770458056dc40709bf8b986ba83c0296d/ubuntu-12.04/gitlab_7.1.1-ee.omnibus-1_amd64.deb)
    + MD5: f6b84bc60b10556344e16175a19719ef

- 7.1.0-ee - Ubuntu 12.04 64-bit [gitlab_7.1.0-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/a4416b7b2ab2a50b74062471b7969f127ae01e03/ubuntu-12.04/gitlab_7.1.0-ee.omnibus-1_amd64.deb)
    + MD5: 07271fafd97f61a2fce5343970f4b4cc

- 7.0.1-ee - Ubuntu 12.04 64-bit [gitlab_7.0.1-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/e52f5de30db26d895438b81ea13ce6a89a22b3cc/ubuntu-12.04/gitlab_7.0.1-ee.omnibus-1_amd64.deb)
    + MD5: fc32a7de460dbfb3f0249cf3e1c56056

- 7.0.0-ee - Ubuntu 12.04 64-bit [gitlab_7.0.0-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/1ad8765351d114afdc9b96f1044551d209e6742c/ubuntu-12.04/gitlab_7.0.0-ee.omnibus-1_amd64.deb)
    - MD5: 4d243a7d075d940963ad0909e60e18e5

- 6.9.4-ee - Ubuntu 12.04 64-bit [gitlab_6.9.4-ee.omnibus.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/c0139737a5ffc2725eb5f72316c1d0f1d34d8944/ubuntu-12.04/gitlab_6.9.4-ee.omnibus.1-1_amd64.deb)
    - MD5: 85c7879a5e3c368c7d9d8b5c0bd8eed0

- 6.9.3-ee - Ubuntu 12.04 64-bit [gitlab_6.9.3-ee.omnibus.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/4cc3c248f50ecfc8048209da908e5ea62252190b/ubuntu-12.04/gitlab_6.9.3-ee.omnibus.1-1_amd64.deb)
    - MD5: d5a92e909e157638f8616041de1e9ff8

- 6.9.2-ee - Ubuntu 12.04 64-bit [gitlab_6.9.2-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/513969c5bd4ae079c27b61c792a86217eeb2c443/ubuntu-12.04/gitlab_6.9.2-ee.omnibus-1_amd64
    - MD5: 074fc4c035837c5671de5fea10ecfcec

- 6.9.1-ee - Ubuntu 12.04 64-bit [gitlab_6.9.1-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/f1b162213022e7c5def15ed773e2bfdf7d420590/ubuntu-12.04/gitlab_6.9.1-ee.omnibus-1_amd64.deb)
    - MD5: 52481cfaf8c555fb296c15facaf39900

- 6.9.0-ee - Ubuntu 12.04 64-bit [gitlab_6.9.0-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/f4bfa95fe308a10298178316aa140f5623536432/ubuntu-12.04/gitlab_6.9.0-ee.omnibus-1_amd64.deb)
    - MD5: 022feef5454b35ad49b9485149122c2e

- 6.8.1-ee - Ubuntu 12.04 64-bit [gitlab_6.8.1-ee.omnibus.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/aad7786fc512593733cc3351ebf515fb6f0d0462/ubuntu-12.04/gitlab_6.8.1-ee.omnibus.1-1_amd64.deb)
    - MD5: 4b7b3487f3631a261d56dc58e1922a11

- 6.8.0-ee - Ubuntu 12.04 64-bit [gitlab_6.8.0-ee.omnibus.4-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/788d9b718e820d3196295f2801b0bbec307e68a7/ubuntu-12.04/gitlab_6.8.0-ee.omnibus.4-1_amd64.deb)
    - MD5: 9a8a99ef147f30aa92ef5dddf85dfa97

- 6.7.4-ee - Ubuntu 12.04 64-bit [gitlab_6.7.4-ee.omnibus-1.ubuntu.12.04_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/e27eb70aac3619b17ba7ade0e6bfc48e896b057f/gitlab_6.7.4-ee.omnibus-1.ubuntu.12.04_amd64.deb)
    - MD5: 16d0c4ab627638cc6d612042af4498da

- 6.7.3-ee - Ubuntu 12.04 64-bit [gitlab_6.7.3-ee.omnibus.1-1.ubuntu.12.04_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/43c6dec1146d6335c6ca90fa8679d4e63962732e/gitlab_6.7.3-ee.omnibus.1-1.ubuntu.12.04_amd64.deb)
    - MD5: 527561c7b817f3375598778368530e9a

- 6.7.2-ee - Ubuntu 12.04 64-bit [gitlab_6.7.2-ee.omnibus.2-1.ubuntu.12.04_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/91692a0c3730d22621af07670b832e3ec1df7ee9/gitlab_6.7.2-ee.omnibus.2-1.ubuntu.12.04_amd64.deb)
    - MD5: 1deb3ac65cb2f25b00b489e52bf800e6

- 6.7.2-ee - Ubuntu 12.04 64-bit [gitlab_6.7.2-ee.omnibus-1.ubuntu.12.04_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/66e5962a62e403f30b63a6a709a894fdf6f8bc33/gitlab_6.7.2-ee.omnibus-1.ubuntu.12.04_amd64.deb)
    - MD5: 24d9618767217acd39c37cb7e0ae1881

- 6.7.1-ee Ubuntu 12.04 64-bit [gitlab_6.7.1-ee.omnibus-1.ubuntu.12.04_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/6d24b1dfb3a0ac4c80a7301bd42a32faf1e9d650/gitlab_6.7.1-ee.omnibus-1.ubuntu.12.04_amd64.deb)
    - MD5: cafba48596583b023758f35eaaaf98fa

- 6.6.3-ee Ubuntu 12.04 64-bit [gitlab_6.6.3-ee.omnibus.2-1.ubuntu.12.04_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/a7dcf16bd7948d5415a9c53176f2078375dac12e/gitlab_6.6.3-ee.omnibus.2-1.ubuntu.12.04_amd64.deb)
    - MD5: cbd2a9086691f0ea2ebe47b374e84151

- 6.6.3-ee Ubuntu 12.04 64-bit [gitlab_6.6.3-ee.omnibus-1.ubuntu.12.04_amd64.deb](https://downloads-packages.s3.amazonaws.com/2601c69af9247a47334c21cb9c9e4267d21eb8e7/gitlab_6.6.3-ee.omnibus-1.ubuntu.12.04_amd64.deb)
    - MD5: de0a2cf1b9876b9c07256aa7f5692677


### CentOS 6 64-bit

- 7.5.3-ee/CI 5.2.1 - CentOS 6 64-bit [gitlab-7.5.3_ee.omnibus.5.2.1.ci-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/09755469e681f852c4a81794c6ec640ed20a7f82/centos-6.6/gitlab-7.5.3_ee.omnibus.5.2.1.ci-1.el6.x86_64.rpm)
    + SHA256: 208b46fea67029cb3bbdfca593cd5866845b1a5b68cbd0b3d1f6201d9169ae00

- 7.5.2-ee/CI 5.2.1 - CentOS 6 64-bit [gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/91595f2a0207e8456e9b7d86e4e529c80dc2f998/centos-6.6/gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el6.x86_64.rpm)
    + SHA256: 79d8d3c954466a539d4e33c4ba43bda090eae73fb3738ea98aaf281869fe80ac

- 7.5.1-ee/CI 5.2.0 - CentOS 6 64-bit [gitlab-7.5.1_ee.omnibus.5.2.0.ci-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/52cf99f7a5d7ab1ee9414b95d7875afce4c30525/centos-6.6/gitlab-7.5.1_ee.omnibus.5.2.0.ci-1.el6.x86_64.rpm)
    + SHA256: e50d86c483211734bc60ba039ce63b5e44d444f286759f119bd9899b1715df43

- 7.4.5-ee/CI 5.1.0 - CentOS 6 64-bit [gitlab-7.4.5_ee.omnibus.5.1.0.ci-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/db1bf2b0be4947b23bc3e9ff22a7059720ccfc3a/centos-6.6/gitlab-7.4.5_ee.omnibus.5.1.0.ci-1.el6.x86_64.rpm)
    + SHA256: 4fa6e9f4ef399833fd4e38194fc5acfc5914cc9f90adfa75ff674e7e054c5d83

- 7.4.4-ee/CI 5.1.0 - CentOS 6 64-bit [gitlab-7.4.4_ee.omnibus.5.1.0.ci-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/8cdc5c7ae898c51845669dacc09d844614e46f90/centos-6.5/gitlab-7.4.4_ee.omnibus.5.1.0.ci-1.el6.x86_64.rpm)
    + MD5: be5c4d977b647459c28ea587de1b82c4

- 7.4.3-ee/CI 5.1.0 - CentOS 6 64-bit [gitlab-7.4.3_ee.omnibus.5.1.0.ci-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/268e1049c800baeebaa6a2bbcec1b520d52c9587/centos-6.5/gitlab-7.4.3_ee.omnibus.5.1.0.ci-1.el6.x86_64.rpm)
    + MD5: 3e9753ce5d4580900a809da99c4b91de

- 7.4.3-ee - CentOS 6 64-bit [gitlab-7.4.3_ee.omnibus.1-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/0de6a7cef7e1c4b81dfb41b3aed5b29245521241/centos-6.5/gitlab-7.4.3_ee.omnibus.1-1.el6.x86_64.rpm)
    + MD5: 03fda4571bc087059214511c988819c5

- 7.4.2-ee - CentOS 6 64-bit [gitlab-7.4.2_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/0cacc003ce7d724eae04610af9adc8cf2c47f6cc/centos-6.5/gitlab-7.4.2_ee.omnibus-1.el6.x86_64.rpm)
    + MD5: ab9c5fa50eaa337d6fcb13dadf83c7c7

- 7.4.1-ee - CentOS 6 64-bit [gitlab-7.4.1_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/0e35c2a4c7174facb186a892a5260cad168a6167/centos-6.5/gitlab-7.4.1_ee.omnibus-1.el6.x86_64.rpm)
    + MD5: 6909bbb98071974a4ab9808c63e15f19

- 7.4.0-ee - CentOS 6 64-bit [gitlab-7.4.0_ee.omnibus.2-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/f26f3f667c432fb7d901cb8ec6d9933b6682f023/centos-6.5/gitlab-7.4.0_ee.omnibus.2-1.el6.x86_64.rpm)
    + MD5: 5fe5843b33d244edb7e53a65f1dddd46

- 7.3.2-ee - CentOS 6 64-bit [gitlab-7.3.2_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/e951c9049fdcb4719b62d32da4b5b20fb4ac06ba/centos-6.5/gitlab-7.3.2_ee.omnibus-1.el6.x86_64.rpm)
    + MD5: 66dc5db39a230149bd6b4fa3543c1704

- 7.3.1-ee - CentOS 6 64-bit [gitlab-7.3.1_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/31cd8285078211e0c586e3ca55de835fbb4bd641/centos-6.5/gitlab-7.3.1_ee.omnibus-1.el6.x86_64.rpm)
    + MD5: 1bb944331915bd1ab024f26f5363d5ac

- 7.3.0-ee - CentOS 6 64-bit [gitlab-7.3.0_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/e96783668115d01b2c11e7a68fe174055f2fa409/centos-6.5/gitlab-7.3.0_ee.omnibus-1.el6.x86_64.rpm)
    + MD5: 3f79fd3a8df8c3f14b7731be0e71a0ce

- 7.2.2-ee - CentOS 6 64-bit [gitlab-7.2.2_ee.omnibus.1-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/0f1f8d86c7d33d063066e078d2f46d38199471a6/centos-6.5/gitlab-7.2.2_ee.omnibus-1.el6.x86_64.rpm)
    + MD5: aac87719e12b89a8b7fbb8e76d08cf10

- 7.2.1-ee - CentOS 6 64-bit [gitlab-7.2.1_ee.omnibus.1-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/bfecfa9854037cf7c8d3d17c9fadebe06a30c908/centos-6.5/gitlab-7.2.1_ee.omnibus.1-1.el6.x86_64.rpm)
    + MD5: 6242e0715620d34e2f5329ba9bd74e23

- 7.2.0-ee - CentOS 6 64-bit [gitlab-7.2.0_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/2f0192626cfa99c6c86eeb9d340a7a5969d7943a/centos-6.5/gitlab-7.2.0_ee.omnibus-1.el6.x86_64.rpm)
    + MD5: e2db09cfc46542fd4c53a669d4159b68

- 7.1.1-ee - CentOS 6 64-bit [gitlab-7.1.0_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/ba1aa90ff5662e790fd3eecfd6653e4377cada95/centos-6.5/gitlab-7.1.1_ee.omnibus-1.el6.x86_64.rpm)
    + MD5: cee4f447c7ae99afd2bd6634a8a48000

- 7.1.0-ee - CentOS 6 64-bit [gitlab-7.1.0_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/de9f52c1c4cf611db78ad0548275c574d85cb220/centos-6.5/gitlab-7.1.0_ee.omnibus-1.el6.x86_64.rpm)
    + MD5: 35311bc3ae636b370c142aa10217d702

- 7.0.1-ee - CentOS 6 64-bit [gitlab-7.0.1_ee.omnibus.1-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/09a89ba7f0fe28ba9c4b52a492d02135e5a39a9c/centos-6.5/gitlab-7.0.1_ee.omnibus.1-1.el6.x86_64.rpm)
    + MD5: d9b518df79b2abd63ce70f1d028f5c30

- 7.0.0-ee - CentOS 6 64-bit [gitlab-7.0.0_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/6232e9f5ee819537011a57d3f8eb40c149795052/centos-6.5/gitlab-7.0.0_ee.omnibus-1.el6.x86_64.rpm)
    - MD5: 49a9eb63daba98bec85d3dbc175bac9d

- 6.9.4-ee - CentOS 6 64-bit [gitlab-6.9.4_ee.omnibus.1-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/60dc935248ddfdc182703f770ac8b55718b7bf94/centos-6.5/gitlab-6.9.4_ee.omnibus.1-1.el6.x86_64.rpm)
    - MD5: 17c358ff5edf868ccf3f07158b0ef382

- 6.9.3-ee - CentOS 6 64-bit [gitlab-6.9.3_ee.omnibus.1-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/2309ffd68483e2d74ef1b96566e7b68934abd99f/centos-6.5/gitlab-6.9.3_ee.omnibus.1-1.el6.x86_64.rpm)
    - MD5: 2e716a56643b93f0ee8d8c6cb5457952

- 6.9.2-ee - CentOS 6 64-bit [gitlab-6.9.2_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/8f0bde82158c3d542357f5ae5658bc4939f9d006/centos-6.5/gitlab-6.9.2_ee.omnibus-1.el6.x86_64.rpm)
    - MD5: 696c861da0a8a71d7df22c431ddb9619

- 6.9.1-ee - CentOS 6 64-bit [gitlab-6.9.1_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/c5bddcb7e781a16eca3bd5d6418f200cdfcdd311/centos-6.5/gitlab-6.9.1_ee.omnibus-1.el6.x86_64.rpm)
    - MD5: 4728394d750f28827c445ddc01f53580

- 6.9.0-ee - CentOS 6 64-bit [gitlab-6.9.0_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/f86f29bac6fa3e7cd96315550c362816fc04cdb4/centos-6.5/gitlab-6.9.0_ee.omnibus-1.el6.x86_64.rpm)
    - MD5: 18bd1bea069b968935eea489e4a24b50

- 6.8.1-ee - CentOS 6 64-bit [gitlab-6.8.1_ee.omnibus.1-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/e8f63c2a21cae7e9842c16b20d76b9de25d3130b/centos-6.5/gitlab-6.8.1_ee.omnibus.1-1.el6.x86_64.rpm)
    - MD5: 31895155f8f694ded61a04976a06baeb

- 6.8.0-ee - CentOS 6 64-bit [gitlab-6.8.0_ee.omnibus.4-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/0a6d0e42b82d64a4c4ec6bbe448ffc0a5cfb70ab/centos-6.5/gitlab-6.8.0_ee.omnibus.4-1.el6.x86_64.rpm)
    - MD5: 6648d41b02712c1d701d8361490126e7

- 6.7.4-ee - CentOS 6 64-bit [gitlab-6.7.4_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/e9394ffe2dd9cba518ab6d43510fb0fb6acc4ff6/gitlab-6.7.4_ee.omnibus-1.el6.x86_64.rpm)
    - MD5: 5004af120eb457fe7eefbaa5f47429dc

- 6.7.3-ee - CentOS 6 64-bit [gitlab-6.7.3_ee.omnibus.1-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/4a83046ae506fe84158c1bc433d8fa85a886abba/gitlab-6.7.3_ee.omnibus.1-1.el6.x86_64.rpm)
    - MD5: 6335719321acc8edc2f718570960c832

- 6.7.2-ee CentOS 6 64-bit [gitlab-6.7.2_ee.omnibus.2-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/e13ccafca35955ad754ea501798875d99e0cce4c/gitlab-6.7.2_ee.omnibus.2-1.el6.x86_64.rpm)
    - MD5: 36347c81013c4215226a3cb30f6ac1b4

- 6.7.2-ee - CentOS 6 64-bit [gitlab-6.7.2_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/d8fd3ffca4c88ec2cd056cf0abb76fa5fc2c9236/gitlab-6.7.2_ee.omnibus-1.el6.x86_64.rpm)
    - MD5: 783db81d088e1fa679e8608672e83adb

- 6.7.1-ee - CentOS 6 64-bit [gitlab-6.7.1_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/bc91ee44fe1d23d9816e2497ff2fb23ad5efbbd4/gitlab-6.7.1_ee.omnibus-1.el6.x86_64.rpm)
    - MD5: 5271918a5610f972b6c10225b151ad81

- 6.6.3-ee - CentOS 6 64-bit [gitlab-6.6.3_ee.omnibus.2-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/9fdbc4650df67d3a55c94fe7dced4fb9161aa056/gitlab-6.6.3_ee.omnibus.2-1.el6.x86_64.rpm)
    - MD5: e7f8e1bfe3f6f8173fce204e3903672c

- 6.6.2-ee - CentOS 6 64-bit [gitlab-6.6.2_ee.omnibus-1.el6.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/32f814ce19709276846c281cac23b934f91beb06/gitlab-6.6.2_ee.omnibus-1.el6.x86_64.rpm)
    - MD5: e4414bf4c4b13e30a35c8578943bb7a1

### CentOS 7 64-bit

- 7.5.3-ee/CI 5.2.1 - CentOS 7 64-bit [gitlab-7.5.3_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/f08d577a156a0bf4ef06f4b42586a94707d2e456/centos-7.0.1406/gitlab-7.5.3_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm)
    + SHA256: d3e734f37841b38f37892ea5557a7c707f0e7bba8bf5f70869f309bd8f21120a

- 7.5.2-ee/CI 5.2.1 - CentOS 7 64-bit [gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/01fe47e4a0b4f27da31edfc40e8bb2c695fa1647/centos-7.0.1406/gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm)
    + SHA256: 0543dcfccd229d37934a069cb151b14bf61f2f8a6dcb78e8aeb14cfdb0fecb47

- 7.5.1-ee/CI 5.2.0 - CentOS 7 64-bit [gitlab-7.5.1_ee.omnibus.5.2.0.ci-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/cbe0e6ef39dc93d791707f5f715d4009034f74fc/centos-7.0.1406/gitlab-7.5.1_ee.omnibus.5.2.0.ci-1.el7.x86_64.rpm)
+ SHA256: e184d321f2d3bff994be9b7a66a76a4ec84fc88fb299b22a66d1ce90d551a970

- 7.4.5-ee/CI 5.1.0 - CentOS 7 64-bit [gitlab-7.4.5_ee.omnibus.5.1.0.ci-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/9cb022483de75b25e9ed55f0a89b8f6de01da8d8/centos-7.0.1406/gitlab-7.4.5_ee.omnibus.5.1.0.ci-1.el7.x86_64.rpm)
    + SHA256: 50aebcda2b2a0b65527636b7ed4deded23e20dfeb6049d8fc167a441654af5e8

- 7.4.4-ee/CI 5.1.0 - CentOS 7 64-bit [gitlab-7.4.4_ee.omnibus.5.1.0.ci-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/b5a6e03222854e741d1c0e0cf37748d5b79beac5/centos-7.0.1406/gitlab-7.4.4_ee.omnibus.5.1.0.ci-1.el7.x86_64.rpm)
    + MD5: 88d34e3705ca8317e61a2cf91ef101af

- 7.4.3-ee/CI 5.1.0 - CentOS 7 64-bit [gitlab-7.4.3_ee.omnibus.5.1.0.ci-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/f4535b85fe82f08ed758d77284572db0f5a8c141/centos-7.0.1406/gitlab-7.4.3_ee.omnibus.5.1.0.ci-1.el7.x86_64.rpm)
    + MD5: 9a1da05ff685348edc44ab2bcf419401

- 7.4.3-ee - CentOS 7 64-bit [gitlab-7.4.3_ee.omnibus.1-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/6fb497096e614fc9e06a97e2340c42c6eff902a7/centos-7.0.1406/gitlab-7.4.3_ee.omnibus.1-1.el7.x86_64.rpm)
    + MD5: 4437aa26a37e6755741cd17cf8b0ace1

- 7.4.2-ee - CentOS 7 64-bit [gitlab-7.4.2_ee.omnibus-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/34271e331e786ffb2ea436ba2f872be091d9a985/centos-7.0.1406/gitlab-7.4.2_ee.omnibus-1.el7.x86_64.rpm)
    + MD5: 54cbef1653422906aa912925c4821e80

- 7.4.1-ee - CentOS 7 64-bit [gitlab-7.4.1_ee.omnibus-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/7fec37a0e4f36281269260bdbd0b911acfb8593b/centos-7.0.1406/gitlab-7.4.1_ee.omnibus-1.el7.x86_64.rpm)
    + MD5: 6d5e0c2be3ab694a17536c7ff93e88c4

- 7.4.0-ee - CentOS 7 64-bit [gitlab-7.4.0_ee.omnibus.2-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/9b33aa1758a695f38898818a4fdd79529d123dc6/centos-7.0.1406/gitlab-7.4.0_ee.omnibus.2-1.el7.x86_64.rpm)
    + MD5: 9489913a4250df7691f6037dc5f26c3e

- 7.3.2-ee - CentOS 7 64-bit [gitlab-7.3.2_ee.omnibus-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/e5c37348729adcb27801dd2bd6c580f88b49e6ad/centos-7.0.1406/gitlab-7.3.2_ee.omnibus-1.el7.x86_64.rpm)
    + MD5: 123e637a7e75ff8506bb95b2727a5a97

- 7.3.1-ee - CentOS 7 64-bit [gitlab-7.3.1_ee.omnibus-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/3050e92537dea21bfe91a5c81037d778a00f19aa/centos-7.0.1406/gitlab-7.3.1_ee.omnibus-1.el7.x86_64.rpm)
    + MD5: fb1baf16e1937634359961656ac3d18c

- 7.3.0-ee - CentOS 7 64-bit [gitlab-7.3.0_ee.omnibus-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/18ad7ed255618bf1d3d1a26e0eaff324f609e8a2/centos-7.0.1406/gitlab-7.3.0_ee.omnibus-1.el7.x86_64.rpm)
    + MD5: c75673bed7add69c032606db9581b13f

- 7.2.2-ee - CentOS 7 64-bit [gitlab-7.2.2_ee.omnibus.1-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/8ec5d93f4c7b6884a85fe3a0b4f6e4f1ab561de4/centos-7.0.1406/gitlab-7.2.2_ee.omnibus-1.el7.x86_64.rpm)
    + MD5: d9122c6afb70f059c8c9d63691db6bb7

- 7.2.1-ee - CentOS 7 64-bit [gitlab-7.2.1_ee.omnibus.1-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/3769df612d984a89472ddd55a1c7edd76ba5d245/centos-7.0.1406/gitlab-7.2.1_ee.omnibus.1-1.el7.x86_64.rpm)
    + MD5: 1d3cee97374e1b4e9eda9afad7e75057

- 7.2.0-ee - CentOS 7 64-bit [gitlab-7.2.0_ee.omnibus.1-1.el7.x86_64.rpm](https://s3-eu-west-1.amazonaws.com/downloads-packages/74a4d7a4e9406253f7ba7fff1e83c67122d7f12d/centos-7.0.1406/gitlab-7.2.0_ee.omnibus.1-1.el7.x86_64.rpm)
    + MD5: 77b343220a36d39a1c167355ccb7c8fc


### Debian 7 64-bit

- 7.5.3-ee/CI 5.2.1 - Debian 7 64-bit [gitlab_7.5.3-ee.omnibus.5.2.1.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/9e2aa73766f581642ff10daac1dcbdaff44f6040/debian-7.6/gitlab_7.5.3-ee.omnibus.5.2.1.ci-1_amd64.deb)
    + SHA256: f370fe69342c36a84080a19ccc2f9dfce5c70cdf99922b5381fabf126b0c203e

- 7.5.2-ee/CI 5.2.1 - Debian 7 64-bit [gitlab_7.5.2-ee.omnibus.5.2.1.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/9e4146057f068039938937722a26ed9b3eef755b/debian-7.6/gitlab_7.5.2-ee.omnibus.5.2.1.ci-1_amd64.deb)
    + SHA256: 8a60a952e400cba552356613e4bd299eb8e23f982de6494d7c4207e3708a3a27

- 7.5.1-ee/CI 5.2.0 - Debian 7 64-bit [gitlab_7.5.1-ee.omnibus.5.2.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/4cd93dae8f910df1ffcc2e13dca77c6e99f6262e/debian-7.6/gitlab_7.5.1-ee.omnibus.5.2.0.ci-1_amd64.deb)
+ SHA256: 4e5812b72518dd911024c578c3abd827ae0b112781ab21d0f5821a004ba66007

- 7.4.5-ee/CI 5.1.0 - Debian 7 64-bit [gitlab_7.4.5-ee.omnibus.5.1.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/263e437825ad04d972b8a29fd1b95e3fa9d2eca5/debian-7.6/gitlab_7.4.5-ee.omnibus.5.1.0.ci-1_amd64.deb)
    + SHA256: 16cef31906a1508869b91565fc71c1dfb9c712789e56554c3177341bd1f8903e

- 7.4.4-ee/CI 5.1.0 - Debian 7 64-bit [gitlab_7.4.4-ee.omnibus.5.1.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/57faf07036cda6780f9c55da6aaefad97218f835/debian-7.6/gitlab_7.4.4-ee.omnibus.5.1.0.ci-1_amd64.deb)
    + MD5: 0690cc175b8563239a374c5d2001254c

- 7.4.3-ee/CI 5.1.0 - Debian 7 64-bit [gitlab_7.4.3-ee.omnibus.5.1.0.ci-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/312e79a2724f10353c68c4e4ebc68d7c706939ae/debian-7.6/gitlab_7.4.3-ee.omnibus.5.1.0.ci-1_amd64.deb)
    + MD5: d4ddb61274bca6d7268d2e3613ea5654

- 7.4.3-ee - Debian 7 64-bit [gitlab_7.4.3-ee.omnibus.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/15a6fd75f742b239a4589aa54dad7cd382d46e00/debian-7.6/gitlab_7.4.3-ee.omnibus.1-1_amd64.deb)
    + MD5: e513fba07fdc84ab0e4f8bc10f9b4a90

- 7.4.2-ee - Debian 7 64-bit [gitlab_7.4.2-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/93b1781f1ef5bf910075fa23bd609d504c5875a0/debian-7.6/gitlab_7.4.2-ee.omnibus-1_amd64.deb)
    + MD5: 21f097081c2c94edf91bc2d35fc5821a

- 7.4.1-ee - Debian 7 64-bit [gitlab_7.4.1-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/aded923f200d89ec22f70e2edc6c12146f3e605a/debian-7.6/gitlab_7.4.1-ee.omnibus-1_amd64.deb)
    + MD5: 901115747079fbab658078f268991596

- 7.4.0-ee - Debian 7 64-bit [gitlab_7.4.0-ee.omnibus.2-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/22be93e9b1d13b05c94dfa5c77ac1210932b92e1/debian-7.6/gitlab_7.4.0-ee.omnibus.2-1_amd64.deb)
    + MD5: b887551f922d97b41f5c9fbd0814ef3f

- 7.3.2-ee - Debian 7 64-bit [gitlab_7.3.2-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/daf694d5de05b57c2fd1ecb05f8bd49b4ae8dd5b/debian-7.6/gitlab_7.3.2-ee.omnibus-1_amd64.deb)
    + MD5: b57dc8b083680aa30b6ad5c4186a5194

- 7.3.1-ee - Debian 7 64-bit [gitlab_7.3.1-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/e89bc59a8001adf3349a89913c9ea4f25c217d59/debian-7.6/gitlab_7.3.1-ee.omnibus-1_amd64.deb)
    + MD5: 51d8206aaee69d3d3a1236bf61cc4b8a

- 7.3.0-ee - Debian 7 64-bit [gitlab_7.3.0-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/37b500c5c99269354366f74ee6f4558dd5aa7fe1/debian-7.6/gitlab_7.3.0-ee.omnibus-1_amd64.deb)
    + MD5: 4488f302d1f1c5278282b199f8246490

- 7.2.2-ee - Debian 7 64-bit [gitlab_7.2.2-ee.omnibus.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/f3ce6ab1750ab3cf54fa4685d83b2c0cdb846867/debian-7.6/gitlab_7.2.2-ee.omnibus-1_amd64.deb)
    + MD5: 392815a9b63e2f4c1ba69111ad509264

- 7.2.1-ee - Debian 7 64-bit [gitlab_7.2.1-ee.omnibus.2-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/f5508877220d49dc7abf9bdb6b5f016fa4deb46a/debian-7.6/gitlab_7.2.1-ee.omnibus.2-1_amd64.deb)
    + MD5: 8fbcb93fcb2c6a09a3a8b5d86d2b8d85

- 7.2.0-ee - Debian 7 64-bit [gitlab_7.2.0-ee.omnibus.2-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/49ca44c4b6a815993d878d8a42a653fb71672f0c/debian-7.6/gitlab_7.2.0-ee.omnibus.2-1_amd64.deb)
    + MD5: 36166f60d990afd1d76217ad23bd9e5d

- 7.1.1-ee - Debian 7 64-bit [gitlab_7.1.1-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/15e4d859ee875474aed4d28e85ab363513ab9967/debian-7.5/gitlab_7.1.1-ee.omnibus-1_amd64.deb)
    - MD5: b25110d4dd807c968aa593afd2c9ea8b

- 7.1.0-ee - Debian 7 64-bit [gitlab_7.1.0-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/f25023e63a9c8782c05a1f3bcc3ed45cd8e15136/debian-7.5/gitlab_7.1.0-ee.omnibus-1_amd64.deb)
    - MD5: 800b904ab58a66c95b4b9e2771233a81

- 7.0.1-ee - Debian 7 64-bit [gitlab_7.0.0-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/c0190e8bf1fc0b61f27c3482e26ccc8adc58e82e/debian-7.5/gitlab_7.0.1-ee.omnibus-1_amd64.deb)
    - MD5: 572866c64e3dc2bead15566abd1590c2

- 7.0.0-ee - Debian 7 64-bit [gitlab_7.0.0-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/0abbb828dccfc70557caf9fd07ea302e14cc07dd/debian-7.5/gitlab_7.0.0-ee.omnibus-1_amd64.deb)
    - MD5: 823ff3cf365aead9a641169c43171ea9

- 6.9.4-ee - Debian 7 64-bit [gitlab_6.9.4-ee.omnibus.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/1b5bc6d0d291eef9a6399383d6a8f13b01c09e47/debian-7.5/gitlab_6.9.4-ee.omnibus.1-1_amd64.deb)
    - MD5: c31b66def74400dcc95625b6cc886191

- 6.9.3-ee - Debian 7 64-bit [gitlab_6.9.3-ee.omnibus.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/029b026311e688f1865ba9e8f7c9e4b4d01fbdc2/debian-7.5/gitlab_6.9.3-ee.omnibus.1-1_amd64.deb)
    - MD5: 643e6d26d31b5b1166b9f67de299b450

- 6.9.2-ee - Debian 7 64-bit [gitlab_6.9.2-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/d33ef3d41af88acd847d0199678a1e3503fbbaa0/debian-7.4/gitlab_6.9.2-ee.omnibus-1_amd64.deb)
    - MD5: 8027344d00d3d26abbd87b754a42fe2c

- 6.9.1-ee - Debian 7 64-bit [gitlab_6.9.1-ee.omnibus-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/0a8357d7282de4350c45ebdcc109ab653978a03d/debian-7.4/gitlab_6.9.1-ee.omnibus-1_amd64.deb)
    - MD5: 8ea5d343bc60b984ef44325d03180f27

- 6.9.0-ee - Debian 7 64-bit [gitlab_6.9.0-ee.omnibus.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/9a604b7d3f4b57d7ebf34c26e034fb99dbe90ebf/debian-7.4/gitlab_6.9.0-ee.omnibus.1-1_amd64.deb)
    - MD5: 4831a0b7dff2abf7982aaefae88a66f4

- 6.8.1-ee - Debian 7 64-bit [gitlab_6.8.1-ee.omnibus.1-1_amd64.deb](https://s3-eu-west-1.amazonaws.com/downloads-packages/42982fb41464911692bcf98692bb5858a0bba009/debian-7.4/gitlab_6.8.1-ee.omnibus.1-1_amd64.deb)
    - MD5: fb0510d75a2672b605575439e4107ce9
