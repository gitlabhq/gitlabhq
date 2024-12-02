<script>
import {
  GlButton,
  GlButtonGroup,
  GlModal,
  GlSprintf,
  GlTooltipDirective,
  GlModalDirective,
  GlTruncateText,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  i18n: {
    showMore: __('Show more'),
    showLess: __('Show less'),
  },
  components: { GlButton, GlButtonGroup, GlModal, GlSprintf, GlTruncateText },
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
    deleteListMessage: __('User list %{name} will be removed. Are you sure?'),
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
      class="gl-flex gl-w-full gl-justify-between gl-border-b-1 gl-border-default gl-py-4 gl-border-b-solid"
    >
      <div class="gl-flex gl-grow gl-flex-col">
        <span data-testid="ffUserListName" class="gl-mb-2 gl-font-bold">
          {{ list.name }}
        </span>
        <span
          v-gl-tooltip
          :title="tooltipTitle(list.created_at)"
          data-testid="ffUserListTimestamp"
          class="gl-mb-2 gl-text-gray-300"
        >
          {{ createdTimeago(list) }}
        </span>
        <gl-truncate-text
          :lines="2"
          :mobile-lines="2"
          :show-more-text="$options.i18n.showMore"
          :show-less-text="$options.i18n.showLess"
        >
          <div data-testid="ffUserListIds">
            {{ displayList(list) }}
          </div>
        </gl-truncate-text>
      </div>

      <gl-button-group class="gl-mt-2 gl-self-start">
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
