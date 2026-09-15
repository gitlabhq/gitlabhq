# frozen_string_literal: true

class ReplaceWakemeopsGlabInstallInExternalAgents < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  THIRD_PARTY_FLOW_TYPE = 3 # Ai::Catalog::Item.item_types[:third_party_flow]
  GITLAB_MAINTAINED = 100 # Namespaces::VerifiedNamespace::VERIFICATION_LEVELS[:gitlab_maintained]

  # rubocop:disable Layout/LineLength -- Better readability
  INSTALL_COMMAND =
    'if command -v glab > /dev/null 2>&1; then echo "glab already present, skipping installation"; ' \
      'else ( set -o pipefail && echo "Installing glab@1.111.0..." && ' \
      "GLAB_OS=$(uname -s | tr '[:upper:]' '[:lower:]') && " \
      'GLAB_ARCH=$(uname -m) && ' \
      'case "$GLAB_ARCH" in ' \
      'x86_64) GLAB_ARCH=amd64 ;; ' \
      'aarch64|arm64) GLAB_ARCH=arm64 ;; ' \
      '*) echo "Unsupported architecture: $GLAB_ARCH" >&2; exit 1 ;; ' \
      'esac && ' \
      'mkdir -p /tmp/bin /tmp/glab && ' \
      'curl --silent --show-error --fail --location --output /tmp/glab/glab.tar.gz ' \
      '"https://gitlab.com/gitlab-org/cli/-/releases/v1.111.0/downloads/glab_1.111.0_${GLAB_OS}_${GLAB_ARCH}.tar.gz" && ' \
      'case "${GLAB_OS}_${GLAB_ARCH}" in ' \
      'darwin_amd64) GLAB_SHA256=bf97aee449ae37e31e0ce9c052dd42840487317fa6159a42bce633ebda4f7333 ;; ' \
      'darwin_arm64) GLAB_SHA256=5cef8943f7aa73dcd619928d13ece8465a07962f1b036d74eef4f3d258d5cec3 ;; ' \
      'linux_amd64) GLAB_SHA256=d3aa186428ce6668455e2e35184c6f60b013840d759c7ea4cf02bac68d2a1827 ;; ' \
      'linux_arm64) GLAB_SHA256=13737967bf713574ac6c9b7316a8878c9a5920e1c1c3ccdc99772eafd274020a ;; ' \
      '*) echo "No vetted glab checksum for ${GLAB_OS}_${GLAB_ARCH}" >&2; exit 1 ;; ' \
      'esac && ' \
      'echo "$GLAB_SHA256 */tmp/glab/glab.tar.gz" | sha256sum --check --quiet && ' \
      'tar --extract --gzip --file /tmp/glab/glab.tar.gz --directory /tmp/glab && ' \
      'mv /tmp/glab/bin/glab /tmp/bin/ ' \
      ') || echo "Warning: glab installation failed; continuing without glab" >&2; fi'
  # rubocop:enable Layout/LineLength

  PATH_COMMAND = 'export PATH="/tmp/bin:$PATH"'

  NEW_YAML_BLOCK =
    "  - |\n    " \
      "#{INSTALL_COMMAND}\n  " \
      "- #{PATH_COMMAND}"

  AGENTS = [
    {
      name: 'Claude Agent by GitLab',
      old_yaml_block:
        "  - curl -sSL https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository | bash\n  " \
        "- apt-get install -y glab"
    },
    {
      name: 'Codex Agent by GitLab',
      old_yaml_block:
        "  - curl --silent --show-error --location " \
        "\"https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository\" | bash\n  " \
        "- apt-get install --yes glab"
    }
  ].freeze

  class AiCatalogItem < MigrationRecord
    self.table_name = 'ai_catalog_items'
  end

  class AiCatalogItemVersion < MigrationRecord
    self.table_name = 'ai_catalog_item_versions'
  end

  def up
    AGENTS.each do |agent|
      item_ids = AiCatalogItem
        .where(name: agent[:name], item_type: THIRD_PARTY_FLOW_TYPE, verification_level: GITLAB_MAINTAINED)
        .select(:id)

      AiCatalogItemVersion
        .where(ai_catalog_item_id: item_ids)
        .find_each { |version| fix_version(version, agent[:old_yaml_block]) }
    end
  end

  def down
    # no-op: Reverting would reinstate the third-party upciti/wakemeops mirror
    # that this migration removes for supply-chain safety.
  end

  private

  def fix_version(version, old_yaml_block)
    yaml = version.definition['yaml_definition']
    return unless yaml.is_a?(String) && yaml.include?(old_yaml_block)

    version.update_column(:definition, rebuild_definition(yaml.sub(old_yaml_block, NEW_YAML_BLOCK)))
  end

  # Inverse of the seeder's build_version: parse the fixed YAML and merge the
  # raw source back under 'yaml_definition'. Regenerating the commands array
  # from the YAML keeps both representations in sync and produces a row
  # byte-identical to a freshly-seeded one.
  def rebuild_definition(yaml)
    YAML.safe_load(yaml, permitted_classes: [], aliases: false)
        .merge('yaml_definition' => yaml)
  end
end
