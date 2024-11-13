<script>
import { GlButton, GlIcon, GlLink, GlPopover, GlTooltipDirective } from '@gitlab/ui';
import { kebabCase, snakeCase } from 'lodash';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import { timeFor } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import {
  dropdowni18nText,
  LocalizedIssuableAttributeType,
  IssuableAttributeTypeKeyMap,
  IssuableAttributeType,
  Tracking,
} from 'ee_else_ce/sidebar/constants';
import { issuableAttributesQueries } from 'ee_else_ce/sidebar/queries/constants';
import SidebarDropdown from './sidebar_dropdown.vue';
import SidebarEditableItem from './sidebar_editable_item.vue';

export default {
  i18n: {
    expired: __('(expired)'),
    none: __('None'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlLink,
    GlIcon,
    GlPopover,
    GlButton,
    SidebarDropdown,
    SidebarEditableItem,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    isClassicSidebar: {
      default: false,
    },
    issuableAttributesQueries: {
      default: issuableAttributesQueries,
    },
    widgetTitleText: {
      default: {
        [IssuableAttributeType.Milestone]: __('Milestone'),
        expired: __('(expired)'),
        none: __('None'),
      },
    },
  },
  props: {
    issuableAttribute: {
      type: String,
      required: true,
    },
    workspacePath: {
      required: true,
      type: String,
    },
    iid: {
      required: true,
      type: String,
    },
    attrWorkspacePath: {
      required: true,
      type: String,
    },
    issuableType: {
      type: String,
      required: true,
      validator(value) {
        return [TYPE_ISSUE, TYPE_MERGE_REQUEST].includes(value);
      },
    },
    icon: {
      type: String,
      required: false,
      default: undefined,
    },
    showWorkItemEpics: {
      type: Boolean,
      required: false,
      default: false,
    },
    isEpicAttribute: {
      type: Boolean,
      required: false,
      default: false,
    },
    issuableParent: {
      type: Object,
      required: false,
      default: null,
    },
  },
  apollo: {
    issuable: {
      query() {
        const { current } = this.issuableAttributeQuery;
        const { query } = current[this.issuableType];

        return query;
      },
      variables() {
        return {
          fullPath: this.workspacePath,
          iid: this.iid,
        };
      },
      update(data) {
        return data.workspace?.issuable || {};
      },
      result({ data }) {
        if (this.glFeatures?.epicWidgetEditConfirmation && this.isEpicAttribute) {
          this.hasCurrentAttribute = data?.workspace?.issuable.hasEpic;
        }
      },
      skip() {
        return !this.iid;
      },
      error(error) {
        createAlert({
          message: this.i18n.currentFetchError,
          captureError: true,
          error,
        });
      },
      subscribeToMore: {
        document() {
          return issuableAttributesQueries[this.issuableAttribute].subscription;
        },
        variables() {
          return {
            issuableId: this.issuableId,
          };
        },
        skip() {
          return this.shouldSkipRealTimeEpicLinkUpdates;
        },
      },
    },
  },
  data() {
    return {
      updating: false,
      selectedTitle: null,
      issuable: {},
      hasCurrentAttribute: false,
      editConfirmation: false,
      tracking: {
        event: Tracking.editEvent,
        label: Tracking.rightSidebarLabel,
        property: this.issuableAttribute,
      },
    };
  },
  computed: {
    currentAttribute() {
      if (this.isEpicAttribute && this.issuableParent?.attribute) {
        return this.issuableParent.attribute;
      }
      return this.issuable.attribute;
    },
    issuableId() {
      return this.issuable.id;
    },
    issuableAttributeQuery() {
      return this.issuableAttributesQueries[this.issuableAttribute];
    },
    attributeTitle() {
      return this.currentAttribute?.title || __('None');
    },
    attributeUrl() {
      return this.currentAttribute?.webUrl;
    },
    loading() {
      return this.$apollo.queries.issuable.loading;
    },
    attributeTypeTitle() {
      return this.widgetTitleText[this.issuableAttribute];
    },
    attributeTypeIcon() {
      return this.icon || this.issuableAttribute;
    },
    tooltipText() {
      return timeFor(this.currentAttribute?.dueDate);
    },
    i18n() {
      const localizedAttribute =
        LocalizedIssuableAttributeType[IssuableAttributeTypeKeyMap[this.issuableAttribute]];
      return dropdowni18nText(localizedAttribute, this.issuableType);
    },
    formatIssuableAttribute() {
      return {
        kebab: kebabCase(this.issuableAttribute),
        snake: snakeCase(this.issuableAttribute),
      };
    },
    shouldShowConfirmationPopover() {
      if (!this.glFeatures?.epicWidgetEditConfirmation) {
        return false;
      }

      return this.isEpicAttribute && this.currentAttribute === null && this.hasCurrentAttribute
        ? !this.editConfirmation
        : false;
    },
    shouldSkipRealTimeEpicLinkUpdates() {
      return !this.issuableId || this.issuableAttribute !== IssuableAttributeType.Epic;
    },
  },
  methods: {
    updateAttribute({ id, workItemType }) {
      if (this.currentAttribute === null && id === null) return;
      if (id === this.currentAttribute?.id) return;

      if (this.showWorkItemEpics && this.isEpicAttribute) {
        this.$emit('updateAttribute', { id, workItemType });
      } else {
        this.updating = true;

        const { current } = this.issuableAttributeQuery;
        const { mutation } = current[this.issuableType];

        this.$apollo
          .mutate({
            mutation,
            variables: {
              fullPath: this.workspacePath,
              attributeId:
                this.issuableAttribute === IssuableAttributeType.Milestone &&
                this.issuableType === TYPE_ISSUE
                  ? getIdFromGraphQLId(id)
                  : id,
              iid: this.iid,
            },
          })
          .then(({ data }) => {
            if (data.issuableSetAttribute?.errors?.length) {
              createAlert({
                message: data.issuableSetAttribute.errors[0],
                captureError: true,
                error: data.issuableSetAttribute.errors[0],
              });
            } else {
              this.$emit('attribute-updated', data);
            }
          })
          .catch((error) => {
            createAlert({ message: this.i18n.updateError, captureError: true, error });
          })
          .finally(() => {
            this.updating = false;
            this.selectedTitle = null;
          });
      }
    },
    isAttributeOverdue(attribute) {
      return this.issuableAttribute === IssuableAttributeType.Milestone
        ? attribute?.expired
        : false;
    },
    showDropdown() {
      this.$refs.dropdown.show();
    },
    handlePopoverClose() {
      this.$refs.popover.$emit('close');
    },
    handlePopoverConfirm(cb) {
      this.editConfirmation = true;
      this.handlePopoverClose();
      setTimeout(cb, 0);
    },
    handleEditConfirmation() {
      this.$refs.popover.$emit('open');
    },
  },
};
</script>

<template>
  <sidebar-editable-item
    ref="editable"
    :title="attributeTypeTitle"
    :data-testid="`${formatIssuableAttribute.kebab}-edit`"
    :button-id="`${formatIssuableAttribute.kebab}-edit`"
    :tracking="tracking"
    :should-show-confirmation-popover="shouldShowConfirmationPopover"
    :loading="updating || loading"
    @open="showDropdown"
    @edit-confirm="handleEditConfirmation"
  >
    <template #collapsed>
      <slot name="value-collapsed" :current-attribute="currentAttribute">
        <div
          v-if="isClassicSidebar"
          v-gl-tooltip.left.viewport
          :title="attributeTypeTitle"
          class="sidebar-collapsed-icon"
        >
          <gl-icon :aria-label="attributeTypeTitle" :name="attributeTypeIcon" />
          <span class="collapse-truncated-title gl-px-3 gl-pt-2 gl-text-sm">
            {{ attributeTitle }}
          </span>
        </div>
      </slot>
      <div
        :data-testid="`select-${formatIssuableAttribute.kebab}`"
        :class="isClassicSidebar ? 'hide-collapsed' : 'gl-mt-3'"
      >
        <span v-if="updating">{{ selectedTitle }}</span>
        <template v-else-if="!currentAttribute && hasCurrentAttribute">
          <gl-icon name="warning" variant="warning" />
          <span class="gl-text-subtle">{{ i18n.noPermissionToView }}</span>
        </template>
        <span v-else-if="!currentAttribute" class="gl-text-subtle">
          {{ $options.i18n.none }}
        </span>
        <slot
          v-else
          name="value"
          :attribute-title="attributeTitle"
          :attribute-url="attributeUrl"
          :current-attribute="currentAttribute"
        >
          <gl-link
            v-gl-tooltip="tooltipText"
            class="gl-text-inherit hover:gl-text-blue-800"
            :href="attributeUrl"
            :data-testid="`${formatIssuableAttribute.kebab}-link`"
          >
            {{ attributeTitle }}
            <span v-if="isAttributeOverdue(currentAttribute)">{{ $options.i18n.expired }}</span>
          </gl-link>
        </slot>
      </div>
    </template>
    <template v-if="shouldShowConfirmationPopover" #default="{ toggle }">
      <gl-popover
        ref="popover"
        :target="`${formatIssuableAttribute.kebab}-edit`"
        placement="bottomleft"
        boundary="viewport"
        triggers="click"
      >
        <div class="gl-mb-4 gl-text-base">
          {{ i18n.editConfirmation }}
        </div>
        <div class="gl-flex gl-items-center">
          <gl-button
            size="small"
            variant="confirm"
            category="primary"
            data-testid="confirm-edit-cta"
            @click.prevent="() => handlePopoverConfirm(toggle)"
            >{{ i18n.editConfirmationCta }}</gl-button
          >
          <gl-button
            class="gl-ml-auto"
            size="small"
            name="cancel"
            variant="default"
            category="primary"
            data-testid="confirm-edit-cancel"
            @click.prevent="handlePopoverClose"
            >{{ i18n.editConfirmationCancel }}</gl-button
          >
        </div>
      </gl-popover>
    </template>
    <template v-else #default>
      <sidebar-dropdown
        ref="dropdown"
        :attr-workspace-path="attrWorkspacePath"
        :current-attribute="currentAttribute"
        :issuable-attribute="issuableAttribute"
        :issuable-type="issuableType"
        :show-work-item-epics="showWorkItemEpics"
        @change="updateAttribute"
      >
        <template #list="{ attributesList, isAttributeChecked, updateAttribute: update }">
          <slot
            name="list"
            :attributes-list="attributesList"
            :is-attribute-checked="isAttributeChecked"
            :update-attribute="update"
          >
          </slot>
        </template>
      </sidebar-dropdown>
    </template>
  </sidebar-editable-item>
</template>
