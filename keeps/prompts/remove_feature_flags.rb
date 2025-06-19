# frozen_string_literal: true

module Keeps
  module Prompts
    class RemoveFeatureFlags
      attr_reader :logger

      def initialize(logger)
        @logger = logger
      end

      def fetch(feature_flag, file, flag_enabled)
        if file.end_with?('_spec.rb')
          prompt_rspec(feature_flag, file, flag_enabled)
        elsif file.end_with?('.rb')
          prompt_ruby(feature_flag, file, flag_enabled)
        elsif file.end_with?('.haml')
          prompt_haml(feature_flag, file, flag_enabled)
        elsif file.end_with?('.md')
          prompt_markdown(feature_flag, file) unless skip_markdown_file?(file)
        elsif file.end_with?('_spec.js')
          prompt_js_spec(feature_flag, file, flag_enabled)
        elsif file.end_with?('.js')
          prompt_js(feature_flag, file, flag_enabled)
        elsif file.end_with?('.vue')
          prompt_vue(feature_flag, file, flag_enabled)
        else
          logger.puts("Unexpected file extension in #{file} referencing feature flag #{feature_flag.name}. Skipping.")
        end
      end

      private

      def milestones_helper
        @milestones_helper ||= ::Keeps::Helpers::Milestones.new
      end

      def prompt_shared(feature_flag, file, flag_enabled)
        if flag_enabled
          <<~MARKDOWN
          Your job is to remove old feature flags from code. The feature flag has already been enabled and any references to it should be removed and any dead code paths that are only used when the feature flag is disabled should also be removed.
          The feature flag is called `#{feature_flag.name}`.
          The code below is in a file named `#{file}` and the code may contain references to the feature flag. It's possible this code does not contain explicit reference the feature flag. In that case make no changes.
          Once you are done with the changes make sure to run rubocop as well and reformat the code also remove any dead code and unreachable code that you see after the refactoring.
          MARKDOWN
        else
          <<~MARKDOWN
          Your job is to remove old feature flags from code. The feature flag has been disabled and any references to it should be removed and any dead code paths that are only used when the feature flag is enabled should also be removed.
          The feature flag is called `#{feature_flag.name}`.
          The code below is in a file named `#{file}` and the code may contain references to the feature flag. It's possible this code does not contain explicit reference the feature flag. In that case make no changes.
          Once you are done with the changes make sure to run rubocop as well and reformat the code also remove any dead code and unreachable code that you see after the refactoring.
          MARKDOWN
        end
      end

      def prompt_ruby(feature_flag, file, flag_enabled)
        <<~MARKDOWN
        #{prompt_shared(feature_flag, file, flag_enabled)}

        Feature flags are checked using `Feature.enabled?(:#{feature_flag.name})` and stubbed in tests using `stub_feature_flag(#{feature_flag.name}: false)`. If you see code that does not use the feature flag you should return the code unchanged exactly as it was.

        #{ruby_feature_flag_instructions(feature_flag, flag_enabled)}
        MARKDOWN
      end

      def prompt_haml_flag_enabled_disabled_mode(flag_enabled)
        if flag_enabled
          <<~MARKDOWN
            ### Flag Enabled Mode (#{flag_enabled ? 'This is the current mode' : 'Not the current mode'}):
            If the flag is being kept but enabled permanently:

            1. Remove the entire feature flag condition
            2. Keep only the code that was executed when the flag was enabled
            3. Remove any code that was only executed when the flag was disabled
            4. **Important**: If you remove code that renders partials (e.g., `= render 'path/to/partial'`), note that these referenced partials may no longer be needed
          MARKDOWN
        else
          <<~MARKDOWN
            ### Flag Disabled Mode (#{!flag_enabled ? 'This is the current mode' : 'Not the current mode'}):
            If the flag is being completely removed:

            1. Remove the entire feature flag condition
            2. Keep only the code that was executed when the flag was disabled
            3. Remove any code that was only executed when the flag was enabled
            4. **Important**: If you remove code that renders partials (e.g., `= render 'path/to/partial'`), note that these referenced partials may no longer be needed
          MARKDOWN
        end
      end

      def prompt_haml(feature_flag, file, flag_enabled)
        <<~MARKDOWN
          #{prompt_shared(feature_flag, file, flag_enabled)}

          ## HAML Template Feature Flag Removal Guidelines:

          In HAML templates, feature flags are typically checked using Ruby expressions like:
          ```ruby
          - if Feature.enabled?(:#{feature_flag.name}, project)
            # Enabled code here
          - else
            # Disabled code here
          ```

          #{prompt_haml_flag_enabled_disabled_mode(flag_enabled)}

          ### Example Transformations:

          #{flag_enabled ? prompt_haml_flag_enabled_examples(feature_flag) : prompt_haml_flag_disabled_examples(feature_flag)}

          ### Additional Guidelines:

          1. For each rendered partial that is removed (`= render 'path/to/partial'`), add a note: "The partial 'path/to/partial' may no longer be needed and should be considered for removal."

          2. Only suggest removing partials that are rendered directly in the removed code. Don't attempt to analyze deeper dependencies.

          3. Look for these common patterns for rendering partials:
            - `= render 'path/to/partial'`
            - `= render partial: 'path/to/partial'`
            - `= render 'path/to/partial', locals: { ... }`
            - `= render layout: 'path/to/layout'`

          4. Be careful with partial paths that use variables or dynamic components:
            - `= render partial_path`
            - `= render locals[:partial_name]`
            - Don't suggest removing these as the path is not clear from static analysis

          5. If no changes are needed to the file, return it unchanged.

          #{ruby_feature_flag_instructions(feature_flag, flag_enabled)}
        MARKDOWN
      end

      def prompt_haml_flag_enabled_examples(feature_flag)
        <<~MARKDOWN
          #### Example 1: Basic conditional rendering
          ```haml
          - if Feature.enabled?(:#{feature_flag.name})
            .new-feature
              = render 'components/new_feature'
          - else
            .old-feature
              = render 'components/old_feature'
          ```

          Transform to:
          ```haml
          .new-feature
            = render 'components/new_feature'
          ```
          And note: "The partial 'components/old_feature' may no longer be needed."

          #### Example 2: Conditional with nested partials
          ```haml
          .container
            - if Feature.enabled?(:#{feature_flag.name}, project)
              #js-new-component{ data: component_data(project, user) }
            - else
              .legacy-component
                = render 'projects/component/legacy_header', project: @project
                = render 'shared/legacy_content'
          ```

          Transform to:
          ```haml
          .container
            #js-new-component{ data: component_data(project, user) }
          ```
          And note: "The partials 'projects/component/legacy_header' and 'shared/legacy_content' may no longer be needed."

          #### Example 3: Flag used in a method call
          ```haml
          = render_component(project, feature_enabled: Feature.enabled?(:#{feature_flag.name}))
          ```

          Transform to:
          ```haml
          = render_component(project, feature_enabled: true)
          ```
        MARKDOWN
      end

      def prompt_haml_flag_disabled_examples(feature_flag)
        <<~MARKDOWN
          #### Example 1: Basic conditional rendering
          ```haml
          - if Feature.enabled?(:#{feature_flag.name})
            .new-feature
              = render 'components/new_feature'
          - else
            .old-feature
              = render 'components/old_feature'
          ```

          Transform to:
          ```haml
          .old-feature
            = render 'components/old_feature'
          ```
          And note: "The partial 'components/new_feature' may no longer be needed."

          #### Example 2: Conditional with nested partials
          ```haml
          .container
            - if Feature.enabled?(:#{feature_flag.name}, project)
              #js-new-component{ data: component_data(project, user) }
            - else
              .legacy-component
                = render 'projects/component/legacy_header', project: @project
                = render 'shared/legacy_content'
          ```

          Transform to:
          ```haml
          .container
            .legacy-component
              = render 'projects/component/legacy_header', project: @project
              = render 'shared/legacy_content'
          ```
          And note: "The JS component '#js-new-component' and its associated logic may no longer be needed."

          #### Example 3: Flag used in a method call
          ```haml
          = render_component(project, feature_enabled: Feature.enabled?(:#{feature_flag.name}))
          ```

          Transform to:
          ```haml
          = render_component(project, feature_enabled: false)
          ```
        MARKDOWN
      end

      def prompt_markdown_flag_enabled_disabled_mode(flag_enabled)
        if flag_enabled
          <<~MARKDOWN
            ### Flag Enabled Mode (#{flag_enabled ? 'This is the current mode' : 'Not the current mode'}):
            If the flag is being kept but enabled permanently:
            - Remove all conditional logic tied to the feature flag
            - Keep components and code that were shown when the flag was enabled
            - Remove components and code that were only shown when the flag was disabled
          MARKDOWN
        else
          <<~MARKDOWN
            ### Flag Disabled Mode (#{!flag_enabled ? 'This is the current mode' : 'Not the current mode'}):
            If the flag is being completely removed:
            - Remove all conditional logic tied to the feature flag
            - Keep components and code that were shown when the flag was disabled
            - Remove components and code that were only shown when the flag was enabled
          MARKDOWN
        end
      end

      def prompt_vue(feature_flag, file, flag_enabled)
        camel_case_flag = feature_flag.name.camelize(:lower)

        <<~MARKDOWN
          #{prompt_shared(feature_flag, file, flag_enabled)}

          ## Vue.js Feature Flag Removal Guidelines:

          The feature flag is accessed in Vue components through `this.glFeatures.#{camel_case_flag}` after adding the feature flag mixin `glFeatureFlagMixin()`.

          #{prompt_markdown_flag_enabled_disabled_mode(flag_enabled)}

          ### Common Vue.js Patterns to Handle:

          #{flag_enabled ? prompt_vue_flag_enabled_examples(camel_case_flag) : prompt_vue_flag_disabled_examples(camel_case_flag)}

          ### CRITICAL: Feature Flag Mixin Cleanup Instructions

          **Step 1**: After removing all references to `glFeatures.#{camel_case_flag}`, search the ENTIRE file for any remaining uses of `this.glFeatures.` or `glFeatures.`

          **Step 2**: Count the remaining feature flag references:
          - If you find ANY other `this.glFeatures.` or `glFeatures.` references → KEEP the mixin completely unchanged
          - If you find ZERO other `this.glFeatures.` or `glFeatures.` references → Remove the mixin

          **Step 3**: If removing the mixin (only when NO other feature flags exist):
          - Remove the mixin import statement (e.g., `import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';`)
          - Remove the mixin registration (e.g., `mixins: [glFeatureFlagMixin()]` or from a mixins array)

          **IMPORTANT WARNINGS**:
          - NEVER change the syntax of remaining feature flags from `this.glFeatures.otherFlag` to anything else
          - NEVER replace `this.glFeatures.` with `$options.features.` or any other syntax
          - NEVER modify feature flags other than `#{camel_case_flag}`
          - If in doubt, keep the mixin - it's safer to leave it than to break other feature flags

          If there are no changes needed to the file, return it unchanged.
        MARKDOWN
      end

      def prompt_vue_flag_enabled_examples(camel_case_flag)
        <<~MARKDOWN
          1. Conditional rendering with v-if/v-else:
            ```vue
            <!-- Before -->
            <component-a v-if="glFeatures.#{camel_case_flag}" />
            <component-b v-else />

            <!-- After -->
            <component-a />
            ```

          2. Negated conditional rendering:
            ```vue
            <!-- Before -->
            <component-a v-if="!glFeatures.#{camel_case_flag}" />

            <!-- After -->
            <!-- Component completely removed -->
            ```

          3. Conditional classes with object syntax:
            ```vue
            <!-- Before -->
            <div :class="{ 'special-class': glFeatures.#{camel_case_flag} }">

            <!-- After -->
            <div class="special-class">
            ```

          4. Negated conditional classes:
            ```vue
            <!-- Before -->
            <div :class="{ 'special-class': !glFeatures.#{camel_case_flag} }">

            <!-- After -->
            <div>
            ```

          5. Ternary expressions in props or bindings:
            ```vue
            <!-- Before -->
            <component :prop="glFeatures.#{camel_case_flag} ? 'new-value' : 'old-value'" />

            <!-- After -->
            <component :prop="'new-value'" />
            ```
        MARKDOWN
      end

      def prompt_vue_flag_disabled_examples(camel_case_flag)
        <<~MARKDOWN
          1. Conditional rendering with v-if/v-else:
            ```vue
            <!-- Before -->
            <component-a v-if="glFeatures.#{camel_case_flag}" />
            <component-b v-else />

            <!-- After -->
            <component-b />
            ```

          2. Negated conditional rendering:
            ```vue
            <!-- Before -->
            <component-a v-if="!glFeatures.#{camel_case_flag}" />

            <!-- After -->
            <component-a />
            ```

          3. Conditional classes with object syntax:
            ```vue
            <!-- Before -->
            <div :class="{ 'special-class': glFeatures.#{camel_case_flag} }">

            <!-- After -->
            <div>
            ```

          4. Negated conditional classes:
            ```vue
            <!-- Before -->
            <div :class="{ 'special-class': !glFeatures.#{camel_case_flag} }">

            <!-- After -->
            <div class="special-class">
            ```

          5. Ternary expressions in props or bindings:
            ```vue
            <!-- Before -->
            <component :prop="glFeatures.#{camel_case_flag} ? 'new-value' : 'old-value'" />

            <!-- After -->
            <component :prop="'old-value'" />
            ```
        MARKDOWN
      end

      def prompt_js_flag_enabled_disabled_mode(flag_enabled)
        if flag_enabled
          <<~MARKDOWN
            ### Flag Enabled Mode (#{flag_enabled ? 'This is the current mode' : 'Not the current mode'}):
            If the flag is being kept but enabled permanently:
            - Remove all conditional checks for the feature flag
            - Keep the code that was previously gated by the feature flag
            - Remove any code paths that only ran when the flag was disabled
          MARKDOWN
        else
          <<~MARKDOWN
            ### Flag Disabled Mode (#{!flag_enabled ? 'This is the current mode' : 'Not the current mode'}):
            If the flag is being completely removed:
            - Remove all conditional checks for the feature flag
            - Keep the code that was previously run when the flag was disabled
            - Remove any code paths that only ran when the flag was enabled
          MARKDOWN
        end
      end

      def prompt_js(feature_flag, file, flag_enabled)
        camel_case_flag = feature_flag.name.camelize(:lower)

        <<~MARKDOWN
          #{prompt_shared(feature_flag, file, flag_enabled)}

          ## JavaScript Feature Flag Removal Guidelines:

          The feature flag is accessed in JavaScript through the global object `gon?.features?.#{camel_case_flag}`.

          #{prompt_js_flag_enabled_disabled_mode(flag_enabled)}

          ### Example Transformations:

          #{flag_enabled ? prompt_js_flag_enabled_examples(camel_case_flag) : prompt_js_flag_disabled_examples(camel_case_flag)}

          ### Special Cases:
          1. If the feature flag is destructured from gon.features:
            ```javascript
            const { #{camel_case_flag} } = gon.features ?? {};
            ```
            Remove this line completely if it's not needed elsewhere.

          2. If the feature flag is used in a ternary operator:
            ```javascript
            const description = gon?.features?.#{camel_case_flag} ? __('New text') : __('Old text');
            ```
            Replace with just the appropriate string based on flag status.

          3. If the feature flag is used in an object property initialization:
            ```javascript
            {
              property: gon?.features?.#{camel_case_flag} ? newValue : oldValue,
            }
            ```
            Replace with the appropriate value.

          Make sure to verify the resulting code maintains correct syntax and behavior.
          If there are no changes needed to the file, return it unchanged.
        MARKDOWN
      end

      def prompt_js_flag_enabled_examples(camel_case_flag)
        <<~MARKDOWN
          ```javascript
          // Before
          if (gon?.features?.#{camel_case_flag}) {
            renderFeature(elements);
          } else {
            renderLegacy(elements);
          }

          // After
          renderFeature(elements);
          ```
        MARKDOWN
      end

      def prompt_js_flag_disabled_examples(camel_case_flag)
        <<~MARKDOWN
          ```javascript
          // Before
          if (gon?.features?.#{camel_case_flag}) {
            renderFeature(elements);
          } else {
            renderLegacy(elements);
          }

          // After
          renderLegacy(elements);
          ```
        MARKDOWN
      end

      def prompt_js_spec_flag_enabled_disabled_mode(flag_enabled)
        if flag_enabled
          <<~MARKDOWN
            ### Flag Enabled Mode (#{flag_enabled ? 'This is the current mode' : 'Not the current mode'}):
            If the feature flag is being kept but enabled permanently:

            1. Remove test cases that specifically test the disabled state of the feature
            2. Keep test cases that test the enabled state of the feature
            3. For tests that set up both states:
              - Remove conditional flag setup
              - Keep only the test logic for the enabled state
              - Update test descriptions to remove mentions of the feature flag
          MARKDOWN
        else
          <<~MARKDOWN
            ### Flag Disabled Mode (#{!flag_enabled ? 'This is the current mode' : 'Not the current mode'}):
            If the feature flag is being completely removed:

            1. Remove test cases that specifically test the enabled state of the feature
            2. Keep test cases that test the disabled state of the feature
            3. For tests that set up both states:
              - Remove conditional flag setup
              - Keep only the test logic for the disabled state
              - Update test descriptions to remove mentions of the feature flag
          MARKDOWN
        end
      end

      def prompt_js_spec(feature_flag, file, flag_enabled)
        camel_case_flag = feature_flag.name.camelize(:lower)

        <<~MARKDOWN
          #{prompt_shared(feature_flag, file, flag_enabled)}

          ## Jest Test Files Feature Flag Removal Guidelines:

          In Jest test files (for both JavaScript and Vue.js), feature flags are typically mocked in one of these ways:

          1. In individual tests:
            ```javascript
            it('shows feature when flag is enabled', () => {
              wrapper = createComponent({
                provide: { glFeatures: { #{camel_case_flag}: true } }
              });
              // Test assertions...
            });
            ```

          2. In beforeEach blocks:
            ```javascript
            beforeEach(() => {
              provide = {
                glFeatures: {
                  #{camel_case_flag}: true,
                },
              };
            });
            ```

          3. Using mocks:
            ```javascript
            jest.mock('~/feature_flags/feature_flags', () => ({
              __esModule: true,
              default: { #{camel_case_flag}: true },
            }));
            ```

          #{prompt_js_spec_flag_enabled_disabled_mode(flag_enabled)}

          ### Examples of Common Transformations:

          #{flag_enabled ? prompt_js_spec_flag_enabled_examples(camel_case_flag) : prompt_js_spec_flag_disabled_examples(camel_case_flag)}

          ### Additional Guidelines:

          1. Update test descriptions to remove references to the feature flag
          2. Remove any test cases that are only testing feature flag detection behavior
          3. If a test file exclusively tests feature flag behavior that's being removed, consider if the entire file should be deleted
          4. Check for jest.mock() calls at the top of the file that may need to be updated
          5. Look for factory functions that incorporate feature flags in their options

          If there are no changes needed to the file, return it unchanged.
        MARKDOWN
      end

      def prompt_js_spec_flag_enabled_examples(camel_case_flag)
        <<~MARKDOWN
          #### Example 1: Remove specific feature-gated tests
          ```javascript
          // Before
          it('shows component when feature flag is enabled', () => {
            wrapper = createComponent({ provide: { glFeatures: { #{camel_case_flag}: true } } });
            expect(wrapper.find('.new-feature').exists()).toBe(true);
          });

          it('hides component when feature flag is disabled', () => {
            wrapper = createComponent({ provide: { glFeatures: { #{camel_case_flag}: false } } });
            expect(wrapper.find('.new-feature').exists()).toBe(false);
          });

          // After
          it('shows component', () => {
            wrapper = createComponent();
            expect(wrapper.find('.new-feature').exists()).toBe(true);
          });
          ```

          #### Example 2: Update beforeEach and describe blocks
          ```javascript
          // Before
          describe('with feature flag enabled', () => {
            beforeEach(() => {
              provide.glFeatures.#{camel_case_flag} = true;
            });

            it('works correctly', () => { /* test code */ });
          });

          describe('with feature flag disabled', () => {
            beforeEach(() => {
              provide.glFeatures.#{camel_case_flag} = false;
            });

            it('falls back to old behavior', () => { /* test code */ });
          });

          // After
          describe('component behavior', () => {
            it('works correctly', () => { /* test code */ });
          });
          ```

          #### Example 3: Update mock imports
          ```javascript
          // Before
          jest.mock('~/feature_flags/feature_flags', () => ({
            __esModule: true,
            default: {
              otherFlag: true,
              #{camel_case_flag}: true
            },
          }));

          // After
          jest.mock('~/feature_flags/feature_flags', () => ({
            __esModule: true,
            default: {
              otherFlag: true
            },
          }));
          ```
        MARKDOWN
      end

      def prompt_js_spec_flag_disabled_examples(camel_case_flag)
        <<~MARKDOWN
          #### Example 1: Remove specific feature-gated tests
          ```javascript
          // Before
          it('shows component when feature flag is enabled', () => {
            wrapper = createComponent({ provide: { glFeatures: { #{camel_case_flag}: true } } });
            expect(wrapper.find('.new-feature').exists()).toBe(true);
          });

          it('hides component when feature flag is disabled', () => {
            wrapper = createComponent({ provide: { glFeatures: { #{camel_case_flag}: false } } });
            expect(wrapper.find('.new-feature').exists()).toBe(false);
          });

          // After
          it('hides component', () => {
            wrapper = createComponent();
            expect(wrapper.find('.new-feature').exists()).toBe(false);
          });
          ```

          #### Example 2: Update beforeEach and describe blocks
          ```javascript
          // Before
          describe('with feature flag enabled', () => {
            beforeEach(() => {
              provide.glFeatures.#{camel_case_flag} = true;
            });

            it('works correctly', () => { /* test code */ });
          });

          describe('with feature flag disabled', () => {
            beforeEach(() => {
              provide.glFeatures.#{camel_case_flag} = false;
            });

            it('falls back to old behavior', () => { /* test code */ });
          });

          // After
          describe('component behavior', () => {
            it('falls back to old behavior', () => { /* test code */ });
          });
          ```

          #### Example 3: Update mock imports
          ```javascript
          // Before
          jest.mock('~/feature_flags/feature_flags', () => ({
            __esModule: true,
            default: {
              otherFlag: true,
              #{camel_case_flag}: true
            },
          }));

          // After
          jest.mock('~/feature_flags/feature_flags', () => ({
            __esModule: true,
            default: {
              otherFlag: true
            },
          }));
          ```
        MARKDOWN
      end

      def ruby_feature_flag_instructions(feature_flag, flag_enabled)
        <<~MARKDOWN
        If you see a branch of logic with `if Feature.enabled?(:#{feature_flag.name})` you should simplify the logic assuming the check returns `#{flag_enabled}`. If you find a method that is returning `Feature.enabled?(:#{feature_flag.name})` then you should return `#{flag_enabled}` instead. You may also see `Feature.disabled?(:#{feature_flag.name})` and this is just the opposite of `enabled?` and you should assume this is always returning `#{!flag_enabled}`.
        MARKDOWN
      end

      def prompt_rspec(feature_flag, file, flag_enabled)
        <<~MARKDOWN
        #{prompt_ruby(feature_flag, file, flag_enabled)}

        #{rspec_instructions(flag_enabled)}
        MARKDOWN
      end

      def rspec_instructions(flag_enabled)
        <<~MARKDOWN
        Branches of tests that have stubbed the feature flag as #{!flag_enabled ? 'enabled' : 'disabled'} should be entirely removed. Pay close attention to the stubbed feature flag values to ensure you remove all redundant test coverage. Note that all feature flags are enabled by default in specs so you can assume branches without `stub_feature_flag` are behaving as though it is enabled. And if you find any branches of code that are calling `stub_feature_flag` for this feature flag and setting it to `true` you should simply remove the call to `stub_feature_flag` as it is redundant#{flag_enabled ? '' : ' also remove those blocks where the feature flag is enabled'}. You are likely to find whole rspec `context` blocks with the feature flag disabled. Be sure to #{flag_enabled ? 'delete' : 'keep'} the entire context block in that case.
        MARKDOWN
      end

      def prompt_markdown(feature_flag, file)
        <<~MARKDOWN
        CRITICAL FORMATTING REQUIREMENT: After making any changes, you MUST scan the entire document and remove all consecutive empty lines. Replace any double, triple, or multiple empty lines with single empty lines. This is mandatory - markdown linting will fail otherwise.

        #{prompt_shared(feature_flag, file, true)}

        MARKDOWN-SPECIFIC INSTRUCTIONS:

        History Notes:
        When updating markdown history notes, do NOT remove existing history notes that refer to this feature flag. Instead, add exactly this new history note:

        ```
        > - [Generally available](#{feature_flag.rollout_issue_url}) in GitLab #{milestones_helper.next_milestone}. Feature flag `#{feature_flag.name}` removed.
        ```

        Other References:
        Remove all other markdown references to this feature flag (except history notes).

        MANDATORY FINAL STEPS:
        1. Remove ALL consecutive empty lines throughout the document
        2. Verify markdown syntax compliance
        3. Ensure no orphaned headers or malformed elements remain

        Remember: The document must pass markdown linting - double empty lines will cause failure.
        MARKDOWN
      end

      def skip_markdown_file?(file)
        file_path = file.to_s.downcase

        file_path.include?('doc-locale')
      end
    end
  end
end
