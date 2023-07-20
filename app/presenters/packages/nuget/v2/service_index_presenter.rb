# frozen_string_literal: true

module Packages
  module Nuget
    module V2
      class ServiceIndexPresenter
        include API::Helpers::RelatedResourcesHelpers

        ROOT_ATTRIBUTES = {
          xmlns: 'http://www.w3.org/2007/app',
          'xmlns:atom' => 'http://www.w3.org/2005/Atom'
        }.freeze

        def initialize(project_or_group)
          @project_or_group = project_or_group
        end

        def xml
          Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            xml.service(ROOT_ATTRIBUTES.merge('xml:base' => xml_base)) do
              xml.workspace do
                xml['atom'].title('Default', type: 'text')
                xml.collection(href: 'Packages') do
                  xml['atom'].title('Packages', type: 'text')
                end
              end
            end
          end
        end

        private

        attr_reader :project_or_group

        def xml_base
          base_path = case project_or_group
                      when Project
                        api_v4_projects_packages_nuget_v2_path(id: project_or_group.id)
                      when Group
                        api_v4_groups___packages_nuget_v2_path(id: project_or_group.id)
                      end

          expose_url(base_path)
        end
      end
    end
  end
end
