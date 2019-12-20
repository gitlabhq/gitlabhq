import _ from 'underscore';
import { USER_TOKEN_TYPES } from 'ee_else_ce/filtered_search/constants';
import FilteredSearchContainer from '~/filtered_search/container';
import FilteredSearchVisualTokens from '~/filtered_search/filtered_search_visual_tokens';
import AjaxCache from '~/lib/utils/ajax_cache';
import DropdownUtils from '~/filtered_search/dropdown_utils';
import Flash from '~/flash';
import UsersCache from '~/lib/utils/users_cache';
import { __ } from '~/locale';

export default class VisualTokenValue {
  constructor(tokenValue, tokenType) {
    this.tokenValue = tokenValue;
    this.tokenType = tokenType;
  }

  render(tokenValueContainer, tokenValueElement) {
    const { tokenType, tokenValue } = this;

    if (['none', 'any'].includes(tokenValue.toLowerCase())) {
      return;
    }

    if (tokenType === 'label') {
      this.updateLabelTokenColor(tokenValueContainer);
    } else if (USER_TOKEN_TYPES.includes(tokenType)) {
      this.updateUserTokenAppearance(tokenValueContainer, tokenValueElement);
    } else if (tokenType === 'my-reaction') {
      this.updateEmojiTokenAppearance(tokenValueContainer, tokenValueElement);
    }
  }

  updateUserTokenAppearance(tokenValueContainer, tokenValueElement) {
    const { tokenValue } = this;
    const username = this.tokenValue.replace(/^@/, '');

    return (
      UsersCache.retrieve(username)
        .then(user => {
          if (!user) {
            return;
          }

          /* eslint-disable no-param-reassign */
          tokenValueContainer.dataset.originalValue = tokenValue;
          tokenValueElement.innerHTML = `
          <img class="avatar s20" src="${user.avatar_url}" alt="">
          ${_.escape(user.name)}
        `;
          /* eslint-enable no-param-reassign */
        })
        // ignore error and leave username in the search bar
        .catch(() => {})
    );
  }

  updateLabelTokenColor(tokenValueContainer) {
    const { tokenValue } = this;
    const filteredSearchInput = FilteredSearchContainer.container.querySelector('.filtered-search');
    const { labelsEndpoint } = filteredSearchInput.dataset;
    const labelsEndpointWithParams = FilteredSearchVisualTokens.getEndpointWithQueryParams(
      `${labelsEndpoint}.json`,
      filteredSearchInput.dataset.endpointQueryParams,
    );

    return AjaxCache.retrieve(labelsEndpointWithParams)
      .then(labels => {
        const matchingLabel = (labels || []).find(
          label => `~${DropdownUtils.getEscapedText(label.title)}` === tokenValue,
        );

        if (!matchingLabel) {
          return;
        }

        VisualTokenValue.setTokenStyle(
          tokenValueContainer,
          matchingLabel.color,
          matchingLabel.text_color,
        );
      })
      .catch(() => new Flash(__('An error occurred while fetching label colors.')));
  }

  static setTokenStyle(tokenValueContainer, backgroundColor, textColor) {
    const token = tokenValueContainer;

    token.style.backgroundColor = backgroundColor;
    token.style.color = textColor;

    if (textColor === '#FFFFFF') {
      const removeToken = token.querySelector('.remove-token');
      removeToken.classList.add('inverted');
    }

    return token;
  }

  updateEmojiTokenAppearance(tokenValueContainer, tokenValueElement) {
    const container = tokenValueContainer;
    const element = tokenValueElement;
    const value = this.tokenValue;

    return (
      import(/* webpackChunkName: 'emoji' */ '../emoji')
        .then(Emoji => {
          if (!Emoji.isEmojiNameValid(value)) {
            return;
          }

          container.dataset.originalValue = value;
          element.innerHTML = Emoji.glEmojiTag(value);
        })
        // ignore error and leave emoji name in the search bar
        .catch(() => {})
    );
  }
}
