import Vuex from 'vuex';
import { mount } from '@vue/test-utils';
import ReleaseEditApp from '~/releases/components/app_edit.vue';
import { release as originalRelease } from '../mock_data';
import * as commonUtils from '~/lib/utils/common_utils';
import { BACK_URL_PARAM } from '~/releases/constants';

describe('Release edit component', () => {
  let wrapper;
  let release;
  let actions;
  let state;

  const factory = () => {
    state = {
      release,
      markdownDocsPath: 'path/to/markdown/docs',
      updateReleaseApiDocsPath: 'path/to/update/release/api/docs',
      releasesPagePath: 'path/to/releases/page',
    };

    actions = {
      fetchRelease: jest.fn(),
      updateRelease: jest.fn(),
    };

    const store = new Vuex.Store({
      modules: {
        detail: {
          namespaced: true,
          actions,
          state,
        },
      },
    });

    wrapper = mount(ReleaseEditApp, {
      store,
    });
  };

  beforeEach(() => {
    gon.api_version = 'v4';

    release = commonUtils.convertObjectPropsToCamelCase(originalRelease, { deep: true });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe(`basic functionality tests: all tests unrelated to the "${BACK_URL_PARAM}" parameter`, () => {
    beforeEach(() => {
      factory();
    });

    it('calls fetchRelease when the component is created', () => {
      expect(actions.fetchRelease).toHaveBeenCalledTimes(1);
    });

    it('renders the description text at the top of the page', () => {
      expect(wrapper.find('.js-subtitle-text').text()).toBe(
        'Releases are based on Git tags. We recommend naming tags that fit within semantic versioning, for example v1.0, v2.0-pre.',
      );
    });

    it('renders the correct tag name in the "Tag name" field', () => {
      expect(wrapper.find('#git-ref').element.value).toBe(release.tagName);
    });

    it('renders the correct help text under the "Tag name" field', () => {
      const helperText = wrapper.find('#tag-name-help');
      const helperTextLink = helperText.find('a');
      const helperTextLinkAttrs = helperTextLink.attributes();

      expect(helperText.text()).toBe(
        'Changing a Release tag is only supported via Releases API. More information',
      );
      expect(helperTextLink.text()).toBe('More information');
      expect(helperTextLinkAttrs).toEqual(
        expect.objectContaining({
          href: state.updateReleaseApiDocsPath,
          rel: 'noopener noreferrer',
          target: '_blank',
        }),
      );
    });

    it('renders the correct release title in the "Release title" field', () => {
      expect(wrapper.find('#release-title').element.value).toBe(release.name);
    });

    it('renders the release notes in the "Release notes" textarea', () => {
      expect(wrapper.find('#release-notes').element.value).toBe(release.description);
    });

    it('renders the "Save changes" button as type="submit"', () => {
      expect(wrapper.find('.js-submit-button').attributes('type')).toBe('submit');
    });

    it('calls updateRelease when the form is submitted', () => {
      wrapper.find('form').trigger('submit');
      expect(actions.updateRelease).toHaveBeenCalledTimes(1);
    });
  });

  describe(`when the URL does not contain a "${BACK_URL_PARAM}" parameter`, () => {
    beforeEach(() => {
      factory();
    });

    it(`renders a "Cancel" button with an href pointing to "${BACK_URL_PARAM}"`, () => {
      const cancelButton = wrapper.find('.js-cancel-button');
      expect(cancelButton.attributes().href).toBe(state.releasesPagePath);
    });
  });

  describe(`when the URL contains a "${BACK_URL_PARAM}" parameter`, () => {
    const backUrl = 'https://example.gitlab.com/back/url';

    beforeEach(() => {
      commonUtils.getParameterByName = jest
        .fn()
        .mockImplementation(paramToGet => ({ [BACK_URL_PARAM]: backUrl }[paramToGet]));

      factory();
    });

    it('renders a "Cancel" button with an href pointing to the main Releases page', () => {
      const cancelButton = wrapper.find('.js-cancel-button');
      expect(cancelButton.attributes().href).toBe(backUrl);
    });
  });
});
