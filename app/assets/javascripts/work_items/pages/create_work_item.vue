<script>
import { GlButton, GlAlert, GlLoadingIcon, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import createWorkItemMutation from '../graphql/create_work_item.mutation.graphql';
import projectWorkItemTypesQuery from '../graphql/project_work_item_types.query.graphql';

import ItemTitle from '../components/item_title.vue';

export default {
  components: {
    GlButton,
    GlAlert,
    GlLoadingIcon,
    GlDropdown,
    GlDropdownItem,
    ItemTitle,
  },
  inject: ['fullPath'],
  props: {
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialTitle: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      title: this.initialTitle,
      error: null,
      workItemTypes: [],
      selectedWorkItemType: null,
    };
  },
  apollo: {
    workItemTypes: {
      query: projectWorkItemTypesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes;
      },
      error() {
        this.error = s__(
          'WorkItem|Something went wrong when fetching work item types. Please try again',
        );
      },
    },
  },
  computed: {
    dropdownButtonText() {
      return this.selectedWorkItemType?.name || s__('WorkItem|Type');
    },
  },
  methods: {
    async createWorkItem() {
      try {
        const response = await this.$apollo.mutate({
          mutation: createWorkItemMutation,
          variables: {
            input: {
              title: this.title,
            },
          },
        });

        const {
          data: {
            localCreateWorkItem: {
              workItem: { id, type },
            },
          },
        } = response;
        if (!this.isModal) {
          this.$router.push({ name: 'workItem', params: { id } });
        } else {
          this.$emit('onCreate', { id, title: this.title, type });
        }
      } catch {
        this.error = s__(
          'WorkItem|Something went wrong when creating a work item. Please try again',
        );
      }
    },
    handleTitleInput(title) {
      this.title = title;
    },
    handleCancelClick() {
      if (!this.isModal) {
        this.$router.go(-1);
        return;
      }
      this.$emit('closeModal');
    },
    selectWorkItemType(type) {
      this.selectedWorkItemType = type;
    },
  },
};
</script>

<template>
  <form @submit.prevent="createWorkItem">
    <gl-alert v-if="error" variant="danger" @dismiss="error = null">{{ error }}</gl-alert>
    <div :class="{ 'gl-px-5': isModal }" data-testid="content">
      <item-title
        :initial-title="title"
        data-testid="title-input"
        @title-input="handleTitleInput"
      />
      <div>
        <gl-dropdown :text="dropdownButtonText">
          <gl-loading-icon
            v-if="$apollo.queries.workItemTypes.loading"
            size="md"
            data-testid="loading-types"
          />
          <template v-else>
            <gl-dropdown-item
              v-for="type in workItemTypes"
              :key="type.id"
              @click="selectWorkItemType(type)"
            >
              {{ type.name }}
            </gl-dropdown-item>
          </template>
        </gl-dropdown>
      </div>
    </div>
    <div
      class="gl-bg-gray-10 gl-py-5 gl-px-6 gl-mt-4"
      :class="{ 'gl-display-flex gl-justify-content-end': isModal }"
    >
      <gl-button
        variant="confirm"
        :disabled="title.length === 0"
        :class="{ 'gl-mr-3': !isModal }"
        data-testid="create-button"
        type="submit"
      >
        {{ s__('WorkItem|Create work item') }}
      </gl-button>
      <gl-button
        type="button"
        data-testid="cancel-button"
        class="gl-order-n1"
        :class="{ 'gl-mr-3': isModal }"
        @click="handleCancelClick"
      >
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </form>
</template>
