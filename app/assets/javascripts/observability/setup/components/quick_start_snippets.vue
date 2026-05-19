<script>
import { GlTabs, GlTab, GlButton } from '@gitlab/ui';
import { debounce } from 'lodash-es';
import { s__ } from '~/locale';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import Tracking from '~/tracking';
import { LANGUAGES, SNIPPET_COPIED_TIMEOUT } from '../constants';
import { generateSnippet } from '../utils';

export default {
  name: 'QuickStartSnippets',
  components: {
    GlTabs,
    GlTab,
    GlButton,
  },
  mixins: [Tracking.mixin()],
  props: {
    endpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      copied: false,
      activeTabIndex: 0,
    };
  },
  computed: {
    languages() {
      return LANGUAGES.map((lang) => ({
        ...lang,
        code: generateSnippet(lang.key, this.endpoint),
      }));
    },
    activeSnippet() {
      return this.languages[this.activeTabIndex]?.code || '';
    },
    copyButtonText() {
      return this.copied ? this.$options.i18n.copied : this.$options.i18n.copy;
    },
  },
  created() {
    this.resetCopyState = debounce(() => {
      this.copied = false;
    }, SNIPPET_COPIED_TIMEOUT);
  },
  beforeDestroy() {
    this.resetCopyState.cancel();
  },
  methods: {
    async handleCopy() {
      try {
        await copyToClipboard(this.activeSnippet);
        this.copied = true;
        this.track('copy_quick_start_snippet', {
          label: this.languages[this.activeTabIndex].key,
        });
        this.resetCopyState();
      } catch (e) {
        this.$toast.show(this.$options.i18n.copyError);
        captureException(e);
      }
    },
    onTabChange(index) {
      this.activeTabIndex = index;
      this.track('switch_quick_start_language', {
        label: this.languages[index].key,
      });
    },
  },
  i18n: {
    heading: s__('Observability|Quick start'),
    description: s__(
      'Observability|Add this to your application to start sending traces to GitLab. The CI/CD variables are automatically available in your pipeline.',
    ),
    copy: s__('Observability|Copy'),
    copied: s__('Observability|Copied!'),
    copyError: s__('Observability|Failed to copy snippet'),
  },
};
</script>

<template>
  <div data-testid="quick-start-snippets" class="gl-border-t gl-mb-6 gl-border-subtle gl-pt-5">
    <h3 class="gl-heading-3 gl-mb-2">{{ $options.i18n.heading }}</h3>
    <p class="gl-mb-5 gl-text-subtle">{{ $options.i18n.description }}</p>

    <div class="gl-relative">
      <gl-tabs :value="activeTabIndex" @input="onTabChange">
        <gl-tab v-for="lang in languages" :key="lang.key" :title="lang.name">
          <div class="gl-relative">
            <gl-button
              category="tertiary"
              size="small"
              class="gl-absolute gl-right-3 gl-top-3"
              :class="{ 'gl-text-success': copied }"
              :aria-label="copyButtonText"
              aria-live="polite"
              data-testid="copy-snippet-button"
              @click="handleCopy"
            >
              {{ copyButtonText }}
            </gl-button>
            <pre
              class="gl-overflow-x-auto gl-rounded-base gl-bg-strong gl-p-4 gl-text-sm gl-leading-20"
            ><code>{{ lang.code }}</code></pre>
          </div>
        </gl-tab>
      </gl-tabs>
    </div>
  </div>
</template>
