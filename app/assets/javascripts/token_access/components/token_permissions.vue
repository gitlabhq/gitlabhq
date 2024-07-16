<script>
import { GlButton, GlCard, GlFormCheckbox, GlIcon, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import updateCiJobTokenPermissionsMutation from '../graphql/mutations/update_ci_job_token_permissions.mutation.graphql';
import getCiJobTokenPermissionsQuery from '../graphql/queries/get_ci_job_token_permissions.query.graphql';

export default {
  name: 'TokenPermissions',
  components: {
    GlButton,
    GlCard,
    GlFormCheckbox,
    GlIcon,
    GlLink,
    GlLoadingIcon,
  },
  inject: ['fullPath'],
  apollo: {
    ciCdSettings: {
      query: getCiJobTokenPermissionsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update({ data }) {
        return data?.project?.ciCdSettings;
      },
      result({ data }) {
        this.projectName = data?.project?.name;
        this.allowPushToRepo = data?.project?.ciCdSettings?.pushRepositoryForJobTokenAllowed;
      },
      error() {
        createAlert({
          message: __('There was a problem fetching the CI/CD job token permissions.'),
        });
      },
    },
  },
  data() {
    return {
      allowPushToRepo: false,
      isUpdating: false,
      projectName: '',
    };
  },
  computed: {
    isPermissionsQueryLoading() {
      return this.$apollo.queries.ciCdSettings.loading;
    },
  },
  methods: {
    updateAllowPushToRepo(value) {
      this.allowPushToRepo = value;
    },
    async updateCiJobTokenPermissions() {
      this.isUpdating = true;

      try {
        const {
          data: {
            projectCiCdSettingsUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updateCiJobTokenPermissionsMutation,
          variables: {
            input: {
              fullPath: this.fullPath,
              pushRepositoryForJobTokenAllowed: this.allowPushToRepo,
            },
          },
        });

        if (errors.length > 0) {
          throw new Error(errors[0]);
        } else {
          const toastMessage = sprintf(
            __("CI/CD job token permissions for '%{projectName}' were successfully updated."),
            { projectName: this.projectName },
          );
          this.$toast.show(toastMessage);
        }
      } catch (error) {
        createAlert({ message: error.message });
      } finally {
        this.isUpdating = false;
      }
    },
  },
  docsLink: helpPagePath('ci/jobs/ci_job_token', {
    anchor: 'push-to-a-project-repository-using-a-job-token',
  }),
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isPermissionsQueryLoading" size="lg" class="gl-mt-5" />
    <gl-card v-else class="gl-new-card" header-class="gl-new-card-header">
      <template #header>
        <div class="gl-new-card-title-wrapper gl-flex-col gl-flex-wrap">
          <div class="gl-new-card-title">
            <h5 class="gl-mt-0 gl-mb-2">{{ s__('CICD|Additional permissions') }}</h5>
          </div>
          <p class="gl-text-secondary gl-my-0">
            {{
              s__("CICD|Grant additional access permissions to this project's CI/CD job tokens.")
            }}
          </p>
        </div>
      </template>
      <gl-form-checkbox :checked="allowPushToRepo" @input="updateAllowPushToRepo">
        {{ s__('CICD|Allow Git push requests to the repository') }}
        <p class="gl-text-secondary gl-mb-3">
          {{
            s__(
              'CICD|CI/CD job token can be used to authenticate a Git push to this repository, using the permissions of the user that started the job.',
            )
          }}<gl-link :href="$options.docsLink" target="_blank">
            <gl-icon name="question-o" class="gl-ml-2 gl-text-blue-500" />
          </gl-link>
        </p>
      </gl-form-checkbox>

      <gl-button variant="confirm" :loading="isUpdating" @click="updateCiJobTokenPermissions"
        >{{ __('Save Changes') }}
      </gl-button>
    </gl-card>
  </div>
</template>
