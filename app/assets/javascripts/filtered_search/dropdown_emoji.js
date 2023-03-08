import { createAlert } from '~/alert';
import { __ } from '~/locale';
import Ajax from './droplab/plugins/ajax';
import Filter from './droplab/plugins/filter';
import DropdownUtils from './dropdown_utils';
import FilteredSearchDropdown from './filtered_search_dropdown';

export default class DropdownEmoji extends FilteredSearchDropdown {
  constructor(options = {}) {
    super(options);
    this.config = {
      Ajax: {
        endpoint: `${gon.relative_url_root || ''}/-/autocomplete/award_emojis`,
        method: 'setData',
        loadingTemplate: this.loadingTemplate,
        onError() {
          createAlert({
            message: __('An error occurred fetching the dropdown data.'),
          });
        },
      },
      Filter: {
        template: 'name',
      },
    };

    import(/* webpackChunkName: 'emoji' */ '~/emoji')
      .then(({ glEmojiTag }) => {
        this.glEmojiTag = glEmojiTag;
      })
      .catch(() => {
        /* ignore error and leave emoji name in the search bar */
      });

    this.unbindEvents();
    this.bindEvents();
  }

  bindEvents() {
    super.bindEvents();

    this.listRenderedWrapper = this.listRendered.bind(this);
    this.dropdown.addEventListener('render.dl', this.listRenderedWrapper);
  }

  unbindEvents() {
    this.dropdown.removeEventListener('render.dl', this.listRenderedWrapper);
    super.unbindEvents();
  }

  listRendered() {
    this.replaceEmojiElement();
  }

  itemClicked(e) {
    super.itemClicked(e, (selected) => {
      const name = selected.querySelector('.js-data-value').innerText.trim();
      return DropdownUtils.getEscapedText(name);
    });
  }

  renderContent(forceShowList = false) {
    this.droplab.changeHookList(this.hookId, this.dropdown, [Ajax, Filter], this.config);
    super.renderContent(forceShowList);
  }

  replaceEmojiElement() {
    if (!this.glEmojiTag) return;

    // Replace empty gl-emoji tag to real content
    const dropdownItems = [...this.dropdown.querySelectorAll('.filter-dropdown-item')];
    dropdownItems.forEach((dropdownItem) => {
      const valueElement = dropdownItem.querySelector('.js-data-value');
      if (valueElement !== null) {
        const name = valueElement.innerText;
        const emojiTag = this.glEmojiTag(name);
        const emojiElement = dropdownItem.querySelector('gl-emoji');
        // eslint-disable-next-line no-unsanitized/property
        emojiElement.outerHTML = emojiTag;
      }
    });
  }

  init() {
    this.droplab.addHook(this.input, this.dropdown, [Ajax, Filter], this.config).init();
  }
}
