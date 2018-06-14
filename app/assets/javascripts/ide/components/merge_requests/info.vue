<script>
import { mapGetters } from 'vuex';
import Icon from '../../../vue_shared/components/icon.vue';
import timeago from '../../../vue_shared/mixins/timeago';
import tooltip from '../../../vue_shared/directives/tooltip';

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
      <div class="detail-page-header-body">
        <div
          :class="{
            'status-box-open': isOpen,
            'status-box-closed': isClosed
          }"
          class="issuable-status-box status-box d-flex h-100"
        >
          <icon
            :name="iconName"
          />
        </div>
        <div class="issuable-meta">
          Opened
          {{ timeFormated(currentMergeRequest.created_at) }}
          by
          <a
            :href="currentMergeRequest.author.web_url"
            class="author_link"
          >
            <img
              :src="currentMergeRequest.author.avatar_url"
              class="avatar avatar-inline s24"
            />
            <strong
              v-tooltip
              :title="authorUsername"
            >
              {{ currentMergeRequest.author.name }}
            </strong>
          </a>
        </div>
      </div>
    </div>
    <div class="detail-page-description">
      <h2 class="title">
        {{ currentMergeRequest.title }}
      </h2>
      <div
        v-if="currentMergeRequest.description"
        class="description"
      >
        <div class="wiki">
          <p dir="auto">
            {{ currentMergeRequest.description }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.ide-merge-request-info {
  overflow: auto;
}
</style>
