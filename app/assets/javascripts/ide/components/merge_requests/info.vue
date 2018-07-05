<script>
import { mapGetters } from 'vuex';
import Icon from '../../../vue_shared/components/icon.vue';
import TitleComponent from '../../../issue_show/components/title.vue';
import DescriptionComponent from '../../../issue_show/components/description.vue';

export default {
  components: {
    Icon,
    TitleComponent,
    DescriptionComponent,
  },
  computed: {
    ...mapGetters(['currentMergeRequest']),
  },
};
</script>

<template>
  <div class="ide-merge-request-info h-100 d-flex flex-column">
    <div class="detail-page-header">
      <icon
        name="git-merge"
        class="align-self-center append-right-8"
      />
      <strong>
        !{{ currentMergeRequest.iid }}
      </strong>
    </div>
    <div class="issuable-details">
      <title-component
        :issuable-ref="currentMergeRequest.iid"
        :title-html="currentMergeRequest.title_html"
        :title-text="currentMergeRequest.title"
      />
      <description-component
        :description-html="currentMergeRequest.description_html"
        :description-text="currentMergeRequest.description"
        :can-update="false"
      />
    </div>
  </div>
</template>
