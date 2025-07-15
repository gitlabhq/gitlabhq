<script>
import { GlDrawer, GlButton, GlFormTextarea, GlAccordion, GlAccordionItem } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { s__ } from '~/locale';

export default {
  name: 'ManageExclusionsDrawer',
  components: {
    GlDrawer,
    GlButton,
    GlFormTextarea,
    GlAccordion,
    GlAccordionItem,
  },
  props: {
    open: {
      type: Boolean,
      required: true,
    },
    exclusionRules: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      localRules: '',
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
  },
  watch: {
    exclusionRules: {
      handler(newRules) {
        this.localRules = newRules.join('\n');
      },
      immediate: true,
    },
    open(isOpen) {
      if (isOpen) {
        this.localRules = this.exclusionRules.join('\n');
      }
    },
  },
  methods: {
    handleSave() {
      const rules = this.localRules
        .split('\n')
        .map((rule) => rule.trim())
        .filter((rule) => rule.length > 0);

      // Update the exclusion rules in the parent component
      this.$emit('save', rules);
    },
    handleCancel() {
      this.localRules = this.exclusionRules.join('\n');
      this.$emit('close');
    },
  },
  i18n: {
    title: s__('DuoFeatures|Manage Exclusions'),
    filesAndDirectoriesLabel: s__('DuoFeatures|Files or directories'),
    filesAndDirectoriesHelp: s__('DuoFeatures|Add each exclusion on a separate line.'),
    saveExclusions: s__('DuoFeatures|Save exclusions'),
    cancel: s__('DuoFeatures|Cancel'),
    viewExamples: s__('DuoFeatures|View examples of exclusions.'),
    exampleEnvFiles: s__('DuoFeatures|Excludes all .env files'),
    exampleSecretsDirectory: s__('DuoFeatures|Excludes entire secrets directory'),
    exampleKeyFiles: s__('DuoFeatures|Excludes all .key files in any subdirectory'),
    exampleSpecificFile: s__('DuoFeatures|Excludes the specified file'),
    exampleAllowFile: s__(
      'DuoFeatures|Allows the specified file in the specified directory, even if excluded by previous rules',
    ),
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    :open="open"
    data-testid="manage-exclusions-drawer"
    @close="handleCancel"
  >
    <template #title>
      <h2 class="gl-heading-3 gl-mb-0">{{ $options.i18n.title }}</h2>
    </template>

    <div class="gl-flex gl-flex-col gl-gap-4 gl-p-4">
      <div>
        <label for="exclusion-rules-textarea" class="gl-mb-2 gl-block gl-font-bold">
          {{ $options.i18n.filesAndDirectoriesLabel }}
        </label>
        <p class="gl-mb-3 gl-text-subtle">
          {{ $options.i18n.filesAndDirectoriesHelp }}
        </p>
        <gl-form-textarea
          id="exclusion-rules-textarea"
          v-model="localRules"
          class="gl-font-monospace"
          rows="10"
          data-testid="exclusion-rules-textarea"
        />
      </div>

      <gl-accordion :header-level="3" class="gl-border-t gl-pt-4">
        <gl-accordion-item
          :title="$options.i18n.viewExamples"
          class="gl-font-normal"
          data-testid="examples-accordion"
        >
          <div class="md">
            <blockquote>
              <ul class="gl-mb-0 gl-p-0">
                <li>
                  <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
                  <code class="gl-font-monospace">*.env</code> - {{ $options.i18n.exampleEnvFiles }}
                </li>
                <li>
                  <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
                  <code class="gl-font-monospace">secrets/</code> -
                  {{ $options.i18n.exampleSecretsDirectory }}
                </li>
                <li>
                  <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
                  <code class="gl-font-monospace">**/*.key</code> -
                  {{ $options.i18n.exampleKeyFiles }}
                </li>
                <li>
                  <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
                  <code class="gl-font-monospace">config/production.yml</code> -
                  {{ $options.i18n.exampleSpecificFile }}
                </li>
                <li>
                  <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
                  <code class="gl-font-monospace">!secrets/file.json</code> -
                  {{ $options.i18n.exampleAllowFile }}
                </li>
              </ul>
            </blockquote>
          </div>
        </gl-accordion-item>
      </gl-accordion>

      <div class="gl-border-t gl-flex gl-gap-3 gl-pt-4">
        <gl-button
          variant="confirm"
          data-testid="save-exclusions-button"
          @click.prevent.stop="handleSave"
        >
          {{ $options.i18n.saveExclusions }}
        </gl-button>
        <gl-button data-testid="cancel-button" @click="handleCancel">
          {{ $options.i18n.cancel }}
        </gl-button>
      </div>
    </div>
  </gl-drawer>
</template>
