<script>
import { __ } from '~/locale';
import { GlIcon, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import CiIcon from '../../vue_shared/components/ci_icon.vue';
import flash from '~/flash';
import Poll from '~/lib/utils/poll';

export default {
  name: 'MRWidgetTerraformPlan',
  components: {
    CiIcon,
    GlIcon,
    GlLoadingIcon,
    GlSprintf,
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
      plans: {},
    };
  },
  computed: {
    addNum() {
      return Number(this.plan.create);
    },
    changeNum() {
      return Number(this.plan.update);
    },
    deleteNum() {
      return Number(this.plan.delete);
    },
    iconStatusObj() {
      return {
        group: 'warning',
        icon: 'status_warning',
      };
    },
    logUrl() {
      return this.plan.job_path;
    },
    plan() {
      return this.plans['tfplan.json'] || {};
    },
    validPlanValues() {
      return this.addNum + this.changeNum + this.deleteNum >= 0;
    },
  },
  created() {
    this.fetchPlans();
  },
  methods: {
    fetchPlans() {
      this.loading = true;

      const poll = new Poll({
        resource: {
          fetchPlans: () => axios.get(this.endpoint),
        },
        data: this.endpoint,
        method: 'fetchPlans',
        successCallback: ({ data }) => {
          this.plans = data;

          if (Object.keys(this.plan).length) {
            this.loading = false;
            poll.stop();
          }
        },
        errorCallback: () => {
          this.plans = {};
          this.loading = false;
          flash(__('An error occurred while loading terraform report'));
        },
      });

      poll.makeRequest();
    },
  },
};
</script>

<template>
  <section class="mr-widget-section">
    <div class="mr-widget-body media d-flex flex-row">
      <span class="append-right-default align-self-start align-self-lg-center">
        <ci-icon :status="iconStatusObj" :size="24" />
      </span>

      <div class="d-flex flex-fill flex-column flex-md-row">
        <div class="terraform-mr-plan-text normal d-flex flex-column flex-lg-row">
          <p class="m-0 pr-1">{{ __('A terraform report was generated in your pipelines.') }}</p>

          <gl-loading-icon v-if="loading" size="md" />

          <p v-else-if="validPlanValues" class="m-0">
            <gl-sprintf
              :message="
                __(
                  'Reported Resource Changes: %{addNum} to add, %{changeNum} to change, %{deleteNum} to delete',
                )
              "
            >
              <template #addNum>
                <strong>{{ addNum }}</strong>
              </template>

              <template #changeNum>
                <strong>{{ changeNum }}</strong>
              </template>

              <template #deleteNum>
                <strong>{{ deleteNum }}</strong>
              </template>
            </gl-sprintf>
          </p>

          <p v-else class="m-0">{{ __('Changes are unknown') }}</p>
        </div>

        <div class="terraform-mr-plan-actions">
          <a
            v-if="logUrl"
            :href="logUrl"
            target="_blank"
            data-track-event="click_terraform_mr_plan_button"
            data-track-label="mr_widget_terraform_mr_plan_button"
            data-track-property="terraform_mr_plan_button"
            class="btn btn-sm js-terraform-report-link"
            rel="noopener"
          >
            {{ __('View full log') }}
            <gl-icon name="external-link" />
          </a>
        </div>
      </div>
    </div>
  </section>
</template>
