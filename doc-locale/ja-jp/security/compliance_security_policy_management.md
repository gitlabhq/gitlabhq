---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 単一の集中管理された場所から、複数のグループやプロジェクトにセキュリティポリシーとコンプライアンスフレームワークを適用する方法を説明します。
title: インスタンス全体のコンプライアンスとセキュリティポリシー管理
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: ベータ{{< /details >}}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/groups/gitlab-org/-/epics/15864)され、[機能フラグ](../administration/feature_flags/_index.md)`security_policies_csp`という名前が付けられています。デフォルトでは無効になっています。
- GitLab 18.3のGitLab Self-Managedで[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/550318)。
- GitLab 18.5で[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/17392)になりました。機能フラグ`security_policies_csp`は削除されました。

{{< /history >}}

インスタンス管理者は、一元化された場所から複数のグループやプロジェクトにセキュリティポリシーとコンプライアンスフレームワークを適用するために、コンプライアンスとセキュリティポリシー（CSP）グループを指定できます。これにより、インスタンス管理者は以下を実行できます:

- インスタンス全体に自動的に適用されるセキュリティポリシーを作成および構成します。
- 一元化されたコンプライアンスフレームワークを作成して、他のトップレベルグループで使用できるようにします。
- セキュリティポリシーのコンプライアンスフレームワーク、グループ、プロジェクト、またはインスタンス全体への適用範囲をスコープします。
- 包括的なポリシーカバレッジを表示して、どのセキュリティポリシーがアクティブで、どこでアクティブになっているかを把握します。
- チームが独自の追加ポリシーとフレームワークを作成できるようにしながら、一元的なコントロールを維持します。

## 前提要件 {#prerequisites}

- GitLab Self-Managed。
- GitLab 18.2以降。
- インスタンス管理者である必要があります。
- コンプライアンスとセキュリティポリシーグループとして機能する既存のトップレベルグループが必要です。
- REST API（オプション）を使用するには、管理者アクセス権を持つトークンが必要です。

## インスタンス全体のコンプライアンスとセキュリティポリシー管理 {#set-up-instance-wide-compliance-and-security-policy-management}

インスタンス全体のコンプライアンスとセキュリティポリシー管理をセットアップするには、コンプライアンスとセキュリティポリシーグループを指定し、そのグループでセキュリティポリシーとコンプライアンスフレームワークを作成します。

### コンプライアンスとセキュリティポリシーグループの指定 {#designate-a-compliance-and-security-policy-group}

コンプライアンスとセキュリティポリシーグループは、GitLabユーザーインターフェースまたはREST APIを使用して指定できます。

#### GitLab UIの使用 {#using-the-gitlab-ui}

1. **管理者エリア** > **設定** > **セキュリティとコンプライアンス**に移動します。
1. **CSPグループの指定**セクションで、ドロップダウンリストから既存のトップレベルグループを選択します。
1. **変更を保存**を選択します。

#### REST APIの使用 {#using-the-rest-api}

REST APIを使用して、プログラムでコンプライアンスとセキュリティポリシーグループを指定することもできます。このAPIは、自動化や複数のインスタンスを管理する場合に役立ちます。

コンプライアンスフレームワークとセキュリティポリシーグループの設定:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"csp_namespace_id": 123456}' \
  --url "https://gitlab.example.com/api/v4/admin/security/policy_settings"
```

コンプライアンスとセキュリティポリシーグループをクリアするには:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"csp_namespace_id": null}' \
  --url "https://gitlab.example.com/api/v4/admin/security/policy_settings"
```

現在のコンプライアンスとセキュリティポリシー設定を取得するには:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/security/policy_settings"
```

詳細については、[ポリシー設定APIドキュメント](../api/compliance_policy_settings.md)を参照してください。

選択したグループがコンプライアンスとセキュリティポリシーグループになり、インスタンス全体のセキュリティポリシーとコンプライアンスフレームワークを管理するための中央拠点として機能します。

### コンプライアンスとセキュリティポリシーグループのセキュリティポリシー管理 {#security-policy-management-in-the-compliance-and-security-policy-group}

セキュリティポリシーについては、[コンプライアンスとセキュリティポリシーグループ](../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md)のドキュメントを参照してください。

### 一元化されたコンプライアンスフレームワーク管理 {#centralized-compliance-framework-management}

コンプライアンスとセキュリティポリシーグループを指定すると、インスタンス内のすべてのトップレベルグループで自動的に使用できるコンプライアンスフレームワークを作成できます。これにより、組織全体でコンプライアンスへの一貫したアプローチが提供されます。

コンプライアンスとセキュリティポリシーグループで作成されたコンプライアンスフレームワーク:

- インスタンス内の他のトップレベルグループに対して表示および利用可能です。
- グループオーナーはプロジェクトに割り当てることができます。
- コンプライアンスとセキュリティポリシーグループの外部のユーザーに対しては読み取り専用です。
- 強化されたコンプライアンスの実施のために、セキュリティポリシーと統合できます。

一元化されたコンプライアンスフレームワークの作成と管理の詳細な手順については、[一元化されたコンプライアンスフレームワーク](../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md)を参照してください。

## ユーザーワークフロー {#user-workflows}

### インスタンス管理者 {#instance-administrators}

インスタンス管理者は次のことができます:

1. 既存のトップレベルグループから**Designate a compliance and security policy group**（コンプライアンスとセキュリティポリシーグループを指定）します
1. 指定されたグループに**Create security policies**（セキュリティポリシーを作成）します
1. 指定されたグループに**Create compliance frameworks**（コンプライアンスフレームワークを作成）します
1. ポリシーの適用場所を決定するために**Configure policy scope**（セキュリティポリシーのスコープを構成）します
1. 特定のフレームワークを持つプロジェクトでポリシーを適用するために**Scope policies to compliance frameworks**（セキュリティポリシーをコンプライアンスフレームワークにスコープします）
1. グループとプロジェクト全体でどのポリシーがアクティブであるかを理解するために**View policy coverage**（ポリシーカバレッジを表示）します
1. 必要に応じて、一元化されたポリシーとフレームワークを**Edit and manage**（編集および管理）します

### グループ管理者とオーナー {#group-administrators-and-owners}

グループ管理者とオーナーは次のことができます:

- ローカルで定義されたポリシーと一元的に管理されたポリシーの両方を含む、**セキュリティ**>**ポリシー**の適用可能なすべてのポリシーを表示します。
- 一元化されたコンプライアンスフレームワークを表示し、グループ内のプロジェクトに適用します。
- 一元的に管理されたポリシーとフレームワークに加えて、特定のグループまたはプロジェクトのポリシーとフレームワークを作成します。
- ポリシーがチームまたは中央管理のどちらから提供されたかを示す明確な指標を使用して、ポリシーソースを理解します。

{{< alert type="note" >}}

**ポリシー**ページには、グループに現在適用されているコンプライアンスとセキュリティポリシーグループのポリシーのみが表示されます。

{{< /alert >}}

### プロジェクト管理者とオーナー {#project-administrators-and-owners}

プロジェクト管理者とオーナーは次のことができます:

- ローカルで定義されたポリシーと一元的に管理されたポリシーの両方を含む、**セキュリティ**>**ポリシー**の適用可能なすべてのポリシーを表示します。
- 一元化されたフレームワークを含む、どのコンプライアンスフレームワークが自分のプロジェクトに適用されているかを表示します。
- 一元的に管理されたポリシーに加えて、プロジェクト固有のポリシーを作成します。
- ポリシーがプロジェクト、グループ、または中央管理のどこから提供されたかを示す明確な指標を使用して、ポリシーソースを理解します。

{{< alert type="note" >}}

**ポリシー**ページには、グループに現在適用されているコンプライアンスとセキュリティポリシーからのポリシーのみが表示されます。

{{< /alert >}}

### デベロッパー {#developers}

デベロッパーは次のことができます:

- **セキュリティ**>**ポリシー**で、自分の作業に適用されるすべてのセキュリティポリシーを表示します。
- 作業対象のプロジェクトにどのコンプライアンスフレームワークが適用されているかを表示します。
- 一元的に義務付けられたポリシーを明確に把握することで、セキュリティとコンプライアンスの要件を理解します。

## セキュリティポリシープロジェクトからの移行を自動化する {#automate-your-migration-from-security-policy-projects}

複数のグループにわたってポリシーを適用するためにセキュリティポリシープロジェクトをすでに使用している場合は、リンクされたグループの1つをコンプライアンスとセキュリティポリシーグループとして指定できます。ただし、コンプライアンスとセキュリティポリシーグループではないすべてのグループから、セキュリティポリシープロジェクトのリンクを解除する必要があります。そうしないと、同じセキュリティポリシーがそれらのグループで2回適用されます。リンクされたセキュリティポリシーグループから1回、コンプライアンスとセキュリティポリシーグループからもう1回。

グループをコンプライアンスとセキュリティポリシーグループに移行するプロセスを自動化するには、次の`csp_designation.rb`スクリプトを使用します。

このスクリプトは、指定されたバックアップファイルに、コンプライアンスとセキュリティポリシーグループのセキュリティポリシープロジェクトにリンクされているすべてのグループのIDを保存します。必要に応じて、これにより、セキュリティポリシープロジェクトへのリンクを含む、以前の状態を復元できます。

前提要件: 

- コンプライアンスとセキュリティポリシーグループとして指定するグループにリンクされたセキュリティポリシープロジェクトが必要です。

スクリプトを使用するには:

1. 次のセクションから`csp_designation.rb`スクリプト全体をコピーします。
1. ターミナルウィンドウで、インスタンスに接続します。
1. `csp_designation.rb`という名前の新しいファイルを作成し、新しいファイルにスクリプトを貼り付けます。
1. 次のコマンドを実行してコンプライアンスとセキュリティポリシーグループを割り当て、以下を変更します:
   - `<group_id>`を、コンプライアンスとセキュリティポリシーグループとして設定するグループのGitLab IDに変更します。
   - 最初の`/path/to/`インスタンスを、バックアップファイルに必要なディレクトリのフルパスに変更します。
   - 2番目の`/path/to/`インスタンスを、`csp_designation.rb`ファイルを保存したディレクトリのフルパスに変更します。

   ```shell
   CSP_GROUP_ID=<group-id> BACKUP_FILENAME="/path/to/csp_backup.txt" ACTION=assign sudo gitlab-rails runner /path/to/csp_designation.rb
   ```

1. オプション。変更全体を元に戻す必要がある場合は、以前に使用したのと同じグループID、バックアップファイルのパス、およびスクリプトパスを使用して、このコマンドを実行します:

   ```shell
   CSP_GROUP_ID=<group-id> BACKUP_FILENAME="/path/to/csp_backup.txt" ACTION=unassign sudo gitlab-rails runner /path/to/csp_designation.rb
   ```

詳細については、[Railsランナーのトラブルシューティングセクション](../administration/operations/rails_console.md#troubleshooting)を参照してください。

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
    Security::PolicySetting.for_organization(Organizations::Organization.default_organization).update! csp_namespace: @csp_group

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
    Security::PolicySetting.for_organization(Organizations::Organization.default_organization).update! csp_namespace: nil

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

## トラブルシューティング {#troubleshooting}

**Unable to designate compliance and security policy group**（コンプライアンスとセキュリティポリシーグループを指定できません）

- インスタンス管理者の権限があることを確認します。
- グループがトップレベルグループ（サブグループではない）であることを確認します。
- グループが存在し、アクセス可能であることを確認します。

## フィードバックとサポート {#feedback-and-support}

これはベータリリースであるため、ユーザーからのフィードバックを積極的に求めています。次の方法で、経験、提案、および問題を共有してください:

- [GitLabイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues)。
- 通常のGitLabサポートチャンネル。

## 関連トピック {#related-topics}

- [一元化されたコンプライアンスフレームワーク](../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md)
- [コンプライアンスとセキュリティポリシーグループ](../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md)
- [コンプライアンスセンター](../user/compliance/compliance_center/_index.md)
- [コンプライアンスフレームワーク](../user/compliance/compliance_frameworks/_index.md)
