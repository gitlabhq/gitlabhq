<script>
import {
  GlButton,
  GlCollapsibleListbox,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { kebabCase, snakeCase } from 'lodash-es';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST, NAMESPACE_PROJECT } from '~/issues/constants';
import { timeFor } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import { sanitize } from '~/lib/dompurify';
import { keysFor } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import {
  dropdowni18nText,
  IssuableAttributeState,
  IssuableAttributeType,
  IssuableAttributeTypeKeyMap,
  LocalizedIssuableAttributeType,
  noAttributeId,
  Tracking,
} from 'ee_else_ce/sidebar/constants';
import { issuableAttributesQueries } from 'ee_else_ce/sidebar/queries/constants';

export default {
  name: 'SidebarDropdownWidget',
  i18n: {
    expired: __('(expired)'),
    none: __('None'),
    edit: __('Edit'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlCollapsibleListbox,
    GlIcon,
    GlLink,
    GlLoadingIcon,
  },
  inject: {
    canUpdate: {
      default: false,
    },
    isClassicSidebar: {
      default: false,
    },
    issuableAttributesQueries: {
      default: issuableAttributesQueries,
    },
    issuableAttributesState: {
      default: IssuableAttributeState,
    },
    widgetTitleText: {
      default: {
        [IssuableAttributeType.Milestone]: __('Milestone'),
        expired: __('(expired)'),
        none: __('None'),
      },
    },
    keybinding: { default: null },
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
    groupBy: {
      type: Function,
      required: false,
      default: null,
    },
  },
  emits: ['attribute-updated'],
  apollo: {
    issuable: {
      query() {
        return this.issuableAttributeQuery.current[this.issuableType].query;
      },
      variables() {
        return {
          fullPath: this.workspacePath,
          iid: this.iid,
        };
      },
      update(data) {
        return data.namespace?.issuable || {};
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
            issuableId: this.issuable.id,
          };
        },
        skip() {
          return !issuableAttributesQueries[this.issuableAttribute].subscription;
        },
      },
    },
    attributesList: {
      query() {
        const { query } = this.issuableAttributeQuery.list[this.issuableType];
        return query[NAMESPACE_PROJECT] || query;
      },
      variables() {
        return {
          fullPath: this.attrWorkspacePath,
          title: this.searchTerm,
          state: this.issuableAttributesState[this.issuableAttribute],
        };
      },
      update: (data) => data?.namespace?.attributes?.nodes ?? [],
      result() {
        this.hasLoadedAttributes = true;
      },
      error(error) {
        this.hasLoadedAttributes = true;
        createAlert({ message: this.i18n.listFetchError, captureError: true, error });
      },
      skip() {
        return this.skipQuery;
      },
      debounce: 250,
    },
  },
  data() {
    return {
      updating: false,
      selectedTitle: null,
      issuable: {},
      attributesList: [],
      searchTerm: '',
      skipQuery: true,
      hasLoadedAttributes: false,
      tracking: {
        event: Tracking.editEvent,
        label: Tracking.rightSidebarLabel,
        property: this.issuableAttribute,
      },
    };
  },
  computed: {
    currentAttribute() {
      return this.issuable.attribute;
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
    isMergeRequest() {
      return this.issuableType === TYPE_MERGE_REQUEST;
    },
    supportsPopover() {
      return this.issuableAttribute === IssuableAttributeType.Milestone;
    },
    popoverAttributes() {
      if (!this.supportsPopover || !this.currentAttribute?.id) return {};

      return {
        'data-reference-type': IssuableAttributeType.Milestone,
        'data-placement': 'left',
        'data-milestone': getIdFromGraphQLId(this.currentAttribute.id),
      };
    },
    items() {
      if (this.groupBy) {
        return this.groupBy(this.attributesList);
      }
      return this.attributesList.map((attr) => ({
        ...attr,
        value: attr.id,
        text: attr.title,
        expired: this.isAttributeOverdue(attr),
      }));
    },
    flatItems() {
      if (!this.groupBy) return this.items;
      return this.items.flatMap((group) => group.options || []);
    },
    selectedAttributeId() {
      return this.currentAttribute?.id ?? null;
    },
    searching() {
      if (this.skipQuery) return false;
      return !this.hasLoadedAttributes || this.$apollo.queries.attributesList.loading;
    },
    labelShortcutDescription() {
      return shouldDisableShortcuts() || !this.keybinding ? null : this.keybinding.description;
    },
    labelShortcutKey() {
      return shouldDisableShortcuts() || !this.keybinding ? null : keysFor(this.keybinding)[0];
    },
    labelTooltip() {
      const description = this.labelShortcutDescription;
      const key = this.labelShortcutKey;
      return shouldDisableShortcuts() || !this.keybinding
        ? null
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
  },
  methods: {
    isAttributeOverdue(attribute) {
      return this.issuableAttribute === IssuableAttributeType.Milestone
        ? attribute?.expired
        : false;
    },
    onSearch(value) {
      this.searchTerm = value;
    },
    onShown() {
      this.skipQuery = false;
    },
    onReset() {
      this.selectedTitle = null;
      this.$refs.dropdown.close();
      this.updateAttribute({ id: noAttributeId });
    },
    onSelect(id) {
      const attr = this.flatItems.find((item) => item.value === id);
      this.selectedTitle = attr?.text ?? this.$options.i18n.none;
      this.updateAttribute({ id });
    },
    updateAttribute({ id }) {
      if (!this.canUpdate) return;
      if (this.currentAttribute === null && id === null) return;
      if (id === this.currentAttribute?.id) return;

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
    },
  },
};
</script>

<template>
  <div>
    <div
      class="hide-collapsed gl-flex gl-items-center gl-gap-2 gl-font-bold gl-leading-20 gl-text-default"
    >
      <span>{{ attributeTypeTitle }}</span>
      <gl-loading-icon
        v-if="loading"
        size="sm"
        inline
        class="!gl-align-bottom"
        data-testid="loading-icon"
      />
      <gl-collapsible-listbox
        v-if="canUpdate"
        ref="dropdown"
        :selected="selectedAttributeId"
        :header-text="i18n.assignAttribute"
        :reset-button-label="i18n.noAttribute"
        :items="items"
        :searching="searching"
        searchable
        placement="bottom-end"
        is-check-centered
        class="sidebar-dropdown-widget-listbox gl-ml-auto"
        @search="onSearch"
        @shown="onShown"
        @reset="onReset"
        @select="onSelect"
      >
        <template #toggle="{ accessibilityAttributes }">
          <gl-button
            v-gl-tooltip.viewport.html
            v-bind="accessibilityAttributes"
            class="shortcut-sidebar-dropdown-toggle"
            category="tertiary"
            size="small"
            :title="labelTooltip"
            :loading="updating"
            :data-track-action="tracking.event"
            :data-track-label="tracking.label"
            :data-track-property="tracking.property"
            :data-testid="`${formatIssuableAttribute.kebab}-edit`"
          >
            {{ $options.i18n.edit }}
          </gl-button>
        </template>
        <template #group-label="{ group }">
          <slot name="group-label" :group="group">{{ group.text }}</slot>
        </template>
        <template #list-item="{ item }">
          <slot name="list-item" :item="item">
            <span :data-testid="`${formatIssuableAttribute.kebab}-items`">
              {{ item.text }}
              <template v-if="item.expired">{{ $options.i18n.expired }}</template>
            </span>
          </slot>
        </template>
        <template #footer>
          <slot name="footer"></slot>
        </template>
      </gl-collapsible-listbox>
    </div>
    <div v-if="!isMergeRequest" data-testid="collapsed-content">
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
    </div>
    <div
      :data-testid="`select-${formatIssuableAttribute.kebab}`"
      :class="isClassicSidebar && !isMergeRequest ? 'hide-collapsed' : 'gl-pt-2 gl-leading-1'"
    >
      <span v-if="updating && selectedTitle">{{ selectedTitle }}</span>
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
          v-gl-tooltip="!supportsPopover ? tooltipText : null"
          :class="['gl-text-inherit hover:gl-text-blue-800', { 'has-popover': supportsPopover }]"
          :href="attributeUrl"
          :data-testid="`${formatIssuableAttribute.kebab}-link`"
          v-bind="supportsPopover ? popoverAttributes : {}"
        >
          {{ attributeTitle }}
          <span v-if="isAttributeOverdue(currentAttribute)">{{ $options.i18n.expired }}</span>
        </gl-link>
      </slot>
    </div>
  </div>
</template>
