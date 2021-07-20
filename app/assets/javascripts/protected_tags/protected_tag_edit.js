import createFlash from '~/flash';
import axios from '../lib/utils/axios_utils';
import { FAILED_TO_UPDATE_TAG_MESSAGE } from './constants';
import ProtectedTagAccessDropdown from './protected_tag_access_dropdown';

export default class ProtectedTagEdit {
  constructor(options) {
    this.$wrap = options.$wrap;
    this.$allowedToCreateDropdownButton = this.$wrap.find('.js-allowed-to-create');
    this.onSelectCallback = this.onSelect.bind(this);

    this.buildDropdowns();
  }

  buildDropdowns() {
    // Allowed to create dropdown
    this.protectedTagAccessDropdown = new ProtectedTagAccessDropdown({
      $dropdown: this.$allowedToCreateDropdownButton,
      data: gon.create_access_levels,
      onSelect: this.onSelectCallback,
    });
  }

  onSelect() {
    const $allowedToCreateInput = this.$wrap.find(
      `input[name="${this.$allowedToCreateDropdownButton.data('fieldName')}"]`,
    );

    // Do not update if one dropdown has not selected any option
    if (!$allowedToCreateInput.length) return;

    this.$allowedToCreateDropdownButton.disable();

    axios
      .patch(this.$wrap.data('url'), {
        protected_tag: {
          create_access_levels_attributes: [
            {
              id: this.$allowedToCreateDropdownButton.data('accessLevelId'),
              access_level: $allowedToCreateInput.val(),
            },
          ],
        },
      })
      .then(() => {
        this.$allowedToCreateDropdownButton.enable();
      })
      .catch(() => {
        this.$allowedToCreateDropdownButton.enable();

        window.scrollTo({ top: 0, behavior: 'smooth' });
        createFlash({
          message: FAILED_TO_UPDATE_TAG_MESSAGE,
        });
      });
  }
}
