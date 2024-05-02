<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlCard, GlLoadingIcon, GlIcon, GlButton } from '@gitlab/ui';
import { fetchPolicies } from '~/lib/graphql';
import CreateForm from '../components/form.vue';
import List from '../components/list.vue';

export default {
  apollo: {
    savedReplies: {
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      query() {
        return this.fetchAllQuery;
      },
      update: (r) => r.object?.savedReplies?.nodes,
      variables() {
        return {
          path: this.path,
          ...this.pagination,
        };
      },
      result({ data }) {
        const pageInfo = data.object?.savedReplies?.pageInfo;

        this.count = data.object?.savedReplies?.count;

        if (pageInfo) {
          this.pageInfo = pageInfo;
        }
      },
    },
  },
  components: {
    GlCard,
    GlButton,
    GlLoadingIcon,
    GlIcon,
    CreateForm,
    List,
  },
  inject: {
    path: { default: '' },
    fetchAllQuery: { required: true },
  },
  data() {
    return {
      savedReplies: [],
      count: 0,
      pageInfo: {},
      pagination: {},
      showForm: false,
    };
  },
  methods: {
    refetchSavedReplies() {
      this.pagination = {};
      this.$apollo.queries.savedReplies.refetch();
      this.toggleShowForm();
    },
    changePage(pageInfo) {
      this.pagination = pageInfo;
    },
    toggleShowForm() {
      this.showForm = !this.showForm;
    },
  },
};
</script>

<template>
  <gl-card
    class="gl-new-card"
    header-class="gl-new-card-header"
    body-class="gl-new-card-body gl-px-0"
  >
    <template #header>
      <div class="gl-new-card-title-wrapper" data-testid="title">
        <h3 class="gl-new-card-title">
          {{ __('Comment templates') }}
        </h3>
        <div class="gl-new-card-count">
          <gl-icon name="comment-lines" class="gl-mr-2" />
          {{ count }}
        </div>
      </div>
      <gl-button v-if="!showForm" size="small" class="gl-ml-3" @click="toggleShowForm">
        {{ __('Add new') }}
      </gl-button>
    </template>
    <div v-if="showForm" class="gl-new-card-add-form gl-m-3 gl-mb-4">
      <h4 class="gl-mt-0">{{ __('Add new comment template') }}</h4>
      <create-form @saved="refetchSavedReplies" @cancel="toggleShowForm" />
    </div>
    <gl-loading-icon v-if="$apollo.queries.savedReplies.loading" size="sm" class="gl-my-5" />
    <list
      v-else-if="savedReplies && savedReplies.length"
      :saved-replies="savedReplies"
      :page-info="pageInfo"
      @input="changePage"
    />
    <div v-else class="gl-new-card-empty gl-px-5 gl-py-4">
      {{ __('You have no comment templates yet.') }}
    </div>
  </gl-card>
</template>
