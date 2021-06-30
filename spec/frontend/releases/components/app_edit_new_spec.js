import { mount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { merge } from 'lodash';
import Vuex from 'vuex';
import { getJSONFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'helpers/test_constants';
import * as commonUtils from '~/lib/utils/common_utils';
import ReleaseEditNewApp from '~/releases/components/app_edit_new.vue';
import AssetLinksForm from '~/releases/components/asset_links_form.vue';
import { BACK_URL_PARAM } from '~/releases/constants';

const originalRelease = getJSONFixture('api/releases/release.json');
const originalMilestones = originalRelease.milestones;
const releasesPagePath = 'path/to/releases/page';

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
      releasesPagePath,
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
            editNew: {
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

    wrapper.element.querySelectorAll('input').forEach((input) => jest.spyOn(input, 'focus'));
  };

  beforeEach(() => {
    global.jsdom.reconfigure({ url: TEST_HOST });

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

      allInputs.forEach((input) => {
        const expectedFocusCalls = input === firstEnabledInput ? 1 : 0;
        expect(input.focus).toHaveBeenCalledTimes(expectedFocusCalls);
      });
    });

    it('renders the description text at the top of the page', () => {
      expect(wrapper.find('.js-subtitle-text').text()).toBe(
        'Releases are based on Git tags. We recommend tags that use semantic versioning, for example v1.0.0, v2.1.0-pre.',
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

  // eslint-disable-next-line no-script-url
  const xssBackUrl = 'javascript:alert(1)';
  describe.each`
    backUrl                            | expectedHref
    ${`${TEST_HOST}/back/url`}         | ${`${TEST_HOST}/back/url`}
    ${`/back/url?page=2`}              | ${`/back/url?page=2`}
    ${`back/url?page=3`}               | ${`back/url?page=3`}
    ${'http://phishing.test/back/url'} | ${releasesPagePath}
    ${'//phishing.test/back/url'}      | ${releasesPagePath}
    ${xssBackUrl}                      | ${releasesPagePath}
  `(
    `when the URL contains a "${BACK_URL_PARAM}=$backUrl" parameter`,
    ({ backUrl, expectedHref }) => {
      beforeEach(async () => {
        global.jsdom.reconfigure({
          url: `${TEST_HOST}?${BACK_URL_PARAM}=${encodeURIComponent(backUrl)}`,
        });

        await factory();
      });

      it(`renders a "Cancel" button with an href pointing to ${expectedHref}`, () => {
        const cancelButton = wrapper.find('.js-cancel-button');
        expect(cancelButton.attributes().href).toBe(expectedHref);
      });
    },
  );

  describe('when creating a new release', () => {
    beforeEach(async () => {
      await factory({
        store: {
          modules: {
            editNew: {
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
              editNew: {
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
              editNew: {
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
