<script>
import { GlBadge, GlButton, GlIcon, GlLink } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { s__, sprintf } from '~/locale';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';

export default {
  name: 'CandidateHeader',
  components: {
    DeleteButton,
    GlBadge,
    GlButton,
    GlIcon,
    GlLink,
    PageHeading,
    TimeAgoTooltip,
  },
  mixins: [timeagoMixin],
  props: {
    candidate: {
      type: Object,
      required: true,
    },
  },
  computed: {
    title() {
      return sprintf(s__('MlExperimentTracking|Run %{id}'), { id: this.info.iid });
    },
    authorInfo() {
      return sprintf(s__('MlExperimentTracking|by %{author}'), { author: this.info.authorName });
    },
    statusVariant() {
      return this.$options.statusVariants[this.info.status];
    },
    info() {
      return this.candidate.info;
    },
  },
  i18n: {
    deleteCandidateConfirmationMessage: s__(
      'MlExperimentTracking|Deleting this run will delete the associated parameters, metrics, and metadata.',
    ),
    deleteCandidatePrimaryActionLabel: s__('MlExperimentTracking|Delete run'),
    deleteCandidateModalTitle: s__('MlExperimentTracking|Delete run?'),
    promoteText: s__('ExperimentTracking|Promote run'),
  },
  statusVariants: {
    running: 'success',
    scheduled: 'info',
    finished: 'muted',
    failed: 'warning',
    killed: 'danger',
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-justify-between">
    <page-heading>
      <template #heading>
        <gl-link data-testid="experiment-link" :href="info.pathToExperiment">
          {{ info.experimentName }} /
        </gl-link>
        <span class="gl-inline-flex gl-items-center">
          {{ title }}
        </span>
      </template>
      <template #description>
        <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-x-2">
          <gl-badge :variant="statusVariant">
            <gl-icon name="issue-type-test-case" />
            {{ info.status }}
          </gl-badge>
          <time-ago-tooltip :time="info.createdAt" />
          <gl-link
            v-if="info.authorName"
            data-testid="author-link"
            class="js-user-link gl-font-bold !gl-text-subtle"
            :href="info.authorWebUrl"
          >
            <span class="sm:gl-inline">{{ authorInfo }}</span>
          </gl-link>
        </div>
      </template>
    </page-heading>
    <div class="gl-flex">
      <gl-button v-if="info.canPromote" :href="info.promotePath" variant="confirm" class="gl-mr-3">
        {{ $options.i18n.promoteText }}
      </gl-button>
      <delete-button
        v-if="candidate.canWriteModelExperiments"
        :delete-path="info.path"
        :delete-confirmation-text="$options.i18n.deleteCandidateConfirmationMessage"
        :action-primary-text="$options.i18n.deleteCandidatePrimaryActionLabel"
        :modal-title="$options.i18n.deleteCandidateModalTitle"
      />
    </div>
  </div>
</template>
