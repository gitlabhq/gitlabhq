<script>
import { GlModal } from '@gitlab/ui';
import { sprintf } from '@gitlab/ui/src/utils/i18n';
import { uniqueId } from 'lodash';
import { renderLeaveSuccessToast } from '~/vue_shared/components/projects_list/utils';
import { createAlert } from '~/alert';
import { s__, __ } from '~/locale';
import { deleteProjectMember } from '~/api/projects_api';

export default {
  name: 'ProjectsListItemLeaveModal',
  components: {
    GlModal,
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
    project: {
      type: Object,
      required: true,
    },
  },
  emits: ['success', 'change'],
  data() {
    return {
      modalId: uniqueId('projects-list-item-leave-modal-'),
      isLoading: false,
    };
  },
  modal: {
    actionCancel: { text: __('Cancel') },
  },
  computed: {
    title() {
      return sprintf(s__('Projects|Are you sure you want to leave "%{nameWithNamespace}"?'), {
        nameWithNamespace: this.project.nameWithNamespace,
      });
    },
    actionPrimary() {
      return {
        text: s__('Projects|Leave project'),
        attributes: {
          variant: 'danger',
          loading: this.isLoading,
        },
      };
    },
  },
  methods: {
    async handlePrimary() {
      this.isLoading = true;

      try {
        await deleteProjectMember(this.project.id, gon.current_user_id);
        this.$emit('success');
        renderLeaveSuccessToast(this.project);
      } catch (error) {
        createAlert({
          message: s__(
            'Projects|An error occurred while leaving the project. Please refresh the page to try again.',
          ),
          error,
          captureError: true,
        });
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <gl-modal
    v-bind="$options.modal"
    :modal-id="modalId"
    :visible="visible"
    :title="title"
    :action-primary="actionPrimary"
    @primary.prevent="handlePrimary"
    @change="$emit('change')"
  >
    <p>{{ s__('Projects|When you leave this project:') }}</p>
    <ul>
      <li>
        {{ s__('Projects|You are no longer a project member and cannot contribute.') }}
      </li>
      <li>
        {{
          s__(
            'Projects|All the issues and merge requests that were assigned to you are unassigned.',
          )
        }}
      </li>
    </ul>
  </gl-modal>
</template>
