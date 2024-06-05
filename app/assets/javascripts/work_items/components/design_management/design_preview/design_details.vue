<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlAlert } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { fetchPolicies } from '~/lib/graphql';
import { Mousetrap } from '~/lib/mousetrap';
import { keysFor, ISSUE_CLOSE_DESIGN } from '~/behaviors/shortcuts/keybindings';
import { WORK_ITEM_ROUTE_NAME } from '../../../constants';
import getDesignQuery from '../graphql/design_details.query.graphql';
import { extractDesign, getPageLayoutElement } from '../utils';
import { DESIGN_DETAIL_LAYOUT_CLASSLIST } from '../constants';
import { DESIGN_NOT_FOUND_ERROR, DESIGN_VERSION_NOT_EXIST_ERROR } from '../error_messages';
import DesignPresentation from './design_presentation.vue';
import DesignToolbar from './design_toolbar.vue';
import DesignSidebar from './design_sidebar.vue';

const DEFAULT_SCALE = 1;
const DEFAULT_MAX_SCALE = 2;

export default {
  WORK_ITEM_ROUTE_NAME,
  components: {
    DesignPresentation,
    DesignSidebar,
    DesignToolbar,
    GlAlert,
  },
  inject: ['fullPath'],
  beforeRouteUpdate(to, from, next) {
    // reset scale when the active design changes
    this.scale = DEFAULT_SCALE;
    next();
  },
  beforeRouteEnter(to, from, next) {
    const pageEl = getPageLayoutElement();
    if (pageEl) {
      pageEl.classList.add(...DESIGN_DETAIL_LAYOUT_CLASSLIST);
    }

    next();
  },
  beforeRouteLeave(to, from, next) {
    const pageEl = getPageLayoutElement();
    if (pageEl) {
      pageEl.classList.remove(...DESIGN_DETAIL_LAYOUT_CLASSLIST);
    }

    next();
  },
  props: {
    iid: {
      type: String,
      required: true,
    },
    allDesigns: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      design: {},
      annotationCoordinates: null,
      errorMessage: '',
      scale: DEFAULT_SCALE,
      resolvedDiscussionsExpanded: false,
      prevCurrentUserTodos: null,
      maxScale: DEFAULT_MAX_SCALE,
      discussions: [],
      workItemId: '',
      workItemTitle: '',
      isSidebarOpen: true,
    };
  },
  apollo: {
    design: {
      query: getDesignQuery,
      // We want to see cached design version if we have one, and fetch newer version on the background to update discussions
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      // We need this for handling loading state when using frontend cache
      notifyOnNetworkStatusChange: true,
      variables() {
        return this.designVariables;
      },
      update: (data) => extractDesign(data),
      result(res) {
        this.onDesignQueryResult(res);
      },
      error() {
        this.onQueryError(DESIGN_NOT_FOUND_ERROR);
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.design.loading && !this.design.id;
    },
    designVariables() {
      return {
        fullPath: this.fullPath,
        iid: this.iid,
        filenames: [this.$route.params.id],
        atVersion: this.designsVersion,
      };
    },
    hasValidVersion() {
      return this.$route.query.version;
    },
    designsVersion() {
      return this.hasValidVersion
        ? `gid://gitlab/DesignManagement::Version/${this.$route.query.version}`
        : null;
    },
  },
  mounted() {
    Mousetrap.bind(keysFor(ISSUE_CLOSE_DESIGN), this.closeDesign);
  },
  methods: {
    onDesignQueryResult({ data, loading }) {
      // On the initial load with cache-and-network policy data is undefined while loading is true
      // To prevent throwing an error, we don't perform any logic until loading is false
      if (loading) {
        return;
      }

      if (!data || !extractDesign(data)) {
        this.onQueryError(DESIGN_NOT_FOUND_ERROR);
      } else if (this.$route.query.version && !this.hasValidVersion) {
        this.onQueryError(DESIGN_VERSION_NOT_EXIST_ERROR);
      } else {
        const workItem = data.project.workItems.nodes[0];
        this.workItemId = workItem.id;
        this.workItemTitle = workItem.title;
      }
    },
    onQueryError(message) {
      // because we redirect user to work item page,
      // we want to create these alerts on the work item page
      createAlert({ message });
      this.$router.push({ name: this.$options.WORK_ITEM_ROUTE_NAME });
    },
    onError(message, e) {
      this.errorMessage = message;
      if (e) throw e;
    },
    closeDesign() {
      this.$router.push({
        name: this.$options.WORK_ITEM_ROUTE_NAME,
        query: this.$route.query,
      });
    },
    setMaxScale(event) {
      this.maxScale = 1 / event;
    },
    toggleSidebar() {
      this.isSidebarOpen = !this.isSidebarOpen;
    },
  },
};
</script>

<template>
  <div
    class="design-detail js-design-detail fixed-top gl-w-full gl-flex gl-justify-content-center gl-flex-col gl-lg-flex-direction-row gl-bg-gray-10"
  >
    <div class="gl-flex gl-overflow-hidden gl-grow gl-flex-col gl-relative">
      <design-toolbar
        :work-item-title="workItemTitle"
        :design="design"
        :design-filename="$route.params.id"
        :is-loading="isLoading"
        :is-sidebar-open="isSidebarOpen"
        :all-designs="allDesigns"
        @toggle-sidebar="toggleSidebar"
      />
      <div
        class="gl-flex gl-overflow-hidden gl-flex-col gl-lg-flex-direction-row gl-grow gl-relative"
      >
        <div class="gl-flex gl-overflow-hidden gl-flex-grow-2 gl-flex-col gl-relative">
          <div v-if="errorMessage" class="gl-p-5">
            <gl-alert variant="danger" @dismiss="errorMessage = null">
              {{ errorMessage }}
            </gl-alert>
          </div>
          <design-presentation
            :image="design.image"
            :image-name="design.filename"
            :discussions="discussions"
            :scale="scale"
            :resolved-discussions-expanded="resolvedDiscussionsExpanded"
            :is-loading="isLoading"
            disable-commenting
            @setMaxScale="setMaxScale"
          />
        </div>
        <design-sidebar :design="design" :is-loading="isLoading" :is-open="isSidebarOpen" />
      </div>
    </div>
  </div>
</template>
