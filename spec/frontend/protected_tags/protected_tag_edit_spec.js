import MockAdapter from 'axios-mock-adapter';
import { ACCESS_LEVELS, LEVEL_TYPES } from '~/protected_tags/constants';
import ProtectedTagEdit, { i18n } from '~/protected_tags/protected_tag_edit.vue';
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import axios from '~/lib/utils/axios_utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { mockAccessLevels } from './mock_data';

jest.mock('~/alert');

describe('Protected Tag Edit', () => {
  let wrapper;
  let mockAxios;

  const url = 'http://some.url';
  const toggleClass = 'js-allowed-to-create gl-max-w-34';

  const findAccessDropdown = () => wrapper.findComponent(AccessDropdown);

  const createComponent = () => {
    wrapper = shallowMountExtended(ProtectedTagEdit, {
      propsData: {
        url,
        accessLevelsData: mockAccessLevels,
        searchEnabled: false,
      },
    });
  };

  beforeEach(() => {
    window.gon = {
      api_version: 'v4',
      deploy_access_levels: {
        roles: [],
      },
    };
    mockAxios = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    mockAxios.restore();
  });

  it('renders access dropdown with correct props', () => {
    expect(findAccessDropdown().props()).toMatchObject({
      toggleClass,
      accessLevel: ACCESS_LEVELS.CREATE,
      accessLevelsData: mockAccessLevels,
      searchEnabled: false,
    });
  });

  describe('when dropdown is closed and has no changes', () => {
    it('does not make a patch request to update permission', () => {
      jest.spyOn(axios, 'patch');

      findAccessDropdown().vm.$emit('hidden', []);

      expect(axios.patch).not.toHaveBeenCalled();
    });
  });

  describe('when dropdown is closed and has changes', () => {
    it('makes patch request to update permission', () => {
      jest.spyOn(axios, 'patch');

      const newPermissions = [{ id: 1, access_level: 30 }];
      findAccessDropdown().vm.$emit('hidden', newPermissions);

      expect(axios.patch).not.toHaveBeenCalled();
    });
  });

  describe('when permission is updated successfully', () => {
    beforeEach(async () => {
      const updatedPermissions = [
        { user_id: 1, id: 1 },
        { group_id: 1, id: 2 },
        { access_level: 3, id: 3 },
        { deploy_key_id: 1, id: 4 },
      ];
      mockAxios.onPatch().replyOnce(HTTP_STATUS_OK, { [ACCESS_LEVELS.CREATE]: updatedPermissions });
      findAccessDropdown().vm.$emit('hidden', [{ user_id: 1 }]);
      await waitForPromises();
    });

    it('should update selected items', () => {
      const newPreselected = [
        { user_id: 1, id: 1, type: LEVEL_TYPES.USER },
        { group_id: 1, id: 2, type: LEVEL_TYPES.GROUP },
        { access_level: 3, id: 3, type: LEVEL_TYPES.ROLE },
        { deploy_key_id: 1, id: 4, type: LEVEL_TYPES.DEPLOY_KEY },
      ];
      expect(findAccessDropdown().props('preselectedItems')).toEqual(newPreselected);
    });
  });

  describe('when permission update fails', () => {
    beforeEach(async () => {
      mockAxios.onPatch().replyOnce(HTTP_STATUS_BAD_REQUEST, {});
      findAccessDropdown().vm.$emit('hidden', [{ user_id: 1 }]);
      await waitForPromises();
    });

    it('should show error message', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: i18n.failureMessage,
      });
    });
  });
});
