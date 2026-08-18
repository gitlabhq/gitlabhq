# frozen_string_literal: true

module Gitlab
  module HeadingSlug
    extend self

    # Mimics Comrak's anchorize(): https://github.com/kivikakk/comrak/blob/v0.53.0/src/html/anchorizer.rs
    def from_text(text)
      text.downcase
        .gsub(/[^\p{L}\p{M}\p{N}\p{Pc} -]/, '')
        .tr(' ', '-')
    end

    def prefix_from_file_path(file_path)
      return unless file_path

      name = File.basename(file_path, File.extname(file_path))
      slug = from_text(name)
      return if slug.blank?

      "#{slug}-"
    end
  end
end
