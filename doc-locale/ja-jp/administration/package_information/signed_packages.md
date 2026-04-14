---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: パッケージ署名
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

<!-- vale gitlab_base.SubstitutionWarning = NO -->

GitLabが作成するLinuxパッケージは、[オムニバス](https://github.com/chef/omnibus)を使用して作成されており、GitLabは[自身のフォーク](https://gitlab.com/gitlab-org/omnibus)で`debsigs`を使用したDEB署名を追加しました。

<!-- vale gitlab_base.SubstitutionWarning = YES -->

既存のRPM署名機能と組み合わせることで、この追加により、GitLabはDEBまたはRPMを使用するすべてのサポート対象ディストリビューションに署名済みパッケージを提供できます。

これらのパッケージは、[`omnibus-gitlab`プロジェクト](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.gitlab-ci.yml)にあるGitLab CIプロセスによって生成されます。これは、パッケージがコミュニティへの配信前に改ざんされないことを保証するために、<https://packages.gitlab.com>に配信される前に作成されます。

## GnuPG公開キー {#gnupg-public-keys}

すべてのパッケージは、その形式に適した方法で[GnuPG](https://www.gnupg.org/)を使用して署名されます。これらのパッケージの署名に使用されるキーは、[MIT PGP公開キーサーバー](https://pgp.mit.edu)の[`0x3cfcf9baf27eab47`](https://pgp.mit.edu/pks/lookup?op=vindex&search=0x3CFCF9BAF27EAB47)で見つけることができます。

## 署名の検証 {#verifying-signatures}

GitLabのパッケージ署名を検証する方法に関する情報は、[パッケージ署名](https://docs.gitlab.com/omnibus/update/package_signatures/)で見つけることができます。

## GPG署名の管理 {#gpg-signature-management}

GitLabがパッケージ署名用のGPGキーを管理する方法に関する情報は、[手順書](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/packaging/manage-package-signing-keys.md)で見つけることができます。
