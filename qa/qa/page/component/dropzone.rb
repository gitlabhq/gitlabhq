# frozen_string_literal: true

module QA
  module Page
    module Component
      class Dropzone
        attr_reader :page, :container

        # page      - A QA::Page::Base object
        # container - CSS selector of the comment textarea's container
        def initialize(page, container)
          @page = page
          @container = container
        end

        # Not tested and not expected to work with multiple dropzones
        # instantiated on one page because there is no distinguishing
        # attribute per dropzone file field.
        def attach_file(attachment)
          if QA::Page::Base.perform { |d| d.has_element?('content-editor', wait: 0.5) } # Rich text editor
            filename = attachment.match(%r{([^/]+$)})[1]
            page.find('[data-testid="file-upload-field"]', visible: 'false').set attachment

            # Wait for link to be appended to dropzone text
            page.wait_until(reload: false) do
              page.find("#{container} img")['alt'].match?(filename)
            end
          else # Plain text editor
            filename = ::File.basename(attachment)

            field_style = { visibility: 'visible', height: '', width: '' }
            page.attach_file(attachment, class: 'dz-hidden-input', make_visible: field_style)

            # Wait for link to be appended to dropzone text
            page.wait_until(reload: false) do
              page.find("#{container} textarea").value.match(filename)
            end
          end
        end
      end
    end
  end
end
