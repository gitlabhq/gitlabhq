<script>
import {
  GlLink,
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlSearchBoxByType,
  GlDropdownDivider,
  GlLoadingIcon,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import createFlash from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { IssuableType } from '~/issue_show/constants';
import { __, s__, sprintf } from '~/locale';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import {
  IssuableAttributeState,
  IssuableAttributeType,
  issuableAttributesQueries,
  noAttributeId,
  defaultEpicSort,
} from '../constants';

export default {
  noAttributeId,
  IssuableAttributeState,
  issuableAttributesQueries,
  i18n: {
    [IssuableAttributeType.Milestone]: __('Milestone'),
    expired: __('(expired)'),
    none: __('None'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    SidebarEditableItem,
    GlLink,
    GlDropdown,
    GlDropdownItem,
    GlDropdownText,
    GlDropdownDivider,
    GlSearchBoxByType,
    GlIcon,
    GlLoadingIcon,
  },
  inject: {
    isClassicSidebar: {
      default: false,
    },
  },
  props: {
    issuableAttribute: {
      type: String,
      required: true,
      validator(value) {
        return [IssuableAttributeType.Milestone].includes(value);
      },
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
        return [IssuableType.Issue, IssuableType.MergeRequest].includes(value);
      },
    },
    icon: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  apollo: {
    currentAttribute: {
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
        return data?.workspace?.issuable.attribute;
      },
      error(error) {
        createFlash({
          message: this.i18n.currentFetchError,
          captureError: true,
          error,
        });
      },
    },
    attributesList: {
      query() {
        const { list } = this.issuableAttributeQuery;
        const { query } = list[this.issuableType];

        return query;
      },
      skip() {
        return !this.editing;
      },
      debounce: 250,
      variables() {
        return {
          fullPath: this.attrWorkspacePath,
          title: this.searchTerm,
          state: this.$options.IssuableAttributeState[this.issuableAttribute],
          sort: this.issuableAttribute === IssuableType.Epic ? defaultEpicSort : null,
        };
      },
      update(data) {
        if (data?.workspace) {
          return data?.workspace?.attributes.nodes;
        }
        return [];
      },
      error(error) {
        createFlash({ message: this.i18n.listFetchError, captureError: true, error });
      },
    },
  },
  data() {
    return {
      searchTerm: '',
      editing: false,
      updating: false,
      selectedTitle: null,
      currentAttribute: null,
      attributesList: [],
      tracking: {
        label: 'right_sidebar',
        event: 'click_edit_button',
        property: this.issuableAttribute,
      },
    };
  },
  computed: {
    issuableAttributeQuery() {
      return this.$options.issuableAttributesQueries[this.issuableAttribute];
    },
    attributeTitle() {
      return this.currentAttribute?.title || this.i18n.noAttribute;
    },
    attributeUrl() {
      return this.currentAttribute?.webUrl;
    },
    dropdownText() {
      return this.currentAttribute
        ? this.currentAttribute?.title
        : this.$options.i18n[this.issuableAttribute];
    },
    loading() {
      return this.$apollo.queries.currentAttribute.loading;
    },
    emptyPropsList() {
      return this.attributesList.length === 0;
    },
    attributeTypeTitle() {
      return this.$options.i18n[this.issuableAttribute];
    },
    attributeTypeIcon() {
      return this.icon || this.issuableAttribute;
    },
    i18n() {
      return {
        noAttribute: sprintf(s__('DropdownWidget|No %{issuableAttribute}'), {
          issuableAttribute: this.issuableAttribute,
        }),
        assignAttribute: sprintf(s__('DropdownWidget|Assign %{issuableAttribute}'), {
          issuableAttribute: this.issuableAttribute,
        }),
        noAttributesFound: sprintf(s__('DropdownWidget|No %{issuableAttribute} found'), {
          issuableAttribute: this.issuableAttribute,
        }),
        updateError: sprintf(
          s__(
            'DropdownWidget|Failed to set %{issuableAttribute} on this %{issuableType}. Please try again.',
          ),
          { issuableAttribute: this.issuableAttribute, issuableType: this.issuableType },
        ),
        listFetchError: sprintf(
          s__(
            'DropdownWidget|Failed to fetch the %{issuableAttribute} for this %{issuableType}. Please try again.',
          ),
          { issuableAttribute: this.issuableAttribute, issuableType: this.issuableType },
        ),
        currentFetchError: sprintf(
          s__(
            'DropdownWidget|An error occurred while fetching the assigned %{issuableAttribute} of the selected %{issuableType}.',
          ),
          { issuableAttribute: this.issuableAttribute, issuableType: this.issuableType },
        ),
      };
    },
  },
  methods: {
    updateAttribute(attributeId) {
      if (this.currentAttribute === null && attributeId === null) return;
      if (attributeId === this.currentAttribute?.id) return;

      this.updating = true;

      const selectedAttribute =
        Boolean(attributeId) && this.attributesList.find((p) => p.id === attributeId);
      this.selectedTitle = selectedAttribute ? selectedAttribute.title : this.$options.i18n.none;

      const { current } = this.issuableAttributeQuery;
      const { mutation } = current[this.issuableType];

      this.$apollo
        .mutate({
          mutation,
          variables: {
            fullPath: this.workspacePath,
            attributeId:
              this.issuableAttribute === IssuableAttributeType.Milestone &&
              this.issuableType === IssuableType.Issue
                ? getIdFromGraphQLId(attributeId)
                : attributeId,
            iid: this.iid,
          },
        })
        .then(({ data }) => {
          if (data.issuableSetAttribute?.errors?.length) {
            createFlash({
              message: data.issuableSetAttribute.errors[0],
              captureError: true,
              error: data.issuableSetAttribute.errors[0],
            });
          } else {
            this.$emit('attribute-updated', data);
          }
        })
        .catch((error) => {
          createFlash({ message: this.i18n.updateError, captureError: true, error });
        })
        .finally(() => {
          this.updating = false;
          this.searchTerm = '';
          this.selectedTitle = null;
        });
    },
    isAttributeChecked(attributeId = undefined) {
      return (
        attributeId === this.currentAttribute?.id || (!this.currentAttribute?.id && !attributeId)
      );
    },
    isAttributeOverdue(attribute) {
      return this.issuableAttribute === IssuableAttributeType.Milestone
        ? attribute?.expired
        : false;
    },
    showDropdown() {
      this.$refs.newDropdown.show();
    },
    handleOpen() {
      this.editing = true;
      this.showDropdown();
    },
    handleClose() {
      this.editing = false;
    },
    setFocus() {
      this.$refs.search.focusInput();
    },
  },
};
</script>

<template>
  <sidebar-editable-item
    ref="editable"
    :title="attributeTypeTitle"
    :data-testid="`${issuableAttribute}-edit`"
    :tracking="tracking"
    :loading="updating || loading"
    @open="handleOpen"
    @close="handleClose"
  >
    <template #collapsed>
      <div v-if="isClassicSidebar" v-gl-tooltip class="sidebar-collapsed-icon">
        <gl-icon :size="16" :aria-label="attributeTypeTitle" :name="attributeTypeIcon" />
        <span class="collapse-truncated-title">
          {{ attributeTitle }}
        </span>
      </div>
      <div
        :data-testid="`select-${issuableAttribute}`"
        :class="isClassicSidebar ? 'hide-collapsed' : 'gl-mt-3'"
      >
        <span v-if="updating" class="gl-font-weight-bold">{{ selectedTitle }}</span>
        <span v-else-if="!currentAttribute" class="gl-text-gray-500">
          {{ $options.i18n.none }}
        </span>
        <slot
          v-else
          name="value"
          :attributeTitle="attributeTitle"
          :attributeUrl="attributeUrl"
          :currentAttribute="currentAttribute"
        >
          <gl-link
            class="gl-text-gray-900! gl-font-weight-bold"
            :href="attributeUrl"
            :data-qa-selector="`${issuableAttribute}_link`"
          >
            {{ attributeTitle }}
            <span v-if="isAttributeOverdue(currentAttribute)">{{ $options.i18n.expired }}</span>
          </gl-link>
        </slot>
      </div>
    </template>
    <template #default>
      <gl-dropdown
        ref="newDropdown"
        lazy
        :header-text="i18n.assignAttribute"
        :text="dropdownText"
        :loading="loading"
        class="gl-w-full"
        @shown="setFocus"
      >
        <gl-search-box-by-type ref="search" v-model="searchTerm" />
        <gl-dropdown-item
          :data-testid="`no-${issuableAttribute}-item`"
          :is-check-item="true"
          :is-checked="isAttributeChecked($options.noAttributeId)"
          @click="updateAttribute($options.noAttributeId)"
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
            :attributesList="attributesList"
            :isAttributeChecked="isAttributeChecked"
            :updateAttribute="updateAttribute"
          >
            <gl-dropdown-item
              v-for="attrItem in attributesList"
              :key="attrItem.id"
              :is-check-item="true"
              :is-checked="isAttributeChecked(attrItem.id)"
              :data-testid="`${issuableAttribute}-items`"
              @click="updateAttribute(attrItem.id)"
            >
              {{ attrItem.title }}
              <span v-if="isAttributeOverdue(attrItem)">{{ $options.i18n.expired }}</span>
            </gl-dropdown-item>
          </slot>
        </template>
      </gl-dropdown>
    </template>
  </sidebar-editable-item>
</template>
