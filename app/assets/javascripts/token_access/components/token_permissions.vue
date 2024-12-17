<script>
import { GlButton, GlFormCheckbox, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import updateCiJobTokenPermissionsMutation from '../graphql/mutations/update_ci_job_token_permissions.mutation.graphql';
import getCiJobTokenPermissionsQuery from '../graphql/queries/get_ci_job_token_permissions.query.graphql';

export default {
  name: 'TokenPermissions',
  components: {
    GlButton,
    GlFormCheckbox,
    GlLink,
    GlLoadingIcon,
    CrudComponent,
    HelpIcon,
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
      ciCdSettings: null,
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
    anchor: 'allow-git-push-requests-to-your-project-repository',
  }),
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isPermissionsQueryLoading" size="md" class="gl-mt-5" />
    <crud-component v-else :title="s__('CICD|Additional permissions')">
      <template #description>
        {{ s__("CICD|Grant additional access permissions to this project's CI/CD job tokens.") }}
      </template>

      <gl-form-checkbox :checked="allowPushToRepo" @input="updateAllowPushToRepo">
        {{ s__('CICD|Allow Git push requests to the repository') }}
        <p class="gl-mb-3 gl-text-subtle">
          {{
            s__(
              'CICD|CI/CD job token can be used to authenticate a Git push to this repository, using the permissions of the user that started the job.',
            )
          }}<gl-link :href="$options.docsLink" target="_blank">
            <help-icon class="gl-ml-2" />
          </gl-link>
        </p>
      </gl-form-checkbox>

      <gl-button variant="confirm" :loading="isUpdating" @click="updateCiJobTokenPermissions"
        >{{ __('Save Changes') }}
      </gl-button>
    </crud-component>
  </div>
</template>
