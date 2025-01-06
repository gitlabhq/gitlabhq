# frozen_string_literal: true

module Gitlab
  module Regex
    module Packages
      include ::Gitlab::Utils::StrongMemoize

      CONAN_RECIPE_FILES = %w[conanfile.py conanmanifest.txt conan_sources.tgz conan_export.tgz].freeze
      CONAN_PACKAGE_FILES = %w[conaninfo.txt conanmanifest.txt conan_package.tgz].freeze

      PYPI_NORMALIZED_NAME_REGEX_STRING = '[-_.]+'

      # see https://github.com/apache/maven/blob/c1dfb947b509e195c75d4275a113598cf3063c3e/maven-artifact/src/main/java/org/apache/maven/artifact/Artifact.java#L46
      MAVEN_SNAPSHOT_DYNAMIC_PARTS = /\A.{0,1000}(-\d{8}\.\d{6}-\d+).{0,1000}\z/

      API_PATH_REGEX = %r{^/api/v\d+/(projects/[^/]+/|groups?/[^/]+/-/)?packages/[A-Za-z]+}

      def conan_package_reference_regex
        @conan_package_reference_regex ||= %r{\A[A-Za-z0-9]+\z}
      end

      def conan_revision_regex
        @conan_revision_regex ||= %r{\A0\z}
      end

      def conan_revision_regex_v2
        # The revision can be one of two types:
        # - "hash" (default): the checksum hash of the recipe manifest: MD5 Hash 32 Characters
        # - "scm" or "scm_folder": the commit ID for the repository system (Git or SVN): SHA-1 Hash 40 Characters
        # according to https://docs.conan.io/2.10/reference/conanfile/attributes.html#revision-mode
        @conan_revision_regex_v2 ||= %r/\A(?:\h{32}|\h{40})\z/
      end

      def conan_recipe_user_channel_regex
        %r{\A(_|#{conan_name_regex})\z}
      end

      def conan_recipe_component_regex
        # https://docs.conan.io/en/latest/reference/conanfile/attributes.html#name
        @conan_recipe_component_regex ||= %r{\A#{conan_name_regex}\z}
      end

      def composer_package_version_regex
        # see https://github.com/composer/semver/blob/31f3ea725711245195f62e54ffa402d8ef2fdba9/src/VersionParser.php#L215
        @composer_package_version_regex ||= %r{\Av?((\d++)(\.(?:\d++|[xX*]))?(\.(?:\d++|[xX*]))?(\.(?:\d++|[xX*]))?)?\z}
      end

      def composer_dev_version_regex
        @composer_dev_version_regex ||= %r{(^dev-)|(-dev$)}
      end

      def package_name_regex(other_accepted_chars_package_name = nil)
        strong_memoize_with(:package_name_regex, other_accepted_chars_package_name) do
          %r{
              \A\@?
              (?> # atomic group to prevent backtracking
                (([\w\-\.\+]*)\/)*([\w\-\.]+)
              )
              @?
              (?> # atomic group to prevent backtracking
                (([\w\-\.\+]*)\/)*([\w\-\.#{other_accepted_chars_package_name}]*)
              )
              \z
            }x
        end
      end

      def maven_file_name_regex
        @maven_file_name_regex ||= %r{\A[A-Za-z0-9\.\_\-\+]+\z}
      end

      def maven_path_regex
        @maven_path_regex ||= %r{\A\@?(([\w\-\.]*)/)*([\w\-\.\+]*)\z}
      end

      def maven_app_name_regex
        @maven_app_name_regex ||= /\A[\w\-\.]+\z/
      end

      def maven_version_regex
        @maven_version_regex ||= /\A(?!.*\.\.)[\w+.-]+\z/
      end

      def maven_app_group_regex
        maven_app_name_regex
      end

      def npm_package_name_regex(other_accepted_chars = nil)
        strong_memoize_with(:npm_package_name_regex, other_accepted_chars) do
          %r{\A(?:@(#{Gitlab::PathRegex::NAMESPACE_FORMAT_REGEX})/)?[-+\.\_a-zA-Z0-9#{other_accepted_chars}]+\z}
        end
      end

      def npm_package_name_regex_message
        'should be a valid NPM package name: https://github.com/npm/validate-npm-package-name#naming-rules.'
      end

      def nuget_package_name_regex
        @nuget_package_name_regex ||= %r{\A[-+\.\_a-zA-Z0-9]+\z}
      end

      def nuget_version_regex
        @nuget_version_regex ||= /
          \A#{_semver_major_regex}
          \.#{_semver_minor_regex}
          (\.#{_semver_patch_regex})?
          (\.\d*)?
          #{_semver_prerelease_build_regex}\z
        /x
      end

      def terraform_module_package_name_regex
        @terraform_module_package_name_regex ||= %r{\A[-a-z0-9]+\/[-a-z0-9]+\z}
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
            )\z}xi
      end

      def debian_package_name_regex
        # See official parser
        # https://git.dpkg.org/cgit/dpkg/dpkg.git/tree/lib/dpkg/parsehelp.c?id=9e0c88ec09475f4d1addde9cdba1ad7849720356#n122
        # @debian_package_name_regex ||= %r{\A[a-z0-9][-+\._a-z0-9]*\z}i.freeze
        # But we prefer a more strict version from Lintian
        # https://salsa.debian.org/lintian/lintian/-/blob/5080c0068ffc4a9ddee92022a91d0c2ff53e56d1/lib/Lintian/Util.pm#L116
        @debian_package_name_regex ||= %r{\A[a-z0-9][-+\.a-z0-9]+\z}
      end

      def debian_version_regex
        # See official parser: https://git.dpkg.org/cgit/dpkg/dpkg.git/tree/lib/dpkg/parsehelp.c?id=9e0c88ec09475f4d1addde9cdba1ad7849720356#n205
        @debian_version_regex ||= %r{
          \A(?:
            (?:([0-9]{1,9}):)?            (?# epoch)
            ([0-9][0-9a-z\.+~]*)          (?# version)
            (-[0-9a-z\.+~]+){0,14}        (?# -revision)
            (?<!-)
            )\z}xi
      end

      def debian_architecture_regex
        # See official parser: https://git.dpkg.org/cgit/dpkg/dpkg.git/tree/lib/dpkg/arch.c?id=9e0c88ec09475f4d1addde9cdba1ad7849720356#n43
        # But we limit to lower case
        @debian_architecture_regex ||= %r{\A#{::Packages::Debian::ARCHITECTURE_REGEX}\z}o
      end

      def debian_distribution_regex
        @debian_distribution_regex ||= %r{\A#{::Packages::Debian::DISTRIBUTION_REGEX}\z}io
      end

      def debian_component_regex
        @debian_component_regex ||= %r{\A#{::Packages::Debian::COMPONENT_REGEX}\z}o
      end

      def debian_direct_upload_filename_regex
        @debian_direct_upload_filename_regex ||= %r{\A.*\.(deb|udeb|ddeb)\z}o
      end

      def helm_channel_regex
        @helm_channel_regex ||= %r{\A([a-zA-Z0-9](\.|-|_)?){1,255}(?<!\.|-|_)\z}
      end

      def helm_package_regex
        @helm_package_regex ||= %r{#{helm_channel_regex}}
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
        /x
      end

      def semver_regex
        @semver_regex ||= Regexp.new("\\A#{::Gitlab::Regex.unbounded_semver_regex.source}\\z", ::Gitlab::Regex.unbounded_semver_regex.options).freeze
      end

      def semver_regex_message
        'should follow SemVer: https://semver.org'
      end

      # These partial semver regexes are intended for use in composing other
      # regexes rather than being used alone.
      def _semver_major_minor_patch_regex
        @_semver_major_minor_patch_regex ||= /
          #{_semver_major_regex}\.#{_semver_minor_regex}\.#{_semver_patch_regex}
        /x
      end

      def _semver_major_regex
        @_semver_major_regex ||= /
          (?<major>0|[1-9]\d*)
        /x
      end

      def _semver_minor_regex
        @_semver_minor_regex ||= /
          (?<minor>0|[1-9]\d*)
        /x
      end

      def _semver_patch_regex
        @_semver_patch_regex ||= /
          (?<patch>0|[1-9]\d*)
        /x
      end

      def _semver_prerelease_build_regex
        @_semver_prerelease_build_regex ||= /
          (?:-(?<prerelease>(?:\d*[a-zA-Z-][0-9a-zA-Z-]*|[1-9]\d*|0)(?:\.(?:\d*[a-zA-Z-][0-9a-zA-Z-]*|[1-9]\d*|0))*))?
          (?:\+(?<build>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?
        /x
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
          (?<=^|\s|\() (?# beginning of line, whitespace character, or opening parenthesis)
          (?<domain>
            [0-9a-z](?:(?:-|[0-9a-z]){0,61}[0-9a-z]) (?# first domain)
            (?:\.[0-9a-z](?:(?:-|[0-9a-z]){0,61}[0-9a-z])?){0,49} (?# inner domains)
            \.[a-z]{2,63}(?=/|\s|$|\)) (?# top-level domain, ends with /, whitespace, or end of line)
          )
          (?<path>
            /(?:
              [-/$_.+!*'(),0-9a-z] (?# plain URL character)
              |
              %[0-9a-f]{2} (?# URL encoded character)
            ){0,1000}
          )? (?# optional path)
          (?=$|\s|\)) (?# followed by end of line, whitespace, or closing parenthesis)
        }ix
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
        @sha256_regex ||= /\A[0-9a-f]{64}\z/i
      end

      def slack_link_regex
        @slack_link_regex ||= Gitlab::UntrustedRegexp.new('<([^|<>]*[|][^|<>]*)>')
      end

      private

      def conan_name_regex
        @conan_name_regex ||= %r{[a-zA-Z0-9_][a-zA-Z0-9_\+\.-]{1,49}}
      end
    end
  end
end
