<template>
  <div class="block assignee">
    <div class="title append-bottom-10">
      Assignee
      <a
        v-if="canEdit"
        class="js-sidebar-dropdown-toggle edit-link pull-right"
        href="#"
      >
        Edit
      </a>
    </div>
    <div class="value">
      <div
        v-if="hasValue"
        class="media"
      >
        <div class="align-center">
          <user-avatar-image
            :img-src="selected.avatar_url"
            :size="32"
          />
        </div>
        <div class="media-body">
          <div class="bold author">
            {{ selected.name }}
          </div>

          <div class="username">
            @{{ selected.username }}
          </div>
        </div>
      </div>
      <div v-else>
        Any assignee
      </div>
    </div>

    <div class="selectbox" style="display: none">

      <input type="hidden" name="assignee_id" v-model="board.assignee_id">

      <div class="dropdown">
        <button
          class="dropdown-menu-toggle wide js-user-search js-author-search js-save-user-data js-board-config-modal"
          :data-field-name="fieldName"
          data-current-user="true"
          data-dropdown-title="Select assignee"
          data-any-user="Any assignee"
          :data-group-id="groupId"
          :data-project-id="projectId"
          :data-selected="selected.id"
          data-toggle="dropdown"
          aria-expanded="false"
          type="button"
        >
          <span class="dropdown-toggle-text">
            Select assignee
          </span> <i aria-hidden="true" class="fa fa-chevron-down" data-hidden="true"></i>
        </button>
        <div class="dropdown-menu dropdown-select dropdown-menu-paging dropdown-menu-user dropdown-menu-selectable dropdown-menu-author">
          <div class="dropdown-input">
            <input
              autocomplete="off"
              class="dropdown-input-field" id=""
              placeholder="Search"
              type="search"
              value=""
            >
            <i aria-hidden="true" class="fa fa-search dropdown-input-search" data-hidden="true"></i>
            <i aria-hidden="true" class="fa fa-times dropdown-input-clear js-dropdown-input-clear" data-hidden="true" role="button"></i>
          </div>
          <div class="dropdown-content"></div>
          <div class="dropdown-loading">
            <i aria-hidden="true" class="fa fa-spinner fa-spin" data-hidden="true"></i>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import UsersSelect from '~/users_select';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

export default {
  props: {
    board: {
      type: Object,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    fieldName: {
      type: String,
      required: true,
    },
    groupId: {
      type: String,
      required: false,
      default: '',
    },
    projectId: {
      type: String,
      required: false,
      default: '',
    },
    selected: {
      type: Object,
      required: false,
      default: () => ({}),
    }
  },
  components: {
    UserAvatarImage,
  },
  computed: {
    hasValue() {
      return Object.keys(this.selected).length > 0 && this.selected.id;
    },
  },
  mounted() {
    new UsersSelect();
  },
};
</script>
