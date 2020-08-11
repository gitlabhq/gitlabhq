<script>
import { escape } from 'lodash';
import Tribute from 'tributejs';
import axios from '~/lib/utils/axios_utils';
import { spriteIcon } from '~/lib/utils/common_utils';
import SidebarMediator from '~/sidebar/sidebar_mediator';

const AutoComplete = {
  Labels: 'labels',
  Members: 'members',
};

function doesCurrentLineStartWith(searchString, fullText, selectionStart) {
  const currentLineNumber = fullText.slice(0, selectionStart).split('\n').length;
  const currentLine = fullText.split('\n')[currentLineNumber - 1];
  return currentLine.startsWith(searchString);
}

const autoCompleteMap = {
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
      const rectAvatarClass = original.type === 'Group' ? 'rect-avatar' : '';

      const avatarClasses = `avatar avatar-inline center s26 ${rectAvatarClass}
        gl-display-inline-flex! gl-align-items-center gl-justify-content-center`;

      const avatarTag = original.avatar_url
        ? `<img
            src="${original.avatar_url}"
            alt="${original.username}'s avatar"
            class="${avatarClasses}"/>`
        : `<div class="${avatarClasses}">${original.username.charAt(0).toUpperCase()}</div>`;

      const name = escape(original.name);

      const count = original.count && !original.mentionsDisabled ? ` (${original.count})` : '';

      const icon = original.mentionsDisabled
        ? spriteIcon('notifications-off', 's16 gl-vertical-align-middle gl-ml-3')
        : '';

      return `${avatarTag}
        ${original.username}
        <small class="gl-text-small gl-font-weight-normal gl-reset-color">${name}${count}</small>
        ${icon}`;
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
          trigger: '@',
          fillAttr: 'username',
          lookup: value => value.name + value.username,
          menuItemTemplate: autoCompleteMap[AutoComplete.Members].menuItemTemplate,
          values: this.getValues(AutoComplete.Members),
        },
        {
          trigger: '~',
          lookup: 'title',
          menuItemTemplate: autoCompleteMap[AutoComplete.Labels].menuItemTemplate,
          selectTemplate: ({ original }) =>
            NON_WORD_OR_INTEGER.test(original.title)
              ? `~"${original.title}"`
              : `~${original.title}`,
          values: this.getValues(AutoComplete.Labels),
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
