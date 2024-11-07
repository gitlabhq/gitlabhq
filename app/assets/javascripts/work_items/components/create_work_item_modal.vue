<script>
import { GlButton, GlModal, GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { setNewWorkItemCache } from '~/work_items/graphql/cache_utils';
import { isMetaClick } from '~/lib/utils/common_utils';
import { isWorkItemItemValidEnum, newWorkItemPath } from '~/work_items/utils';
import {
  I18N_NEW_WORK_ITEM_BUTTON_LABEL,
  I18N_WORK_ITEM_CREATED,
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_FETCHING_TYPES,
  ROUTES,
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
  directives: {
    GlTooltip: GlTooltipDirective,
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
    relatedItem: {
      type: Object,
      required: false,
      validator: (i) => i.id && i.type && i.reference,
      default: null,
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
          this.workItemTypes[0]?.iconName,
        );
      },
      error() {
        this.error = I18N_WORK_ITEM_ERROR_FETCHING_TYPES;
      },
    },
  },
  computed: {
    useVueRouter() {
      return (
        !this.asDropdownItem &&
        this.$router &&
        this.$router.options.routes.some((route) => route.name === 'workItem')
      );
    },
    newWorkItemPath() {
      return newWorkItemPath({
        fullPath: this.fullPath,
        isGroup: this.isGroup,
        workItemTypeName: this.workItemTypeName,
      });
    },
    newWorkItemText() {
      return sprintfWorkItem(I18N_NEW_WORK_ITEM_BUTTON_LABEL, this.workItemTypeName);
    },
    workItemCreatedText() {
      return sprintfWorkItem(I18N_WORK_ITEM_CREATED, this.workItemTypeName);
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
    },
    showModal(event) {
      if (isMetaClick(event)) {
        // opening in a new tab
        return;
      }

      // don't follow the link for normal clicks - open in modal
      event.preventDefault();

      this.isVisible = true;
    },
    handleCreated(workItem) {
      this.$toast.show(this.workItemCreatedText, {
        autoHideDelay: 10000,
        action: {
          text: __('View details'),
          onClick: () => {
            if (this.useVueRouter) {
              this.$router.push({ name: 'workItem', params: { iid: workItem.iid } });
            } else {
              visitUrl(workItem.webUrl);
            }
          },
        },
      });
      this.$emit('workItemCreated', workItem);
      if (this.workItemTypes && this.workItemTypes[0]) {
        setNewWorkItemCache(
          this.fullPath,
          this.workItemTypes[0]?.widgetDefinitions,
          this.workItemTypeName,
          this.workItemTypes[0]?.id,
          this.workItemTypes[0]?.iconName,
        );
      }
      this.hideModal();
    },
    redirectToNewPage(event) {
      if (isMetaClick(event)) {
        // opening in a new tab
        return;
      }

      event.preventDefault();

      if (this.useVueRouter) {
        this.$router.push({ name: ROUTES.new });
      } else {
        visitUrl(this.newWorkItemPath);
      }
    },
  },
};
</script>

<template>
  <div>
    <template v-if="!hideButton">
      <!-- overriding default slow because using item.action doesn't pass the click event, so can't prevent href nav -->
      <gl-disclosure-dropdown-item v-if="asDropdownItem">
        <!-- using an a instead of gl-link to prevent unwanted underline style when active -->
        <template #default
          ><a class="gl-new-dropdown-item-content" :href="newWorkItemPath" @click="showModal"
            ><span class="gl-new-dropdown-item-text-wrapper">{{ newWorkItemText }}</span></a
          ></template
        >
      </gl-disclosure-dropdown-item>
      <gl-button
        v-else
        category="primary"
        variant="confirm"
        data-testid="new-epic-button"
        :href="newWorkItemPath"
        @click="showModal"
        >{{ newWorkItemText }}
      </gl-button>
    </template>
    <gl-modal
      modal-id="create-work-item-modal"
      modal-class="create-work-item-modal"
      :visible="isVisible"
      size="lg"
      hide-footer
      @hide="hideModal"
    >
      <template #modal-header>
        <div class="gl-text gl-flex gl-w-full gl-items-center gl-gap-x-2">
          <h2 class="modal-title">{{ newWorkItemText }}</h2>
          <gl-button
            v-gl-tooltip
            data-testid="new-work-item-modal-link"
            :href="newWorkItemPath"
            :title="__('Open in full page')"
            category="tertiary"
            class="gl-text-secondary"
            icon="maximize"
            size="small"
            :aria-label="__('Open in full page')"
            @click="redirectToNewPage"
          />
        </div>
      </template>
      <create-work-item
        :description="description"
        hide-form-title
        :is-group="isGroup"
        :parent-id="parentId"
        :show-project-selector="showProjectSelector"
        :title="title"
        :work-item-type-name="workItemTypeName"
        :related-item="relatedItem"
        @cancel="hideModal"
        @workItemCreated="handleCreated"
      />
    </gl-modal>
  </div>
</template>
