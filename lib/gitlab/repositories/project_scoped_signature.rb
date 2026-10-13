# frozen_string_literal: true

module Gitlab
  module Repositories
    module ProjectScopedSignature
      extend ::Gitlab::Utils::Override

      private

      override :lazy_signature
      def lazy_signature
        BatchLoader.for([commit.project.id, commit.sha]).batch(key: signature_class) do |project_sha_pairs, loader|
          project_ids = project_sha_pairs.map(&:first).uniq
          shas = project_sha_pairs.map(&:last).uniq

          signature_class.by_commit_shas_and_project_ids(shas, project_ids).each do |signature|
            loader.call([signature.project_id, signature.commit_sha], signature)
          end
        end
      end
    end
  end
end
