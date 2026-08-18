---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des paramètres de conformité et de politique
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/17392) dans GitLab 18.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `security_policies_csp`. Désactivé par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/550318) sur GitLab Self-Managed dans GitLab 18.3.
- [En disponibilité générale](https://gitlab.com/groups/gitlab-org/-/epics/17392) dans GitLab 18.5. L'indicateur de fonctionnalité `security_policies_csp` a été supprimé.

{{< /history >}}

Utilisez cette API pour interagir avec les paramètres de politique de sécurité de votre instance GitLab.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.
- Votre instance doit disposer du niveau Ultimate pour utiliser les politiques de sécurité.

## Récupérer les paramètres de politique de sécurité {#retrieve-security-policy-settings}

Récupère les paramètres de politique de sécurité actuels de cette instance GitLab.

```plaintext
GET /admin/security/compliance_policy_settings
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/security/compliance_policy_settings"
```

Exemple de réponse :

```json
{
  "csp_namespace_id": 42
}
```

Lorsqu'aucun espace de nommage CSP n'est configuré :

```json
{
  "csp_namespace_id": null
}
```

## Mettre à jour les paramètres de politique de sécurité {#update-security-policy-settings}

Met à jour les paramètres de politique de sécurité de cette instance GitLab.

```plaintext
PUT /admin/security/compliance_policy_settings
```

| Attribut         | Type    | Obligatoire | Description |
|:------------------|:--------|:---------|:------------|
| `csp_namespace_id` | integer | oui     | ID du groupe désigné pour gérer de manière centralisée les politiques de sécurité. Doit être un groupe principal. Définir sur `null` pour effacer le paramètre. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"csp_namespace_id": 42}' \
  --url "https://gitlab.example.com/api/v4/admin/security/compliance_policy_settings"
```

Exemple de réponse :

```json
{
  "csp_namespace_id": 42
}
```
