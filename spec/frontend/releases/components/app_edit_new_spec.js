import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { merge } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { nextTick } from 'vue';
import { GlDatepicker, GlFormCheckbox } from '@gitlab/ui';
import originalOneReleaseForEditingQueryResponse from 'test_fixtures/graphql/releases/graphql/queries/one_release_for_editing.query.graphql.json';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { convertOneReleaseGraphQLResponse } from '~/releases/util';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import ReleaseEditNewApp from '~/releases/components/app_edit_new.vue';
import { putCreateReleaseNotification } from '~/releases/release_notification_service';
import AssetLinksForm from '~/releases/components/asset_links_form.vue';
import ConfirmDeleteModal from '~/releases/components/confirm_delete_modal.vue';
import { BACK_URL_PARAM } from '~/releases/constants';
import { ValidationResult } from '~/lib/utils/ref_validator';

const originalRelease = originalOneReleaseForEditingQueryResponse.data.project.release;
const originalMilestones = originalRelease.milestones;
const releasesPagePath = 'path/to/releases/page';
const upcomingReleaseDocsPath = 'path/to/upcoming/release/docs';
const projectPath = 'project/path';
jest.mock('~/releases/release_notification_service');

describe('Release edit/new component', () => {
  let wrapper;
  let release;
  let actions;
  let getters;
  let state;
  let refActions;
  let refState;
  let mock;

  const factory = async ({ featureFlags = {}, store: storeUpdates = {} } = {}) => {
    state = {
      release,
      isExistingRelease: true,
      projectPath,
      markdownPreviewPath: 'path/to/markdown/preview',
      markdownDocsPath: 'path/to/markdown/docs',
      releasesPagePath,
      projectId: '8',
      groupId: '42',
      groupMilestonesAvailable: true,
      upcomingReleaseDocsPath,
    };

    actions = {
      initializeRelease: jest.fn(),
      saveRelease: jest.fn(),
      addEmptyAssetLink: jest.fn(),
      deleteRelease: jest.fn(),
      updateReleaseNotes: jest.fn(),
    };

    getters = {
      isValid: () => true,
      validationErrors: () => ({
        assets: {
          links: [],
        },
        tagNameValidation: new ValidationResult(),
      }),
      formattedReleaseNotes: () => 'these notes are formatted',
      isCreating: jest.fn(),
      isSearching: jest.fn(),
      isExistingTag: jest.fn(),
      isNewTag: jest.fn(),
    };

    refState = {
      matches: [],
    };

    refActions = {
      setEnabledRefTypes: jest.fn(),
      setProjectId: jest.fn(),
      search: jest.fn(),
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
            ref: {
              namespaced: true,
              actions: refActions,
              state: refState,
            },
          },
        },
        storeUpdates,
      ),
    );

    wrapper = mountExtended(ReleaseEditNewApp, {
      store,
      provide: {
        glFeatures: featureFlags,
      },
    });

    await nextTick();

    wrapper.element.querySelectorAll('input').forEach((input) => jest.spyOn(input, 'focus'));
  };

  beforeEach(() => {
    setWindowLocation(TEST_HOST);

    mock = new MockAdapter(axios);
    gon.api_version = 'v4';

    mock.onGet('/api/v4/projects/8/milestones').reply(HTTP_STATUS_OK, originalMilestones);

    release = convertOneReleaseGraphQLResponse(originalOneReleaseForEditingQueryResponse).data;
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
        'Releases are based on Git tags. We recommend tags that use semantic versioning, for example 1.0.0, 2.1.0-pre.',
      );
    });

    it('renders the correct release title in the "Release title" field', () => {
      expect(wrapper.find('#release-title').element.value).toBe(release.name);
    });

    it('renders the released at date in the "Released at" datepicker', () => {
      expect(wrapper.findComponent(GlDatepicker).props('value')).toBe(release.releasedAt);
    });

    it('links to the documentation on upcoming releases in the "Released at" description', () => {
      const link = wrapper.findByRole('link', { name: 'Upcoming Release' });

      expect(link.exists()).toBe(true);

      expect(link.attributes('href')).toBe(upcomingReleaseDocsPath);
    });

    it('renders the release notes in the "Release notes" textarea', () => {
      expect(wrapper.find('#release-notes').element.value).toBe(release.description);
    });

    it('renders the "Save changes" button as type="submit"', () => {
      expect(findSubmitButton().attributes('type')).toBe('submit');
    });

    it('allows switching to rich text editor', () => {
      expect(wrapper.html()).toContain('Switch to rich text editing');
    });

    it('calls saveRelease when the form is submitted', () => {
      findForm().trigger('submit');

      expect(actions.saveRelease).toHaveBeenCalledTimes(1);
    });

    it('sets release created notification when the form is submitted', () => {
      findForm().trigger('submit');
      const releaseName = originalOneReleaseForEditingQueryResponse.data.project.release.name;
      expect(putCreateReleaseNotification).toHaveBeenCalledTimes(1);
      expect(putCreateReleaseNotification).toHaveBeenCalledWith(projectPath, releaseName);
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
        setWindowLocation(`${TEST_HOST}?${BACK_URL_PARAM}=${encodeURIComponent(backUrl)}`);

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
              state: { isExistingRelease: false },
            },
          },
        },
      });
    });

    it('renders the submit button with the text "Create release"', () => {
      expect(findSubmitButton().text()).toBe('Create release');
    });

    it('renders a checkbox to include release notes', () => {
      expect(wrapper.findComponent(GlFormCheckbox).exists()).toBe(true);
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
      expect(wrapper.findComponent(AssetLinksForm).exists()).toBe(true);
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
        expect(findSubmitButton().attributes('disabled')).toBeDefined();
      });

      it('does not allow the form to be submitted', () => {
        findForm().trigger('submit');

        expect(actions.saveRelease).not.toHaveBeenCalled();
      });
    });

    describe('when tag notes are loading', () => {
      beforeEach(async () => {
        await factory({
          store: {
            modules: {
              editNew: {
                state: {
                  isFetchingTagNotes: true,
                },
              },
            },
          },
        });
      });
      it('renders the submit button as disabled', () => {
        expect(findSubmitButton().attributes('disabled')).toBeDefined();
      });
    });
  });

  describe('delete', () => {
    const findConfirmDeleteModal = () => wrapper.findComponent(ConfirmDeleteModal);

    it('calls the deleteRelease action on confirmation', async () => {
      await factory();
      findConfirmDeleteModal().vm.$emit('delete');

      expect(actions.deleteRelease).toHaveBeenCalled();
    });

    it('is hidden if this is a new release', async () => {
      await factory({
        store: {
          modules: {
            editNew: {
              state: {
                isExistingRelease: false,
              },
            },
          },
        },
      });

      expect(findConfirmDeleteModal().exists()).toBe(false);
    });
  });
});
