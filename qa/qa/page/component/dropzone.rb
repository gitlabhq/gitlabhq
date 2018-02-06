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
          filename = File.basename(attachment)

          field_style = { visibility: 'visible', height: '', width: '' }
          page.attach_file(attachment, class: 'dz-hidden-input', make_visible: field_style)

          # Wait for link to be appended to dropzone text
          page.wait(reload: false) do
            page.find("#{container} textarea").value.match(filename)
          end
        end
      end
    end
  end
end
