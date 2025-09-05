<script>
import { __ } from '~/locale';
import WikiDiscussionSorter from './wiki_discussion_sorter.vue';

export default {
  name: 'WikiNotesActivityHeader',
  components: { WikiDiscussionSorter },
  i18n: {
    headerText: __('Comments'),
  },
};
</script>
<template>
  <div
    class="gl-flex gl-flex-col gl-justify-between gl-pt-5 @sm/panel:gl-flex-row @sm/panel:gl-items-center"
  >
    <h2 class="gl-heading-2 gl-mb-0 gl-mt-5">{{ $options.i18n.headerText }}</h2>
    <wiki-discussion-sorter />
  </div>
</template>
