<script>
import {
  GlButton,
  GlButtonGroup,
  GlModal,
  GlSprintf,
  GlModalDirective,
  GlTruncateText,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'UserListsTable',
  components: { GlButton, GlButtonGroup, GlModal, GlSprintf, GlTruncateText, TimeAgo },
  directives: { GlModal: GlModalDirective },
  props: {
    userLists: {
      type: Array,
      required: true,
    },
  },
  emits: ['delete'],
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
      return sprintf(s__('UserList|Delete %{name}?'), {
        name: this.deleteListName,
      });
    },
  },
  methods: {
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
        <span data-testid="ffUserListTimestamp" class="gl-mb-2 gl-text-subtle">
          <gl-sprintf :message="s__('UserList|created %{timeago}')">
            <template #timeago>
              <time-ago :time="list.created_at" />
            </template>
          </gl-sprintf>
        </span>

        <gl-truncate-text
          :lines="2"
          :mobile-lines="2"
          :show-more-text="__('Show more')"
          :show-less-text="__('Show less')"
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
          :aria-label="s__('FeatureFlags|Edit User List')"
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
      <gl-sprintf :message="__('User list %{name} will be removed. Are you sure?')">
        <template #name>
          <b>{{ deleteListName }}</b>
        </template>
      </gl-sprintf>
    </gl-modal>
  </div>
</template>
