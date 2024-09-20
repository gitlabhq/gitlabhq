import { escape } from 'lodash';
import { USER_TOKEN_TYPES } from 'ee_else_ce/filtered_search/constants';
import * as Emoji from '~/emoji';
import FilteredSearchContainer from '~/filtered_search/container';
import DropdownUtils from '~/filtered_search/dropdown_utils';
import FilteredSearchVisualTokens from '~/filtered_search/filtered_search_visual_tokens';
import { createAlert } from '~/alert';
import AjaxCache from '~/lib/utils/ajax_cache';
import UsersCache from '~/lib/utils/users_cache';
import { __ } from '~/locale';
import { TOKEN_TYPE_LABEL } from '~/vue_shared/components/filtered_search_bar/constants';

export default class VisualTokenValue {
  constructor(tokenValue, tokenType, tokenOperator) {
    this.tokenValue = tokenValue;
    this.tokenType = tokenType;
    this.tokenOperator = tokenOperator;
  }

  render(tokenValueContainer, tokenValueElement) {
    const { tokenType, tokenValue } = this;

    if (['none', 'any'].includes(tokenValue.toLowerCase())) {
      return;
    }

    if (tokenType === TOKEN_TYPE_LABEL) {
      this.updateLabelTokenColor(tokenValueContainer);
    } else if (USER_TOKEN_TYPES.includes(tokenType)) {
      this.updateUserTokenAppearance(tokenValueContainer, tokenValueElement);
    } else if (tokenType === 'my-reaction') {
      this.updateEmojiTokenAppearance(tokenValueContainer, tokenValueElement);
    } else if (tokenType === 'epic') {
      this.updateEpicLabel(tokenValueContainer, tokenValueElement);
    }
  }

  updateUserTokenAppearance(tokenValueContainer, tokenValueElement) {
    const { tokenValue } = this;
    const username = this.tokenValue.replace(/^@/, '');

    return (
      UsersCache.retrieve(username)
        .then((user) => {
          if (!user) {
            return;
          }

          /* eslint-disable no-param-reassign */
          tokenValueContainer.dataset.originalValue = tokenValue;
          // eslint-disable-next-line no-unsanitized/property
          tokenValueElement.innerHTML = `
          <img class="avatar s16 !gl-mr-2" src="${user.avatar_url}" alt="">
          ${escape(user.name)}
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
      .then((labels) => {
        const matchingLabel = (labels || []).find(
          (label) => `~${DropdownUtils.getEscapedText(label.title)}` === tokenValue,
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
      .catch(() =>
        createAlert({
          message: __('An error occurred while fetching label colors.'),
        }),
      );
  }

  updateEpicLabel(tokenValueContainer) {
    const tokenValue = this.tokenValue.replace(/^&/, '');
    const filteredSearchInput = FilteredSearchContainer.container.querySelector('.filtered-search');
    const { epicsEndpoint } = filteredSearchInput.dataset;
    const epicsEndpointWithParams = FilteredSearchVisualTokens.getEndpointWithQueryParams(
      `${epicsEndpoint}.json`,
      filteredSearchInput.dataset.endpointQueryParams,
    );

    return AjaxCache.retrieve(epicsEndpointWithParams)
      .then((epics) => {
        const matchingEpic = (epics || []).find((epic) => epic.id === Number(tokenValue));

        if (!matchingEpic) {
          return;
        }

        VisualTokenValue.replaceEpicTitle(tokenValueContainer, matchingEpic.title, matchingEpic.id);
      })
      .catch(() =>
        createAlert({
          message: __('An error occurred while adding formatted title for epic'),
        }),
      );
  }

  static replaceEpicTitle(tokenValueContainer, epicTitle, epicId) {
    const tokenContainer = tokenValueContainer;

    const valueContainer = tokenContainer.querySelector('.value');

    if (valueContainer) {
      tokenContainer.dataset.originalValue = valueContainer.innerText;
      valueContainer.innerText = `"${epicTitle}"::&${epicId}`;
    }
  }

  static setTokenStyle(tokenValueContainer, backgroundColor, textColor) {
    const token = tokenValueContainer;

    token.style.backgroundColor = backgroundColor;
    token.style.color = textColor;
    const removeToken = token.querySelector('.close-icon');
    removeToken.style.color = textColor;

    return token;
  }

  updateEmojiTokenAppearance(tokenValueContainer, tokenValueElement) {
    const container = tokenValueContainer;
    const element = tokenValueElement;
    const value = this.tokenValue;

    return Emoji.initEmojiMap().then(() => {
      if (!Emoji.isEmojiNameValid(value)) {
        return;
      }

      container.dataset.originalValue = value;
      // eslint-disable-next-line no-unsanitized/property
      element.innerHTML = Emoji.glEmojiTag(value);
    });
  }
}
