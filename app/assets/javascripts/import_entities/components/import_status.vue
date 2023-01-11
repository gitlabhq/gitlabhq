<script>
import { GlAccordion, GlAccordionItem, GlBadge, GlIcon } from '@gitlab/ui';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { __, s__ } from '~/locale';
import { STATUSES } from '../constants';

const STATISTIC_ITEMS = {
  diff_note: __('Diff notes'),
  issue: __('Issues'),
  issue_attachment: s__('GithubImporter|Issue attachments'),
  issue_event: __('Issue events'),
  label: __('Labels'),
  lfs_object: __('LFS objects'),
  merge_request_attachment: s__('GithubImporter|Merge request attachments'),
  milestone: __('Milestones'),
  note: __('Notes'),
  note_attachment: s__('GithubImporter|Note attachments'),
  protected_branch: __('Protected branches'),
  pull_request: s__('GithubImporter|Pull requests'),
  pull_request_merged_by: s__('GithubImporter|PR mergers'),
  pull_request_review: s__('GithubImporter|PR reviews'),
  pull_request_review_request: s__('GithubImporter|PR reviews'),
  release: __('Releases'),
  release_attachment: s__('GithubImporter|Release attachments'),
};

// support both camel case and snake case versions
Object.assign(STATISTIC_ITEMS, convertObjectPropsToCamelCase(STATISTIC_ITEMS));

const SCHEDULED_STATUS = {
  icon: 'status-scheduled',
  text: __('Pending'),
  variant: 'muted',
};

const STATUS_MAP = {
  [STATUSES.NONE]: {
    icon: 'status-waiting',
    text: __('Not started'),
    variant: 'muted',
  },
  [STATUSES.SCHEDULING]: SCHEDULED_STATUS,
  [STATUSES.SCHEDULED]: SCHEDULED_STATUS,
  [STATUSES.CREATED]: SCHEDULED_STATUS,
  [STATUSES.STARTED]: {
    icon: 'status-running',
    text: __('Importing...'),
    variant: 'info',
  },
  [STATUSES.FAILED]: {
    icon: 'status-failed',
    text: __('Failed'),
    variant: 'danger',
  },
  [STATUSES.TIMEOUT]: {
    icon: 'status-failed',
    text: __('Timeout'),
    variant: 'danger',
  },
  [STATUSES.CANCELED]: {
    icon: 'status-stopped',
    text: __('Cancelled'),
    variant: 'neutral',
  },
};

function isIncompleteImport(stats) {
  return Object.keys(stats.fetched).some((key) => stats.fetched[key] !== stats.imported[key]);
}

export default {
  name: 'ImportStatus',
  components: {
    GlAccordion,
    GlAccordionItem,
    GlBadge,
    GlIcon,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
    stats: {
      type: Object,
      required: false,
      default: () => ({ fetched: {}, imported: {} }),
    },
  },

  computed: {
    knownStats() {
      const knownStatisticKeys = Object.keys(STATISTIC_ITEMS);
      return Object.keys(this.stats.fetched).filter((key) => knownStatisticKeys.includes(key));
    },

    hasStats() {
      return this.stats && this.knownStats.length > 0;
    },

    mappedStatus() {
      if (this.status === STATUSES.FINISHED) {
        const isIncomplete = this.stats && isIncompleteImport(this.stats);
        return {
          icon: 'status-success',
          ...(isIncomplete
            ? {
                text: __('Partial import'),
                variant: 'warning',
              }
            : {
                text: __('Complete'),
                variant: 'success',
              }),
        };
      }

      return STATUS_MAP[this.status];
    },
  },

  methods: {
    getStatisticIconProps(key) {
      const fetched = this.stats.fetched[key];
      const imported = this.stats.imported[key];

      if (fetched === imported) {
        return { name: 'status-success', class: 'gl-text-green-400' };
      } else if (imported === 0) {
        return { name: 'status-scheduled', class: 'gl-text-gray-400' };
      }

      return { name: 'status-running', class: 'gl-text-blue-400' };
    },
  },

  STATISTIC_ITEMS,
};
</script>

<template>
  <div>
    <div class="gl-display-inline-block gl-w-13">
      <gl-badge :icon="mappedStatus.icon" :variant="mappedStatus.variant" size="md" class="gl-mr-2">
        {{ mappedStatus.text }}
      </gl-badge>
    </div>
    <gl-accordion v-if="hasStats" :header-level="3">
      <gl-accordion-item :title="__('Details')">
        <ul class="gl-p-0 gl-list-style-none gl-font-sm">
          <li v-for="key in knownStats" :key="key">
            <div class="gl-display-flex gl-w-20 gl-align-items-center">
              <gl-icon
                :size="12"
                class="gl-mr-3 gl-flex-shrink-0"
                v-bind="getStatisticIconProps(key)"
              />
              <span class="">{{ $options.STATISTIC_ITEMS[key] }}</span>
              <span class="gl-ml-auto">
                {{ stats.imported[key] || 0 }}/{{ stats.fetched[key] }}
              </span>
            </div>
          </li>
        </ul>
      </gl-accordion-item>
    </gl-accordion>
  </div>
</template>
