import { escape } from 'lodash';
import labelData from 'test_fixtures/labels/project_labels.json';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import FilteredSearchSpecHelper from 'helpers/filtered_search_spec_helper';
import { TEST_HOST } from 'helpers/test_constants';
import DropdownUtils from '~/filtered_search/dropdown_utils';
import VisualTokenValue from '~/filtered_search/visual_token_value';
import { createAlert } from '~/alert';
import AjaxCache from '~/lib/utils/ajax_cache';
import UsersCache from '~/lib/utils/users_cache';

jest.mock('~/alert');

describe('Filtered Search Visual Tokens', () => {
  const findElements = (tokenElement) => {
    const tokenNameElement = tokenElement.querySelector('.name');
    const tokenValueContainer = tokenElement.querySelector('.value-container');
    const tokenValueElement = tokenValueContainer.querySelector('.value');
    const tokenOperatorElement = tokenElement.querySelector('.operator');
    const tokenType = tokenNameElement.innerText.toLowerCase();
    const tokenValue = tokenValueElement.innerText;
    const tokenOperator = tokenOperatorElement.innerText;
    const subject = new VisualTokenValue(tokenValue, tokenType, tokenOperator);
    return { subject, tokenValueContainer, tokenValueElement };
  };

  let tokensContainer;
  let authorToken;
  let bugLabelToken;

  beforeEach(() => {
    setHTMLFixture(`
      <ul class="tokens-container">
        ${FilteredSearchSpecHelper.createInputHTML()}
      </ul>
    `);
    tokensContainer = document.querySelector('.tokens-container');

    authorToken = FilteredSearchSpecHelper.createFilterVisualToken('author', '=', '@user');
    bugLabelToken = FilteredSearchSpecHelper.createFilterVisualToken('label', '=', '~bug');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('updateUserTokenAppearance', () => {
    let usersCacheSpy;

    beforeEach(() => {
      jest.spyOn(UsersCache, 'retrieve').mockImplementation((username) => usersCacheSpy(username));
    });

    it('ignores error if UsersCache throws', async () => {
      const dummyError = new Error('Earth rotated backwards');
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);
      const tokenValue = tokenValueElement.innerText;
      usersCacheSpy = (username) => {
        expect(`@${username}`).toBe(tokenValue);
        return Promise.reject(dummyError);
      };

      await subject.updateUserTokenAppearance(tokenValueContainer, tokenValueElement, tokenValue);
      expect(createAlert).toHaveBeenCalledTimes(0);
    });

    it('does nothing if user cannot be found', async () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);
      const tokenValue = tokenValueElement.innerText;
      usersCacheSpy = (username) => {
        expect(`@${username}`).toBe(tokenValue);
        return Promise.resolve(undefined);
      };

      await subject.updateUserTokenAppearance(tokenValueContainer, tokenValueElement, tokenValue);
      expect(tokenValueElement.innerText).toBe(tokenValue);
    });

    it('replaces author token with avatar and display name', async () => {
      const dummyUser = {
        name: 'Important Person',
        avatar_url: `${TEST_HOST}/mypics/avatar.png`,
      };
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);
      const tokenValue = tokenValueElement.innerText;
      usersCacheSpy = (username) => {
        expect(`@${username}`).toBe(tokenValue);
        return Promise.resolve(dummyUser);
      };

      await subject.updateUserTokenAppearance(tokenValueContainer, tokenValueElement, tokenValue);
      expect(tokenValueContainer.dataset.originalValue).toBe(tokenValue);
      expect(tokenValueElement.innerText.trim()).toBe(dummyUser.name);
      const avatar = tokenValueElement.querySelector('img.avatar');

      expect(avatar.getAttribute('src')).toBe(dummyUser.avatar_url);
      expect(avatar.getAttribute('alt')).toBe('');
    });

    it('escapes user name when creating token', async () => {
      const dummyUser = {
        name: '<script>',
        avatar_url: `${TEST_HOST}/mypics/avatar.png`,
      };
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);
      const tokenValue = tokenValueElement.innerText;
      usersCacheSpy = (username) => {
        expect(`@${username}`).toBe(tokenValue);
        return Promise.resolve(dummyUser);
      };

      await subject.updateUserTokenAppearance(tokenValueContainer, tokenValueElement, tokenValue);
      expect(tokenValueElement.innerText.trim()).toBe(dummyUser.name);
      tokenValueElement.querySelector('.avatar').remove();

      expect(tokenValueElement.innerHTML.trim()).toBe(escape(dummyUser.name));
    });
  });

  describe('updateLabelTokenColor', () => {
    const dummyEndpoint = '/dummy/endpoint';

    const missingLabelToken = FilteredSearchSpecHelper.createFilterVisualToken(
      'label',
      '=',
      '~doesnotexist',
    );
    const spaceLabelToken = FilteredSearchSpecHelper.createFilterVisualToken(
      'label',
      '=',
      '~"some space"',
    );

    beforeEach(() => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
        ${bugLabelToken.outerHTML}
        ${missingLabelToken.outerHTML}
        ${spaceLabelToken.outerHTML}
      `);

      const filteredSearchInput = document.querySelector('.filtered-search');
      filteredSearchInput.dataset.runnerTagsEndpoint = `${dummyEndpoint}/admin/runners/tag_list`;
      filteredSearchInput.dataset.labelsEndpoint = `${dummyEndpoint}/-/labels`;
      filteredSearchInput.dataset.milestonesEndpoint = `${dummyEndpoint}/-/milestones`;

      AjaxCache.internalStorage = {};
      AjaxCache.internalStorage[`${filteredSearchInput.dataset.labelsEndpoint}.json`] = labelData;
    });

    const parseColor = (color) => {
      const dummyElement = document.createElement('div');
      dummyElement.style.color = color;
      return dummyElement.style.color;
    };

    const expectValueContainerStyle = (tokenValueContainer, label) => {
      expect(tokenValueContainer.getAttribute('style')).not.toBe(null);
      expect(tokenValueContainer.style.backgroundColor).toBe(parseColor(label.color));
      expect(tokenValueContainer.style.color).toBe(parseColor(label.text_color));
    };

    const findLabel = (tokenValue) =>
      labelData.find((label) => tokenValue === `~${DropdownUtils.getEscapedText(label.title)}`);

    it('updates the color of a label token', async () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(bugLabelToken);
      const tokenValue = tokenValueElement.innerText;
      const matchingLabel = findLabel(tokenValue);

      await subject.updateLabelTokenColor(tokenValueContainer, tokenValue);
      expectValueContainerStyle(tokenValueContainer, matchingLabel);
    });

    it('updates the color of a label token with spaces', async () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(spaceLabelToken);
      const tokenValue = tokenValueElement.innerText;
      const matchingLabel = findLabel(tokenValue);

      await subject.updateLabelTokenColor(tokenValueContainer, tokenValue);
      expectValueContainerStyle(tokenValueContainer, matchingLabel);
    });

    it('does not change color of a missing label', async () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(missingLabelToken);
      const tokenValue = tokenValueElement.innerText;
      const matchingLabel = findLabel(tokenValue);

      expect(matchingLabel).toBe(undefined);

      await subject.updateLabelTokenColor(tokenValueContainer, tokenValue);
      expect(tokenValueContainer.getAttribute('style')).toBe(null);
    });
  });

  describe('setTokenStyle', () => {
    let originalTextColor;

    beforeEach(() => {
      originalTextColor = bugLabelToken.style.color;
    });

    it('should set backgroundColor', () => {
      const originalBackgroundColor = bugLabelToken.style.backgroundColor;
      const token = VisualTokenValue.setTokenStyle(bugLabelToken, 'blue', 'white');

      expect(token.style.backgroundColor).toEqual('blue');
      expect(token.style.backgroundColor).not.toEqual(originalBackgroundColor);
    });

    it('should set textColor', () => {
      const token = VisualTokenValue.setTokenStyle(bugLabelToken, 'white', 'black');

      expect(token.style.color).toEqual('black');
      expect(token.style.color).not.toEqual(originalTextColor);
    });

    it('should set the color of the remove token close icon to the label text color', () => {
      const token = VisualTokenValue.setTokenStyle(bugLabelToken, 'black', '#FFFFFF');
      const removeIcon = token.querySelector('.close-icon');

      expect(removeIcon.style.color).toEqual('rgb(255, 255, 255)');
    });
  });

  describe('render', () => {
    const setupSpies = (subject) => {
      jest.spyOn(subject, 'updateLabelTokenColor').mockImplementation(() => {});
      const updateLabelTokenColorSpy = subject.updateLabelTokenColor;

      jest.spyOn(subject, 'updateUserTokenAppearance').mockImplementation(() => {});
      const updateUserTokenAppearanceSpy = subject.updateUserTokenAppearance;

      return { updateLabelTokenColorSpy, updateUserTokenAppearanceSpy };
    };

    const keywordToken = FilteredSearchSpecHelper.createFilterVisualToken('search');
    const milestoneToken = FilteredSearchSpecHelper.createFilterVisualToken(
      'milestone',
      'upcoming',
    );

    beforeEach(() => {
      tokensContainer.innerHTML = FilteredSearchSpecHelper.createTokensContainerHTML(`
        ${authorToken.outerHTML}
        ${bugLabelToken.outerHTML}
        ${keywordToken.outerHTML}
        ${milestoneToken.outerHTML}
      `);
    });

    it('renders a author token value element', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);

      const { updateLabelTokenColorSpy, updateUserTokenAppearanceSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateUserTokenAppearanceSpy.mock.calls.length).toBe(1);
      const expectedArgs = [tokenValueContainer, tokenValueElement];

      expect(updateUserTokenAppearanceSpy.mock.calls[0]).toEqual(expectedArgs);
      expect(updateLabelTokenColorSpy.mock.calls.length).toBe(0);
    });

    it('renders a label token value element', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(bugLabelToken);

      const { updateLabelTokenColorSpy, updateUserTokenAppearanceSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateLabelTokenColorSpy.mock.calls.length).toBe(1);
      const expectedArgs = [tokenValueContainer];

      expect(updateLabelTokenColorSpy.mock.calls[0]).toEqual(expectedArgs);
      expect(updateUserTokenAppearanceSpy.mock.calls.length).toBe(0);
    });

    it('renders a milestone token value element', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(milestoneToken);

      const { updateLabelTokenColorSpy, updateUserTokenAppearanceSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateLabelTokenColorSpy.mock.calls.length).toBe(0);
      expect(updateUserTokenAppearanceSpy.mock.calls.length).toBe(0);
    });

    it('does not update user token appearance for `none` filter', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);

      subject.tokenValue = 'none';

      const { updateUserTokenAppearanceSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateUserTokenAppearanceSpy.mock.calls.length).toBe(0);
    });

    it('does not update user token appearance for `None` filter', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);

      subject.tokenValue = 'None';

      const { updateUserTokenAppearanceSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateUserTokenAppearanceSpy.mock.calls.length).toBe(0);
    });

    it('does not update user token appearance for `any` filter', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(authorToken);

      subject.tokenValue = 'any';

      const { updateUserTokenAppearanceSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateUserTokenAppearanceSpy.mock.calls.length).toBe(0);
    });

    it('does not update label token color for `None` filter', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(bugLabelToken);

      subject.tokenValue = 'None';

      const { updateLabelTokenColorSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateLabelTokenColorSpy.mock.calls.length).toBe(0);
    });

    it('does not update label token color for `none` filter', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(bugLabelToken);

      subject.tokenValue = 'none';

      const { updateLabelTokenColorSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateLabelTokenColorSpy.mock.calls.length).toBe(0);
    });

    it('does not update label token color for `any` filter', () => {
      const { subject, tokenValueContainer, tokenValueElement } = findElements(bugLabelToken);

      subject.tokenValue = 'any';

      const { updateLabelTokenColorSpy } = setupSpies(subject);
      subject.render(tokenValueContainer, tokenValueElement);

      expect(updateLabelTokenColorSpy.mock.calls.length).toBe(0);
    });
  });
});
