import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { merge } from 'lodash-es';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import GroupNameAndPath from '~/groups/components/group_name_and_path.vue';
import { getGroupPathAvailability } from '~/rest_api';
import { createAlert } from '~/alert';
import { helpPagePath } from '~/helpers/help_page_helper';
import searchGroupsWhereUserCanCreateSubgroups from '~/groups/queries/search_groups_where_user_can_create_subgroups.query.graphql';

jest.mock('~/alert');
jest.mock('~/rest_api', () => ({
  getGroupPathAvailability: jest.fn(),
}));

Vue.use(VueApollo);

describe('GroupNameAndPath', () => {
  let wrapper;

  const mockGroupName = 'My awesome group';
  const mockGroupUrl = 'my-awesome-group';
  const mockGroupUrlSuggested = 'my-awesome-group1';

  const mockResponse = jest.fn().mockResolvedValue({
    data: {
      currentUser: {
        id: '1',
        groups: {
          nodes: [{ id: '2', fullPath: '/path2' }],
        },
      },
    },
  });

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
      parentFullPath: { name: 'group[parent_full_path]', id: 'group_full_path', value: '/path1' },
      groupId: { name: 'group[id]', id: 'group_id', value: '' },
    },
    newSubgroup: false,
    mattermostEnabled: false,
  };

  const createComponent = ({ provide = {}, mockQueryResponse = mockResponse } = {}) => {
    wrapper = mountExtended(GroupNameAndPath, {
      provide: merge({}, defaultProvide, provide),
      apolloProvider: createMockApollo([
        [searchGroupsWhereUserCanCreateSubgroups, mockQueryResponse],
      ]),
    });
  };
  const createComponentEditGroup = ({ path = mockGroupUrl } = {}) => {
    createComponent({
      provide: { fields: { groupId: { value: '1' }, path: { value: path } } },
    });
  };

  const findGroupNameField = () => wrapper.findByLabelText('Group name');
  const findGroupUrlField = () => wrapper.findByLabelText('Group URL');
  const findSubgroupNameField = () => wrapper.findByLabelText('Subgroup name');
  const findSubgroupSlugField = () => wrapper.findByLabelText('Subgroup slug');
  const findSelectedGroup = () => wrapper.findComponent(GlCollapsibleListbox);
  const findChangeUrlAlert = () => extendedWrapper(wrapper.findByTestId('changing-url-alert'));
  const findDotInPathAlert = () => extendedWrapper(wrapper.findByTestId('dot-in-path-alert'));

  const apiMockAvailablePath = () => {
    getGroupPathAvailability.mockResolvedValueOnce({
      data: { exists: false, suggests: [] },
    });
  };
  const apiMockUnavailablePath = (suggests = [mockGroupUrlSuggested]) => {
    getGroupPathAvailability.mockResolvedValueOnce({
      data: { exists: true, suggests },
    });
  };
  const apiMockLoading = () => {
    getGroupPathAvailability.mockImplementationOnce(() => new Promise(() => {}));
  };

  const expectLoadingMessageExists = () => {
    expect(wrapper.findByText(GroupNameAndPath.i18n.apiLoadingMessage).exists()).toBe(true);
  };

  describe('when user types in the `Group name` field', () => {
    describe('when creating a new group', () => {
      it('updates `Group URL` field as user types', async () => {
        createComponent();

        await findGroupNameField().setValue(mockGroupName);

        expect(findGroupUrlField().element.value).toBe(mockGroupUrl);
      });

      it('adds auto-generated class to `Group URL` field when name is typed', async () => {
        createComponent();

        await findGroupNameField().setValue(mockGroupName);

        expect(findGroupUrlField().classes()).toContain('!gl-bg-feedback-info');
      });

      it('removes auto-generated class when user manually edits `Group URL`', async () => {
        createComponent();

        await findGroupNameField().setValue(mockGroupName);
        await findGroupUrlField().setValue('custom-slug');

        expect(findGroupUrlField().classes()).not.toContain('!gl-bg-feedback-info');
      });
    });

    describe('when creating a new subgroup', () => {
      beforeEach(() => {
        createComponent({ provide: { newSubgroup: true } });
      });

      it('show correct state before dropdown is opened', () => {
        expect(findSelectedGroup().props('loading')).toBe(false);
        expect(findSelectedGroup().props('noResultsText')).toBe('');
      });

      it('shows correct state when dropdown is opened', async () => {
        findSelectedGroup().vm.$emit('shown');
        await nextTick();

        expect(findSelectedGroup().props('loading')).toBe(true);
        expect(findSelectedGroup().props('noResultsText')).toBe('');
      });

      it('shows no-results text when query completes with no results', async () => {
        // Mock the GraphQL query to return empty results
        const mockQuery = jest.fn().mockResolvedValue({
          data: {
            currentUser: {
              groups: {
                nodes: [],
              },
            },
          },
        });
        wrapper.vm.$apollo.query = mockQuery;

        findSelectedGroup().vm.$emit('shown');
        await waitForPromises();

        expect(findSelectedGroup().props('noResultsText')).toBe('No matches found');
      });

      it('shows searching state when user types in search', async () => {
        findSelectedGroup().vm.$emit('search', 'test');
        await nextTick();

        expect(findSelectedGroup().props('searching')).toBe(true);
      });

      it('updates `Subgroup slug` field as user types', async () => {
        await findSubgroupNameField().setValue(mockGroupName);

        expect(findSubgroupSlugField().element.value).toBe(mockGroupUrl);
      });

      describe('when user selects parent group', () => {
        it('updates `Subgroup URL` dropdown and calls API', async () => {
          expect(findSelectedGroup().props('toggleText')).toContain('/path1');

          await findSubgroupNameField().setValue(mockGroupName);
          findSelectedGroup().vm.$emit('shown');

          await waitForPromises();

          findSelectedGroup().vm.$emit('select', '2');
          await nextTick();

          expect(findSelectedGroup().props('toggleText')).toContain('/path2');

          expect(getGroupPathAvailability).toHaveBeenCalled();

          expect(wrapper.findByText(GroupNameAndPath.i18n.inputs.path.validFeedback).exists()).toBe(
            true,
          );
        });
      });
    });

    describe('when editing a group', () => {
      it('does not update `Group URL` field and does not call API', async () => {
        const groupUrl = 'foo-bar';

        createComponentEditGroup({ path: groupUrl });

        await findGroupNameField().setValue(mockGroupName);

        expect(findGroupUrlField().element.value).toBe(groupUrl);
        expect(getGroupPathAvailability).not.toHaveBeenCalled();
      });
    });

    describe('when `Group URL` field has been manually entered', () => {
      it('does not update `Group URL` field and does not call API', async () => {
        apiMockAvailablePath();

        createComponent();

        await findGroupUrlField().setValue(mockGroupUrl);
        await waitForPromises();

        getGroupPathAvailability.mockClear();

        await findGroupNameField().setValue('Foo bar');

        expect(findGroupUrlField().element.value).toBe(mockGroupUrl);
        expect(getGroupPathAvailability).not.toHaveBeenCalled();
      });
    });

    it('shows loading message', async () => {
      apiMockLoading();

      createComponent();

      await findGroupNameField().setValue(mockGroupName);

      expectLoadingMessageExists();
    });

    it('shows warning alert on using dot in path', () => {
      createComponentEditGroup();

      expect(findDotInPathAlert().exists()).toBe(true);
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
        getGroupPathAvailability.mockRejectedValueOnce({});

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
        getGroupPathAvailability.mockRejectedValueOnce({ __CANCEL__: true });
        apiMockUnavailablePath();

        const abortSpy = jest.spyOn(AbortController.prototype, 'abort');

        createComponent();

        await findGroupNameField().setValue('Foo');
        await findGroupNameField().setValue(mockGroupName);

        // Wait for re-render to ensure loading message is still there
        await nextTick();
        expectLoadingMessageExists();

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

    describe('when the slugified `Group URL` has an invalid format', () => {
      it('shows the inline format error on the auto-generated path', async () => {
        createComponent();

        await findGroupNameField().setValue('a');

        expect(wrapper.findByText('Group URL must be at least 2 characters long.').exists()).toBe(
          true,
        );
      });

      it('does not call the availability API', async () => {
        createComponent();

        await findGroupNameField().setValue('a');
        jest.runAllTimers();
        await waitForPromises();

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

    describe('when editing a group', () => {
      it('calls API if `Group URL` does not equal the original `Group URL`', async () => {
        const groupUrl = 'foo-bar';

        apiMockAvailablePath();

        createComponentEditGroup({ path: groupUrl });

        await findGroupUrlField().setValue('foo-bar1');
        await waitForPromises();

        expect(getGroupPathAvailability).toHaveBeenCalled();
        expect(wrapper.findByText(GroupNameAndPath.i18n.inputs.path.validFeedback).exists()).toBe(
          true,
        );

        getGroupPathAvailability.mockClear();

        await findGroupUrlField().setValue('foo-bar');

        expect(getGroupPathAvailability).not.toHaveBeenCalled();
      });
    });
  });

  describe('when `Group URL` is invalid', () => {
    it.each`
      path           | message
      ${'-abc'}      | ${'Group URL must start with a letter, digit, underscore, or period.'}
      ${'abc!'}      | ${'Group URL can only contain letters, digits, underscores, periods, and dashes.'}
      ${'abc.'}      | ${'Group URL must end with a letter, digit, underscore, or dash.'}
      ${'repo.git'}  | ${'Group URL must not end with `.git` or `.atom`.'}
      ${'feed.atom'} | ${'Group URL must not end with `.git` or `.atom`.'}
      ${'a'}         | ${'Group URL must be at least 2 characters long.'}
    `(
      'shows the inline error "$message" for path "$path" and does not call the availability API',
      async ({ path, message }) => {
        createComponent();

        await findGroupUrlField().setValue(path);
        await waitForPromises();

        expect(wrapper.findByText(message).exists()).toBe(true);
        expect(getGroupPathAvailability).not.toHaveBeenCalled();
      },
    );

    it('does not show the loading message when the format is invalid', async () => {
      createComponent();

      await findGroupUrlField().setValue('-abc');

      expect(wrapper.findByText(GroupNameAndPath.i18n.apiLoadingMessage).exists()).toBe(false);
    });

    it('aborts an in-flight availability request when the format becomes invalid', async () => {
      apiMockLoading();

      const abortSpy = jest.spyOn(AbortController.prototype, 'abort');

      createComponent();

      await findGroupUrlField().setValue(mockGroupUrl);
      expectLoadingMessageExists();

      await findGroupUrlField().setValue('-abc');

      expect(abortSpy).toHaveBeenCalled();
      expect(wrapper.findByText(GroupNameAndPath.i18n.apiLoadingMessage).exists()).toBe(false);
      expect(
        wrapper
          .findByText('Group URL must start with a letter, digit, underscore, or period.')
          .exists(),
      ).toBe(true);
    });

    it('triggers the availability check once the format becomes valid again', async () => {
      apiMockAvailablePath();

      createComponent();

      await findGroupUrlField().setValue('-abc');
      expect(getGroupPathAvailability).not.toHaveBeenCalled();

      await findGroupUrlField().setValue(mockGroupUrl);
      await waitForPromises();

      expect(getGroupPathAvailability).toHaveBeenCalled();
      expect(wrapper.findByText(GroupNameAndPath.i18n.inputs.path.validFeedback).exists()).toBe(
        true,
      );
    });

    it('shows the required message when the native `invalid` event fires on an empty field', async () => {
      createComponent();

      await findGroupUrlField().trigger('invalid');

      expect(wrapper.findByText('Group URL is required.').exists()).toBe(true);
    });

    it('falls back to the generic pattern message when the value passes client-side rules but the native `invalid` event fires', async () => {
      createComponent();

      await findGroupUrlField().setValue(mockGroupUrl);
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

  describe('when editing a group', () => {
    it('shows warning alert with `Learn more` link', () => {
      createComponentEditGroup();

      expect(findChangeUrlAlert().exists()).toBe(true);
      expect(
        findChangeUrlAlert().findByRole('link', { name: 'Learn more' }).attributes('href'),
      ).toBe(
        helpPagePath('user/group/manage', {
          anchor: 'change-a-groups-path',
        }),
      );
    });

    it('shows `Group ID` field', () => {
      createComponentEditGroup();

      expect(wrapper.findByLabelText('Group ID').element.value).toBe('1');
    });
  });
});
