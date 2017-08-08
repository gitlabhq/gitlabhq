export default {
  name: 'MRWidgetRelatedLinks',
  props: {
    relatedLinks: { type: Object, required: true },
    state: { type: String, required: false },
  },
  computed: {
    hasLinks() {
      const { closing, mentioned, assignToMe } = this.relatedLinks;
      return closing || mentioned || assignToMe;
    },
    closesText() {
      if (this.state === 'merged') {
        return 'Closed';
      }
      if (this.state === 'closed') {
        return 'Did not close';
      }
      return 'Closes';
    },
  },
  template: `
    <section
      v-if="hasLinks"
      class="mr-info-list mr-links">
      <p v-if="relatedLinks.closing">
        {{closesText}} <span v-html="relatedLinks.closing"></span>
      </p>
      <p v-if="relatedLinks.mentioned">
        Mentions <span v-html="relatedLinks.mentioned"></span>
      </p>
      <p v-if="relatedLinks.assignToMe">
        <span v-html="relatedLinks.assignToMe"></span>
      </p>
    </section>
  `,
};
