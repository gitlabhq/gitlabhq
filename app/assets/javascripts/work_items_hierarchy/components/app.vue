<script>
import { GlBanner } from '@gitlab/ui';
import Cookies from '~/lib/utils/cookies';
import { parseBoolean } from '~/lib/utils/common_utils';
import RESPONSE from '../static_response';
import { WORK_ITEMS_SURVEY_COOKIE_NAME, workItemTypes } from '../constants';
import Hierarchy from './hierarchy.vue';

export default {
  components: {
    GlBanner,
    Hierarchy,
  },
  inject: ['illustrationPath', 'licensePlan'],
  data() {
    return {
      bannerVisible: !parseBoolean(Cookies.get(WORK_ITEMS_SURVEY_COOKIE_NAME)),
      workItemHierarchy: RESPONSE[this.licensePlan],
    };
  },
  computed: {
    hasUnavailableStructure() {
      return this.workItemTypes.unavailable.length > 0;
    },
    workItemTypes() {
      return this.workItemHierarchy.reduce(
        (itemTypes, item) => {
          const skipItem = workItemTypes[item.type].isWorkItem;

          if (skipItem) {
            return itemTypes;
          }
          const key = item.available ? 'available' : 'unavailable';
          const nestedTypes = item.nestedTypes?.map((type) => workItemTypes[type]);

          itemTypes[key].push({
            ...item,
            ...workItemTypes[item.type],
            nestedTypes,
          });

          return itemTypes;
        },
        { available: [], unavailable: [] },
      );
    },
  },
  methods: {
    handleClose() {
      Cookies.set(WORK_ITEMS_SURVEY_COOKIE_NAME, 'true', { expires: 365 * 10 });
      this.bannerVisible = false;
    },
  },
};
</script>

<template>
  <div>
    <gl-banner
      v-if="bannerVisible"
      class="gl-mt-4 !gl-px-5"
      :title="s__('Hierarchy|Help us improve work items in GitLab!')"
      :button-text="s__('Hierarchy|Take the work items survey')"
      button-link="https://forms.gle/u1BmRp8rTbwj52iq5"
      :svg-path="illustrationPath"
      @close="handleClose"
    >
      <p>
        {{
          s__(
            'Hierarchy|Is there a framework or type of work item you wish you had access to in GitLab? Give us your feedback and help us build the experiences valuable to you.',
          )
        }}
      </p>
    </gl-banner>
    <h3 class="!gl-mt-5">{{ s__('Hierarchy|Planning hierarchy') }}</h3>
    <p>
      {{
        s__(
          'Hierarchy|Deliver value more efficiently by breaking down necessary work into a hierarchical structure. This structure helps teams understand scope, priorities, and how work cascades up toward larger goals.',
        )
      }}
    </p>

    <div class="gl-mb-2 gl-font-bold">{{ s__('Hierarchy|Current structure') }}</div>
    <p class="!gl-mb-3">{{ s__('Hierarchy|You can start using these items now.') }}</p>
    <hierarchy :work-item-types="workItemTypes.available" />

    <div
      v-if="hasUnavailableStructure"
      data-testid="unavailable-structure"
      class="gl-mb-2 gl-mt-5 gl-font-bold"
    >
      {{ s__('Hierarchy|Unavailable structure') }}
    </div>
    <p v-if="hasUnavailableStructure" class="!gl-mb-3">
      {{ s__('Hierarchy|These items are unavailable in the current structure.') }}
    </p>
    <hierarchy :work-item-types="workItemTypes.unavailable" />
  </div>
</template>
