<script>
import { GlAlert, GlFormCheckbox, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import GetKeepLatestArtifactProjectSetting from './graphql/queries/get_keep_latest_artifact_project_setting.query.graphql';
import UpdateKeepLatestArtifactProjectSetting from './graphql/mutations/update_keep_latest_artifact_project_setting.mutation.graphql';

const FETCH_ERROR = __('There was a problem fetching the keep latest artifact setting.');
const UPDATE_ERROR = __('There was a problem updating the keep latest artifact setting.');

export default {
  components: {
    GlAlert,
    GlFormCheckbox,
    GlLink,
  },
  inject: {
    fullPath: {
      default: '',
    },
    helpPagePath: {
      default: '',
    },
  },
  apollo: {
    keepLatestArtifact: {
      query: GetKeepLatestArtifactProjectSetting,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.project?.ciCdSettings?.keepLatestArtifact;
      },
      error() {
        this.reportError(FETCH_ERROR);
      },
    },
  },
  data() {
    return {
      keepLatestArtifact: true,
      errorMessage: '',
      isAlertDismissed: false,
    };
  },
  computed: {
    shouldShowAlert() {
      return this.errorMessage && !this.isAlertDismissed;
    },
  },
  methods: {
    reportError(error) {
      this.errorMessage = error;
      this.isAlertDismissed = false;
    },
    async updateSetting(checked) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: UpdateKeepLatestArtifactProjectSetting,
          variables: {
            fullPath: this.fullPath,
            keepLatestArtifact: checked,
          },
        });

        if (data.ciCdSettingsUpdate.errors.length) {
          this.reportError(UPDATE_ERROR);
        }
      } catch (error) {
        this.reportError(UPDATE_ERROR);
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="shouldShowAlert"
      class="gl-mb-5"
      variant="danger"
      @dismiss="isAlertDismissed = true"
      >{{ errorMessage }}</gl-alert
    >
    <gl-form-checkbox v-model="keepLatestArtifact" @change="updateSetting"
      ><b class="gl-mr-3">{{ __('Keep artifacts from most recent successful jobs') }}</b>
      <gl-link :href="helpPagePath">{{ __('More information') }}</gl-link></gl-form-checkbox
    >
    <p>
      {{
        __(
          'The latest artifacts created by jobs in the most recent successful pipeline will be stored.',
        )
      }}
    </p>
  </div>
</template>
