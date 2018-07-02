<script>
import { mapGetters } from 'vuex';
import Icon from '../../../vue_shared/components/icon.vue';
import timeago from '../../../vue_shared/mixins/timeago';
import tooltip from '../../../vue_shared/directives/tooltip';
import TitleComponent from '../../../issue_show/components/title.vue';
import DescriptionComponent from '../../../issue_show/components/description.vue';

const states = {
  open: 'open',
  closed: 'closed',
};

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
    TitleComponent,
    DescriptionComponent,
  },
  mixins: [timeago],
  computed: {
    ...mapGetters(['currentMergeRequest']),
    isOpen() {
      return this.currentMergeRequest.state === states.open;
    },
    isClosed() {
      return this.currentMergeRequest.state === states.closed;
    },
    authorUsername() {
      return `@${this.currentMergeRequest.author.username}`;
    },
    iconName() {
      return this.isOpen ? 'issue-open-m' : 'close';
    },
  },
};
</script>

<template>
  <div class="ide-merge-request-info">
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
        :title-html="currentMergeRequest.title"
        :title-text="currentMergeRequest.title"
      />
      <description-component
        :description-html="currentMergeRequest.description"
        :description-text="currentMergeRequest.description"
        :can-update="false"
      />
    </div>
  </div>
</template>

<style scoped>
.ide-merge-request-info {
  overflow: auto;
}

.detail-page-header {
  line-height: initial;
}
</style>
