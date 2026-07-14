---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Restrictions d'adresses IP"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les restrictions d'adresses IP aident à empêcher les utilisateurs malveillants de dissimuler leurs activités derrière plusieurs adresses IP.

GitLab conserve une liste des adresses IP uniques utilisées par un utilisateur pour effectuer des requêtes sur une période donnée. Lorsque la limite spécifiée est atteinte, toute requête effectuée par l'utilisateur depuis une nouvelle adresse IP est rejetée avec une erreur `403 Forbidden`.

Les adresses IP sont supprimées de la liste lorsqu'aucune requête supplémentaire n'a été effectuée par l'utilisateur depuis cette adresse IP pendant la période définie.

> [!note]
> Lorsqu'un runner exécute un job CI/CD en tant qu'utilisateur particulier, l'adresse IP du runner est également enregistrée dans la liste des adresses IP uniques de l'utilisateur. Par conséquent, la limite d'adresses IP par utilisateur doit tenir compte du nombre de runners actifs configurés.

## Configurer les restrictions d'adresses IP {#configure-ip-address-restrictions}

Prérequis :

- Accès administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rapports**.
1. Développez **Protection anti‐spam et anti‐robot**.
1. Mettez à jour les paramètres de restrictions d'adresses IP :
   1. Cochez la case **Limiter les connexions issues de plusieurs adresses IP** pour activer les restrictions d'adresses IP.
   1. Saisissez un nombre dans le champ **Adresses IP par utilisateur**, supérieur ou égal à `1`. Ce nombre spécifie le nombre maximum d'adresses IP uniques depuis lesquelles un utilisateur peut accéder à GitLab pendant la période définie avant que les requêtes provenant d'une nouvelle adresse IP ne soient rejetées.
   1. Saisissez un nombre dans le champ **Délai d'expiration de l'adresse IP**, supérieur ou égal à `0`. Ce nombre spécifie la durée en secondes pendant laquelle une adresse IP est comptabilisée dans la limite pour un utilisateur, à partir du moment où la dernière requête a été effectuée.
1. Sélectionnez **Sauvegarder les modifications**.
