# frozen_string_literal: true

module QA
  module Support
    module Page
      module Logging
        def refresh
          log("refreshing #{current_url}")

          super
        end

        def wait(max: 60, time: 0.1, reload: true)
          log("with wait: max #{max}; time #{time}; reload #{reload}")
          now = Time.now

          element = super

          log("ended wait after #{Time.now - now} seconds")

          element
        end

        def scroll_to(selector, text: nil)
          msg = "scrolling to :#{selector}"
          msg += " with text: #{text}" if text
          log(msg)

          super
        end

        def asset_exists?(url)
          exists = super

          log("asset_exists? #{url} returned #{exists}")

          exists
        end

        def find_element(name)
          log("finding :#{name}")

          element = super

          log("found :#{name}") if element

          element
        end

        def all_elements(name)
          log("finding all :#{name}")

          elements = super

          log("found #{elements.size} :#{name}") if elements

          elements
        end

        def click_element(name)
          log("clicking :#{name}")

          super
        end

        def fill_element(name, content)
          masked_content = name.to_s.include?('password') ? '*****' : content

          log(%Q(filling :#{name} with "#{masked_content}"))

          super
        end

        def has_element?(name)
          found = super

          log("has_element? :#{name} returned #{found}")

          found
        end

        def within_element(name)
          log("within element :#{name}")

          element = super

          log("end within element :#{name}")

          element
        end

        private

        def log(msg)
          QA::Runtime::Logger.debug(msg)
        end
      end
    end
  end
end
