---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Signatures des packages
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

<!-- vale gitlab_base.SubstitutionWarning = NO -->

Les packages Linux produits par GitLab sont créés à l'aide de [Omnibus](https://github.com/chef/omnibus), pour lequel GitLab a ajouté la signature DEB à l'aide de `debsigs` dans [notre propre duplication](https://gitlab.com/gitlab-org/omnibus).

<!-- vale gitlab_base.SubstitutionWarning = YES -->

Combinée à la fonctionnalité existante de signature RPM, cette addition permet à GitLab de fournir des packages signés pour toutes les distributions prises en charge utilisant DEB ou RPM.

Ces packages sont produits par le processus GitLab CI, tel que défini dans le [projet `omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.gitlab-ci.yml), avant leur livraison à <https://packages.gitlab.com> afin de garantir que les packages ne sont pas altérés avant leur livraison à notre communauté.

## Clés publiques GnuPG {#gnupg-public-keys}

Tous les packages sont signés avec [GnuPG](https://www.gnupg.org/), selon une méthode adaptée à leur format. La clé utilisée pour signer ces packages peut être trouvée sur le [serveur de clés publiques PGP du MIT](https://pgp.mit.edu) à l'adresse [`0x3cfcf9baf27eab47`](https://pgp.mit.edu/pks/lookup?op=vindex&search=0x3CFCF9BAF27EAB47).

## Vérification des signatures {#verifying-signatures}

Des informations sur la vérification des signatures des packages GitLab sont disponibles dans [Package Signatures](https://docs.gitlab.com/omnibus/update/package_signatures/).

## Gestion des signatures GPG {#gpg-signature-management}

Des informations sur la façon dont GitLab gère les clés GPG pour la signature des packages sont disponibles dans [les runbooks](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/packaging/manage-package-signing-keys.md).
