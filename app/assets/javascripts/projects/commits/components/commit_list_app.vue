<script>
import { GlIcon } from '@gitlab/ui';
import { mockCommits } from 'jest/projects/commits/components/mock_data';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import CommitListHeader from './commit_list_header.vue';
import CommitListItem from './commit_list_item.vue';

export default {
  name: 'CommitListApp',
  components: {
    GlIcon,
    CommitListHeader,
    CommitListItem,
  },
  data() {
    return {
      // TODO - replace with real data in https://gitlab.com/gitlab-org/gitlab/-/issues/550474
      commits: mockCommits,
    };
  },
  methods: {
    getFormattedDate(dateTime) {
      return localeDateFormat.asDate.format(new Date(dateTime));
    },
  },
};
</script>

<template>
  <div class="gl-mt-5">
    <commit-list-header />
    <ol class="gl-my-6 gl-list-none gl-p-0">
      <li v-for="commit in commits" :key="commit.id" data-testid="daily-commits">
        <div class="gl-mb-3 gl-flex gl-items-center gl-gap-5">
          <gl-icon name="commit" />
          <time class="gl-font-bold" :datetime="commit.day">
            {{ getFormattedDate(commit.day) }}
          </time>
        </div>
        <ul class="commit-list-item gl-mb-6 gl-list-none gl-p-0">
          <commit-list-item
            v-for="dailyCommit in commit.dailyCommits"
            :key="dailyCommit.id"
            :commit="dailyCommit"
          />
        </ul>
      </li>
    </ol>
  </div>
</template>
