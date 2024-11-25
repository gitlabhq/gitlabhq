<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'UsageBanner',
  components: {
    GlSkeletonLoader,
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  storageUsageQuotaHelpPage: helpPagePath('user/storage_usage_quotas'),
};
</script>
<template>
  <div class="gl-flex gl-flex-col">
    <div class="gl-flex gl-items-center gl-py-3">
      <div class="gl-flex gl-grow gl-flex-col gl-items-stretch gl-justify-between sm:gl-flex-row">
        <div class="gl-mb-3 gl-flex gl-min-w-0 gl-grow gl-flex-col sm:gl-mb-0">
          <div
            v-if="
              /* eslint-disable-line @gitlab/vue-prefer-dollar-scopedslots */ $slots[
                'left-primary-text'
              ]
            "
            class="gl-flex gl-min-h-6 gl-min-w-0 gl-items-center gl-font-bold gl-text-default"
          >
            <slot name="left-primary-text"></slot>
          </div>
          <div
            v-if="
              /* eslint-disable-line @gitlab/vue-prefer-dollar-scopedslots */ $slots[
                'left-secondary-text'
              ]
            "
            class="gl-flex gl-min-h-6 gl-w-7/10 gl-min-w-0 gl-grow gl-items-center gl-text-subtle md:gl-max-w-7/10"
          >
            <slot name="left-secondary-text"></slot>
          </div>
        </div>
        <div
          class="gl-flex gl-shrink-0 gl-flex-col gl-justify-between gl-text-subtle sm:gl-items-end"
        >
          <div
            v-if="
              /* eslint-disable-line @gitlab/vue-prefer-dollar-scopedslots */ $slots[
                'right-primary-text'
              ]
            "
            class="gl-flex gl-min-h-6 gl-items-center sm:gl-font-bold sm:gl-text-default"
          >
            <slot name="right-primary-text"></slot>
          </div>
          <div
            v-if="
              /* eslint-disable-line @gitlab/vue-prefer-dollar-scopedslots */ $slots[
                'right-secondary-text'
              ]
            "
            class="gl-flex gl-min-h-6 gl-items-center"
          >
            <slot v-if="!loading" name="right-secondary-text"></slot>
            <gl-skeleton-loader v-else :width="60" :lines="1" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
