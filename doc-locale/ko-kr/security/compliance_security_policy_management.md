---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 단일의 중앙화된 위치에서 여러 그룹과 프로젝트에 걸쳐 보안 정책 및 준수 프레임워크를 적용하는 방법을 알아봅니다.
title: 인스턴스 전체 준수 및 보안 정책 관리
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `security_policies_csp`라는 이름의 [기능 플래그](../administration/feature_flags/_index.md)로 GitLab 18.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/15864)되었습니다. 기본적으로 사용 중지되어 있습니다.
- GitLab Self-Managed에서 GitLab 18.3에서 [기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/550318)
- GitLab 18.5에서 [일반적으로 사용 가능](https://gitlab.com/groups/gitlab-org/-/epics/17392)합니다. `security_policies_csp` 기능 플래그가 제거되었습니다.

{{< /history >}}

단일의 중앙화된 위치에서 여러 그룹과 프로젝트에 걸쳐 보안 정책 및 준수 프레임워크를 적용하려면 인스턴스 관리자가 준수 및 보안 정책(CSP) 그룹을 지정할 수 있습니다. 이를 통해 인스턴스 관리자는 다음을 수행할 수 있습니다:

- 인스턴스 전체에 자동으로 적용되는 보안 정책을 생성하고 구성합니다.
- 다른 최상위 그룹에서 사용할 수 있도록 중앙화된 준수 프레임워크를 생성합니다.
- 준수 프레임워크, 그룹, 프로젝트 또는 전체 인스턴스에 적용되도록 정책의 범위를 지정합니다.
- 어떤 정책이 활성화되어 있는지, 어디에 활성화되어 있는지 이해하기 위해 포괄적인 정책 범위를 봅니다.
- 팀이 자신의 추가 정책 및 프레임워크를 생성할 수 있도록 허용하면서 중앙화된 제어를 유지합니다.

## 전제 조건 {#prerequisites}

- GitLab 18.2 이상
- 인스턴스 관리자여야 합니다.
- 준수 및 보안 정책 그룹으로 사용할 기존 최상위 그룹이 필요합니다.
- REST API를 사용하려면(선택 사항) 관리자 액세스 권한이 있는 토큰이 필요합니다.

## 인스턴스 전체 준수 및 보안 정책 관리 설정 {#set-up-instance-wide-compliance-and-security-policy-management}

인스턴스 전체 준수 및 보안 정책 관리를 설정하려면 준수 및 보안 정책 그룹을 지정한 다음 해당 그룹에서 정책 및 준수 프레임워크를 생성합니다.

### 준수 및 보안 정책 그룹 지정 {#designate-a-compliance-and-security-policy-group}

GitLab UI 또는 REST API를 사용하여 준수 및 보안 정책 그룹을 지정할 수 있습니다.

#### GitLab UI 사용 {#using-the-gitlab-ui}

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **Security and Compliance**를 선택합니다.
1. **Designate CSP Group** 섹션에서 드롭다운 목록에서 기존 최상위 그룹을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

#### REST API 사용 {#using-the-rest-api}

REST API를 사용하여 프로그래밍 방식으로 준수 및 보안 정책 그룹을 지정할 수도 있습니다. API는 자동화 또는 여러 인스턴스를 관리할 때 유용합니다.

준수 및 보안 정책 그룹을 설정하려면:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"csp_namespace_id": 123456}' \
  --url "https://gitlab.example.com/api/v4/admin/security/policy_settings"
```

준수 및 보안 정책 그룹을 삭제하려면:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"csp_namespace_id": null}' \
  --url "https://gitlab.example.com/api/v4/admin/security/policy_settings"
```

현재 준수 및 보안 정책 설정을 가져오려면:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/security/policy_settings"
```

자세한 내용은 [정책 설정 API 문서](../api/compliance_policy_settings.md)를 참조하세요.

선택한 그룹은 인스턴스 전체에서 보안 정책 및 준수 프레임워크를 관리하기 위한 중앙 위치로 사용되는 준수 및 보안 정책 그룹이 됩니다.

### 준수 및 보안 정책 그룹의 보안 정책 관리 {#security-policy-management-in-the-compliance-and-security-policy-group}

[준수 및 보안 정책 그룹](../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md) 설명서에서 보안 정책을 참조하세요.

### 중앙화된 준수 프레임워크 관리 {#centralized-compliance-framework-management}

준수 및 보안 정책 그룹을 지정한 후 인스턴스의 모든 최상위 그룹에 자동으로 사용할 수 있는 준수 프레임워크를 생성할 수 있습니다. 이를 통해 조직 전체에서 준수에 대한 일관된 접근 방식을 제공합니다.

준수 및 보안 정책 그룹에서 생성된 준수 프레임워크:

- 인스턴스의 다른 최상위 그룹에 대해 표시되고 사용 가능합니다.
- 그룹 소유자가 프로젝트에 적용할 수 있습니다.
- 준수 및 보안 정책 그룹 외부의 사용자에게는 읽기 전용입니다.
- 향상된 준수 적용을 위해 보안 정책과 통합될 수 있습니다.

중앙화된 준수 프레임워크를 생성하고 관리하는 방법에 대한 자세한 지침은 [중앙화된 준수 프레임워크](../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md)를 참조하세요.

## 사용자 워크플로우 {#user-workflows}

### 인스턴스 관리자 {#instance-administrators}

인스턴스 관리자는 다음을 수행할 수 있습니다:

1. 기존 최상위 그룹에서 **Designate a compliance and security policy group**
1. 지정된 그룹에 **Create security policies**
1. 지정된 그룹에 **Create compliance frameworks**
1. 정책이 적용될 위치를 결정하려면 **Configure policy scope**
1. 특정 프레임워크가 있는 프로젝트에 정책을 적용하려면 **Scope policies to compliance frameworks**
1. 그룹과 프로젝트 전체에서 활성화된 정책을 이해하려면 **View policy coverage**
1. 필요에 따라 중앙화된 정책 및 프레임워크를 **Edit and manage**

### 그룹 관리자 및 소유자 {#group-administrators-and-owners}

그룹 관리자 및 소유자는 다음을 수행할 수 있습니다:

- **보안** > **정책**에서 로컬로 정의된 정책과 중앙에서 관리하는 정책을 포함한 모든 적용 가능한 정책을 봅니다.
- 중앙화된 준수 프레임워크를 자신의 그룹의 프로젝트에 보기 및 적용합니다.
- 중앙에서 관리하는 정책 및 프레임워크 외에도 특정 그룹 또는 프로젝트에 대한 정책 및 프레임워크를 생성합니다.
- 정책이 팀에서 오는지 또는 중앙 관리에서 오는지 보여주는 명확한 표시기로 정책 소스를 이해합니다.

> [!note]
> **정책** 페이지는 현재 그룹에 적용되는 준수 및 보안 정책 그룹의 정책만 표시합니다.

### 프로젝트 관리자 및 소유자 {#project-administrators-and-owners}

프로젝트 관리자 및 소유자는 다음을 수행할 수 있습니다:

- **보안** > **정책**에서 로컬로 정의된 정책과 중앙에서 관리하는 정책을 포함한 모든 적용 가능한 정책을 봅니다.
- 중앙화된 프레임워크를 포함하여 프로젝트에 적용된 준수 프레임워크를 봅니다.
- 중앙에서 관리하는 정책 외에도 프로젝트별 정책을 생성합니다.
- 정책이 프로젝트, 그룹 또는 중앙 관리에서 오는지 보여주는 명확한 표시기로 정책 소스를 이해합니다.

> [!note]
> **정책** 페이지는 현재 그룹에 적용되는 준수 및 보안 정책의 정책만 표시합니다.

### 개발자 {#developers}

개발자는 다음을 수행할 수 있습니다:

- **보안** > **정책**에서 작업에 적용되는 모든 보안 정책을 봅니다.
- 작업 중인 프로젝트에 적용된 준수 프레임워크를 봅니다.
- 중앙에서 위임된 정책에 대한 명확한 가시성으로 보안 및 준수 요구 사항을 이해합니다.

## 보안 정책 프로젝트에서의 마이그레이션 자동화 {#automate-your-migration-from-security-policy-projects}

이미 보안 정책 프로젝트를 사용하여 여러 그룹에 걸쳐 정책을 적용하는 경우 연결된 그룹 중 하나를 준수 및 보안 정책 그룹으로 지정할 수 있습니다. 그러나 준수 및 보안 정책 그룹이 아닌 모든 그룹에서 보안 정책 프로젝트의 링크를 해제해야 합니다. 그렇지 않으면 같은 정책이 해당 그룹에서 두 번 적용됩니다. 연결된 보안 정책 그룹에서 한 번, 준수 및 보안 정책 그룹에서 다시 한 번.

그룹을 준수 및 보안 정책 그룹으로 마이그레이션하는 과정을 자동화하려면 다음 `csp_designation.rb` 스크립트를 사용할 수 있습니다.

스크립트는 준수 및 보안 정책 그룹의 정책 프로젝트에 연결된 모든 그룹의 ID를 지정된 백업 파일에 저장합니다. 필요한 경우 보안 정책 프로젝트 링크를 포함한 이전 상태를 복원할 수 있습니다.

전제 조건:

- 준수 및 보안 정책 그룹으로 지정하려는 그룹에 연결된 보안 정책 프로젝트가 있어야 합니다.

스크립트를 사용하려면:

1. 다음 섹션에서 전체 `csp_designation.rb` 스크립트를 복사합니다.
1. 터미널 창에서 인스턴스에 연결합니다.
1. `csp_designation.rb` 파일을 새로 만들고 스크립트를 새 파일에 붙여넣습니다.
1. 다음 명령을 실행하여 준수 및 보안 정책 그룹을 할당하고 다음을 변경합니다:
   - `<group_id>`을(를) 준수 및 보안 정책 그룹으로 설정하려는 그룹의 GitLab ID로.
   - 첫 번째 `/path/to/` 인스턴스를 백업 파일에 대한 원하는 디렉터리의 전체 경로로.
   - 두 번째 `/path/to/` 인스턴스를 `csp_designation.rb` 파일을 저장한 디렉터리의 전체 경로로.

   ```shell
   CSP_GROUP_ID=<group-id> BACKUP_FILENAME="/path/to/csp_backup.txt" ACTION=assign sudo gitlab-rails runner /path/to/csp_designation.rb
   ```

1. 선택 사항. 전체 변경을 되돌려야 하는 경우 이전에 사용한 것과 동일한 그룹 ID, 백업 파일 경로 및 스크립트 경로를 사용하여 이 명령을 실행합니다:

   ```shell
   CSP_GROUP_ID=<group-id> BACKUP_FILENAME="/path/to/csp_backup.txt" ACTION=unassign sudo gitlab-rails runner /path/to/csp_designation.rb
   ```

자세한 내용은 [Rails Runner 문제 해결 섹션](../administration/operations/rails_console.md#troubleshooting)을(를) 참조하세요.

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

## 문제 해결 {#troubleshooting}

**Unable to designate compliance and security policy group**

- 인스턴스 관리자 권한이 있는지 확인합니다.
- 그룹이 최상위 그룹인지 확인합니다(하위 그룹이 아님).
- 그룹이 존재하고 액세스 가능한지 확인합니다.

## 피드백 및 지원 {#feedback-and-support}

이것이 베타 릴리스이기 때문에 사용자 피드백을 권장합니다. 다음을 통해 경험, 제안 및 문제를 공유합니다:

- [GitLab Issues](https://gitlab.com/gitlab-org/gitlab/-/issues).
- 정기적인 GitLab 지원 채널.

## 관련 항목 {#related-topics}

- [중앙화된 준수 프레임워크](../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md)
- [준수 및 보안 정책 그룹](../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md)
- [준수 센터](../user/compliance/compliance_center/_index.md)
- [준수 프레임워크](../user/compliance/compliance_frameworks/_index.md)
