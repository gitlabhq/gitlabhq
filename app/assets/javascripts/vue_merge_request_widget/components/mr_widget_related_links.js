export default {
  name: 'MRWidgetRelatedLinks',
  props: {
    relatedLinks: { type: Object, required: true },
  },
  methods: {
    hasMultipleIssues(text) {
      return !text ? false : text.match(/<\/a> and <a/);
    },
    issueLabel(field) {
      return this.hasMultipleIssues(this.relatedLinks[field]) ? 'issues' : 'issue';
    },
    verbLabel(field) {
      return this.hasMultipleIssues(this.relatedLinks[field]) ? 'are' : 'is';
    },
  },
  template: `
    <section>
      <p v-if="relatedLinks.closing">
        Closes {{issueLabel('closing')}} <span v-html="relatedLinks.closing"></span>.
      </p>
      <p v-if="relatedLinks.mentioned">
        <span class="capitalize">{{issueLabel('mentioned')}}</span>
        <span v-html="relatedLinks.mentioned"></span>
        {{verbLabel('mentioned')}} mentioned but will not be closed.
      </p>
    </section>
  `,
};
