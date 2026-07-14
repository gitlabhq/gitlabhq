---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Fournir des informations de contact de sécurité publiques
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/433210) dans GitLab 16.7.

{{< /history >}}

Les organisations peuvent faciliter la divulgation responsable des problèmes de sécurité en fournissant des informations de contact publiques. GitLab prend en charge l'utilisation d'un fichier [`security.txt`](https://securitytxt.org/) à cet effet.

Les administrateurs peuvent ajouter un fichier `security.txt` via l'interface GitLab ou l'[API REST](../../api/settings.md#update-application-settings). Tout contenu ajouté est mis à disposition à l'adresse `https://gitlab.example.com/.well-known/security.txt`. Aucune authentification n'est requise pour consulter ce fichier.

Pour configurer un fichier `security.txt` :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Ajouter des informations de contact de sécurité**.
1. Dans **Contenu pour security.txt**, saisissez les informations de contact de sécurité au format documenté sur <https://securitytxt.org/>.
1. Sélectionnez **Sauvegarder les modifications**.

Pour savoir comment répondre si vous recevez un rapport, consultez [Répondre aux incidents de sécurité](../../security/responding_to_security_incidents.md).

## Exemple de fichier `security.txt` {#example-securitytxt-file}

Le format de ces informations est documenté sur <https://securitytxt.org/>. Voici un exemple de fichier `security.txt` :

```plaintext
Contact: mailto:security@example.com
Expires: 2024-12-31T23:59Z
```
