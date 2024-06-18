<script>
import { isString } from 'lodash';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { DEFAULT_COLOR, COLOR_WIDGET_COLOR, DROPDOWN_VARIANT, ISSUABLE_COLORS } from './constants';
import DropdownContents from './dropdown_contents.vue';
import DropdownValue from './dropdown_value.vue';
import { isDropdownVariantSidebar, isDropdownVariantEmbedded } from './utils';
import epicColorQuery from './graphql/epic_color.query.graphql';
import updateEpicColorMutation from './graphql/epic_update_color.mutation.graphql';

export default {
  i18n: {
    assignColor: s__('ColorWidget|Assign epic color'),
    dropdownButtonText: COLOR_WIDGET_COLOR,
    fetchingError: s__('ColorWidget|Error fetching epic color.'),
    updatingError: s__('ColorWidget|An error occurred while updating color.'),
    widgetTitle: COLOR_WIDGET_COLOR,
  },
  components: {
    DropdownValue,
    DropdownContents,
    SidebarEditableItem,
  },
  props: {
    allowEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    iid: {
      type: String,
      required: false,
      default: '',
    },
    fullPath: {
      type: String,
      required: true,
    },
    variant: {
      type: String,
      required: false,
      default: DROPDOWN_VARIANT.Sidebar,
    },
    dropdownButtonText: {
      type: String,
      required: false,
      default: COLOR_WIDGET_COLOR,
    },
    dropdownTitle: {
      type: String,
      required: false,
      default: s__('ColorWidget|Assign epic color'),
    },
    defaultColor: {
      type: Object,
      required: false,
      validator(value) {
        return isString(value?.color) && isString(value?.title);
      },
      default() {
        return {
          color: '',
          title: '',
        };
      },
    },
  },
  data() {
    return {
      issuableColor: this.defaultColor,
      colorUpdateInProgress: false,
      oldIid: null,
      sidebarExpandedOnClick: false,
    };
  },
  apollo: {
    issuableColor: {
      query: epicColorQuery,
      skip() {
        return !isDropdownVariantSidebar(this.variant) || !this.iid;
      },
      variables() {
        return {
          iid: this.iid,
          fullPath: this.fullPath,
        };
      },
      update(data) {
        const issuableColor = data.workspace?.issuable?.color;

        if (issuableColor) {
          return ISSUABLE_COLORS.find((color) => color.color === issuableColor) ?? DEFAULT_COLOR;
        }

        return DEFAULT_COLOR;
      },
      error() {
        createAlert({
          message: this.$options.i18n.fetchingError,
          captureError: true,
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.colorUpdateInProgress || this.$apollo.queries.issuableColor.loading;
    },
  },
  watch: {
    iid(_, oldVal) {
      this.oldIid = oldVal;
    },
  },
  methods: {
    handleDropdownClose(color) {
      if (this.iid !== '') {
        this.updateSelectedColor(color);
      } else {
        this.$emit('updateSelectedColor', { color });
      }

      this.collapseEditableItem();
    },
    collapseEditableItem() {
      this.$refs.editable?.collapse();
      if (this.sidebarExpandedOnClick) {
        this.sidebarExpandedOnClick = false;
        this.$emit('toggleCollapse');
      }
    },
    getUpdateVariables(color) {
      const currentIid = this.oldIid || this.iid;

      return {
        iid: currentIid,
        groupPath: this.fullPath,
        color: color.color,
      };
    },
    updateSelectedColor(color) {
      this.colorUpdateInProgress = true;

      const input = this.getUpdateVariables(color);

      this.$apollo
        .mutate({
          mutation: updateEpicColorMutation,
          variables: { input },
        })
        .then(({ data }) => {
          if (data.updateIssuableColor?.errors?.length) {
            throw new Error();
          }

          this.$emit('updateSelectedColor', {
            id: data.updateIssuableColor?.issuable?.id,
            color,
          });
        })
        .catch((error) =>
          createAlert({
            message: this.$options.i18n.updatingError,
            captureError: true,
            error,
          }),
        )
        .finally(() => {
          this.colorUpdateInProgress = false;
        });
    },
    isDropdownVariantSidebar,
    isDropdownVariantEmbedded,
  },
};
</script>

<template>
  <div
    class="labels-select-wrapper gl-relative"
    :class="{
      'is-embedded': isDropdownVariantEmbedded(variant),
    }"
  >
    <template v-if="isDropdownVariantSidebar(variant)">
      <sidebar-editable-item
        ref="editable"
        :title="$options.i18n.widgetTitle"
        :loading="isLoading"
        :can-edit="allowEdit"
        @open="oldIid = null"
      >
        <template #collapsed>
          <dropdown-value :selected-color="issuableColor">
            <slot></slot>
          </dropdown-value>
        </template>
        <template #default="{ edit }">
          <dropdown-value :selected-color="issuableColor" class="gl-mb-2">
            <slot></slot>
          </dropdown-value>
          <dropdown-contents
            ref="dropdownContents"
            :dropdown-button-text="dropdownButtonText"
            :dropdown-title="dropdownTitle"
            :selected-color="issuableColor"
            :variant="variant"
            :is-visible="edit"
            @setColor="handleDropdownClose"
            @closeDropdown="collapseEditableItem"
          />
        </template>
      </sidebar-editable-item>
    </template>
    <dropdown-contents
      v-else
      ref="dropdownContents"
      :dropdown-button-text="dropdownButtonText"
      :dropdown-title="dropdownTitle"
      :selected-color="issuableColor"
      :variant="variant"
      @setColor="handleDropdownClose"
    />
  </div>
</template>
