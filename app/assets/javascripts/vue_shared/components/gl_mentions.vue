<script>
import { escape, last } from 'lodash';
import Tribute from 'tributejs';
import axios from '~/lib/utils/axios_utils';
import { spriteIcon } from '~/lib/utils/common_utils';
import SidebarMediator from '~/sidebar/sidebar_mediator';

const AutoComplete = {
  Issues: 'issues',
  Labels: 'labels',
  Members: 'members',
  MergeRequests: 'mergeRequests',
  Milestones: 'milestones',
};

const groupType = 'Group'; // eslint-disable-line @gitlab/require-i18n-strings

function doesCurrentLineStartWith(searchString, fullText, selectionStart) {
  const currentLineNumber = fullText.slice(0, selectionStart).split('\n').length;
  const currentLine = fullText.split('\n')[currentLineNumber - 1];
  return currentLine.startsWith(searchString);
}

const autoCompleteMap = {
  [AutoComplete.Issues]: {
    filterValues() {
      return this[AutoComplete.Issues];
    },
    menuItemTemplate({ original }) {
      return `<small>${original.reference || original.iid}</small> ${escape(original.title)}`;
    },
  },
  [AutoComplete.Labels]: {
    filterValues() {
      const fullText = this.$slots.default?.[0]?.elm?.value;
      const selectionStart = this.$slots.default?.[0]?.elm?.selectionStart;

      if (doesCurrentLineStartWith('/label', fullText, selectionStart)) {
        return this.labels.filter(label => !label.set);
      }

      if (doesCurrentLineStartWith('/unlabel', fullText, selectionStart)) {
        return this.labels.filter(label => label.set);
      }

      return this.labels;
    },
    menuItemTemplate({ original }) {
      return `
        <span class="dropdown-label-box" style="background: ${escape(original.color)};"></span>
        ${escape(original.title)}`;
    },
  },
  [AutoComplete.Members]: {
    filterValues() {
      const fullText = this.$slots.default?.[0]?.elm?.value;
      const selectionStart = this.$slots.default?.[0]?.elm?.selectionStart;

      // Need to check whether sidebar store assignees has been updated
      // in the case where the assignees AJAX response comes after the user does @ autocomplete
      const isAssigneesLengthSame =
        this.assignees?.length === SidebarMediator.singleton?.store?.assignees?.length;

      if (!this.assignees || !isAssigneesLengthSame) {
        this.assignees =
          SidebarMediator.singleton?.store?.assignees?.map(assignee => assignee.username) || [];
      }

      if (doesCurrentLineStartWith('/assign', fullText, selectionStart)) {
        return this.members.filter(member => !this.assignees.includes(member.username));
      }

      if (doesCurrentLineStartWith('/unassign', fullText, selectionStart)) {
        return this.members.filter(member => this.assignees.includes(member.username));
      }

      return this.members;
    },
    menuItemTemplate({ original }) {
      const commonClasses = 'gl-avatar gl-avatar-s24 gl-flex-shrink-0';
      const noAvatarClasses = `${commonClasses} gl-rounded-small
        gl-display-flex gl-align-items-center gl-justify-content-center`;

      const avatar = original.avatar_url
        ? `<img class="${commonClasses} gl-avatar-circle" src="${original.avatar_url}" alt="" />`
        : `<div class="${noAvatarClasses}" aria-hidden="true">
            ${original.username.charAt(0).toUpperCase()}</div>`;

      let displayName = original.name;
      let parentGroupOrUsername = `@${original.username}`;

      if (original.type === groupType) {
        const splitName = original.name.split(' / ');
        displayName = splitName.pop();
        parentGroupOrUsername = splitName.pop();
      }

      const count = original.count && !original.mentionsDisabled ? ` (${original.count})` : '';

      const disabledMentionsIcon = original.mentionsDisabled
        ? spriteIcon('notifications-off', 's16 gl-ml-3')
        : '';

      return `
        <div class="gl-display-flex gl-align-items-center">
          ${avatar}
          <div class="gl-font-sm gl-line-height-normal gl-ml-3">
            <div>${escape(displayName)}${count}</div>
            <div class="gl-text-gray-700">${escape(parentGroupOrUsername)}</div>
          </div>
          ${disabledMentionsIcon}
        </div>
      `;
    },
  },
  [AutoComplete.MergeRequests]: {
    filterValues() {
      return this[AutoComplete.MergeRequests];
    },
    menuItemTemplate({ original }) {
      return `<small>${original.reference || original.iid}</small> ${escape(original.title)}`;
    },
  },
  [AutoComplete.Milestones]: {
    filterValues() {
      return this[AutoComplete.Milestones];
    },
    menuItemTemplate({ original }) {
      return escape(original.title);
    },
  },
};

export default {
  name: 'GlMentions',
  props: {
    dataSources: {
      type: Object,
      required: false,
      default: () => gl.GfmAutoComplete?.dataSources || {},
    },
  },
  mounted() {
    const NON_WORD_OR_INTEGER = /\W|^\d+$/;

    this.tribute = new Tribute({
      collection: [
        {
          trigger: '#',
          lookup: value => value.iid + value.title,
          menuItemTemplate: autoCompleteMap[AutoComplete.Issues].menuItemTemplate,
          selectTemplate: ({ original }) => original.reference || `#${original.iid}`,
          values: this.getValues(AutoComplete.Issues),
        },
        {
          trigger: '@',
          fillAttr: 'username',
          lookup: value =>
            value.type === groupType ? last(value.name.split(' / ')) : value.name + value.username,
          menuItemTemplate: autoCompleteMap[AutoComplete.Members].menuItemTemplate,
          values: this.getValues(AutoComplete.Members),
        },
        {
          trigger: '~',
          lookup: 'title',
          menuItemTemplate: autoCompleteMap[AutoComplete.Labels].menuItemTemplate,
          selectTemplate: ({ original }) =>
            NON_WORD_OR_INTEGER.test(original.title)
              ? `~"${escape(original.title)}"`
              : `~${escape(original.title)}`,
          values: this.getValues(AutoComplete.Labels),
        },
        {
          trigger: '!',
          lookup: value => value.iid + value.title,
          menuItemTemplate: autoCompleteMap[AutoComplete.MergeRequests].menuItemTemplate,
          selectTemplate: ({ original }) => original.reference || `!${original.iid}`,
          values: this.getValues(AutoComplete.MergeRequests),
        },
        {
          trigger: '%',
          lookup: 'title',
          menuItemTemplate: autoCompleteMap[AutoComplete.Milestones].menuItemTemplate,
          selectTemplate: ({ original }) => `%"${escape(original.title)}"`,
          values: this.getValues(AutoComplete.Milestones),
        },
      ],
    });

    const input = this.$slots.default?.[0]?.elm;
    this.tribute.attach(input);
  },
  beforeDestroy() {
    const input = this.$slots.default?.[0]?.elm;
    this.tribute.detach(input);
  },
  methods: {
    getValues(autoCompleteType) {
      return (inputText, processValues) => {
        if (this[autoCompleteType]) {
          const filteredValues = autoCompleteMap[autoCompleteType].filterValues.call(this);
          processValues(filteredValues);
        } else if (this.dataSources[autoCompleteType]) {
          axios
            .get(this.dataSources[autoCompleteType])
            .then(response => {
              this[autoCompleteType] = response.data;
              const filteredValues = autoCompleteMap[autoCompleteType].filterValues.call(this);
              processValues(filteredValues);
            })
            .catch(() => {});
        } else {
          processValues([]);
        }
      };
    },
  },
  render(createElement) {
    return createElement('div', this.$slots.default);
  },
};
</script>
