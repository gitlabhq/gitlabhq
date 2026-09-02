<script>
import { GlButton, GlModal, GlSprintf } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { createAlert } from '~/alert';
import { DEFAULT_ORGANIZATION_GID } from '~/organizations/shared/constants';
import { isDefaultOrganization } from '~/organizations/shared/utils';
import axios from '~/lib/utils/axios_utils';
import { createOrganizationFromGroupPath } from '~/lib/utils/path_helpers/group';
import { rootPath } from '~/lib/utils/path_helpers/routes';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ORGANIZATION } from '~/graphql_shared/constants';
import groupsQuery from '../graphql/queries/groups.query.graphql';
import transferGroupsAndConfirmOrganizationMutation from '../graphql/mutations/transfer_groups_and_confirm_organization.mutation.graphql';
import { NEW_ORGANIZATION_GID } from '../constants';
import SkeletonLoader from './skeleton_loader.vue';
import Step1 from './steps/step_1.vue';
import Step2 from './steps/step_2.vue';
import Step3 from './steps/step_3.vue';

export default {
  name: 'OrganizationReconciliationModal',
  i18n: {
    stepProgress: s__('Organization|Step %{currentStep} / %{totalSteps}'),
    errorMessage: s__('Organization|An error occurred fetching organizations. Please try again.'),
  },
  alertContainerSelector: 'js-organization-reconciliation-modal-alert-container',
  components: {
    GlButton,
    GlModal,
    GlSprintf,
    SkeletonLoader,
  },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
    groupFullPath: {
      type: String,
      required: true,
    },
    groupGid: {
      type: String,
      required: true,
    },
    groupOrganization: {
      type: Object,
      required: true,
    },
  },
  emits: ['change'],
  data() {
    return {
      currentStep: 1,
      organizations: [],
      initialDefaultOrgGroupIds: [],
      nextButtonLoading: false,
      createdOrganization: null,
    };
  },
  apollo: {
    organizations: {
      query: groupsQuery,
      variables() {
        return {
          defaultOrganizationGid: DEFAULT_ORGANIZATION_GID,
          groupFullPath: this.groupFullPath,
          groupGid: this.groupGid,
        };
      },
      skip() {
        return !this.visible || this.organizations.length > 0;
      },
      update(data) {
        const { group, defaultOrganization } = data;

        this.setInitialDefaultOrgGroups(defaultOrganization.groups.nodes);

        const groups = {
          nodes: [group],
        };
        // This is the format the new organization will be in when created using
        // API that calls app/services/organizations/create_from_group_service.rb:47.
        const organization = this.shouldCreateNewOrganization
          ? {
              id: NEW_ORGANIZATION_GID,
              name: group.fullName,
              path: group.path,
              visibility: group.visibility,
              avatarUrl: null,
              groups,
            }
          : {
              ...this.groupOrganization,
              groups,
            };

        return [organization, defaultOrganization];
      },
      error(error) {
        createAlert({
          message: this.$options.i18n.errorMessage,
          error,
          captureError: true,
          containerSelector: `.${this.$options.alertContainerSelector}`,
        });
      },
    },
  },
  computed: {
    computedGroupOrganization() {
      return this.createdOrganization || this.groupOrganization;
    },
    shouldCreateNewOrganization() {
      // If the current group is in the Default organization we need to create a new organization for the group.
      // The creation of the new organization will be done when user clicks `Confirm` in step 3.
      // If it is not in the default organization it has already been backfilled and we can proceed without
      // creating a new organization.
      return isDefaultOrganization(this.computedGroupOrganization);
    },
    organization() {
      return this.organizations[0];
    },
    movedGroups() {
      return this.organization.groups.nodes.filter((group) => group.id !== this.groupGid);
    },
    loading() {
      return this.$apollo.queries.organizations.loading;
    },
    stepComponent() {
      return this.stepComponents[this.currentStep - 1];
    },
    totalSteps() {
      return this.stepComponents.length;
    },
    isFirstStep() {
      return this.currentStep === 1;
    },
    isLastStep() {
      return this.currentStep === this.totalSteps;
    },
    prevButtonText() {
      return this.isFirstStep ? __('Cancel') : __('Back');
    },
    nextButtonText() {
      return this.isLastStep ? __('Confirm') : __('Continue');
    },
    stepComponents() {
      if (!this.initialDefaultOrgGroupIds.length) {
        return [Step1, Step3];
      }

      return [Step1, Step2, Step3];
    },
  },
  methods: {
    setInitialDefaultOrgGroups(defaultOrgGroups) {
      this.initialDefaultOrgGroupIds = defaultOrgGroups.map((group) => group.id);
    },
    updateModalVisibility(value) {
      this.$emit('change', value);
    },
    async createNewOrganizationIfNeeded() {
      if (!this.shouldCreateNewOrganization) {
        return Promise.resolve(this.computedGroupOrganization.id);
      }

      try {
        const { data: organization } = await axios.post(
          createOrganizationFromGroupPath(this.groupFullPath),
        );

        const id = convertToGraphQLId(TYPE_ORGANIZATION, organization.id);

        this.createdOrganization = {
          id,
          name: organization.name,
          path: organization.path,
          visibility: organization.visibility,
          avatarUrl: organization.avatar_url,
        };

        return id;
      } catch (error) {
        createAlert({
          message: s__(
            'Organization|An error occurred creating your organization. Please try again.',
          ),
          error,
          captureError: true,
          containerSelector: `.${this.$options.alertContainerSelector}`,
        });

        return null;
      }
    },
    async transferGroupsAndConfirmOrganization(organizationId) {
      try {
        const {
          data: {
            organizationConfirm: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: transferGroupsAndConfirmOrganizationMutation,
          variables: {
            organizationId,
            groupIds: this.movedGroups.map((group) => group.id),
          },
        });

        if (errors.length) {
          throw new Error(errors.join(', '));
        }

        return true;
      } catch (error) {
        createAlert({
          message: s__(
            'Organization|An error occurred transferring groups into your organization. Please try again.',
          ),
          error,
          captureError: true,
          containerSelector: `.${this.$options.alertContainerSelector}`,
        });

        return false;
      }
    },
    async onNext() {
      if (!this.isLastStep) {
        this.currentStep += 1;

        return;
      }

      this.nextButtonLoading = true;
      const organizationId = await this.createNewOrganizationIfNeeded();

      if (organizationId === null) {
        this.nextButtonLoading = false;
        return;
      }

      const isSuccessful = await this.transferGroupsAndConfirmOrganization(organizationId);

      if (!isSuccessful) {
        this.nextButtonLoading = false;

        return;
      }

      visitUrlWithAlerts(rootPath(), [
        {
          id: 'organization-successfully-created-from-group-settings',
          message: s__(
            'Organization|Groups, projects, and users are being transferred into your organization. You will receive an email when your organization is ready.',
          ),
          variant: 'success',
        },
      ]);
    },
    onPrev() {
      if (this.isFirstStep) {
        this.updateModalVisibility(false);
      } else {
        this.currentStep -= 1;
      }
    },
    onUpdate(updatedOrganizations) {
      this.organizations = updatedOrganizations;
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="organization-reconciliation-modal"
    scrollable
    :visible="visible"
    :hide-footer="loading"
    @change="updateModalVisibility($event)"
  >
    <div class="gl-mb-5 empty:gl-mb-0" :class="$options.alertContainerSelector"></div>
    <skeleton-loader v-if="loading" />
    <template v-if="!loading && organization">
      <div class="gl-text-center gl-font-bold">
        <gl-sprintf :message="$options.i18n.stepProgress">
          <template #currentStep>{{ currentStep }}</template>
          <template #totalSteps>{{ totalSteps }}</template>
        </gl-sprintf>
      </div>
      <component
        :is="stepComponent"
        :organizations="organizations"
        :organization="organization"
        :initial-default-org-group-ids="initialDefaultOrgGroupIds"
        @update="onUpdate"
      />
    </template>
    <template #modal-footer>
      <div class="gl-flex gl-w-full gl-justify-center gl-gap-3">
        <gl-button @click="onPrev">{{ prevButtonText }}</gl-button>
        <gl-button variant="confirm" :loading="nextButtonLoading" @click="onNext">{{
          nextButtonText
        }}</gl-button>
      </div>
    </template>
  </gl-modal>
</template>
