# frozen_string_literal: true

module Glfm
  module Constants
    # Root dir containing all specification files
    specification_path = Pathname.new(File.expand_path("../../../glfm_specification", __dir__))

    # GitHub Flavored Markdown specification file
    GHFM_SPEC_TXT_URI = 'https://raw.githubusercontent.com/github/cmark-gfm/master/test/spec.txt'
    GHFM_SPEC_VERSION = '0.29'
    GHFM_SPEC_TXT_FILENAME = "ghfm_spec_v_#{GHFM_SPEC_VERSION}.txt"
    GHFM_SPEC_TXT_PATH = specification_path.join('input/github_flavored_markdown', GHFM_SPEC_TXT_FILENAME)

    # GitLab Flavored Markdown specification files
    specification_input_glfm_path = specification_path.join('input/gitlab_flavored_markdown')
    GLFM_INTRO_TXT_PATH = specification_input_glfm_path.join('glfm_intro.txt')
    GLFM_EXAMPLES_TXT_PATH = specification_input_glfm_path.join('glfm_canonical_examples.txt')
    GLFM_SPEC_TXT_PATH = specification_path.join('output/spec.txt')

    # Other constants used for processing files
    GLFM_SPEC_TXT_HEADER = <<~GLFM_SPEC_TXT_HEADER
      ---
      title: GitLab Flavored Markdown (GLFM) Spec
      version: alpha
      ...
    GLFM_SPEC_TXT_HEADER
    INTRODUCTION_HEADER_LINE_TEXT = /\A# Introduction\Z/.freeze
    END_TESTS_COMMENT_LINE_TEXT = /\A<!-- END TESTS -->\Z/.freeze
  end
end
