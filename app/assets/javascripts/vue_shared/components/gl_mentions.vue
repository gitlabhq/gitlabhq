<script>
import { escape } from 'lodash';
import Tribute from 'tributejs';
import axios from '~/lib/utils/axios_utils';
import { spriteIcon } from '~/lib/utils/common_utils';

/**
 * Creates the HTML template for each row of the mentions dropdown.
 *
 * @param original An object from the array returned from the `autocomplete_sources/members` API
 * @returns {string} An HTML template
 */
function menuItemTemplate({ original }) {
  const rectAvatarClass = original.type === 'Group' ? 'rect-avatar' : '';

  const avatarClasses = `avatar avatar-inline center s26 ${rectAvatarClass}
    gl-display-inline-flex gl-align-items-center gl-justify-content-center`;

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
}

export default {
  name: 'GlMentions',
  props: {
    dataSources: {
      type: Object,
      required: false,
      default: () => gl.GfmAutoComplete?.dataSources || {},
    },
  },
  data() {
    return {
      members: undefined,
    };
  },
  mounted() {
    this.tribute = new Tribute({
      trigger: '@',
      fillAttr: 'username',
      lookup: value => value.name + value.username,
      menuItemTemplate,
      values: this.getMembers,
    });

    const input = this.$slots.default[0].elm;
    this.tribute.attach(input);
  },
  beforeDestroy() {
    const input = this.$slots.default[0].elm;
    this.tribute.detach(input);
  },
  methods: {
    /**
     * Creates the list of users to show in the mentions dropdown.
     *
     * @param inputText - The text entered by the user in the mentions input field
     * @param processValues - Callback function to set the list of users to show in the mentions dropdown
     */
    getMembers(inputText, processValues) {
      if (this.members) {
        processValues(this.members);
      } else if (this.dataSources.members) {
        axios
          .get(this.dataSources.members)
          .then(response => {
            this.members = response.data;
            processValues(response.data);
          })
          .catch(() => {});
      } else {
        processValues([]);
      }
    },
  },
  render(createElement) {
    return createElement('div', this.$slots.default);
  },
};
</script>
