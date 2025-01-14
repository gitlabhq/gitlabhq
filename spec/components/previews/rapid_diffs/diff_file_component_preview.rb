# frozen_string_literal: true

module RapidDiffs
  class DiffFileComponentPreview < ViewComponent::Preview
    layout 'lookbook/rapid_diffs'

    # @!group Code

    def added_and_removed_lines
      hunk = "
        --- a/app/views/layouts/preview/rapid_diffs.html.haml	(revision eaba934a0bc6eed56cfd1f082e9fa3f5409f2938)
        +++ b/app/views/layouts/preview/rapid_diffs.html.haml	(date 1718119822001)
        @@ -1,7 +1,6 @@
        -= universal_stylesheet_link_tag 'application'
        -= universal_stylesheet_link_tag 'application_utilities'
         = universal_stylesheet_link_tag 'preview/rapid_diffs'
         = webpack_bundle_tag 'javascripts/entrypoints/preview/rapid_diffs'
        += webpack_bundle_tag 'javascripts/entrypoints/preview'

        -%div{ style: 'padding: 20px' }
        +%div{ style: 'padding: 20px', class: 'container-fluid' }
           = yield
      "
      render(::RapidDiffs::DiffFileComponent.new(diff_file: diff_file_from_hunk(hunk)))
    end

    def added_lines
      hunk = "
        --- a/app/views/layouts/preview/rapid_diffs.html.haml	(revision eaba934a0bc6eed56cfd1f082e9fa3f5409f2938)
        +++ b/app/views/layouts/preview/rapid_diffs.html.haml	(date 1718118441569)
        @@ -2,6 +2,7 @@
         = universal_stylesheet_link_tag 'application_utilities'
         = universal_stylesheet_link_tag 'preview/rapid_diffs'
         = webpack_bundle_tag 'javascripts/entrypoints/preview/rapid_diffs'
        += webpack_bundle_tag 'javascripts/entrypoints/preview/rapid_diffs'

         %div{ style: 'padding: 20px' }
           = yield
      "
      render(::RapidDiffs::DiffFileComponent.new(diff_file: diff_file_from_hunk(hunk)))
    end

    def removed_lines
      hunk = "
        --- a/app/views/layouts/preview/rapid_diffs.html.haml	(revision eaba934a0bc6eed56cfd1f082e9fa3f5409f2938)
        +++ b/app/views/layouts/preview/rapid_diffs.html.haml	(date 1718119765262)
        @@ -1,7 +1,6 @@
         = universal_stylesheet_link_tag 'application'
         = universal_stylesheet_link_tag 'application_utilities'
         = universal_stylesheet_link_tag 'preview/rapid_diffs'
        -= webpack_bundle_tag 'javascripts/entrypoints/preview/rapid_diffs'

         %div{ style: 'padding: 20px' }
           = yield
      "
      render(::RapidDiffs::DiffFileComponent.new(diff_file: diff_file_from_hunk(hunk)))
    end

    def added_file
      hunk = "
        --- /dev/null
        +++ b/app/views/layouts/preview/rapid_diffs.html.haml	(date 1718119765262)
        @@ -0,0 +1,7 @@
        += universal_stylesheet_link_tag 'application'
        += universal_stylesheet_link_tag 'application_utilities'
        += universal_stylesheet_link_tag 'preview/rapid_diffs'
        += webpack_bundle_tag 'javascripts/entrypoints/preview/rapid_diffs'
        +
        +%div{ style: 'padding: 20px' }
        +  = yield
      "
      render(::RapidDiffs::DiffFileComponent.new(diff_file: diff_file_from_hunk(hunk)))
    end

    def removed_file
      hunk = "
        --- a/app/views/layouts/preview/rapid_diffs.html.haml	(revision eaba934a0bc6eed56cfd1f082e9fa3f5409f2938)
        +++ /dev/null
        @@ -1,7 +1,0 @@
        -= universal_stylesheet_link_tag 'application'
        -= universal_stylesheet_link_tag 'application_utilities'
        -= universal_stylesheet_link_tag 'preview/rapid_diffs'
        -= webpack_bundle_tag 'javascripts/entrypoints/preview/rapid_diffs'
        -
        -%div{ style: 'padding: 20px' }
        -  = yield
      "
      render(::RapidDiffs::DiffFileComponent.new(diff_file: diff_file_from_hunk(hunk)))
    end

    # @!endgroup

    # @!group NoPreview

    def moved_text_file
      hunk = "
        --- a/old_text_file
        +++ b/new_text_file
         Line 1
      "
      diff = raw_diff(diff_content(hunk), new_file: false, renamed_file: true, a_mode: '100644')
      render(::RapidDiffs::DiffFileComponent.new(diff_file: diff_file(diff)))
    end

    def deleted_ignored_file
      hunk = "
        --- a/deleted_ignored_file
        +++ /dev/null
        Line 1
      "
      diff = raw_diff(diff_content(hunk), new_file: false, deleted_file: true, a_mode: '100644', b_mode: '0')
      file = diff_file(diff)
      file.define_singleton_method(:diffable?) { false }
      render(::RapidDiffs::DiffFileComponent.new(diff_file: file))
    end

    def added_unsupported_file
      hunk = "
        --- /dev/null
        +++ b/new_binary_file
        Binary files /dev/null and b/new_binary_file differ
      "
      file = diff_file_from_hunk(hunk)
      file.define_singleton_method(:diffable?) { true }
      file.define_singleton_method(:text_diff?) { false }
      file.define_singleton_method(:text?) { false }
      render(::RapidDiffs::DiffFileComponent.new(diff_file: file))
    end

    def mode_changed_text_file
      hunk = "
        --- a/text_file
        +++ b/text_file
        old mode 100644
        new mode 100755
      "
      diff = raw_diff(diff_content(hunk), new_file: false, a_mode: '100644', b_mode: '100755')
      file = diff_file(diff)
      render(::RapidDiffs::DiffFileComponent.new(diff_file: file))
    end

    def added_big_file
      hunk = "
        --- a/text_file
        +++ b/text_file
      "
      file = diff_file_from_hunk(hunk)
      file.define_singleton_method(:too_large?) { true }
      render(::RapidDiffs::DiffFileComponent.new(diff_file: file))
    end

    def changed_file_with_big_diff
      hunk = "
        --- a/text_file
        +++ b/text_file
      "
      diff = raw_diff(diff_content(hunk), new_file: false, a_mode: '100644')
      file = diff_file(diff)
      file.define_singleton_method(:collapsed?) { true }
      file.define_singleton_method(:content_changed?) { true }
      render(::RapidDiffs::DiffFileComponent.new(diff_file: file))
    end

    # @!endgroup

    private

    def diff_file(diff)
      diff_refs = ::Gitlab::Diff::DiffRefs.new(base_sha: 'a', head_sha: 'b')
      ::Gitlab::Diff::File.new(diff, repository: FakeRepository.new, diff_refs: diff_refs).tap do |file|
        file.instance_variable_set(:@new_blob, Blob.decorate(raw_blob(diff_content(diff.diff))))
        file.instance_variable_set(:@old_blob, Blob.decorate(raw_blob(diff_content(diff.diff))))
      end
    end

    def diff_file_from_hunk(hunk)
      diff = raw_diff(diff_content(hunk))
      diff_file(diff)
    end

    def diff_content(hunk)
      hunk.split("\n").filter_map(&:lstrip).reject(&:empty?).join("\n")
    end

    def raw_diff(hunk, **attrs)
      ::Gitlab::Git::Diff.new(
        {
          diff: hunk,
          new_path: new_path(hunk),
          old_path: old_path(hunk),
          a_mode: '0',
          b_mode: '100644',
          new_file: true,
          renamed_file: false,
          deleted_file: false,
          too_large: false,
          **attrs
        })
    end

    def raw_blob(hunk)
      ::Gitlab::Git::Blob.new(
        id: 'bba46076dd3e6a406b45ad98ef3b8194fde8b568',
        commit_id: 'master',
        size: 264,
        name: new_path(hunk),
        path: new_path(hunk),
        data: "",
        mode: '100644'
      )
    end

    def old_path(hunk)
      hunk[%r{--- a/([^\s\n]*)}, 1]
    end

    def new_path(hunk)
      hunk[%r{\+\+\+ b/([^\s\n]*)}, 1]
    end

    class FakeRepository
      def initialize
        @project = FactoryBot.build_stubbed(:project)
      end

      def attributes(_)
        {}
      end

      attr_reader :project
    end
  end
end
