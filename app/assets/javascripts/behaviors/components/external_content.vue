<script>
import { GlAlert, GlButton, GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import { s__, sprintf } from '~/locale';
import { embedStyle, getPlaceholderStyles } from '../markdown/external_content';

const ALERT_BORDER_RADIUS = 'var(--gl-border-radius-lg) var(--gl-border-radius-lg) 0 0';

export default {
  name: 'ExternalContent',
  i18n: {
    heading: s__('ExternalContent|External content from %{provider} (%{host})'),
  },
  components: {
    GlAlert,
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
  },
  props: {
    provider: {
      type: Object,
      required: true,
    },
    href: {
      type: String,
      required: false,
      default: null,
    },
    width: {
      type: [String, Number],
      required: false,
      default: null,
    },
    height: {
      type: [String, Number],
      required: false,
      default: null,
    },
  },
  emits: ['activated'],
  data() {
    return {
      activated: false,
      headingId: uniqueId('external-content-heading-'),
      descriptionId: uniqueId('external-content-description-'),
    };
  },
  computed: {
    active() {
      return this.activated || !this.provider.require_activation;
    },
    host() {
      return new URL(this.provider.src_origin).host;
    },
    title() {
      return sprintf(
        this.$options.i18n.heading,
        { provider: this.provider.name, host: this.host },
        false,
      );
    },
    placeholderStyles() {
      return getPlaceholderStyles(this.width, this.height);
    },
  },
  methods: {
    async activate() {
      this.activated = true;
      await this.$nextTick();
      this.$emit('activated');
    },
  },
  embedStyle,
  alertStyle: { '--gl-alert-border-radius': ALERT_BORDER_RADIUS },
};
</script>
<template>
  <span class="gl-flex gl-flex-col" :style="$options.embedStyle">
    <template v-if="active">
      <gl-alert
        variant="warning"
        :dismissible="false"
        role="note"
        politeness="off"
        class="gl-w-0 gl-min-w-full gl-wrap-anywhere"
        :style="$options.alertStyle"
        data-testid="external-content-warning"
      >
        <gl-sprintf
          :message="
            s__(
              'ExternalContent|You are viewing external content from %{host}. GitLab does not control this content.',
            )
          "
        >
          <template #host>
            <strong>{{ host }}</strong>
          </template>
        </gl-sprintf>
        <gl-link
          v-if="href"
          :href="href"
          target="_blank"
          rel="noopener noreferrer"
          variant="meta"
          show-external-icon
          class="gl-font-bold"
          data-testid="external-content-open-in-new-tab"
        >
          {{ s__('ExternalContent|Open in new tab') }}
        </gl-link>
      </gl-alert>
      <slot :title="title"></slot>
    </template>
    <span
      v-else
      class="gl-grid gl-w-full gl-min-w-full gl-grid-cols-1 gl-rounded-lg gl-bg-subtle gl-shadow-inner-1-border-default"
      :style="placeholderStyles.box"
      data-testid="external-content-placeholder"
    >
      <span class="gl-col-start-1 gl-row-start-1" :style="placeholderStyles.spacer"></span>
      <span
        class="gl-col-start-1 gl-row-start-1 gl-flex gl-flex-col gl-items-center gl-justify-center gl-gap-5 gl-p-6 gl-text-center"
      >
        <span
          class="gl-border gl-flex gl-size-8 gl-items-center gl-justify-center gl-rounded-full gl-border-feedback-warning gl-bg-feedback-warning"
        >
          <gl-icon name="warning" variant="warning" :size="24" />
        </span>
        <span class="gl-block">
          <span
            :id="headingId"
            class="gl-mb-2 gl-block gl-font-bold"
            data-testid="external-content-heading"
          >
            <gl-sprintf :message="$options.i18n.heading">
              <template #provider>{{ provider.name }}</template>
              <template #host>
                <code>{{ host }}</code>
              </template>
            </gl-sprintf>
          </span>
          <span :id="descriptionId" class="gl-block gl-text-sm gl-text-subtle">
            <gl-sprintf
              :message="
                s__(
                  'ExternalContent|If you load this content, %{host} receives your IP address and browser information. GitLab cannot verify how %{host} uses this data. Do not enter passwords, tokens, or other sensitive information.',
                )
              "
            >
              <template #host>
                <code>{{ host }}</code>
              </template>
            </gl-sprintf>
          </span>
        </span>
        <gl-button
          variant="confirm"
          icon="arrow-right"
          :aria-describedby="`${headingId} ${descriptionId}`"
          data-testid="activate-external-content"
          @click="activate"
        >
          {{ s__('ExternalContent|Load external content') }}
        </gl-button>
      </span>
    </span>
  </span>
</template>
