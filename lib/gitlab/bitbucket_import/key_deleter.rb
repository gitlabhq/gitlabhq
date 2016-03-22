module Gitlab
  module BitbucketImport
    class KeyDeleter  < ImporterInit
      attr_reader :current_user

      def execute
        return false unless BitbucketImport.public_key.present?

        client.delete_deploy_key(project.import_source, BitbucketImport.public_key)

        true
      rescue
        false
      end
    end
  end
end
