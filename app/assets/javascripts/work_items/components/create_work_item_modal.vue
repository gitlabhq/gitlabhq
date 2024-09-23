<script>
import { GlButton, GlModal, GlDisclosureDropdownItem } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { setNewWorkItemCache } from '~/work_items/graphql/cache_utils';
import { isWorkItemItemValidEnum } from '~/work_items/utils';
import {
  I18N_NEW_WORK_ITEM_BUTTON_LABEL,
  I18N_WORK_ITEM_CREATED,
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_FETCHING_TYPES,
} from '../constants';
import namespaceWorkItemTypesQuery from '../graphql/namespace_work_item_types.query.graphql';
import CreateWorkItem from './create_work_item.vue';

export default {
  components: {
    CreateWorkItem,
    GlButton,
    GlModal,
    GlDisclosureDropdownItem,
  },
  inject: ['fullPath'],
  props: {
    description: {
      type: String,
      required: false,
      default: '',
    },
    hideButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    parentId: {
      type: String,
      required: false,
      default: '',
    },
    showProjectSelector: {
      type: Boolean,
      required: false,
      default: false,
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemTypeName: {
      type: String,
      required: false,
      default: null,
    },
    asDropdownItem: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isVisible: false,
      workItemTypes: [],
    };
  },
  apollo: {
    workItemTypes: {
      query() {
        return namespaceWorkItemTypesQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          name: this.workItemTypeName,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes ?? [];
      },
      async result() {
        if (!this.workItemTypes || this.workItemTypes.length === 0) {
          return;
        }

        // We need a valid enum of fetching workItemTypes which otherwise causes issues in cache
        if (!isWorkItemItemValidEnum(this.workItemTypeName)) {
          return;
        }
        await setNewWorkItemCache(
          this.fullPath,
          this.workItemTypes[0]?.widgetDefinitions,
          this.workItemTypeName,
          this.workItemTypes[0]?.id,
        );
      },
      error() {
        this.error = I18N_WORK_ITEM_ERROR_FETCHING_TYPES;
      },
    },
  },
  computed: {
    newWorkItemText() {
      return sprintfWorkItem(I18N_NEW_WORK_ITEM_BUTTON_LABEL, this.workItemTypeName);
    },
    workItemCreatedText() {
      return sprintfWorkItem(I18N_WORK_ITEM_CREATED, this.workItemTypeName);
    },
    dropdownItem() {
      return {
        text: this.newWorkItemText,
        action: this.showModal,
      };
    },
  },
  watch: {
    visible: {
      immediate: true,
      handler(visible) {
        this.isVisible = visible;
      },
    },
  },
  methods: {
    hideModal() {
      this.$emit('hideModal');
      this.isVisible = false;
      if (this.workItemTypes && this.workItemTypes[0]) {
        setNewWorkItemCache(
          this.fullPath,
          this.workItemTypes[0]?.widgetDefinitions,
          this.workItemTypeName,
          this.workItemTypes[0]?.id,
        );
      }
    },
    showModal() {
      this.isVisible = true;
    },
    handleCreated(workItem) {
      this.$toast.show(this.workItemCreatedText, {
        action: {
          text: __('View details'),
          onClick: () => {
            if (
              this.$router &&
              this.$router.options.routes.some((route) => route.name === 'workItem')
            ) {
              this.$router.push({ name: 'workItem', params: { iid: workItem.iid } });
            } else {
              visitUrl(workItem.webUrl);
            }
          },
        },
      });
      this.$emit('workItemCreated', workItem);
      this.hideModal();
    },
  },
};
</script>

<template>
  <div>
    <template v-if="!hideButton">
      <gl-disclosure-dropdown-item v-if="asDropdownItem" :item="dropdownItem" />
      <gl-button
        v-else
        category="primary"
        variant="confirm"
        data-testid="new-epic-button"
        @click="showModal"
        >{{ newWorkItemText }}
      </gl-button>
    </template>
    <gl-modal
      modal-id="create-work-item-modal"
      :visible="isVisible"
      :title="newWorkItemText"
      size="lg"
      hide-footer
      no-focus-on-show
      @hide="hideModal"
    >
      <create-work-item
        :description="description"
        hide-form-title
        :is-group="isGroup"
        :parent-id="parentId"
        :show-project-selector="showProjectSelector"
        :title="title"
        :work-item-type-name="workItemTypeName"
        @cancel="hideModal"
        @workItemCreated="handleCreated"
      />
    </gl-modal>
  </div>
</template>
