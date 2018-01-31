<script>
  import { s__ } from '~/locale';

  export default {
    name: 'MRWidgetRelatedLinks',
    props: {
      relatedLinks: {
        type: Object,
        required: true,
        default: () => ({}),
      },
      state: {
        type: String,
        required: false,
        default: '',
      },
    },
    computed: {
      closesText() {
        if (this.state === 'merged') {
          return s__('mrWidget|Closed');
        }
        if (this.state === 'closed') {
          return s__('mrWidget|Did not close');
        }
        return s__('mrWidget|Closes');
      },
    },
  };
</script>
<template>
  <section class="mr-info-list mr-links">
    <p v-if="relatedLinks.closing">
      {{ closesText }} <span v-html="relatedLinks.closing"></span>
    </p>
    <p v-if="relatedLinks.mentioned">
      {{ s__("mrWidget|Mentions") }} <span v-html="relatedLinks.mentioned"></span>
    </p>
    <p v-if="relatedLinks.assignToMe">
      <span v-html="relatedLinks.assignToMe"></span>
    </p>
  </section>
</template>
