# frozen_string_literal: true

require "factory_bot"

module RapidDiffs
  class DiffFileComponentPreview < ViewComponent::Preview
    layout 'lookbook/rapid_diffs'

    # @!group Code

    def added_and_removed_lines
      diff = "
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
      render(RapidDiffs::DiffFileComponent.new(diff_file: diff_file(diff)))
    end

    def added_lines
      diff = "
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
      render(RapidDiffs::DiffFileComponent.new(diff_file: diff_file(diff)))
    end

    def removed_lines
      diff = "
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
      render(RapidDiffs::DiffFileComponent.new(diff_file: diff_file(diff)))
    end

    def added_file
      diff = "
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
      render(RapidDiffs::DiffFileComponent.new(diff_file: diff_file(diff)))
    end

    def removed_file
      diff = "
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
      render(RapidDiffs::DiffFileComponent.new(diff_file: diff_file(diff)))
    end

    # @!endgroup

    private

    def diff_content(diff)
      diff.split("\n").filter_map(&:lstrip).reject(&:empty?).join("\n")
    end

    def diff_file(diff)
      ::Gitlab::Diff::File.new(raw_diff(diff_content(diff)), repository: FakeRepository.new).tap do |file|
        file.instance_variable_set(:@new_blob, Blob.decorate(raw_blob(diff_content(diff))))
      end
    end

    def raw_diff(diff)
      Gitlab::Git::Diff.new(
        {
          diff: diff,
          new_path: new_path(diff),
          old_path: old_path(diff),
          a_mode: '0',
          b_mode: '100644',
          new_file: true,
          renamed_file: false,
          deleted_file: false,
          too_large: false
        })
    end

    def raw_blob(diff)
      Gitlab::Git::Blob.new(
        id: 'bba46076dd3e6a406b45ad98ef3b8194fde8b568',
        commit_id: 'master',
        size: 264,
        name: new_path(diff),
        path: new_path(diff),
        data: "",
        mode: '100644'
      )
    end

    def old_path(diff)
      diff[%r{--- a/([^\s\n]*)}, 1]
    end

    def new_path(diff)
      diff[%r{\+\+\+ b/([^\s\n]*)}, 1]
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
