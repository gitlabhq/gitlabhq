<script>
import UsersSelect from '~/users_select';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

export default {
  components: {
    UserAvatarImage,
  },
  props: {
    anyUserText: {
      type: String,
      required: false,
      default: 'Any user',
    },
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
      type: Number,
      required: false,
      default: 0,
    },
    label: {
      type: String,
      required: true,
    },
    placeholderText: {
      type: String,
      required: false,
      default: 'Select user',
    },
    projectId: {
      type: Number,
      required: false,
      default: 0,
    },
    selected: {
      type: Object,
      required: true,
    },
    wrapperClass: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    hasValue() {
      return this.selected.id > 0;
    },
    selectedId() {
      return this.selected ? this.selected.id : null;
    },
  },
  watch: {
    selected() {
      this.initSelect();
    },
  },
  mounted() {
    this.initSelect();
  },
  methods: {
    initSelect() {
      this.userDropdown = new UsersSelect(null, this.$refs.dropdown, {
        handleClick: this.selectUser,
      });
    },
    selectUser(user, isMarking) {
      let assignee = user;
      if (!isMarking) {
        // correctly select "unassigned" in Assignee dropdown
        assignee = {
          id: undefined,
        };
      }
      this.board.assignee_id = assignee.id;
      this.board.assignee = assignee;
    },
  },
};
</script>

<template>
  <div
    :class="wrapperClass"
    class="block"
  >
    <div class="title append-bottom-10">
      {{ label }}
      <button
        v-if="canEdit"
        type="button"
        class="edit-link btn btn-blank float-right"
      >
        Edit
      </button>
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
      <div
        v-else
        class="text-secondary"
      >
        {{ anyUserText }}
      </div>
    </div>

    <div
      class="selectbox"
      style="display: none"
    >
      <div class="dropdown">
        <button
          ref="dropdown"
          :data-field-name="fieldName"
          :data-dropdown-title="placeholderText"
          :data-any-user="anyUserText"
          :data-group-id="groupId"
          :data-project-id="projectId"
          :data-selected="selectedId"
          class="dropdown-menu-toggle wide"
          data-toggle="dropdown"
          aria-expanded="false"
          type="button"
        >
          <span class="dropdown-toggle-text">
            {{ placeholderText }}
          </span>
          <i
            aria-hidden="true"
            class="fa fa-chevron-down"
            data-hidden="true"
          >
          </i>
        </button>
        <div
          class="dropdown-menu dropdown-select dropdown-menu-paging
dropdown-menu-user dropdown-menu-selectable dropdown-menu-author"
        >
          <div class="dropdown-input">
            <input
              autocomplete="off"
              class="dropdown-input-field"
              placeholder="Search"
              type="search"
            />
            <i
              aria-hidden="true"
              class="fa fa-search dropdown-input-search"
              data-hidden="true"
            >
            </i>
            <i
              aria-hidden="true"
              class="fa fa-times dropdown-input-clear js-dropdown-input-clear"
              data-hidden="true"
              role="button"
            >
            </i>
          </div>
          <div class="dropdown-content"></div>
          <div class="dropdown-loading">
            <gl-loading-icon />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
