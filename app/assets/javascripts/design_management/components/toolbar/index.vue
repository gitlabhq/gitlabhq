<script>
import { GlDeprecatedButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import Pagination from './pagination.vue';
import DeleteButton from '../delete_button.vue';
import permissionsQuery from '../../graphql/queries/permissions.query.graphql';
import appDataQuery from '../../graphql/queries/appData.query.graphql';
import { DESIGNS_ROUTE_NAME } from '../../router/constants';

export default {
  components: {
    Icon,
    Pagination,
    DeleteButton,
    GlDeprecatedButton,
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
      projectPath: '',
      issueIid: null,
    };
  },
  apollo: {
    appData: {
      query: appDataQuery,
      manual: true,
      result({ data: { projectPath, issueIid } }) {
        this.projectPath = projectPath;
        this.issueIid = issueIid;
      },
    },
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
  <header class="d-flex p-2 bg-white align-items-center js-design-header">
    <router-link
      :to="{
        name: $options.DESIGNS_ROUTE_NAME,
        query: $route.query,
      }"
      :aria-label="s__('DesignManagement|Go back to designs')"
      class="mr-3 text-plain d-flex justify-content-center align-items-center"
    >
      <icon :size="18" name="close" />
    </router-link>
    <div class="overflow-hidden d-flex align-items-center">
      <h2 class="m-0 str-truncated-100 gl-font-base">{{ filename }}</h2>
      <small v-if="updatedAt" class="text-secondary">{{ updatedText }}</small>
    </div>
    <pagination :id="id" class="ml-auto flex-shrink-0" />
    <gl-deprecated-button :href="image" class="mr-2">
      <icon :size="18" name="download" />
    </gl-deprecated-button>
    <delete-button
      v-if="isLatestVersion && canDeleteDesign"
      :is-deleting="isDeleting"
      button-variant="danger"
      @deleteSelectedDesigns="$emit('delete')"
    >
      <icon :size="18" name="remove" />
    </delete-button>
  </header>
</template>
