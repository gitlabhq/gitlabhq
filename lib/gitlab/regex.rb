# frozen_string_literal: true

module Gitlab
  module Regex
    module Packages
      CONAN_RECIPE_FILES = %w[conanfile.py conanmanifest.txt conan_sources.tgz conan_export.tgz].freeze
      CONAN_PACKAGE_FILES = %w[conaninfo.txt conanmanifest.txt conan_package.tgz].freeze

      PYPI_NORMALIZED_NAME_REGEX_STRING = '[-_.]+'

      # see https://github.com/apache/maven/blob/c1dfb947b509e195c75d4275a113598cf3063c3e/maven-artifact/src/main/java/org/apache/maven/artifact/Artifact.java#L46
      MAVEN_SNAPSHOT_DYNAMIC_PARTS = /\A.{0,1000}(-\d{8}\.\d{6}-\d+).{0,1000}\z/.freeze

      API_PATH_REGEX = %r{^/api/v\d+/(projects/[^/]+/|groups?/[^/]+/-/)?packages/[A-Za-z]+}.freeze

      def conan_package_reference_regex
        @conan_package_reference_regex ||= %r{\A[A-Za-z0-9]+\z}.freeze
      end

      def conan_revision_regex
        @conan_revision_regex ||= %r{\A0\z}.freeze
      end

      def conan_recipe_user_channel_regex
        %r{\A(_|#{conan_name_regex})\z}.freeze
      end

      def conan_recipe_component_regex
        # https://docs.conan.io/en/latest/reference/conanfile/attributes.html#name
        @conan_recipe_component_regex ||= %r{\A#{conan_name_regex}\z}.freeze
      end

      def composer_package_version_regex
        # see https://github.com/composer/semver/blob/31f3ea725711245195f62e54ffa402d8ef2fdba9/src/VersionParser.php#L215
        @composer_package_version_regex ||= %r{\Av?((\d++)(\.(?:\d++|[xX*]))?(\.(?:\d++|[xX*]))?(\.(?:\d++|[xX*]))?)?\z}.freeze
      end

      def composer_dev_version_regex
        @composer_dev_version_regex ||= %r{(^dev-)|(-dev$)}.freeze
      end

      def package_name_regex
        @package_name_regex ||=
          %r{
              \A\@?
              (?> # atomic group to prevent backtracking
                (([\w\-\.\+]*)\/)*([\w\-\.]+)
              )
              @?
              (?> # atomic group to prevent backtracking
                (([\w\-\.\+]*)\/)*([\w\-\.]*)
              )
              \z
            }x.freeze
      end

      def maven_file_name_regex
        @maven_file_name_regex ||= %r{\A[A-Za-z0-9\.\_\-\+]+\z}.freeze
      end

      def maven_path_regex
        @maven_path_regex ||= %r{\A\@?(([\w\-\.]*)/)*([\w\-\.\+]*)\z}.freeze
      end

      def maven_app_name_regex
        @maven_app_name_regex ||= /\A[\w\-\.]+\z/.freeze
      end

      def maven_version_regex
        @maven_version_regex ||= /\A(?!.*\.\.)[\w+.-]+\z/.freeze
      end

      def maven_app_group_regex
        maven_app_name_regex
      end

      def npm_package_name_regex
        @npm_package_name_regex ||= %r{\A(?:@(#{Gitlab::PathRegex::NAMESPACE_FORMAT_REGEX})/)?[-+\.\_a-zA-Z0-9]+\z}o
      end

      def nuget_package_name_regex
        @nuget_package_name_regex ||= %r{\A[-+\.\_a-zA-Z0-9]+\z}.freeze
      end

      def nuget_version_regex
        @nuget_version_regex ||= /
          \A#{_semver_major_regex}
          \.#{_semver_minor_regex}
          (\.#{_semver_patch_regex})?
          (\.\d*)?
          #{_semver_prerelease_build_regex}\z
        /x.freeze
      end

      def terraform_module_package_name_regex
        @terraform_module_package_name_regex ||= %r{\A[-a-z0-9]+\/[-a-z0-9]+\z}.freeze
      end

      def pypi_version_regex
        # See the official regex: https://github.com/pypa/packaging/blob/16.7/packaging/version.py#L159

        @pypi_version_regex ||= %r{
          \A(?:
            v?
            (?:([0-9]+)!)?                                                 (?# epoch)
            ([0-9]+(?:\.[0-9]+)*)                                          (?# release segment)
            ([-_\.]?((a|b|c|rc|alpha|beta|pre|preview))[-_\.]?([0-9]+)?)?  (?# pre-release)
            ((?:-([0-9]+))|(?:[-_\.]?(post|rev|r)[-_\.]?([0-9]+)?))?       (?# post release)
            ([-_\.]?(dev)[-_\.]?([0-9]+)?)?                                (?# dev release)
            (?:\+([a-z0-9]+(?:[-_\.][a-z0-9]+)*))?                         (?# local version)
            )\z}xi.freeze
      end

      def debian_package_name_regex
        # See official parser
        # https://git.dpkg.org/cgit/dpkg/dpkg.git/tree/lib/dpkg/parsehelp.c?id=9e0c88ec09475f4d1addde9cdba1ad7849720356#n122
        # @debian_package_name_regex ||= %r{\A[a-z0-9][-+\._a-z0-9]*\z}i.freeze
        # But we prefer a more strict version from Lintian
        # https://salsa.debian.org/lintian/lintian/-/blob/5080c0068ffc4a9ddee92022a91d0c2ff53e56d1/lib/Lintian/Util.pm#L116
        @debian_package_name_regex ||= %r{\A[a-z0-9][-+\.a-z0-9]+\z}.freeze
      end

      def debian_version_regex
        # See official parser: https://git.dpkg.org/cgit/dpkg/dpkg.git/tree/lib/dpkg/parsehelp.c?id=9e0c88ec09475f4d1addde9cdba1ad7849720356#n205
        @debian_version_regex ||= %r{
          \A(?:
            (?:([0-9]{1,9}):)?            (?# epoch)
            ([0-9][0-9a-z\.+~]*)          (?# version)
            (-[0-9a-z\.+~]+){0,14}        (?# -revision)
            (?<!-)
            )\z}xi.freeze
      end

      def debian_architecture_regex
        # See official parser: https://git.dpkg.org/cgit/dpkg/dpkg.git/tree/lib/dpkg/arch.c?id=9e0c88ec09475f4d1addde9cdba1ad7849720356#n43
        # But we limit to lower case
        @debian_architecture_regex ||= %r{\A#{::Packages::Debian::ARCHITECTURE_REGEX}\z}o.freeze
      end

      def debian_distribution_regex
        @debian_distribution_regex ||= %r{\A#{::Packages::Debian::DISTRIBUTION_REGEX}\z}io.freeze
      end

      def debian_component_regex
        @debian_component_regex ||= %r{\A#{::Packages::Debian::COMPONENT_REGEX}\z}o.freeze
      end

      def debian_direct_upload_filename_regex
        @debian_direct_upload_filename_regex ||= %r{\A.*\.(deb|udeb|ddeb)\z}o.freeze
      end

      def helm_channel_regex
        @helm_channel_regex ||= %r{\A([a-zA-Z0-9](\.|-|_)?){1,255}(?<!\.|-|_)\z}.freeze
      end

      def helm_package_regex
        @helm_package_regex ||= %r{#{helm_channel_regex}}.freeze
      end

      def helm_version_regex
        # identical to semver_regex, with optional preceding 'v'
        @helm_version_regex ||= Regexp.new("\\Av?#{::Gitlab::Regex.unbounded_semver_regex.source}\\z", ::Gitlab::Regex.unbounded_semver_regex.options)
      end

      def unbounded_semver_regex
        # See the official regex: https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string

        # The order of the alternatives in <prerelease> are intentionally
        # reordered to be greedy. Without this change, the unbounded regex would
        # only partially match "v0.0.0-20201230123456-abcdefabcdef".
        @unbounded_semver_regex ||= /
          #{_semver_major_minor_patch_regex}#{_semver_prerelease_build_regex}
        /x.freeze
      end

      def semver_regex
        @semver_regex ||= Regexp.new("\\A#{::Gitlab::Regex.unbounded_semver_regex.source}\\z", ::Gitlab::Regex.unbounded_semver_regex.options).freeze
      end

      # These partial semver regexes are intended for use in composing other
      # regexes rather than being used alone.
      def _semver_major_minor_patch_regex
        @_semver_major_minor_patch_regex ||= /
          #{_semver_major_regex}\.#{_semver_minor_regex}\.#{_semver_patch_regex}
        /x.freeze
      end

      def _semver_major_regex
        @_semver_major_regex ||= /
          (?<major>0|[1-9]\d*)
        /x.freeze
      end

      def _semver_minor_regex
        @_semver_minor_regex ||= /
          (?<minor>0|[1-9]\d*)
        /x.freeze
      end

      def _semver_patch_regex
        @_semver_patch_regex ||= /
          (?<patch>0|[1-9]\d*)
        /x.freeze
      end

      def _semver_prerelease_build_regex
        @_semver_prerelease_build_regex ||= /
          (?:-(?<prerelease>(?:\d*[a-zA-Z-][0-9a-zA-Z-]*|[1-9]\d*|0)(?:\.(?:\d*[a-zA-Z-][0-9a-zA-Z-]*|[1-9]\d*|0))*))?
          (?:\+(?<build>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?
        /x.freeze
      end

      def prefixed_semver_regex
        # identical to semver_regex, except starting with 'v'
        @prefixed_semver_regex ||= Regexp.new("\\Av#{::Gitlab::Regex.unbounded_semver_regex.source}\\z", ::Gitlab::Regex.unbounded_semver_regex.options)
      end

      def go_package_regex
        # A Go package name looks like a URL but is not; it:
        #   - Must not have a scheme, such as http:// or https://
        #   - Must not have a port number, such as :8080 or :8443

        @go_package_regex ||= %r{
          \b (?# word boundary)
          (?<domain>
            [0-9a-z](?:(?:-|[0-9a-z]){0,61}[0-9a-z])? (?# first domain)
            (?:\.[0-9a-z](?:(?:-|[0-9a-z]){0,61}[0-9a-z])?)* (?# inner domains)
            \.[a-z]{2,} (?# top-level domain)
          )
          (?<path>/(?:
            [-/$_.+!*'(),0-9a-z] (?# plain URL character)
            | %[0-9a-f]{2})* (?# URL encoded character)
          )? (?# path)
          \b (?# word boundary)
        }ix.freeze
      end

      def generic_package_version_regex
        maven_version_regex
      end

      def generic_package_name_regex
        maven_file_name_regex
      end

      def generic_package_file_name_regex
        generic_package_name_regex
      end

      def sha256_regex
        @sha256_regex ||= /\A[0-9a-f]{64}\z/i.freeze
      end

      private

      def conan_name_regex
        @conan_name_regex ||= %r{[a-zA-Z0-9_][a-zA-Z0-9_\+\.-]{1,49}}.freeze
      end
    end

    module BulkImports
      def bulk_import_destination_namespace_path_regex
        # This regexp validates the string conforms to rules for a destination_namespace path:
        # i.e does not start with a non-alphanumeric character,
        # contains only alphanumeric characters, forward slashes, periods, and underscores,
        # does not end with a period or forward slash, and has a relative path structure
        # with no http protocol chars or leading or trailing forward slashes
        # eg 'source/full/path' or 'destination_namespace' not 'https://example.com/destination/namespace/path'
        # the regex also allows for an empty string ('') to be accepted as this is allowed in
        # a bulk_import POST request
        @bulk_import_destination_namespace_path_regex ||= %r/((\A\z)|(\A[0-9a-z]*(-_.)?[0-9a-z])(\/?[0-9a-z]*[-_.]?[0-9a-z])+\z)/i
      end

      def bulk_import_source_full_path_regex
        # This regexp validates the string conforms to rules for a source_full_path path:
        # i.e does not start with a non-alphanumeric character except for periods or underscores,
        # contains only alphanumeric characters, forward slashes, periods, and underscores,
        # does not end with a period or forward slash, and has a relative path structure
        # with no http protocol chars or leading or trailing forward slashes
        # eg 'source/full/path' or 'destination_namespace' not 'https://example.com/source/full/path'
        @bulk_import_source_full_path_regex ||= %r/\A([.]?)[^\W](\/?([-_.+]*)*[0-9a-z][-_]*)+\z/i
      end

      def bulk_import_source_full_path_regex_message
        bulk_import_destination_namespace_path_regex_message
      end

      def bulk_import_destination_namespace_path_regex_message
        "must have a relative path structure " \
        "with no HTTP protocol characters, or leading or trailing forward slashes. " \
        "Path segments must not start or end with a special character, " \
        "and must not contain consecutive special characters."
      end
    end

    extend self
    extend Packages
    extend BulkImports

    def group_path_regex
      # This regexp validates the string conforms to rules for a group slug:
      # i.e does not start with a non-alphanumeric character except for periods or underscores,
      # contains only alphanumeric characters, periods, and underscores,
      # does not end with a period or forward slash, and has no leading or trailing forward slashes
      # eg 'destination-path' or 'destination_pth' not 'example/com/destination/full/path'
      @group_path_regex ||= %r/\A[.]?[^\W]([.]?[0-9a-z][-_]*)+\z/i
    end

    def group_path_regex_message
      "cannot start with a non-alphanumeric character except for periods or underscores, " \
      "can contain only alphanumeric characters, periods, and underscores, " \
      "cannot end with a period or forward slash, and has no leading or trailing forward slashes." \
    end

    def project_name_regex
      # The character range \p{Alnum} overlaps with \u{00A9}-\u{1f9ff}
      # hence the Ruby warning.
      # https://gitlab.com/gitlab-org/gitlab/merge_requests/23165#not-easy-fixable
      @project_name_regex ||= /\A[\p{Alnum}\u{00A9}-\u{1f9ff}_][\p{Alnum}\p{Pd}\u{002B}\u{00A9}-\u{1f9ff}_\. ]*\z/.freeze
    end

    def project_name_regex_message
      "can contain only letters, digits, emojis, '_', '.', '+', dashes, or spaces. " \
      "It must start with a letter, digit, emoji, or '_'."
    end

    # Project path must conform to this regex. See https://gitlab.com/gitlab-org/gitlab/-/issues/27483
    def oci_repository_path_regex
      @oci_repository_path_regex ||= %r{\A[a-zA-Z0-9]+([._-][a-zA-Z0-9]+)*\z}.freeze
    end

    def oci_repository_path_regex_message
      'must not start or end with a special character and must not contain consecutive special characters.'
    end

    def group_name_regex
      @group_name_regex ||= /\A#{group_name_regex_chars}\z/.freeze
    end

    def group_name_regex_chars
      @group_name_regex_chars ||= /[\p{Alnum}\u{00A9}-\u{1f9ff}_][\p{Alnum}\p{Pd}\u{00A9}-\u{1f9ff}_()\. ]*/.freeze
    end

    def group_name_regex_message
      "can contain only letters, digits, emojis, '_', '.', dash, space, parenthesis. " \
      "It must start with letter, digit, emoji or '_'."
    end

    ##
    # Docker Distribution Registry repository / tag name rules
    #
    # See https://github.com/docker/distribution/blob/master/reference/regexp.go.
    #
    def container_repository_name_regex
      @container_repository_regex ||= %r{\A[a-z0-9]+(([._/]|__|-*)[a-z0-9])*\z}
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
      @environment_name_regex ||= /\A[#{environment_name_regex_chars_without_slash}]([#{environment_name_regex_chars}]*[#{environment_name_regex_chars_without_slash}])?\z/.freeze
    end

    def environment_name_regex_message
      "can contain only letters, digits, '-', '_', '/', '$', '{', '}', '.', and spaces, but it cannot start or end with '/'"
    end

    def environment_scope_regex_chars
      "#{environment_name_regex_chars}\\*"
    end

    def environment_scope_regex
      @environment_scope_regex ||= /\A[#{environment_scope_regex_chars}]+\z/.freeze
    end

    def environment_scope_regex_message
      "can contain only letters, digits, '-', '_', '/', '$', '{', '}', '.', '*' and spaces"
    end

    # https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/identity_and_auth.md#agent-identity-and-name
    def cluster_agent_name_regex
      /\A[a-z0-9]([-a-z0-9]*[a-z0-9])?\z/
    end

    def cluster_agent_name_regex_message
      %q{can contain only lowercase letters, digits, and '-', but cannot start or end with '-'}
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
      @environment_slug_regex ||= /\A[a-z]([a-z0-9-]*[a-z0-9])?\z/.freeze
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
      }x.freeze
    end

    MARKDOWN_CODE_BLOCK_REGEX = %r{
      (?<code>
        # Code blocks:
        # ```
        # Anything, including `>>>` blocks which are ignored by this filter
        # ```

        ^```
        .+?
        \n```\ *$
      )
    }mx.freeze

    # Code blocks:
    # ```
    # Anything, including `>>>` blocks which are ignored by this filter
    # ```
    MARKDOWN_CODE_BLOCK_REGEX_UNTRUSTED =
      '(?P<code>' \
        '^```.*?\n' \
        '(?:\n|.)*?' \
        '\n```\ *$' \
      ')'.freeze

    MARKDOWN_HTML_BLOCK_REGEX = %r{
      (?<html>
        # HTML block:
        # <tag>
        # Anything, including `>>>` blocks which are ignored by this filter
        # </tag>

        ^<[^>]+?>\ *\n
        .+?
        \n<\/[^>]+?>\ *$
      )
    }mx.freeze

    # HTML block:
    # <tag>
    # Anything, including `>>>` blocks which are ignored by this filter
    # </tag>
    MARKDOWN_HTML_BLOCK_REGEX_UNTRUSTED =
      '(?P<html>' \
        '^<[^>]+?>\ *\n' \
        '(?:\n|.)*?' \
        '\n<\/[^>]+?>\ *$' \
      ')'.freeze

    # HTML comment line:
    # <!-- some commented text -->
    MARKDOWN_HTML_COMMENT_LINE_REGEX_UNTRUSTED =
      '(?P<html_comment_line>' \
        '^<!--\ .*?\ -->\ *$' \
      ')'.freeze

    MARKDOWN_HTML_COMMENT_BLOCK_REGEX_UNTRUSTED =
      '(?P<html_comment_block>' \
        '^<!--.*?\n' \
        '(?:\n|.)*?' \
        '\n.*?-->\ *$' \
      ')'.freeze

    def markdown_code_or_html_blocks
      @markdown_code_or_html_blocks ||= %r{
          #{MARKDOWN_CODE_BLOCK_REGEX}
        |
          #{MARKDOWN_HTML_BLOCK_REGEX}
      }mx.freeze
    end

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
    # Avoids linking CVE IDs (https://cve.mitre.org/cve/identifiers/syntaxchange.html#new) as Jira issues.
    # CVE IDs use the format of CVE-YYYY-NNNNNNN
    def jira_issue_key_regex
      @jira_issue_key_regex ||= /(?!CVE-\d+-\d+)[A-Z][A-Z_0-9]+-\d+/
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
      @utc_date_regex ||= /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/.freeze
    end

    def merge_request_draft
      /\A(?i)(\[draft\]|\(draft\)|draft:)/
    end

    def issue
      @issue ||= /(?<issue>\d+)(?<format>\+s{,1})?(?=\W|\z)/
    end

    def work_item
      @work_item ||= /(?<work_item>\d+)(?<format>\+s{,1})?(?=\W|\z)/
    end

    def merge_request
      @merge_request ||= /(?<merge_request>\d+)(?<format>\+s{,1})?/
    end

    def base64_regex
      @base64_regex ||= %r{(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?}.freeze
    end

    def feature_flag_regex
      /\A[a-z]([-_a-z0-9]*[a-z0-9])?\z/
    end

    def feature_flag_regex_message
      "can contain only lowercase letters, digits, '_' and '-'. " \
      "Must start with a letter, and cannot end with '-' or '_'"
    end

    # One or more `part`s, separated by separator
    def sep_by_1(separator, part)
      %r(#{part} (#{separator} #{part})*)x
    end

    def x509_subject_key_identifier_regex
      @x509_subject_key_identifier_regex ||= /\A(?:\h{2}:)*\h{2}\z/.freeze
    end
  end
end

Gitlab::Regex.prepend_mod
