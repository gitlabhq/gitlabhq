<script>
import {
  GlDisclosureDropdown,
  GlTooltipDirective,
  GlDisclosureDropdownItem,
  GlToggle,
  GlIcon,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import {
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS,
  METADATA_KEYS,
} from '~/work_items/constants';
import {
  workItemRoadmapPath,
  saveHiddenMetadataKeysToLocalStorage,
  getHiddenMetadataKeysFromLocalStorage,
} from '~/work_items/utils';

export default {
  i18n: {
    displayOptions: s__('WorkItem|Display options'),
    fields: s__('WorkItems|Fields'),
    showClosed: s__('WorkItem|Show closed items'),
  },
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlToggle,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
  inject: {
    getWorkItemTypeConfiguration: {
      default: null,
    },
  },
  props: {
    workItemIid: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    showClosed: {
      type: Boolean,
      required: false,
      default: true,
    },
    showViewRoadmapAction: {
      type: Boolean,
      required: false,
      default: false,
    },
    metadataLocalStorageKey: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isDropdownVisible: false,
      hiddenMetadataKeys: getHiddenMetadataKeysFromLocalStorage(this.metadataLocalStorageKey, []),
    };
  },
  computed: {
    workItemTypeConfiguration() {
      // Legacy applications may not have access to the metadata provider
      return this.getWorkItemTypeConfiguration
        ? this.getWorkItemTypeConfiguration(this.workItemType)
        : {};
    },
    tooltipText() {
      return !this.isDropdownVisible ? this.$options.i18n.displayOptions : '';
    },
    widgetMetadataFields() {
      return WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS.filter(
        (field) => ![METADATA_KEYS.COMMENTS, METADATA_KEYS.POPULARITY].includes(field.key),
      );
    },
    workItemRoadmapPathHref() {
      return workItemRoadmapPath(this.fullPath, this.workItemIid);
    },
    viewOnARoadmap() {
      return {
        text: s__('WorkItem|View on a roadmap'),
        href: this.workItemRoadmapPathHref,
        extraAttrs: {
          'data-testid': 'view-roadmap',
        },
      };
    },
    shouldShowViewRoadmapAction() {
      if (this.showViewRoadmapAction) {
        return (
          this.workItemTypeConfiguration?.supportsRoadmapView ||
          this.workItemType === WORK_ITEM_TYPE_NAME_EPIC
        );
      }
      return false;
    },
  },
  methods: {
    showDropdown() {
      this.isDropdownVisible = true;
    },
    hideDropdown() {
      this.isDropdownVisible = false;
    },
    toggleMetadataDisplaySettings(fieldKey) {
      const isHidden = this.hiddenMetadataKeys.includes(fieldKey);

      if (isHidden) {
        this.hiddenMetadataKeys = this.hiddenMetadataKeys.filter((key) => key !== fieldKey);
      } else {
        this.hiddenMetadataKeys = [...this.hiddenMetadataKeys, fieldKey];
      }

      saveHiddenMetadataKeysToLocalStorage(this.metadataLocalStorageKey, this.hiddenMetadataKeys);

      this.$emit('update-hidden-metadata-keys', this.hiddenMetadataKeys);
    },
  },
};
</script>
<template>
  <div>
    <gl-disclosure-dropdown
      ref="workItemsMoreActions"
      v-gl-tooltip="tooltipText"
      icon="preferences"
      text-sr-only
      :toggle-text="$options.i18n.displayOptions"
      size="small"
      category="tertiary"
      no-caret
      placement="bottom-end"
      :auto-close="false"
      @shown="showDropdown"
      @hidden="hideDropdown"
    >
      <div class="gl-border-b">
        <div class="gl-border-b gl-py-3">
          <span class="gl-pl-4 gl-text-sm gl-font-bold">
            {{ $options.i18n.displayOptions }}
          </span>
        </div>
        <div class="gl-py-2">
          <gl-disclosure-dropdown-item
            class="work-item-dropdown-toggle"
            @action="$emit('toggle-show-closed')"
          >
            <template #list-item>
              <gl-toggle
                :value="showClosed"
                :label="$options.i18n.showClosed"
                class="gl-justify-between"
                label-position="left"
              />
            </template>
          </gl-disclosure-dropdown-item>
          <gl-disclosure-dropdown-item
            v-if="shouldShowViewRoadmapAction"
            :item="viewOnARoadmap"
            @action="trackEvent('view_epic_on_roadmap')"
          />
        </div>
      </div>
      <div class="gl-pt-3">
        <span class="gl-pl-4 gl-text-sm gl-font-bold">
          {{ $options.i18n.fields }}
        </span>
        <gl-disclosure-dropdown-item
          v-for="metadata in widgetMetadataFields"
          :key="metadata.key"
          class="work-item-dropdown-toggle"
          @action="toggleMetadataDisplaySettings(metadata.key)"
        >
          <template #list-item>
            <div class="gl-flex gl-items-center gl-gap-3">
              <gl-icon :name="metadata.icon" />
              <gl-toggle
                :value="!hiddenMetadataKeys.includes(metadata.key)"
                :label="metadata.label"
                class="gl-w-full gl-justify-between"
                label-position="left"
              />
            </div>
          </template>
        </gl-disclosure-dropdown-item>
      </div>
    </gl-disclosure-dropdown>
  </div>
</template>
