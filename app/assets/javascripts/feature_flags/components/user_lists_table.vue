<script>
import {
  GlButton,
  GlButtonGroup,
  GlModal,
  GlSprintf,
  GlTooltipDirective,
  GlModalDirective,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: { GlButton, GlButtonGroup, GlModal, GlSprintf },
  directives: { GlTooltip: GlTooltipDirective, GlModal: GlModalDirective },
  mixins: [timeagoMixin],
  props: {
    userLists: {
      type: Array,
      required: true,
    },
  },
  translations: {
    createdTimeagoLabel: s__('UserList|created %{timeago}'),
    deleteListTitle: s__('UserList|Delete %{name}?'),
    deleteListMessage: s__('User list %{name} will be removed. Are you sure?'),
    editUserListLabel: s__('FeatureFlags|Edit User List'),
  },
  modal: {
    id: 'deleteListModal',
    actionPrimary: {
      text: __('Delete user list'),
      attributes: { variant: 'danger', 'data-testid': 'modal-confirm' },
    },
  },
  data() {
    return {
      deleteUserList: null,
    };
  },
  computed: {
    deleteListName() {
      return this.deleteUserList?.name;
    },
    modalTitle() {
      return sprintf(this.$options.translations.deleteListTitle, {
        name: this.deleteListName,
      });
    },
  },
  methods: {
    createdTimeago(list) {
      return sprintf(this.$options.translations.createdTimeagoLabel, {
        timeago: this.timeFormatted(list.created_at),
      });
    },
    displayList(list) {
      return list.user_xids.replace(/,/g, ', ');
    },
    onDelete() {
      this.$emit('delete', this.deleteUserList);
    },
    confirmDeleteList(list) {
      this.deleteUserList = list;
    },
  },
};
</script>
<template>
  <div>
    <div
      v-for="list in userLists"
      :key="list.id"
      data-testid="ffUserList"
      class="gl-border-b-solid gl-border-gray-100 gl-border-b-1 gl-w-full gl-py-4 gl-display-flex gl-justify-content-space-between"
    >
      <div class="gl-display-flex gl-flex-direction-column gl-overflow-hidden gl-flex-grow-1">
        <span data-testid="ffUserListName" class="gl-font-weight-bold gl-mb-2">
          {{ list.name }}
        </span>
        <span
          v-gl-tooltip
          :title="tooltipTitle(list.created_at)"
          data-testid="ffUserListTimestamp"
          class="gl-text-gray-300 gl-mb-2"
        >
          {{ createdTimeago(list) }}
        </span>
        <span data-testid="ffUserListIds" class="gl-str-truncated">{{ displayList(list) }}</span>
      </div>

      <gl-button-group class="gl-align-self-start gl-mt-2">
        <gl-button
          :href="list.path"
          category="secondary"
          icon="pencil"
          :aria-label="$options.translations.editUserListLabel"
          data-testid="edit-user-list"
        />
        <gl-button
          v-gl-modal="$options.modal.id"
          category="secondary"
          variant="danger"
          icon="remove"
          :aria-label="$options.modal.actionPrimary.text"
          data-testid="delete-user-list"
          @click="confirmDeleteList(list)"
        />
      </gl-button-group>
    </div>
    <gl-modal
      :title="modalTitle"
      :modal-id="$options.modal.id"
      :action-primary="$options.modal.actionPrimary"
      static
      @primary="onDelete"
    >
      <gl-sprintf :message="$options.translations.deleteListMessage">
        <template #name>
          <b>{{ deleteListName }}</b>
        </template>
      </gl-sprintf>
    </gl-modal>
  </div>
</template>
