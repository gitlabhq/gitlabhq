<script>
import { GlButton, GlModal, GlFormGroup, GlFormInput, GlFormTextarea, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import createCustomDashboardMutation from '../graphql/create_custom_dashboard.mutation.graphql';
import { getDashboardIdFromGraphQLId } from '../utils';

export default {
  name: 'NewDashboardButton',
  components: {
    GlButton,
    GlModal,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlAlert,
  },
  data() {
    return {
      showModal: false,
      isLoading: false,
      title: '',
      description: '',
      errorMessage: '',
    };
  },
  computed: {
    modalActionPrimary() {
      return {
        text: s__('AnalyticsDashboards|Next'),
        attributes: { variant: 'confirm', loading: this.isLoading },
      };
    },
    modalActionCancel() {
      return {
        text: s__('AnalyticsDashboards|Cancel'),
        attributes: { disabled: this.isLoading },
      };
    },
  },
  methods: {
    openModal() {
      this.showModal = true;
      this.title = '';
      this.description = '';
      this.clearError();
    },
    closeModal() {
      this.showModal = false;
    },
    clearError() {
      this.errorMessage = '';
    },
    async handlePrimary() {
      this.clearError();

      if (!this.title.trim()) {
        this.errorMessage = s__('AnalyticsDashboards|Dashboard title is required.');
        return;
      }

      this.isLoading = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: createCustomDashboardMutation,
          variables: {
            input: {
              name: this.title,
              description: this.description,
              config: {
                title: this.title,
                description: this.description,
                panels: [],
              },
            },
          },
        });

        const { dashboard, errors } = data?.createCustomDashboard || {};
        if (errors?.length) {
          [this.errorMessage] = errors;
          this.isLoading = false;
          return;
        }

        const dashboardId = getDashboardIdFromGraphQLId(dashboard.id);

        visitUrl(joinPaths(this.$router.options.base, `${dashboardId}`));
      } catch (error) {
        this.errorMessage = s__(
          'AnalyticsDashboards|Failed to create dashboard. Please try again.',
        );
        this.isLoading = false;
      }
    },
  },
  buttonLabel: s__('AnalyticsDashboards|New dashboard'),
};
</script>

<template>
  <div>
    <gl-button variant="confirm" @click="openModal">
      {{ $options.buttonLabel }}
    </gl-button>
    <gl-modal
      v-model="showModal"
      modal-id="new-dashboard-modal"
      size="sm"
      :title="$options.buttonLabel"
      :action-primary="modalActionPrimary"
      :action-cancel="modalActionCancel"
      @primary.prevent="handlePrimary"
      @canceled="closeModal"
    >
      <gl-alert v-if="errorMessage" variant="danger" class="gl-mb-4" @dismiss="clearError">
        {{ errorMessage }}
      </gl-alert>
      <gl-form-group
        :label="s__('AnalyticsDashboards|Dashboard title')"
        label-for="dashboard-title"
      >
        <gl-form-input
          id="dashboard-title"
          v-model="title"
          :placeholder="s__('AnalyticsDashboards|Enter a title')"
          :disabled="isLoading"
          data-testid="dashboard-title-input"
        />
      </gl-form-group>
      <gl-form-group
        :label="s__('AnalyticsDashboards|Dashboard description')"
        label-for="dashboard-description"
      >
        <gl-form-textarea
          id="dashboard-description"
          v-model="description"
          :placeholder="s__('AnalyticsDashboards|Enter a description (optional)')"
          :disabled="isLoading"
          data-testid="dashboard-description-textarea"
        />
      </gl-form-group>
    </gl-modal>
  </div>
</template>
