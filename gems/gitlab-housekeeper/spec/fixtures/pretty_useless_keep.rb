# frozen_string_literal: true

module Keeps
  class PrettyUselessKeep < ::Gitlab::Housekeeper::Keep
    def each_change
      (1..3).each do |i|
        file_name = "new_file#{i}.txt"

        `touch #{file_name}`

        change = ::Gitlab::Housekeeper::Change.new

        change.identifiers = [self.class.name.demodulize, "new_file#{i}"]

        change.title = "Make new file #{file_name}"

        change.description = <<~MARKDOWN
        ## New files

        This MR makes a new file #{file_name}
        MARKDOWN

        change.labels = %w[type::feature]

        change.changed_files = [file_name]

        # to push changes without triggering a pipeline.
        change.push_options.ci_skip = true

        yield(change)
      end
    end
  end
end
