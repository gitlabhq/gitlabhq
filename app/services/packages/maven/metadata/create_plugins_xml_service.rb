# frozen_string_literal: true

module Packages
  module Maven
    module Metadata
      class CreatePluginsXmlService < BaseCreateXmlService
        XPATH_PLUGIN_ARTIFACT_ID = '//plugin/artifactId'
        XPATH_PLUGINS = '//metadata/plugins'
        EMPTY_PLUGINS_PAYLOAD = {
          changes_exist: true,
          empty_plugins: true
        }.freeze

        def execute
          return ServiceResponse.error(message: 'package not set') unless @package
          return ServiceResponse.error(message: 'metadata_content not set') unless @metadata_content
          return ServiceResponse.error(message: 'metadata_content is invalid') unless plugins_xml_node.present?
          return ServiceResponse.success(payload: EMPTY_PLUGINS_PAYLOAD) if plugin_artifact_ids_from_database.empty?

          changes_exist = update_plugins_list

          payload = { changes_exist: changes_exist, empty_versions: false }
          payload[:metadata_content] = xml_doc.to_xml(indent: INDENT_SPACE) if changes_exist

          ServiceResponse.success(payload: payload)
        end

        private

        def update_plugins_list
          return false if plugin_artifact_ids_from_xml == plugin_artifact_ids_from_database

          plugins_xml_node.children.remove

          plugin_artifact_ids_from_database.each do |artifact_id|
            plugins_xml_node.add_child(plugin_node_for(artifact_id))
          end

          true
        end

        def plugins_xml_node
          strong_memoize(:plugins_xml_node) do
            xml_doc.xpath(XPATH_PLUGINS)
                   .first
          end
        end

        def plugin_artifact_ids_from_xml
          strong_memoize(:plugin_artifact_ids_from_xml) do
            plugins_xml_node.xpath(XPATH_PLUGIN_ARTIFACT_ID)
                            .map(&:content)
          end
        end

        def plugin_artifact_ids_from_database
          strong_memoize(:plugin_artifact_ids_from_database) do
            package_names = plugin_artifact_ids_from_xml.map do |artifact_id|
              "#{@package.name}/#{artifact_id}"
            end

            packages = @package.project.packages
                                       .maven
                                       .displayable
                                       .with_name(package_names)
                                       .has_version

            ::Packages::Maven::Metadatum.for_package_ids(packages.select(:id))
                                        .order_created
                                        .pluck_app_name
                                        .uniq
          end
        end

        def plugin_node_for(artifact_id)
          xml_doc.create_element('plugin').tap do |plugin_node|
            plugin_node.add_child(xml_node('name', artifact_id))
            plugin_node.add_child(xml_node('prefix', prefix_from(artifact_id)))
            plugin_node.add_child(xml_node('artifactId', artifact_id))
          end
        end

        # Maven plugin prefix generation from
        # https://github.com/apache/maven/blob/c3dba0e5ba71ee7cbd62620f669a8c206e71b5e2/maven-plugin-api/src/main/java/org/apache/maven/plugin/descriptor/PluginDescriptor.java#L189
        def prefix_from(artifact_id)
          artifact_id.gsub(/-?maven-?/, '')
                     .gsub(/-?plugin-?/, '')
        end
      end
    end
  end
end
