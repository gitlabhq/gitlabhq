# frozen_string_literal: true

module Gitlab
  module Regex
    extend self
    extend MergeRequests
    extend Packages

    def project_name_regex
      # The character range \p{Alnum} overlaps with \u{00A9}-\u{1f9ff}
      # hence the Ruby warning.
      # https://gitlab.com/gitlab-org/gitlab/merge_requests/23165#not-easy-fixable
      @project_name_regex ||= /\A[\p{Alnum}\u{00A9}-\u{1f9ff}_][\p{Alnum}\p{Pd}\u{002B}\u{00A9}-\u{1f9ff}_\. ]*\z/
    end

    def project_name_regex_message
      "can contain only letters, digits, emoji, '_', '.', '+', dashes, or spaces. " \
      "It must start with a letter, digit, emoji, or '_'."
    end

    # Project path must conform to this regex. See https://gitlab.com/gitlab-org/gitlab/-/issues/27483
    def oci_repository_path_regex
      @oci_repository_path_regex ||= %r{\A[a-zA-Z0-9]+([._-][a-zA-Z0-9]+)*\z}
    end

    def oci_repository_path_regex_message
      "can only include non-accented letters, digits, '_', '-' and '.'. It must not start with '-', '_', or '.', nor end with '-', '_', '.', '.git', or '.atom'."
    end

    def group_name_regex
      @group_name_regex ||= /\A#{group_name_regex_chars}\z/
    end

    def group_name_regex_chars
      @group_name_regex_chars ||= /[\p{Alnum}\u{00A9}-\u{1f9ff}_][\p{Alnum}\p{Pd}\u{00A9}-\u{1f9ff}_()\. ]*/
    end

    def group_name_regex_message
      "can contain only letters, digits, emoji, '_', '.', dash, space, parenthesis. " \
      "It must start with letter, digit, emoji or '_'."
    end

    ##
    # Docker Distribution Registry repository / tag name rules
    #
    # See https://github.com/docker/distribution/blob/master/reference/regexp.go.
    #
    def container_repository_name_regex(other_accepted_chars = nil)
      strong_memoize_with(:container_repository_name_regex, other_accepted_chars) do
        %r{\A[a-z0-9]+(([._/]|__|-*)[a-z0-9#{other_accepted_chars}])*\z}
      end
    end

    ##
    # We do not use regexp anchors here because these are not allowed when
    # used as a routing constraint.
    #
    def container_registry_tag_regex
      @container_registry_tag_regex ||= /\w[\w.-]{0,127}/
    end

    def environment_name_regex_chars
      'a-zA-Z0-9_/\\$\\{\\}\\. \\-'
    end

    def environment_name_regex_chars_without_slash
      'a-zA-Z0-9_\\$\\{\\}\\. -'
    end

    def environment_name_regex
      @environment_name_regex ||= /\A[#{environment_name_regex_chars_without_slash}]([#{environment_name_regex_chars}]*[#{environment_name_regex_chars_without_slash}])?\z/
    end

    def environment_name_regex_message
      "can contain only letters, digits, '-', '_', '/', '$', '{', '}', '.', and spaces, but it cannot start or end with '/'"
    end

    def environment_scope_regex_chars
      "#{environment_name_regex_chars}\\*"
    end

    def environment_scope_regex
      @environment_scope_regex ||= /\A[#{environment_scope_regex_chars}]+\z/
    end

    def environment_scope_regex_message
      "can contain only letters, digits, '-', '_', '/', '$', '{', '}', '.', '*' and spaces"
    end

    # https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/identity_and_auth.md#agent-identity-and-name
    def cluster_agent_name_regex
      /\A[a-z0-9]([-a-z0-9]*[a-z0-9])?\z/
    end

    def cluster_agent_name_regex_message
      %q(can contain only lowercase letters, digits, and '-', but cannot start or end with '-')
    end

    def kubernetes_namespace_regex
      /\A[a-z0-9]([-a-z0-9]*[a-z0-9])?\z/
    end

    def kubernetes_namespace_regex_message
      "can contain only lowercase letters, digits, and '-'. " \
      "Must start with a letter, and cannot end with '-'"
    end

    # Pod name adheres to DNS Subdomain Names(RFC 1123) naming convention
    # https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-subdomain-names
    def kubernetes_dns_subdomain_regex
      /\A[a-z0-9]([a-z0-9\-\.]*[a-z0-9])?\z/
    end

    def environment_slug_regex
      @environment_slug_regex ||= /\A[a-z]([a-z0-9-]*[a-z0-9])?\z/
    end

    def environment_slug_regex_message
      "can contain only lowercase letters, digits, and '-'. " \
      "Must start with a letter, and cannot end with '-'"
    end

    # The section start, e.g. section_start:12345678:NAME
    def logs_section_prefix_regex
      /section_((?:start)|(?:end)):(\d+):([a-zA-Z0-9_.-]+)/
    end

    # The optional section options, e.g. [collapsed=true]
    def logs_section_options_regex
      /(\[(?:\w+=\w+)(?:, ?(?:\w+=\w+))*\])?/
    end

    # The region end, always: \r\e\[0K
    def logs_section_suffix_regex
      /\r\033\[0K/
    end

    def build_trace_section_regex
      @build_trace_section_regexp ||= %r{
        #{logs_section_prefix_regex}
        #{logs_section_options_regex}
        #{logs_section_suffix_regex}
      }x
    end

    # Code blocks:
    # ```
    # Anything, including `>>>` blocks which are ignored by this filter
    # ```
    MARKDOWN_CODE_BLOCK_REGEX_UNTRUSTED =
      '(?P<code>' \
        '^```.*?\n' \
        '(?:\n|.)*?' \
        '\n```\ *$' \
      ')'

    # HTML block:
    # <tag>
    # Anything, including `>>>` blocks which are ignored by this filter
    # </tag>
    MARKDOWN_HTML_BLOCK_REGEX_UNTRUSTED =
      '(?P<html>' \
        '^<[^>]+?>\ *\n' \
        '(?:\n|.)*?' \
        '\n<\/[^>]+?>\ *$' \
      ')'

    # HTML comment line:
    # <!-- some commented text -->
    MARKDOWN_HTML_COMMENT_LINE_REGEX_UNTRUSTED =
      '(?P<html_comment_line>' \
        '^<!--\ .*?\ -->\ *$' \
      ')'

    MARKDOWN_HTML_COMMENT_BLOCK_REGEX_UNTRUSTED =
      '(?P<html_comment_block>' \
        '^<!--.*?\n' \
        '(?:\n|.)*?' \
        '\n.*?-->\ *$' \
      ')'

    def markdown_code_or_html_blocks_untrusted
      @markdown_code_or_html_blocks_untrusted ||=
        "#{MARKDOWN_CODE_BLOCK_REGEX_UNTRUSTED}" \
        "|" \
        "#{MARKDOWN_HTML_BLOCK_REGEX_UNTRUSTED}"
    end

    def markdown_code_or_html_comments_untrusted
      @markdown_code_or_html_comments_untrusted ||=
        "#{MARKDOWN_CODE_BLOCK_REGEX_UNTRUSTED}" \
        "|" \
        "#{MARKDOWN_HTML_COMMENT_LINE_REGEX_UNTRUSTED}" \
        "|" \
        "#{MARKDOWN_HTML_COMMENT_BLOCK_REGEX_UNTRUSTED}"
    end

    def markdown_code_or_html_blocks_or_html_comments_untrusted
      @markdown_code_or_html_comments_untrusted ||=
        "#{MARKDOWN_CODE_BLOCK_REGEX_UNTRUSTED}" \
        "|" \
        "#{MARKDOWN_HTML_BLOCK_REGEX_UNTRUSTED}" \
        "|" \
        "#{MARKDOWN_HTML_COMMENT_LINE_REGEX_UNTRUSTED}" \
        "|" \
        "#{MARKDOWN_HTML_COMMENT_BLOCK_REGEX_UNTRUSTED}"
    end

    # Based on Jira's project key format
    # https://confluence.atlassian.com/adminjiraserver073/changing-the-project-key-format-861253229.html
    def jira_issue_key_regex(expression_escape: '\b')
      /#{expression_escape}([A-Z][A-Z_0-9]+-\d+)/
    end

    def jira_issue_key_project_key_extraction_regex
      @jira_issue_key_project_key_extraction_regex ||= /-\d+/
    end

    def jira_transition_id_regex
      @jira_transition_id_regex ||= /\d+/
    end

    def breakline_regex
      @breakline_regex ||= /\r\n|\r|\n/
    end

    # https://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html
    def aws_account_id_regex
      /\A\d{12}\z/
    end

    def aws_account_id_message
      'must be a 12-digit number'
    end

    # https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    def aws_arn_regex
      /\Aarn:\S+\z/
    end

    def aws_arn_regex_message
      'must be a valid Amazon Resource Name'
    end

    def utc_date_regex
      @utc_date_regex ||= /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/
    end

    def issue
      @issue ||= /(?<issue>\d+)(?<format>\+s{,1})?(?=\W|\z)/
    end

    def work_item
      @work_item ||= /(?<work_item>\d+)(?<format>\+s{,1})?(?=\W|\z)/
    end

    def base64_regex
      @base64_regex ||= %r{(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?}
    end

    def feature_flag_regex
      /\A[a-z]([-_a-z0-9]*[a-z0-9])?\z/
    end

    # One or more `part`s, separated by separator
    def sep_by_1(separator, part)
      %r{#{part} (#{separator} #{part})*}x
    end

    def x509_subject_key_identifier_regex
      @x509_subject_key_identifier_regex ||= /\A(?:\h{2}:)*\h{2}\z/
    end

    def ml_model_name_regex
      package_name_regex
    end

    def ml_model_version_name_regex
      Regexp.union(semver_regex, /candidate_\d+/)
    end

    def ml_model_file_name_regex
      @ml_model_file_name_regex ||= %r{\A[A-Za-z0-9\.\_\-\+ ]+\z}
    end
  end
end

Gitlab::Regex.prepend_mod
