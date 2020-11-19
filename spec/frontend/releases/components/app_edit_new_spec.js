import Vuex from 'vuex';
import { mount } from '@vue/test-utils';
import { merge } from 'lodash';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { getJSONFixture } from 'helpers/fixtures';
import ReleaseEditNewApp from '~/releases/components/app_edit_new.vue';
import * as commonUtils from '~/lib/utils/common_utils';
import { BACK_URL_PARAM } from '~/releases/constants';
import AssetLinksForm from '~/releases/components/asset_links_form.vue';

const originalRelease = getJSONFixture('api/releases/release.json');
const originalMilestones = originalRelease.milestones;

describe('Release edit/new component', () => {
  let wrapper;
  let release;
  let actions;
  let getters;
  let state;
  let mock;

  const factory = async ({ featureFlags = {}, store: storeUpdates = {} } = {}) => {
    state = {
      release,
      markdownDocsPath: 'path/to/markdown/docs',
      releasesPagePath: 'path/to/releases/page',
      projectId: '8',
      groupId: '42',
      groupMilestonesAvailable: true,
    };

    actions = {
      initializeRelease: jest.fn(),
      saveRelease: jest.fn(),
      addEmptyAssetLink: jest.fn(),
    };

    getters = {
      isValid: () => true,
      isExistingRelease: () => true,
      validationErrors: () => ({
        assets: {
          links: [],
        },
      }),
    };

    const store = new Vuex.Store(
      merge(
        {
          modules: {
            detail: {
              namespaced: true,
              actions,
              state,
              getters,
            },
          },
        },
        storeUpdates,
      ),
    );

    wrapper = mount(ReleaseEditNewApp, {
      store,
      provide: {
        glFeatures: featureFlags,
      },
    });

    await wrapper.vm.$nextTick();

    wrapper.element.querySelectorAll('input').forEach(input => jest.spyOn(input, 'focus'));
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    gon.api_version = 'v4';

    mock.onGet('/api/v4/projects/8/milestones').reply(200, originalMilestones);

    release = commonUtils.convertObjectPropsToCamelCase(originalRelease, { deep: true });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findSubmitButton = () => wrapper.find('button[type=submit]');
  const findForm = () => wrapper.find('form');

  describe(`basic functionality tests: all tests unrelated to the "${BACK_URL_PARAM}" parameter`, () => {
    beforeEach(async () => {
      await factory();
    });

    it('calls initializeRelease when the component is created', () => {
      expect(actions.initializeRelease).toHaveBeenCalledTimes(1);
    });

    it('focuses the first non-disabled input element once the page is shown', () => {
      const firstEnabledInput = wrapper.element.querySelector('input:enabled');
      const allInputs = wrapper.element.querySelectorAll('input');

      allInputs.forEach(input => {
        const expectedFocusCalls = input === firstEnabledInput ? 1 : 0;
        expect(input.focus).toHaveBeenCalledTimes(expectedFocusCalls);
      });
    });

    it('renders the description text at the top of the page', () => {
      expect(wrapper.find('.js-subtitle-text').text()).toBe(
        'Releases are based on Git tags. We recommend tags that use semantic versioning, for example v1.0, v2.0-pre.',
      );
    });

    it('renders the correct release title in the "Release title" field', () => {
      expect(wrapper.find('#release-title').element.value).toBe(release.name);
    });

    it('renders the release notes in the "Release notes" textarea', () => {
      expect(wrapper.find('#release-notes').element.value).toBe(release.description);
    });

    it('renders the "Save changes" button as type="submit"', () => {
      expect(findSubmitButton().attributes('type')).toBe('submit');
    });

    it('calls saveRelease when the form is submitted', () => {
      findForm().trigger('submit');

      expect(actions.saveRelease).toHaveBeenCalledTimes(1);
    });
  });

  describe(`when the URL does not contain a "${BACK_URL_PARAM}" parameter`, () => {
    beforeEach(async () => {
      await factory();
    });

    it(`renders a "Cancel" button with an href pointing to "${BACK_URL_PARAM}"`, () => {
      const cancelButton = wrapper.find('.js-cancel-button');
      expect(cancelButton.attributes().href).toBe(state.releasesPagePath);
    });
  });

  describe(`when the URL contains a "${BACK_URL_PARAM}" parameter`, () => {
    const backUrl = 'https://example.gitlab.com/back/url';

    beforeEach(async () => {
      commonUtils.getParameterByName = jest
        .fn()
        .mockImplementation(paramToGet => ({ [BACK_URL_PARAM]: backUrl }[paramToGet]));

      await factory();
    });

    it('renders a "Cancel" button with an href pointing to the main Releases page', () => {
      const cancelButton = wrapper.find('.js-cancel-button');
      expect(cancelButton.attributes().href).toBe(backUrl);
    });
  });

  describe('when creating a new release', () => {
    beforeEach(async () => {
      await factory({
        store: {
          modules: {
            detail: {
              getters: {
                isExistingRelease: () => false,
              },
            },
          },
        },
      });
    });

    it('renders the submit button with the text "Create release"', () => {
      expect(findSubmitButton().text()).toBe('Create release');
    });
  });

  describe('when editing an existing release', () => {
    beforeEach(async () => {
      await factory();
    });

    it('renders the submit button with the text "Save changes"', () => {
      expect(findSubmitButton().text()).toBe('Save changes');
    });
  });

  describe('asset links form', () => {
    beforeEach(factory);

    it('renders the asset links portion of the form', () => {
      expect(wrapper.find(AssetLinksForm).exists()).toBe(true);
    });
  });

  describe('validation', () => {
    describe('when the form is valid', () => {
      beforeEach(async () => {
        await factory({
          store: {
            modules: {
              detail: {
                getters: {
                  isValid: () => true,
                },
              },
            },
          },
        });
      });

      it('renders the submit button as enabled', () => {
        expect(findSubmitButton().attributes('disabled')).toBeUndefined();
      });
    });

    describe('when the form is invalid', () => {
      beforeEach(async () => {
        await factory({
          store: {
            modules: {
              detail: {
                getters: {
                  isValid: () => false,
                },
              },
            },
          },
        });
      });

      it('renders the submit button as disabled', () => {
        expect(findSubmitButton().attributes('disabled')).toBe('disabled');
      });

      it('does not allow the form to be submitted', () => {
        findForm().trigger('submit');

        expect(actions.saveRelease).not.toHaveBeenCalled();
      });
    });
  });
});
