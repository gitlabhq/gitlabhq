import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import AssetLinksForm from '~/releases/components/asset_links_form.vue';
import { release as originalRelease } from '../mock_data';
import * as commonUtils from '~/lib/utils/common_utils';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Release edit component', () => {
  let wrapper;
  let release;
  let actions;
  let getters;
  let state;

  const factory = ({ release: overriddenRelease, linkErrors } = {}) => {
    state = {
      release: overriddenRelease || release,
      releaseAssetsDocsPath: 'path/to/release/assets/docs',
    };

    actions = {
      addEmptyAssetLink: jest.fn(),
      updateAssetLinkUrl: jest.fn(),
      updateAssetLinkName: jest.fn(),
      removeAssetLink: jest.fn().mockImplementation((_context, linkId) => {
        state.release.assets.links = state.release.assets.links.filter(l => l.id !== linkId);
      }),
    };

    getters = {
      validationErrors: () => ({
        assets: {
          links: linkErrors || {},
        },
      }),
    };

    const store = new Vuex.Store({
      modules: {
        detail: {
          namespaced: true,
          actions,
          state,
          getters,
        },
      },
    });

    wrapper = mount(AssetLinksForm, {
      localVue,
      store,
    });
  };

  beforeEach(() => {
    release = commonUtils.convertObjectPropsToCamelCase(originalRelease, { deep: true });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with a basic store state', () => {
    beforeEach(() => {
      factory();
    });

    it('calls the "addEmptyAssetLink" store method when the "Add another link" button is clicked', () => {
      expect(actions.addEmptyAssetLink).not.toHaveBeenCalled();

      wrapper.find({ ref: 'addAnotherLinkButton' }).vm.$emit('click');

      expect(actions.addEmptyAssetLink).toHaveBeenCalledTimes(1);
    });

    it('calls the "removeAssetLinks" store method when the remove button is clicked', () => {
      expect(actions.removeAssetLink).not.toHaveBeenCalled();

      wrapper.find('.remove-button').vm.$emit('click');

      expect(actions.removeAssetLink).toHaveBeenCalledTimes(1);
    });

    it('calls the "updateAssetLinkUrl" store method when text is entered into the "URL" input field', () => {
      const linkIdToUpdate = release.assets.links[0].id;
      const newUrl = 'updated url';

      expect(actions.updateAssetLinkUrl).not.toHaveBeenCalled();

      wrapper.find({ ref: 'urlInput' }).vm.$emit('change', newUrl);

      expect(actions.updateAssetLinkUrl).toHaveBeenCalledTimes(1);
      expect(actions.updateAssetLinkUrl).toHaveBeenCalledWith(
        expect.anything(),
        {
          linkIdToUpdate,
          newUrl,
        },
        undefined,
      );
    });

    it('calls the "updateAssetLinName" store method when text is entered into the "Link title" input field', () => {
      const linkIdToUpdate = release.assets.links[0].id;
      const newName = 'updated name';

      expect(actions.updateAssetLinkName).not.toHaveBeenCalled();

      wrapper.find({ ref: 'nameInput' }).vm.$emit('change', newName);

      expect(actions.updateAssetLinkName).toHaveBeenCalledTimes(1);
      expect(actions.updateAssetLinkName).toHaveBeenCalledWith(
        expect.anything(),
        {
          linkIdToUpdate,
          newName,
        },
        undefined,
      );
    });
  });

  describe('validation', () => {
    let linkId;

    beforeEach(() => {
      linkId = release.assets.links[0].id;
    });

    const findUrlValidationMessage = () => wrapper.find('.url-field .invalid-feedback');
    const findNameValidationMessage = () => wrapper.find('.link-title-field .invalid-feedback');

    it('does not show any validation messages if there are no validation errors', () => {
      factory();

      expect(findUrlValidationMessage().exists()).toBe(false);
      expect(findNameValidationMessage().exists()).toBe(false);
    });

    it('shows a validation error message when two links have the same URLs', () => {
      factory({
        linkErrors: {
          [linkId]: { isDuplicate: true },
        },
      });

      expect(findUrlValidationMessage().text()).toBe(
        'This URL is already used for another link; duplicate URLs are not allowed',
      );
    });

    it('shows a validation error message when a URL has a bad format', () => {
      factory({
        linkErrors: {
          [linkId]: { isBadFormat: true },
        },
      });

      expect(findUrlValidationMessage().text()).toBe(
        'URL must start with http://, https://, or ftp://',
      );
    });

    it('shows a validation error message when the URL is empty (and the title is not empty)', () => {
      factory({
        linkErrors: {
          [linkId]: { isUrlEmpty: true },
        },
      });

      expect(findUrlValidationMessage().text()).toBe('URL is required');
    });

    it('shows a validation error message when the title is empty (and the URL is not empty)', () => {
      factory({
        linkErrors: {
          [linkId]: { isNameEmpty: true },
        },
      });

      expect(findNameValidationMessage().text()).toBe('Link title is required');
    });
  });

  describe('empty state', () => {
    describe('when the release fetched from the API has no links', () => {
      beforeEach(() => {
        factory({
          release: {
            ...release,
            assets: {
              links: [],
            },
          },
        });
      });

      it('calls the addEmptyAssetLink store method when the component is created', () => {
        expect(actions.addEmptyAssetLink).toHaveBeenCalledTimes(1);
      });
    });

    describe('when the release fetched from the API has one link', () => {
      beforeEach(() => {
        factory({
          release: {
            ...release,
            assets: {
              links: release.assets.links.slice(0, 1),
            },
          },
        });
      });

      it('does not call the addEmptyAssetLink store method when the component is created', () => {
        expect(actions.addEmptyAssetLink).not.toHaveBeenCalled();
      });

      it('calls addEmptyAssetLink when the final link is deleted by the user', () => {
        wrapper.find('.remove-button').vm.$emit('click');

        expect(actions.addEmptyAssetLink).toHaveBeenCalledTimes(1);
      });
    });
  });
});
