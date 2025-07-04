---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Learn how to apply security policies and compliance frameworks across multiple groups and projects from a single, centralized location.
title: Instance-wide compliance and security policy management
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Status: Beta
{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/15864) in GitLab 18.2 [with a feature flag](../administration/feature_flags/_index.md) named `security_policies_csp`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is subject to change and may not ready for production use.

{{< /alert >}}

To apply security policies across multiple groups and projects from a single and centralized location, instance administrators can designate a compliance and security policy (CSP) group. This allows the instance administrators to:

- Create and configure security policies that automatically apply across your instance.
- Create compliance frameworks to make them available for other top-level groups.
- Scope policies to apply to compliance frameworks, groups, projects, or your entire instance.
- View comprehensive policy coverage to understand which policies are active and where they're active.
- Maintain centralized control while allowing teams to create their own additional policies.

## Prerequisites

- GitLab Self-Managed.
- GitLab 18.2 or later.
- You must be instance administrator.
- You must have an existing top-level group to serve as the CSP group.
- To use the REST API (optional), you must have a token with administrator access.

## Set up instance-wide compliance and security policy management

To set up instance-wide compliance and security policy management, you designate a CSP group and then create policies and compliance frameworks in the group.

### Designate a CSP group

You can designate a CSP group using either the GitLab UI or the REST API.

#### Using the GitLab UI

1. Go to **Admin Area** > **Settings** > **Security and Compliance**.
1. In the **Designate CSP Group** section, select an existing top-level group from the dropdown list.
1. Select **Save changes**.

#### Using the REST API

You can also designate a CSP group programmatically using the REST API. The API is useful for automation or when managing multiple instances.

To set a CSP group:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"csp_namespace_id": 123456}' \
  --url "https://gitlab.example.com/api/v4/admin/security/policy_settings"
```

To clear the CSP group:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"csp_namespace_id": null}' \
  --url "https://gitlab.example.com/api/v4/admin/security/policy_settings"
```

To get the current CSP settings:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/security/policy_settings"
```

For more information, see the [policy settings API documentation](../api/policy_settings.md).

The selected group becomes your compliance and security policy (CSP) group, serving as the central place to manage security policies and compliance frameworks across your instance.

### Security policy management in the CSP group

See the [centralized security policy management](../user/application_security/policies/centralized_security_policy_management.md) documentation.

## User workflows

### Instance administrators

Instance administrators can:

1. **Designate a CSP group** from your existing top-level groups
1. **Create CSP security policies** in the designated group
1. **Configure policy scope** to determine where policies apply
1. **View policy coverage** to understand which policies are active across groups and projects
1. **Edit and manage** centralized policies as needed

### Group administrators and owners

Group administrators and owners can:

- View all applicable policies in **Secure** > **Policies**, including both locally-defined and centrally-managed policies.
- Create team-specific policies in addition to centrally-managed ones.
- Understand policy sources with clear indicators that show whether policies come from your team or central administration.

{{< alert type="note" >}}

The **Policies** page displays only the policies from the CSP that are currently applied to your group.

{{< /alert >}}

### Project administrators and owners

Project administrators and owners can:

- View all applicable policies in **Secure** > **Policies**, including both locally-defined and centrally-managed policies.
- Create project-specific policies in addition to centrally-managed ones.
- Understand policy sources with clear indicators that show whether policies come from your project, group, or central administration.

{{< alert type="note" >}}

The **Policies** page displays only the policies from the CSP that are currently applied to your group.

{{< /alert >}}

### Developers

Developers can:

- View all security policies that apply to your work in the **Secure** > **Policies**.
- Understand security and compliance requirements with clear visibility into centrally-mandated policies.

## Beta considerations

- Performance testing: While using a CSP in not expected to impact performance, comprehensive performance testing is ongoing.
- Mixed permission scenarios: Some edge cases with mixed permissions may require additional validation
- User experience: Some UI elements may not be fully polished and could change in future releases
- Compliance framework scoping: Scoping policies to compliance frameworks is not supported in the Beta release.

## Automate your migration from security policy projects

If you already use a security policy project to enforce policies across multiple groups, you can designate one of the linked groups as your CSP group.
However, you should unlink the security policy project from all of the groups that are not the CSP group. Otherwise, the same policies
are enforced twice in those groups. Once from the linked security policy group and again from the CSP group.

To automate the process of migrating your groups to a CSP, you can use the following `csp_designation.rb` script.

The script saves the IDs of all groups that are linked to the CSP policy project in the specified backup file. If necessary, this allows you to restore the previous state, including the links to the security policy project.

Prerequisites:

- You must have a security policy project linked to the group that you want to designate as your CSP group.

To use the script:

1. Copy the entire `csp_designation.rb` script from the following section.
1. In your terminal window, connect to your instance.
1. Create a new file named `csp_designation.rb` and paste the script in the new file.
1. Run the following command to assign a CSP group, changing:
   - `<group_id>` to the GitLab ID of the group you want to set as your CSP group.
   - The first `/path/to/` instance to the full path of your desired directory for the backup file.
   - The second `/path/to/` instance to the full path of the directory where you saved the `csp_designation.rb` file.

   ```shell
   CSP_GROUP_ID=<group-id> BACKUP_FILENAME="/path/to/csp_backup.txt" ACTION=assign sudo gitlab-rails runner /path/to/csp_designation.rb
   ```

1. Optional. If you need to revert the entire change, run this command, using the same group ID, backup file path, and script path that you used previously:

   ```shell
   CSP_GROUP_ID=<group-id> BACKUP_FILENAME="/path/to/csp_backup.txt" ACTION=unassign sudo gitlab-rails runner /path/to/csp_designation.rb
   ```

For more information, see the [Rails Runner troubleshooting section](../administration/operations/rails_console.md#troubleshooting).

### `csp_designation.rb`

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
    Security::PolicySetting.instance.update! csp_namespace: @csp_group

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
    Security::PolicySetting.instance.update! csp_namespace: nil

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

## Troubleshooting

**Unable to designate CSP group**

- Verify that you have instance administrator privileges.
- Verify that the group is a top-level group (not a subgroup).
- Verify that the group exists and is accessible.

## Feedback and support

As this is a Beta release, we actively seek feedback from users. Share your experience, suggestions, and any issues through:

- [GitLab Issues](https://gitlab.com/gitlab-org/gitlab/-/issues).
- Your regular GitLab support channels.
