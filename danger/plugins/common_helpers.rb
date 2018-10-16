# frozen_string_literal: true

module Danger
  # Common helper functions for our danger scripts
  # If we find ourselves repeating code in our danger files, we might as well put them in here.
  class CommonHelpers < Plugin
    # Returns a list of all files that have been added, modified or renamed
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
      (git.added_files +
        git.modified_files +
        git.renamed_files.map { |x| x[:after] } -
        git.renamed_files.map { |x| x[:before] }).sort
    end
  end
end
