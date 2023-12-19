<script>
import { GlModal, GlLoadingIcon, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import getWritableForksQuery from './get_writable_forks.query.graphql';

export const i18n = {
  btnText: __('Create a new fork'),
  title: __('Fork project?'),
  message: __('You can’t edit files directly in this project.'),
  existingForksMessage: __(
    'To submit your changes in a merge request, switch to one of these forks or create a new fork.',
  ),
  newForkMessage: __('To submit your changes in a merge request, create a new fork.'),
};

export default {
  name: 'ConfirmForkModal',
  components: {
    GlModal,
    GlLoadingIcon,
    GlLink,
  },
  inject: {
    projectPath: {
      default: '',
    },
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
    modalId: {
      type: String,
      required: true,
    },
    forkPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      forks: [],
    };
  },
  apollo: {
    forks: {
      query: getWritableForksQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update({ project } = {}) {
        return project?.visibleForks?.nodes.map((node) => {
          return {
            text: node.fullPath,
            href: node.webUrl,
          };
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.forks.loading;
    },
    hasWritableForks() {
      return this.forks.length;
    },
    btnActions() {
      return {
        cancel: { text: __('Cancel') },
        primary: {
          text: this.$options.i18n.btnText,
          attributes: {
            href: this.forkPath,
            variant: 'confirm',
          },
        },
      };
    },
  },
  i18n,
};
</script>
<template>
  <gl-modal
    :visible="visible"
    :modal-id="modalId"
    :title="$options.i18n.title"
    :action-primary="btnActions.primary"
    :action-cancel="btnActions.cancel"
    @change="$emit('change', $event)"
  >
    <p>{{ $options.i18n.message }}</p>
    <gl-loading-icon v-if="isLoading" />
    <template v-else-if="hasWritableForks">
      <p>{{ $options.i18n.existingForksMessage }}</p>
      <div v-for="fork in forks" :key="fork.text">
        <gl-link :href="fork.href">{{ fork.text }}</gl-link>
      </div>
    </template>
    <p v-else>{{ $options.i18n.newForkMessage }}</p>
  </gl-modal>
</template>
