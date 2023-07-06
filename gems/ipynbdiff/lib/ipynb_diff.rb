# frozen_string_literal: true

require 'ipynb_diff/transformer'
require 'ipynb_diff/diff'
require 'ipynb_diff/symbol_map'

# Human Readable Jupyter Diffs
module IpynbDiff
  def self.diff(from, to, raise_if_invalid_nb: false, include_frontmatter: false, hide_images: false, diffy_opts: {})
    transformer = Transformer.new(include_frontmatter: include_frontmatter, hide_images: hide_images)

    Diff.new(transformer.transform(from), transformer.transform(to), diffy_opts)
  rescue InvalidNotebookError
    raise if raise_if_invalid_nb
  end

  def self.transform(notebook, raise_errors: false, include_frontmatter: true, hide_images: false)
    return unless notebook

    Transformer.new(include_frontmatter: include_frontmatter, hide_images: hide_images).transform(notebook).as_text
  rescue InvalidNotebookError
    raise if raise_errors
  end
end
