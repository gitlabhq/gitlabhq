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

      class NoRequiredElementsError < RuntimeError
        def initialize(page_class)
          @page_class = page_class
          super
        end

        def to_s
          <<~MSG.strip % { page: @page_class }
            %{page} has no required elements.
            See https://docs.gitlab.com/ee/development/testing_guide/end_to_end/dynamic_element_validation.html#required-elements
          MSG
        end
      end

      def_delegators :evaluator, :view, :views

      def initialize
        @retry_later_backoff = QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME
      end

      def inspect
        # For prettier failure messages
        # Eg.: "expected QA::Page::File::Show not to have file "QA Test - File name"
        # Instead of "expected #<QA::Page::File::Show:0x000055c6511e07b8 @retry_later_backoff=60> not to have file "QA Test - File name"
        self.class.to_s
      end

      def assert_no_element(name)
        assert_no_selector(element_selector_css(name))
      end

      def refresh(skip_finished_loading_check: false)
        page.refresh

        wait_for_requests(skip_finished_loading_check: skip_finished_loading_check)
      end

      def wait_until(max_duration: 60, sleep_interval: 0.1, reload: true, raise_on_failure: true, skip_finished_loading_check_on_refresh: false)
        Support::Waiter.wait_until(max_duration: max_duration, sleep_interval: sleep_interval, raise_on_failure: raise_on_failure) do
          yield || (reload && refresh(skip_finished_loading_check: skip_finished_loading_check_on_refresh) && false)
        end
      end

      def retry_until(max_attempts: 3, reload: false, sleep_interval: 0, raise_on_failure: true)
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

        return false unless wait_until(sleep_interval: 0.5, max_duration: 60, reload: false) do
          page.evaluate_script('xhr.readyState == XMLHttpRequest.DONE')
        end

        page.evaluate_script('xhr.status') == 200
      end

      def find_element(name, **kwargs)
        skip_finished_loading_check = kwargs.delete(:skip_finished_loading_check)
        wait_for_requests(skip_finished_loading_check: skip_finished_loading_check)

        element_selector = element_selector_css(name, reject_capybara_query_keywords(kwargs))
        find(element_selector, only_capybara_query_keywords(kwargs))
      end

      def only_capybara_query_keywords(kwargs)
        kwargs.select { |kwarg| Capybara::Queries::SelectorQuery::VALID_KEYS.include?(kwarg) }
      end

      def reject_capybara_query_keywords(kwargs)
        kwargs.reject { |kwarg| Capybara::Queries::SelectorQuery::VALID_KEYS.include?(kwarg) }
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

      def check_element(name, click_by_js = false, visibility = false)
        if find_element(name, visible: visibility).checked?
          QA::Runtime::Logger.debug("#{name} is already checked")

          return
        end

        retry_until(sleep_interval: 1) do
          click_checkbox_or_radio(name, click_by_js, visibility)
          checked = find_element(name, visible: visibility).checked?

          QA::Runtime::Logger.debug(checked ? "#{name} was checked" : "#{name} was not checked")

          checked
        end
      end

      def uncheck_element(name, click_by_js = false, visibility = false)
        unless find_element(name, visible: visibility).checked?
          QA::Runtime::Logger.debug("#{name} is already unchecked")

          return
        end

        retry_until(sleep_interval: 1) do
          click_checkbox_or_radio(name, click_by_js, visibility)
          unchecked = !find_element(name, visible: visibility).checked?

          QA::Runtime::Logger.debug(unchecked ? "#{name} was unchecked" : "#{name} was not unchecked")

          unchecked
        end
      end

      # Method for selecting radios
      def choose_element(name, click_by_js = false, visibility = false)
        if find_element(name, visible: visibility).checked?
          QA::Runtime::Logger.debug("#{name} is already selected")

          return
        end

        retry_until(sleep_interval: 1) do
          click_checkbox_or_radio(name, click_by_js, visibility)
          selected = find_element(name, visible: visibility).checked?

          QA::Runtime::Logger.debug(selected ? "#{name} was selected" : "#{name} was not selected")

          selected
        end
        wait_for_requests
      end

      # Use this to simulate moving the pointer to an element's coordinate
      # and sending a click event.
      # This is a helpful workaround when there is a transparent element overlapping
      # the target element and so, normal `click_element` on target would raise
      # Selenium::WebDriver::Error::ElementClickInterceptedError
      def click_element_coordinates(name, **kwargs)
        page.driver.browser.action.move_to(find_element(name, **kwargs).native).click.perform
      end

      # replace with (..., page = self.class)
      def click_element(name, page = nil, **kwargs)
        skip_finished_loading_check = kwargs.delete(:skip_finished_loading_check)
        wait_for_requests(skip_finished_loading_check: skip_finished_loading_check)

        wait = kwargs.delete(:wait) || Capybara.default_max_wait_time
        text = kwargs.delete(:text)

        find(element_selector_css(name, kwargs), text: text, wait: wait).click
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
        disabled = kwargs.delete(:disabled)
        original_kwargs = kwargs.dup
        wait = kwargs.delete(:wait) || Capybara.default_max_wait_time
        text = kwargs.delete(:text)
        klass = kwargs.delete(:class)
        visible = kwargs.delete(:visible)
        visible = visible.nil? && true

        try_find_element = ->(wait) do
          if disabled.nil?
            has_css?(element_selector_css(name, kwargs), text: text, wait: wait, class: klass, visible: visible)
          else
            find_element(name, original_kwargs).disabled? == disabled
          end
        end

        # Check for the element before waiting for requests, just in case unrelated requests are in progress.
        # This is to avoid waiting unnecessarily after the element we're interested in has already appeared.
        return true if try_find_element.call(wait)

        # If the element didn't appear, wait for requests and then check again
        wait_for_requests(skip_finished_loading_check: !!kwargs.delete(:skip_finished_loading_check))

        # We only wait one second now because we previously waited the full expected duration,
        # plus however long it took for requests to complete. One second should be enough
        # for the UI to update after requests complete.
        try_find_element.call(1)
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

      def has_no_text?(text, wait: Capybara.default_max_wait_time)
        wait_for_requests

        page.has_no_text?(text, wait: wait)
      end

      def has_normalized_ws_text?(text, wait: Capybara.default_max_wait_time)
        has_text?(text.gsub(/\s+/, " "), wait: wait)
      end

      def finished_loading_block?
        wait_for_requests

        has_no_css?('.gl-spinner', wait: Capybara.default_max_wait_time)
      end

      def has_loaded_all_images?
        # I don't know of a foolproof way to wait for all images to load
        # This loop gives time for the img tags to be rendered and for
        # images to start loading.
        previous_total_images = 0
        wait_until(sleep_interval: 1) do
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

      def within_element(name, **kwargs)
        wait_for_requests
        text = kwargs.delete(:text)

        page.within(element_selector_css(name, kwargs), text: text) do
          yield
        end
      end

      def within_element_by_index(name, index)
        page.within all_elements(name, minimum: index + 1)[index] do
          yield
        end
      end

      def scroll_to_element(name, *kwargs)
        text = kwargs.delete(:text)

        scroll_to(element_selector_css(name, kwargs), text: text)
      end

      def element_selector_css(name, *attributes)
        return name.selector_css if name.is_a? Page::Element

        Page::Element.new(name, *attributes).selector_css
      end

      def click_link_with_text(text)
        wait_for_requests

        click_link text
      end

      def visit_link_in_element(name)
        visit find_element(name)['href']
      end

      def wait_if_retry_later
        return if @retry_later_backoff > QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME * 5

        if has_css?('body', text: 'Retry later', wait: 0)
          QA::Runtime::Logger.warn("`Retry later` error occurred. Sleeping for #{@retry_later_backoff} seconds...")
          sleep @retry_later_backoff
          refresh
          @retry_later_backoff += QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME

          wait_if_retry_later
        end
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

      def self.required_elements
        elements.select(&:required?)
      end

      def send_keys_to_element(name, keys)
        find_element(name).send_keys(keys)
      end

      def visible?
        raise NoRequiredElementsError, self.class if self.class.required_elements.empty?

        self.class.required_elements.each do |required_element|
          return false if has_no_element? required_element
        end

        true
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

      private

      def click_checkbox_or_radio(name, click_by_js, visibility)
        box = find_element(name, visible: visibility)
        # Some checkboxes and radio buttons are hidden by their labels and cannot be clicked directly
        click_by_js ? page.execute_script("arguments[0].click();", box) : box.click
      end
    end
  end
end
