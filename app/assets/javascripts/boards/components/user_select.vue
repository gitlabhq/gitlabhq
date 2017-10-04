<script>
import UsersSelect from '~/users_select';
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

export default {
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
      type: String,
      required: false,
      default: '',
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
      type: String,
      required: false,
      default: '',
    },
    selected: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    wrapperClass: {
      type: String,
      required: false,
      default: '',
    },
  },
  components: {
    loadingIcon,
    UserAvatarImage,
  },
  computed: {
    hasValue() {
      return this.selected.id;
    },
  },
  watch: {
    board: {
      handler() {
        this.$nextTick(() => {
          new UsersSelect();
        });
      },
      deep: true,
    }
  },
  mounted() {
    this.$nextTick(() => {
      new UsersSelect();
    });
  },
};
</script>

<template>
  <div
    class="block"
    :class="wrapperClass"
  >
    <div class="title append-bottom-10">
      {{ label }}
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
          class="dropdown-menu-toggle wide js-user-search js-author-search js-save-user-data js-board-config-modal"
          ref="dropdown"
          :data-field-name="fieldName"
          data-current-user="true"
          :data-dropdown-title="placeholderText"
          :data-any-user="anyUserText"
          :data-group-id="groupId"
          :data-project-id="projectId"
          :data-selected="selected.id"
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
          />
        </button>
        <div class="dropdown-menu dropdown-select dropdown-menu-paging dropdown-menu-user dropdown-menu-selectable dropdown-menu-author">
          <div class="dropdown-input">
            <input
              autocomplete="off"
              class="dropdown-input-field"
              placeholder="Search"
              type="search"
            >
            <i
              aria-hidden="true"
              class="fa fa-search dropdown-input-search"
              data-hidden="true"
            />
            <i
              aria-hidden="true"
              class="fa fa-times dropdown-input-clear js-dropdown-input-clear"
              data-hidden="true"
              role="button"
            />
          </div>
          <div class="dropdown-content"></div>
          <div class="dropdown-loading">
            <loading-icon />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
