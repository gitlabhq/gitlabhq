# frozen_string_literal: true

module SystemCheck
  module App
    class HashedStorageAllProjectsCheck < SystemCheck::BaseCheck
      set_name 'All projects are in hashed storage?'

      def check?
        !Project.with_unmigrated_storage.exists?
      end

      def show_error
        try_fixing_it(
          "Please migrate all projects to hashed storage#{' on the primary' if Gitlab.ee? && Gitlab::Geo.secondary?}",
          "as legacy storage is deprecated in 13.0 and support will be removed in 14.0."
        )

        for_more_information('doc/administration/repository_storage_types.md')
      end
    end
  end
end
