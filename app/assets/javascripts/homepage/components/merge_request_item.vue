<script>
import ApprovalCount from 'ee_else_ce/merge_requests/components/approval_count.vue';
import { __, sprintf } from '~/locale';
import { newDate } from '~/lib/utils/datetime/date_calculation_utility';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import DiscussionsBadge from '~/merge_requests/list/components/discussions_badge.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';

export default {
  name: 'MergeRequestItem',
  components: {
    ApprovalCount,
    CiIcon,
    DiscussionsBadge,
    TooltipOnTruncate,
  },
  props: {
    mergeRequest: {
      type: Object,
      required: true,
    },
  },
  emits: ['click'],
  computed: {
    projectPath() {
      const { name, namespace } = this.mergeRequest.project;

      return `${namespace.name} / ${name}`;
    },
    detailedStatus() {
      return this.mergeRequest.headPipeline?.detailedStatus;
    },
    updatedAtText() {
      return sprintf(__('Updated %{date}'), {
        date: localeDateFormat.asDateTime.format(newDate(this.mergeRequest.updatedAt)),
      });
    },
  },
};
</script>

<template>
  <div
    class="gl-relative -gl-mx-3 gl-flex gl-flex-col gl-gap-1 gl-rounded-base gl-p-3 hover:gl-bg-subtle"
  >
    <span class="gl-flex gl-min-w-0 gl-gap-2 gl-text-sm gl-text-subtle">
      <tooltip-on-truncate
        :title="projectPath"
        class="gl-relative gl-z-1 gl-overflow-hidden gl-text-ellipsis gl-whitespace-nowrap"
      >
        {{ projectPath }}
      </tooltip-on-truncate>
    </span>

    <a
      :href="mergeRequest.webPath"
      class="gl-text-default gl-stretched-link hover:gl-text-default hover:gl-no-underline"
      @click="$emit('click')"
    >
      <tooltip-on-truncate
        :title="mergeRequest.title"
        class="gl-relative gl-z-1 gl-block gl-overflow-hidden gl-text-ellipsis gl-whitespace-nowrap"
      >
        {{ mergeRequest.title }}
      </tooltip-on-truncate>
    </a>

    <span class="gl-relative gl-flex gl-items-center gl-justify-between gl-gap-3">
      <span class="gl-flex gl-shrink-0 gl-items-center gl-gap-3">
        <ci-icon v-if="detailedStatus" :status="detailedStatus" :use-link="false" />
        <approval-count :merge-request="mergeRequest" neutral />
        <discussions-badge
          v-if="mergeRequest.resolvableDiscussionsCount"
          :merge-request="mergeRequest"
          neutral
        />
      </span>
      <time
        :datetime="mergeRequest.updatedAt"
        :title="updatedAtText"
        class="gl-min-w-0 gl-truncate gl-text-sm gl-text-subtle"
      >
        {{ updatedAtText }}
      </time>
    </span>
  </div>
</template>
