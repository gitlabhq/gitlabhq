# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Page
    # Page base class
    #
    # @!method self.perform
    #   Perform action on the page
    #   @yieldparam [self] instance of page object
    class Base
      # Generic matcher for common css selectors like:
      # - class name '.someclass'
      # - id '#someid'
      # - selection by attributes 'input[attribute=name][value=value]'
      #
      # @return [Regex]
      CSS_SELECTOR_PATTERN = /^(\.[a-z-]+|\#[a-z-]+)+|([a-z]+\[.*\])$/i

      prepend Support::Page::Logging
      prepend Mobile::Page::Base if QA::Runtime::Env.mobile_layout?

      include Capybara::DSL
      include Scenario::Actable
      include Support::WaitForRequests

      extend Validatable

      ElementNotFound = Class.new(RuntimeError)

      class NoRequiredElementsError < RuntimeError
        def initialize(page_class)
          @page_class = page_class
          super
        end

        def to_s
          format(<<~MSG.strip, page: @page_class)
            %{page} has no required elements.
            See https://docs.gitlab.com/ee/development/testing_guide/end_to_end/dynamic_element_validation.html#required-elements
          MSG
        end
      end

      def initialize
        @retry_later_backoff = QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME
      end

      def inspect
        # For prettier failure messages
        # Eg.: "expected QA::Page::File::Show not to have file "QA Test - File name"
        # Instead of "expected #<QA::Page::File::Show:0x000055c6511e07b8 @retry_later_backoff=60>
        # not to have file "QA Test - File name"
        self.class.to_s
      end

      def assert_no_element(name)
        assert_no_selector(element_selector_css(name))
      end

      def refresh(skip_finished_loading_check: false)
        page.refresh

        wait_for_requests(skip_finished_loading_check: skip_finished_loading_check)
      end

      def wait_until(
        max_duration: 60,
        sleep_interval: 0.1,
        reload: true,
        raise_on_failure: true,
        skip_finished_loading_check_on_refresh: false,
        message: nil
      )
        Support::Waiter.wait_until(
          max_duration: max_duration,
          sleep_interval: sleep_interval,
          raise_on_failure: raise_on_failure,
          message: message
        ) do
          yield || (reload && refresh(skip_finished_loading_check: skip_finished_loading_check_on_refresh) && false)
        end
      end

      def retry_until(max_attempts: 3, reload: false, sleep_interval: 0, raise_on_failure: true, message: nil, &block)
        Support::Retrier.retry_until(
          max_attempts: max_attempts,
          reload_page: (reload && self),
          sleep_interval: sleep_interval,
          raise_on_failure: raise_on_failure,
          message: message,
          &block
        )
      end

      def retry_on_exception(max_attempts: 3, reload: false, sleep_interval: 0.5, message: nil, &block)
        Support::Retrier.retry_on_exception(
          max_attempts: max_attempts,
          reload_page: (reload && self),
          sleep_interval: sleep_interval,
          message: message,
          &block
        )
      end

      def scroll_to(selector, text: nil, &block)
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

        page.within(selector, &block) if block
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
        find(element_selector, **only_capybara_query_keywords(kwargs))
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
        all_args = [:minimum, :maximum, :count, :between]

        if kwargs.keys.none? { |key| all_args.include?(key) }
          raise ArgumentError, "Please use :minimum, :maximum, :count, or :between so that all is more reliable"
        end

        wait_for_requests(skip_finished_loading_check: !!kwargs.delete(:skip_finished_loading_check))

        all(element_selector_css(name), **kwargs)
      end

      def check_element(name, click_by_js = false, **kwargs)
        kwargs[:visible] = false unless kwargs.key?(:visible)
        if find_element(name, **kwargs).checked?
          QA::Runtime::Logger.debug("#{name} is already checked")

          return
        end

        retry_until(sleep_interval: 1) do
          click_checkbox_or_radio(name, click_by_js, **kwargs)
          checked = find_element(name, **kwargs).checked?

          QA::Runtime::Logger.debug(checked ? "#{name} was checked" : "#{name} was not checked")

          checked
        end
      end

      def uncheck_element(name, click_by_js = false, **kwargs)
        kwargs[:visible] = false unless kwargs.key?(:visible)
        unless find_element(name, **kwargs).checked?
          QA::Runtime::Logger.debug("#{name} is already unchecked")

          return
        end

        retry_until(sleep_interval: 1) do
          click_checkbox_or_radio(name, click_by_js, **kwargs)
          unchecked = !find_element(name, **kwargs).checked?

          QA::Runtime::Logger.debug(unchecked ? "#{name} was unchecked" : "#{name} was not unchecked")

          unchecked
        end
      end

      # Method for selecting radios
      def choose_element(name, click_by_js = false, **kwargs)
        kwargs[:visible] = false unless kwargs.key?(:visible)
        if find_element(name, **kwargs).checked?
          QA::Runtime::Logger.debug("#{name} is already selected")

          return
        end

        retry_until(sleep_interval: 1) do
          click_checkbox_or_radio(name, click_by_js, **kwargs)
          selected = find_element(name, **kwargs).checked?

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
      rescue Selenium::WebDriver::Error::StaleElementReferenceError => e
        QA::Runtime::Logger.error("Element #{name} has become stale: #{e}")
      end

      # replace with (..., page = self.class)
      def click_element(name, page = nil, **kwargs)
        skip_finished_loading_check = kwargs.delete(:skip_finished_loading_check)
        wait_for_requests(skip_finished_loading_check: skip_finished_loading_check)

        wait = kwargs.delete(:wait) || Capybara.default_max_wait_time
        text = kwargs.delete(:text)

        begin
          find(element_selector_css(name, kwargs), text: text, wait: wait).click
        rescue Net::ReadTimeout => error
          # In some situations due to perhaps a slow environment we can encounter errors
          # where clicks are registered, but the calls to selenium-webdriver result in
          # timeout errors. In these cases rescue from the error and attempt to continue in
          # the test to avoid a flaky test failure. This should be safe as assertions in the
          # tests will catch any case where the click wasn't actually registered.
          QA::Runtime::Logger.warn "click_element -- #{error} -- #{error.backtrace.inspect}"
          # There may be a 5xx error -- lets refresh the page like the warning page suggests
          # and it if resolves itself we can avoid a flaky failure
          refresh
        end

        page.validate_elements_present! if page
      end

      # Uses capybara to locate and interact with an element instead of using `*_element`.
      # This can be used when it's not possible to add a QA selector but we still want to log the action
      #
      # @param [String] method the capybara method to use
      # @param [String] locator the selector used to find the element
      # @param [Hash] **kwargs optional arguments
      def act_via_capybara(method, locator, **kwargs)
        page.public_send(method, locator, **kwargs)
      end

      def fill_element(name, content)
        find_element(name).set(content)
      end

      # fill in editor element, whether plain text or rich text
      def fill_editor_element(name, content)
        element = find_element name

        if element.tag_name == 'textarea'
          element.set content
        else
          mod = page.driver.browser.capabilities.platform_name.include?("mac") ? :command : :control
          prosemirror = element.find '[contenteditable].ProseMirror'
          prosemirror.send_keys [mod, 'a']
          prosemirror.send_keys :delete
          prosemirror.send_keys content
        end
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
        visible = true if visible.nil?

        try_find_element = ->(wait) do
          if disabled.nil?
            has_css?(element_selector_css(name, kwargs), text: text, wait: wait, class: klass, visible: visible)
          else
            find_element(name, **original_kwargs).disabled? == disabled
          end
        rescue Capybara::ElementNotFound
          false
        end

        # Check to see if we can return early, without the need to wait for all network requests to complete
        # We don't want to add overhead to cases where wait=0 as the caller in these cases is indicating that they
        # don't want any overhead
        return true if wait > 1 && try_find_element.call(1)

        wait_for_requests(skip_finished_loading_check: !!kwargs.delete(:skip_finished_loading_check))
        try_find_element.call(wait)
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
        raise ElementNotFound, %(Couldn't find element named "#{name}") unless has_element?(name)

        sleep 1
      end

      def within_element(name, **kwargs, &block)
        wait_for_requests(skip_finished_loading_check: !!kwargs.delete(:skip_finished_loading_check))
        text = kwargs.delete(:text)

        page.within(element_selector_css(name, kwargs), text: text, &block)
      end

      def within_element_by_index(name, index, &block)
        page.within(all_elements(name, minimum: index + 1)[index], &block)
      end

      def scroll_to_element(name, *kwargs)
        text = kwargs.delete(:text)

        scroll_to(element_selector_css(name, kwargs), text: text)
      end

      def element_selector_css(name, *attributes)
        return name.selector_css if name.is_a? Page::Element
        return name if name.is_a?(String) && name.match?(CSS_SELECTOR_PATTERN)

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
        return unless has_css?('body', text: 'Retry later', wait: 0)

        QA::Runtime::Logger.warn("`Retry later` error occurred. Sleeping for #{@retry_later_backoff} seconds...")
        sleep @retry_later_backoff
        refresh
        @retry_later_backoff += QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME

        wait_if_retry_later
      end

      def current_host
        URI(page.current_url).host
      end

      class << self
        def skip_selectors_check!
          @check_selectors = false
        end

        def check_selectors?
          @check_selectors.nil? ? true : @check_selectors
        end

        def path
          raise NotImplementedError
        end

        def evaluator
          @evaluator ||= Page::Base::DSL.new
        end

        def errors
          return [] unless check_selectors?
          return ["Page class does not have views / elements defined!"] if views.empty?

          views.flat_map(&:errors)
        end

        def elements
          views.flat_map(&:elements)
        end

        def required_elements
          elements.select(&:required?)
        end

        delegate :view, :views, to: :evaluator
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

      def click_by_javascript(element)
        page.execute_script("arguments[0].click();", element)
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

      def click_checkbox_or_radio(name, click_by_js, **kwargs)
        box = find_element(name, **kwargs)
        # Some checkboxes and radio buttons are hidden by their labels and cannot be clicked directly
        click_by_js ? page.execute_script("arguments[0].click();", box) : box.click
      end

      def feature_flag_controlled_element(
        feature_flag,
        element_when_flag_enabled,
        element_when_flag_disabled,
        visibility = true
      )
        # Feature flags can change the UI elements shown, but we need admin access to get feature flag values, which
        # prevents us running the tests on production. Instead we detect the UI element that should be shown when the
        # feature flag is enabled and otherwise use the element that should be displayed when the feature flag is
        # disabled.

        # Check both options once quickly so that the test doesn't wait unnecessarily if the UI has loaded
        # We wait for requests first and wait one second for the element because it can take a moment for a Vue app to
        # load and render the UI
        wait_for_requests

        return element_when_flag_enabled if has_element?(element_when_flag_enabled, wait: 1, visible: visibility)
        return element_when_flag_disabled if has_element?(element_when_flag_disabled, wait: 1, visibile: visibility)

        # Check both options again, this time waiting for the default duration
        return element_when_flag_enabled if has_element?(element_when_flag_enabled, visible: visibility)
        return element_when_flag_disabled if has_element?(element_when_flag_disabled, visible: visibility)

        raise ElementNotFound,
          "Could not find the expected element as #{element_when_flag_enabled} or #{element_when_flag_disabled}." \
          "The relevant feature flag is #{feature_flag}"
      end

      def wait_for_gitlab_to_respond
        wait_until(sleep_interval: 5, message: '502 - GitLab is taking too much time to respond') do
          Capybara.page.has_no_text?(/GitLab is taking too much time to respond|Waiting for GitLab to boot/)
        end
      end
    end
  end
end

QA::Page::Base.prepend_mod_with('Page::Base', namespace: QA)
