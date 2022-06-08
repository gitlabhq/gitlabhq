import { merge } from 'lodash';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import GroupNameAndPath from '~/groups/components/group_name_and_path.vue';
import { getGroupPathAvailability } from '~/rest_api';
import { createAlert } from '~/flash';

jest.mock('~/flash');
jest.mock('~/rest_api', () => ({
  getGroupPathAvailability: jest.fn(),
}));

describe('GroupNameAndPath', () => {
  let wrapper;

  const mockGroupName = 'My awesome group';
  const mockGroupUrl = 'my-awesome-group';
  const mockGroupUrlSuggested = 'my-awesome-group1';

  const defaultProvide = {
    basePath: 'http://gitlab.com/',
    fields: {
      name: { name: 'group[name]', id: 'group_name', value: '' },
      path: {
        name: 'group[path]',
        id: 'group_path',
        value: '',
        maxLength: 255,
        pattern: '[a-zA-Z0-9_\\.][a-zA-Z0-9_\\-\\.]*[a-zA-Z0-9_\\-]|[a-zA-Z0-9_]',
      },
      parentId: { name: 'group[parent_id]', id: 'group_parent_id', value: '1' },
      groupId: { name: 'group[id]', id: 'group_id', value: '' },
    },
    mattermostEnabled: false,
  };

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = mountExtended(GroupNameAndPath, { provide: merge({}, defaultProvide, provide) });
  };

  const findGroupNameField = () => wrapper.findByLabelText(GroupNameAndPath.i18n.inputs.name.label);
  const findGroupUrlField = () => wrapper.findByLabelText(GroupNameAndPath.i18n.inputs.path.label);

  const apiMockAvailablePath = () => {
    getGroupPathAvailability.mockResolvedValue({
      data: { exists: false, suggests: [] },
    });
  };
  const apiMockUnavailablePath = (suggests = [mockGroupUrlSuggested]) => {
    getGroupPathAvailability.mockResolvedValue({
      data: { exists: true, suggests },
    });
  };
  const apiMockLoading = () => {
    getGroupPathAvailability.mockImplementation(() => new Promise(() => {}));
  };

  const expectLoadingMessageExists = () => {
    expect(wrapper.findByText(GroupNameAndPath.i18n.apiLoadingMessage).exists()).toBe(true);
  };

  describe('when user types in the `Group name` field', () => {
    it('updates `Group URL` field as user types', async () => {
      createComponent();

      await findGroupNameField().setValue(mockGroupName);

      expect(findGroupUrlField().element.value).toBe(mockGroupUrl);
    });

    it('shows loading message', async () => {
      apiMockLoading();

      createComponent();

      await findGroupNameField().setValue(mockGroupName);

      expectLoadingMessageExists();
    });

    describe('when path is available', () => {
      it('does not update `Group URL` field', async () => {
        apiMockAvailablePath();

        createComponent();

        await findGroupNameField().setValue(mockGroupName);

        expect(getGroupPathAvailability).toHaveBeenCalledWith(
          mockGroupUrl,
          defaultProvide.fields.parentId.value,
          { signal: expect.any(AbortSignal) },
        );

        await waitForPromises();

        expect(findGroupUrlField().element.value).toBe(mockGroupUrl);
      });
    });

    describe('when path is not available', () => {
      it('updates `Group URL` field', async () => {
        apiMockUnavailablePath();

        createComponent();

        await findGroupNameField().setValue(mockGroupName);
        await waitForPromises();

        expect(findGroupUrlField().element.value).toBe(mockGroupUrlSuggested);
      });
    });

    describe('when API returns no suggestions', () => {
      it('calls `createAlert`', async () => {
        apiMockUnavailablePath([]);

        createComponent();

        await findGroupNameField().setValue(mockGroupName);
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: GroupNameAndPath.i18n.apiErrorMessage,
        });
      });
    });

    describe('when API call fails', () => {
      it('calls `createAlert`', async () => {
        getGroupPathAvailability.mockRejectedValue({});

        createComponent();

        await findGroupNameField().setValue(mockGroupName);
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: GroupNameAndPath.i18n.apiErrorMessage,
        });
      });
    });

    describe('when multiple API calls are in-flight', () => {
      it('aborts the first API call and resolves second API call', async () => {
        apiMockLoading();
        apiMockUnavailablePath();
        const abortSpy = jest.spyOn(AbortController.prototype, 'abort');

        createComponent();

        await findGroupNameField().setValue('Foo');
        await findGroupNameField().setValue(mockGroupName);
        await waitForPromises();

        expect(createAlert).not.toHaveBeenCalled();
        expect(findGroupUrlField().element.value).toBe(mockGroupUrlSuggested);
        expect(abortSpy).toHaveBeenCalled();
      });
    });

    describe('when `Group URL` is empty', () => {
      it('does not call API', async () => {
        createComponent({
          provide: { fields: { name: { value: mockGroupName }, path: mockGroupUrl } },
        });

        await findGroupNameField().setValue('');

        expect(getGroupPathAvailability).not.toHaveBeenCalled();
      });
    });
  });

  describe('when `Group name` field is invalid', () => {
    it('shows error message', async () => {
      createComponent();

      await findGroupNameField().trigger('invalid');

      expect(wrapper.findByText(GroupNameAndPath.i18n.inputs.name.invalidFeedback).exists()).toBe(
        true,
      );
    });
  });

  describe('when user types in `Group URL` field', () => {
    it('shows loading message', async () => {
      apiMockLoading();

      createComponent();

      await findGroupUrlField().setValue(mockGroupUrl);

      expectLoadingMessageExists();
    });

    describe('when path is available', () => {
      it('displays success message', async () => {
        apiMockAvailablePath();

        createComponent();

        await findGroupUrlField().setValue(mockGroupUrl);
        await waitForPromises();

        expect(wrapper.findByText(GroupNameAndPath.i18n.inputs.path.validFeedback).exists()).toBe(
          true,
        );
      });
    });

    describe('when path is not available', () => {
      it('displays error message and updates `Group URL` field', async () => {
        apiMockUnavailablePath();

        createComponent();

        await findGroupUrlField().setValue(mockGroupUrl);
        await waitForPromises();

        expect(
          wrapper
            .findByText(GroupNameAndPath.i18n.inputs.path.invalidFeedbackPathUnavailable)
            .exists(),
        ).toBe(true);
        expect(findGroupUrlField().element.value).toBe(mockGroupUrlSuggested);
      });
    });
  });

  describe('when `Group URL` field is invalid', () => {
    it('shows error message', async () => {
      createComponent();

      await findGroupUrlField().trigger('invalid');

      expect(
        wrapper
          .findByText(GroupNameAndPath.i18n.inputs.path.invalidFeedbackInvalidPattern)
          .exists(),
      ).toBe(true);
    });
  });

  describe('mattermost', () => {
    it('adds `data-bind-in` attribute when enabled', () => {
      createComponent({ provide: { mattermostEnabled: true } });

      expect(findGroupUrlField().attributes('data-bind-in')).toBe(
        GroupNameAndPath.mattermostDataBindName,
      );
    });

    it('does not add `data-bind-in` attribute when disabled', () => {
      createComponent();

      expect(findGroupUrlField().attributes('data-bind-in')).toBeUndefined();
    });
  });
});
