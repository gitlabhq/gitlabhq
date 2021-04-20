<script>
import {
  GlAlert,
  GlButton,
  GlEmptyState,
  GlLoadingIcon,
  GlModalDirective as GlModal,
} from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { s__, __ } from '~/locale';
import { states, ADD_USER_MODAL_ID } from '../constants/show';
import AddUserModal from './add_user_modal.vue';

const commonTableClasses = ['gl-py-5', 'gl-border-b-1', 'gl-border-b-solid', 'gl-border-gray-100'];

export default {
  components: {
    GlAlert,
    GlButton,
    GlEmptyState,
    GlLoadingIcon,
    AddUserModal,
  },
  directives: {
    GlModal,
  },
  props: {
    emptyStatePath: {
      required: true,
      type: String,
    },
  },
  translations: {
    addUserButtonLabel: s__('UserLists|Add Users'),
    emptyStateTitle: s__('UserLists|There are no users'),
    emptyStateDescription: s__(
      'UserLists|Define a set of users to be used within feature flag strategies',
    ),
    userIdLabel: s__('UserLists|User IDs'),
    userIdColumnHeader: s__('UserLists|User ID'),
    errorMessage: __('Something went wrong on our end. Please try again!'),
    editButtonLabel: s__('UserLists|Edit'),
  },
  classes: {
    headerClasses: [
      'gl-display-flex',
      'gl-justify-content-space-between',
      'gl-pb-5',
      'gl-border-b-1',
      'gl-border-b-solid',
      'gl-border-gray-100',
    ].join(' '),
    tableHeaderClasses: commonTableClasses.join(' '),
    tableRowClasses: [
      ...commonTableClasses,
      'gl-display-flex',
      'gl-justify-content-space-between',
      'gl-align-items-center',
    ].join(' '),
  },
  ADD_USER_MODAL_ID,
  computed: {
    ...mapState(['userList', 'userIds', 'state']),
    name() {
      return this.userList?.name ?? '';
    },
    hasUserIds() {
      return this.userIds.length > 0;
    },
    isLoading() {
      return this.state === states.LOADING;
    },
    hasError() {
      return this.state === states.ERROR;
    },
    editPath() {
      return this.userList?.edit_path;
    },
  },
  mounted() {
    this.fetchUserList();
  },
  methods: {
    ...mapActions(['fetchUserList', 'dismissErrorAlert', 'removeUserId', 'addUserIds']),
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="hasError" variant="danger" @dismiss="dismissErrorAlert">
      {{ $options.translations.errorMessage }}
    </gl-alert>
    <gl-loading-icon v-if="isLoading" size="xl" class="gl-mt-6" />
    <div v-else>
      <add-user-modal @addUsers="addUserIds" />
      <div :class="$options.classes.headerClasses">
        <div>
          <h3>{{ name }}</h3>
          <h4 class="gl-text-gray-500">{{ $options.translations.userIdLabel }}</h4>
        </div>
        <div class="gl-mt-6">
          <gl-button v-if="editPath" :href="editPath" data-testid="edit-user-list" class="gl-mr-3">
            {{ $options.translations.editButtonLabel }}
          </gl-button>
          <gl-button
            v-gl-modal="$options.ADD_USER_MODAL_ID"
            data-testid="add-users"
            variant="success"
          >
            {{ $options.translations.addUserButtonLabel }}
          </gl-button>
        </div>
      </div>
      <div v-if="hasUserIds">
        <div :class="$options.classes.tableHeaderClasses">
          {{ $options.translations.userIdColumnHeader }}
        </div>
        <div
          v-for="id in userIds"
          :key="id"
          data-testid="user-id-row"
          :class="$options.classes.tableRowClasses"
        >
          <span data-testid="user-id">{{ id }}</span>
          <gl-button
            category="secondary"
            variant="danger"
            icon="remove"
            :aria-label="__('Remove user')"
            data-testid="delete-user-id"
            @click="removeUserId(id)"
          />
        </div>
      </div>
      <gl-empty-state
        v-else
        :title="$options.translations.emptyStateTitle"
        :description="$options.translations.emptyStateDescription"
        :svg-path="emptyStatePath"
      />
    </div>
  </div>
</template>
