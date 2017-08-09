export default {
  name: 'MRWidgetRelatedLinks',
  props: {
    relatedLinks: { type: Object, required: true },
<<<<<<< HEAD
    state: { type: String },
=======
    state: { type: String, required: false },
>>>>>>> upstream/master
  },
  computed: {
    hasLinks() {
      const { closing, mentioned, assignToMe } = this.relatedLinks;
      return closing || mentioned || assignToMe;
    },
<<<<<<< HEAD
  },
  methods: {
    closesText(state) {
      if (state === 'merged') {
        return 'Closed';
      }
      if (state === 'closed') {
=======
    closesText() {
      if (this.state === 'merged') {
        return 'Closed';
      }
      if (this.state === 'closed') {
>>>>>>> upstream/master
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
<<<<<<< HEAD
        {{closesText(state)}} <span v-html="relatedLinks.closing"></span>
=======
        {{closesText}} <span v-html="relatedLinks.closing"></span>
>>>>>>> upstream/master
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
