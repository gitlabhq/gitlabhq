<script>
import { GlDeprecatedSkeletonLoading as GlSkeletonLoading, GlSprintf } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import Poll from '~/lib/utils/poll';
import { n__ } from '~/locale';
import MrWidgetExpanableSection from '../mr_widget_expandable_section.vue';
import TerraformPlan from './terraform_plan.vue';

export default {
  name: 'MRWidgetTerraformContainer',
  components: {
    GlSkeletonLoading,
    GlSprintf,
    MrWidgetExpanableSection,
    TerraformPlan,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: true,
      plansObject: {},
      poll: null,
    };
  },
  computed: {
    inValidPlanCountText() {
      if (this.numberOfInvalidPlans === 0) {
        return null;
      }

      return n__(
        'Terraform|%{number} Terraform report failed to generate',
        'Terraform|%{number} Terraform reports failed to generate',
        this.numberOfInvalidPlans,
      );
    },
    numberOfInvalidPlans() {
      return Object.values(this.plansObject).filter((plan) => plan.tf_report_error).length;
    },
    numberOfPlans() {
      return Object.keys(this.plansObject).length;
    },
    numberOfValidPlans() {
      return this.numberOfPlans - this.numberOfInvalidPlans;
    },
    validPlanCountText() {
      if (this.numberOfValidPlans === 0) {
        return null;
      }

      return n__(
        'Terraform|%{number} Terraform report was generated in your pipelines',
        'Terraform|%{number} Terraform reports were generated in your pipelines',
        this.numberOfValidPlans,
      );
    },
  },
  created() {
    this.fetchPlans();
  },
  beforeDestroy() {
    this.poll.stop();
  },
  methods: {
    fetchPlans() {
      this.loading = true;

      this.poll = new Poll({
        resource: {
          fetchPlans: () => axios.get(this.endpoint),
        },
        data: this.endpoint,
        method: 'fetchPlans',
        successCallback: ({ data }) => {
          this.plansObject = data;

          if (this.numberOfPlans > 0) {
            this.loading = false;
            this.poll.stop();
          }
        },
        errorCallback: () => {
          this.plansObject = { bad_plan: { tf_report_error: 'api_error' } };
          this.loading = false;
          this.poll.stop();
        },
      });

      this.poll.makeRequest();
    },
  },
};
</script>

<template>
  <section class="mr-widget-section">
    <div v-if="loading" class="mr-widget-body">
      <gl-skeleton-loading />
    </div>

    <mr-widget-expanable-section v-else>
      <template #header>
        <div
          data-testid="terraform-header-text"
          class="gl-flex-grow-1 gl-display-flex gl-flex-direction-column"
        >
          <p v-if="validPlanCountText" class="gl-m-0">
            <gl-sprintf :message="validPlanCountText">
              <template #number>
                <strong>{{ numberOfValidPlans }}</strong>
              </template>
            </gl-sprintf>
          </p>

          <p v-if="inValidPlanCountText" class="gl-m-0">
            <gl-sprintf :message="inValidPlanCountText">
              <template #number>
                <strong>{{ numberOfInvalidPlans }}</strong>
              </template>
            </gl-sprintf>
          </p>
        </div>
      </template>

      <template #content>
        <div class="mr-widget-body gl-pb-1">
          <terraform-plan v-for="(plan, key) in plansObject" :key="key" :plan="plan" />
        </div>
      </template>
    </mr-widget-expanable-section>
  </section>
</template>
