export default {
  name: 'MRWidgetRelatedLinks',
  props: {
    relatedLinks: { type: Object, required: true },
  },
  methods: {
    issuesText(field, isSuffix) {
      const text = this.relatedLinks[field];
      const matched = text ? text.match(/<\/a> and <a/) : null;

      if (matched) {
        if (isSuffix) {
          return matched.length ? 'are' : 'is';
        }
        return matched.length ? 'issues' : 'issue';
      }

      return '';
    },
  },
  template: `
    <section>
      <p v-if="relatedLinks.closing">
        Closes {{issuesText('closing')}} <span v-html="relatedLinks.closing"></span>.
      </p>
      <p v-if="relatedLinks.mentioned">
        <span class="capitalize">{{issuesText('mentioned')}}</span>
        <span v-html="relatedLinks.mentioned"></span>
        {{issuesText('mentioned', true)}} mentioned but will not be closed.
      </p>
    </section>
  `,
};
