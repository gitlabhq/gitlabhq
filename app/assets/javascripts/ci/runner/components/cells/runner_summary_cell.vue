<script>
import { GlIcon, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, __, formatNumber } from '~/locale';

import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import RunnerName from '../runner_name.vue';
import RunnerTags from '../runner_tags.vue';
import RunnerTypeBadge from '../runner_type_badge.vue';
import RunnerManagersBadge from '../runner_managers_badge.vue';

import { formatJobCount } from '../../utils';
import {
  I18N_NO_DESCRIPTION,
  I18N_LOCKED_RUNNER_DESCRIPTION,
  I18N_VERSION_LABEL,
  I18N_LAST_CONTACT_LABEL,
  I18N_CREATED_AT_LABEL,
  I18N_CREATED_AT_BY_LABEL,
} from '../../constants';
import RunnerSummaryField from './runner_summary_field.vue';

export default {
  components: {
    GlIcon,
    GlSprintf,
    TimeAgo,
    RunnerSummaryField,
    RunnerName,
    RunnerTags,
    RunnerTypeBadge,
    RunnerManagersBadge,
    RunnerUpgradeStatusIcon: () =>
      import('ee_component/ci/runner/components/runner_upgrade_status_icon.vue'),
    UserAvatarLink,
    TooltipOnTruncate,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  computed: {
    managersCount() {
      return this.runner.managers?.count || 0;
    },
    firstIpAddress() {
      return this.runner.managers?.nodes?.[0]?.ipAddress || null;
    },
    additionalIpAddressCount() {
      return this.managersCount - 1;
    },
    jobCount() {
      return formatJobCount(this.runner.jobCount);
    },
    createdBy() {
      return this.runner?.createdBy;
    },
    createdByImgAlt() {
      const name = this.createdBy?.name;
      if (name) {
        return sprintf(__("%{name}'s avatar"), { name });
      }
      return null;
    },
  },
  methods: {
    formatNumber,
  },
  i18n: {
    I18N_NO_DESCRIPTION,
    I18N_LOCKED_RUNNER_DESCRIPTION,
    I18N_VERSION_LABEL,
    I18N_LAST_CONTACT_LABEL,
    I18N_CREATED_AT_LABEL,
    I18N_CREATED_AT_BY_LABEL,
  },
};
</script>

<template>
  <div>
    <div class="gl-mb-3">
      <slot :runner="runner" name="runner-name">
        <runner-name :runner="runner" />
      </slot>

      <runner-managers-badge :count="managersCount" size="sm" class="gl-vertical-align-middle" />
      <gl-icon
        v-if="runner.locked"
        v-gl-tooltip
        :title="$options.i18n.I18N_LOCKED_RUNNER_DESCRIPTION"
        name="lock"
      />
      <runner-type-badge :type="runner.runnerType" size="sm" class="gl-vertical-align-middle" />
    </div>

    <div class="gl-mb-3 gl-ml-auto gl-display-inline-flex gl-max-w-full">
      <template v-if="runner.version">
        <div class="gl-flex-shrink-0">
          <runner-upgrade-status-icon :upgrade-status="runner.upgradeStatus" />
          <gl-sprintf :message="$options.i18n.I18N_VERSION_LABEL">
            <template #version>{{ runner.version }}</template>
          </gl-sprintf>
        </div>
        <div class="gl-text-secondary gl-mx-2" aria-hidden="true">·</div>
      </template>
      <tooltip-on-truncate
        class="gl-text-truncate gl-display-block"
        :class="{ 'gl-text-secondary': !runner.description }"
        :title="runner.description"
      >
        {{ runner.description || $options.i18n.I18N_NO_DESCRIPTION }}
      </tooltip-on-truncate>
    </div>

    <div>
      <runner-summary-field icon="clock">
        <gl-sprintf :message="$options.i18n.I18N_LAST_CONTACT_LABEL">
          <template #timeAgo>
            <time-ago v-if="runner.contactedAt" :time="runner.contactedAt" />
            <template v-else>{{ __('Never') }}</template>
          </template>
        </gl-sprintf>
      </runner-summary-field>

      <runner-summary-field v-if="firstIpAddress" icon="disk" :tooltip="__('IP Address')">
        {{ firstIpAddress }}
        <template v-if="additionalIpAddressCount"
          >(+{{ formatNumber(additionalIpAddressCount) }})</template
        >
      </runner-summary-field>

      <runner-summary-field icon="pipeline" data-testid="job-count" :tooltip="__('Jobs')">
        {{ jobCount }}
      </runner-summary-field>

      <runner-summary-field icon="calendar">
        <template v-if="createdBy">
          <gl-sprintf :message="$options.i18n.I18N_CREATED_AT_BY_LABEL">
            <template #timeAgo>
              <time-ago v-if="runner.createdAt" :time="runner.createdAt" />
            </template>
            <template #avatar>
              <user-avatar-link
                :link-href="createdBy.webUrl"
                :img-src="createdBy.avatarUrl"
                img-css-classes="gl-vertical-align-top"
                :img-size="16"
                :img-alt="createdByImgAlt"
                :tooltip-text="createdBy.username"
              />
            </template>
          </gl-sprintf>
        </template>
        <template v-else>
          <gl-sprintf :message="$options.i18n.I18N_CREATED_AT_LABEL">
            <template #timeAgo>
              <time-ago v-if="runner.createdAt" :time="runner.createdAt" />
            </template>
          </gl-sprintf>
        </template>
      </runner-summary-field>
    </div>

    <runner-tags class="gl-display-block" :tag-list="runner.tagList" size="sm" />
  </div>
</template>
