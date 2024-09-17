<script>
import { uniqueId } from 'lodash';
import { GlDisclosureDropdown, GlTooltip, GlModal, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export default {
  components: {
    GlDisclosureDropdown,
    GlTooltip,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: ['deleteMutation'],
  props: {
    template: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isDeleting: false,
      modalId: uniqueId('delete-comment-template-'),
      toggleId: uniqueId('actions-toggle-'),
    };
  },
  computed: {
    id() {
      return getIdFromGraphQLId(this.template.id);
    },
    dropdownItems() {
      return [
        {
          text: __('Edit'),
          action: () => this.$router.push({ name: 'edit', params: { id: this.id } }),
          extraAttrs: {
            'data-testid': 'comment-template-edit-btn',
          },
        },
        {
          text: __('Delete'),
          action: () => this.$refs['delete-modal'].show(),
          extraAttrs: {
            'data-testid': 'comment-template-delete-btn',
            class: '!gl-text-red-500',
          },
        },
      ];
    },
  },
  methods: {
    onDelete() {
      this.isDeleting = true;

      this.$apollo.mutate({
        mutation: this.deleteMutation,
        variables: {
          id: this.template.id,
        },
        update: (cache) => {
          const cacheId = cache.identify(this.template);
          cache.evict({ id: cacheId });
        },
      });
    },
  },
  actionPrimary: { text: __('Delete'), attributes: { variant: 'danger' } },
  actionSecondary: { text: __('Cancel'), attributes: { variant: 'default' } },
};
</script>

<template>
  <li>
    <div class="gl-flex">
      <h6 class="gl-my-0 gl-mr-3" data-testid="comment-template-name">{{ template.name }}</h6>
      <div class="gl-ml-auto">
        <gl-disclosure-dropdown
          :items="dropdownItems"
          :toggle-id="toggleId"
          icon="ellipsis_v"
          no-caret
          text-sr-only
          placement="bottom-end"
          :toggle-text="__('Comment template actions')"
          :loading="isDeleting"
          category="tertiary"
        />
        <gl-tooltip :target="toggleId">
          {{ __('Comment template actions') }}
        </gl-tooltip>
      </div>
    </div>
    <div class="-gl-mt-6 gl-line-clamp-6 gl-whitespace-pre-line gl-text-sm gl-font-monospace">
      {{ template.content }}
    </div>
    <gl-modal
      ref="delete-modal"
      :title="__('Delete comment template')"
      :action-primary="$options.actionPrimary"
      :action-secondary="$options.actionSecondary"
      :modal-id="modalId"
      size="sm"
      @primary="onDelete"
    >
      <gl-sprintf
        :message="__('Are you sure you want to delete %{name}? This action cannot be undone.')"
      >
        <template #name
          ><strong>{{ template.name }}</strong></template
        >
      </gl-sprintf>
    </gl-modal>
  </li>
</template>
