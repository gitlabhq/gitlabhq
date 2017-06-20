export default {
  name: 'MRWidgetRelatedLinks',
  props: {
    isMerged: { type: Boolean, required: true },
    relatedLinks: { type: Object, required: true },
  },
  computed: {
    // TODO: the following should be handled by i18n
    closingText() {
      if (this.isMerged) {
        return `Closed ${this.issueLabel('closing')}`;
      }

      return `Closes ${this.issueLabel('closing')}`;
    },
    hasLinks() {
      const { closing, mentioned, assignToMe } = this.relatedLinks;
      return closing || mentioned || assignToMe;
    },
    // TODO: the following should be handled by i18n
    mentionedText() {
      if (this.isMerged) {
        if (this.hasMultipleIssues(this.relatedLinks.mentioned)) {
          return 'are mentioned but were not closed';
        }

        return 'is mentioned but was not closed';
      }

      if (this.hasMultipleIssues(this.relatedLinks.mentioned)) {
        return 'are mentioned but will not be closed';
      }

      return 'is mentioned but will not be closed';
    },
  },
  methods: {
    hasMultipleIssues(text) {
      return /<\/a>,? and <a/.test(text);
    },
    // TODO: the following should be handled by i18n
    issueLabel(field) {
      return this.hasMultipleIssues(this.relatedLinks[field]) ? 'issues' : 'issue';
    },
  },
  template: `
    <div v-if="hasLinks">
      <div class="legend"></div>
      <p v-if="relatedLinks.closing">
        {{closingText}}
        <span v-html="relatedLinks.closing"></span>.
      </p>
      <p v-if="relatedLinks.mentioned">
        <span class="capitalize">{{issueLabel('mentioned')}}</span>
        <span v-html="relatedLinks.mentioned"></span>
        {{mentionedText}}
      </p>
      <p v-if="relatedLinks.assignToMe">
        <span v-html="relatedLinks.assignToMe"></span>
      </p>
    </div>
  `,
};
