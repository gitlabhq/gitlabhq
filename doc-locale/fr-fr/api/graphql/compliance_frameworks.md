---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API GraphQL des cadres de conformité
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Gérez les cadres de conformité pour les groupes principaux à l'aide d'une API GraphQL.

## Prérequis {#prerequisites}

- Pour créer, modifier et supprimer des cadres de conformité, les utilisateurs doivent soit :
  - Avoir le rôle Owner pour le groupe principal.
  - Se voir attribuer un [rôle personnalisé](../../user/custom_roles/_index.md) avec l'`admin_compliance_framework` [autorisation personnalisée](../../user/custom_roles/abilities.md#compliance-management).

## Créer un cadre de conformité à partir d'un modèle {#create-a-compliance-framework-from-a-template}

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/16808) dans GitLab 19.0 [avec un flag](../../administration/feature_flags/_index.md) nommé `compliance_framework_templates`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Créez un cadre de conformité à partir d'un modèle prédéfini. Les modèles incluent des exigences et des contrôles préconfigurés alignés sur les normes de conformité courantes.

### Lister les modèles disponibles {#list-available-templates}

Pour lister tous les modèles de cadres de conformité disponibles :

```graphql
query {
  complianceFrameworkTemplates {
    id
    name
    description
    color
    templateVersion
  }
}
```

Pour récupérer un modèle spécifique par ID et afficher sa structure JSON complète :

```graphql
query {
  complianceFrameworkTemplates(
    id: "gid://gitlab/ComplianceManagement::Frameworks::TemplateRegistry::Template/soc2"
  ) {
    id
    name
    description
    color
    templateVersion
    json
  }
}
```

ID de modèles disponibles :

| ID de modèle | Nom |
|-------------|------|
| `cis_csc_v8-1` | CIS CSC v8.1 |
| `csa_ccm_v4` | CSA CCM v4 |
| `cyber_essentials` | Cyber Essentials |
| `dora` | DORA |
| `fedramp_high_r5` | FedRAMP High |
| `fedramp_low_r5` | FedRAMP Low |
| `fedramp_moderate_r5` | FedRAMP Moderate |
| `irap_official` | IRAP Official |
| `irap_protected` | IRAP Protected |
| `irap_secret` | IRAP Secret |
| `irap_top_secret` | IRAP Top Secret |
| `ismap` | ISMAP |
| `iso_27001:2022` | ISO 27001:2022 |
| `nis_2` | NIS 2 |
| `nist_800-171_r3_cmmc` | NIST 800-171 Rev. 3 CMMC |
| `nist_800-218_v1-1` | NIST SP 800-218 |
| `nist_800-53_r5` | NIST 800-53 Révision 5 |
| `soc2` | SOC 2 |
| `tisax` | TISAX |

### Créer un cadre à partir d'un modèle {#create-a-framework-from-a-template}

Pour créer un cadre de conformité à partir d'un modèle, utilisez la mutation `createComplianceFrameworkFromTemplate`. Les arguments `templateId` et `namespacePath` sont obligatoires. Tous les autres arguments sont des remplacements facultatifs des valeurs par défaut du modèle.

```graphql
mutation {
  createComplianceFrameworkFromTemplate(
    input: {
      namespacePath: "my-group"
      templateId: "gid://gitlab/ComplianceManagement::Frameworks::TemplateRegistry::Template/soc2"
    }
  ) {
    framework {
      id
      name
      description
      color
    }
    errors
  }
}
```

Vous pouvez remplacer le nom, la description, la couleur et le statut par défaut du modèle :

```graphql
mutation {
  createComplianceFrameworkFromTemplate(
    input: {
      namespacePath: "my-group"
      templateId: "gid://gitlab/ComplianceManagement::Frameworks::TemplateRegistry::Template/soc2"
      name: "Custom SOC 2"
      description: "Our organization's SOC 2 compliance framework"
      color: "#FCA121"
      default: true
    }
  ) {
    framework {
      id
      name
      description
      color
    }
    errors
  }
}
```

Le cadre est créé avec toutes les exigences et tous les contrôles du modèle préremplis. L'ID et la version du modèle source sont enregistrés en tant que champs de provenance immuables et ne peuvent pas être modifiés après la création.

Le cadre est créé si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

## Créer un cadre de conformité {#create-a-compliance-framework}

Créez un nouveau cadre de conformité pour un groupe principal.

Pour créer un cadre de conformité, utilisez la mutation `createComplianceFramework` :

```graphql
mutation {
  createComplianceFramework(input: {
    namespacePath: "my-group",
    params: {
      name: "SOX Compliance",
      description: "Sarbanes-Oxley compliance framework for financial reporting",
      color: "#1f75cb",
      default: false
    }
  }) {
    errors
    framework {
      id
      name
      description
      color
      default
      namespace {
        name
      }
    }
  }
}
```

Le cadre est créé si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

### Créer un cadre avec des exigences {#create-a-framework-with-requirements}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

Vous pouvez créer des cadres avec des exigences et des contrôles spécifiques :

```graphql
mutation {
  createComplianceFramework(input: {
    namespacePath: "my-group",
    params: {
      name: "Security Framework",
      description: "Security compliance framework with SAST and dependency scanning",
      color: "#e24329",
      default: false
    }
  }) {
    errors
    framework {
      id
      name
      description
      color
      default
      namespace {
        name
      }
    }
  }
}
```

Après avoir créé le cadre, vous pouvez ajouter des exigences en utilisant l'ID de cadre renvoyé par la mutation de création.

## Lister les cadres de conformité {#list-compliance-frameworks}

Listez tous les cadres de conformité pour un groupe principal.

Vous pouvez afficher une liste de cadres de conformité pour un groupe principal en utilisant la requête `group` :

```graphql
query {
  group(fullPath: "my-group") {
    id
    complianceFrameworks {
      nodes {
        id
        name
        description
        color
        default
        pipelineConfigurationFullPath
      }
    }
  }
}
```

Si la liste résultante est vide, aucun cadre de conformité n'existe pour ce groupe.

## Lister les cadres de conformité assignés à un projet {#list-compliance-frameworks-assigned-to-a-project}

```graphql
query {
 project(fullPath: "my-project"){
  id
  name
  complianceFrameworks{
    nodes{
      id
      name
      }
    }
  }
}

```

Remplacez `"my-project"` par le chemin complet de votre projet.

## Mettre à jour un cadre de conformité {#update-a-compliance-framework}

Mettez à jour un cadre de conformité existant pour un groupe principal.

Pour mettre à jour un cadre de conformité, utilisez la mutation `updateComplianceFramework`. Vous pouvez récupérer l'ID du cadre en [listant tous les cadres de conformité](#list-compliance-frameworks) pour le groupe.

```graphql
mutation {
  updateComplianceFramework(input: {
    id: "gid://gitlab/ComplianceManagement::Framework/1",
    params: {
      name: "Updated SOX Compliance",
      description: "Updated Sarbanes-Oxley compliance framework",
      color: "#6b4fbb",
      default: true
    }
  }) {
    errors
    framework {
      id
      name
      description
      color
      default
      namespace {
        name
      }
    }
  }
}
```

Le cadre est mis à jour si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

## Supprimer un cadre de conformité {#delete-a-compliance-framework}

Supprimez un cadre de conformité d'un groupe principal.

Pour supprimer un cadre de conformité, utilisez la mutation `destroyComplianceFramework`. Vous pouvez récupérer l'ID du cadre en [listant tous les cadres de conformité](#list-compliance-frameworks) pour le groupe.

```graphql
mutation {
  destroyComplianceFramework(input: {
    id: "gid://gitlab/ComplianceManagement::Framework/1"
  }) {
    errors
  }
}
```

Le cadre est supprimé si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

## Appliquer des cadres de conformité à des projets {#apply-compliance-frameworks-to-projects}

Appliquez un ou plusieurs cadres de conformité à des projets.

Prérequis :

- Rôle Maintainer ou Owner pour le projet.
- Le projet doit appartenir à un groupe disposant de cadres de conformité.

Pour appliquer des cadres de conformité à un projet, utilisez la mutation `projectUpdateComplianceFrameworks` :

```graphql
mutation {
  projectUpdateComplianceFrameworks(input: {
    projectId: "gid://gitlab/Project/1",
    complianceFrameworkIds: [
      "gid://gitlab/ComplianceManagement::Framework/1",
      "gid://gitlab/ComplianceManagement::Framework/2"
    ]
  }) {
    errors
    project {
      id
      complianceFrameworks {
        nodes {
          id
          name
          color
        }
      }
    }
  }
}
```

Les cadres sont appliqués si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

### Supprimer des cadres de conformité des projets {#remove-compliance-frameworks-from-projects}

Pour supprimer tous les cadres de conformité d'un projet, transmettez un tableau vide :

```graphql
mutation {
  projectUpdateComplianceFrameworks(input: {
    projectId: "gid://gitlab/Project/1",
    complianceFrameworkIds: []
  }) {
    errors
    project {
      id
      complianceFrameworks {
        nodes {
          id
          name
        }
      }
    }
  }
}
```

## Travailler avec les exigences et les contrôles {#working-with-requirements-and-controls}

Vous pouvez gérer les exigences et les contrôles des cadres de conformité à l'aide de GraphQL.

### Interroger les exigences du cadre {#query-framework-requirements}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

Pour afficher les exigences et les contrôles d'un cadre de conformité :

```graphql
query {
  group(fullPath: "my-group") {
    complianceFrameworks {
      nodes {
        id
        name
        requirements {
          nodes {
            id
            name
            description
            controls {
              nodes {
                id
                name
                controlId
                controlType
              }
            }
          }
        }
      }
    }
  }
}
```

### Ajouter des exigences à un cadre {#add-requirements-to-a-framework}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

Pour ajouter une exigence avec des contrôles de conformité GitLab à un cadre existant :

```graphql
mutation {
  complianceFrameworkRequirementCreate(input: {
    frameworkId: "gid://gitlab/ComplianceManagement::Framework/1",
    name: "Security Scanning Requirement",
    description: "Ensure security scanning is enabled for all projects",
    controlIds: [
      "scanner_sast_running",
      "scanner_dep_scanning_running",
      "scanner_secret_detection_running"
    ]
  }) {
    errors
    requirement {
      id
      name
      description
      controls {
        nodes {
          id
          name
          controlId
        }
      }
    }
  }
}
```

### Ajouter des contrôles externes {#add-external-controls}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

Pour ajouter une exigence avec des contrôles externes :

```graphql
mutation {
  createComplianceRequirement(
    input: {
      complianceFrameworkId: "gid://gitlab/ComplianceManagement::Framework/1",
      controls: [{
        controlType: "external",
        name: "external_control",
        externalControlName: "ServiceNowApproval",
        externalUrl: "https://mycompany.service-now.com/api/approval",
        secretToken: "my-secret-key"
      }],
      params: {
        name: "External Approval Requirement",
        description: "Require external system approval for deployments"
      }
    }
  ) {
    errors
    requirement {
      id
      name
      description
      complianceRequirementsControls {
        nodes {
          id
          name
          controlType
          externalUrl
        }
      }
    }
  }
}
```

### Mettre à jour les exigences {#update-requirements}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

Pour mettre à jour une exigence existante :

```graphql
mutation {
  updateComplianceRequirement(input: {
    id: "gid://gitlab/ComplianceManagement::ComplianceFramework::ComplianceRequirement/1",
    params: {
      name: "Updated Security Requirement",
      description: "Updated security scanning requirement with additional controls"
    },
    controls: [{
        expression: "{\"field\":\"scanner_sast_running\",\"operator\":\"=\",\"value\":true}",
        name: "scanner_sast_running"
      },
      {
        expression: "{\"field\":\"scanner_dep_scanning_running\",\"operator\":\"=\",\"value\":true}",
        name: "scanner_dep_scanning_running"
      },
      {
        expression: "{\"field\":\"scanner_secret_detection_running\",\"operator\":\"=\",\"value\":true}",
        name: "scanner_secret_detection_running"
      }]
  })
  {
    errors
    requirement {
      id
      name
      description
      complianceRequirementsControls {
        nodes {
          id
          name
        }
      }
    }
  }
}
```

### Supprimer des exigences {#delete-requirements}

{{< details >}}

- Édition : Ultimate

{{< /details >}}

Pour supprimer une exigence d'un cadre :

```graphql
mutation {
  destroyComplianceRequirement(input: {
    id: "gid://gitlab/ComplianceManagement::ComplianceFramework::ComplianceRequirement/1"
  }) {
    errors
  }
}
```

## Gestion des erreurs {#error-handling}

Lorsque vous travaillez avec des cadres de conformité via GraphQL, vous pouvez rencontrer les erreurs courantes suivantes :

- **Framework name already exists** : Chaque nom de cadre doit être unique au sein d'un groupe.
- **Invalid color format** : Les couleurs doivent être au format hexadécimal (par exemple, `#1f75cb`).
- **Permissions insuffisantes** : Seuls les propriétaires de groupe ou les utilisateurs disposant de l'`admin_compliance_framework` autorisation personnalisée peuvent gérer les cadres.
- **Invalid control ID** : Les ID de contrôle doivent correspondre aux [contrôles de conformité GitLab](../../user/compliance/compliance_frameworks/_index.md#gitlab-compliance-controls) pris en charge.

Vérifiez toujours le champ `errors` dans la réponse pour gérer les problèmes survenant lors des mutations.

## Sujets connexes {#related-topics}

- [Cadres de conformité](../../user/compliance/compliance_frameworks/_index.md)
- [Centre de conformité](../../user/compliance/compliance_center/_index.md)
- [Référence de l'API GraphQL](reference/_index.md)
