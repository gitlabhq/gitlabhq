module EE
  module Gitlab
    module ImportSources
      extend ::Gitlab::Utils::Override

      override :import_table
      def import_table
        super + ee_import_table
      end

      def ee_import_table
        # This method can be called/loaded before the database
        # has been created. With this guard clause we prevent calling
        # the License table until the connection has been established
        return [] unless ActiveRecord::Base.connected? && License.feature_available?(:custom_project_templates)

        [::Gitlab::ImportSources::ImportSource.new('gitlab_custom_project_template',
                                                   'GitLab custom project template export',
                                                   ::Gitlab::ImportExport::Importer)]
      end
    end
  end
end
