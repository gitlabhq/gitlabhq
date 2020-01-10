# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Page
    class Base
      prepend Support::Page::Logging if Runtime::Env.debug?
      include Capybara::DSL
      include Scenario::Actable
      include Support::WaitForRequests
      extend Validatable
      extend SingleForwardable

      ElementNotFound = Class.new(RuntimeError)

      def_delegators :evaluator, :view, :views

      def assert_no_element(name)
        assert_no_selector(element_selector_css(name))
      end

      def refresh
        page.refresh

        wait_for_requests
      end

      def wait(max: 60, interval: 0.1, reload: true, raise_on_failure: false)
        Support::Waiter.wait_until(max_duration: max, sleep_interval: interval, raise_on_failure: raise_on_failure) do
          yield || (reload && refresh && false)
        end
      end

      def retry_until(max_attempts: 3, reload: false, sleep_interval: 0, raise_on_failure: false)
        Support::Retrier.retry_until(max_attempts: max_attempts, reload_page: (reload && self), sleep_interval: sleep_interval, raise_on_failure: raise_on_failure) do
          yield
        end
      end

      def retry_on_exception(max_attempts: 3, reload: false, sleep_interval: 0.5)
        Support::Retrier.retry_on_exception(max_attempts: max_attempts, reload_page: (reload && self), sleep_interval: sleep_interval) do
          yield
        end
      end

      def scroll_to(selector, text: nil)
        wait_for_requests

        page.execute_script <<~JS
          var elements = Array.from(document.querySelectorAll('#{selector}'));
          var text = '#{text}';

          if (text.length > 0) {
            elements.find(e => e.textContent === text).scrollIntoView();
          } else {
            elements[0].scrollIntoView();
          }
        JS

        page.within(selector) { yield } if block_given?
      end

      # Returns true if successfully GETs the given URL
      # Useful because `page.status_code` is unsupported by our driver, and
      # we don't have access to the `response` to use `have_http_status`.
      def asset_exists?(url)
        page.execute_script <<~JS
          xhr = new XMLHttpRequest();
          xhr.open('GET', '#{url}', true);
          xhr.send();
        JS

        return false unless wait(interval: 0.5, max: 60, reload: false) do
          page.evaluate_script('xhr.readyState == XMLHttpRequest.DONE')
        end

        page.evaluate_script('xhr.status') == 200
      end

      def find_element(name, **kwargs)
        wait_for_requests

        find(element_selector_css(name), kwargs)
      end

      def active_element?(name)
        find_element(name, class: 'active')
      end

      def all_elements(name, **kwargs)
        if kwargs.keys.none? { |key| [:minimum, :maximum, :count, :between].include?(key) }
          raise ArgumentError, "Please use :minimum, :maximum, :count, or :between so that all is more reliable"
        end

        wait_for_requests

        all(element_selector_css(name), **kwargs)
      end

      def check_element(name)
        retry_until(sleep_interval: 1) do
          find_element(name).set(true)

          find_element(name).checked?
        end
      end

      def uncheck_element(name)
        retry_until(sleep_interval: 1) do
          find_element(name).set(false)

          !find_element(name).checked?
        end
      end

      # replace with (..., page = self.class)
      def click_element(name, page = nil, text: nil)
        find_element(name, text: text).click
        page.validate_elements_present! if page
      end

      def fill_element(name, content)
        find_element(name).set(content)
      end

      def select_element(name, value)
        element = find_element(name)

        return if element.text == value

        element.select value
      end

      def has_active_element?(name, **kwargs)
        has_element?(name, class: 'active', **kwargs)
      end

      def has_element?(name, **kwargs)
        wait_for_requests

        wait = kwargs.delete(:wait) || Capybara.default_max_wait_time
        text = kwargs.delete(:text)
        klass = kwargs.delete(:class)

        has_css?(element_selector_css(name, kwargs), text: text, wait: wait, class: klass)
      end

      def has_no_element?(name, **kwargs)
        wait_for_requests

        wait = kwargs.delete(:wait) || Capybara.default_max_wait_time
        text = kwargs.delete(:text)

        has_no_css?(element_selector_css(name, kwargs), wait: wait, text: text)
      end

      def has_text?(text, wait: Capybara.default_max_wait_time)
        wait_for_requests

        page.has_text?(text, wait: wait)
      end

      def has_no_text?(text)
        wait_for_requests

        page.has_no_text? text
      end

      def has_normalized_ws_text?(text, wait: Capybara.default_max_wait_time)
        has_text?(text.gsub(/\s+/, " "), wait: wait)
      end

      def finished_loading?
        wait_for_requests

        # The number of selectors should be able to be reduced after
        # migration to the new spinner is complete.
        # https://gitlab.com/groups/gitlab-org/-/epics/956
        has_no_css?('.gl-spinner, .fa-spinner, .spinner', wait: Capybara.default_max_wait_time)
      end

      def finished_loading_block?
        wait_for_requests

        has_no_css?('.fa-spinner.block-loading', wait: Capybara.default_max_wait_time)
      end

      def has_loaded_all_images?
        # I don't know of a foolproof way to wait for all images to load
        # This loop gives time for the img tags to be rendered and for
        # images to start loading.
        previous_total_images = 0
        wait(interval: 1) do
          current_total_images = all("img").size
          result = previous_total_images == current_total_images
          previous_total_images = current_total_images
          result
        end

        # Retry until all images found can be fetched via HTTP, and
        # check that the image has a non-zero natural width (a broken
        # img tag could have a width, but wouldn't have a natural width)

        # Unfortunately, this doesn't account for SVGs. They're rendered
        # as HTML, so there doesn't seem to be a way to check that they
        # display properly via Selenium. However, if the SVG couldn't be
        # rendered (e.g., because the file doesn't exist), the whole page
        # won't display properly, so we should catch that with the test
        # this method is called from.

        # The user's avatar is an img, which could be a gravatar image,
        # so we skip that by only checking for images hosted internally
        retry_until(sleep_interval: 1) do
          all("img").all? do |image|
            next true unless URI(image['src']).host == URI(page.current_url).host

            asset_exists?(image['src']) && image['naturalWidth'].to_i > 0
          end
        end
      end

      def wait_for_animated_element(name)
        # It would be ideal if we could detect when the animation is complete
        # but in some cases there's nothing we can easily access via capybara
        # so instead we wait for the element, and then we wait a little longer
        raise ElementNotFound, %Q(Couldn't find element named "#{name}") unless has_element?(name)

        sleep 1
      end

      def within_element(name, text: nil)
        page.within(element_selector_css(name), text: text) do
          yield
        end
      end

      def within_element_by_index(name, index)
        page.within all_elements(name, minimum: index + 1)[index] do
          yield
        end
      end

      def scroll_to_element(name, *args)
        scroll_to(element_selector_css(name), *args)
      end

      def element_selector_css(name, *attributes)
        Page::Element.new(name, *attributes).selector_css
      end

      def click_link_with_text(text)
        wait_for_requests

        click_link text
      end

      def click_body
        wait_for_requests

        find('body').click
      end

      def visit_link_in_element(name)
        visit find_element(name)['href']
      end

      def self.path
        raise NotImplementedError
      end

      def self.evaluator
        @evaluator ||= Page::Base::DSL.new
      end

      def self.errors
        if views.empty?
          return ["Page class does not have views / elements defined!"]
        end

        views.flat_map(&:errors)
      end

      def self.elements
        views.flat_map(&:elements)
      end

      def send_keys_to_element(name, keys)
        find_element(name).send_keys(keys)
      end

      class DSL
        attr_reader :views

        def initialize
          @views = []
        end

        def view(path, &block)
          Page::View.evaluate(&block).tap do |view|
            @views.push(Page::View.new(path, view.elements))
          end
        end
      end
    end
  end
end
