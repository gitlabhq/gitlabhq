<script>
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export default {
  name: 'NoteAuthor',
  props: {
    author: {
      type: Object,
      required: true,
    },
    showUsername: {
      type: Boolean,
      required: false,
      default: true,
    },
    truncate: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
  },
};
</script>

<template>
  <a
    :href="author.path || author.webUrl"
    class="js-user-link gl-overflow-hidden gl-text-default hover:gl-text-link focus-visible:gl-focus"
    :class="truncate ? 'gl-truncate' : 'gl-break-words'"
    :data-user-id="authorId"
    :data-username="author.username"
  >
    <span class="gl-font-bold" data-testid="author-name" v-text="author.name"></span
    ><span
      v-if="showUsername && author.username"
      class="gl-ml-2 gl-inline-block gl-max-w-full gl-truncate gl-whitespace-nowrap gl-align-bottom gl-text-subtle @max-sm/discussion:gl-hidden"
      >@{{ author.username }}</span
    >
  </a>
</template>
