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
  storageUsageQuotaHelpPage: helpPagePath('user/usage_quotas'),
};
</script>
<template>
  <div class="gl-display-flex gl-flex-direction-column">
    <div class="gl-display-flex gl-align-items-center gl-py-3">
      <div
        class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row gl-justify-content-space-between gl-align-items-stretch gl-flex-grow-1"
      >
        <div
          class="gl-display-flex gl-flex-direction-column gl-mb-3 gl-sm-mb-0 gl-min-w-0 gl-flex-grow-1"
        >
          <div
            v-if="
              /* eslint-disable-line @gitlab/vue-prefer-dollar-scopedslots */ $slots[
                'left-primary-text'
              ]
            "
            class="gl-display-flex gl-align-items-center gl-text-body gl-font-bold gl-min-h-6 gl-min-w-0"
          >
            <slot name="left-primary-text"></slot>
          </div>
          <div
            v-if="
              /* eslint-disable-line @gitlab/vue-prefer-dollar-scopedslots */ $slots[
                'left-secondary-text'
              ]
            "
            class="gl-display-flex gl-align-items-center gl-text-gray-500 gl-min-h-6 gl-min-w-0 gl-flex-grow-1 gl-w-7/10 gl-md-max-w-70p"
          >
            <slot name="left-secondary-text"></slot>
          </div>
        </div>
        <div
          class="gl-display-flex gl-flex-direction-column gl-sm-align-items-flex-end gl-justify-content-space-between gl-text-gray-500 gl-flex-shrink-0"
        >
          <div
            v-if="
              /* eslint-disable-line @gitlab/vue-prefer-dollar-scopedslots */ $slots[
                'right-primary-text'
              ]
            "
            class="gl-display-flex gl-align-items-center gl-sm-text-body sm:gl-font-bold gl-min-h-6"
          >
            <slot name="right-primary-text"></slot>
          </div>
          <div
            v-if="
              /* eslint-disable-line @gitlab/vue-prefer-dollar-scopedslots */ $slots[
                'right-secondary-text'
              ]
            "
            class="gl-display-flex gl-align-items-center gl-min-h-6"
          >
            <slot v-if="!loading" name="right-secondary-text"></slot>
            <gl-skeleton-loader v-else :width="60" :lines="1" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
