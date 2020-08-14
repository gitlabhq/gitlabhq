<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import Pagination from './pagination.vue';
import DeleteButton from '../delete_button.vue';
import permissionsQuery from '../../graphql/queries/design_permissions.query.graphql';
import { DESIGNS_ROUTE_NAME } from '../../router/constants';

export default {
  components: {
    GlIcon,
    Pagination,
    DeleteButton,
    GlButton,
  },
  mixins: [timeagoMixin],
  props: {
    id: {
      type: String,
      required: true,
    },
    isDeleting: {
      type: Boolean,
      required: true,
    },
    filename: {
      type: String,
      required: false,
      default: '',
    },
    updatedAt: {
      type: String,
      required: false,
      default: null,
    },
    updatedBy: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isLatestVersion: {
      type: Boolean,
      required: true,
    },
    image: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      permissions: {
        createDesign: false,
      },
    };
  },
  inject: {
    projectPath: {
      default: '',
    },
    issueIid: {
      default: '',
    },
  },
  apollo: {
    permissions: {
      query: permissionsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issueIid,
        };
      },
      update: data => data.project.issue.userPermissions,
    },
  },
  computed: {
    updatedText() {
      return sprintf(__('Updated %{updated_at} by %{updated_by}'), {
        updated_at: this.timeFormatted(this.updatedAt),
        updated_by: this.updatedBy.name,
      });
    },
    canDeleteDesign() {
      return this.permissions.createDesign;
    },
  },
  DESIGNS_ROUTE_NAME,
};
</script>

<template>
  <header
    class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-bg-white gl-py-4 gl-pl-4 js-design-header"
  >
    <div class="gl-display-flex gl-align-items-center">
      <router-link
        :to="{
          name: $options.DESIGNS_ROUTE_NAME,
          query: $route.query,
        }"
        :aria-label="s__('DesignManagement|Go back to designs')"
        data-testid="close-design"
        class="gl-mr-5 gl-display-flex gl-align-items-center gl-justify-content-center text-plain"
      >
        <gl-icon name="close" />
      </router-link>
      <div class="overflow-hidden d-flex align-items-center">
        <h2 class="m-0 str-truncated-100 gl-font-base">{{ filename }}</h2>
        <small v-if="updatedAt" class="text-secondary">{{ updatedText }}</small>
      </div>
    </div>

    <div class="gl-display-flex gl-align-items-center">
      <pagination :id="id" class="gl-mr-3 gl-flex-shrink-0" />
      <gl-button :href="image" icon="download" />
      <delete-button
        v-if="isLatestVersion && canDeleteDesign"
        class="gl-ml-3"
        :is-deleting="isDeleting"
        button-variant="warning"
        button-icon="archive"
        button-category="secondary"
        @deleteSelectedDesigns="$emit('delete')"
      />
    </div>
  </header>
</template>
