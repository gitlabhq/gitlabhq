<script>
import {
  GlDropdown,
  GlDropdownDivider,
  GlDropdownItem,
  GlDropdownText,
  GlLoadingIcon,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { kebabCase, snakeCase } from 'lodash';
import {
  TYPE_EPIC,
  TYPE_ISSUE,
  TYPE_MERGE_REQUEST,
  WORKSPACE_GROUP,
  WORKSPACE_PROJECT,
} from '~/issues/constants';
import { __ } from '~/locale';
import {
  defaultEpicSort,
  dropdowni18nText,
  epicIidPattern,
  IssuableAttributeState,
  IssuableAttributeType,
  IssuableAttributeTypeKeyMap,
  LocalizedIssuableAttributeType,
  noAttributeId,
} from 'ee_else_ce/sidebar/constants';
import { issuableAttributesQueries } from 'ee_else_ce/sidebar/queries/constants';
import { createAlert } from '~/alert';
import { PathIdSeparator } from '~/related_issues/constants';
import { WORK_ITEM_TYPE_ENUM_EPIC } from '~/work_items/constants';

export default {
  noAttributeId,
  i18n: {
    expired: __('(expired)'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownText,
    GlDropdownDivider,
    GlSearchBoxByType,
    GlLoadingIcon,
  },
  inject: {
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
  },
  props: {
    attrWorkspacePath: {
      required: true,
      type: String,
    },
    currentAttribute: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    issuableAttribute: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      required: true,
      validator(value) {
        return [TYPE_ISSUE, TYPE_MERGE_REQUEST].includes(value);
      },
    },
    workspaceType: {
      type: String,
      required: false,
      default: WORKSPACE_PROJECT,
      validator(value) {
        return [WORKSPACE_GROUP, WORKSPACE_PROJECT].includes(value);
      },
    },
    showWorkItemEpics: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      attributesList: [],
      searchTerm: '',
      skipQuery: true,
    };
  },
  apollo: {
    attributesList: {
      query() {
        if (this.isEpic && this.showWorkItemEpics) {
          return this.issuableAttributesQueries[IssuableAttributeType.Parent].list[
            this.issuableType
          ].query;
        }

        const { list } = this.issuableAttributeQuery;
        const { query } = list[this.issuableType];
        return query[this.workspaceType] || query;
      },
      variables() {
        if (!this.isEpic) {
          return {
            fullPath: this.attrWorkspacePath,
            title: this.searchTerm,
            state: this.issuableAttributesState[this.issuableAttribute],
          };
        }

        const variables = {
          fullPath: this.attrWorkspacePath,
          state: this.issuableAttributesState[this.issuableAttribute],
          sort: defaultEpicSort,
        };

        if (this.showWorkItemEpics) {
          variables.types = [WORK_ITEM_TYPE_ENUM_EPIC];
        }

        if (epicIidPattern.test(this.searchTerm)) {
          const matches = this.searchTerm.match(epicIidPattern);
          variables.iidStartsWith = matches.groups.iid;
        } else if (this.searchTerm !== '') {
          variables.in = 'TITLE';
          variables.title = this.searchTerm;
        }

        return variables;
      },
      update: (data) => data?.workspace?.attributes?.nodes ?? [],
      error(error) {
        createAlert({ message: this.i18n.listFetchError, captureError: true, error });
      },
      skip() {
        if (
          this.isEpic &&
          this.searchTerm.startsWith(PathIdSeparator.Epic) &&
          this.searchTerm.length < 2
        ) {
          return true;
        }
        return this.skipQuery;
      },
      debounce: 250,
    },
  },
  computed: {
    attributeTypeTitle() {
      return this.widgetTitleText[this.issuableAttribute];
    },
    dropdownText() {
      return this.currentAttribute ? this.currentAttribute?.title : this.attributeTypeTitle;
    },
    emptyPropsList() {
      return this.attributesList.length === 0;
    },
    i18n() {
      const localizedAttribute =
        LocalizedIssuableAttributeType[IssuableAttributeTypeKeyMap[this.issuableAttribute]];
      return dropdowni18nText(localizedAttribute, this.issuableType);
    },
    isEpic() {
      // MV to EE https://gitlab.com/gitlab-org/gitlab/-/issues/345311
      return this.issuableAttribute === TYPE_EPIC;
    },
    issuableAttributeQuery() {
      return this.issuableAttributesQueries[this.issuableAttribute];
    },
    formatIssuableAttribute() {
      return {
        kebab: kebabCase(this.issuableAttribute),
        snake: snakeCase(this.issuableAttribute),
      };
    },
  },
  methods: {
    isAttributeChecked(attributeId) {
      return (
        attributeId === this.currentAttribute?.id || (!this.currentAttribute?.id && !attributeId)
      );
    },
    isAttributeOverdue(attribute) {
      return this.issuableAttribute === IssuableAttributeType.Milestone
        ? attribute?.expired
        : false;
    },
    handleShow() {
      this.skipQuery = false;
    },
    setFocus() {
      this.$refs?.search?.focusInput();
    },
    show() {
      this.$refs.dropdown.show();
    },
    updateAttribute(attribute) {
      this.$emit('change', attribute);
    },
  },
};
</script>

<template>
  <gl-dropdown
    ref="dropdown"
    block
    :header-text="i18n.assignAttribute"
    lazy
    :text="dropdownText"
    toggle-class="gl-m-0"
    @show="handleShow"
    @shown="setFocus"
  >
    <gl-search-box-by-type ref="search" v-model="searchTerm" :placeholder="__('Search')" />
    <gl-dropdown-item
      :data-testid="`no-${formatIssuableAttribute.kebab}-item`"
      is-check-item
      :is-checked="isAttributeChecked($options.noAttributeId)"
      @click="$emit('change', { id: $options.noAttributeId })"
    >
      {{ i18n.noAttribute }}
    </gl-dropdown-item>
    <gl-dropdown-divider />
    <gl-loading-icon
      v-if="$apollo.queries.attributesList.loading"
      size="sm"
      class="gl-py-4"
      data-testid="loading-icon-dropdown"
    />
    <template v-else>
      <gl-dropdown-text v-if="emptyPropsList">
        {{ i18n.noAttributesFound }}
      </gl-dropdown-text>
      <slot
        v-else
        name="list"
        :attributes-list="attributesList"
        :is-attribute-checked="isAttributeChecked"
        :update-attribute="updateAttribute"
      >
        <gl-dropdown-item
          v-for="attrItem in attributesList"
          :key="attrItem.id"
          is-check-item
          :is-checked="isAttributeChecked(attrItem.id)"
          :data-testid="`${formatIssuableAttribute.kebab}-items`"
          @click="updateAttribute(attrItem)"
        >
          {{ attrItem.title }}
          <template v-if="isAttributeOverdue(attrItem)">{{ $options.i18n.expired }}</template>
        </gl-dropdown-item>
      </slot>
    </template>
    <template #footer>
      <slot name="footer"></slot>
    </template>
  </gl-dropdown>
</template>
