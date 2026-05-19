<script>
import {
  GlBadge,
  GlButton,
  GlIcon,
  GlPopover,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { setCookie, removeCookie, getCookie } from '~/lib/utils/common_utils';
import Api from '~/api';
import Tracking from '~/tracking';
import { SERVICE_PING_SCHEMA } from '~/tracking/constants';
import { RAPID_DIFFS_COOKIE_NAME } from '~/rapid_diffs/constants';

const FEEDBACK_ISSUE_PATH = 'https://gitlab.com/gitlab-org/gitlab/-/work_items/596236';
const TRACKING_TIMEOUT_MS = 500;

function waitableTrackEvent(event, additionalProperties = {}) {
  Tracking.event(undefined, event, {
    context: {
      schema: SERVICE_PING_SCHEMA,
      data: { event_name: event, data_source: 'redis_hll' },
    },
    ...additionalProperties,
  });
  const tracking = Api.trackInternalEvent(event, additionalProperties);
  const timeout = new Promise((resolve) => {
    setTimeout(resolve, TRACKING_TIMEOUT_MS);
  });

  return Promise.race([tracking, timeout]).catch(() => {});
}

export default {
  name: 'RapidDiffsToggle',
  components: {
    GlBadge,
    GlButton,
    GlIcon,
    GlPopover,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
  },
  data() {
    return {
      enabled: getCookie(RAPID_DIFFS_COOKIE_NAME) === 'true',
    };
  },
  computed: {
    infoGroup() {
      return {
        items: [
          {
            text: this.$options.i18n.learnMore,
            href: this.$options.docsUrl,
            icon: 'question-o',
            extraAttrs: { target: '_blank' },
          },
          {
            text: this.$options.i18n.leaveFeedback,
            href: FEEDBACK_ISSUE_PATH,
            icon: 'comment-dots',
            extraAttrs: { target: '_blank' },
          },
        ],
      };
    },
    switchGroup() {
      return {
        items: [
          {
            text: this.$options.i18n.switchToClassic,
            action: this.disable,
          },
        ],
      };
    },
  },
  methods: {
    async enable() {
      await waitableTrackEvent('toggle_rapid_diffs', { label: 'enabled' });
      setCookie(RAPID_DIFFS_COOKIE_NAME, 'true');
      const url = new URL(window.location.href);
      url.searchParams.delete('rapid_diffs_disabled');
      window.location.assign(url.toString());
    },
    async disable() {
      await waitableTrackEvent('toggle_rapid_diffs', { label: 'disabled' });
      removeCookie(RAPID_DIFFS_COOKIE_NAME);
      const url = new URL(window.location.href);
      url.searchParams.delete('rapid_diffs');
      window.location.assign(url.toString());
    },
  },
  i18n: {
    tryRapidDiffs: s__('RapidDiffs|Try Rapid Diffs'),
    beta: s__('RapidDiffs|Beta'),
    popoverTitle: s__('RapidDiffs|Improved performance loading diffs'),
    popoverBody: s__(
      'RapidDiffs|Speeds up diff loading and interactions when reviewing code changes.',
    ),
    popoverBetaNote: s__('RapidDiffs|Some classic diff features are not yet available.'),
    learnMore: __('Learn more'),
    rapidDiffsEnabled: s__('RapidDiffs|Rapid Diffs'),
    leaveFeedback: s__('RapidDiffs|Leave feedback'),
    switchToClassic: s__('RapidDiffs|Switch to classic loading'),
  },
  docsUrl: helpPagePath('user/project/merge_requests/changes', { anchor: 'rapid-diffs' }),
};
</script>

<template>
  <div>
    <template v-if="!enabled">
      <gl-button
        ref="tryButton"
        variant="confirm"
        category="tertiary"
        data-testid="rapid-diffs-try-button"
        @click="enable"
      >
        {{ $options.i18n.tryRapidDiffs }}
        <gl-badge variant="neutral" data-testid="rapid-diffs-beta-badge">
          {{ $options.i18n.beta }}
        </gl-badge>
      </gl-button>
      <gl-popover
        :target="() => $refs.tryButton.$el"
        placement="bottom"
        :title="$options.i18n.popoverTitle"
      >
        <p>{{ $options.i18n.popoverBody }}</p>
        <p class="gl-mb-0">{{ $options.i18n.popoverBetaNote }}</p>
        <gl-button
          class="gl-mt-3"
          :href="$options.docsUrl"
          target="_blank"
          category="secondary"
          data-testid="rapid-diffs-learn-more-button"
        >
          {{ $options.i18n.learnMore }}
        </gl-button>
      </gl-popover>
    </template>
    <gl-disclosure-dropdown v-else data-testid="rapid-diffs-dropdown">
      <template #toggle="{ accessibilityAttributes }">
        <gl-button v-bind="accessibilityAttributes" category="tertiary">
          {{ $options.i18n.rapidDiffsEnabled }}
          <gl-badge variant="neutral" data-testid="rapid-diffs-beta-badge">
            {{ $options.i18n.beta }}
          </gl-badge>
          <gl-icon class="dropdown-chevron" name="chevron-down" />
        </gl-button>
      </template>
      <gl-disclosure-dropdown-group :group="infoGroup" />
      <gl-disclosure-dropdown-group :group="switchGroup" bordered />
    </gl-disclosure-dropdown>
  </div>
</template>
