<script>
  import { mapGetters } from 'vuex';
  import resolveSvg from 'icons/_icon_resolve_discussion.svg';
  import resolvedSvg from 'icons/_icon_status_success_solid.svg';
  import { pluralize } from '../../lib/utils/text_utility';

  export default {
    computed: {
      ...mapGetters([
        'getUserData',
        'discussionCount',
        'resolvedDiscussionCount',
      ]),
      isLoggedIn() {
        return this.getUserData.id;
      },
      hasNextButton() {
        return this.isLoggedIn && !this.allResolved;
      },
      countText() {
        return pluralize('discussion', this.discussionCount);
      },
      allResolved() {
        return this.resolvedDiscussionCount === this.discussionCount;
      },
    },
    created() {
      this.resolveSvg = resolveSvg;
      this.resolvedSvg = resolvedSvg;
    },
  }
</script>

<template>
  <div class="line-resolve-all-container">
    <div>
      <div
        v-if="discussionCount > 0"
        :class="{ 'has-next-btn': hasNextButton }"
        class="line-resolve-all"
      >
        <span
          :class="{ 'is-active': allResolved }"
          class="line-resolve-btn is-disabled"
          type="button">
          <span
            v-if="allResolved"
            v-html="resolvedSvg"
          ></span>
          <span
            v-else
            v-html="resolveSvg"
          ></span>
        </span>
        <span class=".line-resolve-text">
          {{resolvedDiscussionCount}}/{{discussionCount}} {{countText}} resolved
        </span>
      </div>
    </div>
  </div>
</template>
