<script>
import { mapActions, mapGetters } from 'vuex';
import { GlDropdownItem, GlDropdownDivider, GlAvatarLabeled, GlAvatarLink } from '@gitlab/ui';
import { __, n__ } from '~/locale';
import IssuableAssignees from '~/sidebar/components/assignees/issuable_assignees.vue';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import MultiSelectDropdown from '~/vue_shared/components/sidebar/multiselect_dropdown.vue';
import getIssueParticipants from '~/vue_shared/components/sidebar/queries/getIssueParticipants.query.graphql';

export default {
  i18n: {
    unassigned: __('Unassigned'),
    assignee: __('Assignee'),
    assignees: __('Assignees'),
    assignTo: __('Assign to'),
  },
  components: {
    BoardEditableItem,
    IssuableAssignees,
    MultiSelectDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlAvatarLabeled,
    GlAvatarLink,
  },
  data() {
    return {
      participants: [],
      selected: this.$store.getters.activeIssue.assignees,
    };
  },
  apollo: {
    participants: {
      query: getIssueParticipants,
      variables() {
        return {
          id: `gid://gitlab/Issue/${this.activeIssue.iid}`,
        };
      },
      update(data) {
        return data.issue?.participants?.nodes || [];
      },
    },
  },
  computed: {
    ...mapGetters(['activeIssue']),
    assigneeText() {
      return n__('Assignee', '%d Assignees', this.selected.length);
    },
    unSelectedFiltered() {
      return this.participants.filter(({ username }) => {
        return !this.selectedUserNames.includes(username);
      });
    },
    selectedIsEmpty() {
      return this.selected.length === 0;
    },
    selectedUserNames() {
      return this.selected.map(({ username }) => username);
    },
  },
  methods: {
    ...mapActions(['setAssignees']),
    clearSelected() {
      this.selected = [];
    },
    selectAssignee(name) {
      if (name === undefined) {
        this.clearSelected();
        return;
      }

      this.selected = this.selected.concat(name);
    },
    unselect(name) {
      this.selected = this.selected.filter(user => user.username !== name);
    },
    saveAssignees() {
      this.setAssignees(this.selectedUserNames);
    },
    isChecked(id) {
      return this.selectedUserNames.includes(id);
    },
  },
};
</script>

<template>
  <board-editable-item :title="assigneeText" @close="saveAssignees">
    <template #collapsed>
      <issuable-assignees :users="activeIssue.assignees" />
    </template>

    <template #default>
      <multi-select-dropdown
        class="w-100"
        :text="$options.i18n.assignees"
        :header-text="$options.i18n.assignTo"
      >
        <template #items>
          <gl-dropdown-item
            :is-checked="selectedIsEmpty"
            data-testid="unassign"
            class="mt-2"
            @click="selectAssignee()"
            >{{ $options.i18n.unassigned }}</gl-dropdown-item
          >
          <gl-dropdown-divider data-testid="unassign-divider" />
          <gl-dropdown-item
            v-for="item in selected"
            :key="item.id"
            :is-checked="isChecked(item.username)"
            @click="unselect(item.username)"
          >
            <gl-avatar-link>
              <gl-avatar-labeled
                :size="32"
                :label="item.name"
                :sub-label="item.username"
                :src="item.avatarUrl || item.avatar"
              />
            </gl-avatar-link>
          </gl-dropdown-item>
          <gl-dropdown-divider v-if="!selectedIsEmpty" data-testid="selected-user-divider" />
          <gl-dropdown-item
            v-for="unselectedUser in unSelectedFiltered"
            :key="unselectedUser.id"
            :data-testid="`item_${unselectedUser.name}`"
            @click="selectAssignee(unselectedUser)"
          >
            <gl-avatar-link>
              <gl-avatar-labeled
                :size="32"
                :label="unselectedUser.name"
                :sub-label="unselectedUser.username"
                :src="unselectedUser.avatarUrl || unselectedUser.avatar"
              />
            </gl-avatar-link>
          </gl-dropdown-item>
        </template>
      </multi-select-dropdown>
    </template>
  </board-editable-item>
</template>
