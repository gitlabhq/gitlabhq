---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Découvrez comment appliquer des politiques de sécurité et des frameworks de conformité sur plusieurs groupes et projets depuis un emplacement unique et centralisé.
title: "Gestion des politiques de conformité et de sécurité à l'échelle de l'instance"
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/15864) dans GitLab 18.2 [avec un feature flag](../administration/feature_flags/_index.md) nommé `security_policies_csp`. Désactivées par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/550318) sur GitLab Self-Managed dans GitLab 18.3.
- [Passage en disponibilité générale](https://gitlab.com/groups/gitlab-org/-/epics/17392) dans GitLab 18.5. Suppression du feature flag `security_policies_csp`.

{{< /history >}}

Pour appliquer des politiques de sécurité et des frameworks de conformité sur plusieurs groupes et projets depuis un emplacement unique et centralisé, les administrateurs d'instance peuvent désigner un groupe de conformité et de politique de sécurité (CSP). Cela permet aux administrateurs d'instance de :

- Créer et configurer des politiques de sécurité qui s'appliquent automatiquement à l'ensemble de votre instance.
- Créer des frameworks de conformité centralisés pour les rendre disponibles pour d'autres groupes principaux.
- Définir la portée des politiques pour les appliquer aux frameworks de conformité, aux groupes, aux projets ou à l'ensemble de votre instance.
- Consulter une couverture complète des politiques pour comprendre quelles politiques sont actives et où elles sont actives.
- Maintenir un contrôle centralisé tout en permettant aux équipes de créer leurs propres politiques et frameworks supplémentaires.

## Prérequis {#prerequisites}

- GitLab 18.2 ou version ultérieure.
- Vous devez être administrateur d'instance.
- Vous devez disposer d'un groupe principal existant pour servir de groupe de conformité et de politique de sécurité.
- Pour utiliser l'API REST (facultatif), vous devez disposer d'un jeton avec accès administrateur.

## Configurer la gestion des politiques de conformité et de sécurité à l'échelle de l'instance {#set-up-instance-wide-compliance-and-security-policy-management}

Pour configurer la gestion des politiques de conformité et de sécurité à l'échelle de l'instance, vous désignez un groupe de conformité et de politique de sécurité, puis vous créez des politiques et des frameworks de conformité dans ce groupe.

### Désigner un groupe de conformité et de politique de sécurité {#designate-a-compliance-and-security-policy-group}

Vous pouvez désigner un groupe de conformité et de politique de sécurité en utilisant l'interface GitLab ou l'API REST.

#### Utilisation de l'interface GitLab {#using-the-gitlab-ui}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Security and Compliance**.
1. Dans la section **Designate CSP Group**, sélectionnez un groupe principal existant dans la liste déroulante.
1. Sélectionnez **Enregistrer les modifications**.

#### Utilisation de l'API REST {#using-the-rest-api}

Vous pouvez également désigner un groupe de conformité et de politique de sécurité par programmation en utilisant l'API REST. L'API est utile pour l'automatisation ou pour la gestion de plusieurs instances.

Pour définir un groupe de conformité et de politique de sécurité :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"csp_namespace_id": 123456}' \
  --url "https://gitlab.example.com/api/v4/admin/security/policy_settings"
```

Pour effacer le groupe de conformité et de politique de sécurité :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"csp_namespace_id": null}' \
  --url "https://gitlab.example.com/api/v4/admin/security/policy_settings"
```

Pour obtenir les paramètres actuels de conformité et de politique de sécurité :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/security/policy_settings"
```

Pour plus d'informations, consultez la [documentation de l'API des paramètres de politique](../api/compliance_policy_settings.md).

Le groupe sélectionné devient votre groupe de conformité et de politique de sécurité, servant de point central pour gérer les politiques de sécurité et les frameworks de conformité dans votre instance.

### Gestion des politiques de sécurité dans le groupe de conformité et de politique de sécurité {#security-policy-management-in-the-compliance-and-security-policy-group}

Consultez la documentation sur le [groupe de conformité et de politique de sécurité](../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md) pour les politiques de sécurité.

### Gestion centralisée des frameworks de conformité {#centralized-compliance-framework-management}

Après avoir désigné un groupe de conformité et de politique de sécurité, vous pouvez créer des frameworks de conformité automatiquement disponibles pour tous les groupes principaux de votre instance. Cela offre une approche cohérente de la conformité dans toute votre organisation.

Les frameworks de conformité créés dans le groupe de conformité et de politique de sécurité :

- Sont visibles et disponibles pour d'autres groupes principaux de votre instance.
- Peuvent être appliqués aux projets par les propriétaires de groupe.
- Sont en lecture seule pour les utilisateurs extérieurs au groupe de conformité et de politique de sécurité.
- Peuvent être intégrés aux politiques de sécurité pour renforcer l'application de la conformité.

Pour des instructions détaillées sur la création et la gestion des frameworks de conformité centralisés, consultez [les frameworks de conformité centralisés](../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md).

## Workflows utilisateur {#user-workflows}

### Administrateurs d'instance {#instance-administrators}

Les administrateurs d'instance peuvent :

1. **Designate a compliance and security policy group** parmi vos groupes principaux existants
1. **Create security policies** dans le groupe désigné
1. **Create compliance frameworks** dans le groupe désigné
1. **Configure policy scope** pour déterminer où les politiques s'appliquent
1. **Scope policies to compliance frameworks** pour appliquer des politiques aux projets avec des frameworks spécifiques
1. **View policy coverage** pour comprendre quelles politiques sont actives dans les groupes et projets
1. **Edit and manage** les politiques et frameworks centralisés selon les besoins

### Administrateurs et propriétaires de groupe {#group-administrators-and-owners}

Les administrateurs et propriétaires de groupe peuvent :

- Consulter toutes les politiques applicables dans **Sécurisation** > **Politiques**, y compris les politiques définies localement et celles gérées de manière centralisée.
- Consulter et appliquer des frameworks de conformité centralisés aux projets de leurs groupes.
- Créer des politiques et des frameworks pour des groupes ou projets spécifiques, en complément des politiques et frameworks gérés de manière centralisée.
- Comprendre les sources des politiques grâce à des indicateurs clairs indiquant si les politiques proviennent de votre équipe ou de l'administration centrale.

> [!note]
> La page **Politiques** affiche uniquement les politiques du groupe de conformité et de politique de sécurité qui sont actuellement appliquées à votre groupe.

### Administrateurs et propriétaires de projet {#project-administrators-and-owners}

Les administrateurs et propriétaires de projet peuvent :

- Consulter toutes les politiques applicables dans **Sécurisation** > **Politiques**, y compris les politiques définies localement et celles gérées de manière centralisée.
- Consulter les frameworks de conformité appliqués à leurs projets, y compris les frameworks centralisés.
- Créer des politiques spécifiques au projet en complément de celles gérées de manière centralisée.
- Comprendre les sources des politiques grâce à des indicateurs clairs indiquant si les politiques proviennent de votre projet, de votre groupe ou de l'administration centrale.

> [!note]
> La page **Politiques** affiche uniquement les politiques de conformité et de politique de sécurité qui sont actuellement appliquées à votre groupe.

### Développeurs {#developers}

Les développeurs peuvent :

- Consulter toutes les politiques de sécurité qui s'appliquent à votre travail dans **Sécurisation** > **Politiques**.
- Consulter les frameworks de conformité appliqués aux projets sur lesquels ils travaillent.
- Comprendre les exigences de sécurité et de conformité grâce à une visibilité claire sur les politiques imposées de manière centralisée.

## Automatiser votre migration depuis des projets de politique de sécurité {#automate-your-migration-from-security-policy-projects}

Si vous utilisez déjà un projet de politique de sécurité pour appliquer des politiques sur plusieurs groupes, vous pouvez désigner l'un des groupes liés comme votre groupe de conformité et de politique de sécurité. Cependant, vous devez dissocier le projet de politique de sécurité de tous les groupes qui ne sont pas le groupe de conformité et de politique de sécurité. Sinon, les mêmes politiques sont appliquées deux fois dans ces groupes. Une fois depuis le groupe de politique de sécurité lié et une nouvelle fois depuis le groupe de conformité et de politique de sécurité.

Pour automatiser le processus de migration de vos groupes vers un groupe de conformité et de politique de sécurité, vous pouvez utiliser le script `csp_designation.rb` suivant.

Le script enregistre les identifiants de tous les groupes liés au projet de politique pour le groupe de conformité et de politique de sécurité dans le fichier de sauvegarde spécifié. Si nécessaire, cela vous permet de restaurer l'état précédent, y compris les liens vers le projet de politique de sécurité.

Prérequis :

- Vous devez disposer d'un projet de politique de sécurité lié au groupe que vous souhaitez désigner comme votre groupe de conformité et de politique de sécurité.

Pour utiliser le script :

1. Copiez l'intégralité du script `csp_designation.rb` depuis la section suivante.
1. Dans votre fenêtre de terminal, connectez-vous à votre instance.
1. Créez un nouveau fichier nommé `csp_designation.rb` et collez le script dans ce nouveau fichier.
1. Exécutez la commande suivante pour affecter un groupe de conformité et de politique de sécurité, en modifiant :
   - `<group_id>` par l'identifiant GitLab du groupe que vous souhaitez définir comme votre groupe de conformité et de politique de sécurité.
   - La première instance de `/path/to/` par le chemin complet du répertoire souhaité pour le fichier de sauvegarde.
   - La deuxième instance de `/path/to/` par le chemin complet du répertoire où vous avez enregistré le fichier `csp_designation.rb`.

   ```shell
   CSP_GROUP_ID=<group-id> BACKUP_FILENAME="/path/to/csp_backup.txt" ACTION=assign sudo gitlab-rails runner /path/to/csp_designation.rb
   ```

1. Facultatif. Si vous devez annuler l'intégralité de la modification, exécutez cette commande en utilisant le même identifiant de groupe, le même chemin de fichier de sauvegarde et le même chemin de script que ceux utilisés précédemment :

   ```shell
   CSP_GROUP_ID=<group-id> BACKUP_FILENAME="/path/to/csp_backup.txt" ACTION=unassign sudo gitlab-rails runner /path/to/csp_designation.rb
   ```

Pour plus d'informations, consultez la [section de dépannage de Rails Runner](../administration/operations/rails_console.md#troubleshooting).

### `csp_designation.rb` {#csp_designationrb}

```ruby
class CspDesignation
  def initialize(csp_group_id, backup_filename)
    @backup_filename = backup_filename
    @csp_group = Group.find_by_id(csp_group_id)
    @csp_configuration = @csp_group&.security_orchestration_policy_configuration
    @user = @csp_configuration&.policy_last_updated_by
    @spp = @csp_configuration&.security_policy_management_project
  end

  def assign
    check_spp!

    config_ids, group_ids = Security::OrchestrationPolicyConfiguration.for_management_project(@spp)
                                                                      .where.not(namespace: @csp_group)
                                                                      .pluck(:id, :namespace_id)
                                                                      .transpose
    if group_ids.present?
      puts "Saving group IDs to #{@backup_filename} as backup: #{group_ids}..."
      File.write(@backup_filename, "#{group_ids.join("\n")}\n")
    end

    puts "Setting #{@csp_group.full_path} as CSP..."
    Security::PolicySetting.in_organization(Organizations::Organization.default_organization).update! csp_namespace: @csp_group

    if config_ids.present?
      puts "Unassigning the policy project #{@spp.id} from the groups in the background to remove duplicate policies..."
      config_ids.each do |config_id|
        ::Security::DeleteOrchestrationConfigurationWorker.perform_async(
          config_id, @user.id, @spp.id
        )
      end
    end
    puts "Done."
  end

  def unassign
    check_spp!

    puts "Unassigning #{@csp_group.full_path} as CSP..."
    Security::PolicySetting.in_organization(Organizations::Organization.default_organization).update! csp_namespace: nil

    if File.exist?(@backup_filename)
      puts "Reading group IDs from #{@backup_filename} to restore the policy project links..."
      namespace_ids = File.read(@backup_filename).split("\n").map(&:to_i).reject(&:zero?)
      Namespace.id_in(namespace_ids).find_each(batch_size: 100) do |namespace|
        puts "Assigning the policy project to #{namespace.full_path}..."
        result = ::Security::Orchestration::AssignService.new(
          container: namespace, current_user: @user,
          params: { policy_project_id: @spp.id }
        ).execute
        puts "Failed to assign policy project to #{namespace.full_path}: #{result[:message]}" if result.error?
      end
    end
  end

  private

  def check_spp!
    raise "CSP policy project doesn't exist" if @spp.blank?
  end
end

SUPPORTED_ACTIONS = %w[assign unassign].freeze
action = ENV['ACTION']
csp_group_id = ENV['CSP_GROUP_ID']
backup_filename = ENV['BACKUP_FILENAME']
raise "Unknown action: #{action}. Use either 'assign' or 'unassign'." unless action.in? SUPPORTED_ACTIONS
raise "Missing CSP_GROUP_ID" if csp_group_id.blank?
raise "Missing BACKUP_FILENAME" if backup_filename.blank?

CspDesignation.new(csp_group_id, backup_filename).public_send(action)
```

## Dépannage {#troubleshooting}

**Unable to designate compliance and security policy group**

- Vérifiez que vous disposez des privilèges d'administrateur d'instance.
- Vérifiez que le groupe est un groupe principal (et non un sous-groupe).
- Vérifiez que le groupe existe et est accessible.

## Commentaires et assistance {#feedback-and-support}

Comme il s'agit d'une version bêta, les retours des utilisateurs sont encouragés. Partagez votre expérience, vos suggestions et vos éventuels problèmes via :

- [GitLab Issues](https://gitlab.com/gitlab-org/gitlab/-/issues).
- Vos canaux d'assistance GitLab habituels.

## Sujets connexes {#related-topics}

- [Frameworks de conformité centralisés](../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md)
- [Groupes de conformité et de politique de sécurité](../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md)
- [Centre de conformité](../user/compliance/compliance_center/_index.md)
- [Frameworks de conformité](../user/compliance/compliance_frameworks/_index.md)
