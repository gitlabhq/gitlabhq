<script>
import { GlModal, GlFormCheckboxGroup, GlFormCheckbox, GlSearchBoxByType } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { toggleArrayItem } from '~/lib/utils/array_utility';
import RefTrackingMetadata from './ref_tracking_metadata.vue';

export default {
  name: 'RefTrackingSelection',
  components: {
    GlModal,
    GlFormCheckboxGroup,
    GlFormCheckbox,
    GlSearchBoxByType,
    RefTrackingMetadata,
  },
  props: {
    isVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      searchTerm: '',
      selectedRefs: [],
      // Hardcoded data for first iteration - will be replaced with GraphQL data
      availableRefs: [
        {
          id: 'ref-1',
          name: 'rhendricksen/update_service_settings',
          refType: 'BRANCH',
          isProtected: false,
          commit: {
            shortId: '544ffe4a',
            // eslint-disable-next-line @gitlab/require-i18n-strings
            title: 'Update how the settings form works',
            authoredDate: '2024-11-03T10:45:00Z',
            webPath: '#',
          },
        },
        {
          id: 'ref-2',
          name: 'rails-next',
          refType: 'BRANCH',
          isProtected: true,
          commit: {
            shortId: '4809jop2',
            // eslint-disable-next-line @gitlab/require-i18n-strings
            title: "Merge branch webhook-extension into 'main'",
            authoredDate: '2024-11-03T10:42:00Z',
            webPath: '#',
          },
        },
        {
          id: 'ref-3',
          name: '17-12-stable-ee',
          refType: 'BRANCH',
          isProtected: false,
          commit: {
            shortId: '233rue8n',
            // eslint-disable-next-line @gitlab/require-i18n-strings
            title: 'Allow for editing of service account email address via UI',
            authoredDate: '2024-11-03T10:29:00Z',
            webPath: '#',
          },
        },
        {
          id: 'ref-4',
          name: '17-12-stable-ee',
          refType: 'TAG',
          isProtected: false,
          commit: {
            shortId: '5900yyr8',
            // eslint-disable-next-line @gitlab/require-i18n-strings
            title: 'Update VERSION files',
            authoredDate: '2024-11-03T09:00:00Z',
            webPath: '#',
          },
        },
        {
          id: 'ref-5',
          name: 'main',
          refType: 'BRANCH',
          isProtected: true,
          commit: {
            shortId: 'a1b2c3d4',
            // eslint-disable-next-line @gitlab/require-i18n-strings
            title: 'Latest main branch commit',
            authoredDate: '2024-11-03T08:30:00Z',
            webPath: '#',
          },
        },
      ],
    };
  },
  computed: {
    filteredRefs() {
      // Note: This search functionality is only temporary and will be replaced with GraphQL search functionality
      if (!this.searchTerm) {
        return this.availableRefs;
      }
      return this.availableRefs.filter((ref) =>
        ref.name.toLowerCase().includes(this.searchTerm.toLowerCase()),
      );
    },
    modalTitle() {
      return s__('SecurityTrackedRefs|Track new ref');
    },
    actionPrimaryProps() {
      return {
        text: s__('SecurityTrackedRefs|Track ref(s)'),
        attributes: {
          variant: 'confirm',
          disabled: !this.selectedRefs.length,
        },
      };
    },
    actionCancelProps() {
      return {
        text: __('Cancel'),
      };
    },
  },
  methods: {
    toggleRef(refId) {
      this.selectedRefs = toggleArrayItem(this.selectedRefs, refId);
    },
    handleHidden() {
      this.selectedRefs = [];
      this.searchTerm = '';
      this.$emit('cancel');
    },
  },
};
</script>

<template>
  <gl-modal
    :visible="isVisible"
    :title="modalTitle"
    hide-header
    hide-header-close
    scrollable
    :action-primary="actionPrimaryProps"
    :action-cancel="actionCancelProps"
    modal-id="track-ref-selection-modal"
    modal-class="gl-pt-12 gl-px-2 sm:gl-pt-20 sm:gl-px-4 [&_.modal-dialog]:!gl-items-start"
    size="lg"
    :centered="false"
    @hidden="handleHidden"
  >
    <gl-search-box-by-type
      v-model="searchTerm"
      :placeholder="s__('SecurityTrackedRefs|Search branches and tags')"
      class="gl-mb-4 gl-mt-3"
      data-testid="ref-search-input"
    />

    <gl-form-checkbox-group v-model="selectedRefs">
      <ul class="gl-m-0 gl-list-none gl-p-0">
        <li
          v-for="ref in filteredRefs"
          :key="ref.id"
          class="gl-border-b gl-cursor-pointer gl-p-4 last:gl-border-b-0 hover:gl-bg-gray-50"
          @click="toggleRef(ref.id)"
        >
          <!-- We use the `@click` handler within the `li` so the whole item is clickable, not just the checkbox, therefor we need to disable pointer events on the checkbox -->
          <gl-form-checkbox :value="ref.id" class="gl-pointer-events-none gl-grid gl-items-start">
            <div class="gl-ml-2">
              <ref-tracking-metadata :tracked-ref="ref" :disable-commit-link="true" />
            </div>
          </gl-form-checkbox>
        </li>
      </ul>
    </gl-form-checkbox-group>
  </gl-modal>
</template>
