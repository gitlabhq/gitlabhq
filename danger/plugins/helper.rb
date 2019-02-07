# frozen_string_literal: true

module Danger
  # Common helper functions for our danger scripts
  # If we find ourselves repeating code in our danger files, we might as well put them in here.
  class Helper < Plugin
    # Returns a list of all files that have been added, modified or renamed.
    # `git.modified_files` might contain paths that already have been renamed,
    # so we need to remove them from the list.
    #
    # Considering these changes:
    #
    # - A new_file.rb
    # - D deleted_file.rb
    # - M modified_file.rb
    # - R renamed_file_before.rb -> renamed_file_after.rb
    #
    # it will return
    # ```
    # [ 'new_file.rb', 'modified_file.rb', 'renamed_file_after.rb' ]
    # ```
    #
    # @return [Array<String>]
    def all_changed_files
      Set.new
        .merge(git.added_files.to_a)
        .merge(git.modified_files.to_a)
        .merge(git.renamed_files.map { |x| x[:after] })
        .subtract(git.renamed_files.map { |x| x[:before] })
        .to_a
        .sort
    end

    # @return [Boolean]
    def ee?
      ENV['CI_PROJECT_NAME'] == 'gitlab-ee' || File.exist?('../../CHANGELOG-EE.md')
    end

    # @return [Hash<String,Array<String>>]
    def changes_by_category
      all_changed_files.inject(Hash.new { |h, k| h[k] = [] }) do |hsh, file|
        hsh[category_for_file(file)] << file
      end
    end

    def category_for_file(file)
      _, category = CATEGORIES.find { |regexp, _| regexp.match?(file) }

      category || :unknown
    end

    CATEGORIES = {
      %r{\Adoc/} => :documentation
    }
  end
end
